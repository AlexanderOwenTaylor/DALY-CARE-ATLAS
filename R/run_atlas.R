run_atlas <- function(project_root, source_map_path, output_root = "atlas_runs",
                      mode = "report",
                      bootstrap_path = dalycare_resolve_bootstrap_path(Sys.getenv("DALYCARE_BOOTSTRAP_PATH", unset = "")),
                      db_adapter = NULL) {
  mode <- match.arg(mode, c("report", "strict"))
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  bootstrap_path <- dalycare_resolve_bootstrap_path(bootstrap_path)
  source_map_path <- if (file.exists(source_map_path)) source_map_path else file.path(project_root, source_map_path)
  output_root <- if (grepl("^[A-Za-z]:|^/", output_root)) output_root else file.path(project_root, output_root)

  run_id <- atlas_run_id()
  run_dir <- file.path(output_root, run_id)
  output_dir <- file.path(run_dir, "outputs")
  panel_dir <- file.path(output_dir, "panels")
  log_dir <- file.path(run_dir, "logs")
  dir_create(panel_dir)
  dir_create(log_dir)

  log_rows <- list()
  log_event <- function(level, table_name, message) {
    log_rows[[length(log_rows) + 1L]] <<- data.frame(
      timestamp = atlas_timestamp(),
      level = level,
      table_name = table_name %||% "",
      message = message,
      stringsAsFactors = FALSE
    )
  }

  generated_at <- atlas_timestamp()
  log_event("info", "", paste("Starting DALY-CARE atlas run", run_id))
  source_map <- read_source_map(source_map_path, project_root = project_root)
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
    damyda_clinical_profile = empty_registry_categorical(),
    damyda_numeric_fields = empty_registry_numeric(),
    lyfo_clinical_profile = empty_registry_categorical(),
    cll_clinical_profile = empty_registry_categorical(),
    sp_operational_sources = data.frame(stringsAsFactors = FALSE),
    atlas_temporal_coverage = empty_temporal_coverage(),
    atlas_temporal_coverage_years = empty_temporal_coverage_years(),
    atlas_spatial_region_counts = empty_spatial_region_counts(),
    atlas_spatial_region_coverage = empty_spatial_region_coverage(),
    atlas_dk_choropleth_regions = empty_dk_choropleth_regions(),
    situation_report_summary = empty_situation_report_summary(),
    situation_report_breakdowns = empty_situation_report_breakdowns(),
    situation_report_freshness = empty_situation_report_freshness(),
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
  columns <- safe_read_output_csv(stream_paths$columns, bind_rows_base(column_rows))
  column_profiles <- add_source_context_to_column_outputs(safe_read_output_csv(stream_paths$column_profiles, bind_rows_base(column_profile_rows)), sources)
  column_top_values <- add_source_context_to_column_outputs(safe_read_output_csv(stream_paths$column_top_values, bind_rows_base(column_top_value_rows)), sources)
  checks <- safe_read_output_csv(stream_paths$checks, bind_rows_base(check_rows))
  access_checks <- access_report_checks(access_report)
  if (nrow(access_checks)) checks <- bind_rows_base(list(checks, access_checks))
  frequencies <- safe_read_output_csv(stream_paths$value_frequencies, bind_rows_base(frequency_rows))
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
  panels$atlas_module_readiness <- atlas_module_readiness(sources, panels)
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
  output_paths$resource_catalog <- write_csv(resource_catalog(sources), file.path(output_dir, "atlas_resource_catalog.csv"))
  output_paths$sources <- write_csv(sources, file.path(output_dir, "atlas_sources.csv"))
  output_paths$columns <- write_csv(columns, file.path(output_dir, "atlas_columns.csv"))
  output_paths$column_profiles <- write_csv(column_profiles, file.path(output_dir, "atlas_column_profiles.csv"))
  output_paths$column_top_values <- write_csv(column_top_values, file.path(output_dir, "atlas_column_top_values.csv"))
  output_paths$checks <- write_csv(checks, file.path(output_dir, "atlas_checks.csv"))
  output_paths$value_frequencies <- write_csv(frequencies, file.path(output_dir, "atlas_value_frequencies.csv"))
  run_summary <- atlas_run_summary(
    run_id, generated_at, source_map, sources, columns, checks, frequencies, panels,
    column_profiles = column_profiles,
    column_top_values = column_top_values
  )
  output_paths$run_summary <- write_csv(run_summary, file.path(output_dir, "atlas_run_summary.csv"))

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
    write_tsv(bind_rows_base(log_rows), file.path(log_dir, "atlas_execution_log.tsv"))
    stop(empty_live_run_message(source_map, source_resolution), "\nDiagnostics written to: ", run_dir, call. = FALSE)
  }

  payload_sources <- safe_read_output_csv(output_paths$sources, sources)
  payload_columns <- safe_read_output_csv(output_paths$columns, columns)
  payload_checks <- safe_read_output_csv(output_paths$checks, checks)
  payload_column_profiles <- safe_read_output_csv(output_paths$column_profiles, column_profiles)
  payload_column_top_values <- safe_read_output_csv(output_paths$column_top_values, column_top_values)
  payload_run_summary <- safe_read_output_csv(output_paths$run_summary, run_summary)
  payload_action_items <- safe_read_output_csv(output_paths$action_items, action_items)
  payload_db_query_log <- safe_read_output_csv(output_paths$db_query_log, db_query_log)
  payload_db_budget_actions <- safe_read_output_csv(output_paths$db_budget_actions, db_budget_actions)
  payload_panels <- lapply(names(panels), function(panel_name) {
    safe_read_output_csv(panel_paths[[panel_name]], panels[[panel_name]])
  })
  names(payload_panels) <- names(panels)

  payload <- atlas_payload(
    run_id, generated_at, payload_sources, payload_columns, payload_checks, payload_panels,
    column_profiles = payload_column_profiles,
    column_top_values = payload_column_top_values,
    run_summary = payload_run_summary,
    action_items = payload_action_items,
    source_resolution = source_resolution,
    memory_plan = memory_plan,
    db_query_log = payload_db_query_log,
    db_budget_actions = payload_db_budget_actions
  )
  site_paths <- write_static_atlas(run_dir, payload, project_root = project_root)
  log_event("info", "", "Static atlas written")

  memory_log_path <- write_tsv(bind_rows_base(memory_log_rows), file.path(log_dir, "atlas_memory_log.tsv"))
  all_paths <- c(output_paths, panel_paths, list(html = site_paths$html, payload = site_paths$payload, memory_log = memory_log_path))
  manifest <- output_manifest(all_paths, run_dir = run_dir)
  manifest_path <- write_csv(manifest, file.path(output_dir, "output_manifest.csv"))
  log_event("info", "", "Output manifest written")
  log_event("info", "", paste("Run summary:", run_summary_log_message(run_summary)))
  write_tsv(bind_rows_base(log_rows), file.path(log_dir, "atlas_execution_log.tsv"))

  invisible(list(
    run_id = run_id,
    run_dir = run_dir,
    manifest = manifest_path,
    html = site_paths$html,
    payload = site_paths$payload
  ))
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

output_manifest <- function(paths, run_dir) {
  rows <- lapply(names(paths), function(id) {
    path <- paths[[id]]
    info <- if (file.exists(path)) file.info(path) else NULL
    data.frame(
      artifact_id = id,
      relative_path = relative_path(path, run_dir),
      path = normalize_slashes(normalizePath(path, winslash = "/", mustWork = FALSE)),
      status = if (file.exists(path)) "ok" else "missing",
      file_size_bytes = if (!is.null(info)) as.numeric(info$size) else NA_real_,
      stringsAsFactors = FALSE
    )
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
