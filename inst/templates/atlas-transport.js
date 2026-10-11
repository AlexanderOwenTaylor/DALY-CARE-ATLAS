(function (window) {
  'use strict';
  // Reviewed, one-way aliases only. Producers remove a target only after equality checking.
  const pairs = [
    ['action_items','action_items'], ['action_summary','action_summary'],
    ['streaming_summary','review_streaming_summary'], ['temporal_date_quality','review_temporal_date_quality'],
    ['db_budget_actions','db_budget_actions'], ['db_query_log','db_query_log'], ['catalog','catalog_rows'],
    ['resource_reconciliation','resource_reconciliation_rows'], ['canonical_resource_reconciliation','canonical_resource_reconciliation_rows'],
    ['current_run_source_map_audit','current_run_source_map_audit_rows'], ['source_map_crosswalk','source_map_crosswalk_rows'],
    ['source_resolution_delta','source_resolution_delta_rows'], ['legacy_resource_audit','legacy_cartography_audit_rows'],
    ['columns','column_profile_rows'], ['column_summary','column_profile_summary'], ['panels','panel_groups'],
    ['qa','qa_items'], ['run_summary','run_summary']
  ];
  const own = (o,k) => o && Object.prototype.hasOwnProperty.call(o,k);
  const MAX_BYTES=67108864;
  const WORK_LIMITS={tables:4096,path_depth:16,schemas_per_table:64,keys_per_schema:64,key_utf8_bytes:128,rows:100000,cells:1000000,json_depth:128};
  const unsafe=key=>key==='__proto__'||key==='constructor'||key==='prototype';
  const record=value=>value!==null&&typeof value==='object'&&!Array.isArray(value)&&
    (Object.getPrototypeOf(value)===Object.prototype||Object.getPrototypeOf(value)===null);
  function equalParts(a,b) {
    if(a.length!==b.length)return false;
    for(let index=0;index<a.length;index++)if(a[index]!==b[index])return false;
    return true;
  }
  function counter(limit) {
    return {used:0,add(amount){this.used+=amount;if(this.used>limit)throw new Error('Payload transport byte limit exceeded');}};
  }
  function stringCharge(value,budget) {
    budget.add(2);
    for(let index=0;index<value.length;index++) {
      const code=value.charCodeAt(index);
      if(code>=0xD800&&code<=0xDBFF) {
        const next=value.charCodeAt(++index);
        if(!(next>=0xDC00&&next<=0xDFFF))throw new Error('Invalid Unicode surrogate');
        budget.add(4);
      } else if(code>=0xDC00&&code<=0xDFFF)throw new Error('Invalid Unicode surrogate');
      else if(code===34||code===92||code===8||code===9||code===10||code===12||code===13)budget.add(2);
      else if(code<32)budget.add(6);
      else budget.add(code<128?1:code<2048?2:3);
    }
  }
  function utf8Length(value) {
    let length=0;
    for(let index=0;index<value.length;index++) {
      const code=value.charCodeAt(index);
      if(code>=0xD800&&code<=0xDBFF) {
        const next=value.charCodeAt(++index);
        if(!(next>=0xDC00&&next<=0xDFFF))throw new Error('Invalid Unicode surrogate');
        length+=4;
      } else if(code>=0xDC00&&code<=0xDFFF)throw new Error('Invalid Unicode surrogate');
      else length+=code<128?1:code<2048?2:3;
    }
    return length;
  }
  function scalarCharge(value,budget) {
    if(value===null)budget.add(4);
    else if(typeof value==='boolean')budget.add(value?4:5);
    else if(typeof value==='number'&&Number.isFinite(value))budget.add(32);
    else if(typeof value==='string')stringCharge(value,budget);
    else throw new Error('Invalid JSON scalar or nonfinite number');
  }
  // Count every serialized occurrence. Active ancestors detect cycles without
  // treating a shared, acyclic subtree as either a cycle or a free occurrence.
  function walkJson(value,budget,depth,ancestors,depthLimit) {
    if(depth>depthLimit)throw new Error('Payload transport JSON depth limit exceeded');
    if(value===null||typeof value!=='object') {scalarCharge(value,budget);return;}
    if(ancestors.has(value))throw new Error('Cyclic transport graph');
    if(!Array.isArray(value)&&!record(value))throw new Error('Invalid JSON record');
    ancestors.add(value);
    const keys=Reflect.ownKeys(value);
    if(Array.isArray(value)) {
      const prototype=Object.getPrototypeOf(value);
      if(prototype!==Array.prototype&&prototype!==null)throw new Error('Invalid JSON array prototype');
      const length=value.length;
      if(keys.length!==length+1)throw new Error('Invalid dense JSON array');
      for(let index=0;index<keys.length;index++)if(typeof keys[index]!=='string')throw new Error('Invalid dense JSON array');
      budget.add(2+Math.max(0,length-1));
      for(let index=0;index<length;index++) {
        const descriptor=Object.getOwnPropertyDescriptor(value,String(index));
        if(!descriptor||!own(descriptor,'value')||!descriptor.enumerable)throw new Error('Invalid dense JSON array or accessor');
        walkJson(descriptor.value,budget,depth+1,ancestors,depthLimit);
      }
    } else {
      budget.add(2+Math.max(0,keys.length-1));
      for(let index=0;index<keys.length;index++) {
        const key=keys[index];
        if(typeof key!=='string')throw new Error('Invalid JSON symbol key');
        const descriptor=Object.getOwnPropertyDescriptor(value,key);
        if(!own(descriptor,'value')||!descriptor.enumerable)throw new Error('Invalid JSON property or accessor');
        stringCharge(key,budget);budget.add(1);
        walkJson(descriptor.value,budget,depth+1,ancestors,depthLimit);
      }
    }
    ancestors.delete(value);
  }
  function normalizedCharge(value,maxBytes=MAX_BYTES,depthLimit=WORK_LIMITS.json_depth) {
    const budget=counter(maxBytes);
    walkJson(value,budget,0,new Set(),depthLimit);
    return budget.used;
  }
  function exactKeys(value,expected,label) {
    if(!record(value)||Object.keys(value).length!==expected.length)throw new Error('Invalid '+label+' shape');
    for(let index=0;index<expected.length;index++)if(!own(value,expected[index]))throw new Error('Invalid '+label+' shape');
  }
  function pathParts(value,limits,label) {
    if(!Array.isArray(value)||value.length===0)throw new Error('Invalid '+label+' path');
    if(value.length>limits.path_depth)throw new Error('Transport path depth limit exceeded');
    for(let index=0;index<value.length;index++) {
      const part=value[index];
      if(typeof part!=='string'||part.length===0||unsafe(part))throw new Error('Invalid or unsafe '+label+' path');
      if(utf8Length(part)>limits.key_utf8_bytes)throw new Error('Transport path key byte limit exceeded');
    }
  }
  function originalDestination(payload,path) {
    let parent=payload;
    for(let index=0;index<path.length;index++) {
      const key=path[index];
      if(!record(parent)||!own(parent,key))throw new Error('Missing or invalid row table path');
      if(index===path.length-1) {
        if(parent[key]!==null)throw new Error('Row table destination must be null');
      } else parent=parent[key];
    }
  }
  function insertPath(trie,path) {
    let node=trie;
    for(let index=0;index<path.length;index++) {
      const key=path[index];
      if(node.terminal)throw new Error('Overlapping row table path');
      if(!node.children.has(key))node.children.set(key,{children:new Map(),terminal:false});
      node=node.children.get(key);
    }
    if(node.terminal||node.children.size)throw new Error('Duplicate or overlapping row table path');
    node.terminal=true;
  }
  function reviewedAlias(alias,strict,limits) {
    if(strict) {
      exactKeys(alias,['target','source'],'alias');
      pathParts(alias.target,limits,'alias target');pathParts(alias.source,limits,'alias source');
    }
    if(alias&&Array.isArray(alias.target)&&Array.isArray(alias.source)) {
      for(let index=0;index<pairs.length;index++) {
        const pair=pairs[index];
        if(equalParts(alias.target,['review_infrastructure_sections',pair[0]])&&equalParts(alias.source,[pair[1]]))return;
      }
    }
    throw new Error('Unreviewed alias path');
  }
  function reachesV2(value,target,seen=new Set()) {
    if(value===target)return true;
    if(!value||typeof value!=='object'||seen.has(value))return false;
    seen.add(value);
    // The complete graph preflight already proved these are own data cells.
    if(Array.isArray(value)) {
      for(let index=0;index<value.length;index++)if(reachesV2(value[index],target,seen))return true;
    } else {
      const keys=Object.keys(value);
      for(let index=0;index<keys.length;index++)if(reachesV2(value[keys[index]],target,seen))return true;
    }
    return false;
  }
  function validateV2Aliases(aliases,payload,packedSources,limits) {
    const seen=new Set();
    for(let index=0;index<aliases.length;index++) {
      const alias=aliases[index];
      reviewedAlias(alias,true,limits);
      const key=alias.target[1],source=alias.source[0];
      if(!own(payload,'review_infrastructure_sections'))throw new Error('Invalid or overwritten alias target');
      const parent=payload.review_infrastructure_sections;
      if(!record(parent)||own(parent,key)||seen.has(key))throw new Error('Invalid or overwritten alias target');
      if(!own(payload,source)||(!Array.isArray(payload[source])&&!packedSources.has(source)))throw new Error('Missing or non-array alias source');
      if(Array.isArray(payload[source])&&reachesV2(payload[source],parent))throw new Error('Cyclic alias source');
      seen.add(key);
    }
  }
  // Define own data properties so untouched __proto__ data never reaches a setter.
  function put(record,key,value) {
    Object.defineProperty(record,key,{value,enumerable:true,configurable:true,writable:true});
  }
  function copyRecord(value) {
    const copy=Object.create(Object.getPrototypeOf(value));
    const keys=Object.keys(value);
    for(let index=0;index<keys.length;index++)put(copy,keys[index],value[keys[index]]);
    return copy;
  }
  function copiedParent(root,path,copies) {
    let parent=root;
    for(let index=0;index<path.length-1;index++) {
      const key=path[index];
      if(!copies.has(parent[key])) {
        const copy=copyRecord(parent[key]);copies.add(copy);put(parent,key,copy);
      }
      parent=parent[key];
    }
    return parent;
  }
  function decodeV2(value,maxBytes=MAX_BYTES,limits=WORK_LIMITS) {
    // These bounded helpers stay private. The browser entry always uses the
    // fixed defense ceilings, independent of caller arguments or environment.
    normalizedCharge(value,maxBytes,limits.json_depth);
    exactKeys(value,['transport_version','payload','aliases','row_tables'],'transport envelope');
    if(!record(value.payload)||!Array.isArray(value.aliases)||!Array.isArray(value.row_tables))throw new Error('Invalid transport payload shape');
    if(value.row_tables.length>limits.tables)throw new Error('Transport table limit exceeded');
    const expanded=counter(maxBytes);expanded.add(normalizedCharge(value.payload,maxBytes,limits.json_depth));
    const trie={children:new Map(),terminal:false},packedSources=new Set();
    let rowCount=0,cellCount=0;
    for(let tableIndex=0;tableIndex<value.row_tables.length;tableIndex++) {
      const table=value.row_tables[tableIndex];
      exactKeys(table,['path','schemas','rows'],'row table');
      pathParts(table.path,limits,'row table');insertPath(trie,table.path);originalDestination(value.payload,table.path);
      if(table.path.length===1)packedSources.add(table.path[0]);
      if(!Array.isArray(table.schemas)||table.schemas.length===0)throw new Error('Invalid empty row table schemas');
      if(table.schemas.length>limits.schemas_per_table)throw new Error('Transport schema limit exceeded');
      const schemaCharges=[];
      for(let index=0;index<table.schemas.length;index++) {
        const schema=table.schemas[index];
        if(!Array.isArray(schema)||schema.length===0)throw new Error('Invalid empty row schema');
        if(schema.length>limits.keys_per_schema)throw new Error('Transport schema key limit exceeded');
        const seenKeys=new Set();
        for(let keyIndex=0;keyIndex<schema.length;keyIndex++) {
          const key=schema[keyIndex];
          if(typeof key!=='string'||key.length===0||unsafe(key)||seenKeys.has(key))throw new Error('Invalid, duplicate or unsafe schema key');
          if(utf8Length(key)>limits.key_utf8_bytes)throw new Error('Transport schema key byte limit exceeded');
          seenKeys.add(key);
        }
        for(let prior=0;prior<index;prior++)if(equalParts(schema,table.schemas[prior]))throw new Error('Duplicate row schema');
        // Repeated key overhead has the same charge for every row of a schema.
        const overhead=counter(maxBytes);overhead.add(2+schema.length-1);
        for(let keyIndex=0;keyIndex<schema.length;keyIndex++) {stringCharge(schema[keyIndex],overhead);overhead.add(1);}
        schemaCharges[index]=overhead.used;
      }
      if(!Array.isArray(table.rows)||table.rows.length<2)throw new Error('Row table requires at least two rows');
      rowCount+=table.rows.length;
      if(rowCount>limits.rows)throw new Error('Transport row limit exceeded');
      expanded.used-=4;expanded.add(2+table.rows.length-1);
      for(let rowIndex=0;rowIndex<table.rows.length;rowIndex++) {
        const row=table.rows[rowIndex];
        if(!Array.isArray(row)||typeof row[0]!=='number'||!Number.isInteger(row[0])||row[0]<0||row[0]>=table.schemas.length)throw new Error('Invalid row schema index');
        const schema=table.schemas[row[0]];
        if(row.length!==schema.length+1)throw new Error('Invalid row width');
        cellCount+=schema.length;
        if(cellCount>limits.cells)throw new Error('Transport scalar cell limit exceeded');
        if(table.path.length+2>limits.json_depth)throw new Error('Expanded payload JSON depth limit exceeded');
        expanded.add(schemaCharges[row[0]]);
        for(let index=0;index<schema.length;index++)scalarCharge(row[index+1],expanded);
      }
    }
    validateV2Aliases(value.aliases,value.payload,packedSources,limits);
    // Every graph, descriptor, original destination, cell and budget has passed.
    // Reconstruction cannot expose a partial write through the input envelope.
    const staged=copyRecord(value.payload),copies=new WeakSet();copies.add(staged);
    for(let tableIndex=0;tableIndex<value.row_tables.length;tableIndex++) {
      const table=value.row_tables[tableIndex];
      const restored=new Array(table.rows.length);
      for(let rowIndex=0;rowIndex<table.rows.length;rowIndex++) {
        const row=table.rows[rowIndex],schema=table.schemas[row[0]],entry=Object.create(Object.prototype);
        for(let index=0;index<schema.length;index++)put(entry,schema[index],row[index+1]);
        restored[rowIndex]=entry;
      }
      put(copiedParent(staged,table.path,copies),table.path[table.path.length-1],restored);
    }
    // Validate all reconstructed sources before any staged alias write.
    validateV2Aliases(value.aliases,staged,new Set(),limits);
    for(let index=0;index<value.aliases.length;index++) {
      const alias=value.aliases[index];
      put(copiedParent(staged,alias.target,copies),alias.target[1],staged[alias.source[0]]);
    }
    return staged;
  }
  function reaches(value,target,seen=new Set(),ancestors=new Set()) {
    if(value===target)return true;
    if(ancestors.has(value))throw new Error('Cyclic alias source');
    if(!value || typeof value!=='object' || seen.has(value))return false;
    seen.add(value);ancestors.add(value);
    const result=Object.keys(value).some(key=>reaches(value[key],target,seen,ancestors));
    ancestors.delete(value);return result;
  }
  function decode(value) {
    if (!value || !own(value,'transport_version')) return value;
    const version=Object.getOwnPropertyDescriptor(value,'transport_version');
    if(!own(version,'value'))throw new Error('Invalid transport version accessor');
    if(version.value===2)return decodeV2(value);
    if (value.transport_version !== 1) throw new Error('Unsupported payload transport version');
    const payload=value.payload;
    if (!payload || typeof payload !== 'object' || Array.isArray(payload) || !Array.isArray(value.aliases)) throw new Error('Invalid transport payload');
    const seen=new Set();
    // Validate the entire envelope before mutating the logical object.
    for (const alias of value.aliases) {
      if (!alias || !Array.isArray(alias.target) || !Array.isArray(alias.source) ||
          !pairs.some(([t,s]) => JSON.stringify(alias.target)===JSON.stringify(['review_infrastructure_sections',t]) && JSON.stringify(alias.source)===JSON.stringify([s]))) throw new Error('Unreviewed alias path');
      const key=alias.target[1], source=alias.source[0], parent=payload.review_infrastructure_sections;
      if (!own(payload,'review_infrastructure_sections') || !parent || typeof parent!=='object' || Array.isArray(parent) || own(parent,key) || seen.has(key)) throw new Error('Invalid or overwritten alias target');
      if (!own(payload,source) || !Array.isArray(payload[source])) throw new Error('Missing alias source');
      if(reaches(payload[source],parent))throw new Error('Cyclic alias source');
      seen.add(key);
    }
    for (const alias of value.aliases) payload.review_infrastructure_sections[alias.target[1]]=payload[alias.source[0]];
    return payload;
  }
  window.DALYCARE_TRANSPORT={decode};
})(window);
