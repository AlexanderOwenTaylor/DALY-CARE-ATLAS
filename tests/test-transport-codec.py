"""Synthetic lossless transport contract and local graph boundaries."""
import copy
import json
import math
import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import site_bundle as b

CONTRACT = json.loads((ROOT / 'tests/fixtures/transport-v2-contract.json').read_text(encoding='utf-8'))


def at(value, path):
    for key in path:
        value = value[key]
    return value


class CodecTests(unittest.TestCase):
    def test_frozen_valid_cases_and_exact_budgets(self):
        for case in CONTRACT['valid_decodes']:
            with self.subTest(case=case['id']):
                wire = copy.deepcopy(case['wire'])
                before = copy.deepcopy(wire)
                decoded = b.decode_transport(wire, max_bytes=case['minimum_decode_budget'])
                self.assertEqual(decoded, case['logical'])
                self.assertEqual(wire, before)
                self.assertIs(decoded.get('untouched'), wire['payload'].get('untouched'))
                for left, right in case.get('identity_paths', []):
                    self.assertIs(at(decoded, left), at(decoded, right))
                self.assertEqual(b.normalized_size(wire), case['encoded_charge'])
                with self.assertRaises(ValueError):
                    b.decode_transport(wire, max_bytes=case['minimum_decode_budget'] - 1)

    def test_frozen_invalid_cases_are_transactional(self):
        for case in CONTRACT['invalid_decodes']:
            with self.subTest(case=case['id']):
                wire = copy.deepcopy(case['wire'])
                before = copy.deepcopy(wire)
                with self.assertRaises(ValueError):
                    b.decode_transport(wire)
                self.assertEqual(wire, before)

    def test_shared_normalized_charges(self):
        for case in CONTRACT['normalized_charges']:
            with self.subTest(value=repr(case['value'])):
                self.assertEqual(b.normalized_size(case['value']), case['charge'])
                self.assertEqual(b.normalized_size(case['value'], case['charge']), case['charge'])
                with self.assertRaises(ValueError):
                    b.normalized_size(case['value'], case['charge'] - 1)

    def test_packing_preserves_rows_order_types_and_aliases(self):
        original = copy.deepcopy(CONTRACT['encoder_payload'])
        before = copy.deepcopy(original)
        wire = b.encode_transport(original)
        self.assertEqual(wire['transport_version'], 2)
        self.assertEqual(set(wire), {'transport_version', 'payload', 'aliases', 'row_tables'})
        self.assertEqual([t['path'] for t in wire['row_tables']], CONTRACT['must_pack_paths'])
        decoded = b.decode_transport(wire)
        self.assertEqual(b.compact(decoded), b.compact(original))
        self.assertIs(decoded['catalog_rows'], decoded['review_infrastructure_sections']['catalog'])
        self.assertEqual(original, before)
        for path in CONTRACT['must_remain_verbatim_paths']:
            self.assertEqual(at(wire['payload'], path), at(original, path))
        self.assertLess(len(b.compact(wire).encode()), len(b.compact(b.encode_transport(original, 1)).encode()))
        self.assertEqual(b.compact(wire), b.compact(b.encode_transport(original)))

    def test_configuration_precedence_is_public_only(self):
        for case in CONTRACT['configuration_cases']:
            with self.subTest(case=case['id']), patch.dict(os.environ, {}, clear=False):
                os.environ.pop('DALYCARE_ATLAS_TRANSPORT_VERSION', None)
                if case['environment'] is not None:
                    os.environ['DALYCARE_ATLAS_TRANSPORT_VERSION'] = case['environment']
                if case.get('error'):
                    with self.assertRaises(ValueError):
                        b.resolve_transport_version(case['explicit'])
                else:
                    self.assertEqual(b.resolve_transport_version(case['explicit']), case['expect'])
        with patch.dict(os.environ, {'DALYCARE_ATLAS_TRANSPORT_VERSION': 'invalid'}):
            self.assertEqual(b.encode_transport({})['transport_version'], 2)

    def test_graph_numbers_unicode_and_depth(self):
        wire = {'transport_version': 2, 'payload': {}, 'aliases': [], 'row_tables': []}
        cycle = {}; cycle['self'] = cycle
        for bad in (cycle, {'x': math.inf}, {'x': math.nan}, {'x': 10 ** 400}, {'x': '\ud800'}, {'x': (1, 2)}, {1: 'x'}):
            with self.subTest(bad_type=type(bad)):
                candidate = dict(wire, payload=bad)
                with self.assertRaises(ValueError):
                    b.decode_transport(candidate)
                with self.assertRaises(ValueError):
                    b.encode_transport(bad)
        large = 10 ** 308
        self.assertEqual(b.decode_transport(b.encode_transport({'n': large}))['n'], large)
        shared = {'n': 1}
        self.assertEqual(b.normalized_size([shared, shared]), 79)
        exact = None
        for _ in range(128):
            exact = [exact]
        self.assertGreater(b.normalized_size(exact), 0)
        with self.assertRaises(ValueError):
            b.normalized_size([exact])

    def test_legacy_and_v1_reads_keep_existing_limit_semantics(self):
        legacy = {'untouched': {'__proto__': 'data'}, 'n': math.inf}
        self.assertIs(b.decode_transport(legacy, max_bytes=1), legacy)
        v1 = {'transport_version': 1, 'payload': {'rows': ['long']}, 'aliases': []}
        self.assertEqual(b.decode_transport(v1, max_bytes=1), v1['payload'])

    def test_work_limits_fallback_does_not_consume_or_truncate(self):
        many = [{'long_repeated_synthetic_key': i} for i in range(10)]
        small = many[:4]
        payload = {'too_large': many, 'small': small, 'later': small}
        with patch.dict(b.WORK_LIMITS, {'rows': 4}):
            wire = b.encode_transport(payload)
            self.assertEqual([t['path'] for t in wire['row_tables']], [['small']])
            self.assertEqual(wire['payload']['too_large'], many)
            self.assertEqual(wire['payload']['later'], small)
            self.assertEqual(b.decode_transport(wire), payload)
            oversized = b.encode_transport({'many': many}, 1)
            oversized.update(transport_version=2, row_tables=[{'path':['many'], 'schemas':[['long_repeated_synthetic_key']], 'rows':[[0, i] for i in range(10)]}])
            oversized['payload']['many'] = None
            with self.assertRaises(ValueError):
                b.decode_transport(oversized)

    def test_shared_encoder_subtrees_preserve_each_serialized_occurrence(self):
        branch = {'rows': [{'long_repeated_synthetic_key': i} for i in range(10)]}
        payload = {'left': branch, 'right': branch}
        wire = b.encode_transport(payload)
        self.assertEqual([t['path'] for t in wire['row_tables']], [['left','rows'], ['right','rows']])
        self.assertEqual(b.decode_transport(wire), payload)
        self.assertIs(payload['left'], payload['right'])
        self.assertEqual(len(payload['left']['rows']), 10)

    def test_expanded_budget_counts_repeated_schema_keys_before_rows_exist(self):
        # 10 restored records each cost 109; hand array charge: 1101,
        # then enclosing record/key/colon cost9, for expanded total1110.
        table = {'path':['rows'], 'schemas':[['x'*100]], 'rows':[[0,None] for _ in range(10)]}
        wire = {'transport_version':2,'payload':{'rows':None},'aliases':[],'row_tables':[table]}
        self.assertLess(b.normalized_size(wire), 1110)
        self.assertEqual(len(b.decode_transport(wire, max_bytes=1110)['rows']),10)
        before = copy.deepcopy(wire)
        with self.assertRaises(ValueError):
            b.decode_transport(wire, max_bytes=1109)
        self.assertEqual(wire,before)

    def test_late_bad_table_preserves_input_and_success_copies_only_affected_branches(self):
        wire = copy.deepcopy(CONTRACT['valid_decodes'][0]['wire'])
        wire['payload']['branch']={'second':None,'shared':{'keep':True}}
        wire['row_tables'].append({'path':['branch','second'],'schemas':[['a']],'rows':[[0,None],[0,False]]})
        before = copy.deepcopy(wire)
        decoded = b.decode_transport(wire)
        self.assertEqual(wire,before)
        self.assertIsNot(decoded,wire['payload'])
        self.assertIsNot(decoded['branch'],wire['payload']['branch'])
        self.assertIs(decoded['branch']['shared'],wire['payload']['branch']['shared'])
        wire['row_tables'][-1]['rows'][-1].append('wrong_width')
        before = copy.deepcopy(wire)
        with self.assertRaises(ValueError):
            b.decode_transport(wire)
        self.assertEqual(wire,before)

    def test_oversized_encoder_graph_rejects_before_snapshot_allocation(self):
        # Each reviewed alias has one canonical source; input may contain at most
        # a second copy of its budgeted data before reviewed alias removal.
        with patch.object(b, '_copy_json_occurrences', side_effect=AssertionError('snapshot allocated before budget')):
            with self.assertRaisesRegex(ValueError, 'budget'):
                b.encode_transport({'verbatim': 'x'*1000}, max_bytes=100)

    def test_alias_duplicates_are_excluded_from_binding_pre_alias_budget(self):
        rows = [{'long_repeated_key':None} for _ in range(200)]
        payload = {'catalog_rows':rows,'review_infrastructure_sections':{'catalog':rows}}
        self.assertGreater(b.normalized_size(payload),9000)
        for version in (1,2):
            wire = b.encode_transport(payload,version,max_bytes=9000)
            decoded = b.decode_transport(wire,max_bytes=9000)
            self.assertEqual(decoded,payload)
            self.assertIs(decoded['catalog_rows'],decoded['review_infrastructure_sections']['catalog'])

    def test_numeric_boundary_integral_spellings_and_invalid_limits(self):
        maximum = int(sys.float_info.max)
        finite = {'n': maximum}
        self.assertEqual(b.decode_transport(b.encode_transport(finite))['n'], maximum)
        parsed_v1 = b.decode_transport(json.loads(b.compact(b.encode_transport(finite,1))))
        parsed_v2 = b.decode_transport(json.loads(b.compact(b.encode_transport(finite,2))))
        self.assertEqual(parsed_v2,parsed_v1)
        self.assertIs(type(parsed_v2['n']),int)
        self.assertEqual(b.normalized_size(maximum),32)
        for invalid in (maximum + 2**971, math.inf, -math.inf):
            with self.assertRaises(ValueError):
                b.encode_transport({'n':invalid})
        wire = copy.deepcopy(CONTRACT['valid_decodes'][0]['wire'])
        wire['transport_version']=2.0
        wire['row_tables'][0]['rows'][0][0]=0.0
        self.assertEqual(b.decode_transport(wire),CONTRACT['valid_decodes'][0]['logical'])
        for maximum in (True,False,0,-1,1.5,'100',math.inf,math.nan):
            with self.subTest(maximum=maximum), self.assertRaises(ValueError):
                b.decode_transport(wire,max_bytes=maximum)

    def test_all_packing_work_limits_leave_whole_tables_verbatim(self):
        rows = [{'long_repeated_synthetic_column':i} for i in range(10)]
        mixed = [{'long_repeated_synthetic_column':i, **({'second_long_repeated_synthetic_column':True} if i%2 else {})} for i in range(10)]
        cases = [({'tables':1},{'a':rows,'b':rows},[['a']]),
                 ({'cells':10},{'wide':mixed,'small':rows},[['small']]),
                 ({'schemas_per_table':1},{'mixed':mixed,'small':rows},[['small']]),
                 ({'keys_per_schema':1},{'mixed':mixed,'small':rows},[['small']]),
                 ({'path_depth':1},{'deep':{'rows':rows},'small':rows},[['small']]),
                 ({'key_utf8_bytes':40},{'x'*41:rows,'small':rows},[['small']])]
        for limits,payload,expected_paths in cases:
            with self.subTest(limits=limits),patch.dict(b.WORK_LIMITS,limits):
                wire=b.encode_transport(payload)
                self.assertEqual([t['path'] for t in wire['row_tables']],expected_paths)
                self.assertEqual(b.decode_transport(wire),payload)

    def test_unsafe_and_unprofitable_encoder_candidates_remain_verbatim(self):
        payload={'tiny':[{'a':1},{'a':2}],
                 'unsafe':[{'constructor':i,'long_repeated_synthetic_column':None} for i in range(10)],
                 'constructor':{'rows':[{'long_repeated_synthetic_column':i} for i in range(10)]},
                 'empty':[{},{}]}
        wire=b.encode_transport(payload)
        self.assertEqual(wire['row_tables'],[])
        self.assertEqual(b.decode_transport(wire),payload)


if __name__ == '__main__':
    unittest.main()
