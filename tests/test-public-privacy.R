# Focused shared synthetic-fixture checks; repository or workspace cwd.
privacy_test_root <- if (file.exists("R/public_privacy.R")) "." else "atlas-source"
source(file.path(privacy_test_root,"R/utils.R"), encoding = "UTF-8")
source(file.path(privacy_test_root,"R/public_privacy.R"), encoding = "UTF-8")
source(file.path(privacy_test_root,"R/profiler.R"), encoding = "UTF-8")
fixtures <- jsonlite::fromJSON(file.path(privacy_test_root,"tests/fixtures/public-privacy-input.json"), simplifyVector = FALSE)
out <- lapply(fixtures, atlas_public_privacy, project_root = privacy_test_root)
stopifnot(identical(out, lapply(out, atlas_public_privacy, project_root = privacy_test_root)))
stopifnot(normalize_min_cell_count(1) == 5, normalize_min_cell_count(10) == 10)
stopifnot(is.null(out[[1]]$column_profile_rows[[1]]$mean))
for (i in c(2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18)) {
  stopifnot(is.null(out[[i]]$column_profile_rows[[1]]$mean))
}
encoded <- atlas_to_json(out)
for (forbidden in c("SYNTHETIC_FORBIDDEN_NAME","SYNTHETIC_FORBIDDEN_UUID","1927-02-03","987654.125","-999")) stopifnot(!grepl(forbidden, encoded, fixed = TRUE))
privacy_test_output <- Sys.getenv("DALYCARE_PRIVACY_TEST_OUTPUT",unset=tempfile(fileext=".json"))
writeLines(encoded, privacy_test_output, useBytes = TRUE)
cat(length(fixtures), "shared fixtures, R idempotence, threshold, independent assertions and byte absence passed\n")

range_payload <- function(end) {
 rows <- lapply(1980:end,function(year) list(table_name='S',date_column='D',coverage_basis='source_date_range',year=year,n_rows=NULL,pct=NULL))
 rows <- c(rows,list(list(table_name='S',date_column='E',coverage_basis='event_date_counts',year=2020,n_rows=20,pct=100),list(table_name='S',date_column='F',coverage_basis='streamed_event_date_counts',year=2021,n_rows=30,pct=100)))
 inventory <- list(list(group='Coverage',panel_name='atlas_temporal_coverage_years',title='Years',n_rows=length(rows)))
 list(panels=list(atlas_temporal_coverage_years=rows),review_temporal_coverage=list(years=rows,summary=list(list(table_name='S',date_column='D',n_year_rows=end-1979))),panel_groups=inventory,review_overview=list(panel_groups=inventory),review_infrastructure_sections=list(panels=inventory))
}
range_a <- atlas_public_privacy(range_payload(1982),privacy_test_root)
range_b <- atlas_public_privacy(range_payload(2025),privacy_test_root)
stopifnot(identical(range_a,range_b),length(range_a$panels$atlas_temporal_coverage_years)==3L,is.null(range_a$panels$atlas_temporal_coverage_years[[1]]$year),range_a$panels$atlas_temporal_coverage_years[[2]]$n_rows==20,range_a$panels$atlas_temporal_coverage_years[[3]]$year==2021,identical(range_a,atlas_public_privacy(range_a,privacy_test_root)))
