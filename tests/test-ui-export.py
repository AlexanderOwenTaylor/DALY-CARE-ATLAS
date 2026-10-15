"""Portable synthetic builder checks plus opt-in local export regressions."""
import csv
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from build_ui_iteration import build
from public_privacy import audit_public_payload
from site_bundle import decode_transport
from runtime_fixture import public_rows

EXPORT_ENV = {
    'original': 'DALYCARE_TEST_ORIGINAL_EXPORT',
    'updated': 'DALYCARE_TEST_UPDATED_EXPORT',
    'iteration5': 'DALYCARE_TEST_ITERATION5_EXPORT',
    'iteration7': 'DALYCARE_TEST_ITERATION7_EXPORT',
}


def load_js(path):
    prefix = 'window.DALYCARE_ATLAS_PAYLOAD ='
    raw = path.read_text(encoding='utf-8-sig').strip()
    assert raw.startswith(prefix)
    return decode_transport(json.loads(raw[len(prefix):].strip().removesuffix(';')))


def supplied_exports():
    """Validate every supplied path before considering any optional skip."""
    exports = {}
    for name, env in EXPORT_ENV.items():
        if os.environ.get(env):
            directory = Path(os.environ[env])
            data = load_js(directory / 'DALYCARE_atlas_payload.js')
            if not isinstance(data, dict):
                raise ValueError(f'{env} must contain a payload object')
            if name == 'updated' and audit_public_payload(data):
                raise ValueError(f'{env} fails the public privacy audit')
            json_path = directory / 'DALYCARE_atlas_payload.json'
            if json_path.exists() or name == 'updated':
                json_data = decode_transport(json.loads(json_path.read_text(encoding='utf-8-sig')))
                if json_data != data:
                    raise ValueError(f'{env} has different JS and JSON payloads')
            exports[name] = (directory, data)
    return exports


class SyntheticBuilderTest(unittest.TestCase):
    def setUp(self):
        policy = patch.dict(os.environ, {'DALYCARE_MIN_CELL_COUNT':'5'})
        policy.start(); self.addCleanup(policy.stop)
        self.temp = tempfile.TemporaryDirectory(prefix='dalycare-synthetic-export-')
        self.addCleanup(self.temp.cleanup)
        self.input = Path(self.temp.name) / 'input'
        self.output = Path(self.temp.name) / 'output'
        self.input.mkdir()
        # Deliberately invented statistics and forbidden strings, never real data.
        numeric = dict(table_name='RKKP_CLL', column_name='Reg_Leukocyttal',
            profile_kind='numeric', n_rows=100, n_available=80, n_missing=20,
            pct_available=80, pct_missing=20, n_distinct_capped=20,
            min=0, max=987654.125, mean=0, median=0, p25=0, p75=10)
        self.payload = {
            'fixture_notice': 'SYNTHETIC TEST DATA; not a dataset export',
            'column_profile_rows': [numeric,
                dict(numeric, column_name='synthetic_small', n_available=99, n_missing=1),
                dict(numeric, column_name='ClinicalDate', profile_kind='date', min_date='1927-02-03', max_date='2099-01-01')],
            'column_top_value_rows': [{'table_name':'T', 'column_name':'report_text',
                'value':'SYNTHETIC_FORBIDDEN_NAME', 'n':20}],
            'panels': {'mm_treatment_code_counts': [{'code_column':'DrugCode', 'code':'SYNTHETIC_FORBIDDEN_UUID', 'n_rows':20}]},
            'npu_display_dictionary': [{'code':'SYNTHETIC_OBSOLETE_DICTIONARY'}],
            'clinical_display_dictionary': [{'code':'SYNTHETIC_OBSOLETE_DICTIONARY'}],
        }

    def write_input(self, raw=None):
        (self.input / 'DALYCARE_atlas_payload.js').write_text(
            raw if raw is not None else 'window.DALYCARE_ATLAS_PAYLOAD = ' + json.dumps(self.payload) + ';',
            encoding='utf-8')

    def run_cli(self, arguments):
        # Use the real CLI in an isolated public-only project so a regression to
        # sibling output defaults cannot overwrite a developer's local export.
        project = Path(self.temp.name) / 'cli-project'
        from runtime_fixture import copy_runtime_fixture
        copy_runtime_fixture(ROOT,project)
        return subprocess.run([sys.executable, str(project / 'scripts/build_ui_iteration.py'), *arguments],
                              cwd=self.temp.name, text=True, capture_output=True)

    def test_builder_cli_requires_both_explicit_directories_before_reading_input(self):
        for arguments, missing in (([], ('--input-dir', '--output-dir')),
                                   (['--input-dir', str(self.input)], ('--output-dir',)),
                                   (['--output-dir', str(self.output)], ('--input-dir',))):
            with self.subTest(arguments=arguments):
                result = self.run_cli(arguments)
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn('usage:', result.stderr)
                self.assertIn('required', result.stderr)
                for option in missing:
                    self.assertIn(option, result.stderr)
                self.assertNotIn('Traceback', result.stderr)
                self.assertFalse(self.output.exists())
                self.assertFalse((Path(self.temp.name) / 'atlas-iteration-9').exists())
                self.assertEqual(list(Path(self.temp.name).rglob('DALYCARE_atlas_payload.json')), [])

    def test_builder_cli_builds_explicit_synthetic_input_and_output(self):
        self.write_input()
        result = self.run_cli(['--input-dir', str(self.input), '--output-dir', str(self.output)])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Built ', result.stdout)
        raw = (self.output / 'DALYCARE_atlas_payload.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';')
        self.assertEqual(json.loads(raw), json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8')))
        self.assertEqual(json.loads(raw)['transport_version'], 2)
        data = load_js(self.output / 'DALYCARE_atlas_payload.js')
        self.assertEqual(data, decode_transport(json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8'))))
        self.assertTrue(data['synthetic_validation'])
        self.assertEqual(audit_public_payload(data), [])
        self.assertEqual((self.output / 'DALYCARE_atlas.html').read_bytes(),
                         (ROOT / 'inst/templates/DALYCARE_entry.html').read_bytes())

    def test_builder_cli_can_publish_requested_v1(self):
        self.write_input()
        result = self.run_cli(['--input-dir', str(self.input), '--output-dir', str(self.output), '--transport-version', '1'])
        self.assertEqual(result.returncode, 0, result.stderr)
        wire = json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8'))
        self.assertEqual(wire['transport_version'], 1)
        self.assertEqual(load_js(self.output / 'DALYCARE_atlas_payload.js'), decode_transport(wire))
        self.assertEqual(audit_public_payload(decode_transport(wire)), [])

    def test_build_emits_offline_html_and_identical_json_and_script(self):
        self.write_input()
        build(self.input, self.output, ROOT)
        raw = (self.output / 'DALYCARE_atlas_payload.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';')
        self.assertEqual(json.loads(raw), json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8')))
        data = load_js(self.output / 'DALYCARE_atlas_payload.js')
        self.assertEqual(data, decode_transport(json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8'))))
        self.assertEqual((self.output / 'DALYCARE_atlas.html').read_bytes(),
                         (ROOT / 'inst/templates/DALYCARE_entry.html').read_bytes())
        self.assertIn('DALYCARE_search.js', (self.output / 'DALYCARE_clinical.html').read_text(encoding='utf-8'))
        self.assertNotIn('DALYCARE_atlas_payload.js', (self.output / 'DALYCARE_clinical.html').read_text(encoding='utf-8'))
        self.assertTrue(data['synthetic_validation'])

    def test_builder_preserves_committed_public_dictionary_identity(self):
        self.write_input()
        build(self.input, self.output, ROOT)
        raw = (self.output / 'DALYCARE_atlas_payload.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';')
        self.assertEqual(json.loads(raw), json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8')))
        data = load_js(self.output / 'DALYCARE_atlas_payload.js')
        for key, filename in [('npu_display_dictionary','npu-display-dictionary.csv'),
                              ('clinical_display_dictionary','clinical-display-dictionary.csv')]:
            with (ROOT / 'config' / filename).open(encoding='utf-8-sig', newline='') as stream:
                self.assertEqual([{k:'' if v is None else v for k,v in r.items()} for r in public_rows(self.output,key)],list(csv.DictReader(stream)))
        self.assertNotIn('SYNTHETIC_OBSOLETE_DICTIONARY', json.dumps(data))

    def test_builder_enforces_privacy_and_preserves_eligible_zero(self):
        self.write_input()
        build(self.input, self.output, ROOT)
        raw = (self.output / 'DALYCARE_atlas_payload.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';')
        self.assertEqual(json.loads(raw), json.loads((self.output / 'DALYCARE_atlas_payload.json').read_text(encoding='utf-8')))
        data = load_js(self.output / 'DALYCARE_atlas_payload.js')
        self.assertEqual(audit_public_payload(data), [])
        self.assertGreaterEqual(data['privacy_metadata']['minimum_cell_count'], 5)
        eligible, small, date = public_rows(self.output,'column_profiles')
        self.assertEqual(eligible['numeric_privacy_status'], 'needs_verified_grouped_evidence')
        self.assertEqual([eligible[k] for k in ('mean','median','p25','p75')], [None]*4)
        self.assertEqual([eligible[k] for k in ('n_available','n_missing')], [80,20])
        self.assertIsNone(eligible['min']); self.assertIsNone(eligible['max'])
        self.assertEqual(small['availability_privacy_status'], 'withheld_small_complementary_cells')
        for key in ('n_available','n_missing','pct_available','pct_missing','mean','median','p25','p75'):
            self.assertIsNone(small[key])
        self.assertIsNone(date['min_date']); self.assertIsNone(date['max_date'])
        self.assertIsNone(public_rows(self.output,'mm_treatment_code_counts')[0]['code'])
        for forbidden in ('SYNTHETIC_FORBIDDEN_NAME','SYNTHETIC_FORBIDDEN_UUID','1927-02-03','987654.125'):
            for path in self.output.rglob('*'):
                if path.is_file(): self.assertNotIn(forbidden,path.read_text(encoding='utf-8'))

    def test_builder_rejects_malformed_inputs_before_publishing(self):
        for raw in ('wrong wrapper', 'window.DALYCARE_ATLAS_PAYLOAD = {broken};',
                    'window.DALYCARE_ATLAS_PAYLOAD = [];'):
            with self.subTest(raw=raw):
                self.write_input(raw)
                with self.assertRaises((ValueError, TypeError)):
                    build(self.input, self.output, ROOT)
                self.assertFalse(self.output.exists())

    def test_builder_fails_closed_when_sanitized_payload_is_unsafe(self):
        self.write_input()
        # Exercise the independent post-sanitization audit gate using a faulty
        # sanitizer result; the real audit and builder still execute.
        with patch('build_ui_iteration.sanitize_public_payload', return_value={
                'privacy_metadata':{}, 'display_metadata':{}, 'column_profile_rows':[{'min_date':'1927-02-03'}]}):
            with self.assertRaisesRegex(ValueError, 'Public privacy audit failed'):
                build(self.input, self.output, ROOT)
        self.assertFalse(self.output.exists())

    def test_explicit_invalid_optional_export_does_not_silently_skip(self):
        for raw in ('wrong wrapper', 'window.DALYCARE_ATLAS_PAYLOAD = {broken};',
                    'window.DALYCARE_ATLAS_PAYLOAD = {"column_profile_rows":[{"min_date":"1927-02-03"}]};'):
            with self.subTest(raw=raw):
                self.write_input(raw)
                with patch.dict(os.environ, {env:'' for env in EXPORT_ENV.values()}):
                    os.environ[EXPORT_ENV['updated']] = str(self.input)
                    with self.assertRaises((AssertionError, ValueError)):
                        supplied_exports()
        self.write_input('window.DALYCARE_ATLAS_PAYLOAD = {};')
        with patch.dict(os.environ, {env:'' for env in EXPORT_ENV.values()}):
            os.environ[EXPORT_ENV['updated']] = str(self.input / 'missing')
            with self.assertRaises(FileNotFoundError):
                supplied_exports()
            os.environ[EXPORT_ENV['updated']] = str(self.input)
            (self.input / 'DALYCARE_atlas_payload.json').write_text('{broken}', encoding='utf-8')
            with self.assertRaises(ValueError):
                supplied_exports()
            (self.input / 'DALYCARE_atlas_payload.json').write_text('{"different":true}', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'different JS and JSON'):
                supplied_exports()


class AtlasExportTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.exports = supplied_exports()
        if not all(key in cls.exports for key in ('original','updated')):
            raise unittest.SkipTest('Optional local regression: set DALYCARE_TEST_ORIGINAL_EXPORT and DALYCARE_TEST_UPDATED_EXPORT to export directories')
        cls.original = cls.exports['original'][1]
        cls.updated = cls.exports['updated'][1]

    def previous(self, name):
        if name not in self.exports:
            self.skipTest(f'Optional comparison requires {EXPORT_ENV[name]} export directory')
        return self.exports[name][1]

    def test_public_privacy_invariants_and_reference_preservation(self):
        previous = self.previous('iteration7')
        for key in ('npu_display_dictionary','clinical_display_dictionary'):
            self.assertEqual(previous[key],self.updated[key])
        self.assertEqual(len(self.original['column_profile_rows']),len(self.updated['column_profile_rows']))
        self.assertGreaterEqual(self.updated['privacy_metadata']['minimum_cell_count'],5)
        def visit(obj):
            if isinstance(obj,list):
                for row in obj: visit(row)
            elif isinstance(obj,dict):
                for key,value in obj.items():
                    if key in ('npu_display_dictionary','clinical_display_dictionary'): continue
                    if key in ('min','max','min_date','max_date','raw_min_date','raw_max_date','date_range'):
                        self.assertIn(value,(None,''))
                    if key in ('mean','median','p25','p75') and value not in (None,''):
                        self.assertEqual(obj.get('numeric_privacy_status'),'eligible_stored_summary')
                        self.assertGreaterEqual(float(obj['n_available']),5)
                    visit(value)
        visit(self.updated)

    def test_offline_script_and_json_have_identical_data(self):
        with (self.exports['updated'][0] / 'DALYCARE_atlas_payload.json').open(encoding='utf-8') as stream:
            self.assertEqual(self.updated, decode_transport(json.load(stream)))

    def test_exact_terminology_coverage_and_known_corrections(self):
        dictionary = {row['code']: row for row in self.updated['npu_display_dictionary']}
        codes = {row['lab_code'] for row in self.original['panels']['lab_npu_code_coverage']}
        self.assertEqual(len(codes), 250)
        self.assertEqual(codes - dictionary.keys(), set())
        self.assertEqual(dictionary['NPU17597']['status'], 'historical_reference')
        self.assertEqual(dictionary['NPU17597']['label'], 'Naked nuclei in blood')
        self.assertIn('publications.iupac.org', dictionary['NPU17597']['source_url'])
        self.assertEqual(dictionary['NPU02593']['label'], 'Leukocytes')
        self.assertEqual(dictionary['NPU04998']['label'], 'Creatinine')
        self.assertEqual(dictionary['NPU19748']['label'], 'C-reactive protein (CRP)')
        self.assertEqual(dictionary['NPU02636']['label'], 'Lymphocytes')

    def test_all_observed_treatment_codes_and_lab_groups_have_exact_names(self):
        entries = self.updated['clinical_display_dictionary']
        keys = {(r['kind'], r['system'], r['code']) for r in entries}
        self.assertEqual(len(keys), len(entries))
        for row in self.original['panels']['mm_treatment_code_counts']:
            self.assertIn(('code', row['code_system'], row['code']), keys)
        for row in self.original['panels']['npu_dictionary_vectors']:
            self.assertIn(('laboratory_group', 'Atlas', row['consensus_vector']), keys)
        for code in ['NK', 'MF/SZ', 'HD-LP', 'PCTCL']:
            self.assertNotIn(('registry_value', 'RKKP_LYFO:subtype', code), keys)

    def test_verified_drug_corrections_and_historical_codes(self):
        entries = {(r['system'],r['code']):r for r in self.updated['clinical_display_dictionary'] if r['kind']=='code'}
        for system,code,label in [('SKS','BWHA169','Treatment with vinblastine'),('ATC','L01XK02','Niraparib'),('ATC','L01XC15','Obinutuzumab'),('SKS','BWGC1','Conventional external beam radiotherapy')]:
            self.assertEqual(entries[system,code]['label'],label)
        self.assertIn('L01EL01 in 2021',entries['ATC','L01XE27']['note'])
        self.assertIn('IMRT',entries['SKS','BWGC4A']['label'])
        for system,code,label in [('PATOBANK','M97323','Multiple myeloma morphology code'),('PATOBANK','P28260','Bone marrow examination'),('SKS','UXZ10','With intravenous contrast'),('SKS','UXZ11','Without intravenous contrast')]:
            self.assertEqual(entries[system,code]['label'],label)

    def test_pathology_definitions_preserve_zero_and_original_count_rows(self):
        entries = {r['code']:r for r in self.updated['clinical_display_dictionary'] if r['system']=='PATOBANK'}
        for row in self.original['patobank_ki67_percent']['code_counts']:
            self.assertEqual(entries[row['canonical_code']]['label'],f"Ki-67 index: {int(row['parsed_percent'])}%")
        self.assertEqual(entries['AEKI000']['label'],'Ki-67 index: 0%')
        self.assertNotIn('AEKI101',entries)

    def test_added_field_names_are_exact_exported_source_fields(self):
        previous = self.previous('iteration5')
        previous_keys = {(r['system'],r['code']) for r in previous['clinical_display_dictionary'] if r['kind']=='field'}
        exported = {(r['table_name'],r['column_name']) for r in self.original['column_profile_rows']}
        for row in self.updated['clinical_display_dictionary']:
            key = row['system'],row['code']
            if row['kind']=='field' and key not in previous_keys:
                self.assertIn(key,exported)

    def test_iteration5_names_preserve_code_identity_and_treatment_stage(self):
        entries = {(r['kind'],r['system'],r['code']):r for r in self.updated['clinical_display_dictionary']}
        expected = [('SKS','APAA4','Hospital physician'),('SKS','UXCD10','CT of upper abdomen'),('SKS','UXCD15','CT of lower abdomen, including pelvis'),('SKS','UXCA00','CT of cerebrum'),('ATC','L01EL01','Ibrutinib'),('ATC','L01FA01','Rituximab'),('ATC','L01FA03','Obinutuzumab'),('ATC','L01XG01','Bortezomib'),('ATC','L01XG02','Carfilzomib')]
        for system,code,label in expected:
            self.assertEqual(entries['code',system,code]['label'],label)
            self.assertTrue(entries['code',system,code]['source_url'].startswith('https://'))
        stages = [('Reg_PlanlagtBeh','Planned'),('PB_Behandling','Primary'),('SB_Behandling','Secondary'),('FU_Behandling','Follow-up'),('PB_VedligeholdBeh','Maintenance')]
        for prefix,stage in stages:
            entry=entries['field','RKKP_DaMyDa',prefix+'_Bortezomib']
            self.assertEqual(entry['label'],stage+' treatment: Bortezomib')
            self.assertIn('not a medication administration record',entry['definition'])
        for term in ['ISS','R-ISS','CR','sCR','PR','VGPR','SD','PD','ORR','PFS','OS','DEXA/DXA','CNS','IPI','aaIPI','FLIPI','FLIPI2','IPS']:
            self.assertTrue(entries['term','Glossary',term]['source_url'].startswith('https://'))

    def test_iteration6_molecular_names_and_previous_definitions_are_preserved(self):
        entries = {(r['kind'],r['system'],r['code']):r for r in self.updated['clinical_display_dictionary']}
        previous = self.previous('iteration5')
        for row in previous['clinical_display_dictionary']:
            self.assertEqual(entries[row['kind'],row['system'],row['code']],row)
        self.assertEqual(entries['gene','Gene symbol','TP53']['label'],'tumor protein p53')
        self.assertEqual(entries['gene','Gene symbol','MYD88']['label'],'MYD88 innate immune signal transduction adaptor')
        for code in ['TP53','ATM','NOTCH1','SF3B1','BIRC3','MYD88','BRAF','KRAS','NRAS','XPO1','POT1']:
            row=entries['field','CLLPANEL_WIDE',code]
            self.assertIn('Field presence alone does not establish',row['definition'])
            self.assertIn('ncbi.nlm.nih.gov',row['source_url'])
        self.assertNotIn(('field','CLLPANEL_WIDE','PLCG2'),entries)
        for term in ['PCR','MIC','MRSA','VRE','ESBL','CMV','EBV','HIV','HCV','HBsAg','anti-HBc','ICU','ADT','CLL-IPI','CIRS']:
            self.assertTrue(entries['term','Glossary',term]['source_url'].startswith('https://'))
        for source,code in [('SP_AlleProvesvar','ord_value'),('SDS_lab_forsker','value')]:
            self.assertEqual(entries['field',source,code]['label'],'Recorded laboratory result')


if __name__ == '__main__':
    unittest.main()
