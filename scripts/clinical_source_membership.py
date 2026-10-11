"""Reviewed exact Clinical membership; selection never copies source evidence."""
import hashlib
import json
from pathlib import Path


RESOURCE_PATH = 'inst/config/clinical-source-membership.json'
RESOURCE_MAX_BYTES = 1048576
PANEL_IDS = frozenset((
    'diagnosis_atlas', 'clinical_adt', 'clinical_notes', 'clinical_microbiology',
    'clinical_imaging', 'clinical_pathology', 'clinical_biobank', 'clinical_vitals',
    'clinical_social_history', 'reg_damyda', 'reg_lyfo', 'reg_cll',
))
ROLES = frozenset(('primary', 'context', 'derived_view', 'text_availability'))
UNSAFE_KEYS = frozenset(('__proto__', 'prototype', 'constructor'))
LOADED = frozenset(('ok', 'loaded'))
NOT_LOADED = frozenset(('failed', 'mapped', 'not_loaded', 'not_tested', 'not_attempted', 'unavailable'))


def _fail(code):
    raise ValueError(code)


def _identity(value, code):
    if not isinstance(value, str) or not value or value != value.strip():
        _fail(code)
    if value in UNSAFE_KEYS:
        _fail('unsafe_resource_key')
    return value


def _check_unsafe(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key in UNSAFE_KEYS:
                _fail('unsafe_resource_key')
            _check_unsafe(child)
    elif isinstance(value, list):
        for child in value:
            _check_unsafe(child)
    elif isinstance(value, str) and value in UNSAFE_KEYS:
        _fail('unsafe_resource_key')


def validate_membership_spec(spec):
    """Validate the shared schema without normalizing or modifying its values."""
    if not isinstance(spec, dict):
        _fail('invalid_resource_shape')
    _check_unsafe(spec)
    if type(spec.get('schema_version')) is not int or spec['schema_version'] != 1:
        _fail('unsupported_schema_version')
    _identity(spec.get('inventory_version'), 'invalid_inventory_version')
    panels = spec.get('panels')
    if not isinstance(panels, list) or not panels:
        _fail('invalid_panels')
    panel_ids, families, aliases = set(), {}, {}
    for panel in panels:
        if not isinstance(panel, dict):
            _fail('invalid_panel_shape')
        panel_id = _identity(panel.get('panel_id'), 'invalid_panel_id')
        if panel_id not in PANEL_IDS:
            _fail('invalid_panel_id')
        if panel_id in panel_ids:
            _fail('duplicate_panel_id')
        panel_ids.add(panel_id)
        if 'review_key' in panel:
            _identity(panel['review_key'], 'invalid_review_key')
        sources = panel.get('sources')
        if not isinstance(sources, list) or not sources:
            _fail('invalid_sources')
        memberships = set()
        for source in sources:
            if not isinstance(source, dict):
                _fail('invalid_source_shape')
            family = _identity(source.get('membership_id'), 'invalid_membership_id')
            if family in memberships:
                _fail('duplicate_membership_id')
            memberships.add(family)
            keys = source.get('source_keys')
            if not isinstance(keys, list) or not keys:
                _fail('invalid_source_keys')
            seen = set()
            for key in keys:
                _identity(key, 'invalid_source_keys')
                if key in seen:
                    _fail('duplicate_source_key')
                seen.add(key)
            role = _identity(source.get('membership_role'), 'invalid_membership_role')
            if role not in ROLES:
                _fail('invalid_membership_role')
            _identity(source.get('evidence_layer'), 'invalid_evidence_layer')
            canonical = source.get('canonical_resource_id')
            if 'canonical_resource_id' in source:
                _identity(canonical, 'invalid_canonical_resource_id')
            signature = (tuple(keys), canonical)
            if family in families and families[family] != signature:
                _fail('conflicting_membership_family')
            families[family] = signature
            for key in keys:
                if key in aliases and aliases[key] != family:
                    _fail('conflicting_source_key')
                aliases[key] = family
    return spec


def _resource_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            _fail('duplicate_resource_object_key')
        result[key] = value
    return result


def load_membership_resource(project_root):
    """Read once at a build boundary and return validated spec plus input identity."""
    path = Path(project_root) / RESOURCE_PATH
    try:
        if not path.is_file() or path.stat().st_size > RESOURCE_MAX_BYTES:
            raise ValueError('missing_or_oversized_resource')
        raw = path.read_bytes()
        if len(raw) > RESOURCE_MAX_BYTES:
            raise ValueError('oversized_resource')
        spec = validate_membership_spec(json.loads(raw.decode('utf-8-sig'), object_pairs_hook=_resource_object))
        # Publication metadata advertises the complete reviewed panel set;
        # partial resources remain valid only for explicit pure-selector callers.
        if {panel['panel_id'] for panel in spec['panels']} != PANEL_IDS:
            _fail('incomplete_panel_coverage')
    except (OSError, UnicodeError, ValueError, RecursionError) as exc:
        raise ValueError(f'Required clinical source membership resource missing or malformed: {path}') from exc
    metadata = dict(path=str(path.resolve()), bytes=len(raw), provenance='project_reference',
                    artifact_id='clinical_source_membership', schema_version=spec['schema_version'],
                    inventory_version=spec['inventory_version'], sha256=hashlib.sha256(raw).hexdigest())
    return spec, metadata


def load_membership_spec(project_root):
    """Load from the explicitly selected project, with no ambient fallback."""
    return load_membership_resource(project_root)[0]


def clinical_source_inventory(catalog_rows, membership_spec,
                              evidence_origin='imported_snapshot', inventory_limited=False):
    """Select exact supplied identities from validated metadata, without I/O."""
    if evidence_origin not in ('fresh_run', 'imported_snapshot'):
        _fail('invalid_evidence_origin')
    if type(inventory_limited) is not bool:
        _fail('invalid_inventory_limited')
    result = dict(schema_version=1, inventory_version=membership_spec['inventory_version'],
                  basis='reviewed_exact_source_inventory', evidence_origin=evidence_origin,
                  inventory_state='present', rows=[], diagnostics=[])

    def diagnose(code, source_key=None, membership_id=None):
        diagnostics = result['diagnostics']
        if len(diagnostics) < 100:
            diagnostics.append(dict(code=code, source_key=source_key, membership_id=membership_id))
        elif len(diagnostics) == 100:
            diagnostics.append(dict(code='diagnostics_truncated', source_key=None, membership_id=None))

    if catalog_rows is None:
        result['inventory_state'] = 'unavailable'
        diagnose('catalog_unavailable')
        return result
    if (not isinstance(catalog_rows, list) or any(
            not isinstance(row, dict) or not isinstance(row.get('table_name'), str)
            or not row['table_name'].strip() for row in catalog_rows)):
        result['inventory_state'] = 'unavailable'
        diagnose('catalog_malformed')
        return result
    if inventory_limited:
        result['inventory_state'] = 'limited'
        diagnose('catalog_limited')
    by_key = {}
    for row in catalog_rows:
        by_key.setdefault(row['table_name'], []).append(row)
    families, aliases = {}, {}
    for panel in membership_spec['panels']:
        for source in panel['sources']:
            families.setdefault(source['membership_id'], source)
            for key in source['source_keys']:
                aliases[key] = source['membership_id']
    conflicts = set()
    for key, supplied_rows in by_key.items():
        if len(supplied_rows) > 1:
            diagnose('duplicate_source_identity', key)
        family = aliases.get(key)
        if family is None:
            continue
        canonical = families[family].get('canonical_resource_id')
        supplied_ids, invalid = set(), False
        for row in supplied_rows:
            supplied = row.get('canonical_resource_id')
            if supplied is None:
                continue
            if not isinstance(supplied, str):
                invalid = True
            elif supplied.strip():
                supplied_ids.add(supplied)
        if invalid or len(supplied_ids) > 1 or (canonical is not None and any(i != canonical for i in supplied_ids)):
            conflicts.add(key)
            diagnose('canonical_lineage_conflict', key, family)
    family_multiple = {}
    for family, source in families.items():
        multiple = sum(key in by_key for key in source['source_keys']) > 1
        family_multiple[family] = multiple
        if multiple:
            diagnose('multiple_family_identities', membership_id=family)
    for panel in membership_spec['panels']:
        for source in panel['sources']:
            family = source['membership_id']
            for key in source['source_keys']:
                if key not in by_key:
                    continue
                supplied_rows = by_key[key]
                duplicate = len(supplied_rows) > 1
                canonical = source.get('canonical_resource_id')
                lineage = 'conflicting' if key in conflicts else 'established' if canonical is not None else 'unestablished'
                status = None if duplicate else supplied_rows[0].get('load_status')
                if not isinstance(status, str):
                    status = None
                result['rows'].append(dict(
                    panel_id=panel['panel_id'], membership_id=family, source_key=key,
                    canonical_resource_id=None if key in conflicts else canonical,
                    membership_role=source['membership_role'], evidence_layer=source['evidence_layer'],
                    catalog_identity_state='duplicate' if duplicate else 'unique', canonical_lineage_state=lineage,
                    family_identity_state='multiple' if family_multiple[family] else 'single',
                    load_status=status, load_state='loaded' if status in LOADED else 'not_loaded' if status in NOT_LOADED else 'unknown',
                ))
    return result
