# A growing pending-buffer reserialization must exceed the measured work bound.
source('tests/helper.R'); source_test_runtime()
Sys.unsetenv('DALYCARE_ATLAS_TRANSPORT_VERSION')
root <- normalizePath('.',winslash='/')
count <- 25700L
rows <- lapply(seq_len(count)-1L,function(i)list(code=sprintf('SYNTHETIC_E0_%04d',i%%257L),
  label=sprintf('Definition %d',i%%257L),definition='東京 "quoted" \\ path\næ'))
table <- list(id='npu_display_dictionary',status='available',complete=TRUE,
  source_file='config/npu-display-dictionary.csv',source_terms=list(),
  columns=lapply(names(rows[[1]]),function(key)list(key=key,type='string')),rows=rows)
original_json <- atlas_bundle_json
work <- new.env(parent=emptyenv());work$calls <- 0L;work$row_occurrences <- 0L;work$serialized_bytes <- 0
atlas_bundle_json <- function(value) {
  result <- original_json(value)
  matches <- gregexpr('SYNTHETIC_E0_',result,fixed=TRUE)[[1]]
  work$calls <- work$calls+1L
  work$row_occurrences <- work$row_occurrences+if(matches[[1]]<0L)0L else length(matches)
  work$serialized_bytes <- work$serialized_bytes+nchar(enc2utf8(result),type='bytes')
  result
}
tmp <- tempfile('shard-work-');dir.create(tmp)
elapsed <- system.time(paths <- atlas_write_site_bundle(file.path(tmp,'site'),
  list(run_id='E0_SYNTHETIC'),list(table),root,'legacy_payload'))[['elapsed']]
atlas_bundle_json <- original_json
catalogue <- jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',
  paste(readLines(paths$catalogue,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
item <- catalogue$tables[[1]];restored <- list();script_bytes <- 0
stopifnot(identical(vapply(item$shards,function(s)s$rows,integer(1)),c(rep(250L,102L),200L)))
for(shard in item$shards) {
  path <- file.path(tmp,'site',shard$src)
  text <- paste0(paste(readLines(path,encoding='UTF-8'),collapse='\n'),'\n')
  registration <- jsonlite::fromJSON(sub('\\);\\s*$','',sub('^window.DALYCARE_OUTPUTS.register\\(','',text)),simplifyVector=FALSE)
  stopifnot(identical(registration$build_id,catalogue$build_id),identical(registration$table_id,item$id),
    identical(registration$shard_id,shard$id),nchar(enc2utf8(registration$rows_json),type='bytes')==shard$bytes,
    shard$bytes<=262144,file.info(path)$size<=262144)
  restored <- c(restored,jsonlite::fromJSON(registration$rows_json,simplifyVector=FALSE))
  script_bytes <- script_bytes+file.info(path)$size
}
stopifnot(identical(restored,rows))
cat(sprintf('E0 R definitions=%d elapsed_seconds=%.3f calls=%d row_occurrences=%d serialized_bytes=%.0f shards=%d rows_json_bytes=%.0f script_bytes=%.0f\n',
  count,elapsed,work$calls,work$row_occurrences,work$serialized_bytes,length(item$shards),
  sum(vapply(item$shards,function(s)s$bytes,numeric(1))),script_bytes))
unlink(tmp,recursive=TRUE)
stopifnot(work$row_occurrences<=12*count)
# The additive escaping calculation must also hold at byte-driven boundaries.
tmp <- tempfile('shard-wide-');dir.create(tmp)
wide <- table
wide$columns <- list(list(key='code',type='string'),list(key='definition',type='string'))
wide$rows <- lapply(1:4,function(i)list(code=paste0('SYNTHETIC_E0_',i),
  definition=paste(rep(paste0('東京"/\\\b\t\n\f\r',intToUtf8(c(8232L,8233L,128512L))),3500),collapse='')))
set.seed(73)
result <- atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='E0_WIDE'),list(wide),root,'legacy_payload')
catalogue <- jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',
  paste(readLines(result$catalogue,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
restored <- list()
stopifnot(length(catalogue$tables[[1]]$shards)>1L)
for(shard in catalogue$tables[[1]]$shards) {
  path <- file.path(tmp,'site',shard$src)
  registration <- jsonlite::fromJSON(sub('\\);\\s*$','',sub('^window.DALYCARE_OUTPUTS.register\\(','',
    paste(readLines(path,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
  stopifnot(file.info(path)$size<=262144,shard$bytes<=262144)
  restored <- c(restored,jsonlite::fromJSON(registration$rows_json,simplifyVector=FALSE))
}
stopifnot(identical(restored,wide$rows))
assets <- unlist(result$assets);deterministic <- tools::md5sum(assets)
set.seed(73)
invisible(atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='E0_WIDE'),list(wide),root,'legacy_payload'))
stopifnot(identical(deterministic,tools::md5sum(assets)))
files <- c(unlist(result$assets),result$manifest);prior <- tools::md5sum(files)
required <- list(id='sources',status='available',complete=TRUE,source_terms=list(),
  source_file='outputs/atlas_sources.csv',columns=list(list(key='table_name',type='string')),
  rows=c(rep(list(list(table_name='small')),250),list(list(table_name=paste(rep('x',270000),collapse='')))))
failed <- try(atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='E0_REQUIRED'),list(required),root,'legacy_payload'),silent=TRUE)
stopifnot(inherits(failed,'try-error'),grepl('Required table row exceeds',as.character(failed),fixed=TRUE),
  identical(prior,tools::md5sum(files)))
unlink(tmp,recursive=TRUE)
cat('Site bundle R bounded serialization test passed\n')
