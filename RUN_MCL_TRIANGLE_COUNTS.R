# DALY-CARE Atlas one-click MCL/TRIANGLE aggregate cohort-size finder for RStudio.
#
# Usage:
#   source("RUN_MCL_TRIANGLE_COUNTS.R")
#
# Optional overrides before sourcing:
#   MCL_COUNT_MODE <- "production_aggregate"
#   MCL_COUNT_UPDATE_PAYLOAD <- TRUE
#   MCL_COUNT_SMALL_CELL_N <- 10L
#   MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- "path/to/main_atlas_outputs"
#   MCL_TRIANGLE_ATLAS_OUTPUT_ZIP <- "path/to/main_atlas_outputs.zip"
#   MCL_TRIANGLE_KI67_TEXT_SCAN <- FALSE
#   MCL_TRIANGLE_KI67_THRESHOLD_PERCENT <- 30L

.mcl_count_entry_path <- local({
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    if (exists("ofile", envir = frames[[i]], inherits = FALSE)) {
      path <- normalizePath(get("ofile", envir = frames[[i]]), winslash = "/", mustWork = FALSE)
      if (identical(basename(path), "RUN_MCL_TRIANGLE_COUNTS.R")) return(path)
    }
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    path <- normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE)
    if (identical(basename(path), "RUN_MCL_TRIANGLE_COUNTS.R")) return(path)
  }
  candidate <- file.path(getwd(), "RUN_MCL_TRIANGLE_COUNTS.R")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
  NA_character_
})

.mcl_count_default_project_root <- if (!is.na(.mcl_count_entry_path) && nzchar(.mcl_count_entry_path)) {
  dirname(.mcl_count_entry_path)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

.mcl_count_find_project_root <- function(default_root) {
  candidates <- unique(c(default_root, normalizePath(getwd(), winslash = "/", mustWork = FALSE)))
  nested_sourceables <- list.files(
    getwd(),
    pattern = "^source_mcl_triangle_counts[.]R$",
    recursive = TRUE,
    full.names = TRUE
  )
  nested_sourceables <- normalizePath(nested_sourceables, winslash = "/", mustWork = FALSE)
  nested_sourceables <- nested_sourceables[grepl("/scripts/source_mcl_triangle_counts[.]R$", nested_sourceables)]
  if (length(nested_sourceables)) {
    candidates <- unique(c(candidates, dirname(dirname(nested_sourceables))))
  }
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "scripts", "source_mcl_triangle_counts.R"))) {
      return(candidate)
    }
  }
  default_root
}

if (!exists("MCL_COUNT_MODE", inherits = FALSE)) {
  MCL_COUNT_MODE <- "plan"
}
if (!exists("MCL_COUNT_PROJECT_ROOT", inherits = FALSE)) {
  MCL_COUNT_PROJECT_ROOT <- .mcl_count_find_project_root(.mcl_count_default_project_root)
}
if (!exists("MCL_COUNT_OUTPUTS_DIR", inherits = FALSE)) {
  MCL_COUNT_OUTPUTS_DIR <- "outputs"
}
if (!exists("MCL_COUNT_SMALL_CELL_N", inherits = FALSE)) {
  MCL_COUNT_SMALL_CELL_N <- 5L
}
if (!exists("MCL_COUNT_UPDATE_PAYLOAD", inherits = FALSE)) {
  MCL_COUNT_UPDATE_PAYLOAD <- FALSE
}
if (!exists("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", inherits = FALSE)) {
  MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_DIR", unset = "")
}
if (!exists("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", inherits = FALSE)) {
  MCL_TRIANGLE_ATLAS_OUTPUT_ZIP <- Sys.getenv("MCL_TRIANGLE_ATLAS_OUTPUT_ZIP", unset = "")
}
if (!exists("MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY", inherits = FALSE)) {
  MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY <- TRUE
}
if (!exists("MCL_TRIANGLE_KI67_TEXT_SCAN", inherits = FALSE)) {
  MCL_TRIANGLE_KI67_TEXT_SCAN <- Sys.getenv("MCL_TRIANGLE_KI67_TEXT_SCAN", unset = "false")
}
if (!exists("MCL_TRIANGLE_KI67_THRESHOLD_PERCENT", inherits = FALSE)) {
  MCL_TRIANGLE_KI67_THRESHOLD_PERCENT <- NA_integer_
}

.mcl_count_project_root <- normalizePath(MCL_COUNT_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
.mcl_count_sourceable <- file.path(.mcl_count_project_root, "scripts", "source_mcl_triangle_counts.R")
if (!file.exists(.mcl_count_sourceable)) {
  stop(
    "Missing MCL/TRIANGLE sourceable count script: ", .mcl_count_sourceable, "\n",
    "Set MCL_COUNT_PROJECT_ROOT to the unpacked atlas package/repository directory, or source RUN_MCL_TRIANGLE_COUNTS.R from inside that directory.",
    call. = FALSE
  )
}

.MCL_COUNT_SOURCE_CONFIG <- list(
  MCL_COUNT_MODE = MCL_COUNT_MODE,
  MCL_COUNT_PROJECT_ROOT = MCL_COUNT_PROJECT_ROOT,
  MCL_COUNT_OUTPUTS_DIR = MCL_COUNT_OUTPUTS_DIR,
  MCL_COUNT_SMALL_CELL_N = MCL_COUNT_SMALL_CELL_N,
  MCL_COUNT_UPDATE_PAYLOAD = MCL_COUNT_UPDATE_PAYLOAD,
  MCL_TRIANGLE_ATLAS_OUTPUT_DIR = MCL_TRIANGLE_ATLAS_OUTPUT_DIR,
  MCL_TRIANGLE_ATLAS_OUTPUT_ZIP = MCL_TRIANGLE_ATLAS_OUTPUT_ZIP,
  MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY = MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY,
  MCL_TRIANGLE_KI67_TEXT_SCAN = MCL_TRIANGLE_KI67_TEXT_SCAN,
  MCL_TRIANGLE_KI67_THRESHOLD_PERCENT = MCL_TRIANGLE_KI67_THRESHOLD_PERCENT
)
assign(".MCL_COUNT_SOURCE_CONFIG", .MCL_COUNT_SOURCE_CONFIG, envir = .GlobalEnv)
source(.mcl_count_sourceable)
