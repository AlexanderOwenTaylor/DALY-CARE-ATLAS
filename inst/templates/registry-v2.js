/* Independent browser verification of the exact, locally generated policy resource. */
(function(root){
'use strict';
const counts=['denominator_n','n_valid','n_missing','n_unrecognised','n_conflicting'];
const estimates=['approximate_mean','p25_band','median_band','p75_band','iqr_lower','iqr_upper','modal_band'];
const metadata=['table_name','source_column','kind','topic','phase','label'];
const schema=['contract_version',...metadata,'policy_version','policy_checksum','mapping_status','collection_status','data_status','publication_status','summary_status','minimum_cell_count','count_basis','summary_method','unit_status','unit_code','unit_evidence_id','unit_evidence_checksum','unit_binding_checksum','numeric_policy_id','numeric_policy_checksum','band_level',...counts,'category_counts_json','numeric_groups_json',...estimates];
const collections=['complete','field_absent','source_unavailable','needs_person_key','missing_person_key','query_failed','resource_limit'];
const states=['unknown','empty_source','all_missing','all_unrecognised','all_conflicting','no_usable_values','usable_values'];
const publications=['published','withheld_privacy','needs_mapping','needs_unit_evidence','needs_numeric_policy','invalid_contract','not_applicable'];
const legacySchema=['contract_version',...metadata,'unit_status','count_basis','summary_method','summary_status','minimum_cell_count','denominator_n','n_valid','n_missing','n_invalid','n_conflicting','n_distinct','minimum_value_support','category_counts_json','mean','median','p25','p75'];
const integer=x=>typeof x==='number'&&Number.isSafeInteger(x)&&x>=0;
const safe=(ns,total,k)=>ns.every(n=>integer(n)&&(n===0||n>=k&&(total-n===0||total-n>=k)));
const same=(a,b)=>a===b || typeof a==='number'&&typeof b==='number'&&Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<=Math.max(1,Math.abs(b))*1e-12;
const status=ns=>ns.reduce((a,b)=>a+b,0)===0?'empty_source':ns[0]>0?'usable_values':ns[1]===ns.reduce((a,b)=>a+b,0)?'all_missing':ns[2]===ns.reduce((a,b)=>a+b,0)?'all_unrecognised':ns[3]===ns.reduce((a,b)=>a+b,0)?'all_conflicting':'no_usable_values';
function strictCells(raw,key){
 if(typeof raw!=='string'||new TextEncoder().encode(raw).length>65536)return null;
 // The flat grammar rejects duplicate keys before JSON.parse can discard them.
 const quoted='"(?:[^"\\\\\\x00-\\x1f]|\\\\(?:["\\\\/bfnrt]|u[0-9a-fA-F]{4}))*"';
 const n='(?:0|[1-9][0-9]*)(?:\\.0+)?';
 const entry=`\\{\\s*(?:"${key}"\\s*:\\s*${quoted}\\s*,\\s*"n"\\s*:\\s*${n}|"n"\\s*:\\s*${n}\\s*,\\s*"${key}"\\s*:\\s*${quoted})\\s*\\}`;
 if(!(new RegExp(`^\\s*\\[\\s*${entry}(?:\\s*,\\s*${entry})*\\s*\\]\\s*$`)).test(raw))return null;
 try{const cells=JSON.parse(raw);return cells.length<=1000&&cells.every(c=>Object.keys(c).length===2&&typeof c[key]==='string'&&integer(c.n)&&c.n>0)?cells:null;}catch{return null;}
}
function bandList(p,level){const v=p.levels[level];return v.slice(0,-1).map((a,i)=>({id:`b${a}_${v[i+1]}`,lower:p.edges[a],upper:p.edges[v[i+1]]}));}
function estimate(cells,bands){
 const used=cells.map(c=>bands.find(b=>b.id===c.band_id)),ns=cells.map(c=>c.n),total=ns.reduce((a,b)=>a+b,0);
 const rank=p=>{let sum=0;return ns.findIndex(n=>(sum+=n)>=Math.ceil(total*p));};const [a,b,c]=[.25,.5,.75].map(rank);
 return {approximate_mean:cells.length>1&&used.every(b=>b.upper!==null)?used.reduce((sum,b,i)=>sum+(b.lower+(b.upper-b.lower)/2)*(ns[i]/total),0):null,p25_band:cells[a].band_id,median_band:cells[b].band_id,p75_band:cells[c].band_id,iqr_lower:used[a].upper===null?0:Math.max(0,used[c].lower-used[a].upper),iqr_upper:used[c].upper===null?null:used[c].upper-used[a].lower,modal_band:cells[ns.indexOf(Math.max(...ns))].band_id};
}
function validate(row,resource,k=5){
 try{
 if(!row||Object.keys(row).length!==schema.length||schema.some(n=>!Object.prototype.hasOwnProperty.call(row,n))||!resource||resource.version!=='registry-summary-v2')return null;
 const s=resource.fields.find(s=>s.table_name===row.table_name&&s.source_column===row.source_column);if(!s)return null;
 if(s.kind==='categorical'&&['needs_unit_evidence','needs_numeric_policy'].includes(row.publication_status))return null;
 if(metadata.some(n=>row[n]!==s[n])||row.contract_version!==resource.version||row.policy_version!==resource.version||row.policy_checksum!==resource.checksum||row.mapping_status!==s.mapping_status||row.count_basis!=='distinct_people_one_unambiguous_value_per_field'||row.summary_method!==(s.kind==='numeric'?'fixed_bands_midpoint_mean_nearest_rank_intervals':'complete_reviewed_recorded_codes'))return null;
 if(!integer(row.minimum_cell_count)||row.minimum_cell_count<Math.max(5,k)||!collections.includes(row.collection_status)||!states.includes(row.data_status)||!publications.includes(row.publication_status))return null;
 k=row.minimum_cell_count;const binding=s.binding||null;
 const expected=binding?{unit_status:'verified',unit_code:binding.evidence.unit_code,unit_evidence_id:binding.evidence.evidence_id,unit_evidence_checksum:binding.evidence.evidence_checksum.toLowerCase(),unit_binding_checksum:binding.evidence.binding_checksum,numeric_policy_id:binding.policy.numeric_policy_id,numeric_policy_checksum:binding.policy.checksum}:{unit_status:'unverified',unit_code:null,unit_evidence_id:null,unit_evidence_checksum:null,unit_binding_checksum:null,numeric_policy_id:null,numeric_policy_checksum:null};
 if(Object.keys(expected).some(n=>row[n]!==expected[n]))return null;
 if(row.publication_status!=='published'&&row.data_status==='unknown'){
   const summary=row.collection_status==='complete'?row.publication_status:row.collection_status;
   return row.summary_status===summary&&row.category_counts_json==='[]'&&row.numeric_groups_json==='[]'&&[...counts,...estimates,'band_level'].every(n=>row[n]===null)?{...row,categories:[],groups:[]}:null;
 }
 const ns=counts.map(n=>row[n]);if(ns.some(n=>!integer(n))||ns.slice(1).reduce((a,b)=>a+b,0)!==ns[0]||!safe(ns.slice(1),ns[0],k)||row.data_status!==status(ns.slice(1))||row.collection_status!=='complete')return null;
 if(ns[1]===0)return row.publication_status===(row.data_status==='all_unrecognised'?'needs_mapping':'not_applicable')&&row.summary_status===row.data_status&&row.category_counts_json==='[]'&&row.numeric_groups_json==='[]'&&[...estimates,'band_level'].every(n=>row[n]===null)?{...row,categories:[],groups:[]}:null;
 if(row.publication_status!=='published'||row.summary_status!=='published')return null;
 const numeric=s.kind==='numeric',key=numeric?'band_id':'code',cells=strictCells(row[numeric?'numeric_groups_json':'category_counts_json'],key);if(!cells)return null;
 let allowed,bands;
 if(numeric){
  if(!binding||row.category_counts_json!=='[]'||!integer(row.band_level)||row.band_level>=binding.policy.levels.length||ns[1]<binding.policy.minimum_people)return null;
  bands=bandList(binding.policy,row.band_level);allowed=bands.map(b=>b.id);
 }else{
  if(row.numeric_groups_json!=='[]'||[...estimates,'band_level'].some(n=>row[n]!==null))return null;
  allowed=s.codes.map(c=>c.code);
 }
 const ids=cells.map(c=>c[key]);if(new Set(ids).size!==ids.length||ids.some(id=>!allowed.includes(id)))return null;
 cells.sort((a,b)=>allowed.indexOf(a[key])-allowed.indexOf(b[key]));const n=cells.map(c=>c.n);
 if(n.reduce((a,b)=>a+b,0)!==ns[1]||!safe(n,ns[0],k)||!safe(n,ns[1],k))return null;
 if(numeric){const est=estimate(cells,bands);if(estimates.some(n=>!same(row[n],est[n])))return null;}
 return {...row,categories:numeric?[]:cells.map(c=>({...c,label:s.codes.find(v=>v.code===c.code).label})),groups:numeric?cells.map(c=>({...c,...bands.find(b=>b.id===c.band_id)})):[]};
 }catch{return null;}
}
function validateLegacy(row,resource,k=5){
 try{
  if(!row||Object.keys(row).length!==legacySchema.length||legacySchema.some(n=>!Object.prototype.hasOwnProperty.call(row,n)))return null;
  const field=resource.fields.find(s=>s.table_name===row.table_name&&s.source_column===row.source_column);
  if(!field||metadata.some(n=>field[n]!==row[n])||row.contract_version!=='registry-summary-v1'||row.unit_status!=='unverified'||row.count_basis!=='distinct_people_one_unambiguous_value_per_field'||row.summary_method!=='exact_complete_field_3sf'||!integer(row.minimum_cell_count)||row.minimum_cell_count<Math.max(5,k))return null;
  k=row.minimum_cell_count;const quantities=['denominator_n','n_valid','n_missing','n_invalid','n_conflicting','n_distinct','minimum_value_support','mean','median','p25','p75'];
  if(row.summary_status!=='published')return ['needs_person_key','missing_person_key','field_unavailable','query_failed','resource_limit','withheld_small_group','withheld_constant','withheld_near_unique','no_values','invalid_contract','needs_unit_evidence'].includes(row.summary_status)&&row.category_counts_json==='[]'&&quantities.every(n=>row[n]===null)?row:null;
  if(row.kind!=='categorical'||['n_distinct','minimum_value_support','mean','median','p25','p75'].some(n=>row[n]!==null))return null;
  const ns=quantities.slice(0,5).map(n=>row[n]);if(!ns.every(integer)||ns[1]<=0||ns.slice(1).reduce((a,b)=>a+b,0)!==ns[0]||!safe(ns,ns[0],k))return null;
  const cells=strictCells(row.category_counts_json,'code');if(!cells||cells.some(c=>!field.legacy_categories.includes(c.code))||new Set(cells.map(c=>c.code)).size!==cells.length)return null;
  const n=cells.map(c=>c.n);return n.reduce((a,b)=>a+b,0)===ns[1]&&safe(n,ns[0],k)&&safe(n,ns[1],k)?row:null;
 }catch{return null;}
}
root.DALYCARERegistryV2={validate,validateLegacy,estimate,bandList,strictCells,schema,legacySchema};
if(typeof module==='object'&&module.exports)module.exports=root.DALYCARERegistryV2;
})(typeof window==='object'?window:globalThis);
