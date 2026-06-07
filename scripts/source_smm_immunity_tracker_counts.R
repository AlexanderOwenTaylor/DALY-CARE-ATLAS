smm_immunity_tracker_sourceable_is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

smm_immunity_tracker_sourceable_resolve <- function(path, project_root) {
  if (is.null(path) || !length(path) || all(is.na(path))) path <- ""
  path <- as.character(path)
  if (!nzchar(path)) stop("SMM Immunity Tracker count output path cannot be empty.", call. = FALSE)
  path <- path.expand(path)
  if (smm_immunity_tracker_sourceable_is_absolute_path(path)) path else file.path(project_root, path)
}

smm_immunity_tracker_sourceable_source_required <- function(project_root, relative_path) {
  path <- file.path(project_root, relative_path)
  if (!file.exists(path)) stop("Required SMM Immunity Tracker helper file is missing: ", path, call. = FALSE)
  source(path)
}

config <- if (exists(".SMM_IMMUNITY_TRACKER_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
  get(".SMM_IMMUNITY_TRACKER_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
} else {
  list()
}

config_value <- function(name, default) {
  if (!is.null(config[[name]])) return(config[[name]])
  if (exists(name, envir = .GlobalEnv, inherits = FALSE)) return(get(name, envir = .GlobalEnv, inherits = FALSE))
  default
}

SMM_IMMUNITY_COUNT_MODE <- config_value("SMM_IMMUNITY_COUNT_MODE", "plan")
SMM_IMMUNITY_COUNT_PROJECT_ROOT <- config_value("SMM_IMMUNITY_COUNT_PROJECT_ROOT", ".")
SMM_IMMUNITY_COUNT_OUTPUTS_DIR <- config_value("SMM_IMMUNITY_COUNT_OUTPUTS_DIR", "outputs/smm_immunity_tracker_only")
SMM_IMMUNITY_COUNT_SMALL_CELL_N <- config_value("SMM_IMMUNITY_COUNT_SMALL_CELL_N", 5L)
SMM_IMMUNITY_WP5_OUTPUT_ROOT <- config_value("SMM_IMMUNITY_WP5_OUTPUT_ROOT", Sys.getenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT", unset = ""))
SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR <- config_value("SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR", Sys.getenv("SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR", unset = ""))
SMM_IMMUNITY_COUNT_DB_ADAPTER <- config_value("SMM_IMMUNITY_COUNT_DB_ADAPTER", NULL)

if (nzchar(SMM_IMMUNITY_WP5_OUTPUT_ROOT %||% "")) {
  Sys.setenv(SMM_IMMUNITY_WP5_OUTPUT_ROOT = SMM_IMMUNITY_WP5_OUTPUT_ROOT)
}

project_root <- normalizePath(SMM_IMMUNITY_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(smm_immunity_tracker_sourceable_resolve(SMM_IMMUNITY_COUNT_OUTPUTS_DIR, project_root), winslash = "/", mustWork = FALSE)
small_cell_n <- suppressWarnings(as.integer(SMM_IMMUNITY_COUNT_SMALL_CELL_N))
if (is.na(small_cell_n) || small_cell_n < 1L) small_cell_n <- 5L

smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "utils.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "source_map.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "profiler.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "mcl_triangle_counts.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "confluence_clone_evidence.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "confluence_feasibility.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "confluence_counts.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "smm_immunity_tracker_feasibility.R"))
smm_immunity_tracker_sourceable_source_required(project_root, file.path("R", "smm_immunity_tracker_counts.R"))

if (!SMM_IMMUNITY_COUNT_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported SMM_IMMUNITY_COUNT_MODE: ", SMM_IMMUNITY_COUNT_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE SMM Immunity Tracker aggregate mini-bundle runner\n")
cat("Mode: ", SMM_IMMUNITY_COUNT_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Small-cell threshold: ", small_cell_n, "\n", sep = "")
cat("WP5 output root: ", smm_immunity_tracker_wp5_output_root(project_root), "\n", sep = "")
if (nzchar(SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR %||% "")) {
  cat("Atlas output evidence dir: ", SMM_IMMUNITY_COUNT_ATLAS_OUTPUT_DIR, " (reserved; not required in v1)\n", sep = "")
}
if (identical(SMM_IMMUNITY_COUNT_MODE, "plan")) {
  cat("Plan mode: writing scaffold/readiness outputs and fail-closed aggregate audit rows; no database connection is opened.\n")
}
if (identical(SMM_IMMUNITY_COUNT_MODE, "production_aggregate")) {
  cat("Production aggregate mode: aggregate hook or secure WP5 source-reader outputs are accepted; row-level data are not written.\n")
}

smm_immunity_scaffold_outputs <- build_smm_immunity_tracker_feasibility_outputs(
  project_root = project_root,
  min_cell_count = small_cell_n
)
smm_immunity_count_outputs <- smm_immunity_tracker_count_build_outputs(
  project_root = project_root,
  db_adapter = SMM_IMMUNITY_COUNT_DB_ADAPTER,
  mode = SMM_IMMUNITY_COUNT_MODE,
  min_cell_count = small_cell_n
)
smm_immunity_outputs <- smm_immunity_tracker_count_merge_outputs(smm_immunity_scaffold_outputs, smm_immunity_count_outputs)
smm_immunity_paths <- smm_immunity_tracker_write_outputs(smm_immunity_outputs, output_dir)

assign("SMM_IMMUNITY_TRACKER_COUNT_RESULT", list(outputs = smm_immunity_outputs, paths = smm_immunity_paths), envir = .GlobalEnv)

summary_rows <- smm_immunity_outputs$production_execution_summary
summary_value <- function(metric, default = "") {
  if (!is.data.frame(summary_rows) || !nrow(summary_rows) || !"metric" %in% names(summary_rows)) return(default)
  hit <- summary_rows[summary_rows$metric == metric, , drop = FALSE]
  if (!nrow(hit)) return(default)
  hit$value[[1]] %||% default
}
accepted_rows <- function(x) {
  if (!is.data.frame(x) || !nrow(x) || !"acceptance_status" %in% names(x)) return(0L)
  sum(x$acceptance_status == "accepted", na.rm = TRUE)
}
failed_rows <- if (is.data.frame(smm_immunity_outputs$failed_query_audit)) nrow(smm_immunity_outputs$failed_query_audit) else 0L

cat("Production aggregate console summary:\n")
cat(" - count mode: ", summary_value("count_mode", SMM_IMMUNITY_COUNT_MODE), "\n", sep = "")
cat(" - production query attempted: ", summary_value("production_query_attempted", "FALSE"), "\n", sep = "")
cat(" - production query success: ", summary_value("production_query_success", "FALSE"), "\n", sep = "")
cat(" - internal cohort rows: ", summary_value("cohort_rows_internal", "0"), "\n", sep = "")
cat(" - internal infection event rows: ", summary_value("infection_event_rows_internal", "0"), "\n", sep = "")
cat(" - accepted cohort rows: ", accepted_rows(smm_immunity_outputs$cohort_counts), "\n", sep = "")
cat(" - accepted infection rows: ", accepted_rows(smm_immunity_outputs$infection_counts), "\n", sep = "")
cat(" - accepted landmark rows: ", accepted_rows(smm_immunity_outputs$landmark_progression_signal), "\n", sep = "")
cat(" - failed-query audit rows: ", failed_rows, "\n", sep = "")
failure <- summary_value("failure_reason", "")
if (nzchar(failure)) cat(" - production aggregate status: ", failure, "\n", sep = "")

cat("SMM Immunity Tracker mini-bundle outputs written:\n")
for (path in unlist(smm_immunity_paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}

invisible(SMM_IMMUNITY_TRACKER_COUNT_RESULT)
