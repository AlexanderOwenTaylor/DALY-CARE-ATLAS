root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

template <- read_text(file.path(root, "inst", "templates", "DALYCARE_atlas.html"))
html_r <- read_text(file.path(root, "R", "html.R"))
semantic_r <- read_text(file.path(root, "R", "semantic_dictionary.R"))

expect_true(grepl("Laboratory & Diagnostics", template, fixed = TRUE), "Rendered atlas should expose Laboratory & Diagnostics taxonomy.")
for (needle in c(
  "data-sub=\"lab-imaging\"",
  "data-sub=\"lab-microbiology\"",
  "data-sub=\"lab-pathology\"",
  "laboratory-imaging-cards",
  "laboratory-microbiology-cards",
  "laboratory-pathology-cards"
)) {
  expect_true(grepl(needle, template, fixed = TRUE), paste("Laboratory & Diagnostics should wire diagnostics pane:", needle))
}
expect_true(grepl("Laboratory & Diagnostics", html_r, fixed = TRUE), "R view-model navigation should use Laboratory & Diagnostics.")
expect_true(grepl("section = \"Laboratory & Diagnostics\"", semantic_r, fixed = TRUE), "Semantic panel links should classify diagnostics under Laboratory & Diagnostics.")

expect_false(grepl("not available patients", template, ignore.case = TRUE), "Rendered template must not contain 'not available patients'.")
expect_false(grepl("not available patients", html_r, ignore.case = TRUE), "R renderer code must not contain 'not available patients'.")
expect_true(grepl("patient denominator", template, fixed = TRUE) && grepl("not computed for this aggregate block", template, fixed = TRUE), "Registry blocks should use precise patient-denominator wording.")

expect_true(grepl("function npuDisplayConcept", template, fixed = TRUE), "NPU Detective should have a semantic display-concept helper.")
expect_true(grepl("\"Display concept\"", template, fixed = TRUE) && grepl("\"Codes included\"", template, fixed = TRUE), "NPU Detective should show display concepts and included codes.")
expect_false(grepl("row.surface || row.consensus_vector || row.npu_code", template, fixed = TRUE), "NPU Detective must not use raw surface/vector as the primary label fallback.")
expect_true(grepl("Internal candidate-set names and raw surfaces are retained only in the technical disclosure", template, fixed = TRUE), "NPU Detective should demote raw technical labels.")

expect_true(grepl("microbiologySourceAliasKeys", template, fixed = TRUE), "Microbiology renderer should know source/hospital aliases.")
expect_true(grepl("function microbiologyColumnRole", template, fixed = TRUE), "Microbiology renderer should classify column roles before display.")
expect_true(grepl("function microbiologyAllowedForConcept", template, fixed = TRUE), "Microbiology renderer should filter concept panels by role.")
for (alias in c("HVH", "HER", "RHM", "RGH", "Rigshospitalet", "Herlev", "Hvidovre")) {
  expect_true(grepl(alias, template, fixed = TRUE), paste("Microbiology source alias should be explicitly guarded:", alias))
}

expect_true(grepl("Radiotherapy procedure evidence is available through SKS/BWGC procedure codes. SP radiotherapy plan/report detail is not available in the current aggregate block.", template, fixed = TRUE), "Radiotherapy wording should distinguish BWGC procedure evidence from SP plan/report detail.")
expect_true(grepl("imagingCodeLabels", template, fixed = TRUE) && grepl("BWGC1: \"Radiotherapy fraction\"", template, fixed = TRUE), "Imaging renderer should translate UX/BWGC procedure codes.")

expect_true(grepl("function damydaImagingBoneLabel", template, fixed = TRUE), "DaMyDa imaging/bone renderer should group raw fields into concepts.")
for (concept in c("PET/CT", "DEXA", "Scintigraphy", "Bone lesion type", "Bone lesions")) {
  expect_true(grepl(concept, template, fixed = TRUE), paste("DaMyDa imaging/bone renderer should expose concept:", concept))
}

expect_true(grepl("Antineoplastic / immunomodulatory ATC signals", template, fixed = TRUE), "Treatment renderer should separate antineoplastic/immunomodulatory ATC signals.")
expect_true(grepl("Supportive medication signals", template, fixed = TRUE), "Treatment renderer should separate supportive medication signals.")
expect_false(grepl("Named treatment/supportive medicines", template, fixed = TRUE), "Treatment renderer must not flatten treatment and supportive medicines into one primary list.")

ae <- intToUtf8(0x00C6)
ki67_caveat <- paste0(
  "This is structured PATOBANK/SDS AEKI/", ae,
  "KI code-family evidence found in the TRIANGLE feasibility pre-study route. It is not a complete Ki-67 capture strategy, not a patient denominator, not a clinical distribution, and not validated against full pathology text."
)
expect_true(grepl(ki67_caveat, template, fixed = TRUE), "TRIANGLE Ki-67 panel should show the full candidate-only caveat.")
for (badge in c("candidate-only", "feasibility-only", "not complete capture", "raw text not emitted")) {
  expect_true(grepl(badge, template, fixed = TRUE), paste("TRIANGLE Ki-67 panel should include badge:", badge))
}
expect_true(grepl("This is not all Ki-67 in DALY-CARE", template, fixed = TRUE), "TRIANGLE Ki-67 panel should state that it is not all Ki-67 in DALY-CARE.")
