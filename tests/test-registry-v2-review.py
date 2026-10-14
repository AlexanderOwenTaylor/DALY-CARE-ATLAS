import copy,json,os,pathlib,sys,tempfile
root=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(root/'scripts'))
import registry_v2 as v
work=root/'.artifact-temp/registry-v2'
os.environ['DALYCARE_REGISTRY_NUMERIC_POLICY_FILE']=str(work/'policy.json');os.environ['DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE']=str(work/'unit.json')
resource=json.loads((work/'resource.json').read_text());row=json.loads((work/'golden.json').read_text())[0]
s=next(f for f in resource['fields'] if f['table_name']==row['table_name'] and f['source_column']==row['source_column']);s={**s,'policy_checksum':resource['checksum']}
for lower in (0,1):
 spec=copy.deepcopy(s);spec['binding']['policy']['edges']=[0,10,11,12,None]
 cells=[{'band_id':'b0_1','n':10},{'band_id':'b1_2' if lower==0 else 'b2_3','n':10}]
 candidate={**row,'numeric_groups_json':json.dumps(cells),**v.estimates(cells,v.bands(spec['binding']['policy'],0))}
 assert v.validate(candidate,spec,5)
 candidate['iqr_lower']=bool(lower)
 assert v.validate(candidate,spec,5) is None,'boolean estimate accepted'
original=json.loads((work/'unit.json').read_text());stale=copy.deepcopy(original['bindings'][0]);stale['numeric_policy_checksum']='f'*64
with tempfile.TemporaryDirectory(dir=work) as tmp:
 p=pathlib.Path(tmp)/'duplicate.json';os.environ['DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE']=str(p)
 for bindings in ([stale,original['bindings'][0]],[original['bindings'][0],stale]):
  p.write_text(json.dumps({'version':'registry-unit-evidence-v2','bindings':bindings}))
  assert not any(f.get('binding') for f in v.policy(root).values()),'duplicate binding accepted'
os.environ['DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE']=str(work/'unit.json')
public=v.public_resource(root)
assert any(f.get('mapping_lineage') for f in public['fields']),'reviewed raw/canonical lineage absent'
assert all('evidence_file' not in m for f in public['fields'] for m in f.get('mapping_lineage',[]))
print('PASS strict estimates, duplicate binding order and bounded mapping lineage')

from metadata_privacy import metadata_only,metadata_context
from public_privacy import sanitize_public_payload,audit_public_payload
metadata=json.loads((work/'metadata.json').read_text(encoding='utf-8'));original=metadata['semantic_dictionary_rows'][0];context=metadata_context(metadata,root)
assert metadata_only(original,('semantic_dictionary_rows',),root,context)
assert not metadata_only(original,('semantic_dictionary_rows',),root)
for unknown_source in (True,False):
 forged=copy.deepcopy(original)
 if unknown_source:forged.update(source_name='SYNTHETIC_UNKNOWN_SOURCE',object_name='SYNTHETIC_UNKNOWN_SOURCE')
 forged['raw_descriptor']='SYNTHETIC_PRIVATE_OBSERVATION'
 forged['semantic_id']='current_'+'_'.join(forged[k].encode('utf-8').hex() for k in ('source_name','raw_column','value_column','raw_descriptor'))
 forged['evidence_filter']='"'+forged['raw_column'].replace('"','""')+'" = '+"'"+forged['raw_descriptor']+"'"
 bad={**metadata,'semantic_dictionary_rows':[forged]}
 assert not metadata_only(forged,('semantic_dictionary_rows',),root,context)
 assert sanitize_public_payload(bad,project_root=root)['semantic_dictionary_rows'][0]['raw_descriptor'] is None
 assert audit_public_payload(bad,project_root=root)
print('PASS independent current-column authority and recomputed forged descriptor rejection')

with tempfile.TemporaryDirectory(dir=work) as tmp:
 p=pathlib.Path(tmp)/'definitions.json';os.environ['DALYCARE_METADATA_DEFINITIONS_FILE']=str(p)
 p.write_text(json.dumps({'version':'approved-metadata-definitions-v1','definitions':[]}))
 try:metadata_context(metadata,root)
 except ValueError:pass
 else:raise AssertionError('Malformed local metadata provenance accepted')
 del os.environ['DALYCARE_METADATA_DEFINITIONS_FILE']
print('PASS malformed configured descriptor evidence fails before use')

for key in ('clinical_variable','semantic_meaning','privacy_note','clinical_caveat','search_terms','schema_name','table_name','evidence_filter','semantic_id'):
 injected=copy.deepcopy(metadata);injected['semantic_dictionary_rows'][0][key]='SYNTHETIC_PRIVATE_OBSERVATION'
 assert not metadata_only(injected['semantic_dictionary_rows'][0],('semantic_dictionary_rows',),root,context)
 cleaned=sanitize_public_payload(injected,project_root=root)
 assert 'SYNTHETIC_PRIVATE_OBSERVATION' not in json.dumps(cleaned)
 assert audit_public_payload(injected,project_root=root)
 assert not audit_public_payload(cleaned,project_root=root)
print('PASS approved identities do not authorize injected derivative text, filters, locations or encoded IDs')

# Derived clinical review path must use identical authority and screening.
for key in ('clinical_variable','semantic_meaning','raw_descriptor','evidence_filter','semantic_id'):
 injected=copy.deepcopy(metadata);injected['review_clinical_variables']={'raw_fields':[copy.deepcopy(original)]}
 injected['review_clinical_variables']['raw_fields'][0][key]='SYNTHETIC_PRIVATE_OBSERVATION'
 cleaned=sanitize_public_payload(injected,project_root=root)
 assert 'SYNTHETIC_PRIVATE_OBSERVATION' not in json.dumps(cleaned)
 assert audit_public_payload(injected,project_root=root)
 assert not audit_public_payload(cleaned,project_root=root)
print('PASS derived review raw_fields receives identical metadata authority and injection protection')
