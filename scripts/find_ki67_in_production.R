args <- commandArgs(trailingOnly = TRUE)

usage <- paste(
  "Usage:",
  "  Rscript scripts/find_ki67_in_production.R --mode plan --project-root . --outputs-dir outputs",
  "  Rscript scripts/find_ki67_in_production.R --mode production_aggregate --project-root . --outputs-dir outputs",
  "  Rscript scripts/find_ki67_in_production.R --mode production_aggregate --candidate-tables pato,t_mikro,t_konk,RKKP_LYFO --project-root . --outputs-dir outputs",
  "",
  "Finds Ki-67 production locations using aggregate-only metadata/code/text scans.",
  "Plan mode writes aggregate SQL templates and does not connect to the database.",
  "Production mode uses existing read-only DALY-CARE DB conventions and emits aggregate counts only.",
  sep = "\n"
)

parse_cli <- function(args) {
  out <- list(
    mode = "plan",
    project_root = ".",
    outputs_dir = "outputs",
    candidate_tables = "pato,t_mikro,t_konk,RKKP_LYFO",
    full_scan = FALSE,
    min_cell_count = 5L,
    update_mcl = TRUE
  )
  if (!length(args) || any(args %in% c("-h", "--help"))) {
    cat(usage, "\n")
    quit(status = if (any(args %in% c("-h", "--help"))) 0L else 1L)
  }
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) stop("Unexpected argument: ", key, call. = FALSE)
    if (i == length(args)) stop("Missing value for argument: ", key, call. = FALSE)
    value <- args[[i + 1L]]
    key <- gsub("-", "_", sub("^--", "", key), fixed = TRUE)
    if (!key %in% names(out)) stop("Unknown argument: --", key, call. = FALSE)
    out[[key]] <- value
    i <- i + 2L
  }
  out$full_scan <- tolower(as.character(out$full_scan)) %in% c("true", "1", "yes", "y")
  out$update_mcl <- tolower(as.character(out$update_mcl)) %in% c("true", "1", "yes", "y")
  out$min_cell_count <- suppressWarnings(as.integer(out$min_cell_count))
  if (is.na(out$min_cell_count) || out$min_cell_count < 1L) out$min_cell_count <- 5L
  out$candidate_tables <- trimws(strsplit(as.character(out$candidate_tables), ",", fixed = TRUE)[[1]])
  out$candidate_tables <- out$candidate_tables[nzchar(out$candidate_tables)]
  out
}

is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

resolve_under_project <- function(path, project_root) {
  path <- as.character(path)
  path <- path.expand(if (length(path) && !is.na(path[[1]])) path[[1]] else "")
  if (!nzchar(path)) stop("Path cannot be empty.", call. = FALSE)
  if (is_absolute_path(path)) path else file.path(project_root, path)
}

source_required <- function(path) {
  if (!file.exists(path)) stop("Required helper file is missing: ", path, call. = FALSE)
  source(path)
}

opts <- parse_cli(args)
if (!opts$mode %in% c("plan", "production_aggregate")) {
  stop("Unsupported --mode: ", opts$mode, call. = FALSE)
}

project_root <- normalizePath(opts$project_root, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(resolve_under_project(opts$outputs_dir, project_root), winslash = "/", mustWork = FALSE)

source_required(file.path(project_root, "R", "utils.R"))
source_required(file.path(project_root, "R", "source_map.R"))
source_required(file.path(project_root, "R", "db_profile.R"))
source_required(file.path(project_root, "R", "ki67_discovery.R"))
source_required(file.path(project_root, "R", "mcl_triangle_feasibility.R"))
source_required(file.path(project_root, "R", "ki67_production_finder.R"))

if (identical(opts$mode, "plan")) {
  cat("Ki-67 direct production finder plan mode: writing aggregate-only query templates; no DB connection will be opened.\n")
}
if (identical(opts$mode, "production_aggregate") && !isTRUE(opts$full_scan)) {
  cat("Ki-67 production aggregate mode: broad pathology text scans are disabled. Use --full-scan true only after reviewing ki67_db_query_templates.sql.\n")
}

outputs <- build_ki67_db_outputs(
  project_root = project_root,
  outputs_dir = output_dir,
  mode = opts$mode,
  candidate_tables = opts$candidate_tables,
  full_scan = opts$full_scan,
  min_cell_count = opts$min_cell_count,
  update_mcl = opts$update_mcl
)

paths <- ki67_db_write_outputs(outputs, output_dir)
if (length(outputs$updated_mcl_paths %||% character())) {
  paths <- c(paths, updated_mcl_paths = outputs$updated_mcl_paths)
}

cat("Ki-67 direct finder outputs written in ", opts$mode, " mode:\n", sep = "")
for (path in unlist(paths, use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}

if (identical(opts$mode, "production_aggregate") && any(outputs$aeki_code_counts$validation_status == "no_db_connection", na.rm = TRUE)) {
  cat("No production DB connection was available; query plans were written but aggregate scans were not executed.\n")
}
