const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'inst/templates/DALYCARE_atlas.html'), 'utf8');
const block = html.split('/* CLINICIAN_DISPLAY_START */')[1]?.split('/* CLINICIAN_DISPLAY_END */')[0] || '';
function runtime() {
  const context = vm.createContext({
    payload: { npu_display_dictionary: [
      { code: 'NPU02593', label: 'Leukocytes', label_da: 'Leukocytter;B', system: 'Blood', unit: '× 109/L' },
      { code: 'NPU04998', label: 'Creatinine', label_da: 'Kreatinin;P', system: 'Plasma', unit: 'µmol/L' },
      { code: 'NPU09102', label: 'Creatinine', system: 'Urine', unit: 'mmol/L' }
    ], canonical_resource_reconciliation_rows: [
      {current_resolved_table_or_view: 'custom_exact_source', display_name: 'Documented source title'},
      {expected_resource_id: 'Flowcytometry', current_resolved_table_or_view: null, display_name: 'Flow cytometry'}
    ], domain_panel_rows: [
      {panel_id: 'clinical_adt', panel_title: 'ADT', clinical_purpose: 'Admission, discharge and transfer signals.'},
      {panel_id: 'laboratory_npu', panel_title: 'Laboratory/NPU', clinical_purpose: 'Laboratory evidence.'}
    ] },
    panels: { lab_npu_code_coverage: [
      { lab_code: 'NPU02593', table_name: 'SP_AlleProvesvar', n: 12 },
      { lab_code: 'NPU02593', table_name: 'SDS_lab_forsker', n: 0 },
      { lab_code: 'NPU04998', table_name: 'SP_AlleProvesvar', n: 9 },
      { lab_code: 'NPU99999', table_name: 'SP_AlleProvesvar', n: 6 },
      { lab_code: 'NPU09102', table_name: 'SP_AlleProvesvar', n: 3 }
    ] }
  });
  vm.runInContext(block, context);
  return expression => vm.runInContext(expression, context);
}
test('Danish and English searches return the same source-scoped evidence', () => {
  const run = runtime();
  assert.equal(run("typeof labSearchRows"), 'function', 'Missing label search');
  assert.equal(run("labSearchRows('leukocytes').length"), 2);
  assert.equal(run("labSearchRows('Leukocytter').length"), 2);
  assert.equal(run("labSearchRows('NPU02593')[1].n"), 0);
  assert.equal(run("labSearchRows('kreatinin')[0].lab_code"), 'NPU04998');
});

test('spaced NPU codes resolve to an exact test without matching longer codes', () => {
  const run = runtime();
  assert.equal(run("labSearchRows('npu 04998').length"), 1);
  assert.equal(run("labSearchRows('npu-04998')[0]?.lab_code"), 'NPU04998');
});

test('specimen filters separate identically named tests and ordering preserves zero counts', () => {
  const run = runtime();
  assert.equal(run("labSearchRows('creatinine', '', '', {specimen:'Urine'}).length"), 1);
  assert.equal(run("labSearchRows('creatinine', '', '', {specimen:'Urine'})[0].lab_code"), 'NPU09102');
  assert.equal(run("labSearchRows('', '', '', {sort:'name'})[0].lab_code"), 'NPU04998');
  assert.equal(run("labSearchRows('', '', '', {sort:'records'}).at(-1).n"), 0);
});

test('source names use exact documented mappings while unknown identifiers stay recognizable', () => {
  const run = runtime();
  assert.equal(run("sourceDisplayName('SP_AdministreretMedicin')"), 'Administered medicines (SP)');
  assert.equal(run("sourceDisplayName('custom_exact_source')"), 'Documented source title');
  assert.equal(run("sourceDisplayName('Flowcytometry')"), 'Flow cytometry');
  assert.equal(run("sourceDisplayName('custom_exact_source_other')"), 'custom exact source other');
});

test('clinical topic directory uses only exported panels and routes clinical questions correctly', () => {
  const run = runtime();
  assert.equal(run("typeof clinicalTopicSearch"), 'function');
  assert.equal(run("clinicalTopicSearch('').length"), 2);
  assert.equal(run("clinicalTopicSearch('admissions')[0]?.sub"), 'clinical-admissions');
  assert.equal(run("clinicalTopicSearch('kreatinin')[0]?.sub"), 'lab-npu');
  assert.equal(run("clinicalTopicSearch('nonexistent clinical test').length"), 0);
});
test('unknown codes remain unresolved and exact code identity is preserved', () => {
  const run = runtime();
  assert.equal(run("typeof labDisplayEntry"), 'function', 'Missing exact code lookup');
  assert.equal(run("labDisplayEntry('NPU02593').label"), 'Leukocytes');
  assert.equal(run("labDisplayEntry('NPU99999').resolved"), false);
  assert.equal(run("labSearchRows('NPU99999').length"), 1);
  assert.equal(run("labDisplayEntry('NPU025930').resolved"), false);
});
