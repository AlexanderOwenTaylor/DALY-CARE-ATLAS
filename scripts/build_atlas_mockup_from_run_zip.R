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
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM"),
    error = function(e) data.frame(stringsAsFactors = FALSE)
  )
}

read_tsv_or_empty <- function(path) {
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  if (is.na(file.info(path)$size) || file.info(path)$size == 0) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(
    utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM"),
    error = function(e) data.frame(stringsAsFactors = FALSE)
  )
}

write_text <- function(lines, path) {
  dir_create(dirname(path))
  writeLines(enc2utf8(lines), path, useBytes = TRUE)
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

zip_dir_with_powershell_dotnet <- function(from, zipfile) {
  ps <- Sys.which("powershell")
  if (!nzchar(ps)) ps <- Sys.which("pwsh")
  if (!nzchar(ps)) {
    stop("Could not create ZIP: neither utils::zip nor PowerShell is available.", call. = FALSE)
  }
  ps_script <- c(
    "param([string]$SourceDir, [string]$ZipPath)",
    "Add-Type -AssemblyName System.IO.Compression",
    "Add-Type -AssemblyName System.IO.Compression.FileSystem",
    "if (Test-Path -LiteralPath $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }",
    "$root = (Resolve-Path -LiteralPath $SourceDir).Path",
    "$zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)",
    "try {",
    "  Get-ChildItem -LiteralPath $root -Recurse -File -Force | ForEach-Object {",
    "    $rel = $_.FullName.Substring($root.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)",
    "    $entryName = $rel -replace '\\\\','/'",
    "    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null",
    "  }",
    "} finally {",
    "  $zip.Dispose()",
    "}"
  )
  ps_file <- tempfile("portable_zip_", fileext = ".ps1")
  writeLines(ps_script, ps_file, useBytes = TRUE)
  on.exit(unlink(ps_file, force = TRUE), add = TRUE)
  status <- system2(
    ps,
    c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps_file, from, zipfile)
  )
  if (!identical(status, 0L) || !file.exists(zipfile)) {
    stop("Portable PowerShell ZIP creation failed.", call. = FALSE)
  }
  invisible(zipfile)
}

zip_dir <- function(from, zipfile) {
  from <- normalizePath(from, winslash = "/", mustWork = TRUE)
  zipfile <- normalizePath(zipfile, winslash = "/", mustWork = FALSE)
  if (file.exists(zipfile)) unlink(zipfile, force = TRUE)
  old <- setwd(from)
  on.exit(setwd(old), add = TRUE)
  files <- gsub("\\\\", "/", list.files(".", all.files = TRUE, no.. = TRUE, recursive = TRUE))
  ok <- tryCatch({
    utils::zip(zipfile = zipfile, files = files)
    file.exists(zipfile)
  }, error = function(e) FALSE)
  if (!isTRUE(ok)) {
    zip_dir_with_powershell_dotnet(from, zipfile)
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
source_map_files <- list.files(temp_root, pattern = "^source-map[.]dalycare[.]tsv$", recursive = TRUE, full.names = TRUE)
source_map <- if (length(source_map_files)) {
  read_source_map(source_map_files[[1]], project_root = project_root)
} else {
  data.frame(stringsAsFactors = FALSE)
}

mock_dir <- file.path(dirname(output_zip), sub("[.]zip$", "", basename(output_zip), ignore.case = TRUE))
copy_dir_contents(run_dir, mock_dir)

copy_project_artifact <- function(relative_path) {
  src <- file.path(project_root, relative_path)
  if (!file.exists(src)) return(invisible(FALSE))
  dest <- file.path(mock_dir, relative_path)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  file.copy(src, dest, overwrite = TRUE)
  invisible(TRUE)
}

project_artifacts <- c(
  "RUN_KI67_FINDER.R",
  "RUN_MCL_TRIANGLE_COUNTS.R",
  "RUN_SMM_IMMUNITY_TRACKER_COUNTS.R",
  "config/mcl_triangle_feasibility_concepts.tsv",
  "config/mcl_triangle_person_date_mapping.tsv",
  "config/mcl_triangle_count_value_mappings.tsv",
  "config/smm_immunity_tracker_cohort_sources.tsv",
  "config/smm_immunity_tracker_endpoint_definitions.tsv",
  "config/smm_immunity_tracker_analysis_windows.tsv",
  "config/smm_immunity_tracker_wp5_output_contract.tsv",
  "clinical_questions/ki67_extraction_spec.yml",
  "clinical_questions/mcl_triangle_count_definitions.yml",
  "clinical_questions/mcl_triangle_high_risk_biology_definitions.yml",
  "MCL_TRIANGLE_EVIDENCE_MATCHING_FIX_NOTES.md",
  "MCL_TRIANGLE_COUNTS_PRODUCTION_NOTES.md",
  "MCL_TRIANGLE_ANSWERABILITY_COUNTS_NOTES.md",
  "KI67_ONE_CLICK_RSTDIO_NOTES.md",
  "KI67_DIRECT_PRODUCTION_FINDER_NOTES.md",
  "KI67_DISCOVERY_NOTES.md",
  "KI67_PRODUCTION_VALIDATION_PLAN.md",
  "R/utils.R",
  "R/dalycare_preflight.R",
  "R/source_map.R",
  "R/db_profile.R",
  "R/ki67_discovery.R",
  "R/patobank_ki67_cartography.R",
  "R/ki67_production_finder.R",
  "R/mcl_triangle_counts.R",
  "R/mcl_triangle_feasibility.R",
  "R/smm_immunity_tracker_feasibility.R",
  "R/smm_immunity_tracker_counts.R",
  "scripts/build_ki67_discovery.R",
  "scripts/find_ki67_in_production.R",
  "scripts/source_ki67_finder.R",
  "scripts/source_mcl_triangle_counts.R",
  "scripts/source_smm_immunity_tracker_counts.R",
  "scripts/run_tests.R",
  "docs/SMM_IMMUNITY_TRACKER_NOTES.md",
  "tests/helper.R",
  "tests/test-ki67-discovery.R",
  "tests/test-ki67-production-finder.R",
  "tests/test-ki67-one-click-runner.R",
  "tests/test-mcl-triangle-counts.R",
  "tests/test-mcl-triangle-answerability-counts.R",
  "tests/test-mcl-triangle-feasibility.R",
  "tests/test-mcl-triangle-evidence-filtering.R",
  "tests/test_smm_immunity_tracker_counts.R",
  "tests/test_smm_immunity_tracker_payload.R"
)
invisible(vapply(project_artifacts, copy_project_artifact, logical(1)))

copy_mcl_triangle_count_outputs <- function(from, to) {
  if (!dir.exists(from) || !dir.exists(to)) return(invisible(FALSE))
  patterns <- c(
    "^mcl_triangle_.*[.]csv$",
    "^mcl_triangle_count_query_templates[.]sql$",
    "^output_generation_status[.]csv$"
  )
  files <- unique(unlist(lapply(patterns, function(pattern) {
    list.files(from, pattern = pattern, full.names = TRUE)
  }), use.names = FALSE))
  if (!length(files)) return(invisible(FALSE))
  file.copy(files, file.path(to, basename(files)), overwrite = TRUE)
  invisible(TRUE)
}

accepted_mcl_source <- function(source) {
  nzchar(source$outputs_dir %||% "") &&
    exists("mcl_count_output_dir_is_accepted_production", mode = "function") &&
    isTRUE(mcl_count_output_dir_is_accepted_production(source$outputs_dir))
}

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

semantic_outputs <- build_semantic_outputs(
  project_root = project_root,
  sources = sources,
  column_profiles = column_profiles,
  panels = panels,
  min_cell_count = atlas_min_cell_count()
)
product_outputs <- build_product_layer_outputs(
  semantic_outputs = semantic_outputs,
  sources = sources,
  panels = panels,
  column_profiles = column_profiles,
  min_cell_count = atlas_min_cell_count(),
  project_root = project_root
)
write_csv(semantic_outputs$dictionary, file.path(mock_output_dir, "atlas_semantic_data_dictionary.csv"))
write_csv(semantic_outputs$value_map, file.path(mock_output_dir, "atlas_semantic_value_map.csv"))
write_csv(semantic_outputs$code_map, file.path(mock_output_dir, "atlas_semantic_code_map.csv"))
write_csv(semantic_outputs$panel_links, file.path(mock_output_dir, "atlas_semantic_panel_links.csv"))
write_csv(semantic_outputs$unmapped_entity_overlay, file.path(mock_output_dir, "atlas_semantic_unmapped_entity_overlay.csv"))
write_csv(semantic_outputs$overlay_lookup, file.path(mock_output_dir, "atlas_semantic_overlay_lookup.csv"))
write_csv(semantic_outputs$curator_label_promotions, file.path(mock_output_dir, "atlas_curator_label_promotions.csv"))
write_csv(semantic_outputs$curator_label_lookup, file.path(mock_output_dir, "atlas_curator_label_promotion_lookup.csv"))
write_csv(semantic_outputs$mapping_conflicts, file.path(mock_output_dir, "atlas_semantic_mapping_conflicts.csv"))
write_csv(product_outputs$clinical_concepts, file.path(mock_output_dir, "atlas_clinical_concepts.csv"))
write_csv(product_outputs$domain_panels, file.path(mock_output_dir, "atlas_domain_panels.csv"))
write_csv(product_outputs$panel_kpis, file.path(mock_output_dir, "atlas_panel_kpis.csv"))
write_csv(product_outputs$panel_distributions, file.path(mock_output_dir, "atlas_panel_distributions.csv"))
write_csv(product_outputs$panel_raw_fields, file.path(mock_output_dir, "atlas_panel_raw_fields.csv"))
write_csv(product_outputs$panel_parity, file.path(mock_output_dir, "atlas_panel_parity.csv"))

legacy_resource_audit <- build_legacy_cartography_source_resolution_audit(project_root)
production_source_map <- read_production_source_recovery_map(project_root)
source_resolution_plan_dry_run <- build_source_resolution_plan_dry_run(
  project_root = project_root,
  production_map = production_source_map
)
source_resolution_attempts <- build_source_resolution_attempts(
  project_root = project_root,
  production_map = production_source_map,
  sources = sources,
  source_resolution = source_resolution
)
source_resolution_delta <- build_source_resolution_delta_legacy_vs_current(
  project_root = project_root,
  source_map = source_map,
  sources = sources,
  source_resolution = source_resolution,
  legacy_audit = legacy_resource_audit,
  source_attempts = source_resolution_attempts
)
resource_reconciliation <- build_atlas_resource_reconciliation(
  project_root = project_root,
  source_map = source_map,
  sources = sources,
  source_resolution = source_resolution,
  legacy_audit = legacy_resource_audit,
  source_attempts = source_resolution_attempts
)
source_truth_evidence <- build_source_truth_evidence_matrix(
  project_root = project_root,
  legacy_audit = legacy_resource_audit,
  delta = source_resolution_delta,
  reconciliation = resource_reconciliation
)
source_truth_metrics <- source_truth_summary(source_truth_evidence)
canonical_resources <- read_canonical_dalycare_resources(project_root)
source_map_crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
  project_root = project_root,
  source_map = source_map,
  sources = sources,
  source_resolution = source_resolution,
  canonical = canonical_resources
)
current_run_source_map_audit <- build_current_run_source_map_audit(
  project_root = project_root,
  source_map = source_map,
  sources = sources,
  source_resolution = source_resolution,
  canonical = canonical_resources
)
canonical_reconciliation <- build_canonical_resource_reconciliation_64(
  project_root = project_root,
  source_map = source_map,
  sources = sources,
  source_resolution = source_resolution,
  canonical = canonical_resources,
  resource_reconciliation = resource_reconciliation
)
billeddiagnostik_del2_audit <- build_billeddiagnostik_del2_regression_audit(
  project_root = project_root,
  sources = sources,
  source_resolution = source_resolution,
  canonical_reconciliation = canonical_reconciliation,
  crosswalk = source_map_crosswalk
)
remaining_activation_plan <- build_remaining_canonical_resources_activation_plan(
  project_root = project_root,
  canonical_reconciliation = canonical_reconciliation,
  production_map = production_source_map,
  canonical = canonical_resources
)
legacy_reference_vs_current <- build_legacy_reference_vs_current_profiled_evidence(
  project_root = project_root,
  semantic_dictionary = semantic_outputs$dictionary,
  semantic_code_map = semantic_outputs$code_map,
  semantic_value_map = semantic_outputs$value_map,
  canonical_reconciliation = canonical_reconciliation,
  sources = sources,
  canonical = canonical_resources
)
ki67_discovery <- build_ki67_discovery_outputs(
  project_root = project_root,
  include_reference_files = TRUE,
  semantic_dictionary = semantic_outputs$dictionary,
  semantic_value_map = semantic_outputs$value_map,
  semantic_code_map = semantic_outputs$code_map,
  semantic_panel_links = semantic_outputs$panel_links,
  semantic_overlay_lookup = semantic_outputs$overlay_lookup,
  clinical_concepts = product_outputs$clinical_concepts,
  domain_panels = product_outputs$domain_panels,
  panel_kpis = product_outputs$panel_kpis,
  panel_distributions = product_outputs$panel_distributions,
  panel_raw_fields = product_outputs$panel_raw_fields,
  sources = sources,
  columns = columns,
  column_profiles = column_profiles,
  column_top_values = column_top_values,
  source_resolution = source_resolution,
  canonical_reconciliation = canonical_reconciliation,
  legacy_reference_vs_current = legacy_reference_vs_current
)
mcl_triangle_feasibility <- build_mcl_triangle_feasibility_outputs(
  project_root = project_root,
  semantic_dictionary = semantic_outputs$dictionary,
  semantic_value_map = semantic_outputs$value_map,
  semantic_code_map = semantic_outputs$code_map,
  semantic_panel_links = semantic_outputs$panel_links,
  columns = columns,
  column_profiles = column_profiles,
  panel_raw_fields = product_outputs$panel_raw_fields,
  panel_distributions = product_outputs$panel_distributions,
  panel_kpis = product_outputs$panel_kpis,
  sources = sources,
  canonical_reconciliation = canonical_reconciliation,
  legacy_reference_vs_current = legacy_reference_vs_current,
  ki67_discovery = ki67_discovery
)
confluence_feasibility <- build_confluence_feasibility_outputs(
  project_root = project_root,
  sources = sources,
  columns = columns,
  column_profiles = column_profiles,
  column_top_values = column_top_values,
  panels = panels,
  panel_raw_fields = product_outputs$panel_raw_fields,
  panel_distributions = product_outputs$panel_distributions,
  panel_kpis = product_outputs$panel_kpis,
  canonical_reconciliation = canonical_reconciliation,
  legacy_reference_vs_current = legacy_reference_vs_current,
  min_cell_count = atlas_min_cell_count()
)
confluence_write_outputs(confluence_feasibility, mock_output_dir)

write_csv(legacy_resource_audit, file.path(mock_output_dir, "legacy_cartography_source_resolution_audit.csv"))
write_csv(billeddiagnostik_del2_audit, file.path(mock_output_dir, "billeddiagnostik_del2_regression_audit.csv"))
write_csv(source_resolution_plan_dry_run, file.path(mock_output_dir, "source_resolution_plan_dry_run.csv"))
write_csv(source_resolution_attempts, file.path(mock_output_dir, "source_resolution_attempts.csv"))
write_csv(source_resolution_delta, file.path(mock_output_dir, "source_resolution_delta_legacy_vs_current.csv"))
write_csv(resource_reconciliation, file.path(mock_output_dir, "atlas_resource_reconciliation.csv"))
write_csv(source_truth_evidence, file.path(mock_output_dir, "source_truth_evidence_matrix.csv"))
write_csv(source_truth_metrics, file.path(mock_output_dir, "source_truth_summary.csv"))
write_csv(current_run_source_map_audit, file.path(mock_output_dir, "current_run_source_map_audit.csv"))
write_csv(canonical_reconciliation, file.path(mock_output_dir, "canonical_resource_reconciliation_64.csv"))
write_csv(source_map_crosswalk, file.path(mock_output_dir, "source_map_row_to_canonical_resource_crosswalk.csv"))
write_csv(legacy_reference_vs_current, file.path(mock_output_dir, "legacy_reference_vs_current_profiled_evidence.csv"))
write_csv(remaining_activation_plan, file.path(mock_output_dir, "remaining_canonical_resources_activation_plan.csv"))
ki67_write_outputs(ki67_discovery, output_dir = mock_output_dir, project_root = project_root)
patobank_ki67_percent <- patobank_ki67_read_outputs(mock_output_dir)
patobank_file_audit <- patobank_ki67_validate_output_files(mock_output_dir)
if (any(patobank_file_audit$status == "empty_output_error")) {
  patobank_ki67_percent <- patobank_ki67_fail_closed_outputs(
    reason_id = "input_patobank_ki67_header_only",
    label = "PATOBANK Ki-67 cartography output",
    notes = "Input atlas artifact contained header-only PATOBANK Ki-67 cartography files. Mock-up output fails closed instead of presenting empty scaffolds as completed coverage.",
    source_table = "SDS_pato",
    source_column = "c_snomedkode",
    query_templates = patobank_ki67_percent$query_templates %||% character()
  )
  patobank_ki67_write_outputs(patobank_ki67_percent, output_dir = mock_output_dir)
} else if (!file.exists(file.path(mock_output_dir, "patobank_ki67_percent_summary.csv"))) {
  patobank_ki67_write_outputs(patobank_ki67_percent, output_dir = mock_output_dir)
}
mcl_triangle_write_outputs(mcl_triangle_feasibility, mock_output_dir)
standalone_mcl_source <- if (exists("mcl_count_resolve_standalone_output_source", mode = "function")) {
  mcl_count_resolve_standalone_output_source(
    project_root = project_root,
    outputs_dir = mock_output_dir,
    count_output_zip = "",
    count_output_dir = mock_output_dir
  )
} else {
  list(outputs_dir = "", metadata = mcl_triangle_empty_standalone_output_source())
}
if (!accepted_mcl_source(standalone_mcl_source) && exists("mcl_count_resolve_standalone_output_source", mode = "function")) {
  standalone_mcl_source <- mcl_count_resolve_standalone_output_source(
    project_root = project_root,
    outputs_dir = mock_output_dir,
    count_output_zip = "",
    count_output_dir = ""
  )
}
if (exists("mcl_count_read_outputs", mode = "function") &&
    accepted_mcl_source(standalone_mcl_source)) {
  copy_mcl_triangle_count_outputs(standalone_mcl_source$outputs_dir, mock_output_dir)
  mcl_triangle_feasibility$cohort_counts <- mcl_count_read_outputs(standalone_mcl_source$outputs_dir)
  mcl_triangle_feasibility$standalone_output_source <- standalone_mcl_source$metadata
  mcl_triangle_feasibility$pathology_ki67_signpost <- mcl_triangle_pathology_ki67_signpost(mcl_triangle_feasibility$cohort_counts)
} else if (exists("mcl_count_build_outputs", mode = "function")) {
  mcl_triangle_count_outputs <- mcl_count_build_outputs(
    project_root = project_root,
    outputs_dir = mock_output_dir,
    mode = "plan",
    min_cell_count = atlas_min_cell_count()
  )
  mcl_count_write_outputs(mcl_triangle_count_outputs, mock_output_dir)
  mcl_triangle_feasibility$cohort_counts <- mcl_count_read_outputs(mock_output_dir)
  mcl_triangle_feasibility$standalone_output_source <- if (exists("mcl_count_empty_standalone_output_source", mode = "function")) {
    mcl_count_empty_standalone_output_source()
  } else {
    mcl_triangle_empty_standalone_output_source()
  }
  mcl_triangle_feasibility$pathology_ki67_signpost <- mcl_triangle_pathology_ki67_signpost(mcl_triangle_feasibility$cohort_counts)
}

ki67_db_files <- file.path(
  mock_output_dir,
  c(
    "ki67_db_aeki_code_counts.csv",
    "ki67_db_p16_dual_stain_counts.csv",
    "ki67_db_text_pattern_counts.csv",
    "ki67_db_registry_field_counts.csv",
    "ki67_db_summary.csv",
    "ki67_found_locations.csv"
  )
)
if (any(file.exists(ki67_db_files))) {
  ki67_db_outputs <- ki67_db_read_outputs(mock_output_dir)
  write_csv(ki67_db_outputs$summary, file.path(mock_output_dir, "ki67_db_summary.csv"))
  write_csv(ki67_db_outputs$found_locations, file.path(mock_output_dir, "ki67_found_locations.csv"))
  ki67_db_apply_to_mcl_outputs(mock_output_dir, ki67_db_outputs)
  mcl_triangle_feasibility$summary <- read_csv_or_empty(file.path(mock_output_dir, "mcl_triangle_feasibility_summary.csv"))
  mcl_triangle_feasibility$biology_gap_analysis <- read_csv_or_empty(file.path(mock_output_dir, "mcl_triangle_biology_gap_analysis.csv"))
  mcl_triangle_feasibility$study_readiness_matrix <- read_csv_or_empty(file.path(mock_output_dir, "mcl_triangle_study_readiness_matrix.csv"))
  ki67_discovery$channel_summary <- read_csv_or_empty(file.path(mock_output_dir, "ki67_channel_summary.csv"))
  ki67_discovery$db_summary <- ki67_db_outputs$summary
  ki67_discovery$db_found_locations <- ki67_db_outputs$found_locations
  ki67_discovery$db_aeki_code_counts <- ki67_db_outputs$aeki_code_counts
  ki67_discovery$db_p16_dual_stain_counts <- ki67_db_outputs$p16_dual_stain_counts
  ki67_discovery$db_text_pattern_counts <- ki67_db_outputs$text_pattern_counts
  ki67_discovery$db_registry_field_counts <- ki67_db_outputs$registry_field_counts
  mcl_triangle_feasibility$ki67_discovery <- ki67_discovery
}

if (nrow(run_summary) && all(c("metric", "value") %in% names(run_summary))) {
  source_recovery_metrics <- source_recovery_run_summary_metrics(
    plan = production_source_map,
    dry_run = source_resolution_plan_dry_run,
    attempts = source_resolution_attempts
  )
  canonical_metrics <- canonical_resource_summary_metrics(
    canonical_reconciliation = canonical_reconciliation,
    crosswalk = source_map_crosswalk,
    legacy_reference = legacy_reference_vs_current
  )
  run_summary <- run_summary[!run_summary$metric %in% c(source_recovery_metrics$metric, canonical_metrics$metric), , drop = FALSE]
  run_summary <- bind_rows_base(list(run_summary, source_recovery_metrics, canonical_metrics))
  write_csv(run_summary, file.path(mock_output_dir, "atlas_run_summary.csv"))
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
  db_budget_actions = db_budget_actions,
  semantic_dictionary = semantic_outputs$dictionary,
  semantic_value_map = semantic_outputs$value_map,
  semantic_code_map = semantic_outputs$code_map,
  semantic_panel_links = semantic_outputs$panel_links,
  semantic_unmapped_entity_overlay = semantic_outputs$unmapped_entity_overlay,
  semantic_overlay_lookup = semantic_outputs$overlay_lookup,
  curator_label_promotions = semantic_outputs$curator_label_promotions,
  curator_label_lookup = semantic_outputs$curator_label_lookup,
  semantic_mapping_conflicts = semantic_outputs$mapping_conflicts,
  clinical_concepts = product_outputs$clinical_concepts,
  domain_panels = product_outputs$domain_panels,
  panel_kpis_product = product_outputs$panel_kpis,
  panel_distributions = product_outputs$panel_distributions,
  panel_raw_fields = product_outputs$panel_raw_fields,
  panel_parity = product_outputs$panel_parity,
  legacy_resource_audit = legacy_resource_audit,
  billeddiagnostik_del2_regression_audit = billeddiagnostik_del2_audit,
  source_resolution_plan_dry_run = source_resolution_plan_dry_run,
  source_resolution_attempts = source_resolution_attempts,
  source_resolution_delta = source_resolution_delta,
  resource_reconciliation = resource_reconciliation,
  source_truth_evidence = source_truth_evidence,
  source_truth_summary = source_truth_metrics,
  current_run_source_map_audit = current_run_source_map_audit,
  canonical_resource_reconciliation = canonical_reconciliation,
  source_map_crosswalk = source_map_crosswalk,
  legacy_reference_vs_current = legacy_reference_vs_current,
  remaining_activation_plan = remaining_activation_plan,
  ki67_discovery = ki67_discovery,
  patobank_ki67_percent = patobank_ki67_percent,
  mcl_triangle_feasibility = mcl_triangle_feasibility,
  confluence_feasibility = confluence_feasibility
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
  paste("Visual QA source artifact:", input_zip),
  "Fixture-output visual QA runs validate the atlas template against fixture outputs. A separate full-output visual QA run is required before final visual acceptance of production-scale data.",
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
