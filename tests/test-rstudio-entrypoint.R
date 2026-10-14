root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

entrypoint <- file.path(root, "RUN_DALYCARE_ATLAS_73_SOURCE.R")
expect_file(entrypoint)
runner_text <- paste(readLines(entrypoint,warn=FALSE),collapse="\n")
expect_false(grepl("\\bquit\\s*\\(|\\bq\\s*\\(",runner_text))
old_source_map <- Sys.getenv("DALYCARE_ATLAS_SOURCE_MAP", unset = NA)
old_output_root <- Sys.getenv("DALYCARE_ATLAS_OUTPUT_ROOT", unset = NA)
old_mode <- Sys.getenv("DALYCARE_ATLAS_MODE", unset = NA)
old_allow_empty <- Sys.getenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN", unset = NA)
old_db_profile <- Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = NA)
on.exit({
  if (is.na(old_source_map)) Sys.unsetenv("DALYCARE_ATLAS_SOURCE_MAP") else Sys.setenv(DALYCARE_ATLAS_SOURCE_MAP = old_source_map)
  if (is.na(old_output_root)) Sys.unsetenv("DALYCARE_ATLAS_OUTPUT_ROOT") else Sys.setenv(DALYCARE_ATLAS_OUTPUT_ROOT = old_output_root)
  if (is.na(old_mode)) Sys.unsetenv("DALYCARE_ATLAS_MODE") else Sys.setenv(DALYCARE_ATLAS_MODE = old_mode)
  if (is.na(old_allow_empty)) Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN") else Sys.setenv(DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN = old_allow_empty)
  if (is.na(old_db_profile)) Sys.unsetenv("DALYCARE_ATLAS_DB_PROFILE") else Sys.setenv(DALYCARE_ATLAS_DB_PROFILE = old_db_profile)
  for (nm in c("dalycare_atlas_result", "dalycare_atlas_last_error", "dalycare_atlas_failed")) {
    if (exists(nm, envir = .GlobalEnv, inherits = FALSE)) rm(list = nm, envir = .GlobalEnv)
  }
}, add = TRUE)

example_out <- tempfile("atlas_entry_example_")
Sys.setenv(
  DALYCARE_ATLAS_SOURCE_MAP = "config/source-map.example.tsv",
  DALYCARE_ATLAS_OUTPUT_ROOT = example_out,
  DALYCARE_ATLAS_MODE = "report"
)
Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN")
sys.source(entrypoint, envir = new.env(parent = .GlobalEnv))
expect_true(exists("dalycare_atlas_result", envir = .GlobalEnv, inherits = FALSE), "Entrypoint should save successful results in the global environment.")
expect_false(isTRUE(get("dalycare_atlas_failed", envir = .GlobalEnv)), "Entrypoint should mark fixture runs as successful.")
entry_result <- get("dalycare_atlas_result", envir = .GlobalEnv)
expect_file(entry_result$html)
expect_file(entry_result$payload)

failing_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "RKKP_CLL\tdataset\tRKKP_CLL\t1\tsummary"
), failing_map)
failing_out <- tempfile("atlas_entry_fail_")
Sys.setenv(
  DALYCARE_ATLAS_SOURCE_MAP = failing_map,
  DALYCARE_ATLAS_OUTPUT_ROOT = failing_out,
  DALYCARE_ATLAS_MODE = "report",
  DALYCARE_ATLAS_DB_PROFILE = "FALSE"
)
Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN")
assign("dalycare_atlas_result", entry_result, envir = .GlobalEnv)
sys.source(entrypoint, envir = new.env(parent = .GlobalEnv))
expect_true(isTRUE(get("dalycare_atlas_failed", envir = .GlobalEnv)), "Entrypoint should catch live-run failures and keep R alive.")
expect_true(inherits(get("dalycare_atlas_last_error", envir = .GlobalEnv), "error"), "Entrypoint should retain the failure object for inspection.")
failed_dirs <- list.dirs(failing_out, recursive = FALSE, full.names = TRUE)
expect_true(length(failed_dirs) == 1L, "Failed entrypoint runs should leave a diagnostic run directory.")
expect_file(file.path(failed_dirs[[1]], "outputs", "atlas_dalycare_access.csv"))

expect_false(exists("dalycare_atlas_result",envir=.GlobalEnv,inherits=FALSE),"A failed rerun must clear the previous successful result.")
expect_file(file.path(failed_dirs[[1]],"outputs/atlas_completion_summary.csv"))
report <- read.csv(file.path(failed_dirs[[1]],"outputs/atlas_registry_completion.csv"))
expect_equal(report$source_status[report$table_name=="RKKP_CLL"],"source_unavailable")
summary <- read.csv(file.path(failed_dirs[[1]],"outputs/atlas_completion_summary.csv"))
expect_equal(summary$value[summary$metric=="build_status"],"failed")
# Failure before run creation must not reuse an older output path.
Sys.setenv(DALYCARE_ATLAS_SOURCE_MAP=paste0(failing_map,".missing"),DALYCARE_ATLAS_OUTPUT_ROOT=example_out)
assign("dalycare_atlas_result", entry_result, envir = .GlobalEnv)
early <- capture.output(sys.source(entrypoint,envir=new.env(parent=.GlobalEnv)))
expect_true(isTRUE(get("dalycare_atlas_failed", envir = .GlobalEnv)), "Early failures must keep R alive and mark the attempt as failed.")
early_error <- get("dalycare_atlas_last_error", envir = .GlobalEnv)
expect_true(inherits(early_error, "atlas_build_error"), "Early failures must retain a structured recovery error.")
expect_equal(early_error$stage, "preflight")
expect_equal(early_error$code, "invalid_source_map")
expect_file(early_error$diagnostics)
recovery_path <- file.path(dirname(early_error$diagnostics), "atlas_recovery.txt")
expect_file(recovery_path)
early_state <- read.delim(early_error$diagnostics, stringsAsFactors = FALSE)
expect_equal(early_state$value[early_state$metric == "run_status"], "failed")
expect_equal(early_state$value[early_state$metric == "failing_stage"], "preflight")
expect_true(nzchar(early_state$value[early_state$metric == "recovery_instructions"]), "Early failures must retain recovery instructions.")
early_paths <- gsub("\\", "/", early, fixed = TRUE)
expect_true(any(grepl(normalizePath(early_error$diagnostics, winslash = "/"), early_paths, fixed = TRUE)), "Entrypoint must print the current durable diagnostic path.")
expect_true(any(grepl(normalizePath(recovery_path, winslash = "/"), early_paths, fixed = TRUE)), "Entrypoint must print the current recovery instructions path.")
for (old_run in c(entry_result$run_dir, failed_dirs[[1]])) {
  expect_false(any(grepl(normalizePath(old_run, winslash = "/"), early_paths, fixed = TRUE)), "Early failures must not report a previous run directory.")
}
expect_false(exists("dalycare_atlas_result",envir=.GlobalEnv,inherits=FALSE))
