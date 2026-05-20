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
del2_keys <- resource_key(c(del2_id, del2_ascii, "BilleddiagnostikeUndersogelser_Del2"))
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

restored_is_fish <- resource_key(restored_source_map$canonical_resource_id) == resource_key("FISH") |
  resource_key(restored_source_map$table_name) == resource_key("FISH")
restored_is_danricht <- resource_key(restored_source_map$canonical_resource_id) == resource_key("DANRICHT") |
  resource_key(restored_source_map$table_name) == resource_key("DANRICHT")
restored_is_del2 <- resource_key(restored_source_map$canonical_resource_id) %in% del2_keys |
  grepl(resource_key(del2_ascii), resource_key(restored_source_map$table_name), fixed = TRUE) |
  grepl(resource_key(del2_ascii), resource_key(restored_source_map$source), fixed = TRUE)

restored_sources <- data.frame(
  table_name = restored_source_map$table_name,
  source = restored_source_map$source,
  table = ifelse(
    restored_is_del2,
    "SP_BilleddiagnostiskeUndersÃ¸gelser_Del2",
    ifelse(nzchar(restored_source_map$table), restored_source_map$table, restored_source_map$table_name)
  ),
  db_name = ifelse(nzchar(restored_source_map$db_name), restored_source_map$db_name, "import"),
  schema = ifelse(nzchar(restored_source_map$schema), restored_source_map$schema, "public"),
  canonical_resource_id = restored_source_map$canonical_resource_id,
  resolver_type = restored_source_map$resolver_type,
  load_status = ifelse(restored_is_fish, "skipped", ifelse(restored_is_danricht, "failed", "ok")),
  n_rows = ifelse(restored_is_del2, "1909409", ifelse(restored_is_fish | restored_is_danricht, "", "1")),
  n_cols = ifelse(restored_is_del2, "12", ifelse(restored_is_fish | restored_is_danricht, "", "1")),
  resolution_status = ifelse(restored_is_fish | restored_is_danricht, "missing", "resolved"),
  chosen_strategy = ifelse(nzchar(restored_source_map$load_strategy), restored_source_map$load_strategy, "db_aggregate"),
  memory_status = "",
  attempted_in_current_run = ifelse(restored_is_fish | restored_is_danricht, "FALSE", "TRUE"),
  profiled_in_current_run = ifelse(restored_is_fish | restored_is_danricht, "FALSE", "TRUE"),
  activation_status = ifelse(restored_is_fish, "embedded_fields", ifelse(restored_is_danricht, "special_manual", "profiled_current_run")),
  schema_signature = "",
  message = "",
  stringsAsFactors = FALSE
)
restored_sources$schema_signature[resource_key(restored_sources$table_name) == resource_key("RKKP_CLL")] <- "Reg_FISH; del17p; trisomi12"

restored_columns <- data.frame(
  table_name = c("RKKP_CLL", "RKKP_DaMyDa"),
  column_name = c("Reg_FISH", "Cyto_FishResultat_17p"),
  stringsAsFactors = FALSE
)
restored_source_resolution <- data.frame(
  table_name = restored_source_map$table_name,
  source = restored_source_map$source,
  table = restored_sources$table,
  db_name = restored_sources$db_name,
  schema = restored_sources$schema,
  resolution_status = ifelse(restored_is_fish | restored_is_danricht, "missing", "resolved"),
  row_count = restored_sources$n_rows,
  message = "",
  suggestion = "",
  candidate_locations = "",
  candidate_row_counts = "",
  stringsAsFactors = FALSE
)
restored_checks <- data.frame(
  table_name = c("FISH", "DANRICHT"),
  check_id = c("source_skipped_risky_full_load", "source_load_failed"),
  severity = c("warning", "error"),
  message = c("Skipped FISH standalone table", "DANRICHT manual file not found"),
  stringsAsFactors = FALSE
)

normalized <- normalize_special_manual_run_statuses(
  source_map = restored_source_map,
  sources = restored_sources,
  source_resolution = restored_source_resolution,
  checks = restored_checks,
  columns = restored_columns
)
fish_source <- normalized$sources[restored_is_fish, , drop = FALSE]
danricht_source <- normalized$sources[restored_is_danricht, , drop = FALSE]
expect_true(nrow(fish_source) == 1L && fish_source$load_status[[1]] == "embedded_fields_represented", "FISH should be represented as embedded fields, not a skipped or failed DB source.")
expect_true(nrow(danricht_source) == 1L && danricht_source$load_status[[1]] == "manual_file_not_available", "DANRICHT should be represented as a manual-file note, not a DB failure.")
expect_true(all(normalized$checks$severity[normalized$checks$table_name == "FISH"] == "info"), "FISH embedded-field representation should be informational.")
expect_true(all(normalized$checks$severity[normalized$checks$table_name == "DANRICHT"] == "manual_note"), "DANRICHT missing manual file should be a manual note.")

profiled_rows <- normalized$sources[normalized$sources$load_status == "ok", , drop = FALSE]
expect_false(any(profiled_rows$activation_status == "not_attempted_candidate"), "No resolved/profiled source row should retain not-attempted activation status.")
expect_false(any(profiled_rows$profiled_in_current_run == "FALSE"), "No resolved/profiled source row should retain profiled_in_current_run = FALSE.")

restored_attempts <- build_source_resolution_attempts(
  project_root = root,
  production_map = production_plan,
  source_map = restored_source_map,
  sources = normalized$sources,
  source_resolution = normalized$source_resolution
)
fish_attempt <- restored_attempts[restored_attempts$expected_resource_id == "FISH", , drop = FALSE]
danricht_attempt <- restored_attempts[restored_attempts$expected_resource_id == "DANRICHT", , drop = FALSE]
expect_true(nrow(fish_attempt) == 1L && isTRUE(as.logical(fish_attempt$resolved[[1]])) && !isTRUE(as.logical(fish_attempt$attempted[[1]])), "FISH should be resolved through embedded fields without being a DB-attempted source.")
expect_true(nrow(danricht_attempt) == 1L && !isTRUE(as.logical(danricht_attempt$resolved[[1]])) && !isTRUE(as.logical(danricht_attempt$attempted[[1]])), "DANRICHT absent manual files should not be counted as an attempted DB failure.")
expect_false(grepl("DB", danricht_attempt$error_or_warning[[1]], ignore.case = TRUE), "DANRICHT warning should not describe an ordinary DB failure.")

restored_resource_reconciliation <- build_atlas_resource_reconciliation(
  project_root = root,
  source_map = restored_source_map,
  sources = normalized$sources,
  source_resolution = normalized$source_resolution,
  source_attempts = restored_attempts
)
restored_canonical_reconciliation <- build_canonical_resource_reconciliation_64(
  project_root = root,
  source_map = restored_source_map,
  sources = normalized$sources,
  source_resolution = normalized$source_resolution,
  canonical = canonical,
  resource_reconciliation = restored_resource_reconciliation
)
restored_crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
  project_root = root,
  source_map = restored_source_map,
  sources = normalized$sources,
  source_resolution = normalized$source_resolution,
  canonical = canonical
)
restored_summary <- canonical_resource_summary_metrics(
  canonical_reconciliation = restored_canonical_reconciliation,
  crosswalk = restored_crosswalk,
  legacy_reference = data.frame(stringsAsFactors = FALSE)
)
restored_values <- stats::setNames(restored_summary$value, restored_summary$metric)
expect_equal(restored_values[["canonical_resources_total"]], "64", "Successful restored run summary should preserve exactly 64 canonical resources.")
expect_equal(restored_values[["canonical_resources_accounted_for"]], "64", "Successful restored run summary should account for all canonical resources.")
expect_equal(restored_values[["db_attemptable_canonical_resources"]], "62", "Successful restored run should classify 62 canonical resources as DB-attemptable.")
expect_equal(restored_values[["db_attemptable_profiled_resources"]], "62", "Successful restored run should profile all DB-attemptable canonical resources.")
expect_equal(restored_values[["special_manual_or_embedded_resources"]], "2", "Successful restored run should keep FISH and DANRICHT as the two special/manual resources.")
expect_equal(restored_values[["embedded_field_resources"]], "1", "FISH should count as the embedded-field resource.")
expect_equal(restored_values[["manual_special_not_loaded_resources"]], "1", "DANRICHT should count as the manual/special source not loaded.")
expect_equal(restored_values[["unexpected_missing_canonical_resources"]], "0", "Successful restored run should have no unexpected missing canonical resources.")
expect_equal(restored_values[["db_attemptable_failures"]], "0", "Successful restored run should have zero DB-attemptable failures.")
expect_equal(restored_values[["source_map_rows_profiled_current_run"]], "71", "Successful restored run should profile 71 source-map rows when FISH and DANRICHT are special/manual.")

special_rows <- restored_canonical_reconciliation[restored_canonical_reconciliation$canonical_resource_id %in% c("FISH", "DANRICHT"), , drop = FALSE]
expect_equal(special_rows$current_status[special_rows$canonical_resource_id == "FISH"][[1]], "embedded_fields_represented", "Canonical FISH status should be embedded-fields represented.")
expect_equal(special_rows$current_status[special_rows$canonical_resource_id == "DANRICHT"][[1]], "manual_file_not_available", "Canonical DANRICHT status should be manual-file not available.")
restored_del2 <- restored_canonical_reconciliation[resource_key(restored_canonical_reconciliation$canonical_resource_id) %in% del2_keys, , drop = FALSE]
expect_true(nrow(restored_del2) == 1L && restored_del2$current_status[[1]] == "legacy_unavailable_current_resolved", "Del2 should remain legacy-unavailable/current-resolved in the restored run summary.")
