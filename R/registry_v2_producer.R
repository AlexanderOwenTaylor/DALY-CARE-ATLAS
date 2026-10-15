empty_registry_field_summaries <- function() registry_v2_frame()
registry_summary_row <- function(spec,status,k) {
  if(is.null(spec$policy_checksum)) {
    fields<-registry_v2_fields('.');s<-Filter(function(s)s$table_name==spec$table_name&&s$source_column==spec$source_column,fields)
    if(length(s))spec<-s[[1]]
  }
  if(status=='field_unavailable')status<-'field_absent'
  registry_v2_frame(list(registry_v2_row(spec,status,k)))
}
registry_summary_number <- function(x) {
  lexical<-!is.na(x)&nchar(x)<=1024&grepl('^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]{1,4})?$',x)
  decimal_range<-vapply(seq_along(x),function(i) {
    if(!lexical[i])return(FALSE)
    v<-tolower(x[i]);mant<-sub('e.*$','',v);digits<-sub('^0+','',gsub('[.-]','',mant))
    if(!nzchar(digits))return(TRUE)
    if(startsWith(v,'-'))return(FALSE)
    exponent<-if(grepl('e',v,fixed=TRUE))as.numeric(sub('^.*e','',v)) else 0
    fraction<-if(grepl('.',mant,fixed=TRUE))nchar(sub('^[^.]*[.]','',mant)) else 0
    power<-exponent+nchar(digits)-fraction-1
    padded<-paste0(digits,strrep('0',1040-nchar(digits)))
    power>= -308&&power<=308&&(power!= -308||padded>=paste0('22250738585072014',strrep('0',1023)))&&(power!=308||padded<=paste0('17976931348623157',strrep('0',1023)))
  },logical(1))
  n<-suppressWarnings(as.numeric(x));n[!decimal_range|!is.finite(n)]<-NA_real_;n
}
registry_v2_canonical_token <- function(v,s) {
  out<-v
  for(m in s$mappings) {
    hit<-!is.na(v)&if(m$normalisation=='exact')v==m$raw_token else chartr('abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ',trimws(v,whitespace='[ ]'))==toupper(trimws(m$raw_token,whitespace='[ ]'))
    out[hit]<-m$canonical_token
  };out
}
registry_v2_group_data <- function(data,key,s) {
  pid<-registry_summary_input_text(data[[key]])
  if(any(is.na(pid)|trimws(pid)==''))return(data.frame(status='key_missing',value='',n=1))
  raw<-registry_summary_input_text(data[[s$source_column]])
  raw_tokens<-raw # Private input lineage; never overwritten with display labels.
  raw[is.na(raw)|grepl('^[ \t\r\n]*$',raw)]<-NA_character_
  canonical_tokens<-if(s$kind=='numeric')trimws(raw,whitespace='[ \t\r\n]') else registry_v2_canonical_token(raw,s)
  allowed<-vapply(s$codes,function(c)c$code,character(1));values<-numeric()
  resolved<-lapply(split(canonical_tokens,pid),function(v) {
    v<-unique(v[!is.na(v)])
    if(!length(v))return(c(status='missing',value=''))
    if(length(v)>1)return(c(status='conflicting',value=''))
    if(s$kind=='categorical')return(if(v %in% allowed)c(status='valid',value=v) else c(status='invalid',value=''))
    n<-registry_summary_number(v)
    if(is.na(n))return(c(status='invalid',value=''))
    if(is.null(s$binding)){values<<-c(values,n);return(c(status='valid',value='unbound'))}
    stored<-n
    b<-s$binding$evidence
    if(b$stored_to_display_multiplier!=1||b$stored_to_display_offset!=0) {
      product<-n*b$stored_to_display_multiplier
      if(!is.finite(product)||abs(b$stored_to_display_offset)>8.988465674311579e307||product>8.988465674311579e307||(n!=0&&product<4.450147717014403e-308))return(c(status='invalid',value=''))
      n<-product+b$stored_to_display_offset
    }
    if(!is.finite(n)||n<0)return(c(status='invalid',value=''))
    bands<-registry_v2_bands(s$binding$policy,0)
    b<-Filter(function(b)n>=b$lower&&(is.null(b$upper)||n<b$upper),bands)
    if(length(b)!=1)return(c(status='invalid',value=''))
    values<<-c(values,stored)
    c(status='valid',value=b[[1]]$id)
  })
  groups<-data.frame(status=character(),value=character(),n=numeric())
  if(length(resolved)) {
    r<-as.data.frame(do.call(rbind,resolved),stringsAsFactors=FALSE)
    groups<-aggregate(list(n=rep(1,nrow(r))),list(status=r$status,value=r$value),sum)
  }
  if(s$kind=='numeric'&&length(values)&&length(unique(values))==1)groups<-rbind(groups,data.frame(status='constant',value='',n=1))
  groups
}
# Private, bounded evidence: one row per reviewed field, fixed resolution classes.
# Never retain group values (including reviewed codes/bands), raw tokens or keys.
empty_registry_interpretation_diagnostics <- function() {
  cols<-c(atlas_registry_privacy_metadata,'policy_checksum','mapping_status','collection_status','encoding_basis','count_basis',registry_v2_counts)
  as.data.frame(setNames(lapply(cols,function(n)if(n %in% registry_v2_counts)numeric() else character()),cols),stringsAsFactors=FALSE)
}
registry_v2_diagnostic <- function(s,row,groups=NULL) {
  d<-s[c(atlas_registry_privacy_metadata,'policy_checksum','mapping_status')]
  d$collection_status<-row$collection_status
  d$encoding_basis<-if(s$kind=='categorical')'reviewed_recorded_codes' else 'strict_numeric_encoding'
  d$count_basis<-'distinct_people_one_unambiguous_value_per_field'
  d[registry_v2_counts]<-as.list(rep(NA_real_,length(registry_v2_counts)))
  if(identical(row$collection_status,'complete')&&is.data.frame(groups)&&nrow(groups)<=5000L&&
     setequal(names(groups),c('status','value','n'))&&!is.logical(groups$n)) {
    n<-suppressWarnings(as.numeric(groups$n))
    if(all(groups$status %in% c('valid','missing','invalid','conflicting','constant'))&&
       all(is.finite(n)&n>=0&n==floor(n)&n<=9007199254740991)) {
      parts<-vapply(c('valid','missing','invalid','conflicting'),function(st)sum(n[groups$status==st]),numeric(1))
      if(sum(parts)<=9007199254740991)d[registry_v2_counts]<-as.list(c(sum(parts),unname(parts)))
    }
  }
  as.data.frame(d,stringsAsFactors=FALSE)
}
registry_v2_with_diagnostics <- function(rows,diagnostics,project_root,k) {
  out<-registry_summary_final_guard(registry_v2_frame(rows),project_root,k)
  attr(out,'registry_interpretation_diagnostics')<-if(length(diagnostics))do.call(rbind,diagnostics) else empty_registry_interpretation_diagnostics()
  out
}
registry_field_summaries <- function(data,table_name,project_root='.',min_cell_count=5) {
  specs<-Filter(function(s)s$table_name==table_name,registry_v2_fields(project_root));k<-registry_summary_k(min_cell_count)
  key<-registry_summary_person_key(table_name,names(data))
  diagnostics<-list()
  rows<-lapply(specs,function(s) {
    groups<-NULL
    row<-if(!s$source_column %in% names(data))registry_v2_row(s,'field_absent',k)
      else if(key$status!='ok')registry_v2_row(s,key$status,k)
      else {groups<-registry_v2_group_data(data,key$key,s);registry_v2_from_groups(s,groups,k)}
    diagnostics[[length(diagnostics)+1L]]<<-registry_v2_diagnostic(s,row,groups)
    row
  });registry_v2_with_diagnostics(rows,diagnostics,project_root,k)
}
registry_summary_from_groups <- function(spec,groups,k) {
  if(is.null(spec$policy_checksum)) {
    s<-Filter(function(s)s$table_name==spec$table_name&&s$source_column==spec$source_column,registry_v2_fields('.'));if(length(s))spec<-s[[1]]
  }
  registry_v2_frame(list(registry_v2_from_groups(spec,groups,k)))
}
registry_summary_sql <- function(conn,table_ref,key,spec,dialect,cap) {
  s<-spec
  if(is.null(s$policy_checksum)) {
    found<-Filter(function(s)s$table_name==spec$table_name&&s$source_column==spec$source_column,registry_v2_fields('.'));if(length(found))s<-found[[1]]
  }
  q<-function(x)as.character(DBI::dbQuoteIdentifier(conn,x));lit<-function(x)as.character(DBI::dbQuoteString(conn,x))
  trim<-function(x)if(dialect=='postgres')paste0('btrim(',x,", E' \\t\\r\\n')") else paste0('trim(',x,", char(9)||char(10)||char(13)||' ')")
  raw<-paste0('CAST(',q(s$source_column),' AS TEXT)')
  if(s$kind=='numeric'&&dialect=='sqlite')raw<-paste0("CASE WHEN typeof(",q(s$source_column),")='real' THEN printf('%!.17g',",q(s$source_column),') ELSE ',raw,' END')
  value<-paste0('CASE WHEN NULLIF(',trim(raw),",'') IS NULL THEN NULL ELSE ",if(s$kind=='numeric')trim(raw) else raw,' END')
  canonical<-'v'
  if(length(s$mappings))canonical<-paste0('CASE ',paste(vapply(s$mappings,function(m)paste0('WHEN ',if(m$normalisation=='exact')'v' else if(dialect=='postgres')"translate(trim(v),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" else 'upper(trim(v))',' = ',lit(if(m$normalisation=='exact')m$raw_token else toupper(trimws(m$raw_token,whitespace='[ ]'))),' THEN ',lit(m$canonical_token)),character(1)),collapse=' '),' ELSE v END')
  pid<-paste0('CASE WHEN NULLIF(',trim(paste0('CAST(',q(key),' AS TEXT)')) ,",'') IS NULL THEN NULL ELSE CAST(",q(key),' AS TEXT) END')
  if(dialect=='sqlite')pid<-paste0("CASE WHEN typeof(",q(key),")='real' THEN printf('%!.17g',",q(key),') ELSE ',pid,' END')
  parse_source<-'per_person';parse_ctes<-''
  if(s$kind=='categorical') {
    codes<-vapply(s$codes,function(c)c$code,character(1));test<-if(length(codes))paste0('v IN (',paste(vapply(codes,lit,character(1)),collapse=','),')') else '1=0';number<-'NULL';band<-'v'
  } else {
    if(dialect=='postgres') {
      parsed<-"CASE WHEN length(v)<=1024 AND v ~ '^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]{1,4})?$' THEN CAST(v AS NUMERIC) ELSE NULL END"
      number<-paste0('CASE WHEN (',parsed,')=0 OR ((',parsed,')>=2.2250738585072014e-308 AND (',parsed,')<=1.7976931348623157e308) THEN CAST((',parsed,') AS DOUBLE PRECISION) ELSE NULL END')
    } else {
      # Exact decimal bounds precede double conversion in all three dialects.
      exponent<-"CASE WHEN instr(lower(v),'e')>0 THEN ltrim(substr(lower(v),instr(lower(v),'e')+1),'+-') ELSE '0' END"
      parse_ctes<-paste0(", numeric_text AS (SELECT d,v,substr(v,1,CASE WHEN instr(lower(v),'e')>0 THEN instr(lower(v),'e')-1 ELSE length(v) END) AS mant,CASE WHEN instr(lower(v),'e')>0 THEN CAST(substr(lower(v),instr(lower(v),'e')+1) AS INTEGER) ELSE 0 END AS exponent FROM per_person), numeric_digits AS (SELECT d,v,mant,exponent,ltrim(replace(replace(mant,'.',''),'-',''),'0') AS digits FROM numeric_text), numeric_range AS (SELECT d,v,digits,exponent+length(digits)-(CASE WHEN instr(mant,'.')>0 THEN length(mant)-instr(mant,'.') ELSE 0 END)-1 AS power FROM numeric_digits)")
      parse_source<-'numeric_range';padded<-paste0("substr(digits||'",strrep('0',1040),"',1,1040)")
      range<-paste0("digits='' OR substr(v,1,1)!='-' AND power BETWEEN -308 AND 308 AND (power!=-308 OR ",padded,">='22250738585072014",strrep('0',1023),"') AND (power!=308 OR ",padded,"<='17976931348623157",strrep('0',1023),"')")
      number<-paste0("CASE WHEN length(v)<=1024 AND length(",exponent,")<=4 AND json_valid(v) THEN CASE WHEN json_type(v) IN ('integer','real') AND (",range,") THEN CAST(v AS REAL) ELSE NULL END ELSE NULL END")
    }
    test<-'num IS NOT NULL';band<-"'unbound'"
    if(!is.null(s$binding)) {
      b<-s$binding$evidence;converted<-'num'
      if(b$stored_to_display_multiplier!=1||b$stored_to_display_offset!=0) {
        multiplier<-sprintf('%.17g',b$stored_to_display_multiplier);offset<-sprintf('%.17g',b$stored_to_display_offset)
        product<-paste0('(num * ',if(dialect=='postgres')paste0('CAST(',multiplier,' AS DOUBLE PRECISION)') else multiplier,')')
        if(dialect=='postgres') {
          # Broad decimal precheck prevents float overflow/underflow exceptions.
          # The common tighter check below determines acceptance on binary64.
          decimal<-paste0('(CAST(CAST(num AS TEXT) AS NUMERIC) * ',multiplier,')')
          product<-paste0('(CASE WHEN num=0 OR ',decimal,' BETWEEN 2.2250738585072014e-308 AND 1.3482698511467367e308 THEN ',product,' ELSE NULL END)')
        }
        converted<-paste0('(CASE WHEN ',if(abs(b$stored_to_display_offset)<=8.988465674311579e307)'1=1' else '1=0',' AND (num=0 OR ',product,'>=4.450147717014403e-308) AND ',product,'<=8.988465674311579e307 THEN ',product,' + ',if(dialect=='postgres')paste0('CAST(',offset,' AS DOUBLE PRECISION)') else offset,' ELSE NULL END)')
      }
      test<-paste0(test,' AND ',converted,'>=0 AND ',converted,'<=1.7976931348623157e308')
      bands<-registry_v2_bands(s$binding$policy,0)
      band<-paste0('CASE ',paste(vapply(bands,function(b)paste0('WHEN ',converted,'>=',sprintf('%.17g',b$lower),if(!is.null(b$upper))paste0(' AND ',converted,'<',sprintf('%.17g',b$upper)) else '', ' THEN ',lit(b$id)),character(1)),collapse=' ')," ELSE '' END")
    }
  }
  paste0('WITH raw AS (SELECT ',pid,' AS pid,',value,' AS v FROM ',table_ref,'), normalized AS (SELECT pid,v AS raw_token,',canonical,' AS v FROM raw), per_person AS (SELECT pid,COUNT(DISTINCT v) AS d,MIN(v) AS v FROM normalized WHERE pid IS NOT NULL GROUP BY pid)',parse_ctes,', parsed AS (SELECT d,v,',number,' AS num FROM ',parse_source,'), resolved AS (SELECT CASE WHEN d=0 THEN \'missing\' WHEN d>1 THEN \'conflicting\' WHEN ',test," THEN 'valid' ELSE 'invalid' END AS status, CASE WHEN d=1 AND (",test,') THEN ',band," ELSE '' END AS value, CASE WHEN d=1 AND (",test,') THEN num ELSE NULL END AS number FROM parsed), grouped AS (SELECT status,value,COUNT(*) AS n FROM resolved GROUP BY status,value UNION ALL SELECT \'key_missing\',\'\',COUNT(*) FROM raw WHERE pid IS NULL HAVING COUNT(*)>0',if(s$kind=='numeric')" UNION ALL SELECT 'constant','',CASE WHEN COUNT(*)>0 THEN 1 ELSE 0 END FROM resolved WHERE status='valid' HAVING COUNT(number)>0 AND MIN(number)=MAX(number)" else '',') SELECT status,value,n FROM grouped ORDER BY status,value LIMIT ',cap+1L)
}
dbi_registry_field_summaries <- function(conn,table_ref,table_name,column_names,project_root='.',min_cell_count=5,budget_context=NULL) {
  specs<-Filter(function(s)s$table_name==table_name,registry_v2_fields(project_root));k<-registry_summary_k(min_cell_count)
  key<-registry_summary_person_key(table_name,column_names);dialect<-registry_summary_db_dialect(conn)
  diagnostics<-list()
  rows<-lapply(specs,function(s) {
    groups<-NULL
    collect<-function() {
    if(!s$source_column %in% column_names)return(registry_v2_row(s,'field_absent',k))
    if(key$status!='ok')return(registry_v2_row(s,key$status,k))
    if(dialect=='unsupported')return(registry_v2_row(s,'query_failed',k))
    if(!is.null(budget_context)&&is.function(budget_context$should_skip)&&budget_context$should_skip('registry_complete_person_groups',atlas_max_text_distinct_rows(),s$source_column))return(registry_v2_row(s,'resource_limit',k))
    start<-proc.time()[['elapsed']]
    query<-registry_summary_query(conn,registry_summary_sql(conn,table_ref,key$key,s,dialect,5000L),dialect)
    row<-if(query$status!='ok')registry_v2_row(s,query$status,k)
      else if(nrow(query$groups)>5000)registry_v2_row(s,'resource_limit',k)
      else {groups<<-query$groups;registry_v2_from_groups(s,groups,k)}
    status<-if(row$collection_status=='complete')'ok' else row$collection_status
    if(!is.null(budget_context)&&is.function(budget_context$add_log))
      budget_context$add_log(s$source_column,'registry_complete_person_groups',status,
        if(status=='ok')'executed' else 'withheld','Complete-field registry aggregate; private values excluded.',
        elapsed_ms=1000*(proc.time()[['elapsed']]-start),strategy='sql_person_aggregate')
    row
    }
    row<-collect()
    diagnostics[[length(diagnostics)+1L]]<<-registry_v2_diagnostic(s,row,groups)
    row
  });registry_v2_with_diagnostics(rows,diagnostics,project_root,k)
}
registry_v2_complete <- function(rows,root='.',k=5) {
  existing<-if(nrow(rows))paste(rows$table_name,rows$source_column,sep='\r') else character()
  missing<-Filter(function(s)!paste(s$table_name,s$source_column,sep='\r') %in% existing,registry_v2_fields(root))
  if(length(missing))rows<-rbind(rows,registry_v2_frame(lapply(missing,function(s)registry_v2_row(s,'source_unavailable',registry_summary_k(k)))))
  rows
}
