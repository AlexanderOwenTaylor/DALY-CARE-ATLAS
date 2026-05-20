args <- commandArgs(trailingOnly = TRUE)

usage <- paste(
  "Usage:",
  "  Rscript scripts/build_ki67_discovery.R <project_root> <outputs_dir>",
  "",
  "Builds aggregate-only Ki-67 discovery outputs from existing atlas CSV outputs.",
  sep = "\n"
)

if (length(args) != 2L || any(args %in% c("-h", "--help"))) {
  cat(usage, "\n")
  quit(status = if (length(args) == 1L && args[[1]] %in% c("-h", "--help")) 0L else 1L)
}

project_root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = "TRUE")
source(file.path(project_root, "scripts", "run_atlas.R"))
load_atlas_runtime(project_root)

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
  legacy_reference_vs_current = read_output("legacy_reference_vs_current_profiled_evidence.csv")
)

paths <- ki67_write_outputs(outputs, output_dir = output_dir, project_root = project_root)
cat("Ki-67 discovery outputs written:\n")
for (path in unlist(paths, use.names = FALSE)) cat(" - ", path, "\n", sep = "")
