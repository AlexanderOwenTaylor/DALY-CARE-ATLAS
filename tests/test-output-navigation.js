const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const templates=path.join(__dirname,'../inst/templates');

// The full shipped runtime runs against a small DOM/history and script-loading boundary.
function navigation(search='',suppliedTables,catalogueMetadata={}) {
  const html=fs.readFileSync(path.join(templates,'DALYCARE_outputs.html'),'utf8');
  const elements=new Map(),listeners={},scrolls=[],focuses=[],scripts=[];
  let window,document;
  function element(id,attrs='') {
    const handlers={};let hidden=/\bhidden\b/.test(attrs),markup='',cards=[];
    return {id,value:'',textContent:'',disabled:false,checked:false,dataset:{},children:[],parentNode:null,open:/\bopen\b/.test(attrs),tagName:'',tabIndex:/tabindex="(-?\d+)"/.test(attrs)?Number(RegExp.$1):undefined,
      get hidden(){return hidden;},set hidden(value){hidden=value;if(id==='library'&&value)window.scrollY=Math.min(window.scrollY,160);},
      get innerHTML(){return markup;},set innerHTML(value){markup=value;cards=[...value.matchAll(/<button[^>]*data-table="([^"]+)"/g)].map(match=>Object.assign(element('card-'+match[1]),{dataset:{table:match[1]}}));},
      addEventListener(name,fn){handlers[name]=fn;},fire(name){handlers[name]?.({preventDefault(){}});},
      appendChild(node){if(node.parentNode)node.parentNode.children.splice(node.parentNode.children.indexOf(node),1);this.children.push(node);node.parentNode=this;return node;},
      querySelectorAll(){return cards;},setAttribute(name,value){this[name]=value;},
      focus(options){document.activeElement=this;focuses.push({element:this,options});if(!options?.preventScroll)window.scrollY=80;}
    };
  }
  const stack=[];
  for(const match of html.matchAll(/<\/?([a-z][\w-]*)\b[^>]*>/gi)){
    const tag=match[1].toLowerCase();if(match[0].startsWith('</')){if(stack.at(-1)?.tagName===tag)stack.pop();continue;}
    const name=match[0].match(/\bid="([^"]+)"/)?.[1],node=element(name||'',match[0]);node.tagName=tag;if(name)elements.set(name,node);stack.at(-1)?.appendChild(node);
    if(!['meta','link','input','br','hr','img'].includes(tag))stack.push(node);
  }
  const el=id=>elements.get(id);
  document={getElementById:el,activeElement:null,body:{classList:{toggle(){}}},documentElement:{dataset:{}},createElement:()=>({remove(){}}),head:{appendChild(s){scripts.push(s);}}};
  const tables=suppliedTables||Array.from({length:147},(_,i)=>({id:'t'+i,title:'Table '+i,group:'Evidence',status:'metadata_only',columns:[],shards:[]}));
  const entries=[{search,state:null}],copy=value=>JSON.parse(JSON.stringify(value));let index=0;
  const history={scrollRestoration:'auto',get state(){return entries[index].state;},get length(){return entries.length;},
    replaceState(state,_title,url){entries[index]={state:copy(state),search:new URL(url,'https://atlas.test/').search};window.location.search=entries[index].search;},
    pushState(state,_title,url){entries.splice(++index);entries.push({state:copy(state),search:new URL(url,'https://atlas.test/').search});window.location.search=entries[index].search;},
    go(delta){index+=delta;window.location.search=entries[index].search;listeners.popstate({state:this.state});if(this.scrollRestoration==='auto')window.scrollY=160;}
  };
  window={DALYCARE_OUTPUT_CATALOGUE:{schema_version:1,build_id:'b1',tables,...catalogueMetadata},location:{search},history,scrollX:0,scrollY:0,
    scrollTo(options){scrolls.push({...options});this.scrollX=options.left;this.scrollY=options.top;},addEventListener(name,fn){listeners[name]=fn;}};
  const vitalModule=path.join(templates,'atlas-vitals.js');
  if(fs.existsSync(vitalModule))vm.runInNewContext(fs.readFileSync(vitalModule,'utf8'),{window,URLSearchParams});
  vm.runInNewContext(fs.readFileSync(path.join(templates,'atlas-outputs.js'),'utf8'),{window,document,URLSearchParams,TextEncoder,AbortController,setTimeout:()=>1,clearTimeout(){}});
  const card=id=>el('table-list').querySelectorAll('[data-table]').find(button=>button.dataset.table===id);
  return {window,document,el,card,scrolls,focuses,scripts,tables,
    visible(id){let node=el(id);if(!node)return false;for(;node;node=node.parentNode)if(node.hidden||node.tagName==='details'&&!node.open)return false;return true;},
    open(id,x=7,y=6200){window.scrollX=x;window.scrollY=y;card(id).focus({preventScroll:true});card(id).fire('click');},
    answer(rows){const script=scripts.at(-1),t=tables.find(t=>t.shards.some(s=>s.src===script.src)),s=t.shards.find(s=>s.src===script.src);document.currentScript=script;window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'b1',table_id:t.id,shard_id:s.id,rows_json:JSON.stringify(rows)});document.currentScript=null;}
  };
}

function readable(id,rows,metadata={}) {
 const json=JSON.stringify(rows);return {id,title:id,group:'Evidence',status:'available',kind:'aggregate_summary',complete:true,...metadata,columns:Object.keys(rows[0]).map(key=>({key,label:key,type:typeof rows.find(r=>r[key]!==null)?.[key]==='number'?'number':'string',definition:'Supplied meaning for '+key})),shards:[{id:'s1',src:'output-shards/'+id+'-s1.js',rows:rows.length,bytes:Buffer.byteLength(json)}]};
}
const flush=async()=>{for(let i=0;i<5;i++)await Promise.resolve();};

test('vital-sign searches answer with a reference guide without fabricating matching profile rows',async()=>{
 const rows=[{table_name:'SP_VitaleVaerdier',column_name:'displayname',n_rows:64124202,top_values:null,value_privacy_status:'protected_field'}],table=readable('column_profiles',rows);
 for(const query of ['', 'blood pressure','SpO2 %','temperature']){
  const h=navigation('?view=fields&table=column_profiles&source=SP_VitaleVaerdier&search='+encodeURIComponent(query),[table]);h.answer(rows);await flush();
  assert.ok(h.el('vital-guide'),'Visible measurement guide mount');assert.equal(h.el('vital-guide').hidden,false);
  assert.match(h.el('vital-guide').innerHTML,/Blood pressure/);assert.match(h.el('vital-guide').innerHTML,/SpO₂/);assert.match(h.el('vital-guide').innerHTML,/Temperature/);
  assert.doesNotMatch(h.el('vital-guide').innerHTML,/64,124,202|64124202/);
  if(query){assert.equal(h.el('rows').innerHTML,'');assert.match(h.el('read-status').textContent,/measurement guide/i);}
  assert.equal(h.scripts.length,1,'Guide does not load the clinical payload or extra shards');
 }
 for(const query of ['blood pressure','SpO2','temperature']){
  const h=navigation('?view=fields&table=column_profiles&searchmode=fields&search='+encodeURIComponent(query),[table]);h.answer(rows);await flush();
  assert.equal(h.el('vital-guide').hidden,false,'Unscoped field search must also discover the reference guide');
  assert.match(h.el('read-status').textContent,/measurement guide/i);
 }
 for(const source of ['SP_VitaleVaerdier_extra','SP_PatientInfo']){
  const h=navigation('?table=column_profiles&source='+source,[table]);h.answer(rows);await flush();assert.equal(h.el('vital-guide').hidden,true);
 }
});

test('catalogue labels reach nonregistry field readers and both label and raw-name searches',async()=>{
 for(const [source,field,label] of [['BIOBANK_SAMPLES','sampletype','Sample type'],['microbiology_culture_resistance','interpretation','Susceptibility interpretation'],['SDS_diagnoser','diagnosekode','Diagnosis code']]){
  const rows=[{table_name:source,column_name:field,n_rows:120}],metadata={field_labels:{[source]:{[field]:label}}},table=readable('column_profiles',rows);
  for(const query of ['',label,field]){
   const route=new URLSearchParams({table:table.id,source,field,search:query,searchmode:'fields'}),h=navigation('?'+route,[table],metadata);h.answer(rows);await flush();
    assert.equal(h.el('table-title').textContent,label);
    assert.ok(visibleText(h.el('field-identity').innerHTML).includes(field));
    assert.ok(visibleText(h.el('field-identity').innerHTML).includes(source));
    assert.match(h.el('read-status').textContent,/of 1 (matching|published) profile row/);
   assert.equal(h.scripts.length,1,'labels require only the selected output shard');
  }
 }
});

test('optional catalogue labels override registry fallback and missing exact pairs stay raw',async()=>{
 const rows=[{table_name:'RKKP_LYFO',column_name:'IPI'},{table_name:'RKKP_LYFO',column_name:'Reg_IPI'},{table_name:'SDS_t_udtilsgh',column_name:'c_udtilsgh'},{table_name:'RKKP_DaMyDa',column_name:'Stadie'}],table=readable('column_profiles',rows),h=navigation('?table=column_profiles',[table],{field_labels:{RKKP_LYFO:{IPI:'Reviewed index'}}});h.answer(rows);await flush();
 const html=h.el('rows').innerHTML;assert.match(html,/<strong>Reviewed index<\/strong>/);assert.match(html,/<strong>Reg_IPI<\/strong>/);assert.match(html,/<strong>c_udtilsgh<\/strong>/);assert.match(html,/<strong>Stadie<\/strong>/);assert.doesNotMatch(html,/International Prognostic|Recorded myeloma stage/);
 h.el('table-query').value='Recorded myeloma stage';h.el('search-table').fire('submit');await flush();assert.equal(h.el('rows').innerHTML,'');
});

test('catalogue label searches keep exact source and field scope without aliases or key normalization',async()=>{
 const rows=[{table_name:'S',column_name:'f'},{table_name:'SS',column_name:'f'},{table_name:'S',column_name:'ff'},{table_name:' s ',column_name:'f'},{table_name:'S',column_name:' F '}],table=readable('column_profiles',rows),metadata={field_labels:{S:{f:'Reviewed meaning',ff:'Reviewed meaning'},SS:{f:'Reviewed meaning'},' s ':{f:'Spaced source meaning'},'S ':{f:'Different exact source'}}};
  const scoped=navigation('?table=column_profiles&source=S&field=f&search=Reviewed%20meaning&searchmode=fields',[table],metadata);scoped.answer(rows);await flush();assert.match(scoped.el('read-status').textContent,/1 matching profile row/);assert.equal(scoped.el('table-title').textContent,'Reviewed meaning');
 const raw=navigation('?table=column_profiles',[table],metadata);raw.answer(rows);await flush();assert.match(raw.el('rows').innerHTML,/<strong>Spaced source meaning<\/strong>/);assert.match(raw.el('rows').innerHTML,/<strong> F <\/strong>/);assert.doesNotMatch(raw.el('rows').innerHTML,/Different exact source/);
});

test('old catalogues retain exact registry fallback while inherited optional metadata is ignored',async()=>{
 const rows=[{table_name:'RKKP_LYFO',column_name:'IPI'},{table_name:'RKKP_LYFO',column_name:'Reg_IPI'}],table=readable('column_profiles',rows),h=navigation('?table=column_profiles',[table]);
 Object.setPrototypeOf(h.window.DALYCARE_OUTPUT_CATALOGUE,{field_labels:{RKKP_LYFO:{IPI:'Inherited replacement'}}});h.answer(rows);await flush();assert.match(h.el('rows').innerHTML,/International Prognostic Index \(IPI\)/);assert.match(h.el('rows').innerHTML,/<strong>Reg_IPI<\/strong>/);assert.doesNotMatch(h.el('rows').innerHTML,/Inherited replacement/);
});

test('malformed optional labels leave raw fields readable without rendering objects or enabling fallback',async()=>{
 const rows=[{table_name:'RKKP_LYFO',column_name:'IPI'}],table=readable('column_profiles',rows);
 for(const map of [null,undefined,[],42,'bad',{RKKP_LYFO:null},{RKKP_LYFO:[]},{RKKP_LYFO:'bad'},{RKKP_LYFO:{IPI:{label:'bad'}}},{RKKP_LYFO:{IPI:42}},{RKKP_LYFO:{IPI:''}},{RKKP_LYFO:{IPI:' \t '}}]){
  const h=navigation('?table=column_profiles',[table],{field_labels:map});h.answer(rows);await flush();assert.match(h.el('rows').innerHTML,/<strong>IPI<\/strong>/);assert.doesNotMatch(h.el('rows').innerHTML,/International Prognostic|\[object Object\]/);assert.doesNotMatch(h.el('read-status').textContent,/incomplete/i);
 }
});

test('label reader ignores inherited source and field entries and prototype-related own keys',async()=>{
 const rows=[{table_name:'InheritedSource',column_name:'f'},{table_name:'S',column_name:'inheritedField'},{table_name:'S',column_name:'f'},{table_name:'constructor',column_name:'f'},{table_name:'__proto__',column_name:'f'},{table_name:'prototype',column_name:'f'},{table_name:'S',column_name:'constructor'},{table_name:'S',column_name:'__proto__'},{table_name:'S',column_name:'prototype'}],table=readable('column_profiles',rows);
 const labels=JSON.parse('{"S":{"f":"Own reviewed label","constructor":"Unsafe field label","__proto__":"Unsafe field label","prototype":"Unsafe field label"},"constructor":{"f":"Unsafe source label"},"__proto__":{"f":"Unsafe source label"},"prototype":{"f":"Unsafe source label"}}');
 Object.setPrototypeOf(labels,{InheritedSource:{f:'Inherited source label'}});Object.setPrototypeOf(labels.S,{inheritedField:'Inherited field label'});
 const h=navigation('?table=column_profiles',[table],{field_labels:labels});h.answer(rows);await flush();assert.match(h.el('rows').innerHTML,/<strong>Own reviewed label<\/strong>/);assert.doesNotMatch(h.el('rows').innerHTML,/Inherited source label|Inherited field label|Unsafe source label|Unsafe field label/);
 for(const query of ['Inherited source label','Inherited field label','Unsafe source label','Unsafe field label']){h.el('table-query').value=query;h.el('search-table').fire('submit');await flush();assert.equal(h.el('rows').innerHTML,'');}
});

test('empty metadata identities are ignored while valid exact entries remain available',async()=>{
 const rows=[{table_name:'',column_name:'f'},{table_name:' ',column_name:'f'},{table_name:'S',column_name:''},{table_name:'S',column_name:' '},{table_name:'S',column_name:'valid'},{table_name:'S',column_name:'bad'}],table=readable('column_profiles',rows),h=navigation('?table=column_profiles',[table],{field_labels:{'':{f:'Invalid empty source'},' ':{f:'Invalid blank source'},S:{'':'Invalid empty field',' ':'Invalid blank field',valid:'  Reviewed exact label  ',bad:{label:'Invalid object'}}}});h.answer(rows);await flush();
 assert.doesNotMatch(h.el('rows').innerHTML,/Invalid empty|Invalid blank|Invalid object|\[object Object\]/);assert.match(h.el('rows').innerHTML,/<strong>  Reviewed exact label  <\/strong>/);assert.match(h.el('rows').innerHTML,/<strong>bad<\/strong>/);
});

test('HTML-like reviewed labels are escaped in readable rows and remain searchable as text',async()=>{
 const label='<img src=x onerror="bad"> & \'reviewed\'',rows=[{table_name:'S',column_name:'raw_field'}],table=readable('columns',rows),h=navigation('?table=columns&search='+encodeURIComponent(label)+'&searchmode=fields',[table],{field_labels:{S:{raw_field:label}}});h.answer(rows);await flush();const html=h.el('rows').innerHTML;
 assert.match(html,/<strong>&lt;img src=x onerror=&quot;bad&quot;&gt; &amp; &#39;reviewed&#39;<\/strong>/);assert.doesNotMatch(html,/<img/);assert.match(html,/raw_field/);assert.match(h.el('read-status').textContent,/1 matching rows/);
});

test('reviewed display preserves typed raw evidence, units and withheld values in both reader modes',async()=>{
 const row={table_name:'S',source_column:'resultvalue',unit:'mmol/L',n_available:0,pct_available:0,median:null,numeric_privacy_status:'needs_validation_negative_sentinel'},rows=[row],table=readable('damyda_numeric_fields',rows);table.columns.find(c=>c.key==='median').type='number';const h=navigation('?table=damyda_numeric_fields',[table],{field_labels:{S:{resultvalue:'Recorded result'}}});h.answer(rows);await flush();
 assert.match(h.el('rows').innerHTML,/<strong>Recorded result<\/strong>/);for(const value of ['resultvalue','mmol/L','0.0%','<code>S</code>'])assert.ok(h.el('rows').innerHTML.includes(value),value);assert.match(h.el('table-result').textContent,/invalid stored values/);
 const scanned=await h.window.DALYCARE_OUTPUTS.scanTable(table.id,'Recorded result',0,null,null,{source:'S',field:'resultvalue',fieldNames:true});assert.deepEqual(JSON.parse(JSON.stringify(scanned.rows)),rows);
 h.el('exact-columns').fire('click');for(const value of ['resultvalue','mmol/L','invalid stored values'])assert.ok(h.el('rows').innerHTML.includes(value),value);assert.doesNotMatch(h.el('rows').innerHTML,/Recorded result/);
});

test('reference rows are never field-label aliases',async()=>{
 const rows=[{kind:'code',system:'S',code:'raw_code',label:'Supplied code meaning',table_name:'S',column_name:'raw_field'}],table=readable('clinical_display_dictionary',rows,{kind:'reference_definitions'}),h=navigation('?table=clinical_display_dictionary&search=Field%20only%20meaning',[table],{field_labels:{S:{raw_field:'Field only meaning'}}});h.answer(rows);await flush();assert.equal(h.el('rows').innerHTML,'');
 h.el('table-query').value='Supplied code meaning';h.el('search-table').fire('submit');await flush();assert.match(h.el('rows').innerHTML,/Supplied code meaning/);assert.doesNotMatch(h.el('rows').innerHTML,/Field only meaning/);
});

const sourceFixture=()=>({sources:[{table_name:'RKKP_DaMyDa',n_rows:14805,n_cols:352},{table_name:'RKKP_CLL',n_rows:7884,n_cols:80}],atlas_temporal_coverage:[{table_name:'RKKP_DaMyDa',date_column:'Diagnosedato',pct_available:100},{table_name:'RKKP_CLL',date_column:'Reg_Diagnose_dt',pct_available:100}],atlas_temporal_coverage_years:[{table_name:'RKKP_DaMyDa',date_column:'Diagnosedato',coverage_basis:'event_date_counts',year:2024,n_rows:491,pct_rows:3.31644714623438}],atlas_spatial_region_counts:[{table_name:'RKKP_DaMyDa',region_column:'Region',count_basis:'region_column_counts',region_name:'Other/unknown',region_code:'UNK',n_rows:11,pct_rows:0.0742992232353935}]});
async function answerWorkspace(h,data){for(let i=0;i<8;i++){await flush();const script=h.scripts.at(-1);if(!script||script.answered)break;script.answered=true;const t=h.tables.find(t=>t.shards.some(s=>s.src===script.src));h.answer(data[t.id]);}await flush();}
function synopsis(h){assert.ok(h.el('coverage-synopsis'),'A stable peer answer must precede source controls');return h.el('coverage-synopsis').innerHTML;}
const coverageMarkup=h=>synopsis(h)+h.el('coverage-answer').innerHTML;
test('exact coverage arrival gives peer answers before a long series and keeps supporting facts secondary',async()=>{
 const data=sourceFixture();data.atlas_temporal_coverage_years=Array.from({length:27},(_,i)=>({table_name:'RKKP_CLL',date_column:'Reg_Diagnose_dt',coverage_basis:'event_date_counts',year:2001+i,n_rows:100+i}));
 const h=navigation('?view=timeplace&source=RKKP_CLL',Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);
 const answer=synopsis(h);assert.match(answer,/Annual evidence/);assert.match(answer,/Regional evidence/);assert.match(answer,/Reg_Diagnose_dt/);assert.match(answer,/No regional summary is published/);assert.doesNotMatch(answer,/<table|7,884|100\.0%|Diagnosedato/);
 const children=h.el('coverage-workspace').children;assert.ok(children.indexOf(h.el('coverage-synopsis'))<children.indexOf(h.el('coverage-tools')));assert.ok(children.indexOf(h.el('coverage-tools'))<children.indexOf(h.el('coverage-answer')));
 assert.equal(h.el('coverage-tools').open,false);assert.match(h.el('coverage-answer').innerHTML,/<details id="coverage-facts"/);assert.match(h.el('coverage-answer').innerHTML,/7,884/);
 assert.equal((h.el('coverage-answer').innerHTML.match(/<tr><th scope="row">/g)||[]).length,27);assert.doesNotMatch(h.el('coverage-answer').innerHTML,/No regional summary is published/);
});
test('coverage synopsis preserves exact groups, publication markers and all original exceptional count rows',async()=>{
 const data=sourceFixture(),year={...data.atlas_temporal_coverage_years[0],count_privacy_status:null,value_privacy_status:null,availability_privacy_status:null};data.atlas_temporal_coverage_years=[{...year,year:2027,n_rows:0},{...year,year:2027,n_rows:99},{...year,year:2025,n_rows:null},{...year,year:2023,n_rows:987654,count_privacy_status:'withheld_small_cells'},{...year,date_column:'B',coverage_basis:'future_basis',year:2022,n_rows:44,value_privacy_status:'protected_field',availability_privacy_status:'withheld_small_complementary_cells'},{...year,date_column:'C',coverage_basis:'source_date_range',year:1901,n_rows:999999}];data.atlas_spatial_region_counts.push({...data.atlas_spatial_region_counts[0],n_rows:22},{...data.atlas_spatial_region_counts[0],region_column:'OtherField',count_basis:'registry_region_panel',n_rows:33});
 const h=navigation('?view=timeplace&source=RKKP_DaMyDa',Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);assert.equal(h.el('coverage-status').textContent,'');
 const answer=synopsis(h),details=visibleText(h.el('coverage-answer').innerHTML);assert.equal((answer.match(/class="coverage-summary-group"/g)||[]).length,5);
 for(const field of ['Diagnosedato','B','C','Region','OtherField'])assert.ok(answer.includes('data-coverage-field="'+field+'"'));
 assert.match(answer,/future_basis|Source range withheld/);assert.match(answer,/Withheld: protected field/);assert.match(answer,/small groups and related counts/);assert.match(answer,/row-specific/);
 for(const value of ['2027','0','99','Missing','Count withheld','44','Duplicate evidence','registry'])assert.ok(details.includes(value),value);
 assert.doesNotMatch(details,/987,654|999,999|1901|2026/);
 const urls=[...answer.matchAll(/href="([^"]+)"/g)].map(m=>new URL(m[1].replaceAll('&amp;','&'),'https://atlas.test/'));
 assert.ok(urls.some(u=>u.searchParams.get('source')==='RKKP_DaMyDa'&&u.searchParams.get('field')==='OtherField'));
});
test('coverage absence distinguishes completed, limited and unavailable exports without claiming missing source data',async()=>{
 for(const [metadata,expected] of [[{},/No annual summary is published/],[{complete:false,status:'limited'},/scope is limited or unknown/],[{status:'withheld',shards:[]},/Privacy withheld/],[{status:'not_produced',shards:[]},/Not in this export/]]){
  const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows,id==='atlas_temporal_coverage_years'?metadata:{})),h=navigation('?view=timeplace&source=RKKP_CLL',tables);await answerWorkspace(h,data);assert.match(synopsis(h),expected);assert.doesNotMatch(synopsis(h),/No records|0 records/);
 }
 const partial=sourceFixture(),limited=navigation('?view=timeplace&source=RKKP_DaMyDa',Object.entries(partial).map(([id,rows])=>readable(id,rows,id==='atlas_temporal_coverage_years'?{complete:false,status:'limited'}:{})));await answerWorkspace(limited,partial);assert.match(synopsis(limited),/Published scope is limited or unknown/);assert.match(limited.el('coverage-answer').innerHTML,/491/);
 const data=sourceFixture(),h=navigation('?view=timeplace&source=UNKNOWN',Object.entries(data).map(([id,rows])=>readable(id,rows,id==='sources'?{complete:false}:{})));await answerWorkspace(h,data);assert.match(synopsis(h),/UNKNOWN/);assert.match(synopsis(h),/inventory.*limited or unknown/i);assert.equal(h.el('coverage-answer').innerHTML,'');assert.equal(h.el('coverage-tools').open,true);
});
test('coverage tools stay open and focused through typing and selection without toggle side effects',async()=>{
 const data=sourceFixture(),h=navigation('?view=timeplace&source=RKKP_DaMyDa',Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);synopsis(h);
 const tools=h.el('coverage-tools'),query=h.el('coverage-query'),select=h.el('coverage-source'),reads=h.scripts.length,history=h.window.history.length;
 tools.open=true;tools.fire('toggle');assert.equal(h.scripts.length,reads);assert.equal(h.window.history.length,history);query.focus();query.value='CLL';query.fire('input');assert.equal(tools.open,true);assert.equal(h.document.activeElement,query);assert.match(synopsis(h),/RKKP_CLL/);
 query.value='no such source';query.fire('input');assert.equal(synopsis(h),'');assert.equal(h.el('coverage-answer').innerHTML,'');assert.equal(tools.open,true);
 query.value='';query.fire('input');select.focus();select.value='RKKP_CLL';select.fire('change');await flush();assert.equal(tools.open,true);assert.equal(h.document.activeElement,select);assert.equal(h.el('coverage-source'),select);assert.match(synopsis(h),/RKKP_CLL/);
});
test('coverage snapshots appear only after complete reading and cancellation or failure clears both mounts',async()=>{
 for(const action of ['cancel','error']){
  const data=sourceFixture(),h=navigation('?view=timeplace&source=RKKP_DaMyDa',Object.entries(data).map(([id,rows])=>readable(id,rows)));assert.equal(synopsis(h),'');h.el('coverage-tools').open=true;h.answer(data.sources);await flush();assert.equal(synopsis(h),'');assert.equal(h.el('coverage-tools').open,true);
  for(const id of ['coverage-status','coverage-cancel','coverage-retry']){let parent=h.el(id).parentNode;while(parent){assert.notEqual(parent,h.el('coverage-tools'));parent=parent.parentNode;}}
  h.el('coverage-synopsis').innerHTML='stale';h.el('coverage-answer').innerHTML='stale';if(action==='cancel')h.el('coverage-cancel').fire('click');else h.scripts.at(-1).onerror();await flush();assert.equal(synopsis(h),'');assert.equal(h.el('coverage-answer').innerHTML,'');assert.equal(h.el('coverage-retry').hidden,false);assert.match(h.el('coverage-status').textContent,/incomplete/);
  h.el('coverage-retry').fire('click');await answerWorkspace(h,data);assert.match(synopsis(h),/RKKP_DaMyDa/);assert.equal(h.el('coverage-tools').open,true);
 }
});
test('coverage return focuses its stable visible heading even before summaries finish reading',async()=>{
 const data=sourceFixture(),h=navigation('?view=timeplace&table=atlas_temporal_coverage_years&source=RKKP_DaMyDa&returnsource=RKKP_DaMyDa',Object.entries(data).map(([id,rows])=>readable(id,rows)));h.answer(data.atlas_temporal_coverage_years);await flush();h.el('back-library').fire('click');
 assert.ok(h.el('coverage-title'));assert.equal(h.document.activeElement,h.el('coverage-title'));assert.equal(h.visible('coverage-title'),true);assert.equal(h.el('coverage-tools').open,false);await answerWorkspace(h,data);assert.equal(h.document.activeElement,h.el('coverage-title'));assert.match(synopsis(h),/RKKP_DaMyDa/);
 for(const route of ['?view=timeplace','?view=timeplace&findsource=CLL']){const generic=navigation(route,Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(generic,data);assert.equal(generic.el('coverage-tools').open,true);if(route==='?view=timeplace')assert.match(synopsis(generic),/Example source/);}
});
test('coverage workspace composes only the selected source and preserves field evidence routes',async()=>{
 const data=sourceFixture(),h=navigation('?view=timeplace&source=RKKP_DaMyDa',[...Object.entries(data).map(([id,rows])=>readable(id,rows)),readable('column_profiles',[{table_name:'RKKP_DaMyDa',column_name:'Diagnosedato'}])]);
 assert.equal(h.scripts.length,1,'coverage starts a bounded source read');await answerWorkspace(h,data);const html=h.el('coverage-answer').innerHTML,text=visibleText(html);
 for(const value of ['14,805','Diagnosedato','100.0%','2024','491','Other/unknown','11'])assert.ok(text.includes(value),value);
 assert.doesNotMatch(text,/7,884|Missing/);assert.match(html,/table=atlas_temporal_coverage_years.*source=RKKP_DaMyDa/);assert.match(html,/table=column_profiles.*source=RKKP_DaMyDa/);
 assert.ok(h.scripts.every(s=>Object.keys(data).some(id=>s.src.includes(id+'-'))));
 h.el('coverage-source').value='RKKP_CLL';h.el('coverage-source').fire('change');await answerWorkspace(h,data);
 const cll=visibleText(coverageMarkup(h));assert.match(cll,/7,884/);assert.match(cll,/Reg_Diagnose_dt/);assert.match(cll,/No annual summary is published/);assert.doesNotMatch(cll,/491|Diagnosedato/);assert.equal(new URLSearchParams(h.window.location.search).get('source'),'RKKP_CLL');
 h.window.history.go(-1);await answerWorkspace(h,data);assert.match(visibleText(h.el('coverage-answer').innerHTML),/14,805/);
});
test('default field search submits directly to published rows without changing intent to metadata',()=>{
 const h=navigation('',[readable('column_profiles',[{table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll'}])]);h.el('metadata-query').value='creatinine';h.el('metadata-query').fire('input');assert.notEqual(new URLSearchParams(h.window.location.search).get('view'),'all');h.el('catalogue-search-form').fire('submit');assert.equal(new URLSearchParams(h.window.location.search).get('table'),'column_profiles');assert.equal(h.el('table-query').value,'creatinine');
});
test('coverage failed reads do not become absent-summary answers and can retry',async()=>{
 const data=sourceFixture(),h=navigation('?view=timeplace',Object.entries(data).map(([id,rows])=>readable(id,rows)));assert.equal(h.scripts.length,1);h.scripts[0].onerror();await flush();assert.equal(h.el('coverage-retry').hidden,false);assert.doesNotMatch(h.el('coverage-answer').innerHTML,/No annual summary/);h.el('coverage-retry').fire('click');assert.equal(h.scripts.length,2);
});
test('coverage preserves duplicate supplied counts, separates bases and withholds inferred ranges',async()=>{
 const data=sourceFixture();data.atlas_temporal_coverage_years.push({...data.atlas_temporal_coverage_years[0],n_rows:612},{...data.atlas_temporal_coverage_years[0],coverage_basis:'streamed_event_date_counts',n_rows:713},{...data.atlas_temporal_coverage_years[0],coverage_basis:'future_basis',n_rows:814},{...data.atlas_temporal_coverage_years[0],coverage_basis:'source_date_range',year:1901,n_rows:919191});
 const h=navigation('?view=timeplace',Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);const text=visibleText(h.el('coverage-answer').innerHTML);
 for(const value of ['491','612','713','814','Duplicate evidence','streamed','future_basis','range withheld'])assert.ok(text.includes(value),value);assert.doesNotMatch(text,/919,191|1901/);
});
test('source without a selected date field does not manufacture missing-date availability',async()=>{
 const data=sourceFixture();data.atlas_temporal_coverage[0]={table_name:'RKKP_DaMyDa',date_column:null,pct_available:null};const h=navigation('?view=timeplace',Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);const text=visibleText(h.el('coverage-answer').innerHTML);assert.match(text,/No date field identified/);assert.doesNotMatch(text,/nonmissing.*Missing|Exact date bounds are withheld/);
});
test('coverage collector rejects oversized overview before requesting any shard',async()=>{
 const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows));tables[0].shards=Array.from({length:9},(_,i)=>({id:'s'+i,src:'output-shards/sources-s'+i+'.js',rows:250,bytes:64000}));const h=navigation('?view=timeplace',tables);await flush();assert.equal(h.scripts.length,0);assert.match(h.el('coverage-status').textContent,/reading limit/);assert.equal(h.el('coverage-answer').innerHTML,'');
});
test('changing source while reading cancels old registration and paints only the new source',async()=>{
 const data=sourceFixture(),h=navigation('?view=timeplace&source=RKKP_DaMyDa',Object.entries(data).map(([id,rows])=>readable(id,rows)));h.answer(data.sources);await flush();const old=h.scripts.at(-1);h.el('coverage-source').value='RKKP_CLL';h.el('coverage-source').fire('change');await flush();h.document.currentScript=old;h.window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'b1',table_id:'atlas_temporal_coverage',shard_id:'s1',rows_json:JSON.stringify(data.atlas_temporal_coverage)});h.document.currentScript=null;await answerWorkspace(h,data);const text=visibleText(h.el('coverage-answer').innerHTML);assert.match(text,/7,884/);assert.doesNotMatch(text,/14,805|491/);
});
test('source discovery finds reviewed names and exact identifiers and refresh preserves field intent',async()=>{
 for(const [query,source] of [['myeloma','RKKP_DaMyDa'],['RKKP_CLL','RKKP_CLL']]){const data=sourceFixture(),h=navigation('?view=timeplace&q='+query,Object.entries(data).map(([id,rows])=>readable(id,rows)));await answerWorkspace(h,data);assert.equal(h.el('coverage-source').value,source);assert.match(h.el('coverage-answer').innerHTML,new RegExp(source));}
 const h=navigation('?view=fields&q=creatinine',[readable('column_profiles',[{table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll'}])]);h.el('catalogue-search-form').fire('submit');assert.equal(h.el('table-query').value,'creatinine');assert.equal(new URLSearchParams(h.window.location.search).get('table'),'column_profiles');
});
test('unavailable source inventory is an incomplete read rather than no matching sources',async()=>{
 const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows));tables[0].status='metadata_only';tables[0].shards=[];const h=navigation('?view=timeplace',tables);await answerWorkspace(h,data);assert.match(h.el('coverage-status').textContent,/inventory.*unavailable/i);assert.doesNotMatch(h.el('coverage-discovery').textContent,/No source names match/);assert.equal(h.el('coverage-answer').innerHTML,'');
});
test('coverage exact evidence routes scope date and region fields by equality',async()=>{
 for(const [id,key] of [['atlas_temporal_coverage_years','date_column'],['atlas_spatial_region_counts','region_column']]){const rows=[{table_name:'S',[key]:'A',n_rows:14},{table_name:'S',[key]:'AB',n_rows:25},{table_name:'SS',[key]:'A',n_rows:36}],h=navigation('?view=timeplace&table='+id+'&source=S&field=A',[readable(id,rows)]);h.answer(rows);await flush();assert.match(h.el('rows').innerHTML,/14/);assert.doesNotMatch(h.el('rows').innerHTML,/>25<|>36</);assert.match(h.el('row-scope-navigation').innerHTML,/view=timeplace.*source=S/);}
});
test('primary field search returns focus to its visible entry control',async()=>{
 const rows=[{table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll'}],h=navigation('',[readable('column_profiles',rows)]);h.el('metadata-query').value='creatinine';h.el('metadata-query').fire('input');h.el('catalogue-search-form').fire('submit');h.answer(rows);await flush();h.el('back-library').fire('click');assert.equal(h.document.activeElement,h.el('catalogue-search-submit'));
});
test('explicit source routes override conflicting discovery on refresh and history',async()=>{
 const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows));
 for(const query of ['findsource=myeloma','q=myeloma']){const h=navigation('?view=timeplace&source=RKKP_CLL&'+query,tables);await answerWorkspace(h,data);assert.equal(h.el('coverage-source').value,'RKKP_CLL');assert.match(h.el('coverage-answer').innerHTML,/7,884/);assert.equal(new URLSearchParams(h.window.location.search).get('source'),'RKKP_CLL');const refreshed=navigation(h.window.location.search,tables);await answerWorkspace(refreshed,data);assert.equal(refreshed.el('coverage-source').value,'RKKP_CLL');h.el('coverage-source').value='RKKP_DaMyDa';h.el('coverage-source').fire('change');h.window.history.go(-1);await flush();assert.equal(h.el('coverage-source').value,'RKKP_CLL');h.window.history.go(1);await flush();assert.equal(h.el('coverage-source').value,'RKKP_DaMyDa');}
});
test('unknown explicit source stays identified until the user deliberately discovers another',async()=>{
 const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows)),h=navigation('?view=timeplace&source=SOURCE_NOT_EXPORTED&findsource=myeloma',tables);await answerWorkspace(h,data);assert.equal(new URLSearchParams(h.window.location.search).get('source'),'SOURCE_NOT_EXPORTED');assert.match(synopsis(h),/SOURCE_NOT_EXPORTED/);assert.match(synopsis(h),/not present in this export/i);assert.doesNotMatch(coverageMarkup(h),/14,805/);const refreshed=navigation(h.window.location.search,tables);await answerWorkspace(refreshed,data);assert.match(synopsis(refreshed),/SOURCE_NOT_EXPORTED/);h.el('coverage-query').value='CLL';h.el('coverage-query').fire('input');assert.equal(h.el('coverage-source').value,'RKKP_CLL');assert.match(h.el('coverage-answer').innerHTML,/7,884/);
});
test('field-name search excludes source aliases and other cell values while generic search remains available',async()=>{
 const rows=[{table_name:'SP_AlleProvesvar',column_name:'unrelated_synthetic_field',note:'',n_rows:12},{table_name:'X',column_name:'hospital_department',note:'',n_rows:23},{table_name:'X',column_name:'other_field',note:'hospital',n_rows:34},{table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll',note:'',n_rows:45}],tables=[readable('column_profiles',rows)],h=navigation('?table=column_profiles&search=hospital&searchmode=fields',tables);h.answer(rows);await flush();assert.match(h.el('rows').innerHTML,/hospital_department/);assert.doesNotMatch(h.el('rows').innerHTML,/unrelated_synthetic_field|other_field/);assert.equal(h.el('table-search-mode').value,'fields');assert.match(h.el('table-query-label').textContent,/field names/i);
 h.el('table-search-mode').value='rows';h.el('table-search-mode').fire('change');await flush();assert.match(h.el('rows').innerHTML,/unrelated_synthetic_field|other_field/);h.window.history.go(-1);await flush();assert.doesNotMatch(h.el('rows').innerHTML,/unrelated_synthetic_field|other_field/);h.window.history.go(1);await flush();assert.match(h.el('rows').innerHTML,/other_field/);
 const refreshed=navigation('?table=column_profiles&search=34&searchmode=fields',tables);refreshed.answer(rows);await flush();assert.equal(refreshed.el('rows').innerHTML,'');assert.match(refreshed.el('read-status').textContent,/field names|reviewed labels/i);assert.doesNotMatch(refreshed.el('read-status').textContent,/exact source identifier/);h.el('table-search-mode').value='fields';h.el('table-search-mode').fire('change');h.el('table-query').value='creatinine';h.el('search-table').fire('submit');await flush();assert.match(h.el('rows').innerHTML,/Reg_Creatinin_mikmoll/);assert.equal(new URLSearchParams(h.window.location.search).get('searchmode'),'fields');
});
test('default field and hospital routes request field-name mode and global searches retain their return source',async()=>{
 const data=sourceFixture(),fields=[{table_name:'RKKP_DaMyDa',column_name:'Reg_Creatinin_mikmoll'}],tables=[...Object.entries(data).map(([id,rows])=>readable(id,rows)),readable('column_profiles',fields)],h=navigation('',tables);h.el('metadata-query').value='creatinine';h.el('catalogue-search-form').fire('submit');assert.equal(new URLSearchParams(h.window.location.search).get('searchmode'),'fields');h.answer(fields);await flush();
 const coverage=navigation('?view=timeplace&source=RKKP_CLL',tables);await answerWorkspace(coverage,data);const html=coverage.el('coverage-answer').innerHTML,href=html.match(/href="([^"]+)"[^>]*>Find hospital fields across sources/)[1].replaceAll('&amp;','&'),params=new URL(href,'https://atlas.test/').searchParams;assert.equal(params.get('searchmode'),'fields');assert.equal(params.get('source'),null);assert.equal(params.get('returnsource'),'RKKP_CLL');const target=navigation('?'+params.toString(),tables);target.answer(fields);await flush();assert.equal(target.el('row-scope').hidden,true);target.el('back-library').fire('click');await answerWorkspace(target,data);assert.equal(target.el('coverage-source').value,'RKKP_CLL');assert.match(target.el('coverage-answer').innerHTML,/7,884/);target.window.history.go(-1);await flush();assert.equal(new URLSearchParams(target.window.location.search).get('returnsource'),'RKKP_CLL');assert.equal(target.el('row-scope').hidden,true);
 const noOrigin=navigation('?view=timeplace&table=column_profiles&search=hospital&searchmode=fields',tables);assert.match(noOrigin.el('back-library').textContent,/Back to years and regions/);
});
test('field-name mode persists across whole-table paging and exact source scope',async()=>{
 const rows=[...Array.from({length:51},(_,i)=>({table_name:'S',column_name:'hospital_'+i,n_rows:i})),{table_name:'SS',column_name:'hospital_other_source',n_rows:999},{table_name:'S',column_name:'other_field',n_rows:51}],tables=[readable('column_profiles',rows)],h=navigation('?table=column_profiles&source=S&search=hospital&searchmode=fields',tables);h.answer(rows);await flush();assert.match(h.el('read-status').textContent,/51 matching/);assert.doesNotMatch(h.el('rows').innerHTML,/hospital_other_source/);h.el('next-page').fire('click');await flush();assert.match(h.el('rows').innerHTML,/hospital_50/);assert.doesNotMatch(h.el('rows').innerHTML,/hospital_49/);const params=new URLSearchParams(h.window.location.search);assert.equal(params.get('source'),'S');assert.equal(params.get('searchmode'),'fields');assert.equal(params.get('page'),'2');const refreshed=navigation(h.window.location.search,tables);refreshed.answer(rows);await flush();assert.match(refreshed.el('rows').innerHTML,/hospital_50/);assert.equal(refreshed.el('table-search-mode').value,'fields');h.window.history.go(-1);await flush();assert.match(h.el('rows').innerHTML,/hospital_49/);
});
test('live source discovery refreshes unscoped context links without repeated scoped field navigation',async()=>{
 const data=sourceFixture(),tables=Object.entries(data).map(([id,rows])=>readable(id,rows)),h=navigation('?view=timeplace&source=RKKP_DaMyDa',tables);await answerWorkspace(h,data);h.el('coverage-query').value='CLL';h.el('coverage-query').fire('input');assert.match(h.el('coverage-evidence-links').innerHTML,/returnsource=RKKP_CLL/);assert.doesNotMatch(h.el('coverage-evidence-links').innerHTML,/returnsource=RKKP_DaMyDa/);
 const rows=[{table_name:'S',column_name:'A'},{table_name:'S',column_name:'B'}],fields=navigation('?table=column_profiles&source=S',[readable('column_profiles',rows)]);fields.answer(rows);await flush();assert.match(fields.el('row-scope-navigation').innerHTML,/Years and regions/);assert.doesNotMatch(fields.el('rows').innerHTML,/Years and regions for this source/);
});

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

// A category profile is useful as a field list when its distributions are withheld.
// These cases fail if the reading view repeats protected categories or discards evidence.
const profileRow=(extra={})=>({table_name:'RKKP_DaMyDa',registry:'DaMyDa',source_column:'Stadie',label:null,n:null,pct_rows:null,availability_privacy_status:null,value_privacy_status:'withheld_unvalidated_distribution',...extra});
test('withheld category reading view collapses identical field context and exact view retains every row',async()=>{
 const rows=[profileRow(),profileRow(),profileRow({source_column:'Reg_Knogleforandringer'})],t=readable('damyda_clinical_profile',rows),h=navigation('?table=damyda_clinical_profile',[t,readable('column_profiles',[{table_name:'RKKP_DaMyDa',column_name:'Stadie'}])]);h.answer(rows);await flush();
 let text=visibleText(h.el('rows').innerHTML);
 assert.equal((text.match(/Recorded myeloma stage/g)||[]).length,1);assert.equal((text.match(/Bone changes/g)||[]).length,1);
 assert.equal((text.match(/RKKP_DaMyDa/g)||[]).length,1,'source is stated once for the field group');
 assert.equal((h.el('table-result').textContent.match(/withheld pending validation/gi)||[]).length,1,'one reason replaces repeated protected cells');assert.doesNotMatch(text,/withheld pending validation/i);
 assert.doesNotMatch(text,/Missing|48 categories|3 categories/i);assert.match(h.el('rows').innerHTML,/table=column_profiles&amp;source=RKKP_DaMyDa&amp;field=Stadie/);
 assert.equal(h.el('exact-columns').hidden,false);h.el('exact-columns').fire('click');
 assert.equal((h.el('rows').innerHTML.match(/<tr>/g)||[]).length,4);assert.match(h.el('rows').innerHTML,/source_column/);assert.equal(h.scripts.length,1);
 h.el('exact-columns').fire('click');assert.equal((visibleText(h.el('rows').innerHTML).match(/Recorded myeloma stage/g)||[]).length,1);assert.equal(h.scripts.length,1);
});

test('reading a category profile preserves extra privacy state, different sources, supplied zero and unexplained missingness',async()=>{
 const rows=[profileRow(),profileRow({availability_privacy_status:'withheld_small_complementary_cells'}),profileRow({table_name:'Unreviewed',registry:'Other'}),profileRow({label:'Known category',n:0,pct_rows:0,value_privacy_status:null}),profileRow({source_column:'No_reason',value_privacy_status:null}),profileRow({source_column:'New_reason',value_privacy_status:'future_guard'})];
 const t=readable('damyda_clinical_profile',rows);for(const c of t.columns)if(['n','pct_rows'].includes(c.key))c.type='number';const h=navigation('?table=damyda_clinical_profile',[t]);h.answer(rows);await flush();const text=visibleText(h.el('rows').innerHTML);
 assert.match(text,/small groups and related counts/);assert.match(text,/Unreviewed/);assert.match(text,/Known category/);assert.match(text,/0\.0%/);assert.match(text,/Missing/);assert.match(text,/future_guard/);
 assert.equal((text.match(/Recorded myeloma stage/g)||[]).length,3,'reviewed label applies only to its exact source');
 h.el('exact-columns').fire('click');assert.equal((h.el('rows').innerHTML.match(/<tr>/g)||[]).length,7);
});

test('English field searches match reviewed identities in category, profile and metadata tables while preserving exact-column search',async()=>{
 for(const id of ['damyda_clinical_profile','column_profiles','columns']){
  const category=id==='damyda_clinical_profile';
  const rows=category?[profileRow({source_column:'Reg_Knogleforandringer'}),profileRow({table_name:'Unreviewed',source_column:'Reg_Knogleforandringer'})]:[{table_name:'RKKP_DaMyDa',column_name:'Reg_Knogleforandringer',profile_kind:'categorical',n_available:0,n_rows:12,pct_available:0},{table_name:'Unreviewed',column_name:'Reg_Knogleforandringer',profile_kind:'categorical',n_available:0,n_rows:12,pct_available:0}];
  const t=readable(id,rows),h=navigation('?table='+id+'&search=bone%20changes',[t]);h.answer(rows);await flush();
  assert.match(visibleText(h.el('rows').innerHTML),/Bone changes/);assert.doesNotMatch(visibleText(h.el('rows').innerHTML),/Unreviewed/);assert.equal(h.scripts.length,1);
  h.el('table-query').value='Unreviewed';h.el('search-table').fire('submit');await flush();assert.match(visibleText(h.el('rows').innerHTML),/Unreviewed/);assert.doesNotMatch(visibleText(h.el('rows').innerHTML),/Bone changes/);assert.equal(h.scripts.length,1);
 }
});

test('category grouping is page-scoped when retained evidence spans more than one page',async()=>{
 const rows=Array.from({length:60},()=>profileRow()),t=readable('damyda_clinical_profile',rows),h=navigation('?table=damyda_clinical_profile',[t]);h.answer(rows);await flush();
 assert.match(h.el('read-status').textContent,/this page/i);assert.equal(h.el('next-page').disabled,false);assert.equal((visibleText(h.el('rows').innerHTML).match(/Recorded myeloma stage/g)||[]).length,1);
 h.el('next-page').fire('click');await flush();assert.equal(h.el('next-page').disabled,true);assert.equal(h.el('previous-page').disabled,false);assert.match(h.el('read-status').textContent,/this page/i);
 h.el('exact-columns').fire('click');assert.equal((h.el('rows').innerHTML.match(/<tr>/g)||[]).length,11);assert.match(h.el('read-status').textContent,/51–60 of 60/);
});

test('related availability routes match exact source and field, retain scope through history, and allow an explicit clear',async()=>{
 const rows=[{table_name:'RKKP_DaMyDa',column_name:'Stadie',profile_kind:'categorical',n_rows:14805,n_available:12901,pct_available:87.1394799},{table_name:'Other',column_name:'Stadie',profile_kind:'categorical',n_rows:20,n_available:19,pct_available:95},{table_name:'RKKP_DaMyDa',column_name:'Stadie_other',profile_kind:'categorical',n_rows:30,n_available:29,pct_available:96.6}];
 const t=readable('column_profiles',rows),h=navigation('?table=column_profiles&source=RKKP_DaMyDa&field=Stadie',[t]);h.answer(rows);await flush();
 const text=visibleText(h.el('rows').innerHTML);assert.match(text,/12,901/);assert.match(text,/14,805/);assert.doesNotMatch(text,/Other|Stadie_other/);
 assert.equal(h.el('row-scope').hidden,false);assert.match(h.el('row-scope-label').textContent,/RKKP_DaMyDa.*Stadie/);
 h.el('table-query').value='stage';h.el('search-table').fire('submit');await flush();assert.equal(new URLSearchParams(h.window.location.search).get('source'),'RKKP_DaMyDa');
 h.el('clear-row-scope').fire('click');await flush();assert.equal(h.el('row-scope').hidden,true);assert.equal(new URLSearchParams(h.window.location.search).has('source'),false);
 h.window.history.go(-1);await flush();assert.equal(h.el('row-scope').hidden,false);assert.match(visibleText(h.el('rows').innerHTML),/12,901/);
 h.el('back-library').fire('click');assert.equal(new URLSearchParams(h.window.location.search).has('source'),false);
});

test('an exact related field with no published availability row reports the scoped absence',async()=>{
 const rows=[{table_name:'Other',column_name:'Stadie',profile_kind:'categorical'}],t=readable('column_profiles',rows),h=navigation('?table=column_profiles&source=RKKP_DaMyDa&field=Stadie',[t]);h.answer(rows);await flush();
 assert.equal(h.el('rows').innerHTML,'');assert.match(h.el('read-status').textContent,/no.*published.*exact source.*field/i);assert.equal(h.el('row-scope').hidden,false);
});

test('numeric coverage shares one common summary limit while retaining reviewed names, units and exact evidence',async()=>{
 const rows=[{table_name:'RKKP_DaMyDa',field:'haemoglobin',source_column:'Reg_Haemoglobin',unit:'mmol/L',n_available:10,n_rows:12,pct_available:83.33,mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'needs_validation_unreviewed_field'},
 {table_name:'RKKP_DaMyDa',field:'creatinine',source_column:'Reg_Creatinin_mikmoll',unit:'µmol/L',n_available:0,n_rows:12,pct_available:0,mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'needs_validation_unreviewed_field'}];
 const t=readable('damyda_numeric_fields',rows),h=navigation('?table=damyda_numeric_fields',[t]);h.answer(rows);await flush();const text=visibleText(h.el('rows').innerHTML);
 assert.match(text,/Haemoglobin/);assert.match(text,/Creatinine/);assert.match(text,/mmol\/L/);assert.match(text,/0\.0%/);assert.doesNotMatch(text,/field needs review/);assert.match(h.el('table-result').textContent,/field needs review/i);
 assert.equal((text.match(/RKKP_DaMyDa/g)||[]).length,1);
 h.el('exact-columns').fire('click');assert.equal((h.el('rows').innerHTML.match(/<tr>/g)||[]).length,3);assert.match(visibleText(h.el('rows').innerHTML),/field needs review/);
});

test('numeric coverage keeps different summary reasons separate and never hides a supplied zero summary',async()=>{
 const rows=[{table_name:'RKKP_DaMyDa',source_column:'Reg_Haemoglobin',unit:'mmol/L',n_available:10,pct_available:50,median:null,numeric_privacy_status:'needs_validation_negative_sentinel'},{table_name:'RKKP_DaMyDa',source_column:'Reg_LDH',unit:'U/L',n_available:0,pct_available:0,median:null,numeric_privacy_status:'needs_validation_unreviewed_field'}];
 const t=readable('damyda_numeric_fields',rows);t.columns.find(c=>c.key==='median').type='number';const h=navigation('?table=damyda_numeric_fields',[t]);h.answer(rows);await flush();
 let text=visibleText(h.el('rows').innerHTML);assert.equal((text.match(/invalid stored values need review/g)||[]).length,1);assert.equal((text.match(/field needs review/g)||[]).length,1);
 rows[0].median=0;const fresh=readable('damyda_numeric_fields',rows),withZero=navigation('?table=damyda_numeric_fields',[fresh]);withZero.answer(rows);await flush();text=visibleText(withZero.el('rows').innerHTML);assert.match(text,/Median:.*0/);assert.match(text,/invalid stored values/);assert.equal(withZero.el('table-result').hidden,true);
});

test('shared availability suppression is one reason with an independent source total, while zero and missing remain distinct',async()=>{
 const base={table_name:'RKKP_DaMyDa',column_name:'Reg_Mkomponent',profile_kind:'categorical',n_rows:14805,n_available:null,pct_available:null,availability_privacy_status:'withheld_small_complementary_cells'};
 const cases=[{row:base,reason:/small groups and related counts/g},{row:{...base,availability_privacy_status:'withheld_unknown_support'},reason:/supporting count unknown/g},{row:{...base,n_available:0,pct_available:0},zero:true},{row:{...base,availability_privacy_status:null},missing:true}];
 for(const example of cases){const t=readable('column_profiles',[example.row]);for(const c of t.columns)if(['n_available','pct_available'].includes(c.key))c.type='number';const h=navigation('?table=column_profiles',[t]);h.answer([example.row]);await flush();const text=visibleText(h.el('rows').innerHTML);
  if(example.reason){assert.equal((text.match(example.reason)||[]).length,1);assert.match(text,/Source records:.*14,805/);assert.doesNotMatch(text,/Withheld:[^\n]*of\s+14,805/);}
  if(example.zero){assert.match(text,/With a value:.*0.*of.*14,805/);assert.match(text,/0\.0%/);assert.doesNotMatch(text,/Withheld/);}
  if(example.missing){assert.match(text,/Missing/);assert.doesNotMatch(text,/Withheld|0\.0%/);}
 }
});

test('rounded numeric coverage distinguishes a near-complete percentage from exactly 100 and retains exact values',async()=>{
 const base={table_name:'RKKP_DaMyDa',source_column:'Reg_Haemoglobin',unit:'mmol/L',n_available:14799,pct_available:99.9594731509625,median:null,numeric_privacy_status:'needs_validation_negative_sentinel'};
 const rows=[base,{...base,source_column:'Reg_LDH',pct_available:100}],t=readable('damyda_numeric_fields',rows),h=navigation('?table=damyda_numeric_fields',[t]);h.answer(rows);await flush();
 const html=h.el('rows').innerHTML,text=visibleText(html);assert.match(text,/rounded/i);assert.match(html,/&lt;100%/);assert.equal((text.match(/100\.0%/g)||[]).length,1);assert.match(html,/Exact supplied value: 99\.9594731509625/);
 h.el('exact-columns').fire('click');assert.match(visibleText(h.el('rows').innerHTML),/99\.9594731509625/);assert.doesNotMatch(h.el('rows').innerHTML,/&lt;100%/);
});

test('distinct registries in one exact source remain distinguishable in category group headings',async()=>{
 const rows=[profileRow({registry:'Registry A'}),profileRow({registry:'Registry B'})],t=readable('damyda_clinical_profile',rows),h=navigation('?table=damyda_clinical_profile',[t]);h.answer(rows);await flush();
 const headings=[...h.el('rows').innerHTML.matchAll(/<h3>(.*?)<\/h3>/g)].map(match=>visibleText(match[1]));assert.equal(headings.length,2);assert.match(headings[0],/RKKP_DaMyDa.*Registry A/);assert.match(headings[1],/RKKP_DaMyDa.*Registry B/);
});

test('category status hides only for an unqueried complete reading page and returns for exact, search, limited and failed reads',async()=>{
 const rows=[profileRow()],t=readable('damyda_clinical_profile',rows),h=navigation('?table=damyda_clinical_profile',[t]);h.answer(rows);await flush();assert.equal(h.el('read-status').hidden,true);assert.equal(h.el('table-state').hidden,true);
 h.el('exact-columns').fire('click');assert.equal(h.el('read-status').hidden,false);assert.equal(h.el('table-state').hidden,false);
 h.el('exact-columns').fire('click');h.el('table-query').value='stage';h.el('search-table').fire('submit');await flush();assert.equal(h.el('read-status').hidden,false);assert.equal(h.el('table-state').hidden,false);
 const limited=readable('damyda_clinical_profile',rows,{complete:false}),l=navigation('?table=damyda_clinical_profile',[limited]);l.answer(rows);await flush();assert.equal(l.el('read-status').hidden,false);assert.equal(l.el('table-state').hidden,false);
 const failed=navigation('?table=damyda_clinical_profile',[t]);failed.scripts[0].onerror();await flush();assert.equal(failed.el('read-status').hidden,false);assert.match(failed.el('read-status').textContent,/incomplete/i);
});

const fieldProfile=(extra={})=>({table_name:'S',column_name:'f',domain:null,subdomain:null,atlas_role:null,profile_kind:'numeric',n_rows:100,n_available:61,pct_available:60.5,n_missing:37,pct_missing:38.25,availability_privacy_status:null,mean:null,median:null,p25:null,p75:null,numeric_privacy_status:'needs_validation_unreviewed_field',summary_scope:null,summary_method:null,...extra});
const fieldRoute='?table=column_profiles&source=S&field=f';
const profileTable=(rows,extra={})=>{const t=readable('column_profiles',rows,extra);for(const c of t.columns)if(['n_rows','n_available','pct_available','n_missing','pct_missing','mean','median','p25','p75'].includes(c.key))c.type='number';return t;};
const fieldText=h=>visibleText(h.el('rows').innerHTML).replace(/\s+/g,' ').trim();
const params=h=>new URLSearchParams(h.window.location.search);

test('field arrival identifies the requested pair before reading and preserves independent supplied missingness',async()=>{
 const rows=[fieldProfile(),fieldProfile({table_name:'SS',n_available:999}),fieldProfile({column_name:'ff',n_available:888})],h=navigation(fieldRoute,[profileTable(rows)],{field_labels:{S:{f:'Reviewed field'}}});
 assert.equal(h.el('table-title').textContent,'Reviewed field');assert.match(visibleText(h.el('field-identity').innerHTML),/S.*f/);assert.equal(h.document.activeElement,h.el('table-title'));
 h.answer(rows);await flush();const text=fieldText(h);
 for(const value of ['61','100','60.5%','37','38.3%','Recorded availability','Stored summary','field needs review'])assert.ok(text.includes(value),value);
 assert.doesNotMatch(text,/999|888|39\.5%/);assert.match(h.el('read-status').textContent,/1 published profile row/);assert.equal(h.scripts.length,1);
 const scanned=await h.window.DALYCARE_OUTPUTS.scanTable('column_profiles','',0,null,null,{source:'S',field:'f'});assert.deepEqual(JSON.parse(JSON.stringify(scanned.rows)),[rows[0]]);
});

test('field arrival moves only optional controls and restores ordinary readers on scope clear and history',async()=>{
 const rows=[fieldProfile()],h=navigation(fieldRoute,[profileTable(rows)]);
 assert.equal(h.visible('cancel-search'),true);assert.equal(h.visible('read-status'),true);assert.equal(h.visible('table-query'),false);assert.equal(h.el('field-tools').open,false);
 h.answer(rows);await flush();assert.equal(h.el('table-purpose').hidden,true);assert.equal(h.el('table-state').hidden,true);
 h.el('field-tools').open=true;h.el('clear-row-scope').fire('click');await flush();assert.equal(h.el('table-title').textContent,'Field availability and summaries');assert.equal(h.el('table-purpose').hidden,false);assert.equal(h.visible('table-query'),true);assert.equal(h.el('field-tools').hidden,true);
 h.window.history.go(-1);await flush();assert.equal(h.el('table-title').textContent,'f');assert.equal(h.visible('table-query'),false);
 for(const [route,id] of [['?table=column_profiles&source=S','column_profiles'],['?table=column_profiles&field=f','column_profiles'],['?table=column_profiles','column_profiles'],['?table=columns&source=S&field=f','columns']]){
  const t=profileTable(rows);t.id=id;const ordinary=navigation(route,[t]);assert.equal(ordinary.el('field-tools').hidden,true);assert.equal(ordinary.visible('table-query'),true);assert.equal(ordinary.el('table-purpose').hidden,false);
 }
});

test('field arrival distinguishes zero, absent, protected and partially published availability without suppressing supplied complements',async()=>{
 const cases=[
  {row:fieldProfile({n_available:0,pct_available:0,n_missing:0,pct_missing:0}),yes:['With a value: 0','0.0%','Without a value: 0'],no:/Withheld/},
  {row:fieldProfile({n_available:null,pct_available:null,n_missing:null,pct_missing:null}),yes:['Recorded availability not supplied','100'],no:/Withheld|0\.0%/},
  {row:fieldProfile({n_available:null,pct_available:null,n_missing:null,pct_missing:null,availability_privacy_status:'withheld_small_complementary_cells'}),yes:['small groups and related counts','100'],no:/With a value: 0/},
  {row:fieldProfile({n_available:null,pct_available:null,availability_privacy_status:'withheld_unknown_support'}),yes:['supporting count unknown','Without a value: 37','38.3%'],no:/Without a value: 39/},
  {row:fieldProfile({n_available:null,pct_available:null,n_missing:null,pct_missing:null,availability_privacy_status:'future_guard'}),yes:['future_guard','not supplied'],no:/With a value: 0/}
 ];
 for(const {row,yes,no} of cases){const h=navigation(fieldRoute,[profileTable([row])]);h.answer([row]);await flush();for(const value of yes)assert.ok(fieldText(h).includes(value),value);assert.doesNotMatch(fieldText(h),no);}
});

test('field arrival retains partial zero summaries and metadata on categorical or all-null profiles',async()=>{
 const rows=[fieldProfile({median:0,p25:null,p75:7,numeric_privacy_status:'eligible_stored_summary',summary_scope:'future_scope',summary_method:'future_method'}),fieldProfile({profile_kind:'categorical',summary_scope:'stored_source_row_profile',summary_method:'supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample'}),fieldProfile({numeric_privacy_status:'future_reason'})],h=navigation(fieldRoute,[profileTable(rows)]);h.answer(rows);await flush();const text=fieldText(h);
 for(const value of ['Median: 0','75th percentile: 7','future_scope','future_method','Stored source rows','sample of source records','future_reason','Summary scope not supplied'])assert.ok(text.includes(value),value);
 assert.equal((text.match(/Recorded availability/g)||[]).length,3);assert.match(h.el('read-status').textContent,/3 published profile rows/);
});

test('field arrival retains duplicate profiles in source order across 50 and 2 row pages',async()=>{
 const rows=Array.from({length:52},(_,i)=>fieldProfile({atlas_role:i<2?'identical':'role_'+i,n_available:i<2?22:1000+i,summary_scope:i===2?'special_scope':null}));rows.push(fieldProfile({table_name:'SS',n_available:9999}));
 const h=navigation(fieldRoute,[profileTable(rows)]);h.answer(rows);await flush();let text=fieldText(h);assert.equal((text.match(/With a value: 22 /g)||[]).length,2);assert.match(text,/Profile row 1/);assert.match(text,/Profile row 50/);assert.match(text,/special_scope/);assert.doesNotMatch(text,/9999|role_50/);assert.match(h.el('read-status').textContent,/52 published profile rows/);
 h.el('next-page').fire('click');await flush();text=fieldText(h);assert.match(text,/Profile row 51/);assert.match(text,/Profile row 52/);assert.match(text,/role_50/);assert.doesNotMatch(text,/role_49/);assert.equal((text.match(/Recorded availability/g)||[]).length,2);assert.equal(params(h).get('page'),'2');
});

test('field arrival distinguishes query no-match from absent pair and clears search without losing exact context',async()=>{
 const rows=[fieldProfile()],table=profileTable(rows),route=fieldRoute+'&view=timeplace&returnsource=Other&search=not-found&searchmode=fields&columns=all&page=3',h=navigation(route,[table]);h.answer(rows);await flush();
 assert.match(h.el('read-status').textContent,/No published profiles match.*not-found/);assert.equal(h.el('field-tools').open,true);h.el('field-tools').open=false;assert.equal(h.visible('clear-field-search'),true);assert.match(h.el('field-filter-status').textContent,/not-found.*field names/i);
 h.el('clear-field-search').fire('click');await flush();for(const [key,value] of [['source','S'],['field','f'],['searchmode','fields'],['columns','all'],['returnsource','Other']])assert.equal(params(h).get(key),value);assert.equal(params(h).has('search'),false);assert.equal(params(h).has('page'),false);assert.match(h.el('read-status').textContent,/1 published profile row/);
 h.window.history.go(-1);await flush();assert.equal(h.el('table-query').value,'not-found');assert.match(h.el('read-status').textContent,/No published profiles match/);
 const absent=navigation(fieldRoute,[profileTable([fieldProfile({table_name:'SS'})])],{field_labels:{S:{f:'Label without evidence'}}});absent.answer([fieldProfile({table_name:'SS'})]);await flush();assert.equal(absent.el('table-title').textContent,'Label without evidence');assert.match(absent.el('read-status').textContent,/No published profile rows.*exact source and field/);assert.equal(absent.el('rows').innerHTML,'');assert.equal(absent.visible('clear-field-search'),false);
});

test('field arrival recovers page999 explicitly while preserving query mode columns and source',async()=>{
 const rows=[fieldProfile()],h=navigation(fieldRoute+'&search=f&searchmode=fields&columns=all&page=999',[profileTable(rows)]);h.answer(rows);await flush();assert.match(h.el('read-status').textContent,/No profile rows on this page.*1/);assert.equal(params(h).get('page'),'999');h.el('field-tools').open=false;assert.equal(h.visible('first-page'),true);
 h.el('first-page').fire('click');await flush();assert.equal(params(h).has('page'),false);for(const [key,value] of [['source','S'],['field','f'],['search','f'],['searchmode','fields'],['columns','all']])assert.equal(params(h).get(key),value);assert.ok(h.el('rows').innerHTML);assert.equal(h.visible('first-page'),false);
});

test('field arrival renders raw keys immediately for exact columns with distinct reviewed headings and no second read',async()=>{
 const rows=[fieldProfile()],t=profileTable(rows);t.columns.find(c=>c.key==='n_missing').label='Records without a value';const h=navigation(fieldRoute+'&columns=all',[t]);h.answer(rows);await flush();const text=fieldText(h);assert.match(text,/Records without a value/);assert.match(text,/n_missing/);assert.match(h.el('field-filter-status').textContent,/exact columns/i);const count=h.scripts.length;h.el('exact-columns').fire('click');assert.match(fieldText(h),/Recorded availability/);assert.equal(h.scripts.length,count);assert.equal(params(h).has('columns'),false);
});

test('applied query survives an unsent draft through presentation paging retry and refresh',async()=>{
 const rows=Array.from({length:52},(_,i)=>fieldProfile({atlas_role:'role_'+i})),t=profileTable(rows),h=navigation(fieldRoute+'&search=role',[t]);h.answer(rows);await flush();h.el('table-query').value='UNSENT';h.el('exact-columns').fire('click');assert.equal(params(h).get('search'),'role');assert.match(h.el('field-filter-status').textContent,/role/);assert.doesNotMatch(h.el('read-status').textContent,/UNSENT/);
 h.el('next-page').fire('click');await flush();assert.match(h.el('read-status').textContent,/52 matching/);assert.match(fieldText(h),/role_51/);assert.equal(h.el('table-query').value,'UNSENT');h.el('retry-read').fire('click');await flush();assert.match(fieldText(h),/role_51/);
 const refreshed=navigation(h.window.location.search,[t]);refreshed.answer(rows);await flush();assert.equal(refreshed.el('table-query').value,'role');assert.match(fieldText(refreshed),/role_51/);
 h.el('table-search-mode').value='fields';h.el('table-search-mode').fire('change');await flush();assert.equal(params(h).get('search'),'UNSENT');assert.match(h.el('read-status').textContent,/No published profiles match.*UNSENT/);
});

test('draft edits do not relabel an in-flight field read or generic category results',async()=>{
 const rows=[fieldProfile()],h=navigation(fieldRoute+'&search=f',[profileTable(rows)]);h.el('table-query').value='UNSENT';h.el('exact-columns').fire('click');assert.equal(h.scripts.length,1);assert.equal(params(h).get('search'),'f');assert.match(h.el('read-status').textContent,/Loading|Reading/);h.answer(rows);await flush();assert.match(h.el('field-filter-status').textContent,/f/);assert.doesNotMatch(h.el('field-filter-status').textContent,/UNSENT/);assert.ok(h.el('rows').innerHTML);
 const category=[profileRow()],g=navigation('?table=damyda_clinical_profile',[readable('damyda_clinical_profile',category)]);g.answer(category);await flush();g.el('table-query').value='UNSENT';g.el('exact-columns').fire('click');assert.equal(params(g).has('search'),false);assert.match(g.el('read-status').textContent,/published rows/);g.el('exact-columns').fire('click');assert.equal(g.el('read-status').hidden,true);
});

test('field arrival retains source links and limited snapshot context even without readable rows',async()=>{
 for(const extra of [{complete:false,provenance:'snapshot_only'},{status:'withheld',reason:'Publication withheld',complete:false,provenance:'snapshot_only',shards:[]}]){
  const rows=[fieldProfile()],h=navigation(fieldRoute+'&search=x&page=2&columns=all',[profileTable(rows,extra)]);assert.match(h.el('field-publication').textContent,/limited or unknown/i);assert.match(h.el('field-publication').textContent,/earlier atlas snapshot/i);
  const links=h.el('field-navigation').innerHTML;assert.match(links,/view=fields&amp;table=column_profiles&amp;source=S/);assert.match(links,/view=timeplace&amp;source=S/);assert.doesNotMatch(links,/field=f|search=x|page=2|columns=all/);
  if(extra.status){assert.equal(h.scripts.length,0);assert.match(h.el('unreadable-status').textContent,/Publication withheld/);assert.equal(h.el('rows').innerHTML,'');}
 }
});

test('field arrival cancelled or failed partial scans expose retry and ignore stale registrations',async()=>{
 for(const action of ['cancel','fail']){
  const first=[fieldProfile({atlas_role:'first'})],second=[fieldProfile({atlas_role:'second'})],t=profileTable(first);t.shards.push({id:'s2',src:'output-shards/column_profiles-s2.js',rows:1,bytes:Buffer.byteLength(JSON.stringify(second))});const h=navigation(fieldRoute,[t]);h.answer(first);await flush();const stale=h.scripts.at(-1);assert.equal(h.visible('cancel-search'),true);
  if(action==='cancel')h.el('cancel-search').fire('click');else stale.onerror();await flush();assert.equal(h.visible('retry-read'),true);assert.match(h.el('read-status').textContent,/incomplete/i);assert.equal(h.el('rows').innerHTML,'');assert.doesNotMatch(h.el('read-status').textContent,/No published profile|2 published/);
  h.el('retry-read').fire('click');await flush();h.document.currentScript=stale;h.window.DALYCARE_OUTPUTS.register({schema_version:1,build_id:'b1',table_id:t.id,shard_id:'s2',rows_json:JSON.stringify(second)});h.document.currentScript=null;assert.equal(h.el('rows').innerHTML,'');h.answer(second);await flush();assert.match(h.el('read-status').textContent,/2 published profile rows/);assert.match(fieldText(h),/first/);assert.match(fieldText(h),/second/);assert.equal(h.document.activeElement,h.el('table-title'));
 }
});

test('field recovery actions move focus to the heading before their controls disappear',async()=>{
 const rows=[fieldProfile()],t=profileTable(rows);
 for(const [route,control] of [[fieldRoute+'&search=absent','clear-field-search'],[fieldRoute+'&page=999','first-page'],[fieldRoute,'clear-row-scope']]){
  const h=navigation(route,[t]);h.answer(rows);await flush();if(control==='clear-row-scope')h.el('field-tools').open=true;
  h.el(control).focus();h.el(control).fire('click');assert.equal(h.document.activeElement,h.el('table-title'));await flush();assert.equal(h.document.activeElement,h.el('table-title'));
 }
});

test('empty field search submission preserves the user-open tools and focused input',async()=>{
 const rows=[fieldProfile()];
 for(const initialQuery of ['', '&search=f']){
  const h=navigation(fieldRoute+initialQuery,[profileTable(rows)]);h.answer(rows);await flush();
  h.el('field-tools').open=true;h.el('table-query').value='';h.el('table-query').focus();h.el('search-table').fire('submit');
  assert.equal(h.el('field-tools').open,true);assert.equal(h.visible('table-query'),true);assert.equal(h.document.activeElement,h.el('table-query'));
  await flush();assert.equal(h.visible('table-query'),true);assert.equal(h.document.activeElement,h.el('table-query'));assert.equal(params(h).has('search'),false);assert.equal(params(h).get('source'),'S');assert.equal(params(h).get('field'),'f');assert.match(h.el('read-status').textContent,/1 published profile row/);
 }
});

test('empty field search switching to all row values preserves open tools and focused selector',async()=>{
 const rows=[fieldProfile()],h=navigation(fieldRoute+'&searchmode=fields',[profileTable(rows)]);h.answer(rows);await flush();
 h.el('table-search-mode').focus();h.el('table-search-mode').value='rows';h.el('table-search-mode').fire('change');
 assert.equal(h.el('field-tools').open,true);assert.equal(h.visible('table-search-mode'),true);assert.equal(h.document.activeElement,h.el('table-search-mode'));
 await flush();assert.equal(h.visible('table-search-mode'),true);assert.equal(h.document.activeElement,h.el('table-search-mode'));assert.equal(params(h).has('searchmode'),false);assert.equal(params(h).has('search'),false);assert.match(h.el('read-status').textContent,/1 published profile row/);
});

test('field summary reasons stay readable under their heading and unknown supplied status remains labelled',async()=>{
 const rows=[fieldProfile({numeric_privacy_status:'needs_validation_unreviewed_field',summary_scope:'scope_review'}),fieldProfile({numeric_privacy_status:'withheld_unknown_support',summary_method:'method_support'}),fieldProfile({numeric_privacy_status:'future_summary_guard',summary_scope:'scope_future'})],h=navigation(fieldRoute,[profileTable(rows)]);h.answer(rows);await flush();const text=fieldText(h);
 for(const value of ['Not shown: field needs review','Withheld: supporting count unknown','Supplied summary status: future_summary_guard','scope_review','method_support','scope_future'])assert.ok(text.includes(value),value);
 assert.doesNotMatch(text,/Stored summary status:/);assert.equal((text.match(/Recorded availability/g)||[]).length,3);
});
