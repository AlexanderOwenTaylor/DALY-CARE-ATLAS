args <- commandArgs(trailingOnly = TRUE)

usage <- paste(
  "Usage:",
  "  Rscript scripts/build_ki67_discovery.R --mode cached_outputs --project-root . --outputs-dir outputs",
  "  Rscript scripts/build_ki67_discovery.R --mode standalone_zip --project-root <unpacked-atlas-dir> --outputs-dir <outputs-dir>",
  "  Rscript scripts/build_ki67_discovery.R --mode targeted_production_validation --project-root . --outputs-dir outputs --validate-only true",
  "",
  "Backward-compatible form:",
  "  Rscript scripts/build_ki67_discovery.R <project_root> <outputs_dir>",
  "",
  "Builds aggregate-only Ki-67 discovery outputs from existing atlas CSV outputs.",
  "cached_outputs and standalone_zip do not connect to the database or run the atlas profiler.",
  "targeted_production_validation is currently a plan-only mode: it validates/emits aggregate-only AEKI/text validation plans and does not query production databases.",
  sep = "\n"
)

parse_cli <- function(args) {
  out <- list(
    mode = "cached_outputs",
    project_root = ".",
    outputs_dir = "outputs",
    write_site_payload = FALSE,
    validate_only = FALSE
  )
  if (length(args) == 2L && !startsWith(args[[1]], "--")) {
    out$project_root <- args[[1]]
    out$outputs_dir <- args[[2]]
    return(out)
  }
  if (!length(args) || any(args %in% c("-h", "--help"))) {
    cat(usage, "\n")
    quit(status = if (any(args %in% c("-h", "--help"))) 0L else 1L)
  }
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) stop("Unexpected argument: ", key)
    if (i == length(args)) stop("Missing value for argument: ", key)
    value <- args[[i + 1L]]
    key <- sub("^--", "", key)
    key <- gsub("-", "_", key, fixed = TRUE)
    if (!key %in% names(out)) stop("Unknown argument: --", key)
    out[[key]] <- value
    i <- i + 2L
  }
  out$write_site_payload <- tolower(as.character(out$write_site_payload)) %in% c("true", "1", "yes", "y")
  out$validate_only <- tolower(as.character(out$validate_only)) %in% c("true", "1", "yes", "y")
  out
}

opts <- parse_cli(args)
if (!opts$mode %in% c("cached_outputs", "standalone_zip", "targeted_production_validation")) {
  stop("Unsupported --mode: ", opts$mode)
}

if (identical(opts$mode, "targeted_production_validation")) {
  cat("Ki-67 targeted production validation is plan-only in this package: no DB connection is opened, no source profiling is run, and only aggregate validation-plan outputs are validated or written.\n")
}

is_absolute_path <- function(path) {
  grepl("^([A-Za-z]:[\\\\/]|[\\\\/])", path)
}

resolve_outputs_dir <- function(outputs_dir, project_root) {
  outputs_dir <- as.character(outputs_dir)
  if (!length(outputs_dir) || is.na(outputs_dir[[1]]) || !nzchar(outputs_dir[[1]])) {
    stop("--outputs-dir cannot be empty.", call. = FALSE)
  }
  outputs_dir <- path.expand(outputs_dir[[1]])
  if (is_absolute_path(outputs_dir[[1]])) {
    outputs_dir[[1]]
  } else {
    file.path(project_root, outputs_dir[[1]])
  }
}

project_root <- normalizePath(opts$project_root, winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(resolve_outputs_dir(opts$outputs_dir, project_root), winslash = "/", mustWork = TRUE)

source_required <- function(path) {
  if (!file.exists(path)) stop("Required helper file is missing: ", path)
  source(path)
}

source_required(file.path(project_root, "R", "utils.R"))
source_required(file.path(project_root, "R", "ki67_discovery.R"))
if (isTRUE(opts$write_site_payload) && file.exists(file.path(project_root, "R", "mcl_triangle_feasibility.R"))) {
  source_required(file.path(project_root, "R", "mcl_triangle_feasibility.R"))
}

read_output <- function(name) {
  path <- file.path(output_dir, name)
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
}

outputs <- build_ki67_discovery_outputs(
  project_root = project_root,
  include_reference_files = TRUE,
  semantic_dictionary = read_output("atlas_semantic_data_dictionary.csv"),
  semantic_value_map = read_output("atlas_semantic_value_map.csv"),
  semantic_code_map = read_output("atlas_semantic_code_map.csv"),
  semantic_panel_links = read_output("atlas_semantic_panel_links.csv"),
  clinical_concepts = read_output("atlas_clinical_concepts.csv"),
  domain_panels = read_output("atlas_domain_panels.csv"),
  panel_kpis = read_output("atlas_panel_kpis.csv"),
  panel_distributions = read_output("atlas_panel_distributions.csv"),
  panel_raw_fields = read_output("atlas_panel_raw_fields.csv"),
  sources = read_output("atlas_sources.csv"),
  columns = read_output("atlas_columns.csv"),
  column_profiles = read_output("atlas_column_profiles.csv"),
  column_top_values = read_output("atlas_column_top_values.csv"),
  source_resolution = read_output("atlas_source_resolution.csv"),
  canonical_reconciliation = read_output("canonical_resource_reconciliation_64.csv"),
  legacy_reference_vs_current = read_output("legacy_reference_vs_current_profiled_evidence.csv"),
  mcl_summary = read_output("mcl_triangle_feasibility_summary.csv"),
  mcl_biology = read_output("mcl_triangle_biology_gap_analysis.csv"),
  mcl_readiness = read_output("mcl_triangle_study_readiness_matrix.csv")
)

if (isTRUE(opts$validate_only)) {
  stopifnot(is.data.frame(outputs$search_inventory))
  stopifnot(is.data.frame(outputs$channel_summary), nrow(outputs$channel_summary) == 4L)
  cat("Ki-67 discovery validation passed without running source profiling or DB access.\n")
  quit(status = 0L)
}

paths <- ki67_write_outputs(outputs, output_dir = output_dir, project_root = project_root)

if (isTRUE(opts$write_site_payload) && exists("build_mcl_triangle_feasibility_outputs", mode = "function")) {
  mcl_outputs <- build_mcl_triangle_feasibility_outputs(
    project_root = project_root,
    semantic_dictionary = read_output("atlas_semantic_data_dictionary.csv"),
    semantic_value_map = read_output("atlas_semantic_value_map.csv"),
    semantic_code_map = read_output("atlas_semantic_code_map.csv"),
    semantic_panel_links = read_output("atlas_semantic_panel_links.csv"),
    clinical_concepts = read_output("atlas_clinical_concepts.csv"),
    domain_panels = read_output("atlas_domain_panels.csv"),
    panel_kpis = read_output("atlas_panel_kpis.csv"),
    panel_distributions = read_output("atlas_panel_distributions.csv"),
    panel_raw_fields = read_output("atlas_panel_raw_fields.csv"),
    sources = read_output("atlas_sources.csv"),
    columns = read_output("atlas_columns.csv"),
    column_profiles = read_output("atlas_column_profiles.csv"),
    column_top_values = read_output("atlas_column_top_values.csv"),
    legacy_reference_vs_current = read_output("legacy_reference_vs_current_profiled_evidence.csv"),
    ki67_discovery = outputs
  )
  paths <- c(paths, mcl_triangle_write_outputs(mcl_outputs, output_dir))
}

cat("Ki-67 discovery outputs written in ", opts$mode, " mode:\n", sep = "")
for (path in unlist(paths, use.names = FALSE)) cat(" - ", path, "\n", sep = "")
