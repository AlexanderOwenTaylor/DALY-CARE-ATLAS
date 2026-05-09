root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

tmp <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "b\tfile\tb.csv\t2\tfull",
  "a\tdataset\ta_dataset\t1\t"
), tmp)

source_map <- read_source_map(tmp)
expect_equal(source_map$table_name, c("a", "b"), "Source map should sort by priority.")
expect_equal(source_map$profile_mode[[1]], "full", "Blank profile_mode should default to full.")

bad <- tempfile(fileext = ".tsv")
writeLines(c("table_name\tsource_type", "a\tfile"), bad)
failed <- FALSE
tryCatch(read_source_map(bad), error = function(e) failed <<- TRUE)
expect_true(failed, "Invalid source map should fail validation.")

warn_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "dup\tfile\tmissing.csv\t1\trich",
  "dup\tfile\tmissing_again.csv\t2\tfull"
), warn_map)
warned <- read_source_map(warn_map, project_root = dirname(warn_map))
warnings <- attr(warned, "warnings")
expect_true(any(warnings$warning_id == "duplicate_table_name"), "Duplicate table names should produce a source-map warning.")
expect_true(any(warnings$warning_id == "unsupported_profile_mode"), "Unsupported profile_mode should produce a source-map warning.")
expect_true(any(warnings$warning_id == "missing_file_source"), "Missing file-backed sources should produce a source-map warning.")
expect_equal(warned$profile_mode[[1]], "full", "Unsupported profile_mode should default to full.")

risky <- output_root_warnings(file.path(root, "inst", "legacy", "atlas_runs"), project_root = root)
expect_true(any(risky$warning_id == "risky_output_root"), "Risky output locations should produce a validation warning.")

metadata_map <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode\tdomain\tsubdomain\tatlas_role\tload_strategy\tdb_name\tschema\ttable\tchunk_size\tallow_full_load",
  "RKKP_CLL\tdataset\tRKKP_CLL\t1\tsummary\tRKKP\tCLL\tclinical_registry\tdb_aggregate\tcore\tpublic\tRKKP_CLL\t25000\tFALSE"
), metadata_map)
metadata_source_map <- read_source_map(metadata_map)
expect_true(all(c("domain", "subdomain", "atlas_role", "load_strategy", "db_name", "schema", "table", "chunk_size", "allow_full_load") %in% names(metadata_source_map)), "Optional DALY-CARE metadata and runtime columns should be preserved.")
expect_equal(metadata_source_map$atlas_role[[1]], "clinical_registry", "Optional atlas_role metadata should survive normalization.")
expect_equal(metadata_source_map$load_strategy[[1]], "db_aggregate", "Optional load_strategy should survive normalization.")
