.dalycare_entry_path <- local({
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
  candidate <- file.path(getwd(), "RUN_DALYCARE_ATLAS_48_SOURCE.R")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
  NA_character_
})

.dalycare_project_root <- if (!is.na(.dalycare_entry_path)) {
  dirname(.dalycare_entry_path)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}
if (!identical(basename(if (is.na(.dalycare_entry_path)) "" else .dalycare_entry_path), "RUN_DALYCARE_ATLAS_48_SOURCE.R") &&
    file.exists(file.path(getwd(), "RUN_DALYCARE_ATLAS_48_SOURCE.R"))) {
  .dalycare_entry_path <- normalizePath(file.path(getwd(), "RUN_DALYCARE_ATLAS_48_SOURCE.R"), winslash = "/", mustWork = FALSE)
  .dalycare_project_root <- dirname(.dalycare_entry_path)
}

.dalycare_restore_source_only <- Sys.getenv("DALYCARE_ATLAS_SOURCE_ONLY", unset = NA)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = "TRUE")
source(file.path(.dalycare_project_root, "scripts", "run_atlas.R"), local = .GlobalEnv)
if (is.na(.dalycare_restore_source_only)) {
  Sys.unsetenv("DALYCARE_ATLAS_SOURCE_ONLY")
} else {
  Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = .dalycare_restore_source_only)
}

.dalycare_latest_run_dir <- function(output_root) {
  if (!dir.exists(output_root)) return(NA_character_)
  dirs <- list.dirs(output_root, recursive = FALSE, full.names = TRUE)
  if (!length(dirs)) return(NA_character_)
  info <- file.info(dirs)
  normalizePath(dirs[which.max(info$mtime)], winslash = "/", mustWork = FALSE)
}

.dalycare_run_dir_from_error <- function(error_message, output_root) {
  hit <- regmatches(error_message, regexpr("Diagnostics written to:[^\r\n]+", error_message))
  if (length(hit) && nzchar(hit[[1]])) {
    return(trimws(sub("^Diagnostics written to:", "", hit[[1]])))
  }
  .dalycare_latest_run_dir(output_root)
}

.dalycare_print_diagnostic_path <- function(label, path) {
  suffix <- if (file.exists(path)) "" else " (not found)"
  cat("  - ", label, ": ", normalizePath(path, winslash = "/", mustWork = FALSE), suffix, "\n", sep = "")
}

setwd(.dalycare_project_root)
cat("\nDALY-CARE Atlas one-click RStudio runner (48-source compatibility map)\n")
cat("Project root: ", .dalycare_project_root, "\n", sep = "")

.dalycare_source_map <- Sys.getenv("DALYCARE_ATLAS_SOURCE_MAP", unset = "config/source-map.dalycare.tsv")
.dalycare_output_root <- Sys.getenv("DALYCARE_ATLAS_OUTPUT_ROOT", unset = "atlas_runs")
.dalycare_mode <- Sys.getenv("DALYCARE_ATLAS_MODE", unset = "report")
.dalycare_output_root_abs <- if (grepl("^[A-Za-z]:|^/", .dalycare_output_root)) {
  normalizePath(.dalycare_output_root, winslash = "/", mustWork = FALSE)
} else {
  normalizePath(file.path(.dalycare_project_root, .dalycare_output_root), winslash = "/", mustWork = FALSE)
}

assign("dalycare_atlas_failed", FALSE, envir = .GlobalEnv)
assign("dalycare_atlas_last_error", NULL, envir = .GlobalEnv)

.dalycare_result <- tryCatch(
  {
    project_root <- load_atlas_runtime(.dalycare_project_root)
    run_atlas(
      project_root = project_root,
      source_map_path = .dalycare_source_map,
      output_root = .dalycare_output_root,
      mode = .dalycare_mode
    )
  },
  error = function(e) e
)

if (inherits(.dalycare_result, "error")) {
  assign("dalycare_atlas_failed", TRUE, envir = .GlobalEnv)
  assign("dalycare_atlas_last_error", .dalycare_result, envir = .GlobalEnv)
  .dalycare_error_message <- conditionMessage(.dalycare_result)
  .dalycare_run_dir <- .dalycare_run_dir_from_error(.dalycare_error_message, .dalycare_output_root_abs)
  cat("\nDALY-CARE atlas failed, but RStudio is still open.\n")
  cat("Error: ", .dalycare_error_message, "\n", sep = "")
  if (!is.na(.dalycare_run_dir) && nzchar(.dalycare_run_dir)) {
    cat("\nRun directory: ", .dalycare_run_dir, "\n", sep = "")
    cat("Diagnostic files:\n")
    .dalycare_print_diagnostic_path("DALY access", file.path(.dalycare_run_dir, "outputs", "atlas_dalycare_access.csv"))
    .dalycare_print_diagnostic_path("Source resolution", file.path(.dalycare_run_dir, "outputs", "atlas_source_resolution.csv"))
    .dalycare_print_diagnostic_path("Memory plan", file.path(.dalycare_run_dir, "outputs", "atlas_memory_plan.csv"))
    .dalycare_print_diagnostic_path("Execution log", file.path(.dalycare_run_dir, "logs", "atlas_execution_log.tsv"))
  } else {
    cat("\nNo run directory was created before the failure.\n")
  }
  cat("\nFailure object saved as: dalycare_atlas_last_error\n")
} else {
  assign("dalycare_atlas_result", .dalycare_result, envir = .GlobalEnv)
  assign("dalycare_atlas_failed", FALSE, envir = .GlobalEnv)
  assign("dalycare_atlas_last_error", NULL, envir = .GlobalEnv)
  cat("\nDALY-CARE atlas run complete.\n")
  cat("Run directory: ", .dalycare_result$run_dir, "\n", sep = "")
  cat("HTML: ", .dalycare_result$html, "\n", sep = "")
  cat("Result object saved as: dalycare_atlas_result\n")
}

invisible(.dalycare_result)
