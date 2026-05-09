root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

old_db_profile <- Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = NA)
old_max_full_load <- Sys.getenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS", unset = NA)
on.exit({
  if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
  if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
  if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) rm(load_dataset, envir = .GlobalEnv)
}, add = TRUE)
Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = "TRUE", DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = "3")

fake_damyda <- data.frame(
  patientid = c("0101011234", "0202022345", "0303033456", "0404044567", "0505055678", "0606066789"),
  Reg_Diagnose_dt = as.Date("2020-01-01") + 0:5,
  Stadie = c("I", "I", "II", "II", "II", "III"),
  ALB = c(34, 35, 36, 38, 39, 40),
  stringsAsFactors = FALSE
)
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
                           profile_mode = "full", top_n = 10L, min_cell_count = atlas_min_cell_count()) {
    if (!identical(table, "RKKP_DaMyDa")) stop("unexpected fake table")
    profile_source(
      fake_damyda,
      table_name = table_name,
      source_type = source_type,
      source = source,
      profile_mode = profile_mode,
      top_n = top_n,
      min_cell_count = min_cell_count
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

plan <- memory_plan_for_sources(source_map, resolution)
expect_true(any(plan$table_name == "RKKP_DaMyDa" & plan$chosen_strategy == "db_aggregate"), "Resolved DALY sources should prefer DB aggregate profiling.")
expect_true(any(plan$table_name == "RKKP_CLL" & plan$chosen_strategy == "skipped_risky_full_load"), "Ambiguous large DALY sources should not fall back to load_dataset() by default.")
expect_true(any(plan$table_name == "NOPE" & plan$chosen_strategy == "skipped_risky_full_load"), "Missing sources with unknown row counts should be skipped unless full-load fallback is allowed.")

db_profile <- profile_db_source(
  source_record = source_map[source_map$table_name == "RKKP_DaMyDa", , drop = FALSE],
  resolution_row = resolution[resolution$table_name == "RKKP_DaMyDa", , drop = FALSE],
  db_adapter = fake_adapter,
  profile_mode = "full",
  min_cell_count = 2L
)
expect_equal(nrow(db_profile$column_profiles), ncol(fake_damyda), "DB aggregate profile should emit one column profile per source column.")
expect_true(any(db_profile$column_profiles$column_name == "ALB" & db_profile$column_profiles$profile_kind == "numeric"), "DB aggregate profile should preserve numeric aggregate summaries.")
expect_false(any(db_profile$column_top_values$column_name == "patientid"), "DB aggregate top values must not expose patient identifiers.")
expect_true(any(db_profile$column_top_values$column_name == "Stadie" & db_profile$column_top_values$n >= 2), "DB aggregate top values should obey minimum-cell suppression.")

Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = "FALSE")
skip_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "large_dataset\tdataset\tlarge_dataset\t1\tfull"
), skip_map)
assign("load_dataset", function(dataset = NULL) stop("load_dataset should not be called for skipped risky full loads"), envir = .GlobalEnv)
skip_result <- run_atlas(project_root = root, source_map_path = skip_map, output_root = tempfile("atlas_skip_"), mode = "report")
skip_sources <- utils::read.csv(file.path(skip_result$run_dir, "outputs", "atlas_sources.csv"), stringsAsFactors = FALSE)
expect_true(identical(skip_sources$load_status[[1]], "skipped"), "Risky unresolved dataset sources should be skipped before load_dataset() is called.")
expect_true(identical(skip_sources$chosen_strategy[[1]], "skipped_risky_full_load"), "Skipped source rows should record the memory guardrail strategy.")
if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) rm(load_dataset, envir = .GlobalEnv)
if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
if (is.na(old_max_full_load)) Sys.unsetenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS") else Sys.setenv(DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS = old_max_full_load)
