source('tests/helper.R'); source_test_runtime()
root <- normalizePath('.',winslash='/')
fixture <- jsonlite::fromJSON(file.path(root,'tests/fixtures/site-field-labels.json'),simplifyVector=FALSE)
temp_parent <- file.path(dirname(root),'.artifact-temp/iteration17-team')
dir.create(temp_parent,recursive=TRUE,showWarnings=FALSE)
tmp <- tempfile('r-labels-',tmpdir=temp_parent);dir.create(tmp)
out <- file.path(tmp,'site')
dictionary <- Filter(function(t)t$id=='clinical_display_dictionary',atlas_output_evidence(NULL,root,list()))[[1]]
read_catalogue <- function(paths) jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=', '',paste(readLines(paths$catalogue,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
label_profiles <- function(rows) lapply(Filter(function(r)identical(r$kind,'field'),rows),function(r)list(table_name=r$system,column_name=r$code,column_type='character'))
index_labels <- function(paths){idx<-jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=', '',paste(readLines(file.path(out,'DALYCARE_search.js'),encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE);result<-list();for(f in idx$fields)if(nzchar(f[[3]]))result[[idx$sources[[f[[1]]+1L]]]][[f[[2]]]]<-f[[3]];result}
publish_labels <- function(rows,payload=list(run_id='field-labels')) {
  table <- dictionary;table$rows <- rows
  if(is.null(payload$column_profile_rows))payload$column_profile_rows<-label_profiles(fixture$valid)
  column<-Filter(function(t)t$id=='column_profiles',atlas_output_evidence(NULL,root,payload))[[1]]
  atlas_write_site_bundle(out,payload,list(table,column),root,'legacy_payload')
}
# Missing extraction or a stale dictionary source breaks exact emitted labels.
paths <- publish_labels(fixture$valid,list(run_id='field-labels',clinical_display_dictionary=list(list(kind='field',system='SDS_t_biobank',code='SampleType',label='Stale copied label'))))
catalogue <- read_catalogue(paths)
expect_equal(index_labels(paths),fixture$expected,'Exact field_labels must come from the guarded published dictionary')
stopifnot(is.null(index_labels(paths)$RKKP_LYFO$IPI),is.null(index_labels(paths)$SDS_t_udtilsgh),catalogue$tables[[1]]$provenance=='project_reference')
emitted <- list()
for(shard in catalogue$tables[[1]]$shards) {
  registration <- jsonlite::fromJSON(sub('\\);\\s*$','',sub('^window.DALYCARE_OUTPUTS.register\\(', '',paste(readLines(file.path(out,shard$src),encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
  emitted <- c(emitted,jsonlite::fromJSON(registration$rows_json,simplifyVector=FALSE))
}
keys <- c('kind','system','code','label')
expect_equal(lapply(emitted,function(r)r[keys]),lapply(fixture$valid,function(r)r[keys]))
stopifnot(emitted[[1]]$source_url=='https://example.test/reviewed',emitted[[1]]$retrieved_on=='2026-10-11')
for(p in list(list(run_id='absent'),list(clinical_display_dictionary=list()),list(clinical_display_dictionary_alias=fixture$valid))) {
  absent <- atlas_write_site_bundle(out,p,list(),root,'legacy_payload')
  stopifnot(!'field_labels' %in% names(read_catalogue(absent)))
}
for(rows in list(list(),fixture$excluded)) stopifnot(!'field_labels' %in% names(read_catalogue(publish_labels(rows))))
payload_only <- atlas_write_site_bundle(out,list(clinical_display_dictionary=fixture$valid,column_profile_rows=label_profiles(fixture$valid)),list(),root,'legacy_payload')
expect_equal(index_labels(payload_only),list(),'Missing discovered profile evidence must not invent field identities')
expect_equal(length(read_catalogue(payload_only)$tables),0L,'Unbound payload dictionary cannot bypass screened descriptors')
paths <- publish_labels(fixture$valid)
prior_paths <- c(unlist(paths$assets),paths$manifest);prior <- tools::md5sum(prior_paths)
cases <- c(list(fixture$conflict),lapply(fixture$invalid,function(row)list(row)))
for(i in seq_along(cases)) {
  failed <- try(publish_labels(cases[[i]]),silent=TRUE)
  expect_true(inherits(failed,'try-error'),paste('Invalid/conflicting field label case must fail:',i))
  expect_true(grepl('field.label|Typed evidence mismatch: clinical_display_dictionary',as.character(failed),ignore.case=TRUE),paste('Explicit field label error required:',i))
  expect_equal(tools::md5sum(prior_paths),prior)
}
wide <- lapply(seq_len(600),function(i)list(kind='field',system='Source',code=paste0('field',i),label=paste(rep('x',1000),collapse='')))
deferred<-publish_labels(wide)
expect_equal(length(read_public_table(out,'clinical_display_dictionary')),600L)
expect_true(all(vapply(unlist(lapply(read_catalogue(deferred)$tables,function(t)t$shards),recursive=FALSE),function(shard)file.info(file.path(out,shard$src))$size<=262144,logical(1))))
paths<-publish_labels(fixture$valid);prior_paths<-c(unlist(paths$assets),paths$manifest);prior<-tools::md5sum(prior_paths)
failed <- try(publish_labels(wide,list(run_id='large-search-index',column_profile_rows=label_profiles(wide))),silent=TRUE)
expect_true(inherits(failed,'try-error'),'Field label metadata must obey existing initial library ceiling')
stopifnot(grepl('Initial asset byte budget exceeded|Cold route dependency byte budget exceeded',as.character(failed)))
expect_equal(tools::md5sum(prior_paths),prior)
unlink(tmp,recursive=TRUE)
cat('Field label bundle R tests passed\n')
