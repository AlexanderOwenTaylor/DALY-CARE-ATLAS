"""Complete public runtime fixture; never copy runs, archives or private logs."""
import shutil
import json
def copy_runtime_fixture(root,destination):
    destination.mkdir(parents=True,exist_ok=True)
    for name in ('scripts','R','inst','config'):
        shutil.copytree(root/name,destination/name,dirs_exist_ok=True,ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
    for name in ('DESCRIPTION','NAMESPACE','LICENSE'):
        shutil.copyfile(root/name,destination/name)

def public_catalogue(site):
    return json.loads((site/'DALYCARE_output_catalogue.js').read_text(encoding='utf-8').split('=',1)[1].strip().removesuffix(';'))

def public_rows(site,table_id):
    table=next(t for t in public_catalogue(site)['tables'] if t['id']==table_id)
    rows=[]
    for shard in table['shards']:
        script=(site/shard['src']).read_text(encoding='utf-8')
        wire=json.loads(script.split('register(',1)[1].removesuffix(');\n'))
        rows.extend(json.loads(wire['rows_json']))
    return rows
