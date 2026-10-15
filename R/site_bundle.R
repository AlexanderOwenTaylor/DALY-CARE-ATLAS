# Matched bounded transport and staged publication for R-only installations.
atlas_bundle_json <- function(x) {
  encoded<-as.character(jsonlite::toJSON(x,auto_unbox=TRUE,null='null',na='null',digits=NA))
  # Some jsonlite/R combinations round finite DBL_MAX past the JSON/browser
  # boundary. Repair by encoding the original scalar graph at 17 digits, never
  # by clamping the rounded wire token or relaxing the browser finite check.
  if(grepl('e[+]?308',encoded)) {
    pattern<-'"(?:[^"\\\\]|\\\\.)*"(*SKIP)(*F)|-?[0-9]+(?:[.][0-9]+)?e[+]?308'
    tokens<-regmatches(encoded,gregexpr(pattern,encoded,perl=TRUE))[[1]]
    if(any(!is.finite(suppressWarnings(as.numeric(tokens))))) {
      precise<-function(v){
        if(is.null(v))return('null')
        if(is.list(v)&&identical(class(v),'list')&&all(names(attributes(v))%in%'names')){
          members<-vapply(v,precise,character(1));keys<-names(v)
          if(is.null(keys))return(paste0('[',paste(members,collapse=','),']'))
          if(anyNA(keys)||any(!nzchar(keys))||anyDuplicated(keys))stop('Extreme numeric JSON requires unique record keys',call.=FALSE)
          return(paste0('{',paste(paste0(vapply(keys,function(k)as.character(jsonlite::toJSON(k,auto_unbox=TRUE)),character(1)),':',members),collapse=','),'}'))
        }
        if(is.numeric(v)&&is.null(attributes(v))){
          values<-vapply(v,function(n)if(is.na(n))'null' else if(is.finite(n))sprintf('%.17g',n)else stop('Invalid finite transport number',call.=FALSE),character(1))
          return(if(length(values)==1L)values else paste0('[',paste(values,collapse=','),']'))
        }
        if(is.atomic(v)&&typeof(v)%in%c('character','logical')&&is.null(attributes(v)))return(as.character(jsonlite::toJSON(v,auto_unbox=TRUE,null='null',na='null')))
        stop('Extreme numeric JSON shape unsupported; use scalar records',call.=FALSE)
      }
      encoded<-precise(x)
    }
  }
  encoded
}
atlas_bundle_aliases <- function() c(action_items='action_items',action_summary='action_summary',streaming_summary='review_streaming_summary',temporal_date_quality='review_temporal_date_quality',db_budget_actions='db_budget_actions',db_query_log='db_query_log',catalog='catalog_rows',resource_reconciliation='resource_reconciliation_rows',canonical_resource_reconciliation='canonical_resource_reconciliation_rows',current_run_source_map_audit='current_run_source_map_audit_rows',source_map_crosswalk='source_map_crosswalk_rows',source_resolution_delta='source_resolution_delta_rows',legacy_resource_audit='legacy_cartography_audit_rows',columns='column_profile_rows',column_summary='column_profile_summary',panels='panel_groups',qa='qa_items',run_summary='run_summary')
atlas_transport_version <- function(transport_version=NULL) {
  if(is.null(transport_version)) {
    selected <- Sys.getenv('DALYCARE_ATLAS_TRANSPORT_VERSION',unset='')
    if(identical(selected,'')) return(2L)
    selected <- trimws(selected,whitespace='[\\h\\v]')
  } else selected <- transport_version
  valid <- length(selected)==1L && !is.na(selected) &&
    ((is.character(selected) && selected %in% c('1','2')) ||
     (is.numeric(selected) && is.finite(selected) && selected %in% c(1,2)))
  if(!valid) stop('Invalid atlas transport version',call.=FALSE)
  as.integer(selected)
}
atlas_transport_limit <- function(max_bytes) {
  if(!is.numeric(max_bytes) || length(max_bytes)!=1L || !is.finite(max_bytes) ||
     max_bytes<=0 || max_bytes!=floor(max_bytes)) stop('Invalid transport byte limit',call.=FALSE)
  min(67108864,max_bytes)
}
atlas_transport_record <- function(x) {
  is.list(x) && identical(class(x),'list') &&
    all(names(attributes(x)) %in% 'names') && !is.null(names(x)) &&
    !anyNA(names(x)) && all(nzchar(names(x))) && !anyDuplicated(names(x))
}
atlas_transport_named_list <- function(x) {
  is.list(x) && identical(class(x),'list') &&
    all(names(attributes(x)) %in% 'names') && !is.null(names(x))
}
atlas_transport_wire_keys <- function(x) {
  keys <- names(x)
  missing <- is.na(keys) | !nzchar(keys)
  keys[missing] <- as.character(seq_along(keys))[missing]
  make.unique(keys)
}
atlas_transport_array <- function(x) is.list(x) && is.null(attributes(x))
# Alias deduplication follows the existing serialized v1 wire contract. Inert
# attributes can preserve that contract while making a node ineligible to pack.
atlas_transport_alias_record <- function(x) {
  keys <- names(x)
  if(!is.list(x) || is.null(keys) || anyNA(keys) || any(!nzchar(keys)) || anyDuplicated(keys)) return(FALSE)
  if(atlas_transport_record(x)) return(TRUE)
  # Compare the complete record spelling to prove exact ordered key identities,
  # rather than accepting any attribute-bearing value that merely starts with '{'.
  members <- vapply(seq_along(x),function(i)
    paste0(atlas_bundle_json(keys[[i]]),':',atlas_bundle_json(x[[i]])),character(1))
  identical(atlas_bundle_json(x),paste0('{',paste(members,collapse=','),'}'))
}
atlas_transport_alias_array_json <- function(x) {
  if(!is.list(x) || !is.null(names(x))) return(NULL)
  encoded <- atlas_bundle_json(x)
  if(!startsWith(encoded,'[') || !endsWith(encoded,']')) return(NULL)
  encoded
}
atlas_transport_string_codes <- function(x) {
  codes <- suppressWarnings(utf8ToInt(enc2utf8(x)))
  if(anyNA(codes) || any(codes>=55296L & codes<=57343L)) stop('Invalid transport Unicode',call.=FALSE)
  codes
}
atlas_transport_string_usage <- function(x) {
  codes <- atlas_transport_string_codes(x)
  2+sum(ifelse(codes %in% c(34L,92L,8L,9L,10L,12L,13L),2,
    ifelse(codes<32L,6,ifelse(codes<128L,1,ifelse(codes<2048L,2,ifelse(codes<65536L,3,4))))))
}
# Count an unsupported R subtree's existing wire representation without rebuilding
# or replacing its value graph. This also handles JSON NUL, which R strings lack.
atlas_transport_json_usage <- function(text,max_bytes=67108864,depth=0L,reject_proto=FALSE) {
  limit <- atlas_transport_limit(max_bytes); codes <- atlas_transport_string_codes(text)
  n <- length(codes); pos <- 1L; total <- 0
  add <- function(amount) {
    total <<- total+amount
    if(total>limit) stop('Transport normalized byte budget exceeded',call.=FALSE)
  }
  skip <- function() while(pos<=n && codes[[pos]] %in% c(9L,10L,13L,32L)) pos <<- pos+1L
  take <- function(code) {
    skip()
    if(pos>n || codes[[pos]]!=code) stop('Invalid serialized transport shape',call.=FALSE)
    pos <<- pos+1L
  }
  string <- function(key=FALSE) {
    take(34L); add(2); key_codes <- integer()
    while(pos<=n && codes[[pos]]!=34L) {
      code <- codes[[pos]]; pos <<- pos+1L
      if(code==92L) {
        if(pos>n) stop('Invalid serialized transport string',call.=FALSE)
        escape <- codes[[pos]]; pos <<- pos+1L
        if(escape==117L) {
          hex <- function() {
            if(pos+3L>n) stop('Invalid serialized transport Unicode',call.=FALSE)
            digits <- intToUtf8(codes[pos:(pos+3L)]); pos <<- pos+4L
            if(!grepl('^[0-9a-fA-F]{4}$',digits)) stop('Invalid serialized transport Unicode',call.=FALSE)
            strtoi(digits,16L)
          }
          code <- hex()
          if(code>=55296L && code<=56319L) {
            if(pos+1L>n || codes[[pos]]!=92L || codes[[pos+1L]]!=117L) stop('Invalid transport Unicode',call.=FALSE)
            pos <<- pos+2L; low <- hex()
            if(low<56320L || low>57343L) stop('Invalid transport Unicode',call.=FALSE)
            code <- 65536L+(code-55296L)*1024L+low-56320L
          } else if(code>=56320L && code<=57343L) stop('Invalid transport Unicode',call.=FALSE)
        } else {
          escaped <- c(`34`=34L,`92`=92L,`47`=47L,`98`=8L,`116`=9L,`110`=10L,`102`=12L,`114`=13L)
          code <- escaped[[as.character(escape)]]
          if(is.null(code)) stop('Invalid serialized transport string',call.=FALSE)
        }
      } else if(code<32L) stop('Invalid serialized transport string',call.=FALSE)
      add(if(code %in% c(34L,92L,8L,9L,10L,12L,13L)) 2 else if(code<32L) 6 else
        if(code<128L) 1 else if(code<2048L) 2 else if(code<65536L) 3 else 4)
      if(key && reject_proto) key_codes <- c(key_codes,code)
    }
    take(34L)
    if(key && reject_proto && identical(key_codes,utf8ToInt('__proto__'))) stop('Unsafe classic-script __proto__ property',call.=FALSE)
  }
  value <- function(level) {
    if(level>128L) stop('Transport JSON depth exceeded',call.=FALSE)
    skip()
    if(pos>n) stop('Invalid serialized transport value',call.=FALSE)
    code <- codes[[pos]]
    if(code==34L) return(string())
    if(code %in% c(91L,123L)) {
      object <- code==123L; close <- if(object)125L else 93L
      pos <<- pos+1L;add(2);skip()
      if(pos<=n && codes[[pos]]==close) {pos <<- pos+1L;return(invisible(NULL))}
      repeat {
        if(object) {string(TRUE);take(58L);add(1)}
        value(level+1L);skip()
        if(pos<=n && codes[[pos]]==close) {pos <<- pos+1L;break}
        take(44L);add(1)
      }
      return(invisible(NULL))
    }
    start <- pos
    while(pos<=n && !codes[[pos]] %in% c(9L,10L,13L,32L,44L,93L,125L)) pos <<- pos+1L
    token <- intToUtf8(codes[start:(pos-1L)])
    if(token %in% c('null','true','false')) add(if(token=='false')5 else 4) else {
      if(!grepl('^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?$',token) ||
         !is.finite(suppressWarnings(as.numeric(token)))) stop('Invalid finite transport number',call.=FALSE)
      add(32)
    }
  }
  value(depth);skip()
  if(pos<=n) stop('Invalid serialized transport suffix',call.=FALSE)
  total
}
atlas_transport_usage <- function(x,max_bytes=67108864,reject_proto=FALSE) {
  limit <- atlas_transport_limit(max_bytes); total <- 0
  add <- function(amount) {
    total <<- total+amount
    if(total>limit) stop('Transport normalized byte budget exceeded',call.=FALSE)
  }
  walk <- function(value,depth) {
    if(depth>128L) stop('Transport JSON depth exceeded',call.=FALSE)
    if(is.null(value)) {add(4);return(invisible(NULL))}
    if(is.numeric(value) && (any(is.nan(value)) || any(!is.na(value) & !is.finite(value)))) stop('Invalid finite transport number',call.=FALSE)
    if(is.character(value)) for(s in value[!is.na(value)]) atlas_transport_string_codes(s)
    record <- atlas_transport_named_list(value); array <- atlas_transport_array(value)
    if(record || array) {
      add(2+max(0,length(value)-1L))
      keys <- if(record) atlas_transport_wire_keys(value) else NULL
      for(i in seq_along(value)) {
        if(record) {
          key <- keys[[i]]
          if(reject_proto && identical(key,'__proto__')) stop('Unsafe classic-script __proto__ property',call.=FALSE)
          add(atlas_transport_string_usage(key)+1)
        }
        walk(value[[i]],depth+1L)
      }
    } else if(is.atomic(value) && is.null(attributes(value)) && length(value)==1L &&
              typeof(value) %in% c('character','logical','integer','double')) {
      if(is.na(value)) add(4) else if(is.character(value)) add(atlas_transport_string_usage(value)) else
        if(is.logical(value)) add(if(value)4 else 5) else add(32)
    } else {
      if(is.environment(value) || is.function(value) || is.language(value) || isS4(value)) stop('Invalid transport R shape',call.=FALSE)
      add(atlas_transport_json_usage(atlas_bundle_json(value),limit-total,depth,reject_proto))
    }
    invisible(NULL)
  }
  walk(x,0L);total
}
atlas_transport_scalar <- function(x) {
  is.null(x) || (is.atomic(x) && is.null(attributes(x)) && length(x)==1L && !is.na(x) &&
    (is.character(x) || is.logical(x) || (is.numeric(x) && is.finite(x))))
}
atlas_transport_pack <- function(payload,limits=list(tables=4096L,path_depth=16L,schemas_per_table=64L,
  keys_per_schema=64L,key_utf8_bytes=128L,rows=100000L,cells=1000000L)) {
  descriptors <- list(); packed_rows <- packed_cells <- 0
  safe_component <- function(key) nzchar(key) && !key %in% c('__proto__','constructor','prototype') &&
    nchar(enc2utf8(key),type='bytes')<=limits$key_utf8_bytes
  candidate <- function(rows,path) {
    if(!atlas_transport_array(rows) || length(rows)<2L || !length(path) ||
       length(path)>limits$path_depth || !all(vapply(path,safe_component,logical(1))) ||
       length(descriptors)>=limits$tables || length(rows)+packed_rows>limits$rows) return(NULL)
    schemas <- packed <- list();cells <- 0
    for(i in seq_along(rows)) {
      row <- rows[[i]]; keys <- names(row)
      if(!atlas_transport_record(row) || !length(row) || length(row)>limits$keys_per_schema ||
         !all(vapply(keys,safe_component,logical(1))) || !all(vapply(row,atlas_transport_scalar,logical(1)))) return(NULL)
      cells <- cells+length(row)
      if(cells+packed_cells>limits$cells) return(NULL)
      keys <- as.list(keys)
      index <- which(vapply(schemas,identical,logical(1),keys))
      if(!length(index)) {
        if(length(schemas)>=limits$schemas_per_table) return(NULL)
        schemas[[length(schemas)+1L]] <- keys;index <- length(schemas)
      }
      packed[[i]] <- c(list(as.integer(index-1L)),unname(row))
    }
    descriptor <- list(path=path,schemas=schemas,rows=packed)
    # Replacing the array costs null (4), the descriptor, and one array separator.
    before <- nchar(enc2utf8(atlas_bundle_json(rows)),type='bytes')
    after <- 4+nchar(enc2utf8(atlas_bundle_json(descriptor)),type='bytes')+as.integer(length(descriptors)>0L)
    if(after>=before) return(NULL)
    list(descriptor=descriptor,cells=cells)
  }
  visit <- function(node,path=list()) {
    if(!atlas_transport_record(node)) return(node)
    for(key in names(node)) {
      next_path <- c(path,list(key)); value <- node[[key]]
      selected <- candidate(value,next_path)
      if(!is.null(selected)) {
        descriptors[[length(descriptors)+1L]] <<- selected$descriptor
        packed_rows <<- packed_rows+length(value);packed_cells <<- packed_cells+selected$cells
        node[key] <- list(NULL)
      } else if(atlas_transport_record(value)) node[key] <- list(visit(value,next_path))
    }
    node
  }
  list(payload=visit(payload),row_tables=descriptors)
}
atlas_payload_transport <- function(payload,transport_version=2L,max_bytes=67108864) {
  if(!is.numeric(transport_version) || length(transport_version)!=1L || !is.finite(transport_version) ||
     !transport_version %in% c(1,2)) stop('Invalid transport protocol version',call.=FALSE)
  max_bytes <- atlas_transport_limit(max_bytes)
  if(!is.list(payload) || is.data.frame(payload) || is.null(names(payload)))
    stop('Transport payload must be a named record',call.=FALSE)
  aliases <- list(); pairs <- atlas_bundle_aliases()
  review <- payload[['review_infrastructure_sections']]
  alias_parents <- atlas_transport_alias_record(payload) && atlas_transport_alias_record(review)
  for(target in names(pairs)) {
    if(!alias_parents) break
    review <- payload[['review_infrastructure_sections']]
    source <- pairs[[target]]; a <- review[[target]]; b <- payload[[source]]
    a_json <- atlas_transport_alias_array_json(a);b_json <- atlas_transport_alias_array_json(b)
    if(!is.null(a_json) && !is.null(b_json) && identical(a_json,b_json)) {
      payload$review_infrastructure_sections[target] <- NULL
      aliases[[length(aliases)+1L]] <- list(target=list('review_infrastructure_sections',target),source=list(source))
    }
  }
  # Expanded accounting precedes alias restoration; repeated aliases are excluded.
  atlas_transport_usage(payload,max_bytes)
  transport <- list(transport_version=as.integer(transport_version),payload=payload,aliases=aliases)
  if(transport_version==2L) {
    packed <- atlas_transport_pack(payload)
    transport$payload <- packed$payload;transport$row_tables <- packed$row_tables
  }
  atlas_transport_usage(transport,max_bytes)
  transport
}
atlas_transport_assets <- function(transport,max_bytes) {
  max_bytes <- atlas_transport_limit(max_bytes)
  # JSON object literals reinterpret __proto__, even though JSON.parse preserves it.
  atlas_transport_usage(transport,max_bytes,reject_proto=TRUE)
  encoded <- atlas_bundle_json(transport)
  assets <- list(script=paste0('window.DALYCARE_ATLAS_PAYLOAD = ',encoded,';\n'),json=paste0(encoded,'\n'))
  if(any(vapply(assets,function(text)nchar(enc2utf8(text),type='bytes')>max_bytes,logical(1))))
    stop('Transport emitted-file byte budget exceeded',call.=FALSE)
  assets
}
atlas_bundle_resource <- function(name,project_root) {
  path <- file.path(project_root,'inst/templates',name)
  if(!file.exists(path)) path <- system.file('templates',name,package='dalycareatlas')
  if(!nzchar(path) || !file.exists(path)) stop('Site resource unavailable: ',name,call.=FALSE)
  path
}
atlas_bundle_field_labels <- function(dictionary) {
  labels <- list()
  for(row in dictionary) {
    if(!is.list(row) || !identical(row[['kind']],'field')) next
    values <- lapply(c('system','code','label'),function(key)row[[key]])
    valid <- vapply(values,function(v)is.character(v) && length(v)==1L && !is.na(v) && nzchar(trimws(v,whitespace='[\\h\\v]')),logical(1))
    if(!all(valid)) stop('Invalid field label dictionary row',call.=FALSE)
    source <- values[[1]];field <- values[[2]];label <- values[[3]]
    if(source %in% c('__proto__','constructor','prototype') || field %in% c('__proto__','constructor','prototype')) stop('Unsafe field label dictionary key',call.=FALSE)
    fields <- labels[[source]]
    if(field %in% names(fields) && !identical(fields[[field]],label)) stop('Conflicting field label dictionary pair',call.=FALSE)
    if(is.null(fields)) fields <- list()
    fields[[field]] <- label;labels[[source]] <- fields
  }
  labels
}
atlas_bundle_vital_profiles <- function(profiles) {
  # Only project already guarded rows; retain duplicates for ambiguity detection.
  event_fields <- c('displayname','numericvalue','recorded_time','meas_value','meas_value_clean','val_type_c','val_type_name','isaccepted_yn','template_name','date_received','datetime_created')
  dedicated <- list(SP_PatientInfo=c('bmi','weight_in_kg','height_in_cm'),RKKP_DaMyDa=c('Reg_Hoejde','Reg_Vaegt'))
  identity <- c('table_name','column_name','column_type','column_class')
  summary <- c('n_rows','n_available','pct_available','mean','median','p25','p75','numeric_privacy_status','availability_privacy_status','summary_scope','summary_method','is_sensitive')
  selected <- list()
  for(row in profiles) {
    if(!is.list(row)) next
    table <- row[['table_name']];field <- row[['column_name']]
    if(!is.character(table) || length(table)!=1L || is.na(table) || !is.character(field) || length(field)!=1L || is.na(field)) next
    if(identical(table,'SP_VitaleVaerdier') && field %in% event_fields) keys <- identity
    else if(field %in% dedicated[[table]]) keys <- c(identity,summary)
    else next
    selected[[length(selected)+1L]] <- setNames(lapply(keys,function(key)row[[key]]),keys)
  }
  selected
}
# Check every existing ancestor before creating anything. Sys.readlink returns NA
# for ordinary/missing paths on some platforms; only a known nonempty target is a link.
atlas_site_destination <- function(site_dir) {
  if(!is.character(site_dir) || length(site_dir)!=1L || is.na(site_dir) || !nzchar(site_dir))
    stop('Unsafe site destination',call.=FALSE)
  path <- gsub('\\\\','/',path.expand(site_dir))
  if(basename(path) %in% c('','.','..') || grepl('(^|/)\\.\\.(/|$)',path)) stop('Unsafe site destination',call.=FALSE)
  if(!grepl('^/|^[A-Za-z]:/',path)) path <- file.path(getwd(),path)
  path <- gsub('/\\./','/',path)
  path <- sub('/+$','',path)
  ancestor <- path
  repeat {
    link <- suppressWarnings(Sys.readlink(ancestor))
    if(any(!is.na(link) & nzchar(link))) stop('Unsafe linked site destination',call.=FALSE)
    if(dir.exists(ancestor)) {
      canonical <- normalizePath(ancestor,winslash='/',mustWork=TRUE)
      expected <- ancestor
      if(.Platform$OS.type=='windows') {canonical <- tolower(canonical);expected <- tolower(expected)}
      if(!identical(sub('/+$','',canonical),sub('/+$','',expected))) stop('Unsafe linked site destination',call.=FALSE)
    } else if(file.exists(ancestor)) stop('Unsafe file destination',call.=FALSE)
    parent <- dirname(ancestor)
    if(identical(parent,ancestor)) break
    ancestor <- parent
  }
  parent <- dirname(path)
  if(!dir.exists(parent) && !dir.create(parent,recursive=TRUE,showWarnings=FALSE)) stop('Site parent is not writable',call.=FALSE)
  probe <- tempfile('.atlas-write-check-',tmpdir=parent)
  on.exit(if(dir.exists(probe)) unlink(probe,recursive=TRUE),add=TRUE)
  if(!dir.create(probe,showWarnings=FALSE) ||
     !isTRUE(suppressWarnings(file.create(file.path(probe,'probe'))))) stop('Site parent is not writable',call.=FALSE)
  file.path(normalizePath(parent,winslash='/',mustWork=TRUE),basename(path))
}

atlas_write_site_bundle <- function(site_dir,payload,tables,project_root='.',provenance='legacy_payload',manifest_paths=list(),membership_spec=NULL,transport_version=NULL) {
  if(!exists('atlas_public_manifest',mode='function'))source(file.path(project_root,'R/publication.R'),local=TRUE)
  output <- atlas_site_destination(site_dir)
  transport_version <- atlas_transport_version(transport_version)
  if(is.null(membership_spec)) membership_spec <- load_clinical_source_membership(project_root)
  membership_path <- clinical_source_membership_path(project_root)
  if(!is.null(payload$clinical_source_inventory) && !identical(payload$clinical_source_inventory$inventory_version,membership_spec$inventory_version)) stop('Clinical-source inventory version differs from required resource.',call.=FALSE)
  manifest_paths <- manifest_paths[!vapply(manifest_paths,function(path)identical(normalizePath(path,winslash='/',mustWork=FALSE),membership_path),logical(1))]
  manifest_paths$clinical_source_membership <- membership_path
  registry <- atlas_output_registry(project_root); minimum <- atlas_effective_threshold(payload)
  atlas_transport_usage(payload,atlas_transport_limit(registry$input_max_bytes),reject_proto=TRUE)
  if(!exists('atlas_public_privacy',mode='function')) source(file.path(project_root,'R/public_privacy.R'),encoding='UTF-8')
  if(!provenance %in% c('csv_outputs','legacy_payload')) stop('Invalid entry provenance',call.=FALSE)
  logical <- payload; ids <- vapply(registry$artifacts,function(s)s$id,character(1))
  for(table in tables) {
    index <- match(table$id,ids); if(is.na(index)) next
    spec <- registry$artifacts[[index]]
    if(length(spec$payload_path) && length(spec$projection)) logical <- atlas_evidence_set(logical,unlist(spec$payload_path),table$rows)
  }
  if(!exists('atlas_metadata_context',mode='function'))source(file.path(project_root,'R/metadata_privacy.R'),local=TRUE)
  metadata_context<-atlas_metadata_context(logical,project_root)
  safe <- atlas_public_privacy(logical,project_root,minimum,metadata_context)
  atlas_evidence_audit(safe,project_root,minimum,metadata_context)
  build_id <- paste(sample(c(0:9,letters[1:6]),32,replace=TRUE),collapse='')
  synthetic<-identical(Sys.getenv('DALYCARE_SYNTHETIC_VALIDATION'),'TRUE')||startsWith(payload$run_id %||% '','SYNTHETIC')
  bootstrap <- list(synthetic_validation=synthetic,export_contract='dalycare-lazy-v1',build_id=build_id,run_id=payload$run_id %||% '',privacy_metadata=safe$privacy_metadata,directory='DALYCARE_directory.js',search='DALYCARE_search.js')
  transport <- atlas_payload_transport(bootstrap,transport_version,max_bytes=atlas_transport_limit(registry$input_max_bytes))
  transport_assets <- atlas_transport_assets(transport,registry$input_max_bytes)
  parent <- dirname(output)
  stage <- tempfile(paste0('.',basename(output),'-stage-'),tmpdir=parent)
  if(!dir.create(stage,showWarnings=FALSE)) stop('Cannot create site staging directory',call.=FALSE)
  stage <- normalizePath(stage,winslash='/',mustWork=TRUE)
  backup <- paste0(output,'-previous-',build_id)
  manifest <- atlas_confined_path(parent,'outputs/output_manifest.csv')
  dir.create(dirname(manifest),recursive=TRUE,showWarnings=FALSE)
  manifest <- atlas_confined_path(parent,'outputs/output_manifest.csv')
  manifest_stage <- file.path(parent,paste0('.',basename(output),'-manifest-stage-',build_id,'.csv'))
  manifest_backup <- paste0(manifest,'-previous-',build_id)
  on.exit({if(dir.exists(stage)) unlink(stage,recursive=TRUE);if(file.exists(manifest_stage)) unlink(manifest_stage)},add=TRUE)
  write <- function(name,text) {
    if(startsWith(name,'table-descriptors/')&&nchar(enc2utf8(text),type='bytes')>262144)stop('Descriptor byte budget exceeded',call.=FALSE)
    path <- atlas_confined_path(stage,name)
    con <- file(path,'wb');on.exit(close(con));writeBin(charToRaw(enc2utf8(text)),con)
  }
  resources <- c(DALYCARE_atlas.html='DALYCARE_entry.html',DALYCARE_clinical.html='DALYCARE_lazy.html',DALYCARE_outputs.html='DALYCARE_lazy.html',`atlas-entry.js`='atlas-entry.js',`atlas-outputs.js`='atlas-outputs.js',`atlas-transport.js`='atlas-transport.js',`atlas-pages.css`='atlas-pages.css',`atlas-vitals.js`='atlas-vitals.js',`atlas-vitals.css`='atlas-vitals.css')
  lazy_resources<-c('atlas-reader.js','atlas-shell.js','atlas-shell.css','atlas-topic.js','atlas-topic.css','atlas-route-registries.js','atlas-route-vitals.js','atlas-route-laboratory.js','atlas-route-treatment.js','atlas-route-situation.js','atlas-route-feasibility.js','atlas-route-infrastructure.js','atlas-route-variables.js','atlas-route-ehr.js','atlas-route-timeplace.js','atlas-route-sources.js','favicon.svg','THIRD_PARTY_NOTICES.txt','OPERATING.txt')
  resources<-c(resources,setNames(lazy_resources,lazy_resources))
  for(name in names(resources)) if(!file.copy(atlas_bundle_resource(resources[[name]],project_root),file.path(stage,name))) stop('Resource copy failed',call.=FALSE)
  write('registry-v2.js',paste0('window.DALYCARE_REGISTRY_BUILD_ID = ',atlas_bundle_json(build_id),';\nwindow.DALYCARE_REGISTRY_V2_RESOURCE = ',atlas_bundle_json(registry_v2_public_resource(project_root)),';\n',paste(readLines(atlas_bundle_resource('registry-v2.js',project_root),warn=FALSE,encoding='UTF-8'),collapse='\n')))
  write('DALYCARE_atlas_payload.js',transport_assets$script)
  write('DALYCARE_atlas_payload.json',transport_assets$json)
  write('DALYCARE_entry.js',paste0('window.DALYCARE_ENTRY = ',atlas_bundle_json(list(synthetic_validation=synthetic,schema_version=1L,build_id=build_id,run_id=payload$run_id %||% '',provenance=provenance)),';\n'))
  dir.create(file.path(stage,'output-shards'));dir.create(file.path(stage,'table-descriptors'));dir.create(file.path(stage,'downloads'));canonical<-list()
  registration <- function(table_id,shard_id,rows) {
    data <- paste0('[',paste(unlist(rows,use.names=FALSE),collapse=','),']')
    script <- paste0('window.DALYCARE_OUTPUTS.register(',atlas_bundle_json(list(schema_version=1L,build_id=build_id,table_id=table_id,shard_id=shard_id,rows_json=data)),');\n')
    list(data=data,script=script,bytes=nchar(enc2utf8(data),type='bytes'))
  }
  fits <- function(x) x$bytes<=262144 && nchar(enc2utf8(x$script),type='bytes')<=262144
  catalog_tables <- list();total <- 0;seen <- character()
  privacy <- c('value_privacy_status','count_privacy_status','date_privacy_status','availability_privacy_status','numeric_privacy_status','summary_scope','summary_method','is_sensitive')
  for(table in tables) {
    id <- table$id;table$title<-table$title %||% id
    if(!grepl('^[A-Za-z0-9_-]+$',id) || id %in% seen) stop('Invalid table identity',call.=FALSE)
    seen <- c(seen,id); index <- match(id,ids); spec <- if(!is.na(index)) registry$artifacts[[index]] else NULL
    rows <- if(length(spec$projection) && length(spec$payload_path)) atlas_evidence_get(safe,unlist(spec$payload_path)) else list()
    keys <- vapply(table$columns,function(c)c$key,character(1))
    if(!identical(id,'registry_field_summaries'))for(key in sort(setdiff(intersect(privacy,unique(unlist(lapply(rows,names)))),keys))){table$columns[[length(table$columns)+1L]]<-list(key=key,label=key,type=if(key=='is_sensitive')'boolean' else 'string');keys<-c(keys,key)}
    if(any(!keys %in% c(unlist(spec$projection),if(!is.null(spec)) privacy)) || (is.null(spec) && (length(keys) || nzchar(table$source_file)))) stop('Unreviewed public schema',call.=FALSE)
    if(!identical(id,'registry_field_summaries')) rows <- lapply(rows,function(r)setNames(lapply(keys,function(k)r[[k]]),keys))
    table$rows <- NULL;table$shards <- list()
    if(identical(table$status,'snapshot_preview')) table$status <- 'limited'
    parts <- list();pending <- list();pending_bytes <- 2
    pending_script_bytes <- nchar(enc2utf8(registration(id,'s0001',list())$script),type='bytes')
    shard_target<-if(id=='semantic_dictionary')131072 else 262144
    shard_row_limit<-if(id=='registry_field_summaries')50L else if(id=='column_profiles')100L else 250L
    for(row in rows) {
      for(column in table$columns) {
        v <- row[[column$key]]
        valid <- is.null(v) || (length(v)==1 && switch(column$type,string=is.character(v),boolean=is.logical(v),number=is.numeric(v) && is.finite(v),FALSE))
        if(!valid) stop('Typed evidence mismatch: ',id,call.=FALSE)
      }
      serialized <- atlas_bundle_json(row)
      # String escaping is additive across serialized row fragments. Count each
      # fragment once, plus the array's brackets and separators, rather than
      # serializing every growing pending shard again for its byte limits.
      row_bytes <- nchar(enc2utf8(serialized),type='bytes')
      escaped_bytes <- nchar(enc2utf8(atlas_bundle_json(serialized)),type='bytes')-2
      separator <- as.integer(length(pending)>0L)
      if(length(pending)>=shard_row_limit || pending_bytes+separator+row_bytes>shard_target ||
         pending_script_bytes+separator+escaped_bytes>shard_target) {
        if(length(pending)) parts[[length(parts)+1L]] <- pending
        pending <- list();pending_bytes <- 2;separator <- 0L
        pending_script_bytes <- nchar(enc2utf8(registration(id,sprintf('s%04d',length(parts)+1L),list())$script),type='bytes')
        if(pending_bytes+row_bytes>262144 || pending_script_bytes+escaped_bytes>262144) {
          if(isTRUE(spec$required)) stop('Required table row exceeds shard limit',call.=FALSE)
          parts <- list();rows <- list();table$status <- 'unavailable';table$reason <- 'Row exceeds public shard byte limit';table$complete <- FALSE;break
        }
      }
      pending[[length(pending)+1L]] <- serialized
      pending_bytes <- pending_bytes+separator+row_bytes
      pending_script_bytes <- pending_script_bytes+separator+escaped_bytes
    }
    if(length(pending)) parts[[length(parts)+1L]] <- pending
    canonical[[id]]<-rows
    atlas_public_csv(file.path(stage,'downloads',paste0(id,'.csv')),keys,rows)
    table$represented_row_count <- length(rows)
    for(i in seq_along(parts)) {
      shard_id <- sprintf('s%04d',i);item <- registration(id,shard_id,parts[[i]])
      if(!fits(item)) stop('Table shard exceeds byte limit',call.=FALSE)
      relative <- paste0('output-shards/',id,'-',shard_id,'.js');write(relative,item$script)
      total <- total+item$bytes
      table$shards[[i]] <- list(id=shard_id,src=relative,rows=length(parts[[i]]),bytes=item$bytes,asset_bytes=nchar(enc2utf8(item$script),type='bytes'))
      if(id%in%c('column_profiles','registry_field_summaries','semantic_dictionary'))table$shards[[i]]$fields<-lapply(jsonlite::fromJSON(item$data,simplifyVector=FALSE),function(r)list(r[[if(id=='semantic_dictionary')'source_name' else 'table_name']],r[[if(id=='semantic_dictionary')'raw_column' else if(id=='column_profiles')'column_name' else 'source_column']]))
    }
    catalog_tables[[length(catalog_tables)+1L]] <- table
    write(paste0('table-descriptors/',id,'.js'),paste0('window.DALYCARE_OUTPUTS.registerDescriptor(',atlas_bundle_json(list(schema_version=1L,build_id=build_id,table=table)),');\n'))
  }
  if(total>registry$public_table_max_bytes) stop('Public table-data budget exceeded',call.=FALSE)
  limits <- list(input_max_bytes=registry$input_max_bytes,public_table_max_bytes=registry$public_table_max_bytes,shard_max_rows=250L,shard_max_bytes=262144L,cache_max_bytes=1048576L,page_rows=50L,minimum_cell_count=minimum,public_table_bytes=total)
  catalogue <- list(schema_version=1L,build_id=build_id,run_id=payload$run_id %||% '',provenance=provenance,privacy_policy_version=payload$privacy_metadata$policy_version,minimum_cell_count=minimum,limits=limits,tables=catalog_tables)
  write('DALYCARE_output_catalogue.js',paste0('window.DALYCARE_OUTPUT_CATALOGUE = ',atlas_bundle_json(catalogue),';\n'))
  directory<-list(synthetic_validation=synthetic,schema_version=2L,build_id=build_id,run_id=payload$run_id %||% '',minimum_cell_count=minimum,tables=lapply(catalog_tables,function(t)c(t[intersect(c('id','title','status','represented_row_count'),names(t))],list(descriptor=paste0('table-descriptors/',t$id,'.js')))))
  source_identity<-canonical$sources;if(!length(source_identity))source_identity<-safe$catalog_rows
  directory$sources<-lapply(Filter(function(r)is.list(r)&&is.character(r$table_name)&&length(r$table_name)==1L,source_identity),function(r)setNames(lapply(c('table_name','load_status','domain','subdomain'),function(k)r[[k]]),c('table_name','load_status','domain','subdomain')))
  write('DALYCARE_membership.js',paste0('window.DALYCARE_MEMBERSHIP = ',atlas_bundle_json(list(build_id=build_id,inventory=safe$clinical_source_inventory)),';\n'))
  reference<-atlas_reference_search(write,build_id,canonical,catalog_tables)
  if(!is.null(reference)){directory$tables[[length(directory$tables)+1L]]<-reference$directory;atlas_public_csv(file.path(stage,'downloads/npu_reference_search.csv'),vapply(reference$table$columns,function(c)c$key,character(1)),reference$rows)}
  write('DALYCARE_directory.js',paste0('window.DALYCARE_DIRECTORY = ',atlas_bundle_json(directory),';\n'))
  labels<-atlas_bundle_field_labels(canonical$clinical_display_dictionary);sources<-character();fields<-list();identities<-new.env(hash=TRUE,parent=emptyenv())
  for(row in canonical$column_profiles){source<-row$table_name;field<-row$column_name;if(!is.character(source)||!is.character(field))next
    key<-atlas_bundle_json(list(source,field));if(exists(key,envir=identities,inherits=FALSE))next;assign(key,TRUE,envir=identities)
    if(!source%in%sources)sources<-c(sources,source)
    fields[[length(fields)+1L]]<-list(match(source,sources)-1L,field,labels[[source]][[field]] %||% '')}
  write('DALYCARE_search.js',paste0('window.DALYCARE_SEARCH = ',atlas_bundle_json(list(schema_version=1L,build_id=build_id,sources=as.list(sources),fields=fields)),';\n'))
  for(names in list(c('DALYCARE_atlas.html','DALYCARE_entry.js','atlas-entry.js','atlas-pages.css'),c('DALYCARE_clinical.html','DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js','atlas-topic.js','atlas-shell.css','atlas-topic.css')))if(sum(file.info(file.path(stage,names))$size)>524288)stop('Initial asset byte budget exceeded',call.=FALSE)
  atlas_loading_budget(stage,directory)
  atlas_public_manifest(stage,build_id,payload$run_id %||% '',safe$privacy_metadata$policy_version,project_root,payload$publication_phase_summary %||% canonical$run_summary)
  files <- list.files(stage,recursive=TRUE,full.names=FALSE)
  if(any(file.info(file.path(stage,files))$size==0)) stop('Empty site asset',call.=FALSE)
  stage_assets <- as.list(setNames(file.path(stage,files),paste0('site_',seq_along(files))))
  internal <- output_manifest(c(manifest_paths,stage_assets),parent)
  internal$clinical_source_inventory_version <- ''
  internal$clinical_source_inventory_schema_version <- NA_integer_
  internal$input_md5 <- ''
  membership_row <- internal$artifact_id == 'clinical_source_membership'
  internal$clinical_source_inventory_version[membership_row] <- membership_spec$inventory_version
  internal$clinical_source_inventory_schema_version[membership_row] <- membership_spec$schema_version
  internal$input_md5[membership_row] <- unname(tools::md5sum(membership_path))
  site_rows <- match(unlist(stage_assets,use.names=FALSE),internal$path)
  if(anyNA(site_rows)) stop('Incomplete staged manifest',call.=FALSE)
  internal$relative_path[site_rows] <- paste0(basename(output),'/',files)
  internal$path[site_rows] <- file.path(output,files)
  if(anyDuplicated(internal$relative_path) || any(internal$file_size_bytes[site_rows]!=file.info(file.path(stage,files))$size)) stop('Invalid staged manifest',call.=FALSE)
  write_csv(internal,manifest_stage)
  # Promote the public directory and internal manifest as one recoverable pair.
  moved_site <- moved_manifest <- published_site <- FALSE
  tryCatch({
    if(dir.exists(output)) {
      if(!file.rename(output,backup)) stop('Cannot preserve previous site',call.=FALSE)
      moved_site <- TRUE
    }
    if(file.exists(manifest)) {
      if(!file.rename(manifest,manifest_backup)) stop('Cannot preserve previous manifest',call.=FALSE)
      moved_manifest <- TRUE
    }
    if(!file.rename(stage,output)) stop('Site publication failed',call.=FALSE)
    published_site <- TRUE
    if(!file.rename(manifest_stage,manifest)) stop('Manifest publication failed',call.=FALSE)
  },error=function(e) {
    if(published_site) unlink(output,recursive=TRUE)
    if(moved_site && !file.rename(backup,output)) stop('Previous site retained at ',backup,call.=FALSE)
    if(moved_manifest && !file.rename(manifest_backup,manifest)) stop('Previous manifest retained at ',manifest_backup,call.=FALSE)
    stop(e)
  })
  if(moved_site) unlink(backup,recursive=TRUE)
  if(moved_manifest) unlink(manifest_backup)
  list(html=file.path(output,'DALYCARE_atlas.html'),clinical_html=file.path(output,'DALYCARE_clinical.html'),payload=file.path(output,'DALYCARE_atlas_payload.js'),payload_json=file.path(output,'DALYCARE_atlas_payload.json'),catalogue=file.path(output,'DALYCARE_output_catalogue.js'),manifest=manifest,assets=as.list(setNames(file.path(output,files),paste0('site_',seq_along(files)))))
}
