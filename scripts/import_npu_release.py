"""Reproduce the pinned IFCC retrieval snapshot from an already downloaded CSV.

No network requests. Publication dates are not inferred from retrieval dates.
"""
import argparse
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path

RAW_SHA256 = '3aef05383e918cc1304c53c5ca6f8a9467b6d700fc3ba18563744c1fbe904353'
SNAPSHOT = 'ifcc-npu-retrieved-2026-10-14'
URL = 'https://cms.ifcc.org/wp-content/uploads/npu-codes-latest.csv'


def generate(source, root):
    raw = Path(source).read_bytes()
    if hashlib.sha256(raw).hexdigest() != RAW_SHA256:
        raise ValueError('Unexpected official NPU snapshot checksum')
    config = Path(root) / 'config'
    target = config / 'terminology' / SNAPSHOT
    target.mkdir(parents=True, exist_ok=True)
    reviewed_path = target / 'reviewed-display-labels.csv'
    if not reviewed_path.exists():
        reviewed_path.write_bytes((config / 'npu-display-dictionary.csv').read_bytes())
    reviewed = {r['code']: r for r in csv.DictReader(io.StringIO(reviewed_path.read_text(encoding='utf-8-sig')))}
    records = list(csv.DictReader(io.StringIO(raw.decode('utf-8-sig'))))
    current = [r for r in records if r['active'] == '1' and r['current_version'].lower() == 'true']
    if len(current) != 25699 or len({r['npu_code'] for r in current}) != len(current):
        raise ValueError('Official active/current code inventory changed')
    with (target / 'official.csv.gz').open('wb') as output:
        with gzip.GzipFile(filename='', fileobj=output, mode='wb', mtime=0) as compressed:
            compressed.write(raw)
    display = config / 'npu-display-dictionary.csv'
    fields = ['code','label','label_da','system','system_spec','unit','definition','property','status','source_url','retrieved_on','source_label','note']
    with display.open('w', encoding='utf-8', newline='') as output:
        writer = csv.DictWriter(output, fieldnames=fields, lineterminator='\n')
        writer.writeheader()
        for r in sorted(current, key=lambda r: r['npu_code']):
            old = reviewed.get(r['npu_code'], {})
            approved = bool(old.get('label') and old.get('source_url') and old.get('retrieved_on'))
            writer.writerow(dict(code=r['npu_code'],label=old['label'] if approved else r['component'],
                label_da=old.get('label_da','') if approved else '', system=r['system'],system_spec=r['sys_spec'],
                unit=r['unit_short'],definition=r['full_definition'],property=r['kind_of_property'],status='active',
                source_url=URL,retrieved_on='2026-10-14',source_label='IFCC NPU retrieval snapshot 2026-10-14',
                note=('Reviewed readable label retained from '+old['retrieved_on']+'. ' if approved else '')+
                'Reference terminology unit only; does not verify any stored source-field unit. Official name coverage is separate from consensus grouping coverage.'))
        # Retain reviewed earlier definitions that are absent from this current
        # active release, explicitly outside the active/current official count.
        active_codes={r['npu_code'] for r in current}
        for code, old in sorted(reviewed.items()):
            if code in active_codes:continue
            writer.writerow({**{k:old.get(k,'') for k in fields},'status':'reviewed_legacy_reference',
                'source_label':'Reviewed local fallback retained from '+old.get('retrieved_on','prior display dictionary'),
                'note':'Reviewed earlier display definition; absent from the active/current IFCC retrieval snapshot 2026-10-14. '
                    'Original source URL and retrieval date retained. Reference unit does not verify any stored source-field unit.'})
    files = [target/'official.csv.gz', reviewed_path, display]
    manifest = dict(schema_version=1,snapshot=SNAPSHOT,retrieved_on='2026-10-14',source_url=URL,
        landing_url='https://ifcc.org/ifcc-scientific-division/sd-committees/c-npu/',
        raw_sha256=RAW_SHA256,raw_bytes=len(raw),active_current_unique_codes=len(current),
        publication_date=None,reviewed_legacy_fallback_codes=sorted(set(reviewed)-active_codes),consensus_grouping='Separate config/npu-consensus-dictionary.tsv; not official name coverage',
        files=[dict(path=p.relative_to(config).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size) for p in files])
    (config/'terminology'/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    generate(args.source,args.root)
