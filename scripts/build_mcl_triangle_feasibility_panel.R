usage <- paste(
  "Usage:",
  "  Rscript scripts/build_mcl_triangle_feasibility_panel.R <project_root> <outputs_dir>",
  "",
  "Examples:",
  "  Rscript scripts/build_mcl_triangle_feasibility_panel.R . atlas_runs/20260520_120000-p123/outputs",
  sep = "\n"
)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L || any(args %in% c("-h", "--help"))) {
  cat(usage, "\n")
  quit(status = if (length(args) < 2L) 1L else 0L)
}

project_root <- normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
output_dir <- normalizePath(args[[2]], winslash = "/", mustWork = FALSE)

source(file.path(project_root, "R", "utils.R"))
source(file.path(project_root, "R", "semantic_dictionary.R"))
source(file.path(project_root, "R", "product_layer.R"))
source(file.path(project_root, "R", "ki67_discovery.R"))
source(file.path(project_root, "R", "mcl_triangle_counts.R"))
source(file.path(project_root, "R", "mcl_triangle_feasibility.R"))

read_output <- function(file, fallback) {
  path <- file.path(output_dir, file)
  if (!file.exists(path)) return(fallback)
  read_delimited_file(path)
}

outputs <- build_mcl_triangle_feasibility_outputs(
  project_root = project_root,
  semantic_dictionary = read_output("atlas_semantic_data_dictionary.csv", empty_semantic_data_dictionary()),
  semantic_value_map = read_output("atlas_semantic_value_map.csv", empty_semantic_value_map()),
  semantic_code_map = read_output("atlas_semantic_code_map.csv", empty_semantic_code_map()),
  semantic_panel_links = read_output("atlas_semantic_panel_links.csv", empty_semantic_panel_links()),
  columns = read_output("atlas_columns.csv", data.frame(stringsAsFactors = FALSE)),
  column_profiles = read_output("atlas_column_profiles.csv", data.frame(stringsAsFactors = FALSE)),
  panel_raw_fields = read_output("atlas_panel_raw_fields.csv", empty_panel_raw_fields()),
  panel_distributions = read_output("atlas_panel_distributions.csv", empty_panel_distributions()),
  panel_kpis = read_output("atlas_panel_kpis.csv", empty_panel_kpis()),
  sources = read_output("atlas_sources.csv", data.frame(stringsAsFactors = FALSE)),
  canonical_reconciliation = read_output("canonical_resource_reconciliation_64.csv", data.frame(stringsAsFactors = FALSE)),
  legacy_reference_vs_current = read_output("legacy_reference_vs_current_profiled_evidence.csv", data.frame(stringsAsFactors = FALSE))
)

paths <- mcl_triangle_write_outputs(outputs, output_dir)
count_outputs <- mcl_count_build_outputs(
  project_root = project_root,
  outputs_dir = output_dir,
  mode = "plan",
  min_cell_count = atlas_min_cell_count()
)
count_paths <- mcl_count_write_outputs(count_outputs, output_dir)
cat("MCL/TRIANGLE feasibility outputs written:\n")
for (path in unlist(c(paths, count_paths), use.names = FALSE)) {
  cat(" - ", path, "\n", sep = "")
}
