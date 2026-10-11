import csv, importlib.util, json, pathlib, sys, tempfile, unittest, shutil, os
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
class EvidenceTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(); self.run=pathlib.Path(self.tmp.name); (self.run/'outputs/panels').mkdir(parents=True)
 def tearDown(self): self.tmp.cleanup()
 def collect(self):
  from output_evidence import collect_output_evidence
  return collect_output_evidence(self.run,ROOT)
 def write(self,name,headers,rows):
  with (self.run/'outputs'/name).open('w',encoding='utf-8',newline='') as f:
   w=csv.writer(f);w.writerow(headers);w.writerows(rows)
 def test_full_distribution_and_unknown_metadata(self):
  shutil.copyfile(ROOT/'tests/fixtures/output-evidence-distribution.csv',self.run/'outputs/panels/registry_clinical_summary.csv')
  self.write('FORBIDDEN_FILENAME.csv',['FORBIDDEN_HEADER'],[['FORBIDDEN_BODY']])
  tables=self.collect(); t=next(t for t in tables if t['id']=='registry_clinical_summary')
  self.assertEqual(len(t['rows']),5201); self.assertTrue(t['complete'])
  self.assertIsNone(t['rows'][5200]['n_rows']); self.assertNotIn('FORBIDDEN',json.dumps(tables))
 def test_optional_empty_and_changed_schema(self):
  self.write('panels/registry_clinical_summary.csv',['table_name','registry','n_rows','n_cols','n_patients','min_date','max_date'],[])
  self.assertEqual(next(t for t in self.collect() if t['id']=='registry_clinical_summary')['status'],'empty_output')
  self.write('panels/registry_clinical_summary.csv',['FORBIDDEN_HEADER'],[['FORBIDDEN_BODY']])
  t=next(t for t in self.collect() if t['id']=='registry_clinical_summary')
  self.assertEqual(t['status'],'metadata_only'); self.assertNotIn('FORBIDDEN',json.dumps(t))
 def test_typed_roundtrip_and_reference_source(self):
  from output_evidence import read_registered_csv
  spec={'schemas':[{'code':'string','label':'string','n':'number'}]}
  self.write('typed.csv',['code','label','n'],[['0012','Æble,\n東京',0],['0013','',None]])
  rows=read_registered_csv(self.run/'outputs/typed.csv',spec)
  self.assertEqual(rows,[{'code':'0012','label':'Æble,\n東京','n':0},{'code':'0013','label':None,'n':None}])
  self.write('npu-display-dictionary.csv',['FORBIDDEN_HEADER'],[['FORBIDDEN_BODY']])
  self.assertNotIn('FORBIDDEN',json.dumps(self.collect()))
 def test_path_escape_and_bad_csv_rejected(self):
  from output_evidence import confined_path,read_registered_csv
  with self.assertRaises(ValueError): confined_path(self.run,'../outside.csv')
  with self.assertRaises(ValueError): confined_path(self.run,'outputs/../../outside.csv')
  p=self.run/'outputs/bad.csv';p.write_text('code,label,n\n"unterminated',encoding='utf8')
  with self.assertRaises(ValueError): read_registered_csv(p,{'schemas':[{'code':'string','label':'string','n':'number'}]})
 def test_required_context_and_limits(self):
  self.write('atlas_sources.csv',['FORBIDDEN_HEADER'],[['FORBIDDEN_BODY']])
  context={'schema_version':1,'registry_version':1,'bindings':['sources']}
  (self.run/'outputs/atlas_build_context.json').write_text(json.dumps(context),encoding='utf8')
  with self.assertRaises(ValueError):self.collect()
  (self.run/'outputs/atlas_build_context.json').unlink()
  self.write('panels/registry_clinical_summary.csv',['table_name','registry','n_rows','n_cols','n_patients','min_date','max_date'],[['S','LYFO',0,7,0,'','']])
  os.environ['DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES']='1'
  try:
   with self.assertRaises(ValueError):self.collect()
  finally:os.environ.pop('DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES')
 def test_large_field_uses_and_restores_configured_budget(self):
  from output_evidence import read_registered_csv
  spec={'schemas':[{'code':'string','label':'string','n':'number'}]}
  self.write('large.csv',['code','label','n'],[['0001','x'*140000,0]])
  path=self.run/'outputs/large.csv'; previous=csv.field_size_limit()
  self.assertEqual(read_registered_csv(path,spec,200000)[0]['label'],'x'*140000)
  self.assertEqual(csv.field_size_limit(),previous)
  with self.assertRaises(ValueError):read_registered_csv(path,spec,140000)
  self.assertEqual(csv.field_size_limit(),previous)
  path.write_text('code,label,n\n0001,"unterminated',encoding='utf8')
  with self.assertRaises(ValueError):read_registered_csv(path,spec,200000)
  self.assertEqual(csv.field_size_limit(),previous)
 def test_selected_mcl_binding_is_confined_and_required(self):
  from output_evidence import load_registry
  spec=next(s for s in load_registry(ROOT)['artifacts'] if s['id']=='mcl_triangle_feasibility_cohort_counts_count_summary')
  headers=list(spec['schemas'][0]); row={k:'' for k in headers};row.update(metric='synthetic_count',label='Selected source',value='23',status='available')
  (self.run/'outputs/selected_mcl').mkdir()
  self.write('selected_mcl/mcl_triangle_count_summary.csv',headers,[[row[k] for k in headers]])
  self.write('mcl_triangle_count_summary.csv',['UNREVIEWED'],[['CONFLICTING_CURRENT']])
  context={'schema_version':1,'registry_version':1,'bindings':[spec['id']],'binding_files':{spec['id']:'outputs/selected_mcl/mcl_triangle_count_summary.csv'}}
  path=self.run/'outputs/atlas_build_context.json';path.write_text(json.dumps(context),encoding='utf8')
  self.assertEqual(next(t for t in self.collect() if t['id']==spec['id'])['status'],'metadata_only')
  context['binding_files'][spec['id']]='../escape.csv';path.write_text(json.dumps(context),encoding='utf8')
  with self.assertRaises(ValueError):self.collect()
  context['binding_files'][spec['id']]='outputs/selected_mcl/mcl_triangle_count_summary.csv';path.write_text(json.dumps(context),encoding='utf8')
  (self.run/context['binding_files'][spec['id']]).unlink()
  with self.assertRaises(ValueError):self.collect()
 def test_manifest_escape_and_snapshot_scope(self):
  self.write('output_manifest.csv',['relative_path'],[['../FORBIDDEN.csv']])
  with self.assertRaises(ValueError):self.collect()
  from output_evidence import collect_output_evidence
  rows=collect_output_evidence(None,ROOT,{'panels':{'registry_clinical_summary':[{'table_name':'S','registry':'LYFO','n_rows':20,'n_cols':7,'n_patients':20}]}})
  t=next(t for t in rows if t['id']=='registry_clinical_summary')
  self.assertEqual(t['status'],'snapshot_preview');self.assertIsNone(t['source_row_count']);self.assertFalse(t['complete']);self.assertEqual(len(t['rows']),1)
 def test_profile_context_beyond_clinical_cap(self):
  header='domain subdomain atlas_role table_name column_name column_type column_class profile_kind n_rows n_available pct_available n_missing pct_missing n_distinct_capped is_sensitive is_date_like is_numeric_like min mean median p25 p75 max min_date max_date'.split()
  rows=[['Laboratory','','','S'+str(i),'test','numeric','numeric','numeric',1000,998,99.8,2 if i==3000 else 0,0.2,10,False,False,True,1,5,5,3,7,20,'',''] for i in range(3001)]
  self.write('atlas_column_profiles.csv',header,rows)
  self.write('panels/damyda_numeric_fields.csv','table_name registry field source_column unit n_available pct_available mean median p25 p75'.split(),[['S3000','DaMyDa','Test','test','',998,99.8,5,5,3,7]])
  tables=self.collect(); t=next(t for t in tables if t['id']=='damyda_numeric_fields')
  self.assertIsNone(t['rows'][0]['n_available']);self.assertIsNone(t['rows'][0]['mean'])
if __name__=='__main__':unittest.main()
