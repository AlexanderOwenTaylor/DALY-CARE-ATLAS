const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
const payload=require('./fixtures/synthetic-ui-payload.cjs').createSyntheticPayload();
function load(start,end,ctx){const a=html.indexOf(start),b=html.indexOf(end,a);assert.ok(a>=0&&b>a);vm.runInContext(html.slice(a,b),ctx);}
function runtime(extra={}){
  const output={},nodes={};
  const node=id=>nodes[id]||=( {value:'',textContent:'',innerHTML:'',options:[],listeners:{},addEventListener(event,handler){this.listeners[event]=handler;},classList:{contains:()=>true},querySelectorAll:()=>[],closest:()=>null,setAttribute(){}} );
  const ctx=vm.createContext({payload,sourceMapCrosswalkRows:payload.source_map_crosswalk_rows,columnRows:payload.column_profile_rows,catalogRows:payload.catalog_rows,catalogDisplayRows:payload.canonical_resource_reconciliation_rows,columnPageIndex:0,columnExactField:'',columnMeasurement:'',reviewTemporal:payload.review_temporal_coverage,reviewSpatial:payload.review_spatial_coverage,clinicalDisplayEntry:(kind,system,code)=>payload.clinical_display_dictionary.find(row=>row.kind===kind&&row.system===system&&row.code===code),sourceDisplayName:name=>({RKKP_CLL:'Chronic Lymphocytic Leukaemia Registry',RKKP_LYFO:'Danish Lymphoma Registry',RKKP_DaMyDa:'Danish Myeloma Database'}[name] || name),clinicalFieldMatches:(row,q)=>row.column_name.toLowerCase().includes(q),setHtml:(id,value)=>output[id]=value,document:{getElementById:node,querySelectorAll:()=>[]},...extra});
  Object.assign(ctx,{URLSearchParams,window:{},panels:payload.panels,reviewLaboratory:{lab_sources:[]},collapseGlobalSearch(){}});
  vm.runInContext(fs.readFileSync(path.join(__dirname,'../inst/templates/atlas-vitals.js'),'utf8'),ctx);
  vm.runInContext(html.split('/* CLINICIAN_DISPLAY_START */')[1].split('/* CLINICIAN_DISPLAY_END */')[0],ctx);
  load('      function text(', '      function metric(',ctx);
  load('      function observedRowsWithheld(', '      function sourceTiles(',ctx);
  load('      function resourceSources(', '      ["catalog-search"',ctx);
  load('      function sourceTiles(', '      function cssClass(',ctx);
  load('      function finiteSummary(', '      ["column-search"',ctx);
  return {ctx,output,node,run:code=>vm.runInContext(code,ctx)};
}
test('source discovery and dictionary defaults preserve section IDs',()=>{
  assert.match(html,/<button class="sub-tab active" data-sub="infra-catalog">/);
  assert.match(html,/<button class="sub-tab active" data-sub="dictionary-codes">/);
  assert.match(html,/data-jump-sub="infra-catalog">Browse data sources/);
  const catalog=html.slice(html.indexOf('id="infra-catalog"'),html.indexOf('id="infra-columns"'));
  assert.ok(catalog.indexOf('id="catalog-search"')<catalog.indexOf('Source coverage details'));
  assert.ok(catalog.indexOf('id="catalog-list"')<catalog.indexOf('Source coverage details'));
  assert.match(html,/deferRender\("catalog-list", \(\) => renderCatalog\(\)\)/);
});
test('resource cards route exact sources and use current counts',()=>{
  const {run}=runtime();
  const card=run("resourceCard(payload.canonical_resource_reconciliation_rows.find(row=>row.canonical_resource_id==='RKKP_CLL'))");
  assert.match(card,/data-source-fields="RKKP_CLL"/);assert.match(card,/1,234 current source records · 83 fields/);
  assert.match(card,/Chronic Lymphocytic Leukaemia Registry/);assert.match(card,/Profiled/);
  const manual=run("resourceCard(payload.canonical_resource_reconciliation_rows.find(row=>row.canonical_resource_id==='DANRICHT'))");
  assert.match(manual,/Manual source/);assert.doesNotMatch(manual,/data-source-fields|0 current/);
});
test('connections use only explicit membership and documented FISH representation',()=>{
  const {run,ctx}=runtime({columnRows:[{table_name:'A'},{table_name:'A_similar'},{table_name:'B'}],catalogRows:[],sourceMapCrosswalkRows:[{canonical_resource_id:'r',source_map_key:'A'},{canonical_resource_id:'r',source_map_key:'B'},{canonical_resource_id:'other',source_map_key:'A_similar'}]});
  assert.equal(run("JSON.stringify(resourceSources({canonical_resource_id:'r'}))"),'["A","B"]');
  const card=run("resourceCard({canonical_resource_id:'r'})");assert.match(card,/verified join is not established/);assert.doesNotMatch(card,/A_similar/);
  const real=runtime().run("resourceCard(payload.canonical_resource_reconciliation_rows.find(row=>row.canonical_resource_id==='FISH'))");
  assert.match(real,/data-source-fields="RKKP_CLL"/);assert.match(real,/data-source-fields="RKKP_DaMyDa"/);assert.doesNotMatch(real,/data-source-fields="FISH"/);
});
test('catalogue search scopes the primary list and labels secondary list unfiltered',()=>{
  const {run,node,output}=runtime();node('catalog-search').value='RKKP_CLL';run('renderCatalog()');
  assert.match(output['catalog-list'],/Chronic Lymphocytic Leukaemia Registry/);assert.match(output['catalog-list'],/FISH cytogenetics/);assert.doesNotMatch(output['catalog-list'],/DANRICHT/);
  assert.match(html,/Current source-map rows \(all sources, unfiltered\)/);
  assert.match(html,/if \(disclosure\) disclosure.open = true/);
});
test('40-field pagination reaches every field and last page',()=>{
  const {run}=runtime();assert.equal(run('columnPage(columnRows,0).rows.length'),40);
  assert.equal(run('columnPage(columnRows,5).start'),200);assert.equal(run('columnPage(columnRows,5).rows.length'),23);
  assert.equal(run('columnPage(columnRows,999).page'),5);
  assert.equal(run('JSON.stringify(Array.from({length:6},(_,page)=>columnPage(columnRows,page).rows).flat()) === JSON.stringify(columnRows)'),true);
  assert.equal(run('columnPage([],NaN).pages'),1);
});
test('source filtering resets stale filters and routes preserve page and exact field state',()=>{
  const {ctx,node,output,run}=runtime();Object.assign(ctx,{activateTab(){},activateSubPane(){},applyLocalSearch(){},updateShareUrl(){},activeSubForTab(){},scrollToAtlasTarget(){}});
  load('      function jumpToPanel(', '      function scrollToAtlasTarget(',ctx);
  node('column-domain-filter').value='stale';node('column-kind-filter').value='numeric';node('column-search').value='stale';
  run("jumpToPanel('infrastructure','infra-columns',{source:'RKKP_CLL',scroll:false})");
  assert.equal(node('column-domain-filter').value,'');assert.equal(node('column-kind-filter').value,'');assert.equal(node('column-search').value,'');
  assert.match(node('column-count').textContent,/of 83 matching fields/);assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,40);
  run("jumpToPanel('infrastructure','infra-columns',{source:'RKKP_LYFO',search:'subtype',item:'subtype',scroll:false})");assert.match(output['column-list'],/Summary and meanings/);assert.match(output['column-list'],/<details class="lineage-block" open>/);
  assert.match(html,/routeParams.page = columnPageIndex/);assert.match(html,/columnPageIndex = Math.max\(0, Number\(route.page \|\| 1\) - 1\)/);
  assert.match(html,/columnPageIndex=0; columnExactField=''; if \(id === 'column-search'\) columnMeasurement=''; renderColumnExplorer/);
});
test('legacy numeric summaries remain withheld for zero, missing and reversed quartiles',()=>{
  const {run}=runtime();
  for(const bounds of ['mean:0,median:0,p25:0,p75:10','p25:null,p75:10','p25:10,p75:0','p25:NaN,p75:10','p25:0,p75:Infinity']) {
    const card=run(`columnStat({profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',${bounds}})`);
    assert.match(card,/Verified grouped evidence required/);assert.doesNotMatch(card,/<dt>Mean|<dt>Median|IQR width/);
  }
  const withheld=run("columnStat({profile_kind:'numeric',numeric_privacy_status:'needs_validation_negative_sentinel',mean:123456,median:123456})");assert.match(withheld,/Numeric coding needs review/);assert.doesNotMatch(withheld,/123456/);
  assert.equal(run('formatNumber(null)'),'Not supplied');assert.equal(run('formatNumber(0)'),'0');assert.equal(run("finiteSummary(' ')"),null);
});

test('reloading a source-field route restores page and an exact definition route',()=>{
  const {ctx,node,output,run}=runtime();Object.assign(ctx,{applyLocalSearch(_tab,_sub,q,item){node('column-search').value=q;ctx.columnPageIndex=0;ctx.columnExactField=item;},activeSubForTab:()=>'',renderGlobalSearch(){}});
  node('column-dataset-filter').options=[{value:''},{value:'RKKP_DaMyDa'},{value:'RKKP_LYFO'}];
  load('      function restoreRouteSearch(', '      function activateTab(',ctx);
  run("restoreRouteSearch({tabId:'infrastructure',subId:'infra-columns',source:'RKKP_DaMyDa',page:'4',q:'',g:''})");
  assert.match(node('column-count').textContent,/Showing 121–127 of 127/);assert.match(output['column-pagination'],/Page 4 of 4/);assert.match(output['column-source-context'],/RKKP_DaMyDa/);
  run("restoreRouteSearch({tabId:'infrastructure',subId:'infra-columns',source:'RKKP_LYFO',item:'subtype',q:'subtype',g:''})");
  assert.match(output['column-list'],/Lymphoma subtype/);assert.match(output['column-list'],/Diffuse large B-cell lymphoma/);assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,1);
});
test('field definitions are scoped reference meanings separate from frequencies',()=>{
  const {run}=runtime();const definitions=run("fieldCard(columnRows.find(row=>row.table_name==='RKKP_LYFO'&&row.column_name==='subtype'))");
  assert.equal((definitions.match(/Definition source/g)||[]).length,13);assert.match(definitions,/Reference definitions/);assert.match(definitions,/Categorical values and frequencies are not published for this field/);assert.match(definitions,/Mode: Not supplied/);assert.match(definitions,/Diffuse large B-cell lymphoma/);
  const unknown=run("fieldCard(columnRows.find(row=>row.table_name==='RKKP_CLL'&&row.column_name==='Reg_BinetStadium'))");assert.match(unknown,/Value definitions are not included for this field/);assert.doesNotMatch(unknown,/Diffuse large/);
});
test('small, protected and date fields remain schema discoverable without raw values',()=>{
  const {run,ctx}=runtime();ctx.row={table_name:'RKKP_CLL',column_name:'test',profile_kind:'numeric',availability_privacy_status:'withheld_small_complementary_cells',n_available:null,n_missing:null,pct_available:null,numeric_privacy_status:'withheld_small_complementary_cells',median:null};
  const small=run('fieldCard(row)');assert.match(small,/Small count withheld/);assert.doesNotMatch(small,/\b0 available|\b0 missing|\b0%/);
  ctx.row={table_name:'x',column_name:'protected',profile_kind:'sensitive',numeric_privacy_status:'protected_field'};assert.match(run('fieldCard(row)'),/schema only/);
  assert.match(run("columnStat({profile_kind:'date',min_date:'2099-01-01'})"),/Date values withheld/);
});
test('masked observed code panels show one withheld state and retain reference route',()=>{
  const {run,ctx}=runtime({panels:{mm_treatment_code_counts:[{code:null,n_rows:null,value_privacy_status:'withheld_unvalidated_distribution'}]}});
  load('      function renderObservedTreatmentCodes(', '      function renderTargetVisible(',ctx);
  const rendered=run('renderObservedTreatmentCodes()');assert.match(rendered,/Observed values and frequencies are withheld/);assert.match(rendered,/data-jump-sub="dictionary-codes"/);assert.doesNotMatch(rendered,/meaning-card|0 source/);
  assert.match(run('rowsForTable(panels.mm_treatment_code_counts)'),/withheld/);
  assert.equal(run('payload.clinical_display_dictionary.length + payload.npu_display_dictionary.length'),payload.clinical_display_dictionary.length+payload.npu_display_dictionary.length);
  assert.ok(payload.npu_display_dictionary.length>25000,'Fixture must use the full current pinned NPU reference');
});
test('synthetic field privacy labels follow field type, not removed date-bound keys',()=>{
  const {run}=runtime();
  assert.equal(run("fieldPrivacyLabel(columnRows.find(row=>row.table_name==='RKKP_CLL'&&row.column_name==='Reg_BinetStadium'))"),'');
  assert.equal(run("fieldPrivacyLabel(columnRows.find(row=>row.table_name==='RKKP_LYFO'&&row.column_name==='Reg_Haemoglobin'))"),'');
  assert.equal(run("fieldPrivacyLabel(columnRows.find(row=>row.table_name==='RKKP_CLL'&&row.column_name==='Reg_Leukocyttal'))"),'Numeric coding needs review');
});
test('synthetic withheld situation metrics never become zero when definitions are ok',()=>{
  const {ctx,output,run}=runtime({reviewSituation:payload.review_situation_sections,situationCards:payload.situation_report_cards,cssClass:String,humanMetricLabel:value=>String(value).replaceAll('_',' ')});
  ctx.rowsForTable=()=>'';load('      function renderSituationReport(', '      deferRender("situation-cards"',ctx);run('renderSituationReport()');
  assert.equal((output['situation-cards'].match(/<div class="big">Withheld<\/div>/g)||[]).length,3);
  assert.doesNotMatch(output['situation-cards'],/<div class="big">0<\/div>|currently_admitted/);
  ctx.reviewSituation={cards:[{metric_id:'count',n_patients:0,definition_status:'ok'},{metric_id:'count',n_patients:null,definition_status:'ok'}]};run('renderSituationReport()');
  assert.match(output['situation-cards'],/<div class="big">0<\/div>/);assert.match(output['situation-cards'],/<div class="big">Unavailable<\/div>/);
});
test('synthetic supported temporal year entries produce rows without withheld bounds',()=>{
  const {ctx,output,run}=runtime({reviewTemporal:payload.review_temporal_coverage});
  load('      function renderTemporalCoverage(', '      function regionFill(',ctx);run('renderTemporalCoverage()');
  assert.match(output['temporal-heatmap'],/<tbody><tr\b/);assert.match(output['temporal-heatmap'],/source records/);assert.doesNotMatch(output['temporal-heatmap'],/date range coverage|<tbody><\/tbody>|undefined/);
  ctx.reviewTemporal={sources:[{table_name:'x',display_min_year:2000,display_max_year:2025}],years:[]};run('renderTemporalCoverage()');
  assert.match(output['temporal-heatmap'],/Grouped year counts are not included/);assert.doesNotMatch(output['temporal-heatmap'],/<table/);
});
test('synthetic catalogue statuses stay readable and edits synchronize the route',()=>{
  const {run,ctx,node}=runtime();
  assert.equal(run("resourceCompactStatus(payload.canonical_resource_reconciliation_rows.find(row=>row.current_status==='legacy_unavailable_current_resolved'))"),'Profiled');
  assert.equal(run("resourceRoleLabel('canonical_resource')"),'Main resource');
  assert.match(html,/renderCatalog\(\);\s*if \(document.getElementById\('tab-infrastructure'\).classList.contains\('active'\)\)/);
  assert.match(html,/updateShareUrl\('infrastructure', 'infra-catalog', true\)/);
  let savedQuery;ctx.updateShareUrl=()=>{savedQuery=node('catalog-search').value;};
  node('catalog-status-filter').options=[{value:'current_profiled'},{value:'legacy_unavailable_current_resolved'}];
  node('catalog-role-filter').options=[{value:'canonical_resource'}];
  load('      ["catalog-search", "catalog-domain-filter"', '      deferRender("resource-reconciliation-summary"',ctx);
  node('catalog-search').value='FISH';node('catalog-domain-filter').value='Curated';node('catalog-role-filter').value='special_manual_or_embedded';
  node('catalog-search').listeners.input();assert.equal(savedQuery,'FISH');assert.equal(node('catalog-domain-filter').value,'Curated');assert.equal(node('catalog-role-filter').value,'special_manual_or_embedded');
  assert.equal(node('catalog-status-filter').options[1].textContent,'Profiled (previously unavailable)');assert.notEqual(node('catalog-status-filter').options[0].textContent,node('catalog-status-filter').options[1].textContent);assert.equal(node('catalog-role-filter').options[0].textContent,'Main resource');
});
test('synthetic masked lab overview uses reference counts and hides observed controls',()=>{
  const {ctx,run}=runtime({labEvidenceRows:payload.panels.lab_npu_code_coverage,formatTimestamp:()=>({display:'Snapshot'}),labDisplayEntry:()=>({resolved:false})});
  load('      function renderClinicianHome(', '      function setHtml(',ctx);
  load('      function renderLaboratoryNPUPanel(', '      function renderLabExplorer(',ctx);
  const home=run('renderClinicianHome()');assert.doesNotMatch(home,/0 \/ 1|exported lab codes with names/);assert.match(home,new RegExp(String(payload.npu_display_dictionary.length)+'.*reference','s'));assert.equal((home.match(/Browse data sources/g)||[]).length,1);
  const lab=run('renderLaboratoryNPUPanel()');assert.match(lab,/Observed code coverage withheld/);assert.match(lab,/data-jump-sub="dictionary-codes"/);assert.match(lab,/class="lab-controls" hidden/);assert.match(lab,/class="lab-shortcuts"[^>]* hidden/);assert.match(lab,/class="lab-refine" hidden/);
});
test('empty treatment semantic maps are qualified separately from masked observed codes',()=>{
  const {ctx,run}=runtime({panels:payload.panels,treatmentBarRows:rows=>rows,renderValueMapCard:()=>''});
  load('      function renderTreatmentCodeSection(', '      function renderTreatmentPanel(',ctx);
  const state=run("renderTreatmentCodeSection('ATC',[],'green')");assert.match(state,/Semantic code mappings are not included/);assert.match(state,/Observed treatment code frequencies are withheld/);assert.match(state,/data-jump-sub="dictionary-codes"/);
});
test('EKOKUR and all resources with exact profile candidates link to available fields',()=>{
  const {run}=runtime();
  const ekokur=run("resourceCard(payload.canonical_resource_reconciliation_rows.find(row=>row.canonical_resource_id==='EKOKUR'))");
  assert.match(ekokur,/data-source-fields="EKOKUR"/);assert.match(ekokur,/SDS_ekokur/);
  assert.equal(run("payload.canonical_resource_reconciliation_rows.filter(row=>resourceFieldSource(row)).every(row=>resourceCard(row).includes('data-source-fields=') && columnRows.some(field=>field.table_name===resourceFieldSource(row)))"),true);
});
test('global NPU search uses preserved reference definitions with dictionary routes',()=>{
  const {ctx,run}=runtime({panels:payload.panels,patobankKi67Percent:{},mclTriangleFeasibility:{},ki67Discovery:{},clinicalConceptRows:[],semanticRows:[],semanticCodeRows:[],semanticValueRows:[],semanticPanelLinks:[],semanticOverlayRows:[],semanticConflictRows:[],qaItems:[],actionItems:[],curatorLabelRowsForLookup:()=>[],scoreSearchResult:()=>0,normalizeSearchText:value=>String(value).toLowerCase()});
  for(const name of ['CLINICAL_TERMS','CLINICAL_GUIDE']) vm.runInContext(html.split(`/* ${name}_START */`)[1].split(`/* ${name}_END */`)[0],ctx);
  load('      function makeSearchResult(', '      function syncGlobalSearchPlaceholder(',ctx);
  load('      function dedupeSearchResults(', '      function humanMetricLabel(',ctx);
  for(const query of ['NPU04998','creatinine','kreatinin']) {
    ctx.query=query;const results=JSON.parse(run("JSON.stringify(buildGlobalSearchResults(query).Codes)"));
    assert.ok(results.some(row=>row.query==='NPU04998'&&row.status==='Reference meaning'&&row.tab==='dictionary'&&row.sub==='dictionary-codes'));
  }
  const exact=JSON.parse(run("JSON.stringify(buildGlobalSearchResults('NPU04998').Codes)"));assert.equal(exact[0].query,'NPU04998');
  for(const query of ['blood pressure','SpO2 %','temperature']){
    ctx.query=query;const result=JSON.parse(run("JSON.stringify(buildGlobalSearchResults(query)['Clinical concepts'])"));
    assert.equal(result.length,1);assert.equal(result[0].sub,'clinical-vitals');assert.equal(result[0].badge,'Measurement directory');
    assert.ok(result[0].description.includes('Exact source columns'));assert.equal(result[0].query,query.toLowerCase());
  }
});
