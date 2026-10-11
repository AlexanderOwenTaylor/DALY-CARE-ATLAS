const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8');
function runtime(){
  const entries=[
    {kind:'code',system:'SKS',code:'BWHA169',label:'Treatment with vinblastine'},
    {kind:'code',system:'ATC',code:'L01XE27',label:'Ibrutinib'},
    {kind:'code',system:'PATOBANK',code:'AEKI000',label:'Ki-67 recorded as 0%'},
    {kind:'field',system:'SP_SocialHX',code:'ryger',label:'Smoking status'},
    {kind:'field',system:'another_source',code:'ryger',label:'Different source field'},
    {kind:'gene',system:'Gene symbol',code:'TP53',label:'Tumor protein p53'},
    {kind:'gene',system:'Gene symbol',code:'PLCG2',label:'Phospholipase C gamma 2'},
    ...Array.from({length:51},(_,i)=>({kind:'term',system:'Glossary',code:'TERM'+i,label:'Term '+i}))
  ];
  const payload={clinical_display_dictionary:entries,npu_display_dictionary:[{code:'NPU04998',label:'Creatinine',system:'Plasma',unit:'µmol/L'}],column_profile_rows:[{table_name:'SP_SocialHX',column_name:'ryger'}],patobank_ki67_percent:{code_counts:[{canonical_code:'AEKI000',parsed_percent:'0'}]}};
  const context=vm.createContext({payload,panels:{lab_npu_code_coverage:[{lab_code:'NPU04998'}],mm_treatment_code_counts:[{code_system:'SKS',code:'BWHA169'}]},labSearchKey:value=>String(value||'').toLowerCase(),labDisplayEntry:()=>({resolved:false}),sourceDisplayName:value=>value==='SP_SocialHX'?'Social history (SP)':value});
  vm.runInContext(html.slice(html.indexOf('function makeSearchResult('),html.indexOf('function buildGlobalSearchResults(')),context);
  for(const name of ['CLINICAL_TERMS','CLINICAL_GUIDE']) vm.runInContext(html.split(`/* ${name}_START */`)[1]?.split(`/* ${name}_END */`)[0]||'',context);
  return expression=>vm.runInContext(expression,context);
}
test('category browsing reaches every definition without duplicates or hidden last pages',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalGuidePage'),'function');
  assert.equal(run("clinicalGuidePage('','terms',0).total"),51);
  const codes=run("[0,1,2].flatMap(page=>clinicalGuidePage('','terms',page).rows.map(r=>r.code))");
  assert.equal(new Set(codes).size,51);
  assert.equal(codes.length,51);
  assert.equal(run("clinicalGuidePage('','terms',999).page"),2);
  assert.equal(run("clinicalGuidePage('nothing matches','terms',9).page"),0);
});
test('exact codes rank first and category filters apply to matching definitions',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalGuidePage'),'function');
  assert.equal(run("clinicalGuidePage('AEKI000','pathology',0).rows[0].label"),'Ki-67 recorded as 0%');
  assert.equal(run("clinicalGuidePage('AEKI000','treatment',0).total"),0);
  assert.equal(run("clinicalGuidePage('TERM1','terms',0).rows[0].code"),'TERM1');
});
test('data destinations require exact exported code-system or source-field evidence',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalGuideDestination'),'function');
  assert.equal(run("clinicalGuideDestination({kind:'code',system:'SKS',code:'BWHA169'}).tab"),'treatment');
  assert.equal(run("clinicalGuideDestination({kind:'code',system:'ATC',code:'BWHA169'})"),null);
  assert.equal(run("clinicalGuideDestination({kind:'code',system:'ATC',code:'L01XE27'})"),null);
  assert.equal(run("clinicalGuideDestination({kind:'field',system:'SP_SocialHX',code:'ryger'}).source"),'SP_SocialHX');
  assert.equal(run("clinicalGuideDestination({kind:'field',system:'another_source',code:'ryger'})"),null);
  assert.equal(run("clinicalGuideDestination({kind:'code',system:'PATOBANK',code:'AEKI000'}).sub"),'lab-pathology');
});
test('field search supports clinical names while preserving exact source identity',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalFieldMatches'),'function');
  assert.equal(run("clinicalFieldMatches({table_name:'SP_SocialHX',column_name:'ryger'},'smoking status')"),true);
  assert.equal(run("clinicalFieldMatches({table_name:'unknown',column_name:'ryger'},'smoking status')"),false);
  assert.equal(run("clinicalFieldMatches({table_name:'SP_SocialHX',column_name:'ryger'},'ryger')"),true);
});

test('guide filters distinguish linked definitions and exact field sources before paging',()=>{
  const run=runtime();
  assert.equal(run("clinicalGuideRows('','all',{scope:'linked'}).length"),4);
  assert.equal(run("clinicalGuideRows('','fields',{source:'SP_SocialHX'}).length"),1);
  assert.equal(run("clinicalGuideRows('','fields',{source:'SP_SocialHX'})[0].code"),'ryger');
  assert.equal(run("clinicalGuideRows('','fields',{source:'SP_SocialH'}).length"),0);
  assert.equal(run("clinicalGuideRows('','fields',{source:'another_source',scope:'linked'}).length"),0);
  assert.equal(run("clinicalGuideRows('','all',{scope:'reference'}).some(r=>r.code==='L01XE27')"),true);
  assert.equal(run("clinicalGuidePage('','fields',999,{source:'SP_SocialHX',scope:'linked'}).total"),1);
  assert.equal(run("clinicalGuidePage('','fields',999,{source:'SP_SocialHX',scope:'linked'}).page"),0);
});

test('laboratory reference cards retain specimen and terminology units separately from code system',()=>{
  const run=runtime();
  assert.equal(run("clinicalGuideSearch('NPU04998')[0].system"),'NPU');
  assert.equal(run("clinicalGuideSearch('NPU04998')[0].specimen"),'Plasma');
  assert.equal(run("clinicalGuideSearch('NPU04998')[0].unit"),'µmol/L');
});

test('field definitions can be found by readable source name',()=>{
  const run=runtime();
  assert.equal(run("clinicalGuideRows('social history','fields').length"),1);
  assert.equal(run("clinicalGuideRows('social history','fields')[0].system"),'SP_SocialHX');
});

test('global clinical field results retain their exact source and a distinct evidence label',()=>{
  const run=runtime();
  assert.equal(run('typeof clinicalTermSearchResult'),'function');
  const field=JSON.parse(run("JSON.stringify(clinicalTermSearchResult(clinicalDisplayEntry('field','SP_SocialHX','ryger'),'smoking'))"));
  assert.equal(field.group,'Source fields');
  assert.equal(field.source,'SP_SocialHX');
  assert.equal(field.query,'ryger');
  assert.equal(field.tab,'infrastructure');
  assert.equal(field.sub,'infra-columns');
  assert.equal(field.status,'Field listed in export');
  assert.match(field.description,/Social history/);
  assert.equal(run("clinicalTermSearchResult(clinicalDisplayEntry('field','SP_SocialHX','ryger'),'Smoking status').score"),1200);
  const reference=JSON.parse(run("JSON.stringify(clinicalTermSearchResult(clinicalDisplayEntry('field','another_source','ryger'),'ryger'))"));
  assert.equal(reference.tab,'dictionary');
  assert.equal(reference.status,'Reference meaning');
});

test('molecular symbols have a separate category and no inferred result',()=>{
  const run=runtime();
  assert.equal(run("clinicalGuideRows('','molecular').length"),2);
  assert.equal(run("clinicalGuideRows('','molecular',{scope:'linked'}).length"),0);
  assert.equal(run("clinicalGuideDestination({kind:'gene',system:'Gene symbol',code:'TP53'})"),null);
});

test('same-named field results from different sources remain separate choices',()=>{
  const context=vm.createContext({normalizeSearchText:value=>String(value||'').toLowerCase()});
  vm.runInContext(html.slice(html.indexOf('function dedupeSearchResults('),html.indexOf('function humanMetricLabel(')),context);
  const field={title:'Recorded result',description:'Result field',tab:'infrastructure',sub:'infra-columns',query:'value'};
  context.rows=[{...field,source:'source_A'},{...field,source:'source_B'},{...field,source:'source_A'}];
  assert.equal(vm.runInContext('dedupeSearchResults(rows).length',context),2);
});

test('legacy contrast-only rows cannot be counted as CT or MRI evidence',()=>{
  const context=vm.createContext({});
  vm.runInContext(html.split('/* IMAGING_CODE_IDENTITY_START */')[1].split('/* IMAGING_CODE_IDENTITY_END */')[0],context);
  assert.equal(vm.runInContext("imagingIsContrastOnly({raw_code:'UXZ11',clinical_concept_id:'imaging_mri'})",context),true);
  assert.equal(vm.runInContext("imagingIsContrastOnly({raw_value:'UXZ10',clinical_concept_id:'imaging_ct'})",context),true);
  assert.equal(vm.runInContext("imagingIsContrastOnly({raw_code:'UXZ110'})",context),false);
  assert.equal(vm.runInContext("imagingIsContrastOnly({raw_code:'UXCC00'})",context),false);
  assert.equal(vm.runInContext("typeof imagingIsNonModalityCode",context),'function');
  assert.equal(vm.runInContext("imagingIsNonModalityCode({code:'APAA4',clinical_concept_id:'imaging_ct'})",context),true);
  assert.equal(vm.runInContext("imagingIsNonModalityCode({code:'UXZ11'})",context),true);
  assert.equal(vm.runInContext("imagingIsNonModalityCode({code:'APAA40'})",context),false);
  assert.equal(vm.runInContext("imagingIsNonModalityCode({code:'UXCD15'})",context),false);
});

test('legacy staff codes are excluded from imaging coverage and layer distributions',()=>{
  const rows=['APAA4','UXCC00','UXZ10'].map(code=>({raw_code:code,panel_id:'clinical_imaging',clinical_concept_id:'imaging_ct'}));
  const context=vm.createContext({panelRawFieldRows:rows,panelDistributionRows:rows,isDaMyDaImagingRegistryRow:()=>false,imagingIsDateLike:()=>false,imagingIsFreeText:()=>false,imagingSafeLabel:row=>row.raw_code,numberValue:value=>Number(value)||0});
  vm.runInContext(html.split('/* IMAGING_CODE_IDENTITY_START */')[1].split('/* IMAGING_CODE_IDENTITY_END */')[0],context);
  vm.runInContext(html.slice(html.indexOf('function imagingAllRawRows()'),html.indexOf('function imagingFallbackRows(')),context);
  for(const expression of ['imagingAllRawRows()','imagingPanelDistributionRows()']) {
    assert.equal(vm.runInContext(`JSON.stringify(${expression}.map(row=>row.raw_code))`,context),JSON.stringify(['UXCC00','UXZ10']));
  }
});

test('additional imaging hits cannot present an old staff-to-CT mapping',()=>{
  const output={};
  const context=vm.createContext({semanticRows:[{raw_code:'APAA4',clinical_group:'Imaging',clinical_variable:'CT imaging signal'},{raw_code:'UXCC00',clinical_group:'Imaging',clinical_variable:'CT imaging signal'}],deferRender:(_id,render)=>render(),setHtml:(id,value)=>output[id]=value,escapeHtml:value=>value,semanticRawName:row=>row.raw_code});
  vm.runInContext(html.split('/* IMAGING_CODE_IDENTITY_START */')[1].split('/* IMAGING_CODE_IDENTITY_END */')[0],context);
  vm.runInContext(html.slice(html.indexOf('function renderSemanticLineageBlocks()'),html.indexOf('fillSelect("semantic-group-filter"')),context);
  vm.runInContext('renderSemanticLineageBlocks()',context);
  assert.equal(output['semantic-clinical-imaging'].includes('APAA4'),false);
  assert.equal(output['semantic-clinical-imaging'].includes('UXCC00'),true);
});
