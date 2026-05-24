root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)

runner <- file.path(root, "RUN_KI67_FINDER.R")
sourceable <- file.path(root, "scripts", "source_ki67_finder.R")
expect_file(runner)
expect_file(sourceable)

runner_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
sourceable_text <- paste(readLines(sourceable, warn = FALSE), collapse = "\n")
combined <- paste(runner_text, sourceable_text, collapse = "\n")
expect_false(grepl("run_atlas\\s*\\(", combined, perl = TRUE), "One-click Ki-67 finder must not call run_atlas().")
expect_false(grepl("RUN_DALYCARE_ATLAS|scripts/run_atlas[.]R|R/run_atlas[.]R", combined, ignore.case = TRUE), "One-click Ki-67 finder must not source the full atlas runner.")
expect_false(grepl("\\bquit\\s*\\(|\\bq\\s*\\(", combined, perl = TRUE), "One-click Ki-67 finder must not quit the RStudio session.")

plan_dir <- tempfile("ki67_oneclick_plan_")
dir.create(plan_dir, recursive = TRUE, showWarnings = FALSE)
env <- new.env(parent = globalenv())
env$KI67_MODE <- "plan"
env$KI67_PROJECT_ROOT <- root
env$KI67_OUTPUTS_DIR <- plan_dir
env$KI67_CANDIDATE_TABLES <- c("RKKP_LYFO")
env$KI67_UPDATE_MCL <- FALSE
env$KI67_FULL_SCAN <- FALSE
sys.source(runner, envir = env)
expect_file(file.path(plan_dir, "ki67_db_search_plan.csv"))
expect_file(file.path(plan_dir, "ki67_db_query_templates.sql"))
expect_file(file.path(plan_dir, "ki67_found_locations.csv"))
expect_equal(env$KI67_MODE, "plan", "Runner should respect user preset KI67_MODE.")
expect_true(exists("KI67_FINDER_RESULT", envir = .GlobalEnv, inherits = FALSE), "Runner should expose a concise KI67_FINDER_RESULT object.")

prod_dir <- tempfile("ki67_oneclick_prod_")
dir.create(prod_dir, recursive = TRUE, showWarnings = FALSE)
env2 <- new.env(parent = globalenv())
env2$KI67_MODE <- "production_aggregate"
env2$KI67_PROJECT_ROOT <- root
env2$KI67_OUTPUTS_DIR <- prod_dir
env2$KI67_CANDIDATE_TABLES <- c("pato")
env2$KI67_UPDATE_MCL <- FALSE
env2$KI67_FULL_SCAN <- FALSE
sys.source(runner, envir = env2)
expect_file(file.path(prod_dir, "ki67_db_aeki_code_counts.csv"))
prod_counts <- read_delimited_file(file.path(prod_dir, "ki67_db_aeki_code_counts.csv"))
expect_true(nrow(prod_counts) >= 0, "Production mode should fail safely or write aggregate counts without credentials.")

all_outputs <- list.files(c(plan_dir, prod_dir), recursive = TRUE, full.names = TRUE)
for (path in all_outputs) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl("SELECT \\*|LIMIT 10|patientid|\\bcpr\\b|personnummer", text, ignore.case = TRUE, perl = TRUE), paste("One-click output should remain aggregate-only:", basename(path)))
}

outside_dir <- tempfile("ki67_oneclick_outside_")
outside_out <- tempfile("ki67_oneclick_outside_outputs_")
dir.create(outside_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(outside_out, recursive = TRUE, showWarnings = FALSE)
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(outside_dir)
env3 <- new.env(parent = globalenv())
env3$KI67_MODE <- "plan"
env3$KI67_OUTPUTS_DIR <- outside_out
env3$KI67_CANDIDATE_TABLES <- c("RKKP_LYFO")
env3$KI67_UPDATE_MCL <- FALSE
env3$KI67_FULL_SCAN <- FALSE
source(runner, local = env3)
expect_equal(
  normalizePath(env3$KI67_PROJECT_ROOT, winslash = "/", mustWork = TRUE),
  root,
  "Runner sourced from outside the repo should default KI67_PROJECT_ROOT to its own file location."
)
expect_file(file.path(outside_out, "ki67_db_search_plan.csv"))
