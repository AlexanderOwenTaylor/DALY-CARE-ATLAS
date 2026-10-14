# Lifecycle diagnostics deliberately use base R only, including startup failures.
# Raw conditions are never serialized: database drivers may include SQL or secrets.
atlas_recovery_instructions <- function(stage) {
  if(stage %in% c('startup','preflight')) return('Restore required runtime resources and dependencies; choose a writable output directory, then rerun the source entrypoint.')
  if(stage=='collection') return('Review retained source, access and memory diagnostics; correct access or resource limits, then rerun collection.')
  'Keep the run outputs and logs. Correct the failing build resource, then rebuild offline with scripts/rebuild_atlas_from_outputs.R using the existing run directory; recollect only if inputs are incomplete.'
}

atlas_lifecycle_start <- function(project_root, output_root, stage='preflight') {
  state <- new.env(parent=emptyenv())
  state$stage <- stage;state$status <- 'running';state$error <- '';state$error_code <- '';state$error_resource <- ''
  state$outcomes <- c(collection='not_started',interpretation='not_started',website='not_started',packaging='not_implemented')
  state$run_id <- paste0(format(Sys.time(),'%Y%m%d_%H%M%S'),'-p',Sys.getpid(),'-',paste(sample(c(0:9,letters[1:6]),8,TRUE),collapse=''))
  state$run_dir <- file.path(output_root,state$run_id)
  state$log_dirs <- character()
  # A project-level record survives an invalid or unwritable selected output root.
  candidates <- unique(c(file.path(project_root,'atlas_runs','.recovery'),file.path(getwd(),'atlas_runs','.recovery'),
    file.path(path.expand('~'),'.dalycare-atlas','recovery')))
  for(base in candidates) {
    path <- file.path(base,state$run_id)
    ok <- tryCatch({
      suppressWarnings(dir.create(path,recursive=TRUE,showWarnings=FALSE))
      probe <- file.path(path,'.probe')
      if(!isTRUE(suppressWarnings(file.create(probe)))) FALSE else {unlink(probe);TRUE}
    },error=function(e) FALSE)
    if(ok) {state$log_dirs <- normalizePath(path,winslash='/',mustWork=TRUE);break}
  }
  if(!length(state$log_dirs)) stop('Cannot persist recovery diagnostics; choose a writable project or working directory.',call.=FALSE)
  state$events <- data.frame(timestamp=character(),level=character(),table_name=character(),stage=character(),message=character(),stringsAsFactors=FALSE)
  options(dalycare.atlas.active_run_dir=state$run_dir,dalycare.atlas.failure_diagnostics=NULL)
  atlas_lifecycle_event(state,'info','Attempt started')
  state
}

atlas_lifecycle_atomic_write <- function(path,writer) {
  stage <- tempfile('.atlas-state-',tmpdir=dirname(path))
  on.exit(if(file.exists(stage))unlink(stage),add=TRUE)
  writer(stage)
  if(!file.rename(stage,path)) stop('Cannot replace build status; previous status retained.',call.=FALSE)
  invisible(path)
}

atlas_lifecycle_save <- function(state) {
  rows <- data.frame(metric=c('run_id','run_status','failing_stage','current_stage','sanitised_error','error_code','error_resource',
    'recovery_instructions',paste0(names(state$outcomes),'_status')),
    value=c(state$run_id,state$status,if(state$status=='failed')state$stage else '',state$stage,state$error,state$error_code,state$error_resource,
      atlas_recovery_instructions(state$stage),unname(state$outcomes)),stringsAsFactors=FALSE)
  written <- character()
  for(path in state$log_dirs) {
    ok <- tryCatch({
      atlas_lifecycle_atomic_write(file.path(path,'atlas_build_status.tsv'),function(stage)
        utils::write.table(rows,stage,sep='\t',quote=TRUE,row.names=FALSE,fileEncoding='UTF-8'))
      atlas_lifecycle_atomic_write(file.path(path,'atlas_recovery.txt'),function(stage)
        writeLines(c(paste('Stage:',state$stage),paste('Status:',state$status),state$error,atlas_recovery_instructions(state$stage)),stage,useBytes=TRUE))
      TRUE
    },error=function(e) FALSE)
    if(ok) written <- c(written,path)
  }
  if(!length(written)) stop('Cannot persist build diagnostics.',call.=FALSE)
  diagnostics <- file.path(tail(written,1L),'atlas_build_status.tsv')
  options(dalycare.atlas.failure_diagnostics=diagnostics)
  invisible(diagnostics)
}

atlas_lifecycle_event <- function(state,level='info',message='Stage progress recorded',table_name='') {
  state$events <- rbind(state$events,data.frame(timestamp=format(Sys.time(),'%Y-%m-%dT%H:%M:%S%z'),
    level=if(level %in% c('info','warning','error'))level else 'info',table_name=table_name,stage=state$stage,
    message=message,stringsAsFactors=FALSE))
  for(path in state$log_dirs) tryCatch({
    log <- file.path(path,'atlas_execution_log.tsv')
    append <- file.exists(log)
    con <- file(log,if(append)'at' else 'wt',encoding='UTF-8')
    tryCatch({
      utils::write.table(if(append)tail(state$events,1L) else state$events,con,
        sep='\t',quote=TRUE,row.names=FALSE,col.names=!append)
      flush(con)
    },finally=close(con))
  },error=function(e) invisible(NULL))
  atlas_lifecycle_save(state)
}

atlas_lifecycle_stage <- function(state,stage,previous_status='complete') {
  if(state$stage %in% names(state$outcomes)) state$outcomes[[state$stage]] <- previous_status
  state$stage <- stage
  if(stage %in% names(state$outcomes)) state$outcomes[[stage]] <- 'running'
  atlas_lifecycle_event(state,'info','Stage started')
}

atlas_lifecycle_fail <- function(state,error=NULL) {
  state$status <- 'failed'
  state$error_code <- if(inherits(error,'atlas_preflight_error')) error$code else 'unexpected_stage_error'
  state$error_resource <- if(inherits(error,'atlas_preflight_error')) error$resource else ''
  state$error <- paste0('Atlas ',state$stage,' failed: ',state$error_code,
    if(nzchar(state$error_resource))paste0(' (',state$error_resource,')') else '',
    '. Raw error details withheld; inspect retained internal diagnostics.')
  if(state$stage %in% names(state$outcomes)) state$outcomes[[state$stage]] <- 'failed'
  diagnostics <- atlas_lifecycle_event(state,'error',state$error)
  structure(list(message=paste0(state$error,' Diagnostics written to: ',diagnostics),call=NULL,
    stage=state$stage,code=state$error_code,resource=state$error_resource,diagnostics=diagnostics,run_dir=state$run_dir),class=c('atlas_build_error','error','condition'))
}

atlas_preflight_check <- function(code,resource,expr) {
  tryCatch(force(expr),error=function(e) stop(structure(list(message=paste(code,resource),call=NULL,
    code=code,resource=resource),class=c('atlas_preflight_error','error','condition'))))
}

atlas_build_preflight <- function(project_root,source_map_path,run_dir,db_adapter=NULL) {
  # Match DESCRIPTION Imports for source runs too; never install at runtime.
  packages <- c('dplyr','jsonlite','purrr','readr','stringr','tibble','tidyr')
  description <- file.path(project_root,'DESCRIPTION')
  if(file.exists(description)) packages <- atlas_preflight_check('invalid_configuration','DESCRIPTION',{
    imports <- read.dcf(description,fields='Imports')[[1L]]
    trimws(strsplit(gsub('\\([^)]*\\)','',imports),',')[[1L]])
  })
  for(package in unique(c('jsonlite',packages))) atlas_preflight_check('missing_dependency',package,{
    if(!requireNamespace(package,quietly=TRUE)) stop('Required build dependency unavailable',call.=FALSE)
  })
  source_map <- atlas_preflight_check('invalid_source_map','selected source map',read_source_map(source_map_path,project_root=project_root))
  if(is.null(db_adapter) && any(source_map$source_type=='dataset') && atlas_db_profile_enabled()) {
    atlas_preflight_check('missing_dependency','DBI',if(!requireNamespace('DBI',quietly=TRUE)) stop('Required database dependency unavailable',call.=FALSE))
    native_connection <- nzchar(Sys.getenv('DALYCARE_ATLAS_DBNAME',unset=Sys.getenv('PGDATABASE',unset=''))) ||
      file.exists(dalycare_default_db_access_path())
    if(native_connection) atlas_preflight_check('missing_dependency','RPostgres',{
      if(!requireNamespace('RPostgres',quietly=TRUE)) stop('Required database driver unavailable',call.=FALSE)
    })
  }
  for(name in c('DALYCARE_entry.html','DALYCARE_atlas.html','DALYCARE_outputs.html','atlas-entry.js','atlas-outputs.js',
    'atlas-transport.js','atlas-pages.css','atlas-vitals.js','atlas-vitals.css','registry-v2.js')) {
    atlas_preflight_check('missing_or_invalid_template',name,{
      resource <- atlas_bundle_resource(name,project_root)
      expected_bytes <- file.info(resource)$size
      if(is.na(expected_bytes) || expected_bytes<=0) stop('Required template is empty',call.=FALSE)
      connection <- suppressWarnings(file(resource,'rb'))
      tryCatch(withCallingHandlers({
        observed_bytes <- 0
        repeat {
          chunk <- readBin(connection,'raw',n=65536L)
          if(!length(chunk)) break
          observed_bytes <- observed_bytes+length(chunk)
        }
        if(observed_bytes!=expected_bytes) stop('Required template read is incomplete',call.=FALSE)
      },warning=function(w)stop('Required template could not be read',call.=FALSE)),finally=close(connection))
    })
  }
  registry <- atlas_preflight_check('invalid_policy','public-output-registry.json',atlas_output_registry(project_root))
  atlas_preflight_check('invalid_policy','clinical-source-membership.json',load_clinical_source_membership(project_root))
  atlas_preflight_check('invalid_configuration','transport version',atlas_transport_version())
  dictionary <- atlas_preflight_check('invalid_dictionary','npu-consensus-dictionary.tsv',load_npu_consensus_dictionary(project_root))
  atlas_preflight_check('invalid_dictionary','pinned local terminology',validate_local_terminology(project_root))
  atlas_preflight_check('invalid_dictionary','npu-detective-surfaces.tsv',load_npu_detective_surfaces(project_root))
  atlas_preflight_check('invalid_dictionary','isotype-vectors.tsv',load_isotype_vectors(project_root,dictionary=dictionary))
  atlas_preflight_check('invalid_dictionary','mm-treatment-code-families.tsv',load_mm_treatment_code_families(project_root))
  atlas_preflight_check('invalid_policy','registry-summary-policy.json',{
    if(!length(registry_summary_policy(project_root))) stop('Required reviewed registry policy unavailable',call.=FALSE)
  })
  atlas_preflight_check('invalid_policy','registry v2 local policy and unit evidence',registry_v2_preflight(project_root))
  atlas_preflight_check('invalid_policy','approved metadata definitions',{
    if(!exists('atlas_metadata_preflight',mode='function'))source(file.path(project_root,'R/metadata_privacy.R'),local=TRUE)
    atlas_metadata_preflight(project_root)
  })
  # These dictionaries are required by the final HTML serializer as well as the
  # clinical interpretation. Validate them before any source profiling starts.
  for(name in c('npu-display-dictionary.csv','clinical-display-dictionary.csv','public-measurement-policy.csv')) {
    atlas_preflight_check(if(name=='public-measurement-policy.csv')'invalid_policy' else 'invalid_dictionary',name,{
    path <- file.path(project_root,'config',name)
    if(!file.exists(path)) path <- system.file('config',name,package='dalycareatlas')
    if(!nzchar(path) || !file.exists(path)) stop('Required display dictionary or policy unavailable',call.=FALSE)
    rows <- utils::read.csv(path,check.names=FALSE,stringsAsFactors=FALSE,fileEncoding='UTF-8')
    required <- switch(name,'public-measurement-policy.csv'=c('table_name','column_name'),
      'clinical-display-dictionary.csv'=c('kind','system','code','label'),c('code','label'))
    if(!all(required %in% names(rows)) || !nrow(rows)) stop('Invalid display dictionary or policy',call.=FALSE)
    if(name!='public-measurement-policy.csv') {
      id <- if(name=='npu-display-dictionary.csv') 'npu_display_dictionary' else 'clinical_display_dictionary'
      spec <- Filter(function(s)identical(s$id,id),registry$artifacts)[[1]]
      registered <- atlas_read_registered_csv(path,spec,registry$input_max_bytes)
      if(id=='clinical_display_dictionary') atlas_bundle_field_labels(atlas_evidence_rows(registered))
    }
    })
  }
  for(relative in c('site','outputs/panels','logs/probe')) atlas_preflight_check('destination_invalid_or_not_writable',relative,
    atlas_site_destination(file.path(run_dir,relative)))
  invisible(source_map)
}

run_atlas <- function(project_root, source_map_path, output_root = 'atlas_runs',mode='report',
                      bootstrap_path=dalycare_resolve_bootstrap_path(Sys.getenv('DALYCARE_BOOTSTRAP_PATH',unset='')),
                      db_adapter=NULL) {
  project_root <- normalizePath(project_root,winslash='/',mustWork=FALSE)
  output_root <- if(grepl('^[A-Za-z]:|^/',output_root))output_root else file.path(project_root,output_root)
  state <- atlas_lifecycle_start(project_root,output_root)
  tryCatch({
    mode <- match.arg(mode,c('report','strict'))
    map_path <- if(file.exists(source_map_path))source_map_path else file.path(project_root,source_map_path)
    atlas_build_preflight(project_root,map_path,state$run_dir,db_adapter)
    state$log_dirs <- c(state$log_dirs,file.path(state$run_dir,'logs'))
    atlas_lifecycle_stage(state,'collection')
    result <- atlas_run_impl(project_root,source_map_path,output_root,mode,bootstrap_path,db_adapter,state)
    state$outcomes[['website']] <- 'complete'
    values <- setNames(result$completion$summary$value,result$completion$summary$metric)
    state$outcomes[['collection']] <- values[['collection_status']]
    state$outcomes[['interpretation']] <- values[['interpretation_status']]
    state$status <- 'partial' # Packaging is a separate, not yet implemented phase.
    state$stage <- 'finished'
    atlas_lifecycle_event(state,'info','Build finished; review separate phase outcomes')
    result$build_status <- atlas_lifecycle_save(state)
    result$phase_outcomes <- state$outcomes
    result$overall_status <- state$status
    invisible(result)
  },error=function(e) stop(atlas_lifecycle_fail(state,e)))
}

atlas_run_impl <- function(project_root, source_map_path, output_root = "atlas_runs",
                      mode = "report",
                      bootstrap_path = dalycare_resolve_bootstrap_path(Sys.getenv("DALYCARE_BOOTSTRAP_PATH", unset = "")),
                      db_adapter = NULL, lifecycle) {
  mode <- match.arg(mode, c("report", "strict"))
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  registry_options <- options(dalycare.registry.project_root = project_root)
  on.exit(options(registry_options), add = TRUE)
  bootstrap_path <- dalycare_resolve_bootstrap_path(bootstrap_path)
  source_map_path <- if (file.exists(source_map_path)) source_map_path else file.path(project_root, source_map_path)
  output_root <- if (grepl("^[A-Za-z]:|^/", output_root)) output_root else file.path(project_root, output_root)

  run_id <- lifecycle$run_id
  run_dir <- file.path(output_root, run_id)
  output_dir <- file.path(run_dir, "outputs")
  panel_dir <- file.path(output_dir, "panels")
  log_dir <- file.path(run_dir, "logs")
  dir_create(panel_dir)
  dir_create(log_dir)
  # This is the actual attempt, even if it fails before source resolution.
  options(dalycare.atlas.active_run_dir = normalizePath(run_dir, winslash="/", mustWork=FALSE))
  run_completed <- FALSE
  source_map <- NULL
  sources <- NULL
  panels <- list()
  completion <- NULL
  completion_summary_path <- file.path(output_dir, "atlas_completion_summary.csv")
  registry_completion_path <- file.path(output_dir, "atlas_registry_completion.csv")
  on.exit({
    if (!run_completed && dir.exists(output_dir)) tryCatch({
      completed_sources <- safe_read_output_csv(file.path(output_dir,"atlas_sources.csv"), sources)
      completion <- atlas_completion_report(source_map, completed_sources, panels$registry_field_summaries,
        project_root, run_id, "failed", lifecycle)
      write_csv(completion$summary, completion_summary_path)
      write_csv(completion$registries, registry_completion_path)
    },error=function(e) invisible(NULL))
  }, add=TRUE)

  log_event <- function(level, table_name, message) {
    safe_message <- if(level=='error') 'Source operation failed; inspect internal outputs.' else if(level=='warning') 'Source diagnostic available in internal outputs.' else 'Source or build progress recorded.'
    for(prefix in c('Starting DALY-CARE atlas run','Loaded NPU consensus dictionary','Loaded NPU detective surfaces',
      'Loaded isotype NPU mappings','Loaded MM treatment code rules','Using load strategy','Diagnostic manifest written',
      'Static atlas written','Output manifest written','Run summary')) if(startsWith(message,prefix)) safe_message <- prefix
    safe_table <- if(!is.null(source_map) && is.character(table_name) && length(table_name)==1L &&
      !is.na(table_name) && table_name %in% source_map$table_name) table_name else ''
    atlas_lifecycle_event(lifecycle,level,safe_message,safe_table)
  }

  generated_at <- atlas_timestamp()
  log_event("info", "", paste("Starting DALY-CARE atlas run", run_id))
  source_map <- read_source_map(source_map_path, project_root = project_root)
  production_source_map <- read_production_source_recovery_map(project_root = project_root)
  source_resolution_plan_dry_run <- build_source_resolution_plan_dry_run(
    project_root = project_root,
    production_map = production_source_map
  )
  npu_dictionary <- load_npu_consensus_dictionary(project_root = project_root)
  log_event("info", "", paste("Loaded NPU consensus dictionary with", nrow(npu_dictionary), "codes"))
  npu_surfaces <- load_npu_detective_surfaces(project_root = project_root)
  isotype_vectors <- load_isotype_vectors(project_root = project_root, dictionary = npu_dictionary)
  treatment_families <- load_mm_treatment_code_families(project_root = project_root)
  log_event("info", "", paste("Loaded NPU detective surfaces:", nrow(npu_surfaces)))
  log_event("info", "", paste("Loaded isotype NPU mappings:", nrow(isotype_vectors)))
  log_event("info", "", paste("Loaded MM treatment code rules:", nrow(treatment_families)))
  for (warning in validation_warnings(source_map, output_root = output_root, project_root = project_root)) {
    log_event("warning", warning$table_name, warning$message)
  }
  if (is.null(db_adapter) && any(source_map$source_type == "dataset") && atlas_db_profile_enabled()) {
    db_adapter <- dalycare_db_adapter(bootstrap_path = bootstrap_path)
  }
  source_resolution <- resolve_dalycare_sources(source_map, db_adapter = db_adapter)
  memory_plan <- memory_plan_for_sources(source_map, source_resolution)
  access_report <- dalycare_access_report(
    project_root = project_root,
    source_map = source_map,
    bootstrap_path = bootstrap_path,
    db_adapter = db_adapter,
    source_resolution = source_resolution
  )
  access_report <- adjust_access_report_for_actual_impact(
    access_report,
    db_adapter = db_adapter,
    memory_plan = memory_plan
  )
  for (i in seq_len(nrow(access_report))) {
    if (access_report$status[[i]] %in% c("warning", "error")) {
      log_event(access_report$status[[i]], access_report$table_name[[i]], paste(access_report$check_id[[i]], access_report$message[[i]]))
    }
  }
  for (i in seq_len(nrow(source_resolution))) {
    row <- source_resolution[i, , drop = FALSE]
    if (row$resolution_status[[1]] %in% c("missing", "ambiguous", "db_unavailable")) {
      log_event("warning", row$table_name[[1]], paste("DB source resolution:", row$message[[1]]))
    }
  }

  memory_log_rows <- list()
  log_memory <- function(plan_row) {
    memory_log_rows[[length(memory_log_rows) + 1L]] <<- data.frame(
      timestamp = atlas_timestamp(),
      table_name = plan_row$table_name[[1]],
      source_type = plan_row$source_type[[1]],
      chosen_strategy = plan_row$chosen_strategy[[1]],
      memory_status = plan_row$memory_status[[1]],
      row_count = suppressWarnings(as.numeric(plan_row$row_count[[1]] %||% NA_real_)),
      chunk_size = suppressWarnings(as.integer(plan_row$chunk_size[[1]] %||% NA_integer_)),
      max_full_load_rows = suppressWarnings(as.integer(plan_row$max_full_load_rows[[1]] %||% NA_integer_)),
      allow_full_load = as.logical(plan_row$allow_full_load[[1]] %||% FALSE),
      message = plan_row$message[[1]],
      stringsAsFactors = FALSE
    )
  }

  source_rows <- list()
  column_rows <- list()
  column_profile_rows <- list()
  column_top_value_rows <- list()
  check_rows <- list()
  frequency_rows <- list()
  db_query_log_rows <- list()
  db_budget_action_rows <- list()
  panels <- list(
    lab_npu_code_coverage = data.frame(stringsAsFactors = FALSE),
    npu_dictionary_summary = panel_npu_dictionary_summary(npu_dictionary),
    npu_dictionary_vectors = panel_npu_dictionary_vectors(npu_dictionary),
    npu_lab_usage_by_vector = empty_npu_lab_usage_by_vector(),
    npu_lab_unmatched_codes = empty_npu_lab_unmatched_codes(),
    npu_detective_code_inventory = empty_npu_detective_code_inventory(),
    npu_detective_candidates = empty_npu_detective_candidates(),
    npu_detective_source_year = empty_npu_detective_source_year(),
    isotype_code_usage = empty_isotype_code_usage(),
    isotype_bucket_summary = empty_isotype_bucket_summary(),
    mm_treatment_code_counts = empty_mm_treatment_code_counts(),
    mm_treatment_source_summary = empty_mm_treatment_source_summary(),
    diagnosis_icd_groups = data.frame(stringsAsFactors = FALSE),
    medication_atc_groups = data.frame(stringsAsFactors = FALSE),
    damyda_feature_coverage = data.frame(stringsAsFactors = FALSE),
    registry_clinical_summary = empty_registry_summary(),
    registry_field_summaries = empty_registry_field_summaries(),
    damyda_clinical_profile = empty_registry_categorical(),
    damyda_numeric_fields = empty_registry_numeric(),
    lyfo_clinical_profile = empty_registry_categorical(),
    cll_clinical_profile = empty_registry_categorical(),
    sp_operational_sources = data.frame(stringsAsFactors = FALSE),
    atlas_temporal_coverage = empty_temporal_coverage(),
    atlas_temporal_coverage_years = empty_temporal_coverage_years(),
    atlas_temporal_date_quality = empty_temporal_date_quality(),
    atlas_spatial_region_counts = empty_spatial_region_counts(),
    atlas_spatial_region_coverage = empty_spatial_region_coverage(),
    atlas_dk_choropleth_regions = empty_dk_choropleth_regions(),
    situation_report_summary = empty_situation_report_summary(),
    situation_report_breakdowns = empty_situation_report_breakdowns(),
    situation_report_freshness = empty_situation_report_freshness(),
    atlas_streaming_progress_summary = empty_streaming_progress_summary(),
    source_availability_drift = data.frame(stringsAsFactors = FALSE)
  )
  stream_paths <- list(
    sources = file.path(output_dir, "atlas_sources.csv"),
    columns = file.path(output_dir, "atlas_columns.csv"),
    column_profiles = file.path(output_dir, "atlas_column_profiles.csv"),
    column_top_values = file.path(output_dir, "atlas_column_top_values.csv"),
    checks = file.path(output_dir, "atlas_checks.csv"),
    value_frequencies = file.path(output_dir, "atlas_value_frequencies.csv")
  )

  for (i in seq_len(nrow(source_map))) {
    record <- source_map[i, , drop = FALSE]
    table_name <- record$table_name[[1]]
    plan_row <- memory_plan[memory_plan$source_index == i, , drop = FALSE][1, , drop = FALSE]
    resolution_row <- source_resolution[source_resolution$source_index == i, , drop = FALSE][1, , drop = FALSE]
    log_memory(plan_row)
    log_event("info", table_name, paste("Using load strategy:", plan_row$chosen_strategy[[1]]))
    cat(sprintf(
      "[%d/%d] %s: %s (%s)\n",
      i, nrow(source_map), table_name,
      plan_row$chosen_strategy[[1]],
      plan_row$resolution_status[[1]]
    ))
    flush.console()
    if (identical(plan_row$chosen_strategy[[1]], "skipped_risky_full_load")) {
      message <- paste("Skipped source:", plan_row$message[[1]])
      log_event("warning", table_name, message)
      source_out <- append_runtime_source_context(
        skipped_source_row(record, message),
        plan_row,
        resolution_row
      )
      check_out <- check_row(table_name, "source_skipped_risky_full_load", "warning", message)
      append_csv_rows(source_out, stream_paths$sources)
      append_csv_rows(check_out, stream_paths$checks)
      next
    }
    log_event("info", table_name, "Loading source")
    result <- tryCatch({
      if (plan_row$chosen_strategy[[1]] %in% c("db_aggregate", "db_chunked")) {
        if (identical(plan_row$chosen_strategy[[1]], "db_chunked") && is.function(db_adapter$chunked_profile_table)) {
          normalize_profile_result(db_adapter$chunked_profile_table(
            db_name = resolution_row$db_name[[1]],
            schema = resolution_row$schema[[1]],
            table = resolution_row$table[[1]],
            table_name = table_name,
            source_type = "dataset",
            source = record$source[[1]],
            profile_mode = record$profile_mode[[1]],
            chunk_size = plan_row$chunk_size[[1]],
            min_cell_count = atlas_min_cell_count()
          ))
        } else {
          profile_db_source(
            source_record = record,
            resolution_row = resolution_row,
            db_adapter = db_adapter,
            profile_mode = record$profile_mode[[1]],
            npu_dictionary = npu_dictionary,
            npu_surfaces = npu_surfaces,
            isotype_vectors = isotype_vectors,
            treatment_families = treatment_families
          )
        }
      } else {
        data <- load_source_data(record, project_root = project_root, bootstrap_path = bootstrap_path)
        prof <- profile_source(
          data = data,
          table_name = table_name,
          source_type = record$source_type[[1]],
          source = record$source[[1]],
          profile_mode = record$profile_mode[[1]],
          npu_dictionary = npu_dictionary,
          npu_surfaces = npu_surfaces,
          isotype_vectors = isotype_vectors,
          treatment_families = treatment_families
        )
        rm(data)
        gc(verbose = FALSE)
        prof
      }
    }, error = function(e) {
      if (identical(mode, "strict")) stop(e)
      list(error = conditionMessage(e))
    })

    if (!is.null(result$error)) {
      log_event("error", table_name, result$error)
      source_out <- append_runtime_source_context(
        failed_source_row(record, result$error),
        plan_row,
        resolution_row
      )
      check_out <- check_row(table_name, "source_load_failed", "error", result$error)
      append_csv_rows(source_out, stream_paths$sources)
      append_csv_rows(check_out, stream_paths$checks)
      next
    }

    result$source <- append_source_metadata(result$source, record)
    result$source <- append_runtime_source_context(result$source, plan_row, resolution_row)
    append_csv_rows(result$source, stream_paths$sources)
    append_csv_rows(result$columns, stream_paths$columns)
    append_csv_rows(result$column_profiles, stream_paths$column_profiles)
    append_csv_rows(result$column_top_values, stream_paths$column_top_values)
    append_csv_rows(result$checks, stream_paths$checks)
    append_csv_rows(result$value_frequencies, stream_paths$value_frequencies)
    if (is.data.frame(result$db_query_log) && nrow(result$db_query_log)) {
      db_query_log_rows[[length(db_query_log_rows) + 1L]] <- result$db_query_log
    }
    if (is.data.frame(result$db_budget_actions) && nrow(result$db_budget_actions)) {
      db_budget_action_rows[[length(db_budget_action_rows) + 1L]] <- result$db_budget_actions
    }
    for (panel_name in names(result$panels)) {
      panels[[panel_name]] <- bind_rows_base(list(panels[[panel_name]], result$panels[[panel_name]]))
    }
    log_event("info", table_name, "Profiled source")
    cat(sprintf("      done: %s rows, %s columns\n", result$source$n_rows[[1]], result$source$n_cols[[1]]))
    flush.console()
  }

  sources <- safe_read_output_csv(stream_paths$sources, bind_rows_base(source_rows))
  collection_status <- if(!is.data.frame(sources) || nrow(sources)!=nrow(source_map) ||
    !isTRUE(all(sources$load_status=='ok',na.rm=FALSE)) ||
    ('profile_mode' %in% names(sources) && any(sources$profile_mode=='schema',na.rm=TRUE))) 'partial' else 'complete'
  atlas_lifecycle_stage(lifecycle,'interpretation',collection_status)
  columns <- safe_read_output_csv(stream_paths$columns, bind_rows_base(column_rows))
  column_profiles <- add_source_context_to_column_outputs(safe_read_output_csv(stream_paths$column_profiles, bind_rows_base(column_profile_rows)), sources)
  column_top_values <- add_source_context_to_column_outputs(safe_read_output_csv(stream_paths$column_top_values, bind_rows_base(column_top_value_rows)), sources)
  checks <- safe_read_output_csv(stream_paths$checks, bind_rows_base(check_rows))
  access_checks <- access_report_checks(access_report)
  if (nrow(access_checks)) checks <- bind_rows_base(list(checks, access_checks))
  frequencies <- safe_read_output_csv(stream_paths$value_frequencies, bind_rows_base(frequency_rows))
  normalized_special_status <- normalize_special_manual_run_statuses(
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    checks = checks,
    columns = columns
  )
  sources <- normalized_special_status$sources
  source_resolution <- normalized_special_status$source_resolution
  checks <- normalized_special_status$checks
  db_query_log <- bind_rows_base(db_query_log_rows)
  if (!nrow(db_query_log)) db_query_log <- empty_db_query_log()
  db_budget_actions <- bind_rows_base(db_budget_action_rows)
  if (!nrow(db_budget_actions)) db_budget_actions <- empty_db_budget_actions()
  panels <- build_coverage_panels(
    sources = sources,
    column_profiles = column_profiles,
    panels = panels,
    min_cell_count = atlas_min_cell_count()
  )
  panels$atlas_streaming_progress_summary <- atlas_streaming_progress_summary(db_query_log, sources)
  panels$source_availability_drift <- source_availability_panel(sources)
  situation_panels <- build_situation_report_panels(
    source_resolution = source_resolution,
    db_adapter = db_adapter,
    sources = sources,
    column_profiles = column_profiles,
    min_cell_count = atlas_min_cell_count()
  )
  for (panel_name in names(situation_panels)) {
    panels[[panel_name]] <- situation_panels[[panel_name]]
  }
  membership_spec <- load_clinical_source_membership(project_root)
  panels$atlas_module_readiness <- atlas_module_readiness(sources, panels, membership_spec = membership_spec)
  semantic_outputs <- build_semantic_outputs(
    project_root = project_root,
    sources = sources,
    column_profiles = column_profiles,
    panels = panels,
    min_cell_count = atlas_min_cell_count()
  )
  product_outputs <- build_product_layer_outputs(
    semantic_outputs = semantic_outputs,
    sources = sources,
    panels = panels,
    column_profiles = column_profiles,
    min_cell_count = atlas_min_cell_count(),
    project_root = project_root,
    membership_spec = membership_spec
  )
  legacy_resource_audit <- build_legacy_cartography_source_resolution_audit(project_root = project_root)
  source_resolution_attempts <- build_source_resolution_attempts(
    project_root = project_root,
    production_map = production_source_map,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution
  )
  source_resolution_delta <- build_source_resolution_delta_legacy_vs_current(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    legacy_audit = legacy_resource_audit,
    source_attempts = source_resolution_attempts
  )
  resource_reconciliation <- build_atlas_resource_reconciliation(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    legacy_audit = legacy_resource_audit,
    delta = source_resolution_delta,
    source_attempts = source_resolution_attempts
  )
  source_truth_evidence <- build_source_truth_evidence_matrix(
    project_root = project_root,
    legacy_audit = legacy_resource_audit,
    delta = source_resolution_delta,
    reconciliation = resource_reconciliation
  )
  source_truth_metrics <- source_truth_summary(source_truth_evidence)
  canonical_resources <- read_canonical_dalycare_resources(project_root = project_root)
  source_map_crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    canonical = canonical_resources
  )
  current_run_source_map_audit <- build_current_run_source_map_audit(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    canonical = canonical_resources
  )
  canonical_reconciliation <- build_canonical_resource_reconciliation_64(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    canonical = canonical_resources,
    resource_reconciliation = resource_reconciliation
  )
  billeddiagnostik_del2_audit <- build_billeddiagnostik_del2_regression_audit(
    project_root = project_root,
    sources = sources,
    source_resolution = source_resolution,
    canonical_reconciliation = canonical_reconciliation,
    crosswalk = source_map_crosswalk
  )
  remaining_activation_plan <- build_remaining_canonical_resources_activation_plan(
    project_root = project_root,
    canonical_reconciliation = canonical_reconciliation,
    production_map = production_source_map,
    canonical = canonical_resources
  )
  legacy_reference_vs_current <- build_legacy_reference_vs_current_profiled_evidence(
    project_root = project_root,
    semantic_dictionary = semantic_outputs$dictionary,
    semantic_code_map = semantic_outputs$code_map,
    semantic_value_map = semantic_outputs$value_map,
    canonical_reconciliation = canonical_reconciliation,
    sources = sources,
    canonical = canonical_resources
  )
  ki67_discovery <- build_ki67_discovery_outputs(
    project_root = project_root,
    include_reference_files = TRUE,
    semantic_dictionary = semantic_outputs$dictionary,
    semantic_value_map = semantic_outputs$value_map,
    semantic_code_map = semantic_outputs$code_map,
    semantic_panel_links = semantic_outputs$panel_links,
    clinical_concepts = product_outputs$clinical_concepts,
    domain_panels = product_outputs$domain_panels,
    panel_kpis = product_outputs$panel_kpis,
    panel_distributions = product_outputs$panel_distributions,
    panel_raw_fields = product_outputs$panel_raw_fields,
    sources = sources,
    columns = columns,
    column_profiles = column_profiles,
    column_top_values = column_top_values,
    source_resolution = source_resolution,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current
  )
  mcl_triangle_feasibility <- build_mcl_triangle_feasibility_outputs(
    project_root = project_root,
    semantic_dictionary = semantic_outputs$dictionary,
    semantic_value_map = semantic_outputs$value_map,
    semantic_code_map = semantic_outputs$code_map,
    semantic_panel_links = semantic_outputs$panel_links,
    columns = columns,
    column_profiles = column_profiles,
    panel_raw_fields = product_outputs$panel_raw_fields,
    panel_distributions = product_outputs$panel_distributions,
    panel_kpis = product_outputs$panel_kpis,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current,
    ki67_discovery = ki67_discovery
  )
  patobank_ki67_percent <- patobank_ki67_build_outputs(
    project_root = project_root,
    db_adapter = db_adapter,
    source_resolution = source_resolution,
    sources = sources,
    min_cell_count = atlas_min_cell_count()
  )
  resource_checks <- resource_reconciliation_checks(resource_reconciliation)
  if (nrow(resource_checks)) checks <- bind_rows_base(list(checks, resource_checks))
  empty_live_refused <- should_refuse_empty_live_run(source_map, sources)
  if (isTRUE(empty_live_refused)) {
    message <- empty_live_run_message(source_map, source_resolution)
    checks <- bind_rows_base(list(checks, check_row("", "empty_live_run_refused", "error", message)))
    log_event("error", "", message)
  }
  action_items <- atlas_run_action_items(
    access_report = access_report,
    source_resolution = source_resolution,
    memory_plan = memory_plan,
    sources = sources,
    panels = panels,
    checks = checks
  )
  budget_action_items <- db_budget_actions_as_run_action_items(db_budget_actions, sources = sources)
  if (nrow(budget_action_items)) {
    action_items <- bind_rows_base(list(action_items, budget_action_items))
  }

  output_paths <- list()
  output_paths$source_resolution <- write_csv(source_resolution, file.path(output_dir, "atlas_source_resolution.csv"))
  output_paths$dalycare_access <- write_csv(access_report, file.path(output_dir, "atlas_dalycare_access.csv"))
  output_paths$memory_plan <- write_csv(memory_plan, file.path(output_dir, "atlas_memory_plan.csv"))
  output_paths$db_query_log <- write_tsv(db_query_log, file.path(output_dir, "atlas_db_query_log.tsv"))
  output_paths$db_budget_actions <- write_csv(db_budget_actions, file.path(output_dir, "atlas_db_budget_actions.csv"))
  output_paths$action_items <- write_csv(action_items, file.path(output_dir, "atlas_run_action_items.csv"))
  output_paths$legacy_cartography_source_resolution_audit <- write_csv(legacy_resource_audit, file.path(output_dir, "legacy_cartography_source_resolution_audit.csv"))
  output_paths$billeddiagnostik_del2_regression_audit <- write_csv(billeddiagnostik_del2_audit, file.path(output_dir, "billeddiagnostik_del2_regression_audit.csv"))
  output_paths$source_resolution_plan_dry_run <- write_csv(source_resolution_plan_dry_run, file.path(output_dir, "source_resolution_plan_dry_run.csv"))
  output_paths$source_resolution_attempts <- write_csv(source_resolution_attempts, file.path(output_dir, "source_resolution_attempts.csv"))
  output_paths$source_resolution_delta_legacy_vs_current <- write_csv(source_resolution_delta, file.path(output_dir, "source_resolution_delta_legacy_vs_current.csv"))
  output_paths$resource_reconciliation <- write_csv(resource_reconciliation, file.path(output_dir, "atlas_resource_reconciliation.csv"))
  output_paths$source_truth_evidence_matrix <- write_csv(source_truth_evidence, file.path(output_dir, "source_truth_evidence_matrix.csv"))
  output_paths$source_truth_summary <- write_csv(source_truth_metrics, file.path(output_dir, "source_truth_summary.csv"))
  output_paths$current_run_source_map_audit <- write_csv(current_run_source_map_audit, file.path(output_dir, "current_run_source_map_audit.csv"))
  output_paths$canonical_resource_reconciliation_64 <- write_csv(canonical_reconciliation, file.path(output_dir, "canonical_resource_reconciliation_64.csv"))
  output_paths$source_map_row_to_canonical_resource_crosswalk <- write_csv(source_map_crosswalk, file.path(output_dir, "source_map_row_to_canonical_resource_crosswalk.csv"))
  output_paths$legacy_reference_vs_current_profiled_evidence <- write_csv(legacy_reference_vs_current, file.path(output_dir, "legacy_reference_vs_current_profiled_evidence.csv"))
  output_paths$remaining_canonical_resources_activation_plan <- write_csv(remaining_activation_plan, file.path(output_dir, "remaining_canonical_resources_activation_plan.csv"))
  ki67_paths <- ki67_write_outputs(ki67_discovery, output_dir = output_dir, project_root = project_root)
  ki67_paths <- ki67_paths[setdiff(names(ki67_paths), "extraction_spec")]
  names(ki67_paths) <- paste0("ki67_", names(ki67_paths))
  output_paths <- c(output_paths, ki67_paths)
  patobank_ki67_paths <- patobank_ki67_write_outputs(patobank_ki67_percent, output_dir = output_dir)
  names(patobank_ki67_paths) <- paste0("patobank_ki67_", names(patobank_ki67_paths))
  output_paths <- c(output_paths, patobank_ki67_paths)
  mcl_triangle_paths <- mcl_triangle_write_outputs(mcl_triangle_feasibility, output_dir)
  names(mcl_triangle_paths) <- paste0("mcl_triangle_", names(mcl_triangle_paths))
  output_paths <- c(output_paths, mcl_triangle_paths)
  if (exists("mcl_count_build_outputs", mode = "function")) {
    mcl_count_run_mode <- mcl_count_mode(db_adapter)
    mcl_triangle_count_outputs <- mcl_count_build_outputs(
      project_root = project_root,
      outputs_dir = output_dir,
      mode = mcl_count_run_mode,
      db_adapter = db_adapter,
      min_cell_count = atlas_min_cell_count()
    )
    mcl_triangle_count_paths <- mcl_count_write_outputs(mcl_triangle_count_outputs, output_dir)
    names(mcl_triangle_count_paths) <- paste0("mcl_triangle_count_", names(mcl_triangle_count_paths))
    output_paths <- c(output_paths, mcl_triangle_count_paths)
  }
  output_paths$resource_catalog <- write_csv(resource_catalog(sources), file.path(output_dir, "atlas_resource_catalog.csv"))
  output_paths$sources <- write_csv(sources, file.path(output_dir, "atlas_sources.csv"))
  output_paths$columns <- write_csv(columns, file.path(output_dir, "atlas_columns.csv"))
  output_paths$column_profiles <- write_csv(column_profiles, file.path(output_dir, "atlas_column_profiles.csv"))
  output_paths$column_top_values <- write_csv(column_top_values, file.path(output_dir, "atlas_column_top_values.csv"))
  output_paths$checks <- write_csv(checks, file.path(output_dir, "atlas_checks.csv"))
  output_paths$value_frequencies <- write_csv(frequencies, file.path(output_dir, "atlas_value_frequencies.csv"))
  output_paths$semantic_dictionary <- write_csv(semantic_outputs$dictionary, file.path(output_dir, "atlas_semantic_data_dictionary.csv"))
  output_paths$semantic_value_map <- write_csv(semantic_outputs$value_map, file.path(output_dir, "atlas_semantic_value_map.csv"))
  output_paths$semantic_code_map <- write_csv(semantic_outputs$code_map, file.path(output_dir, "atlas_semantic_code_map.csv"))
  output_paths$semantic_panel_links <- write_csv(semantic_outputs$panel_links, file.path(output_dir, "atlas_semantic_panel_links.csv"))
  output_paths$semantic_unmapped_entity_overlay <- write_csv(semantic_outputs$unmapped_entity_overlay, file.path(output_dir, "atlas_semantic_unmapped_entity_overlay.csv"))
  output_paths$semantic_overlay_lookup <- write_csv(semantic_outputs$overlay_lookup, file.path(output_dir, "atlas_semantic_overlay_lookup.csv"))
  output_paths$curator_label_promotions <- write_csv(semantic_outputs$curator_label_promotions, file.path(output_dir, "atlas_curator_label_promotions.csv"))
  output_paths$curator_label_promotion_lookup <- write_csv(semantic_outputs$curator_label_lookup, file.path(output_dir, "atlas_curator_label_promotion_lookup.csv"))
  output_paths$semantic_mapping_conflicts <- write_csv(semantic_outputs$mapping_conflicts, file.path(output_dir, "atlas_semantic_mapping_conflicts.csv"))
  output_paths$clinical_concepts <- write_csv(product_outputs$clinical_concepts, file.path(output_dir, "atlas_clinical_concepts.csv"))
  output_paths$domain_panels <- write_csv(product_outputs$domain_panels, file.path(output_dir, "atlas_domain_panels.csv"))
  output_paths$panel_kpis <- write_csv(product_outputs$panel_kpis, file.path(output_dir, "atlas_panel_kpis.csv"))
  output_paths$panel_distributions <- write_csv(product_outputs$panel_distributions, file.path(output_dir, "atlas_panel_distributions.csv"))
  output_paths$panel_raw_fields <- write_csv(product_outputs$panel_raw_fields, file.path(output_dir, "atlas_panel_raw_fields.csv"))
  output_paths$panel_parity <- write_csv(product_outputs$panel_parity, file.path(output_dir, "atlas_panel_parity.csv"))
  run_summary <- atlas_run_summary(
    run_id, generated_at, source_map, sources, columns, checks, frequencies, panels,
    column_profiles = column_profiles,
    column_top_values = column_top_values
  )
  run_summary <- append_resource_reconciliation_run_summary(run_summary, resource_reconciliation, legacy_resource_audit)
  run_summary <- bind_rows_base(list(
    run_summary,
    source_recovery_run_summary_metrics(
      plan = production_source_map,
      dry_run = source_resolution_plan_dry_run,
      attempts = source_resolution_attempts
    ),
    canonical_resource_summary_metrics(
    canonical_reconciliation = canonical_reconciliation,
    crosswalk = source_map_crosswalk,
    legacy_reference = legacy_reference_vs_current
    )
  ))
  output_paths$run_summary <- write_csv(run_summary, file.path(output_dir, "atlas_run_summary.csv"))

  # Validate the merged artifact before CSV export: duplicate source rows cannot
  # publish individually valid copies of the same exact field.
  panels$registry_field_summaries <- registry_summary_final_guard(
    registry_v2_complete(panels$registry_field_summaries,project_root,atlas_min_cell_count()), project_root, atlas_min_cell_count()
  )
  completion <- atlas_completion_report(source_map, sources, panels$registry_field_summaries,
    project_root, run_id, "building", lifecycle)
  # Mutable attempt state is kept outside the immutable build-context manifest.
  # Final status is written only after the site build succeeds.
  write_csv(completion$summary, completion_summary_path)
  write_csv(completion$registries, registry_completion_path)
  panel_paths <- list()
  for (panel_name in names(panels)) {
    panel_paths[[panel_name]] <- write_csv(panels[[panel_name]], file.path(panel_dir, paste0(panel_name, ".csv")))
  }

  if (isTRUE(empty_live_refused)) {
    memory_log_path <- write_tsv(bind_rows_base(memory_log_rows), file.path(log_dir, "atlas_memory_log.tsv"))
    all_paths <- c(output_paths, panel_paths, list(memory_log = memory_log_path))
    manifest <- output_manifest(all_paths, run_dir = run_dir)
    manifest_path <- write_csv(manifest, file.path(output_dir, "output_manifest.csv"))
    log_event("info", "", "Diagnostic manifest written")
    atlas_lifecycle_save(lifecycle)
    stop(empty_live_run_message(source_map, source_resolution), "\nDiagnostics written to: ", run_dir, call. = FALSE)
  }

  payload_sources <- sources
  payload_columns <- columns
  payload_checks <- checks
  payload_column_profiles <- column_profiles
  payload_column_top_values <- column_top_values
  payload_run_summary <- run_summary
  payload_action_items <- action_items
  payload_db_query_log <- db_query_log
  payload_db_budget_actions <- db_budget_actions
  payload_semantic_dictionary <- semantic_outputs$dictionary
  payload_semantic_value_map <- semantic_outputs$value_map
  payload_semantic_code_map <- semantic_outputs$code_map
  payload_semantic_panel_links <- semantic_outputs$panel_links
  payload_semantic_unmapped_entity_overlay <- semantic_outputs$unmapped_entity_overlay
  payload_semantic_overlay_lookup <- semantic_outputs$overlay_lookup
  payload_curator_label_promotions <- semantic_outputs$curator_label_promotions
  payload_curator_label_lookup <- semantic_outputs$curator_label_lookup
  payload_semantic_mapping_conflicts <- semantic_outputs$mapping_conflicts
  payload_clinical_concepts <- product_outputs$clinical_concepts
  payload_domain_panels <- product_outputs$domain_panels
  payload_panel_kpis <- product_outputs$panel_kpis
  payload_panel_distributions <- product_outputs$panel_distributions
  payload_panel_raw_fields <- product_outputs$panel_raw_fields
  payload_panel_parity <- product_outputs$panel_parity
  payload_legacy_resource_audit <- legacy_resource_audit
  payload_billeddiagnostik_del2_audit <- billeddiagnostik_del2_audit
  payload_source_resolution_plan_dry_run <- source_resolution_plan_dry_run
  payload_source_resolution_attempts <- source_resolution_attempts
  payload_source_resolution_delta <- source_resolution_delta
  payload_resource_reconciliation <- resource_reconciliation
  payload_source_truth_evidence <- source_truth_evidence
  payload_source_truth_summary <- source_truth_metrics
  payload_current_run_source_map_audit <- current_run_source_map_audit
  payload_canonical_resource_reconciliation <- canonical_reconciliation
  payload_source_map_crosswalk <- source_map_crosswalk
  payload_legacy_reference_vs_current <- legacy_reference_vs_current
  payload_remaining_activation_plan <- remaining_activation_plan
  payload_ki67_discovery <- list(
    search_inventory = ki67_discovery$search_inventory,
    registry_field_candidates = ki67_discovery$registry_field_candidates,
    pathology_code_candidates = ki67_discovery$pathology_code_candidates,
    text_pattern_candidates = ki67_discovery$text_pattern_candidates,
    channel_summary = ki67_discovery$channel_summary,
    aeki_validation_plan = ki67_discovery$aeki_validation_plan,
    aeki_code_counts = ki67_discovery$aeki_code_counts,
    text_validation_plan = ki67_discovery$text_validation_plan,
    db_summary = atlas_optional_input(run_dir, "ki67_discovery_db_summary", project_root),
    db_found_locations = atlas_optional_input(run_dir, "ki67_discovery_db_found_locations", project_root),
    db_aeki_code_counts = atlas_optional_input(run_dir, "ki67_discovery_db_aeki_code_counts", project_root),
    db_p16_dual_stain_counts = atlas_optional_input(run_dir, "ki67_discovery_db_p16_dual_stain_counts", project_root),
    db_text_pattern_counts = atlas_optional_input(run_dir, "ki67_discovery_db_text_pattern_counts", project_root),
    db_registry_field_counts = atlas_optional_input(run_dir, "ki67_discovery_db_registry_field_counts", project_root),
    summary = ki67_discovery$summary
  )
  payload_patobank_ki67_percent <- list(
    validation = patobank_ki67_percent$validation,
    summary = patobank_ki67_percent$summary,
    code_counts = patobank_ki67_percent$code_counts,
    denominator_counts = patobank_ki67_percent$denominator_counts,
    query_templates = if (file.exists(output_paths$patobank_ki67_query_templates)) {
      paste(readLines(output_paths$patobank_ki67_query_templates, warn = FALSE), collapse = "\n")
    } else {
      ""
    }
  )
  mcl_triangle_count_source <- if (exists("mcl_count_resolve_standalone_output_source", mode = "function")) {
    mcl_count_resolve_standalone_output_source(project_root = project_root, outputs_dir = output_dir)
  } else {
    list(outputs_dir = "", metadata = mcl_triangle_empty_standalone_output_source())
  }
  payload_mcl_triangle_counts <- if (exists("mcl_count_read_outputs", mode = "function") &&
                                      nzchar(mcl_triangle_count_source$outputs_dir %||% "")) {
    atlas_read_selected_mcl_outputs(mcl_triangle_count_source$outputs_dir, project_root)
  } else {
    list()
  }
  payload_mcl_triangle_feasibility <- list(
    summary = mcl_triangle_feasibility$summary,
    variable_inventory = mcl_triangle_feasibility$variable_inventory,
    treatment_inventory = mcl_triangle_feasibility$treatment_inventory,
    outcome_inventory = mcl_triangle_feasibility$outcome_inventory,
    biology_gap_analysis = mcl_triangle_feasibility$biology_gap_analysis,
    study_readiness_matrix = mcl_triangle_feasibility$study_readiness_matrix,
    false_positive_exclusions = mcl_triangle_feasibility$false_positive_exclusions,
    cohort_counts = payload_mcl_triangle_counts,
    standalone_output_source = mcl_triangle_count_source$metadata,
    pathology_ki67_signpost = mcl_triangle_pathology_ki67_signpost(payload_mcl_triangle_counts),
    ki67_discovery = payload_ki67_discovery,
    recommended_next_actions = mcl_triangle_feasibility$recommended_next_actions,
    caveats = mcl_triangle_feasibility$caveats,
    verdict_metadata = mcl_triangle_feasibility$verdict_metadata
  )
  payload_panels <- lapply(names(panels), function(panel_name) {
    panels[[panel_name]]
  })
  names(payload_panels) <- names(panels)

  payload_args <- list(
    run_id = run_id, generated_at = generated_at, sources = payload_sources, columns = payload_columns, checks = payload_checks, panels = payload_panels,
    column_profiles = payload_column_profiles,
    column_top_values = payload_column_top_values,
    run_summary = payload_run_summary,
    action_items = payload_action_items,
    source_resolution = source_resolution,
    memory_plan = memory_plan,
    db_query_log = payload_db_query_log,
    db_budget_actions = payload_db_budget_actions,
    semantic_dictionary = payload_semantic_dictionary,
    semantic_value_map = payload_semantic_value_map,
    semantic_code_map = payload_semantic_code_map,
    semantic_panel_links = payload_semantic_panel_links,
    semantic_unmapped_entity_overlay = payload_semantic_unmapped_entity_overlay,
    semantic_overlay_lookup = payload_semantic_overlay_lookup,
    curator_label_promotions = payload_curator_label_promotions,
    curator_label_lookup = payload_curator_label_lookup,
    semantic_mapping_conflicts = payload_semantic_mapping_conflicts,
    clinical_concepts = payload_clinical_concepts,
    domain_panels = payload_domain_panels,
    panel_kpis_product = payload_panel_kpis,
    panel_distributions = payload_panel_distributions,
    panel_raw_fields = payload_panel_raw_fields,
    panel_parity = payload_panel_parity,
    legacy_resource_audit = payload_legacy_resource_audit,
    billeddiagnostik_del2_regression_audit = payload_billeddiagnostik_del2_audit,
    source_resolution_plan_dry_run = payload_source_resolution_plan_dry_run,
    source_resolution_attempts = payload_source_resolution_attempts,
    source_resolution_delta = payload_source_resolution_delta,
    resource_reconciliation = payload_resource_reconciliation,
    source_truth_evidence = payload_source_truth_evidence,
    source_truth_summary = payload_source_truth_summary,
    current_run_source_map_audit = payload_current_run_source_map_audit,
    canonical_resource_reconciliation = payload_canonical_resource_reconciliation,
    source_map_crosswalk = payload_source_map_crosswalk,
    legacy_reference_vs_current = payload_legacy_reference_vs_current,
    remaining_activation_plan = payload_remaining_activation_plan,
    ki67_discovery = payload_ki67_discovery,
    patobank_ki67_percent = payload_patobank_ki67_percent,
    mcl_triangle_feasibility = payload_mcl_triangle_feasibility
  )
  output_paths$atlas_build_context <- atlas_save_build_context(run_dir, payload_args, output_paths, panel_paths, project_root)
  reconstructed <- atlas_payload_from_run_outputs(run_dir, project_root, membership_spec = membership_spec)
  payload <- reconstructed$payload
  memory_log_path <- write_tsv(bind_rows_base(memory_log_rows), file.path(log_dir, "atlas_memory_log.tsv"))
  manifest_paths <- c(output_paths,panel_paths,atlas_context_input_paths(run_dir,reconstructed$context,project_root),list(memory_log=memory_log_path))
  interpretation_status <- completion$summary$value[completion$summary$metric=='interpretation_status']
  atlas_lifecycle_stage(lifecycle,'website',interpretation_status)
  site_paths <- write_static_atlas(run_dir,payload,project_root=project_root,output_evidence=reconstructed$tables,manifest_paths=manifest_paths,membership_spec=membership_spec)
  manifest_path <- site_paths$manifest
  log_event("info", "", "Static atlas written")
  log_event("info", "", "Output manifest written")
  log_event("info", "", paste("Run summary:", run_summary_log_message(run_summary)))
  atlas_lifecycle_save(lifecycle)

  completion <- atlas_completion_report(source_map, sources, panels$registry_field_summaries,
    project_root, run_id, "complete", lifecycle)
  write_csv(completion$summary, completion_summary_path)
  write_csv(completion$registries, registry_completion_path)
  run_completed <- TRUE

  invisible(list(
    run_id = run_id,
    run_dir = run_dir,
    manifest = manifest_path,
    html = site_paths$html,
    payload = site_paths$payload,
    completion = completion,
    completion_summary = completion_summary_path,
    registry_completion = registry_completion_path
  ))
}

# Safe completion metadata: source/field inventory counts and controlled statuses.
# Never include person keys, clinical values, SQL text, or raw query errors.
atlas_completion_report <- function(source_map, sources, registry_rows, project_root,
                                    run_id, build_status, lifecycle=NULL) {
  expected <- if (is.data.frame(source_map)) nrow(source_map) else 0L
  profiled <- skipped <- 0L
  if (is.data.frame(sources) && nrow(sources) && "load_status" %in% names(sources)) {
    profiled <- sum(sources$load_status == "ok", na.rm=TRUE)
    skipped <- sum(sources$load_status %in% c("skipped", "skipped_risky_full_load", "special_manual", "embedded_fields", "known_unavailable", "embedded_fields_represented", "manual_file_not_available"), na.rm=TRUE)
  }
  missing <- max(0L, expected - profiled - skipped)
  coverage <- if (is.null(source_map)) "unknown" else if (missing || skipped) "partial" else "complete"
  summary <- data.frame(metric=c("run_id", "build_status", "coverage_status", "expected_sources",
      "profiled_sources", "missing_sources", "skipped_sources"),
    value=as.character(c(run_id, build_status, coverage, expected, profiled, missing, skipped)),
    stringsAsFactors=FALSE)
  policy <- registry_summary_policy(project_root)
  registries <- lapply(c("RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL"), function(table) {
    specs <- Filter(function(spec) is.list(spec) && identical(spec$table_name,table), policy)
    # A nonempty policy for another registry cannot establish this inventory.
    valid_spec <- function(spec) {
      keys <- c("table_name","source_column","kind","topic","phase","label")
      all(vapply(keys,function(key) is.character(spec[[key]]) && length(spec[[key]])==1L &&
        !is.na(spec[[key]]) && nzchar(spec[[key]]),logical(1))) &&
        spec$kind %in% c("categorical","numeric")
    }
    policy_status <- if (length(specs) && all(vapply(specs,valid_spec,logical(1)))) "available" else "unavailable"
    requested <- is.data.frame(source_map) && table %in% source_map$table_name
    source <- if (is.data.frame(sources) && "table_name" %in% names(sources)) sources[sources$table_name==table,,drop=FALSE] else data.frame()
    source_status <- if (!requested) "source_not_requested" else if (!nrow(source) || !any(source$load_status=="ok",na.rm=TRUE)) "source_unavailable" else if (all(source$profile_mode=="schema")) "schema_only" else "profiled"
    rows <- if (is.data.frame(registry_rows) && nrow(registry_rows)) registry_rows[registry_rows$table_name==table,,drop=FALSE] else data.frame()
    statuses <- if (nrow(rows)) rows$summary_status else character()
    count <- function(states) as.integer(sum(statuses %in% states))
    unavailable <- count(c("field_unavailable","field_absent"))
    unassessed <- max(0L,length(specs)-length(unique(if(nrow(rows)) rows$source_column else character())))
    reason <- if (policy_status=="unavailable") "Restore the required reviewed registry policy and JSON dependency." else if (source_status=="source_not_requested") "Select this exact registry in the source map." else if (source_status=="source_unavailable") "Review source resolution, access and memory diagnostics." else if (source_status=="schema_only") "Schema mode omits clinical summaries." else if (any(statuses %in% c("needs_person_key","missing_person_key"))) "Check the exact live patientid column or authoritative private mapping." else if (any(statuses %in% c("query_failed","resource_limit"))) "Review aggregate query and resource-budget diagnostics." else if (any(grepl("^withheld_",statuses))) "Privacy gates withhold ineligible fields." else if(any(statuses %in% c("needs_unit_evidence","needs_numeric_policy"))) "Supply reviewed exact-field stored-unit evidence and approved fixed bands." else if (unavailable || unassessed) "Some reviewed fields are absent or unassessed." else "All reviewed fields assessed; see field statuses."
    data.frame(table_name=table,source_status=source_status,policy_status=policy_status,
      policy_issue_count=as.integer(policy_status=="unavailable"),expected_fields=if(policy_status=="available") length(specs) else NA_integer_,
      published_fields=count("published"),privacy_withheld_fields=count(c("withheld_small_group","withheld_constant","withheld_near_unique","withheld_privacy")),
      field_unavailable_fields=unavailable,key_issue_fields=count(c("needs_person_key","missing_person_key")),
      config_issue_fields=count("needs_person_key"),missing_key_fields=count("missing_person_key"),
      query_issue_fields=count("query_failed"),budget_issue_fields=count("resource_limit"),
      no_values_fields=count(c("no_values","empty_source","all_missing","all_unrecognised","all_conflicting","no_usable_values")),
      needs_unit_evidence_fields=count(c("needs_unit_evidence","needs_numeric_policy")),needs_mapping_fields=count(c("needs_mapping","all_unrecognised")),source_unavailable_fields=count("source_unavailable"),invalid_contract_fields=count("invalid_contract"),
      unassessed_fields=unassessed,action=reason,stringsAsFactors=FALSE)
  })
  registries <- do.call(rbind,registries)
  selected <- registries[registries$source_status!="source_not_requested",,drop=FALSE]
  registry_coverage <- if (!nrow(selected)) "not_requested" else if (any(selected$policy_status=="unavailable")) "unknown" else if (
    any(selected$source_status!="profiled" | selected$field_unavailable_fields>0 |
      selected$key_issue_fields>0 | selected$query_issue_fields>0 | selected$budget_issue_fields>0 |
      selected$invalid_contract_fields>0 | selected$unassessed_fields>0 | selected$needs_unit_evidence_fields>0 | selected$needs_mapping_fields>0 | selected$source_unavailable_fields>0)) "partial" else "complete"
  summary <- rbind(summary,data.frame(metric="registry_coverage_status",value=registry_coverage,stringsAsFactors=FALSE))
  collection <- if(identical(coverage,'complete')) 'complete' else 'partial'
  if(is.data.frame(sources) && 'profile_mode' %in% names(sources) && any(sources$profile_mode=='schema',na.rm=TRUE)) collection <- 'partial'
  interpretation <- if(registry_coverage %in% c('complete','not_requested')) 'complete' else 'partial'
  website <- if(build_status=='complete') 'complete' else if(build_status=='failed') 'not_started' else 'running'
  if(build_status=='failed' && !is.null(lifecycle)) {
    stage <- lifecycle$stage
    if(stage=='collection') {collection <- 'failed';interpretation <- 'not_started'}
    if(stage=='interpretation') interpretation <- 'failed'
    if(stage=='website') website <- 'failed'
  }
  summary <- rbind(summary,data.frame(metric=c('collection_status','interpretation_status','website_status','packaging_status','overall_status'),
    value=c(collection,interpretation,website,'not_implemented',if(build_status=='failed')'failed' else if(build_status=='complete')'partial' else 'running'),stringsAsFactors=FALSE))
  list(summary=summary,registries=registries)
}

atlas_print_completion_report <- function(completion) {
  values <- stats::setNames(completion$summary$value,completion$summary$metric)
  cat("Build status: ", values[["build_status"]], "; source coverage: ", values[["coverage_status"]], "\n", sep="")
  if('overall_status' %in% names(values)) cat('Overall: ',values[['overall_status']],'; collection: ',values[['collection_status']],
    '; interpretation: ',values[['interpretation_status']],'; website: ',values[['website_status']],'; packaging: ',values[['packaging_status']],'\n',sep='')
  cat("Reviewed registry-field coverage: ", values[["registry_coverage_status"]], "\n", sep="")
  cat("Sources expected/profiled/missing/skipped: ", paste(values[c("expected_sources","profiled_sources","missing_sources","skipped_sources")],collapse="/"), "\n", sep="")
  for (i in seq_len(nrow(completion$registries))) {
    r <- completion$registries[i,]
    cat(r$table_name, ": ", r$source_status, "; fields published/privacy withheld/unavailable/key/query/budget/unassessed: ",
      paste(unlist(r[c("published_fields","privacy_withheld_fields","field_unavailable_fields","key_issue_fields","query_issue_fields","budget_issue_fields","unassessed_fields")]),collapse="/"),
      ". ", r$action, "\n",sep="")
  }
}

atlas_allow_empty_live_run <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN", unset = "FALSE"), default = FALSE)
}

should_refuse_empty_live_run <- function(source_map, sources) {
  if (atlas_allow_empty_live_run()) return(FALSE)
  if (!is.data.frame(source_map) || !"source_type" %in% names(source_map)) return(FALSE)
  has_dataset <- any(tolower(source_map$source_type) == "dataset", na.rm = TRUE)
  if (!isTRUE(has_dataset)) return(FALSE)
  loaded <- 0L
  if (is.data.frame(sources) && all(c("load_status", "source_type") %in% names(sources))) {
    loaded <- sum(tolower(sources$source_type) == "dataset" & sources$load_status == "ok", na.rm = TRUE)
  } else if (is.data.frame(sources) && "load_status" %in% names(sources)) {
    loaded <- sum(sources$load_status == "ok", na.rm = TRUE)
  }
  loaded == 0L
}

empty_live_run_message <- function(source_map, source_resolution = NULL) {
  n_dataset <- if (is.data.frame(source_map) && "source_type" %in% names(source_map)) {
    sum(tolower(source_map$source_type) == "dataset", na.rm = TRUE)
  } else {
    0L
  }
  resolution_summary <- ""
  if (is.data.frame(source_resolution) && nrow(source_resolution) && "resolution_status" %in% names(source_resolution)) {
    counts <- table(source_resolution$resolution_status, useNA = "no")
    resolution_summary <- paste(paste(names(counts), as.integer(counts), sep = "="), collapse = ", ")
  }
  paste(
    "Refusing to write a misleading live DALY atlas: the source map contains",
    n_dataset,
    "dataset-backed DALY source(s), but zero sources were profiled.",
    "Check outputs/atlas_dalycare_access.csv and outputs/atlas_source_resolution.csv.",
    if (nzchar(resolution_summary)) paste("Resolution summary:", resolution_summary) else "",
    "Set DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN=TRUE only for fixture/skeleton dry-runs."
  )
}

access_report_checks <- function(access_report) {
  if (!is.data.frame(access_report) || !nrow(access_report)) return(empty_df(table_name = character(), check_id = character(), severity = character(), message = character()))
  status <- access_report$status %||% rep("", nrow(access_report))
  severity <- ifelse(status %in% c("error", "warning"), status, "info")
  data.frame(
    table_name = access_report$table_name %||% rep("", nrow(access_report)),
    check_id = paste0("dalycare_access_", access_report$check_id %||% seq_len(nrow(access_report))),
    severity = severity,
    message = paste(access_report$message %||% "", access_report$detail %||% ""),
    stringsAsFactors = FALSE
  )
}

validation_warnings <- function(source_map, output_root, project_root = ".") {
  rows <- list(attr(source_map, "warnings") %||% empty_df(table_name = character(), warning_id = character(), message = character()))
  risky <- output_root_warnings(output_root, project_root = project_root)
  if (nrow(risky)) rows[[length(rows) + 1L]] <- risky
  out <- bind_rows_base(rows)
  if (!nrow(out)) {
    return(list())
  }
  lapply(seq_len(nrow(out)), function(i) out[i, , drop = FALSE])
}

output_root_warnings <- function(output_root, project_root = ".") {
  output_root <- normalize_slashes(normalizePath(output_root, winslash = "/", mustWork = FALSE))
  project_root <- normalize_slashes(normalizePath(project_root, winslash = "/", mustWork = FALSE))
  risky_roots <- normalize_slashes(file.path(project_root, c("R", "scripts", "tests", "config", "inst", "inst/legacy")))
  risky <- identical(output_root, project_root) || any(startsWith(output_root, paste0(risky_roots, "/"))) || output_root %in% risky_roots
  if (!isTRUE(risky)) {
    return(empty_df(table_name = character(), warning_id = character(), message = character()))
  }
  data.frame(
    table_name = "",
    warning_id = "risky_output_root",
    message = paste("Output root is inside a source-controlled project area:", output_root),
    stringsAsFactors = FALSE
  )
}

source_record_metadata <- function(record) {
  meta_names <- intersect(source_map_optional_metadata(), names(record))
  if (!length(meta_names)) return(data.frame(stringsAsFactors = FALSE))
  out <- as.data.frame(
    stats::setNames(lapply(meta_names, function(nm) as.character(record[[nm]][[1]] %||% "")), meta_names),
    stringsAsFactors = FALSE
  )
  out
}

append_source_metadata <- function(source_row, record) {
  metadata <- source_record_metadata(record)
  if (!ncol(metadata)) return(source_row)
  for (nm in names(metadata)) {
    source_row[[nm]] <- metadata[[nm]][[1]]
  }
  source_row
}

append_runtime_source_context <- function(source_row, plan_row, resolution_row) {
  source_row$chosen_strategy <- plan_row$chosen_strategy[[1]] %||% ""
  source_row$memory_status <- plan_row$memory_status[[1]] %||% ""
  source_row$resolution_status <- resolution_row$resolution_status[[1]] %||% ""
  source_row$db_name <- resolution_row$db_name[[1]] %||% ""
  source_row$schema <- resolution_row$schema[[1]] %||% ""
  source_row$table <- resolution_row$table[[1]] %||% ""
  source_row
}

failed_source_row <- function(record, message) {
  append_source_metadata(data.frame(
    table_name = record$table_name[[1]],
    source_type = record$source_type[[1]],
    source = record$source[[1]],
    profile_mode = record$profile_mode[[1]],
    load_status = "failed",
    n_rows = NA_integer_,
    n_cols = NA_integer_,
    id_column_guess = NA_character_,
    date_column_guess = NA_character_,
    min_date = NA_character_,
    max_date = NA_character_,
    schema_signature = NA_character_,
    profiled_at = atlas_timestamp(),
    message = message,
    stringsAsFactors = FALSE
  ), record)
}

skipped_source_row <- function(record, message) {
  append_source_metadata(data.frame(
    table_name = record$table_name[[1]],
    source_type = record$source_type[[1]],
    source = record$source[[1]],
    profile_mode = record$profile_mode[[1]],
    load_status = "skipped",
    n_rows = NA_integer_,
    n_cols = NA_integer_,
    id_column_guess = NA_character_,
    date_column_guess = NA_character_,
    min_date = NA_character_,
    max_date = NA_character_,
    schema_signature = NA_character_,
    profiled_at = atlas_timestamp(),
    message = message,
    stringsAsFactors = FALSE
  ), record)
}

safe_read_output_csv <- function(path, fallback = data.frame(stringsAsFactors = FALSE)) {
  if (is.null(path) || !length(path) || !nzchar(path[[1]] %||% "")) return(fallback)
  if (!file.exists(path)) return(fallback)
  tryCatch(read_delimited_file(path), error = function(e) fallback)
}

resource_catalog <- function(sources) {
  if (!nrow(sources)) return(sources)
  sources[, intersect(
    c(
      "table_name", "source_type", "source", "domain", "subdomain", "atlas_role",
      "load_status", "chosen_strategy", "memory_status", "resolution_status",
      "db_name", "schema", "table", "n_rows", "n_cols", "min_date", "max_date",
      "id_column_guess", "date_column_guess"
    ),
    names(sources)
  ), drop = FALSE]
}

add_source_context_to_column_outputs <- function(rows, sources) {
  if (!nrow(rows) || !nrow(sources)) return(rows)
  meta_names <- intersect(c("domain", "subdomain", "atlas_role"), names(sources))
  if (!length(meta_names)) return(rows)
  match_idx <- match(rows$table_name, sources$table_name)
  for (nm in rev(meta_names)) {
    rows[[nm]] <- ifelse(is.na(match_idx), NA_character_, as.character(sources[[nm]][match_idx]))
    rows <- rows[c(nm, setdiff(names(rows), nm))]
  }
  rows
}

source_availability_panel <- function(sources) {
  if (!nrow(sources)) {
    return(empty_df(source_type = character(), load_status = character(), n_sources = integer()))
  }
  aggregate(
    list(n_sources = sources$table_name),
    by = list(source_type = sources$source_type, load_status = sources$load_status),
    FUN = length
  )
}

output_manifest_artifact_metadata <- function(id, path = "") {
  stem <- sub("[.][^.]*$", "", basename(path %||% ""))
  key <- if (grepl("^(mcl_triangle|ki67|patobank_ki67|atlas|situation_report|npu|isotype|mm_|registry|damyda|lyfo)_", id)) {
    id
  } else if (nzchar(stem)) {
    stem
  } else {
    id
  }
  module <- if (grepl("^mcl_triangle", key)) {
    "mcl_triangle"
  } else if (grepl("^(ki67|patobank_ki67)_", key)) {
    "ki67"
  } else {
    "atlas"
  }
  mcl_count_output <- grepl("^mcl_triangle_count_", id) ||
    (grepl("^mcl_triangle_", key) && grepl("mcl_triangle_(data_point_counts|execution_summary|failed_query_audit|count_summary|inclusion_waterfall|overlap_matrix|exposure_strata_counts|landmark_feasibility_counts|ki67_|age_proxy_counts|ibrutinib_|treatment_strategy_strata_counts|high_risk_biology_counts|answerability_)", key))
  canonical_output <- isTRUE(mcl_count_output)
  production_output <- canonical_output
  superseded_by <- ""
  artifact_role <- if (nzchar(superseded_by)) {
    "compatibility_reference"
  } else if (canonical_output) {
    "canonical_production"
  } else {
    "supporting_output"
  }
  data.frame(
    module = module,
    artifact_role = artifact_role,
    canonical_output = isTRUE(canonical_output),
    production_output = isTRUE(production_output),
    superseded_by = superseded_by,
    stringsAsFactors = FALSE
  )
}

output_manifest <- function(paths, run_dir) {
  paths <- paths[!duplicated(vapply(paths,function(p)tolower(normalizePath(p,winslash="/",mustWork=FALSE)),character(1)))]
  rows <- lapply(names(paths), function(id) {
    path <- paths[[id]]
    info <- if (file.exists(path)) file.info(path) else NULL
    row <- data.frame(
      artifact_id = id,
      relative_path = relative_path(path, run_dir),
      path = normalize_slashes(normalizePath(path, winslash = "/", mustWork = FALSE)),
      status = if (file.exists(path)) "ok" else "missing",
      file_size_bytes = if (!is.null(info)) as.numeric(info$size) else NA_real_,
      stringsAsFactors = FALSE
    )
    cbind(row, output_manifest_artifact_metadata(id, path))
  })
  bind_rows_base(rows)
}

atlas_run_summary <- function(run_id, generated_at, source_map, sources, columns, checks, frequencies, panels,
                              column_profiles = NULL, column_top_values = NULL) {
  panel_rows <- sum(vapply(panels, nrow, integer(1)), na.rm = TRUE)
  if (is.null(column_profiles)) column_profiles <- data.frame(stringsAsFactors = FALSE)
  if (is.null(column_top_values)) column_top_values <- data.frame(stringsAsFactors = FALSE)
  rows <- list(
    data.frame(metric = "run_id", value = run_id, stringsAsFactors = FALSE),
    data.frame(metric = "generated_at", value = generated_at, stringsAsFactors = FALSE),
    data.frame(metric = "builder_credit", value = atlas_builder_credit(), stringsAsFactors = FALSE),
    data.frame(metric = "mapped_sources", value = as.character(nrow(source_map)), stringsAsFactors = FALSE),
    data.frame(metric = "loaded_sources", value = as.character(sum(sources$load_status == "ok", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "failed_sources", value = as.character(sum(sources$load_status == "failed", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "skipped_sources", value = as.character(sum(sources$load_status == "skipped", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "columns_profiled", value = as.character(nrow(columns)), stringsAsFactors = FALSE),
    data.frame(metric = "column_profile_rows", value = as.character(nrow(column_profiles)), stringsAsFactors = FALSE),
    data.frame(metric = "column_top_value_rows", value = as.character(nrow(column_top_values)), stringsAsFactors = FALSE),
    data.frame(metric = "checks", value = as.character(nrow(checks)), stringsAsFactors = FALSE),
    data.frame(metric = "warnings", value = as.character(sum(checks$severity == "warning", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "errors", value = as.character(sum(checks$severity == "error", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "manual_special_notes", value = as.character(sum(checks$severity == "manual_note", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "informational_notes", value = as.character(sum(checks$severity == "info", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "non_blocking_warnings", value = as.character(sum(checks$severity %in% c("warning", "manual_note", "info"), na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "value_frequency_rows", value = as.character(nrow(frequencies)), stringsAsFactors = FALSE),
    data.frame(metric = "panel_rows", value = as.character(panel_rows), stringsAsFactors = FALSE),
    data.frame(metric = "db_aggregate_sources", value = as.character(sum(sources$chosen_strategy == "db_aggregate", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "db_chunked_sources", value = as.character(sum(sources$chosen_strategy == "db_chunked", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "dataset_full_load_fallback_sources", value = as.character(sum(sources$chosen_strategy == "dataset_full_load_fallback", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "skipped_risky_full_load_sources", value = as.character(sum(sources$chosen_strategy == "skipped_risky_full_load", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "min_cell_count", value = as.character(atlas_min_cell_count()), stringsAsFactors = FALSE)
  )
  bind_rows_base(rows)
}

fish_embedded_evidence_present <- function(sources, columns = NULL) {
  column_hit <- FALSE
  if (is.data.frame(columns) && nrow(columns) && all(c("table_name", "column_name") %in% names(columns))) {
    source_key <- resource_key(columns$table_name)
    column_key <- tolower(as.character(columns$column_name %||% ""))
    fish_like <- grepl("fish|cyto|del17|del13|del11|trisomi|tp53", column_key)
    registry_like <- source_key %in% resource_key(c("RKKP_CLL", "RKKP_DaMyDa"))
    column_hit <- any(registry_like & fish_like, na.rm = TRUE)
  }
  if (isTRUE(column_hit)) return(TRUE)
  if (is.data.frame(sources) && nrow(sources) && "schema_signature" %in% names(sources)) {
    source_key <- resource_key(sources$table_name %||% "")
    registry_like <- source_key %in% resource_key(c("RKKP_CLL", "RKKP_DaMyDa"))
    signature <- tolower(as.character(sources$schema_signature %||% ""))
    return(any(registry_like & grepl("fish|cyto|del17|del13|del11|trisomi|tp53", signature), na.rm = TRUE))
  }
  FALSE
}

normalize_special_manual_run_statuses <- function(source_map = NULL, sources = NULL, source_resolution = NULL,
                                                  checks = NULL, columns = NULL) {
  if (!is.data.frame(sources)) sources <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(source_resolution)) source_resolution <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(checks)) checks <- data.frame(stringsAsFactors = FALSE)
  if (!nrow(sources)) {
    return(list(sources = sources, source_resolution = source_resolution, checks = checks))
  }

  source_key <- resource_key(sources$table_name %||% "")
  canonical_key <- resource_key(sources$canonical_resource_id %||% "")
  resolver_type <- tolower(as.character(sources$resolver_type %||% ""))
  resolved_profiled <- tolower(as.character(sources$load_status %||% "")) == "ok" |
    (tolower(as.character(sources$resolution_status %||% "")) == "resolved" &
       nzchar(as.character(sources$n_rows %||% "")))
  special_source <- resolver_type %in% c("manual_file", "embedded_fields") |
    canonical_key %in% resource_key(c("FISH", "DANRICHT"))
  profile_ix <- which(resolved_profiled & !special_source)
  for (nm in c("attempted_in_current_run", "profiled_in_current_run", "activation_status")) {
    if (!nm %in% names(sources)) sources[[nm]] <- ""
  }
  if (length(profile_ix)) {
    sources$attempted_in_current_run[profile_ix] <- "TRUE"
    sources$profiled_in_current_run[profile_ix] <- "TRUE"
    sources$activation_status[profile_ix] <- "profiled_current_run"
  }

  set_resolution_not_applicable <- function(df, table_key, message) {
    if (!nrow(df) || !"table_name" %in% names(df)) return(df)
    ix <- which(resource_key(df$table_name %||% "") == table_key |
      resource_key(df$source %||% "") == table_key)
    if (!length(ix)) return(df)
    df$resolution_status[ix] <- "not_applicable"
    if ("message" %in% names(df)) df$message[ix] <- message
    if ("suggestion" %in% names(df)) df$suggestion[ix] <- ""
    if ("candidate_locations" %in% names(df)) df$candidate_locations[ix] <- ""
    if ("candidate_row_counts" %in% names(df)) df$candidate_row_counts[ix] <- ""
    df
  }

  set_checks <- function(df, table_name, severity, check_id, message) {
    if (!is.data.frame(df) || !nrow(df) || !"table_name" %in% names(df)) return(df)
    ix <- which(resource_key(df$table_name %||% "") == resource_key(table_name))
    if (!length(ix)) return(df)
    df$severity[ix] <- severity
    if ("check_id" %in% names(df)) df$check_id[ix] <- check_id
    if ("message" %in% names(df)) df$message[ix] <- message
    df
  }

  fish_ix <- which(canonical_key == resource_key("FISH") | source_key == resource_key("FISH"))
  if (length(fish_ix) && fish_embedded_evidence_present(sources, columns)) {
    msg <- "Represented through embedded FISH/cytogenetic fields in RKKP_CLL/RKKP_DaMyDa; no standalone FISH DB table is expected for this run."
    sources$load_status[fish_ix] <- "embedded_fields_represented"
    sources$message[fish_ix] <- msg
    sources$resolution_status[fish_ix] <- "not_applicable"
    sources$chosen_strategy[fish_ix] <- "embedded_fields"
    sources$memory_status[fish_ix] <- "ok"
    sources$attempted_in_current_run[fish_ix] <- "FALSE"
    sources$profiled_in_current_run[fish_ix] <- "FALSE"
    sources$activation_status[fish_ix] <- "embedded_fields_represented"
    source_resolution <- set_resolution_not_applicable(source_resolution, resource_key("FISH"), msg)
    checks <- set_checks(checks, "FISH", "info", "source_embedded_fields_represented", msg)
  }

  danricht_ix <- which(canonical_key == resource_key("DANRICHT") | source_key == resource_key("DANRICHT"))
  if (length(danricht_ix)) {
    msg <- "Manual/special source not loaded: DANRICHT requires on-disk project files such as danricht_clean.parquet or DANRICHT_20240412.csv; this is not a DB-attemptable source failure."
    sources$load_status[danricht_ix] <- "manual_file_not_available"
    sources$message[danricht_ix] <- msg
    sources$resolution_status[danricht_ix] <- "not_applicable"
    sources$chosen_strategy[danricht_ix] <- "manual_file"
    sources$memory_status[danricht_ix] <- "ok"
    sources$attempted_in_current_run[danricht_ix] <- "FALSE"
    sources$profiled_in_current_run[danricht_ix] <- "FALSE"
    sources$activation_status[danricht_ix] <- "manual_file_not_available"
    source_resolution <- set_resolution_not_applicable(source_resolution, resource_key("DANRICHT"), msg)
    checks <- set_checks(checks, "DANRICHT", "manual_note", "manual_file_not_available", msg)
  }

  list(sources = sources, source_resolution = source_resolution, checks = checks)
}

run_summary_log_message <- function(run_summary) {
  values <- stats::setNames(run_summary$value, run_summary$metric)
  paste(
    "mapped_sources=", values[["mapped_sources"]] %||% "0",
    ", loaded_sources=", values[["loaded_sources"]] %||% "0",
    ", failed_sources=", values[["failed_sources"]] %||% "0",
    ", skipped_sources=", values[["skipped_sources"]] %||% "0",
    ", checks=", values[["checks"]] %||% "0",
    ", panel_rows=", values[["panel_rows"]] %||% "0",
    sep = ""
  )
}
