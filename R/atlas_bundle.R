atlas_run_scope <- function(profile = c("full_atlas", "confluence_only")) {
  profile <- match.arg(profile)
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
                                       confluence_feasibility) {
  public_value <- function(value) {
    if (is.data.frame(value)) {
      return(public_rows(sanitize_public_frame(value), max_rows = 2000))
    }
    if (is.list(value)) return(lapply(value, public_value))
    value
  }
  list(
    run_id = run_id,
    generated_at = generated_at,
    builder_credit = atlas_builder_credit(),
    run_scope = run_scope,
    run_summary = public_rows(sanitize_public_frame(run_summary), max_rows = 100),
    confluence_feasibility = public_value(confluence_feasibility),
    sources = list(),
    checks = list(),
    panels = list()
  )
}

atlas_panel_run_summary <- function(run_id, generated_at, run_scope,
                                    production_execution_summary = NULL,
                                    failed_query_audit = NULL,
                                    min_cell_count = atlas_min_cell_count()) {
  metric_value <- function(metric, default = "") {
    rows <- production_execution_summary
    if (!is.data.frame(rows) || !nrow(rows) || !all(c("metric", "value") %in% names(rows))) return(default)
    hit <- rows[rows$metric == metric, , drop = FALSE]
    if (!nrow(hit)) default else as.character(hit$value[[1]] %||% default)
  }
  failed_count <- if (is.data.frame(failed_query_audit)) nrow(failed_query_audit) else 0L
  data.frame(
    metric = c(
      "run_id", "generated_at", "builder_credit", "run_profile", "executed_panel",
      "source_profiling_executed", "production_query_attempted", "production_query_success",
      "failed_query_count", "suppression_threshold", "min_cell_count"
    ),
    value = c(
      run_id,
      generated_at,
      atlas_builder_credit(),
      run_scope$profile,
      paste(run_scope$executed_panels, collapse = ","),
      if (isTRUE(run_scope$source_profiling_executed)) "TRUE" else "FALSE",
      metric_value("production_query_attempted", "FALSE"),
      metric_value("production_query_success", "FALSE"),
      as.character(failed_count),
      as.character(min_cell_count),
      as.character(min_cell_count)
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
  confluence_canonical <- c(
    "confluence_disease_state_person_counts",
    "confluence_first_date_availability",
    "confluence_clone_route_manifest",
    "confluence_clone_source_resolution",
    "confluence_bcell_clone_evidence_counts",
    "confluence_pcd_clone_evidence_counts",
    "confluence_paraprotein_ambiguity_counts",
    "confluence_mgus_reclassification_waterfall",
    "confluence_dual_clone_overlap_counts",
    "confluence_dual_clone_overlap_timing",
    "confluence_primary_overlap_exclusion_reasons",
    "confluence_clone_availability_protocol_runway",
    "confluence_overlap_counts_accepted",
    "confluence_overlap_timing_accepted",
    "confluence_mbl_validation_waterfall",
    "confluence_mgus_validation_waterfall",
    "confluence_dual_clone_validation_waterfall",
    "confluence_infection_endpoint_code_sets",
    "confluence_infection_counts",
    "confluence_recurrent_infection_counts",
    "confluence_infection_person_time",
    "confluence_infection_rates",
    "confluence_microbiology_confirmation_counts",
    "confluence_microbiology_confirmation_source_audit",
    "confluence_production_query_review",
    "confluence_failed_query_audit",
    "confluence_source_resolution_audit",
    "confluence_production_execution_summary"
  )
  confluence_superseded_by <- c(
    confluence_summary = "confluence_production_execution_summary",
    confluence_disease_state_counts = "confluence_disease_state_person_counts",
    confluence_overlap_counts = "confluence_overlap_counts_accepted",
    confluence_overlap_timing = "confluence_overlap_timing_accepted"
  )
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
    (grepl("^mcl_triangle_", key) && grepl("mcl_triangle_(data_point_counts|execution_summary|failed_query_audit|count_summary|inclusion_waterfall|overlap_matrix|exposure_strata_counts|landmark_feasibility_counts|ki67_|age_proxy_counts|ibrutinib_|treatment_strategy_strata_counts|high_risk_biology_counts|answerability_)", key))
  canonical_output <- key %in% confluence_canonical || isTRUE(mcl_count_output)
  superseded_by <- if (key %in% names(confluence_superseded_by)) unname(confluence_superseded_by[[key]]) else ""
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
    production_output = isTRUE(canonical_output),
    superseded_by = superseded_by,
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
