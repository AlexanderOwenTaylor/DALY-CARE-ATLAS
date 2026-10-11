# Focused shared synthetic-fixture checks; repository or workspace cwd.
privacy_test_root <- if (file.exists("R/public_privacy.R")) "." else "atlas-source"
source(file.path(privacy_test_root,"R/utils.R"), encoding = "UTF-8")
source(file.path(privacy_test_root,"R/public_privacy.R"), encoding = "UTF-8")
source(file.path(privacy_test_root,"R/profiler.R"), encoding = "UTF-8")
fixtures <- jsonlite::fromJSON(file.path(privacy_test_root,"tests/fixtures/public-privacy-input.json"), simplifyVector = FALSE)
out <- lapply(fixtures, atlas_public_privacy, project_root = privacy_test_root)
stopifnot(identical(out, lapply(out, atlas_public_privacy, project_root = privacy_test_root)))
stopifnot(normalize_min_cell_count(1) == 5, normalize_min_cell_count(10) == 10)
stopifnot(out[[1]]$column_profile_rows[[1]]$mean == "7")
for (i in c(2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18)) {
  stopifnot(is.null(out[[i]]$column_profile_rows[[1]]$mean))
}
encoded <- atlas_to_json(out)
for (forbidden in c("SYNTHETIC_FORBIDDEN_NAME","SYNTHETIC_FORBIDDEN_UUID","1927-02-03","987654.125","-999")) stopifnot(!grepl(forbidden, encoded, fixed = TRUE))
privacy_test_output <- Sys.getenv("DALYCARE_PRIVACY_TEST_OUTPUT",unset=tempfile(fileext=".json"))
writeLines(encoded, privacy_test_output, useBytes = TRUE)
cat(length(fixtures), "shared fixtures, R idempotence, threshold, independent assertions and byte absence passed\n")
