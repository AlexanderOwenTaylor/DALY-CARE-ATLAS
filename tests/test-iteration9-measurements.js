const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
const payload=require('./fixtures/synthetic-ui-payload.cjs').createSyntheticPayload();
function load(start,end,ctx){const a=html.indexOf(start),b=html.indexOf(end,a);assert.ok(a>=0&&b>a,`Missing executable block: ${start}`);vm.runInContext(html.slice(a,b),ctx);}
function runtime(extra={}) {
 const nodes={},output={};const node=id=>nodes[id]||={value:'',innerHTML:'',textContent:'',options:[],setAttribute(){},querySelectorAll:()=>[],classList:{contains:()=>true}};
 const ctx=vm.createContext({payload,columnRows:payload.column_profile_rows,columnPageIndex:0,columnExactField:'',columnMeasurement:'',reviewTemporal:payload.review_temporal_coverage,reviewSpatial:payload.review_spatial_coverage,URLSearchParams,sourceDisplayName:x=>x,clinicalDisplayEntry:(kind,system,code)=>payload.clinical_display_dictionary.find(r=>r.kind===kind&&r.system===system&&r.code===code),labSearchKey:x=>String(x).toLowerCase(),setHtml:(id,value)=>output[id]=value,document:{getElementById:node,querySelectorAll:()=>[]},...extra});
 load('      function text(', '      function metric(',ctx);load('      function observedRowsWithheld(', '      function sourceTiles(',ctx);
 load('      function clinicalFieldMatches(', '      function clinicalTermSearchResult(',ctx);
 load('      function finiteSummary(', '      ["column-search"',ctx);
 load('      function renderTemporalCoverage(', '      function regionFill(',ctx);
 vm.runInContext(html.split('/* ATLAS_ROUTE_START */')[1].split('/* ATLAS_ROUTE_END */')[0],ctx);
 return {ctx,node,output,run:code=>vm.runInContext(code,ctx)};
}
// Broad substring grouping would incorrectly include weight-loss fields; summaries must sort first.
test('weight and height shortcut is exact, comparable and ordered by usable summary',()=>{
 const {ctx,run,output}=runtime();ctx.columnMeasurement='weight-height';run('renderColumnExplorer()');
 assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,4);
 assert.match(output['column-list'],/weight_in_kg/);assert.match(output['column-list'],/height_in_cm/);assert.match(output['column-list'],/Reg_Vaegt/);assert.match(output['column-list'],/Reg_Hoejde/);
 assert.doesNotMatch(output['column-list'],/Beh_Vaegttab|Weightloss/);
 assert.ok(output['column-list'].indexOf('weight_in_kg')<output['column-list'].indexOf('Reg_Vaegt'));
 const card=run("fieldCard(columnRows.find(r=>r.table_name==='SP_PatientInfo'&&r.column_name==='weight_in_kg'))");
 assert.ok(card.indexOf('Median: 52')<card.indexOf('<details'));assert.match(card,/Middle 50%: 41–63/);assert.match(card,/kg in the field name; source unit metadata not supplied/);
 assert.doesNotMatch(card,/positive finding|completed procedure|normal clinical/);
});
test('equivalent groups have exact source membership and arbitrary readable search remains',()=>{
 const {ctx,node,run,output}=runtime();ctx.columnMeasurement='bmi';run('renderColumnExplorer()');assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,1);assert.match(output['column-list'],/bmi/);
 ctx.columnMeasurement='haemoglobin';run('renderColumnExplorer()');assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,3);assert.match(output['column-list'],/PB_Haemoglobin/);
 ctx.columnMeasurement='';node('column-search').value='smoking';run('renderColumnExplorer()');assert.match(output['column-list'],/ryger/);
 assert.equal(run("clinicalFieldMatches({table_name:'CLLPANEL_WIDE',column_name:'Weightloss'},'weightloss')"),true);
});
test('numeric preview preserves zero, missing quartiles and suppression without unit guesses',()=>{
 const {run}=runtime();assert.match(run("fieldTypicalPreview({profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:0,p25:0,p75:10})"),/Median: 0/);
 assert.match(run("fieldTypicalPreview({profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:null,p25:null,p75:10})"),/Median: Not supplied.*Middle 50%: Not supplied/);
 const withheld=run("fieldTypicalPreview({profile_kind:'numeric',numeric_privacy_status:'needs_validation_negative_sentinel',median:123456})");assert.doesNotMatch(withheld,/123456/);assert.match(withheld,/Numeric coding needs review/);
 for(const name of ['Reg_Vaegt','Reg_Hoejde','Reg_Haemoglobin'])assert.equal(run(`fieldUnitCopy({table_name:'RKKP_DaMyDa',column_name:'${name}'})`),'Unit not supplied in this source profile');
 assert.equal(run("fieldUnitCopy({table_name:'SP_PatientInfo',column_name:'bmi'})"),'Unit not supplied in this source profile');
 assert.match(run("displayFieldDefinition({definition:'Collected at diagnosis.'})"),/Collected at diagnosis/);
});
test('SP uses full exact contact evidence separate from field availability and no direct regions',()=>{
 const {run}=runtime();const context=run("renderSourceCoverage('SP_PatientInfo')");assert.match(context,/Contact date/);assert.match(context,/contact_date/);assert.match(context,/2030–2033/);assert.match(context,/27\.4%/);assert.doesNotMatch(context,/63\.797%/);assert.match(context,/not measurement dates/);assert.match(context,/No direct region counts/);assert.doesNotMatch(context,/residence|National coverage/);
 const counts=run("renderSourceYearCounts('SP_PatientInfo')");assert.equal((counts.match(/<tr>/g)||[]).length,5);assert.match(counts,/2030/);assert.match(counts,/2033/);
});
test('DaMyDa diagnosis coverage retains all region categories and source count caveat',()=>{
 const {run}=runtime();const context=run("renderSourceCoverage('RKKP_DaMyDa')");assert.match(context,/Diagnosis date/);assert.match(context,/Diagnosedato/);assert.match(context,/2028–2032/);assert.match(context,/Other\/unknown/);assert.match(context,/Region/);assert.match(context,/not unique people/);assert.match(context,/data-temporal-source="RKKP_DaMyDa"/);
});
test('year gaps, unknown date fields and withheld counts are visible and never become zero',()=>{
 const {run}=runtime({reviewTemporal:{sources:[{table_name:'X',date_column:'raw_date'}],years:[{table_name:'X',date_column:'raw_date',year:'2020',n_rows:'0'},{table_name:'X',date_column:'raw_date',year:'2022',n_rows:null,count_privacy_status:'withheld_small_cell'}]},reviewSpatial:{region_counts:[{table_name:'X',region_name:'Unmapped',region_column:'area',n_rows:null,count_privacy_status:'withheld_small_cell'}]}});
 const counts=run("renderSourceYearCounts('X')");assert.match(counts,/>2020<.*>0</s);assert.match(counts,/>2021<.*>Not supplied</s);assert.match(counts,/>2022<.*>Count withheld</s);assert.match(counts,/raw_date/);
 const coverage=run("renderSourceCoverage('X')");assert.match(coverage,/Unmapped/);assert.match(coverage,/Count withheld/);
});
test('measurement and temporal source routes round-trip and restore rendered results',()=>{
 const {ctx,node,run,output}=runtime();Object.assign(ctx,{applyLocalSearch(_t,_s,q,item){node('column-search').value=q;ctx.columnExactField=item;ctx.columnMeasurement='';},activeSubForTab:()=>'',renderGlobalSearch(){}});node('column-dataset-filter').options=[{value:''},{value:'SP_PatientInfo'}];node('temporal-source-filter').options=[{value:''},{value:'SP_PatientInfo'}];
 load('      function restoreRouteSearch(', '      function activateTab(',ctx);
 run("restoreRouteSearch(readAtlasRoute(atlasRouteHash('infrastructure','infra-columns',{measurement:'weight-height',source:'SP_PatientInfo',g:''})))");assert.equal((output['column-list'].match(/data-field-name=/g)||[]).length,2);
 run("restoreRouteSearch(readAtlasRoute(atlasRouteHash('overview','overview-temporal',{source:'SP_PatientInfo',g:''})))");assert.equal(node('temporal-source-filter').value,'SP_PatientInfo');assert.match(output['temporal-source-counts'],/contact_date/);assert.match(output['temporal-source-counts'],/2033/);
 run("restoreRouteSearch({tabId:'infrastructure',subId:'infra-columns',q:'smoking',g:''})");assert.equal(ctx.columnMeasurement,'');assert.match(output['column-list'],/ryger/);
});
test('synthetic jump and share handlers save the measurement group and temporal source',()=>{
 const {ctx,node,run}=runtime();let saved='';Object.assign(ctx,{activateTab(){},activateSubPane(){},activeSubForTab:()=>'',scrollToAtlasTarget(){},isQaRoute:()=>false,window:{location:{hash:''},history:{pushState(_state,_title,hash){saved=hash;},replaceState(_state,_title,hash){saved=hash;}}}});
 load('      function updateShareUrl(', '      function parseHashRoute(',ctx);
 load('      function applyLocalSearch(', '      function scrollToAtlasTarget(',ctx);
 node('column-dataset-filter').value='SP_PatientInfo';node('column-search').value='stale';node('column-domain-filter').value='stale';
 run("jumpToPanel('infrastructure','infra-columns',{measurement:'weight-height',scroll:false})");
 assert.equal(ctx.columnMeasurement,'weight-height');assert.equal(node('column-dataset-filter').value,'');assert.equal(node('column-search').value,'');assert.match(saved,/measurement=weight-height/);
 run("jumpToPanel('overview','overview-temporal',{source:'RKKP_DaMyDa',scroll:false})");assert.match(saved,/overview\/overview-temporal\?.*source=RKKP_DaMyDa/);
 run("jumpToPanel('infrastructure','infra-columns',{search:'smoking',scroll:false})");assert.equal(ctx.columnMeasurement,'');assert.doesNotMatch(saved,/measurement=/);assert.match(saved,/q=smoking/);
});
test('synthetic protected-date aggregate counts render in source table and overview heatmap',()=>{
 const {run,output}=runtime();const counts=run("renderSourceYearCounts('SP_PatientInfo')");
 assert.match(counts,/<tr><td>2030<\/td><td>11<\/td><\/tr>/);assert.match(counts,/<tr><td>2033<\/td><td>44<\/td><\/tr>/);assert.doesNotMatch(counts,/Count withheld/);
 run('renderTemporalCoverage()');assert.match(output['temporal-heatmap'],/SP_PatientInfo/);assert.match(output['temporal-heatmap'],/SP_PatientInfo 2030: 11 source records/);
 assert.equal(run("observedRowsWithheld([{value_privacy_status:'protected_field',n_rows:11}])"),true);
});
test('source count status preserves suppression, absent counts and zero independently of protected values',()=>{
 const {run,output}=runtime({reviewTemporal:{sources:[{table_name:'X'}],years:[{table_name:'X',year:2020,n_rows:0,value_privacy_status:'protected_field'},{table_name:'X',year:2021,n_rows:987654,count_privacy_status:'withheld_small_cells'},{table_name:'X',year:2022,n_rows:null},{table_name:'X',year:2023,n_rows:123456,value_privacy_status:'withheld_unvalidated_distribution'}]}});
 const counts=run("renderSourceYearCounts('X')");assert.match(counts,/>2020<\/td><td>0</);assert.match(counts,/>2021<\/td><td>Count withheld</);assert.match(counts,/>2022<\/td><td>Not supplied</);assert.match(counts,/>2023<\/td><td>Count withheld</);assert.doesNotMatch(counts,/987,654|123,456/);
 run('renderTemporalCoverage()');assert.match(output['temporal-heatmap'],/2020: 0 source records/);assert.match(output['temporal-heatmap'],/2021: Count withheld/);assert.match(output['temporal-heatmap'],/2022: Not supplied/);assert.doesNotMatch(output['temporal-heatmap'],/987,654|123,456/);
});
test('compact numeric cards use one unavailable reason and readable percentages',()=>{
 const {run}=runtime();const unavailable=run("fieldCard(columnRows.find(r=>r.table_name==='RKKP_DaMyDa'&&r.column_name==='Reg_Vaegt'))");
 assert.equal((unavailable.match(/Numeric coding needs review/g)||[]).length,1);assert.match(unavailable,/58\.3% recorded/);assert.doesNotMatch(unavailable,/58\.324%/);
 const recorded=run("fieldCard(columnRows.find(r=>r.table_name==='SP_PatientInfo'&&r.column_name==='weight_in_kg'))");assert.match(recorded,/63\.8% recorded/);assert.match(recorded,/Recorded values; not a clinical reference range/);assert.match(recorded,/27\.4% date-field availability/);
});
