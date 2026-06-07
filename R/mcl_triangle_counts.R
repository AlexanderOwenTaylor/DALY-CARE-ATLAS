mcl_count_status_levels <- function() {
  c(
    "query_executable_not_run",
    "production_aggregate_count_available",
    "production_aggregate_failed_credentials_unavailable",
    "production_aggregate_failed_mapping_unavailable",
    "production_aggregate_failed_query_error",
    "count_available_zero_requires_value_mapping_review",
    "count_available",
    "count_available_timing_not_validated",
    "count_not_available_requires_patient_demographics_mapping",
    "count_not_available_requires_person_key_mapping",
    "count_not_available_requires_date_mapping",
    "count_not_available_requires_value_mapping",
    "count_not_available_requires_dedicated_intersection_query",
    "count_not_available_requires_production_validation",
    "suppressed_small_cell",
    "not_applicable"
  )
}

mcl_count_timing_scopes <- function() {
  c("ever_available", "near_diagnosis", "first_line_window", "pre_landmark", "post_landmark", "follow_up_outcome")
}

mcl_count_empty_person_key_audit <- function() {
  empty_df(
    source = character(),
    table = character(),
    candidate_person_id_columns = character(),
    selected_person_id_column = character(),
    confidence = character(),
    usable_for_distinct_person_counts = logical(),
    notes = character()
  )
}

mcl_count_empty_data_point_counts <- function() {
  empty_df(
    data_point_id = character(),
    clinical_label = character(),
    denominator = character(),
    timing_scope = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    denominator_count_display = character(),
    count_source = character(),
    person_key_confidence = character(),
    timing_validation_status = character(),
    source_locations = character(),
    notes = character(),
    query_attempted = logical(),
    query_executed = logical(),
    query_success = logical(),
    error_class = character(),
    error_message_sanitized = character(),
    count_mode = character(),
    source_tables = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    value_rule_used = character(),
    generated_at = character(),
    validation_status = character()
  )
}

mcl_count_empty_inclusion_waterfall <- function() {
  empty_df(
    step_order = integer(),
    step_id = character(),
    step_label = character(),
    denominator = character(),
    timing_scope = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_start_display = character(),
    cumulative_rule = character(),
    notes = character()
  )
}

mcl_count_empty_overlap_matrix <- function() {
  empty_df(
    denominator = character(),
    row_data_point_id = character(),
    column_data_point_id = character(),
    timing_scope = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    notes = character()
  )
}

mcl_count_empty_exposure_strata_counts <- function() {
  empty_df(
    denominator = character(),
    asct_hdt_first_line_status = character(),
    ibrutinib_status = character(),
    timing_scope = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    notes = character()
  )
}

mcl_count_empty_landmark_counts <- function() {
  empty_df(
    landmark_id = character(),
    landmark_label = character(),
    requirement = character(),
    denominator = character(),
    timing_scope = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_person_summary <- function() {
  empty_df(
    denominator = character(),
    timing_window = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    valid_aeki_code_count = character(),
    unique_percent_values_observed = character(),
    source_locations = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_atlas_ki67_source_inventory <- function() {
  empty_df(
    source_channel = character(),
    atlas_source_name = character(),
    atlas_table_name = character(),
    canonical_resource_id = character(),
    db_name = character(),
    schema = character(),
    table_or_view = character(),
    display_table_name = character(),
    column_name = character(),
    column_role = character(),
    has_patientid = logical(),
    has_text = logical(),
    has_code = logical(),
    has_join_keys_to_pato = logical(),
    same_db_as_lyfo = logical(),
    current_profiled = logical(),
    current_n_rows = character(),
    current_n_columns = character(),
    atlas_evidence_file = character(),
    evidence_state = character(),
    countability_status = character(),
    recommended_probe_action = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_source_validation <- function() {
  empty_df(
    source_channel = character(),
    db_name = character(),
    schema = character(),
    table_or_view = character(),
    column_name = character(),
    validation_query_attempted = logical(),
    validation_query_success = logical(),
    validation_status = character(),
    selected_for_numeric_union = logical(),
    error_message_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_aeki_code_counts <- function() {
  empty_df(
    db_name = character(),
    schema = character(),
    table_or_view = character(),
    code_column = character(),
    normalized_code = character(),
    parsed_percent = integer(),
    pathology_code_rows_display = character(),
    mcl_distinct_people_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_aeki_person_counts <- function() {
  empty_df(
    denominator = character(),
    timing_window = character(),
    metric = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_percent_distribution <- function() {
  empty_df(
    denominator = character(),
    parsed_percent = integer(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_threshold_counts <- function() {
  empty_df(
    denominator = character(),
    threshold_percent = integer(),
    metric = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_text_bridge_validation <- function() {
  empty_df(
    text_source = character(),
    schema = character(),
    table_or_view = character(),
    text_column = character(),
    join_key_columns = character(),
    text_rows_total = character(),
    text_rows_with_non_missing_text = character(),
    text_rows_linked_to_sds_pato = character(),
    text_rows_linked_to_patientid = character(),
    mcl_linked_text_hit_people = character(),
    query_attempted = logical(),
    query_success = logical(),
    bridge_status = character(),
    validation_status = character(),
    error_message_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_text_pattern_counts <- function() {
  empty_df(
    source_channel = character(),
    schema = character(),
    table_or_view = character(),
    text_column = character(),
    pattern_name = character(),
    value_class = character(),
    aggregate_count_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_text_person_counts <- function() {
  empty_df(
    denominator = character(),
    source_channel = character(),
    metric = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_union_counts <- function() {
  empty_df(
    denominator = character(),
    union_channel = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ki67_overlap_by_source <- function() {
  empty_df(
    source_channel_a = character(),
    source_channel_b = character(),
    denominator = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_age_proxy_counts <- function() {
  empty_df(
    metric = character(),
    denominator = character(),
    timing_window = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    source_locations = character(),
    value_rule_used = character(),
    validation_status = character(),
    notes = character()
  )
}

mcl_count_empty_ibrutinib_exposure_counts <- function() {
  empty_df(
    denominator = character(),
    timing_window = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    source_locations = character(),
    value_rule_used = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_treatment_strategy_strata_counts <- function() {
  empty_df(
    denominator = character(),
    timing_window = character(),
    ibrutinib_status = character(),
    asct_hdt_first_line_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    count_status = character(),
    validation_status = character(),
    notes = character()
  )
}

mcl_count_empty_high_risk_biology_counts <- function() {
  empty_df(
    denominator = character(),
    biology_component = character(),
    timing_window = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    value_rule_used = character(),
    source_locations = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_answerability_intersections <- function() {
  empty_df(
    intersection_id = character(),
    denominator = character(),
    required_data_points = character(),
    timing_window = character(),
    distinct_person_count_display = character(),
    count_status = character(),
    small_cell_suppressed = logical(),
    interpretation = character(),
    answerability_impact = character(),
    notes = character()
  )
}

mcl_count_empty_answerability_summary <- function() {
  empty_df(
    row_id = character(),
    status = character(),
    distinct_person_count_display = character(),
    limiting_factor = character(),
    interpretation = character(),
    recommended_next_step = character(),
    notes = character()
  )
}

mcl_count_empty_summary <- function() {
  empty_df(
    metric = character(),
    label = character(),
    value = character(),
    status = character(),
    notes = character()
  )
}

mcl_count_empty_patient_demographics_resolver <- function() {
  empty_df(
    database_name = character(),
    search_path = character(),
    verified_at = character(),
    verification_mode = character(),
    db_name = character(),
    source_db_name = character(),
    lyfo_db_name = character(),
    same_db_as_lyfo = logical(),
    cross_db_join_required = logical(),
    cross_db_join_available = logical(),
    schema = character(),
    table = character(),
    has_patientid = logical(),
    has_date_birth = logical(),
    has_date_death_fu = logical(),
    candidate_score = integer(),
    selected = logical(),
    reason = character(),
    usable_for_age_counts = logical(),
    relation_probe_attempted = logical(),
    relation_probe_success = logical(),
    relation_probe_error_sanitized = character(),
    column_probe_attempted = logical(),
    column_probe_success = logical(),
    column_probe_error_sanitized = character(),
    co_residency_probe_attempted = logical(),
    co_residency_probe_success = logical(),
    co_residency_probe_error_sanitized = character(),
    deterministic_tie_break_requires_review = logical(),
    post_selection_execution_attempted = logical(),
    post_selection_execution_success = logical(),
    post_selection_execution_error_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_age_source_locator <- function() {
  empty_df(
    database_name = character(),
    search_path = character(),
    verified_at = character(),
    verification_mode = character(),
    source_type = character(),
    db_name = character(),
    source_db_name = character(),
    lyfo_db_name = character(),
    same_db_as_lyfo = logical(),
    cross_db_join_required = logical(),
    cross_db_join_available = logical(),
    schema = character(),
    table = character(),
    patientid_column = character(),
    birth_date_column = character(),
    age_column = character(),
    age_semantics = character(),
    has_patientid = logical(),
    has_birth_date_like = logical(),
    has_age_like = logical(),
    has_mcl_subtype = logical(),
    numeric_age_plausible = logical(),
    candidate_score = integer(),
    selected = logical(),
    reason = character(),
    usable_for_age_counts = logical(),
    relation_probe_attempted = logical(),
    relation_probe_success = logical(),
    relation_probe_error_sanitized = character(),
    column_probe_attempted = logical(),
    column_probe_success = logical(),
    column_probe_error_sanitized = character(),
    co_residency_probe_attempted = logical(),
    co_residency_probe_success = logical(),
    co_residency_probe_error_sanitized = character(),
    numeric_probe_attempted = logical(),
    numeric_probe_success = logical(),
    numeric_probe_error_sanitized = character(),
    deterministic_tie_break_requires_review = logical(),
    post_selection_execution_attempted = logical(),
    post_selection_execution_success = logical(),
    post_selection_execution_error_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_atlas_age_source_inventory <- function() {
  empty_df(
    db_name = character(),
    schema = character(),
    table = character(),
    column_name = character(),
    data_type = character(),
    source_role = character(),
    is_patient_key = logical(),
    is_birth_date_like = logical(),
    is_age_like = logical(),
    is_age_anchor_like = logical(),
    atlas_file = character(),
    evidence_status = character(),
    notes = character()
  )
}

mcl_count_empty_age_source_validation <- function() {
  empty_df(
    validation_id = character(),
    source_type = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    patientid_column = character(),
    birth_date_column = character(),
    anchor_order = character(),
    mcl_people = integer(),
    people_with_birth_date = integer(),
    people_with_age_anchor = integer(),
    people_with_plausible_age = integer(),
    people_with_multiple_birth_dates = integer(),
    age_le_65_people = integer(),
    age_gt_65_people = integer(),
    age_missing_or_uncomputable_people = integer(),
    query_attempted = logical(),
    query_success = logical(),
    validation_status = character(),
    selected_for_age_counts = logical(),
    error_message_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_atlas_treatment_source_inventory <- function() {
  empty_df(
    source_id = character(),
    canonical_source_id = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    field = character(),
    code_system = character(),
    code = character(),
    code_name = character(),
    atlas_file = character(),
    atlas_rows = character(),
    atlas_patients = character(),
    candidate_role = character(),
    evidence_status = character(),
    counting_status = character(),
    notes = character()
  )
}

mcl_count_empty_ibrutinib_source_validation <- function() {
  empty_df(
    source_id = character(),
    canonical_source_id = character(),
    source_role = character(),
    include_in_primary_union = logical(),
    db_name = character(),
    schema = character(),
    table = character(),
    person_key_column = character(),
    code_column = character(),
    code_system = character(),
    code_value = character(),
    date_columns = character(),
    bridge_table = character(),
    bridge_source_key_column = character(),
    bridge_key_column = character(),
    bridge_person_key_column = character(),
    relation_probe_attempted = logical(),
    relation_probe_success = logical(),
    relation_probe_error_sanitized = character(),
    column_probe_attempted = logical(),
    column_probe_success = logical(),
    column_probe_error_sanitized = character(),
    bridge_probe_attempted = logical(),
    bridge_probe_success = logical(),
    bridge_probe_error_sanitized = character(),
    co_residency_probe_attempted = logical(),
    co_residency_probe_success = logical(),
    co_residency_probe_error_sanitized = character(),
    validation_query_attempted = logical(),
    validation_query_success = logical(),
    source_code_rows = integer(),
    source_distinct_people = integer(),
    mcl_exposed_people = integer(),
    date_available_people = integer(),
    selected_for_union = logical(),
    validation_status = character(),
    error_message_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_ibrutinib_source_counts <- function() {
  empty_df(
    source_id = character(),
    source_role = character(),
    code_system = character(),
    code_value = character(),
    count_status = character(),
    source_code_rows_display = character(),
    source_distinct_people_display = character(),
    mcl_exposed_people_display = character(),
    date_available_people_display = character(),
    selected_for_union = logical(),
    validation_status = character(),
    notes = character()
  )
}

mcl_count_empty_ibrutinib_union_counts <- function() {
  empty_df(
    denominator = character(),
    timing_window = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validated_primary_sources = character(),
    auxiliary_sources = character(),
    validation_status = character(),
    count_status = character(),
    notes = character()
  )
}

mcl_count_empty_ibrutinib_overlap_by_source <- function() {
  empty_df(
    source_id_a = character(),
    source_id_b = character(),
    denominator = character(),
    timing_window = character(),
    count_status = character(),
    distinct_person_count_display = character(),
    percent_of_denominator_display = character(),
    validation_status = character(),
    notes = character()
  )
}

mcl_count_empty_output_generation_status <- function() {
  empty_df(
    output_file = character(),
    generated_after_latest_mapping_change = logical(),
    mode = character(),
    stale = logical(),
    notes = character()
  )
}

mcl_count_empty_atlas_input_audit <- function() {
  empty_df(
    atlas_output_zip = character(),
    atlas_output_dir = character(),
    atlas_input_supplied = logical(),
    selected_atlas_run = character(),
    selected_outputs_dir = character(),
    atlas_sources_rows = integer(),
    atlas_columns_rows = integer(),
    atlas_source_resolution_rows = integer(),
    canonical_resource_reconciliation_rows = integer(),
    selection_reason = character(),
    notes = character()
  )
}

mcl_count_empty_failed_query_audit <- function() {
  empty_df(
    component = character(),
    output_file = character(),
    query_id = character(),
    output_area = character(),
    count_status = character(),
    validation_status = character(),
    query_attempted = logical(),
    query_success = logical(),
    error_message_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_outputs <- function() {
  list(
    definitions = mcl_count_default_definitions(),
    query_templates = character(),
    person_key_audit = mcl_count_empty_person_key_audit(),
    data_point_counts = mcl_count_empty_data_point_counts(),
    inclusion_waterfall = mcl_count_empty_inclusion_waterfall(),
    overlap_matrix = mcl_count_empty_overlap_matrix(),
    exposure_strata_counts = mcl_count_empty_exposure_strata_counts(),
    landmark_feasibility_counts = mcl_count_empty_landmark_counts(),
    ki67_person_count_summary = mcl_count_empty_ki67_person_summary(),
    atlas_ki67_source_inventory = mcl_count_empty_atlas_ki67_source_inventory(),
    ki67_source_validation = mcl_count_empty_ki67_source_validation(),
    ki67_aeki_code_counts = mcl_count_empty_ki67_aeki_code_counts(),
    ki67_aeki_person_counts = mcl_count_empty_ki67_aeki_person_counts(),
    ki67_percent_distribution = mcl_count_empty_ki67_percent_distribution(),
    ki67_threshold_counts = mcl_count_empty_ki67_threshold_counts(),
    ki67_text_bridge_validation = mcl_count_empty_ki67_text_bridge_validation(),
    ki67_text_pattern_counts = mcl_count_empty_ki67_text_pattern_counts(),
    ki67_text_person_counts = mcl_count_empty_ki67_text_person_counts(),
    ki67_union_counts = mcl_count_empty_ki67_union_counts(),
    ki67_overlap_by_source = mcl_count_empty_ki67_overlap_by_source(),
    age_proxy_counts = mcl_count_empty_age_proxy_counts(),
    ibrutinib_exposure_counts = mcl_count_empty_ibrutinib_exposure_counts(),
    treatment_strategy_strata_counts = mcl_count_empty_treatment_strategy_strata_counts(),
    high_risk_biology_counts = mcl_count_empty_high_risk_biology_counts(),
    answerability_intersections = mcl_count_empty_answerability_intersections(),
    answerability_summary = mcl_count_empty_answerability_summary(),
    count_summary = mcl_count_empty_summary(),
    patient_demographics_resolver = mcl_count_empty_patient_demographics_resolver(),
    age_source_locator = mcl_count_empty_age_source_locator(),
    atlas_age_source_inventory = mcl_count_empty_atlas_age_source_inventory(),
    age_source_validation = mcl_count_empty_age_source_validation(),
    atlas_treatment_source_inventory = mcl_count_empty_atlas_treatment_source_inventory(),
    ibrutinib_source_validation = mcl_count_empty_ibrutinib_source_validation(),
    ibrutinib_source_counts = mcl_count_empty_ibrutinib_source_counts(),
    ibrutinib_union_counts = mcl_count_empty_ibrutinib_union_counts(),
    ibrutinib_overlap_by_source = mcl_count_empty_ibrutinib_overlap_by_source(),
    atlas_input_audit = mcl_count_empty_atlas_input_audit(),
    failed_query_audit = mcl_count_empty_failed_query_audit(),
    execution_summary = mcl_count_empty_execution_summary(),
    output_generation_status = mcl_count_empty_output_generation_status()
  )
}

mcl_count_match_empty <- function(df, empty) {
  if (!is.data.frame(df)) df <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(empty)) return(df)
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

mcl_count_default_definitions <- function() {
  data.frame(
    data_point_id = c(
      "all_lyfo_mcl",
      "younger_mcl_proxy_age_le_65",
      "diagnosis_date",
      "first_line_treatment_date",
      "cit_immunochemotherapy",
      "asct_hdt_first_line",
      "asct_hdt_relapse_recurrence",
      "ibrutinib_exposure",
      "os_death",
      "relapse_progression_ffs_proxy",
      "ki67_aeki",
      "tp53_p53_del17p",
      "blastoid_pleomorphic_morphology",
      "mipi_mipic_components",
      "toxicity_proxies",
      "alive_at_landmark",
      "event_free_pre_landmark",
      "asct_hdt_status_known_landmark",
      "ibrutinib_status_known_landmark",
      "high_risk_biology_pre_landmark"
    ),
    clinical_label = c(
      "MCL cohort",
      "Younger/transplant-eligible proxy MCL, age <=65",
      "Diagnosis date",
      "First-line treatment date",
      "CIT / immunochemotherapy",
      "First-line ASCT/HDT",
      "Relapse/recurrence ASCT/HDT",
      "Ibrutinib exposure",
      "OS/death",
      "Relapse/progression/FFS proxy",
      "Ki-67 AEKI numeric pathology code",
      "TP53 / p53 / del17p",
      "Blastoid/pleomorphic morphology",
      "MIPI / MIPI-c components",
      "Toxicity proxies",
      "Alive at landmark",
      "No event before landmark",
      "ASCT/HDT status known at/after landmark",
      "Ibrutinib status known at/after landmark",
      "High-risk biology known before landmark"
    ),
    denominator = c(
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "all_lyfo_mcl",
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65"
    ),
    required_sources = c(
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO; medication/code sources",
      "patient/death/follow-up sources",
      "RKKP_LYFO; treatment-line/follow-up sources",
      "SDS_pato; SDS_dimpatologiskdiagnose",
      "pathology/FISH/molecular/RKKP fields",
      "LYFO histology; PATOBANK; t_mikro; t_konk",
      "RKKP_LYFO; lab fields; Ki-67",
      "ADT/microbiology/medication/transfusion sources",
      "RKKP_LYFO; death/follow-up sources",
      "RKKP_LYFO; relapse/progression sources",
      "RKKP_LYFO Beh_* fields",
      "RKKP_LYFO; medication/code sources",
      "Ki-67; TP53; morphology; MIPI inputs"
    ),
    person_id_strategy = "configured_source_person_key_required",
    date_anchor = c(
      "diagnosis_date",
      "birth_date_or_age_at_diagnosis",
      "diagnosis_date",
      "first_line_treatment_start",
      "first_line_treatment_start",
      "first_line_treatment_start_or_stem_cell_infusion",
      "recurrence_or_relapse_treatment_window",
      "drug_exposure_start",
      "death_or_follow_up_date",
      "relapse_progression_or_next_treatment_date",
      "pathology_sample_date",
      "pathology_or_molecular_test_date",
      "diagnosis_pathology_date",
      "diagnosis_and_first_line_dates",
      "toxicity_event_date",
      "landmark_after_first_line_start",
      "landmark_after_first_line_start",
      "landmark_after_first_line_start",
      "landmark_after_first_line_start",
      "landmark_after_first_line_start"
    ),
    valid_time_window = c(
      "ever_available",
      "near_diagnosis",
      "near_diagnosis",
      "first_line_window",
      "first_line_window",
      "first_line_window",
      "follow_up_outcome",
      "first_line_window",
      "follow_up_outcome",
      "follow_up_outcome",
      "diagnosis_minus_180_to_plus_90_days; diagnosis_plus_minus_90_days; before_first_line_if_available",
      "near_diagnosis",
      "near_diagnosis",
      "near_diagnosis",
      "follow_up_outcome",
      "pre_landmark",
      "pre_landmark",
      "post_landmark",
      "post_landmark",
      "pre_landmark"
    ),
    valid_value_rule = c(
      "LYFO subtype/histology indicates mantle cell lymphoma",
      "age <=65 at diagnosis if age/date fields are mapped",
      "non-missing valid diagnosis date",
      "non-missing valid first-line treatment date",
      "LYFO regimen or treatment fields indicate CIT/immunochemotherapy",
      "Beh_Hoejdosisbehandling yes or Beh_TypeAutologStamcellestoette autolog or Beh_Stamcelleinfusion_dt valid",
      "Rec_Hoejdosisbehandling yes or Rec_Stamcelleinfusion_dt valid; not first-line ASCT/HDT",
      "validated ibrutinib/BTK exposure field or code",
      "death date/status or follow-up survival evidence",
      "relapse/progression/next-treatment/response proxy",
      "valid AEKI000-AEKI100 numeric code; no row-level pathology text",
      "validated TP53/p53/del17p field/code/text-derived aggregate",
      "validated blastoid or pleomorphic morphology field/code/text-derived aggregate",
      "age, performance/ECOG, LDH, leukocytes, Ki-67 where available",
      "aggregate toxicity proxy field/code/event source",
      "alive at configured landmark",
      "no event before configured landmark if event proxy mapped",
      "ASCT/HDT status known at or after landmark",
      "ibrutinib status known at or after landmark",
      "high-risk biology known before landmark"
    ),
    source_priority = c(
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO",
      "RKKP_LYFO Beh_*",
      "RKKP_LYFO Rec_*",
      "RKKP_LYFO then medication/code sources",
      "patient/death/follow-up sources",
      "RKKP_LYFO",
      "SDS_pato; SDS_dimpatologiskdiagnose",
      "pathology/FISH/molecular",
      "LYFO histology then PATOBANK",
      "RKKP_LYFO/labs/Ki-67",
      "ADT/microbiology/medication/transfusion",
      "death/follow-up sources",
      "relapse/progression sources",
      "RKKP_LYFO Beh_*",
      "RKKP_LYFO/medication/code sources",
      "validated biology sources"
    ),
    fallback_sources = c(
      "", "", "", "", "SDS procedures/medication validation only", "SDS/LPR transplant procedure validation only",
      "", "ATC/SKS/medication validation only", "", "", "pathology text validation", "pathology text validation",
      "pathology text validation", "reconstructed MIPI/MIPI-c inputs", "", "", "", "", "", ""
    ),
    validation_status = "requires_production_aggregate_validation",
    notes = c(
      "Primary feasibility denominator.",
      "Younger proxy only; not equivalent to transplant eligibility.",
      "Needed for timing windows.",
      "Needed for first-line and landmark timing.",
      "Count only when person key and treatment fields are mapped.",
      "First-line ASCT/HDT must use LYFO Beh_* fields first.",
      "Relapse/recurrence transplant evidence; keep separate from first-line ASCT/HDT.",
      "Descriptive exposure availability only.",
      "Outcome availability only; not survival analysis.",
      "Proxy availability only; requires clinical validation.",
      "AEKI code counts are distinct-person aggregate counts, not code-row counts.",
      "Requires source-specific validation.",
      "Requires source-specific validation.",
      "MIPI-c requires Ki-67 validation.",
      "Safety/toxicity proxy availability only.",
      "Landmark feasibility only.",
      "Landmark feasibility only.",
      "Landmark feasibility only.",
      "Landmark feasibility only.",
      "Landmark feasibility only."
    ),
    stringsAsFactors = FALSE
  )
}

mcl_count_extra_default_definitions <- function(template) {
  if (!is.data.frame(template) || !nrow(template)) return(template[FALSE, , drop = FALSE])
  make_row <- function(id, label, rule, notes) {
    data.frame(
      data_point_id = id,
      clinical_label = label,
      denominator = "all_lyfo_mcl",
      required_sources = "patient; RKKP_LYFO",
      person_id_strategy = "configured_source_person_key_required",
      date_anchor = "age_anchor_priority",
      valid_time_window = "near_diagnosis",
      valid_value_rule = rule,
      source_priority = "patient; RKKP_LYFO",
      fallback_sources = "",
      validation_status = "requires_production_aggregate_validation",
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  rows <- list(
    make_row("birth_date_available", "Birth date available for age proxy", "patient.date_birth parses as a valid date after joining to LYFO MCL by patientid.", "Aggregate diagnostic only; no birth dates are emitted."),
    make_row("age_anchor_available", "Diagnosis/treatment age anchor available", "First valid date from Reg_DiagnostiskBiopsi_dt, Reg_BehandlingBeslutning_dt, then Beh_KemoterapiStart_dt.", "Aggregate diagnostic only; no dates are emitted."),
    make_row("age_computable", "Age computable at diagnosis/treatment anchor", "Both patient.date_birth and the selected LYFO age anchor parse as valid dates.", "Aggregate diagnostic only; no dates are emitted."),
    make_row("age_gt_65", "MCL age >65 at diagnosis/treatment anchor", "Age at selected LYFO anchor is >=66 years.", "Aggregate diagnostic only; not a treatment eligibility label."),
    make_row("age_missing_uncomputable", "Age missing or uncomputable", "Birth date or selected LYFO age anchor is missing/malformed after guarded parsing.", "Aggregate diagnostic only; invalid dates are counted, not emitted.")
  )
  bind_rows_base(rows)[names(template)]
}

mcl_count_ensure_extra_definitions <- function(defs) {
  extras <- mcl_count_extra_default_definitions(defs)
  missing <- extras[!extras$data_point_id %in% defs$data_point_id, , drop = FALSE]
  if (!nrow(missing)) return(defs)
  before <- match("diagnosis_date", defs$data_point_id)
  if (is.na(before) || before <= 1L) return(bind_rows_base(list(defs, missing)))
  bind_rows_base(list(defs[seq_len(before - 1L), , drop = FALSE], missing, defs[before:nrow(defs), , drop = FALSE]))
}

mcl_count_read_definitions <- function(project_root = ".") {
  path <- file.path(project_root, "clinical_questions", "mcl_triangle_count_definitions.yml")
  defs <- mcl_count_default_definitions()
  if (file.exists(path) && requireNamespace("yaml", quietly = TRUE)) {
    parsed <- tryCatch(yaml::read_yaml(path), error = function(e) NULL)
    if (is.list(parsed) && length(parsed$data_points)) {
      rows <- lapply(parsed$data_points, function(x) {
        data.frame(
          data_point_id = as.character(x$data_point_id %||% ""),
          clinical_label = as.character(x$clinical_label %||% ""),
          denominator = as.character(x$denominator %||% ""),
          required_sources = paste(as.character(x$required_sources %||% ""), collapse = "; "),
          person_id_strategy = as.character(x$person_id_strategy %||% ""),
          date_anchor = as.character(x$date_anchor %||% ""),
          valid_time_window = as.character(x$valid_time_window %||% ""),
          valid_value_rule = as.character(x$valid_value_rule %||% ""),
          source_priority = paste(as.character(x$source_priority %||% ""), collapse = "; "),
          fallback_sources = paste(as.character(x$fallback_sources %||% ""), collapse = "; "),
          validation_status = as.character(x$validation_status %||% ""),
          notes = as.character(x$notes %||% ""),
          stringsAsFactors = FALSE
        )
      })
      parsed_defs <- bind_rows_base(rows)
      if (all(names(defs) %in% names(parsed_defs))) defs <- parsed_defs[names(defs)]
    }
  }
  mcl_count_ensure_extra_definitions(defs)
}

mcl_count_timing_scope <- function(window) {
  value <- tolower(as.character(window %||% ""))
  scopes <- mcl_count_timing_scopes()
  hit <- scopes[vapply(scopes, function(scope) grepl(scope, value, fixed = TRUE), logical(1))]
  if (length(hit)) hit[[1]] else "ever_available"
}

mcl_count_suppress <- function(n, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  if (is.na(n_num)) return(list(display = "", suppressed = FALSE, numeric = NA_real_, status = "count_not_available_requires_production_validation"))
  if (n_num > 0 && n_num < min_cell_count) {
    return(list(display = paste0("<", min_cell_count), suppressed = TRUE, numeric = n_num, status = "suppressed_small_cell"))
  }
  list(display = format(round(n_num), big.mark = ",", scientific = FALSE, trim = TRUE), suppressed = FALSE, numeric = n_num, status = "count_available")
}

mcl_count_production_status <- function(status) {
  if (identical(status, "count_available")) "production_aggregate_count_available" else status
}

mcl_count_percent_display <- function(n, denom, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  denom_num <- suppressWarnings(as.numeric(denom))
  if (is.na(n_num) || is.na(denom_num) || denom_num <= 0) return("")
  if (n_num > 0 && n_num < min_cell_count) return(paste0("<", round(100 * min_cell_count / denom_num, 1), "%"))
  paste0(round(100 * n_num / denom_num, 1), "%")
}

mcl_count_set <- function(sets, id) {
  x <- sets[[id]] %||% character()
  unique(as.character(x[!(is.na(x) | trimws(as.character(x)) == "")]))
}

mcl_count_intersect_sets <- function(sets, ids) {
  ids <- ids[nzchar(ids)]
  if (!length(ids)) return(character())
  current <- mcl_count_set(sets, ids[[1]])
  if (length(ids) == 1L) return(current)
  for (id in ids[-1]) current <- intersect(current, mcl_count_set(sets, id))
  current
}

mcl_count_denominator_ids <- function() {
  c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")
}

mcl_count_source_table <- function(defs) {
  source_for_id <- function(id) {
    if (grepl("ki67", id, ignore.case = TRUE)) return(data.frame(source = "SDS_pato", table = "SDS_pato", stringsAsFactors = FALSE))
    if (grepl("os_death", id, ignore.case = TRUE)) return(data.frame(source = "patient/death", table = "patient_or_death_followup", stringsAsFactors = FALSE))
    data.frame(source = "RKKP_LYFO", table = "RKKP_LYFO", stringsAsFactors = FALSE)
  }
  rows <- lapply(defs$data_point_id, source_for_id)
  out <- bind_rows_base(rows)
  unique(out)
}

mcl_count_column_profiles <- function(outputs_dir = NULL) {
  if (is.null(outputs_dir) || !dir.exists(outputs_dir)) return(data.frame(stringsAsFactors = FALSE))
  path <- file.path(outputs_dir, "atlas_columns.csv")
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  x <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(x) || !nrow(x)) return(data.frame(stringsAsFactors = FALSE))
  if (!"table_name" %in% names(x) || !"column_name" %in% names(x)) return(data.frame(stringsAsFactors = FALSE))
  for (nm in c("column_type", "is_sensitive", "is_date_like", "n_distinct_capped")) {
    if (!nm %in% names(x)) x[[nm]] <- ""
  }
  x
}

mcl_count_physical_tables <- function(table) {
  table <- as.character(table %||% "")
  if (identical(table, "patient_or_death_followup")) {
    return(c("patient", "view_patient_table_os", "view_date_death", "view_true_date_death"))
  }
  table
}

mcl_count_table_columns <- function(column_profiles, table) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(column_profiles[FALSE, , drop = FALSE])
  tables <- mcl_count_physical_tables(table)
  column_profiles[column_profiles$table_name %in% tables, , drop = FALSE]
}

mcl_count_person_key_mapping <- function(column_profiles, table) {
  x <- mcl_count_table_columns(column_profiles, table)
  if (!is.data.frame(x) || !nrow(x)) {
    return(list(candidates = "", selected = "", confidence = "requires_mapping", usable = FALSE, notes = "No aggregate column profile was available for this source."))
  }
  name <- as.character(x$column_name %||% "")
  sensitive <- tolower(as.character(x$is_sensitive %||% "")) %in% c("true", "t", "1", "yes")
  candidate <- grepl("^(patientid|personid|person_id|patient_id|pnr|cpr)$", tolower(name)) |
    (sensitive & grepl("patient|person|pnr|cpr", tolower(name)))
  candidates <- unique(name[candidate & nzchar(name)])
  if (!length(candidates)) {
    return(list(
      candidates = "",
      selected = "",
      confidence = "requires_mapping",
      usable = FALSE,
      notes = "Column profile exists, but no safe person-key column was identified; row counts must not be used as people."
    ))
  }
  selected <- if ("patientid" %in% tolower(candidates)) candidates[match("patientid", tolower(candidates))] else candidates[[1]]
  list(
    candidates = paste(candidates, collapse = "; "),
    selected = selected,
    confidence = "aggregate_column_profile_person_key",
    usable = TRUE,
    notes = "Person-key candidate found in aggregate column profile; production aggregate counts still require validated joins and no identifier export."
  )
}

mcl_count_date_anchor_columns <- function(column_profiles, table, date_anchor = "") {
  x <- mcl_count_table_columns(column_profiles, table)
  if (!is.data.frame(x) || !nrow(x)) return(character())
  cols <- as.character(x$column_name %||% "")
  is_date <- tolower(as.character(x$is_date_like %||% "")) %in% c("true", "t", "1", "yes") |
    grepl("date|dato|_dt$|doedsdato|død|doed|svardato|rekvdato", tolower(cols))
  cols <- cols[is_date & nzchar(cols)]
  if (!length(cols)) return(character())
  anchor <- tolower(as.character(date_anchor %||% ""))
  priority <- character()
  if (grepl("diagnosis|biopsi|diagnose", anchor)) {
    priority <- c("Reg_DiagnostiskBiopsi_dt", "Reg_BehandlingBeslutning_dt")
  } else if (grepl("first_line|treatment|behandling|window", anchor)) {
    priority <- c("Beh_KemoterapiStart_dt", "Beh_ImmunoterapiStart_dt", "Reg_BehandlingBeslutning_dt")
  } else if (grepl("death|follow", anchor)) {
    priority <- c("FU_Doedsdato", "CPR_Doedsdato", "date_death_fu")
  } else if (grepl("relapse|progression", anchor)) {
    priority <- c("Rec_RelapsProgressions_dt")
  } else if (grepl("pathology|sample|ki67", anchor)) {
    priority <- c("d_rekvdato", "d_svardato", "date_received")
  } else if (grepl("birth|age", anchor)) {
    priority <- c("date_birth")
  }
  selected <- unique(c(intersect(priority, cols), cols))
  head(selected, 6L)
}

mcl_count_date_mapping_available <- function(defs, column_profiles, i) {
  anchor <- defs$date_anchor[[i]]
  if (!grepl("date|window|landmark|diagnosis|first_line|birth|age", anchor, ignore.case = TRUE)) return(TRUE)
  source <- mcl_count_source_table(defs[i, , drop = FALSE])
  any(vapply(source$table, function(tbl) length(mcl_count_date_anchor_columns(column_profiles, tbl, anchor)) > 0L, logical(1)))
}

mcl_count_person_key_audit <- function(defs, count_sets = NULL, outputs_dir = NULL) {
  sources <- mcl_count_source_table(defs)
  has_sets <- is.list(count_sets) && length(count_sets)
  column_profiles <- mcl_count_column_profiles(outputs_dir)
  rows <- lapply(seq_len(nrow(sources)), function(i) {
    mapping <- mcl_count_person_key_mapping(column_profiles, sources$table[[i]])
    data.frame(
      source = sources$source[[i]],
      table = sources$table[[i]],
      candidate_person_id_columns = if (has_sets) "source_person_key" else mapping$candidates,
      selected_person_id_column = if (has_sets) "source_person_key" else mapping$selected,
      confidence = if (has_sets) "configured_aggregate_count_hook" else mapping$confidence,
      usable_for_distinct_person_counts = isTRUE(has_sets) || isTRUE(mapping$usable),
      notes = if (has_sets) {
        "Distinct-person aggregate count hook provided; no person-key values emitted."
      } else if (isTRUE(mapping$usable)) {
        mapping$notes
      } else {
        mapping$notes
      },
      stringsAsFactors = FALSE
    )
  })
  out <- unique(bind_rows_base(rows))
  mcl_count_match_empty(out, mcl_count_empty_person_key_audit())
}

mcl_count_data_points_from_sets <- function(defs, sets, min_cell_count = 5L) {
  denom_counts <- vapply(mcl_count_denominator_ids(), function(id) length(mcl_count_set(sets, id)), numeric(1))
  rows <- lapply(seq_len(nrow(defs)), function(i) {
    id <- defs$data_point_id[[i]]
    denom_id <- defs$denominator[[i]]
    if (!mcl_count_set_available(sets, id) || (!mcl_count_set_available(sets, denom_id) && !identical(id, denom_id))) {
      return(data.frame(
        data_point_id = id,
        clinical_label = defs$clinical_label[[i]],
        denominator = denom_id,
        timing_scope = mcl_count_timing_scope(defs$valid_time_window[[i]]),
        count_status = "count_not_available_requires_value_mapping",
        distinct_person_count_display = "",
        percent_of_denominator_display = "",
        denominator_count_display = "",
        count_source = "direct_aggregate_count_hook_missing_set",
        person_key_confidence = "configured_aggregate_count_hook",
        timing_validation_status = "requires_source_validation",
        source_locations = defs$source_priority[[i]],
        notes = paste("No distinct-person aggregate set supplied for", id, "- zero was not inferred."),
        stringsAsFactors = FALSE
      ))
    }
    people <- mcl_count_intersect_sets(sets, c(denom_id, id))
    denom_n <- denom_counts[[denom_id]] %||% length(mcl_count_set(sets, denom_id))
    count <- mcl_count_suppress(length(people), min_cell_count)
    denom <- mcl_count_suppress(denom_n, min_cell_count)
    timing <- mcl_count_timing_scope(defs$valid_time_window[[i]])
    status <- count$status
    if (identical(status, "count_available") && timing != "ever_available" && !grepl("validated", defs$validation_status[[i]], ignore.case = TRUE)) {
      status <- "count_available_timing_not_validated"
    }
    status <- mcl_count_production_status(status)
    data.frame(
      data_point_id = id,
      clinical_label = defs$clinical_label[[i]],
      denominator = denom_id,
      timing_scope = timing,
      count_status = status,
      distinct_person_count_display = count$display,
      percent_of_denominator_display = mcl_count_percent_display(length(people), denom_n, min_cell_count),
      denominator_count_display = denom$display,
      count_source = "direct_aggregate_count_hook",
      person_key_confidence = "configured_aggregate_count_hook",
      timing_validation_status = if (timing == "ever_available") "timing_not_required" else "timing_requires_source_validation",
      source_locations = defs$source_priority[[i]],
      notes = defs$notes[[i]],
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_data_point_counts())
}

mcl_count_data_point_mapping <- function(defs, column_profiles, i) {
  source <- mcl_count_source_table(defs[i, , drop = FALSE])
  person_usable <- any(vapply(source$table, function(tbl) isTRUE(mcl_count_person_key_mapping(column_profiles, tbl)$usable), logical(1)))
  date_usable <- mcl_count_date_mapping_available(defs, column_profiles, i)
  source_locations <- defs$source_priority[[i]]
  date_cols <- unique(unlist(lapply(source$table, function(tbl) mcl_count_date_anchor_columns(column_profiles, tbl, defs$date_anchor[[i]])), use.names = FALSE))
  if (length(date_cols)) source_locations <- paste(source_locations, "date anchors:", paste(date_cols, collapse = "; "), sep = "; ")
  list(
    person_usable = person_usable,
    date_usable = date_usable,
    source_locations = source_locations,
    person_confidence = if (person_usable) "aggregate_column_profile_person_key" else "requires_mapping",
    timing_status = if (date_usable) "date_anchor_candidates_found_requires_validation" else "requires_date_mapping"
  )
}

mcl_count_unavailable_data_points <- function(defs, status = "count_not_available_requires_production_validation", outputs_dir = NULL) {
  column_profiles <- mcl_count_column_profiles(outputs_dir)
  rows <- lapply(seq_len(nrow(defs)), function(i) {
    mapping <- mcl_count_data_point_mapping(defs, column_profiles, i)
    row_status <- status
    if (!isTRUE(mapping$person_usable)) {
      row_status <- "count_not_available_requires_person_key_mapping"
    } else if (!isTRUE(mapping$date_usable) && grepl("date|window|landmark|diagnosis|first_line|birth|age", defs$date_anchor[[i]], ignore.case = TRUE)) {
      row_status <- "count_not_available_requires_date_mapping"
    }
    data.frame(
      data_point_id = defs$data_point_id[[i]],
      clinical_label = defs$clinical_label[[i]],
      denominator = defs$denominator[[i]],
      timing_scope = mcl_count_timing_scope(defs$valid_time_window[[i]]),
      count_status = row_status,
      distinct_person_count_display = "",
      percent_of_denominator_display = "",
      denominator_count_display = "",
      count_source = "plan_only_no_person_counts",
      person_key_confidence = mapping$person_confidence,
      timing_validation_status = mapping$timing_status,
      source_locations = mapping$source_locations,
      notes = "Plan/query-template output only; no distinct-person production aggregate was executed.",
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_data_point_counts())
}

mcl_count_waterfall_from_sets <- function(sets, min_cell_count = 5L) {
  steps <- data.frame(
    step_order = seq_len(9),
    step_id = c(
      "all_lyfo_mcl",
      "younger_mcl_proxy_age_le_65",
      "diagnosis_date",
      "first_line_treatment_date",
      "cit_immunochemotherapy",
      "asct_hdt_first_line",
      "ibrutinib_exposure",
      "os_death",
      "ki67_aeki"
    ),
    step_label = c(
      "MCL cohort",
      "Younger proxy, age <=65",
      "Diagnosis date available",
      "First-line treatment date available",
      "CIT/immunochemotherapy evidence",
      "First-line ASCT/HDT status",
      "Ibrutinib exposure evidence",
      "OS/death evidence",
      "Ki-67 AEKI evidence"
    ),
    stringsAsFactors = FALSE
  )
  current <- character()
  start_n <- NA_real_
  rows <- lapply(seq_len(nrow(steps)), function(i) {
    id <- steps$step_id[[i]]
    if (i == 1L) {
      current <<- mcl_count_set(sets, id)
      start_n <<- length(current)
    } else {
      current <<- intersect(current, mcl_count_set(sets, id))
    }
    count <- mcl_count_suppress(length(current), min_cell_count)
    data.frame(
      step_order = steps$step_order[[i]],
      step_id = id,
      step_label = steps$step_label[[i]],
      denominator = "all_lyfo_mcl",
      timing_scope = if (id %in% c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) "near_diagnosis" else "first_line_window",
      count_status = mcl_count_production_status(count$status),
      distinct_person_count_display = count$display,
      percent_of_start_display = mcl_count_percent_display(length(current), start_n, min_cell_count),
      cumulative_rule = paste(steps$step_id[seq_len(i)], collapse = " + "),
      notes = "Progressive feasibility denominator; not a treatment-effect analysis.",
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_inclusion_waterfall())
}

mcl_count_unavailable_waterfall <- function() {
  mcl_count_match_empty(data.frame(
    step_order = 1L,
    step_id = "all_lyfo_mcl",
    step_label = "MCL cohort",
    denominator = "all_lyfo_mcl",
    timing_scope = "near_diagnosis",
    count_status = "count_not_available_requires_production_validation",
    distinct_person_count_display = "",
    percent_of_start_display = "",
    cumulative_rule = "all_lyfo_mcl",
    notes = "Distinct-person counts require production aggregate execution with person-key mapping.",
    stringsAsFactors = FALSE
  ), mcl_count_empty_inclusion_waterfall())
}

mcl_count_overlap_from_sets <- function(sets, min_cell_count = 5L) {
  denom <- mcl_count_set(sets, "all_lyfo_mcl")
  denom_n <- length(denom)
  ids <- c("younger_mcl_proxy_age_le_65", "cit_immunochemotherapy", "asct_hdt_first_line", "ibrutinib_exposure", "os_death", "relapse_progression_ffs_proxy", "ki67_aeki", "tp53_p53_del17p", "blastoid_pleomorphic_morphology")
  rows <- list()
  for (row_id in ids) {
    for (col_id in ids) {
      people <- Reduce(intersect, list(denom, mcl_count_set(sets, row_id), mcl_count_set(sets, col_id)))
      count <- mcl_count_suppress(length(people), min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(
        denominator = "all_lyfo_mcl",
        row_data_point_id = row_id,
        column_data_point_id = col_id,
        timing_scope = "ever_available",
        count_status = mcl_count_production_status(count$status),
        distinct_person_count_display = count$display,
        percent_of_denominator_display = mcl_count_percent_display(length(people), denom_n, min_cell_count),
        notes = "Pairwise/domain overlap for feasibility only.",
        stringsAsFactors = FALSE
      )
    }
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_overlap_matrix())
}

mcl_count_exposure_strata_from_sets <- function(sets, min_cell_count = 5L) {
  rows <- list()
  for (denom_id in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    denom <- mcl_count_set(sets, denom_id)
    denom_n <- length(denom)
    asct <- intersect(denom, mcl_count_set(sets, "asct_hdt_first_line"))
    ib <- intersect(denom, mcl_count_set(sets, "ibrutinib_exposure"))
    strata <- list(
      list("ASCT/HDT evidence", "ibrutinib evidence", intersect(asct, ib)),
      list("ASCT/HDT evidence", "no ibrutinib evidence", setdiff(asct, ib)),
      list("no ASCT/HDT evidence", "ibrutinib evidence", setdiff(ib, asct)),
      list("no ASCT/HDT evidence", "no ibrutinib evidence", setdiff(denom, union(asct, ib)))
    )
    for (stratum in strata) {
      count <- mcl_count_suppress(length(stratum[[3]]), min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(
        denominator = denom_id,
        asct_hdt_first_line_status = stratum[[1]],
        ibrutinib_status = stratum[[2]],
        timing_scope = "first_line_window",
        count_status = mcl_count_production_status(count$status),
        distinct_person_count_display = count$display,
        percent_of_denominator_display = mcl_count_percent_display(length(stratum[[3]]), denom_n, min_cell_count),
        notes = "Descriptive feasibility stratum only; does not handle timing, eligibility, response, immortal time, or confounding.",
        stringsAsFactors = FALSE
      )
    }
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_exposure_strata_counts())
}

mcl_count_landmark_from_sets <- function(sets, min_cell_count = 5L) {
  reqs <- data.frame(
    requirement = c(
      "MCL patients with diagnosis date",
      "MCL patients with first-line treatment date",
      "MCL patients alive at landmark",
      "MCL patients without event before landmark",
      "MCL patients with ASCT/HDT status known at/after landmark",
      "MCL patients with ibrutinib exposure status known at/after landmark",
      "MCL patients with high-risk biology known before landmark"
    ),
    set_id = c(
      "diagnosis_date",
      "first_line_treatment_date",
      "alive_at_landmark",
      "event_free_pre_landmark",
      "asct_hdt_status_known_landmark",
      "ibrutinib_status_known_landmark",
      "high_risk_biology_pre_landmark"
    ),
    timing_scope = c("near_diagnosis", "first_line_window", "pre_landmark", "pre_landmark", "post_landmark", "post_landmark", "pre_landmark"),
    stringsAsFactors = FALSE
  )
  denom_id <- "younger_mcl_proxy_age_le_65"
  denom <- mcl_count_set(sets, denom_id)
  denom_n <- length(denom)
  rows <- lapply(seq_len(nrow(reqs)), function(i) {
    people <- intersect(denom, mcl_count_set(sets, reqs$set_id[[i]]))
    count <- mcl_count_suppress(length(people), min_cell_count)
    data.frame(
      landmark_id = "six_months_after_first_line_start",
      landmark_label = "6 months after first-line start",
      requirement = reqs$requirement[[i]],
      denominator = denom_id,
      timing_scope = reqs$timing_scope[[i]],
      count_status = mcl_count_production_status(count$status),
      distinct_person_count_display = count$display,
      percent_of_denominator_display = mcl_count_percent_display(length(people), denom_n, min_cell_count),
      notes = "Landmark feasibility only; not target-trial emulation.",
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_landmark_counts())
}

mcl_count_ki67_summary_from_sets <- function(sets, ki67_percent_counts = NULL, min_cell_count = 5L) {
  source_locations <- "SDS_pato.c_snomedkode; SDS_dimpatologiskdiagnose.diagnose_snomed_kode"
  code_count <- ""
  unique_values <- ""
  if (is.data.frame(ki67_percent_counts) && nrow(ki67_percent_counts)) {
    code_count <- as.character(sum(suppressWarnings(as.numeric(ki67_percent_counts$aggregate_count %||% 0)), na.rm = TRUE))
    unique_values <- as.character(length(unique(ki67_percent_counts$parsed_percent %||% character())))
  }
  rows <- lapply(c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65"), function(denom_id) {
    denom <- mcl_count_set(sets, denom_id)
    people <- intersect(denom, mcl_count_set(sets, "ki67_aeki"))
    count <- mcl_count_suppress(length(people), min_cell_count)
    data.frame(
      denominator = denom_id,
      timing_window = "ever_available",
      distinct_person_count_display = count$display,
      percent_of_denominator_display = mcl_count_percent_display(length(people), length(denom), min_cell_count),
      valid_aeki_code_count = code_count,
      unique_percent_values_observed = unique_values,
      source_locations = source_locations,
      validation_status = if (identical(count$status, "count_available")) "production_aggregate_count_available_timing_not_validated" else count$status,
      notes = "Distinct-person Ki-67 AEKI availability; source-specific clinical validation is required before analytic use.",
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_person_summary())
}

mcl_count_summary_from_outputs <- function(data_points, waterfall, overlaps, strata) {
  metric <- function(id, label, value, status, notes) {
    data.frame(metric = id, label = label, value = value, status = status, notes = notes, stringsAsFactors = FALSE)
  }
  mcl <- data_points[data_points$data_point_id == "all_lyfo_mcl", , drop = FALSE]
  young <- data_points[data_points$data_point_id == "younger_mcl_proxy_age_le_65", , drop = FALSE]
  count_available <- sum(data_points$count_status %in% mcl_count_available_statuses(), na.rm = TRUE)
  failed <- sum(grepl("^production_aggregate_failed|^count_not_available", data_points$count_status %||% character(), perl = TRUE), na.rm = TRUE)
  suppressed <- sum(data_points$count_status == "suppressed_small_cell", na.rm = TRUE)
  query_errors <- sum(data_points$count_status == "production_aggregate_failed_query_error", na.rm = TRUE)
  review_zeros <- sum(data_points$count_status == "count_available_zero_requires_value_mapping_review", na.rm = TRUE)
  rows <- list(
    metric("all_lyfo_mcl", "All LYFO MCL distinct-person denominator", mcl$distinct_person_count_display[[1]] %||% "", mcl$count_status[[1]] %||% "", "Main feasibility denominator."),
    metric("younger_mcl_proxy_age_le_65", "Younger/transplant-eligible proxy distinct-person denominator", young$distinct_person_count_display[[1]] %||% "", young$count_status[[1]] %||% "", "Age <=65 is a younger proxy, not full transplant eligibility."),
    metric("countable_data_points", "Data points with aggregate person counts", as.character(count_available), "info", "Counts are aggregate distinct-person feasibility counts."),
    metric("failed_data_points", "Data points unavailable or failed", as.character(failed), "info", "Unavailable counts carry explicit mapping, credential, or query-error statuses."),
    metric("suppressed_cells", "Small-cell suppressed count rows", as.character(suppressed), "info", "Exact counts below the configured threshold are not displayed."),
    metric("query_errors", "Production aggregate query errors", as.character(query_errors), "info", "Failed queries remain production-mode failures and do not fall back to plan mode."),
    metric("zero_counts_requiring_value_mapping_review", "Zero counts requiring value-mapping review", as.character(review_zeros), "warning", "A zero with uncertain value semantics is not treated as clinical absence."),
    metric("waterfall_steps", "Waterfall steps", as.character(nrow(waterfall)), "info", "Progressive inclusion counts for feasibility only."),
    metric("overlap_cells", "Overlap matrix cells", as.character(nrow(overlaps)), "info", "Pairwise/domain overlaps; not a causal design."),
    metric("exposure_strata", "ASCT/HDT x ibrutinib strata", as.character(nrow(strata)), "info", "Descriptive feasibility strata only.")
  )
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_summary())
}

mcl_count_placeholder_outputs <- function(defs, mode = "plan", outputs_dir = NULL) {
  data_points <- mcl_count_unavailable_data_points(
    defs,
    status = if (identical(mode, "plan")) "count_not_available_requires_production_validation" else "count_not_available_requires_person_key_mapping",
    outputs_dir = outputs_dir
  )
  waterfall <- mcl_count_unavailable_waterfall()
  overlaps <- mcl_count_empty_overlap_matrix()
  strata <- mcl_count_empty_exposure_strata_counts()
  list(
    data_point_counts = data_points,
    inclusion_waterfall = waterfall,
    overlap_matrix = overlaps,
    exposure_strata_counts = strata,
    landmark_feasibility_counts = mcl_count_empty_landmark_counts(),
    ki67_person_count_summary = mcl_count_empty_ki67_person_summary(),
    age_proxy_counts = mcl_count_empty_age_proxy_counts(),
    ibrutinib_exposure_counts = mcl_count_empty_ibrutinib_exposure_counts(),
    treatment_strategy_strata_counts = mcl_count_empty_treatment_strategy_strata_counts(),
    high_risk_biology_counts = mcl_count_empty_high_risk_biology_counts(),
    answerability_intersections = mcl_count_empty_answerability_intersections(),
    answerability_summary = mcl_count_empty_answerability_summary(),
    count_summary = mcl_count_summary_from_outputs(data_points, waterfall, overlaps, strata)
  )
}

mcl_count_outputs_from_sets <- function(defs, sets, ki67_percent_counts = NULL, min_cell_count = 5L) {
  data_points <- mcl_count_data_points_from_sets(defs, sets, min_cell_count = min_cell_count)
  waterfall <- mcl_count_waterfall_from_sets(sets, min_cell_count = min_cell_count)
  overlaps <- mcl_count_overlap_from_sets(sets, min_cell_count = min_cell_count)
  strata <- mcl_count_exposure_strata_from_sets(sets, min_cell_count = min_cell_count)
  landmark <- mcl_count_landmark_from_sets(sets, min_cell_count = min_cell_count)
  ki67_summary <- mcl_count_ki67_summary_from_sets(sets, ki67_percent_counts = ki67_percent_counts, min_cell_count = min_cell_count)
  age_proxy <- mcl_count_age_proxy_from_sets(sets, min_cell_count = min_cell_count)
  ibrutinib_counts <- mcl_count_ibrutinib_counts_from_sets(sets, min_cell_count = min_cell_count)
  strategy <- mcl_count_treatment_strategy_from_sets(sets, min_cell_count = min_cell_count)
  high_risk <- mcl_count_high_risk_from_sets(sets, min_cell_count = min_cell_count)
  answerability <- mcl_count_answerability_rows_from_sets(sets, min_cell_count = min_cell_count)
  answerability_summary <- mcl_count_answerability_summary_from_outputs(data_points, answerability, high_risk, strategy, landmark, min_cell_count = min_cell_count)
  list(
    data_point_counts = data_points,
    inclusion_waterfall = waterfall,
    overlap_matrix = overlaps,
    exposure_strata_counts = strata,
    landmark_feasibility_counts = landmark,
    ki67_person_count_summary = ki67_summary,
    age_proxy_counts = age_proxy,
    ibrutinib_exposure_counts = ibrutinib_counts,
    treatment_strategy_strata_counts = strategy,
    high_risk_biology_counts = high_risk,
    answerability_intersections = answerability,
    answerability_summary = answerability_summary,
    count_summary = mcl_count_summary_from_outputs(data_points, waterfall, overlaps, strata)
  )
}

mcl_count_query_templates <- function(defs, outputs_dir = NULL) {
  column_profiles <- mcl_count_column_profiles(outputs_dir)
  header <- c(
    "-- MCL/TRIANGLE aggregate distinct-person feasibility count templates.",
    "-- Aggregate-only. Star-selects and raw-row previews are prohibited. No raw rows, identifiers, dates, or text snippets should be emitted.",
    "-- Person-key/date columns from aggregate column profiles are candidates only; validate source joins before production execution.",
    ""
  )
  templates <- lapply(seq_len(nrow(defs)), function(i) {
    id <- defs$data_point_id[[i]]
    label <- defs$clinical_label[[i]]
    table_name <- if (grepl("ki67", id, ignore.case = TRUE)) "SDS_pato" else "RKKP_LYFO"
    table <- paste0('"public"."', table_name, '"')
    denom_key <- mcl_count_person_key_mapping(column_profiles, "RKKP_LYFO")$selected
    data_key <- mcl_count_person_key_mapping(column_profiles, table_name)$selected
    if (!nzchar(denom_key)) denom_key <- "<person_key>"
    if (!nzchar(data_key)) data_key <- "<person_key>"
    date_cols <- mcl_count_date_anchor_columns(column_profiles, table_name, defs$date_anchor[[i]])
    predicate <- defs$valid_value_rule[[i]]
    paste0(
      "-- ", id, ": ", label, "\n",
      "-- Candidate person key: ", data_key, "\n",
      if (length(date_cols)) paste0("-- Candidate date anchors: ", paste(date_cols, collapse = "; "), "\n") else "-- Candidate date anchors: require date mapping\n",
      "with denominator as (\n",
      "  select distinct ", denom_key, " as person_key\n",
      "  from \"public\".\"RKKP_LYFO\"\n",
      "  where <validated_mcl_predicate>\n",
      "), data_point as (\n",
      "  select distinct ", data_key, " as person_key\n",
      "  from ", table, "\n",
      "  where <validated_rule_for_", id, ">\n",
      ")\n",
      "select '", id, "' as data_point_id,\n",
      "       count(*) as distinct_person_count\n",
      "from denominator d\n",
      "join data_point x using (person_key);\n",
      "-- Value rule: ", gsub("[\r\n]+", " ", predicate), "\n"
    )
  })
  paste(c(header, unlist(templates, use.names = FALSE)), collapse = "\n")
}

mcl_count_read_outputs <- function(output_dir) {
  read_or_empty <- function(name, empty) {
    path <- file.path(output_dir, name)
    if (file.exists(path)) read_delimited_file(path) else empty
  }
  list(
    person_key_audit = read_or_empty("mcl_triangle_person_key_audit.csv", mcl_count_empty_person_key_audit()),
    data_point_counts = read_or_empty("mcl_triangle_data_point_counts.csv", mcl_count_empty_data_point_counts()),
    inclusion_waterfall = read_or_empty("mcl_triangle_inclusion_waterfall.csv", mcl_count_empty_inclusion_waterfall()),
    overlap_matrix = read_or_empty("mcl_triangle_overlap_matrix.csv", mcl_count_empty_overlap_matrix()),
    exposure_strata_counts = read_or_empty("mcl_triangle_exposure_strata_counts.csv", mcl_count_empty_exposure_strata_counts()),
    landmark_feasibility_counts = read_or_empty("mcl_triangle_landmark_feasibility_counts.csv", mcl_count_empty_landmark_counts()),
    ki67_person_count_summary = read_or_empty("mcl_triangle_ki67_person_count_summary.csv", mcl_count_empty_ki67_person_summary()),
    age_proxy_counts = read_or_empty("mcl_triangle_age_proxy_counts.csv", mcl_count_empty_age_proxy_counts()),
    ibrutinib_exposure_counts = read_or_empty("mcl_triangle_ibrutinib_exposure_counts.csv", mcl_count_empty_ibrutinib_exposure_counts()),
    treatment_strategy_strata_counts = read_or_empty("mcl_triangle_treatment_strategy_strata_counts.csv", mcl_count_empty_treatment_strategy_strata_counts()),
    high_risk_biology_counts = read_or_empty("mcl_triangle_high_risk_biology_counts.csv", mcl_count_empty_high_risk_biology_counts()),
    answerability_intersections = read_or_empty("mcl_triangle_answerability_intersections.csv", mcl_count_empty_answerability_intersections()),
    answerability_summary = read_or_empty("mcl_triangle_answerability_summary.csv", mcl_count_empty_answerability_summary()),
    count_summary = read_or_empty("mcl_triangle_count_summary.csv", mcl_count_empty_summary()),
    execution_summary = read_or_empty("mcl_triangle_execution_summary.csv", mcl_count_empty_execution_summary())
  )
}

mcl_count_empty_person_key_audit <- function() {
  empty_df(
    source = character(),
    schema = character(),
    table = character(),
    candidate_person_id_columns = character(),
    selected_person_id_column = character(),
    links_to_dalycare_patient = logical(),
    linkage_confidence = character(),
    usable_for_distinct_person_counts = logical(),
    date_anchor_columns = character(),
    notes = character()
  )
}

mcl_count_person_key_audit <- function(defs, count_sets = NULL, outputs_dir = NULL, project_root = ".") {
  sources <- mcl_count_source_table(defs)
  has_sets <- is.list(count_sets) && length(count_sets)
  pdm <- mcl_count_read_person_date_mapping(project_root)
  if (is.data.frame(pdm) && nrow(pdm) && all(c("resource_id", "table") %in% names(pdm))) {
    configured_sources <- unique(data.frame(
      source = as.character(pdm$resource_id),
      table = as.character(pdm$table),
      stringsAsFactors = FALSE
    ))
    sources <- unique(bind_rows_base(list(sources, configured_sources)))
  }
  rows <- lapply(seq_len(nrow(sources)), function(i) {
    lookup_table <- sources$table[[i]]
    if (identical(lookup_table, "patient_or_death_followup")) lookup_table <- "patient"
    mapping <- mcl_count_source_mapping(pdm, table = lookup_table)
    if (!nrow(mapping)) mapping <- data.frame(schema = "", person_key_column = "", linkage_confidence = "requires_mapping", usable_for_counts = FALSE, date_columns = "", notes = "No configured person/date mapping.", stringsAsFactors = FALSE)
    usable <- isTRUE(has_sets) || mcl_count_mapping_usable(mapping)
    data.frame(
      source = sources$source[[i]],
      schema = mapping$schema[[1]] %||% "",
      table = sources$table[[i]],
      candidate_person_id_columns = if (has_sets) "source_person_key" else (mapping$person_key_column[[1]] %||% ""),
      selected_person_id_column = if (has_sets) "source_person_key" else (mapping$person_key_column[[1]] %||% ""),
      links_to_dalycare_patient = usable,
      linkage_confidence = if (has_sets) "configured_aggregate_count_hook" else (mapping$linkage_confidence[[1]] %||% "requires_mapping"),
      usable_for_distinct_person_counts = usable,
      date_anchor_columns = mapping$date_columns[[1]] %||% "",
      notes = if (has_sets) "Distinct-person aggregate count hook provided; no person-key values emitted." else (mapping$notes[[1]] %||% ""),
      stringsAsFactors = FALSE
    )
  })
  out <- unique(bind_rows_base(rows))
  mcl_count_match_empty(out, mcl_count_empty_person_key_audit())
}

# Production aggregate count extensions -------------------------------------------------

mcl_count_status_levels <- function() {
  c(
    "query_executable_not_run",
    "production_aggregate_count_available",
    "production_aggregate_failed_credentials_unavailable",
    "production_aggregate_failed_mapping_unavailable",
    "production_aggregate_failed_query_error",
    "count_available_zero_requires_value_mapping_review",
    "count_available",
    "count_available_timing_not_validated",
    "count_not_available_requires_patient_demographics_mapping",
    "count_not_available_requires_person_key_mapping",
    "count_not_available_requires_date_mapping",
    "count_not_available_requires_value_mapping",
    "count_not_available_requires_dedicated_intersection_query",
    "count_not_available_requires_production_validation",
    "suppressed_small_cell",
    "not_applicable"
  )
}

mcl_count_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
}

mcl_count_read_mapping_tsv <- function(project_root, file_name) {
  path <- file.path(project_root, "config", file_name)
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
}

mcl_count_ensure_columns <- function(x, needed, fill = "") {
  if (!is.data.frame(x)) x <- data.frame(stringsAsFactors = FALSE)
  n <- nrow(x)
  if (is.null(n)) n <- 0L
  fill <- as.character(fill %||% "")
  for (nm in needed) {
    if (!nm %in% names(x)) x[[nm]] <- rep(fill[[1]], n)
  }
  x[needed]
}

mcl_count_read_person_date_mapping <- function(project_root) {
  x <- mcl_count_read_mapping_tsv(project_root, "mcl_triangle_person_date_mapping.tsv")
  needed <- c(
    "resource_id", "db_name", "schema", "table", "person_key_column", "person_key_type",
    "date_columns", "diagnosis_date_column", "treatment_start_date_column",
    "event_date_column", "source_role", "linkage_confidence",
    "usable_for_counts", "notes"
  )
  mcl_count_ensure_columns(x, needed)
}

mcl_count_read_value_mappings <- function(project_root) {
  x <- mcl_count_read_mapping_tsv(project_root, "mcl_triangle_count_value_mappings.tsv")
  needed <- c(
    "data_point_id", "resource_id", "table", "field", "value_class",
    "mapped_values", "sql_predicate", "validation_status", "notes"
  )
  mcl_count_ensure_columns(x, needed)
}

mcl_count_default_treatment_code_mappings <- function() {
  data.frame(
    source_id = c(
      "RKKP_LYFO_Beh_Kemoterapiregime1",
      "RKKP_LYFO_Beh_Kemoterapiregime2",
      "RKKP_LYFO_Beh_Kemoterapiregime3",
      "SDS_indberetningmedpris_ATC_L01XE27",
      "SP_OrdineretMedicin_ATC_L01XE27",
      "SDS_epikur_ATC_L01XE27",
      "SDS_ekokur_ATC_L01XE27",
      "SDS_t_sksube_SKS_BWHA169",
      "RKKP_CLL_Beh_TargeteretBeh_Ibrutinib",
      "CLL_TREAT_IBRUTINIB_auxiliary"
    ),
    canonical_source_id = c(
      "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO",
      "SDS_indberetningmedpris", "SP_OrdineretMedicin", "SDS_epikur",
      "SDS_ekokur", "SDS_t_sksube", "RKKP_CLL", "CLL_TREAT_IBRUTINIB"
    ),
    db_name = c(rep("import", 9), "core"),
    schema = c(rep("public", 9), "curated"),
    table = c(
      "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO",
      "SDS_indberetningmedpris", "SP_OrdineretMedicin", "SDS_epikur",
      "SDS_ekokur", "SDS_t_sksube", "RKKP_CLL", "CLL_TREAT_IBRUTINIB"
    ),
    person_key_column = c(rep("patientid", 7), "", "patientid", "patientid"),
    code_column = c(
      "Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3",
      "c_atc", "atc;atc5", "atc", "atc", "c_opr",
      "Beh_TargeteretBeh_Ibrutinib", "ibrutinib_mono;ibrutinib_combination"
    ),
    code_system = c(rep("LYFO_REGIMEN", 3), "ATC", "ATC", "ATC", "ATC", "SKS", "RKKP_CLL_FIELD", "CURATED_CLL_FIELD"),
    code_value = c(rep("ibrutinib", 3), "L01XE27", "L01XE27", "L01XE27", "L01XE27", "BWHA169", "Y", "1;Y;TRUE"),
    date_columns = c(
      "Beh_KemoterapiStart_dt", "Beh_KemoterapiStart_dt", "Beh_KemoterapiStart_dt",
      "d_ord_start;d_adm", "order_start_time;order_end_time", "eksd", "eksd", "d_odto",
      "Beh_Behandling_Start_dt", "ibrutinib_start"
    ),
    bridge_table = c(rep("", 7), "SDS_t_adm", "", ""),
    bridge_source_key_column = c(rep("", 7), "v_recnum", "", ""),
    bridge_key_column = c(rep("", 7), "k_recnum", "", ""),
    bridge_person_key_column = c(rep("", 7), "patientid", "", ""),
    source_role = c(rep("primary_registry_regimen", 3), rep("primary_atc_source", 4), "primary_bridged_sks_source", "auxiliary_cross_registry", "auxiliary_cross_db_curated"),
    include_in_primary_union = c(rep(TRUE, 8), FALSE, FALSE),
    timing_window_start_days = -30L,
    timing_window_end_days = 180L,
    notes = c(
      rep("LYFO regimen value evidence remains part of the primary ibrutinib union.", 3),
      "Atlas-confirmed ATC Ibrutinib evidence from SDS in-hospital medicine price reporting.",
      "Atlas-confirmed ATC Ibrutinib evidence from SP ordered medication.",
      "Atlas-confirmed ATC Ibrutinib evidence from SDS_epikur.",
      "Atlas-confirmed ATC Ibrutinib evidence from SDS_ekokur.",
      "Atlas-confirmed SKS Ibrutinib code evidence; aggregate person counting requires SDS_t_sksube.v_recnum to SDS_t_adm.k_recnum/patientid bridge validation.",
      "Auxiliary CLL registry target-therapy evidence only; not included in primary MCL union.",
      "Auxiliary curated CLL source only; source-name and social-history fields are not exposure evidence."
    ),
    stringsAsFactors = FALSE
  )
}

mcl_count_read_treatment_code_mappings <- function(project_root) {
  x <- mcl_count_read_mapping_tsv(project_root, "mcl_triangle_treatment_code_mappings.tsv")
  if (!is.data.frame(x) || !nrow(x)) x <- mcl_count_default_treatment_code_mappings()
  needed <- c(
    "source_id", "canonical_source_id", "db_name", "schema", "table",
    "person_key_column", "code_column", "code_system", "code_value",
    "date_columns", "bridge_table", "bridge_source_key_column",
    "bridge_key_column", "bridge_person_key_column", "source_role",
    "include_in_primary_union", "timing_window_start_days",
    "timing_window_end_days", "notes"
  )
  x <- mcl_count_ensure_columns(x, needed)
  x$canonical_source_id <- ifelse(nzchar(x$canonical_source_id), x$canonical_source_id, x$table)
  x$schema[!nzchar(x$schema)] <- "public"
  x$db_name[!nzchar(x$db_name) & tolower(x$table) %in% c("rkkp_lyfo", "sds_indberetningmedpris", "sp_ordineretmedicin", "sds_epikur", "sds_ekokur", "sds_t_sksube", "sds_t_adm", "rkkp_cll")] <- "import"
  x$db_name[!nzchar(x$db_name) & tolower(x$table) == "cll_treat_ibrutinib"] <- "core"
  x
}

mcl_count_zip_entry <- function(zip_path, patterns) {
  if (!file.exists(zip_path)) return("")
  entries <- tryCatch(utils::unzip(zip_path, list = TRUE), error = function(e) NULL)
  if (!is.data.frame(entries) || !"Name" %in% names(entries)) return("")
  names <- as.character(entries$Name)
  for (pattern in patterns) {
    hit <- names[grepl(pattern, names, ignore.case = TRUE, perl = TRUE)]
    if (length(hit)) return(hit[[1]])
  }
  ""
}

mcl_count_read_zip_table <- function(zip_path, patterns) {
  entry <- mcl_count_zip_entry(zip_path, patterns)
  if (!nzchar(entry)) return(data.frame(stringsAsFactors = FALSE))
  tmp <- tempfile("mcl_count_zip_")
  dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(tmp, recursive = TRUE, force = TRUE), add = TRUE)
  extracted <- tryCatch(
    utils::unzip(zip_path, files = entry, exdir = tmp, junkpaths = TRUE, overwrite = TRUE),
    error = function(e) character()
  )
  if (!length(extracted) || !file.exists(extracted[[1]])) return(data.frame(stringsAsFactors = FALSE))
  sep <- if (grepl("\\.tsv$", entry, ignore.case = TRUE)) "\t" else ","
  tryCatch(
    suppressWarnings(utils::read.table(file = extracted[[1]], sep = sep, header = TRUE, quote = "\"",
                                       comment.char = "", stringsAsFactors = FALSE, check.names = FALSE, fill = TRUE)),
    error = function(e) data.frame(stringsAsFactors = FALSE)
  )
}

mcl_count_read_atlas_output_table <- function(name, atlas_output_dir = NULL, atlas_output_zip = NULL) {
  atlas_output_dir <- as.character(atlas_output_dir %||% "")
  atlas_output_zip <- as.character(atlas_output_zip %||% "")
  if (nzchar(atlas_output_dir) && dir.exists(atlas_output_dir)) {
    hit <- list.files(atlas_output_dir, pattern = paste0("^", gsub("[.]", "[.]", name), "$"), recursive = TRUE, full.names = TRUE)
    if (length(hit)) {
      return(tryCatch(read_delimited_file(hit[[1]]), error = function(e) data.frame(stringsAsFactors = FALSE)))
    }
  }
  if (nzchar(atlas_output_zip) && file.exists(atlas_output_zip)) {
    return(mcl_count_read_zip_table(atlas_output_zip, c(paste0("(^|/)", gsub("[.]", "[.]", name), "$"))))
  }
  data.frame(stringsAsFactors = FALSE)
}

mcl_count_first_named_value <- function(df, names, default = "") {
  for (nm in names) {
    if (nm %in% names(df)) return(as.character(df[[nm]] %||% default))
  }
  rep(default, nrow(df))
}

mcl_count_atlas_input_audit <- function(atlas_output_dir = NULL, atlas_output_zip = NULL) {
  atlas_output_dir <- as.character(atlas_output_dir %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = ""))
  atlas_output_zip <- as.character(atlas_output_zip %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = ""))
  dir_ok <- nzchar(atlas_output_dir) && dir.exists(atlas_output_dir)
  zip_ok <- nzchar(atlas_output_zip) && file.exists(atlas_output_zip)
  supplied <- nzchar(atlas_output_dir) || nzchar(atlas_output_zip)
  selection_reason <- if (dir_ok) {
    "atlas_output_dir_supplied"
  } else if (zip_ok) {
    "atlas_output_zip_supplied"
  } else if (supplied) {
    "atlas_input_path_not_found"
  } else {
    "atlas_input_not_supplied"
  }
  selected_outputs_dir <- if (dir_ok) normalizePath(atlas_output_dir, winslash = "\\", mustWork = FALSE) else ""
  selected_atlas_run <- if (dir_ok) {
    basename(selected_outputs_dir)
  } else if (zip_ok) {
    tools::file_path_sans_ext(basename(atlas_output_zip))
  } else {
    ""
  }
  row_count <- function(name) {
    x <- mcl_count_read_atlas_output_table(name, atlas_output_dir = atlas_output_dir, atlas_output_zip = atlas_output_zip)
    if (is.data.frame(x)) nrow(x) else 0L
  }
  notes <- if (identical(selection_reason, "atlas_input_not_supplied")) {
    "No main atlas output ZIP or directory was supplied; atlas inventories may contain configured source-space candidates only."
  } else if (identical(selection_reason, "atlas_input_path_not_found")) {
    "Atlas input path was supplied but was not readable."
  } else {
    "Atlas input was supplied and searched for standalone probe source discovery."
  }
  mcl_count_match_empty(data.frame(
    atlas_output_zip = atlas_output_zip,
    atlas_output_dir = atlas_output_dir,
    atlas_input_supplied = supplied && (dir_ok || zip_ok),
    selected_atlas_run = selected_atlas_run,
    selected_outputs_dir = selected_outputs_dir,
    atlas_sources_rows = as.integer(row_count("atlas_sources.csv")),
    atlas_columns_rows = as.integer(row_count("atlas_columns.csv")),
    atlas_source_resolution_rows = as.integer(row_count("atlas_source_resolution.csv")),
    canonical_resource_reconciliation_rows = as.integer(row_count("canonical_resource_reconciliation_64.csv")),
    selection_reason = selection_reason,
    notes = notes,
    stringsAsFactors = FALSE
  ), mcl_count_empty_atlas_input_audit())
}

mcl_count_atlas_input_was_supplied <- function(atlas_input_audit) {
  is.data.frame(atlas_input_audit) && nrow(atlas_input_audit) &&
    mcl_count_bool(atlas_input_audit$atlas_input_supplied[[1]] %||% FALSE)
}

mcl_count_read_atlas_age_inventory <- function(atlas_output_dir = NULL, atlas_output_zip = NULL) {
  atlas_output_dir <- atlas_output_dir %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = "")
  atlas_output_zip <- atlas_output_zip %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = "")
  files <- c("atlas_sources.csv", "atlas_columns.csv", "atlas_column_profiles.csv", "atlas_source_resolution.csv", "canonical_resource_reconciliation_64.csv", "atlas_resource_catalog.csv")
  tables <- lapply(files, function(name) {
    x <- mcl_count_read_atlas_output_table(name, atlas_output_dir = atlas_output_dir, atlas_output_zip = atlas_output_zip)
    if (!is.data.frame(x) || !nrow(x)) return(data.frame(stringsAsFactors = FALSE))
    data.frame(
      db_name = mcl_count_first_named_value(x, c("db_name", "source_db_name", "database_name", "database")),
      schema = mcl_count_first_named_value(x, c("schema", "table_schema")),
      table = mcl_count_first_named_value(x, c("table", "table_name", "source_table", "resource_id", "source_name")),
      column_name = mcl_count_first_named_value(x, c("column_name", "field_name", "column", "raw_field")),
      data_type = mcl_count_first_named_value(x, c("data_type", "column_type", "column_class", "type")),
      atlas_file = name,
      stringsAsFactors = FALSE
    )
  })
  rows <- bind_rows_base(tables)
  if (!is.data.frame(rows) || !nrow(rows)) return(mcl_count_empty_atlas_age_source_inventory())
  rows$schema[!nzchar(rows$schema)] <- "public"
  rows$db_name[!nzchar(rows$db_name) & tolower(rows$table) == "patient"] <- "core"
  rows$db_name[!nzchar(rows$db_name) & tolower(rows$table) %in% c("rkkp_lyfo", "sds_t_tumor", "sds_pato")] <- "import"
  rows <- rows[nzchar(rows$table) & nzchar(rows$column_name), , drop = FALSE]
  if (!nrow(rows)) return(mcl_count_empty_atlas_age_source_inventory())
  col <- tolower(rows$column_name)
  tbl <- tolower(rows$table)
  relevant <- col %in% c("patientid", "date_birth", "date_death_fu", "d_fdsdato", "v_diagnosealder", "d_diagnosedato", "c_icd10", "reg_diagnostiskbiopsi_dt", "reg_behandlingbeslutning_dt", "beh_kemoterapistart_dt") |
    grepl("birth|foed|fod|fød|age|alder", col) |
    tbl %in% c("patient", "rkkp_lyfo", "sds_t_tumor", "sds_pato")
  rows <- unique(rows[relevant, , drop = FALSE])
  col <- tolower(rows$column_name)
  tbl <- tolower(rows$table)
  is_patient_key <- col == "patientid"
  is_birth <- col %in% c("date_birth", "birth_date", "d_fdsdato", "fodselsdato", "foedselsdato", paste0("f", "\u00f8", "dselsdato")) | grepl("birth|foed|fod|fød", col)
  is_age <- grepl("age|alder", col)
  is_anchor <- col %in% c("reg_diagnostiskbiopsi_dt", "reg_behandlingbeslutning_dt", "beh_kemoterapistart_dt", "d_diagnosedato")
  status <- ifelse(tbl == "patient" & rows$db_name == "core" & is_birth, "atlas_found_core_patient_birth_date",
                   ifelse(tbl == "rkkp_lyfo", "atlas_found_import_lyfo_no_lyfo_age_field",
                          ifelse(tbl == "sds_t_tumor" & col %in% c("d_fdsdato", "v_diagnosealder"), "same_db_birth_date_candidate_requires_validation", "atlas_age_discovery_evidence")))
  out <- data.frame(
    db_name = rows$db_name,
    schema = rows$schema,
    table = rows$table,
    column_name = rows$column_name,
    data_type = rows$data_type,
    source_role = ifelse(tbl == "sds_t_tumor", "import_same_db_birth_age_candidate", ifelse(tbl == "patient", "core_patient_demographics_death", ifelse(tbl == "rkkp_lyfo", "primary_mcl_registry", ""))),
    is_patient_key = is_patient_key,
    is_birth_date_like = is_birth,
    is_age_like = is_age,
    is_age_anchor_like = is_anchor,
    atlas_file = rows$atlas_file,
    evidence_status = status,
    notes = ifelse(status == "same_db_birth_date_candidate_requires_validation", "Atlas evidence only; production aggregate validation is required before age counts.", ""),
    stringsAsFactors = FALSE
  )
  mcl_count_match_empty(unique(out), mcl_count_empty_atlas_age_source_inventory())
}

mcl_count_columns_from_atlas_age_inventory <- function(inventory) {
  if (!is.data.frame(inventory) || !nrow(inventory)) return(data.frame(stringsAsFactors = FALSE))
  out <- data.frame(
    db_name = as.character(inventory$db_name %||% ""),
    schema = as.character(inventory$schema %||% "public"),
    table = as.character(inventory$table %||% ""),
    column_name = as.character(inventory$column_name %||% ""),
    data_type = as.character(inventory$data_type %||% ""),
    stringsAsFactors = FALSE
  )
  out[nzchar(out$table) & nzchar(out$column_name), , drop = FALSE]
}

mcl_count_normalize_treatment_source_id <- function(x) {
  x0 <- trimws(as.character(x %||% ""))
  xl <- tolower(gsub("[^a-z0-9]+", "_", x0, perl = TRUE))
  xl <- gsub("^_|_$", "", xl)
  out <- x0
  out[xl %in% c("ekokur", "sds_ekokur")] <- "SDS_ekokur"
  out[xl %in% c("sds_indberetningmedpris", "indberetningmedpris")] <- "SDS_indberetningmedpris"
  out[xl %in% c("sp_ordineretmedicin", "ordineretmedicin")] <- "SP_OrdineretMedicin"
  out[xl %in% c("sds_t_sksube", "t_sksube")] <- "SDS_t_sksube"
  out[xl %in% c("sds_t_adm", "t_adm")] <- "SDS_t_adm"
  out[xl %in% c("sds_epikur", "epikur")] <- "SDS_epikur"
  out[xl %in% c("rkkp_lyfo")] <- "RKKP_LYFO"
  out[xl %in% c("rkkp_cll")] <- "RKKP_CLL"
  out[xl %in% c("cll_treat_ibrutinib", "cll_treated_with_ibrutinib", "cll_treated_wtih_ibrutinib")] <- "CLL_TREAT_IBRUTINIB"
  out
}

mcl_count_treatment_source_defaults <- function(source_id) {
  source_id <- mcl_count_normalize_treatment_source_id(source_id)
  lower <- tolower(source_id)
  db <- ifelse(lower %in% c("cll_treat_ibrutinib"), "core", "import")
  schema <- ifelse(lower %in% c("cll_treat_ibrutinib"), "curated", "public")
  data.frame(
    source_id = source_id,
    db_name = db,
    schema = schema,
    table = source_id,
    stringsAsFactors = FALSE
  )
}

mcl_count_read_atlas_treatment_inventory <- function(atlas_output_dir = NULL, atlas_output_zip = NULL) {
  atlas_output_dir <- atlas_output_dir %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = "")
  atlas_output_zip <- atlas_output_zip %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = "")
  files <- c(
    "atlas_sources.csv",
    "atlas_columns.csv",
    "atlas_source_resolution.csv",
    "canonical_resource_reconciliation_64.csv",
    "atlas_semantic_code_map.csv",
    "atlas_panel_raw_fields.csv",
    "atlas_panel_distributions.csv",
    "atlas_column_top_values.csv",
    "atlas_semantic_value_map.csv",
    "cartography_disease_treatment_matrix.tsv",
    "cartography_sks_treatment_codes.tsv"
  )
  rows <- list()
  for (name in files) {
    x <- mcl_count_read_atlas_output_table(name, atlas_output_dir = atlas_output_dir, atlas_output_zip = atlas_output_zip)
    if (!is.data.frame(x) || !nrow(x)) next
    n <- nrow(x)
    source_raw <- mcl_count_first_named_value(x, c("source_name", "source", "resource_id", "table_name", "table", "object_name", "canonical_resource_id"), "")
    canonical <- mcl_count_normalize_treatment_source_id(source_raw)
    code <- mcl_count_first_named_value(x, c("code", "raw_code", "raw_value", "value", "display_value"), "")
    field <- mcl_count_first_named_value(x, c("field", "raw_field", "raw_column", "column_name", "column"), "")
    code_name <- mcl_count_first_named_value(x, c("code_name", "clinical_variable", "display_value", "clinical_interpretation", "value_name", "label"), "")
    code_system <- mcl_count_first_named_value(x, c("code_system", "system", "value_class"), "")
    text <- paste(canonical, source_raw, code, field, code_name, code_system, sep = " ")
    source_hit <- tolower(canonical) %in% tolower(c("SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin", "RKKP_CLL", "CLL_TREAT_IBRUTINIB", "RKKP_LYFO"))
    semantic_hit <- grepl("ibrutinib|imbruvica|btk|l01xe27|bwha169|beh_targeteretbeh_ibrutinib", text, ignore.case = TRUE, perl = TRUE)
    surface_hint <- source_hit & (
      grepl("atc|sks|c_opr|c_atc|ordineret|medicin|kemoterapiregime|targeteretbeh", field, ignore.case = TRUE, perl = TRUE) |
        grepl("sds_indberetningmedpris|sds_t_sksube|sds_epikur|sds_ekokur|sp_ordineretmedicin|rkkp_cll", canonical, ignore.case = TRUE, perl = TRUE)
    )
    hit <- (semantic_hit | surface_hint) & source_hit
    if (!any(hit, na.rm = TRUE)) next
    defaults <- mcl_count_treatment_source_defaults(canonical)
    rows[[length(rows) + 1L]] <- data.frame(
      source_id = canonical[hit],
      canonical_source_id = canonical[hit],
      db_name = defaults$db_name[match(canonical[hit], defaults$source_id)],
      schema = defaults$schema[match(canonical[hit], defaults$source_id)],
      table = defaults$table[match(canonical[hit], defaults$source_id)],
      field = field[hit],
      code_system = code_system[hit],
      code = code[hit],
      code_name = code_name[hit],
      atlas_file = name,
      atlas_rows = mcl_count_first_named_value(x, c("n_rows", "rows", "n"), "")[hit],
      atlas_patients = mcl_count_first_named_value(x, c("n_patients", "patients", "distinct_patients"), "")[hit],
      candidate_role = ifelse(canonical[hit] %in% c("RKKP_CLL", "CLL_TREAT_IBRUTINIB"), "auxiliary_treatment_evidence", ifelse(canonical[hit] == "SDS_t_sksube", "bridge_required_sks_source", "primary_treatment_evidence")),
      evidence_status = ifelse(grepl("bwha169", paste(code[hit], field[hit], code_name[hit]), ignore.case = TRUE), "atlas_confirmed_sks_ibrutinib_bridge_required",
                               ifelse(grepl("ibrutinib|imbruvica|btk|l01xe27|beh_targeteretbeh_ibrutinib", paste(code[hit], field[hit], code_name[hit], code_system[hit]), ignore.case = TRUE, perl = TRUE),
                                      "atlas_confirmed_ibrutinib_code_or_field",
                                      "atlas_treatment_source_surface_requires_code_validation")),
      counting_status = ifelse(canonical[hit] %in% c("RKKP_CLL", "CLL_TREAT_IBRUTINIB"), "auxiliary_not_primary_union", "requires_production_aggregate_validation"),
      notes = ifelse(canonical[hit] == "SDS_t_sksube", "SKS BWHA169 is atlas-confirmed Ibrutinib evidence; person counts require SDS_t_adm bridge validation.", "Atlas evidence only; production aggregate validation is required before counting."),
      stringsAsFactors = FALSE
    )
  }
  out <- bind_rows_base(rows)
  if (!is.data.frame(out) || !nrow(out)) return(mcl_count_empty_atlas_treatment_source_inventory())
  out <- unique(out)
  mcl_count_match_empty(out, mcl_count_empty_atlas_treatment_source_inventory())
}

mcl_count_normalize_ki67_source_id <- function(x) {
  x0 <- trimws(as.character(x %||% ""))
  xl <- tolower(gsub("[^a-z0-9]+", "_", x0, perl = TRUE))
  xl <- gsub("^_|_$", "", xl)
  out <- x0
  out[xl %in% c("pato", "sds_pato")] <- "SDS_pato"
  out[xl %in% c("t_mikro", "t_mikro_ny", "sds_t_mikro", "sds_t_mikro_ny")] <- "SDS_t_mikro_ny"
  out[xl %in% c("t_konk", "t_konk_ny", "sds_t_konk", "sds_t_konk_ny")] <- "SDS_t_konk_ny"
  out
}

mcl_count_ki67_source_specs <- function() {
  data.frame(
    source_channel = c(
      "coded_pathology",
      "pathology_free_text_embedded_in_pato",
      "microscopy_text",
      "conclusion_text"
    ),
    canonical_resource_id = c("pato", "pato", "t_mikro", "t_konk"),
    table_or_view = c("SDS_pato", "SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny"),
    display_table_name = c(
      "PATOBANK coded pathology",
      "PATOBANK coded pathology free text",
      "PATOBANK microscopy text",
      "PATOBANK conclusion text"
    ),
    column_name = c("c_snomedkode", "v_fritekst", "v_fritekst", "v_fritekst"),
    column_role = c("pathology_snomed_code", "pathology_free_text", "pathology_microscopy_text", "pathology_conclusion_text"),
    has_patientid = c(TRUE, TRUE, FALSE, FALSE),
    has_text = c(FALSE, TRUE, TRUE, TRUE),
    has_code = c(TRUE, FALSE, FALSE, FALSE),
    has_join_keys_to_pato = c(FALSE, FALSE, TRUE, TRUE),
    recommended_probe_action = c(
      "run_AEKI_numeric_percent_count",
      "run_redacted_aggregate_text_pattern_count_if_approved",
      "validate_text_to_pato_bridge_then_run_aggregate_text_pattern_count",
      "validate_text_to_pato_bridge_then_run_aggregate_text_pattern_count"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_count_read_atlas_ki67_inventory <- function(atlas_output_dir = NULL, atlas_output_zip = NULL) {
  atlas_output_dir <- atlas_output_dir %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = "")
  atlas_output_zip <- atlas_output_zip %||% Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = "")
  atlas_supplied <- (nzchar(as.character(atlas_output_dir)) && dir.exists(atlas_output_dir)) ||
    (nzchar(as.character(atlas_output_zip)) && file.exists(atlas_output_zip))
  files <- c(
    "atlas_sources.csv",
    "atlas_columns.csv",
    "atlas_column_profiles.csv",
    "atlas_panel_raw_fields.csv",
    "atlas_semantic_data_dictionary.csv",
    "atlas_semantic_code_map.csv",
    "atlas_resource_reconciliation.csv",
    "canonical_resource_reconciliation_64.csv",
    "atlas_source_resolution.csv",
    "source_map_row_to_canonical_resource_crosswalk.csv"
  )
  rows <- list()
  for (name in files) {
    x <- mcl_count_read_atlas_output_table(name, atlas_output_dir = atlas_output_dir, atlas_output_zip = atlas_output_zip)
    if (!is.data.frame(x) || !nrow(x)) next
    source_raw <- mcl_count_first_named_value(x, c("source_name", "source", "resource_id", "canonical_resource_id", "table_name", "table", "current_resolved_table_or_view", "current_table_or_view"), "")
    table_raw <- mcl_count_first_named_value(x, c("current_resolved_table_or_view", "table_or_view", "table_name", "table", "source_table", "resolved_table_or_view", "source"), "")
    canonical <- mcl_count_first_named_value(x, c("canonical_resource_id", "resource_id", "source_id"), "")
    normalized_table <- mcl_count_normalize_ki67_source_id(ifelse(nzchar(table_raw), table_raw, source_raw))
    source_text <- paste(source_raw, table_raw, canonical, sep = " ")
    hit <- normalized_table %in% c("SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny") |
      grepl("(^|[^a-z0-9])(pato|t_mikro|t_konk|sds_pato|sds_t_mikro|sds_t_konk)([^a-z0-9]|$)", source_text, ignore.case = TRUE, perl = TRUE)
    if (!any(hit, na.rm = TRUE)) next
    rows[[length(rows) + 1L]] <- data.frame(
      atlas_source_name = source_raw[hit],
      atlas_table_name = table_raw[hit],
      canonical_resource_id = ifelse(nzchar(canonical[hit]), canonical[hit], ifelse(normalized_table[hit] == "SDS_pato", "pato", ifelse(normalized_table[hit] == "SDS_t_mikro_ny", "t_mikro", "t_konk"))),
      db_name = mcl_count_first_named_value(x, c("db_name", "source_db_name", "database_name", "database"), "")[hit],
      schema = mcl_count_first_named_value(x, c("schema", "table_schema"), "")[hit],
      table_or_view = normalized_table[hit],
      display_table_name = mcl_count_first_named_value(x, c("display_table_name", "display_name", "label", "resource_label"), "")[hit],
      column_name = mcl_count_first_named_value(x, c("column_name", "field_name", "column", "raw_field"), "")[hit],
      current_profiled = mcl_count_bool(mcl_count_first_named_value(x, c("current_profiled", "profiled", "is_current"), "")[hit]),
      current_n_rows = mcl_count_first_named_value(x, c("current_n_rows", "n_rows", "rows"), "")[hit],
      current_n_columns = mcl_count_first_named_value(x, c("current_n_columns", "n_columns", "columns"), "")[hit],
      atlas_evidence_file = name,
      stringsAsFactors = FALSE
    )
  }
  atlas_rows <- bind_rows_base(rows)
  specs <- mcl_count_ki67_source_specs()
  out <- lapply(seq_len(nrow(specs)), function(i) {
    spec <- specs[i, , drop = FALSE]
    hit <- atlas_rows[atlas_rows$table_or_view == spec$table_or_view[[1]], , drop = FALSE]
    col_hit <- hit
    if (nrow(col_hit) && nzchar(spec$column_name[[1]])) {
      with_col <- col_hit[tolower(col_hit$column_name %||% "") == tolower(spec$column_name[[1]]), , drop = FALSE]
      if (nrow(with_col)) col_hit <- with_col
    }
    atlas_found <- nrow(hit) > 0L
    column_found <- nrow(col_hit) > 0L && (nzchar(col_hit$column_name[[1]] %||% "") || any(!nzchar(hit$column_name %||% "")))
    first <- if (nrow(col_hit)) col_hit[1, , drop = FALSE] else data.frame(stringsAsFactors = FALSE)
    db_name <- as.character(first$db_name[[1]] %||% "")
    if (!nzchar(db_name)) db_name <- "import"
    schema <- as.character(first$schema[[1]] %||% "")
    if (!nzchar(schema)) schema <- "public"
    current_profiled <- if (nrow(hit)) any(hit$current_profiled %in% TRUE, na.rm = TRUE) else FALSE
    evidence_state <- if (!atlas_found) {
      "source_space_only_not_ki67_evidence"
    } else if (identical(spec$source_channel[[1]], "coded_pathology")) {
      "atlas_profiled_source_space_only"
    } else {
      "atlas_profiled_source_space_only"
    }
    countability <- if (!atlas_found && atlas_supplied) {
      "atlas_source_not_found_in_supplied_outputs"
    } else if (!atlas_found) {
      "atlas_input_not_supplied_source_space_candidate"
    } else if (identical(spec$source_channel[[1]], "coded_pathology")) {
      "coded_aeki_numeric_percent_requires_codebook_validation"
    } else if (identical(spec$source_channel[[1]], "pathology_free_text_embedded_in_pato")) {
      "text_pattern_numeric_candidate_requires_validation"
    } else {
      "not_countable_no_person_linkage"
    }
    data.frame(
      source_channel = spec$source_channel[[1]],
      atlas_source_name = as.character(first$atlas_source_name[[1]] %||% spec$table_or_view[[1]]),
      atlas_table_name = as.character(first$atlas_table_name[[1]] %||% spec$table_or_view[[1]]),
      canonical_resource_id = spec$canonical_resource_id[[1]],
      db_name = db_name,
      schema = schema,
      table_or_view = spec$table_or_view[[1]],
      display_table_name = if (nzchar(first$display_table_name[[1]] %||% "")) first$display_table_name[[1]] else spec$display_table_name[[1]],
      column_name = spec$column_name[[1]],
      column_role = spec$column_role[[1]],
      has_patientid = spec$has_patientid[[1]],
      has_text = spec$has_text[[1]],
      has_code = spec$has_code[[1]],
      has_join_keys_to_pato = spec$has_join_keys_to_pato[[1]],
      same_db_as_lyfo = tolower(db_name) %in% c("", "import"),
      current_profiled = current_profiled || atlas_found,
      current_n_rows = as.character(first$current_n_rows[[1]] %||% ""),
      current_n_columns = as.character(first$current_n_columns[[1]] %||% ""),
      atlas_evidence_file = if (nrow(hit)) paste(unique(hit$atlas_evidence_file), collapse = "; ") else "",
      evidence_state = evidence_state,
      countability_status = countability,
      recommended_probe_action = spec$recommended_probe_action[[1]],
      notes = if (!atlas_found && atlas_supplied) {
        "Configured Ki-67 source-space candidate; not found in supplied atlas evidence."
      } else if (!atlas_found) {
        "Configured Ki-67 source-space candidate; no atlas input was supplied for confirmation."
      } else if (!column_found) {
        "Atlas profiled the source table; expected column should still be validated by production zero-row probes."
      } else {
        "Atlas source-space evidence only; not treated as validated Ki-67 evidence without aggregate production validation."
      },
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(out)
  if (!is.data.frame(out) || !nrow(out)) return(mcl_count_empty_atlas_ki67_source_inventory())
  mcl_count_match_empty(unique(out), mcl_count_empty_atlas_ki67_source_inventory())
}

mcl_count_ki67_threshold_percent <- function(project_root = ".", threshold_percent = NULL) {
  value <- suppressWarnings(as.integer(threshold_percent %||% NA_integer_))
  if (!is.na(value) && value >= 0L && value <= 100L) return(value)
  value <- tryCatch(mcl_count_high_risk_threshold(project_root), error = function(e) 30L)
  value <- suppressWarnings(as.integer(value))
  if (is.na(value) || value < 0L || value > 100L) 30L else value
}

mcl_count_ki67_aeki_normalized_sql <- function(alias = "p") {
  code_expr <- paste0("trim(", alias, ".", mcl_count_sql_ident("c_snomedkode"), "::text)")
  return(paste0(
    "upper(replace(replace(replace(replace(", code_expr,
    ", 'Æ', 'AE'), 'Ã†', 'AE'), 'Ãƒâ€ ', 'AE'), 'ÃƒÆ’Ã¢â‚¬Â ', 'AE'))"
  ))
  paste0(
    "upper(replace(replace(trim(", alias, ".", mcl_count_sql_ident("c_snomedkode"),
    "::text), 'Ã†', 'AE'), 'Ãƒâ€ ', 'AE'))"
  )
}

mcl_count_ki67_base_ctes <- function(pdm) {
  lyfo <- mcl_count_source_mapping(pdm, "RKKP_LYFO")
  pato <- mcl_count_source_mapping(pdm, "SDS_pato")
  if (!mcl_count_mapping_usable(lyfo) || !mcl_count_mapping_usable(pato)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  pato_ref <- mcl_count_sql_table(pato$schema[[1]], pato$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  pato_key <- mcl_count_sql_ident(pato$person_key_column[[1]])
  norm <- mcl_count_ki67_aeki_normalized_sql("p")
  paste0(
    "with mcl as (\n",
    "  select distinct r.", lyfo_key, " as person_key\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), pato_codes as (\n",
    "  select p.", pato_key, " as person_key,\n",
    "         ", norm, " as normalized_code\n",
    "  from ", pato_ref, " p\n",
    "  join mcl on mcl.person_key = p.", pato_key, "\n",
    "), aeki_rows as (\n",
    "  select person_key,\n",
    "         normalized_code,\n",
    "         substring(normalized_code from 'AEKI([0-9]{3})')::integer as parsed_percent\n",
    "  from pato_codes\n",
    "  where normalized_code ~ '^AEKI[0-9]{3}$'\n",
    "    and substring(normalized_code from 'AEKI([0-9]{3})')::integer between 0 and 100\n",
    "), aeki_person as (\n",
    "  select person_key,\n",
    "         max(parsed_percent) as max_ki67_percent,\n",
    "         min(parsed_percent) as min_ki67_percent,\n",
    "         count(distinct normalized_code) as n_distinct_aeki_codes\n",
    "  from aeki_rows\n",
    "  group by person_key\n",
    ")"
  )
}

mcl_count_ki67_aeki_code_sql <- function(pdm) {
  ctes <- mcl_count_ki67_base_ctes(pdm)
  if (!nzchar(ctes)) return("")
  paste0(
    ctes, "\n",
    "select normalized_code,\n",
    "       parsed_percent,\n",
    "       count(*) as pathology_code_rows,\n",
    "       count(distinct person_key) as mcl_distinct_people\n",
    "from aeki_rows\n",
    "group by normalized_code, parsed_percent\n",
    "order by parsed_percent;"
  )
}

mcl_count_ki67_aeki_person_sql <- function(pdm, threshold_percent = 30L) {
  ctes <- mcl_count_ki67_base_ctes(pdm)
  if (!nzchar(ctes)) return("")
  paste0(
    ctes, ", joined as (\n",
    "  select mcl.person_key, aeki_person.max_ki67_percent, aeki_person.min_ki67_percent, aeki_person.n_distinct_aeki_codes\n",
    "  from mcl\n",
    "  left join aeki_person on aeki_person.person_key = mcl.person_key\n",
    ")\n",
    "select count(*) as mcl_people,\n",
    "       count(*) filter (where max_ki67_percent is not null) as ki67_aeki_known_people,\n",
    "       count(*) filter (where max_ki67_percent >= ", as.integer(threshold_percent), ") as ki67_aeki_ge_threshold_people,\n",
    "       count(*) filter (where max_ki67_percent >= 50) as ki67_aeki_ge_50_people,\n",
    "       count(*) filter (where max_ki67_percent is null) as ki67_aeki_missing_people,\n",
    "       count(*) filter (where n_distinct_aeki_codes > 1) as people_with_multiple_aeki_codes\n",
    "from joined;"
  )
}

mcl_count_ki67_percent_distribution_sql <- function(pdm) {
  ctes <- mcl_count_ki67_base_ctes(pdm)
  if (!nzchar(ctes)) return("")
  paste0(
    ctes, "\n",
    "select parsed_percent,\n",
    "       count(distinct person_key) as distinct_person_count\n",
    "from aeki_rows\n",
    "group by parsed_percent\n",
    "order by parsed_percent;"
  )
}

mcl_count_ki67_text_pattern_regex <- function() {
  "(ki[-[:space:]]?67|mib[-[:space:]]?1|proliferationsindeks|proliferations[-[:space:]]?index)"
}

mcl_count_ki67_direct_text_pattern_sql <- function(pdm) {
  lyfo <- mcl_count_source_mapping(pdm, "RKKP_LYFO")
  pato <- mcl_count_source_mapping(pdm, "SDS_pato")
  if (!mcl_count_mapping_usable(lyfo) || !mcl_count_mapping_usable(pato)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  pato_ref <- mcl_count_sql_table(pato$schema[[1]], pato$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  pato_key <- mcl_count_sql_ident(pato$person_key_column[[1]])
  text_col <- mcl_count_sql_ident("v_fritekst")
  term <- mcl_count_ki67_text_pattern_regex()
  paste0(
    "with mcl as (\n",
    "  select distinct r.", lyfo_key, " as person_key\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), text_rows as (\n",
    "  select p.", pato_key, " as person_key, p.", text_col, "::text as text_value\n",
    "  from ", pato_ref, " p\n",
    "  join mcl on mcl.person_key = p.", pato_key, "\n",
    "  where p.", text_col, " is not null\n",
    ")\n",
    "select 'exact_numeric_percent' as value_class, count(distinct person_key) as aggregate_count from text_rows where text_value ~* '", term, ".{0,80}[0-9]{1,3}([,.][0-9]+)?[[:space:]]*%'\n",
    "union all\n",
    "select 'range_percent' as value_class, count(distinct person_key) as aggregate_count from text_rows where text_value ~* '", term, ".{0,80}[0-9]{1,3}[[:space:]]*[-â€“][[:space:]]*[0-9]{1,3}[[:space:]]*%'\n",
    "union all\n",
    "select 'inequality_percent' as value_class, count(distinct person_key) as aggregate_count from text_rows where text_value ~* '", term, ".{0,80}[<>â‰¤â‰¥][[:space:]]*[0-9]{1,3}([,.][0-9]+)?[[:space:]]*%'\n",
    "union all\n",
    "select 'qualitative_mention_only' as value_class, count(distinct person_key) as aggregate_count from text_rows where text_value ~* '", term, ".{0,80}(positiv|positive|farvning|immunhistokemi|ihc)'\n",
    "union all\n",
    "select 'unknown_or_not_stated' as value_class, count(distinct person_key) as aggregate_count from text_rows where text_value ~* '", term, ".{0,80}(ikke angivet|ukendt|unknown|not stated)';"
  )
}

mcl_count_ki67_bridge_validation_sql <- function(pdm, text_table) {
  lyfo <- mcl_count_source_mapping(pdm, "RKKP_LYFO")
  pato <- mcl_count_source_mapping(pdm, "SDS_pato")
  if (!mcl_count_mapping_usable(lyfo) || !mcl_count_mapping_usable(pato)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  pato_ref <- mcl_count_sql_table(pato$schema[[1]], pato$table[[1]])
  text_ref <- mcl_count_sql_table(pato$schema[[1]], text_table)
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  pato_key <- mcl_count_sql_ident(pato$person_key_column[[1]])
  keys <- c("k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr")
  join_sql <- paste(
    vapply(keys, function(key) paste0("pk.", mcl_count_sql_ident(key), " = t.", mcl_count_sql_ident(key)), character(1)),
    collapse = "\n   and "
  )
  term <- mcl_count_ki67_text_pattern_regex()
  paste0(
    "with mcl as (\n",
    "  select distinct r.", lyfo_key, " as person_key\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), pato_keys as (\n",
    "  select distinct p.", pato_key, " as person_key, p.", mcl_count_sql_ident("k_inst"), ", p.", mcl_count_sql_ident("k_rekvnr"), ", p.", mcl_count_sql_ident("k_matnr"), ", p.", mcl_count_sql_ident("k_sekvensnr"), "\n",
    "  from ", pato_ref, " p\n",
    "  join mcl on mcl.person_key = p.", pato_key, "\n",
    "), text_rows as (\n",
    "  select t.", mcl_count_sql_ident("k_inst"), ", t.", mcl_count_sql_ident("k_rekvnr"), ", t.", mcl_count_sql_ident("k_matnr"), ", t.", mcl_count_sql_ident("k_sekvensnr"), ", t.", mcl_count_sql_ident("v_fritekst"), "::text as text_value\n",
    "  from ", text_ref, " t\n",
    "), linked as (\n",
    "  select pk.person_key, t.text_value\n",
    "  from text_rows t\n",
    "  join pato_keys pk on ", join_sql, "\n",
    "), text_hits as (\n",
    "  select distinct person_key\n",
    "  from linked\n",
    "  where text_value ~* '", term, ".{0,80}[0-9]{1,3}([,.][0-9]+)?[[:space:]]*%'\n",
    ")\n",
    "select (select count(*) from text_rows) as text_rows_total,\n",
    "       (select count(*) from text_rows where text_value is not null and length(trim(text_value)) > 0) as text_rows_with_non_missing_text,\n",
    "       (select count(*) from linked) as text_rows_linked_to_sds_pato,\n",
    "       (select count(distinct person_key) from linked) as text_rows_linked_to_patientid,\n",
    "       (select count(*) from text_hits) as mcl_linked_text_hit_people;"
  )
}

mcl_count_ki67_query_templates <- function(pdm, threshold_percent = 30L, include_text_templates = TRUE) {
  blocks <- c(
    "-- query_id: mcl_triangle_ki67_aeki_code_counts\n-- Aggregate-only AEKI000-AEKI100 code counts; no pathology text emitted.",
    mcl_count_ki67_aeki_code_sql(pdm),
    "-- query_id: mcl_triangle_ki67_aeki_person_and_threshold_counts\n-- Aggregate-only Ki-67 known/high/missing counts; source validation still required.",
    mcl_count_ki67_aeki_person_sql(pdm, threshold_percent),
    "-- query_id: mcl_triangle_ki67_percent_distribution\n-- Aggregate-only Ki-67 parsed-percent distribution for validated AEKI codes.",
    mcl_count_ki67_percent_distribution_sql(pdm)
  )
  if (isTRUE(include_text_templates)) {
    blocks <- c(
      blocks,
      "-- query_id: mcl_triangle_ki67_sds_pato_text_pattern_counts\n-- TEMPLATE ONLY unless MCL_TRIANGLE_KI67_TEXT_SCAN is true. Aggregate counts only; no raw text/snippets.",
      mcl_count_ki67_direct_text_pattern_sql(pdm),
      "-- query_id: mcl_triangle_ki67_t_mikro_text_bridge_validation\n-- TEMPLATE ONLY unless MCL_TRIANGLE_KI67_TEXT_SCAN is true. Aggregate bridge validation only.",
      mcl_count_ki67_bridge_validation_sql(pdm, "SDS_t_mikro_ny"),
      "-- query_id: mcl_triangle_ki67_t_konk_text_bridge_validation\n-- TEMPLATE ONLY unless MCL_TRIANGLE_KI67_TEXT_SCAN is true. Aggregate bridge validation only.",
      mcl_count_ki67_bridge_validation_sql(pdm, "SDS_t_konk_ny")
    )
  }
  paste(blocks[nzchar(blocks)], collapse = "\n\n")
}

mcl_count_ki67_query_review_rows <- function(pdm, threshold_percent = 30L, text_scan = FALSE) {
  code_executable <- nzchar(mcl_count_ki67_aeki_code_sql(pdm))
  text_executable <- isTRUE(text_scan) && nzchar(mcl_count_ki67_direct_text_pattern_sql(pdm))
  rows <- list(
    data.frame(query_id = "mcl_triangle_ki67_aeki_code_counts", output_file = "mcl_triangle_ki67_aeki_code_counts.csv", denominator = "all_lyfo_mcl", data_point = "ki67_aeki", timing_window = "ever_available", tables_used = "RKKP_LYFO; SDS_pato", person_key_used = "patientid", date_anchor_used = "", value_rule_used = "AEKI000-AEKI100", small_cell_suppression_applied = TRUE, emits_only_aggregate_counts = TRUE, query_executable = code_executable, reviewer_notes = "Aggregate AEKI code count query.", stringsAsFactors = FALSE),
    data.frame(query_id = "mcl_triangle_ki67_threshold_counts", output_file = "mcl_triangle_ki67_threshold_counts.csv", denominator = "all_lyfo_mcl", data_point = "ki67_aeki", timing_window = "ever_available", tables_used = "RKKP_LYFO; SDS_pato", person_key_used = "patientid", date_anchor_used = "", value_rule_used = paste0("AEKI parsed percent >= ", threshold_percent), small_cell_suppression_applied = TRUE, emits_only_aggregate_counts = TRUE, query_executable = code_executable, reviewer_notes = "Aggregate Ki-67 threshold query; does not infer standard-risk biology.", stringsAsFactors = FALSE),
    data.frame(query_id = "mcl_triangle_ki67_text_pattern_counts", output_file = "mcl_triangle_ki67_text_pattern_counts.csv", denominator = "all_lyfo_mcl", data_point = "ki67_text_numeric_candidate", timing_window = "ever_available", tables_used = "SDS_pato; SDS_t_mikro_ny; SDS_t_konk_ny", person_key_used = "patientid via SDS_pato where validated", date_anchor_used = "", value_rule_used = "Ki-67/MIB/proliferation aggregate text patterns", small_cell_suppression_applied = TRUE, emits_only_aggregate_counts = TRUE, query_executable = text_executable, reviewer_notes = if (text_executable) "Text scan explicitly enabled; no raw text emitted." else "Text scan disabled; template only.", stringsAsFactors = FALSE)
  )
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_query_review())
}

mcl_count_ki67_planned_text_bridge_rows <- function(inventory, text_scan = FALSE) {
  inv <- inventory
  if (!is.data.frame(inv) || !nrow(inv)) inv <- mcl_count_empty_atlas_ki67_source_inventory()
  text_sources <- inv[inv$source_channel %in% c("microscopy_text", "conclusion_text"), , drop = FALSE]
  if (!nrow(text_sources)) {
    specs <- mcl_count_ki67_source_specs()
    text_sources <- data.frame(
      source_channel = specs$source_channel[specs$source_channel %in% c("microscopy_text", "conclusion_text")],
      schema = "public",
      table_or_view = specs$table_or_view[specs$source_channel %in% c("microscopy_text", "conclusion_text")],
      column_name = "v_fritekst",
      stringsAsFactors = FALSE
    )
  }
  rows <- lapply(seq_len(nrow(text_sources)), function(i) {
    data.frame(
      text_source = text_sources$source_channel[[i]],
      schema = text_sources$schema[[i]] %||% "public",
      table_or_view = text_sources$table_or_view[[i]],
      text_column = text_sources$column_name[[i]] %||% "v_fritekst",
      join_key_columns = "k_inst; k_rekvnr; k_matnr; k_sekvensnr",
      text_rows_total = "",
      text_rows_with_non_missing_text = "",
      text_rows_linked_to_sds_pato = "",
      text_rows_linked_to_patientid = "",
      mcl_linked_text_hit_people = "",
      query_attempted = FALSE,
      query_success = FALSE,
      bridge_status = "atlas_found_text_source_bridge_candidate",
      validation_status = if (isTRUE(text_scan)) "text_scan_enabled_pending_execution" else "text_pattern_query_template_only",
      error_message_sanitized = "",
      notes = "Pathology text source has no direct patientid; bridge to SDS_pato must be validated before text-pattern counts can contribute.",
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_text_bridge_validation())
}

mcl_count_ki67_plan_outputs <- function(inventory, threshold_percent = 30L, text_scan = FALSE) {
  bridge <- mcl_count_ki67_planned_text_bridge_rows(inventory, text_scan = text_scan)
  source_validation <- if (is.data.frame(inventory) && nrow(inventory)) {
    data.frame(
      source_channel = inventory$source_channel,
      db_name = inventory$db_name,
      schema = inventory$schema,
      table_or_view = inventory$table_or_view,
      column_name = inventory$column_name,
      validation_query_attempted = FALSE,
      validation_query_success = FALSE,
      validation_status = ifelse(inventory$has_text, "text_pattern_query_template_only", "atlas_profiled_source_space_only"),
      selected_for_numeric_union = FALSE,
      error_message_sanitized = "",
      notes = "Atlas inventory/source-space row; aggregate production validation has not selected this source.",
      stringsAsFactors = FALSE
    )
  } else {
    mcl_count_empty_ki67_source_validation()
  }
  threshold <- data.frame(
    denominator = "all_lyfo_mcl",
    threshold_percent = as.integer(threshold_percent),
    metric = c("ki67_aeki_known", "ki67_aeki_ge_threshold", "ki67_aeki_ge_50", "ki67_aeki_missing_not_found"),
    distinct_person_count_display = "",
    percent_of_denominator_display = "",
    validation_status = "ki67_threshold_unavailable_requires_dedicated_query",
    count_status = "count_not_available_requires_production_validation",
    notes = "Ki-67 threshold counts require aggregate production AEKI query; missing Ki-67 is not standard-risk evidence.",
    stringsAsFactors = FALSE
  )
  list(
    ki67_source_validation = mcl_count_match_empty(source_validation, mcl_count_empty_ki67_source_validation()),
    ki67_aeki_code_counts = mcl_count_empty_ki67_aeki_code_counts(),
    ki67_aeki_person_counts = mcl_count_empty_ki67_aeki_person_counts(),
    ki67_percent_distribution = mcl_count_empty_ki67_percent_distribution(),
    ki67_threshold_counts = mcl_count_match_empty(threshold, mcl_count_empty_ki67_threshold_counts()),
    ki67_text_bridge_validation = bridge,
    ki67_text_pattern_counts = mcl_count_empty_ki67_text_pattern_counts(),
    ki67_text_person_counts = mcl_count_empty_ki67_text_person_counts(),
    ki67_union_counts = mcl_count_empty_ki67_union_counts(),
    ki67_overlap_by_source = mcl_count_empty_ki67_overlap_by_source(),
    stats = list(attempted = 0L, failed = 0L)
  )
}

mcl_count_ki67_display <- function(n, denom = NA, min_cell_count = 5L) {
  count <- mcl_count_suppress(n, min_cell_count)
  list(
    display = count$display,
    status = mcl_count_production_status(count$status),
    percent = if (!is.na(suppressWarnings(as.numeric(denom)))) mcl_count_percent_display(n, denom, min_cell_count) else "",
    suppressed = count$suppressed
  )
}

mcl_count_execute_ki67_outputs <- function(db_adapter, pdm, inventory, threshold_percent = 30L,
                                           text_scan = FALSE, min_cell_count = 5L) {
  out <- mcl_count_ki67_plan_outputs(inventory, threshold_percent = threshold_percent, text_scan = text_scan)
  stats <- list(attempted = 0L, failed = 0L)
  run_query <- function(sql) {
    stats$attempted <<- stats$attempted + 1L
    result <- mcl_count_db_query_result(db_adapter, sql)
    if (!is.data.frame(result$data)) stats$failed <<- stats$failed + 1L
    result
  }
  code_sql <- mcl_count_ki67_aeki_code_sql(pdm)
  person_sql <- mcl_count_ki67_aeki_person_sql(pdm, threshold_percent)
  dist_sql <- mcl_count_ki67_percent_distribution_sql(pdm)
  code_result <- if (nzchar(code_sql)) run_query(code_sql) else list(data = NULL, error_message_sanitized = "SDS_pato/RKKP_LYFO mapping unavailable.")
  person_result <- if (nzchar(person_sql)) run_query(person_sql) else list(data = NULL, error_message_sanitized = "SDS_pato/RKKP_LYFO mapping unavailable.")
  dist_result <- if (nzchar(dist_sql)) run_query(dist_sql) else list(data = NULL, error_message_sanitized = "SDS_pato/RKKP_LYFO mapping unavailable.")
  has_cols <- function(df, cols) is.data.frame(df) && nrow(df) && all(cols %in% names(df))
  if (has_cols(code_result$data, c("normalized_code", "parsed_percent", "pathology_code_rows", "mcl_distinct_people"))) {
    rows <- lapply(seq_len(nrow(code_result$data)), function(i) {
      row_count <- mcl_count_ki67_display(code_result$data$pathology_code_rows[[i]], NA, min_cell_count)
      person_count <- mcl_count_ki67_display(code_result$data$mcl_distinct_people[[i]], NA, min_cell_count)
      data.frame(
        db_name = "import",
        schema = "public",
        table_or_view = "SDS_pato",
        code_column = "c_snomedkode",
        normalized_code = as.character(code_result$data$normalized_code[[i]] %||% ""),
        parsed_percent = suppressWarnings(as.integer(code_result$data$parsed_percent[[i]] %||% NA_integer_)),
        pathology_code_rows_display = row_count$display,
        mcl_distinct_people_display = person_count$display,
        validation_status = "coded_aeki_numeric_percent_validated_aggregate",
        count_status = person_count$status,
        notes = "Aggregate coded Ki-67 AEKI count; no pathology text or row identifiers emitted.",
        stringsAsFactors = FALSE
      )
    })
    out$ki67_aeki_code_counts <- mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_aeki_code_counts())
  }
  mcl_people <- NA_real_
  if (has_cols(person_result$data, c("mcl_people", "ki67_aeki_known_people", "ki67_aeki_ge_threshold_people", "ki67_aeki_ge_50_people", "ki67_aeki_missing_people", "people_with_multiple_aeki_codes"))) {
    pr <- person_result$data[1, , drop = FALSE]
    mcl_people <- suppressWarnings(as.numeric(pr$mcl_people[[1]] %||% NA_real_))
    metrics <- data.frame(
      metric = c("ki67_aeki_known", "ki67_aeki_ge_threshold", "ki67_aeki_ge_50", "ki67_aeki_missing_not_found", "people_with_multiple_aeki_codes"),
      value = c(
        pr$ki67_aeki_known_people[[1]] %||% NA,
        pr$ki67_aeki_ge_threshold_people[[1]] %||% NA,
        pr$ki67_aeki_ge_50_people[[1]] %||% NA,
        pr$ki67_aeki_missing_people[[1]] %||% NA,
        pr$people_with_multiple_aeki_codes[[1]] %||% NA
      ),
      stringsAsFactors = FALSE
    )
    person_rows <- lapply(seq_len(nrow(metrics)), function(i) {
      disp <- mcl_count_ki67_display(metrics$value[[i]], mcl_people, min_cell_count)
      data.frame(
        denominator = "all_lyfo_mcl",
        timing_window = "ever_available",
        metric = metrics$metric[[i]],
        distinct_person_count_display = disp$display,
        percent_of_denominator_display = disp$percent,
        validation_status = "coded_aeki_numeric_percent_count_available",
        count_status = disp$status,
        notes = "Distinct MCL person aggregate from SDS_pato AEKI codes; source semantics still require clinical/codebook validation.",
        stringsAsFactors = FALSE
      )
    })
    out$ki67_aeki_person_counts <- mcl_count_match_empty(bind_rows_base(person_rows), mcl_count_empty_ki67_aeki_person_counts())
    threshold_rows <- lapply(seq_len(nrow(metrics[metrics$metric %in% c("ki67_aeki_known", "ki67_aeki_ge_threshold", "ki67_aeki_ge_50", "ki67_aeki_missing_not_found"), , drop = FALSE])), function(i) {
      metric_df <- metrics[metrics$metric %in% c("ki67_aeki_known", "ki67_aeki_ge_threshold", "ki67_aeki_ge_50", "ki67_aeki_missing_not_found"), , drop = FALSE]
      disp <- mcl_count_ki67_display(metric_df$value[[i]], mcl_people, min_cell_count)
      data.frame(
        denominator = "all_lyfo_mcl",
        threshold_percent = as.integer(threshold_percent),
        metric = metric_df$metric[[i]],
        distinct_person_count_display = disp$display,
        percent_of_denominator_display = disp$percent,
        validation_status = if (identical(metric_df$metric[[i]], "ki67_aeki_ge_threshold")) "coded_aeki_threshold_count_available" else "coded_aeki_numeric_percent_count_available",
        count_status = disp$status,
        notes = if (identical(metric_df$metric[[i]], "ki67_aeki_missing_not_found")) "Missing Ki-67 must not be interpreted as standard risk." else "Aggregate AEKI threshold/knownness count; source-specific validation still required.",
        stringsAsFactors = FALSE
      )
    })
    out$ki67_threshold_counts <- mcl_count_match_empty(bind_rows_base(threshold_rows), mcl_count_empty_ki67_threshold_counts())
  }
  if (has_cols(dist_result$data, c("parsed_percent", "distinct_person_count"))) {
    rows <- lapply(seq_len(nrow(dist_result$data)), function(i) {
      disp <- mcl_count_ki67_display(dist_result$data$distinct_person_count[[i]], mcl_people, min_cell_count)
      data.frame(
        denominator = "all_lyfo_mcl",
        parsed_percent = suppressWarnings(as.integer(dist_result$data$parsed_percent[[i]] %||% NA_integer_)),
        distinct_person_count_display = disp$display,
        percent_of_denominator_display = disp$percent,
        validation_status = "coded_aeki_numeric_percent_validated_aggregate",
        count_status = disp$status,
        notes = "Aggregate parsed AEKI percent distribution; exact small cells suppressed.",
        stringsAsFactors = FALSE
      )
    })
    out$ki67_percent_distribution <- mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_percent_distribution())
  }
  if (isTRUE(text_scan)) {
    text_sql <- mcl_count_ki67_direct_text_pattern_sql(pdm)
    text_result <- if (nzchar(text_sql)) run_query(text_sql) else list(data = NULL, error_message_sanitized = "SDS_pato text mapping unavailable.")
    if (has_cols(text_result$data, c("value_class", "aggregate_count"))) {
      rows <- lapply(seq_len(nrow(text_result$data)), function(i) {
        disp <- mcl_count_ki67_display(text_result$data$aggregate_count[[i]], NA, min_cell_count)
        data.frame(
          source_channel = "pathology_free_text_embedded_in_pato",
          schema = "public",
          table_or_view = "SDS_pato",
          text_column = "v_fritekst",
          pattern_name = as.character(text_result$data$value_class[[i]] %||% ""),
          value_class = as.character(text_result$data$value_class[[i]] %||% ""),
          aggregate_count_display = disp$display,
          validation_status = "text_pattern_numeric_candidate_requires_validation",
          count_status = disp$status,
          notes = "Aggregate text-pattern count only; no raw pathology text or snippets emitted.",
          stringsAsFactors = FALSE
        )
      })
      out$ki67_text_pattern_counts <- mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_text_pattern_counts())
    }
    bridge_rows <- list()
    for (text_table in c("SDS_t_mikro_ny", "SDS_t_konk_ny")) {
      sql <- mcl_count_ki67_bridge_validation_sql(pdm, text_table)
      result <- if (nzchar(sql)) run_query(sql) else list(data = NULL, error_message_sanitized = "Bridge mapping unavailable.")
      success <- has_cols(result$data, c("text_rows_total", "text_rows_with_non_missing_text", "text_rows_linked_to_sds_pato", "text_rows_linked_to_patientid", "mcl_linked_text_hit_people"))
      if (!success) {
        stats$failed <- stats$failed + if (nzchar(sql)) 0L else 1L
      }
      dat <- if (success) result$data[1, , drop = FALSE] else data.frame(stringsAsFactors = FALSE)
      source_channel <- if (identical(text_table, "SDS_t_mikro_ny")) "microscopy_text" else "conclusion_text"
      hit <- if (success) suppressWarnings(as.numeric(dat$mcl_linked_text_hit_people[[1]] %||% NA_real_)) else NA_real_
      bridge_rows[[length(bridge_rows) + 1L]] <- data.frame(
        text_source = source_channel,
        schema = "public",
        table_or_view = text_table,
        text_column = "v_fritekst",
        join_key_columns = "k_inst; k_rekvnr; k_matnr; k_sekvensnr",
        text_rows_total = as.character(dat$text_rows_total[[1]] %||% ""),
        text_rows_with_non_missing_text = as.character(dat$text_rows_with_non_missing_text[[1]] %||% ""),
        text_rows_linked_to_sds_pato = as.character(dat$text_rows_linked_to_sds_pato[[1]] %||% ""),
        text_rows_linked_to_patientid = as.character(dat$text_rows_linked_to_patientid[[1]] %||% ""),
        mcl_linked_text_hit_people = if (success) mcl_count_ki67_display(hit, NA, min_cell_count)$display else "",
        query_attempted = nzchar(sql),
        query_success = success,
        bridge_status = if (success) "atlas_text_bridge_validated" else "atlas_text_bridge_failed",
        validation_status = if (success) "text_pattern_count_available_requires_validation" else "not_countable_bridge_validation_failed",
        error_message_sanitized = result$error_message_sanitized %||% "",
        notes = "Aggregate bridge validation only; text-derived numeric Ki-67 remains candidate evidence until extraction validation.",
        stringsAsFactors = FALSE
      )
    }
    out$ki67_text_bridge_validation <- mcl_count_match_empty(bind_rows_base(bridge_rows), mcl_count_empty_ki67_text_bridge_validation())
  }
  out$ki67_source_validation <- mcl_count_ki67_source_validation_from_outputs(inventory, out, text_scan = text_scan)
  out$ki67_union_counts <- mcl_count_ki67_union_counts_from_outputs(out, min_cell_count = min_cell_count)
  out$ki67_overlap_by_source <- mcl_count_ki67_overlap_by_source_from_outputs(out)
  out$stats <- stats
  out
}

mcl_count_ki67_source_validation_from_outputs <- function(inventory, outputs, text_scan = FALSE) {
  if (!is.data.frame(inventory) || !nrow(inventory)) return(mcl_count_empty_ki67_source_validation())
  rows <- lapply(seq_len(nrow(inventory)), function(i) {
    source <- inventory$source_channel[[i]]
    attempted <- FALSE
    success <- FALSE
    status <- "atlas_profiled_source_space_only"
    selected <- FALSE
    notes <- "Source-space inventory only; not direct Ki-67 evidence."
    if (identical(source, "coded_pathology")) {
      attempted <- TRUE
      success <- is.data.frame(outputs$ki67_aeki_person_counts) && any(outputs$ki67_aeki_person_counts$count_status %in% mcl_count_available_statuses(), na.rm = TRUE)
      status <- if (success) "coded_aeki_numeric_percent_validated_aggregate" else "coded_aeki_numeric_percent_requires_codebook_validation"
      selected <- success
      notes <- "SDS_pato.c_snomedkode AEKI000-AEKI100 aggregate route; no text emitted."
    } else if (identical(source, "pathology_free_text_embedded_in_pato")) {
      attempted <- isTRUE(text_scan)
      success <- attempted && is.data.frame(outputs$ki67_text_pattern_counts) && nrow(outputs$ki67_text_pattern_counts) > 0L
      status <- if (!attempted) "text_pattern_query_template_only" else if (success) "text_pattern_count_available_requires_validation" else "text_pattern_numeric_candidate_requires_validation"
      notes <- "SDS_pato.v_fritekst text source requires approved extraction validation before classifiability use."
    } else {
      bridge <- outputs$ki67_text_bridge_validation
      bridge_hit <- if (is.data.frame(bridge)) bridge[bridge$text_source == source, , drop = FALSE] else data.frame(stringsAsFactors = FALSE)
      attempted <- nrow(bridge_hit) && any(bridge_hit$query_attempted %in% TRUE)
      success <- nrow(bridge_hit) && any(bridge_hit$query_success %in% TRUE)
      status <- if (!attempted) "text_pattern_query_template_only" else if (success) "atlas_text_bridge_validated" else "atlas_text_bridge_failed"
      notes <- "Text source has no direct patientid; bridge validation is required and does not itself validate text extraction."
    }
    data.frame(
      source_channel = source,
      db_name = inventory$db_name[[i]],
      schema = inventory$schema[[i]],
      table_or_view = inventory$table_or_view[[i]],
      column_name = inventory$column_name[[i]],
      validation_query_attempted = attempted,
      validation_query_success = success,
      validation_status = status,
      selected_for_numeric_union = selected,
      error_message_sanitized = "",
      notes = notes,
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ki67_source_validation())
}

mcl_count_ki67_union_counts_from_outputs <- function(outputs, min_cell_count = 5L) {
  known <- outputs$ki67_threshold_counts
  if (!is.data.frame(known) || !nrow(known)) return(mcl_count_empty_ki67_union_counts())
  hit <- known[known$metric == "ki67_aeki_known", , drop = FALSE]
  if (!nrow(hit)) return(mcl_count_empty_ki67_union_counts())
  data.frame(
    denominator = hit$denominator[[1]],
    union_channel = "validated_numeric_channels",
    distinct_person_count_display = hit$distinct_person_count_display[[1]],
    percent_of_denominator_display = hit$percent_of_denominator_display[[1]],
    validation_status = "ki67_known_for_risk_classification_from_aeki_only",
    count_status = hit$count_status[[1]],
    notes = "Validated numeric Ki-67 union currently includes coded AEKI only; text source-space is excluded until extraction validation.",
    stringsAsFactors = FALSE
  )[names(mcl_count_empty_ki67_union_counts())]
}

mcl_count_ki67_overlap_by_source_from_outputs <- function(outputs) {
  aeki <- outputs$ki67_threshold_counts
  text <- outputs$ki67_text_person_counts
  if (!is.data.frame(aeki) || !nrow(aeki) || !is.data.frame(text) || !nrow(text)) {
    return(mcl_count_empty_ki67_overlap_by_source())
  }
  mcl_count_empty_ki67_overlap_by_source()
}

mcl_count_apply_ki67_outputs_to_count_outputs <- function(count_outputs, ki67_outputs) {
  threshold <- ki67_outputs$ki67_threshold_counts
  if (!is.data.frame(threshold) || !nrow(threshold)) return(count_outputs)
  known <- threshold[threshold$metric == "ki67_aeki_known", , drop = FALSE]
  high <- threshold[threshold$metric == "ki67_aeki_ge_threshold", , drop = FALSE]
  known_available <- nrow(known) && known$count_status[[1]] %in% mcl_count_available_statuses() && nzchar(known$distinct_person_count_display[[1]] %||% "")
  high_available <- nrow(high) && high$count_status[[1]] %in% mcl_count_available_statuses() && nzchar(high$distinct_person_count_display[[1]] %||% "")
  if (known_available && is.data.frame(count_outputs$ki67_person_count_summary) && nrow(count_outputs$ki67_person_count_summary)) {
    idx <- count_outputs$ki67_person_count_summary$denominator == "all_lyfo_mcl"
    count_outputs$ki67_person_count_summary$distinct_person_count_display[idx] <- known$distinct_person_count_display[[1]]
    count_outputs$ki67_person_count_summary$percent_of_denominator_display[idx] <- known$percent_of_denominator_display[[1]]
    count_outputs$ki67_person_count_summary$validation_status[idx] <- known$validation_status[[1]]
    count_outputs$ki67_person_count_summary$count_status[idx] <- known$count_status[[1]]
    if (is.data.frame(ki67_outputs$ki67_aeki_code_counts)) {
      count_outputs$ki67_person_count_summary$valid_aeki_code_count[idx] <- as.character(nrow(ki67_outputs$ki67_aeki_code_counts))
      count_outputs$ki67_person_count_summary$unique_percent_values_observed[idx] <- as.character(length(unique(ki67_outputs$ki67_aeki_code_counts$parsed_percent)))
    }
    count_outputs$ki67_person_count_summary$notes[idx] <- "Distinct-person Ki-67 knownness from aggregate AEKI000-AEKI100 production query; text source-space excluded until validated."
  }
  if (is.data.frame(count_outputs$high_risk_biology_counts) && nrow(count_outputs$high_risk_biology_counts)) {
    if (known_available) {
      idx <- count_outputs$high_risk_biology_counts$biology_component == "ki67_aeki_known"
      count_outputs$high_risk_biology_counts$distinct_person_count_display[idx] <- known$distinct_person_count_display[[1]]
      count_outputs$high_risk_biology_counts$percent_of_denominator_display[idx] <- known$percent_of_denominator_display[[1]]
      count_outputs$high_risk_biology_counts$validation_status[idx] <- "coded_aeki_numeric_percent_count_available"
      count_outputs$high_risk_biology_counts$count_status[idx] <- known$count_status[[1]]
      count_outputs$high_risk_biology_counts$notes[idx] <- "Ki-67 knownness from aggregate coded AEKI route; source-specific validation still required."
    }
    if (high_available) {
      idx <- count_outputs$high_risk_biology_counts$biology_component == "ki67_aeki_high_threshold"
      count_outputs$high_risk_biology_counts$distinct_person_count_display[idx] <- high$distinct_person_count_display[[1]]
      count_outputs$high_risk_biology_counts$percent_of_denominator_display[idx] <- high$percent_of_denominator_display[[1]]
      count_outputs$high_risk_biology_counts$validation_status[idx] <- "coded_aeki_threshold_count_available"
      count_outputs$high_risk_biology_counts$count_status[idx] <- high$count_status[[1]]
      count_outputs$high_risk_biology_counts$notes[idx] <- "Ki-67 high threshold from aggregate AEKI route; this does not make missing Ki-67 standard-risk evidence."
    }
  }
  count_outputs
}

mcl_count_full_atlas_predicate_evidence <- function(zip_path) {
  if (is.null(zip_path) || !nzchar(zip_path) || !file.exists(zip_path)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  values <- mcl_count_read_zip_table(zip_path, c("cartography_rkkp_lyfo_value_counts[.]tsv$"))
  if (!is.data.frame(values) || !nrow(values)) return(data.frame(stringsAsFactors = FALSE))
  if (!"source_table" %in% names(values) && "source_name" %in% names(values)) values$source_table <- values$source_name
  if (!"field_name" %in% names(values) && "column" %in% names(values)) values$field_name <- values$column
  needed <- c("source_table", "field_name", "value", "n")
  values <- mcl_count_ensure_columns(values, needed)
  lyfo <- values[tolower(as.character(values$source_table)) == "rkkp_lyfo", , drop = FALSE]
  field <- tolower(as.character(lyfo$field_name))
  value <- tolower(trimws(as.character(lyfo$value)))
  rows <- list()
  add <- function(data_point_id, field_name, value_text, evidence_n = "", status = "validated_full_atlas_value_evidence", notes = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      data_point_id = data_point_id,
      field = field_name,
      value = value_text,
      evidence_count = as.character(evidence_n %||% ""),
      validation_status = status,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  mcl_hit <- lyfo[field == "subtype" & value == "mcl", , drop = FALSE]
  if (nrow(mcl_hit)) add("all_lyfo_mcl", "subtype", "MCL", mcl_hit$n[[1]], notes = "Confirmed LYFO subtype value for mantle cell lymphoma.")
  chemo_hit <- lyfo[field == "beh_erderforetagetkemo" & value == "y", , drop = FALSE]
  if (nrow(chemo_hit)) add("cit_immunochemotherapy", "Beh_ErDerForetagetKemo", "Y", chemo_hit$n[[1]], notes = "Confirmed Y/N chemotherapy indicator.")
  for (reg_field in c("beh_kemoterapiregime1", "beh_kemoterapiregime2", "beh_kemoterapiregime3")) {
    reg_hits <- lyfo[field == reg_field & value %in% c("chop", "bendamustin", "maxichop", "mantle2", "mantle3", "hdarac", "dhap", "beam", "bcnu", "beac", "cvp", "chlorambucil", "cyclophosphamide"), , drop = FALSE]
    if (nrow(reg_hits)) add("cit_immunochemotherapy", unique(reg_hits$field_name)[[1]], paste(unique(reg_hits$value), collapse = ";"), sum(suppressWarnings(as.numeric(reg_hits$n)), na.rm = TRUE), notes = "Confirmed LYFO regimen values.")
    ib_hits <- lyfo[field == reg_field & value == "ibrutinib", , drop = FALSE]
    if (nrow(ib_hits)) add("ibrutinib_exposure", unique(ib_hits$field_name)[[1]], "ibrutinib", sum(suppressWarnings(as.numeric(ib_hits$n)), na.rm = TRUE), notes = "Confirmed ibrutinib regimen value in LYFO.")
  }
  asct_y <- lyfo[field == "beh_hoejdosisbehandling" & value == "y", , drop = FALSE]
  if (nrow(asct_y)) add("asct_hdt_first_line", "Beh_Hoejdosisbehandling", "Y", asct_y$n[[1]], notes = "Confirmed Y/N first-line high-dose therapy indicator.")
  asct_type <- lyfo[field == "beh_typeautologstamcellestoette" & value %in% c("beam", "other", "bcnu-thiotepa", "bcnu", "beac"), , drop = FALSE]
  if (nrow(asct_type)) add("asct_hdt_first_line", "Beh_TypeAutologStamcellestoette", paste(unique(asct_type$value), collapse = ";"), sum(suppressWarnings(as.numeric(asct_type$n)), na.rm = TRUE), notes = "Confirmed ASCT/HDT support-type values.")
  rec_y <- lyfo[field == "rec_hoejdosisbehandling" & value == "y", , drop = FALSE]
  if (nrow(rec_y)) add("asct_hdt_relapse_recurrence", "Rec_Hoejdosisbehandling", "Y", rec_y$n[[1]], notes = "Confirmed relapse/recurrence high-dose therapy indicator.")
  if (!length(rows)) return(data.frame(stringsAsFactors = FALSE))
  bind_rows_base(rows)
}

mcl_count_default_full_atlas_zip <- function(project_root = ".") {
  candidates <- c(
    Sys.getenv("MCL_COUNT_FULL_ATLAS_ZIP", ""),
    file.path(project_root, "2026.05.20 14.00 ATLAS output(2).zip"),
    file.path(project_root, "2026.05.20 14.00 ATLAS output.zip")
  )
  candidates <- candidates[nzchar(candidates)]
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) normalizePath(hit[[1]], winslash = "/", mustWork = FALSE) else ""
}

mcl_count_import_full_atlas_predicates <- function(project_root = ".", zip_path = mcl_count_default_full_atlas_zip(project_root)) {
  evidence <- mcl_count_full_atlas_predicate_evidence(zip_path)
  if (!is.data.frame(evidence) || !nrow(evidence)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  evidence
}

mcl_count_bool <- function(x) {
  tolower(trimws(as.character(x %||% ""))) %in% c("true", "t", "1", "yes", "y")
}

mcl_count_sql_ident <- function(x) {
  paste0('"', gsub('"', '""', as.character(x %||% "")), '"')
}

mcl_count_sql_table <- function(schema, table) {
  paste(mcl_count_sql_ident(schema %||% "public"), mcl_count_sql_ident(table), sep = ".")
}

mcl_count_source_mapping <- function(person_date_mapping, resource_id = "", table = "") {
  if (!is.data.frame(person_date_mapping) || !nrow(person_date_mapping)) return(data.frame(stringsAsFactors = FALSE))
  hit <- rep(TRUE, nrow(person_date_mapping))
  if (nzchar(resource_id %||% "")) hit <- hit & person_date_mapping$resource_id == resource_id
  if (nzchar(table %||% "")) hit <- hit & person_date_mapping$table == table
  person_date_mapping[hit, , drop = FALSE]
}

mcl_count_mapping_usable <- function(mapping) {
  is.data.frame(mapping) && nrow(mapping) && mcl_count_bool(mapping$usable_for_counts[[1]]) && nzchar(mapping$person_key_column[[1]] %||% "")
}

mcl_count_patient_demographics_status <- function() "count_not_available_requires_patient_demographics_mapping"

mcl_count_patient_demographics_candidate_kind <- function(schema, table, is_configured = FALSE) {
  table_l <- tolower(trimws(as.character(table %||% "")))
  schema_l <- tolower(trimws(as.character(schema %||% "")))
  if (!nzchar(table_l)) return("candidate_requires_explicit_configuration")
  if (isTRUE(is_configured)) return("explicitly_configured_demographics")

  general_patient <- grepl(
    "(^patient$|patient|demograph|person|cpr|civil|folkeregister|population|vital|death|os)",
    table_l,
    ignore.case = TRUE,
    perl = TRUE
  )
  disease_or_registry_source <- grepl(
    "(^|[_])cll([_]|$)|rkkp_cll|damyda|myeloma|(^|[_])mm([_]|$)|dlbcl|mzl|sll|lyfo|rkkp_",
    table_l,
    ignore.case = TRUE,
    perl = TRUE
  )
  treatment_or_event_source <- grepl(
    "treat|therapy|medicine|medicin|procedure|diagnos|diagnose|comorbidity|(^|_)ae($|_)|adverse|recept|sks|pato|antineoplastic",
    table_l,
    ignore.case = TRUE,
    perl = TRUE
  )

  if (disease_or_registry_source || treatment_or_event_source) return("rejected_non_mcl_demographics_source")
  if (schema_l %in% c("curated", "rkkp")) return("rejected_non_mcl_demographics_source")
  if (general_patient) return("general_patient_demographics")
  "candidate_requires_explicit_configuration"
}

mcl_count_reject_patient_demographics_fallback <- function(schema, table, is_configured = FALSE) {
  if (isTRUE(is_configured)) return(FALSE)
  !identical(
    mcl_count_patient_demographics_candidate_kind(schema, table, is_configured = FALSE),
    "general_patient_demographics"
  )
}

mcl_count_relation_failure_pattern <- function() {
  'relation "+public[.]patient"+ does not exist|relation "+public"+[.]"+patient"+ does not exist|view_create_patient_table.*does not exist|view_patient_table_os.*does not exist'
}

mcl_count_has_relation_failure_text <- function(text) {
  grepl(mcl_count_relation_failure_pattern(), as.character(text %||% ""), ignore.case = TRUE, perl = TRUE)
}

mcl_count_df_text <- function(df) {
  if (!is.data.frame(df) || !nrow(df)) return("")
  paste(vapply(df, function(col) paste(as.character(col %||% ""), collapse = "\n"), character(1)), collapse = "\n")
}

mcl_count_coherent_post_selection_resolver_failure <- function(path) {
  df <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(df) || !nrow(df) || !"post_selection_execution_error_sanitized" %in% names(df)) return(FALSE)
  err <- mcl_count_has_relation_failure_text(df$post_selection_execution_error_sanitized)
  coherent <- err &
    !mcl_count_bool(df$selected %||% FALSE) &
    !mcl_count_bool(df$usable_for_age_counts %||% FALSE) &
    as.character(df$reason %||% "") == "post_selection_relation_not_found" &
    mcl_count_bool(df$relation_probe_success %||% FALSE) &
    mcl_count_bool(df$column_probe_success %||% FALSE) &
    mcl_count_bool(df$post_selection_execution_attempted %||% FALSE) &
    !mcl_count_bool(df$post_selection_execution_success %||% FALSE)
  coherent[is.na(coherent)] <- FALSE
  if (!any(coherent, na.rm = TRUE)) return(FALSE)
  df_without_allowed <- df
  df_without_allowed$post_selection_execution_error_sanitized[coherent] <- ""
  !mcl_count_has_relation_failure_text(mcl_count_df_text(df_without_allowed))
}

mcl_count_coherent_post_selection_age_source_failure <- function(path) {
  df <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(df) || !nrow(df) || !"post_selection_execution_error_sanitized" %in% names(df)) return(FALSE)
  err <- mcl_count_has_relation_failure_text(df$post_selection_execution_error_sanitized)
  coherent <- err &
    !mcl_count_bool(df$selected %||% FALSE) &
    !mcl_count_bool(df$usable_for_age_counts %||% FALSE) &
    as.character(df$reason %||% "") == "post_selection_relation_not_found" &
    mcl_count_bool(df$relation_probe_success %||% FALSE) &
    mcl_count_bool(df$column_probe_success %||% FALSE) &
    mcl_count_bool(df$post_selection_execution_attempted %||% FALSE) &
    !mcl_count_bool(df$post_selection_execution_success %||% FALSE)
  coherent[is.na(coherent)] <- FALSE
  if (!any(coherent, na.rm = TRUE)) return(FALSE)
  df_without_allowed <- df
  df_without_allowed$post_selection_execution_error_sanitized[coherent] <- ""
  !mcl_count_has_relation_failure_text(mcl_count_df_text(df_without_allowed))
}

mcl_count_coherent_co_residency_probe_failure <- function(path) {
  df <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(df) || !nrow(df) || !"co_residency_probe_error_sanitized" %in% names(df)) return(FALSE)
  err <- mcl_count_has_relation_failure_text(df$co_residency_probe_error_sanitized)
  coherent <- err &
    !mcl_count_bool(df$selected %||% FALSE) &
    !mcl_count_bool(df$usable_for_age_counts %||% FALSE) &
    as.character(df$reason %||% "") == "co_residency_probe_failed" &
    mcl_count_bool(df$relation_probe_success %||% FALSE) &
    mcl_count_bool(df$column_probe_success %||% FALSE) &
    mcl_count_bool(df$co_residency_probe_attempted %||% FALSE) &
    !mcl_count_bool(df$co_residency_probe_success %||% FALSE)
  coherent[is.na(coherent)] <- FALSE
  if (!any(coherent, na.rm = TRUE)) return(FALSE)
  df_without_allowed <- df
  df_without_allowed$co_residency_probe_error_sanitized[coherent] <- ""
  !mcl_count_has_relation_failure_text(mcl_count_df_text(df_without_allowed))
}

mcl_count_coherent_post_selection_age_failure <- function(path) {
  df <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(df) || !nrow(df) || !"data_point_id" %in% names(df)) return(FALSE)
  if (!"error_message_sanitized" %in% names(df)) return(FALSE)
  err <- mcl_count_has_relation_failure_text(df$error_message_sanitized)
  if (!any(err, na.rm = TRUE)) return(FALSE)
  age <- df$data_point_id %in% mcl_count_age_data_point_ids()
  coherent <- age &
    as.character(df$count_status %||% "") == mcl_count_patient_demographics_status() &
    as.character(df$validation_status %||% "") == "post_selection_resolver_invalidated" &
    !mcl_count_bool(df$query_executed %||% FALSE) &
    !mcl_count_bool(df$query_success %||% FALSE)
  coherent[is.na(coherent)] <- FALSE
  if (any(err & !coherent, na.rm = TRUE)) return(FALSE)
  df_without_allowed <- df
  df_without_allowed$error_message_sanitized[coherent] <- ""
  !mcl_count_has_relation_failure_text(mcl_count_df_text(df_without_allowed))
}

mcl_count_output_relation_failure_is_coherent <- function(path, rel) {
  if (identical(rel, "mcl_triangle_patient_demographics_resolver.csv")) {
    return(mcl_count_coherent_post_selection_resolver_failure(path) || mcl_count_coherent_co_residency_probe_failure(path))
  }
  if (identical(rel, "mcl_triangle_age_source_locator.csv")) {
    return(mcl_count_coherent_post_selection_age_source_failure(path) || mcl_count_coherent_co_residency_probe_failure(path))
  }
  if (identical(rel, "mcl_triangle_data_point_counts.csv")) {
    return(mcl_count_coherent_post_selection_age_failure(path))
  }
  FALSE
}

mcl_count_query_template_sections <- function(text) {
  sections <- unlist(strsplit(as.character(text %||% ""), "-- query_id: ", fixed = TRUE), use.names = FALSE)
  sections[nzchar(trimws(sections))]
}

mcl_count_query_templates_have_executable_relation <- function(text, schema, table) {
  if (!nzchar(schema %||% "") || !nzchar(table %||% "")) return(FALSE)
  relation_quoted <- mcl_count_sql_table(schema, table)
  relation_plain <- paste0(schema, ".", table)
  sections <- mcl_count_query_template_sections(text)
  if (!length(sections)) return(FALSE)
  executable <- sections[!grepl("-- NOT EXECUTABLE", sections, fixed = TRUE)]
  if (!length(executable)) return(FALSE)
  any(grepl(relation_quoted, executable, fixed = TRUE) | grepl(relation_plain, executable, fixed = TRUE), na.rm = TRUE)
}

mcl_count_query_templates_have_executable_invalidated_patient_join <- function(text, resolver) {
  if (!is.data.frame(resolver) || !nrow(resolver)) return(FALSE)
  resolver <- mcl_count_match_empty(resolver, mcl_count_empty_patient_demographics_resolver())
  invalidated <- resolver[
    as.character(resolver$reason %||% "") == "post_selection_relation_not_found" &
      !mcl_count_bool(resolver$selected %||% FALSE) &
      !mcl_count_bool(resolver$usable_for_age_counts %||% FALSE),
    ,
    drop = FALSE
  ]
  if (!nrow(invalidated)) return(FALSE)
  any(vapply(seq_len(nrow(invalidated)), function(i) {
    mcl_count_query_templates_have_executable_relation(text, invalidated$schema[[i]], invalidated$table[[i]])
  }, logical(1)))
}

mcl_count_query_templates_have_executable_invalidated_age_source <- function(text, locator) {
  if (!is.data.frame(locator) || !nrow(locator)) return(FALSE)
  locator <- mcl_count_match_empty(locator, mcl_count_empty_age_source_locator())
  invalidated <- locator[
    as.character(locator$reason %||% "") == "post_selection_relation_not_found" &
      !mcl_count_bool(locator$selected %||% FALSE) &
      !mcl_count_bool(locator$usable_for_age_counts %||% FALSE),
    ,
    drop = FALSE
  ]
  if (!nrow(invalidated)) return(FALSE)
  any(vapply(seq_len(nrow(invalidated)), function(i) {
    mcl_count_query_templates_have_executable_relation(text, invalidated$schema[[i]], invalidated$table[[i]])
  }, logical(1)))
}

mcl_count_query_templates_have_unverified_patient_join <- function(text, selected_patient, selected_age_source = NULL) {
  patient_ref_pattern <- '"public"[.]"patient"|public[.]patient|"public"[.]"view_create_patient_table"|public[.]view_create_patient_table|"public"[.]"view_patient_table_os"|public[.]view_patient_table_os|view_create_patient_table|view_patient_table_os'
  sections <- mcl_count_query_template_sections(text)
  executable <- sections[!grepl("-- NOT EXECUTABLE", sections, fixed = TRUE)]
  if (!length(executable) || !any(grepl(patient_ref_pattern, executable, ignore.case = TRUE, perl = TRUE), na.rm = TRUE)) {
    return(FALSE)
  }
  allowed <- list()
  if (is.data.frame(selected_patient) && nrow(selected_patient)) {
    allowed[[length(allowed) + 1L]] <- data.frame(schema = selected_patient$schema[[1]], table = selected_patient$table[[1]], stringsAsFactors = FALSE)
  }
  if (is.data.frame(selected_age_source) && nrow(selected_age_source) && !identical(selected_age_source$source_type[[1]], "lyfo_age_fallback")) {
    allowed[[length(allowed) + 1L]] <- data.frame(schema = selected_age_source$schema[[1]], table = selected_age_source$table[[1]], stringsAsFactors = FALSE)
  }
  allowed <- bind_rows_base(allowed)
  if (!nrow(allowed)) return(TRUE)
  any_allowed <- any(vapply(seq_len(nrow(allowed)), function(i) {
    selected_plain <- paste0(allowed$schema[[i]], ".", allowed$table[[i]])
    selected_quoted <- mcl_count_sql_table(allowed$schema[[i]], allowed$table[[i]])
    any(grepl(selected_plain, executable, fixed = TRUE) | grepl(selected_quoted, executable, fixed = TRUE), na.rm = TRUE)
  }, logical(1)))
  !any_allowed
}

mcl_count_patient_metadata_context <- function(db_adapter, generated_at = mcl_count_now(), mode = "plan") {
  if (!mcl_count_db_adapter_available(db_adapter)) {
    return(list(database_name = "", search_path = "", verified_at = generated_at, verification_mode = "plan_unverified_no_db"))
  }
  result <- mcl_count_db_query_result(
    db_adapter,
    "select current_database() as database_name, current_setting('search_path') as search_path;"
  )
  data <- result$data
  if (is.data.frame(data) && nrow(data)) {
    database_name <- if ("database_name" %in% names(data)) as.character(data$database_name[[1]] %||% "") else ""
    search_path <- if ("search_path" %in% names(data)) as.character(data$search_path[[1]] %||% "") else ""
    return(list(
      database_name = database_name,
      search_path = search_path,
      verified_at = generated_at,
      verification_mode = if (identical(mode, "test")) "test_fake_information_schema" else "production_information_schema"
    ))
  }
  list(database_name = "", search_path = "", verified_at = generated_at, verification_mode = "production_information_schema")
}

mcl_count_patient_info_schema_columns <- function(db_adapter) {
  if (!mcl_count_db_adapter_available(db_adapter)) return(data.frame(stringsAsFactors = FALSE))
  sql <- paste(
    "select c.table_schema as schema, c.table_name as table, lower(c.column_name) as column_name",
    "from information_schema.columns c",
    "left join information_schema.tables t on t.table_schema = c.table_schema and t.table_name = c.table_name",
    "where lower(c.column_name) in ('patientid', 'date_birth', 'date_death_fu')",
    "and coalesce(t.table_type, 'VIEW') in ('BASE TABLE', 'VIEW')"
  )
  data <- mcl_count_db_query_all_connections(db_adapter, sql)
  if (!is.data.frame(data) || !nrow(data)) return(data.frame(stringsAsFactors = FALSE))
  names(data) <- sub("^table_schema$", "schema", names(data))
  names(data) <- sub("^table_name$", "table", names(data))
  names(data) <- sub("^column$", "column_name", names(data))
  needed <- c("db_name", "schema", "table", "column_name")
  data <- mcl_count_ensure_columns(data, needed)
  data$db_name <- as.character(data$db_name)
  data$schema <- as.character(data$schema)
  data$table <- as.character(data$table)
  data$column_name <- tolower(as.character(data$column_name))
  unique(data)
}

mcl_count_db_age_source_meta <- function(source_db_name = "", lyfo_db_name = "") {
  source_db_name <- as.character(source_db_name %||% "")
  lyfo_db_name <- as.character(lyfo_db_name %||% "")
  same_db <- nzchar(source_db_name) && nzchar(lyfo_db_name) &&
    identical(tolower(source_db_name), tolower(lyfo_db_name))
  cross_required <- nzchar(source_db_name) && nzchar(lyfo_db_name) && !same_db
  list(
    db_name = source_db_name,
    source_db_name = source_db_name,
    lyfo_db_name = lyfo_db_name,
    same_db_as_lyfo = same_db,
    cross_db_join_required = cross_required,
    cross_db_join_available = FALSE
  )
}

mcl_count_patient_atlas_table_names <- function(outputs_dir = NULL) {
  if (is.null(outputs_dir) || !dir.exists(outputs_dir)) return(character())
  tables <- character()
  for (name in c("atlas_columns.csv", "atlas_column_profiles.csv")) {
    path <- file.path(outputs_dir, name)
    if (file.exists(path)) {
      x <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
      for (nm in c("table_name", "table", "source", "resource_id")) {
        if (nm %in% names(x)) tables <- c(tables, as.character(x[[nm]]))
      }
    }
  }
  unique(tolower(tables[nzchar(tables)]))
}

mcl_count_co_residency_probe <- function(db_adapter, lyfo_mapping, schema, table, patientid_column = "patientid", source_db_name = "", lyfo_db_name = "") {
  if (!mcl_count_mapping_usable(lyfo_mapping)) {
    return(list(
      co_residency_probe_attempted = FALSE,
      co_residency_probe_success = FALSE,
      co_residency_probe_error_sanitized = "RKKP_LYFO person-key mapping is unavailable for co-residency probing."
    ))
  }
  source_db_name <- as.character(source_db_name %||% "")
  lyfo_db_name <- as.character(lyfo_db_name %||% lyfo_mapping$db_name[[1]] %||% "")
  if (nzchar(source_db_name) && nzchar(lyfo_db_name) && !identical(tolower(source_db_name), tolower(lyfo_db_name))) {
    return(list(
      co_residency_probe_attempted = FALSE,
      co_residency_probe_success = FALSE,
      co_residency_probe_error_sanitized = paste0("Cross-database join unavailable: source db_name=", source_db_name, " and RKKP_LYFO db_name=", lyfo_db_name, ".")
    ))
  }
  lyfo_ref <- mcl_count_sql_table(lyfo_mapping$schema[[1]], lyfo_mapping$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo_mapping$person_key_column[[1]])
  patient_key <- mcl_count_sql_ident(patientid_column %||% "patientid")
  sql <- paste0(
    "select count(*) as probe_count\n",
    "from ", lyfo_ref, " r\n",
    "join ", mcl_count_sql_table(schema, table), " p on p.", patient_key, " = r.", lyfo_key, "\n",
    "where false;"
  )
  result <- mcl_count_db_query_result(db_adapter, sql)
  success <- is.data.frame(result$data) &&
    "probe_count" %in% names(result$data) &&
    nrow(result$data) == 1L
  error <- result$error_message_sanitized %||% ""
  if (!success && !nzchar(error) && is.data.frame(result$data)) {
    error <- "Co-residency probe returned an unexpected result shape; expected one aggregate probe_count column."
  }
  list(
    co_residency_probe_attempted = TRUE,
    co_residency_probe_success = success,
    co_residency_probe_error_sanitized = error,
    co_residency_sql = sql
  )
}

mcl_count_patient_probe <- function(db_adapter, schema, table, lyfo_mapping = NULL, db_name = "") {
  relation_sql <- paste0(
    "select count(*) as probe_count\nfrom ",
    mcl_count_sql_table(schema, table),
    "\nwhere false;"
  )
  column_sql <- paste0(
    "select ",
    mcl_count_sql_ident("patientid"),
    ", ",
    mcl_count_sql_ident("date_birth"),
    "\nfrom ",
    mcl_count_sql_table(schema, table),
    "\nwhere false;"
  )
  relation <- mcl_count_db_query_result(db_adapter, relation_sql)
  relation_success <- is.data.frame(relation$data) &&
    "probe_count" %in% names(relation$data) &&
    nrow(relation$data) == 1L
  column <- if (relation_success) {
    mcl_count_db_query_result(db_adapter, column_sql)
  } else {
    list(data = NULL, error_class = "", error_message_sanitized = "")
  }
  column_success <- is.data.frame(column$data) &&
    all(c("patientid", "date_birth") %in% names(column$data))
  relation_error <- relation$error_message_sanitized %||% ""
  if (!relation_success && !nzchar(relation_error) && is.data.frame(relation$data)) {
    relation_error <- "Relation probe returned an unexpected result shape; expected one aggregate probe_count column."
  }
  column_error <- column$error_message_sanitized %||% ""
  if (relation_success && !column_success && !nzchar(column_error) && is.data.frame(column$data)) {
    column_error <- "Column probe returned an unexpected result shape; expected patientid and date_birth columns."
  }
  co <- if (relation_success && column_success) {
    mcl_count_co_residency_probe(db_adapter, lyfo_mapping, schema, table, "patientid", source_db_name = db_name, lyfo_db_name = lyfo_mapping$db_name[[1]] %||% "")
  } else {
    list(
      co_residency_probe_attempted = FALSE,
      co_residency_probe_success = FALSE,
      co_residency_probe_error_sanitized = ""
    )
  }
  list(
    relation_probe_attempted = TRUE,
    relation_probe_success = relation_success,
    relation_probe_error_sanitized = relation_error,
    column_probe_attempted = relation_success,
    column_probe_success = column_success,
    column_probe_error_sanitized = if (relation_success) column_error else "",
    co_residency_probe_attempted = isTRUE(co$co_residency_probe_attempted),
    co_residency_probe_success = isTRUE(co$co_residency_probe_success),
    co_residency_probe_error_sanitized = co$co_residency_probe_error_sanitized %||% "",
    relation_sql = relation_sql,
    column_sql = column_sql,
    co_residency_sql = co$co_residency_sql %||% ""
  )
}

mcl_count_patient_candidate_rows <- function(columns, configured = data.frame(stringsAsFactors = FALSE), outputs_dir = NULL,
                                             context = list(), verification_mode = "production_information_schema",
                                             db_adapter = NULL, lyfo_mapping = NULL) {
  empty <- mcl_count_empty_patient_demographics_resolver()
  configured_db <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$db_name[[1]] %||% "") else ""
  configured_schema <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$schema[[1]] %||% "") else ""
  configured_table <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$table[[1]] %||% "") else ""
  lyfo_db_name <- if (is.data.frame(lyfo_mapping) && nrow(lyfo_mapping)) as.character(lyfo_mapping$db_name[[1]] %||% "") else ""
  mk_row <- function(db_name = "", schema = "", table = "", has_patientid = FALSE,
                     has_birth = FALSE, has_death = FALSE, score = 0L,
                     selected = FALSE, reason = "", usable = FALSE, probe = list(),
                     tie_review = FALSE, notes = "") {
    meta <- mcl_count_db_age_source_meta(db_name, lyfo_db_name)
    data.frame(
      database_name = context$database_name %||% "",
      search_path = context$search_path %||% "",
      verified_at = context$verified_at %||% mcl_count_now(),
      verification_mode = verification_mode,
      db_name = meta$db_name,
      source_db_name = meta$source_db_name,
      lyfo_db_name = meta$lyfo_db_name,
      same_db_as_lyfo = isTRUE(meta$same_db_as_lyfo),
      cross_db_join_required = isTRUE(meta$cross_db_join_required),
      cross_db_join_available = isTRUE(meta$cross_db_join_available),
      schema = schema,
      table = table,
      has_patientid = isTRUE(has_patientid),
      has_date_birth = isTRUE(has_birth),
      has_date_death_fu = isTRUE(has_death),
      candidate_score = as.integer(score),
      selected = isTRUE(selected),
      reason = reason,
      usable_for_age_counts = isTRUE(usable),
      relation_probe_attempted = isTRUE(probe$relation_probe_attempted),
      relation_probe_success = isTRUE(probe$relation_probe_success),
      relation_probe_error_sanitized = probe$relation_probe_error_sanitized %||% "",
      column_probe_attempted = isTRUE(probe$column_probe_attempted),
      column_probe_success = isTRUE(probe$column_probe_success),
      column_probe_error_sanitized = probe$column_probe_error_sanitized %||% "",
      co_residency_probe_attempted = isTRUE(probe$co_residency_probe_attempted),
      co_residency_probe_success = isTRUE(probe$co_residency_probe_success),
      co_residency_probe_error_sanitized = probe$co_residency_probe_error_sanitized %||% "",
      deterministic_tie_break_requires_review = isTRUE(tie_review),
      post_selection_execution_attempted = FALSE,
      post_selection_execution_success = FALSE,
      post_selection_execution_error_sanitized = "",
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  if (!is.data.frame(columns) || !nrow(columns)) {
    rows <- list()
    if (nzchar(configured_table)) {
      rows[[1L]] <- mk_row(
        db_name = configured_db,
        schema = configured_schema,
        table = configured_table,
        reason = if (identical(verification_mode, "plan_unverified_no_db")) "no_db_plan_mode" else "configured_relation_missing",
        notes = "No information_schema candidate with patientid and date_birth was verified.",
      )
    }
    return(mcl_count_match_empty(bind_rows_base(rows), empty))
  }
  columns <- mcl_count_ensure_columns(columns, c("db_name", "schema", "table", "column_name"))
  keys <- unique(data.frame(db_name = columns$db_name, schema = columns$schema, table = columns$table, stringsAsFactors = FALSE))
  atlas_tables <- mcl_count_patient_atlas_table_names(outputs_dir)
  rows <- lapply(seq_len(nrow(keys)), function(i) {
    db_name <- keys$db_name[[i]] %||% ""
    schema <- keys$schema[[i]]
    table <- keys$table[[i]]
    cols <- columns$column_name[
      tolower(columns$db_name %||% "") == tolower(db_name) &
        tolower(columns$schema) == tolower(schema) &
        tolower(columns$table) == tolower(table)
    ]
    has_patientid <- "patientid" %in% cols
    has_birth <- "date_birth" %in% cols
    has_death <- "date_death_fu" %in% cols
    is_configured <- nzchar(configured_table) &&
      identical(tolower(schema), tolower(configured_schema)) &&
      identical(tolower(table), tolower(configured_table)) &&
      (!nzchar(configured_db) || !nzchar(db_name) || identical(tolower(configured_db), tolower(db_name)))
    candidate_kind <- mcl_count_patient_demographics_candidate_kind(schema, table, is_configured = is_configured)
    rejected_fallback <- has_patientid && has_birth && mcl_count_reject_patient_demographics_fallback(schema, table, is_configured = is_configured)
    naming <- grepl("(^patient$|patient|patient_table)", table, ignore.case = TRUE)
    atlas_match <- tolower(table) %in% atlas_tables
    score <- 0L
    if (is_configured && has_patientid && has_birth) score <- score + 100L
    if (has_death && !rejected_fallback) score <- score + 40L
    if (naming && !rejected_fallback) score <- score + 25L
    if (atlas_match && !rejected_fallback) score <- score + 20L
    if (rejected_fallback) score <- 0L
    probe <- if (has_patientid && has_birth && !rejected_fallback && mcl_count_db_adapter_available(db_adapter)) {
      mcl_count_patient_probe(db_adapter, schema, table, lyfo_mapping = lyfo_mapping, db_name = db_name)
    } else {
      list(
        relation_probe_attempted = FALSE,
        relation_probe_success = FALSE,
        relation_probe_error_sanitized = "",
        column_probe_attempted = FALSE,
        column_probe_success = FALSE,
        column_probe_error_sanitized = "",
        co_residency_probe_attempted = FALSE,
        co_residency_probe_success = FALSE,
        co_residency_probe_error_sanitized = ""
      )
    }
    meta <- mcl_count_db_age_source_meta(db_name, lyfo_db_name)
    probe_success <- isTRUE(probe$relation_probe_success) && isTRUE(probe$column_probe_success) && isTRUE(probe$co_residency_probe_success)
    reason <- if (rejected_fallback) {
      "rejected_non_mcl_demographics_source"
    } else if (!has_patientid || !has_birth) {
      "missing_required_column"
    } else if (!isTRUE(probe$relation_probe_success)) {
      if (is_configured) "relation_probe_failed" else "relation_probe_failed"
    } else if (!isTRUE(probe$column_probe_success)) {
      "column_probe_failed"
    } else if (isTRUE(meta$cross_db_join_required) && !isTRUE(meta$cross_db_join_available)) {
      "cross_database_join_unavailable"
    } else if (!isTRUE(probe$co_residency_probe_success)) {
      "co_residency_probe_failed"
    } else if (is_configured) {
      "selected_verified_candidate"
    } else {
      "selected_verified_candidate"
    }
    mk_row(
      db_name = db_name,
      schema = schema,
      table = table,
      has_patientid = has_patientid,
      has_birth = has_birth,
      has_death = has_death,
      score = score,
      reason = reason,
      usable = has_patientid && has_birth && !rejected_fallback && probe_success,
      probe = probe,
      notes = if (rejected_fallback) {
        "Rejected as a disease-specific/non-general demographics fallback for MCL age counts. Configure an explicit general patient-demographics relation instead."
      } else if (isTRUE(meta$cross_db_join_required) && !isTRUE(meta$cross_db_join_available)) {
        "Candidate exists but is in a different DB from RKKP_LYFO; no executable same-SQL age join is emitted."
      } else if (atlas_match) {
        "Patient demographics candidate also appears in atlas metadata."
      } else {
        ""
      }
    )
  })
  out <- bind_rows_base(rows)
  if (nzchar(configured_table)) {
    configured_present <- any(
      tolower(out$schema %||% "") == tolower(configured_schema) &
        tolower(out$table %||% "") == tolower(configured_table) &
        (!nzchar(configured_db) | !nzchar(out$db_name %||% "") | tolower(out$db_name %||% "") == tolower(configured_db)),
      na.rm = TRUE
    )
    if (!configured_present) {
      configured_row <- mk_row(
        db_name = configured_db,
        schema = configured_schema,
        table = configured_table,
        reason = if (identical(verification_mode, "plan_unverified_no_db")) "no_db_plan_mode" else "configured_relation_missing",
        notes = "Configured patient demographics relation was not verified as a queryable candidate."
      )
      out <- bind_rows_base(list(configured_row, out))
    }
  }
  selectable <- out[out$usable_for_age_counts %in% TRUE, , drop = FALSE]
  if (!nrow(selectable)) {
    if (nrow(out)) return(mcl_count_match_empty(out, empty))
    return(mcl_count_patient_candidate_rows(data.frame(stringsAsFactors = FALSE), configured, outputs_dir, context, verification_mode, db_adapter = db_adapter, lyfo_mapping = lyfo_mapping))
  }
  ord <- order(-selectable$candidate_score, tolower(selectable$schema), tolower(selectable$table))
  selectable <- selectable[ord, , drop = FALSE]
  top_score <- selectable$candidate_score[[1]]
  tied <- sum(selectable$candidate_score == top_score, na.rm = TRUE) > 1L
  winner_db <- selectable$db_name[[1]] %||% ""
  winner_schema <- selectable$schema[[1]]
  winner_table <- selectable$table[[1]]
  out$selected <- FALSE
  winner <- tolower(out$db_name %||% "") == tolower(winner_db) &
    tolower(out$schema) == tolower(winner_schema) &
    tolower(out$table) == tolower(winner_table)
  out$selected[winner] <- TRUE
  out$deterministic_tie_break_requires_review <- FALSE
  out$deterministic_tie_break_requires_review[winner] <- tied
  out$reason[winner] <- if (tied) "deterministic_tie_break_requires_review" else "selected_verified_candidate"
  selectable_not_winner <- out$usable_for_age_counts %in% TRUE & !winner
  if (any(selectable_not_winner)) {
    out$reason[selectable_not_winner] <- ifelse(tied & out$candidate_score[selectable_not_winner] == top_score, "tie_lost", "lower_score")
  }
  out$notes[winner] <- trimws(paste(out$notes[winner], if (tied) "Equal-scoring patient demographics candidates were present; deterministic schema/table tie-break selected this row and requires review." else ""))
  mcl_count_match_empty(out, empty)
}

mcl_count_existing_patient_resolver <- function(outputs_dir = NULL) {
  if (is.null(outputs_dir) || !dir.exists(outputs_dir)) return(mcl_count_empty_patient_demographics_resolver())
  path <- file.path(outputs_dir, "mcl_triangle_patient_demographics_resolver.csv")
  if (!file.exists(path)) return(mcl_count_empty_patient_demographics_resolver())
  out <- tryCatch(read_delimited_file(path), error = function(e) mcl_count_empty_patient_demographics_resolver())
  mcl_count_match_empty(out, mcl_count_empty_patient_demographics_resolver())
}

mcl_count_selected_patient_resolver <- function(resolver) {
  if (!is.data.frame(resolver) || !nrow(resolver)) return(data.frame(stringsAsFactors = FALSE))
  resolver <- mcl_count_match_empty(resolver, mcl_count_empty_patient_demographics_resolver())
  hit <- resolver[
    resolver$selected %in% TRUE &
      resolver$usable_for_age_counts %in% TRUE &
      resolver$relation_probe_success %in% TRUE &
      resolver$column_probe_success %in% TRUE &
      resolver$co_residency_probe_success %in% TRUE,
    ,
    drop = FALSE
  ]
  if (nrow(hit) == 1L) hit else data.frame(stringsAsFactors = FALSE)
}

mcl_count_resolve_patient_demographics <- function(project_root = ".", outputs_dir = NULL, db_adapter = NULL,
                                                   person_date_mapping = NULL, mode = "plan",
                                                   generated_at = mcl_count_now(),
                                                   verification_mode = NULL,
                                                   atlas_age_source_inventory = NULL) {
  configured <- if (is.data.frame(person_date_mapping)) {
    mcl_count_source_mapping(person_date_mapping, "patient", "")
  } else {
    data.frame(stringsAsFactors = FALSE)
  }
  lyfo <- if (is.data.frame(person_date_mapping)) {
    mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  } else {
    data.frame(stringsAsFactors = FALSE)
  }
  db_available <- mcl_count_db_adapter_available(db_adapter)
  if (identical(mode, "production_aggregate") && db_available) {
    context <- mcl_count_patient_metadata_context(db_adapter, generated_at = generated_at, mode = if (identical(verification_mode, "test_fake_information_schema")) "test" else "production")
    vm <- verification_mode %||% context$verification_mode %||% "production_information_schema"
    columns <- mcl_count_patient_info_schema_columns(db_adapter)
    atlas_columns <- mcl_count_columns_from_atlas_age_inventory(atlas_age_source_inventory)
    if (is.data.frame(atlas_columns) && nrow(atlas_columns)) {
      atlas_columns <- atlas_columns[tolower(atlas_columns$column_name) %in% c("patientid", "date_birth", "date_death_fu"), , drop = FALSE]
      columns <- unique(bind_rows_base(list(columns, atlas_columns[, c("db_name", "schema", "table", "column_name"), drop = FALSE])))
    }
    return(mcl_count_patient_candidate_rows(columns, configured = configured, outputs_dir = outputs_dir, context = context, verification_mode = vm, db_adapter = db_adapter, lyfo_mapping = lyfo))
  }
  existing <- mcl_count_existing_patient_resolver(outputs_dir)
  selected <- mcl_count_selected_patient_resolver(existing)
  if (nrow(selected)) {
    existing$verification_mode <- "plan_reused_resolver_output"
    existing$verified_at <- generated_at
    return(mcl_count_match_empty(existing, mcl_count_empty_patient_demographics_resolver()))
  }
  context <- list(database_name = "", search_path = "", verified_at = generated_at)
  mcl_count_patient_candidate_rows(data.frame(stringsAsFactors = FALSE), configured = configured, outputs_dir = outputs_dir, context = context, verification_mode = "plan_unverified_no_db", db_adapter = NULL, lyfo_mapping = lyfo)
}

mcl_count_column_key <- function(x) {
  out <- tolower(trimws(as.character(x %||% "")))
  out <- gsub("\u00f8", "oe", out, fixed = TRUE)
  out <- gsub("\u00d8", "oe", out, fixed = TRUE)
  out <- gsub("\u00e6", "ae", out, fixed = TRUE)
  out <- gsub("\u00c6", "ae", out, fixed = TRUE)
  out <- gsub("\u00e5", "aa", out, fixed = TRUE)
  out <- gsub("\u00c5", "aa", out, fixed = TRUE)
  gsub("[^a-z0-9]+", "_", out, perl = TRUE)
}

mcl_count_birth_date_column_keys <- function() {
  c(
    "date_birth", "birth_date", "birthdate", "dateofbirth", "date_of_birth",
    "dob", "foedselsdato", "foedsel_dato", "foedsels_dato", "fodselsdato",
    "fodsel_dato", "fodsels_dato", "d_fdsdato", "fdsdato"
  )
}

mcl_count_birth_date_columns <- function(cols, configured_date_columns = character()) {
  cols <- as.character(cols %||% character())
  if (!length(cols)) return(character())
  keys <- mcl_count_column_key(cols)
  configured <- trimws(as.character(configured_date_columns %||% character()))
  configured <- configured[nzchar(configured)]
  configured_birth <- cols[tolower(cols) %in% tolower(configured) & keys %in% mcl_count_birth_date_column_keys()]
  discovered_birth <- cols[keys %in% mcl_count_birth_date_column_keys()]
  unique(c(configured_birth, discovered_birth))
}

mcl_count_patientid_column <- function(cols) {
  cols <- as.character(cols %||% character())
  hit <- cols[tolower(cols) == "patientid"]
  if (length(hit)) hit[[1]] else ""
}

mcl_count_age_column_semantics <- function(column_name) {
  key <- mcl_count_column_key(column_name)
  if (!nzchar(key)) {
    return(list(accepted = FALSE, semantics = "", reason = "missing_age_column_name"))
  }
  has_age_word <- grepl("(^|_)age($|_)|alder|aar|year", key, perl = TRUE)
  if (!has_age_word) {
    return(list(accepted = FALSE, semantics = "", reason = "not_age_like"))
  }
  if (grepl("current|follow|followup|fu|death|doed|dod|last|latest|today|now|seneste|slut|end", key, perl = TRUE)) {
    return(list(accepted = FALSE, semantics = "current_or_followup_age", reason = "rejected_current_or_followup_age"))
  }
  if (grepl("diagnos|diag|dx", key, perl = TRUE)) {
    return(list(accepted = TRUE, semantics = "age_at_diagnosis", reason = "lyfo_age_semantics_verified"))
  }
  if (grepl("registr|(^|_)reg($|_)|indberet|inclusion|inklusion", key, perl = TRUE)) {
    return(list(accepted = TRUE, semantics = "age_at_registration", reason = "lyfo_age_semantics_verified"))
  }
  if (grepl("treat|behand|therapy|kemo|chemo|start|first_line", key, perl = TRUE)) {
    return(list(accepted = TRUE, semantics = "age_at_treatment", reason = "lyfo_age_semantics_verified"))
  }
  list(accepted = FALSE, semantics = "ambiguous_age", reason = "rejected_ambiguous_age_semantics")
}

mcl_count_numeric_sql <- function(expr) {
  expr <- as.character(expr)
  clean <- paste0("nullif(trim(", expr, "::text), '')")
  paste0(
    "(case when ", clean, " ~ '^[0-9]+([.][0-9]+)?$' ",
    "then ", clean, "::numeric else null end)"
  )
}

mcl_count_age_source_info_schema_columns <- function(db_adapter) {
  if (!mcl_count_db_adapter_available(db_adapter)) return(data.frame(stringsAsFactors = FALSE))
  birth_names <- paste(sprintf("'%s'", c(mcl_count_birth_date_column_keys(), paste0("f", "\u00f8", "dselsdato"))), collapse = ", ")
  sql <- paste(
    "select c.table_schema as schema, c.table_name as table, c.column_name as column_name, c.data_type as data_type",
    "from information_schema.columns c",
    "left join information_schema.tables t on t.table_schema = c.table_schema and t.table_name = c.table_name",
    "where coalesce(t.table_type, 'VIEW') in ('BASE TABLE', 'VIEW')",
    "and (",
    "lower(c.column_name) = 'patientid'",
    "or lower(c.column_name) = 'subtype'",
    "or lower(c.column_name) in (", birth_names, ")",
    "or lower(c.column_name) like '%birth%'",
    "or lower(c.column_name) like '%foed%'",
    "or lower(c.column_name) like '%fod%'",
    paste0("or lower(c.column_name) like '%f", "\u00f8", "d%'"),
    "or lower(c.column_name) like '%age%'",
    "or lower(c.column_name) like '%alder%'",
    "or lower(c.table_name) = 'rkkp_lyfo'",
    ")"
  )
  data <- mcl_count_db_query_all_connections(db_adapter, sql)
  if (!is.data.frame(data) || !nrow(data)) return(data.frame(stringsAsFactors = FALSE))
  names(data) <- sub("^table_schema$", "schema", names(data))
  names(data) <- sub("^table_name$", "table", names(data))
  needed <- c("db_name", "schema", "table", "column_name", "data_type")
  data <- mcl_count_ensure_columns(data, needed)
  data$db_name <- as.character(data$db_name)
  data$schema <- as.character(data$schema)
  data$table <- as.character(data$table)
  data$column_name <- as.character(data$column_name)
  data$data_type <- as.character(data$data_type)
  unique(data)
}

mcl_count_age_source_zero_row_probe <- function(db_adapter, schema, table, columns,
                                                lyfo_mapping = NULL,
                                                require_co_residency = FALSE,
                                                patientid_column = "patientid",
                                                db_name = "") {
  columns <- unique(trimws(as.character(columns %||% character())))
  columns <- columns[nzchar(columns)]
  relation_sql <- paste0(
    "select count(*) as probe_count\nfrom ",
    mcl_count_sql_table(schema, table),
    "\nwhere false;"
  )
  column_sql <- paste0(
    "select ",
    paste(vapply(columns, mcl_count_sql_ident, character(1)), collapse = ", "),
    "\nfrom ",
    mcl_count_sql_table(schema, table),
    "\nwhere false;"
  )
  relation <- mcl_count_db_query_result(db_adapter, relation_sql)
  relation_success <- is.data.frame(relation$data) &&
    "probe_count" %in% names(relation$data) &&
    nrow(relation$data) == 1L
  column <- if (relation_success) {
    mcl_count_db_query_result(db_adapter, column_sql)
  } else {
    list(data = NULL, error_class = "", error_message_sanitized = "")
  }
  column_success <- is.data.frame(column$data) &&
    all(tolower(columns) %in% tolower(names(column$data)))
  relation_error <- relation$error_message_sanitized %||% ""
  if (!relation_success && !nzchar(relation_error) && is.data.frame(relation$data)) {
    relation_error <- "Relation probe returned an unexpected result shape; expected one aggregate probe_count column."
  }
  column_error <- column$error_message_sanitized %||% ""
  if (relation_success && !column_success && !nzchar(column_error) && is.data.frame(column$data)) {
    column_error <- "Column probe returned an unexpected result shape for the requested age-source columns."
  }
  co <- if (isTRUE(require_co_residency) && relation_success && column_success) {
    mcl_count_co_residency_probe(db_adapter, lyfo_mapping, schema, table, patientid_column, source_db_name = db_name, lyfo_db_name = lyfo_mapping$db_name[[1]] %||% "")
  } else {
    list(
      co_residency_probe_attempted = FALSE,
      co_residency_probe_success = !isTRUE(require_co_residency),
      co_residency_probe_error_sanitized = ""
    )
  }
  list(
    relation_probe_attempted = TRUE,
    relation_probe_success = relation_success,
    relation_probe_error_sanitized = relation_error,
    column_probe_attempted = relation_success,
    column_probe_success = column_success,
    column_probe_error_sanitized = if (relation_success) column_error else "",
    co_residency_probe_attempted = isTRUE(co$co_residency_probe_attempted),
    co_residency_probe_success = isTRUE(co$co_residency_probe_success),
    co_residency_probe_error_sanitized = co$co_residency_probe_error_sanitized %||% ""
  )
}

mcl_count_age_numeric_plausibility_probe <- function(db_adapter, schema, table, age_column) {
  age_expr <- mcl_count_numeric_sql(paste0("x.", mcl_count_sql_ident(age_column)))
  sql <- paste0(
    "select count(*) as mcl_row_count,\n",
    "       sum(case when ", age_expr, " is not null then 1 else 0 end) as numeric_age_count,\n",
    "       sum(case when ", age_expr, " between 0 and 120 then 1 else 0 end) as plausible_age_count\n",
    "from ", mcl_count_sql_table(schema, table), " x\n",
    "where upper(trim(x.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL';"
  )
  result <- mcl_count_db_query_result(db_adapter, sql)
  data <- result$data
  success <- is.data.frame(data) && nrow(data) == 1L &&
    all(c("numeric_age_count", "plausible_age_count") %in% names(data))
  numeric_count <- if (success) suppressWarnings(as.numeric(data$numeric_age_count[[1]])) else NA_real_
  plausible_count <- if (success) suppressWarnings(as.numeric(data$plausible_age_count[[1]])) else NA_real_
  plausible <- success && !is.na(numeric_count) && numeric_count > 0 && identical(numeric_count, plausible_count)
  list(
    numeric_probe_attempted = TRUE,
    numeric_probe_success = success,
    numeric_age_plausible = plausible,
    numeric_probe_error_sanitized = result$error_message_sanitized %||% ""
  )
}

mcl_count_age_source_candidate_rows <- function(columns, configured = data.frame(stringsAsFactors = FALSE), outputs_dir = NULL,
                                                context = list(), verification_mode = "production_information_schema",
                                                db_adapter = NULL, lyfo_mapping = NULL) {
  empty <- mcl_count_empty_age_source_locator()
  configured_db <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$db_name[[1]] %||% "") else ""
  configured_schema <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$schema[[1]] %||% "") else ""
  configured_table <- if (is.data.frame(configured) && nrow(configured)) as.character(configured$table[[1]] %||% "") else ""
  configured_dates <- if (is.data.frame(configured) && nrow(configured)) {
    strsplit(as.character(configured$date_columns[[1]] %||% ""), ";", fixed = TRUE)[[1]]
  } else {
    character()
  }
  lyfo_db_name <- if (is.data.frame(lyfo_mapping) && nrow(lyfo_mapping)) as.character(lyfo_mapping$db_name[[1]] %||% "") else ""
  mk_row <- function(source_type, db_name = "", schema = "", table = "", patientid_column = "", birth_date_column = "",
                     age_column = "", age_semantics = "", has_patientid = FALSE,
                     has_birth_date_like = FALSE, has_age_like = FALSE, has_mcl_subtype = FALSE,
                     numeric_age_plausible = FALSE, candidate_score = 0L, selected = FALSE,
                     reason = "", usable_for_age_counts = FALSE, probe = list(), numeric_probe = list(),
                     notes = "") {
    meta <- mcl_count_db_age_source_meta(db_name, lyfo_db_name)
    data.frame(
      database_name = context$database_name %||% "",
      search_path = context$search_path %||% "",
      verified_at = context$verified_at %||% mcl_count_now(),
      verification_mode = verification_mode,
      source_type = source_type,
      db_name = meta$db_name,
      source_db_name = meta$source_db_name,
      lyfo_db_name = meta$lyfo_db_name,
      same_db_as_lyfo = isTRUE(meta$same_db_as_lyfo),
      cross_db_join_required = isTRUE(meta$cross_db_join_required),
      cross_db_join_available = isTRUE(meta$cross_db_join_available),
      schema = schema,
      table = table,
      patientid_column = patientid_column,
      birth_date_column = birth_date_column,
      age_column = age_column,
      age_semantics = age_semantics,
      has_patientid = isTRUE(has_patientid),
      has_birth_date_like = isTRUE(has_birth_date_like),
      has_age_like = isTRUE(has_age_like),
      has_mcl_subtype = isTRUE(has_mcl_subtype),
      numeric_age_plausible = isTRUE(numeric_age_plausible),
      candidate_score = as.integer(candidate_score),
      selected = isTRUE(selected),
      reason = reason,
      usable_for_age_counts = isTRUE(usable_for_age_counts),
      relation_probe_attempted = isTRUE(probe$relation_probe_attempted),
      relation_probe_success = isTRUE(probe$relation_probe_success),
      relation_probe_error_sanitized = probe$relation_probe_error_sanitized %||% "",
      column_probe_attempted = isTRUE(probe$column_probe_attempted),
      column_probe_success = isTRUE(probe$column_probe_success),
      column_probe_error_sanitized = probe$column_probe_error_sanitized %||% "",
      co_residency_probe_attempted = isTRUE(probe$co_residency_probe_attempted),
      co_residency_probe_success = isTRUE(probe$co_residency_probe_success),
      co_residency_probe_error_sanitized = probe$co_residency_probe_error_sanitized %||% "",
      numeric_probe_attempted = isTRUE(numeric_probe$numeric_probe_attempted),
      numeric_probe_success = isTRUE(numeric_probe$numeric_probe_success),
      numeric_probe_error_sanitized = numeric_probe$numeric_probe_error_sanitized %||% "",
      deterministic_tie_break_requires_review = FALSE,
      post_selection_execution_attempted = FALSE,
      post_selection_execution_success = FALSE,
      post_selection_execution_error_sanitized = "",
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  if (!is.data.frame(columns) || !nrow(columns)) {
    rows <- list()
    if (nzchar(configured_table)) {
      rows[[1L]] <- mk_row(
        "configured_patient_demographics_birth_date",
        db_name = configured_db,
        schema = configured_schema,
        table = configured_table,
        reason = if (identical(verification_mode, "plan_unverified_no_db")) "no_db_plan_mode" else "configured_relation_missing",
        notes = "Configured patient demographics relation was not verified as a queryable age source."
      )
    } else {
      rows[[1L]] <- mk_row("no_verified_age_source", reason = "no_candidate_columns", notes = "No general demographics birth-date source or LYFO age fallback was verified.")
    }
    return(mcl_count_match_empty(bind_rows_base(rows), empty))
  }
  columns <- mcl_count_ensure_columns(columns, c("db_name", "schema", "table", "column_name", "data_type"))
  keys <- unique(data.frame(db_name = columns$db_name, schema = columns$schema, table = columns$table, stringsAsFactors = FALSE))
  atlas_tables <- mcl_count_patient_atlas_table_names(outputs_dir)
  rows <- list()
  for (i in seq_len(nrow(keys))) {
    db_name <- as.character(keys$db_name[[i]] %||% "")
    schema <- as.character(keys$schema[[i]])
    table <- as.character(keys$table[[i]])
    table_cols <- as.character(columns$column_name[
      tolower(columns$db_name %||% "") == tolower(db_name) &
        tolower(columns$schema) == tolower(schema) &
        tolower(columns$table) == tolower(table)
    ])
    patientid_col <- mcl_count_patientid_column(table_cols)
    birth_cols <- mcl_count_birth_date_columns(table_cols, configured_dates)
    has_patientid <- nzchar(patientid_col)
    has_birth <- length(birth_cols) > 0L
    is_configured <- nzchar(configured_table) &&
      identical(tolower(schema), tolower(configured_schema)) &&
      identical(tolower(table), tolower(configured_table)) &&
      (!nzchar(configured_db) || !nzchar(db_name) || identical(tolower(configured_db), tolower(db_name)))
    is_sds_tumor <- identical(tolower(table), "sds_t_tumor")
    source_type <- if (is_sds_tumor) {
      "same_db_registry_birth_date"
    } else if (is_configured) {
      "configured_patient_demographics_birth_date"
    } else {
      "discovered_patient_demographics_birth_date"
    }
    candidate_kind <- mcl_count_patient_demographics_candidate_kind(schema, table, is_configured = is_configured)
    rejected <- has_patientid && has_birth && !is_sds_tumor &&
      mcl_count_reject_patient_demographics_fallback(schema, table, is_configured = is_configured)
    if (has_patientid || has_birth || is_configured) {
      birth_col <- if (has_birth) birth_cols[[1]] else ""
      probe <- if (has_patientid && has_birth && !rejected && mcl_count_db_adapter_available(db_adapter)) {
        mcl_count_age_source_zero_row_probe(
          db_adapter,
          schema,
          table,
          c(patientid_col, birth_col),
          lyfo_mapping = lyfo_mapping,
          require_co_residency = TRUE,
          patientid_column = patientid_col,
          db_name = db_name
        )
      } else {
        list()
      }
      meta <- mcl_count_db_age_source_meta(db_name, lyfo_db_name)
      probe_success <- isTRUE(probe$relation_probe_success) && isTRUE(probe$column_probe_success) && isTRUE(probe$co_residency_probe_success)
      score <- 0L
      if (is_configured && has_patientid && has_birth) score <- score + 300L
      if (is_sds_tumor && has_patientid && has_birth && !isTRUE(meta$cross_db_join_required)) score <- score + 260L
      if (!is_configured && identical(candidate_kind, "general_patient_demographics") && has_patientid && has_birth) score <- score + 220L
      if (tolower(table) %in% atlas_tables && !rejected) score <- score + 15L
      reason <- if (rejected) {
        "rejected_non_mcl_demographics_source"
      } else if (!has_patientid || !has_birth) {
        "missing_required_age_source_column"
      } else if (!isTRUE(probe$relation_probe_success)) {
        "relation_probe_failed"
      } else if (!isTRUE(probe$column_probe_success)) {
        "column_probe_failed"
      } else if (isTRUE(meta$cross_db_join_required) && !isTRUE(meta$cross_db_join_available)) {
        "cross_database_join_unavailable"
      } else if (is_sds_tumor) {
        "same_db_birth_date_candidate_requires_validation"
      } else if (!isTRUE(probe$co_residency_probe_success)) {
        "co_residency_probe_failed"
      } else {
        "verified_birth_date_age_source"
      }
      rows[[length(rows) + 1L]] <- mk_row(
        source_type,
        db_name = db_name,
        schema = schema,
        table = table,
        patientid_column = patientid_col,
        birth_date_column = birth_col,
        age_semantics = if (has_birth) "birth_date_plus_lyfo_anchor" else "",
        has_patientid = has_patientid,
        has_birth_date_like = has_birth,
        candidate_score = score,
        reason = reason,
        usable_for_age_counts = has_patientid && has_birth && !rejected && probe_success && !is_sds_tumor,
        probe = probe,
        notes = if (rejected) {
          "Rejected as a disease-specific/non-general demographics fallback for MCL age counts."
        } else if (is_sds_tumor && identical(reason, "same_db_birth_date_candidate_requires_validation")) {
          "Same-import-DB tumor birth-date candidate; aggregate validation is required before age counts."
        } else if (identical(reason, "cross_database_join_unavailable")) {
          "Candidate exists but is in a different DB from RKKP_LYFO; no executable same-SQL age join is emitted."
        } else if (is_configured) {
          "Configured demographics mapping is tested before discovered candidates."
        } else {
          ""
        }
      )
    }
    if (identical(tolower(table), "rkkp_lyfo")) {
      has_subtype <- any(tolower(table_cols) == "subtype")
      age_cols <- table_cols[vapply(table_cols, function(col) {
        sem <- mcl_count_age_column_semantics(col)
        !identical(sem$reason, "not_age_like")
      }, logical(1))]
      for (age_col in age_cols) {
        sem <- mcl_count_age_column_semantics(age_col)
        probe <- if (has_patientid && has_subtype && isTRUE(sem$accepted) && mcl_count_db_adapter_available(db_adapter)) {
          mcl_count_age_source_zero_row_probe(db_adapter, schema, table, c(patientid_col, "subtype", age_col), db_name = db_name)
        } else {
          list()
        }
        numeric_probe <- if (isTRUE(probe$relation_probe_success) && isTRUE(probe$column_probe_success)) {
          mcl_count_age_numeric_plausibility_probe(db_adapter, schema, table, age_col)
        } else {
          list()
        }
        probe_success <- isTRUE(probe$relation_probe_success) && isTRUE(probe$column_probe_success)
        numeric_ok <- isTRUE(numeric_probe$numeric_age_plausible)
        reason <- if (!has_patientid) {
          "missing_patientid"
        } else if (!has_subtype) {
          "missing_mcl_subtype_column"
        } else if (!isTRUE(sem$accepted)) {
          sem$reason
        } else if (!isTRUE(probe$relation_probe_success)) {
          "relation_probe_failed"
        } else if (!isTRUE(probe$column_probe_success)) {
          "column_probe_failed"
        } else if (!numeric_ok) {
          "numeric_plausibility_probe_failed"
        } else {
          "verified_lyfo_age_fallback"
        }
        rows[[length(rows) + 1L]] <- mk_row(
          "lyfo_age_fallback",
          db_name = db_name,
          schema = schema,
          table = table,
          patientid_column = patientid_col,
          age_column = age_col,
          age_semantics = sem$semantics %||% "",
          has_patientid = has_patientid,
          has_age_like = TRUE,
          has_mcl_subtype = has_subtype,
          numeric_age_plausible = numeric_ok,
          candidate_score = if (numeric_ok) 120L else 0L,
          reason = reason,
          usable_for_age_counts = has_patientid && has_subtype && isTRUE(sem$accepted) && probe_success && numeric_ok,
          probe = probe,
          numeric_probe = numeric_probe,
          notes = if (numeric_ok) {
            "Accepted only as a LYFO-internal age-at-diagnosis/registration/treatment aggregate fallback; no patient demographics join is used."
          } else {
            "LYFO age fallback candidates must be numeric, plausibly bounded, and clearly anchored to diagnosis, registration, or treatment."
          }
        )
      }
    }
  }
  if (!length(rows)) {
    rows[[1L]] <- mk_row("no_verified_age_source", reason = "no_candidate_columns", notes = "No general demographics birth-date source or LYFO age fallback was verified.")
  }
  out <- bind_rows_base(rows)
  if (nzchar(configured_table)) {
    configured_present <- any(
      tolower(out$schema %||% "") == tolower(configured_schema) &
        tolower(out$table %||% "") == tolower(configured_table) &
        (!nzchar(configured_db) | !nzchar(out$db_name %||% "") | tolower(out$db_name %||% "") == tolower(configured_db)),
      na.rm = TRUE
    )
    if (!configured_present) {
      out <- bind_rows_base(list(
        mk_row(
          "configured_patient_demographics_birth_date",
          db_name = configured_db,
          schema = configured_schema,
          table = configured_table,
          reason = if (identical(verification_mode, "plan_unverified_no_db")) "no_db_plan_mode" else "configured_relation_missing",
          notes = "Configured patient demographics relation was not verified as a queryable age source."
        ),
        out
      ))
    }
  }
  selectable <- out[out$usable_for_age_counts %in% TRUE, , drop = FALSE]
  if (nrow(selectable)) {
    ord <- order(-selectable$candidate_score, tolower(selectable$db_name %||% ""), tolower(selectable$source_type), tolower(selectable$schema), tolower(selectable$table), tolower(selectable$birth_date_column), tolower(selectable$age_column))
    selectable <- selectable[ord, , drop = FALSE]
    top_score <- selectable$candidate_score[[1]]
    tied <- sum(selectable$candidate_score == top_score, na.rm = TRUE) > 1L
    winner <- tolower(out$db_name %||% "") == tolower(selectable$db_name[[1]] %||% "") &
      tolower(out$source_type) == tolower(selectable$source_type[[1]]) &
      tolower(out$schema) == tolower(selectable$schema[[1]]) &
      tolower(out$table) == tolower(selectable$table[[1]]) &
      tolower(out$birth_date_column) == tolower(selectable$birth_date_column[[1]]) &
      tolower(out$age_column) == tolower(selectable$age_column[[1]])
    out$selected <- FALSE
    out$selected[winner] <- TRUE
    out$deterministic_tie_break_requires_review <- FALSE
    out$deterministic_tie_break_requires_review[winner] <- tied
    out$reason[winner] <- if (tied) "deterministic_tie_break_requires_review" else out$reason[winner]
    out$reason[out$usable_for_age_counts %in% TRUE & !winner] <- ifelse(tied & out$candidate_score[out$usable_for_age_counts %in% TRUE & !winner] == top_score, "tie_lost", "lower_score")
  }
  mcl_count_match_empty(out, empty)
}

mcl_count_existing_age_source_locator <- function(outputs_dir = NULL) {
  if (is.null(outputs_dir) || !dir.exists(outputs_dir)) return(mcl_count_empty_age_source_locator())
  path <- file.path(outputs_dir, "mcl_triangle_age_source_locator.csv")
  if (!file.exists(path)) return(mcl_count_empty_age_source_locator())
  out <- tryCatch(read_delimited_file(path), error = function(e) mcl_count_empty_age_source_locator())
  mcl_count_match_empty(out, mcl_count_empty_age_source_locator())
}

mcl_count_selected_age_source_locator <- function(locator) {
  if (!is.data.frame(locator) || !nrow(locator)) return(data.frame(stringsAsFactors = FALSE))
  locator <- mcl_count_match_empty(locator, mcl_count_empty_age_source_locator())
  hit <- locator[
    locator$selected %in% TRUE &
      locator$usable_for_age_counts %in% TRUE &
      locator$relation_probe_success %in% TRUE &
      locator$column_probe_success %in% TRUE,
    ,
    drop = FALSE
  ]
  if (!nrow(hit)) return(data.frame(stringsAsFactors = FALSE))
  lyfo <- hit$source_type == "lyfo_age_fallback"
  hit <- hit[lyfo | hit$co_residency_probe_success %in% TRUE, , drop = FALSE]
  if (!nrow(hit)) return(data.frame(stringsAsFactors = FALSE))
  lyfo <- hit$source_type == "lyfo_age_fallback"
  hit <- hit[!lyfo | (hit$numeric_probe_success %in% TRUE & hit$numeric_age_plausible %in% TRUE), , drop = FALSE]
  if (nrow(hit) == 1L) hit else data.frame(stringsAsFactors = FALSE)
}

mcl_count_age_source_locator_from_patient_resolver <- function(patient_demographics_resolver, generated_at = mcl_count_now()) {
  selected <- mcl_count_selected_patient_resolver(patient_demographics_resolver)
  if (!nrow(selected)) return(mcl_count_empty_age_source_locator())
  out <- data.frame(
    database_name = selected$database_name[[1]] %||% "",
    search_path = selected$search_path[[1]] %||% "",
    verified_at = generated_at,
    verification_mode = "from_patient_demographics_resolver",
    source_type = "configured_patient_demographics_birth_date",
    db_name = selected$db_name[[1]] %||% "",
    source_db_name = selected$source_db_name[[1]] %||% selected$db_name[[1]] %||% "",
    lyfo_db_name = selected$lyfo_db_name[[1]] %||% "",
    same_db_as_lyfo = selected$same_db_as_lyfo[[1]] %in% TRUE,
    cross_db_join_required = selected$cross_db_join_required[[1]] %in% TRUE,
    cross_db_join_available = selected$cross_db_join_available[[1]] %in% TRUE,
    schema = selected$schema[[1]] %||% "",
    table = selected$table[[1]] %||% "",
    patientid_column = "patientid",
    birth_date_column = "date_birth",
    age_column = "",
    age_semantics = "birth_date_plus_lyfo_anchor",
    has_patientid = TRUE,
    has_birth_date_like = TRUE,
    has_age_like = FALSE,
    has_mcl_subtype = FALSE,
    numeric_age_plausible = FALSE,
    candidate_score = 300L,
    selected = TRUE,
    reason = selected$reason[[1]] %||% "verified_birth_date_age_source",
    usable_for_age_counts = TRUE,
    relation_probe_attempted = selected$relation_probe_attempted[[1]] %in% TRUE,
    relation_probe_success = selected$relation_probe_success[[1]] %in% TRUE,
    relation_probe_error_sanitized = selected$relation_probe_error_sanitized[[1]] %||% "",
    column_probe_attempted = selected$column_probe_attempted[[1]] %in% TRUE,
    column_probe_success = selected$column_probe_success[[1]] %in% TRUE,
    column_probe_error_sanitized = selected$column_probe_error_sanitized[[1]] %||% "",
    co_residency_probe_attempted = selected$co_residency_probe_attempted[[1]] %in% TRUE,
    co_residency_probe_success = selected$co_residency_probe_success[[1]] %in% TRUE,
    co_residency_probe_error_sanitized = selected$co_residency_probe_error_sanitized[[1]] %||% "",
    numeric_probe_attempted = FALSE,
    numeric_probe_success = FALSE,
    numeric_probe_error_sanitized = "",
    deterministic_tie_break_requires_review = selected$deterministic_tie_break_requires_review[[1]] %in% TRUE,
    post_selection_execution_attempted = selected$post_selection_execution_attempted[[1]] %in% TRUE,
    post_selection_execution_success = selected$post_selection_execution_success[[1]] %in% TRUE,
    post_selection_execution_error_sanitized = selected$post_selection_execution_error_sanitized[[1]] %||% "",
    notes = "Age source derived from the verified patient demographics resolver.",
    stringsAsFactors = FALSE
  )
  mcl_count_match_empty(out, mcl_count_empty_age_source_locator())
}

mcl_count_resolve_age_source <- function(project_root = ".", outputs_dir = NULL, db_adapter = NULL,
                                         person_date_mapping = NULL, patient_demographics_resolver = NULL,
                                         mode = "plan", generated_at = mcl_count_now(),
                                         verification_mode = NULL,
                                         atlas_age_source_inventory = NULL) {
  configured <- if (is.data.frame(person_date_mapping)) {
    mcl_count_source_mapping(person_date_mapping, "patient", "")
  } else {
    data.frame(stringsAsFactors = FALSE)
  }
  lyfo <- if (is.data.frame(person_date_mapping)) {
    mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  } else {
    data.frame(stringsAsFactors = FALSE)
  }
  db_available <- mcl_count_db_adapter_available(db_adapter)
  if (identical(mode, "production_aggregate") && db_available) {
    context <- mcl_count_patient_metadata_context(db_adapter, generated_at = generated_at, mode = if (identical(verification_mode, "test_fake_information_schema")) "test" else "production")
    vm <- verification_mode %||% context$verification_mode %||% "production_information_schema"
    columns <- mcl_count_age_source_info_schema_columns(db_adapter)
    atlas_columns <- mcl_count_columns_from_atlas_age_inventory(atlas_age_source_inventory)
    if (is.data.frame(atlas_columns) && nrow(atlas_columns)) {
      columns <- unique(bind_rows_base(list(columns, atlas_columns[, c("db_name", "schema", "table", "column_name", "data_type"), drop = FALSE])))
    }
    return(mcl_count_age_source_candidate_rows(columns, configured = configured, outputs_dir = outputs_dir, context = context, verification_mode = vm, db_adapter = db_adapter, lyfo_mapping = lyfo))
  }
  existing <- mcl_count_existing_age_source_locator(outputs_dir)
  if (nrow(mcl_count_selected_age_source_locator(existing))) {
    existing$verification_mode <- "plan_reused_age_source_locator"
    existing$verified_at <- generated_at
    return(mcl_count_match_empty(existing, mcl_count_empty_age_source_locator()))
  }
  from_patient <- mcl_count_age_source_locator_from_patient_resolver(patient_demographics_resolver, generated_at = generated_at)
  if (nrow(mcl_count_selected_age_source_locator(from_patient))) return(from_patient)
  context <- list(database_name = "", search_path = "", verified_at = generated_at)
  mcl_count_age_source_candidate_rows(data.frame(stringsAsFactors = FALSE), configured = configured, outputs_dir = outputs_dir, context = context, verification_mode = "plan_unverified_no_db", db_adapter = NULL, lyfo_mapping = lyfo)
}

mcl_count_metadata_confirms_mcl <- function(outputs_dir = NULL) {
  if (is.null(outputs_dir) || !dir.exists(outputs_dir)) return(FALSE)
  inv_path <- file.path(outputs_dir, "mcl_triangle_variable_inventory.csv")
  if (file.exists(inv_path)) {
    inv <- tryCatch(read_delimited_file(inv_path), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (is.data.frame(inv) && nrow(inv)) {
      source <- tolower(as.character(inv$source %||% ""))
      field <- tolower(as.character(inv$raw_field %||% ""))
      value <- toupper(trimws(as.character(inv$code_or_value %||% "")))
      concept <- tolower(as.character(inv$concept_name %||% ""))
      if (any(source == "rkkp_lyfo" & field == "subtype" & value == "MCL" & grepl("mcl|mantle", concept), na.rm = TRUE)) {
        return(TRUE)
      }
    }
  }
  value_path <- file.path(outputs_dir, "atlas_value_frequencies.csv")
  if (file.exists(value_path)) {
    vf <- tryCatch(read_delimited_file(value_path), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (is.data.frame(vf) && nrow(vf)) {
      table <- tolower(as.character(vf$table_name %||% ""))
      field <- tolower(as.character(vf$column_name %||% ""))
      value <- toupper(trimws(as.character(vf$value %||% "")))
      if (any(table == "rkkp_lyfo" & field == "subtype" & value == "MCL", na.rm = TRUE)) return(TRUE)
    }
  }
  FALSE
}

mcl_count_value_mapping_confirms_mcl <- function(value_mappings) {
  if (!is.data.frame(value_mappings) || !nrow(value_mappings)) return(FALSE)
  hit <- value_mappings[
    value_mappings$data_point_id == "all_lyfo_mcl" &
      tolower(value_mappings$table) == "rkkp_lyfo" &
      tolower(value_mappings$field) == "subtype" &
      toupper(trimws(value_mappings$mapped_values)) == "MCL" &
      grepl("validated|confirmed|full_atlas", value_mappings$validation_status, ignore.case = TRUE),
    ,
    drop = FALSE
  ]
  nrow(hit) > 0L
}

mcl_count_date_sql <- function(expr) {
  expr <- as.character(expr)
  clean <- paste0("nullif(trim(", expr, "::text), '')")
  iso <- paste0("substring(", clean, " from 1 for 10)")
  dmy <- paste0("replace(replace(substring(", clean, " from 1 for 10), '.', '-'), '/', '-')")
  paste0(
    "(case ",
    "when ", clean, " is null then null ",
    "when ", clean, " ~ '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])' ",
    "and to_char(to_date(", iso, ", 'YYYY-MM-DD'), 'YYYY-MM-DD') = ", iso, " ",
    "then to_date(", iso, ", 'YYYY-MM-DD') ",
    "when ", clean, " ~ '^(0[1-9]|[12][0-9]|3[01])[-./](0[1-9]|1[0-2])[-./][0-9]{4}' ",
    "and to_char(to_date(", dmy, ", 'DD-MM-YYYY'), 'DD-MM-YYYY') = ", dmy, " ",
    "then to_date(", dmy, ", 'DD-MM-YYYY') ",
    "else null end)"
  )
}

mcl_count_first_available_column <- function(cols, candidates) {
  cols <- as.character(cols %||% character())
  hit <- candidates[candidates %in% cols]
  if (length(hit)) hit[[1]] else ""
}

mcl_count_mapping_date_anchor <- function(mapping, anchor_type = c("diagnosis", "treatment", "event")) {
  anchor_type <- match.arg(anchor_type)
  if (!is.data.frame(mapping) || !nrow(mapping)) return("")
  if (identical(anchor_type, "diagnosis")) return(as.character(mapping$diagnosis_date_column[[1]] %||% ""))
  if (identical(anchor_type, "treatment")) return(as.character(mapping$treatment_start_date_column[[1]] %||% ""))
  as.character(mapping$event_date_column[[1]] %||% "")
}

mcl_count_age_anchor <- function(lyfo_mapping) {
  if (!is.data.frame(lyfo_mapping) || !nrow(lyfo_mapping)) return("")
  date_cols <- strsplit(as.character(lyfo_mapping$date_columns[[1]] %||% ""), ";", fixed = TRUE)[[1]]
  date_cols <- trimws(date_cols[nzchar(date_cols)])
  priority <- c(
    "Reg_BehandlingBeslutning_dt",
    "Beh_KemoterapiStart_dt",
    "Reg_DiagnostiskBiopsi_dt",
    as.character(lyfo_mapping$diagnosis_date_column[[1]] %||% "")
  )
  mcl_count_first_available_column(date_cols, unique(priority[nzchar(priority)]))
}

mcl_count_age_anchor_order <- function(order = c("primary", "diagnosis_first")) {
  order <- match.arg(order)
  if (identical(order, "diagnosis_first")) {
    c("Reg_DiagnostiskBiopsi_dt", "Reg_BehandlingBeslutning_dt", "Beh_KemoterapiStart_dt")
  } else {
    c("Reg_BehandlingBeslutning_dt", "Beh_KemoterapiStart_dt", "Reg_DiagnostiskBiopsi_dt")
  }
}

mcl_count_age_anchor_columns <- function(lyfo_mapping, order = mcl_count_age_anchor_order("primary")) {
  if (!is.data.frame(lyfo_mapping) || !nrow(lyfo_mapping)) return(character())
  date_cols <- strsplit(as.character(lyfo_mapping$date_columns[[1]] %||% ""), ";", fixed = TRUE)[[1]]
  date_cols <- trimws(date_cols[nzchar(date_cols)])
  order <- unique(c(order, as.character(lyfo_mapping$diagnosis_date_column[[1]] %||% "")))
  order <- order[nzchar(order)]
  order[order %in% date_cols]
}

mcl_count_age_anchor_sql_info <- function(lyfo_mapping, alias = "r", order = mcl_count_age_anchor_order("primary")) {
  cols <- mcl_count_age_anchor_columns(lyfo_mapping, order = order)
  if (!length(cols)) {
    first <- mcl_count_age_anchor(lyfo_mapping)
    if (nzchar(first)) cols <- first
  }
  exprs <- vapply(cols, function(col) mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident(col))), character(1))
  expr <- if (!length(exprs)) "" else if (length(exprs) == 1L) exprs[[1]] else paste0("coalesce(", paste(exprs, collapse = ", "), ")")
  list(expr = expr, columns = cols, label = paste(cols, collapse = ";"))
}

mcl_count_age_years_sql <- function(anchor_expr, birth_expr) {
  paste0(
    "case when ", birth_expr, " is not null and ", anchor_expr, " is not null ",
    "then floor((", anchor_expr, " - ", birth_expr, ")::numeric / 365.2425) else null end"
  )
}

mcl_count_tumor_birth_date_validation_sql <- function(lyfo_mapping, candidate, anchor_order) {
  lyfo_ref <- mcl_count_sql_table(lyfo_mapping$schema[[1]], lyfo_mapping$table[[1]])
  tumor_ref <- mcl_count_sql_table(candidate$schema[[1]], candidate$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo_mapping$person_key_column[[1]])
  tumor_key <- mcl_count_sql_ident(candidate$patientid_column[[1]] %||% "patientid")
  birth_col <- mcl_count_sql_ident(candidate$birth_date_column[[1]] %||% "d_fdsdato")
  anchor_info <- mcl_count_age_anchor_sql_info(lyfo_mapping, alias = "r", order = anchor_order)
  anchor_expr <- anchor_info$expr
  birth_expr <- mcl_count_date_sql(paste0("t.", birth_col))
  age_years_expr <- mcl_count_age_years_sql("m.age_anchor", "b.birth_date")
  paste0(
    "with mcl_rows as (\n",
    "  select distinct r.", lyfo_key, " as person_key,\n",
    "         ", anchor_expr, " as age_anchor\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), mcl as (\n",
    "  select person_key, min(age_anchor) as age_anchor\n",
    "  from mcl_rows\n",
    "  group by person_key\n",
    "), births as (\n",
    "  select t.", tumor_key, " as person_key,\n",
    "         min(", birth_expr, ") as birth_date,\n",
    "         count(distinct ", birth_expr, ") as birth_date_count\n",
    "  from ", tumor_ref, " t\n",
    "  group by t.", tumor_key, "\n",
    "), scored as (\n",
    "  select m.person_key,\n",
    "         m.age_anchor,\n",
    "         b.birth_date,\n",
    "         coalesce(b.birth_date_count, 0) as birth_date_count,\n",
    "         ", age_years_expr, " as age_years\n",
    "  from mcl m\n",
    "  left join births b on b.person_key = m.person_key\n",
    ")\n",
    "select count(*) as mcl_people,\n",
    "       sum(case when birth_date is not null then 1 else 0 end) as people_with_birth_date,\n",
    "       sum(case when age_anchor is not null then 1 else 0 end) as people_with_age_anchor,\n",
    "       sum(case when age_years between 0 and 120 then 1 else 0 end) as people_with_plausible_age,\n",
    "       sum(case when birth_date_count > 1 then 1 else 0 end) as people_with_multiple_birth_dates,\n",
    "       sum(case when age_years between 0 and 65 then 1 else 0 end) as age_le_65_people,\n",
    "       sum(case when age_years > 65 and age_years <= 120 then 1 else 0 end) as age_gt_65_people,\n",
    "       sum(case when age_years is null or not (age_years between 0 and 120) then 1 else 0 end) as age_missing_or_uncomputable_people\n",
    "from scored;"
  )
}

mcl_count_age_source_validation_row <- function(candidate = data.frame(stringsAsFactors = FALSE),
                                                validation_id = "",
                                                anchor_order = character(),
                                                query_attempted = FALSE,
                                                query_success = FALSE,
                                                validation_status = "same_db_birth_date_validation_failed",
                                                selected_for_age_counts = FALSE,
                                                error_message_sanitized = "",
                                                notes = "",
                                                metrics = list()) {
  metric <- function(name) {
    value <- suppressWarnings(as.integer(as.numeric(metrics[[name]] %||% NA_integer_)))
    if (is.na(value)) NA_integer_ else value
  }
  data.frame(
    validation_id = validation_id,
    source_type = candidate$source_type[[1]] %||% "",
    db_name = candidate$db_name[[1]] %||% "",
    schema = candidate$schema[[1]] %||% "",
    table = candidate$table[[1]] %||% "",
    patientid_column = candidate$patientid_column[[1]] %||% "",
    birth_date_column = candidate$birth_date_column[[1]] %||% "",
    anchor_order = paste(anchor_order, collapse = ";"),
    mcl_people = metric("mcl_people"),
    people_with_birth_date = metric("people_with_birth_date"),
    people_with_age_anchor = metric("people_with_age_anchor"),
    people_with_plausible_age = metric("people_with_plausible_age"),
    people_with_multiple_birth_dates = metric("people_with_multiple_birth_dates"),
    age_le_65_people = metric("age_le_65_people"),
    age_gt_65_people = metric("age_gt_65_people"),
    age_missing_or_uncomputable_people = metric("age_missing_or_uncomputable_people"),
    query_attempted = isTRUE(query_attempted),
    query_success = isTRUE(query_success),
    validation_status = validation_status,
    selected_for_age_counts = isTRUE(selected_for_age_counts),
    error_message_sanitized = error_message_sanitized %||% "",
    notes = notes,
    stringsAsFactors = FALSE
  )
}

mcl_count_validate_tumor_birth_date_candidate <- function(db_adapter, lyfo_mapping, candidate,
                                                          validation_id,
                                                          anchor_order,
                                                          multiple_birth_date_tolerance = 0L) {
  if (!mcl_count_db_adapter_available(db_adapter)) {
    return(mcl_count_age_source_validation_row(candidate, validation_id, anchor_order,
      query_attempted = FALSE,
      validation_status = "same_db_birth_date_validation_failed",
      notes = "No DB adapter was available for aggregate age-source validation."
    ))
  }
  sql <- mcl_count_tumor_birth_date_validation_sql(lyfo_mapping, candidate, anchor_order)
  result <- mcl_count_db_query_result(db_adapter, sql)
  data <- result$data
  needed <- c(
    "mcl_people", "people_with_birth_date", "people_with_age_anchor",
    "people_with_plausible_age", "people_with_multiple_birth_dates",
    "age_le_65_people", "age_gt_65_people", "age_missing_or_uncomputable_people"
  )
  success <- is.data.frame(data) && nrow(data) == 1L && all(needed %in% names(data))
  metrics <- if (success) as.list(data[1, needed, drop = FALSE]) else list()
  multiple_births <- suppressWarnings(as.integer(as.numeric(metrics$people_with_multiple_birth_dates %||% NA_integer_)))
  mcl_people <- suppressWarnings(as.integer(as.numeric(metrics$mcl_people %||% NA_integer_)))
  plausible <- suppressWarnings(as.integer(as.numeric(metrics$people_with_plausible_age %||% NA_integer_)))
  valid <- success &&
    !is.na(mcl_people) && mcl_people > 0L &&
    !is.na(plausible) && plausible > 0L &&
    !is.na(multiple_births) && multiple_births <= as.integer(multiple_birth_date_tolerance)
  status <- if (valid) "same_db_birth_date_source_validated" else "same_db_birth_date_validation_failed"
  err <- result$error_message_sanitized %||% ""
  if (!success && !nzchar(err) && is.data.frame(data)) {
    err <- "Age-source validation returned an unexpected aggregate result shape."
  }
  mcl_count_age_source_validation_row(
    candidate,
    validation_id,
    anchor_order,
    query_attempted = TRUE,
    query_success = success,
    validation_status = status,
    selected_for_age_counts = valid && identical(validation_id, "primary"),
    error_message_sanitized = err,
    notes = if (valid) {
      "Same-DB SDS_t_tumor birth-date source passed aggregate validation; age <=65 remains a younger proxy, not transplant eligibility."
    } else if (success && !is.na(multiple_births) && multiple_births > as.integer(multiple_birth_date_tolerance)) {
      "Validation failed because at least one joined MCL person had multiple distinct birth dates."
    } else {
      "Validation failed; age counts remain unavailable."
    },
    metrics = metrics
  )
}

mcl_count_validate_age_source_candidates <- function(age_source_locator, person_date_mapping, db_adapter,
                                                     multiple_birth_date_tolerance = 0L) {
  locator <- mcl_count_match_empty(age_source_locator, mcl_count_empty_age_source_locator())
  lyfo <- mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  if (!nrow(locator) || !mcl_count_mapping_usable(lyfo)) return(mcl_count_empty_age_source_validation())
  candidates <- locator[
    locator$source_type == "same_db_registry_birth_date" &
      locator$table == "SDS_t_tumor" &
      locator$relation_probe_success %in% TRUE &
      locator$column_probe_success %in% TRUE &
      locator$co_residency_probe_success %in% TRUE,
    ,
    drop = FALSE
  ]
  if (!nrow(candidates)) return(mcl_count_empty_age_source_validation())
  candidates <- candidates[order(-candidates$candidate_score, tolower(candidates$db_name %||% ""), tolower(candidates$schema), tolower(candidates$table)), , drop = FALSE]
  candidate <- candidates[1, , drop = FALSE]
  primary_order <- mcl_count_age_anchor_order("primary")
  sensitivity_order <- mcl_count_age_anchor_order("diagnosis_first")
  bind_rows_base(list(
    mcl_count_validate_tumor_birth_date_candidate(db_adapter, lyfo, candidate, "primary", primary_order, multiple_birth_date_tolerance),
    mcl_count_validate_tumor_birth_date_candidate(db_adapter, lyfo, candidate, "diagnosis_first_sensitivity", sensitivity_order, multiple_birth_date_tolerance)
  ))
}

mcl_count_apply_age_source_validation <- function(age_source_locator, age_source_validation) {
  locator <- mcl_count_match_empty(age_source_locator, mcl_count_empty_age_source_locator())
  validation <- mcl_count_match_empty(age_source_validation, mcl_count_empty_age_source_validation())
  if (!nrow(locator) || !nrow(validation)) return(locator)
  primary <- validation[validation$validation_id == "primary", , drop = FALSE]
  if (!nrow(primary)) return(locator)
  match <- locator$source_type == primary$source_type[[1]] &
    tolower(locator$db_name %||% "") == tolower(primary$db_name[[1]] %||% "") &
    tolower(locator$schema) == tolower(primary$schema[[1]]) &
    tolower(locator$table) == tolower(primary$table[[1]]) &
    tolower(locator$patientid_column) == tolower(primary$patientid_column[[1]]) &
    tolower(locator$birth_date_column) == tolower(primary$birth_date_column[[1]])
  if (!any(match, na.rm = TRUE)) return(locator)
  if (primary$selected_for_age_counts[[1]] %in% TRUE && identical(primary$validation_status[[1]], "same_db_birth_date_source_validated")) {
    locator$selected <- FALSE
    locator$usable_for_age_counts[match] <- TRUE
    locator$selected[match] <- TRUE
    locator$reason[match] <- "same_db_birth_date_source_validated"
    locator$notes[match] <- trimws(paste(
      locator$notes[match],
      "same_db_tumor_birth_date_used; aggregate validation passed. Age <=65 is a younger proxy, not transplant eligibility."
    ))
  } else {
    locator$selected[match] <- FALSE
    locator$usable_for_age_counts[match] <- FALSE
    locator$reason[match] <- "same_db_birth_date_validation_failed"
    locator$notes[match] <- trimws(paste(locator$notes[match], primary$notes[[1]] %||% "Age source validation failed."))
  }
  mcl_count_match_empty(locator, mcl_count_empty_age_source_locator())
}

mcl_count_value_rows <- function(value_mappings, data_point_id) {
  if (!is.data.frame(value_mappings) || !nrow(value_mappings)) return(data.frame(stringsAsFactors = FALSE))
  value_mappings[value_mappings$data_point_id == data_point_id, , drop = FALSE]
}

mcl_count_has_validated_value_rule <- function(value_rows) {
  if (!is.data.frame(value_rows) || !nrow(value_rows)) return(FALSE)
  any(grepl("^validated|validated_", value_rows$validation_status, ignore.case = TRUE), na.rm = TRUE)
}

mcl_count_landmark_days <- function() 183L

mcl_count_landmark_info <- function(lyfo, alias = "x", days = mcl_count_landmark_days()) {
  treatment_anchor <- mcl_count_mapping_date_anchor(lyfo, "treatment")
  if (!nzchar(treatment_anchor %||% "")) return(list(treatment_expr = "", landmark_expr = "", label = ""))
  treatment_expr <- mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident(treatment_anchor)))
  list(
    treatment_expr = treatment_expr,
    landmark_expr = paste0("(", treatment_expr, " + ", as.integer(days), ")"),
    label = paste0(treatment_anchor, " + ", as.integer(days), " days")
  )
}

mcl_count_lyfo_death_expr <- function(alias = "x") {
  paste0(
    "coalesce(",
    mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident("FU_Doedsdato"))), ", ",
    mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident("CPR_Doedsdato"))),
    ")"
  )
}

mcl_count_lyfo_relapse_expr <- function(alias = "x") {
  mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident("Rec_RelapsProgressions_dt")))
}

mcl_count_nonempty_text_sql <- function(expr) {
  paste0("nullif(trim(", expr, "::text), '') is not null")
}

mcl_count_any_nonempty_text_sql <- function(alias, columns) {
  columns <- columns[nzchar(columns)]
  if (!length(columns)) return("false")
  paste(
    vapply(columns, function(col) mcl_count_nonempty_text_sql(paste0(alias, ".", mcl_count_sql_ident(col))), character(1)),
    collapse = " or "
  )
}

mcl_count_mipi_component_predicate_sql <- function(alias = "x") {
  mcl_count_any_nonempty_text_sql(alias, c("Reg_PerformanceStatusWHO", "Reg_LDHVaerdi", "Reg_Leukocytter"))
}

mcl_count_asct_hdt_by_landmark_predicate_sql <- function(alias = "x", landmark_expr) {
  infusion_date <- mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident("Beh_Stamcelleinfusion_dt")))
  paste0(
    "(",
    "(", infusion_date, " is not null and ", infusion_date, " <= ", landmark_expr, ")",
    " or upper(trim(", alias, ".", mcl_count_sql_ident("Beh_Hoejdosisbehandling"), "::text)) = 'Y'",
    " or upper(trim(", alias, ".", mcl_count_sql_ident("Beh_TypeAutologStamcellestoette"), "::text)) in ('BEAM','OTHER','BCNU-THIOTEPA','BCNU','BEAC')",
    ")"
  )
}

mcl_count_lyfo_ibrutinib_predicate_sql <- function(alias = "x") {
  paste(
    paste0("upper(trim(", alias, ".", mcl_count_sql_ident(c("Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3")), "::text)) = 'IBRUTINIB'"),
    collapse = " or "
  )
}

mcl_count_read_toxicity_source_mapping <- function(project_root) {
  x <- mcl_count_read_mapping_tsv(project_root, "mcl_triangle_toxicity_source_mapping.tsv")
  needed <- c(
    "source_id", "db_name", "schema", "table", "person_key_column", "date_columns",
    "code_column", "source_role", "linkage_confidence", "usable_for_counts", "notes"
  )
  mcl_count_ensure_columns(x, needed)
}

mcl_count_read_toxicity_endpoint_codes <- function(project_root) {
  x <- mcl_count_read_mapping_tsv(project_root, "mcl_triangle_infection_endpoint_code_sets.tsv")
  needed <- c("endpoint_id", "endpoint_label", "code_system", "match_type", "code_prefix", "definition_status", "notes")
  mcl_count_ensure_columns(x, needed)
}

mcl_count_serious_infection_code_prefixes <- function(project_root) {
  codes <- mcl_count_read_toxicity_endpoint_codes(project_root)
  if (!is.data.frame(codes) || !nrow(codes)) return(character())
  hit <- codes$endpoint_id == "serious_infection_hospitalization" & tolower(codes$match_type %||% "") == "prefix"
  unique(toupper(trimws(as.character(codes$code_prefix[hit] %||% character()))))
}

mcl_count_normalized_code_expr_sql <- function(alias, column) {
  paste0("regexp_replace(upper(trim(", alias, ".", mcl_count_sql_ident(column), "::text)), '[^A-Z0-9]', '', 'g')")
}

mcl_count_prefix_predicate_sql <- function(expr, prefixes) {
  prefixes <- prefixes[nzchar(prefixes)]
  if (!length(prefixes)) return("false")
  paste(vapply(prefixes, function(prefix) paste0(expr, " like ", mcl_count_sql_string(paste0(prefix, "%"))), character(1)), collapse = " or ")
}

mcl_count_toxicity_infection_source_sql <- function(mapping, prefixes) {
  if (!is.data.frame(mapping) || !nrow(mapping)) return("")
  if (!mcl_count_bool(mapping$usable_for_counts[[1]])) return("")
  person <- mapping$person_key_column[[1]] %||% ""
  code <- mapping$code_column[[1]] %||% ""
  if (!nzchar(person) || !nzchar(code) || !nzchar(mapping$date_columns[[1]] %||% "")) return("")
  alias <- "s"
  event_date <- mcl_count_date_coalesce_sql(alias, mapping$date_columns[[1]])
  norm_code <- mcl_count_normalized_code_expr_sql(alias, code)
  pred <- mcl_count_prefix_predicate_sql(norm_code, prefixes)
  paste0(
    "select distinct ", alias, ".", mcl_count_sql_ident(person), "::text as person_key,\n",
    "       ", event_date, " as event_date\n",
    "from ", mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]]), " ", alias, "\n",
    "where ", alias, ".", mcl_count_sql_ident(person), " is not null\n",
    "  and ", event_date, " is not null\n",
    "  and (", pred, ")"
  )
}

mcl_count_serious_infection_union_sql <- function(project_root) {
  mappings <- mcl_count_read_toxicity_source_mapping(project_root)
  prefixes <- mcl_count_serious_infection_code_prefixes(project_root)
  if (!is.data.frame(mappings) || !nrow(mappings) || !length(prefixes)) return("")
  hit <- mappings$source_role %in% c("diagnosis_state_and_infection", "provisional_infection_event") &
    mcl_count_bool(mappings$usable_for_counts %||% FALSE) &
    nzchar(mappings$person_key_column %||% "") &
    nzchar(mappings$date_columns %||% "") &
    nzchar(mappings$code_column %||% "")
  sources <- mappings[hit, , drop = FALSE]
  pieces <- lapply(seq_len(nrow(sources)), function(i) mcl_count_toxicity_infection_source_sql(sources[i, , drop = FALSE], prefixes))
  pieces <- pieces[nzchar(unlist(pieces, use.names = FALSE))]
  if (!length(pieces)) return("")
  paste(vapply(pieces, identity, character(1)), collapse = "\nunion\n")
}

mcl_count_toxicity_proxy_data_sql <- function(lyfo, project_root, days = 365L) {
  info <- mcl_count_landmark_info(lyfo, alias = "r", days = 0L)
  infection_union <- mcl_count_serious_infection_union_sql(project_root)
  if (!nzchar(info$treatment_expr) || !nzchar(infection_union)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  paste0(
    "  with mcl_anchor as (\n",
    "    select distinct r.", lyfo_key, " as person_key,\n",
    "           ", info$treatment_expr, " as first_line_date\n",
    "    from ", lyfo_ref, " r\n",
    "    where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "      and ", info$treatment_expr, " is not null\n",
    "  ), infection_events as (\n",
    "    ", gsub("\n", "\n    ", infection_union, fixed = TRUE), "\n",
    "  )\n",
    "  select distinct m.person_key\n",
    "  from mcl_anchor m\n",
    "  join infection_events e on e.person_key::text = m.person_key::text\n",
    "  where e.event_date >= m.first_line_date\n",
    "    and e.event_date <= (m.first_line_date + ", as.integer(days), ")"
  )
}

mcl_count_high_risk_pre_landmark_data_sql <- function(lyfo, pato, project_root) {
  if (!mcl_count_mapping_usable(pato)) return("")
  info <- mcl_count_landmark_info(lyfo, alias = "r")
  if (!nzchar(info$treatment_expr)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  pato_ref <- mcl_count_sql_table(pato$schema[[1]], pato$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  pato_key <- mcl_count_sql_ident(pato$person_key_column[[1]])
  threshold <- mcl_count_high_risk_threshold(project_root)
  code <- "upper(p.\"c_snomedkode\"::text)"
  percent <- paste0("substring(", code, " from '(?:AEKI|Ã†KI|Ãƒâ€ KI)([0-9]{3})')::integer")
  pato_anchor <- mcl_count_mapping_date_anchor(pato, "event")
  pato_date <- if (nzchar(pato_anchor %||% "")) {
    mcl_count_date_sql(paste0("p.", mcl_count_sql_ident(pato_anchor)))
  } else {
    mcl_count_date_coalesce_sql("p", pato$date_columns[[1]])
  }
  paste0(
    "  with mcl_anchor as (\n",
    "    select distinct r.", lyfo_key, " as person_key,\n",
    "           ", info$treatment_expr, " as first_line_date,\n",
    "           ", info$landmark_expr, " as landmark_date\n",
    "    from ", lyfo_ref, " r\n",
    "    where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "      and ", info$treatment_expr, " is not null\n",
    "  ), ki67_high as (\n",
    "    select distinct m.person_key\n",
    "    from mcl_anchor m\n",
    "    join ", pato_ref, " p on p.", pato_key, "::text = m.person_key::text\n",
    "    where ", pato_date, " is not null\n",
    "      and ", pato_date, " <= m.landmark_date\n",
    "      and ", code, " ~ '^(AEKI|Ã†KI|Ãƒâ€ KI)[0-9]{3}$'\n",
    "      and ", percent, " >= ", as.numeric(threshold), "\n",
    "  ), mipi_components as (\n",
    "    select distinct r.", lyfo_key, " as person_key\n",
    "    from ", lyfo_ref, " r\n",
    "    where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "      and ", info$treatment_expr, " is not null\n",
    "      and (", mcl_count_mipi_component_predicate_sql("r"), ")\n",
    "  )\n",
    "  select person_key from ki67_high\n",
    "  union\n",
    "  select person_key from mipi_components"
  )
}

mcl_count_data_point_rule <- function(id, project_root, outputs_dir, person_date_mapping, value_mappings,
                                      patient_demographics_resolver = NULL,
                                      age_source_locator = NULL,
                                      ibrutinib_source_validation = NULL,
                                      treatment_code_mappings = NULL) {
  lyfo <- mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  pato <- mcl_count_source_mapping(person_date_mapping, "SDS_pato", "SDS_pato")
  selected_patient <- mcl_count_selected_patient_resolver(patient_demographics_resolver)
  selected_age_source <- mcl_count_selected_age_source_locator(age_source_locator)
  mcl_confirmed <- mcl_count_metadata_confirms_mcl(outputs_dir) || mcl_count_value_mapping_confirms_mcl(value_mappings)
  mcl_predicate <- "upper(trim(r.\"subtype\"::text)) = 'MCL'"
  if (!mcl_count_mapping_usable(lyfo)) {
    return(list(executable = FALSE, status = "count_not_available_requires_person_key_mapping", reason = "RKKP_LYFO person key is not validated.", source_tables = "RKKP_LYFO", person_key = "", date_anchor = "", value_rule = ""))
  }
  if (!mcl_confirmed) {
    return(list(executable = FALSE, status = "count_not_available_requires_value_mapping", reason = "MCL subtype value is not confirmed in LYFO metadata/value mappings.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "", value_rule = "subtype = MCL requires confirmation"))
  }
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  patient_ref <- if (nrow(selected_patient)) mcl_count_sql_table(selected_patient$schema[[1]], selected_patient$table[[1]]) else ""
  pato_ref <- if (mcl_count_mapping_usable(pato)) mcl_count_sql_table(pato$schema[[1]], pato$table[[1]]) else ""
  patient_source_label <- if (nrow(selected_patient)) paste0(selected_patient$schema[[1]], ".", selected_patient$table[[1]]) else "patient_demographics_unverified"
  age_source_label <- if (nrow(selected_age_source)) paste0(selected_age_source$schema[[1]], ".", selected_age_source$table[[1]]) else patient_source_label
  patient_validation_status <- if (nrow(selected_patient) && identical(selected_patient$reason[[1]], "deterministic_tie_break_requires_review")) {
    "requires_patient_demographics_review"
  } else {
    "mapped_for_production_aggregate"
  }
  age_validation_status <- if (nrow(selected_age_source) && identical(selected_age_source$reason[[1]], "deterministic_tie_break_requires_review")) {
    "requires_age_source_review"
  } else if (nrow(selected_age_source) && identical(selected_age_source$reason[[1]], "same_db_birth_date_source_validated")) {
    "same_db_birth_date_source_validated"
  } else if (nrow(selected_age_source) && identical(selected_age_source$reason[[1]], "verified_lyfo_age_fallback")) {
    "lyfo_age_fallback_validated"
  } else {
    "mapped_for_production_aggregate"
  }
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  denom_cte <- paste0("denominator as (\n  select distinct r.", lyfo_key, " as person_key\n  from ", lyfo_ref, " r\n  where ", mcl_predicate, "\n)")
  mk <- function(data_sql, source_tables, person_key, date_anchor, value_rule, status = "mapped_for_production_aggregate", reason = "") {
    list(
      executable = TRUE,
      status = status,
      reason = reason,
      denominator_cte = denom_cte,
      data_point_cte = paste0("data_point as (\n", data_sql, "\n)"),
      source_tables = source_tables,
      person_key = person_key,
      date_anchor = date_anchor,
      value_rule = value_rule
    )
  }
  same_lyfo <- function(predicate, date_anchor = "", value_rule = predicate, status = "mapped_for_production_aggregate") {
    mk(
      paste0("  select distinct x.", lyfo_key, " as person_key\n  from ", lyfo_ref, " x\n  where ", predicate),
      "public.RKKP_LYFO",
      lyfo$person_key_column[[1]],
      date_anchor,
      value_rule,
      status = status
    )
  }
  age_birth_source <- function(join_type, patient_ref, patientid_col, birth_col) {
    if (nrow(selected_age_source) && identical(selected_age_source$source_type[[1]], "same_db_registry_birth_date")) {
      tumor_birth_expr <- mcl_count_date_sql(paste0("t.", mcl_count_sql_ident(birth_col)))
      return(list(
        join_sql = paste0(
          join_type, " (\n",
          "    select t.", mcl_count_sql_ident(patientid_col), " as person_key,\n",
          "           min(", tumor_birth_expr, ") as birth_date\n",
          "    from ", patient_ref, " t\n",
          "    group by t.", mcl_count_sql_ident(patientid_col), "\n",
          "  ) p on p.person_key = r.", lyfo_key
        ),
        birth_expr = "p.birth_date"
      ))
    }
    list(
      join_sql = paste0(join_type, " ", patient_ref, " p on p.", mcl_count_sql_ident(patientid_col), " = r.", lyfo_key),
      birth_expr = mcl_count_date_sql(paste0("p.", mcl_count_sql_ident(birth_col)))
    )
  }
  if (identical(id, "all_lyfo_mcl")) {
    return(mk("  select person_key from denominator", "public.RKKP_LYFO", lyfo$person_key_column[[1]], mcl_count_mapping_date_anchor(lyfo, "diagnosis"), "RKKP_LYFO.subtype = 'MCL'"))
  }
  if (identical(id, "younger_mcl_proxy_age_le_65")) {
    if (!nrow(selected_age_source)) {
      return(list(executable = FALSE, status = mcl_count_patient_demographics_status(), reason = "requires patient demographics mapping or verified LYFO age fallback", source_tables = paste("RKKP_LYFO", "age_source_unverified", sep = "; "), person_key = lyfo$person_key_column[[1]], date_anchor = "", value_rule = "age <=65"))
    }
    if (identical(selected_age_source$source_type[[1]], "lyfo_age_fallback")) {
      age_expr <- mcl_count_numeric_sql(paste0("r.", mcl_count_sql_ident(selected_age_source$age_column[[1]])))
      sql <- paste0(
        "  select distinct r.", lyfo_key, " as person_key\n",
        "  from ", lyfo_ref, " r\n",
        "  where ", mcl_predicate, "\n",
        "    and ", age_expr, " between 0 and 65"
      )
      return(mk(sql, paste0(lyfo$schema[[1]], ".", lyfo$table[[1]]), lyfo$person_key_column[[1]], selected_age_source$age_semantics[[1]], paste0(selected_age_source$age_column[[1]], " <=65 using verified LYFO ", selected_age_source$age_semantics[[1]], " fallback"), status = age_validation_status))
    }
    anchor_info <- mcl_count_age_anchor_sql_info(lyfo, alias = "r")
    if (!nzchar(anchor_info$expr)) {
      return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "No LYFO diagnosis/treatment/inclusion date anchor was validated for age <=65.", source_tables = "RKKP_LYFO; patient", person_key = "patientid", date_anchor = "", value_rule = "age <=65"))
    }
    patient_ref <- mcl_count_sql_table(selected_age_source$schema[[1]], selected_age_source$table[[1]])
    patientid_col <- selected_age_source$patientid_column[[1]] %||% "patientid"
    birth_col <- selected_age_source$birth_date_column[[1]] %||% "date_birth"
    birth_source <- age_birth_source("join", patient_ref, patientid_col, birth_col)
    anchor_expr <- anchor_info$expr
    birth_expr <- birth_source$birth_expr
    age_years_expr <- mcl_count_age_years_sql(anchor_expr, birth_expr)
    sql <- paste0(
      "  select distinct r.", lyfo_key, " as person_key\n",
      "  from ", lyfo_ref, " r\n",
      "  ", birth_source$join_sql, "\n",
      "  where ", mcl_predicate, "\n",
      "    and ", birth_expr, " is not null\n",
      "    and ", anchor_expr, " is not null\n",
      "    and ", age_years_expr, " between 0 and 65"
    )
    return(mk(sql, paste(paste0(lyfo$schema[[1]], ".", lyfo$table[[1]]), age_source_label, sep = "; "), patientid_col, anchor_info$label, paste0("age at coalesced LYFO anchor < 66 years using ", birth_col), status = age_validation_status))
  }
  if (id %in% c("birth_date_available", "age_anchor_available", "age_computable", "age_gt_65", "age_missing_uncomputable")) {
    if (!nrow(selected_age_source)) {
      return(list(executable = FALSE, status = mcl_count_patient_demographics_status(), reason = "requires patient demographics mapping or verified LYFO age fallback", source_tables = paste("RKKP_LYFO", "age_source_unverified", sep = "; "), person_key = lyfo$person_key_column[[1]], date_anchor = "", value_rule = id))
    }
    if (identical(selected_age_source$source_type[[1]], "lyfo_age_fallback")) {
      if (identical(id, "birth_date_available")) {
        return(list(executable = FALSE, status = "not_applicable", reason = "Birth-date diagnostic is not applicable when a verified LYFO age-at-diagnosis/registration/treatment fallback is used.", source_tables = paste0(lyfo$schema[[1]], ".", lyfo$table[[1]]), person_key = lyfo$person_key_column[[1]], date_anchor = selected_age_source$age_semantics[[1]], value_rule = id))
      }
      age_expr <- mcl_count_numeric_sql(paste0("r.", mcl_count_sql_ident(selected_age_source$age_column[[1]])))
      pred <- switch(
        id,
        age_anchor_available = paste0(age_expr, " is not null"),
        age_computable = paste0(age_expr, " between 0 and 120"),
        age_gt_65 = paste0(age_expr, " > 65 and ", age_expr, " <= 120"),
        age_missing_uncomputable = paste0("(", age_expr, " is null or not (", age_expr, " between 0 and 120))")
      )
      sql <- paste0(
        "  select distinct r.", lyfo_key, " as person_key\n",
        "  from ", lyfo_ref, " r\n",
        "  where ", mcl_predicate, "\n",
        "    and ", pred
      )
      return(mk(sql, paste0(lyfo$schema[[1]], ".", lyfo$table[[1]]), lyfo$person_key_column[[1]], selected_age_source$age_semantics[[1]], paste0(id, " using verified LYFO ", selected_age_source$age_column[[1]], " fallback"), status = age_validation_status))
    }
    anchor_info <- mcl_count_age_anchor_sql_info(lyfo, alias = "r")
    if (!nzchar(anchor_info$expr)) {
      return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "No LYFO diagnosis/treatment date anchor was validated for age diagnostics.", source_tables = "RKKP_LYFO; patient", person_key = "patientid", date_anchor = "", value_rule = id))
    }
    patient_ref <- mcl_count_sql_table(selected_age_source$schema[[1]], selected_age_source$table[[1]])
    patientid_col <- selected_age_source$patientid_column[[1]] %||% "patientid"
    birth_col <- selected_age_source$birth_date_column[[1]] %||% "date_birth"
    birth_source <- age_birth_source("left join", patient_ref, patientid_col, birth_col)
    anchor_expr <- anchor_info$expr
    birth_expr <- birth_source$birth_expr
    age_years_expr <- mcl_count_age_years_sql(anchor_expr, birth_expr)
    pred <- switch(
      id,
      birth_date_available = paste0(birth_expr, " is not null"),
      age_anchor_available = paste0(anchor_expr, " is not null"),
      age_computable = paste0(age_years_expr, " between 0 and 120"),
      age_gt_65 = paste0(age_years_expr, " > 65 and ", age_years_expr, " <= 120"),
      age_missing_uncomputable = paste0("(", age_years_expr, " is null or not (", age_years_expr, " between 0 and 120))")
    )
    sql <- paste0(
      "  select distinct r.", lyfo_key, " as person_key\n",
      "  from ", lyfo_ref, " r\n",
      "  ", birth_source$join_sql, "\n",
      "  where ", mcl_predicate, "\n",
      "    and ", pred
    )
    return(mk(sql, paste(paste0(lyfo$schema[[1]], ".", lyfo$table[[1]]), age_source_label, sep = "; "), patientid_col, anchor_info$label, paste0(id, " using guarded ", birth_col, "/coalesced anchor date parsing"), status = age_validation_status))
  }
  if (identical(id, "diagnosis_date")) {
    anchor <- mcl_count_mapping_date_anchor(lyfo, "diagnosis")
    if (!nzchar(anchor)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "No LYFO diagnosis date anchor is validated.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "", value_rule = "diagnosis date non-missing"))
    return(same_lyfo(paste0(mcl_count_date_sql(paste0("x.", mcl_count_sql_ident(anchor))), " is not null"), anchor, paste0(anchor, " valid date")))
  }
  if (identical(id, "first_line_treatment_date")) {
    anchor <- mcl_count_mapping_date_anchor(lyfo, "treatment")
    if (!nzchar(anchor)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "No first-line treatment date anchor is validated.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "", value_rule = "first-line date non-missing"))
    return(same_lyfo(paste0(mcl_count_date_sql(paste0("x.", mcl_count_sql_ident(anchor))), " is not null"), anchor, paste0(anchor, " valid date")))
  }
  if (identical(id, "cit_immunochemotherapy")) {
    regimen_values <- c(
      "CHOP", "BENDAMUSTIN", "MAXICHOP", "MANTLE2", "MANTLE3", "HDARAC", "DHAP",
      "BEAM", "BCNU", "BEAC", "CVP", "CHLORAMBUCIL", "CYCLOPHOSPHAMIDE", "IBRUTINIB"
    )
    regimen_sql <- paste(sprintf("'%s'", regimen_values), collapse = ",")
    regimen_pred <- paste(
      paste0("upper(trim(x.", mcl_count_sql_ident(c("Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3")), "::text)) in (", regimen_sql, ")"),
      collapse = " or "
    )
    immuno_pred <- "upper(trim(x.\"Beh_Immunoterapi\"::text)) in ('RITUXIMAB','OBINUTUZUMAB')"
    pred <- paste0("upper(trim(x.\"Beh_ErDerForetagetKemo\"::text)) = 'Y' or ", regimen_pred, " or ", immuno_pred)
    return(same_lyfo(pred, mcl_count_mapping_date_anchor(lyfo, "treatment"), "LYFO chemo Y, regimen, or immunotherapy mapped from full-atlas value evidence"))
  }
  if (identical(id, "asct_hdt_first_line")) {
    pred <- paste0(
      mcl_count_date_sql("x.\"Beh_Stamcelleinfusion_dt\""), " is not null",
      " or upper(trim(x.\"Beh_Hoejdosisbehandling\"::text)) = 'Y'",
      " or upper(trim(x.\"Beh_TypeAutologStamcellestoette\"::text)) in ('BEAM','OTHER','BCNU-THIOTEPA','BCNU','BEAC')"
    )
    return(same_lyfo(pred, "Beh_Stamcelleinfusion_dt", "LYFO Beh_* ASCT/HDT fields", status = "aggregate_evidence_found_requires_validation"))
  }
  if (identical(id, "asct_hdt_relapse_recurrence")) {
    pred <- paste0(
      mcl_count_date_sql("x.\"Rec_Stamcelleinfusion_dt\""), " is not null",
      " or upper(trim(x.\"Rec_Hoejdosisbehandling\"::text)) = 'Y'"
    )
    return(same_lyfo(pred, "Rec_Stamcelleinfusion_dt", "LYFO Rec_* relapse/recurrence ASCT/HDT fields", status = "aggregate_evidence_found_requires_validation"))
  }
  if (identical(id, "ibrutinib_exposure")) {
    mappings <- treatment_code_mappings %||% mcl_count_read_treatment_code_mappings(project_root)
    union_sql <- if (is.data.frame(ibrutinib_source_validation) && nrow(ibrutinib_source_validation)) {
      mcl_count_ibrutinib_union_data_sql(ibrutinib_source_validation, mappings)
    } else {
      ""
    }
    selected <- if (is.data.frame(ibrutinib_source_validation)) mcl_count_ibrutinib_selected_validation(ibrutinib_source_validation) else data.frame(stringsAsFactors = FALSE)
    if (nzchar(union_sql)) {
      return(mk(
        union_sql,
        paste(unique(selected$canonical_source_id), collapse = "; "),
        lyfo$person_key_column[[1]],
        mcl_count_mapping_date_anchor(lyfo, "treatment"),
        paste0("deduplicated validated Ibrutinib union: ", paste(selected$source_id, collapse = "; ")),
        status = mcl_count_ibrutinib_validation_summary_status(ibrutinib_source_validation)
      ))
    }
    pred <- paste(
      paste0("upper(trim(x.", mcl_count_sql_ident(c("Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3")), "::text)) = 'IBRUTINIB'"),
      collapse = " or "
    )
    return(same_lyfo(pred, mcl_count_mapping_date_anchor(lyfo, "treatment"), "LYFO regimen field equals ibrutinib; ATC/SKS expansion requires production aggregate source validation and is never inferred from CLL source names", status = "aggregate_evidence_found_requires_validation"))
  }
  if (identical(id, "os_death")) {
    pred <- paste0(
      mcl_count_date_sql("x.\"FU_Doedsdato\""), " is not null or ",
      mcl_count_date_sql("x.\"CPR_Doedsdato\""), " is not null or upper(trim(x.\"FU_LeverPatienten\"::text)) in ('N','NEJ','NO','0','FALSE')"
    )
    return(same_lyfo(pred, "FU_Doedsdato;CPR_Doedsdato", "LYFO death/status fields"))
  }
  if (identical(id, "relapse_progression_ffs_proxy")) {
    return(same_lyfo(paste0(mcl_count_date_sql("x.\"Rec_RelapsProgressions_dt\""), " is not null"), "Rec_RelapsProgressions_dt", "LYFO relapse/progression date"))
  }
  if (identical(id, "ki67_aeki")) {
    if (!mcl_count_mapping_usable(pato)) {
      return(list(executable = FALSE, status = "count_not_available_requires_person_key_mapping", reason = "SDS_pato patientid linkage is not validated.", source_tables = "SDS_pato", person_key = "", date_anchor = "", value_rule = "AEKI000-AEKI100"))
    }
    code <- "upper(x.\"c_snomedkode\"::text)"
    percent <- paste0("substring(", code, " from '(?:AEKI|ÆKI|Ã†KI)([0-9]{3})')::integer")
    pred <- paste0(code, " ~ '^(AEKI|ÆKI|Ã†KI)[0-9]{3}$' and ", percent, " between 0 and 100")
    data_sql <- paste0("  select distinct x.", mcl_count_sql_ident(pato$person_key_column[[1]]), " as person_key\n  from ", pato_ref, " x\n  where ", pred)
    return(mk(data_sql, "public.SDS_pato", pato$person_key_column[[1]], mcl_count_mapping_date_anchor(pato, "event"), "SDS_pato.c_snomedkode valid AEKI000-AEKI100", status = "aggregate_evidence_found_requires_validation"))
  }
  if (identical(id, "mipi_mipic_components")) {
    return(same_lyfo("x.\"Reg_PerformanceStatusWHO\" is not null or x.\"Reg_LDHVaerdi\" is not null or x.\"Reg_Leukocytter\" is not null", mcl_count_mapping_date_anchor(lyfo, "diagnosis"), "MIPI/MIPI-c component availability", status = "aggregate_evidence_found_requires_validation"))
  }
  if (identical(id, "toxicity_proxies")) {
    data_sql <- mcl_count_toxicity_proxy_data_sql(lyfo, project_root, days = 365L)
    if (!nzchar(data_sql)) {
      return(list(executable = FALSE, status = "count_not_available_requires_value_mapping", reason = "Toxicity proxy requires executable MCL/TRIANGLE serious-infection code/source mappings.", source_tables = "MCL/TRIANGLE provisional serious-infection sources; RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "first_line_start_to_365_days", value_rule = "serious infection diagnosis prefix within 365 days after first-line start"))
    }
    return(mk(
      data_sql,
      "RKKP_LYFO; MCL/TRIANGLE provisional serious-infection diagnosis sources",
      lyfo$person_key_column[[1]],
      "Beh_KemoterapiStart_dt to 365 days after first-line start",
      "repo-derived provisional serious-infection code prefixes after first-line start",
      status = "repo-derived provisional aggregate"
    ))
  }
  if (identical(id, "alive_at_landmark")) {
    info <- mcl_count_landmark_info(lyfo, alias = "x")
    if (!nzchar(info$treatment_expr)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "Alive-at-landmark requires a first-line treatment date anchor.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "landmark_after_first_line_start", value_rule = "alive at landmark date-window"))
    death_expr <- mcl_count_lyfo_death_expr("x")
    pred <- paste0(info$treatment_expr, " is not null and (", death_expr, " is null or ", death_expr, " > ", info$landmark_expr, ")")
    return(same_lyfo(pred, info$label, "first-line anchor plus LYFO death-date fields; alive at 6-month landmark if no death date before/at landmark", status = "repo-derived provisional aggregate"))
  }
  if (identical(id, "asct_hdt_status_known_landmark")) {
    info <- mcl_count_landmark_info(lyfo, alias = "x")
    if (!nzchar(info$treatment_expr)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "ASCT/HDT by landmark requires a first-line treatment date anchor.", source_tables = "RKKP_LYFO Beh_*", person_key = lyfo$person_key_column[[1]], date_anchor = "landmark_after_first_line_start", value_rule = "ASCT/HDT evidence by landmark"))
    pred <- paste0(info$treatment_expr, " is not null and ", mcl_count_asct_hdt_by_landmark_predicate_sql("x", info$landmark_expr))
    return(same_lyfo(pred, info$label, "LYFO Beh_* ASCT/HDT evidence present by 6-month landmark; absence is not inferred", status = "repo-derived provisional aggregate"))
  }
  if (identical(id, "ibrutinib_status_known_landmark")) {
    info <- mcl_count_landmark_info(lyfo, alias = "x")
    if (!nzchar(info$treatment_expr)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "Ibrutinib by landmark requires a first-line treatment date anchor.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "landmark_after_first_line_start", value_rule = "Ibrutinib exposure before/at landmark"))
    pred <- paste0(info$treatment_expr, " is not null and (", mcl_count_lyfo_ibrutinib_predicate_sql("x"), ")")
    return(same_lyfo(pred, info$label, "LYFO regimen field equals ibrutinib before/at 6-month landmark; absence is not inferred", status = "repo-derived provisional aggregate"))
  }
  if (identical(id, "event_free_pre_landmark")) {
    info <- mcl_count_landmark_info(lyfo, alias = "x")
    if (!nzchar(info$treatment_expr)) return(list(executable = FALSE, status = "count_not_available_requires_date_mapping", reason = "Event-free pre-landmark requires a first-line treatment date anchor.", source_tables = "RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "landmark_after_first_line_start", value_rule = "no event before landmark date-window"))
    death_expr <- mcl_count_lyfo_death_expr("x")
    relapse_expr <- mcl_count_lyfo_relapse_expr("x")
    pred <- paste0(
      info$treatment_expr, " is not null",
      " and (", death_expr, " is null or ", death_expr, " > ", info$landmark_expr, ")",
      " and (", relapse_expr, " is null or ", relapse_expr, " > ", info$landmark_expr, ")"
    )
    return(same_lyfo(pred, info$label, "no LYFO death or relapse/progression date before/at 6-month landmark", status = "repo-derived provisional aggregate"))
  }
  if (identical(id, "high_risk_biology_pre_landmark")) {
    data_sql <- mcl_count_high_risk_pre_landmark_data_sql(lyfo, pato, project_root)
    if (!nzchar(data_sql)) {
      return(list(executable = FALSE, status = "count_not_available_requires_value_mapping", reason = "High-risk biology before landmark requires executable Ki-67 AEKI and LYFO MIPI component mappings.", source_tables = "SDS_pato; RKKP_LYFO", person_key = lyfo$person_key_column[[1]], date_anchor = "landmark_after_first_line_start", value_rule = "Ki-67 high threshold or MIPI component availability before landmark"))
    }
    return(mk(
      data_sql,
      "SDS_pato; RKKP_LYFO",
      lyfo$person_key_column[[1]],
      "Beh_KemoterapiStart_dt + 183 days",
      "Ki-67 AEKI high threshold before landmark or LYFO MIPI/MIPI-c component availability; TP53 and morphology not inferred",
      status = "repo-derived provisional aggregate"
    ))
  }
  list(executable = FALSE, status = "count_not_available_requires_value_mapping", reason = paste("No validated value mapping for", id), source_tables = "", person_key = "", date_anchor = "", value_rule = "")
}

mcl_count_compose_count_sql <- function(rule, id) {
  paste0(
    "with ", rule$denominator_cte, ",\n", rule$data_point_cte, "\n",
    "select '", id, "' as data_point_id,\n",
    "       count(*) as distinct_person_count\n",
    "from denominator d\n",
    "join data_point x using (person_key);"
  )
}

mcl_count_rule_with_denominator <- function(rule, denom_rule) {
  if (!isTRUE(rule$executable)) return(rule)
  if (!isTRUE(denom_rule$executable)) {
    return(list(
      executable = FALSE,
      status = denom_rule$status %||% "count_not_available_requires_value_mapping",
      reason = paste("Denominator is not executable:", denom_rule$reason %||% "requires mapping"),
      source_tables = paste(unique(c(denom_rule$source_tables %||% "", rule$source_tables %||% "")), collapse = "; "),
      person_key = rule$person_key %||% "",
      date_anchor = rule$date_anchor %||% "",
      value_rule = rule$value_rule %||% ""
    ))
  }
  rule$denominator_cte <- sub("^data_point\\s+as\\s*\\(", "denominator as (", denom_rule$data_point_cte, ignore.case = TRUE, perl = TRUE)
  rule$source_tables <- paste(unique(trimws(c(strsplit(denom_rule$source_tables %||% "", ";", fixed = TRUE)[[1]], strsplit(rule$source_tables %||% "", ";", fixed = TRUE)[[1]]))), collapse = "; ")
  rule
}

mcl_count_build_query_plan <- function(defs, project_root = ".", outputs_dir = NULL,
                                       patient_demographics_resolver = NULL,
                                       age_source_locator = NULL,
                                       ibrutinib_source_validation = NULL,
                                       treatment_code_mappings = NULL) {
  pdm <- mcl_count_read_person_date_mapping(project_root)
  vm <- mcl_count_read_value_mappings(project_root)
  if (is.null(treatment_code_mappings)) treatment_code_mappings <- mcl_count_read_treatment_code_mappings(project_root)
  if (is.null(patient_demographics_resolver)) {
    patient_demographics_resolver <- mcl_count_resolve_patient_demographics(
      project_root = project_root,
      outputs_dir = outputs_dir,
      db_adapter = NULL,
      person_date_mapping = pdm,
      mode = "plan"
    )
  }
  if (is.null(age_source_locator)) {
    age_source_locator <- mcl_count_resolve_age_source(
      project_root = project_root,
      outputs_dir = outputs_dir,
      db_adapter = NULL,
      person_date_mapping = pdm,
      patient_demographics_resolver = patient_demographics_resolver,
      mode = "plan"
    )
  }
  rows <- list()
  sql <- character()
  for (i in seq_len(nrow(defs))) {
    id <- defs$data_point_id[[i]]
    rule <- mcl_count_data_point_rule(id, project_root, outputs_dir, pdm, vm, patient_demographics_resolver = patient_demographics_resolver, age_source_locator = age_source_locator, ibrutinib_source_validation = ibrutinib_source_validation, treatment_code_mappings = treatment_code_mappings)
    denom_id <- defs$denominator[[i]]
    if (nzchar(denom_id %||% "") && !identical(denom_id, "all_lyfo_mcl") && !identical(denom_id, id)) {
      denom_rule <- mcl_count_data_point_rule(denom_id, project_root, outputs_dir, pdm, vm, patient_demographics_resolver = patient_demographics_resolver, age_source_locator = age_source_locator, ibrutinib_source_validation = ibrutinib_source_validation, treatment_code_mappings = treatment_code_mappings)
      rule <- mcl_count_rule_with_denominator(rule, denom_rule)
    }
    query_id <- paste0("mcl_triangle_", id)
    executable <- isTRUE(rule$executable)
    section <- if (executable) {
      mcl_count_compose_count_sql(rule, id)
    } else if (identical(rule$status %||% "", mcl_count_patient_demographics_status())) {
      paste0("-- NOT EXECUTABLE: requires patient demographics mapping\n-- Reason: ", rule$reason)
    } else if (identical(rule$status %||% "", "not_applicable")) {
      paste0("-- NOT EXECUTABLE: not applicable for selected age source\n-- Reason: ", rule$reason)
    } else {
      paste0("-- NOT EXECUTABLE: requires mapping for ", id, "\n-- Reason: ", rule$reason)
    }
    sql <- c(sql, paste0("-- query_id: ", query_id, "\n", section, "\n"))
    rows[[length(rows) + 1L]] <- data.frame(
      query_id = query_id,
      output_file = "mcl_triangle_data_point_counts.csv",
      denominator = defs$denominator[[i]],
      data_point = id,
      timing_window = defs$valid_time_window[[i]],
      tables_used = rule$source_tables %||% "",
      person_key_used = rule$person_key %||% "",
      date_anchor_used = rule$date_anchor %||% "",
      value_rule_used = rule$value_rule %||% "",
      small_cell_suppression_applied = TRUE,
      emits_only_aggregate_counts = TRUE,
      query_executable = executable,
      reviewer_notes = if (executable) rule$status else rule$reason,
      stringsAsFactors = FALSE
    )
  }
  list(sql = paste(sql, collapse = "\n"), review = bind_rows_base(rows), person_date_mapping = pdm, value_mappings = vm, patient_demographics_resolver = patient_demographics_resolver, age_source_locator = age_source_locator)
}

mcl_count_empty_query_review <- function() {
  empty_df(
    query_id = character(),
    output_file = character(),
    denominator = character(),
    data_point = character(),
    timing_window = character(),
    tables_used = character(),
    person_key_used = character(),
    date_anchor_used = character(),
    value_rule_used = character(),
    small_cell_suppression_applied = logical(),
    emits_only_aggregate_counts = logical(),
    query_executable = logical(),
    reviewer_notes = character()
  )
}

mcl_count_empty_patient_demographics_resolver <- function() {
  empty_df(
    database_name = character(),
    search_path = character(),
    verified_at = character(),
    verification_mode = character(),
    db_name = character(),
    source_db_name = character(),
    lyfo_db_name = character(),
    same_db_as_lyfo = logical(),
    cross_db_join_required = logical(),
    cross_db_join_available = logical(),
    schema = character(),
    table = character(),
    has_patientid = logical(),
    has_date_birth = logical(),
    has_date_death_fu = logical(),
    candidate_score = integer(),
    selected = logical(),
    reason = character(),
    usable_for_age_counts = logical(),
    relation_probe_attempted = logical(),
    relation_probe_success = logical(),
    relation_probe_error_sanitized = character(),
    column_probe_attempted = logical(),
    column_probe_success = logical(),
    column_probe_error_sanitized = character(),
    co_residency_probe_attempted = logical(),
    co_residency_probe_success = logical(),
    co_residency_probe_error_sanitized = character(),
    deterministic_tie_break_requires_review = logical(),
    post_selection_execution_attempted = logical(),
    post_selection_execution_success = logical(),
    post_selection_execution_error_sanitized = character(),
    notes = character()
  )
}

mcl_count_empty_output_generation_status <- function() {
  empty_df(
    output_file = character(),
    generated_after_latest_mapping_change = logical(),
    mode = character(),
    stale = logical(),
    notes = character()
  )
}

mcl_count_empty_execution_summary <- function() {
  empty_df(
    mode = character(),
    db_connection_attempted = logical(),
    db_connection_available = logical(),
    executable_queries = integer(),
    executed_queries = integer(),
    failed_queries = integer(),
    populated_count_outputs = integer(),
    populated_intersection_outputs = integer(),
    atlas_age_inventory_rows = integer(),
    age_validation_queries = integer(),
    atlas_treatment_inventory_rows = integer(),
    ibrutinib_validation_queries = integer(),
    atlas_ki67_inventory_rows = integer(),
    ki67_validation_queries = integer(),
    production_aggregate_succeeded = logical(),
    core_marginal_counts_succeeded = logical(),
    age_validation_succeeded = logical(),
    ibrutinib_validation_succeeded = logical(),
    ki67_validation_succeeded = logical(),
    atlas_ingestion_succeeded = logical(),
    acceptance_status = character(),
    failure_reason = character()
  )
}

mcl_count_percent_display <- function(n, denom, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  denom_num <- suppressWarnings(as.numeric(denom))
  if (is.na(n_num) || is.na(denom_num) || denom_num <= 0) return("")
  if (n_num > 0 && n_num < min_cell_count) return("")
  if (denom_num > 0 && denom_num < min_cell_count) return("")
  paste0(round(100 * n_num / denom_num, 1), "%")
}

mcl_count_add_provenance <- function(df, count_mode, generated_at, source_tables = "", person_key_used = "", date_anchor_used = "", value_rule_used = "", validation_status = "") {
  if (!is.data.frame(df)) return(df)
  n <- nrow(df)
  add <- function(name, value) {
    value <- as.character(value %||% "")
    if (!name %in% names(df)) df[[name]] <<- rep(value[[1]], n)
  }
  add("count_mode", count_mode)
  add("source_tables", source_tables)
  add("person_key_used", person_key_used)
  add("date_anchor_used", date_anchor_used)
  add("value_rule_used", value_rule_used)
  add("generated_at", generated_at)
  add("validation_status", validation_status)
  df
}

mcl_count_sanitize_error_message <- function(message) {
  msg <- as.character(message %||% "")
  if (!nzchar(msg)) return("")
  msg <- gsub("(?i)(password|pwd|token|secret|key)\\s*=\\s*[^;\\s]+", "\\1=<redacted>", msg, perl = TRUE)
  msg <- gsub("(?i)(host|server|dbname|database|user|uid)\\s*=\\s*[^;\\s]+", "\\1=<redacted>", msg, perl = TRUE)
  msg <- gsub("[0-9]{10}", "<redacted_id>", msg, perl = TRUE)
  msg <- gsub("\\s+", " ", msg, perl = TRUE)
  substr(trimws(msg), 1L, 500L)
}

mcl_count_error_class <- function(error) {
  if (is.null(error)) return("")
  cls <- class(error)
  cls <- cls[nzchar(cls)]
  if (length(cls)) cls[[1]] else "query_error"
}

mcl_count_unavailable_data_points <- function(defs, status = "count_not_available_requires_production_validation", outputs_dir = NULL,
                                              project_root = ".", count_mode = "plan", generated_at = mcl_count_now(),
                                              error_class = "", error_message_sanitized = "",
                                              patient_demographics_resolver = NULL,
                                              age_source_locator = NULL,
                                              ibrutinib_source_validation = NULL,
                                              treatment_code_mappings = NULL) {
  plan <- mcl_count_build_query_plan(defs, project_root = project_root, outputs_dir = outputs_dir, patient_demographics_resolver = patient_demographics_resolver, age_source_locator = age_source_locator, ibrutinib_source_validation = ibrutinib_source_validation, treatment_code_mappings = treatment_code_mappings)
  review <- plan$review
  rows <- lapply(seq_len(nrow(defs)), function(i) {
    id <- defs$data_point_id[[i]]
    qr <- review[review$data_point == id, , drop = FALSE]
    executable <- nrow(qr) && isTRUE(qr$query_executable[[1]])
    row_status <- if (executable) status else "count_not_available_requires_value_mapping"
    if (nrow(qr) && grepl("patient demographics mapping", qr$reviewer_notes[[1]], ignore.case = TRUE)) {
      row_status <- mcl_count_patient_demographics_status()
    }
    if (nrow(qr) && grepl("person key", qr$reviewer_notes[[1]], ignore.case = TRUE)) row_status <- "count_not_available_requires_person_key_mapping"
    if (nrow(qr) && grepl("date anchor|date mapping|diagnosis date|treatment date|event date|no (validated )?(diagnosis|treatment|event|first[- ]line).*date", qr$reviewer_notes[[1]], ignore.case = TRUE, perl = TRUE)) {
      row_status <- "count_not_available_requires_date_mapping"
    }
    if (nrow(qr) && grepl("not applicable", qr$reviewer_notes[[1]], ignore.case = TRUE, fixed = FALSE)) {
      row_status <- "not_applicable"
    }
    query_attempted <- identical(count_mode, "production_aggregate") &&
      row_status %in% c("production_aggregate_failed_query_error", "production_aggregate_failed_credentials_unavailable")
    attempted_note <- if (identical(row_status, "production_aggregate_failed_query_error")) {
      "Production aggregate query was attempted but failed; no person-level rows were emitted."
    } else if (identical(row_status, "production_aggregate_failed_credentials_unavailable")) {
      "Production aggregate mode was requested, but no read-only database connection was available."
    } else if (executable) {
      "Plan/query-template output only; production aggregate query was not executed."
    } else {
      qr$reviewer_notes[[1]] %||% "Mapping required."
    }
    data.frame(
      data_point_id = id,
      clinical_label = defs$clinical_label[[i]],
      denominator = defs$denominator[[i]],
      timing_scope = mcl_count_timing_scope(defs$valid_time_window[[i]]),
      count_status = row_status,
      distinct_person_count_display = "",
      percent_of_denominator_display = "",
      denominator_count_display = "",
      count_source = if (executable) "executable_sql_not_run" else "not_executable_mapping_gap",
      person_key_confidence = if (nrow(qr) && nzchar(qr$person_key_used[[1]])) "validated_mapping_config" else "requires_mapping",
      timing_validation_status = if (nrow(qr) && nzchar(qr$date_anchor_used[[1]])) "date_anchor_mapped_requires_validation" else "requires_date_mapping",
      source_locations = qr$tables_used[[1]] %||% defs$source_priority[[i]],
      notes = attempted_note,
      query_attempted = query_attempted,
      query_executed = FALSE,
      query_success = FALSE,
      error_class = if (nzchar(error_class)) error_class else if (grepl("^production_aggregate_failed", row_status)) row_status else "",
      error_message_sanitized = error_message_sanitized %||% "",
      count_mode = count_mode,
      source_tables = qr$tables_used[[1]] %||% "",
      person_key_used = qr$person_key_used[[1]] %||% "",
      date_anchor_used = qr$date_anchor_used[[1]] %||% "",
      value_rule_used = qr$value_rule_used[[1]] %||% "",
      generated_at = generated_at,
      validation_status = if (executable) "query_executable_not_run" else "mapping_gap",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

mcl_count_db_get_query <- function(db_adapter, sql) {
  if (is.null(db_adapter)) return(NULL)
  if (is.function(db_adapter$mcl_triangle_query)) {
    return(tryCatch(db_adapter$mcl_triangle_query(sql), error = function(e) NULL))
  }
  if (!requireNamespace("DBI", quietly = TRUE)) return(NULL)
  conns <- db_adapter$connections %||% list()
  for (conn in conns) {
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) NULL)
    if (is.data.frame(out)) return(out)
  }
  NULL
}

mcl_count_db_query_result <- function(db_adapter, sql) {
  if (is.null(db_adapter)) {
    return(list(data = NULL, error_class = "production_aggregate_failed_credentials_unavailable", error_message_sanitized = "No DBI-compatible DALY-CARE adapter was available."))
  }
  if (is.function(db_adapter$mcl_triangle_query)) {
    return(tryCatch(
      list(data = db_adapter$mcl_triangle_query(sql), error_class = "", error_message_sanitized = ""),
      error = function(e) list(data = NULL, error_class = mcl_count_error_class(e), error_message_sanitized = mcl_count_sanitize_error_message(conditionMessage(e)))
    ))
  }
  if (!requireNamespace("DBI", quietly = TRUE)) {
    return(list(data = NULL, error_class = "production_aggregate_failed_credentials_unavailable", error_message_sanitized = "DBI is not available in this R session."))
  }
  conns <- db_adapter$connections %||% list()
  if (!length(conns)) {
    return(list(data = NULL, error_class = "production_aggregate_failed_credentials_unavailable", error_message_sanitized = "No read-only DALY-CARE DB connection was available."))
  }
  last_error <- NULL
  for (conn in conns) {
    out <- tryCatch(
      DBI::dbGetQuery(conn, sql),
      error = function(e) {
        last_error <<- e
        NULL
      }
    )
    if (is.data.frame(out)) {
      return(list(data = out, error_class = "", error_message_sanitized = ""))
    }
  }
  list(
    data = NULL,
    error_class = mcl_count_error_class(last_error),
    error_message_sanitized = mcl_count_sanitize_error_message(if (is.null(last_error)) "Query returned no aggregate result." else conditionMessage(last_error))
  )
}

mcl_count_db_query_all_connections <- function(db_adapter, sql) {
  if (is.null(db_adapter)) return(data.frame(stringsAsFactors = FALSE))
  if (is.function(db_adapter$mcl_triangle_query_all_connections)) {
    out <- tryCatch(db_adapter$mcl_triangle_query_all_connections(sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out)) return(data.frame(stringsAsFactors = FALSE))
    if (!"db_name" %in% names(out)) out$db_name <- rep("", nrow(out))
    return(out)
  }
  if (is.function(db_adapter$mcl_triangle_query)) {
    out <- tryCatch(db_adapter$mcl_triangle_query(sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out)) return(data.frame(stringsAsFactors = FALSE))
    if (!"db_name" %in% names(out)) out$db_name <- rep("", nrow(out))
    return(out)
  }
  if (!requireNamespace("DBI", quietly = TRUE)) return(data.frame(stringsAsFactors = FALSE))
  conns <- db_adapter$connections %||% list()
  if (!length(conns)) return(data.frame(stringsAsFactors = FALSE))
  rows <- lapply(names(conns), function(db_name) {
    out <- tryCatch(DBI::dbGetQuery(conns[[db_name]], sql), error = function(e) NULL)
    if (!is.data.frame(out)) return(NULL)
    out$db_name <- db_name
    out
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (!length(rows)) return(data.frame(stringsAsFactors = FALSE))
  bind_rows_base(rows)
}

mcl_count_db_adapter_available <- function(db_adapter) {
  if (is.null(db_adapter)) return(FALSE)
  if (is.function(db_adapter$mcl_triangle_count_sets)) return(TRUE)
  if (is.function(db_adapter$mcl_triangle_query)) return(TRUE)
  if (is.function(db_adapter$mcl_triangle_query_all_connections)) return(TRUE)
  conns <- db_adapter$connections %||% list()
  length(conns) > 0L
}

mcl_count_mode <- function(db_adapter = NULL, mode = Sys.getenv("DALYCARE_MCL_TRIANGLE_COUNT_MODE", unset = "auto")) {
  mode <- match.arg(mode, c("auto", "plan", "production_aggregate"))
  if (!identical(mode, "auto")) return(mode)
  if (mcl_count_db_adapter_available(db_adapter)) "production_aggregate" else "plan"
}

mcl_count_split_config <- function(x) {
  x <- as.character(x %||% "")
  out <- unlist(strsplit(x, ";", fixed = TRUE), use.names = FALSE)
  out <- trimws(out)
  out[nzchar(out)]
}

mcl_count_sql_string <- function(x) {
  paste0("'", gsub("'", "''", as.character(x %||% ""), fixed = TRUE), "'")
}

mcl_count_code_predicate_sql <- function(alias, code_columns, code_values) {
  code_columns <- mcl_count_split_config(code_columns)
  code_values <- toupper(mcl_count_split_config(code_values))
  if (!length(code_columns) || !length(code_values)) return("false")
  values_sql <- paste(vapply(code_values, mcl_count_sql_string, character(1)), collapse = ", ")
  paste(
    vapply(code_columns, function(col) {
      paste0("upper(trim(", alias, ".", mcl_count_sql_ident(col), "::text)) in (", values_sql, ")")
    }, character(1)),
    collapse = " or "
  )
}

mcl_count_date_coalesce_sql <- function(alias, date_columns) {
  date_columns <- mcl_count_split_config(date_columns)
  if (!length(date_columns)) return("null::date")
  exprs <- vapply(date_columns, function(col) mcl_count_date_sql(paste0(alias, ".", mcl_count_sql_ident(col))), character(1))
  if (length(exprs) == 1L) exprs[[1]] else paste0("coalesce(", paste(exprs, collapse = ", "), ")")
}

mcl_count_ibrutinib_source_person_sql <- function(mapping, person_expr = NULL, alias = "x") {
  role <- as.character(mapping$source_role[[1]] %||% "")
  if (identical(role, "primary_bridged_sks_source")) {
    return("")
  }
  ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]])
  person_col <- mapping$person_key_column[[1]] %||% "patientid"
  person_expr <- person_expr %||% paste0(alias, ".", mcl_count_sql_ident(person_col))
  pred <- mcl_count_code_predicate_sql(alias, mapping$code_column[[1]], mapping$code_value[[1]])
  paste0(
    "  select distinct ", person_expr, " as person_key\n",
    "  from ", ref, " ", alias, "\n",
    "  where ", pred
  )
}

mcl_count_ibrutinib_source_validation_sql <- function(mapping, lyfo_mapping) {
  lyfo_ref <- mcl_count_sql_table(lyfo_mapping$schema[[1]], lyfo_mapping$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo_mapping$person_key_column[[1]])
  role <- as.character(mapping$source_role[[1]] %||% "")
  if (identical(role, "primary_bridged_sks_source")) {
    source_ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]])
    bridge_ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$bridge_table[[1]])
    source_key <- mcl_count_sql_ident(mapping$bridge_source_key_column[[1]] %||% "v_recnum")
    bridge_key <- mcl_count_sql_ident(mapping$bridge_key_column[[1]] %||% "k_recnum")
    bridge_person <- mcl_count_sql_ident(mapping$bridge_person_key_column[[1]] %||% "patientid")
    pred <- mcl_count_code_predicate_sql("s", mapping$code_column[[1]], mapping$code_value[[1]])
    date_expr <- mcl_count_date_coalesce_sql("s", mapping$date_columns[[1]])
    return(paste0(
      "with mcl as (\n",
      "  select distinct r.", lyfo_key, " as person_key\n",
      "  from ", lyfo_ref, " r\n",
      "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
      "), source_rows as (\n",
      "  select s.", source_key, " as bridge_key, ", date_expr, " as exposure_date\n",
      "  from ", source_ref, " s\n",
      "  where ", pred, "\n",
      "), bridged as (\n",
      "  select distinct b.", bridge_person, " as person_key, min(source_rows.exposure_date) as exposure_date\n",
      "  from source_rows\n",
      "  join ", bridge_ref, " b on b.", bridge_key, "::text = source_rows.bridge_key::text\n",
      "  group by b.", bridge_person, "\n",
      "), joined as (\n",
      "  select bridged.person_key, bridged.exposure_date, mcl.person_key as mcl_person_key\n",
      "  from bridged\n",
      "  left join mcl on mcl.person_key::text = bridged.person_key::text\n",
      ")\n",
      "select count(*) as source_code_rows,\n",
      "       (select count(*) from bridged) as source_distinct_people,\n",
      "       count(distinct case when mcl_person_key is not null then person_key end) as mcl_exposed_people,\n",
      "       count(distinct case when mcl_person_key is not null and exposure_date is not null then person_key end) as date_available_people\n",
      "from joined;"
    ))
  }
  source_ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]])
  person_col <- mcl_count_sql_ident(mapping$person_key_column[[1]] %||% "patientid")
  pred <- mcl_count_code_predicate_sql("x", mapping$code_column[[1]], mapping$code_value[[1]])
  date_expr <- mcl_count_date_coalesce_sql("x", mapping$date_columns[[1]])
  paste0(
    "with mcl as (\n",
    "  select distinct r.", lyfo_key, " as person_key\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), source_rows as (\n",
    "  select x.", person_col, " as person_key, ", date_expr, " as exposure_date\n",
    "  from ", source_ref, " x\n",
    "  where ", pred, "\n",
    "), joined as (\n",
    "  select source_rows.person_key, source_rows.exposure_date, mcl.person_key as mcl_person_key\n",
    "  from source_rows\n",
    "  left join mcl on mcl.person_key::text = source_rows.person_key::text\n",
    ")\n",
    "select count(*) as source_code_rows,\n",
    "       count(distinct person_key) as source_distinct_people,\n",
    "       count(distinct case when mcl_person_key is not null then person_key end) as mcl_exposed_people,\n",
    "       count(distinct case when mcl_person_key is not null and exposure_date is not null then person_key end) as date_available_people\n",
    "from joined;"
  )
}

mcl_count_ibrutinib_source_probe <- function(db_adapter, mapping, lyfo_mapping) {
  columns <- unique(c(
    mcl_count_split_config(mapping$person_key_column[[1]]),
    mcl_count_split_config(mapping$code_column[[1]]),
    mcl_count_split_config(mapping$date_columns[[1]]),
    mcl_count_split_config(mapping$bridge_source_key_column[[1]])
  ))
  columns <- columns[nzchar(columns)]
  relation_sql <- paste0("select count(*) as probe_count\nfrom ", mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]]), "\nwhere false;")
  column_sql <- if (length(columns)) {
    paste0(
      "select ", paste(vapply(columns, mcl_count_sql_ident, character(1)), collapse = ", "),
      "\nfrom ", mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]]), "\nwhere false;"
    )
  } else {
    relation_sql
  }
  relation <- mcl_count_db_query_result(db_adapter, relation_sql)
  relation_success <- is.data.frame(relation$data) && nrow(relation$data) == 1L && "probe_count" %in% names(relation$data)
  column <- if (relation_success) mcl_count_db_query_result(db_adapter, column_sql) else list(data = NULL, error_message_sanitized = "")
  column_success <- is.data.frame(column$data) && (!length(columns) || all(tolower(columns) %in% tolower(names(column$data))))
  relation_error <- relation$error_message_sanitized %||% ""
  if (!relation_success && !nzchar(relation_error) && is.data.frame(relation$data)) relation_error <- "Relation probe returned an unexpected aggregate shape."
  column_error <- column$error_message_sanitized %||% ""
  if (relation_success && !column_success && !nzchar(column_error) && is.data.frame(column$data)) column_error <- "Column probe returned an unexpected zero-row shape."
  role <- as.character(mapping$source_role[[1]] %||% "")
  bridge_attempted <- FALSE
  bridge_success <- FALSE
  bridge_error <- ""
  co_attempted <- FALSE
  co_success <- FALSE
  co_error <- ""
  source_db <- as.character(mapping$db_name[[1]] %||% "")
  lyfo_db <- as.character(lyfo_mapping$db_name[[1]] %||% "")
  same_db <- !nzchar(source_db) || !nzchar(lyfo_db) || identical(tolower(source_db), tolower(lyfo_db))
  if (relation_success && column_success && !same_db) {
    co_error <- paste0("Cross-database join unavailable: source db_name=", source_db, " and RKKP_LYFO db_name=", lyfo_db, ".")
  } else if (relation_success && column_success && identical(role, "primary_bridged_sks_source")) {
    bridge_attempted <- TRUE
    bridge_cols <- unique(c(
      mcl_count_split_config(mapping$bridge_key_column[[1]]),
      mcl_count_split_config(mapping$bridge_person_key_column[[1]])
    ))
    bridge_sql <- paste0(
      "select ", paste(vapply(bridge_cols, mcl_count_sql_ident, character(1)), collapse = ", "),
      "\nfrom ", mcl_count_sql_table(mapping$schema[[1]], mapping$bridge_table[[1]]), "\nwhere false;"
    )
    bridge <- mcl_count_db_query_result(db_adapter, bridge_sql)
    bridge_success <- is.data.frame(bridge$data) && all(tolower(bridge_cols) %in% tolower(names(bridge$data)))
    bridge_error <- bridge$error_message_sanitized %||% ""
    if (!bridge_success && !nzchar(bridge_error) && is.data.frame(bridge$data)) bridge_error <- "Bridge probe returned an unexpected zero-row shape."
    if (bridge_success) {
      co_sql <- paste0(
        "select count(*) as probe_count\n",
        "from ", mcl_count_sql_table(lyfo_mapping$schema[[1]], lyfo_mapping$table[[1]]), " r\n",
        "join ", mcl_count_sql_table(mapping$schema[[1]], mapping$bridge_table[[1]]), " b on b.", mcl_count_sql_ident(mapping$bridge_person_key_column[[1]]), "::text = r.", mcl_count_sql_ident(lyfo_mapping$person_key_column[[1]]), "::text\n",
        "join ", mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]]), " s on s.", mcl_count_sql_ident(mapping$bridge_source_key_column[[1]]), "::text = b.", mcl_count_sql_ident(mapping$bridge_key_column[[1]]), "::text\n",
        "where false;"
      )
      co <- mcl_count_db_query_result(db_adapter, co_sql)
      co_attempted <- TRUE
      co_success <- is.data.frame(co$data) && nrow(co$data) == 1L && "probe_count" %in% names(co$data)
      co_error <- co$error_message_sanitized %||% ""
      if (!co_success && !nzchar(co_error) && is.data.frame(co$data)) co_error <- "Bridge co-residency probe returned an unexpected aggregate shape."
    }
  } else if (relation_success && column_success && nzchar(mapping$person_key_column[[1]] %||% "")) {
    co <- mcl_count_co_residency_probe(
      db_adapter,
      lyfo_mapping,
      mapping$schema[[1]],
      mapping$table[[1]],
      mapping$person_key_column[[1]],
      source_db_name = source_db,
      lyfo_db_name = lyfo_db
    )
    co_attempted <- isTRUE(co$co_residency_probe_attempted)
    co_success <- isTRUE(co$co_residency_probe_success)
    co_error <- co$co_residency_probe_error_sanitized %||% ""
  }
  list(
    relation_probe_attempted = TRUE,
    relation_probe_success = relation_success,
    relation_probe_error_sanitized = relation_error,
    column_probe_attempted = relation_success,
    column_probe_success = column_success,
    column_probe_error_sanitized = if (relation_success) column_error else "",
    bridge_probe_attempted = bridge_attempted,
    bridge_probe_success = bridge_success,
    bridge_probe_error_sanitized = bridge_error,
    co_residency_probe_attempted = co_attempted,
    co_residency_probe_success = co_success,
    co_residency_probe_error_sanitized = co_error
  )
}

mcl_count_ibrutinib_validation_row <- function(mapping, probe = list(), query_attempted = FALSE,
                                               query_success = FALSE, metrics = list(),
                                               validation_status = "source_validation_failed",
                                               selected_for_union = FALSE,
                                               error_message_sanitized = "", notes = "") {
  metric <- function(name) {
    value <- suppressWarnings(as.integer(as.numeric(metrics[[name]] %||% NA_integer_)))
    if (is.na(value)) NA_integer_ else value
  }
  data.frame(
    source_id = mapping$source_id[[1]] %||% "",
    canonical_source_id = mapping$canonical_source_id[[1]] %||% mapping$table[[1]] %||% "",
    source_role = mapping$source_role[[1]] %||% "",
    include_in_primary_union = mcl_count_bool(mapping$include_in_primary_union[[1]]),
    db_name = mapping$db_name[[1]] %||% "",
    schema = mapping$schema[[1]] %||% "",
    table = mapping$table[[1]] %||% "",
    person_key_column = mapping$person_key_column[[1]] %||% "",
    code_column = mapping$code_column[[1]] %||% "",
    code_system = mapping$code_system[[1]] %||% "",
    code_value = mapping$code_value[[1]] %||% "",
    date_columns = mapping$date_columns[[1]] %||% "",
    bridge_table = mapping$bridge_table[[1]] %||% "",
    bridge_source_key_column = mapping$bridge_source_key_column[[1]] %||% "",
    bridge_key_column = mapping$bridge_key_column[[1]] %||% "",
    bridge_person_key_column = mapping$bridge_person_key_column[[1]] %||% "",
    relation_probe_attempted = isTRUE(probe$relation_probe_attempted),
    relation_probe_success = isTRUE(probe$relation_probe_success),
    relation_probe_error_sanitized = probe$relation_probe_error_sanitized %||% "",
    column_probe_attempted = isTRUE(probe$column_probe_attempted),
    column_probe_success = isTRUE(probe$column_probe_success),
    column_probe_error_sanitized = probe$column_probe_error_sanitized %||% "",
    bridge_probe_attempted = isTRUE(probe$bridge_probe_attempted),
    bridge_probe_success = isTRUE(probe$bridge_probe_success),
    bridge_probe_error_sanitized = probe$bridge_probe_error_sanitized %||% "",
    co_residency_probe_attempted = isTRUE(probe$co_residency_probe_attempted),
    co_residency_probe_success = isTRUE(probe$co_residency_probe_success),
    co_residency_probe_error_sanitized = probe$co_residency_probe_error_sanitized %||% "",
    validation_query_attempted = isTRUE(query_attempted),
    validation_query_success = isTRUE(query_success),
    source_code_rows = metric("source_code_rows"),
    source_distinct_people = metric("source_distinct_people"),
    mcl_exposed_people = metric("mcl_exposed_people"),
    date_available_people = metric("date_available_people"),
    selected_for_union = isTRUE(selected_for_union),
    validation_status = validation_status,
    error_message_sanitized = error_message_sanitized %||% "",
    notes = notes,
    stringsAsFactors = FALSE
  )
}

mcl_count_validate_ibrutinib_sources <- function(treatment_mappings, atlas_inventory, person_date_mapping, db_adapter) {
  mappings <- mcl_count_match_empty(treatment_mappings, mcl_count_read_treatment_code_mappings(tempdir()))
  lyfo <- mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  if (!nrow(mappings) || !mcl_count_mapping_usable(lyfo) || !mcl_count_db_adapter_available(db_adapter)) {
    return(mcl_count_empty_ibrutinib_source_validation())
  }
  rows <- list()
  for (i in seq_len(nrow(mappings))) {
    mapping <- mappings[i, , drop = FALSE]
    role <- mapping$source_role[[1]] %||% ""
    probe <- mcl_count_ibrutinib_source_probe(db_adapter, mapping, lyfo)
    bridge_required <- identical(role, "primary_bridged_sks_source")
    probe_ok <- isTRUE(probe$relation_probe_success) &&
      isTRUE(probe$column_probe_success) &&
      isTRUE(probe$co_residency_probe_success) &&
      (!bridge_required || isTRUE(probe$bridge_probe_success))
    query_attempted <- FALSE
    query_success <- FALSE
    metrics <- list()
    err <- ""
    if (probe_ok) {
      sql <- mcl_count_ibrutinib_source_validation_sql(mapping, lyfo)
      result <- mcl_count_db_query_result(db_adapter, sql)
      query_attempted <- TRUE
      data <- result$data
      needed <- c("source_code_rows", "source_distinct_people", "mcl_exposed_people", "date_available_people")
      query_success <- is.data.frame(data) && nrow(data) == 1L && all(needed %in% names(data))
      if (query_success) metrics <- as.list(data[1, needed, drop = FALSE])
      err <- result$error_message_sanitized %||% ""
      if (!query_success && !nzchar(err) && is.data.frame(data)) err <- "Ibrutinib source validation returned an unexpected aggregate shape."
    }
    mcl_people <- suppressWarnings(as.integer(as.numeric(metrics$mcl_exposed_people %||% NA_integer_)))
    include <- mcl_count_bool(mapping$include_in_primary_union[[1]])
    source_valid <- query_success && !is.na(mcl_people) && mcl_people > 0L
    selected <- source_valid && include
    status <- if (!isTRUE(probe$relation_probe_success)) {
      "relation_probe_failed"
    } else if (!isTRUE(probe$column_probe_success)) {
      "column_probe_failed"
    } else if (bridge_required && !isTRUE(probe$bridge_probe_success)) {
      "bridge_probe_failed"
    } else if (!isTRUE(probe$co_residency_probe_success)) {
      "co_residency_probe_failed"
    } else if (!query_success) {
      "source_validation_failed"
    } else if (!source_valid) {
      "source_validated_zero_mcl_exposed"
    } else if (!include) {
      "auxiliary_source_validated_not_primary_union"
    } else if (identical(role, "primary_bridged_sks_source")) {
      "bridged_sks_source_validated"
    } else if (grepl("atc", role, ignore.case = TRUE)) {
      "atc_source_validated"
    } else {
      "lyfo_regimen_source_validated"
    }
    rows[[length(rows) + 1L]] <- mcl_count_ibrutinib_validation_row(
      mapping,
      probe = probe,
      query_attempted = query_attempted,
      query_success = query_success,
      metrics = metrics,
      validation_status = status,
      selected_for_union = selected,
      error_message_sanitized = err,
      notes = if (selected) {
        "Validated aggregate Ibrutinib source contributes to the deduplicated primary MCL union."
      } else if (!include && source_valid) {
        "Validated auxiliary source; retained for audit and source overlap context, not primary MCL union."
      } else if (identical(role, "primary_bridged_sks_source") && !isTRUE(probe$bridge_probe_success)) {
        "SKS BWHA169 is atlas-confirmed Ibrutinib evidence, but person counting requires a validated SDS_t_adm bridge."
      } else {
        "Source failed closed for primary union counting."
      }
    )
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_source_validation())
}

mcl_count_ibrutinib_selected_validation <- function(ibrutinib_source_validation) {
  validation <- mcl_count_match_empty(ibrutinib_source_validation, mcl_count_empty_ibrutinib_source_validation())
  if (!nrow(validation)) return(validation)
  validation[validation$selected_for_union %in% TRUE & validation$validation_query_success %in% TRUE, , drop = FALSE]
}

mcl_count_ibrutinib_source_map <- function(treatment_mappings) {
  mappings <- mcl_count_match_empty(treatment_mappings, mcl_count_read_treatment_code_mappings(tempdir()))
  split(mappings, mappings$source_id)
}

mcl_count_ibrutinib_source_cte_sql <- function(mapping) {
  role <- mapping$source_role[[1]] %||% ""
  if (identical(role, "primary_bridged_sks_source")) {
    source_ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$table[[1]])
    bridge_ref <- mcl_count_sql_table(mapping$schema[[1]], mapping$bridge_table[[1]])
    pred <- mcl_count_code_predicate_sql("s", mapping$code_column[[1]], mapping$code_value[[1]])
    paste0(
      "select distinct b.", mcl_count_sql_ident(mapping$bridge_person_key_column[[1]] %||% "patientid"), " as person_key\n",
      "  from ", source_ref, " s\n",
      "  join ", bridge_ref, " b on b.", mcl_count_sql_ident(mapping$bridge_key_column[[1]] %||% "k_recnum"), "::text = s.", mcl_count_sql_ident(mapping$bridge_source_key_column[[1]] %||% "v_recnum"), "::text\n",
      "  where ", pred
    )
  } else {
    mcl_count_ibrutinib_source_person_sql(mapping)
  }
}

mcl_count_ibrutinib_union_data_sql <- function(selected_validation, treatment_mappings) {
  selected <- mcl_count_ibrutinib_selected_validation(selected_validation)
  if (!nrow(selected)) return("")
  source_map <- mcl_count_ibrutinib_source_map(treatment_mappings)
  pieces <- list()
  for (source_id in selected$source_id) {
    mapping <- source_map[[source_id]]
    if (!is.data.frame(mapping) || !nrow(mapping)) next
    pieces[[length(pieces) + 1L]] <- mcl_count_ibrutinib_source_cte_sql(mapping[1, , drop = FALSE])
  }
  if (!length(pieces)) return("")
  paste0(
    "  select distinct ib.person_key\n",
    "  from (\n",
    paste(vapply(pieces, function(piece) paste0("    ", gsub("\n", "\n    ", piece, fixed = TRUE)), character(1)), collapse = "\n    union\n"),
    "\n  ) ib"
  )
}

mcl_count_ibrutinib_validation_summary_status <- function(validation) {
  selected <- mcl_count_ibrutinib_selected_validation(validation)
  if (!nrow(selected)) return("requires_ibrutinib_source_validation")
  external <- selected[!grepl("^RKKP_LYFO_", selected$source_id), , drop = FALSE]
  if (!nrow(external)) return("lyfo_regimen_only_validated")
  failed <- validation[validation$include_in_primary_union %in% TRUE & !(validation$selected_for_union %in% TRUE), , drop = FALSE]
  if (nrow(failed)) "expanded_atc_sks_validated_with_source_failures" else "expanded_atc_sks_validated"
}

mcl_count_ibrutinib_source_counts_from_validation <- function(validation, min_cell_count = 5L) {
  validation <- mcl_count_match_empty(validation, mcl_count_empty_ibrutinib_source_validation())
  if (!nrow(validation)) return(mcl_count_empty_ibrutinib_source_counts())
  rows <- lapply(seq_len(nrow(validation)), function(i) {
    row <- validation[i, , drop = FALSE]
    source_rows <- mcl_count_suppress(row$source_code_rows[[1]], min_cell_count)
    source_people <- mcl_count_suppress(row$source_distinct_people[[1]], min_cell_count)
    mcl_people <- mcl_count_suppress(row$mcl_exposed_people[[1]], min_cell_count)
    date_people <- mcl_count_suppress(row$date_available_people[[1]], min_cell_count)
    data.frame(
      source_id = row$source_id[[1]],
      source_role = row$source_role[[1]],
      code_system = row$code_system[[1]],
      code_value = row$code_value[[1]],
      count_status = if (row$validation_query_success[[1]] %in% TRUE) mcl_count_production_status(mcl_people$status) else "production_aggregate_failed_query_error",
      source_code_rows_display = source_rows$display,
      source_distinct_people_display = source_people$display,
      mcl_exposed_people_display = mcl_people$display,
      date_available_people_display = date_people$display,
      selected_for_union = row$selected_for_union[[1]] %in% TRUE,
      validation_status = row$validation_status[[1]],
      notes = row$notes[[1]],
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_source_counts())
}

mcl_count_ibrutinib_union_counts_from_data_points <- function(data_points, validation) {
  ib <- mcl_count_data_row(data_points, "ibrutinib_exposure")
  all_mcl <- mcl_count_data_row(data_points, "all_lyfo_mcl")
  selected <- mcl_count_ibrutinib_selected_validation(validation)
  selected_sources <- paste(selected$source_id, collapse = "; ")
  auxiliary <- validation[!(validation$include_in_primary_union %in% TRUE), , drop = FALSE]
  rows <- list()
  for (denom in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    same_denom <- mcl_count_is_available_row(ib) && identical(ib$denominator[[1]], denom)
    rows[[length(rows) + 1L]] <- data.frame(
      denominator = denom,
      timing_window = "ever_observed",
      distinct_person_count_display = if (same_denom) ib$distinct_person_count_display[[1]] else "",
      percent_of_denominator_display = if (same_denom) ib$percent_of_denominator_display[[1]] else "",
      validated_primary_sources = selected_sources,
      auxiliary_sources = paste(auxiliary$source_id, collapse = "; "),
      validation_status = if (same_denom) mcl_count_ibrutinib_validation_summary_status(validation) else "requires_age_specific_union_query_or_denominator",
      count_status = if (same_denom) ib$count_status[[1]] else if (identical(denom, "younger_mcl_proxy_age_le_65")) mcl_count_patient_demographics_status() else "count_not_available_requires_value_mapping",
      notes = if (same_denom) {
        "Deduplicated aggregate ever-observed Ibrutinib exposure across validated primary sources; timing-specific interpretation remains unavailable until date-window validation."
      } else {
        "No validated executable denominator-specific Ibrutinib union count is available."
      },
      stringsAsFactors = FALSE
    )
  }
  if (mcl_count_is_available_row(all_mcl) && !mcl_count_is_available_row(ib)) rows[[1]]$percent_of_denominator_display <- ""
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_union_counts())
}

mcl_count_execute_ibrutinib_source_overlap_sql <- function(validation, treatment_mappings, data_points, db_adapter, min_cell_count = 5L) {
  selected <- mcl_count_ibrutinib_selected_validation(validation)
  if (nrow(selected) < 2L) return(mcl_count_empty_ibrutinib_overlap_by_source())
  source_map <- mcl_count_ibrutinib_source_map(treatment_mappings)
  denom_n <- mcl_count_denominator_display_n(data_points, "all_lyfo_mcl")
  rows <- list()
  for (i in seq_len(nrow(selected) - 1L)) {
    for (j in seq.int(i + 1L, nrow(selected))) {
      a <- selected$source_id[[i]]
      b <- selected$source_id[[j]]
      ma <- source_map[[a]]
      mb <- source_map[[b]]
      if (!is.data.frame(ma) || !nrow(ma) || !is.data.frame(mb) || !nrow(mb)) next
      cte_a <- paste0("source_a as (\n  ", gsub("\n", "\n  ", mcl_count_ibrutinib_source_cte_sql(ma[1, , drop = FALSE]), fixed = TRUE), "\n)")
      cte_b <- paste0("source_b as (\n  ", gsub("\n", "\n  ", mcl_count_ibrutinib_source_cte_sql(mb[1, , drop = FALSE]), fixed = TRUE), "\n)")
      sql <- paste0(
        "with ", cte_a, ",\n", cte_b, "\n",
        "select '", gsub("'", "''", paste(a, b, sep = "__"), fixed = TRUE), "' as intersection_id,\n",
        "       count(*) as distinct_person_count\n",
        "from source_a\n",
        "join source_b using (person_key);"
      )
      result <- if (mcl_count_sql_safe(sql)) mcl_count_execute_intersection_count(db_adapter, sql, min_cell_count, denom_n) else list(count_status = "count_not_available_requires_dedicated_intersection_query", distinct_person_count_display = "", percent_of_denominator_display = "", query_success = FALSE)
      rows[[length(rows) + 1L]] <- data.frame(
        source_id_a = a,
        source_id_b = b,
        denominator = "all_lyfo_mcl",
        timing_window = "ever_observed",
        count_status = result$count_status,
        distinct_person_count_display = result$distinct_person_count_display,
        percent_of_denominator_display = result$percent_of_denominator_display,
        validation_status = if (isTRUE(result$query_success)) "production_aggregate_source_overlap_sql" else "production_aggregate_failed_query_error",
        notes = "Deduplication diagnostic only; no person keys emitted.",
        stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) return(mcl_count_empty_ibrutinib_overlap_by_source())
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_overlap_by_source())
}

mcl_count_sql_safe <- function(sql) {
  !grepl("select\\s+[*]|\\blimit\\s+[0-9]+|<person_key>|<validated_mcl_predicate>|<validated_rule_for_", sql, ignore.case = TRUE, perl = TRUE)
}

mcl_count_execute_data_point_counts <- function(defs, project_root, outputs_dir, db_adapter, min_cell_count = 5L, generated_at = mcl_count_now(),
                                                no_result_status = "production_aggregate_failed_query_error",
                                                patient_demographics_resolver = NULL,
                                                age_source_locator = NULL,
                                                ibrutinib_source_validation = NULL,
                                                treatment_code_mappings = NULL) {
  plan <- mcl_count_build_query_plan(defs, project_root = project_root, outputs_dir = outputs_dir, patient_demographics_resolver = patient_demographics_resolver, age_source_locator = age_source_locator, ibrutinib_source_validation = ibrutinib_source_validation, treatment_code_mappings = treatment_code_mappings)
  denom_counts <- list()
  rows <- list()
  for (i in seq_len(nrow(defs))) {
    id <- defs$data_point_id[[i]]
    qr <- plan$review[plan$review$data_point == id, , drop = FALSE]
    section <- strsplit(plan$sql, "-- query_id: ", fixed = TRUE)[[1]]
    section <- section[grepl(paste0("^mcl_triangle_", id, "\\b"), section)]
    sql <- if (length(section)) sub("^mcl_triangle_[^\n]+\n", "", section[[1]]) else ""
    executable <- nrow(qr) && isTRUE(qr$query_executable[[1]]) && mcl_count_sql_safe(sql)
    n <- NA_real_
    query_result <- list(data = NULL, error_class = "", error_message_sanitized = "")
    if (executable) {
      query_result <- mcl_count_db_query_result(db_adapter, sql)
      result <- query_result$data
      if (is.data.frame(result) && nrow(result) && "distinct_person_count" %in% names(result)) {
        n <- suppressWarnings(as.numeric(result$distinct_person_count[[1]]))
      }
    }
    if (!is.na(n)) {
      count <- mcl_count_suppress(n, min_cell_count)
      denom_id <- defs$denominator[[i]]
      if (id %in% mcl_count_denominator_ids()) denom_counts[[id]] <- n
      denom_n <- denom_counts[[denom_id]] %||% NA_real_
      count_status <- mcl_count_production_status(count$status)
      notes <- "Aggregate distinct-person count; no person keys emitted."
      percent_display <- mcl_count_percent_display(n, denom_n, min_cell_count)
      if (identical(id, "cit_immunochemotherapy") && identical(count_status, "production_aggregate_count_available") && identical(as.numeric(n), 0)) {
        count_status <- "count_available_zero_requires_value_mapping_review"
        notes <- "Query returned zero for CIT/immunochemotherapy; validate LYFO treatment value coding before interpreting this as clinical absence."
        percent_display <- ""
      }
      rows[[length(rows) + 1L]] <- data.frame(
        data_point_id = id,
        clinical_label = defs$clinical_label[[i]],
        denominator = denom_id,
        timing_scope = mcl_count_timing_scope(defs$valid_time_window[[i]]),
        count_status = count_status,
        distinct_person_count_display = count$display,
        percent_of_denominator_display = percent_display,
        denominator_count_display = if (!is.na(denom_n)) mcl_count_suppress(denom_n, min_cell_count)$display else "",
        count_source = "production_aggregate_sql",
        person_key_confidence = "validated_mapping_config",
        timing_validation_status = if (nzchar(qr$date_anchor_used[[1]])) "date_anchor_mapped_requires_validation" else "timing_not_required",
        source_locations = qr$tables_used[[1]],
        notes = notes,
        query_attempted = TRUE,
        query_executed = TRUE,
        query_success = TRUE,
        error_class = "",
        error_message_sanitized = "",
        count_mode = "production_aggregate",
        source_tables = qr$tables_used[[1]],
        person_key_used = qr$person_key_used[[1]],
        date_anchor_used = qr$date_anchor_used[[1]],
        value_rule_used = qr$value_rule_used[[1]] %||% "",
        generated_at = generated_at,
        validation_status = qr$reviewer_notes[[1]],
        stringsAsFactors = FALSE
      )
    } else {
      err_cls <- query_result$error_class %||% ""
      err_msg <- query_result$error_message_sanitized %||% ""
      rows[[length(rows) + 1L]] <- mcl_count_unavailable_data_points(
        defs[i, , drop = FALSE],
        status = if (executable) no_result_status else "count_not_available_requires_value_mapping",
        outputs_dir = outputs_dir,
        project_root = project_root,
        count_mode = "production_aggregate",
        generated_at = generated_at,
        error_class = err_cls,
        error_message_sanitized = err_msg,
        patient_demographics_resolver = patient_demographics_resolver,
        age_source_locator = age_source_locator,
        ibrutinib_source_validation = ibrutinib_source_validation,
        treatment_code_mappings = treatment_code_mappings
      )
    }
  }
  bind_rows_base(rows)
}

mcl_count_age_data_point_ids <- function() {
  c(
    "younger_mcl_proxy_age_le_65",
    "birth_date_available",
    "age_anchor_available",
    "age_computable",
    "age_gt_65",
    "age_missing_uncomputable"
  )
}

mcl_count_relation_not_found_for_source <- function(data_points, schema, table) {
  if (!is.data.frame(data_points) || !nrow(data_points)) {
    return("")
  }
  age_rows <- data_points[data_points$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
  if (!nrow(age_rows)) return("")
  messages <- as.character(age_rows$error_message_sanitized %||% "")
  messages <- messages[nzchar(messages)]
  if (!length(messages)) return("")
  schema <- tolower(as.character(schema %||% ""))
  table <- tolower(as.character(table %||% ""))
  if (!nzchar(schema) || !nzchar(table)) return("")
  for (msg in messages) {
    msg_l <- tolower(msg)
    relation_missing <- grepl("relation", msg_l, fixed = TRUE) && grepl("does not exist", msg_l, fixed = TRUE)
    selected_relation <- grepl(schema, msg_l, fixed = TRUE) && grepl(table, msg_l, fixed = TRUE)
    if (relation_missing && selected_relation) return(msg)
  }
  ""
}

mcl_count_relation_not_found_for_selected <- function(data_points, selected_patient) {
  if (!is.data.frame(selected_patient) || !nrow(selected_patient)) return("")
  mcl_count_relation_not_found_for_source(data_points, selected_patient$schema[[1]], selected_patient$table[[1]])
}

mcl_count_apply_post_selection_patient_check <- function(patient_demographics_resolver, data_points) {
  resolver <- mcl_count_match_empty(patient_demographics_resolver, mcl_count_empty_patient_demographics_resolver())
  selected <- mcl_count_selected_patient_resolver(resolver)
  if (!nrow(selected)) {
    return(list(resolver = resolver, invalidated = FALSE, error_message = ""))
  }
  age_rows <- data_points[data_points$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
  attempted <- is.data.frame(age_rows) && nrow(age_rows) && any(age_rows$query_attempted %in% TRUE, na.rm = TRUE)
  relation_error <- mcl_count_relation_not_found_for_selected(data_points, selected)
  selected_idx <- resolver$selected %in% TRUE &
    tolower(resolver$schema %||% "") == tolower(selected$schema[[1]]) &
    tolower(resolver$table %||% "") == tolower(selected$table[[1]])
  resolver$post_selection_execution_attempted[selected_idx] <- attempted
  resolver$post_selection_execution_success[selected_idx] <- attempted && !nzchar(relation_error)
  resolver$post_selection_execution_error_sanitized[selected_idx] <- relation_error
  if (nzchar(relation_error)) {
    resolver$selected[selected_idx] <- FALSE
    resolver$usable_for_age_counts[selected_idx] <- FALSE
    resolver$reason[selected_idx] <- "post_selection_relation_not_found"
    resolver$notes[selected_idx] <- paste(
      trimws(as.character(resolver$notes[selected_idx] %||% "")),
      "Invalidated after selected relation failed production age-query execution.",
      sep = ifelse(nzchar(trimws(as.character(resolver$notes[selected_idx] %||% ""))), " ", "")
    )
    return(list(resolver = mcl_count_match_empty(resolver, mcl_count_empty_patient_demographics_resolver()), invalidated = TRUE, error_message = relation_error))
  }
  list(resolver = mcl_count_match_empty(resolver, mcl_count_empty_patient_demographics_resolver()), invalidated = FALSE, error_message = "")
}

mcl_count_apply_post_selection_age_source_check <- function(age_source_locator, data_points) {
  locator <- mcl_count_match_empty(age_source_locator, mcl_count_empty_age_source_locator())
  selected <- mcl_count_selected_age_source_locator(locator)
  if (!nrow(selected)) {
    return(list(locator = locator, invalidated = FALSE, error_message = ""))
  }
  age_rows <- data_points[data_points$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
  attempted <- is.data.frame(age_rows) && nrow(age_rows) && any(age_rows$query_attempted %in% TRUE, na.rm = TRUE)
  relation_error <- mcl_count_relation_not_found_for_source(data_points, selected$schema[[1]], selected$table[[1]])
  selected_idx <- locator$selected %in% TRUE &
    tolower(locator$source_type %||% "") == tolower(selected$source_type[[1]]) &
    tolower(locator$schema %||% "") == tolower(selected$schema[[1]]) &
    tolower(locator$table %||% "") == tolower(selected$table[[1]]) &
    tolower(locator$birth_date_column %||% "") == tolower(selected$birth_date_column[[1]]) &
    tolower(locator$age_column %||% "") == tolower(selected$age_column[[1]])
  locator$post_selection_execution_attempted[selected_idx] <- attempted
  locator$post_selection_execution_success[selected_idx] <- attempted && !nzchar(relation_error)
  locator$post_selection_execution_error_sanitized[selected_idx] <- relation_error
  if (nzchar(relation_error)) {
    locator$selected[selected_idx] <- FALSE
    locator$usable_for_age_counts[selected_idx] <- FALSE
    locator$reason[selected_idx] <- "post_selection_relation_not_found"
    locator$notes[selected_idx] <- paste(
      trimws(as.character(locator$notes[selected_idx] %||% "")),
      "Invalidated after selected age source failed production age-query execution.",
      sep = ifelse(nzchar(trimws(as.character(locator$notes[selected_idx] %||% ""))), " ", "")
    )
    return(list(locator = mcl_count_match_empty(locator, mcl_count_empty_age_source_locator()), invalidated = TRUE, error_message = relation_error))
  }
  list(locator = mcl_count_match_empty(locator, mcl_count_empty_age_source_locator()), invalidated = FALSE, error_message = "")
}

mcl_count_fail_closed_age_data_points <- function(data_points, error_message = "") {
  if (!is.data.frame(data_points) || !nrow(data_points)) return(data_points)
  hit <- data_points$data_point_id %in% mcl_count_age_data_point_ids() |
    data_points$denominator %in% "younger_mcl_proxy_age_le_65"
  if (!any(hit, na.rm = TRUE)) return(data_points)
  data_points$count_status[hit] <- mcl_count_patient_demographics_status()
  data_points$distinct_person_count_display[hit] <- ""
  data_points$percent_of_denominator_display[hit] <- ""
  data_points$denominator_count_display[hit] <- ""
  data_points$count_source[hit] <- "not_executable_patient_demographics_mapping"
  data_points$person_key_confidence[hit] <- "requires_patient_demographics_mapping"
  data_points$timing_validation_status[hit] <- "requires_patient_demographics_mapping"
  data_points$source_locations[hit] <- "RKKP_LYFO; patient_demographics_unverified"
  data_points$notes[hit] <- "Selected patient demographics relation failed post-selection execution; age counts require a verified queryable demographics relation. See mcl_triangle_patient_demographics_resolver.csv post_selection_execution_error_sanitized for the production relation-not-found diagnostic."
  data_points$query_attempted[hit] <- TRUE
  data_points$query_executed[hit] <- FALSE
  data_points$query_success[hit] <- FALSE
  data_points$error_class[hit] <- mcl_count_patient_demographics_status()
  data_points$error_message_sanitized[hit] <- if (nzchar(error_message %||% "")) "see resolver audit: post_selection_execution_error_sanitized" else ""
  data_points$source_tables[hit] <- "RKKP_LYFO; patient_demographics_unverified"
  data_points$person_key_used[hit] <- "patientid"
  data_points$date_anchor_used[hit] <- ""
  data_points$validation_status[hit] <- "post_selection_resolver_invalidated"
  data_points
}

mcl_count_display_to_number <- function(x) {
  x <- as.character(x %||% "")
  x <- x[1]
  if (!nzchar(x) || grepl("^<", x)) return(NA_real_)
  suppressWarnings(as.numeric(gsub(",", "", x, fixed = TRUE)))
}

mcl_count_available_statuses <- function() {
  c("production_aggregate_count_available", "count_available", "count_available_timing_not_validated", "suppressed_small_cell")
}

mcl_count_data_row <- function(data_points, id) {
  if (!is.data.frame(data_points) || !nrow(data_points)) return(mcl_count_empty_data_point_counts())
  data_points[data_points$data_point_id == id, , drop = FALSE]
}

mcl_count_is_available_row <- function(row) {
  is.data.frame(row) && nrow(row) && row$count_status[[1]] %in% mcl_count_available_statuses() && nzchar(row$distinct_person_count_display[[1]] %||% "")
}

mcl_count_availability_waterfall_from_data_points <- function(data_points) {
  ids <- c("all_lyfo_mcl", "diagnosis_date", "first_line_treatment_date", "asct_hdt_first_line", "ki67_aeki", "os_death", "relapse_progression_ffs_proxy")
  labels <- c(
    "All LYFO MCL",
    "Diagnosis date available",
    "First-line treatment date available",
    "First-line ASCT/HDT evidence",
    "Ki-67 AEKI evidence",
    "OS/death evidence",
    "Relapse/progression/FFS proxy"
  )
  rows <- list()
  for (i in seq_along(ids)) {
    row <- mcl_count_data_row(data_points, ids[[i]])
    if (mcl_count_is_available_row(row)) {
      rows[[length(rows) + 1L]] <- data.frame(
        step_order = length(rows) + 1L,
        step_id = ids[[i]],
        step_label = labels[[i]],
        denominator = row$denominator[[1]],
        timing_scope = row$timing_scope[[1]],
        count_status = row$count_status[[1]],
        distinct_person_count_display = row$distinct_person_count_display[[1]],
        percent_of_start_display = if (identical(ids[[i]], "all_lyfo_mcl")) "100%" else "",
        cumulative_rule = "data_point_availability_not_cumulative",
        notes = "Independent aggregate data-point availability count. This is not a cumulative inclusion waterfall; overlap/intersection queries are required before interpreting combined cohort sizes.",
        stringsAsFactors = FALSE
      )
    }
  }
  if (!length(rows)) return(mcl_count_unavailable_waterfall())
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_inclusion_waterfall())
}

mcl_count_overlap_status_rows <- function(data_points) {
  pairs <- data.frame(
    row_data_point_id = c("ki67_aeki", "ki67_aeki", "asct_hdt_first_line", "asct_hdt_first_line", "os_death"),
    column_data_point_id = c("asct_hdt_first_line", "os_death", "os_death", "relapse_progression_ffs_proxy", "relapse_progression_ffs_proxy"),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(pairs)), function(i) {
    row_id <- pairs$row_data_point_id[[i]]
    col_id <- pairs$column_data_point_id[[i]]
    row <- mcl_count_data_row(data_points, row_id)
    col <- mcl_count_data_row(data_points, col_id)
    status <- "count_not_available_requires_production_validation"
    note <- "Pairwise overlap requires a dedicated aggregate intersection query; do not infer overlap from marginal counts."
    if (!mcl_count_is_available_row(row)) {
      status <- row$count_status[[1]] %||% status
      note <- paste("Row data point is not count-available:", row_id)
    } else if (!mcl_count_is_available_row(col)) {
      status <- col$count_status[[1]] %||% status
      note <- paste("Column data point is not count-available:", col_id)
    }
    data.frame(
      denominator = "all_lyfo_mcl",
      row_data_point_id = row_id,
      column_data_point_id = col_id,
      timing_scope = "ever_available",
      count_status = status,
      distinct_person_count_display = "",
      percent_of_denominator_display = "",
      notes = note,
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_overlap_matrix())
}

mcl_count_exposure_strata_status_rows <- function(data_points) {
  ibrutinib <- mcl_count_data_row(data_points, "ibrutinib_exposure")
  note <- if (mcl_count_is_available_row(ibrutinib)) {
    "Descriptive feasibility stratum requires aggregate intersection queries with ASCT/HDT. Marginal evidence alone is not a stratum count."
  } else {
    "Ibrutinib predicate is not validated/count-available, so ASCT/HDT x ibrutinib strata are unavailable."
  }
  status <- if (mcl_count_is_available_row(ibrutinib)) {
    "count_not_available_requires_dedicated_intersection_query"
  } else if (nrow(ibrutinib)) {
    ibrutinib$count_status[[1]]
  } else {
    "count_not_available_requires_value_mapping"
  }
  rows <- data.frame(
    denominator = c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65"),
    asct_hdt_first_line_status = "not_computed_without_intersection_query",
    ibrutinib_status = "not_computed_without_validated_ibrutinib_predicate",
    timing_scope = "first_line_window",
    count_status = status %||% "count_not_available_requires_value_mapping",
    distinct_person_count_display = "",
    percent_of_denominator_display = "",
    notes = note,
    stringsAsFactors = FALSE
  )
  mcl_count_match_empty(rows, mcl_count_empty_exposure_strata_counts())
}

mcl_count_landmark_status_rows <- function(data_points) {
  reqs <- data.frame(
    requirement = c(
      "MCL patients with diagnosis date",
      "MCL patients with first-line treatment date",
      "MCL patients alive at landmark",
      "MCL patients without event before landmark",
      "MCL patients with ASCT/HDT status known at/after landmark",
      "MCL patients with ibrutinib exposure status known at/after landmark",
      "MCL patients with high-risk biology known before landmark"
    ),
    set_id = c(
      "diagnosis_date",
      "first_line_treatment_date",
      "alive_at_landmark",
      "event_free_pre_landmark",
      "asct_hdt_status_known_landmark",
      "ibrutinib_status_known_landmark",
      "high_risk_biology_pre_landmark"
    ),
    timing_scope = c("near_diagnosis", "first_line_window", "pre_landmark", "pre_landmark", "post_landmark", "post_landmark", "pre_landmark"),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(reqs)), function(i) {
    row <- mcl_count_data_row(data_points, reqs$set_id[[i]])
    available <- mcl_count_is_available_row(row)
    data.frame(
      landmark_id = "six_months_after_first_line_start",
      landmark_label = "6 months after first-line start",
      requirement = reqs$requirement[[i]],
      denominator = if (available) row$denominator[[1]] else "younger_mcl_proxy_age_le_65",
      timing_scope = reqs$timing_scope[[i]],
      count_status = if (available) row$count_status[[1]] else (row$count_status[[1]] %||% "count_not_available_requires_date_mapping"),
      distinct_person_count_display = if (available) row$distinct_person_count_display[[1]] else "",
      percent_of_denominator_display = if (available) row$percent_of_denominator_display[[1]] else "",
      notes = if (available) {
        "Dedicated aggregate date-window count for landmark feasibility; still descriptive and not a target-trial emulation."
      } else {
        "Landmark-specific count not available until date/value mappings and aggregate intersection queries are validated."
      },
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_landmark_counts())
}

mcl_count_ki67_summary_from_data_points <- function(data_points) {
  ki <- mcl_count_data_row(data_points, "ki67_aeki")
  if (!mcl_count_is_available_row(ki)) return(mcl_count_empty_ki67_person_summary())
  rows <- data.frame(
    denominator = "all_lyfo_mcl",
    timing_window = "ever_available",
    distinct_person_count_display = ki$distinct_person_count_display[[1]],
    percent_of_denominator_display = ki$percent_of_denominator_display[[1]],
    valid_aeki_code_count = "",
    unique_percent_values_observed = "",
    source_locations = "public.SDS_pato.c_snomedkode",
    validation_status = "aggregate_evidence_found_requires_validation",
    count_status = ki$count_status[[1]],
    notes = "Distinct LYFO MCL people with linkable aggregate AEKI Ki-67 percentage-code evidence; source-specific and clinical validation are still required before analytic cohort extraction.",
    stringsAsFactors = FALSE
  )
  mcl_count_match_empty(rows, mcl_count_empty_ki67_person_summary())
}

mcl_count_answerability_threshold <- function() 20L

mcl_count_answerability_interpretation <- function(n, status, threshold = mcl_count_answerability_threshold(), mapping_gap = FALSE) {
  if (isTRUE(mapping_gap) || grepl("requires_value_mapping", status %||% "", fixed = TRUE)) return("not_countable_yet_value_mapping_gap")
  if (grepl("requires_date|timing", status %||% "", ignore.case = TRUE)) return("not_countable_yet_timing_gap")
  if (!status %in% mcl_count_available_statuses()) return("not_countable_yet_mapping_gap")
  n_num <- suppressWarnings(as.numeric(n))
  if (is.na(n_num) || n_num < threshold) return("likely_underpowered_for_effect_modelling")
  "possibly_sufficient_for_descriptive_analysis"
}

mcl_count_high_risk_threshold <- function(project_root = ".") {
  path <- file.path(project_root, "clinical_questions", "mcl_triangle_high_risk_biology_definitions.yml")
  if (file.exists(path) && requireNamespace("yaml", quietly = TRUE)) {
    parsed <- tryCatch(yaml::read_yaml(path), error = function(e) NULL)
    value <- suppressWarnings(as.numeric(parsed$ki67_aeki_threshold_percent %||% NA_real_))
    if (!is.na(value)) return(value)
  }
  30
}

mcl_count_set_available <- function(sets, id) {
  is.list(sets) && id %in% names(sets)
}

mcl_count_people_count_row <- function(people, denom_people, min_cell_count = 5L) {
  count <- mcl_count_suppress(length(unique(people)), min_cell_count)
  list(
    status = mcl_count_production_status(count$status),
    display = count$display,
    percent = mcl_count_percent_display(length(unique(people)), length(unique(denom_people)), min_cell_count),
    suppressed = identical(count$status, "suppressed_small_cell")
  )
}

mcl_count_age_proxy_from_data_points <- function(data_points) {
  all_mcl <- mcl_count_data_row(data_points, "all_lyfo_mcl")
  diagnosis <- mcl_count_data_row(data_points, "diagnosis_date")
  young <- mcl_count_data_row(data_points, "younger_mcl_proxy_age_le_65")
  birth <- mcl_count_data_row(data_points, "birth_date_available")
  anchor <- mcl_count_data_row(data_points, "age_anchor_available")
  computable <- mcl_count_data_row(data_points, "age_computable")
  age_gt_65 <- mcl_count_data_row(data_points, "age_gt_65")
  uncomputable <- mcl_count_data_row(data_points, "age_missing_uncomputable")
  row_value <- function(row, field, fallback = "") {
    if (is.data.frame(row) && nrow(row) && field %in% names(row)) row[[field]][[1]] %||% fallback else fallback
  }
  rows <- list(
    data.frame(metric = "total_mcl_with_birth_date_available", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(birth, "count_status", "count_not_available_requires_production_validation"), distinct_person_count_display = row_value(birth, "distinct_person_count_display"), percent_of_denominator_display = row_value(birth, "percent_of_denominator_display"), source_locations = row_value(birth, "source_locations", "public.patient.date_birth"), value_rule_used = row_value(birth, "value_rule_used", "valid parsed birth date"), validation_status = row_value(birth, "validation_status", "requires_age_diagnostic_query"), notes = "Aggregate birth-date diagnostic; no birth dates are emitted.", stringsAsFactors = FALSE),
    data.frame(metric = "total_mcl_with_diagnosis_or_treatment_anchor_available", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(anchor, "count_status", row_value(diagnosis, "count_status", "count_not_available_requires_date_mapping")), distinct_person_count_display = row_value(anchor, "distinct_person_count_display", row_value(diagnosis, "distinct_person_count_display")), percent_of_denominator_display = row_value(anchor, "percent_of_denominator_display", row_value(diagnosis, "percent_of_denominator_display")), source_locations = row_value(anchor, "source_locations", row_value(diagnosis, "source_locations", "RKKP_LYFO")), value_rule_used = row_value(anchor, "value_rule_used", row_value(diagnosis, "value_rule_used")), validation_status = row_value(anchor, "validation_status", row_value(diagnosis, "validation_status")), notes = "Aggregate selected age-anchor diagnostic using Reg_BehandlingBeslutning_dt, then Beh_KemoterapiStart_dt, then Reg_DiagnostiskBiopsi_dt.", stringsAsFactors = FALSE),
    data.frame(metric = "total_mcl_with_age_computable", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(computable, "count_status", if (mcl_count_is_available_row(young)) young$count_status[[1]] else (young$count_status[[1]] %||% "count_not_available_requires_date_mapping")), distinct_person_count_display = row_value(computable, "distinct_person_count_display", if (mcl_count_is_available_row(young)) young$distinct_person_count_display[[1]] else ""), percent_of_denominator_display = row_value(computable, "percent_of_denominator_display", if (mcl_count_is_available_row(young)) young$percent_of_denominator_display[[1]] else ""), source_locations = row_value(computable, "source_locations", "public.patient.date_birth; public.RKKP_LYFO diagnosis/treatment anchor"), value_rule_used = row_value(computable, "value_rule_used", "birth date and selected LYFO age anchor parse as valid dates"), validation_status = row_value(computable, "validation_status", "age_proxy_requires_anchor_validation"), notes = "Computable age diagnostic is a distinct-person aggregate count.", stringsAsFactors = FALSE),
    data.frame(metric = "total_mcl_age_le_65", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(young, "count_status", "count_not_available_requires_date_mapping"), distinct_person_count_display = row_value(young, "distinct_person_count_display"), percent_of_denominator_display = row_value(young, "percent_of_denominator_display"), source_locations = row_value(young, "source_locations", "RKKP_LYFO; patient"), value_rule_used = row_value(young, "value_rule_used", "age at selected LYFO anchor < 66 years"), validation_status = row_value(young, "validation_status"), notes = "Younger proxy only; not transplant eligibility.", stringsAsFactors = FALSE),
    data.frame(metric = "total_mcl_age_gt_65", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(age_gt_65, "count_status", "count_not_available_requires_production_validation"), distinct_person_count_display = row_value(age_gt_65, "distinct_person_count_display"), percent_of_denominator_display = row_value(age_gt_65, "percent_of_denominator_display"), source_locations = row_value(age_gt_65, "source_locations", "verified birth-date source; RKKP_LYFO diagnosis/treatment anchor"), value_rule_used = row_value(age_gt_65, "value_rule_used", "age at selected LYFO anchor >= 66 years"), validation_status = row_value(age_gt_65, "validation_status", "requires_age_diagnostic_query"), notes = "Older proxy diagnostic; not a treatment eligibility label.", stringsAsFactors = FALSE),
    data.frame(metric = "total_mcl_age_missing_uncomputable", denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = row_value(uncomputable, "count_status", "count_not_available_requires_production_validation"), distinct_person_count_display = row_value(uncomputable, "distinct_person_count_display"), percent_of_denominator_display = row_value(uncomputable, "percent_of_denominator_display"), source_locations = row_value(uncomputable, "source_locations", "verified birth-date source; RKKP_LYFO diagnosis/treatment anchor"), value_rule_used = row_value(uncomputable, "value_rule_used", "invalid or missing birth/anchor dates"), validation_status = row_value(uncomputable, "validation_status", "requires_age_diagnostic_query"), notes = "Uncomputable age is counted only by aggregate diagnostic query; no dates are emitted.", stringsAsFactors = FALSE)
  )
  rows[[1]]$percent_of_denominator_display <- ""
  if (!mcl_count_is_available_row(all_mcl)) {
    rows <- lapply(rows, function(row) {
      if (!identical(row$metric, "total_mcl_with_diagnosis_date_available")) row$percent_of_denominator_display <- ""
      row
    })
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_age_proxy_counts())
}

mcl_count_age_proxy_from_sets <- function(sets, min_cell_count = 5L) {
  denom <- mcl_count_set(sets, "all_lyfo_mcl")
  row_for_set <- function(metric, id, label, source, rule, note) {
    if (!mcl_count_set_available(sets, id)) {
      return(data.frame(metric = metric, denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = "count_not_available_requires_production_validation", distinct_person_count_display = "", percent_of_denominator_display = "", source_locations = source, value_rule_used = rule, validation_status = "requires_dedicated_aggregate_query", notes = note, stringsAsFactors = FALSE))
    }
    people <- intersect(denom, mcl_count_set(sets, id))
    counted <- mcl_count_people_count_row(people, denom, min_cell_count)
    data.frame(metric = metric, denominator = "all_lyfo_mcl", timing_window = "near_diagnosis", count_status = counted$status, distinct_person_count_display = counted$display, percent_of_denominator_display = counted$percent, source_locations = source, value_rule_used = rule, validation_status = "direct_aggregate_count_hook", notes = note, stringsAsFactors = FALSE)
  }
  rows <- list(
    row_for_set("total_mcl_with_birth_date_available", "birth_date_available", "Birth date", "public.patient.date_birth", "valid parsed birth date", "Aggregate birth-date availability."),
    row_for_set("total_mcl_with_diagnosis_date_available", "diagnosis_date", "Diagnosis date", "public.RKKP_LYFO", "valid parsed LYFO diagnosis date", "Aggregate diagnosis-date availability."),
    row_for_set("total_mcl_with_age_computable", "age_computable", "Computable age", "public.patient; public.RKKP_LYFO", "valid birth and age anchor dates", "Aggregate age-computable availability."),
    row_for_set("total_mcl_age_le_65", "younger_mcl_proxy_age_le_65", "Age <=65", "public.patient; public.RKKP_LYFO", "age at selected LYFO anchor < 66 years", "Younger proxy only; not transplant eligibility."),
    row_for_set("total_mcl_age_missing_uncomputable", "age_missing_uncomputable", "Uncomputable age", "public.patient; public.RKKP_LYFO", "missing/invalid birth or anchor date", "Aggregate uncomputable-age diagnostic.")
  )
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_age_proxy_counts())
}

mcl_count_ibrutinib_counts_from_data_points <- function(data_points) {
  ib <- mcl_count_data_row(data_points, "ibrutinib_exposure")
  ib_available <- mcl_count_is_available_row(ib)
  rows <- list()
  for (denom in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    same_denom <- ib_available && identical(ib$denominator[[1]], denom)
    rows[[length(rows) + 1L]] <- data.frame(
      denominator = denom,
      timing_window = "ever_observed",
      distinct_person_count_display = if (same_denom) ib$distinct_person_count_display[[1]] else "",
      percent_of_denominator_display = if (same_denom) ib$percent_of_denominator_display[[1]] else "",
      source_locations = ib$source_locations[[1]] %||% "medication/code sources",
      value_rule_used = ib$value_rule_used[[1]] %||% "validated ibrutinib/BTK exposure field or code",
      validation_status = if (same_denom) (ib$validation_status[[1]] %||% "aggregate_evidence_found_requires_validation") else "requires_value_mapping",
      count_status = if (same_denom) (ib$count_status[[1]] %||% "production_aggregate_count_available") else "count_not_available_requires_value_mapping",
      notes = if (same_denom) "Ibrutinib exposure aggregate count; timing still requires source-specific validation." else "No validated executable Ibrutinib exposure predicate is available; source names alone are not evidence.",
      stringsAsFactors = FALSE
    )
    rows[[length(rows) + 1L]] <- data.frame(
      denominator = denom,
      timing_window = "first_line_window",
      distinct_person_count_display = "",
      percent_of_denominator_display = "",
      source_locations = ib$source_locations[[1]] %||% "medication/code sources",
      value_rule_used = "first-line-window Ibrutinib exposure predicate",
      validation_status = if (ib_available) "requires_timing_validation" else "requires_value_mapping",
      count_status = if (ib_available) "count_not_available_requires_date_mapping" else "count_not_available_requires_value_mapping",
      notes = if (ib_available) "First-line-window Ibrutinib requires validated medication date anchors relative to LYFO first-line treatment." else "First-line-window Ibrutinib is blocked until an executable Ibrutinib medication/code predicate is validated.",
      stringsAsFactors = FALSE
    )
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_exposure_counts())
}

mcl_count_ibrutinib_counts_from_sets <- function(sets, min_cell_count = 5L) {
  rows <- list()
  for (denom_id in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    denom <- mcl_count_set(sets, denom_id)
    if (mcl_count_set_available(sets, "ibrutinib_exposure")) {
      people <- intersect(denom, mcl_count_set(sets, "ibrutinib_exposure"))
      counted <- mcl_count_people_count_row(people, denom, min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(denominator = denom_id, timing_window = "ever_observed", distinct_person_count_display = counted$display, percent_of_denominator_display = counted$percent, source_locations = "validated medication/code source set", value_rule_used = "validated ibrutinib/BTK exposure field or code", validation_status = "direct_aggregate_count_hook", count_status = counted$status, notes = "Ever-observed Ibrutinib exposure; descriptive feasibility only.", stringsAsFactors = FALSE)
      first_line_status <- "count_not_available_requires_date_mapping"
      first_line_validation <- "requires_timing_validation"
      first_line_notes <- "First-line-window Ibrutinib requires medication timing validation."
    } else {
      rows[[length(rows) + 1L]] <- data.frame(denominator = denom_id, timing_window = "ever_observed", distinct_person_count_display = "", percent_of_denominator_display = "", source_locations = "medication/code sources", value_rule_used = "validated ibrutinib/BTK exposure field or code", validation_status = "requires_value_mapping", count_status = "count_not_available_requires_value_mapping", notes = "No validated Ibrutinib source set provided.", stringsAsFactors = FALSE)
      first_line_status <- "count_not_available_requires_value_mapping"
      first_line_validation <- "requires_value_mapping"
      first_line_notes <- "First-line-window Ibrutinib is blocked until an executable Ibrutinib medication/code predicate is validated."
    }
    rows[[length(rows) + 1L]] <- data.frame(denominator = denom_id, timing_window = "first_line_window", distinct_person_count_display = "", percent_of_denominator_display = "", source_locations = "medication/code sources", value_rule_used = "first-line-window Ibrutinib exposure predicate", validation_status = first_line_validation, count_status = first_line_status, notes = first_line_notes, stringsAsFactors = FALSE)
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_ibrutinib_exposure_counts())
}

mcl_count_treatment_strategy_from_sets <- function(sets, min_cell_count = 5L) {
  rows <- list()
  for (denom_id in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    denom <- mcl_count_set(sets, denom_id)
    ib_yes <- intersect(denom, mcl_count_set(sets, "ibrutinib_exposure"))
    asct_yes <- intersect(denom, mcl_count_set(sets, "asct_hdt_first_line"))
    cells <- list(
      list("yes", "yes", intersect(ib_yes, asct_yes)),
      list("yes", "unknown_or_no_evidence", setdiff(ib_yes, asct_yes)),
      list("unknown_or_no_evidence", "yes", setdiff(asct_yes, ib_yes)),
      list("unknown_or_no_evidence", "unknown_or_no_evidence", setdiff(denom, union(ib_yes, asct_yes)))
    )
    if (!mcl_count_set_available(sets, "ibrutinib_exposure")) {
      rows[[length(rows) + 1L]] <- data.frame(denominator = denom_id, timing_window = "ever_observed", ibrutinib_status = "not_countable", asct_hdt_first_line_status = "not_countable", distinct_person_count_display = "", percent_of_denominator_display = "", count_status = "count_not_available_requires_value_mapping", validation_status = "requires_ibrutinib_value_mapping", notes = "Ibrutinib x ASCT/HDT strata require a validated Ibrutinib predicate.", stringsAsFactors = FALSE)
    } else {
      for (cell in cells) {
        counted <- mcl_count_people_count_row(cell[[3]], denom, min_cell_count)
        rows[[length(rows) + 1L]] <- data.frame(denominator = denom_id, timing_window = "ever_observed", ibrutinib_status = cell[[1]], asct_hdt_first_line_status = cell[[2]], distinct_person_count_display = counted$display, percent_of_denominator_display = counted$percent, count_status = counted$status, validation_status = "direct_aggregate_count_hook", notes = "Descriptive feasibility stratum only; no timing, eligibility, response, immortal-time, or confounding adjustment.", stringsAsFactors = FALSE)
      }
    }
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_treatment_strategy_strata_counts())
}

mcl_count_treatment_strategy_from_data_points <- function(data_points) {
  ib <- mcl_count_data_row(data_points, "ibrutinib_exposure")
  status <- if (mcl_count_is_available_row(ib)) {
    "count_not_available_requires_dedicated_intersection_query"
  } else {
    ib$count_status[[1]] %||% "count_not_available_requires_value_mapping"
  }
  rows <- data.frame(
    denominator = c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65"),
    timing_window = "ever_observed",
    ibrutinib_status = "not_countable_without_validated_predicate",
    asct_hdt_first_line_status = "not_countable_without_intersection_query",
    distinct_person_count_display = "",
    percent_of_denominator_display = "",
    count_status = status,
    validation_status = "requires_dedicated_intersection_query",
    notes = "Treatment-strategy strata require aggregate intersection SQL; marginal counts are not converted into strata.",
    stringsAsFactors = FALSE
  )
  mcl_count_match_empty(rows, mcl_count_empty_treatment_strategy_strata_counts())
}

mcl_count_high_risk_from_data_points <- function(data_points, project_root = ".") {
  threshold <- mcl_count_high_risk_threshold(project_root)
  make <- function(component, id, rule, source, note, positive = FALSE) {
    row <- mcl_count_data_row(data_points, id)
    available <- !isTRUE(positive) && mcl_count_is_available_row(row)
    data.frame(
      denominator = "all_lyfo_mcl",
      biology_component = component,
      timing_window = "near_diagnosis",
      distinct_person_count_display = if (available) row$distinct_person_count_display[[1]] else "",
      percent_of_denominator_display = if (available) row$percent_of_denominator_display[[1]] else "",
      value_rule_used = rule,
      source_locations = source,
      validation_status = if (available) row$validation_status[[1]] else "requires_component_value_mapping",
      count_status = if (available) row$count_status[[1]] else "count_not_available_requires_value_mapping",
      notes = note,
      stringsAsFactors = FALSE
    )
  }
  rows <- list(
    make("blastoid_pleomorphic_known", "blastoid_pleomorphic_morphology", "validated blastoid/pleomorphic source evidence", "LYFO histology/PATOBANK", "Blastoid/pleomorphic classifiability requires source-specific value mappings."),
    make("blastoid_pleomorphic_high_risk_yes", "blastoid_pleomorphic_morphology", "blastoid or pleomorphic morphology positive", "LYFO histology/PATOBANK", "Positive high-risk morphology is not inferred without validated values.", TRUE),
    make("ki67_aeki_known", "ki67_aeki", "valid AEKI000-AEKI100", "public.SDS_pato.c_snomedkode", "Ki-67 known from aggregate AEKI evidence; clinical validation required."),
    make("ki67_aeki_high_threshold", "ki67_aeki", paste0("AEKI parsed percent >= ", threshold), "public.SDS_pato.c_snomedkode", "Ki-67 high threshold requires a dedicated aggregate threshold/person query.", TRUE),
    make("tp53_p53_del17p_known", "tp53_p53_del17p", "validated TP53/p53/del17p evidence", "pathology/FISH/molecular", "TP53/p53/del17p classifiability requires validated source mappings."),
    make("tp53_p53_del17p_high_risk_yes", "tp53_p53_del17p", "TP53 mutation/deletion/aberration or high p53 expression", "pathology/FISH/molecular", "TP53 high-risk positivity requires validated values.", TRUE),
    make("mipi_computable", "mipi_mipic_components", "MIPI component availability", "RKKP_LYFO/labs", "MIPI computable is component availability, not a calculated score."),
    make("mipi_high", "mipi_mipic_components", "MIPI high risk", "RKKP_LYFO/labs", "MIPI high-risk classification requires score computation.", TRUE),
    make("mipi_c_computable", "mipi_mipic_components", "MIPI-c component availability including Ki-67", "RKKP_LYFO/labs/Ki-67", "MIPI-c requires Ki-67 validation."),
    make("mipi_c_high", "mipi_mipic_components", "MIPI-c high risk", "RKKP_LYFO/labs/Ki-67", "MIPI-c high-risk classification requires score computation.", TRUE),
    make("any_high_risk_biology_known", "high_risk_biology_pre_landmark", "Ki-67 high threshold or MIPI component availability before landmark", "SDS_pato; RKKP_LYFO", "Union of deterministic Ki-67/MIPI component evidence before landmark; TP53 and morphology positivity are not inferred."),
    data.frame(denominator = "all_lyfo_mcl", biology_component = "standard_risk_biology_classifiable", timing_window = "near_diagnosis", distinct_person_count_display = "", percent_of_denominator_display = "", value_rule_used = "all required high-risk components known and negative", source_locations = "Ki-67; TP53; morphology; MIPI-c", validation_status = "requires_component_value_mapping", count_status = "count_not_available_requires_value_mapping", notes = "Missing high-risk components must not be treated as standard risk.", stringsAsFactors = FALSE),
    data.frame(denominator = "all_lyfo_mcl", biology_component = "high_risk_biology_classifiable", timing_window = "near_diagnosis", distinct_person_count_display = "", percent_of_denominator_display = "", value_rule_used = "high-risk or standard-risk classifiable", source_locations = "Ki-67; TP53; morphology; MIPI-c", validation_status = "requires_component_value_mapping", count_status = "count_not_available_requires_value_mapping", notes = "Risk biology classifiability requires component evidence and value semantics.", stringsAsFactors = FALSE)
  )
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_high_risk_biology_counts())
}

mcl_count_high_risk_from_sets <- function(sets, min_cell_count = 5L, project_root = ".") {
  data_points <- mcl_count_data_points_from_sets(mcl_count_default_definitions(), sets, min_cell_count)
  out <- mcl_count_high_risk_from_data_points(data_points, project_root = project_root)
  denom <- mcl_count_set(sets, "all_lyfo_mcl")
  for (component in c("ki67_aeki_high_threshold", "tp53_p53_del17p_high_risk_yes", "blastoid_pleomorphic_high_risk_yes")) {
    set_id <- switch(component,
      ki67_aeki_high_threshold = "ki67_aeki_high_threshold",
      tp53_p53_del17p_high_risk_yes = "tp53_p53_del17p",
      blastoid_pleomorphic_high_risk_yes = "blastoid_pleomorphic_morphology"
    )
    if (mcl_count_set_available(sets, set_id)) {
      people <- intersect(denom, mcl_count_set(sets, set_id))
      counted <- mcl_count_people_count_row(people, denom, min_cell_count)
      hit <- out$biology_component == component
      out$distinct_person_count_display[hit] <- counted$display
      out$percent_of_denominator_display[hit] <- counted$percent
      out$count_status[hit] <- counted$status
      out$validation_status[hit] <- "direct_aggregate_count_hook"
    }
  }
  out
}

mcl_count_answerability_rows_from_sets <- function(sets, min_cell_count = 5L) {
  specs <- data.frame(
    intersection_id = c(
      "age_le_65_mcl",
      "age_le_65_first_line_treatment_date",
      "age_le_65_ibrutinib_exposure_known",
      "age_le_65_first_line_asct_hdt_status_known",
      "age_le_65_ibrutinib_and_asct_status_known",
      "age_le_65_ibrutinib_yes_asct_yes",
      "age_le_65_ibrutinib_yes_asct_no",
      "age_le_65_ibrutinib_yes_asct_known_os_death",
      "age_le_65_ibrutinib_yes_asct_known_relapse_proxy",
      "age_le_65_ibrutinib_yes_asct_known_ki67_known",
      "age_le_65_ibrutinib_yes_asct_known_any_high_risk_known",
      "age_le_65_ibrutinib_yes_asct_known_high_risk_os",
      "age_le_65_ibrutinib_yes_asct_known_standard_risk_os"
    ),
    required_data_points = c(
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65; first_line_treatment_date",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure",
      "younger_mcl_proxy_age_le_65; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line_no_or_unknown",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; os_death",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; relapse_progression_ffs_proxy",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; ki67_aeki",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; high_risk_biology_pre_landmark",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; high_risk_biology_classifiable; os_death",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; standard_risk_biology_classifiable; os_death"
    ),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(specs)), function(i) {
    ids <- trimws(strsplit(specs$required_data_points[[i]], ";", fixed = TRUE)[[1]])
    unsupported <- ids[grepl("no_or_unknown|classifiable", ids)]
    if (length(unsupported)) {
      return(data.frame(intersection_id = specs$intersection_id[[i]], denominator = "younger_mcl_proxy_age_le_65", required_data_points = specs$required_data_points[[i]], timing_window = "first_line_window", distinct_person_count_display = "", count_status = "count_not_available_requires_value_mapping", small_cell_suppressed = FALSE, interpretation = "not_countable_yet_value_mapping_gap", answerability_impact = "Risk-adapted de-escalation not answerable; biology/exposure classifiability is incomplete.", notes = "No validated no/standard-risk classifiability predicate is available.", stringsAsFactors = FALSE))
    }
    missing <- ids[!vapply(ids, function(set_id) mcl_count_set_available(sets, set_id), logical(1))]
    if (length(missing)) {
      return(data.frame(intersection_id = specs$intersection_id[[i]], denominator = "younger_mcl_proxy_age_le_65", required_data_points = specs$required_data_points[[i]], timing_window = "first_line_window", distinct_person_count_display = "", count_status = "count_not_available_requires_value_mapping", small_cell_suppressed = FALSE, interpretation = "not_countable_yet_value_mapping_gap", answerability_impact = "Required intersection cannot be counted until mappings are validated.", notes = paste("Missing distinct-person set(s):", paste(missing, collapse = ", ")), stringsAsFactors = FALSE))
    }
    people <- Reduce(intersect, lapply(ids, mcl_count_set, sets = sets))
    counted <- mcl_count_people_count_row(people, mcl_count_set(sets, "younger_mcl_proxy_age_le_65"), min_cell_count)
    interpretation <- mcl_count_answerability_interpretation(length(people), counted$status)
    data.frame(intersection_id = specs$intersection_id[[i]], denominator = "younger_mcl_proxy_age_le_65", required_data_points = specs$required_data_points[[i]], timing_window = "first_line_window", distinct_person_count_display = counted$display, count_status = counted$status, small_cell_suppressed = counted$suppressed, interpretation = interpretation, answerability_impact = if (identical(interpretation, "possibly_sufficient_for_descriptive_analysis")) "May support descriptive feasibility, not causal inference." else "Insufficient or unavailable for modelling the risk-adapted question.", notes = "Aggregate distinct-person intersection; no row-level data emitted.", stringsAsFactors = FALSE)
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_answerability_intersections())
}

mcl_count_answerability_rows_from_data_points <- function(data_points) {
  specs <- c(
    "age_le_65_mcl",
    "age_le_65_first_line_treatment_date",
    "age_le_65_ibrutinib_exposure_known",
    "age_le_65_first_line_asct_hdt_status_known",
    "age_le_65_ibrutinib_and_asct_status_known",
    "age_le_65_ibrutinib_yes_asct_yes",
    "age_le_65_ibrutinib_yes_asct_no",
    "age_le_65_ibrutinib_yes_asct_known_os_death",
    "age_le_65_ibrutinib_yes_asct_known_relapse_proxy",
    "age_le_65_ibrutinib_yes_asct_known_ki67_known",
    "age_le_65_ibrutinib_yes_asct_known_any_high_risk_known",
    "age_le_65_ibrutinib_yes_asct_known_high_risk_os",
    "age_le_65_ibrutinib_yes_asct_known_standard_risk_os"
  )
  young <- mcl_count_data_row(data_points, "younger_mcl_proxy_age_le_65")
  rows <- lapply(specs, function(id) {
    status <- if (identical(id, "age_le_65_mcl") && mcl_count_is_available_row(young)) young$count_status[[1]] else "count_not_available_requires_production_validation"
    display <- if (identical(id, "age_le_65_mcl") && mcl_count_is_available_row(young)) young$distinct_person_count_display[[1]] else ""
    interpretation <- if (identical(id, "age_le_65_mcl") && mcl_count_is_available_row(young)) mcl_count_answerability_interpretation(mcl_count_display_to_number(display), status) else "not_countable_yet_mapping_gap"
    data.frame(intersection_id = id, denominator = "younger_mcl_proxy_age_le_65", required_data_points = "requires dedicated aggregate intersection SQL", timing_window = "first_line_window", distinct_person_count_display = display, count_status = status, small_cell_suppressed = identical(status, "suppressed_small_cell"), interpretation = interpretation, answerability_impact = "Risk-adapted ASCT de-escalation is not answerable until treatment, biology, outcome, and landmark intersections are populated.", notes = "Marginal counts are not converted into intersections.", stringsAsFactors = FALSE)
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_answerability_intersections())
}

mcl_count_intersection_empty_stats <- function() {
  list(executable = 0L, executed = 0L, failed = 0L, populated = 0L)
}

mcl_count_intersection_add_stats <- function(a, b) {
  a <- a %||% mcl_count_intersection_empty_stats()
  b <- b %||% mcl_count_intersection_empty_stats()
  list(
    executable = as.integer((a$executable %||% 0L) + (b$executable %||% 0L)),
    executed = as.integer((a$executed %||% 0L) + (b$executed %||% 0L)),
    failed = as.integer((a$failed %||% 0L) + (b$failed %||% 0L)),
    populated = as.integer((a$populated %||% 0L) + (b$populated %||% 0L))
  )
}

mcl_count_rule_map <- function(defs, project_root, outputs_dir, patient_demographics_resolver, age_source_locator,
                               ibrutinib_source_validation = NULL,
                               treatment_code_mappings = NULL) {
  pdm <- mcl_count_read_person_date_mapping(project_root)
  vm <- mcl_count_read_value_mappings(project_root)
  if (is.null(treatment_code_mappings)) treatment_code_mappings <- mcl_count_read_treatment_code_mappings(project_root)
  rules <- list()
  for (id in unique(defs$data_point_id)) {
    rules[[id]] <- mcl_count_data_point_rule(
      id,
      project_root,
      outputs_dir,
      pdm,
      vm,
      patient_demographics_resolver = patient_demographics_resolver,
      age_source_locator = age_source_locator,
      ibrutinib_source_validation = ibrutinib_source_validation,
      treatment_code_mappings = treatment_code_mappings
    )
  }
  rules
}

mcl_count_named_data_point_cte <- function(rule, name) {
  sub("^data_point\\s+as\\s*\\(", paste0(name, " as ("), rule$data_point_cte %||% "", ignore.case = TRUE, perl = TRUE)
}

mcl_count_denominator_intersection_cte <- function(denominator_id, rules) {
  rule <- rules[[denominator_id]]
  if (!isTRUE(rule$executable)) return(list(executable = FALSE, reason = rule$reason %||% "denominator is not executable"))
  if (identical(denominator_id, "all_lyfo_mcl")) {
    return(list(executable = TRUE, cte = rule$denominator_cte, reason = ""))
  }
  list(executable = TRUE, cte = mcl_count_named_data_point_cte(rule, "denominator"), reason = "")
}

mcl_count_compose_intersection_sql <- function(label, denominator_id, include_ids, exclude_ids, rules) {
  denom <- mcl_count_denominator_intersection_cte(denominator_id, rules)
  if (!isTRUE(denom$executable)) return(list(executable = FALSE, reason = denom$reason %||% "denominator is not executable", sql = ""))
  include_ids <- unique(include_ids[nzchar(include_ids) & include_ids != denominator_id])
  exclude_ids <- unique(exclude_ids[nzchar(exclude_ids) & exclude_ids != denominator_id])
  ids <- unique(c(include_ids, exclude_ids))
  ctes <- list(denom$cte)
  joins <- character()
  wheres <- character()
  for (i in seq_along(ids)) {
    id <- ids[[i]]
    rule <- rules[[id]]
    if (!isTRUE(rule$executable)) {
      return(list(executable = FALSE, reason = paste("Data point is not executable:", id, rule$reason %||% "requires mapping"), sql = ""))
    }
    cte_name <- paste0("dp", i)
    ctes[[length(ctes) + 1L]] <- mcl_count_named_data_point_cte(rule, cte_name)
    if (id %in% include_ids) {
      joins <- c(joins, paste0("join ", cte_name, " using (person_key)"))
    } else {
      joins <- c(joins, paste0("left join ", cte_name, " using (person_key)"))
      wheres <- c(wheres, paste0(cte_name, ".person_key is null"))
    }
  }
  sql <- paste0(
    "with ", paste(ctes, collapse = ",\n"), "\n",
    "select '", gsub("'", "''", label, fixed = TRUE), "' as intersection_id,\n",
    "       count(*) as distinct_person_count\n",
    "from denominator d\n",
    if (length(joins)) paste0(paste(joins, collapse = "\n"), "\n") else "",
    if (length(wheres)) paste0("where ", paste(wheres, collapse = " and "), ";") else ";"
  )
  list(executable = mcl_count_sql_safe(sql), reason = if (mcl_count_sql_safe(sql)) "" else "intersection SQL failed safety checks", sql = sql)
}

mcl_count_execute_intersection_count <- function(db_adapter, sql, min_cell_count = 5L, denominator_n = NA_real_) {
  result <- mcl_count_db_query_result(db_adapter, sql)
  data <- result$data
  n <- if (is.data.frame(data) && nrow(data) && "distinct_person_count" %in% names(data)) {
    suppressWarnings(as.numeric(data$distinct_person_count[[1]]))
  } else {
    NA_real_
  }
  if (is.na(n)) {
    return(list(
      count_status = "production_aggregate_failed_query_error",
      distinct_person_count_display = "",
      percent_of_denominator_display = "",
      small_cell_suppressed = FALSE,
      numeric = NA_real_,
      query_attempted = TRUE,
      query_success = FALSE,
      error_class = result$error_class %||% "production_aggregate_failed_query_error",
      error_message_sanitized = result$error_message_sanitized %||% ""
    ))
  }
  count <- mcl_count_suppress(n, min_cell_count)
  list(
    count_status = mcl_count_production_status(count$status),
    distinct_person_count_display = count$display,
    percent_of_denominator_display = mcl_count_percent_display(n, denominator_n, min_cell_count),
    small_cell_suppressed = isTRUE(count$suppressed),
    numeric = n,
    query_attempted = TRUE,
    query_success = TRUE,
    error_class = "",
    error_message_sanitized = ""
  )
}

mcl_count_denominator_display_n <- function(data_points, denominator_id) {
  row <- mcl_count_data_row(data_points, denominator_id)
  if (!mcl_count_is_available_row(row)) return(NA_real_)
  mcl_count_display_to_number(row$distinct_person_count_display[[1]])
}

mcl_count_unavailable_reason_for_ids <- function(data_points, ids, default = "count_not_available_requires_value_mapping") {
  for (id in ids) {
    row <- mcl_count_data_row(data_points, id)
    if (!mcl_count_is_available_row(row)) {
      if (is.data.frame(row) && nrow(row) && "count_status" %in% names(row)) {
        return(row$count_status[[1]] %||% default)
      }
      return(default)
    }
  }
  default
}

mcl_count_execute_exposure_strata_sql <- function(data_points, rules, db_adapter, min_cell_count = 5L) {
  exposure_rows <- list()
  strategy_rows <- list()
  stats <- mcl_count_intersection_empty_stats()
  cells <- list(
    list(exposure_asct = "ASCT/HDT evidence", exposure_ib = "ibrutinib evidence", strategy_ib = "yes", strategy_asct = "yes", include = c("asct_hdt_first_line", "ibrutinib_exposure"), exclude = character()),
    list(exposure_asct = "ASCT/HDT evidence", exposure_ib = "no ibrutinib evidence", strategy_ib = "unknown_or_no_evidence", strategy_asct = "yes", include = "asct_hdt_first_line", exclude = "ibrutinib_exposure"),
    list(exposure_asct = "no ASCT/HDT evidence", exposure_ib = "ibrutinib evidence", strategy_ib = "yes", strategy_asct = "unknown_or_no_evidence", include = "ibrutinib_exposure", exclude = "asct_hdt_first_line"),
    list(exposure_asct = "no ASCT/HDT evidence", exposure_ib = "no ibrutinib evidence", strategy_ib = "unknown_or_no_evidence", strategy_asct = "unknown_or_no_evidence", include = character(), exclude = c("asct_hdt_first_line", "ibrutinib_exposure"))
  )
  for (denom_id in c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65")) {
    denom_n <- mcl_count_denominator_display_n(data_points, denom_id)
    denom_available <- !is.na(denom_n)
    for (cell in cells) {
      needed <- unique(c(denom_id, "asct_hdt_first_line", "ibrutinib_exposure"))
      status <- if (denom_available) "count_not_available_requires_dedicated_intersection_query" else mcl_count_unavailable_reason_for_ids(data_points, denom_id, mcl_count_patient_demographics_status())
      display <- ""
      pct <- ""
      validation <- "requires_dedicated_intersection_query"
      note <- "Descriptive feasibility stratum only; does not handle timing, eligibility, response, immortal time, or confounding."
      if (denom_available && all(vapply(needed, function(id) isTRUE(rules[[id]]$executable), logical(1)))) {
        spec <- mcl_count_compose_intersection_sql(
          paste(c(denom_id, cell$include, paste0("not_", cell$exclude)), collapse = "__"),
          denom_id,
          cell$include,
          cell$exclude,
          rules
        )
        if (isTRUE(spec$executable)) {
          stats$executable <- stats$executable + 1L
          stats$executed <- stats$executed + 1L
          result <- mcl_count_execute_intersection_count(db_adapter, spec$sql, min_cell_count, denom_n)
          status <- result$count_status
          display <- result$distinct_person_count_display
          pct <- result$percent_of_denominator_display
          validation <- if (isTRUE(result$query_success)) "production_aggregate_intersection_sql" else "production_aggregate_failed_query_error"
          if (!isTRUE(result$query_success)) stats$failed <- stats$failed + 1L
          if (status %in% mcl_count_available_statuses()) stats$populated <- stats$populated + 1L
        } else {
          status <- "count_not_available_requires_dedicated_intersection_query"
          note <- spec$reason
        }
      } else if (denom_available) {
        status <- mcl_count_unavailable_reason_for_ids(data_points, needed)
        note <- "Required marginal predicate is unavailable or non-executable; no stratum was inferred from marginal counts."
      }
      exposure_rows[[length(exposure_rows) + 1L]] <- data.frame(
        denominator = denom_id,
        asct_hdt_first_line_status = cell$exposure_asct,
        ibrutinib_status = cell$exposure_ib,
        timing_scope = "first_line_window",
        count_status = status,
        distinct_person_count_display = display,
        percent_of_denominator_display = pct,
        notes = note,
        stringsAsFactors = FALSE
      )
      strategy_rows[[length(strategy_rows) + 1L]] <- data.frame(
        denominator = denom_id,
        timing_window = "ever_observed",
        ibrutinib_status = cell$strategy_ib,
        asct_hdt_first_line_status = cell$strategy_asct,
        distinct_person_count_display = display,
        percent_of_denominator_display = pct,
        count_status = status,
        validation_status = validation,
        notes = note,
        stringsAsFactors = FALSE
      )
    }
  }
  list(
    exposure_strata_counts = mcl_count_match_empty(bind_rows_base(exposure_rows), mcl_count_empty_exposure_strata_counts()),
    treatment_strategy_strata_counts = mcl_count_match_empty(bind_rows_base(strategy_rows), mcl_count_empty_treatment_strategy_strata_counts()),
    stats = stats
  )
}

mcl_count_execute_overlap_sql <- function(data_points, rules, db_adapter, min_cell_count = 5L) {
  pairs <- data.frame(
    row_data_point_id = c("ibrutinib_exposure", "asct_hdt_first_line", "asct_hdt_first_line", "ki67_aeki", "ki67_aeki", "os_death"),
    column_data_point_id = c("asct_hdt_first_line", "os_death", "relapse_progression_ffs_proxy", "asct_hdt_first_line", "os_death", "relapse_progression_ffs_proxy"),
    stringsAsFactors = FALSE
  )
  denom_id <- "all_lyfo_mcl"
  denom_n <- mcl_count_denominator_display_n(data_points, denom_id)
  rows <- list()
  stats <- mcl_count_intersection_empty_stats()
  for (i in seq_len(nrow(pairs))) {
    ids <- c(pairs$row_data_point_id[[i]], pairs$column_data_point_id[[i]])
    status <- mcl_count_unavailable_reason_for_ids(data_points, c(denom_id, ids), "count_not_available_requires_dedicated_intersection_query")
    display <- ""
    pct <- ""
    note <- "Pairwise overlap requires a dedicated aggregate intersection query; do not infer overlap from marginal counts."
    if (!is.na(denom_n) && all(vapply(c(denom_id, ids), function(id) isTRUE(rules[[id]]$executable), logical(1)))) {
      spec <- mcl_count_compose_intersection_sql(paste(ids, collapse = "__"), denom_id, ids, character(), rules)
      if (isTRUE(spec$executable)) {
        stats$executable <- stats$executable + 1L
        stats$executed <- stats$executed + 1L
        result <- mcl_count_execute_intersection_count(db_adapter, spec$sql, min_cell_count, denom_n)
        status <- result$count_status
        display <- result$distinct_person_count_display
        pct <- result$percent_of_denominator_display
        note <- if (isTRUE(result$query_success)) "Pairwise/domain overlap for feasibility only." else "Aggregate overlap query failed; no row-level data emitted."
        if (!isTRUE(result$query_success)) stats$failed <- stats$failed + 1L
        if (status %in% mcl_count_available_statuses()) stats$populated <- stats$populated + 1L
      } else {
        status <- "count_not_available_requires_dedicated_intersection_query"
        note <- spec$reason
      }
    }
    rows[[length(rows) + 1L]] <- data.frame(
      denominator = denom_id,
      row_data_point_id = pairs$row_data_point_id[[i]],
      column_data_point_id = pairs$column_data_point_id[[i]],
      timing_scope = "ever_available",
      count_status = status,
      distinct_person_count_display = display,
      percent_of_denominator_display = pct,
      notes = note,
      stringsAsFactors = FALSE
    )
  }
  list(overlap_matrix = mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_overlap_matrix()), stats = stats)
}

mcl_count_answerability_specs <- function() {
  data.frame(
    intersection_id = c(
      "age_le_65_mcl",
      "age_le_65_first_line_treatment_date",
      "age_le_65_ibrutinib_exposure_known",
      "age_le_65_first_line_asct_hdt_status_known",
      "age_le_65_ibrutinib_and_asct_status_known",
      "age_le_65_ibrutinib_yes_asct_yes",
      "age_le_65_ibrutinib_yes_asct_no",
      "age_le_65_ibrutinib_yes_asct_known_os_death",
      "age_le_65_ibrutinib_yes_asct_known_relapse_proxy",
      "age_le_65_ibrutinib_yes_asct_known_ki67_known",
      "age_le_65_ibrutinib_yes_asct_known_any_high_risk_known",
      "age_le_65_ibrutinib_yes_asct_known_high_risk_os",
      "age_le_65_ibrutinib_yes_asct_known_standard_risk_os"
    ),
    required_data_points = c(
      "younger_mcl_proxy_age_le_65",
      "younger_mcl_proxy_age_le_65; first_line_treatment_date",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure",
      "younger_mcl_proxy_age_le_65; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line_no_or_unknown",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; os_death",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; relapse_progression_ffs_proxy",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; ki67_aeki",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; high_risk_biology_pre_landmark",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; high_risk_biology_classifiable; os_death",
      "younger_mcl_proxy_age_le_65; ibrutinib_exposure; asct_hdt_first_line; standard_risk_biology_classifiable; os_death"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_count_execute_answerability_sql <- function(data_points, rules, db_adapter, min_cell_count = 5L) {
  specs <- mcl_count_answerability_specs()
  denom_id <- "younger_mcl_proxy_age_le_65"
  denom_n <- mcl_count_denominator_display_n(data_points, denom_id)
  rows <- list()
  stats <- mcl_count_intersection_empty_stats()
  for (i in seq_len(nrow(specs))) {
    intersection_id <- specs$intersection_id[[i]]
    ids <- trimws(strsplit(specs$required_data_points[[i]], ";", fixed = TRUE)[[1]])
    unsupported <- ids[grepl("no_or_unknown|classifiable", ids)]
    status <- mcl_count_unavailable_reason_for_ids(data_points, ids, "count_not_available_requires_value_mapping")
    display <- ""
    suppressed <- FALSE
    interpretation <- "not_countable_yet_mapping_gap"
    impact <- "Risk-adapted ASCT de-escalation is not answerable until treatment, biology, outcome, and landmark intersections are populated."
    note <- "Marginal counts are not converted into intersections."
    if (identical(intersection_id, "age_le_65_mcl") && mcl_count_is_available_row(mcl_count_data_row(data_points, denom_id))) {
      young <- mcl_count_data_row(data_points, denom_id)
      status <- young$count_status[[1]]
      display <- young$distinct_person_count_display[[1]]
      interpretation <- mcl_count_answerability_interpretation(mcl_count_display_to_number(display), status)
      note <- "Younger proxy marginal count; no additional intersection query required."
    } else if (length(unsupported)) {
      status <- "count_not_available_requires_value_mapping"
      impact <- "Risk-adapted de-escalation not answerable; biology/exposure classifiability is incomplete."
      note <- "No validated no/standard-risk classifiability predicate is available."
    } else if (!is.na(denom_n) && all(vapply(ids, function(id) isTRUE(rules[[id]]$executable), logical(1)))) {
      spec <- mcl_count_compose_intersection_sql(intersection_id, denom_id, ids, character(), rules)
      if (isTRUE(spec$executable)) {
        stats$executable <- stats$executable + 1L
        stats$executed <- stats$executed + 1L
        result <- mcl_count_execute_intersection_count(db_adapter, spec$sql, min_cell_count, denom_n)
        status <- result$count_status
        display <- result$distinct_person_count_display
        suppressed <- isTRUE(result$small_cell_suppressed)
        interpretation <- mcl_count_answerability_interpretation(result$numeric, status)
        impact <- if (identical(interpretation, "possibly_sufficient_for_descriptive_analysis")) "May support descriptive feasibility, not causal inference." else "Insufficient or unavailable for modelling the risk-adapted question."
        note <- if (isTRUE(result$query_success)) "Aggregate distinct-person intersection; no row-level data emitted." else "Aggregate answerability query failed; no row-level data emitted."
        if (!isTRUE(result$query_success)) stats$failed <- stats$failed + 1L
        if (status %in% mcl_count_available_statuses()) stats$populated <- stats$populated + 1L
      } else {
        status <- "count_not_available_requires_dedicated_intersection_query"
        note <- spec$reason
      }
    } else if (is.na(denom_n)) {
      status <- mcl_count_unavailable_reason_for_ids(data_points, denom_id, mcl_count_patient_demographics_status())
      note <- "Age-specific answerability intersection is unavailable until the younger proxy denominator is count-available."
    }
    rows[[length(rows) + 1L]] <- data.frame(
      intersection_id = intersection_id,
      denominator = denom_id,
      required_data_points = specs$required_data_points[[i]],
      timing_window = "first_line_window",
      distinct_person_count_display = display,
      count_status = status,
      small_cell_suppressed = suppressed,
      interpretation = interpretation,
      answerability_impact = impact,
      notes = note,
      stringsAsFactors = FALSE
    )
  }
  list(answerability_intersections = mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_answerability_intersections()), stats = stats)
}

mcl_count_apply_production_intersection_sql <- function(count_outputs, defs, project_root, outputs_dir, db_adapter,
                                                        patient_demographics_resolver, age_source_locator,
                                                        ibrutinib_source_validation = NULL,
                                                        treatment_code_mappings = NULL,
                                                        min_cell_count = 5L, generated_at = mcl_count_now()) {
  data_points <- count_outputs$data_point_counts
  rules <- mcl_count_rule_map(defs, project_root, outputs_dir, patient_demographics_resolver, age_source_locator, ibrutinib_source_validation = ibrutinib_source_validation, treatment_code_mappings = treatment_code_mappings)
  stats <- mcl_count_intersection_empty_stats()
  strata <- mcl_count_execute_exposure_strata_sql(data_points, rules, db_adapter, min_cell_count)
  stats <- mcl_count_intersection_add_stats(stats, strata$stats)
  overlap <- mcl_count_execute_overlap_sql(data_points, rules, db_adapter, min_cell_count)
  stats <- mcl_count_intersection_add_stats(stats, overlap$stats)
  answerability <- mcl_count_execute_answerability_sql(data_points, rules, db_adapter, min_cell_count)
  stats <- mcl_count_intersection_add_stats(stats, answerability$stats)
  count_outputs$exposure_strata_counts <- mcl_count_add_provenance(strata$exposure_strata_counts, "production_aggregate", generated_at, validation_status = "production_aggregate_intersection_sql")
  count_outputs$treatment_strategy_strata_counts <- mcl_count_add_provenance(strata$treatment_strategy_strata_counts, "production_aggregate", generated_at, validation_status = "production_aggregate_intersection_sql")
  count_outputs$overlap_matrix <- mcl_count_add_provenance(overlap$overlap_matrix, "production_aggregate", generated_at, validation_status = "production_aggregate_intersection_sql")
  count_outputs$answerability_intersections <- mcl_count_add_provenance(answerability$answerability_intersections, "production_aggregate", generated_at, validation_status = "production_aggregate_answerability_sql")
  count_outputs$answerability_summary <- mcl_count_answerability_summary_from_outputs(
    data_points,
    count_outputs$answerability_intersections,
    count_outputs$high_risk_biology_counts,
    count_outputs$treatment_strategy_strata_counts,
    count_outputs$landmark_feasibility_counts,
    min_cell_count = min_cell_count
  )
  count_outputs$answerability_summary <- mcl_count_add_provenance(count_outputs$answerability_summary, "production_aggregate", generated_at, validation_status = "answerability_summary")
  count_outputs$count_summary <- mcl_count_summary_from_outputs(data_points, count_outputs$inclusion_waterfall, count_outputs$overlap_matrix, count_outputs$exposure_strata_counts)
  count_outputs$count_summary <- mcl_count_add_provenance(count_outputs$count_summary, "production_aggregate", generated_at, validation_status = "summary_from_data_point_counts")
  list(outputs = count_outputs, stats = stats)
}

mcl_count_answerability_summary_from_outputs <- function(data_points, intersections, high_risk, strata, landmark, min_cell_count = 5L) {
  metric_row <- function(row_id, status, count = "", factor = "", interpretation = "", next_step = "", notes = "") {
    data.frame(row_id = row_id, status = status, distinct_person_count_display = count, limiting_factor = factor, interpretation = interpretation, recommended_next_step = next_step, notes = notes, stringsAsFactors = FALSE)
  }
  has_available <- function(id) mcl_count_is_available_row(mcl_count_data_row(data_points, id))
  answerable_cells <- is.data.frame(intersections) && nrow(intersections) &&
    any(intersections$intersection_id == "age_le_65_ibrutinib_yes_asct_known_standard_risk_os" &
          intersections$interpretation == "possibly_sufficient_for_descriptive_analysis", na.rm = TRUE) &&
    any(intersections$intersection_id == "age_le_65_ibrutinib_yes_asct_known_high_risk_os" &
          intersections$interpretation == "possibly_sufficient_for_descriptive_analysis", na.rm = TRUE)
  landmark_ready <- is.data.frame(landmark) && nrow(landmark) &&
    any(
      landmark$count_status %in% mcl_count_available_statuses() &
        grepl("landmark_compatible|dedicated_landmark|date_window_intersection", landmark$validation_status %||% "", ignore.case = TRUE),
      na.rm = TRUE
    )
  rows <- list(
    metric_row("base_mcl_cohort", if (has_available("all_lyfo_mcl")) "ready_for_feasibility_report" else "not_countable_yet_mapping_gap", mcl_count_data_row(data_points, "all_lyfo_mcl")$distinct_person_count_display[[1]] %||% "", "", "Base MCL denominator availability.", "Keep validating denominator semantics."),
    metric_row("younger_proxy_available", if (has_available("younger_mcl_proxy_age_le_65")) "ready_for_feasibility_report" else "not_countable_yet_timing_gap", mcl_count_data_row(data_points, "younger_mcl_proxy_age_le_65")$distinct_person_count_display[[1]] %||% "", "age/date anchor", "Younger proxy availability, not transplant eligibility.", "Fix age-anchor production query if unavailable."),
    metric_row("ibrutinib_exposure_available", if (has_available("ibrutinib_exposure")) "possibly_ready_for_descriptive_outcomes_study" else "not_ready_for_risk_adapted_deescalation_answer", mcl_count_data_row(data_points, "ibrutinib_exposure")$distinct_person_count_display[[1]] %||% "", "ibrutinib value mapping", "Ibrutinib exposure must be validated before treatment-strategy strata.", "Validate medication/code predicates."),
    metric_row("first_line_asct_hdt_available", if (has_available("asct_hdt_first_line")) "ready_for_feasibility_report" else "not_countable_yet_mapping_gap", mcl_count_data_row(data_points, "asct_hdt_first_line")$distinct_person_count_display[[1]] %||% "", "", "First-line ASCT/HDT availability.", "Keep Rec_* separate from first-line Beh_* evidence."),
    metric_row("treatment_strategy_strata_available", if (any(strata$count_status %in% mcl_count_available_statuses(), na.rm = TRUE)) "ready_for_descriptive_treatment_pattern_study" else "not_ready_for_risk_adapted_deescalation_answer", "", "Ibrutinib x ASCT/HDT intersections", "Treatment-strategy strata are descriptive only.", "Run aggregate intersection queries after Ibrutinib mapping is validated."),
    metric_row("high_risk_biology_available", if (any(high_risk$count_status %in% mcl_count_available_statuses(), na.rm = TRUE)) "possibly_ready_for_descriptive_outcomes_study" else "not_ready_for_risk_adapted_deescalation_answer", "", "biology component mappings", "High-risk biology classifiability is incomplete until components are validated.", "Validate TP53, morphology, Ki-67 threshold, and MIPI-c component rules."),
    metric_row("ki67_available", if (has_available("ki67_aeki")) "ready_for_feasibility_report" else "not_countable_yet_mapping_gap", mcl_count_data_row(data_points, "ki67_aeki")$distinct_person_count_display[[1]] %||% "", "", "Ki-67 AEKI availability.", "Validate source-specific clinical semantics and timing."),
    metric_row("outcome_available", if (has_available("os_death")) "ready_for_feasibility_report" else "not_countable_yet_mapping_gap", mcl_count_data_row(data_points, "os_death")$distinct_person_count_display[[1]] %||% "", "", "Outcome availability.", "Validate outcome timing for landmark designs."),
    metric_row("landmark_design_available", if (landmark_ready) "possibly_ready_for_descriptive_outcomes_study" else "not_ready_for_risk_adapted_deescalation_answer", "", "landmark-compatible intersections", "Landmark design is unavailable until date-window intersections are populated.", "Implement landmark-specific aggregate SQL."),
    metric_row("overall_answerability", if (answerable_cells) "possibly_ready_for_descriptive_outcomes_study" else "not_ready_for_risk_adapted_deescalation_answer", "", "Ibrutinib x ASCT/HDT, high-risk biology, outcomes, and landmark intersections", "Current counts support feasibility reporting but do not answer risk-adapted ASCT de-escalation.", "Populate treatment-strategy, biology, outcome, and landmark intersections with non-suppressed cells >=20.")
  )
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_answerability_summary())
}

mcl_count_outputs_from_data_points <- function(data_points, min_cell_count = 5L, generated_at = mcl_count_now()) {
  availability <- mcl_count_availability_waterfall_from_data_points(data_points)
  availability <- mcl_count_add_provenance(availability, "production_aggregate", generated_at, validation_status = "availability_counts_not_cumulative_waterfall")
  overlaps <- mcl_count_overlap_status_rows(data_points)
  overlaps <- mcl_count_add_provenance(overlaps, "production_aggregate", generated_at, validation_status = "requires_dedicated_intersection_queries")
  strata <- mcl_count_exposure_strata_status_rows(data_points)
  strata <- mcl_count_add_provenance(strata, "production_aggregate", generated_at, validation_status = "requires_dedicated_intersection_queries")
  landmark <- mcl_count_landmark_status_rows(data_points)
  landmark <- mcl_count_add_provenance(landmark, "production_aggregate", generated_at, validation_status = "dedicated_landmark_aggregate_sql_or_unavailable")
  ki67 <- mcl_count_ki67_summary_from_data_points(data_points)
  ki67 <- mcl_count_add_provenance(ki67, "production_aggregate", generated_at, validation_status = "ki67_from_distinct_person_aeki_count")
  age_proxy <- mcl_count_age_proxy_from_data_points(data_points)
  age_proxy <- mcl_count_add_provenance(age_proxy, "production_aggregate", generated_at, validation_status = "age_proxy_diagnostics")
  ibrutinib_counts <- mcl_count_ibrutinib_counts_from_data_points(data_points)
  ibrutinib_counts <- mcl_count_add_provenance(ibrutinib_counts, "production_aggregate", generated_at, validation_status = "ibrutinib_mapping_or_count_status")
  strategy <- mcl_count_treatment_strategy_from_data_points(data_points)
  strategy <- mcl_count_add_provenance(strategy, "production_aggregate", generated_at, validation_status = "requires_dedicated_intersection_queries")
  high_risk <- mcl_count_high_risk_from_data_points(data_points)
  high_risk <- mcl_count_add_provenance(high_risk, "production_aggregate", generated_at, validation_status = "high_risk_component_status")
  answerability <- mcl_count_answerability_rows_from_data_points(data_points)
  answerability <- mcl_count_add_provenance(answerability, "production_aggregate", generated_at, validation_status = "requires_dedicated_answerability_intersections")
  answerability_summary <- mcl_count_answerability_summary_from_outputs(data_points, answerability, high_risk, strategy, landmark, min_cell_count = min_cell_count)
  answerability_summary <- mcl_count_add_provenance(answerability_summary, "production_aggregate", generated_at, validation_status = "answerability_summary")
  summary <- mcl_count_summary_from_outputs(data_points, availability, overlaps, strata)
  summary <- mcl_count_add_provenance(summary, "production_aggregate", generated_at, validation_status = "summary_from_data_point_counts")
  list(
    data_point_counts = data_points,
    inclusion_waterfall = availability,
    overlap_matrix = overlaps,
    exposure_strata_counts = strata,
    landmark_feasibility_counts = landmark,
    ki67_person_count_summary = ki67,
    age_proxy_counts = age_proxy,
    ibrutinib_exposure_counts = ibrutinib_counts,
    treatment_strategy_strata_counts = strategy,
    high_risk_biology_counts = high_risk,
    answerability_intersections = answerability,
    answerability_summary = answerability_summary,
    count_summary = summary
  )
}

mcl_count_failed_query_audit <- function(data_points = mcl_count_empty_data_point_counts(),
                                         age_source_validation = mcl_count_empty_age_source_validation(),
                                         ibrutinib_source_validation = mcl_count_empty_ibrutinib_source_validation(),
                                         ki67_outputs = list()) {
  rows <- list()
  add_one <- function(component, output_file, query_id, output_area = "", count_status = "",
                      validation_status = "", query_attempted = FALSE, query_success = FALSE,
                      error_message_sanitized = "", notes = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      component = component,
      output_file = output_file,
      query_id = query_id,
      output_area = output_area,
      count_status = count_status,
      validation_status = validation_status,
      query_attempted = isTRUE(query_attempted),
      query_success = isTRUE(query_success),
      error_message_sanitized = error_message_sanitized %||% "",
      notes = notes %||% "",
      stringsAsFactors = FALSE
    )
  }
  if (is.data.frame(data_points) && nrow(data_points)) {
    hit <- mcl_count_bool(data_points$query_attempted %||% FALSE) & !mcl_count_bool(data_points$query_success %||% FALSE)
    for (i in which(hit)) {
      add_one("data_point_counts", "mcl_triangle_data_point_counts.csv", data_points$data_point_id[[i]] %||% "",
              data_points$denominator[[i]] %||% "", data_points$count_status[[i]] %||% "",
              data_points$validation_status[[i]] %||% "", data_points$query_attempted[[i]] %in% TRUE,
              data_points$query_success[[i]] %in% TRUE, data_points$error_message_sanitized[[i]] %||% "",
              data_points$notes[[i]] %||% "")
    }
  }
  if (is.data.frame(age_source_validation) && nrow(age_source_validation)) {
    hit <- mcl_count_bool(age_source_validation$query_attempted %||% FALSE) & !mcl_count_bool(age_source_validation$query_success %||% FALSE)
    for (i in which(hit)) {
      add_one("age_validation", "mcl_triangle_age_source_validation.csv", age_source_validation$validation_id[[i]] %||% "",
              age_source_validation$source_type[[i]] %||% "", "", age_source_validation$validation_status[[i]] %||% "",
              age_source_validation$query_attempted[[i]] %in% TRUE, age_source_validation$query_success[[i]] %in% TRUE,
              age_source_validation$error_message_sanitized[[i]] %||% "", age_source_validation$notes[[i]] %||% "")
    }
  }
  if (is.data.frame(ibrutinib_source_validation) && nrow(ibrutinib_source_validation)) {
    ib_error <- nzchar(as.character(ibrutinib_source_validation$error_message_sanitized %||% "")) |
      nzchar(as.character(ibrutinib_source_validation$co_residency_probe_error_sanitized %||% "")) |
      nzchar(as.character(ibrutinib_source_validation$bridge_probe_error_sanitized %||% ""))
    hit <- (mcl_count_bool(ibrutinib_source_validation$validation_query_attempted %||% FALSE) &
              !mcl_count_bool(ibrutinib_source_validation$validation_query_success %||% FALSE)) | ib_error
    for (i in which(hit)) {
      err <- ibrutinib_source_validation$error_message_sanitized[[i]] %||% ""
      if (!nzchar(err)) err <- ibrutinib_source_validation$co_residency_probe_error_sanitized[[i]] %||% ""
      if (!nzchar(err)) err <- ibrutinib_source_validation$bridge_probe_error_sanitized[[i]] %||% ""
      add_one("ibrutinib_validation", "mcl_triangle_ibrutinib_source_validation.csv", ibrutinib_source_validation$source_id[[i]] %||% "",
              ibrutinib_source_validation$source_role[[i]] %||% "", "", ibrutinib_source_validation$validation_status[[i]] %||% "",
              ibrutinib_source_validation$validation_query_attempted[[i]] %in% TRUE,
              ibrutinib_source_validation$validation_query_success[[i]] %in% TRUE, err,
              ibrutinib_source_validation$notes[[i]] %||% "")
    }
  }
  bridge <- ki67_outputs$ki67_text_bridge_validation %||% mcl_count_empty_ki67_text_bridge_validation()
  if (is.data.frame(bridge) && nrow(bridge)) {
    hit <- mcl_count_bool(bridge$query_attempted %||% FALSE) & !mcl_count_bool(bridge$query_success %||% FALSE)
    for (i in which(hit)) {
      add_one("ki67_text_bridge", "mcl_triangle_ki67_text_bridge_validation.csv", bridge$text_source[[i]] %||% "",
              bridge$table_or_view[[i]] %||% "", "", bridge$validation_status[[i]] %||% "",
              bridge$query_attempted[[i]] %in% TRUE, bridge$query_success[[i]] %in% TRUE,
              bridge$error_message_sanitized[[i]] %||% "", bridge$notes[[i]] %||% "")
    }
  }
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_failed_query_audit())
}

mcl_count_acceptance_flags <- function(mode, data_points, age_source_validation, ibrutinib_source_validation,
                                       ki67_outputs, atlas_input_audit, atlas_age_source_inventory,
                                       atlas_treatment_source_inventory, atlas_ki67_source_inventory,
                                       query_templates = "", value_mappings = data.frame(stringsAsFactors = FALSE),
                                       failed_query_audit = mcl_count_empty_failed_query_audit()) {
  all_mcl <- mcl_count_data_row(data_points, "all_lyfo_mcl")
  age <- mcl_count_data_row(data_points, "younger_mcl_proxy_age_le_65")
  ib <- mcl_count_data_row(data_points, "ibrutinib_exposure")
  ki <- mcl_count_data_row(data_points, "ki67_aeki")
  core_ok <- mcl_count_is_available_row(all_mcl)
  age_ok <- mcl_count_is_available_row(age) &&
    is.data.frame(age_source_validation) &&
    any(age_source_validation$selected_for_age_counts %in% TRUE & age_source_validation$query_success %in% TRUE, na.rm = TRUE)
  ib_errors <- paste(as.character(ibrutinib_source_validation$error_message_sanitized %||% ""), collapse = "\n")
  ib_generated_sql_bug <- grepl("relation \"m\"|left join m on", ib_errors, ignore.case = TRUE, perl = TRUE)
  ib_ok <- mcl_count_is_available_row(ib) && !ib_generated_sql_bug &&
    (!is.data.frame(ibrutinib_source_validation) || !nrow(ibrutinib_source_validation) ||
       any(ibrutinib_source_validation$selected_for_union %in% TRUE | ibrutinib_source_validation$validation_query_success %in% TRUE, na.rm = TRUE))
  ki_summary <- ki67_outputs$ki67_person_count_summary %||% mcl_count_empty_ki67_person_summary()
  ki_special <- if (is.data.frame(ki_summary) && nrow(ki_summary)) mcl_count_display_to_number(ki_summary$distinct_person_count_display[[1]]) else NA_real_
  ki_main <- if (mcl_count_is_available_row(ki)) mcl_count_display_to_number(ki$distinct_person_count_display[[1]]) else NA_real_
  ki_ok <- !is.na(ki_main) && !is.na(ki_special) && identical(as.numeric(ki_main), as.numeric(ki_special))
  atlas_supplied <- mcl_count_atlas_input_was_supplied(atlas_input_audit)
  atlas_ok <- if (atlas_supplied) {
    is.data.frame(atlas_age_source_inventory) && nrow(atlas_age_source_inventory) > 0L &&
      is.data.frame(atlas_treatment_source_inventory) && nrow(atlas_treatment_source_inventory) > 0L &&
      is.data.frame(atlas_ki67_source_inventory) && nrow(atlas_ki67_source_inventory) > 0L
  } else {
    is.data.frame(atlas_input_audit) && nrow(atlas_input_audit) &&
      identical(as.character(atlas_input_audit$selection_reason[[1]] %||% ""), "atlas_input_not_supplied")
  }
  sql <- as.character(query_templates %||% "")
  bad_sql <- grepl("left join m on|text_rows[.]text_value|select[[:space:]]+[*]|[[:space:]]limit[[:space:]]+[0-9]+|join[[:space:]]+(\"public\"[.]\"patient\"|public[.]patient)", sql, ignore.case = TRUE, perl = TRUE)
  cit_has_ib <- is.data.frame(value_mappings) && nrow(value_mappings) &&
    any(as.character(value_mappings$data_point_id %||% "") == "cit_immunochemotherapy" &
          grepl("(^|;)ibrutinib(;|$)", as.character(value_mappings$mapped_values %||% ""), ignore.case = TRUE, perl = TRUE), na.rm = TRUE)
  failed_errors <- paste(as.character(failed_query_audit$error_message_sanitized %||% ""), collapse = "\n")
  generated_error <- grepl("relation \"m\"|text_rows[.]text_value", failed_errors, ignore.case = TRUE, perl = TRUE)
  fatal <- c()
  if (!core_ok) fatal <- c(fatal, "core_marginal_counts_unavailable")
  if (identical(mode, "production_aggregate") && !age_ok) fatal <- c(fatal, "age_validation_or_count_mismatch")
  if (identical(mode, "production_aggregate") && !ib_ok) fatal <- c(fatal, "ibrutinib_validation_not_clean")
  if (identical(mode, "production_aggregate") && !ki_ok) fatal <- c(fatal, "ki67_main_and_specialized_counts_disagree")
  if (!atlas_ok) fatal <- c(fatal, "atlas_ingestion_not_audited_or_empty")
  if (bad_sql) fatal <- c(fatal, "unsafe_or_stale_generated_sql")
  if (cit_has_ib) fatal <- c(fatal, "cit_mapping_contains_ibrutinib")
  if (generated_error) fatal <- c(fatal, "failed_query_audit_contains_generated_sql_bug")
  status <- if (length(fatal)) {
    "failed_acceptance"
  } else if (!atlas_supplied) {
    "accepted_no_atlas_input"
  } else {
    "accepted"
  }
  list(
    core_marginal_counts_succeeded = core_ok,
    age_validation_succeeded = age_ok,
    ibrutinib_validation_succeeded = ib_ok,
    ki67_validation_succeeded = ki_ok,
    atlas_ingestion_succeeded = atlas_ok,
    acceptance_status = status,
    failure_reason = paste(fatal, collapse = "; ")
  )
}

mcl_count_execution_summary <- function(mode, plan, db_attempted = FALSE, db_available = FALSE,
                                        data_points = mcl_count_empty_data_point_counts(),
                                        count_outputs = NULL,
                                        intersection_stats = mcl_count_intersection_empty_stats(),
                                        atlas_age_source_inventory = mcl_count_empty_atlas_age_source_inventory(),
                                        age_source_validation = mcl_count_empty_age_source_validation(),
                                        atlas_treatment_source_inventory = mcl_count_empty_atlas_treatment_source_inventory(),
                                        ibrutinib_source_validation = mcl_count_empty_ibrutinib_source_validation(),
                                        atlas_ki67_source_inventory = mcl_count_empty_atlas_ki67_source_inventory(),
                                        ki67_source_validation = mcl_count_empty_ki67_source_validation(),
                                        ki67_stats = list(attempted = 0L, failed = 0L),
                                        atlas_input_audit = mcl_count_empty_atlas_input_audit(),
                                        failed_query_audit = mcl_count_empty_failed_query_audit(),
                                        query_templates = "",
                                        value_mappings = data.frame(stringsAsFactors = FALSE),
                                        failure_reason = "") {
  executable <- if (is.data.frame(plan$review) && nrow(plan$review)) {
    sum(isTRUE(plan$review$query_executable) | plan$review$query_executable == TRUE, na.rm = TRUE)
  } else {
    0L
  }
  executed <- if (is.data.frame(data_points) && nrow(data_points)) {
    sum(data_points$query_executed %in% TRUE, na.rm = TRUE)
  } else {
    0L
  }
  failed <- if (is.data.frame(data_points) && nrow(data_points)) {
    sum(data_points$query_attempted %in% TRUE & !(data_points$query_success %in% TRUE), na.rm = TRUE)
  } else {
    0L
  }
  populated <- if (is.data.frame(data_points) && nrow(data_points)) {
    sum(data_points$count_status %in% c("production_aggregate_count_available", "count_available", "count_available_timing_not_validated", "suppressed_small_cell"), na.rm = TRUE)
  } else {
    0L
  }
  intersection_executable <- suppressWarnings(as.integer(intersection_stats$executable %||% 0L))
  intersection_executed <- suppressWarnings(as.integer(intersection_stats$executed %||% 0L))
  intersection_failed <- suppressWarnings(as.integer(intersection_stats$failed %||% 0L))
  intersection_populated <- suppressWarnings(as.integer(intersection_stats$populated %||% 0L))
  if (is.na(intersection_executable)) intersection_executable <- 0L
  if (is.na(intersection_executed)) intersection_executed <- 0L
  if (is.na(intersection_failed)) intersection_failed <- 0L
  if (is.na(intersection_populated)) intersection_populated <- 0L
  if (intersection_populated <= 0L && is.list(count_outputs)) {
    populated_status <- function(df) {
      if (!is.data.frame(df) || !nrow(df) || !"count_status" %in% names(df)) return(0L)
      sum(df$count_status %in% mcl_count_available_statuses(), na.rm = TRUE)
    }
    intersection_populated <- populated_status(count_outputs$overlap_matrix) +
      populated_status(count_outputs$exposure_strata_counts) +
      populated_status(count_outputs$treatment_strategy_strata_counts) +
      populated_status(count_outputs$answerability_intersections)
  }
  ki67_rows <- if (is.data.frame(atlas_ki67_source_inventory)) nrow(atlas_ki67_source_inventory) else 0L
  ki67_validation_attempted <- if (is.data.frame(ki67_source_validation) && nrow(ki67_source_validation)) {
    sum(ki67_source_validation$validation_query_attempted %in% TRUE, na.rm = TRUE)
  } else {
    0L
  }
  ki67_validation_failed <- if (is.data.frame(ki67_source_validation) && nrow(ki67_source_validation)) {
    sum(ki67_source_validation$validation_query_attempted %in% TRUE & !(ki67_source_validation$validation_query_success %in% TRUE), na.rm = TRUE)
  } else {
    0L
  }
  ki67_attempted_extra <- suppressWarnings(as.integer(ki67_stats$attempted %||% 0L))
  ki67_failed_extra <- suppressWarnings(as.integer(ki67_stats$failed %||% 0L))
  if (is.na(ki67_attempted_extra)) ki67_attempted_extra <- 0L
  if (is.na(ki67_failed_extra)) ki67_failed_extra <- 0L
  ki67_validation_attempted <- max(ki67_validation_attempted, ki67_attempted_extra)
  ki67_validation_failed <- max(ki67_validation_failed, ki67_failed_extra)
  atlas_rows <- if (is.data.frame(atlas_age_source_inventory)) nrow(atlas_age_source_inventory) else 0L
  validation_attempted <- if (is.data.frame(age_source_validation) && nrow(age_source_validation)) {
    sum(age_source_validation$query_attempted %in% TRUE, na.rm = TRUE)
  } else {
    0L
  }
  validation_failed <- if (is.data.frame(age_source_validation) && nrow(age_source_validation)) {
    sum(age_source_validation$query_attempted %in% TRUE & !(age_source_validation$query_success %in% TRUE), na.rm = TRUE)
  } else {
    0L
  }
  treatment_rows <- if (is.data.frame(atlas_treatment_source_inventory)) nrow(atlas_treatment_source_inventory) else 0L
  ib_validation_attempted <- if (is.data.frame(ibrutinib_source_validation) && nrow(ibrutinib_source_validation)) {
    sum(ibrutinib_source_validation$validation_query_attempted %in% TRUE, na.rm = TRUE)
  } else {
    0L
  }
  ib_validation_failed <- if (is.data.frame(ibrutinib_source_validation) && nrow(ibrutinib_source_validation)) {
    sum(ibrutinib_source_validation$validation_query_attempted %in% TRUE & !(ibrutinib_source_validation$validation_query_success %in% TRUE), na.rm = TRUE)
  } else {
    0L
  }
  flags <- mcl_count_acceptance_flags(
    mode = mode,
    data_points = data_points,
    age_source_validation = age_source_validation,
    ibrutinib_source_validation = ibrutinib_source_validation,
    ki67_outputs = count_outputs %||% list(),
    atlas_input_audit = atlas_input_audit,
    atlas_age_source_inventory = atlas_age_source_inventory,
    atlas_treatment_source_inventory = atlas_treatment_source_inventory,
    atlas_ki67_source_inventory = atlas_ki67_source_inventory,
    query_templates = query_templates,
    value_mappings = value_mappings,
    failed_query_audit = failed_query_audit
  )
  combined_failure_reason <- failure_reason %||% ""
  if (!nzchar(combined_failure_reason) && nzchar(flags$failure_reason %||% "")) {
    combined_failure_reason <- flags$failure_reason
  }
  data.frame(
    mode = mode,
    db_connection_attempted = isTRUE(db_attempted),
    db_connection_available = isTRUE(db_available),
    executable_queries = as.integer(executable + intersection_executable + validation_attempted + ib_validation_attempted + ki67_validation_attempted),
    executed_queries = as.integer(executed + intersection_executed + validation_attempted + ib_validation_attempted + ki67_validation_attempted),
    failed_queries = as.integer(failed + intersection_failed + validation_failed + ib_validation_failed + ki67_validation_failed),
    populated_count_outputs = as.integer(populated),
    populated_intersection_outputs = as.integer(intersection_populated),
    atlas_age_inventory_rows = as.integer(atlas_rows),
    age_validation_queries = as.integer(validation_attempted),
    atlas_treatment_inventory_rows = as.integer(treatment_rows),
    ibrutinib_validation_queries = as.integer(ib_validation_attempted),
    atlas_ki67_inventory_rows = as.integer(ki67_rows),
    ki67_validation_queries = as.integer(ki67_validation_attempted),
    production_aggregate_succeeded = identical(mode, "production_aggregate") && (populated > 0L || intersection_populated > 0L),
    core_marginal_counts_succeeded = isTRUE(flags$core_marginal_counts_succeeded),
    age_validation_succeeded = isTRUE(flags$age_validation_succeeded),
    ibrutinib_validation_succeeded = isTRUE(flags$ibrutinib_validation_succeeded),
    ki67_validation_succeeded = isTRUE(flags$ki67_validation_succeeded),
    atlas_ingestion_succeeded = isTRUE(flags$atlas_ingestion_succeeded),
    acceptance_status = flags$acceptance_status %||% "",
    failure_reason = combined_failure_reason,
    stringsAsFactors = FALSE
  )
}

mcl_count_latest_mapping_change <- function(project_root = ".") {
  candidates <- c(
    file.path(project_root, "R", "mcl_triangle_counts.R"),
    file.path(project_root, "config", "mcl_triangle_person_date_mapping.tsv"),
    file.path(project_root, "config", "mcl_triangle_count_value_mappings.tsv"),
    file.path(project_root, "config", "mcl_triangle_treatment_code_mappings.tsv"),
    file.path(project_root, "clinical_questions", "mcl_triangle_count_definitions.yml"),
    file.path(project_root, "clinical_questions", "mcl_triangle_high_risk_biology_definitions.yml"),
    file.path(project_root, "clinical_questions", "ki67_extraction_spec.yml")
  )
  existing <- candidates[file.exists(candidates)]
  if (!length(existing)) return(Sys.time())
  max(file.info(existing)$mtime, na.rm = TRUE)
}

mcl_count_output_generation_status <- function(output_dir, paths, mode, latest_mapping_change,
                                               patient_demographics_resolver = mcl_count_empty_patient_demographics_resolver(),
                                               age_source_locator = mcl_count_empty_age_source_locator()) {
  selected <- mcl_count_selected_patient_resolver(patient_demographics_resolver)
  selected_age_source <- mcl_count_selected_age_source_locator(age_source_locator)
  path_values <- unique(as.character(unlist(paths, use.names = FALSE)))
  path_values <- path_values[nzchar(path_values)]
  rows <- lapply(path_values, function(path) {
    rel <- basename(path)
    exists <- file.exists(path)
    fresh_time <- exists && isTRUE(file.info(path)$mtime >= latest_mapping_change)
    text <- if (exists && grepl("\\.(csv|sql|js)$", path, ignore.case = TRUE)) {
      paste(readLines(path, warn = FALSE), collapse = "\n")
    } else {
      ""
    }

    executable_invalidated_relation <- identical(rel, "mcl_triangle_count_query_templates.sql") &&
      (
        mcl_count_query_templates_have_executable_invalidated_patient_join(text, patient_demographics_resolver) ||
          mcl_count_query_templates_have_executable_invalidated_age_source(text, age_source_locator)
      )
    unverified_template_relation <- identical(rel, "mcl_triangle_count_query_templates.sql") &&
      mcl_count_query_templates_have_unverified_patient_join(text, selected, selected_age_source)
    stale_failure_raw <- mcl_count_has_relation_failure_text(text)
    coherent_post_selection_diagnostic <- stale_failure_raw &&
      mcl_count_output_relation_failure_is_coherent(path, rel)
    stale_failure <- stale_failure_raw && !coherent_post_selection_diagnostic
    verified_relation <- !executable_invalidated_relation && !unverified_template_relation
    fresh <- fresh_time && verified_relation && !stale_failure

    data.frame(
      output_file = rel,
      generated_after_latest_mapping_change = fresh_time,
      mode = mode,
      stale = !fresh,
      notes = if (!exists) {
        "missing"
      } else if (!fresh_time) {
        "older than latest resolver/count mapping change"
      } else if (executable_invalidated_relation) {
        "contains executable SQL joining an invalidated patient-demographics relation"
      } else if (unverified_template_relation) {
        "contains executable patient-demographics SQL relation not selected by resolver"
      } else if (stale_failure) {
        "contains stale patient-demographics relation failure text from an earlier mapping attempt"
      } else {
        "fresh after resolver change"
      },
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_count_empty_output_generation_status())
}

mcl_count_build_outputs <- function(project_root = ".",
                                    outputs_dir = file.path(project_root, "outputs"),
                                    mode = c("plan", "production_aggregate"),
                                    db_adapter = NULL,
                                    min_cell_count = 5L,
                                    update_payload = FALSE,
                                    atlas_output_dir = Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = ""),
                                    atlas_output_zip = Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = ""),
                                    multiple_birth_date_tolerance = 0L,
                                    run_ki67_source_inventory = TRUE,
                                    ki67_text_scan = mcl_count_bool(Sys.getenv("MCL_TRIANGLE_KI67_TEXT_SCAN", unset = "false")),
                                    ki67_threshold_percent = NULL) {
  mode <- match.arg(mode)
  generated_at <- mcl_count_now()
  defs <- mcl_count_read_definitions(project_root)
  pdm <- mcl_count_read_person_date_mapping(project_root)
  ki67_threshold_percent <- mcl_count_ki67_threshold_percent(project_root, ki67_threshold_percent)
  treatment_code_mappings <- mcl_count_read_treatment_code_mappings(project_root)
  atlas_input_audit <- mcl_count_atlas_input_audit(
    atlas_output_dir = atlas_output_dir,
    atlas_output_zip = atlas_output_zip
  )
  atlas_age_source_inventory <- mcl_count_read_atlas_age_inventory(
    atlas_output_dir = atlas_output_dir,
    atlas_output_zip = atlas_output_zip
  )
  atlas_treatment_source_inventory <- mcl_count_read_atlas_treatment_inventory(
    atlas_output_dir = atlas_output_dir,
    atlas_output_zip = atlas_output_zip
  )
  atlas_ki67_source_inventory <- if (isTRUE(run_ki67_source_inventory)) {
    mcl_count_read_atlas_ki67_inventory(
      atlas_output_dir = atlas_output_dir,
      atlas_output_zip = atlas_output_zip
    )
  } else {
    mcl_count_empty_atlas_ki67_source_inventory()
  }
  ki67_outputs <- mcl_count_ki67_plan_outputs(
    atlas_ki67_source_inventory,
    threshold_percent = ki67_threshold_percent,
    text_scan = ki67_text_scan
  )
  count_sets <- NULL
  ki67_percent_counts <- NULL
  intersection_stats <- mcl_count_intersection_empty_stats()
  db_attempted <- identical(mode, "production_aggregate")
  db_available <- FALSE
  failure_reason <- ""
  if (identical(mode, "production_aggregate")) {
    if (is.null(db_adapter) && exists("dalycare_db_adapter", mode = "function")) {
      db_adapter <- tryCatch(dalycare_db_adapter(), error = function(e) NULL)
    }
    db_available <- mcl_count_db_adapter_available(db_adapter)
    if (!is.null(db_adapter) && is.function(db_adapter$mcl_triangle_count_sets)) {
      hook <- tryCatch(db_adapter$mcl_triangle_count_sets(min_cell_count = min_cell_count), error = function(e) NULL)
      if (is.list(hook)) {
        count_sets <- hook$sets %||% hook
        ki67_percent_counts <- hook$ki67_percent_counts %||% NULL
      }
    }
    if (!db_available) {
      failure_reason <- "production_aggregate_failed_credentials_unavailable"
    }
  }
  patient_demographics_resolver <- mcl_count_resolve_patient_demographics(
    project_root = project_root,
    outputs_dir = outputs_dir,
    db_adapter = if (db_available) db_adapter else NULL,
    person_date_mapping = pdm,
    mode = mode,
    generated_at = generated_at,
    atlas_age_source_inventory = atlas_age_source_inventory
  )
  age_source_locator <- mcl_count_resolve_age_source(
    project_root = project_root,
    outputs_dir = outputs_dir,
    db_adapter = if (db_available) db_adapter else NULL,
    person_date_mapping = pdm,
    patient_demographics_resolver = patient_demographics_resolver,
    mode = mode,
    generated_at = generated_at,
    atlas_age_source_inventory = atlas_age_source_inventory
  )
  age_source_validation <- if (identical(mode, "production_aggregate") && db_available) {
    mcl_count_validate_age_source_candidates(
      age_source_locator,
      pdm,
      db_adapter,
      multiple_birth_date_tolerance = multiple_birth_date_tolerance
    )
  } else {
    mcl_count_empty_age_source_validation()
  }
  age_source_locator <- mcl_count_apply_age_source_validation(age_source_locator, age_source_validation)
  ibrutinib_source_validation <- if (identical(mode, "production_aggregate") && db_available) {
    mcl_count_validate_ibrutinib_sources(
      treatment_code_mappings,
      atlas_treatment_source_inventory,
      pdm,
      db_adapter
    )
  } else {
    mcl_count_empty_ibrutinib_source_validation()
  }
  plan <- mcl_count_build_query_plan(
    defs,
    project_root = project_root,
    outputs_dir = outputs_dir,
    patient_demographics_resolver = patient_demographics_resolver,
    age_source_locator = age_source_locator,
    ibrutinib_source_validation = ibrutinib_source_validation,
    treatment_code_mappings = treatment_code_mappings
  )
  ki67_review <- mcl_count_ki67_query_review_rows(pdm, threshold_percent = ki67_threshold_percent, text_scan = ki67_text_scan)
  if (is.data.frame(ki67_review) && nrow(ki67_review)) {
    plan$review <- mcl_count_match_empty(bind_rows_base(list(plan$review, ki67_review)), mcl_count_empty_query_review())
  }
  ki67_templates <- mcl_count_ki67_query_templates(pdm, threshold_percent = ki67_threshold_percent, include_text_templates = TRUE)
  if (nzchar(ki67_templates)) {
    plan$sql <- paste(plan$sql, ki67_templates, sep = "\n")
  }
  person_key_audit <- mcl_count_person_key_audit(defs, count_sets = count_sets, outputs_dir = outputs_dir, project_root = project_root)
  if (is.list(count_sets) && length(count_sets)) {
    count_outputs <- mcl_count_outputs_from_sets(defs, count_sets, ki67_percent_counts = ki67_percent_counts, min_cell_count = min_cell_count)
    count_outputs <- lapply(count_outputs, function(x) mcl_count_add_provenance(x, "production_aggregate", generated_at, validation_status = "direct_aggregate_count_hook"))
  } else if (identical(mode, "production_aggregate") && db_available) {
    data_points <- mcl_count_execute_data_point_counts(
      defs,
      project_root,
      outputs_dir,
      db_adapter,
      min_cell_count = min_cell_count,
      generated_at = generated_at,
      no_result_status = "production_aggregate_failed_query_error",
      patient_demographics_resolver = patient_demographics_resolver,
      age_source_locator = age_source_locator,
      ibrutinib_source_validation = ibrutinib_source_validation,
      treatment_code_mappings = treatment_code_mappings
    )
    post_selection <- mcl_count_apply_post_selection_patient_check(patient_demographics_resolver, data_points)
    patient_demographics_resolver <- post_selection$resolver
    post_age_source <- mcl_count_apply_post_selection_age_source_check(age_source_locator, data_points)
    age_source_locator <- post_age_source$locator
    if (isTRUE(post_selection$invalidated) || isTRUE(post_age_source$invalidated)) {
      data_points <- mcl_count_fail_closed_age_data_points(data_points, if (nzchar(post_age_source$error_message %||% "")) post_age_source$error_message else post_selection$error_message)
      plan <- mcl_count_build_query_plan(
        defs,
        project_root = project_root,
        outputs_dir = outputs_dir,
        patient_demographics_resolver = patient_demographics_resolver,
        age_source_locator = age_source_locator,
        ibrutinib_source_validation = ibrutinib_source_validation,
        treatment_code_mappings = treatment_code_mappings
      )
      ki67_review <- mcl_count_ki67_query_review_rows(pdm, threshold_percent = ki67_threshold_percent, text_scan = ki67_text_scan)
      if (is.data.frame(ki67_review) && nrow(ki67_review)) {
        plan$review <- mcl_count_match_empty(bind_rows_base(list(plan$review, ki67_review)), mcl_count_empty_query_review())
      }
      ki67_templates <- mcl_count_ki67_query_templates(pdm, threshold_percent = ki67_threshold_percent, include_text_templates = TRUE)
      if (nzchar(ki67_templates)) {
        plan$sql <- paste(plan$sql, ki67_templates, sep = "\n")
      }
    }
    count_outputs <- mcl_count_outputs_from_data_points(data_points, min_cell_count = min_cell_count, generated_at = generated_at)
    ki67_outputs <- mcl_count_execute_ki67_outputs(
      db_adapter,
      pdm,
      atlas_ki67_source_inventory,
      threshold_percent = ki67_threshold_percent,
      text_scan = ki67_text_scan,
      min_cell_count = min_cell_count
    )
    count_outputs <- mcl_count_apply_ki67_outputs_to_count_outputs(count_outputs, ki67_outputs)
    intersection_run <- mcl_count_apply_production_intersection_sql(
      count_outputs,
      defs,
      project_root = project_root,
      outputs_dir = outputs_dir,
      db_adapter = db_adapter,
      patient_demographics_resolver = patient_demographics_resolver,
      age_source_locator = age_source_locator,
      ibrutinib_source_validation = ibrutinib_source_validation,
      treatment_code_mappings = treatment_code_mappings,
      min_cell_count = min_cell_count,
      generated_at = generated_at
    )
    count_outputs <- intersection_run$outputs
    intersection_stats <- intersection_run$stats
    count_outputs$ibrutinib_source_counts <- mcl_count_ibrutinib_source_counts_from_validation(ibrutinib_source_validation, min_cell_count = min_cell_count)
    count_outputs$ibrutinib_source_counts <- mcl_count_add_provenance(count_outputs$ibrutinib_source_counts, "production_aggregate", generated_at, validation_status = "ibrutinib_source_validation")
    count_outputs$ibrutinib_union_counts <- mcl_count_ibrutinib_union_counts_from_data_points(count_outputs$data_point_counts, ibrutinib_source_validation)
    count_outputs$ibrutinib_union_counts <- mcl_count_add_provenance(count_outputs$ibrutinib_union_counts, "production_aggregate", generated_at, validation_status = "ibrutinib_union_from_validated_sources")
    count_outputs$ibrutinib_overlap_by_source <- mcl_count_execute_ibrutinib_source_overlap_sql(ibrutinib_source_validation, treatment_code_mappings, count_outputs$data_point_counts, db_adapter, min_cell_count)
    count_outputs$ibrutinib_overlap_by_source <- mcl_count_add_provenance(count_outputs$ibrutinib_overlap_by_source, "production_aggregate", generated_at, validation_status = "ibrutinib_source_overlap")
    if (!any(data_points$count_source == "production_aggregate_sql", na.rm = TRUE) && !nzchar(failure_reason)) {
      failure_reason <- "production_aggregate_failed_query_error"
    }
  } else {
    status <- if (identical(mode, "plan")) {
      "query_executable_not_run"
    } else if (identical(failure_reason, "production_aggregate_failed_credentials_unavailable")) {
      "production_aggregate_failed_credentials_unavailable"
    } else {
      "production_aggregate_failed_mapping_unavailable"
    }
    data_points <- mcl_count_unavailable_data_points(
      defs,
      status = status,
      outputs_dir = outputs_dir,
      project_root = project_root,
      count_mode = mode,
      generated_at = generated_at,
      patient_demographics_resolver = patient_demographics_resolver,
      age_source_locator = age_source_locator,
      ibrutinib_source_validation = ibrutinib_source_validation,
      treatment_code_mappings = treatment_code_mappings
    )
    count_outputs <- mcl_count_placeholder_outputs(defs, mode = mode, outputs_dir = outputs_dir)
    count_outputs$data_point_counts <- data_points
    count_outputs$ibrutinib_source_counts <- mcl_count_empty_ibrutinib_source_counts()
    count_outputs$ibrutinib_union_counts <- mcl_count_empty_ibrutinib_union_counts()
    count_outputs$ibrutinib_overlap_by_source <- mcl_count_empty_ibrutinib_overlap_by_source()
    count_outputs$count_summary <- mcl_count_summary_from_outputs(
      data_points,
      count_outputs$inclusion_waterfall,
      count_outputs$overlap_matrix,
      count_outputs$exposure_strata_counts
    )
    count_outputs <- lapply(count_outputs, function(x) mcl_count_add_provenance(x, mode, generated_at, validation_status = "plan_or_mapping_gap"))
  }
  if (is.null(count_outputs$ibrutinib_source_counts)) {
    count_outputs$ibrutinib_source_counts <- mcl_count_empty_ibrutinib_source_counts()
  }
  if (is.null(count_outputs$ibrutinib_union_counts)) {
    count_outputs$ibrutinib_union_counts <- mcl_count_empty_ibrutinib_union_counts()
  }
  if (is.null(count_outputs$ibrutinib_overlap_by_source)) {
    count_outputs$ibrutinib_overlap_by_source <- mcl_count_empty_ibrutinib_overlap_by_source()
  }
  for (nm in c(
    "ki67_source_validation",
    "ki67_aeki_code_counts",
    "ki67_aeki_person_counts",
    "ki67_percent_distribution",
    "ki67_threshold_counts",
    "ki67_text_bridge_validation",
    "ki67_text_pattern_counts",
    "ki67_text_person_counts",
    "ki67_union_counts",
    "ki67_overlap_by_source"
  )) {
    if (is.null(count_outputs[[nm]])) count_outputs[[nm]] <- ki67_outputs[[nm]]
  }
  failed_query_audit <- mcl_count_failed_query_audit(
    data_points = count_outputs$data_point_counts,
    age_source_validation = age_source_validation,
    ibrutinib_source_validation = ibrutinib_source_validation,
    ki67_outputs = count_outputs
  )
  execution_summary <- mcl_count_execution_summary(
    mode = mode,
    plan = plan,
    db_attempted = db_attempted,
    db_available = db_available,
    data_points = count_outputs$data_point_counts,
    count_outputs = count_outputs,
    intersection_stats = intersection_stats,
    atlas_age_source_inventory = atlas_age_source_inventory,
    age_source_validation = age_source_validation,
    atlas_treatment_source_inventory = atlas_treatment_source_inventory,
    ibrutinib_source_validation = ibrutinib_source_validation,
    atlas_ki67_source_inventory = atlas_ki67_source_inventory,
    ki67_source_validation = ki67_outputs$ki67_source_validation,
    ki67_stats = ki67_outputs$stats,
    atlas_input_audit = atlas_input_audit,
    failed_query_audit = failed_query_audit,
    query_templates = plan$sql,
    value_mappings = plan$value_mappings,
    failure_reason = failure_reason
  )
  c(
    list(
      definitions = defs,
      query_templates = plan$sql,
      query_review = plan$review,
      person_date_mapping = plan$person_date_mapping,
      value_mappings = plan$value_mappings,
      patient_demographics_resolver = patient_demographics_resolver,
      age_source_locator = age_source_locator,
      atlas_input_audit = atlas_input_audit,
      atlas_age_source_inventory = atlas_age_source_inventory,
      age_source_validation = age_source_validation,
      atlas_treatment_source_inventory = atlas_treatment_source_inventory,
      atlas_ki67_source_inventory = atlas_ki67_source_inventory,
      treatment_code_mappings = treatment_code_mappings,
      ibrutinib_source_validation = ibrutinib_source_validation,
      person_key_audit = person_key_audit,
      failed_query_audit = failed_query_audit,
      execution_summary = execution_summary,
      latest_mapping_change = mcl_count_latest_mapping_change(project_root)
    ),
    count_outputs
  )
}

mcl_count_write_outputs <- function(outputs, output_dir) {
  dir_create(output_dir)
  paths <- list(
    person_key_audit = write_csv(outputs$person_key_audit, file.path(output_dir, "mcl_triangle_person_key_audit.csv")),
    patient_demographics_resolver = write_csv(outputs$patient_demographics_resolver %||% mcl_count_empty_patient_demographics_resolver(), file.path(output_dir, "mcl_triangle_patient_demographics_resolver.csv")),
    age_source_locator = write_csv(outputs$age_source_locator %||% mcl_count_empty_age_source_locator(), file.path(output_dir, "mcl_triangle_age_source_locator.csv")),
    atlas_input_audit = write_csv(outputs$atlas_input_audit %||% mcl_count_empty_atlas_input_audit(), file.path(output_dir, "mcl_triangle_atlas_input_audit.csv")),
    atlas_age_source_inventory = write_csv(outputs$atlas_age_source_inventory %||% mcl_count_empty_atlas_age_source_inventory(), file.path(output_dir, "mcl_triangle_atlas_age_source_inventory.csv")),
    age_source_validation = write_csv(outputs$age_source_validation %||% mcl_count_empty_age_source_validation(), file.path(output_dir, "mcl_triangle_age_source_validation.csv")),
    atlas_treatment_source_inventory = write_csv(outputs$atlas_treatment_source_inventory %||% mcl_count_empty_atlas_treatment_source_inventory(), file.path(output_dir, "mcl_triangle_atlas_treatment_source_inventory.csv")),
    atlas_ki67_source_inventory = write_csv(outputs$atlas_ki67_source_inventory %||% mcl_count_empty_atlas_ki67_source_inventory(), file.path(output_dir, "mcl_triangle_atlas_ki67_source_inventory.csv")),
    ibrutinib_source_validation = write_csv(outputs$ibrutinib_source_validation %||% mcl_count_empty_ibrutinib_source_validation(), file.path(output_dir, "mcl_triangle_ibrutinib_source_validation.csv")),
    ibrutinib_source_counts = write_csv(outputs$ibrutinib_source_counts %||% mcl_count_empty_ibrutinib_source_counts(), file.path(output_dir, "mcl_triangle_ibrutinib_source_counts.csv")),
    ibrutinib_union_counts = write_csv(outputs$ibrutinib_union_counts %||% mcl_count_empty_ibrutinib_union_counts(), file.path(output_dir, "mcl_triangle_ibrutinib_union_counts.csv")),
    ibrutinib_overlap_by_source = write_csv(outputs$ibrutinib_overlap_by_source %||% mcl_count_empty_ibrutinib_overlap_by_source(), file.path(output_dir, "mcl_triangle_ibrutinib_overlap_by_source.csv")),
    query_review = write_csv(outputs$query_review %||% mcl_count_empty_query_review(), file.path(output_dir, "mcl_triangle_count_query_review.csv")),
    data_point_counts = write_csv(outputs$data_point_counts, file.path(output_dir, "mcl_triangle_data_point_counts.csv")),
    inclusion_waterfall = write_csv(outputs$inclusion_waterfall, file.path(output_dir, "mcl_triangle_inclusion_waterfall.csv")),
    overlap_matrix = write_csv(outputs$overlap_matrix, file.path(output_dir, "mcl_triangle_overlap_matrix.csv")),
    exposure_strata_counts = write_csv(outputs$exposure_strata_counts, file.path(output_dir, "mcl_triangle_exposure_strata_counts.csv")),
    landmark_feasibility_counts = write_csv(outputs$landmark_feasibility_counts, file.path(output_dir, "mcl_triangle_landmark_feasibility_counts.csv")),
    ki67_person_count_summary = write_csv(outputs$ki67_person_count_summary, file.path(output_dir, "mcl_triangle_ki67_person_count_summary.csv")),
    ki67_source_validation = write_csv(outputs$ki67_source_validation %||% mcl_count_empty_ki67_source_validation(), file.path(output_dir, "mcl_triangle_ki67_source_validation.csv")),
    ki67_aeki_code_counts = write_csv(outputs$ki67_aeki_code_counts %||% mcl_count_empty_ki67_aeki_code_counts(), file.path(output_dir, "mcl_triangle_ki67_aeki_code_counts.csv")),
    ki67_aeki_person_counts = write_csv(outputs$ki67_aeki_person_counts %||% mcl_count_empty_ki67_aeki_person_counts(), file.path(output_dir, "mcl_triangle_ki67_aeki_person_counts.csv")),
    ki67_percent_distribution = write_csv(outputs$ki67_percent_distribution %||% mcl_count_empty_ki67_percent_distribution(), file.path(output_dir, "mcl_triangle_ki67_percent_distribution.csv")),
    ki67_threshold_counts = write_csv(outputs$ki67_threshold_counts %||% mcl_count_empty_ki67_threshold_counts(), file.path(output_dir, "mcl_triangle_ki67_threshold_counts.csv")),
    ki67_text_bridge_validation = write_csv(outputs$ki67_text_bridge_validation %||% mcl_count_empty_ki67_text_bridge_validation(), file.path(output_dir, "mcl_triangle_ki67_text_bridge_validation.csv")),
    ki67_text_pattern_counts = write_csv(outputs$ki67_text_pattern_counts %||% mcl_count_empty_ki67_text_pattern_counts(), file.path(output_dir, "mcl_triangle_ki67_text_pattern_counts.csv")),
    ki67_text_person_counts = write_csv(outputs$ki67_text_person_counts %||% mcl_count_empty_ki67_text_person_counts(), file.path(output_dir, "mcl_triangle_ki67_text_person_counts.csv")),
    ki67_union_counts = write_csv(outputs$ki67_union_counts %||% mcl_count_empty_ki67_union_counts(), file.path(output_dir, "mcl_triangle_ki67_union_counts.csv")),
    ki67_overlap_by_source = write_csv(outputs$ki67_overlap_by_source %||% mcl_count_empty_ki67_overlap_by_source(), file.path(output_dir, "mcl_triangle_ki67_overlap_by_source.csv")),
    age_proxy_counts = write_csv(outputs$age_proxy_counts %||% mcl_count_empty_age_proxy_counts(), file.path(output_dir, "mcl_triangle_age_proxy_counts.csv")),
    ibrutinib_exposure_counts = write_csv(outputs$ibrutinib_exposure_counts %||% mcl_count_empty_ibrutinib_exposure_counts(), file.path(output_dir, "mcl_triangle_ibrutinib_exposure_counts.csv")),
    treatment_strategy_strata_counts = write_csv(outputs$treatment_strategy_strata_counts %||% mcl_count_empty_treatment_strategy_strata_counts(), file.path(output_dir, "mcl_triangle_treatment_strategy_strata_counts.csv")),
    high_risk_biology_counts = write_csv(outputs$high_risk_biology_counts %||% mcl_count_empty_high_risk_biology_counts(), file.path(output_dir, "mcl_triangle_high_risk_biology_counts.csv")),
    answerability_intersections = write_csv(outputs$answerability_intersections %||% mcl_count_empty_answerability_intersections(), file.path(output_dir, "mcl_triangle_answerability_intersections.csv")),
    answerability_summary = write_csv(outputs$answerability_summary %||% mcl_count_empty_answerability_summary(), file.path(output_dir, "mcl_triangle_answerability_summary.csv")),
    count_summary = write_csv(outputs$count_summary, file.path(output_dir, "mcl_triangle_count_summary.csv")),
    failed_query_audit = write_csv(outputs$failed_query_audit %||% mcl_count_empty_failed_query_audit(), file.path(output_dir, "mcl_triangle_failed_query_audit.csv")),
    execution_summary = write_csv(outputs$execution_summary %||% mcl_count_empty_execution_summary(), file.path(output_dir, "mcl_triangle_execution_summary.csv"))
  )
  template_path <- file.path(output_dir, "mcl_triangle_count_query_templates.sql")
  writeLines(outputs$query_templates %||% "", con = template_path, useBytes = TRUE)
  paths$query_templates <- template_path
  mode <- if (is.data.frame(outputs$execution_summary) && nrow(outputs$execution_summary)) outputs$execution_summary$mode[[1]] else ""
  status <- mcl_count_output_generation_status(
    output_dir,
    paths,
    mode = mode,
    latest_mapping_change = outputs$latest_mapping_change %||% Sys.time(),
    patient_demographics_resolver = outputs$patient_demographics_resolver %||% mcl_count_empty_patient_demographics_resolver(),
    age_source_locator = outputs$age_source_locator %||% mcl_count_empty_age_source_locator()
  )
  paths$output_generation_status <- write_csv(status, file.path(output_dir, "output_generation_status.csv"))
  invisible(paths)
}

mcl_count_read_outputs <- function(output_dir) {
  read_or_empty <- function(name, empty) {
    path <- file.path(output_dir, name)
    if (file.exists(path)) read_delimited_file(path) else empty
  }
  list(
    person_key_audit = read_or_empty("mcl_triangle_person_key_audit.csv", mcl_count_empty_person_key_audit()),
    patient_demographics_resolver = read_or_empty("mcl_triangle_patient_demographics_resolver.csv", mcl_count_empty_patient_demographics_resolver()),
    age_source_locator = read_or_empty("mcl_triangle_age_source_locator.csv", mcl_count_empty_age_source_locator()),
    atlas_input_audit = read_or_empty("mcl_triangle_atlas_input_audit.csv", mcl_count_empty_atlas_input_audit()),
    atlas_age_source_inventory = read_or_empty("mcl_triangle_atlas_age_source_inventory.csv", mcl_count_empty_atlas_age_source_inventory()),
    age_source_validation = read_or_empty("mcl_triangle_age_source_validation.csv", mcl_count_empty_age_source_validation()),
    atlas_treatment_source_inventory = read_or_empty("mcl_triangle_atlas_treatment_source_inventory.csv", mcl_count_empty_atlas_treatment_source_inventory()),
    atlas_ki67_source_inventory = read_or_empty("mcl_triangle_atlas_ki67_source_inventory.csv", mcl_count_empty_atlas_ki67_source_inventory()),
    ibrutinib_source_validation = read_or_empty("mcl_triangle_ibrutinib_source_validation.csv", mcl_count_empty_ibrutinib_source_validation()),
    ibrutinib_source_counts = read_or_empty("mcl_triangle_ibrutinib_source_counts.csv", mcl_count_empty_ibrutinib_source_counts()),
    ibrutinib_union_counts = read_or_empty("mcl_triangle_ibrutinib_union_counts.csv", mcl_count_empty_ibrutinib_union_counts()),
    ibrutinib_overlap_by_source = read_or_empty("mcl_triangle_ibrutinib_overlap_by_source.csv", mcl_count_empty_ibrutinib_overlap_by_source()),
    query_review = read_or_empty("mcl_triangle_count_query_review.csv", mcl_count_empty_query_review()),
    data_point_counts = read_or_empty("mcl_triangle_data_point_counts.csv", mcl_count_empty_data_point_counts()),
    inclusion_waterfall = read_or_empty("mcl_triangle_inclusion_waterfall.csv", mcl_count_empty_inclusion_waterfall()),
    overlap_matrix = read_or_empty("mcl_triangle_overlap_matrix.csv", mcl_count_empty_overlap_matrix()),
    exposure_strata_counts = read_or_empty("mcl_triangle_exposure_strata_counts.csv", mcl_count_empty_exposure_strata_counts()),
    landmark_feasibility_counts = read_or_empty("mcl_triangle_landmark_feasibility_counts.csv", mcl_count_empty_landmark_counts()),
    ki67_person_count_summary = read_or_empty("mcl_triangle_ki67_person_count_summary.csv", mcl_count_empty_ki67_person_summary()),
    ki67_source_validation = read_or_empty("mcl_triangle_ki67_source_validation.csv", mcl_count_empty_ki67_source_validation()),
    ki67_aeki_code_counts = read_or_empty("mcl_triangle_ki67_aeki_code_counts.csv", mcl_count_empty_ki67_aeki_code_counts()),
    ki67_aeki_person_counts = read_or_empty("mcl_triangle_ki67_aeki_person_counts.csv", mcl_count_empty_ki67_aeki_person_counts()),
    ki67_percent_distribution = read_or_empty("mcl_triangle_ki67_percent_distribution.csv", mcl_count_empty_ki67_percent_distribution()),
    ki67_threshold_counts = read_or_empty("mcl_triangle_ki67_threshold_counts.csv", mcl_count_empty_ki67_threshold_counts()),
    ki67_text_bridge_validation = read_or_empty("mcl_triangle_ki67_text_bridge_validation.csv", mcl_count_empty_ki67_text_bridge_validation()),
    ki67_text_pattern_counts = read_or_empty("mcl_triangle_ki67_text_pattern_counts.csv", mcl_count_empty_ki67_text_pattern_counts()),
    ki67_text_person_counts = read_or_empty("mcl_triangle_ki67_text_person_counts.csv", mcl_count_empty_ki67_text_person_counts()),
    ki67_union_counts = read_or_empty("mcl_triangle_ki67_union_counts.csv", mcl_count_empty_ki67_union_counts()),
    ki67_overlap_by_source = read_or_empty("mcl_triangle_ki67_overlap_by_source.csv", mcl_count_empty_ki67_overlap_by_source()),
    age_proxy_counts = read_or_empty("mcl_triangle_age_proxy_counts.csv", mcl_count_empty_age_proxy_counts()),
    ibrutinib_exposure_counts = read_or_empty("mcl_triangle_ibrutinib_exposure_counts.csv", mcl_count_empty_ibrutinib_exposure_counts()),
    treatment_strategy_strata_counts = read_or_empty("mcl_triangle_treatment_strategy_strata_counts.csv", mcl_count_empty_treatment_strategy_strata_counts()),
    high_risk_biology_counts = read_or_empty("mcl_triangle_high_risk_biology_counts.csv", mcl_count_empty_high_risk_biology_counts()),
    answerability_intersections = read_or_empty("mcl_triangle_answerability_intersections.csv", mcl_count_empty_answerability_intersections()),
    answerability_summary = read_or_empty("mcl_triangle_answerability_summary.csv", mcl_count_empty_answerability_summary()),
    count_summary = read_or_empty("mcl_triangle_count_summary.csv", mcl_count_empty_summary()),
    failed_query_audit = read_or_empty("mcl_triangle_failed_query_audit.csv", mcl_count_empty_failed_query_audit()),
    execution_summary = read_or_empty("mcl_triangle_execution_summary.csv", mcl_count_empty_execution_summary()),
    output_generation_status = read_or_empty("output_generation_status.csv", mcl_count_empty_output_generation_status())
  )
}

mcl_count_empty_standalone_output_source <- function() {
  empty_df(
    source_type = character(),
    source_path = character(),
    selected_outputs_dir = character(),
    selected = logical(),
    mode = character(),
    acceptance_status = character(),
    failed_queries = integer(),
    production_aggregate_succeeded = logical(),
    notes = character()
  )
}

mcl_count_output_dir_has_summary <- function(path) {
  is.character(path) &&
    length(path) == 1L &&
    nzchar(path) &&
    file.exists(file.path(path, "mcl_triangle_execution_summary.csv"))
}

mcl_count_find_outputs_dir <- function(path) {
  if (is.null(path) || !length(path) || is.na(path) || !nzchar(path)) return("")
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  candidates <- unique(c(path, file.path(path, "outputs")))
  existing_dirs <- candidates[dir.exists(candidates)]
  recursive <- character()
  if (dir.exists(path)) {
    recursive <- list.dirs(path, recursive = TRUE, full.names = TRUE)
    recursive <- recursive[basename(recursive) == "outputs"]
  }
  candidates <- unique(c(existing_dirs, recursive))
  hits <- candidates[vapply(candidates, mcl_count_output_dir_has_summary, logical(1))]
  if (!length(hits)) return("")
  hits <- hits[order(nchar(hits), hits)]
  normalizePath(hits[[1]], winslash = "/", mustWork = FALSE)
}

mcl_count_output_source_metadata <- function(source_type,
                                             source_path,
                                             selected_outputs_dir = "",
                                             selected = FALSE,
                                             notes = "") {
  mode <- ""
  acceptance_status <- ""
  failed_queries <- NA_integer_
  production_aggregate_succeeded <- FALSE
  if (mcl_count_output_dir_has_summary(selected_outputs_dir)) {
    summary <- tryCatch(
      read_delimited_file(file.path(selected_outputs_dir, "mcl_triangle_execution_summary.csv")),
      error = function(e) data.frame(stringsAsFactors = FALSE)
    )
    if (is.data.frame(summary) && nrow(summary)) {
      mode <- as.character(summary$mode[[1]] %||% "")
      acceptance_status <- as.character(summary$acceptance_status[[1]] %||% "")
      failed_queries <- suppressWarnings(as.integer(summary$failed_queries[[1]] %||% NA_integer_))
      production_aggregate_succeeded <- tolower(as.character(summary$production_aggregate_succeeded[[1]] %||% "")) %in% c("true", "t", "1", "yes")
    }
  }
  data.frame(
    source_type = source_type,
    source_path = normalizePath(source_path %||% "", winslash = "/", mustWork = FALSE),
    selected_outputs_dir = normalizePath(selected_outputs_dir %||% "", winslash = "/", mustWork = FALSE),
    selected = isTRUE(selected),
    mode = mode,
    acceptance_status = acceptance_status,
    failed_queries = failed_queries,
    production_aggregate_succeeded = isTRUE(production_aggregate_succeeded),
    notes = notes,
    stringsAsFactors = FALSE
  )
}

mcl_count_output_dir_is_accepted_production <- function(path) {
  meta <- mcl_count_output_source_metadata("candidate", path, path, selected = TRUE)
  if (!isTRUE(meta$selected[[1]])) return(FALSE)
  identical(meta$mode[[1]], "production_aggregate") &&
    isTRUE(meta$production_aggregate_succeeded[[1]]) &&
    !is.na(meta$failed_queries[[1]]) &&
    meta$failed_queries[[1]] == 0L &&
    grepl("^accepted", meta$acceptance_status[[1]] %||% "")
}

mcl_count_extract_zip_outputs_dir <- function(zip_path) {
  if (is.null(zip_path) || !length(zip_path) || is.na(zip_path) || !file.exists(zip_path)) return("")
  scratch <- file.path(tempdir(), paste0("mcl_triangle_count_output_zip_", Sys.getpid(), "_", as.integer(stats::runif(1, 100000, 999999))))
  dir_create(scratch)
  tryCatch(
    utils::unzip(zip_path, exdir = scratch),
    error = function(e) character()
  )
  mcl_count_find_outputs_dir(scratch)
}

mcl_count_default_output5_fixture_dir <- function(project_root = ".") {
  fixture <- file.path(project_root, "inst", "extdata", "mcl_triangle_output5", "outputs")
  if (mcl_count_output_dir_has_summary(fixture)) normalizePath(fixture, winslash = "/", mustWork = FALSE) else ""
}

mcl_count_resolve_standalone_output_source <- function(project_root = ".",
                                                       outputs_dir = "",
                                                       count_output_zip = Sys.getenv("MCL_TRIANGLE_COUNT_OUTPUT_ZIP", unset = ""),
                                                       count_output_dir = Sys.getenv("MCL_TRIANGLE_COUNT_OUTPUT_DIR", unset = "")) {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  if (nzchar(count_output_zip %||% "")) {
    selected <- mcl_count_extract_zip_outputs_dir(count_output_zip)
    if (nzchar(selected)) {
      return(list(
        outputs_dir = selected,
        metadata = mcl_count_output_source_metadata(
          "explicit_zip",
          count_output_zip,
          selected,
          selected = TRUE,
          notes = "Using explicit MCL_TRIANGLE_COUNT_OUTPUT_ZIP standalone aggregate output."
        )
      ))
    }
    return(list(
      outputs_dir = "",
      metadata = mcl_count_output_source_metadata(
        "explicit_zip_missing",
        count_output_zip,
        "",
        selected = FALSE,
        notes = "Explicit MCL_TRIANGLE_COUNT_OUTPUT_ZIP was supplied but no standalone output directory was found."
      )
    ))
  }
  if (nzchar(count_output_dir %||% "")) {
    selected <- mcl_count_find_outputs_dir(count_output_dir)
    if (nzchar(selected)) {
      return(list(
        outputs_dir = selected,
        metadata = mcl_count_output_source_metadata(
          "explicit_dir",
          count_output_dir,
          selected,
          selected = TRUE,
          notes = "Using explicit MCL_TRIANGLE_COUNT_OUTPUT_DIR standalone aggregate output."
        )
      ))
    }
    return(list(
      outputs_dir = "",
      metadata = mcl_count_output_source_metadata(
        "explicit_dir_missing",
        count_output_dir,
        "",
        selected = FALSE,
        notes = "Explicit MCL_TRIANGLE_COUNT_OUTPUT_DIR was supplied but no standalone output directory was found."
      )
    ))
  }
  current <- mcl_count_find_outputs_dir(outputs_dir)
  if (nzchar(current) && mcl_count_output_dir_is_accepted_production(current)) {
    return(list(
      outputs_dir = current,
      metadata = mcl_count_output_source_metadata(
        "current_atlas_outputs",
        current,
        current,
        selected = TRUE,
        notes = "Using current atlas output directory because it contains accepted production aggregate TRIANGLE outputs."
      )
    ))
  }
  fixture <- mcl_count_default_output5_fixture_dir(project_root)
  if (nzchar(fixture) && mcl_count_output_dir_is_accepted_production(fixture)) {
    return(list(
      outputs_dir = fixture,
      metadata = mcl_count_output_source_metadata(
        "bundled_output5_fixture",
        fixture,
        fixture,
        selected = TRUE,
        notes = "Using local aggregate-only Output(5) fixture as the deterministic atlas fallback."
      )
    ))
  }
  list(
    outputs_dir = "",
    metadata = mcl_count_output_source_metadata(
      "not_available",
      "",
      "",
      selected = FALSE,
      notes = "No accepted production aggregate standalone MCL/TRIANGLE output source was available."
    )
  )
}
