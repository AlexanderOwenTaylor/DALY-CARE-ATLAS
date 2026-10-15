# Authority comes from independently collected/current registered column metadata,
# never semantic rows, evidence_filter strings or a self-asserted semantic_id.
atlas_metadata_key <- function(...) as.character(jsonlite::toJSON(list(...),auto_unbox=TRUE))
atlas_metadata_pair <- function(context,source,column) !is.null(context)&&is.environment(context$pairs)&&exists(atlas_metadata_key(source,column),envir=context$pairs,inherits=FALSE)
atlas_metadata_descriptor <- function(context,source,column,value,descriptor) {
  if(is.null(context))return(FALSE)
  key<-atlas_metadata_key(source,column,value,descriptor)
  exists(key,envir=context$definitions,inherits=FALSE)||tolower(trimws(descriptor,whitespace='[ ]')) %in% context$vocabulary
}
atlas_metadata_context <- function(payload=list(),root='.',columns=NULL,sources=NULL) {
  if(is.null(columns))columns<-payload$column_profile_rows
  if(is.data.frame(columns))columns<-lapply(seq_len(nrow(columns)),function(i)as.list(columns[i,,drop=FALSE]))
  valid<-function(x)is.character(x)&&length(x)==1&&!is.na(x)&&nzchar(x)&&nchar(x)<=240&&!grepl('[[:cntrl:]]',x)
  pairs<-new.env(hash=TRUE,parent=emptyenv());definitions<-new.env(hash=TRUE,parent=emptyenv())
  for(row in columns)if(valid(row$table_name)&&valid(row$column_name))assign(atlas_metadata_key(row$table_name,row$column_name),TRUE,envir=pairs)
  paths<-c(file.path(root,'config/metadata-descriptor-definitions.json'),file.path(root,'inst/config/metadata-descriptor-definitions.json'),system.file('config','metadata-descriptor-definitions.json',package='dalycareatlas'))
  paths<-paths[nzchar(paths)&file.exists(paths)]
  resource<-if(length(paths))tryCatch(jsonlite::fromJSON(paths[1],simplifyVector=FALSE),error=function(e)NULL) else NULL
  if(!is.list(resource)||length(resource)!=7||!setequal(names(resource),c('version','normalisation','descriptors','provenance','display_definitions','registry_concepts','panels'))||!identical(resource$version,'metadata-descriptor-definitions-v1')||!identical(resource$normalisation,'lower_trim_ascii_space')||!is.list(resource$descriptors)||!length(resource$descriptors)||!all(vapply(resource$descriptors,valid,logical(1)))||anyDuplicated(unlist(resource$descriptors))||!identical(resource$provenance,list(evidence_tier='local_reviewed_display_vocabulary',definition_source='vital_descriptor_definition',review_version='C2-fix1')))stop('Invalid reviewed descriptor vocabulary',call.=FALSE)
  record_sets<-list(display_definitions=c('descriptor','clinical_variable','semantic_meaning','clinical_concept_id','clinical_group','clinical_subgroup','mapping_confidence'),registry_concepts=c('source_name','raw_column','clinical_concept_id'),panels=c('panel_id','panel_section'))
  for(name in names(record_sets))if(!is.list(resource[[name]])||length(resource[[name]])>1000||!all(vapply(resource[[name]],function(r)is.list(r)&&length(r)==length(record_sets[[name]])&&setequal(names(r),record_sets[[name]])&&all(vapply(r,function(v)is.character(v)&&length(v)==1&&!is.na(v)&&nchar(v)<=2048&&!grepl('[[:cntrl:]]',v),logical(1))),logical(1))))stop('Invalid reviewed metadata display reference',call.=FALSE)
  vocabulary<-unlist(resource$descriptors,use.names=FALSE)
  local<-Sys.getenv('DALYCARE_METADATA_DEFINITIONS_FILE','')
  if(nzchar(local)) {
    reviewed<-tryCatch(if(file.info(local)$size<=1048576)jsonlite::fromJSON(local,simplifyVector=FALSE) else NULL,error=function(e)NULL)
    keys<-c('source_name','raw_column','value_column','raw_descriptor')
    if(!is.list(reviewed)||!identical(reviewed$version,'approved-metadata-definitions-v1')||length(reviewed)!=3||!setequal(names(reviewed),c('version','definitions','provenance'))||!is.list(reviewed$definitions)||length(reviewed$definitions)>10000)stop('Invalid approved metadata definitions',call.=FALSE)
    provenance<-reviewed$provenance
    if(!is.list(provenance)||length(provenance)!=4||!setequal(names(provenance),c('evidence_id','evidence_checksum','evidence_tier','review_status'))||!all(vapply(provenance,valid,logical(1)))||!grepl('^[a-fA-F0-9]{64}$',provenance$evidence_checksum)||provenance$evidence_tier!='reviewed_descriptor_definition'||provenance$review_status!='verified')stop('Invalid approved metadata provenance',call.=FALSE)
    for(row in reviewed$definitions) {
      if(!is.list(row)||!setequal(names(row),keys)||length(row)!=4||!all(vapply(row,valid,logical(1))))stop('Invalid approved metadata definition',call.=FALSE)
      key<-do.call(atlas_metadata_key,unname(row[keys]));if(exists(key,envir=definitions,inherits=FALSE))stop('Duplicate approved metadata definition',call.=FALSE)
      assign(key,TRUE,envir=definitions)
    }
  }
  if(is.null(sources))sources<-payload$sources
  if(is.data.frame(sources))sources<-lapply(seq_len(nrow(sources)),function(i)as.list(sources[i,,drop=FALSE]))
  locations<-new.env(hash=TRUE,parent=emptyenv())
  for(row in sources)if(valid(row$table_name)) {
    key<-atlas_metadata_key(row$table_name)
    if(exists(key,envir=locations,inherits=FALSE))assign(key,NULL,envir=locations) else assign(key,list(table=if(valid(row$table))row$table else NULL,schema=if(valid(row$schema))row$schema else NULL),envir=locations)
  }
  profiles<-new.env(hash=TRUE,parent=emptyenv())
  for(row in columns)if(valid(row$table_name)&&valid(row$column_name))assign(atlas_metadata_key(row$table_name,row$column_name),row,envir=profiles)
  display_path<-file.path(root,'config/clinical-display-dictionary.csv')
  if(!file.exists(display_path))display_path<-system.file('config','clinical-display-dictionary.csv',package='dalycareatlas')
  labels<-if(nzchar(display_path)&&file.exists(display_path))utils::read.csv(display_path,stringsAsFactors=FALSE,check.names=FALSE,fileEncoding='UTF-8') else data.frame(kind=character(),system=character(),code=character(),label=character(),definition=character())
  labels<-labels[labels$kind=='field',,drop=FALSE]
  registry_path<-file.path(root,'inst/config/public-output-registry.json');if(!file.exists(registry_path))registry_path<-system.file('config','public-output-registry.json',package='dalycareatlas')
  registry<-jsonlite::fromJSON(registry_path,simplifyVector=FALSE)
  specs<-Filter(function(s)s$id %in% c('semantic_dictionary','panel_raw_fields'),registry$artifacts)
  schemas<-unlist(lapply(specs,function(s)c(s$schemas,list(s$schemas[[1]][unlist(s$projection)]))),recursive=FALSE)
  list(pairs=pairs,definitions=definitions,vocabulary=vocabulary,reference=resource,profiles=profiles,labels=labels,locations=locations,schemas=schemas)
}
atlas_metadata_schema_cache <- new.env(parent=emptyenv())
atlas_metadata_identity_approved <- function(row,path,root='.',context=NULL) {
  if(!is.list(row)||!length(path)||!atlas_metadata_path(path))return(FALSE)
  schemas<-context$schemas
  if(is.null(schemas))return(FALSE)
  if(!any(vapply(schemas,function(s)length(names(row))==length(s)&&setequal(names(row),names(s)),logical(1))))return(FALSE)
  schema<-Filter(function(s)length(names(row))==length(s)&&setequal(names(row),names(s)),schemas)[[1]]
  if(!all(vapply(names(row),function(k) {v<-row[[k]];is.null(v)||(length(v)==1L&&is.atomic(v)&&(is.na(v)||switch(schema[[k]],string=is.character(v),number=is.numeric(v)&&is.finite(v),boolean=is.logical(v),FALSE)))},logical(1))))return(FALSE)
  text<-function(k)if(is.null(row[[k]])||!length(row[[k]])||is.na(row[[k]]))'' else as.character(row[[k]])
  if(any(vapply(c('n_rows','n_patients','pct_non_missing','min_date','max_date','raw_code','raw_value'),function(k)nzchar(text(k)),logical(1))))return(FALSE)
  if(!all(vapply(c('source_name','raw_column','value_column'),function(k)nzchar(text(k))&&nchar(text(k))<=240&&!grepl('[[:cntrl:]]',text(k)),logical(1)))||text('object_name')!=text('source_name'))return(FALSE)
  if(!atlas_metadata_pair(context,text('source_name'),text('raw_column'))||!atlas_metadata_pair(context,text('source_name'),text('value_column')))return(FALSE)
  descriptor<-text('raw_descriptor');if(nchar(descriptor)>240||grepl('[[:cntrl:]]',descriptor))return(FALSE)
  args<-c(text('source_name'),text('raw_column'),if(nzchar(descriptor))c(text('value_column'),descriptor))
  identity<-paste0('current_',paste(vapply(args,function(x)paste(format(charToRaw(enc2utf8(x))),collapse=''),character(1)),collapse='_'))
  if(text('semantic_id')!=identity)return(FALSE)
  if(nzchar(descriptor)) {
    if(!atlas_metadata_descriptor(context,text('source_name'),text('raw_column'),text('value_column'),descriptor))return(FALSE)
    filter<-paste0('"',gsub('"','""',text('raw_column'),fixed=TRUE),'" = ',"'",gsub("'","''",descriptor,fixed=TRUE),"'")
    return(text('evidence_file')=='current panel: vital_descriptors'&&text('evidence_filter')==filter&&(!'data_shape' %in% names(row)||text('data_shape')=='long_descriptor_table'))
  }
  text('value_column')==text('raw_column')&&text('evidence_file')=='atlas_column_profiles.csv; atlas_sources.csv'&&text('evidence_filter')==paste0('source=',text('source_name'),'; column=',text('raw_column'))&&(!'data_shape' %in% names(row)||text('data_shape')=='current_column_metadata')
}

atlas_metadata_preflight <- function(root='.') {atlas_metadata_context(root=root);invisible(TRUE)}

atlas_metadata_path <- function(path) length(path)&&(tail(path,1) %in% c('semantic_dictionary','semantic_dictionary_rows','panel_raw_fields','panel_raw_field_rows')||identical(path,c('review_clinical_variables','raw_fields')))
atlas_metadata_fallback <- function(row,context) {
  out<-setNames(rep(list(NULL),length(row)),names(row))
  text<-function(k)if(is.character(row[[k]])&&length(row[[k]])==1&&!is.na(row[[k]]))row[[k]] else ''
  if(atlas_metadata_pair(context,text('source_name'),text('raw_column'))) {
    for(key in intersect(c('source_name','raw_column'),names(row)))out[[key]]<-text(key)
    if('object_name' %in% names(row))out$object_name<-text('source_name')
    if('value_column' %in% names(row)&&atlas_metadata_pair(context,text('source_name'),text('value_column')))out$value_column<-text('value_column')
  }
  if('mapping_status' %in% names(row))out$mapping_status<-'definition_withheld'
  if('privacy_note' %in% names(row))out$privacy_note<-'Unapproved definition content withheld; field identity only.'
  out
}

# Only independent reference text may accompany proven identities. Claimed labels,
# notes, filters or encoded IDs never become authority merely by sharing a row.
atlas_metadata_screen <- function(row,context) {
  text<-function(k)if(is.character(row[[k]])&&length(row[[k]])==1&&!is.na(row[[k]]))row[[k]] else ''
  source<-text('source_name');column<-text('raw_column');descriptor<-text('raw_descriptor');value<-text('value_column')
  profile<-context$profiles[[atlas_metadata_key(source,column)]]
  label<-context$labels[context$labels$system==source&context$labels$code==column,,drop=FALSE]
  reviewed<-nrow(label)==1
  display<-Filter(function(d)d$descriptor==tolower(trimws(descriptor,whitespace='[ ]')),context$reference$display_definitions)
  concept<-Filter(function(d)d$source_name==source&&d$raw_column==column,context$reference$registry_concepts)
  expected<-list(clinical_variable=if(nzchar(descriptor))descriptor else if(reviewed)label$label[1] else column,semantic_meaning=if(!nzchar(descriptor)&&reviewed)label$definition[1] else 'Description unavailable',clinical_concept_id=if(!nzchar(descriptor)&&length(concept))concept[[1]]$clinical_concept_id else text('semantic_id'),clinical_group=if(nzchar(descriptor))'Vitals' else if(startsWith(source,'RKKP_'))'Disease Registries' else if(is.null(profile$domain))'Source fields' else profile$domain,clinical_subgroup=if(is.null(profile$subdomain))'Source fields' else profile$subdomain,mapping_confidence=if(reviewed)'reviewed_display_label' else 'unreviewed')
  if(nzchar(descriptor)&&length(display))for(key in setdiff(names(display[[1]]),'descriptor'))expected[[key]]<-display[[1]][[key]]
  expected$mapping_status<-if(nzchar(descriptor)&&text('mapping_status')=='saved_definition_inventory_unassessed')'saved_definition_inventory_unassessed' else if(reviewed||length(display))'reviewed_display_label' else 'description_unavailable'
  expected$privacy_note<-'Schema and reviewed definition metadata only; no observation is asserted.'
  expected$clinical_caveat<-'Stored unit unverified. Definition metadata does not establish current observations.'
  expected$search_terms<-paste(unique(c(source,column,value,descriptor,expected$clinical_variable)),collapse='; ')
  expected$raw_field_label<-paste0(source,'.',column,if(nzchar(descriptor))paste0(' = ',descriptor),' -> ',expected$clinical_variable)
  expected$curator_label_provenance<-if(reviewed||length(display))'Reviewed local metadata definition' else NULL
  expected$value_type<-if(nzchar(descriptor))'numeric' else profile$column_type
  expected$code_system<-if(nzchar(descriptor))'local_SP_descriptor' else ''
  location<-context$locations[[atlas_metadata_key(source)]]
  expected$table_name<-if(!is.null(location$table))location$table else if(identical(text('table_name'),source))source else NULL
  expected$schema_name<-location$schema
  for(key in c('patient_id_column','date_column'))expected[[key]]<-if(atlas_metadata_pair(context,source,text(key)))text(key) else NULL
  panel<-Filter(function(p)p$panel_id==text('panel_id'),context$reference$panels)
  if(length(panel)){expected$panel_id<-panel[[1]]$panel_id;expected$panel_section<-panel[[1]]$panel_section}
  for(key in c('count_scope','denominator_scope','profile_scope'))expected[[key]]<-'source_identity_metadata'
  out<-row;identity<-c('semantic_id','source_name','object_name','raw_column','value_column','raw_descriptor','evidence_file','evidence_filter','data_shape')
  for(key in setdiff(names(row),identity)) {
    v<-row[[key]]
    if(is.null(v)||length(v)==1&&is.na(v)||is.character(v)&&identical(v,''))next
    if(key=='sort_order'&&is.numeric(v)&&length(v)==1&&is.finite(v)&&v>=0&&v<=10000&&v==floor(v))next
    out[key]<-list(expected[[key]])
  }
  out
}
atlas_metadata_only <- function(row,path,root='.',context=NULL) {
  atlas_metadata_identity_approved(row,path,root,context)&&identical(row,atlas_metadata_screen(row,context))
}
