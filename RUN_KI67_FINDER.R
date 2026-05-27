# DALY-CARE Atlas one-click Ki-67 direct finder for RStudio.
#
# Usage:
#   source("RUN_KI67_FINDER.R")
#
# Optional overrides before sourcing:
#   KI67_MODE <- "plan"
#   KI67_FULL_SCAN <- TRUE
#   KI67_CANDIDATE_TABLES <- c("pato", "t_mikro", "t_konk", "RKKP_LYFO")

.ki67_entry_path <- local({
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    if (exists("ofile", envir = frames[[i]], inherits = FALSE)) {
      path <- normalizePath(get("ofile", envir = frames[[i]]), winslash = "/", mustWork = FALSE)
      if (identical(basename(path), "RUN_KI67_FINDER.R")) return(path)
    }
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    path <- normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE)
    if (identical(basename(path), "RUN_KI67_FINDER.R")) return(path)
  }
  candidate <- file.path(getwd(), "RUN_KI67_FINDER.R")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
  NA_character_
})

.ki67_default_project_root <- if (!is.na(.ki67_entry_path) && nzchar(.ki67_entry_path)) {
  dirname(.ki67_entry_path)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

.ki67_find_project_root <- function(default_root) {
  candidates <- unique(c(default_root, normalizePath(getwd(), winslash = "/", mustWork = FALSE)))
  nested_sourceables <- list.files(
    getwd(),
    pattern = "^source_ki67_finder[.]R$",
    recursive = TRUE,
    full.names = TRUE
  )
  nested_sourceables <- normalizePath(nested_sourceables, winslash = "/", mustWork = FALSE)
  nested_sourceables <- nested_sourceables[grepl("/scripts/source_ki67_finder[.]R$", nested_sourceables)]
  if (length(nested_sourceables)) {
    candidates <- unique(c(candidates, dirname(dirname(nested_sourceables))))
  }
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "scripts", "source_ki67_finder.R"))) {
      return(candidate)
    }
  }
  default_root
}

if (!exists("KI67_MODE", inherits = FALSE)) {
  KI67_MODE <- "production_aggregate"
}
if (!exists("KI67_CANDIDATE_TABLES", inherits = FALSE)) {
  KI67_CANDIDATE_TABLES <- c("pato", "t_mikro", "t_konk", "RKKP_LYFO")
}
if (!exists("KI67_FULL_SCAN", inherits = FALSE)) {
  KI67_FULL_SCAN <- FALSE
}
if (!exists("KI67_UPDATE_MCL", inherits = FALSE)) {
  KI67_UPDATE_MCL <- TRUE
}
if (!exists("KI67_PROJECT_ROOT", inherits = FALSE)) {
  KI67_PROJECT_ROOT <- .ki67_find_project_root(.ki67_default_project_root)
}
if (!exists("KI67_OUTPUTS_DIR", inherits = FALSE)) {
  KI67_OUTPUTS_DIR <- "outputs"
}
if (!exists("KI67_MIN_CELL_COUNT", inherits = FALSE)) {
  KI67_MIN_CELL_COUNT <- 5L
}

.ki67_project_root <- normalizePath(KI67_PROJECT_ROOT, winslash = "/", mustWork = TRUE)
.ki67_sourceable <- file.path(.ki67_project_root, "scripts", "source_ki67_finder.R")
if (!file.exists(.ki67_sourceable)) {
  stop(
    "Missing Ki-67 sourceable finder script: ", .ki67_sourceable, "\n",
    "Set KI67_PROJECT_ROOT to the unpacked atlas package/repository directory, or source RUN_KI67_FINDER.R from inside that directory.",
    call. = FALSE
  )
}

.KI67_SOURCE_CONFIG <- list(
  KI67_MODE = KI67_MODE,
  KI67_CANDIDATE_TABLES = KI67_CANDIDATE_TABLES,
  KI67_FULL_SCAN = KI67_FULL_SCAN,
  KI67_UPDATE_MCL = KI67_UPDATE_MCL,
  KI67_PROJECT_ROOT = KI67_PROJECT_ROOT,
  KI67_OUTPUTS_DIR = KI67_OUTPUTS_DIR,
  KI67_MIN_CELL_COUNT = KI67_MIN_CELL_COUNT
)
assign(".KI67_SOURCE_CONFIG", .KI67_SOURCE_CONFIG, envir = .GlobalEnv)
source(.ki67_sourceable)
