"""C1 prevents legacy evidence from authorising any exact numeric publication."""
import json
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from public_privacy import sanitize_public_payload, audit_public_payload, effective_threshold
from registry_summary_privacy import SCHEMA, CONSTANTS, METADATA, registry_summary_policy, sanitize_registry_summaries, audit_registry_summaries

class LegacyClosureTests(unittest.TestCase):
    def categorical_row(self):
        field=next(f for f in registry_summary_policy(ROOT).values() if f['kind']=='categorical' and len(f['categories'])>=2)
        row=dict.fromkeys(SCHEMA)
        row.update(CONSTANTS); row.update({k:field[k] for k in METADATA})
        row.update(summary_status='published',minimum_cell_count=5,denominator_n=20,n_valid=20,n_missing=0,n_invalid=0,n_conflicting=0,category_counts_json=json.dumps([dict(code=c,n=10) for c in field['categories'][:2]]))
        return row

    def test_direct_guard_and_audit_round_requested_and_environment_up(self):
        row=self.categorical_row()
        for environment,requested in (('5',10.1),('10.1',5)):
            with self.subTest(environment=environment),patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':environment}):
                guarded=sanitize_registry_summaries([row],ROOT,requested)[0]
                self.assertEqual(guarded['minimum_cell_count'],11)
                self.assertEqual(guarded['summary_status'],'invalid_contract')
                self.assertTrue(audit_registry_summaries([row],ROOT,requested))

    def test_original_audit_uses_all_effective_threshold_sources(self):
        for metadata,requested in (({'run_summary':[{'metric':'min_cell_count','value':'11'}]},5),({'privacy_metadata':{'minimum_cell_count':11}},5),({},10.1)):
            with self.subTest(metadata=metadata),patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'5'}):
                original=dict(metadata,registry_field_summaries=[self.categorical_row()])
                self.assertTrue(audit_public_payload(original,ROOT,requested))

    def test_archived_contract_counts_stay_strict_and_invalid_requests_fail_closed(self):
        with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'5'}):
            for key in ('minimum_cell_count','n_valid'):
                for value in (10.1,True,'not-count'):
                    row=self.categorical_row();row[key]=value
                    self.assertEqual(sanitize_registry_summaries([row],ROOT)[0]['summary_status'],'invalid_contract')
            for bad in (True,None,float('inf'),'bad'):
                with self.subTest(bad=bad),self.assertRaises(ValueError):
                    sanitize_registry_summaries([self.categorical_row()],ROOT,bad)

    def test_writer_threshold_rounds_environment_up(self):
        with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'10.1'}):
            self.assertEqual(effective_threshold(),11)
        with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'5'}):
            self.assertEqual(effective_threshold(min_cell_count=10.1),11)
            for bad in (10.1,True,'not-count'):
                for payload,context in (({'run_summary':[{'metric':'min_cell_count','value':bad}]},None),({'privacy_metadata':{'minimum_cell_count':bad}},None),(None,{'minimum_cell_count':bad})):
                    with self.subTest(payload=payload,context=context),self.assertRaises(ValueError):
                        effective_threshold(payload,context)

    def test_stored_marker_never_proves_people_units_or_groups(self):
        for support in (5, 19, 20, 1000):
            row=dict(table_name='RKKP_CLL',column_name='Reg_Leukocyttal',profile_kind='numeric',n_available=support,n_missing=0,n_distinct_capped=2,min=0,max=17,mean=8.5,median=8.5,p25=1,p75=16,numeric_privacy_status='eligible_stored_summary')
            original={'column_profile_rows':[row],'renamed':{'copied':row}}
            self.assertTrue(audit_public_payload(original))
            result=sanitize_public_payload(original)
            for copy in (result['column_profile_rows'][0],result['renamed']['copied']):
                self.assertTrue(all(copy[k] is None for k in ('min','max','mean','median','p25','p75')))
                self.assertEqual(copy['numeric_privacy_status'],'needs_verified_grouped_evidence')
            self.assertEqual(result,sanitize_public_payload(result))

    def test_v1_numeric_is_unavailable_even_with_large_exact_support(self):
        field=next(f for f in registry_summary_policy(ROOT).values() if f['kind']=='numeric')
        row=dict.fromkeys(SCHEMA)
        row.update(CONSTANTS); row.update({k:field[k] for k in METADATA})
        row.update(summary_status='published',minimum_cell_count=5,denominator_n=40,n_valid=40,n_missing=0,n_invalid=0,n_conflicting=0,n_distinct=2,minimum_value_support=20,category_counts_json='[]',mean=8.5,median=8.5,p25=1,p75=16)
        self.assertTrue(audit_registry_summaries([row],ROOT))
        result=sanitize_registry_summaries([row],ROOT)
        self.assertEqual(result[0]['summary_status'],'needs_unit_evidence')
        self.assertIsNone(result[0]['mean'])
        self.assertEqual(result,sanitize_registry_summaries(result,ROOT))

    def test_stronger_threshold_applies_to_every_path_and_metadata(self):
        for archived,environment in ((10,'5'),(5,'10')):
            with patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':environment}):
                original={'privacy_metadata':{'minimum_cell_count':archived},'counts':[{'n':7}], 'column_profile_rows':[{'table_name':'T','column_name':'C','n_available':7,'n_missing':20,'pct_available':26}]}
                result=sanitize_public_payload(original,min_cell_count=1)
                self.assertEqual(result['privacy_metadata']['minimum_cell_count'],10)
                self.assertIsNone(result['counts'][0]['n'])
                self.assertIsNone(result['column_profile_rows'][0]['n_available'])
                self.assertEqual(result,sanitize_public_payload(result))

    def test_legacy_archive_run_summary_threshold_cannot_be_downgraded(self):
        original={'run_summary':[{'metric':'min_cell_count','value':'10'}], 'counts':[{'n':7}]}
        result=sanitize_public_payload(original,min_cell_count=1)
        self.assertEqual(result['privacy_metadata']['minimum_cell_count'],10)
        self.assertIsNone(result['counts'][0]['n'])

    def test_fractional_requested_threshold_is_never_rounded_down(self):
        result=sanitize_public_payload({'counts':[{'n':10}]},min_cell_count=10.1)
        self.assertEqual(result['privacy_metadata']['minimum_cell_count'],11)
        self.assertIsNone(result['counts'][0]['n'])

if __name__=='__main__': unittest.main()
