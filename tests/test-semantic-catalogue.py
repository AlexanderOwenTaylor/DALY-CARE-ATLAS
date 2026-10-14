import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))


class CatalogueTest(unittest.TestCase):
    def test_saved_descriptor_is_an_unassessed_definition(self):
        from semantic_catalogue import rebuild_semantics
        saved=dict(source_name='S',raw_column='name',value_column='result',raw_descriptor='Puls',evidence_filter='"name" = \'Puls\'',
            data_shape='long_descriptor_table',semantic_id='saved_pulse',clinical_concept_id='pulse',clinical_variable='Pulse',n_rows=25,n_patients=20)
        payload=dict(column_profile_rows=[dict(table_name='S',column_name=x) for x in ('name','result')],semantic_dictionary_rows=[saved])
        rebuild_semantics(payload,ROOT)
        row=next(r for r in payload['semantic_dictionary_rows'] if r['semantic_id']=='saved_pulse')
        self.assertEqual(row['mapping_status'],'saved_definition_inventory_unassessed')
        self.assertIsNone(row['n_rows'])
        self.assertIsNone(row['n_patients'])

    def test_partial_routes_and_stale_dependencies(self):
        from semantic_catalogue import rebuild_semantics, exact_id
        columns=[dict(table_name='S',column_name=x) for x in ('name','result_a','result_b','new_field')]
        old=dict(source_name='S',raw_column='name',value_column='result_a',raw_descriptor='Puls',evidence_filter='"name" = \'Puls\'',
            data_shape='long_descriptor_table',semantic_id='descriptor_a',clinical_concept_id='pulse',clinical_variable='Pulse')
        stale={**old,'source_name':'OLD','semantic_id':'stale','clinical_concept_id':'stale'}
        payload=dict(column_profile_rows=columns,semantic_dictionary_rows=[old,stale],
            semantic_panel_links=[dict(semantic_id='descriptor_a',clinical_concept_id='pulse',panel_id='custom'),dict(semantic_id='stale',clinical_concept_id='stale',panel_id='custom')],
            panel_raw_field_rows=[dict(semantic_id='descriptor_a',source_name='S',raw_column='name',clinical_variable='Preserved route'),dict(semantic_id='stale',source_name='OLD')],
            clinical_concept_rows=[dict(clinical_concept_id='pulse',purpose='Preserved current purpose'),dict(clinical_concept_id='stale')])
        rebuild_semantics(payload,ROOT)
        ids={r['semantic_id'] for r in payload['semantic_dictionary_rows']}
        self.assertEqual(len(ids),5,'Descriptor and generic name-column metadata are distinct identities')
        self.assertIn(exact_id('S','name'),ids)
        self.assertEqual({r['semantic_id'] for r in payload['semantic_panel_links']},ids)
        self.assertEqual({r['semantic_id'] for r in payload['panel_raw_field_rows']},ids)
        routes={r['semantic_id']:r for r in payload['panel_raw_field_rows']}
        self.assertEqual(routes['descriptor_a']['value_column'],'result_a')
        self.assertEqual(routes['descriptor_a']['clinical_variable'],'Preserved route')
        concepts={r['clinical_concept_id']:r for r in payload['clinical_concept_rows']}
        self.assertNotIn('stale',concepts)
        self.assertIn(exact_id('S','new_field'),concepts)
        self.assertEqual(concepts['pulse']['purpose'],'Preserved current purpose')

    def test_current_catalogue_offline(self):
        from semantic_catalogue import rebuild_semantics, validate_terminology
        validate_terminology(ROOT)
        columns = [dict(table_name='RKKP_DaMyDa',column_name='Reg_Haemoglobin'),dict(table_name='Ø.X',column_name='patientid'),dict(table_name='Ø.X',column_name='mystery')]
        payload = dict(column_profile_rows=columns,semantic_dictionary_rows=[])
        rebuild_semantics(payload,ROOT)
        rows = payload['semantic_dictionary_rows']
        self.assertEqual(len(rows),3)
        self.assertEqual(rows[0]['clinical_variable'],'Haemoglobin')
        self.assertEqual(rows[2]['semantic_meaning'],'Description unavailable')
        self.assertTrue(all(not r['unit'] and r['n_patients'] is None for r in rows))
        rows[0]['semantic_meaning']='Reviewed current interpretation'
        rebuild_semantics(payload,ROOT)
        self.assertEqual(payload['semantic_dictionary_rows'][0]['semantic_meaning'],'Reviewed current interpretation')

    def test_pins_and_reproducible_import(self):
        from semantic_catalogue import validate_terminology
        from import_npu_release import generate
        import gzip
        source = ROOT/'config/terminology/ifcc-npu-retrieved-2026-10-14/official.csv.gz'
        with tempfile.TemporaryDirectory() as tmp:
            tmp=Path(tmp);(tmp/'config').mkdir()
            reviewed=ROOT/'config/terminology/ifcc-npu-retrieved-2026-10-14/reviewed-display-labels.csv'
            (tmp/'config/npu-display-dictionary.csv').write_bytes(reviewed.read_bytes())
            raw=tmp/'official.csv';raw.write_bytes(gzip.decompress(source.read_bytes()))
            generate(raw,tmp)
            self.assertEqual((tmp/'config/npu-display-dictionary.csv').read_bytes(),(ROOT/'config/npu-display-dictionary.csv').read_bytes())
            validate_terminology(tmp)
            path=tmp/'config/npu-display-dictionary.csv'
            path.write_bytes(b'X'+path.read_bytes()[1:])
            with self.assertRaises(ValueError):validate_terminology(tmp)
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):validate_terminology(Path(tmp))


if __name__=='__main__':unittest.main()
