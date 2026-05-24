root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

extract_regex <- function(pattern, message) {
  match <- regmatches(template, regexpr(pattern, template, perl = TRUE))
  expect_true(length(match) == 1L && nzchar(match), message)
  match
}

triangle_section <- extract_regex(
  "function renderPathologyKi67Signpost\\(\\)[\\s\\S]*?function patobankKi67Metric",
  "TRIANGLE Ki-67 pathology signpost renderer should be present."
)
failed_closed_branch <- extract_regex(
  "if \\(qaState\\.status === \"failed-closed\"\\) \\{[\\s\\S]*?\\n        return `\\n          <div class=\"callout\"><strong>PATOBANK coded Ki-67 percent evidence coverage:",
  "Failed-closed PATOBANK Ki-67 rendering branch should be present."
)

expect_true(grepl("Semantic output QA", template, fixed = TRUE), "Atlas must include a visible Semantic output QA panel.")
expect_true(grepl("empty-output-error", template, fixed = TRUE), "Semantic QA must expose header-only PATOBANK Ki-67 output failures.")
expect_true(grepl("ui_output_inconsistent", template, fixed = TRUE), "Semantic QA must expose UI/output inconsistency failures.")
expect_true(grepl("failed-closed", template, fixed = TRUE), "Semantic QA must expose failed-closed PATOBANK Ki-67 state.")
expect_true(grepl("not available patients", template, fixed = TRUE) == FALSE, "Rendered template must not contain the trust-breaking phrase 'not available patients'.")

expect_true(grepl("feasibility-only", triangle_section, fixed = TRUE), "TRIANGLE Ki-67 cards must say feasibility-only.")
expect_true(grepl("not general PATOBANK coverage", triangle_section, fixed = TRUE), "TRIANGLE Ki-67 cards must say not general PATOBANK coverage.")
expect_true(grepl("not general PATOBANK Ki-67 coverage", template, fixed = TRUE), "TRIANGLE Ki-67 copy must not generalize feasibility evidence to PATOBANK-wide coverage.")
expect_true(grepl("candidate-only", triangle_section, fixed = TRUE), "TRIANGLE Ki-67 cards must keep the candidate-only badge.")
expect_true(grepl("not complete capture", triangle_section, fixed = TRUE), "TRIANGLE Ki-67 cards must state not complete capture.")
expect_true(grepl("raw text not emitted", triangle_section, fixed = TRUE), "TRIANGLE Ki-67 cards must state raw text is not emitted.")

expect_true(grepl('production_ki67_available", value: "no"', failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 output should render production_ki67_available=no.")
expect_true(grepl('coverage denominator", value: "not computed"', failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 output should render denominator as not computed.")
expect_false(grepl("patient coverage", failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 must not render patient denominator KPIs as coverage.")
expect_false(grepl("investigation coverage", failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 must not render investigation denominator KPIs as coverage.")
expect_false(grepl("specimen/material coverage", failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 must not render specimen denominator KPIs as coverage.")
expect_false(grepl("Valid normalized AEKI code counts and parsed percent distribution", failed_closed_branch, fixed = TRUE), "Failed-closed PATOBANK Ki-67 must not render code-count distributions as valid production counts.")
