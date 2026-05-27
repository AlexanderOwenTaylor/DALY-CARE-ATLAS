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
MCL_COUNT_OUTPUTS_DIR <- config_value("MCL_COUNT_OUTPUTS_DIR", "outputs")
MCL_COUNT_SMALL_CELL_N <- config_value("MCL_COUNT_SMALL_CELL_N", 5L)
MCL_COUNT_UPDATE_PAYLOAD <- config_value("MCL_COUNT_UPDATE_PAYLOAD", FALSE)
MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- config_value("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = ""))
MCL_TRIANGLE_ATLAS_OUTPUT_ZIP <- config_value("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = ""))
MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY <- config_value("MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY", TRUE)
MCL_TRIANGLE_KI67_TEXT_SCAN <- config_value("MCL_TRIANGLE_KI67_TEXT_SCAN", Sys.getenv("MCL_TRIANGLE_KI67_TEXT_SCAN", unset = "false"))
MCL_TRIANGLE_KI67_THRESHOLD_PERCENT <- config_value("MCL_TRIANGLE_KI67_THRESHOLD_PERCENT", NA_integer_)

project_root <- normalizePath(MCL_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(mcl_count_sourceable_resolve(MCL_COUNT_OUTPUTS_DIR, project_root), winslash = "/", mustWork = FALSE)
small_cell_n <- suppressWarnings(as.integer(MCL_COUNT_SMALL_CELL_N))
if (is.na(small_cell_n) || small_cell_n < 1L) small_cell_n <- 5L

mcl_count_sourceable_source_required(project_root, file.path("R", "utils.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "source_map.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
mcl_count_sourceable_source_required(project_root, file.path("R", "mcl_triangle_counts.R"))

if (!MCL_COUNT_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported MCL_COUNT_MODE: ", MCL_COUNT_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE MCL/TRIANGLE aggregate cohort-size finder\n")
cat("Mode: ", MCL_COUNT_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Small-cell threshold: ", small_cell_n, "\n", sep = "")
cat("Payload update enabled: ", isTRUE(MCL_COUNT_UPDATE_PAYLOAD), "\n", sep = "")
if (nzchar(MCL_TRIANGLE_ATLAS_OUTPUT_DIR %||% "")) {
  cat("Atlas output evidence dir: ", MCL_TRIANGLE_ATLAS_OUTPUT_DIR, "\n", sep = "")
}
if (nzchar(MCL_TRIANGLE_ATLAS_OUTPUT_ZIP %||% "")) {
  cat("Atlas output evidence zip: ", MCL_TRIANGLE_ATLAS_OUTPUT_ZIP, "\n", sep = "")
}
cat("Ki-67 source inventory enabled: ", isTRUE(MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY), "\n", sep = "")
cat("Ki-67 text scan enabled: ", isTRUE(mcl_count_bool(MCL_TRIANGLE_KI67_TEXT_SCAN)), "\n", sep = "")
if (identical(MCL_COUNT_MODE, "plan")) {
  cat("Plan mode: writing aggregate-only SQL templates; no database connection is opened.\n")
}
if (identical(MCL_COUNT_MODE, "production_aggregate")) {
  cat("Production aggregate mode: aggregate DBI count queries run only when person-key, date, and value mappings are executable.\n")
}

mcl_triangle_count_outputs <- mcl_count_build_outputs(
  project_root = project_root,
  outputs_dir = output_dir,
  mode = MCL_COUNT_MODE,
  min_cell_count = small_cell_n,
  update_payload = isTRUE(MCL_COUNT_UPDATE_PAYLOAD),
  atlas_output_dir = MCL_TRIANGLE_ATLAS_OUTPUT_DIR,
  atlas_output_zip = MCL_TRIANGLE_ATLAS_OUTPUT_ZIP,
  run_ki67_source_inventory = isTRUE(MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY),
  ki67_text_scan = isTRUE(mcl_count_bool(MCL_TRIANGLE_KI67_TEXT_SCAN)),
  ki67_threshold_percent = MCL_TRIANGLE_KI67_THRESHOLD_PERCENT
)

mcl_triangle_count_paths <- mcl_count_write_outputs(mcl_triangle_count_outputs, output_dir)
assign("MCL_TRIANGLE_COUNT_RESULT", list(outputs = mcl_triangle_count_outputs, paths = mcl_triangle_count_paths), envir = .GlobalEnv)

summary_row <- mcl_triangle_count_outputs$execution_summary
if (is.data.frame(summary_row) && nrow(summary_row)) {
  cat("DB connection: ", if (isTRUE(summary_row$db_connection_attempted[[1]])) "attempted" else "not attempted", "\n", sep = "")
  cat("DB available: ", isTRUE(summary_row$db_connection_available[[1]]), "\n", sep = "")
  cat("Executable queries: ", summary_row$executable_queries[[1]], "\n", sep = "")
  cat("Executed queries: ", summary_row$executed_queries[[1]], "\n", sep = "")
  cat("Failed queries: ", summary_row$failed_queries[[1]] %||% 0L, "\n", sep = "")
  cat("Populated count outputs: ", summary_row$populated_count_outputs[[1]], "\n", sep = "")
  cat("Populated intersection outputs: ", summary_row$populated_intersection_outputs[[1]] %||% 0L, "\n", sep = "")
  cat("Atlas age inventory rows: ", summary_row$atlas_age_inventory_rows[[1]] %||% 0L, "\n", sep = "")
  cat("Age validation queries: ", summary_row$age_validation_queries[[1]] %||% 0L, "\n", sep = "")
  cat("Atlas treatment inventory rows: ", summary_row$atlas_treatment_inventory_rows[[1]] %||% 0L, "\n", sep = "")
  cat("Ibrutinib validation queries: ", summary_row$ibrutinib_validation_queries[[1]] %||% 0L, "\n", sep = "")
  cat("Atlas Ki-67 inventory rows: ", summary_row$atlas_ki67_inventory_rows[[1]] %||% 0L, "\n", sep = "")
  cat("Ki-67 validation queries: ", summary_row$ki67_validation_queries[[1]] %||% 0L, "\n", sep = "")
  cat("Core marginal counts succeeded: ", isTRUE(summary_row$core_marginal_counts_succeeded[[1]]), "\n", sep = "")
  cat("Age validation succeeded: ", isTRUE(summary_row$age_validation_succeeded[[1]]), "\n", sep = "")
  cat("Ibrutinib validation succeeded: ", isTRUE(summary_row$ibrutinib_validation_succeeded[[1]]), "\n", sep = "")
  cat("Ki-67 validation succeeded: ", isTRUE(summary_row$ki67_validation_succeeded[[1]]), "\n", sep = "")
  cat("Atlas ingestion succeeded: ", isTRUE(summary_row$atlas_ingestion_succeeded[[1]]), "\n", sep = "")
  cat("Acceptance status: ", summary_row$acceptance_status[[1]] %||% "", "\n", sep = "")
  if (nzchar(summary_row$failure_reason[[1]] %||% "")) {
    cat("Production aggregate status: ", summary_row$failure_reason[[1]], "\n", sep = "")
  }
}

count_display <- function(id) {
  x <- mcl_triangle_count_outputs$data_point_counts
  if (!is.data.frame(x) || !nrow(x)) return("")
  hit <- x[x$data_point_id == id, , drop = FALSE]
  if (!nrow(hit)) return("")
  display <- hit$distinct_person_count_display[[1]] %||% ""
  status <- hit$count_status[[1]] %||% ""
  if (nzchar(display)) display else status
}
cat("Production aggregate console summary:\n")
cat(" - count mode: ", MCL_COUNT_MODE, "\n", sep = "")
cat(" - executed queries: ", if (is.data.frame(summary_row) && nrow(summary_row)) summary_row$executed_queries[[1]] else 0L, "\n", sep = "")
cat(" - failed queries: ", if (is.data.frame(summary_row) && nrow(summary_row)) (summary_row$failed_queries[[1]] %||% 0L) else 0L, "\n", sep = "")
cat(" - populated intersections: ", if (is.data.frame(summary_row) && nrow(summary_row)) (summary_row$populated_intersection_outputs[[1]] %||% 0L) else 0L, "\n", sep = "")
cat(" - acceptance status: ", if (is.data.frame(summary_row) && nrow(summary_row)) (summary_row$acceptance_status[[1]] %||% "") else "", "\n", sep = "")
cat(" - all MCL count: ", count_display("all_lyfo_mcl"), "\n", sep = "")
cat(" - age <=65 count: ", count_display("younger_mcl_proxy_age_le_65"), "\n", sep = "")
cat(" - CIT count: ", count_display("cit_immunochemotherapy"), "\n", sep = "")
cat(" - Ibrutinib count: ", count_display("ibrutinib_exposure"), "\n", sep = "")
cat(" - ASCT/HDT count: ", count_display("asct_hdt_first_line"), "\n", sep = "")
cat(" - Ki-67 AEKI count: ", count_display("ki67_aeki"), "\n", sep = "")
cat(" - payload updated: ", isTRUE(mcl_triangle_count_outputs$payload_updated %||% FALSE), "\n", sep = "")

cat("MCL/TRIANGLE aggregate count outputs written:\n")
for (path in unlist(mcl_triangle_count_paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}
if (identical(MCL_COUNT_MODE, "production_aggregate") &&
    all(mcl_triangle_count_outputs$data_point_counts$count_status %in% c(
      "production_aggregate_failed_credentials_unavailable",
      "production_aggregate_failed_mapping_unavailable",
      "production_aggregate_failed_query_error",
      "count_not_available_requires_person_key_mapping",
      "count_not_available_requires_date_mapping",
      "count_not_available_requires_value_mapping",
      "count_not_available_requires_production_validation"
    ), na.rm = TRUE)) {
  cat("No executable production aggregate counts completed; query plans were written and no row counts were labelled as people.\n")
}

invisible(MCL_TRIANGLE_COUNT_RESULT)
