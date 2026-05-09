args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) args[[1]] else "."
project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
source_map_path <- if (length(args) >= 2L) args[[2]] else file.path(project_root, "config", "source-map.dalycare.tsv")
bootstrap_path <- if (length(args) >= 3L) {
  args[[3]]
} else {
  Sys.getenv("DALYCARE_BOOTSTRAP_PATH", file.path(project_root, "inst", "templates", "dalycare_bootstrap.R"))
}

source(file.path(project_root, "R", "utils.R"))
source(file.path(project_root, "R", "source_map.R"))
source(file.path(project_root, "R", "npu_dictionary.R"))
source(file.path(project_root, "R", "code_panels.R"))
source(file.path(project_root, "R", "profiler.R"))
source(file.path(project_root, "R", "db_profile.R"))
source(file.path(project_root, "R", "dalycare_preflight.R"))

attempt_load <- toupper(Sys.getenv("DALYCARE_PREFLIGHT_ATTEMPT_LOAD", unset = "FALSE")) %in% c("1", "TRUE", "YES", "Y")
report <- check_dalycare_bootstrap(
  project_root = project_root,
  source_map_path = source_map_path,
  bootstrap_path = bootstrap_path,
  attempt_load = attempt_load
)
write_dalycare_preflight_report(report)
if (dalycare_preflight_has_errors(report)) {
  quit(status = 1L, save = "no", runLast = FALSE)
}
