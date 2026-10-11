// Execute the atlas's real matching functions against an explicitly supplied index.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { performance } = require('node:perf_hooks');
const { createHash } = require('node:crypto');
const root = path.resolve(__dirname, '..');
const payloadPath = process.argv[2] || process.env.DALYCARE_BENCHMARK_PAYLOAD;
if (!payloadPath) {
  console.error('Usage: node tests/benchmark-search.cjs PAYLOAD.json-or-js [TEMPLATE.html]\nOr set DALYCARE_BENCHMARK_PAYLOAD to an explicit payload path. No local export is loaded by default.');
  process.exit(2);
}
const template = process.argv[3] || path.join(root, 'inst/templates/DALYCARE_atlas.html');
const html = fs.readFileSync(template, 'utf8');
const functions = html.slice(html.indexOf('      function normalizeSearchText'), html.indexOf('      function codeSearchValue'))
  + html.slice(html.indexOf('      function scoreSearchResult'), html.indexOf('      function dedupeSearchResults'));
const payloadText = fs.readFileSync(payloadPath, 'utf8').replace(/^\uFEFF/, '');
const transport = vm.createContext({window:{},inputText:payloadText.trim().replace(/^window.DALYCARE_ATLAS_PAYLOAD\s*=\s*/, '').replace(/;$/, '')});
vm.runInContext(fs.readFileSync(path.join(root, 'inst/templates/atlas-transport.js'), 'utf8'), transport);
const payload = vm.runInContext('window.DALYCARE_TRANSPORT.decode(JSON.parse(inputText))', transport);
if (!Array.isArray(payload.column_profile_rows)) throw new Error('Payload must provide column_profile_rows');
const context = vm.createContext({text: value => value == null ? '' : String(value)});
vm.runInContext(functions, context);
const rank = vm.runInContext('scoreSearchResult', context);
const fields = {exact:['column_name'], title:['column_name'], source:['table_name'], body:['domain','subdomain']};
const scores = [];
const started = performance.now();
for (const query of ['creatinine','admission','smoking','NPU04998','rituximab']) {
  scores.push(payload.column_profile_rows.map(row => rank(row,query,fields)));
}
console.log(JSON.stringify({milliseconds:+(performance.now()-started).toFixed(1), rows:payload.column_profile_rows.length, queries:5,
  scoreChecksum:createHash('sha256').update(JSON.stringify(scores)).digest('hex')}));
