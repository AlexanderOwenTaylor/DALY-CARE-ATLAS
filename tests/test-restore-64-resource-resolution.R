root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

canonical <- read_canonical_dalycare_resources(root)
restored_source_map <- read_source_map(file.path(root, "config", "source-map.dalycare64.restored.tsv"), project_root = root)
current_source_map <- read_source_map(file.path(root, "config", "source-map.dalycare.tsv"), project_root = root)
production_plan <- read_production_source_recovery_map(root)

expect_equal(nrow(canonical), 64L, "Canonical resource file should contain exactly 64 DALY-CARE resources.")
expect_equal(
  length(unique(restored_source_map$canonical_resource_id[nzchar(restored_source_map$canonical_resource_id)])),
  64L,
  "Restored source map should represent all 64 canonical resources."
)
expect_true(
  all(current_source_map$table_name %in% restored_source_map$table_name),
  "The restored source map must preserve every source-map row from the successful 48-source production run."
)

view_rows <- restored_source_map[grepl("^view", restored_source_map$table_name, ignore.case = TRUE), , drop = FALSE]
expect_true(nrow(view_rows) > 0, "Restored source map should retain production view rows.")
expect_true(all(view_rows$source_map_role_secondary == "derived_view" | view_rows$source_map_role_primary == "derived_view"), "Production view rows must carry derived-view role metadata.")

del2_id <- "BilleddiagnostikeUndersøgelser_Del2"
del2_ascii <- "BilleddiagnostikeUndersoegelser_Del2"
del2_source_map_hit <- grepl(resource_key(del2_ascii), resource_key(current_source_map$table_name), fixed = TRUE) |
  grepl(resource_key(del2_ascii), resource_key(current_source_map$source), fixed = TRUE)
del2_canonical <- canonical[resource_key(canonical$canonical_resource_id) == resource_key(del2_id), , drop = FALSE]
expect_true(nrow(del2_canonical) == 1L, "Billeddiagnostik Del2 should remain in the canonical 64-resource universe.")
expect_true(
  del2_canonical$current_validation_status == "legacy_unavailable_current_resolved",
  "Del2 should be marked as legacy-unavailable but current-resolved after the production run evidence."
)

sources <- data.frame(
  table_name = current_source_map$table_name,
  source = current_source_map$source,
  table = ifelse(
    del2_source_map_hit,
    "SP_BilleddiagnostiskeUndersøgelser_Del2",
    ifelse(nzchar(current_source_map$table), current_source_map$table, current_source_map$table_name)
  ),
  db_name = ifelse(nzchar(current_source_map$db_name), current_source_map$db_name, "import"),
  schema = ifelse(nzchar(current_source_map$schema), current_source_map$schema, "public"),
  load_status = "ok",
  n_rows = ifelse(del2_source_map_hit, "1909409", "1"),
  n_cols = ifelse(del2_source_map_hit, "12", "1"),
  stringsAsFactors = FALSE
)
source_resolution <- data.frame(
  table_name = current_source_map$table_name,
  source = current_source_map$source,
  table = sources$table,
  db_name = sources$db_name,
  schema = sources$schema,
  resolution_status = "resolved",
  row_count = sources$n_rows,
  stringsAsFactors = FALSE
)

attempts <- build_source_resolution_attempts(
  project_root = root,
  production_map = production_plan,
  source_map = current_source_map,
  sources = sources,
  source_resolution = source_resolution
)
del2_attempt <- attempts[resource_key(attempts$expected_resource_id) == resource_key(del2_id), , drop = FALSE]
expect_true(nrow(del2_attempt) == 1L && isTRUE(as.logical(del2_attempt$resolved[[1]])), "Del2 should resolve when the current production output contains its resolved SP imaging table.")

resource_reconciliation <- build_atlas_resource_reconciliation(
  project_root = root,
  source_map = current_source_map,
  sources = sources,
  source_resolution = source_resolution,
  source_attempts = attempts
)
canonical_reconciliation <- build_canonical_resource_reconciliation_64(
  project_root = root,
  source_map = current_source_map,
  sources = sources,
  source_resolution = source_resolution,
  canonical = canonical,
  resource_reconciliation = resource_reconciliation
)
del2_reconciliation <- canonical_reconciliation[resource_key(canonical_reconciliation$canonical_resource_id) == resource_key(del2_id), , drop = FALSE]
expect_true(nrow(del2_reconciliation) == 1L, "Canonical reconciliation should include Del2.")
expect_equal(del2_reconciliation$current_status[[1]], "legacy_unavailable_current_resolved", "Del2 must not be downgraded to current-unavailable when production output resolves it.")
expect_equal(del2_reconciliation$current_n_rows[[1]], "1909409", "Del2 current row count should come from the current production output.")

crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
  project_root = root,
  source_map = current_source_map,
  sources = sources,
  source_resolution = source_resolution,
  canonical = canonical
)
expect_equal(nrow(crosswalk), nrow(current_source_map), "Every current source-map row should have a crosswalk row.")
expect_true(any(crosswalk$is_derived_view), "Current production view rows should be represented as derived views.")
expect_true(any(crosswalk$is_derived_view & crosswalk$is_canonical_resource), "Role booleans should allow a source-map row to be both canonical and derived when explicitly mapped.")
t_dalycare_crosswalk <- crosswalk[crosswalk$canonical_resource_id == "t_dalycare_diagnoses", , drop = FALSE]
expect_true(any(t_dalycare_crosswalk$is_canonical_resource & t_dalycare_crosswalk$current_profiled), "t_dalycare_diagnoses should remain canonical and current-profiled even when represented through a view/source-map row.")

summary_metrics <- canonical_resource_summary_metrics(
  canonical_reconciliation = canonical_reconciliation,
  crosswalk = crosswalk,
  legacy_reference = data.frame(stringsAsFactors = FALSE)
)
summary_values <- stats::setNames(summary_metrics$value, summary_metrics$metric)
expect_equal(summary_values[["canonical_expected_resources"]], "64", "Summary metrics should count 64 canonical resources.")
expect_equal(summary_values[["source_map_rows_profiled"]], as.character(nrow(current_source_map)), "Summary metrics should separately count profiled source-map rows.")
expect_equal(summary_values[["legacy_unavailable_current_resolved_resources"]], "1", "Summary metrics should count the Del2 legacy-unavailable/current-resolved case.")
expect_equal(summary_values[["source_map_rows_profiled_current_run"]], as.character(nrow(current_source_map)), "Summary metrics should expose source-map rows profiled this run.")
expect_true(as.integer(summary_values[["source_map_rows_canonical"]]) < nrow(current_source_map), "Source-map rows should not be blindly counted as canonical resources.")

del2_audit <- build_billeddiagnostik_del2_regression_audit(
  project_root = root,
  sources = sources,
  source_resolution = source_resolution,
  canonical_reconciliation = canonical_reconciliation,
  crosswalk = crosswalk
)
expect_true(any(del2_audit$evidence_type == "current_run_resolution" & del2_audit$final_classification == "legacy_unavailable_current_resolved"), "Del2 audit should include direct current-run resolution evidence.")
expect_false(any(grepl("Behandlingsplaner|Bloddyrkning|Journalnotater", del2_audit$matched_string)), "Unrelated generic Del2 resources should not pollute the Billeddiagnostik Del2 audit.")

activation_plan <- build_remaining_canonical_resources_activation_plan(
  project_root = root,
  canonical_reconciliation = canonical_reconciliation,
  production_map = production_plan,
  canonical = canonical
)
expect_true(all(activation_plan$current_status == "current_not_attempted"), "Activation plan should list only current-not-attempted canonical resources.")
expect_true(all(c("EKOKUR", "t_mikro", "t_konk", "microbiology_analysis", "BIOBANK_SAMPLES", "MM_TREAT_DARA") %in% activation_plan$canonical_resource_id), "Activation plan should include late-cartography and curated not-attempted resources.")

semantic_reference <- data.frame(
  source_name = c(del2_ascii, "t_mikro"),
  evidence_file = c("current production semantic output", "legacy cartography reference"),
  stringsAsFactors = FALSE
)
legacy_vs_current <- build_legacy_reference_vs_current_profiled_evidence(
  project_root = root,
  semantic_dictionary = semantic_reference,
  canonical_reconciliation = canonical_reconciliation,
  sources = sources,
  canonical = canonical
)
del2_evidence <- legacy_vs_current[resource_key(legacy_vs_current$evidence_source) == resource_key(del2_ascii), , drop = FALSE]
t_mikro_evidence <- legacy_vs_current[legacy_vs_current$evidence_source == "t_mikro", , drop = FALSE]
expect_true(nrow(del2_evidence) == 1L && isTRUE(as.logical(del2_evidence$current_profiled_this_run[[1]])), "Del2 semantic evidence should be marked current-profiled when the source was profiled.")
expect_true(nrow(t_mikro_evidence) == 1L && isTRUE(as.logical(t_mikro_evidence$warning_needed[[1]])), "Legacy/reference-only evidence should be flagged when the current production run did not profile that source.")
