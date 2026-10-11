import csv,json,pathlib,sys,tempfile,unittest,os
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from output_evidence import collect_output_evidence,load_registry
class ReviewedCoverage(unittest.TestCase):
 def test_selected_date_identity_survives_guard_without_releasing_bounds(self):
  spec=next(s for s in load_registry(ROOT)['artifacts'] if s['id']=='atlas_temporal_coverage')
  with tempfile.TemporaryDirectory() as tmp:
   base=pathlib.Path(tmp);(base/'outputs/panels').mkdir(parents=True)
   keys=list(spec['schemas'][0]); row=dict(table_name='S',date_column='ClinicalDate',n_rows=20,pct_available=75,min_date='2020-01-01',max_date='2025-01-01')
   with (base/spec['source_file']).open('w',newline='',encoding='utf8') as f:
    w=csv.writer(f);w.writerow(keys);w.writerow([row.get(k) for k in keys])
   t=next(t for t in collect_output_evidence(base,ROOT) if t['id']==spec['id'])
   self.assertEqual(t['rows'][0].get('date_column'),'ClinicalDate');self.assertIsNone(t['rows'][0].get('min_date'));self.assertIsNone(t['rows'][0].get('max_date'))
   columns={c['key']:c for c in t['columns']};self.assertEqual(columns['date_column']['label'],'Selected date field');self.assertIn('date validity',columns['pct_available']['definition'])
 def test_reference_category_and_bounded_id_meanings_reach_evidence_catalogue(self):
  with tempfile.TemporaryDirectory() as tmp:
   tables={t['id']:t for t in collect_output_evidence(pathlib.Path(tmp),ROOT)}
   col=lambda table,key: next(c for c in tables[table]['columns'] if c['key']==key)
   self.assertEqual(col('registry_clinical_summary','n_patients')['label'],'Bounded ID / record count');self.assertIn('100,000',col('registry_clinical_summary','n_patients')['definition']);self.assertIn('otherwise counts source records',col('registry_clinical_summary','n_patients')['definition'])
   self.assertEqual(col('damyda_clinical_profile','n')['label'],'Retained category occurrences');self.assertIn('bounded',tables['damyda_clinical_profile']['row_grain'].lower());self.assertIn('DaMyDa',tables['damyda_clinical_profile']['source_terms'])
   self.assertEqual(tables['npu_dictionary_vectors']['count_basis'],'reference_dictionary_metadata');self.assertEqual(col('npu_dictionary_vectors','n_dictionary_codes')['label'],'Dictionary entries');self.assertIn('not clinical reference ranges',tables['damyda_numeric_fields']['row_grain'])
 def test_r_python_reviewed_evidence_metadata_parity(self):
  parity=os.environ.get('DALYCARE_METADATA_TEST_OUTPUT')
  if not parity or not pathlib.Path(parity).exists():self.skipTest('Run the R metadata test with DALYCARE_METADATA_TEST_OUTPUT first')
  snapshot={'panels':{'atlas_temporal_coverage':[dict(table_name='S',date_column='ClinicalDate',n_rows=20,pct_available=75,min_date='2020-01-01',max_date='2025-01-01')]}}
  py={t['id']:t for t in collect_output_evidence(None,ROOT,snapshot)}
  r={t['id']:t for t in json.loads(pathlib.Path(parity).read_text(encoding='utf8'))}
  reviewed=['checks','npu_dictionary_summary','npu_dictionary_vectors','npu_lab_usage_by_vector','npu_lab_unmatched_codes','npu_detective_code_inventory','npu_detective_candidates','isotype_code_usage','isotype_bucket_summary','mm_treatment_code_counts','mm_treatment_source_summary','registry_clinical_summary','damyda_clinical_profile','lyfo_clinical_profile','cll_clinical_profile','damyda_numeric_fields','atlas_temporal_coverage','atlas_temporal_coverage_years','atlas_temporal_date_quality','atlas_spatial_region_counts','atlas_spatial_region_coverage','atlas_dk_choropleth_regions','situation_report_summary','situation_report_breakdowns','situation_report_freshness','atlas_streaming_progress_summary','source_availability_drift','atlas_module_readiness','run_summary','action_items','source_resolution','memory_plan','db_budget_actions','domain_panels','panel_kpis_product','panel_distributions','panel_parity','legacy_resource_audit','resource_reconciliation','source_truth_evidence','canonical_resource_reconciliation','source_truth_summary']
  for key in reviewed:
   for field in ['title','row_grain','count_basis','columns','source_terms']:self.assertEqual(py[key][field],r[key][field],(key,field))
  self.assertEqual(py['atlas_temporal_coverage']['rows'],r['atlas_temporal_coverage']['rows'])
if __name__=='__main__':unittest.main()
