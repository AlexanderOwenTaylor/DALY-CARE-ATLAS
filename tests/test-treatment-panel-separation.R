root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

extract_regex <- function(pattern, message) {
  match <- regmatches(template, regexpr(pattern, template, perl = TRUE))
  expect_true(length(match) == 1L && nzchar(match), message)
  match
}
expect_contains <- function(haystack, needle, message) {
  expect_true(grepl(needle, haystack, fixed = TRUE), message)
}

treatment_panel <- extract_regex(
  "function renderTreatmentPanel\\(\\)[\\s\\S]*?const imagingLayerSpecs",
  "Treatment panel renderer should be present."
)
treatment_context <- extract_regex(
  "function treatmentSourceContext\\(row\\)[\\s\\S]*?function treatmentCodeRows",
  "Treatment source-context classifier should be present."
)
treatment_labels <- extract_regex(
  "const treatmentKnownCodeLabels[\\s\\S]*?function treatmentBarRows",
  "Treatment code label renderer should be present."
)
antineoplastic_terms <- extract_regex(
  "const antineoplasticDrugTerms = \\[[\\s\\S]*?\\];",
  "Antineoplastic treatment term list should be explicit."
)
supportive_terms <- extract_regex(
  "const supportiveMedicationTerms = \\[[\\s\\S]*?\\];",
  "Supportive medication term list should be explicit."
)
cross_source_section <- extract_regex(
  "renderSectionCard\\(\"Technical cross-source treatment matrix\"[\\s\\S]*?renderSectionCard\\(\"SP treatment plans\"",
  "Raw cross-source treatment matrix should be separated into a technical disclosure."
)

for (needle in c(
  "Treatment source availability matrix",
  "Treatment evidence layers",
  "SP treatment plans",
  "SKS/procedure signals",
  "Antineoplastic / immunomodulatory ATC signals",
  "Supportive medication signals",
  "SMR / in-hospital medication",
  "Outpatient prescriptions",
  "Registry treatment fields",
  "Curated treatment cohorts"
)) {
  expect_contains(treatment_panel, needle, paste("Treatment panel should include section:", needle))
}

for (supportive in c("aciclovir", "paracetamol", "pantoprazole", "trimethoprim", "sulfamethoxazole", "potassium", "sodium")) {
  expect_contains(supportive_terms, supportive, paste("Supportive medication terms should include", supportive))
  expect_false(
    grepl(supportive, antineoplastic_terms, fixed = TRUE),
    paste("Supportive medication should not appear in the antineoplastic overview:", supportive)
  )
}

expect_contains(treatment_context, 'ctx("sks", "SKS procedure/treatment signals"', "SKS rows should be classified as procedure/treatment signals.")
expect_contains(treatment_context, "Procedure or treatment-code signal; not an ATC drug exposure or medication administration row.", "SKS/BWGC procedure evidence should not be described as medication.")
expect_contains(treatment_labels, '"BWGC": "Radiotherapy procedure family"', "BWGC should remain radiotherapy/procedure evidence.")
expect_false(grepl("BWGC", antineoplastic_terms, fixed = TRUE), "BWGC radiotherapy should not appear in antineoplastic drug terms.")
expect_false(grepl("BWGC", supportive_terms, fixed = TRUE), "BWGC radiotherapy should not appear in supportive medication terms.")

expect_contains(cross_source_section, "<details class=\"lineage-block\">", "Cross-source treatment matrix should be in a technical disclosure.")
expect_contains(cross_source_section, "Raw cross-source treatment matrix and aggregate rows", "Raw cross-source treatment matrix should be labelled technical/raw.")
expect_contains(treatment_panel, "Registry treatment context: disease registries provide curated treatment", "Registry treatment fields should be labelled as registry indicators, not medication administration.")
expect_contains(treatment_panel, "outpatient prescription rows only; not administered medication", "Outpatient prescriptions should be separated from administered medication.")
