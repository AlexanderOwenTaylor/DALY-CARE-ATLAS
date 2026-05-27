root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)

reference_outputs_dir <- file.path(root, "DALYCARE_atlas_ki67_validation_cleanup_20260520_234114", "outputs")
if (!dir.exists(reference_outputs_dir)) reference_outputs_dir <- file.path(root, "outputs")

plan_outputs <- build_ki67_db_outputs(
  project_root = root,
  outputs_dir = reference_outputs_dir,
  mode = "plan",
  candidate_tables = c("pato", "t_mikro", "t_konk", "RKKP_LYFO"),
  full_scan = FALSE,
  min_cell_count = 5L,
  update_mcl = FALSE
)
expect_true(nrow(plan_outputs$search_plan) > 0, "Plan mode should create concrete Ki-67 candidate search-plan rows.")
expect_true(length(plan_outputs$query_templates) > 0, "Plan mode should create aggregate SQL/pseudo-SQL templates.")
query_text <- paste(plan_outputs$query_templates, collapse = "\n")
expect_false(grepl("select\\s+[*]", query_text, ignore.case = TRUE, perl = TRUE), "Ki-67 query templates must not use raw SELECT * previews.")
expect_false(grepl("\\blimit\\s+[0-9]+", query_text, ignore.case = TRUE, perl = TRUE), "Ki-67 query templates must not use raw LIMIT preview queries.")
expect_true(any(grepl("group by|count\\(", query_text, ignore.case = TRUE, perl = TRUE)), "Ki-67 query templates should be aggregate-only.")

script_text <- paste(readLines(file.path(root, "scripts", "find_ki67_in_production.R"), warn = FALSE), collapse = "\n")
expect_false(grepl("run_atlas\\s*\\(", script_text, perl = TRUE), "Direct Ki-67 finder must not invoke run_atlas().")
expect_false(grepl("R/run_atlas[.]R", script_text, fixed = FALSE), "Direct Ki-67 finder must not source the full atlas runner.")
expect_false(grepl("profile_sources|profile_table\\s*\\(|run_atlas_from_source", script_text, perl = TRUE), "Direct Ki-67 finder must not invoke full source profiling loops.")
expect_false(grepl("render_atlas|write_atlas_html|build_atlas_html", script_text, perl = TRUE), "Direct Ki-67 finder must not rebuild the full HTML payload.")

patobank_cases <- c("ÆKI000" = 0, "ÆKI005" = 5, "ÆKI020" = 20, "ÆKI100" = 100, "AEKI020" = 20)
for (code in names(patobank_cases)) {
  expect_equal(ki67_parse_patobank_numeric_percent(code), unname(as.numeric(patobank_cases[[code]])), paste("Unexpected parsed Ki-67 percent for", code))
}
for (code in c("ÆKI101", "ÆKI999", "ÆKI20", "ÆKI0200", "ÆK1020")) {
  expect_true(is.na(ki67_parse_patobank_numeric_percent(code)), paste("Invalid Ki-67 Patobank code should be rejected:", code))
}

dual <- ki67_dual_stain_code_info("FY5016")
expect_true(is.data.frame(dual) && nrow(dual) == 1L, "p16/Ki-67 dual-stain code should be classified separately.")
expect_equal(dual$value_class[[1]], "qualitative_mention_only", "p16/Ki-67 dual-stain code is qualitative, not numeric Ki-67 percent.")
expect_false(isTRUE(ki67_value_is_numeric_extractable(dual$value_class[[1]])), "p16/Ki-67 dual-stain code must not be numeric-extractable for MCL Ki-67.")

examples <- c(
  "Ki-67 20%" = "exact_numeric_percent",
  "Ki67 ca. 20%" = "exact_numeric_percent",
  "Ki-67 cirka 20 %" = "exact_numeric_percent",
  "MIB-1 index 35%" = "exact_numeric_percent",
  "proliferationsindeks på 15%" = "exact_numeric_percent",
  "Ki-67 < 10%" = "inequality_percent",
  "Ki-67 5-10%" = "range_percent",
  "Ki-67 positiv" = "qualitative_mention_only",
  "Ki-67 ikke angivet" = "unknown_or_not_stated"
)
for (txt in names(examples)) {
  expect_equal(ki67_classify_value(txt), examples[[txt]], paste("Unexpected Ki-67 text value class for:", txt))
}

small <- ki67_db_suppress_count(4, min_cell_count = 5L)
expect_equal(small$display, "<5", "Small aggregate counts should be suppressed by default.")
expect_true(small$suppressed, "Suppressed small aggregate counts should be flagged.")
large <- ki67_db_suppress_count(5, min_cell_count = 5L)
expect_equal(large$display, "5", "Counts meeting the threshold may be displayed exactly.")

no_db_outputs <- build_ki67_db_outputs(
  project_root = root,
  outputs_dir = tempfile("ki67_no_db_outputs_"),
  mode = "production_aggregate",
  candidate_tables = c("pato"),
  full_scan = FALSE,
  min_cell_count = 5L,
  update_mcl = FALSE,
  db_adapter = list(connections = list())
)
expect_true(any(no_db_outputs$aeki_code_counts$validation_status == "no_db_connection"), "Production aggregate mode should fail safely without DB credentials.")
expect_true(nrow(no_db_outputs$search_plan) > 0, "Production aggregate no-DB fallback should still write a query plan.")

alias_aeki <- data.frame(
  resource_id = c("SDS_pato", "pato", "SDS_dimpatologiskdiagnose"),
  schema = c("public", "public", "public"),
  table = c("SDS_pato", "SDS_pato", "SDS_dimpatologiskdiagnose"),
  column = c("c_snomedkode", "c_snomedkode", "diagnose_snomed_kode"),
  code = c("AEKI020", "AEKI020", "AEKI020"),
  parsed_percent = c("20", "20", "20"),
  aggregate_count = c("152", "152", "172"),
  distinct_patient_count_if_allowed = "",
  year_min_if_allowed = "",
  year_max_if_allowed = "",
  validation_status = "aggregate_count_available",
  notes = "Synthetic aggregate count.",
  stringsAsFactors = FALSE
)
alias_summary <- ki67_db_summary(alias_aeki, ki67_db_empty_p16_dual_stain_counts(), ki67_db_empty_text_pattern_counts(), ki67_db_empty_registry_field_counts())
alias_aeki_row <- alias_summary[alias_summary$channel == "danish_patobank_aeki_codes", , drop = FALSE]
expect_equal(as.integer(alias_aeki_row$physical_locations_found[[1]]), 2L, "AEKI aliases should deduplicate to physical schema/table/column locations.")
expect_equal(as.integer(alias_aeki_row$unique_numeric_percent_codes[[1]]), 1L, "Duplicate AEKI aliases should not inflate unique percent-code counts.")
expect_false(grepl("152; 172", alias_aeki_row$aggregate_count_total[[1]], fixed = TRUE), "AEKI summary should not use semicolon-list aggregate totals.")
alias_found <- ki67_db_found_locations(alias_summary, alias_aeki, ki67_db_empty_text_pattern_counts(), ki67_db_empty_registry_field_counts(), ki67_db_empty_p16_dual_stain_counts())
alias_locations <- alias_found[alias_found$evidence_channel == "danish_patobank_aeki_codes", , drop = FALSE]
expect_equal(nrow(alias_locations), 2L, "Found-location table should display physical AEKI columns, not alias/code duplicates.")

out_dir <- tempfile("ki67_direct_mcl_")
dir_create(out_dir)
write_csv(data.frame(
  study_requirement = "Ki-67",
  readiness_status = "weak_candidate_only",
  direct_variable_available = FALSE,
  proxy_available = FALSE,
  current_profiled_evidence = FALSE,
  legacy_reference_only_evidence = FALSE,
  preferred_source = "",
  candidate_fields_or_codes = "",
  key_limitation = "",
  recommended_next_action = "",
  stringsAsFactors = FALSE
), file.path(out_dir, "mcl_triangle_study_readiness_matrix.csv"))
write_csv(data.frame(
  marker = "Ki-67",
  direct_variable_found = FALSE,
  indirect_proxy_found = FALSE,
  current_profiled_source_available = FALSE,
  legacy_reference_only = FALSE,
  preferred_recovery_source = "",
  action_required = "",
  feasibility_status = "weak_candidate_only",
  notes = "",
  stringsAsFactors = FALSE
), file.path(out_dir, "mcl_triangle_biology_gap_analysis.csv"))
write_csv(data.frame(
  metric = "ki67_evidence_found",
  label = "Ki-67 evidence found",
  value = "weak_candidate_only",
  status = "weak_candidate_only",
  count_type = "derived verdict",
  evidence_count = 0L,
  notes = "",
  stringsAsFactors = FALSE
), file.path(out_dir, "mcl_triangle_feasibility_summary.csv"))
write_csv(data.frame(
  evidence_channel = "danish_pathology_code_evidence",
  channel_label = "Danish pathology code evidence / AEKIxxx",
  confirmed_hits = 0L,
  candidate_hits = 0L,
  source_space_hits = 0L,
  status = "requires_production_validation",
  next_validation_action = "",
  notes = "",
  stringsAsFactors = FALSE
), file.path(out_dir, "ki67_channel_summary.csv"))

direct_outputs <- list(
  summary = data.frame(
    channel = "danish_patobank_aeki_codes",
    direct_evidence_found = TRUE,
    numeric_percent_found = TRUE,
    aggregate_count_total = "<5",
    physical_locations_found = "2",
    unique_numeric_percent_codes = "51",
    non_suppressed_code_rows = "32",
    small_cell_suppressed_rows = "19",
    aggregate_count_display = "AEKI numeric Ki-67 code evidence found in 2 pathology code columns, covering 51 unique percent-code values. Exact small cells are suppressed.",
    best_source = "public.SDS_pato.c_snomedkode",
    evidence_strength = "strong_structured_coded",
    mcl_triangle_relevance = "numeric Danish Patobank Ki-67 code candidate",
    requires_manual_validation = TRUE,
    next_action = "Validate Danish Patobank local codebook and MCL applicability.",
    notes = "Synthetic aggregate evidence for test.",
    stringsAsFactors = FALSE
  )
)
updated <- ki67_db_apply_to_mcl_outputs(out_dir, direct_outputs)
expect_true(length(updated) >= 3L, "Direct aggregate evidence should update MCL/TRIANGLE summary tables.")
matrix <- read_delimited_file(file.path(out_dir, "mcl_triangle_study_readiness_matrix.csv"))
expect_equal(matrix$readiness_status[[1]], "strong_structured_coded", "Direct AEKI evidence should upgrade Ki-67 readiness to strong structured coded.")
expect_true(grepl("source-specific clinical validation", matrix$key_limitation[[1]], fixed = TRUE), "Direct AEKI readiness should retain validation-required wording.")
biology <- read_delimited_file(file.path(out_dir, "mcl_triangle_biology_gap_analysis.csv"))
expect_equal(biology$feasibility_status[[1]], "aggregate_evidence_found_requires_validation", "Direct aggregate Ki-67 evidence should not mark biology as ready before source validation.")

tmp_out <- tempfile("ki67_direct_plan_outputs_")
dir_create(tmp_out)
rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
cli_script <- file.path(root, "scripts", "find_ki67_in_production.R")
cli_project_root <- root
cli_tmp_out <- tmp_out
if (.Platform$OS.type == "windows") {
  cli_script <- utils::shortPathName(cli_script)
  cli_project_root <- utils::shortPathName(cli_project_root)
  cli_tmp_out <- utils::shortPathName(cli_tmp_out)
}
qarg <- function(x) if (.Platform$OS.type == "windows") shQuote(x, type = "cmd") else x
plan_result <- system2(
  rscript,
  c(qarg(cli_script), "--mode", "plan", "--project-root", qarg(cli_project_root), "--outputs-dir", qarg(cli_tmp_out), "--candidate-tables", "pato,t_mikro,t_konk,RKKP_LYFO"),
  stdout = TRUE,
  stderr = TRUE
)
plan_status <- attr(plan_result, "status") %||% 0L
expect_equal(as.integer(plan_status), 0L, paste(c("Ki-67 direct finder plan mode should run without DB credentials.", plan_result), collapse = "\n"))
for (file in c(
  "ki67_db_query_templates.sql",
  "ki67_db_search_plan.csv",
  "ki67_db_column_name_hits.csv",
  "ki67_db_aeki_code_counts.csv",
  "ki67_db_p16_dual_stain_counts.csv",
  "ki67_db_text_pattern_counts.csv",
  "ki67_db_registry_field_counts.csv",
  "ki67_db_summary.csv",
  "ki67_found_locations.csv"
)) {
  expect_file(file.path(tmp_out, file))
}
sql <- paste(readLines(file.path(tmp_out, "ki67_db_query_templates.sql"), warn = FALSE), collapse = "\n")
expect_false(grepl("select\\s+[*]|\\blimit\\s+[0-9]+", sql, ignore.case = TRUE, perl = TRUE), "Written query templates must not contain raw preview SQL.")
