smm_immunity_tracker_empty_summary <- function() {
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

smm_immunity_tracker_empty_story_cards <- function() {
  empty_df(
    card_id = character(),
    title = character(),
    status = character(),
    tone = character(),
    body = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_cohort_readiness <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    tracker_role = character(),
    time_origin = character(),
    entry_rule = character(),
    progression_endpoint = character(),
    competing_event = character(),
    readiness_status = character(),
    source_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_cohort_counts <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    time_origin = character(),
    n_people_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    source_acceptance_status = character(),
    tracker_status = character(),
    query_status = character(),
    suppression_status = character(),
    source_file_or_route = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_wp5_source_audit <- function() {
  empty_df(
    source_file = character(),
    source_root_label = character(),
    wp5_run_id = character(),
    path_status = character(),
    found = logical(),
    read_status = character(),
    rows_read = integer(),
    public_safe = logical(),
    secure_input_only = logical(),
    notes = character()
  )
}

smm_immunity_tracker_empty_tracker_status <- function() {
  empty_df(
    status_key = character(),
    status_value = character(),
    status_label = character(),
    caveat = character()
  )
}

smm_immunity_tracker_empty_endpoint_definitions <- function() {
  empty_df(
    endpoint_id = character(),
    endpoint_label = character(),
    endpoint_family = character(),
    definition_status = character(),
    route_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_infection_counts <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    analysis_window = character(),
    infection_endpoint_id = character(),
    infection_endpoint_label = character(),
    burden_window_role = character(),
    count_display = character(),
    n_people = numeric(),
    event_count_display = character(),
    n_events = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    endpoint_definition_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_person_time <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    analysis_window = character(),
    landmark_days = integer(),
    n_people_display = character(),
    n_people = numeric(),
    person_years_display = character(),
    person_years = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_rates <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    analysis_window = character(),
    infection_endpoint_id = character(),
    infection_endpoint_label = character(),
    event_count_display = character(),
    n_events = numeric(),
    person_years_display = character(),
    person_years = numeric(),
    rate_per_100py = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_burden_strata_counts <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    analysis_window = character(),
    infection_endpoint_id = character(),
    infection_endpoint_label = character(),
    burden_stratum = character(),
    landmark_days = integer(),
    n_people_display = character(),
    n_people = numeric(),
    n_progression_display = character(),
    n_progression = numeric(),
    n_competing_death_display = character(),
    n_competing_death = numeric(),
    person_years_display = character(),
    person_years = numeric(),
    progression_rate_per_100py = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    immortal_time_handling_note = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_landmark_progression_signal <- function() {
  empty_df(
    cohort_id = character(),
    cohort_label = character(),
    analysis_window = character(),
    landmark_days = integer(),
    infection_burden_definition = character(),
    burden_stratum = character(),
    horizon_years = numeric(),
    n_at_landmark_display = character(),
    n_at_landmark = numeric(),
    progression_events_display = character(),
    progression_events = numeric(),
    competing_deaths_display = character(),
    competing_deaths = numeric(),
    person_years_display = character(),
    person_years = numeric(),
    progression_rate_per_100py = numeric(),
    endpoint_definition_status = character(),
    acceptance_status = character(),
    query_status = character(),
    suppression_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_atypical_readiness <- function() {
  empty_df(
    category_id = character(),
    category_label = character(),
    definition_status = character(),
    route_status = character(),
    acceptance_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_bias_warnings <- function() {
  empty_df(
    bias_id = character(),
    bias_label = character(),
    tracker_implication = character(),
    mitigation = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_estimands <- function() {
  empty_df(
    estimand_id = character(),
    title = character(),
    primary_view = character(),
    exposure_window = character(),
    outcome = character(),
    competing_event = character(),
    interpretation_limit = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_protocol_runway <- function() {
  empty_df(
    runway_id = character(),
    workstream = character(),
    status = character(),
    owner_role = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_source_resolution_audit <- function() {
  empty_df(
    route_id = character(),
    configured = logical(),
    query_executed = logical(),
    query_success = logical(),
    query_status = character(),
    source_table = character(),
    error_message_sanitized = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_production_query_review <- function() {
  empty_df(
    query_id = character(),
    query_label = character(),
    query_executable = logical(),
    query_status = character(),
    acceptance_status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_failed_query_audit <- function() {
  empty_df(
    query_id = character(),
    artifact = character(),
    count_status = character(),
    mode = character(),
    error_class = character(),
    error_message_sanitized = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_execution_summary <- function() {
  empty_df(
    metric = character(),
    label = character(),
    value = character(),
    status = character(),
    notes = character()
  )
}

smm_immunity_tracker_empty_payload <- function() {
  list(
    summary = smm_immunity_tracker_empty_summary(),
    story_cards = smm_immunity_tracker_empty_story_cards(),
    cohort_readiness = smm_immunity_tracker_empty_cohort_readiness(),
    cohort_counts = smm_immunity_tracker_empty_cohort_counts(),
    wp5_source_audit = smm_immunity_tracker_empty_wp5_source_audit(),
    tracker_status = smm_immunity_tracker_empty_tracker_status(),
    endpoint_definitions = smm_immunity_tracker_empty_endpoint_definitions(),
    infection_counts = smm_immunity_tracker_empty_infection_counts(),
    recurrent_infection_counts = smm_immunity_tracker_empty_infection_counts(),
    microbiology_confirmation_counts = smm_immunity_tracker_empty_infection_counts(),
    infection_person_time = smm_immunity_tracker_empty_person_time(),
    infection_rates = smm_immunity_tracker_empty_rates(),
    burden_strata_counts = smm_immunity_tracker_empty_burden_strata_counts(),
    landmark_progression_signal = smm_immunity_tracker_empty_landmark_progression_signal(),
    atypical_prolonged_severe_readiness = smm_immunity_tracker_empty_atypical_readiness(),
    bias_warnings = smm_immunity_tracker_empty_bias_warnings(),
    estimands = smm_immunity_tracker_empty_estimands(),
    protocol_runway = smm_immunity_tracker_empty_protocol_runway(),
    source_resolution_audit = smm_immunity_tracker_empty_source_resolution_audit(),
    production_query_review = smm_immunity_tracker_empty_production_query_review(),
    failed_query_audit = smm_immunity_tracker_empty_failed_query_audit(),
    production_execution_summary = smm_immunity_tracker_empty_execution_summary()
  )
}

smm_immunity_tracker_match_empty <- function(df, empty) {
  if (exists("confluence_match_empty", mode = "function")) {
    return(confluence_match_empty(df, empty))
  }
  if (!is.data.frame(df)) df <- data.frame(stringsAsFactors = FALSE)
  n <- nrow(df)
  for (nm in setdiff(names(empty), names(df))) {
    proto <- empty[[nm]]
    if (is.logical(proto)) {
      df[[nm]] <- rep(FALSE, n)
    } else if (is.integer(proto)) {
      df[[nm]] <- rep(NA_integer_, n)
    } else if (is.numeric(proto)) {
      df[[nm]] <- rep(NA_real_, n)
    } else {
      df[[nm]] <- rep("", n)
    }
  }
  df[names(empty)]
}

smm_immunity_tracker_cohort_readiness <- function() {
  data.frame(
    cohort_id = c(
      "aot_wp5_original_smm",
      "cvm_jama_smm_day90_harmonized",
      "cvm_jama_smm_diagnosis_origin"
    ),
    cohort_label = c(
      "AOT/WP5 original SMM-compatible day-90 cohort",
      "CVM/JAMA clinically filtered SMM cohort, day-90 harmonized",
      "CVM/JAMA clinically filtered SMM cohort, diagnosis-origin reproduction"
    ),
    tracker_role = c("primary comparative view", "primary comparative view", "secondary reproduction/readiness view"),
    time_origin = c(
      "day90_harmonized",
      "day90_harmonized",
      "diagnosis_origin_after_90d_eligibility_restriction"
    ),
    entry_rule = c(
      "first DC900 plus 90 days",
      "first DC900 plus 90 days",
      "first DC900 diagnosis date, conditioned on 90-day eligibility"
    ),
    progression_endpoint = rep("Treatment-defined active MM or AL amyloidosis according to the cohort output contract.", 3),
    competing_event = rep("Death before progression.", 3),
    readiness_status = rep("requires WP5/CVM source outputs or aggregate count hook", 3),
    source_status = rep("fail-closed until source outputs or aggregate counts are supplied", 3),
    notes = c(
      "Broad untreated-through-day-90 SMM-compatible surface. Follow-up begins at the day-90 tracker entry.",
      "Clinical SMM filters are preserved, but the tracker comparison uses the same day-90 time origin as AOT/WP5.",
      "Retained to reproduce the published CVM/JAMA time-origin framing; not the primary cross-cohort infection-burden signal."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_endpoint_definitions <- function() {
  data.frame(
    endpoint_id = c(
      "serious_infection_hospitalization",
      "microbiology_confirmed_infection",
      "recurrent_infection_episode",
      "high_burden_infection",
      "atypical_or_opportunistic_infection",
      "prolonged_or_complicated_infection",
      "severe_infection"
    ),
    endpoint_label = c(
      "Serious infection hospitalization",
      "Microbiology-confirmed infection",
      "Recurrent infection episode",
      "High burden infection",
      "Atypical or opportunistic infection",
      "Prolonged or complicated infection",
      "Severe infection"
    ),
    endpoint_family = c("hospital diagnosis", "microbiology", "derived episode", "derived stratum", "readiness", "readiness", "readiness"),
    definition_status = c(
      "repo-derived provisional",
      "repo-derived provisional",
      "derived from event stream using 14-day same-endpoint gap",
      "derived burden strata",
      "readiness only until validated code lists and source routes exist",
      "readiness only until validated code lists and source routes exist",
      "readiness only until validated code lists and source routes exist"
    ),
    route_status = c(
      "reuse CONFLUENCE infection endpoint code sets where available",
      "reuse CONFLUENCE microbiology confirmation mapping where available",
      "requires serious infection or microbiology event stream",
      "requires infection event stream and landmark window",
      "not accepted as a count in v1 unless validated",
      "not accepted as a count in v1 unless validated",
      "not accepted as a count in v1 unless validated"
    ),
    notes = c(
      "Feasibility endpoint only; final clinical endpoint ownership is required before modelling.",
      "No organism names or result text are emitted.",
      "Episodes are used for aggregate burden counts only.",
      "Default strata are 0, 1, 2-3, and >=4 episodes in a fixed window.",
      "Use only pre-approved aggregate categories; no organism text.",
      "Potential definitions include long admission or repeated linked episodes, but not accepted until routes are locked.",
      "Potential definitions include sepsis or intensive-care routes, but broad diagnosis alone is not enough for severity."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_atypical_readiness <- function() {
  data.frame(
    category_id = c("atypical_or_opportunistic_infection", "prolonged_or_complicated_infection", "severe_infection"),
    category_label = c("Atypical/opportunistic infection", "Prolonged/complicated infection", "Severe infection"),
    definition_status = rep("readiness/provisional only", 3),
    route_status = rep("validated code list and source route required before accepted counts", 3),
    acceptance_status = rep("not accepted aggregate", 3),
    notes = c(
      "Can be shown as available yes/no/readiness only until protocol-owned definitions exist.",
      "Admission duration or episode linkage routes must be validated before counts are accepted.",
      "Severity must not be inferred from broad infection diagnosis alone."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_bias_warnings <- function() {
  data.frame(
    bias_id = c(
      "immortal_time",
      "reverse_causation",
      "surveillance_testing",
      "competing_death",
      "treatment_confounding",
      "cohort_definition_drift",
      "small_cell_suppression",
      "not_causal"
    ),
    bias_label = c(
      "Immortal-time bias",
      "Reverse causation",
      "Surveillance/testing bias",
      "Competing death",
      "Treatment confounding",
      "Cohort-definition drift",
      "Small-cell and complementary suppression",
      "Feasibility signal only"
    ),
    tracker_implication = c(
      "Post-entry infection burden must use landmark or time-updated framing, not simple baseline exposure.",
      "Infection may cluster near occult progression or treatment start.",
      "Infection-prone patients may have more contacts and tests.",
      "Death can prevent observing progression.",
      "Early treatment, steroids, or immune-modulating therapy can change infection risk.",
      "AOT/WP5 and CVM/JAMA define SMM surfaces differently.",
      "Suppressed cells can limit visible strata and rates.",
      "The panel does not establish that infections cause progression."
    ),
    mitigation = c(
      "Use day-90 harmonized tracker entry and 6/12-month landmarks.",
      "Report pre-progression burden as descriptive only.",
      "Separate hospital-coded and microbiology-confirmed routes; note testing intensity.",
      "Report death before progression as competing event.",
      "Keep treatment-readiness and early treatment as protocol-hardening work.",
      "Keep cohorts separate and label the CVM diagnosis-origin reproduction view.",
      "Apply primary and complementary suppression and suppress rates when numerator is hidden.",
      "Use time to progression and cumulative incidence language only."
    ),
    notes = "",
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_estimands <- function() {
  data.frame(
    estimand_id = c("day90_harmonized_burden", "six_month_landmark", "twelve_month_landmark", "pre_progression_descriptive"),
    title = c(
      "Day-90 harmonized infection-burden signal",
      "Post-entry 6-month landmark progression signal",
      "Post-entry 12-month landmark progression signal",
      "Pre-progression descriptive burden"
    ),
    primary_view = c("yes", "yes", "yes", "no"),
    exposure_window = c("pre_diagnosis_365d and diagnosis_to_day90", "post_entry_6m_landmark", "post_entry_12m_landmark", "pre_progression_descriptive"),
    outcome = rep("Time to treatment-defined progression to active MM or AL amyloidosis.", 4),
    competing_event = rep("Death before progression.", 4),
    interpretation_limit = c(
      "Descriptive feasibility signal; needs formal protocol before modelling.",
      "Landmark-only signal; no causal interpretation.",
      "Landmark-only signal; no causal interpretation.",
      "Descriptive clustering only, not a predictor estimate."
    ),
    notes = "",
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_protocol_runway <- function() {
  data.frame(
    runway_id = c(
      "cohort_source_lock",
      "endpoint_code_validation",
      "microbiology_route_validation",
      "infection_window_lock",
      "progression_endpoint_lock",
      "competing_risk_plan",
      "surveillance_bias_plan",
      "privacy_review"
    ),
    workstream = c(
      "Lock WP5/CVM cohort source outputs",
      "Validate serious infection endpoint codes",
      "Validate microbiology confirmation routes",
      "Lock infection time windows",
      "Lock treatment-defined progression endpoint",
      "Write competing-risk analysis plan",
      "Mitigate surveillance/testing bias",
      "Review suppression and public output safety"
    ),
    status = rep("required before risk-factor interpretation", 8),
    owner_role = c(
      "WP5/CVM analyst",
      "clinician investigator plus analyst",
      "microbiology/source owner plus analyst",
      "clinician investigator plus analyst",
      "WP5/CVM analyst",
      "statistician",
      "clinician investigator plus statistician",
      "data manager / QA"
    ),
    notes = c(
      "Do not silently reimplement WP5 cohort logic when accepted source outputs exist.",
      "CONFLUENCE prefixes are provisional and need endpoint ownership.",
      "No organism names or result text should appear in static outputs.",
      "Use day-90 harmonized entry for the primary comparison.",
      "Keep AL amyloidosis and treatment-defined progression aligned to cohort contract.",
      "Death before progression is a competing event, not missing follow-up.",
      "Testing intensity may explain apparent infection differences.",
      "Primary and complementary suppression are both required."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_scaffold_summary <- function() {
  data.frame(
    metric = c("panel_status", "primary_time_origin", "raw_patient_rows_emitted", "causal_claim_status", "production_aggregate_status"),
    label = c("Panel status", "Primary time origin", "Raw row output", "Causal claim status", "Production aggregate status"),
    value = c("readiness scaffold", "day90_harmonized", "0", "not causal", "not run"),
    status = c("feasibility", "required", "privacy-safe", "blocked from causal interpretation", "fail-closed"),
    count_kind = c("scaffold", "analysis design", "public output audit", "interpretation guardrail", "aggregate execution"),
    evidence_confidence = c("source-readiness", "protocol amendment applied", "privacy boundary", "descriptive feasibility only", "query executable not run"),
    notes = c(
      "SMM Immunity Tracker renders without production data and fails closed until aggregate sources are supplied.",
      "AOT/WP5 and CVM/JAMA primary comparison uses first DC900 plus 90 days.",
      "Static outputs must be aggregate-only.",
      "Feasibility signal only. Infection burden may mark immune vulnerability, occult progression, surveillance intensity, frailty, or treatment-readiness differences.",
      "Use the aggregate-only adapter hook or WP5 outputs plus secure event routes for accepted counts."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_status_rows <- function(cohort_denominators = "unavailable",
                                             cvm_aggregate_route = "pending",
                                             infection_routes = "unavailable",
                                             microbiology_routes = "unavailable",
                                             person_time_routes = "unavailable",
                                             progression_signal = "unavailable",
                                             tracker_status = "partial",
                                             production_aggregate_status = "partial: cohort counts unavailable; CVM aggregate route pending; infection routes unavailable") {
  data.frame(
    status_key = c(
      "wp5_cohort_denominators",
      "cvm_aggregate_route",
      "infection_routes",
      "microbiology_routes",
      "person_time_routes",
      "progression_signal",
      "tracker_status",
      "production_aggregate_status"
    ),
    status_value = c(
      cohort_denominators,
      cvm_aggregate_route,
      infection_routes,
      microbiology_routes,
      person_time_routes,
      progression_signal,
      tracker_status,
      production_aggregate_status
    ),
    status_label = c(
      "AOT/WP5 cohort denominators",
      "CVM/JAMA aggregate route",
      "Hospital-coded infection routes",
      "Microbiology routes",
      "Person-time routes",
      "Progression-by-infection signal",
      "Tracker-wide status",
      "Production aggregate status"
    ),
    caveat = c(
      "Accepted only when populated from public WP5 aggregate files.",
      "CVM/JAMA counts require a separate accepted aggregate source.",
      "Unavailable until secure aggregate infection-event routes are configured.",
      "Unavailable until secure aggregate microbiology routes are configured.",
      "Unavailable until secure aggregate person-time routes are configured.",
      "Unavailable until secure infection-burden and progression aggregate routes are configured.",
      "Partial means cohort denominators may be available while infection routes remain unavailable.",
      "Empty infection outputs mean unavailable/not run, never true zero."
    ),
    stringsAsFactors = FALSE
  )
}

smm_immunity_tracker_attach_story_layer <- function(outputs) {
  if (is.null(outputs)) outputs <- smm_immunity_tracker_empty_payload()
  counts <- outputs$cohort_counts %||% smm_immunity_tracker_empty_cohort_counts()
  accepted_counts <- if (is.data.frame(counts) && nrow(counts) && "acceptance_status" %in% names(counts)) {
    sum(counts$acceptance_status == "accepted", na.rm = TRUE)
  } else {
    0L
  }
  outputs$story_cards <- data.frame(
    card_id = c("purpose", "day90_harmonized", "infection_windows", "privacy_boundary", "protocol_hardening"),
    title = c("Purpose", "Primary comparison", "Timing windows", "Privacy boundary", "Protocol hardening"),
    status = c(
      "feasibility only",
      "day-90 harmonized",
      "landmark required",
      "aggregate only",
      if (accepted_counts > 0L) "aggregate rows available" else "source validation required"
    ),
    tone = c("cyan", "green", "amber", "green", if (accepted_counts > 0L) "green" else "amber"),
    body = c(
      "Ask whether immune vulnerability after SMM recognition is measurable before progression.",
      if (accepted_counts > 0L) {
        "AOT/WP5 cohort denominators available; CVM aggregate route pending; infection routes unavailable."
      } else {
        "AOT/WP5 cohort denominators unavailable; CVM aggregate route pending; infection routes unavailable."
      },
      "Use pre-diagnosis, diagnosis-to-day-90, and 6/12-month landmark windows; pre-progression burden is descriptive only.",
      "No row-level records, identifiers, raw dates, organism names, microbiology text, pathology text, or free text are written.",
      "Endpoint codes, microbiology routes, cohort source lock, competing-risk plan, and suppression review are required before interpretation."
    ),
    notes = "",
    stringsAsFactors = FALSE
  )
  outputs
}

build_smm_immunity_tracker_feasibility_outputs <- function(project_root = ".",
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
                                                           min_cell_count = atlas_min_cell_count(),
                                                           ...) {
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  empty <- smm_immunity_tracker_empty_payload()
  outputs <- empty
  outputs$summary <- smm_immunity_tracker_scaffold_summary()
  outputs$cohort_readiness <- smm_immunity_tracker_cohort_readiness()
  outputs$tracker_status <- smm_immunity_tracker_status_rows(
    tracker_status = "partial",
    production_aggregate_status = "partial: cohort counts unavailable; CVM aggregate route pending; infection routes unavailable"
  )
  outputs$endpoint_definitions <- smm_immunity_tracker_endpoint_definitions()
  outputs$atypical_prolonged_severe_readiness <- smm_immunity_tracker_atypical_readiness()
  outputs$bias_warnings <- smm_immunity_tracker_bias_warnings()
  outputs$estimands <- smm_immunity_tracker_estimands()
  outputs$protocol_runway <- smm_immunity_tracker_protocol_runway()
  outputs$production_query_review <- data.frame(
    query_id = c("smm_immunity_tracker_counts", "wp5_source_outputs", "infection_event_routes"),
    query_label = c("Aggregate SMM tracker counts", "WP5/CVM cohort source outputs", "Serious infection and microbiology event routes"),
    query_executable = c(FALSE, FALSE, FALSE),
    query_status = rep("query executable not run", 3),
    acceptance_status = rep("not accepted aggregate", 3),
    notes = c(
      "Use aggregate-only db_adapter$smm_immunity_tracker_counts() for production outputs.",
      "Set SMM_IMMUNITY_WP5_OUTPUT_ROOT or WOMMEN_WP5_OUTPUT_ROOT inside the secure environment.",
      "Reuse CONFLUENCE infection route concepts only after source routes are available."
    ),
    stringsAsFactors = FALSE
  )
  outputs$failed_query_audit <- data.frame(
    query_id = "smm_immunity_tracker_production_aggregate",
    artifact = "smm_immunity_tracker_production_execution_summary.csv",
    count_status = "query executable not run",
    mode = "plan",
    error_class = "",
    error_message_sanitized = "SMM Immunity Tracker production aggregate mode was not run.",
    notes = "Fail-closed scaffold; no accepted counts are emitted in plan mode.",
    stringsAsFactors = FALSE
  )
  outputs$production_execution_summary <- data.frame(
    metric = c("count_mode", "production_query_attempted", "production_query_success", "min_cell_count"),
    label = c("Count mode", "Production query attempted", "Production query success", "Small-cell threshold"),
    value = c("plan", "FALSE", "FALSE", as.character(min_cell_count)),
    status = c("plan", "not run", "fail-closed", "privacy threshold"),
    notes = c(
      "Scaffold/readiness mode only.",
      "No aggregate adapter hook was executed.",
      "No accepted production counts are available.",
      "Primary and complementary suppression use this threshold."
    ),
    stringsAsFactors = FALSE
  )
  smm_immunity_tracker_attach_story_layer(outputs)
}

smm_immunity_tracker_write_outputs <- function(outputs, output_dir) {
  if (is.null(outputs)) outputs <- smm_immunity_tracker_empty_payload()
  outputs <- smm_immunity_tracker_attach_story_layer(outputs)
  list(
    summary = write_csv(outputs$summary %||% smm_immunity_tracker_empty_summary(), file.path(output_dir, "smm_immunity_tracker_summary.csv")),
    story_cards = write_csv(outputs$story_cards %||% smm_immunity_tracker_empty_story_cards(), file.path(output_dir, "smm_immunity_tracker_story_cards.csv")),
    cohort_readiness = write_csv(outputs$cohort_readiness %||% smm_immunity_tracker_empty_cohort_readiness(), file.path(output_dir, "smm_immunity_tracker_cohort_readiness.csv")),
    cohort_counts = write_csv(outputs$cohort_counts %||% smm_immunity_tracker_empty_cohort_counts(), file.path(output_dir, "smm_immunity_tracker_cohort_counts.csv")),
    wp5_source_audit = write_csv(outputs$wp5_source_audit %||% smm_immunity_tracker_empty_wp5_source_audit(), file.path(output_dir, "smm_immunity_tracker_wp5_source_audit.csv")),
    tracker_status = write_csv(outputs$tracker_status %||% smm_immunity_tracker_empty_tracker_status(), file.path(output_dir, "smm_immunity_tracker_status.csv")),
    endpoint_definitions = write_csv(outputs$endpoint_definitions %||% smm_immunity_tracker_empty_endpoint_definitions(), file.path(output_dir, "smm_immunity_tracker_endpoint_definitions.csv")),
    infection_counts = write_csv(outputs$infection_counts %||% smm_immunity_tracker_empty_infection_counts(), file.path(output_dir, "smm_immunity_tracker_infection_counts.csv")),
    recurrent_infection_counts = write_csv(outputs$recurrent_infection_counts %||% smm_immunity_tracker_empty_infection_counts(), file.path(output_dir, "smm_immunity_tracker_recurrent_infection_counts.csv")),
    microbiology_confirmation_counts = write_csv(outputs$microbiology_confirmation_counts %||% smm_immunity_tracker_empty_infection_counts(), file.path(output_dir, "smm_immunity_tracker_microbiology_confirmation_counts.csv")),
    infection_person_time = write_csv(outputs$infection_person_time %||% smm_immunity_tracker_empty_person_time(), file.path(output_dir, "smm_immunity_tracker_infection_person_time.csv")),
    infection_rates = write_csv(outputs$infection_rates %||% smm_immunity_tracker_empty_rates(), file.path(output_dir, "smm_immunity_tracker_infection_rates.csv")),
    burden_strata_counts = write_csv(outputs$burden_strata_counts %||% smm_immunity_tracker_empty_burden_strata_counts(), file.path(output_dir, "smm_immunity_tracker_burden_strata_counts.csv")),
    landmark_progression_signal = write_csv(outputs$landmark_progression_signal %||% smm_immunity_tracker_empty_landmark_progression_signal(), file.path(output_dir, "smm_immunity_tracker_landmark_progression_signal.csv")),
    atypical_prolonged_severe_readiness = write_csv(outputs$atypical_prolonged_severe_readiness %||% smm_immunity_tracker_empty_atypical_readiness(), file.path(output_dir, "smm_immunity_tracker_atypical_prolonged_severe_readiness.csv")),
    bias_warnings = write_csv(outputs$bias_warnings %||% smm_immunity_tracker_empty_bias_warnings(), file.path(output_dir, "smm_immunity_tracker_bias_warnings.csv")),
    estimands = write_csv(outputs$estimands %||% smm_immunity_tracker_empty_estimands(), file.path(output_dir, "smm_immunity_tracker_estimands.csv")),
    protocol_runway = write_csv(outputs$protocol_runway %||% smm_immunity_tracker_empty_protocol_runway(), file.path(output_dir, "smm_immunity_tracker_protocol_runway.csv")),
    source_resolution_audit = write_csv(outputs$source_resolution_audit %||% smm_immunity_tracker_empty_source_resolution_audit(), file.path(output_dir, "smm_immunity_tracker_source_resolution_audit.csv")),
    production_query_review = write_csv(outputs$production_query_review %||% smm_immunity_tracker_empty_production_query_review(), file.path(output_dir, "smm_immunity_tracker_production_query_review.csv")),
    failed_query_audit = write_csv(outputs$failed_query_audit %||% smm_immunity_tracker_empty_failed_query_audit(), file.path(output_dir, "smm_immunity_tracker_failed_query_audit.csv")),
    production_execution_summary = write_csv(outputs$production_execution_summary %||% smm_immunity_tracker_empty_execution_summary(), file.path(output_dir, "smm_immunity_tracker_production_execution_summary.csv"))
  )
}
