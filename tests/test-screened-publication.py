"""Mandatory synthetic production publication contracts, independent of user archives."""
import csv, hashlib, json, sys, tempfile, unittest, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from output_evidence import collect_output_evidence
import site_bundle as b

class Publication(unittest.TestCase):
 def test_original_audit_and_implicit_availability_complements(self):
  from public_privacy import sanitize_public_payload,audit_public_payload
  for row in [dict(n_available=99,n_missing=None,pct_available=99),dict(n_available=None,n_missing=99,pct_missing=99),dict(n_available=None,n_missing=None,pct_available=99)]:
   row.update(table_name='S',column_name='value',n_rows=100)
   original={'column_profile_rows':[row]}
   self.assertTrue(audit_public_payload(original,ROOT),'audit must reject original reconstructable small complements')
   safe=sanitize_public_payload(original,project_root=ROOT)
   self.assertTrue(all(safe['column_profile_rows'][0].get(k) is None for k in ('n_available','n_missing','pct_available','pct_missing')))
   self.assertEqual(audit_public_payload(safe,ROOT),[])
 def test_small_legacy_categories_screen_through_actual_importer(self):
  from public_privacy import sanitize_public_payload,audit_public_payload
  from build_ui_iteration import build
  original={'run_id':'SYNTHETIC_SMALL_LEGACY','column_top_value_rows':[dict(table_name='S',column_name='category',value='UNSAFE_SMALL_'+str(n),n=n) for n in (1,4)]}
  self.assertTrue(audit_public_payload(original,ROOT))
  safe=sanitize_public_payload(original,project_root=ROOT)
  self.assertEqual(audit_public_payload(safe,ROOT),[])
  with tempfile.TemporaryDirectory() as tmp:
   base=Path(tmp);source=base/'input';source.mkdir();(source/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = '+json.dumps(original)+';')
   build(source,base/'site',ROOT)
   self.assertFalse(any(b'UNSAFE_SMALL_' in p.read_bytes() for p in (base/'site').rglob('*') if p.is_file()))

 def test_download_directory_index_and_package(self):
  payload={'run_id':'SYNTHETIC_E1','column_profile_rows':[{'table_name':'Synthetic','column_name':'field_'+str(i),'column_type':'character','n_rows':20,'n_available':19,'n_missing':1} for i in range(2200)]}
  tables=collect_output_evidence(None,ROOT,payload)
  with tempfile.TemporaryDirectory() as tmp:
   out=Path(tmp)/'site'; result=b.write_site_bundle(out,payload,tables,ROOT,'legacy_payload')
   manifest=json.loads((out/'public-manifest.json').read_text())
   self.assertEqual(manifest['build_id'],json.loads(result['payload_json'].read_text())['payload']['build_id'])
   self.assertEqual(manifest['state'],'partial')
   self.assertNotIn('public-manifest.json',[f['path'] for f in manifest['files']])
   for f in manifest['files']:
    data=(out/f['path']).read_bytes(); self.assertEqual(len(data),f['bytes']);self.assertEqual(hashlib.sha256(data).hexdigest(),f['sha256'])
   directory=json.loads((out/'DALYCARE_directory.js').read_text().split('=',1)[1].strip().removesuffix(';'))
   index=json.loads((out/'DALYCARE_search.js').read_text().split('=',1)[1].strip().removesuffix(';'))
   self.assertEqual(len(index['fields']),2200)
   self.assertNotIn('column_profile_rows',b.decode_transport(json.loads(result['payload_json'].read_text())))
   for table in directory['tables']:
    self.assertTrue((out/'downloads'/f"{table['id']}.csv").is_file())
    descriptor=json.loads((out/table['descriptor']).read_text().split('registerDescriptor(',1)[1].removesuffix(');\n'))['table']
    rows=[]
    for s in descriptor['shards']:
     raw=(out/s['src']).read_bytes();self.assertLessEqual(len(raw),262144)
     rows.extend(json.loads(json.loads(raw.decode().split('register(',1)[1].removesuffix(');\n'))['rows_json']))
    with (out/'downloads'/f"{table['id']}.csv").open(encoding='utf-8',newline='') as stream:
     reader=csv.DictReader(stream); self.assertEqual(reader.fieldnames,[c['key'] for c in descriptor['columns']]); actual=list(reader)
    self.assertEqual(len(actual),len(rows))
    if table['id']=='column_profiles':
     self.assertEqual(len(rows),2200)
     self.assertTrue(all(r['n_available'] is None and r['n_missing'] is None and r.get('pct_available') is None for r in rows))
   z=b.package_site(out)
   with zipfile.ZipFile(z) as archive:
    self.assertEqual(set(archive.namelist()),{f['path'] for f in manifest['files']}|{'public-manifest.json'})
   before=z.read_bytes();(out/'atlas-reader.js').write_text('mutated')
   with self.assertRaisesRegex(ValueError,'checksum'):b.package_site(out)
   self.assertEqual(before,z.read_bytes())

 def test_lazy_input_is_explicitly_rejected(self):
  from build_ui_iteration import build
  with tempfile.TemporaryDirectory() as tmp:
   path=Path(tmp);(path/'DALYCARE_atlas_payload.js').write_text('window.DALYCARE_ATLAS_PAYLOAD = '+json.dumps({'export_contract':'dalycare-lazy-v1','build_id':'x'})+';')
   with self.assertRaisesRegex(ValueError,'lazy.*rebuild_atlas_from_outputs'):build(path,path/'out',ROOT)

 def test_manifest_completeness_requires_known_upstream_outcomes(self):
  from publication import publication_outcomes
  self.assertEqual(publication_outcomes([])['collection'],'unknown')
  from publication import public_manifest
  for summary,expected in [([], 'partial'),([dict(metric=p+'_status',value='complete') for p in ('collection','interpretation')],'complete')]:
   with tempfile.TemporaryDirectory() as tmp:
    self.assertEqual(public_manifest(Path(tmp),'b','r','p',{},summary)['state'],expected)
  self.assertTrue(all(v=='complete' for v in publication_outcomes([dict(metric=p+'_status',value='complete') for p in ('collection','interpretation')]).values()))
  self.assertEqual(publication_outcomes([dict(metric='collection_status',value='complete'),dict(metric='collection_status',value='failed')])['collection'],'unknown')

if __name__=='__main__':unittest.main()
