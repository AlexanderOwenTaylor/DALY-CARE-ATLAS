const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8');
const block = html.split('/* CLINICAL_TERMS_START */')[1]?.split('/* CLINICAL_TERMS_END */')[0] || '';
function runtime() {
  const context = vm.createContext({payload:{clinical_display_dictionary:[
    {kind:'code',system:'SKS',code:'BWHA402',label:'Bortezomib treatment',definition:'Treatment procedure code.'},
    {kind:'registry_value',system:'RKKP_LYFO:subtype',code:'DLBCL',label:'Diffuse large B-cell lymphoma'},
    {kind:'field',system:'RKKP_CLL',code:'Reg_Umuteret',label:'IGHV mutation-status field'},
    {kind:'field',system:'RKKP_DaMyDa',code:'Reg_LDH',label:'Lactate dehydrogenase (LDH)'},
    {kind:'laboratory_group',system:'Atlas',code:'FLC_RATIO_U_CODES',label:'Urine free light-chain ratio'},
    {kind:'term',system:'Glossary',code:'MRD',label:'Measurable residual disease',definition:'Disease remaining after treatment.'}
  ]},labDisplayEntry:code=>({label:'Creatinine',code,resolved:code==='NPU04998'}),
  labSearchKey:value=>String(value||'').toLowerCase(),sourceDisplayName:value=>value});
  vm.runInContext(block,context);
  return expression=>vm.runInContext(expression,context);
}
test('procedure translations require the exact coding system and whole code',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalDisplayEntry'),'function');
  assert.equal(run("clinicalDisplayEntry('code','SKS','BWHA402').label"),'Bortezomib treatment');
  assert.equal(run("clinicalDisplayEntry('code','ATC','BWHA402')"),null);
  assert.equal(run("clinicalDisplayEntry('code','SKS','BWHA4029')"),null);
});
test('registry abbreviations stay source scoped and unknown meanings stay explicit',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalRegistryLabel'),'function');
  assert.equal(run("clinicalRegistryLabel({table_name:'RKKP_LYFO',source_column:'subtype',label:'DLBCL'})"),'Diffuse large B-cell lymphoma');
  assert.equal(run("clinicalRegistryLabel({table_name:'RKKP_LYFO',source_column:'subtype',label:'NK'})"),'Subtype code NK — meaning not verified');
  assert.equal(run("clinicalDisplayEntry('registry_value','RKKP_CLL:subtype','DLBCL')"),null);
});
test('raw yes/no indicators are not converted into biological mutation results',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalRegistryLabel'),'function');
  assert.equal(run("clinicalRegistryLabel({table_name:'RKKP_CLL',source_column:'Reg_Umuteret',label:'N'})"),'IGHV mutation-status field — No');
});
test('table labels retain original codes and zero values without changing the row',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalCellDisplay'),'function');
  assert.equal(run("JSON.stringify(clinicalCellDisplay({code_system:'SKS',code:'BWHA402'},'code'))"),JSON.stringify({label:'Bortezomib treatment',raw:'BWHA402'}));
  assert.equal(run("clinicalCellDisplay({n_rows:0},'n_rows').label"),'0');
  assert.equal(run("clinicalCellDisplay({table_name:'RKKP_DaMyDa',source_column:'Reg_LDH_extra'},'source_column').label"),'Reg_LDH_extra');
  assert.equal(run("clinicalCellDisplay({npu_code:'NPU04998'},'npu_code').raw"),'NPU04998');
});
test('clinical names and technical laboratory group identifiers find the same entry',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalTermSearch'),'function');
  assert.equal(run("clinicalTermSearch('urine light-chain')[0].code"),'FLC_RATIO_U_CODES');
  assert.equal(run("clinicalTermSearch('BWHA402')[0].label"),'Bortezomib treatment');
  assert.equal(run("clinicalTermSearch('bortezomib')[0].code"),'BWHA402');
  assert.equal(run("clinicalTermSearch('unknownword').length"),0);
});

test('terminology export follows the clinical query independently of legacy rows',()=>{
  const run=runtime();
  const exportBlock=html.slice(html.indexOf('function filteredRowsForExport('),html.indexOf('function rowsToCsv('));
  const context=vm.createContext({clinicalGuideFilters:()=>({scope:'all',source:''}),clinicalGuideRows:query=>JSON.parse(run(`JSON.stringify(clinicalTermSearch(${JSON.stringify(query)}))`)), document:{getElementById:()=>({value:'bortezomib'})}, appState:{}, clinicalConceptRows:[],semanticRows:[],semanticValueRows:[],semanticCodeRows:[],semanticPanelLinks:[],semanticOverlayRows:[],semanticConflictRows:[]});
  vm.runInContext(exportBlock,context);
  assert.equal(vm.runInContext("filteredRowsForExport('clinical-terms')[0]?.code",context),'BWHA402');
});

test('terminology export forwards the selected source and evidence scope without pagination',()=>{
  let received;
  const context=vm.createContext({clinicalGuideFilters:()=>({scope:'linked',source:'RKKP_DaMyDa'}),clinicalGuideRows:(...args)=>{received=args;return Array.from({length:28},(_,i)=>({code:'FIELD'+i}));},document:{getElementById:id=>({value:id==='semantic-code-search'?'planned treatment':'fields'})}});
  vm.runInContext(html.slice(html.indexOf('function filteredRowsForExport('),html.indexOf('function rowsToCsv(')),context);
  assert.equal(vm.runInContext("filteredRowsForExport('clinical-terms').length",context),28);
  assert.deepEqual(received,['planned treatment','fields',{scope:'linked',source:'RKKP_DaMyDa'}]);
});
