# One-click SMM Immunity Tracker aggregate mini-bundle runner.
# Source this file from RStudio or run it with Rscript from the project root.

.smm_immunity_count_entry_path <- local({
  cmd <- commandArgs(FALSE)
  file_arg <- grep("^--file=", cmd, value = TRUE)
  if (length(file_arg)) {
    normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE)
  } else if (!is.null(sys.frames()[[1]]$ofile)) {
    normalizePath(sys.frames()[[1]]$ofile, winslash = "/", mustWork = FALSE)
  } else {
    normalizePath("RUN_SMM_IMMUNITY_TRACKER_COUNTS.R", winslash = "/", mustWork = FALSE)
  }
})

.smm_immunity_count_default_project_root <- if (!is.na(.smm_immunity_count_entry_path) && nzchar(.smm_immunity_count_entry_path)) {
  dirname(.smm_immunity_count_entry_path)
} else {
  getwd()
}

.smm_immunity_count_find_project_root <- function(default_root) {
  default_root <- normalizePath(default_root, winslash = "/", mustWork = FALSE)
  if (file.exists(file.path(default_root, "scripts", "source_smm_immunity_tracker_counts.R"))) return(default_root)
  sourceables <- list.files(
    default_root,
    pattern = "^source_smm_immunity_tracker_counts[.]R$",
    recursive = TRUE,
    full.names = TRUE
  )
  sourceables <- sourceables[grepl("/scripts/source_smm_immunity_tracker_counts[.]R$", normalizePath(sourceables, winslash = "/", mustWork = FALSE))]
  if (length(sourceables)) return(normalizePath(file.path(dirname(sourceables[[1]]), ".."), winslash = "/", mustWork = TRUE))
  default_root
}

if (!exists("SMM_IMMUNITY_COUNT_MODE", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_MODE <- "plan"
}
if (!exists("SMM_IMMUNITY_COUNT_PROJECT_ROOT", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_PROJECT_ROOT <- .smm_immunity_count_find_project_root(.smm_immunity_count_default_project_root)
}
if (!exists("SMM_IMMUNITY_COUNT_OUTPUTS_DIR", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_OUTPUTS_DIR <- "outputs/smm_immunity_tracker_only"
}
if (!exists("SMM_IMMUNITY_COUNT_SMALL_CELL_N", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_SMALL_CELL_N <- 5L
}
if (!exists("SMM_IMMUNITY_WP5_OUTPUT_ROOT", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_WP5_OUTPUT_ROOT <- Sys.getenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT", unset = "")
}
if (!exists("SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR <- Sys.getenv("SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR", unset = "")
}
if (!exists("SMM_IMMUNITY_COUNT_DB_ADAPTER", envir = .GlobalEnv, inherits = FALSE)) {
  SMM_IMMUNITY_COUNT_DB_ADAPTER <- NULL
}

.smm_immunity_count_project_root <- normalizePath(SMM_IMMUNITY_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
.smm_immunity_count_sourceable <- file.path(.smm_immunity_count_project_root, "scripts", "source_smm_immunity_tracker_counts.R")
if (!file.exists(.smm_immunity_count_sourceable)) {
  stop(
    "Missing SMM Immunity Tracker sourceable count script: ", .smm_immunity_count_sourceable, "\n",
    "Open the DALY-CARE-ATLAS repository root or set SMM_IMMUNITY_COUNT_PROJECT_ROOT explicitly.",
    call. = FALSE
  )
}

assign(
  ".SMM_IMMUNITY_TRACKER_COUNT_SOURCE_CONFIG",
  list(
    SMM_IMMUNITY_COUNT_MODE = SMM_IMMUNITY_COUNT_MODE,
    SMM_IMMUNITY_COUNT_PROJECT_ROOT = .smm_immunity_count_project_root,
    SMM_IMMUNITY_COUNT_OUTPUTS_DIR = SMM_IMMUNITY_COUNT_OUTPUTS_DIR,
    SMM_IMMUNITY_COUNT_SMALL_CELL_N = SMM_IMMUNITY_COUNT_SMALL_CELL_N,
    SMM_IMMUNITY_WP5_OUTPUT_ROOT = SMM_IMMUNITY_WP5_OUTPUT_ROOT,
    SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR = SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR,
    SMM_IMMUNITY_COUNT_DB_ADAPTER = SMM_IMMUNITY_COUNT_DB_ADAPTER
  ),
  envir = .GlobalEnv
)

source(.smm_immunity_count_sourceable)
