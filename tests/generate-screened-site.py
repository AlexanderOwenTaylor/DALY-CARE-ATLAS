"""Actual writer fixture for deterministic production-module and browser checks."""
import sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from output_evidence import collect_output_evidence
from site_bundle import write_site_bundle
from registry_summary_privacy import registry_summary_policy,_canonical
from registry_v2 import policy,canonical
output=Path(sys.argv[1])
payload={'run_id':'SYNTHETIC_E1_MODULE_VALIDATION','column_profile_rows':[dict(table_name='Synthetic_Source_'+str(i//100),column_name='exact_field_'+str(i),column_type='character',n_rows=100,n_available=99,n_missing=1) for i in range(2200)]}
legacy=registry_summary_policy(ROOT);v2=policy(ROOT);registry=[]
for i,(key,field) in enumerate(legacy.items()):
    row=canonical(v2[key],'field_absent',5) if i==0 else _canonical(field,5,'field_absent')
    if i and field['kind']=='categorical' and len(field['categories'])>=2:
        row.update(summary_status='published',denominator_n=40,n_valid=30,n_missing=5,n_invalid=5,n_conflicting=0,category_counts_json=json.dumps([dict(code=field['categories'][0],n=15),dict(code=field['categories'][1],n=15)],separators=(',',':')))
    registry.append(row)
payload['sources']=[dict(table_name='Synthetic_Source_21',load_status='ok',n_rows=100,n_cols=100)]
payload['semantic_dictionary_rows']=[dict(semantic_id='current_'+r['table_name'].encode().hex()+'_'+r['column_name'].encode().hex(),source_name=r['table_name'],table_name=r['table_name'],raw_column=r['column_name'],value_column=r['column_name'],data_shape='current_column_metadata',evidence_file='atlas_column_profiles.csv; atlas_sources.csv',evidence_filter='source='+r['table_name']+'; column='+r['column_name']) for r in payload['column_profile_rows']]
payload['panels']={'registry_field_summaries':registry,'registry_clinical_summary':[dict(table_name='Wide_'+'東京'*15000,registry='LYFO',n_rows=20,n_cols=7,n_patients=20) for i in range(4)]}
payload['catalog_rows']=[dict(table_name='Synthetic_Source_'+str(i),load_status='ok') for i in range(22)]+[dict(table_name='BIOBANK_SAMPLES',load_status='unavailable')]
if '--clinician' in sys.argv:
    payload['column_profile_rows']=[dict(table_name='SP_VitaleVaerdier',column_name=name,column_type='character') for name in ('meas_value','recorded_time')]
    payload['column_profile_rows'].append(dict(table_name='RKKP_CLL',column_name='Reg_FISH',column_type='character'))
    payload['sources']=[dict(table_name=name,load_status='embedded_fields_represented') for name in ('FISH','EMPTY_HELPER')]
    payload['semantic_dictionary_rows']=[dict(semantic_id='current_'+r['table_name'].encode().hex()+'_'+r['column_name'].encode().hex(),source_name=r['table_name'],table_name=r['table_name'],raw_column=r['column_name'],value_column=r['column_name'],clinical_variable='Recorded measurement value' if r['column_name']=='meas_value' else 'Measurement time',semantic_meaning='Exact schema definition',data_shape='current_column_metadata',evidence_file='atlas_column_profiles.csv; atlas_sources.csv',evidence_filter='source='+r['table_name']+'; column='+r['column_name']) for r in payload['column_profile_rows']]
    payload['panels']['atlas_temporal_coverage']=[dict(table_name='RKKP_CLL',date_column=None,n_rows=20,selection_basis='name_prioritised_date_candidate',event_meaning='Selected source field; clinical event meaning not verified')]
write_site_bundle(output,payload,collect_output_evidence(None,ROOT,payload),ROOT,'legacy_payload')
