smm_immunity_tracker_count_mode <- function(db_adapter = NULL,
                                            mode = Sys.getenv("SMM_IMMUNITY_COUNT_MODE", unset = "auto"),
                                            project_root = ".") {
  mode <- tolower(trimws(as.character(mode %||% "auto")))
  if (mode %in% c("plan", "off", "disabled", "false", "0")) return("plan")
  if (mode %in% c("production", "production_aggregate", "run", "true", "1")) return("production_aggregate")
  if (!is.null(db_adapter) && is.function(db_adapter$smm_immunity_tracker_counts)) return("production_aggregate")
  root <- smm_immunity_tracker_wp5_output_root(project_root)
  if (nzchar(root) && dir.exists(root)) "production_aggregate" else "plan"
}

smm_immunity_tracker_count_empty_outputs <- function() {
  empty <- smm_immunity_tracker_empty_payload()
  empty[names(empty)]
}

smm_immunity_tracker_count_scalar <- function(x, default = "") {
  if (is.null(x) || !length(x)) return(default)
  value <- x[[1]]
  if (is.null(value) || is.na(value)) return(default)
  value
}

smm_immunity_tracker_wp5_output_root <- function(project_root = ".") {
  resolution <- smm_immunity_tracker_resolve_wp5_outputs(project_root)
  resolution$wp5_public_root %||% ""
}

smm_immunity_tracker_wp5_aggregate_files <- function() {
  c("wp5_smm_analysis_tiers.csv", "wp5_cohort_attrition.csv")
}

smm_immunity_tracker_wp5_secure_input_files <- function() {
  c(
    "wp5_followup_sanity.csv",
    "wp5_treatment_landmark_cohort.csv",
    "wp5_smm_like_cohort.csv",
    "wp5_patient_classification.csv",
    "wp5_smm_model_frames.csv",
    "wp5_treatment_evidence_patient.csv",
    "wp5_treatment_source_overlap.csv",
    "wp5_lab_feature_patient.csv",
    "wp5_smm_baseline_features.csv",
    "wp5_smm_biomarker_window_qc.csv",
    "wp5_risk_derivability.csv",
    "wp5_risk_derivability_reasons.csv",
    "wp5_mgus_context.csv",
    "wp5_treatment_window_sensitivity.csv"
  )
}

smm_immunity_tracker_wp5_resolution_empty <- function(status = "not_found",
                                                      wp5_public_root = "",
                                                      wp5_run_outputs_root = "",
                                                      source_root_label = "",
                                                      wp5_run_id = "",
                                                      path_status = "not_found",
                                                      reason = "") {
  list(
    status = status,
    wp5_public_root = wp5_public_root,
    wp5_run_outputs_root = wp5_run_outputs_root,
    source_root_label = source_root_label,
    wp5_run_id = wp5_run_id,
    path_status = path_status,
    reason = reason
  )
}

smm_immunity_tracker_wp5_has_aggregate_contract <- function(path) {
  if (!nzchar(path) || !dir.exists(path)) return(FALSE)
  any(file.exists(file.path(path, smm_immunity_tracker_wp5_aggregate_files())))
}

smm_immunity_tracker_wp5_run_id_from_path <- function(public_root, fallback = "current_wp5_run") {
  public_root <- normalize_slashes(public_root %||% "")
  if (!nzchar(public_root)) return(fallback)
  parts <- strsplit(public_root, "/", fixed = TRUE)[[1]]
  idx <- which(parts == "outputs")
  if (length(idx) && idx[[1]] > 1L) return(parts[[idx[[1]] - 1L]])
  fallback
}

smm_immunity_tracker_resolve_wp5_candidate <- function(path, source_root_label, project_root = ".") {
  if (!nzchar(path) || !dir.exists(path)) {
    return(smm_immunity_tracker_wp5_resolution_empty(
      source_root_label = source_root_label,
      path_status = "not_found",
      reason = "candidate_root_not_found"
    ))
  }
  root <- normalizePath(path, winslash = "/", mustWork = FALSE)
  checks <- list(
    list(public_root = root, run_outputs_root = dirname(root), path_status = "resolved_to_outputs_wp5"),
    list(public_root = file.path(root, "wp5"), run_outputs_root = root, path_status = "resolved_from_outputs_parent"),
    list(public_root = file.path(root, "outputs", "wp5"), run_outputs_root = file.path(root, "outputs"), path_status = "resolved_from_run_dir"),
    list(public_root = file.path(root, "data", "processed", "wp5"), run_outputs_root = file.path(root, "data", "processed", "wp5"), path_status = "resolved_from_project_root")
  )
  for (candidate in checks) {
    if (smm_immunity_tracker_wp5_has_aggregate_contract(candidate$public_root)) {
      run_id <- smm_immunity_tracker_wp5_run_id_from_path(candidate$public_root)
      return(smm_immunity_tracker_wp5_resolution_empty(
        status = "resolved",
        wp5_public_root = normalizePath(candidate$public_root, winslash = "/", mustWork = FALSE),
        wp5_run_outputs_root = normalizePath(candidate$run_outputs_root, winslash = "/", mustWork = FALSE),
        source_root_label = source_root_label,
        wp5_run_id = run_id,
        path_status = candidate$path_status,
        reason = "aggregate_contract_found"
      ))
    }
  }
  # If a run-parent directory was supplied, look for the newest run with an
  # outputs/wp5 aggregate contract without exposing its absolute path publicly.
  run_parents <- c(root, file.path(root, "data", "processed", "wp5"))
  for (run_parent in unique(run_parents)) {
    if (!dir.exists(run_parent)) next
    runs <- list.dirs(run_parent, full.names = TRUE, recursive = FALSE)
    runs <- runs[dir.exists(file.path(runs, "outputs", "wp5"))]
    if (length(runs)) {
      info <- file.info(runs)
      runs <- runs[order(info$mtime, decreasing = TRUE)]
      for (run in runs) {
        public_root <- file.path(run, "outputs", "wp5")
        if (smm_immunity_tracker_wp5_has_aggregate_contract(public_root)) {
          return(smm_immunity_tracker_wp5_resolution_empty(
            status = "resolved",
            wp5_public_root = normalizePath(public_root, winslash = "/", mustWork = FALSE),
            wp5_run_outputs_root = normalizePath(file.path(run, "outputs"), winslash = "/", mustWork = FALSE),
            source_root_label = source_root_label,
            wp5_run_id = basename(run),
            path_status = "resolved_from_project_root",
            reason = "latest_local_wp5_aggregate_contract_found"
          ))
        }
      }
    }
  }
  smm_immunity_tracker_wp5_resolution_empty(
    status = "invalid_contract",
    source_root_label = source_root_label,
    path_status = "invalid_contract",
    reason = "wp5_aggregate_files_not_found"
  )
}

smm_immunity_tracker_resolve_wp5_outputs <- function(project_root = ".") {
  candidates <- c(
    Sys.getenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT", unset = ""),
    Sys.getenv("WOMMEN_WP5_OUTPUT_ROOT", unset = ""),
    file.path(project_root, "outputs", "wp5"),
    file.path(project_root, "outputs"),
    file.path(project_root, "wp5_outputs"),
    file.path(project_root, "outputs", "wp5_side_by_side"),
    project_root
  )
  labels <- c(
    "env:SMM_IMMUNITY_WP5_OUTPUT_ROOT",
    "env:WOMMEN_WP5_OUTPUT_ROOT",
    "latest_local_wp5",
    "latest_local_outputs",
    "latest_local_wp5_outputs",
    "latest_local_wp5_side_by_side",
    "project_root"
  )
  last_invalid <- NULL
  for (i in seq_along(candidates)) {
    if (!nzchar(candidates[[i]])) next
    resolved <- smm_immunity_tracker_resolve_wp5_candidate(candidates[[i]], labels[[i]], project_root = project_root)
    if (identical(resolved$status, "resolved")) return(resolved)
    if (!identical(resolved$status, "not_found")) last_invalid <- resolved
  }
  last_invalid %||% smm_immunity_tracker_wp5_resolution_empty(
    status = "not_found",
    source_root_label = "not_configured",
    path_status = "not_found",
    reason = "no_wp5_output_root_configured_or_found"
  )
}

smm_immunity_tracker_count_suppress <- function(n, total = NA_real_, min_cell_count = atlas_min_cell_count()) {
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  n <- suppressWarnings(as.numeric(n))
  total <- suppressWarnings(as.numeric(total))
  if (is.na(n)) {
    return(list(display = "not available", n_public = NA_real_, status = "not available"))
  }
  if (n == 0) {
    return(list(display = "0", n_public = 0, status = "not suppressed"))
  }
  primary <- n < min_cell_count
  complement <- !is.na(total) && total > 0 && total > n && (total - n) < min_cell_count
  if (primary || complement) {
    status <- if (primary && complement) "suppressed small cell and complementary cell" else if (primary) "suppressed small cell" else "suppressed complementary cell"
    return(list(display = paste0("<", min_cell_count), n_public = NA_real_, status = status))
  }
  list(display = as.character(round(n, 2)), n_public = n, status = "not suppressed")
}

smm_immunity_tracker_count_status_join <- function(...) {
  vals <- unique(as.character(c(...)))
  vals <- vals[nzchar(vals)]
  if (!length(vals)) "" else paste(vals, collapse = "; ")
}

smm_immunity_tracker_fail_closed_frame <- function(query_id, artifact, reason, mode = "plan", error_class = "") {
  data.frame(
    query_id = query_id,
    artifact = artifact,
    count_status = if (identical(mode, "plan")) "query executable not run" else "not accepted aggregate",
    mode = mode,
    error_class = error_class,
    error_message_sanitized = reason,
    notes = "Related public outputs failed closed and must not be interpreted as accepted zero counts.",
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_execution_summary <- function(mode,
                                                   attempted = FALSE,
                                                   success = FALSE,
                                                   failure_reason = "",
                                                   min_cell_count = atlas_min_cell_count(),
                                                   cohort_rows = 0L,
                                                   infection_rows = 0L) {
  data.frame(
    metric = c("count_mode", "production_query_attempted", "production_query_success", "min_cell_count", "cohort_rows_internal", "infection_event_rows_internal", "failure_reason"),
    label = c("Count mode", "Production query attempted", "Production query success", "Small-cell threshold", "Internal cohort rows", "Internal infection event rows", "Failure reason"),
    value = c(mode, as.character(isTRUE(attempted)), as.character(isTRUE(success)), as.character(normalize_min_cell_count(min_cell_count)), as.character(cohort_rows), as.character(infection_rows), failure_reason),
    status = c(mode, if (attempted) "attempted" else "not run", if (success) "success" else "fail-closed", "privacy threshold", "secure intermediate only", "secure intermediate only", if (nzchar(failure_reason)) "fail-closed" else "none"),
    notes = c(
      "SMM Immunity Tracker count execution mode.",
      "Aggregate adapter or secure source reader execution state.",
      "TRUE only when aggregate output generation succeeded.",
      "Applied to primary and complementary suppression.",
      "Secure in-memory/source rows only; not written to static outputs.",
      "Secure in-memory/source rows only; not written to static outputs.",
      "Empty when no count execution failure occurred."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_count_placeholder_outputs <- function(mode = "plan",
                                                           reason = "SMM Immunity Tracker production aggregate query did not run.",
                                                           error_class = "",
                                                           project_root = ".",
                                                           min_cell_count = atlas_min_cell_count()) {
  outputs <- smm_immunity_tracker_empty_payload()
  scaffold <- build_smm_immunity_tracker_feasibility_outputs(project_root = project_root, min_cell_count = min_cell_count)
  for (nm in names(scaffold)) outputs[[nm]] <- scaffold[[nm]]
  outputs$failed_query_audit <- smm_immunity_tracker_fail_closed_frame(
    "smm_immunity_tracker_production_aggregate",
    "smm_immunity_tracker_production_execution_summary.csv",
    reason,
    mode = mode,
    error_class = error_class
  )
  outputs$production_execution_summary <- smm_immunity_tracker_execution_summary(
    mode,
    attempted = !identical(mode, "plan"),
    success = FALSE,
    failure_reason = reason,
    min_cell_count = min_cell_count
  )
  outputs
}

smm_immunity_tracker_count_route_row <- function(route_id,
                                                 configured = FALSE,
                                                 query_executed = FALSE,
                                                 query_success = FALSE,
                                                 query_status = "",
                                                 source_table = "",
                                                 error_message_sanitized = "",
                                                 notes = "") {
  if (!nzchar(query_status)) {
    query_status <- if (isTRUE(query_success)) {
      "executed"
    } else if (isTRUE(query_executed)) {
      "production_aggregate_failed_query_error"
    } else {
      "production_aggregate_failed_mapping_unavailable"
    }
  }
  data.frame(
    route_id = route_id,
    configured = isTRUE(configured),
    query_executed = isTRUE(query_executed),
    query_success = isTRUE(query_success),
    query_status = query_status,
    source_table = source_table %||% "",
    error_message_sanitized = error_message_sanitized %||% "",
    notes = notes %||% "",
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_count_failed_route_audit <- function(route_status) {
  if (!is.data.frame(route_status) || !nrow(route_status)) return(smm_immunity_tracker_empty_failed_query_audit())
  failed <- route_status[!suppressWarnings(as.logical(route_status$query_success)), , drop = FALSE]
  if (!nrow(failed)) return(smm_immunity_tracker_empty_failed_query_audit())
  out <- data.frame(
    query_id = paste0("smm_immunity_tracker_", failed$route_id),
    artifact = "smm_immunity_tracker_source_resolution_audit.csv",
    count_status = failed$query_status,
    mode = "production_aggregate",
    error_class = failed$query_status,
    error_message_sanitized = failed$error_message_sanitized,
    notes = failed$notes,
    stringsAsFactors = FALSE
  )
  smm_immunity_tracker_match_empty(out, smm_immunity_tracker_empty_failed_query_audit())
}

smm_immunity_tracker_public_output_is_safe <- function(outputs) {
  forbidden_names <- smm_immunity_tracker_unsafe_public_exact_columns()
  forbidden_patterns <- smm_immunity_tracker_unsafe_public_regex_columns()
  path_pattern <- "(/ngc/|/home/|/mnt/|[A-Za-z]:[\\\\/])"
  raw_date_pattern <- "\\b[0-9]{4}-[0-9]{2}-[0-9]{2}\\b"
  hits <- character()
  for (nm in names(outputs)) {
    value <- outputs[[nm]]
    if (!is.data.frame(value)) next
    lower_names <- tolower(names(value))
    bad <- names(value)[lower_names %in% forbidden_names]
    for (pattern in forbidden_patterns) {
      bad <- unique(c(bad, names(value)[grepl(pattern, lower_names, perl = TRUE)]))
    }
    if (length(bad)) hits <- c(hits, paste(nm, paste(bad, collapse = ","), sep = ":"))
    for (col in names(value)) {
      vals <- as.character(value[[col]])
      vals <- vals[!is.na(vals) & nzchar(vals)]
      if (!length(vals)) next
      path_hits <- vals[grepl(path_pattern, vals, ignore.case = TRUE)]
      if (length(path_hits)) hits <- c(hits, paste(nm, col, "absolute_path_value", sep = ":"))
      if (!identical(tolower(col), "wp5_run_id")) {
        date_hits <- vals[grepl(raw_date_pattern, vals)]
        if (length(date_hits)) hits <- c(hits, paste(nm, col, "raw_date_value", sep = ":"))
      }
    }
  }
  list(ok = !length(hits), hits = hits)
}

smm_immunity_tracker_assert_public_output_safe <- function(outputs) {
  safe <- smm_immunity_tracker_public_output_is_safe(outputs)
  if (!isTRUE(safe$ok)) {
    stop("SMM Immunity Tracker public output contains forbidden columns: ", paste(safe$hits, collapse = "; "), call. = FALSE)
  }
  invisible(TRUE)
}

smm_immunity_tracker_unsafe_public_exact_columns <- function() {
  tolower(c(
    "person_key", "patientid", "patient_id", "person_id", "person_key", "cpr", "pnr",
    "date", "raw_date", "event_date", "sample_date", "sampling_date", "sampling_datetime",
    "first_dc900_date", "tracker_entry_date", "progression_date", "death_date", "censor_date",
    "organism", "species", "organism_name", "result_text", "microbiology_text",
    "pathology_text", "free_text", "cohort_entries", "infection_events",
    "microbiology_confirmation_events"
  ))
}

smm_immunity_tracker_unsafe_public_regex_columns <- function() {
  c(
    "(^|_)cpr($|_)",
    "(^|_)pnr($|_)",
    "(^|_)patientid($|_)",
    "(^|_)person_key($|_)",
    "raw_",
    "free.?text",
    "organism",
    "species",
    "microbiology.*text",
    "pathology.*text",
    "event.*date",
    "sample.*date",
    "sampling.*date"
  )
}

smm_immunity_tracker_aggregate_hook_privacy_hits <- function(hook) {
  hits <- character()
  row_level_names <- c("cohort_entries", "infection_events", "microbiology_confirmation_events")
  bad_names <- intersect(names(hook), row_level_names)
  if (length(bad_names)) hits <- c(hits, paste0("row_level_frame_name:", bad_names))
  exact <- smm_immunity_tracker_unsafe_public_exact_columns()
  patterns <- smm_immunity_tracker_unsafe_public_regex_columns()
  for (nm in names(hook)) {
    df <- hook[[nm]]
    if (!is.data.frame(df)) next
    lower_names <- tolower(names(df))
    bad <- names(df)[lower_names %in% exact]
    for (pattern in patterns) {
      bad <- unique(c(bad, names(df)[grepl(pattern, lower_names, perl = TRUE)]))
    }
    if (length(bad)) hits <- c(hits, paste(nm, paste(bad, collapse = ","), sep = ":"))
  }
  hits
}

smm_immunity_tracker_append_status <- function(existing, addition) {
  existing <- as.character(existing %||% "")
  addition <- as.character(addition %||% "")
  out <- existing
  blank <- !nzchar(out)
  out[blank] <- addition
  out[!blank & nzchar(addition)] <- paste(out[!blank & nzchar(addition)], addition, sep = "; ")
  out
}

smm_immunity_tracker_suppress_adapter_frame <- function(df, min_cell_count = atlas_min_cell_count()) {
  if (!is.data.frame(df) || !nrow(df)) return(df)
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  count_cols <- intersect(names(df), c(
    "persons_n", "events_n", "n_people", "n_events", "event_count",
    "n_progression", "n_competing_death", "n_at_landmark", "progression_events",
    "competing_deaths"
  ))
  if (!length(count_cols)) return(df)
  if (!"suppression_status" %in% names(df)) df$suppression_status <- ""
  for (col in count_cols) {
    vals <- suppressWarnings(as.numeric(df[[col]]))
    suppress <- !is.na(vals) & vals > 0 & vals < min_cell_count
    if (!any(suppress)) next
    df[[col]][suppress] <- NA
    df$suppression_status[suppress] <- smm_immunity_tracker_append_status(df$suppression_status[suppress], "suppressed small cell")
    display_candidates <- switch(col,
      persons_n = c("persons_display", "count_display", "n_people_display"),
      events_n = c("events_display", "event_count_display"),
      n_people = c("n_people_display", "count_display"),
      n_events = c("event_count_display", "events_display"),
      event_count = c("event_count_display", "events_display"),
      n_progression = c("n_progression_display", "progression_events_display"),
      n_competing_death = c("n_competing_death_display", "competing_deaths_display"),
      n_at_landmark = c("n_at_landmark_display"),
      progression_events = c("progression_events_display", "n_progression_display"),
      competing_deaths = c("competing_deaths_display", "n_competing_death_display"),
      character()
    )
    display_hit <- display_candidates[display_candidates %in% names(df)]
    if (length(display_hit)) df[[display_hit[[1]]]][suppress] <- paste0("<", min_cell_count)
  }
  df
}

smm_immunity_tracker_suppress_adapter_outputs <- function(hook, min_cell_count = atlas_min_cell_count()) {
  if (!is.list(hook)) return(hook)
  for (nm in names(hook)) {
    if (is.data.frame(hook[[nm]])) {
      hook[[nm]] <- smm_immunity_tracker_suppress_adapter_frame(hook[[nm]], min_cell_count = min_cell_count)
    }
  }
  hook
}

smm_immunity_tracker_first_existing_col <- function(df, candidates) {
  hit <- candidates[candidates %in% names(df)]
  if (length(hit)) hit[[1]] else ""
}

smm_immunity_tracker_pick_col <- function(df, candidates, default = "") {
  nm <- smm_immunity_tracker_first_existing_col(df, candidates)
  if (!nzchar(nm)) return(rep(default, nrow(df)))
  df[[nm]]
}

smm_immunity_tracker_pick_date <- function(df, candidates) {
  safe_as_date(smm_immunity_tracker_pick_col(df, candidates, default = NA))
}

smm_immunity_tracker_numeric <- function(x) {
  suppressWarnings(as.numeric(x))
}

smm_immunity_tracker_cohort_label <- function(cohort_id) {
  labels <- c(
    aot_wp5_original_smm = "AOT/WP5 original SMM-compatible day-90 cohort",
    cvm_jama_smm_day90_harmonized = "CVM/JAMA clinically filtered SMM cohort, day-90 harmonized",
    cvm_jama_smm_diagnosis_origin = "CVM/JAMA clinically filtered SMM cohort, diagnosis-origin reproduction"
  )
  out <- labels[as.character(cohort_id)]
  out[is.na(out)] <- as.character(cohort_id)[is.na(out)]
  unname(out)
}

smm_immunity_tracker_normalize_cohort_entries <- function(cohort_entries) {
  if (!is.data.frame(cohort_entries) || !nrow(cohort_entries)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  raw <- cohort_entries
  person_key <- as.character(smm_immunity_tracker_pick_col(raw, c("person_key", "patientid", "patient_id", "id")))
  cohort_id <- as.character(smm_immunity_tracker_pick_col(raw, c("cohort_id", "cohort", "scaffold_family"), ""))
  cohort_id[!nzchar(cohort_id)] <- "aot_wp5_original_smm"
  cohort_id <- ifelse(cohort_id %in% c("aot_wp5_original", "aot_wp5", "wp5_original"), "aot_wp5_original_smm", cohort_id)
  cohort_id <- ifelse(cohort_id %in% c("cvm_jama", "cvm_jama_smm"), "cvm_jama_smm_day90_harmonized", cohort_id)

  first_dc900 <- smm_immunity_tracker_pick_date(raw, c("first_dc900_date", "first_mm_date", "index_date", "date_diagnosis", "diagnosis_date"))
  day90 <- smm_immunity_tracker_pick_date(raw, c("day90_date", "entry_date", "tracker_entry_date"))
  day90[is.na(day90) & !is.na(first_dc900)] <- first_dc900[is.na(day90) & !is.na(first_dc900)] + 90L
  diagnosis_origin <- smm_immunity_tracker_pick_date(raw, c("diagnosis_origin_entry_date", "main_time_zero", "cvm_time_zero", "diagnosis_date", "first_dc900_date", "first_mm_date"))
  diagnosis_origin[is.na(diagnosis_origin)] <- first_dc900[is.na(diagnosis_origin)]
  progression <- smm_immunity_tracker_pick_date(raw, c("progression_date", "cvm_progression_date_main"))
  death <- smm_immunity_tracker_pick_date(raw, c("death_date", "date_death_fu"))
  censor <- smm_immunity_tracker_pick_date(raw, c("censor_date", "followup_reference_date", "exit_date", "cvm_exit_date_main"))
  censor[is.na(censor)] <- smm_immunity_tracker_pick_date(raw, c("follow_up_end", "last_followup_date"))[is.na(censor)]
  event_status <- smm_immunity_tracker_numeric(smm_immunity_tracker_pick_col(raw, c("event_status", "cvm_event_status_main"), NA))

  base <- data.frame(
    person_key = person_key,
    cohort_id = cohort_id,
    first_dc900_date = first_dc900,
    tracker_entry_date = day90,
    diagnosis_origin_entry_date = diagnosis_origin,
    progression_date = progression,
    progression_type = as.character(smm_immunity_tracker_pick_col(raw, c("progression_type", "progression_source", "cvm_progression_source_main"), "")),
    death_date = death,
    censor_date = censor,
    event_status = event_status,
    risk_202020_group = as.character(smm_immunity_tracker_pick_col(raw, c("risk_202020_group"), "")),
    aquila_group = as.character(smm_immunity_tracker_pick_col(raw, c("aquila_group"), "")),
    sex = as.character(smm_immunity_tracker_pick_col(raw, c("sex"), "")),
    age_years = smm_immunity_tracker_numeric(smm_immunity_tracker_pick_col(raw, c("age_years"), NA)),
    source_file_or_route = as.character(smm_immunity_tracker_pick_col(raw, c("source_file", "source_file_or_route"), "secure cohort frame")),
    stringsAsFactors = FALSE
  )
  base <- base[nzchar(base$person_key) & !is.na(base$first_dc900_date) & !is.na(base$tracker_entry_date), , drop = FALSE]
  if (!nrow(base)) return(base)

  aot <- base[base$cohort_id == "aot_wp5_original_smm", , drop = FALSE]
  cvm <- base[base$cohort_id %in% c("cvm_jama_smm_day90_harmonized", "cvm_jama_smm"), , drop = FALSE]
  if (nrow(cvm)) {
    cvm$cohort_id <- "cvm_jama_smm_day90_harmonized"
    cvm$tracker_entry_date <- cvm$first_dc900_date + 90L
  }
  dx <- cvm
  if (nrow(dx)) {
    dx$cohort_id <- "cvm_jama_smm_diagnosis_origin"
    dx$tracker_entry_date <- dx$diagnosis_origin_entry_date
  }
  out <- bind_rows_base(list(aot, cvm, dx, base[!base$cohort_id %in% c("aot_wp5_original_smm", "cvm_jama_smm_day90_harmonized", "cvm_jama_smm"), , drop = FALSE]))
  out$cohort_label <- smm_immunity_tracker_cohort_label(out$cohort_id)
  out$time_origin <- ifelse(out$cohort_id == "cvm_jama_smm_diagnosis_origin", "diagnosis_origin_after_90d_eligibility_restriction", "day90_harmonized")
  out
}

smm_immunity_tracker_normalize_events <- function(events, default_endpoint = "serious_infection_hospitalization") {
  if (!is.data.frame(events) || !nrow(events)) {
    return(data.frame(person_key = character(), event_date = as.Date(character()), endpoint_id = character(), stringsAsFactors = FALSE))
  }
  person_key <- as.character(smm_immunity_tracker_pick_col(events, c("person_key", "patientid", "patient_id", "id")))
  event_date <- safe_as_date(smm_immunity_tracker_pick_col(events, c("event_date", "infection_date", "sample_date", "contact_date"), NA))
  endpoint_id <- as.character(smm_immunity_tracker_pick_col(events, c("endpoint_id", "infection_endpoint_id"), default_endpoint))
  endpoint_id[!nzchar(endpoint_id)] <- default_endpoint
  out <- data.frame(person_key = person_key, event_date = event_date, endpoint_id = endpoint_id, stringsAsFactors = FALSE)
  unique(out[nzchar(out$person_key) & !is.na(out$event_date), , drop = FALSE])
}

smm_immunity_tracker_episode_flags <- function(events, episode_gap_days = 14L) {
  events <- smm_immunity_tracker_normalize_events(events)
  if (!nrow(events)) return(events)
  events <- events[order(events$person_key, events$endpoint_id, events$event_date), , drop = FALSE]
  split_key <- paste(events$person_key, events$endpoint_id, sep = "\r")
  is_new <- logical(nrow(events))
  for (key in unique(split_key)) {
    idx <- which(split_key == key)
    is_new[idx] <- c(TRUE, diff(events$event_date[idx]) > episode_gap_days)
  }
  events$is_new_episode <- is_new
  events
}

smm_immunity_tracker_window_specs <- function() {
  data.frame(
    analysis_window = c("pre_diagnosis_365d", "diagnosis_to_day90", "post_entry_6m_landmark", "post_entry_12m_landmark", "pre_progression_descriptive"),
    burden_window_role = c("baseline history", "diagnostic-to-day90 burden", "landmark predictor", "landmark predictor", "descriptive only"),
    landmark_days = c(0L, 90L, 183L, 365L, NA_integer_),
    notes = c(
      "Events before first DC900; no immortal-time bias.",
      "Events between diagnosis and day 90; descriptive or day-90 predictor only.",
      "Include only people alive and progression-free at the 6-month landmark.",
      "Include only people alive and progression-free at the 12-month landmark.",
      "Events before progression, death, or censoring; not a predictor estimate."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_min_date <- function(...) {
  vals <- do.call(c, list(...))
  vals <- vals[!is.na(vals)]
  if (!length(vals)) as.Date(NA) else min(vals)
}

smm_immunity_tracker_window_frame <- function(entries, spec) {
  if (!nrow(entries)) return(entries[FALSE, , drop = FALSE])
  out <- entries
  aw <- spec$analysis_window[[1]]
  if (identical(aw, "pre_diagnosis_365d")) {
    out$window_start <- out$first_dc900_date - 365L
    out$window_end <- out$first_dc900_date - 1L
    out$outcome_clock <- out$tracker_entry_date
  } else if (identical(aw, "diagnosis_to_day90")) {
    out$window_start <- out$first_dc900_date
    out$window_end <- out$first_dc900_date + 90L
    out$outcome_clock <- out$tracker_entry_date
  } else if (identical(aw, "post_entry_6m_landmark")) {
    out$window_start <- out$tracker_entry_date
    out$window_end <- out$tracker_entry_date + 183L
    out$outcome_clock <- out$window_end
    out <- out[(is.na(out$progression_date) | out$progression_date > out$outcome_clock) &
      (is.na(out$death_date) | out$death_date > out$outcome_clock), , drop = FALSE]
  } else if (identical(aw, "post_entry_12m_landmark")) {
    out$window_start <- out$tracker_entry_date
    out$window_end <- out$tracker_entry_date + 365L
    out$outcome_clock <- out$window_end
    out <- out[(is.na(out$progression_date) | out$progression_date > out$outcome_clock) &
      (is.na(out$death_date) | out$death_date > out$outcome_clock), , drop = FALSE]
  } else {
    out$window_start <- out$tracker_entry_date
    out$window_end <- as.Date(vapply(seq_len(nrow(out)), function(i) {
      as.character(smm_immunity_tracker_min_date(out$progression_date[[i]], out$death_date[[i]], out$censor_date[[i]]))
    }, character(1)))
    out$outcome_clock <- out$tracker_entry_date
  }
  out
}

smm_immunity_tracker_exit_date <- function(entries) {
  as.Date(vapply(seq_len(nrow(entries)), function(i) {
    as.character(smm_immunity_tracker_min_date(entries$progression_date[[i]], entries$death_date[[i]], entries$censor_date[[i]]))
  }, character(1)))
}

smm_immunity_tracker_burden_stratum <- function(n) {
  n <- suppressWarnings(as.numeric(n))
  if (is.na(n) || n <= 0) return("0")
  if (n == 1) return("1")
  if (n <= 3) return("2-3")
  ">=4"
}

smm_immunity_tracker_endpoint_label <- function(endpoint_id) {
  defs <- smm_immunity_tracker_endpoint_definitions()
  hit <- defs[defs$endpoint_id == endpoint_id, , drop = FALSE]
  if (nrow(hit)) hit$endpoint_label[[1]] else endpoint_id
}

smm_immunity_tracker_window_event_counts <- function(entries, events, spec) {
  frame <- smm_immunity_tracker_window_frame(entries, spec)
  if (!nrow(frame)) return(data.frame(stringsAsFactors = FALSE))
  joined <- merge(frame[c("person_key", "cohort_id", "cohort_label", "time_origin", "window_start", "window_end", "outcome_clock", "progression_date", "death_date", "censor_date")], events, by = "person_key", all.x = TRUE)
  if (nrow(joined)) {
    joined <- joined[!is.na(joined$event_date) & joined$event_date >= joined$window_start & joined$event_date <= joined$window_end, , drop = FALSE]
  }
  endpoints <- unique(events$endpoint_id)
  if (!length(endpoints)) endpoints <- "serious_infection_hospitalization"
  rows <- list()
  for (endpoint in endpoints) {
    ep <- joined[joined$endpoint_id == endpoint, , drop = FALSE]
    counts <- if (nrow(ep)) {
      aggregate(list(event_count = ep$event_date), by = list(person_key = ep$person_key), FUN = length)
    } else {
      data.frame(person_key = character(), event_count = integer(), stringsAsFactors = FALSE)
    }
    person <- merge(frame, counts, by = "person_key", all.x = TRUE)
    person$event_count[is.na(person$event_count)] <- 0L
    person$endpoint_id <- endpoint
    rows[[length(rows) + 1L]] <- person
  }
  bind_rows_base(rows)
}

smm_immunity_tracker_outcome_counts <- function(person_rows) {
  if (!nrow(person_rows)) {
    return(list(progression = 0L, death = 0L, py = 0))
  }
  exit_date <- smm_immunity_tracker_exit_date(person_rows)
  clock <- person_rows$outcome_clock
  valid_exit <- !is.na(exit_date) & !is.na(clock) & exit_date > clock
  py <- sum(as.numeric(exit_date[valid_exit] - clock[valid_exit]) / 365.25, na.rm = TRUE)
  progression <- sum(!is.na(person_rows$progression_date) & !is.na(clock) & person_rows$progression_date > clock & (is.na(person_rows$death_date) | person_rows$progression_date <= person_rows$death_date), na.rm = TRUE)
  death <- sum(!is.na(person_rows$death_date) & !is.na(clock) & person_rows$death_date > clock & (is.na(person_rows$progression_date) | person_rows$death_date < person_rows$progression_date), na.rm = TRUE)
  list(progression = progression, death = death, py = py)
}

smm_immunity_tracker_build_cohort_counts <- function(entries, min_cell_count = atlas_min_cell_count(), source_label = "secure source") {
  if (!nrow(entries)) return(smm_immunity_tracker_empty_cohort_counts())
  rows <- lapply(split(entries, entries$cohort_id), function(group) {
    n <- length(unique(group$person_key))
    count <- smm_immunity_tracker_count_suppress(n, min_cell_count = min_cell_count)
    data.frame(
      cohort_id = group$cohort_id[[1]],
      cohort_label = group$cohort_label[[1]],
      time_origin = group$time_origin[[1]],
      n_people_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = "accepted",
      query_status = "executed",
      suppression_status = count$status,
      source_file_or_route = source_label,
      notes = "Accepted aggregate cohort count; the day-90 harmonized tracker entry is used for primary comparison.",
      stringsAsFactors = FALSE
    )
  })
  smm_immunity_tracker_match_empty(bind_rows_base(rows), smm_immunity_tracker_empty_cohort_counts())
}

smm_immunity_tracker_build_infection_counts <- function(entries,
                                                        events,
                                                        min_cell_count = atlas_min_cell_count(),
                                                        recurrent = FALSE,
                                                        microbiology = FALSE) {
  events <- if (isTRUE(recurrent)) {
    ev <- smm_immunity_tracker_episode_flags(events)
    ev[ev$is_new_episode, c("person_key", "event_date", "endpoint_id"), drop = FALSE]
  } else {
    smm_immunity_tracker_normalize_events(events, if (isTRUE(microbiology)) "microbiology_confirmed_infection" else "serious_infection_hospitalization")
  }
  if (!nrow(entries)) return(smm_immunity_tracker_empty_infection_counts())
  specs <- smm_immunity_tracker_window_specs()
  rows <- list()
  for (si in seq_len(nrow(specs))) {
    spec <- specs[si, , drop = FALSE]
    person_events <- smm_immunity_tracker_window_event_counts(entries, events, spec)
    endpoints <- unique(c(events$endpoint_id, if (isTRUE(microbiology)) "microbiology_confirmed_infection" else "serious_infection_hospitalization"))
    for (cohort in unique(entries$cohort_id)) {
      eligible <- smm_immunity_tracker_window_frame(entries[entries$cohort_id == cohort, , drop = FALSE], spec)
      total_people <- length(unique(eligible$person_key))
      for (endpoint in endpoints) {
        subset <- person_events[person_events$cohort_id == cohort & person_events$endpoint_id == endpoint, , drop = FALSE]
        people_n <- sum(subset$event_count > 0, na.rm = TRUE)
        events_n <- sum(subset$event_count, na.rm = TRUE)
        people_count <- smm_immunity_tracker_count_suppress(people_n, total_people, min_cell_count)
        event_count <- smm_immunity_tracker_count_suppress(events_n, min_cell_count = min_cell_count)
        cohort_label <- smm_immunity_tracker_cohort_label(cohort)
        rows[[length(rows) + 1L]] <- data.frame(
          cohort_id = cohort,
          cohort_label = cohort_label,
          analysis_window = spec$analysis_window,
          infection_endpoint_id = endpoint,
          infection_endpoint_label = smm_immunity_tracker_endpoint_label(endpoint),
          burden_window_role = spec$burden_window_role,
          count_display = people_count$display,
          n_people = people_count$n_public,
          event_count_display = event_count$display,
          n_events = event_count$n_public,
          count_kind = if (isTRUE(recurrent)) "distinct recurrent episodes" else "distinct people and events",
          acceptance_status = if (nrow(events)) "accepted" else "not accepted aggregate",
          query_status = if (nrow(events)) "executed" else "production_aggregate_failed_mapping_unavailable",
          suppression_status = smm_immunity_tracker_count_status_join(people_count$status, event_count$status),
          endpoint_definition_status = "repo-derived provisional",
          notes = if (identical(spec$analysis_window, "pre_progression_descriptive")) {
            "Descriptive only; not a predictor estimate."
          } else if (isTRUE(recurrent)) {
            "Recurrent infection episode aggregate using a 14-day same-endpoint episode gap."
          } else {
            "Aggregate infection signal using the configured SMM tracker window."
          },
          stringsAsFactors = FALSE
        )
      }
    }
  }
  smm_immunity_tracker_match_empty(bind_rows_base(rows), smm_immunity_tracker_empty_infection_counts())
}

smm_immunity_tracker_build_burden_outputs <- function(entries, events, min_cell_count = atlas_min_cell_count()) {
  events <- smm_immunity_tracker_normalize_events(events)
  if (!nrow(entries)) {
    return(list(
      burden_strata_counts = smm_immunity_tracker_empty_burden_strata_counts(),
      landmark_progression_signal = smm_immunity_tracker_empty_landmark_progression_signal(),
      infection_person_time = smm_immunity_tracker_empty_person_time(),
      infection_rates = smm_immunity_tracker_empty_rates()
    ))
  }
  specs <- smm_immunity_tracker_window_specs()
  burden_rows <- list()
  signal_rows <- list()
  person_time_rows <- list()
  rate_rows <- list()
  endpoints <- unique(c(events$endpoint_id, "serious_infection_hospitalization"))
  for (si in seq_len(nrow(specs))) {
    spec <- specs[si, , drop = FALSE]
    person_events <- smm_immunity_tracker_window_event_counts(entries, events, spec)
    for (cohort in unique(entries$cohort_id)) {
      eligible <- smm_immunity_tracker_window_frame(entries[entries$cohort_id == cohort, , drop = FALSE], spec)
      total_people <- length(unique(eligible$person_key))
      cohort_label <- smm_immunity_tracker_cohort_label(cohort)
      outcome_all <- smm_immunity_tracker_outcome_counts(eligible)
      people_display <- smm_immunity_tracker_count_suppress(total_people, min_cell_count = min_cell_count)
      py_display <- if (is.na(people_display$n_public)) {
        list(display = paste0("<", normalize_min_cell_count(min_cell_count)), n_public = NA_real_, status = people_display$status)
      } else {
        list(display = as.character(round(outcome_all$py, 2)), n_public = round(outcome_all$py, 2), status = "not suppressed")
      }
      person_time_rows[[length(person_time_rows) + 1L]] <- data.frame(
        cohort_id = cohort,
        cohort_label = cohort_label,
        analysis_window = spec$analysis_window,
        landmark_days = spec$landmark_days,
        n_people_display = people_display$display,
        n_people = people_display$n_public,
        person_years_display = py_display$display,
        person_years = py_display$n_public,
        count_kind = "person-years after outcome clock",
        acceptance_status = if (total_people > 0) "accepted" else "not accepted aggregate",
        query_status = if (total_people > 0) "executed" else "production_aggregate_failed_mapping_unavailable",
        suppression_status = smm_immunity_tracker_count_status_join(people_display$status, py_display$status),
        notes = spec$notes,
        stringsAsFactors = FALSE
      )
      for (endpoint in endpoints) {
        subset <- person_events[person_events$cohort_id == cohort & person_events$endpoint_id == endpoint, , drop = FALSE]
        if (!nrow(subset)) {
          subset <- eligible
          subset$event_count <- 0L
          subset$endpoint_id <- endpoint
        }
        subset$burden_stratum <- vapply(subset$event_count, smm_immunity_tracker_burden_stratum, character(1))
        for (stratum in c("0", "1", "2-3", ">=4")) {
          group <- subset[subset$burden_stratum == stratum, , drop = FALSE]
          n_people <- length(unique(group$person_key))
          outcome <- smm_immunity_tracker_outcome_counts(group)
          n_count <- smm_immunity_tracker_count_suppress(n_people, total_people, min_cell_count)
          prog_count <- smm_immunity_tracker_count_suppress(outcome$progression, n_people, min_cell_count)
          death_count <- smm_immunity_tracker_count_suppress(outcome$death, n_people, min_cell_count)
          py_count <- if (is.na(n_count$n_public)) {
            list(display = paste0("<", normalize_min_cell_count(min_cell_count)), n_public = NA_real_, status = n_count$status)
          } else {
            list(display = as.character(round(outcome$py, 2)), n_public = round(outcome$py, 2), status = "not suppressed")
          }
          rate <- if (!is.na(prog_count$n_public) && !is.na(py_count$n_public) && py_count$n_public > 0) round(100 * prog_count$n_public / py_count$n_public, 2) else NA_real_
          status <- smm_immunity_tracker_count_status_join(n_count$status, prog_count$status, death_count$status, py_count$status)
          note <- if (identical(spec$analysis_window, "pre_progression_descriptive")) "Descriptive only; not a predictor estimate." else spec$notes
          burden_rows[[length(burden_rows) + 1L]] <- data.frame(
            cohort_id = cohort,
            cohort_label = cohort_label,
            analysis_window = spec$analysis_window,
            infection_endpoint_id = endpoint,
            infection_endpoint_label = smm_immunity_tracker_endpoint_label(endpoint),
            burden_stratum = stratum,
            landmark_days = spec$landmark_days,
            n_people_display = n_count$display,
            n_people = n_count$n_public,
            n_progression_display = prog_count$display,
            n_progression = prog_count$n_public,
            n_competing_death_display = death_count$display,
            n_competing_death = death_count$n_public,
            person_years_display = py_count$display,
            person_years = py_count$n_public,
            progression_rate_per_100py = rate,
            count_kind = "infection-burden stratum",
            acceptance_status = if (nrow(events)) "accepted" else "not accepted aggregate",
            query_status = if (nrow(events)) "executed" else "production_aggregate_failed_mapping_unavailable",
            suppression_status = status,
            immortal_time_handling_note = spec$notes,
            notes = note,
            stringsAsFactors = FALSE
          )
          signal_rows[[length(signal_rows) + 1L]] <- data.frame(
            cohort_id = cohort,
            cohort_label = cohort_label,
            analysis_window = spec$analysis_window,
            landmark_days = spec$landmark_days,
            infection_burden_definition = paste(endpoint, "episodes in", spec$analysis_window),
            burden_stratum = stratum,
            horizon_years = NA_real_,
            n_at_landmark_display = n_count$display,
            n_at_landmark = n_count$n_public,
            progression_events_display = prog_count$display,
            progression_events = prog_count$n_public,
            competing_deaths_display = death_count$display,
            competing_deaths = death_count$n_public,
            person_years_display = py_count$display,
            person_years = py_count$n_public,
            progression_rate_per_100py = rate,
            endpoint_definition_status = "repo-derived provisional",
            acceptance_status = if (nrow(events)) "accepted" else "not accepted aggregate",
            query_status = if (nrow(events)) "executed" else "production_aggregate_failed_mapping_unavailable",
            suppression_status = status,
            notes = note,
            stringsAsFactors = FALSE
          )
        }
        endpoint_events <- subset$event_count
        event_total <- sum(endpoint_events, na.rm = TRUE)
        event_count <- smm_immunity_tracker_count_suppress(event_total, min_cell_count = min_cell_count)
        rate <- if (!is.na(event_count$n_public) && !is.na(py_display$n_public) && py_display$n_public > 0) round(100 * event_count$n_public / py_display$n_public, 2) else NA_real_
        rate_rows[[length(rate_rows) + 1L]] <- data.frame(
          cohort_id = cohort,
          cohort_label = cohort_label,
          analysis_window = spec$analysis_window,
          infection_endpoint_id = endpoint,
          infection_endpoint_label = smm_immunity_tracker_endpoint_label(endpoint),
          event_count_display = event_count$display,
          n_events = event_count$n_public,
          person_years_display = py_display$display,
          person_years = py_display$n_public,
          rate_per_100py = rate,
          count_kind = "rate from suppressed aggregate components",
          acceptance_status = if (nrow(events)) "accepted" else "not accepted aggregate",
          query_status = if (nrow(events)) "executed" else "production_aggregate_failed_mapping_unavailable",
          suppression_status = smm_immunity_tracker_count_status_join(event_count$status, py_display$status),
          notes = "Rates are suppressed when numerator or denominator components are suppressed.",
          stringsAsFactors = FALSE
        )
      }
    }
  }
  list(
    burden_strata_counts = smm_immunity_tracker_match_empty(bind_rows_base(burden_rows), smm_immunity_tracker_empty_burden_strata_counts()),
    landmark_progression_signal = smm_immunity_tracker_match_empty(bind_rows_base(signal_rows), smm_immunity_tracker_empty_landmark_progression_signal()),
    infection_person_time = smm_immunity_tracker_match_empty(bind_rows_base(person_time_rows), smm_immunity_tracker_empty_person_time()),
    infection_rates = smm_immunity_tracker_match_empty(bind_rows_base(rate_rows), smm_immunity_tracker_empty_rates())
  )
}

smm_immunity_tracker_read_wp5_public_aggregate <- function(public_root, source_file) {
  path <- file.path(public_root, source_file)
  if (!file.exists(path)) {
    return(list(data = data.frame(stringsAsFactors = FALSE), read_status = "not_found", rows_read = 0L))
  }
  data <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  status <- if (is.data.frame(data) && nrow(data)) "read_public_aggregate" else "public_aggregate_empty_or_unreadable"
  list(data = data, read_status = status, rows_read = if (is.data.frame(data)) nrow(data) else 0L)
}

smm_immunity_tracker_wp5_source_audit <- function(resolution, aggregate_reads = list()) {
  public_root <- resolution$wp5_public_root %||% ""
  aggregate_rows <- lapply(smm_immunity_tracker_wp5_aggregate_files(), function(source_file) {
    read <- aggregate_reads[[source_file]] %||% list(read_status = "not_checked", rows_read = 0L)
    found <- nzchar(public_root) && file.exists(file.path(public_root, source_file))
    data.frame(
      source_file = source_file,
      source_root_label = resolution$source_root_label %||% "",
      wp5_run_id = resolution$wp5_run_id %||% "",
      path_status = resolution$path_status %||% "",
      found = found,
      read_status = if (found) read$read_status else "not_found",
      rows_read = if (found) as.integer(read$rows_read %||% 0L) else 0L,
      public_safe = TRUE,
      secure_input_only = FALSE,
      notes = if (found) "accepted_public_aggregate_source" else "public_aggregate_source_absent",
      stringsAsFactors = FALSE
    )
  })
  secure_rows <- lapply(smm_immunity_tracker_wp5_secure_input_files(), function(source_file) {
    found <- nzchar(public_root) && file.exists(file.path(public_root, source_file))
    data.frame(
      source_file = source_file,
      source_root_label = resolution$source_root_label %||% "",
      wp5_run_id = resolution$wp5_run_id %||% "",
      path_status = resolution$path_status %||% "",
      found = found,
      read_status = if (found) "not_read_secure_input_only" else "not_found_secure_input_only",
      rows_read = NA_integer_,
      public_safe = FALSE,
      secure_input_only = TRUE,
      notes = if (found) "secure_input_presence_checked_only" else "secure_input_not_found",
      stringsAsFactors = FALSE
    )
  })
  smm_immunity_tracker_match_empty(bind_rows_base(c(aggregate_rows, secure_rows)), smm_immunity_tracker_empty_wp5_source_audit())
}

smm_immunity_tracker_extract_tier_count <- function(tiers, tier_id) {
  if (!is.data.frame(tiers) || !nrow(tiers)) return(NA_real_)
  tier_col <- smm_immunity_tracker_first_existing_col(tiers, c("tier_id", "frame_id", "cohort_id"))
  n_col <- smm_immunity_tracker_first_existing_col(tiers, c("n_patients", "n_people", "n", "patients"))
  if (!nzchar(tier_col) || !nzchar(n_col)) return(NA_real_)
  values <- as.character(tiers[[tier_col]])
  aliases <- switch(tier_id,
    "SMM-A" = c("SMM-A", "smm_a", "aot_wp5_original_smm"),
    "SMM-B" = c("SMM-B", "smm_b", "bmpc_confirmable_subset"),
    "SMM-C" = c("SMM-C", "smm_c", "risk_derivable_subset"),
    tier_id
  )
  hit <- tiers[values %in% aliases, , drop = FALSE]
  if (!nrow(hit)) return(NA_real_)
  suppressWarnings(as.numeric(hit[[n_col]][[1]]))
}

smm_immunity_tracker_build_wp5_aggregate_cohort_counts <- function(tiers,
                                                                   min_cell_count = atlas_min_cell_count(),
                                                                   source_file = "wp5_smm_analysis_tiers.csv") {
  spec <- data.frame(
    wp5_tier_id = c("SMM-A", "SMM-B", "SMM-C"),
    cohort_id = c("aot_wp5_original_smm", "aot_wp5_bmpc_confirmable_subset", "aot_wp5_biomarker_rich_subset"),
    cohort_label = c(
      "AOT/WP5 original SMM-compatible day-90 cohort",
      "AOT/WP5 BMPC-confirmable subset",
      "AOT/WP5 biomarker-rich subset"
    ),
    time_origin = rep("day90_harmonized", 3),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(spec)), function(i) {
    n <- smm_immunity_tracker_extract_tier_count(tiers, spec$wp5_tier_id[[i]])
    accepted <- !is.na(n)
    count <- if (accepted) smm_immunity_tracker_count_suppress(n, min_cell_count = min_cell_count) else list(display = "not available", n_public = NA_real_, status = "not available")
    data.frame(
      cohort_id = spec$cohort_id[[i]],
      cohort_label = spec$cohort_label[[i]],
      time_origin = spec$time_origin[[i]],
      n_people_display = count$display,
      n_people = count$n_public,
      count_kind = "accepted WP5 aggregate denominator",
      acceptance_status = if (accepted) "accepted" else "not accepted aggregate",
      source_acceptance_status = if (accepted) "accepted_wp5_aggregate" else "wp5_aggregate_tier_absent",
      tracker_status = if (accepted) "partial" else "unavailable",
      query_status = if (accepted) "executed" else "aggregate_tier_absent",
      suppression_status = count$status,
      source_file_or_route = source_file,
      notes = if (accepted) "accepted_wp5_aggregate_denominator" else "wp5_aggregate_tier_not_available",
      stringsAsFactors = FALSE
    )
  })
  cvm <- data.frame(
    cohort_id = "cvm_jama_smm",
    cohort_label = "CVM/JAMA SMM denominator readiness row",
    time_origin = "day90_harmonized_planned",
    n_people_display = "not available",
    n_people = NA_real_,
    count_kind = "readiness placeholder",
    acceptance_status = "not accepted aggregate",
    source_acceptance_status = "not_yet_accepted_aggregate_source",
    tracker_status = "unavailable",
    query_status = "aggregate_source_pending",
    suppression_status = "not available",
    source_file_or_route = "pending_accepted_cvm_aggregate_source",
    notes = "cvm_counts_require_separate_accepted_aggregate_source",
    stringsAsFactors = FALSE
  )
  smm_immunity_tracker_match_empty(bind_rows_base(c(rows, list(cvm))), smm_immunity_tracker_empty_cohort_counts())
}

smm_immunity_tracker_unavailable_route_audit <- function(cohort_available = FALSE) {
  routes <- data.frame(
    route_id = c(
      "wp5_cohort_denominators",
      "cvm_jama_aggregate_route",
      "hospital_coded_serious_infection_route",
      "microbiology_confirmed_infection_route",
      "recurrent_infection_route",
      "infection_person_time_route",
      "landmark_progression_signal_route"
    ),
    configured = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
    query_executed = c(isTRUE(cohort_available), FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
    query_success = c(isTRUE(cohort_available), FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
    query_status = c(
      if (isTRUE(cohort_available)) "executed" else "production_aggregate_failed_mapping_unavailable",
      "not_yet_accepted_aggregate_source",
      rep("unavailable_not_configured", 5)
    ),
    source_table = "",
    error_message_sanitized = "",
    notes = c(
      if (isTRUE(cohort_available)) "aot_wp5_cohort_denominators_available" else "aot_wp5_cohort_denominators_unavailable",
      "cvm_counts_require_separate_accepted_aggregate_source",
      "hospital_coded_serious_infection_route_unavailable",
      "microbiology_confirmed_infection_route_unavailable",
      "recurrent_infection_route_unavailable",
      "infection_person_time_route_unavailable",
      "landmark_progression_signal_route_unavailable"
    ),
    stringsAsFactors = FALSE
  )
  smm_immunity_tracker_match_empty(routes, smm_immunity_tracker_empty_source_resolution_audit())
}

smm_immunity_tracker_count_outputs_from_wp5_aggregates <- function(resolution,
                                                                   aggregate_reads,
                                                                   project_root = ".",
                                                                   min_cell_count = atlas_min_cell_count(),
                                                                   mode = "production_aggregate") {
  outputs <- build_smm_immunity_tracker_feasibility_outputs(project_root = project_root, min_cell_count = min_cell_count)
  tiers <- aggregate_reads[["wp5_smm_analysis_tiers.csv"]]$data %||% data.frame(stringsAsFactors = FALSE)
  outputs$cohort_counts <- smm_immunity_tracker_build_wp5_aggregate_cohort_counts(tiers, min_cell_count = min_cell_count)
  cohort_available <- any(outputs$cohort_counts$source_acceptance_status == "accepted_wp5_aggregate", na.rm = TRUE)
  outputs$wp5_source_audit <- smm_immunity_tracker_wp5_source_audit(resolution, aggregate_reads)
  outputs$source_resolution_audit <- smm_immunity_tracker_unavailable_route_audit(cohort_available = cohort_available)
  outputs$failed_query_audit <- smm_immunity_tracker_count_failed_route_audit(outputs$source_resolution_audit)
  outputs$production_query_review <- data.frame(
    query_id = c("smm_immunity_tracker_counts", "wp5_aggregate_denominators", "cvm_jama_aggregate_denominators", "infection_event_routes"),
    query_label = c("Aggregate SMM tracker counts", "AOT/WP5 public aggregate denominators", "CVM/JAMA aggregate denominator route", "Serious infection and microbiology event routes"),
    query_executable = c(TRUE, TRUE, FALSE, FALSE),
    query_status = c(
      "partial_executed",
      if (cohort_available) "executed" else "production_aggregate_failed_mapping_unavailable",
      "not_yet_accepted_aggregate_source",
      "unavailable_not_configured"
    ),
    acceptance_status = c("partial", if (cohort_available) "accepted_wp5_aggregate" else "not accepted aggregate", "not accepted aggregate", "not accepted aggregate"),
    notes = c(
      "Cohort denominators may be available while infection routes remain unavailable.",
      "Only wp5_smm_analysis_tiers.csv and wp5_cohort_attrition.csv are eligible public count sources.",
      "CVM/JAMA counts require a separate accepted aggregate source.",
      "Infection outputs remain schemaful empty tables and must not be interpreted as true zero."
    ),
    stringsAsFactors = FALSE
  )
  outputs$tracker_status <- smm_immunity_tracker_status_rows(
    cohort_denominators = if (cohort_available) "available" else "unavailable",
    cvm_aggregate_route = "pending",
    infection_routes = "unavailable",
    microbiology_routes = "unavailable",
    person_time_routes = "unavailable",
    progression_signal = "unavailable",
    tracker_status = "partial",
    production_aggregate_status = if (cohort_available) {
      "partial: cohort counts available; CVM aggregate route pending; infection routes unavailable"
    } else {
      "partial: cohort counts unavailable; CVM aggregate route pending; infection routes unavailable"
    }
  )
  outputs$production_execution_summary <- smm_immunity_tracker_execution_summary(
    mode,
    attempted = TRUE,
    success = cohort_available,
    failure_reason = if (cohort_available) "" else "No accepted WP5 aggregate cohort denominator rows were available.",
    min_cell_count = min_cell_count,
    cohort_rows = 0L,
    infection_rows = 0L
  )
  outputs$summary$value[outputs$summary$metric == "panel_status"] <- if (cohort_available) "partial production aggregate available" else "readiness scaffold"
  outputs$summary$status[outputs$summary$metric == "panel_status"] <- if (cohort_available) "partial" else "feasibility"
  outputs$summary$value[outputs$summary$metric == "production_aggregate_status"] <- outputs$tracker_status$status_value[outputs$tracker_status$status_key == "production_aggregate_status"][[1]]
  outputs$summary$status[outputs$summary$metric == "production_aggregate_status"] <- "partial"
  smm_immunity_tracker_assert_public_output_safe(outputs)
  smm_immunity_tracker_attach_story_layer(outputs)
}

smm_immunity_tracker_read_wp5_cohort_frames <- function(project_root = ".") {
  resolution <- smm_immunity_tracker_resolve_wp5_outputs(project_root)
  aggregate_reads <- list()
  if (identical(resolution$status, "resolved")) {
    for (source_file in smm_immunity_tracker_wp5_aggregate_files()) {
      aggregate_reads[[source_file]] <- smm_immunity_tracker_read_wp5_public_aggregate(resolution$wp5_public_root, source_file)
    }
  }
  list(
    cohort_entries = data.frame(stringsAsFactors = FALSE),
    cohort_route_status = smm_immunity_tracker_unavailable_route_audit(cohort_available = FALSE),
    cohort_source_audit = smm_immunity_tracker_wp5_source_audit(resolution, aggregate_reads)
  )
}

smm_immunity_tracker_count_outputs_from_secure_frames <- function(frames,
                                                                  project_root = ".",
                                                                  min_cell_count = atlas_min_cell_count(),
                                                                  mode = "production_aggregate",
                                                                  source_label = "secure synthetic fixture") {
  if (!is.list(frames)) frames <- list()
  entries <- smm_immunity_tracker_normalize_cohort_entries(frames$cohort_entries %||% data.frame(stringsAsFactors = FALSE))
  infection_events <- smm_immunity_tracker_normalize_events(frames$infection_events %||% data.frame(stringsAsFactors = FALSE))
  microbiology_events <- smm_immunity_tracker_normalize_events(frames$microbiology_confirmation_events %||% data.frame(stringsAsFactors = FALSE), "microbiology_confirmed_infection")
  route_status <- frames$route_status %||% bind_rows_base(list(
    smm_immunity_tracker_count_route_row("cohort_entries", TRUE, TRUE, nrow(entries) > 0L, source_table = source_label, notes = "Secure cohort source frame."),
    smm_immunity_tracker_count_route_row("infection_events", TRUE, TRUE, nrow(infection_events) > 0L, source_table = source_label, notes = "Secure infection event source frame."),
    smm_immunity_tracker_count_route_row("microbiology_confirmation", TRUE, TRUE, nrow(microbiology_events) > 0L, source_table = source_label, notes = "Secure microbiology confirmation event frame.")
  ))

  outputs <- build_smm_immunity_tracker_feasibility_outputs(project_root = project_root, min_cell_count = min_cell_count)
  outputs$cohort_counts <- smm_immunity_tracker_build_cohort_counts(entries, min_cell_count = min_cell_count, source_label = source_label)
  outputs$infection_counts <- smm_immunity_tracker_build_infection_counts(entries, infection_events, min_cell_count = min_cell_count)
  outputs$recurrent_infection_counts <- smm_immunity_tracker_build_infection_counts(entries, infection_events, min_cell_count = min_cell_count, recurrent = TRUE)
  outputs$microbiology_confirmation_counts <- smm_immunity_tracker_build_infection_counts(entries, microbiology_events, min_cell_count = min_cell_count, microbiology = TRUE)
  burden <- smm_immunity_tracker_build_burden_outputs(entries, infection_events, min_cell_count = min_cell_count)
  outputs$burden_strata_counts <- burden$burden_strata_counts
  outputs$landmark_progression_signal <- burden$landmark_progression_signal
  outputs$infection_person_time <- burden$infection_person_time
  outputs$infection_rates <- burden$infection_rates
  outputs$wp5_source_audit <- frames$wp5_source_audit %||% smm_immunity_tracker_empty_wp5_source_audit()
  outputs$source_resolution_audit <- smm_immunity_tracker_match_empty(route_status, smm_immunity_tracker_empty_source_resolution_audit())
  outputs$failed_query_audit <- smm_immunity_tracker_count_failed_route_audit(outputs$source_resolution_audit)
  outputs$production_query_review <- data.frame(
    query_id = c("smm_immunity_tracker_counts", "cohort_entries", "infection_events", "microbiology_confirmation"),
    query_label = c("Aggregate SMM tracker counts", "SMM cohort entries", "Serious infection events", "Microbiology confirmation events"),
    query_executable = c(TRUE, TRUE, TRUE, TRUE),
    query_status = c("executed", if (nrow(entries)) "executed" else "production_aggregate_failed_mapping_unavailable", if (nrow(infection_events)) "executed" else "production_aggregate_failed_mapping_unavailable", if (nrow(microbiology_events)) "executed" else "production_aggregate_failed_mapping_unavailable"),
    acceptance_status = c(if (nrow(entries)) "accepted" else "not accepted aggregate", if (nrow(entries)) "accepted" else "not accepted aggregate", if (nrow(infection_events)) "accepted" else "not accepted aggregate", if (nrow(microbiology_events)) "accepted" else "not accepted aggregate"),
    notes = c(
      "Aggregate outputs generated from secure in-memory/source frames.",
      "Cohort entries are harmonized to day-90 primary tracker view before aggregation.",
      "Infection events are counted only in configured aggregate windows.",
      "Microbiology confirmation is counted without organism or result text."
    ),
    stringsAsFactors = FALSE
  )
  outputs$production_execution_summary <- smm_immunity_tracker_execution_summary(
    mode,
    attempted = TRUE,
    success = nrow(entries) > 0L,
    failure_reason = if (nrow(entries)) "" else "No SMM cohort entries were available.",
    min_cell_count = min_cell_count,
    cohort_rows = nrow(entries),
    infection_rows = nrow(infection_events)
  )
  outputs$summary$value[outputs$summary$metric == "production_aggregate_status"] <- if (nrow(entries)) "aggregate output available" else "not accepted aggregate"
  outputs$summary$status[outputs$summary$metric == "production_aggregate_status"] <- if (nrow(entries)) "accepted" else "fail-closed"
  smm_immunity_tracker_assert_public_output_safe(outputs)
  smm_immunity_tracker_attach_story_layer(outputs)
}

smm_immunity_tracker_prepare_aggregate_hook_outputs <- function(hook,
                                                                project_root = ".",
                                                                min_cell_count = atlas_min_cell_count()) {
  if (!is.list(hook)) {
    return(smm_immunity_tracker_count_placeholder_outputs(
      mode = "production_aggregate",
      reason = "SMM aggregate count hook did not return a list.",
      error_class = "production_aggregate_failed_query_error",
      project_root = project_root,
      min_cell_count = min_cell_count
    ))
  }
  privacy_hits <- smm_immunity_tracker_aggregate_hook_privacy_hits(hook)
  if (length(privacy_hits)) {
    return(smm_immunity_tracker_count_placeholder_outputs(
      mode = "production_aggregate",
      reason = paste("SMM aggregate hook returned unsafe row-level or sensitive fields:", paste(privacy_hits, collapse = "; ")),
      error_class = "production_aggregate_failed_privacy_contract",
      project_root = project_root,
      min_cell_count = min_cell_count
    ))
  }
  hook <- smm_immunity_tracker_suppress_adapter_outputs(hook, min_cell_count = min_cell_count)
  outputs <- build_smm_immunity_tracker_feasibility_outputs(project_root = project_root, min_cell_count = min_cell_count)
  for (nm in intersect(names(outputs), names(hook))) {
    if (is.data.frame(hook[[nm]])) outputs[[nm]] <- hook[[nm]]
  }
  outputs$cohort_counts <- smm_immunity_tracker_match_empty(outputs$cohort_counts, smm_immunity_tracker_empty_cohort_counts())
  outputs$infection_counts <- smm_immunity_tracker_match_empty(outputs$infection_counts, smm_immunity_tracker_empty_infection_counts())
  outputs$recurrent_infection_counts <- smm_immunity_tracker_match_empty(outputs$recurrent_infection_counts, smm_immunity_tracker_empty_infection_counts())
  outputs$microbiology_confirmation_counts <- smm_immunity_tracker_match_empty(outputs$microbiology_confirmation_counts, smm_immunity_tracker_empty_infection_counts())
  outputs$burden_strata_counts <- smm_immunity_tracker_match_empty(outputs$burden_strata_counts, smm_immunity_tracker_empty_burden_strata_counts())
  outputs$landmark_progression_signal <- smm_immunity_tracker_match_empty(outputs$landmark_progression_signal, smm_immunity_tracker_empty_landmark_progression_signal())
  outputs$infection_person_time <- smm_immunity_tracker_match_empty(outputs$infection_person_time, smm_immunity_tracker_empty_person_time())
  outputs$infection_rates <- smm_immunity_tracker_match_empty(outputs$infection_rates, smm_immunity_tracker_empty_rates())
  if (!is.data.frame(outputs$production_execution_summary) || !nrow(outputs$production_execution_summary)) {
    outputs$production_execution_summary <- smm_immunity_tracker_execution_summary(
      "production_aggregate",
      attempted = TRUE,
      success = TRUE,
      min_cell_count = min_cell_count
    )
  }
  smm_immunity_tracker_assert_public_output_safe(outputs)
  smm_immunity_tracker_attach_story_layer(outputs)
}

smm_immunity_tracker_count_build_outputs <- function(project_root = ".",
                                                     db_adapter = NULL,
  mode = c("auto", "plan", "production_aggregate"),
  min_cell_count = atlas_min_cell_count()) {
  mode <- match.arg(mode)
  if (identical(mode, "auto")) mode <- smm_immunity_tracker_count_mode(db_adapter, mode = "auto", project_root = project_root)
  if (identical(mode, "plan")) {
    return(smm_immunity_tracker_count_placeholder_outputs(
      mode = "plan",
      reason = "SMM Immunity Tracker production aggregate mode disabled or aggregate sources unavailable.",
      project_root = project_root,
      min_cell_count = min_cell_count
    ))
  }
  wp5_resolution <- smm_immunity_tracker_resolve_wp5_outputs(project_root)
  wp5_root <- wp5_resolution$wp5_public_root %||% ""
  if (!is.null(db_adapter) && is.function(db_adapter$smm_immunity_tracker_counts)) {
    hook <- tryCatch(
      db_adapter$smm_immunity_tracker_counts(min_cell_count = min_cell_count, wp5_output_root = wp5_root),
      error = function(e) {
        smm_immunity_tracker_count_placeholder_outputs(
          mode = "production_aggregate",
          reason = conditionMessage(e),
          error_class = "production_aggregate_failed_query_error",
          project_root = project_root,
          min_cell_count = min_cell_count
        )
      }
    )
    return(smm_immunity_tracker_prepare_aggregate_hook_outputs(hook, project_root = project_root, min_cell_count = min_cell_count))
  }
  if (identical(wp5_resolution$status, "resolved")) {
    aggregate_reads <- list()
    for (source_file in smm_immunity_tracker_wp5_aggregate_files()) {
      aggregate_reads[[source_file]] <- smm_immunity_tracker_read_wp5_public_aggregate(wp5_resolution$wp5_public_root, source_file)
    }
    return(smm_immunity_tracker_count_outputs_from_wp5_aggregates(
      wp5_resolution,
      aggregate_reads,
      project_root = project_root,
      min_cell_count = min_cell_count,
      mode = "production_aggregate"
    ))
  }
  smm_immunity_tracker_count_placeholder_outputs(
    mode = "production_aggregate",
    reason = "No aggregate SMM count hook or accepted public WP5 aggregate source outputs were available.",
    error_class = "production_aggregate_failed_mapping_unavailable",
    project_root = project_root,
    min_cell_count = min_cell_count
  )
}

smm_immunity_tracker_count_production_success <- function(outputs) {
  summary <- outputs$production_execution_summary %||% data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(summary) || !nrow(summary) || !all(c("metric", "value") %in% names(summary))) return(FALSE)
  hit <- summary[summary$metric == "production_query_success", , drop = FALSE]
  any(tolower(as.character(hit$value %||% "")) == "true", na.rm = TRUE)
}

smm_immunity_tracker_count_merge_outputs <- function(scaffold, production) {
  if (is.null(scaffold)) scaffold <- smm_immunity_tracker_empty_payload()
  if (is.null(production)) production <- smm_immunity_tracker_count_empty_outputs()
  for (nm in names(production)) {
    if (is.data.frame(production[[nm]]) && nrow(production[[nm]])) {
      scaffold[[nm]] <- production[[nm]]
    } else if (!nm %in% c("summary", "story_cards", "cohort_readiness", "endpoint_definitions", "atypical_prolonged_severe_readiness", "bias_warnings", "estimands", "protocol_runway")) {
      scaffold[[nm]] <- production[[nm]]
    }
  }
  if (smm_immunity_tracker_count_production_success(production)) {
    tracker_status <- production$tracker_status %||% data.frame(stringsAsFactors = FALSE)
    production_status <- if (is.data.frame(tracker_status) && nrow(tracker_status) && all(c("status_key", "status_value") %in% names(tracker_status))) {
      hit <- tracker_status[tracker_status$status_key == "production_aggregate_status", "status_value", drop = TRUE]
      hit[[1]] %||% "partial: cohort counts available; CVM aggregate route pending; infection routes unavailable"
    } else {
      "partial: cohort counts available; CVM aggregate route pending; infection routes unavailable"
    }
    scaffold$summary$value[scaffold$summary$metric == "panel_status"] <- "partial production aggregate available"
    scaffold$summary$status[scaffold$summary$metric == "panel_status"] <- "partial"
    scaffold$summary$value[scaffold$summary$metric == "production_aggregate_status"] <- production_status
    scaffold$summary$status[scaffold$summary$metric == "production_aggregate_status"] <- "partial"
  }
  smm_immunity_tracker_attach_story_layer(scaffold)
}

smm_immunity_tracker_count_read_outputs <- function(outputs_dir) {
  empty <- smm_immunity_tracker_empty_payload()
  out <- empty
  for (nm in names(empty)) {
    path <- file.path(outputs_dir, paste0("smm_immunity_tracker_", nm, ".csv"))
    if (identical(nm, "summary")) path <- file.path(outputs_dir, "smm_immunity_tracker_summary.csv")
    if (identical(nm, "story_cards")) path <- file.path(outputs_dir, "smm_immunity_tracker_story_cards.csv")
    if (identical(nm, "tracker_status")) path <- file.path(outputs_dir, "smm_immunity_tracker_status.csv")
    if (file.exists(path)) {
      out[[nm]] <- tryCatch(read_delimited_file(path), error = function(e) empty[[nm]])
    }
  }
  out
}

smm_immunity_tracker_count_write_outputs <- function(outputs, output_dir) {
  smm_immunity_tracker_write_outputs(outputs, output_dir)
}
