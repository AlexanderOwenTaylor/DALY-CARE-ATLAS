"""Rebuild the static UI from an existing aggregate export, without a database run."""
import argparse
import csv
import json
import os
from pathlib import Path
from public_privacy import sanitize_public_payload, audit_public_payload, effective_threshold
from output_evidence import collect_output_evidence, load_registry, confined_path, read_registered_csv, read_build_context, _bound_source_file
from site_bundle import write_site_bundle, decode_transport, resolve_transport_version, _byte_limit
from clinical_source_membership import load_membership_resource, clinical_source_inventory
from semantic_catalogue import rebuild_semantics, validate_terminology


def build(input_dir, output_dir, project_root, run_dir=None, transport_version=None):
    transport_version = resolve_transport_version(transport_version)
    input_dir, output_dir, project_root = map(Path, (input_dir, output_dir, project_root))
    validate_terminology(project_root)
    membership_spec, membership_input = load_membership_resource(project_root)
    registry = load_registry(project_root)
    source = input_dir / 'DALYCARE_atlas_payload.js'
    maximum = _byte_limit(registry['input_max_bytes'])
    if source.stat().st_size > maximum:
        raise ValueError('Imported payload exceeds pre-read limit')
    raw = source.read_text(encoding='utf-8-sig')
    prefix = 'window.DALYCARE_ATLAS_PAYLOAD ='
    if not raw.strip().startswith(prefix):
        raise ValueError('Unrecognized atlas payload wrapper')
    payload = decode_transport(json.loads(raw.strip()[len(prefix):].strip().removesuffix(';')), max_bytes=maximum)
    context = matching_run_context(run_dir, payload, registry) if run_dir is not None else None
    minimum = effective_threshold(payload, context)
    rebuild_semantics(payload,project_root)
    for key in ('npu_display_dictionary','clinical_display_dictionary'):
        spec = next(s for s in registry['artifacts'] if s['id']==key)
        try:
            payload[key] = [{k: '' if v is None else v for k,v in row.items()} for row in read_registered_csv(project_root/spec['source_file'], spec, registry['input_max_bytes'])]
        except ValueError:
            payload[key] = []
    payload['display_metadata'] = {
        'version': '2026-10-11-clinician-9',
        'terminology_source': 'https://cms.ifcc.org/wp-content/uploads/npu-codes-latest.csv',
        'danish_alias_source': 'https://docs.ehealth.sundhed.dk/latest/ig/CodeSystem-mcs.json',
        'note': 'Public disclosure guard applied; stored source-row summaries and reference terminology.'
    }
    payload = sanitize_public_payload(payload, min_cell_count=minimum, project_root=project_root)
    payload['display_metadata'].update(payload['privacy_metadata'])
    # The legacy Clinical catalog has a 1000-row guard ceiling. Saturation means
    # possible truncation, not proof of omitted rows or complete upstream coverage.
    # Matching CSV evidence stays separate; it never replaces this snapshot basis.
    catalog = payload.get('catalog_rows')
    payload['clinical_source_inventory'] = clinical_source_inventory(
        catalog, membership_spec, evidence_origin='imported_snapshot',
        inventory_limited=isinstance(catalog, list) and len(catalog) >= 1000)
    errors = audit_public_payload(payload, project_root=project_root, min_cell_count=minimum)
    if errors:
        raise ValueError(f'Public privacy audit failed at {len(errors)} paths')
    tables = collect_output_evidence(run_dir, project_root, payload)
    inputs = [dict(path=str(source.resolve()),bytes=source.stat().st_size,provenance='legacy_payload'), membership_input]
    for spec in registry['artifacts']:
        base = project_root if spec.get('resource') else run_dir
        if base is not None:
            path = confined_path(base,spec['source_file'] if spec.get('resource') else _bound_source_file(spec,context))
            if path.is_file(): inputs.append(dict(path=str(path),bytes=path.stat().st_size,provenance='project_reference' if spec.get('resource') else 'csv_run',artifact_id=spec['id']))
    if context is not None:
        path=confined_path(run_dir,'outputs/atlas_build_context.json')
        inputs.append(dict(path=str(path),bytes=path.stat().st_size,provenance='build_context'))
    paths = write_site_bundle(output_dir, payload, tables, project_root, 'legacy_payload',manifest_inputs=inputs,transport_version=transport_version)
    print(f'Built {output_dir}: {paths["payload_json"].stat().st_size:,} transport bytes')
    return paths


def matching_run_context(run_dir, payload, registry):
    """Saved identity wins; historical migration requires the reviewed run metric."""
    run = Path(run_dir).resolve(strict=True)
    context = read_build_context(run, registry)
    identities = [context.get('run_id')] if context is not None else []
    spec = next(s for s in registry['artifacts'] if s['source_file']=='outputs/atlas_run_summary.csv')
    summary = confined_path(run, spec['source_file'])
    if summary.exists():
        rows = read_registered_csv(summary, spec, registry['input_max_bytes'])
        found = [r['value'] for r in rows if r['metric']=='run_id']
        if len(found)!=1:
            raise ValueError('Missing or conflicting run identity')
        identities.extend(found)
    if not identities or any(not isinstance(i,str) or not i or i!=payload.get('run_id') for i in identities):
        raise ValueError('Selected CSV run does not match imported payload identity')
    return context



if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input-dir', type=Path, required=True,
                        help='Directory containing DALYCARE_atlas_payload.js to rebuild')
    parser.add_argument('--output-dir', type=Path, required=True,
                        help='Directory in which to write the rebuilt HTML, JS, and JSON files')
    parser.add_argument('--run-dir', type=Path, help='Explicit matching CSV run to restore complete table evidence')
    parser.add_argument('--transport-version', choices=('1', '2'), help='Clinical payload transport version (default: environment or 2)')
    args = parser.parse_args()
    build(args.input_dir, args.output_dir, root, args.run_dir, args.transport_version)
