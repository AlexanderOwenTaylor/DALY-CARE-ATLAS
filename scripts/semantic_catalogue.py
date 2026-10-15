"""Offline display catalogue from exact current source/column metadata.

R remains the clinical assembler. This rebuild fallback restores field discovery
for older empty semantic exports; it does not manufacture clinical observations.
"""
import csv
import hashlib
import json
from pathlib import Path


def validate_terminology(root):
    config = Path(root)/'config'
    try:
        manifest=json.loads((config/'terminology/manifest.json').read_text(encoding='utf-8'))
        expected={'terminology/ifcc-npu-retrieved-2026-10-14/official.csv.gz',
            'terminology/ifcc-npu-retrieved-2026-10-14/reviewed-display-labels.csv','npu-display-dictionary.csv'}
        if (manifest['schema_version']!=1 or manifest['active_current_unique_codes']!=25699 or
            manifest['raw_sha256']!='3aef05383e918cc1304c53c5ca6f8a9467b6d700fc3ba18563744c1fbe904353' or
            len(manifest['files'])!=3 or {r['path'] for r in manifest['files']}!=expected):
            raise ValueError('Invalid pinned terminology manifest')
        for row in manifest['files']:
            raw=(config/row['path']).read_bytes()
            if len(raw)!=row['bytes'] or hashlib.sha256(raw).hexdigest()!=row['sha256']:
                raise ValueError('Local terminology checksum mismatch')
    except (OSError,KeyError,TypeError,json.JSONDecodeError) as exc:
        raise ValueError('Pinned local terminology unavailable or invalid') from exc
    return True


def exact_id(*parts):
    return 'current_'+'_'.join(str(p).encode('utf-8').hex() for p in parts)


def rebuild_semantics(payload,root):
    validate_terminology(root)
    with (Path(root)/'config/clinical-display-dictionary.csv').open(encoding='utf-8-sig',newline='') as f:
        labels={}
        for r in csv.DictReader(f):
            if r['kind']=='field':labels.setdefault((r['system'],r['code']),[]).append(r)
    columns=[r for r in (payload.get('column_profile_rows') or []) if isinstance(r,dict)]
    sources=[r for r in (payload.get('catalog_rows') or []) if isinstance(r,dict)]
    discovered={(r.get('table_name'),r.get('column_name')):r for r in columns if r.get('table_name') and r.get('column_name')}
    for source in sources:
        for field in (source.get('schema_signature') or '').split('|'):
            parts=field.split(':')
            if len(parts)==3 and parts[0] and source.get('table_name'):
                discovered.setdefault((source['table_name'],parts[0]),dict(profile_kind='metadata_only',column_type=parts[1]))
    existing=payload.get('semantic_dictionary_rows') or []
    rows=[r for r in existing if (r.get('source_name'),r.get('raw_column')) in discovered and
        (not r.get('raw_descriptor') or (r.get('source_name'),r.get('value_column')) in discovered)]
    for row in rows:
        if row.get('raw_descriptor'):
            row['mapping_status']='saved_definition_inventory_unassessed'
            note='Saved descriptor definition; current descriptor inventory unassessed; no current observation asserted.'
            caveat=row.get('clinical_caveat') or ''
            row['clinical_caveat']=caveat if note in caveat else '; '.join(filter(None,(caveat,note)))
            for key in ('n_rows','n_patients','pct_non_missing'):row[key]=None
            for key in ('min_date','max_date'):row[key]=''
    # A descriptor/code context does not replace generic field metadata.
    seen={(r.get('source_name'),r.get('raw_column')) for r in rows if
        not r.get('raw_descriptor') and r.get('data_shape')!='long_descriptor_table' and not r.get('raw_code') and not r.get('raw_value')}
    for (source,field),column in discovered.items():
        if (source,field) in seen:continue
        hits=labels.get((source,field),[])
        label=hits[0] if len(hits)==1 and hits[0].get('label') else None
        identifier=exact_id(source,field)
        rows.append(dict(semantic_id=identifier,clinical_concept_id=identifier,
            clinical_variable=label['label'] if label else field,clinical_group='Source fields',clinical_subgroup='Source fields',
            semantic_meaning=label['definition'] if label else 'Description unavailable',source_name=source,object_name=source,
            table_name=source,schema_name='',raw_column=field,raw_descriptor='',raw_code='',raw_value='',code_system='',unit='',
            value_type=column.get('column_type',''),data_shape='current_column_metadata',value_column=field,
            patient_id_column='',date_column='',source_level='',geography='',n_rows=None,n_patients=None,pct_non_missing=None,
            min_date='',max_date='',evidence_file='atlas_column_profiles.csv; atlas_sources.csv',evidence_filter=f'source={source}; column={field}',
            mapping_confidence='reviewed_display_label' if label else 'unreviewed',mapping_status='reviewed_display_label' if label else 'description_unavailable',
            privacy_note='Field metadata only; value profile: '+str(column.get('profile_kind','not_produced')),
            clinical_caveat='Stored unit unverified. Field discovery and reviewed names do not establish observed values or clinical findings.',
            search_terms='; '.join([source,field]+([label['label'],label.get('label_da','')] if label else [])),prior_display_label='',
            curator_label_provenance='; '.join(['config/clinical-display-dictionary.csv',label['source_label'],label['retrieved_on']]) if label else ''))
    payload['semantic_dictionary_rows']=rows
    by_id={r['semantic_id']:r for r in rows}
    links=[]
    seen_links=set()
    for link in payload.get('semantic_panel_links') or []:
        identity=link.get('semantic_id');key=(identity,link.get('panel_id'))
        if identity in by_id and key not in seen_links:
            links.append({**link,'clinical_concept_id':by_id[identity]['clinical_concept_id']});seen_links.add(key)
    linked={r['semantic_id'] for r in links}
    links.extend(dict(semantic_id=r['semantic_id'],clinical_concept_id=r['clinical_concept_id'],
        panel_id='data_dictionary',panel_section='Data Dictionary',relationship='raw_lineage',sort_order=i+1)
        for i,r in enumerate(rows) if r['semantic_id'] not in linked)
    payload['semantic_panel_links']=links
    registry=json.loads((Path(root)/'inst/config/public-output-registry.json').read_text(encoding='utf-8'))
    specs={s['id']:s for s in registry['artifacts']}
    def blank(spec):return {k:None for k in specs[spec]['schemas'][0]}
    routes=[]
    old_routes={r.get('semantic_id'):r for r in payload.get('panel_raw_field_rows') or [] if r.get('semantic_id') in by_id}
    for i,row in enumerate(rows):
        route={**blank('panel_raw_fields'),**{k:row.get(k) for k in ('semantic_id','clinical_concept_id','clinical_variable','source_name','object_name','raw_column','raw_descriptor','raw_code','raw_value','mapping_status','mapping_confidence','evidence_file','evidence_filter','privacy_note','clinical_caveat')}}
        route.update(panel_id=next(r['panel_id'] for r in links if r['semantic_id']==row['semantic_id']),
            panel_section='Data Dictionary',count_scope='source_identity_metadata',denominator_scope='source_identity_metadata',profile_scope='source_identity_metadata',sort_order=i+1)
        route.update(old_routes.get(row['semantic_id'],{}))
        route['value_column']=row.get('value_column')
        routes.append(route)
    payload['panel_raw_field_rows']=routes
    grouped={}
    for row in rows:grouped.setdefault(row['clinical_concept_id'],[]).append(row)
    old_concepts={r.get('clinical_concept_id'):r for r in payload.get('clinical_concept_rows') or [] if r.get('clinical_concept_id') in grouped}
    concepts=[]
    for identity,group in grouped.items():
        row=group[0]
        concept={**blank('clinical_concepts'),**{k:row.get(k) for k in ('clinical_concept_id','clinical_variable','clinical_group','clinical_subgroup','search_terms')}}
        concept.update(concept_status='metadata_only',purpose=row.get('semantic_meaning','Description unavailable'),raw_field_count=str(len(group)),
            primary_sources='; '.join(sorted({r['source_name'] for r in group})),count_scope='source_identity_metadata',denominator_scope='source_identity_metadata',profile_scope='source_identity_metadata')
        concept.update(old_concepts.get(identity,{}))
        concept['raw_field_count']=str(len(group))
        concept['primary_sources']='; '.join(sorted({r['source_name'] for r in group}))
        concepts.append(concept)
    payload['clinical_concept_rows']=concepts
    return payload
