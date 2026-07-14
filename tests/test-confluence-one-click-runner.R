root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

runner <- file.path(root, "RUN_CONFLUENCE_COUNTS.R")
sourceable <- file.path(root, "scripts", "source_confluence_counts.R")
bundle_helper <- file.path(root, "R", "atlas_bundle.R")
expect_file(runner)
expect_file(sourceable)
expect_file(bundle_helper)
source(bundle_helper)

confluence_scope <- atlas_run_scope("confluence_only")
expect_equal(confluence_scope$profile, "confluence_only", "Panel-only scope should identify the CONFLUENCE-only profile.")
expect_equal(unlist(confluence_scope$executed_panels, use.names = FALSE), "confluence_feasibility", "Panel-only scope should execute only the CONFLUENCE pane.")
expect_false(confluence_scope$source_profiling_executed, "Panel-only scope must not claim that 64-source profiling executed.")

full_scope <- atlas_run_scope("full_atlas")
expect_equal(unlist(full_scope$executed_panels, use.names = FALSE), "*", "Full-atlas scope should permit every atlas pane.")
expect_true(full_scope$source_profiling_executed, "Full-atlas scope should identify source profiling as executed.")

runner_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
sourceable_text <- paste(readLines(sourceable, warn = FALSE), collapse = "\n")
combined <- paste(runner_text, sourceable_text, collapse = "\n")
full_runner_text <- paste(readLines(file.path(root, "R", "run_atlas.R"), warn = FALSE), collapse = "\n")
full_sourceable_text <- paste(readLines(file.path(root, "scripts", "run_atlas.R"), warn = FALSE), collapse = "\n")
expect_false(grepl("RUN_DALYCARE_ATLAS|scripts/run_atlas[.]R|R/run_atlas[.]R", combined, ignore.case = TRUE), "One-click CONFLUENCE runner must not source the full atlas runner.")
expect_false(grepl('file.path("R", "profiler.R")', sourceable_text, fixed = TRUE), "One-click CONFLUENCE runner must not source the 64-source profiler.")
expect_true(grepl("confluence_build_atlas_panel", sourceable_text, fixed = TRUE), "CONFLUENCE sourceable should use the shared atlas-panel builder.")
expect_true(grepl("confluence_write_outputs", sourceable_text, fixed = TRUE), "CONFLUENCE sourceable should write the mini-bundle CSVs.")
expect_true(grepl("confluence_build_atlas_panel", full_runner_text, fixed = TRUE), "Full atlas runner should use the shared CONFLUENCE panel builder.")
expect_true(grepl('atlas_run_scope("full_atlas")', full_runner_text, fixed = TRUE), "Full atlas payload should identify full-atlas scope.")
expect_true(grepl("atlas_panel_run_summary", full_runner_text, fixed = TRUE), "Full atlas run summary should use the shared scope/query/privacy summary helper.")
expect_true(grepl("suppression_threshold=", full_runner_text, fixed = TRUE), "Full atlas execution log should record its publication suppression threshold.")
expect_true(grepl("atlas_write_bundle", full_runner_text, fixed = TRUE), "Full atlas runner should use the shared bundle writer.")
expect_true(grepl('file.path(project_root, "R", "atlas_bundle.R")', full_sourceable_text, fixed = TRUE), "Full sourceable should load the shared bundle definitions.")
expect_false(grepl("output_manifest_artifact_metadata <- function", full_runner_text, fixed = TRUE), "Manifest logic should live only in the shared bundle module.")
expect_true(grepl("CONFLUENCE_COUNT_OUTPUTS_DIR is deprecated", sourceable_text, fixed = TRUE), "Legacy output-directory alias should emit a clear deprecation warning.")

old_config_exists <- exists(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
old_config <- if (old_config_exists) get(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE) else NULL
old_result_exists <- exists("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)
old_result <- if (old_result_exists) get("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE) else NULL
old_profile_source_exists <- exists("profile_source", envir = .GlobalEnv, inherits = FALSE)
old_profile_source <- if (old_profile_source_exists) get("profile_source", envir = .GlobalEnv, inherits = FALSE) else NULL
assign("profile_source", function(...) stop("64-source profiler must not run in CONFLUENCE-only mode"), envir = .GlobalEnv)
on.exit({
  if (old_config_exists) {
    assign(".CONFLUENCE_COUNT_SOURCE_CONFIG", old_config, envir = .GlobalEnv)
  } else if (exists(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)) {
    rm(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv)
  }
  if (old_result_exists) {
    assign("CONFLUENCE_COUNT_RESULT", old_result, envir = .GlobalEnv)
  } else if (exists("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)) {
    rm("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv)
  }
  if (old_profile_source_exists) {
    assign("profile_source", old_profile_source, envir = .GlobalEnv)
  } else if (exists("profile_source", envir = .GlobalEnv, inherits = FALSE)) {
    rm("profile_source", envir = .GlobalEnv)
  }
}, add = TRUE)

run_confluence_sourceable <- function(config) {
  assign(".CONFLUENCE_COUNT_SOURCE_CONFIG", config, envir = .GlobalEnv)
  capture.output(sys.source(sourceable, envir = new.env(parent = globalenv())))
  get("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)
}

plan_dir <- tempfile("confluence-one-click-plan-")
plan_result <- run_confluence_sourceable(list(
  CONFLUENCE_COUNT_MODE = "plan",
  CONFLUENCE_COUNT_PROJECT_ROOT = root,
  CONFLUENCE_COUNT_OUTPUT_ROOT = plan_dir,
  CONFLUENCE_COUNT_OUTPUTS_DIR = plan_dir,
  CONFLUENCE_COUNT_SMALL_CELL_N = 5L,
  CONFLUENCE_COUNT_UPDATE_PAYLOAD = FALSE,
  CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR = "",
  CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP = ""
))

expect_true(
  is.list(plan_result) && all(c("run_id", "run_dir", "outputs", "paths", "html", "payload", "manifest") %in% names(plan_result)),
  "CONFLUENCE one-click result should expose the canonical atlas bundle and its aggregate outputs."
)
expect_true(dir.exists(plan_result$run_dir), "CONFLUENCE one-click runner should create a timestamped run directory.")
expect_equal(dirname(plan_result$paths$summary), file.path(plan_result$run_dir, "outputs"), "CONFLUENCE CSVs should live in the canonical outputs directory.")
expect_file(plan_result$html)
expect_file(plan_result$payload)
expect_file(plan_result$manifest)
expect_file(file.path(plan_result$run_dir, "logs", "atlas_execution_log.tsv"))
plan_payload_text <- paste(readLines(plan_result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl('"profile":"confluence_only"', plan_payload_text, fixed = TRUE), "Panel-only payload should identify its run scope.")
expect_true(grepl('"executed_panels":["confluence_feasibility"]', plan_payload_text, fixed = TRUE), "Panel-only payload should identify CONFLUENCE as its only executed pane.")
expect_false(grepl('"executed_panels":["*"]', plan_payload_text, fixed = TRUE), "Panel-only payload must not claim that every pane executed.")
expect_false(grepl('"hero_metrics"', plan_payload_text, fixed = TRUE), "Panel-only payload must not manufacture ordinary-atlas zero hero metrics for work that did not run.")
expect_false(grepl('"review_overview"', plan_payload_text, fixed = TRUE), "Panel-only payload must not manufacture an ordinary-atlas review model for work that did not run.")
expect_false(grepl('"source_count":0', plan_payload_text, fixed = TRUE), "Panel-only payload must omit a misleading zero source count when source profiling did not run.")
plan_manifest <- read.csv(plan_result$manifest, stringsAsFactors = FALSE, check.names = FALSE)
expect_true(all(c("html", "payload") %in% plan_manifest$artifact_id), "Panel-only manifest should include the offline HTML and payload.")
plan_run_summary <- read.csv(plan_result$paths$run_summary, stringsAsFactors = FALSE, check.names = FALSE)
expect_true(all(c(
  "run_profile", "executed_panel", "source_profiling_executed",
  "production_query_attempted", "production_query_success", "failed_query_count",
  "suppression_threshold"
) %in% plan_run_summary$metric), "Panel-only run summary should record scope, query, failure, and privacy truth fields.")
plan_log <- paste(readLines(file.path(plan_result$run_dir, "logs", "atlas_execution_log.tsv"), warn = FALSE), collapse = "\n")
for (field in c(
  "run_profile=confluence_only", "executed_panel=confluence_feasibility",
  "source_profiling_executed=FALSE", "attempted=FALSE", "success=FALSE",
  "failed_queries=", "suppression_threshold=5"
)) {
  expect_true(grepl(field, plan_log, fixed = TRUE), paste("Panel-only execution log should record:", field))
}
for (name in c(
  "summary",
  "story_cards",
  "evidence_spine",
  "overlap_signal_summary",
  "ingredient_map",
  "protocol_runway",
  "clone_route_manifest",
  "clone_source_resolution",
  "bcell_clone_evidence_counts",
  "pcd_clone_evidence_counts",
  "paraprotein_ambiguity_counts",
  "mgus_reclassification_waterfall",
  "dual_clone_overlap_counts",
  "dual_clone_overlap_timing",
  "primary_overlap_exclusion_reasons",
  "clone_availability_protocol_runway",
  "disease_state_counts",
  "overlap_counts_accepted",
  "infection_endpoint_code_sets",
  "infection_counts",
  "infection_person_time",
  "infection_rates",
  "microbiology_confirmation_source_audit",
  "production_execution_summary",
  "failed_query_audit",
  "source_resolution_audit"
)) {
  expect_true(name %in% names(plan_result$paths), paste("Plan-mode CONFLUENCE mini-bundle should write:", name))
  expect_file(plan_result$paths[[name]])
}
expect_true(any(plan_result$outputs$production_execution_summary$value == "plan"), "Default plan mode should remain fail-closed/no-DB.")
expect_true(all(plan_result$outputs$overlap_counts_accepted$acceptance_status != "accepted"), "Plan mode should not accept overlap counts.")
expect_true(any(plan_result$outputs$failed_query_audit$count_status == "query executable not run"), "Plan mode should retain not-run failed-query audit rows.")
expect_true(
  all(plan_result$outputs$production_execution_summary$value[plan_result$outputs$production_execution_summary$metric %in% c("first_date_state_rows", "infection_event_rows_internal")] == "not run"),
  "Plan mode must label unavailable runtime diagnostics as not run instead of publishing plausible zero counts."
)

private_runtime_summary <- confluence_count_execution_summary(
  mode = "production_aggregate",
  attempted = TRUE,
  success = TRUE,
  first_dates = data.frame(row = seq_len(3L)),
  infection_events = data.frame(row = seq_len(2L)),
  min_cell_count = 5L
)
expect_true(
  all(private_runtime_summary$value[private_runtime_summary$metric %in% c("first_date_state_rows", "infection_event_rows_internal")] == "<5"),
  "Small secure-runtime diagnostic row counts must be suppressed before the execution summary becomes public."
)
expect_true(
  all(private_runtime_summary$status[private_runtime_summary$metric %in% c("first_date_state_rows", "infection_event_rows_internal")] == "suppressed small cell"),
  "Suppressed secure-runtime diagnostics should carry an explicit suppression status."
)

privacy_parent <- data.frame(
  overlap_id = "accepted_dual_clone_overlap",
  overlap_label = "Accepted dual-clone overlap",
  count_display = "24",
  n_people = 24,
  acceptance_status = "accepted",
  query_status = "executed",
  suppression_status = "not suppressed",
  stringsAsFactors = FALSE
)
privacy_timing <- data.frame(
  timing_id = c("same_90_day_window", "bcell_first", "pcd_first"),
  timing_label = c("same 90 day window", "bcell first", "pcd first"),
  classification_id = "accepted_dual_clone_overlap",
  bcell_entry_route_id = "bcell_route",
  pcd_entry_route_id = "pcd_route",
  count_display = c("<6", "11", "8"),
  n_people = c(NA_real_, 11, 8),
  acceptance_status = "accepted",
  query_status = "executed",
  suppression_status = c("suppressed small cell", "not suppressed", "not suppressed"),
  stringsAsFactors = FALSE
)
privacy_outputs <- list(
  dual_clone_overlap_counts = privacy_parent,
  overlap_counts_accepted = privacy_parent,
  overlap_counts = privacy_parent,
  dual_clone_overlap_timing = privacy_timing,
  overlap_timing_accepted = privacy_timing,
  overlap_timing = privacy_timing,
  small_cell_suppression_audit = confluence_empty_small_cell_suppression_audit()
)
privacy_repaired <- confluence_apply_public_suppression(privacy_outputs, min_cell_count = 6L)
expect_true(
  is.na(privacy_repaired$dual_clone_overlap_timing$n_people[privacy_repaired$dual_clone_overlap_timing$timing_id == "pcd_first"]),
  "Complementary privacy should suppress the smallest eligible visible timing sibling."
)
expect_equal(
  privacy_repaired$dual_clone_overlap_timing$count_display[privacy_repaired$dual_clone_overlap_timing$timing_id == "pcd_first"],
  "suppressed for complementary privacy",
  "Complementary suppression should use an explicit public truth label."
)
expect_equal(
  privacy_repaired$dual_clone_overlap_counts$n_people[privacy_repaired$dual_clone_overlap_counts$overlap_id == "accepted_dual_clone_overlap"],
  24,
  "Complementary privacy should retain the parent total when an eligible sibling can be hidden."
)
expect_true(
  all(is.na(privacy_repaired$overlap_timing_accepted$n_people[privacy_repaired$overlap_timing_accepted$timing_id == "pcd_first"])),
  "Canonical timing mirrors must not retain the complementary cell."
)
complementary_audit <- privacy_repaired$small_cell_suppression_audit[
  privacy_repaired$small_cell_suppression_audit$suppression_status == "suppressed complementary cell",
  ,
  drop = FALSE
]
expect_equal(nrow(complementary_audit), 1L, "Complementary suppression should append one deterministic audit row.")
expect_true(all(complementary_audit$raw_count_available == "no raw count emitted"), "Complementary suppression audit must not record the hidden value.")
expect_false(grepl("(^|[^0-9])8([^0-9]|$)", paste(unlist(complementary_audit), collapse = " ")), "Complementary suppression audit must not leak the hidden sibling count.")

privacy_no_sibling <- privacy_outputs
privacy_no_sibling$dual_clone_overlap_counts$n_people <- 8
privacy_no_sibling$dual_clone_overlap_counts$count_display <- "8"
privacy_no_sibling$overlap_counts_accepted <- privacy_no_sibling$dual_clone_overlap_counts
privacy_no_sibling$overlap_counts <- privacy_no_sibling$dual_clone_overlap_counts
privacy_no_sibling$dual_clone_overlap_timing$n_people <- NA_real_
privacy_no_sibling$dual_clone_overlap_timing$count_display <- "<6"
privacy_no_sibling$dual_clone_overlap_timing$suppression_status <- "suppressed small cell"
privacy_no_sibling$overlap_timing_accepted <- privacy_no_sibling$dual_clone_overlap_timing
privacy_no_sibling$overlap_timing <- privacy_no_sibling$dual_clone_overlap_timing
privacy_parent_repaired <- confluence_apply_public_suppression(privacy_no_sibling, min_cell_count = 6L)
expect_true(
  is.na(privacy_parent_repaired$dual_clone_overlap_counts$n_people[privacy_parent_repaired$dual_clone_overlap_counts$overlap_id == "accepted_dual_clone_overlap"]),
  "Complementary privacy should suppress the parent when no eligible visible sibling exists."
)
expect_equal(
  privacy_parent_repaired$overlap_counts_accepted$count_display[privacy_parent_repaired$overlap_counts_accepted$overlap_id == "accepted_dual_clone_overlap"],
  "suppressed for complementary privacy",
  "Parent suppression should propagate to the canonical accepted-count mirror."
)

fake_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) {
    list(
      patient_frame = data.frame(
        person_key = sprintf("p%02d", 1:12),
        date_death_fu = rep(NA, 12),
        stringsAsFactors = FALSE
      ),
      disease_first_dates = data.frame(
        person_key = c(
          "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08",
          "p01", "p02", "p03", "p04", "p05", "p06",
          "p01", "p02", "p03", "p04", "p05",
          "p09", "p10", "p11", "p12"
        ),
        state_id = c(
          rep("cll", 8),
          rep("mgus", 6),
          rep("coded_mbl", 5),
          rep("mm", 4)
        ),
        first_date = as.Date(c(
          rep("2020-01-01", 8),
          rep("2020-06-01", 6),
          rep("2019-03-01", 5),
          rep("2021-01-15", 4)
        )),
        stringsAsFactors = FALSE
      ),
      clone_evidence = data.frame(
        person_key = c(sprintf("p%02d", 1:8), sprintf("p%02d", 1:8)),
        route_id = c(rep("bcell_diag_cll_icd_c911", 8), rep("pcd_damyda_clonal_pc_percent", 8)),
        evidence_date = as.Date(c(rep("2020-01-01", 8), rep("2020-06-01", 8))),
        stringsAsFactors = FALSE
      ),
      infection_events = data.frame(
        person_key = c("p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p09", "p10"),
        event_date = as.Date(c("2020-07-01", "2020-07-02", "2020-07-03", "2020-07-04", "2020-07-05", "2020-07-06", "2020-07-07", "2020-07-08", "2021-02-01", "2021-02-02")),
        endpoint_id = "serious_infection_hospitalization",
        stringsAsFactors = FALSE
      )
    )
  }
)

prod_dir <- tempfile("confluence-one-click-production-")
prod_result <- run_confluence_sourceable(list(
  CONFLUENCE_COUNT_MODE = "production_aggregate",
  CONFLUENCE_COUNT_PROJECT_ROOT = root,
  CONFLUENCE_COUNT_OUTPUTS_DIR = prod_dir,
  CONFLUENCE_COUNT_SMALL_CELL_N = 5L,
  CONFLUENCE_COUNT_UPDATE_PAYLOAD = FALSE,
  CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR = "",
  CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP = "",
  CONFLUENCE_COUNT_DB_ADAPTER = fake_adapter
))

shared_panel <- confluence_build_atlas_panel(
  project_root = root,
  db_adapter = fake_adapter,
  mode = "production_aggregate",
  min_cell_count = 5L,
  scaffold_args = list()
)
expect_equal(
  shared_panel$overlap_counts_accepted,
  prod_result$outputs$overlap_counts_accepted,
  "Shared CONFLUENCE panel builder should reproduce the one-click canonical overlap output."
)
expect_equal(
  shared_panel$production_execution_summary,
  prod_result$outputs$production_execution_summary,
  "Shared CONFLUENCE panel builder should reproduce the one-click execution summary."
)

expect_true(any(prod_result$outputs$production_execution_summary$metric == "production_query_success" & prod_result$outputs$production_execution_summary$value == "TRUE"), "Fake production adapter should populate CONFLUENCE production execution summary.")
expect_true(any(prod_result$outputs$overlap_counts_accepted$overlap_id == "accepted_dual_clone_overlap" & prod_result$outputs$overlap_counts_accepted$count_display == "8" & prod_result$outputs$overlap_counts_accepted$acceptance_status == "accepted"), "Fake production adapter should produce a nonzero accepted dual-clone overlap row.")
expect_true(any(prod_result$outputs$infection_person_time$acceptance_status == "accepted"), "Fake production adapter should produce accepted person-time rows.")
expect_true(any(prod_result$outputs$infection_counts$endpoint_definition_status == "repo-derived provisional"), "Fake production adapter should produce provisional infection endpoint aggregates.")

partial_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) {
    list(
      sets = fake_adapter$confluence_count_sets(min_cell_count = min_cell_count),
      errors = data.frame(
        component = "optional_partial_route",
        output_file = "confluence_production_execution_summary.csv",
        query_id = "optional_partial_route",
        count_status = "production_aggregate_failed_query_error",
        query_attempted = TRUE,
        query_success = FALSE,
        error_class = "production_aggregate_failed_query_error",
        error_message_sanitized = "password=hunter2 id 1234567890 date 2020-01-01",
        notes = "password=hunter2 id 1234567890 date 2020-01-01",
        sensitive_extra = "must be dropped",
        stringsAsFactors = FALSE
      )
    )
  }
)
partial_dir <- tempfile("confluence-one-click-partial-production-")
partial_result <- run_confluence_sourceable(list(
  CONFLUENCE_COUNT_MODE = "production_aggregate",
  CONFLUENCE_COUNT_PROJECT_ROOT = root,
  CONFLUENCE_COUNT_OUTPUT_ROOT = partial_dir,
  CONFLUENCE_COUNT_SMALL_CELL_N = 5L,
  CONFLUENCE_COUNT_DB_ADAPTER = partial_adapter
))
partial_audit_text <- paste(unlist(partial_result$outputs$failed_query_audit, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("hunter2|1234567890|2020-01-01|must be dropped", partial_audit_text), "Partial-success failure audits must sanitize secrets, identifiers, dates, and non-contract fields before publication.")
expect_true(grepl("<redacted>", partial_audit_text, fixed = TRUE), "Partial-success failure audits should retain a useful redaction marker.")
expect_equal(names(partial_result$outputs$failed_query_audit), names(confluence_count_empty_failed_query_audit()), "Partial-success failure audits should be normalized to the public contract schema.")

failed_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) stop("aggregate adapter unavailable")
)
failed_dir <- tempfile("confluence-one-click-failed-production-")
failed_result <- run_confluence_sourceable(list(
  CONFLUENCE_COUNT_MODE = "production_aggregate",
  CONFLUENCE_COUNT_PROJECT_ROOT = root,
  CONFLUENCE_COUNT_OUTPUT_ROOT = failed_dir,
  CONFLUENCE_COUNT_SMALL_CELL_N = 5L,
  CONFLUENCE_COUNT_DB_ADAPTER = failed_adapter
))
expect_file(failed_result$html)
expect_file(failed_result$payload)
expect_file(failed_result$manifest)
expect_true(
  any(failed_result$outputs$production_execution_summary$metric == "production_query_success" & failed_result$outputs$production_execution_summary$value == "FALSE"),
  "Unavailable production adapters should emit a diagnostic atlas that records query failure."
)
expect_false(
  any(failed_result$outputs$overlap_counts_accepted$acceptance_status == "accepted", na.rm = TRUE),
  "Unavailable production adapters must not fabricate accepted CONFLUENCE counts."
)
expect_true(nrow(failed_result$outputs$failed_query_audit) > 0L, "Unavailable production adapters should retain a public-safe failure audit.")
expect_true(
  any(failed_result$outputs$failed_query_audit$error_class == "production_aggregate_failed_query_error"),
  "A failing secure aggregate hook should preserve its query-error class in the public audit."
)
expect_true(
  any(grepl("aggregate adapter unavailable", failed_result$outputs$failed_query_audit$error_message_sanitized, fixed = TRUE)),
  "A failing secure aggregate hook should preserve its sanitized diagnostic instead of replacing it with a generic mapping failure."
)
expect_true(
  all(failed_result$outputs$production_execution_summary$value[failed_result$outputs$production_execution_summary$metric %in% c("first_date_state_rows", "infection_event_rows_internal")] == "not run"),
  "Failed production queries must label unavailable runtime diagnostics as not run instead of publishing plausible zero counts."
)

public_text <- paste(unlist(prod_result$outputs, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("\\bp[0-9]{2}\\b", public_text), "CONFLUENCE one-click public outputs must not emit fake patient identifiers.")
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", public_text), "CONFLUENCE one-click public outputs must not emit CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", public_text), "CONFLUENCE one-click public outputs must not emit raw dates.")
expect_false(grepl("raw pathology text|snippet|row preview", public_text, ignore.case = TRUE), "CONFLUENCE one-click public outputs must not emit raw free text/snippets/row previews.")

fake_patient_pattern <- paste0("\\b(", paste(sprintf("p%02d", 1:12), collapse = "|"), ")\\b")
public_artifact_paths <- unique(c(
  unlist(prod_result$paths, use.names = FALSE),
  prod_result$html,
  prod_result$payload,
  prod_result$manifest
))
public_data_artifact_paths <- setdiff(public_artifact_paths, prod_result$html)
public_artifact_text <- paste(vapply(public_data_artifact_paths[file.exists(public_data_artifact_paths)], function(path) {
  paste(readLines(path, warn = FALSE), collapse = "\n")
}, character(1)), collapse = "\n")
patient_leak_paths <- public_data_artifact_paths[vapply(public_data_artifact_paths, function(path) {
  file.exists(path) && grepl(fake_patient_pattern, paste(readLines(path, warn = FALSE), collapse = "\n"))
}, logical(1))]
expect_false(length(patient_leak_paths) > 0L, paste("Persisted CONFLUENCE public artifacts must not emit fake patient identifiers:", paste(basename(patient_leak_paths), collapse = ", ")))
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", public_artifact_text), "Persisted CONFLUENCE public artifacts must not emit CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", public_artifact_text), "Persisted CONFLUENCE public artifacts must not emit raw dates.")
expect_false(grepl("raw pathology text|snippet|row preview", public_artifact_text, ignore.case = TRUE), "Persisted CONFLUENCE public artifacts must not emit raw free text/snippets/row previews.")

partial_artifact_paths <- unique(c(
  unlist(partial_result$paths, use.names = FALSE),
  partial_result$payload,
  partial_result$manifest
))
partial_artifact_text <- paste(vapply(partial_artifact_paths[file.exists(partial_artifact_paths)], function(path) {
  paste(readLines(path, warn = FALSE), collapse = "\n")
}, character(1)), collapse = "\n")
expect_false(grepl("hunter2|1234567890|2020-01-01|must be dropped", partial_artifact_text), "Persisted partial-success artifacts must not contain raw hook secrets, identifiers, dates, or extra fields.")
offline_html_text <- paste(readLines(prod_result$html, warn = FALSE), collapse = "\n")
expect_false(grepl("window.DALYCARE_ATLAS_PAYLOAD =", offline_html_text, fixed = TRUE), "Offline HTML must not embed the payload or any aggregate-input values.")

bad_error <- tryCatch(
  {
    run_confluence_sourceable(list(
      CONFLUENCE_COUNT_MODE = "bad_mode",
      CONFLUENCE_COUNT_PROJECT_ROOT = root,
      CONFLUENCE_COUNT_OUTPUTS_DIR = tempfile("confluence-one-click-bad-"),
      CONFLUENCE_COUNT_SMALL_CELL_N = 5L
    ))
    NA_character_
  },
  error = function(e) conditionMessage(e)
)
expect_true(grepl("Unsupported CONFLUENCE_COUNT_MODE", bad_error, fixed = TRUE), "Unsupported CONFLUENCE_COUNT_MODE should fail with a clear message.")

cat("CONFLUENCE one-click runner tests passed\n")
