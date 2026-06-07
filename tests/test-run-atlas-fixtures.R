root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
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
expect_file(file.path(result$run_dir, "outputs", "atlas_run_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "output_manifest.csv"))
expect_file(file.path(result$run_dir, "logs", "atlas_execution_log.tsv"))
expect_file(result$html)
expect_file(result$payload)

html <- paste(readLines(result$html, warn = FALSE), collapse = "\n")
payload <- paste(readLines(result$payload, warn = FALSE), collapse = "\n")

expect_true(grepl("DALYCARE_atlas_payload.js", html, fixed = TRUE), "HTML should reference external payload JS.")
expect_false(grepl("window.DALYCARE_ATLAS_PAYLOAD =", html, fixed = TRUE), "HTML should not embed the full payload.")
expect_true(grepl("data-sub=\"confluence-feasibility\"", html, fixed = TRUE), "HTML should include the CONFLUENCE feasibility sub-tab.")
expect_true(grepl("function renderConfluenceFeasibilityPanel", html, fixed = TRUE), "HTML should include the CONFLUENCE feasibility renderer.")
expect_true(grepl("confluence_feasibility", payload, fixed = TRUE), "Payload should include the CONFLUENCE feasibility view model.")

manifest <- read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE, check.names = FALSE)
expect_true(any(manifest$artifact_id == "html"), "Manifest should include the generated HTML artifact.")
expect_true(any(manifest$artifact_id == "payload"), "Manifest should include the generated payload artifact.")

cat("Atlas fixture smoke test passed\n")
