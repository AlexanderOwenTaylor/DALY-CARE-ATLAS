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
payload['panels']={'registry_field_summaries':registry,'registry_clinical_summary':[dict(table_name='Wide_'+'東京'*15000,registry='LYFO',n_rows=20,n_cols=7,n_patients=20) for i in range(4)]}
payload['catalog_rows']=[dict(table_name='Synthetic_Source_'+str(i),load_status='ok') for i in range(22)]+[dict(table_name='BIOBANK_SAMPLES',load_status='unavailable')]
write_site_bundle(output,payload,collect_output_evidence(None,ROOT,payload),ROOT,'legacy_payload')
