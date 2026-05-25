root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
visual_qa <- paste(readLines(file.path(root, "scripts", "visual_qa_atlas.js"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

expect_contains <- function(haystack, needle, message = NULL) {
  expect_true(grepl(needle, haystack, fixed = TRUE), message %||% paste("Expected text:", needle))
}

expect_not_contains <- function(haystack, needle, message = NULL) {
  expect_false(grepl(needle, haystack, fixed = TRUE), message %||% paste("Unexpected text:", needle))
}

read_snapshot_numbers <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  keys <- c(
    "top_level_tabs", "sub_tabs", "panels", "details_sections",
    "source_catalog_rows", "data_dictionary_rows", "resource_reconciliation_rows",
    "payload_top_level_keys", "mcl_triangle_data_point_rows", "confluence_rows",
    "output_csv_files", "rendered_export_links"
  )
  out <- setNames(integer(length(keys)), keys)
  for (key in keys) {
    pattern <- paste0("\"", key, "\"\\s*:\\s*([0-9]+)")
    hit <- regexec(pattern, txt, perl = TRUE)
    value <- regmatches(txt, hit)[[1]]
    if (length(value) < 2) stop(paste("Snapshot key missing:", key), call. = FALSE)
    out[[key]] <- as.integer(value[[2]])
  }
  out
}

count_pattern <- function(text, pattern) {
  hit <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(hit, -1L)) 0L else length(hit)
}

before <- read_snapshot_numbers(file.path(root, "qa_pdsa_cycle3", "preservation_snapshot_before.json"))
after <- read_snapshot_numbers(file.path(root, "qa_pdsa_cycle3", "preservation_snapshot_after.json"))
for (key in names(before)) {
  expect_true(after[[key]] >= before[[key]], paste("Cycle 3 snapshot must not decrease:", key))
}

actual_static <- c(
  top_level_tabs = count_pattern(template, "class=\"tab-page"),
  sub_tabs = count_pattern(template, "class=\"sub-tab"),
  panels = count_pattern(template, "class=\"panel"),
  details_sections = count_pattern(template, "<details"),
  rendered_export_links = count_pattern(template, "data-export-view")
)
for (key in names(actual_static)) {
  expect_true(actual_static[[key]] >= after[[key]], paste("Rendered template count below Cycle 3 snapshot:", key))
}

for (path in c(
  "qa_pdsa_cycle3/AUDIENCE_UI_ASSESSMENT.md",
  "qa_pdsa_cycle3/PDSA_CYCLE3_PLAN.md",
  "qa_pdsa_cycle3/PDSA_CYCLE3_STUDY_TEMPLATE.md",
  "qa_pdsa_cycle3/PDSA_CYCLE3_STUDY_RESULTS_TEMPLATE.md",
  "qa_pdsa_cycle3/visual_readability_review.md"
)) {
  expect_file(file.path(root, path))
}

expect_contains(template, "function hBarResolveScaleMode", "h-bar renderer should have explicit scale resolver.")
expect_contains(template, "scaleMode", "h-bar renderer should accept scaleMode.")
expect_contains(template, "denominator_id", "auto scaling should consider denominator_id.")
for (field in c("source_name", "evidence_file", "clinical_concept_id", "raw_column", "denominator_scope", "profile_scope", "count_scope")) {
  expect_contains(template, field, paste("auto scaling should consider:", field))
}
expect_contains(template, "Bars scaled by count within this displayed list.")
expect_contains(template, "Bars scaled by percent within this field.")

hbar_label_block <- regmatches(template, regexpr("\\.h-bar \\.label \\{[^}]+\\}", template, perl = TRUE))
expect_true(length(hbar_label_block) == 1L, "Expected one .h-bar .label CSS block.")
expect_not_contains(hbar_label_block, "text-overflow", "h-bar labels should not default to ellipsis.")
expect_not_contains(hbar_label_block, "white-space: nowrap", "h-bar labels should wrap.")
expect_contains(template, ".label-secondary", "h-bar rows should support secondary lineage labels.")

for (prefix in c(
  "ATC medication signals -",
  "SKS procedure/treatment signals -",
  "SMR / in-hospital medication -"
)) {
  expect_not_contains(template, prefix, paste("Primary labels should not rely on repeated prefix:", prefix))
}
expect_contains(template, "treatmentDisplayLabel", "Treatment should still use a display label helper.")
expect_contains(template, "renderlessTreatmentContext(row) || rawLineageHint", "Treatment context should move to secondary metadata.")

expect_contains(template, "friendlyAtlasLabelMap", "Cycle 3 should define friendly raw-label mappings.")
expect_contains(template, "Reg_Knogleforandringer", "Raw DaMyDa field names should remain reachable.")
expect_contains(template, "Bone lesions recorded", "DaMyDa bone fields should have human-facing labels.")
expect_contains(template, "Treatment contacts - diagnosis", "Long raw treatment-contact headings should be humanized.")
expect_contains(template, "Raw aliases:", "Grouped display rows should preserve raw alias lineage.")

expect_contains(template, "microbiologyCanonicalAliasLabels", "Microbiology alias display map should exist.")
for (label in c("Rigshospitalet / RGH", "Herlev / HER", "Hvidovre / HVH", "Region Hovedstaden", "Bacteria", "Fungus")) {
  expect_contains(template, label, paste("Expected microbiology display alias:", label))
}
expect_contains(template, "groupDisplayBarRows", "Alias grouping should be display-row derived and scope guarded.")
expect_contains(template, "hBarScopeKey", "Display grouping should include source/field/denominator scope.")

expect_contains(template, "renderPathologyTextAvailabilitySection", "Pathology free-text availability should be status-first.")
expect_not_contains(template, "renderPathologyLayerSection(\"microscopy_text\"", "Microscopy free-text should not use code-bar inventory renderer.")
expect_not_contains(template, "renderPathologyLayerSection(\"conclusion_text\"", "Conclusion free-text should not use code-bar inventory renderer.")
expect_contains(template, "Coded pathology rows are shown separately", "Text route should point to separate coded inventory sections.")
expect_contains(template, "Unmapped SNOMED/pathology code:", "Unmapped pathology codes should show the full code.")

expect_contains(template, "Source summary card not generated in this aggregate output; code-level signals may be available below.", "Empty source summary should not contradict populated code bars.")
expect_contains(template, "renderCollapsedRawLineage", "Raw lineage must remain available.")
expect_contains(template, "rawLineageHint", "Primary display rows should retain raw/source hints.")

expect_contains(visual_qa, "reviewer_readability_report.json", "Visual QA should write a reviewer-readability report.")
for (needle in c("clippedHBarLabels", "ellipsisLabelCount", "repeatedPrefixes", "emptyBeforeBars", "rawHeadingCandidates")) {
  expect_contains(visual_qa, needle, paste("Visual QA should audit:", needle))
}

cat("PDSA Cycle 3 reviewer readability regression tests passed\n")
