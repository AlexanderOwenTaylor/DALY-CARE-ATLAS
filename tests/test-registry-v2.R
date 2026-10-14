source('tests/helper.R')
source('R/registry_summary_privacy.R'); source('R/registry_summaries.R')
Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE','DALYCARE_REGISTRY_NUMERIC_POLICY_FILE'))
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
expect_equal(readBin('config/registry-summary-policy-v2.json','raw',n=1e6),readBin('inst/config/registry-summary-policy-v2.json','raw',n=1e6),'Mirrored v2 policy bytes are identical across installed/source paths.')
one <- function(data,col='Beh_ErDerForetagetKemo',table='RKKP_LYFO') {
  out <- registry_field_summaries(data,table,'.'); out[out$source_column==col,,drop=FALSE]
}
data <- data.frame(patientid=1:20,Beh_ErDerForetagetKemo=rep(c('Y','N'),each=10))
row <- one(data)
expect_equal(row$contract_version,'registry-summary-v2','New producers emit the coherent v2 contract.')
expect_equal(row$summary_status,'published')
expect_equal(row$collection_status,'complete')
expect_equal(row$data_status,'usable_values')
expect_equal(row$n_valid,20)
expect_equal(one(rbind(data,transform(data,Beh_ErDerForetagetKemo=paste0(' ',tolower(Beh_ErDerForetagetKemo),' '))))$n_valid,20)
for (case in c('all_missing','all_unrecognised','all_conflicting','empty_source')) {
  sample <- data
  if(case=='all_missing') sample$Beh_ErDerForetagetKemo <- NA_character_
  if(case=='all_unrecognised') sample$Beh_ErDerForetagetKemo <- 'SYNTHETIC_POISON'
  if(case=='all_conflicting') sample <- rbind(sample,transform(sample,Beh_ErDerForetagetKemo='SYNTHETIC_POISON'))
  if(case=='empty_source') sample <- sample[FALSE,]
  got <- one(sample)
  expect_equal(got$data_status,case)
  expect_false(any(grepl('SYNTHETIC_POISON',as.character(unlist(got)),fixed=TRUE)))
}
expect_equal(one(data[1,,drop=FALSE])$summary_status,'withheld_privacy')
expect_equal(one(data['patientid'])$collection_status,'field_absent')
expect_equal(one(data['Beh_ErDerForetagetKemo'])$collection_status,'missing_person_key')
regimens<-data.frame(patientid=1:20,Beh_Kemoterapiregime1=rep(c(' CHOP ','bendamustin'),each=10))
expect_equal(one(regimens,'Beh_Kemoterapiregime1')$summary_status,'published')
cll<-data.frame(patientid=1:20,Beh_TargeteretBeh_Ibrutinib='Y')
expect_equal(one(cll,'Beh_TargeteretBeh_Ibrutinib','RKKP_CLL')$summary_status,'published')
cll$Beh_TargeteretBeh_Ibrutinib<-' y '
expect_equal(one(cll,'Beh_TargeteretBeh_Ibrutinib','RKKP_CLL')$data_status,'all_unrecognised')
other<-data.frame(patientid=1:20,Beh_Kemo_Fludarabin='Y')
expect_equal(one(other,'Beh_Kemo_Fludarabin','RKKP_CLL')$data_status,'all_unrecognised')
mixed<-data.frame(patientid=c(1:15,11:15),Beh_ErDerForetagetKemo=c(rep(NA_character_,5),rep('SYNTHETIC_POISON',5),rep('Y',5),rep('N',5)))
expect_equal(one(mixed)$data_status,'no_usable_values')
cat('Registry v2 status and reviewed-alias tests passed.\n')
source('tests/registry-v2-fixture.R');work<-registry_v2_test_setup()
numeric_row<-function(x,pid=seq_along(x))one(data.frame(patientid=pid,Reg_Haemoglobin=x),'Reg_Haemoglobin','RKKP_DaMyDa')
safe<-numeric_row(rep(c('1','11','21','31'),each=5))
expect_equal(safe$summary_status,'published')
expect_equal(safe$approximate_mean,20)
expect_equal(safe$p25_band,'b0_1');expect_equal(safe$median_band,'b1_2');expect_equal(safe$p75_band,'b2_3')
expect_equal(numeric_row(rep(c('1','11','21','31'),c(4,6,5,5)))$band_level,1)
expect_equal(numeric_row(c(rep('1',10),rep('11',9)))$summary_status,'withheld_privacy')
expect_equal(numeric_row(c(rep('1',10),rep('11',9),'100'))$summary_status,'withheld_privacy')
tail<-numeric_row(rep(c('1','11','50','60'),each=5));expect_true(is.na(tail$approximate_mean));expect_true(is.na(tail$iqr_upper))
same_band<-numeric_row(c(rep(c('1','11'),each=10),'2'),c(1:20,1));expect_equal(same_band$summary_status,'withheld_privacy')
expect_equal(numeric_row(rep('1',20))$summary_status,'withheld_privacy')
expect_equal(numeric_row(rep(c('2','12','22','32'),each=5))$approximate_mean,safe$approximate_mean)
guarded<-atlas_registry_summary_guard(safe,'.');expect_true(atlas_registry_summary_audit(guarded,'.')$ok)
expect_equal(atlas_registry_summary_guard(guarded,'.'),guarded)
for(key in c('approximate_mean','denominator_n','band_level')) {
  bad<-guarded;bad[[1]][[key]]<-bad[[1]][[key]]+1
  expect_false(atlas_registry_summary_audit(bad,'.')$ok)
}
for(key in c('collection_status','data_status','publication_status','summary_status','category_counts_json','numeric_groups_json')) {
  malformed<-guarded;malformed[[1]][key]<-list(NULL)
  expect_false(atlas_registry_summary_audit(malformed,'.')$ok)
  expect_equal(atlas_registry_summary_guard(malformed,'.')[[1]]$summary_status,'invalid_contract')
}
expect_equal(atlas_registry_summary_guard(guarded,'.',11)[[1]]$summary_status,'invalid_contract')
jsonlite::write_json(c(guarded,atlas_registry_summary_guard(tail,'.')),file.path(work,'golden.json'),auto_unbox=TRUE,null='null',digits=NA)
s<-Filter(function(s)s$table_name=='RKKP_DaMyDa'&&s$source_column=='Reg_Haemoglobin',registry_v2_fields('.'))[[1]]
writeLines(registry_summary_sql(DBI::ANSI(),'cohort','patientid',s,'sqlite',5000L),file.path(work,'numeric.sql'))
jsonlite::write_json(registry_v2_public_resource('.'),file.path(work,'resource.json'),auto_unbox=TRUE,null='null',digits=NA)
cat('Registry v2 synthetic grouped release, intervals, privacy and tamper tests passed.\n')

# Nonidentity binary64 conversion is tested at band and safe-domain boundaries.
conversion_values<-c('99.99999999999999','100','100.00000000000001','199.99999999999997','200','400','2.2250738585072014e-308','1.7976931348623157e308','0')
conversion<-s;conversion$binding$evidence$stored_to_display_multiplier<-0.1
conversion_frame<-data.frame(patientid=seq_along(conversion_values),Reg_Haemoglobin=conversion_values)
jsonlite::write_json(list(values=conversion_values,groups=registry_v2_group_data(conversion_frame,'patientid',conversion)),file.path(work,'conversion.json'),auto_unbox=TRUE,null='null',digits=NA)
writeLines(registry_summary_sql(DBI::ANSI(),'cohort','patientid',conversion,'sqlite',5000L),file.path(work,'conversion.sql'))
