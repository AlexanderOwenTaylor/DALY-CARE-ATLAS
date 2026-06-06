confluence_empty_summary <- function() {
  empty_df(
    metric = character(),
    label = character(),
    value = character(),
    status = character(),
    count_kind = character(),
    evidence_confidence = character(),
    notes = character()
  )
}

confluence_empty_disease_state_counts <- function() {
  empty_df(
    entity_id = character(),
    entity_label = character(),
    disease_family = character(),
    danish_sks_code = character(),
    icd10_code = character(),
    diagnosis_label = character(),
    count_display = character(),
    n_records = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    evidence_confidence = character(),
    source_table = character(),
    source_column = character(),
    evidence_source = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_overlap_counts <- function() {
  empty_df(
    overlap_id = character(),
    overlap_label = character(),
    left_state = character(),
    right_state = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    feasibility_status = character(),
    query_status = character(),
    notes = character()
  )
}

confluence_empty_overlap_timing <- function() {
  empty_df(
    timing_id = character(),
    timing_label = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    query_status = character(),
    notes = character()
  )
}

confluence_empty_infection_outcome_readiness <- function() {
  empty_df(
    outcome_id = character(),
    outcome_label = character(),
    source_layer = character(),
    source_signal = character(),
    readiness_status = character(),
    evidence_status = character(),
    count_kind = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_treatment_modifier_readiness <- function() {
  empty_df(
    modifier_id = character(),
    modifier_label = character(),
    source_layer = character(),
    source_signal = character(),
    readiness_status = character(),
    evidence_status = character(),
    count_kind = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_estimands <- function() {
  empty_df(
    estimand_id = character(),
    title = character(),
    population = character(),
    exposure_condition = character(),
    outcome_variable = character(),
    intercurrent_events = character(),
    summary_measure = character(),
    plain_language = character(),
    feasibility_status = character()
  )
}

confluence_empty_validation_checklist <- function() {
  empty_df(
    entity_id = character(),
    entity_label = character(),
    validation_step = character(),
    source_hint = character(),
    status = character(),
    notes = character()
  )
}

confluence_empty_bias_warnings <- function() {
  empty_df(
    bias_id = character(),
    bias_label = character(),
    why_it_matters = character(),
    mitigation = character(),
    severity = character()
  )
}

confluence_empty_recommended_next_actions <- function() {
  empty_df(
    action_id = character(),
    action_label = character(),
    owner_role = character(),
    priority = character(),
    status = character(),
    notes = character()
  )
}

confluence_empty_code_sets <- function() {
  empty_df(
    concept_id = character(),
    concept_label = character(),
    disease_family = character(),
    source_role = character(),
    code_system = character(),
    source_table_hint = character(),
    source_column_hint = character(),
    code = character(),
    normalized_code = character(),
    exact_match_required = logical(),
    include_or_exclude = character(),
    validation_role = character(),
    evidence_status = character(),
    acceptance_status = character(),
    notes = character()
  )
}

confluence_empty_source_counts <- function() {
  empty_df(
    source_tier_id = character(),
    source_tier_label = character(),
    disease_family = character(),
    code_system = character(),
    codes = character(),
    source_role = character(),
    count_display = character(),
    n_records = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    evidence_confidence = character(),
    source_table = character(),
    source_column = character(),
    suppression_status = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_candidate_first_date_summary <- function() {
  empty_df(
    state_id = character(),
    state_label = character(),
    source_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    first_date_logic = character(),
    notes = character()
  )
}

confluence_empty_overlap_counts_accepted <- function() {
  empty_df(
    overlap_id = character(),
    overlap_label = character(),
    mbl_tier = character(),
    pcd_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

confluence_empty_overlap_timing_accepted <- function() {
  empty_df(
    timing_id = character(),
    timing_label = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

confluence_empty_validation_waterfall <- function() {
  empty_df(
    waterfall_id = character(),
    entity_id = character(),
    step_order = integer(),
    step_label = character(),
    source_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

confluence_empty_small_cell_suppression_audit <- function() {
  empty_df(
    audit_id = character(),
    table_name = character(),
    row_id = character(),
    min_cell_count = integer(),
    raw_count_available = character(),
    count_display = character(),
    suppression_status = character(),
    public_safe = character(),
    notes = character()
  )
}

confluence_empty_utf8_quality_audit <- function() {
  empty_df(
    audit_id = character(),
    target = character(),
    pattern_code = character(),
    pattern_present = logical(),
    status = character(),
    notes = character()
  )
}

confluence_empty_infection_endpoint_definitions <- function() {
  empty_df(
    endpoint_id = character(),
    endpoint_label = character(),
    definition_status = character(),
    source_layer = character(),
    required_code_set_status = character(),
    readiness_status = character(),
    count_kind = character(),
    notes = character()
  )
}

confluence_empty_story_cards <- function() {
  empty_df(
    card_id = character(),
    sort_order = integer(),
    headline = character(),
    metric_display = character(),
    submetric_display = character(),
    interpretation = character(),
    evidence_table = character(),
    evidence_status = character(),
    caveat = character(),
    tone = character()
  )
}

confluence_empty_evidence_spine <- function() {
  empty_df(
    spine_id = character(),
    sort_order = integer(),
    study_component = character(),
    question_it_answers = character(),
    current_evidence = character(),
    source_tables_or_outputs = character(),
    status = character(),
    unresolved_edge = character(),
    tone = character()
  )
}

confluence_empty_overlap_signal_summary <- function() {
  empty_df(
    signal_id = character(),
    endpoint_family = character(),
    group_id = character(),
    group_label = character(),
    horizon_years = integer(),
    people_display = character(),
    event_count_display = character(),
    person_years_display = character(),
    rate_per_100_person_years = character(),
    descriptive_contrast_vs_cll_only = character(),
    descriptive_contrast_vs_pcd_only = character(),
    evidence_status = character(),
    caveat = character()
  )
}

confluence_empty_ingredient_map <- function() {
  empty_df(
    ingredient_id = character(),
    sort_order = integer(),
    ingredient = character(),
    what_it_contributes = character(),
    current_source = character(),
    accepted_or_provisional = character(),
    validation_needed = character(),
    why_it_matters = character(),
    tone = character()
  )
}

confluence_empty_protocol_runway <- function() {
  empty_df(
    runway_id = character(),
    sort_order = integer(),
    workstream = character(),
    already_available = character(),
    next_protocol_move = character(),
    blocker_type = character(),
    priority = character(),
    caveat = character()
  )
}

confluence_empty_payload <- function() {
  list(
    summary = confluence_empty_summary(),
    story_cards = confluence_empty_story_cards(),
    evidence_spine = confluence_empty_evidence_spine(),
    overlap_signal_summary = confluence_empty_overlap_signal_summary(),
    ingredient_map = confluence_empty_ingredient_map(),
    protocol_runway = confluence_empty_protocol_runway(),
    clone_route_manifest = confluence_clone_empty_route_manifest(),
    clone_source_resolution = confluence_clone_empty_source_resolution(),
    bcell_clone_evidence_counts = confluence_clone_empty_evidence_counts(),
    pcd_clone_evidence_counts = confluence_clone_empty_evidence_counts(),
    paraprotein_ambiguity_counts = confluence_clone_empty_ambiguity_counts(),
    mgus_reclassification_waterfall = confluence_clone_empty_mgus_waterfall(),
    dual_clone_overlap_counts = confluence_clone_empty_overlap_counts(),
    dual_clone_overlap_timing = confluence_clone_empty_overlap_timing(),
    primary_overlap_exclusion_reasons = confluence_clone_empty_exclusion_reasons(),
    clone_availability_protocol_runway = confluence_clone_empty_protocol_runway(),
    disease_state_counts = confluence_empty_disease_state_counts(),
    overlap_counts = confluence_empty_overlap_counts(),
    overlap_timing = confluence_empty_overlap_timing(),
    infection_outcome_readiness = confluence_empty_infection_outcome_readiness(),
    treatment_modifier_readiness = confluence_empty_treatment_modifier_readiness(),
    estimands = confluence_empty_estimands(),
    validation_checklist = confluence_empty_validation_checklist(),
    bias_warnings = confluence_empty_bias_warnings(),
    recommended_next_actions = confluence_empty_recommended_next_actions(),
    code_sets = confluence_empty_code_sets(),
    mbl_source_counts = confluence_empty_source_counts(),
    mgus_source_counts = confluence_empty_source_counts(),
    candidate_first_date_summary = confluence_empty_candidate_first_date_summary(),
    overlap_counts_accepted = confluence_empty_overlap_counts_accepted(),
    overlap_timing_accepted = confluence_empty_overlap_timing_accepted(),
    mbl_validation_waterfall = confluence_empty_validation_waterfall(),
    mgus_validation_waterfall = confluence_empty_validation_waterfall(),
    dual_clone_validation_waterfall = confluence_empty_validation_waterfall(),
    small_cell_suppression_audit = confluence_empty_small_cell_suppression_audit(),
    utf8_quality_audit = confluence_empty_utf8_quality_audit(),
    infection_endpoint_definitions = confluence_empty_infection_endpoint_definitions(),
    disease_state_person_counts = confluence_empty_candidate_first_date_summary(),
    first_date_availability = confluence_empty_candidate_first_date_summary(),
    infection_endpoint_code_sets = confluence_empty_infection_endpoint_definitions(),
    infection_counts = confluence_empty_overlap_counts_accepted(),
    recurrent_infection_counts = confluence_empty_overlap_counts_accepted(),
    infection_person_time = confluence_empty_overlap_counts_accepted(),
    infection_rates = confluence_empty_overlap_counts_accepted(),
    microbiology_confirmation_counts = confluence_empty_infection_endpoint_definitions(),
    microbiology_confirmation_source_audit = empty_df(
      source_id = character(),
      source_role = character(),
      configured_db_name = character(),
      configured_schema = character(),
      configured_table = character(),
      resolved_db_name = character(),
      resolved_schema = character(),
      resolved_table = character(),
      person_key_column = character(),
      date_columns = character(),
      result_columns = character(),
      organism_columns = character(),
      sample_material_columns = character(),
      include_in_confirmed_union = logical(),
      endpoint_definition_status = character(),
      resolution_status = character(),
      query_executable = logical(),
      query_attempted = logical(),
      query_success = logical(),
      error_message_sanitized = character(),
      notes = character()
    ),
    production_query_review = empty_df(
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
    ),
    failed_query_audit = empty_df(
      component = character(),
      output_file = character(),
      query_id = character(),
      count_status = character(),
      query_attempted = logical(),
      query_success = logical(),
      error_class = character(),
      error_message_sanitized = character(),
      notes = character()
    ),
    source_resolution_audit = empty_df(
      source_id = character(),
      source_role = character(),
      route_id = character(),
      configured_db_name = character(),
      configured_schema = character(),
      configured_table = character(),
      resolved_db_name = character(),
      resolved_schema = character(),
      resolved_table = character(),
      person_key_column = character(),
      date_columns = character(),
      code_column = character(),
      usable_for_counts = logical(),
      resolution_status = character(),
      query_executable = logical(),
      notes = character()
    ),
    production_execution_summary = empty_df(
      metric = character(),
      label = character(),
      value = character(),
      status = character(),
      notes = character()
    )
  )
}

confluence_story_conform <- function(df, empty) {
  if (!is.data.frame(df)) return(empty)
  for (nm in names(empty)) {
    if (!nm %in% names(df)) {
      template <- empty[[nm]]
      if (is.integer(template)) {
        df[[nm]] <- rep(NA_integer_, nrow(df))
      } else if (is.numeric(template)) {
        df[[nm]] <- rep(NA_real_, nrow(df))
      } else if (is.logical(template)) {
        df[[nm]] <- rep(NA, nrow(df))
      } else {
        df[[nm]] <- rep("", nrow(df))
      }
    }
  }
  df <- df[, names(empty), drop = FALSE]
  if (!nrow(df)) return(empty)
  df
}

confluence_story_table <- function(outputs, name, empty = data.frame(stringsAsFactors = FALSE)) {
  if (!is.list(outputs) || !is.data.frame(outputs[[name]])) return(empty)
  outputs[[name]]
}

confluence_story_has_accepted <- function(df) {
  is.data.frame(df) && nrow(df) && "acceptance_status" %in% names(df) &&
    any(tolower(as.character(df$acceptance_status)) == "accepted", na.rm = TRUE)
}

confluence_story_usable_rows <- function(df) {
  if (!is.data.frame(df) || !nrow(df)) return(df)
  out <- df
  if ("acceptance_status" %in% names(out)) {
    out <- out[tolower(as.character(out$acceptance_status)) == "accepted", , drop = FALSE]
  }
  if ("suppression_status" %in% names(out)) {
    suppression <- as.character(out$suppression_status)
    suppressed <- grepl("suppressed", suppression, ignore.case = TRUE) &
      !grepl("not suppressed", suppression, ignore.case = TRUE)
    out <- out[!suppressed, , drop = FALSE]
  }
  out
}

confluence_story_row <- function(df, key, value) {
  if (!is.data.frame(df) || !nrow(df) || !key %in% names(df)) return(data.frame(stringsAsFactors = FALSE))
  rows <- confluence_story_usable_rows(df)
  rows <- rows[as.character(rows[[key]]) == as.character(value), , drop = FALSE]
  if (!nrow(rows)) return(data.frame(stringsAsFactors = FALSE))
  rows[1, , drop = FALSE]
}

confluence_story_value <- function(row, key, default = "not available") {
  if (!is.data.frame(row) || !nrow(row) || !key %in% names(row)) return(default)
  value <- row[[key]][[1]]
  if (is.null(value) || length(value) == 0L || is.na(value) || !nzchar(trimws(as.character(value)))) return(default)
  as.character(value)
}

confluence_story_count <- function(df, key, value, default = "not available") {
  confluence_story_value(confluence_story_row(df, key, value), "count_display", default)
}

confluence_story_line <- function(label, value) {
  value <- as.character(value %||% "")
  if (!length(value) || is.na(value[[1]]) || !nzchar(value[[1]]) || identical(value[[1]], "not available")) return(character())
  value <- value[[1]]
  paste0(label, ": ", value)
}

confluence_story_collapse <- function(x, default = "not available") {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) return(default)
  paste(x, collapse = "; ")
}

confluence_story_numeric <- function(x) {
  x <- as.character(x %||% "")
  if (length(x) == 0L || is.na(x[[1]]) || !nzchar(x[[1]]) || grepl("<|suppressed|not available|not accepted", x[[1]], ignore.case = TRUE)) return(NA_real_)
  x <- x[[1]]
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

confluence_story_rate_for <- function(rates, group_id, horizon_years) {
  if (!is.data.frame(rates) || !nrow(rates)) return(NA_real_)
  required <- c("group_id", "horizon_years", "rate_per_100_person_years")
  if (!all(required %in% names(rates))) return(NA_real_)
  rows <- confluence_story_usable_rows(rates)
  rows <- rows[as.character(rows$group_id) == as.character(group_id) &
                 as.character(rows$horizon_years) == as.character(horizon_years), , drop = FALSE]
  if (!nrow(rows)) return(NA_real_)
  confluence_story_numeric(rows$rate_per_100_person_years[[1]])
}

confluence_safe_rate_contrast <- function(rate_a, rate_b) {
  if (is.na(rate_a) || is.na(rate_b) || !is.finite(rate_a) || !is.finite(rate_b) || rate_b <= 0) {
    return("not available")
  }
  paste0(
    format(round(rate_a / rate_b, 2), nsmall = 2, trim = TRUE),
    "x (display-only aggregate rate contrast; not adjusted; not causal)"
  )
}

confluence_story_endpoint_line <- function(counts, group_id, horizon_years) {
  if (!is.data.frame(counts) || !nrow(counts) || !all(c("group_id", "horizon_years") %in% names(counts))) {
    return(paste0(horizon_years, "y: not available"))
  }
  row <- confluence_story_row(
    counts[counts$group_id == group_id & as.character(counts$horizon_years) == as.character(horizon_years), , drop = FALSE],
    "group_id",
    group_id
  )
  if (!nrow(row)) return(paste0(horizon_years, "y: not available"))
  paste0(
    horizon_years, "y: ",
    confluence_story_value(row, "count_display"), " people / ",
    confluence_story_value(row, "event_count_display"), " events"
  )
}

confluence_story_person_time_line <- function(person_time, group_id, horizon_years) {
  if (!is.data.frame(person_time) || !nrow(person_time) || !"group_id" %in% names(person_time)) {
    return(paste0(horizon_years, "y: not available"))
  }
  rows <- confluence_story_usable_rows(person_time)
  rows <- rows[as.character(rows$group_id) == as.character(group_id) &
                 as.character(rows$horizon_years) == as.character(horizon_years), , drop = FALSE]
  if (!nrow(rows)) return(paste0(horizon_years, "y: not available"))
  paste0(
    horizon_years, "y: ",
    confluence_story_value(rows[1, , drop = FALSE], "person_years_display"),
    " PY"
  )
}

confluence_story_cards <- function(outputs) {
  disease <- confluence_story_table(outputs, "disease_state_person_counts")
  first_dates <- confluence_story_table(outputs, "first_date_availability")
  overlap <- confluence_story_table(outputs, "overlap_counts_accepted")
  timing <- confluence_story_table(outputs, "overlap_timing_accepted")
  bcell_clone <- confluence_story_table(outputs, "bcell_clone_evidence_counts")
  pcd_clone <- confluence_story_table(outputs, "pcd_clone_evidence_counts")
  ambiguity <- confluence_story_table(outputs, "paraprotein_ambiguity_counts")
  exclusions <- confluence_story_table(outputs, "primary_overlap_exclusion_reasons")
  infection <- confluence_story_table(outputs, "infection_counts")
  microbiology <- confluence_story_table(outputs, "microbiology_confirmation_counts")
  person_time <- confluence_story_table(outputs, "infection_person_time")
  bias <- confluence_story_table(outputs, "bias_warnings")
  actions <- confluence_story_table(outputs, "recommended_next_actions")

  state_count <- function(id) confluence_story_count(disease, "state_id", id)
  overlap_count <- function(id) confluence_story_count(overlap, "overlap_id", id)
  timing_count <- function(id) confluence_story_count(timing, "timing_id", id)
  clone_state_count <- function(df, id) confluence_story_count(df, "state_id", id)
  exclusion_count <- function(id) confluence_story_count(exclusions, "exclusion_reason", id)

  denominator_lines <- c(
    confluence_story_line("accepted B-cell clone", clone_state_count(bcell_clone, "bcell_cll_diagnosis_accepted")),
    confluence_story_line("B-cell registry support", clone_state_count(bcell_clone, "bcell_cll_registry_accepted")),
    confluence_story_line("direct PCD support", clone_state_count(pcd_clone, "pcd_direct_clone_supported")),
    confluence_story_line("registry-supported PCD", clone_state_count(pcd_clone, "pcd_registry_supported")),
    confluence_story_line("MGUS code candidates", exclusion_count("mgus_code_only")),
    confluence_story_line("IgM ambiguity", confluence_story_count(ambiguity, "ambiguity_id", "ambiguous_bcell_paraprotein_classified"))
  )
  first_date_status <- if (confluence_story_has_accepted(first_dates)) {
    "first-date availability accepted"
  } else {
    "first-date availability not yet accepted"
  }
  bias_terms <- if (is.data.frame(bias) && nrow(bias) && "bias_label" %in% names(bias)) {
    paste(unique(as.character(bias$bias_label)), collapse = "; ")
  } else {
    "immortal time; testing intensity; treatment timing; progression; competing mortality; small-cell protection"
  }
  completed_actions <- if (is.data.frame(actions) && nrow(actions) && all(c("status", "action_label") %in% names(actions))) {
    action_status <- tolower(paste(actions$status, actions$priority))
    actions$action_label[grepl("complete|accepted provisional aggregate", action_status)]
  } else {
    character()
  }
  next_actions <- if (is.data.frame(actions) && nrow(actions) && all(c("status", "action_label") %in% names(actions))) {
    action_status <- tolower(paste(actions$status, actions$priority))
    actions$action_label[!grepl("complete|accepted provisional aggregate", action_status)]
  } else {
    character()
  }

  rows <- data.frame(
    card_id = c(
      "overlap_identifiable",
      "denominator_separated",
      "mgus_candidate_gate",
      "ambiguity_hierarchy",
      "overlap_clock_defined",
      "infection_two_routes",
      "person_time_under_signal",
      "bias_controls_named",
      "completed_aggregate_checks",
      "next_protocol_moves"
    ),
    sort_order = seq_len(10L),
    headline = c(
      "Accepted dual-clone cohort is identifiable",
      "Clone-evidence denominators are separated from diagnosis anchors",
      "MGUS code overlap is candidate only",
      "IgM paraprotein ambiguity is isolated",
      "The overlap clock is defined",
      "Infection can be measured two ways",
      "There is person-time underneath the signal",
      "The difficult biases are already on the page",
      "Completed aggregate checks",
      "Next protocol moves"
    ),
    metric_display = c(
      overlap_count("accepted_dual_clone_overlap"),
      confluence_story_collapse(denominator_lines),
      exclusion_count("mgus_code_only"),
      confluence_story_count(ambiguity, "ambiguity_id", "ambiguous_bcell_paraprotein_classified"),
      "later disease-state entry",
      "hospital-coded plus microbiology",
      confluence_story_collapse(vapply(c(1L, 2L, 5L), function(h) confluence_story_person_time_line(person_time, "accepted_dual_clone_overlap", h), character(1)), "person-time not available"),
      "bias controls named",
      if (length(completed_actions)) "production aggregate checks completed" else "no completed aggregate checks yet",
      "protocol hardening path"
    ),
    submetric_display = c(
      confluence_story_collapse(c(
        confluence_story_line("probable sensitivity", overlap_count("probable_dual_clone_sensitivity")),
        confluence_story_line("candidate diagnosis overlap", overlap_count("candidate_diagnosis_overlap")),
        confluence_story_line("ambiguous B-cell paraprotein", overlap_count("ambiguous_bcell_paraprotein"))
      )),
      paste(c(confluence_story_collapse(denominator_lines), first_date_status), collapse = "; "),
      "MGUS diagnosis-code overlap is a candidate signal, not accepted evidence of an independent plasma-cell clone.",
      "CLL/MBL plus IgM-only paraprotein remains ambiguous unless independent PCD evidence is present.",
      confluence_story_collapse(c(
        confluence_story_line("same 90-day window", timing_count("same_90_day_window")),
        confluence_story_line("B-cell first", timing_count("bcell_first")),
        confluence_story_line("PCD first", timing_count("pcd_first"))
      )),
      paste(
        confluence_story_collapse(vapply(c(1L, 2L, 5L), function(h) confluence_story_endpoint_line(infection, "accepted_dual_clone_overlap", h), character(1))),
        confluence_story_collapse(vapply(c(1L, 2L, 5L), function(h) confluence_story_endpoint_line(microbiology, "accepted_dual_clone_overlap", h), character(1))),
        sep = "; microbiology: "
      ),
      "explicit denominator time by 1, 2, and 5 year horizon",
      bias_terms,
      if (length(completed_actions)) confluence_story_collapse(completed_actions) else "accepted production checks are not available in this run",
      if (length(next_actions)) confluence_story_collapse(next_actions) else "source validation, endpoint ownership, microbiology roles, treatment timing"
    ),
    interpretation = c(
      "Primary CONFLUENCE is accepted B-cell clone plus accepted plasma-cell clone, with weak routes blocked from the headline cohort.",
      "Route-level evidence counts and first-date availability are separated from scaffold/reference diagnosis anchors.",
      "MGUS diagnosis-code overlap is a candidate signal, not accepted evidence of an independent plasma-cell clone.",
      "IgM paraprotein can be a B-cell clone signal in CLL/MBL; the hierarchy prevents that from masquerading as independent PCD.",
      "Follow-up begins at the second qualifying state, so ever-overlap does not create immortal-time exposure.",
      "Hospital-coded and microbiology-confirmed routes both produce aggregate outcome strata.",
      "The infection signal is backed by explicit denominator time, not only event counts.",
      "Immortal time, testing intensity, treatment, progression, competing mortality, MBL undercoding, MGUS ascertainment, and small-cell protection are explicit design objects.",
      "Accepted rows show that core aggregate checks have executed; they remain feasibility checks rather than final analysis.",
      "Next work is source validation, endpoint ownership, microbiology role classification, and treatment timing - not discovery of whether a cohort exists."
    ),
    evidence_table = c(
      "confluence_dual_clone_overlap_counts.csv; confluence_overlap_counts_accepted.csv",
      "confluence_bcell_clone_evidence_counts.csv; confluence_pcd_clone_evidence_counts.csv; confluence_clone_route_manifest.csv",
      "confluence_mgus_reclassification_waterfall.csv; confluence_primary_overlap_exclusion_reasons.csv",
      "confluence_paraprotein_ambiguity_counts.csv",
      "confluence_overlap_timing_accepted.csv",
      "confluence_infection_counts.csv; confluence_microbiology_confirmation_counts.csv",
      "confluence_infection_person_time.csv",
      "confluence_bias_warnings.csv",
      "confluence_recommended_next_actions.csv; confluence_production_execution_summary.csv",
      "confluence_recommended_next_actions.csv"
    ),
    evidence_status = c(
      if (confluence_story_has_accepted(overlap)) "accepted aggregate row" else "not accepted aggregate",
      if (nrow(bcell_clone) || nrow(pcd_clone)) "route-level aggregate evidence" else "source validation required",
      "candidate-only gate",
      "ambiguity gate",
      if (confluence_story_has_accepted(timing)) "accepted aggregate row" else "not accepted aggregate",
      if (confluence_story_has_accepted(infection) || confluence_story_has_accepted(microbiology)) "accepted provisional endpoint aggregate" else "source validation required",
      if (confluence_story_has_accepted(person_time)) "accepted aggregate row" else "not accepted aggregate",
      "protocol hardening",
      if (length(completed_actions)) "completed aggregate checks" else "protocol hardening",
      "protocol hardening"
    ),
    caveat = c(
      "Aggregate feasibility only; not causal.",
      "Configured routes must be usable in the route manifest before contributing.",
      "A person cannot enter accepted_dual_clone_overlap through MGUS-code-only evidence.",
      "Ambiguous IgM-only rows are not primary PCD evidence.",
      "Protocol-level state-transition rules are still required.",
      "Endpoint definitions remain provisional and require clinical ownership.",
      "Do not interpret descriptive rates as modelled risks.",
      "Bias handling still needs final protocol implementation.",
      "Completed checks remain aggregate feasibility outputs; not causal.",
      "Do not call anything final until validation passes."
    ),
    tone = c("green", "green", "amber", "amber", "blue", "blue", "cyan", "amber", "green", "amber"),
    stringsAsFactors = FALSE
  )
  confluence_story_conform(rows, confluence_empty_story_cards())
}

confluence_evidence_spine <- function(outputs) {
  accepted_status <- function(name) {
    if (confluence_story_has_accepted(confluence_story_table(outputs, name))) "accepted aggregate row" else "source validation required"
  }
  endpoint_status <- function(name) {
    if (confluence_story_has_accepted(confluence_story_table(outputs, name))) "accepted provisional endpoint aggregate" else "source validation required"
  }
  rows <- data.frame(
    spine_id = c(
      "disease_state_anchors",
      "first_qualifying_dates",
      "overlap_entry_date",
      "comparator_groups",
      "serious_infection_endpoint",
      "recurrent_infection_endpoint",
      "microbiology_confirmed_endpoint",
      "person_time_denominator",
      "source_resolution_audit",
      "small_cell_privacy_guard",
      "treatment_modifier_readiness",
      "competing_risk_progression_warning"
    ),
    sort_order = seq_len(12L),
    study_component = c(
      "Clone-evidence route manifest",
      "First qualifying clone dates",
      "Accepted dual-clone entry date",
      "Comparator groups",
      "Serious infection endpoint",
      "Recurrent infection endpoint",
      "Microbiology-confirmed endpoint",
      "Person-time denominator",
      "Source-resolution audit",
      "Small-cell/privacy guard",
      "Treatment modifier readiness",
      "Competing-risk/progression design warning"
    ),
    question_it_answers = c(
      "Can B-cell and plasma-cell clone evidence routes be resolved or failed closed?",
      "Can clone-state time begin at a qualifying aggregate date?",
      "Can dual-clone follow-up begin at the later accepted clone date?",
      "Can accepted dual clone be compared with single-axis and candidate/ambiguous strata?",
      "Can hospital-coded serious infection be counted by group and horizon?",
      "Can repeated serious infection episodes be counted separately?",
      "Can microbiology-confirmed infection be measured as a second route?",
      "Is denominator time available under the event counts?",
      "Are source routes resolved or failed closed visibly?",
      "Are public counts protected before display?",
      "Are infection-modifying therapies visible as design variables?",
      "Are death and progression named before modelling?"
    ),
    current_evidence = c(
      "Every configured clone route is usable or explicitly failed closed in confluence_clone_route_manifest.csv.",
      "Accepted B-cell and plasma-cell clone dates are separated from candidate diagnosis dates.",
      "Accepted dual-clone entry is anchored at the later accepted clone date; MGUS code date is candidate only.",
      "Accepted dual clone, probable sensitivity, ambiguous paraprotein, candidate overlap, B-cell only, and PCD only strata.",
      "Repo-derived provisional serious infection hospitalization rows.",
      "Repo-derived provisional 14-day same-endpoint recurrent episode rows.",
      "Mapped SP blood-culture and PERSIMUNE culture/microscopy confirmation rows when available.",
      "Person-years at 1, 2, and 5 years by group.",
      "Catalog/source-map resolution audit with fail-closed status.",
      "Minimum-cell suppression and aggregate-only output checks.",
      "Treatment layers are named for protocol timing, not interpreted as effects.",
      "Bias warnings name competing death, progression, and immortal-time handling."
    ),
    source_tables_or_outputs = c(
      "confluence_clone_route_manifest.csv; confluence_clone_source_resolution.csv",
      "confluence_bcell_clone_evidence_counts.csv; confluence_pcd_clone_evidence_counts.csv",
      "confluence_dual_clone_overlap_counts.csv; confluence_dual_clone_overlap_timing.csv",
      "confluence_infection_person_time.csv; confluence_infection_counts.csv",
      "confluence_infection_counts.csv",
      "confluence_recurrent_infection_counts.csv",
      "confluence_microbiology_confirmation_counts.csv",
      "confluence_infection_person_time.csv; confluence_infection_rates.csv",
      "confluence_source_resolution_audit.csv; confluence_failed_query_audit.csv",
      "confluence_small_cell_suppression_audit.csv",
      "confluence_treatment_modifier_readiness.csv",
      "confluence_bias_warnings.csv"
    ),
    status = c(
      if (is.data.frame(confluence_story_table(outputs, "clone_route_manifest")) && nrow(confluence_story_table(outputs, "clone_route_manifest"))) "route manifest available" else "source validation required",
      if (is.data.frame(confluence_story_table(outputs, "bcell_clone_evidence_counts")) || is.data.frame(confluence_story_table(outputs, "pcd_clone_evidence_counts"))) "route-level aggregate evidence" else "source validation required",
      accepted_status("overlap_counts_accepted"),
      accepted_status("infection_person_time"),
      endpoint_status("infection_counts"),
      endpoint_status("recurrent_infection_counts"),
      endpoint_status("microbiology_confirmation_counts"),
      accepted_status("infection_person_time"),
      if (is.data.frame(confluence_story_table(outputs, "source_resolution_audit")) && nrow(confluence_story_table(outputs, "source_resolution_audit"))) "audit available" else "source validation required",
      "privacy-safe aggregate only",
      "source validation required",
      "protocol hardening"
    ),
    unresolved_edge = c(
      "No route contributes unless route_status is usable.",
      "Protocol rules must define how state transitions are used.",
      "No raw dates are emitted; analysis rules remain protocol-level.",
      "Comparator use is descriptive until modelling is specified.",
      "Endpoint ownership and code-set review remain required.",
      "Episode-gap rules remain provisional.",
      "Organism/result roles need final clinical ownership.",
      "Rates remain descriptive aggregate displays.",
      "Unavailable routes must stay fail-closed.",
      "Small overlap strata may remain grouped or suppressed.",
      "Treatment timing needs source-specific rules.",
      "Final analysis must handle death/progression explicitly."
    ),
    tone = c("green", "green", "blue", "cyan", "blue", "blue", "blue", "green", "cyan", "green", "amber", "amber"),
    stringsAsFactors = FALSE
  )
  confluence_story_conform(rows, confluence_empty_evidence_spine())
}

confluence_overlap_signal_summary <- function(outputs) {
  person_time <- confluence_story_table(outputs, "infection_person_time")
  rates <- confluence_story_table(outputs, "infection_rates")
  families <- list(
    serious_infection = confluence_story_table(outputs, "infection_counts"),
    recurrent_serious_infection = confluence_story_table(outputs, "recurrent_infection_counts"),
    microbiology_confirmed_infection = confluence_story_table(outputs, "microbiology_confirmation_counts")
  )
  rows <- list()
  for (family in names(families)) {
    counts <- families[[family]]
    if (!is.data.frame(counts) || !nrow(counts) || !all(c("group_id", "horizon_years") %in% names(counts))) next
    counts <- confluence_story_usable_rows(counts)
    if (!nrow(counts)) next
    for (i in seq_len(nrow(counts))) {
      row <- counts[i, , drop = FALSE]
      group_id <- as.character(row$group_id[[1]] %||% "")
      horizon <- suppressWarnings(as.integer(row$horizon_years[[1]] %||% NA_integer_))
      pt <- if (is.data.frame(person_time) && nrow(person_time) && all(c("group_id", "horizon_years") %in% names(person_time))) {
        p <- confluence_story_usable_rows(person_time)
        p[p$group_id == group_id & as.character(p$horizon_years) == as.character(horizon), , drop = FALSE]
      } else {
        data.frame(stringsAsFactors = FALSE)
      }
      rate <- if (identical(family, "serious_infection")) confluence_story_rate_for(rates, group_id, horizon) else NA_real_
      rate_display <- if (is.na(rate)) {
        if (identical(family, "serious_infection")) "not available" else "rate row not emitted for this endpoint family"
      } else {
        as.character(rate)
      }
      acceptance_status <- confluence_story_value(row, "acceptance_status", "")
      endpoint_definition_status <- confluence_story_value(row, "endpoint_definition_status", "")
      evidence_status <- if (grepl("^accepted$", acceptance_status, ignore.case = TRUE)) {
        "accepted provisional endpoint aggregate"
      } else if (nzchar(endpoint_definition_status) && !identical(endpoint_definition_status, "not available")) {
        endpoint_definition_status
      } else {
        confluence_story_value(row, "acceptance_status", "source validation required")
      }
      rows[[length(rows) + 1L]] <- data.frame(
        signal_id = paste(family, group_id, horizon, sep = "_"),
        endpoint_family = switch(
          family,
          serious_infection = "Serious infection hospitalization",
          recurrent_serious_infection = "Recurrent serious infection episodes",
          microbiology_confirmed_infection = "Microbiology-confirmed infection",
          family
        ),
        group_id = group_id,
        group_label = confluence_story_value(row, "group_label"),
        horizon_years = horizon,
        people_display = confluence_story_value(row, "count_display"),
        event_count_display = confluence_story_value(row, "event_count_display"),
        person_years_display = if (nrow(pt)) confluence_story_value(pt[1, , drop = FALSE], "person_years_display") else "not available",
        rate_per_100_person_years = rate_display,
        descriptive_contrast_vs_cll_only = confluence_safe_rate_contrast(rate, confluence_story_rate_for(rates, "cll_only", horizon)),
        descriptive_contrast_vs_pcd_only = confluence_safe_rate_contrast(rate, confluence_story_rate_for(rates, "pcd_only", horizon)),
        evidence_status = evidence_status,
        caveat = if (identical(family, "serious_infection")) {
          "Display-only aggregate signal; provisional endpoint; not adjusted; not causal."
        } else {
          "Display-only aggregate signal; provisional endpoint; rate row not emitted for this endpoint family; not adjusted; not causal."
        },
        stringsAsFactors = FALSE
      )
    }
  }
  confluence_story_conform(bind_rows_base(rows), confluence_empty_overlap_signal_summary())
}

confluence_ingredient_map <- function(outputs) {
  status <- function(name, accepted = "accepted aggregate row", fallback = "source validation required") {
    if (confluence_story_has_accepted(confluence_story_table(outputs, name))) accepted else fallback
  }
  rows <- data.frame(
    ingredient_id = c(
      "cll_mbl_axis",
      "pcd_axis",
      "route_manifest_gate",
      "ambiguity_hierarchy",
      "overlap_timing",
      "hospital_serious_infection",
      "recurrent_episode_logic",
      "microbiology_confirmation",
      "blood_culture_route",
      "treatment_modifiers",
      "death_followup_censoring",
      "small_cell_suppression",
      "source_resolution_fail_closed"
    ),
    sort_order = seq_len(13L),
    ingredient = c(
      "Accepted B-cell clone axis",
      "Accepted plasma-cell clone axis",
      "Route manifest gate",
      "Paraprotein ambiguity hierarchy",
      "Overlap timing",
      "Hospital-coded serious infection",
      "Recurrent infection episode logic",
      "Microbiology confirmation",
      "Blood-culture route",
      "Treatment modifiers",
      "Death/follow-up/censoring",
      "Small-cell suppression",
      "Source-resolution/fail-closed audit"
    ),
    what_it_contributes = c(
      "Defines the B-cell clone side of the study frame.",
      "Defines the plasma-cell clone side without promoting MGUS code-only evidence.",
      "Prevents configured routes from silently contributing when tables or columns are missing.",
      "Separates CLL/MBL plus IgM paraprotein from independent plasma-cell clone evidence.",
      "Protects follow-up from ever-overlap immortal-time exposure.",
      "Provides a broad serious infection ascertainment route.",
      "Separates repeated episodes from first-event feasibility.",
      "Adds a laboratory-confirmed infection route alongside hospital coding.",
      "Supports bloodstream/culture confirmation readiness.",
      "Names BTKi, venetoclax, anti-CD20, steroids, MM therapy, and ASCT/HDT as modifiers to time.",
      "Provides denominator time and censoring ingredients for later protocol analysis.",
      "Prevents unsafe public display of small cells.",
      "Shows which routes resolved, executed, or failed closed."
    ),
    current_source = c(
      "RKKP_CLL, exact CLL diagnosis routes, and validated/supporting B-cell clone routes.",
      "DaMyDa direct/support fields, validated pathology/flow routes, and lab support tiers.",
      "confluence_clone_route_manifest.csv.",
      "confluence_paraprotein_ambiguity_counts.csv.",
      "Accepted dual-clone overlap counts/timing and first-date availability.",
      "SDS/LPR diagnosis/contact routes using repo-derived provisional code families.",
      "Provisional 14-day same-endpoint episode gap.",
      "SP blood-culture and PERSIMUNE culture/microscopy mappings where executable.",
      "SP blood-culture Del1-3 route where deterministic.",
      "Readiness layer only; no treatment-effect claim.",
      "Patient-frame/person-time aggregate outputs.",
      "Minimum-cell audit and public display labels.",
      "Source-resolution audit and failed-query audit."
    ),
    accepted_or_provisional = c(
      if (is.data.frame(confluence_story_table(outputs, "bcell_clone_evidence_counts")) && nrow(confluence_story_table(outputs, "bcell_clone_evidence_counts"))) "route-level aggregate evidence" else "source validation required",
      if (is.data.frame(confluence_story_table(outputs, "pcd_clone_evidence_counts")) && nrow(confluence_story_table(outputs, "pcd_clone_evidence_counts"))) "route-level aggregate evidence" else "source validation required",
      if (is.data.frame(confluence_story_table(outputs, "clone_route_manifest")) && nrow(confluence_story_table(outputs, "clone_route_manifest"))) "route manifest available" else "source validation required",
      "ambiguity gate",
      status("overlap_timing_accepted"),
      status("infection_counts", accepted = "accepted provisional endpoint aggregate"),
      status("recurrent_infection_counts", accepted = "accepted provisional endpoint aggregate"),
      status("microbiology_confirmation_counts", accepted = "accepted provisional endpoint aggregate"),
      status("microbiology_confirmation_counts", accepted = "accepted provisional endpoint aggregate"),
      "source validation required",
      status("infection_person_time"),
      "privacy-safe aggregate only",
      if (is.data.frame(confluence_story_table(outputs, "source_resolution_audit")) && nrow(confluence_story_table(outputs, "source_resolution_audit"))) "audit available" else "source validation required"
    ),
    validation_needed = c(
      "Coded MBL needs biologic/source validation.",
      "MGUS diagnosis-code overlap stays candidate unless direct/registry-supported evidence exists.",
      "Every route with missing columns must remain failed closed.",
      "Confirm whether ambiguous IgM paraprotein can be resolved by independent PCD evidence.",
      "State-transition rules need protocol ownership.",
      "Endpoint definition and code-set ownership.",
      "Episode gap and recurrence definition ownership.",
      "Organism/result role classification.",
      "Testing opportunity and source-role validation.",
      "Time-updated modifier mapping.",
      "Final censoring and competing-risk rules.",
      "Precheck small overlap strata.",
      "Keep unresolved routes fail-closed."
    ),
    why_it_matters = c(
      "The study needs a separable B-cell clone axis.",
      "The study needs a separable plasma-cell clone axis.",
      "Trust depends on visible source resolution and honest failure.",
      "It prevents B-cell paraprotein biology from being mislabelled as dual clone.",
      "Overlap risk time should start at the second disease-state entry.",
      "Hospital-coded infection captures serious clinical events.",
      "Recurrent burden asks a different feasibility question from first infection.",
      "Microbiology confirmation tests whether phenotype detail is measurable.",
      "Blood culture supports bloodstream-infection feasibility.",
      "Treatment can confound or modify infection risk.",
      "Events need denominator time and censoring context.",
      "Public outputs must remain aggregate-only.",
      "Trust depends on visible source resolution and honest failure."
    ),
    tone = c("green", "green", "cyan", "amber", "blue", "blue", "blue", "cyan", "cyan", "amber", "green", "green", "cyan"),
    stringsAsFactors = FALSE
  )
  confluence_story_conform(rows, confluence_empty_ingredient_map())
}

confluence_protocol_runway <- function(outputs) {
  rows <- data.frame(
    runway_id = c(
      "mbl_validation",
      "mgus_validation",
      "smm_definition",
      "infection_endpoint_ownership",
      "microbiology_roles",
      "treatment_timing",
      "testing_intensity",
      "death_progression",
      "small_cell_precheck"
    ),
    sort_order = seq_len(9L),
    workstream = c(
      "MBL validation",
      "MGUS validation",
      "SMM definition",
      "Serious/recurrent infection endpoint ownership",
      "Microbiology organism/result role classification",
      "Treatment timing/modifier mapping",
      "Testing/admission intensity handling",
      "Competing death/progression handling",
      "Small-cell suppression precheck"
    ),
    already_available = c(
      "Coded MBL and pathology-supported MBL aggregate tiers.",
      "Coded MGUS and active-MM pressure aggregate layers.",
      "SMM is explicitly unresolved rather than inferred.",
      "Hospital-coded serious and recurrent infection aggregate strata.",
      "Mapped microbiology-confirmation rows and source audit where executable.",
      "Treatment modifier readiness rows.",
      "Bias warning and microbiology/hospital route separation.",
      "Person-time denominator and progression/state-transition warnings.",
      "Small-cell audit and public suppression labels."
    ),
    next_protocol_move = c(
      "Define validated biologic/source-supported MBL rules.",
      "Define monoclonal-protein support and MM exclusion rules.",
      "Add source-specific SMM value/code rules before counting.",
      "Lock endpoint code families and episode-gap rules.",
      "Finalize which organism/result fields count as confirmation.",
      "Define pre/post and time-updated treatment windows.",
      "Specify adjustment or stratification for testing opportunity.",
      "Specify competing-risk and state-transition handling.",
      "Group or suppress sparse overlap strata before sharing."
    ),
    blocker_type = c(
      "source validation required",
      "source validation required",
      "source validation required",
      "protocol hardening",
      "protocol hardening",
      "protocol hardening",
      "protocol hardening",
      "protocol hardening",
      "privacy-safe aggregate only"
    ),
    priority = c("P0", "P0", "P1", "P1", "P1", "P1", "P1", "P1", "P0"),
    caveat = c(
      "Do not treat coded MBL as all biologic MBL.",
      "Do not treat coded MGUS as validated MGUS without support.",
      "Do not infer SMM from generic source availability.",
      "Accepted provisional means executable aggregate route, not final endpoint.",
      "No organism/result text is emitted.",
      "No treatment effect is estimated here.",
      "No adjustment is performed in this display layer.",
      "No survival or causal model is produced here.",
      "Suppression decisions remain binding."
    ),
    stringsAsFactors = FALSE
  )
  confluence_story_conform(rows, confluence_empty_protocol_runway())
}

confluence_attach_story_layer <- function(outputs) {
  if (is.null(outputs)) outputs <- confluence_empty_payload()
  outputs$story_cards <- confluence_story_cards(outputs)
  outputs$evidence_spine <- confluence_evidence_spine(outputs)
  outputs$overlap_signal_summary <- confluence_overlap_signal_summary(outputs)
  outputs$ingredient_map <- confluence_ingredient_map(outputs)
  outputs$protocol_runway <- confluence_protocol_runway(outputs)
  outputs
}

confluence_norm_code <- function(x) {
  toupper(gsub("[^A-Z0-9]", "", as.character(x %||% "")))
}

confluence_norm_text <- function(x) {
  x <- tolower(as.character(x %||% ""))
  x <- gsub("\u00e6", "ae", x, fixed = TRUE)
  x <- gsub("\u00f8", "oe", x, fixed = TRUE)
  x <- gsub("\u00e5", "aa", x, fixed = TRUE)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

confluence_code_sets <- function() {
  rows <- data.frame(
    concept_id = c(
      "cll_diagnosis", "cll_diagnosis",
      "richter_diagnosis", "richter_diagnosis",
      "mbl_diagnosis", "mbl_diagnosis",
      "mgus_diagnosis", "mgus_diagnosis", "mgus_diagnosis", "mgus_diagnosis",
      "mm_diagnosis", "mm_diagnosis",
      "mbl_patobank_non_cll_type", "mbl_patobank_nos", "mbl_patobank_cll_type",
      "cll_patobank_morphology_pressure",
      "mbl_flow_supported_candidate", "smm_unresolved_candidate"
    ),
    concept_label = c(
      "CLL diagnosis-coded candidate", "CLL ICD-normalized candidate",
      "Richter diagnosis-coded candidate", "Richter ICD-normalized candidate",
      "MBL diagnosis-coded candidate", "MBL ICD-normalized candidate",
      "MGUS diagnosis-coded candidate", "MGUS diagnosis-coded candidate", "MGUS ICD-normalized candidate", "MGUS ICD-normalized candidate",
      "MM diagnosis-coded candidate", "MM ICD-normalized candidate",
      "PATOBANK MBL, non-CLL-type", "PATOBANK MBL, NOS", "PATOBANK MBL, CLL-type",
      "PATOBANK CLL morphology pressure",
      "Flow-supported MBL candidate", "SMM unresolved candidate"
    ),
    disease_family = c(
      "CLL/MBL/Richter", "CLL/MBL/Richter",
      "CLL/MBL/Richter", "CLL/MBL/Richter",
      "CLL/MBL/Richter", "CLL/MBL/Richter",
      "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder",
      "Plasma-cell disorder", "Plasma-cell disorder",
      "CLL/MBL/Richter", "CLL/MBL/Richter", "CLL/MBL/Richter",
      "CLL/MBL/Richter",
      "CLL/MBL/Richter", "Plasma-cell disorder"
    ),
    source_role = c(
      rep("diagnosis code", 12),
      rep("pathology morphology", 4),
      "flow cytometry readiness", "unresolved source placeholder"
    ),
    code_system = c(
      rep("SKS diagnosis", 2),
      rep("SKS diagnosis", 2),
      rep("SKS diagnosis", 2),
      rep("SKS diagnosis", 4),
      rep("SKS diagnosis", 2),
      rep("SNOMED pathology morphology", 4),
      "flow cytometry", "source-specific definition pending"
    ),
    source_table_hint = c(
      rep("t_dalycare_diagnoses; diagnoses_all; LPR diagnosis layers", 12),
      rep("SDS_pato; PATOBANK SNOMED aggregate rows", 4),
      "LAB_Flowcytometry; flow cytometry aggregate rows", "DaMyDa/lab/diagnosis sources if mapped"
    ),
    source_column_hint = c(
      rep("diagnosis", 12),
      rep("snomed / c_snomedkode / morphology code", 4),
      "flow phenotype fields", "source-specific SMM field pending"
    ),
    code = c("DC911", "C911", "DC911B", "C911B", "DD479B", "D479B", "DD472", "DD472B", "D472", "D472B", "DC900", "C900", "M95911", "M96121", "M98231", "M98233", "", ""),
    exact_match_required = c(rep(TRUE, 16), FALSE, FALSE),
    include_or_exclude = c(rep("include", 15), "exclude", "include_if_validated", "include_if_validated"),
    validation_role = c(
      rep("candidate disease-state anchor", 12),
      "pathology-supported MBL candidate", "pathology-supported MBL candidate", "pathology-supported MBL candidate",
      "CLL/overt-disease contamination or exclusion pressure",
      "source-readiness only", "source-readiness only"
    ),
    evidence_status = c(
      rep("coded candidate cohort", 12),
      rep("pathology-supported candidate", 3),
      "contamination/exclusion-pressure evidence",
      "source validation required", "source validation required"
    ),
    acceptance_status = c(rep("not accepted person denominator", 16), "not accepted aggregate", "not accepted aggregate"),
    notes = c(
      "Exact CLL diagnosis-code anchor; not a validated person denominator.",
      "Normalized ICD form for CLL; exact match only.",
      "Exact Richter diagnosis-code anchor; validate timing against CLL course.",
      "Normalized ICD form for Richter; exact match only.",
      "Exact coded MBL anchor; not all biologic MBL.",
      "Normalized ICD form for coded MBL; exact match only.",
      "Exact MGUS anchor.",
      "Exact MGUS variant anchor.",
      "Normalized ICD form for MGUS.",
      "Normalized ICD variant form for MGUS.",
      "Exact MM anchor.",
      "Normalized ICD form for MM.",
      "Exact PATOBANK MBL SNOMED morphology; do not use prefix matching.",
      "Exact PATOBANK MBL SNOMED morphology; do not use prefix matching.",
      "Exact PATOBANK CLL-type MBL SNOMED morphology; do not use prefix matching.",
      "M98233 is CLL morphology and must never be classified as MBL.",
      "Flow evidence requires source-specific validation before MBL classification.",
      "SMM remains unresolved until source-specific aggregate logic exists."
    ),
    stringsAsFactors = FALSE
  )
  rows$normalized_code <- confluence_norm_code(rows$code)
  rows
}

confluence_disease_state_specs <- function() {
  data.frame(
    entity_id = c("cll_candidate", "mbl_candidate", "richter_candidate", "mgus_candidate", "smm_candidate", "mm_candidate", "any_pcd_candidate"),
    entity_label = c("CLL candidate", "MBL coded candidate", "Richter candidate", "MGUS coded candidate", "SMM candidate", "MM candidate", "Any plasma-cell disorder candidate"),
    disease_family = c("CLL/MBL/Richter", "CLL/MBL/Richter", "CLL/MBL/Richter", "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder"),
    danish_sks_code = c("DC911", "DD479B", "DC911B", "DD472", "", "DC900", ""),
    icd10_code = c("C91.1", "D47.9B", "C91.1B", "D47.2", "", "C90.0", ""),
    diagnosis_label = c(
      "Chronic lymphocytic leukemia",
      "Monoklonal B-celle lymfocytose / MBL",
      "Richter transformation",
      "Monoclonal gammopathy of undetermined significance / MGUS",
      "Smouldering multiple myeloma / SMM",
      "Multiple myeloma",
      "MGUS/SMM/MM or related plasma-cell disorder"
    ),
    validation_needed = c(
      "Confirm CLL registry or repeated diagnosis support; derive first qualifying state date.",
      "Treat DD479B / D47.9B as coded MBL only; deduplicate persons, exclude prior/concurrent CLL where appropriate, and seek flow-cytometry/lab support.",
      "Validate relation to CLL course and timing before overlap classification.",
      "Treat DD472 / D47.2 as coded MGUS only; seek M-protein/FLC/immunoglobulin support and exclude active MM at or before MGUS index for strict definitions.",
      "Locate and validate SMM-specific registry, diagnosis, or laboratory criteria before use.",
      "Confirm DaMyDa and/or DC900 / C90.0 support plus staging/treatment evidence where available.",
      "Define source hierarchy across MGUS, SMM, MM, plasmacytoma, plasma-cell leukemia, and AL amyloidosis before grouping."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_reference_diagnosis_counts <- function(project_root = ".") {
  path <- file.path(project_root, "config", "cartography-reference", "files", "cartography_t_dalycare_diagnoses_value_counts.tsv")
  if (!file.exists(path)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  ref <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(ref) || !nrow(ref) || !"value" %in% names(ref)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(ref$value),
    n_records = suppressWarnings(as.numeric(ref$n_rows %||% ref$n %||% NA_real_)),
    source_table = as.character(ref$object_name %||% ref$source_name %||% "t_dalycare_diagnoses"),
    source_column = as.character(ref$column_name %||% "diagnosis_code"),
    evidence_source = "checked-in cartography-reference rows",
    stringsAsFactors = FALSE
  )
}

confluence_current_diagnosis_counts <- function(column_top_values = NULL) {
  if (!is.data.frame(column_top_values) || !nrow(column_top_values) || !"value" %in% names(column_top_values)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  code <- confluence_norm_code(column_top_values$value)
  table_name <- as.character(column_top_values$table_name %||% "")
  column_name <- as.character(column_top_values$column_name %||% "")
  likely_diagnosis <- grepl("diag|diagnos|icd|sks|tumor|tumour", paste(table_name, column_name), ignore.case = TRUE)
  rows <- column_top_values[likely_diagnosis & nzchar(code), , drop = FALSE]
  if (!nrow(rows)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(rows$value),
    n_records = suppressWarnings(as.numeric(rows$n %||% rows$n_rows %||% NA_real_)),
    source_table = as.character(rows$table_name %||% ""),
    source_column = as.character(rows$column_name %||% ""),
    evidence_source = "current-run profiled aggregate rows",
    stringsAsFactors = FALSE
  )
}

confluence_best_count_for_code <- function(code, current_counts, reference_counts) {
  norm <- confluence_norm_code(code)
  current <- current_counts[current_counts$code == norm & !is.na(current_counts$n_records), , drop = FALSE]
  if (nrow(current)) {
    current <- current[order(-current$n_records), , drop = FALSE][1, , drop = FALSE]
    return(current)
  }
  reference <- reference_counts[reference_counts$code == norm & !is.na(reference_counts$n_records), , drop = FALSE]
  if (nrow(reference)) {
    reference <- reference[order(-reference$n_records), , drop = FALSE][1, , drop = FALSE]
    return(reference)
  }
  empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character())
}

confluence_reference_snomed_counts <- function(project_root = ".") {
  path <- file.path(project_root, "config", "cartography-reference", "files", "cartography_pato_top_snomed.tsv")
  if (!file.exists(path)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  ref <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(ref) || !nrow(ref) || !"snomed" %in% names(ref)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(ref$snomed),
    n_records = suppressWarnings(as.numeric(ref$n %||% NA_real_)),
    source_table = "SDS_pato",
    source_column = "SNOMED aggregate",
    evidence_source = "checked-in cartography-reference PATOBANK SNOMED rows",
    stringsAsFactors = FALSE
  )
}

confluence_current_code_counts <- function(column_top_values = NULL) {
  if (!is.data.frame(column_top_values) || !nrow(column_top_values) || !"value" %in% names(column_top_values)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(column_top_values$value),
    n_records = suppressWarnings(as.numeric(column_top_values$n %||% column_top_values$n_rows %||% NA_real_)),
    source_table = as.character(column_top_values$table_name %||% column_top_values$object_name %||% ""),
    source_column = as.character(column_top_values$column_name %||% ""),
    evidence_source = "current-run profiled aggregate rows",
    stringsAsFactors = FALSE
  )
}

confluence_best_count_for_codes <- function(codes, current_counts, reference_counts) {
  codes <- confluence_norm_code(codes)
  codes <- codes[nzchar(codes)]
  empty <- empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character())
  if (!length(codes)) return(empty)
  current <- current_counts[current_counts$code %in% codes & !is.na(current_counts$n_records), , drop = FALSE]
  if (nrow(current)) return(current)
  reference <- reference_counts[reference_counts$code %in% codes & !is.na(reference_counts$n_records), , drop = FALSE]
  if (nrow(reference)) return(reference)
  empty
}

confluence_suppress_count <- function(n, min_cell_count = atlas_min_cell_count()) {
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  n <- suppressWarnings(as.numeric(n[[1]] %||% NA_real_))
  if (is.na(n)) {
    return(list(display = "query executable not run", n_public = NA_real_, suppressed = FALSE, status = "not run"))
  }
  if (n > 0 && n < min_cell_count) {
    return(list(display = paste0("<", min_cell_count), n_public = NA_real_, suppressed = TRUE, status = "suppressed small cell"))
  }
  list(display = format(n, big.mark = ",", scientific = FALSE, trim = TRUE), n_public = n, suppressed = FALSE, status = "not suppressed")
}

confluence_source_count_row <- function(source_tier_id, source_tier_label, disease_family, code_system,
                                        codes, source_role, hits, validation_needed, notes,
                                        min_cell_count = atlas_min_cell_count(),
                                        evidence_status = "source validation required",
                                        acceptance_status = "not accepted person denominator") {
  has_count <- is.data.frame(hits) && nrow(hits) && any(!is.na(hits$n_records))
  n_records <- if (has_count) sum(suppressWarnings(as.numeric(hits$n_records)), na.rm = TRUE) else NA_real_
  suppressed <- confluence_suppress_count(n_records, min_cell_count = min_cell_count)
  data.frame(
    source_tier_id = source_tier_id,
    source_tier_label = source_tier_label,
    disease_family = disease_family,
    code_system = code_system,
    codes = paste(codes[nzchar(codes)], collapse = " / "),
    source_role = source_role,
    count_display = if (has_count) suppressed$display else "not available in current aggregate output",
    n_records = suppressed$n_public,
    count_kind = if (has_count) "aggregate code rows, not distinct people" else "source-readiness signal, not outcome count",
    evidence_status = evidence_status,
    acceptance_status = acceptance_status,
    evidence_confidence = if (has_count && any(grepl("current-run", hits$evidence_source))) "profiled aggregate" else if (has_count) "fallback/reference" else "source validation required",
    source_table = if (has_count) paste(unique(hits$source_table), collapse = "; ") else "",
    source_column = if (has_count) paste(unique(hits$source_column), collapse = "; ") else "",
    suppression_status = if (has_count) suppressed$status else "not run",
    validation_needed = validation_needed,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

confluence_mbl_source_counts <- function(project_root = ".", column_top_values = NULL, min_cell_count = atlas_min_cell_count()) {
  current_counts <- confluence_current_code_counts(column_top_values)
  diagnosis_counts <- confluence_reference_diagnosis_counts(project_root)
  snomed_counts <- confluence_reference_snomed_counts(project_root)
  bind_rows_base(list(
    confluence_source_count_row(
      "diagnosis_coded_mbl", "Diagnosis-coded MBL", "CLL/MBL/Richter", "SKS diagnosis",
      c("DD479B", "D479B"), "coded diagnosis anchor",
      confluence_best_count_for_codes(c("DD479B", "D479B"), current_counts, diagnosis_counts),
      "Deduplicate persons, derive first date, and exclude prior/concurrent overt CLL where appropriate.",
      "DD479B / D47.9B remains coded-candidate MBL, not validated biologic MBL.",
      min_cell_count = min_cell_count,
      evidence_status = "coded candidate cohort"
    ),
    confluence_source_count_row(
      "patobank_mbl_any", "PATOBANK SNOMED MBL, any exact MBL code", "CLL/MBL/Richter", "SNOMED pathology morphology",
      c("M95911", "M96121", "M98231"), "pathology-supported MBL candidate",
      confluence_best_count_for_codes(c("M95911", "M96121", "M98231"), current_counts, snomed_counts),
      "Validate person deduplication and exclude nearby overt CLL/Richter evidence before using as MBL state.",
      "Exact SNOMED matches only. Do not use starts_with(\"M9823\") or other prefix logic.",
      min_cell_count = min_cell_count,
      evidence_status = "pathology-supported candidate"
    ),
    confluence_source_count_row(
      "patobank_mbl_cll_type", "PATOBANK SNOMED MBL, CLL-type M98231", "CLL/MBL/Richter", "SNOMED pathology morphology",
      c("M98231"), "pathology-supported MBL candidate",
      confluence_best_count_for_codes(c("M98231"), current_counts, snomed_counts),
      "Treat as CLL-type MBL candidate only after overt CLL contamination checks.",
      "M98231 is CLL-type MBL; exact match only.",
      min_cell_count = min_cell_count,
      evidence_status = "pathology-supported candidate"
    ),
    confluence_source_count_row(
      "patobank_mbl_non_cll_type", "PATOBANK SNOMED MBL, non-CLL-type M95911", "CLL/MBL/Richter", "SNOMED pathology morphology",
      c("M95911"), "pathology-supported MBL candidate",
      confluence_best_count_for_codes(c("M95911"), current_counts, snomed_counts),
      "Validate source and person timing before using as disease-state evidence.",
      "M95911 is non-CLL-type MBL; exact match only.",
      min_cell_count = min_cell_count,
      evidence_status = "pathology-supported candidate"
    ),
    confluence_source_count_row(
      "patobank_mbl_nos", "PATOBANK SNOMED MBL, NOS M96121", "CLL/MBL/Richter", "SNOMED pathology morphology",
      c("M96121"), "pathology-supported MBL candidate",
      confluence_best_count_for_codes(c("M96121"), current_counts, snomed_counts),
      "Validate source and person timing before using as disease-state evidence.",
      "M96121 is MBL NOS; exact match only.",
      min_cell_count = min_cell_count,
      evidence_status = "pathology-supported candidate"
    ),
    confluence_source_count_row(
      "patobank_cll_morphology_pressure", "PATOBANK CLL morphology pressure M98233", "CLL/MBL/Richter", "SNOMED pathology morphology",
      c("M98233"), "CLL/overt-disease contamination or exclusion pressure",
      confluence_best_count_for_codes(c("M98233"), current_counts, snomed_counts),
      "Use as overt CLL pressure when validating MBL, not as MBL evidence.",
      "M98233 is CLL morphology and must never be classified as MBL.",
      min_cell_count = min_cell_count,
      evidence_status = "contamination/exclusion-pressure evidence",
      acceptance_status = "not accepted MBL evidence"
    ),
    confluence_source_count_row(
      "flow_supported_mbl_candidate", "Flow-supported MBL candidate", "CLL/MBL/Richter", "flow cytometry",
      character(), "flow cytometry readiness",
      empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()),
      "Define flow-cytometry phenotype criteria and clonal B-cell burden logic before use.",
      "Flow-supported MBL remains source validation required in v0.2.",
      min_cell_count = min_cell_count,
      evidence_status = "source validation required",
      acceptance_status = "not accepted aggregate"
    )
  ))
}

confluence_mgus_source_counts <- function(project_root = ".", column_top_values = NULL, min_cell_count = atlas_min_cell_count()) {
  current_counts <- confluence_current_code_counts(column_top_values)
  diagnosis_counts <- confluence_reference_diagnosis_counts(project_root)
  bind_rows_base(list(
    confluence_source_count_row(
      "diagnosis_coded_mgus", "Diagnosis-coded MGUS", "Plasma-cell disorder", "SKS diagnosis",
      c("DD472", "DD472B", "D472", "D472B"), "coded diagnosis anchor",
      confluence_best_count_for_codes(c("DD472", "DD472B", "D472", "D472B"), current_counts, diagnosis_counts),
      "Derive person-level first date and exclude active MM/AL/WM pressure before strict MGUS classification.",
      "MGUS diagnosis-code rows are candidate anchors, not validated persons.",
      min_cell_count = min_cell_count,
      evidence_status = "coded candidate cohort"
    ),
    confluence_source_count_row(
      "lab_supported_mgus", "Lab-supported MGUS candidate", "Plasma-cell disorder", "NPU/LABKA/isotype",
      character(), "laboratory readiness",
      empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()),
      "Map M-protein, FLC, immunoglobulin, and isotype evidence before use.",
      "Laboratory-supported MGUS remains source validation required in v0.2.",
      min_cell_count = min_cell_count,
      evidence_status = "source validation required",
      acceptance_status = "not accepted aggregate"
    ),
    confluence_source_count_row(
      "non_igm_compatible_mgus", "Non-IgM-compatible MGUS candidate", "Plasma-cell disorder", "NPU/LABKA/isotype",
      character(), "laboratory readiness",
      empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()),
      "Use MGUS manuscript-style biomarker tiers only after source-specific validation.",
      "Non-IgM-compatible MGUS remains source validation required in v0.2.",
      min_cell_count = min_cell_count,
      evidence_status = "source validation required",
      acceptance_status = "not accepted aggregate"
    ),
    confluence_source_count_row(
      "active_mm_pressure", "Active MM / AL / WM exclusion pressure", "Plasma-cell disorder", "diagnosis/registry/treatment",
      c("DC900", "C900"), "exclusion-pressure evidence",
      confluence_best_count_for_codes(c("DC900", "C900"), current_counts, diagnosis_counts),
      "Use as exclusion or state-transition pressure for strict MGUS definitions.",
      "Active plasma-cell malignancy pressure is not MGUS evidence.",
      min_cell_count = min_cell_count,
      evidence_status = "exclusion-pressure evidence",
      acceptance_status = "not accepted MGUS evidence"
    )
  ))
}

confluence_disease_state_counts <- function(project_root = ".", column_top_values = NULL) {
  specs <- confluence_disease_state_specs()
  current_counts <- confluence_current_diagnosis_counts(column_top_values)
  reference_counts <- confluence_reference_diagnosis_counts(project_root)
  rows <- lapply(seq_len(nrow(specs)), function(i) {
    spec <- specs[i, , drop = FALSE]
    if (!nzchar(spec$danish_sks_code[[1]])) {
      return(data.frame(
        entity_id = spec$entity_id,
        entity_label = spec$entity_label,
        disease_family = spec$disease_family,
        danish_sks_code = spec$danish_sks_code,
        icd10_code = spec$icd10_code,
        diagnosis_label = spec$diagnosis_label,
        count_display = "query executable not run",
        n_records = NA_real_,
        count_kind = "not run",
        evidence_status = "source validation required",
        acceptance_status = "not accepted aggregate",
        evidence_confidence = "candidate mapping",
        source_table = "",
        source_column = "",
        evidence_source = "scaffold-only row",
        validation_needed = spec$validation_needed,
        notes = "No accepted aggregate person count exists in this scaffold-first CONFLUENCE implementation.",
        stringsAsFactors = FALSE
      ))
    }
    hit <- confluence_best_count_for_code(spec$danish_sks_code[[1]], current_counts, reference_counts)
    has_count <- nrow(hit) && !is.na(hit$n_records[[1]])
    data.frame(
      entity_id = spec$entity_id,
      entity_label = spec$entity_label,
      disease_family = spec$disease_family,
      danish_sks_code = spec$danish_sks_code,
      icd10_code = spec$icd10_code,
      diagnosis_label = spec$diagnosis_label,
      count_display = if (has_count) format(hit$n_records[[1]], big.mark = ",", scientific = FALSE, trim = TRUE) else "not available in current aggregate output",
      n_records = if (has_count) hit$n_records[[1]] else NA_real_,
      count_kind = "diagnosis-atlas records",
      evidence_status = "coded candidate cohort",
      acceptance_status = "not accepted person denominator",
      evidence_confidence = if (has_count && grepl("current-run", hit$evidence_source[[1]])) "profiled aggregate" else "fallback/reference",
      source_table = if (has_count) hit$source_table[[1]] else "",
      source_column = if (has_count) hit$source_column[[1]] else "",
      evidence_source = if (has_count) hit$evidence_source[[1]] else "no exact diagnosis-code top-value row found",
      validation_needed = spec$validation_needed,
      notes = "Evidence anchor only: diagnosis-atlas records are not validated persons and not a disease-state denominator.",
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_disease_state_counts() else out
}

confluence_overlap_counts <- function() {
  rows <- data.frame(
    overlap_id = c("cll_mgus", "cll_smm_mm", "cll_any_pcd", "mbl_mgus", "mbl_smm_mm", "mbl_any_pcd", "cll_mbl_pcd"),
    overlap_label = c(
      "CLL \u2229 MGUS",
      "CLL \u2229 SMM/MM",
      "CLL \u2229 any PCD",
      "MBL \u2229 MGUS",
      "MBL \u2229 SMM/MM",
      "MBL \u2229 any PCD",
      "CLL/MBL \u2229 MGUS/SMM/MM"
    ),
    left_state = c("CLL", "CLL", "CLL", "MBL", "MBL", "MBL", "CLL/MBL"),
    right_state = c("MGUS", "SMM/MM", "any plasma-cell disorder", "MGUS", "SMM/MM", "any plasma-cell disorder", "MGUS/SMM/MM"),
    stringsAsFactors = FALSE
  )
  rows$count_display <- "query executable not run"
  rows$n_people <- NA_real_
  rows$count_kind <- "not run"
  rows$evidence_status <- "query executable not run"
  rows$acceptance_status <- "not accepted aggregate"
  rows$feasibility_status <- "source validation required"
  rows$query_status <- "query executable not run"
  rows$notes <- "Scaffold-first row only. Do not label as accepted unless a future aggregate query returns acceptance_status == accepted."
  rows
}

confluence_overlap_timing <- function() {
  rows <- data.frame(
    timing_id = c("cll_mbl_first", "pcd_first", "same_day_or_same_year", "unknown_timing"),
    timing_label = c("CLL/MBL first", "Plasma-cell disorder first", "same-day/same-year", "unknown timing"),
    stringsAsFactors = FALSE
  )
  rows$count_display <- "query executable not run"
  rows$n_people <- NA_real_
  rows$count_kind <- "not run"
  rows$evidence_status <- "query executable not run"
  rows$acceptance_status <- "not accepted aggregate"
  rows$query_status <- "query executable not run"
  rows$notes <- "Overlap timing must be defined from first qualifying disease-state dates; no accepted aggregate timing output exists yet."
  rows
}

confluence_acceptance_gate <- function(row) {
  if (!is.data.frame(row) || !nrow(row)) {
    return(data.frame(accepted = FALSE, acceptance_gate_status = "failed: no row supplied", stringsAsFactors = FALSE))
  }
  row <- row[1, , drop = FALSE]
  val <- function(name) as.character(row[[name]] %||% "")
  executed <- identical(tolower(val("query_executed")), "yes") || identical(tolower(val("query_status")), "executed")
  count_kind_ok <- grepl("distinct people|distinct events|defined aggregate denominator|person-years|rate from suppressed aggregate components", val("count_kind"), ignore.case = TRUE)
  source_recorded <- nzchar(val("source_table")) && nzchar(val("code_set_version"))
  suppression_ok <- identical(tolower(val("min_cell_suppression_applied")), "yes") || grepl("not suppressed|suppressed", val("suppression_status"), ignore.case = TRUE)
  privacy_ok <- identical(tolower(val("public_safe")), "yes") || identical(tolower(val("privacy_safe")), "yes")
  first_date_ok <- grepl("first qualifying|overlap date|later of", val("first_date_logic"), ignore.case = TRUE)
  immortal_note_ok <- grepl("immortal", val("immortal_time_handling_note"), ignore.case = TRUE)
  mbl_tier_ok <- nzchar(val("mbl_tier"))
  checks <- c(executed, count_kind_ok, source_recorded, suppression_ok, privacy_ok, first_date_ok, immortal_note_ok, mbl_tier_ok)
  labels <- c("query not executed", "invalid count kind", "missing source/code-set version", "missing min-cell suppression", "privacy not certified", "missing first-date overlap logic", "missing immortal-time note", "missing MBL tier")
  accepted <- all(checks)
  data.frame(
    accepted = accepted,
    acceptance_gate_status = if (accepted) "passed" else paste("failed:", paste(labels[!checks], collapse = "; ")),
    stringsAsFactors = FALSE
  )
}

confluence_candidate_first_date_summary <- function() {
  data.frame(
    state_id = c("cll_first", "coded_mbl_first", "pathology_supported_mbl_first", "mgus_first", "mm_first", "overlap_entry_date"),
    state_label = c("CLL first qualifying date", "Coded MBL first qualifying date", "Pathology-supported MBL first qualifying date", "MGUS first qualifying date", "MM first qualifying date", "Overlap entry date"),
    source_tier = c("diagnosis/registry candidate", "diagnosis-coded MBL", "PATOBANK SNOMED-supported MBL", "diagnosis-coded MGUS", "diagnosis/DaMyDa candidate", "later of two qualifying disease-state dates"),
    count_display = "query executable not run",
    n_people = NA_real_,
    count_kind = "not run",
    acceptance_status = "not accepted aggregate",
    query_status = "query executable not run",
    first_date_logic = c(
      "First qualifying CLL evidence date must be derived inside the secure runtime.",
      "First exact DD479B/D479B MBL diagnosis date must be derived inside the secure runtime.",
      "First exact M95911/M96121/M98231 pathology-supported MBL date must be derived inside the secure runtime.",
      "First exact DD472/DD472B/D472/D472B MGUS date must be derived inside the secure runtime.",
      "First MM evidence date must be derived from diagnosis/registry/treatment hierarchy inside the secure runtime.",
      "Overlap date must be the later of the two qualifying disease-state dates, not ever/ever overlap."
    ),
    notes = "Scaffold row only; no raw dates are emitted.",
    stringsAsFactors = FALSE
  )
}

confluence_overlap_counts_accepted <- function(min_cell_count = atlas_min_cell_count()) {
  rows <- data.frame(
    overlap_id = c("coded_mbl_mgus", "pathology_mbl_mgus", "research_grade_mbl_mgus", "cll_mgus", "cll_mm"),
    overlap_label = c("coded MBL + MGUS", "pathology-supported MBL + MGUS", "validated/research-grade MBL + MGUS", "CLL + MGUS", "CLL + MM"),
    mbl_tier = c("coded MBL", "pathology-supported MBL", "validated/research-grade MBL", "CLL", "CLL"),
    pcd_tier = c("coded MGUS", "coded/lab-supported MGUS", "lab-supported MGUS", "coded/lab-supported MGUS", "active MM"),
    count_display = "query executable not run",
    n_people = NA_real_,
    count_kind = "not run",
    acceptance_status = "not accepted aggregate",
    query_status = "query executable not run",
    acceptance_gate_status = "failed: query not executed",
    suppression_status = paste0("min cell ", normalize_min_cell_count(min_cell_count), " required before public display"),
    notes = "No accepted overlap count exists in v0.2; future rows must pass confluence_acceptance_gate().",
    stringsAsFactors = FALSE
  )
  rows
}

confluence_overlap_timing_accepted <- function(min_cell_count = atlas_min_cell_count()) {
  rows <- data.frame(
    timing_id = c("mbl_before_mgus", "mgus_before_mbl", "same_90_day_window", "same_calendar_year", "unknown_unavailable"),
    timing_label = c("MBL before MGUS", "MGUS before MBL", "same 90-day window", "same calendar year", "unknown/unavailable timing"),
    count_display = "query executable not run",
    n_people = NA_real_,
    count_kind = "not run",
    acceptance_status = "not accepted aggregate",
    query_status = "query executable not run",
    acceptance_gate_status = "failed: query not executed",
    suppression_status = paste0("min cell ", normalize_min_cell_count(min_cell_count), " required before public display"),
    notes = "Timing rows must be derived from first qualifying disease-state dates; no raw dates are emitted.",
    stringsAsFactors = FALSE
  )
  rows
}

confluence_validation_waterfall <- function(entity_id, steps, source_tiers, min_cell_count = atlas_min_cell_count()) {
  data.frame(
    waterfall_id = paste(entity_id, seq_along(steps), sep = "_"),
    entity_id = entity_id,
    step_order = seq_along(steps),
    step_label = steps,
    source_tier = source_tiers,
    count_display = "query executable not run",
    n_people = NA_real_,
    count_kind = "not run",
    acceptance_status = "not accepted aggregate",
    query_status = "query executable not run",
    suppression_status = paste0("min cell ", normalize_min_cell_count(min_cell_count), " required before public display"),
    notes = "Scaffold-only waterfall step; no production aggregate has been accepted.",
    stringsAsFactors = FALSE
  )
}

confluence_mbl_validation_waterfall <- function(min_cell_count = atlas_min_cell_count()) {
  confluence_validation_waterfall(
    "mbl",
    c("Diagnosis-coded MBL", "PATOBANK exact MBL SNOMED support", "Remove CLL morphology pressure M98233", "Remove nearby CLL/Richter evidence", "Flow-supported candidate review", "Research-grade MBL candidate"),
    c("DD479B/D479B", "M95911/M96121/M98231", "M98233 exclusion pressure", "CLL/Richter timing pressure", "flow source validation", "not accepted aggregate"),
    min_cell_count = min_cell_count
  )
}

confluence_mgus_validation_waterfall <- function(min_cell_count = atlas_min_cell_count()) {
  confluence_validation_waterfall(
    "mgus",
    c("Diagnosis-coded MGUS", "Laboratory M-protein/FLC/isotype support", "Non-IgM-compatible tier", "Remove active MM/AL/WM pressure", "Research-grade MGUS candidate"),
    c("DD472/DD472B/D472/D472B", "NPU/LABKA/isotype source validation", "MGUS manuscript tier logic", "active PCD exclusion pressure", "not accepted aggregate"),
    min_cell_count = min_cell_count
  )
}

confluence_dual_clone_validation_waterfall <- function(min_cell_count = atlas_min_cell_count()) {
  confluence_validation_waterfall(
    "dual_clone",
    c("Candidate MBL/CLL state", "Candidate MGUS/PCD state", "First-date derivation", "Overlap date as later disease-state date", "Small-cell suppression", "Accepted dual-clone aggregate"),
    c("MBL/CLL tier explicit", "MGUS/PCD tier explicit", "secure runtime only", "immortal-time guard", "public reporting guard", "not accepted aggregate"),
    min_cell_count = min_cell_count
  )
}

confluence_small_cell_suppression_audit <- function(min_cell_count = atlas_min_cell_count()) {
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  suppressed <- confluence_suppress_count(max(1L, min_cell_count - 1L), min_cell_count = min_cell_count)
  data.frame(
    audit_id = c("confluence_public_min_cell_rule", "confluence_small_cell_display_fixture"),
    table_name = c("all CONFLUENCE public outputs", "confluence_small_cell_suppression_audit"),
    row_id = c("global", "below_threshold_fixture"),
    min_cell_count = c(min_cell_count, min_cell_count),
    raw_count_available = c("no raw count emitted", "below threshold, exact value withheld"),
    count_display = c(paste0("<", min_cell_count, " when below threshold"), suppressed$display),
    suppression_status = c("required", suppressed$status),
    public_safe = c("yes", "yes"),
    notes = c(
      "CONFLUENCE v0.2 emits aggregate-only public tables and requires suppression before accepted counts.",
      "Fixture row proves the public display uses a threshold label rather than an exact small count."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_utf8_quality_audit <- function(..., target = "CONFLUENCE generated output") {
  text_blob <- paste(unlist(list(...), recursive = TRUE, use.names = FALSE), collapse = " ")
  patterns <- list(
    U_00E2 = intToUtf8(0x00E2),
    U_FFFD = intToUtf8(0xFFFD),
    U_00C3 = intToUtf8(0x00C3)
  )
  rows <- lapply(names(patterns), function(id) {
    present <- grepl(patterns[[id]], text_blob, fixed = TRUE, useBytes = TRUE)
    data.frame(
      audit_id = paste0("utf8_", tolower(id)),
      target = target,
      pattern_code = sub("_", "+", id, fixed = TRUE),
      pattern_present = present,
      status = if (present) "failed mojibake audit" else "pass",
      notes = if (present) "Broken UTF-8/mojibake marker detected in generated text." else "No broken UTF-8/mojibake marker detected.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_infection_endpoint_definitions <- function() {
  data.frame(
    endpoint_id = c("infection_hospitalization", "recurrent_serious_infection", "microbiology_confirmed_infection", "bloodstream_infection", "resistant_organism_signal", "infection_related_mortality"),
    endpoint_label = c("Infection-related hospitalization", "Recurrent serious infection", "Microbiology-confirmed infection", "Bloodstream infection", "Resistant organism signal", "Infection-related mortality"),
    definition_status = "protocol-owned definition required",
    source_layer = c("SDS/LPR admissions and diagnosis layers", "SDS/LPR admissions and episode logic", "MiBa/PERSIMUNE/SP microbiology", "SP blood culture / microbiology", "Microbiology resistance/susceptibility", "Cause-of-death / mortality route"),
    required_code_set_status = "not finalized in CONFLUENCE v0.2",
    readiness_status = "source validation required",
    count_kind = "endpoint definition scaffold, not outcome count",
    notes = c(
      "Do not invent a final infection ICD code set inside this scaffold.",
      "Episode gap rules and person-time denominators must be protocol-owned.",
      "Testing opportunity and admission intensity need explicit handling.",
      "Separate blood-culture testing opportunity from confirmed bloodstream infection.",
      "Hospital/source aliases must not be treated as resistance or susceptibility values.",
      "Validate cause-of-death route before endpoint use."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_signal_present <- function(pattern, ...) {
  frames <- list(...)
  text_blob <- paste(unlist(lapply(frames, function(x) {
    if (!is.data.frame(x) || !nrow(x)) return(character())
    as.character(unlist(x, use.names = FALSE))
  }), use.names = FALSE), collapse = " ")
  grepl(pattern, confluence_norm_text(text_blob), perl = TRUE)
}

confluence_readiness_row <- function(id, label, source_layer, source_signal, present, validation_needed, notes = "") {
  data.frame(
    outcome_id = id,
    outcome_label = label,
    source_layer = source_layer,
    source_signal = source_signal,
    readiness_status = if (isTRUE(present)) "source evidence present; validation required" else "source validation required",
    evidence_status = if (isTRUE(present)) "profiled aggregate" else "query executable not run",
    count_kind = "source-readiness signal, not outcome count",
    validation_needed = validation_needed,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

confluence_infection_outcome_readiness <- function(sources = NULL, panel_raw_fields = NULL, panel_distributions = NULL, panels = NULL) {
  panel_text <- bind_rows_base(Filter(is.data.frame, panels %||% list()))
  rows <- list(
    confluence_readiness_row("infection_hospitalization", "Infection-related hospitalization", "SDS/LPR admissions and diagnosis layers", "infection diagnosis/contact/admission evidence", confluence_signal_present("infection|infektion|admission|kontakt|lpr|diagnos", sources, panel_raw_fields, panel_distributions, panel_text), "Define infection diagnosis code families, admission windows, and recurrent-episode gap rules."),
    confluence_readiness_row("recurrent_infection", "Recurrent serious infection", "Admissions/outcomes", "episode counting from hospital contacts", confluence_signal_present("infection|infektion|admission|kontakt|episode|recurrent", sources, panel_raw_fields, panel_distributions, panel_text), "Validate episode-splitting rules and person-time denominators."),
    confluence_readiness_row("microbiology_confirmed", "Microbiology-confirmed infection", "Laboratory & Diagnostics / MiBa / PERSIMUNE", "microbiology culture/PCR/analysis evidence", confluence_signal_present("micro|miba|persimune|culture|dyrkning|pcr", sources, panel_raw_fields, panel_distributions, panel_text), "Classify microbiology fields by organism, specimen, source, agent, and result role before analysis."),
    confluence_readiness_row("bloodstream_infection", "Bloodstream infection", "SP blood culture / microbiology", "blood culture evidence", confluence_signal_present("blood culture|bloodculture|bloddyrkning|bloed|sepsis", sources, panel_raw_fields, panel_distributions, panel_text), "Separate blood-culture testing opportunity from confirmed bloodstream infection."),
    confluence_readiness_row("resistant_organism", "Resistant organism signal", "Microbiology resistance/susceptibility", "resistance and susceptibility evidence", confluence_signal_present("resistance|resistent|susceptib|foelsom|folsom|sensitivitet|antibiot", sources, panel_raw_fields, panel_distributions, panel_text), "Do not treat hospital/source aliases as antibiotic or susceptibility values."),
    confluence_readiness_row("infection_mortality", "Infection-related mortality", "Death / cause-of-death route", "cause-of-death or infection mortality evidence", confluence_signal_present("death|dod|doed|mortality|cause of death|dodsarsag|doedsaarsag", sources, panel_raw_fields, panel_distributions, panel_text), "Validate cause-of-death source access and coding before endpoint use.")
  )
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_infection_outcome_readiness() else out
}

confluence_treatment_modifier_row <- function(id, label, source_layer, source_signal, present, validation_needed, notes = "") {
  data.frame(
    modifier_id = id,
    modifier_label = label,
    source_layer = source_layer,
    source_signal = source_signal,
    readiness_status = if (isTRUE(present)) "source evidence present; validation required" else "source validation required",
    evidence_status = if (isTRUE(present)) "profiled aggregate" else "query executable not run",
    count_kind = "source-readiness signal, not treatment count",
    validation_needed = validation_needed,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

confluence_treatment_modifier_readiness <- function(sources = NULL, panel_raw_fields = NULL, panel_distributions = NULL, panels = NULL) {
  panel_text <- bind_rows_base(Filter(is.data.frame, panels %||% list()))
  rows <- list(
    confluence_treatment_modifier_row("cll_treatment", "CLL treatment", "RKKP_CLL / treatment panels", "CLL registry treatment fields", confluence_signal_present("rkkp cll|cll|behandling|treatment", sources, panel_raw_fields, panel_distributions, panel_text), "Classify registry indicators separately from medication administrations."),
    confluence_treatment_modifier_row("btki", "BTKi / ibrutinib", "ATC/SKS/treatment", "ibrutinib/BTK inhibitor evidence", confluence_signal_present("ibrutinib|imbruvica|btki|btk inhibitor|l01xe27|bwha169", sources, panel_raw_fields, panel_distributions, panel_text), "Define timing as pre-treatment/post-treatment or time-updated modifier."),
    confluence_treatment_modifier_row("venetoclax", "Venetoclax", "ATC/SKS/treatment", "venetoclax evidence", confluence_signal_present("venetoclax|venclyxto", sources, panel_raw_fields, panel_distributions, panel_text), "Validate source and route before using as modifier."),
    confluence_treatment_modifier_row("anti_cd20", "Anti-CD20", "ATC/SKS/treatment", "rituximab/obinutuzumab evidence", confluence_signal_present("rituximab|mabthera|obinutuzumab|gazyvaro|anti cd20", sources, panel_raw_fields, panel_distributions, panel_text), "Separate regimen component, supportive context, and registry indicator evidence."),
    confluence_treatment_modifier_row("steroids", "Steroids", "Medication / treatment", "steroid evidence", confluence_signal_present("steroid|prednis|dexameth|methylpred", sources, panel_raw_fields, panel_distributions, panel_text), "Distinguish antineoplastic regimen components from supportive or unrelated steroid use."),
    confluence_treatment_modifier_row("mm_therapy", "MM therapy", "DaMyDa / ATC / SKS", "myeloma treatment evidence", confluence_signal_present("damyda|myeloma|bortezomib|lenalidomide|pomalidomide|carfilzomib|daratumumab", sources, panel_raw_fields, panel_distributions, panel_text), "Define MM therapy line and timing before modifier use."),
    confluence_treatment_modifier_row("anti_cd38", "Anti-CD38", "ATC/treatment", "daratumumab/isatuximab evidence", confluence_signal_present("daratumumab|darzalex|isatuximab|sarclisa|anti cd38", sources, panel_raw_fields, panel_distributions, panel_text), "Validate source and line of therapy."),
    confluence_treatment_modifier_row("imid", "IMiD", "ATC/treatment", "lenalidomide/pomalidomide/thalidomide evidence", confluence_signal_present("lenalidomide|pomalidomide|thalidomide|imid", sources, panel_raw_fields, panel_distributions, panel_text), "Validate drug concept grouping and source separation."),
    confluence_treatment_modifier_row("proteasome_inhibitor", "Proteasome inhibitor", "ATC/treatment", "bortezomib/carfilzomib/ixazomib evidence", confluence_signal_present("bortezomib|carfilzomib|ixazomib|proteasome", sources, panel_raw_fields, panel_distributions, panel_text), "Validate drug concept grouping and source separation."),
    confluence_treatment_modifier_row("asct_hdt", "ASCT/HDT", "SKS/procedure therapy", "stem-cell transplant/high-dose therapy evidence", confluence_signal_present("asct|hdt|stem cell|stamcelle|transplant|bwgc|bwha", sources, panel_raw_fields, panel_distributions, panel_text), "Treat as procedure/treatment timing evidence, not medication.")
  )
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_treatment_modifier_readiness() else out
}

confluence_estimands <- function() {
  data.frame(
    estimand_id = c("first_serious_infection", "recurrent_infection_burden", "microbiology_confirmed_phenotype", "additive_interaction_dual_clone"),
    title = c("First serious infection estimand", "Recurrent infection burden estimand", "Microbiology-confirmed infection phenotype estimand", "Additive interaction / dual-clone vulnerability estimand"),
    population = c(
      "Adults in DALY-CARE with validated CLL/MBL and/or validated MGUS/SMM/MM disease states, alive and under observation at disease-state entry.",
      "Same disease-state population as the primary estimand.",
      "Subcohort with microbiology/blood-culture ascertainment opportunity.",
      "Adults with sufficient follow-up and validated disease-state timing."
    ),
    exposure_condition = c(
      "Time-varying clonal disease state: CLL/MBL only, PCD only, or CLL/MBL + PCD overlap.",
      "Time-varying clonal disease state groups.",
      "CLL/MBL only, PCD only, overlap.",
      "Joint exposure: CLL/MBL yes/no x PCD yes/no."
    ),
    outcome_variable = c(
      "First serious infection within 2 years after disease-state entry, optionally enriched by microbiology confirmation.",
      "Number of serious infection episodes per person-year.",
      "Positive culture/PCR/analysis, bloodstream infection, organism class, and resistance signal.",
      "2-year serious infection risk."
    ),
    intercurrent_events = c(
      "Death before infection is a competing event; progression and treatment initiation are time-updated modifiers or stratifiers.",
      "Death terminates follow-up; treatment can be handled as time-updated.",
      "Testing intensity and admission intensity are key ascertainment processes.",
      "Death as competing event; treatment as time-updated modifier/sensitivity."
    ),
    summary_measure = c(
      "Cumulative incidence at 1 and 2 years plus adjusted cause-specific or subdistribution hazard ratio.",
      "Incidence rate ratio or recurrent-event model estimate.",
      "Proportion or rate of microbiology-confirmed infections by organism class and disease state.",
      "Excess risk due to interaction, such as RERI or risk-difference interaction."
    ),
    plain_language = c(
      "Among people who newly enter a CLL/MBL, plasma-cell-disorder, or overlap state, what is the 1-2 year risk of serious infection, accounting for death and progression?",
      "Is the overlap group experiencing more repeated infection episodes, not just earlier first infection?",
      "Do overlap patients have a different infection phenotype, not just a higher infection count?",
      "Is infection risk in people with both clonal states greater than the sum of the risks from each state alone?"
    ),
    feasibility_status = "feasibility only; query executable not run; not causal",
    stringsAsFactors = FALSE
  )
}

confluence_validation_checklist <- function() {
  data.frame(
    entity_id = c("cll", "mbl", "mgus", "smm", "mm", "overlap", "infection", "treatment", "privacy"),
    entity_label = c("CLL", "MBL", "MGUS", "SMM", "MM", "Overlap person-time", "Infection outcomes", "Treatment modifiers", "Privacy/suppression"),
    validation_step = c(
      "Use RKKP_CLL preferred when available; support with repeated diagnosis, treatment, molecular, or flow/FISH/IGHV evidence.",
      "Use DD479B / D47.9B as coded candidate; exclude prior/concurrent CLL where appropriate and seek flow-cytometry/lab support.",
      "Use DD472 / D47.2 as coded candidate; seek M-protein/FLC/immunoglobulin support and exclude active MM at or before MGUS index.",
      "Locate SMM-specific registry/lab/diagnosis logic if present.",
      "Use DaMyDa and/or DC900 / C90.0 with treatment/staging support where available.",
      "Define overlap date as the later of two qualifying disease-state entry dates; do not classify pre-overlap time as overlap time.",
      "Separate serious infection, recurrent infection, microbiology-confirmed infection, bloodstream infection, resistance, and infection mortality.",
      "Handle CLL/MM treatments as time-updated modifiers, not ignored confounders.",
      "Keep outputs aggregate-only with small-cell suppression and no individual-record examples."
    ),
    source_hint = c("RKKP_CLL; diagnoses_all; t_dalycare_diagnoses", "DD479B / D47.9B; flow cytometry if available", "DD472 / D47.2; LABKA/NPU M-protein/FLC/Ig evidence", "DaMyDa/lab/diagnosis sources if mapped", "RKKP_DaMyDa; DC900 / C90.0", "future accepted aggregate query", "SDS/LPR; microbiology; blood culture; mortality routes", "Treatment panels; ATC/SKS; RKKP registries; SP/SMR/prescriptions", "atlas min-cell and public-frame sanitization"),
    status = c("source validation required", "coded candidate cohort", "coded candidate cohort", "query executable not run", "coded candidate cohort", "query executable not run", "source validation required", "source validation required", "required"),
    notes = c(
      "CLL diagnosis-atlas records are not validated persons.",
      "MBL is a biologic/flow-cytometry entity; the atlas anchor is a diagnosis-code candidate.",
      "MGUS ascertainment may be incidental and testing-opportunity dependent.",
      "SMM is not accepted unless a source-specific aggregate run proves it.",
      "MM diagnosis records are not equivalent to validated DaMyDa person denominators.",
      "This prevents immortal-time bias from naive ever-overlap classification.",
      "Testing/admission opportunity must be modelled or stratified.",
      "BTKi, venetoclax, anti-CD20, steroids, IMiD, PI, anti-CD38, and ASCT/HDT can modify infection risk.",
      "No identifiers, CPR values, individual event dates, pathology narratives, or unsafe small cells."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_bias_warnings <- function() {
  data.frame(
    bias_id = c("immortal_time", "surveillance_testing", "mbl_undercoding", "mgus_ascertainment", "treatment_confounding", "progression_state_transition", "competing_mortality", "small_cell_suppression"),
    bias_label = c("immortal-time bias", "surveillance/testing bias", "MBL undercoding", "MGUS ascertainment bias", "treatment confounding", "progression/state-transition bias", "competing mortality", "small-cell suppression"),
    why_it_matters = c(
      "Overlap patients must survive long enough to receive the second qualifying disease-state diagnosis.",
      "CLL/MM patients may receive more labs, admissions, and cultures, inflating observed infection ascertainment.",
      "Many MBL cases are flow-detected or biologic and may not be diagnosis-coded.",
      "MGUS is often incidental and depends on testing opportunity.",
      "BTKi, venetoclax, anti-CD20, steroids, IMiD, PI, anti-CD38, ASCT/HDT, and other treatments may cause or prevent infections.",
      "MGUS/SMM can progress to MM and MBL can progress to CLL, changing risk state over time.",
      "Death before infection competes with the infection endpoint.",
      "MBL overlap strata may be small and must remain suppressed or grouped when below threshold."
    ),
    mitigation = c(
      "Define overlap entry at the second qualifying disease-state date or use time-varying exposure.",
      "Separate hospital-coded and microbiology-confirmed outcomes; consider testing/admission intensity.",
      "Label DD479B / D47.9B as coded MBL candidate, not all biologic MBL.",
      "Use M-protein/FLC/immunoglobulin testing opportunity and sensitivity analyses.",
      "Model treatment as pre/post strata or time-updated modifier.",
      "Use time-updated disease states and first-date validation.",
      "Use competing-risk cumulative incidence or cause-specific handling.",
      "Report aggregate-only with suppression and count-kind labels."
    ),
    severity = c("critical", "high", "high", "high", "critical", "high", "high", "critical"),
    stringsAsFactors = FALSE
  )
}

confluence_recommended_next_actions <- function() {
  data.frame(
    action_id = c("deduplicate_first_dates", "run_overlap_counts", "validate_mbl", "validate_mgus", "map_infection_outcomes", "classify_microbiology_roles", "add_treatment_modifiers", "review_small_cells"),
    action_label = c(
      "Build person-deduplicated disease-state first-date aggregate",
      "Run overlap-count aggregates with accepted/not-accepted status",
      "Validate coded MBL against CLL conflicts and flow/lab support",
      "Validate coded MGUS against MM conflicts and monoclonal-protein support",
      "Define serious and recurrent infection outcomes",
      "Classify microbiology field roles before organism/resistance panels",
      "Map treatment modifiers as time-updated source-specific layers",
      "Pre-check small-cell suppression for MBL/PCD overlaps"
    ),
    owner_role = c("data manager / analyst", "data manager / analyst", "CLL researcher + data manager", "PCD researcher + data manager", "clinician investigator + analyst", "microbiology/source owner + analyst", "treatment/source owner + analyst", "data manager / QA"),
    priority = c("P0", "P0", "P0", "P0", "P1", "P1", "P1", "P0"),
    status = c("not started", "query executable not run", "source validation required", "source validation required", "source validation required", "source validation required", "source validation required", "required"),
    notes = c(
      "Needed before any overlap timing or target-trial state assignment.",
      "Do not label overlap rows accepted until the aggregate run returns acceptance_status == accepted.",
      "Classify as coded MBL until validated biologic MBL logic exists.",
      "Separate MGUS, SMM, active MM, and paraprotein associated with CLL.",
      "Outcome definitions should be protocol-owned before extraction.",
      "Avoid repeating the hospital/source alias error in antibiotic/susceptibility panels.",
      "Treat medications/procedures/registry indicators as different evidence types.",
      "Likely limiting step for MBL overlap reporting."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_summary <- function(disease_counts, infection_readiness, treatment_readiness) {
  candidate_rows <- sum(disease_counts$evidence_status == "coded candidate cohort", na.rm = TRUE)
  diagnosis_records <- sum(suppressWarnings(as.numeric(disease_counts$n_records)), na.rm = TRUE)
  readiness_present <- sum(grepl("present", infection_readiness$readiness_status %||% "", ignore.case = TRUE), na.rm = TRUE)
  treatment_present <- sum(grepl("present", treatment_readiness$readiness_status %||% "", ignore.case = TRUE), na.rm = TRUE)
  data.frame(
    metric = c("panel_status", "candidate_disease_anchors", "diagnosis_atlas_record_anchors", "overlap_acceptance_status", "infection_readiness_signals", "treatment_modifier_signals", "raw_patient_rows_emitted"),
    label = c("Panel status", "Candidate disease anchors", "Diagnosis-atlas record anchors", "Overlap acceptance status", "Infection readiness signals", "Treatment modifier readiness signals", "Raw patient rows emitted"),
    value = c("scaffold first", as.character(candidate_rows), format(diagnosis_records, big.mark = ",", scientific = FALSE, trim = TRUE), "query executable not run", as.character(readiness_present), as.character(treatment_present), "0"),
    status = c("feasibility only", "coded candidate cohort", "diagnosis-atlas records", "not accepted aggregate", "source validation required", "source validation required", "privacy-safe aggregate only"),
    count_kind = c("not patient count", "source/code rows", "diagnosis-atlas records", "not run", "source-readiness signal", "source-readiness signal", "not patient count"),
    evidence_confidence = c("candidate mapping", "fallback/reference", "fallback/reference", "query executable not run", "profiled aggregate", "profiled aggregate", "production safeguard"),
    notes = c(
      "CONFLUENCE renders feasibility infrastructure only; it does not execute new production overlap queries.",
      "CLL, MBL, MGUS, and MM anchors are candidate diagnosis-code evidence until validated.",
      "Diagnosis-atlas records are evidence anchors, not validated person denominators.",
      "Overlap counts and timing remain not-run/not-accepted in this scaffold implementation.",
      "Presence indicates route/readiness evidence only, not outcome counts.",
      "Presence indicates route/readiness evidence only, not medication exposure counts.",
      "The panel emits aggregate rows only."
    ),
    stringsAsFactors = FALSE
  )
}

build_confluence_feasibility_outputs <- function(project_root = ".",
                                                 sources = NULL,
                                                 columns = NULL,
                                                 column_profiles = NULL,
                                                 column_top_values = NULL,
                                                 panels = NULL,
                                                 panel_raw_fields = NULL,
                                                 panel_distributions = NULL,
                                                 panel_kpis = NULL,
                                                 canonical_reconciliation = NULL,
                                                 legacy_reference_vs_current = NULL,
                                                 min_cell_count = atlas_min_cell_count()) {
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  code_sets <- confluence_code_sets()
  disease_counts <- confluence_disease_state_counts(project_root = project_root, column_top_values = column_top_values)
  mbl_source_counts <- confluence_mbl_source_counts(project_root = project_root, column_top_values = column_top_values, min_cell_count = min_cell_count)
  mgus_source_counts <- confluence_mgus_source_counts(project_root = project_root, column_top_values = column_top_values, min_cell_count = min_cell_count)
  overlap_counts <- confluence_overlap_counts()
  overlap_timing <- confluence_overlap_timing()
  candidate_first_date_summary <- confluence_candidate_first_date_summary()
  overlap_counts_accepted <- confluence_overlap_counts_accepted(min_cell_count = min_cell_count)
  overlap_timing_accepted <- confluence_overlap_timing_accepted(min_cell_count = min_cell_count)
  clone_outputs <- confluence_clone_placeholder_outputs(project_root = project_root, min_cell_count = min_cell_count)
  mbl_validation_waterfall <- confluence_mbl_validation_waterfall(min_cell_count = min_cell_count)
  mgus_validation_waterfall <- confluence_mgus_validation_waterfall(min_cell_count = min_cell_count)
  dual_clone_validation_waterfall <- confluence_dual_clone_validation_waterfall(min_cell_count = min_cell_count)
  small_cell_suppression_audit <- confluence_small_cell_suppression_audit(min_cell_count = min_cell_count)
  infection_endpoint_definitions <- confluence_infection_endpoint_definitions()
  infection_readiness <- confluence_infection_outcome_readiness(
    sources = sources,
    panel_raw_fields = panel_raw_fields,
    panel_distributions = panel_distributions,
    panels = panels
  )
  treatment_readiness <- confluence_treatment_modifier_readiness(
    sources = sources,
    panel_raw_fields = panel_raw_fields,
    panel_distributions = panel_distributions,
    panels = panels
  )
  utf8_quality_audit <- confluence_utf8_quality_audit(
    code_sets,
    disease_counts,
    mbl_source_counts,
    mgus_source_counts,
    overlap_counts,
    overlap_timing,
    candidate_first_date_summary,
    overlap_counts_accepted,
    overlap_timing_accepted,
    mbl_validation_waterfall,
    mgus_validation_waterfall,
    dual_clone_validation_waterfall,
    small_cell_suppression_audit,
    infection_endpoint_definitions,
    infection_readiness,
    treatment_readiness,
    confluence_estimands(),
    confluence_validation_checklist(),
    confluence_bias_warnings(),
    confluence_recommended_next_actions()
  )
  empty_production <- confluence_empty_payload()
  outputs <- list(
    summary = confluence_summary(disease_counts, infection_readiness, treatment_readiness),
    clone_route_manifest = clone_outputs$clone_route_manifest,
    clone_source_resolution = clone_outputs$clone_source_resolution,
    bcell_clone_evidence_counts = clone_outputs$bcell_clone_evidence_counts,
    pcd_clone_evidence_counts = clone_outputs$pcd_clone_evidence_counts,
    paraprotein_ambiguity_counts = clone_outputs$paraprotein_ambiguity_counts,
    mgus_reclassification_waterfall = clone_outputs$mgus_reclassification_waterfall,
    dual_clone_overlap_counts = clone_outputs$dual_clone_overlap_counts,
    dual_clone_overlap_timing = clone_outputs$dual_clone_overlap_timing,
    primary_overlap_exclusion_reasons = clone_outputs$primary_overlap_exclusion_reasons,
    clone_availability_protocol_runway = clone_outputs$clone_availability_protocol_runway,
    disease_state_counts = disease_counts,
    overlap_counts = overlap_counts,
    overlap_timing = overlap_timing,
    infection_outcome_readiness = infection_readiness,
    treatment_modifier_readiness = treatment_readiness,
    estimands = confluence_estimands(),
    validation_checklist = confluence_validation_checklist(),
    bias_warnings = confluence_bias_warnings(),
    recommended_next_actions = confluence_recommended_next_actions(),
    code_sets = code_sets,
    mbl_source_counts = mbl_source_counts,
    mgus_source_counts = mgus_source_counts,
    candidate_first_date_summary = candidate_first_date_summary,
    overlap_counts_accepted = overlap_counts_accepted,
    overlap_timing_accepted = overlap_timing_accepted,
    mbl_validation_waterfall = mbl_validation_waterfall,
    mgus_validation_waterfall = mgus_validation_waterfall,
    dual_clone_validation_waterfall = dual_clone_validation_waterfall,
    small_cell_suppression_audit = small_cell_suppression_audit,
    utf8_quality_audit = utf8_quality_audit,
    infection_endpoint_definitions = infection_endpoint_definitions,
    disease_state_person_counts = empty_production$disease_state_person_counts,
    first_date_availability = empty_production$first_date_availability,
    infection_endpoint_code_sets = empty_production$infection_endpoint_code_sets,
    infection_counts = empty_production$infection_counts,
    recurrent_infection_counts = empty_production$recurrent_infection_counts,
    infection_person_time = empty_production$infection_person_time,
    infection_rates = empty_production$infection_rates,
    microbiology_confirmation_counts = empty_production$microbiology_confirmation_counts,
    microbiology_confirmation_source_audit = empty_production$microbiology_confirmation_source_audit,
    production_query_review = empty_production$production_query_review,
    failed_query_audit = empty_production$failed_query_audit,
    source_resolution_audit = empty_production$source_resolution_audit,
    production_execution_summary = empty_production$production_execution_summary
  )
  confluence_attach_story_layer(outputs)
}

confluence_write_outputs <- function(outputs, output_dir) {
  if (is.null(outputs)) outputs <- confluence_empty_payload()
  outputs <- confluence_attach_story_layer(outputs)
  list(
    summary = write_csv(outputs$summary %||% confluence_empty_summary(), file.path(output_dir, "confluence_feasibility_summary.csv")),
    story_cards = write_csv(outputs$story_cards %||% confluence_empty_story_cards(), file.path(output_dir, "confluence_story_cards.csv")),
    evidence_spine = write_csv(outputs$evidence_spine %||% confluence_empty_evidence_spine(), file.path(output_dir, "confluence_evidence_spine.csv")),
    overlap_signal_summary = write_csv(outputs$overlap_signal_summary %||% confluence_empty_overlap_signal_summary(), file.path(output_dir, "confluence_overlap_signal_summary.csv")),
    ingredient_map = write_csv(outputs$ingredient_map %||% confluence_empty_ingredient_map(), file.path(output_dir, "confluence_ingredient_map.csv")),
    protocol_runway = write_csv(outputs$protocol_runway %||% confluence_empty_protocol_runway(), file.path(output_dir, "confluence_protocol_runway.csv")),
    clone_route_manifest = write_csv(outputs$clone_route_manifest %||% confluence_clone_empty_route_manifest(), file.path(output_dir, "confluence_clone_route_manifest.csv")),
    clone_source_resolution = write_csv(outputs$clone_source_resolution %||% confluence_clone_empty_source_resolution(), file.path(output_dir, "confluence_clone_source_resolution.csv")),
    bcell_clone_evidence_counts = write_csv(outputs$bcell_clone_evidence_counts %||% confluence_clone_empty_evidence_counts(), file.path(output_dir, "confluence_bcell_clone_evidence_counts.csv")),
    pcd_clone_evidence_counts = write_csv(outputs$pcd_clone_evidence_counts %||% confluence_clone_empty_evidence_counts(), file.path(output_dir, "confluence_pcd_clone_evidence_counts.csv")),
    paraprotein_ambiguity_counts = write_csv(outputs$paraprotein_ambiguity_counts %||% confluence_clone_empty_ambiguity_counts(), file.path(output_dir, "confluence_paraprotein_ambiguity_counts.csv")),
    mgus_reclassification_waterfall = write_csv(outputs$mgus_reclassification_waterfall %||% confluence_clone_empty_mgus_waterfall(), file.path(output_dir, "confluence_mgus_reclassification_waterfall.csv")),
    dual_clone_overlap_counts = write_csv(outputs$dual_clone_overlap_counts %||% confluence_clone_empty_overlap_counts(), file.path(output_dir, "confluence_dual_clone_overlap_counts.csv")),
    dual_clone_overlap_timing = write_csv(outputs$dual_clone_overlap_timing %||% confluence_clone_empty_overlap_timing(), file.path(output_dir, "confluence_dual_clone_overlap_timing.csv")),
    primary_overlap_exclusion_reasons = write_csv(outputs$primary_overlap_exclusion_reasons %||% confluence_clone_empty_exclusion_reasons(), file.path(output_dir, "confluence_primary_overlap_exclusion_reasons.csv")),
    clone_availability_protocol_runway = write_csv(outputs$clone_availability_protocol_runway %||% confluence_clone_empty_protocol_runway(), file.path(output_dir, "confluence_clone_availability_protocol_runway.csv")),
    disease_state_counts = write_csv(outputs$disease_state_counts %||% confluence_empty_disease_state_counts(), file.path(output_dir, "confluence_disease_state_counts.csv")),
    overlap_counts = write_csv(outputs$overlap_counts %||% confluence_empty_overlap_counts(), file.path(output_dir, "confluence_overlap_counts.csv")),
    overlap_timing = write_csv(outputs$overlap_timing %||% confluence_empty_overlap_timing(), file.path(output_dir, "confluence_overlap_timing.csv")),
    infection_outcome_readiness = write_csv(outputs$infection_outcome_readiness %||% confluence_empty_infection_outcome_readiness(), file.path(output_dir, "confluence_infection_outcome_readiness.csv")),
    treatment_modifier_readiness = write_csv(outputs$treatment_modifier_readiness %||% confluence_empty_treatment_modifier_readiness(), file.path(output_dir, "confluence_treatment_modifier_readiness.csv")),
    estimands = write_csv(outputs$estimands %||% confluence_empty_estimands(), file.path(output_dir, "confluence_estimands.csv")),
    validation_checklist = write_csv(outputs$validation_checklist %||% confluence_empty_validation_checklist(), file.path(output_dir, "confluence_validation_checklist.csv")),
    bias_warnings = write_csv(outputs$bias_warnings %||% confluence_empty_bias_warnings(), file.path(output_dir, "confluence_bias_warnings.csv")),
    recommended_next_actions = write_csv(outputs$recommended_next_actions %||% confluence_empty_recommended_next_actions(), file.path(output_dir, "confluence_recommended_next_actions.csv")),
    code_sets = write_csv(outputs$code_sets %||% confluence_empty_code_sets(), file.path(output_dir, "confluence_code_sets.csv")),
    mbl_source_counts = write_csv(outputs$mbl_source_counts %||% confluence_empty_source_counts(), file.path(output_dir, "confluence_mbl_source_counts.csv")),
    mgus_source_counts = write_csv(outputs$mgus_source_counts %||% confluence_empty_source_counts(), file.path(output_dir, "confluence_mgus_source_counts.csv")),
    candidate_first_date_summary = write_csv(outputs$candidate_first_date_summary %||% confluence_empty_candidate_first_date_summary(), file.path(output_dir, "confluence_candidate_first_date_summary.csv")),
    overlap_counts_accepted = write_csv(outputs$overlap_counts_accepted %||% confluence_empty_overlap_counts_accepted(), file.path(output_dir, "confluence_overlap_counts_accepted.csv")),
    overlap_timing_accepted = write_csv(outputs$overlap_timing_accepted %||% confluence_empty_overlap_timing_accepted(), file.path(output_dir, "confluence_overlap_timing_accepted.csv")),
    mbl_validation_waterfall = write_csv(outputs$mbl_validation_waterfall %||% confluence_empty_validation_waterfall(), file.path(output_dir, "confluence_mbl_validation_waterfall.csv")),
    mgus_validation_waterfall = write_csv(outputs$mgus_validation_waterfall %||% confluence_empty_validation_waterfall(), file.path(output_dir, "confluence_mgus_validation_waterfall.csv")),
    dual_clone_validation_waterfall = write_csv(outputs$dual_clone_validation_waterfall %||% confluence_empty_validation_waterfall(), file.path(output_dir, "confluence_dual_clone_validation_waterfall.csv")),
    small_cell_suppression_audit = write_csv(outputs$small_cell_suppression_audit %||% confluence_empty_small_cell_suppression_audit(), file.path(output_dir, "confluence_small_cell_suppression_audit.csv")),
    utf8_quality_audit = write_csv(outputs$utf8_quality_audit %||% confluence_empty_utf8_quality_audit(), file.path(output_dir, "confluence_utf8_quality_audit.csv")),
    infection_endpoint_definitions = write_csv(outputs$infection_endpoint_definitions %||% confluence_empty_infection_endpoint_definitions(), file.path(output_dir, "confluence_infection_endpoint_definitions.csv")),
    disease_state_person_counts = write_csv(outputs$disease_state_person_counts %||% confluence_empty_payload()$disease_state_person_counts, file.path(output_dir, "confluence_disease_state_person_counts.csv")),
    first_date_availability = write_csv(outputs$first_date_availability %||% confluence_empty_payload()$first_date_availability, file.path(output_dir, "confluence_first_date_availability.csv")),
    infection_endpoint_code_sets = write_csv(outputs$infection_endpoint_code_sets %||% confluence_empty_payload()$infection_endpoint_code_sets, file.path(output_dir, "confluence_infection_endpoint_code_sets.csv")),
    infection_counts = write_csv(outputs$infection_counts %||% confluence_empty_payload()$infection_counts, file.path(output_dir, "confluence_infection_counts.csv")),
    recurrent_infection_counts = write_csv(outputs$recurrent_infection_counts %||% confluence_empty_payload()$recurrent_infection_counts, file.path(output_dir, "confluence_recurrent_infection_counts.csv")),
    infection_person_time = write_csv(outputs$infection_person_time %||% confluence_empty_payload()$infection_person_time, file.path(output_dir, "confluence_infection_person_time.csv")),
    infection_rates = write_csv(outputs$infection_rates %||% confluence_empty_payload()$infection_rates, file.path(output_dir, "confluence_infection_rates.csv")),
    microbiology_confirmation_counts = write_csv(outputs$microbiology_confirmation_counts %||% confluence_empty_payload()$microbiology_confirmation_counts, file.path(output_dir, "confluence_microbiology_confirmation_counts.csv")),
    microbiology_confirmation_source_audit = write_csv(outputs$microbiology_confirmation_source_audit %||% confluence_empty_payload()$microbiology_confirmation_source_audit, file.path(output_dir, "confluence_microbiology_confirmation_source_audit.csv")),
    production_query_review = write_csv(outputs$production_query_review %||% confluence_empty_payload()$production_query_review, file.path(output_dir, "confluence_production_query_review.csv")),
    failed_query_audit = write_csv(outputs$failed_query_audit %||% confluence_empty_payload()$failed_query_audit, file.path(output_dir, "confluence_failed_query_audit.csv")),
    source_resolution_audit = write_csv(outputs$source_resolution_audit %||% confluence_empty_payload()$source_resolution_audit, file.path(output_dir, "confluence_source_resolution_audit.csv")),
    production_execution_summary = write_csv(outputs$production_execution_summary %||% confluence_empty_payload()$production_execution_summary, file.path(output_dir, "confluence_production_execution_summary.csv"))
  )
}
