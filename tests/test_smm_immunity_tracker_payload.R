root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

outputs <- build_smm_immunity_tracker_feasibility_outputs(project_root = root, min_cell_count = 5L)
expect_true("cohort_readiness" %in% names(outputs), "Scaffold should include cohort readiness.")
expect_true("tracker_status" %in% names(outputs), "Scaffold should include tracker-wide status rows.")
expect_true(any(outputs$tracker_status$status_key == "tracker_status" & outputs$tracker_status$status_value == "partial"), "Tracker-wide status should remain partial in scaffold mode.")
expect_true(any(outputs$cohort_readiness$cohort_id == "cvm_jama_smm_day90_harmonized"), "Scaffold should include CVM day-90 harmonized cohort.")
expect_true(any(outputs$cohort_readiness$cohort_id == "cvm_jama_smm_diagnosis_origin" & outputs$cohort_readiness$tracker_role == "secondary reproduction/readiness view"), "CVM diagnosis-origin view should be secondary.")
expect_false(any(grepl("survival before progression", capture.output(str(outputs)), ignore.case = TRUE)), "SMM output copy should avoid survival-before-progression language.")

payload <- atlas_payload(
  run_id = "synthetic-smm",
  generated_at = "2026-06-07T00:00:00Z",
  sources = data.frame(table_name = character(), source_type = character(), load_status = character(), stringsAsFactors = FALSE),
  columns = data.frame(stringsAsFactors = FALSE),
  checks = data.frame(table_name = character(), check_id = character(), severity = character(), message = character(), stringsAsFactors = FALSE),
  panels = list(),
  smm_immunity_tracker = outputs
)
expect_true("smm_immunity_tracker" %in% names(payload), "Payload should expose smm_immunity_tracker.")
payload_cohort_ids <- vapply(
  payload$smm_immunity_tracker$cohort_readiness,
  function(row) as.character(row$cohort_id %||% ""),
  character(1)
)
expect_true(any(payload_cohort_ids == "aot_wp5_original_smm"), "Payload should include SMM cohort readiness rows.")

manifest_meta <- output_manifest_artifact_metadata("smm_immunity_tracker_landmark_progression_signal", "outputs/smm_immunity_tracker_landmark_progression_signal.csv")
expect_equal(manifest_meta$module[[1]], "smm_immunity_tracker", "Manifest metadata should classify SMM outputs under the SMM module.")
expect_equal(manifest_meta$artifact_role[[1]], "canonical_production", "SMM aggregate signal file should be canonical production metadata.")
expect_true(isTRUE(manifest_meta$production_output[[1]]), "SMM aggregate signal file should be marked production output.")

html <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE), collapse = "\n")
for (needle in c(
  "SMM immunity tracker",
  "smm-immunity-tracker-dashboard",
  "function renderSmmImmunityTrackerPanel",
  "payload.smm_immunity_tracker",
  "smoldering",
  "smouldering",
  "infection burden",
  "AOT",
  "WP5",
  "CVM",
  "JAMA Oncology",
  "This panel does not establish that infections cause progression"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Expected HTML to contain:", needle))
}
expect_false(grepl("survival before progression", html, ignore.case = TRUE), "HTML should avoid survival-before-progression wording.")
expect_true(grepl("time to progression", html, ignore.case = TRUE), "HTML should use time-to-progression language.")
expect_true(grepl("death as competing event", html, ignore.case = TRUE), "HTML should mention death as competing event.")

paths <- smm_immunity_tracker_write_outputs(outputs, tempfile("smm_outputs_"))
expect_true(any(grepl("smm_immunity_tracker_bias_warnings.csv", unlist(paths), fixed = TRUE)), "Writer should emit SMM bias warnings.")
expect_true(any(grepl("smm_immunity_tracker_landmark_progression_signal.csv", unlist(paths), fixed = TRUE)), "Writer should emit landmark progression signal.")
expect_true(any(grepl("smm_immunity_tracker_status.csv", unlist(paths), fixed = TRUE)), "Writer should emit SMM tracker status.")

cat("SMM Immunity Tracker payload tests passed\n")
