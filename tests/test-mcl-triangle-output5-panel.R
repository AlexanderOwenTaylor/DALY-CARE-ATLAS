root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

fixture_dir <- mcl_count_default_output5_fixture_dir(root)
expect_true(nzchar(fixture_dir), "Output(5) fixture directory should be present.")
expect_true(file.exists(file.path(fixture_dir, "mcl_triangle_execution_summary.csv")), "Output(5) fixture should include execution summary.")

current_dir <- tempfile("accepted_current_outputs_")
dir.create(current_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(list.files(fixture_dir, full.names = TRUE), current_dir, overwrite = TRUE)
current_resolved <- mcl_count_resolve_standalone_output_source(
  project_root = root,
  outputs_dir = current_dir,
  count_output_zip = "",
  count_output_dir = ""
)
expect_equal(current_resolved$metadata$source_type[[1]], "current_atlas_outputs", "Resolver should prefer fresh accepted atlas outputs before the bundled fixture.")
expect_equal(current_resolved$outputs_dir, normalizePath(current_dir, winslash = "/", mustWork = FALSE), "Resolver should select the current accepted output directory.")

explicit_resolved <- mcl_count_resolve_standalone_output_source(
  project_root = root,
  outputs_dir = tempfile("ignored_current_outputs_"),
  count_output_zip = "",
  count_output_dir = current_dir
)
expect_equal(explicit_resolved$metadata$source_type[[1]], "explicit_dir", "Explicit MCL_TRIANGLE_COUNT_OUTPUT_DIR should still override automatic current/fallback selection.")

resolved <- mcl_count_resolve_standalone_output_source(
  project_root = root,
  outputs_dir = tempfile("empty_current_outputs_"),
  count_output_zip = "",
  count_output_dir = ""
)
expect_equal(resolved$metadata$source_type[[1]], "bundled_output5_fixture", "Resolver should fall back to the bundled Output(5) fixture.")
expect_equal(resolved$metadata$mode[[1]], "production_aggregate", "Output(5) fixture should be production aggregate.")
expect_equal(resolved$metadata$acceptance_status[[1]], "accepted_no_atlas_input", "Output(5) fixture should carry accepted_no_atlas_input.")
expect_equal(resolved$metadata$failed_queries[[1]], 0L, "Output(5) fixture should have zero failed queries.")

counts <- mcl_count_read_outputs(resolved$outputs_dir)
dp <- function(id) {
  rows <- counts$data_point_counts
  rows[rows$data_point_id == id, , drop = FALSE]
}
metric <- function(rows, key, value) rows[rows[[key]] == value, , drop = FALSE]
display <- function(row) as.character(row$distinct_person_count_display[[1]] %||% "")

expect_equal(display(dp("all_lyfo_mcl")), "1,417", "All LYFO MCL count should match Output(5).")
expect_equal(display(dp("younger_mcl_proxy_age_le_65")), "411", "Age <=65 younger proxy count should match Output(5).")
expect_equal(display(dp("ibrutinib_exposure")), "115", "Expanded Ibrutinib count should match Output(5).")
expect_equal(display(dp("ki67_aeki")), "37", "Main Ki-67 AEKI count should match Output(5).")

all_both <- metric(counts$treatment_strategy_strata_counts, "denominator", "all_lyfo_mcl")
all_both <- all_both[all_both$ibrutinib_status == "yes" & all_both$asct_hdt_first_line_status == "yes", , drop = FALSE]
all_asct_only <- counts$treatment_strategy_strata_counts[
  counts$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl" &
    counts$treatment_strategy_strata_counts$ibrutinib_status == "unknown_or_no_evidence" &
    counts$treatment_strategy_strata_counts$asct_hdt_first_line_status == "yes",
  ,
  drop = FALSE
]
all_ib_only <- counts$treatment_strategy_strata_counts[
  counts$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl" &
    counts$treatment_strategy_strata_counts$ibrutinib_status == "yes" &
    counts$treatment_strategy_strata_counts$asct_hdt_first_line_status == "unknown_or_no_evidence",
  ,
  drop = FALSE
]
all_neither <- counts$treatment_strategy_strata_counts[
  counts$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl" &
    counts$treatment_strategy_strata_counts$ibrutinib_status == "unknown_or_no_evidence" &
    counts$treatment_strategy_strata_counts$asct_hdt_first_line_status == "unknown_or_no_evidence",
  ,
  drop = FALSE
]
expect_equal(display(all_both), "14", "All-MCL Ibrutinib + ASCT/HDT cell should be 14.")
expect_equal(display(all_asct_only), "322", "All-MCL ASCT/HDT-only cell should be 322.")
expect_equal(display(all_ib_only), "101", "All-MCL Ibrutinib-only cell should be 101.")
expect_equal(display(all_neither), "980", "All-MCL neither-evidence cell should be 980.")

young_rows <- counts$treatment_strategy_strata_counts[counts$treatment_strategy_strata_counts$denominator == "younger_mcl_proxy_age_le_65", , drop = FALSE]
young_both <- young_rows[young_rows$ibrutinib_status == "yes" & young_rows$asct_hdt_first_line_status == "yes", , drop = FALSE]
young_asct_only <- young_rows[young_rows$ibrutinib_status == "unknown_or_no_evidence" & young_rows$asct_hdt_first_line_status == "yes", , drop = FALSE]
young_ib_only <- young_rows[young_rows$ibrutinib_status == "yes" & young_rows$asct_hdt_first_line_status == "unknown_or_no_evidence", , drop = FALSE]
young_neither <- young_rows[young_rows$ibrutinib_status == "unknown_or_no_evidence" & young_rows$asct_hdt_first_line_status == "unknown_or_no_evidence", , drop = FALSE]
expect_equal(display(young_both), "11", "Age <=65 Ibrutinib + ASCT/HDT cell should be 11.")
expect_equal(display(young_asct_only), "258", "Age <=65 ASCT/HDT-only cell should be 258.")
expect_equal(display(young_ib_only), "17", "Age <=65 Ibrutinib-only cell should be 17.")
expect_equal(display(young_neither), "125", "Age <=65 neither-evidence cell should be 125.")
expect_equal(
  sum(as.integer(c(display(young_both), display(young_ib_only)))),
  28L,
  "Age <=65 expanded Ibrutinib should be derived as 11 + 17 = 28."
)

ki67_known <- metric(counts$ki67_aeki_person_counts, "metric", "ki67_aeki_known")
ki67_ge30 <- metric(counts$ki67_aeki_person_counts, "metric", "ki67_aeki_ge_threshold")
ki67_ge50 <- metric(counts$ki67_aeki_person_counts, "metric", "ki67_aeki_ge_50")
expect_equal(display(ki67_known), "37", "Ki-67 AEKI known should be 37.")
expect_equal(display(ki67_ge30), "20", "Ki-67 AEKI >=30 should be 20.")
expect_equal(display(ki67_ge50), "13", "Ki-67 AEKI >=50 should be 13.")

signpost <- mcl_triangle_pathology_ki67_signpost(counts)
expect_true(nrow(signpost) == 1L, "Pathology Ki-67 signpost should be built from Output(5).")
expect_equal(signpost$mcl_aeki_known[[1]], "37", "Signpost should expose MCL Ki-67 known count.")
expect_true(grepl("SDS_pato", signpost$table_name[[1]], fixed = TRUE), "Signpost should surface SDS_pato.")
expect_true(grepl("c_snomedkode", signpost$column_name[[1]], fixed = TRUE), "Signpost should surface c_snomedkode.")
expect_true(grepl("AEKI", signpost$code_family[[1]], fixed = TRUE), "Signpost should surface AEKI.")

mcl_payload <- mcl_triangle_empty_payload()
mcl_payload$cohort_counts <- counts
mcl_payload$standalone_output_source <- resolved$metadata
mcl_payload$pathology_ki67_signpost <- signpost
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
expect_true(length(payload$mcl_triangle_feasibility$cohort_counts$data_point_counts) >= nrow(counts$data_point_counts), "Payload should not drop Output(5) data-point rows.")
expect_true(length(payload$mcl_triangle_feasibility$standalone_output_source) == 1L, "Payload should expose standalone output metadata.")
expect_true(length(payload$mcl_triangle_feasibility$pathology_ki67_signpost) == 1L, "Payload should expose pathology Ki-67 signpost.")

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
  "accepted production aggregate",
  "fallback reference count",
  "fallback/reference count",
  "Fallback/reference counts stay visible and labelled",
  "feasibility/readiness review for study planning",
  "does not estimate treatment effects or recommend ASCT/HDT decisions",
  "Cohort construction looks feasible; risk-adapted TRIANGLE emulation still needs validation.",
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
