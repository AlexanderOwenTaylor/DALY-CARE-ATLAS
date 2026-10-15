"""The R and Python publishers charge the complete bounded filtered prefix."""
import json, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from publication import loading_budget

class FilteredBudget(unittest.TestCase):
 def test_filtered_prefix_charges_more_than_first_fifty_rows_in_both_publishers(self):
  with tempfile.TemporaryDirectory() as tmp:
   stage=Path(tmp)
   for name in ('DALYCARE_clinical.html','atlas-shell.css','DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js','atlas-topic.js','atlas-topic.css','DALYCARE_atlas.html','atlas-pages.css','DALYCARE_entry.js','atlas-entry.js','DALYCARE_membership.js','favicon.svg','atlas-route-sources.js'):
    (stage/name).write_bytes(b'x'*100)
   (stage/'table-descriptors').mkdir();(stage/'output-shards').mkdir()
   shards=[]
   for i in range(3):
    name='output-shards/scoped-'+str(i)+'.js';(stage/name).write_bytes(b'x'*100000)
    shards.append(dict(id='s'+str(i),src=name,rows=250,bytes=99900,asset_bytes=100000))
   descriptor='table-descriptors/scoped.js'
   (stage/descriptor).write_text('window.DALYCARE_OUTPUTS.registerDescriptor('+json.dumps(dict(table=dict(id='scoped',provenance='run_output',shards=shards)))+');\n',encoding='utf-8')
   directory=dict(build_id='budget',tables=[dict(id='scoped',descriptor=descriptor)])
   result=loading_budget(stage,directory)
   values={r['route']:r['bytes'] for r in result['routes']}
   self.assertEqual(values['source-filtered bounded scan=scoped']-values['table=scoped'],100000)
   self.assertLessEqual(max(values.values()),524288)
   rscript=os.environ.get('RSCRIPT') or shutil.which('Rscript')
   if not rscript and os.name=='nt':
    candidates=list(Path('C:/Program Files/R').glob('*/bin/Rscript.exe'))
    if candidates:rscript=str(sorted(candidates)[-1])
   self.assertIsNotNone(rscript,'R runtime is required for publisher budget parity')
   (stage/'directory.json').write_text(json.dumps(directory),encoding='utf-8')
   driver=stage/'budget.R'
   driver.write_text("source('R/site_bundle.R');source('R/publication.R');stage<-"+json.dumps(stage.as_posix())+";atlas_loading_budget(stage,jsonlite::fromJSON(file.path(stage,'directory.json'),simplifyVector=FALSE))",encoding='utf-8')
   subprocess.run([rscript,str(driver)],cwd=ROOT,check=True,capture_output=True,text=True)
   other=json.loads((stage/'loading-budget.json').read_text(encoding='utf-8'))
   self.assertEqual(other,result)

if __name__=='__main__':unittest.main()
