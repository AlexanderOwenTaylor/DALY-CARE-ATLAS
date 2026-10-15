"""Vitals consume canonical screened profiles; no duplicate summary directory."""
import copy,json,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'scripts'))
from output_evidence import collect_output_evidence
from site_bundle import decode_transport,write_site_bundle
from runtime_fixture import public_rows,public_catalogue
def profile(table,field,**changes):
 row=dict(table_name=table,column_name=field,column_type='decimal',column_class='numeric',profile_kind='numeric',n_rows=100,n_available=80,pct_available=80,n_missing=20,n_distinct_capped=20,min=0,max=999,mean=24,median=23,p25=21,p75=26,is_sensitive=False,availability_privacy_status='available');row.update(changes);return row
class VitalProfileBundleTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.out=Path(self.tmp.name)/'site'
 def publish(self,rows,payload=None):
  table=copy.deepcopy(next(t for t in collect_output_evidence(None,ROOT,{}) if t['id']=='column_profiles'));table['rows']=rows
  return write_site_bundle(self.out,payload or {'run_id':'SYNTHETIC_VITALS'},[table],ROOT,'legacy_payload')
 def test_canonical_profiles_preserve_all_exact_identities_duplicates_and_single_authority(self):
  pairs=[('SP_VitaleVaerdier',f) for f in ['displayname','numericvalue','recorded_time','meas_value','meas_value_clean','val_type_c','val_type_name','isaccepted_yn','template_name','date_received','datetime_created']]+[('SP_PatientInfo','bmi'),('SP_PatientInfo','weight_in_kg'),('SP_PatientInfo','height_in_cm'),('RKKP_DaMyDa','Reg_Hoejde'),('RKKP_DaMyDa','Reg_Vaegt'),('SP_PatientInfo','bmi'),('SP_VitaleVaerdier_old','numericvalue'),('sp_vitalevaerdier','numericvalue'),('SP_VitaleVaerdier','NumericValue'),('SP_VitaleVaerdier','patient_id'),('Other','bmi')]
  paths=self.publish([profile(*p) for p in pairs],{'column_profile_rows':[profile('SP_PatientInfo','bmi',mean=999)]})
  emitted=public_rows(self.out,'column_profiles')
  self.assertEqual([(r['table_name'],r['column_name']) for r in emitted],pairs)
  self.assertEqual(emitted[11],emitted[16]);self.assertTrue(all(r['mean'] is None for r in emitted))
  self.assertEqual(emitted[11]['numeric_privacy_status'],'needs_verified_grouped_evidence')
  self.assertEqual([emitted[11][k] for k in ('n_rows','n_available','pct_available')],[100,80,80])
  self.assertNotIn('vital_profiles',public_catalogue(self.out));self.assertNotIn('column_profile_rows',decode_transport(json.loads(paths['payload_json'].read_text())))
 def test_raw_values_identifiers_extrema_and_arbitrary_metadata_never_enter_any_public_format(self):
  unsafe=dict(raw_value='FORBIDDEN_RAW',top_value='FORBIDDEN_TOP',patient_id='FORBIDDEN_ID',arbitrary='FORBIDDEN_METADATA',min_date='1927-02-03',max_date='1927-02-04')
  self.publish([profile('SP_VitaleVaerdier','numericvalue',**unsafe),profile('SP_PatientInfo','bmi',**unsafe)])
  for p in self.out.rglob('*'):
   if p.is_file():self.assertNotRegex(p.read_text(encoding='utf-8'),'FORBIDDEN|1927-')
 def test_sensitive_small_complement_and_negative_sentinel_summaries_stay_null(self):
  for changes,status in [(dict(is_sensitive=True),'protected_field'),(dict(n_available=4),'withheld_small_complementary_cells'),(dict(n_missing=1),'withheld_small_complementary_cells'),(dict(min=-999),'needs_validation_negative_sentinel'),(dict(numeric_privacy_status='withheld_constant_profile'),'withheld_constant_profile')]:
   with self.subTest(changes=changes):
    self.publish([profile('SP_PatientInfo','bmi',**changes)]);row=public_rows(self.out,'column_profiles')[0]
    self.assertEqual(row['numeric_privacy_status'],status);self.assertTrue(all(row[k] is None for k in ('mean','median','p25','p75')))
    if status=='withheld_small_complementary_cells':self.assertEqual(row['availability_privacy_status'],status);self.assertIsNone(row['n_available']);self.assertIsNone(row['pct_available'])
    if status=='protected_field':self.assertIs(row['is_sensitive'],True)
 def test_empty_and_unrelated_fields_remain_honest_metadata(self):
  self.publish([]);self.assertEqual(public_rows(self.out,'column_profiles'),[])
  self.publish([profile('Other','bmi')]);self.assertEqual(public_rows(self.out,'column_profiles')[0]['table_name'],'Other')
 def test_required_overwide_profile_preserves_previous_site(self):
  paths=self.publish([profile('SP_PatientInfo','bmi')]);prior={p:p.read_bytes() for p in paths['assets']+[paths['manifest']]}
  with self.assertRaisesRegex(ValueError,'row|byte|budget'):self.publish([profile('SP_VitaleVaerdier','numericvalue',column_type='x'*530000)])
  self.assertEqual(prior,{p:p.read_bytes() for p in prior})
if __name__=='__main__':unittest.main()
