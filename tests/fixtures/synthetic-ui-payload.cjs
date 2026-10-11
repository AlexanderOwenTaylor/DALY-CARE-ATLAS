// Invented test data only. Public field identities and reference definitions come
// from the committed dictionaries; no counts or statistics come from an export.
const fs = require('node:fs');
const path = require('node:path');

// RFC 4180 quoted fields, escaped quotes, commas and embedded newlines. The
// dictionaries include commas in definitions and must not be split by line.
function parseCsv(raw) {
  const records = []; let record = [], value = '', quoted = false;
  raw = raw.replace(/^\uFEFF/, '');
  for (let i = 0; i < raw.length; i++) {
    const ch = raw[i];
    if (ch === '"') {
      if (quoted && raw[i + 1] === '"') { value += '"'; i++; }
      else quoted = !quoted;
    } else if (!quoted && ch === ',') { record.push(value); value = ''; }
    else if (!quoted && (ch === '\n' || ch === '\r')) {
      if (ch === '\r' && raw[i + 1] === '\n') i++;
      record.push(value); records.push(record); record = []; value = '';
    } else value += ch;
  }
  if (quoted) throw new Error('Unterminated quoted CSV field');
  if (value || record.length) { record.push(value); records.push(record); }
  const headers = records.shift();
  return records.filter(row => row.some(Boolean)).map(row => {
    if (row.length !== headers.length) throw new Error('Invalid dictionary CSV row width');
    return Object.fromEntries(headers.map((key, i) => [key, row[i]]));
  });
}
function dictionary(name) {
  return parseCsv(fs.readFileSync(path.join(__dirname, '../../config', name), 'utf8'));
}
function createSyntheticPayload() {
  const columns = [];
  const field = (table_name, column_name, extra = {}) => ({table_name, column_name,
    profile_kind: 'categorical', domain: 'Synthetic fixture', n_available: 600,
    n_missing: 400, pct_available: 60, ...extra});
  const numeric = {profile_kind:'numeric', numeric_privacy_status:'eligible_stored_summary', mean:51, median:52, p25:41, p75:63};
  const review = {profile_kind:'numeric', numeric_privacy_status:'needs_validation_negative_sentinel', mean:null, median:null, p25:null, p75:null};
  function source(name, initial, size) {
    columns.push(...initial.map(([column, extra]) => field(name,column,extra)));
    for (let i = initial.length; i < size; i++) columns.push(field(name,`synthetic_field_${String(i).padStart(3,'0')}`));
  }
  source('RKKP_CLL', [['Reg_BinetStadium',{}],['Reg_Leukocyttal',review]], 83);
  source('RKKP_DaMyDa', [['Reg_Vaegt',{...review,n_available:583,n_missing:417,pct_available:58.324}],['Reg_Hoejde',review],['Reg_Haemoglobin',numeric],['PB_Haemoglobin',numeric]],127);
  source('RKKP_LYFO', [['subtype',{}],['Reg_Haemoglobin',numeric],['Beh_Vaegttab',{}]],4);
  source('SP_PatientInfo', [['weight_in_kg',{...numeric,n_available:638,n_missing:362,pct_available:63.797}],['height_in_cm',numeric],['bmi',numeric],['contact_date',{profile_kind:'date',value_privacy_status:'protected_field'}]],5);
  source('SP_SocialHX', [['ryger',{}]],1);
  source('CLLPANEL_WIDE', [['Weightloss',{}],['weight_in_kg',numeric]],2); // similar name, wrong source
  source('EKOKUR', [['synthetic_field',{}]],1);
  const canonical = ['RKKP_CLL','RKKP_DaMyDa','RKKP_LYFO','SP_PatientInfo','EKOKUR'].map(id => ({canonical_resource_id:id,
    current_resolved_source_key:id, current_status:id==='EKOKUR'?'legacy_unavailable_current_resolved':'current_profiled',
    current_n_rows:1234,current_n_columns:columns.filter(r=>r.table_name===id).length,
    resource_role:'canonical_resource',notes:id==='EKOKUR'?'SDS_ekokur public source identity':''}));
  canonical.push({canonical_resource_id:'DANRICHT',current_status:'manual_file_not_available',resource_role:'special_manual_or_embedded'},
    {canonical_resource_id:'FISH',display_name:'FISH cytogenetics',current_status:'embedded_fields_represented',resource_role:'special_manual_or_embedded'});
  const years = (table_name,date_column,start,counts) => counts.map((n_rows,i)=>({table_name,date_column,year:start+i,n_rows,value_privacy_status:'protected_field'}));
  const withheld = {n_rows:null,value_privacy_status:'withheld_unvalidated_distribution'};
  return {
    fixture_notice:'SYNTHETIC TEST DATA — invented counts and statistics; not a dataset export',
    generated_at:'2099-01-01',loaded_source_count:8,column_count:columns.length,
    column_profile_rows:columns,canonical_resource_reconciliation_rows:canonical,
    source_map_crosswalk_rows:canonical.filter(r=>r.current_resolved_source_key).map(r=>({canonical_resource_id:r.canonical_resource_id,source_map_key:r.current_resolved_source_key})),
    catalog_rows:canonical.filter(r=>r.current_resolved_source_key).map(r=>({table_name:r.current_resolved_source_key,n_rows:1234})),
    clinical_display_dictionary:dictionary('clinical-display-dictionary.csv'),npu_display_dictionary:dictionary('npu-display-dictionary.csv'),
    review_temporal_coverage:{sources:[{table_name:'SP_PatientInfo',date_column:'contact_date',pct_available:27.438},
      {table_name:'RKKP_DaMyDa',date_column:'Diagnosedato'}],years:[...years('SP_PatientInfo','contact_date',2030,[11,22,33,44]),
      ...years('RKKP_DaMyDa','Diagnosedato',2028,[15,25,35,45,55])]},
    review_spatial_coverage:{region_counts:['Region A','Region B','Other/unknown'].map((region_name,i)=>({table_name:'RKKP_DaMyDa',region_column:'Region',region_name,n_rows:20+i*10}))},
    review_situation_sections:{cards:Array.from({length:3},(_,i)=>({metric_id:`synthetic_metric_${i}`,definition_status:'ok',n_patients:null,value_privacy_status:'withheld_unvalidated_distribution'}))},
    situation_report_cards:[],panels:{lab_npu_code_coverage:[{lab_code:null,...withheld}],mm_treatment_code_counts:[{code:null,...withheld}]}
  };
}
module.exports = {createSyntheticPayload, parseCsv};
