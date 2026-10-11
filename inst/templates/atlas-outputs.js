(function (window,document) {
  'use strict';
  const MAX_BYTES=262144,MAX_ROWS=250,CACHE_BYTES=1048576,PAGE_ROWS=50;
  const cache=new Map(); let cacheBytes=0,activeTable=null,pending=null,scanEpoch=0;
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const id=value=>typeof value==='string' && /^[A-Za-z0-9_-]+$/.test(value);
  const utf8=value=>new TextEncoder().encode(value).length;
  function catalogue() {
    const c=window.DALYCARE_OUTPUT_CATALOGUE;
    if (!c || c.schema_version!==1) throw new Error('Unsupported or missing catalogue version');
    if (!id(c.build_id) || !Array.isArray(c.tables)) throw new Error('Invalid catalogue build');
    const ids=new Set();
    for(const table of c.tables){
      if(!table || !id(table.id) || ids.has(table.id) || typeof table.title!=='string' || !Array.isArray(table.columns) || !Array.isArray(table.shards))throw new Error('Invalid catalogue table schema or identity');
      ids.add(table.id);
    }
    return c;
  }
  function tableFor(tableId) {
    const c=catalogue(),t=c.tables.find(t=>t.id===tableId);
    if (!t || !id(t.id) || !Array.isArray(t.columns) || !Array.isArray(t.shards)) throw new Error('Unknown table or incompatible schema');
    const keys=new Set();
    if(['available','limited'].includes(t.status))for(const column of t.columns){if(!column || typeof column.key!=='string' || !column.key || ['__proto__','constructor','prototype'].includes(column.key) || keys.has(column.key) || !['string','number','boolean'].includes(column.type))throw new Error('Incompatible column schema type');keys.add(column.key);}
    const shards=new Set();
    for(const shard of t.shards){
      if(!shard || !id(shard.id) || shards.has(shard.id))throw new Error('Invalid or duplicate shard identity');
      if(typeof shard.src!=='string' || !/^output-shards\/[A-Za-z0-9_-]+\.js$/.test(shard.src))throw new Error('Invalid shard path');
      if(!Number.isInteger(shard.rows) || shard.rows<0 || shard.rows>MAX_ROWS || !Number.isInteger(shard.bytes) || shard.bytes<2 || shard.bytes>MAX_BYTES)throw new Error('Shard row or byte descriptor exceeds limit');
      shards.add(shard.id);
    }
    return {c,t};
  }
  function settle(error,rows,bytes) {
    const request=pending;if(!request)return;
    pending=null;clearTimeout(request.timer);request.script.remove();
    if(error) request.reject(error);
    else {
      while(cacheBytes+bytes>CACHE_BYTES && cache.size){const first=cache.keys().next().value;cacheBytes-=cache.get(first).bytes;cache.delete(first);}
      cache.set(request.key,{rows,bytes});cacheBytes+=bytes;request.resolve(rows);
    }
  }
  function cancel() {scanEpoch++;settle(new Error('Search incomplete: read cancelled'));}
  function selectTable(tableId) {if(activeTable!==tableId){cancel();activeTable=tableId;}}
  function loadShard(tableId,shardId) {
    try {
      const {c,t}=tableFor(tableId);selectTable(tableId);
      if(!['available','limited'].includes(t.status)) throw new Error('Table rows unavailable');
      const s=t.shards.find(s=>s.id===shardId);
      if(!s || !id(s.id)) throw new Error('Unknown shard identity');
      const key=c.build_id+':'+tableId+':'+shardId;
      if(cache.has(key)){const item=cache.get(key);cache.delete(key);cache.set(key,item);return Promise.resolve(item.rows);}
      if(pending){if(pending.key===key)return pending.promise;throw new Error('A table shard read is already active');}
      const script=document.createElement('script');script.src=s.src;script.async=true;
      const request={key,c,t,s,script,buildId:c.build_id};request.promise=new Promise((resolve,reject)=>{request.resolve=resolve;request.reject=reject;});pending=request;
      script.onerror=()=>{if(pending===request)settle(new Error('Shard failed to load'));};
      script.onload=()=>{if(pending===request)settle(new Error('Shard registration missing'));};
      request.timer=setTimeout(()=>{if(pending===request)settle(new Error('Shard load timeout; retry available'));},15000);
      document.head.appendChild(script);return request.promise;
    } catch(error){return Promise.reject(error);}
  }
  function register(data) {
    const r=pending;
    // Correlate the actual executing script, so late timeout/cancel responses cannot poison a retry.
    if(!r || document.currentScript!==r.script)return;
    try {
      if(!data || data.schema_version!==1 || data.build_id!==r.buildId || catalogue().build_id!==r.buildId || data.table_id!==r.t.id || data.shard_id!==r.s.id)throw new Error('Shard version/build/table identity mismatch');
      if(typeof data.rows_json!=='string' || data.rows_json.length>MAX_BYTES || utf8(data.rows_json)!==r.s.bytes)throw new Error('Shard byte mismatch or limit exceeded');
      const rows=JSON.parse(data.rows_json);
      if(!Array.isArray(rows) || rows.length!==r.s.rows || rows.length>MAX_ROWS)throw new Error('Shard row count mismatch or limit exceeded');
      const keys=new Set(r.t.columns.map(c=>c.key));
      for(const row of rows) {
        if(!row || typeof row!=='object' || Array.isArray(row) || Object.keys(row).some(k=>!keys.has(k)))throw new Error('Shard contains unreviewed schema columns');
        for(const column of r.t.columns) {
          if(!own(row,column.key))throw new Error('Shard missing schema column');
          const value=row[column.key];if(value===null)continue;
          if(typeof value==='object' || !['string','number','boolean'].includes(typeof value))throw new Error('Invalid row value');
          if(column.type==='number' && (typeof value!=='number' || !Number.isFinite(value)))throw new Error('Invalid numeric schema value');
          if(column.type==='boolean' && typeof value!=='boolean')throw new Error('Invalid boolean schema value');
          if(column.type==='string' && typeof value!=='string')throw new Error('Invalid string schema value');
        }
      }
      settle(null,rows,r.s.bytes);
    }catch(error){settle(error);}
  }
  async function scanTable(tableId,query,page,onProgress,signal) {
    const {t}=tableFor(tableId);selectTable(tableId);cancel();const epoch=scanEpoch;
    const check=()=>{if(signal?.aborted || epoch!==scanEpoch || activeTable!==tableId)throw new Error('Search incomplete: cancelled');};
    const abort=()=>{if(epoch===scanEpoch)cancel();};signal?.addEventListener('abort',abort,{once:true});
    let scanned=0,matches=0;const rows=[],start=Math.max(0,Number.isFinite(Number(page))?Math.floor(Number(page)):0)*PAGE_ROWS;
    const needle=String(query||'').toLocaleLowerCase();
    try {
      check();
      if(!needle) {
        const total=t.shards.reduce((n,s)=>n+s.rows,0);let offset=0;
        for(const shard of t.shards){check();if(offset<start+PAGE_ROWS && offset+shard.rows>start){const data=await loadShard(tableId,shard.id);check();for(let i=Math.max(0,start-offset);i<data.length && rows.length<PAGE_ROWS;i++)rows.push(data[i]);scanned+=data.length;}offset+=shard.rows;}
        return {rows,total_matches:total,scanned_rows:scanned,complete:true};
      }
      for(const shard of t.shards){check();const data=await loadShard(tableId,shard.id);check();for(const row of data){if(t.columns.some(c=>row[c.key]!==null && String(row[c.key]).toLocaleLowerCase().includes(needle))){if(matches>=start && rows.length<PAGE_ROWS)rows.push(row);matches++;}}scanned+=data.length;onProgress?.({scanned_rows:scanned,total_rows:t.shards.reduce((n,s)=>n+s.rows,0)});}
      check();return {rows,total_matches:matches,scanned_rows:scanned,complete:true};
    }catch(error){throw new Error('Search incomplete: '+error.message);}
    finally {signal?.removeEventListener('abort',abort);}
  }
  const reviewedLabels={
    numeric_privacy_status:{eligible_stored_summary:'Stored summary available',needs_validation_negative_sentinel:'Not shown: invalid stored values need review',protected_field:'Protected field · schema only'},
    summary_scope:{stored_source_row_profile:'Stored source rows'},
    summary_method:{supplied_mean_and_quantiles:'Supplied mean and quantiles'},
    summary_caveat:{quantiles_may_use_bounded_stream_sample:'Quartiles may use a sample of source records'},
    summary_caveats:{quantiles_may_use_bounded_stream_sample:'Quartiles may use a sample of source records'}
  };
  const privacyLabels={
    protected_field:'Withheld: protected field',
    withheld_unvalidated_distribution:'Withheld: values and counts need validation',
    withheld_small_cells:'Withheld: small groups',
    withheld_residual_small_distribution:'Withheld: small groups and related counts',
    withheld_small_complementary_cells:'Withheld: small groups and related counts',
    withheld_exact_clinical_bounds:'Withheld: exact clinical date bounds',
    withheld_derived_source_range:'Source range withheld',
    needs_validation_unreviewed_field:'Not shown: field needs review',
    withheld_unknown_support:'Withheld: supporting count unknown',
    unavailable_zero_support:'Unavailable: no recorded values',
    withheld_insufficient_support:'Withheld: too few recorded values',
    needs_validation_unknown_distinctness:'Not shown: distinct values need review',
    withheld_constant_profile:'Withheld: constant stored values',
    withheld_near_unique_profile:'Withheld: nearly unique stored values',
    needs_validation_missing_range_evidence:'Not shown: stored range needs review',
    needs_validation_negative_sentinel:'Not shown: invalid stored values need review'
  };
  Object.assign(reviewedLabels,{
    count_basis:{reference_dictionary_metadata:'Dictionary entries and reference metadata; units depend on the named count',region_reference_metadata:'Configured region reference entries'},
    coverage_basis:{event_date_counts:'Recorded event-year counts',streamed_event_date_counts:'Recorded event-year counts (streamed)',source_date_range:'Inferred source date range; bounds withheld'},
    value_privacy_status:privacyLabels,count_privacy_status:privacyLabels,date_privacy_status:privacyLabels,availability_privacy_status:privacyLabels
  });
  Object.assign(reviewedLabels.numeric_privacy_status,privacyLabels);
  reviewedLabels.summary_method['supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample']='Supplied mean and quantiles; quartiles may use a sample of source records';
  function formatValue(value,key,row={}) {
    if(value!==null && value!==undefined) return reviewedLabels[key] && own(reviewedLabels[key],value)?reviewedLabels[key][value]:String(value);
    let status;
    if(['mean','median','p25','p75','sd','q25','q75','iqr','min','max'].includes(key)) {
      status=row.numeric_privacy_status;
      if(['min','max'].includes(key) && status==='eligible_stored_summary') return 'Withheld: exact stored extrema';
    } else if(['n_available','n_missing','pct_available','pct_missing'].includes(key)) status=row.availability_privacy_status;
    else if(['n','n_rows','n_observed','n_patients','count','frequency','pct','pct_rows','pct_patients'].includes(key)) status=row.count_privacy_status || (row.value_privacy_status==='withheld_unvalidated_distribution'?row.value_privacy_status:null) || (row.date_privacy_status==='withheld_derived_source_range'?row.date_privacy_status:null);
    else if(['value','label','top_value','mode','code','npu_code','lab_code','category','display_value','raw_value'].includes(key)) status=row.value_privacy_status;
    else if(key==='year' && row.date_privacy_status==='withheld_derived_source_range') status=row.date_privacy_status;
    else if(['min_date','max_date','date_min','date_max','date_range','display_min_year','display_max_year'].includes(key)) status=row.date_privacy_status;
    else if(key==='n_distinct_capped') status=row.availability_privacy_status || (row.is_sensitive && row.value_privacy_status==='protected_field'?row.value_privacy_status:null) || (['protected_field','withheld_unknown_support','withheld_insufficient_support','unavailable_zero_support'].includes(row.numeric_privacy_status)?row.numeric_privacy_status:null);
    return privacyLabels[status] || 'Missing';
  }
  window.DALYCARE_OUTPUTS={register,loadShard,scanTable,cancel,formatValue,get cacheBytes(){return cacheBytes;}};
  const root = document.getElementById('outputs-app');
  if (!root) return;
  const el = id => document.getElementById(id),
    escape = value => String(value ?? '').replace(/[&<>"']/g, ch => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[ch]));
  const statusLabels = {available:'Published rows',limited:'Limited rows',empty_output:'Empty output',not_produced:'Not in this export',metadata_only:'Metadata only',withheld:'Privacy withheld',unavailable:'Unavailable'};
  const kindLabels={aggregate_summary:'Aggregate summary',field_metadata:'Field metadata',reference:'Reference definitions',reference_dictionary:'Reference definitions',reference_definitions:'Reference definitions',metadata:'Metadata'};
  const originLabels={csv_run:'From this run’s CSV outputs',csv_outputs:'From CSV outputs',project_reference:'Reviewed project reference definitions',snapshot_only:'From an earlier atlas snapshot; original scope unknown',legacy_payload:'From an earlier atlas export'};
  // Exact reviewed table identities, never an inferred clinical classification.
  const tasks={
    fields:{title:'Fields and summaries',description:'Inspect source fields, missingness, and supplied stored summaries. A field match does not establish a validated measurement.',ids:['column_profiles','columns','damyda_numeric_fields','damyda_clinical_profile','lyfo_clinical_profile','cll_clinical_profile']},
    sources:{title:'Sources',description:'Check source inventory and current loading or resolution status. These are source records, not unique-person cohorts.',ids:['sources','registry_clinical_summary','source_resolution','atlas_module_readiness']},
    timeplace:{title:'Years and regions',description:'Inspect the selected date or region field for each source. These separate summaries do not define a combined cohort.',ids:['atlas_temporal_coverage_years','atlas_temporal_coverage','atlas_spatial_region_counts','atlas_spatial_region_coverage','atlas_dk_choropleth_regions']},
    codes:{title:'Code meanings',description:'Look up supplied reference definitions. A definition is not evidence of an observed test or result.',ids:['npu_display_dictionary','clinical_display_dictionary']},
    all:{title:'All outputs',description:'The complete export inventory, including context-only and unpublished outputs.'},
    technical:{title:'Run and publication details',description:'Technical outputs, mapping context, and publication limits. A file with rows may still omit the information needed for a clinical question.'}
  };
  const descriptions={
    column_profiles:['Field summaries','Find exact source fields, availability, and stored summaries where approved.'],
    columns:['Field inventory','Inspect exact field names, types, and supplied missingness.'],
    damyda_numeric_fields:['Availability and summary status','Inspect numeric-field availability and supplied units; stored summaries may be withheld.'],
    damyda_clinical_profile:['Category context','Selected myeloma registry fields; category values and counts may be withheld.'],
    lyfo_clinical_profile:['Category context','Selected lymphoma registry fields; category values and counts may be withheld.'],
    cll_clinical_profile:['Category context','Selected CLL registry fields; category values and counts may be withheld.'],
    sources:['Source inventory','Inspect source sizes and load/profile status.'],
    registry_clinical_summary:['Registry sources','Inspect source-record and field counts; ID counts are not validated patient totals.'],
    source_resolution:['Resolution status','Check whether configured sources were found; this does not establish completeness.'],
    atlas_module_readiness:['Evidence readiness','Inspect module and source readiness; this is not clinical completeness.'],
    atlas_temporal_coverage_years:['Recorded years','Inspect source records by selected date-field year and the supplied evidence basis.'],
    atlas_temporal_coverage:['Date-field availability','Inspect the selected date field and supplied availability for each source.'],
    atlas_spatial_region_counts:['Recorded regions','Inspect counts by source and recorded region field; location meaning depends on that field.'],
    atlas_spatial_region_coverage:['Regional coverage status','Inspect supplied source coverage status and basis by region.'],
    atlas_dk_choropleth_regions:['Reference regions','Configured region labels; not observed residence or treatment location.'],
    npu_display_dictionary:['Reference definitions','Look up laboratory code meanings, systems, and units where supplied.'],
    clinical_display_dictionary:['Reference definitions','Look up clinical code and field meanings in the stated source/system.'],
    checks:['Context only','Source identity only; check identifier, severity, and message are not published.'],
    action_items:['Context only','Source context only; the action itself is not published.'],
    db_budget_actions:['Context only','Affected source and field only; action details are not published.'],
    legacy_resource_audit:['Context only','Domain only; individual resources and audit results are not published.'],
    resource_reconciliation:['Context only','Domain only; individual resources and reconciliation results are not published.'],
    source_truth_evidence:['Context only','Domain only; resource identities and comparison counts are not published.'],
    canonical_resource_reconciliation:['Context only','Domain only; individual canonical resources are not identifiable.'],
    mm_treatment_source_summary:['Context only','Source identity and withheld date fields; no treatment totals are published.'],
    situation_report_freshness:['Context only','Metric identity and withheld date fields; latest dates are not published.'],
    atlas_temporal_date_quality:['Context only','Source/date-quality context; inspect published columns for the retained evidence.'],
    source_availability_drift:['Context only','Source type and load-status groups only; their counts are not published.'],
    lab_npu_code_coverage:['Code mapping context','Source-field context; code values and counts are withheld pending validation.'],
    npu_lab_usage_by_vector:['Code mapping context','Dictionary-group context; observed counts are subject to withholding.'],
    npu_lab_unmatched_codes:['Code mapping context','Mapping-gap context, not clinical findings or validated result values.'],
    npu_detective_code_inventory:['Code mapping context','Code-to-dictionary mapping metadata; not validated laboratory results.'],
    npu_detective_candidates:['Code mapping context','Laboratory mapping review candidates, not measured results.'],
    isotype_code_usage:['Code mapping context','Curated isotype-code context; mapping does not establish measured results.'],
    isotype_bucket_summary:['Code mapping context','Mapped isotype-group context; not a unique-person cohort.'],
    mm_treatment_code_counts:['Treatment-rule context','Curated rule matches may overlap; do not sum them as unique people.'],
    npu_dictionary_summary:['Reference summary','Named dictionary metrics, not observed laboratory results.'],
    npu_dictionary_vectors:['Reference groups','Dictionary-group entry counts; use Code meanings for individual definitions.'],
    column_top_values:['No rows published','Observed category values and frequencies are not published in this export.']
  };
  const researchIds=new Set(Object.values(tasks).flatMap(task=>task.ids||[]));
  const isReference=t=>['reference','reference_dictionary','reference_definitions'].includes(t.kind);
  const readable=t=>['available','limited'].includes(t.status)&&t.shards.some(s=>s.rows>0);
  function content(t){
    const reviewed=descriptions[t.id];
    if(!['available','limited'].includes(t.status))return ['No rows published',reviewed?.[1] || (t.status==='empty_output'?'This output is empty.':t.reason || 'Rows are not included in this export.')];
    return reviewed || [isReference(t)?'Reference definitions':'Published rows','Inspect the supplied row meaning and publication limits.'];
  }
  let c;
  try{c=catalogue();}catch(error){el('outputs-status').textContent=error.message+'. Keep all atlas files together and retry.';if(document.documentElement)document.documentElement.dataset.atlasReady='outputs-error';return;}
  const groups=[...new Set(c.tables.map(t=>t.group).filter(Boolean))].sort();
  el('group-filter').innerHTML='<option value="">All groups</option>'+groups.map(g=>'<option>'+escape(g)+'</option>').join('');
  let selected=null,page=0,controller=null,viewEpoch=0,libraryReturn=null,view='fields',listPage=0,exactColumns=false,lastResult=null;
  const LIST_ROWS=12;
  if('scrollRestoration' in window.history)window.history.scrollRestoration='manual';
  const count=value=>value===null||value===undefined?'Not supplied':formatValue(value);
  function saveState(replace=false){
    const p=new URLSearchParams();
    if(view!=='fields')p.set('view',view);
    if(listPage)p.set('listpage',listPage+1);
    if(el('metadata-query').value)p.set('q',el('metadata-query').value);
    if(el('group-filter').value)p.set('group',el('group-filter').value);
    if(el('availability-filter').value)p.set('status',el('availability-filter').value);
    if(selected){p.set('table',selected.id);if(el('table-query').value)p.set('search',el('table-query').value);if(page)p.set('page',page+1);if(exactColumns)p.set('columns','all');}
    window.history[replace?'replaceState':'pushState']({outputsLibraryReturn:libraryReturn},'','DALYCARE_outputs.html'+(p.size?'?'+p:''));
  }
  function restoreLibraryPosition(){
    if(!libraryReturn)return false;
    const target=libraryReturn.controlId?el(libraryReturn.controlId):[...el('table-list').querySelectorAll('[data-table]')].find(button=>button.dataset.table===libraryReturn.tableId);
    if(!target||target.hidden)return false;
    target.focus({preventScroll:true});window.scrollTo({left:libraryReturn.x,top:libraryReturn.y,behavior:'instant'});return true;
  }
  const searchTargets=[['search-field-rows','column_profiles'],['search-clinical-rows','clinical_display_dictionary'],['search-lab-rows','npu_display_dictionary']];
  function list(){
    const q=el('metadata-query').value.trim().toLocaleLowerCase(),g=el('group-filter').value,s=el('availability-filter').value,task=tasks[view];
    const tables=c.tables.filter(t=>(view==='all'||(view==='technical'?!researchIds.has(t.id):task.ids.includes(t.id)))&&(!g||t.group===g)&&(!s||t.status===s)&&[t.id,t.title,t.group,t.source_file,t.kind,t.row_grain,...(t.source_terms||[]),...(t.columns||[]).flatMap(c=>[c.key,c.label,c.definition])].some(value=>String(value||'').toLocaleLowerCase().includes(q)));
    if(task.ids)tables.sort((a,b)=>task.ids.indexOf(a.id)-task.ids.indexOf(b.id));
    listPage=Math.min(listPage,Math.max(0,Math.ceil(tables.length/LIST_ROWS)-1));
    const start=listPage*LIST_ROWS,shown=tables.slice(start,start+LIST_ROWS);
    el('table-list').innerHTML=shown.map(t=>{const [label,purpose]=content(t);return '<button type="button" class="table-card" data-table="'+escape(t.id)+'"><span class="card-content-label">'+escape(label)+'</span><strong>'+escape(t.title)+'</strong><span>'+escape(purpose)+'</span><small class="card-action">'+(readable(t)?'Open table':'Inspect export status')+' →</small></button>';}).join('')||'<p class="empty-catalogue">No table names or descriptions match. Try a row search above, clear filters, or choose All outputs.</p>';
    el('table-list').querySelectorAll('[data-table]').forEach(button=>button.addEventListener('click',()=>open(button.dataset.table)));
    el('task-title').textContent=task.title;el('task-description').textContent=task.description;
    Object.keys(tasks).forEach(key=>el('task-'+key).setAttribute('aria-pressed',String(view===key)));
    el('outputs-status').textContent=(tables.length?'Showing '+(start+1)+'–'+(start+shown.length)+' of '+tables.length:'0')+' outputs'+(view==='all'?' in the complete inventory':'');
    el('catalogue-previous').disabled=listPage===0;el('catalogue-next').disabled=start+LIST_ROWS>=tables.length;el('catalogue-paging').hidden=tables.length<=LIST_ROWS;
    el('catalogue-page').textContent='Page '+(listPage+1)+' of '+Math.max(1,Math.ceil(tables.length/LIST_ROWS));
    el('clear-filters').hidden=!(q||g||s);el('applied-filters').hidden=!(g||s);el('applied-filters').textContent=[g&&'Group: '+g,s&&'State: '+statusLabels[s]].filter(Boolean).join(' · ');
    let actions=0;for(const [control,tableId] of searchTargets){const t=c.tables.find(t=>t.id===tableId);el(control).hidden=!q||!t||!readable(t);if(!el(control).hidden)actions++;}
    el('query-actions').hidden=!actions;el('query-action-label').textContent='Look for “'+el('metadata-query').value.trim()+'” inside published rows:';
  }
  const cell=(row,key)=>escape(formatValue(row[key],key,row));
  const supplied=(row,key)=>row[key]!==null&&row[key]!==undefined&&row[key]!=='';
  const line=(label,value)=>'<span class="cell-line"><span class="cell-key">'+escape(label)+': </span>'+value+'</span>';
  const lines=(row,keys)=>keys.filter(key=>own(row,key)).map(key=>line(key.replaceAll('_',' '),cell(row,key))).join('');
  const identity=(row,field='column_name')=>'<strong>'+cell(row,field)+'</strong>'+line('Source',cell(row,'table_name'));
  function availability(row){
    let html=own(row,'n_available')?line('With a value',cell(row,'n_available')+(own(row,'n_rows')?' of '+cell(row,'n_rows')+' source rows':' source rows')):'';
    if(own(row,'pct_available'))html+=line('Supplied percentage',cell(row,'pct_available')+(supplied(row,'pct_available')?'%':''));
    return html||'Availability not supplied';
  }
  function summaryValues(row){
    const keys=['median','p25','p75','mean'],present=keys.filter(key=>own(row,key)&&supplied(row,key));
    let html='';
    if(present.length){for(const [key,label] of [['median','Median'],['p25','25th percentile'],['p75','75th percentile'],['mean','Mean']])if(own(row,key))html+=line(label,cell(row,key));}
    else if(row.numeric_privacy_status)html=cell(row,'numeric_privacy_status');
    else html='No stored numeric summary supplied';
    if(present.length&&row.numeric_privacy_status)html+=line('Summary status',cell(row,'numeric_privacy_status'));
    return html;
  }
  function summaryScope(row){return ['summary_method','summary_scope'].filter(key=>supplied(row,key)).map(key=>'<span class="cell-line">'+cell(row,key)+'</span>').join('')||'Summary method and scope not supplied';}
  // Primary columns compose existing values only. Exact columns remain available below the toggle.
  const primary={
    column_profiles:[['Source field','Exact field, source and profile kind',r=>identity(r)+line('Profile',cell(r,'profile_kind'))],['Availability','Source records, not people',availability],['Stored values','Supplied summaries, not reference ranges',summaryValues],['Method and scope','Read with the stored values',summaryScope]],
    damyda_numeric_fields:[['Source field and unit','Configured unit, not harmonization',r=>identity(r,'source_column')+line('Field key',cell(r,'field'))+line('Unit',cell(r,'unit'))],['Availability','Supplied source-record availability',availability],['Stored values','Supplied summaries or withholding reason',summaryValues],['Method and scope','Read with the stored values',summaryScope]],
    columns:[['Source field','Exact names',r=>identity(r)],['Field type','Supplied source typing',r=>lines(r,['column_type','column_class'])],['Missingness','Source records, not people',r=>lines(r,['n_missing','pct_missing','availability_privacy_status'])],['Distinctness and protection','Capped count, not a value list',r=>lines(r,['n_distinct_capped','is_sensitive','value_privacy_status'])]],
    sources:[['Source','Exact table and configured type',r=>'<strong>'+cell(r,'table_name')+'</strong>'+lines(r,['source_type','domain'])],['Source size','Records and fields, not people',r=>lines(r,['n_rows','n_cols'])],['Load and profile','Supplied current-run status',r=>lines(r,['load_status','profile_mode'])],['Resolution','Finding a source is not completeness',r=>lines(r,['resolution_status','memory_status'])]],
    npu_display_dictionary:[['Code and meaning','Supplied reference entry',r=>'<strong>'+cell(r,'code')+'</strong>'+line('Meaning',cell(r,'label'))+(supplied(r,'label_da')?line('Danish label',cell(r,'label_da')):'')],['System and unit','As supplied by the dictionary',r=>lines(r,['system','system_spec','unit','property'])],['Definition','Reference meaning, not an observation',r=>cell(r,'definition')],['Reference source','Supplied provenance',r=>lines(r,['source_label','source_url','retrieved_on','note'])]],
    clinical_display_dictionary:[['Code and meaning','Supplied reference entry',r=>'<strong>'+cell(r,'code')+'</strong>'+line('Meaning',cell(r,'label'))+(supplied(r,'label_da')?line('Danish label',cell(r,'label_da')):'')],['Kind and system','Confirm the stated source/system',r=>lines(r,['kind','system'])],['Definition','Reference meaning, not an observation',r=>cell(r,'definition')],['Reference source','Supplied provenance',r=>lines(r,['source_label','source_url','retrieved_on','note'])]],
    atlas_temporal_coverage_years:[['Source and date field','Exact selected evidence field',r=>identity(r,'date_column')],['Recorded year','Selected date-field year',r=>cell(r,'year')],['Source records','Count and supplied percentage',r=>lines(r,['n_rows','pct_rows'])],['Evidence basis','Interpret counts using this basis',r=>lines(r,['coverage_basis','availability_privacy_status','value_privacy_status'])]],
    atlas_temporal_coverage:[['Source and date field','Exact selected field',r=>identity(r,'date_column')],['Source records','Not unique people',r=>lines(r,['n_rows'])],['Date availability','Supplied percentage and status',r=>lines(r,['pct_available','availability_privacy_status','date_privacy_status'])]],
    atlas_spatial_region_counts:[['Source and region field','Location meaning depends on this field',r=>identity(r,'region_column')],['Recorded region','Supplied normalized region',r=>lines(r,['region_name','region_code'])],['Source records','Count and supplied percentage',r=>lines(r,['n_rows','pct_rows'])],['Evidence basis','Not a residence or treatment claim',r=>lines(r,['count_basis'])]],
    atlas_spatial_region_coverage:[['Region','Configured region labels',r=>lines(r,['region_name','region_code'])],['Source coverage','Supplied group and status',r=>lines(r,['domain','coverage_status'])],['Records and basis','Read the basis with the count',r=>lines(r,['n_rows','basis'])]]
  };
  function renderRows(){
    if(!selected||!lastResult)return;
    const t=selected,rows=lastResult.rows,compact=primary[t.id]&&!exactColumns;
    el('exact-columns').hidden=!primary[t.id];el('exact-columns').textContent=exactColumns?'Show reading view':'Show all exact columns';el('exact-columns').setAttribute('aria-pressed',String(exactColumns));
    if(!rows.length){el('rows').innerHTML='';return;}
    const columns=compact?primary[t.id]:t.columns.map(c=>[c.label||c.key,c.definition||('Exact column: '+c.key),r=>cell(r,c.key)]);
    el('rows').innerHTML='<div class="'+(compact?'reading-table':'table-scroll')+'"><table><thead><tr>'+columns.map(([label,meaning])=>'<th scope="col">'+escape(label)+'<small>'+escape(meaning)+'</small></th>').join('')+'</tr></thead><tbody>'+rows.map(row=>'<tr>'+columns.map(([label,,render])=>'<td data-label="'+escape(label)+'">'+render(row)+'</td>').join('')+'</tr>').join('')+'</tbody></table></div>';
  }
  async function readPage(){
    controller?.abort();controller=new AbortController();const epoch=++viewEpoch,t=selected;if(!t)return;
    lastResult=null;el('rows').innerHTML='';el('read-status').textContent='Loading table rows…';el('cancel-search').disabled=false;el('cancel-search').hidden=false;el('next-page').disabled=true;el('previous-page').disabled=true;el('data-paging').hidden=true;el('retry-read').hidden=true;
    try{
      const result=await scanTable(t.id,el('table-query').value,page,progress=>{if(epoch===viewEpoch)el('read-status').textContent='Searching published rows… '+progress.scanned_rows+' of '+progress.total_rows+' scanned';},controller.signal);
      if(epoch!==viewEpoch)return;lastResult=result;
      const range=result.rows.length?'Showing '+(page*PAGE_ROWS+1)+'–'+(page*PAGE_ROWS+result.rows.length)+' of '+result.total_matches+(el('table-query').value?' matching rows':' published rows'):'No rows on this page · '+result.total_matches+' matching rows';
      el('read-status').textContent=result.total_matches?range: isReference(t)?'No matching reference definition in this export. Try an exact code or another spelling.':'No matching published rows. Try an exact source-field name or another spelling.';
      renderRows();el('next-page').disabled=(page+1)*PAGE_ROWS>=result.total_matches;el('previous-page').disabled=page===0;el('data-paging').hidden=page===0&&result.total_matches<=PAGE_ROWS;
    }catch(error){if(epoch===viewEpoch){el('read-status').textContent=error.message.replace(/shard/gi,'table part')+'. Keep the HTML and accompanying data folder/files together, then try again to complete the search.';el('rows').innerHTML='';el('retry-read').hidden=false;}}
    finally{if(epoch===viewEpoch){el('cancel-search').disabled=true;el('cancel-search').hidden=true;}}
  }
  function detailMode(active){document.body.classList.toggle('detail-mode',active);}
  function open(tableId,restore=false,query='',controlId=null){
    const next=c.tables.find(t=>t.id===tableId)||null;
    if(!restore&&next&&!selected){libraryReturn={tableId,controlId,x:window.scrollX,y:window.scrollY};saveState(true);}
    controller?.abort();cancel();viewEpoch++;selected=next;lastResult=null;
    el('table-detail').hidden=!selected;el('library').hidden=!!selected;detailMode(!!selected);if(!selected)return;
    if(!restore){page=0;el('table-query').value=query;exactColumns=false;}
    const t=selected,[label,purpose]=content(t);
    el('table-title').textContent=t.title;el('table-purpose').textContent=descriptions[t.id]?purpose:(t.row_grain||'Row meaning not supplied. Inspect the column meanings before interpreting this output.');
    const cues=[];
    if(isReference(t))cues.push('Reference definitions do not establish observed tests, categories or result values.');
    else if(t.id==='column_profiles'||t.id==='damyda_numeric_fields')cues.push('Counts and summaries describe stored source records, not unique people or clinical reference ranges. Missing values are not zero.');
    else if(t.id==='lab_npu_code_coverage')cues.push('<a href="DALYCARE_outputs.html?table=npu_display_dictionary">Reviewed laboratory reference definitions</a> explain meanings, not observed availability.');
    else if(t.id==='semantic_code_map')cues.push('Code values are withheld. <a href="DALYCARE_outputs.html?table=clinical_display_dictionary">Reviewed reference definitions</a> explain code meanings.');
    if(t.complete!==true&&readable(t))cues.push('Only the published rows in this export are searchable; original scope is limited or unknown.');
    el('table-cue').innerHTML=cues.join(' ');el('table-cue').hidden=!cues.length;
    el('table-state').textContent=label;el('table-scope').textContent=t.complete===true?'All approved output rows are represented. Search covers these published rows.':'Limited or unknown original scope. Search covers only published rows in this export.';
    el('table-metadata').innerHTML='<dl>'+[['Exact table ID',t.id],['Export state',statusLabels[t.status]||'Unavailable'],['Publication reason',t.reason],['Source file',t.source_file],['Run',c.run_id],['Source terms',(t.source_terms||[]).join(', ')],['Row grain',t.row_grain],['Count basis',formatValue(t.count_basis,'count_basis')],...(formatValue(t.count_basis,'count_basis')!==t.count_basis?[['Raw count basis',t.count_basis]]:[]),['CSV source rows',count(t.source_row_count)],['Represented rows',count(t.represented_row_count)],['Evidence origin',originLabels[t.provenance]||'Not supplied']].map(([label,value])=>'<dt>'+label+'</dt><dd>'+escape(value===0?0:value||'Not supplied')+'</dd>').join('')+'</dl>';
    el('column-meanings').innerHTML=t.columns.map(c=>'<article><strong>'+escape(c.label||c.key)+'</strong> <code>'+escape(c.key)+'</code><p>'+escape(c.definition||'Definition not supplied')+'</p>'+['type','unit','denominator','scope','missing_rule'].filter(k=>c[k]!==undefined).map(k=>'<p><small>'+escape(k.replace('_',' '))+': '+escape(c[k])+'</small></p>').join('')+'</article>').join('')||'<p>No public column definitions supplied for this output.</p>';
    const canRead=readable(t);el('row-controls').hidden=!canRead;el('unreadable-status').hidden=canRead;el('unreadable-status').textContent=(statusLabels[t.status]||'Unavailable')+': '+(t.reason|| (t.status==='empty_output'?'This output contains no rows.':'Table rows are not included in this export.'));
    el('rows').innerHTML='';el('read-status').textContent='';el('retry-read').hidden=true;el('data-paging').hidden=true;el('exact-columns').hidden=!canRead||!primary[t.id];
    if(!restore)saveState();el('table-title').focus();if(canRead)readPage();
  }
  function showLibrary(){controller?.abort();cancel();viewEpoch++;selected=null;lastResult=null;el('table-detail').hidden=true;el('library').hidden=false;detailMode(false);}
  function clearFilters(){for(const name of ['metadata-query','group-filter','availability-filter'])el(name).value='';listPage=0;libraryReturn=null;}
  for(const key of Object.keys(tasks))el('task-'+key).addEventListener('click',()=>{view=key;clearFilters();list();saveState();});
  el('clear-filters').addEventListener('click',()=>{clearFilters();list();saveState();});
  el('metadata-query').addEventListener('input',()=>{libraryReturn=null;listPage=0;view='all';list();saveState(true);});
  for(const name of ['group-filter','availability-filter'])el(name).addEventListener('change',()=>{libraryReturn=null;listPage=0;view='all';list();saveState();});
  for(const [name,delta] of [['catalogue-previous',-1],['catalogue-next',1]])el(name).addEventListener('click',()=>{listPage=Math.max(0,listPage+delta);libraryReturn=null;list();saveState();el('task-title').setAttribute('tabindex','-1');el('task-title').focus();});
  for(const [control,tableId] of searchTargets)el(control).addEventListener('click',()=>open(tableId,false,el('metadata-query').value.trim(),control));
  el('search-table').addEventListener('submit',event=>{event.preventDefault();page=0;saveState();readPage();});
  el('retry-read').addEventListener('click',readPage);el('cancel-search').addEventListener('click',()=>controller?.abort());
  el('exact-columns').addEventListener('click',()=>{exactColumns=!exactColumns;renderRows();saveState(true);});
  for(const [name,delta] of [['previous-page',-1],['next-page',1]])el(name).addEventListener('click',()=>{page=Math.max(0,page+delta);saveState();readPage();});
  el('back-library').addEventListener('click',()=>{showLibrary();saveState();list();if(!restoreLibraryPosition())el('metadata-query').focus();});
  function restore(event){
    const p=new URLSearchParams(window.location.search),saved=window.history.state?.outputsLibraryReturn;
    libraryReturn=saved&&id(saved.tableId)&&Number.isFinite(saved.x)&&Number.isFinite(saved.y)&&(!saved.controlId||searchTargets.some(([control])=>control===saved.controlId))?saved:null;
    view=own(tasks,p.get('view'))?p.get('view'):(p.get('q')||p.get('group')||p.get('status')?'all':'fields');listPage=Math.max(0,Math.floor(Number(p.get('listpage'))||1)-1);
    el('metadata-query').value=p.get('q')||'';el('group-filter').value=groups.includes(p.get('group'))?p.get('group'):'';el('availability-filter').value=own(statusLabels,p.get('status'))?p.get('status'):'';
    el('table-query').value=p.get('search')||'';page=Math.max(0,Math.floor(Number(p.get('page'))||1)-1);exactColumns=p.get('columns')==='all';list();
    if(p.get('table'))open(p.get('table'),true);else{showLibrary();if(!restoreLibraryPosition()&&event)el('metadata-query').focus();}
  }
  window.addEventListener('popstate',restore);restore();if(document.documentElement)document.documentElement.dataset.atlasReady='outputs';
})(window,document);
