import copy,json,os,pathlib,sqlite3,subprocess,sys,shutil
root=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(root/'scripts'))
from registry_summary_privacy import sanitize_registry_summaries,audit_registry_summaries
from registry_v2 import policy,public_resource
work=root/'.artifact-temp/registry-v2'
runtime=os.environ.get('RSCRIPT') or shutil.which('Rscript') or 'C:/Program Files/R/R-4.3.1/bin/Rscript.exe'
env=os.environ.copy()
if os.name=='nt':
 env.setdefault('LC_ALL','English_United States.utf8')
 libs=pathlib.Path('C:/Users/User/AppData/Local/R/win-library/4.3')
 if libs.exists():env.setdefault('R_LIBS_USER',str(libs))
subprocess.run([runtime,'tests/test-registry-v2.R'],cwd=root,env=env,check=True)
os.environ['DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE']=str(work/'unit.json');os.environ['DALYCARE_REGISTRY_NUMERIC_POLICY_FILE']=str(work/'policy.json');os.environ['DALYCARE_MIN_CELL_COUNT']='5'
golden=json.loads((work/'golden.json').read_text())
for row in golden:
 assert audit_registry_summaries([row],root)==[]
 safe=sanitize_registry_summaries([row],root)
 assert safe==sanitize_registry_summaries(safe,root)
 assert audit_registry_summaries(safe,root)==[]
 for key,value in [('approximate_mean',123),('denominator_n',True),('n_valid',20.5),('unit_evidence_checksum','f'*64),('unit_binding_checksum','f'*64),('numeric_policy_checksum','f'*64),('band_level',10),('extra','poison')]:
  bad=copy.deepcopy(row);bad[key]=value
  assert audit_registry_summaries([bad],root),key
  assert sanitize_registry_summaries([bad],root)[0]['summary_status']=='invalid_contract',key
 for raw in ['[{"band_id":"b0_1","n":20,"n":5}]','[{"band_id":"b0_1","n":5},{"band_id":"b0_1","n":15}]','[{"band_id":"b0_1","n":true}]']:
  bad={**row,'numeric_groups_json':raw};assert audit_registry_summaries([bad],root)
 assert audit_registry_summaries([row],root,11)
 assert sanitize_registry_summaries([row,row],root)[0]['summary_status']=='invalid_contract'
# Unchanged claimed evidence identifiers cannot authorize a changed conversion.
unit_path=work/'unit.json';original=unit_path.read_bytes()
try:
 changed=json.loads(original);changed['bindings'][0]['stored_to_display_multiplier']=2
 unit_path.write_text(json.dumps(changed),encoding='utf-8')
 assert audit_registry_summaries([golden[0]],root)
finally:
 unit_path.write_bytes(original)
resource=public_resource(root)
(work/'resource.json').write_text(json.dumps(resource),encoding='utf-8')
conn=sqlite3.connect(':memory:');conn.execute('create table cohort(patientid text,Reg_Haemoglobin text)')
sql=(work/'numeric.sql').read_text()
def run(values,pids=None):
 conn.execute('delete from cohort');conn.executemany('insert into cohort values (?,?)',zip(pids or map(str,range(len(values))),values))
 rows=conn.execute(sql).fetchall();assert not any('POISON' in str(r) for r in rows)
 return {(s,v):n for s,v,n in rows}
assert run(['1']*10+['11']*10)=={('valid','b0_1'):10,('valid','b1_2'):10}
assert run(['1','2','11'],['a','a','b'])=={('conflicting',''):1,('constant',''):1,('valid','b1_2'):1}
assert run(['9.999999999999998','10','10.000000000000002','19.999999999999996','20','40'])=={('valid','b0_1'):1,('valid','b1_2'):3,('valid','b2_3'):1,('valid','b3_4'):1}
bad=['1e999999999999','1e309','1e-9999','5e-324','NaN','Infinity','-1','00','+1','1.','1e00001','SYNTHETIC_POISON','1.79769313486231571e308','2.22507385850720139e-308']
assert run(bad)=={('invalid',''):len(bad)}
assert run(['0','0e-9999','2.2250738585072014e-308','1.7976931348623157e308'])=={('valid','b0_1'):3,('valid','b3_4'):1}
conversion=json.loads((work/'conversion.json').read_text());sql=(work/'conversion.sql').read_text()
assert run(conversion['values'])=={(r['status'],r['value']):r['n'] for r in conversion['groups']}
from public_privacy import sanitize_public_payload,audit_public_payload
metadata_path=work/'metadata.json'
if metadata_path.exists():
 metadata=json.loads(metadata_path.read_text(encoding='utf-8'));screened=sanitize_public_payload(metadata,project_root=root)
 assert screened['semantic_dictionary_rows'][0]['raw_descriptor']==metadata['semantic_dictionary_rows'][0]['raw_descriptor']
 assert not audit_public_payload(screened,project_root=root)
 for key,value in [('n_rows',1),('raw_value','SYNTHETIC_POISON'),('semantic_id','forged'),('evidence_filter','forged')]:
  bad=copy.deepcopy(metadata);bad['semantic_dictionary_rows'][0][key]=value
  assert sanitize_public_payload(bad,project_root=root)['semantic_dictionary_rows'][0]['raw_descriptor'] is None
print('PASS v2 independent Python guard and actual SQLite grouped SQL, exact boundaries and malformed numbers')
