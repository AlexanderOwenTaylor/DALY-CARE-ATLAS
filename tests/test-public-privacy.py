import sys, unittest, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
from public_privacy import sanitize_public_payload, audit_public_payload
class PrivacyTests(unittest.TestCase):
 def test_structural_panel_sizes_are_preserved_at_exact_paths(self):
  rows=[{'group':'Source Content','panel_name':'example','title':'Example','n_rows':1}]
  out=sanitize_public_payload({'panel_groups':rows,'review_overview':{'panel_groups':rows},'review_infrastructure_sections':{'panels':rows},'panels':{'observed':rows}})
  self.assertEqual(out['panel_groups'],rows)
  self.assertEqual(out['review_infrastructure_sections']['panels'],rows)
  self.assertEqual(out['review_overview']['panel_groups'],rows)
  self.assertIsNone(out['panels']['observed'][0]['n_rows'])
 def profile(self, **kw):
  r=dict(table_name="RKKP_CLL",column_name="Reg_Leukocyttal",profile_kind="numeric",n_rows="100",n_available="80",n_missing="20",pct_available="80",pct_missing="20",n_distinct_capped="20",min="0",max="999999.123",mean="7",median="6",p25="4",p75="8")
  r.update(kw); return r
 def clean(self,r): return sanitize_public_payload({"column_profile_rows":[r],"review":{"columns":[r]}})["column_profile_rows"][0]
 def test_small_and_complement(self):
  for n in ["1","4"]:
   for key in ["n_available","n_missing"]:
    r=self.clean(self.profile(**{key:n}))
    for k in ["n_available","n_missing","pct_available","pct_missing"]: self.assertIsNone(r[k])
  r=self.clean(self.profile(n_available="4")); self.assertIsNone(r["mean"])
 def test_measurements(self):
  self.assertEqual(self.clean(self.profile(n_available="5",n_distinct_capped="2"))["mean"],"7")
  for kw in [dict(column_name="culturefindingsid"),dict(column_name="DrugCode"),dict(n_available=None),dict(n_distinct_capped="1"),dict(n_distinct_capped="79"),dict(min="-999")]:
   self.assertIsNone(self.clean(self.profile(**kw))["mean"])
  self.assertIsNone(self.clean(self.profile())["max"])
 def test_dates_categories_and_idempotence(self):
  p={"generated_at":"2026-10-11", "review":{"min_date":"1927-02-03","date_range":"1927-02-03 to 2020-03-04"},"column_top_value_rows":[{"table_name":"T","column_name":"report_text","value":"SYNTHETIC FORBIDDEN NAME","n":20}],"column_profile_rows":[self.profile()],"clinical_display_dictionary":[{"kind":"field","code":"ABC","retrieved_on":"2026-10-10"}]}
  o=sanitize_public_payload(p)
  self.assertEqual(o["generated_at"],p["generated_at"])
  self.assertEqual(o["clinical_display_dictionary"],p["clinical_display_dictionary"])
  self.assertNotIn("SYNTHETIC FORBIDDEN NAME",json.dumps(o)); self.assertNotIn("1927-02-03",json.dumps(o))
  self.assertEqual(o,sanitize_public_payload(o))
 def test_date_column_copy_cannot_reconstruct_suppressed_availability(self):
  p={'column_profile_rows':[self.profile(column_name='ClinicalDate',profile_kind='date',n_missing='1')], 'panels':{'atlas_temporal_coverage':[{'table_name':'RKKP_CLL','date_column':'ClinicalDate','pct_available':'99'}]}}
  out=sanitize_public_payload(p)
  self.assertIsNone(out['panels']['atlas_temporal_coverage'][0]['pct_available'])
  out['panels']['atlas_temporal_coverage'][0]['pct_available']='99'
  self.assertTrue(audit_public_payload(out))
 def test_observed_distribution_aliases_and_map_residual(self):
  p={'panel_distribution_rows':[{'distribution_type':'observed','raw_column':'report_text','raw_value':'SYNTHETIC_FORBIDDEN_NAME','display_value':'SYNTHETIC_FORBIDDEN_NAME','raw_code':'SYNTHETIC_FORBIDDEN_UUID','n':20,'pct':20}], 'column_top_value_rows':[{'display_value':'SYNTHETIC_FORBIDDEN_NAME','n':20}], 'panels':{'atlas_dk_choropleth_regions':[{'region_code':'A','choropleth_value':1,'damyda_n':1,'pct_total':1},{'region_code':'B','choropleth_value':99,'damyda_n':99,'pct_total':99}]},'total':100}
  out=sanitize_public_payload(p)
  self.assertNotIn('SYNTHETIC_FORBIDDEN',json.dumps(out))
  self.assertIsNone(out['panel_distribution_rows'][0]['pct'])
  self.assertTrue(all(r['choropleth_value'] is None and r['damyda_n'] is None and r['pct_total'] is None for r in out['panels']['atlas_dk_choropleth_regions']))
  self.assertEqual(audit_public_payload(out),[])
 def test_shared_fixtures_are_idempotent_and_contain_no_forbidden_bytes(self):
  fixtures=json.loads((Path(__file__).parent/'fixtures/public-privacy-input.json').read_text())
  for p in fixtures:
   out=sanitize_public_payload(p)
   self.assertEqual(out,sanitize_public_payload(out))
   self.assertEqual(audit_public_payload(out),[])
   data=json.dumps(out)
   for forbidden in ('SYNTHETIC_FORBIDDEN_NAME','SYNTHETIC_FORBIDDEN_UUID','1927-02-03','987654.125','-999'):
    self.assertNotIn(forbidden,data)
if __name__ == "__main__": unittest.main()
