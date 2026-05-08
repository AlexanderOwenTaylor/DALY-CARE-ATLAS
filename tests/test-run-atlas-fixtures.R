root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

out_root <- tempfile("atlas_runs_")
result <- run_atlas(
  project_root = root,
  source_map_path = file.path(root, "config", "source-map.example.tsv"),
  output_root = out_root,
  mode = "report"
)

expect_file(file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_sources.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_columns.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_checks.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_value_frequencies.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "lab_npu_code_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "diagnosis_icd_groups.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "damyda_feature_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "output_manifest.csv"))
expect_file(file.path(result$run_dir, "logs", "atlas_execution_log.tsv"))
expect_file(result$html)
expect_file(result$payload)

html <- paste(readLines(result$html, warn = FALSE), collapse = "\n")
expect_true(grepl("DALYCARE_atlas_payload.js", html, fixed = TRUE), "HTML should reference external payload JS.")

freq <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_value_frequencies.csv"), stringsAsFactors = FALSE)
expect_false(any(freq$column_name == "patientid"), "Public value frequencies must not expose patient IDs.")

manifest <- utils::read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE)
expect_true(all(c("resource_catalog", "sources", "columns", "checks", "value_frequencies", "html", "payload") %in% manifest$artifact_id), "Manifest should list expected artifacts.")
expect_true(all(manifest$status == "ok"), "Manifest artifacts should exist.")

sources <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_sources.csv"), stringsAsFactors = FALSE)
expect_true(!any(sources$date_column_guess == "patientid"), "Patient identifiers should not be guessed as date columns.")
expect_true("2021-01-01" %in% sources$min_date, "Date ranges should be emitted as ISO dates.")
