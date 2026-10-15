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
 def test_private_registry_diagnostics_create_no_public_table_or_link(self):
  baseline=self.collect()
  self.write('panels/registry_interpretation_diagnostics.csv',['table_name','source_column','n_valid','n_unrecognised'],[['RKKP_CLL','Beh_Immunterapi',19,1]])
  self.assertEqual(self.collect(),baseline)
 def test_coverage_context_and_collapsed_scope_are_published_without_range_length(self):
  from output_evidence import load_registry
  specs={s['id']:s for s in load_registry(ROOT)['artifacts']}
  def write_years(end):
   spec=specs['atlas_temporal_coverage_years']; keys=list(spec['schemas'][0])
   rows=[dict(table_name='S',date_column='D',coverage_basis='source_date_range',year=y) for y in range(1980,end)]
   rows += [dict(table_name='S',date_column='E',coverage_basis='event_date_counts',year=2020,n_rows=1,pct_rows=1)]
   self.write('panels/atlas_temporal_coverage_years.csv',keys,[[r.get(k) for k in keys] for r in rows])
   return next(t for t in self.collect() if t['id']==spec['id'])
  a=write_years(1983); b=write_years(2026)
  self.assertEqual(a,b); self.assertIsNone(a['source_row_count']); self.assertEqual(a['represented_row_count'],2)
  self.assertIn('transformed',a['reason'].lower()); self.assertIsNone(a['rows'][0]['year']); self.assertEqual(a['rows'][1]['date_column'],'E'); self.assertIsNone(a['rows'][1]['year']); self.assertIsNone(a['rows'][1]['n_rows'])
  spec=specs['atlas_spatial_region_counts'];keys=list(spec['schemas'][0]);row=dict(table_name='S',region_column='RegionCode',region_code='01',n_rows=1)
  self.write('panels/atlas_spatial_region_counts.csv',keys,[[row.get(k) for k in keys]])
  table=next(t for t in self.collect() if t['id']==spec['id']);self.assertEqual(table['rows'][0]['region_column'],'RegionCode');self.assertIsNone(table['rows'][0]['n_rows'])
 def test_supported_year_label_survives_with_counts_withheld(self):
  from output_evidence import collect_output_evidence
  row=dict(table_name='S',date_column='D',coverage_basis='person_supported_label_only',year=2020,n_rows=10,pct_rows=50,support_k=5,person_support_safe=True,outside_person_support_safe=True,outside_record_support_safe=True,partition_complete=False)
  tables=collect_output_evidence(None,ROOT,{'panels':{'atlas_temporal_coverage_years':[row]}})
  table=next(t for t in tables if t['id']=='atlas_temporal_coverage_years')
  self.assertEqual(table['rows'][0]['year'],2020);self.assertIsNone(table['rows'][0]['n_rows']);self.assertIsNone(table['rows'][0]['pct_rows']);self.assertEqual(table['rows'][0]['count_privacy_status'],'withheld_partition_counts')
 def test_reviewed_discovery_terms_are_not_arbitrary_field_values(self):
  from output_evidence import collect_output_evidence
  p={'column_profile_rows':[{'table_name':'SP_PatientInfo','column_name':'weight_in_kg'},{'table_name':'Other','column_name':'FORBIDDEN_ARBITRARY_TERM'}]}
  t=next(t for t in collect_output_evidence(None,ROOT,payload_snapshot=p) if t['id']=='column_profiles')
  self.assertIn('weight',t['source_terms']);self.assertIn('weight_in_kg',t['source_terms']);self.assertNotIn('FORBIDDEN_ARBITRARY_TERM',t['source_terms'])
  self.assertEqual(next(c for c in t['columns'] if c['key']=='n_available')['label'],'Source rows with a value')
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
 def test_r_manifest_allows_only_exact_membership_resource(self):
  resource=(ROOT/'inst/config/clinical-source-membership.json').resolve().as_posix()
  self.write('output_manifest.csv',['artifact_id','relative_path'],[['clinical_source_membership',resource]])
  self.collect()
  self.write('output_manifest.csv',['artifact_id','relative_path'],[['clinical_source_membership','../FORBIDDEN.json']])
  with self.assertRaises(ValueError):self.collect()
 def test_profile_context_beyond_clinical_cap(self):
  header='domain subdomain atlas_role table_name column_name column_type column_class profile_kind n_rows n_available pct_available n_missing pct_missing n_distinct_capped is_sensitive is_date_like is_numeric_like min mean median p25 p75 max min_date max_date'.split()
  rows=[['Laboratory','','','S'+str(i),'test','numeric','numeric','numeric',1000,998,99.8,2 if i==3000 else 0,0.2,10,False,False,True,1,5,5,3,7,20,'',''] for i in range(3001)]
  self.write('atlas_column_profiles.csv',header,rows)
  self.write('panels/damyda_numeric_fields.csv','table_name registry field source_column unit n_available pct_available mean median p25 p75'.split(),[['S3000','DaMyDa','Test','test','',998,99.8,5,5,3,7]])
  tables=self.collect(); t=next(t for t in tables if t['id']=='damyda_numeric_fields')
  self.assertIsNone(t['rows'][0]['n_available']);self.assertIsNone(t['rows'][0]['mean'])

 def test_saved_context_binding_validation_is_shared(self):
  from build_ui_iteration import matching_run_context
  from output_evidence import load_registry
  registry=load_registry(ROOT)
  base={'schema_version':1,'registry_version':1,'run_id':'synthetic-context','bindings':[]}
  context_path=self.run/'outputs/atlas_build_context.json'
  selected='mcl_triangle_feasibility_cohort_counts_count_summary'
  invalid=[[],None,dict(base,schema_version=True),dict(base,registry_version=2),
   {k:v for k,v in base.items() if k!='bindings'},dict(base,bindings=None),dict(base,bindings='sources'),
   dict(base,bindings={'sources':True}),dict(base,bindings=[['sources']]),dict(base,bindings=[1]),
   dict(base,bindings=['not_a_registered_input']),dict(base,bindings=['sources','sources']),
   dict(base,binding_files=['invalid']),dict(base,binding_files=None),
   dict(base,binding_files={'not_a_registered_input':'outputs/selected_mcl/unknown.csv'}),
   dict(base,binding_files={selected:'outputs/selected_mcl/mcl_triangle_count_summary.csv'}),
   dict(base,bindings=[selected],binding_files={selected:'../outside.csv'}),
   dict(base,bindings=[selected],binding_files={selected:None}),
   dict(base,bindings=['sources'],binding_files={'sources':'outputs/selected_mcl/atlas_sources.csv'})]
  for context in invalid:
   with self.subTest(context=context):
    context_path.write_text(json.dumps(context),encoding='utf-8')
    for read in (lambda:matching_run_context(self.run,{'run_id':'synthetic-context'},registry),self.collect):
     with self.assertRaises(ValueError):read()
  for context in (base,dict(base,binding_files={}),dict(base,binding_files=[])):
   context_path.write_text(json.dumps(context),encoding='utf-8')
   self.assertEqual(matching_run_context(self.run,{'run_id':'synthetic-context'},registry),context)
   self.assertEqual({t['id'] for t in self.collect()},{s['id'] for s in registry['artifacts']})
  # A real selected binding validates and remains required at its selected path.
  spec=next(s for s in registry['artifacts'] if s['id']==selected)
  headers=list(spec['schemas'][0]);row={k:'' for k in headers};row.update(metric='synthetic_count',label='Selected source',value='23',status='available')
  (self.run/'outputs/selected_mcl').mkdir()
  self.write('selected_mcl/mcl_triangle_count_summary.csv',headers,[[row[k] for k in headers]])
  context=dict(base,bindings=[selected],binding_files={selected:'outputs/selected_mcl/mcl_triangle_count_summary.csv'})
  context_path.write_text(json.dumps(context),encoding='utf-8')
  self.assertEqual(matching_run_context(self.run,{'run_id':'synthetic-context'},registry),context)
  self.assertEqual({t['id'] for t in self.collect()},{s['id'] for s in registry['artifacts']})
  context_path.unlink();self.write('atlas_run_summary.csv',['metric','value'],[['run_id','synthetic-context']])
  self.assertIsNone(matching_run_context(self.run,{'run_id':'synthetic-context'},registry))
  self.assertEqual({t['id'] for t in self.collect()},{s['id'] for s in registry['artifacts']})

if __name__=='__main__':unittest.main()
