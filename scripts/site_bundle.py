"""Bounded classic-script site bundles, published from a complete sibling stage."""
import copy
import json
import math
import os
import re
import shutil
import uuid
import warnings
import csv
from publication import public_manifest, package_site, loading_budget
from pathlib import Path
from output_evidence import load_registry, _get, _set
from public_privacy import sanitize_public_payload, audit_public_payload, effective_threshold, VERSION

ALIASES = dict(action_items='action_items', action_summary='action_summary', streaming_summary='review_streaming_summary', temporal_date_quality='review_temporal_date_quality', db_budget_actions='db_budget_actions', db_query_log='db_query_log', catalog='catalog_rows', resource_reconciliation='resource_reconciliation_rows', canonical_resource_reconciliation='canonical_resource_reconciliation_rows', current_run_source_map_audit='current_run_source_map_audit_rows', source_map_crosswalk='source_map_crosswalk_rows', source_resolution_delta='source_resolution_delta_rows', legacy_resource_audit='legacy_cartography_audit_rows', columns='column_profile_rows', column_summary='column_profile_summary', panels='panel_groups', qa='qa_items', run_summary='run_summary')
SHARD_BYTES = 262144
ENTRY_BYTES = 524288
PRIVACY_COLUMNS = {'value_privacy_status','count_privacy_status','date_privacy_status','availability_privacy_status','numeric_privacy_status','summary_scope','summary_method','is_sensitive'}
HARD_MAX_BYTES = 67108864
WORK_LIMITS = dict(tables=4096, path_depth=16, schemas_per_table=64,
                   keys_per_schema=64, key_utf8_bytes=128, rows=100000,
                   cells=1000000, json_depth=128)
UNSAFE_KEYS = {'__proto__', 'constructor', 'prototype'}


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def _finite_number(value):
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _integral(value):
    return _finite_number(value) and value == int(value)


def _byte_limit(max_bytes=None):
    if max_bytes is None:
        return HARD_MAX_BYTES
    if not _integral(max_bytes) or max_bytes <= 0:
        raise ValueError('Invalid transport byte limit')
    return min(HARD_MAX_BYTES, int(max_bytes))


def resolve_transport_version(explicit=None):
    """Normalize public configuration once; codecs never consult the environment."""
    if explicit is None:
        raw = os.environ.get('DALYCARE_ATLAS_TRANSPORT_VERSION')
        if raw is None or raw == '':
            return 2
        raw = raw.strip()
        if raw not in ('1', '2'):
            raise ValueError('Invalid transport version configuration')
        return int(raw)
    if type(explicit) is str and explicit in ('1', '2'):
        return int(explicit)
    if _integral(explicit) and explicit in (1, 2):
        return int(explicit)
    raise ValueError('Invalid transport version configuration')


class _Budget:
    def __init__(self, maximum):
        self.maximum = maximum
        self.total = 0

    def add(self, charge):
        self.total += charge
        if self.maximum is not None and self.total > self.maximum:
            raise ValueError('Transport byte budget exceeded')


def _charge_string(value, budget):
    budget.add(2)
    for char in value:
        code = ord(char)
        if 0xd800 <= code <= 0xdfff:
            raise ValueError('Invalid Unicode scalar string')
        if char in '"\\\b\t\n\f\r':
            budget.add(2)
        elif code < 32:
            budget.add(6)
        else:
            budget.add(1 if code < 128 else 2 if code < 2048 else 3 if code < 65536 else 4)


def _charge_graph(value, budget, depth=0, active=None, reject_proto=False):
    """Walk every serialized occurrence without materializing JSON or a clone."""
    if depth > WORK_LIMITS['json_depth']:
        raise ValueError('Transport JSON depth exceeded')
    kind = type(value)
    if value is None:
        budget.add(4)
    elif kind is bool:
        budget.add(4 if value else 5)
    elif kind in (int, float):
        if not _finite_number(value):
            raise ValueError('Invalid finite JavaScript number')
        budget.add(32)
    elif kind is str:
        _charge_string(value, budget)
    elif kind in (dict, list):
        active = set() if active is None else active
        identity = id(value)
        if identity in active:
            raise ValueError('Cyclic transport graph')
        active.add(identity)
        try:
            budget.add(2)
            for index, item in enumerate(value.items() if kind is dict else value):
                if index:
                    budget.add(1)
                if kind is dict:
                    key, child = item
                    if type(key) is not str:
                        raise ValueError('Transport record keys must be strings')
                    if reject_proto and key == '__proto__':
                        raise ValueError('Classic-script payload cannot preserve own __proto__')
                    _charge_string(key, budget)
                    budget.add(1)
                else:
                    child = item
                _charge_graph(child, budget, depth + 1, active, reject_proto)
        finally:
            active.remove(identity)
    else:
        raise ValueError('Non-JSON transport graph value')


def normalized_size(value, max_bytes=None):
    budget = _Budget(_byte_limit(max_bytes))
    _charge_graph(value, budget)
    return budget.total


def _component(value):
    return (type(value) is str and bool(value) and value not in UNSAFE_KEYS
            and len(value.encode('utf-8')) <= WORK_LIMITS['key_utf8_bytes'])


def _path(path):
    if (type(path) is not list or not path or len(path) > WORK_LIMITS['path_depth']
            or not all(_component(key) for key in path)):
        raise ValueError('Invalid transport path')
    return tuple(path)


def _lookup(value, path):
    for key in path:
        if type(value) is not dict or key not in value:
            raise ValueError('Missing transport path')
        value = value[key]
    return value


def _aliases_preflight(payload, aliases, packed_paths=()):
    used = set()
    for alias in aliases:
        if type(alias) is not dict or set(alias) != {'target', 'source'}:
            raise ValueError('Invalid transport alias metadata')
        target, source = _path(alias['target']), _path(alias['source'])
        if (len(target) != 2 or target[0] != 'review_infrastructure_sections'
                or target[1] not in ALIASES or source != (ALIASES[target[1]],)
                or target in used):
            raise ValueError('Unreviewed transport alias')
        parent = _lookup(payload, target[:-1])
        original_source = _lookup(payload, source)
        if (type(parent) is not dict or target[-1] in parent
                or not (type(original_source) is list or source in packed_paths)):
            raise ValueError('Invalid transport alias')
        used.add(target)


def _expanded_charge(payload, tables, maximum):
    budget = _Budget(maximum)
    _charge_graph(payload, budget)
    for table in tables:
        # Replace the null placeholder, then charge restored rows directly.
        budget.total -= 4
        rows = table['rows']
        budget.add(2)
        for index, row in enumerate(rows):
            if index:
                budget.add(1)
            keys = table['schemas'][int(row[0])]
            budget.add(2)
            for cell_index, (key, cell) in enumerate(zip(keys, row[1:])):
                if cell_index:
                    budget.add(1)
                _charge_string(key, budget)
                budget.add(1)
                _charge_graph(cell, budget, len(table['path']) + 2)
    return budget.total


def _v2_preflight(value, maximum):
    # This complete graph pass precedes descriptor handling and all row allocation.
    normalized_size(value, maximum)
    if (set(value) != {'transport_version', 'payload', 'aliases', 'row_tables'}
            or type(value['payload']) is not dict or type(value['aliases']) is not list
            or type(value['row_tables']) is not list):
        raise ValueError('Invalid v2 transport envelope')
    tables = value['row_tables']
    if len(tables) > WORK_LIMITS['tables']:
        raise ValueError('Transport table work limit exceeded')
    paths, row_total, cell_total = set(), 0, 0
    for table in tables:
        if type(table) is not dict or set(table) != {'path', 'schemas', 'rows'}:
            raise ValueError('Invalid transport table metadata')
        path = _path(table['path'])
        if any(path[:len(other)] == other or other[:len(path)] == path for other in paths):
            raise ValueError('Duplicate or overlapping transport paths')
        if _lookup(value['payload'], path) is not None:
            raise ValueError('Transport destination must be null')
        paths.add(path)
        schemas, rows = table['schemas'], table['rows']
        if type(schemas) is not list or not 1 <= len(schemas) <= WORK_LIMITS['schemas_per_table']:
            raise ValueError('Invalid transport schemas')
        seen = set()
        for keys in schemas:
            if (type(keys) is not list or not 1 <= len(keys) <= WORK_LIMITS['keys_per_schema']
                    or not all(_component(key) for key in keys) or len(set(keys)) != len(keys)
                    or tuple(keys) in seen):
                raise ValueError('Invalid transport schema')
            seen.add(tuple(keys))
        if type(rows) is not list or len(rows) < 2:
            raise ValueError('Invalid transport rows')
        row_total += len(rows)
        if row_total > WORK_LIMITS['rows']:
            raise ValueError('Transport row work limit exceeded')
        for row in rows:
            if (type(row) is not list or not row or not _integral(row[0])
                    or row[0] < 0 or row[0] >= len(schemas)):
                raise ValueError('Invalid transport schema index')
            keys = schemas[int(row[0])]
            if len(row) != len(keys) + 1 or any(type(cell) in (dict, list) for cell in row[1:]):
                raise ValueError('Invalid transport row cells')
            cell_total += len(keys)
            if cell_total > WORK_LIMITS['cells']:
                raise ValueError('Transport cell work limit exceeded')
    _aliases_preflight(value['payload'], value['aliases'], paths)
    _expanded_charge(value['payload'], tables, maximum)


def _copy_write(root, original, path, replacement, copied):
    """Copy only the destination's record ancestors, reusing staged copies."""
    parent, source = root, original
    prefix = ()
    for key in path[:-1]:
        prefix += (key,)
        source = source[key]
        if prefix not in copied:
            parent[key] = dict(source)
            copied.add(prefix)
        parent = parent[key]
    parent[path[-1]] = replacement


def _pack_tables(logical):
    tables, totals = [], dict(rows=0, cells=0)
    def visit(record, path=()):
        for key, value in record.items():
            destination = path + (key,)
            if type(value) is dict:
                if len(destination) < WORK_LIMITS['path_depth'] and all(_component(k) for k in destination):
                    visit(value, destination)
                continue
            if (type(value) is not list or len(value) < 2 or len(tables) >= WORK_LIMITS['tables']
                    or len(destination) > WORK_LIMITS['path_depth'] or not all(_component(k) for k in destination)
                    or totals['rows'] + len(value) > WORK_LIMITS['rows']):
                continue
            schemas, schema_ids, packed, cells = [], {}, [], 0
            for row in value:
                if (type(row) is not dict or not row or len(row) > WORK_LIMITS['keys_per_schema']
                        or not all(_component(k) for k in row)
                        or any(type(cell) in (dict, list) for cell in row.values())):
                    break
                keys = tuple(row)
                if keys not in schema_ids:
                    if len(schemas) >= WORK_LIMITS['schemas_per_table']:
                        break
                    schema_ids[keys] = len(schemas)
                    schemas.append(list(keys))
                cells += len(keys)
                if totals['cells'] + cells > WORK_LIMITS['cells']:
                    break
                packed.append([schema_ids[keys], *row.values()])
            else:
                table = dict(path=list(destination), schemas=schemas, rows=packed)
                # Incremental envelope cost: null + descriptor + inter-table comma.
                overhead = 4 + len(compact(table).encode('utf-8')) + bool(tables)
                if overhead < len(compact(value).encode('utf-8')):
                    record[key] = None
                    tables.append(table)
                    totals['rows'] += len(value)
                    totals['cells'] += cells
    visit(logical)
    return tables


def _copy_json_occurrences(value):
    # JSON repeats acyclic shared branches; preserving deepcopy identity would
    # let packing one path replace an unrelated occurrence's array with null.
    if type(value) is dict:
        return {key: _copy_json_occurrences(child) for key, child in value.items()}
    if type(value) is list:
        return [_copy_json_occurrences(child) for child in value]
    return value


def encode_transport(payload, transport_version=2, max_bytes=None):
    if type(payload) is not dict or not _integral(transport_version) or transport_version not in (1, 2):
        raise ValueError('Unsupported transport')
    maximum = _byte_limit(max_bytes)
    # Bound validation before copying. Each reviewed alias has one canonical
    # source and removes at most a second occurrence of that source's data.
    # The exact pre-alias/envelope gates below still enforce maximum itself.
    _charge_graph(payload, _Budget(2 * maximum))
    logical = _copy_json_occurrences(payload)
    aliases = []
    infra = logical.get('review_infrastructure_sections', {})
    for target, source in ALIASES.items():
        if type(infra) is dict and isinstance(infra.get(target), list) and isinstance(logical.get(source), list) and compact(infra[target]) == compact(logical[source]):
            del infra[target]
            aliases.append(dict(target=['review_infrastructure_sections',target],source=[source]))
    # Charge the pre-alias logical graph before replacing any arrays.
    normalized_size(logical, maximum)
    envelope = dict(transport_version=int(transport_version), payload=logical, aliases=aliases)
    if transport_version == 2:
        envelope['row_tables'] = _pack_tables(logical)
        _v2_preflight(envelope, maximum)
    else:
        normalized_size(envelope, maximum)
    return envelope


def decode_transport(value, max_bytes=None):
    if not isinstance(value, dict):
        raise ValueError('Payload must be an object')
    if 'transport_version' not in value:
        return value
    version = value['transport_version']
    if not _integral(version) or version not in (1, 2):
        raise ValueError('Unsupported transport')
    if version == 2:
        _v2_preflight(value, _byte_limit(max_bytes))
        original = value['payload']
        logical, copied = dict(original), {()}
        for table in value['row_tables']:
            rows = [dict(zip(table['schemas'][int(row[0])], row[1:])) for row in table['rows']]
            _copy_write(logical, original, table['path'], rows, copied)
        # Validate all reconstructed sources before any staged alias write.
        _aliases_preflight(logical, value['aliases'])
        for alias in value['aliases']:
            _copy_write(logical, original, alias['target'], _lookup(logical, alias['source']), copied)
        return logical
    if not isinstance(value.get('payload'), dict) or not isinstance(value.get('aliases'), list):
        raise ValueError('Unsupported transport')
    logical = copy.deepcopy(value['payload'])
    used = set()
    for alias in value['aliases']:
        target, source = alias.get('target'), alias.get('source')
        if not isinstance(target,list) or len(target)!=2 or target[0]!='review_infrastructure_sections' or target[1] not in ALIASES or source != [ALIASES[target[1]]] or target[1] in used:
            raise ValueError('Unreviewed transport alias')
        parent = logical.get(target[0])
        if not isinstance(parent,dict) or target[1] in parent or not isinstance(logical.get(source[0]),list):
            raise ValueError('Invalid transport alias')
        used.add(target[1]); parent[target[1]] = logical[source[0]]
    return logical


def _registration(build_id, table_id, shard_id, rows_json):
    script = 'window.DALYCARE_OUTPUTS.register(' + compact(dict(schema_version=1,build_id=build_id,table_id=table_id,shard_id=shard_id,rows_json=rows_json)) + ');\n'
    return rows_json, script


def _field_labels(dictionary):
    labels = {}
    for row in dictionary or []:
        if not isinstance(row, dict) or row.get('kind') != 'field':
            continue
        source, field, label = (row.get(key) for key in ('system', 'code', 'label'))
        if any(not isinstance(value, str) or not value.strip() for value in (source, field, label)):
            raise ValueError('Invalid field label dictionary row')
        if source in {'__proto__', 'constructor', 'prototype'} or field in {'__proto__', 'constructor', 'prototype'}:
            raise ValueError('Unsafe field label dictionary key')
        fields = labels.setdefault(source, {})
        if field in fields and fields[field] != label:
            raise ValueError('Conflicting field label dictionary pair')
        fields[field] = label
    return labels


def _vital_profiles(profiles):
    """Project exact measurement metadata from already guarded profile rows."""
    event_fields = {'displayname', 'numericvalue', 'recorded_time', 'meas_value', 'meas_value_clean',
                    'val_type_c', 'val_type_name', 'isaccepted_yn', 'template_name',
                    'date_received', 'datetime_created'}
    dedicated = {'SP_PatientInfo': {'bmi', 'weight_in_kg', 'height_in_cm'},
                 'RKKP_DaMyDa': {'Reg_Hoejde', 'Reg_Vaegt'}}
    identity = ('table_name', 'column_name', 'column_type', 'column_class')
    summary = ('n_rows', 'n_available', 'pct_available', 'mean', 'median', 'p25', 'p75',
               'numeric_privacy_status', 'availability_privacy_status', 'summary_scope',
               'summary_method', 'is_sensitive')
    selected = []
    for row in profiles or []:
        if not isinstance(row, dict):
            continue
        table, field = row.get('table_name'), row.get('column_name')
        if not isinstance(table, str) or not isinstance(field, str):
            continue
        if table == 'SP_VitaleVaerdier' and field in event_fields:
            keys = identity
        elif field in dedicated.get(table, set()):
            keys = identity + summary
        else:
            continue
        selected.append({key: row.get(key) for key in keys})
    return selected


def write_site_bundle(output_dir, payload, tables, project_root, provenance, manifest_inputs=None, transport_version=None):
    transport_version = resolve_transport_version(transport_version)
    requested = Path(output_dir).absolute()
    output = requested.parent.resolve() / requested.name
    if output.resolve() != output or output.is_symlink() or output == output.parent or (output.exists() and not output.is_dir()):
        raise ValueError('Unsafe site destination')
    root = Path(project_root)
    registry = load_registry(root)
    maximum = _byte_limit(registry['input_max_bytes'])
    _charge_graph(payload, _Budget(maximum), reject_proto=True)
    minimum = effective_threshold(payload)
    # Restore full evidence at its reviewed paths before guarding, including profile context.
    logical = copy.deepcopy(payload)
    specs = {s['id']:s for s in registry['artifacts']}
    for table in tables:
        spec = specs.get(table['id'])
        if spec and spec['payload_path'] and spec['projection']:
            _set(logical,spec['payload_path'],table['rows'])
    from metadata_privacy import metadata_context
    context=metadata_context(logical,root)
    safe_tables = sanitize_public_payload(logical, minimum, root, context)
    if audit_public_payload(safe_tables, project_root=root, min_cell_count=minimum, metadata_context=context):
        raise ValueError('Public privacy audit failed')
    synthetic=os.environ.get('DALYCARE_SYNTHETIC_VALIDATION')=='TRUE' or str(payload.get('run_id','')).startswith('SYNTHETIC') or str(payload.get('fixture_notice','')).startswith('SYNTHETIC')
    build_id = uuid.uuid4().hex
    guarded = dict(synthetic_validation=synthetic,export_contract='dalycare-lazy-v1',build_id=build_id,run_id=payload.get('run_id',''),privacy_metadata=safe_tables.get('privacy_metadata',{}),directory='DALYCARE_directory.js',search='DALYCARE_search.js')
    encoded = encode_transport(guarded, transport_version, maximum)
    _charge_graph(encoded, _Budget(maximum), reject_proto=True)
    transport = compact(encoded)
    payload_script = 'window.DALYCARE_ATLAS_PAYLOAD = '+transport+';\n'
    payload_json = transport+'\n'
    if max(len(payload_script.encode('utf-8')),len(payload_json.encode('utf-8'))) > maximum:
        raise ValueError('Actual payload asset byte budget exceeded')
    output.parent.mkdir(parents=True,exist_ok=True)
    stage = output.parent / ('.'+output.name+'-stage-'+build_id)
    backup = output.parent / ('.'+output.name+'-previous-'+build_id)
    manifest = output.with_name(output.name+'.manifest.json')
    manifest_stage = output.parent / ('.'+output.name+'-manifest-stage-'+build_id)
    manifest_backup = output.parent / ('.'+output.name+'-manifest-previous-'+build_id)
    if manifest.is_symlink() or (manifest.exists() and not manifest.is_file()):
        raise ValueError('Unsafe manifest destination')
    stage.mkdir()
    try:
        resources = {'DALYCARE_atlas.html':'DALYCARE_entry.html','DALYCARE_clinical.html':'DALYCARE_lazy.html', **{name:name for name in ('atlas-entry.js','atlas-outputs.js','atlas-transport.js','atlas-pages.css','atlas-vitals.js','atlas-vitals.css')}}
        resources['DALYCARE_outputs.html']='DALYCARE_lazy.html'
        resources.update({name:name for name in ('atlas-reader.js','atlas-shell.js','atlas-shell.css','atlas-topic.js','atlas-topic.css','atlas-route-registries.js','atlas-route-vitals.js','atlas-route-laboratory.js','atlas-route-treatment.js','atlas-route-situation.js','atlas-route-feasibility.js','atlas-route-infrastructure.js','atlas-route-variables.js','atlas-route-ehr.js','atlas-route-timeplace.js','atlas-route-sources.js','favicon.svg')})
        for name, source in resources.items():
            shutil.copyfile(root/'inst/templates'/source,stage/name)
        def write(name, text):
            if name.startswith('table-descriptors/') and len(text.encode('utf-8'))>262144:raise ValueError('Descriptor byte budget exceeded')
            (stage/name).write_bytes(text.encode('utf-8'))
        from registry_v2 import public_resource
        write('registry-v2.js','window.DALYCARE_REGISTRY_BUILD_ID = '+compact(build_id)+';\nwindow.DALYCARE_REGISTRY_V2_RESOURCE = '+compact(public_resource(root))+';\n'+(root/'inst/templates/registry-v2.js').read_text(encoding='utf-8'))
        write('DALYCARE_atlas_payload.js',payload_script)
        write('DALYCARE_atlas_payload.json',payload_json)
        entry = dict(synthetic_validation=synthetic,schema_version=1,build_id=build_id,run_id=payload.get('run_id',''),provenance=provenance)
        if provenance not in ('csv_outputs','legacy_payload'):
            raise ValueError('Invalid entry provenance')
        write('DALYCARE_entry.js','window.DALYCARE_ENTRY = '+compact(entry)+';\n')
        (stage/'output-shards').mkdir()
        (stage/'table-descriptors').mkdir()
        (stage/'downloads').mkdir()
        canonical = {}
        catalogue_tables, total = [], 0
        seen = set()
        for table in tables:
            table = copy.deepcopy(table)
            table_id = table['id']
            table.setdefault('title',table_id)
            if not re.fullmatch('[A-Za-z0-9_-]+',table_id) or table_id in seen:
                raise ValueError('Invalid table identity')
            seen.add(table_id)
            spec = specs.get(table_id)
            rows = _get(safe_tables,spec['payload_path']) if spec and spec['projection'] and spec['payload_path'] else []
            rows = rows or []
            keys = [c['key'] for c in table['columns']]
            if table_id!='registry_field_summaries':
                for key in sorted(PRIVACY_COLUMNS.intersection(k for r in rows for k in r)-set(keys)):
                    table['columns'].append(dict(key=key,label=key,type='boolean' if key=='is_sensitive' else 'string'));keys.append(key)
            allowed = set(spec['projection']) | PRIVACY_COLUMNS if spec else set()
            if not set(keys) <= allowed or (not spec and (table['columns'] or table['source_file'])):
                raise ValueError('Unreviewed public schema')
            if table_id!='registry_field_summaries': rows = [{k:r.get(k) for k in keys} for r in rows]
            table.pop('rows',None); table['shards'] = []
            if table['status'] == 'snapshot_preview': table['status'] = 'limited'
            pending, parts = [], []
            pending_bytes = 2  # JSON array brackets, including for an empty shard.
            _, empty_script = _registration(build_id,table_id,'s0001','[]')
            pending_script_bytes = len(empty_script.encode('utf-8'))
            shard_target=131072 if table_id in ('column_profiles','registry_field_summaries','semantic_dictionary') else SHARD_BYTES
            pending_source=None
            shard_row_limit=50 if table_id=='registry_field_summaries' else 100 if table_id=='column_profiles' else 250
            for row in rows:
                for col in table['columns']:
                    v = row.get(col['key']); kind = col['type']
                    if v is not None and not ((kind=='string' and isinstance(v,str)) or (kind=='boolean' and isinstance(v,bool)) or (kind=='number' and isinstance(v,(float,int)) and not isinstance(v,bool))):
                        raise ValueError('Typed evidence mismatch: '+table_id)
                # Serialize each row once. JSON string escaping is additive across
                # row fragments; only brackets and commas belong to the array.
                serialized = compact(row)
                row_bytes = len(serialized.encode('utf-8'))
                escaped_bytes = len(compact(serialized).encode('utf-8')) - 2
                separator = int(bool(pending))
                source=row.get('source_name') or row.get('table_name','')
                if (pending and table_id in ('column_profiles','registry_field_summaries','semantic_dictionary') and source!=pending_source) or len(pending)>=shard_row_limit or pending_bytes+separator+row_bytes>shard_target or pending_script_bytes+separator+escaped_bytes>shard_target:
                    if pending:
                        parts.append(pending); pending=[]
                    pending_bytes = 2
                    _, empty_script = _registration(build_id,table_id,'s'+str(len(parts)+1).zfill(4),'[]')
                    pending_script_bytes = len(empty_script.encode('utf-8'))
                    separator = 0
                    if pending_bytes+row_bytes>SHARD_BYTES or pending_script_bytes+escaped_bytes>SHARD_BYTES:
                        if spec and spec.get('required'):
                            raise ValueError('Required table row exceeds shard limit')
                        parts=[];pending=[];rows=[]
                        table.update(status='unavailable',reason='Row exceeds public shard byte limit',complete=False)
                        break
                pending_source=source
                pending.append(serialized)
                pending_bytes += separator+row_bytes
                pending_script_bytes += separator+escaped_bytes
            if pending:
                parts.append(pending)
            canonical[table_id] = rows
            with (stage/'downloads'/f'{table_id}.csv').open('w',encoding='utf-8',newline='') as stream:
                writer=csv.writer(stream,lineterminator='\n'); writer.writerow(keys)
                writer.writerows([('true' if r.get(k) else 'false') if type(r.get(k)) is bool else r.get(k) for k in keys] for r in rows)
            table['represented_row_count'] = len(rows)
            for i, part in enumerate(parts,1):
                shard_id = 's'+str(i).zfill(4)
                data, script = _registration(build_id,table_id,shard_id,'['+','.join(part)+']')
                if max(len(data.encode('utf-8')),len(script.encode('utf-8')))>SHARD_BYTES:
                    raise ValueError('Table shard exceeds byte limit')
                relative = 'output-shards/'+table_id+'-'+shard_id+'.js'
                write(relative,script); size=len(data.encode());total+=size
                shard=dict(id=shard_id,src=relative,rows=len(part),bytes=size,asset_bytes=len(script.encode('utf-8')))
                if table_id in ('column_profiles','registry_field_summaries','semantic_dictionary'):shard['fields']=[[r.get('source_name' if table_id=='semantic_dictionary' else 'table_name'),r.get('raw_column' if table_id=='semantic_dictionary' else 'column_name' if table_id=='column_profiles' else 'source_column')] for r in map(json.loads,part)]
                table['shards'].append(shard)
            catalogue_tables.append(table)
            write('table-descriptors/'+table_id+'.js','window.DALYCARE_OUTPUTS.registerDescriptor('+compact(dict(schema_version=1,build_id=build_id,table=table))+');\n')
        if total>registry['public_table_max_bytes']:
            raise ValueError('Public table-data budget exceeded')
        limits = dict(input_max_bytes=registry['input_max_bytes'],public_table_max_bytes=registry['public_table_max_bytes'],shard_max_rows=250,shard_max_bytes=SHARD_BYTES,cache_max_bytes=1048576,page_rows=50,minimum_cell_count=minimum,public_table_bytes=total)
        catalogue = dict(schema_version=1,build_id=build_id,run_id=payload.get('run_id',''),provenance=provenance,privacy_policy_version=VERSION,minimum_cell_count=minimum,limits=limits,tables=catalogue_tables)
        write('DALYCARE_output_catalogue.js','window.DALYCARE_OUTPUT_CATALOGUE = '+compact(catalogue)+';\n')
        directory=dict(synthetic_validation=synthetic,schema_version=2,build_id=build_id,run_id=payload.get('run_id',''),minimum_cell_count=minimum,tables=[{k:t[k] for k in ('id','title','status','represented_row_count') if k in t}|dict(descriptor='table-descriptors/'+t['id']+'.js') for t in catalogue_tables])
        directory['sources']=[{k:r.get(k) for k in ('table_name','load_status','domain','subdomain')} for r in (canonical.get('sources') or safe_tables.get('catalog_rows') or []) if isinstance(r,dict) and isinstance(r.get('table_name'),str)]
        write('DALYCARE_membership.js','window.DALYCARE_MEMBERSHIP = '+compact(dict(build_id=build_id,inventory=safe_tables.get('clinical_source_inventory')))+';\n')
        write_reference_index(stage,build_id,canonical,catalogue_tables,directory)
        write('DALYCARE_directory.js','window.DALYCARE_DIRECTORY = '+compact(directory)+';\n')
        labels=_field_labels(canonical.get('clinical_display_dictionary',[]))
        sources=[]; fields=[]; seen_fields=set()
        for row in canonical.get('column_profiles',[]):
            source,field=row.get('table_name'),row.get('column_name')
            if not isinstance(source,str) or not isinstance(field,str) or (source,field) in seen_fields:continue
            seen_fields.add((source,field))
            if source not in sources:sources.append(source)
            fields.append([sources.index(source),field,labels.get(source,{}).get(field,'')])
        write('DALYCARE_search.js','window.DALYCARE_SEARCH = '+compact(dict(schema_version=1,build_id=build_id,sources=sources,fields=fields))+';\n')
        for names in [('DALYCARE_atlas.html','DALYCARE_entry.js','atlas-entry.js','atlas-pages.css'),('DALYCARE_clinical.html','DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js','atlas-topic.js','atlas-shell.css','atlas-topic.css')]:
            if sum((stage/n).stat().st_size for n in names)>ENTRY_BYTES:
                raise ValueError('Initial asset byte budget exceeded')
        for name in ('THIRD_PARTY_NOTICES.txt','OPERATING.txt'):
            shutil.copyfile(root/'inst/templates'/name,stage/name)
        terminology=json.loads((root/'config/terminology/manifest.json').read_text(encoding='utf-8-sig'))
        loading_budget(stage,directory)
        public_manifest(stage,build_id,payload.get('run_id',''),VERSION,terminology,payload.get('publication_phase_summary',canonical.get('run_summary',[])))
        files = sorted(p.relative_to(stage) for p in stage.rglob('*') if p.is_file())
        if any((stage/f).stat().st_size==0 for f in files):
            raise ValueError('Empty site asset')
        internal = dict(schema_version=1,build_id=build_id,run_id=payload.get('run_id',''),provenance=provenance,limits=limits,
                        assets=[dict(path=f.as_posix(),bytes=(stage/f).stat().st_size) for f in files],inputs=manifest_inputs or [])
        manifest_stage.write_bytes((compact(internal)+'\n').encode('utf-8'))
        # Two artifacts form one publication. Restore both on either rename failure.
        moved_site = moved_manifest = published_site = False
        try:
            if output.exists():
                output.rename(backup); moved_site = True
            if manifest.exists():
                manifest.rename(manifest_backup); moved_manifest = True
            stage.rename(output); published_site = True
            manifest_stage.rename(manifest)
        except BaseException:
            if published_site:
                shutil.rmtree(output)
            if moved_site: backup.rename(output)
            if moved_manifest: manifest_backup.rename(manifest)
            raise
        try:
            if backup.exists(): shutil.rmtree(backup)
            if manifest_backup.exists(): manifest_backup.unlink()
        except OSError:
            warnings.warn('Bundle published; previous backup could not be removed', RuntimeWarning)
        return dict(html=output/'DALYCARE_atlas.html',clinical_html=output/'DALYCARE_clinical.html',payload=output/'DALYCARE_atlas_payload.js',payload_json=output/'DALYCARE_atlas_payload.json',catalogue=output/'DALYCARE_output_catalogue.js',manifest=manifest,assets=[output/f for f in files])
    finally:
        if stage.exists(): shutil.rmtree(stage)
        if manifest_stage.exists(): manifest_stage.unlink()


def write_reference_index(stage,build_id,canonical,tables,directory):
    source=next((t for t in tables if t['id']=='npu_display_dictionary'),None)
    if source is None:return
    data=canonical.get('npu_display_dictionary',[]);offset=0;rows=[]
    for shard in source['shards']:
        for row in data[offset:offset+shard['rows']]:
            words=dict.fromkeys(re.findall(r"[\w]+",' '.join(str(v) for v in row.values() if v is not None).lower()))
            rows.append(dict(code=row.get('code',''),label=row.get('label',''),terms=' '.join(words),shard=shard['id']))
        offset+=shard['rows']
    rows.sort(key=lambda r:r['code'])
    t=dict(id='npu_reference_search',title='NPU reference search',status='available' if rows else 'empty_output',represented_row_count=len(rows),complete=True,columns=[dict(key=k,label=k,type='string') for k in ('code','label','terms','shard')],shards=[])
    parts=[];pending=[];pending_bytes=0
    for row in rows:
        encoded=compact(row);charge=len(compact(encoded).encode('utf-8'))+1
        if pending and (len(pending)>=100 or pending_bytes+charge>SHARD_BYTES-512):
            parts.append(pending);pending=[];pending_bytes=0
        if charge>SHARD_BYTES-512:raise ValueError('Reference search row exceeds byte budget')
        pending.append(encoded);pending_bytes+=charge
    if pending:parts.append(pending)
    offset=0
    for i,part in enumerate(parts,1):
        sid='s'+str(i).zfill(4);raw,script=_registration(build_id,t['id'],sid,'['+','.join(part)+']');relative='output-shards/'+t['id']+'-'+sid+'.js'
        if len(script.encode('utf-8'))>SHARD_BYTES:raise ValueError('Reference search shard budget')
        (stage/relative).write_text(script,encoding='utf-8',newline='')
        t['shards'].append(dict(id=sid,src=relative,rows=len(part),bytes=len(raw.encode('utf-8')),first=rows[offset]['code'],last=rows[offset+len(part)-1]['code'],definitions=list(dict.fromkeys(r['shard'] for r in rows[offset:offset+len(part)]))))
        offset+=len(part)
    relative='table-descriptors/'+t['id']+'.js'
    descriptor='window.DALYCARE_OUTPUTS.registerDescriptor('+compact(dict(schema_version=1,build_id=build_id,table=t))+');\n'
    if len(descriptor.encode('utf-8'))>262144:raise ValueError('Reference descriptor byte budget exceeded')
    (stage/relative).write_text(descriptor,encoding='utf-8',newline='')
    directory['tables'].append({k:t[k] for k in ('id','title','status','represented_row_count','complete')}|dict(descriptor=relative))
    with (stage/'downloads'/f"{t['id']}.csv").open('w',encoding='utf-8',newline='') as stream:
        w=csv.DictWriter(stream,fieldnames=['code','label','terms','shard'],lineterminator='\n');w.writeheader();w.writerows(rows)
