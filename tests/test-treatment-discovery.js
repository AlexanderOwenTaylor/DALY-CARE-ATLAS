const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
const selected={SP_AdministreretMedicin:['mar_action_c','taken_time','atc','sig','zc_med_unit_name','zc_admin_route_name'],SP_OrdineretMedicin:['order_status_c','order_start_time','atc','is_pending_ord_yn','hv_discrete_dose']};
const profiles=Object.entries(selected).flatMap(([table_name,fields])=>fields.map(column_name=>({table_name,column_name})));
function runtime(extra={}){
 const ctx=vm.createContext({URLSearchParams,columnRows:profiles,clinicalDictionaryRows:profiles.map(r=>({kind:'field',system:r.table_name,code:r.column_name,label:`Reviewed ${r.column_name}`})),reviewTreatment:{treatment_sources:[{table_name:'SDS_t_sksube',n_rows:9999},{table_name:'SP_OrdineretMedicin',n_rows:200},{table_name:'SP_AdministreretMedicin',n_rows:100}]},semanticCodeRows:[],panelDistributionRows:[],panelRawFieldRows:[],domainPanelRows:[],treatmentCards:{},panels:{},sourceDisplayName:x=>x,renderObservedTreatmentCodes:()=>'',renderTermHelp:()=>'',renderSectionCard:(title,body)=>`<section><h3>${title}</h3>${body}</section>`,renderValueMapCard:()=>'',renderBadge:()=>'',observedRowsWithheld:()=>false,...extra});
 const load=(a,b)=>vm.runInContext(html.slice(html.indexOf(a),html.indexOf(b,html.indexOf(a))),ctx);
 load('      function text(','      function metric(');
 for(const name of ['toneColor','renderKpiStrip','browseFieldsLink','sourceEvidenceLinks']){const a=html.indexOf(`      function ${name}(`),b=html.indexOf('\n      function ',a+1);vm.runInContext(html.slice(a,b),ctx);}
 load('      function treatmentContains(','      const imagingLayerSpecs =');
 return {ctx,run:code=>vm.runInContext(code,ctx),panel:()=>vm.runInContext('renderTreatmentPanel()',ctx)};
}
const primary=panel=>panel.split('<details class="lineage-block"><summary>Code mappings, other treatment signals and technical lineage</summary>')[0];
const links=markup=>[...markup.matchAll(/href="([^"]+)"/g)].map(m=>new URL(m[1].replace(/&amp;/g,'&'),'https://atlas.test/')).filter(u=>u.searchParams.has('field'));
test('primary treatment arrival promotes existing administration then orders and links all eleven exact pairs once',()=>{
 const panel=runtime().panel(),body=primary(panel),urls=links(panel);
 assert.equal(urls.length,11);
 assert.deepEqual(urls.map(u=>[u.searchParams.get('source'),u.searchParams.get('field')]),profiles.map(r=>[r.table_name,r.column_name]));
 assert.ok(body.indexOf('data-treatment-source="SP_AdministreretMedicin"')<body.indexOf('data-treatment-source="SP_OrdineretMedicin"'));
 assert.ok(body.indexOf('data-treatment-source="SP_OrdineretMedicin"')<body.indexOf('SKS procedure/treatment signals'));
 for(const u of urls){assert.equal(u.pathname,'/DALYCARE_outputs.html');assert.equal(u.searchParams.get('view'),'fields');assert.equal(u.searchParams.get('table'),'column_profiles');}
 assert.match(body,/do not establish a delivered dose/);assert.match(body,/do not establish administration/);
 assert.match(body,/data-source-fields="SP_AdministreretMedicin"/);assert.match(body,/view=timeplace&amp;source=SP_OrdineretMedicin/);
 assert.doesNotMatch(panel.slice(body.length),/data-treatment-field=/);
});
test('source enhancement rejects near identities and all conflicting secondary identities without losing source cards',()=>{
 for(const row of [{table_name:'sp_administreretmedicin'},{table_name:'SP_AdministreretMedicin '},{table_name:'SP_AdministreretMedicin_extra'},{table_name:'SP_AdministreretMedicin',source_name:'Medication module'},{table_name:'SP_AdministreretMedicin',object_name:'unknown'},{table_name:'SP_AdministreretMedicin',source_name:'SP_OrdineretMedicin'},{table_name:'SP_AdministreretMedicin',code_system:'NPU'}]){
  const body=primary(runtime({reviewTreatment:{treatment_sources:[row]}}).panel());
  assert.equal(links(body).length,0,JSON.stringify(row));assert.ok(body.includes(row.table_name));
 }
 assert.equal(links(primary(runtime({reviewTreatment:{treatment_sources:[{source_name:'SP_OrdineretMedicin',object_name:'SP_OrdineretMedicin'}]}}).panel())).length,5);
 assert.equal(links(primary(runtime({reviewTreatment:{treatment_sources:[]}}).panel())).length,0);
});
test('exact labels reject normalized, conflicting and malformed definitions, while identical reviewed labels survive escaped',()=>{
 const exact={kind:'field',system:'SP_AdministreretMedicin',code:'mar_action_c',label:'Action <reviewed> & exact'};
 for(const definitions of [[{...exact,system:'sp_administreretmedicin'}],[exact,{...exact,label:''}],[exact,{...exact,label:{bad:true}}],[exact,{...exact,label:'Other'}]]){
  const body=primary(runtime({clinicalDictionaryRows:definitions}).panel());assert.doesNotMatch(body,/Action &lt;reviewed&gt;/);assert.match(body,/>mar_action_c<\/a>/);
 }
 assert.match(primary(runtime({clinicalDictionaryRows:[exact,{...exact}]}).panel()),/>Action &lt;reviewed&gt; &amp; exact<code>mar_action_c<\/code><\/a>/);
});
test('missing, multiple, protected and unknown profile states stay truthful without previews or borrowed profiles',()=>{
 const rows=profiles.filter(r=>r.column_name!=='taken_time').map(r=>({...r,median:'SENSITIVE_PREVIEW',top_values:'CATEGORY_PREVIEW'}));
 rows.push({table_name:'SP_AdministreretMedicin ',column_name:'taken_time'});
 rows.find(r=>r.column_name==='zc_med_unit_name').numeric_privacy_status='protected_field';
 rows.find(r=>r.column_name==='atc').numeric_privacy_status='future_marker';
 rows.push({...rows.find(r=>r.column_name==='mar_action_c'),numeric_privacy_status:'withheld_small_cells'});
 const body=primary(runtime({columnRows:rows}).panel());
 assert.equal(links(body).length,10);assert.ok(!links(body).some(u=>u.searchParams.get('field')==='taken_time'));
 assert.match(body,/No published profile/);assert.match(body,/2 profiles/);assert.match(body,/Publication states differ/);assert.match(body,/Protected field/);assert.match(body,/Field links show recorded availability and publication limits/);
 assert.doesNotMatch(body,/SENSITIVE_PREVIEW|CATEGORY_PREVIEW/);
});
test('sensitivity-only profiles show protection and distinguish mixed duplicate states without previewing values',()=>{
 const base={table_name:'SP_AdministreretMedicin',column_name:'mar_action_c',median:'RETAINED_SECRET'};
 for(const marker of [{is_sensitive:true},{is_sensitive:'TRUE'},{profile_kind:'sensitive'}]){
  const single=runtime({columnRows:[{...base,...marker}]}).run("renderTreatmentDiscoveryField('SP_AdministreretMedicin','mar_action_c')");
  assert.match(single,/Protected field/);assert.equal(links(single).length,1);assert.doesNotMatch(single,/RETAINED_SECRET/);
  const mixed=runtime({columnRows:[base,{...base,...marker}]}).run("renderTreatmentDiscoveryField('SP_AdministreretMedicin','mar_action_c')");
  assert.match(mixed,/2 profiles/);assert.match(mixed,/Publication states differ/);assert.doesNotMatch(mixed,/Protected field|RETAINED_SECRET/);
 }
 for(const marker of [{is_sensitive:false},{is_sensitive:'FALSE'},{}]){
  const field=runtime({columnRows:[{...base,...marker}]}).run("renderTreatmentDiscoveryField('SP_AdministreretMedicin','mar_action_c')");
  assert.doesNotMatch(field,/Protected field|Publication details|RETAINED_SECRET/);
 }
});
test('source publication guidance consolidates common and unknown markers without losing field-specific exceptions',()=>{
 const source='SP_AdministreretMedicin',rows=profiles.filter(row=>row.table_name===source).map(row=>({...row,numeric_privacy_status:'future_status'}));
 const {ctx,run}=runtime({columnRows:rows});ctx.source=source;
 const render=()=>run("renderTreatmentDiscoverySource(source,[{table_name:source}],treatmentSourceContext({table_name:source}))");
 const common=render();
 assert.equal((common.match(/Field links show recorded availability and publication limits\./g)||[]).length,1);
 assert.doesNotMatch(common,/class="treatment-field-note"/);assert.equal(links(common).length,6);
 ctx.columnRows=[{...rows[0],is_sensitive:true},rows[1],rows[1],{...rows[2],numeric_privacy_status:'first_reason'},{...rows[2],numeric_privacy_status:'second_reason'},rows[3],rows[4]];
 const mixed=render(),field=key=>mixed.match(new RegExp(`<li data-treatment-field="${key}">([\\s\\S]*?)<\\/li>`))[1];
 assert.equal((mixed.match(/Field links show recorded availability and publication limits\./g)||[]).length,1);
 assert.match(field('mar_action_c'),/Protected field/);assert.match(field('taken_time'),/2 profiles/);
 assert.match(field('atc'),/2 profiles.*Publication states differ/);assert.match(field('zc_admin_route_name'),/No published profile/);
 assert.equal(links(mixed).length,5);
 ctx.columnRows=rows.map(row=>({...row,numeric_privacy_status:'eligible_stored_summary'}));
 assert.doesNotMatch(render(),/Field links show recorded availability and publication limits/);
});
test('duplicate source entries share one discovery list but retain every original source fact in details',()=>{
 const rows=[{table_name:'SP_AdministreretMedicin',n_rows:0,n_cols:null},{table_name:'SP_AdministreretMedicin',n_rows:'withheld',n_cols:7}];
 const {ctx,run,panel}=runtime({reviewTreatment:{treatment_sources:rows}});ctx.sources=rows;
 const body=primary(panel());assert.equal(links(body).length,6);assert.match(body,/2 supplied source entries/);
 assert.ok(body.includes(run("renderTreatmentSourceCards(sources,'SP administered medication')")));
 assert.match(body,/<b>0<\/b>/);assert.match(body,/not available/);assert.match(body,/withheld/);
});
test('primary group seam preserves unknown and ordinary fallback order and never manufactures a missing source',()=>{
 const {ctx,run}=runtime();ctx.groups=['future_b','sp_ordered','future_a','sp_administered','future_c'].map(id=>({context:{id,label:id,description:id},rows:[{table_name:id==='sp_ordered'?'SP_OrdineretMedicin':id==='sp_administered'?'SP_AdministreretMedicin':id}]}));
 const body=run('renderTreatmentPrimaryGroups(groups)');assert.ok(body.indexOf('SP_AdministreretMedicin')<body.indexOf('SP_OrdineretMedicin'));
 assert.ok(body.indexOf('<h3>future_b')<body.indexOf('<h3>future_a'));assert.ok(body.indexOf('<h3>future_a')<body.indexOf('<h3>future_c'));
 ctx.groups=ctx.groups.filter(g=>!g.context.id.startsWith('sp_'));const absent=run('renderTreatmentPrimaryGroups(groups)');assert.doesNotMatch(absent,/data-treatment-source=/);
});
