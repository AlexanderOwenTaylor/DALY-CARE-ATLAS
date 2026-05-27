root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

html <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
visual_qa <- paste(readLines(file.path(root, "scripts", "visual_qa_atlas.js"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

for (needle in c(
  "Start here — DALY-CARE internal briefing",
  "What this atlas is",
  "What can be used now",
  "What needs validation first",
  "What must not be concluded"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Cycle 2 briefing should include:", needle))
}

for (needle in c(
  "PI / senior investigator",
  "Data manager / QA",
  "Lymphoma researcher",
  "New employee onboarding",
  "Senior clinician / manager",
  "Recommended first tab:",
  "Next two useful tabs:",
  "Main caveat:"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Cycle 2 route cards should include:", needle))
}

for (needle in c(
  "Plasma cell disorders / MM",
  "Other lymphoproliferative disorders",
  "Data Manager command center",
  "New employee onboarding: first 3 safe tasks",
  "Clinician/manager print briefing"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Cycle 2 audience panel should include:", needle))
}

for (needle in c(
  "production aggregate",
  "profiled aggregate",
  "fallback/reference",
  "candidate mapping",
  "blocked/mapping gap",
  "special access",
  "descriptive feasibility only"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Trust legend should include:", needle))
}

for (needle in c(
  "overview-trust-legend",
  "clinical-feasibility-trust-legend",
  "dictionary-trust-legend",
  "source-catalog-trust-legend",
  "qa-trust-legend"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Trust legend container should exist:", needle))
}

for (needle in c(
  "Scope:",
  "feasibility/readiness review for study planning",
  "does not estimate treatment effects or recommend ASCT/HDT decisions",
  "Cohort construction looks feasible; risk-adapted TRIANGLE emulation still needs validation.",
  "Fallback/reference counts stay visible and labelled when production acceptance is absent."
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("MCL/TRIANGLE-lite warning should include:", needle))
}

for (needle in c(
  "pi:",
  "\"data manager\"",
  "\"source readiness\"",
  "feasibility:",
  "mbl:",
  "dd479b:",
  "mm:",
  "cll:",
  "lymphoma:",
  "\"chief doctor\"",
  "management:"
)) {
  expect_true(grepl(needle, tolower(html), fixed = TRUE), paste("Search synonyms should include:", needle))
}

for (needle in c(
  "{ name: \"laboratory_diagnostics\", tab: \"laboratory\", sub: \"lab-npu\" }",
  "{ name: \"npu_detective\", tab: \"laboratory\", sub: \"lab-npu\", search: \"NPU02319\" }",
  "{ name: \"microbiology\", tab: \"laboratory\", sub: \"lab-microbiology\" }",
  "{ name: \"pathology\", tab: \"laboratory\", sub: \"lab-pathology\" }",
  "print_briefing_desktop.png",
  "print_mode"
)) {
  expect_true(grepl(needle, visual_qa, fixed = TRUE), paste("Visual QA should include Cycle 2 target:", needle))
}

for (path in c(
  "qa_pdsa_cycle2/AUDIENCE_UI_ASSESSMENT.md",
  "qa_pdsa_cycle2/PDSA_CYCLE2_PLAN.md",
  "qa_pdsa_cycle2/PDSA_CYCLE2_STUDY_TEMPLATE.md",
  "qa_pdsa_cycle2/PDSA_CYCLE2_STUDY_RESULTS_TEMPLATE.md",
  "qa_pdsa_cycle2/preservation_snapshot_before.json",
  "qa_pdsa_cycle2/preservation_snapshot_after.json"
)) {
  expect_file(file.path(root, path))
}
