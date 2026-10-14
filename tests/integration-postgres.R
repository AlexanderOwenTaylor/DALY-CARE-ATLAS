# Synthetic-only acceptance. A skipped invocation is not PostgreSQL acceptance.
if(!identical(Sys.getenv('DALYCARE_TEST_POSTGRES'),'1')) {
  cat('SKIP PostgreSQL acceptance: set DALYCARE_TEST_POSTGRES=1 and PG connection variables.\n')
  quit(status=0)
}
source('tests/helper.R')
source('R/registry_summaries.R')
source('R/registry_summary_privacy.R')
stopifnot(requireNamespace('RPostgres',quietly=TRUE))
Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE'))
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
connection <- DBI::dbConnect(RPostgres::Postgres())
DBI::dbBegin(connection)
tryCatch({
  # A transaction-local schema and rollback isolate tests even on an existing test DB.
  schema <- paste0('atlas_synthetic_',Sys.getpid())
  DBI::dbExecute(connection,paste('CREATE SCHEMA',DBI::dbQuoteIdentifier(connection,schema)))
  policy <- registry_summary_policy('.')
  for(table in c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL')) {
    categorical <- Filter(function(f) f$table_name==table&&f$kind=='categorical'&&length(f$categories)>=2,policy)[[1]]
    numeric <- Filter(function(f) f$table_name==table&&f$kind=='numeric',policy)[[1]]
    ref <- DBI::Id(schema=schema,table=table)
    quoted <- as.character(DBI::dbQuoteIdentifier(connection,ref))
    codes <- unlist(categorical$categories)[1:2]
    frame <- data.frame(patientid=sprintf('SYNTHETIC-%03d',1:40),stringsAsFactors=FALSE)
    frame[[categorical$source_column]] <- rep(codes,each=20)
    frame[[numeric$source_column]] <- rep(c('1','2'),each=20)
    put <- function(data) DBI::dbWriteTable(connection,ref,data,overwrite=TRUE,row.names=FALSE)
    query <- function(spec) DBI::dbGetQuery(connection,registry_summary_sql(connection,quoted,'patientid',spec,'postgres',5000L))
    row_for <- function(rows,column) rows[rows$source_column==column,,drop=FALSE]
    put(rbind(frame,frame))
    groups <- query(categorical)
    stopifnot(nrow(groups)==2,sum(groups$n)==40,all(groups$n==20))
    published <- dbi_registry_field_summaries(connection,quoted,table,names(frame),'.')
    stopifnot(row_for(published,categorical$source_column)$summary_status=='published')
    stopifnot(row_for(published,numeric$source_column)$summary_status=='needs_unit_evidence')
    stopifnot(row_for(dbi_registry_field_summaries(connection,quoted,table,names(frame),'.',21),categorical$source_column)$summary_status=='withheld_small_group')
    conflict <- frame[1:5,,drop=FALSE];conflict[[categorical$source_column]]<-codes[2];conflict[[numeric$source_column]]<-'1.1'
    put(rbind(frame,conflict));groups<-query(numeric)
    stopifnot(sum(groups$n[groups$status=='conflicting'])==5)
    # Recognised plus unknown is a conflict, never silently the recognised value.
    conflict[[categorical$source_column]]<-'SYNTHETIC_FORBIDDEN_TOKEN'
    put(rbind(frame,conflict));groups<-query(categorical)
    stopifnot(sum(groups$n[groups$status=='conflicting'])==5,!any(grepl('FORBIDDEN|SYNTHETIC-',as.character(unlist(groups)))))
    malformed<-frame
    malformed[[numeric$source_column]]<-rep(c('1e999999999999999999999','1e309','NaN','Infinity','-1','not-a-number','1.5','2e1'),each=5)
    put(malformed);groups<-query(numeric)
    stopifnot(sum(groups$n[groups$status=='invalid'])==30,sum(groups$n[groups$status=='valid'])==10)
    missing<-frame;missing$patientid[1]<-'';put(missing)
    stopifnot(row_for(dbi_registry_field_summaries(connection,quoted,table,names(frame),'.'),categorical$source_column)$summary_status=='missing_person_key')
  }
  cat('PASS PostgreSQL C1 production SQL acceptance: three registries, repeated people, conflicts, unknown encoding, threshold, malformed/overflow numeric values and missing keys. Grouped v2 acceptance remains C2.\n')
},finally={DBI::dbRollback(connection);DBI::dbDisconnect(connection)})
