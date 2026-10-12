source('tests/helper.R'); source_test_runtime()
root <- normalizePath('.',winslash='/')
temp_parent <- file.path(root,'.artifact-temp/vital-profiles')
dir.create(temp_parent,recursive=TRUE,showWarnings=FALSE)
tmp <- tempfile('r-',tmpdir=temp_parent);dir.create(tmp)
out <- file.path(tmp,'site')
identity <- c('table_name','column_name','column_type','column_class')
summary_keys <- c('n_rows','n_available','pct_available','mean','median','p25','p75','numeric_privacy_status','availability_privacy_status','summary_scope','summary_method','is_sensitive')
profile <- function(table,field,...) modifyList(list(table_name=table,column_name=field,column_type='decimal',column_class='numeric',profile_kind='numeric',n_rows=100,n_available=80,pct_available=80,n_missing=20,n_distinct_capped=20,min=0,max=999,mean=24,median=23,p25=21,p75=26,is_sensitive=FALSE,availability_privacy_status='available'),list(...))
read_catalogue <- function(paths) jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=', '',paste(readLines(paths$catalogue,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
publish_profiles <- function(rows,payload=list(run_id='vital-profiles')) {
  descriptor <- Filter(function(t)t$id=='column_profiles',atlas_output_evidence(NULL,root,list()))[[1]]
  descriptor$rows <- rows
  atlas_write_site_bundle(out,payload,list(descriptor),root,'legacy_payload',transport_version=1L)
}
event_fields <- c('displayname','numericvalue','recorded_time','meas_value','meas_value_clean','val_type_c','val_type_name','isaccepted_yn','template_name','date_received','datetime_created')
dedicated <- list(c('SP_PatientInfo','bmi'),c('SP_PatientInfo','weight_in_kg'),c('SP_PatientInfo','height_in_cm'),c('RKKP_DaMyDa','Reg_Hoejde'),c('RKKP_DaMyDa','Reg_Vaegt'))
events <- lapply(event_fields,function(field)profile('SP_VitaleVaerdier',field))
dedicated_rows <- lapply(dedicated,function(pair)profile(pair[[1]],pair[[2]]))
excluded <- list(profile('SP_VitaleVaerdier_old','numericvalue'),profile('sp_vitalevaerdier','numericvalue'),profile('SP_VitaleVaerdier','NumericValue'),profile('SP_VitaleVaerdier','patient_id'),profile('SP_PatientInfo','bmi_old'),profile('RKKP_DaMyDa_old','Reg_Vaegt'),profile('Other','bmi'))
paths <- publish_profiles(c(events,dedicated_rows,list(dedicated_rows[[1]]),excluded),list(run_id='vital-profiles',column_profile_rows=list(profile('SP_PatientInfo','bmi',mean=999))))
emitted <- read_catalogue(paths)$vital_profiles
expect_true(is.list(emitted) && length(emitted)==17L,'Writer must emit exact selected vital_profiles including duplicate rows')
expect_equal(emitted[seq_len(11)],lapply(events,function(row)row[identity]))
for(i in seq_along(dedicated)) {
  row <- emitted[[11+i]]
  expect_equal(names(row),c(identity,summary_keys))
  expect_equal(unlist(row[c('table_name','column_name')],use.names=FALSE),dedicated[[i]])
  expect_equal(as.numeric(unlist(row[c('n_rows','n_available','pct_available','mean','median','p25','p75')],use.names=FALSE)),c(100,80,80,24,23,21,26))
  stopifnot(row$numeric_privacy_status=='eligible_stored_summary',row$availability_privacy_status=='available',row$summary_scope=='stored_source_row_profile',row$summary_method=='supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample')
}
expect_equal(emitted[[17]],emitted[[12]])
wire <- jsonlite::fromJSON(paths$payload_json,simplifyVector=FALSE)
stopifnot(wire$payload$column_profile_rows[[1]]$mean==999)
# A broad projection would leak raw values, identifiers, extrema or unrelated metadata.
unsafe <- list(raw_value='FORBIDDEN_RAW',top_value='FORBIDDEN_TOP',patient_id='FORBIDDEN_ID',arbitrary='FORBIDDEN_METADATA',min_date='1927-02-03',max_date='1927-02-04')
emitted <- read_catalogue(publish_profiles(list(modifyList(profile('SP_VitaleVaerdier','numericvalue'),unsafe),modifyList(profile('SP_PatientInfo','bmi'),unsafe))))$vital_profiles
expect_equal(names(emitted[[1]]),identity);expect_equal(names(emitted[[2]]),c(identity,summary_keys))
stopifnot(!grepl('FORBIDDEN|1927-',jsonlite::toJSON(emitted,auto_unbox=TRUE)))
cases <- list(list(changes=list(is_sensitive=TRUE),status='protected_field'),list(changes=list(n_available=4),status='withheld_small_complementary_cells'),list(changes=list(n_missing=1),status='withheld_small_complementary_cells'),list(changes=list(min=-999),status='needs_validation_negative_sentinel'),list(changes=list(numeric_privacy_status='withheld_constant_profile'),status='withheld_constant_profile'))
for(case in cases) {
  row <- read_catalogue(publish_profiles(list(modifyList(profile('SP_PatientInfo','bmi'),case$changes))))$vital_profiles[[1]]
  expect_equal(row$numeric_privacy_status,case$status)
  expect_true(all(vapply(row[c('mean','median','p25','p75')],is.null,logical(1))))
  if(case$status=='withheld_small_complementary_cells') {
    expect_equal(row$availability_privacy_status,case$status)
    stopifnot(is.null(row$n_available),is.null(row$pct_available))
  }
  if(case$status=='protected_field') expect_equal(row$is_sensitive,TRUE)
}
for(payload in list(list(),list(column_profile_rows=list()),list(column_profile_alias=list(profile('SP_PatientInfo','bmi'))),list(column_profile_rows=list(profile('Other','bmi'))))) {
  paths <- atlas_write_site_bundle(out,payload,list(),root,'legacy_payload')
  stopifnot(!'vital_profiles' %in% names(read_catalogue(paths)))
}
paths <- atlas_write_site_bundle(out,list(column_profile_rows=list(profile('SP_PatientInfo','bmi'))),list(),root,'legacy_payload')
stopifnot(read_catalogue(paths)$vital_profiles[[1]]$mean==24)
prior_paths <- c(unlist(paths$assets),paths$manifest);prior <- tools::md5sum(prior_paths)
wide <- profile('SP_VitaleVaerdier','numericvalue',column_type=paste(rep('x',530000),collapse=''))
failed <- try(atlas_write_site_bundle(out,list(column_profile_rows=list(wide)),list(),root,'legacy_payload'),silent=TRUE)
expect_true(inherits(failed,'try-error'),'Directory must obey initial asset budget')
stopifnot(grepl('Initial asset byte budget exceeded',as.character(failed),fixed=TRUE))
expect_equal(tools::md5sum(prior_paths),prior)
unlink(tmp,recursive=TRUE)
cat('Vital profile bundle R tests passed\n')
