const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'), vm=require('node:vm'), path=require('node:path');
const runtime=path.join(__dirname,'../inst/templates/atlas-outputs.js');
function harness(tableCount=1, shardCount=3, large=false) {
  const scripts=[],timers=new Map(); let clock=0;
  const tables=Array.from({length:tableCount},(_,i)=>({id:'t'+i,title:'Table '+i,status:'available',columns:[{key:'value',label:'Value',type:'string'}],shards:Array.from({length:shardCount},(_,j)=>{
    const rows=large?Array.from({length:200},()=>({value:'x'.repeat(1000)})):[{value:j===shardCount-1?'last æ':'first'},{value:'0'},{value:null}];
    const json=JSON.stringify(rows);return {id:'s'+j,src:`output-shards/t${i}-s${j}.js`,rows:rows.length,bytes:Buffer.byteLength(json),json};
  })}));
  const document={createElement:()=>({remove(){this.removed=true;}}),head:{appendChild(s){scripts.push(s);}},getElementById:()=>null};
  const window={DALYCARE_OUTPUT_CATALOGUE:{schema_version:1,build_id:'b1',tables},location:{hash:''},addEventListener(){}};
  const context=vm.createContext({window,document,URLSearchParams,TextEncoder,AbortController,setTimeout(fn){timers.set(++clock,fn);return clock;},clearTimeout(id){timers.delete(id);},console});
  assert.ok(fs.existsSync(runtime),'bounded table runtime exists');vm.runInContext(fs.readFileSync(runtime,'utf8'),context);
  function answer(script=scripts.at(-1), changes={}) {
    const match=script.src.match(/t(\d+)-s(\d+)\.js/), t=tables[+match[1]],s=t.shards[+match[2]];
    document.currentScript=script;
    window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'b1',table_id:t.id,shard_id:s.id,rows_json:s.json,...changes});
    document.currentScript=null;
  }
  return {api:window.DALYCARE_OUTPUTS,window,tables,scripts,timers,answer,timeout(){for(const fn of [...timers.values()])fn();}};
}
test('concurrent shard readers coalesce and preserve zero and missing values',async()=>{
  const h=harness(),a=h.api.loadShard('t0','s0'),b=h.api.loadShard('t0','s0');assert.equal(h.scripts.length,1);h.answer();
  assert.strictEqual(await a,await b);assert.equal(h.api.formatValue(0),'0');assert.equal(h.api.formatValue(null),'Missing');
});
test('registration validates every identity before exposing rows',async()=>{
  for(const changes of [{schema_version:2},{build_id:'other'},{table_id:'other'},{shard_id:'other'}]){
    const h=harness(),p=h.api.loadShard('t0','s0');h.answer(undefined,changes);await assert.rejects(p,/identity|version|build/i);
  }
});
test('invalid paths and catalogue versions never request scripts',async()=>{
  for(const src of ['../secret.js','https://other/x.js','output-shards/../x.js','output-shards/x.js?x=1','/output-shards/x.js']){
    const h=harness();h.tables[0].shards[0].src=src;await assert.rejects(h.api.loadShard('t0','s0'),/path/i);assert.equal(h.scripts.length,0);
  }
  const h=harness();h.window.DALYCARE_OUTPUT_CATALOGUE.schema_version=2;await assert.rejects(h.api.loadShard('t0','s0'),/version/i);
});
test('exact UTF-8 rows_json bytes accept decimal and exponent spellings',async()=>{
  const h=harness(),json='[{"value":1.000,"text":""},{"value":1e-7,"text":""},{"value":0,"text":"æ 雪"}]';h.tables[0].columns=[{key:'value',type:'number'},{key:'text',type:'string'}];h.tables[0].shards[0].bytes=Buffer.byteLength(json);
  const p=h.api.loadShard('t0','s0');h.answer(undefined,{rows_json:json});const rows=await p;assert.equal(rows[2].text,'æ 雪');assert.equal(rows[2].value,0);
});
test('row, byte and schema limits fail closed',async()=>{
  for(const json of ['[{"value":"wrong bytes"}]',JSON.stringify(Array.from({length:251},()=>({value:0}))),'[{"unreviewed":"secret"}]']){
    const h=harness();if(json.includes('unreviewed')||json.length>500){h.tables[0].shards[0].bytes=Buffer.byteLength(json);h.tables[0].shards[0].rows=Math.min(250,JSON.parse(json).length);}
    const p=h.api.loadShard('t0','s0');h.answer(undefined,{rows_json:json});await assert.rejects(p,/byte|row|schema|column/i);
  }
  const h=harness();h.tables[0].shards[0].bytes=262145;await assert.rejects(h.api.loadShard('t0','s0'),/limit|byte/i);assert.equal(h.scripts.length,0);
});
test('cache evicts oldest shards below one MiB and refetches them',async()=>{
  const h=harness(1,7,true);for(let i=0;i<7;i++){const p=h.api.loadShard('t0','s'+i);h.answer();await p;assert.ok(h.api.cacheBytes<=1048576);}
  const before=h.scripts.length,p=h.api.loadShard('t0','s0');assert.equal(h.scripts.length,before+1);h.answer();await p;
});
test('timeout permits retry and late old registrations cannot settle retry',async()=>{
  const h=harness(),first=h.api.loadShard('t0','s0'),old=h.scripts[0];h.timeout();await assert.rejects(first,/timeout/i);
  const retry=h.api.loadShard('t0','s0');h.answer(old,{rows_json:'bad'});h.answer();assert.equal((await retry).length,3);
});
test('selected-table change cancels old loads and ignores late responses',async()=>{
  const h=harness(2),a=h.api.loadShard('t0','s0'),old=h.scripts[0],b=h.api.loadShard('t1','s0');await assert.rejects(a,/cancel|incomplete/i);
  h.answer(old);h.answer();assert.equal((await b).length,3);assert.ok(h.api.cacheBytes<1000);
});
test('search scans last shard, counts all matches and retains only one page',async()=>{
  const h=harness(1,30);h.tables[0].shards.forEach(s=>{s.json=JSON.stringify(Array.from({length:100},()=>({value:'match'})));s.rows=100;s.bytes=Buffer.byteLength(s.json);});
  const progress=[],p=h.api.scanTable('t0','match',1,x=>progress.push(x));
  for(let i=0;i<30;i++){h.answer();await Promise.resolve();await Promise.resolve();}
  const r=await p;assert.equal(r.total_matches,3000);assert.equal(r.rows.length,50);assert.equal(r.scanned_rows,3000);assert.equal(r.complete,true);assert.equal(progress.length,30);
  const other=harness(),last=other.api.scanTable('t0','last',0);for(let i=0;i<3;i++){other.answer();await Promise.resolve();await Promise.resolve();}assert.equal((await last).total_matches,1);
});
test('failed and aborted searches report incomplete and never no matches',async()=>{
  const h=harness(),controller=new AbortController(),p=h.api.scanTable('t0','missing',0,null,controller.signal),old=h.scripts[0];controller.abort();await assert.rejects(p,/incomplete/i);h.answer(old);assert.equal(h.api.cacheBytes,0);
  const f=harness(),failed=f.api.scanTable('t0','missing',0);f.scripts[0].onerror();await assert.rejects(failed,/incomplete/i);
});
test('empty search reads only the page intersecting shards',async()=>{
  const h=harness(1,3,true),p=h.api.scanTable('t0','',5);assert.equal(h.scripts.length,1);assert.match(h.scripts[0].src,/s1/);h.answer();const r=await p;assert.equal(r.rows.length,50);assert.equal(r.total_matches,600);
});
test('reviewed profile tokens have plain labels only in their exact columns',()=>{
 const h=harness();assert.equal(h.api.formatValue('eligible_stored_summary','numeric_privacy_status'),'Stored summary available');assert.equal(h.api.formatValue('needs_validation_negative_sentinel','numeric_privacy_status'),'Not shown: invalid stored values need review');assert.equal(h.api.formatValue('stored_source_row_profile','summary_scope'),'Stored source rows');assert.equal(h.api.formatValue('supplied_mean_and_quantiles','summary_method'),'Supplied mean and quantiles');assert.equal(h.api.formatValue('eligible_stored_summary','unrelated'),'eligible_stored_summary');
});
test('changing catalogue build during a request rejects stale registration',async()=>{
 const h=harness(),p=h.api.loadShard('t0','s0');h.window.DALYCARE_OUTPUT_CATALOGUE.build_id='b2';h.answer();await assert.rejects(p,/build|identity/i);
});
test('numeric schemas reject string numbers and unknown column types',async()=>{
 const h=harness();h.tables[0].columns[0].type='number';const p=h.api.loadShard('t0','s0');h.answer();await assert.rejects(p,/numeric|schema/i);
 const f=harness();f.tables[0].columns[0].type='unreviewed_type';const bad=f.api.loadShard('t0','s0');if(f.scripts.length)f.answer();await assert.rejects(bad,/schema|type/i);assert.equal(f.scripts.length,0);
});
test('invalid non-page descriptors and duplicate shard identities prevent scans',async()=>{
 const h=harness();h.tables[0].shards[2].rows=-1;const p=h.api.scanTable('t0','',0);for(let i=0;i<2;i++){if(h.scripts.length)h.answer();await Promise.resolve();await Promise.resolve();}await assert.rejects(p,/row|descriptor/i);assert.equal(h.scripts.length,0);
 const f=harness();f.tables[0].shards[1].id='s0';const duplicate=f.api.loadShard('t0','s0');if(f.scripts.length)f.answer();await assert.rejects(duplicate,/identity|duplicate/i);assert.equal(f.scripts.length,0);
});
test('metadata-only, withheld and missing outputs cannot request rows',async()=>{
 for(const status of ['metadata_only','withheld','not_produced','empty_output','unavailable']){const h=harness();h.tables[0].status=status;await assert.rejects(h.api.loadShard('t0','s0'),/unavailable/i);assert.equal(h.scripts.length,0);}
});
test('string codes keep leading zeros and number schemas keep null separately from zero',async()=>{
 const h=harness(),json='[{"value":0,"code":"0012"},{"value":null,"code":"0000"}]';h.tables[0].columns=[{key:'value',type:'number'},{key:'code',type:'string'}];Object.assign(h.tables[0].shards[0],{rows:2,bytes:Buffer.byteLength(json),json});const p=h.api.loadShard('t0','s0');h.answer();const rows=await p;assert.equal(rows[0].value,0);assert.equal(rows[1].value,null);assert.equal(rows[0].code,'0012');
});
test('malformed and duplicate table metadata fail before requesting any rows',async()=>{
 for(const change of [h=>h.tables.push({...h.tables[0]}),h=>h.tables[0]=null,h=>h.tables[0].title=null]){const h=harness();change(h);const p=h.api.loadShard('t0','s0');if(h.scripts.length)h.answer();await assert.rejects(p,/catalogue|schema|identity/i);assert.equal(h.scripts.length,0);}
});
