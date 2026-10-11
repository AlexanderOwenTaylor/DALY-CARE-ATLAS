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
  const formatValue=(value,key)=>value===null || value===undefined?'Missing':(reviewedLabels[key] && own(reviewedLabels[key],value)?reviewedLabels[key][value]:String(value));
  window.DALYCARE_OUTPUTS={register,loadShard,scanTable,cancel,formatValue,get cacheBytes(){return cacheBytes;}};
  const root = document.getElementById('outputs-app');
  if (!root) return;
  const el = id => document.getElementById(id),
    escape = value => String(value ?? '').replace(/[&<>"']/g, ch => ({
      '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[ch]));
  const statusLabels = {
    available: 'Available', limited: 'Limited', empty_output: 'Empty output',
    not_produced: 'Not in this export', metadata_only: 'Metadata only',
    withheld: 'Privacy withheld', unavailable: 'Unavailable'
  };
  let c;
  try {
    c = catalogue();
  } catch (error) {
    el('outputs-status').textContent = error.message + '. Keep all atlas files together and retry.';
    if (document.documentElement) document.documentElement.dataset.atlasReady = 'outputs-error';
    return;
  }
  const groups = [...new Set(c.tables.map(t => t.group).filter(Boolean))].sort(),
    params = new URLSearchParams(window.location.search);
  el('metadata-query').value = params.get('q') || '';
  el('group-filter').innerHTML = '<option value="">All groups</option>' +
    groups.map(g => '<option>' + escape(g) + '</option>').join('');
  el('group-filter').value = groups.includes(params.get('group')) ? params.get('group') : '';
  let selected = null, page = 0, controller = null, viewEpoch = 0;
  const count = value => value === null || value === undefined ? 'Not supplied' : formatValue(value);

  function saveState(replace = false) {
    const p = new URLSearchParams();
    if (el('metadata-query').value) p.set('q', el('metadata-query').value);
    if (el('group-filter').value) p.set('group', el('group-filter').value);
    if (el('availability-filter').value) p.set('status', el('availability-filter').value);
    if (selected) {
      p.set('table', selected.id);
      if (el('table-query').value) p.set('search', el('table-query').value);
      if (page) p.set('page', page + 1);
    }
    window.history[replace ? 'replaceState' : 'pushState'](
      {}, '', 'DALYCARE_outputs.html' + (p.size ? '?' + p : '')
    );
  }

  function list() {
    const q = el('metadata-query').value.toLocaleLowerCase(),
      g = el('group-filter').value,
      s = el('availability-filter').value;
    const tables = c.tables.filter(t =>
      (!g || t.group === g) && (!s || t.status === s) && [
        t.title, t.group, t.source_file, t.kind, t.row_grain,
        ...(t.source_terms || []),
        ...(t.columns || []).flatMap(c => [c.key, c.label, c.definition])
      ].some(value => String(value || '').toLocaleLowerCase().includes(q))
    );
    el('table-list').innerHTML = tables.map(t =>
      '<button type="button" class="table-card" data-table="' + escape(t.id) + '">' +
      '<strong>' + escape(t.title) + '</strong><span>' +
      escape(statusLabels[t.status] || 'Unavailable') + ' · ' + escape(t.group || 'Other') +
      '</span><small>' + escape(t.source_file || 'File not supplied') + '</small></button>'
    ).join('') || '<p>No tables match these metadata filters.</p>';
    el('table-list').querySelectorAll('[data-table]').forEach(button =>
      button.addEventListener('click', () => open(button.dataset.table))
    );
    el('outputs-status').textContent = tables.length +
      (tables.length === 1 ? ' table' : ' tables') + ' · Run ' + (c.run_id || 'not supplied');
  }

  async function readPage() {
    controller?.abort();
    controller = new AbortController();
    const epoch = ++viewEpoch, t = selected;
    if (!t) return;
    el('rows').innerHTML = '';
    el('read-status').textContent = 'Loading table rows…';
    el('cancel-search').disabled = false;
    el('next-page').disabled = true;
    el('previous-page').disabled = true;
    el('retry-read').hidden = true;
    try {
      const result = await scanTable(t.id, el('table-query').value, page, progress => {
        if (epoch === viewEpoch) el('read-status').textContent = 'Searching table… ' +
          progress.scanned_rows + ' of ' + progress.total_rows + ' rows scanned';
      }, controller.signal);
      if (epoch !== viewEpoch) return;
      const range = result.rows.length ?
        'Showing ' + (page * PAGE_ROWS + 1) + '–' + (page * PAGE_ROWS + result.rows.length) +
        ' of ' + result.total_matches + (el('table-query').value ? ' matching rows' : ' rows') :
        'No rows on this page · ' + result.total_matches + ' matching rows';
      el('read-status').textContent = (result.total_matches ? range : 'No matches') +
        (el('table-query').value ? ' · Full scan complete' : '');
      el('rows').innerHTML = result.rows.length ?
        '<div class="table-scroll"><table><thead><tr>' +
        t.columns.map(c => '<th scope="col">' + escape(c.label || c.key) + '</th>').join('') +
        '</tr></thead><tbody>' + result.rows.map(row =>
          '<tr>' + t.columns.map(c =>
            '<td title="' + escape(formatValue(row[c.key])) + '">' +
            escape(formatValue(row[c.key], c.key)) + '</td>'
          ).join('') + '</tr>'
        ).join('') + '</tbody></table></div>' : '';
      el('next-page').disabled = (page + 1) * PAGE_ROWS >= result.total_matches;
      el('previous-page').disabled = page === 0;
    } catch (error) {
      if (epoch === viewEpoch) {
        el('read-status').textContent = error.message + '. Try again to complete the search.';
        el('rows').innerHTML = '';
        el('retry-read').hidden = false;
      }
    }
    finally {
      if (epoch === viewEpoch) el('cancel-search').disabled = true;
    }
  }

  function detailMode(active) {
    document.body.classList.toggle('detail-mode', active);
    el('catalogue-note').hidden = active;
    el('outputs-status').hidden = active;
  }

  function open(tableId, restore = false) {
    controller?.abort();
    cancel();
    viewEpoch++;
    selected = c.tables.find(t => t.id === tableId) || null;
    el('table-detail').hidden = !selected;
    el('library').hidden = !!selected;
    detailMode(!!selected);
    if (!selected) return;
    if (!restore) {
      page = 0;
      el('table-query').value = '';
    }
    const t = selected;
    el('table-title').textContent = t.title;
    el('table-state').textContent = (statusLabels[t.status] || 'Unavailable') +
      (t.reason ? ' · ' + t.reason : '');
    el('table-metadata').innerHTML = '<dl>' + [
      ['Source file', t.source_file],
      ['Source terms', (t.source_terms || []).join(', ')],
      ['Row grain', t.row_grain],
      ['Count basis', t.count_basis],
      ['CSV source rows', count(t.source_row_count)],
      ['Represented rows', count(t.represented_row_count)],
      ['Completeness', t.complete === true ? 'Complete reviewed output' :
        t.complete === false ? 'Limited / incomplete output' : 'Unknown'],
      ['Evidence origin', t.provenance === 'csv_outputs' ? 'From CSV outputs' :
        t.provenance === 'legacy_payload' ? 'From an earlier atlas export' :
        t.provenance || 'Not supplied']
    ].map(([label, value]) =>
      '<dt>' + label + '</dt><dd>' + escape(value || 'Not supplied') + '</dd>'
    ).join('') + '</dl>';
    el('column-meanings').innerHTML = t.columns.map(c =>
      '<article><strong>' + escape(c.label || c.key) + '</strong> <code>' + escape(c.key) +
      '</code><p>' + escape(c.definition || 'Definition not supplied') + '</p>' +
      ['type', 'unit', 'denominator', 'scope', 'missing_rule']
        .filter(k => c[k] !== undefined)
        .map(k => '<p><small>' + escape(k.replace('_', ' ')) + ': ' + escape(c[k]) + '</small></p>')
        .join('') + '</article>'
    ).join('');
    const readable = ['available', 'limited'].includes(t.status) && t.shards.length > 0;
    el('row-controls').hidden = !readable;
    el('rows').innerHTML = '';
    el('read-status').textContent = readable ? '' : t.status === 'empty_output' ?
      'This output contains no rows.' : (statusLabels[t.status] || 'Unavailable') +
      ': table rows are not included in this export.';
    if (!restore) saveState();
    if (readable) readPage();
  }

  for (const name of ['metadata-query', 'group-filter', 'availability-filter'])
    el(name).addEventListener(name === 'metadata-query' ? 'input' : 'change', () => {
      list();
      saveState();
    });
  el('search-table').addEventListener('submit', event => {
    event.preventDefault();
    page = 0;
    saveState();
    readPage();
  });
  el('retry-read').addEventListener('click', readPage);
  el('cancel-search').addEventListener('click', () => controller?.abort());
  for (const [name, delta] of [['previous-page', -1], ['next-page', 1]])
    el(name).addEventListener('click', () => {
      page = Math.max(0, page + delta);
      saveState();
      readPage();
    });
  el('back-library').addEventListener('click', () => {
    controller?.abort();
    cancel();
    viewEpoch++;
    selected = null;
    el('table-detail').hidden = true;
    el('library').hidden = false;
    detailMode(false);
    saveState();
    list();
  });

  function restore() {
    const p = new URLSearchParams(window.location.search);
    el('metadata-query').value = p.get('q') || '';
    el('group-filter').value = groups.includes(p.get('group')) ? p.get('group') : '';
    el('availability-filter').value = own(statusLabels, p.get('status')) ? p.get('status') : '';
    el('table-query').value = p.get('search') || '';
    page = Math.max(0, Math.floor(Number(p.get('page')) || 1) - 1);
    list();
    if (p.get('table')) open(p.get('table'), true);
    else {
      controller?.abort();
      cancel();
      viewEpoch++;
      selected = null;
      el('table-detail').hidden = true;
      el('library').hidden = false;
      detailMode(false);
    }
  }

  window.addEventListener('popstate', restore);
  restore();
  if (document.documentElement) document.documentElement.dataset.atlasReady = 'outputs';
})(window,document);
