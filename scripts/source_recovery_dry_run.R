usage <- paste(
  "Usage:",
  "  Rscript scripts/source_recovery_dry_run.R [project_root] [source_map_path] [output_root]",
  "",
  "Examples:",
  "  Rscript scripts/source_recovery_dry_run.R . config/source-map.dalycare64.production.tsv source_recovery_dry_run",
  sep = "\n"
)

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = FALSE)
  repeat {
    if (
      file.exists(file.path(current, "R", "source_reconciliation.R")) &&
        file.exists(file.path(current, "config", "expected_dalycare_resources_64.tsv"))
    ) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }
  normalizePath(start, winslash = "/", mustWork = FALSE)
}

load_dry_run_runtime <- function(project_root) {
  source(file.path(project_root, "R", "utils.R"))
  source(file.path(project_root, "R", "source_map.R"))
  source(file.path(project_root, "R", "db_profile.R"))
  source(file.path(project_root, "R", "source_reconciliation.R"))
  invisible(TRUE)
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("-h", "--help"))) {
  cat(usage, "\n")
  quit(save = "no", status = 0)
}

project_root <- if (length(args) >= 1) args[[1]] else find_project_root()
project_root <- find_project_root(project_root)
source_map_path <- if (length(args) >= 2) args[[2]] else file.path(project_root, "config", "source-map.dalycare64.production.tsv")
if (!grepl("^[A-Za-z]:|^/", source_map_path)) source_map_path <- file.path(project_root, source_map_path)
output_root <- if (length(args) >= 3) args[[3]] else file.path(project_root, "source_recovery_dry_run")
if (!grepl("^[A-Za-z]:|^/", output_root)) output_root <- file.path(project_root, output_root)
output_dir <- file.path(output_root, "outputs")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

load_dry_run_runtime(project_root)
plan <- read_production_source_recovery_map(project_root = project_root, path = source_map_path)
dry_run <- build_source_resolution_plan_dry_run(project_root = project_root, production_map = plan)
summary <- source_recovery_run_summary_metrics(plan = plan, dry_run = dry_run)
summary <- summary[!grepl("^source_resolution_", summary$metric), , drop = FALSE]
summary <- bind_rows_base(list(
  summary,
  data.frame(
    metric = "production_attempt_status",
    value = "not_applicable_dry_run",
    stringsAsFactors = FALSE
  )
))

write_csv(dry_run, file.path(output_dir, "source_resolution_plan_dry_run.csv"))
write_csv(summary, file.path(output_dir, "source_recovery_dry_run_summary.csv"))

cat("Production source recovery dry run complete\n")
cat("Resources in plan:", nrow(plan), "\n")
cat("Dry-run report:", file.path(output_dir, "source_resolution_plan_dry_run.csv"), "\n")
