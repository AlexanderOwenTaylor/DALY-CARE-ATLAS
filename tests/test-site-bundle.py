import json, os, sys, tempfile, unittest, copy
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
class BundleTests(unittest.TestCase):
 def test_chunks_transport_manifest_and_rollback(self):
  import site_bundle as b
  from output_evidence import collect_output_evidence
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'
   payload={'run_id':'synthetic','action_items':[{'status':'safe'}], 'review_infrastructure_sections':{'action_items':[{'status':'safe'}]},'privacy_metadata':{'minimum_cell_count':10}}
   tables=collect_output_evidence(None,ROOT,{'privacy_metadata':{'minimum_cell_count':10},'panels':{'registry_clinical_summary':[{'table_name':'S'+str(i),'registry':'LYFO','n_rows':7 if i==250 else 20,'n_cols':7,'n_patients':20} for i in range(251)]}})
   paths=b.write_site_bundle(out,payload,tables,ROOT,'legacy_payload')
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
   from public_privacy import sanitize_public_payload
   self.assertEqual(decoded,sanitize_public_payload(payload,10,ROOT))
   self.assertEqual(decoded['action_items'],payload['action_items']); self.assertIs(decoded['action_items'],decoded['review_infrastructure_sections']['action_items'])
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
   (run/'outputs/atlas_build_context.json').write_text(json.dumps({'schema_version':1,'bindings':['registry_clinical_summary']}),encoding='utf-8')
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
   self.assertEqual(restored['action_items'],payload['action_items'])
   self.assertIs(restored['action_items'],restored['review_infrastructure_sections']['action_items'])

if __name__=='__main__':unittest.main()
