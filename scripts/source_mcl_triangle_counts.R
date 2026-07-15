mcl_count_sourceable_is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

mcl_count_sourceable_resolve <- function(path, project_root) {
  if (is.null(path) || !length(path) || all(is.na(path))) path <- ""
  path <- as.character(path)
  if (!nzchar(path)) stop("MCL/TRIANGLE count output path cannot be empty.", call. = FALSE)
  path <- path.expand(path)
  if (mcl_count_sourceable_is_absolute_path(path)) path else file.path(project_root, path)
}

mcl_count_sourceable_source_required <- function(project_root, relative_path) {
  path <- file.path(project_root, relative_path)
  if (!file.exists(path)) stop("Required MCL/TRIANGLE count helper file is missing: ", path, call. = FALSE)
  source(path)
}

config <- if (exists(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
  get(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
} else {
  list()
}
config_value <- function(name, default) {
  if (!is.null(config[[name]])) return(config[[name]])
  if (exists(name, envir = .GlobalEnv, inherits = FALSE)) return(get(name, envir = .GlobalEnv, inherits = FALSE))
  default
}

MCL_COUNT_MODE <- config_value("MCL_COUNT_MODE", "plan")
MCL_COUNT_PROJECT_ROOT <- config_value("MCL_COUNT_PROJECT_ROOT", ".")
MCL_COUNT_OUTPUTS_DIR <- config_value("MCL_COUNT_OUTPUTS_DIR", "")
MCL_COUNT_OUTPUT_ROOT <- config_value(
  "MCL_COUNT_OUTPUT_ROOT",
  if (length(MCL_COUNT_OUTPUTS_DIR) && !is.na(MCL_COUNT_OUTPUTS_DIR[[1]]) && nzchar(as.character(MCL_COUNT_OUTPUTS_DIR[[1]]))) {
    MCL_COUNT_OUTPUTS_DIR
  } else {
    "atlas_runs"
  }
)
MCL_COUNT_SMALL_CELL_N <- config_value("MCL_COUNT_SMALL_CELL_N", 5L)
MCL_COUNT_UPDATE_PAYLOAD <- config_value("MCL_COUNT_UPDATE_PAYLOAD", FALSE)
MCL_COUNT_UPDATE_PAYLOAD_SUPPLIED <- config_value(
  "MCL_COUNT_UPDATE_PAYLOAD_SUPPLIED",
  !is.null(config[["MCL_COUNT_UPDATE_PAYLOAD"]]) || exists("MCL_COUNT_UPDATE_PAYLOAD", envir = .GlobalEnv, inherits = FALSE)
)
MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- config_value("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = ""))
MCL_TRIANGLE_ATLAS_OUTPUT_ZIP <- config_value("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = ""))
MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY <- config_value("MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY", TRUE)
MCL_TRIANGLE_KI67_TEXT_SCAN <- config_value("MCL_TRIANGLE_KI67_TEXT_SCAN", Sys.getenv("MCL_TRIANGLE_KI67_TEXT_SCAN", unset = "false"))
MCL_TRIANGLE_KI67_THRESHOLD_PERCENT <- config_value("MCL_TRIANGLE_KI67_THRESHOLD_PERCENT", NA_integer_)
MCL_COUNT_DB_ADAPTER <- config_value("MCL_COUNT_DB_ADAPTER", NULL)

project_root <- normalizePath(MCL_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
mcl_count_sourceable_source_required(project_root, file.path("R", "utils.R"))
output_root <- normalizePath(mcl_count_sourceable_resolve(MCL_COUNT_OUTPUT_ROOT, project_root), winslash = "/", mustWork = FALSE)
run_id <- atlas_run_id()
run_dir <- file.path(output_root, run_id)
output_dir <- file.path(run_dir, "outputs")
small_cell_n <- suppressWarnings(as.integer(MCL_COUNT_SMALL_CELL_N))
if (is.na(small_cell_n) || small_cell_n < 1L) small_cell_n <- 5L

mcl_count_sourceable_source_required(project_root, file.path("R", "source_map.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "semantic_dictionary.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "ki67_discovery.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_asct_hdt_evidence.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_counts.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_feasibility.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "atlas_bundle.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "html.R"))

if (!MCL_COUNT_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported MCL_COUNT_MODE: ", MCL_COUNT_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE MCL/TRIANGLE panel-only atlas runner\n")
cat("Mode: ", MCL_COUNT_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Run directory: ", run_dir, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Small-cell threshold: ", small_cell_n, "\n", sep = "")
if (length(MCL_COUNT_OUTPUTS_DIR) && !is.na(MCL_COUNT_OUTPUTS_DIR[[1]]) && nzchar(as.character(MCL_COUNT_OUTPUTS_DIR[[1]]))) {
  cat("MCL_COUNT_OUTPUTS_DIR is deprecated; use MCL_COUNT_OUTPUT_ROOT. The new setting takes precedence when both are supplied.\n")
}
if (isTRUE(MCL_COUNT_UPDATE_PAYLOAD_SUPPLIED)) {
  cat("MCL_COUNT_UPDATE_PAYLOAD is deprecated and ignored; this runner creates a fresh scoped atlas bundle.\n")
}
if (nzchar(MCL_TRIANGLE_ATLAS_OUTPUT_DIR %||% "")) {
  cat("Read-only atlas evidence directory: ", MCL_TRIANGLE_ATLAS_OUTPUT_DIR, "\n", sep = "")
}
if (nzchar(MCL_TRIANGLE_ATLAS_OUTPUT_ZIP %||% "")) {
  cat("Read-only atlas evidence ZIP: ", MCL_TRIANGLE_ATLAS_OUTPUT_ZIP, "\n", sep = "")
}
cat("Ki-67 source inventory enabled: ", isTRUE(MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY), "\n", sep = "")
cat("Ki-67 text scan enabled: ", isTRUE(mcl_count_bool(MCL_TRIANGLE_KI67_TEXT_SCAN)), "\n", sep = "")
if (identical(MCL_COUNT_MODE, "plan")) {
  cat("Plan mode: writing readiness material and fail-closed aggregate query plans; no database connection is opened.\n")
}
if (identical(MCL_COUNT_MODE, "production_aggregate")) {
  cat("Production aggregate mode: only MCL/TRIANGLE aggregate queries execute; 64-source profiling is not invoked.\n")
}

mcl_triangle_panel <- mcl_triangle_build_atlas_panel(
  project_root = project_root,
  db_adapter = MCL_COUNT_DB_ADAPTER,
  mode = MCL_COUNT_MODE,
  min_cell_count = small_cell_n,
  scaffold_args = list(),
  count_args = list(
    outputs_dir = output_dir,
    atlas_output_dir = MCL_TRIANGLE_ATLAS_OUTPUT_DIR,
    atlas_output_zip = MCL_TRIANGLE_ATLAS_OUTPUT_ZIP,
    run_ki67_source_inventory = isTRUE(MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY),
    ki67_text_scan = isTRUE(mcl_count_bool(MCL_TRIANGLE_KI67_TEXT_SCAN)),
    ki67_threshold_percent = MCL_TRIANGLE_KI67_THRESHOLD_PERCENT
  )
)
mcl_triangle_count_outputs <- attr(mcl_triangle_panel, "count_outputs")
attr(mcl_triangle_panel, "count_outputs") <- NULL
if (!is.list(mcl_triangle_count_outputs)) stop("Shared MCL/TRIANGLE panel builder did not return count outputs.", call. = FALSE)

mcl_triangle_paths <- mcl_triangle_write_outputs(mcl_triangle_panel, output_dir)
mcl_triangle_count_paths <- mcl_count_write_outputs(mcl_triangle_count_outputs, output_dir)

summary_row <- mcl_triangle_count_outputs$execution_summary %||% mcl_count_empty_execution_summary()
summary_value <- function(name, default = "") {
  if (!is.data.frame(summary_row) || !nrow(summary_row) || !name %in% names(summary_row)) return(default)
  summary_row[[name]][[1]] %||% default
}
failed_rows <- if (is.data.frame(mcl_triangle_count_outputs$failed_query_audit)) nrow(mcl_triangle_count_outputs$failed_query_audit) else 0L
atlas_input_audit <- mcl_triangle_count_outputs$atlas_input_audit %||% mcl_count_empty_atlas_input_audit()
evidence_provenance <- if (is.data.frame(atlas_input_audit) && nrow(atlas_input_audit)) {
  reason <- as.character(atlas_input_audit$selection_reason[[1]] %||% "")
  selected <- as.character(atlas_input_audit$selected_atlas_run[[1]] %||% "")
  if (nzchar(selected)) paste(reason, selected, sep = ":") else reason
} else {
  "atlas_input_not_supplied"
}

generated_at <- atlas_timestamp()
run_scope <- atlas_run_scope("triangle_only")
run_summary <- atlas_panel_run_summary(
  run_id = run_id,
  generated_at = generated_at,
  run_scope = run_scope,
  execution_summary = summary_row,
  failed_query_audit = mcl_triangle_count_outputs$failed_query_audit,
  min_cell_count = small_cell_n,
  evidence_input_provenance = evidence_provenance
)
run_summary_path <- write_csv(run_summary, file.path(output_dir, "atlas_run_summary.csv"))
payload <- atlas_scoped_panel_payload(
  run_id = run_id,
  generated_at = generated_at,
  run_scope = run_scope,
  run_summary = run_summary,
  panel_payloads = list(mcl_triangle_feasibility = mcl_triangle_panel)
)

bool_text <- function(x) if (isTRUE(x)) "TRUE" else "FALSE"
execution_log <- data.frame(
  timestamp = generated_at,
  level = if (identical(MCL_COUNT_MODE, "plan") || isTRUE(summary_value("production_aggregate_succeeded", FALSE))) "info" else "warning",
  table_name = "mcl_triangle_feasibility",
  message = paste0(
    "TRIANGLE-only atlas; run_profile=", run_scope$profile,
    "; executed_panel=", paste(run_scope$executed_panels, collapse = ","),
    "; source_profiling_executed=", bool_text(run_scope$source_profiling_executed),
    "; mode=", MCL_COUNT_MODE,
    "; db_attempted=", bool_text(summary_value("db_connection_attempted", FALSE)),
    "; db_available=", bool_text(summary_value("db_connection_available", FALSE)),
    "; executable_queries=", summary_value("executable_queries", 0L),
    "; executed_queries=", summary_value("executed_queries", 0L),
    "; failed_queries=", summary_value("failed_queries", failed_rows),
    "; populated_counts=", summary_value("populated_count_outputs", 0L),
    "; populated_intersections=", summary_value("populated_intersection_outputs", 0L),
    "; acceptance_status=", summary_value("acceptance_status", ""),
    "; suppression_threshold=", small_cell_n,
    "; optional_atlas_evidence_input=", evidence_provenance
  ),
  stringsAsFactors = FALSE
)

manifest_readiness_paths <- mcl_triangle_paths
names(manifest_readiness_paths) <- paste0("mcl_triangle_", names(manifest_readiness_paths))
manifest_count_paths <- mcl_triangle_count_paths
names(manifest_count_paths) <- paste0("mcl_triangle_count_", names(manifest_count_paths))
manifest_paths <- c(manifest_readiness_paths, manifest_count_paths, list(run_summary = run_summary_path))
bundle <- atlas_write_bundle(
  run_dir = run_dir,
  project_root = project_root,
  payload = payload,
  artifact_paths = manifest_paths,
  execution_log = execution_log
)

MCL_TRIANGLE_COUNT_RESULT <- list(
  run_id = run_id,
  run_dir = run_dir,
  outputs = mcl_triangle_panel,
  paths = c(
    mcl_triangle_paths,
    mcl_triangle_count_paths,
    list(run_summary = run_summary_path, execution_log = bundle$execution_log)
  ),
  html = bundle$html,
  payload = bundle$payload,
  manifest = bundle$manifest
)
assign("MCL_TRIANGLE_COUNT_RESULT", MCL_TRIANGLE_COUNT_RESULT, envir = .GlobalEnv)

cat("Production aggregate console summary:\n")
cat(" - count mode: ", MCL_COUNT_MODE, "\n", sep = "")
cat(" - executable queries: ", summary_value("executable_queries", 0L), "\n", sep = "")
cat(" - executed queries: ", summary_value("executed_queries", 0L), "\n", sep = "")
cat(" - failed queries: ", summary_value("failed_queries", failed_rows), "\n", sep = "")
cat(" - populated count outputs: ", summary_value("populated_count_outputs", 0L), "\n", sep = "")
cat(" - populated intersections: ", summary_value("populated_intersection_outputs", 0L), "\n", sep = "")
cat(" - acceptance status: ", summary_value("acceptance_status", ""), "\n", sep = "")
cat("MCL/TRIANGLE panel-only atlas outputs written:\n")
for (path in unlist(c(mcl_triangle_paths, mcl_triangle_count_paths), use.names = FALSE)) cat(" - ", path, "\n", sep = "")
cat(" - ", bundle$html, "\n", sep = "")
cat(" - ", bundle$payload, "\n", sep = "")
cat(" - ", bundle$manifest, "\n", sep = "")

invisible(MCL_TRIANGLE_COUNT_RESULT)
