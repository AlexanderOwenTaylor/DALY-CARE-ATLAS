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

npu_display <- extract_regex("function npuDisplayConcept\\(row\\)[\\s\\S]*?function renderCodeDiscoveryCards", "NPU Detective display-concept renderer should be present.")
microbiology_gate <- extract_regex("const microbiologySourceAliasKeys[\\s\\S]*?function microbiologyRawRows", "Microbiology source-alias and role gate should be present.")
pathology_labels <- extract_regex("const pathologyCodeLabels[\\s\\S]*?function pathologyLayer", "Pathology/SNOMED label renderer should be present.")
imaging_labels <- extract_regex("const imagingCodeLabels[\\s\\S]*?function imagingLayer", "Imaging/SKS/UX label renderer should be present.")
treatment_labels <- extract_regex("const treatmentKnownCodeLabels[\\s\\S]*?function renderTreatmentSourceCards", "Treatment code label renderer should be present.")

expect_contains(npu_display, "Display concept", "NPU Detective should group by display concept.")
expect_contains(npu_display, "Codes included", "NPU Detective should show included NPU codes separately.")
expect_contains(npu_display, "Technical vectors", "NPU Detective should preserve internal vectors only in technical disclosure.")
expect_contains(npu_display, "Unmapped NPU code", "Unmapped NPU values should be explicitly labelled.")
expect_false(grepl("renal_creatinine", template, fixed = TRUE), "Internal NPU label renal_creatinine must not appear as a literal audience-facing label.")
expect_false(grepl("LEUKOCYTE_CODES", template, fixed = TRUE), "Internal NPU label LEUKOCYTE_CODES must not appear as a literal audience-facing label.")

for (alias in c("HVH", "HER", "RHM", "RGH", "SSI", "VEM", "AUH", "OUM", "NJA", "STM")) {
  expect_contains(microbiology_gate, alias, paste("Microbiology source aliases should be explicitly classified:", alias))
}
expect_contains(microbiology_gate, 'wanted.has("microbiology_antibiotic")) return role === "antibiotic" && !isSourceAlias', "Microbiology antibiotic panels must exclude hospital/lab source aliases.")
expect_contains(microbiology_gate, 'wanted.has("microbiology_susceptibility") || wanted.has("microbiology_susceptibility_result")) return role === "susceptibility" && !isSourceAlias', "Microbiology susceptibility panels must exclude hospital/lab source aliases.")
expect_contains(microbiology_gate, 'wanted.has("microbiology_lab_source")) return role === "source" || isSourceAlias', "Microbiology hospital/lab source aliases should be routed to source coverage.")

for (needle in c(
  '"T06002": "Bone marrow biopsy"',
  '"T0X000": "Blood"',
  '"T06000": "Bone marrow"',
  '"P28260": "Flow cytometry"',
  '"M97323": "Diffuse large B-cell lymphoma morphology"',
  '"M98233": "CLL morphology"',
  "Unmapped SNOMED/pathology code"
)) {
  expect_contains(pathology_labels, needle, paste("Pathology main labels should translate or mark code:", needle))
}

for (needle in c(
  "UXCC00: \"CT thorax\"",
  "UXCD00: \"CT abdomen\"",
  "UXZ10: \"CT\"",
  "UXZ11: \"MRI\"",
  "BWGC1: \"Radiotherapy fraction\"",
  "BWGC4A: \"Electron beam therapy\"",
  "Unmapped SKS/UX/BWGC code"
)) {
  expect_contains(imaging_labels, needle, paste("Imaging/radiotherapy labels should translate or mark code:", needle))
}

for (needle in c(
  '"BWGC": "Radiotherapy procedure family"',
  '"BWGC1": "Radiotherapy fraction"',
  '"BWGC4A": "Electron beam therapy"',
  '"L01XE27": "Ibrutinib"',
  '"L01XX52": "Venetoclax"',
  '"L01XC02": "Rituximab"',
  '"L01XC15": "Daratumumab"',
  "Unmapped ${codeSystem} code"
)) {
  expect_contains(treatment_labels, needle, paste("Treatment code labels should translate or mark code:", needle))
}

expect_contains(template, "Primary taxonomy: Laboratory & Diagnostics; cross-linked here for clinical planning.", "Clinical Data cross-links for Microbiology and Pathology should carry the exact Laboratory & Diagnostics caveat.")
expect_contains(template, 'tab: "laboratory", sub: "lab-microbiology"', "Microbiology search/routes should prefer Laboratory & Diagnostics.")
expect_contains(template, 'tab: "laboratory", sub: "lab-pathology"', "Pathology/PATOBANK search/routes should prefer Laboratory & Diagnostics.")
expect_contains(template, 'tab: "laboratory", sub: "lab-imaging"', "Imaging/radiotherapy search/routes should prefer Laboratory & Diagnostics.")
