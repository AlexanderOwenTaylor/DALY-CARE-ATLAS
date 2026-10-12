"""The lightweight measurement directory only receives exact guarded profiles."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from output_evidence import collect_output_evidence
from site_bundle import decode_transport, write_site_bundle

TEMP = ROOT / '.artifact-temp/vital-profiles'
TEMP.mkdir(parents=True, exist_ok=True)
IDENTITY = ['table_name', 'column_name', 'column_type', 'column_class']
SUMMARY = ['n_rows', 'n_available', 'pct_available', 'mean', 'median', 'p25', 'p75',
           'numeric_privacy_status', 'availability_privacy_status', 'summary_scope',
           'summary_method', 'is_sensitive']
EVENT_FIELDS = ['displayname', 'numericvalue', 'recorded_time', 'meas_value', 'meas_value_clean',
                'val_type_c', 'val_type_name', 'isaccepted_yn', 'template_name',
                'date_received', 'datetime_created']
DEDICATED = [('SP_PatientInfo', 'bmi'), ('SP_PatientInfo', 'weight_in_kg'),
             ('SP_PatientInfo', 'height_in_cm'), ('RKKP_DaMyDa', 'Reg_Hoejde'),
             ('RKKP_DaMyDa', 'Reg_Vaegt')]


def profile(table, field, **changes):
    row = dict(table_name=table, column_name=field, column_type='decimal', column_class='numeric',
               profile_kind='numeric', n_rows=100, n_available=80, pct_available=80,
               n_missing=20, n_distinct_capped=20, min=0, max=999,
               mean=24, median=23, p25=21, p75=26, is_sensitive=False,
               availability_privacy_status='available')
    row.update(changes)
    return row


def catalogue(paths):
    return json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=', 1)[1].strip().removesuffix(';'))


class VitalProfileBundleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='python-', dir=TEMP)
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name) / 'site'

    def publish(self, rows, payload=None):
        descriptor = copy.deepcopy(next(t for t in collect_output_evidence(None, ROOT, {}) if t['id'] == 'column_profiles'))
        descriptor['rows'] = rows
        return write_site_bundle(self.out, payload or {'run_id': 'vital-profiles'}, [descriptor], ROOT, 'legacy_payload')

    def test_writer_projects_exact_pairs_and_preserves_duplicates_from_published_profiles(self):
        events = [profile('SP_VitaleVaerdier', field) for field in EVENT_FIELDS]
        dedicated = [profile(*pair) for pair in DEDICATED]
        excluded = [profile('SP_VitaleVaerdier_old', 'numericvalue'),
                    profile('sp_vitalevaerdier', 'numericvalue'), profile('SP_VitaleVaerdier', 'NumericValue'),
                    profile('SP_VitaleVaerdier', 'patient_id'), profile('SP_PatientInfo', 'bmi_old'),
                    profile('RKKP_DaMyDa_old', 'Reg_Vaegt'), profile('Other', 'bmi')]
        rows = events + dedicated + [copy.deepcopy(dedicated[0])] + excluded
        payload = {'run_id': 'vital-profiles', 'column_profile_rows': [profile('SP_PatientInfo', 'bmi', mean=999)]}
        paths = self.publish(rows, payload)
        emitted = catalogue(paths).get('vital_profiles')
        self.assertIsInstance(emitted, list, 'writer must emit optional vital_profiles')
        self.assertEqual(len(emitted), 17)
        self.assertEqual(emitted[:11], [{key: row[key] for key in IDENTITY} for row in events])
        for row, pair in zip(emitted[11:16], DEDICATED):
            self.assertEqual(set(row), set(IDENTITY + SUMMARY))
            self.assertEqual((row['table_name'], row['column_name']), pair)
            self.assertEqual([row[k] for k in ['n_rows', 'n_available', 'pct_available', 'mean', 'median', 'p25', 'p75']], [100, 80, 80, 24, 23, 21, 26])
            self.assertEqual(row['numeric_privacy_status'], 'eligible_stored_summary')
            self.assertEqual(row['availability_privacy_status'], 'available')
            self.assertEqual(row['summary_scope'], 'stored_source_row_profile')
            self.assertEqual(row['summary_method'], 'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample')
        self.assertEqual(emitted[16], emitted[11])
        # The adapter must not replace the independent core payload with table data.
        core = decode_transport(json.loads(paths['payload_json'].read_text(encoding='utf-8')))
        self.assertEqual(core['column_profile_rows'][0]['mean'], 999)

    def test_raw_values_identifiers_extrema_and_arbitrary_metadata_never_enter_directory(self):
        unsafe = dict(raw_value='FORBIDDEN_RAW', top_value='FORBIDDEN_TOP', patient_id='FORBIDDEN_ID',
                      arbitrary='FORBIDDEN_METADATA', min_date='1927-02-03', max_date='1927-02-04')
        emitted = catalogue(self.publish([profile('SP_VitaleVaerdier', 'numericvalue', **unsafe),
                                          profile('SP_PatientInfo', 'bmi', **unsafe)]))['vital_profiles']
        self.assertEqual(set(emitted[0]), set(IDENTITY))
        self.assertEqual(set(emitted[1]), set(IDENTITY + SUMMARY))
        self.assertNotIn('FORBIDDEN', json.dumps(emitted))
        self.assertNotIn('1927-', json.dumps(emitted))

    def test_sensitive_small_complement_and_negative_sentinel_summaries_stay_null(self):
        cases = [(dict(is_sensitive=True), 'protected_field'),
                 (dict(n_available=4), 'withheld_small_complementary_cells'),
                 (dict(n_missing=1), 'withheld_small_complementary_cells'),
                 (dict(min=-999), 'needs_validation_negative_sentinel'),
                 (dict(numeric_privacy_status='withheld_constant_profile'), 'withheld_constant_profile')]
        for changes, status in cases:
            with self.subTest(changes=changes):
                row = catalogue(self.publish([profile('SP_PatientInfo', 'bmi', **changes)]))['vital_profiles'][0]
                self.assertEqual(row['numeric_privacy_status'], status)
                self.assertTrue(all(row[k] is None for k in ['mean', 'median', 'p25', 'p75']))
                if status == 'withheld_small_complementary_cells':
                    self.assertEqual(row['availability_privacy_status'], status)
                    self.assertTrue(all(row[k] is None for k in ['n_available', 'pct_available']))
                if status == 'protected_field':
                    self.assertIs(row['is_sensitive'], True)

    def test_absent_empty_alias_and_unrelated_profiles_omit_optional_key(self):
        for payload in ({}, {'column_profile_rows': []}, {'column_profile_alias': [profile('SP_PatientInfo', 'bmi')]},
                        {'column_profile_rows': [profile('Other', 'bmi')]}):
            paths = write_site_bundle(self.out, payload, [], ROOT, 'legacy_payload')
            self.assertNotIn('vital_profiles', catalogue(paths))
        paths = write_site_bundle(self.out, {'column_profile_rows': [profile('SP_PatientInfo', 'bmi')]}, [], ROOT, 'legacy_payload')
        self.assertEqual(catalogue(paths)['vital_profiles'][0]['mean'], 24)

    def test_directory_metadata_obeys_initial_budget_and_preserves_published_site(self):
        paths = self.publish([profile('SP_PatientInfo', 'bmi')])
        prior = {p: p.read_bytes() for p in paths['assets'] + [paths['manifest']]}
        wide = profile('SP_VitaleVaerdier', 'numericvalue', column_type='x' * 530000)
        with self.assertRaisesRegex(ValueError, 'Initial asset byte budget exceeded'):
            write_site_bundle(self.out, {'column_profile_rows': [wide]}, [], ROOT, 'legacy_payload')
        self.assertEqual(prior, {p: p.read_bytes() for p in prior})


if __name__ == '__main__':
    unittest.main()
