const {test,after}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),cp=require('node:child_process');
const root=path.join(__dirname,'..'),site=path.join(root,'.artifact-temp','E1-production-module-site');
cp.execFileSync(process.env.PYTHON||(process.platform==='win32'?'python':'python3'),[path.join(__dirname,'generate-screened-site.py'),site],{cwd:root,stdio:'pipe'});
const measurements=[];after(()=>{const report=path.join(root,'.artifact-temp/repair-upgrade/E1-production-loading.json');fs.mkdirSync(path.dirname(report),{recursive:true});fs.writeFileSync(report,JSON.stringify(measurements,null,2));});
function harness(search='',hash='#overview/overview-summary',transform=(name,text)=>text){
 const requested=[],elements=new Map(),failures=[],listeners={};let context;
 function element(id){if(!elements.has(id))elements.set(id,{id,value:'',innerHTML:'',textContent:'',dataset:{},setAttribute(){},querySelector(){return null;},querySelectorAll(){return [];},remove(){}});return elements.get(id);}
 function execute(name,script){requested.push(name);const prior=document.currentScript;document.currentScript=script;try{vm.runInContext(transform(name,fs.readFileSync(path.join(site,name),'utf8')),context,{filename:name});}finally{document.currentScript=prior;}}
 const document={getElementById:element,documentElement:{dataset:{}},createElement:()=>({remove(){}}),head:{appendChild(script){const name=script.src||script.href;assert.match(name,/^[A-Za-z0-9_./-]+$/);if(script.href){requested.push(name);return;}queueMicrotask(()=>{try{execute(name,script);script.onload?.();}catch(e){failures.push(e);script.onerror?.();}});}}};
 const window={location:{search,hash,pathname:'DALYCARE_clinical.html'},history:{replaceState(){}},addEventListener(name,handler){listeners[name]=handler;}};
 context=vm.createContext({window,document,URLSearchParams,TextEncoder,AbortController,setTimeout,clearTimeout,console});
 requested.push('DALYCARE_clinical.html','atlas-shell.css','favicon.svg');for(const name of ['DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js'])execute(name);
 async function ready(){for(let i=0;i<100;i++){await new Promise(resolve=>setImmediate(resolve));if(document.documentElement.dataset.atlasReady&& !/Loading|Searching/.test(element('load-state').textContent))break;}assert.deepEqual(failures,[]);assert.doesNotMatch(element('load-state').textContent,/failed/i);measurements.push({route:search+hash,bytes:requested.reduce((n,p)=>n+fs.statSync(path.join(site,p)).size,0),requests:[...requested]});}
 return {window,document,requested,element,ready,async navigate(hash,search=''){window.location.hash=hash;window.location.search=search;listeners.hashchange();await ready();},bytes(){return requested.reduce((n,p)=>n+fs.statSync(path.join(site,p)).size,0);}};
}
test('production opening knows all2200 identities without detail/reference transfers',async()=>{
 const h=harness();await h.ready();assert.equal(h.window.DALYCARE_SHELL.findFields('').length,2200);assert.equal(h.window.DALYCARE_SHELL.findFields('exact_field_2199').length,1);
 assert.ok(!h.requested.some(x=>/output-shards|registry-v2|table-descriptors/.test(x)));assert.ok(h.bytes()<=524288);assert.match(h.element('route-content').innerHTML,/Available evidence|Exact source fields/);
});
test('cold exact field route loads its own shard and stays within closure budget',async()=>{
 const h=harness('?table=column_profiles&source=Synthetic_Source_21&field=exact_field_2199');await h.ready();assert.match(h.element('detail-content').innerHTML,/exact_field_2199/);assert.match(h.element('detail-content').innerHTML,/Withheld/);
 assert.equal(h.requested.filter(x=>/^output-shards/.test(x)).length,1);assert.ok(h.bytes()<=524288,`actual requested closure ${h.bytes()}`);
});
test('NPU reference search covers unloaded definitions and opens exact Unicode definition',async()=>{
 const h=harness();await h.ready();const dictionary=JSON.parse(fs.readFileSync(path.join(site,'DALYCARE_output_catalogue.js'),'utf8').split('=',2)[1].trim().replace(/;$/,''));
 const t=dictionary.tables.find(t=>t.id==='npu_display_dictionary'),last=t.shards.at(-1),script=fs.readFileSync(path.join(site,last.src),'utf8'),rows=JSON.parse(JSON.parse(script.slice(script.indexOf('register(')+9).trim().slice(0,-2)).rows_json),entry=rows.at(-1);
 await h.window.DALYCARE_SHELL.searchReference(entry.code);assert.match(h.element('detail-content').innerHTML,new RegExp(entry.code));assert.ok(!h.requested.some(x=>/^output-shards\/npu_display_dictionary/.test(x)));
 const indexTable=h.window.DALYCARE_DIRECTORY.tables.find(t=>t.id==='npu_reference_search');const result=await h.window.DALYCARE_OUTPUTS.scanTable(indexTable.id,entry.code,0);assert.equal(result.total_matches,1);
 await h.window.DALYCARE_SHELL.showDefinition(result.rows[0]);assert.match(h.element('detail-content').innerHTML,new RegExp(entry.code));assert.ok(h.requested.some(x=>x===last.src));assert.ok(h.element('detail-content').innerHTML.includes(entry.definition.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;')));
});
test('cold old NPU item URL opens the exact definition within the complete dependency budget',async()=>{
 const h=harness('','#laboratory/lab-npu?q=NPU04998&item=NPU04998&source=SP_Laboratorieproever');await h.ready();assert.equal((h.element('detail-content').innerHTML.match(/aria-label="Evidence context"/g)||[]).length,1);assert.match(h.element('load-state').textContent,/reference definition NPU04998/);assert.ok(h.bytes()<=524288,`NPU cold closure ${h.bytes()}`);
});
test('production mixed registry first page validates its complete locator inventory before one shard',async()=>{
 const h=harness('?table=registry_field_summaries');await h.ready();assert.match(h.element('detail-content').innerHTML,/registry-summary-v2/);assert.match(h.element('detail-content').innerHTML,/registry-summary-v1/);
 assert.equal(h.requested.filter(x=>/^output-shards\/registry_field_summaries/.test(x)).length,1);assert.ok(h.requested.includes('registry-v2.js'));assert.ok(h.bytes()<=524288,`registry cold closure ${h.bytes()}`);
 const result=await h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0);assert.equal(result.rows.length,50);assert.equal(result.total_matches,217);
});
test('registry duplicate locators across unloaded shards fail before row requests',async()=>{
 const h=harness('','#overview/overview-summary',(name,text)=>{if(name!=='table-descriptors/registry_field_summaries.js')return text;const data=JSON.parse(text.split('registerDescriptor(')[1].trim().slice(0,-2));data.table.shards[1].fields[0]=data.table.shards[0].fields[0];return 'window.DALYCARE_OUTPUTS.registerDescriptor('+JSON.stringify(data)+');';});await h.ready();await h.window.DALYCARE_SHELL.showTable('registry_field_summaries');assert.match(h.element('load-state').textContent,/Duplicate registry locator/);assert.ok(!h.requested.some(x=>/^output-shards/.test(x)));
});
test('registry row identities must match their individually unique declared locators',async()=>{
 const h=harness('','#overview/overview-summary',(name,text)=>{if(name!=='table-descriptors/registry_field_summaries.js')return text;const data=JSON.parse(text.split('registerDescriptor(')[1].trim().slice(0,-2)),s=data.table.shards[0];[s.fields[0],s.fields[1]]=[s.fields[1],s.fields[0]];return 'window.DALYCARE_OUTPUTS.registerDescriptor('+JSON.stringify(data)+');';});await h.ready();await h.window.DALYCARE_SHELL.showTable('registry_field_summaries');assert.match(h.element('load-state').textContent,/locator identity disagrees/);assert.equal(h.element('detail-content').innerHTML,'<button id="retry-load">Retry this table</button>');
});
test('descriptor confinement and in-flight directory mutation reject before rows',async()=>{
 const h=harness();await h.ready();const entry=h.window.DALYCARE_DIRECTORY.tables.find(t=>t.id==='column_profiles'),before=h.requested.length;entry.descriptor='../private.js';await assert.rejects(h.window.DALYCARE_OUTPUTS.ensureDescriptor(entry.id),/descriptor path/);assert.equal(h.requested.length,before);
 entry.descriptor='table-descriptors/column_profiles.js';const pending=h.window.DALYCARE_OUTPUTS.ensureDescriptor(entry.id);entry.title='changed during read';await assert.rejects(pending,/identity/);assert.ok(!h.requested.some(x=>/^output-shards/.test(x)));
});
test('cold source profiles count complete identities while loading only the first page shard',async()=>{
 const h=harness('?table=column_profiles&source=Synthetic_Source_21');await h.ready();assert.match(h.element('load-state').textContent,/100 matching/);assert.equal(h.requested.filter(x=>/^output-shards/.test(x)).length,1);assert.ok(h.bytes()<=524288);
});
test('old semantic item identity and broad domain routes remain useful without eager details',async()=>{
 const source='Synthetic_Source_21',field='exact_field_2199',item='current_'+Buffer.from(source).toString('hex')+'_'+Buffer.from(field).toString('hex'),h=harness('','#variables/variables-raw?item='+item);await h.ready();assert.match(h.element('detail-content').innerHTML,/exact_field_2199/);assert.ok(h.bytes()<=524288);
 for(const [hash,title] of [['#situation','Current and recent activity'],['#treatment','Medicines and treatment'],['#clinical-feasibility/mcl-triangle-feasibility','MCL TRIANGLE feasibility'],['#ehr','EHR source modules'],['#infrastructure/infra-catalog','Source catalogue and collection status']]){const route=harness('',hash);await route.ready();assert.equal(route.element('route-title').textContent,title);assert.match(route.element('route-content').innerHTML,/Inspect evidence|Complete CSV/);assert.ok(route.bytes()<=524288);}
});

test('actual wide UTF8 producer rows use bounded cold bytes and preserve continuation',async()=>{
 const h=harness('?table=registry_clinical_summary');await h.ready();assert.ok(h.bytes()<=524288,`wide cold closure ${h.bytes()}`);
 const first=await h.window.DALYCARE_OUTPUTS.scanTable('registry_clinical_summary','',0);assert.equal(first.total_matches,4);assert.ok(first.rows.length>0&&first.rows.length<4);assert.equal(h.requested.filter(x=>/^output-shards\/registry_clinical_summary/.test(x)).length,1);
 const next=await h.window.DALYCARE_OUTPUTS.scanTable('registry_clinical_summary','',0,undefined,undefined,{offset:first.next_offset});assert.equal(first.rows.length+next.rows.length,4);assert.equal(new Set([...first.rows,...next.rows].map(r=>r.table_name)).size,1);assert.equal(next.next_offset,4);
});

test('cached registry rows reject changed threshold and resource context',async()=>{
 for(const mutation of ['threshold','resource','validator']){
  const h=harness('?table=registry_field_summaries');await h.ready();const before=await h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0);assert.ok(before.rows.some(r=>r.summary_status==='published'));
  if(mutation==='threshold')h.window.DALYCARE_DIRECTORY.minimum_cell_count=100;else if(mutation==='resource')h.window.DALYCARE_REGISTRY_V2_RESOURCE.fields[0].label='changed policy context';else h.window.DALYCARERegistryV2.validate=()=>true;
  await assert.rejects(h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0),/privacy|context|contract/i);
 }
});

test('in-flight registry completion rejects privacy resource and validator mutations',async()=>{
 for(const mutation of ['threshold','resource','validator']){
  const h=harness('','#overview/overview-summary',(name,text)=>{
   if(!name.startsWith('output-shards/registry_field_summaries'))return text;
   const change=mutation==='threshold'?'window.DALYCARE_DIRECTORY.minimum_cell_count=100;':mutation==='resource'?"window.DALYCARE_REGISTRY_V2_RESOURCE.fields[0].label='changed during load';":'window.DALYCARERegistryV2.validate=()=>true;';
   return change+text;
  });await h.ready();await assert.rejects(h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0),/privacy|context|policy/i);
 }
});
test('cold reference source context does not scan all definitions or imply observed membership',async()=>{
 const h=harness('?table=npu_display_dictionary&source=SP_Laboratorieproever');await h.ready();assert.ok(h.bytes()<=524288,`scoped reference cold ${h.bytes()}`);assert.equal(h.requested.filter(x=>/^output-shards\/npu_display_dictionary/.test(x)).length,1);assert.match(h.element('detail-content').innerHTML,/Reference definitions/);assert.match(h.element('detail-content').innerHTML,/navigation context/i);
});
test('completed navigation clears prior selected definition and field search state',async()=>{
 const h=harness('','#laboratory/lab-npu?q=NPU04998&item=NPU04998');await h.ready();assert.match(h.element('detail-content').innerHTML,/NPU04998/);await h.navigate('#registries/reg-damyda');assert.doesNotMatch(h.element('detail-content').innerHTML,/NPU04998/);assert.match(h.element('detail-content').innerHTML,/RKKP_DaMyDa/);assert.equal(h.element('search-results').innerHTML,'');
 const field=harness('?source=Synthetic_Source_21&field=exact_field_2199');await field.ready();assert.match(field.element('detail-content').innerHTML,/exact_field_2199/);await field.navigate('#treatment');assert.equal(field.element('detail-content').innerHTML,'');
});

test('registry theme uses exact reviewed identities and the selected clinical answer precedes lineage',async()=>{
 const h=harness('','#registries/reg-damyda?theme=stage');await h.ready();assert.match(h.element('detail-content').innerHTML,/data-primary-answer/);assert.ok(h.bytes()<=524288);
 const route=h.window.DALYCARE_SHELL.route();assert.equal(route.source,'RKKP_DaMyDa');
 const resource=h.window.DALYCARE_REGISTRY_V2_RESOURCE,fields=resource.fields.filter(r=>r.table_name==='RKKP_DaMyDa'&&r.topic==='stage').map(r=>r.source_column);
 const result=await h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0,undefined,undefined,{source:'RKKP_DaMyDa',fields});assert.ok(result.rows.length>0);assert.ok(result.rows.every(r=>r.topic==='stage'));
 const none=await h.window.DALYCARE_OUTPUTS.scanTable('registry_field_summaries','',0,undefined,undefined,{source:'RKKP_DaMyDa',fields:[]});assert.equal(none.total_matches,0);
});

test('exact registry identity prefers its validated clinical outcome and global links discard source query',async()=>{
 const h=harness('?table=column_profiles&source=RKKP_DaMyDa&field=Stadie');await h.ready();assert.ok(h.requested.some(x=>x.startsWith('output-shards/registry_field_summaries')));assert.ok(!h.requested.some(x=>x.startsWith('output-shards/column_profiles')));assert.match(h.element('detail-content').innerHTML,/data-primary-answer/);assert.ok(h.bytes()<=524288);
 assert.match(h.element('task-content').innerHTML,/href="DALYCARE_clinical.html#clinical\/clinical-vitals"/);assert.doesNotMatch(h.element('task-content').innerHTML,/href="#/);
});

test('local q and explicitly empty global g remain distinct on saved routes',async()=>{
 const h=harness('','#laboratory/lab-npu?q=NPU04998&g=&item=NPU04998');await h.ready();assert.equal(h.window.DALYCARE_SHELL.route().q,'NPU04998');assert.equal(h.window.DALYCARE_SHELL.route().g,'');assert.equal(h.element('search-results').innerHTML,'');assert.match(h.element('detail-content').innerHTML,/NPU04998/);
});

test('semantic source-field locators use logical source and raw column across unloaded shards',async()=>{
 for(const name of fs.readdirSync(path.join(site,'output-shards')).filter(n=>n.startsWith('semantic_dictionary-')))assert.ok(fs.statSync(path.join(site,'output-shards',name)).size<=131072,'semantic writer uses bounded transfer target');
 const h=harness('?table=semantic_dictionary&source=Synthetic_Source_21&field=exact_field_2199');await h.ready();assert.match(h.element('detail-content').innerHTML,/exact_field_2199/);assert.equal(h.requested.filter(x=>/^output-shards\/semantic_dictionary/.test(x)).length,1);assert.ok(h.bytes()<=524288);
});

test('small source-filtered evidence completes automatically; large prefix stays explicitly partial',async()=>{
 const small=harness('?table=sources&source=Synthetic_Source_21');await small.ready();assert.match(small.element('load-state').textContent,/Complete: 1 matching/);assert.match(small.element('detail-content').innerHTML,/Synthetic_Source_21/);assert.ok(small.bytes()<=524288);
 const large=harness('?table=registry_clinical_summary&source=Synthetic_Source_21');await large.ready();assert.match(large.element('load-state').textContent,/Partial search: at least 0/);assert.match(large.element('detail-content').innerHTML,/Remaining rows have not been searched/);assert.ok(large.bytes()<=524288);assert.equal(large.requested.filter(x=>/^output-shards\/registry_clinical_summary/.test(x)).length,1);
 const budgets=JSON.parse(fs.readFileSync(path.join(site,'loading-budget.json'),'utf8')).routes;
 for(const [table,h] of [['sources',small],['registry_clinical_summary',large]])assert.ok(budgets.find(r=>r.route==='source-filtered bounded scan='+table).bytes>=h.bytes(),'producer budget must cover actual filtered dependency bytes');
 const complete=await large.window.DALYCARE_SHELL.showTable('registry_clinical_summary','','Synthetic_Source_21','',0,null,true);assert.equal(complete.complete,true);assert.equal(complete.scanned_rows,4);assert.match(large.element('load-state').textContent,/Complete: 0 matching/);
});

test('global field submission searches other sources from a selected source route',async()=>{
 const h=harness('?source=Synthetic_Source_21');await h.ready();h.element('search-query').value='exact_field_0';h.element('field-search').onsubmit({preventDefault(){}});assert.match(h.element('search-results').innerHTML,/Synthetic_Source_0/);
});

test('form Enter opens an exact NPU definition and reference back clears stale field results',async()=>{
 const h=harness('','#laboratory/lab-npu?source=SP_Laboratorieproever');await h.ready();h.element('search-results').innerHTML='STALE_ZERO_FIELDS';h.element('search-query').value=' npu04998 ';
 await h.element('field-search').onsubmit({preventDefault(){}});assert.match(h.element('load-state').textContent,/reference definition NPU04998/);assert.match(h.element('detail-content').innerHTML,/Creatinine/);assert.equal(h.element('search-results').innerHTML,'');assert.match(h.element('detail-content').innerHTML,/Reference definitions do not establish observed usage/);assert.match(h.element('detail-content').innerHTML,/source=SP_Laboratorieproever/);
 assert.equal(h.requested.filter(n=>n.startsWith('output-shards/npu_reference_search')).length,1);assert.equal(h.requested.filter(n=>n.startsWith('output-shards/npu_display_dictionary')).length,1);
 await h.element('back-reference').onclick();assert.match(h.element('detail-content').innerHTML,/NPU reference matches/);assert.match(h.element('detail-content').innerHTML,/NPU04998/);
 h.element('search-query').value='Creatinine';await h.element('reference-search').onclick();assert.match(h.element('detail-content').innerHTML,/NPU reference matches/);assert.match(h.element('detail-content').innerHTML,/Creatinine/);
});

test('explicit field search keeps its intent and offers exact-code reference recovery',async()=>{
 const html=fs.readFileSync(path.join(site,'DALYCARE_clinical.html'),'utf8');assert.match(html,/<button id="field-search-button" type="button">Search fields/);assert.match(html,/Enter opens an exact NPU code/);
 const h=harness('?source=Synthetic_Source_21');await h.ready();h.element('search-query').value='NPU04998';h.element('field-search-button').onclick();assert.match(h.element('load-state').textContent,/field identities searched/);assert.match(h.element('search-results').innerHTML,/No matching exact field names/);assert.ok(!h.requested.some(n=>n.startsWith('output-shards/npu_')));
 const recovery=h.element('search-results').innerHTML.match(/href="([^"]+)">Open NPU04998 reference definition/)[1].replaceAll('&amp;','&');assert.match(recovery,/source=Synthetic_Source_21/);await h.navigate(recovery.slice(recovery.indexOf('#')));assert.match(h.element('detail-content').innerHTML,/Creatinine/);assert.equal(h.element('search-results').innerHTML,'');
 h.element('search-query').value='exact_field_0';h.element('field-search-button').onclick();assert.match(h.element('search-results').innerHTML,/Synthetic_Source_0/);
});

for(const table of ['registry_field_summaries','column_profiles'])test('early exact '+table+' skips all trailing zero-match locator shards',async()=>{
 const descriptor=JSON.parse(fs.readFileSync(path.join(site,'table-descriptors',table+'.js'),'utf8').split('registerDescriptor(')[1].trim().slice(0,-2)).table,first=descriptor.shards[0],pair=first.fields[0];assert.ok(descriptor.shards.length>=3);assert.ok(first.asset_bytes+descriptor.shards[1].asset_bytes<=(table==='registry_field_summaries'?131072:262144),'fixture must allow the erroneous extra transfer');
 const h=harness('?'+new URLSearchParams({table,source:pair[0],field:pair[1]}));await h.ready();assert.deepEqual(h.requested.filter(p=>p.startsWith('output-shards/')),[first.src]);assert.match(h.element('load-state').textContent,/Complete: 1 matching screened rows/);assert.ok(h.bytes()<=524288);
});

test('opening an existing reference result clears intervening field no-match feedback',async()=>{
 const h=harness('','#laboratory/lab-npu?source=SP_Laboratorieproever');await h.ready();const buttons=[{dataset:{definition:'0'}}];h.element('detail-content').querySelectorAll=selector=>selector==='[data-definition]'?buttons:[];
 h.element('search-query').value='NPU04998';await h.element('reference-search').onclick();assert.match(h.element('detail-content').innerHTML,/<button data-definition="0">Open exact definition/);
 h.element('field-search-button').onclick();assert.match(h.element('search-results').innerHTML,/No matching exact field names/);assert.match(h.element('detail-content').innerHTML,/NPU reference matches/);
 await buttons[0].onclick();assert.match(h.element('load-state').textContent,/reference definition NPU04998/);assert.equal(h.element('search-results').innerHTML,'');assert.match(h.element('detail-content').innerHTML,/Creatinine/);assert.match(h.element('detail-content').innerHTML,/source=SP_Laboratorieproever/);
 await h.element('back-reference').onclick();assert.match(h.element('detail-content').innerHTML,/NPU reference matches/);
});
