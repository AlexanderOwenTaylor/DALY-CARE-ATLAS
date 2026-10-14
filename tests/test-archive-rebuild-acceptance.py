"""Synthetic tests for the local-only production archive acceptance checker."""
import importlib.util
import csv
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

    def test_csv_downloads_match_screened_table_rows_and_types(self):
        descriptor = {'id': 'sample', 'columns': [{'key': 'code', 'type': 'string'},
                       {'key': 'n', 'type': 'number'}, {'key': 'flag', 'type': 'boolean'}]}
        rows = [{'code': '0012', 'n': 10, 'flag': False}, {'code': 'Ø', 'n': None, 'flag': None}]
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory)
            (site / 'downloads').mkdir()
            path = site / 'downloads/sample.csv'
            with path.open('w', encoding='utf-8', newline='') as handle:
                writer = csv.writer(handle)
                writer.writerows([['code', 'n', 'flag'], ['Ø', '', ''], ['0012', '10.0', 'FALSE']])
            module.compare_csv_downloads(site, {'sample': rows}, {'tables': [descriptor]})
            path.write_text('code,n,flag\n0012,9,FALSE\nØ,,\n', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'disagrees'):
                module.compare_csv_downloads(site, {'sample': rows}, {'tables': [descriptor]})
            path.write_text('code,n,flag,patient_value\n0012,10,FALSE,secret\nØ,,,\n', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'schema'):
                module.compare_csv_downloads(site, {'sample': rows}, {'tables': [descriptor]})

    def test_registered_payload_copy_cannot_change_distribution(self):
        descriptor = {'id': 'registry_field_summaries', 'columns': [
            {'key': key, 'type': 'number' if key == 'n_valid' else 'string'}
            for key in self.tables['registry_field_summaries'][0]]}
        registry = {'artifacts': [{'id': descriptor['id'], 'payload_path': ['panel_groups', 'registry_field_summaries']}]}
        payload = {'panel_groups': {'registry_field_summaries': [dict(self.tables['registry_field_summaries'][0])]}}
        catalogue = {'tables': [descriptor]}
        module.compare_payload_tables(payload, self.tables, catalogue, registry)
        payload['panel_groups']['registry_field_summaries'][0]['category_counts_json'] = '[{"code":"A","n":10}]'
        with self.assertRaisesRegex(ValueError, 'disagrees'):
            module.compare_payload_tables(payload, self.tables, catalogue, registry)
        payload['panel_groups']['registry_field_summaries'] = []
        with self.assertRaisesRegex(ValueError, 'disagrees'):
            module.compare_payload_tables(payload, self.tables, catalogue, registry)
        # A lean payload may omit a detailed table and load its registered shards.
        module.compare_payload_tables({}, self.tables, catalogue, registry)

    def test_payload_copies_cannot_add_unregistered_values(self):
        columns = [{'key': 'code', 'type': 'string'}]
        with self.assertRaisesRegex(ValueError, 'schema'):
            module.canonical_rows([{'code': 'A', 'patient_value': 'SYNTHETIC_UNEXPECTED'}], columns)

    def test_comparison_preserves_all_numeric_digits(self):
        columns = [{'key': 'n', 'type': 'number'}]
        first = module.canonical_rows([{'n': 123456789012345678901234567890}], columns)
        second = module.canonical_rows([{'n': 123456789012345678901234567891}], columns)
        self.assertNotEqual(first, second)
        self.assertEqual(module.canonical_rows([{'n': '-0.0'}, {'n': '10.0'}], columns),
                         module.canonical_rows([{'n': 10}, {'n': 0}], columns))

    def test_valid_shard_sized_csv_cell_is_read_without_global_limit_leak(self):
        descriptor = {'id': 'reference', 'columns': [{'key': 'definition', 'type': 'string'}]}
        rows = [{'definition': 'x' * 150000}]
        old_limit = csv.field_size_limit()
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory)
            (site / 'downloads').mkdir()
            (site / 'downloads/reference.csv').write_text('definition\n' + rows[0]['definition'] + '\n', encoding='utf-8')
            module.compare_csv_downloads(site, {'reference': rows}, {'tables': [descriptor]})
        self.assertEqual(csv.field_size_limit(), old_limit)


if __name__ == '__main__':
    unittest.main()
