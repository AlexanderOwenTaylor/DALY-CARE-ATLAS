"""Exact field registry contract guard; policy comes only from local resources."""
import json
import math
import os
from collections import Counter
from pathlib import Path

VERSION = 'registry-summary-v1'
COUNTS = ('denominator_n','n_valid','n_missing','n_invalid','n_conflicting','n_distinct','minimum_value_support')
STATS = ('mean','median','p25','p75')
METADATA = ('table_name','source_column','kind','topic','phase','label')
CONSTANTS = dict(contract_version=VERSION,unit_status='unverified',count_basis='distinct_people_one_unambiguous_value_per_field',summary_method='exact_complete_field_3sf')
SCHEMA = ('contract_version',)+METADATA+('unit_status','count_basis','summary_method','summary_status','minimum_cell_count')+COUNTS+('category_counts_json',)+STATS
STATUSES = {'published','needs_person_key','missing_person_key','field_unavailable','query_failed','resource_limit','withheld_small_group','withheld_constant','withheld_near_unique','no_values','invalid_contract'}
STATUSES.add('needs_unit_evidence')

def _number(x):
    if x is None or isinstance(x,bool) or not isinstance(x,(str,int,float)): return None
    try:
        n=float(x)
        return n if math.isfinite(n) and n >= 0 else None
    except (ValueError,TypeError,OverflowError): return None

def _integer(x):
    n=_number(x)
    return int(n) if n is not None and n == int(n) and n <= 9007199254740991 else None

def _floor(value):
    n=_integer(value)
    return max(5,n) if n is not None else 5

def _requested_threshold(value):
    n=_number(value)
    if n is None or n < 1 or n > 9007199254740991:
        raise ValueError('Invalid explicit privacy threshold')
    return max(5,math.ceil(n))

def registry_summary_policy(project_root=None):
    root=Path(project_root) if project_root is not None else Path(__file__).resolve().parents[1]
    candidates=(root/'config/registry-summary-policy.json',root/'inst/config/registry-summary-policy.json')
    path=next((p for p in candidates if p.is_file()),None)
    if path is None: return {}
    try:
        policy=json.loads(path.read_text(encoding='utf-8-sig'))
        if not isinstance(policy,dict) or set(policy)!={'version','fields'} or policy['version']!=VERSION or not isinstance(policy['fields'],list): return {}
        out={}
        for f in policy['fields']:
            if not isinstance(f,dict) or set(f)!=set(METADATA)|{'categories'}: return {}
            if any(not isinstance(f[key],str) for key in METADATA): return {}
            if f['table_name'] not in {'RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL'} or f['kind'] not in {'numeric','categorical'} or f['topic'] not in {'stage','treatment','response','laboratory'}: return {}
            categories=f['categories']
            if not isinstance(categories,list) or any(not isinstance(c,str) or not c or len(c)>128 for c in categories) or len(categories)>1000 or len(set(categories))!=len(categories): return {}
            if f['kind']=='numeric' and categories: return {}
            identity=(f['table_name'],f['source_column'])
            if identity in out: return {}
            out[identity]=f
        return out
    except (OSError,ValueError,TypeError): return {}

def _identity(row):
    if not isinstance(row,dict): return None
    a,b=row.get('table_name'),row.get('source_column')
    return (a,b) if isinstance(a,str) and isinstance(b,str) else None

def _k(row, requested):
    return max(_requested_threshold(requested),_requested_threshold(os.environ.get('DALYCARE_MIN_CELL_COUNT','5')),_floor(row.get('minimum_cell_count')))

def _canonical(field,k,status):
    row={key:None for key in SCHEMA}
    row.update(CONSTANTS)
    row.update({key:field[key] for key in METADATA})
    row.update(summary_status=status,minimum_cell_count=k,category_counts_json='[]')
    return row

def _category_cells(raw,field):
    if not isinstance(raw,str): return None
    try:
        if len(raw.encode('utf-8'))>65536: return None
    except UnicodeError: return None
    try:
        # Duplicate JSON object keys are rejected before json can silently overwrite.
        def pairs(items):
            d={}
            for key,value in items:
                if key in d: raise ValueError('duplicate key')
                d[key]=value
            return d
        values=json.loads(raw,object_pairs_hook=pairs)
    except (ValueError,TypeError,RecursionError): return None
    if not isinstance(values,list) or len(values)>len(field['categories']): return None
    codes=set(); cells=[]
    for value in values:
        if not isinstance(value,dict) or set(value)!={'code','n'} or not isinstance(value['code'],str) or value['code'] not in field['categories'] or value['code'] in codes: return None
        # JSON cell counts must be actual integers, not strings or booleans.
        if isinstance(value['n'],bool) or not isinstance(value['n'],int) or _integer(value['n']) is None or value['n']<=0: return None
        codes.add(value['code']); cells.append(dict(code=value['code'],n=value['n']))
    return sorted(cells,key=lambda c:field['categories'].index(c['code']))

def _published(row,field,k):
    """Validate original data; used by guard and independently by audit."""
    if field['kind']=='numeric': return None  # v1 never proves stored unit or grouped release.
    counts={key:_integer(row.get(key)) for key in COUNTS[:5]}
    if any(n is None for n in counts.values()): return None
    total=counts['denominator_n']; valid=counts['n_valid']
    if total<=0 or valid<=0 or sum(counts[key] for key in COUNTS[1:5])!=total: return None
    if any(0<n<k or 0<total-n<k for n in counts.values()): return None
    out=dict(counts)
    if field['kind']=='categorical':
        if any(row.get(key) is not None for key in STATS+COUNTS[5:]): return None
        cells=_category_cells(row.get('category_counts_json'),field)
        if cells is None or not cells or sum(c['n'] for c in cells)!=valid: return None
        if any(c['n']<k or 0<valid-c['n']<k or 0<total-c['n']<k for c in cells): return None
        out['category_counts_json']=json.dumps(cells,ensure_ascii=False,separators=(',',':'))
    else:
        if row.get('category_counts_json')!='[]': return None
        distinct=_integer(row.get('n_distinct')); minimum=_integer(row.get('minimum_value_support'))
        values={key:_number(row.get(key)) for key in STATS}
        if valid<20 or distinct is None or distinct<=1 or distinct>=valid*.9 or minimum is None or minimum<k or distinct*minimum>valid or any(n is None for n in values.values()): return None
        if not values['p25']<=values['median']<=values['p75']: return None
        values={key:float(format(value,'.3g')) for key,value in values.items()}
        if any(not math.isfinite(value) for value in values.values()): return None
        out.update(values); out.update(n_distinct=distinct,minimum_value_support=minimum)
    return out

def _schema_ok(row,field):
    return set(row)==set(SCHEMA) and row.get('kind')==field['kind'] and all(row.get(key)==value for key,value in CONSTANTS.items()) and isinstance(row.get('summary_status'),str) and row['summary_status'] in STATUSES and _integer(row.get('minimum_cell_count')) is not None and _integer(row.get('minimum_cell_count'))>=5

def sanitize_registry_summaries(rows,project_root=None,min_cell_count=5):
    if not isinstance(rows,list): return []
    if any(isinstance(r,dict) and r.get('contract_version')=='registry-summary-v2' for r in rows):
        from registry_v2 import guard
        modern=[r for r in rows if isinstance(r,dict) and r.get('contract_version')=='registry-summary-v2']
        legacy=[r for r in rows if r not in modern]
        ids=Counter(_identity(r) for r in rows)
        thresholds={id:max(_k(r,min_cell_count) for r in rows if _identity(r)==id) for id in ids}
        modern=[dict(r,summary_status='invalid_contract',minimum_cell_count=thresholds[_identity(r)]) if ids[_identity(r)]>1 else r for r in modern]
        legacy=[dict(r,summary_status='invalid_contract',minimum_cell_count=thresholds[_identity(r)]) if ids[_identity(r)]>1 else r for r in legacy]
        result=guard(modern,project_root,min_cell_count)+sanitize_registry_summaries(legacy,project_root,min_cell_count)
        byid={}
        for r in result:byid.setdefault(_identity(r),r)
        return [byid[id] for id in dict.fromkeys(_identity(r) for r in rows) if id in byid]
    policy=registry_summary_policy(project_root)
    counts=Counter(_identity(r) for r in rows)
    out=[]; seen=set()
    for row in rows:
        identity=_identity(row)
        if identity not in policy or identity in seen: continue
        seen.add(identity); field=policy[identity]
        k=max(_k(r,min_cell_count) for r in rows if _identity(r)==identity)
        status=row.get('summary_status') if _schema_ok(row,field) else 'invalid_contract'
        if counts[identity]>1: status='invalid_contract'
        if status=='published' and field['kind']=='numeric': status='needs_unit_evidence'
        result=_canonical(field,k,status)
        if status=='published':
            publication=_published(row,field,k)
            if publication is None: result['summary_status']='invalid_contract'
            else: result.update(publication)
        out.append(result)
    return out

def audit_registry_summaries(rows,project_root=None,min_cell_count=5):
    """Inspect original rows independently; errors contain paths only, never values."""
    if not isinstance(rows,list): return ['registry_field_summaries.invalid_list']
    policy=registry_summary_policy(project_root)
    identities=Counter(_identity(row) for row in rows)
    errors=[]
    if isinstance(rows,list) and any(isinstance(r,dict) and r.get('contract_version')=='registry-summary-v2' for r in rows):
        from registry_v2 import guard
        modern=[r for r in rows if isinstance(r,dict) and r.get('contract_version')=='registry-summary-v2'];legacy=[r for r in rows if r not in modern]
        ids=[_identity(r) for r in rows]
        return guard(modern,project_root,min_cell_count,True)+audit_registry_summaries(legacy,project_root,min_cell_count)+(['registry_field_summaries.duplicate_identity'] if len(set(ids))!=len(ids) else [])
    for index,row in enumerate(rows):
        prefix=f'registry_field_summaries.{index}'
        identity=_identity(row); field=policy.get(identity)
        if field is None or not _schema_ok(row,field) or identities[identity]>1:
            errors.append(prefix+'.invalid_contract'); continue
        k=_k(row,min_cell_count)
        canonical=_canonical(field,k,row['summary_status'])
        if any(row.get(key)!=canonical[key] for key in METADATA+tuple(CONSTANTS)+('minimum_cell_count',)):
            errors.append(prefix+'.metadata')
        if row['summary_status']=='published':
            publication=_published(row,field,k)
            if publication is None: errors.append(prefix+'.unsafe_publication')
            elif field['kind']=='numeric' and any(_number(row[key])!=publication[key] for key in STATS): errors.append(prefix+'.numeric_precision')
        elif row.get('category_counts_json')!='[]' or any(row.get(key) is not None for key in COUNTS+STATS): errors.append(prefix+'.withheld_data')
    return errors
