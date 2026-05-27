root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

runner <- file.path(root, "RUN_CONFLUENCE_COUNTS.R")
sourceable <- file.path(root, "scripts", "source_confluence_counts.R")
expect_file(runner)
expect_file(sourceable)

runner_text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
sourceable_text <- paste(readLines(sourceable, warn = FALSE), collapse = "\n")
combined <- paste(runner_text, sourceable_text, collapse = "\n")
expect_false(grepl("RUN_DALYCARE_ATLAS|scripts/run_atlas[.]R|R/run_atlas[.]R", combined, ignore.case = TRUE), "One-click CONFLUENCE runner must not source the full atlas runner.")
expect_true(grepl("build_confluence_feasibility_outputs", sourceable_text, fixed = TRUE), "CONFLUENCE sourceable should build scaffold/readiness outputs.")
expect_true(grepl("confluence_count_build_outputs", sourceable_text, fixed = TRUE), "CONFLUENCE sourceable should use the production aggregate layer.")
expect_true(grepl("confluence_write_outputs", sourceable_text, fixed = TRUE), "CONFLUENCE sourceable should write the mini-bundle CSVs.")

old_config_exists <- exists(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE)
old_config <- if (old_config_exists) get(".CONFLUENCE_COUNT_SOURCE_CONFIG", envir = .GlobalEnv, inherits = FALSE) else NULL
old_result_exists <- exists("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE)
old_result <- if (old_result_exists) get("CONFLUENCE_COUNT_RESULT", envir = .GlobalEnv, inherits = FALSE) else NULL
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
  CONFLUENCE_COUNT_OUTPUTS_DIR = plan_dir,
  CONFLUENCE_COUNT_SMALL_CELL_N = 5L,
  CONFLUENCE_COUNT_UPDATE_PAYLOAD = FALSE,
  CONFLUENCE_COUNT_ATLAS_OUTPUT_DIR = "",
  CONFLUENCE_COUNT_ATLAS_OUTPUT_ZIP = ""
))

expect_true(is.list(plan_result) && all(c("outputs", "paths") %in% names(plan_result)), "CONFLUENCE one-click result should expose outputs and paths.")
for (name in c(
  "summary",
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

expect_true(any(prod_result$outputs$production_execution_summary$metric == "production_query_success" & prod_result$outputs$production_execution_summary$value == "TRUE"), "Fake production adapter should populate CONFLUENCE production execution summary.")
expect_true(any(prod_result$outputs$overlap_counts_accepted$acceptance_status == "accepted"), "Fake production adapter should produce accepted overlap rows.")
expect_true(any(prod_result$outputs$infection_person_time$acceptance_status == "accepted"), "Fake production adapter should produce accepted person-time rows.")
expect_true(any(prod_result$outputs$infection_counts$endpoint_definition_status == "repo-derived provisional"), "Fake production adapter should produce provisional infection endpoint aggregates.")

public_text <- paste(unlist(prod_result$outputs, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("\\bp[0-9]{2}\\b", public_text), "CONFLUENCE one-click public outputs must not emit fake patient identifiers.")
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", public_text), "CONFLUENCE one-click public outputs must not emit CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", public_text), "CONFLUENCE one-click public outputs must not emit raw dates.")
expect_false(grepl("raw pathology text|snippet|row preview", public_text, ignore.case = TRUE), "CONFLUENCE one-click public outputs must not emit raw free text/snippets/row previews.")

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
