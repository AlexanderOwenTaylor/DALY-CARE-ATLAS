root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

fake_people <- paste0("fixture-person-", 1:12)
fake_sets <- list(
  all_lyfo_mcl = fake_people,
  younger_mcl_proxy_age_le_65 = fake_people[1:9],
  diagnosis_date = fake_people,
  first_line_treatment_date = fake_people[1:10],
  cit_immunochemotherapy = fake_people[1:9],
  asct_hdt_first_line = fake_people[1:7],
  asct_hdt_relapse_recurrence = fake_people[9:11],
  ibrutinib_exposure = fake_people[2:6],
  os_death = fake_people[1:11],
  relapse_progression_ffs_proxy = fake_people[c(1:7, 12)],
  ki67_aeki = fake_people[c(1:6, 10)],
  tp53_p53_del17p = fake_people[c(1, 2, 5:7)],
  blastoid_pleomorphic_morphology = fake_people[3:5],
  mipi_mipic_components = fake_people[1:6],
  toxicity_proxies = fake_people[1:4],
  alive_at_landmark = fake_people[1:8],
  event_free_pre_landmark = fake_people[c(1:4, 6, 7)],
  asct_hdt_status_known_landmark = fake_people[1:7],
  ibrutinib_status_known_landmark = fake_people[2:8],
  high_risk_biology_pre_landmark = fake_people[1:5]
)
fake_adapter <- list(mcl_triangle_count_sets = function(min_cell_count = 1L) list(sets = fake_sets))

out_root <- tempfile("atlas_runs_")
result <- run_atlas(
  project_root = root,
  source_map_path = file.path(root, "config", "source-map.example.tsv"),
  output_root = out_root,
  mode = "report",
  db_adapter = fake_adapter
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
expect_true(grepl('"profile":"full_atlas"', payload_js, fixed = TRUE), "Full runner should identify full-atlas scope.")

full_counts <- read.csv(file.path(result$run_dir, "outputs", "mcl_triangle_data_point_counts.csv"), stringsAsFactors = FALSE, check.names = FALSE)
direct_panel <- mcl_triangle_build_atlas_panel(
  project_root = root,
  db_adapter = fake_adapter,
  mode = "production_aggregate",
  min_cell_count = 1L,
  scaffold_args = list(ki67_discovery = ki67_empty_payload()),
  count_args = list(outputs_dir = tempfile("mcl-triangle-direct-parity-"), run_ki67_source_inventory = FALSE)
)
direct_counts <- direct_panel$cohort_counts$data_point_counts
comparison_columns <- c("data_point_id", "distinct_person_count_display", "count_status", "acceptance_status", "suppression_status")
full_comparison <- full_counts[order(full_counts$data_point_id), comparison_columns, drop = FALSE]
direct_comparison <- direct_counts[order(direct_counts$data_point_id), comparison_columns, drop = FALSE]
full_comparison[] <- lapply(full_comparison, as.character)
direct_comparison[] <- lapply(direct_comparison, as.character)
full_comparison[is.na(full_comparison)] <- ""
direct_comparison[is.na(direct_comparison)] <- ""
rownames(full_comparison) <- NULL
rownames(direct_comparison) <- NULL
expect_equal(full_comparison, direct_comparison, "Full and TRIANGLE-only panel paths should publish identical canonical aggregate rows for the same adapter.")
persisted_text <- paste(vapply(
  list.files(result$run_dir, recursive = TRUE, full.names = TRUE),
  function(path) if (dir.exists(path)) "" else paste(readLines(path, warn = FALSE), collapse = "\n"),
  character(1)
), collapse = "\n")
expect_false(grepl("fixture-person-", persisted_text, fixed = TRUE), "Full-atlas public artifacts must not persist aggregate-adapter person identifiers.")

manifest <- read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE)
manifest_text <- paste(unlist(manifest), collapse = "\n")
expect_true(grepl("DALYCARE_atlas.html", manifest_text, fixed = TRUE), "Manifest should include the HTML artifact.")
expect_true(grepl("DALYCARE_atlas_payload.js", manifest_text, fixed = TRUE), "Manifest should include the payload artifact.")

message("Atlas fixture smoke test passed")
