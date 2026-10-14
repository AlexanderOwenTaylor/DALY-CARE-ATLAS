"""Check a rebuilt public site against a private archive reference, locally only.

The reference is deliberately supplied by the operator, never downloaded or sent
to CI. This complements the public privacy validators; it does not certify a live
NGC run. Output contains structural totals, not clinical values or identifiers.
"""
from __future__ import annotations

import argparse
from collections import Counter
import csv
from decimal import Decimal, InvalidOperation
import hashlib
import json
from pathlib import Path
import sys

EMPTY = (None, '', 'NA', 'null')
STATISTICS = frozenset(('min', 'max', 'mean', 'median', 'p25', 'p75', 'min_date', 'max_date',
                        'q1', 'q3', 'sd', 'minimum', 'maximum', 'numeric_min', 'numeric_max'))


def records(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from records(child)
    elif isinstance(value, list):
        for child in value:
            yield from records(child)


def identity(row):
    if row.get('source_name') and row.get('raw_column'):
        return (row['source_name'], row['raw_column'])
    return (row.get('table_name') or row.get('source_name'),
            row.get('column_name') or row.get('source_column') or row.get('raw_column'))


def privacy_identities(row):
    # Catalogue reconciliation chooses the logical semantic pair. Privacy scans
    # must consider all claimed locations/columns so no alternate pair hides one.
    sources = {row[key] for key in ('table_name', 'source_name')
               if isinstance(row.get(key), str) and row[key]}
    columns = {row[key] for key in ('column_name', 'source_column', 'raw_column')
               if isinstance(row.get(key), str) and row[key]}
    return {(source, column) for source in sources for column in columns}


def check_small_profiles(reference, value):
    profiles = reference.get('small_support_profiles')
    if not isinstance(profiles, list):
        raise ValueError('Invalid small-support reference')
    protected = {}
    for profile in profiles:
        if not isinstance(profile, dict):
            raise ValueError('Invalid small-support reference')
        key, statistics = profile.get('identity'), profile.get('statistic_columns')
        if (not isinstance(key, list) or len(key) != 2
                or not all(isinstance(part, str) and part for part in key)
                or not isinstance(statistics, list)
                or not all(isinstance(name, str) and name for name in statistics)):
            raise ValueError('Invalid small-support reference')
        protected.setdefault(tuple(key), set(STATISTICS)).update(statistics)
    for row in records(value):
        statistics = set().union(*(protected.get(pair, ()) for pair in privacy_identities(row)))
        if any(row.get(key) not in EMPTY for key in statistics):
            raise ValueError('A small-support profile retains public statistics')


def category_counts(row):
    groups = row.get('category_counts_json') or []
    if isinstance(groups, str):
        groups = json.loads(groups)
    result = {}
    for group in groups:
        code, count = group['code'], group['n']
        if code in result or type(count) not in (int, float) or count < 0 or int(count) != count:
            raise ValueError('Invalid or duplicate distribution category')
        result[code] = int(count)
    return result


def compare_tables(reference, tables, allow_stricter_withholding=False):
    wanted_columns = {tuple(row) for row in reference['source_columns']}
    profiles = tables.get('column_profiles', [])
    catalogue = tables.get('semantic_dictionary', [])
    if not wanted_columns <= {identity(row) for row in profiles}:
        raise ValueError('Rebuilt column profiles omit archived metadata')
    if not wanted_columns <= {identity(row) for row in catalogue}:
        raise ValueError('Rebuilt clinical catalogue omits archived columns')
    registry = tables.get('registry_field_summaries', [])
    registry_counts = Counter(identity(row) for row in registry)
    if any(n != 1 for n in registry_counts.values()):
        raise ValueError('Rebuilt registry has duplicate field outcomes')
    if not {tuple(row) for row in reference['registry_identities']} <= registry_counts.keys():
        raise ValueError('Rebuilt registry omits archived field outcomes')
    lookup = {identity(row): row for row in registry}
    reconciled = withheld = 0
    for old in reference['published_registry']:
        new = lookup[identity(old)]
        status = new.get('publication_status') or new.get('summary_status')
        if status != 'published':
            if (allow_stricter_withholding and status in ('withheld', 'withheld_privacy')
                    and not category_counts(new) and new.get('n_valid') in EMPTY):
                withheld += 1
                continue
            raise ValueError('An archived published distribution was lost without stricter withholding')
        old_groups, new_groups = category_counts(old), category_counts(new)
        if old_groups != new_groups or sum(new_groups.values()) != float(new['n_valid']):
            raise ValueError('A rebuilt distribution disagrees with its source counts')
        reconciled += 1
    check_small_profiles(reference, tables)
    return dict(columns=len(wanted_columns), registry_fields=len(reference['registry_identities']),
                reconciled_distributions=reconciled, withheld_distributions=withheld,
                small_support_profiles=len(reference['small_support_profiles']))


def json_statement(text, prefix, suffix=';'):
    text = text.strip()
    if not text.startswith(prefix) or not text.endswith(suffix):
        raise ValueError('Unrecognised static data registration')
    return json.loads(text[len(prefix):-len(suffix)])


def inside(root, relative):
    path = root / relative
    if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError('Invalid public file reference')
    return path


def read_site_tables(site):
    catalogue = json_statement((site / 'DALYCARE_output_catalogue.js').read_text(encoding='utf-8-sig'),
                               'window.DALYCARE_OUTPUT_CATALOGUE = ')
    tables = {}
    for table in catalogue['tables']:
        if table['id'] in tables:
            raise ValueError('Duplicate public table identity')
        rows = []
        for shard in table['shards']:
            path = inside(site, shard['src'])
            if path.stat().st_size > 262144:
                raise ValueError('Public shard exceeds 256 KiB')
            registration = json_statement(path.read_text(encoding='utf-8-sig'),
                                          'window.DALYCARE_OUTPUTS.register(', ');')
            if (registration['build_id'] != catalogue['build_id'] or
                    registration['table_id'] != table['id'] or registration['shard_id'] != shard['id']):
                raise ValueError('Stale or misidentified public shard')
            part = json.loads(registration['rows_json'])
            if len(part) != shard['rows']:
                raise ValueError('Public shard row count disagrees')
            rows.extend(part)
        if len(rows) != table['represented_row_count']:
            raise ValueError('Public table row count disagrees')
        tables[table['id']] = rows
    return tables, catalogue


def verify_original(reference, original):
    for relative, expected in reference['input_files_sha256'].items():
        path = inside(original, relative)
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError('Original archive evidence changed during rebuilding')


def canonical_rows(rows, columns):
    """Compare CSV and JSON values without losing typed codes or row duplicates."""
    def cell(value, column):
        if value is None or value == '':
            return None
        kind = column['type']
        if kind == 'number':
            if isinstance(value, bool):
                raise ValueError('Invalid numeric public copy')
            try:
                number = Decimal(str(value))
            except InvalidOperation as error:
                raise ValueError('Invalid numeric public copy') from error
            if not number.is_finite():
                raise ValueError('Nonfinite numeric public copy')
            return ('number', number)
        if kind == 'boolean':
            if type(value) is bool:
                return value
            if value not in ('TRUE', 'FALSE', 'true', 'false'):
                raise ValueError('Invalid boolean public copy')
            return value.upper() == 'TRUE'
        if kind != 'string' or not isinstance(value, str):
            raise ValueError('Invalid string public copy')
        if column['key'].endswith('_json'):
            return ('json', json.dumps(json.loads(value), sort_keys=True, separators=(',', ':'), allow_nan=False))
        return ('string', value)
    keys = [column['key'] for column in columns]
    if len(keys) != len(set(keys)):
        raise ValueError('Invalid public table schema')
    result = Counter()
    for row in rows:
        if not isinstance(row, dict) or set(keys) != row.keys():
            raise ValueError('Invalid public table-copy schema')
        result[tuple(cell(row[key], column) for key, column in zip(keys, columns))] += 1
    return result


def compare_csv_downloads(site, tables, catalogue):
    for table in catalogue['tables']:
        table_id = table['id']
        path = inside(site, 'downloads/' + table_id + '.csv')
        header, rows = read_public_csv(path)
        keys = [column['key'] for column in table['columns']]
        if header != keys:
            raise ValueError('Public CSV schema disagrees with its table')
        if any(set(row) != set(keys) or any(value is None for value in row.values()) for row in rows):
            raise ValueError('Public CSV schema has malformed row widths')
        if canonical_rows(rows, table['columns']) != canonical_rows(tables[table_id], table['columns']):
            raise ValueError('Public CSV disagrees with its screened table')


def read_public_csv(path):
    size = path.stat().st_size
    if not 0 < size <= 67108864:
        raise ValueError('Public CSV exceeds bounded input size')
    previous = csv.field_size_limit(size)
    try:
        with path.open(encoding='utf-8-sig', newline='') as handle:
            reader = csv.DictReader(handle, strict=True)
            header = reader.fieldnames
            return header, list(reader)
    except (csv.Error, UnicodeError) as error:
        raise ValueError('Malformed public CSV') from error
    finally:
        csv.field_size_limit(previous)


def compare_payload_tables(payload, tables, catalogue, registry):
    """Only registered data paths represent table copies; absent lazy data is fine."""
    descriptors = {table['id']: table for table in catalogue['tables']}
    for spec in registry['artifacts']:
        path = spec.get('payload_path')
        if spec['id'] not in descriptors or not path:
            continue
        value = payload
        for key in path:
            if not isinstance(value, dict) or key not in value:
                break
            value = value[key]
        else:
            table = descriptors[spec['id']]
            if not isinstance(value, list):
                raise ValueError('Invalid registered public payload table')
            if canonical_rows(value, table['columns']) != canonical_rows(tables[spec['id']], table['columns']):
                raise ValueError('Public payload disagrees with its screened table')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', required=True, type=Path)
    parser.add_argument('--original', required=True, type=Path)
    parser.add_argument('--site', required=True, type=Path)
    parser.add_argument('--report', required=True, type=Path)
    parser.add_argument('--allow-stricter-withholding', action='store_true')
    args = parser.parse_args()
    reference = json.loads(args.reference.read_text(encoding='utf-8-sig'))
    verify_original(reference, args.original)
    tables, catalogue = read_site_tables(args.site)
    result = compare_tables(reference, tables, args.allow_stricter_withholding)
    compare_csv_downloads(args.site, tables, catalogue)
    check_small_profiles(reference, catalogue)
    # Independent copies in every CSV and JSON are inspected, not only UI tables.
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from site_bundle import decode_transport
    registry = json.loads((Path(__file__).resolve().parents[1] / 'inst/config/public-output-registry.json').read_text(encoding='utf-8'))
    inspected = Counter()
    for path in args.site.rglob('*'):
        if not path.is_file():
            continue
        inside(args.site, path.relative_to(args.site))
        if path.suffix.lower() == '.csv':
            check_small_profiles(reference, read_public_csv(path)[1])
            inspected['csv'] += 1
        elif path.suffix.lower() == '.json':
            data = json.loads(path.read_text(encoding='utf-8-sig'))
            if isinstance(data, dict) and 'transport_version' in data:
                data = decode_transport(data)
            check_small_profiles(reference, data)
            compare_payload_tables(data, tables, catalogue, registry)
            inspected['json'] += 1
        elif path.suffix.lower() == '.js':
            text = path.read_text(encoding='utf-8-sig').strip()
            prefix = 'window.DALYCARE_ATLAS_PAYLOAD = '
            if text.startswith(prefix):
                data = decode_transport(json_statement(text, prefix))
                check_small_profiles(reference, data)
                compare_payload_tables(data, tables, catalogue, registry)
                inspected['payload_js'] += 1
    if not inspected['csv']:
        raise ValueError('The rebuilt site contains no screened CSV downloads')
    result.update(formats_inspected=dict(inspected), input_hashes_unchanged=True,
                  csv_tables_reconciled=len(tables), registered_payload_copies_reconciled=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
