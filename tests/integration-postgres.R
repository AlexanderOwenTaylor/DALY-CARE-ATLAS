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
    stopifnot(row_for(dbi_registry_field_summaries(connection,quoted,table,names(frame),'.',21),categorical$source_column)$summary_status=='withheld_privacy')
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
  source('tests/registry-v2-fixture.R');registry_v2_test_setup()
  specs<-registry_v2_fields('.')
  numeric<-Filter(function(s)s$table_name=='RKKP_DaMyDa'&&s$source_column=='Reg_Haemoglobin',specs)[[1]]
  ref<-DBI::Id(schema=schema,table='v2_numeric');quoted<-as.character(DBI::dbQuoteIdentifier(connection,ref))
  numeric_case<-function(values,ids=seq_along(values),k=5) {
    frame<-data.frame(patientid=as.character(ids),Reg_Haemoglobin=values)
    DBI::dbWriteTable(connection,ref,frame,overwrite=TRUE,row.names=FALSE)
    groups<-DBI::dbGetQuery(connection,registry_summary_sql(connection,quoted,'patientid',numeric,'postgres',5000L))
    sql_row<-registry_summary_from_groups(numeric,groups,k)
    memory<-registry_field_summaries(frame,'RKKP_DaMyDa','.',k);memory<-memory[memory$source_column=='Reg_Haemoglobin',,drop=FALSE]
    rownames(memory)<-NULL;rownames(sql_row)<-NULL
    stopifnot(identical(memory,sql_row));sql_row
  }
  stopifnot(numeric_case(rep(c('1','11','21','31'),each=5))$summary_status=='published')
  stopifnot(numeric_case(rep(c('1','11','21','31'),c(4,6,5,5)))$band_level==1)
  stopifnot(numeric_case(c(rep('1',10),rep('11',9)))$summary_status=='withheld_privacy')
  stopifnot(numeric_case(c(rep('1',10),rep('11',9),'100'))$summary_status=='withheld_privacy')
  stopifnot(is.na(numeric_case(rep(c('1','11','50','60'),each=5))$approximate_mean))
  stopifnot(numeric_case(rep('1',20))$summary_status=='withheld_privacy')
  numeric_case(c(rep(c('1','11'),each=10),'2'),c(1:20,1))
  for(bad in c('1e999999999999999999999','1e309','1e-9999','5e-324','NaN','Infinity','-1','00','+1','1.','1e00001','SYNTHETIC_POISON','1.79769313486231571e308','2.22507385850720139e-308')) numeric_case(rep(bad,20))
  for(boundary in c('0','9.999999999999998','10','10.000000000000002','19.999999999999996','20','40','2.2250738585072014e-308','1.7976931348623157e308'))numeric_case(rep(c(boundary,'11'),each=10))
  for(k in c(1,5,10,11)) numeric_case(rep(c('1','11'),each=10),k=max(5,k))
  for(partition in c('missing','unknown','conflict'))for(n in 1:4) {
    values<-rep(c('1','11'),each=10);ids<-1:20
    if(partition=='missing')values[seq_len(n)]<-NA_character_
    if(partition=='unknown')values[seq_len(n)]<-'SYNTHETIC_POISON'
    if(partition=='conflict'){values<-c(values,rep('2',n));ids<-c(ids,seq_len(n))}
    stopifnot(numeric_case(values,ids)$summary_status=='withheld_privacy')
  }
  # Compare raw grouped results too: privacy withholding must not hide divergence.
  converted<-numeric;converted$binding$evidence$stored_to_display_multiplier<-0.1
  conversion_values<-c('99.99999999999999','100','100.00000000000001','199.99999999999997','200','400','2.2250738585072014e-308','1.7976931348623157e308','0')
  conversion_frame<-data.frame(patientid=seq_along(conversion_values),Reg_Haemoglobin=conversion_values)
  DBI::dbWriteTable(connection,ref,conversion_frame,overwrite=TRUE,row.names=FALSE)
  pg_groups<-DBI::dbGetQuery(connection,registry_summary_sql(connection,quoted,'patientid',converted,'postgres',5000L))
  memory_groups<-registry_v2_group_data(conversion_frame,'patientid',converted)
  normalize_groups<-function(g){g$n<-as.numeric(g$n);g<-g[order(g$status,g$value),c('status','value','n')];rownames(g)<-NULL;g}
  stopifnot(identical(normalize_groups(pg_groups),normalize_groups(memory_groups)))
  categorical<-Filter(function(s)s$table_name=='RKKP_LYFO'&&s$source_column=='Beh_ErDerForetagetKemo',specs)[[1]]
  alias_frame<-data.frame(patientid=rep(1:20,2),Beh_ErDerForetagetKemo=rep(c(rep('Y',10),rep('N',10),rep(' y ',10),rep(' n ',10))))
  DBI::dbWriteTable(connection,ref,alias_frame,overwrite=TRUE,row.names=FALSE)
  aliases<-DBI::dbGetQuery(connection,registry_summary_sql(connection,quoted,'patientid',categorical,'postgres',5000L))
  stopifnot(sum(as.numeric(aliases$n[aliases$status=='valid']))==20,!any(aliases$status=='conflicting'))
  cat('PASS PostgreSQL v2 fixed groups, coarsening, open tails, 19/20, constant, complements, same-band conflicts, aliases and exact parser boundaries.\n')
  cat('PASS PostgreSQL C1 production SQL acceptance: three registries, repeated people, conflicts, unknown encoding, threshold, malformed/overflow numeric values and missing keys.\n')
},finally={DBI::dbRollback(connection);DBI::dbDisconnect(connection)})
