"""Independent v2 validator. Local policy and unit evidence establish authority."""
import hashlib,json,math,os
from pathlib import Path

COUNTS=('denominator_n','n_valid','n_missing','n_unrecognised','n_conflicting')
ESTIMATES=('approximate_mean','p25_band','median_band','p75_band','iqr_lower','iqr_upper','modal_band')
META=('table_name','source_column','kind','topic','phase','label')
SCHEMA=('contract_version',)+META+('policy_version','policy_checksum','mapping_status','collection_status','data_status','publication_status','summary_status','minimum_cell_count','count_basis','summary_method','unit_status','unit_code','unit_evidence_id','unit_evidence_checksum','unit_binding_checksum','numeric_policy_id','numeric_policy_checksum','band_level')+COUNTS+('category_counts_json','numeric_groups_json')+ESTIMATES
COLLECTION={'complete','field_absent','source_unavailable','needs_person_key','missing_person_key','query_failed','resource_limit'}
DATA={'unknown','empty_source','all_missing','all_unrecognised','all_conflicting','no_usable_values','usable_values'}
PUBLICATION={'published','withheld_privacy','needs_mapping','needs_unit_evidence','needs_numeric_policy','invalid_contract','not_applicable'}
def pairs(items):
    out={}
    for k,v in items:
        if k in out: raise ValueError('duplicate key')
        out[k]=v
    return out
def decode(raw): return json.loads(raw,object_pairs_hook=pairs,parse_constant=lambda x: (_ for _ in ()).throw(ValueError('nonfinite')))
def number(x): return isinstance(x,(float,int)) and not isinstance(x,bool) and math.isfinite(x)
def integer(x): return number(x) and 0<=x<=9007199254740991 and int(x)==x
def read(path,limit=1048576):
    p=Path(path)
    if not path or not p.is_file() or p.stat().st_size>limit: raise ValueError('missing resource')
    raw=p.read_bytes();return decode(raw.decode('utf-8-sig')),hashlib.sha256(raw).hexdigest()
def safe(ns,total,k): return all(integer(n) and (n==0 or n>=k and (total-n==0 or total-n>=k)) for n in ns)
def numeric_policies(fields):
    try:
        p,checksum=read(os.getenv('DALYCARE_REGISTRY_NUMERIC_POLICY_FILE',''),262144)
        if set(p)!={'version','policies'} or p['version']!='registry-numeric-policy-v1' or not isinstance(p['policies'],list) or len(p['policies'])>217: return {}
        out={}
        for s in p['policies']:
            if set(s)!={'numeric_policy_id','table_name','source_column','unit_code','edges','levels','minimum_people','constant_policy'}: return {}
            if any(not isinstance(s[k],str) or not 0<len(s[k])<=160 for k in ('numeric_policy_id','table_name','source_column','unit_code')): return {}
            f=fields.get((s['table_name'],s['source_column']))
            if not f or f['kind']!='numeric' or s['numeric_policy_id'] in out or s['constant_policy']!='withhold' or not integer(s['minimum_people']) or s['minimum_people']<20: return {}
            edges=s['edges'];levels=s['levels']
            if not isinstance(edges,list) or not 3<=len(edges)<=65 or edges[-1] is not None or any(not number(e) or not 0<=e<=1e100 for e in edges[:-1]) or edges[0]!=0 or any(a>=b for a,b in zip(edges[:-2],edges[1:-1])): return {}
            previous=list(range(len(edges)))
            if not isinstance(levels,list) or not 1<=len(levels)<=16 or levels[0]!=previous: return {}
            for level in levels:
                if not isinstance(level,list) or len(level)<2 or any(not integer(v) for v in level) or level[0]!=0 or level[-1]!=len(edges)-1 or any(a>=b for a,b in zip(level,level[1:])) or any(v not in previous for v in level): return {}
                previous=level
            out[s['numeric_policy_id']]={**s,'checksum':checksum}
        return out
    except (OSError,ValueError,TypeError,KeyError,RecursionError): return {}
def unit_bindings(fields,policies):
    try:
        p,checksum=read(os.getenv('DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE',''),262144)
        if set(p)!={'version','bindings'} or p['version']!='registry-unit-evidence-v2' or not isinstance(p['bindings'],list) or len(p['bindings'])>217:return {}
        out={};seen=set()
        keys={'table_name','source_column','unit_code','stored_to_display_multiplier','stored_to_display_offset','evidence_id','evidence_source','evidence_revision','evidence_checksum','review_status','numeric_policy_id','numeric_policy_checksum','numeric_policy_version','evidence_tier'}
        import re
        for b in p['bindings']:
            if not isinstance(b,dict) or set(b)!=keys:return {}
            if any(not isinstance(b[k],str) or not 0<len(b[k])<=1024 for k in keys-{'stored_to_display_multiplier','stored_to_display_offset'}):return {}
            if not number(b['stored_to_display_multiplier']) or b['stored_to_display_multiplier']<=0 or not number(b['stored_to_display_offset']):return {}
            id=(b['table_name'],b['source_column']);f=fields.get(id)
            if not f or f['kind']!='numeric' or id in seen or b['review_status']!='verified' or b['evidence_tier']!='authoritative_source_metadata' or not re.fullmatch('[a-fA-F0-9]{64}',b['evidence_checksum']):return {}
            seen.add(id)
            if b['numeric_policy_version']!='registry-numeric-policy-v1' or not re.fullmatch('[a-f0-9]{64}',b['numeric_policy_checksum']):return {}
            n=policies.get(b['numeric_policy_id'])
            if n and b['numeric_policy_version']=='registry-numeric-policy-v1' and n['checksum']==b['numeric_policy_checksum'] and all(n[k]==b[k] for k in ('table_name','source_column','unit_code')):out[id]={'evidence':{**b,'binding_checksum':checksum},'policy':n}
        return out
    except (OSError,ValueError,TypeError,KeyError,RecursionError):return {}
def policy(root):
    root=Path(root) if root else Path(__file__).resolve().parents[1]
    try:
        path=next(p for p in (root/'config/registry-summary-policy-v2.json',root/'inst/config/registry-summary-policy-v2.json') if p.is_file())
        p,checksum=read(path)
        if p['version']!='registry-summary-v2' or len(p['fields'])!=217:return {}
        fields={(s['table_name'],s['source_column']):{**s,'policy_checksum':checksum} for s in p['fields']}
        if len(fields)!=217:return {}
        from registry_summary_privacy import registry_summary_policy
        legacy=registry_summary_policy(root)
        mapping_path=next(p for p in (root/'config/registry-source-mappings.json',root/'inst/config/registry-source-mappings.json') if p.is_file())
        mapping,_=read(mapping_path)
        for id,s in fields.items():
            old=legacy.get(id)
            if not old or any(s[k]!=old[k] for k in META) or set(s)!=set(META)|{'mapping_status','codes','mappings','policy_checksum'}:return {}
            expected=[m for m in mapping['records'] if (m['table_name'],m['source_column'])==id]
            if s['mappings']!=expected or s['mapping_status']!=('local_reviewed_recognition' if expected else 'recorded_codes_meaning_unverified'):return {}
            codes={c:{'code':c,'label':f'Recorded code {c}; meaning unverified'} for c in old['categories']}
            for m in expected:codes[m['canonical_token']]={'code':m['canonical_token'],'label':m['display_label']}
            if s['codes']!=list(codes.values()):return {}
        policies=numeric_policies(fields);bindings=unit_bindings(fields,policies)
        return {id:{**s,'binding':bindings.get(id)} for id,s in fields.items()}
    except (StopIteration,OSError,ValueError,TypeError,KeyError):return {}
def canonical(s,status,k,data='unknown'):
    r={k:None for k in SCHEMA};r.update({k:s[k] for k in META})
    r.update(contract_version='registry-summary-v2',policy_version='registry-summary-v2',policy_checksum=s['policy_checksum'],mapping_status=s['mapping_status'],count_basis='distinct_people_one_unambiguous_value_per_field',summary_method='fixed_bands_midpoint_mean_nearest_rank_intervals' if s['kind']=='numeric' else 'complete_reviewed_recorded_codes',minimum_cell_count=k,collection_status=status if status in COLLECTION else 'complete',data_status=data,publication_status=status if status in PUBLICATION else 'not_applicable',summary_status=data if status=='complete' else status,unit_status='unverified',category_counts_json='[]',numeric_groups_json='[]')
    if s.get('binding'):
        b=s['binding']['evidence'];p=s['binding']['policy']
        r.update(unit_status='verified',unit_code=b['unit_code'],unit_evidence_id=b['evidence_id'],unit_evidence_checksum=b['evidence_checksum'].lower(),unit_binding_checksum=b['binding_checksum'],numeric_policy_id=p['numeric_policy_id'],numeric_policy_checksum=p['checksum'])
    return r
def bands(p,level): return [{'id':f'b{int(a)}_{int(b)}','lower':p['edges'][int(a)],'upper':p['edges'][int(b)]} for a,b in zip(p['levels'][level],p['levels'][level][1:])]
def estimates(cells,bs):
    byid={b['id']:b for b in bs};used=[byid[c['band_id']] for c in cells];ns=[c['n'] for c in cells];total=sum(ns)
    def rank(prob):
        target=math.ceil(total*prob);n=0
        for i,c in enumerate(ns):
            n+=c
            if n>=target:return i
    a,b,c=map(rank,(.25,.5,.75))
    return dict(approximate_mean=sum((v['lower']+(v['upper']-v['lower'])/2)*(n/total) for v,n in zip(used,ns)) if len(cells)>1 and all(v['upper'] is not None for v in used) else None,p25_band=cells[a]['band_id'],median_band=cells[b]['band_id'],p75_band=cells[c]['band_id'],iqr_lower=0 if used[a]['upper'] is None else max(0,used[c]['lower']-used[a]['upper']),iqr_upper=None if used[c]['upper'] is None else used[c]['upper']-used[a]['lower'],modal_band=cells[ns.index(max(ns))]['band_id'])
def status(ns):
    if sum(ns)==0:return 'empty_source'
    if ns[0]>0:return 'usable_values'
    for i,label in enumerate(('usable_values','all_missing','all_unrecognised','all_conflicting')):
        if ns[i]==sum(ns):return label
    return 'no_usable_values'
def validate(row,s,k):
    try:
        if not isinstance(row,dict) or set(row)!=set(SCHEMA) or not integer(row['minimum_cell_count']) or row['minimum_cell_count']<k:return None
        if any(not isinstance(row[n],str) for n in ('collection_status','data_status','publication_status','summary_status','category_counts_json','numeric_groups_json')):return None
        if s['kind']=='categorical' and row['publication_status'] in {'needs_unit_evidence','needs_numeric_policy'}:return None
        if row['collection_status'] not in COLLECTION or row['data_status'] not in DATA or row['publication_status'] not in PUBLICATION:return None
        out=canonical(s,row['publication_status'] if row['collection_status']=='complete' else row['collection_status'],k,row['data_status'])
        meta=set(SCHEMA)-set(COUNTS+ESTIMATES+('category_counts_json','numeric_groups_json','band_level','summary_status'))
        if any(row[n]!=out[n] for n in meta):return None
        if row['publication_status']!='published' and row['data_status']=='unknown':
            if row['summary_status']!=out['summary_status'] or row['category_counts_json']!='[]' or row['numeric_groups_json']!='[]' or any(row[n] is not None for n in COUNTS+ESTIMATES+('band_level',)):return None
            return out
        ns=[row[n] for n in COUNTS]
        if not all(integer(n) for n in ns) or sum(ns[1:])!=ns[0] or not safe(ns[1:],ns[0],k) or row['data_status']!=status(ns[1:]) or row['collection_status']!='complete':return None
        if ns[1]==0:
            expected='needs_mapping' if row['data_status']=='all_unrecognised' else 'not_applicable'
            if row['publication_status']!=expected or row['summary_status']!=row['data_status'] or row['category_counts_json']!='[]' or row['numeric_groups_json']!='[]' or any(row[n] is not None for n in ESTIMATES+('band_level',)):return None
            out.update({n:row[n] for n in COUNTS});out['summary_status']=row['data_status'];return out
        if row['publication_status']!='published' or row['summary_status']!='published':return None
        numeric=s['kind']=='numeric';raw=row['numeric_groups_json' if numeric else 'category_counts_json'];key='band_id' if numeric else 'code'
        if not isinstance(raw,str) or len(raw.encode('utf-8'))>65536:return None
        cells=decode(raw)
        if not isinstance(cells,list) or not 1<=len(cells)<=1000 or any(not isinstance(c,dict) or set(c)!={key,'n'} or not isinstance(c[key],str) or not integer(c['n']) or c['n']<=0 for c in cells):return None
        ids=[c[key] for c in cells]
        if len(set(ids))!=len(ids):return None
        if numeric:
            if not s.get('binding') or row['category_counts_json']!='[]' or not integer(row['band_level']):return None
            p=s['binding']['policy'];level=int(row['band_level'])
            if level>=len(p['levels']) or ns[1]<p['minimum_people']:return None
            bs=bands(p,level);allowed=[b['id'] for b in bs]
        else:
            if row['numeric_groups_json']!='[]' or any(row[n] is not None for n in ESTIMATES+('band_level',)):return None
            allowed=[c['code'] for c in s['codes']]
        if any(id not in allowed for id in ids):return None
        cells.sort(key=lambda c:allowed.index(c[key]));counts=[c['n'] for c in cells]
        if sum(counts)!=ns[1] or not safe(counts,ns[0],k) or not safe(counts,ns[1],k):return None
        if numeric:
            est=estimates(cells,bs)
            for n,value in est.items():
                actual=row[n]
                if value is None:
                    if actual is not None:return None
                elif isinstance(value,str):
                    if not isinstance(actual,str) or actual!=value:return None
                elif not number(actual) or abs(actual-value)>max(1,abs(value))*1e-12:return None
            out.update(est);out['band_level']=level
        out['numeric_groups_json' if numeric else 'category_counts_json']=json.dumps(cells,ensure_ascii=False,separators=(',',':'))
        out.update({n:row[n] for n in COUNTS});return out
    except (KeyError,TypeError,ValueError,OverflowError,RecursionError):return None
def guard(rows,root,k,audit=False):
    from registry_summary_privacy import _identity,_k
    fields=policy(root);out=[];errors=[];ids=[_identity(r) for r in rows];seen=set()
    for i,row in enumerate(rows):
        id=ids[i];s=fields.get(id)
        if not s:errors.append(f'registry_field_summaries.{i}.invalid_v2_contract');continue
        threshold=max(_k(r,k) for r in rows if _identity(r)==id)
        candidate=dict(row)
        if not audit and integer(candidate.get('minimum_cell_count')) and candidate['minimum_cell_count']>=5:candidate['minimum_cell_count']=threshold
        checked=validate(candidate,s,threshold) if ids.count(id)==1 else None
        if checked is None:errors.append(f'registry_field_summaries.{i}.invalid_v2_contract')
        if id not in seen:out.append(checked or canonical(s,'invalid_contract',threshold));seen.add(id)
    return errors if audit else out

def public_resource(root):
    from registry_summary_privacy import registry_summary_policy
    legacy=registry_summary_policy(root)
    fields=policy(root);out=[]
    for s in fields.values():
        f={k:s[k] for k in (*META,'mapping_status','codes')}
        f['mapping_lineage']=[{k:m[k] for k in ('table_name','source_column','raw_token','canonical_token','normalisation','evidence_tier','evidence_row','evidence_checksum','review_status','evidence_key','caveat')} for m in s['mappings']]
        f['legacy_categories']=legacy[(s['table_name'],s['source_column'])]['categories']
        if s.get('binding'):
            f['binding']={'policy':s['binding']['policy'],'evidence':{k:s['binding']['evidence'][k] for k in ('unit_code','stored_to_display_multiplier','stored_to_display_offset','evidence_id','evidence_checksum','binding_checksum')}}
        out.append(f)
    return {'version':'registry-summary-v2','checksum':next(iter(fields.values()))['policy_checksum'] if fields else None,'fields':out}
