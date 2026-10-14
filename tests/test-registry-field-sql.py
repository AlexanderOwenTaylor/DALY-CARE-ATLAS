"""Execute producer-generated SQL against complete synthetic SQLite cohorts.
No individual patient records are fetched by the registry summary SQL.
"""
import csv,json,pathlib,sqlite3,os,shutil,subprocess
root=pathlib.Path(__file__).resolve().parents[1]
p=root/'.artifact-temp/registry-sql-fixtures'
# Regenerate SQL from the R producer on a clean checkout or after source changes.
producer=root/'R/registry_summaries.R'
needs_generate=not (p/'Stadie.sql').exists() or (p/'Stadie.sql').stat().st_mtime < producer.stat().st_mtime
if needs_generate:
 runtime=shutil.which('Rscript')
 if runtime is None and pathlib.Path('C:/Program Files/R/R-4.3.1/bin/Rscript.exe').exists():
  runtime='C:/Program Files/R/R-4.3.1/bin/Rscript.exe'
 if runtime is None: raise RuntimeError('Rscript is required to generate the actual producer SQL fixture')
 env=os.environ.copy()
 libs=pathlib.Path('C:/Users/User/AppData/Local/R/win-library/4.3')
 if libs.exists(): env.setdefault('R_LIBS_USER',str(libs))
 temp=root/'.artifact-temp/registry-temp';temp.mkdir(parents=True,exist_ok=True)
 for key in ('TEMP','TMP','TMPDIR'): env[key]=str(temp)
 env['LC_ALL']='English_United States.utf8' if os.name=='nt' else 'C.UTF-8'
 subprocess.run([runtime,'tests/test-registry-field-producer.R'],cwd=root,env=env,check=True)
conn=sqlite3.connect(':memory:')
conn.execute('create table cohort(secret_person text, Stadie text, Reg_Haemoglobin text)')
rows=list(csv.DictReader((p/'cohort.csv').open()))
base=[(r['secret_person'],r['Stadie'],r['Reg_Haemoglobin']) for r in rows]
queries={f.stem:f.read_text() for f in p.glob('*.sql')}
def load(cohort):
 conn.execute('delete from cohort')
 conn.executemany('insert into cohort values(?,?,?)',cohort)
def run(name):
 result=conn.execute(queries[name]).fetchall()
 assert all(len(row)==3 and row[0] in ('valid','missing','invalid','conflicting','key_missing') for row in result)
 assert all('private-' not in str(row) for row in result)
 return result
def counts(result): return {(s,v):n for s,v,n in result}
load(base)
assert counts(run('Stadie'))=={('valid','I'):20,('valid','II'):20}
assert counts(run('Reg_Haemoglobin'))=={('valid','1'):10,('valid','2'):10,('valid','3'):10,('valid','4'):10}
load(base+base)
assert counts(run('Stadie'))=={('valid','I'):20,('valid','II'):20}
load(base+[(r[0],'III','8') for r in base[:5]])
assert counts(run('Stadie'))=={('conflicting',''):5,('valid','I'):15,('valid','II'):20}
assert counts(run('Reg_Haemoglobin'))=={('conflicting',''):5,('valid','1'):5,('valid','2'):10,('valid','3'):10,('valid','4'):10}
load([(pid,st,('-1' if i<5 else 'Inf' if i<10 else val)) for i,(pid,st,val) in enumerate(base)])
assert counts(run('Reg_Haemoglobin'))=={('invalid',''):10,('valid','2'):10,('valid','3'):10,('valid','4'):10}
load([(pid,('arbitrary secret free text' if i==0 else st),val) for i,(pid,st,val) in enumerate(base)])
assert ('invalid','') in counts(run('Stadie'))
assert all('arbitrary' not in str(row) for row in run('Stadie'))
load([('',st,val) if i==0 else (pid,st,val) for i,(pid,st,val) in enumerate(base)])
assert counts(run('Stadie'))[('key_missing','')]==1
# Adjacent representable doubles must never collapse and conceal a rare tail.
load([(pid,st,('1.0000000000000002' if i==0 else '1' if i<20 else '2')) for i,(pid,st,val) in enumerate(base)])
rare_groups=run('Reg_Haemoglobin')
assert sorted(n for status,value,n in rare_groups)==[1,19,20], rare_groups
rare_path=p/'rare-double-groups.csv'
with rare_path.open('w',newline='') as f:
 writer=csv.writer(f);writer.writerow(['status','value','n']);writer.writerows(rare_groups)
# Revalidate those exact SQL results through the actual R producer gate.
runtime=shutil.which('Rscript') or ('C:/Program Files/R/R-4.3.1/bin/Rscript.exe' if pathlib.Path('C:/Program Files/R/R-4.3.1/bin/Rscript.exe').exists() else None)
if runtime is None: raise RuntimeError('Rscript required for SQL-to-producer rare-tail validation')
env=os.environ.copy(); libs=pathlib.Path('C:/Users/User/AppData/Local/R/win-library/4.3')
if libs.exists(): env.setdefault('R_LIBS_USER',str(libs))
temp=root/'.artifact-temp/registry-temp';temp.mkdir(parents=True,exist_ok=True)
for key in ('TEMP','TMP','TMPDIR'): env[key]=str(temp)
env['LC_ALL']='English_United States.utf8' if os.name=='nt' else 'C.UTF-8'
code="""source('R/registry_summaries.R'); source('R/registry_summary_privacy.R'); spec <- Filter(function(s) s$table_name=='RKKP_DaMyDa' && s$source_column=='Reg_Haemoglobin',registry_summary_policy('.'))[[1]]; groups <- read.csv('.artifact-temp/registry-sql-fixtures/rare-double-groups.csv',colClasses=c('character','character','numeric')); out <- registry_summary_from_groups(spec,groups,5); stopifnot(out$summary_status=='needs_unit_evidence',is.na(out$n_valid),is.na(out$mean)); cat('Adjacent-double SQL results withheld by R producer.\n')"""
r_gate=p/'verify-rare-double.R'; r_gate.write_text(code,encoding='utf-8')
subprocess.run([runtime,str(r_gate)],cwd=root,env=env,check=True)
# Real-typed SQLite values need round-trip formatting before CAST-to-text.
conn.execute('drop table cohort')
conn.execute('create table cohort(secret_person text, Stadie text, Reg_Haemoglobin real)')
load([(pid,st,(1.0000000000000002 if i==0 else 1.0 if i<20 else 2.0)) for i,(pid,st,val) in enumerate(base)])
assert sorted(n for status,value,n in run('Reg_Haemoglobin'))==[1,19,20]
# Recreate text fixture for remaining cap and complete tests.
conn.execute('drop table cohort')
conn.execute('create table cohort(secret_person text, Stadie text, Reg_Haemoglobin text)')
# Cap+1 deliberately returns incomplete grouped results, which R must withhold.
load(base)
q=queries['Reg_Haemoglobin'].replace('LIMIT 5001','LIMIT 3')
assert len(conn.execute(q).fetchall())==3
load(base)
for name in queries:
 result=run(name)
 with (p/(name+'-groups.csv')).open('w',newline='') as f:
  writer=csv.writer(f);writer.writerow(['status','value','n']);writer.writerows(result)
print('SQLite generated-SQL fixtures passed: complete counts, repeated values, conflicts, negative/Inf, unknown category, missing keys, and cardinality cap.')
