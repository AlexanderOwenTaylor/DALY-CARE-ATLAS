const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const v2=require('../inst/templates/registry-v2.js');
const work=path.resolve(__dirname,'../.artifact-temp/registry-v2');
if(!fs.existsSync(path.join(work,'resource.json'))){
 const cp=require('node:child_process'),env={...process.env};
 if(process.platform==='win32'){const local='C:/Users/User/AppData/Local/R/win-library/4.3';if(!env.R_LIBS_USER&&fs.existsSync(local))env.R_LIBS_USER=local;env.LC_ALL=env.LC_ALL||'English_United States.utf8';}
 const fallback='C:/Program Files/R/R-4.3.1/bin/Rscript.exe',rscript=env.RSCRIPT||(process.platform==='win32'&&fs.existsSync(fallback)?fallback:'Rscript');
 cp.execFileSync(rscript,['tests/test-registry-v2.R'],{cwd:path.resolve(__dirname,'..'),env,stdio:'inherit'});
}
const resource=JSON.parse(fs.readFileSync(path.join(work,'resource.json'),'utf8'));
const rows=JSON.parse(fs.readFileSync(path.join(work,'golden.json'),'utf8'));
for(const row of rows){
 assert(v2.validate(row,resource), 'R golden passes independent browser guard');
 for(const [key,value] of [['approximate_mean',123],['denominator_n',true],['n_valid',20.5],['numeric_policy_checksum','f'.repeat(64)],['unit_evidence_checksum','f'.repeat(64)],['unit_binding_checksum','f'.repeat(64)],['band_level',10],['extra','poison']])assert.equal(v2.validate({...row,[key]:value},resource),null,key);
 for(const raw of ['[{"band_id":"b0_1","n":20,"n":5}]','[{"band_id":"b0_1","n":5},{"band_id":"b0_1","n":15}]','[{"band_id":"b0_1","n":true}]'])assert.equal(v2.validate({...row,numeric_groups_json:raw},resource),null);
 assert.equal(v2.validate(row,resource,11),null);
}
console.log('PASS independent browser v2 golden, threshold, duplicate, schema and tamper checks');
const {test}=require('node:test'),vm=require('node:vm');
function reader(input){
 const scripts=[],table={id:'registry_field_summaries',title:'Registry',status:'available',columns:Object.keys(rows[0]).map(key=>({key,type:typeof rows[0][key]==='number'?'number':'string'})),shards:input.map((row,i)=>{const json=JSON.stringify([row]);return {id:'s'+i,src:`output-shards/registry_field_summaries-s${i}.js`,rows:1,bytes:Buffer.byteLength(json),json};})};
 const window={DALYCARE_REGISTRY_V2_RESOURCE:resource,DALYCARERegistryV2:v2,DALYCARE_OUTPUT_CATALOGUE:{schema_version:1,build_id:'synthetic',minimum_cell_count:5,tables:[table]},location:{hash:''},addEventListener(){}};
 const document={createElement:()=>({remove(){}}),head:{appendChild(s){scripts.push(s);}},getElementById:()=>null};
 vm.runInNewContext(fs.readFileSync(path.resolve(__dirname,'../inst/templates/atlas-reader.js'),'utf8'),{window,document,URLSearchParams,TextEncoder,setTimeout,clearTimeout,console});
 return {api:window.DALYCARE_OUTPUTS,answer(index){document.currentScript=scripts.at(-1);const shard=table.shards[index];window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'synthetic',table_id:table.id,shard_id:shard.id,rows_json:shard.json});document.currentScript=null;}};
}
test('exact-column output reader independently rejects altered v2 groups',async()=>{
 let h=reader([rows[0]]),pending=h.api.loadShard('registry_field_summaries','s0');h.answer(0);assert.equal((await pending)[0].summary_status,'published');
 h=reader([{...rows[0],approximate_mean:123}]);pending=h.api.loadShard('registry_field_summaries','s0');h.answer(0);await assert.rejects(pending,/contract/);
});
test('output reader checks the entire registry before displaying cross-shard duplicates',async()=>{
 const h=reader([rows[0],rows[0]]),pending=h.api.scanTable('registry_field_summaries','',0);
 h.answer(0);await Promise.resolve();await Promise.resolve();h.answer(1);await assert.rejects(pending,/Duplicate registry field/);
});
