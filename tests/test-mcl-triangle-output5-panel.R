root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

fixture_dir <- mcl_count_default_output5_fixture_dir(root)
expect_false(nzchar(fixture_dir), "Bundled Output(5) fixture should be optional and absent in a clean source checkout.")

resolved <- mcl_count_resolve_standalone_output_source(
  project_root = root,
  outputs_dir = tempfile("empty_current_outputs_"),
  count_output_zip = "",
  count_output_dir = ""
)
expect_equal(resolved$outputs_dir, "", "Resolver should not select a standalone output directory when none is supplied.")
expect_equal(resolved$metadata$source_type[[1]], "not_available", "Resolver should expose an explicit not-available metadata row.")
expect_false(isTRUE(resolved$metadata$selected[[1]]), "Resolver metadata should mark the source as unselected.")

counts <- mcl_count_read_outputs(resolved$outputs_dir)
expect_true(is.list(counts), "Count reader should return a shaped list for absent output directories.")
expect_equal(nrow(counts$data_point_counts), 0L, "Absent standalone outputs should produce empty data-point counts.")
expect_equal(nrow(counts$treatment_strategy_strata_counts), 0L, "Absent standalone outputs should produce empty strategy counts.")

mcl_payload <- mcl_triangle_empty_payload()
mcl_payload$cohort_counts <- counts
mcl_payload$standalone_output_source <- resolved$metadata
payload <- atlas_payload(
  "test-run",
  "2026-05-22T00:00:00+0200",
  sources = data.frame(table_name = "SDS_pato", source = "SDS_pato", domain = "Pathology", load_status = "ok", stringsAsFactors = FALSE),
  columns = data.frame(table_name = "SDS_pato", column_name = "c_snomedkode", stringsAsFactors = FALSE),
  checks = data.frame(severity = character(), table_name = character(), check_id = character(), message = character(), stringsAsFactors = FALSE),
  panels = list(),
  mcl_triangle_feasibility = mcl_payload
)
expect_true("cohort_counts" %in% names(payload$mcl_triangle_feasibility), "Payload should include MCL/TRIANGLE cohort_counts.")
expect_true(length(payload$mcl_triangle_feasibility$standalone_output_source) == 1L, "Payload should expose standalone output metadata.")

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
for (needle in c(
  "TRIANGLE-lite feasibility template",
  "PICO",
  "Target estimand",
  "landmark",
  "immortal-time bias",
  "confounding by indication",
  "reusable",
  "feasibility pre-study",
  "descriptive feasibility only",
  "fallback reference count",
  "fallback/reference count",
  "Fallback/reference counts stay visible and labelled",
  "feasibility/readiness review for study planning",
  "does not estimate treatment effects or recommend ASCT/HDT decisions",
  "Ki-67 proliferation index",
  "SDS_pato",
  "c_snomedkode",
  "AEKI",
  "age <=65 younger proxy",
  "expanded ibrutinib ever-observed",
  "risk-adapted answerability not yet validated"
)) {
  expect_true(grepl(tolower(needle), tolower(template), fixed = TRUE), paste("Template should include:", needle))
}
for (needle in c(
  "proves treatment efficacy",
  "ASCT can safely be omitted",
  "transplant eligibility is observed",
  "standard-risk classifiability is validated",
  "validated text Ki-67 extraction"
)) {
  expect_false(grepl(needle, template, fixed = TRUE), paste("Template should not include overclaim:", needle))
}
