root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

sources <- data.frame(
  table_name = c("example_labs", "RKKP_DaMyDa"),
  source_type = c("file", "file"),
  source = c("labs.csv", "damyda.csv"),
  domain = c("SP", "RKKP"),
  subdomain = c("Laboratory", "DaMyDa"),
  atlas_role = c("fixture", "clinical_registry"),
  profile_mode = c("full", "full"),
  load_status = c("ok", "ok"),
  n_rows = c(10, 4),
  n_cols = c(5, 8),
  id_column_guess = c("patientid", "patientid"),
  min_date = c("2020-01-01", "2021-01-01"),
  max_date = c("2020-01-03", "2021-04-01"),
  stringsAsFactors = FALSE
)
columns <- data.frame(
  table_name = "example_labs",
  column_name = "patientid",
  column_type = "character",
  stringsAsFactors = FALSE
)
checks <- data.frame(
  table_name = "example_labs",
  check_id = "sensitive_column_values_suppressed",
  severity = "ok",
  message = "Value frequencies suppressed for: patientid",
  stringsAsFactors = FALSE
)
panels <- list(
  npu_dictionary_summary = data.frame(
    metric = c("dictionary_codes", "consensus_vectors"),
    label = c("Dictionary NPU codes", "Consensus vectors"),
    value = c("155", "45"),
    stringsAsFactors = FALSE
  ),
  npu_dictionary_vectors = data.frame(
    consensus_vector = c("CREATININE_CODES", "CALCIUM_TOTAL_CODES"),
    n_dictionary_codes = c(2, 3),
    systems = c("P", "P"),
    n_systems = c(1, 1),
    n_active = c(2, 1),
    n_with_clinical_role = c(2, 3),
    n_v08_sources = c(1, 1),
    clinical_roles = c("Plasma creatinine", "Total plasma calcium"),
    stringsAsFactors = FALSE
  ),
  npu_lab_usage_by_vector = data.frame(
    table_name = "example_labs",
    code_column = "analysiscode",
    consensus_vector = "CREATININE_CODES",
    clinical_role = "Plasma creatinine",
    n_observed = 6,
    pct_rows = 60,
    n_codes_observed = 1,
    n_dictionary_codes = 2,
    stringsAsFactors = FALSE
  ),
  npu_lab_unmatched_codes = empty_npu_lab_unmatched_codes(),
  npu_detective_code_inventory = data.frame(
    table_name = "example_labs",
    code_column = "analysiscode",
    npu_code = "NPU04998",
    dictionary_match = TRUE,
    consensus_vector = "CREATININE_CODES",
    clinical_role = "Plasma creatinine",
    system = "P",
    status_labterm = "Active",
    surface = "renal_creatinine",
    candidate_label = "Creatinine and renal function",
    n_observed = 6,
    pct_rows = 60,
    stringsAsFactors = FALSE
  ),
  npu_detective_candidates = empty_npu_detective_candidates(),
  npu_detective_source_year = data.frame(
    table_name = "example_labs",
    code_column = "analysiscode",
    year_column = "samplingdate",
    year = 2021,
    npu_code = "NPU04998",
    consensus_vector = "CREATININE_CODES",
    surface = "renal_creatinine",
    n_observed = 6,
    pct_rows = 60,
    stringsAsFactors = FALSE
  ),
  isotype_code_usage = data.frame(
    table_name = "example_labs",
    code_column = "analysiscode",
    npu_code = "NPU28638",
    consensus_vector = "MSPIKE_IGG",
    isotype_family = "IgG",
    specimen_class = "plasma",
    bucket = "heavy_chain",
    n_observed = 3,
    pct_rows = 30,
    stringsAsFactors = FALSE
  ),
  isotype_bucket_summary = data.frame(
    table_name = "example_labs",
    bucket = "heavy_chain",
    isotype_family = "IgG",
    specimen_class = "plasma",
    n_rows = 3,
    pct_rows = 30,
    n_patients = NA_integer_,
    stringsAsFactors = FALSE
  ),
  mm_treatment_code_counts = data.frame(
    table_name = "example_treatments",
    code_column = "procedurekode",
    code_system = "SKS",
    family = "mm_procedure",
    match_type = "exact",
    code = "BWHA154",
    label = "Myeloma procedure BWHA154",
    n_rows = 2,
    pct_rows = 20,
    n_patients = NA_integer_,
    stringsAsFactors = FALSE
  ),
  mm_treatment_source_summary = data.frame(
    table_name = "example_treatments",
    n_rows_scanned = 10,
    matched_rows = 2,
    pct_rows_matched = 20,
    matched_patients = NA_integer_,
    min_date = "2021-06-01",
    max_date = "2021-06-02",
    stringsAsFactors = FALSE
  ),
  situation_report_summary = data.frame(
    metric_id = "diagnosed_30d",
    label = "Diagnosed in past 30 days",
    n_patients = 7,
    n_rows = 8,
    window_days = 30,
    as_of_date = "2026-05-01",
    source_table = "t_dalycare_diagnoses",
    date_column = "date_diagnosis",
    definition_basis = "diagnosis_date_30d",
    n_cohort = 100,
    pct_cohort = 7,
    definition_status = "ok",
    freshness_status = "current",
    message = "Aggregate DB-side count.",
    stringsAsFactors = FALSE
  ),
  situation_report_breakdowns = data.frame(
    metric_id = "diagnosed_30d",
    label = "Diagnosed in past 30 days",
    breakdown_type = "source",
    breakdown_value = "t_dalycare_diagnoses",
    n_patients = 7,
    n_rows = 8,
    pct_patients = 100,
    source_table = "t_dalycare_diagnoses",
    as_of_date = "2026-05-01",
    stringsAsFactors = FALSE
  ),
  situation_report_freshness = data.frame(
    metric_id = "diagnosed_30d",
    source_table = "t_dalycare_diagnoses",
    date_column = "date_diagnosis",
    max_date = "2026-05-01",
    as_of_date = "2026-05-01",
    lag_days = 0,
    freshness_status = "current",
    message = "Source date matches the freshest situation-report source.",
    stringsAsFactors = FALSE
  ),
  atlas_temporal_coverage = data.frame(
    table_name = c("example_labs", "RKKP_DaMyDa"),
    domain = c("SP", "RKKP"),
    subdomain = c("Laboratory", "DaMyDa"),
    atlas_role = c("fixture", "clinical_registry"),
    n_rows = c(10, 4),
    date_column = c("samplingdate", "diagnosis_date"),
    raw_min_date = c("2020-01-01", "2021-01-01"),
    raw_max_date = c("2020-01-03", "2021-04-01"),
    display_min_year = c(2020, 2021),
    display_max_year = c(2020, 2021),
    display_min_date = c("2020-01-01", "2021-01-01"),
    display_max_date = c("2020-12-31", "2021-12-31"),
    pct_available = c(100, 100),
    date_qc = "ok",
    stringsAsFactors = FALSE
  ),
  atlas_temporal_coverage_years = data.frame(
    table_name = c("example_labs", "RKKP_DaMyDa"),
    domain = c("SP", "RKKP"),
    subdomain = c("Laboratory", "DaMyDa"),
    atlas_role = c("fixture", "clinical_registry"),
    date_column = c("samplingdate", "diagnosis_date"),
    year = c(2020, 2021),
    n_rows = c(10, 4),
    pct_rows = c(100, 100),
    coverage_basis = "event_date_counts",
    stringsAsFactors = FALSE
  ),
  atlas_spatial_region_counts = data.frame(
    table_name = "RKKP_DaMyDa",
    domain = "RKKP",
    subdomain = "DaMyDa",
    atlas_role = "clinical_registry",
    region_column = "Region",
    region_code = "1084",
    region_name = "Capital Region",
    n_rows = 4,
    pct_rows = 100,
    count_basis = "region_column_counts",
    stringsAsFactors = FALSE
  ),
  atlas_spatial_region_coverage = data.frame(
    region_code = "1084",
    region_name = "Capital Region",
    display_label = "Capital",
    domain = "SP",
    coverage_status = "ehr",
    loaded_sources = 1,
    mapped_sources = 1,
    n_rows = 10,
    basis = "source_metadata",
    stringsAsFactors = FALSE
  ),
  atlas_dk_choropleth_regions = data.frame(
    region_code = "1084",
    region_name = "Capital Region",
    display_label = "Capital",
    map_order = 1,
    map_include = TRUE,
    svg_path = "M0 0 L1 0 L1 1 Z",
    choropleth_value = 4,
    pct_total = 100,
    choropleth_basis = "DaMyDa region count",
    damyda_n = 4,
    ehr_status = "ehr",
    lab_status = "capital",
    story = "fixture",
    stringsAsFactors = FALSE
  ),
  registry_clinical_summary = data.frame(
    table_name = "RKKP_DaMyDa",
    registry = "DaMyDa",
    n_rows = 4,
    n_cols = 8,
    n_patients = 4,
    min_date = "2021-01-01",
    max_date = "2021-04-01",
    stringsAsFactors = FALSE
  ),
  damyda_clinical_profile = data.frame(
    table_name = "RKKP_DaMyDa",
    registry = "DaMyDa",
    facet = c("stage", "stage", "bone_disease"),
    source_column = c("iss_stage", "iss_stage", "bone_disease"),
    label = c("II", "I", "yes"),
    n = c(2, 1, 2),
    pct_rows = c(50, 25, 50),
    stringsAsFactors = FALSE
  ),
  damyda_numeric_fields = data.frame(
    table_name = "RKKP_DaMyDa",
    registry = "DaMyDa",
    field = "albumin",
    source_column = "albumin",
    unit = "g/L",
    n_available = 3,
    pct_available = 75,
    mean = 37,
    median = 38,
    p25 = 35,
    p75 = 40,
    stringsAsFactors = FALSE
  ),
  lyfo_clinical_profile = empty_registry_categorical(),
  cll_clinical_profile = empty_registry_categorical(),
  source_availability_drift = data.frame(source_type = "file", load_status = "ok", n_sources = 2, stringsAsFactors = FALSE)
)
run_summary <- data.frame(
  metric = c("mapped_sources", "loaded_sources", "min_cell_count"),
  value = c("2", "2", "5"),
  stringsAsFactors = FALSE
)
action_items <- data.frame(
  severity = "warning",
  category = "Source resolution",
  action_id = "missing_source",
  table_name = "view_date_death",
  domain = "DALY views",
  subdomain = "Survival",
  atlas_role = "infrastructure",
  reason = "No matching table or view was found in the DB catalog.",
  current_behavior = "The source was not profiled because it was absent from the live DB catalog.",
  recommended_action = "Confirm that this DALY view exists in the live database.",
  evidence = "nearest=view_true_date_death",
  stringsAsFactors = FALSE
)
column_profiles <- data.frame(
  domain = c("SP", "SP"),
  table_name = c("example_labs", "example_labs"),
  column_name = c("patientid", "group"),
  column_type = c("character", "character"),
  column_class = c("character", "character"),
  profile_kind = c("sensitive", "categorical"),
  n_rows = c(10, 10),
  n_available = c(10, 9),
  pct_available = c(100, 90),
  n_missing = c(0, 1),
  pct_missing = c(0, 10),
  n_distinct_capped = c(10, 2),
  is_sensitive = c(TRUE, FALSE),
  is_date_like = c(FALSE, FALSE),
  is_numeric_like = c(FALSE, FALSE),
  min = c(NA, NA),
  mean = c(NA, NA),
  median = c(NA, NA),
  p25 = c(NA, NA),
  p75 = c(NA, NA),
  max = c(NA, NA),
  min_date = c(NA, NA),
  max_date = c(NA, NA),
  stringsAsFactors = FALSE
)
column_top_values <- data.frame(
  domain = "SP",
  table_name = "example_labs",
  column_name = "group",
  value = "A",
  n = 6,
  pct_rows = 60,
  stringsAsFactors = FALSE
)

payload <- atlas_payload(
  "test-run", "2026-05-09T00:00:00+0200", sources, columns, checks, panels,
  column_profiles = column_profiles,
  column_top_values = column_top_values,
  run_summary = run_summary,
  action_items = action_items,
  db_query_log = data.frame(
    table_name = "example_labs",
    column_name = "value",
    query_category = "column_stream",
    strategy = "stream_column",
    estimated_rows = 10,
    chunks_fetched = 1,
    status = "ok",
    budget_decision = "streamed",
    elapsed_ms = 1,
    message = "test",
    stringsAsFactors = FALSE
  ),
  db_budget_actions = data.frame(
    severity = "warning",
    category = "DB budget",
    action_id = "db_budget_skipped",
    table_name = "example_labs",
    column_name = "value",
    query_category = "numeric_quantiles",
    estimated_rows = 10,
    reason = "test",
    current_behavior = "test",
    recommended_action = "test",
    stringsAsFactors = FALSE
  )
)
expect_true(all(c("hero_metrics", "domain_cards", "catalog_rows", "qa_items", "action_items", "action_summary", "db_query_log", "db_budget_actions", "npu_cards", "detective_cards", "isotype_cards", "treatment_cards", "situation_report_cards", "registry_cards", "panel_groups", "column_profile_rows", "column_top_value_rows", "column_profile_summary") %in% names(payload)), "Payload should include the AOT-grade view model sections.")
expect_true(all(c("aot_nav", "aot_overview", "aot_registry_sections", "aot_clinical_sections", "aot_treatment_sections", "aot_laboratory_sections", "aot_situation_sections", "aot_ehr_sections", "aot_infrastructure_sections") %in% names(payload)), "Payload should include the V33-style AOT view-model sections.")
expect_true(all(c("aot_temporal_coverage", "aot_spatial_coverage", "aot_dk_choropleth") %in% names(payload)), "Payload should include V33-style coverage view-model sections.")
expect_true(length(payload$hero_metrics) > 0, "Hero metrics should be populated.")
expect_true(length(payload$aot_nav) == 9L, "AOT navigation should expose the V33-style top-level domains.")
expect_true(any(vapply(payload$aot_nav, function(row) identical(row$label, "Situation Report"), logical(1))), "AOT navigation should include Situation Report.")
expect_true(any(vapply(payload$aot_nav, function(row) identical(row$label, "Disease Registries"), logical(1))), "AOT navigation should include Disease Registries.")
expect_true(length(payload$aot_overview$source_availability) > 0, "AOT overview should derive source availability summaries from source rows.")
expect_true(length(payload$aot_registry_sections$damyda) > 0, "AOT registry sections should include DaMyDa panels when available.")
expect_true(length(payload$aot_laboratory_sections$npu$summary) > 0, "AOT laboratory sections should include NPU dictionary summaries.")
expect_true(length(payload$aot_treatment_sections$code_families) > 0, "AOT treatment sections should include treatment-code family summaries.")
expect_true(length(payload$aot_situation_sections$cards) > 0, "AOT Situation Report sections should include headline cards.")
expect_true(length(payload$aot_situation_sections$freshness) > 0, "AOT Situation Report sections should include freshness rows.")
expect_true(length(payload$aot_infrastructure_sections$catalog) > 0, "AOT infrastructure sections should include catalog rows.")
expect_true(length(payload$aot_infrastructure_sections$action_items) > 0, "AOT infrastructure sections should include action item rows.")
expect_true(length(payload$aot_infrastructure_sections$action_summary) > 0, "AOT infrastructure sections should include action item summaries.")
expect_true(length(payload$aot_infrastructure_sections$db_budget_actions) > 0, "AOT infrastructure sections should include DB budget action rows.")
expect_true(length(payload$aot_infrastructure_sections$db_query_log) > 0, "AOT infrastructure sections should include DB query log rows.")
expect_true(length(payload$aot_temporal_coverage$sources) > 0, "AOT temporal coverage should include source coverage rows.")
expect_true(length(payload$aot_temporal_coverage$years) > 0, "AOT temporal coverage should include year rows.")
expect_true(length(payload$aot_spatial_coverage$region_coverage) > 0, "AOT spatial coverage should include region coverage rows.")
expect_true(length(payload$aot_dk_choropleth$map_regions) > 0, "AOT Denmark choropleth should include map regions.")
expect_true(length(payload$domain_cards) == 2L, "Domain cards should be derived from source domains.")
expect_true(length(payload$catalog_rows) == 2L, "Catalog rows should be derived from source rows.")
expect_true(length(payload$column_profile_rows) == 2L, "Column profile rows should be included in the public payload.")
expect_true(length(payload$column_top_value_rows) == 1L, "Column top value rows should be included in the public payload.")
expect_true(length(payload$column_profile_summary) > 0, "Column profile summaries should be included in the public payload.")
expect_true(length(payload$npu_cards$summary) > 0, "NPU cards should include dictionary summary rows.")
expect_true(length(payload$npu_cards$top_vectors) > 0, "NPU cards should include vector summaries.")
expect_true(length(payload$npu_cards$observed_vectors) > 0, "NPU cards should include observed lab usage.")
expect_true(length(payload$detective_cards$observed_codes) > 0, "NPU detective cards should include observed code inventory.")
expect_true(length(payload$isotype_cards$code_usage) > 0, "Isotype cards should include observed code usage.")
expect_true(length(payload$treatment_cards$code_families) > 0, "Treatment cards should include MM treatment code counts.")
expect_true(length(payload$situation_report_cards) > 0, "Situation Report cards should include headline metrics.")
expect_true(length(payload$registry_cards) == 1L, "Registry cards should be generated when registry panels exist.")
expect_true("DaMyDa" %in% names(payload$registry_cards), "Registry cards should be keyed by registry name.")
expect_true(any(vapply(payload$panel_groups, function(row) identical(row$panel_name, "damyda_clinical_profile"), logical(1))), "Panel groups should include generated panel metadata.")

view_json <- atlas_to_json(list(
  hero_metrics = payload$hero_metrics,
  domain_cards = payload$domain_cards,
  catalog_rows = payload$catalog_rows,
  qa_items = payload$qa_items,
  action_items = payload$action_items,
  action_summary = payload$action_summary,
  npu_cards = payload$npu_cards,
  detective_cards = payload$detective_cards,
  isotype_cards = payload$isotype_cards,
  treatment_cards = payload$treatment_cards,
  situation_report_cards = payload$situation_report_cards,
  aot_nav = payload$aot_nav,
  aot_overview = payload$aot_overview,
  aot_registry_sections = payload$aot_registry_sections,
  aot_clinical_sections = payload$aot_clinical_sections,
  aot_treatment_sections = payload$aot_treatment_sections,
  aot_laboratory_sections = payload$aot_laboratory_sections,
  aot_situation_sections = payload$aot_situation_sections,
  aot_ehr_sections = payload$aot_ehr_sections,
  aot_temporal_coverage = payload$aot_temporal_coverage,
  aot_spatial_coverage = payload$aot_spatial_coverage,
  aot_dk_choropleth = payload$aot_dk_choropleth,
  aot_infrastructure_sections = payload$aot_infrastructure_sections,
  registry_cards = payload$registry_cards,
  panel_groups = payload$panel_groups,
  column_profile_rows = payload$column_profile_rows,
  column_top_value_rows = payload$column_top_value_rows
))
expect_false(grepl("patientid", view_json, ignore.case = TRUE), "View-model payload sections should not expose id-like field names.")
