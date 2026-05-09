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
  run_summary = run_summary
)
expect_true(all(c("hero_metrics", "domain_cards", "catalog_rows", "qa_items", "npu_cards", "registry_cards", "panel_groups", "column_profile_rows", "column_top_value_rows", "column_profile_summary") %in% names(payload)), "Payload should include the AOT-grade view model sections.")
expect_true(length(payload$hero_metrics) > 0, "Hero metrics should be populated.")
expect_true(length(payload$domain_cards) == 2L, "Domain cards should be derived from source domains.")
expect_true(length(payload$catalog_rows) == 2L, "Catalog rows should be derived from source rows.")
expect_true(length(payload$column_profile_rows) == 2L, "Column profile rows should be included in the public payload.")
expect_true(length(payload$column_top_value_rows) == 1L, "Column top value rows should be included in the public payload.")
expect_true(length(payload$column_profile_summary) > 0, "Column profile summaries should be included in the public payload.")
expect_true(length(payload$npu_cards$summary) > 0, "NPU cards should include dictionary summary rows.")
expect_true(length(payload$npu_cards$top_vectors) > 0, "NPU cards should include vector summaries.")
expect_true(length(payload$npu_cards$observed_vectors) > 0, "NPU cards should include observed lab usage.")
expect_true(length(payload$registry_cards) == 1L, "Registry cards should be generated when registry panels exist.")
expect_true("DaMyDa" %in% names(payload$registry_cards), "Registry cards should be keyed by registry name.")
expect_true(any(vapply(payload$panel_groups, function(row) identical(row$panel_name, "damyda_clinical_profile"), logical(1))), "Panel groups should include generated panel metadata.")

view_json <- atlas_to_json(list(
  hero_metrics = payload$hero_metrics,
  domain_cards = payload$domain_cards,
  catalog_rows = payload$catalog_rows,
  qa_items = payload$qa_items,
  npu_cards = payload$npu_cards,
  registry_cards = payload$registry_cards,
  panel_groups = payload$panel_groups,
  column_profile_rows = payload$column_profile_rows,
  column_top_value_rows = payload$column_top_value_rows
))
expect_false(grepl("patientid", view_json, ignore.case = TRUE), "View-model payload sections should not expose id-like field names.")
