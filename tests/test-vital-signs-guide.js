const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
function guide(){const window={};vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../inst/templates/atlas-vitals.js'),'utf8'),{window,URLSearchParams});return window.DALYCARE_VITALS;}
test('clinical and Danish names locate the right vital sign without matching blood cultures',()=>{
 const g=guide();
 for(const [query,id] of [['blood pressure','blood-pressure'],['BP','blood-pressure'],['systolic','blood-pressure'],['BT diastolisk','blood-pressure'],['blodtryk','blood-pressure'],['SpO2 %','oxygen-saturation'],['SpO₂','oxygen-saturation'],['oxygen saturation','oxygen-saturation'],['iltmætning','oxygen-saturation'],['temperature','temperature'],['temperatur','temperature']])assert.deepEqual(Array.from(g.search(query),r=>r.id),[id],query);
 for(const q of ['blood culture','pressure ulcer','arterial blood gas','patientid','<script>'])assert.equal(g.search(q).length,0,q);
});
test('guide routes to the exact descriptor, numeric value and time fields; reference units never become dataset statistics',()=>{
 const g=guide(),html=g.render('SpO2 %');
 assert.match(html,/SpO₂/);assert.match(html,/Usual unit: %/);assert.match(html,/usual units.*not verified stored units/i);
 assert.match(html,/No measurement-specific counts, medians or IQRs/);
 assert.match(html,/<details[^>]*id="vital-oxygen-saturation"[^>]* open/);
 assert.doesNotMatch(html,/<details[^>]*id="vital-blood-pressure"[^>]* open/);
 const urls=[...html.matchAll(/href="(DALYCARE_outputs[^"]+)"/g)].map(m=>new URL(m[1].replaceAll('&amp;','&'),'https://atlas.test/'));
 for(const field of ['displayname','numericvalue','recorded_time'])assert.ok(urls.some(u=>u.searchParams.get('source')==='SP_VitaleVaerdier'&&u.searchParams.get('field')===field),field);
 assert.doesNotMatch(g.render('<img src=x onerror=alert(1)>'),/<img|onerror/);
 assert.doesNotMatch(html,/64,124,202|61,392,978|120\/80|patientid/);
});
