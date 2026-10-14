source('tests/helper.R');source('R/utils.R');source('R/registry_summary_privacy.R');source('R/registry_summaries.R');source('R/output_evidence.R');source('R/public_privacy.R')
Sys.unsetenv(c('DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE','DALYCARE_REGISTRY_NUMERIC_POLICY_FILE'));Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
old<-Filter(function(s)s$table_name=='RKKP_CLL'&&s$source_column=='Reg_BinetStadium',atlas_registry_privacy_policy('.'))[[1]]
legacy<-atlas_registry_privacy_canonical(old,5,'no_values')
modern<-Filter(function(s)s$table_name=='RKKP_DaMyDa'&&s$source_column=='Reg_Haemoglobin',registry_v2_fields('.'))[[1]]
modern<-registry_v2_row(modern,'needs_unit_evidence',5)
rows<-list(legacy,modern);frame<-registry_contract_frame(rows)
expect_equal(atlas_registry_summary_guard(frame,'.'),rows)
spec<-Filter(function(s)s$id=='registry_field_summaries',atlas_output_registry('.')$artifacts)[[1]]
path<-'.artifact-temp/registry-v2/mixed.csv';dir.create(dirname(path),recursive=TRUE,showWarnings=FALSE)
write.csv(frame,path,row.names=FALSE,na='')
read<-atlas_read_registered_csv(path,spec)
expect_equal(atlas_evidence_rows(read),rows)
expect_equal(atlas_registry_summary_guard(read,'.'),rows)
expect_true(atlas_registry_summary_audit(atlas_evidence_rows(read),'.')$ok)
# The deliberate adapter cannot turn nonempty foreign-version properties into evidence.
frame$approximate_mean[1]<-123;write.csv(frame,path,row.names=FALSE,na='')
expect_true(inherits(tryCatch(atlas_read_registered_csv(path,spec),error=identity),'error'))
# Relocating a grouped record cannot bypass validation or original-payload audit.
bad<-modern;bad$approximate_mean<-87654321;bad$numeric_groups_json<-'[{"band_id":"secret","n":1}]'
safe<-atlas_public_privacy(list(renamed=list(bad)),'.')
expect_true(is.null(safe$renamed[[1]]$approximate_mean));expect_equal(safe$renamed[[1]]$numeric_groups_json,'[]')
expect_true(inherits(tryCatch(atlas_evidence_audit(list(renamed=list(bad)),'.'),error=identity),'error'))
cat('PASS v1/v2 mixed typed migration, legacy ambiguity, foreign-property rejection and renamed-path audit\n')
