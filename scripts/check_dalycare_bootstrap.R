args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) args[[1]] else "."
project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
source_map_path <- if (length(args) >= 2L) args[[2]] else file.path(project_root, "config", "source-map.dalycare64.production.tsv")
if (!grepl("^[A-Za-z]:|^/", source_map_path)) source_map_path <- file.path(project_root, source_map_path)

source(file.path(project_root, "R", "utils.R"))
source(file.path(project_root, "R", "source_map.R"))
source(file.path(project_root, "R", "db_profile.R"))
source(file.path(project_root, "R", "source_reconciliation.R"))

rows <- list()
add <- function(status, check_id, message, detail = "") {
  rows[[length(rows) + 1L]] <<- data.frame(
    status = status,
    check_id = check_id,
    message = message,
    detail = detail,
    stringsAsFactors = FALSE
  )
}

required_dirs <- c("R", "config", "scripts", "tests", "inst/templates")
for (dir in required_dirs) {
  path <- file.path(project_root, dir)
  if (dir.exists(path)) {
    add("ok", "required_directory", paste("Directory exists:", dir))
  } else {
    add("error", "required_directory_missing", paste("Directory missing:", dir))
  }
}

required_files <- c(
  "config/expected_dalycare_resources_64.tsv",
  "config/source-map.dalycare64.production.tsv",
  "config/source-map.example.tsv",
  "R/source_reconciliation.R",
  "R/db_profile.R",
  "R/run_atlas.R",
  "scripts/source_recovery_dry_run.R",
  "inst/templates/DALYCARE_atlas.html"
)
for (file in required_files) {
  path <- file.path(project_root, file)
  if (file.exists(path)) {
    add("ok", "required_file", paste("File exists:", file))
  } else {
    add("error", "required_file_missing", paste("File missing:", file))
  }
}

expected <- tryCatch(read_expected_dalycare_resources(project_root), error = function(e) e)
if (inherits(expected, "error")) {
  add("error", "expected_resources_invalid", conditionMessage(expected))
} else if (nrow(expected) == 64L) {
  add("ok", "expected_resources_64", "Expected-resource file has 64 rows.")
} else {
  add("error", "expected_resources_not_64", paste("Expected-resource row count:", nrow(expected)))
}

production_map <- tryCatch(read_production_source_recovery_map(project_root, path = source_map_path), error = function(e) e)
if (inherits(production_map, "error")) {
  add("error", "production_source_map_invalid", conditionMessage(production_map))
} else {
  if (nrow(production_map) == 64L) {
    add("ok", "production_source_map_64", "Production source-map candidate has 64 rows.")
  } else {
    add("error", "production_source_map_not_64", paste("Production source-map row count:", nrow(production_map)))
  }
  missing_resolver <- production_map$expected_resource_id[!nzchar(production_map$resolver_type %||% "")]
  if (length(missing_resolver)) {
    add("error", "missing_resolver_strategy", paste("Resources lacking resolver strategy:", paste(missing_resolver, collapse = ", ")))
  } else {
    add("ok", "all_resources_have_resolver", "All expected production resources have resolver strategies.")
  }
  dry_run <- tryCatch(build_source_resolution_plan_dry_run(project_root = project_root, production_map = production_map), error = function(e) e)
  if (inherits(dry_run, "error")) {
    add("error", "dry_run_failed", conditionMessage(dry_run))
  } else if (nrow(dry_run) == 64L && !any(dry_run$dry_run_status == "needs_manual_review", na.rm = TRUE)) {
    add("ok", "dry_run_valid", "Production source recovery dry-run validates all 64 expected resources.")
  } else {
    add("error", "dry_run_needs_review", paste("Dry-run rows:", nrow(dry_run), "manual-review rows:", sum(dry_run$dry_run_status == "needs_manual_review", na.rm = TRUE)))
  }
}

report <- bind_rows_base(rows)
for (i in seq_len(nrow(report))) {
  cat(sprintf("[%s] %s: %s\n", report$status[[i]], report$check_id[[i]], report$message[[i]]))
}
if (any(report$status == "error", na.rm = TRUE)) {
  cat("DALY-CARE atlas package preflight failed.\n")
  quit(status = 1L, save = "no", runLast = FALSE)
}
cat("DALY-CARE atlas package preflight passed. No production DB credentials were required.\n")
