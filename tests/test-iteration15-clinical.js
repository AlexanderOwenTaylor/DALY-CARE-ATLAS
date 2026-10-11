const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
function load(start,end,ctx){const a=html.indexOf(start),b=html.indexOf(end,a);assert.ok(a>=0&&b>a,`Missing block: ${start}`);vm.runInContext(html.slice(a,b),ctx);}
function fn(name,ctx){const a=html.indexOf(`      function ${name}(`);assert.ok(a>=0,`Missing function: ${name}`);const b=html.indexOf('\n      function ',a+1);vm.runInContext(html.slice(a,b<0?undefined:b),ctx);}
function runtime(extra={}){
 const payload=require('./fixtures/synthetic-ui-payload.cjs').createSyntheticPayload(),output={},nodes={};
 const node=id=>nodes[id]||={value:'',innerHTML:'',textContent:'',options:[],classList:{contains:()=>false,remove(){},toggle(){}},querySelector:()=>null};
 const ctx=vm.createContext({payload,panels:{lab_npu_code_coverage:[{value_privacy_status:'withheld_unvalidated_distribution'}]},columnRows:payload.column_profile_rows,reviewTemporal:payload.review_temporal_coverage,reviewSpatial:payload.review_spatial_coverage,columnExactField:'',columnMeasurement:'',columnPageIndex:0,URLSearchParams,document:{getElementById:node,querySelector:()=>null},setHtml:(id,value)=>output[id]=value,...extra});
 load('      function text(', '      function metric(',ctx);
 load('      function observedRowsWithheld(', '      function sourceTiles(',ctx);
 vm.runInContext(html.split('/* CLINICIAN_DISPLAY_START */')[1].split('/* CLINICIAN_DISPLAY_END */')[0],ctx);
 load('      function makeSearchResult(', '      function buildGlobalSearchResults(',ctx);
 for(const marker of ['CLINICAL_TERMS','CLINICAL_GUIDE'])vm.runInContext(html.split(`/* ${marker}_START */`)[1].split(`/* ${marker}_END */`)[0],ctx);
 load('      function finiteSummary(', '      ["column-search"',ctx);
 fn('normalizeClinicalKey',ctx);
 return {ctx,node,output,run:code=>vm.runInContext(code,ctx)};
}
test('treatment source identities classify known layers and leave near-matches or conflicts as candidates',()=>{
 const {ctx,run}=runtime();fn('treatmentSourceContext',ctx);
 for(const [source,id] of [['SP_AdministreretMedicin','sp_administered'],['SP_OrdineretMedicin','sp_ordered'],['SP_Behandlingsplaner_Del1','sp_plan'],['Behandlingsplaner_del2','sp_plan'],['SDS_indberetningmedpris','smr'],['RKKP_DaMyDa','registry'],['SDS_t_sksube','sks'],['EKOKUR','national_prescription']]){
  ctx.row={table_name:source};assert.equal(run('treatmentSourceContext(row).id'),id,source);
 }
 for(const row of [{table_name:'SP_AdministreretMedicin_extra'},{table_name:'unknown',evidence_file:'SP_AdministreretMedicin.csv'},{table_name:'SP_AdministreretMedicin',source_name:'SP_OrdineretMedicin'},{table_name:'SP_AdministreretMedicin',code_system:'SKS',code:'BWHA'}]){ctx.row=row;assert.equal(run('treatmentSourceContext(row).id'),'candidate');}
 ctx.row={table_name:'SP_OrdineretMedicin',code_system:'ATC',code:'L01'};assert.equal(run('treatmentSourceContext(row).id'),'sp_ordered');
 ctx.row={code_system:'SKS',code:'BWHA'};assert.equal(run('treatmentSourceContext(row).id'),'sks');
});
test('reference search distinguishes same-name codes with supplied specimen and terminology unit',()=>{
 const {run}=runtime();const result=run("clinicalTermSearchResult({kind:'laboratory_test',label:'Creatinine',code:'NPU03800',system:'NPU',specimen:'Patient',system_spec:'vB;fPt',unit:'mmol/d'},'creatinine')");
 assert.match(result.description,/Patient/);assert.match(result.description,/vB;fPt/);assert.match(result.description,/mmol\/d/);assert.match(result.description,/Reference unit/);assert.equal(result.status,'Reference meaning');assert.equal(result.source,'');
});
test('an authoritative unknown treatment table cannot inherit a known secondary source layer',()=>{
 const {ctx,run}=runtime();fn('treatmentSourceContext',ctx);
 for(const row of [{table_name:'SP_AdministreretMedicin_extra',source_name:'SP_AdministreretMedicin'},{table_name:'unreviewed_table',object_name:'SP_OrdineretMedicin'},{table_name:'unreviewed_table',source_name:'SP_AdministreretMedicin',code_system:'ATC',code:'L01XE27'},{table_name:'unreviewed_table',code_system:'SKS',code:'BWHA'}]){ctx.row=row;assert.equal(run('treatmentSourceContext(row).id'),'candidate');}
 // Actual source inventory rows carry a table name plus descriptive domain/role metadata.
 ctx.row={table_name:'SP_AdministreretMedicin',load_status:'loaded',domain:'SP',subdomain:'Medication',atlas_role:'administered_medicine',source_name:'Medication module',object_name:'Administration export'};assert.equal(run('treatmentSourceContext(row).id'),'sp_administered');
 ctx.row={table_name:'Behandlingsplaner_del2',object_name:'SP_Behandlingsplaner_Del2'};assert.equal(run('treatmentSourceContext(row).id'),'sp_plan');
 ctx.row={table_name:'SP_AdministreretMedicin',source_name:'SP_OrdineretMedicin'};assert.equal(run('treatmentSourceContext(row).id'),'candidate');
 for(const [code_system,code,want] of [['ATC','L01XE27','atc'],['SKS','BWHA','sks']]){ctx.row={code_system,code};assert.equal(run('treatmentSourceContext(row).id'),want);}
});
test('field answers retain explicit totals, small percentages and exact scoped evidence without source tables repeated',()=>{
 const {ctx,run}=runtime();ctx.row={table_name:'SP_PatientInfo',column_name:'weight_in_kg',profile_kind:'numeric',n_rows:10000,n_available:9999,n_missing:1,pct_available:99.99,numeric_privacy_status:'eligible_stored_summary',median:0,p25:0,p75:10};
 const card=run('fieldCard(row)');assert.match(card,/9,999 of 10,000 source records/);assert.match(card,/&lt;100%/);assert.match(card,/Median: 0/);assert.match(card,/kg in the field name/);assert.doesNotMatch(card,/source-year-counts|Recorded region<\/th>/);
 assert.match(card,/view=timeplace&amp;source=SP_PatientInfo/);assert.match(card,/table=column_profiles&amp;source=SP_PatientInfo&amp;field=weight_in_kg/);
 assert.equal(run('fieldPercent(0.004)'),'<0.1');assert.equal(run('fieldPercent(99.95)'),'<100');assert.equal(run('fieldPercent(100)'),'100');assert.equal(run('fieldPercent(0)'),'0');
 ctx.row={...ctx.row,n_rows:null,n_missing:1};assert.doesNotMatch(run('fieldCard(row)'),/of 10,000/);
 ctx.row={...ctx.row,n_rows:10000,n_available:9999,n_missing:1,pct_available:99.99,availability_privacy_status:'withheld_small_complementary_cells',numeric_privacy_status:'withheld_small_complementary_cells',median:123456};assert.doesNotMatch(run('fieldCard(row)'),/123,456|99\.99|9,999|0%|of 10,000/);
});
test('registry numeric evidence explains withholding once and keeps configured unit separate from profiles',()=>{
 const {ctx,run}=runtime();const block=html.split('/* REGISTRY_NUMERIC_START */')[1]?.split('/* REGISTRY_NUMERIC_END */')[0];assert.ok(block,'Executable numeric renderer');vm.runInContext(block,ctx);
 ctx.row={table_name:'RKKP_DaMyDa',source_column:'Reg_Creatinin_mikmoll',unit:'umol/L',n_available:50,pct_available:99.99,numeric_privacy_status:'needs_validation_unreviewed_field',median:123456};
 const card=run("renderRegistryNumericCard(row,'Creatinine','RKKP_DaMyDa')");assert.match(card,/Configured registry-panel unit: umol\/L/);assert.match(card,/Stored numeric summaries need validation/);assert.doesNotMatch(card,/123,456|<dt>Median|<dt>25th/);assert.match(card,/field=Reg_Creatinin_mikmoll/);
 assert.equal(run("fieldUnitCopy({table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll'})"),'Unit not supplied in this source profile');
 ctx.row={...ctx.row,numeric_privacy_status:'eligible_stored_summary',median:0,p25:0,p75:10};assert.match(run("renderRegistryNumericCard(row,'Creatinine','RKKP_DaMyDa')"),/Median: 0/);
});
test('source cards use exact useful destinations and consistent source labels',()=>{
 const {ctx,run}=runtime();fn('browseFieldsLink',ctx);fn('resourceCompactStatus',ctx);fn('sourceEvidenceLinks',ctx);fn('sourceTiles',ctx);
 const tiles=run("sourceTiles([{table_name:'SP_PatientInfo',status:'current_profiled',n_rows:100,n_cols:5}])");assert.match(tiles,/Patient information \(SP\)/);assert.match(tiles,/data-source-fields="SP_PatientInfo"/);assert.match(tiles,/view=timeplace&amp;source=SP_PatientInfo/);assert.doesNotMatch(tiles.split('<details')[0],/>current_profiled</);
 fn('resourceTitle',ctx);assert.equal(run("resourceTitle({table_name:'SP_PatientInfo',display_name:'SP patient info'})"),'Patient information (SP)');
});
test('registry lists share a common summary limitation while retaining distinct fields and configured units',()=>{
 const {ctx,run}=runtime();vm.runInContext(html.split('/* REGISTRY_NUMERIC_START */')[1].split('/* REGISTRY_NUMERIC_END */')[0],ctx);ctx.rows=[{source_column:'Reg_A',numeric_privacy_status:'needs_validation_unreviewed_field',n_available:0,unit:'mmol/L'},{source_column:'Reg_B',numeric_privacy_status:'needs_validation_unreviewed_field',n_available:50,unit:'mg/L'}];
 assert.equal(run('typeof renderRegistryNumericList'),'function');const list=run("renderRegistryNumericList(rows,'RKKP_DaMyDa')");assert.equal((list.match(/Stored numeric summaries need validation/g)||[]).length,1);assert.match(list,/0 source records with a value/);assert.match(list,/50 source records with a value/);assert.match(list,/mmol\/L/);assert.match(list,/mg\/L/);assert.match(list,/field=Reg_A/);assert.match(list,/field=Reg_B/);
});
test('vitals distinguishes absent SP event aggregates from the existing patient-information measurement journey',()=>{
 const {ctx,run}=runtime({panelRawFieldRows:[],panelDistributionRows:[],clinicalConceptRows:[],renderVitalsStatCard:()=>'',scanScopeNote:()=>'',conceptButtons:()=>''});fn('firstMatchingRow',ctx);fn('browseFieldsLink',ctx);fn('renderVitalsPanel',ctx);
 const panel=run('renderVitalsPanel()');assert.match(panel,/data-measurement="weight-height"/);assert.match(panel,/SP_PatientInfo/);assert.match(panel,/SP_VitaleVaerdier/);assert.match(panel,/not supplied/);assert.doesNotMatch(panel,/P05|PATIENTS|Open Height concept/);
});
test('withheld laboratory landing has one limit and distinct reference and exact source actions',()=>{
 const {ctx,node,output,run}=runtime({reviewLaboratory:{lab_sources:[{table_name:'SP_AlleProvesvar',n_rows:100,n_cols:2}]}});fn('browseFieldsLink',ctx);fn('resourceCompactStatus',ctx);fn('sourceTiles',ctx);fn('renderLaboratoryNPUPanel',ctx);fn('renderLabExplorer',ctx);
 const panel=run('renderLaboratoryNPUPanel()');run('renderLabExplorer(0)');assert.match(panel,/dictionary-codes/);assert.match(panel,/view=timeplace&amp;source=SP_AlleProvesvar/);assert.equal((panel.match(/Observed code coverage withheld/g)||[]).length,1);assert.equal(output['lab-results'],'');assert.equal(node('lab-result-summary').textContent,'');
});
test('collapsed search state preserves the query and can reopen results without retyping',()=>{
 const {ctx,node,run}=runtime({appState:{lastGlobalQuery:'haemoglobin',globalResultsExpanded:false},window:{matchMedia:()=>({matches:false})},buildGlobalSearchResults:()=>({'Codes':[{title:'Haemoglobin',description:'NPU42',tab:'dictionary',sub:'dictionary-codes',query:'NPU42',score:1}]})});
 fn('toneColor',ctx);fn('renderBadge',ctx);fn('collapseGlobalSearch',ctx);load('      function renderGlobalSearch(', '      function filteredRowsForExport(',ctx);node('global-atlas-search').value='haemoglobin';run('collapseGlobalSearch()');assert.match(node('global-search-results').innerHTML,/Search: haemoglobin/);assert.match(node('global-search-results').innerHTML,/Show search results/);assert.equal(run('appState.globalResultsHidden'),true);
 run("renderGlobalSearch('haemoglobin')");assert.match(node('global-search-results').innerHTML,/data-search-open/);assert.equal(run('appState.globalResultsHidden'),false);
});
test('pending rendering waits for a closed detail and flushes on direct arrival or print',()=>{
 const detail={tagName:'DETAILS',open:false,parentElement:null,classList:{contains:()=>false}},target={tagName:'DIV',parentElement:detail,classList:{contains:()=>false}};
 const {ctx,run}=runtime({document:{getElementById:()=>target},pendingRenders:new Map(),renderFailures:new Set()});load('      function renderTargetVisible(', '      function renderClinicianHome(',ctx);ctx.renders=0;run("deferRender('hidden',()=>renders++)");assert.equal(run('renders'),0);detail.open=true;run('flushPendingRenders()');assert.equal(run('renders'),1);detail.open=false;run("deferRender('print',()=>renders++)");run('flushPendingRenders(true)');assert.equal(run('renders'),2);
});
test('history restores selected field identity and search visibility independently',()=>{
 const entries=[],history={state:null,pushState(state,_title,hash){this.state=state;entries.push({state,hash});ctx.window.location.hash=hash;},replaceState(state,_title,hash){this.state=state;ctx.window.location.hash=hash;}};
 const {ctx,node,output,run}=runtime({appState:{},isQaRoute:()=>false,window:{location:{hash:''},history,matchMedia:()=>({matches:false})},activeSubForTab:()=> 'infra-columns',activateTab(){},activateSubPane(){},scrollToAtlasTarget(){},buildGlobalSearchResults:()=>({Codes:[{title:'Haemoglobin',description:'NPU42',tab:'dictionary',sub:'dictionary-codes',query:'NPU42',score:1}]})});
 fn('toneColor',ctx);fn('renderBadge',ctx);fn('collapseGlobalSearch',ctx);load('      function renderGlobalSearch(', '      function filteredRowsForExport(',ctx);vm.runInContext(html.split('/* ATLAS_ROUTE_START */')[1].split('/* ATLAS_ROUTE_END */')[0],ctx);
 load('      function updateShareUrl(', '      function parseHashRoute(',ctx);load('      function applyLocalSearch(', '      function scrollToAtlasTarget(',ctx);load('      function restoreRouteSearch(', '      function activateTab(',ctx);
 node('column-dataset-filter').options=[{value:''},{value:'RKKP_DaMyDa'}];node('global-atlas-search').value='haemoglobin';run("renderGlobalSearch('haemoglobin'); updateShareUrl('infrastructure','infra-columns',false)");
 run("jumpToPanel('infrastructure','infra-columns',{source:'RKKP_DaMyDa',search:'Reg_Haemoglobin',item:'Reg_Haemoglobin',scroll:false})");assert.equal(entries[0].state.searchResultsVisible,true);assert.equal(entries[1].state.searchResultsVisible,false);
 history.state=entries[1].state;ctx.window.location.hash=entries[1].hash;run('restoreRouteSearch(readAtlasRoute(window.location.hash))');assert.match(node('global-search-results').innerHTML,/Show search results/);assert.match(output['column-list'],/Reg_Haemoglobin/);assert.equal(node('column-dataset-filter').value,'RKKP_DaMyDa');
 history.state=entries[0].state;ctx.window.location.hash=entries[0].hash;run('restoreRouteSearch(readAtlasRoute(window.location.hash))');assert.match(node('global-search-results').innerHTML,/data-search-open/);assert.equal(node('global-atlas-search').value,'haemoglobin');assert.equal(node('column-dataset-filter').value,'');
});
test('an active secondary destination reveals its labelled navigation disclosure',()=>{
 const active={textContent:'Clinical Feasibility'},more={open:false,querySelector:()=>active},detail={open:false,querySelector:()=>({textContent:'Priority QA'})},label={textContent:''};
 const {ctx,run}=runtime({document:{getElementById:id=>id==='nav-more'?more:label,querySelectorAll:()=>[detail]}});fn('syncSecondaryNavigation',ctx);run('syncSecondaryNavigation()');assert.equal(more.open,true);assert.equal(label.textContent,'More: Clinical Feasibility');assert.equal(detail.open,true);
 more.querySelector=()=>null;detail.querySelector=()=>null;run('syncSecondaryNavigation()');assert.equal(more.open,false);assert.equal(label.textContent,'More sections');assert.equal(detail.open,false);
});
