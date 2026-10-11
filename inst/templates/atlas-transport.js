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
