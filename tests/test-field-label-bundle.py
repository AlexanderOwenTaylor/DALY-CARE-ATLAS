"""The emitted catalogue must use the guarded published dictionary exactly."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from output_evidence import collect_output_evidence
from site_bundle import write_site_bundle

FIXTURE = json.loads((ROOT / 'tests/fixtures/site-field-labels.json').read_text(encoding='utf-8'))
TEMP = ROOT.parent / '.artifact-temp/iteration17-team'
TEMP.mkdir(parents=True, exist_ok=True)


def catalogue(paths):
    return json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=', 1)[1].strip().removesuffix(';'))


class FieldLabelBundleTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='python-labels-', dir=TEMP)
        self.addCleanup(self.tmp.cleanup)
        self.out = Path(self.tmp.name) / 'site'
        self.dictionary = next(t for t in collect_output_evidence(None, ROOT, {}) if t['id'] == 'clinical_display_dictionary')

    def publish(self, rows, *, payload=None):
        table = copy.deepcopy(self.dictionary)
        table['rows'] = copy.deepcopy(rows)
        return write_site_bundle(self.out, payload or {'run_id': 'field-labels'}, [table], ROOT, 'legacy_payload')

    def test_emitted_exact_labels_come_from_published_dictionary_not_stale_payload(self):
        paths = self.publish(FIXTURE['valid'], payload={'run_id': 'field-labels', 'clinical_display_dictionary': [
            {'kind': 'field', 'system': 'SDS_t_biobank', 'code': 'SampleType', 'label': 'Stale copied label'}]})
        cat = catalogue(paths)
        self.assertEqual(cat.get('field_labels'), FIXTURE['expected'])
        self.assertNotIn('IPI', cat['field_labels']['RKKP_LYFO'])
        self.assertNotIn('SDS_t_udtilsgh', cat['field_labels'])
        self.assertEqual(cat['tables'][0]['provenance'], 'project_reference')
        emitted = []
        for shard in cat['tables'][0]['shards']:
            registration = json.loads((self.out / shard['src']).read_text(encoding='utf-8').split('register(', 1)[1].removesuffix(');\n'))
            emitted.extend(json.loads(registration['rows_json']))
        self.assertEqual([(r['kind'], r['system'], r['code'], r['label']) for r in emitted],
                         [(r['kind'], r['system'], r['code'], r['label']) for r in FIXTURE['valid']])
        self.assertEqual(emitted[0]['source_url'], 'https://example.test/reviewed')
        self.assertEqual(emitted[0]['retrieved_on'], '2026-10-11')

    def test_absent_empty_and_nonfield_dictionary_omit_optional_map(self):
        for payload in ({'run_id': 'absent'}, {'clinical_display_dictionary': []},
                        {'clinical_display_dictionary_alias': FIXTURE['valid']}):
            with self.subTest(payload=payload):
                paths = write_site_bundle(self.out, payload, [], ROOT, 'legacy_payload')
                self.assertNotIn('field_labels', catalogue(paths))
        for rows in ([], FIXTURE['excluded']):
            self.assertNotIn('field_labels', catalogue(self.publish(rows)))

    def test_qualifying_payload_dictionary_works_without_descriptor(self):
        paths = write_site_bundle(self.out, {'clinical_display_dictionary': FIXTURE['valid']}, [], ROOT, 'legacy_payload')
        self.assertEqual(catalogue(paths).get('field_labels'), FIXTURE['expected'])

    def test_conflicting_invalid_and_prototype_rows_fail_preserving_site_and_manifest(self):
        paths = self.publish(FIXTURE['valid'])
        prior = {p: p.read_bytes() for p in paths['assets'] + [paths['manifest']]}
        cases = [('conflicting pair', FIXTURE['conflict'])] + [(str(i), [row]) for i, row in enumerate(FIXTURE['invalid'])]
        for name, rows in cases:
            with self.subTest(case=name):
                with self.assertRaisesRegex(ValueError, '(?i)field.label'):
                    self.publish(rows)
                self.assertEqual(prior, {p: p.read_bytes() for p in prior})

    def test_label_metadata_obeys_initial_library_ceiling_and_rolls_back(self):
        paths = self.publish(FIXTURE['valid'])
        prior = {p: p.read_bytes() for p in paths['assets'] + [paths['manifest']]}
        rows = [{'kind': 'field', 'system': 'Source', 'code': 'field' + str(i), 'label': 'x' * 1000} for i in range(600)]
        with self.assertRaisesRegex(ValueError, 'Initial asset byte budget exceeded'):
            self.publish(rows)
        self.assertEqual(prior, {p: p.read_bytes() for p in prior})


if __name__ == '__main__':
    unittest.main()
