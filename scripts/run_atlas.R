atlas_runner_script_path <- local({
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    if (exists("ofile", envir = frames[[i]], inherits = FALSE)) {
      return(normalizePath(get("ofile", envir = frames[[i]]), winslash = "/", mustWork = FALSE))
    }
  }

  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE))
  }

  NA_character_
})

usage <- paste(
  "Usage:",
  "  Rscript scripts/run_atlas.R <project_root> <source_map_path> [output_root] [mode]",
  "  Rscript scripts/run_atlas.R <source_map_path> [output_root] [mode]",
  "  Rscript scripts/run_atlas.R <project_root>",
  "",
  "Examples:",
  "  Rscript scripts/run_atlas.R . config/source-map.example.tsv atlas_runs report",
  "  Rscript scripts/run_atlas.R config/source-map.dalycare.tsv atlas_runs report",
  "  Rscript scripts/run_atlas.R .",
  sep = "\n"
)

find_project_root <- function(start = NULL) {
  if (is.null(start)) {
    start <- if (!is.na(atlas_runner_script_path)) dirname(dirname(atlas_runner_script_path)) else getwd()
  }
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

default_source_map <- function(project_root = find_project_root()) {
  dalycare_map <- file.path(project_root, "config", "source-map.dalycare.tsv")
  if (file.exists(dalycare_map)) {
    return("config/source-map.dalycare.tsv")
  }
  "config/source-map.example.tsv"
}

load_atlas_runtime <- function(project_root = find_project_root()) {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  source(file.path(project_root, "R", "utils.R"))
  source(file.path(project_root, "R", "source_map.R"))
  source(file.path(project_root, "R", "loader.R"))
  source(file.path(project_root, "R", "npu_dictionary.R"))
  source(file.path(project_root, "R", "profiler.R"))
  source(file.path(project_root, "R", "db_profile.R"))
  source(file.path(project_root, "R", "html.R"))
  source(file.path(project_root, "R", "run_atlas.R"))
  invisible(project_root)
}

run_atlas_from_source <- function(project_root = find_project_root(),
                                  source_map_path = default_source_map(project_root),
                                  output_root = "atlas_runs",
                                  mode = "report") {
  project_root <- load_atlas_runtime(project_root)
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

run_atlas_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (any(args %in% c("-h", "--help"))) {
    cat(usage, "\n")
    return(invisible(NULL))
  }

  if (length(args) == 0) {
    cat(usage, "\n")
    cat("\nNo source map was provided. In R/RStudio, run:\n")
    cat("  source(\"scripts/run_atlas.R\")\n")
    cat("  result <- run_atlas_from_source(source_map_path = \"config/source-map.dalycare.tsv\")\n")
    return(invisible(NULL))
  }

  if (length(args) > 4) {
    stop(usage, call. = FALSE)
  }

  if (length(args) == 1 && is_project_root_arg(args[[1]])) {
    project_root_arg <- args[[1]]
    source_map_path <- default_source_map(project_root_arg)
    output_root <- "atlas_runs"
    mode <- "report"
  } else if (length(args) >= 2 && is_project_root_arg(args[[1]])) {
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

  run_atlas_from_source(
    project_root = project_root_arg,
    source_map_path = source_map_path,
    output_root = output_root,
    mode = mode
  )
}

run_atlas_source_message <- function() {
  cat("DALY-CARE atlas runner loaded.\n")
  cat("Run from this R session with:\n")
  cat("  result <- run_atlas_from_source(source_map_path = \"config/source-map.dalycare.tsv\")\n")
  cat("Or from a terminal with:\n")
  cat("  Rscript scripts/run_atlas.R config/source-map.dalycare.tsv atlas_runs report\n")
  invisible(NULL)
}

if (identical(Sys.getenv("DALYCARE_ATLAS_SOURCE_ONLY"), "TRUE")) {
  invisible(NULL)
} else if (interactive()) {
  run_atlas_source_message()
} else {
  invisible(run_atlas_cli())
}
