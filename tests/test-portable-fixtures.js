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

test('benchmark requires an explicit payload and runs both JSON and offline JS', () => {
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
    fs.writeFileSync(json,'{"wrong_schema":[]}');
    const bad = spawnSync(process.execPath,[benchmark,json],{encoding:'utf8',env});
    assert.notEqual(bad.status,0); assert.match(bad.stderr,/column_profile_rows/);
  } finally { fs.rmSync(directory,{recursive:true,force:true}); }
});
