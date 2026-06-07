root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expect_file(file.path(root, "config", "mcl_triangle_asct_hdt_evidence_sources.tsv"))

sources <- mcl_asct_read_evidence_sources(root)
expect_equal(names(sources), mcl_asct_required_evidence_source_columns(), "ASCT/HDT evidence-source config should keep the required public schema.")
expect_equal(nrow(sources), 15L, "ASCT/HDT evidence-source config should include the requested 15 source rows.")
expect_true(any(sources$source_id == "RKKP_LYFO_Beh_Stamcelleinfusion_dt" & sources$include_in_primary_asct == "TRUE"), "LYFO stem-cell infusion date should be primary ASCT/HDT evidence.")
expect_true(any(sources$source_id == "RKKP_LYFO_Rec_Stamcelleinfusion_dt" & sources$include_in_primary_asct == "FALSE"), "Relapse/recurrence ASCT must not be merged into first-line primary ASCT/HDT.")
expect_true(any(sources$source_id == "SDS_indberetningmedpris_ATC_L01AA03" & sources$include_in_sensitivity_asct == "TRUE" & sources$include_in_primary_asct == "FALSE"), "Melphalan should be sensitivity/validation evidence only.")
expect_true(any(sources$source_id == "SDS_t_sksube_ASCT_PROCEDURE_CANDIDATES" & grepl("Do not guess SKS codes", sources$notes, fixed = TRUE)), "Procedure rows should be inventory-only until exact ASCT/SCT SKS codes are validated.")

empty_source_resolution <- mcl_asct_empty_source_resolution()
expect_true(all(c(
  "asct_hdt_source_resolution",
  "asct_hdt_primary_vs_conditioning_counts",
  "asct_hdt_validation_matrix",
  "triangle_arm_proxy_counts",
  "asct_hdt_evidence_timing",
  "asct_hdt_protocol_runway"
) %in% names(mcl_count_empty_outputs())), "MCL count outputs should include ASCT/HDT evidence tables.")

lyfo <- data.frame(
  person_key = paste0("p", 1:10),
  subtype = rep("MCL", 10),
  Beh_Stamcelleinfusion_dt = rep("", 10),
  Beh_KemoterapiStart_dt = rep("2020-01-01", 10),
  Reg_BehandlingBeslutning_dt = rep("2019-12-15", 10),
  Beh_Hoejdosisbehandling = rep("", 10),
  Beh_TypeAutologStamcellestoette = rep("", 10),
  Rec_Stamcelleinfusion_dt = rep("", 10),
  Rec_Hoejdosisbehandling = rep("", 10),
  Beh_Kemoterapiregime1 = rep("", 10),
  Beh_Kemoterapiregime2 = rep("", 10),
  Beh_Kemoterapiregime3 = rep("", 10),
  btk_exposure = rep(FALSE, 10),
  stringsAsFactors = FALSE
)
lyfo$Beh_KemoterapiStart_dt[[1]] <- "2020-05-01"
lyfo$Beh_Stamcelleinfusion_dt[[1]] <- "2020-06-15"
lyfo$Beh_Hoejdosisbehandling[[1]] <- "Y"
lyfo$Beh_Kemoterapiregime1[[1]] <- "DHAP"
lyfo$Beh_Hoejdosisbehandling[[2]] <- "Y"
lyfo$Beh_Kemoterapiregime1[[4]] <- "DHAP"
lyfo$Beh_Kemoterapiregime1[[5]] <- "DHAP"
lyfo$btk_exposure[[5]] <- TRUE
lyfo$Beh_Stamcelleinfusion_dt[[6]] <- "2020-06-01"
lyfo$Beh_Kemoterapiregime1[[6]] <- "DHAP"
lyfo$btk_exposure[[6]] <- TRUE
lyfo$Beh_Stamcelleinfusion_dt[[7]] <- "2020-06-01"
lyfo$Beh_Kemoterapiregime1[[7]] <- "DHAP"
lyfo$Rec_Stamcelleinfusion_dt[[8]] <- "2021-03-01"
lyfo$Rec_Hoejdosisbehandling[[8]] <- "Y"
lyfo$Beh_TypeAutologStamcellestoette[[10]] <- "BCNU"

medication_events <- data.frame(
  person_key = c("p1", "p1", "p3"),
  code_value = c("L01AA03", "L01AD01", "L01AA03"),
  event_date = c("2020-06-10", "2020-06-11", "2020-05-01"),
  stringsAsFactors = FALSE
)

flags <- mcl_asct_derive_fixture_flags(lyfo, medication_events)
flag <- function(person, column) flags[flags$person_key == person, column, drop = TRUE][[1]]
expect_true(flag("p1", "asct_hdt_primary_lyfo"), "p1 should be primary LYFO ASCT/HDT.")
expect_true(flag("p1", "melphalan_near_stem_cell_infusion"), "p1 should have melphalan near stem-cell infusion.")
expect_true(flag("p1", "beam_multi_component_near_infusion"), "p1 should have BEAM multi-component validation support.")
expect_true(flag("p2", "asct_hdt_primary_lyfo"), "p2 should be primary LYFO ASCT/HDT without medication support.")
expect_false(flag("p3", "asct_hdt_primary_lyfo"), "p3 conditioning-only evidence should not become primary ASCT/HDT.")
expect_true(flag("p3", "melphalan_in_first_line_transplant_window"), "p3 should be a conditioning-only rescue candidate.")
expect_true(flag("p4", "triangle_induction_cytarabine_platinum_proxy"), "DHAP should be induction/protocol eligibility evidence.")
expect_false(flag("p4", "asct_hdt_primary_lyfo"), "DHAP alone must not define ASCT/HDT.")
expect_true(flag("p5", "triangle_btk_exposure_any"), "p5 should have BTKi evidence.")
expect_false(flag("p5", "asct_hdt_primary_lyfo"), "BTKi no-ASCT path should not be forced into missing ASCT.")
expect_true(flag("p6", "triangle_btk_exposure_any") && flag("p6", "asct_hdt_primary_lyfo"), "p6 should be BTKi plus primary LYFO ASCT/HDT.")
expect_true(flag("p7", "triangle_induction_cytarabine_platinum_proxy") && flag("p7", "asct_hdt_primary_lyfo"), "p7 should be legacy induction plus primary LYFO ASCT/HDT.")
expect_true(flag("p8", "asct_hdt_relapse_recurrence_lyfo"), "p8 should be relapse/recurrence ASCT/HDT.")
expect_false(flag("p8", "asct_hdt_primary_lyfo"), "Relapse/recurrence ASCT/HDT should stay separate from first-line primary ASCT/HDT.")

outputs <- mcl_asct_outputs_from_flags(flags, empty_source_resolution, min_cell_count = 1L)
display_count <- function(rows, id_col, id) {
  row <- rows[rows[[id_col]] == id, , drop = FALSE]
  expect_true(nrow(row) == 1L, paste("Expected one ASCT/HDT output row for", id))
  as.character(row$persons_n[[1]] %||% "")
}
expect_equal(display_count(outputs$asct_hdt_primary_vs_conditioning_counts, "state_id", "asct_hdt_primary_lyfo"), "5", "Primary LYFO ASCT/HDT count should use only Beh_* evidence.")
expect_equal(display_count(outputs$asct_hdt_primary_vs_conditioning_counts, "state_id", "asct_hdt_validated_by_conditioning"), "1", "Only p1 should validate primary LYFO ASCT/HDT by conditioning evidence.")
expect_equal(display_count(outputs$asct_hdt_primary_vs_conditioning_counts, "state_id", "asct_hdt_lyfo_only_no_conditioning_seen"), "4", "LYFO-only primary ASCT/HDT should remain visible.")
expect_equal(display_count(outputs$asct_hdt_primary_vs_conditioning_counts, "state_id", "asct_hdt_conditioning_rescue_candidate"), "1", "Conditioning-only rescue candidate should be sensitivity evidence.")
expect_equal(display_count(outputs$asct_hdt_primary_vs_conditioning_counts, "state_id", "asct_hdt_relapse_recurrence_lyfo"), "1", "Relapse/recurrence ASCT/HDT should be counted separately.")
expect_equal(display_count(outputs$asct_hdt_validation_matrix, "validation_cell", "LYFO_ASCT_no__melphalan_first_line_window_only"), "1", "Melphalan in first-line transplant window should be sensitivity only.")
expect_equal(display_count(outputs$asct_hdt_validation_matrix, "validation_cell", "relapse_ASCT_only"), "1", "Relapse-only ASCT should stay separate.")
expect_equal(display_count(outputs$asct_hdt_validation_matrix, "validation_cell", "no_ASCT_or_conditioning_evidence"), "3", "No-evidence fixtures should stay no-evidence.")
expect_equal(display_count(outputs$triangle_arm_proxy_counts, "arm_proxy_id", "triangle_btk_no_asct_arm_proxy"), "1", "BTKi plus induction and no primary ASCT should be counted as a no-ASCT BTKi arm proxy.")
expect_equal(display_count(outputs$triangle_arm_proxy_counts, "arm_proxy_id", "triangle_btk_plus_asct_arm_proxy"), "1", "BTKi plus induction plus primary ASCT should be counted separately.")
expect_equal(display_count(outputs$triangle_arm_proxy_counts, "arm_proxy_id", "legacy_asct_standard_proxy"), "2", "Legacy induction plus primary ASCT without BTKi should stay separate.")
expect_equal(display_count(outputs$triangle_arm_proxy_counts, "arm_proxy_id", "legacy_induction_no_asct_no_btk"), "1", "Induction without ASCT/BTKi should not be collapsed into the BTKi arm.")
expect_equal(display_count(outputs$asct_hdt_evidence_timing, "timing_id", "near_stem_cell_infusion"), "1", "Near-infusion validation window should count p1 only.")
expect_equal(display_count(outputs$asct_hdt_evidence_timing, "timing_id", "first_line_transplant_window"), "1", "First-line rescue window should count p3 only.")

small_outputs <- mcl_asct_outputs_from_flags(flags, empty_source_resolution, min_cell_count = 5L)
small_mel <- small_outputs$asct_hdt_primary_vs_conditioning_counts[
  small_outputs$asct_hdt_primary_vs_conditioning_counts$state_id == "melphalan_near_stem_cell_infusion",
  ,
  drop = FALSE
]
expect_equal(small_mel$persons_n[[1]], "<5", "Small ASCT/HDT support cells should be suppressed.")
expect_true(isTRUE(small_mel$suppressed_flag[[1]]), "Small ASCT/HDT support cells should carry a suppression flag.")

sp_admin <- sources[sources$source_id == "SP_AdministreretMedicin_ATC_L01AA03", , drop = FALSE]
fake_adapter <- list(
  mcl_triangle_query = function(sql) {
    if (grepl("count(*) as probe_count", sql, fixed = TRUE)) {
      return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
    }
    data.frame(patientid = integer(), stringsAsFactors = FALSE)
  }
)
resolution <- mcl_asct_source_resolution(sp_admin, mcl_count_read_person_date_mapping(root), fake_adapter)
expect_false(resolution$column_probe_success[[1]], "Source-resolution probe should fail closed when medication columns are absent.")
expect_false(resolution$usable_for_sensitivity_asct[[1]], "Missing medication columns must not contribute sensitivity ASCT/HDT evidence.")
expect_equal(resolution$resolution_status[[1]], "columns_missing_or_unreadable", "Missing medication columns should have a distinct source-resolution state.")
expect_false(resolution$qualifying_event_probe_success[[1]], "Qualifying-event probe should not run after a failed column probe.")
expect_equal(resolution$qualifying_event_count_status[[1]], "not_attempted", "Failed source probes should not report synthetic qualifying-event counts.")
expect_true(grepl("Missing source column", resolution$missing_reason[[1]], fixed = TRUE), "Missing column names should be visible in source resolution.")

melphalan_source <- sources[sources$source_id == "SDS_indberetningmedpris_ATC_L01AA03", , drop = FALSE]
melphalan_probe_adapter <- function(qualifying_people) {
  list(
    mcl_triangle_query = function(sql) {
      if (grepl("qualifying_people", sql, fixed = TRUE)) {
        return(data.frame(qualifying_people = qualifying_people, stringsAsFactors = FALSE))
      }
      if (grepl("SDS_indberetningmedpris", sql, fixed = TRUE) &&
          grepl("where false", sql, fixed = TRUE) &&
          !grepl("count(*) as probe_count", sql, fixed = TRUE)) {
        return(data.frame(
          patientid = integer(),
          c_atc = character(),
          d_ord_start = character(),
          d_adm = character(),
          stringsAsFactors = FALSE
        ))
      }
      if (grepl("count(*) as probe_count", sql, fixed = TRUE)) {
        return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
      }
      stop("Unexpected SQL in melphalan source-resolution test: ", substr(gsub("[[:space:]]+", " ", sql), 1, 180), call. = FALSE)
    }
  )
}
zero_resolution <- mcl_asct_source_resolution(
  melphalan_source,
  mcl_count_read_person_date_mapping(root),
  melphalan_probe_adapter(0L),
  min_cell_count = 5L
)
expect_equal(zero_resolution$resolution_status[[1]], "available_zero_qualifying_events", "Available medication sources with no exact aggregate events should be distinguishable.")
expect_true(zero_resolution$qualifying_event_probe_success[[1]], "Exact melphalan source should run an aggregate qualifying-event probe.")
expect_equal(zero_resolution$qualifying_event_count_status[[1]], "available_zero_qualifying_events", "Zero qualifying events should be explicit rather than a source failure.")
expect_equal(zero_resolution$qualifying_person_count_display[[1]], "0", "Zero qualifying events can be displayed without suppression.")
expect_true(zero_resolution$usable_for_sensitivity_asct[[1]], "Available exact melphalan sources remain sensitivity-only.")
expect_false(zero_resolution$usable_for_primary_asct[[1]], "Available exact melphalan sources must not become primary ASCT/HDT.")

positive_resolution <- mcl_asct_source_resolution(
  melphalan_source,
  mcl_count_read_person_date_mapping(root),
  melphalan_probe_adapter(7L),
  min_cell_count = 5L
)
expect_equal(positive_resolution$resolution_status[[1]], "available_with_qualifying_events", "Available medication sources with exact aggregate events should be distinguishable.")
expect_equal(positive_resolution$qualifying_event_count_status[[1]], "available_with_qualifying_events", "Positive qualifying-event aggregate status should be explicit.")
expect_equal(positive_resolution$qualifying_person_count_display[[1]], "7", "Non-small aggregate qualifying-event counts should display directly.")
expect_false(positive_resolution$qualifying_person_count_suppressed[[1]], "Non-small aggregate qualifying-event counts should not be suppressed.")
expect_true(positive_resolution$usable_for_sensitivity_asct[[1]], "Positive melphalan evidence remains sensitivity-only.")
expect_false(positive_resolution$usable_for_primary_asct[[1]], "Positive melphalan evidence must not inflate primary ASCT/HDT.")

procedure_source <- sources[sources$source_id == "SDS_t_sksube_ASCT_PROCEDURE_CANDIDATES", , drop = FALSE]
procedure_adapter <- list(
  mcl_triangle_query = function(sql) {
    if (grepl("qualifying_people", sql, fixed = TRUE)) {
      stop("CONFIG_REQUIRED procedure rows must not run qualifying-event classification queries.", call. = FALSE)
    }
    if (grepl("SDS_t_sksube", sql, fixed = TRUE) &&
        grepl("where false", sql, fixed = TRUE) &&
        !grepl("count(*) as probe_count", sql, fixed = TRUE)) {
      return(data.frame(v_recnum = character(), c_opr = character(), d_odto = character(), stringsAsFactors = FALSE))
    }
    if (grepl("SDS_t_adm", sql, fixed = TRUE) &&
        grepl("where false", sql, fixed = TRUE) &&
        !grepl("count(*) as probe_count", sql, fixed = TRUE)) {
      return(data.frame(k_recnum = character(), patientid = character(), stringsAsFactors = FALSE))
    }
    if (grepl("count(*) as probe_count", sql, fixed = TRUE)) {
      return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
    }
    stop("Unexpected SQL in procedure source-resolution test: ", substr(gsub("[[:space:]]+", " ", sql), 1, 180), call. = FALSE)
  }
)
procedure_resolution <- mcl_asct_source_resolution(
  procedure_source,
  mcl_count_read_person_date_mapping(root),
  procedure_adapter,
  min_cell_count = 5L
)
expect_equal(procedure_resolution$resolution_status[[1]], "inventory_only_code_validation_required", "CONFIG_REQUIRED SKS procedure candidates should remain inventory-only.")
expect_equal(procedure_resolution$qualifying_event_count_status[[1]], "inventory_only_code_validation_required", "CONFIG_REQUIRED procedure rows should not emit qualifying ASCT event counts.")
expect_false(procedure_resolution$qualifying_event_probe_success[[1]], "CONFIG_REQUIRED procedure rows should not run qualifying-event probes.")
expect_false(procedure_resolution$usable_for_primary_asct[[1]], "CONFIG_REQUIRED procedure rows must not classify primary ASCT/HDT.")
expect_false(procedure_resolution$usable_for_sensitivity_asct[[1]], "CONFIG_REQUIRED procedure rows must not classify sensitivity ASCT/HDT.")

tmp <- tempfile("mcl_asct_outputs_")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- mcl_asct_write_outputs(outputs, tmp)
for (path in unlist(paths, use.names = FALSE)) expect_file(path)
for (path in unlist(paths, use.names = FALSE)) {
  output_text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl("\\bp[0-9]+\\b|\\bcpr\\b|personnummer", output_text, ignore.case = TRUE, perl = TRUE), "ASCT/HDT evidence outputs must not emit identifier-like values.")
  expect_false(grepl("(^|,|\\n)(person_key|medication_name|resulttextvalue|v_fritekst|OBS_DIAGNOSIS|PHENOTYPE|CONCLUSION|POPULATION)(,|\\n|$)", output_text, ignore.case = TRUE, perl = TRUE), "ASCT/HDT evidence outputs must not emit raw identifier or clinical-text field cells.")
}

fake_sets <- list(
  all_lyfo_mcl = paste0("p", 1:10),
  asct_hdt_first_line = c("p1", "p2"),
  ibrutinib_exposure = c("p2", "p5"),
  cit_immunochemotherapy = c("p1", "p2", "p5")
)
count_hook_adapter <- list(
  mcl_triangle_count_sets = function(min_cell_count = 5L) list(sets = fake_sets)
)
built <- mcl_count_build_outputs(
  project_root = root,
  mode = "production_aggregate",
  db_adapter = count_hook_adapter,
  min_cell_count = 1L
)
alias_row <- built$data_point_counts[built$data_point_counts$data_point_id == "asct_hdt_primary_lyfo", , drop = FALSE]
legacy_row <- built$data_point_counts[built$data_point_counts$data_point_id == "asct_hdt_first_line", , drop = FALSE]
expect_equal(alias_row$distinct_person_count_display[[1]], "2", "asct_hdt_primary_lyfo should remain available as a direct data-point alias.")
expect_equal(legacy_row$distinct_person_count_display[[1]], "2", "Legacy asct_hdt_first_line should remain available.")
expect_true(nrow(built$asct_hdt_primary_vs_conditioning_counts) > 0, "Count builder should produce ASCT/HDT primary-vs-conditioning outputs.")
expect_true(any(built$triangle_arm_proxy_counts$arm_proxy_id == "triangle_btk_no_asct_arm_proxy"), "Count builder should produce TRIANGLE no-ASCT BTKi arm proxy rows.")
