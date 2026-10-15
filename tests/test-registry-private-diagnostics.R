source('tests/helper.R');source_test_runtime('.');library(DBI)
Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE','DALYCARE_REGISTRY_NUMERIC_POLICY_FILE'))
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5',DALYCARE_ATLAS_DB_BUDGET_MODE='TRUE')
data<-data.frame(patientid=sprintf('PRIVATE_PERSON_%02d',1:20),Beh_Immunterapi=c(rep('0',19),'UNMAPPED_SYNTHETIC'))
get_diag<-function(rows) {
  d<-attr(rows,'registry_interpretation_diagnostics')
  expect_true(is.data.frame(d),'Producer must retain private interpretation evidence before public withholding.')
  d[d$source_column=='Beh_Immunterapi',,drop=FALSE]
}
check<-function(rows,valid=19,invalid=1,conflicting=0) {
  public<-rows[rows$source_column=='Beh_Immunterapi',,drop=FALSE]
  expect_equal(public$publication_status,'withheld_privacy')
  expect_true(all(is.na(public[registry_v2_counts])))
  d<-get_diag(rows)
  expect_equal(d$collection_status,'complete');expect_equal(d$n_valid,as.numeric(valid))
  expect_equal(d$n_unrecognised,as.numeric(invalid));expect_equal(d$n_conflicting,as.numeric(conflicting))
  expect_equal(d$denominator_n,20)
  expect_false(any(grepl('PRIVATE_PERSON_|UNMAPPED_SYNTHETIC',as.character(unlist(d)))))
  invisible(d)
}
memory<-registry_field_summaries(data,'RKKP_CLL','.')
check(memory)
check(registry_field_summaries(rbind(data,data),'RKKP_CLL','.'))
check(registry_field_summaries(rbind(data,transform(data[1,,drop=FALSE],Beh_Immunterapi='UNMAPPED_SYNTHETIC')),'RKKP_CLL','.'),18,1,1)
panels<-profile_panels(data,'RKKP_CLL','summary')
expect_equal(panels$registry_interpretation_diagnostics,attr(memory,'registry_interpretation_diagnostics'))
expect_true(is.null(attr(panels$registry_field_summaries,'registry_interpretation_diagnostics')))
# Real generated SQL is executed through Python's standard SQLite engine.
methods::setClass('PrivateDiagnosticsSQLiteConnection',contains='DBIConnection')
methods::setMethod('dbQuoteIdentifier',c('PrivateDiagnosticsSQLiteConnection','character'),function(conn,x,...)DBI::dbQuoteIdentifier(DBI::ANSI(),x))
methods::setMethod('dbQuoteString',c('PrivateDiagnosticsSQLiteConnection','character'),function(conn,x,...)DBI::dbQuoteString(DBI::ANSI(),x))
mode<-'ok';queries<-0L
methods::setMethod('dbGetQuery',c('PrivateDiagnosticsSQLiteConnection','character'),function(conn,statement,...) {
  queries<<-queries+1L
  if(mode=='error')stop('synthetic query failure PRIVATE_QUERY_VALUE')
  if(mode=='timeout')stop('synthetic statement timeout PRIVATE_QUERY_VALUE')
  work<-tempfile('private-sql-');dir.create(work)
  on.exit(unlink(work,recursive=TRUE))
  write.csv(data,file.path(work,'data.csv'),row.names=FALSE)
  writeLines(statement,file.path(work,'query.sql'))
  code<-"import csv,sqlite3,sys;from pathlib import Path;p=Path(sys.argv[1]);c=sqlite3.connect(':memory:');c.execute('create table cohort(patientid text, Beh_Immunterapi text)');c.executemany('insert into cohort values(?,?)',[(r['patientid'],r['Beh_Immunterapi']) for r in csv.DictReader((p/'data.csv').open())]);rows=c.execute((p/'query.sql').read_text()).fetchall();f=(p/'groups.csv').open('w',newline='');w=csv.writer(f);w.writerow(['status','value','n']);w.writerows(rows);f.close()"
  writeLines(code,file.path(work,'sql.py'))
  stopifnot(system2(Sys.which('python'),shQuote(c(file.path(work,'sql.py'),work)))==0)
  read.csv(file.path(work,'groups.csv'),stringsAsFactors=FALSE)
})
conn<-methods::new('PrivateDiagnosticsSQLiteConnection')
budget<-new_db_budget_context('RKKP_CLL',20)
sql<-dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.',budget_context=budget)
expect_equal(check(sql),get_diag(memory));expect_equal(queries,1L)
log<-budget$query_log();expect_equal(log$status,'ok');expect_true(all(is.finite(log$elapsed_ms)&log$elapsed_ms>=0))
original_data<-data
data<-rbind(original_data,original_data)
check(dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.'))
data<-rbind(original_data,transform(original_data[1,,drop=FALSE],Beh_Immunterapi='UNMAPPED_SYNTHETIC'))
check(dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.'),18,1,1)
data<-original_data
mode<-'error'
failed<-dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.',budget_context=budget)
expect_equal(get_diag(failed)$collection_status,'query_failed');expect_true(is.na(get_diag(failed)$n_valid))
expect_equal(tail(budget$query_log()$status,1),'query_failed')
mode<-'timeout'
timed<-new_db_budget_context('RKKP_CLL',20)
timeout<-dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.',budget_context=timed)
expect_equal(get_diag(timeout)$collection_status,'resource_limit');expect_true(is.na(get_diag(timeout)$n_valid))
expect_equal(timed$query_log()$status,'resource_limit')
expect_false(any(grepl('PRIVATE_QUERY_VALUE|SELECT|WITH raw',as.character(unlist(timed$query_log())))))
before<-queries
skipping<-new_db_budget_context('RKKP_CLL',atlas_max_text_distinct_rows()+1)
skipped<-dbi_registry_field_summaries(conn,'"cohort"','RKKP_CLL',names(data),'.',budget_context=skipping)
expect_equal(get_diag(skipped)$collection_status,'resource_limit');expect_true(is.na(get_diag(skipped)$n_valid))
expect_equal(queries,before)
expect_equal(skipping$query_log()$status,'budget_skipped');expect_equal(nrow(skipping$budget_actions()),1L)
cat('PASS private 19+1 evidence, repeated/conflicting people, memory panels, real SQLite success/failure, timeout and budget logging\n')
