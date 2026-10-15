const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
function presentation(){
 const elements=new Map(),element=id=>{if(!elements.has(id))elements.set(id,{innerHTML:'',textContent:'',querySelectorAll:()=>[]});return elements.get(id);};
 const window={location:{pathname:'DALYCARE_clinical.html'},DALYCARE_SEARCH:{sources:['SP_VitaleVaerdier'],fields:[[0,'recorded_time','']]},DALYCARE_SHELL:{fieldLink:(s,f)=>'DALYCARE_outputs.html?'+new URLSearchParams({source:s,field:f}),contextLinks:()=>'<a>Years and regions</a>'}};
 const ctx=vm.createContext({window,document:{getElementById:element},URLSearchParams});
 vm.runInContext(fs.readFileSync('inst/templates/atlas-topic.js','utf8'),ctx);
 const esc=x=>String(x??'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;');
 return {window,ctx,element,render(id,rows,extra={}){const target=element('detail');window.DALYCARE_TOPIC.renderTable({table:{id,title:id,columns:Object.keys(rows[0]||{}).map(key=>({key}))},result:{rows,total_matches:rows.length,complete:true},esc,format:x=>String(x??'Missing'),target,...extra});return target.innerHTML;}};
}
test('selected profile becomes a readable exact field answer with secondary lineage',()=>{
 const p=presentation(),html=p.render('column_profiles',[{table_name:'RKKP_LYFO',column_name:'Reg_Haemoglobin',numeric_privacy_status:'needs_verified_grouped_evidence',column_type:'numeric'}],{source:'RKKP_LYFO',field:'Reg_Haemoglobin'});
 assert.match(html,/data-primary-answer/);assert.match(html,/RKKP_LYFO.Reg_Haemoglobin/);assert.match(html,/<details/);assert.match(html,/stored.unit/i);
});
test('registry answer retains code meaning and distinct person exclusions without raw repeated cards',()=>{
 const p=presentation(),html=p.render('registry_field_summaries',[{table_name:'RKKP_CLL',source_column:'Reg_BinetStadium',label:'Binet stage',kind:'categorical',summary_status:'published',contract_version:'registry-summary-v2',phase:'registration',denominator_n:40,n_valid:30,n_missing:5,n_unrecognised:5,n_conflicting:0,category_counts_json:'[{"code":"A","n":15},{"code":"B","n":15}]'}]);
 assert.match(html,/data-primary-answer/);assert.match(html,/distinct people/);assert.match(html,/5 unrecognised/);assert.match(html,/Recorded code A/);assert.match(html,/Meaning unverified/);assert.doesNotMatch(html,/Field unavailable in this run/);
});
test('NPU formal definition is primary with reference unit and provenance distinctions',()=>{
 const html=presentation().render('npu_display_dictionary',[{code:'NPU04998',label:'Creatinine',definition:'Exact formal definition',unit:'micromole/L',retrieved_at:'2026-10-14'}]);
 assert.match(html,/data-primary-answer/);assert.match(html,/Exact formal definition/);assert.match(html,/Reference unit/);assert.match(html,/does not verify.*stored/i);
});
test('vital semantic answers distinguish current supported and reference only identities',()=>{
 const p=presentation(),base={source_name:'SP_VitaleVaerdier',raw_column:'displayname',value_column:'meas_value',raw_descriptor:'Puls',clinical_variable:'Pulse',data_shape:'long_descriptor_table',evidence_file:'current panel: vital_descriptors',evidence_filter:'"displayname" = \'Puls\'',mapping_status:'reviewed_display_label'};
 const html=p.render('semantic_dictionary',[base,{...base,raw_descriptor:'Resp.frekvens',mapping_status:'saved_definition_inventory_unassessed'}],{source:'SP_VitaleVaerdier'});
 assert.match(html,/Supported current measurement names/);assert.match(html,/Reference.only/);assert.match(html,/recorded_time/);assert.match(html,/Required filter/);assert.match(html,/meas_value/);assert.match(html,/omitted names.*absent/i);
});
test('coverage label-only rows show null counts as withheld and discrete years',()=>{
 const html=presentation().render('atlas_temporal_coverage_years',[{table_name:'SP_VitaleVaerdier',date_column:'recorded_time',year:2021,n_rows:null,count_privacy_status:'withheld_partition_counts'},{table_name:'SP_VitaleVaerdier',date_column:'recorded_time',year:2024,n_rows:null,count_privacy_status:'withheld_partition_counts'}]);
 assert.match(html,/Counts withheld/);assert.match(html,/2021/);assert.match(html,/2024/);assert.doesNotMatch(html,/2022|2023|0 records/);assert.match(html,/records.*people/i);
});
test('empty observed laboratory evidence differs from a completed unmatched reference search',()=>{
 const p=presentation();assert.match(p.render('lab_npu_code_coverage',[]),/No observed.code evidence/);assert.match(p.render('npu_reference_search',[]),/No reference definition matches/);
});
test('primary detail precedes topic catalogue in the actual shipped markup',()=>{
 const html=fs.readFileSync('inst/templates/DALYCARE_lazy.html','utf8');assert.ok(html.indexOf('id="detail-content"')<html.indexOf('id="route-content"'));
});
test('validated numeric answer renders actual band intervals and containing quartiles',()=>{
 const p=presentation();p.window.DALYCARE_REGISTRY_V2_RESOURCE={fields:[]};p.window.DALYCARERegistryV2={validate:()=>({groups:[{id:'b0_1',band_id:'b0_1',lower:0,upper:10,n:10},{id:'b1_2',band_id:'b1_2',lower:10,upper:20,n:10}]})};
 const html=p.render('registry_field_summaries',[{table_name:'RKKP_DaMyDa',source_column:'Reg_Haemoglobin',kind:'numeric',contract_version:'registry-summary-v2',summary_status:'published',unit_status:'verified',unit_code:'synthetic-unit',denominator_n:20,n_valid:20,n_missing:0,n_unrecognised:0,n_conflicting:0,p25_band:'b0_1',median_band:'b0_1',p75_band:'b1_2',approximate_mean:10,iqr_lower:0,iqr_upper:20,modal_band:'b1_2'}]);
 assert.match(html,/0 ≤ value &lt; 10/);assert.match(html,/10 ≤ value &lt; 20/);assert.match(html,/Approximate midpoint mean/);
 assert.match(html,/Approximate IQR width/);assert.match(html,/Modal band/);assert.doesNotMatch(html,/Interquartile interval/);
});
test('withheld lab usage retains exact code field without invented observed codes',()=>{
 const html=presentation().render('lab_npu_code_coverage',[{table_name:'SP_Laboratorieproever',code_column:'analysiscode',lab_code:null,n:null,value_privacy_status:'withheld_unvalidated_distribution'}]);assert.match(html,/data-primary-answer/);assert.match(html,/SP_Laboratorieproever.analysiscode/);assert.match(html,/Observed code values withheld/);assert.doesNotMatch(html,/0 tests/);
});
test('vital inventory groups exact descriptor identity without pooling distinct result columns',()=>{
 const p=presentation(),base={source_name:'SP_VitaleVaerdier',raw_column:'displayname',raw_descriptor:'Puls',clinical_variable:'Pulse',data_shape:'long_descriptor_table',evidence_file:'current panel: vital_descriptors',mapping_status:'reviewed_display_label',evidence_filter:'displayname = Puls'};
 const html=p.render('semantic_dictionary',['meas_value','meas_value_clean','numericvalue'].map(value_column=>({...base,value_column})),{source:'SP_VitaleVaerdier'});
 assert.equal((html.match(/data-primary-answer/g)||[]).length,1);for(const name of ['meas_value','meas_value_clean','numericvalue'])assert.match(html,new RegExp(name));assert.equal((html.match(/Stored unit/g)||[]).length,1);
});
test('registry browse is compact while an explicitly selected clinical field is expanded',()=>{
 const p=presentation(),row={table_name:'RKKP_DaMyDa',source_column:'Stadie',label:'Recorded stage',kind:'categorical',summary_status:'field_absent'};
 assert.match(p.render('registry_field_summaries',[row]),/<details class="field-outcome"><summary>/);
 assert.doesNotMatch(p.render('registry_field_summaries',[row],{source:row.table_name,field:row.source_column}),/<details class="field-outcome">/);
});
test('task controls are positioned before inventories and primary results',()=>{
 const html=fs.readFileSync('inst/templates/DALYCARE_lazy.html','utf8');assert.ok(html.includes('id="task-content"'));assert.ok(html.indexOf('id="task-content"')<html.indexOf('id="detail-content"'));
});
test('coverage translates date selection and supplies one shared context action',()=>{
 const p=presentation(),html=p.render('atlas_temporal_coverage',[{table_name:'S',date_column:'event_date',selection_basis:'name_prioritised_date_candidate',event_meaning:'Clinical event meaning unverified',n_rows:20}],{source:'S'});
 assert.match(html,/Selected by date-field name priority/);assert.match(html,/Source records/);assert.equal((html.match(/Years and regions/g)||[]).length,1);
});

// Follow the emitted profile-to-definition link through the real writer/reader.
test('generated exact vital definitions and missing-date coverage preserve their evidence scope',async()=>{
 const path=require('node:path'),cp=require('node:child_process'),root=process.cwd(),site=path.join(root,'.artifact-temp/E2-clinician-regression-site'),measurements=[];
 cp.execFileSync(process.env.PYTHON||(process.platform==='win32'?'python':'python3'),['tests/generate-screened-site.py',site,'--clinician'],{cwd:root,stdio:'pipe'});
 const harnessSource=fs.readFileSync('tests/test-lazy-production.js','utf8');eval(harnessSource.slice(harnessSource.indexOf('function harness('),harnessSource.indexOf("\ntest('production opening")));
 for(const field of ['meas_value','recorded_time']){
  const h=harness('?table=column_profiles&source=SP_VitaleVaerdier&field='+field);await h.ready();
  const link=h.element('detail-content').innerHTML.match(/href="(DALYCARE_outputs.html[^"]+)">Open reviewed definition/)[1].replaceAll('&amp;','&');
  await h.navigate('',link.slice(link.indexOf('?')));const primary=h.element('detail-content').innerHTML.split('<summary>Inspect screened evidence')[0];
  assert.match(primary,new RegExp('SP_VitaleVaerdier\\.'+field));assert.match(primary,/Exact schema definition/);assert.doesNotMatch(primary,/Current descriptor membership|Supported current measurement names/);
 }
 const embedded=harness('?view=fields&source=FISH');await embedded.ready();assert.match(embedded.element('task-content').innerHTML,/FISH is an embedded resource/);
 const recovery=embedded.element('task-content').innerHTML.match(/href="([^"]+)">Search current exact fields across sources/)[1].replaceAll('&amp;','&');await embedded.navigate('',recovery.slice(recovery.indexOf('?')));assert.match(embedded.element('search-results').innerHTML,/RKKP_CLL.Reg_FISH/);
 const existing=embedded.element('search-results').innerHTML.match(/href="([^"]+)"/)[1].replaceAll('&amp;','&');await embedded.navigate('',existing.slice(existing.indexOf('?')));assert.match(embedded.element('detail-content').innerHTML,/RKKP_CLL.Reg_FISH/);
 const absent=harness('?view=fields&source=EMPTY_HELPER');await absent.ready();assert.match(absent.element('task-content').innerHTML,/EMPTY_HELPER is an embedded resource/);await absent.navigate('','?view=fields&g=EMPTY_HELPER');assert.match(absent.element('search-results').innerHTML,/No matching exact field names/);assert.match(absent.element('search-results').innerHTML,/does not establish/);
 const missing=harness('?view=timeplace&source=RKKP_CLL');await missing.ready();const primary=missing.element('detail-content').innerHTML.split('<summary>Inspect screened evidence')[0];
 assert.match(primary,/No date field identified/);assert.match(primary,/Source records/);assert.doesNotMatch(primary,/RKKP_CLL\\.|Selected by date-field name priority|Coverage shows records with verified person support/);
});
