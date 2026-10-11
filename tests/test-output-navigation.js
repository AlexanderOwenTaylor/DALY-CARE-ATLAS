const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const templates=path.join(__dirname,'../inst/templates');

// Execute the full shipped runtime; only the browser DOM/history boundary is simulated.
// No table reads are needed for position/focus regressions, so metadata-only cards suffice.
function navigation(search='') {
  const html=fs.readFileSync(path.join(templates,'DALYCARE_outputs.html'),'utf8');
  const elements=new Map(),listeners={},scrolls=[],focuses=[];
  let window,document;
  function element(id,attrs='') {
    const handlers={};let hidden=/\bhidden\b/.test(attrs),markup='',cards=[];
    return {id,value:'',textContent:'',tabIndex:/tabindex="(-?\d+)"/.test(attrs)?Number(RegExp.$1):undefined,
      get hidden(){return hidden;},set hidden(value){hidden=value;if(id==='library'&&value)window.scrollY=Math.min(window.scrollY,160);},
      get innerHTML(){return markup;},set innerHTML(value){markup=value;cards=[...value.matchAll(/<button[^>]*data-table="([^"]+)"/g)].map(match=>Object.assign(element('card-'+match[1]),{dataset:{table:match[1]}}));},
      addEventListener(name,fn){handlers[name]=fn;},fire(name){handlers[name]?.({preventDefault(){}});},
      querySelectorAll(){return cards;},setAttribute(name,value){if(name==='tabindex')this.tabIndex=Number(value);},
      focus(options){document.activeElement=this;focuses.push({element:this,options});if(!options?.preventScroll)window.scrollY=80;}
    };
  }
  for(const match of html.matchAll(/<[^>]*\bid="([^"]+)"[^>]*>/g))elements.set(match[1],element(match[1],match[0]));
  const el=id=>elements.get(id);
  document={getElementById:el,activeElement:null,body:{classList:{toggle(){}}},documentElement:{dataset:{}}};
  const tables=Array.from({length:147},(_,i)=>({id:'t'+i,title:'Table '+i,group:'Evidence',status:'metadata_only',columns:[],shards:[]}));
  const entries=[{search,state:null}],copy=value=>JSON.parse(JSON.stringify(value));let index=0;
  const history={scrollRestoration:'auto',get state(){return entries[index].state;},
    replaceState(state,_title,url){entries[index]={state:copy(state),search:new URL(url,'https://atlas.test/').search};window.location.search=entries[index].search;},
    pushState(state,_title,url){entries.splice(++index);entries.push({state:copy(state),search:new URL(url,'https://atlas.test/').search});window.location.search=entries[index].search;},
    go(delta){index+=delta;window.location.search=entries[index].search;listeners.popstate({state:this.state});
      // Persisted native restoration follows popstate; the SPA must avoid clobbering its own position.
      if(this.scrollRestoration==='auto')window.scrollY=160;}
  };
  window={DALYCARE_OUTPUT_CATALOGUE:{schema_version:1,build_id:'b1',tables},location:{search},history,scrollX:0,scrollY:0,
    scrollTo(options){scrolls.push({...options});this.scrollX=options.left;this.scrollY=options.top;},addEventListener(name,fn){listeners[name]=fn;}};
  vm.runInNewContext(fs.readFileSync(path.join(templates,'atlas-outputs.js'),'utf8'),{window,document,URLSearchParams,TextEncoder,AbortController,setTimeout,clearTimeout});
  const card=id=>el('table-list').querySelectorAll('[data-table]').find(button=>button.dataset.table===id);
  return {window,document,el,card,scrolls,focuses,open(id,x=7,y=6200){window.scrollX=x;window.scrollY=y;card(id).focus({preventScroll:true});card(id).fire('click');}};
}

test('custom Back restores deep filtered list position and the rebuilt originating card without focus scrolling',()=>{
  const h=navigation('?q=Table&group=Evidence&status=metadata_only');
  const origin=h.card('t120');h.open('t120');
  assert.equal(h.document.activeElement,h.el('table-title'),'opening assigns meaningful detail focus');
  assert.equal(h.el('table-title').tabIndex,-1,'visible heading supports programmatic focus');
  assert.equal(h.el('table-title').textContent,'Table 120');
  h.window.scrollY=130;h.el('back-library').fire('click');
  assert.equal(h.el('library').hidden,false);
  assert.equal(h.window.scrollY,6200,'return survives detail-height clamping');assert.equal(h.window.scrollX,7);
  assert.equal(h.document.activeElement,h.card('t120'));assert.notEqual(h.card('t120'),origin,'list was rebuilt');
  assert.equal(h.focuses.at(-1).options.preventScroll,true,'focusing the rebuilt card cannot move the restored viewport');
  assert.equal(h.scrolls.at(-1).behavior,'instant','restoration is immediate even with smooth scrolling preferences');
  assert.equal(h.window.location.search,'?q=Table&group=Evidence&status=metadata_only');
});

test('browser Back/Forward retains per-entry list origin through table search history and custom Back',()=>{
  const h=navigation('?group=Evidence');h.open('t120');
  h.el('table-query').value='æ & value';h.el('search-table').fire('submit');
  h.window.history.go(-1);assert.equal(h.el('table-query').value,'');
  h.window.history.go(-1);
  assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'));
  h.window.history.go(1);assert.equal(h.document.activeElement,h.el('table-title'));
  h.window.history.go(1);assert.equal(h.el('table-query').value,'æ & value');
  h.el('back-library').fire('click');assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'));
  h.open('t40',0,2100);h.el('back-library').fire('click');
  assert.equal(h.window.scrollY,2100);assert.equal(h.document.activeElement,h.card('t40'));
  h.window.history.go(-3);h.el('back-library').fire('click');
  assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'),'earlier detail entries retain their own origin');
});

test('direct table links retain queries/pages without creating an originating card or saved list position',()=>{
  const h=navigation('?table=t120&q=Table&group=Evidence&status=metadata_only&search=needle&page=3');
  assert.equal(h.el('table-query').value,'needle');assert.equal(h.document.activeElement,h.el('table-title'));
  assert.equal(h.window.location.search,'?table=t120&q=Table&group=Evidence&status=metadata_only&search=needle&page=3');
  h.el('back-library').fire('click');
  assert.equal(h.scrolls.length,0,'no nonexistent list position is imposed');
  assert.equal(h.focuses.some(call=>call.element.id.startsWith('card-')),false,'no arbitrary card receives focus');
  assert.equal(h.window.location.search,'?q=Table&group=Evidence&status=metadata_only');
  h.window.history.go(-1);assert.equal(h.el('table-query').value,'needle');
  h.window.history.go(1);assert.equal(h.scrolls.length,0);
});

test('changing metadata filters discards stale origin while history restores its earlier matching list',()=>{
  const h=navigation();h.open('t120');h.el('back-library').fire('click');
  h.el('metadata-query').value='Table 40';h.el('metadata-query').fire('input');
  const restores=h.scrolls.length;h.window.history.go(-1);
  assert.equal(h.window.scrollY,6200);assert.equal(h.document.activeElement,h.card('t120'));
  h.window.history.go(1);assert.equal(h.scrolls.length,restores+1,'filtered entry cannot reuse an unrelated saved origin');
  assert.equal(h.el('metadata-query').value,'Table 40');assert.equal(h.card('t120'),undefined);
});
