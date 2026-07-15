root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)

expect_true(exists("mcl_triangle_apply_public_suppression", mode = "function"), "MCL/TRIANGLE publication suppression helper should exist.")
expect_true("suppressed_complementary_cell" %in% mcl_count_status_levels(), "Complementary suppression should be a declared public count status.")

outputs <- list(
  data_point_counts = data.frame(
    data_point_id = "all_lyfo_mcl",
    distinct_person_count_display = "31",
    n_people = 31,
    count_status = "production_aggregate_count_available",
    validation_status = "validated",
    stringsAsFactors = FALSE
  ),
  age_proxy_counts = data.frame(
    metric = c("total_mcl_age_le_65", "total_mcl_age_gt_65", "total_mcl_age_missing_uncomputable"),
    denominator = "all_lyfo_mcl",
    distinct_person_count_display = c("7", "13", "11"),
    n_people = c(7, 13, 11),
    count_status = "production_aggregate_count_available",
    validation_status = "validated",
    stringsAsFactors = FALSE
  ),
  small_cell_suppression_audit = mcl_triangle_empty_small_cell_suppression_audit()
)

repaired <- mcl_triangle_apply_public_suppression(outputs, min_cell_count = 10L)
expect_equal(
  repaired$age_proxy_counts$distinct_person_count_display[repaired$age_proxy_counts$metric == "total_mcl_age_le_65"],
  "<10",
  "Primary small-cell suppression should replace the public display."
)
expect_true(
  is.na(repaired$age_proxy_counts$n_people[repaired$age_proxy_counts$metric == "total_mcl_age_le_65"]),
  "Primary suppression should clear the public numeric field."
)
expect_equal(
  repaired$age_proxy_counts$distinct_person_count_display[repaired$age_proxy_counts$metric == "total_mcl_age_missing_uncomputable"],
  "suppressed for complementary privacy",
  "Complementary privacy should hide the smallest eligible visible sibling."
)
expect_true(
  is.na(repaired$age_proxy_counts$n_people[repaired$age_proxy_counts$metric == "total_mcl_age_missing_uncomputable"]),
  "Complementary suppression should clear the sibling numeric field."
)
expect_equal(
  repaired$age_proxy_counts$acceptance_status[repaired$age_proxy_counts$metric == "total_mcl_age_missing_uncomputable"],
  "accepted suppressed aggregate row",
  "Complementary suppression should update the row-level acceptance label."
)
expect_equal(repaired$data_point_counts$distinct_person_count_display[[1]], "31", "Parent should remain visible when an eligible sibling can be hidden.")
expect_true(all(c("acceptance_status", "suppression_status") %in% names(repaired$age_proxy_counts)), "Published count rows should carry acceptance and suppression truth fields.")

audit <- repaired$small_cell_suppression_audit
expect_equal(nrow(audit), 2L, "Primary and complementary suppression should each emit one safe audit row.")
expect_true(all(audit$hidden_value_recorded == "no hidden value recorded"), "Suppression audit must explicitly omit hidden values.")
audit_text <- paste(unlist(audit, use.names = FALSE), collapse = " ")
expect_false(grepl("(^|[^0-9])7([^0-9]|$)", audit_text), "Primary hidden value must not appear in the audit.")
expect_false(grepl("(^|[^0-9])11([^0-9]|$)", audit_text), "Complementary hidden sibling value must not appear in the audit.")

no_sibling <- outputs
no_sibling$data_point_counts$distinct_person_count_display <- "15"
no_sibling$data_point_counts$n_people <- 15
no_sibling$age_proxy_counts$distinct_person_count_display <- c("7", "", "")
no_sibling$age_proxy_counts$n_people <- c(7, NA, NA)
no_sibling$small_cell_suppression_audit <- mcl_triangle_empty_small_cell_suppression_audit()
parent_repaired <- mcl_triangle_apply_public_suppression(no_sibling, min_cell_count = 10L)
expect_equal(
  parent_repaired$data_point_counts$distinct_person_count_display[[1]],
  "suppressed for complementary privacy",
  "Parent total should be hidden when no eligible visible sibling exists."
)
expect_true(is.na(parent_repaired$data_point_counts$n_people[[1]]), "Complementary parent suppression should clear its public numeric field.")

ki67_outputs <- list(
  ki67_aeki_person_counts = data.frame(
    denominator = "all_lyfo_mcl",
    metric = c("ki67_aeki_known", "ki67_aeki_ge_threshold", "ki67_aeki_ge_50", "ki67_aeki_missing_not_found"),
    distinct_person_count_display = c("30", "12", "7", "21"),
    n_people = c(30, 12, 7, 21),
    count_status = "production_aggregate_count_available",
    validation_status = "validated",
    stringsAsFactors = FALSE
  ),
  small_cell_suppression_audit = mcl_triangle_empty_small_cell_suppression_audit()
)
ki67_repaired <- mcl_triangle_apply_public_suppression(ki67_outputs, min_cell_count = 10L)
expect_equal(
  ki67_repaired$ki67_aeki_person_counts$distinct_person_count_display[ki67_repaired$ki67_aeki_person_counts$metric == "ki67_aeki_ge_threshold"],
  "suppressed for complementary privacy",
  "Nested Ki-67 hierarchy should hide the nearest visible parent of a suppressed threshold."
)

failing_hook <- list(
  mcl_triangle_count_sets = function(min_cell_count = 5L) {
    stop("token=supersecret patient=1234567890")
  }
)
failed_outputs <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = tempfile("mcl-triangle-failed-hook-"),
  mode = "production_aggregate",
  db_adapter = failing_hook,
  min_cell_count = 5L,
  atlas_output_dir = "",
  atlas_output_zip = "",
  run_ki67_source_inventory = FALSE
)
failed_text <- paste(failed_outputs$failed_query_audit$error_message_sanitized, collapse = " ")
expect_true(grepl("<redacted>", failed_text, fixed = TRUE), "Failed secure aggregate hook should retain a sanitized diagnostic.")
expect_false(grepl("supersecret", failed_text, fixed = TRUE), "Sanitized hook failure must not expose a token.")
expect_false(grepl("1234567890", failed_text, fixed = TRUE), "Sanitized hook failure must not expose a patient-like identifier.")
expect_false(any(failed_outputs$data_point_counts$count_status %in% mcl_count_available_statuses()), "Failed aggregate hook must never substitute available or provisional counts.")

cat("MCL/TRIANGLE privacy tests passed\n")
