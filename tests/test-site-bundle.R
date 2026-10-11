source('tests/helper.R'); source_test_runtime()
root <- normalizePath('.',winslash='/'); tmp <- tempfile('site-bundle-');dir.create(tmp)
payload <- list(run_id='synthetic',action_items=list(list(status='safe')),review_infrastructure_sections=list(action_items=list(list(status='safe'))))
snapshot <- list(privacy_metadata=list(minimum_cell_count=10),panels=list(registry_clinical_summary=lapply(seq_len(251),function(i)list(table_name=paste0('S',i),registry='LYFO',n_rows=if(i==251)7 else 20,n_cols=7,n_patients=20))))
tables <- atlas_output_evidence(NULL,root,snapshot)
stopifnot(exists('atlas_write_site_bundle',mode='function'))
paths <- atlas_write_site_bundle(file.path(tmp,'site'),payload,tables,root,'legacy_payload')
cattext <- paste(readLines(paths$catalogue,encoding='UTF-8'),collapse='\n')
catalogue <- jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=', '',cattext)),simplifyVector=FALSE)
table <- Filter(function(t)t$id=='registry_clinical_summary',catalogue$tables)[[1]]
stopifnot(identical(vapply(table$shards,function(s)s$rows,integer(1)),c(250L,1L)))
for(t in catalogue$tables) for(s in t$shards) {
 p <- file.path(tmp,'site',s$src); stopifnot(file.info(p)$size<=262144)
 data <- jsonlite::fromJSON(sub('\\);\\s*$','',sub('^window.DALYCARE_OUTPUTS.register\\(', '',paste(readLines(p,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
 stopifnot(nchar(enc2utf8(data$rows_json),type='bytes')==s$bytes)
 if(t$id=='registry_clinical_summary') stopifnot(all(vapply(jsonlite::fromJSON(data$rows_json,simplifyVector=FALSE),function(r)is.null(r$n_rows),logical(1))))
}
actual <- normalizePath(list.files(file.path(tmp,'site'),recursive=TRUE,full.names=TRUE),winslash='/')
stopifnot(setequal(actual,normalizePath(unlist(paths$assets),winslash='/')))
stopifnot(!is.null(paths$manifest),file.exists(paths$manifest))
manifest <- read.csv(paths$manifest,stringsAsFactors=FALSE)
stopifnot(setequal(manifest$relative_path,paste0('site/',list.files(file.path(tmp,'site'),recursive=TRUE))))
prior <- tools::md5sum(c(actual,paths$manifest))
Sys.setenv(DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES='1')
failed <- try(atlas_write_site_bundle(file.path(tmp,'site'),payload,tables,root,'legacy_payload'),silent=TRUE)
Sys.unsetenv('DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES')
stopifnot(inherits(failed,'try-error'),identical(prior,tools::md5sum(c(actual,paths$manifest))))
# Force only final manifest promotion to fail; the previous site+manifest survives.
original_rename <- file.rename
file.rename <- function(from,to) {
  if(identical(to,paths$manifest) && grepl('manifest-stage',from,fixed=TRUE)) return(FALSE)
  original_rename(from,to)
}
failed <- try(atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='failed'),tables,root,'legacy_payload'),silent=TRUE)
rm(file.rename)
stopifnot(inherits(failed,'try-error'),identical(prior,tools::md5sum(c(actual,paths$manifest))))
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
x <- atlas_output_evidence(NULL,root,list(privacy_metadata=list(minimum_cell_count=10),panels=list(registry_clinical_summary=list(list(table_name='0012',registry='LYFO',n_rows='7',n_cols='0',n_patients=NULL)))))
t <- Filter(function(t)t$id=='registry_clinical_summary',x)[[1]]
stopifnot(is.null(t$rows[[1]]$n_rows),identical(t$rows[[1]]$n_cols,0),identical(t$rows[[1]]$table_name,'0012'))
Sys.setenv(DALYCARE_MIN_CELL_COUNT='bogus')
stopifnot(inherits(try(atlas_output_evidence(NULL,root,list()),silent=TRUE),'try-error'))
Sys.unsetenv('DALYCARE_MIN_CELL_COUNT')
# Both transport files are identical and decode in the approved browser runtime.
js <- file.path(tmp,'verify.cjs')
writeLines(c("const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');","const [json,script,decoder]=process.argv.slice(2); const context={window:{}}; vm.createContext(context);","vm.runInContext(fs.readFileSync(script,'utf8'),context);vm.runInContext(fs.readFileSync(decoder,'utf8'),context);","assert.deepEqual(JSON.parse(JSON.stringify(context.window.DALYCARE_ATLAS_PAYLOAD)),JSON.parse(fs.readFileSync(json,'utf8')));","const p=context.window.DALYCARE_TRANSPORT.decode(context.window.DALYCARE_ATLAS_PAYLOAD);assert.equal(p.action_items,p.review_infrastructure_sections.action_items);"),js)
stopifnot(system2(Sys.which('node'),shQuote(c(js,paths$payload_json,paths$payload,file.path(root,'inst/templates/atlas-transport.js'))))==0)
# Wide UTF-8 cells are bounded by data bytes and the escaped registration file.
wide <- Filter(function(t)t$id=='registry_clinical_summary',tables)[[1]]
wide$rows <- rep(wide$rows[1],4)
for(i in seq_along(wide$rows)) wide$rows[[i]]$table_name <- paste(rep('東京',15000),collapse='')
wide$source_terms <- list()
wpaths <- atlas_write_site_bundle(file.path(tmp,'wide','site'),list(run_id='wide'),list(wide),root,'legacy_payload')
wc <- jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=', '',paste(readLines(wpaths$catalogue,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
stopifnot(length(wc$tables[[1]]$shards)>1,all(vapply(wc$tables[[1]]$shards,function(s) file.info(file.path(tmp,'wide','site',s$src))$size<=262144,logical(1))))
# A later single-row failure discards already accumulated parts, including when
# row JSON fits but escaping it into the registration script exceeds the limit.
optional <- Filter(function(t)t$id=='npu_display_dictionary',tables)[[1]]
labels <- list(paste(rep('x',270000),collapse=''),paste(rep(paste0('"',intToUtf8(92)),40000),collapse=''))
for(i in seq_along(labels)) {
  test_table <- optional
  small <- optional$rows[[1]];big <- small;big$label <- labels[[i]]
  row_json <- atlas_bundle_json(list(big))
  if(i==2L) stopifnot(nchar(enc2utf8(row_json),type='bytes')<262144,nchar(enc2utf8(atlas_bundle_json(list(rows_json=row_json))),type='bytes')>262144)
  test_table$rows <- c(rep(list(small),250),list(big))
  target <- file.path(tmp,paste0('later-wide-',i),'site')
  result <- atlas_write_site_bundle(target,list(run_id='wide'),list(test_table),root,'legacy_payload')
  cat_json <- sub(';\\s*$','',sub('^[^=]+=', '',paste(readLines(result$catalogue,encoding='UTF-8'),collapse='\n')))
  descriptor <- jsonlite::fromJSON(cat_json,simplifyVector=FALSE)$tables[[1]]
  stopifnot(descriptor$status=='unavailable',identical(descriptor$complete,FALSE),descriptor$represented_row_count==0,length(descriptor$shards)==0,length(list.files(file.path(target,'output-shards')))==0)
}
# Schema conversions do not turn booleans or leading-zero identifiers into numbers.
converted <- atlas_normalize_snapshot_rows(list(list(code='0012',n='0',flag='FALSE')),list(schemas=list(list(code='string',n='number',flag='boolean'))))
stopifnot(identical(converted[[1]],list(code='0012',n=0,flag=FALSE)))
stopifnot(inherits(try(atlas_normalize_snapshot_rows(list(list(n='invalid')),list(schemas=list(list(n='number')))),silent=TRUE),'try-error'))
unlink(tmp,recursive=TRUE)
cat('Site bundle R tests passed\n')
