"""Strict metadata-only catalogue exemption; no data-shape-only bypass."""
import json,re,os,csv
from functools import lru_cache
from pathlib import Path
@lru_cache(maxsize=8)
def schemas_for(path,mtime):
    registry=json.loads(Path(path).read_text(encoding='utf-8'))
    return [sc for s in registry['artifacts'] if s['id'] in ('semantic_dictionary','panel_raw_fields') for sc in [*s['schemas'],{k:s['schemas'][0][k] for k in s['projection']}]]
def unique_pairs(items):
    out={}
    for key,value in items:
        if key in out:raise ValueError('Duplicate metadata definition property')
        out[key]=value
    return out

def metadata_context(payload=None,root=None,columns=None,sources=None):
    root=Path(root or Path(__file__).resolve().parents[1])
    columns=columns if columns is not None else (payload or {}).get('column_profile_rows',[])
    def valid(v):return isinstance(v,str) and 0<len(v)<=240 and not re.search(r'[\x00-\x1f\x7f]',v)
    pairs={(r['table_name'],r['column_name']) for r in columns if isinstance(r,dict) and valid(r.get('table_name')) and valid(r.get('column_name'))}
    resource=json.loads((root/'config/metadata-descriptor-definitions.json').read_text(encoding='utf-8'))
    if set(resource)!={'version','normalisation','descriptors','provenance','display_definitions','registry_concepts','panels'} or resource['version']!='metadata-descriptor-definitions-v1' or resource['normalisation']!='lower_trim_ascii_space' or not isinstance(resource['descriptors'],list) or not resource['descriptors'] or not all(valid(v) for v in resource['descriptors']) or len(set(resource['descriptors']))!=len(resource['descriptors']) or resource['provenance']!={'evidence_tier':'local_reviewed_display_vocabulary','definition_source':'vital_descriptor_definition','review_version':'C2-fix1'}:raise ValueError('Invalid reviewed descriptor vocabulary')
    record_sets={'display_definitions':{'descriptor','clinical_variable','semantic_meaning','clinical_concept_id','clinical_group','clinical_subgroup','mapping_confidence'},'registry_concepts':{'source_name','raw_column','clinical_concept_id'},'panels':{'panel_id','panel_section'}}
    for name,keys in record_sets.items():
        if not isinstance(resource[name],list) or len(resource[name])>1000 or any(not isinstance(r,dict) or set(r)!=keys or any(not isinstance(v,str) or len(v)>2048 or re.search(r'[\x00-\x1f\x7f]',v) for v in r.values()) for r in resource[name]):raise ValueError('Invalid reviewed metadata display reference')
    vocabulary=set(resource['descriptors'])
    definitions=set();local=os.getenv('DALYCARE_METADATA_DEFINITIONS_FILE','')
    if local:
        path=Path(local)
        if path.stat().st_size>1048576:raise ValueError('Invalid approved metadata definitions')
        reviewed=json.loads(path.read_text(encoding='utf-8-sig'),object_pairs_hook=unique_pairs)
        if set(reviewed)!={'version','definitions','provenance'} or reviewed['version']!='approved-metadata-definitions-v1' or not isinstance(reviewed['definitions'],list) or len(reviewed['definitions'])>10000:raise ValueError('Invalid approved metadata definitions')
        provenance=reviewed['provenance']
        if not isinstance(provenance,dict) or set(provenance)!={'evidence_id','evidence_checksum','evidence_tier','review_status'} or not all(valid(v) for v in provenance.values()) or not re.fullmatch('[a-fA-F0-9]{64}',provenance['evidence_checksum']) or provenance['evidence_tier']!='reviewed_descriptor_definition' or provenance['review_status']!='verified':raise ValueError('Invalid approved metadata provenance')
        keys=('source_name','raw_column','value_column','raw_descriptor')
        for row in reviewed['definitions']:
            if not isinstance(row,dict) or set(row)!=set(keys) or not all(valid(v) for v in row.values()):raise ValueError('Invalid approved metadata definition')
            key=tuple(row[k] for k in keys)
            if key in definitions:raise ValueError('Duplicate approved metadata definition')
            definitions.add(key)
    locations={}
    for row in sources if sources is not None else (payload or {}).get('sources',[]):
        if isinstance(row,dict) and valid(row.get('table_name')):
            key=row['table_name'];locations[key]=None if key in locations else {'table':row.get('table') if valid(row.get('table')) else None,'schema':row.get('schema') if valid(row.get('schema')) else None}
    with (root/'config/clinical-display-dictionary.csv').open(encoding='utf-8-sig',newline='') as f:labels={(r['system'],r['code']):r for r in csv.DictReader(f) if r['kind']=='field'}
    return {'pairs':pairs,'vocabulary':vocabulary,'definitions':definitions,'reference':resource,'profiles':{(r['table_name'],r['column_name']):r for r in columns if isinstance(r,dict) and (r.get('table_name'),r.get('column_name')) in pairs},'labels':labels,'locations':locations}

def metadata_identity_approved(row,path,root,context=None):
    if not isinstance(row,dict) or not metadata_path(path):return False
    try:
        p=Path(root or Path(__file__).resolve().parents[1])/'inst/config/public-output-registry.json'
        schemas=schemas_for(str(p),p.stat().st_mtime_ns)
        if not any(set(row)==set(sc) for sc in schemas):return False
        schema=next(sc for sc in schemas if set(sc)==set(row))
        import math
        for key,value in row.items():
            if value is None:continue
            kind=schema[key]
            if not (kind=='string' and isinstance(value,str) or kind=='boolean' and isinstance(value,bool) or kind=='number' and isinstance(value,(int,float)) and not isinstance(value,bool) and math.isfinite(value)):return False
        for key in ('n_rows','n_patients','pct_non_missing','min_date','max_date','raw_code','raw_value'):
            if row.get(key) not in (None,''):return False
        for key in ('source_name','raw_column','value_column'):
            if not isinstance(row.get(key),str) or not 0<len(row[key])<=240 or re.search(r'[\x00-\x1f]',row[key]):return False
        if row.get('object_name')!=row['source_name']:return False
        if context is None or any((row['source_name'],row[key]) not in context['pairs'] for key in ('raw_column','value_column')):return False
        descriptor=row.get('raw_descriptor') or ''
        if not isinstance(descriptor,str) or len(descriptor)>240 or re.search(r'[\x00-\x1f]',descriptor):return False
        args=[row['source_name'],row['raw_column']]+([row['value_column'],descriptor] if descriptor else [])
        identity='current_'+'_'.join(v.encode('utf-8').hex() for v in args)
        if row.get('semantic_id')!=identity:return False
        if descriptor:
            if descriptor.strip(' ').lower() not in context['vocabulary'] and (row['source_name'],row['raw_column'],row['value_column'],descriptor) not in context['definitions']:return False
            expected='"'+row['raw_column'].replace('"','""')+'" = '+"'"+descriptor.replace("'","''")+"'"
            return row.get('evidence_file')=='current panel: vital_descriptors' and row.get('evidence_filter')==expected and row.get('data_shape','long_descriptor_table')=='long_descriptor_table'
        return row['value_column']==row['raw_column'] and row.get('evidence_file')=='atlas_column_profiles.csv; atlas_sources.csv' and row.get('evidence_filter')==f"source={row['source_name']}; column={row['raw_column']}" and row.get('data_shape','current_column_metadata')=='current_column_metadata'
    except (OSError,ValueError,TypeError,KeyError):return False

def metadata_path(path):return bool(path and (path[-1] in {'semantic_dictionary','semantic_dictionary_rows','panel_raw_fields','panel_raw_field_rows'} or tuple(path)==('review_clinical_variables','raw_fields')))
def metadata_fallback(row,context):
    out=dict.fromkeys(row)
    source=row.get('source_name');column=row.get('raw_column')
    if isinstance(source,str) and isinstance(column,str) and (source,column) in context['pairs']:
        out.update(source_name=source,raw_column=column)
        if 'object_name' in row:out['object_name']=source
        if isinstance(row.get('value_column'),str) and (source,row['value_column']) in context['pairs']:out['value_column']=row['value_column']
    if 'mapping_status' in row:out['mapping_status']='definition_withheld'
    if 'privacy_note' in row:out['privacy_note']='Unapproved definition content withheld; field identity only.'
    return out

def metadata_screen(row,context):
    text=lambda key:row.get(key) if isinstance(row.get(key),str) else ''
    source,column,descriptor,value=map(text,('source_name','raw_column','raw_descriptor','value_column'))
    profile=context['profiles'].get((source,column),{});label=context['labels'].get((source,column))
    display=next((d for d in context['reference']['display_definitions'] if d['descriptor']==descriptor.strip(' ').lower()),None)
    concept=next((d for d in context['reference']['registry_concepts'] if (d['source_name'],d['raw_column'])==(source,column)),None)
    expected={'clinical_variable':descriptor if descriptor else label['label'] if label else column,'semantic_meaning':label['definition'] if not descriptor and label else 'Description unavailable','clinical_concept_id':concept['clinical_concept_id'] if not descriptor and concept else text('semantic_id'),'clinical_group':'Vitals' if descriptor else 'Disease Registries' if source.startswith('RKKP_') else profile.get('domain','Source fields'),'clinical_subgroup':profile.get('subdomain','Source fields'),'mapping_confidence':'reviewed_display_label' if label else 'unreviewed'}
    if descriptor and display:expected.update({k:v for k,v in display.items() if k!='descriptor'})
    expected.update(mapping_status='saved_definition_inventory_unassessed' if descriptor and text('mapping_status')=='saved_definition_inventory_unassessed' else 'reviewed_display_label' if label or display else 'description_unavailable',privacy_note='Schema and reviewed definition metadata only; no observation is asserted.',clinical_caveat='Stored unit unverified. Definition metadata does not establish current observations.',search_terms='; '.join(dict.fromkeys((source,column,value,descriptor,expected['clinical_variable']))),raw_field_label=source+'.'+column+(' = '+descriptor if descriptor else '')+' -> '+expected['clinical_variable'],curator_label_provenance='Reviewed local metadata definition' if label or display else None,value_type='numeric' if descriptor else profile.get('column_type'),code_system='local_SP_descriptor' if descriptor else '',table_name=source if text('table_name')==source else None)
    location=context['locations'].get(source) or {}
    expected['table_name']=location.get('table') or (source if text('table_name')==source else None)
    expected['schema_name']=location.get('schema')
    for key in ('patient_id_column','date_column'):expected[key]=text(key) if (source,text(key)) in context['pairs'] else None
    panel=next((p for p in context['reference']['panels'] if p['panel_id']==text('panel_id')),None)
    if panel:expected.update(panel)
    for key in ('count_scope','denominator_scope','profile_scope'):expected[key]='source_identity_metadata'
    identity={'semantic_id','source_name','object_name','raw_column','value_column','raw_descriptor','evidence_file','evidence_filter','data_shape'}
    out=dict(row)
    for key,v in row.items():
        if key in identity or v is None or v=='':continue
        if key=='sort_order' and isinstance(v,(int,float)) and not isinstance(v,bool) and 0<=v<=10000 and int(v)==v:continue
        out[key]=expected.get(key)
    return out

def metadata_only(row,path,root,context=None):
    return metadata_identity_approved(row,path,root,context) and row==metadata_screen(row,context)
