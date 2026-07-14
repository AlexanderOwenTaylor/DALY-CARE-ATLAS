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
CONFLUENCE_COUNT_OUTPUTS_DIR <- config_value("CONFLUENCE_COUNT_OUTPUTS_DIR", "")
CONFLUENCE_COUNT_OUTPUT_ROOT <- config_value(
  "CONFLUENCE_COUNT_OUTPUT_ROOT",
  if (length(CONFLUENCE_COUNT_OUTPUTS_DIR) && !is.na(CONFLUENCE_COUNT_OUTPUTS_DIR[[1]]) && nzchar(as.character(CONFLUENCE_COUNT_OUTPUTS_DIR[[1]]))) {
    CONFLUENCE_COUNT_OUTPUTS_DIR
  } else {
    "atlas_runs"
  }
)
CONFLUENCE_COUNT_SMALL_CELL_N <- config_value("CONFLUENCE_COUNT_SMALL_CELL_N", 5L)
CONFLUENCE_COUNT_UPDATE_PAYLOAD <- config_value("CONFLUENCE_COUNT_UPDATE_PAYLOAD", FALSE)
CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR <- config_value("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", unset = ""))
CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP <- config_value("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", unset = ""))
CONFLUENCE_COUNT_DB_ADAPTER <- config_value("CONFLUENCE_COUNT_DB_ADAPTER", NULL)

project_root <- normalizePath(CONFLUENCE_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
confluence_count_sourceable_source_required(project_root, file.path("R", "utils.R"))
output_root <- normalizePath(confluence_count_sourceable_resolve(CONFLUENCE_COUNT_OUTPUT_ROOT, project_root), winslash = "/", mustWork = FALSE)
run_id <- atlas_run_id()
run_dir <- file.path(output_root, run_id)
output_dir <- file.path(run_dir, "outputs")
small_cell_n <- suppressWarnings(as.integer(CONFLUENCE_COUNT_SMALL_CELL_N))
if (is.na(small_cell_n) || small_cell_n < 1L) small_cell_n <- 5L

confluence_count_sourceable_source_required(project_root, file.path("R", "source_map.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_counts.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_clone_evidence.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_feasibility.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "confluence_counts.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "atlas_bundle.R"))
confluence_count_sourceable_source_required(project_root, file.path("R", "html.R"))

if (!CONFLUENCE_COUNT_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported CONFLUENCE_COUNT_MODE: ", CONFLUENCE_COUNT_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE CONFLUENCE panel-only atlas runner\n")
cat("Mode: ", CONFLUENCE_COUNT_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Run directory: ", run_dir, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Small-cell threshold: ", small_cell_n, "\n", sep = "")
if (length(CONFLUENCE_COUNT_OUTPUTS_DIR) && !is.na(CONFLUENCE_COUNT_OUTPUTS_DIR[[1]]) && nzchar(as.character(CONFLUENCE_COUNT_OUTPUTS_DIR[[1]]))) {
  cat("CONFLUENCE_COUNT_OUTPUTS_DIR is deprecated; use CONFLUENCE_COUNT_OUTPUT_ROOT. The new setting takes precedence when both are supplied.\n")
}
if (isTRUE(CONFLUENCE_COUNT_UPDATE_PAYLOAD) || nzchar(CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR %||% "") || nzchar(CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP %||% "")) {
  cat("Deprecated overlay settings were supplied and are ignored; this runner creates a fresh scoped atlas bundle.\n")
}
if (identical(CONFLUENCE_COUNT_MODE, "plan")) {
  cat("Plan mode: writing scaffold/readiness outputs and fail-closed aggregate audit rows; no database connection is opened.\n")
}
if (identical(CONFLUENCE_COUNT_MODE, "production_aggregate")) {
  cat("Production aggregate mode: aggregate DB-backed CONFLUENCE queries run only when a secure DALY-CARE DB adapter or hook is available.\n")
}

confluence_outputs <- confluence_build_atlas_panel(
  project_root = project_root,
  db_adapter = CONFLUENCE_COUNT_DB_ADAPTER,
  mode = CONFLUENCE_COUNT_MODE,
  min_cell_count = small_cell_n,
  scaffold_args = list()
)
confluence_paths <- confluence_write_outputs(confluence_outputs, output_dir)

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

generated_at <- atlas_timestamp()
run_scope <- atlas_run_scope("confluence_only")
run_summary <- atlas_panel_run_summary(
  run_id = run_id,
  generated_at = generated_at,
  run_scope = run_scope,
  production_execution_summary = confluence_outputs$production_execution_summary,
  failed_query_audit = confluence_outputs$failed_query_audit,
  min_cell_count = small_cell_n
)
run_summary_path <- write_csv(run_summary, file.path(output_dir, "atlas_run_summary.csv"))
payload <- atlas_scoped_panel_payload(
  run_id = run_id,
  generated_at = generated_at,
  run_scope = run_scope,
  run_summary = run_summary,
  confluence_feasibility = confluence_outputs
)
execution_log <- data.frame(
  timestamp = generated_at,
  level = if (identical(summary_value("production_query_success", "FALSE"), "TRUE")) "info" else "warning",
  table_name = "confluence_feasibility",
  message = paste0(
    "CONFLUENCE-only atlas; run_profile=", run_scope$profile,
    "; executed_panel=", paste(run_scope$executed_panels, collapse = ","),
    "; source_profiling_executed=", if (isTRUE(run_scope$source_profiling_executed)) "TRUE" else "FALSE",
    "; mode=", CONFLUENCE_COUNT_MODE,
    "; attempted=", summary_value("production_query_attempted", "FALSE"),
    "; success=", summary_value("production_query_success", "FALSE"),
    "; failed_queries=", failed_rows,
    "; suppression_threshold=", small_cell_n
  ),
  stringsAsFactors = FALSE
)
manifest_paths <- confluence_paths
names(manifest_paths) <- paste0("confluence_", names(manifest_paths))
manifest_paths$run_summary <- run_summary_path
bundle <- atlas_write_bundle(
  run_dir = run_dir,
  project_root = project_root,
  payload = payload,
  artifact_paths = manifest_paths,
  execution_log = execution_log
)

CONFLUENCE_COUNT_RESULT <- list(
  run_id = run_id,
  run_dir = run_dir,
  outputs = confluence_outputs,
  paths = c(confluence_paths, list(run_summary = run_summary_path, execution_log = bundle$execution_log)),
  html = bundle$html,
  payload = bundle$payload,
  manifest = bundle$manifest
)
assign("CONFLUENCE_COUNT_RESULT", CONFLUENCE_COUNT_RESULT, envir = .GlobalEnv)

cat("CONFLUENCE panel-only atlas outputs written:\n")
for (path in unlist(confluence_paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}
cat(" - ", bundle$html, "\n", sep = "")
cat(" - ", bundle$payload, "\n", sep = "")
cat(" - ", bundle$manifest, "\n", sep = "")

invisible(CONFLUENCE_COUNT_RESULT)
