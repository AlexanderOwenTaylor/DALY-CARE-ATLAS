const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
function decoder(){const file=path.join(__dirname,'../inst/templates/atlas-transport.js');assert.ok(fs.existsSync(file),'payload transport decoder exists');const window={};vm.runInNewContext(fs.readFileSync(file,'utf8'),{window});return window.DALYCARE_TRANSPORT.decode;}
test('legacy payload remains unchanged and aliases restore shared logical rows',()=>{
 const decode=decoder(),legacy={panels:{x:[{n:0}]}};assert.strictEqual(decode(legacy),legacy);
 const payload={catalog_rows:[{n:0}],review_infrastructure_sections:{}};const restored=decode({transport_version:1,payload,aliases:[{target:['review_infrastructure_sections','catalog'],source:['catalog_rows']}]});assert.strictEqual(restored.review_infrastructure_sections.catalog,restored.catalog_rows);
});
test('unsafe aliases, overwritten targets, missing sources and future versions fail closed',()=>{
 const decode=decoder();for(const aliases of [[{target:['__proto__','secret'],source:['rows']}],[{target:['rows'],source:['rows']}],[{target:['copy'],source:['absent']}],[{target:['copy'],source:['constructor']}]])assert.throws(()=>decode({transport_version:1,payload:{rows:[]},aliases}),/alias|path|target|source/i);
 assert.throws(()=>decode({transport_version:2,payload:{},aliases:[]}),/version/i);assert.equal({}.secret,undefined);
});
test('clinical initialization decodes before capturing payload',()=>{
 const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8');assert.ok(html.indexOf('atlas-transport.js')<html.indexOf('const payload = window.DALYCARE_ATLAS_PAYLOAD'));assert.match(html,/DALYCARE_TRANSPORT\.decode\(window.DALYCARE_ATLAS_PAYLOAD\)/);
});
test('reviewed aliases reject missing/overwritten targets and cyclic identity graphs',()=>{
 const decode=decoder(),alias={target:['review_infrastructure_sections','catalog'],source:['catalog_rows']};
 for(const payload of [{catalog_rows:[]},{catalog_rows:[],review_infrastructure_sections:{catalog:[]}},{review_infrastructure_sections:{}},{catalog_rows:[],review_infrastructure_sections:[]}])assert.throws(()=>decode({transport_version:1,payload,aliases:[alias]}),/alias|source|target/i);
 const parent={},payload={catalog_rows:[parent],review_infrastructure_sections:parent};assert.throws(()=>decode({transport_version:1,payload,aliases:[alias]}),/cyclic/i);assert.equal(parent.catalog,undefined);
 const cyclic=[];cyclic.push(cyclic);assert.throws(()=>decode({transport_version:1,payload:{catalog_rows:cyclic,review_infrastructure_sections:{}},aliases:[alias]}),/cyclic/i);
 const inherited=Object.create({review_infrastructure_sections:{}});inherited.catalog_rows=[];assert.throws(()=>decode({transport_version:1,payload:inherited,aliases:[alias]}),/target/i);
});
test('clinical missing or incompatible assets render a readable load error',()=>{
 const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8'),block=html.split('/* ATLAS_PAYLOAD_INIT_START */')[1]?.split('/* ATLAS_PAYLOAD_INIT_END */')[0];assert.ok(block,'clinical load error initializer exists');
 for(const payload of [undefined,{transport_version:1,payload:{},aliases:[]}]){const status={textContent:'',setAttribute(){}},document={getElementById:()=>status,documentElement:{dataset:{}}};vm.runInNewContext('(function(){'+block+'})()',{window:{DALYCARE_ATLAS_PAYLOAD:payload},document});assert.match(status.textContent,/could not load|Keep all atlas files/);assert.equal(document.documentElement.dataset.atlasReady,'clinical-error');}
});
