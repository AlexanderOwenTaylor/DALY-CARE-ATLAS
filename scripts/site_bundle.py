"""Bounded classic-script site bundles, published from a complete sibling stage."""
import copy
import json
import re
import shutil
import uuid
import warnings
from pathlib import Path
from output_evidence import load_registry, _get, _set
from public_privacy import sanitize_public_payload, audit_public_payload, effective_threshold, VERSION

ALIASES = dict(action_items='action_items', action_summary='action_summary', streaming_summary='review_streaming_summary', temporal_date_quality='review_temporal_date_quality', db_budget_actions='db_budget_actions', db_query_log='db_query_log', catalog='catalog_rows', resource_reconciliation='resource_reconciliation_rows', canonical_resource_reconciliation='canonical_resource_reconciliation_rows', current_run_source_map_audit='current_run_source_map_audit_rows', source_map_crosswalk='source_map_crosswalk_rows', source_resolution_delta='source_resolution_delta_rows', legacy_resource_audit='legacy_cartography_audit_rows', columns='column_profile_rows', column_summary='column_profile_summary', panels='panel_groups', qa='qa_items', run_summary='run_summary')
SHARD_BYTES = 262144
ENTRY_BYTES = 524288
PRIVACY_COLUMNS = {'value_privacy_status','count_privacy_status','date_privacy_status','availability_privacy_status','numeric_privacy_status','summary_scope','summary_method','is_sensitive'}


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(',', ':'), allow_nan=False)


def encode_transport(payload):
    logical = copy.deepcopy(payload)
    aliases = []
    infra = logical.get('review_infrastructure_sections', {})
    for target, source in ALIASES.items():
        if isinstance(infra.get(target), list) and isinstance(logical.get(source), list) and compact(infra[target]) == compact(logical[source]):
            del infra[target]
            aliases.append(dict(target=['review_infrastructure_sections',target],source=[source]))
    return dict(transport_version=1,payload=logical,aliases=aliases)


def decode_transport(value):
    if not isinstance(value, dict):
        raise ValueError('Payload must be an object')
    if 'transport_version' not in value:
        return value
    if value['transport_version'] != 1 or not isinstance(value.get('payload'), dict) or not isinstance(value.get('aliases'), list):
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


def _registration(build_id, table_id, shard_id, rows):
    rows_json = compact(rows)
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


def write_site_bundle(output_dir, payload, tables, project_root, provenance, manifest_inputs=None):
    requested = Path(output_dir).absolute()
    output = requested.parent.resolve() / requested.name
    if output.resolve() != output or output.is_symlink() or output == output.parent or (output.exists() and not output.is_dir()):
        raise ValueError('Unsafe site destination')
    root = Path(project_root)
    registry = load_registry(root)
    minimum = effective_threshold(payload)
    # Restore full evidence at its reviewed paths before guarding, including profile context.
    logical = copy.deepcopy(payload)
    specs = {s['id']:s for s in registry['artifacts']}
    for table in tables:
        spec = specs.get(table['id'])
        if spec and spec['payload_path'] and spec['projection']:
            _set(logical,spec['payload_path'],table['rows'])
    safe_tables = sanitize_public_payload(logical, minimum, root)
    guarded = sanitize_public_payload(payload, minimum, root)
    if audit_public_payload(safe_tables) or audit_public_payload(guarded):
        raise ValueError('Public privacy audit failed')
    field_labels = _field_labels(safe_tables.get('clinical_display_dictionary'))
    transport = compact(encode_transport(guarded))
    build_id = uuid.uuid4().hex
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
        resources = {'DALYCARE_atlas.html':'DALYCARE_entry.html','DALYCARE_clinical.html':'DALYCARE_atlas.html', **{name:name for name in ('DALYCARE_outputs.html','atlas-entry.js','atlas-outputs.js','atlas-transport.js','atlas-pages.css')}}
        for name, source in resources.items():
            shutil.copyfile(root/'inst/templates'/source,stage/name)
        def write(name, text):
            (stage/name).write_bytes(text.encode('utf-8'))
        write('DALYCARE_atlas_payload.js','window.DALYCARE_ATLAS_PAYLOAD = '+transport+';\n')
        write('DALYCARE_atlas_payload.json',transport+'\n')
        entry = dict(schema_version=1,build_id=build_id,run_id=payload.get('run_id',''),provenance=provenance)
        if provenance not in ('csv_outputs','legacy_payload'):
            raise ValueError('Invalid entry provenance')
        write('DALYCARE_entry.js','window.DALYCARE_ENTRY = '+compact(entry)+';\n')
        (stage/'output-shards').mkdir()
        catalogue_tables, total = [], 0
        seen = set()
        for table in tables:
            table = copy.deepcopy(table)
            table_id = table['id']
            if not re.fullmatch('[A-Za-z0-9_-]+',table_id) or table_id in seen:
                raise ValueError('Invalid table identity')
            seen.add(table_id)
            spec = specs.get(table_id)
            rows = _get(safe_tables,spec['payload_path']) if spec and spec['projection'] and spec['payload_path'] else []
            rows = rows or []
            keys = [c['key'] for c in table['columns']]
            allowed = set(spec['projection']) | PRIVACY_COLUMNS if spec else set()
            if not set(keys) <= allowed or (not spec and (table['columns'] or table['source_file'])):
                raise ValueError('Unreviewed public schema')
            rows = [{k:r.get(k) for k in keys} for r in rows]
            table.pop('rows',None); table['shards'] = []
            if table['status'] == 'snapshot_preview': table['status'] = 'limited'
            pending, parts = [], []
            for row in rows:
                for col in table['columns']:
                    v = row[col['key']]; kind = col['type']
                    if v is not None and not ((kind=='string' and isinstance(v,str)) or (kind=='boolean' and isinstance(v,bool)) or (kind=='number' and isinstance(v,(float,int)) and not isinstance(v,bool))):
                        raise ValueError('Typed evidence mismatch: '+table_id)
                trial = pending+[row]
                data, script = _registration(build_id,table_id,'s'+str(len(parts)+1).zfill(4),trial)
                if len(trial)>250 or len(data.encode())>SHARD_BYTES or len(script.encode())>SHARD_BYTES:
                    if pending:
                        parts.append(pending); pending=[]
                    data, script = _registration(build_id,table_id,'s'+str(len(parts)+1).zfill(4),[row])
                    if len(data.encode())>SHARD_BYTES or len(script.encode())>SHARD_BYTES:
                        if spec and spec.get('required'):
                            raise ValueError('Required table row exceeds shard limit')
                        parts=[];pending=[];rows=[]
                        table.update(status='unavailable',reason='Row exceeds public shard byte limit',complete=False)
                        break
                pending.append(row)
            if pending:
                parts.append(pending)
            table['represented_row_count'] = len(rows)
            for i, part in enumerate(parts,1):
                shard_id = 's'+str(i).zfill(4)
                data, script = _registration(build_id,table_id,shard_id,part)
                relative = 'output-shards/'+table_id+'-'+shard_id+'.js'
                write(relative,script); size=len(data.encode());total+=size
                table['shards'].append(dict(id=shard_id,src=relative,rows=len(part),bytes=size))
            catalogue_tables.append(table)
        if total>registry['public_table_max_bytes']:
            raise ValueError('Public table-data budget exceeded')
        limits = dict(input_max_bytes=registry['input_max_bytes'],public_table_max_bytes=registry['public_table_max_bytes'],shard_max_rows=250,shard_max_bytes=SHARD_BYTES,cache_max_bytes=1048576,page_rows=50,minimum_cell_count=minimum,public_table_bytes=total)
        catalogue = dict(schema_version=1,build_id=build_id,run_id=payload.get('run_id',''),provenance=provenance,privacy_policy_version=VERSION,limits=limits,tables=catalogue_tables)
        if field_labels:
            catalogue['field_labels'] = field_labels
        write('DALYCARE_output_catalogue.js','window.DALYCARE_OUTPUT_CATALOGUE = '+compact(catalogue)+';\n')
        for names in [('DALYCARE_atlas.html','DALYCARE_entry.js','atlas-entry.js','atlas-pages.css'),('DALYCARE_outputs.html','DALYCARE_output_catalogue.js','atlas-outputs.js','atlas-pages.css')]:
            if sum((stage/n).stat().st_size for n in names)>ENTRY_BYTES:
                raise ValueError('Initial asset byte budget exceeded')
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
