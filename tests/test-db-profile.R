root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

old_db_profile <- Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = NA)
old_max_full_load <- Sys.getenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS", unset = NA)
old_allow_empty <- Sys.getenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN", unset = NA)
old_db_access <- Sys.getenv("DALYCARE_DB_ACCESS_PATH", unset = NA)
old_max_text_distinct <- Sys.getenv("DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS", unset = NA)
old_db_stream_rows <- Sys.getenv("DALYCARE_ATLAS_DB_STREAM_ROWS", unset = NA)
old_stream_threshold <- Sys.getenv("DALYCARE_ATLAS_STREAM_THRESHOLD_ROWS", unset = NA)
on.exit({
  if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
  if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
  if (is.na(old_allow_empty)) Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN") else Sys.setenv(DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN = old_allow_empty)
  if (is.na(old_db_access)) Sys.unsetenv("DALYCARE_DB_ACCESS_PATH") else Sys.setenv(DALYCARE_DB_ACCESS_PATH = old_db_access)
  if (is.na(old_max_text_distinct)) Sys.unsetenv("DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS = old_max_text_distinct)
  if (is.na(old_db_stream_rows)) Sys.unsetenv("DALYCARE_ATLAS_DB_STREAM_ROWS") else Sys.setenv(DALYCARE_ATLAS_DB_STREAM_ROWS = old_db_stream_rows)
  if (is.na(old_stream_threshold)) Sys.unsetenv("DALYCARE_ATLAS_STREAM_THRESHOLD_ROWS") else Sys.setenv(DALYCARE_ATLAS_STREAM_THRESHOLD_ROWS = old_stream_threshold)
  if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) rm(load_dataset, envir = .GlobalEnv)
}, add = TRUE)
Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = "TRUE", DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = "3")

fake_damyda <- data.frame(
  patientid = c("0101011234", "0202022345", "0303033456", "0404044567", "0505055678", "0606066789"),
  Reg_Diagnose_dt = as.Date("2020-01-01") + 0:5,
  Stadie = c("I", "I", "II", "II", "II", "III"),
  analysiscode = c("NPU04998", "NPU04998", "NPU01443", "NPU99999", "NPU99999", "not-a-code"),
  ALB = c(34, 35, 36, 38, 39, 40),
  stringsAsFactors = FALSE
)
npu_dictionary <- load_npu_consensus_dictionary(project_root = root)
npu_surfaces <- load_npu_detective_surfaces(project_root = root)
isotype_vectors <- load_isotype_vectors(project_root = root, dictionary = npu_dictionary)
treatment_families <- load_mm_treatment_code_families(project_root = root)
fake_adapter <- list(
  list_tables = function() {
    data.frame(
      db_name = c("core", "core", "core", "import"),
      schema = c("public", "public", "curated", "public"),
      table = c("RKKP_DaMyDa", "RKKP_CLL", "RKKP_CLL", "patient"),
      stringsAsFactors = FALSE
    )
  },
  table_row_count = function(db_name, schema, table) {
    if (identical(table, "RKKP_DaMyDa")) return(nrow(fake_damyda))
    if (identical(table, "patient")) return(2L)
    500000L
  },
  profile_table = function(db_name, schema, table, table_name, source_type, source,
                           profile_mode = "full", top_n = 10L, min_cell_count = atlas_min_cell_count(),
                           npu_dictionary = NULL,
                           npu_surfaces = NULL,
                           isotype_vectors = NULL,
                           treatment_families = NULL) {
    if (!identical(table, "RKKP_DaMyDa")) stop("unexpected fake table")
    profile_source(
      fake_damyda,
      table_name = table_name,
      source_type = source_type,
      source = source,
      profile_mode = profile_mode,
      top_n = top_n,
      min_cell_count = min_cell_count,
      npu_dictionary = npu_dictionary,
      npu_surfaces = npu_surfaces,
      isotype_vectors = isotype_vectors,
      treatment_families = treatment_families
    )
  }
)

source_map <- data.frame(
  table_name = c("RKKP_DaMyDa", "RKKP_CLL", "NOPE", "patient"),
  source_type = rep("dataset", 4),
  source = c("RKKP_DaMyDa", "RKKP_CLL", "NOPE", "patient"),
  priority = 1:4,
  profile_mode = rep("full", 4),
  load_strategy = rep("auto", 4),
  allow_full_load = c("FALSE", "FALSE", "FALSE", "FALSE"),
  stringsAsFactors = FALSE
)

resolution <- resolve_dalycare_sources(source_map, db_adapter = fake_adapter)
expect_true(any(resolution$table_name == "RKKP_DaMyDa" & resolution$resolution_status == "resolved"), "Resolver should find an unambiguous DALY table.")
expect_true(any(resolution$table_name == "RKKP_CLL" & resolution$resolution_status == "ambiguous"), "Resolver should flag ambiguous DB table matches.")
expect_true(any(resolution$table_name == "NOPE" & resolution$resolution_status == "missing"), "Resolver should flag missing DB table matches.")
ambiguous <- resolution[resolution$table_name == "RKKP_CLL", , drop = FALSE]
expect_true(grepl("core.public.RKKP_CLL", ambiguous$candidate_locations[[1]], fixed = TRUE), "Ambiguous resolver rows should list candidate DB locations.")
expect_true(grepl("unavailable|500000", ambiguous$candidate_row_counts[[1]]), "Ambiguous resolver rows should list row-count availability.")
missing <- resolution[resolution$table_name == "NOPE", , drop = FALSE]
expect_true("suggestion" %in% names(missing), "Missing resolver rows should include a suggestion field.")

alias_map <- data.frame(
  table_name = c("SP_BilleddiagnostikeUndersoegelser_Del1", "view_diagnoses_all"),
  source_type = "dataset",
  source = c("SP_BilleddiagnostikeUndersoegelser_Del1", "view_diagnoses_all"),
  priority = 1:2,
  profile_mode = "schema",
  stringsAsFactors = FALSE
)
alias_tables <- data.frame(
  db_name = c("import", "dalycare"),
  schema = c("public", "views"),
  table = c("SP_BilleddiagnostiskeUndersøgelser_Del1", "view_diagnosses_all"),
  stringsAsFactors = FALSE
)
alias_resolution <- resolve_dalycare_sources(alias_map, db_adapter = list(list_tables = function() alias_tables, table_row_count = function(...) 1L))
expect_true(all(alias_resolution$resolution_status == "resolved"), "Resolver should match ASCII-folded and known spelling aliases.")

late_legacy_map <- data.frame(
  table_name = c(
    "SDS_t_mikro", "SDS_t_konk", "SDS_t_doedsaarsag",
    "SDS_procedure_kirurgi", "SDS_procedure_andre",
    "SP_Administreret_Medicin", "SP_ADT_Haendelser",
    "SP_Aktive_Problemliste_Diagnoser", "SP_Behandlingskontakter_diagnoser",
    "SP_Behandlingsplaner_del1", "SP_Behandlingsplaner_del2",
    "SP_Journalnotater_del1", "SP_Journalnotater_del2",
    "SP_BilleddiagnostikeUndersoegelser_Del1", "MM_TREAT_DARA"
  ),
  source_type = "dataset",
  source = c(
    "SDS_t_mikro", "SDS_t_konk", "SDS_t_doedsaarsag",
    "SDS_procedure_kirurgi", "SDS_procedure_andre",
    "SP_Administreret_Medicin", "SP_ADT_Haendelser",
    "SP_Aktive_Problemliste_Diagnoser", "SP_Behandlingskontakter_diagnoser",
    "SP_Behandlingsplaner_del1", "SP_Behandlingsplaner_del2",
    "SP_Journalnotater_del1", "SP_Journalnotater_del2",
    "SP_BilleddiagnostikeUndersoegelser_Del1", "MM_TREAT_DARA"
  ),
  priority = seq_len(15),
  profile_mode = "schema",
  stringsAsFactors = FALSE
)
late_legacy_tables <- data.frame(
  db_name = c(rep("import", 14), "core"),
  schema = c(rep("public", 14), "curated"),
  table = c(
    "SDS_t_mikro_ny", "SDS_t_konk_ny", "SDS_t_dodsaarsag_2",
    "SDS_procedurer_kirurgi", "SDS_procedurer_andre",
    "SP_AdministreretMedicin", "SP_ADT_haendelser",
    "SP_AktiveProblemlisteDiagnoser", "SP_BehandlingskontakterOgDiagnoser",
    "SP_Behandlingsplaner_Del1", "SP_Behandlingsplaner_Del2",
    "SP_Journalnotater_Del1", "SP_Journalnotater_Del2",
    "SP_BilleddiagnostiskeUndersoegelser_Del1", "REQUIRE_PERMISSION_MM_TREAT_DARA"
  ),
  stringsAsFactors = FALSE
)
late_legacy_resolution <- resolve_dalycare_sources(
  late_legacy_map,
  db_adapter = list(list_tables = function() late_legacy_tables, table_row_count = function(...) 1L)
)
expect_true(all(late_legacy_resolution$resolution_status == "resolved"), "Late-cartography legacy resources should resolve through explicit alias/direct-table mappings.")

fake_db_access <- tempfile(fileext = ".R")
writeLines(c("pw <- 'not-secret-in-report'", "ignored <- 123"), fake_db_access)
Sys.setenv(DALYCARE_DB_ACCESS_PATH = fake_db_access)
access <- read_dalycare_db_access()
expect_true(access$password_present, "DB access reader should detect a pw symbol.")
report <- dalycare_access_report(source_map = alias_map, db_adapter = list(list_tables = function() alias_tables, table_row_count = function(...) 1L), source_resolution = alias_resolution)
report_text <- paste(capture.output(print(report)), collapse = "\n")
expect_false(grepl("not-secret-in-report", report_text, fixed = TRUE), "DB access diagnostics must not expose credential values.")

impact_report <- data.frame(
  status = c("error", "ok"),
  check_id = c("bootstrap_source_failed", "db_adapter_available"),
  table_name = "",
  db_name = "",
  schema = "",
  message = c("object 'un' not found", "DB adapter available"),
  detail = "",
  stringsAsFactors = FALSE
)
impact_plan <- data.frame(chosen_strategy = "db_aggregate", stringsAsFactors = FALSE)
adjusted <- adjust_access_report_for_actual_impact(impact_report, db_adapter = fake_adapter, memory_plan = impact_plan)
expect_true(adjusted$status[adjusted$check_id == "bootstrap_source_failed"] == "warning", "Bootstrap source failure should be a warning when DB aggregate profiling is available.")
expect_true(grepl("DB aggregate profiling succeeded", adjusted$message[adjusted$check_id == "bootstrap_source_failed"], fixed = TRUE), "Adjusted bootstrap diagnostics should explain the fallback impact.")
blocking_plan <- data.frame(chosen_strategy = "dataset_full_load_fallback", stringsAsFactors = FALSE)
blocking <- adjust_access_report_for_actual_impact(impact_report, db_adapter = NULL, memory_plan = blocking_plan)
expect_true(blocking$status[blocking$check_id == "bootstrap_source_failed"] == "error", "Bootstrap source failure should remain an error when DB aggregate profiling is unavailable.")

plan <- memory_plan_for_sources(source_map, resolution)
expect_true(any(plan$table_name == "RKKP_DaMyDa" & plan$chosen_strategy == "db_aggregate"), "Resolved DALY sources should prefer DB aggregate profiling.")
expect_true(any(plan$table_name == "RKKP_CLL" & plan$chosen_strategy == "skipped_risky_full_load"), "Ambiguous large DALY sources should not fall back to load_dataset() by default.")
expect_true(any(plan$table_name == "NOPE" & plan$chosen_strategy == "skipped_risky_full_load"), "Missing sources with unknown row counts should be skipped unless full-load fallback is allowed.")

db_profile <- profile_db_source(
  source_record = source_map[source_map$table_name == "RKKP_DaMyDa", , drop = FALSE],
  resolution_row = resolution[resolution$table_name == "RKKP_DaMyDa", , drop = FALSE],
  db_adapter = fake_adapter,
  profile_mode = "full",
  min_cell_count = 2L,
  npu_dictionary = npu_dictionary,
  npu_surfaces = npu_surfaces,
  isotype_vectors = isotype_vectors,
  treatment_families = treatment_families
)
expect_equal(nrow(db_profile$column_profiles), ncol(fake_damyda), "DB aggregate profile should emit one column profile per source column.")
expect_true(any(db_profile$column_profiles$column_name == "ALB" & db_profile$column_profiles$profile_kind == "numeric"), "DB aggregate profile should preserve numeric aggregate summaries.")
expect_false(any(db_profile$column_top_values$column_name == "patientid"), "DB aggregate top values must not expose patient identifiers.")
expect_true(any(db_profile$column_top_values$column_name == "Stadie" & db_profile$column_top_values$n >= 2), "DB aggregate top values should obey minimum-cell suppression.")
expect_true(any(db_profile$panels$lab_npu_code_coverage$lab_code == "NPU04998"), "DB aggregate profile should produce NPU code coverage without full-table loading.")
expect_true(any(db_profile$panels$npu_lab_usage_by_vector$consensus_vector == "CREATININE_CODES"), "DB aggregate profile should produce dictionary-aware NPU vector usage.")
expect_true(any(db_profile$panels$npu_lab_unmatched_codes$npu_code == "NPU99999"), "DB aggregate profile should produce suppressed-safe unmatched NPU summaries.")
expect_true(any(db_profile$panels$npu_detective_code_inventory$surface == "renal_creatinine"), "DB aggregate profile should produce NPU detective inventory from aggregate counts.")
expect_true(any(db_profile$panels$npu_detective_candidates$npu_code == "NPU99999"), "DB aggregate profile should produce NPU detective candidates from aggregate counts.")
Sys.setenv(DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS = "100")
expect_true(dbi_skip_distinct_count("text", "text", 101), "DB profiling should skip expensive distinct counts for huge text columns.")
expect_false(dbi_skip_distinct_count("text", "text", 100), "DB profiling should keep distinct counts for small text columns.")
expect_false(dbi_skip_distinct_count("integer", "int4", 1000000), "DB profiling should keep distinct counts for non-text columns.")
expect_true(likely_text_date_column("Reg_Diagnose_dt", "text", "text"), "DB profiling should treat DALY text _dt aliases as date-like.")
expect_true(likely_text_date_column("samplingtime", "text", "text"), "DB profiling should treat text time aliases as date-like.")
expect_false(likely_text_date_column("diagnosekode", "text", "text"), "DB profiling should not treat diagnosis code fields as date-like.")
expect_false(likely_text_date_column("diagnosetype", "text", "text"), "DB profiling should not treat diagnosis type fields as date-like.")
expect_true(grepl("regexp_replace", dbi_date_year_expression("\"Reg_Diagnose_dt\"", "text", "text"), fixed = TRUE), "Text-date year extraction should be SQL-side and aggregate-safe.")
expect_equal(atlas_elapsed_label(65), "01:05", "DB progress helpers should format short elapsed times for RStudio heartbeats.")
expect_equal(atlas_format_count(1234567), "1,234,567", "DB progress helpers should format row counts for RStudio heartbeats.")

budget_items <- db_budget_actions_as_run_action_items(data.frame(
  severity = "warning",
  category = "DB budget",
  action_id = "db_budget_skipped",
  table_name = c("huge_table", "huge_table_2"),
  column_name = c("a", "b"),
  query_category = "numeric_quantiles",
  estimated_rows = c(10000000, 20000000),
  reason = "sampled quantiles",
  current_behavior = "approximate quantiles",
  recommended_action = "increase sample only if needed",
  stringsAsFactors = FALSE
))
expect_equal(nrow(budget_items), 1L, "Repeated DB budget warnings should be grouped into one operator action item.")
expect_true(grepl("n_columns=2", budget_items$evidence[[1]], fixed = TRUE), "Grouped DB budget action items should preserve column-count evidence.")
expect_true(grepl("n_sources=2", budget_items$evidence[[1]], fixed = TRUE), "Grouped DB budget action items should preserve source-count evidence.")

stream_summary <- atlas_streaming_progress_summary(data.frame(
  table_name = c("huge_table", "huge_table", "other_table"),
  column_name = c("a", "b", "x"),
  query_category = "column_stream",
  strategy = "stream_column",
  estimated_rows = c(1000000, 1000000, 500000),
  chunks_fetched = c(10L, 12L, 5L),
  status = "ok",
  budget_decision = "streamed",
  elapsed_ms = c(1000, 2500, 500),
  message = "streamed one column in bounded chunks",
  stringsAsFactors = FALSE
))
expect_true(any(stream_summary$table_name == "huge_table" & stream_summary$streamed_columns == 2L), "Streaming progress summaries should count streamed columns by source.")
expect_true(any(stream_summary$table_name == "huge_table" & stream_summary$total_chunks == 22L), "Streaming progress summaries should sum chunk counts by source.")
expect_true(any(stream_summary$table_name == "huge_table" & stream_summary$slowest_column == "b"), "Streaming progress summaries should identify the slowest streamed column.")

Sys.setenv(DALYCARE_ATLAS_DB_STREAM_ROWS = "TRUE", DALYCARE_ATLAS_STREAM_THRESHOLD_ROWS = "100")
expect_equal(dbi_profile_strategy(101, "full"), "stream_column", "Large DB tables should use cursor/chunk streaming by default.")
expect_equal(dbi_profile_strategy(100, "full"), "sql_aggregate", "Small DB tables should keep the exact SQL aggregate path.")
expect_equal(dbi_profile_strategy(1000000, "schema"), "schema_metadata", "Schema mode should not scan data values.")
count_env <- new.env(parent = emptyenv())
assign("A", 1, envir = count_env)
assign("B", 2.5, envir = count_env)
count_vec <- env_numeric_counts(count_env)
expect_equal(unname(count_vec["A"]), 1, "Streamed count extraction should accept integer-like counts.")
expect_equal(unname(count_vec["B"]), 2.5, "Streamed count extraction should not fail when R stores counts as doubles.")

formerly_skipped_map <- utils::read.delim(file.path(root, "config", "source-map.dalycare.tsv"), stringsAsFactors = FALSE, check.names = FALSE)
formerly_skipped_names <- c(
  "SDS_t_tumor", "SDS_lab_forsker", "SDS_t_dodsaarsag_2",
  "view_diagnoses_all_hosp_region", "view_dalycare_diagnoses",
  "view_date_death", "view_date_followup", "view_true_date_death",
  "view_patient_table_os"
)
formerly_skipped_map <- formerly_skipped_map[formerly_skipped_map$table_name %in% formerly_skipped_names, , drop = FALSE]
formerly_skipped_tables <- data.frame(
  db_name = c("import", "import", "import", "core", "core", "core"),
  schema = rep("public", 6),
  table = c("SDS_t_tumor", "SDS_lab_forsker", "SDS_t_dodsaarsag_2", "diagnoses_all", "t_dalycare_diagnoses", "patient"),
  stringsAsFactors = FALSE
)
formerly_skipped_adapter <- list(
  list_tables = function() formerly_skipped_tables,
  table_row_count = function(db_name, schema, table) {
    rows <- c(SDS_t_tumor = 106316, SDS_lab_forsker = 129855400, SDS_t_dodsaarsag_2 = 28521,
              diagnoses_all = 1000, t_dalycare_diagnoses = 1000, patient = 1000)
    if (table %in% names(rows)) unname(rows[[table]]) else 1000
  }
)
formerly_skipped_resolution <- resolve_dalycare_sources(formerly_skipped_map, db_adapter = formerly_skipped_adapter)
expect_true(all(formerly_skipped_resolution$resolution_status == "resolved"), "The 9 formerly skipped DALY sources should resolve through exact or explicit backing-table mappings.")
formerly_skipped_plan <- memory_plan_for_sources(formerly_skipped_map, formerly_skipped_resolution)
expect_false(any(formerly_skipped_plan$chosen_strategy == "skipped_risky_full_load"), "Resolved formerly skipped sources should not be source-level skipped.")
expect_true(any(formerly_skipped_plan$table_name == "SDS_lab_forsker" & formerly_skipped_plan$chosen_strategy == "db_chunked"), "Huge resolved DALY tables should use DB chunked streaming instead of exact aggregate scans.")

skip_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode\tdomain\tsubdomain\tatlas_role",
  "example_labs\tfile\ttests/fixtures/example_labs.csv\t1\tfull\tSP\tLaboratory\tfixture",
  "large_dataset\tdataset\tlarge_dataset\t2\tfull\tDALY\tLarge\tguardrail"
), skip_map)
assign("load_dataset", function(dataset = NULL) stop("load_dataset should not be called for skipped risky full loads"), envir = .GlobalEnv)
Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = "FALSE")
Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN")
fail_root <- tempfile("atlas_empty_fail_")
empty_error <- tryCatch(
  run_atlas(project_root = root, source_map_path = skip_map, output_root = fail_root, mode = "report"),
  error = function(e) conditionMessage(e)
)
expect_true(grepl("Refusing to write a misleading live DALY atlas", empty_error, fixed = TRUE), "Dataset-backed DALY maps with zero profiled sources should fail loudly by default.")
failed_dirs <- list.dirs(fail_root, recursive = FALSE, full.names = TRUE)
expect_true(length(failed_dirs) == 1L, "Failed empty live runs should still leave one diagnostic run directory.")
expect_file(file.path(failed_dirs[[1]], "outputs", "atlas_dalycare_access.csv"))
expect_file(file.path(failed_dirs[[1]], "outputs", "atlas_run_action_items.csv"))
expect_file(file.path(failed_dirs[[1]], "outputs", "output_manifest.csv"))

Sys.setenv(DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN = "TRUE")
skip_result <- run_atlas(project_root = root, source_map_path = skip_map, output_root = tempfile("atlas_skip_"), mode = "report")
skip_sources <- utils::read.csv(file.path(skip_result$run_dir, "outputs", "atlas_sources.csv"), stringsAsFactors = FALSE)
skipped_source <- skip_sources[skip_sources$table_name == "large_dataset", , drop = FALSE]
expect_true(identical(skipped_source$load_status[[1]], "skipped"), "Risky unresolved dataset sources should be skipped before load_dataset() is called.")
expect_true(identical(skipped_source$chosen_strategy[[1]], "skipped_risky_full_load"), "Skipped source rows should record the memory guardrail strategy.")
expect_true(identical(skipped_source$domain[[1]], "DALY"), "Skipped source rows should keep source-map metadata aligned in atlas_sources.csv.")
expect_true(grepl("Skipped source:", skipped_source$message[[1]], fixed = TRUE), "Skipped source diagnostics should stay in the message column.")
skip_actions <- utils::read.csv(file.path(skip_result$run_dir, "outputs", "atlas_run_action_items.csv"), stringsAsFactors = FALSE)
expect_true(any(skip_actions$table_name == "large_dataset" & skip_actions$action_id == "skipped_risky_full_load"), "Skipped risky full-load sources should appear in run action items.")
if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) rm(load_dataset, envir = .GlobalEnv)
if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
