const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const {parseCsv} = require('./fixtures/synthetic-ui-payload.cjs');

test('fixture dictionary parser retains quoted commas, newlines and escaped quotes', () => {
  assert.deepEqual(parseCsv('\uFEFFcode,definition,note\r\nX,"a,b","line1\nline2 with ""quotes"""\r\n'),
    [{code:'X',definition:'a,b',note:'line1\nline2 with "quotes"'}]);
  assert.throws(() => parseCsv('a,b\nX,"unfinished'), /Unterminated/);
  assert.throws(() => parseCsv('a,b\nX'), /row width/);
});

test('benchmark rejects future transport versions instead of scoring apparent top-level rows', () => {
  const directory=fs.mkdtempSync(path.join(__dirname,'synthetic-benchmark-'));
  try {
    const envelope={transport_version:2,payload:{column_profile_rows:[]},aliases:[],column_profile_rows:[]};
    for(const name of ['future.json','future.js']) {
      const file=path.join(directory,name),text=JSON.stringify(envelope);
      fs.writeFileSync(file,name.endsWith('.js')?'window.DALYCARE_ATLAS_PAYLOAD = '+text+';':text);
      const result=spawnSync(process.execPath,[path.join(__dirname,'benchmark-search.cjs'),file],{encoding:'utf8'});
      assert.notEqual(result.status,0);assert.match(result.stderr,/Unsupported payload transport version/);
    }
  } finally {fs.rmSync(directory,{recursive:true,force:true});}
});

test('benchmark requires an explicit payload and scores legacy and versioned JSON/offline JS equivalently', () => {
  const benchmark = path.join(__dirname, 'benchmark-search.cjs');
  const env = {...process.env}; delete env.DALYCARE_BENCHMARK_PAYLOAD;
  const absent = spawnSync(process.execPath, [benchmark], {encoding:'utf8',env});
  assert.equal(absent.status,2); assert.match(absent.stderr,/Usage:.*PAYLOAD/);
  const directory = fs.mkdtempSync(path.join(__dirname,'synthetic-benchmark-'));
  try {
    const payload = {fixture_notice:'SYNTHETIC TEST DATA',column_profile_rows:[
      {table_name:'SYNTHETIC_SOURCE',column_name:'creatinine',domain:'Synthetic'},
      {table_name:'SYNTHETIC_SOURCE',column_name:'smoking',domain:'Synthetic'}]};
    const json = path.join(directory,'payload.json');
    const js = path.join(directory,'payload.js');
    fs.writeFileSync(json,JSON.stringify(payload));
    fs.writeFileSync(js,'window.DALYCARE_ATLAS_PAYLOAD = '+JSON.stringify(payload)+';');
    const result = spawnSync(process.execPath,[benchmark,json],{encoding:'utf8',env});
    assert.equal(result.status,0,result.stderr);
    const data = JSON.parse(result.stdout);
    assert.equal(data.rows,2); assert.equal(data.queries,5); assert.ok(data.milliseconds>=0);
    const fromEnv = spawnSync(process.execPath,[benchmark],{encoding:'utf8',env:{...env,DALYCARE_BENCHMARK_PAYLOAD:js}});
    assert.equal(fromEnv.status,0,fromEnv.stderr);
    assert.equal(JSON.parse(fromEnv.stdout).scoreChecksum,data.scoreChecksum);
    const envelope = {transport_version:1,payload:{...payload,review_infrastructure_sections:{}},aliases:[
      {target:['review_infrastructure_sections','columns'],source:['column_profile_rows']} ]};
    for (const [file,text] of [[json,JSON.stringify(envelope)],[js,'window.DALYCARE_ATLAS_PAYLOAD = '+JSON.stringify(envelope)+';']]) {
      fs.writeFileSync(file,text);
      const versioned = spawnSync(process.execPath,[benchmark,file],{encoding:'utf8',env});
      assert.equal(versioned.status,0,versioned.stderr);
      const scored = JSON.parse(versioned.stdout);
      assert.equal(scored.rows,2); assert.equal(scored.queries,5);
      assert.equal(scored.scoreChecksum,data.scoreChecksum);
    }
    for (const file of [json,js]) {
      const unsupported = {...envelope,transport_version:2};
      fs.writeFileSync(file,file===json?JSON.stringify(unsupported):'window.DALYCARE_ATLAS_PAYLOAD = '+JSON.stringify(unsupported)+';');
      const rejected = spawnSync(process.execPath,[benchmark,file],{encoding:'utf8',env});
      assert.notEqual(rejected.status,0); assert.match(rejected.stderr,/Unsupported payload transport version/);
    }
    fs.writeFileSync(json,'{"wrong_schema":[]}');
    const bad = spawnSync(process.execPath,[benchmark,json],{encoding:'utf8',env});
    assert.notEqual(bad.status,0); assert.match(bad.stderr,/column_profile_rows/);
  } finally { fs.rmSync(directory,{recursive:true,force:true}); }
});
