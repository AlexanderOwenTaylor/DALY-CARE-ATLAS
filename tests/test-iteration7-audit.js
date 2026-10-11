const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
function load(start,end,context){vm.runInContext(html.slice(html.indexOf(start),html.indexOf(end)),context);}
function search(mobile=false){
  const container={innerHTML:'',classList:{remove(){},toggle(){}}};
  const context=vm.createContext({text:String,escapeHtml:String,renderBadge:()=>'',sourceDisplayName:String,appState:{},window:{matchMedia:()=>({matches:mobile})},document:{getElementById:()=>container},buildGlobalSearchResults:()=>({ 'Source fields':Array.from({length:7},(_,i)=>({title:'Registry '+i,score:1200-i,query:'field'+i})),Codes:[{title:'Plasma creatinine',score:1000,query:'NPU04998'},{title:'Urine creatinine',score:999,query:'NPU09102'},{title:'Patient creatinine',score:998,query:'NPU03800'}]})});
  load('      function renderGlobalSearch(', '      function filteredRowsForExport(',context);
  return {context,container};
}
for(const mobile of [false,true]) test(`balanced search preview exposes specimen codes and registry fields (${mobile?'mobile':'desktop'})`,()=>{
  const {context,container}=search(mobile);vm.runInContext("renderGlobalSearch('creatinine')",context);
  assert.match(container.innerHTML,/Plasma creatinine/);assert.match(container.innerHTML,/Urine creatinine/);assert.match(container.innerHTML,/Registry 0/);
  assert.equal((container.innerHTML.match(/data-search-open=/g)||[]).length,mobile?4:6);
  context.appState.globalResultsExpanded=true;vm.runInContext("renderGlobalSearch('creatinine')",context);assert.equal((container.innerHTML.match(/data-search-open=/g)||[]).length,10);
});
test('approved numeric zero has labelled quartiles and an unknown source unit',()=>{
  const context=vm.createContext({});load('      function text(', '      function metric(',context);load('      function finiteSummary(', '      function renderColumnExplorer(',context);
  const rendered=vm.runInContext("columnStat({profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:0,p25:0,p75:10})",context);
  assert.match(rendered,/Median.*0/);assert.match(rendered,/Q1–Q3 interval.*0.*10/);assert.match(rendered,/Unit not supplied in this source profile/);
  const missing=vm.runInContext("columnStat({profile_kind:'numeric',numeric_privacy_status:'eligible_stored_summary',median:null})",context);assert.match(missing,/Median<\/dt><dd>Not supplied/);assert.doesNotMatch(missing,/Median<\/dt><dd>0/);
});
test('exact code match precedes lower scoring groups in the bounded preview',()=>{
  const {context,container}=search();context.buildGlobalSearchResults=()=>({'Source fields':[{title:'Registry',query:'field',score:760}],Codes:[{title:'Exact plasma code',query:'NPU04998',score:1200}]});
  vm.runInContext("renderGlobalSearch('NPU04998')",context);
  assert.ok(container.innerHTML.indexOf('Exact plasma code')<container.innerHTML.indexOf('Registry'));
  assert.match(container.innerHTML,/data-search-query="NPU04998"/);
});
test('related semantic table export disables empty matches and recovers with rows',()=>{
  const button={disabled:false};const context=vm.createContext({appState:{},rowMatchesQuery:()=>true,setHtml:()=>{},rowsForTable:()=>'',formatNumber:String,escapeHtml:String,document:{querySelectorAll:()=>[button],getElementById:()=>({value:'',closest:()=>null})}});
  load('      function updateEmptyExportButtons(', '      function renderSemanticExplorer(',context);load('      function renderFilteredSemanticTable(', '      function renderSemanticLineageBlocks(',context);
  vm.runInContext("renderFilteredSemanticTable('semantic-value-map',[],'semanticValueFilteredRows','semantic-value-search')",context);assert.equal(button.disabled,true);
  vm.runInContext("renderFilteredSemanticTable('semantic-value-map',[{value:'safe'}],'semanticValueFilteredRows','semantic-value-search')",context);assert.equal(button.disabled,false);
});
for(const [targetId,viewName] of [['semantic-overlay-map','semantic-overlay'],['semantic-conflict-map','semantic-conflicts']]) test(`${targetId} disables the actual export control for zero matches and recovers`,()=>{
  const button={disabled:false};const context=vm.createContext({appState:{},rowMatchesQuery:()=>true,setHtml:()=>{},rowsForTable:()=>'',formatNumber:String,escapeHtml:String,document:{querySelectorAll:selector=>selector===`[data-export-view="${viewName}"]`?[button]:[],getElementById:()=>({value:'',closest:()=>null})}});
  load('      function updateEmptyExportButtons(', '      function renderSemanticExplorer(',context);load('      function renderFilteredSemanticTable(', '      function renderSemanticLineageBlocks(',context);
  vm.runInContext(`renderFilteredSemanticTable('${targetId}',[],'semanticFilteredRows','search')`,context);assert.equal(button.disabled,true);
  vm.runInContext(`renderFilteredSemanticTable('${targetId}',[{value:'safe'}],'semanticFilteredRows','search')`,context);assert.equal(button.disabled,false);
});
test('navigation reserves actual wrapped toolbar space on desktop and mobile',()=>{
  let scrolled;const subnav={getBoundingClientRect:()=>({height:54})};const target={closest:()=>({querySelector:()=>subnav}),getBoundingClientRect:()=>({top:600}),setAttribute(){},focus(){}};
  const context=vm.createContext({document:{querySelector:()=>({getBoundingClientRect:()=>({height:100})})},getComputedStyle:()=>({position:'static'}),window:{scrollY:200,matchMedia:()=>({matches:true}),scrollTo:x=>scrolled=x}});
  load('      function scrollToAtlasTarget(', '      /* REGISTRY_THEME_ACTION_START */',context);context.target=target;vm.runInContext('scrollToAtlasTarget(target)',context);assert.equal(scrolled.top,630);assert.equal(scrolled.behavior,'auto');
});
test('zero semantic source rows differ from nonzero source filtered to no matches',()=>{
  const output={};const button={disabled:false};const elements={};
  const context=vm.createContext({semanticRows:[],appState:{},textMatchesQuery:()=>false,semanticPanelFor:()=>'',semanticHay:()=>'',escapeHtml:String,renderSemanticDetail:()=>{},setHtml:(id,value)=>output[id]=value,document:{getElementById:id=>elements[id]||=( {value:'',innerHTML:'',querySelectorAll:()=>[]}),querySelectorAll:selector=>selector.includes('data-export-view')?[button]:[]}});
  load('      function updateEmptyExportButtons(', '      function renderFilteredSemanticTable(',context);
  // Load the existing renderer separately until the shared helper has been introduced.
  if(!context.renderSemanticExplorer)load('      function renderSemanticExplorer(', '      function renderFilteredSemanticTable(',context);
  vm.runInContext('renderSemanticExplorer()',context);
  assert.match(output['semantic-list'],/Field connections are not included/);assert.match(output['semantic-list'],/data-jump-tab="infrastructure" data-jump-sub="infra-columns"/);assert.equal(button.disabled,true);
  context.semanticRows=[{}];context.document.getElementById('semantic-search').value='unmatched';vm.runInContext('renderSemanticExplorer()',context);assert.match(output['semantic-list'],/current filters/);assert.doesNotMatch(output['semantic-list'],/Field connections are not included/);
});
test('search replacement toggle handlers restore focus only on explicit toggle activation',()=>{
  let listener;let focused=0;const replacement={focus:()=>focused++};
  const context=vm.createContext({appState:{lastGlobalQuery:'creatinine'},globalAtlasSearch:{value:'creatinine'},parseHashRoute:()=>({tabId:'overview',subId:'overview-summary'}),updateShareUrl(){},activeSubForTab:()=>'',renderGlobalSearch:()=>{},document:{addEventListener:(_event,handler)=>listener=handler,getElementById:()=>({querySelector:()=>replacement})}});
  const start=html.indexOf('      document.addEventListener("click", event => {\n        if (event.target.closest(\'[data-clear-global-search]\'))');
  const end=html.indexOf('        const copy =',start);
  vm.runInContext(html.slice(start,end)+'\n      });',context);
  listener({target:{closest:selector=>selector.includes('data-toggle-global-results')?{}:null}});assert.equal(focused,1);
  listener({target:{closest:()=>null}});assert.equal(focused,1);
});
