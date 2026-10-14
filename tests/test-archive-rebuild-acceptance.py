"""Synthetic tests for the local-only production archive acceptance checker."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('archive_acceptance', ROOT / 'scripts/validate_archive_rebuild.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ArchiveAcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.reference = {
            'source_columns': [['Source.Ø', 'field-x'], ['Source.Ø', 'patientid']],
            'registry_identities': [['RKKP_CLL', 'Reg_BinetStadium']],
            'published_registry': [{'table_name': 'RKKP_CLL', 'source_column': 'Reg_BinetStadium',
                                    'n_valid': '10', 'category_counts_json': '[{"code":"A","n":5},{"code":"B","n":5}]'}],
            'small_support_profiles': [{'identity': ['Source.Ø', 'field-x'], 'statistic_columns': ['mean', 'min_date']}],
        }
        self.tables = {
            'column_profiles': [{'table_name': 'Source.Ø', 'column_name': key, 'mean': None, 'min_date': None} for key in ('field-x', 'patientid')],
            'semantic_dictionary': [{'source_name': 'Source.Ø', 'raw_column': key} for key in ('field-x', 'patientid')],
            'registry_field_summaries': [dict(self.reference['published_registry'][0], summary_status='published')],
        }

    def test_preserves_exact_metadata_and_categorical_counts(self):
        result = module.compare_tables(self.reference, self.tables)
        self.assertEqual(result['columns'], 2)
        self.assertEqual(result['reconciled_distributions'], 1)
        self.assertEqual(result['small_support_profiles'], 1)

    def test_hidden_identifier_column_metadata_is_not_allowed(self):
        self.tables['semantic_dictionary'].pop()
        with self.assertRaisesRegex(ValueError, 'catalogue'):
            module.compare_tables(self.reference, self.tables)

    def test_rejects_lost_or_duplicate_registry_outcomes(self):
        self.tables['registry_field_summaries'] *= 2
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            module.compare_tables(self.reference, self.tables)

    def test_rejects_changed_published_distribution(self):
        self.tables['registry_field_summaries'][0]['category_counts_json'] = '[{"code":"A","n":10}]'
        with self.assertRaisesRegex(ValueError, 'distribution'):
            module.compare_tables(self.reference, self.tables)

    def test_statistics_cannot_survive_in_alternate_payloads(self):
        nested = {'legacy': {'profiles': [{'source_name': 'Source.Ø', 'raw_column': 'field-x', 'mean': 123.456}]}}
        with self.assertRaisesRegex(ValueError, 'small-support'):
            module.check_small_profiles(self.reference, nested)

    def test_reference_declared_statistics_are_screened(self):
        self.reference['small_support_profiles'][0]['statistic_columns'].append('raw_min_date')
        row = {'table_name': 'Source.Ø', 'column_name': 'field-x', 'raw_min_date': 'synthetic-date'}
        with self.assertRaisesRegex(ValueError, 'small-support'):
            module.check_small_profiles(self.reference, [row])

    def test_malformed_protected_profile_reference_fails_closed(self):
        for invalid in (None, {'identity': ['Source.Ø'], 'statistic_columns': []},
                        {'identity': ['Source.Ø', 'field-x'], 'statistic_columns': 'mean'},
                        {'identity': ['Source.Ø', 'field-x'], 'statistic_columns': ['']},
                        {'identity': ['Source.Ø', 1], 'statistic_columns': []}):
            with self.subTest(invalid=invalid):
                self.reference['small_support_profiles'] = [invalid]
                with self.assertRaisesRegex(ValueError, 'reference'):
                    module.check_small_profiles(self.reference, [])

    def test_strict_threshold_may_withhold_but_cannot_drop_field(self):
        row = self.tables['registry_field_summaries'][0]
        row.update(summary_status='withheld', category_counts_json='[]', n_valid=None)
        with self.assertRaisesRegex(ValueError, 'distribution'):
            module.compare_tables(self.reference, self.tables)
        self.assertEqual(module.compare_tables(self.reference, self.tables, allow_stricter_withholding=True)['withheld_distributions'], 1)

    def test_reads_registered_shards_without_executing_javascript(self):
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory)
            row = {'table_name': 'Source.Ø', 'column_name': 'field-x'}
            registration = dict(build_id='new', table_id='column_profiles', shard_id='s0001', rows_json=json.dumps([row]))
            (site / 's.js').write_text('window.DALYCARE_OUTPUTS.register(' + json.dumps(registration) + ');', encoding='utf-8')
            catalogue = dict(build_id='new', tables=[dict(id='column_profiles', represented_row_count=1,
                            shards=[dict(src='s.js', rows=1, id='s0001')])])
            (site / 'DALYCARE_output_catalogue.js').write_text('window.DALYCARE_OUTPUT_CATALOGUE = ' + json.dumps(catalogue) + ';', encoding='utf-8')
            self.assertEqual(module.read_site_tables(site)[0]['column_profiles'], [row])
            registration['build_id'] = 'stale'
            (site / 's.js').write_text('window.DALYCARE_OUTPUTS.register(' + json.dumps(registration) + ');', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'Stale'):
                module.read_site_tables(site)

    def test_rejects_mutation_of_original_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'evidence.csv').write_text('changed', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'changed'):
                module.verify_original({'input_files_sha256': {'evidence.csv': 'original-checksum'}}, root)


if __name__ == '__main__':
    unittest.main()
