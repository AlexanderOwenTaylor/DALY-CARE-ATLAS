args <- commandArgs(trailingOnly = TRUE)

usage <- paste(
  "Usage:",
  "  Rscript scripts/build_atlas_mockup_from_run_zip.R <input_run_zip> [output_zip]",
  "",
  "Builds a V33 coverage mock-up atlas from an existing aggregate-only atlas ZIP.",
  sep = "\n"
)

if (length(args) < 1L || length(args) > 2L || any(args %in% c("-h", "--help"))) {
  cat(usage, "\n")
  quit(status = if (length(args) == 1L && args[[1]] %in% c("-h", "--help")) 0L else 1L)
}

input_zip <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
output_zip <- if (length(args) >= 2L) {
  normalizePath(args[[2]], winslash = "/", mustWork = FALSE)
} else {
  file.path(dirname(input_zip), paste0("DALYCARE_atlas_V33_coverage_mockup_", format(Sys.Date(), "%Y%m%d"), ".zip"))
}

script_path <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1]]), winslash = "/", mustWork = FALSE)
project_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = "TRUE")
source(file.path(project_root, "scripts", "run_atlas.R"))
load_atlas_runtime(project_root)

read_csv_or_empty <- function(path) {
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  if (is.na(file.info(path)$size) || file.info(path)$size == 0) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) data.frame(stringsAsFactors = FALSE)
  )
}

read_tsv_or_empty <- function(path) {
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  if (is.na(file.info(path)$size) || file.info(path)$size == 0) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(
    utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) data.frame(stringsAsFactors = FALSE)
  )
}

write_text <- function(lines, path) {
  dir_create(dirname(path))
  writeLines(lines, path, useBytes = TRUE)
  path
}

copy_dir_contents <- function(from, to) {
  from <- normalizePath(from, winslash = "/", mustWork = TRUE)
  if (dir.exists(to)) unlink(to, recursive = TRUE, force = TRUE)
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  items <- list.files(from, all.files = TRUE, no.. = TRUE, recursive = TRUE, full.names = TRUE)
  dirs <- items[dir.exists(items)]
  files <- items[file.exists(items) & !dir.exists(items)]
  rel_dirs <- substring(normalizePath(dirs, winslash = "/", mustWork = FALSE), nchar(from) + 2L)
  rel_files <- substring(normalizePath(files, winslash = "/", mustWork = FALSE), nchar(from) + 2L)
  for (rel in rel_dirs) dir.create(file.path(to, rel), recursive = TRUE, showWarnings = FALSE)
  for (i in seq_along(files)) {
    dir.create(dirname(file.path(to, rel_files[[i]])), recursive = TRUE, showWarnings = FALSE)
    file.copy(files[[i]], file.path(to, rel_files[[i]]), overwrite = TRUE)
  }
  invisible(to)
}

zip_dir <- function(from, zipfile) {
  if (file.exists(zipfile)) unlink(zipfile, force = TRUE)
  old <- setwd(from)
  on.exit(setwd(old), add = TRUE)
  files <- list.files(".", all.files = TRUE, no.. = TRUE, recursive = TRUE)
  ok <- tryCatch({
    utils::zip(zipfile = zipfile, files = files)
    file.exists(zipfile)
  }, error = function(e) FALSE)
  if (!isTRUE(ok)) {
    ps <- Sys.which("powershell")
    if (!nzchar(ps)) ps <- Sys.which("pwsh")
    if (!nzchar(ps)) stop("Could not create ZIP: neither utils::zip nor PowerShell is available.", call. = FALSE)
    cmd <- paste0(
      "Compress-Archive -Path ",
      shQuote(file.path(from, "*"), type = "cmd"),
      " -DestinationPath ",
      shQuote(zipfile, type = "cmd"),
      " -Force"
    )
    status <- system2(ps, c("-NoProfile", "-Command", cmd))
    if (!identical(status, 0L) || !file.exists(zipfile)) {
      stop("PowerShell Compress-Archive failed.", call. = FALSE)
    }
  }
  zipfile
}

temp_root <- tempfile("atlas_mockup_unzip_")
dir.create(temp_root, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(temp_root, recursive = TRUE, force = TRUE), add = TRUE)
utils::unzip(input_zip, exdir = temp_root)

source_files <- list.files(temp_root, pattern = "^atlas_sources[.]csv$", recursive = TRUE, full.names = TRUE)
if (!length(source_files)) stop("Could not find outputs/atlas_sources.csv inside the input ZIP.", call. = FALSE)
output_dir <- dirname(source_files[[1]])
run_dir <- dirname(output_dir)
panel_dir <- file.path(output_dir, "panels")

mock_dir <- file.path(dirname(output_zip), sub("[.]zip$", "", basename(output_zip), ignore.case = TRUE))
copy_dir_contents(run_dir, mock_dir)

mock_output_dir <- file.path(mock_dir, "outputs")
mock_panel_dir <- file.path(mock_output_dir, "panels")
dir_create(mock_panel_dir)

sources <- read_csv_or_empty(file.path(mock_output_dir, "atlas_sources.csv"))
columns <- read_csv_or_empty(file.path(mock_output_dir, "atlas_columns.csv"))
checks <- read_csv_or_empty(file.path(mock_output_dir, "atlas_checks.csv"))
column_profiles <- read_csv_or_empty(file.path(mock_output_dir, "atlas_column_profiles.csv"))
column_top_values <- read_csv_or_empty(file.path(mock_output_dir, "atlas_column_top_values.csv"))
run_summary <- read_csv_or_empty(file.path(mock_output_dir, "atlas_run_summary.csv"))
source_resolution <- read_csv_or_empty(file.path(mock_output_dir, "atlas_source_resolution.csv"))
memory_plan <- read_csv_or_empty(file.path(mock_output_dir, "atlas_memory_plan.csv"))
action_items <- read_csv_or_empty(file.path(mock_output_dir, "atlas_run_action_items.csv"))
db_query_log <- read_tsv_or_empty(file.path(mock_output_dir, "atlas_db_query_log.tsv"))
db_budget_actions <- read_csv_or_empty(file.path(mock_output_dir, "atlas_db_budget_actions.csv"))
access_report <- read_csv_or_empty(file.path(mock_output_dir, "atlas_dalycare_access.csv"))
db_available_in_access_report <- is.data.frame(access_report) &&
  nrow(access_report) > 0 &&
  all(c("check_id", "status") %in% names(access_report)) &&
  any(access_report$check_id == "db_adapter_available" & access_report$status == "ok", na.rm = TRUE)
access_report <- adjust_access_report_for_actual_impact(
  access_report,
  db_adapter = if (db_available_in_access_report) list() else NULL,
  memory_plan = memory_plan
)
if (nrow(access_report)) {
  write_csv(access_report, file.path(mock_output_dir, "atlas_dalycare_access.csv"))
}
if (nrow(checks) && nrow(access_report) && all(c("check_id", "status", "message", "detail") %in% names(access_report))) {
  for (i in seq_len(nrow(access_report))) {
    check_id <- paste0("dalycare_access_", access_report$check_id[[i]])
    hit <- which(checks$check_id == check_id)
    if (length(hit)) {
      checks$severity[hit] <- if (access_report$status[[i]] %in% c("error", "warning")) access_report$status[[i]] else "info"
      checks$message[hit] <- paste(access_report$message[[i]] %||% "", access_report$detail[[i]] %||% "")
    }
  }
  write_csv(checks, file.path(mock_output_dir, "atlas_checks.csv"))
}
if (nrow(run_summary) && all(c("metric", "value") %in% names(run_summary))) {
  run_summary$value[run_summary$metric == "warnings"] <- as.character(sum(checks$severity == "warning", na.rm = TRUE))
  run_summary$value[run_summary$metric == "errors"] <- as.character(sum(checks$severity == "error", na.rm = TRUE))
  write_csv(run_summary, file.path(mock_output_dir, "atlas_run_summary.csv"))
}

panel_files <- list.files(mock_panel_dir, pattern = "[.]csv$", full.names = TRUE)
panels <- lapply(panel_files, read_csv_or_empty)
names(panels) <- sub("[.]csv$", "", basename(panel_files))
panels <- build_coverage_panels(
  sources = sources,
  column_profiles = column_profiles,
  panels = panels,
  min_cell_count = atlas_min_cell_count()
)
panels$atlas_streaming_progress_summary <- atlas_streaming_progress_summary(db_query_log, sources)

for (panel_name in names(panels)) {
  write_csv(panels[[panel_name]], file.path(mock_panel_dir, paste0(panel_name, ".csv")))
}

action_items <- atlas_run_action_items(
  access_report = access_report,
  source_resolution = source_resolution,
  memory_plan = memory_plan,
  sources = sources,
  panels = panels,
  checks = checks
)
budget_action_items <- db_budget_actions_as_run_action_items(db_budget_actions, sources = sources)
if (nrow(budget_action_items)) {
  action_items <- bind_rows_base(list(action_items, budget_action_items))
}
write_csv(action_items, file.path(mock_output_dir, "atlas_run_action_items.csv"))

generated_at <- named_value(stats::setNames(run_summary$value, run_summary$metric), "generated_at", atlas_timestamp())
run_id <- named_value(stats::setNames(run_summary$value, run_summary$metric), "run_id", basename(run_dir))
payload <- atlas_payload(
  run_id = paste0(run_id, "_coverage_mockup"),
  generated_at = generated_at,
  sources = sources,
  columns = columns,
  checks = checks,
  panels = panels,
  column_profiles = column_profiles,
  column_top_values = column_top_values,
  run_summary = run_summary,
  action_items = action_items,
  source_resolution = source_resolution,
  memory_plan = memory_plan,
  db_query_log = db_query_log,
  db_budget_actions = db_budget_actions
)
site_paths <- write_static_atlas(mock_dir, payload, project_root = project_root)

readme <- c(
  "DALY-CARE Atlas V33 coverage mock-up",
  "",
  paste("Input ZIP:", input_zip),
  paste("Generated:", atlas_timestamp()),
  "",
  "This is a static preview generated from the aggregate CSV outputs of the input atlas run.",
  "It is not a fresh live DALY run and it does not contain patient-level data.",
  "",
  "New preview coverage panels:",
  "  - outputs/panels/atlas_temporal_coverage.csv",
  "  - outputs/panels/atlas_temporal_coverage_years.csv",
  "  - outputs/panels/atlas_spatial_region_counts.csv",
  "  - outputs/panels/atlas_spatial_region_coverage.csv",
  "  - outputs/panels/atlas_dk_choropleth_regions.csv",
  "  - outputs/panels/atlas_temporal_date_quality.csv",
  "  - outputs/panels/atlas_streaming_progress_summary.csv",
  "",
  "Open site/DALYCARE_atlas.html to review the mock-up."
)
write_text(readme, file.path(mock_dir, "MOCKUP_README.txt"))

outputs <- list.files(file.path(mock_dir, "outputs"), pattern = "[.]csv$", full.names = TRUE, recursive = FALSE)
panel_outputs <- list.files(mock_panel_dir, pattern = "[.]csv$", full.names = TRUE)
artifact_paths <- c(outputs[basename(outputs) != "output_manifest.csv"], panel_outputs)
artifact_names <- sub("[.]csv$", "", basename(artifact_paths))
artifact_names <- sub("^atlas_", "", artifact_names)
artifact_names[basename(artifact_paths) %in% paste0(names(panels), ".csv")] <- names(panels)
all_paths <- stats::setNames(as.list(artifact_paths), artifact_names)
all_paths$html <- site_paths$html
all_paths$payload <- site_paths$payload
memory_log <- file.path(mock_dir, "logs", "atlas_memory_log.tsv")
if (file.exists(memory_log)) all_paths$memory_log <- memory_log
manifest <- output_manifest(all_paths, run_dir = mock_dir)
write_csv(manifest, file.path(mock_output_dir, "output_manifest.csv"))

zip_dir(mock_dir, output_zip)
cat("Mock-up ZIP written:\n", output_zip, "\n", sep = "")
