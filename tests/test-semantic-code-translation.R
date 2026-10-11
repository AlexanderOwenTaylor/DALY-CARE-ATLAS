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
treatment_labels <- extract_regex("function treatmentDisplayLabel[\\s\\S]*?function renderTreatmentSourceCards", "Treatment code label renderer should be present.")

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
  '"T06002": "Iliac crest bone marrow"',
  '"T0X000": "Blood"',
  '"T06000": "Bone marrow"',
  '"P28260": "Bone marrow examination"',
  '"M97323": "Multiple myeloma morphology code"',
  '"M98233": "Chronic lymphocytic leukemia morphology code"',
  "Unmapped SNOMED/pathology code"
)) {
  expect_contains(pathology_labels, needle, paste("Pathology main labels should translate or mark code:", needle))
}

for (needle in c(
  "UXCC00: \"CT of the thorax\"",
  "UXCD00: \"CT of the abdomen\"",
  "UXZ10: \"With intravenous contrast\"",
  "UXZ11: \"Without intravenous contrast\"",
  "BWGC1: \"Conventional external beam radiotherapy\"",
  "BWGC4A: \"Intensity-modulated radiotherapy (IMRT), image-guided radiotherapy (IGRT)\"",
  "Unmapped SKS/UX/BWGC code"
)) {
  expect_contains(imaging_labels, needle, paste("Imaging/radiotherapy labels should translate or mark code:", needle))
}

expect_contains(treatment_labels, "clinicalDisplayEntry('code',row.code_system,row.code || row.raw_code)", "Treatment names must use exact system-aware dictionary entries.")
expect_contains(treatment_labels, "Unmapped ${codeSystem} code", "Unknown treatment codes must remain explicit.")
dictionary <- read.csv(file.path(root, "config", "clinical-display-dictionary.csv"), stringsAsFactors = FALSE, fileEncoding = "UTF-8")
for (pair in list(c("ATC", "L01XC15", "Obinutuzumab"), c("ATC", "L01XK02", "Niraparib"), c("SKS", "BWHA169", "Treatment with vinblastine"))) {
  hit <- dictionary[dictionary$kind == "code" & dictionary$system == pair[1] & dictionary$code == pair[2], ]
  expect_equal(nrow(hit), 1L, "Corrected treatment code should have one exact definition.")
  expect_equal(hit$label, pair[3], "Treatment code must retain its verified meaning.")
}

expect_contains(template, "Primary taxonomy: Laboratory & Diagnostics; cross-linked here for clinical planning.", "Clinical Data cross-links for Microbiology and Pathology should carry the exact Laboratory & Diagnostics caveat.")
expect_contains(template, 'tab: "laboratory", sub: "lab-microbiology"', "Microbiology search/routes should prefer Laboratory & Diagnostics.")
expect_contains(template, 'tab: "laboratory", sub: "lab-pathology"', "Pathology/PATOBANK search/routes should prefer Laboratory & Diagnostics.")
expect_contains(template, 'tab: "laboratory", sub: "lab-imaging"', "Imaging/radiotherapy search/routes should prefer Laboratory & Diagnostics.")
