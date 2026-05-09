# DALY-CARE atlas bootstrap.
#
# Set DALYCARE_PACKAGE_ROOT to the checkout that contains dalycare/functions/load_dataset.R.
# Live database access is still controlled by the DALY-CARE package and the user's
# NGC db_access.R file, usually /ngc/people/<user>/db_access.R.

dalycare_package_root <- Sys.getenv("DALYCARE_PACKAGE_ROOT", unset = "")
if (!nzchar(dalycare_package_root)) {
  stop("DALYCARE_PACKAGE_ROOT is not set.", call. = FALSE)
}

load_dataset_path <- file.path(dalycare_package_root, "dalycare", "functions", "load_dataset.R")
if (!file.exists(load_dataset_path)) {
  stop("load_dataset.R not found under DALYCARE_PACKAGE_ROOT: ", load_dataset_path, call. = FALSE)
}

source(load_dataset_path, local = .GlobalEnv)
if (!exists("load_dataset", mode = "function", envir = .GlobalEnv)) {
  stop("DALY-CARE bootstrap completed but load_dataset() is unavailable.", call. = FALSE)
}

invisible(TRUE)
