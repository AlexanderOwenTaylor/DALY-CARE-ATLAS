(function(window,document){
 'use strict';
 const directory=window.DALYCARE_DIRECTORY,index=window.DALYCARE_SEARCH,reader=window.DALYCARE_OUTPUTS;
 const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 let epoch=0,controller=null,activeRoute=null,referencePage=0,referenceQuery='';
 const el=id=>document.getElementById(id),state=(text,error=false)=>{el('load-state').textContent=text;el('load-state').setAttribute('role',error?'alert':'status');};
 function route(){const [fragment='',query='']=window.location.hash.replace(/^#/,'').split('?'),[tab='overview',sub='overview-summary']=fragment.split('/'),p=new URLSearchParams(query);for(const [k,v] of new URLSearchParams(window.location.search))p.set(k,v);const result={tab:p.get('qaTab')||p.get('tab')||tab,sub:p.get('qaSub')||p.get('sub')||sub,p,source:p.get('source')||'',field:p.get('field')||'',item:p.get('item')||'',q:p.get('qaSearch')||p.get('search')||p.get('q')||'',g:p.has('g')?p.get('g'):p.get('qaSearch')||p.get('search')||p.get('q')||''};
  if(!result.field&&/^current_[0-9a-f]+_[0-9a-f]+$/.test(result.item)){try{const pair=result.item.slice(8).split('_').map(s=>decodeURIComponent(s.match(/../g).map(v=>'%'+v).join('')));if(index.sources.includes(pair[0])&&index.fields.some(f=>index.sources[f[0]]===pair[0]&&f[1]===pair[1])){result.source=pair[0];result.field=pair[1];}}catch{}}
  if(!result.source&&result.tab==='registries')result.source=({'reg-damyda':'RKKP_DaMyDa','reg-lyfo':'RKKP_LYFO','reg-cll':'RKKP_CLL'})[result.sub]||'';
  if(!result.field&&result.source&&index.fields.some(f=>index.sources[f[0]]===result.source&&f[1]===result.item))result.field=result.item;return result;}
 function returnUrl(){const name=window.location.pathname.split('/').pop();return (/^DALYCARE_(?:clinical|outputs|atlas)\.html$/.test(name)?name:'DALYCARE_clinical.html')+window.location.search+window.location.hash;}
 function safeReturn(value){return typeof value==='string'&&/^DALYCARE_(?:clinical|outputs|atlas)\.html(?:[?#].*)?$/.test(value)?value:'';}
 function fieldLink(source,field,from=returnUrl()){return 'DALYCARE_outputs.html?'+new URLSearchParams({table:'column_profiles',source,field,from:safeReturn(from)});}
 function contextLinks(source,field=''){if(!source)return '';const from=safeReturn(activeRoute?.p.get('from'))||returnUrl();return '<nav class="answer-actions" aria-label="Evidence context">'+(safeReturn(activeRoute?.p.get('from'))?'<a href="'+esc(from)+'">Back to selected item</a>':'')+'<a href="DALYCARE_outputs.html?'+esc(new URLSearchParams({view:'fields',source}))+'">Source fields</a><a href="DALYCARE_outputs.html?'+esc(new URLSearchParams({view:'timeplace',source,from:field?returnUrl():from}))+'">Years and regions</a></nav>';}

 function findFields(q,source=''){const needle=String(q||'').toLocaleLowerCase();return index.fields.filter(f=>(!source||index.sources[f[0]]===source)&&(!needle||[index.sources[f[0]],f[1],f[2]].some(v=>String(v||'').toLocaleLowerCase().includes(needle))));}
 function renderFields(rows,page=0,target='search-results'){
  const selected=rows.slice(page*50,(page+1)*50);
  el(target).innerHTML=(!rows.length?'<p>No matching exact field names or reviewed labels in this search. This does not establish that the resource or observations are absent.</p>':'')+'<p>'+rows.length+' exact fields · '+(rows.length? page*50+1:0)+'–'+Math.min((page+1)*50,rows.length)+'</p>'+selected.map(f=>'<article><a href="'+esc(fieldLink(index.sources[f[0]],f[1]))+'">'+esc(f[2]||f[1])+'</a><p><code>'+esc(index.sources[f[0]])+'.'+esc(f[1])+'</code></p></article>').join('')+(rows.length>(page+1)*50?'<button data-more-fields>Next 50 fields</button>':'');
  const more=el(target).querySelector('[data-more-fields]');if(more)more.onclick=()=>renderFields(rows,page+1,target);
 }
 function begin(){epoch++;controller?.abort();reader.cancel();controller=new AbortController();return {epoch,signal:controller.signal};}
 function current(task){return task.epoch===epoch&&!task.signal.aborted;}
 function tableLinks(ids){return ids.map(id=>directory.tables.find(t=>t.id===id)).filter(Boolean).map(t=>'<article><h3>'+esc(t.title)+'</h3><p>'+esc(t.status)+' · '+t.represented_row_count+' screened rows</p><a href="DALYCARE_outputs.html?'+esc(new URLSearchParams({table:t.id,source:activeRoute?.source||''}))+'">Inspect evidence</a> · <a download href="downloads/'+esc(t.id)+'.csv">Complete CSV</a></article>').join('');}
 async function showTable(id,q='',source='',field='',page=0,offset=null,explicitFull=false,criteria={}){
  const task=begin();state('Loading screened evidence…');
  try{const table=await reader.ensureDescriptor(id);if(!current(task))return;
   if(!['available','limited'].includes(table.status)){window.DALYCARE_TOPIC.renderTable({table,result:{rows:[],total_matches:0,complete:true},source,field,esc,format:reader.formatValue,target:el('detail-content')});el('detail-content').innerHTML+='<p>'+esc(table.reason||table.status)+'</p>';state('Complete: '+table.status);return;}
   const result=await reader.scanTable(id,q,page,p=>{if(current(task))state('Searching screened rows: '+p.scanned_rows+' / '+p.total_rows);},task.signal,{...criteria,source,field,offset,explicitFull});if(!current(task))return;
   window.DALYCARE_TOPIC.renderTable({table,result,source,field,esc,format:reader.formatValue,target:el('detail-content')});
   const next=el('detail-content').querySelector('[data-next]');if(next)next.onclick=()=>showTable(id,q,source,field,page+1,result.next_offset,explicitFull,criteria);
   if(!result.complete){el('detail-content').innerHTML+='<p>Only part of this source-scoped table has been inspected. Remaining rows have not been searched.</p><button id="full-scoped-search">Search the complete table for this source and field</button>';el('full-scoped-search').onclick=()=>showTable(id,q,source,field,0,null,true,criteria);}
   state((result.complete?'Complete: ':'Partial search: at least ')+result.total_matches+' matching screened rows'+(result.complete?'':' in '+result.scanned_rows+' inspected rows'));return result;
  }catch(error){if(current(task)){state('Load failed. '+error.message,true);el('detail-content').innerHTML='<button id="retry-load">Retry this table</button>';el('retry-load').onclick=()=>showTable(id,q,source,field,page,offset,explicitFull,criteria);}}
 }
 async function searchReference(q,page=0){referencePage=page;referenceQuery=q;return showTable('npu_reference_search',q,'','',page);}
 async function showDefinition(row){const task=begin();state('Loading exact NPU definition…');try{const table=await reader.ensureDescriptor('npu_display_dictionary');if(!current(task))return;const rows=await reader.loadShard(table.id,row.shard);if(!current(task))return;const matches=rows.filter(r=>r.code===row.code);if(matches.length!==1)throw new Error('Definition identity missing or ambiguous');window.DALYCARE_TOPIC.renderTable({table,result:{rows:matches,total_matches:1},source:activeRoute?.source||'',esc,format:reader.formatValue,target:el('detail-content')});el('detail-content').innerHTML+='<button id="back-reference">Back to reference results</button>';el('back-reference').onclick=()=>searchReference(referenceQuery,referencePage);state('Complete: reference definition '+row.code);}catch(error){if(current(task)){state('Definition load failed: '+error.message,true);el('detail-content').innerHTML='<p>This definition could not be loaded. The search result does not establish observed usage.</p><button id="retry-definition">Retry this definition</button><button id="back-reference">Back to reference results</button>';el('retry-definition').onclick=()=>showDefinition(row);el('back-reference').onclick=()=>searchReference(referenceQuery,referencePage);}}}
 const modules=new Map();
 function moduleScript(name,valid){if(modules.has(name))return modules.get(name);const promise=new Promise((resolve,reject)=>{const script=document.createElement('script');script.src=name;const timer=setTimeout(()=>done(new Error('Module load timeout; retry available')),15000);function done(error){clearTimeout(timer);script.remove();if(error){modules.delete(name);reject(error);}else resolve();}script.onload=()=>done(valid()?null:new Error('Module build or registration mismatch'));script.onerror=()=>done(new Error('Module failed to load'));document.head.appendChild(script);});modules.set(name,promise);return promise;}
 async function loadTopic(route){if(!window.DALYCARE_TOPIC){const style=document.createElement('link');style.rel='stylesheet';style.href='atlas-topic.css';document.head.appendChild(style);await moduleScript('atlas-topic.js',()=>!!window.DALYCARE_TOPIC);}const key=window.DALYCARE_TOPIC.selection(route);await moduleScript('atlas-route-'+key+'.js',()=>!!window.DALYCARE_ROUTE_GROUPS?.[key]);if(route.tab==='clinical'||/imaging|microbiology|pathology|biobank/.test(route.sub))await moduleScript('DALYCARE_membership.js',()=>window.DALYCARE_MEMBERSHIP?.build_id===directory.build_id);}
 async function navigate(){
  const task=begin();activeRoute=route();el('detail-content').innerHTML='';el('search-results').innerHTML='';el('task-content').innerHTML='';state('Loading topic…');
  try{await loadTopic(activeRoute);if(!current(task))return;el('search-query').value=activeRoute.g;window.DALYCARE_TOPIC.render({route:activeRoute,directory,index,esc,tableLinks,renderFields,findFields,target:el('route-content'),title:el('route-title')});
   if(activeRoute.g&&!/^NPU\d{5}$/i.test(activeRoute.item||activeRoute.q))renderFields(findFields(activeRoute.g));
   state('Ready: '+index.fields.length+' exact fields searchable before profile loading · Run '+directory.run_id);document.documentElement.dataset.atlasReady='route';
   const table=activeRoute.p.get('table');if(table){const selected=activeRoute;
    if(selected.q&&!(table==='npu_reference_search'&&/^NPU\d{5}$/i.test(selected.q))){el('detail-content').innerHTML='<p>Search requested: <strong>'+esc(selected.q)+'</strong>. Search the complete screened table on demand.</p><button id="start-table-search">Search table</button>';el('start-table-search').onclick=()=>showTable(table,selected.q,selected.source,selected.field);state('Ready: exact field matches shown; full table search requires Search table.');}
    else if(table==='column_profiles'&&selected.source&&selected.field)await showField(selected);else await showTable(table,selected.q,selected.source,selected.field);
   }
   else if(activeRoute.field&&activeRoute.source)await showField(activeRoute);
   else if(/^NPU\d{5}$/i.test(activeRoute.item||activeRoute.field)){const selected=activeRoute,code=selected.item||selected.field,result=await searchReference(code);if(activeRoute===selected&&selected.item&&result?.total_matches===1)await showDefinition(result.rows[0]);}
   else await showClinical(activeRoute);
  }catch(error){if(current(task))state('Route load failed: '+error.message,true);}
 }
 async function showField(selected){
  if(/^RKKP_/.test(selected.source)&&directory.tables.some(t=>t.id==='registry_field_summaries')){const task={epoch},table=await reader.ensureDescriptor('registry_field_summaries');if(task.epoch!==epoch)return; if(table.shards?.some(s=>s.fields?.some(p=>p[0]===selected.source&&p[1]===selected.field)))return showTable(table.id,'',selected.source,selected.field);}
  return showTable('column_profiles','',selected.source,selected.field);
 }
 async function showClinical(selected){const key=window.DALYCARE_TOPIC.selection(selected),has=id=>directory.tables.some(t=>t.id===id);let id='',source=selected.source,criteria={};
  if(key==='registries'&&source){id='registry_field_summaries';const theme=selected.p.get('theme');if(theme){state('Loading reviewed registry theme…');await reader.registryResource();if(activeRoute!==selected)return;const topic={stage:'stage',baseline:'laboratory',treatment:'treatment',response:'response'}[theme];criteria.fields=window.DALYCARE_REGISTRY_V2_RESOURCE.fields.filter(f=>f.table_name===source&&(topic?f.topic===topic:theme==='workup'?/genetic|workup|cyto|fish/i.test(f.topic):/site/i.test(f.topic))).map(f=>f.source_column);}}
  else if(key==='vitals'&&!selected.p.get('measurement')){id='semantic_dictionary';source='SP_VitaleVaerdier';}
  else if(key==='laboratory'&&selected.sub==='lab-npu')id='lab_npu_code_coverage';
  else if(key==='timeplace'&&source)id='atlas_temporal_coverage';
  if(id&&has(id))await showTable(id,'',source,'',Math.max(0,Number(selected.p.get('page')||1)-1),null,false,criteria);
 }
 window.DALYCARE_SHELL={route,findFields,fieldLink,contextLinks,showTable,showDefinition,searchReference,renderFields};
 if(!directory||directory.schema_version!==2||!index||index.schema_version!==1||index.build_id!==directory.build_id||!Array.isArray(index.sources)||!Array.isArray(index.fields)){state('Directory unavailable or from another build. Keep the complete export together.',true);return;}
 if(directory.synthetic_validation)el('fixture-notice').textContent='SYNTHETIC VALIDATION DATA — not DALY-CARE results';
 el('field-search').onsubmit=event=>{event.preventDefault();begin();const q=el('search-query').value;renderFields(findFields(q));state('Complete: all '+index.fields.length+' field identities searched');const p=new URLSearchParams(window.location.search);p.set('g',q);window.history.replaceState(null,'','?'+p+window.location.hash);};
 el('reference-search').onclick=()=>searchReference(el('search-query').value);
 window.addEventListener('hashchange',navigate);window.addEventListener('popstate',navigate);navigate();
})(window,document);
