import copy, importlib.util, json, os, shutil, subprocess, sys, tempfile, unittest
import unittest.mock
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from public_privacy import sanitize_public_payload, audit_public_payload

SPEC = importlib.util.find_spec('registry_summary_privacy')
MODULE = __import__('registry_summary_privacy') if SPEC else None

class RegistryPrivacyTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(MODULE, 'registry contract validator must exist')
        policy = json.loads((ROOT / 'inst/config/registry-summary-policy.json').read_text(encoding='utf-8-sig'))
        self.policy = policy
    def row(self, kind='categorical'):
        field = next(f for f in self.policy['fields'] if f['kind'] == kind and (kind == 'numeric' or len(f['categories']) > 1))
        row = {key: None for key in MODULE.SCHEMA}
        row.update({key: field[key] for key in ('table_name','source_column','kind','topic','phase','label')})
        row.update(contract_version='registry-summary-v1',unit_status='unverified',count_basis='distinct_people_one_unambiguous_value_per_field',summary_method='exact_complete_field_3sf',summary_status='published',minimum_cell_count=5,denominator_n=40,n_valid=30,n_missing=5,n_invalid=5,n_conflicting=0,category_counts_json='[]')
        if kind == 'categorical': row['category_counts_json']=json.dumps([{'code':field['categories'][0],'n':15},{'code':field['categories'][1],'n':15}],separators=(',',':'))
        else: row.update(n_distinct=3,minimum_value_support=10,mean=2,median=2,p25=1,p75=3)
        return row
    def guard(self, rows, k=5): return MODULE.sanitize_registry_summaries(rows, ROOT, k)
    def assertWithheld(self, rows, k=5):
        out=self.guard(rows,k)
        self.assertEqual(len(out),1)
        self.assertNotEqual(out[0]['summary_status'],'published')
        for key in MODULE.COUNTS+MODULE.STATS: self.assertIsNone(out[0].get(key),key)
        self.assertEqual(out[0]['category_counts_json'],'[]')
        self.assertEqual(out,self.guard(out,k))
        self.assertEqual(MODULE.audit_registry_summaries(out,ROOT,k),[])
        return out
    def test_contract_publishes_and_is_idempotent(self):
        for kind in ('categorical',):
            row=self.row(kind); out=self.guard([row])
            self.assertEqual(out[0]['summary_status'],'published')
            self.assertEqual(out,self.guard(out))
            self.assertEqual(MODULE.audit_registry_summaries(out,ROOT),[])
    def test_full_schema_and_partition_fail_closed(self):
        cases=[dict(n_valid=29),dict(n_missing=1,denominator_n=36),dict(n_invalid=-1),dict(n_missing=1.5),dict(n_valid=True),dict(summary_status='forged'),dict(summary_status=['published']),dict(contract_version='registry-summary-v2'),dict(raw_value='FORBIDDEN'),dict(kind='numeric'),dict(minimum_cell_count=1),dict(minimum_cell_count=5.9),dict(unit_status='verified'),dict(count_basis='source_rows'),dict(summary_method='top_n')]
        for change in cases:
            with self.subTest(change=change):
                row=self.row(); row.update(change); self.assertWithheld([row]); self.assertTrue(MODULE.audit_registry_summaries([row],ROOT))
        row=self.row(); del row['n_conflicting']; self.assertWithheld([row])
    def test_categories_are_complete_bounded_allowlisted(self):
        row=self.row(); codes=json.loads(row['category_counts_json'])
        cases=['[',json.dumps(codes[:1]),json.dumps(codes+[codes[0]]),json.dumps([dict(code='FORBIDDEN',n=30)]),json.dumps([dict(code=codes[0]['code'],n=1),dict(code=codes[1]['code'],n=29)]),json.dumps([dict(code=codes[0]['code'],n=30,extra='FORBIDDEN')]),json.dumps([dict(code=codes[0]['code'],n='30')]),'[{'+'"code":'+json.dumps(codes[0]['code'])+',"n":1,"n":30}]',' '*100000+'[]']
        for value in cases:
            with self.subTest(value=value[:100]): self.assertWithheld([dict(row,category_counts_json=value)])
    def test_numeric_safety(self):
        for change in (dict(n_valid=19,denominator_n=29),dict(n_distinct=1),dict(n_distinct=27),dict(minimum_value_support=4),dict(minimum_value_support=20),dict(mean=-1),dict(mean=float('nan')),dict(mean=float('inf')),dict(p25=3,median=2),dict(median=4,p75=3),dict(category_counts_json='[{"code":"FORBIDDEN","n":30}]')):
            with self.subTest(change=change): self.assertWithheld([dict(self.row('numeric'),**change)])
    def test_legacy_numeric_precision_cannot_authorise_publication(self):
        row=dict(self.row('numeric'),mean=987654.125)
        out=self.guard([row]); self.assertIsNone(out[0]['mean'])
        self.assertTrue(MODULE.audit_registry_summaries([row],ROOT))
        self.assertEqual(MODULE.audit_registry_summaries(out,ROOT),[])
    def test_unknown_identity_duplicate_and_status_data(self):
        row=self.row(); self.assertEqual(self.guard([dict(row,source_column='FORBIDDEN')]),[])
        self.assertWithheld([row,dict(row,summary_status='query_failed')])
        self.assertWithheld([row,row])
        out=self.assertWithheld([dict(row,summary_status='query_failed')]); self.assertEqual(out[0]['summary_status'],'query_failed')
        self.assertTrue(MODULE.audit_registry_summaries([dict(row,summary_status='query_failed')],ROOT))
    def test_metadata_regenerated_threshold_never_lowered(self):
        row=self.row(); out=self.guard([dict(row,label='FORBIDDEN',topic='FORBIDDEN',phase='FORBIDDEN')])
        self.assertEqual(out[0]['label'],row['label']); self.assertEqual(out[0]['topic'],row['topic'])
        self.assertWithheld([row],10)
        self.assertWithheld([dict(row,minimum_cell_count=10)])
        with unittest.mock.patch.dict(os.environ,{'DALYCARE_MIN_CELL_COUNT':'10'}): self.assertWithheld([row])
        payload={'privacy_metadata':{'minimum_cell_count':10},'panels':{'registry_field_summaries':[row]}}
        out=sanitize_public_payload(payload,project_root=ROOT)
        self.assertNotEqual(out['panels']['registry_field_summaries'][0]['summary_status'],'published')
        self.assertEqual(out['panels']['registry_field_summaries'][0]['minimum_cell_count'],10)
    def test_generic_paths_and_forged_marker(self):
        row=self.row('numeric')
        payload={'panels':{'registry_field_summaries':[row]},'review_registry':{'registry_field_summaries':[row]},'evidence':{'restored':{'registry_field_summaries':[row]}}}
        out=sanitize_public_payload(payload,project_root=ROOT)
        self.assertIsNone(out['panels']['registry_field_summaries'][0]['mean'])
        self.assertEqual(out,sanitize_public_payload(out,project_root=ROOT)); self.assertEqual(audit_public_payload(out,project_root=ROOT),[])
        out['panels']['registry_field_summaries'][0]['n_missing']=1
        self.assertTrue(audit_public_payload(out,project_root=ROOT))
        forged=dict(row,value='FORBIDDEN',n=30)
        other=sanitize_public_payload({'column_top_value_rows':[forged]})
        self.assertIsNone(other['column_top_value_rows'][0].get('value')); self.assertIsNone(other['column_top_value_rows'][0].get('mean'))
        self.assertNotIn('FORBIDDEN',json.dumps(other));self.assertEqual(other['column_top_value_rows'][0]['summary_status'],'invalid_contract')
    def test_r_python_parity_adversarial(self):
        rscript=Path(os.environ.get('RSCRIPT') or shutil.which('Rscript') or 'C:/Program Files/R/R-4.3.1/bin/Rscript.exe')
        self.assertTrue(rscript.is_file(),'R runtime is required for adversarial parity')
        rows=[self.row(),self.row('numeric')]
        cases=[rows,[dict(rows[0],n_valid=29)],[dict(rows[1],mean=-1)],[rows[0],dict(rows[0],summary_status='query_failed')],[dict(rows[0],extra='FORBIDDEN')],[dict(rows[0],category_counts_json='[')]]
        for change in (dict(n_valid=True),dict(n_missing=1.5),dict(n_valid=29),dict(summary_status=['published']),dict(minimum_cell_count=10),dict(unit_status='verified'),dict(minimum_cell_count=5.9)):
            cases.append([dict(rows[0],**change)])
        for change in (dict(n_distinct=1),dict(n_distinct=27),dict(minimum_value_support=4),dict(minimum_value_support=20),dict(p25=3,median=2),dict(n_missing=0,n_invalid=0,denominator_n=30),dict(mean=987654.125)):
            cases.append([dict(rows[1],**change)])
        with tempfile.TemporaryDirectory(dir=ROOT/'.artifact-temp') as temp:
            input_path=Path(temp)/'input.json'; output_path=Path(temp)/'output.json'
            input_path.write_text(json.dumps(cases),encoding='utf-8')
            env=dict(os.environ,TEMP=temp,TMP=temp,TMPDIR=temp)
            if os.name=='nt':
                env.setdefault('LC_ALL','English_United States.utf8')
                libs=Path('C:/Users/User/AppData/Local/R/win-library/4.3')
                if libs.is_dir():env.setdefault('R_LIBS_USER',str(libs))
            run=subprocess.run([str(rscript),str(ROOT/'tests/test-registry-summary-privacy.R'),str(input_path),str(output_path)],cwd=ROOT,env=env,capture_output=True,text=True)
            self.assertEqual(run.returncode,0,run.stdout+run.stderr)
            rout=json.loads(output_path.read_text())
            self.assertEqual(rout,[self.guard(case) for case in cases])

if __name__=='__main__':
    unittest.main()
