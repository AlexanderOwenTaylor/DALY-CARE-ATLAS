atlas_run_scope <- function(profile = c("full_atlas", "triangle_only", "confluence_only")) {
  profile <- match.arg(profile)
  if (identical(profile, "triangle_only")) {
    return(list(
      profile = profile,
      executed_panels = list("mcl_triangle_feasibility"),
      source_profiling_executed = FALSE
    ))
  }
  if (identical(profile, "confluence_only")) {
    return(list(
      profile = profile,
      executed_panels = list("confluence_feasibility"),
      source_profiling_executed = FALSE
    ))
  }
  list(
    profile = profile,
    executed_panels = list("*"),
    source_profiling_executed = TRUE
  )
}

atlas_scoped_panel_payload <- function(run_id, generated_at, run_scope, run_summary,
                                       panel_payloads = list()) {
  public_value <- function(value) {
    if (is.data.frame(value)) {
      return(public_rows(sanitize_public_frame(value), max_rows = 2000))
    }
    if (is.list(value)) return(lapply(value, public_value))
    value
  }
  payload <- list(
    run_id = run_id,
    generated_at = generated_at,
    builder_credit = atlas_builder_credit(),
    run_scope = run_scope,
    run_summary = public_rows(sanitize_public_frame(run_summary), max_rows = 100),
    sources = list(),
    checks = list(),
    panels = list()
  )
  if (length(panel_payloads)) {
    for (name in names(panel_payloads)) payload[[name]] <- public_value(panel_payloads[[name]])
  }
  payload
}

atlas_panel_run_summary <- function(run_id, generated_at, run_scope,
                                    execution_summary = NULL,
                                    failed_query_audit = NULL,
                                    min_cell_count = atlas_min_cell_count(),
                                    evidence_input_provenance = "") {
  execution_value <- function(name, default = "") {
    rows <- execution_summary
    if (!is.data.frame(rows) || !nrow(rows)) return(default)
    if (all(c("metric", "value") %in% names(rows))) {
      hit <- rows[as.character(rows$metric) == name, , drop = FALSE]
      if (nrow(hit)) return(as.character(hit$value[[1]] %||% default))
    }
    if (name %in% names(rows)) return(as.character(rows[[name]][[1]] %||% default))
    default
  }
  bool_text <- function(value) {
    if (isTRUE(value) || tolower(as.character(value %||% "")) %in% c("true", "t", "1", "yes")) "TRUE" else "FALSE"
  }
  mode <- execution_value("mode", execution_value("count_mode", ""))
  attempted <- execution_value("db_connection_attempted", execution_value("production_query_attempted", "FALSE"))
  available <- execution_value("db_connection_available", "FALSE")
  succeeded <- execution_value("production_aggregate_succeeded", execution_value("production_query_success", "FALSE"))
  failed_count <- execution_value(
    "failed_queries",
    if (is.data.frame(failed_query_audit)) as.character(nrow(failed_query_audit)) else "0"
  )
  data.frame(
    metric = c(
      "run_id", "generated_at", "builder_credit", "run_profile", "executed_panel",
      "source_profiling_executed", "mode", "production_query_attempted",
      "database_connection_available", "production_query_success", "executable_query_count",
      "executed_query_count", "failed_query_count", "populated_count_outputs",
      "populated_intersection_outputs", "acceptance_status", "suppression_threshold",
      "min_cell_count", "optional_atlas_evidence_input"
    ),
    value = c(
      run_id,
      generated_at,
      atlas_builder_credit(),
      run_scope$profile,
      paste(run_scope$executed_panels, collapse = ","),
      bool_text(run_scope$source_profiling_executed),
      mode,
      bool_text(attempted),
      bool_text(available),
      bool_text(succeeded),
      execution_value("executable_queries", "0"),
      execution_value("executed_queries", "0"),
      failed_count,
      execution_value("populated_count_outputs", "0"),
      execution_value("populated_intersection_outputs", "0"),
      execution_value("acceptance_status", ""),
      as.character(min_cell_count),
      as.character(min_cell_count),
      as.character(evidence_input_provenance %||% "")
    ),
    stringsAsFactors = FALSE
  )
}

output_manifest_artifact_metadata <- function(id, path = "") {
  stem <- sub("[.][^.]*$", "", basename(path %||% ""))
  key <- if (grepl("^(confluence|mcl_triangle|ki67|patobank_ki67|atlas|situation_report|npu|isotype|mm_|registry|damyda|lyfo)_", id)) {
    id
  } else if (nzchar(stem)) {
    stem
  } else {
    id
  }
  module <- if (grepl("^confluence_", key)) {
    "confluence"
  } else if (grepl("^mcl_triangle", key)) {
    "mcl_triangle"
  } else if (grepl("^(ki67|patobank_ki67)_", key)) {
    "ki67"
  } else {
    "atlas"
  }
  mcl_count_output <- grepl("^mcl_triangle_count_", id) ||
    (grepl("^mcl_triangle_", key) && grepl("mcl_triangle_(data_point_counts|execution_summary|failed_query_audit|small_cell_suppression_audit|count_summary|inclusion_waterfall|overlap_matrix|exposure_strata_counts|landmark_feasibility_counts|ki67_|age_proxy_counts|ibrutinib_|treatment_strategy_strata_counts|high_risk_biology_counts|answerability_|asct_hdt_|triangle_arm_proxy)", key))
  canonical_output <- isTRUE(mcl_count_output)
  artifact_role <- if (canonical_output) "canonical_production" else "supporting_output"
  data.frame(
    module = module,
    artifact_role = artifact_role,
    canonical_output = isTRUE(canonical_output),
    production_output = isTRUE(canonical_output),
    superseded_by = "",
    stringsAsFactors = FALSE
  )
}

output_manifest <- function(paths, run_dir) {
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

atlas_write_bundle <- function(run_dir, project_root, payload, artifact_paths = list(), execution_log = NULL) {
  output_dir <- file.path(run_dir, "outputs")
  log_dir <- file.path(run_dir, "logs")
  dir_create(output_dir)
  dir_create(log_dir)
  if (is.null(execution_log)) {
    execution_log <- empty_df(
      timestamp = character(), level = character(), table_name = character(), message = character()
    )
  }
  execution_log_path <- write_tsv(execution_log, file.path(log_dir, "atlas_execution_log.tsv"))
  site_paths <- write_static_atlas(run_dir, payload, project_root = project_root)
  all_paths <- c(
    artifact_paths,
    list(html = site_paths$html, payload = site_paths$payload, execution_log = execution_log_path)
  )
  manifest_path <- write_csv(output_manifest(all_paths, run_dir), file.path(output_dir, "output_manifest.csv"))
  list(
    html = site_paths$html,
    payload = site_paths$payload,
    manifest = manifest_path,
    execution_log = execution_log_path
  )
}
