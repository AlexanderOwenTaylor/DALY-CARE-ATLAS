"""Public allowlist, checksums and independently staged ZIP publication."""
import hashlib, json, os, re, zipfile, tempfile
from pathlib import Path

def loading_budget(stage,directory):
    """Account for actual emitted classic-script dependencies through first results."""
    common=['DALYCARE_clinical.html','atlas-shell.css','DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js','atlas-topic.js','atlas-topic.css','favicon.svg']
    # Conservatively charge the largest route module, while the runtime loads one.
    route_bytes=max((p.stat().st_size for p in stage.glob('atlas-route-*.js')),default=0)
    size=lambda names:sum((stage/name).stat().st_size for name in set(names+['favicon.svg']))+(route_bytes if 'atlas-topic.js' in names else 0)
    routes=[dict(route='home',bytes=size(['DALYCARE_atlas.html','atlas-pages.css','DALYCARE_entry.js','atlas-entry.js'])),dict(route='clinical topic',bytes=size(common)),dict(route='clinical source membership',bytes=size(common+['DALYCARE_membership.js']))]
    descriptors={}
    for entry in directory['tables']:
        table=json.loads((stage/entry['descriptor']).read_text(encoding='utf-8').split('registerDescriptor(',1)[1].removesuffix(');\n'))['table']
        descriptors[table['id']]=(entry,table)
        deps=common+[entry['descriptor']];shards=table['shards']
        if table['id']=='registry_field_summaries':deps+=['registry-v2.js']
        count=0;page_bytes=0;page_limit=131072 if table['id']=='registry_field_summaries' else 262144
        for s in shards:
            charge=(stage/s['src']).stat().st_size
            if count>=50 or (page_bytes and page_bytes+charge>page_limit):break
            deps.append(s['src']);count+=s['rows'];page_bytes+=charge
        routes.append(dict(route='table='+table['id'],bytes=size(deps)))
        # A scoped non-locator scan may inspect nonmatching shards up to its
        # byte allowance. Charge that complete prefix, not merely 50 rows.
        if table.get('provenance')!='project_reference' and table['id'] not in ('column_profiles','registry_field_summaries','npu_reference_search'):
            filtered=common+[entry['descriptor']];charged=0
            for shard in shards:
                amount=(stage/shard['src']).stat().st_size
                if charged and charged+amount>page_limit:break
                filtered.append(shard['src']);charged+=amount
            routes.append(dict(route='source-filtered bounded scan='+table['id'],bytes=size(filtered)))

        if table['id'] in ('column_profiles','registry_field_summaries') and shards:
            scoped=common+[entry['descriptor']]+(['registry-v2.js'] if table['id']=='registry_field_summaries' else [])
            routes.append(dict(route=table['id']+' exact field detail (largest shard)',bytes=size(scoped)+max((stage/s['src']).stat().st_size for s in shards)))
            sources={pair[0] for s in shards for pair in s.get('fields',[])}
            for source in sources:
                deps=scoped[:];count=0;page_bytes=0
                for s in shards:
                    n=sum(pair[0]==source for pair in s.get('fields',[]))
                    if n and count<50:
                        charge=(stage/s['src']).stat().st_size
                        if page_bytes and page_bytes+charge>page_limit:break
                        deps.append(s['src']);count+=n;page_bytes+=charge
                routes.append(dict(route='source field first page',bytes=size(deps)))
    if all(k in descriptors for k in ('npu_reference_search','npu_display_dictionary')):
        search,reference=descriptors['npu_reference_search'],descriptors['npu_display_dictionary']
        deps=common+[search[0]['descriptor'],reference[0]['descriptor']]
        definitions={s['id']:s for s in reference[1]['shards']}
        pairs=[size(deps+[s['src'],definitions[key]['src']]) for s in search[1]['shards'] for key in s.get('definitions',[])]
        routes.append(dict(route='selected NPU item (largest actual dependency pair)',bytes=max(pairs,default=size(deps))))
    exceeded=next((r for r in routes if r['bytes']>524288),None)
    if exceeded:raise ValueError('Cold route dependency byte budget exceeded: '+exceeded['route']+' '+str(exceeded['bytes']))
    result=dict(schema_version=1,build_id=directory['build_id'],limit=524288,accounting='Emitted bytes without gzip or cache credit; explicit later search/detail transfers excluded',routes=routes)
    (stage/'loading-budget.json').write_text(json.dumps(result,separators=(',',':'))+'\n',encoding='utf-8')
    return result

def publication_outcomes(summary):
    outcomes={phase:'unknown' for phase in ('collection','interpretation')}
    for phase in outcomes:
        values=[row.get('value') for row in summary if row.get('metric')==phase+'_status']
        if len(values)==1 and values[0] in ('complete','partial','failed','not_started','running'):outcomes[phase]=values[0]
    outcomes['website']='complete'
    return outcomes

def public_manifest(stage, build_id, run_id, policy, terminology, summary=()):
    files=[]
    for path in sorted(stage.rglob('*')):
        if path.is_symlink(): raise ValueError('Unsafe public linked asset')
        if path.is_file():
            data=path.read_bytes()
            files.append(dict(path=path.relative_to(stage).as_posix(),bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
    outcomes=publication_outcomes(summary)
    manifest=dict(schema_version=1,build_id=build_id,run_id=run_id,state='complete' if all(v=='complete' for v in outcomes.values()) else 'partial',outcomes=outcomes,privacy_policy_version=policy,terminology=terminology,files=files)
    (stage/'public-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    validate_site(stage)
    return manifest

def validate_site(site):
    site=Path(site); raw=(site/'public-manifest.json').read_bytes(); manifest=json.loads(raw)
    names=set()
    for item in manifest['files']:
        name=item['path']
        if not isinstance(name,str) or not re.fullmatch(r'[A-Za-z0-9_./-]+',name) or name.startswith('/') or '..' in name.split('/') or name in names or name=='public-manifest.json': raise ValueError('Unsafe public asset name')
        names.add(name);path=site/name
        if any(p.is_symlink() for p in [path,*path.parents]): raise ValueError('Unsafe public linked asset')
        data=path.read_bytes()
        if len(data)!=item['bytes'] or hashlib.sha256(data).hexdigest()!=item['sha256']: raise ValueError('Public asset checksum mismatch; rebuild from retained outputs')
    actual={p.relative_to(site).as_posix() for p in site.rglob('*') if p.is_file()}
    if actual!=names|{'public-manifest.json'}:raise ValueError('Unexpected public assets; rebuild from retained outputs')
    return manifest,raw

def package_site(site, destination=None):
    site=Path(site);manifest,raw=validate_site(site)
    destination=Path(destination) if destination else site.with_suffix('.zip')
    if destination.is_symlink():raise ValueError('Unsafe ZIP destination')
    fd,staged=tempfile.mkstemp(prefix='.atlas-zip-',suffix='.zip',dir=destination.parent);os.close(fd)
    try:
        with zipfile.ZipFile(staged,'w',zipfile.ZIP_DEFLATED) as z:
            for item in manifest['files']:z.write(site/item['path'],item['path'])
            z.writestr('public-manifest.json',raw)
        with zipfile.ZipFile(staged) as z:
            if len(z.namelist())!=len(set(z.namelist())) or set(z.namelist())!={f['path'] for f in manifest['files']}|{'public-manifest.json'}:raise ValueError('ZIP allowlist mismatch')
            for item in manifest['files']:
                data=z.read(item['path'])
                if len(data)!=item['bytes'] or hashlib.sha256(data).hexdigest()!=item['sha256']:raise ValueError('ZIP checksum mismatch')
            if z.read('public-manifest.json')!=raw:raise ValueError('ZIP manifest mismatch')
        os.replace(staged,destination)
        return destination
    finally:
        if os.path.exists(staged):os.unlink(staged)
