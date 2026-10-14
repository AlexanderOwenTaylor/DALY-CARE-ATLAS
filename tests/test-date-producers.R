source('tests/helper.R');source_test_runtime()
library(DBI)
# Controlled DBI transport exercises actual profile dispatch/stream handling.
# SQL execution/calendar parity is separately tested by integration-postgres.R.
methods::setClass('DDateConnection',contains='DBIConnection',slots=c(state='environment'))
methods::setClass('DDateResult',contains='DBIResult',slots=c(state='environment'))
methods::setMethod('dbQuoteIdentifier',c(conn='DDateConnection',x='character'),function(conn,x,...)DBI::dbQuoteIdentifier(DBI::ANSI(),x))
methods::setMethod('dbSendQuery',c(conn='DDateConnection',statement='character'),function(conn,statement,...) {
 conn@state$sql<-c(conn@state$sql,statement)
 state<-new.env();state$done<-FALSE
 state$values<-if(grepl('as is_missing',statement,fixed=TRUE))is.na(conn@state$values) else conn@state$values
 methods::new('DDateResult',state=state)
})
methods::setMethod('dbFetch','DDateResult',function(res,n=-1,...) {
 if(res@state$done)return(data.frame(value=res@state$values[FALSE]))
 res@state$done<-TRUE;data.frame(value=res@state$values)
})
methods::setMethod('dbClearResult','DDateResult',function(res,...)TRUE)
methods::setMethod('dbGetQuery',c(conn='DDateConnection',statement='character'),function(conn,statement,...) {
 conn@state$sql<-c(conn@state$sql,statement)
 if(grepl('as n_missing',statement,fixed=TRUE))return(data.frame(n_missing=0,n_distinct=1))
 if(grepl('as min_date',statement,fixed=TRUE))return(data.frame(min_date='2024-01-01',max_date='2024-01-01'))
 data.frame(min=20240101,mean=20240101,median=20240101,p25=20240101,p75=20240101,max=20240101)
})
mapping<-tempfile(fileext='.csv')
write.csv(data.frame(table_name='RKKP_CLL',column_name=c('event_date','observation_token','patientid'),format_rule=c('ymd_compact','dmy_dash','ymd_compact'),reviewed=TRUE),mapping,row.names=FALSE)
Sys.setenv(DALYCARE_DATE_FORMATS_FILE=mapping,DALYCARE_ATLAS_PROGRESS='FALSE')
for(case in list(list(column='event_date',type='integer',class='int4',values=rep(20240101L,5)),
 list(column='observation_token',type='text',class='text',values=rep('01-01-2024',5)))) {
 state<-new.env();state$values<-case$values;state$sql<-character();conn<-methods::new('DDateConnection',state=state)
 info<-data.frame(column_name=case$column,data_type=case$type,udt_name=case$class)
 schema_profile<-dbi_schema_column_profiles(info,'RKKP_CLL',5)
 expect_equal(schema_profile$profile_kind,'date');expect_true(is.na(schema_profile$min_date))
 sql<-dbi_column_profile(conn,'fixture',info,'RKKP_CLL',5,'full')
 expect_equal(sql$profile_kind,'date');expect_equal(sql$min_date,'2024-01-01');expect_equal(sql$max_date,'2024-01-01')
 expect_false(sql$is_numeric_like);expect_true(any(grepl('make_date',state$sql,fixed=TRUE)))
 streamed<-dbi_stream_column_profile(conn,'fixture',info,'RKKP_CLL',5,'full')$profile
 expect_equal(streamed$profile_kind,'date');expect_equal(streamed$min_date,sql$min_date);expect_equal(streamed$max_date,sql$max_date)
 expect_true(is.na(streamed$sample_size))
}
info<-data.frame(column_name='patientid',data_type='integer',udt_name='int4')
state$values<-rep(20240101L,5);state$sql<-character()
for(profile in list(dbi_column_profile(conn,'fixture',info,'RKKP_CLL',5,'full'),dbi_stream_column_profile(conn,'fixture',info,'RKKP_CLL',5,'full')$profile)) {
 expect_equal(profile$profile_kind,'sensitive');expect_true(is.na(profile$min_date));expect_false(profile$is_date_like)
}
expect_false(any(grepl('make_date',state$sql,fixed=TRUE)))
Sys.unsetenv('DALYCARE_DATE_FORMATS_FILE');unlink(mapping)
state$sql<-character()
invisible(dbi_column_profile(conn,'fixture',data.frame(column_name='event_date',data_type='timestamp with time zone',udt_name='timestamptz'),'RKKP_CLL',5,'full'))
expect_true(any(grepl("at time zone 'UTC'",state$sql,fixed=TRUE)),'Timestamptz profile extrema must use UTC dates.')
Sys.unsetenv('DALYCARE_ATLAS_PROGRESS')
cat('PASS SQL/stream mapped date dispatch, sensitive field protection and UTC extrema expression\n')
