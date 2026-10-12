(function (window,document) {
  'use strict';
  const MAX_BYTES=262144,MAX_ROWS=250,CACHE_BYTES=1048576,PAGE_ROWS=50;
  const cache=new Map(); let cacheBytes=0,activeTable=null,pending=null,scanEpoch=0;
  const own=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
  const categoryProfiles=new Set(['damyda_clinical_profile','lyfo_clinical_profile','cll_clinical_profile']);
  // Verbatim labels from the reviewed clinical_display_dictionary. Match exact source and field only.
  const fieldLabels={
    RKKP_DaMyDa:{Stadie:'Recorded myeloma stage',Reg_Knogleforandringer:'Bone changes',Reg_Amyloidose:'Amyloidosis field',IND_Relaps:'Relapse field',Cyto_FishUdfoert:'FISH test performed',Reg_PerformanceStatus:'Performance status',Reg_Mkomponent:'Monoclonal protein (M-protein) field',Reg_TidligereMGUS:'Previous MGUS field',Charlson_Index:'Charlson comorbidity index',Reg_Haemoglobin:'Haemoglobin',Reg_Creatinin_mikmoll:'Creatinine',Reg_LDH:'Lactate dehydrogenase (LDH)',Reg_CReaktivtProtein_gl:'C-reactive protein (CRP)',Reg_IgG_gl:'Immunoglobulin G (IgG)',Reg_IgA_gl:'Immunoglobulin A (IgA)',Reg_IgM_gl:'Immunoglobulin M (IgM)',Reg_Albumin_gl:'Albumin',Reg_PlasmaMKomponent:'Plasma monoclonal protein (M-protein)',Reg_CalciumIoniseret:'Ionised calcium',Reg_FrieKappaKaeder:'Free kappa light chains',Reg_FrieLambdaKaeder:'Free lambda light chains',Reg_Beta2Microglobulin_gl:'Beta-2 microglobulin',Reg_ProcentKlonalePlasmaceller:'Clonal plasma-cell percentage',Reg_CalciumAlbuminkorrigeret:'Albumin-corrected calcium'},
    RKKP_LYFO:{subtype:'Lymphoma subtype',Reg_Stadium:'Recorded lymphoma stage',IPI:'International Prognostic Index (IPI)',Reg_BSymptomer:'B symptoms',Reg_PerformanceStatusWHO:'WHO performance status',Reg_BulkSygdom:'Bulky disease'},
    RKKP_CLL:{Reg_BinetStadium:'Binet stage',Reg_Umuteret:'IGHV mutation-status field',Reg_FISH:'FISH result field',Reg_Del13q14:'Chromosome 13q14 deletion field',Reg_Del11q:'Chromosome 11q deletion field',Reg_Del17p:'Chromosome 17p deletion field',Reg_Trisomi12:'Trisomy 12 field',Reg_TP53:'TP53 field',Reg_Performancestatus:'Performance status',Reg_ZAP70:'ZAP-70 marker field',Reg_CD38Positiv:'CD38 positivity field',Reg_Beta2Microglobulin:'Beta-2 microglobulin field'}
  };
  const sourceLabels={RKKP_DaMyDa:'Myeloma registry',RKKP_LYFO:'Lymphoma registry',RKKP_CLL:'CLL registry'};
  const fieldKey=row=>own(row,'column_name')?row.column_name:own(row,'source_column')?row.source_column:own(row,'date_column')?row.date_column:row.region_column;
  function fieldLabel(row){
    const c=window.DALYCARE_OUTPUT_CATALOGUE,field=fieldKey(row),sourceName=row.table_name;
    // Only old catalogues use the copied registry fallback. New maps are exact,
    // and invalid or missing entries retain the raw identity in the reader.
    const labels=c&&own(c,'field_labels')?c.field_labels:fieldLabels;
    const record=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
    const safeKey=value=>typeof value==='string'&&value.trim()&&!['__proto__','constructor','prototype'].includes(value);
    if(!record(labels)||!safeKey(sourceName)||!safeKey(field)||!own(labels,sourceName))return '';
    const source=labels[sourceName];
    if(!record(source)||!own(source,field))return '';
    const label=source[field];return typeof label==='string'&&label.trim()?label:'';
  }
  const sourceLabel=source=>own(sourceLabels,source)?sourceLabels[source]:'';
  const fieldTable=tableId=>categoryProfiles.has(tableId)||['column_profiles','columns','damyda_numeric_fields'].includes(tableId);
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
  async function scanTable(tableId,query,page,onProgress,signal,criteria={}) {
    const {t}=tableFor(tableId);selectTable(tableId);cancel();const epoch=scanEpoch;
    const check=()=>{if(signal?.aborted || epoch!==scanEpoch || activeTable!==tableId)throw new Error('Search incomplete: cancelled');};
    const abort=()=>{if(epoch===scanEpoch)cancel();};signal?.addEventListener('abort',abort,{once:true});
    let scanned=0,matches=0;const rows=[],start=Math.max(0,Number.isFinite(Number(page))?Math.floor(Number(page)):0)*PAGE_ROWS;
    const needle=String(query||'').toLocaleLowerCase();
    try {
      check();
      if(!needle&&!criteria.source&&!criteria.field) {
        const total=t.shards.reduce((n,s)=>n+s.rows,0);let offset=0;
        for(const shard of t.shards){check();if(offset<start+PAGE_ROWS && offset+shard.rows>start){const data=await loadShard(tableId,shard.id);check();for(let i=Math.max(0,start-offset);i<data.length && rows.length<PAGE_ROWS;i++)rows.push(data[i]);scanned+=data.length;}offset+=shard.rows;}
        return {rows,total_matches:total,scanned_rows:scanned,complete:true};
      }
      for(const shard of t.shards){check();const data=await loadShard(tableId,shard.id);check();for(const row of data){
        const inScope=(!criteria.source||row.table_name===criteria.source)&&(!criteria.field||fieldKey(row)===criteria.field);
        const namesOnly=criteria.fieldNames===true&&fieldTable(tableId),alias=fieldTable(tableId)?[fieldLabel(row),own(sourceLabels,row.table_name)?sourceLabels[row.table_name]:''].join(' '):'';
        const matchesQuery=!needle||(namesOnly?[fieldKey(row),fieldLabel(row)].some(value=>String(value||'').toLocaleLowerCase().includes(needle)):t.columns.some(c=>row[c.key]!==null&&String(row[c.key]).toLocaleLowerCase().includes(needle))||alias.toLocaleLowerCase().includes(needle));
        if(inScope&&matchesQuery){if(matches>=start&&rows.length<PAGE_ROWS)rows.push(row);matches++;}
      }scanned+=data.length;onProgress?.({scanned_rows:scanned,total_rows:t.shards.reduce((n,s)=>n+s.rows,0)});}
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
    damyda_numeric_fields:['Field coverage','Inspect recorded availability, configured units, and the publication status of stored summaries.'],
    damyda_clinical_profile:['Registry fields','Find selected myeloma fields and inspect their recorded availability. Category distributions are subject to withholding.'],
    lyfo_clinical_profile:['Registry fields','Find selected lymphoma fields and inspect their recorded availability. Category distributions are subject to withholding.'],
    cll_clinical_profile:['Registry fields','Find selected CLL fields and inspect their recorded availability. Category distributions are subject to withholding.'],
    sources:['Source inventory','Inspect source sizes and load/profile status.'],
    registry_clinical_summary:['Registry sources','Inspect source-record and field counts; ID counts are not validated patient totals.'],
    source_resolution:['Resolution status','Check whether configured sources were found; this does not establish completeness.'],
    atlas_module_readiness:['Evidence readiness','Inspect module and source readiness; this is not clinical completeness.'],
    atlas_temporal_coverage_years:['Recorded years','Inspect source records by selected date-field year and the supplied evidence basis.'],
    atlas_temporal_coverage:['Date-field availability','Inspect the selected date field and supplied availability for each source.'],
    atlas_spatial_region_counts:['Recorded regions','Inspect counts by source and recorded region field; location meaning depends on that field.'],
    atlas_spatial_region_coverage:['Regional coverage status','Inspect region/domain status; any source total is domain-wide and repeated across regions.'],
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
  const readingTitles={column_profiles:'Field availability and summaries',columns:'Field types and missingness',damyda_numeric_fields:'Myeloma numeric-field coverage',damyda_clinical_profile:'Myeloma registry fields',lyfo_clinical_profile:'Lymphoma registry fields',cll_clinical_profile:'CLL registry fields'};
  const tableTitle=t=>readingTitles[t.id]||t.title;
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
  let selected=null,page=0,controller=null,viewEpoch=0,libraryReturn=null,view='fields',listPage=0,exactColumns=false,lastResult=null,lastReadState=null,rowScope={},fieldNameOnly=false,appliedQuery='',coverageSource='',coverageQuery='',coverageExplicit=false,sourceInventory=null,coverageRunning=false;
  const LIST_ROWS=12;
  if('scrollRestoration' in window.history)window.history.scrollRestoration='manual';
  const count=value=>value===null||value===undefined?'Not supplied':formatValue(value);
  function saveState(replace=false){
    const p=new URLSearchParams();
    if(view!=='fields'||el('metadata-query').value)p.set('view',view);
    if(listPage)p.set('listpage',listPage+1);
    if(el('metadata-query').value)p.set('q',el('metadata-query').value);
    if(el('group-filter').value)p.set('group',el('group-filter').value);
    if(el('availability-filter').value)p.set('status',el('availability-filter').value);
    if(view==='timeplace'){if(coverageSource)p.set(selected?'returnsource':'source',coverageSource);if(coverageQuery)p.set('findsource',coverageQuery);}
    if(selected){p.set('table',selected.id);if(appliedQuery)p.set('search',appliedQuery);if(fieldNameOnly)p.set('searchmode','fields');if(page)p.set('page',page+1);if(exactColumns)p.set('columns','all');if(rowScope.source)p.set('source',rowScope.source);if(rowScope.field)p.set('field',rowScope.field);}
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
    document.body.classList.toggle('coverage-mode',view==='timeplace');el('coverage-workspace').hidden=view!=='timeplace';
    el('catalogue-search-label').textContent=view==='fields'?'Find a field in published rows':'Search table names and descriptions';
    el('catalogue-search-help').textContent=view==='fields'?'Search exact field names and reviewed labels across sources.':'This searches table names and descriptions. Row searches are available below.';
    el('catalogue-search-submit').textContent=view==='fields'?'Find fields':'Find tables';
    el('metadata-query').placeholder=view==='fields'?'Try creatinine, height, or an exact field name':'Try a table name or exact table ID';
    const tables=c.tables.filter(t=>(view==='all'||(view==='technical'?!researchIds.has(t.id):task.ids.includes(t.id)))&&(!g||t.group===g)&&(!s||t.status===s)&&(view==='fields'||[t.id,t.title,tableTitle(t),t.group,t.source_file,t.kind,t.row_grain,...(t.source_terms||[]),...(t.columns||[]).flatMap(c=>[c.key,c.label,c.definition])].some(value=>String(value||'').toLocaleLowerCase().includes(q))));
    if(task.ids)tables.sort((a,b)=>task.ids.indexOf(a.id)-task.ids.indexOf(b.id));
    listPage=Math.min(listPage,Math.max(0,Math.ceil(tables.length/LIST_ROWS)-1));
    const start=listPage*LIST_ROWS,shown=tables.slice(start,start+LIST_ROWS);
    el('table-list').innerHTML=shown.map(t=>{const [label,purpose]=content(t);return '<button type="button" class="table-card" data-table="'+escape(t.id)+'"><span class="card-content-label">'+escape(label)+'</span><strong>'+escape(tableTitle(t))+'</strong><span>'+escape(purpose)+'</span><small class="card-action">'+(readable(t)?categoryProfiles.has(t.id)?'Inspect fields':'Open table':'Inspect export status')+' →</small></button>';}).join('')||'<p class="empty-catalogue">No table names or descriptions match. Try a row search above, clear filters, or choose All outputs.</p>';
    el('table-list').querySelectorAll('[data-table]').forEach(button=>button.addEventListener('click',()=>open(button.dataset.table)));
    el('task-title').textContent=task.title;el('task-description').textContent=task.description;
    Object.keys(tasks).forEach(key=>el('task-'+key).setAttribute('aria-pressed',String(view===key)));
    el('outputs-status').textContent=(tables.length?'Showing '+(start+1)+'–'+(start+shown.length)+' of '+tables.length:'0')+' outputs'+(view==='all'?' in the complete inventory':'');
    el('catalogue-previous').disabled=listPage===0;el('catalogue-next').disabled=start+LIST_ROWS>=tables.length;el('catalogue-paging').hidden=tables.length<=LIST_ROWS;
    el('catalogue-page').textContent='Page '+(listPage+1)+' of '+Math.max(1,Math.ceil(tables.length/LIST_ROWS));
    el('clear-filters').hidden=!(q||g||s);el('applied-filters').hidden=!(g||s);el('applied-filters').textContent=[g&&'Group: '+g,s&&'State: '+statusLabels[s]].filter(Boolean).join(' · ');
    let actions=0;for(const [control,tableId] of searchTargets){const t=c.tables.find(t=>t.id===tableId);el(control).hidden=!q||!t||!readable(t);if(!el(control).hidden)actions++;}
    el('query-actions').hidden=!actions||view==='fields'||view==='timeplace';el('query-action-label').textContent='Look for “'+el('metadata-query').value.trim()+'” inside published rows:';
  }
  const cell=(row,key)=>escape(formatValue(row[key],key,row));
  const supplied=(row,key)=>row[key]!==null&&row[key]!==undefined&&row[key]!=='';
  const line=(label,value)=>'<span class="cell-line"><span class="cell-key">'+escape(label)+': </span>'+value+'</span>';
  const percentKeys=new Set(['pct_rows','pct_available','pct_missing']);
  const statisticKeys=new Set(['mean','median','p25','p75']);
  const countKeys=new Set(['n_rows','n_cols','n_available','n_missing','n_distinct_capped','n_observed','n_patients','n']);
  function readingCell(row,key){
    const value=row[key];
    if(typeof value!=='number'||!Number.isFinite(value)||(!percentKeys.has(key)&&!statisticKeys.has(key)&&!countKeys.has(key)))return cell(row,key);
    const tiny=value!==0&&Math.abs(value)<(percentKeys.has(key)?0.1:0.01);
    const options=tiny?{maximumSignificantDigits:3}:percentKeys.has(key)?{minimumFractionDigits:1,maximumFractionDigits:1}:statisticKeys.has(key)?{maximumFractionDigits:2}:{maximumFractionDigits:20};
    let displayed=value.toLocaleString('en-US',options)+(percentKeys.has(key)?'%':'');
    if(percentKeys.has(key)&&value<100&&displayed==='100.0%')displayed='<100%';
    return '<span title="Exact supplied value: '+escape(value)+'">'+escape(displayed)+'</span>';
  }
  function readingLabel(key){
    const c=selected.columns.find(c=>c.key===key),fallback={n_rows:'Source records',n_cols:'Fields',n_missing:'Missing source records',pct_missing:'Missing source records (%)',n_distinct_capped:'Distinct values (capped)'};
    // Keep reviewed semantic labels; replace only generated key labels for counts.
    if(fallback[key]&&(!c?.label||c.label===key||c.label.toLocaleLowerCase()===key.replaceAll('_',' ').toLocaleLowerCase()))return fallback[key];
    return c?.label||key.replaceAll('_',' ');
  }
  const lines=(row,keys)=>keys.filter(key=>own(row,key)&&(!key.endsWith('_privacy_status')||supplied(row,key))).map(key=>line(readingLabel(key),readingCell(row,key))).join('');
  const fieldIdentity=(row,field='column_name')=>'<strong>'+escape(fieldLabel(row)||formatValue(row[field],field,row))+'</strong>'+(fieldLabel(row)?'<code class="cell-line">'+cell(row,field)+'</code>':'');
  const identity=(row,field='column_name')=>fieldIdentity(row,field)+line('Source',cell(row,'table_name'))+(fieldTable(selected?.id)&&!rowScope.source?sourceCoverageLink(row.table_name):'');
  function availability(row){
    if(row.n_available===null&&row.pct_available===null&&own(privacyLabels,row.availability_privacy_status))return cell(row,'n_available')+(own(row,'n_rows')?line('Source records',readingCell(row,'n_rows')):'');
    let html=own(row,'n_available')?line('With a value',readingCell(row,'n_available')+(own(row,'n_rows')?' of '+readingCell(row,'n_rows')+' source rows':' source rows')):'';
    if(own(row,'pct_available'))html+=line('Supplied percentage',readingCell(row,'pct_available'));
    return html||'Availability not supplied';
  }
  const isFieldEvidence=()=>selected?.id==='column_profiles'&&!!rowScope.source&&!!rowScope.field;
  function fieldAvailability(row){
    const metrics=['n_available','pct_available','n_missing','pct_missing'],reason=row.availability_privacy_status;
    const value=key=>supplied(row,key)?readingCell(row,key):own(privacyLabels,reason)?cell(row,key):'Not supplied';
    if(!metrics.some(key=>supplied(row,key)))return '<p>'+(own(privacyLabels,reason)?'Recorded availability '+escape(privacyLabels[reason].replace(/^Withheld:/,'withheld:')):'Recorded availability not supplied')+'</p>'+line('Source records',value('n_rows'))+(reason&&!own(privacyLabels,reason)?line('Supplied availability status',cell(row,'availability_privacy_status')):'');
    return line('With a value',value('n_available')+(supplied(row,'n_available')&&supplied(row,'n_rows')?' of '+readingCell(row,'n_rows')+' source records':''))+line('Supplied share',value('pct_available'))+line('Without a value',value('n_missing'))+line('Supplied missing share',value('pct_missing'))+(!supplied(row,'n_available')||!supplied(row,'n_rows')?line('Source records',value('n_rows')):'')+(reason&&!own(privacyLabels,reason)?line('Supplied availability status',cell(row,'availability_privacy_status')):'');
  }
  function fieldSummary(row){
    let html='';
    if(hasSummary(row))for(const [key,label] of [['median','Median'],['p25','25th percentile'],['p75','75th percentile'],['mean','Mean']])if(own(row,key))html+=line(label,readingCell(row,key));
    const reason=row.numeric_privacy_status;
    if(reason&&reason!=='eligible_stored_summary')html+=own(reviewedLabels.numeric_privacy_status,reason)?'<p>'+cell(row,'numeric_privacy_status')+'</p>':line('Supplied summary status',cell(row,'numeric_privacy_status'));
    else if(!hasSummary(row))html='<p>No stored numeric summary supplied.</p>';
    return html;
  }
  function fieldProfileContext(row){
    let html=lines(row,['domain','subdomain','atlas_role','profile_kind'].filter(key=>supplied(row,key)));
    html+=supplied(row,'summary_scope')?line('Supplied summary scope',cell(row,'summary_scope')):'<span class="cell-line">Summary scope not supplied.</span>';
    html+=supplied(row,'summary_method')?line('Supplied summary method',cell(row,'summary_method')):'<span class="cell-line">Summary method not supplied.</span>';
    for(const key of ['summary_caveat','summary_caveats'])if(supplied(row,key))html+=line('Supplied summary caveat',cell(row,key));
    return html;
  }
  function renderFieldProfiles(rows){
    const multiple=lastResult.total_matches>1;
    return rows.map((row,index)=>'<article class="field-profile">'+(multiple?'<h3>Profile row '+(lastReadState.page*PAGE_ROWS+index+1)+'</h3>':'')+'<div class="field-evidence-pair"><section><h3>Recorded availability</h3>'+fieldAvailability(row)+'</section><section><h3>Stored summary</h3>'+fieldSummary(row)+'</section></div><div class="field-profile-context">'+fieldProfileContext(row)+'</div></article>').join('');
  }
  const hasSummary=row=>['median','p25','p75','mean'].some(key=>supplied(row,key));
  function summaryValues(row){
    let html='';
    if(hasSummary(row)){for(const [key,label] of [['median','Median'],['p25','25th percentile'],['p75','75th percentile'],['mean','Mean']])if(own(row,key))html+=line(label,readingCell(row,key));}
    else if(row.numeric_privacy_status&&row.numeric_privacy_status!=='eligible_stored_summary')html=cell(row,'numeric_privacy_status');
    else html='No stored numeric summary supplied';
    if(hasSummary(row)&&row.numeric_privacy_status&&row.numeric_privacy_status!=='eligible_stored_summary')html+=line('Summary status',cell(row,'numeric_privacy_status'));
    return html+summaryScope(row);
  }
  function summaryScope(row){
    if(!hasSummary(row)||row.profile_kind==='categorical')return '';
    const knownMethods=['supplied_mean_and_quantiles','supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample'];
    let note=row.summary_method===knownMethods[1]||row.summary_caveat==='quantiles_may_use_bounded_stream_sample'||row.summary_caveats==='quantiles_may_use_bounded_stream_sample'?'<span class="cell-line">Quartiles may use a sample of source records.</span>':'';
    if(!supplied(row,'summary_method'))note+='<span class="cell-line">Summary method not supplied.</span>';
    else if(!knownMethods.includes(row.summary_method))note+=line('Supplied method',cell(row,'summary_method'));
    if(!supplied(row,'summary_scope'))note+='<span class="cell-line">Summary scope not supplied.</span>';
    else if(row.summary_scope!=='stored_source_row_profile')note+=line('Supplied scope',cell(row,'summary_scope'));
    return note;
  }
  function coverageShare(row,kind){
    const knownYear=['event_date_counts','streamed_event_date_counts'].includes(row.coverage_basis);
    const directRegion=['region_column_counts','streamed_region_column_counts'].includes(row.count_basis);
    const registryRegion=row.count_basis==='registry_region_panel';
    const denominator=kind==='year'&&knownYear?'Denominator: all source records, including missing, unparseable or out-of-window dates.':kind==='region'&&directRegion?'Denominator: all source records.':kind==='region'&&registryRegion?'Denominator: retained normalized registry-region counts; missing, unmapped or suppressed categories may be excluded.':'The percentage denominator is not supplied for this evidence basis.';
    return lines(row,['n_rows'])+line('Supplied share',readingCell(row,'pct_rows'))+'<span class="cell-line">'+denominator+'</span>';
  }
  function regionBasis(row){
    const labels={region_column_counts:'Recorded region-field counts',streamed_region_column_counts:'Recorded region-field counts (streamed)',registry_region_panel:'Retained registry-region categories'};
    return escape(labels[row.count_basis]||row.count_basis||'Basis not supplied');
  }
  // Names already reviewed in the Clinical explorer. Unknown names retain exact identifiers.
  Object.assign(sourceLabels,{SP_AlleProvesvar:'Hospital laboratory results (SP)',SDS_lab_forsker:'National laboratory data (SDS)',biochemistry:'PERSIMUNE biochemistry',SP_AdministreretMedicin:'Administered medicines (SP)',SP_OrdineretMedicin:'Prescribed medicines (SP)',SP_ADT_haendelser:'Admissions, discharges and transfers (SP)',SP_VitaleVaerdier:'Vital signs (SP)',SP_SocialHX:'Social history (SP)',SP_ITAOphold:'Intensive care stays (SP)',CLLPANEL_WIDE:'CLL molecular-marker dataset',CLL_TREAT:'CLL treatment dataset',CLL_TREAT_IBRUTINIB:'CLL ibrutinib treatment dataset',SP_Behandlingsplaner_Del1:'Treatment plans — part 1 (SP)',Behandlingsplaner_del2:'Treatment plans — part 2 (SP)',SP_Journalnotater_Del1:'Clinical notes — part 1 (SP)',Journalnotater_del2:'Clinical notes — part 2 (SP)',SP_PatientInfo:'Patient information (SP)',Flytningshistorik:'Patient movement history (SP)',SP_BilleddiagnostikeUndersoegelser_Del1:'Imaging examinations — part 1 (SP)',SP_BilleddiagnostikeUndersoegelser_Del2:'Imaging examinations — part 2 (SP)',microbiology_analysis:'Microbiology analyses',microbiology_culture:'Microbiology cultures',microbiology_culture_resistance:'Antimicrobial susceptibility',microbiology_microscopy:'Microbiology microscopy',SDS_pato:'Pathology records (SDS)',BIOBANK_SAMPLES:'Biobank samples',SDS_diagnoser:'Diagnoses (LPR3)',SDS_t_diag:'Diagnoses (LPR)',SDS_procedurer_kirurgi:'Surgical procedures (LPR3)',SDS_procedurer_andre:'Other procedures (LPR3)'});
  const coverageIds=['sources','atlas_temporal_coverage','atlas_temporal_coverage_years','atlas_spatial_region_counts'];
  // In addition to the unchanged 1 MiB shard cache, retain at most 512 KiB / 2,048 aggregate rows.
  // These four reviewed aggregates total about 300 KiB / 965 rows in this export.
  const COVERAGE_BYTES=524288,COVERAGE_ROWS=2048;
  const coverageFieldLabels={RKKP_CLL:{Reg_Diagnose_dt:'CLL diagnosis date'},RKKP_LYFO:{Reg_DiagnostiskBiopsi_dt:'Diagnostic biopsy date'},RKKP_DaMyDa:{Diagnosedato:'Diagnosis date'},SP_AdministreretMedicin:{taken_time:'Medication administration time'},SP_OrdineretMedicin:{order_start_time:'Prescription start time'},SP_ADT_haendelser:{kontakt_start_local_dttm:'Hospital contact start (local time)'},SP_AlleProvesvar:{specimn_taken_time:'Specimen collection time'},SP_BilleddiagnostikeUndersoegelser_Del1:{bestillingstidspunkt:'Imaging order time'},SP_BilleddiagnostikeUndersoegelser_Del2:{bestillingstidspunkt:'Imaging order time'},SP_Behandlingsplaner_Del1:{behandlingsstartdato:'Treatment start date'},SP_Bloddyrkning_Del3:{provetagningstidspunkt:'Blood culture specimen collection time'},SP_SocialHX:{registringsdato:'Social history recording date'},SP_VitaleVaerdier:{recorded_time:'Measurement recording time'},SDS_kontakter:{dato_start:'Contact start date'},SDS_t_sksube:{d_odto:'Procedure date'},SDS_procedurer_andre:{dato_start:'Procedure start date'},SDS_pato:{d_rekvdato:'Pathology request date'},SDS_lab_forsker:{samplingdate:'Specimen collection date'},SP_PatientInfo:{contact_date:'Hospital contact date'},microbiology_analysis:{samplerecieveddatetime:'Microbiology sample receipt time'},microbiology_culture:{samplerecieveddatetime:'Microbiology sample receipt time'},microbiology_microscopy:{samplerecieveddatetime:'Microbiology sample receipt time'},BIOBANK_SAMPLES:{date_samplecollection:'Sample collection date'},CLL_TREAT_IBRUTINIB:{date_diagnosis:'CLL diagnosis date'},SP_ITAOphold:{region_name:'Region name'}};
  function coverageField(row,key){const source=own(coverageFieldLabels,row.table_name)?coverageFieldLabels[row.table_name]:null,label=source&&own(source,row[key])?source[row[key]]:'';return (label?escape(label)+' ':'')+'<code>'+cell(row,key)+'</code>';}
  let coverageData=null,coverageExample=false;
  function evidenceLink(tableId,label,source='',field='',query='',namesOnly=false){
    const target=c.tables.find(t=>t.id===tableId);if(!target||tableId==='column_profiles'&&!readable(target))return '';
    const p=new URLSearchParams({view:'timeplace',table:tableId});if(source)p.set('source',source);if(field)p.set('field',field);if(query)p.set('search',query);if(namesOnly)p.set('searchmode','fields');if(coverageSource||source)p.set('returnsource',coverageSource||source);
    return '<a href="DALYCARE_outputs.html?'+escape(p.toString())+'">'+escape(label)+' →</a>';
  }
  function sourceCoverageLink(source){return supplied({source},'source')?'<a class="field-availability" href="DALYCARE_outputs.html?'+escape(new URLSearchParams({view:'timeplace',source}).toString())+'">Years and regions for this source →</a>':'';}
  function coveragePickerEntry(){el('coverage-tools').open=!coverageExplicit||!!coverageQuery||coverageExample;}
  function clearCoverageAnswer(){el('coverage-synopsis').innerHTML='';el('coverage-answer').innerHTML='';}
  function sourceChoices(){
    if(!sourceInventory)return;
    const allNames=[...new Set(sourceInventory.map(r=>r.table_name).filter(Boolean))],matches=name=>(sourceLabel(name)+' '+name).toLocaleLowerCase().includes(coverageQuery.trim().toLocaleLowerCase());
    if(coverageExplicit&&coverageSource&&(!allNames.includes(coverageSource)||!matches(coverageSource))){coverageQuery='';el('coverage-query').value='';}
    const names=allNames.filter(matches),unknown=coverageExplicit&&coverageSource&&!allNames.includes(coverageSource);
    names.sort((a,b)=>(sourceLabel(a)||a).localeCompare(sourceLabel(b)||b));
    if(!coverageExplicit&&!names.includes(coverageSource))coverageSource=['RKKP_DaMyDa','RKKP_CLL','RKKP_LYFO'].find(name=>names.includes(name))||names[0]||'';
    el('coverage-source').innerHTML=(unknown?'<option value="'+escape(coverageSource)+'">'+escape(coverageSource)+' · not present in this export</option>':'')+names.map(name=>'<option value="'+escape(name)+'">'+escape(sourceLabel(name)?sourceLabel(name)+' · '+name:name)+'</option>').join('');el('coverage-source').value=coverageSource;
    if(unknown||!names.length||coverageQuery||coverageExample)el('coverage-tools').open=true;
    el('coverage-discovery').textContent=unknown?'The requested source is not present in the published inventory. Choose another source.':names.length?names.length+' matching sources'+(coverageExample?' · Showing an example source; choose the source for your question.':''):'No source names match. Try an exact identifier or another term.';
  }
  function disclosure(row){return ['count_privacy_status','availability_privacy_status','value_privacy_status','date_privacy_status'].filter(key=>supplied(row,key)).map(key=>cell(row,key)).filter((v,i,a)=>a.indexOf(v)===i).join(' · ');}
  function denominator(row,kind){
    if(kind==='year'&&['event_date_counts','streamed_event_date_counts'].includes(row.coverage_basis))return 'Supplied shares use all source records, including missing, unparseable or out-of-window dates.';
    if(kind==='region'&&['region_column_counts','streamed_region_column_counts'].includes(row.count_basis))return 'Supplied shares use all source records.';
    if(kind==='region'&&row.count_basis==='registry_region_panel')return 'Supplied shares use retained normalized registry-region counts; missing, unmapped or suppressed categories may be excluded.';
    return 'The percentage denominator is not supplied for this evidence basis.';
  }
  function coverageGroups(rows,kind){
    const groups=new Map(),field=kind==='year'?'date_column':'region_column',basis=kind==='year'?'coverage_basis':'count_basis';
    for(const row of rows){const key=JSON.stringify([row.table_name,row[field],row[basis]]);if(!groups.has(key))groups.set(key,[]);groups.get(key).push(row);}
    return [...groups.values()];
  }
  function evidenceGroups(rows,kind){
    const field=kind==='year'?'date_column':'region_column',basis=kind==='year'?'coverage_basis':'count_basis';
    return coverageGroups(rows,kind).map(group=>{
      const first=group[0],range=kind==='year'&&first.coverage_basis==='source_date_range',observed=kind==='year'?['event_date_counts','streamed_event_date_counts'].includes(first.coverage_basis):['region_column_counts','streamed_region_column_counts','registry_region_panel'].includes(first.count_basis);
      const keys=new Map();for(const row of group){const key=JSON.stringify(kind==='year'?row.year:[row.region_code,row.region_name]);keys.set(key,(keys.get(key)||0)+1);}
      const sorted=kind==='year'?[...group].sort((a,b)=>Number(b.year)-Number(a.year)):group;
      const title=kind==='year'?(range?'Inferred source date range':first.coverage_basis==='streamed_event_date_counts'?'Recorded year counts (streamed)':observed?'Recorded year counts':'Unreviewed year evidence: '+cell(first,basis)):regionBasis(first);
      const meta='<p class="mini">'+coverageField(first,field)+' · '+title+'</p>';
      if(range)return '<section class="coverage-group">'+meta+'<p>Source range withheld. This does not establish recorded events or continuous coverage.</p></section>';
      return '<section class="coverage-group">'+meta+'<p class="mini">'+denominator(first,kind)+'</p><table class="coverage-values"><thead><tr><th scope="col">'+(kind==='year'?'Year':'Recorded region')+'</th><th scope="col">Source records</th><th scope="col">Supplied share</th></tr></thead><tbody>'+sorted.map(row=>{
        const key=JSON.stringify(kind==='year'?row.year:[row.region_code,row.region_name]),duplicate=keys.get(key)>1,guard=disclosure(row),protectedCount=row.count_privacy_status||row.value_privacy_status==='withheld_unvalidated_distribution'||row.date_privacy_status==='withheld_derived_source_range';
        const name=kind==='year'?(supplied(row,'year')?cell(row,'year'):'Year not supplied'):(supplied(row,'region_name')?cell(row,'region_name'):cell(row,'region_code'));
        const number=protectedCount?'Count withheld':readingCell(row,'n_rows');
        const share=protectedCount?'Not shown':readingCell(row,'pct_rows');
        return '<tr><th scope="row">'+name+(duplicate?'<small class="cell-line">Duplicate evidence; separate supplied row</small>':'')+'</th><td>'+number+'</td><td>'+share+'</td></tr>'+(guard?'<tr class="coverage-guard"><td colspan="3">'+guard+'</td></tr>':'');
      }).join('')+'</tbody></table><p class="coverage-links">'+evidenceLink(kind==='year'?'atlas_temporal_coverage_years':'atlas_spatial_region_counts','Exact '+(kind==='year'?'year':'region')+' evidence',coverageSource,first[field]||'')+' '+evidenceLink('column_profiles','Inspect this field',coverageSource,first[field]||'')+'</p></section>';
    }).join('');
  }
  function coverageAbsence(id,label){
    const descriptor=c.tables.find(t=>t.id===id);
    return coverageData[id].readable?(descriptor?.complete===true?'No '+label+' summary is published for this source.':'No '+label+' summary is present in these published rows; the original scope is limited or unknown.'):(statusLabels[descriptor?.status]||'Unavailable')+': the '+label+' summary is not available in this export.';
  }
  function coverageDimension(rows,kind){
    const field=kind==='year'?'date_column':'region_column',basis=kind==='year'?'coverage_basis':'count_basis',tableId=kind==='year'?'atlas_temporal_coverage_years':'atlas_spatial_region_counts';
    const groups=coverageGroups(rows,kind).map(group=>{
      const first=group[0],range=kind==='year'&&first.coverage_basis==='source_date_range';
      const label=kind==='year'?(range?'Source range withheld':first.coverage_basis==='streamed_event_date_counts'?'Recorded year counts (streamed)':first.coverage_basis==='event_date_counts'?'Recorded year counts':'Unreviewed year evidence: '+cell(first,basis)):regionBasis(first);
      const statuses=[...new Set(group.map(disclosure).filter(Boolean))];
      return '<div class="coverage-summary-group" data-coverage-field="'+escape(first[field]??'')+'" data-coverage-basis="'+escape(first[basis]??'')+'"><p>'+coverageField(first,field)+'</p><p class="mini">'+label+(range?'. This does not establish recorded events or continuous coverage.':'. Supplied rows; inspect individual counts.')+'</p>'+(statuses.length?'<p class="mini">Supplied publication statuses; inspect row-specific details: '+statuses.join(' · ')+'</p>':'')+'<p class="coverage-links">'+evidenceLink(tableId,'Exact '+(kind==='year'?'year':'region')+' evidence',coverageSource,first[field]||'')+' '+evidenceLink('column_profiles','Inspect this field',coverageSource,first[field]||'')+'</p></div>';
    }).join('');
    const scope=groups&&c.tables.find(t=>t.id===tableId)?.complete!==true?'<p class="mini">Published scope is limited or unknown.</p>':'';
    return '<section class="coverage-dimension" data-coverage-kind="'+kind+'"><h3>'+(kind==='year'?'Annual evidence':'Regional evidence')+'</h3>'+scope+(groups||'<p class="coverage-empty">'+escape(coverageAbsence(tableId,kind==='year'?'annual':'regional'))+'</p>')+'</section>';
  }
  function renderCoverage(){
    renderCoverageLinks();
    clearCoverageAnswer();
    if(!coverageData||!coverageSource)return;
    if(!sourceInventory.some(r=>r.table_name===coverageSource)){el('coverage-synopsis').innerHTML='<section class="coverage-source-summary"><p class="coverage-showing">Requested source: '+escape(coverageSource)+'</p><p>'+(c.tables.find(t=>t.id==='sources')?.complete===true?'This source is not present in this export.':'This source is not present in the published inventory; its scope is limited or unknown.')+' Its clinical data availability cannot be determined here. Choose another source to inspect published evidence.</p></section>';return;}
    const rows=id=>coverageData[id].rows.filter(r=>r.table_name===coverageSource),inventory=rows('sources'),dates=rows('atlas_temporal_coverage'),years=rows('atlas_temporal_coverage_years'),regions=rows('atlas_spatial_region_counts');
    const dateFacts=dates.length?dates.map(r=>!supplied(r,'date_column')?'<div class="coverage-date"><span>No date field identified in this export.</span></div>':'<div class="coverage-date"><strong>'+(supplied(r,'pct_available')?readingCell(r,'pct_available'):r.availability_privacy_status?cell(r,'availability_privacy_status'):'Availability not supplied')+'</strong><span>'+(supplied(r,'pct_available')?'Records with a date value · ':'')+coverageField(r,'date_column')+'</span></div>').join(''):'<div class="coverage-date"><span>Date-field availability is not supplied for this source.</span></div>';
    const dateStates=[...new Set(dates.filter(r=>supplied(r,'date_privacy_status')).map(r=>formatValue(r.date_privacy_status,'date_privacy_status')))];
    el('coverage-synopsis').innerHTML='<div class="coverage-identity">'+(coverageExample?'<p class="mini">Example source; choose the source for your question.</p>':'')+'<p class="coverage-showing">'+escape(sourceLabel(coverageSource)||coverageSource)+'</p>'+(sourceLabel(coverageSource)?'<code>'+escape(coverageSource)+'</code>':'')+'</div><div class="coverage-overview">'+coverageDimension(years,'year')+coverageDimension(regions,'region')+'</div><p class="mini">Years and regions are separate source-record summaries, not a combined cohort.</p>';
    el('coverage-answer').innerHTML='<details id="coverage-facts"><summary>Source facts and date availability</summary><div class="coverage-facts">'+inventory.map(r=>'<div><strong>'+(supplied(r,'n_rows')?readingCell(r,'n_rows'):'Not supplied')+'</strong><span>source records</span></div><div><strong>'+(supplied(r,'n_cols')?readingCell(r,'n_cols'):'Not supplied')+'</strong><span>source fields</span></div>').join('')+dateFacts+'</div><p class="mini">Counts describe source records, not unique people. A nonmissing date does not establish date validity.'+(dateStates.length?' '+escape(dateStates.join(' · '))+'.':'')+'</p><p class="coverage-links">'+evidenceLink('column_profiles','Fields in this source',coverageSource)+' '+evidenceLink('sources','Source details',coverageSource)+' '+evidenceLink('atlas_temporal_coverage','Date availability evidence',coverageSource)+'</p></details><div class="coverage-panels">'+(years.length?'<section aria-label="Annual evidence rows"><p class="mini">Individual published years, not a claim of continuous coverage.</p>'+evidenceGroups(years,'year')+'</section>':'')+(regions.length?'<section aria-label="Regional evidence rows"><p class="mini">Location meaning depends on the selected region field; residence or treatment location is not established.</p>'+evidenceGroups(regions,'region')+'</section>':'')+'</div><div class="coverage-hospitals"><p class="mini">Hospital field names can be checked across sources. Hospital names and counts are not supplied here.</p>'+evidenceLink('column_profiles','Find hospital fields across sources','','','hospital',true)+'</div>';
  }
  async function readCoverage(){
    controller?.abort();cancel();controller=new AbortController();const signal=controller.signal,epoch=++viewEpoch;coverageRunning=true;
    const check=()=>{if(signal.aborted||epoch!==viewEpoch||view!=='timeplace'||selected)throw new Error('Reading cancelled');};
    const abort=()=>{if(epoch===viewEpoch)cancel();};signal.addEventListener('abort',abort,{once:true});
    clearCoverageAnswer();el('coverage-status').textContent='Reading source summaries…';el('coverage-retry').hidden=true;el('coverage-cancel').hidden=false;
    try{
      if(!coverageData){
        const descriptors=coverageIds.map(id=>c.tables.find(t=>t.id===id)),shards=descriptors.flatMap(t=>t?.shards||[]);
        if(shards.reduce((n,s)=>n+s.rows,0)>COVERAGE_ROWS||shards.reduce((n,s)=>n+s.bytes,0)>COVERAGE_BYTES)throw new Error('Source summaries exceed the overview reading limit. Use the original tables below');
        const data={};for(const tableId of coverageIds){check();const t=c.tables.find(t=>t.id===tableId);data[tableId]={rows:[],readable:!!t&&readable(t)};if(data[tableId].readable){for(const shard of t.shards){check();const rows=await loadShard(tableId,shard.id);check();data[tableId].rows.push(...rows);}}if(tableId==='sources'){if(!data.sources.rows.length)throw new Error('Source inventory is unavailable in this export');sourceInventory=data.sources.rows;sourceChoices();}}
        check();coverageData=data;
      }
      check();sourceInventory=coverageData.sources.rows;sourceChoices();renderCoverage();el('coverage-status').textContent='';saveState(true);
    }catch(error){if(epoch===viewEpoch){clearCoverageAnswer();el('coverage-status').textContent=error.message+'. Source summaries are incomplete; no absence of evidence can be concluded. Keep the atlas files together and retry.';el('coverage-retry').hidden=false;}}
    finally{signal.removeEventListener('abort',abort);if(epoch===viewEpoch){coverageRunning=false;el('coverage-cancel').hidden=true;}}
  }
  function renderCoverageLinks(){el('coverage-evidence-links').innerHTML=tasks.timeplace.ids.map(id=>evidenceLink(id,tableTitle(c.tables.find(t=>t.id===id)||{id,title:id}))).join(' ');}
  function startCoverage(){
    el('coverage-query').value=coverageQuery;renderCoverageLinks();
    if(coverageData){sourceChoices();renderCoverage();el('coverage-status').textContent='';}else readCoverage();
  }
  // Primary columns compose existing values only. Exact columns remain available below the toggle.
  const primary={
    column_profiles:[['Source field','Exact field, source and profile kind',r=>identity(r)+line('Profile',cell(r,'profile_kind'))],['Availability','Source records, not people',availability],['Stored values','Supplied summaries, not reference ranges',summaryValues]],
    damyda_numeric_fields:[['Source field and unit','Configured unit, not harmonization',r=>identity(r,'source_column')+line('Field key',cell(r,'field'))+line('Unit',cell(r,'unit'))],['Availability','Supplied source-record availability',availability],['Stored values','Supplied summaries or withholding reason',summaryValues]],
    columns:[['Source field','Exact names',r=>identity(r)],['Field type','Supplied source typing',r=>lines(r,['column_type','column_class'])],['Missingness','Source records, not people',r=>lines(r,['n_missing','pct_missing','availability_privacy_status'])],['Distinctness and protection','Capped count, not a value list',r=>lines(r,['n_distinct_capped','is_sensitive','value_privacy_status'])]],
    sources:[['Source','Exact table and configured type',r=>'<strong>'+escape(sourceLabel(r.table_name)||r.table_name)+'</strong>'+line('Exact source',cell(r,'table_name'))+lines(r,['source_type','domain'])+sourceCoverageLink(r.table_name)+' '+evidenceLink('column_profiles','Fields in this source',r.table_name)],['Source size','Records and fields, not people',r=>lines(r,['n_rows','n_cols'])],['Load and profile','Supplied current-run status',r=>lines(r,['load_status','profile_mode'])],['Resolution','Finding a source is not completeness',r=>lines(r,['resolution_status','memory_status'])]],
    npu_display_dictionary:[['Code and meaning','Supplied reference entry',r=>'<strong>'+cell(r,'code')+'</strong>'+line('Meaning',cell(r,'label'))+(supplied(r,'label_da')?line('Danish label',cell(r,'label_da')):'')],['System and unit','As supplied by the dictionary',r=>lines(r,['system','system_spec','unit','property'])],['Definition','Reference meaning, not an observation',r=>cell(r,'definition')],['Reference source','Supplied provenance',r=>lines(r,['source_label','source_url','retrieved_on','note'])]],
    clinical_display_dictionary:[['Code and meaning','Supplied reference entry',r=>'<strong>'+cell(r,'code')+'</strong>'+line('Meaning',cell(r,'label'))+(supplied(r,'label_da')?line('Danish label',cell(r,'label_da')):'')],['Kind and system','Confirm the stated source/system',r=>lines(r,['kind','system'])],['Definition','Reference meaning, not an observation',r=>cell(r,'definition')],['Reference source','Supplied provenance',r=>lines(r,['source_label','source_url','retrieved_on','note'])]],
    atlas_temporal_coverage_years:[['Source and date field','Exact selected evidence field',r=>identity(r,'date_column')],['Recorded year','Selected date-field year',r=>cell(r,'year')],['Source records','Count and supplied percentage',r=>coverageShare(r,'year')],['Evidence basis','Interpret counts using this basis',r=>lines(r,['coverage_basis','availability_privacy_status','value_privacy_status'])]],
    atlas_temporal_coverage:[['Source and date field','Exact selected field',r=>identity(r,'date_column')],['Source records','Not unique people',r=>lines(r,['n_rows'])],['Date availability','Supplied percentage and status',r=>line('With a nonmissing date',readingCell(r,'pct_available'))+'<span class="cell-line">Share of profiled source records; this does not establish date validity.</span>'+lines(r,['availability_privacy_status','date_privacy_status'])]],
    atlas_spatial_region_counts:[['Source and region field','Location meaning depends on this field',r=>identity(r,'region_column')],['Recorded region','Supplied normalized region',r=>lines(r,['region_name','region_code'])],['Source records','Count and supplied percentage',r=>coverageShare(r,'region')],['Evidence basis','Not a residence or treatment claim',regionBasis]],
    atlas_spatial_region_coverage:[['Region','Configured region labels',r=>lines(r,['region_name','region_code'])],['Source coverage','Supplied group and status',r=>lines(r,['domain','coverage_status'])],['Domain records and basis','These totals are not regional counts',r=>line('Domain source records',readingCell(r,'n_rows'))+'<span class="cell-line">The same domain total is repeated across regions; not a regional count. Do not sum across regions.</span>'+lines(r,['basis'])]]
  };
  const hasReadingView=t=>!!primary[t.id]||categoryProfiles.has(t.id);
  const withheldDistribution=row=>row.value_privacy_status==='withheld_unvalidated_distribution'&&['label','n','pct_rows'].every(key=>own(row,key)&&row[key]===null);
  function availabilityLink(row){
    const target=c.tables.find(t=>t.id==='column_profiles');
    if(!target||!readable(target)||!supplied(row,'table_name')||!supplied(row,'source_column'))return '';
    const params=new URLSearchParams({table:'column_profiles',source:row.table_name,field:row.source_column});
    return '<a class="field-availability" href="DALYCARE_outputs.html?'+escape(params.toString())+'">Inspect field availability →</a>';
  }
  function renderCategoryRows(rows){
    const allWithheld=rows.every(withheldDistribution),partial=lastResult.total_matches>rows.length||page>0||selected.complete!==true||appliedQuery||rowScope.source||rowScope.field;
    el('table-result').textContent=(allWithheld?'Category values, counts and shares'+(partial?' in these rows':'')+' are withheld pending validation. Field names are published; they do not show patient findings.':'These are selected registry fields, not patient findings. Category values and frequencies appear only where published.');
    el('table-result').hidden=false;
    const groups=new Map(),seen=new Set();
    for(const row of rows){
      // Collapse only identical, wholly withheld evidence. Every original row remains in exact view.
      const signature=JSON.stringify(selected.columns.map(c=>row[c.key]));
      if(withheldDistribution(row)&&seen.has(signature))continue;
      if(withheldDistribution(row))seen.add(signature);
      const key=JSON.stringify([row.table_name,row.registry]);if(!groups.has(key))groups.set(key,[]);groups.get(key).push(row);
    }
    const registryVariants=new Map();for(const group of groups.values()){const row=group[0];if(!registryVariants.has(row.table_name))registryVariants.set(row.table_name,new Set());registryVariants.get(row.table_name).add(row.registry);}
    return [...groups.values()].map(group=>'<section class="registry-fields"><h3>'+escape(sourceLabel(group[0].table_name)||group[0].registry||'Registry source')+' <code>'+cell(group[0],'table_name')+'</code>'+(registryVariants.get(group[0].table_name).size>1?' · Registry: '+cell(group[0],'registry'):'')+'</h3><ul>'+group.map(row=>{
      let evidence='';
      if(!withheldDistribution(row))evidence=line('Category',cell(row,'label'))+line('Source records',readingCell(row,'n'))+line('Supplied share',readingCell(row,'pct_rows'))+(supplied(row,'value_privacy_status')?line('Publication status',cell(row,'value_privacy_status')):'');
      else if(!allWithheld)evidence='<span class="cell-line">Distribution withheld pending validation.</span>';
      if(supplied(row,'availability_privacy_status'))evidence+=line('Availability',cell(row,'availability_privacy_status'));
      const known=new Set(['table_name','registry','source_column','label','n','pct_rows','availability_privacy_status','value_privacy_status']);
      evidence+=lines(row,selected.columns.map(c=>c.key).filter(key=>!known.has(key)&&supplied(row,key)));
      return '<li><div>'+fieldIdentity(row,'source_column')+evidence+'</div>'+availabilityLink(row)+'</li>';
    }).join('')+'</ul></section>').join('');
  }
  function renderNumericCoverage(rows){
    if(rows.some(row=>hasSummary(row)||!own(privacyLabels,row.numeric_privacy_status)))return null;
    const states=[...new Set(rows.map(row=>row.numeric_privacy_status))],groups=new Map();
    el('table-result').textContent='Stored numeric summaries are not published for these fields. '+(states.length===1?privacyLabels[states[0]]+'. ':'')+'Recorded availability and configured units are shown below.';
    el('table-result').hidden=false;
    for(const row of rows){if(!groups.has(row.table_name))groups.set(row.table_name,[]);groups.get(row.table_name).push(row);}
    return [...groups.entries()].map(([source,sourceRows])=>{
      const byStatus=new Map();for(const row of sourceRows){if(!byStatus.has(row.numeric_privacy_status))byStatus.set(row.numeric_privacy_status,[]);byStatus.get(row.numeric_privacy_status).push(row);}
      return '<section class="registry-fields"><h3>'+escape(sourceLabel(source)||'Source')+' <code>'+escape(source)+'</code></h3>'+[...byStatus.entries()].map(([status,fields])=>(states.length>1?'<h4 class="summary-status">Stored summaries withheld: '+escape(privacyLabels[status].replace(/^(?:Not shown|Withheld): /,''))+'</h4>':'')+'<div class="reading-table"><table><thead><tr><th scope="col">Field and configured unit</th><th scope="col">Recorded availability<small>Source records, not unique people</small></th></tr></thead><tbody>'+fields.map(row=>'<tr><td data-label="Field and configured unit">'+fieldIdentity(row,'source_column')+line('Unit',cell(row,'unit'))+'</td><td data-label="Recorded availability">'+availability(row)+(supplied(row,'availability_privacy_status')?line('Availability status',cell(row,'availability_privacy_status')):'')+'</td></tr>').join('')+'</tbody></table></div>').join('')+'</section>';
    }).join('');
  }
  function rowStatus(result){
    if(isFieldEvidence()){
      const state=lastReadState;
      if(!result.total_matches)return state.query?'No published profiles match “'+state.query+'” within this exact field.':'No published profile rows for this exact source and field in this export.';
      const total=result.total_matches+(state.query?' matching':' published')+' profile row'+(result.total_matches===1?'':'s');
      return result.rows.length?'Showing '+(state.page*PAGE_ROWS+1)+'–'+(state.page*PAGE_ROWS+result.rows.length)+' of '+total+' for this exact field.':'No profile rows on this page · '+total+'.';
    }
    if(!result.total_matches&&fieldNameOnly)return rowScope.source||rowScope.field?'No field names or reviewed labels match in this exact source and field scope. Clear the scope to search other fields.':'No field names or reviewed labels match. Try another field name, switch Search scope to all row fields and values, or use Sources to find a source.';
    if(!result.total_matches)return rowScope.source||rowScope.field?'No matching published rows for this exact source and field scope. Clear the scope to search other fields.':isReference(selected)?'No matching reference definition in this export. Try an exact code or another spelling.':'No matching published rows. Try a field name, exact source identifier, or another spelling.';
    return result.rows.length?'Showing '+(page*PAGE_ROWS+1)+'–'+(page*PAGE_ROWS+result.rows.length)+' of '+result.total_matches+(appliedQuery?' matching rows':' published rows'):'No rows on this page · '+result.total_matches+' matching rows';
  }
  function renderRowScope(){el('row-scope').hidden=!(rowScope.source||rowScope.field);el('row-scope-label').textContent=[rowScope.source&&'Source: '+rowScope.source,rowScope.field&&'Field: '+rowScope.field].filter(Boolean).join(' · ');el('row-scope-navigation').innerHTML=rowScope.source?sourceCoverageLink(rowScope.source):'';}
  function renderFieldPresentation(resetTools=false){
    const field=isFieldEvidence(),canRead=selected&&readable(selected);
    document.body.classList.toggle('field-evidence-mode',field);
    for(const [control,ordinary,special] of [['row-scope','row-scope-slot','field-scope-slot'],['search-table','table-search-slot','field-search-slot'],['exact-columns','exact-columns-slot','field-columns-slot']]){
      const target=el(field?special:ordinary),node=el(control);if(node.parentNode!==target)target.appendChild(node);
    }
    el('field-tools').hidden=!field||!canRead;
    if(resetTools)el('field-tools').open=field&&!!(appliedQuery||fieldNameOnly||exactColumns);
    el('field-identity').hidden=!field;el('field-navigation').hidden=!field;el('table-purpose').hidden=field;
    if(selected)el('table-title').textContent=field?fieldLabel({table_name:rowScope.source,column_name:rowScope.field})||rowScope.field:tableTitle(selected);
    if(selected?.id==='column_profiles')el('table-cue').textContent='Counts and summaries describe stored source records, not unique people or clinical reference ranges. Missing values are not zero.'+(!field&&selected.complete!==true&&canRead?' Only the published rows in this export are searchable; original scope is limited or unknown.':'');
    el('table-state').hidden=field;
    const active=[];if(appliedQuery)active.push('Applied search: “'+appliedQuery+'”');if(appliedQuery||fieldNameOnly)active.push('Search scope: '+(fieldNameOnly?'field names and reviewed labels':'all row fields and values'));if(exactColumns)active.push('Showing all exact columns');
    el('field-applied').hidden=!field||!active.length;el('field-filter-status').textContent=active.join(' · ');el('clear-field-search').hidden=!field||!appliedQuery||!canRead;
    if(!field){el('field-publication').hidden=true;return;}
    const source=sourceLabel(rowScope.source);
    el('field-identity').innerHTML=(source?'<strong>'+escape(source)+'</strong> · ':'')+'<code>'+escape(rowScope.source)+'</code><span class="cell-line">Exact field: <code>'+escape(rowScope.field)+'</code></span>';
    const publication=[];if(selected.complete!==true)publication.push('Published export scope is limited or unknown.');if(['snapshot_only','legacy_payload'].includes(selected.provenance))publication.push(originLabels[selected.provenance]+'.');
    el('field-publication').textContent=publication.join(' ');el('field-publication').hidden=!publication.length;
    const sourceParams=new URLSearchParams({view:'fields',table:'column_profiles',source:rowScope.source}),coverageParams=new URLSearchParams({view:'timeplace',source:rowScope.source});
    el('field-navigation').innerHTML='<a href="DALYCARE_outputs.html?'+escape(sourceParams.toString())+'">Browse fields in '+escape(source||'this source')+' →</a><a href="DALYCARE_outputs.html?'+escape(coverageParams.toString())+'">Years and regions for '+escape(source||'this source')+' →</a>';
    el('exact-columns').textContent=exactColumns?'Show field reading view':'Show all exact columns';el('exact-columns').setAttribute('aria-pressed',String(exactColumns));
  }
  function renderSearchMode(){
    const fields=fieldTable(selected?.id);if(!fields)fieldNameOnly=false;
    el('table-search-mode-control').hidden=!fields;el('table-search-mode').value=fieldNameOnly?'fields':'rows';
    el('table-query-label').textContent=fieldNameOnly?'Search field names and reviewed labels':'Search fields and values';
    el('table-query').placeholder=fieldNameOnly?'Field name or reviewed field label':'Field, code, or value';
  }
  function renderRows(){
    if(!selected||!lastResult)return;
    const t=selected,rows=lastResult.rows,compact=primary[t.id]&&!exactColumns;
    el('read-status').textContent=rowStatus(lastResult);el('read-status').hidden=false;el('table-state').hidden=isFieldEvidence();el('table-result').hidden=true;
    el('first-page').hidden=!isFieldEvidence()||!!rows.length||!lastResult.total_matches;
    el('exact-columns').hidden=!hasReadingView(t);el('exact-columns').textContent=exactColumns?'Show reading view':categoryProfiles.has(t.id)?'Show exact published rows':'Show all exact columns';el('exact-columns').setAttribute('aria-pressed',String(exactColumns));
    if(!rows.length){el('rows').innerHTML='';return;}
    if(isFieldEvidence()&&!exactColumns){el('rows').innerHTML=renderFieldProfiles(rows);return;}
    const precisionNote=!exactColumns&&hasReadingView(t)&&rows.some(row=>[...percentKeys,...statisticKeys].some(key=>typeof row[key]==='number'&&!Number.isInteger(row[key])))?'<p class="mini reading-precision">Numbers are rounded for reading where needed. Exact supplied values remain in all exact columns.</p>':'';
    if(categoryProfiles.has(t.id)&&!exactColumns){
      el('rows').innerHTML=precisionNote+renderCategoryRows(rows);
      el('read-status').textContent=lastResult.total_matches>rows.length||page>0?'Fields represented on this page · repeated withheld rows are combined':appliedQuery?'Fields matching your search':t.complete===true?'Selected registry fields in this export':'Selected fields from published rows';
      const quiet=t.complete===true&&!appliedQuery&&!rowScope.source&&!rowScope.field&&page===0&&lastResult.total_matches===rows.length;
      el('read-status').hidden=quiet;el('table-state').hidden=quiet;
      return;
    }
    if(t.id==='damyda_numeric_fields'&&!exactColumns){const coverage=renderNumericCoverage(rows);if(coverage!==null){el('rows').innerHTML=precisionNote+coverage;return;}}
    const columns=compact?primary[t.id]:t.columns.map(c=>[c.label||c.key,c.definition||('Exact column: '+c.key),r=>cell(r,c.key),c.key]);
    el('rows').innerHTML=precisionNote+'<div class="'+(compact?'reading-table':'table-scroll')+'"><table><thead><tr>'+columns.map(([label,meaning,,key])=>'<th scope="col">'+escape(label)+(isFieldEvidence()&&exactColumns?'<code class="cell-line">'+escape(key)+'</code>':'')+'<small>'+escape(meaning)+'</small></th>').join('')+'</tr></thead><tbody>'+rows.map(row=>'<tr>'+columns.map(([label,,render])=>'<td data-label="'+escape(label)+'">'+render(row)+'</td>').join('')+'</tr>').join('')+'</tbody></table></div>';
  }
  async function readPage(){
    controller?.abort();controller=new AbortController();const epoch=++viewEpoch,t=selected;if(!t)return;
    const request={query:appliedQuery,page,fieldNames:fieldNameOnly,scope:{...rowScope}};
    lastResult=null;lastReadState=null;el('rows').innerHTML='';el('table-result').hidden=true;el('read-status').hidden=false;el('table-state').hidden=isFieldEvidence();el('read-status').textContent=isFieldEvidence()?'Reading published field profiles…':'Loading table rows…';el('cancel-search').disabled=false;el('cancel-search').hidden=false;el('next-page').disabled=true;el('previous-page').disabled=true;el('data-paging').hidden=true;el('retry-read').hidden=true;el('first-page').hidden=true;
    try{
      const result=await scanTable(t.id,request.query,request.page,progress=>{if(epoch===viewEpoch)el('read-status').textContent='Searching published rows… '+progress.scanned_rows+' of '+progress.total_rows+' scanned';},controller.signal,{...request.scope,fieldNames:request.fieldNames});
      if(epoch!==viewEpoch)return;lastResult=result;lastReadState=request;
      renderRows();el('next-page').disabled=(page+1)*PAGE_ROWS>=result.total_matches;el('previous-page').disabled=page===0;el('data-paging').hidden=page===0&&result.total_matches<=PAGE_ROWS;
    }catch(error){if(epoch===viewEpoch){el('read-status').textContent=error.message.replace(/shard/gi,'table part')+'. Keep the HTML and accompanying data folder/files together, then try again to complete the search.';el('rows').innerHTML='';el('retry-read').hidden=false;}}
    finally{if(epoch===viewEpoch){el('cancel-search').disabled=true;el('cancel-search').hidden=true;}}
  }
  function detailMode(active){document.body.classList.toggle('detail-mode',active);}
  function open(tableId,restore=false,query='',controlId=null,namesOnly=false){
    const next=c.tables.find(t=>t.id===tableId)||null;
    if(!restore&&next&&!selected){libraryReturn={tableId,controlId,x:window.scrollX,y:window.scrollY};saveState(true);}
    controller?.abort();cancel();viewEpoch++;selected=next;lastResult=null;
    el('table-detail').hidden=!selected;el('library').hidden=!!selected;detailMode(!!selected);if(!selected)return;
    el('back-library').textContent=view==='timeplace'?(coverageSource?'← Back to this source':'← Back to years and regions'):'← Back to tables';
    if(!restore){page=0;appliedQuery=query;el('table-query').value=query;exactColumns=false;rowScope={};fieldNameOnly=namesOnly;}renderRowScope();renderSearchMode();
    const t=selected,[label,purpose]=content(t);
    el('table-title').textContent=tableTitle(t);el('table-purpose').textContent=categoryProfiles.has(t.id)?'Inspect the selected fields and their recorded availability.':descriptions[t.id]?purpose:(t.row_grain||'Row meaning not supplied. Inspect the column meanings before interpreting this output.');
    const cues=[];
    if(isReference(t))cues.push('Reference definitions do not establish observed tests, categories or result values.');
    else if(t.id==='column_profiles'||t.id==='damyda_numeric_fields')cues.push('Counts and summaries describe stored source records, not unique people or clinical reference ranges. Missing values are not zero.');
    else if(t.id==='lab_npu_code_coverage')cues.push('<a href="DALYCARE_outputs.html?table=npu_display_dictionary">Reviewed laboratory reference definitions</a> explain meanings, not observed availability.');
    else if(t.id==='semantic_code_map')cues.push('Code values are withheld. <a href="DALYCARE_outputs.html?table=clinical_display_dictionary">Reviewed reference definitions</a> explain code meanings.');
    if(t.complete!==true&&readable(t))cues.push('Only the published rows in this export are searchable; original scope is limited or unknown.');
    el('table-cue').innerHTML=cues.join(' ');el('table-cue').hidden=!cues.length;
    el('table-state').textContent=label;el('table-state').hidden=false;el('read-status').hidden=false;el('table-scope').textContent=t.complete===true?'All approved output rows are represented. Search covers these published rows.':'Limited or unknown original scope. Search covers only published rows in this export.';
    el('table-metadata').innerHTML='<dl>'+[['Exact table ID',t.id],['Original output title',t.title],['Export state',statusLabels[t.status]||'Unavailable'],['Publication reason',t.reason],['Source file',t.source_file],['Run',c.run_id],['Source terms',(t.source_terms||[]).join(', ')],['Row grain',t.row_grain],['Count basis',formatValue(t.count_basis,'count_basis')],...(formatValue(t.count_basis,'count_basis')!==t.count_basis?[['Raw count basis',t.count_basis]]:[]),['CSV source rows',count(t.source_row_count)],['Represented rows',count(t.represented_row_count)],['Evidence origin',originLabels[t.provenance]||'Not supplied']].map(([label,value])=>'<dt>'+label+'</dt><dd>'+escape(value===0?0:value||'Not supplied')+'</dd>').join('')+'</dl>';
    el('column-meanings').innerHTML=t.columns.map(c=>'<article><strong>'+escape(c.label||c.key)+'</strong> <code>'+escape(c.key)+'</code><p>'+escape(c.definition||'Definition not supplied')+'</p>'+['type','unit','denominator','scope','missing_rule'].filter(k=>c[k]!==undefined).map(k=>'<p><small>'+escape(k.replace('_',' '))+': '+escape(c[k])+'</small></p>').join('')+'</article>').join('')||'<p>No public column definitions supplied for this output.</p>';
    const canRead=readable(t);el('row-controls').hidden=!canRead;el('unreadable-status').hidden=canRead;el('unreadable-status').textContent=(statusLabels[t.status]||'Unavailable')+': '+(t.reason|| (t.status==='empty_output'?'This output contains no rows.':'Table rows are not included in this export.'));
    el('rows').innerHTML='';el('table-result').hidden=true;el('read-status').textContent='';el('retry-read').hidden=true;el('first-page').hidden=true;el('data-paging').hidden=true;el('exact-columns').hidden=!canRead||!hasReadingView(t);renderFieldPresentation(true);
    if(!restore)saveState();el('table-title').focus();if(canRead)readPage();
  }
  function showLibrary(){controller?.abort();cancel();viewEpoch++;selected=null;lastResult=null;el('table-detail').hidden=true;el('library').hidden=false;detailMode(false);renderFieldPresentation(true);}
  function clearFilters(){for(const name of ['metadata-query','group-filter','availability-filter'])el(name).value='';listPage=0;libraryReturn=null;}
  for(const key of Object.keys(tasks))el('task-'+key).addEventListener('click',()=>{controller?.abort();cancel();viewEpoch++;view=key;clearFilters();list();saveState();if(view==='timeplace'){coverageExample=!coverageSource;coveragePickerEntry();startCoverage();}});
  el('clear-filters').addEventListener('click',()=>{clearFilters();list();saveState();});
  el('metadata-query').addEventListener('input',()=>{libraryReturn=null;listPage=0;if(view!=='fields')view='all';list();saveState(true);});
  el('catalogue-search-form').addEventListener('submit',event=>{event.preventDefault();if(view==='fields')open('column_profiles',false,el('metadata-query').value.trim(),'catalogue-search-submit',true);else{list();saveState(true);}});
  el('coverage-query').addEventListener('input',()=>{coverageQuery=el('coverage-query').value;coverageExplicit=false;coverageExample=false;sourceChoices();renderCoverage();saveState(true);});
  el('coverage-source').addEventListener('change',()=>{coverageSource=el('coverage-source').value;coverageExplicit=true;coverageExample=false;if(coverageRunning){controller?.abort();cancel();viewEpoch++;}saveState();startCoverage();});
  el('coverage-retry').addEventListener('click',readCoverage);el('coverage-cancel').addEventListener('click',()=>controller?.abort());
  for(const name of ['group-filter','availability-filter'])el(name).addEventListener('change',()=>{libraryReturn=null;listPage=0;view='all';list();saveState();});
  for(const [name,delta] of [['catalogue-previous',-1],['catalogue-next',1]])el(name).addEventListener('click',()=>{listPage=Math.max(0,listPage+delta);libraryReturn=null;list();saveState();el('task-title').setAttribute('tabindex','-1');el('task-title').focus();});
  for(const [control,tableId] of searchTargets)el(control).addEventListener('click',()=>open(tableId,false,el('metadata-query').value.trim(),control));
  el('search-table').addEventListener('submit',event=>{event.preventDefault();appliedQuery=el('table-query').value;page=0;renderFieldPresentation();saveState();readPage();});
  el('table-search-mode').addEventListener('change',()=>{fieldNameOnly=el('table-search-mode').value==='fields';appliedQuery=el('table-query').value;page=0;renderSearchMode();renderFieldPresentation();saveState();readPage();});
  el('clear-row-scope').addEventListener('click',()=>{rowScope={};page=0;renderRowScope();renderFieldPresentation(true);saveState();el('table-title').focus();readPage();});
  el('clear-field-search').addEventListener('click',()=>{appliedQuery='';el('table-query').value='';page=0;renderFieldPresentation(true);saveState();el('table-title').focus();readPage();});
  el('first-page').addEventListener('click',()=>{page=0;saveState();el('table-title').focus();readPage();});
  el('retry-read').addEventListener('click',readPage);el('cancel-search').addEventListener('click',()=>controller?.abort());
  el('exact-columns').addEventListener('click',()=>{exactColumns=!exactColumns;renderFieldPresentation();renderRows();saveState(true);});
  for(const [name,delta] of [['previous-page',-1],['next-page',1]])el(name).addEventListener('click',()=>{page=Math.max(0,page+delta);saveState();readPage();});
  el('back-library').addEventListener('click',()=>{showLibrary();saveState();list();if(view==='timeplace'){startCoverage();el('coverage-title').focus();}else if(!restoreLibraryPosition())el('metadata-query').focus();});
  function restore(event){
    const p=new URLSearchParams(window.location.search),saved=window.history.state?.outputsLibraryReturn;
    libraryReturn=saved&&id(saved.tableId)&&Number.isFinite(saved.x)&&Number.isFinite(saved.y)&&(!saved.controlId||saved.controlId==='catalogue-search-submit'||searchTargets.some(([control])=>control===saved.controlId))?saved:null;
    view=own(tasks,p.get('view'))?p.get('view'):(p.get('q')||p.get('group')||p.get('status')?'all':'fields');listPage=Math.max(0,Math.floor(Number(p.get('listpage'))||1)-1);
    coverageSource=(p.get('table')?p.get('returnsource'):'')||p.get('source')||'';coverageExplicit=!!coverageSource;coverageQuery=p.get('findsource')||(view==='timeplace'?p.get('q')||'':'');coverageExample=view==='timeplace'&&!coverageSource&&!coverageQuery;
    coveragePickerEntry();
    el('metadata-query').value=view==='timeplace'?'':p.get('q')||'';el('group-filter').value=groups.includes(p.get('group'))?p.get('group'):'';el('availability-filter').value=own(statusLabels,p.get('status'))?p.get('status'):'';
    appliedQuery=p.get('search')||'';el('table-query').value=appliedQuery;page=Math.max(0,Math.floor(Number(p.get('page'))||1)-1);exactColumns=p.get('columns')==='all';fieldNameOnly=p.get('searchmode')==='fields';rowScope={source:p.get('source')||'',field:p.get('field')||''};list();
    if(p.get('table'))open(p.get('table'),true);else{showLibrary();if(view==='timeplace')startCoverage();else if(!restoreLibraryPosition()&&event)el('metadata-query').focus();}
  }
  window.addEventListener('popstate',restore);restore();if(document.documentElement)document.documentElement.dataset.atlasReady='outputs';
})(window,document);
