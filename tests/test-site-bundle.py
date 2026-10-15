import json, os, sys, tempfile, unittest, copy, subprocess
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
class BundleTests(unittest.TestCase):
 def test_public_versions_actual_script_parity_and_proto_rollback(self):
  import site_bundle as b
  payload={'run_id':'SYNTHETIC','untouched':{'constructor':'keep','prototype':'keep'},'rows':[{'long_repeated_synthetic_column':i} for i in range(12)]}
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'
   for requested,environment,want in ((None,'',2),(None,' 1\t',1),(2,'invalid',2),('1','2',1)):
    with patch.dict(os.environ,{'DALYCARE_ATLAS_TRANSPORT_VERSION':environment}):
     result=b.write_site_bundle(out,payload,[],ROOT,'legacy_payload',transport_version=requested)
    wire=json.loads(result['payload_json'].read_text(encoding='utf-8'))
    self.assertEqual(wire['transport_version'],want)
    # Evaluate the unchanged classic-script object-literal boundary, not JSON.parse.
    probe="const fs=require('fs'),vm=require('vm');let c={window:{}};vm.runInNewContext(fs.readFileSync(process.argv[1],'utf8'),c);process.stdout.write(JSON.stringify(c.window.DALYCARE_ATLAS_PAYLOAD));"
    evaluated=subprocess.run(['node','-e',probe,str(result['payload'])],capture_output=True,text=True,check=True)
    self.assertEqual(json.loads(evaluated.stdout),wire)
    decoded=b.decode_transport(wire)
    self.assertEqual(decoded['export_contract'],'dalycare-lazy-v1')
    self.assertEqual(decoded['run_id'],payload['run_id'])
    self.assertNotIn('untouched',decoded)
   before={p:p.read_bytes() for p in result['assets']+[result['manifest']]}
   for version in (1,2):
    for unsafe in ({'__proto__':'own'}, {'nested':[{'__proto__':'own'}]}):
     with self.assertRaisesRegex(ValueError,'__proto__'):
      b.write_site_bundle(out,dict(payload,unsafe=unsafe),[],ROOT,'legacy_payload',transport_version=version)
     self.assertEqual(before,{p:p.read_bytes() for p in before})

 def test_writer_exact_asset_and_normalized_budgets_preserve_site(self):
  import site_bundle as b
  from output_evidence import load_registry
  payload={'run_id':'SYNTHETIC','text':'x'*300,'large_integer':10**200}
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'
   for version in (1,2):
    result=b.write_site_bundle(out,payload,[],ROOT,'legacy_payload',transport_version=version)
    wire=json.loads(result['payload_json'].read_text(encoding='utf-8'))
    required=max(result['payload'].stat().st_size,result['payload_json'].stat().st_size,b.normalized_size(wire),b.normalized_size(payload))
    registry=load_registry(ROOT)
    registry['input_max_bytes']=required
    with patch.object(b,'load_registry',return_value=registry):
     result=b.write_site_bundle(out,payload,[],ROOT,'legacy_payload',transport_version=version)
    before={p:p.read_bytes() for p in result['assets']+[result['manifest']]}
    registry['input_max_bytes']=required-1
    with patch.object(b,'load_registry',return_value=registry):
     with self.assertRaisesRegex(ValueError,'budget'):
      b.write_site_bundle(out,payload,[],ROOT,'legacy_payload',transport_version=version)
    self.assertEqual(before,{p:p.read_bytes() for p in before})
    # Numeric normalized charges exceed their small actual token spellings.
    registry['input_max_bytes']=1000
    with patch.object(b,'load_registry',return_value=registry):
     with self.assertRaisesRegex(ValueError,'budget'):
      b.write_site_bundle(out,{'numbers':[0]*100},[],ROOT,'legacy_payload',transport_version=version)
    self.assertEqual(before,{p:p.read_bytes() for p in before})

 def test_real_legacy_v1_v2_imports_output_default2_or_explicit1(self):
  from build_ui_iteration import build
  import site_bundle as b
  payload={'run_id':'SYNTHETIC_IMPORT','rows':[{'long_repeated_synthetic_column':i} for i in range(12)]}
  with tempfile.TemporaryDirectory() as tmp:
   src=Path(tmp)/'input';src.mkdir()
   with patch.dict(os.environ,{'DALYCARE_ATLAS_TRANSPORT_VERSION':''}):
    for imported in (payload,b.encode_transport(payload,1),b.encode_transport(payload,2)):
     (src/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = '+b.compact(imported)+';\n',encoding='utf-8')
     for requested,want in ((None,2),(1,1)):
      result=build(src,Path(tmp)/'site',ROOT,transport_version=requested)
      wire=json.loads(result['payload_json'].read_text(encoding='utf-8'))
      self.assertEqual(wire['transport_version'],want)
      decoded=b.decode_transport(wire)
      self.assertEqual(decoded['run_id'],payload['run_id'])
      self.assertEqual(decoded['export_contract'],'dalycare-lazy-v1')
      self.assertNotIn('rows',decoded)

 def test_chunks_transport_manifest_and_rollback(self):
  import site_bundle as b
  from output_evidence import collect_output_evidence
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'
   payload={'run_id':'synthetic','action_items':[{'status':'safe'}], 'review_infrastructure_sections':{'action_items':[{'status':'safe'}]},'privacy_metadata':{'minimum_cell_count':10}}
   tables=collect_output_evidence(None,ROOT,{'privacy_metadata':{'minimum_cell_count':10},'panels':{'registry_clinical_summary':[{'table_name':'S'+str(i),'registry':'LYFO','n_rows':7 if i==250 else 20,'n_cols':7,'n_patients':20} for i in range(251)]}})
   paths=b.write_site_bundle(out,payload,tables,ROOT,'legacy_payload')
   for name in ('atlas-reader.js','atlas-shell.js'):
    self.assertEqual((out/name).read_bytes(),(ROOT/'inst/templates'/name).read_bytes())
    for page in ('DALYCARE_outputs.html','DALYCARE_clinical.html'):
     self.assertIn(name,(out/page).read_text(encoding='utf-8'))
   cat=json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))
   table=next(t for t in cat['tables'] if t['id']=='registry_clinical_summary')
   self.assertEqual([s['rows'] for s in table['shards']],[250,1])
   for shard in table['shards']:
    data=json.loads((out/shard['src']).read_text(encoding='utf-8').split('register(',1)[1].removesuffix(');\n'))
    self.assertTrue(all(row['n_rows'] is None for row in json.loads(data['rows_json'])))
   for t in cat['tables']:
    for s in t['shards']:
     data=json.loads((out/s['src']).read_text(encoding='utf-8').split('register(',1)[1].removesuffix(');\n'))
     self.assertEqual(len(data['rows_json'].encode()),s['bytes']); self.assertLessEqual((out/s['src']).stat().st_size,262144)
   transport=json.loads(paths['payload_json'].read_text(encoding='utf-8')); decoded=b.decode_transport(transport)
   self.assertEqual(decoded['export_contract'],'dalycare-lazy-v1')
   self.assertEqual(decoded['privacy_metadata']['minimum_cell_count'],10)
   self.assertNotIn('action_items',decoded)
   self.assertNotIn('review_infrastructure_sections',decoded)
   self.assertEqual(set(paths['assets']),set(p for p in out.rglob('*') if p.is_file()))
   prior={p.relative_to(out):p.read_bytes() for p in paths['assets']}
   with patch.dict(os.environ,{'DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES':'1'}):
    with self.assertRaises(ValueError):b.write_site_bundle(out,payload,tables,ROOT,'legacy_payload')
   self.assertEqual(prior,{p.relative_to(out):p.read_bytes() for p in out.rglob('*') if p.is_file()})
 def test_wide_unicode_shards_and_unknown_descriptor(self):
  import site_bundle as b
  from output_evidence import collect_output_evidence
  tables=collect_output_evidence(None,ROOT,{'panels':{'registry_clinical_summary':[{'table_name':'東京'*15000,'registry':'LYFO','n_rows':20,'n_cols':7,'n_patients':20} for _ in range(4)]}})
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'; paths=b.write_site_bundle(out,{'run_id':'wide'},tables,ROOT,'legacy_payload')
   cat=json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))
   t=next(t for t in cat['tables'] if t['id']=='registry_clinical_summary');self.assertGreater(len(t['shards']),1)
   self.assertTrue(all((out/s['src']).stat().st_size<=262144 for s in t['shards']))
 def test_legacy_types_and_stricter_policy(self):
  from output_evidence import collect_output_evidence
  payload={'privacy_metadata':{'minimum_cell_count':10},'panels':{'registry_clinical_summary':[{'table_name':'0012','registry':'LYFO','n_rows':'7','n_cols':'0','n_patients':None}]}}
  with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'5'}):
   t=next(t for t in collect_output_evidence(None,ROOT,payload) if t['id']=='registry_clinical_summary')
  self.assertIsNone(t['rows'][0]['n_rows']);self.assertEqual(t['rows'][0]['n_cols'],0);self.assertEqual(t['rows'][0]['table_name'],'0012')
  self.assertEqual(set(t['rows'][0]),{c['key'] for c in t['columns']})
 def test_malformed_explicit_policy_fails(self):
  from output_evidence import collect_output_evidence
  with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'bogus'}):
   with self.assertRaises(ValueError):collect_output_evidence(None,ROOT,{})

 def test_internal_manifest_matches_assets_and_rollback(self):
  import site_bundle as b
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'; result=b.write_site_bundle(out,{'run_id':'before'},[],ROOT,'legacy_payload')
   manifest=json.loads(result['manifest'].read_text(encoding='utf-8'))
   self.assertEqual({a['path'] for a in manifest['assets']},{p.relative_to(out).as_posix() for p in result['assets']})
   self.assertTrue(all((out/a['path']).stat().st_size==a['bytes'] for a in manifest['assets']))
   before=(result['manifest'].read_bytes(),result['payload'].read_bytes())
   rename=Path.rename
   def fail_manifest(path,target):
    if str(target)==str(result['manifest']) and 'stage' in path.name: raise OSError('synthetic manifest publication failure')
    return rename(path,target)
   with patch.object(Path,'rename',fail_manifest):
    with self.assertRaises(OSError):b.write_site_bundle(out,{'run_id':'after'},[],ROOT,'legacy_payload')
   self.assertEqual(before,(result['manifest'].read_bytes(),result['payload'].read_bytes()))
 def test_pre_read_limit_and_migration_identity(self):
  from build_ui_iteration import build
  with tempfile.TemporaryDirectory() as tmp:
   src=Path(tmp)/'input'; src.mkdir(); run=Path(tmp)/'input-run';(run/'outputs').mkdir(parents=True)
   (src/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = {"run_id":"right","privacy_metadata":{"minimum_cell_count":10}};',encoding='utf-8')
   (run/'outputs/atlas_run_summary.csv').write_text('metric,value\nrun_id,wrong\n',encoding='utf-8')
   with self.assertRaisesRegex(ValueError,'identity'):build(src,Path(tmp)/'site',ROOT,run)
   (run/'outputs/atlas_run_summary.csv').write_text('metric,value\nrun_id,right\n',encoding='utf-8')
   (run/'outputs/panels').mkdir()
   (run/'outputs/panels/registry_clinical_summary.csv').write_text('table_name,registry,n_rows,n_cols,n_patients,min_date,max_date\nS,LYFO,7,0,7,,\n',encoding='utf-8')
   with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'5'}):
    paths=build(src,Path(tmp)/'site',ROOT,run)
   self.assertEqual(json.loads(paths['payload_json'].read_text(encoding='utf-8'))['payload']['privacy_metadata']['minimum_cell_count'],10)
   bootstrap=json.loads((Path(tmp)/'site/DALYCARE_entry.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))
   self.assertEqual(bootstrap['provenance'],'legacy_payload')
   catalogue=json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))
   self.assertEqual(next(t for t in catalogue['tables'] if t['id']=='run_summary')['provenance'],'csv_run')
   table=next(t for t in catalogue['tables'] if t['id']=='registry_clinical_summary')
   data=json.loads((Path(tmp)/'site'/table['shards'][0]['src']).read_text(encoding='utf-8').split('register(',1)[1].removesuffix(');\n'))
   self.assertIsNone(json.loads(data['rows_json'])[0]['n_rows'])
   with (src/'DALYCARE_atlas_payload.js').open('wb') as f:f.truncate(67108865)
   with self.assertRaisesRegex(ValueError,'pre-read'):build(src,Path(tmp)/'site',ROOT)


 def test_optional_oversized_csv_and_invalid_snapshot_close_publication(self):
  from output_evidence import collect_output_evidence
  with tempfile.TemporaryDirectory() as tmp:
   run=Path(tmp);(run/'outputs/panels').mkdir(parents=True)
   path=run/'outputs/panels/registry_clinical_summary.csv'
   with path.open('wb') as f:f.truncate(67108865)
   t=next(t for t in collect_output_evidence(run,ROOT) if t['id']=='registry_clinical_summary')
   self.assertEqual(t['status'],'metadata_only');self.assertEqual(t['rows'],[])
   (run/'outputs/atlas_build_context.json').write_text(json.dumps({'schema_version':1,'registry_version':1,'bindings':['registry_clinical_summary']}),encoding='utf-8')
   with self.assertRaises(ValueError):collect_output_evidence(run,ROOT)
  t=next(t for t in collect_output_evidence(None,ROOT,{'panels':{'registry_clinical_summary':[{'table_name':'0012','registry':'LYFO','n_rows':'bad','n_cols':'0'}]}}) if t['id']=='registry_clinical_summary')
  self.assertEqual(t['status'],'unavailable');self.assertEqual(t['rows'],[])


 def test_import_new_transport_and_schema_booleans(self):
  from build_ui_iteration import build
  from site_bundle import encode_transport,decode_transport
  from output_evidence import normalize_snapshot_rows
  self.assertEqual(normalize_snapshot_rows([{'code':'0012','n':'0','flag':'FALSE'}],{'schemas':[{'code':'string','n':'number','flag':'boolean'}]}),[{'code':'0012','n':0,'flag':False}])
  with tempfile.TemporaryDirectory() as tmp:
   src=Path(tmp)/'input';src.mkdir()
   payload={'run_id':'new','action_items':[{'status':'safe'}],'review_infrastructure_sections':{'action_items':[{'status':'safe'}]}}
   (src/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = '+json.dumps(encode_transport(payload))+';',encoding='utf-8')
   paths=build(src,Path(tmp)/'output',ROOT)
   restored=decode_transport(json.loads(paths['payload_json'].read_text(encoding='utf-8')))
   self.assertEqual(restored['run_id'],'new')
   self.assertEqual(restored['export_contract'],'dalycare-lazy-v1')
   self.assertNotIn('action_items',restored)
   with self.assertRaisesRegex(ValueError,'lazy export requires its original aggregate run'):
    build(Path(tmp)/'output',Path(tmp)/'second',ROOT)


 def test_invalid_saved_context_preserves_previous_site_and_manifest(self):
  from build_ui_iteration import build
  with tempfile.TemporaryDirectory() as tmp:
   src=Path(tmp)/'input';src.mkdir();run=Path(tmp)/'run';(run/'outputs').mkdir(parents=True)
   (src/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = {"run_id":"saved"};',encoding='utf-8')
   (run/'outputs/atlas_build_context.json').write_text(json.dumps({'schema_version':1,'registry_version':1,'run_id':'saved','bindings':[],'binding_files':[]}),encoding='utf-8')
   paths=build(src,Path(tmp)/'site',ROOT,run)
   original={p:p.read_bytes() for p in paths['assets']+[paths['manifest']]}
   for bindings in (['not_registered'],['sources','sources'],None,'sources'):
    (run/'outputs/atlas_build_context.json').write_text(json.dumps({'schema_version':1,'registry_version':1,'run_id':'saved','bindings':bindings}),encoding='utf-8')
    with self.assertRaises(ValueError):build(src,Path(tmp)/'site',ROOT,run)
    self.assertEqual(original,{p:p.read_bytes() for p in original})
 def test_later_optional_overwide_row_discards_all_prior_parts(self):
  from output_evidence import collect_output_evidence
  from site_bundle import write_site_bundle
  base=next(t for t in collect_output_evidence(None,ROOT,{}) if t['id']=='npu_display_dictionary')
  for label in ('x'*270000,('"'+chr(92))*40000):
   table=copy.deepcopy(base);small=copy.deepcopy(table['rows'][0]);big=dict(small,label=label)
   row_json=json.dumps([big],ensure_ascii=False,separators=(',',':'))
   if label.startswith('"'):
    self.assertLess(len(row_json.encode('utf-8')),262144)
    self.assertGreater(len(json.dumps({'rows_json':row_json},ensure_ascii=False,separators=(',',':')).encode('utf-8')),262144)
   table['rows']=[small]*250+[big]
   with tempfile.TemporaryDirectory() as tmp:
    paths=write_site_bundle(Path(tmp)/'site',{'run_id':'wide'},[table],ROOT,'legacy_payload')
    cat=json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))
    item=cat['tables'][0]
    self.assertEqual(item['status'],'unavailable');self.assertFalse(item['complete'])
    self.assertEqual(item['represented_row_count'],0);self.assertEqual(item['shards'],[])
    self.assertEqual(list((Path(tmp)/'site/output-shards').iterdir()),[])

if __name__=='__main__':unittest.main()
