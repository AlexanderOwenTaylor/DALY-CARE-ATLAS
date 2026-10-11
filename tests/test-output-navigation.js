const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const templates=path.join(__dirname,'../inst/templates');

// The full shipped runtime runs against a small DOM/history and script-loading boundary.
function navigation(search='',suppliedTables) {
  const html=fs.readFileSync(path.join(templates,'DALYCARE_outputs.html'),'utf8');
  const elements=new Map(),listeners={},scrolls=[],focuses=[],scripts=[];
  let window,document;
  function element(id,attrs='') {
    const handlers={};let hidden=/\bhidden\b/.test(attrs),markup='',cards=[];
    return {id,value:'',textContent:'',disabled:false,checked:false,dataset:{},tabIndex:/tabindex="(-?\d+)"/.test(attrs)?Number(RegExp.$1):undefined,
      get hidden(){return hidden;},set hidden(value){hidden=value;if(id==='library'&&value)window.scrollY=Math.min(window.scrollY,160);},
      get innerHTML(){return markup;},set innerHTML(value){markup=value;cards=[...value.matchAll(/<button[^>]*data-table="([^"]+)"/g)].map(match=>Object.assign(element('card-'+match[1]),{dataset:{table:match[1]}}));},
      addEventListener(name,fn){handlers[name]=fn;},fire(name){handlers[name]?.({preventDefault(){}});},
      querySelectorAll(){return cards;},setAttribute(name,value){this[name]=value;},
      focus(options){document.activeElement=this;focuses.push({element:this,options});if(!options?.preventScroll)window.scrollY=80;}
    };
  }
  for(const match of html.matchAll(/<[^>]*\bid="([^"]+)"[^>]*>/g))elements.set(match[1],element(match[1],match[0]));
  const el=id=>elements.get(id);
  document={getElementById:el,activeElement:null,body:{classList:{toggle(){}}},documentElement:{dataset:{}},createElement:()=>({remove(){}}),head:{appendChild(s){scripts.push(s);}}};
  const tables=suppliedTables||Array.from({length:147},(_,i)=>({id:'t'+i,title:'Table '+i,group:'Evidence',status:'metadata_only',columns:[],shards:[]}));
  const entries=[{search,state:null}],copy=value=>JSON.parse(JSON.stringify(value));let index=0;
  const history={scrollRestoration:'auto',get state(){return entries[index].state;},get length(){return entries.length;},
    replaceState(state,_title,url){entries[index]={state:copy(state),search:new URL(url,'https://atlas.test/').search};window.location.search=entries[index].search;},
    pushState(state,_title,url){entries.splice(++index);entries.push({state:copy(state),search:new URL(url,'https://atlas.test/').search});window.location.search=entries[index].search;},
    go(delta){index+=delta;window.location.search=entries[index].search;listeners.popstate({state:this.state});if(this.scrollRestoration==='auto')window.scrollY=160;}
  };
  window={DALYCARE_OUTPUT_CATALOGUE:{schema_version:1,build_id:'b1',tables},location:{search},history,scrollX:0,scrollY:0,
    scrollTo(options){scrolls.push({...options});this.scrollX=options.left;this.scrollY=options.top;},addEventListener(name,fn){listeners[name]=fn;}};
  vm.runInNewContext(fs.readFileSync(path.join(templates,'atlas-outputs.js'),'utf8'),{window,document,URLSearchParams,TextEncoder,AbortController,setTimeout:()=>1,clearTimeout(){}});
  const card=id=>el('table-list').querySelectorAll('[data-table]').find(button=>button.dataset.table===id);
  return {window,document,el,card,scrolls,focuses,scripts,tables,
    open(id,x=7,y=6200){window.scrollX=x;window.scrollY=y;card(id).focus({preventScroll:true});card(id).fire('click');},
    answer(rows){const t=tables.find(t=>t.id===new URLSearchParams(window.location.search).get('table')),s=t.shards[0];document.currentScript=scripts.at(-1);window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'b1',table_id:t.id,shard_id:s.id,rows_json:JSON.stringify(rows)});document.currentScript=null;}
  };
}

function readable(id,rows,metadata={}) {
 const json=JSON.stringify(rows);return {id,title:id,group:'Evidence',status:'available',kind:'aggregate_summary',complete:true,...metadata,columns:Object.keys(rows[0]).map(key=>({key,label:key,type:typeof rows[0][key]==='number'?'number':'string',definition:'Supplied meaning for '+key})),shards:[{id:'s1',src:'output-shards/'+id+'-s1.js',rows:rows.length,bytes:Buffer.byteLength(json)}]};
}
const flush=async()=>{for(let i=0;i<5;i++)await Promise.resolve();};

test('full catalogue is bounded to twelve entries per page and all 147 remain reachable',()=>{
 const h=navigation('?view=all'),seen=[];
 do {seen.push(...h.el('table-list').querySelectorAll('[data-table]').map(b=>b.dataset.table));assert.ok(h.el('table-list').querySelectorAll('[data-table]').length<=12);if(h.el('catalogue-next').disabled)break;h.el('catalogue-next').fire('click');}while(seen.length<200);
 assert.equal(seen.length,147);assert.equal(new Set(seen).size,147);assert.equal(seen.at(-1),'t146');assert.equal(h.scripts.length,0);
});

test('Back restores the originating card and catalogue page without focus scrolling',()=>{
 const h=navigation('?view=all&listpage=11&q=Table&group=Evidence&status=metadata_only');const origin=h.card('t120');h.open('t120');
 assert.equal(h.document.activeElement,h.el('table-title'));assert.equal(h.el('table-title').tabIndex,-1);
 h.window.scrollY=130;h.el('back-library').fire('click');
 assert.equal(h.window.scrollY,6200);assert.equal(h.window.scrollX,7);assert.equal(h.document.activeElement,h.card('t120'));assert.notEqual(h.card('t120'),origin);
 assert.equal(h.focuses.at(-1).options.preventScroll,true);assert.equal(new URLSearchParams(h.window.location.search).get('listpage'),'11');
});

test('browser Back and Forward retain per-entry origin through row-search history',()=>{
 const h=navigation('?view=all&listpage=11');h.open('t120');h.el('table-query').value='æ & value';h.el('search-table').fire('submit');
 h.window.history.go(-1);assert.equal(h.el('table-query').value,'');h.window.history.go(-1);assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'));
 h.window.history.go(1);h.window.history.go(1);assert.equal(h.el('table-query').value,'æ & value');h.el('back-library').fire('click');assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'));
});

test('legacy direct table links keep queries and data pages without an invented origin',()=>{
 const h=navigation('?table=t120&q=Table&group=Evidence&status=metadata_only&search=needle&page=3');
 assert.equal(h.el('table-query').value,'needle');assert.equal(h.document.activeElement,h.el('table-title'));
 h.el('back-library').fire('click');assert.equal(h.scrolls.length,0);assert.equal(h.document.activeElement,h.el('metadata-query'));assert.equal(new URLSearchParams(h.window.location.search).get('q'),'Table');
 h.window.history.go(-1);assert.equal(h.el('table-query').value,'needle');
});

test('typing metadata search replaces state and exact IDs find otherwise unrelated titles',()=>{
 const h=navigation('?view=all');for(const q of ['t','t1','t120']){h.el('metadata-query').value=q;h.el('metadata-query').fire('input');}
 assert.equal(h.window.history.length,1);assert.ok(h.card('t120'));assert.equal(h.card('t12'),undefined);
 h.open('t120');h.window.history.go(-1);assert.equal(h.el('metadata-query').value,'t120');assert.equal(h.document.activeElement,h.card('t120'));
});

test('question changes clear incompatible filters and show only reviewed task entries',()=>{
 const h=navigation('?view=all&q=old&group=Evidence&status=metadata_only',[{id:'column_profiles',title:'Field profiles',group:'Evidence',status:'available',columns:[],shards:[]},{id:'checks',title:'Checks',status:'available',columns:[],shards:[]}]);
 h.el('task-fields').fire('click');assert.equal(h.el('metadata-query').value,'');assert.equal(h.el('group-filter').value,'');assert.equal(h.el('availability-filter').value,'');assert.ok(h.card('column_profiles'));assert.equal(h.card('checks'),undefined);
 h.el('task-all').fire('click');assert.match(h.el('table-list').innerHTML,/Context only/);
});

test('catalogue search can deliberately carry a term into field rows without an automatic read',async()=>{
 const rows=[{table_name:'SP',column_name:'height_in_cm',median:172}],t=readable('column_profiles',rows),h=navigation('?q=height',[t]);
 assert.equal(h.scripts.length,0);assert.equal(h.el('query-actions').hidden,false);h.window.scrollY=550;h.el('search-field-rows').fire('click');
 assert.equal(h.el('table-query').value,'height');assert.equal(new URLSearchParams(h.window.location.search).get('search'),'height');assert.equal(h.scripts.length,1);
 h.answer(rows);await flush();h.el('back-library').fire('click');assert.equal(h.el('metadata-query').value,'height');assert.equal(h.document.activeElement,h.el('search-field-rows'));assert.equal(h.window.scrollY,550);
});

test('compact field rows preserve identities, denominator, supplied summaries, zero and withholding reasons',async()=>{
 const rows=[{table_name:'SP_PatientInfo',column_name:'height_in_cm',profile_kind:'numeric',n_rows:58216,n_available:41390,pct_available:71.1,mean:171.785,median:172,p25:165,p75:179,numeric_privacy_status:'eligible_stored_summary',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample',summary_scope:'stored_source_row_profile'},
 {table_name:'RKKP',column_name:'Reg_Hoejde',profile_kind:'numeric',n_rows:14805,n_available:0,pct_available:0,mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'needs_validation_negative_sentinel',summary_method:'supplied_mean_and_quantiles',summary_scope:'stored_source_row_profile'}];
 const t=readable('column_profiles',rows),h=navigation('?table=column_profiles',[t]);h.answer(rows);await flush();const output=h.el('rows').innerHTML;
 for(const text of ['SP_PatientInfo','height_in_cm','41390','58216','172','165','179','Reg_Hoejde','invalid stored values','sample of source records'])assert.ok(output.includes(text),text);
 assert.match(output,/0/);assert.match(output,/data-label=/);assert.doesNotMatch(output,/>Missing</);
 h.el('exact-columns').fire('click');assert.match(h.el('rows').innerHTML,/summary_method/);assert.equal(h.scripts.length,1,'changing presentation never starts another scan');
});

test('unknown code search explains absence of supplied meaning without judging code validity',async()=>{
 const rows=[{code:'NPU01960',label:'Erythrocytes',system:'Blood',unit:'x 1012/L',definition:'Supplied definition'}],t=readable('npu_display_dictionary',rows,{kind:'reference_definitions'}),h=navigation('?table=npu_display_dictionary&search=UNKNOWN',[t]);
 h.answer(rows);await flush();assert.match(h.el('read-status').textContent,/No matching.*definition/i);assert.match(h.el('read-status').textContent,/export/i);assert.doesNotMatch(h.el('read-status').textContent,/invalid code/i);
});

const visibleText=html=>html.replace(/<[^>]*>/g,' ');
test('reading numbers use useful precision while exact values and numeric zero remain accessible',async()=>{
 const rows=[{table_name:'SP',column_name:'height_in_cm',profile_kind:'numeric',n_rows:58216,n_available:41390,pct_available:71.0972928404562,mean:171.78538294274,median:0,p25:0.00003123,p75:179,numeric_privacy_status:'eligible_stored_summary',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample',summary_scope:'stored_source_row_profile'}];
 const t=readable('column_profiles',rows),h=navigation('?table=column_profiles',[t]);h.answer(rows);await flush();const html=h.el('rows').innerHTML,text=visibleText(html);
 for(const expected of ['41,390','58,216','71.1%','171.79','0.0000312'])assert.ok(text.includes(expected),expected);
 assert.match(text,/Median:.*0/);assert.doesNotMatch(text,/Stored summary available|Supplied mean and quantiles/);assert.match(text,/sample of source records/);assert.match(html,/171\.78538294274/);
 h.el('exact-columns').fire('click');assert.match(visibleText(h.el('rows').innerHTML),/171\.78538294274/);
});

test('eligible but absent summaries stay absent and categorical rows do not inherit numeric method prose',async()=>{
 const rows=[{table_name:'SP',column_name:'numeric_zero',profile_kind:'numeric',mean:0,median:0,p25:0,p75:0,numeric_privacy_status:'eligible_stored_summary',summary_method:'supplied_mean_and_quantiles',summary_scope:'stored_source_row_profile'},
 {table_name:'SP',column_name:'absent',profile_kind:'numeric',mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'eligible_stored_summary',summary_method:'supplied_mean_and_quantiles',summary_scope:'stored_source_row_profile'},
 {table_name:'CLL',column_name:'Weightloss',profile_kind:'categorical',mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'needs_validation_unreviewed_field',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample',summary_scope:'stored_source_row_profile'}];
 const t=readable('column_profiles',rows),h=navigation('?table=column_profiles',[t]);h.answer(rows);await flush();const text=visibleText(h.el('rows').innerHTML);
 assert.match(text,/No stored numeric summary supplied/);assert.doesNotMatch(text,/Stored summary available|Supplied mean and quantiles|sample of source records/);assert.match(text,/field needs review/);assert.match(text,/Median:.*0/);
});

test('regional coverage attaches the repeated domain total qualification to every count',async()=>{
 const rows=[{region_code:'A',region_name:'Region A',domain:'RKKP',coverage_status:'observed',n_rows:49750,basis:'observed_region_counts'},{region_code:'B',region_name:'Region B',domain:'RKKP',coverage_status:'observed',n_rows:49750,basis:'observed_region_counts'}];
 const t=readable('atlas_spatial_region_coverage',rows),h=navigation('?table=atlas_spatial_region_coverage',[t]);h.answer(rows);await flush();const text=visibleText(h.el('rows').innerHTML);
 assert.equal((text.match(/49,750/g)||[]).length,2);assert.equal((text.match(/not a regional count/gi)||[]).length,2);assert.equal((text.match(/do not sum across regions/gi)||[]).length,2);assert.match(text,/Domain source records/);
});

test('regional shares retain percent units and distinct supported or unknown denominators',async()=>{
 const rows=[{table_name:'S',region_column:'region_field',region_code:'1',region_name:'A',n_rows:12000,pct_rows:71.234,count_basis:'region_column_counts'},
 {table_name:'R',region_column:'Region',region_code:'2',region_name:'B',n_rows:500,pct_rows:25,count_basis:'registry_region_panel'},
 {table_name:'U',region_column:'unknown_field',region_code:'3',region_name:'C',n_rows:0,pct_rows:0,count_basis:'future_basis'}];
 const t=readable('atlas_spatial_region_counts',rows);t.columns.find(c=>c.key==='n_rows').label='Grouped source records';
 const h=navigation('?table=atlas_spatial_region_counts',[t]);h.answer(rows);await flush();const text=visibleText(h.el('rows').innerHTML);
 for(const expected of ['Grouped source records','12,000','71.2%','25.0%','all source records','retained normalized registry-region counts','missing, unmapped or suppressed','future_basis','denominator is not supplied'])assert.ok(text.includes(expected),expected);
 assert.doesNotMatch(text,/pct rows:/i);
});

test('year and date-availability shares state their supplied record denominators and units',async()=>{
 for(const [id,row,expected] of [
 ['atlas_temporal_coverage_years',{table_name:'S',date_column:'contact_date',year:2020,n_rows:12345,pct_rows:23.456,coverage_basis:'event_date_counts'},['2020','12,345','23.5%','all source records','missing, unparseable or out-of-window']],
 ['atlas_temporal_coverage',{table_name:'S',date_column:'date_field',n_rows:12000,pct_available:0},['0.0%','profiled source records','nonmissing','date validity']]
 ]){const t=readable(id,[row]),h=navigation('?table='+id,[t]);h.answer([row]);await flush();const text=visibleText(h.el('rows').innerHTML);for(const value of expected)assert.ok(text.includes(value),id+': '+value);assert.doesNotMatch(text,/2,020/);}
});
