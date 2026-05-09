args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript scripts/run_atlas.R <project_root> <source_map_path> [output_root] [mode]", call. = FALSE)
}

project_root <- normalizePath(args[[1]], winslash = "/", mustWork = FALSE)
source(file.path(project_root, "R", "utils.R"))
source(file.path(project_root, "R", "source_map.R"))
source(file.path(project_root, "R", "loader.R"))
source(file.path(project_root, "R", "npu_dictionary.R"))
source(file.path(project_root, "R", "profiler.R"))
source(file.path(project_root, "R", "db_profile.R"))
source(file.path(project_root, "R", "html.R"))
source(file.path(project_root, "R", "run_atlas.R"))

source_map_path <- args[[2]]
output_root <- args[[3]] %||% "atlas_runs"
mode <- args[[4]] %||% "report"

result <- run_atlas(
  project_root = project_root,
  source_map_path = source_map_path,
  output_root = output_root,
  mode = mode
)

cat("DALY-CARE atlas run complete\n")
cat("Run directory:", result$run_dir, "\n")
cat("HTML:", result$html, "\n")
