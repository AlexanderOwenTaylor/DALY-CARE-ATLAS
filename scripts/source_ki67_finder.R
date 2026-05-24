ki67_sourceable_is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

ki67_sourceable_resolve <- function(path, project_root) {
  if (is.null(path) || !length(path) || all(is.na(path))) path <- ""
  path <- as.character(path)
  if (!nzchar(path)) stop("Ki-67 output path cannot be empty.", call. = FALSE)
  path <- path.expand(path)
  if (ki67_sourceable_is_absolute_path(path)) path else file.path(project_root, path)
}

ki67_sourceable_source_required <- function(project_root, relative_path) {
  path <- file.path(project_root, relative_path)
  if (!file.exists(path)) stop("Required Ki-67 helper file is missing: ", path, call. = FALSE)
  source(path)
}

config <- if (exists(".KI67_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
  get(".KI67_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
} else {
  list()
}
config_value <- function(name, default) {
  if (!is.null(config[[name]])) return(config[[name]])
  if (exists(name, envir = .GlobalEnv, inherits = FALSE)) return(get(name, envir = .GlobalEnv, inherits = FALSE))
  default
}

KI67_MODE <- config_value("KI67_MODE", "production_aggregate")
KI67_CANDIDATE_TABLES <- config_value("KI67_CANDIDATE_TABLES", c("pato", "t_mikro", "t_konk", "RKKP_LYFO"))
KI67_FULL_SCAN <- config_value("KI67_FULL_SCAN", FALSE)
KI67_UPDATE_MCL <- config_value("KI67_UPDATE_MCL", TRUE)
KI67_PROJECT_ROOT <- config_value("KI67_PROJECT_ROOT", ".")
KI67_OUTPUTS_DIR <- config_value("KI67_OUTPUTS_DIR", "outputs")
KI67_MIN_CELL_COUNT <- config_value("KI67_MIN_CELL_COUNT", 5L)

project_root <- normalizePath(KI67_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(ki67_sourceable_resolve(KI67_OUTPUTS_DIR, project_root), winslash = "/", mustWork = FALSE)
candidate_tables <- trimws(as.character(KI67_CANDIDATE_TABLES))
candidate_tables <- candidate_tables[nzchar(candidate_tables)]
if (length(candidate_tables) == 1L && grepl(",", candidate_tables, fixed = TRUE)) {
  candidate_tables <- trimws(strsplit(candidate_tables, ",", fixed = TRUE)[[1]])
  candidate_tables <- candidate_tables[nzchar(candidate_tables)]
}
min_cell_count <- suppressWarnings(as.integer(KI67_MIN_CELL_COUNT))
if (is.na(min_cell_count) || min_cell_count < 1L) min_cell_count <- 5L

ki67_sourceable_source_required(project_root, file.path("R", "utils.R"))
ki67_sourceable_source_required(project_root, file.path("R", "source_map.R"))
ki67_sourceable_source_required(project_root, file.path("R", "db_profile.R"))
ki67_sourceable_source_required(project_root, file.path("R", "ki67_discovery.R"))
ki67_sourceable_source_required(project_root, file.path("R", "mcl_triangle_feasibility.R"))
ki67_sourceable_source_required(project_root, file.path("R", "ki67_production_finder.R"))

if (!KI67_MODE %in% c("plan", "production_aggregate")) {
  stop("Unsupported KI67_MODE: ", KI67_MODE, ". Use 'plan' or 'production_aggregate'.", call. = FALSE)
}

cat("DALY-CARE Ki-67 direct finder\n")
cat("Mode: ", KI67_MODE, "\n", sep = "")
cat("Project root: ", project_root, "\n", sep = "")
cat("Outputs: ", output_dir, "\n", sep = "")
cat("Candidate tables: ", paste(candidate_tables, collapse = ", "), "\n", sep = "")
if (identical(KI67_MODE, "plan")) {
  cat("Plan mode: writing aggregate-only query templates; no database connection is opened.\n")
}
if (identical(KI67_MODE, "production_aggregate") && !isTRUE(KI67_FULL_SCAN)) {
  cat("Production aggregate mode: broad text scans are disabled unless KI67_FULL_SCAN <- TRUE.\n")
}

ki67_finder_outputs <- build_ki67_db_outputs(
  project_root = project_root,
  outputs_dir = output_dir,
  mode = KI67_MODE,
  candidate_tables = candidate_tables,
  full_scan = isTRUE(KI67_FULL_SCAN),
  min_cell_count = min_cell_count,
  update_mcl = isTRUE(KI67_UPDATE_MCL)
)

ki67_finder_paths <- ki67_db_write_outputs(ki67_finder_outputs, output_dir)
if (length(ki67_finder_outputs$updated_mcl_paths %||% character())) {
  ki67_finder_paths <- c(ki67_finder_paths, updated_mcl_paths = ki67_finder_outputs$updated_mcl_paths)
}

assign("KI67_FINDER_RESULT", list(outputs = ki67_finder_outputs, paths = ki67_finder_paths), envir = .GlobalEnv)
cat("Ki-67 finder outputs written:\n")
for (path in unlist(ki67_finder_paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}
if (identical(KI67_MODE, "production_aggregate") &&
    any(ki67_finder_outputs$aeki_code_counts$validation_status == "no_db_connection", na.rm = TRUE)) {
  cat("No production DB connection was available; aggregate query plans were written and no patient-level rows were emitted.\n")
}

invisible(KI67_FINDER_RESULT)
