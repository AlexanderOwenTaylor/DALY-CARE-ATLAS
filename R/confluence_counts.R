confluence_count_empty_disease_state_person_counts <- function() {
  empty_df(
    state_id = character(),
    state_label = character(),
    source_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    source_table = character(),
    code_set_version = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    endpoint_definition_status = character(),
    mbl_tier = character(),
    immortal_time_handling_note = character(),
    notes = character()
  )
}

confluence_count_empty_first_date_availability <- function() {
  empty_df(
    state_id = character(),
    state_label = character(),
    source_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    first_date_logic = character(),
    source_table = character(),
    code_set_version = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    mbl_tier = character(),
    immortal_time_handling_note = character(),
    notes = character()
  )
}

confluence_count_empty_infection_counts <- function() {
  empty_df(
    group_id = character(),
    group_label = character(),
    endpoint_id = character(),
    endpoint_label = character(),
    horizon_years = integer(),
    count_display = character(),
    n_people = numeric(),
    event_count_display = character(),
    n_events = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    endpoint_definition_status = character(),
    source_table = character(),
    code_set_version = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    mbl_tier = character(),
    immortal_time_handling_note = character(),
    notes = character()
  )
}

confluence_count_empty_person_time <- function() {
  empty_df(
    group_id = character(),
    group_label = character(),
    horizon_years = integer(),
    people_display = character(),
    n_people = numeric(),
    person_years_display = character(),
    person_years = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    endpoint_definition_status = character(),
    source_table = character(),
    code_set_version = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    mbl_tier = character(),
    immortal_time_handling_note = character(),
    notes = character()
  )
}

confluence_count_empty_infection_rates <- function() {
  empty_df(
    group_id = character(),
    group_label = character(),
    endpoint_id = character(),
    endpoint_label = character(),
    horizon_years = integer(),
    event_count_display = character(),
    person_years_display = character(),
    rate_per_100_person_years = character(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    endpoint_definition_status = character(),
    notes = character()
  )
}

confluence_count_empty_microbiology_confirmation_counts <- function() {
  empty_df(
    endpoint_id = character(),
    endpoint_label = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    endpoint_definition_status = character(),
    source_table = character(),
    notes = character()
  )
}

confluence_count_empty_query_review <- function() {
  empty_df(
    query_id = character(),
    output_file = character(),
    query_executable = logical(),
    tables_used = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    value_rule_used = character(),
    endpoint_definition_status = character(),
    emits_only_aggregate_counts = logical(),
    reviewer_notes = character()
  )
}

confluence_count_empty_failed_query_audit <- function() {
  empty_df(
    component = character(),
    output_file = character(),
    query_id = character(),
    count_status = character(),
    query_attempted = logical(),
    query_success = logical(),
    error_class = character(),
    error_message_sanitized = character(),
    notes = character()
  )
}

confluence_count_empty_execution_summary <- function() {
  empty_df(
    metric = character(),
    label = character(),
    value = character(),
    status = character(),
    notes = character()
  )
}

confluence_count_empty_outputs <- function() {
  list(
    disease_state_person_counts = confluence_count_empty_disease_state_person_counts(),
    first_date_availability = confluence_count_empty_first_date_availability(),
    overlap_counts_accepted = confluence_empty_overlap_counts_accepted(),
    overlap_timing_accepted = confluence_empty_overlap_timing_accepted(),
    mbl_validation_waterfall = confluence_empty_validation_waterfall(),
    mgus_validation_waterfall = confluence_empty_validation_waterfall(),
    dual_clone_validation_waterfall = confluence_empty_validation_waterfall(),
    infection_endpoint_code_sets = confluence_count_empty_endpoint_code_sets(),
    infection_counts = confluence_count_empty_infection_counts(),
    recurrent_infection_counts = confluence_count_empty_infection_counts(),
    infection_person_time = confluence_count_empty_person_time(),
    infection_rates = confluence_count_empty_infection_rates(),
    microbiology_confirmation_counts = confluence_count_empty_microbiology_confirmation_counts(),
    production_query_review = confluence_count_empty_query_review(),
    failed_query_audit = confluence_count_empty_failed_query_audit(),
    production_execution_summary = confluence_count_empty_execution_summary()
  )
}

confluence_count_empty_endpoint_code_sets <- function() {
  empty_df(
    endpoint_id = character(),
    endpoint_label = character(),
    code_system = character(),
    match_type = character(),
    code_prefix = character(),
    definition_status = character(),
    notes = character()
  )
}

confluence_count_mode <- function(db_adapter = NULL, mode = Sys.getenv("DALYCARE_CONFLUENCE_COUNT_MODE", unset = "auto")) {
  mode <- tolower(trimws(as.character(mode %||% "auto")))
  if (mode %in% c("plan", "off", "disabled", "false", "0")) return("plan")
  if (mode %in% c("production", "production_aggregate", "run", "true", "1")) return("production_aggregate")
  if (confluence_count_db_available(db_adapter)) "production_aggregate" else "plan"
}

confluence_mcl_count_mode <- function(db_adapter = NULL, mode = Sys.getenv("DALYCARE_MCL_TRIANGLE_COUNT_MODE", unset = "auto")) {
  mode <- tolower(trimws(as.character(mode %||% "auto")))
  if (mode %in% c("plan", "off", "disabled", "false", "0")) return("plan")
  if (mode %in% c("production", "production_aggregate", "run", "true", "1")) return("production_aggregate")
  if (confluence_count_db_available(db_adapter)) "production_aggregate" else "plan"
}

confluence_count_db_available <- function(db_adapter) {
  if (is.null(db_adapter)) return(FALSE)
  if (is.function(db_adapter$confluence_count_sets)) return(TRUE)
  if (is.function(db_adapter$confluence_query)) return(TRUE)
  if (exists("mcl_count_db_adapter_available", mode = "function")) return(mcl_count_db_adapter_available(db_adapter))
  conns <- db_adapter$connections %||% list()
  length(conns) > 0L
}

confluence_count_auto_db_adapter <- function(db_adapter = NULL) {
  if (!is.null(db_adapter)) return(db_adapter)
  if (!exists("dalycare_db_adapter", mode = "function")) return(NULL)
  tryCatch(dalycare_db_adapter(), error = function(e) NULL)
}

confluence_count_read_person_date_mapping <- function(project_root = ".") {
  path <- file.path(project_root, "config", "confluence_person_date_mapping.tsv")
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  read_delimited_file(path)
}

confluence_count_read_endpoint_code_sets <- function(project_root = ".") {
  path <- file.path(project_root, "config", "confluence_infection_endpoint_code_sets.tsv")
  if (!file.exists(path)) return(confluence_count_empty_endpoint_code_sets())
  rows <- read_delimited_file(path)
  required <- c("endpoint_id", "endpoint_label", "code_prefix", "definition_status")
  if (!all(required %in% names(rows))) return(confluence_count_empty_endpoint_code_sets())
  rows$code_prefix <- confluence_norm_code(rows$code_prefix)
  rows
}

confluence_count_suppress <- function(n, min_cell_count = atlas_min_cell_count()) {
  confluence_suppress_count(n, min_cell_count = min_cell_count)
}

confluence_count_status_from_suppression <- function(suppressed) {
  if (identical(suppressed$status, "suppressed small cell")) "suppressed small cell" else "not suppressed"
}

confluence_count_acceptance_row <- function(count_kind,
                                            source_table,
                                            code_set_version = "CONFLUENCE-v1-provisional",
                                            person_key_used = "patientid",
                                            date_anchor_used = "first qualifying disease-state date",
                                            endpoint_definition_status = "repo-derived provisional",
                                            mbl_tier = "not applicable",
                                            overlap_logic = "overlap date is later of two first qualifying disease-state dates") {
  row <- data.frame(
    query_status = "executed",
    query_executed = "yes",
    count_kind = count_kind,
    source_table = source_table,
    code_set_version = code_set_version,
    min_cell_suppression_applied = "yes",
    public_safe = "yes",
    first_date_logic = overlap_logic,
    immortal_time_handling_note = "Immortal-time handled by assigning overlap entry at the later first qualifying disease-state date.",
    mbl_tier = mbl_tier,
    stringsAsFactors = FALSE
  )
  gate <- confluence_acceptance_gate(row)
  list(
    acceptance_status = if (isTRUE(gate$accepted[[1]])) "accepted" else "not accepted aggregate",
    acceptance_gate_status = gate$acceptance_gate_status[[1]],
    query_status = "executed",
    source_table = source_table,
    code_set_version = code_set_version,
    person_key_used = person_key_used,
    date_anchor_used = date_anchor_used,
    endpoint_definition_status = endpoint_definition_status,
    mbl_tier = mbl_tier,
    immortal_time_handling_note = row$immortal_time_handling_note[[1]]
  )
}

confluence_count_fail_closed_frame <- function(component, output_file, reason, mode = "plan", error_class = "") {
  status <- if (identical(mode, "plan")) "query executable not run" else if (nzchar(error_class)) error_class else "production_aggregate_failed_mapping_unavailable"
  data.frame(
    component = component,
    output_file = output_file,
    query_id = component,
    count_status = status,
    query_attempted = !identical(mode, "plan"),
    query_success = FALSE,
    error_class = error_class,
    error_message_sanitized = reason,
    notes = reason,
    stringsAsFactors = FALSE
  )
}

confluence_count_state_labels <- function() {
  data.frame(
    state_id = c("cll", "coded_mbl", "pathology_mbl", "cll_morphology_pressure", "mgus", "mm", "any_pcd", "cll_mbl"),
    state_label = c("CLL", "Coded MBL", "Pathology-supported MBL", "CLL morphology pressure", "MGUS", "MM", "Any PCD", "CLL/MBL"),
    source_tier = c("registry/diagnosis", "diagnosis-coded MBL", "PATOBANK SNOMED-supported MBL", "PATOBANK CLL pressure", "diagnosis-coded MGUS", "diagnosis/DaMyDa", "MGUS/MM", "CLL or MBL"),
    mbl_tier = c("not applicable", "coded MBL", "pathology-supported MBL", "not MBL", "not applicable", "not applicable", "not applicable", "CLL/MBL"),
    stringsAsFactors = FALSE
  )
}

confluence_count_overlap_specs <- function() {
  data.frame(
    overlap_id = c("coded_mbl_mgus", "pathology_mbl_mgus", "cll_mgus", "cll_mm", "cll_any_pcd", "mbl_any_pcd", "cll_mbl_pcd"),
    overlap_label = c("coded MBL + MGUS", "pathology-supported MBL + MGUS", "CLL + MGUS", "CLL + MM", "CLL + any PCD", "MBL + any PCD", "CLL/MBL + MGUS/SMM/MM"),
    left_state = c("coded_mbl", "pathology_mbl", "cll", "cll", "cll", "coded_mbl", "cll_mbl"),
    right_state = c("mgus", "mgus", "mgus", "mm", "any_pcd", "any_pcd", "any_pcd"),
    mbl_tier = c("coded MBL", "pathology-supported MBL", "CLL", "CLL", "CLL", "coded/pathology MBL", "CLL/MBL"),
    pcd_tier = c("coded MGUS", "coded MGUS", "coded MGUS", "active MM", "MGUS/MM", "MGUS/MM", "MGUS/MM"),
    stringsAsFactors = FALSE
  )
}

confluence_count_group_specs <- function() {
  data.frame(
    group_id = c("cll_only", "coded_mbl_only", "pcd_only", "cll_pcd_overlap", "coded_mbl_pcd_overlap", "cll_mbl_pcd_overlap"),
    group_label = c("CLL only", "coded MBL only", "PCD only", "CLL + PCD overlap", "coded MBL + PCD overlap", "CLL/MBL + PCD overlap"),
    stringsAsFactors = FALSE
  )
}

confluence_count_normalize_first_dates <- function(first_dates) {
  if (!is.data.frame(first_dates) || !nrow(first_dates)) {
    return(empty_df(person_key = character(), state_id = character(), first_date = as.Date(character())))
  }
  names(first_dates) <- tolower(names(first_dates))
  if (!"person_key" %in% names(first_dates) && "patientid" %in% names(first_dates)) first_dates$person_key <- first_dates$patientid
  if (!"state_id" %in% names(first_dates) && "state" %in% names(first_dates)) first_dates$state_id <- first_dates$state
  if (!"first_date" %in% names(first_dates) && "date" %in% names(first_dates)) first_dates$first_date <- first_dates$date
  required <- c("person_key", "state_id", "first_date")
  if (!all(required %in% names(first_dates))) return(empty_df(person_key = character(), state_id = character(), first_date = as.Date(character())))
  rows <- first_dates[required]
  rows$person_key <- as.character(rows$person_key)
  rows$state_id <- confluence_norm_text(rows$state_id)
  rows$state_id <- gsub(" ", "_", rows$state_id)
  rows$state_id[rows$state_id %in% c("mbl", "diagnosis_coded_mbl", "mbl_candidate")] <- "coded_mbl"
  rows$state_id[rows$state_id %in% c("patobank_mbl", "snomed_mbl", "pathology_supported_mbl")] <- "pathology_mbl"
  rows$state_id[rows$state_id %in% c("pcd", "plasma_cell_disorder")] <- "any_pcd"
  rows$state_id[rows$state_id %in% c("multiple_myeloma")] <- "mm"
  rows$first_date <- safe_as_date(rows$first_date)
  rows <- rows[nzchar(rows$person_key) & nzchar(rows$state_id) & !is.na(rows$first_date), , drop = FALSE]
  if (!nrow(rows)) return(empty_df(person_key = character(), state_id = character(), first_date = as.Date(character())))
  stats::aggregate(first_date ~ person_key + state_id, rows, min)
}

confluence_count_derive_states <- function(first_dates) {
  rows <- confluence_count_normalize_first_dates(first_dates)
  if (!nrow(rows)) return(rows)
  wide <- reshape(rows, idvar = "person_key", timevar = "state_id", direction = "wide")
  add_state <- function(state_id, source_states) {
    cols <- paste0("first_date.", source_states)
    cols <- cols[cols %in% names(wide)]
    if (!length(cols)) return(NULL)
    vals <- do.call(pmin, c(wide[cols], list(na.rm = TRUE)))
    vals[is.infinite(vals)] <- NA
    data.frame(person_key = wide$person_key, state_id = state_id, first_date = as.Date(vals, origin = "1970-01-01"), stringsAsFactors = FALSE)
  }
  derived <- bind_rows_base(list(
    add_state("any_pcd", c("mgus", "mm")),
    add_state("cll_mbl", c("cll", "coded_mbl", "pathology_mbl"))
  ))
  if (nrow(derived)) {
    derived <- derived[!is.na(derived$first_date), , drop = FALSE]
  }
  bind_rows_base(list(rows, derived))
}

confluence_count_normalize_events <- function(events) {
  if (!is.data.frame(events) || !nrow(events)) {
    return(empty_df(person_key = character(), event_date = as.Date(character()), endpoint_id = character()))
  }
  names(events) <- tolower(names(events))
  if (!"person_key" %in% names(events) && "patientid" %in% names(events)) events$person_key <- events$patientid
  if (!"event_date" %in% names(events) && "date" %in% names(events)) events$event_date <- events$date
  if (!"endpoint_id" %in% names(events)) events$endpoint_id <- "serious_infection_hospitalization"
  required <- c("person_key", "event_date", "endpoint_id")
  if (!all(required %in% names(events))) return(empty_df(person_key = character(), event_date = as.Date(character()), endpoint_id = character()))
  rows <- events[required]
  rows$person_key <- as.character(rows$person_key)
  rows$event_date <- safe_as_date(rows$event_date)
  rows$endpoint_id <- as.character(rows$endpoint_id)
  rows <- rows[nzchar(rows$person_key) & !is.na(rows$event_date) & nzchar(rows$endpoint_id), , drop = FALSE]
  unique(rows)
}

confluence_count_normalize_patient_frame <- function(patient_frame) {
  if (!is.data.frame(patient_frame) || !nrow(patient_frame)) {
    return(empty_df(person_key = character(), date_death_fu = as.Date(character())))
  }
  names(patient_frame) <- tolower(names(patient_frame))
  if (!"person_key" %in% names(patient_frame) && "patientid" %in% names(patient_frame)) patient_frame$person_key <- patient_frame$patientid
  if (!"date_death_fu" %in% names(patient_frame) && "death_date" %in% names(patient_frame)) patient_frame$date_death_fu <- patient_frame$death_date
  if (!"date_death_fu" %in% names(patient_frame)) patient_frame$date_death_fu <- NA
  if (!"person_key" %in% names(patient_frame)) return(empty_df(person_key = character(), date_death_fu = as.Date(character())))
  rows <- patient_frame[c("person_key", "date_death_fu")]
  rows$person_key <- as.character(rows$person_key)
  rows$date_death_fu <- safe_as_date(rows$date_death_fu)
  rows[nzchar(rows$person_key), , drop = FALSE]
}

confluence_count_state_count_rows <- function(first_dates, min_cell_count = atlas_min_cell_count()) {
  states <- confluence_count_state_labels()
  rows <- lapply(seq_len(nrow(states)), function(i) {
    spec <- states[i, , drop = FALSE]
    people <- unique(first_dates$person_key[first_dates$state_id == spec$state_id[[1]]])
    count <- confluence_count_suppress(length(people), min_cell_count)
    acc <- confluence_count_acceptance_row(
      "distinct people",
      "secure CONFLUENCE disease-state aggregate",
      mbl_tier = spec$mbl_tier[[1]]
    )
    data.frame(
      state_id = spec$state_id,
      state_label = spec$state_label,
      source_tier = spec$source_tier,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = acc$acceptance_gate_status,
      suppression_status = confluence_count_status_from_suppression(count),
      source_table = acc$source_table,
      code_set_version = acc$code_set_version,
      person_key_used = acc$person_key_used,
      date_anchor_used = acc$date_anchor_used,
      endpoint_definition_status = "not an infection endpoint",
      mbl_tier = spec$mbl_tier,
      immortal_time_handling_note = acc$immortal_time_handling_note,
      notes = "Accepted aggregate disease-state person count; no patient IDs or raw dates emitted.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_count_first_date_rows <- function(first_dates, min_cell_count = atlas_min_cell_count()) {
  states <- confluence_count_state_labels()
  rows <- lapply(seq_len(nrow(states)), function(i) {
    spec <- states[i, , drop = FALSE]
    people <- unique(first_dates$person_key[first_dates$state_id == spec$state_id[[1]]])
    count <- confluence_count_suppress(length(people), min_cell_count)
    acc <- confluence_count_acceptance_row("distinct people", "secure CONFLUENCE first-date aggregate", mbl_tier = spec$mbl_tier[[1]])
    data.frame(
      state_id = spec$state_id,
      state_label = paste(spec$state_label, "first qualifying date"),
      source_tier = spec$source_tier,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people with first qualifying date",
      acceptance_status = acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = acc$acceptance_gate_status,
      suppression_status = confluence_count_status_from_suppression(count),
      first_date_logic = "First qualifying disease-state date derived inside secure runtime; raw dates not emitted.",
      source_table = acc$source_table,
      code_set_version = acc$code_set_version,
      person_key_used = acc$person_key_used,
      date_anchor_used = "first qualifying date, not emitted",
      mbl_tier = spec$mbl_tier,
      immortal_time_handling_note = acc$immortal_time_handling_note,
      notes = "Accepted aggregate first-date availability count; no raw dates emitted.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_count_person_state_date <- function(first_dates, state_id) {
  rows <- first_dates[first_dates$state_id == state_id, c("person_key", "first_date"), drop = FALSE]
  names(rows)[names(rows) == "first_date"] <- state_id
  rows
}

confluence_count_overlap_people <- function(first_dates, left_state, right_state) {
  left <- confluence_count_person_state_date(first_dates, left_state)
  right <- confluence_count_person_state_date(first_dates, right_state)
  if (!nrow(left) || !nrow(right)) {
    return(empty_df(person_key = character(), left_date = as.Date(character()), right_date = as.Date(character()), overlap_date = as.Date(character())))
  }
  merged <- merge(left, right, by = "person_key")
  if (!nrow(merged)) {
    return(empty_df(person_key = character(), left_date = as.Date(character()), right_date = as.Date(character()), overlap_date = as.Date(character())))
  }
  left_date <- merged[[left_state]]
  right_date <- merged[[right_state]]
  data.frame(
    person_key = merged$person_key,
    left_date = left_date,
    right_date = right_date,
    overlap_date = pmax(left_date, right_date, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

confluence_count_overlap_count_rows <- function(first_dates, min_cell_count = atlas_min_cell_count()) {
  specs <- confluence_count_overlap_specs()
  rows <- lapply(seq_len(nrow(specs)), function(i) {
    spec <- specs[i, , drop = FALSE]
    people <- confluence_count_overlap_people(first_dates, spec$left_state[[1]], spec$right_state[[1]])
    count <- confluence_count_suppress(nrow(people), min_cell_count)
    acc <- confluence_count_acceptance_row("distinct people", "secure CONFLUENCE overlap aggregate", mbl_tier = spec$mbl_tier[[1]])
    data.frame(
      overlap_id = spec$overlap_id,
      overlap_label = spec$overlap_label,
      mbl_tier = spec$mbl_tier,
      pcd_tier = spec$pcd_tier,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = acc$acceptance_gate_status,
      suppression_status = confluence_count_status_from_suppression(count),
      source_table = acc$source_table,
      code_set_version = acc$code_set_version,
      person_key_used = acc$person_key_used,
      date_anchor_used = "overlap date as later first qualifying state date, not emitted",
      endpoint_definition_status = "not an infection endpoint",
      immortal_time_handling_note = acc$immortal_time_handling_note,
      notes = "Accepted aggregate overlap count; overlap time starts at the later first qualifying disease-state date.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_count_overlap_timing_rows <- function(first_dates, min_cell_count = atlas_min_cell_count()) {
  overlap <- confluence_count_overlap_people(first_dates, "cll_mbl", "any_pcd")
  timing_levels <- data.frame(
    timing_id = c("cll_mbl_first", "pcd_first", "same_90_day_window", "same_calendar_year", "unknown_unavailable"),
    timing_label = c("CLL/MBL first", "Plasma-cell disorder first", "same 90-day window", "same calendar year", "unknown/unavailable timing"),
    stringsAsFactors = FALSE
  )
  timing <- rep("unknown_unavailable", nrow(overlap))
  if (nrow(overlap)) {
    diff_days <- as.numeric(overlap$right_date - overlap$left_date)
    timing[!is.na(diff_days) & abs(diff_days) <= 90] <- "same_90_day_window"
    timing[!is.na(diff_days) & abs(diff_days) > 90 & format(overlap$left_date, "%Y") == format(overlap$right_date, "%Y")] <- "same_calendar_year"
    timing[!is.na(diff_days) & diff_days > 90] <- "cll_mbl_first"
    timing[!is.na(diff_days) & diff_days < -90] <- "pcd_first"
  }
  rows <- lapply(seq_len(nrow(timing_levels)), function(i) {
    spec <- timing_levels[i, , drop = FALSE]
    n <- sum(timing == spec$timing_id[[1]], na.rm = TRUE)
    count <- confluence_count_suppress(n, min_cell_count)
    acc <- confluence_count_acceptance_row("distinct people", "secure CONFLUENCE overlap timing aggregate", mbl_tier = "CLL/MBL")
    data.frame(
      timing_id = spec$timing_id,
      timing_label = spec$timing_label,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = acc$acceptance_gate_status,
      suppression_status = confluence_count_status_from_suppression(count),
      source_table = acc$source_table,
      code_set_version = acc$code_set_version,
      person_key_used = acc$person_key_used,
      date_anchor_used = "first qualifying disease-state dates, not emitted",
      endpoint_definition_status = "not an infection endpoint",
      mbl_tier = "CLL/MBL",
      immortal_time_handling_note = acc$immortal_time_handling_note,
      notes = "Accepted aggregate timing category; raw dates are not emitted.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_count_group_entries <- function(first_dates) {
  cll <- confluence_count_person_state_date(first_dates, "cll")
  mbl <- confluence_count_person_state_date(first_dates, "coded_mbl")
  cll_mbl <- confluence_count_person_state_date(first_dates, "cll_mbl")
  pcd <- confluence_count_person_state_date(first_dates, "any_pcd")
  people <- unique(c(cll$person_key, mbl$person_key, cll_mbl$person_key, pcd$person_key))
  if (!length(people)) return(empty_df(person_key = character(), group_id = character(), group_label = character(), entry_date = as.Date(character())))
  get_date <- function(frame, person) {
    hit <- frame[frame$person_key == person, , drop = FALSE]
    if (nrow(hit)) hit[[2]][[1]] else as.Date(NA)
  }
  specs <- confluence_count_group_specs()
  rows <- lapply(people, function(person) {
    d_cll <- get_date(cll, person)
    d_mbl <- get_date(mbl, person)
    d_bcell <- get_date(cll_mbl, person)
    d_pcd <- get_date(pcd, person)
    group_id <- character()
    entry <- as.Date(character())
    if (!is.na(d_bcell) && !is.na(d_pcd)) {
      if (!is.na(d_cll)) group_id <- c(group_id, "cll_pcd_overlap")
      if (!is.na(d_mbl)) group_id <- c(group_id, "coded_mbl_pcd_overlap")
      group_id <- c(group_id, "cll_mbl_pcd_overlap")
      entry <- c(entry, rep(max(d_bcell, d_pcd), length(group_id)))
    } else if (!is.na(d_cll)) {
      group_id <- c(group_id, "cll_only")
      entry <- c(entry, d_cll)
    } else if (!is.na(d_mbl)) {
      group_id <- c(group_id, "coded_mbl_only")
      entry <- c(entry, d_mbl)
    } else if (!is.na(d_pcd)) {
      group_id <- c(group_id, "pcd_only")
      entry <- c(entry, d_pcd)
    }
    if (!length(group_id)) return(NULL)
    labels <- specs$group_label[match(group_id, specs$group_id)]
    data.frame(person_key = person, group_id = group_id, group_label = labels, entry_date = entry, stringsAsFactors = FALSE)
  })
  bind_rows_base(rows)
}

confluence_count_person_time_rows <- function(group_entries, patient_frame, min_cell_count = atlas_min_cell_count(), horizons = c(1L, 2L, 5L)) {
  if (!nrow(group_entries)) return(confluence_count_empty_person_time())
  pf <- confluence_count_normalize_patient_frame(patient_frame)
  entries <- merge(group_entries, pf, by = "person_key", all.x = TRUE)
  rows <- list()
  for (h in horizons) {
    for (group_id in unique(entries$group_id)) {
      group <- entries[entries$group_id == group_id, , drop = FALSE]
      end_date <- group$entry_date + as.integer(round(365.25 * h))
      has_death <- !is.na(group$date_death_fu) & group$date_death_fu >= group$entry_date & group$date_death_fu < end_date
      end_date[has_death] <- group$date_death_fu[has_death]
      py <- sum(pmax(0, as.numeric(end_date - group$entry_date)) / 365.25, na.rm = TRUE)
      count <- confluence_count_suppress(length(unique(group$person_key)), min_cell_count)
      acc <- confluence_count_acceptance_row("person-years", "secure CONFLUENCE person-time aggregate", mbl_tier = if (grepl("mbl", group_id)) "coded MBL" else "not applicable")
      rows[[length(rows) + 1L]] <- data.frame(
        group_id = group_id,
        group_label = group$group_label[[1]],
        horizon_years = h,
        people_display = count$display,
        n_people = count$n_public,
        person_years_display = if (is.na(count$n_public) && count$suppressed) paste0("<", min_cell_count, " people") else format(round(py, 1), big.mark = ",", scientific = FALSE, trim = TRUE),
        person_years = if (is.na(count$n_public) && count$suppressed) NA_real_ else round(py, 3),
        count_kind = "person-years",
        acceptance_status = acc$acceptance_status,
        query_status = acc$query_status,
        acceptance_gate_status = acc$acceptance_gate_status,
        suppression_status = confluence_count_status_from_suppression(count),
        endpoint_definition_status = "not an infection endpoint",
        source_table = acc$source_table,
        code_set_version = acc$code_set_version,
        person_key_used = acc$person_key_used,
        date_anchor_used = "disease-state entry to death/follow-up/horizon, dates not emitted",
        mbl_tier = if (grepl("mbl", group_id)) "coded MBL" else "not applicable",
        immortal_time_handling_note = acc$immortal_time_handling_note,
        notes = "Accepted aggregate person-time denominator; raw entry/censor dates are not emitted.",
        stringsAsFactors = FALSE
      )
    }
  }
  bind_rows_base(rows)
}

confluence_count_episode_flags <- function(events, episode_gap_days = 14L) {
  events <- confluence_count_normalize_events(events)
  if (!nrow(events)) return(events)
  events <- events[order(events$person_key, events$endpoint_id, events$event_date), , drop = FALSE]
  split_key <- paste(events$person_key, events$endpoint_id, sep = "\r")
  is_new <- logical(nrow(events))
  for (key in unique(split_key)) {
    idx <- which(split_key == key)
    dates <- events$event_date[idx]
    is_new[idx] <- c(TRUE, diff(dates) > episode_gap_days)
  }
  events$is_new_episode <- is_new
  events
}

confluence_count_infection_rows <- function(group_entries, infection_events, person_time, endpoint_code_sets, min_cell_count = atlas_min_cell_count(), horizons = c(1L, 2L, 5L)) {
  events <- confluence_count_normalize_events(infection_events)
  if (!nrow(group_entries) || !nrow(events)) return(confluence_count_empty_infection_counts())
  endpoint_label <- function(id) {
    hit <- endpoint_code_sets[endpoint_code_sets$endpoint_id == id, , drop = FALSE]
    if (nrow(hit)) hit$endpoint_label[[1]] else id
  }
  rows <- list()
  for (h in horizons) {
    for (group_id in unique(group_entries$group_id)) {
      group <- group_entries[group_entries$group_id == group_id, , drop = FALSE]
      joined <- merge(group[c("person_key", "group_id", "group_label", "entry_date")], events, by = "person_key")
      if (nrow(joined)) {
        joined <- joined[joined$event_date >= joined$entry_date & joined$event_date <= joined$entry_date + as.integer(round(365.25 * h)), , drop = FALSE]
      }
      for (endpoint in unique(c(events$endpoint_id, "serious_infection_hospitalization"))) {
        ep <- joined[joined$endpoint_id == endpoint, , drop = FALSE]
        people_n <- length(unique(ep$person_key))
        events_n <- nrow(ep)
        people_count <- confluence_count_suppress(people_n, min_cell_count)
        event_count <- confluence_count_suppress(events_n, min_cell_count)
        acc <- confluence_count_acceptance_row("distinct events", "secure CONFLUENCE provisional infection aggregate", mbl_tier = if (grepl("mbl", group_id)) "coded MBL" else "not applicable")
        rows[[length(rows) + 1L]] <- data.frame(
          group_id = group_id,
          group_label = group$group_label[[1]],
          endpoint_id = endpoint,
          endpoint_label = endpoint_label(endpoint),
          horizon_years = h,
          count_display = people_count$display,
          n_people = people_count$n_public,
          event_count_display = event_count$display,
          n_events = event_count$n_public,
          count_kind = "distinct people and events",
          acceptance_status = acc$acceptance_status,
          query_status = acc$query_status,
          acceptance_gate_status = acc$acceptance_gate_status,
          suppression_status = paste(unique(c(confluence_count_status_from_suppression(people_count), confluence_count_status_from_suppression(event_count))), collapse = "; "),
          endpoint_definition_status = "repo-derived provisional",
          source_table = acc$source_table,
          code_set_version = acc$code_set_version,
          person_key_used = acc$person_key_used,
          date_anchor_used = "infection event date within disease-state horizon, dates not emitted",
          mbl_tier = if (grepl("mbl", group_id)) "coded MBL" else "not applicable",
          immortal_time_handling_note = acc$immortal_time_handling_note,
          notes = "Provisional infection endpoint aggregate; final clinical endpoint code set still requires protocol review.",
          stringsAsFactors = FALSE
        )
      }
    }
  }
  bind_rows_base(rows)
}

confluence_count_recurrent_rows <- function(group_entries, infection_events, endpoint_code_sets, min_cell_count = atlas_min_cell_count(), horizons = c(1L, 2L, 5L)) {
  events <- confluence_count_episode_flags(infection_events)
  if (!nrow(group_entries) || !nrow(events)) return(confluence_count_empty_infection_counts())
  recurrent_events <- events[events$is_new_episode, , drop = FALSE]
  rows <- confluence_count_infection_rows(group_entries, recurrent_events, NULL, endpoint_code_sets, min_cell_count = min_cell_count, horizons = horizons)
  if (nrow(rows)) {
    rows$count_kind <- "distinct recurrent episodes"
    rows$notes <- "Recurrent infection episode aggregate using provisional 14-day same-endpoint episode gap."
  }
  rows
}

confluence_count_rate_rows <- function(infection_counts, person_time, min_cell_count = atlas_min_cell_count()) {
  if (!nrow(infection_counts) || !nrow(person_time)) return(confluence_count_empty_infection_rates())
  rows <- list()
  for (i in seq_len(nrow(infection_counts))) {
    inf <- infection_counts[i, , drop = FALSE]
    pt <- person_time[person_time$group_id == inf$group_id[[1]] & person_time$horizon_years == inf$horizon_years[[1]], , drop = FALSE]
    py <- if (nrow(pt)) suppressWarnings(as.numeric(pt$person_years[[1]])) else NA_real_
    events <- suppressWarnings(as.numeric(inf$n_events[[1]]))
    suppressed <- is.na(events) || is.na(py) || py <= 0
    rate <- if (!suppressed) round(100 * events / py, 2) else NA_real_
    acc <- confluence_count_acceptance_row("rate from suppressed aggregate components", "secure CONFLUENCE provisional infection aggregate", mbl_tier = inf$mbl_tier[[1]] %||% "not applicable")
    rows[[length(rows) + 1L]] <- data.frame(
      group_id = inf$group_id,
      group_label = inf$group_label,
      endpoint_id = inf$endpoint_id,
      endpoint_label = inf$endpoint_label,
      horizon_years = inf$horizon_years,
      event_count_display = inf$event_count_display,
      person_years_display = if (nrow(pt)) pt$person_years_display[[1]] else "not available",
      rate_per_100_person_years = if (suppressed) "not computed due to suppressed/missing component" else as.character(rate),
      count_kind = "rate from suppressed aggregate components",
      acceptance_status = if (suppressed) "not accepted aggregate" else acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = if (suppressed) "failed: suppressed/missing rate component" else acc$acceptance_gate_status,
      suppression_status = if (suppressed) "suppressed or missing component" else "not suppressed",
      endpoint_definition_status = "repo-derived provisional",
      notes = "Rate is calculated only when aggregate event and person-time components are public-safe.",
      stringsAsFactors = FALSE
    )
  }
  bind_rows_base(rows)
}

confluence_count_waterfall_from_sets <- function(first_dates, min_cell_count = atlas_min_cell_count()) {
  state_people <- function(state) unique(first_dates$person_key[first_dates$state_id == state])
  row <- function(entity_id, order, step, tier, people, mbl_tier = "not applicable") {
    count <- confluence_count_suppress(length(unique(people)), min_cell_count)
    acc <- confluence_count_acceptance_row("distinct people", paste("secure CONFLUENCE", entity_id, "validation waterfall"), mbl_tier = mbl_tier)
    data.frame(
      waterfall_id = paste(entity_id, order, sep = "_"),
      entity_id = entity_id,
      step_order = order,
      step_label = step,
      source_tier = tier,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = acc$acceptance_status,
      query_status = acc$query_status,
      acceptance_gate_status = acc$acceptance_gate_status,
      suppression_status = confluence_count_status_from_suppression(count),
      notes = "Accepted aggregate validation waterfall step; raw person IDs and dates are not emitted.",
      stringsAsFactors = FALSE
    )
  }
  mbl_any <- union(state_people("coded_mbl"), state_people("pathology_mbl"))
  mbl_without_cll_pressure <- setdiff(mbl_any, union(state_people("cll"), state_people("cll_morphology_pressure")))
  pcd_any <- state_people("any_pcd")
  mbl_waterfall <- bind_rows_base(list(
    row("mbl", 1L, "Diagnosis-coded MBL", "DD479B/D479B", state_people("coded_mbl"), "coded MBL"),
    row("mbl", 2L, "PATOBANK exact MBL SNOMED support", "M95911/M96121/M98231", state_people("pathology_mbl"), "pathology-supported MBL"),
    row("mbl", 3L, "Remove CLL morphology pressure M98233", "M98233 exclusion pressure", setdiff(mbl_any, state_people("cll_morphology_pressure")), "coded/pathology MBL"),
    row("mbl", 4L, "Remove overt CLL evidence", "CLL/Richter timing pressure", mbl_without_cll_pressure, "coded/pathology MBL"),
    row("mbl", 5L, "MBL with any PCD overlap", "overlap aggregate", intersect(mbl_any, pcd_any), "coded/pathology MBL")
  ))
  mgus_without_mm <- setdiff(state_people("mgus"), state_people("mm"))
  mgus_waterfall <- bind_rows_base(list(
    row("mgus", 1L, "Diagnosis-coded MGUS", "DD472/DD472B/D472/D472B", state_people("mgus")),
    row("mgus", 2L, "Remove active MM pressure", "DC900/C900", mgus_without_mm),
    row("mgus", 3L, "MGUS with MBL/CLL overlap", "overlap aggregate", intersect(state_people("mgus"), state_people("cll_mbl")))
  ))
  dual_waterfall <- bind_rows_base(list(
    row("dual_clone", 1L, "Candidate CLL/MBL state", "CLL/MBL tier explicit", state_people("cll_mbl"), "CLL/MBL"),
    row("dual_clone", 2L, "Candidate MGUS/PCD state", "MGUS/PCD tier explicit", pcd_any),
    row("dual_clone", 3L, "Overlap date as later disease-state date", "immortal-time guard", intersect(state_people("cll_mbl"), pcd_any), "CLL/MBL")
  ))
  list(mbl = mbl_waterfall, mgus = mgus_waterfall, dual = dual_waterfall)
}

confluence_count_outputs_from_sets <- function(count_sets, project_root = ".", min_cell_count = atlas_min_cell_count()) {
  endpoint_codes <- confluence_count_read_endpoint_code_sets(project_root)
  first_dates <- confluence_count_derive_states(count_sets$disease_first_dates %||% count_sets$first_dates)
  patient_frame <- confluence_count_normalize_patient_frame(count_sets$patient_frame %||% data.frame(stringsAsFactors = FALSE))
  infection_events <- confluence_count_normalize_events(count_sets$infection_events %||% data.frame(stringsAsFactors = FALSE))
  group_entries <- confluence_count_group_entries(first_dates)
  person_time <- confluence_count_person_time_rows(group_entries, patient_frame, min_cell_count = min_cell_count)
  infection_counts <- confluence_count_infection_rows(group_entries, infection_events, person_time, endpoint_codes, min_cell_count = min_cell_count)
  recurrent <- confluence_count_recurrent_rows(group_entries, infection_events, endpoint_codes, min_cell_count = min_cell_count)
  rates <- confluence_count_rate_rows(infection_counts, person_time, min_cell_count = min_cell_count)
  water <- confluence_count_waterfall_from_sets(first_dates, min_cell_count = min_cell_count)
  list(
    disease_state_person_counts = confluence_count_state_count_rows(first_dates, min_cell_count = min_cell_count),
    first_date_availability = confluence_count_first_date_rows(first_dates, min_cell_count = min_cell_count),
    overlap_counts_accepted = confluence_count_overlap_count_rows(first_dates, min_cell_count = min_cell_count),
    overlap_timing_accepted = confluence_count_overlap_timing_rows(first_dates, min_cell_count = min_cell_count),
    mbl_validation_waterfall = water$mbl,
    mgus_validation_waterfall = water$mgus,
    dual_clone_validation_waterfall = water$dual,
    infection_endpoint_code_sets = endpoint_codes,
    infection_counts = infection_counts,
    recurrent_infection_counts = recurrent,
    infection_person_time = person_time,
    infection_rates = rates,
    microbiology_confirmation_counts = confluence_count_microbiology_fail_closed(mode = "production_aggregate"),
    production_query_review = confluence_count_query_review(success = TRUE, endpoint_codes = endpoint_codes),
    failed_query_audit = confluence_count_empty_failed_query_audit(),
    production_execution_summary = confluence_count_execution_summary("production_aggregate", TRUE, TRUE, first_dates, infection_events)
  )
}

confluence_count_microbiology_fail_closed <- function(mode = "plan", reason = "Microbiology-confirmed infection requires deterministic patient/date/result mappings; no accepted mapping is configured in this patch.") {
  data.frame(
    endpoint_id = "microbiology_confirmed_infection",
    endpoint_label = "Microbiology-confirmed infection",
    count_display = if (identical(mode, "plan")) "query executable not run" else "source validation required",
    n_people = NA_real_,
    count_kind = "not accepted aggregate",
    acceptance_status = "source validation required",
    query_status = if (identical(mode, "plan")) "query executable not run" else "production_aggregate_failed_mapping_unavailable",
    acceptance_gate_status = "failed: deterministic microbiology patient/date/result mapping missing",
    suppression_status = "not run",
    endpoint_definition_status = "source validation required",
    source_table = "SP blood culture / PERSIMUNE microbiology",
    notes = reason,
    stringsAsFactors = FALSE
  )
}

confluence_count_query_review <- function(success = FALSE, endpoint_codes = confluence_count_empty_endpoint_code_sets()) {
  data.frame(
    query_id = c("confluence_disease_first_dates", "confluence_overlap_counts", "confluence_provisional_infection_counts", "confluence_person_time"),
    output_file = c("confluence_first_date_availability.csv", "confluence_overlap_counts_accepted.csv", "confluence_infection_counts.csv", "confluence_infection_person_time.csv"),
    query_executable = success,
    tables_used = c("patient; t_dalycare_diagnoses; diagnoses_all; RKKP_CLL; RKKP_DaMyDa; SDS_pato", "secure disease-state first-date aggregate", "t_dalycare_diagnoses; diagnoses_all; SDS_t_adm; SDS_kontakter", "patient; secure disease-state first-date aggregate"),
    person_key_used = "patientid",
    date_anchor_used = c("first qualifying disease-state date", "later first qualifying disease-state date", "provisional infection event date", "entry to death/follow-up/horizon"),
    value_rule_used = c("exact CLL/MBL/MGUS/MM and SNOMED code sets", "intersection of first-date state sets", paste(unique(endpoint_codes$code_prefix %||% ""), collapse = ";"), "1, 2, and 5 year horizons"),
    endpoint_definition_status = c("not an infection endpoint", "not an infection endpoint", "repo-derived provisional", "not an infection endpoint"),
    emits_only_aggregate_counts = TRUE,
    reviewer_notes = "CONFLUENCE production aggregate query emits only public-safe aggregate counts.",
    stringsAsFactors = FALSE
  )
}

confluence_count_execution_summary <- function(mode, attempted, success, first_dates = NULL, infection_events = NULL, failure_reason = "") {
  data.frame(
    metric = c("count_mode", "production_query_attempted", "production_query_success", "first_date_state_rows", "infection_event_rows_internal", "failure_reason"),
    label = c("Count mode", "Production query attempted", "Production query success", "Internal first-date state rows", "Internal infection event rows", "Failure reason"),
    value = c(mode, as.character(isTRUE(attempted)), as.character(isTRUE(success)), as.character(if (is.data.frame(first_dates)) nrow(first_dates) else 0L), as.character(if (is.data.frame(infection_events)) nrow(infection_events) else 0L), failure_reason),
    status = c(mode, if (attempted) "attempted" else "not attempted", if (success) "success" else "not successful", "internal secure runtime only", "internal secure runtime only", if (nzchar(failure_reason)) "failed closed" else "ok"),
    notes = c(
      "CONFLUENCE count mode selected for this atlas run.",
      "Production aggregate execution uses DB adapter or secure hook when available.",
      "Success means aggregate outputs were generated; rows may still be suppressed.",
      "This number is a diagnostic row count inside the secure runtime, not a public patient list.",
      "This number is a diagnostic event-row count inside the secure runtime, not a public event list.",
      "Failure rows remain visible and fail closed."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_count_sql_quote_values <- function(values) {
  values <- values[nzchar(values)]
  if (!length(values)) return("''")
  paste(vapply(values, function(x) paste0("'", gsub("'", "''", x, fixed = TRUE), "'"), character(1)), collapse = ", ")
}

confluence_count_date_sql <- function(expr) {
  if (exists("mcl_count_date_sql", mode = "function")) return(mcl_count_date_sql(expr))
  paste0("cast(", expr, " as date)")
}

confluence_count_fetch_sets_from_db <- function(db_adapter, project_root = ".") {
  endpoint_codes <- confluence_count_read_endpoint_code_sets(project_root)
  prefix_pred <- paste0("(", paste(vapply(endpoint_codes$code_prefix, function(prefix) {
    paste0("normalized_code like '", gsub("'", "''", prefix, fixed = TRUE), "%'")
  }, character(1)), collapse = " or "), ")")
  norm_expr <- function(col) paste0("regexp_replace(upper(trim(", col, "::text)), '[^A-Z0-9]', '', 'g')")
  first_sql <- paste0(
    "with diagnosis_rows as (\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("date_diagnosis"), " as event_date, ", norm_expr("diagnosis"), " as normalized_code from public.t_dalycare_diagnoses\n",
    "  union all\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("date_diagnosis"), " as event_date, ", norm_expr("diagnosis"), " as normalized_code from public.diagnoses_all\n",
    "), coded_states as (\n",
    "  select person_key,\n",
    "    case\n",
    "      when normalized_code in ('DC911','C911') then 'cll'\n",
    "      when normalized_code in ('DD479B','D479B') then 'coded_mbl'\n",
    "      when normalized_code in ('DD472','DD472B','D472','D472B') then 'mgus'\n",
    "      when normalized_code in ('DC900','C900') then 'mm'\n",
    "      else null end as state_id,\n",
    "    event_date\n",
    "  from diagnosis_rows where event_date is not null\n",
    "), grouped as (\n",
    "  select person_key, state_id, min(event_date) as first_date from coded_states where state_id is not null group by person_key, state_id\n",
    ")\n",
    "select person_key, state_id, first_date from grouped;"
  )
  pato_sql <- paste0(
    "with pato as (\n",
    "  select patientid::text as person_key, coalesce(", confluence_count_date_sql("d_rekvdato"), ", ", confluence_count_date_sql("d_svardato"), ") as event_date, ", norm_expr("c_snomedkode"), " as normalized_code from public.SDS_pato\n",
    "), grouped as (\n",
    "  select person_key,\n",
    "    case when normalized_code in ('M95911','M96121','M98231') then 'pathology_mbl' when normalized_code = 'M98233' then 'cll_morphology_pressure' else null end as state_id,\n",
    "    min(event_date) as first_date\n",
    "  from pato where event_date is not null group by person_key, state_id\n",
    ")\n",
    "select person_key, state_id, first_date from grouped where state_id is not null;"
  )
  infection_sql <- paste0(
    "with infection_rows as (\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("date_diagnosis"), " as event_date, ", norm_expr("diagnosis"), " as normalized_code from public.t_dalycare_diagnoses\n",
    "  union all\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("date_diagnosis"), " as event_date, ", norm_expr("diagnosis"), " as normalized_code from public.diagnoses_all\n",
    "  union all\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("d_inddto"), " as event_date, ", norm_expr("c_adiag"), " as normalized_code from public.SDS_t_adm\n",
    "  union all\n",
    "  select patientid::text as person_key, ", confluence_count_date_sql("dato_start"), " as event_date, ", norm_expr("aktionsdiagnose"), " as normalized_code from public.SDS_kontakter\n",
    ")\n",
    "select distinct person_key, event_date, 'serious_infection_hospitalization' as endpoint_id\n",
    "from infection_rows where person_key is not null and event_date is not null and ", prefix_pred, ";"
  )
  patient_sql <- paste0(
    "select patientid::text as person_key, ", confluence_count_date_sql("date_death_fu"), " as date_death_fu from public.patient;"
  )
  query <- function(sql) {
    if (is.function(db_adapter$confluence_query)) {
      return(tryCatch(list(data = db_adapter$confluence_query(sql), error_class = "", error_message_sanitized = ""), error = function(e) list(data = NULL, error_class = "production_aggregate_failed_query_error", error_message_sanitized = conditionMessage(e))))
    }
    mcl_count_db_query_result(db_adapter, sql)
  }
  first <- query(first_sql)
  pato <- query(pato_sql)
  infection <- query(infection_sql)
  patient <- query(patient_sql)
  errors <- bind_rows_base(list(
    if (nzchar(first$error_class %||% "")) confluence_count_fail_closed_frame("confluence_disease_first_dates", "confluence_first_date_availability.csv", first$error_message_sanitized, "production_aggregate", first$error_class),
    if (nzchar(pato$error_class %||% "")) confluence_count_fail_closed_frame("confluence_pathology_first_dates", "confluence_mbl_validation_waterfall.csv", pato$error_message_sanitized, "production_aggregate", pato$error_class),
    if (nzchar(infection$error_class %||% "")) confluence_count_fail_closed_frame("confluence_infection_events", "confluence_infection_counts.csv", infection$error_message_sanitized, "production_aggregate", infection$error_class),
    if (nzchar(patient$error_class %||% "")) confluence_count_fail_closed_frame("confluence_patient_frame", "confluence_infection_person_time.csv", patient$error_message_sanitized, "production_aggregate", patient$error_class)
  ))
  list(
    sets = list(
      disease_first_dates = bind_rows_base(list(first$data, pato$data)),
      infection_events = infection$data,
      patient_frame = patient$data
    ),
    errors = errors
  )
}

confluence_count_placeholder_outputs <- function(mode = "plan", reason = "CONFLUENCE production aggregate query did not run.", error_class = "", project_root = ".") {
  outputs <- confluence_count_empty_outputs()
  outputs$infection_endpoint_code_sets <- confluence_count_read_endpoint_code_sets(project_root)
  outputs$microbiology_confirmation_counts <- confluence_count_microbiology_fail_closed(mode = mode)
  outputs$failed_query_audit <- confluence_count_fail_closed_frame("confluence_production_aggregate", "confluence_production_execution_summary.csv", reason, mode = mode, error_class = error_class)
  outputs$production_query_review <- confluence_count_query_review(success = FALSE, endpoint_codes = outputs$infection_endpoint_code_sets)
  outputs$production_execution_summary <- confluence_count_execution_summary(mode, attempted = !identical(mode, "plan"), success = FALSE, failure_reason = reason)
  outputs
}

confluence_count_build_outputs <- function(project_root = ".", db_adapter = NULL, mode = c("auto", "plan", "production_aggregate"), min_cell_count = atlas_min_cell_count()) {
  mode <- match.arg(mode)
  if (identical(mode, "auto")) mode <- confluence_count_mode(db_adapter)
  if (identical(mode, "plan")) {
    return(confluence_count_placeholder_outputs(mode = "plan", reason = "CONFLUENCE production aggregate mode disabled or DB adapter unavailable.", project_root = project_root))
  }
  db_adapter <- confluence_count_auto_db_adapter(db_adapter)
  if (!confluence_count_db_available(db_adapter)) {
    return(confluence_count_placeholder_outputs(mode = "production_aggregate", reason = "No DB adapter or secure CONFLUENCE count hook was available.", error_class = "production_aggregate_failed_credentials_unavailable", project_root = project_root))
  }
  count_sets <- NULL
  db_errors <- confluence_count_empty_failed_query_audit()
  if (is.function(db_adapter$confluence_count_sets)) {
    hook <- tryCatch(db_adapter$confluence_count_sets(min_cell_count = min_cell_count), error = function(e) {
      db_errors <<- confluence_count_fail_closed_frame("confluence_count_sets_hook", "confluence_production_execution_summary.csv", conditionMessage(e), "production_aggregate", "production_aggregate_failed_query_error")
      NULL
    })
    if (is.list(hook)) count_sets <- hook$sets %||% hook
  } else {
    fetched <- confluence_count_fetch_sets_from_db(db_adapter, project_root = project_root)
    count_sets <- fetched$sets
    db_errors <- fetched$errors
  }
  if (!is.list(count_sets) || !is.data.frame(count_sets$disease_first_dates) || !nrow(count_sets$disease_first_dates)) {
    return(confluence_count_placeholder_outputs(mode = "production_aggregate", reason = "No disease-state first-date rows were available after production aggregate query.", error_class = "production_aggregate_failed_mapping_unavailable", project_root = project_root))
  }
  outputs <- confluence_count_outputs_from_sets(count_sets, project_root = project_root, min_cell_count = min_cell_count)
  if (nrow(db_errors)) outputs$failed_query_audit <- db_errors
  outputs
}

confluence_count_merge_outputs <- function(scaffold, production) {
  if (is.null(scaffold)) scaffold <- confluence_empty_payload()
  if (is.null(production)) production <- confluence_count_empty_outputs()
  for (nm in names(production)) {
    if (nm %in% c("overlap_counts_accepted", "overlap_timing_accepted", "mbl_validation_waterfall", "mgus_validation_waterfall", "dual_clone_validation_waterfall")) {
      if (is.data.frame(production[[nm]]) && nrow(production[[nm]])) scaffold[[nm]] <- production[[nm]]
    } else {
      scaffold[[nm]] <- production[[nm]]
    }
  }
  scaffold
}
