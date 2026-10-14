const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
function guide(){const window={};vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../inst/templates/atlas-vitals.js'),'utf8'),{window,URLSearchParams});return window.DALYCARE_VITALS;}
test('clinical and Danish names locate the right vital sign without matching blood cultures',()=>{
 const g=guide();
 for(const [query,id] of [['blood pressure','blood-pressure'],['BP','blood-pressure'],['systolic','blood-pressure'],['BT diastolisk','blood-pressure'],['blodtryk','blood-pressure'],['SpO2 %','oxygen-saturation'],['SpO₂','oxygen-saturation'],['oxygen saturation','oxygen-saturation'],['iltmætning','oxygen-saturation'],['temperature','temperature'],['temperatur','temperature']])assert.deepEqual(Array.from(g.search(query),r=>r.id),[id],query);
 for(const q of ['blood culture','pressure ulcer','arterial blood gas','patientid','<script>'])assert.equal(g.search(q).length,0,q);
});
test('all historical descriptors and exact source fields are immediately visible',()=>{
 const html=guide().render('');
 for(const label of ['Puls','SpO2','Saturation','Resp','Resp.frekvens','BT (Diastolisk)','BT (Systolisk)','Temp.','Temperatur','Ilt (l/min.)','Vægt','Højde','EWS total','Bevidsthedsniveau','Lejring','I-EWS score (projekt)','Udgået - I-EWS modifikator','Udgået - Rover, EWS-handling'])assert.ok(html.includes(label),label);
 for(const field of ['displayname','numericvalue','recorded_time'])assert.ok(html.indexOf('SP_VitaleVaerdier.'+field)<html.indexOf('<details'),field+' stays visible');
 assert.ok(html.includes('Scores and retired reference labels'));assert.ok(html.indexOf('Scores and retired reference labels')<html.indexOf('id="vital-ews"'));
});
test('measurement aliases refine to the intended rows without prose matches',()=>{
 const g=guide();
 for(const [query,id] of [['pulse','pulse'],['heart rate','pulse'],['Puls','pulse'],['respiration','respiratory-rate'],['respiratory rate','respiratory-rate'],['Resp.frekvens','respiratory-rate'],['BT (Diastolisk)','blood-pressure'],['weight','weight'],['Vægt','weight'],['height','height'],['Højde','height'],['BMI','bmi'],['consciousness','consciousness'],['position','position'],['oxygen flow','oxygen-flow'],['I-EWS score (projekt)','i-ews-project']])assert.deepEqual(Array.from(g.search(query),r=>r.id),[id],query);
 for(const [query,id] of [['weight_in_kg','weight'],['SP_PatientInfo.weight_in_kg','weight'],['Reg_Vaegt','weight'],['RKKP_DaMyDa.Reg_Vaegt','weight'],['height_in_cm','height'],['SP_PatientInfo.height_in_cm','height'],['Reg_Hoejde','height'],['RKKP_DaMyDa.Reg_Hoejde','height'],['SP_PatientInfo.bmi','bmi'],['weight in kg','weight']])assert.deepEqual(Array.from(g.search(query),r=>r.id),[id],query);
 const html=g.render('heart rate');assert.match(html,/Puls/);assert.doesNotMatch(html,/Values in displayname[^]*SpO2/);
 assert.match(g.render('unfindable'),/No measurements match/);
 assert.match(g.render(''),/Find a measurement/);assert.match(g.render(''),/Find measurement/);assert.match(g.render('pulse'),/Show all measurements/);
});
const visible=html=>html.replace(/<[^>]*>/g,' ').replace(/\s+/g,' ');
const profile=(source,field,extra={})=>({table_name:source,column_name:field,column_type:'double precision',column_class:'numeric',profile_kind:'numeric',is_sensitive:'FALSE',is_numeric_like:'TRUE',n_rows:'100',n_available:'80',availability_privacy_status:null,numeric_privacy_status:'eligible_stored_summary',median:'72',p25:'63',p75:'85',summary_scope:'stored_source_row_profile',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample',...extra});
const render=profiles=>guide().render('',{profiles});
test('exact unique profiles alone supply storage metadata and availability',()=>{
 const html=render([profile('SP_VitaleVaerdier','numericvalue',{column_type:'text',column_class:'character',median:'991991'})]);
 assert.match(visible(html),/numericvalue.*Stored as: text/);assert.doesNotMatch(html,/991991/);
 assert.match(render([]),/Profile not supplied/i);
 const duplicate=render([profile('SP_PatientInfo','weight_in_kg',{median:771771}),profile('SP_PatientInfo','weight_in_kg',{median:882882})]);
 assert.match(duplicate,/Ambiguous profile/i);assert.doesNotMatch(duplicate,/771771|882882/);
 assert.doesNotMatch(render([profile('SP_PatientInfo_wrong','weight_in_kg',{median:661661})]),/661661/);
 for(const html of [render([]),duplicate])assert.doesNotMatch(html,/href="[^"]*field=weight_in_kg/);
});
test('dedicated measurements withhold legacy summaries while preserving source row context',()=>{
 for(const [source,field] of [['SP_PatientInfo','weight_in_kg'],['SP_PatientInfo','height_in_cm'],['SP_PatientInfo','bmi'],['RKKP_DaMyDa','Reg_Vaegt'],['RKKP_DaMyDa','Reg_Hoejde']]){
  const text=visible(render([profile(source,field)]));assert.doesNotMatch(text,/Median: 72/);assert.doesNotMatch(text,/Middle 50%: 63.*85/);assert.match(text,/80 of 100 source records/);assert.match(text,/quartiles.*sample/i);assert.match(text,/not unique people/i);
 }
 const text=visible(render([profile('SP_PatientInfo','weight_in_kg',{median:'0',p25:0,p75:'0',n_available:'0'})]));assert.doesNotMatch(text,/Median: 0/);assert.doesNotMatch(text,/Middle 50%: 0.*0/);assert.match(text,/0 of 100 source records/);
});
test('legacy exact means remain withheld even with an eligibility marker',()=>{
 assert.doesNotMatch(visible(render([profile('SP_PatientInfo','weight_in_kg',{mean:'0'})])),/Mean: 0/);
 assert.doesNotMatch(visible(render([profile('SP_PatientInfo','weight_in_kg',{mean:'71.5'})])),/Mean: 71\.5/);
 for(const mean of [null,'',true,{},'Infinity'])assert.doesNotMatch(visible(render([profile('SP_PatientInfo','weight_in_kg',{mean})])),/Mean:/);
 assert.doesNotMatch(render([profile('SP_PatientInfo','weight_in_kg',{mean:787878,numeric_privacy_status:'future_status'})]),/787878/);
});
test('null malformed reversed and noneligible numeric summaries fail closed',()=>{
 for(const status of [null,'','future_status','needs_validation_negative_sentinel','withheld_small_complementary_cells'])assert.doesNotMatch(render([profile('SP_PatientInfo','weight_in_kg',{numeric_privacy_status:status,median:'919919',p25:'929929',p75:'939939'})]),/919919|929929|939939/);
 for(const value of [null,'',true,{},'Infinity','NaN','not a number'])assert.doesNotMatch(visible(render([profile('SP_PatientInfo','bmi',{median:value,p25:value,p75:value})])),/Median: 0|Middle 50%: 0/);
 assert.doesNotMatch(visible(render([profile('SP_PatientInfo','bmi',{p25:98,p75:10})])),/Middle 50%: 98/);
 assert.match(render([profile('RKKP_DaMyDa','Reg_Vaegt',{numeric_privacy_status:'needs_validation_negative_sentinel',median:null,p25:null,p75:null})]),/80 of 100 source records/);
});
test('availability privacy and sensitive flags are enforced without truthy string coercion',()=>{
 for(const status of ['future_status','withheld_small_complementary_cells','eligible_stored_summary'])assert.doesNotMatch(render([profile('SP_PatientInfo','weight_in_kg',{availability_privacy_status:status,n_available:818181,n_rows:828282})]),/818181|828282/);
 for(const value of [null,'',true,{},'Infinity',-1,1.5])assert.doesNotMatch(visible(render([profile('SP_PatientInfo','weight_in_kg',{n_available:value})])),/of 100 source records/);
 for(const sensitive of [true,'TRUE','future_flag'])assert.doesNotMatch(render([profile('SP_PatientInfo','weight_in_kg',{is_sensitive:sensitive,median:717171,n_available:818181})]),/717171|818181/);
 assert.match(render([profile('SP_PatientInfo','weight_in_kg',{availability_privacy_status:'',is_sensitive:false})]),/80 of 100 source records/);
});
test('arbitrary private profile content and query markup are never rendered unsafely',()=>{
 const html=guide().render('<img src=x onerror=alert(1)>',{profiles:[profile('SP_PatientInfo','bmi',{column_type:'<script>bad()</script>',top_values:'PRIVATE_PAYLOAD',min:123456,max:234567,raw_values:'RAW_PRIVATE',numeric_privacy_reason:'UNREVIEWED_PRIVATE'})]});
 assert.doesNotMatch(html,/<img|<script|PRIVATE_PAYLOAD|RAW_PRIVATE|UNREVIEWED_PRIVATE|123456|234567/);assert.match(html,/&lt;img/);
 const storage=render([profile('SP_PatientInfo','bmi',{column_type:'<script>bad()</script>',top_values:'PRIVATE_PAYLOAD',min:123456,max:234567})]);assert.doesNotMatch(storage,/<script|PRIVATE_PAYLOAD|123456|234567/);assert.match(storage,/&lt;script&gt;/);
});
test('tiny nonzero summaries remain withheld without grouped evidence',()=>{
 assert.doesNotMatch(visible(render([profile('SP_PatientInfo','bmi',{median:'0.00003123',p25:'0.000001',p75:'0.00009'})])),/Median: (?:0\.00003123|3\.123e-5)/);
});
test('verified reference units are attached to their respective measurement rather than asserted as storage units',()=>{
 const g=guide();
 for(const [query,unit,reference] of [['pulse','beats/min','8867-4'],['respiration','breaths/min','9279-1'],['oxygen flow','L/min','3151-8']]){const html=g.render(query);assert.ok(html.includes('Reference unit: '+unit));assert.ok(html.includes('https://loinc.org/'+reference+'/'));assert.match(html,/stored units are unverified/i);}
});
test('category and common unit-qualified searches find intentional measurement groups',()=>{
 const g=guide();
 for(const query of ['anthropometrics','height weight BMI','BMI height weight'])assert.deepEqual(Array.from(g.search(query),r=>r.id),['weight','height','bmi'],query);
 const vitals=Array.from(g.search('vital signs'),r=>r.id);assert.ok(vitals.includes('pulse'));assert.ok(vitals.includes('blood-pressure'));assert.ok(vitals.includes('rover-retired'));
 for(const [query,id] of [['pulse bpm','pulse'],['heart rate bpm','pulse'],['blood pressure mmHg','blood-pressure'],['respiratory rate breaths/min','respiratory-rate'],['weight kg','weight'],['height cm','height']])assert.deepEqual(Array.from(g.search(query),r=>r.id),[id],query);
});
test('local find control precedes the visible source schema and units are qualified before the directory',()=>{
 const html=guide().render('');
 assert.match(html,/<h3>Measurement directory<\/h3>/);
 assert.ok(html.indexOf('Find a measurement')<html.indexOf('SP_VitaleVaerdier.displayname'));
 assert.ok(html.indexOf('stored units are unverified')<html.indexOf('id="vital-pulse"'));
 assert.match(visible(html),/per-measurement date or baseline window/);assert.match(visible(html),/not harmonized across sources/);
});
test('BMI-only and empty-result searches do not precede the answer with unrelated SP event schema',()=>{
 const g=guide(),html=g.render('BMI',{profiles:[profile('SP_PatientInfo','bmi')]});
 assert.match(html,/SP_PatientInfo\.bmi/);assert.doesNotMatch(html,/Median: 72/);assert.match(html,/Patient information \(SP\)/);
 assert.doesNotMatch(html,/SP_VitaleVaerdier|No measurement-specific counts|numericvalue pools/);
 assert.doesNotMatch(g.render('unfindable'),/SP_VitaleVaerdier|stored source records|baseline window/);
 const all=g.render('');for(const field of ['displayname','numericvalue','recorded_time'])assert.ok(all.includes('SP_VitaleVaerdier.'+field));
 assert.match(all,/Vital signs \(SP\) · SP_VitaleVaerdier/);assert.match(all,/Myeloma registry/);
});
test('local submission and reset refine the same directory while retaining supplied profiles',()=>{
 const changes=[],listeners={},window={},input={value:'weight',focus(){},setSelectionRange(){}},root={innerHTML:'',getAttribute(){return this.context;},querySelector(){return input;}};
 const document={addEventListener(type,handler){listeners[type]=handler;}};
 vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../inst/templates/atlas-vitals.js'),'utf8'),{window,document,URLSearchParams});
 root.innerHTML=window.DALYCARE_VITALS.render('',{profiles:[profile('SP_PatientInfo','weight_in_kg')],onQueryChange(query){changes.push(query);}});root.context=root.innerHTML.match(/data-vital-directory="(\d+)"/)[1];
 assert.deepEqual(changes,[]);
 const form={closest(){return root;},querySelector(){return input;}};
 listeners.submit({target:{closest(){return form;}},preventDefault(){}});
 assert.doesNotMatch(root.innerHTML,/Median: 72/);assert.match(root.innerHTML,/Vægt/);assert.doesNotMatch(root.innerHTML,/Resp.frekvens/);
 listeners.click({target:{closest(){return {closest(){return root;}};}},preventDefault(){}});
 assert.match(root.innerHTML,/Resp.frekvens/);assert.doesNotMatch(root.innerHTML,/Median: 72/);
 assert.deepEqual(changes,['weight','']);
});
test('separately published event summaries are acknowledged without reusing the pooled reading statistics',()=>{
 const html=guide().render('',{eventSummariesAvailable:true,profiles:[profile('SP_VitaleVaerdier','numericvalue',{median:818181})]});
 assert.match(html,/Separately published per-measurement SP summaries/);assert.doesNotMatch(html,/No measurement-specific counts|818181/);
});
test('source fields have exact summary routes and never pooled vital statistics',()=>{
 const g=guide(),profiles=[...['displayname','numericvalue','recorded_time','meas_value','meas_value_clean','val_type_c'].map(field=>profile('SP_VitaleVaerdier',field)),...['weight_in_kg','height_in_cm','bmi'].map(field=>profile('SP_PatientInfo',field)),...['Reg_Vaegt','Reg_Hoejde'].map(field=>profile('RKKP_DaMyDa',field))],html=g.render('SpO2 %',{profiles});
 assert.match(html,/SpO₂/);assert.match(html,/Reference unit: %/);assert.match(html,/stored units are unverified/i);
 assert.match(html,/No measurement-specific counts, medians or IQRs/);
 const urls=[...html.matchAll(/href="(DALYCARE_outputs[^"]+)"/g)].map(m=>new URL(m[1].replaceAll('&amp;','&'),'https://atlas.test/'));
 for(const field of ['displayname','numericvalue','recorded_time'])assert.ok(urls.some(u=>u.searchParams.get('source')==='SP_VitaleVaerdier'&&u.searchParams.get('field')===field),field);
 const all=g.render('',{profiles});
 for(const [source,fields] of [['SP_PatientInfo',['weight_in_kg','height_in_cm','bmi']],['RKKP_DaMyDa',['Reg_Vaegt','Reg_Hoejde']]])for(const field of fields){assert.ok(visible(all).includes(source+'.'+field));assert.ok([...all.matchAll(/href="(DALYCARE_outputs[^\"]+)"/g)].some(m=>{const u=new URL(m[1].replaceAll('&amp;','&'),'https://atlas.test/');return u.searchParams.get('source')===source&&u.searchParams.get('field')===field;}));}
 assert.match(visible(all),/one row.*observation/i);assert.match(visible(all),/share.*reading column/i);assert.match(visible(all),/stored BMI/i);
 assert.doesNotMatch(html,/64,124,202|61,392,978|120\/80|patientid/);
});
