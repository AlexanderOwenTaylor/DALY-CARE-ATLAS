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

payload <- atlas_payload("test-run", "2026-05-09T00:00:00+0200", sources, columns, checks, panels, run_summary = run_summary)
expect_true(all(c("hero_metrics", "domain_cards", "catalog_rows", "qa_items", "registry_cards", "panel_groups") %in% names(payload)), "Payload should include the AOT-grade view model sections.")
expect_true(length(payload$hero_metrics) > 0, "Hero metrics should be populated.")
expect_true(length(payload$domain_cards) == 2L, "Domain cards should be derived from source domains.")
expect_true(length(payload$catalog_rows) == 2L, "Catalog rows should be derived from source rows.")
expect_true(length(payload$registry_cards) == 1L, "Registry cards should be generated when registry panels exist.")
expect_true("DaMyDa" %in% names(payload$registry_cards), "Registry cards should be keyed by registry name.")
expect_true(any(vapply(payload$panel_groups, function(row) identical(row$panel_name, "damyda_clinical_profile"), logical(1))), "Panel groups should include generated panel metadata.")

view_json <- atlas_to_json(list(
  hero_metrics = payload$hero_metrics,
  domain_cards = payload$domain_cards,
  catalog_rows = payload$catalog_rows,
  qa_items = payload$qa_items,
  registry_cards = payload$registry_cards,
  panel_groups = payload$panel_groups
))
expect_false(grepl("patientid", view_json, ignore.case = TRUE), "View-model payload sections should not expose id-like field names.")
