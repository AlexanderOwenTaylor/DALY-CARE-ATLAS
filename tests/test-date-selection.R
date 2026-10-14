source('tests/helper.R');source_test_runtime()
mapping<-tempfile(fileext='.csv')
write.csv(data.frame(table_name='RKKP_CLL',column_name=c('event_date','observation_token'),
 format_rule=c('ymd_compact','dmy_dash'),reviewed=TRUE),mapping,row.names=FALSE)
Sys.setenv(DALYCARE_DATE_FORMATS_FILE=mapping)
for(case in list(list(column='event_date',type='integer',class='int4',values=rep(c(20240101L,20250101L),each=5)),
 list(column='observation_token',type='text',class='text',values=rep(c('01-01-2024','01-01-2025'),each=5)))) {
 frame<-data.frame(patientid=1:10);frame[[case$column]]<-case$values
 profiles<-profile_column_profiles(frame,'RKKP_CLL')
 schema<-dbi_schema_column_profiles(data.frame(column_name=c('patientid',case$column),data_type=c('integer',case$type),udt_name=c('int4',case$class)),'RKKP_CLL',10)
 expect_equal(profiles$profile_kind[profiles$column_name==case$column],'date')
 expect_equal(schema$profile_kind[schema$column_name==case$column],'date')
 evidence<-coverage_evidence_panels_from_data(frame,'RKKP_CLL')$coverage_evidence
 if(case$column=='event_date') {
   expect_equal(coverage_date_column_from_profiles(profiles),'event_date')
   expect_equal(coverage_date_column_from_profiles(schema),'event_date')
   expect_equal(sort(evidence$group_value[evidence$dimension=='year']),c('2024','2025'))
   expect_true(all(evidence$release_status[evidence$dimension=='year']=='published'))
 } else {
   expect_true(is.na(coverage_date_column_from_profiles(profiles)))
   expect_true(is.na(coverage_date_column_from_profiles(schema)))
   db_evidence<-dbi_coverage_evidence(DBI::ANSI(),'unused',schema,data.frame(table_name='RKKP_CLL',n_rows=10))
   for(result in list(evidence,db_evidence)) {
     temporal<-result[result$dimension%in%c('year','date_quality','date_format'),]
     expect_true(all(temporal$collection_status=='missing_column'))
     expect_true(all(is.na(temporal$column_name))&&all(is.na(temporal$group_value))&&all(is.na(temporal$record_count)))
   }
 }
}
Sys.unsetenv('DALYCARE_DATE_FORMATS_FILE');unlink(mapping)
cat('PASS reviewed formats parse both fields; only selected event_date supplies annual groups; observation_token remains missing_column\n')
