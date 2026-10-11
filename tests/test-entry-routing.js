const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const dir=path.join(__dirname,'../inst/templates');
function routes(){const file=path.join(dir,'atlas-entry.js');assert.ok(fs.existsSync(file),'entry routes exist');const window={location:{hash:'',pathname:'/DALYCARE_atlas.html'},addEventListener(){}};vm.runInNewContext(fs.readFileSync(file,'utf8'),{window,URLSearchParams,document:{getElementById:()=>null}});return window.DALYCARE_ROUTES;}
test('legacy known clinical/source/field fragments are preserved exactly',()=>{
 const r=routes();for(const hash of ['#laboratory/lab-npu?q=NPU04998&g=',' #infrastructure/infra-columns?source=SP&q=weight'.trim(),'#dictionary/dictionary-codes?category=fields','#infrastructure/infra-columns?measurement=weight'])assert.equal(r.destination(hash), 'DALYCARE_clinical.html'+hash);
 assert.equal(r.destination('#evil/path?return=https://evil'),'DALYCARE_atlas.html?route=unknown');
});
test('old Panels queries preserve g as search and validate explicit groups in library',()=>{
 const r=routes(),dest=r.destination('#infrastructure/infra-panels?g=admissions&group=Clinical');assert.equal(dest,'DALYCARE_outputs.html?q=admissions&group=Clinical');assert.equal(r.destination('#infrastructure/infra-panels?q=old'),'DALYCARE_outputs.html?q=old');
});
test('entry and table library initial assets contain no core or table rows',()=>{
 for(const file of ['DALYCARE_entry.html','DALYCARE_outputs.html']){assert.ok(fs.existsSync(path.join(dir,file)),file+' exists');const html=fs.readFileSync(path.join(dir,file),'utf8');assert.doesNotMatch(html,/<script[^>]+(?:atlas_payload|output-shards|clinical\.html)/);assert.match(html,/atlas-pages.css/);}
 const entry=fs.readFileSync(path.join(dir,'DALYCARE_entry.html'),'utf8');assert.match(entry,/Weight and height/);assert.match(entry,/Common values/);assert.match(entry,/Coverage over time/);assert.match(entry,/Coverage by place/);
 const clinical=fs.readFileSync(path.join(dir,'DALYCARE_atlas.html'),'utf8');assert.match(clinical,/href="DALYCARE_atlas.html"[^>]*>Home/);assert.match(clinical,/href="DALYCARE_outputs.html"[^>]*>Data tables/);assert.doesNotMatch(clinical,/<a[^>]*href="DALYCARE_(?:atlas|outputs).html"[^>]*class="tab-button"/);
});
test('Panels library navigation uses changed or cleared global search at click time',()=>{
 const html=fs.readFileSync(path.join(dir,'DALYCARE_atlas.html'),'utf8');
 const start=html.indexOf('      function renderPanels()');
 const end=html.indexOf('      document.getElementById("panel-group-filter").addEventListener("change", renderPanels);',start);
 const link={href:'',listeners:{},addEventListener(name,handler){this.listeners[name]=handler;}};
 const search={value:'old query'},group={value:'Clinical'};
 const elements={'global-atlas-search':search,'panel-group-filter':group,'panel-list':{querySelector:()=>link}};
 const context=vm.createContext({URLSearchParams,document:{getElementById:id=>elements[id]},escapeHtml:value=>String(value).replace(/&/g,'&amp;'),setHtml(id,html){if(id==='panel-list')link.href=html.match(/href="([^"]+)"/)[1].replace(/&amp;/g,'&');}});
 vm.runInContext(html.slice(start,end)+'\nrenderPanels();',context);
 search.value='æ & weight';link.listeners.click?.();
 let params=new URLSearchParams(link.href.split('?')[1]);assert.equal(params.get('q'),'æ & weight');assert.equal(params.get('group'),'Clinical');
 search.value='';link.listeners.click?.();
 params=new URLSearchParams(link.href.split('?')[1]);assert.equal(params.has('q'),false);assert.equal(params.get('group'),'Clinical');
});

test('Home question arrival focuses answers once below sticky navigation without altering history restoration',()=>{
 const html=fs.readFileSync(path.join(dir,'DALYCARE_atlas.html'),'utf8');
 const start=html.indexOf('      function focusQuestionArrival()'),end=html.indexOf('      function overflowReport()',start);
 assert.ok(start>=0);
 const helper=html.slice(html.indexOf('      function scrollToAtlasTarget('),html.indexOf('      const atlasNav ='));
 const calls=[],target={setAttribute(){},focus(options){calls.push(['focus',options]);},scrollIntoView(options){calls.push(['rawScroll',options]);},getBoundingClientRect:()=>({top:1000}),closest:()=>({querySelector:()=>({getBoundingClientRect:()=>({height:30})})})};
 const window={location:{search:'?question=weight-height'},scrollY:0,scrollTo:options=>calls.push(['scroll',options]),matchMedia:()=>({matches:true}),performance:{getEntriesByType:()=>[{type:'navigate'}]}};
 const document={querySelector:()=>({getBoundingClientRect:()=>({height:50})}),getElementById:id=>id==='column-list'?{querySelector:()=>target}:null};
 const context=vm.createContext({window,URLSearchParams,isQaRoute:()=>false,parseHashRoute:()=>({subId:'infra-columns'}),document});
 vm.runInContext(helper+html.slice(start,end)+';focusQuestionArrival();focusQuestionArrival();',context);
 assert.equal(calls.filter(c=>c[0]==='focus').length,1);assert.equal(calls.filter(c=>c[0]==='scroll').length,1);assert.equal(calls.find(c=>c[0]==='scroll')[1].top,904);
 calls.length=0;window.performance.getEntriesByType=()=>[{type:'back_forward'}];
 vm.runInNewContext(helper+html.slice(start,end)+';focusQuestionArrival();',{window,URLSearchParams,isQaRoute:()=>false,parseHashRoute:()=>({subId:'infra-columns'}),document});
 assert.equal(calls.length,0);
});
