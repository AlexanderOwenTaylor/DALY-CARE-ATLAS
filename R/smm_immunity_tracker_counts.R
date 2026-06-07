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
  candidates <- c(
    Sys.getenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT", unset = ""),
    Sys.getenv("WOMMEN_WP5_OUTPUT_ROOT", unset = ""),
    file.path(project_root, "wp5_outputs"),
    file.path(project_root, "outputs", "wp5_side_by_side")
  )
  candidates <- candidates[nzchar(candidates)]
  if (!length(candidates)) return("")
  hit <- candidates[dir.exists(candidates)]
  if (length(hit)) normalizePath(hit[[1]], winslash = "/", mustWork = FALSE) else candidates[[1]]
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
  forbidden_names <- c(
    "person_key", "patientid", "patient_id", "cpr", "raw_date", "event_date",
    "first_dc900_date", "tracker_entry_date", "progression_date", "death_date",
    "censor_date", "organism", "organism_name", "result_text", "free_text"
  )
  hits <- character()
  for (nm in names(outputs)) {
    value <- outputs[[nm]]
    if (!is.data.frame(value)) next
    bad <- names(value)[tolower(names(value)) %in% forbidden_names]
    if (length(bad)) hits <- c(hits, paste(nm, paste(bad, collapse = ","), sep = ":"))
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

smm_immunity_tracker_read_wp5_cohort_frames <- function(project_root = ".") {
  root <- smm_immunity_tracker_wp5_output_root(project_root)
  expected <- data.frame(
    source_id = c(
      "wp5_smm_like_cohort",
      "wp5_treatment_landmark_cohort",
      "wp5_cvm_patient_flags",
      "wp5_cvm_progression_summary",
      "wp5_scaffold_compare_membership_overlap"
    ),
    relative_path = c(
      file.path("outputs", "wp5", "wp5_smm_like_cohort.csv"),
      file.path("outputs", "wp5", "wp5_treatment_landmark_cohort.csv"),
      file.path("outputs", "wp5_cvm", "wp5_cvm_patient_flags.csv"),
      file.path("outputs", "wp5_cvm", "wp5_cvm_progression_summary.csv"),
      file.path("outputs", "wp5_scaffold_compare", "wp5_scaffold_compare_membership_overlap.csv")
    ),
    source_family = c("aot_wp5_original", "aot_wp5_original", "cvm_jama", "cvm_jama", "compare"),
    stringsAsFactors = FALSE
  )
  rows <- list()
  audit <- list()
  for (i in seq_len(nrow(expected))) {
    path <- file.path(root, expected$relative_path[[i]])
    found <- nzchar(root) && file.exists(path)
    read_status <- "not found"
    data <- data.frame(stringsAsFactors = FALSE)
    if (found) {
      data <- tryCatch(read_delimited_file(path), error = function(e) {
        read_status <<- paste("read error:", conditionMessage(e))
        data.frame(stringsAsFactors = FALSE)
      })
      if (is.data.frame(data) && nrow(data)) {
        read_status <- "read"
        data$source_file_or_route <- expected$source_id[[i]]
        data$cohort_id <- if (identical(expected$source_family[[i]], "cvm_jama")) "cvm_jama_smm_day90_harmonized" else if (identical(expected$source_family[[i]], "aot_wp5_original")) "aot_wp5_original_smm" else data$cohort_id %||% ""
        rows[[length(rows) + 1L]] <- data
      }
    }
    audit[[length(audit) + 1L]] <- data.frame(
      source_id = expected$source_id[[i]],
      expected_path = expected$relative_path[[i]],
      source_family = expected$source_family[[i]],
      found = found,
      read_status = read_status,
      rows_read = if (is.data.frame(data)) nrow(data) else 0L,
      notes = if (found) "WP5 source was checked inside the configured source root." else "Expected WP5 source output was absent; related counts fail closed.",
      stringsAsFactors = FALSE
    )
  }
  list(
    cohort_entries = bind_rows_base(rows),
    cohort_route_status = bind_rows_base(list(
      smm_immunity_tracker_count_route_row("wp5_cohort_outputs", configured = nzchar(root), query_executed = nzchar(root), query_success = length(rows) > 0L, source_table = root, notes = "WP5/CVM source output reader.")
    )),
    cohort_source_audit = smm_immunity_tracker_match_empty(bind_rows_base(audit), smm_immunity_tracker_empty_wp5_source_audit())
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
  if (any(c("cohort_entries", "infection_events", "microbiology_confirmation_events") %in% names(hook))) {
    return(smm_immunity_tracker_count_placeholder_outputs(
      mode = "production_aggregate",
      reason = "SMM aggregate hook returned row-level frame names. Use smm_immunity_tracker_counts() aggregate tables only.",
      error_class = "production_aggregate_failed_privacy_contract",
      project_root = project_root,
      min_cell_count = min_cell_count
    ))
  }
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
  wp5_root <- smm_immunity_tracker_wp5_output_root(project_root)
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
  wp5 <- smm_immunity_tracker_read_wp5_cohort_frames(project_root)
  if (is.data.frame(wp5$cohort_entries) && nrow(wp5$cohort_entries)) {
    return(smm_immunity_tracker_count_outputs_from_secure_frames(
      list(
        cohort_entries = wp5$cohort_entries,
        infection_events = data.frame(stringsAsFactors = FALSE),
        microbiology_confirmation_events = data.frame(stringsAsFactors = FALSE),
        route_status = wp5$cohort_route_status,
        wp5_source_audit = wp5$cohort_source_audit
      ),
      project_root = project_root,
      min_cell_count = min_cell_count,
      mode = "production_aggregate",
      source_label = "WP5 source outputs"
    ))
  }
  smm_immunity_tracker_count_placeholder_outputs(
    mode = "production_aggregate",
    reason = "No aggregate SMM count hook or WP5 cohort source outputs were available.",
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
    scaffold$summary$value[scaffold$summary$metric == "panel_status"] <- "production aggregate available"
    scaffold$summary$status[scaffold$summary$metric == "panel_status"] <- "accepted"
    scaffold$summary$value[scaffold$summary$metric == "production_aggregate_status"] <- "aggregate output available"
    scaffold$summary$status[scaffold$summary$metric == "production_aggregate_status"] <- "accepted"
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
    if (file.exists(path)) {
      out[[nm]] <- tryCatch(read_delimited_file(path), error = function(e) empty[[nm]])
    }
  }
  out
}

smm_immunity_tracker_count_write_outputs <- function(outputs, output_dir) {
  smm_immunity_tracker_write_outputs(outputs, output_dir)
}
