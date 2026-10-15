# Internal readiness and finite encoding diagnostics. No patient values leave SQL.
atlas_encoding_probe_vocabulary <- function() c('missing','conflicting','key_missing','other_nonempty',
  paste0('token:',c('0','1','2','3','4','5','6','7','8','9','99','TRUE','FALSE','Yes','No','Ja','Nej','Y','N','true','false','yes','no','ja','nej','y','n')),
  paste0('trimmed:',c('0','1','TRUE','FALSE','Yes','No','Ja','Nej','Y','N','true','false','yes','no','ja','nej','y','n')))

atlas_encoding_probe_class <- function(v) {
  out<-rep('other_nonempty',length(v));out[is.na(v)|grepl('^[ \t\r\n]*$',v)]<-'missing'
  for(label in atlas_encoding_probe_vocabulary()) {
    if(startsWith(label,'token:'))out[!is.na(v)&v==substring(label,7)]<-label
    if(startsWith(label,'trimmed:'))out[!is.na(v)&v!=trimws(v)&trimws(v)==substring(label,9)]<-label
  };out
}
atlas_encoding_probe_data <- function(data,key,column) {
  pid<-as.character(data[[key]]);v<-as.character(data[[column]])
  if(any(is.na(pid)|trimws(pid)==''))return(data.frame(encoding='key_missing',n_people=NA_real_))
  classes<-vapply(split(v,pid),function(x) {
    x<-unique(x[!is.na(x)&!grepl('^[ \t\r\n]*$',x)])
    if(!length(x))'missing' else if(length(x)>1)'conflicting' else atlas_encoding_probe_class(x)
  },character(1))
  counts<-table(classes);data.frame(encoding=names(counts),n_people=as.numeric(counts))
}
atlas_encoding_probe_sql <- function(conn,ref,key,column) {
  q<-function(x)as.character(DBI::dbQuoteIdentifier(conn,x));lit<-function(x)as.character(DBI::dbQuoteString(conn,x))
  trim<-function(x)paste0('trim(',x,if(registry_summary_db_dialect(conn)=='postgres')", E' \\t\\r\\n'" else ", char(9)||char(10)||char(13)||' '",')')
  cases<-vapply(Filter(function(x)grepl('^(token|trimmed):',x),atlas_encoding_probe_vocabulary()),function(label) {
    exact<-startsWith(label,'token:');token<-substring(label,if(exact)7 else 9)
    paste0('WHEN ',if(exact)'v' else trim('v'),'=',lit(token),' THEN ',lit(label))
  },character(1))
  paste0('WITH raw AS (SELECT CASE WHEN NULLIF(',trim(paste0('CAST(',q(key),' AS TEXT)')),",'') IS NULL THEN NULL ELSE CAST(",q(key),' AS TEXT) END AS pid, CASE WHEN NULLIF(',trim(paste0('CAST(',q(column),' AS TEXT)')),",'') IS NULL THEN NULL ELSE CAST(",q(column),' AS TEXT) END AS v FROM ',ref,
    "), per_person AS (SELECT pid,COUNT(DISTINCT v) AS d,MIN(v) AS v FROM raw WHERE pid IS NOT NULL GROUP BY pid), classified AS (SELECT CASE WHEN d=0 THEN 'missing' WHEN d>1 THEN 'conflicting' ",paste(cases,collapse=' ')," ELSE 'other_nonempty' END AS encoding FROM per_person) SELECT encoding,COUNT(*) AS n_people FROM classified GROUP BY encoding UNION ALL SELECT 'key_missing',NULL FROM raw WHERE pid IS NULL HAVING COUNT(*)>0")
}

atlas_clinical_probe_query <- function(conn,sql,remaining=15) {
  old<-Sys.getenv('DALYCARE_REGISTRY_QUERY_SECONDS',unset=NA_character_)
  on.exit(if(is.na(old))Sys.unsetenv('DALYCARE_REGISTRY_QUERY_SECONDS') else Sys.setenv(DALYCARE_REGISTRY_QUERY_SECONDS=old))
  configured<-suppressWarnings(as.numeric(old));if(!is.finite(configured)||configured<=0)configured<-15
  if(remaining<=0)return(list(status='budget_skipped',groups=NULL))
  Sys.setenv(DALYCARE_REGISTRY_QUERY_SECONDS=as.character(min(15,remaining,configured)))
  registry_summary_query(conn,sql,'postgres')
}

atlas_clinical_configuration_check <- function() {
  flag<-toupper(Sys.getenv('DALYCARE_ATLAS_PREFLIGHT_ONLY','FALSE'))
  if(!flag%in%c('TRUE','FALSE'))stop('DALYCARE_ATLAS_PREFLIGHT_ONLY must be TRUE or FALSE',call.=FALSE)
  path<-Sys.getenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE','')
  if(nzchar(path)) {
    x<-tryCatch(read.csv(path,colClasses='character',check.names=FALSE),error=function(e)NULL)
    if(is.null(x)||!all(c('table_name','person_key','reviewed')%in%names(x))||anyNA(x[c('table_name','reviewed')])||anyDuplicated(x$table_name)||any(!nzchar(x$table_name))||any(!tolower(x$reviewed)%in%c('true','false'))||any(tolower(x$reviewed)=='true'&(is.na(x$person_key)|!nzchar(x$person_key))))stop('Invalid reviewed person-key configuration',call.=FALSE)
  }
  invisible(TRUE)
}

atlas_clinical_readiness <- function(table,schema,root='.') {
  columns<-if(is.data.frame(schema)&&'column_name'%in%names(schema))as.character(schema$column_name) else character()
  rows<-list();add<-function(column,requirement,status,action) {
    rows[[length(rows)+1L]]<<-data.frame(table_name=table,source_column=column,requirement=requirement,status=status,action=action,stringsAsFactors=FALSE)
  }
  key<-registry_summary_person_key(table,columns)
  add(if(is.null(key$key))'' else key$key,'person_key',if(key$status=='ok')'configured' else if(key$status=='missing_person_key')'column_absent' else 'needs_review',
    if(key$status=='ok')'Reviewed mapping found; aggregate key checks still required.' else 'Supply a reviewed source-specific person-key mapping; never use record counts as person counts.')
  add('','person_support','not_checked','Validate missing keys and distinct-person support inside NGC.')
  specs<-Filter(function(s)s$table_name==table,registry_v2_fields(root))
  for(s in specs) {
    status<-if(!s$source_column%in%columns)'field_absent' else if(s$kind=='numeric'&&is.null(s$binding))'needs_unit_evidence' else if(s$kind=='categorical'&&s$mapping_status=='recorded_codes_meaning_unverified')'needs_encoding_review' else 'configured'
    add(s$source_column,'registry_field',status,switch(status,field_absent='Configured field is absent from this schema.',needs_unit_evidence='Provide authoritative stored-unit evidence and a matching approved numeric-band policy.',needs_encoding_review='Review finite encoding diagnostics and the source codebook; do not infer treatment absence.','Configuration found; observed support and privacy checks remain required.'))
  }
  if(table=='SP_VitaleVaerdier')for(value in c('meas_value','meas_value_clean','numericvalue')) {
    add(value,'vital_inventory',if(all(c('displayname',value)%in%columns))if(key$status=='ok')'configured' else 'needs_review' else 'field_absent','Use displayname as the measurement filter with this exact value column; observed units require separate evidence.')
  }
  dates<-columns[grepl('date|dato|_dt$|time|tidspunkt',columns,ignore.case=TRUE)]
  regions<-columns[grepl('region',columns,ignore.case=TRUE)]
  for(dimension in c('event_date','region')) {
    candidates<-if(dimension=='event_date')dates else regions
    add(paste(candidates,collapse=';'),dimension,if(length(candidates))'needs_review' else 'column_absent',
      if(dimension=='event_date')'Candidate schema fields only: document the event and date format before interpreting coverage.' else 'Candidate schema fields only: validate observed region coding; expected remit is not observed coverage.')
  }
  do.call(rbind,rows)
}

atlas_clinical_preflight <- function(source_map,adapter,root,run_dir,probe=FALSE,resolution=NULL) {
  prior<-options(dalycare.registry.project_root=root);on.exit(options(prior),add=TRUE)
  # Resolution for a short preflight must never COUNT entire source tables.
  if(is.null(resolution)) {
    schema_adapter<-adapter
    if(!is.null(schema_adapter))schema_adapter$table_row_count<-function(...)NA_real_
    resolution<-resolve_dalycare_sources(source_map,schema_adapter)
  }
  readiness<-list();diagnostics<-list();drafts<-list();started<-proc.time()[['elapsed']]
  for(i in seq_len(nrow(source_map))) {
    table<-source_map$table_name[i];r<-resolution[resolution$source_index==i,,drop=FALSE];schema<-NULL
    if(nrow(r)==1&&r$resolution_status=='resolved'&&!is.null(adapter)&&is.function(adapter$table_schema))
      schema<-tryCatch(adapter$table_schema(r$db_name,r$schema,r$table),error=function(e)NULL)
    report<-atlas_clinical_readiness(table,schema,root)
    if(is.null(schema)) {
      report$status<-'schema_unavailable';report$action<-'Schema could not be checked; no absence or completeness claim is made.'
    }
    readiness[[i]]<-report
    cols<-if(is.null(schema))character() else schema$column_name
    reviewed_key<-registry_summary_person_key(table,cols)
    candidate<-if(reviewed_key$status=='ok')reviewed_key$key else if('patientid'%in%cols)'patientid' else if('PATIENTID'%in%cols)'PATIENTID' else ''
    drafts[[i]]<-data.frame(table_name=table,person_key=candidate,reviewed=reviewed_key$status=='ok',evidence=if(reviewed_key$status=='ok')'Existing reviewed mapping; schema matched' else 'Unreviewed candidate only; establish source linkage before setting reviewed=TRUE')
    if(!probe||is.null(schema))next
    key<-registry_summary_person_key(table,schema$column_name)
    if(key$status!='ok')next
    conn<-tryCatch(dbi_connection_for(adapter$connections,r$db_name),error=function(e)NULL)
    if(is.null(conn)||registry_summary_db_dialect(conn)!='postgres')next
    ref<-dbi_table_ref(conn,r$schema,r$table)
    specs<-Filter(function(s)s$table_name==table&&s$kind=='categorical'&&s$source_column%in%schema$column_name,registry_v2_fields(root))
    for(s in specs) {
      status<-'budget_skipped';out<-NULL
      if(proc.time()[['elapsed']]-started<120) {
        result<-atlas_clinical_probe_query(conn,atlas_encoding_probe_sql(conn,ref,key$key,s$source_column),120-(proc.time()[['elapsed']]-started))
        status<-result$status;out<-result$groups
      }
      if(status=='ok'&&is.data.frame(out)&&setequal(c('encoding','n_people'),names(out))&&nrow(out)<=length(atlas_encoding_probe_vocabulary())&&all(out$encoding%in%atlas_encoding_probe_vocabulary())&&all((out$encoding=='key_missing'&is.na(out$n_people))|(!is.na(out$n_people)&is.finite(out$n_people)&out$n_people>=0&out$n_people==floor(out$n_people)))) {
        out$table_name<-table;out$source_column<-s$source_column;out$status<-'ok'
      } else out<-data.frame(encoding='',n_people=NA_real_,table_name=table,source_column=s$source_column,status=if(status=='ok')'invalid_contract' else status)
      diagnostics[[length(diagnostics)+1L]]<-out
    }
    if(proc.time()[['elapsed']]-started<120) {
      qkey<-as.character(DBI::dbQuoteIdentifier(conn,key$key))
      # A bounded existence check; neither identifiers nor full row counts are returned.
      result<-atlas_clinical_probe_query(conn,paste0('SELECT EXISTS(SELECT 1 FROM ',ref,' WHERE ',qkey," IS NULL OR btrim(CAST(",qkey," AS TEXT), E' \\t\\r\\n')='') AS missing"),120-(proc.time()[['elapsed']]-started))
      missing<-if(result$status=='ok'&&is.logical(result$groups$missing)&&length(result$groups$missing)==1)result$groups$missing else NA
      ix<-readiness[[i]]$requirement=='person_support'
      readiness[[i]]$status[ix]<-if(is.na(missing))'query_failed' else if(isTRUE(missing))'missing_person_key' else 'keys_nonmissing'
      readiness[[i]]$action[ix]<-'Aggregate key check only; summary-specific support and conflict checks still apply.'
    }
  }
  report<-do.call(rbind,readiness);dir.create(file.path(run_dir,'logs'),recursive=TRUE,showWarnings=FALSE)
  path<-file.path(run_dir,'logs','clinical_readiness.csv');write.csv(report,path,row.names=FALSE,na='',fileEncoding='UTF-8')
  write.csv(do.call(rbind,drafts),file.path(run_dir,'logs','person-keys.review-required.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
  diag<-if(length(diagnostics))do.call(rbind,diagnostics) else data.frame(encoding=character(),n_people=numeric(),table_name=character(),source_column=character(),status=character())
  write.csv(diag,file.path(run_dir,'logs','encoding_diagnostics.csv'),row.names=FALSE,na='',fileEncoding='UTF-8')
  cat('Clinical readiness: ',sum(!report$status%in%c('configured','keys_nonmissing')),' unresolved checks. Internal report: ',path,'\n',sep='')
  list(readiness=report,readiness_file=path,encoding_diagnostics=diag)
}
