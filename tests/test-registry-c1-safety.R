source('R/public_privacy.R')
source('R/registry_summaries.R')
source('R/registry_summary_privacy.R')
source('R/utils.R')
source('R/output_evidence.R')
for(key in c('mean','median','p25','p75','sd','q25','q75','iqr')) {
  raw <- list(numeric_privacy_status='eligible_stored_summary');raw[[key]]<-8.5
  rejected <- tryCatch({atlas_evidence_audit(list(renamed=raw));FALSE},error=function(e)TRUE)
  stopifnot(rejected)
}
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
for(support in c(5,19,20,1000)) {
  row <- list(table_name='RKKP_CLL',column_name='Reg_Leukocyttal',profile_kind='numeric',n_available=support,n_missing=0,n_distinct_capped=2,min=0,max=17,mean=8.5,median=8.5,p25=1,p75=16,numeric_privacy_status='eligible_stored_summary')
  result <- atlas_public_privacy(list(column_profile_rows=list(row),renamed=list(copied=row)))
  for(copy in list(result$column_profile_rows[[1]],result$renamed$copied)) stopifnot(all(vapply(copy[c('min','max','mean','median','p25','p75')],is.null,logical(1))),copy$numeric_privacy_status=='needs_verified_grouped_evidence')
  stopifnot(identical(result,atlas_public_privacy(result)))
}
spec <- Filter(function(s) s$kind=='numeric',registry_summary_policy('.'))[[1]]
numeric <- registry_summary_from_groups(spec,data.frame(status='valid',value=c('1','16'),n=20),5)
stopifnot(numeric$summary_status=='needs_unit_evidence',is.na(numeric$mean))
for(environment in c('5','10')) {
  Sys.setenv(DALYCARE_MIN_CELL_COUNT=environment)
  payload <- list(privacy_metadata=list(minimum_cell_count=if(environment=='5') 10 else 5),counts=list(list(n=7)),column_profile_rows=list(list(table_name='T',column_name='C',n_available=7,n_missing=20,pct_available=26)))
  result <- atlas_public_privacy(payload,min_cell_count=1)
  stopifnot(result$privacy_metadata$minimum_cell_count==10,is.null(result$counts[[1]]$n),is.null(result$column_profile_rows[[1]]$n_available),identical(result,atlas_public_privacy(result)))
}
Sys.unsetenv('DALYCARE_MIN_CELL_COUNT')
archived <- atlas_public_privacy(list(run_summary=list(list(metric='min_cell_count',value='10')),counts=list(list(n=7))),min_cell_count=1)
stopifnot(archived$privacy_metadata$minimum_cell_count==10,is.null(archived$counts[[1]]$n))
fractional <- atlas_public_privacy(list(counts=list(list(n=10))),min_cell_count=10.1)
stopifnot(fractional$privacy_metadata$minimum_cell_count==11,is.null(fractional$counts[[1]]$n))
# Direct APIs must preserve the threshold without relying on a public wrapper.
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5');Sys.unsetenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE')
category <- Filter(function(s) s$kind=='categorical'&&length(s$categories)>=2,registry_summary_policy('.'))[[1]]
data <- data.frame(patientid=sprintf('synthetic-%02d',1:20),stringsAsFactors=FALSE)
data[[category$source_column]] <- rep(unlist(category$categories)[1:2],each=10)
baseline <- registry_field_summaries(data,category$table_name,'.',5)
row <- atlas_registry_privacy_rows(baseline[baseline$source_column==category$source_column,,drop=FALSE])[[1]]
stopifnot(row$summary_status=='published')
failures <- character()
check <- function(ok,label) if(!isTRUE(ok)) failures <<- c(failures,label)
rejects <- function(expr) inherits(tryCatch(force(expr),error=identity),'error')
check(atlas_effective_threshold(min_cell_count=10.1)==11,'writer requested threshold')
for(environment in c('5','10.1')) {
  Sys.setenv(DALYCARE_MIN_CELL_COUNT=environment)
  requested <- if(environment=='5') 10.1 else 5
  produced <- registry_field_summaries(data,category$table_name,'.',requested)
  produced <- produced[produced$source_column==category$source_column,,drop=FALSE]
  check(produced$minimum_cell_count==11&&produced$summary_status!='published','direct producer fractional threshold')
  guarded <- atlas_registry_summary_guard(list(row),'.',requested)[[1]]
  check(guarded$minimum_cell_count==11&&guarded$summary_status=='invalid_contract','direct R guard fractional threshold')
  check(!atlas_registry_summary_audit(list(row),'.',requested)$ok,'direct R audit fractional threshold')
  check(tryCatch(atlas_effective_threshold(),error=function(e)NA_real_)==if(environment=='5') 5 else 11,'writer environment threshold')
}
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
for(metadata in list(list(run_summary=list(list(metric='min_cell_count',value='11'))),list(privacy_metadata=list(minimum_cell_count=11)),list())) {
  original <- c(metadata,list(registry_field_summaries=list(row)))
  requested <- if(length(metadata)) 5 else 10.1
  check(rejects(atlas_evidence_audit(original,'.',requested)),'original R audit effective threshold')
  if(length(metadata)) check(atlas_effective_threshold(original)==11,'writer archived effective threshold')
}
# Saved run summaries also arrive as data frames or tibbles, not only JSON rows.
summary_shapes <- list(
  rows=function(value) list(list(metric='min_cell_count',value=value)),
  data_frame=function(value) data.frame(metric='min_cell_count',value=value,stringsAsFactors=FALSE),
  tibble=function(value) tibble::tibble(metric='min_cell_count',value=value)
)
failure_message <- function(expr) tryCatch({force(expr);''},error=conditionMessage)
for(shape in names(summary_shapes)) {
  for(value in list(11,'11')) {
    original <- list(run_summary=summary_shapes[[shape]](value),registry_field_summaries=list(row))
    check(atlas_effective_threshold(original)==11,paste('effective archived threshold shape',shape))
    check(identical(failure_message(atlas_evidence_audit(original)),'Registry summary privacy audit failed'),paste('original archived audit shape',shape))
  }
  for(bad in list(10.1,TRUE,NA_real_,Inf,'not-count','')) {
    original <- list(run_summary=summary_shapes[[shape]](bad),registry_field_summaries=list(row))
    check(identical(failure_message(atlas_effective_threshold(original)),'Invalid explicit privacy threshold'),paste('invalid archived threshold shape',shape))
    check(identical(failure_message(atlas_evidence_audit(original)),'Invalid explicit privacy threshold'),paste('invalid original audit shape',shape))
  }
}
for(bad in list(10.1,TRUE,'not-count')) {
  malformed <- row;malformed$minimum_cell_count <- bad
  check(atlas_registry_summary_guard(list(malformed))[[1]]$summary_status=='invalid_contract','strict archived registry k')
  malformed <- row;malformed$n_valid <- bad
  check(atlas_registry_summary_guard(list(malformed))[[1]]$summary_status=='invalid_contract','strict archived registry counts')
  check(rejects(atlas_effective_threshold(list(run_summary=list(list(metric='min_cell_count',value=bad))))),'strict archived run threshold')
  check(rejects(atlas_effective_threshold(list(privacy_metadata=list(minimum_cell_count=bad)))),'strict archived metadata threshold')
  check(rejects(atlas_effective_threshold(context=list(minimum_cell_count=bad))),'strict archived context threshold')
}
for(bad in list(TRUE,NA_real_,Inf,'bad')) {
  check(rejects(registry_field_summaries(data,category$table_name,'.',bad)),'invalid producer threshold fails closed')
  check(rejects(atlas_registry_summary_guard(list(row),'.',bad)),'invalid direct guard threshold fails closed')
}
if(length(failures)) stop(paste(unique(failures),collapse='; '))
cat('C1 legacy closure and threshold safety passed.\n')
