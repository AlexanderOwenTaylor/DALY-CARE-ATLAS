root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expect_stops <- function(expr, pattern) {
  err <- tryCatch(
    {
      force(expr)
      NULL
    },
    error = function(e) conditionMessage(e)
  )
  expect_true(!is.null(err), "Expected expression to stop.")
  expect_true(grepl(pattern, err, ignore.case = TRUE), paste("Expected error matching", pattern, "but got", err))
}

map_path <- semantic_unmapped_entity_map_path(root)
expect_file(map_path)

entity_map <- read_semantic_unmapped_entity_map(root, validate = TRUE)
expect_equal(nrow(entity_map), 3902L, "Semantic unmapped entity map should preserve all supplied rows.")
expect_true(all(semantic_unmapped_entity_map_columns() %in% names(entity_map)), "Semantic unmapped entity map should have the required columns.")
expect_true(!any(duplicated(entity_map$entity_scope_key)), "Semantic unmapped entity map keys should be unique.")
for (field in c("fill_preferred_label", "fill_denotation_definition", "fill_clinical_domain", "fill_specimen_or_context", "fill_unit_or_value_type")) {
  expect_true(all(nzchar(trimws(entity_map[[field]]))), paste("Semantic unmapped entity map should not have blank", field))
}

bad <- entity_map
bad$entity_scope_key <- NULL
expect_stops(validate_semantic_unmapped_entity_map(bad), "missing")

bad <- entity_map
bad$entity_scope_key[[2]] <- bad$entity_scope_key[[1]]
expect_stops(validate_semantic_unmapped_entity_map(bad), "duplicate")

bad <- entity_map
bad$fill_preferred_label[[1]] <- "010101-1234"
expect_stops(validate_semantic_unmapped_entity_map(bad), "CPR")

bad <- entity_map
bad$fill_preferred_label[[1]] <- "2020-01-01"
expect_stops(validate_semantic_unmapped_entity_map(bad), "date")

bad <- entity_map
bad$fill_preferred_label[[1]] <- "HÃ¸jde"
expect_stops(validate_semantic_unmapped_entity_map(bad), "mojibake")

semantic <- build_semantic_outputs(project_root = root, min_cell_count = 5)
overlay <- semantic$unmapped_entity_overlay
conflicts <- semantic$mapping_conflicts
code_map <- semantic$code_map
dictionary <- semantic$dictionary

expect_true(nrow(overlay) == 3902L, "Overlay output should preserve one row per supplied entity.")
expect_true(nrow(conflicts) > 0, "Overlay should emit a conflict audit where supplied labels disagree with existing labels.")
expect_true(all(is.na(code_map$n_patients[grepl("^curated_overlay_", code_map$semantic_id)])), "Curated overlay code rows must not expose patient counts.")
expect_true(all(is.na(dictionary$n_patients[dictionary$data_shape == "semantic_overlay"])), "Curated overlay dictionary rows must not expose patient counts.")

expect_overlay <- function(scope_key, code, label_pattern) {
  row <- overlay[overlay$entity_scope_key == scope_key, , drop = FALSE]
  expect_true(nrow(row) == 1L, paste("Expected overlay row for", scope_key))
  expect_true(grepl(label_pattern, row$fill_preferred_label[[1]], ignore.case = TRUE), paste("Expected readable label for", scope_key))
  expect_true(row$overlay_action[[1]] == "wired_overlay", paste("Expected non-conflicting overlay to be wired:", scope_key))
  expect_true(any(code_map$code == code & grepl(label_pattern, code_map$code_name, ignore.case = TRUE)), paste("Expected code map label for", scope_key))
}

expect_overlay("ATC:C03AB01", "C03AB01", "Bendroflumethiazide")
expect_overlay("SNOMED/pathology:T06002", "T06002", "Cristamarv")
expect_overlay("SKS/procedure:BWGC1", "BWGC1", "BWGC1")
expect_overlay("ICD10/SKS_diagnosis:DD479B", "DD479B", "Monoclonal B-cell lymphocytosis")
expect_overlay("Danish_pathology_AEKI_Ki67_percent_code:AEKI030", "AEKI030", "Ki-67 coded percent value: 30%")

for (code in c("NPU02593", "NPU04998", "NPU19748")) {
  expect_true(any(conflicts$entity_code == code & conflicts$mapping_status == "conflict_pending_review"), paste("Expected NPU conflict audit row for", code))
}
expect_true(any(code_map$code == "NPU02593" & code_map$clinical_concept_id == "creatinine"), "NPU02593 should keep the current primary creatinine mapping under conflict policy.")
expect_false(any(code_map$code == "NPU02593" & grepl("Leukocytes", code_map$code_name, fixed = TRUE)), "NPU02593 overlay leukocyte label must not silently replace current primary label.")
expect_true(any(code_map$code == "NPU04998" & code_map$clinical_concept_id == "crp"), "NPU04998 should keep the current primary CRP mapping under conflict policy.")
expect_false(any(code_map$code == "NPU04998" & grepl("Creatininium", code_map$code_name, fixed = TRUE)), "NPU04998 overlay creatinine label must not silently replace current primary label.")
expect_true(any(code_map$code == "NPU19748" & code_map$clinical_variable == "Leukocytes"), "NPU19748 should keep the current primary leukocyte mapping under conflict policy.")
expect_false(any(code_map$code == "NPU19748" & grepl("C-reactive protein", code_map$code_name, fixed = TRUE)), "NPU19748 overlay CRP label must not silently replace current primary label.")

curated_code_rows <- code_map[grepl("^curated_overlay_", code_map$semantic_id), , drop = FALSE]
curated_dictionary_rows <- dictionary[dictionary$data_shape == "semantic_overlay", , drop = FALSE]
expect_true(all(is.na(curated_code_rows$n_patients)), "Curated overlay code rows must leave n_patients blank.")
expect_true(all(is.na(curated_dictionary_rows$n_patients)), "Curated overlay dictionary rows must leave n_patients blank.")
expect_false(any(
  !is.na(overlay$n_patients) &
    overlay$n_patients %in% suppressWarnings(as.numeric(entity_map$observed_count_sum_across_surfaces_do_not_treat_as_unique))
), "Cross-surface observed-count sums must not be exposed as overlay patient counts.")
