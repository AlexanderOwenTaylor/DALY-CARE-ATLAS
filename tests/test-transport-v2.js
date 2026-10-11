const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');

const source=fs.readFileSync(path.join(__dirname,'../inst/templates/atlas-transport.js'),'utf8');
const fixtureText=fs.readFileSync(path.join(__dirname,'fixtures/transport-v2-contract.json'),'utf8');
function realm() {
  const context=vm.createContext({window:{}});
  // Only the test copy exposes private accounting/bounded decoding helpers.
  vm.runInContext(source.replace('window.DALYCARE_TRANSPORT={decode};',
    'window.DALYCARE_TRANSPORT={decode}; window.codecTest={bounded:typeof decodeV2 === "function" ? decodeV2 : null, charge:typeof normalizedCharge === "function" ? normalizedCharge : null};'),context);
  function parse(text) { context.inputText=text; return vm.runInContext('JSON.parse(inputText)',context); }
  return {context,parse,decode:context.window.DALYCARE_TRANSPORT.decode,
    bounded:context.window.codecTest.bounded,charge:context.window.codecTest.charge,
    fixtures:parse(fixtureText),run:code=>vm.runInContext(code,context)};
}
const plain=value=>JSON.parse(JSON.stringify(value));
const at=(value,parts)=>parts.reduce((node,key)=>node[key],value);
function base(r) { return r.parse('{"transport_version":2,"payload":{"rows":null,"untouched":{"note":"SYNTHETIC"}},"aliases":[],"row_tables":[{"path":["rows"],"schemas":[["x"]],"rows":[[0,1],[0,2]]}]}'); }

test('v2 frozen valid fixtures restore types, key order, absence and aliases',()=>{
  const r=realm();
  for(const fixture of r.fixtures.valid_decodes) {
    const wire=r.parse(JSON.stringify(fixture.wire)), before=JSON.stringify(wire);
    const decoded=r.decode(wire);
    assert.deepEqual(plain(decoded),plain(fixture.logical),fixture.id);
    assert.equal(JSON.stringify(wire),before,fixture.id+' preserves input');
    for(const [left,right] of fixture.identity_paths||[]) assert.strictEqual(at(decoded,left),at(decoded,right),fixture.id);
  }
  const decoded=r.decode(r.fixtures.valid_decodes[0].wire);
  assert.deepEqual(Array.from(Object.keys(decoded.rows[0])),['label','count']);
  assert.deepEqual(Array.from(Object.keys(decoded.rows[1])),['label']);
  assert.equal(Object.hasOwn(decoded.rows[1],'count'),false);
});

test('v2 frozen invalid fixtures fail without changing any placeholder or alias target',()=>{
  const r=realm();
  for(const fixture of r.fixtures.invalid_decodes) {
    const wire=r.parse(JSON.stringify(fixture.wire)),before=JSON.stringify(wire),payload=wire.payload;
    assert.throws(()=>r.decode(wire),undefined,fixture.id);
    assert.equal(JSON.stringify(wire),before,fixture.id+' preserves input');
    assert.strictEqual(wire.payload,payload,fixture.id+' keeps payload identity');
  }
});

test('v2 normalized charges and frozen exact boundaries count every envelope field',()=>{
  const r=realm();
  assert.equal(typeof r.charge,'function');assert.equal(typeof r.bounded,'function');
  for(const entry of r.fixtures.normalized_charges) assert.equal(r.charge(entry.value,10000),entry.charge,JSON.stringify(entry.value));
  for(const fixture of r.fixtures.valid_decodes) {
    assert.equal(r.charge(fixture.wire,10000),fixture.encoded_charge,fixture.id);
    assert.doesNotThrow(()=>r.bounded(fixture.wire,fixture.minimum_decode_budget),fixture.id);
    assert.throws(()=>r.bounded(fixture.wire,fixture.minimum_decode_budget-1),/limit|budget|bytes/i,fixture.id);
  }
});

test('v2 expanded repeated keys have an independent pre-alias budget',()=>{
  const r=realm(),wire=base(r);
  wire.row_tables[0].schemas[0][0]='SYNTHETIC_REPEATED_KEY'.repeat(4);
  wire.row_tables[0].rows=r.parse('[[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0]]');
  // Payload costs 46. Replace null (4) with ten 125-unit rows and 11 array units.
  assert.equal(r.charge(wire,10000),951);
  assert.doesNotThrow(()=>r.bounded(wire,1303));
  assert.throws(()=>r.bounded(wire,1302),/limit|budget|bytes/i);
  // More rows make expanded size exceed encoded size; charge each repeated key.
  wire.row_tables[0].rows=r.parse(JSON.stringify(Array.from({length:30},()=>[0,0])));
  const before=JSON.stringify(wire);
  assert.equal(r.charge(wire,10000),2311);
  assert.doesNotThrow(()=>r.bounded(wire,3823));
  assert.throws(()=>r.bounded(wire,3822),/limit|budget|bytes/i);
  assert.equal(JSON.stringify(wire),before);
});

test('v2 expanded accounting excludes restored alias copies',()=>{
  const r=realm(),wire=r.fixtures.valid_decodes.find(entry=>entry.id==='restored_alias_identity').wire;
  wire.row_tables[0].schemas=r.parse(JSON.stringify([['SYNTHETIC_REPEATED_KEY'.repeat(4)]]));
  wire.row_tables[0].rows=r.parse(JSON.stringify(Array.from({length:30},()=>[0,0])));
  // The original payload costs 70; the source rows cost 3781 after unpacking.
  const decoded=r.bounded(wire,3847);
  assert.throws(()=>r.bounded(wire,3846),/limit|budget|bytes/i);
  assert.equal(r.charge(decoded,10000),7639);
  assert.strictEqual(decoded.catalog_rows,decoded.review_infrastructure_sections.catalog);
});

test('v2 copies affected record branches and keeps untouched own unsafe names and subtrees',()=>{
  const r=realm();
  const wire=r.parse('{"transport_version":2,"payload":{"branch":{"rows":null,"keep":{"constructor":"own","prototype":"own","__proto__":"own"}},"other":{"note":"share"},"__proto__":"root-own"},"aliases":[],"row_tables":[{"path":["branch","rows"],"schemas":[["x"]],"rows":[[0,null],[0,false]]}]}');
  const original=wire.payload,decoded=r.decode(wire);
  assert.notStrictEqual(decoded,original);assert.notStrictEqual(decoded.branch,original.branch);
  assert.strictEqual(decoded.branch.keep,original.branch.keep);assert.strictEqual(decoded.other,original.other);
  assert.equal(Object.hasOwn(decoded,'__proto__'),true);assert.equal(decoded.__proto__,'root-own');
  assert.equal(decoded.branch.keep.__proto__,'own');assert.strictEqual(r.run('Object.prototype'),Object.getPrototypeOf(decoded));
  assert.equal(original.branch.rows,null);
});

test('v2 validates late table metadata, cells, aliases and budgets before restored row allocation',()=>{
  const r=realm(),first=base(r);
  first.payload.later=null;
  first.row_tables.push(r.parse('{"path":["later"],"schemas":[["y"]],"rows":[[0,3],[0,4]]}'));
  for(const mutation of [
    wire=>{wire.row_tables[1].extra=true;},
    wire=>{wire.row_tables[1].rows[1][1]=r.parse('{"nested":true}');},
    wire=>{wire.aliases=r.parse('[{"target":["review_infrastructure_sections","unknown"],"source":["rows"]}]');}
  ]) {
    const wire=r.parse(JSON.stringify(first));mutation(wire);const before=JSON.stringify(wire);
    // Restored records are created via Object.create; any allocation before rejection fails this test.
    r.context.wire=wire;
    assert.throws(()=>r.run('(function(){const original=Object.create;Object.create=function(){throw new Error("EARLY ROW ALLOCATION")};try{return window.DALYCARE_TRANSPORT.decode(wire)}finally{Object.create=original}})()'),error=>!/EARLY ROW ALLOCATION/.test(error.message));
    assert.equal(JSON.stringify(wire),before);
  }
  const before=JSON.stringify(first);
  assert.throws(()=>r.bounded(first,200),/limit|budget|bytes/i);
  assert.equal(JSON.stringify(first),before);
});

test('v2 rejects cycles, sparse arrays, undefined, symbols, accessors and non-record values',()=>{
  const r=realm();
  for(const setup of [
    'wire.payload.loop=wire.payload', 'wire.payload.bad=[,1]', 'wire.payload.bad=undefined',
    'wire.payload.bad=function(){}', 'wire.payload.bad=1n', 'wire.payload.bad=Symbol("x")',
    'wire.payload.bad=new Date()', 'wire.payload.bad=new Map()', 'wire.payload.bad=Object.create({inherited:1})',
    'wire.payload[Symbol("x")]=1', 'wire.payload.bad=[1];wire.payload.bad.extra=2',
    'Object.defineProperty(wire.payload,"bad",{value:1,enumerable:false})',
    'Object.defineProperty(wire.payload,"bad",{enumerable:true,get(){throw new Error("GETTER INVOKED")}})',
    'Object.defineProperty(wire.row_tables[0].rows[0],"1",{enumerable:true,get(){throw new Error("GETTER INVOKED")}})'
  ]) {
    r.context.wire=base(r);r.run(setup);
    assert.throws(()=>r.decode(r.context.wire),error=>!/GETTER INVOKED/.test(error.message),setup);
    assert.equal(r.context.wire.payload.rows,null);
  }
});

test('v2 accepts acyclic shared records and charges each serialized occurrence',()=>{
  const r=realm();
  const graph=r.run('(()=>{const shared={x:0};return {a:shared,b:shared}})()');
  assert.equal(r.charge(graph,100),87);assert.throws(()=>r.charge(graph,86),/limit|budget|bytes/i);
  const wire=base(r);wire.payload.a=graph.a;wire.payload.b=graph.b;
  const decoded=r.decode(wire);assert.strictEqual(decoded.a,decoded.b);assert.strictEqual(decoded.a,graph.a);
});

test('v2 accepts null-prototype records and never invokes inherited alias-parent accessors',()=>{
  const r=realm();
  const wire=r.run('(()=>{const payload=Object.create(null);payload.rows=null;payload.keep=Object.create(null);payload.keep.note="SYNTHETIC";return {transport_version:2,payload,aliases:[],row_tables:[{path:["rows"],schemas:[["x"]],rows:[[0,1],[0,2]]}]}})()');
  const decoded=r.decode(wire);
  assert.equal(Object.getPrototypeOf(decoded),null);assert.strictEqual(decoded.keep,wire.payload.keep);
  assert.deepEqual(plain(decoded.rows),[{x:1},{x:2}]);
  const inherited=r.parse('{"transport_version":2,"payload":{"catalog_rows":[]},"aliases":[{"target":["review_infrastructure_sections","catalog"],"source":["catalog_rows"]}],"row_tables":[]}');
  r.context.wire=inherited;
  assert.throws(()=>r.run('(function(){Object.defineProperty(Object.prototype,"review_infrastructure_sections",{configurable:true,get(){throw new Error("INHERITED GETTER INVOKED")}});try{return window.DALYCARE_TRANSPORT.decode(wire)}finally{delete Object.prototype.review_infrastructure_sections}})()'),error=>!/INHERITED GETTER INVOKED/.test(error.message));
});

test('v2 rejects exotic array prototypes before inherited iterator mutation at every input position',()=>{
  const positions=[['row_tables'],['row_tables',0,'path'],['row_tables',0,'schemas'],['row_tables',0,'schemas',0],
    ['row_tables',0,'rows'],['row_tables',0,'rows',0],['aliases'],['aliases',0,'target'],['aliases',0,'source'],['payload','verbatim']];
  for(const position of positions) {
    const r=realm(),wire=r.fixtures.valid_decodes.find(entry=>entry.id==='restored_alias_identity').wire;
    wire.payload.verbatim=r.parse('[null,0]');
    r.context.wire=wire;r.context.candidate=at(wire,position);
    const before=JSON.stringify(wire);
    const outcome=r.run('(()=>{let called=0;const proto=Object.create(Array.prototype);Object.defineProperty(proto,Symbol.iterator,{get(){called++;wire.payload.bad=Infinity;return Array.prototype[Symbol.iterator]}});Object.setPrototypeOf(candidate,proto);let accepted=false;try{window.DALYCARE_TRANSPORT.decode(wire);accepted=true}catch{}return {accepted,called}})()');
    assert.equal(outcome.called,0,JSON.stringify(position)+' must not call an inherited iterator');
    assert.equal(outcome.accepted,false,JSON.stringify(position)+' must reject an exotic array prototype');
    assert.equal(JSON.stringify(wire),before,JSON.stringify(position)+' must preserve input');
    assert.equal(wire.payload.catalog_rows,null);
  }
});

test('v2 rejects inherited every allowlist bypass before the method runs',()=>{
  const r=realm(),wire=r.parse('{"transport_version":2,"payload":{"rogueRows":[],"review_infrastructure_sections":{}},"aliases":[{"target":["review_infrastructure_sections","not_reviewed"],"source":["rogueRows"]}],"row_tables":[]}');
  r.context.wire=wire;const before=JSON.stringify(wire);
  const outcome=r.run('(()=>{let called=0;const proto=Object.create(Array.prototype);proto.every=function(){called++;return true};Object.setPrototypeOf(wire.aliases[0].target,proto);Object.setPrototypeOf(wire.aliases[0].source,proto);let accepted=false;try{window.DALYCARE_TRANSPORT.decode(wire);accepted=true}catch{}return {accepted,called}})()');
  assert.equal(outcome.called,0,'inherited every must not decide reviewed alias identity');
  assert.equal(outcome.accepted,false,'unreviewed alias must reject');
  assert.equal(JSON.stringify(wire),before);assert.equal(Object.hasOwn(wire.payload.review_infrastructure_sections,'not_reviewed'),false);
});

test('v2 dense null-prototype arrays work throughout metadata, rows, aliases and untouched data',()=>{
  const r=realm();
  for(const fixture of r.fixtures.valid_decodes) {
    const wire=r.parse(JSON.stringify(fixture.wire));r.context.wire=wire;
    r.run('(function nullArrays(value){if(value&&typeof value==="object"){const keys=Object.keys(value);for(let index=0;index<keys.length;index++)nullArrays(value[keys[index]]);if(Array.isArray(value))Object.setPrototypeOf(value,null)}})(wire)');
    const before=JSON.stringify(wire),decoded=r.decode(wire);
    assert.deepEqual(plain(decoded),plain(fixture.logical),fixture.id);
    assert.equal(JSON.stringify(wire),before,fixture.id+' preserves null-prototype inputs');
    for(const [left,right] of fixture.identity_paths||[])assert.strictEqual(at(decoded,left),at(decoded,right),fixture.id);
  }
  const cyclic=r.run('(()=>{const parent={},source=[parent],target=["review_infrastructure_sections","catalog"],sourcePath=["catalog_rows"],aliases=[{target,source:sourcePath}],tables=[];for(const value of [source,target,sourcePath,aliases,tables])Object.setPrototypeOf(value,null);return {transport_version:2,payload:{catalog_rows:source,review_infrastructure_sections:parent},aliases,row_tables:tables}})()');
  assert.throws(()=>r.decode(cyclic),/cyclic|cycle/i);assert.equal(Object.hasOwn(cyclic.payload.review_infrastructure_sections,'catalog'),false);
});

test('v2 never dispatches inherited Array.prototype methods or iterators during decoding',()=>{
  const r=realm(),wire=r.fixtures.valid_decodes.find(entry=>entry.id==='restored_alias_identity').wire;
  r.context.wire=wire;
  const decoded=r.run('(()=>{const names=[Symbol.iterator,"every","some","push"],saved=[];for(let index=0;index<names.length;index++)saved[index]=Object.getOwnPropertyDescriptor(Array.prototype,names[index]);try{for(let index=0;index<names.length;index++)Object.defineProperty(Array.prototype,names[index],{configurable:true,get(){throw new Error("INHERITED ARRAY DISPATCH")}});return window.DALYCARE_TRANSPORT.decode(wire)}finally{for(let index=0;index<names.length;index++)Object.defineProperty(Array.prototype,names[index],saved[index])}})()');
  assert.deepEqual(plain(decoded),plain(r.fixtures.valid_decodes.find(entry=>entry.id==='restored_alias_identity').logical));
  assert.strictEqual(decoded.catalog_rows,decoded.review_infrastructure_sections.catalog);
});

test('v2 depth rejects values beyond edge128 and accepts the exact edge128 boundary',()=>{
  const r=realm();
  const graph=r.run('(()=>{let value=null;for(let i=0;i<128;i++)value={x:value};return value})()');
  assert.doesNotThrow(()=>r.charge(graph,10000));
  const deeper=r.run('(()=>{let value=null;for(let i=0;i<129;i++)value={x:value};return value})()');
  assert.throws(()=>r.charge(deeper,10000),/depth/i);
});

test('v2 scalar Unicode and finite numbers match the existing parsed-v1 numeric baseline',()=>{
  const r=realm();
  const wire=r.parse('{"transport_version":2.0,"payload":{"rows":null},"aliases":[],"row_tables":[{"path":["rows"],"schemas":[["x"]],"rows":[[0.0,9007199254740993],[0,1.7976931348623157e308]]}]}');
  const baseline=r.parse('{"rows":[{"x":9007199254740993},{"x":1.7976931348623157e308}]}');
  assert.deepEqual(plain(r.decode(wire)),plain(baseline));
  for(const bad of [NaN,Infinity,-Infinity]) {const input=base(r);input.row_tables[0].rows[0][1]=bad;assert.throws(()=>r.decode(input),/number|finite|graph/i);}
  const overflow=r.parse('{"transport_version":2,"payload":{"rows":null},"aliases":[],"row_tables":[{"path":["rows"],"schemas":[["x"]],"rows":[[0,1e309],[0,2]]}]}');
  assert.throws(()=>r.decode(overflow),/number|finite|graph/i);
  for(const bad of ['\ud800','\udc00','x\ud800y']) {const input=base(r);input.payload.bad=bad;assert.throws(()=>r.decode(input),/unicode|surrogate/i);}
  const key=base(r);key.payload['\ud800']=true;assert.throws(()=>r.decode(key),/unicode|surrogate/i);
});

test('v2 metadata work limits reject whole tables and include unused schemas',()=>{
  const r=realm();
  for(const [name,limit] of [['tables',0],['rows',1],['cells',1],['schemas_per_table',0],['keys_per_schema',0],['path_depth',0],['key_utf8_bytes',0]]) {
    const wire=base(r),before=JSON.stringify(wire);
    assert.throws(()=>r.bounded(wire,10000,{...plain(r.fixtures.work_limits),[name]:limit}),/limit|budget|depth/i,name);
    assert.equal(JSON.stringify(wire),before,name);
  }
  const unused=r.fixtures.valid_decodes.find(entry=>entry.id==='unused_schema_is_bounded_metadata').wire;
  assert.throws(()=>r.bounded(unused,10000,{...plain(r.fixtures.work_limits),schemas_per_table:1}),/limit|schema/i);
  const long=base(r);long.row_tables[0].schemas[0][0]='😀'.repeat(33);
  assert.throws(()=>r.decode(long),/limit|bytes|key/i);
});

test('v2 alias restoration copies its parent, preserves source identity and rejects cyclic writes',()=>{
  const r=realm(),wire=r.fixtures.valid_decodes.find(entry=>entry.id==='restored_alias_identity').wire;
  const parent=wire.payload.review_infrastructure_sections,decoded=r.decode(wire);
  assert.notStrictEqual(decoded.review_infrastructure_sections,parent);
  assert.equal(Object.hasOwn(parent,'catalog'),false);
  assert.strictEqual(decoded.catalog_rows,decoded.review_infrastructure_sections.catalog);
  const cyclic=r.run('(()=>{const parent={};return {transport_version:2,payload:{catalog_rows:[parent],review_infrastructure_sections:parent},aliases:[{target:["review_infrastructure_sections","catalog"],source:["catalog_rows"]}],row_tables:[]}})()');
  assert.throws(()=>r.decode(cyclic),/cyclic|cycle/i);assert.equal(Object.hasOwn(cyclic.payload.review_infrastructure_sections,'catalog'),false);
});

test('public decoder retains the fixed defense limit and unchanged legacy/v1 read behavior',()=>{
  const r=realm(),legacy=r.parse('{"rows":[{"x":1}]}');assert.strictEqual(r.decode(legacy),legacy);
  const v1=r.parse('{"transport_version":1,"payload":{"catalog_rows":[],"review_infrastructure_sections":{}},"aliases":[{"target":["review_infrastructure_sections","catalog"],"source":["catalog_rows"]}]}');
  assert.strictEqual(r.decode(v1),v1.payload);assert.strictEqual(v1.payload.catalog_rows,v1.payload.review_infrastructure_sections.catalog);
  // A second argument is deliberately ignored by the public decode(value) API.
  assert.doesNotThrow(()=>r.decode(base(r),1));
  assert.deepEqual(Object.keys(r.context.window.DALYCARE_TRANSPORT),['decode']);
  // Shared arrays keep the fixture itself small while its serialized occurrences
  // exceed 64MiB under the normalized 32-unit numeric charge.
  const over=r.run('(()=>{const row=Array(64).fill(0);return {transport_version:2,payload:{verbatim:Array(32768).fill(row)},aliases:[],row_tables:[]}})()');
  assert.throws(()=>r.decode(over),/limit|budget|bytes/i);
  assert.strictEqual(r.decode(over.payload),over.payload);
  const old=r.parse('{"transport_version":1,"payload":{},"aliases":[]}');
  old.payload=over.payload;
  assert.strictEqual(r.decode(old),old.payload);
});
