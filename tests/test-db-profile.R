root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

old_db_profile <- Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = NA)
old_max_full_load <- Sys.getenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS", unset = NA)
old_allow_empty <- Sys.getenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN", unset = NA)
old_db_access <- Sys.getenv("DALYCARE_DB_ACCESS_PATH", unset = NA)
old_max_text_distinct <- Sys.getenv("DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS", unset = NA)
on.exit({
  if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
  if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
  if (is.na(old_allow_empty)) Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN") else Sys.setenv(DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN = old_allow_empty)
  if (is.na(old_db_access)) Sys.unsetenv("DALYCARE_DB_ACCESS_PATH") else Sys.setenv(DALYCARE_DB_ACCESS_PATH = old_db_access)
  if (is.na(old_max_text_distinct)) Sys.unsetenv("DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS = old_max_text_distinct)
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
                           npu_dictionary = NULL) {
    if (!identical(table, "RKKP_DaMyDa")) stop("unexpected fake table")
    profile_source(
      fake_damyda,
      table_name = table_name,
      source_type = source_type,
      source = source,
      profile_mode = profile_mode,
      top_n = top_n,
      min_cell_count = min_cell_count,
      npu_dictionary = npu_dictionary
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

fake_db_access <- tempfile(fileext = ".R")
writeLines(c("pw <- 'not-secret-in-report'", "ignored <- 123"), fake_db_access)
Sys.setenv(DALYCARE_DB_ACCESS_PATH = fake_db_access)
access <- read_dalycare_db_access()
expect_true(access$password_present, "DB access reader should detect a pw symbol.")
report <- dalycare_access_report(source_map = alias_map, db_adapter = list(list_tables = function() alias_tables, table_row_count = function(...) 1L), source_resolution = alias_resolution)
report_text <- paste(capture.output(print(report)), collapse = "\n")
expect_false(grepl("not-secret-in-report", report_text, fixed = TRUE), "DB access diagnostics must not expose credential values.")

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
  npu_dictionary = npu_dictionary
)
expect_equal(nrow(db_profile$column_profiles), ncol(fake_damyda), "DB aggregate profile should emit one column profile per source column.")
expect_true(any(db_profile$column_profiles$column_name == "ALB" & db_profile$column_profiles$profile_kind == "numeric"), "DB aggregate profile should preserve numeric aggregate summaries.")
expect_false(any(db_profile$column_top_values$column_name == "patientid"), "DB aggregate top values must not expose patient identifiers.")
expect_true(any(db_profile$column_top_values$column_name == "Stadie" & db_profile$column_top_values$n >= 2), "DB aggregate top values should obey minimum-cell suppression.")
expect_true(any(db_profile$panels$lab_npu_code_coverage$lab_code == "NPU04998"), "DB aggregate profile should produce NPU code coverage without full-table loading.")
expect_true(any(db_profile$panels$npu_lab_usage_by_vector$consensus_vector == "CREATININE_CODES"), "DB aggregate profile should produce dictionary-aware NPU vector usage.")
expect_true(any(db_profile$panels$npu_lab_unmatched_codes$npu_code == "NPU99999"), "DB aggregate profile should produce suppressed-safe unmatched NPU summaries.")
Sys.setenv(DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS = "100")
expect_true(dbi_skip_distinct_count("text", "text", 101), "DB profiling should skip expensive distinct counts for huge text columns.")
expect_false(dbi_skip_distinct_count("text", "text", 100), "DB profiling should keep distinct counts for small text columns.")
expect_false(dbi_skip_distinct_count("integer", "int4", 1000000), "DB profiling should keep distinct counts for non-text columns.")

skip_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "large_dataset\tdataset\tlarge_dataset\t1\tfull"
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
expect_file(file.path(failed_dirs[[1]], "outputs", "output_manifest.csv"))

Sys.setenv(DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN = "TRUE")
skip_result <- run_atlas(project_root = root, source_map_path = skip_map, output_root = tempfile("atlas_skip_"), mode = "report")
skip_sources <- utils::read.csv(file.path(skip_result$run_dir, "outputs", "atlas_sources.csv"), stringsAsFactors = FALSE)
expect_true(identical(skip_sources$load_status[[1]], "skipped"), "Risky unresolved dataset sources should be skipped before load_dataset() is called.")
expect_true(identical(skip_sources$chosen_strategy[[1]], "skipped_risky_full_load"), "Skipped source rows should record the memory guardrail strategy.")
if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) rm(load_dataset, envir = .GlobalEnv)
if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
