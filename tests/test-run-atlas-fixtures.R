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

for (path in c(
  file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv"),
  file.path(result$run_dir, "outputs", "atlas_source_resolution.csv"),
  file.path(result$run_dir, "outputs", "atlas_sources.csv"),
  file.path(result$run_dir, "outputs", "atlas_columns.csv"),
  file.path(result$run_dir, "outputs", "atlas_checks.csv"),
  file.path(result$run_dir, "outputs", "atlas_run_summary.csv"),
  file.path(result$run_dir, "outputs", "output_manifest.csv"),
  file.path(result$run_dir, "logs", "atlas_execution_log.tsv"),
  result$html,
  result$payload
)) {
  expect_file(path)
}

html <- paste(readLines(result$html, warn = FALSE), collapse = "\n")
expect_true(grepl("DALYCARE_atlas_payload.js", html, fixed = TRUE), "HTML should reference external payload JS.")
expect_false(grepl("window.DALYCARE_ATLAS_PAYLOAD =", html, fixed = TRUE), "HTML should not embed the full payload.")
expect_true(grepl("<meta name=\"author\" content=\"Alexander Owen Taylor\">", html, fixed = TRUE), "HTML should include author metadata.")
expect_true(grepl("tab-overview", html, fixed = TRUE), "HTML should include the Overview tab.")
expect_true(grepl("tab-dictionary", html, fixed = TRUE), "HTML should include the Data Dictionary tab.")
expect_true(grepl("tab-clinical-feasibility", html, fixed = TRUE), "HTML should include the Clinical Feasibility tab.")
expect_true(grepl("data-sub=\"mcl-triangle-feasibility\"", html, fixed = TRUE), "HTML should include the MCL/TRIANGLE feasibility sub-tab.")
expect_true(grepl("function renderMclTriangleFeasibilityPanel", html, fixed = TRUE), "HTML should include the MCL/TRIANGLE feasibility renderer.")

payload_js <- paste(readLines(result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl("window.DALYCARE_ATLAS_PAYLOAD", payload_js, fixed = TRUE), "Payload JS should define the atlas payload.")
expect_true(grepl("mcl_triangle", payload_js, fixed = TRUE), "Payload should include MCL/TRIANGLE aggregate fields.")

manifest <- read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE)
manifest_text <- paste(unlist(manifest), collapse = "\n")
expect_true(grepl("DALYCARE_atlas.html", manifest_text, fixed = TRUE), "Manifest should include the HTML artifact.")
expect_true(grepl("DALYCARE_atlas_payload.js", manifest_text, fixed = TRUE), "Manifest should include the payload artifact.")

message("Atlas fixture smoke test passed")
