root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

icu <- data.frame(
  patientid = c("p1", "p2", "p3", "p4"),
  icu_stay_start = as.Date(c("2026-04-20", "2026-05-01", "2026-04-01", "2026-05-11")),
  icu_stay_end = as.Date(c(NA, "2026-05-10", "2026-04-03", NA)),
  stringsAsFactors = FALSE
)
current_ita <- situation_current_interval_from_data(
  icu,
  metric_id = "currently_ita",
  label = "Currently in ITA/ICU",
  start_col = "icu_stay_start",
  end_col = "icu_stay_end",
  min_cell_count = 1L
)
expect_equal(current_ita$n_patients[[1]], 2L, "Current interval metrics should count patients active at the source-specific as-of date.")
expect_equal(current_ita$as_of_date[[1]], "2026-05-11", "Current interval metrics should anchor to the source max date.")

adt_start_only <- data.frame(
  patientid = c("p1", "p2"),
  kontakt_start_local_dttm = as.Date(c("2026-05-01", "2026-05-02")),
  patient_class = c("Indlagt patient", "Indlagt patient"),
  stringsAsFactors = FALSE
)
start_only <- situation_current_admission_from_data(
  adt_start_only,
  end_col = "kontakt_end_local_dttm",
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(start_only$definition_status[[1]], "unavailable", "Current admission must not fall back to ever-started contacts when the paired end column is missing.")
expect_true(is.na(start_only$n_patients[[1]]), "Unavailable current admission should not expose a patient count.")

adt <- data.frame(
  patientid = c("p1", "p2", "p3", "p4"),
  kontakt_start_local_dttm = as.Date(c("2026-05-01", "2026-05-01", "2026-05-01", "2026-05-10")),
  kontakt_end_local_dttm = as.Date(c(NA, "2026-05-09", NA, NA)),
  patient_class = c("Indlagt patient", "Indlagt patient", "Ambulant patient", "Indlagt patient"),
  stringsAsFactors = FALSE
)
current_admitted <- situation_current_admission_from_data(
  adt,
  as_of = as.Date("2026-05-10"),
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(current_admitted$n_patients[[1]], 2L, "Current admission should count only active inpatient intervals.")
expect_equal(current_admitted$n_rows[[1]], 2L, "Current admission should not count discharged or ambulatory contacts.")
expect_equal(current_admitted$pct_cohort[[1]], 2, "Situation metrics should report percent of the cohort denominator.")

recent_admitted <- situation_recent_admission_date_from_data(
  adt,
  metric_id = "admitted_30d",
  label = "Admitted in past 30 days",
  date_col = "kontakt_start_local_dttm",
  as_of = as.Date("2026-05-10"),
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(recent_admitted$n_patients[[1]], 3L, "Recent admission should filter out ambulatory contact rows when patient_class is available.")
expect_equal(recent_admitted$as_of_date[[1]], "2026-05-10", "Recent admission should use the source-specific as-of date.")

diagnoses <- data.frame(
  patientid = c("p1", "p2", "p2", "p3", "p4", "p5", "p5"),
  date_diagnosis = as.Date(c("2026-04-01", "2026-04-15", "2026-05-10", "2026-05-11", "2026-05-12", "2026-03-01", "2026-05-12")),
  stringsAsFactors = FALSE
)
recent_dx_any_row <- situation_recent_from_data(
  diagnoses,
  metric_id = "diagnosed_30d",
  label = "Diagnosed in past 30 days",
  date_col = "date_diagnosis",
  min_cell_count = 1L
)
expect_equal(recent_dx_any_row$n_patients[[1]], 4L, "The generic recent-date fixture helper counts patients with any row inside the data-as-of window.")
recent_dx <- situation_recent_earliest_from_data(
  diagnoses,
  date_col = "date_diagnosis",
  min_cell_count = 1L,
  n_cohort = 1000L
)
expect_equal(recent_dx$n_patients[[1]], 3L, "Diagnosed-30d should count patients whose earliest diagnosis date is inside the data-as-of window.")
expect_equal(recent_dx$n_rows[[1]], 3L, "Earliest-diagnosis metrics should not count later diagnosis rows for old patients.")
expect_equal(recent_dx$as_of_date[[1]], "2026-05-12", "Earliest-diagnosis metrics should anchor to the source max date.")
expect_true(grepl("earliest_patient_diagnosis_date_30d", recent_dx$definition_basis[[1]], fixed = TRUE), "Diagnosed-30d should record earliest-diagnosis definition basis.")

suppressed_dx <- situation_recent_earliest_from_data(
  diagnoses,
  date_col = "date_diagnosis",
  min_cell_count = 10L
)
expect_equal(suppressed_dx$definition_status[[1]], "suppressed", "Situation metrics should suppress small public counts.")
expect_true(is.na(suppressed_dx$n_patients[[1]]), "Suppressed Situation metrics should not expose patient counts.")

unavailable_dx <- situation_recent_earliest_from_data(
  diagnoses[, "date_diagnosis", drop = FALSE],
  date_col = "date_diagnosis",
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(unavailable_dx$definition_status[[1]], "unavailable", "Diagnosed-30d should be unavailable when patient/date evidence is incomplete.")

implausible_dx <- situation_recent_earliest_from_data(
  diagnoses,
  date_col = "date_diagnosis",
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(implausible_dx$definition_status[[1]], "needs_review", "Implausibly high diagnosed-30d metrics should be flagged for review.")

fallback <- build_situation_report_panels(
  sources = data.frame(table_name = "example", stringsAsFactors = FALSE),
  column_profiles = data.frame(
    table_name = "example",
    column_name = "event_date",
    profile_kind = "date",
    max_date = "2026-05-12",
    stringsAsFactors = FALSE
  ),
  min_cell_count = 1L
)
expect_true(all(c("situation_report_summary", "situation_report_breakdowns", "situation_report_freshness") %in% names(fallback)), "Situation builder should return all panel outputs.")
expect_true(any(fallback$situation_report_summary$definition_status == "unavailable"), "Missing live DB access should produce unavailable metric rows rather than failing.")
expect_true(nrow(fallback$situation_report_freshness) > 0, "Fallback freshness should reuse aggregate column-profile date ranges when available.")

fake_adapter <- list(
  situation_report = function(...) {
    list(
      situation_report_summary = data.frame(
        metric_id = "currently_admitted",
        label = "Currently admitted",
        n_patients = 12,
        n_rows = 14,
        window_days = NA_integer_,
        as_of_date = "2026-05-12",
        source_table = "SP_ADT_haendelser",
        date_column = "event_time",
        definition_status = "ok",
        freshness_status = "current",
        message = "DB aggregate profiling succeeded.",
        stringsAsFactors = FALSE
      ),
      situation_report_breakdowns = data.frame(
        metric_id = "currently_admitted",
        label = "Currently admitted",
        breakdown_type = "source",
        breakdown_value = "SP_ADT_haendelser",
        n_patients = 12,
        n_rows = 14,
        pct_patients = 100,
        source_table = "SP_ADT_haendelser",
        as_of_date = "2026-05-12",
        stringsAsFactors = FALSE
      ),
      situation_report_freshness = data.frame(
        metric_id = "currently_admitted",
        source_table = "SP_ADT_haendelser",
        date_column = "event_time",
        max_date = "2026-05-12",
        as_of_date = "2026-05-12",
        lag_days = 0,
        freshness_status = "current",
        message = "Source date matches the freshest situation-report source.",
        stringsAsFactors = FALSE
      )
    )
  }
)
fake <- build_situation_report_panels(db_adapter = fake_adapter, min_cell_count = 1L)
expect_equal(fake$situation_report_summary$n_patients[[1]], 12, "Custom DB adapters should be able to supply aggregate Situation Report panels.")
expect_equal(fake$situation_report_breakdowns$breakdown_type[[1]], "source", "Situation Report breakdown panels should be preserved.")

implausible <- situation_metric_row(
  situation_report_metric_defs()[[1]],
  counts = list(n_patients = 28L, n_rows = 1000L),
  as_of_date = as.Date("2026-05-12"),
  source_table = "SP_ADT_haendelser",
  date_column = "kontakt_start_local_dttm",
  min_cell_count = 1L,
  n_cohort = 100L
)
expect_equal(implausible$definition_status[[1]], "needs_review", "Implausibly high current-admitted metrics should be flagged for review.")
