root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source(file.path(root, "R", "utils.R"))
source(file.path(root, "R", "html.R"))

bundle_helper <- file.path(root, "R", "atlas_bundle.R")
expect_file(bundle_helper)
source(bundle_helper)

triangle_scope <- atlas_run_scope("triangle_only")
expect_equal(triangle_scope$profile, "triangle_only", "TRIANGLE-only scope should identify its run profile.")
expect_equal(
  unlist(triangle_scope$executed_panels, use.names = FALSE),
  "mcl_triangle_feasibility",
  "TRIANGLE-only scope should execute only the MCL/TRIANGLE feasibility pane."
)
expect_false(triangle_scope$source_profiling_executed, "TRIANGLE-only scope must not claim that 64-source profiling executed.")

full_scope <- atlas_run_scope("full_atlas")
expect_equal(unlist(full_scope$executed_panels, use.names = FALSE), "*", "Full-atlas scope should execute every pane.")
expect_true(full_scope$source_profiling_executed, "Full-atlas scope should identify source profiling as executed.")

scoped_payload <- atlas_scoped_panel_payload(
  run_id = "triangle-test",
  generated_at = "2026-07-14T00:00:00+0200",
  run_scope = triangle_scope,
  run_summary = data.frame(metric = "run_profile", value = "triangle_only", stringsAsFactors = FALSE),
  panel_payloads = list(
    mcl_triangle_feasibility = list(
      summary = data.frame(metric = "panel_status", value = "readiness available", stringsAsFactors = FALSE)
    )
  )
)
expect_true("mcl_triangle_feasibility" %in% names(scoped_payload), "Scoped payload should carry its named panel component.")
expect_false("hero_metrics" %in% names(scoped_payload), "Scoped payload must not fabricate ordinary-atlas hero metrics.")
expect_false("source_count" %in% names(scoped_payload), "Scoped payload must not claim a zero source count when profiling did not run.")

source_test_runtime(root)
expect_true(
  exists("mcl_triangle_build_atlas_panel", mode = "function"),
  "The readiness and aggregate routes should be combined by a shared MCL/TRIANGLE panel builder."
)
panel <- mcl_triangle_build_atlas_panel(
  project_root = root,
  db_adapter = NULL,
  mode = "plan",
  min_cell_count = 5L,
  scaffold_args = list(ki67_discovery = ki67_empty_payload()),
  count_args = list(outputs_dir = tempfile("mcl-triangle-panel-plan-"))
)
expect_true(all(c("summary", "study_readiness_matrix", "cohort_counts") %in% names(panel)), "Shared panel should carry readiness and count components.")
expect_true(is.data.frame(panel$cohort_counts$execution_summary), "Shared panel should expose current-run count execution metadata.")
expect_true(
  any(panel$cohort_counts$data_point_counts$count_status == "query_executable_not_run") &&
    !any(panel$cohort_counts$data_point_counts$count_status %in% mcl_count_available_statuses()),
  "Plan-mode panel counts should remain explicitly not run or blocked by readiness mappings, never available."
)
expect_false(
  any(c("definitions", "query_templates", "person_date_mapping", "value_mappings", "treatment_code_mappings") %in% names(panel$cohort_counts)),
  "Public panel payload must exclude internal definitions, SQL, and mapping tables."
)
expect_true(is.list(attr(panel, "count_outputs")), "Shared panel should retain internal count outputs only as a transient writer attribute.")

runner <- file.path(root, "RUN_MCL_TRIANGLE_COUNTS.R")
sourceable <- file.path(root, "scripts", "source_mcl_triangle_counts.R")
runner_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
sourceable_text <- paste(readLines(sourceable, warn = FALSE), collapse = "\n")
combined_text <- paste(runner_text, sourceable_text, collapse = "\n")
full_runner_text <- paste(readLines(file.path(root, "R", "run_atlas.R"), warn = FALSE), collapse = "\n")
full_sourceable_text <- paste(readLines(file.path(root, "scripts", "run_atlas.R"), warn = FALSE), collapse = "\n")
expect_false(grepl("RUN_DALYCARE_ATLAS|scripts/run_atlas[.]R|R/run_atlas[.]R", combined_text, ignore.case = TRUE), "TRIANGLE-only runner must not source the full atlas runner.")
expect_false(grepl('file.path("R", "profiler.R")', sourceable_text, fixed = TRUE), "TRIANGLE-only runner must not source the 64-source profiler.")
expect_true(grepl("mcl_triangle_build_atlas_panel", sourceable_text, fixed = TRUE), "TRIANGLE-only sourceable should use the shared panel builder.")
expect_true(grepl("atlas_write_bundle", sourceable_text, fixed = TRUE), "TRIANGLE-only sourceable should use the shared bundle writer.")
expect_true(grepl("mcl_triangle_build_atlas_panel", full_runner_text, fixed = TRUE), "Full runner should use the same MCL/TRIANGLE panel builder.")
expect_false(grepl("mcl_count_resolve_standalone_output_source", full_runner_text, fixed = TRUE), "Full runner must pass current-run rows directly instead of rediscovering them through the standalone resolver.")
expect_true(grepl('atlas_run_scope("full_atlas")', full_runner_text, fixed = TRUE), "Full runner should identify full-atlas scope.")
expect_true(grepl('file.path(project_root, "R", "atlas_bundle.R")', full_sourceable_text, fixed = TRUE), "Full sourceable should load shared bundle definitions.")
expect_true(grepl("MCL_COUNT_OUTPUTS_DIR is deprecated", sourceable_text, fixed = TRUE), "Legacy output-directory alias should emit a clear warning.")

old_config_exists <- exists(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
old_config <- if (old_config_exists) get(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE) else NULL
old_result_exists <- exists("MCL_TRIANGLE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)
old_result <- if (old_result_exists) get("MCL_TRIANGLE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE) else NULL
old_profile_exists <- exists("profile_source", envir = .GlobalEnv, inherits = FALSE)
old_profile <- if (old_profile_exists) get("profile_source", envir = .GlobalEnv, inherits = FALSE) else NULL
assign("profile_source", function(...) stop("64-source profiler must not run in TRIANGLE-only mode"), envir = .GlobalEnv)
on.exit({
  if (old_config_exists) {
    assign(".MCL_COUNT_SOURCE_CONFIG", old_config, envir = .GlobalEnv)
  } else if (exists(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".MCL_COUNT_SOURCE_CONFIG", envir = .GlobalEnv)
  }
  if (old_result_exists) {
    assign("MCL_TRIANGLE_COUNT_RESULT", old_result, envir = .GlobalEnv)
  } else if (exists("MCL_TRIANGLE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)) {
    rm("MCL_TRIANGLE_COUNT_RESULT", envir = .GlobalEnv)
  }
  if (old_profile_exists) {
    assign("profile_source", old_profile, envir = .GlobalEnv)
  } else if (exists("profile_source", envir = .GlobalEnv, inherits = FALSE)) {
    rm("profile_source", envir = .GlobalEnv)
  }
}, add = TRUE)

run_triangle_sourceable <- function(config) {
  assign(".MCL_COUNT_SOURCE_CONFIG", config, envir = .GlobalEnv)
  console <- capture.output(sys.source(sourceable, envir = new.env(parent = globalenv())))
  result <- get("MCL_TRIANGLE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)
  attr(result, "console") <- console
  result
}

plan_root <- tempfile("mcl-triangle-one-click-plan-")
plan_result <- run_triangle_sourceable(list(
  MCL_COUNT_MODE = "plan",
  MCL_COUNT_PROJECT_ROOT = root,
  MCL_COUNT_OUTPUT_ROOT = plan_root,
  MCL_COUNT_OUTPUTS_DIR = "",
  MCL_COUNT_SMALL_CELL_N = 5L,
  MCL_COUNT_UPDATE_PAYLOAD = FALSE,
  MCL_TRIANGLE_ATLAS_OUTPUT_DIR = "",
  MCL_TRIANGLE_ATLAS_OUTPUT_ZIP = "",
  MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY = TRUE,
  MCL_TRIANGLE_KI67_TEXT_SCAN = FALSE,
  MCL_TRIANGLE_KI67_THRESHOLD_PERCENT = 30L,
  MCL_COUNT_DB_ADAPTER = NULL
))
expect_true(
  is.list(plan_result) && all(c("run_id", "run_dir", "outputs", "paths", "html", "payload", "manifest") %in% names(plan_result)),
  "TRIANGLE-only result should expose the canonical atlas bundle and panel outputs."
)
expect_true(dir.exists(plan_result$run_dir), "TRIANGLE-only runner should create a timestamped run directory.")
expect_equal(dirname(plan_result$paths$summary), file.path(plan_result$run_dir, "outputs"), "TRIANGLE readiness CSVs should use the canonical outputs directory.")
expect_file(plan_result$html)
expect_file(plan_result$payload)
expect_file(plan_result$manifest)
expect_file(file.path(plan_result$run_dir, "logs", "atlas_execution_log.tsv"))
expect_true(grepl("MCL_COUNT_UPDATE_PAYLOAD is deprecated and ignored", paste(attr(plan_result, "console"), collapse = "\n"), fixed = TRUE), "Supplying the deprecated payload flag should warn even when its value is FALSE.")
expect_true("small_cell_suppression_audit" %in% names(plan_result$paths), "Scoped bundle should publish its safe suppression audit.")
expect_file(plan_result$paths$small_cell_suppression_audit)
expect_true("small_cell_suppression_audit" %in% names(plan_result$outputs$cohort_counts), "Scoped panel payload should carry the same suppression audit.")
payload_text <- paste(readLines(plan_result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl('"profile":"triangle_only"', payload_text, fixed = TRUE), "Scoped payload should identify TRIANGLE-only scope.")
expect_true(grepl('"executed_panels":["mcl_triangle_feasibility"]', payload_text, fixed = TRUE), "Scoped payload should identify its only executed pane.")
expect_false(grepl('"hero_metrics"', payload_text, fixed = TRUE), "Scoped payload must not manufacture ordinary-atlas hero metrics.")
expect_true(grepl('"cohort_counts"', payload_text, fixed = TRUE), "Scoped payload should include current-run cohort-count rows.")
run_summary <- read.csv(plan_result$paths$run_summary, stringsAsFactors = FALSE, check.names = FALSE)
expect_true(all(c(
  "run_profile", "executed_panel", "source_profiling_executed", "mode",
  "production_query_attempted", "production_query_success", "failed_query_count",
  "suppression_threshold", "optional_atlas_evidence_input"
) %in% run_summary$metric), "Scoped run summary should record execution, privacy, and evidence-input truth fields.")
run_log <- paste(readLines(file.path(plan_result$run_dir, "logs", "atlas_execution_log.tsv"), warn = FALSE), collapse = "\n")
for (field in c(
  "run_profile=triangle_only", "executed_panel=mcl_triangle_feasibility",
  "source_profiling_executed=FALSE", "mode=plan", "suppression_threshold=5"
)) {
  expect_true(grepl(field, run_log, fixed = TRUE), paste("Scoped execution log should record:", field))
}

fake_people <- paste0("patient-raw-", sprintf("%03d", 1:12))
fake_sets <- list(
  all_lyfo_mcl = fake_people,
  younger_mcl_proxy_age_le_65 = fake_people[1:9],
  diagnosis_date = fake_people,
  first_line_treatment_date = fake_people[1:10],
  cit_immunochemotherapy = fake_people[c(1:8, 11)],
  asct_hdt_first_line = fake_people[c(1:6, 10)],
  asct_hdt_relapse_recurrence = fake_people[c(9:11)],
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
fake_adapter <- list(
  mcl_triangle_count_sets = function(min_cell_count = 5L) list(sets = fake_sets)
)
production_root <- tempfile("mcl-triangle-one-click-production-")
production_result <- run_triangle_sourceable(list(
  MCL_COUNT_MODE = "production_aggregate",
  MCL_COUNT_PROJECT_ROOT = root,
  MCL_COUNT_OUTPUT_ROOT = production_root,
  MCL_COUNT_OUTPUTS_DIR = "",
  MCL_COUNT_SMALL_CELL_N = 5L,
  MCL_COUNT_UPDATE_PAYLOAD = FALSE,
  MCL_TRIANGLE_ATLAS_OUTPUT_DIR = "",
  MCL_TRIANGLE_ATLAS_OUTPUT_ZIP = "",
  MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY = FALSE,
  MCL_TRIANGLE_KI67_TEXT_SCAN = FALSE,
  MCL_TRIANGLE_KI67_THRESHOLD_PERCENT = 30L,
  MCL_COUNT_DB_ADAPTER = fake_adapter
))
production_counts <- production_result$outputs$cohort_counts$data_point_counts
all_mcl <- production_counts[production_counts$data_point_id == "all_lyfo_mcl", , drop = FALSE]
expect_equal(all_mcl$distinct_person_count_display[[1]], "12", "Scoped production runner should publish the executed all-MCL aggregate.")
expect_true(all_mcl$count_status[[1]] %in% mcl_count_available_statuses(), "Executed all-MCL aggregate should carry an available count status.")
expect_equal(production_result$outputs$cohort_counts$execution_summary$mode[[1]], "production_aggregate", "Scoped production runner should record production aggregate mode.")
expect_true(production_result$outputs$cohort_counts$execution_summary$db_connection_attempted[[1]], "Scoped production runner should record its database-adapter attempt.")
expect_file(production_result$paths$data_point_counts)
persisted_paths <- list.files(production_result$run_dir, recursive = TRUE, full.names = TRUE)
persisted_paths <- persisted_paths[file.info(persisted_paths)$isdir %in% FALSE]
persisted_text <- paste(vapply(persisted_paths, function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("patient-raw-", persisted_text, fixed = TRUE), "Canonical TRIANGLE artifacts must not persist fake patient identifiers used by the aggregate adapter.")
expect_true(grepl("Not run in this TRIANGLE-only atlas", paste(readLines(production_result$html, warn = FALSE), collapse = "\n"), fixed = TRUE), "Scoped HTML should contain the exact not-run truth label for every other pane.")

failure_root <- tempfile("mcl-triangle-one-click-failure-")
failure_result <- run_triangle_sourceable(list(
  MCL_COUNT_MODE = "production_aggregate",
  MCL_COUNT_PROJECT_ROOT = root,
  MCL_COUNT_OUTPUT_ROOT = failure_root,
  MCL_COUNT_OUTPUTS_DIR = "",
  MCL_COUNT_SMALL_CELL_N = 5L,
  MCL_COUNT_UPDATE_PAYLOAD = FALSE,
  MCL_TRIANGLE_ATLAS_OUTPUT_DIR = "",
  MCL_TRIANGLE_ATLAS_OUTPUT_ZIP = "",
  MCL_TRIANGLE_RUN_KI67_SOURCE_INVENTORY = FALSE,
  MCL_TRIANGLE_KI67_TEXT_SCAN = FALSE,
  MCL_TRIANGLE_KI67_THRESHOLD_PERCENT = 30L,
  MCL_COUNT_DB_ADAPTER = list(
    mcl_triangle_count_sets = function(min_cell_count = 5L) stop("token=bundle-secret patient=1234567890")
  )
))
expect_file(failure_result$html)
expect_file(failure_result$payload)
expect_file(failure_result$manifest)
failure_counts <- failure_result$outputs$cohort_counts$data_point_counts
expect_false(any(failure_counts$count_status %in% mcl_count_available_statuses()), "Failed production adapter must not yield available or provisional counts in the scoped atlas.")
expect_true(any(failure_counts$count_status == "production_aggregate_failed_query_error"), "Failed production adapter should remain an explicit failed-query state.")
failure_payload_text <- paste(readLines(failure_result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl("<redacted>", failure_payload_text, fixed = TRUE), "Diagnostic scoped atlas should retain a sanitized failure audit.")
expect_false(grepl("bundle-secret|1234567890", failure_payload_text, perl = TRUE), "Diagnostic scoped atlas must not expose credentials or patient-like identifiers.")

cat("MCL/TRIANGLE shared bundle contract tests passed\n")
