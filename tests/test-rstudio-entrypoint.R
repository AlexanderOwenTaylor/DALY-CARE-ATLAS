root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

runner_specs <- data.frame(
  file = c(
    "RUN_DALYCARE_ATLAS.R",
    "RUN_DALYCARE_ATLAS_48_SOURCE.R",
    "RUN_DALYCARE_ATLAS_64_SOURCE.R"
  ),
  default_source_map = c(
    "config/source-map.dalycare.tsv",
    "config/source-map.dalycare.tsv",
    "config/source-map.dalycare64.restored.tsv"
  ),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(runner_specs))) {
  runner_file <- runner_specs$file[[i]]
  runner_path <- file.path(root, runner_file)
  expect_file(runner_path)
  runner_text <- paste(readLines(runner_path, warn = FALSE), collapse = "\n")
  expect_false(grepl("\\bquit\\s*\\(", runner_text), paste(runner_file, "must not call quit()."))
  expect_false(grepl("\\bq\\s*\\(", runner_text), paste(runner_file, "must not call q()."))
  expect_true(
    grepl(paste0('candidate <- file.path(getwd(), "', runner_file, '")'), runner_text, fixed = TRUE),
    paste(runner_file, "should discover its own file name.")
  )
  expect_true(
    grepl(paste0('basename(if (is.na(.dalycare_entry_path)) "" else .dalycare_entry_path), "', runner_file, '"'), runner_text, fixed = TRUE),
    paste(runner_file, "should guard against redirects using its own file name.")
  )
  expect_true(
    grepl(paste0('Sys.getenv("DALYCARE_ATLAS_SOURCE_MAP", unset = "', runner_specs$default_source_map[[i]], '")'), runner_text, fixed = TRUE),
    paste(runner_file, "should default to the expected source map.")
  )
  if (!identical(runner_file, "RUN_DALYCARE_ATLAS.R")) {
    expect_false(
      grepl('file.path(getwd(), "RUN_DALYCARE_ATLAS.R")', runner_text, fixed = TRUE),
      paste(runner_file, "must not redirect back to the default one-click runner.")
    )
  }
}

entrypoint <- file.path(root, "RUN_DALYCARE_ATLAS.R")

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
  "large_dataset\tdataset\tlarge_dataset\t1\tfull"
), failing_map)
failing_out <- tempfile("atlas_entry_fail_")
Sys.setenv(
  DALYCARE_ATLAS_SOURCE_MAP = failing_map,
  DALYCARE_ATLAS_OUTPUT_ROOT = failing_out,
  DALYCARE_ATLAS_MODE = "report",
  DALYCARE_ATLAS_DB_PROFILE = "FALSE"
)
Sys.unsetenv("DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN")
assign("dalycare_atlas_result", NULL, envir = .GlobalEnv)
sys.source(entrypoint, envir = new.env(parent = .GlobalEnv))
expect_true(isTRUE(get("dalycare_atlas_failed", envir = .GlobalEnv)), "Entrypoint should catch live-run failures and keep R alive.")
expect_true(inherits(get("dalycare_atlas_last_error", envir = .GlobalEnv), "error"), "Entrypoint should retain the failure object for inspection.")
failed_dirs <- list.dirs(failing_out, recursive = FALSE, full.names = TRUE)
expect_true(length(failed_dirs) == 1L, "Failed entrypoint runs should leave a diagnostic run directory.")
expect_file(file.path(failed_dirs[[1]], "outputs", "atlas_dalycare_access.csv"))
