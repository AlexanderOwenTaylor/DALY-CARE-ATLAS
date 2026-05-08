root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

dalycare_map_path <- file.path(root, "config", "source-map.dalycare.tsv")
dalycare_map <- read_source_map(dalycare_map_path, project_root = root)
expect_true(all(c("table_name", "source_type", "source", "priority", "profile_mode", "domain", "subdomain", "atlas_role") %in% names(dalycare_map)), "DALY-CARE preset should include required and metadata columns.")
expect_true(all(c(
  "patient", "RKKP_CLL", "RKKP_LYFO", "RKKP_DaMyDa",
  "SP_AdministreretMedicin", "SP_OrdineretMedicin", "SP_AlleProvesvar",
  "SDS_t_adm", "SDS_diagnoser", "SDS_lab_forsker", "t_dalycare_diagnoses"
) %in% dalycare_map$source), "DALY-CARE preset should include canonical load_all_data() sources.")
expect_true(all(c("RKKP", "SP", "SDS", "DALY Views") %in% unique(dalycare_map$domain)), "DALY-CARE preset should preserve source domains.")
expect_true(!any(attr(dalycare_map, "warnings")$warning_id == "unsupported_profile_mode"), "DALY-CARE preset should use supported profile modes.")

old_package_root <- Sys.getenv("DALYCARE_PACKAGE_ROOT", unset = NA)
Sys.unsetenv("DALYCARE_PACKAGE_ROOT")
missing_root_report <- check_dalycare_bootstrap(
  project_root = root,
  source_map_path = dalycare_map_path,
  bootstrap_path = file.path(root, "inst", "templates", "dalycare_bootstrap.R"),
  attempt_load = FALSE
)
expect_true(any(missing_root_report$check_id == "missing_package_root" & missing_root_report$status == "error"), "Preflight should clearly fail when DALYCARE_PACKAGE_ROOT is missing for the default bootstrap.")
if (is.na(old_package_root)) {
  Sys.unsetenv("DALYCARE_PACKAGE_ROOT")
} else {
  Sys.setenv(DALYCARE_PACKAGE_ROOT = old_package_root)
}

fake_bootstrap <- tempfile(fileext = ".R")
writeLines(c(
  "load_dataset <- function(dataset = NULL, value = NULL, column = 'patientid') {",
  "  if (is.null(dataset)) return(c('patient', 'RKKP_CLL'))",
  "  assign(dataset, data.frame(patientid = 1:2, x = 1:2), envir = parent.frame())",
  "  invisible(NULL)",
  "}"
), fake_bootstrap)
fake_report <- check_dalycare_bootstrap(
  project_root = root,
  source_map_path = dalycare_map_path,
  bootstrap_path = fake_bootstrap,
  attempt_load = FALSE
)
expect_false(any(fake_report$status == "error"), "Preflight should succeed with a fake load_dataset() bootstrap when DB access is skipped.")
expect_true(any(fake_report$check_id == "load_dataset_available" & fake_report$status == "ok"), "Preflight should verify load_dataset() exists.")
expect_true(any(fake_report$check_id == "db_access_skipped" & fake_report$status == "ok"), "Preflight should report that real DB access was skipped.")
expect_false(any(grepl("patientid", paste(fake_report$message, fake_report$detail), ignore.case = TRUE)), "Preflight output should stay log-only and avoid patient-level field examples.")

unsupported_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "mystery\tdataset\tNOT_A_DALY_SOURCE\t1\tschema"
), unsupported_map)
unsupported_report <- check_dalycare_bootstrap(
  project_root = root,
  source_map_path = unsupported_map,
  bootstrap_path = fake_bootstrap,
  attempt_load = FALSE
)
expect_true(any(unsupported_report$check_id == "unsupported_source_names"), "Preflight should report unsupported dataset source names.")
