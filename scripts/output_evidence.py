"""Registry-gated CSV evidence. R remains the authoritative clinical assembler."""
import csv
import json
import math
import os
import sys
import threading
from contextlib import contextmanager
from pathlib import Path
from public_privacy import sanitize_public_payload, audit_public_payload, effective_threshold


def load_registry(project_root):
    path = Path(project_root) / 'inst/config/public-output-registry.json'
    registry = json.loads(path.read_text(encoding='utf-8'))
    if registry['schema_version'] != 1:
        raise ValueError('Unsupported output registry version')
    for key, env in [('input_max_bytes', 'DALYCARE_ATLAS_INPUT_MAX_BYTES'), ('public_table_max_bytes', 'DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES')]:
        if os.environ.get(env):
            value = int(os.environ[env])
            if value < 1:
                raise ValueError('Invalid build byte limit')
            registry[key] = value
    return registry


def confined_path(root, relative):
    root = Path(root).resolve()
    relative = str(relative).replace('\\', '/')
    if Path(relative).is_absolute() or ':' in relative or '..' in relative.split('/'):
        raise ValueError('Output path escapes selected run')
    path = (root / relative).resolve()
    if not path.is_relative_to(root):
        raise ValueError('Output path escapes selected run')
    return path


_CSV_FIELD_LOCK = threading.RLock()


@contextmanager
def _csv_field_budget(max_bytes):
    # CSV limits count characters; a UTF-8 field cannot have more characters
    # than the bounded input has bytes. Serialize our readers while changing
    # the parser's process-wide setting, and restore it on every exit path.
    with _CSV_FIELD_LOCK:
        previous = csv.field_size_limit(min(int(max_bytes), sys.maxsize))
        try:
            yield
        finally:
            csv.field_size_limit(previous)


def read_registered_csv(path, spec, max_bytes=67108864):
    path = Path(path)
    if not path.is_file() or path.stat().st_size > max_bytes:
        raise ValueError('Required input missing or exceeds pre-read limit')
    try:
        with _csv_field_budget(max_bytes), path.open(encoding='utf-8-sig', newline='') as handle:
            reader = csv.reader(handle, delimiter='\t' if path.suffix == '.tsv' else ',', strict=True)
            header = next(reader)
            if header == ['']:
                header = []
            schema = next((s for s in spec['schemas'] if set(s) == set(header) and len(s) == len(header)), None)
            if schema is None:
                raise ValueError('Incompatible CSV schema')
            rows = []
            for cells in reader:
                if len(cells) != len(header):
                    raise ValueError('Malformed CSV record width')
                row = {}
                for key, value in zip(header, cells):
                    kind = schema[key]
                    if value == '':
                        value = None
                    elif kind == 'number':
                        value = float(value)
                        if not math.isfinite(value):
                            raise ValueError('Nonfinite numeric input')
                    elif kind == 'boolean':
                        if value.upper() not in ('TRUE', 'FALSE'):
                            raise ValueError('Invalid boolean input')
                        value = value.upper() == 'TRUE'
                    row[key] = value
                rows.append(row)
            return rows
    except (csv.Error, StopIteration, UnicodeError, OSError) as exc:
        raise ValueError('Missing or malformed registered input') from exc


def _get(obj, path):
    for key in path:
        if not isinstance(obj, dict):
            return None
        obj = obj.get(key)
    return obj


def _set(obj, path, value):
    for key in path[:-1]:
        obj = obj.setdefault(key, {})
    obj[path[-1]] = value


def _bound_source_file(spec, context):
    relative = ((context or {}).get('binding_files') or {}).get(spec['id'])
    if relative is None:
        return spec['source_file']
    expected = 'outputs/selected_mcl/' + Path(spec['source_file']).name
    if (spec['arg_path'][:2] != ['mcl_triangle_feasibility', 'cohort_counts']
            or len(spec['arg_path']) != 3 or relative != expected
            or spec['id'] not in context.get('bindings', [])):
        raise ValueError('Invalid selected aggregate binding')
    return relative


def validate_build_context(context, registry):
    """Validate required-input metadata before either migration or evidence reads."""
    if not isinstance(context, dict):
        raise ValueError('Build context must be an object')
    for key in ('schema_version', 'registry_version'):
        if type(context.get(key)) is not int or context[key] != 1:
            raise ValueError('Unsupported build context version')
    specs = {spec['id']: spec for spec in registry['artifacts']}
    bindings = context.get('bindings')
    if (not isinstance(bindings, list)
            or any(not isinstance(key, str) or key not in specs for key in bindings)
            or len(bindings) != len(set(bindings))):
        raise ValueError('Invalid build context bindings')
    files = context.get('binding_files', {})
    # jsonlite writes an unpopulated R named-list candidate as []; preserve that
    # exact empty representation, without accepting nonempty arrays or scalars.
    if isinstance(files, list) and not files:
        files = {}
    if not isinstance(files, dict):
        raise ValueError('Invalid selected aggregate bindings')
    for key, relative in files.items():
        if key not in specs or key not in bindings or not isinstance(relative, str):
            raise ValueError('Invalid selected aggregate binding')
        _bound_source_file(specs[key], context)
    return context


def read_build_context(run_dir, registry):
    """Read bounded optional context; historical runs can lack this file."""
    path = confined_path(run_dir, 'outputs/atlas_build_context.json')
    if not path.exists():
        return None
    if not path.is_file() or path.stat().st_size > registry['input_max_bytes']:
        raise ValueError('Build context unavailable or exceeds pre-read limit')
    return validate_build_context(json.loads(path.read_text(encoding='utf-8-sig')), registry)


def collect_output_evidence(run_dir, project_root, payload_snapshot=None):
    registry = load_registry(project_root)
    run = Path(run_dir).resolve() if run_dir is not None else None
    logical, descriptors, retained = {}, [], []
    context = None
    if run is not None:
        manifest = confined_path(run, 'outputs/output_manifest.csv')
        if manifest.exists():
            if manifest.stat().st_size > registry['input_max_bytes']:
                raise ValueError('Output manifest exceeds pre-read limit')
            with _csv_field_budget(registry['input_max_bytes']), manifest.open(encoding='utf-8-sig', newline='') as handle:
                reader = csv.DictReader(handle, strict=True)
                if 'relative_path' not in (reader.fieldnames or []):
                    raise ValueError('Invalid output manifest')
                for row in reader:
                    confined_path(run, row['relative_path'])
    if run is not None:
        context = read_build_context(run, registry)
    minimum = effective_threshold(payload_snapshot, context)
    required = set(context.get('bindings', [])) if context else set()
    for spec in registry['artifacts']:
        resource = spec.get('resource', False)
        base = project_root if resource else run
        path = confined_path(base, spec['source_file'] if resource else _bound_source_file(spec, context)) if base is not None else None
        rows, status, reason = [], 'not_produced', 'Output not produced'
        provenance = 'project_reference' if resource else 'csv_run' if run else 'snapshot_only'
        source_count = None
        complete = False
        if path is not None and path.exists():
            try:
                rows = read_registered_csv(path, spec, registry['input_max_bytes'])
                source_count = len(rows)
                status, reason, complete = ('available' if rows else 'empty_output'), '', True
            except ValueError:
                if spec['id'] in required:
                    raise ValueError('Required registered input invalid: ' + spec['id'])
                status, reason = 'metadata_only', 'Input unavailable or schema not reviewed'
        elif spec['id'] in required:
            raise ValueError('Required registered input missing: ' + spec['id'])
        elif run is None and not resource and payload_snapshot is not None and spec['payload_path']:
            candidate = _get(payload_snapshot, spec['payload_path'])
            if isinstance(candidate, list):
                try:
                    rows = normalize_snapshot_rows(candidate, spec)
                    status, reason = 'snapshot_preview', 'Original CSV row count and completeness unknown'
                except ValueError:
                    rows, status, reason = [], 'unavailable', 'Snapshot values incompatible with reviewed schema'
        if not spec['projection']:
            rows, complete = [], False
            if status in ('available', 'empty_output', 'snapshot_preview'):
                status, reason = 'metadata_only', 'Public column projection not reviewed'
            source_count = None
        if spec['payload_path'] and spec['projection']:
            # Keep all schema fields for disclosure context; project only after the guard.
            _set(logical, spec['payload_path'], rows)
        descriptor = {k: spec[k] for k in ('id', 'title', 'source_file', 'group', 'kind', 'row_grain', 'count_basis')}
        descriptor.update(status=status, reason=reason, source_row_count=source_count,
                          represented_row_count=0, complete=complete, provenance=provenance,
                          source_terms=[], columns=[], rows=[])
        descriptors.append(descriptor)
        retained.append(spec)
    safe = sanitize_public_payload(logical, min_cell_count=minimum, project_root=project_root)
    if audit_public_payload(safe):
        raise ValueError('Public evidence privacy audit failed')
    privacy_columns = {'value_privacy_status', 'count_privacy_status', 'date_privacy_status', 'availability_privacy_status', 'numeric_privacy_status', 'summary_scope', 'summary_method', 'is_sensitive'}
    for descriptor, spec in zip(descriptors, retained):
        rows = _get(safe, spec['payload_path']) if spec['payload_path'] and spec['projection'] else []
        allowed = set(spec['projection']) | privacy_columns
        keys = list(spec['projection']) + sorted({k for row in rows or [] for k in row if k in privacy_columns and k not in spec['projection']})
        descriptor['rows'] = [{k: row.get(k) for k in keys} for row in rows or []]
        descriptor['represented_row_count'] = len(descriptor['rows'])
        descriptor['source_terms'] = sorted({str(row[key]) for row in descriptor['rows'] for key in ('table_name', 'source_name', 'registry') if row.get(key) not in (None, '')})
        types = {k: v for schema in spec['schemas'] for k, v in schema.items()}
        descriptor['columns'] = [{'key': key, 'label': key.replace('_', ' ').capitalize(), 'type': types.get(key, 'boolean' if key == 'is_sensitive' else 'string'), **spec.get('column_meanings', {}).get(key, {})} for key in keys]
    if run is not None:
        known = {s['source_file'] for s in retained}
        unknown = []
        for sub in ('outputs', 'outputs/panels'):
            for path in sorted(confined_path(run, sub).glob('*.csv')):
                confined_path(run, path.relative_to(run).as_posix())
                if path.relative_to(run).as_posix() not in known and path.name != 'output_manifest.csv':
                    unknown.append(path)
        for i, _ in enumerate(unknown, 1):
            descriptors.append(dict(id=f'unreviewed_{i}', title='Unreviewed output', source_file='', group='Other outputs', kind='metadata', status='metadata_only', reason='Artifact not registered for publication', row_grain='Meaning not supplied', count_basis='not supplied', source_row_count=None, represented_row_count=0, complete=False, provenance='csv_run', source_terms=[], columns=[], rows=[]))
    size = len(json.dumps([t['rows'] for t in descriptors], ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
    if size > registry['public_table_max_bytes']:
        raise ValueError('Public table-data budget exceeded')
    return descriptors


def normalize_snapshot_rows(rows, spec):
    """Convert only registered types before the whole-table privacy guard."""
    types = {k: v for schema in spec['schemas'] for k, v in schema.items()}
    result = []
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError('Invalid snapshot row')
        converted = dict(row)
        for key, value in row.items():
            kind = types.get(key)
            if value is None or value == '':
                converted[key] = None
            elif kind == 'number':
                if isinstance(value, bool):
                    raise ValueError('Invalid numeric snapshot value')
                try:
                    converted[key] = float(value)
                except (TypeError, ValueError) as exc:
                    raise ValueError('Invalid numeric snapshot value') from exc
                if not math.isfinite(converted[key]):
                    raise ValueError('Invalid numeric snapshot value')
            elif kind == 'boolean':
                if isinstance(value, bool):
                    continue
                if not isinstance(value, str) or value.upper() not in ('TRUE', 'FALSE'):
                    raise ValueError('Invalid boolean snapshot value')
                converted[key] = value.upper() == 'TRUE'
            elif kind == 'string' and not isinstance(value, str):
                raise ValueError('Invalid string snapshot value')
        result.append(converted)
    return result
