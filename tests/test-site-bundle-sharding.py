"""Reference-table shard work stays bounded as the dictionary grows."""
import json
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import site_bundle as b


class ShardWorkTests(unittest.TestCase):
    def test_wide_escaped_rows_roundtrip_and_required_oversize_rolls_back(self):
        rows = [dict(code='SYNTHETIC_E0_%d' % i,
                     definition=('東京"/\\\b\t\n\f\r\u2028\u2029😀' * 3500)) for i in range(4)]
        table = dict(id='npu_display_dictionary', status='available', complete=True,
                     source_file='config/npu-display-dictionary.csv', source_terms=[],
                     columns=[dict(key=k, type='string') for k in rows[0]], rows=rows)
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'site'
            with patch.object(b.uuid, 'uuid4', return_value=b.uuid.UUID(int=0)):
                result = b.write_site_bundle(out, {'run_id': 'E0_WIDE'}, [table], ROOT, 'legacy_payload')
            catalogue = json.loads(result['catalogue'].read_text(encoding='utf-8').split('=', 1)[1].strip().removesuffix(';'))
            restored = []
            for shard in catalogue['tables'][0]['shards']:
                text = (out / shard['src']).read_text(encoding='utf-8')
                registration = json.loads(text.split('register(', 1)[1].removesuffix(');\n'))
                self.assertLessEqual(len(text.encode('utf-8')), 262144)
                self.assertLessEqual(shard['bytes'], 262144)
                restored.extend(json.loads(registration['rows_json']))
            self.assertGreater(len(catalogue['tables'][0]['shards']), 1)
            self.assertEqual(restored, rows)
            assets = {p: p.read_bytes() for p in result['assets']}
            with patch.object(b.uuid, 'uuid4', return_value=b.uuid.UUID(int=0)):
                b.write_site_bundle(out, {'run_id': 'E0_WIDE'}, [table], ROOT, 'legacy_payload')
            self.assertEqual(assets, {p: p.read_bytes() for p in assets})
            before = {p: p.read_bytes() for p in result['assets'] + [result['manifest']]}
            required = dict(id='sources', status='available', complete=True, source_terms=[],
                            source_file='outputs/atlas_sources.csv',
                            columns=[dict(key='table_name', type='string')],
                            rows=[dict(table_name='small')] * 250 + [dict(table_name='x' * 270000)])
            with self.assertRaisesRegex(ValueError, 'Required table row exceeds'):
                b.write_site_bundle(out, {'run_id': 'E0_REQUIRED'}, [required], ROOT, 'legacy_payload')
            self.assertEqual(before, {p: p.read_bytes() for p in before})

    def test_large_definition_table_has_bounded_serialization_work(self):
        # Repeatedly serializing a growing pending shard must fail this bound.
        # Complete duplicates and UTF-8/escaped cells must survive the same path.
        count = 25700
        rows = [dict(code='SYNTHETIC_E0_%04d' % (i % 257),
                     label='Definition %d' % (i % 257),
                     definition='東京 "quoted" \\ path\næ') for i in range(count)]
        table = dict(id='npu_display_dictionary', status='available', complete=True,
                     source_file='config/npu-display-dictionary.csv', source_terms=[],
                     columns=[dict(key=k, type='string') for k in rows[0]], rows=rows)
        original = b.compact
        work = dict(calls=0, row_occurrences=0, serialized_bytes=0)

        def measured(value):
            result = original(value)
            work['calls'] += 1
            work['row_occurrences'] += result.count('SYNTHETIC_E0_')
            work['serialized_bytes'] += len(result.encode('utf-8'))
            return result

        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'site'
            started = time.perf_counter()
            with patch.object(b, 'compact', side_effect=measured):
                paths = b.write_site_bundle(out, {'run_id': 'E0_SYNTHETIC'}, [table], ROOT, 'legacy_payload')
            elapsed = time.perf_counter() - started
            catalogue = json.loads(paths['catalogue'].read_text(encoding='utf-8').split('=', 1)[1].strip().removesuffix(';'))
            item = catalogue['tables'][0]
            restored, script_bytes = [], 0
            self.assertEqual([s['rows'] for s in item['shards']], [250] * 102 + [200])
            for shard in item['shards']:
                text = (out / shard['src']).read_text(encoding='utf-8')
                registration = json.loads(text.split('register(', 1)[1].removesuffix(');\n'))
                self.assertEqual((registration['build_id'], registration['table_id'], registration['shard_id']),
                                 (catalogue['build_id'], item['id'], shard['id']))
                self.assertEqual(len(registration['rows_json'].encode('utf-8')), shard['bytes'])
                self.assertLessEqual(shard['bytes'], 262144)
                self.assertLessEqual(len(text.encode('utf-8')), 262144)
                restored.extend(json.loads(registration['rows_json']))
                script_bytes += len(text.encode('utf-8'))
            self.assertEqual(restored, rows)
            print('E0 Python definitions=%d elapsed_seconds=%.3f calls=%d row_occurrences=%d serialized_bytes=%d shards=%d rows_json_bytes=%d script_bytes=%d' %
                  (count, elapsed, work['calls'], work['row_occurrences'], work['serialized_bytes'],
                   len(item['shards']), sum(s['bytes'] for s in item['shards']), script_bytes), flush=True)
            self.assertLessEqual(work['row_occurrences'], 12 * count)


if __name__ == '__main__':
    unittest.main()
