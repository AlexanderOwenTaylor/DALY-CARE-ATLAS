stopifnot(file.exists('R/registry_summary_privacy.R'))
source('R/registry_summary_privacy.R',encoding='UTF-8')
args <- commandArgs(trailingOnly=TRUE)
if(length(args)>=2L) {
  cases <- jsonlite::fromJSON(args[[1]],simplifyVector=FALSE)
  out <- lapply(cases,atlas_registry_summary_guard,project_root='.')
  stopifnot(identical(out,lapply(out,atlas_registry_summary_guard,project_root='.')))
  stopifnot(all(vapply(out,function(rows) atlas_registry_summary_audit(rows,project_root='.')$ok,logical(1))))
  writeLines(jsonlite::toJSON(out,auto_unbox=TRUE,null='null',na='null',digits=NA),args[[2]],useBytes=TRUE)
} else {
  policy <- jsonlite::fromJSON('inst/config/registry-summary-policy.json',simplifyVector=FALSE)
  field <- Filter(function(x) x$kind=='numeric',policy$fields)[[1]]
  row <- setNames(rep(list(NULL),length(atlas_registry_privacy_schema)),atlas_registry_privacy_schema)
  row[c('table_name','source_column','kind','topic','phase','label')] <- field[c('table_name','source_column','kind','topic','phase','label')]
  row[c('contract_version','unit_status','count_basis','summary_method','summary_status','minimum_cell_count','denominator_n','n_valid','n_missing','n_invalid','n_conflicting','n_distinct','minimum_value_support','category_counts_json','mean','median','p25','p75')] <- list('registry-summary-v1','unverified','distinct_people_one_unambiguous_value_per_field','exact_complete_field_3sf','published',5,40,30,5,5,0,3,10,'[]',2,2,1,3)
  out <- atlas_registry_summary_guard(list(row)); stopifnot(out[[1]]$summary_status=='needs_unit_evidence',atlas_registry_summary_audit(out)$ok)
  bad <- row; bad$n_missing <- 1
  withheld <- atlas_registry_summary_guard(list(bad)); stopifnot(is.null(withheld[[1]]$mean),identical(withheld,atlas_registry_summary_guard(withheld)),!atlas_registry_summary_audit(list(bad))$ok)
  source('R/public_privacy.R',encoding='UTF-8')
  payload <- list(panels=list(registry_field_summaries=list(row)),review_registry=list(registry_field_summaries=list(row)),evidence=list(restored=list(registry_field_summaries=list(row))))
  guarded <- atlas_public_privacy(payload)
  stopifnot(is.null(guarded$panels$registry_field_summaries[[1]]$mean),identical(guarded,atlas_public_privacy(guarded)))
  archived <- payload; archived$privacy_metadata <- list(minimum_cell_count=10)
  guarded_archive <- atlas_public_privacy(archived)
  stopifnot(guarded_archive$panels$registry_field_summaries[[1]]$minimum_cell_count==10,is.null(guarded_archive$panels$registry_field_summaries[[1]]$mean))
  forged <- row; forged$value <- 'FORBIDDEN'; forged$n <- 30
  other <- atlas_public_privacy(list(column_top_value_rows=list(forged)))
  stopifnot(is.null(other$column_top_value_rows[[1]]$value),is.null(other$column_top_value_rows[[1]]$mean))
}
cat('Registry privacy R contract, audit and idempotence checks passed\n')
