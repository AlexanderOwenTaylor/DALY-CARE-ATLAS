root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expect_file(file.path(root, "R", "confluence_counts.R"))
expect_file(file.path(root, "config", "confluence_person_date_mapping.tsv"))
expect_file(file.path(root, "config", "confluence_infection_endpoint_code_sets.tsv"))

plan_outputs <- confluence_count_build_outputs(
  project_root = root,
  db_adapter = NULL,
  mode = "auto",
  min_cell_count = 5L
)
expect_true(any(plan_outputs$production_execution_summary$value == "plan"), "No DB adapter should keep CONFLUENCE in plan/fail-closed mode.")
expect_true(all(plan_outputs$overlap_counts_accepted$acceptance_status != "accepted"), "Plan mode must not emit accepted overlap counts.")
expect_true(any(plan_outputs$failed_query_audit$count_status == "query executable not run"), "Plan mode should preserve a precise not-run audit row.")

fake_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) {
    list(
      patient_frame = data.frame(
        person_key = sprintf("p%02d", 1:16),
        date_death_fu = c(rep(NA, 15), as.Date("2022-07-01")),
        stringsAsFactors = FALSE
      ),
      disease_first_dates = data.frame(
        person_key = c(
          "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p09", "p10", "p11", "p12",
          "p01", "p02", "p03", "p04", "p05", "p06", "p07", "p08", "p13", "p14", "p15", "p16",
          "p03", "p04", "p05", "p06", "p07", "p08",
          "p09", "p10", "p11", "p12",
          "p15"
        ),
        state_id = c(
          rep("cll", 12),
          rep("mgus", 12),
          rep("coded_mbl", 6),
          rep("mm", 4),
          "cll_morphology_pressure"
        ),
        first_date = as.Date(c(
          rep("2020-01-01", 12),
          rep("2020-06-01", 12),
          rep("2019-03-01", 6),
          rep("2021-01-15", 4),
          "2020-02-01"
        )),
        stringsAsFactors = FALSE
      ),
      infection_events = data.frame(
        person_key = c("p01", "p01", "p02", "p03", "p04", "p05", "p05", "p06", "p07", "p08", "p09", "p10", "p11", "p12", "p13", "p14"),
        event_date = as.Date(c(
          "2020-07-01", "2020-07-10", "2020-09-01", "2020-07-05", "2020-07-06", "2020-08-01", "2020-09-01",
          "2020-07-07", "2020-07-08", "2020-08-09", "2020-05-01", "2020-05-02", "2020-05-03", "2020-05-04",
          "2020-10-01", "2020-10-02"
        )),
        endpoint_id = "serious_infection_hospitalization",
        stringsAsFactors = FALSE
      )
    )
  }
)

prod <- confluence_count_build_outputs(
  project_root = root,
  db_adapter = fake_adapter,
  mode = "auto",
  min_cell_count = 5L
)

old_dalycare_db_adapter_exists <- exists("dalycare_db_adapter", envir = .GlobalEnv, inherits = FALSE)
old_dalycare_db_adapter <- if (old_dalycare_db_adapter_exists) get("dalycare_db_adapter", envir = .GlobalEnv, inherits = FALSE) else NULL
assign("dalycare_db_adapter", function(...) fake_adapter, envir = .GlobalEnv)
auto_prod <- tryCatch(
  confluence_count_build_outputs(
    project_root = root,
    db_adapter = NULL,
    mode = "production_aggregate",
    min_cell_count = 5L
  ),
  finally = {
    if (old_dalycare_db_adapter_exists) {
      assign("dalycare_db_adapter", old_dalycare_db_adapter, envir = .GlobalEnv)
    } else if (exists("dalycare_db_adapter", envir = .GlobalEnv, inherits = FALSE)) {
      rm("dalycare_db_adapter", envir = .GlobalEnv)
    }
  }
)
expect_true(any(auto_prod$production_execution_summary$metric == "production_query_success" & auto_prod$production_execution_summary$value == "TRUE"), "Explicit production mode should auto-discover dalycare_db_adapter() when no adapter is supplied.")
expect_true(any(auto_prod$overlap_counts_accepted$acceptance_status == "accepted"), "Auto-discovered CONFLUENCE adapter should feed accepted aggregate outputs.")

expect_true(any(prod$production_execution_summary$metric == "production_query_success" & prod$production_execution_summary$value == "TRUE"), "Fake DB adapter should execute CONFLUENCE production aggregates.")
expect_true(any(prod$disease_state_person_counts$state_id == "cll" & prod$disease_state_person_counts$acceptance_status == "accepted"), "CLL first-date aggregate should be accepted.")
expect_true(any(prod$disease_state_person_counts$state_id == "coded_mbl" & prod$disease_state_person_counts$count_display == "6"), "Coded MBL person count should be computed from secure first dates.")
expect_false(any(prod$disease_state_person_counts$state_id == "cll_morphology_pressure" & grepl("MBL", prod$disease_state_person_counts$state_label) & prod$disease_state_person_counts$acceptance_status == "accepted"), "M98233 pressure must never become an accepted MBL cohort.")

overlap <- prod$overlap_counts_accepted
expect_true(any(overlap$overlap_id == "coded_mbl_mgus" & overlap$count_display == "6" & overlap$acceptance_status == "accepted"), "Coded MBL + MGUS overlap should be accepted when gate proofs exist.")
expect_true(all(grepl("later first qualifying", overlap$date_anchor_used, ignore.case = TRUE)), "Overlap date anchor should be the later disease-state first date.")
expect_false(any(overlap$acceptance_status == "accepted" & overlap$acceptance_gate_status != "passed"), "Accepted overlap rows must pass the acceptance gate.")

timing <- prod$overlap_timing_accepted
expect_true(any(timing$timing_id == "cll_mbl_first" & timing$count_display == "12"), "Timing should classify CLL/MBL first when the B-cell state precedes PCD.")

expect_true(any(prod$infection_endpoint_code_sets$definition_status == "repo-derived provisional"), "Infection endpoint code sets should be labelled provisional.")
expect_true(any(prod$infection_counts$endpoint_definition_status == "repo-derived provisional" & prod$infection_counts$acceptance_status == "accepted"), "Provisional infection counts should be accepted only as provisional endpoint aggregates.")
expect_true(any(prod$recurrent_infection_counts$count_kind == "distinct recurrent episodes"), "Recurrent infection output should use the provisional 14-day same-endpoint episode gap.")
expect_true(any(prod$infection_person_time$count_kind == "person-years" & prod$infection_person_time$acceptance_status == "accepted"), "Person-time denominators should be accepted aggregate person-years.")
expect_true(any(prod$infection_rates$count_kind == "rate from suppressed aggregate components"), "Rates should be rendered from aggregate components.")
expect_true(all(prod$microbiology_confirmation_counts$acceptance_status != "accepted"), "Microbiology-confirmed infection must fail closed without deterministic patient/date/result mappings.")

pathology_failed_status <- bind_rows_base(list(
  confluence_count_route_status_row("diagnosis_first_dates", TRUE, TRUE, source_table = "diagnosis fixture"),
  confluence_count_route_status_row(
    "pathology_first_dates",
    TRUE,
    FALSE,
    error_class = "production_aggregate_failed_query_error",
    error_message_sanitized = "relation public.sds_pato does not exist",
    source_table = "import.public.SDS_pato"
  ),
  confluence_count_route_status_row("infection_events", TRUE, TRUE, source_table = "infection fixture"),
  confluence_count_route_status_row("patient_frame", TRUE, TRUE, source_table = "patient fixture")
))
pathology_failed_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) {
    list(
      sets = list(
        patient_frame = data.frame(person_key = sprintf("p%02d", 1:8), date_death_fu = rep(NA, 8), stringsAsFactors = FALSE),
        disease_first_dates = data.frame(
          person_key = c(sprintf("p%02d", 1:6), sprintf("p%02d", 1:6)),
          state_id = c(rep("cll", 6), rep("mgus", 6)),
          first_date = as.Date(c(rep("2020-01-01", 6), rep("2020-06-01", 6))),
          stringsAsFactors = FALSE
        ),
        infection_events = data.frame(
          person_key = sprintf("p%02d", 1:6),
          event_date = as.Date(rep("2020-08-01", 6)),
          endpoint_id = "serious_infection_hospitalization",
          stringsAsFactors = FALSE
        ),
        route_status = pathology_failed_status
      ),
      errors = confluence_count_failed_route_audit(pathology_failed_status)
    )
  }
)
pathology_failed <- confluence_count_build_outputs(root, pathology_failed_adapter, mode = "production_aggregate", min_cell_count = 5L)
failed_pathology_rows <- pathology_failed$disease_state_person_counts[pathology_failed$disease_state_person_counts$state_id %in% c("pathology_mbl", "cll_morphology_pressure"), , drop = FALSE]
expect_true(all(failed_pathology_rows$acceptance_status == "not accepted aggregate"), "Failed PATOBANK route must not accept pathology-derived rows.")
expect_false(any(failed_pathology_rows$count_display == "0" & failed_pathology_rows$acceptance_status == "accepted"), "Failed PATOBANK route must not become accepted zero.")
failed_mbl_steps <- pathology_failed$mbl_validation_waterfall[pathology_failed$mbl_validation_waterfall$step_order %in% c(2L, 3L), , drop = FALSE]
expect_true(all(failed_mbl_steps$acceptance_status == "not accepted aggregate"), "Pathology-specific MBL waterfall steps must fail closed when PATOBANK fails.")
expect_true(any(pathology_failed$failed_query_audit$query_id == "confluence_pathology_first_dates"), "Failed PATOBANK route should be visible in failed-query audit.")

pathology_zero_status <- bind_rows_base(list(
  confluence_count_route_status_row("diagnosis_first_dates", TRUE, TRUE, source_table = "diagnosis fixture"),
  confluence_count_route_status_row("pathology_first_dates", TRUE, TRUE, source_table = "PATOBANK fixture"),
  confluence_count_route_status_row("infection_events", TRUE, TRUE, source_table = "infection fixture"),
  confluence_count_route_status_row("patient_frame", TRUE, TRUE, source_table = "patient fixture")
))
pathology_zero <- confluence_count_outputs_from_sets(
  list(
    patient_frame = data.frame(person_key = sprintf("p%02d", 1:6), date_death_fu = rep(NA, 6), stringsAsFactors = FALSE),
    disease_first_dates = data.frame(
      person_key = sprintf("p%02d", 1:6),
      state_id = "cll",
      first_date = as.Date(rep("2020-01-01", 6)),
      stringsAsFactors = FALSE
    ),
    infection_events = data.frame(
      person_key = sprintf("p%02d", 1:6),
      event_date = as.Date(rep("2020-08-01", 6)),
      endpoint_id = "serious_infection_hospitalization",
      stringsAsFactors = FALSE
    ),
    route_status = pathology_zero_status
  ),
  project_root = root,
  min_cell_count = 5L
)
zero_pathology_rows <- pathology_zero$disease_state_person_counts[pathology_zero$disease_state_person_counts$state_id %in% c("pathology_mbl", "cll_morphology_pressure"), , drop = FALSE]
expect_true(all(zero_pathology_rows$count_display == "0" & zero_pathology_rows$acceptance_status == "accepted"), "Accepted zero is allowed when the PATOBANK route executed successfully and returned no rows.")

infection_failed_status <- bind_rows_base(list(
  confluence_count_route_status_row("diagnosis_first_dates", TRUE, TRUE, source_table = "diagnosis fixture"),
  confluence_count_route_status_row("pathology_first_dates", TRUE, TRUE, source_table = "PATOBANK fixture"),
  confluence_count_route_status_row(
    "infection_events",
    TRUE,
    FALSE,
    error_class = "production_aggregate_failed_query_error",
    error_message_sanitized = "relation public.t_dalycare_diagnoses does not exist",
    source_table = "core.public.t_dalycare_diagnoses"
  ),
  confluence_count_route_status_row("patient_frame", TRUE, TRUE, source_table = "patient fixture")
))
infection_failed <- confluence_count_outputs_from_sets(
  list(
    patient_frame = data.frame(person_key = sprintf("p%02d", 1:6), date_death_fu = rep(NA, 6), stringsAsFactors = FALSE),
    disease_first_dates = data.frame(
      person_key = c(sprintf("p%02d", 1:6), sprintf("p%02d", 1:6)),
      state_id = c(rep("cll", 6), rep("mgus", 6)),
      first_date = as.Date(c(rep("2020-01-01", 6), rep("2020-06-01", 6))),
      stringsAsFactors = FALSE
    ),
    infection_events = data.frame(stringsAsFactors = FALSE),
    route_status = infection_failed_status
  ),
  project_root = root,
  min_cell_count = 5L
)
expect_true(all(infection_failed$infection_counts$acceptance_status == "not accepted aggregate"), "Failed infection route must leave infection counts not accepted.")
expect_true(all(infection_failed$infection_rates$acceptance_status == "not accepted aggregate"), "Failed infection route must leave infection rates not accepted.")
expect_true(any(infection_failed$failed_query_audit$query_id == "confluence_infection_events"), "Failed infection route should be visible in failed-query audit.")

mixed_queries <- character()
mixed_case_adapter <- list(
  list_tables = function() {
    data.frame(
      db_name = c("core", "core", "core", "import", "import", "import"),
      schema = "public",
      table = c("patient", "t_dalycare_diagnoses", "diagnoses_all", "SDS_pato", "SDS_t_adm", "SDS_kontakter"),
      stringsAsFactors = FALSE
    )
  },
  confluence_query = function(sql) {
    mixed_queries <<- c(mixed_queries, sql)
    if (grepl("serious_infection_hospitalization", sql, fixed = TRUE)) {
      return(empty_df(person_key = character(), event_date = as.Date(character()), endpoint_id = character()))
    }
    if (grepl('"SDS_pato"', sql, fixed = TRUE)) {
      return(data.frame(person_key = "p01", state_id = "pathology_mbl", first_date = as.Date("2020-02-01"), stringsAsFactors = FALSE))
    }
    if (grepl('"t_dalycare_diagnoses"', sql, fixed = TRUE)) {
      return(data.frame(person_key = "p01", state_id = "cll", first_date = as.Date("2020-01-01"), stringsAsFactors = FALSE))
    }
    if (grepl('"diagnoses_all"', sql, fixed = TRUE)) {
      return(empty_df(person_key = character(), state_id = character(), first_date = as.Date(character())))
    }
    if (grepl('"patient"', sql, fixed = TRUE)) {
      return(data.frame(person_key = "p01", date_death_fu = as.Date(NA_character_), stringsAsFactors = FALSE))
    }
    data.frame(stringsAsFactors = FALSE)
  }
)
mixed_case <- confluence_count_build_outputs(root, mixed_case_adapter, mode = "production_aggregate", min_cell_count = 1L)
expect_true(any(grepl('"SDS_pato"', mixed_queries, fixed = TRUE)), "Mixed-case PATOBANK table should be quoted in generated SQL.")
expect_true(any(mixed_case$disease_state_person_counts$state_id == "pathology_mbl" & mixed_case$disease_state_person_counts$acceptance_status == "accepted"), "Resolved mixed-case PATOBANK table should produce accepted pathology-supported MBL rows.")
expect_true(any(mixed_case$source_resolution_audit$source_id == "SDS_pato" & mixed_case$source_resolution_audit$resolved_table == "SDS_pato"), "CONFLUENCE source resolution audit should expose resolved mixed-case PATOBANK table.")

small <- prod$disease_state_person_counts[prod$disease_state_person_counts$state_id == "cll_morphology_pressure", , drop = FALSE]
expect_true(any(small$count_display == "<5"), "Small cells should display threshold labels.")
expect_true(any(small$suppression_status == "suppressed small cell"), "Small cells should retain suppression status.")

merged <- confluence_count_merge_outputs(build_confluence_feasibility_outputs(project_root = root), prod)
expect_true("infection_rates" %in% names(merged), "Merged CONFLUENCE payload should include infection rates.")
expect_true(any(merged$production_execution_summary$value == "TRUE"), "Merged CONFLUENCE payload should carry production execution summary.")

tmp <- tempfile("confluence-production-")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- confluence_write_outputs(merged, tmp)
for (name in c(
  "disease_state_person_counts",
  "first_date_availability",
  "infection_endpoint_code_sets",
  "infection_counts",
  "recurrent_infection_counts",
  "infection_person_time",
  "infection_rates",
  "microbiology_confirmation_counts",
  "production_query_review",
  "failed_query_audit",
  "source_resolution_audit",
  "production_execution_summary"
)) {
  expect_true(name %in% names(paths), paste("CONFLUENCE writer should include:", name))
  expect_file(paths[[name]])
}

public_text <- paste(unlist(prod, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("\\bp[0-9]{2}\\b", public_text), "Public outputs must not emit fake patient identifiers.")
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", public_text), "Public outputs must not emit CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", public_text), "Public outputs must not emit raw dates.")
expect_false(grepl("raw pathology text|snippet|row preview", public_text, ignore.case = TRUE), "Public outputs must not emit raw free text or row previews.")

expect_equal(confluence_count_mode(NULL, mode = "plan"), "plan", "Explicit CONFLUENCE plan mode should disable production query execution.")
expect_equal(confluence_count_mode(fake_adapter, mode = "auto"), "production_aggregate", "CONFLUENCE auto mode should run when secure adapter is available.")
expect_equal(confluence_mcl_count_mode(NULL, mode = "plan"), "plan", "Explicit MCL plan mode should disable production query execution.")
expect_equal(confluence_mcl_count_mode(fake_adapter, mode = "auto"), "production_aggregate", "MCL auto mode helper should choose production when a secure adapter is available.")

source_text <- paste(readLines(file.path(root, "R", "confluence_counts.R"), warn = FALSE), collapse = "\n")
expect_false(grepl("starts_with\\(\"M9823\"", source_text), "Production CONFLUENCE counts must not use starts_with(\"M9823\") logic.")
expect_false(grepl("M9823%", source_text, fixed = TRUE), "Production CONFLUENCE counts must not use M9823 prefix SQL.")
expect_true(grepl("M98233", source_text, fixed = TRUE), "Production CONFLUENCE counts should explicitly handle M98233 as CLL morphology pressure.")

cat("CONFLUENCE production count tests passed\n")
