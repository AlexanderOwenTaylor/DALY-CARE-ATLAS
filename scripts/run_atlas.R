usage <- paste(
  "Usage:",
  "  Rscript scripts/run_atlas.R <project_root> <source_map_path> [output_root] [mode]",
  "  Rscript scripts/run_atlas.R <source_map_path> [output_root] [mode]",
  "",
  "Examples:",
  "  Rscript scripts/run_atlas.R . config/source-map.example.tsv atlas_runs report",
  "  Rscript scripts/run_atlas.R config/source-map.dalycare.tsv atlas_runs report",
  sep = "\n"
)

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = FALSE)
  repeat {
    if (
      file.exists(file.path(current, "R", "run_atlas.R")) &&
        file.exists(file.path(current, "scripts", "run_atlas.R"))
    ) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }
  normalizePath(start, winslash = "/", mustWork = FALSE)
}

is_project_root_arg <- function(path) {
  if (!dir.exists(path)) return(FALSE)
  file.exists(file.path(path, "R", "run_atlas.R")) &&
    file.exists(file.path(path, "scripts", "run_atlas.R"))
}

run_atlas_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (any(args %in% c("-h", "--help"))) {
    cat(usage, "\n")
    return(invisible(NULL))
  }

  if (length(args) == 0 || length(args) > 4) {
    stop(usage, call. = FALSE)
  }

  if (length(args) >= 2 && is_project_root_arg(args[[1]])) {
    project_root_arg <- args[[1]]
    source_map_path <- args[[2]]
    output_root <- if (length(args) >= 3) args[[3]] else "atlas_runs"
    mode <- if (length(args) >= 4) args[[4]] else "report"
  } else {
    project_root_arg <- find_project_root()
    source_map_path <- args[[1]]
    output_root <- if (length(args) >= 2) args[[2]] else "atlas_runs"
    mode <- if (length(args) >= 3) args[[3]] else "report"
  }

  project_root <- normalizePath(project_root_arg, winslash = "/", mustWork = FALSE)
  source(file.path(project_root, "R", "utils.R"))
  source(file.path(project_root, "R", "source_map.R"))
  source(file.path(project_root, "R", "loader.R"))
  source(file.path(project_root, "R", "npu_dictionary.R"))
  source(file.path(project_root, "R", "profiler.R"))
  source(file.path(project_root, "R", "db_profile.R"))
  source(file.path(project_root, "R", "html.R"))
  source(file.path(project_root, "R", "run_atlas.R"))

  result <- run_atlas(
    project_root = project_root,
    source_map_path = source_map_path,
    output_root = output_root,
    mode = mode
  )

  cat("DALY-CARE atlas run complete\n")
  cat("Run directory:", result$run_dir, "\n")
  cat("HTML:", result$html, "\n")
  invisible(result)
}

if (!identical(Sys.getenv("DALYCARE_ATLAS_SOURCE_ONLY"), "TRUE")) {
  invisible(run_atlas_cli())
}
