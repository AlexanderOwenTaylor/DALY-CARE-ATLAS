"""Rebuild the static UI from an existing aggregate export, without a database run."""
import argparse
import csv
import json
import os
from pathlib import Path
from public_privacy import sanitize_public_payload, audit_public_payload


def build(input_dir, output_dir, project_root):
    source = input_dir / 'DALYCARE_atlas_payload.js'
    raw = source.read_text(encoding='utf-8-sig')
    prefix = 'window.DALYCARE_ATLAS_PAYLOAD ='
    if not raw.strip().startswith(prefix):
        raise ValueError('Unrecognized atlas payload wrapper')
    payload = json.loads(raw.strip()[len(prefix):].strip().removesuffix(';'))
    with (project_root / 'config/npu-display-dictionary.csv').open(encoding='utf-8-sig', newline='') as stream:
        payload['npu_display_dictionary'] = list(csv.DictReader(stream))
    with (project_root / 'config/clinical-display-dictionary.csv').open(encoding='utf-8-sig', newline='') as stream:
        payload['clinical_display_dictionary'] = list(csv.DictReader(stream))
    payload['display_metadata'] = {
        'version': '2026-10-11-clinician-9',
        'terminology_source': 'https://cms.ifcc.org/wp-content/uploads/npu-codes-latest.csv',
        'danish_alias_source': 'https://docs.ehealth.sundhed.dk/latest/ig/CodeSystem-mcs.json',
        'note': 'Public disclosure guard applied; stored source-row summaries and reference terminology.'
    }
    payload = sanitize_public_payload(payload, min_cell_count=os.environ.get('DALYCARE_MIN_CELL_COUNT', '5'), project_root=project_root)
    payload['display_metadata'].update(payload['privacy_metadata'])
    errors = audit_public_payload(payload)
    if errors:
        raise ValueError(f'Public privacy audit failed at {len(errors)} paths')
    compact = json.dumps(payload, ensure_ascii=False, separators=(',', ':'), allow_nan=False)
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / 'DALYCARE_atlas.html').write_bytes((project_root / 'inst/templates/DALYCARE_atlas.html').read_bytes())
    (output_dir / 'DALYCARE_atlas_payload.js').write_text(prefix + compact + ';\n', encoding='utf-8')
    (output_dir / 'DALYCARE_atlas_payload.json').write_text(compact + '\n', encoding='utf-8')
    print(f'Built {output_dir}: {len(compact.encode()):,} payload bytes')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input-dir', type=Path, required=True,
                        help='Directory containing DALYCARE_atlas_payload.js to rebuild')
    parser.add_argument('--output-dir', type=Path, required=True,
                        help='Directory in which to write the rebuilt HTML, JS, and JSON files')
    args = parser.parse_args()
    build(args.input_dir, args.output_dir, root)
