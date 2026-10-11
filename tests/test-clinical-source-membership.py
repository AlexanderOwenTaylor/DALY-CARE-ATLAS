"""Literal shared selector parity and imported publication evidence invariants."""
import copy
import hashlib
import importlib
import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from build_ui_iteration import build
from output_evidence import collect_output_evidence
from public_privacy import sanitize_public_payload
from site_bundle import decode_transport

FIXTURE = json.loads((ROOT / 'tests/fixtures/clinical-source-membership.json').read_text(encoding='utf-8'))
TEMP_ROOT = ROOT.parent / '.artifact-temp/iteration18-team/python-tests'
TEMP_ROOT.mkdir(parents=True, exist_ok=True)


def load_payload(path):
    return decode_transport(json.loads(path.read_text(encoding='utf-8')))


def published_tables(path):
    raw = (path / 'DALYCARE_output_catalogue.js').read_text(encoding='utf-8')
    catalogue = json.loads(raw.split('=', 1)[1].strip().removesuffix(';'))
    tables = []
    for table in catalogue['tables']:
        rows = []
        for shard in table['shards']:
            text = (path / shard['src']).read_text(encoding='utf-8')
            registration = json.loads(text.removeprefix('window.DALYCARE_OUTPUTS.register(').strip().removesuffix(');'))
            rows.extend(json.loads(registration['rows_json']))
        descriptor = {k: v for k, v in table.items() if k != 'shards'}
        # Snapshot-preview transport is explicitly labelled limited on publication.
        descriptor['rows'] = rows
        tables.append(descriptor)
    return tables


class MembershipSelectorTest(unittest.TestCase):
    def module(self):
        self.assertIsNotNone(importlib.util.find_spec('clinical_source_membership'),
                             'Required pure membership selector is missing')
        return importlib.import_module('clinical_source_membership')

    def test_shared_resource_cases_have_frozen_validation_codes(self):
        module = self.module()
        for case in FIXTURE['resource_cases']:
            with self.subTest(case=case['name']):
                original = copy.deepcopy(case['input'])
                if case['expected_valid']:
                    self.assertEqual(module.validate_membership_spec(case['input']), original)
                else:
                    with self.assertRaisesRegex(ValueError, case['expected_error']):
                        module.validate_membership_spec(case['input'])
                self.assertEqual(case['input'], original)

    def test_full_literal_selector_parity_preserves_all_evidence(self):
        module = self.module()
        spec = module.load_membership_spec(ROOT)
        original_spec = copy.deepcopy(spec)
        for case in FIXTURE['selector_cases']:
            with self.subTest(case=case['name']):
                inputs = copy.deepcopy(case['input'])
                result = module.clinical_source_inventory(
                    inputs['catalog_rows'], spec, inputs['evidence_origin'], inputs['inventory_limited'])
                self.assertEqual(result, case['expected'])
                self.assertEqual(inputs, case['input'])
                self.assertEqual(spec, original_spec)
                forbidden = {'n_rows', 'n_columns', 'n_available', 'min_date', 'max_date', 'value', 'text'}
                self.assertTrue(all(not forbidden.intersection(row) for row in result['rows']))

    def test_installed_inventory_covers_only_twelve_reviewed_panels(self):
        spec = self.module().load_membership_spec(ROOT)
        self.assertEqual([p['panel_id'] for p in spec['panels']], FIXTURE['covered_panel_ids'])
        self.assertEqual(spec['inventory_version'], '2026-10-11-clinical-source-1')
        self.assertEqual(next(p for p in spec['panels'] if p['panel_id'] == 'clinical_imaging')['review_key'], 'imaging')

    def test_duplicate_diagnostics_are_bounded_without_arbitrary_count_selection(self):
        module = self.module()
        rows = [dict(table_name=f'unknown_{i}', n_rows=n) for i in range(105) for n in (0, 100)]
        result = module.clinical_source_inventory(rows, module.load_membership_spec(ROOT))
        self.assertEqual(result['rows'], [])
        self.assertEqual(len(result['diagnostics']), 101)
        self.assertEqual(result['diagnostics'][0], dict(code='duplicate_source_identity', source_key='unknown_0', membership_id=None))
        self.assertEqual(result['diagnostics'][99]['source_key'], 'unknown_99')
        self.assertEqual(result['diagnostics'][-1], dict(code='diagnostics_truncated', source_key=None, membership_id=None))

    def test_invalid_supplied_lineage_is_unresolved_and_status_is_literal(self):
        module = self.module()
        result = module.clinical_source_inventory([
            dict(table_name='BIOBANK_SAMPLES', canonical_resource_id=42, load_status='LOADED')
        ], module.load_membership_spec(ROOT))
        row = result['rows'][0]
        self.assertIsNone(row['canonical_resource_id'])
        self.assertEqual(row['canonical_lineage_state'], 'conflicting')
        self.assertEqual((row['load_status'], row['load_state']), ('LOADED', 'unknown'))

    def test_unknown_supplied_lineage_never_creates_a_canonical_relationship(self):
        module = self.module()
        result = module.clinical_source_inventory([
            dict(table_name='view_diagnosses_all', canonical_resource_id='invented_lineage', load_status='loaded')
        ], module.load_membership_spec(ROOT))
        self.assertEqual(result['rows'][0]['canonical_lineage_state'], 'unestablished')
        self.assertIsNone(result['rows'][0]['canonical_resource_id'])
        self.assertEqual(result['diagnostics'], [])


class ImportedMembershipBuildTest(unittest.TestCase):
    maxDiff = 1200

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='membership-', dir=TEMP_ROOT)
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.project = self.base / 'project'
        for directory in ('config', 'inst/config', 'inst/templates'):
            shutil.copytree(ROOT / directory, self.project / directory)
        self.input = self.base / 'input'
        self.input.mkdir()
        self.output = self.base / 'site'
        # Both alias identities have distinct catalog evidence, only one has profiles.
        self.payload = sanitize_public_payload({
            'run_id': 'synthetic-membership-run',
            'catalog_rows': [dict(table_name='BIOBANK_SAMPLES', load_status='loaded', n_rows=0),
                             dict(table_name='LAB_BIOBANK_SAMPLES', load_status='ok', n_rows=50)],
            'column_profile_rows': [dict(table_name='BIOBANK_SAMPLES', column_name='sample_type')],
            'review_clinical_sections': {'notes': [dict(table_name='SDS_epikur', n_rows=50)]},
            'review_module_readiness': [dict(module='historical', n_rows=50)],
            'panels': {'atlas_module_readiness': [dict(module='historical', n_rows=50)]},
            'panel_kpi_rows': [dict(panel_id='clinical_biobank', kpi_id='source_rows', unit='rows', count_scope='historical', value='50')],
        }, project_root=self.project)
        self.write_input()

    def write_input(self):
        (self.input / 'DALYCARE_atlas_payload.js').write_text(
            'window.DALYCARE_ATLAS_PAYLOAD = ' + json.dumps(self.payload) + ';', encoding='utf-8')

    def test_builder_appends_imported_metadata_and_preserves_original_arrays_and_tables(self):
        before_tables = collect_output_evidence(None, self.project, self.payload)
        build(self.input, self.output, self.project)
        payload = load_payload(self.output / 'DALYCARE_atlas_payload.json')
        self.assertTrue('clinical_source_inventory' in payload, 'Imported membership overlay is missing')
        self.assertEqual(payload['clinical_source_inventory']['evidence_origin'], 'imported_snapshot')
        self.assertEqual([row['source_key'] for row in payload['clinical_source_inventory']['rows']],
                         ['BIOBANK_SAMPLES', 'LAB_BIOBANK_SAMPLES'])
        for key in ('catalog_rows', 'column_profile_rows', 'review_clinical_sections', 'review_module_readiness', 'panels', 'panel_kpi_rows'):
            self.assertEqual(payload[key], self.payload[key], key)
        for table in before_tables:
            if table['status'] == 'snapshot_preview':
                table['status'] = 'limited'
        self.assertEqual(published_tables(self.output), before_tables)
        manifest = json.loads(self.output.with_suffix('.manifest.json').read_text(encoding='utf-8'))
        resource = self.project / 'inst/config/clinical-source-membership.json'
        recorded = [i for i in manifest['inputs'] if i.get('artifact_id') == 'clinical_source_membership']
        self.assertEqual(len(recorded), 1)
        self.assertEqual(recorded[0]['path'], str(resource.resolve()))
        self.assertEqual(recorded[0]['inventory_version'], '2026-10-11-clinical-source-1')
        self.assertEqual(recorded[0]['sha256'], hashlib.sha256(resource.read_bytes()).hexdigest())
        self.assertEqual(recorded[0]['bytes'], resource.stat().st_size)

    def test_required_config_failure_preserves_old_site_and_manifest(self):
        self.output.mkdir()
        (self.output / 'previous.txt').write_bytes(b'previous site')
        manifest = self.output.with_suffix('.manifest.json')
        manifest.write_bytes(b'previous manifest')
        resource = self.project / 'inst/config/clinical-source-membership.json'
        for contents in (None, '{broken', '{"schema_version":2}'):
            with self.subTest(contents=contents):
                if contents is None:
                    resource.unlink()
                else:
                    resource.write_text(contents, encoding='utf-8')
                with self.assertRaisesRegex(ValueError, 'clinical source membership'):
                    build(self.input, self.output, self.project)
                self.assertEqual((self.output / 'previous.txt').read_bytes(), b'previous site')
                self.assertEqual(manifest.read_bytes(), b'previous manifest')
                self.assertEqual(list(self.output.iterdir()), [self.output / 'previous.txt'])

    def test_partial_installed_resource_is_valid_pure_metadata_but_cannot_publish(self):
        module = importlib.import_module('clinical_source_membership')
        resource = self.project / 'inst/config/clinical-source-membership.json'
        partial = json.loads(resource.read_text(encoding='utf-8'))
        partial['panels'] = partial['panels'][:-1]
        minimal = FIXTURE['resource_cases'][0]['input']
        self.output.mkdir()
        (self.output / 'previous.txt').write_bytes(b'previous site')
        manifest = self.output.with_suffix('.manifest.json')
        manifest.write_bytes(b'previous manifest')
        for candidate in (partial, minimal):
            self.assertEqual(module.validate_membership_spec(candidate), candidate)
            resource.write_text(json.dumps(candidate), encoding='utf-8')
            for label, action in (
                    ('required loader', lambda: module.load_membership_resource(self.project)),
                    ('spec loader', lambda: module.load_membership_spec(self.project)),
                    ('actual build', lambda: build(self.input, self.output, self.project))):
                with self.subTest(panel_count=len(candidate['panels']), action=label):
                    with self.assertRaisesRegex(ValueError, 'clinical source membership') as caught:
                        action()
                    self.assertEqual(str(caught.exception.__cause__), 'incomplete_panel_coverage')
                    self.assertEqual((self.output / 'previous.txt').read_bytes(), b'previous site')
                    self.assertEqual(manifest.read_bytes(), b'previous manifest')
                    self.assertEqual(list(self.output.iterdir()), [self.output / 'previous.txt'])

    def test_saturated_legacy_guard_is_possible_truncation_not_upstream_absence(self):
        self.payload['catalog_rows'] += [dict(table_name=f'unreviewed_{i}', load_status='loaded') for i in range(998)]
        self.write_input()
        build(self.input, self.output, self.project)
        payload = load_payload(self.output / 'DALYCARE_atlas_payload.json')
        inventory = payload['clinical_source_inventory']
        self.assertEqual(inventory['inventory_state'], 'limited')
        self.assertEqual(inventory['diagnostics'][0], dict(code='catalog_limited', source_key=None, membership_id=None))
        self.assertEqual(len(inventory['rows']), 2)
        self.assertEqual(payload['catalog_rows'], self.payload['catalog_rows'])

    def test_guarded_catalog_missing_malformed_and_empty_remain_distinct(self):
        for catalog, state, code in ((None, 'unavailable', 'catalog_unavailable'),
                                     ({'table_name': 'BIOBANK_SAMPLES'}, 'unavailable', 'catalog_malformed'),
                                     ([], 'present', None)):
            with self.subTest(state=state, code=code):
                self.payload['catalog_rows'] = catalog
                self.write_input()
                build(self.input, self.output, self.project)
                inventory = load_payload(self.output / 'DALYCARE_atlas_payload.json')['clinical_source_inventory']
                self.assertEqual(inventory['inventory_state'], state)
                self.assertEqual(inventory['rows'], [])
                self.assertEqual(inventory['diagnostics'], [] if code is None else [dict(code=code, source_key=None, membership_id=None)])

    def test_matching_csv_catalog_never_replaces_snapshot_membership_basis_or_evidence(self):
        run = self.base / 'run'
        (run / 'outputs').mkdir(parents=True)
        (run / 'outputs/atlas_run_summary.csv').write_text('metric,value\nrun_id,synthetic-membership-run\n', encoding='utf-8')
        registry = json.loads((self.project / 'inst/config/public-output-registry.json').read_text())
        spec = next(s for s in registry['artifacts'] if s['id'] == 'atlas_resource_catalog')
        schema = spec['schemas'][0]
        import csv
        csv_path = run / spec['source_file']
        csv_path.parent.mkdir(parents=True, exist_ok=True)
        with csv_path.open('w', newline='', encoding='utf-8') as handle:
            writer = csv.DictWriter(handle, fieldnames=list(schema))
            writer.writeheader()
            writer.writerow({k: 'RKKP_CLL' if k == 'table_name' else '100' if schema[k] == 'number' else '' for k in schema})
        csv_before = csv_path.read_bytes()
        expected_tables = collect_output_evidence(run, self.project, self.payload)
        build(self.input, self.output, self.project, run)
        payload = load_payload(self.output / 'DALYCARE_atlas_payload.json')
        self.assertTrue('clinical_source_inventory' in payload, 'Imported membership overlay is missing')
        self.assertEqual([r['source_key'] for r in payload['clinical_source_inventory']['rows']], ['BIOBANK_SAMPLES', 'LAB_BIOBANK_SAMPLES'])
        self.assertEqual(payload['catalog_rows'], self.payload['catalog_rows'])
        self.assertEqual(csv_path.read_bytes(), csv_before)
        self.assertEqual(published_tables(self.output), expected_tables)


if __name__ == '__main__':
    unittest.main()
