root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)

outputs <- build_ki67_discovery_outputs(
  project_root = root,
  include_reference_files = FALSE,
  column_profiles = data.frame(
    table_name = c("RKKP_LYFO", "SDS_pato", "SDS_pato"),
    column_name = c("Ki67_pct", "c_snomedkode", "patologi_tekst"),
    profile_kind = c("numeric", "categorical", "text"),
    domain = c("Registry", "Pathology", "Pathology"),
    stringsAsFactors = FALSE
  ),
  semantic_code_map = data.frame(
    source_name = "SDS_pato",
    object_name = "SDS_pato",
    code_system = "SNOMED_CT_REFERENCE",
    code = c("1255078008", "ÆKI020", "FY5016", "M0901L"),
    code_name = c(
      "Percent of cell nuclei positive for proliferation marker protein Ki-67 in primary malignant neoplasm by immunohistochemistry",
      "Ki-67 proliferationsindex / KI67 i %",
      "p16/Ki-67-positive cells detected",
      "too little material for p16/Ki-67"
    ),
    stringsAsFactors = FALSE
  ),
  sources = data.frame(
    table_name = c("SDS_pato", "t_mikro", "RKKP_LYFO"),
    source = c("pato", "t_mikro", "RKKP_LYFO"),
    domain = c("Pathology", "Pathology", "Registry"),
    load_status = "ok",
    stringsAsFactors = FALSE
  )
)

expect_true(nrow(outputs$search_inventory) > 0, "Ki-67 search inventory should be generated from aggregate metadata.")
expect_true(nrow(outputs$registry_field_candidates) > 0, "Ki-67 registry field candidates should be generated.")
expect_true(nrow(outputs$pathology_code_candidates) >= 2, "Ki-67 pathology code candidates should include external anchors.")
expect_true(nrow(outputs$text_pattern_candidates) > 0, "Ki-67 text pattern candidates should be generated.")
expect_true(all(c("display_in_ui", "ui_group", "ui_priority", "suppression_reason", "evidence_channel") %in% names(outputs$search_inventory)), "Ki-67 search inventory should carry UI display controls.")
expect_true(nrow(outputs$channel_summary) == 4, "Ki-67 channel summary should report the four evidence channels.")
expect_true(all(c("structured_registry_fields", "danish_pathology_code_evidence", "pathology_text_extraction_readiness", "source_only_search_space") %in% outputs$channel_summary$evidence_channel), "Ki-67 channel summary should include registry, pathology-code, text-readiness, and source-only channels.")
expect_true(nrow(outputs$aeki_validation_plan) > 0, "AEKI/ÆKI production validation plan should be generated.")
expect_true(nrow(outputs$aeki_code_counts) > 0, "AEKI/ÆKI code count placeholder should be generated.")
expect_true(nrow(outputs$text_validation_plan) > 0, "Ki-67 text validation plan should be generated.")
expect_true("source_space_hits" %in% names(outputs$channel_summary), "Ki-67 channel summary should report source-space hits separately from candidate hits.")

spec_path <- file.path(root, "clinical_questions", "ki67_extraction_spec.yml")
expect_file(spec_path)
spec <- paste(readLines(spec_path, warn = FALSE), collapse = "\n")
for (needle in c("Ki-67", "MIB-1", "proliferationsindeks", "1255078008", "1279926000")) {
  expect_true(grepl(needle, spec, fixed = TRUE), paste("Ki-67 extraction spec should include:", needle))
}
expect_true(grepl("ÆKIxxx", spec, fixed = TRUE), "Ki-67 extraction spec should document the Danish Patobank ÆKIxxx code pattern.")

patobank_cases <- c("ÆKI000" = 0, "ÆKI005" = 5, "ÆKI020" = 20, "ÆKI100" = 100, "AEKI020" = 20, "Aeki020" = 20, "Ã†KI020" = 20)
for (code in names(patobank_cases)) {
  expect_equal(ki67_parse_patobank_numeric_percent(code), patobank_cases[[code]], paste("Unexpected parsed Patobank Ki-67 percent for:", code))
}
for (code in c("ÆKI101", "ÆKI999", "ÆKI20", "ÆKI0200", "ÆK1020")) {
  expect_true(is.na(ki67_parse_patobank_numeric_percent(code)), paste("Malformed or out-of-range Patobank Ki-67 code should be rejected:", code))
}

patobank_rows <- outputs$pathology_code_candidates[outputs$pathology_code_candidates$code == "AEKI020", , drop = FALSE]
expect_true(nrow(patobank_rows) > 0, "ÆKI020 should be surfaced as a Danish Patobank Ki-67 pathology-code candidate.")
expect_equal(patobank_rows$evidence_strength[[1]], "strong_direct", "ÆKIxxx should be strong direct structured pathology-code evidence.")
expect_equal(patobank_rows$value_class[[1]] %||% "exact_numeric_percent", "exact_numeric_percent", "ÆKIxxx should be interpreted as exact numeric percent evidence.")
expect_true(isTRUE(patobank_rows$is_value_code[[1]]), "ÆKIxxx should be classified as a local value code.")

dual_rows <- outputs$pathology_code_candidates[outputs$pathology_code_candidates$code %in% c("FY5016", "M0901L"), , drop = FALSE]
expect_true(nrow(dual_rows) >= 2, "p16/Ki-67 dual-stain codes should be surfaced separately.")
expect_false(any(dual_rows$mcl_triangle_high_risk_ki67_numeric), "p16/Ki-67 dual-stain codes must not count as numeric MCL Ki-67 proliferation-index evidence.")

patterns <- ki67_percent_patterns()
for (pattern in patterns) {
  expect_true(!inherits(try(grepl(pattern, "Ki-67 20%", perl = TRUE), silent = TRUE), "try-error"), "Ki-67 regex patterns should compile.")
}

examples <- c(
  "Ki-67 20%" = "exact_numeric_percent",
  "Ki67: 20 %" = "exact_numeric_percent",
  "Ki67 ca. 20%" = "exact_numeric_percent",
  "Ki-67 cirka 20 %" = "exact_numeric_percent",
  "MIB-1 index 35%" = "exact_numeric_percent",
  "proliferationsindeks på 15%" = "exact_numeric_percent",
  "Ki-67 < 10%" = "inequality_percent",
  "Ki-67 5-10%" = "range_percent",
  "Ki-67 ikke angivet" = "unknown_or_not_stated",
  "Ki-67 positiv" = "qualitative_mention_only"
)
for (txt in names(examples)) {
  expect_equal(ki67_classify_value(txt), examples[[txt]], paste("Unexpected Ki-67 value class for:", txt))
}

expect_false(ki67_value_is_numeric_extractable(ki67_classify_value("Ki-67 150%")), "Percentages over 100 should not be extractable.")
expect_false(ki67_value_is_numeric_extractable(ki67_classify_value("Ki-67 2024")), "Years/dates should not be accepted as Ki-67 percentages.")
expect_false(ki67_value_is_numeric_extractable(ki67_classify_value("Ki-67 positiv")), "Qualitative Ki-67 mentions should not be extractable numeric percentages.")

source_only_outputs <- build_ki67_discovery_outputs(
  project_root = root,
  include_reference_files = FALSE,
  sources = data.frame(
    table_name = c("SDS_pato_a", "SDS_pato_b", "SDS_pato_c", "SDS_pato_d", "SDS_pato_e", "SDS_pato_f", "t_mikro", "RKKP_LYFO"),
    source = c("pato_a", "pato_b", "pato_c", "pato_d", "pato_e", "pato_f", "t_mikro", "RKKP_LYFO"),
    domain = c("Pathology", "Pathology", "Pathology", "Pathology", "Pathology", "Pathology", "Pathology", "Registry"),
    load_status = "ok",
    stringsAsFactors = FALSE
  )
)
expect_true(any(source_only_outputs$search_inventory$evidence_strength == "source_only"), "Pathology/LYFO source availability should be represented as source-only search space.")
expect_false(any(source_only_outputs$search_inventory$evidence_strength %in% c("strong_direct", "moderate_direct")), "Source-only hits must not count as direct Ki-67 evidence.")
source_only_rows <- source_only_outputs$search_inventory[source_only_outputs$search_inventory$evidence_strength == "source_only", , drop = FALSE]
expect_true(any(!source_only_rows$display_in_ui %in% TRUE), "Duplicate source-only rows should be suppressed from the concise UI.")
expect_true(all(source_only_rows$evidence_channel == "source_only_search_space"), "Source-only rows should be assigned to the source-space evidence channel.")
source_only_channel <- source_only_outputs$channel_summary[source_only_outputs$channel_summary$evidence_channel == "source_only_search_space", , drop = FALSE]
expect_equal(source_only_channel$candidate_hits[[1]], 0L, "Source-only search-space rows must not be counted as candidate evidence.")
expect_true(source_only_channel$source_space_hits[[1]] > 0L, "Source-only search-space rows should be counted in source_space_hits.")
registry_channel <- source_only_outputs$channel_summary[source_only_outputs$channel_summary$evidence_channel == "structured_registry_fields", , drop = FALSE]
expect_equal(registry_channel$candidate_hits[[1]], 0L, "Structured registry source-only rows should not be counted as candidate evidence.")
expect_true(registry_channel$source_space_hits[[1]] > 0L, "Structured registry source-only rows should be counted as source-space hits.")

empty_inventory <- mcl_triangle_empty_variable_inventory()
ki67_matrix <- mcl_triangle_build_readiness_matrix(empty_inventory, ki67_discovery = source_only_outputs)
ki67_row <- ki67_matrix[ki67_matrix$study_requirement == "Ki-67", , drop = FALSE]
expect_equal(ki67_row$readiness_status[[1]], "weak_candidate_only", "Source-only Ki-67 search space should remain weak candidate only.")
expect_false(isTRUE(ki67_row$direct_variable_available[[1]]), "Source-only Ki-67 search space should not be direct evidence.")
expect_false(isTRUE(ki67_row$proxy_available[[1]]), "Source-only Ki-67 search space should not be a proxy.")

microbiology_only <- build_ki67_discovery_outputs(
  project_root = root,
  include_reference_files = FALSE,
  sources = data.frame(
    table_name = "microbiology_microscopy",
    source = "PERSIMUNE_microbiology_microscopy",
    domain = "Microbiology",
    load_status = "ok",
    stringsAsFactors = FALSE
  )
)
expect_false(any(grepl("microbiology_microscopy", paste(microbiology_only$search_inventory$file_or_table, microbiology_only$search_inventory$resource_id), ignore.case = TRUE)), "Generic microbiology microscopy should not create Ki-67 evidence or source-space rows.")

microbiology_direct <- build_ki67_discovery_outputs(
  project_root = root,
  include_reference_files = FALSE,
  column_profiles = data.frame(
    table_name = "microbiology_microscopy",
    column_name = "Ki-67_result_note",
    profile_kind = "text",
    domain = "Microbiology",
    stringsAsFactors = FALSE
  )
)
expect_true(any(microbiology_direct$search_inventory$evidence_strength %in% c("strong_direct", "moderate_direct")), "A direct Ki-67 term should still be detected even if the source name would otherwise be excluded.")

placeholder <- build_ki67_discovery_outputs(
  project_root = root,
  include_reference_files = FALSE,
  sources = data.frame(table_name = "SDS_pato", source = "pato", domain = "Pathology", stringsAsFactors = FALSE)
)
expect_true(any(placeholder$aeki_code_counts$validation_status == "requires_production_validation"), "Fixture/static mode should emit a production-validation placeholder rather than fake AEKI counts.")
expect_false(any(placeholder$pathology_code_candidates$code %in% c("FY5015", "FY5016", "M0901K", "M0901L") & placeholder$pathology_code_candidates$mcl_triangle_high_risk_ki67_numeric), "p16/Ki-67 dual-stain or test-quality codes must not upgrade numeric MCL Ki-67 readiness.")

zip_root <- file.path(tempdir(), paste0("ki67_zip_shape_", Sys.getpid()))
unlink(zip_root, recursive = TRUE, force = TRUE)
dir_create(file.path(zip_root, "R"))
dir_create(file.path(zip_root, "scripts"))
dir_create(file.path(zip_root, "tests"))
dir_create(file.path(zip_root, "outputs"))
dir_create(file.path(zip_root, "clinical_questions"))
for (path in c(
  "R/utils.R",
  "R/ki67_discovery.R",
  "R/mcl_triangle_feasibility.R",
  "scripts/build_ki67_discovery.R",
  "scripts/run_tests.R",
  "tests/helper.R",
  "tests/test-ki67-discovery.R",
  "clinical_questions/ki67_extraction_spec.yml"
)) {
  expect_true(file.copy(file.path(root, path), file.path(zip_root, path), overwrite = TRUE), paste("Failed to copy ZIP-shaped package file:", path))
}
expect_false(file.exists(file.path(zip_root, "R", "run_atlas.R")), "ZIP-shaped Ki-67 package test should not include the full atlas runner.")
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
cached_result <- system2(
  rscript,
  c(
    file.path(zip_root, "scripts", "build_ki67_discovery.R"),
    "--mode", "cached_outputs",
    "--project-root", zip_root,
    "--outputs-dir", "outputs",
    "--validate-only", "true"
  ),
  stdout = TRUE,
  stderr = TRUE
)
cached_status <- attr(cached_result, "status") %||% 0L
expect_equal(as.integer(cached_status), 0L, paste(c("Cached-output validate-only command should run from the unpacked ZIP shape.", cached_result), collapse = "\n"))
expect_true(any(grepl("without running source profiling or DB access", cached_result, fixed = TRUE)), "Cached-output validate-only command should state that it does not run source profiling or DB access.")
outside_cached_result <- system2(
  rscript,
  c(
    file.path(zip_root, "scripts", "build_ki67_discovery.R"),
    "--mode", "cached_outputs",
    "--project-root", zip_root,
    "--outputs-dir", "outputs",
    "--validate-only", "true"
  ),
  stdout = TRUE,
  stderr = TRUE
)
outside_cached_status <- attr(outside_cached_result, "status") %||% 0L
expect_equal(as.integer(outside_cached_status), 0L, paste(c("Relative --outputs-dir should resolve under --project-root, not the caller working directory.", outside_cached_result), collapse = "\n"))
targeted_result <- system2(
  rscript,
  c(file.path(zip_root, "scripts", "build_ki67_discovery.R"), "--mode", "targeted_production_validation", "--project-root", zip_root, "--outputs-dir", "outputs", "--validate-only", "true"),
  stdout = TRUE,
  stderr = TRUE
)
targeted_status <- attr(targeted_result, "status") %||% 0L
expect_equal(as.integer(targeted_status), 0L, paste(c("Targeted production validation validate-only command should run as plan-only mode.", targeted_result), collapse = "\n"))
expect_true(any(grepl("plan-only", targeted_result, fixed = TRUE)), "Targeted production validation mode should clearly report plan-only behavior.")
