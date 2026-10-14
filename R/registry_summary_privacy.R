# Exact registry contract, independent of the legacy row-profile guard.
atlas_registry_privacy_counts <- c('denominator_n','n_valid','n_missing','n_invalid','n_conflicting','n_distinct','minimum_value_support')
atlas_registry_privacy_stats <- c('mean','median','p25','p75')
atlas_registry_privacy_metadata <- c('table_name','source_column','kind','topic','phase','label')
atlas_registry_privacy_constants <- list(contract_version='registry-summary-v1',unit_status='unverified',count_basis='distinct_people_one_unambiguous_value_per_field',summary_method='exact_complete_field_3sf')
atlas_registry_privacy_schema <- c('contract_version',atlas_registry_privacy_metadata,'unit_status','count_basis','summary_method','summary_status','minimum_cell_count',atlas_registry_privacy_counts,'category_counts_json',atlas_registry_privacy_stats)
atlas_registry_privacy_statuses <- c('published','needs_person_key','missing_person_key','field_unavailable','query_failed','resource_limit','withheld_small_group','withheld_constant','withheld_near_unique','no_values','invalid_contract')
atlas_registry_privacy_statuses <- c(atlas_registry_privacy_statuses,'needs_unit_evidence')

atlas_registry_privacy_number <- function(x) {
  if(is.null(x)||length(x)!=1L||is.logical(x)||!is.atomic(x)) return(NA_real_)
  value <- suppressWarnings(as.numeric(x))
  if(is.na(value)||!is.finite(value)||value<0) NA_real_ else value
}
atlas_registry_privacy_integer <- function(x) {
  value <- atlas_registry_privacy_number(x)
  if(is.na(value)||value!=floor(value)||value>9007199254740991) NA_real_ else value
}
atlas_registry_privacy_floor <- function(x) {
  value <- atlas_registry_privacy_integer(x); if(is.na(value)) 5 else max(5,value)
}
atlas_registry_privacy_requested_threshold <- function(x) {
  value <- atlas_registry_privacy_number(x)
  if(is.na(value)||value<1||value>9007199254740991) stop('Invalid explicit privacy threshold',call.=FALSE)
  max(5,ceiling(value))
}
atlas_registry_privacy_identity <- function(row) {
  if(!is.list(row)||is.null(names(row))) return('')
  a <- row$table_name; b <- row$source_column
  if(!is.character(a)||length(a)!=1L||is.na(a)||!is.character(b)||length(b)!=1L||is.na(b)) return('')
  # JSON preserves exact identity even if a supplied identifier contains a separator.
  as.character(jsonlite::toJSON(list(a,b),auto_unbox=TRUE))
}
atlas_registry_privacy_policy <- function(project_root='.') {
  candidates <- c(file.path(project_root,'config','registry-summary-policy.json'),file.path(project_root,'inst','config','registry-summary-policy.json'),system.file('config','registry-summary-policy.json',package='dalycareatlas'))
  existing <- candidates[nzchar(candidates)&file.exists(candidates)]
  if(!length(existing)) return(list())
  policy <- tryCatch(jsonlite::fromJSON(existing[[1]],simplifyVector=FALSE),error=function(e) NULL)
  if(!is.list(policy)||!setequal(names(policy),c('version','fields'))||!identical(policy$version,'registry-summary-v1')||!is.list(policy$fields)) return(list())
  out <- list()
  for(field in policy$fields) {
    if(!is.list(field)||!setequal(names(field),c(atlas_registry_privacy_metadata,'categories'))||length(names(field))!=7L) return(list())
    if(!all(vapply(atlas_registry_privacy_metadata,function(key) is.character(field[[key]])&&length(field[[key]])==1L&&!is.na(field[[key]]),logical(1)))) return(list())
    if(!field$table_name %in% c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL')||!field$kind %in% c('numeric','categorical')||!field$topic %in% c('stage','treatment','response','laboratory')) return(list())
    categories <- field$categories
    if(!is.list(categories)||length(categories)>1000L||!all(vapply(categories,function(x) is.character(x)&&length(x)==1L&&!is.na(x)&&nzchar(x)&&nchar(x)<=128L,logical(1)))) return(list())
    codes <- unlist(categories,use.names=FALSE)
    if(anyDuplicated(codes)||(field$kind=='numeric'&&length(codes))) return(list())
    id <- atlas_registry_privacy_identity(field)
    if(!nzchar(id)||!is.null(out[[id]])) return(list())
    out[[id]] <- field
  }
  out
}
atlas_registry_privacy_rows <- function(rows) {
  if(is.data.frame(rows)) return(lapply(seq_len(nrow(rows)),function(i) {
    row <- as.list(rows[i,,drop=FALSE]); lapply(row,function(x) if(length(x)==1L&&is.atomic(x)&&is.na(x)) NULL else x)
  }))
  if(!is.list(rows)||!is.null(names(rows))) return(NULL)
  rows
}
atlas_registry_privacy_k <- function(row,min_cell_count) max(atlas_registry_privacy_requested_threshold(min_cell_count),atlas_registry_privacy_requested_threshold(Sys.getenv('DALYCARE_MIN_CELL_COUNT','5')),atlas_registry_privacy_floor(row$minimum_cell_count))
atlas_registry_privacy_canonical <- function(field,k,status) {
  row <- setNames(rep(list(NULL),length(atlas_registry_privacy_schema)),atlas_registry_privacy_schema)
  row[names(atlas_registry_privacy_constants)] <- atlas_registry_privacy_constants
  row[atlas_registry_privacy_metadata] <- field[atlas_registry_privacy_metadata]
  row$summary_status <- status; row$minimum_cell_count <- k; row$category_counts_json <- '[]'
  row
}
atlas_registry_privacy_schema_ok <- function(row,field) {
  is.list(row)&&length(names(row))==length(atlas_registry_privacy_schema)&&setequal(names(row),atlas_registry_privacy_schema)&&identical(row$kind,field$kind)&&all(vapply(names(atlas_registry_privacy_constants),function(key) identical(row[[key]],atlas_registry_privacy_constants[[key]]),logical(1)))&&is.character(row$summary_status)&&length(row$summary_status)==1L&&row$summary_status %in% atlas_registry_privacy_statuses&&!is.na(atlas_registry_privacy_integer(row$minimum_cell_count))&&atlas_registry_privacy_integer(row$minimum_cell_count)>=5
}
atlas_registry_privacy_category_cells <- function(raw,field) {
  if(!is.character(raw)||length(raw)!=1L||is.na(raw)||nchar(raw,type='bytes')>65536L) return(NULL)
  values <- tryCatch(jsonlite::fromJSON(raw,simplifyVector=FALSE),error=function(e) NULL)
  if(is.null(values)||!is.list(values)||!is.null(names(values))||length(values)>length(field$categories)) return(NULL)
  codes <- character(); cells <- list(); allowed <- unlist(field$categories,use.names=FALSE)
  for(value in values) {
    if(!is.list(value)||length(names(value))!=2L||!setequal(names(value),c('code','n'))||!is.character(value$code)||length(value$code)!=1L||is.na(value$code)||!value$code %in% allowed||value$code %in% codes) return(NULL)
    n <- atlas_registry_privacy_integer(value$n)
    if(!is.numeric(value$n)||is.na(n)||n<=0) return(NULL)
    codes <- c(codes,value$code); cells[[length(cells)+1L]] <- list(code=value$code,n=n)
  }
  cells[order(match(codes,allowed))]
}
atlas_registry_privacy_published <- function(row,field,k) {
  # No v1 exact numeric record carries verified stored units or a complete band release.
  if(field$kind=='numeric') return(NULL)
  counts <- setNames(lapply(atlas_registry_privacy_counts[1:5],function(key) atlas_registry_privacy_integer(row[[key]])),atlas_registry_privacy_counts[1:5])
  numbers <- unlist(counts,use.names=FALSE)
  if(anyNA(numbers)) return(NULL)
  total <- counts$denominator_n; valid <- counts$n_valid
  if(total<=0||valid<=0||sum(unlist(counts[2:5]))!=total||any((numbers>0&numbers<k)|(total-numbers>0&total-numbers<k))) return(NULL)
  out <- counts
  if(field$kind=='categorical') {
    if(any(vapply(c(atlas_registry_privacy_stats,atlas_registry_privacy_counts[6:7]),function(key) !is.null(row[[key]]),logical(1)))) return(NULL)
    cells <- atlas_registry_privacy_category_cells(row$category_counts_json,field)
    if(is.null(cells)||!length(cells)) return(NULL)
    n <- vapply(cells,function(x) x$n,numeric(1))
    if(sum(n)!=valid||any(n<k|(valid-n>0&valid-n<k)|(total-n>0&total-n<k))) return(NULL)
    out$category_counts_json <- as.character(jsonlite::toJSON(cells,auto_unbox=TRUE,null='null',digits=NA))
  } else {
    if(!identical(row$category_counts_json,'[]')) return(NULL)
    distinct <- atlas_registry_privacy_integer(row$n_distinct); minimum <- atlas_registry_privacy_integer(row$minimum_value_support)
    values <- setNames(lapply(atlas_registry_privacy_stats,function(key) atlas_registry_privacy_number(row[[key]])),atlas_registry_privacy_stats)
    if(valid<20||is.na(distinct)||distinct<=1||distinct>=valid*.9||is.na(minimum)||minimum<k||distinct*minimum>valid||anyNA(unlist(values))) return(NULL)
    if(values$p25>values$median||values$median>values$p75) return(NULL)
    values <- lapply(values,signif,digits=3)
    if(any(!is.finite(unlist(values)))) return(NULL)
    out <- c(out,list(n_distinct=distinct,minimum_value_support=minimum),values)
  }
  out
}
atlas_registry_summary_guard <- function(rows,project_root='.',min_cell_count=5) {
  rows <- atlas_registry_privacy_rows(rows); if(is.null(rows)) return(list())
  policy <- atlas_registry_privacy_policy(project_root)
  identities <- vapply(rows,atlas_registry_privacy_identity,character(1)); seen <- character(); out <- list()
  for(i in seq_along(rows)) {
    id <- identities[[i]]; if(!nzchar(id)||is.null(policy[[id]])||id %in% seen) next
    seen <- c(seen,id); row <- rows[[i]]; field <- policy[[id]]
    group <- which(identities==id)
    k <- max(vapply(rows[group],atlas_registry_privacy_k,numeric(1),min_cell_count=min_cell_count))
    status <- if(atlas_registry_privacy_schema_ok(row,field)) row$summary_status else 'invalid_contract'
    if(length(group)>1L) status <- 'invalid_contract'
    if(status=='published' && field$kind=='numeric') status <- 'needs_unit_evidence'
    result <- atlas_registry_privacy_canonical(field,k,status)
    if(status=='published') {
      publication <- atlas_registry_privacy_published(row,field,k)
      if(is.null(publication)) result$summary_status <- 'invalid_contract' else result[names(publication)] <- publication
    }
    out[[length(out)+1L]] <- result
  }
  out
}
atlas_registry_summary_audit <- function(rows,project_root='.',min_cell_count=5) {
  rows <- atlas_registry_privacy_rows(rows); violations <- list()
  fail <- function(path,reason) violations[[length(violations)+1L]] <<- list(path=path,reason=reason)
  if(is.null(rows)) {fail('registry_field_summaries','invalid_list'); return(list(ok=FALSE,violations=violations))}
  policy <- atlas_registry_privacy_policy(project_root); identities <- vapply(rows,atlas_registry_privacy_identity,character(1))
  for(i in seq_along(rows)) {
    id <- identities[[i]]; row <- rows[[i]]; path <- paste0('registry_field_summaries.',i-1L)
    field <- if(nzchar(id)) policy[[id]] else NULL
    if(is.null(field)||!atlas_registry_privacy_schema_ok(row,field)||sum(identities==id)>1L) {fail(path,'invalid_contract'); next}
    k <- atlas_registry_privacy_k(row,min_cell_count); canonical <- atlas_registry_privacy_canonical(field,k,row$summary_status)
    if(!all(vapply(c(atlas_registry_privacy_metadata,names(atlas_registry_privacy_constants)),function(key) identical(row[[key]],canonical[[key]]),logical(1)))||atlas_registry_privacy_integer(row$minimum_cell_count)!=k) fail(path,'metadata')
    if(row$summary_status=='published') {
      publication <- atlas_registry_privacy_published(row,field,k)
      if(is.null(publication)) fail(path,'unsafe_publication') else if(field$kind=='numeric'&&any(vapply(atlas_registry_privacy_stats,function(key) atlas_registry_privacy_number(row[[key]])!=publication[[key]],logical(1)))) fail(path,'numeric_precision')
    } else if(!identical(row$category_counts_json,'[]')||any(vapply(c(atlas_registry_privacy_counts,atlas_registry_privacy_stats),function(key) !is.null(row[[key]]),logical(1)))) fail(path,'withheld_data')
  }
  list(ok=!length(violations),violations=violations)
}
