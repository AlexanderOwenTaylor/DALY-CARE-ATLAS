confluence_count_sourceable_is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

confluence_count_sourceable_resolve <- function(path, project_root) {
  if (is.null(path) || !length(path) || all(is.na(path))) path <- ""
  path <- as.character(path)
  if (!nzchar(path)) stop("CONFLUENCE count output path cannot be empty.", call. = FALSE)
  path <- path.expand(path)
  if (confluence_count_sourceable_is_absolute_path(path)) path else file.path(project_root, path)
}

confluence_count_sourceable_source_required <- function(project_root, relative_path) {
  path <- file.path(project_root, relative_path)
  if (!file.exists(path)) stop("Required CONFLUENCE count helper file is missing: ", path, call. = FALSE)
  source(path)
}

config <- if (exists(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
  get(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
} else {
  list()
}
config_value <- function(name, default) {
  if (!is.null(config[[name]])) return(config[[name]])
  if (exists(name, envir = .GlobalEnv, inherits = FALSE)) return(get(name, envir = .GlobalEnv, inherits = FALSE))
  default
}

CONFLUENCE_COUNT_MODE <- config_value("CONFLUENCE_COUNT_MODE", "plan")
CONFLUENCE_COUNT_PROJECT_ROOT <- config_value("CONFLUENCE_COUNT_PROJECT_ROOT", ".")
CONFLUENCE_COUNT_OUTPUTS_DIR <- config_value("CONFLUENCE_COUNT_OUTPUTS_DIR", "outputs/confluence_only")
CONFLUENCE_COUNT_SMALL_CELL_N <- config_value("CONFLUENCE_COUNT_SMALL_CELL_N", 5L)
CONFLUENCE_COUNT_UPDATE_PAYLOAD <- config_value("CONFLUENCE_COUNT_UPDATE_PAYLOAD", FALSE)
CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR <- config_value("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", unset = ""))
CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP <- config_value("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", unset = ""))
CONFLUENCE_COUNT_DB_ADAPTER <- config_value("CONFLUENCE_COUNT_DB_ADAPTER", NULL)

project_root <- normalizePath(CONFLUENCE_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(confluence_count_sourceable_resolve(CONFLUENCE_COUNT_OUTPUTS_DIR, project_root), winslash = "/", mustWork = FALSE)
small_cell_n <- suppressWarnings(as.integer(CONFLUENCE_COUNT_SMALL_CELL_N))
if (is.na(small_cell_n) || small_cell_n < 1L) small_cell_n <- 5L

confluence_count_sourceable_source_required(project_root, file.path("R", "utils.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "source_map.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "profiler.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_counts.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_clone_evidence.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_feasibility.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_counts.R"))

if (!CONFLUENCE_COUNT_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported CONFLUENCE_COUNT_MODE: ", CONFLUENCE_COUNT_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE CONFLUENCE aggregate mini-bundle runner\n")
cat("Mode: ", CONFLUENCE_COUNT_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Small-cell threshold: ", small_cell_n, "\n", sep = "")
cat("Payload update enabled: ", isTRUE(CONFLUENCE_COUNT_UPDATE_PAYLOAD), " (not used in v1)\n", sep = "")
if (nzchar(CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR %||% "")) {
  cat("Atlas output evidence dir: ", CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR, " (reserved; not required in v1)\n", sep = "")
}
if (nzchar(CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP %||% "")) {
  cat("Atlas output evidence zip: ", CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP, " (reserved; not required in v1)\n", sep = "")
}
if (identical(CONFLUENCE_COUNT_MODE, "plan")) {
  cat("Plan mode: writing scaffold/readiness outputs and fail-closed aggregate audit rows; no database connection is opened.\n")
}
if (identical(CONFLUENCE_COUNT_MODE, "production_aggregate")) {
  cat("Production aggregate mode: aggregate DB-backed CONFLUENCE queries run only when a secure DALY-CARE DB adapter or hook is available.\n")
}

confluence_scaffold_outputs <- build_confluence_feasibility_outputs(
  project_root = project_root,
  min_cell_count = small_cell_n
)
confluence_count_outputs <- confluence_count_build_outputs(
  project_root = project_root,
  db_adapter = CONFLUENCE_COUNT_DB_ADAPTER,
  mode = CONFLUENCE_COUNT_MODE,
  min_cell_count = small_cell_n
)
confluence_outputs <- confluence_count_merge_outputs(confluence_scaffold_outputs, confluence_count_outputs)
confluence_paths <- confluence_write_outputs(confluence_outputs, output_dir)

assign("CONFLUENCE_COUNT_RESULT", list(outputs = confluence_outputs, paths = confluence_paths), envir = .GlobalEnv)

summary_rows <- confluence_outputs$production_execution_summary
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
failed_rows <- if (is.data.frame(confluence_outputs$failed_query_audit)) nrow(confluence_outputs$failed_query_audit) else 0L

cat("Production aggregate console summary:\n")
cat(" - count mode: ", summary_value("count_mode", CONFLUENCE_COUNT_MODE), "\n", sep = "")
cat(" - production query attempted: ", summary_value("production_query_attempted", "FALSE"), "\n", sep = "")
cat(" - production query success: ", summary_value("production_query_success", "FALSE"), "\n", sep = "")
cat(" - internal first-date rows: ", summary_value("first_date_state_rows", "0"), "\n", sep = "")
cat(" - internal infection event rows: ", summary_value("infection_event_rows_internal", "0"), "\n", sep = "")
cat(" - accepted disease-state person rows: ", accepted_rows(confluence_outputs$disease_state_person_counts), "\n", sep = "")
cat(" - accepted overlap rows: ", accepted_rows(confluence_outputs$overlap_counts_accepted), "\n", sep = "")
cat(" - accepted infection aggregate rows: ", accepted_rows(confluence_outputs$infection_counts), "\n", sep = "")
cat(" - accepted person-time rows: ", accepted_rows(confluence_outputs$infection_person_time), "\n", sep = "")
cat(" - failed-query audit rows: ", failed_rows, "\n", sep = "")
failure <- summary_value("failure_reason", "")
if (nzchar(failure)) {
  cat(" - production aggregate status: ", failure, "\n", sep = "")
}

cat("CONFLUENCE mini-bundle outputs written:\n")
for (path in unlist(confluence_paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}

invisible(CONFLUENCE_COUNT_RESULT)
