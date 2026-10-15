source('tests/helper.R');source_test_runtime()
root<-normalizePath('.',winslash='/');tmp<-Sys.getenv('DALYCARE_PUBLICATION_TEST_DIR',unset=tempfile('screened-publication-'));dir.create(tmp,recursive=TRUE,showWarnings=FALSE)
payload<-list(run_id='SYNTHETIC_E1',column_profile_rows=lapply(1:2200,function(i)list(table_name='Synthetic',column_name=paste0('field_',i),column_type='character',n_rows=20,n_available=19,n_missing=1)))
tables<-atlas_output_evidence(NULL,root,payload)
paths<-atlas_write_site_bundle(file.path(tmp,'site'),payload,tables,root)
source('R/publication.R')
manifest<-atlas_validate_public_site(file.path(tmp,'site'))
expect_equal(manifest$state,'partial')
index<-jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',paste(readLines(file.path(tmp,'site/DALYCARE_search.js')),collapse='\n'))),simplifyVector=FALSE)
expect_equal(length(index$fields),2200L)
catalogue<-jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',paste(readLines(paths$catalogue),collapse='\n'))),simplifyVector=FALSE)
for(table in catalogue$tables){path<-file.path(tmp,'site/downloads',paste0(table$id,'.csv'))
 if(!length(table$columns)){expect_equal(readLines(path),'');expect_equal(table$represented_row_count,0L);next}
 csv<-utils::read.csv(path,colClasses='character',check.names=FALSE)
 expect_equal(names(csv),vapply(table$columns,function(c)c$key,character(1)))
 expect_equal(nrow(csv),table$represented_row_count)
 if(table$id=='column_profiles')expect_true(all(csv$n_available==''&csv$n_missing==''))}
archive<-atlas_package_site(file.path(tmp,'site'));before<-atlas_public_hash(archive)
reader<-file.path(tmp,'site/atlas-reader.js');reader_bytes<-readBin(reader,'raw',n=file.info(reader)$size)
writeLines('mutated',reader)
expect_true(inherits(try(atlas_package_site(file.path(tmp,'site')),silent=TRUE),'try-error'))
expect_equal(atlas_public_hash(archive),before)
writeBin(reader_bytes,reader)
invisible(atlas_validate_public_site(file.path(tmp,"site")))
cat('PASS R canonical downloads, all2200 identities, public manifest and ZIP failure preservation\n')

expect_equal(atlas_publication_outcomes(list())$collection,'unknown')
expect_true(all(unlist(atlas_publication_outcomes(list(list(metric='collection_status',value='complete'),list(metric='interpretation_status',value='complete'))))=='complete'))
expect_equal(atlas_publication_outcomes(list(list(metric='collection_status',value='complete'),list(metric='collection_status',value='failed')))$collection,'unknown')

# A one-column missing row must not become an empty line skipped by CSV readers.
csv_probe<-file.path(tmp,'missing.csv');atlas_public_csv(csv_probe,'value',list(list(value=NULL),list(value=''),list(value='0012')))
expect_equal(nrow(read.csv(csv_probe,colClasses='character',check.names=FALSE,blank.lines.skip=FALSE)),3L)

atlas_public_csv(csv_probe,'value',list(list(value=1/3),list(value=.Machine$double.xmax)))
expect_equal(read.csv(csv_probe,colClasses='character')$value,vapply(c(1/3,.Machine$double.xmax),atlas_bundle_json,character(1)))

for(expected in c('partial','complete')){
 stage<-tempfile('manifest-state-');dir.create(stage)
 summary<-if(expected=='complete')list(list(metric='collection_status',value='complete'),list(metric='interpretation_status',value='complete'))else list()
 expect_equal(atlas_public_manifest(stage,'b','r','p',root,summary)$state,expected)
}
