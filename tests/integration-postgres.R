# Synthetic-only acceptance. A skipped invocation is not PostgreSQL acceptance.
if(!identical(Sys.getenv('DALYCARE_TEST_POSTGRES'),'1')) {
  cat('SKIP PostgreSQL acceptance: set DALYCARE_TEST_POSTGRES=1 and PG connection variables.\n')
  quit(status=0)
}
source('tests/helper.R')
source('R/registry_summaries.R')
source('R/registry_summary_privacy.R')
source('R/clinical_readiness.R')
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
    attr(memory,'registry_interpretation_diagnostics')<-NULL
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
  # D uses the real generated parser, exact membership aggregate and producer path.
  source_test_runtime()
  # Retain private 19+1 resolution evidence with the actual PostgreSQL producer.
  ref<-DBI::Id(schema=schema,table='private_registry');quoted<-as.character(DBI::dbQuoteIdentifier(connection,ref))
  private_frame<-data.frame(patientid=sprintf('SYNTHETIC_PRIVATE_%02d',1:20),Beh_Immunterapi=c(rep('0',19),'UNMAPPED_SYNTHETIC'))
  DBI::dbWriteTable(connection,ref,private_frame,overwrite=TRUE,row.names=FALSE)
  budget<-new_db_budget_context('RKKP_CLL',20)
  private_sql<-dbi_registry_field_summaries(connection,quoted,'RKKP_CLL',names(private_frame),'.',budget_context=budget)
  private_memory<-registry_field_summaries(private_frame,'RKKP_CLL','.')
  stopifnot(identical(private_sql,private_memory))
  diagnostic<-attr(private_sql,'registry_interpretation_diagnostics');diagnostic<-diagnostic[diagnostic$source_column=='Beh_Immunterapi',]
  public<-private_sql[private_sql$source_column=='Beh_Immunterapi',]
  stopifnot(diagnostic$n_valid==19,diagnostic$n_unrecognised==1,diagnostic$denominator_n==20,
    public$publication_status=='withheld_privacy',all(is.na(public[registry_v2_counts])),
    identical(budget$query_log()$status,'ok'),all(is.finite(budget$query_log()$elapsed_ms)),
    !any(grepl('SYNTHETIC_PRIVATE_|UNMAPPED_SYNTHETIC',as.character(unlist(diagnostic)))))
  # Failure logging needs a savepoint because PostgreSQL aborts a failed transaction.
  DBI::dbExecute(connection,'SAVEPOINT diagnostic_failure')
  absent_ref<-as.character(DBI::dbQuoteIdentifier(connection,DBI::Id(schema=schema,table='private_registry_absent')))
  failed<-dbi_registry_field_summaries(connection,absent_ref,'RKKP_CLL',names(private_frame),'.',budget_context=budget)
  DBI::dbExecute(connection,'ROLLBACK TO SAVEPOINT diagnostic_failure')
  stopifnot(tail(budget$query_log()$status,1)=='query_failed',
    all(attr(failed,'registry_interpretation_diagnostics')$collection_status %in% c('field_absent','query_failed')))
  private_profile<-dbi_profile_table(list(test=connection),'test',schema,'private_registry','RKKP_CLL','dataset','synthetic','summary')
  retained<-private_profile$panels$registry_interpretation_diagnostics
  retained<-retained[retained$source_column=='Beh_Immunterapi',]
  stopifnot(retained$n_valid==19,retained$n_unrecognised==1,
    is.null(attr(private_profile$panels$registry_field_summaries,'registry_interpretation_diagnostics')),
    'registry_complete_person_groups' %in% private_profile$db_query_log$query_category)
  retained_path<-tempfile('postgres-private-diagnostic-',fileext='.csv');write.csv(retained,retained_path,row.names=FALSE)
  retained_csv<-read.csv(retained_path);stopifnot(retained_csv$n_valid==19,retained_csv$n_unrecognised==1);unlink(retained_path)
  cat('PASS PostgreSQL private 19+1 diagnostics and safe success/failure logging.\n')
  Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_DATE_FORMATS_FILE'))
  ref<-DBI::Id(schema=schema,table='date_coverage');quoted<-as.character(DBI::dbQuoteIdentifier(connection,ref))
  dates<-c('2024-02-29','2023-02-29','2024-02-30','2024-13-01','2024-01-01junk','01-02-03','01/02/2024',
    '31-12-2024','20240101','2024-01-01T23:59:59Z','2024-01-01 24:00:00','2024-01-01T12:30:00+02:00',
    '2024-01-01T12:30:00+24:00','2024-01-01T12:30:60Z','1900-02-29','2000-02-29',NA,'','9999-12-31','0000-01-01','\t2024-01-01\r\n','31.12.2024','01-02-03')
  DBI::dbWriteTable(connection,ref,data.frame(id=seq_along(dates),value=dates),overwrite=TRUE,row.names=FALSE)
  for(rule in c('iso','dmy_dash','dmy_slash','dmy_dot','ymd_compact')) {
    expression<-dbi_text_date_string_expression('"value"',rule)
    parsed<-DBI::dbGetQuery(connection,paste0('select ',expression,' parsed from ',quoted,' order by id'))$parsed
    stopifnot(identical(parsed,as.character(safe_as_date(dates,rule))))
  }
  for(rule_name in c('iso','dmy_dash','dmy_slash','dmy_dot','ymd_compact')) {
    rule<-list(format_rule=rule_name,sentinel_dates='9999-12-31')
    reason<-coverage_date_format_sql(connection,'"value"',rule)
    sql_reasons<-DBI::dbGetQuery(connection,paste0('select ',reason,' reason from ',quoted,' order by id'))$reason
    stopifnot(identical(sql_reasons,coverage_date_format_values(dates,rule)))
  }
  compact<-dbi_text_date_string_expression('20240101','ymd_compact')
  stopifnot(DBI::dbGetQuery(connection,paste('select',compact,'d'))$d==as.character(safe_as_date(20240101,'ymd_compact')))
  extracted<-DBI::dbGetQuery(connection,paste0('select ',dbi_date_year_expression('"value"','text','text'),' y from ',quoted,' order by id'))$y
  stopifnot(identical(extracted,as.integer(format(safe_as_date(dates),'%Y'))))
  # Invalid dates cannot crash the Situation cast or contribute a year.
  expression<-situation_date_expression(connection,data.frame(column_name='value',data_type='text',udt_name='text'),'value')
  DBI::dbGetQuery(connection,paste0('select ',expression,' parsed from ',quoted))
  data<-data.frame(patientid=c(1:10,1),event_date=c(rep('2024-01-01',5),rep('2025-01-01',5),'2025-02-01'),
    Region=c(rep('Capital',3),rep('Region Hovedstaden',2),rep('Zealand',6)))
  source_row<-data.frame(table_name='RKKP_CLL',n_rows=nrow(data),n_cols=ncol(data),min_date=NA_character_,max_date=NA_character_,date_column_guess='event_date')
  normalize_e<-function(e){e<-e[order(e$dimension,e$group_value),];rownames(e)<-NULL;e}
  compare_coverage<-function(d) {
    DBI::dbWriteTable(connection,ref,d,overwrite=TRUE,row.names=FALSE)
    profiles<-profile_column_profiles(d,'RKKP_CLL')
    source_row$n_rows<-nrow(d)
    pg<-dbi_coverage_evidence(connection,quoted,profiles,source_row)
    memory<-coverage_evidence_panels_from_data(d,'RKKP_CLL')$coverage_evidence
    stopifnot(identical(normalize_e(pg),normalize_e(memory)))
    pg
  }
  evidence<-compare_coverage(data)
  stopifnot(evidence$outside_person_count[evidence$dimension=='year'&evidence$group_value=='2024']==6)
  rare<-data[c(1:5,11),];rare_evidence<-compare_coverage(rare)
  # Gates apply to each partition: rare year/region cells are unsafe, while
  # homogeneous date quality/format have five people and no outside group.
  expected<-c(year='withheld_privacy',region='withheld_privacy',date_quality='published',date_format='published')
  for(dimension in names(expected)) {
    rows<-rare_evidence[rare_evidence$dimension==dimension,]
    stopifnot(nrow(rows)>0,all(rows$release_status==expected[[dimension]]))
    if(dimension%in%c('date_quality','date_format'))stopifnot(nrow(rows)==1,rows$record_count==6,rows$person_count==5,
      rows$outside_record_count==0,rows$outside_person_count==0)
  }
  one<-data;one$patientid<-1;stopifnot(all(compare_coverage(one)$release_status=='withheld_privacy'))
  missing<-data;missing$patientid[1]<-NA;stopifnot(all(compare_coverage(missing)$release_status=='missing_person_key'))
  quality<-data.frame(patientid=1:20,event_date=rep(c('2024-01-01',NA,'2024-02-30','9999-12-31'),each=5),Region=rep(c('Capital','Zealand','confidential',''),each=5))
  compare_coverage(quality)
  partial<-data.frame(patientid=1:21,event_date=c(rep('2024-01-01',10),rep('2025-01-01',10),'bad'),Region=c(rep('Capital',10),rep('Zealand',10),'PRIVATE unknown'))
  labels<-coverage_release_panels(list(coverage_evidence=compare_coverage(partial)),source_row)
  stopifnot(identical(labels$atlas_temporal_coverage_years$year,c(2024L,2025L)),all(is.na(labels$atlas_temporal_coverage_years$n_rows)),
    identical(labels$atlas_spatial_region_counts$region_code,c('1084','1085')),all(is.na(labels$atlas_spatial_region_counts$n_rows)))
  mapped<-tempfile(fileext='.csv')
  write.csv(data.frame(table_name='RKKP_CLL',column_name='event_date',format_rule='dmy_dash',reviewed=TRUE,sentinel_dates='9999-12-31'),mapped,row.names=FALSE)
  Sys.setenv(DALYCARE_DATE_FORMATS_FILE=mapped)
  quality$event_date<-rep(c('31-12-2024',NA,'29-02-2023','31-12-9999'),each=5)
  compare_coverage(quality);Sys.unsetenv('DALYCARE_DATE_FORMATS_FILE');unlink(mapped)
  # Reviewed mappings must reach both real SQL and streamed profile producers,
  # including numeric representations and names outside the date heuristic.
  for(case in list(list(column='event_date',type='integer',class='int4',rule='ymd_compact',values=rep(c(20240101L,20250101L),each=5)),
    list(column='observation_token',type='text',class='text',rule='dmy_dash',values=rep(c('01-01-2024','01-01-2025'),each=5)))) {
    mapped<-tempfile(fileext='.csv')
    write.csv(data.frame(table_name='RKKP_CLL',column_name=case$column,format_rule=case$rule,reviewed=TRUE),mapped,row.names=FALSE)
    Sys.setenv(DALYCARE_DATE_FORMATS_FILE=mapped)
    frame<-data.frame(patientid=1:10);frame[[case$column]]<-case$values
    DBI::dbWriteTable(connection,ref,frame,overwrite=TRUE,row.names=FALSE)
    info<-data.frame(column_name=case$column,data_type=case$type,udt_name=case$class)
    sql_profile<-dbi_column_profile(connection,quoted,info,'RKKP_CLL',10,'full')
    stream_profile<-dbi_stream_column_profile(connection,quoted,info,'RKKP_CLL',10,'full')$profile
    memory<-profile_column_profiles(frame,'RKKP_CLL')
    memory<-memory[memory$column_name==case$column,]
    for(profile in list(sql_profile,stream_profile))stopifnot(profile$profile_kind=='date',profile$min_date=='2024-01-01',profile$max_date=='2025-01-01',
      profile$min_date==memory$min_date,profile$max_date==memory$max_date,!profile$is_numeric_like)
    profiles<-rbind(profile_column_profiles(frame['patientid'],'RKKP_CLL'),sql_profile)
    coverage<-dbi_coverage_evidence(connection,quoted,profiles,data.frame(table_name='RKKP_CLL',n_rows=10))
    if(case$column=='event_date') {
      stopifnot(identical(coverage_date_column_from_profiles(profiles),'event_date'),
        identical(sort(coverage$group_value[coverage$dimension=='year']),c('2024','2025')),
        all(coverage$release_status[coverage$dimension=='year']=='published'))
    } else {
      # A reviewed format establishes parsing, not clinical event selection.
      temporal<-coverage[coverage$dimension%in%c('year','date_quality','date_format'),]
      stopifnot(is.na(coverage_date_column_from_profiles(profiles)),all(temporal$collection_status=='missing_column'),
        all(is.na(temporal$column_name)),all(is.na(temporal$group_value)),all(is.na(temporal$record_count)))
    }
    Sys.unsetenv('DALYCARE_DATE_FORMATS_FILE');unlink(mapped)
  }
  # Session-local casts must not change timestamptz profile UTC dates. Plain
  # timestamp/date retain their calendar day and do not receive UTC conversion.
  DBI::dbExecute(connection,paste('drop table',quoted))
  DBI::dbExecute(connection,paste('create table',quoted,'(patientid text,event_date timestamptz,local_date date,local_timestamp timestamp)'))
  DBI::dbExecute(connection,paste('insert into',quoted,"select g::text,TIMESTAMPTZ '2024-12-31 23:30:00-02:00',DATE '2024-12-31',TIMESTAMP '2024-12-31 23:30:00' from generate_series(1,10) g"))
  DBI::dbExecute(connection,"SET LOCAL TIME ZONE 'America/New_York'")
  info<-data.frame(column_name=c('event_date','local_date','local_timestamp'),data_type=c('timestamp with time zone','date','timestamp without time zone'),udt_name=c('timestamptz','date','timestamp'))
  utc_day<-as.character(safe_as_date(as.POSIXct('2025-01-01 01:30:00',tz='UTC')))
  typed_profiles<-lapply(seq_len(nrow(info)),function(i) {
    expected<-if(i==1)utc_day else '2024-12-31'
    profile<-dbi_column_profile(connection,quoted,info[i,,drop=FALSE],'RKKP_CLL',10,'full')
    stream<-dbi_stream_column_profile(connection,quoted,info[i,,drop=FALSE],'RKKP_CLL',10,'full')$profile
    stopifnot(profile$min_date==expected,profile$max_date==expected,stream$min_date==expected,stream$max_date==expected)
    profile
  })
  profiles<-rbind(profile_column_profiles(data.frame(patientid=1:10),'RKKP_CLL'),typed_profiles[[1]])
  coverage<-dbi_coverage_evidence(connection,quoted,profiles,data.frame(table_name='RKKP_CLL',n_rows=10))
  stopifnot(identical(coverage$group_value[coverage$dimension=='year'],'2025'))
  DBI::dbExecute(connection,"SET LOCAL TIME ZONE 'UTC'")
  # Typed timestamptz uses UTC day, including a local-day boundary crossing.
  q<-coverage_group_sql(connection,"TIMESTAMPTZ '2024-12-31 23:30:00-02:00'",'year',column_type='timestamp with time zone')
  stopifnot(DBI::dbGetQuery(connection,paste('select',q,'g'))$g=='2025')
  # Exercise the actual DB panel entry; no row-only streamed panel can authorize coverage.
  DBI::dbWriteTable(connection,ref,data,overwrite=TRUE,row.names=FALSE)
  panels<-dbi_panels_from_profiles(profile_column_profiles(data,'RKKP_CLL'),source_row,conn=connection,table_ref=quoted,min_cell_count=5L)
  stopifnot(nrow(panels$coverage_evidence)>0,nrow(panels$atlas_temporal_coverage_years)==2)
  # Actual streamed numeric profile records bounded sample size and full eligible N.
  DBI::dbWriteTable(connection,ref,data.frame(value=as.numeric(1:1000)),overwrite=TRUE,row.names=FALSE)
  Sys.setenv(DALYCARE_ATLAS_QUANTILE_SAMPLE_SIZE='20',DALYCARE_ATLAS_STREAM_CHUNK_SIZE='73',DALYCARE_ATLAS_PROGRESS='FALSE')
  set.seed(173)
  streamed<-dbi_stream_column_profile(connection,quoted,data.frame(column_name='value',data_type='double precision',udt_name='float8'),'synthetic',1000,'full')$profile
  stopifnot(streamed$sample_size==20,streamed$eligible_n==1000,streamed$sampling_method=='algorithm_r_reservoir',streamed$sampling_complete,streamed$mean==500.5)
  Sys.unsetenv(c('DALYCARE_ATLAS_QUANTILE_SAMPLE_SIZE','DALYCARE_ATLAS_STREAM_CHUNK_SIZE','DALYCARE_ATLAS_PROGRESS'))
  dictionary<-load_npu_consensus_dictionary('.')
  codes<-head(dictionary$npu_code[dictionary$consensus_vector=='CREATININE_CODES'],2)
  for(has_codes in c(TRUE,FALSE)) {
    frame<-if(has_codes)data.frame(analysiscode=rep(codes,each=3)) else data.frame(value=1:6)
    DBI::dbWriteTable(connection,ref,frame,overwrite=TRUE,row.names=FALSE)
    info<-data.frame(column_name=names(frame),data_type=if(has_codes)'text' else 'integer',udt_name=if(has_codes)'text' else 'int4')
    bundle<-dbi_stream_column_profiles(connection,quoted,info,'SP_Labs',6,'full')
    panels<-dbi_panels_from_profiles(bundle$column_profiles,data.frame(table_name='SP_Labs',n_rows=6),conn=connection,table_ref=quoted,
      profile_strategy='stream_column',stream_profile_bundle=bundle,npu_dictionary=dictionary)
    if(has_codes)stopifnot(panels$npu_lab_usage_by_vector$n_observed[panels$npu_lab_usage_by_vector$consensus_vector=='CREATININE_CODES']==6,
      nrow(stream_npu_counts_from_bundle(bundle,'analysiscode',6))==0) else stopifnot(nrow(panels$npu_lab_usage_by_vector)==0)
  }
  # Controlled current inventory requires explicit reviewed SP person mapping.
  vital<-data.frame(subject=1:10,displayname=rep(c('Puls','SpO2'),each=5),meas_value='PRIVATE measurement text')
  DBI::dbWriteTable(connection,ref,vital,overwrite=TRUE,row.names=FALSE)
  stopifnot(all(dbi_vital_inventory(connection,quoted,names(vital),'SP_VitaleVaerdier')$vital_descriptor_assessment$inventory_status=='needs_person_key'))
  keyfile<-tempfile(fileext='.csv');write.csv(data.frame(table_name='SP_VitaleVaerdier',person_key='subject',reviewed=TRUE),keyfile,row.names=FALSE)
  Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=keyfile)
  inventory<-dbi_vital_inventory(connection,quoted,names(vital),'SP_VitaleVaerdier')
  stopifnot(identical(sort(inventory$vital_descriptors$descriptor),c('Puls','SpO2')),all(inventory$vital_descriptor_assessment$inventory_status=='assessed_complete'))
  vital$displayname[1]<-'PRIVATE unknown descriptor';DBI::dbWriteTable(connection,ref,vital,overwrite=TRUE,row.names=FALSE)
  inventory<-dbi_vital_inventory(connection,quoted,names(vital),'SP_VitaleVaerdier')
  stopifnot(identical(inventory$vital_descriptors$descriptor,'SpO2'),all(inventory$vital_descriptor_assessment$inventory_status=='partial_withheld'),!any(grepl('PRIVATE',unlist(inventory))))
  vital<-data.frame(subject=1:21,displayname=c(rep('Puls',10),rep('Temp',10),'PRIVATE unknown descriptor'),meas_value='PRIVATE measurement')
  DBI::dbWriteTable(connection,ref,vital,overwrite=TRUE,row.names=FALSE)
  inventory<-dbi_vital_inventory(connection,quoted,names(vital),'SP_VitaleVaerdier')
  stopifnot(identical(sort(inventory$vital_descriptors$descriptor),c('Puls','Temp')),all(inventory$vital_descriptor_assessment$inventory_status=='partial_withheld'))
  Sys.unsetenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE');unlink(keyfile)
  # Finite diagnostic vocabulary: execute the actual SQL, with no raw tokens/IDs.
  probe<-data.frame(patientid=c('SECRET1','SECRET2','SECRET3','SECRET4','SECRET4'),Beh_Immunterapi=c(' true ','FALSE','PRIVATE free text','Y','N'))
  DBI::dbWriteTable(connection,ref,probe,overwrite=TRUE,row.names=FALSE)
  result<-atlas_clinical_probe_query(connection,atlas_encoding_probe_sql(connection,quoted,'patientid','Beh_Immunterapi'))
  stopifnot(result$status=='ok')
  expected<-atlas_encoding_probe_data(probe,'patientid','Beh_Immunterapi')
  actual<-result$groups
  actual<-actual[order(actual$encoding),];expected<-expected[order(expected$encoding),]
  stopifnot(identical(actual$encoding,expected$encoding),identical(as.numeric(actual$n_people),expected$n_people),!any(grepl('SECRET|PRIVATE',unlist(actual))))
  probe$patientid[1]<-NA;DBI::dbWriteTable(connection,ref,probe,overwrite=TRUE,row.names=FALSE)
  missing<-atlas_clinical_probe_query(connection,atlas_encoding_probe_sql(connection,quoted,'patientid','Beh_Immunterapi'))
  stopifnot(any(missing$groups$encoding=='key_missing'),!any(grepl('SECRET|PRIVATE',unlist(missing$groups))))
  cat('PASS PostgreSQL finite encoding diagnostic parity and missing-key handling.\n')
  cat('PASS PostgreSQL D strict dates/mapped formats/Situation casts, overlapping person complements, alias regions, missing keys, actual producer, reservoir stream and controlled vital inventory.\n')

},finally={DBI::dbRollback(connection);DBI::dbDisconnect(connection)})
