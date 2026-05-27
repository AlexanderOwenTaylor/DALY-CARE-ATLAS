root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

template <- read_text(file.path(root, "inst", "templates", "DALYCARE_atlas.html"))
html_r <- read_text(file.path(root, "R", "html.R"))
run_atlas_r <- read_text(file.path(root, "R", "run_atlas.R"))
semantic_r <- read_text(file.path(root, "R", "semantic_dictionary.R"))
visual_qa <- read_text(file.path(root, "scripts", "visual_qa_atlas.js"))

semantic <- build_semantic_outputs(project_root = root, min_cell_count = 5)
overlay <- semantic$unmapped_entity_overlay
lookup <- semantic$overlay_lookup
conflicts <- semantic$mapping_conflicts
code_map <- semantic$code_map
dictionary <- semantic$dictionary

expect_equal(nrow(overlay), 3902L, "Cycle 4 should preserve all supplied overlay rows.")
expect_equal(sum(overlay$overlay_action == "wired_overlay"), 3805L, "Cycle 4 should preserve wired overlay count.")
expect_equal(sum(overlay$overlay_action == "conflict_pending_review"), 97L, "Cycle 4 should preserve conflict-pending count.")
expect_equal(nrow(lookup), 3902L, "All overlay rows should be available to the display resolver.")
expect_equal(sum(lookup$promotion_eligible == "yes"), 3805L, "Only wired overlay rows should be promotion-eligible.")
expect_equal(sum(lookup$mapping_status == "conflict_pending_review"), 97L, "Conflict rows should remain visible in lookup but not eligible.")
semantic_visible_text <- paste(
  lookup$display_label,
  lookup$notes,
  overlay$fill_preferred_label,
  overlay$fill_denotation_definition,
  code_map$code_name,
  dictionary$clinical_variable,
  collapse = "\n"
)
for (marker in c("â", "Ã", "�")) {
  expect_false(grepl(marker, semantic_visible_text, fixed = TRUE), paste("Semantic overlay display text should not contain mojibake marker:", marker))
}

expect_false(any(code_map$source_name == "semantic_unmapped_entity_map", na.rm = TRUE), "Code map source display must not expose the overlay TSV as a data source.")
expect_false(any(dictionary$source_name == "semantic_unmapped_entity_map", na.rm = TRUE), "Dictionary source display must not expose the overlay TSV as a data source.")

expect_label <- function(code, pattern) {
  rows <- code_map[!is.na(code_map$code) & toupper(code_map$code) == toupper(code), , drop = FALSE]
  expect_true(nrow(rows) > 0L, paste("Expected code-map row for", code))
  hay <- paste(rows$code_name, rows$clinical_variable, rows$notes, collapse = " || ")
  expect_true(grepl(pattern, hay, ignore.case = TRUE), paste("Expected promoted label for", code, "matching", pattern))
}

expect_label("DNK35131", "e-GFR")
expect_label("NPU18162", "Erythrocyte volumes")
expect_label("NPU18282", "Eosinophilocytes")
expect_label("NPU01459", "Carbamide")
expect_label("NPU03688", "Urate")
expect_label("C03AB01", "Bendroflumethiazide")
expect_label("DD479B", "Monoclonal B-cell lymphocytosis")
expect_label("AEKI030", "Ki-67 coded percent value: 30%")

for (code in c("NPU02593", "NPU04998", "NPU19748")) {
  expect_true(any(conflicts$entity_code == code & conflicts$mapping_status == "conflict_pending_review"), paste("Expected conflict audit row for", code))
}
expect_true(any(code_map$code == "NPU02593" & code_map$clinical_concept_id == "creatinine"), "NPU02593 should keep current creatinine mapping.")
expect_false(any(code_map$code == "NPU02593" & grepl("Leukocytes", code_map$code_name, fixed = TRUE)), "NPU02593 conflict label must not be promoted.")
expect_true(any(code_map$code == "NPU04998" & code_map$clinical_concept_id == "crp"), "NPU04998 should keep current CRP mapping.")
expect_false(any(code_map$code == "NPU04998" & grepl("Creatininium", code_map$code_name, fixed = TRUE)), "NPU04998 conflict label must not be promoted.")
expect_true(any(code_map$code == "NPU19748" & code_map$clinical_variable == "Leukocytes"), "NPU19748 should keep current leukocyte mapping.")
expect_false(any(code_map$code == "NPU19748" & grepl("C-reactive protein", code_map$code_name, fixed = TRUE)), "NPU19748 conflict label must not be promoted.")

empty_sources <- data.frame(
  table_name = character(),
  load_status = character(),
  stringsAsFactors = FALSE
)
empty_columns <- data.frame(
  table_name = character(),
  column_name = character(),
  stringsAsFactors = FALSE
)
empty_checks <- data.frame(
  severity = character(),
  table_name = character(),
  check_id = character(),
  message = character(),
  stringsAsFactors = FALSE
)

payload <- atlas_payload(
  run_id = "cycle4-test",
  generated_at = "now",
  sources = empty_sources,
  columns = empty_columns,
  checks = empty_checks,
  panels = list(),
  semantic_dictionary = dictionary,
  semantic_code_map = code_map,
  semantic_unmapped_entity_overlay = overlay,
  semantic_overlay_lookup = lookup,
  semantic_mapping_conflicts = conflicts
)
expect_true("semantic_overlay_lookup_rows" %in% names(payload), "Payload should include an uncapped overlay lookup.")
expect_equal(length(payload$semantic_overlay_lookup_rows), 3902L, "Payload lookup should include all overlay rows.")
expect_true(length(payload$semantic_code_map_rows) <= 5000L, "Code-map payload may remain capped.")
expect_true(length(payload$semantic_dictionary_rows) <= 5000L, "Dictionary payload may remain capped.")

for (needle in c(
  "semantic_overlay_lookup_rows",
  "semanticOverlayLookupRows",
  "semanticOverlayResolve",
  "semanticOverlayDisplayForRow",
  "semanticOverlaySourceForDisplay"
)) {
  expect_true(grepl(needle, paste(html_r, template, collapse = "\n"), fixed = TRUE), paste("Expected overlay resolver wiring:", needle))
}
expect_true(grepl("atlas_semantic_overlay_lookup.csv", run_atlas_r, fixed = TRUE), "Run outputs should write the overlay lookup CSV.")
expect_true(grepl("semantic_overlay_promotion_report.json", visual_qa, fixed = TRUE), "Visual QA should emit Cycle 4 overlay-promotion report.")
expect_true(grepl("visiblePseudoSource", visual_qa, fixed = TRUE), "Visual QA should flag visible overlay pseudo-source leakage.")

for (path in c(
  "qa_pdsa_cycle4/AUDIENCE_UI_ASSESSMENT.md",
  "qa_pdsa_cycle4/PDSA_CYCLE4_PLAN.md",
  "qa_pdsa_cycle4/PDSA_CYCLE4_STUDY_TEMPLATE.md",
  "qa_pdsa_cycle4/PDSA_CYCLE4_STUDY_RESULTS_TEMPLATE.md",
  "qa_pdsa_cycle4/semantic_overlay_promotion_audit.md",
  "qa_pdsa_cycle4/preservation_snapshot_before.json",
  "qa_pdsa_cycle4/preservation_snapshot_after.json"
)) {
  expect_file(file.path(root, path))
}

cat("PDSA Cycle 4 semantic overlay promotion tests passed\n")
