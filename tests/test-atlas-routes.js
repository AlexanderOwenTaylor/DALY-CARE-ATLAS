const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const html = fs.readFileSync(path.join(__dirname, '../inst/templates/DALYCARE_atlas.html'), 'utf8');
const block = html.split('/* ATLAS_ROUTE_START */')[1]?.split('/* ATLAS_ROUTE_END */')[0] || '';
const context = vm.createContext({ URLSearchParams });
vm.runInContext(block, context);
const run = code => vm.runInContext(code, context);

test('laboratory links retain local filters independently of global search', () => {
  const route = JSON.parse(run(`JSON.stringify(readAtlasRoute(atlasRouteHash('laboratory', 'lab-npu', {q:'creatinine', specimen:'Urine', source:'SP_AlleProvesvar', translation:'resolved', sort:'name', g:'admissions'})))`));
  assert.deepEqual(route, {tabId:'laboratory', subId:'lab-npu', q:'creatinine', specimen:'Urine', source:'SP_AlleProvesvar', translation:'resolved', sort:'name', g:'admissions', item:'', category:'', page:'', scope:'', measurement:''});
});
test('clearing global search does not revive it or erase local laboratory filters', () => {
  assert.equal(run(`readAtlasRoute(atlasRouteHash('laboratory','lab-npu',{q:'creatinine',specimen:'Urine',g:''})).g`), '');
  assert.equal(run(`readAtlasRoute(atlasRouteHash('laboratory','lab-npu',{q:'creatinine',specimen:'Urine',g:''})).q`), 'creatinine');
});
test('queries with encoded punctuation round-trip and legacy laboratory links still work', () => {
  assert.equal(run(`readAtlasRoute(atlasRouteHash('variables','variables-concepts',{q:'A&B? 50% + æ'})).q`), 'A&B? 50% + æ');
  assert.equal(run(`readAtlasRoute('#laboratory/lab-npu?q=NPU04998').q`), 'NPU04998');
  assert.equal(run(`readAtlasRoute('#overview/overview-summary?q=creatinine').g`), 'creatinine');
  assert.equal(run(`readAtlasRoute('#overview/%broken').subId`), '');
});

test('dictionary links retain category and page, and field links retain the source', () => {
  const filtered=JSON.parse(run(`JSON.stringify(readAtlasRoute(atlasRouteHash('dictionary','dictionary-codes',{category:'fields',scope:'linked',source:'RKKP_LYFO',q:'planned treatment',g:''})))`));
  assert.equal(filtered.scope,'linked');
  assert.equal(filtered.source,'RKKP_LYFO');
  assert.equal(filtered.q,'planned treatment');
  assert.equal(filtered.g,'');
  assert.equal(run(`readAtlasRoute(atlasRouteHash('dictionary','dictionary-codes',{category:'pathology',page:'3',g:''})).page`),'3');
  assert.equal(run(`readAtlasRoute(atlasRouteHash('dictionary','dictionary-codes',{category:'pathology',page:'3',g:''})).category`),'pathology');
  assert.equal(run(`readAtlasRoute(atlasRouteHash('infrastructure','infra-columns',{q:'ryger',source:'SP_SocialHX',g:''})).source`),'SP_SocialHX');
});
