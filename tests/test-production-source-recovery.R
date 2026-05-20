root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expected <- read_expected_dalycare_resources(root)
plan <- read_production_source_recovery_map(root)
dry_run <- build_source_resolution_plan_dry_run(project_root = root, production_map = plan)

expect_equal(nrow(expected), 64L, "Expected-resource file should contain the V033 64-resource universe.")
expect_equal(nrow(plan), 64L, "Production source recovery map should contain one row per expected resource.")
expect_true(all(expected$expected_resource_id %in% plan$expected_resource_id), "Every expected resource should appear in the production source recovery map.")
expect_equal(sum(source_recovery_truthy(plan$legacy_known_unavailable)), 1L, "Exactly one resource should carry legacy-known-unavailable status.")
expect_equal(sum(source_recovery_truthy(plan$current_known_unavailable)), 0L, "No resource should be marked current-known-unavailable without a production attempt.")
expect_true(any(plan$expected_resource_id == "BilleddiagnostikeUndersøgelser_Del2" & source_recovery_truthy(plan$legacy_known_unavailable) & plan$resolver_type == "direct_sql"), "SP imaging Del2 should be legacy-unavailable but configured as a current direct-SQL candidate.")
expect_equal(sum(plan$resolver_type %in% c("standard_table", "alias_table", "schema_qualified_table", "direct_sql")), 62L, "There should be 62 DB-attemptable resolver candidates, including Del2.")
expect_equal(sum(plan$resolver_type %in% c("manual_file", "embedded_fields")), 2L, "There should be two special/manual or embedded resources.")
expect_false(any(!nzchar(plan$resolver_type)), "No resource should lack resolver_type.")

late_resources <- c(
  "t_mikro", "t_konk", "t_doedsaarsag", "t_tumor", "procedure_kirurgi", "procedure_andre",
  "SP_Administreret_Medicin", "SP_ADT_Haendelser", "Aktive_Problemliste_Diagnoser",
  "Behandlingskontakter_diagnoser", "Behandlingsplaner_del1", "Behandlingsplaner_del2",
  "Journalnotater_del1", "Journalnotater_del2", "BilleddiagnostikeUndersøgelser_Del1",
  "FISH", "MM_TREAT_DARA", "DANRICHT"
)
for (resource_id in late_resources) {
  hit <- plan[plan$expected_resource_id == resource_id, , drop = FALSE]
  expect_true(nrow(hit) == 1L && nzchar(hit$resolver_type[[1]]), paste("Late-cartography resource should have a resolver strategy:", resource_id))
}
expect_false(any(plan$expected_resource_id == "t_tumor" & plan$resolver_type == "known_unavailable"), "t_tumor must not be marked known unavailable.")
expect_true(any(plan$expected_resource_id == "DANRICHT" & plan$resolver_type == "manual_file" & !source_recovery_truthy(plan$known_unavailable)), "DANRICHT should be manual_file, not unavailable.")
expect_true(any(plan$expected_resource_id == "FISH" & plan$resolver_type == "embedded_fields" & !source_recovery_truthy(plan$known_unavailable)), "FISH should be embedded_fields, not unavailable.")

expect_equal(nrow(dry_run), 64L, "Dry-run plan should list all expected resources.")
expect_equal(sum(dry_run$dry_run_status == "legacy_unavailable_current_candidate"), 1L, "Dry-run plan should flag Del2 as legacy-unavailable current candidate.")
expect_equal(sum(dry_run$dry_run_status %in% c("would_attempt_in_production", "requires_manual_file", "requires_embedded_field_mapping", "legacy_unavailable_current_candidate", "current_known_unavailable_declared")), 64L, "Dry-run plan should configure every resource without implying production resolution.")
expect_false(any(dry_run$dry_run_status == "needs_manual_review"), "Dry-run plan should not require manual review for missing resolver metadata.")

tables <- data.frame(
  db_name = c("import", "import", "import", "import", "import"),
  schema = c("public", "public", "public", "public", "public"),
  table = c(
    "SP_BilleddiagnostiskeUndersøgelser_Del1",
    "SP_BilleddiagnostiskeUndersøgelser_Del2",
    "SDS_t_mikro_ny",
    "sds_procedurer_kirurgi",
    "SPAdministreretMedicin"
  ),
  row_count = c(10, 11, 20, 30, 40),
  stringsAsFactors = FALSE
)
match_one <- function(resource_id) {
  row <- plan[plan$expected_resource_id == resource_id, , drop = FALSE]
  match_table_location(row, tables)
}
expect_true(nrow(match_one("BilleddiagnostikeUndersøgelser_Del1")) == 1L, "Danish billeddiagnostik spelling variants should match through aliases.")
expect_true(nrow(match_one("BilleddiagnostikeUndersøgelser_Del2")) == 1L, "Del2 candidate aliases should match if the production table exists.")
expect_true(nrow(match_one("t_mikro")) == 1L, "t_mikro should match SDS_t_mikro_ny through aliases.")
expect_true(nrow(match_one("procedure_kirurgi")) == 1L, "procedure_kirurgi should match case-insensitive SDS procedure aliases.")
expect_true(nrow(match_one("SP_Administreret_Medicin")) == 1L, "SP medication naming should match underscore/punctuation variants.")
