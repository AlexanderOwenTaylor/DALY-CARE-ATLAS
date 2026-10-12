const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
function load(start,end,ctx){const a=html.indexOf(start),b=html.indexOf(end,a);assert.ok(a>=0&&b>a,`Missing block: ${start}`);vm.runInContext(html.slice(a,b),ctx);}
function fn(name,ctx){const a=html.indexOf(`      function ${name}(`),b=html.indexOf('\n      function ',a+1);assert.ok(a>=0,`Missing function: ${name}`);vm.runInContext(html.slice(a,b<0?undefined:b),ctx);}
function runtime(extra={}){
const ctx=vm.createContext({URLSearchParams,payload:{},panels:{},catalogRows:[],columnRows:[],panelDistributionRows:[],panelRawFieldRows:[],reviewClinical:{},reviewTemporal:{},reviewSpatial:{},clinicalConceptRows:[],domainPanelRows:[],panelKpiRows:[],renderTermHelp:()=>'',semanticOverlayDisplayForRow:()=>null,semanticOverlaySourceForDisplay:v=>v,semanticRawName:r=>r.raw_column||'',renderScopeChip:()=>'',...extra});
 load('      function text(', '      function metric(',ctx);
 vm.runInContext(html.split('/* CLINICIAN_DISPLAY_START */')[1].split('/* CLINICIAN_DISPLAY_END */')[0],ctx);
 for(const name of ['finiteSummary','fieldPercent','fieldUnitCopy','browseFieldsLink','sourceEvidenceLinks','normalizeClinicalKey','observedRowsWithheld','withheldObservedState','toneColor','cssClass'])fn(name,ctx);
 load('      let sourceCoverageCache;', '      function renderSourceCoverage(',ctx);
 load('      function scopeLabel(', '      function renderConceptCard(',ctx);
 load('      const clinicalDictionaryRows =', '      const clinicalTermIndex =',ctx);fn('clinicalRegistryLabel',ctx);
 vm.runInContext(html.split('/* DOMAIN_SOURCE_EVIDENCE_START */')[1].split('/* DOMAIN_SOURCE_EVIDENCE_END */')[0],ctx);
 load('      function panelRows(', '      document.getElementById("hero-copy")',ctx);
 routes(ctx);
 return {ctx,run:code=>vm.runInContext(code,ctx)};
}
const row=(label,n,extra={})=>({registry:'LYFO',table_name:'RKKP_LYFO',source_column:'Reg_Stadium',facet:'stage',label,n,...extra});
test('registry charts show supplied positive and zero counts but never null categories or null counts',()=>{
 const {run}=runtime({panels:{lyfo_clinical_profile:[row('Published positive',40),row('Published zero',0),row('Null count',null),row(null,25)]}});
 const result=run("renderLYFOFacetGroup('Stage',['stage'],'','plum')");
 assert.equal((result.match(/class="track"/g)||[]).length,2);assert.match(result,/<div class="val">0<\/div>/);assert.doesNotMatch(result,/Null count|>null</);
});
test('original retained flagged values cannot reach labels, titles, bars or coding footers',()=>{
 for(const flag of [{value_privacy_status:'withheld_unvalidated_distribution'},{count_privacy_status:'suppressed_small_cell'},{value_privacy_status:'protected_field'},{validation_status:'blocked'},{value_privacy_status:'unreviewed_future_policy'}]){
  const {run}=runtime({panels:{lyfo_clinical_profile:[row('PRIVATE_SENTINEL',87654321,flag)]}});
  const result=run("renderLYFOFacetGroup('Stage',['stage'],'','plum')");
  assert.doesNotMatch(result,/PRIVATE_SENTINEL|87,654,321|class="track"|h-bar-scale-note|original field and category/);assert.match(result,/withheld/i);
 }
});
test('mixed registry rows retain safe charts and one withholding notice',()=>{
 const {run}=runtime({panels:{lyfo_clinical_profile:[row('Safe',50),row('SECRET',87654321,{value_privacy_status:'withheld_unvalidated_distribution'})]}});
 const result=run("renderLYFOFacetGroup('Stage',['stage'],'','blue')");
 assert.equal((result.match(/class="track"/g)||[]).length,1);assert.match(result,/Safe/);assert.doesNotMatch(result,/SECRET|87,654,321/);assert.equal((result.match(/Category frequencies withheld/g)||[]).length,1);
});
test('DaMyDa does not combine distinct exact fields, sources or summary scopes',()=>{
 const rows=[row('Same category',20,{registry:'DaMyDa',table_name:'RKKP_DaMyDa',source_column:'Stadie',profile_scope:'full'}),row('Same category',30,{registry:'DaMyDa',table_name:'RKKP_DaMyDa',source_column:'Reg_PerformanceStatus',profile_scope:'sample'}),row('Same category',40,{registry:'DaMyDa',table_name:'alias',source_column:'Stadie',profile_scope:'full'})];
 const {ctx,run}=runtime();ctx.rows=rows;
 const result=Array.from(run("groupDaMyDaFacetRows(rows,()=> 'Shared display','blue')"));
 assert.equal(result.length,3);assert.deepEqual(result.map(r=>r.n),[20,30,40]);assert.equal(rows[0].label,'Same category');
});
test('CLL chooses one distribution per exact source field and scope while preserving another scope',()=>{
 const {run}=runtime({panels:{cll_clinical_profile:[row('Yes',50,{registry:'CLL',table_name:'RKKP_CLL',source_column:'Reg_FISH',facet:'fish_overall',profile_scope:'full'}),row('Other scope',20,{registry:'CLL',table_name:'RKKP_CLL',source_column:'Reg_FISH',facet:'fish_overall',profile_scope:'sample'})]},panelDistributionRows:[{panel_id:'reg_cll',table_name:'RKKP_CLL',raw_column:'Reg_FISH',raw_value:'Yes',n:50,profile_scope:'full'}]});
 const result=run("renderCLLSection('FISH',['fish_overall'],['Reg_FISH'],'',8)");
 assert.equal((result.match(/class="track"/g)||[]).length,2);assert.equal((result.match(/<div class="val">50<\/div>/g)||[]).length,1);assert.match(result,/<div class="val">20<\/div>/);
});
test('CLL generic distribution paths also gate retained protected values before mapping',()=>{
 const {run}=runtime({panelDistributionRows:[{panel_id:'reg_cll',table_name:'RKKP_CLL',raw_column:'Reg_FISH',raw_value:'SECRET',n:87654321,value_privacy_status:'protected_field'}]});
 const result=run("renderCLLDistributionGroups(['Reg_FISH'],'violet')");assert.doesNotMatch(result,/SECRET|87,654,321|class="track"|h-bar-scale-note/);assert.match(result,/withheld/i);
});
function theme(result,id){const marker=`id="registry-${id}"`,a=result.indexOf(marker);assert.ok(a>=0,marker);const b=result.indexOf('</section>',a);return result.slice(a,b);}
const profile=(source,field,extra={})=>({table_name:source,column_name:field,profile_kind:'categorical',n_available:0,n_missing:50,...extra});
const membership=(source,panel='reg_cll',extra={})=>({panel_id:panel,membership_id:'registry_'+panel.slice(4),source_key:source,canonical_resource_id:panel==='reg_cll'?'RKKP_CLL':null,membership_role:'primary',evidence_layer:'registry',catalog_identity_state:'unique',canonical_lineage_state:panel==='reg_cll'?'established':'unestablished',family_identity_state:'single',load_status:'loaded',load_state:'loaded',...extra});
const inventory=rows=>({schema_version:1,inventory_version:'fixture19',basis:'reviewed_exact_source_inventory',evidence_origin:'imported_snapshot',inventory_state:'present',rows,diagnostics:[]});
test('reviewed response fields join their own exact profiles even with no raw mapping rows',()=>{
 for(const [source,renderer,id,fields] of [['RKKP_DaMyDa','renderDaMyDaPanel','damyda',['PB_MaksimaleRespons','SB_Respons']],['RKKP_LYFO','renderLYFOPanel','lyfo',['Beh_Responsevaluering','Rec_Responsevaluering','FU_Sygdomsstatus']]]){
  const {run}=runtime({catalogRows:[{table_name:source,n_rows:50,n_cols:5}],columnRows:fields.map(f=>profile(source,f)),payload:{clinical_display_dictionary:fields.map((code,i)=>({kind:'field',system:source,code,label:`Reviewed response ${i+1}`}))}});
  const response=theme(run(`${renderer}()`),`${id}-theme-response`);
  for(const field of fields){assert.match(response,new RegExp(`field=${field}`));assert.match(response,new RegExp(`${source} / ${field}`));}assert.match(response,/Reviewed response 1/);assert.match(response,/0 source records with a value/);assert.doesNotMatch(response,/view=timeplace/);
 }
});
test('LYFO relapse treatment stays in Treatment and unknown Rec fields cannot assert Response or Workup',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_LYFO'}],columnRows:['Rec_Kemoterapiregime1','Rec_DosisIGray','Rec_Operationstype','Rec_Unreviewed','Reg_Lokal_Knoglemarv'].map(f=>profile('RKKP_LYFO',f))});const result=run('renderLYFOPanel()');
 const treatment=theme(result,'lyfo-theme-treatment'),response=theme(result,'lyfo-theme-response'),workup=theme(result,'lyfo-theme-workup');
 for(const field of ['Rec_Kemoterapiregime1','Rec_DosisIGray','Rec_Operationstype'])assert.match(treatment,new RegExp(`field=${field}`));
 assert.doesNotMatch(response,/field=Rec_Kemoterapiregime1|field=Rec_Unreviewed/);assert.doesNotMatch(workup,/field=Reg_Lokal_Knoglemarv/);assert.match(workup,/not been classified/);assert.match(workup,/source=RKKP_LYFO/);
});
test('wrong sources, aliases and missing profiles do not borrow reviewed field cards',()=>{
 const payload={clinical_source_inventory:inventory([membership('RKKP_CLL','reg_cll',{family_identity_state:'multiple'}),membership('CLL alias','reg_cll',{family_identity_state:'multiple'})])};
 const {run}=runtime({payload,catalogRows:[{table_name:'RKKP_CLL',n_rows:100,n_cols:8},{table_name:'CLL alias',n_rows:7,n_cols:2}],columnRows:[profile('unreviewed','Beh_Responsevaluering'),profile('CLL alias','Beh_Responsevaluering'),profile('RKKP_CLL','Reg_BinetStadium')]});
 const result=run('renderCLLPanel()'),response=theme(result,'cll-theme-response');
 assert.doesNotMatch(response,/field=Beh_Responsevaluering|field=Beh_MRD/);assert.match(result,/data-registry-source="CLL alias"/);assert.match(result,/100 source records/);assert.match(result,/7 source records/);assert.match(response,/source=CLL\+alias/);assert.match(response,/No reviewed field mapping/);
});
test('registry source strips retain duplicate and unavailable inventory states without choosing summary regex matches',()=>{
 const payload={clinical_source_inventory:inventory([membership('RKKP_CLL','reg_cll',{catalog_identity_state:'duplicate',load_status:null,load_state:'unknown'})])};
 const {run}=runtime({payload,catalogRows:[{table_name:'RKKP_CLL',n_rows:111},{table_name:'RKKP_CLL',n_rows:222}],panels:{registry_clinical_summary:[{registry:'CLL similar',table_name:'near_CLL',n_rows:87654321}]}});
 const result=run('renderCLLPanel()');assert.match(result,/Duplicate catalog identity/);assert.doesNotMatch(result,/87,654,321/);assert.match(result,/identity unresolved/i);
 const unavailable=runtime({payload:{clinical_source_inventory:{...inventory([]),inventory_state:'unavailable'}}}).run('renderCLLPanel()');assert.match(unavailable,/Source-inventory limitation/);assert.doesNotMatch(unavailable,/data-registry-source=/);
});
test('dedicated summary metrics require one unambiguous exact supplied identity',()=>{
 for(const summary of [{registry:'CLL',n_rows:87654321},{table_name:'RKKP_CLL',source_name:'Other',n_rows:87654321}]){
  const {run}=runtime({catalogRows:[{table_name:'RKKP_CLL',n_rows:50}],panels:{registry_clinical_summary:[summary]}});assert.doesNotMatch(run('renderCLLPanel()'),/87,654,321/);
 }
 const {run}=runtime({catalogRows:[{table_name:'RKKP_CLL',n_rows:50}],panels:{registry_clinical_summary:[{table_name:'RKKP_CLL',n_rows:70,summary_scope:'supplied separate scan'}]}});const result=run('renderCLLPanel()');assert.match(result,/70 source records/);assert.match(result,/supplied separate scan/);assert.match(result,/50 source records/);
});
test('field units and permitted numeric summaries remain separate from configured panel units',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_DaMyDa'}],columnRows:[profile('RKKP_DaMyDa','Reg_CReaktivtProtein_gl',{profile_kind:'numeric',numeric_privacy_status:'needs_validation_unreviewed_field',median:87654321})],panels:{damyda_numeric_fields:[{table_name:'RKKP_DaMyDa',source_column:'Reg_CReaktivtProtein_gl',unit:'mg/L',numeric_privacy_status:'needs_validation_unreviewed_field',numeric_privacy_reason:'Codebook not verified',median:87654321}]}});
 const baseline=theme(run('renderDaMyDaPanel()'),'damyda-theme-baseline');assert.match(baseline,/Configured registry-panel unit: mg\/L/);assert.match(baseline,/Unit not supplied in this source profile/);assert.match(baseline,/Codebook not verified/);assert.doesNotMatch(baseline,/87,654,321/);
 const eligible=runtime({catalogRows:[{table_name:'RKKP_DaMyDa'}],columnRows:[profile('RKKP_DaMyDa','Reg_CReaktivtProtein_gl',{profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:0,p25:0,p75:10,unit:'mg/L'})]}).run('renderDaMyDaPanel()');assert.match(eligible,/Median: 0/);assert.match(eligible,/Source unit metadata: mg\/L/);
});
function routes(ctx){vm.runInContext(html.split('/* ATLAS_ROUTE_START */')[1].split('/* ATLAS_ROUTE_END */')[0],ctx);}
test('theme routes round-trip only valid themes for the active registry and preserve global search',()=>{
 const {ctx,run}=runtime();routes(ctx);
 assert.equal(run("atlasRouteHash('registries','reg-cll',{theme:'response',g:'lymphoma'})"),'#registries/reg-cll?g=lymphoma&theme=response');
 assert.equal(run("readAtlasRoute('#registries/reg-cll?theme=response&g=lymphoma').theme"),'response');
 assert.equal(run("readAtlasRoute('#registries/reg-cll?theme=sites').theme"),'');
 assert.equal(run("readAtlasRoute('#registries/reg-lyfo?theme=sites').theme"),'sites');
 assert.equal(run("readAtlasRoute('#clinical/clinical-notes?theme=response').theme"),'');
 assert.equal(run("atlasRouteHash('registries','reg-cll',{theme:'unknown'})"),'#registries/reg-cll');
});
test('source task links are native registry anchors without global handler attributes',()=>{
 const {ctx,run}=runtime({catalogRows:[{table_name:'RKKP_CLL'}]});routes(ctx);const result=run('renderCLLPanel()');
 const index=result.match(/<nav[^>]*registry-theme-index[\s\S]*?<\/nav>/)?.[0];assert.ok(index);assert.match(index,/href="#registries\/reg-cll\?theme=response"/);assert.match(index,/data-registry-theme="response"/);assert.doesNotMatch(index,/sub-tab|sub-nav|data-tab=|data-sub=|role="tab/);
 assert.equal((result.match(/class="registry-theme-section"/g)||[]).length,5);
});
test('theme restoration flushes deferred content before focus and aria-current updates',()=>{
 const events=[],links=['stage','response'].map(id=>({dataset:{registryTheme:id},attrs:{},setAttribute(key,value){this.attrs[key]=value;},removeAttribute(key){delete this.attrs[key];}}));
 const target={id:'registry-cll-theme-response',querySelector:()=>({id:'response-heading'})},pane={dataset:{},querySelectorAll:()=>links};let rendered=false;
 const {ctx,run}=runtime({document:{getElementById:id=>id==='reg-cll'?pane:id==='registry-cll-theme-response'&&rendered?target:null},flushPendingRenders:()=>{rendered=true;events.push('render');},scrollToAtlasTarget:node=>events.push(node.id)});routes(ctx);fn('restoreRegistryTheme',ctx);
 run("restoreRegistryTheme(readAtlasRoute('#registries/reg-cll?theme=response'))");assert.deepEqual(events,['render','response-heading']);assert.equal(links[1].attrs['aria-current'],'location');assert.equal(links[0].attrs['aria-current'],undefined);
 run("restoreRegistryTheme(readAtlasRoute('#registries/reg-cll?theme=invalid'))");assert.equal(links[1].attrs['aria-current'],undefined);assert.equal(pane.dataset.registryTheme,'');
});
test('route updates preserve same-registry theme through search and drop it when switching scopes',()=>{
 const hashes=[],window={location:{hash:'#registries/reg-cll?theme=response'},history:{state:{},pushState(state,_title,hash){this.state=state;this.lastHash=hash;window.location.hash=hash;hashes.push(hash);},replaceState(state,_title,hash){this.pushState(state,_title,hash);}}};
 const {ctx,run}=runtime({window,document:{getElementById:id=>id==='global-atlas-search'?{value:'mrd'}:null},isQaRoute:()=>false,appState:{}});routes(ctx);fn('updateShareUrl',ctx);
 run("updateShareUrl('registries','reg-cll',true)");assert.equal(hashes.at(-1),'#registries/reg-cll?g=mrd&theme=response');
 run("updateShareUrl('registries','reg-lyfo',false)");assert.equal(hashes.at(-1),'#registries/reg-lyfo?g=mrd');
 run("updateShareUrl('clinical','clinical-notes',false,{theme:'response'})");assert.equal(hashes.at(-1),'#clinical/clinical-notes?g=mrd');
});
test('one delegated theme activation writes history once and keeps modifier clicks native',()=>{
 const listeners=[],updates=[],restores=[],pane={id:'reg-cll'},link={dataset:{registryTheme:'response',registrySub:'reg-cll'},closest:selector=>selector==='.sub-pane'?pane:null};
 const {ctx,run}=runtime({document:{addEventListener:(type,handler)=>listeners.push({type,handler})},window:{location:{hash:'#registries/reg-cll?g=mrd'}},activeSubForTab:()=> 'reg-cll',updateShareUrl:(...args)=>updates.push(args),restoreRegistryTheme:route=>restores.push(route)});routes(ctx);
 const block=html.split('/* REGISTRY_THEME_ACTION_START */')[1]?.split('/* REGISTRY_THEME_ACTION_END */')[0];assert.ok(block);vm.runInContext(block,ctx);assert.equal(listeners.length,1);
 let prevented=0;const event={button:0,target:{closest:selector=>selector==='[data-registry-theme]'?link:null},preventDefault:()=>prevented++};listeners[0].handler(event);assert.equal(prevented,1);assert.equal(updates.length,1);assert.equal(updates[0][3].theme,'response');assert.equal(updates[0][3].g,'mrd');assert.equal(restores[0].theme,'response');
 listeners[0].handler({...event,ctrlKey:true});assert.equal(updates.length,1);
});
test('registry overview categories gate original flags and nulls before human labels too',()=>{
 const output={};const {ctx,run}=runtime({registryCards:{CLL:{table_name:'RKKP_CLL',n_rows:50,n_cols:5,facets:[row('Safe',50,{registry:'CLL',table_name:'RKKP_CLL'}),row('SECRET',87654321,{value_privacy_status:'unknown_future_restriction'}),row(null,25),row('Missing count',null)]}},setHtml:(id,result)=>output[id]=result,deferRender:(_id,render)=>render()});load('      function bars(', '      deferRender("npu-cards"',ctx);
 load('      deferRender("registry-cards",', '      fillSelect("panel-group-filter"',ctx);
 assert.doesNotMatch(output['registry-cards'],/SECRET|87,654,321|Missing count|\(null\)/);assert.match(output['registry-cards'],/Safe/);assert.match(output['registry-cards'],/withheld/i);assert.equal((output['registry-cards'].match(/class="track"/g)||[]).length,1);
});
test('complete registry panels preserve supported counts and zeroes alongside withheld rows',()=>{
 for(const [source,renderer,panel,facet,field] of [['RKKP_DaMyDa','renderDaMyDaPanel','damyda_clinical_profile','stage','Stadie'],['RKKP_LYFO','renderLYFOPanel','lyfo_clinical_profile','ann_arbor_stage','Reg_Stadium'],['RKKP_CLL','renderCLLPanel','cll_clinical_profile','binet','Reg_BinetStadium']]){
  const {run}=runtime({catalogRows:[{table_name:source}],columnRows:[profile(source,field)],panels:{[panel]:[row('Published',50,{table_name:source,source_column:field,facet}),row('Zero',0,{table_name:source,source_column:field,facet}),row('SECRET',87654321,{table_name:source,source_column:field,facet,value_privacy_status:'withheld_unvalidated_distribution'})]}});
  const result=theme(run(`${renderer}()`),`${panel.split('_')[0]}-theme-stage`);assert.equal((result.match(/class="track"/g)||[]).length,2);assert.match(result,/<div class="val">0<\/div>/);assert.doesNotMatch(result,/SECRET|87,654,321/);assert.equal((result.match(/Category frequencies withheld/g)||[]).length,1);
 }
});
test('plain registry arrival clears a theme selection left in the pane after changing sections',()=>{
 const links=[{dataset:{registryTheme:'response'},attrs:{'aria-current':'location'},setAttribute(key,value){this.attrs[key]=value;},removeAttribute(key){delete this.attrs[key];}}],pane={dataset:{registryTheme:'response'},querySelectorAll:()=>links,querySelector:()=>null};
 const window={location:{hash:'#clinical/clinical-notes'},history:{state:{},pushState(state,_title,hash){this.state=state;window.location.hash=hash;},replaceState(){}}};
 const {ctx,run}=runtime({window,document:{getElementById:id=>id==='tab-registries'?{}:id==='reg-cll'?pane:id==='global-atlas-search'?{value:''}:null},isQaRoute:()=>false,activateTab(){},activateSubPane(){},activeSubForTab:()=> 'reg-cll',collapseGlobalSearch(){},flushPendingRenders(){},appState:{}});fn('updateShareUrl',ctx);fn('restoreRegistryTheme',ctx);fn('jumpToPanel',ctx);
 run("jumpToPanel('registries','reg-cll',{scroll:false})");assert.equal(window.location.hash,'#registries/reg-cll?g=');assert.equal(pane.dataset.registryTheme,'');assert.equal(links[0].attrs['aria-current'],undefined);
});
test('a published category zero has zero bar width even when original source totals are retained',()=>{
 const {ctx,run}=runtime();ctx.rows=[row('Published zero',0,{n_rows:9999,pct_available:100,profile_scope:'full source'}),row('Positive',50,{n_rows:9999,profile_scope:'full source'})];
 const result=run('renderRegistryCategories(rows)');assert.match(result,/Published zero[\s\S]*?width:0%/);assert.match(result,/Positive[\s\S]*?width:100%/);assert.match(result,/RKKP_LYFO \/ Reg_Stadium/);assert.match(result,/full source/);assert.equal(ctx.rows[0].n_rows,9999);
});
test('registry date fields remain discovery rows even if a supplied numeric summary claims eligibility',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_CLL'}],columnRows:[profile('RKKP_CLL','Beh_Responsevaluering_dt',{profile_kind:'date',numeric_privacy_status:'eligible_stored_summary',median:87654321,min_date:'2000-01-01',max_date:'2020-01-01'})]});const response=theme(run('renderCLLPanel()'),'cll-theme-response');assert.match(response,/field=Beh_Responsevaluering_dt/);assert.doesNotMatch(response,/Median:|87,654,321|2000-01-01|2020-01-01|class="track"/);
});
test('supported sensitivity markers exclude retained categories while mixed safe positive and zero rows survive',()=>{
 for(const marker of [{is_sensitive:true},{is_sensitive:'TRUE'},{profile_kind:'sensitive'}]){
  const {ctx,run}=runtime();ctx.rows=[row('RETAINED_PRIVATE_MARKER',87654321,marker),row('Safe positive',50,{is_sensitive:false}),row('Safe zero',0)];
  const result=run('renderRegistryCategories(rows)');assert.doesNotMatch(result,/RETAINED_PRIVATE_MARKER|87,654,321/);assert.match(result,/Safe positive/);assert.match(result,/Safe zero/);assert.equal((result.match(/class="track"/g)||[]).length,2);assert.match(result,/<div class="val">0<\/div>/);assert.equal((result.match(/Category frequencies withheld/g)||[]).length,1);assert.equal(ctx.rows[0].n,87654321);
 }
});
test('is_sensitive protects retained field availability counts and numeric values without hiding its exact evidence action',()=>{
 for(const is_sensitive of [true,'TRUE']){
  const {ctx,run}=runtime();ctx.row=profile('RKKP_CLL','Reg_Beta2Microglobulin',{profile_kind:'numeric',is_sensitive,n_available:87654321,n_missing:12345678,numeric_privacy_status:'eligible_stored_summary',median:22222222});
  const result=run("renderRegistryFieldProfile(row,'reg_cll')");assert.doesNotMatch(result,/87,654,321|12,345,678|22,222,222|Median:/);assert.match(result,/Availability counts withheld/);assert.match(result,/field=Reg_Beta2Microglobulin/);
 }
});
test('false and unset sensitivity markers preserve published categories and field zeroes',()=>{
 for(const marker of [{},{is_sensitive:false},{is_sensitive:'false'},{is_sensitive:null}]){
  const {ctx,run}=runtime();ctx.rows=[row('Safe zero',0,marker)];const categories=run('renderRegistryCategories(rows)');assert.match(categories,/<div class="val">0<\/div>/);assert.match(categories,/width:0%/);assert.doesNotMatch(categories,/withheld/i);
  ctx.row=profile('RKKP_CLL','Reg_Beta2Microglobulin',{profile_kind:'numeric',n_available:0,n_missing:50,numeric_privacy_status:'eligible_stored_summary',median:0,...marker});const field=run("renderRegistryFieldProfile(row,'reg_cll')");assert.match(field,/0 source records with a value/);assert.match(field,/50 missing source records/);assert.match(field,/Median: 0/);assert.doesNotMatch(field,/Availability counts withheld/);
 }
});
test('opening registry choices precede source context while normal provenance and loaded status are disclosed',()=>{
 const {run}=runtime({payload:{clinical_source_inventory:inventory([membership('RKKP_CLL')])},catalogRows:[{table_name:'RKKP_CLL',n_rows:100,n_cols:8}],columnRows:[profile('RKKP_CLL','Reg_BinetStadium')]});
 const result=run('renderCLLPanel()');assert.ok(result.indexOf('class="registry-theme-index"')<result.indexOf('data-registry-source="RKKP_CLL"'));
 const strip=run("renderRegistrySourceStrip('reg_cll',domainSourceInventory(domainSourceSpecs('reg_cll')))");const primary=strip.split('<details class="lineage-block registry-scope-details">')[0],disclosure=strip.slice(primary.length);
 assert.match(primary,/100 source records/);assert.match(primary,/8 catalog fields/);assert.match(primary,/1 published field profiles/);assert.match(primary,/data-source-fields="RKKP_CLL"/);assert.match(primary,/view=timeplace&amp;source=RKKP_CLL/);assert.doesNotMatch(primary,/imported snapshot|Reviewed exact source identities|upstream coverage|Supplied load status: loaded/);assert.match(disclosure,/imported snapshot/);assert.match(disclosure,/Supplied load status: loaded/);assert.match(disclosure,/Patient denominators/);
});
test('compact primary source context retains limited, unloaded and conflicting states',()=>{
 for(const [rowChange,state,catalog,want] of [[{},'limited',[{table_name:'RKKP_CLL',n_rows:100}],/Limited supplied inventory/],[{load_status:'not_loaded',load_state:'not_loaded'},'present',[{table_name:'RKKP_CLL',load_status:'not_loaded',n_rows:100}],/not loaded or not tested/],[{canonical_resource_id:null,canonical_lineage_state:'conflicting'},'present',[{table_name:'RKKP_CLL',n_rows:100}],/Canonical lineage conflicting/]]){
  const {run}=runtime({payload:{clinical_source_inventory:{...inventory([membership('RKKP_CLL','reg_cll',rowChange)]),inventory_state:state}},catalogRows:catalog});const strip=run("renderRegistrySourceStrip('reg_cll',domainSourceInventory(domainSourceSpecs('reg_cll')))");assert.match(strip.split('<details class="lineage-block registry-scope-details">')[0],want);
 }
});
test('unclassified LYFO workup offers one explanation and a visible exact source action',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_LYFO'}],columnRows:[profile('RKKP_LYFO','Reg_Lokal_Knoglemarv')]});const result=theme(run('renderLYFOPanel()'),'lyfo-theme-workup');
 assert.doesNotMatch(result,/registry-summary-status|No reviewed field mapping|<details|field=Reg_Lokal_Knoglemarv/);assert.match(result,/not been classified/);assert.match(result,/Disease-site fields describe involvement/);assert.match(result,/class="registry-field-action"[^>]*source=RKKP_LYFO/);
});
test('reviewed treatment forms and disease-site groups expose their complete exact clinical breadth',()=>{
 const cases=[['RKKP_DaMyDa','renderDaMyDaPanel','damyda-theme-treatment',['Reg_PlanlagtBeh_Lenalidomid','PB_Behandling_MelfalanStamcelle','SB_Behandling_Elotuzumab'],/Planned treatment[\s\S]*Primary treatment[\s\S]*Secondary treatment/],['RKKP_LYFO','renderLYFOPanel','lyfo-theme-sites',['Reg_Lokal_Waldeyers','Reg_Lokal_Testis','Reg_Lokal_Leptomeninges'],/Head and neck[\s\S]*Urogenital[\s\S]*Nervous system/]];
 for(const [source,renderer,id,fields,groups] of cases){const {run}=runtime({catalogRows:[{table_name:source}],columnRows:fields.map(f=>profile(source,f))});const result=theme(run(`${renderer}()`),id);for(const field of fields)assert.match(result,new RegExp(`field=${field}`));assert.match(result,groups);assert.match(result,/<details class="registry-clinical-group"/);}
});
test('LYFO immunoglobulins show finite stored mean median and IQR beside unguessed source units',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_LYFO'}],columnRows:['Reg_ImmunglobulinA_gL','Reg_ImmunglobulinG_gL','Reg_ImmunglobulinM_gL'].map(f=>profile('RKKP_LYFO',f,{profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',mean:2,median:1,p25:0,p75:3,summary_scope:'stored_source_row_profile',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample'}))});const result=theme(run('renderLYFOPanel()'),'lyfo-theme-baseline');assert.equal((result.match(/Mean: 2/g)||[]).length,3);assert.equal((result.match(/Median: 1/g)||[]).length,3);assert.equal((result.match(/IQR: 0–3/g)||[]).length,3);assert.equal((result.match(/Unit not supplied in this source profile/g)||[]).length,3);assert.match(result,/stored source rows/i);assert.match(result,/bounded stream sample/i);assert.doesNotMatch(result,/registry-summary-status|Source unit metadata: g\/L/);
});
test('complete catalogue finds unmapped exact source fields by label or column without assigning a clinical theme',()=>{
 const {ctx,run}=runtime({catalogRows:[{table_name:'RKKP_CLL'}],columnRows:[profile('RKKP_CLL','Unknown_ClinicalField'),profile('RKKP_CLL','Reg_Performancestatus'),profile('Other','Unknown_ClinicalField')],payload:{clinical_display_dictionary:[{kind:'field',system:'RKKP_CLL',code:'Unknown_ClinicalField',label:'A reviewed readable label'}]}});
 const result=run('renderCLLPanel()');assert.match(result,/data-registry-catalogue="reg_cll"/);ctx.sources=run("domainSourceInventory(domainSourceSpecs('reg_cll'))");const found=run("registryCataloguePage('reg_cll',sources,'readable',0)");assert.equal(found.total,1);assert.equal(found.rows[0].row.column_name,'Unknown_ClinicalField');assert.equal(found.rows[0].theme,'Unclassified');assert.equal(run("registryCataloguePage('reg_cll',sources,'performancestatus',0).total"),1);
});
test('LYFO subtype definitions are reference meanings even when observed subtype frequencies are withheld',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_LYFO'}],payload:{clinical_display_dictionary:[{kind:'registry_value',system:'RKKP_LYFO:subtype',code:'MCL',label:'Mantle cell lymphoma',definition:'Supplied reference meaning',source_label:'Reviewed reference'}]},panels:{lyfo_clinical_profile:[row('SECRET',87654321,{facet:'subtype',source_column:'Reg_WHOHistologikode1',value_privacy_status:'withheld_unvalidated_distribution'})]}});const result=run('renderLYFOPanel()');assert.match(result,/Mantle cell lymphoma/);assert.match(result,/Reference meanings/);assert.match(result,/not observed cases/);assert.doesNotMatch(result,/SECRET|87,654,321/);assert.equal((result.match(/Category frequencies withheld/g)||[]).length,1);
});
test('registry coverage shows supplied event years and regions while withholding unknown flags and inferred bounds',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_DaMyDa'}],reviewTemporal:{years:[{table_name:'RKKP_DaMyDa',date_column:'Diagnosedato',year:2005,n_rows:50,coverage_basis:'event_date_counts'},{table_name:'RKKP_DaMyDa',date_column:'Diagnosedato',year:2024,n_rows:70,coverage_basis:'event_date_counts'},{table_name:'RKKP_DaMyDa',date_column:'SECRET_DATE',year:2099,n_rows:87654321,coverage_basis:'unreviewed_future_basis'}]},reviewSpatial:{region_counts:[{table_name:'RKKP_DaMyDa',region_name:'North Denmark Region',region_column:'Region',n_rows:80},{table_name:'RKKP_DaMyDa',region_name:'SECRET_REGION',region_column:'Region',n_rows:87654321,value_privacy_status:'future_policy'}]}});
 const result=run('renderDaMyDaPanel()');assert.match(result,/Source years and regions/);assert.match(result,/2005–2024/);assert.match(result,/North Denmark Region/);assert.doesNotMatch(result,/SECRET_DATE|2099|SECRET_REGION|87,654,321/);
 const absent=runtime({catalogRows:[{table_name:'RKKP_LYFO'}]}).run('renderLYFOPanel()');assert.match(absent,/Year summaries are not available in this export/);assert.match(absent,/No direct region counts are supplied/);
});
test('unrecognized availability status and conflicting profile identity fail closed in topics and catalogue',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_CLL'}],columnRows:[profile('RKKP_CLL','Reg_Performancestatus',{n_available:87654321,availability_privacy_status:'future_policy'}),profile('RKKP_CLL','Reg_FAMCLL',{source_name:'Other',n_available:87654321})]});const result=run('renderCLLPanel()');assert.doesNotMatch(result,/87,654,321/);assert.match(result,/Availability counts withheld/);assert.doesNotMatch(result,/field=Reg_FAMCLL/);
});
test('registry catalogue search and paging rerender exact results while preserving the search input',()=>{
 const results={innerHTML:''},input={value:'Field31'},catalogue={dataset:{registryCatalogue:'reg_cll'},querySelector:selector=>selector==='[data-registry-catalogue-results]'?results:input};
 const {ctx,run}=runtime({scrollToAtlasTarget:()=>{},catalogRows:[{table_name:'RKKP_CLL'}],columnRows:Array.from({length:35},(_,i)=>profile('RKKP_CLL',`Field${i}`))});
 fn('handleRegistryCatalogueSearch',ctx);fn('handleRegistryCataloguePage',ctx);ctx.event={target:{closest:selector=>selector==='[data-registry-catalogue-search]'?{value:input.value,closest:()=>catalogue}:null}};
 run('handleRegistryCatalogueSearch(event)');assert.match(results.innerHTML,/1–1 of 1/);assert.match(results.innerHTML,/field=Field31/);assert.doesNotMatch(results.innerHTML,/field=Field0(?:&|"|<)/);assert.equal(input.value,'Field31');
 input.value='';ctx.event={target:{closest:()=>({dataset:{registryCataloguePage:'1'},closest:()=>catalogue})}};run('handleRegistryCataloguePage(event)');assert.match(results.innerHTML,/31–35 of 35/);assert.match(results.innerHTML,/field=Field34/);assert.doesNotMatch(results.innerHTML,/field=Field0(?:&|"|<)/);
});
test('explicit blocked numeric validation cannot publish retained summaries despite an eligibility claim',()=>{
 const {ctx,run}=runtime();ctx.row=profile('RKKP_CLL','Reg_Beta2Microglobulin',{profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',validation_status:'blocked',mean:87654321,median:87654321});const result=run("renderRegistryFieldProfile(row,'reg_cll')");assert.doesNotMatch(result,/87,654,321|Median:|Mean:/);
});
test('reviewed nodal indicators and M-protein are classified while undefined peri localization has no thoracic claim',()=>{
 const {run}=runtime();assert.equal(run("registryDiscoverySpecs.reg_lyfo.themes.find(t=>t.id==='sites').groups.some(g=>g.fields.includes('Reg_Sygdomslokalisation_nodal'))"),true);assert.equal(run("registryDiscoverySpecs.reg_lyfo.themes.find(t=>t.id==='sites').groups.some(g=>g.fields.includes('Reg_Sygdomslokal_extranodel'))"),true);assert.equal(run("registryDiscoverySpecs.reg_lyfo.themes.find(t=>t.id==='sites').groups.find(g=>g.fields.includes('Reg_Lokal_peri_Lymfom')).title"),'Other involvement fields');assert.equal(run("registryDiscoverySpecs.reg_damyda.themes.find(t=>t.id==='baseline').groups.some(g=>g.fields.includes('Reg_Mkomponent'))"),true);
});
test('catalogue and DaMyDa fallback summaries reject every unknown privacy or suppression marker',()=>{
 for(const flags of [{value_privacy_status:'future_restriction'},{value_privacy_status:'protected_field'},{new_privacy_status:'future_policy'},{suppressed:true},{withheld:'TRUE'},{protected:true},{is_suppressed:true},{is_protected:'true'}]){
  const stored={profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:87654321,mean:87654321,...flags};
  const catalogue=runtime({catalogRows:[{table_name:'RKKP_CLL'}],columnRows:[profile('RKKP_CLL','UnclassifiedNumeric',stored)]}).run('renderCLLPanel()');assert.doesNotMatch(catalogue,/87,654,321|Median:|Mean:/);
  const fallback=runtime({catalogRows:[{table_name:'RKKP_DaMyDa'}],columnRows:[profile('RKKP_DaMyDa','Reg_Haemoglobin')],panels:{damyda_numeric_fields:[{table_name:'RKKP_DaMyDa',source_column:'Reg_Haemoglobin',...stored}]}}).run('renderDaMyDaPanel()');assert.doesNotMatch(fallback,/87,654,321|Median:|Mean:/);
 }
});
test('category-only withholding preserves explicitly permitted numeric summaries but date-like rows never publish',()=>{
 const {ctx,run}=runtime();ctx.row=profile('RKKP_LYFO','Reg_Haemoglobin',{profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',value_privacy_status:'withheld_unvalidated_distribution',date_privacy_status:'withheld_exact_clinical_bounds',median:0,suppressed:'FALSE'});assert.match(run("renderRegistryFieldProfile(row,'reg_lyfo')"),/Median: 0/);
 ctx.row.is_date_like='TRUE';assert.doesNotMatch(run("renderRegistryFieldProfile(row,'reg_lyfo')"),/Median:/);
});
test('catalogue controls expose clear search, both paging positions and useful empty-result guidance',()=>{
 const {run}=runtime({catalogRows:[{table_name:'RKKP_CLL'}],columnRows:Array.from({length:35},(_,i)=>profile('RKKP_CLL',`Field${i}`))});const result=run('renderCLLPanel()');assert.match(result,/Find any registry field/);assert.match(result,/data-registry-catalogue-clear/);assert.equal((result.match(/data-registry-catalogue-page="1"/g)||[]).length,2);assert.match(result,/distinct published field identities/);assert.doesNotMatch(result,/Complete published field catalogue/);const empty=run("renderRegistryCatalogueResults('reg_cll',domainSourceInventory(domainSourceSpecs('reg_cll')),'no-match',0)");assert.match(empty,/Try a shorter clinical term or exact column name/);
});
test('LYFO baseline separates immunoglobulins and shares numeric interpretation once per group',()=>{
 const fields=['Reg_Haemoglobin','Reg_Albumin_gL','Reg_ImmunglobulinA_gL','Reg_ImmunglobulinG_gL','Reg_ImmunglobulinM_gL'];
 const {run}=runtime({catalogRows:[{table_name:'RKKP_LYFO'}],columnRows:[...fields.map(f=>profile('RKKP_LYFO',f,{profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:2,summary_scope:'stored_source_row_profile',summary_method:'quantiles_may_use_bounded_stream_sample'})),profile('RKKP_LYFO','Reg_ImmunglobulinA_Mikmoll',{profile_kind:'numeric'})]});const result=theme(run('renderLYFOPanel()'),'lyfo-theme-baseline');assert.match(result,/<h4>Blood and biochemical markers<\/h4>/);assert.match(result,/<h4>Immunoglobulins · IgA, IgG and IgM<\/h4>/);assert.match(result,/Additional marker fields and unit variants/);assert.equal((result.match(/not a clinical reference range/g)||[]).length,2);assert.equal((result.match(/Unit not supplied in this source profile/g)||[]).length,6);
});
test('reviewed myeloma form complications and bone examinations are discoverable without interpreting unreviewed fields',()=>{
 const fields=['PB_Manifestekomp_Hypercal','SB_Manifestekomp_Amyloidose','FU_Manifestekomp_Neuropati','Reg_Knogleundersoegelser_dexa','Reg_Knogleundersoegelser_scinti','Reg_Knogleundersoegelser_other','Reg_AndreKnogleundersoegelse','Reg_AndenKnogleundersoegelse','PB_Manifestekomp_Unreviewed'];const {run}=runtime({catalogRows:[{table_name:'RKKP_DaMyDa'}],columnRows:fields.map(f=>profile('RKKP_DaMyDa',f))});const result=run('renderDaMyDaPanel()');const response=theme(result,'damyda-theme-response'),workup=theme(result,'damyda-theme-workup');for(const field of fields.slice(0,3))assert.match(response,new RegExp(`field=${field}`));for(const field of fields.slice(3,8))assert.match(workup,new RegExp(`field=${field}`));assert.doesNotMatch(response,/field=PB_Manifestekomp_Unreviewed/);
});
test('find-field action opens catalogue and clear search restores results with keyboard focus',()=>{
 const effects=[],results={innerHTML:''},input={value:'NO_MATCH',focus:()=>effects.push('search focus'),scrollIntoView:()=>effects.push('search scroll')},catalogue={open:false,dataset:{registryCatalogue:'reg_cll'},querySelector:selector=>selector==='[data-registry-catalogue-results]'?results:input};
 const {ctx,run}=runtime({document:{getElementById:()=>catalogue},catalogRows:[{table_name:'RKKP_CLL'}],columnRows:[profile('RKKP_CLL','Reg_BinetStadium')]});fn('handleRegistryCatalogueAction',ctx);ctx.event={target:{closest:selector=>selector==='[data-registry-catalogue-open]'?{dataset:{registryCatalogueOpen:'reg_cll'}}:null}};run('handleRegistryCatalogueAction(event)');assert.equal(catalogue.open,true);assert.deepEqual(effects,['search scroll','search focus']);
 effects.length=0;ctx.event={target:{closest:selector=>selector==='[data-registry-catalogue-clear]'?{closest:()=>catalogue}:null}};run('handleRegistryCatalogueAction(event)');assert.equal(input.value,'');assert.match(results.innerHTML,/field=Reg_BinetStadium/);assert.match(results.innerHTML,/1–1 of 1/);assert.deepEqual(effects,['search focus']);
});
test('catalogue page changes retain search and focus the updated result status',()=>{
 const effects=[],status={id:'result-status'},results={innerHTML:''},input={value:'Field'},catalogue={dataset:{registryCatalogue:'reg_cll'},querySelector:selector=>selector==='[data-registry-catalogue-results]'?results:selector==='[data-registry-catalogue-status]'?status:input};const {ctx,run}=runtime({scrollToAtlasTarget:target=>effects.push(target.id),catalogRows:[{table_name:'RKKP_CLL'}],columnRows:Array.from({length:35},(_,i)=>profile('RKKP_CLL',`Field${i}`))});fn('handleRegistryCataloguePage',ctx);ctx.event={target:{closest:()=>({dataset:{registryCataloguePage:'1'},closest:()=>catalogue})}};run('handleRegistryCataloguePage(event)');assert.equal(input.value,'Field');assert.match(results.innerHTML,/31–35 of 35/);assert.deepEqual(effects,['result-status']);
});
test('registry overview numeric cards apply the same unknown restriction guard',()=>{
 const {ctx,run}=runtime();ctx.row={source_column:'Reg_Haemoglobin',numeric_privacy_status:'eligible_stored_summary',median:87654321,value_privacy_status:'future_restriction'};assert.doesNotMatch(run("renderRegistryNumericCard(row,'Haemoglobin','RKKP_DaMyDa')"),/87,654,321|Median:/);
});
