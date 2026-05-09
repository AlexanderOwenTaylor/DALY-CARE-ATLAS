root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

dictionary <- load_npu_consensus_dictionary(project_root = root)
expect_true(all(c(
  "npu_code", "consensus_vector", "system", "status_labterm", "clinical_role",
  "used_in_v08_classification", "vector_consensus_basis", "resolution_note"
) %in% names(dictionary)), "NPU dictionary loader should expose normalized required columns.")
expect_equal(nrow(dictionary), 155L, "Committed NPU dictionary should contain 155 consensus rows.")
expect_equal(length(unique(dictionary$npu_code)), 155L, "Committed NPU dictionary should contain unique NPU codes.")
expect_equal(length(unique_nonblank(dictionary$consensus_vector)), 45L, "Committed NPU dictionary should contain 45 nonblank consensus vectors.")

bad_path <- tempfile(fileext = ".tsv")
writeLines(c(
  "Code\tConsensus vector\tSystem\tStatus (LabTerm)\tClinical role\tUsed in V08 classification\tVector consensus basis\tResolution note",
  "NPU04998\tCREATININE_CODES\tP\tActive\tCreatinine\tV7\tbasis\t",
  "NPU04998\tCREATININE_CODES\tP\tActive\tCreatinine\tV7\tbasis\t"
), bad_path)
duplicate_failed <- FALSE
tryCatch(load_npu_consensus_dictionary(path = bad_path), error = function(e) duplicate_failed <<- TRUE)
expect_true(duplicate_failed, "NPU dictionary loader should reject duplicate codes.")

blank_path <- tempfile(fileext = ".tsv")
writeLines(c(
  "Code\tConsensus vector\tSystem\tStatus (LabTerm)\tClinical role\tUsed in V08 classification\tVector consensus basis\tResolution note",
  "\tCREATININE_CODES\tP\tActive\tCreatinine\tV7\tbasis\t"
), blank_path)
blank_failed <- FALSE
tryCatch(load_npu_consensus_dictionary(path = blank_path), error = function(e) blank_failed <<- TRUE)
expect_true(blank_failed, "NPU dictionary loader should reject blank codes.")

summary_panel <- panel_npu_dictionary_summary(dictionary)
vector_panel <- panel_npu_dictionary_vectors(dictionary)
expect_true("dictionary_codes" %in% summary_panel$metric, "Dictionary summary should include total code count.")
expect_true(any(vector_panel$consensus_vector == "CREATININE_CODES" & vector_panel$n_dictionary_codes >= 2), "Vector panel should summarize dictionary codes by consensus vector.")

labs <- data.frame(
  analysiscode = c("NPU04998", "NPU04998", "npu01443", "not-a-code", "NPU99999"),
  result = c(10, 11, 2, 99, 7),
  stringsAsFactors = FALSE
)
usage <- panel_npu_lab_usage_by_vector(labs, "labs", dictionary, min_cell_count = 2L)
unmatched_suppressed <- panel_npu_lab_unmatched_codes(labs, "labs", dictionary, min_cell_count = 2L)
unmatched_visible <- panel_npu_lab_unmatched_codes(labs, "labs", dictionary, min_cell_count = 1L)
coverage <- panel_lab_codes(labs, "labs", min_cell_count = 1L)
expect_true(any(usage$consensus_vector == "CREATININE_CODES" & usage$n_observed == 2L), "Observed dictionary NPUs should aggregate by consensus vector.")
expect_false(any(usage$consensus_vector == "CALCIUM_TOTAL_CODES"), "Vector usage below the minimum cell count should be suppressed.")
expect_equal(nrow(unmatched_suppressed), 0L, "Unmatched observed NPU codes below the minimum cell count should be suppressed.")
expect_true(any(unmatched_visible$npu_code == "NPU99999"), "Unmatched NPU-like codes should be visible only when the minimum cell count allows them.")
expect_false(any(coverage$lab_code == "NOTACODE"), "Non-NPU lab values should not pollute NPU coverage panels.")
