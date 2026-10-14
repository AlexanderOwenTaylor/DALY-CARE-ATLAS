# Version two is a separate contract. Local evidence is never inferred from names.
registry_v2_counts <- c('denominator_n','n_valid','n_missing','n_unrecognised','n_conflicting')
registry_v2_estimates <- c('approximate_mean','p25_band','median_band','p75_band','iqr_lower','iqr_upper','modal_band')
registry_v2_schema <- c('contract_version','table_name','source_column','kind','topic','phase','label',
  'policy_version','policy_checksum','mapping_status','collection_status','data_status','publication_status',
  'summary_status','minimum_cell_count','count_basis','summary_method','unit_status','unit_code',
  'unit_evidence_id','unit_evidence_checksum','unit_binding_checksum','numeric_policy_id','numeric_policy_checksum','band_level',
  registry_v2_counts,'category_counts_json','numeric_groups_json',registry_v2_estimates)
registry_v2_numbers <- c('minimum_cell_count','band_level',registry_v2_counts,'approximate_mean','iqr_lower','iqr_upper')
registry_v2_collection <- c('complete','field_absent','source_unavailable','needs_person_key','missing_person_key','query_failed','resource_limit')
registry_v2_data <- c('unknown','empty_source','all_missing','all_unrecognised','all_conflicting','no_usable_values','usable_values')
registry_v2_publication <- c('published','withheld_privacy','needs_mapping','needs_unit_evidence','needs_numeric_policy','invalid_contract','not_applicable')
registry_v2_completed_status <- function(parts) {
  if(sum(parts)==0)return('empty_source')
  if(parts[1]>0)return('usable_values')
  states<-c('usable_values','all_missing','all_unrecognised','all_conflicting')
  hit<-which(parts==sum(parts));if(length(hit))states[hit[1]] else 'no_usable_values'
}
registry_v2_json <- function(x) as.character(jsonlite::toJSON(x,auto_unbox=TRUE,null='null',digits=NA))
registry_v2_read <- function(path,limit=1048576) {
  if(!length(path)||!nzchar(path)||!file.exists(path)||file.info(path)$size>limit) return(NULL)
  tryCatch(jsonlite::fromJSON(path,simplifyVector=FALSE),error=function(e) NULL)
}
registry_v2_path <- function(root,name) {
  paths <- c(file.path(root,'config',name),file.path(root,'inst/config',name),system.file('config',name,package='dalycareatlas'))
  paths <- paths[nzchar(paths)&file.exists(paths)];if(length(paths)) paths[1] else ''
}
registry_v2_policy <- function(root='.') {
  path <- registry_v2_path(root,'registry-summary-policy-v2.json');p <- registry_v2_read(path)
  if(is.null(p)||length(names(p))!=2||!setequal(names(p),c('version','fields'))||!identical(p$version,'registry-summary-v2')||length(p$fields)!=217L) return(NULL)
  legacy<-atlas_registry_privacy_policy(root)
  mappings<-registry_v2_read(registry_v2_path(root,'registry-source-mappings.json'))$records
  seen<-character()
  for(s in p$fields) {
    if(!is.list(s)||length(names(s))!=9L||!setequal(names(s),c(atlas_registry_privacy_metadata,'mapping_status','codes','mappings')))return(NULL)
    id<-atlas_registry_privacy_identity(s);old<-legacy[[id]]
    if(is.null(old)||id %in% seen||!identical(s[atlas_registry_privacy_metadata],old[atlas_registry_privacy_metadata]))return(NULL)
    expected<-Filter(function(m)identical(m$table_name,s$table_name)&&identical(m$source_column,s$source_column),mappings)
    if(!identical(s$mappings,expected)||s$mapping_status!=if(length(expected))'local_reviewed_recognition' else 'recorded_codes_meaning_unverified')return(NULL)
    allowed<-unique(c(unlist(old$categories),vapply(expected,function(m)m$canonical_token,character(1))))
    if(!is.list(s$codes)||length(s$codes)!=length(allowed))return(NULL)
    for(i in seq_along(allowed)) {
      c<-s$codes[[i]];labels<-Filter(function(m)m$canonical_token==allowed[i],expected)
      label<-if(length(labels))tail(labels,1)[[1]]$display_label else paste0('Recorded code ',allowed[i],'; meaning unverified')
      if(!is.list(c)||length(names(c))!=2||!setequal(names(c),c('code','label'))||!identical(c$code,allowed[i])||!identical(c$label,label))return(NULL)
    }
    seen<-c(seen,id)
  }
  p$checksum <- digest::digest(readBin(path,'raw',n=file.info(path)$size),algo='sha256',serialize=FALSE);p
}
registry_v2_numeric_policy <- function(root='.') {
  path <- Sys.getenv('DALYCARE_REGISTRY_NUMERIC_POLICY_FILE','');p <- registry_v2_read(path,262144)
  if(!is.list(p)||!identical(sort(names(p)),sort(c('version','policies')))||!identical(p$version,'registry-numeric-policy-v1')||!is.list(p$policies)||length(p$policies)>217) return(list())
  fields <- registry_v2_policy(root)$fields;out <- list();seen <- character()
  for(s in p$policies) {
    keys <- c('numeric_policy_id','table_name','source_column','unit_code','edges','levels','minimum_people','constant_policy')
    if(!is.list(s)||length(names(s))!=length(keys)||!setequal(names(s),keys)||!all(vapply(keys[1:4],function(k) is.character(s[[k]])&&length(s[[k]])==1&&nzchar(s[[k]])&&nchar(s[[k]])<=160,logical(1)))) return(list())
    field <- Filter(function(f) identical(f$table_name,s$table_name)&&identical(f$source_column,s$source_column)&&f$kind=='numeric',fields)
    if(length(field)!=1||s$numeric_policy_id %in% seen||!identical(s$constant_policy,'withhold')||!is.numeric(s$minimum_people)||length(s$minimum_people)!=1||!is.finite(s$minimum_people)||s$minimum_people>9007199254740991||s$minimum_people<20||s$minimum_people!=floor(s$minimum_people)) return(list())
    edges <- s$edges
    if(!is.list(edges)||length(edges)<3||length(edges)>65||!is.null(tail(edges,1)[[1]])) return(list())
    finite <- head(edges,-1)
    if(!all(vapply(finite,function(x) is.numeric(x)&&length(x)==1&&is.finite(x)&&x>=0&&x<=1e100,logical(1)))) return(list())
    e <- unlist(finite);if(e[1]!=0||any(diff(e)<=0)||!is.list(s$levels)||!length(s$levels)||length(s$levels)>16) return(list())
    previous <- seq_along(edges)-1L
    for(level in s$levels) {
      if(!is.list(level)||!length(level)||!all(vapply(level,function(x)is.numeric(x)&&length(x)==1&&is.finite(x)&&x==floor(x),logical(1)))) return(list())
      v <- unlist(level);if(length(v)<2||v[1]!=0||tail(v,1)!=length(edges)-1||any(diff(v)<=0)||any(!v %in% previous)) return(list())
      previous <- v
    }
    if(!identical(as.numeric(unlist(s$levels[[1]])),as.numeric(seq_along(edges)-1L))) return(list())
    s$checksum <- digest::digest(readBin(path,'raw',n=file.info(path)$size),algo='sha256',serialize=FALSE);out[[s$numeric_policy_id]]<-s;seen<-c(seen,s$numeric_policy_id)
  };out
}
registry_v2_units <- function(root='.') {
  p<-registry_v2_read(Sys.getenv('DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE',''),262144)
  if(!is.list(p)||!identical(sort(names(p)),sort(c('version','bindings')))||!identical(p$version,'registry-unit-evidence-v2')||!is.list(p$bindings)||length(p$bindings)>217)return(list())
  keys<-c('table_name','source_column','unit_code','stored_to_display_multiplier','stored_to_display_offset','evidence_id','evidence_source','evidence_revision','evidence_checksum','review_status','numeric_policy_id','numeric_policy_checksum','numeric_policy_version','evidence_tier')
  seen<-character()
  for(b in p$bindings) {
    if(!is.list(b)||length(names(b))!=length(keys)||!setequal(names(b),keys)||!all(vapply(setdiff(keys,c('stored_to_display_multiplier','stored_to_display_offset')),function(k)is.character(b[[k]])&&length(b[[k]])==1&&nzchar(b[[k]])&&nchar(b[[k]])<=1024,logical(1))))return(list())
    if(!all(vapply(c('stored_to_display_multiplier','stored_to_display_offset'),function(k)is.numeric(b[[k]])&&length(b[[k]])==1&&is.finite(b[[k]]),logical(1)))||b$stored_to_display_multiplier<=0||b$review_status!='verified'||b$evidence_tier!='authoritative_source_metadata'||b$numeric_policy_version!='registry-numeric-policy-v1'||!grepl('^[a-fA-F0-9]{64}$',b$evidence_checksum)||!grepl('^[a-f0-9]{64}$',b$numeric_policy_checksum))return(list())
    id<-registry_v2_json(b[c('table_name','source_column')]);if(id %in% seen)return(list());seen<-c(seen,id)
  }
  path<-Sys.getenv('DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE','');checksum<-digest::digest(readBin(path,'raw',n=file.info(path)$size),algo='sha256',serialize=FALSE)
  lapply(p$bindings,function(b){b$binding_checksum<-checksum;b})
}
registry_v2_fields <- function(root='.') {
  p <- registry_v2_policy(root);if(is.null(p))return(list())
  bindings<-registry_v2_units(root);policies<-registry_v2_numeric_policy(root)
  lapply(p$fields,function(s) {
    s$policy_checksum<-p$checksum;s$binding<-NULL;s$numeric_policy_missing<-FALSE
    b<-Filter(function(b)identical(b$table_name,s$table_name)&&identical(b$source_column,s$source_column),bindings)
    if(length(b)==1) {
      b<-b[[1]];n<-policies[[b$numeric_policy_id]]
      s$numeric_policy_missing<-is.null(n)
      if(!is.null(n)&&identical(n$table_name,b$table_name)&&identical(n$source_column,b$source_column)&&identical(n$unit_code,b$unit_code)&&identical(n$checksum,b$numeric_policy_checksum))s$binding<-list(evidence=b,policy=n)
    };s
  })
}
registry_v2_row <- function(s,status,k,data_status='unknown') {
  r<-setNames(rep(list(NULL),length(registry_v2_schema)),registry_v2_schema)
  for(n in atlas_registry_privacy_metadata)r[[n]]<-s[[n]]
  r$contract_version<-'registry-summary-v2';r$policy_version<-'registry-summary-v2';r$policy_checksum<-s$policy_checksum
  r$mapping_status<-s$mapping_status;r$count_basis<-'distinct_people_one_unambiguous_value_per_field'
  r$summary_method<-if(s$kind=='numeric')'fixed_bands_midpoint_mean_nearest_rank_intervals' else 'complete_reviewed_recorded_codes'
  r$minimum_cell_count<-k;r$collection_status<-if(status %in% registry_v2_collection)status else 'complete'
  r$data_status<-data_status;r$publication_status<-if(status %in% registry_v2_publication)status else 'not_applicable'
  r$summary_status<-if(status=='complete')data_status else status
  r$unit_status<-'unverified';r$category_counts_json<-'[]';r$numeric_groups_json<-'[]'
  if(!is.null(s$binding)) {
    b<-s$binding$evidence;p<-s$binding$policy;r$unit_status<-'verified';r$unit_code<-b$unit_code
    r$unit_evidence_id<-b$evidence_id;r$unit_evidence_checksum<-tolower(b$evidence_checksum);r$unit_binding_checksum<-b$binding_checksum
    r$numeric_policy_id<-p$numeric_policy_id;r$numeric_policy_checksum<-p$checksum
  };r
}
registry_v2_frame <- function(rows=list()) {
  as.data.frame(setNames(lapply(registry_v2_schema,function(k) {
    if(k %in% registry_v2_numbers) vapply(rows,function(r)if(is.null(r[[k]])) NA_real_ else as.numeric(r[[k]]),numeric(1))
    else vapply(rows,function(r)if(is.null(r[[k]])) NA_character_ else as.character(r[[k]]),character(1))
  }),registry_v2_schema),stringsAsFactors=FALSE)
}
registry_contract_frame <- function(rows) {
  if(!length(rows))return(registry_v2_frame())
  keys<-unique(unlist(lapply(rows,names),use.names=FALSE));numbers<-unique(c(registry_v2_numbers,atlas_registry_privacy_counts,atlas_registry_privacy_stats))
  frame<-as.data.frame(setNames(lapply(keys,function(k) {
    if(k %in% numbers)vapply(rows,function(r)if(is.null(r[[k]]))NA_real_ else as.numeric(r[[k]]),numeric(1))
    else vapply(rows,function(r)if(is.null(r[[k]]))NA_character_ else as.character(r[[k]]),character(1))
  }),keys),stringsAsFactors=FALSE)
  if(length(unique(vapply(rows,function(r)r$contract_version,character(1))))>1)attr(frame,'registry_contract_rows')<-rows
  frame
}
registry_v2_safe <- function(n,total,k) all(is.finite(n)&n>=0&n==floor(n)&n<=9007199254740991)&all(n==0|(n>=k&(total-n==0|total-n>=k)))
registry_v2_bands <- function(p,level) {
  v<-unlist(p$levels[[level+1L]]);lapply(seq_len(length(v)-1L),function(i)list(id=paste0('b',v[i],'_',v[i+1]),lower=p$edges[[v[i]+1L]],upper=p$edges[[v[i+1]+1L]]))
}
registry_v2_estimate <- function(cells,bands) {
  n<-vapply(cells,function(c)c$n,numeric(1));ids<-vapply(cells,function(c)c$band_id,character(1));all_ids<-vapply(bands,function(b)b$id,character(1));b<-bands[match(ids,all_ids)]
  rank_band<-function(p) which(cumsum(n)>=ceiling(sum(n)*p))[1]
  q<-vapply(c(.25,.5,.75),rank_band,integer(1));low<-function(i)b[[i]]$lower;upper<-function(i)b[[i]]$upper
  closed<-all(vapply(b,function(b)!is.null(b$upper),logical(1)))
  avg<-if(closed&&length(cells)>1)sum(vapply(b,function(b)b$lower+(b$upper-b$lower)/2,numeric(1))*(n/sum(n))) else NULL
  list(approximate_mean=avg,p25_band=ids[q[1]],median_band=ids[q[2]],p75_band=ids[q[3]],
    iqr_lower=if(is.null(upper(q[1])))0 else max(0,low(q[3])-upper(q[1])),
    iqr_upper=if(is.null(upper(q[3])))NULL else upper(q[3])-low(q[1]),modal_band=ids[which.max(n)])
}
registry_v2_from_groups <- function(s,groups,k) {
  fail<-function(status,data='unknown')registry_v2_row(s,status,k,data)
  if(is.data.frame(groups)&&'n' %in% names(groups)) {
    if(is.logical(groups$n))return(fail('query_failed'))
    groups$n<-suppressWarnings(as.numeric(groups$n))
  }
  if(!is.data.frame(groups)||!setequal(names(groups),c('status','value','n'))||any(!groups$status %in% c('valid','missing','invalid','conflicting','key_missing','constant'))||any(!is.finite(groups$n)|groups$n<0|groups$n!=floor(groups$n)|groups$n>9007199254740991))return(fail('query_failed'))
  if(any(groups$status=='key_missing'&groups$n>0))return(fail('missing_person_key'))
  constant<-any(groups$status=='constant'&groups$n>0);groups<-groups[!groups$status %in% c('key_missing','constant'),,drop=FALSE]
  parts<-setNames(vapply(c('valid','missing','invalid','conflicting'),function(st)sum(groups$n[groups$status==st]),numeric(1)),c('valid','missing','invalid','conflicting'))
  total<-sum(parts);data<-registry_v2_completed_status(parts)
  if(!registry_v2_safe(parts,total,k))return(fail('withheld_privacy'))
  if(parts['valid']==0) {
    out<-fail('complete',data);out$publication_status<-if(data=='all_unrecognised')'needs_mapping' else 'not_applicable'
    out$summary_status<-data;out[registry_v2_counts]<-as.list(c(total,unname(parts)));return(out)
  }
  if(s$kind=='numeric'&&is.null(s$binding))return(fail(if(isTRUE(s$numeric_policy_missing))'needs_numeric_policy' else 'needs_unit_evidence'))
  g<-groups[groups$status=='valid'&groups$n>0,,drop=FALSE]
  if(anyDuplicated(g$value))return(fail('query_failed'))
  out<-fail('published',data)
  if(s$kind=='categorical') {
    allowed<-vapply(s$codes,function(c)c$code,character(1))
    if(any(!g$value %in% allowed))return(fail('query_failed'))
    if(!registry_v2_safe(g$n,total,k)||!registry_v2_safe(g$n,parts['valid'],k))return(fail('withheld_privacy'))
    g<-g[order(match(g$value,allowed)),,drop=FALSE]
    out$category_counts_json<-registry_v2_json(lapply(seq_len(nrow(g)),function(i)list(code=g$value[i],n=g$n[i])))
  } else {
    p<-s$binding$policy
    if(parts['valid']<p$minimum_people||constant)return(fail('withheld_privacy'))
    base<-registry_v2_bands(p,0);ids<-vapply(base,function(b)b$id,character(1))
    if(any(!g$value %in% ids))return(fail('query_failed'))
    counts<-setNames(rep(0,length(base)),ids);counts[g$value]<-g$n;chosen<-NULL
    for(level in seq_along(p$levels)-1L) {
      boundaries<-unlist(p$levels[[level+1L]]);bands<-registry_v2_bands(p,level)
      n<-vapply(seq_along(bands),function(i)sum(counts[seq.int(boundaries[i]+1L,boundaries[i+1L])]),numeric(1))
      if(registry_v2_safe(n,total,k)&&registry_v2_safe(n,parts['valid'],k)){chosen<-level;break}
    }
    if(is.null(chosen))return(fail('withheld_privacy'))
    cells<-lapply(which(n>0),function(i)list(band_id=bands[[i]]$id,n=n[i]))
    out$band_level<-chosen;out$numeric_groups_json<-registry_v2_json(cells)
    out[registry_v2_estimates]<-registry_v2_estimate(cells,bands)
  }
  out[registry_v2_counts]<-as.list(c(total,unname(parts)));out
}

# Strict validation of original records. No publication is granted by a marker.
registry_v2_validate <- function(row,s,k) {
  if(!is.list(row)||length(names(row))!=length(registry_v2_schema)||!setequal(names(row),registry_v2_schema)||anyDuplicated(names(row)))return(NULL)
  if(!all(vapply(c('collection_status','data_status','publication_status','summary_status','category_counts_json','numeric_groups_json'),function(n)is.character(row[[n]])&&length(row[[n]])==1&&!is.na(row[[n]]),logical(1))))return(NULL)
  if(s$kind=='categorical'&&row$publication_status %in% c('needs_unit_evidence','needs_numeric_policy'))return(NULL)
  if(!is.numeric(row$minimum_cell_count)||length(row$minimum_cell_count)!=1||is.na(atlas_registry_privacy_integer(row$minimum_cell_count))||row$minimum_cell_count<k)return(NULL)
  if(!row$collection_status %in% registry_v2_collection||!row$data_status %in% registry_v2_data||!row$publication_status %in% registry_v2_publication)return(NULL)
  canonical<-registry_v2_row(s,if(row$collection_status=='complete')row$publication_status else row$collection_status,k,row$data_status)
  meta<-setdiff(registry_v2_schema,c(registry_v2_counts,registry_v2_estimates,'category_counts_json','numeric_groups_json','band_level','summary_status'))
  if(!all(vapply(meta,function(n)identical(row[[n]],canonical[[n]])||(is.numeric(row[[n]])&&is.numeric(canonical[[n]])&&identical(as.numeric(row[[n]]),as.numeric(canonical[[n]]))),logical(1))))return(NULL)
  q<-c(registry_v2_counts,registry_v2_estimates,'band_level')
  if(row$publication_status!='published'&&row$data_status=='unknown') {
    if(row$summary_status!=canonical$summary_status||row$category_counts_json!='[]'||row$numeric_groups_json!='[]'||any(vapply(q,function(n)!is.null(row[[n]]),logical(1))))return(NULL)
    return(canonical)
  }
  n<-vapply(registry_v2_counts,function(n)if(is.numeric(row[[n]]))atlas_registry_privacy_integer(row[[n]]) else NA_real_,numeric(1))
  if(anyNA(n)||sum(n[-1])!=n[1]||!registry_v2_safe(n[-1],n[1],k))return(NULL)
  status<-registry_v2_completed_status(n[-1])
  if(row$data_status!=status||row$collection_status!='complete')return(NULL)
  if(n[2]==0) {
    expected<-if(status=='all_unrecognised')'needs_mapping' else 'not_applicable'
    if(row$publication_status!=expected||row$summary_status!=status||row$category_counts_json!='[]'||row$numeric_groups_json!='[]'||any(vapply(c(registry_v2_estimates,'band_level'),function(n)!is.null(row[[n]]),logical(1))))return(NULL)
    canonical$summary_status<-status;canonical[registry_v2_counts]<-as.list(n);return(canonical)
  }
  if(row$publication_status!='published'||row$summary_status!='published')return(NULL)
  parse<-function(raw,keys) {
    if(!is.character(raw)||length(raw)!=1||nchar(raw,type='bytes')>65536)return(NULL)
    cells<-tryCatch(jsonlite::fromJSON(raw,simplifyVector=FALSE),error=function(e)NULL)
    if(is.null(cells)||!is.list(cells)||!is.null(names(cells))||!length(cells)||length(cells)>1000)return(NULL)
    if(!all(vapply(cells,function(c)is.list(c)&&length(names(c))==2&&!anyDuplicated(names(c))&&setequal(names(c),keys)&&is.numeric(c$n)&&!is.na(atlas_registry_privacy_integer(c$n))&&c$n>0,logical(1))))return(NULL)
    cells
  }
  if(s$kind=='categorical') {
    if(row$numeric_groups_json!='[]'||any(vapply(c(registry_v2_estimates,'band_level'),function(n)!is.null(row[[n]]),logical(1))))return(NULL)
    cells<-parse(row$category_counts_json,c('code','n'));if(is.null(cells))return(NULL)
    allowed<-vapply(s$codes,function(c)c$code,character(1));ids<-vapply(cells,function(c)if(is.character(c$code)&&length(c$code)==1)c$code else '',character(1))
    if(any(!ids %in% allowed)||anyDuplicated(ids))return(NULL)
    cells<-cells[order(match(ids,allowed))];canonical$category_counts_json<-registry_v2_json(cells)
  } else {
    if(is.null(s$binding)||row$category_counts_json!='[]'||!is.numeric(row$band_level)||is.na(atlas_registry_privacy_integer(row$band_level)))return(NULL)
    p<-s$binding$policy;level<-row$band_level
    if(level>=length(p$levels)||n[2]<p$minimum_people)return(NULL)
    cells<-parse(row$numeric_groups_json,c('band_id','n'));if(is.null(cells))return(NULL)
    bands<-registry_v2_bands(p,level);allowed<-vapply(bands,function(b)b$id,character(1));ids<-vapply(cells,function(c)if(is.character(c$band_id)&&length(c$band_id)==1)c$band_id else '',character(1))
    if(any(!ids %in% allowed)||anyDuplicated(ids))return(NULL)
    cells<-cells[order(match(ids,allowed))];est<-registry_v2_estimate(cells,bands)
    if(!all(vapply(names(est),function(n)identical(row[[n]],est[[n]])||(is.numeric(row[[n]])&&is.numeric(est[[n]])&&length(row[[n]])==1&&is.finite(row[[n]])&&abs(row[[n]]-est[[n]])<=max(1,abs(est[[n]]))*1e-12),logical(1))))return(NULL)
    canonical[registry_v2_estimates]<-est;canonical$numeric_groups_json<-registry_v2_json(cells);canonical$band_level<-level
  }
  counts<-vapply(cells,function(c)c$n,numeric(1))
  if(sum(counts)!=n[2]||!registry_v2_safe(counts,n[1],k)||!registry_v2_safe(counts,n[2],k))return(NULL)
  canonical[registry_v2_counts]<-as.list(n);canonical
}

registry_v2_guard <- function(rows,root,k,audit=FALSE) {
  fields<-registry_v2_fields(root);ids<-vapply(rows,atlas_registry_privacy_identity,character(1));out<-list();errors<-list()
  policy<-setNames(fields,vapply(fields,atlas_registry_privacy_identity,character(1)))
  for(i in seq_along(rows)) {
    s<-policy[[ids[i]]];if(is.null(s)){errors[[length(errors)+1L]]<-i;next}
    threshold<-max(vapply(rows[ids==ids[i]],atlas_registry_privacy_k,numeric(1),min_cell_count=k))
    candidate<-rows[[i]]
    if(!audit&&is.numeric(candidate$minimum_cell_count)&&!is.na(atlas_registry_privacy_integer(candidate$minimum_cell_count))&&candidate$minimum_cell_count>=5)candidate$minimum_cell_count<-threshold
    valid<-if(sum(ids==ids[i])==1)registry_v2_validate(candidate,s,threshold) else NULL
    if(is.null(valid))errors[[length(errors)+1L]]<-i
    if(!ids[i] %in% ids[seq_len(i-1L)])out[[length(out)+1L]]<-if(is.null(valid))registry_v2_row(s,'invalid_contract',threshold) else valid
  }
  if(audit)return(list(ok=!length(errors),violations=lapply(errors,function(i)list(path=paste0('registry_field_summaries.',i-1L),reason='invalid_v2_contract'))))
  out
}

registry_v2_public_resource <- function(root='.') {
  p<-registry_v2_policy(root)
  legacy<-atlas_registry_privacy_policy(root)
  fields<-lapply(registry_v2_fields(root),function(s) {
    out<-s[c(atlas_registry_privacy_metadata,'mapping_status','codes')]
    out$mapping_lineage<-lapply(s$mappings,function(m)m[c('table_name','source_column','raw_token','canonical_token','normalisation','evidence_tier','evidence_row','evidence_checksum','review_status','evidence_key','caveat')])
    out$legacy_categories<-legacy[[atlas_registry_privacy_identity(s)]]$categories
    if(!is.null(s$binding))out$binding<-list(
      evidence=s$binding$evidence[c('unit_code','stored_to_display_multiplier','stored_to_display_offset','evidence_id','evidence_checksum','binding_checksum')],
      policy=s$binding$policy)
    out
  })
  list(version='registry-summary-v2',checksum=p$checksum,fields=fields)
}
registry_v2_preflight <- function(root='.') {
  if(is.null(registry_v2_policy(root)))stop('Invalid v2 policy',call.=FALSE)
  policies<-registry_v2_numeric_policy(root);bindings<-registry_v2_units(root)
  if(nzchar(Sys.getenv('DALYCARE_REGISTRY_NUMERIC_POLICY_FILE',''))&&!length(policies))stop('Invalid local numeric policy',call.=FALSE)
  if(nzchar(Sys.getenv('DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE',''))) {
    matched<-Filter(function(s)!is.null(s$binding),registry_v2_fields(root))
    if(!length(bindings)||length(matched)!=length(bindings))stop('Invalid or stale local unit binding',call.=FALSE)
  }
  invisible(TRUE)
}
