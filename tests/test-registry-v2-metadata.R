source('tests/helper.R');source_test_runtime('.')
source('R/metadata_privacy.R');source('R/public_privacy.R')
source<- 'SP_VitaleVærdier';column<-'måling "højde"';value<-'resultat-værdi';descriptor<-'Højde'
row<-as.list(semantic_row(semantic_id=semantic_exact_id(source,column,value,descriptor),source_name=source,object_name=source,raw_column=column,value_column=value,raw_descriptor=descriptor,data_shape='long_descriptor_table',evidence_file='current panel: vital_descriptors',evidence_filter=semantic_exact_filter(column,descriptor),mapping_status='saved_definition_inventory_unassessed')[1,])
row<-lapply(row,function(v)if(length(v)==1&&is.na(v))NULL else v)
payload<-list(column_profile_rows=list(list(table_name=source,column_name=column),list(table_name=source,column_name=value)),semantic_dictionary_rows=list(row))
expect_false(atlas_metadata_only(row,'semantic_dictionary_rows','.'))
context<-atlas_metadata_context(payload,'.')
expect_true(atlas_metadata_only(row,'semantic_dictionary_rows','.',context))
safe<-atlas_public_privacy(payload,'.');expect_equal(safe$semantic_dictionary_rows[[1]]$raw_descriptor,descriptor)
expect_equal(safe$semantic_dictionary_rows[[1]]$value_column,value)
expect_equal(safe$semantic_dictionary_rows[[1]]$evidence_filter,row$evidence_filter)
atlas_evidence_audit(safe,'.')
expect_equal(atlas_public_privacy(safe,'.'),safe)
for(key in c('n_rows','raw_value','semantic_id','evidence_filter')) {
  bad<-row;bad[[key]]<-if(key=='n_rows')1 else 'SYNTHETIC_POISON'
  masked<-atlas_public_privacy(list(semantic_dictionary_rows=list(bad)),'.')
  expect_true(is.null(masked$semantic_dictionary_rows[[1]]$raw_descriptor))
}
# Fully recomputed self-attestation still needs independent discovered columns.
for(unknown_source in c(TRUE,FALSE)) {
  forged<-row
  if(unknown_source){forged$source_name<-'SYNTHETIC_UNKNOWN_SOURCE';forged$object_name<-forged$source_name}
  forged$raw_descriptor<-'SYNTHETIC_PRIVATE_OBSERVATION'
  forged$semantic_id<-semantic_exact_id(forged$source_name,forged$raw_column,forged$value_column,forged$raw_descriptor)
  forged$evidence_filter<-semantic_exact_filter(forged$raw_column,forged$raw_descriptor)
  bad<-payload;bad$semantic_dictionary_rows<-list(forged)
  expect_false(atlas_metadata_only(forged,'semantic_dictionary_rows','.',context))
  expect_true(is.null(atlas_public_privacy(bad,'.')$semantic_dictionary_rows[[1]]$raw_descriptor))
  expect_true(inherits(tryCatch(atlas_evidence_audit(bad,'.'),error=identity),'error'))
}
work<-'.artifact-temp/registry-v2';dir.create(work,recursive=TRUE,showWarnings=FALSE)
jsonlite::write_json(payload,file.path(work,'metadata.json'),auto_unbox=TRUE,null='null',digits=NA)
cat('PASS exact metadata schema, descriptor filter, Unicode/quoted identifiers and anti-spoof checks\n')

# Approved identities cannot bless attacker-controlled derived display text.
for(key in c('clinical_variable','semantic_meaning','privacy_note','clinical_caveat','search_terms','schema_name','table_name','evidence_filter','semantic_id')) {
  injected<-payload;injected$semantic_dictionary_rows[[1]][[key]]<-'SYNTHETIC_PRIVATE_OBSERVATION'
  expect_false(atlas_metadata_only(injected$semantic_dictionary_rows[[1]],'semantic_dictionary_rows','.',context))
  cleaned<-atlas_public_privacy(injected,'.')
  expect_false(grepl('SYNTHETIC_PRIVATE_OBSERVATION',jsonlite::toJSON(cleaned,auto_unbox=TRUE),fixed=TRUE))
  expect_true(inherits(tryCatch(atlas_evidence_audit(injected,'.'),error=identity),'error'))
  atlas_evidence_audit(cleaned,'.')
}
# Optional exact definition evidence is local-only, versioned and preflighted.
local_path<-file.path(work,'approved-metadata.json')
record<-list(source_name=source,raw_column=column,value_column=value,raw_descriptor='SYNTHETIC_REVIEWED_DEFINITION')
local<-list(version='approved-metadata-definitions-v1',definitions=list(record),provenance=list(evidence_id='SYNTHETIC-TEST-ONLY',evidence_checksum=paste(rep('b',64),collapse=''),evidence_tier='reviewed_descriptor_definition',review_status='verified'))
jsonlite::write_json(local,local_path,auto_unbox=TRUE,null='null')
Sys.setenv(DALYCARE_METADATA_DEFINITIONS_FILE=local_path)
expect_true(atlas_metadata_preflight('.'))
approved<-row;approved$raw_descriptor<-record$raw_descriptor;approved$semantic_id<-semantic_exact_id(source,column,value,record$raw_descriptor);approved$evidence_filter<-semantic_exact_filter(column,record$raw_descriptor)
expect_true(atlas_metadata_only(approved,'semantic_dictionary_rows','.',atlas_metadata_context(payload,'.')))
jsonlite::write_json(list(version=local$version,definitions=local$definitions),local_path,auto_unbox=TRUE)
expect_true(inherits(tryCatch(atlas_metadata_preflight('.'),error=identity),'error'))
Sys.unsetenv('DALYCARE_METADATA_DEFINITIONS_FILE')
expect_equal(readBin('config/metadata-descriptor-definitions.json','raw',n=1e6),readBin('inst/config/metadata-descriptor-definitions.json','raw',n=1e6))
cat('PASS approved local definition provenance, fail-closed preflight and mirrored resources\n')

# The derived review table uses the same registered schema and independent context.
for(key in c('clinical_variable','semantic_meaning','raw_descriptor','evidence_filter','semantic_id')) {
  injected<-payload;injected$review_clinical_variables<-list(raw_fields=list(row))
  injected$review_clinical_variables$raw_fields[[1]][[key]]<-'SYNTHETIC_PRIVATE_OBSERVATION'
  cleaned<-atlas_public_privacy(injected,'.')
  expect_false(grepl('SYNTHETIC_PRIVATE_OBSERVATION',jsonlite::toJSON(cleaned,auto_unbox=TRUE),fixed=TRUE))
  expect_true(inherits(tryCatch(atlas_evidence_audit(injected,'.'),error=identity),'error'))
  atlas_evidence_audit(cleaned,'.')
}
cat('PASS derived review raw_fields uses the same metadata authority and rejects injection\n')
