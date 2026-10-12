# Authoritative CSV handoff. Registry entries, not filenames or saved payloads,
# authorize schemas and public projections. The context never contains data rows.
atlas_output_registry <- function(project_root = '.') {
  path <- file.path(project_root, 'inst/config/public-output-registry.json')
  if (!file.exists(path)) path <- system.file('config','public-output-registry.json',package='dalycareatlas')
  if (!nzchar(path) || !file.exists(path)) stop('Output registry unavailable',call.=FALSE)
  x <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  if (!identical(x$schema_version,1L)) stop('Unsupported output registry version',call.=FALSE)
  for (key in c('input_max_bytes','public_table_max_bytes')) {
    env <- if(key=='input_max_bytes') 'DALYCARE_ATLAS_INPUT_MAX_BYTES' else 'DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES'
    configured <- Sys.getenv(env,unset='')
    if(nzchar(configured)) {
      value <- suppressWarnings(as.numeric(configured))
      if(length(value)!=1 || !is.finite(value) || value<1 || value!=floor(value)) stop('Invalid build byte limit',call.=FALSE)
      x[[key]] <- value
    }
  }
  x
}

atlas_optional_input <- function(run_dir,id,project_root='.') {
  registry <- atlas_output_registry(project_root)
  spec <- Filter(function(s)s$id==id,registry$artifacts)[[1]]
  path <- atlas_confined_path(run_dir,spec$source_file)
  if(file.exists(path)) return(atlas_read_registered_csv(path,spec,registry$input_max_bytes))
  as.data.frame(lapply(spec$schemas[[1]],function(type) switch(type,number=numeric(),boolean=logical(),character())),stringsAsFactors=FALSE)
}

atlas_confined_path <- function(root, relative) {
  relative <- gsub('\\\\','/',relative)
  if (length(relative)!=1L || is.na(relative) || grepl('^/|:|(^|/)\\.\\.(/|$)',relative)) stop('Output path escapes selected run',call.=FALSE)
  root <- normalizePath(root,winslash='/',mustWork=TRUE)
  path <- normalizePath(file.path(root,relative),winslash='/',mustWork=FALSE)
  # Resolve existing ancestors as well, so links cannot escape through missing leaves.
  parent <- dirname(path)
  if (dir.exists(parent)) path <- file.path(normalizePath(parent,winslash='/',mustWork=TRUE),basename(path))
  if (!startsWith(tolower(path),paste0(tolower(root),'/'))) stop('Output path escapes selected run',call.=FALSE)
  path
}

atlas_read_registered_csv <- function(path, spec, max_bytes=67108864) {
  if (!file.exists(path) || is.na(file.info(path)$size) || file.info(path)$size > max_bytes) stop('Required input missing or exceeds pre-read limit',call.=FALSE)
  sep <- if (grepl('\\.tsv$',path)) '\t' else ','
  fail <- function(...) stop('Malformed or schema-incompatible registered input: ',basename(path),call.=FALSE)
  withCallingHandlers({
    widths <- count.fields(path,sep=sep,quote='"',comment.char='',blank.lines.skip=FALSE)
    if (!length(widths)) fail()
    # count.fields reports NA for physical continuation lines inside quoted fields.
    widths <- widths[!is.na(widths)]
    if (length(widths) && any(widths != widths[1])) fail()
    x <- utils::read.table(path,header=TRUE,sep=sep,quote='"',comment.char='',fill=FALSE,
                           colClasses='character',check.names=FALSE,stringsAsFactors=FALSE,
                           na.strings='',fileEncoding='UTF-8',blank.lines.skip=FALSE)
    if (identical(names(x),'')) x <- data.frame()
    schemas <- Filter(function(s) length(s)==ncol(x) && setequal(names(s),names(x)),spec$schemas)
    if (!length(schemas) || anyDuplicated(names(x))) fail()
    schema <- schemas[[1]]
    for (key in names(schema)) {
      value <- x[[key]]
      if (schema[[key]] == 'number') {
        numeric <- suppressWarnings(as.numeric(value))
        if (any(!is.na(value) & (is.na(numeric) | !is.finite(numeric)))) fail()
        x[[key]] <- numeric
      } else if (schema[[key]] == 'boolean') {
        if (any(!is.na(value) & !toupper(value) %in% c('TRUE','FALSE'))) fail()
        x[[key]] <- as.logical(toupper(value))
      }
    }
    x
  },warning=function(w) fail())
}

atlas_evidence_get <- function(x,path) {
  for (key in path) { if (!is.list(x)) return(NULL); x <- x[[key]] }
  x
}
atlas_evidence_set <- function(x,path,value) {
  if (length(path)==1L) {x[path] <- list(value); return(x)}
  x[[path[[1]]]] <- atlas_evidence_set(x[[path[[1]]]] %||% list(),path[-1],value)
  x
}
atlas_evidence_rows <- function(x) {
  if (!is.data.frame(x)) return(x)
  lapply(seq_len(nrow(x)),function(i) lapply(as.list(x[i,,drop=FALSE]),function(v) if(is.na(v)) NULL else unname(v)))
}

# Only identifiers required to regenerate the existing controlled SQL template
# are retained. Unrecognized SQL is rejected, never cached in build context.
atlas_query_template_context <- function(args) {
  text <- args$patobank_ki67_percent$query_templates %||% ''
  text <- paste(text,collapse='\n')
  if (!nzchar(text)) return(list(empty=TRUE))
  loc <- regmatches(text,regexec('from "([^"]+)"\\."([^"]+)" p',text))[[1]]
  col <- regmatches(text,regexec('p\\."([^"]+)"',text))[[1]]
  if (length(loc)!=3 || length(col)!=2) stop('Unsupported query template context',call.=FALSE)
  keys <- list(patient=character(),investigation=character(),specimen=character())
  denominators <- args$patobank_ki67_percent$denominator_counts
  for (key in names(keys)) {
    value <- denominators$key_columns_used[denominators$denominator_id==key]
    value <- value[!is.na(value) & nzchar(value)]
    if (length(value)) keys[[key]] <- trimws(strsplit(value[1],';',fixed=TRUE)[[1]])
  }
  config <- list(schema=loc[2],table=loc[3],source_column=col[2],key_columns=keys)
  if (!identical(text,do.call(patobank_ki67_query_templates_for_columns,config))) stop('Unsupported custom query template; reviewed regeneration required',call.=FALSE)
  c(list(empty=FALSE),config)
}

atlas_is_mcl_cohort_spec <- function(spec) {
  path <- unlist(spec$arg_path,use.names=FALSE)
  length(path)==3L && identical(path[1:2],c('mcl_triangle_feasibility','cohort_counts'))
}

# Selected-source files become immutable inputs of this run, in a separate
# directory so same-named current-run outputs are not replaced.
atlas_imported_mcl_path <- function(spec) {
  if(!atlas_is_mcl_cohort_spec(spec)) stop('Only reviewed MCL aggregates can have imported bindings',call.=FALSE)
  paste0('outputs/selected_mcl/',basename(spec$source_file))
}

atlas_bound_source_file <- function(spec,context=NULL) {
  relative <- context$binding_files[[spec$id]]
  if(is.null(relative)) return(spec$source_file)
  if(!identical(relative,atlas_imported_mcl_path(spec)) || !spec$id %in% unlist(context$bindings,use.names=FALSE)) stop('Invalid selected aggregate binding',call.=FALSE)
  relative
}

atlas_read_selected_mcl_outputs <- function(outputs_dir,project_root='.') {
  registry <- atlas_output_registry(project_root)
  result <- list()
  for(spec in registry$artifacts) if(atlas_is_mcl_cohort_spec(spec)) {
    path <- atlas_confined_path(outputs_dir,basename(spec$source_file))
    if(file.exists(path)) {
      result[[spec$arg_path[[3]]]] <- atlas_read_registered_csv(path,spec,registry$input_max_bytes)
    }
  }
  result
}

atlas_save_build_context <- function(run_dir,payload_args,output_paths,panel_paths,project_root='.') {
  registry <- atlas_output_registry(project_root)
  # Validate all caller bindings, including unused outputs, before accepting a run.
  run <- normalizePath(run_dir,winslash='/',mustWork=TRUE)
  for (path in c(output_paths,panel_paths)) {
    path <- normalizePath(path,winslash='/',mustWork=FALSE)
    if (!startsWith(tolower(path),paste0(tolower(run),'/'))) stop('Output binding escapes selected run',call.=FALSE)
    atlas_confined_path(run,substring(path,nchar(run)+2))
  }
  bindings <- list(); binding_files <- list(); schema_metadata <- list(); consumed <- character()
  selection <- payload_args$mcl_triangle_feasibility$standalone_output_source
  selected_dir <- NULL
  if(is.data.frame(selection) && 'selected' %in% names(selection)) {
    chosen <- which(!is.na(selection$selected) & as.logical(selection$selected))
    if(length(chosen)>1L) stop('Ambiguous selected aggregate source',call.=FALSE)
    if(length(chosen)) {
      selected_dir <- selection$selected_outputs_dir[[chosen]]
      if(!is.character(selected_dir) || is.na(selected_dir) || !nzchar(selected_dir) || !dir.exists(selected_dir)) stop('Selected aggregate directory unavailable',call.=FALSE)
      selected_dir <- normalizePath(selected_dir,winslash='/',mustWork=TRUE)
    }
  }
  for (spec in registry$artifacts) {
    if (!length(spec$arg_path)) next
    path <- unlist(spec$arg_path,use.names=FALSE)
    value <- atlas_evidence_get(payload_args,path)
    if (is.null(value)) next
    if (!is.data.frame(value)) stop('Unsupported non-tabular build argument: ',paste(path,collapse='/'),call.=FALSE)
    file <- atlas_confined_path(run,spec$source_file)
    if(atlas_is_mcl_cohort_spec(spec) && !is.null(selected_dir)) {
      selected_file <- atlas_confined_path(selected_dir,basename(spec$source_file))
      if(!file.exists(selected_file)) {
        if(nrow(value)) stop('Nonempty selected aggregate has no CSV binding: ',spec$id,call.=FALSE)
        consumed <- c(consumed,paste(path,collapse='/'));next
      }
      # Validate the actual selected file before reading/copying, even if an
      # earlier module read returned an empty fallback for malformed input.
      atlas_read_registered_csv(selected_file,spec,registry$input_max_bytes)
      if(!identical(tolower(selected_file),tolower(file))) {
        relative <- atlas_imported_mcl_path(spec)
        file <- atlas_confined_path(run,relative)
        dir_create(dirname(file))
        # Re-resolve after directory creation to enforce confinement through links.
        file <- atlas_confined_path(run,relative)
        if(!file.copy(selected_file,file,overwrite=TRUE)) stop('Could not preserve selected aggregate',call.=FALSE)
        binding_files[[spec$id]] <- relative
      }
    }
    if (!isTRUE(spec$required) && !file.exists(file) && !isTRUE(spec$supplementary)) {
      if(nrow(value)) stop('Nonempty optional aggregate has no CSV binding: ',spec$id,call.=FALSE)
      consumed <- c(consumed,paste(path,collapse='/'));next
    }
    if (isTRUE(spec$supplementary)) {
      if (!any(vapply(spec$schemas,function(s) setequal(names(s),names(value)),logical(1)))) stop('Unsupported aggregate context schema: ',spec$id,call.=FALSE)
      write_csv(value,file)
    }
    frame <- atlas_read_registered_csv(file,spec,registry$input_max_bytes)
    bindings[[length(bindings)+1L]] <- spec$id
    schema_metadata[[spec$id]] <- as.list(names(frame))
    consumed <- c(consumed,paste(path,collapse='/'))
  }
  check <- function(x,path=character()) {
    name <- paste(path,collapse='/')
    if (name %in% consumed || name %in% c('run_id','generated_at','patobank_ki67_percent/query_templates','mcl_triangle_feasibility/ki67_discovery')) return(invisible(NULL))
    if (is.list(x) && !is.data.frame(x)) {for(k in names(x)) check(x[[k]],c(path,k));return(invisible(NULL))}
    if (!is.null(x)) stop('Unsupported build context field: ',name,call.=FALSE)
  }
  check(payload_args)
  for (key in c('run_id','generated_at')) if (!is.character(payload_args[[key]]) || length(payload_args[[key]])!=1 || is.na(payload_args[[key]])) stop('Invalid run identity',call.=FALSE)
  context <- list(schema_version=1L,registry_version=1L,provenance='csv_rehydrated',run_id=payload_args$run_id,generated_at=payload_args$generated_at,
                  bindings=bindings,binding_files=binding_files,table_schemas=schema_metadata,query_template=atlas_query_template_context(payload_args),
                  minimum_cell_count=atlas_effective_threshold(),limits=list(input_max_bytes=registry$input_max_bytes,public_table_max_bytes=registry$public_table_max_bytes))
  path <- atlas_confined_path(run,'outputs/atlas_build_context.json')
  jsonlite::write_json(context,path,auto_unbox=TRUE,pretty=TRUE,null='null',na='null')
  invisible(path)
}

atlas_read_build_context <- function(run_dir,registry) {
  path <- atlas_confined_path(run_dir,'outputs/atlas_build_context.json')
  if (!file.exists(path) || file.info(path)$size > registry$input_max_bytes) stop('Required build context missing or oversized; use explicitly labelled snapshot migration for older runs',call.=FALSE)
  x <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  if (!identical(x$schema_version,1L) || !identical(x$registry_version,1L)) stop('Unsupported build context version',call.=FALSE)
  ids <- vapply(registry$artifacts,function(s)s$id,character(1))
  if (any(!unlist(x$bindings,use.names=FALSE) %in% ids) || anyDuplicated(unlist(x$bindings))) stop('Invalid build context bindings',call.=FALSE)
  for(id in names(x$binding_files)) {
    spec <- registry$artifacts[[match(id,ids)]]
    if(is.null(spec)) stop('Unknown selected aggregate binding',call.=FALSE)
    atlas_bound_source_file(spec,x)
  }
  x
}

atlas_payload_from_run_outputs <- function(run_dir,project_root='.',membership_spec=NULL) {
  if(is.null(membership_spec)) membership_spec <- load_clinical_source_membership(project_root)
  registry <- atlas_output_registry(project_root); context <- atlas_read_build_context(run_dir,registry)
  minimum <- atlas_effective_threshold(context=context)
  args <- list(run_id=context$run_id,generated_at=context$generated_at,panels=list())
  for (spec in registry$artifacts) {
    if (!spec$id %in% unlist(context$bindings,use.names=FALSE)) next
    if (!length(spec$arg_path)) stop('Invalid clinical input binding',call.=FALSE)
    frame <- atlas_read_registered_csv(atlas_confined_path(run_dir,atlas_bound_source_file(spec,context)),spec,registry$input_max_bytes)
    args <- atlas_evidence_set(args,unlist(spec$arg_path,use.names=FALSE),frame)
  }
  required <- vapply(Filter(function(s)isTRUE(s$required) && length(s$arg_path),registry$artifacts),function(s)s$id,character(1))
  if (!all(required %in% unlist(context$bindings,use.names=FALSE))) stop('Required clinical bindings missing from build context',call.=FALSE)
  q <- context$query_template
  if (!is.logical(q$empty) || length(q$empty)!=1) stop('Invalid template configuration',call.=FALSE)
  if (isTRUE(q$empty)) sql <- '' else {
    if (!setequal(names(q),c('empty','schema','table','source_column','key_columns'))) stop('Unsupported template configuration',call.=FALSE)
    q$empty <- NULL; q$key_columns <- lapply(q$key_columns,unlist,use.names=FALSE)
    sql <- do.call(patobank_ki67_query_templates_for_columns,q)
  }
  args$patobank_ki67_percent$query_templates <- sql
  args$mcl_triangle_feasibility$cohort_counts <- args$mcl_triangle_feasibility$cohort_counts %||% list()
  args$mcl_triangle_feasibility$ki67_discovery <- args$ki67_discovery
  if (!exists('atlas_public_privacy',mode='function')) source(file.path(project_root,'R/public_privacy.R'),encoding='UTF-8')
  # Guard the full logical input tables before atlas_payload's clinical summary caps.
  logical <- list()
  for(spec in registry$artifacts) if(length(spec$arg_path) && length(spec$payload_path)) {
    frame <- atlas_evidence_get(args,unlist(spec$arg_path,use.names=FALSE))
    if(is.data.frame(frame)) logical <- atlas_evidence_set(logical,unlist(spec$payload_path,use.names=FALSE),atlas_evidence_rows(frame))
  }
  guarded <- atlas_public_privacy(logical,project_root,minimum)
  # Transfer whole-table decisions to the original typed frames before any
  # clinical helper filters, ranks or caps them. This also protects derived copies.
  for(spec in registry$artifacts) if(length(spec$arg_path) && length(spec$payload_path)) {
    path <- unlist(spec$arg_path,use.names=FALSE)
    frame <- atlas_evidence_get(args,path)
    full <- atlas_evidence_get(guarded,unlist(spec$payload_path,use.names=FALSE))
    if (identical(spec$id,'registry_field_summaries') && is.list(full)) {
      schema <- spec$schemas[[1]]
      frame <- as.data.frame(setNames(lapply(names(schema),function(key) {
        if (schema[[key]]=='number') vapply(full,function(row) if(is.null(row[[key]])) NA_real_ else as.numeric(row[[key]]),numeric(1))
        else vapply(full,function(row) row[[key]] %||% NA_character_,character(1))
      }),names(schema)),stringsAsFactors=FALSE)
      args <- atlas_evidence_set(args,path,frame)
      next
    }
    if(is.data.frame(frame) && nrow(frame) && is.list(full)) {
      if(nrow(frame) != length(full)) {
        # Range-derived rows were collapsed by the whole-table guard. Preserve
        # original column types while rebuilding only the approved row set.
        frame <- frame[rep(NA_integer_,length(full)),,drop=FALSE]
        rownames(frame) <- NULL
        for(i in seq_along(full)) for(key in intersect(names(frame),names(full[[i]]))) {
          if(!is.null(full[[i]][[key]])) frame[i,key] <- full[[i]][[key]]
        }
      }
      for(i in seq_len(nrow(frame))) for(key in intersect(names(frame),names(full[[i]]))) {
        if(is.null(full[[i]][[key]])) frame[i,key] <- NA
      }
      for(key in unique(unlist(lapply(full,function(row)grep('privacy_status$|^summary_scope$|^summary_method$',names(row),value=TRUE))))) {
        frame[[key]] <- vapply(full,function(row) row[[key]] %||% NA_character_,character(1))
      }
      args <- atlas_evidence_set(args,path,frame)
    }
  }
  args$mcl_triangle_feasibility$ki67_discovery <- args$ki67_discovery
  args$membership_spec <- membership_spec
  payload <- atlas_public_privacy(do.call(atlas_payload,args),project_root,minimum)
  list(payload=payload,tables=atlas_output_evidence(run_dir,project_root,discard_membership_input=TRUE),context=context,membership_spec=membership_spec)
}

atlas_evidence_audit <- function(x,project_root='.',min_cell_count=5) {
  visit <- function(row,path=character()) {
    if(!is.list(row)) return(invisible(NULL))
    if(length(path) && tail(path,1)=='registry_field_summaries') {
      result <- atlas_registry_summary_audit(row,project_root,min_cell_count)
      if(!isTRUE(result$ok)) stop('Registry summary privacy audit failed',call.=FALSE)
      return(invisible(NULL))
    }
    if(is.null(names(row))) {for(v in row) visit(v,path);return(invisible(NULL))}
    if(any(tail(path,1) %in% c('npu_display_dictionary','clinical_display_dictionary'))) return(invisible(NULL))
    forbidden <- intersect(c('min','max','min_date','max_date','raw_min_date','raw_max_date','display_min_date','display_max_date'),names(row))
    if(!identical(row$numeric_privacy_status,'eligible_stored_summary')) forbidden <- c(forbidden,intersect(c('mean','median','p25','p75','sd'),names(row)))
    if(row$value_privacy_status %||% '' %in% c('protected_field','withheld_unvalidated_distribution')) forbidden <- c(forbidden,intersect(c('value','label','raw_value','raw_code','raw_descriptor','display_value','statistic_value'),names(row)))
    if(any(vapply(forbidden,function(k) !is.null(row[[k]]) && length(row[[k]]) && !is.na(row[[k]]) && as.character(row[[k]])!='',logical(1)))) stop('Public evidence privacy audit failed',call.=FALSE)
    for(key in names(row)) visit(row[[key]],c(path,key))
  }
  visit(x); invisible(TRUE)
}

atlas_validate_output_manifest <- function(run_dir,max_bytes,project_root='.',discard_membership_input=FALSE) {
  path <- atlas_confined_path(run_dir,'outputs/output_manifest.csv')
  if(!file.exists(path)) return(invisible(NULL))
  if(file.info(path)$size>max_bytes) stop('Output manifest exceeds pre-read limit',call.=FALSE)
  rows <- withCallingHandlers(read.csv(path,colClasses='character',check.names=FALSE,stringsAsFactors=FALSE,fileEncoding='UTF-8'),warning=function(w)stop('Malformed output manifest',call.=FALSE))
  if(!'relative_path' %in% names(rows)) stop('Invalid output manifest',call.=FALSE)
  if(isTRUE(discard_membership_input) && 'artifact_id' %in% names(rows)) {
    # An old resource input is never rehydrated. Drop it from this saved-run view
    # before path validation, so the current project/installation can replace it.
    rows <- rows[is.na(rows[['artifact_id']]) | rows[['artifact_id']]!='clinical_source_membership',,drop=FALSE]
  }
  for(i in seq_len(nrow(rows))) {
    relative <- rows$relative_path[[i]]
    if('artifact_id' %in% names(rows) && identical(rows$artifact_id[[i]],'clinical_source_membership')) {
      # This required installed/project input is metadata outside the run, never
      # an arbitrary output path. Permit only its explicitly resolved exact path.
      if(!identical(relative,clinical_source_membership_path(project_root))) stop('Invalid membership resource manifest input',call.=FALSE)
    } else atlas_confined_path(run_dir,relative)
  }
  invisible(NULL)
}

atlas_output_evidence <- function(run_dir,project_root='.',payload_snapshot=NULL,discard_membership_input=FALSE) {
  registry <- atlas_output_registry(project_root); logical <- list(); descriptors <- list()
  if(!is.null(run_dir)) atlas_validate_output_manifest(run_dir,registry$input_max_bytes,project_root,discard_membership_input=discard_membership_input)
  context <- if (!is.null(run_dir) && file.exists(atlas_confined_path(run_dir,'outputs/atlas_build_context.json'))) atlas_read_build_context(run_dir,registry) else NULL
  minimum <- atlas_effective_threshold(payload_snapshot,context)
  required <- unlist(context$bindings,use.names=FALSE)
  for(spec in registry$artifacts) {
    resource <- isTRUE(spec$resource); base <- if(resource) project_root else run_dir
    file <- if(!is.null(base)) atlas_confined_path(base,if(resource) spec$source_file else atlas_bound_source_file(spec,context)) else NULL
    rows <- list(); status <- 'not_produced'; reason <- 'Output not produced'; count <- NULL; complete <- FALSE
    provenance <- if(resource) 'project_reference' else if(!is.null(run_dir)) 'csv_run' else 'snapshot_only'
    if(!is.null(file) && file.exists(file)) {
      frame <- tryCatch(atlas_read_registered_csv(file,spec,registry$input_max_bytes),error=identity)
      if(inherits(frame,'error')) {
        if(spec$id %in% required) stop('Required registered input invalid: ',spec$id,call.=FALSE)
        status <- 'metadata_only';reason <- 'Input unavailable or schema not reviewed'
      } else {rows <- atlas_evidence_rows(frame);count <- nrow(frame);status <- if(count) 'available' else 'empty_output';reason <- '';complete <- TRUE}
    } else if(spec$id %in% required) stop('Required registered input missing: ',spec$id,call.=FALSE)
    else if(is.null(run_dir) && !resource && !is.null(payload_snapshot) && length(spec$payload_path)) {
      candidate <- atlas_evidence_get(payload_snapshot,unlist(spec$payload_path,use.names=FALSE))
      if(is.list(candidate) && is.null(names(candidate))) {
        converted <- tryCatch(atlas_normalize_snapshot_rows(candidate,spec),error=identity)
        if(inherits(converted,'error')) {status <- 'unavailable';reason <- 'Snapshot values incompatible with reviewed schema'}
        else {rows <- converted;status <- 'snapshot_preview';reason <- 'Original CSV row count and completeness unknown'}
      }
    }
    if(!length(spec$projection)) {rows <- list();complete <- FALSE;count <- NULL;if(status %in% c('available','empty_output','snapshot_preview')) {status <- 'metadata_only';reason <- 'Public column projection not reviewed'}}
    if(length(spec$payload_path) && length(spec$projection)) logical <- atlas_evidence_set(logical,unlist(spec$payload_path,use.names=FALSE),rows)
    descriptor <- spec[c('id','title','source_file','group','kind','row_grain','count_basis')]
    descriptor <- c(descriptor,list(status=status,reason=reason,source_row_count=count,represented_row_count=0L,complete=complete,provenance=provenance,source_terms=list(),columns=list(),rows=list()))
    descriptors[[length(descriptors)+1L]] <- descriptor
  }
  if(!exists('atlas_public_privacy',mode='function')) source(file.path(project_root,'R/public_privacy.R'),encoding='UTF-8')
  safe <- atlas_public_privacy(logical,project_root,minimum)
  atlas_evidence_audit(safe,project_root,minimum)
  privacy <- c('value_privacy_status','count_privacy_status','date_privacy_status','availability_privacy_status','numeric_privacy_status','summary_scope','summary_method','is_sensitive')
  for(i in seq_along(descriptors)) {
    spec <- registry$artifacts[[i]]
    rows <- if(length(spec$payload_path) && length(spec$projection)) atlas_evidence_get(safe,unlist(spec$payload_path,use.names=FALSE)) else list()
    keys <- unique(c(unlist(spec$projection,use.names=FALSE),sort(intersect(unique(unlist(lapply(rows,names))),privacy))))
    descriptors[[i]]$rows <- lapply(rows,function(row) setNames(lapply(keys,function(k)row[[k]]),keys))
    descriptors[[i]]$represented_row_count <- length(descriptors[[i]]$rows)
    if(any(vapply(rows,function(row) identical(row$date_privacy_status,'withheld_derived_source_range'),logical(1)))) {
      descriptors[[i]]['source_row_count'] <- list(NULL)
      descriptors[[i]]$reason <- 'Transformed approved scope: inferred source ranges collapsed; original row count withheld'
    }

    terms <- unlist(lapply(descriptors[[i]]$rows,function(row)row[intersect(c('table_name','source_name','registry'),names(row))]),use.names=FALSE)

    terms <- c(terms,unlist(spec$navigation_terms,use.names=FALSE))
    for(mapping in spec$navigation_fields) if(any(vapply(descriptors[[i]]$rows,function(row) identical(row$table_name,mapping$table_name) && identical(row$column_name,mapping$column_name),logical(1)))) terms <- c(terms,unlist(mapping$terms,use.names=FALSE))
    descriptors[[i]]$source_terms <- as.list(sort(unique(as.character(terms[!is.na(terms) & nzchar(terms)])),method='radix'))
    types <- unlist(spec$schemas)
    descriptors[[i]]$columns <- lapply(as.list(keys),function(key)utils::modifyList(list(key=key,label=paste0(toupper(substr(gsub('_',' ',key),1,1)),substring(gsub('_',' ',key),2)),type=if(key %in% names(types)) unname(types[key][1]) else if(key=='is_sensitive') 'boolean' else 'string'),spec$column_meanings[[key]] %||% list()))
  }
  if(!is.null(run_dir)) {
    known <- vapply(registry$artifacts,function(s)s$source_file,character(1)); unknown <- character()
    for(sub in c('outputs','outputs/panels')) for(file in sort(list.files(atlas_confined_path(run_dir,sub),pattern='\\.csv$',full.names=FALSE))) {
      relative <- paste0(sub,'/',file);atlas_confined_path(run_dir,relative)
      if(!relative %in% known && file!='output_manifest.csv') unknown <- c(unknown,relative)
    }
    for(i in seq_along(unknown)) descriptors[[length(descriptors)+1L]] <- list(id=paste0('unreviewed_',i),title='Unreviewed output',source_file='',group='Other outputs',kind='metadata',status='metadata_only',reason='Artifact not registered for publication',row_grain='Meaning not supplied',count_basis='not supplied',source_row_count=NULL,represented_row_count=0L,complete=FALSE,provenance='csv_run',source_terms=list(),columns=list(),rows=list())
  }
  bytes <- nchar(jsonlite::toJSON(lapply(descriptors,function(t)t$rows),auto_unbox=TRUE,null='null',na='null',digits=NA),type='bytes')
  if(bytes > registry$public_table_max_bytes) stop('Public table-data budget exceeded',call.=FALSE)
  descriptors
}


atlas_effective_threshold <- function(payload=NULL,context=NULL) {
  values <- list(Sys.getenv('DALYCARE_MIN_CELL_COUNT',unset='5'))
  if(!is.null(payload$privacy_metadata) && 'minimum_cell_count' %in% names(payload$privacy_metadata)) values <- c(values,list(payload$privacy_metadata$minimum_cell_count))
  if('minimum_cell_count' %in% names(context)) values <- c(values,list(context$minimum_cell_count))
  parsed <- vapply(values,function(value) {
    if(length(value)!=1 || !(is.numeric(value) || is.character(value))) stop('Invalid explicit privacy threshold',call.=FALSE)
    n <- suppressWarnings(as.numeric(value))
    if(!is.finite(n) || n<1 || n!=floor(n)) stop('Invalid explicit privacy threshold',call.=FALSE)
    n
  },numeric(1))
  max(5,parsed)
}

atlas_normalize_snapshot_rows <- function(rows,spec) {
  types <- unlist(spec$schemas)
  lapply(rows,function(row) {
    if(!is.list(row) || is.null(names(row))) stop('Invalid snapshot row',call.=FALSE)
    for(key in names(row)) {
      value <- row[[key]]; kind <- unname(types[key][1])
      if(is.null(value) || identical(value,'')) {row[key] <- list(NULL);next}
      if(length(value)!=1 || is.list(value)) stop('Invalid snapshot cell',call.=FALSE)
      if(identical(kind,'number')) {
        n <- suppressWarnings(as.numeric(value))
        if(is.logical(value) || !is.finite(n)) stop('Invalid numeric snapshot value',call.=FALSE)
        row[[key]] <- n
      } else if(identical(kind,'boolean')) {
        if(!is.logical(value)) {
          if(!is.character(value) || !toupper(value) %in% c('TRUE','FALSE')) stop('Invalid boolean snapshot value',call.=FALSE)
          row[[key]] <- as.logical(toupper(value))
        }
      } else if(identical(kind,'string') && !is.character(value)) stop('Invalid string snapshot value',call.=FALSE)
    }
    row
  })
}


atlas_context_input_paths <- function(run_dir,context,project_root='.') {
  registry <- atlas_output_registry(project_root)
  specs <- Filter(function(s)s$id %in% unlist(context$bindings),registry$artifacts)
  paths <- lapply(specs,function(s)atlas_confined_path(run_dir,atlas_bound_source_file(s,context)))
  names(paths) <- vapply(specs,function(s)paste0('input_',s$id),character(1))
  c(list(atlas_build_context=atlas_confined_path(run_dir,'outputs/atlas_build_context.json'),
         clinical_source_membership=clinical_source_membership_path(project_root)),paths)
}
