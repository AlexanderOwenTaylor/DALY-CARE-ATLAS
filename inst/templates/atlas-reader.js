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
  const rowSource=row=>own(row,'source_name')?row.source_name:row.table_name;
  const fieldKey=row=>own(row,'raw_column')?row.raw_column:own(row,'column_name')?row.column_name:own(row,'source_column')?row.source_column:own(row,'date_column')?row.date_column:row.region_column;
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
    const c=window.DALYCARE_DIRECTORY || window.DALYCARE_OUTPUT_CATALOGUE;
    if (!c || c.schema_version!==(window.DALYCARE_DIRECTORY?2:1)) throw new Error('Unsupported or missing catalogue version');
    if (!id(c.build_id) || !Array.isArray(c.tables)) throw new Error('Invalid catalogue build');
    const ids=new Set();
    for(const table of c.tables){
      if(!table || !id(table.id) || ids.has(table.id) || typeof table.title!=='string' || (c.schema_version===1&&(!Array.isArray(table.columns)||!Array.isArray(table.shards))))throw new Error('Invalid catalogue table schema or identity');
      ids.add(table.id);
    }
    return c;
  }
  function tableFor(tableId) {
    const c=catalogue(),t=c.tables.find(t=>t.id===tableId);
    if (!t || !id(t.id) || !Array.isArray(t.columns) || !Array.isArray(t.shards)) throw new Error('Unknown table or incompatible schema');
    const keys=new Set();
    if(['available','limited'].includes(t.status))for(const column of t.columns){if(!column || typeof column.key!=='string' || !column.key || ['__proto__','constructor','prototype'].includes(column.key) || keys.has(column.key) || !['string','number','boolean'].includes(column.type))throw new Error('Incompatible column schema type');keys.add(column.key);}
    const shards=new Set(),registryIdentities=new Set();
    for(const shard of t.shards){
      if(!shard || !id(shard.id) || shards.has(shard.id))throw new Error('Invalid or duplicate shard identity');
      if(typeof shard.src!=='string' || !/^output-shards\/[A-Za-z0-9_-]+\.js$/.test(shard.src))throw new Error('Invalid shard path');
      if(!Number.isInteger(shard.rows) || shard.rows<0 || shard.rows>MAX_ROWS || !Number.isInteger(shard.bytes) || shard.bytes<2 || shard.bytes>MAX_BYTES)throw new Error('Shard row or byte descriptor exceeds limit');
      if(own(shard,'asset_bytes')&&(!Number.isInteger(shard.asset_bytes)||shard.asset_bytes<shard.bytes||shard.asset_bytes>MAX_BYTES))throw new Error('Shard asset byte descriptor exceeds limit');
      if(own(shard,'fields')&&(!Array.isArray(shard.fields)||shard.fields.length!==shard.rows||shard.fields.some(pair=>!Array.isArray(pair)||pair.length!==2||pair.some(v=>typeof v!=='string'))))throw new Error('Invalid exact field locator');
      if(t.id==='registry_field_summaries'&&Array.isArray(shard.fields))for(const pair of shard.fields){const key=JSON.stringify(pair);if(registryIdentities.has(key))throw new Error('Duplicate registry locator identity');registryIdentities.add(key);}
      shards.add(shard.id);
    }
    return {c,t};
  }
  let registryContext=null;
  function validationContext(tableId,c){
    const minimum=c.minimum_cell_count??5;if(!Number.isInteger(minimum)||minimum<5)throw new Error('Invalid privacy threshold context');
    if(tableId!=='registry_field_summaries')return {minimum};
    const guard=window.DALYCARERegistryV2,resource=JSON.stringify(window.DALYCARE_REGISTRY_V2_RESOURCE);
    const context={minimum,resource,validate:guard?.validate,legacy:guard?.validateLegacy,build:c.build_id};
    if(registryContext&&registryContext.build===c.build_id&&(registryContext.resource!==resource||registryContext.validate!==context.validate||registryContext.legacy!==context.legacy))throw new Error('Registry privacy resource or validator context changed; reload the complete site');
    registryContext=context;return context;
  }
  function sameContext(a,b){return a.minimum===b.minimum&&a.resource===b.resource&&a.validate===b.validate&&a.legacy===b.legacy&&a.build===b.build;}
  function settle(error,rows,bytes) {
    const request=pending;if(!request)return;
    pending=null;clearTimeout(request.timer);request.script.remove();
    if(error) request.reject(error);
    else {
      while(cacheBytes+bytes>CACHE_BYTES && cache.size){const first=cache.keys().next().value;cacheBytes-=cache.get(first).bytes;cache.delete(first);}
      for(const row of rows)Object.freeze(row);Object.freeze(rows);
      cache.set(request.key,{rows,bytes,schema:request.schema,context:request.context});cacheBytes+=bytes;request.resolve(rows);
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
      const key=c.build_id+':'+tableId+':'+shardId,context=validationContext(tableId,c);
      if(cache.has(key)){const item=cache.get(key);cache.delete(key);if(!sameContext(item.context,context)){cacheBytes-=item.bytes;throw new Error('Cached privacy context changed; reload the complete site');}if(item.schema===JSON.stringify(t)){cache.set(key,item);return Promise.resolve(item.rows);}cacheBytes-=item.bytes;}
      if(pending){if(pending.key===key)return pending.promise;throw new Error('A table shard read is already active');}
      const script=document.createElement('script');script.src=s.src;script.async=true;
      const request={key,c,t,s,script,buildId:c.build_id,schema:JSON.stringify(t),minimum:c.minimum_cell_count,context};request.promise=new Promise((resolve,reject)=>{request.resolve=resolve;request.reject=reject;});pending=request;
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
      if(JSON.stringify(tableFor(r.t.id).t)!==r.schema||catalogue().minimum_cell_count!==r.minimum||!sameContext(r.context,validationContext(r.t.id,catalogue())))throw new Error('Table schema or privacy policy changed during load');
      if(typeof data.rows_json!=='string' || data.rows_json.length>MAX_BYTES || utf8(data.rows_json)!==r.s.bytes)throw new Error('Shard byte mismatch or limit exceeded');
      const rows=parseRows(data.rows_json);
      if(!Array.isArray(rows) || rows.length!==r.s.rows || rows.length>MAX_ROWS)throw new Error('Shard row count mismatch or limit exceeded');
      const keys=new Set(r.t.columns.map(c=>c.key));
      const registryIds=new Set();
      for(const [rowIndex,row] of rows.entries()) {
        if(!row || typeof row!=='object' || Array.isArray(row) || Object.keys(row).some(k=>!keys.has(k)))throw new Error('Shard contains unreviewed schema columns');
        for(const column of r.t.columns) {
          if(!own(row,column.key)) {
            const contract=row.contract_version==='registry-summary-v2'?window.DALYCARERegistryV2?.schema:window.DALYCARERegistryV2?.legacySchema;
            if(r.t.id==='registry_field_summaries'&&contract&&!contract.includes(column.key))continue;
            throw new Error('Shard missing schema column');
          }
          const value=row[column.key];if(value===null)continue;
          if(typeof value==='object' || !['string','number','boolean'].includes(typeof value))throw new Error('Invalid row value');
          if(column.type==='number' && (typeof value!=='number' || !Number.isFinite(value)))throw new Error('Invalid numeric schema value');
          if(column.type==='boolean' && typeof value!=='boolean')throw new Error('Invalid boolean schema value');
          if(column.type==='string' && typeof value!=='string')throw new Error('Invalid string schema value');
        }
        if(r.t.id==='registry_field_summaries') {
          if(Array.isArray(r.s.fields)&&(row.table_name!==r.s.fields[rowIndex][0]||row.source_column!==r.s.fields[rowIndex][1]))throw new Error('Registry locator identity disagrees with screened row');
          const identity=JSON.stringify([row.table_name,row.source_column]),guard=window.DALYCARERegistryV2;
          const checked=row.contract_version==='registry-summary-v2'?guard?.validate(row,window.DALYCARE_REGISTRY_V2_RESOURCE,r.c.minimum_cell_count||5):guard?.validateLegacy(row,window.DALYCARE_REGISTRY_V2_RESOURCE,r.c.minimum_cell_count||5);
          if(!checked||registryIds.has(identity))throw new Error('Registry field contract failed');
          registryIds.add(identity);
        }
      }
      settle(null,rows,r.s.bytes);
    }catch(error){settle(error);}
  }
  async function scanTable(tableId,query,page,onProgress,signal,criteria={}) {
    if(window.DALYCARE_DIRECTORY)await ensureDescriptor(tableId);
    if(tableId==='registry_field_summaries'&&window.DALYCARE_DIRECTORY)await registryResource();
    const {t}=tableFor(tableId);const reference_context=!!(criteria.source||criteria.field)&&(t.provenance==='project_reference'||['npu_display_dictionary','npu_reference_search','clinical_display_dictionary'].includes(tableId));
    if(reference_context)criteria={...criteria,source:'',field:''};
    selectTable(tableId);cancel();const epoch=scanEpoch;
    const check=()=>{if(signal?.aborted || epoch!==scanEpoch || activeTable!==tableId)throw new Error('Search incomplete: cancelled');};
    const abort=()=>{if(epoch===scanEpoch)cancel();};signal?.addEventListener('abort',abort,{once:true});
    let scanned=0,matches=0;const registrySeen=new Set();if(tableId==='registry_field_summaries'&&t.shards.reduce((n,s)=>n+s.rows,0)>217)throw new Error('Registry field inventory exceeds policy');const rows=[],start=Number.isInteger(criteria.offset)&&criteria.offset>=0?criteria.offset:Math.max(0,Number.isFinite(Number(page))?Math.floor(Number(page)):0)*PAGE_ROWS;let pageBytes=0;const pageLimit=['registry_field_summaries','semantic_dictionary'].includes(tableId)?131072:MAX_BYTES;
    const needle=String(query||'').toLocaleLowerCase();
    try {
      check();
      const locatedRegistry=tableId==='registry_field_summaries'&&t.shards.every(s=>Array.isArray(s.fields));
      if(locatedRegistry){const identities=new Set(),known=new Set(window.DALYCARE_REGISTRY_V2_RESOURCE.fields.map(r=>JSON.stringify([r.table_name,r.source_column])));for(const shard of t.shards)for(const pair of shard.fields){const key=JSON.stringify(pair);if(identities.has(key)||!known.has(key))throw new Error('Duplicate or unknown registry locator identity');identities.add(key);}}
      if(!needle&&((['column_profiles','semantic_dictionary'].includes(tableId)&&(criteria.source||criteria.field))||locatedRegistry)&&t.shards.every(s=>Array.isArray(s.fields))){
        const match=pair=>(!criteria.source||pair[0]===criteria.source)&&(!criteria.field||pair[1]===criteria.field)&&(!Array.isArray(criteria.fields)||criteria.fields.includes(pair[1]));
        const total=t.shards.reduce((n,s)=>n+s.fields.filter(match).length,0);let offset=0;
        for(const shard of t.shards){const count=shard.fields.filter(match).length;check();if(count>0&&offset<start+PAGE_ROWS&&offset+count>start){const charge=shard.asset_bytes||shard.bytes;if(pageBytes&&pageBytes+charge>pageLimit)break;pageBytes+=charge;const data=await loadShard(tableId,shard.id);check();
          if(data.some((row,i)=>rowSource(row)!==shard.fields[i][0]||fieldKey(row)!==shard.fields[i][1]))throw new Error('Exact field locator disagrees with screened rows');
          const selected=data.filter(row=>match([rowSource(row),fieldKey(row)]));for(let i=Math.max(0,start-offset);i<selected.length&&rows.length<PAGE_ROWS;i++)rows.push(selected[i]);scanned+=data.length;
        }offset+=count;}
        return {rows,total_matches:total,scanned_rows:scanned,complete:true,reference_context,next_offset:start+rows.length};
      }
      if(!needle&&!criteria.source&&!criteria.field&&tableId!=='registry_field_summaries') {
        const total=t.shards.reduce((n,s)=>n+s.rows,0);let offset=0;
        for(const shard of t.shards){check();if(offset<start+PAGE_ROWS && offset+shard.rows>start){const charge=shard.asset_bytes||shard.bytes;if(pageBytes&&pageBytes+charge>pageLimit)break;pageBytes+=charge;const data=await loadShard(tableId,shard.id);check();for(let i=Math.max(0,start-offset);i<data.length && rows.length<PAGE_ROWS;i++)rows.push(data[i]);scanned+=data.length;}offset+=shard.rows;}
        return {rows,total_matches:total,scanned_rows:scanned,complete:true,reference_context,next_offset:start+rows.length};
      }
      const boundedScope=!needle&&!!(criteria.source||criteria.field)&&!criteria.explicitFull;let exhausted=true;
      for(const shard of t.shards){
        const charge=shard.asset_bytes||shard.bytes;if(boundedScope&&((pageBytes&&pageBytes+charge>pageLimit)||rows.length>=PAGE_ROWS)){exhausted=false;break;}if(boundedScope)pageBytes+=charge;
        if(['column_profiles','semantic_dictionary'].includes(tableId)&&criteria.source&&Array.isArray(shard.fields)&&!shard.fields.some(pair=>Array.isArray(pair)&&pair[0]===criteria.source&&(!criteria.field||pair[1]===criteria.field)))continue;
        if(tableId==='npu_reference_search'&&/^npu\d{5}$/i.test(needle)&&typeof shard.first==='string'&&typeof shard.last==='string'&&(needle.toUpperCase()<shard.first||needle.toUpperCase()>shard.last))continue;
        check();const data=await loadShard(tableId,shard.id);check();for(const row of data){
        if(tableId==='registry_field_summaries'){const id=JSON.stringify([row.table_name,row.source_column]);if(registrySeen.has(id))throw new Error('Duplicate registry field identity');registrySeen.add(id);}
        const inScope=(!criteria.source||rowSource(row)===criteria.source)&&(!criteria.field||fieldKey(row)===criteria.field)&&(!Array.isArray(criteria.fields)||criteria.fields.includes(fieldKey(row)));
        const namesOnly=criteria.fieldNames===true&&fieldTable(tableId),alias=fieldTable(tableId)?[fieldLabel(row),own(sourceLabels,row.table_name)?sourceLabels[row.table_name]:''].join(' '):'';
        const matchesQuery=!needle||(namesOnly?[fieldKey(row),fieldLabel(row)].some(value=>String(value||'').toLocaleLowerCase().includes(needle)):t.columns.some(c=>row[c.key]!==null&&String(row[c.key]).toLocaleLowerCase().includes(needle))||alias.toLocaleLowerCase().includes(needle));
        if(inScope&&matchesQuery){if(matches>=start&&rows.length<PAGE_ROWS)rows.push(row);matches++;}
      }scanned+=data.length;onProgress?.({scanned_rows:scanned,total_rows:t.shards.reduce((n,s)=>n+s.rows,0)});}
      check();return {rows,total_matches:matches,scanned_rows:scanned,complete:exhausted,reference_context,next_offset:start+rows.length};
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
  reviewedLabels.summary_status={published:'Published complete distribution',field_absent:'Field absent from checked schema',source_unavailable:'Source unavailable',needs_person_key:'Reviewed person key required',missing_person_key:'Person key missing',query_failed:'Query did not complete',resource_limit:'Resource limit reached',withheld_privacy:'Withheld by complete-distribution privacy checks',needs_unit_evidence:'Verified stored-unit evidence required',needs_numeric_policy:'Approved fixed bands required',needs_mapping:'Source-specific mapping required',invalid_contract:'Withheld: contract validation failed',empty_source:'Completed empty source',all_missing:'All assessed values missing',all_unrecognised:'All assessed values unrecognised',all_conflicting:'All assessed people have conflicting values',no_usable_values:'No usable values after complete assessment',no_values:'Legacy reason unavailable'};
  Object.assign(reviewedLabels.summary_method,{fixed_bands_midpoint_mean_nearest_rank_intervals:'Approximate midpoint mean and containing-band quartiles',complete_reviewed_recorded_codes:'Complete person-counted recorded codes'});
  reviewedLabels.summary_method['supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample']='Supplied mean and quantiles; quartiles may use a sample of source records';
  function formatValue(value,key,row={}) {
    if(value!==null && value!==undefined && ['mean','median','p25','p75','sd','q25','q75','iqr','min','max'].includes(key)) return 'Withheld: verified grouped evidence required';
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

  let descriptorRequest=null, registryPromise=null;
  function parseRows(text) {
    const tokens=text.match(/"(?:\\.|[^"\\])*"|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null|[{}\[\],:]/g)||[];
    let pos=0;
    function value(depth){
      if(depth>128)throw new Error('JSON depth limit');
      const token=tokens[pos++];
      if(token==='{'||token==='['){const object=token==='{',end=object?'}':']',keys=new Set();if(tokens[pos]===end){pos++;return;}
        for(;;){if(object){const key=JSON.parse(tokens[pos++]);if(typeof key!=='string'||['__proto__','constructor','prototype'].includes(key)||keys.has(key)||tokens[pos++]!==':')throw new Error('Unsafe or duplicate JSON key');keys.add(key);}value(depth+1);if(tokens[pos]===end){pos++;break;}if(tokens[pos++]!==',')throw new Error('Invalid JSON separator');}
      }else if(token===undefined)throw new Error('Invalid JSON value');
    }
    value(0);if(pos!==tokens.length)throw new Error('Invalid JSON suffix');return JSON.parse(text);
  }
  function ensureDescriptor(tableId){
    const c=catalogue(),t=c.tables.find(t=>t.id===tableId);
    if(!t)return Promise.reject(new Error('Unknown table'));
    if(Array.isArray(t.columns)&&Array.isArray(t.shards))return Promise.resolve(t);
    if(typeof t.descriptor!=='string'||!/^table-descriptors\/[A-Za-z0-9_-]+\.js$/.test(t.descriptor))return Promise.reject(new Error('Invalid descriptor path'));
    if(descriptorRequest){if(descriptorRequest.table===t)return descriptorRequest.promise;return descriptorRequest.promise.catch(()=>{}).then(()=>ensureDescriptor(tableId));}
    const script=document.createElement('script');script.src=t.descriptor;
    const r={table:t,identity:t.id,snapshot:JSON.stringify(t),build:c.build_id,script};r.promise=new Promise((resolve,reject)=>{r.resolve=resolve;r.reject=reject;});descriptorRequest=r;
    r.finish=(error)=>{if(descriptorRequest!==r)return;descriptorRequest=null;clearTimeout(r.timer);script.remove();error?r.reject(error):r.resolve(t);};
    script.onerror=()=>r.finish(new Error('Table descriptor failed; retry available'));script.onload=()=>r.finish(new Error('Descriptor registration missing'));r.timer=setTimeout(()=>r.finish(new Error('Descriptor timeout; retry available')),15000);document.head.appendChild(script);return r.promise;
  }
  function registerDescriptor(data){
    const r=descriptorRequest;if(!r||document.currentScript!==r.script)return;
    try{
      if(!data||data.schema_version!==1||data.build_id!==r.build||catalogue().build_id!==r.build||!data.table||data.table.id!==r.identity||JSON.stringify(r.table)!==r.snapshot||utf8(JSON.stringify(data))>MAX_BYTES)throw new Error('Descriptor identity or byte mismatch');
      const candidate=data.table;if(!Array.isArray(candidate.columns)||!Array.isArray(candidate.shards)||Object.keys(candidate).some(k=>['__proto__','constructor','prototype'].includes(k)))throw new Error('Invalid descriptor schema');
      const before={...r.table};Object.assign(r.table,candidate);
      try{tableFor(r.table.id);}catch(e){Object.keys(r.table).forEach(k=>delete r.table[k]);Object.assign(r.table,before);throw e;}
      r.finish();
    }catch(error){r.finish(error);}
  }
  function registryResource(){
    const ready=()=>window.DALYCARERegistryV2&&window.DALYCARE_REGISTRY_V2_RESOURCE&&window.DALYCARE_REGISTRY_BUILD_ID===catalogue().build_id;
    if(ready())return Promise.resolve();
    if(registryPromise)return registryPromise;
    registryPromise=new Promise((resolve,reject)=>{const script=document.createElement('script');script.src='registry-v2.js';let timer;const fail=()=>{clearTimeout(timer);script.remove();registryPromise=null;reject(new Error('Registry validator unavailable or build mismatch; retry available'));};script.onerror=fail;script.onload=()=>{clearTimeout(timer);if(ready()){script.remove();resolve();}else fail();};timer=setTimeout(fail,15000);document.head.appendChild(script);});return registryPromise;
  }

  window.DALYCARE_OUTPUTS={register,registerDescriptor,ensureDescriptor,registryResource,loadShard,scanTable,cancel,formatValue,tableFor,get cacheBytes(){return cacheBytes;}};
})(window,document);
