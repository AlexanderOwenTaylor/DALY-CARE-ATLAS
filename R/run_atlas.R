run_atlas <- function(project_root, source_map_path, output_root = "atlas_runs",
                      mode = "report", bootstrap_path = Sys.getenv("DALYCARE_BOOTSTRAP_PATH")) {
  mode <- match.arg(mode, c("report", "strict"))
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
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
  for (warning in validation_warnings(source_map, output_root = output_root, project_root = project_root)) {
    log_event("warning", warning$table_name, warning$message)
  }

  source_rows <- list()
  column_rows <- list()
  check_rows <- list()
  frequency_rows <- list()
  panels <- list(
    lab_npu_code_coverage = data.frame(stringsAsFactors = FALSE),
    diagnosis_icd_groups = data.frame(stringsAsFactors = FALSE),
    medication_atc_groups = data.frame(stringsAsFactors = FALSE),
    damyda_feature_coverage = data.frame(stringsAsFactors = FALSE),
    registry_clinical_summary = empty_registry_summary(),
    damyda_clinical_profile = empty_registry_categorical(),
    damyda_numeric_fields = empty_registry_numeric(),
    lyfo_clinical_profile = empty_registry_categorical(),
    cll_clinical_profile = empty_registry_categorical(),
    sp_operational_sources = data.frame(stringsAsFactors = FALSE),
    source_availability_drift = data.frame(stringsAsFactors = FALSE)
  )

  for (i in seq_len(nrow(source_map))) {
    record <- source_map[i, , drop = FALSE]
    table_name <- record$table_name[[1]]
    log_event("info", table_name, "Loading source")
    result <- tryCatch({
      data <- load_source_data(record, project_root = project_root, bootstrap_path = bootstrap_path)
      prof <- profile_source(
        data = data,
        table_name = table_name,
        source_type = record$source_type[[1]],
        source = record$source[[1]],
        profile_mode = record$profile_mode[[1]]
      )
      rm(data)
      gc(verbose = FALSE)
      prof
    }, error = function(e) {
      if (identical(mode, "strict")) stop(e)
      list(error = conditionMessage(e))
    })

    if (!is.null(result$error)) {
      log_event("error", table_name, result$error)
      source_rows[[length(source_rows) + 1L]] <- failed_source_row(record, result$error)
      check_rows[[length(check_rows) + 1L]] <- check_row(table_name, "source_load_failed", "error", result$error)
      next
    }

    source_rows[[length(source_rows) + 1L]] <- result$source
    column_rows[[length(column_rows) + 1L]] <- result$columns
    check_rows[[length(check_rows) + 1L]] <- result$checks
    frequency_rows[[length(frequency_rows) + 1L]] <- result$value_frequencies
    for (panel_name in names(result$panels)) {
      panels[[panel_name]] <- bind_rows_base(list(panels[[panel_name]], result$panels[[panel_name]]))
    }
    log_event("info", table_name, "Profiled source")
  }

  sources <- bind_rows_base(source_rows)
  columns <- bind_rows_base(column_rows)
  checks <- bind_rows_base(check_rows)
  frequencies <- bind_rows_base(frequency_rows)
  panels$source_availability_drift <- source_availability_panel(sources)

  output_paths <- list()
  output_paths$resource_catalog <- write_csv(resource_catalog(sources), file.path(output_dir, "atlas_resource_catalog.csv"))
  output_paths$sources <- write_csv(sources, file.path(output_dir, "atlas_sources.csv"))
  output_paths$columns <- write_csv(columns, file.path(output_dir, "atlas_columns.csv"))
  output_paths$checks <- write_csv(checks, file.path(output_dir, "atlas_checks.csv"))
  output_paths$value_frequencies <- write_csv(frequencies, file.path(output_dir, "atlas_value_frequencies.csv"))
  run_summary <- atlas_run_summary(run_id, generated_at, source_map, sources, columns, checks, frequencies, panels)
  output_paths$run_summary <- write_csv(run_summary, file.path(output_dir, "atlas_run_summary.csv"))

  panel_paths <- list()
  for (panel_name in names(panels)) {
    panel_paths[[panel_name]] <- write_csv(panels[[panel_name]], file.path(panel_dir, paste0(panel_name, ".csv")))
  }

  payload <- atlas_payload(run_id, generated_at, sources, columns, checks, panels, run_summary = run_summary)
  site_paths <- write_static_atlas(run_dir, payload, project_root = project_root)
  log_event("info", "", "Static atlas written")

  all_paths <- c(output_paths, panel_paths, list(html = site_paths$html, payload = site_paths$payload))
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

failed_source_row <- function(record, message) {
  data.frame(
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
  )
}

resource_catalog <- function(sources) {
  if (!nrow(sources)) return(sources)
  sources[, intersect(
    c("table_name", "source_type", "source", "load_status", "n_rows", "n_cols", "min_date", "max_date", "id_column_guess", "date_column_guess"),
    names(sources)
  ), drop = FALSE]
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

atlas_run_summary <- function(run_id, generated_at, source_map, sources, columns, checks, frequencies, panels) {
  panel_rows <- sum(vapply(panels, nrow, integer(1)), na.rm = TRUE)
  rows <- list(
    data.frame(metric = "run_id", value = run_id, stringsAsFactors = FALSE),
    data.frame(metric = "generated_at", value = generated_at, stringsAsFactors = FALSE),
    data.frame(metric = "mapped_sources", value = as.character(nrow(source_map)), stringsAsFactors = FALSE),
    data.frame(metric = "loaded_sources", value = as.character(sum(sources$load_status == "ok", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "failed_sources", value = as.character(sum(sources$load_status == "failed", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "columns_profiled", value = as.character(nrow(columns)), stringsAsFactors = FALSE),
    data.frame(metric = "checks", value = as.character(nrow(checks)), stringsAsFactors = FALSE),
    data.frame(metric = "warnings", value = as.character(sum(checks$severity == "warning", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "errors", value = as.character(sum(checks$severity == "error", na.rm = TRUE)), stringsAsFactors = FALSE),
    data.frame(metric = "value_frequency_rows", value = as.character(nrow(frequencies)), stringsAsFactors = FALSE),
    data.frame(metric = "panel_rows", value = as.character(panel_rows), stringsAsFactors = FALSE),
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
    ", checks=", values[["checks"]] %||% "0",
    ", panel_rows=", values[["panel_rows"]] %||% "0",
    sep = ""
  )
}
