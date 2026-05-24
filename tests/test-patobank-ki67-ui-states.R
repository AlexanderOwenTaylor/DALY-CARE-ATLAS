root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

expect_contains <- function(haystack, needle, message) {
  expect_true(grepl(needle, haystack, fixed = TRUE), message)
}

extract_regex <- function(pattern, message) {
  match <- regmatches(template, regexpr(pattern, template, perl = TRUE))
  expect_true(length(match) == 1L && nzchar(match), message)
  match
}

qa_state_function <- extract_regex(
  "function patobankKi67QaState\\(\\)[\\s\\S]*?function patobankKi67DenominatorDisplay",
  "PATOBANK Ki-67 QA-state function should be present in the atlas template."
)
semantic_qa_function <- extract_regex(
  "function renderSemanticOutputQaSummary\\(\\)[\\s\\S]*?function renderSpecialManualResourcesCard",
  "Semantic output QA summary renderer should be present in the atlas template."
)
failed_closed_branch <- extract_regex(
  "if \\(qaState\\.status === \"failed-closed\"\\) \\{[\\s\\S]*?\\n        return `\\n          <div class=\"callout\"><strong>PATOBANK coded Ki-67 percent evidence coverage:",
  "Failed-closed PATOBANK Ki-67 rendering branch should be testable."
)
qa_error_branch <- extract_regex(
  "if \\(qaState\\.status === \"empty-output-error\" \\|\\| qaState\\.status === \"ui_output_inconsistent\"\\) \\{[\\s\\S]*?\\n        if \\(qaState\\.status === \"failed-closed\"\\)",
  "QA-error PATOBANK Ki-67 rendering branch should be testable."
)

expect_contains(qa_state_function, 'status: "failed-closed"', "Failed-closed QA state should be explicit.")
expect_true(
  grepl('status: "failed-closed"[\\s\\S]*?atlasReviewable: true[\\s\\S]*?productionKi67Available: false[\\s\\S]*?shippableWithoutKnownSemanticFailures: false', qa_state_function, perl = TRUE),
  "Failed-closed PATOBANK Ki-67 should render reviewable but production_ki67_available=no and not fully shippable."
)
expect_true(
  grepl('status: "ui_output_inconsistent"[\\s\\S]*?atlasReviewable: false[\\s\\S]*?productionKi67Available: false[\\s\\S]*?shippableWithoutKnownSemanticFailures: false', qa_state_function, perl = TRUE),
  "UI/output inconsistent Ki-67 state should render not reviewable and not shippable."
)
expect_true(
  grepl('status: "success"[\\s\\S]*?atlasReviewable: true[\\s\\S]*?productionKi67Available: true[\\s\\S]*?shippableWithoutKnownSemanticFailures: true', qa_state_function, perl = TRUE),
  "Successful PATOBANK Ki-67 aggregate state should render production_ki67_available=yes."
)

expect_contains(semantic_qa_function, 'atlas_reviewable', "Semantic QA summary should expose atlas_reviewable.")
expect_contains(semantic_qa_function, 'production_ki67_available', "Semantic QA summary should expose production_ki67_available.")
expect_contains(semantic_qa_function, 'shippable_without_known_semantic_failures', "Semantic QA summary should expose shippability.")
expect_contains(semantic_qa_function, 'ki67State.productionKi67Available ? "yes" : "no"', "Successful Ki-67 QA state should drive production_ki67_available=yes in the semantic QA panel.")

expect_contains(failed_closed_branch, 'production_ki67_available", value: "no"', "Failed-closed PATOBANK Ki-67 card should state production_ki67_available=no.")
expect_contains(failed_closed_branch, 'coverage denominator", value: "not computed"', "Failed-closed PATOBANK Ki-67 must not invent coverage denominators.")
expect_false(grepl("patient coverage", failed_closed_branch, fixed = TRUE), "Failed-closed Ki-67 must not render successful patient coverage KPI.")
expect_false(grepl("investigation coverage", failed_closed_branch, fixed = TRUE), "Failed-closed Ki-67 must not render successful investigation coverage KPI.")
expect_false(grepl("specimen/material coverage", failed_closed_branch, fixed = TRUE), "Failed-closed Ki-67 must not render successful specimen/material coverage KPI.")
expect_false(grepl("Valid normalized AEKI code counts and parsed percent distribution", failed_closed_branch, fixed = TRUE), "Failed-closed Ki-67 must not render code-count distributions as valid production counts.")

expect_contains(qa_error_branch, 'atlas_reviewable", value: "no"', "QA-error Ki-67 branch should be not reviewable.")
expect_contains(qa_error_branch, 'production_ki67_available", value: "no"', "QA-error Ki-67 branch should not be production available.")
expect_contains(qa_error_branch, 'shippable_without_known_semantic_failures", value: "no"', "QA-error Ki-67 branch should not be shippable.")

successful_fixture <- patobank_ki67_outputs_from_frame(data.frame(
  patientid = c("P1", "P2", "P3"),
  k_inst = c("A", "A", "B"),
  k_rekvnr = c("R1", "R2", "R3"),
  k_matnr = c("M1", "M2", "M3"),
  k_sekvensnr = c("S1", "S2", "S3"),
  c_snomedkode = c("AEKI030", "AEKI050", "AEKI100"),
  stringsAsFactors = FALSE
), min_cell_count = 1L)
expect_true(
  any(successful_fixture$code_counts$count_status == "aggregate_count_available"),
  "Successful aggregate Ki-67 fixture should contain valid aggregate code-count rows for the success UI state."
)
