# DALY-CARE Atlas one-click CONFLUENCE aggregate mini-bundle runner for RStudio.
#
# Usage:
#   source("RUN_CONFLUENCE_COUNTS.R")
#
# Optional overrides before sourcing:
#   CONFLUENCE_COUNT_MODE <- "production_aggregate"
#   CONFLUENCE_COUNT_OUTPUTS_DIR <- "outputs/confluence_only"
#   CONFLUENCE_COUNT_SMALL_CELL_N <- 10L
#   CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR <- "path/to/main_atlas_outputs"
#   CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP <- "path/to/main_atlas_outputs.zip"

.confluence_count_entry_path <- local({
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    if (exists("ofile", envir = frames[[i]], inherits = FALSE)) {
      path <- normalizePath(get("ofile", envir = frames[[i]]), winslash = "/", mustWork = FALSE)
      if (identical(basename(path), "RUN_CONFLUENCE_COUNTS.R")) return(path)
    }
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    path <- normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE)
    if (identical(basename(path), "RUN_CONFLUENCE_COUNTS.R")) return(path)
  }
  candidate <- file.path(getwd(), "RUN_CONFLUENCE_COUNTS.R")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
  NA_character_
})

.confluence_count_default_project_root <- if (!is.na(.confluence_count_entry_path) && nzchar(.confluence_count_entry_path)) {
  dirname(.confluence_count_entry_path)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

.confluence_count_find_project_root <- function(default_root) {
  candidates <- unique(c(default_root, normalizePath(getwd(), winslash = "/", mustWork = FALSE)))
  nested_sourceables <- list.files(
    getwd(),
    pattern = "^source_confluence_counts[.]R$",
    recursive = TRUE,
    full.names = TRUE
  )
  nested_sourceables <- normalizePath(nested_sourceables, winslash = "/", mustWork = FALSE)
  nested_sourceables <- nested_sourceables[grepl("/scripts/source_confluence_counts[.]R$", nested_sourceables)]
  if (length(nested_sourceables)) {
    candidates <- unique(c(candidates, dirname(dirname(nested_sourceables))))
  }
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "scripts", "source_confluence_counts.R"))) {
      return(candidate)
    }
  }
  default_root
}

if (!exists("CONFLUENCE_COUNT_MODE", inherits = FALSE)) {
  CONFLUENCE_COUNT_MODE <- "plan"
}
if (!exists("CONFLUENCE_COUNT_PROJECT_ROOT", inherits = FALSE)) {
  CONFLUENCE_COUNT_PROJECT_ROOT <- .confluence_count_find_project_root(.confluence_count_default_project_root)
}
if (!exists("CONFLUENCE_COUNT_OUTPUTS_DIR", inherits = FALSE)) {
  CONFLUENCE_COUNT_OUTPUTS_DIR <- "outputs/confluence_only"
}
if (!exists("CONFLUENCE_COUNT_SMALL_CELL_N", inherits = FALSE)) {
  CONFLUENCE_COUNT_SMALL_CELL_N <- 5L
}
if (!exists("CONFLUENCE_COUNT_UPDATE_PAYLOAD", inherits = FALSE)) {
  CONFLUENCE_COUNT_UPDATE_PAYLOAD <- FALSE
}
if (!exists("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", inherits = FALSE)) {
  CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR <- Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR", unset = "")
}
if (!exists("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", inherits = FALSE)) {
  CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP <- Sys.getenv("CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP", unset = "")
}

.confluence_count_project_root <- normalizePath(CONFLUENCE_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
.confluence_count_sourceable <- file.path(.confluence_count_project_root, "scripts", "source_confluence_counts.R")
if (!file.exists(.confluence_count_sourceable)) {
  stop(
    "Missing CONFLUENCE sourceable count script: ", .confluence_count_sourceable, "\n",
    "Set CONFLUENCE_COUNT_PROJECT_ROOT to the unpacked atlas package/repository directory, or source RUN_CONFLUENCE_COUNTS.R from inside that directory.",
    call. = FALSE
  )
}

.CONFLUENCE_COUNT_SOURCE_CONFIG <- list(
  CONFLUENCE_COUNT_MODE = CONFLUENCE_COUNT_MODE,
  CONFLUENCE_COUNT_PROJECT_ROOT = CONFLUENCE_COUNT_PROJECT_ROOT,
  CONFLUENCE_COUNT_OUTPUTS_DIR = CONFLUENCE_COUNT_OUTPUTS_DIR,
  CONFLUENCE_COUNT_SMALL_CELL_N = CONFLUENCE_COUNT_SMALL_CELL_N,
  CONFLUENCE_COUNT_UPDATE_PAYLOAD = CONFLUENCE_COUNT_UPDATE_PAYLOAD,
  CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR = CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR,
  CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP = CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP,
  CONFLUENCE_COUNT_DB_ADAPTER = if (exists("CONFLUENCE_COUNT_DB_ADAPTER", inherits = FALSE)) CONFLUENCE_COUNT_DB_ADAPTER else NULL
)
assign(".CONFLUENCE_COUNT_SOURCE_CONFIG", .CONFLUENCE_COUNT_SOURCE_CONFIG, envir = .GlobalEnv)
source(.confluence_count_sourceable)
