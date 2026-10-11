# These assertions exercise the evidence builder after the shared disclosure guard.
source('tests/helper.R'); source_test_runtime()
root <- normalizePath('.',winslash='/')
snapshot <- list(panels=list(atlas_temporal_coverage=list(list(table_name='S',date_column='ClinicalDate',n_rows=20,pct_available=75,min_date='2020-01-01',max_date='2025-01-01'))))
tables <- atlas_output_evidence(NULL,root,snapshot)
table <- function(id) Filter(function(t)t$id==id,tables)[[1]]
column <- function(id,key) Filter(function(c)c$key==key,table(id)$columns)[[1]]
stopifnot(table('atlas_temporal_coverage')$rows[[1]]$date_column=='ClinicalDate',is.null(table('atlas_temporal_coverage')$rows[[1]]$min_date),is.null(table('atlas_temporal_coverage')$rows[[1]]$max_date))
stopifnot(column('atlas_temporal_coverage','date_column')$label=='Selected date field',grepl('date validity',column('atlas_temporal_coverage','pct_available')$definition,fixed=TRUE))
stopifnot(column('registry_clinical_summary','n_patients')$label=='Bounded ID / record count',grepl('100,000',column('registry_clinical_summary','n_patients')$definition,fixed=TRUE),grepl('otherwise counts source records',column('registry_clinical_summary','n_patients')$definition,fixed=TRUE))
stopifnot(column('damyda_clinical_profile','n')$label=='Retained category occurrences',table('npu_dictionary_vectors')$count_basis=='reference_dictionary_metadata',column('npu_dictionary_vectors','n_dictionary_codes')$label=='Dictionary entries')
# Persist production descriptors so Python can compare every reviewed semantic field.
parity_path <- Sys.getenv('DALYCARE_METADATA_TEST_OUTPUT')
if(nzchar(parity_path)) jsonlite::write_json(tables,parity_path,auto_unbox=TRUE,null='null',na='null',pretty=FALSE)
cat('Reviewed metadata and selected-date guard checks passed\n')
