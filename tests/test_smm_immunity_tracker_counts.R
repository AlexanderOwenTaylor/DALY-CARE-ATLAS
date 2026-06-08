root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expect_file(file.path(root, "R", "smm_immunity_tracker_feasibility.R"))
expect_file(file.path(root, "R", "smm_immunity_tracker_counts.R"))
expect_file(file.path(root, "config", "smm_immunity_tracker_analysis_windows.tsv"))

plan_outputs <- smm_immunity_tracker_count_build_outputs(
  project_root = root,
  db_adapter = NULL,
  mode = "auto",
  min_cell_count = 5L
)
expect_true(any(plan_outputs$production_execution_summary$value == "plan"), "No SMM sources should keep the tracker in plan/fail-closed mode.")
expect_true(all(plan_outputs$cohort_counts$acceptance_status != "accepted"), "Plan mode must not emit accepted cohort counts.")
expect_true(any(plan_outputs$failed_query_audit$count_status == "query executable not run"), "Plan mode should preserve a not-run audit row.")

old_wp5_root <- Sys.getenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT", unset = NA_character_)
old_wommen_wp5_root <- Sys.getenv("WOMMEN_WP5_OUTPUT_ROOT", unset = NA_character_)
on.exit({
  if (is.na(old_wp5_root)) Sys.unsetenv("SMM_IMMUNITY_WP5_OUTPUT_ROOT") else Sys.setenv(SMM_IMMUNITY_WP5_OUTPUT_ROOT = old_wp5_root)
  if (is.na(old_wommen_wp5_root)) Sys.unsetenv("WOMMEN_WP5_OUTPUT_ROOT") else Sys.setenv(WOMMEN_WP5_OUTPUT_ROOT = old_wommen_wp5_root)
}, add = TRUE)

wp5_fixture <- tempfile("wp5_run_")
wp5_outputs <- file.path(wp5_fixture, "outputs", "wp5")
dir.create(wp5_outputs, recursive = TRUE)
utils::write.csv(
  data.frame(
    tier_id = c("SMM-A", "SMM-B", "SMM-C"),
    tier_label = c("Untreated", "BMPC", "Biomarker"),
    n_patients = c(6641, 2133, 1795),
    stringsAsFactors = FALSE
  ),
  file.path(wp5_outputs, "wp5_smm_analysis_tiers.csv"),
  row.names = FALSE
)
utils::write.csv(
  data.frame(step_id = c("first_dc900", "followup_beyond_day90"), n = c(13526, 6641), stringsAsFactors = FALSE),
  file.path(wp5_outputs, "wp5_cohort_attrition.csv"),
  row.names = FALSE
)
utils::write.csv(
  data.frame(patientid = c("p1", "p2"), first_mm_date = c("2020-01-01", "2020-01-02"), stringsAsFactors = FALSE),
  file.path(wp5_outputs, "wp5_smm_model_frames.csv"),
  row.names = FALSE
)
Sys.setenv(SMM_IMMUNITY_WP5_OUTPUT_ROOT = wp5_fixture)
agg_outputs <- smm_immunity_tracker_count_build_outputs(
  project_root = root,
  db_adapter = NULL,
  mode = "production_aggregate",
  min_cell_count = 5L
)
expect_true(any(agg_outputs$cohort_counts$cohort_id == "aot_wp5_original_smm" & agg_outputs$cohort_counts$n_people == 6641), "AOT/WP5 SMM-A denominator should come from public aggregate tiers.")
expect_true(any(agg_outputs$cohort_counts$cohort_id == "aot_wp5_bmpc_confirmable_subset" & agg_outputs$cohort_counts$n_people == 2133), "SMM-B denominator should come from public aggregate tiers.")
expect_true(any(agg_outputs$cohort_counts$cohort_id == "aot_wp5_biomarker_rich_subset" & agg_outputs$cohort_counts$n_people == 1795), "SMM-C denominator should come from public aggregate tiers.")
expect_true(any(agg_outputs$cohort_counts$cohort_id == "cvm_jama_smm" & agg_outputs$cohort_counts$source_acceptance_status == "not_yet_accepted_aggregate_source"), "CVM/JAMA should appear as a pending readiness row, not an accepted count.")
expect_true(all(c("source_file", "source_root_label", "wp5_run_id", "path_status", "public_safe", "secure_input_only") %in% names(agg_outputs$wp5_source_audit)), "WP5 public audit should use privacy-safe columns.")
expect_false("expected_path" %in% names(agg_outputs$wp5_source_audit), "WP5 public audit must not expose expected_path.")
secure_audit <- agg_outputs$wp5_source_audit[agg_outputs$wp5_source_audit$source_file == "wp5_smm_model_frames.csv", , drop = FALSE]
expect_true(nrow(secure_audit) == 1L && isTRUE(secure_audit$secure_input_only[[1]]) && is.na(secure_audit$rows_read[[1]]), "Secure WP5 files must be presence-checked only with rows_read NA.")
expect_equal(nrow(agg_outputs$infection_counts), 0L, "Unavailable infection outputs should be schemaful empty tables.")
expect_true(length(names(agg_outputs$infection_counts)) > 0L, "Schemaful empty infection outputs should keep their columns.")
expect_true(any(agg_outputs$source_resolution_audit$route_id == "hospital_coded_serious_infection_route" & agg_outputs$source_resolution_audit$query_status == "unavailable_not_configured"), "Source-resolution audit should explain unavailable infection routes.")
expect_true(any(agg_outputs$tracker_status$status_key == "production_aggregate_status" & grepl("cohort counts available; CVM aggregate route pending; infection routes unavailable", agg_outputs$tracker_status$status_value, fixed = TRUE)), "Tracker status should state the partial production state.")
expect_true(any(grepl("AOT/WP5 cohort denominators available; CVM aggregate route pending; infection routes unavailable", agg_outputs$story_cards$body, fixed = TRUE)), "Payload story should state available denominators and unavailable routes.")
flat_values <- paste(unlist(lapply(agg_outputs, function(x) if (is.data.frame(x)) as.character(unlist(x, use.names = FALSE)) else character()), use.names = FALSE), collapse = "\n")
expect_false(grepl("(/ngc/|/home/|/mnt/|[A-Za-z]:[\\\\/])", flat_values, ignore.case = TRUE), "Public outputs must not expose absolute filesystem paths.")
for (nm in names(agg_outputs)) {
  df <- agg_outputs[[nm]]
  if (!is.data.frame(df) || !nrow(df)) next
  for (col in setdiff(names(df), "wp5_run_id")) {
    vals <- as.character(df[[col]])
    vals <- vals[!is.na(vals)]
    expect_false(any(grepl("\\b[0-9]{4}-[0-9]{2}-[0-9]{2}\\b", vals)), paste("Public outputs must not expose raw dates outside wp5_run_id:", nm, col))
  }
}

entry <- as.Date("2020-03-31")
first <- as.Date("2020-01-01")
aot <- data.frame(
  person_key = sprintf("a%02d", 1:8),
  cohort_id = "aot_wp5_original_smm",
  first_dc900_date = first,
  day90_date = entry,
  progression_date = as.Date(c("2020-11-25", NA, "2020-08-01", NA, NA, "2021-01-10", NA, "2021-02-01")),
  death_date = as.Date(c(NA, NA, NA, "2020-06-20", NA, NA, NA, NA)),
  censor_date = as.Date("2021-03-31"),
  stringsAsFactors = FALSE
)
cvm <- data.frame(
  person_key = sprintf("c%02d", 1:6),
  cohort_id = "cvm_jama_smm",
  first_dc900_date = first,
  diagnosis_date = first,
  progression_date = as.Date(c("2020-12-01", NA, NA, NA, "2020-07-15", NA)),
  death_date = as.Date(c(NA, NA, "2020-10-01", NA, NA, NA)),
  censor_date = as.Date("2021-03-31"),
  stringsAsFactors = FALSE
)
infection_events <- data.frame(
  person_key = c("a01", "a02", "a05", "a05", "a06", "a06", "a07", "a08", "a08", "a08", "a08", "c01", "c02"),
  event_date = as.Date(c(
    "2020-04-01",
    "2020-03-01",
    "2020-04-10", "2020-04-17",
    "2020-04-10", "2020-05-15",
    "2019-12-15",
    "2020-04-01", "2020-05-01", "2020-06-01", "2020-07-01",
    "2020-03-10", "2020-04-20"
  )),
  endpoint_id = "serious_infection_hospitalization",
  stringsAsFactors = FALSE
)
micro_events <- data.frame(
  person_key = c("a01", "c02"),
  event_date = as.Date(c("2020-04-02", "2020-05-01")),
  endpoint_id = "microbiology_confirmed_infection",
  stringsAsFactors = FALSE
)

prod <- smm_immunity_tracker_count_outputs_from_secure_frames(
  list(
    cohort_entries = bind_rows_base(list(aot, cvm)),
    infection_events = infection_events,
    microbiology_confirmation_events = micro_events
  ),
  project_root = root,
  min_cell_count = 1L,
  source_label = "synthetic test fixture"
)

expect_true(any(prod$cohort_counts$cohort_id == "aot_wp5_original_smm" & prod$cohort_counts$n_people_display == "8"), "AOT cohort count should be accepted.")
expect_true(any(prod$cohort_counts$cohort_id == "cvm_jama_smm_day90_harmonized"), "CVM day-90 harmonized cohort should be emitted.")
expect_true(any(prod$cohort_counts$cohort_id == "cvm_jama_smm_diagnosis_origin" & prod$cohort_counts$time_origin == "diagnosis_origin_after_90d_eligibility_restriction"), "CVM diagnosis-origin view should be secondary/reproduction.")

aot_diag90 <- prod$infection_counts[
  prod$infection_counts$cohort_id == "aot_wp5_original_smm" &
    prod$infection_counts$analysis_window == "diagnosis_to_day90",
  ,
  drop = FALSE
]
expect_true(any(aot_diag90$count_display == "1"), "AOT infection before day 90 should count in diagnosis_to_day90.")

aot_post6 <- prod$infection_counts[
  prod$infection_counts$cohort_id == "aot_wp5_original_smm" &
    prod$infection_counts$analysis_window == "post_entry_6m_landmark",
  ,
  drop = FALSE
]
expect_false(any(aot_post6$count_display == "1" & aot_post6$event_count_display == "1"), "AOT day-60 infection should not be the only post-entry 6-month event.")

rec <- prod$recurrent_infection_counts[
  prod$recurrent_infection_counts$cohort_id == "aot_wp5_original_smm" &
    prod$recurrent_infection_counts$analysis_window == "post_entry_6m_landmark",
  ,
  drop = FALSE
]
raw <- prod$infection_counts[
  prod$infection_counts$cohort_id == "aot_wp5_original_smm" &
    prod$infection_counts$analysis_window == "post_entry_6m_landmark",
  ,
  drop = FALSE
]
expect_true(as.numeric(rec$event_count_display[[1]]) < as.numeric(raw$event_count_display[[1]]), "Two same-endpoint infections within 7 days should collapse under the recurrent episode rule.")
expect_true(any(prod$microbiology_confirmation_counts$acceptance_status == "accepted"), "Synthetic microbiology route should emit accepted aggregate rows.")

aot_landmark <- prod$landmark_progression_signal[
  prod$landmark_progression_signal$cohort_id == "aot_wp5_original_smm" &
    prod$landmark_progression_signal$analysis_window == "post_entry_6m_landmark",
  ,
  drop = FALSE
]
expect_equal(sum(aot_landmark$n_at_landmark, na.rm = TRUE), 6, "Progression/death before the 6-month landmark should be excluded from the landmark risk set.")
expect_true(any(aot_landmark$progression_events > 0, na.rm = TRUE), "Progression after the landmark should be counted.")
expect_true(any(prod$landmark_progression_signal$analysis_window == "pre_progression_descriptive" & prod$landmark_progression_signal$competing_deaths > 0, na.rm = TRUE), "Death before progression should be represented as a competing event in descriptive summaries.")

small <- smm_immunity_tracker_count_suppress(4, total = 10, min_cell_count = 5L)
comp <- smm_immunity_tracker_count_suppress(6, total = 10, min_cell_count = 5L)
ok <- smm_immunity_tracker_count_suppress(5, total = 10, min_cell_count = 5L)
expect_true(is.na(small$n_public) && grepl("small cell", small$status), "Primary small cells should be suppressed.")
expect_true(is.na(comp$n_public) && grepl("complementary", comp$status), "Complementary small cells should be suppressed.")
expect_equal(ok$n_public, 5, "Balanced cells at the threshold should remain visible.")

bad_adapter <- list(
  smm_immunity_tracker_counts = function(min_cell_count = 5L, wp5_output_root = "") {
    list(cohort_entries = aot)
  }
)
bad <- smm_immunity_tracker_count_build_outputs(
  project_root = root,
  db_adapter = bad_adapter,
  mode = "production_aggregate",
  min_cell_count = 5L
)
expect_true(any(grepl("privacy", bad$production_execution_summary$value, ignore.case = TRUE) | grepl("row-level", bad$failed_query_audit$error_message_sanitized, ignore.case = TRUE)), "Aggregate hook must reject row-level frame returns.")

unsafe_adapter <- list(
  smm_immunity_tracker_counts = function(min_cell_count = 5L, wp5_output_root = "") {
    list(cohort_counts = data.frame(cohort_id = "x", patientid = "p1", persons_n = 10, stringsAsFactors = FALSE))
  }
)
unsafe <- smm_immunity_tracker_count_build_outputs(
  project_root = root,
  db_adapter = unsafe_adapter,
  mode = "production_aggregate",
  min_cell_count = 5L
)
expect_true(any(grepl("unsafe", unsafe$failed_query_audit$error_message_sanitized, ignore.case = TRUE)), "Aggregate hook must reject unsafe adapter columns.")

safe_adapter <- list(
  smm_immunity_tracker_counts = function(min_cell_count = 5L, wp5_output_root = "") {
    list(cohort_counts = data.frame(
      cohort_id = "aggregate_safe_test",
      cohort_label = "Aggregate safe test",
      time_origin = "day90_harmonized",
      n_people_display = "3",
      n_people = 3,
      acceptance_status = "accepted",
      query_status = "executed",
      stringsAsFactors = FALSE
    ))
  }
)
safe_adapter_outputs <- smm_immunity_tracker_count_build_outputs(
  project_root = root,
  db_adapter = safe_adapter,
  mode = "production_aggregate",
  min_cell_count = 5L
)
expect_true(is.na(safe_adapter_outputs$cohort_counts$n_people[[1]]) && safe_adapter_outputs$cohort_counts$n_people_display[[1]] == "<5", "Adapter count outputs should receive small-cell suppression before writing.")

safe <- smm_immunity_tracker_public_output_is_safe(prod)
expect_true(safe$ok, paste("SMM outputs should not expose forbidden public columns:", paste(safe$hits, collapse = "; ")))

cat("SMM Immunity Tracker count tests passed\n")
