root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)
source(file.path(root, "R", "mcl_triangle_counts.R"))

expect_file(file.path(root, "clinical_questions", "mcl_triangle_count_definitions.yml"))
expect_file(file.path(root, "config", "mcl_triangle_person_date_mapping.tsv"))
expect_file(file.path(root, "config", "mcl_triangle_count_value_mappings.tsv"))
expect_file(file.path(root, "RUN_MCL_TRIANGLE_COUNTS.R"))
expect_file(file.path(root, "scripts", "source_mcl_triangle_counts.R"))

full_atlas_zip <- Sys.getenv("MCL_COUNT_FULL_ATLAS_ZIP", "")
if (!nzchar(full_atlas_zip)) full_atlas_zip <- "C:/Users/User/Music/2026.05.20 14.00 ATLAS output.zip"
if (file.exists(full_atlas_zip)) {
  imported <- mcl_count_import_full_atlas_predicates(root, full_atlas_zip)
  expect_true(any(imported$data_point_id == "all_lyfo_mcl" & imported$field == "subtype" & imported$value == "MCL"), "Full-atlas importer should confirm the LYFO MCL subtype predicate.")
  expect_true(any(imported$data_point_id == "cit_immunochemotherapy" & imported$value == "Y"), "Full-atlas importer should confirm LYFO Y/N chemotherapy evidence.")
  expect_true(any(imported$data_point_id == "ibrutinib_exposure" & grepl("ibrutinib", imported$value, ignore.case = TRUE)), "Full-atlas importer should surface LYFO ibrutinib regimen evidence.")
}

defs <- mcl_count_read_definitions(root)
expect_true(all(c("all_lyfo_mcl", "younger_mcl_proxy_age_le_65", "asct_hdt_first_line", "asct_hdt_relapse_recurrence", "ki67_aeki") %in% defs$data_point_id), "Count definitions should include required MCL/TRIANGLE data points.")
expect_false(any(defs$data_point_id == "younger_mcl_proxy_age_le_65" & grepl("^transplant eligible$", defs$clinical_label, ignore.case = TRUE)), "Age <=65 must not be labelled as transplant eligibility by itself.")

fake_sets <- list(
  all_lyfo_mcl = paste0("p", 1:12),
  younger_mcl_proxy_age_le_65 = paste0("p", 1:9),
  diagnosis_date = paste0("p", 1:12),
  first_line_treatment_date = paste0("p", 1:10),
  cit_immunochemotherapy = paste0("p", c(1:8, 11)),
  asct_hdt_first_line = paste0("p", c(1, 2, 3, 4, 5, 10)),
  asct_hdt_relapse_recurrence = paste0("p", c(9, 10, 11)),
  ibrutinib_exposure = paste0("p", c(2, 3, 4, 5, 6)),
  os_death = paste0("p", 1:11),
  relapse_progression_ffs_proxy = paste0("p", c(1:7, 12)),
  ki67_aeki = paste0("p", c(1, 2, 3, 4, 5, 6, 10)),
  tp53_p53_del17p = paste0("p", c(1, 2, 5, 6, 7)),
  blastoid_pleomorphic_morphology = paste0("p", c(3, 4, 5)),
  mipi_mipic_components = paste0("p", 1:6),
  toxicity_proxies = paste0("p", c(1, 2, 3, 4)),
  alive_at_landmark = paste0("p", 1:8),
  event_free_pre_landmark = paste0("p", c(1, 2, 3, 4, 6, 7)),
  asct_hdt_status_known_landmark = paste0("p", 1:7),
  ibrutinib_status_known_landmark = paste0("p", 2:8),
  high_risk_biology_pre_landmark = paste0("p", c(1, 2, 3, 4, 5))
)
fake_adapter <- list(
  mcl_triangle_count_sets = function(min_cell_count = 5L) {
    list(
      sets = fake_sets,
      ki67_percent_counts = data.frame(
        code = c("AEKI020", "AEKI080"),
        parsed_percent = c(20, 80),
        aggregate_count = c(6, 1),
        stringsAsFactors = FALSE
      )
    )
  }
)

out <- mcl_count_build_outputs(
  project_root = root,
  mode = "production_aggregate",
  db_adapter = fake_adapter,
  min_cell_count = 5L
)

audit <- out$person_key_audit
expect_true(nrow(audit) > 0, "Person-key audit should be generated.")
expect_true(all(audit$usable_for_distinct_person_counts), "Fake aggregate count hook should mark source person keys usable.")

counts <- out$data_point_counts
mcl_row <- counts[counts$data_point_id == "all_lyfo_mcl", , drop = FALSE]
young_row <- counts[counts$data_point_id == "younger_mcl_proxy_age_le_65", , drop = FALSE]
asct_row <- counts[counts$data_point_id == "asct_hdt_first_line", , drop = FALSE]
rec_row <- counts[counts$data_point_id == "asct_hdt_relapse_recurrence", , drop = FALSE]
ki67_row <- counts[counts$data_point_id == "ki67_aeki", , drop = FALSE]
expect_equal(mcl_row$distinct_person_count_display[[1]], "12", "All-MCL denominator should count distinct people.")
expect_equal(young_row$distinct_person_count_display[[1]], "9", "Younger proxy denominator should count distinct people.")
expect_true(grepl("Beh_", asct_row$source_locations[[1]], fixed = TRUE), "First-line ASCT/HDT counts should prioritize LYFO Beh_* fields.")
expect_true(grepl("Rec_", rec_row$source_locations[[1]], fixed = TRUE), "Relapse ASCT/HDT counts should be labelled with LYFO Rec_* fields.")
expect_equal(ki67_row$distinct_person_count_display[[1]], "7", "Ki-67 AEKI counts should be person-level aggregates, not code-row counts.")

small_row <- counts[counts$data_point_id == "toxicity_proxies", , drop = FALSE]
expect_equal(small_row$count_status[[1]], "suppressed_small_cell", "Small-cell person counts should be suppressed.")
expect_equal(small_row$distinct_person_count_display[[1]], "<5", "Small-cell display should not reveal exact counts.")

waterfall_counts <- suppressWarnings(as.numeric(gsub(",", "", out$inclusion_waterfall$distinct_person_count_display)))
expect_true(all(diff(waterfall_counts[!is.na(waterfall_counts)]) <= 0), "Waterfall counts should be monotonic.")

overlap_counts <- suppressWarnings(as.numeric(gsub(",", "", out$overlap_matrix$distinct_person_count_display)))
expect_true(all(overlap_counts[!is.na(overlap_counts)] <= 12), "Overlap counts must not exceed the all-MCL denominator.")

strata_text <- paste(out$exposure_strata_counts$notes, collapse = " ")
expect_true(grepl("Descriptive feasibility stratum only", strata_text, fixed = TRUE), "Exposure strata must be labelled descriptive feasibility only.")

query_templates <- out$query_templates
expect_false(grepl("SELECT \\*|LIMIT 10", query_templates, ignore.case = TRUE, perl = TRUE), "Count SQL templates must not use raw-row previews.")

tmp <- tempfile("mcl_counts_")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- mcl_count_write_outputs(out, tmp)
for (path in unlist(paths, use.names = FALSE)) expect_file(path)
expect_file(file.path(tmp, "mcl_triangle_age_source_locator.csv"))
expect_file(file.path(tmp, "mcl_triangle_execution_summary.csv"))
execution_summary <- read_delimited_file(file.path(tmp, "mcl_triangle_execution_summary.csv"))
expect_true(all(c("mode", "db_connection_attempted", "db_connection_available", "executable_queries", "executed_queries", "failed_queries", "populated_count_outputs", "populated_intersection_outputs", "production_aggregate_succeeded", "failure_reason") %in% names(execution_summary)), "Execution summary should expose standalone production progress fields.")
generation_status <- read_delimited_file(file.path(tmp, "output_generation_status.csv"))
expect_true(all(c("output_file", "generated_after_latest_mapping_change", "mode", "stale", "notes") %in% names(generation_status)), "Output generation status should expose freshness fields.")
expect_true(any(generation_status$output_file == "mcl_triangle_data_point_counts.csv" & generation_status$stale == FALSE), "Freshly written count outputs should be marked fresh after resolver/count mapping changes.")
expect_true(any(generation_status$output_file == "mcl_triangle_execution_summary.csv" & generation_status$stale == FALSE), "Execution summary should be listed in output freshness status.")
all_output_text <- paste(vapply(list.files(tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("010101|\\bcpr\\b|personnummer|raw snippet|SELECT \\*|LIMIT 10", all_output_text, ignore.case = TRUE, perl = TRUE), "Count outputs must not emit patient identifiers, raw snippets, or raw preview SQL.")

plan_out <- mcl_count_build_outputs(project_root = root, mode = "plan", min_cell_count = 5L)
expect_true(all(plan_out$data_point_counts$count_status %in% c(
  "query_executable_not_run",
  "count_not_available_requires_production_validation",
  "count_not_available_requires_patient_demographics_mapping",
  "count_not_available_requires_person_key_mapping",
  "count_not_available_requires_patient_demographics_mapping",
  "count_not_available_requires_date_mapping",
  "count_not_available_requires_value_mapping"
)), "Plan mode should not invent distinct-person counts.")
expect_true(all(!nzchar(plan_out$data_point_counts$distinct_person_count_display)), "Plan mode should leave distinct-person count displays empty.")
expect_true(any(plan_out$person_key_audit$usable_for_distinct_person_counts == FALSE), "Plan mode should audit missing person-key mapping.")
expect_true("value_rule_used" %in% names(plan_out$query_review), "Query review should record the value rule used for each planned count.")
expect_true(all(c("count_mode", "source_tables", "person_key_used", "date_anchor_used", "value_rule_used", "generated_at", "validation_status") %in% names(plan_out$data_point_counts)), "Count rows should carry mode, mapping, and validation provenance.")
expect_true(any(plan_out$data_point_counts$count_status == "count_not_available_requires_value_mapping"), "Unconfirmed MCL subtype/value semantics should be reported as a value-mapping gap.")
expect_false(grepl("<person_key>|<validated_mcl_predicate>|<validated_rule_for_", plan_out$query_templates, fixed = FALSE, perl = TRUE), "Plan SQL must not contain executable-looking unresolved placeholders.")
non_exec_sections <- unlist(strsplit(plan_out$query_templates, "-- query_id: ", fixed = TRUE), use.names = FALSE)
non_exec_sections <- non_exec_sections[grepl("NOT EXECUTABLE", non_exec_sections, fixed = TRUE)]
expect_true(all(grepl("\n-- NOT EXECUTABLE: requires mapping for |\n-- NOT EXECUTABLE: requires patient demographics mapping", paste0("\n", non_exec_sections), perl = TRUE)), "Non-executable SQL sections must be clearly labelled.")

minimal_root <- tempfile("mcl_count_minimal_root_")
dir.create(minimal_root, recursive = TRUE, showWarnings = FALSE)
minimal_out <- mcl_count_build_outputs(project_root = minimal_root, mode = "plan", min_cell_count = 5L)
expect_true(nrow(minimal_out$data_point_counts) > 0, "Missing mapping/config files should produce explicit unavailable rows, not an empty-data-frame assignment error.")
expect_true(all(minimal_out$data_point_counts$count_status %in% c(
  "count_not_available_requires_person_key_mapping",
  "count_not_available_requires_date_mapping",
  "count_not_available_requires_value_mapping",
  "count_not_available_requires_production_validation",
  "query_executable_not_run"
)), "Minimal package plan mode should fail closed with explicit mapping statuses.")

profile_dir <- tempfile("mcl_count_column_profiles_")
dir.create(profile_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(data.frame(
  table_name = c(
    "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO",
    "SDS_pato", "SDS_pato", "patient", "patient"
  ),
  column_name = c(
    "patientid", "Reg_DiagnostiskBiopsi_dt", "Beh_KemoterapiStart_dt", "FU_Doedsdato",
    "patientid", "d_svardato", "patientid", "date_death_fu"
  ),
  column_type = c("integer", "text", "text", "text", "integer", "timestamp", "integer", "date"),
  column_class = c("int4", "text", "text", "text", "int4", "timestamp", "int4", "date"),
  n_missing = "",
  pct_missing = "",
  n_distinct_capped = "",
  is_sensitive = c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, FALSE),
  is_date_like = c(FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, TRUE),
  is_numeric_like = FALSE,
  stringsAsFactors = FALSE
), file.path(profile_dir, "atlas_columns.csv"))
profile_plan <- mcl_count_build_outputs(project_root = root, outputs_dir = profile_dir, mode = "plan", min_cell_count = 5L)
lyfo_audit <- profile_plan$person_key_audit[profile_plan$person_key_audit$table == "RKKP_LYFO", , drop = FALSE]
pato_audit <- profile_plan$person_key_audit[profile_plan$person_key_audit$table == "SDS_pato", , drop = FALSE]
expect_equal(lyfo_audit$selected_person_id_column[[1]], "patientid", "Column profiles should resolve RKKP_LYFO patientid as a candidate person key.")
expect_equal(pato_audit$selected_person_id_column[[1]], "patientid", "Column profiles should resolve SDS_pato patientid as a candidate person key.")
expect_true(any(profile_plan$person_key_audit$usable_for_distinct_person_counts), "Column-profile person keys should be audit-usable for production aggregate planning.")
expect_true(any(profile_plan$query_review$query_executable), "Validated config seeded from full-atlas value evidence should make mapped SQL templates executable.")
expect_true(any(profile_plan$data_point_counts$count_status == "query_executable_not_run"), "Mapped plan-mode queries should be explicitly marked executable but not run.")

write_csv(data.frame(
  source = "RKKP_LYFO",
  raw_field = "subtype",
  code_or_value = "MCL",
  concept_name = "Mantle cell lymphoma cohort",
  stringsAsFactors = FALSE
), file.path(profile_dir, "mcl_triangle_variable_inventory.csv"))
profile_validated <- mcl_count_build_outputs(project_root = root, outputs_dir = profile_dir, mode = "plan", min_cell_count = 5L)
expect_true(any(profile_validated$query_review$query_executable), "Confirmed subtype metadata should make mapped aggregate SQL templates executable for mapped data points.")
expect_true(grepl("patientid", profile_validated$query_templates, fixed = TRUE), "Executable count query templates should use validated mapped person keys.")
expect_true(grepl("Reg_DiagnostiskBiopsi_dt|Reg_BehandlingBeslutning_dt|Beh_KemoterapiStart_dt", profile_validated$query_templates, perl = TRUE), "Executable count query templates should show configured date anchors.")
expect_true(any(profile_validated$data_point_counts$count_status == "query_executable_not_run"), "Executable plan-mode queries should be explicitly marked as mapped but not run.")
asct_sql_section <- unlist(strsplit(profile_validated$query_templates, "-- query_id: ", fixed = TRUE), use.names = FALSE)
asct_sql_section <- asct_sql_section[grepl("^mcl_triangle_asct_hdt_first_line\\b", asct_sql_section)]
expect_true(length(asct_sql_section) == 1L && !grepl('"public"."view_patient_table_os"', asct_sql_section[[1]], fixed = TRUE), "All-MCL treatment marginal counts should not be blocked by the younger-proxy patient demographic join.")
young_sql_section <- unlist(strsplit(profile_validated$query_templates, "-- query_id: ", fixed = TRUE), use.names = FALSE)
young_sql_section <- young_sql_section[grepl("^mcl_triangle_younger_mcl_proxy_age_le_65\\b", young_sql_section)]
expect_true(length(young_sql_section) == 1L && grepl("-- NOT EXECUTABLE: requires patient demographics mapping", young_sql_section[[1]], fixed = TRUE), "Plan mode should not emit executable age SQL unless a patient demographics relation was verified by the resolver.")
expect_false(grepl('"public"."patient"', profile_validated$query_templates, fixed = TRUE), "Production count templates must not join public.patient, which is absent in the reviewed production output.")

fake_info_adapter <- function(columns, relation_fail_tables = character(), column_fail_tables = character(),
                              relation_wrong_shape_tables = character(), column_wrong_shape_tables = character(),
                              co_fail_tables = character()) {
  force(columns)
  force(relation_fail_tables)
  force(column_fail_tables)
  force(relation_wrong_shape_tables)
  force(column_wrong_shape_tables)
  force(co_fail_tables)
  list(
    mcl_triangle_query = function(sql) {
      if (grepl("current_database\\(\\)", sql)) {
        return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
      }
      if (grepl("information_schema[.]columns", sql)) {
        return(columns)
      }
      for (tbl in co_fail_tables) {
        if (grepl('"RKKP_LYFO"', sql, fixed = TRUE) &&
            grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) &&
            grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          stop(paste("relation", tbl, "cannot join to LYFO; token=secret"))
        }
      }
      for (tbl in relation_fail_tables) {
        if (grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) && grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          stop(paste("relation", tbl, "does not exist; password=secret"))
        }
      }
      for (tbl in column_fail_tables) {
        if (grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) && grepl('select "patientid", "date_birth"', sql, fixed = TRUE)) {
          stop(paste("column date_birth missing on", tbl, "token=secret"))
        }
      }
      for (tbl in relation_wrong_shape_tables) {
        if (grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) && grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          return(data.frame(distinct_person_count = 10, stringsAsFactors = FALSE))
        }
      }
      for (tbl in column_wrong_shape_tables) {
        if (grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) && grepl('select "patientid", "date_birth"', sql, fixed = TRUE)) {
          return(data.frame(distinct_person_count = integer(), stringsAsFactors = FALSE))
        }
      }
      if (grepl("where false", sql, fixed = TRUE)) {
        if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
        }
        return(data.frame(patientid = integer(), date_birth = character(), birth_date = character(), subtype = character(), age_at_diagnosis = numeric(), current_age = numeric(), stringsAsFactors = FALSE))
      }
      data.frame(distinct_person_count = 10, stringsAsFactors = FALSE)
    }
  )
}

fake_age_source_adapter <- function(columns, numeric_ok = TRUE, younger_count = 24L, co_fail_tables = character()) {
  force(columns)
  force(numeric_ok)
  force(younger_count)
  force(co_fail_tables)
  list(
    mcl_triangle_query = function(sql) {
      if (grepl("current_database\\(\\)", sql)) {
        return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
      }
      if (grepl("information_schema[.]columns", sql)) {
        return(columns)
      }
      for (tbl in co_fail_tables) {
        if (grepl('"RKKP_LYFO"', sql, fixed = TRUE) &&
            grepl(paste0('"', tbl, '"'), sql, fixed = TRUE) &&
            grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          stop(paste("birth-date source", tbl, "cannot join to LYFO; token=secret"))
        }
      }
      if (grepl("where false", sql, fixed = TRUE)) {
        if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
        }
        return(data.frame(patientid = integer(), date_birth = character(), birth_date = character(), subtype = character(), age_at_diagnosis = numeric(), current_age = numeric(), stringsAsFactors = FALSE))
      }
      if (grepl("numeric_age_count", sql, fixed = TRUE)) {
        return(data.frame(
          mcl_row_count = 30L,
          numeric_age_count = 24L,
          plausible_age_count = if (isTRUE(numeric_ok)) 24L else 20L,
          stringsAsFactors = FALSE
        ))
      }
      data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", gsub("\n", " ", sql), perl = TRUE)
      value <- switch(
        data_point,
        younger_mcl_proxy_age_le_65 = younger_count,
        age_anchor_available = 24L,
        age_computable = 24L,
        age_gt_65 = 6L,
        age_missing_uncomputable = 0L,
        all_lyfo_mcl = 30L,
        cit_immunochemotherapy = 20L,
        asct_hdt_first_line = 10L,
        ibrutinib_exposure = 12L,
        ki67_aeki = 8L,
        10L
      )
      data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
    }
  )
}

fake_multi_db_age_adapter <- function(unstable_birth = FALSE) {
  force(unstable_birth)
  info_cols <- data.frame(
    db_name = c(
      rep("core", 3),
      rep("import", 6),
      rep("import", 5),
      rep("import", 3)
    ),
    schema = "public",
    table = c(
      rep("patient", 3),
      rep("RKKP_LYFO", 6),
      rep("SDS_t_tumor", 5),
      rep("SDS_pato", 3)
    ),
    column_name = c(
      "patientid", "date_birth", "date_death_fu",
      "patientid", "subtype", "Reg_BehandlingBeslutning_dt", "Beh_KemoterapiStart_dt", "Reg_DiagnostiskBiopsi_dt", "Beh_Hoejdosisbehandling",
      "patientid", "d_fdsdato", "v_diagnosealder", "d_diagnosedato", "c_icd10",
      "patientid", "d_svardato", "c_snomedkode"
    ),
    data_type = c(
      "integer", "date", "date",
      "integer", "text", "date", "date", "date", "text",
      "integer", "date", "numeric", "date", "text",
      "integer", "date", "text"
    ),
    stringsAsFactors = FALSE
  )
  list(
    mcl_triangle_query_all_connections = function(sql) {
      if (grepl("information_schema[.]columns", sql)) return(info_cols)
      data.frame(stringsAsFactors = FALSE)
    },
    mcl_triangle_query = function(sql) {
      compact_sql <- gsub("\n", " ", sql)
      if (grepl("current_database\\(\\)", sql)) {
        return(data.frame(database_name = "import", search_path = "public", stringsAsFactors = FALSE))
      }
      if (grepl("where false", sql, fixed = TRUE)) {
        if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
        }
        return(data.frame(
          patientid = integer(),
          date_birth = character(),
          date_death_fu = character(),
          d_fdsdato = character(),
          subtype = character(),
          Reg_BehandlingBeslutning_dt = character(),
          Beh_KemoterapiStart_dt = character(),
          Reg_DiagnostiskBiopsi_dt = character(),
          stringsAsFactors = FALSE
        ))
      }
      if (grepl("people_with_birth_date", sql, fixed = TRUE) &&
          grepl("people_with_multiple_birth_dates", sql, fixed = TRUE)) {
        return(data.frame(
          mcl_people = 100L,
          people_with_birth_date = 95L,
          people_with_age_anchor = 90L,
          people_with_plausible_age = if (isTRUE(unstable_birth)) 88L else 89L,
          people_with_multiple_birth_dates = if (isTRUE(unstable_birth)) 2L else 0L,
          age_le_65_people = 55L,
          age_gt_65_people = 34L,
          age_missing_or_uncomputable_people = if (isTRUE(unstable_birth)) 12L else 11L,
          stringsAsFactors = FALSE
        ))
      }
      if (grepl("as intersection_id", sql, fixed = TRUE)) {
        intersection_id <- sub(".*select '([^']+)' as intersection_id.*", "\\1", compact_sql, perl = TRUE)
        value <- switch(
          intersection_id,
          all_lyfo_mcl__asct_hdt_first_line__ibrutinib_exposure = 9L,
          age_le_65_mcl__asct_hdt_first_line__ibrutinib_exposure = 6L,
          age_le_65_ibrutinib_yes_asct_yes = 6L,
          ibrutinib_exposure__asct_hdt_first_line = 9L,
          8L
        )
        return(data.frame(intersection_id = intersection_id, distinct_person_count = value, stringsAsFactors = FALSE))
      }
      data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", compact_sql, perl = TRUE)
      value <- switch(
        data_point,
        all_lyfo_mcl = 100L,
        younger_mcl_proxy_age_le_65 = 55L,
        birth_date_available = 95L,
        age_anchor_available = 90L,
        age_computable = 89L,
        age_gt_65 = 34L,
        age_missing_uncomputable = 11L,
        diagnosis_date = 100L,
        first_line_treatment_date = 90L,
        cit_immunochemotherapy = 70L,
        asct_hdt_first_line = 30L,
        asct_hdt_relapse_recurrence = 7L,
        ibrutinib_exposure = 20L,
        os_death = 40L,
        relapse_progression_ffs_proxy = 25L,
        ki67_aeki = 12L,
        mipi_mipic_components = 100L,
        10L
      )
      data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
    }
  )
}

write_mcl_triangle_metadata <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  write_csv(data.frame(
    source = c(rep("RKKP_LYFO", 6), "SDS_pato"),
    raw_field = c("subtype", "Beh_ErDerForetagetKemo", "Beh_Kemoterapiregime1", "Beh_Hoejdosisbehandling", "FU_LeverPatienten", "Rec_RelapsProgressions_dt", "c_snomedkode"),
    code_or_value = c("MCL", "Y", "IBRUTINIB", "Y", "N", "non_missing_valid_date", "AEKI030"),
    concept_name = c("Mantle cell lymphoma cohort", "Chemotherapy performed", "Ibrutinib regimen", "First-line ASCT/HDT", "Death/status proxy", "Relapse/progression proxy", "Ki-67 AEKI"),
    stringsAsFactors = FALSE
  ), file.path(path, "mcl_triangle_variable_inventory.csv"))
}

configured_cols <- data.frame(
  schema = "public",
  table = "view_patient_table_os",
  column_name = c("patientid", "date_birth", "date_death_fu"),
  stringsAsFactors = FALSE
)
configured_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_true(any(configured_resolver$selected & configured_resolver$table == "view_patient_table_os"), "Configured patient demographics relation should be selected only after information-schema verification.")
expect_true(all(c("database_name", "search_path", "verified_at", "verification_mode", "relation_probe_success", "column_probe_success", "co_residency_probe_success") %in% names(configured_resolver)), "Resolver output should include database/schema verification and probe context.")
configured_selected <- configured_resolver[configured_resolver$selected, , drop = FALSE]
expect_true(configured_selected$relation_probe_success[[1]] && configured_selected$column_probe_success[[1]] && configured_selected$co_residency_probe_success[[1]], "Configured patient demographics relation should require standalone and LYFO co-residency probes before selection.")

co_fail_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols, co_fail_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
co_fail_row <- co_fail_resolver[co_fail_resolver$table == "view_patient_table_os", , drop = FALSE]
expect_false(any(co_fail_row$selected), "Standalone relation/column probes are not enough when the relation cannot join to LYFO.")
expect_true(any(co_fail_row$reason == "co_residency_probe_failed"), "LYFO co-residency probe failures should be recorded explicitly.")
expect_true(co_fail_row$relation_probe_success[[1]] && co_fail_row$column_probe_success[[1]], "Co-residency failure should preserve successful standalone probe provenance.")
expect_false(co_fail_row$co_residency_probe_success[[1]], "Co-residency probe success must be false when the LYFO join probe fails.")
expect_false(grepl("secret", paste(co_fail_row$co_residency_probe_error_sanitized, collapse = " "), fixed = TRUE), "Co-residency probe errors should be sanitized.")
co_fail_tmp <- tempfile("mcl_count_co_residency_status_")
dir.create(co_fail_tmp, recursive = TRUE, showWarnings = FALSE)
co_fail_path <- write_csv(co_fail_resolver, file.path(co_fail_tmp, "mcl_triangle_patient_demographics_resolver.csv"))
co_fail_status <- mcl_count_output_generation_status(
  co_fail_tmp,
  list(patient_demographics_resolver = co_fail_path),
  mode = "production_aggregate",
  latest_mapping_change = Sys.time() - 3600,
  patient_demographics_resolver = co_fail_resolver
)
expect_false(any(co_fail_status$stale), "Current co-residency probe failures should be fresh resolver audit evidence, not stale-output warnings.")

relation_fail_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols, relation_fail_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_false(any(relation_fail_resolver$selected & relation_fail_resolver$table == "view_patient_table_os"), "Information-schema candidates must not be selected when the relation probe fails.")
expect_true(any(relation_fail_resolver$reason == "relation_probe_failed"), "Relation-probe failures should be recorded explicitly.")
expect_false(grepl("secret", paste(relation_fail_resolver$relation_probe_error_sanitized, collapse = " "), fixed = TRUE), "Relation-probe errors should be sanitized.")

column_fail_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols, column_fail_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_false(any(column_fail_resolver$selected & column_fail_resolver$table == "view_patient_table_os"), "Information-schema candidates must not be selected when the column-reference probe fails.")
expect_true(any(column_fail_resolver$reason == "column_probe_failed"), "Column-probe failures should be recorded explicitly.")
expect_false(grepl("secret", paste(column_fail_resolver$column_probe_error_sanitized, collapse = " "), fixed = TRUE), "Column-probe errors should be sanitized.")

wrong_shape_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols, relation_wrong_shape_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_false(any(wrong_shape_resolver$selected & wrong_shape_resolver$table == "view_patient_table_os"), "Probe success should require the relation probe to return the expected aggregate probe_count shape.")
expect_true(any(grepl("unexpected result shape", wrong_shape_resolver$relation_probe_error_sanitized, fixed = TRUE)), "Unexpected relation-probe result shapes should be audited.")

wrong_column_shape_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(configured_cols, column_wrong_shape_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_false(any(wrong_column_shape_resolver$selected & wrong_column_shape_resolver$table == "view_patient_table_os"), "Probe success should require the column probe to return patientid and date_birth columns.")
expect_true(any(grepl("unexpected result shape", wrong_column_shape_resolver$column_probe_error_sanitized, fixed = TRUE)), "Unexpected column-probe result shapes should be audited.")

discovered_cols <- data.frame(
  schema = c(rep("public", 3), rep("public", 3)),
  table = c(rep("view_patient_table_os", 3), rep("view_discovered_patient_table", 3)),
  column_name = rep(c("patientid", "date_birth", "date_death_fu"), 2),
  stringsAsFactors = FALSE
)
discovered_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(discovered_cols, relation_fail_tables = "view_patient_table_os"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
expect_true(any(discovered_resolver$selected & discovered_resolver$table == "view_discovered_patient_table"), "A discovered patientid/date_birth candidate should be selected when the configured relation is missing.")

tie_cols <- data.frame(
  schema = c(rep("public", 3), rep("public", 3)),
  table = c(rep("view_alpha_patient_table", 3), rep("view_beta_patient_table", 3)),
  column_name = rep(c("patientid", "date_birth", "date_death_fu"), 2),
  stringsAsFactors = FALSE
)
tie_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(tie_cols),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
selected_tie <- tie_resolver[tie_resolver$selected, , drop = FALSE]
expect_equal(selected_tie$table[[1]], "view_alpha_patient_table", "Equal-score patient demographic candidates should be selected by deterministic schema/table order.")
expect_equal(selected_tie$reason[[1]], "deterministic_tie_break_requires_review", "Equal-score resolver selections should be flagged for review.")
expect_true(selected_tie$deterministic_tie_break_requires_review[[1]], "Equal-score resolver selections should expose a dedicated review flag.")

no_candidate_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(data.frame(schema = character(), table = character(), column_name = character())),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
no_candidate_plan <- mcl_count_build_query_plan(defs, project_root = root, outputs_dir = profile_dir, patient_demographics_resolver = no_candidate_resolver)
expect_true(grepl("-- NOT EXECUTABLE: requires patient demographics mapping", no_candidate_plan$sql, fixed = TRUE), "Age SQL should fail closed when no verified patient demographics candidate exists.")
expect_true(any(no_candidate_plan$review$data_point == "cit_immunochemotherapy" & no_candidate_plan$review$query_executable), "All-MCL treatment counts should remain executable when patient demographics are unresolved.")

cll_demographics_cols <- data.frame(
  schema = "public",
  table = "RKKP_CLL_CLEAN",
  column_name = c("patientid", "date_birth", "date_death_fu"),
  stringsAsFactors = FALSE
)
cll_fallback_resolver <- mcl_count_resolve_patient_demographics(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_info_adapter(cll_demographics_cols),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
cll_row <- cll_fallback_resolver[cll_fallback_resolver$table == "RKKP_CLL_CLEAN", , drop = FALSE]
expect_true(nrow(cll_row) == 1L && cll_row$reason[[1]] == "rejected_non_mcl_demographics_source", "CLL disease-specific tables with patientid/date_birth must be rejected as MCL demographics fallbacks.")
expect_false(any(cll_fallback_resolver$selected & cll_fallback_resolver$table == "RKKP_CLL_CLEAN"), "RKKP_CLL_CLEAN must not be selected for MCL age counts.")
expect_false(any(cll_fallback_resolver$usable_for_age_counts & cll_fallback_resolver$table == "RKKP_CLL_CLEAN"), "Rejected disease-specific candidates must not be usable for age counts.")
cll_fallback_plan <- mcl_count_build_query_plan(defs, project_root = root, outputs_dir = profile_dir, patient_demographics_resolver = cll_fallback_resolver)
expect_true(any(cll_fallback_plan$review$data_point == "younger_mcl_proxy_age_le_65" & !cll_fallback_plan$review$query_executable), "Age SQL should stay non-executable when only CLL demographics fallbacks are available.")
expect_false(grepl('"public"."RKKP_CLL_CLEAN"', cll_fallback_plan$sql, fixed = TRUE), "Age SQL must not join disease-specific CLL fallback demographics sources.")

birth_alias_cols <- data.frame(
  schema = c(rep("public", 2), rep("public", 4)),
  table = c(rep("view_general_demographics", 2), rep("RKKP_LYFO", 4)),
  column_name = c("patientid", "birth_date", "patientid", "subtype", "Reg_DiagnostiskBiopsi_dt", "Beh_KemoterapiStart_dt"),
  data_type = c("integer", "date", "integer", "text", "date", "date"),
  stringsAsFactors = FALSE
)
birth_alias_locator <- mcl_count_resolve_age_source(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_age_source_adapter(birth_alias_cols),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  patient_demographics_resolver = no_candidate_resolver,
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
birth_alias_selected <- birth_alias_locator[birth_alias_locator$selected, , drop = FALSE]
expect_equal(birth_alias_selected$birth_date_column[[1]], "birth_date", "Age source locator should accept verified birth-date aliases, not only date_birth.")
birth_alias_plan <- mcl_count_build_query_plan(defs, project_root = root, outputs_dir = profile_dir, patient_demographics_resolver = no_candidate_resolver, age_source_locator = birth_alias_locator)
birth_alias_age_sql <- unlist(strsplit(birth_alias_plan$sql, "-- query_id: ", fixed = TRUE), use.names = FALSE)
birth_alias_age_sql <- birth_alias_age_sql[grepl("^mcl_triangle_younger_mcl_proxy_age_le_65\\b", birth_alias_age_sql)]
expect_true(length(birth_alias_age_sql) == 1L && grepl('"public"."view_general_demographics"', birth_alias_age_sql[[1]], fixed = TRUE) && grepl('"birth_date"', birth_alias_age_sql[[1]], fixed = TRUE), "Verified general demographics birth-date aliases should make age SQL executable.")

birth_alias_co_fail_locator <- mcl_count_resolve_age_source(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_age_source_adapter(birth_alias_cols, co_fail_tables = "view_general_demographics"),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  patient_demographics_resolver = no_candidate_resolver,
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
birth_alias_co_fail_row <- birth_alias_co_fail_locator[birth_alias_co_fail_locator$table == "view_general_demographics", , drop = FALSE]
expect_false(any(birth_alias_co_fail_row$selected), "Birth-date age sources must not be selected when they cannot join to LYFO.")
expect_true(any(birth_alias_co_fail_row$reason == "co_residency_probe_failed"), "Birth-date age source co-residency failures should be audited explicitly.")
expect_true(birth_alias_co_fail_row$relation_probe_success[[1]] && birth_alias_co_fail_row$column_probe_success[[1]], "Birth-date co-residency failures should preserve standalone probe provenance.")
expect_false(grepl("secret", paste(birth_alias_co_fail_row$co_residency_probe_error_sanitized, collapse = " "), fixed = TRUE), "Birth-date co-residency errors should be sanitized.")
age_co_fail_tmp <- tempfile("mcl_count_age_co_residency_status_")
dir.create(age_co_fail_tmp, recursive = TRUE, showWarnings = FALSE)
age_co_fail_path <- write_csv(birth_alias_co_fail_locator, file.path(age_co_fail_tmp, "mcl_triangle_age_source_locator.csv"))
age_co_fail_status <- mcl_count_output_generation_status(
  age_co_fail_tmp,
  list(age_source_locator = age_co_fail_path),
  mode = "production_aggregate",
  latest_mapping_change = Sys.time() - 3600,
  age_source_locator = birth_alias_co_fail_locator
)
expect_false(any(age_co_fail_status$stale), "Current age-source co-residency probe failures should be fresh locator audit evidence, not stale-output warnings.")

cll_age_locator <- mcl_count_resolve_age_source(
  project_root = root,
  outputs_dir = profile_dir,
  db_adapter = fake_age_source_adapter(data.frame(schema = "public", table = "RKKP_CLL_CLEAN", column_name = c("patientid", "birth_date"), data_type = c("integer", "date"), stringsAsFactors = FALSE)),
  person_date_mapping = mcl_count_read_person_date_mapping(root),
  patient_demographics_resolver = no_candidate_resolver,
  mode = "production_aggregate",
  generated_at = "2026-05-22T00:00:00+0000",
  verification_mode = "test_fake_information_schema"
)
cll_age_row <- cll_age_locator[cll_age_locator$table == "RKKP_CLL_CLEAN", , drop = FALSE]
expect_true(nrow(cll_age_row) == 1L && cll_age_row$reason[[1]] == "rejected_non_mcl_demographics_source", "Age source locator must reject disease-specific demographics fallbacks.")
expect_false(any(cll_age_locator$selected), "Rejected disease-specific age sources must not be selected.")

lyfo_age_cols <- data.frame(
  schema = "public",
  table = "RKKP_LYFO",
  column_name = c("patientid", "subtype", "age_at_diagnosis", "Reg_DiagnostiskBiopsi_dt", "Beh_KemoterapiStart_dt"),
  data_type = c("integer", "text", "numeric", "date", "date"),
  stringsAsFactors = FALSE
)
lyfo_age_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_age_source_adapter(lyfo_age_cols, numeric_ok = TRUE, younger_count = 24L),
  min_cell_count = 5L
)
lyfo_age_selected <- lyfo_age_out$age_source_locator[lyfo_age_out$age_source_locator$selected, , drop = FALSE]
expect_true(nrow(lyfo_age_selected) == 1L && lyfo_age_selected$source_type[[1]] == "lyfo_age_fallback", "Verified LYFO age-at-diagnosis should be accepted as a fallback only after numeric plausibility checks.")
expect_true(lyfo_age_selected$numeric_age_plausible[[1]], "Accepted LYFO age fallback must have a plausible numeric aggregate probe.")
lyfo_young <- lyfo_age_out$data_point_counts[lyfo_age_out$data_point_counts$data_point_id == "younger_mcl_proxy_age_le_65", , drop = FALSE]
expect_equal(lyfo_young$distinct_person_count_display[[1]], "24", "Accepted LYFO age fallback should populate age <=65 without a patient-demographics join.")
lyfo_age_sql <- unlist(strsplit(lyfo_age_out$query_templates, "-- query_id: ", fixed = TRUE), use.names = FALSE)
lyfo_age_sql <- lyfo_age_sql[grepl("^mcl_triangle_younger_mcl_proxy_age_le_65\\b", lyfo_age_sql)]
expect_true(length(lyfo_age_sql) == 1L && grepl('"age_at_diagnosis"', lyfo_age_sql[[1]], fixed = TRUE) && !grepl(" join ", lyfo_age_sql[[1]], ignore.case = TRUE), "LYFO age fallback SQL should not join an unverified patient table.")

current_age_cols <- data.frame(
  schema = "public",
  table = "RKKP_LYFO",
  column_name = c("patientid", "subtype", "current_age", "Reg_DiagnostiskBiopsi_dt"),
  data_type = c("integer", "text", "numeric", "date"),
  stringsAsFactors = FALSE
)
current_age_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_age_source_adapter(current_age_cols, numeric_ok = TRUE),
  min_cell_count = 5L
)
current_age_row <- current_age_out$age_source_locator[current_age_out$age_source_locator$age_column == "current_age", , drop = FALSE]
expect_true(nrow(current_age_row) == 1L && current_age_row$reason[[1]] == "rejected_current_or_followup_age", "Current/follow-up age fields must not be accepted as TRIANGLE age-at-diagnosis proxies.")
expect_false(any(current_age_out$age_source_locator$selected), "Ambiguous/current LYFO age candidates must not be selected.")
current_age_rows <- current_age_out$data_point_counts[current_age_out$data_point_counts$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
expect_true(all(!nzchar(current_age_rows$percent_of_denominator_display)), "Unavailable age rows must not display fake percentages.")
current_mcl <- current_age_out$data_point_counts[current_age_out$data_point_counts$data_point_id == "all_lyfo_mcl", , drop = FALSE]
expect_equal(current_mcl$distinct_person_count_display[[1]], "30", "All-MCL marginal counts should remain available when age is unavailable.")
current_all_mcl_strata <- current_age_out$treatment_strategy_strata_counts[current_age_out$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl", , drop = FALSE]
current_young_strata <- current_age_out$treatment_strategy_strata_counts[current_age_out$treatment_strategy_strata_counts$denominator == "younger_mcl_proxy_age_le_65", , drop = FALSE]
expect_true(any(current_all_mcl_strata$count_status %in% mcl_count_available_statuses()), "All-MCL ASCT/HDT x Ibrutinib strata should still populate when age is unavailable.")
expect_true(all(current_young_strata$count_status == "count_not_available_requires_patient_demographics_mapping"), "Age-specific treatment strata should fail closed when the younger denominator is unavailable.")

multi_db_adapter <- fake_multi_db_age_adapter()
multi_patient_cols <- mcl_count_patient_info_schema_columns(multi_db_adapter)
multi_age_cols <- mcl_count_age_source_info_schema_columns(multi_db_adapter)
expect_true(any(multi_patient_cols$db_name == "core" & multi_patient_cols$table == "patient" & multi_patient_cols$column_name == "date_birth"), "All-connection patient discovery should include core.public.patient.date_birth.")
expect_true(any(multi_age_cols$db_name == "import" & multi_age_cols$table == "SDS_t_tumor" & multi_age_cols$column_name == "d_fdsdato"), "All-connection age-source discovery should include import.public.SDS_t_tumor.d_fdsdato.")

atlas_evidence_dir <- tempfile("mcl_atlas_age_evidence_")
dir.create(atlas_evidence_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(data.frame(
  db_name = c("core", "core", "import", "import", "import", "import"),
  table_name = c("patient", "patient", "RKKP_LYFO", "RKKP_LYFO", "SDS_t_tumor", "SDS_t_tumor"),
  column_name = c("patientid", "date_birth", "patientid", "subtype", "patientid", "d_fdsdato"),
  data_type = c("integer", "date", "integer", "text", "integer", "date"),
  stringsAsFactors = FALSE
), file.path(atlas_evidence_dir, "atlas_columns.csv"))
atlas_inventory <- mcl_count_read_atlas_age_inventory(atlas_output_dir = atlas_evidence_dir)
expect_true(any(atlas_inventory$evidence_status == "atlas_found_core_patient_birth_date"), "Atlas ingestion should record core patient birth-date evidence.")
expect_true(any(atlas_inventory$evidence_status == "same_db_birth_date_candidate_requires_validation"), "Atlas ingestion should record SDS_t_tumor as validation-required age evidence.")

multi_db_dir <- tempfile("mcl_multi_db_age_")
write_mcl_triangle_metadata(multi_db_dir)
multi_db_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = multi_db_dir,
  mode = "production_aggregate",
  db_adapter = multi_db_adapter,
  min_cell_count = 5L,
  atlas_output_dir = atlas_evidence_dir
)
core_patient_row <- multi_db_out$patient_demographics_resolver[
  multi_db_out$patient_demographics_resolver$db_name == "core" &
    multi_db_out$patient_demographics_resolver$table == "patient",
  ,
  drop = FALSE
]
expect_true(nrow(core_patient_row) == 1L && core_patient_row$reason[[1]] == "cross_database_join_unavailable", "core.public.patient should be recognized but rejected for executable LYFO age joins across the DB boundary.")
expect_true(core_patient_row$relation_probe_success[[1]] && core_patient_row$column_probe_success[[1]], "Cross-DB rejection should preserve successful standalone patient probes.")
expect_false(core_patient_row$co_residency_probe_success[[1]], "Cross-DB patient evidence must not be treated as LYFO co-resident.")
sds_age_row <- multi_db_out$age_source_locator[
  multi_db_out$age_source_locator$table == "SDS_t_tumor" &
    multi_db_out$age_source_locator$birth_date_column == "d_fdsdato",
  ,
  drop = FALSE
]
expect_true(any(sds_age_row$selected & sds_age_row$reason == "same_db_birth_date_source_validated"), "Validated import.public.SDS_t_tumor.d_fdsdato should become the selected age source.")
age_validation <- multi_db_out$age_source_validation
expect_true(any(age_validation$validation_id == "primary" & age_validation$selected_for_age_counts), "Primary same-DB birth-date validation should select the age source when aggregate metrics pass.")
expect_true(any(age_validation$validation_id == "diagnosis_first_sensitivity" & age_validation$query_success), "Diagnosis-first sensitivity validation should also be emitted as aggregate evidence.")
multi_young <- multi_db_out$data_point_counts[multi_db_out$data_point_counts$data_point_id == "younger_mcl_proxy_age_le_65", , drop = FALSE]
expect_equal(multi_young$distinct_person_count_display[[1]], "55", "Validated same-DB SDS_t_tumor birth date should populate the younger age proxy.")
multi_birth <- multi_db_out$data_point_counts[multi_db_out$data_point_counts$data_point_id == "birth_date_available", , drop = FALSE]
expect_equal(multi_birth$distinct_person_count_display[[1]], "95", "Validated same-DB birth date should populate birth-date availability.")
multi_young_strata <- multi_db_out$treatment_strategy_strata_counts[multi_db_out$treatment_strategy_strata_counts$denominator == "younger_mcl_proxy_age_le_65", , drop = FALSE]
expect_true(any(multi_young_strata$count_status %in% mcl_count_available_statuses()), "Age-specific strata should populate after same-DB birth-date validation.")
expect_true(multi_db_out$execution_summary$atlas_age_inventory_rows[[1]] > 0L, "Execution summary should count atlas age inventory rows.")
expect_true(multi_db_out$execution_summary$age_validation_queries[[1]] >= 2L, "Execution summary should count age validation queries.")
multi_db_tmp <- tempfile("mcl_multi_db_age_outputs_")
dir.create(multi_db_tmp, recursive = TRUE, showWarnings = FALSE)
mcl_count_write_outputs(multi_db_out, multi_db_tmp)
expect_file(file.path(multi_db_tmp, "mcl_triangle_atlas_age_source_inventory.csv"))
expect_file(file.path(multi_db_tmp, "mcl_triangle_age_source_validation.csv"))
multi_db_text <- paste(vapply(list.files(multi_db_tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("SELECT \\*|LIMIT 10|010101|personnummer|raw snippet", multi_db_text, ignore.case = TRUE, perl = TRUE), "DB-aware age outputs must remain aggregate-only and avoid raw-row preview patterns.")
expect_false(grepl('"public"."patient"', multi_db_out$query_templates, fixed = TRUE), "DB-aware templates must not emit executable cross-DB joins to public.patient.")

unstable_db_dir <- tempfile("mcl_multi_db_age_unstable_")
write_mcl_triangle_metadata(unstable_db_dir)
unstable_age_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = unstable_db_dir,
  mode = "production_aggregate",
  db_adapter = fake_multi_db_age_adapter(unstable_birth = TRUE),
  min_cell_count = 5L
)
unstable_sds <- unstable_age_out$age_source_locator[unstable_age_out$age_source_locator$table == "SDS_t_tumor", , drop = FALSE]
expect_true(any(unstable_sds$reason == "same_db_birth_date_validation_failed"), "Multiple birth dates should fail the SDS_t_tumor age source closed.")
expect_false(any(unstable_sds$selected), "Unstable birth-date validation must not select SDS_t_tumor.")
unstable_age_rows <- unstable_age_out$data_point_counts[unstable_age_out$data_point_counts$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
expect_true(all(unstable_age_rows$count_status == "count_not_available_requires_patient_demographics_mapping"), "Age rows should fail closed when same-DB birth-date validation fails.")
expect_equal(unstable_age_out$data_point_counts[unstable_age_out$data_point_counts$data_point_id == "all_lyfo_mcl", "distinct_person_count_display"][[1]], "100", "All-MCL marginal counts should remain available after age validation failure.")

post_fail_adapter <- list(
  mcl_triangle_query = function(sql) {
    if (grepl("current_database\\(\\)", sql)) {
      return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
    }
    if (grepl("information_schema[.]columns", sql)) {
      return(data.frame(
        schema = "public",
        table = "patient",
        column_name = c("patientid", "date_birth", "date_death_fu"),
        stringsAsFactors = FALSE
      ))
    }
    if (grepl("where false", sql, fixed = TRUE)) {
      if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
        return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
      }
      return(data.frame(patientid = integer(), date_birth = character(), stringsAsFactors = FALSE))
    }
    if (grepl('"public"."patient"', sql, fixed = TRUE)) {
      stop('Failed to prepare query : ERROR: relation "public.patient" does not exist')
    }
    data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", gsub("\n", " ", sql), perl = TRUE)
    data.frame(data_point_id = data_point, distinct_person_count = 10, stringsAsFactors = FALSE)
  }
)
post_fail_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = profile_dir,
  mode = "production_aggregate",
  db_adapter = post_fail_adapter,
  min_cell_count = 5L
)
post_fail_resolver <- post_fail_out$patient_demographics_resolver
expect_false(any(post_fail_resolver$selected & post_fail_resolver$table == "patient"), "A selected demographics relation must be invalidated if production age SQL later reports relation-not-found.")
expect_true(any(post_fail_resolver$reason == "post_selection_relation_not_found"), "Post-selection relation-not-found failures should be visible in the resolver audit.")
expect_true(any(post_fail_resolver$post_selection_execution_attempted %in% TRUE), "Resolver audit should record post-selection execution attempts.")
expect_false(any(post_fail_resolver$post_selection_execution_success %in% TRUE), "The invalidated resolver relation should not report post-selection execution success.")
expect_true(any(post_fail_resolver$table == "patient" & post_fail_resolver$relation_probe_success %in% TRUE), "Post-selection invalidation should preserve the successful relation probe audit instead of rewriting probe success to FALSE.")
expect_true(any(post_fail_resolver$table == "patient" & post_fail_resolver$column_probe_success %in% TRUE), "Post-selection invalidation should preserve the successful column probe audit instead of rewriting probe success to FALSE.")
expect_true(any(post_fail_out$data_point_counts$data_point_id == "younger_mcl_proxy_age_le_65" & post_fail_out$data_point_counts$count_status == "count_not_available_requires_patient_demographics_mapping"), "Age counts should fail closed after selected relation invalidation.")
expect_true(any(post_fail_out$query_review$data_point == "younger_mcl_proxy_age_le_65" & !post_fail_out$query_review$query_executable), "Age query review should be regenerated as non-executable after selected relation invalidation.")
expect_true(grepl("-- NOT EXECUTABLE: requires patient demographics mapping", post_fail_out$query_templates, fixed = TRUE), "Age query templates should be regenerated as non-executable after selected relation invalidation.")
expect_true(any(post_fail_out$data_point_counts$data_point_id == "cit_immunochemotherapy" & post_fail_out$data_point_counts$count_status == "production_aggregate_count_available"), "All-MCL treatment counts should remain available after age resolver invalidation.")
post_fail_age_rows <- post_fail_out$data_point_counts[post_fail_out$data_point_counts$data_point_id %in% mcl_count_age_data_point_ids(), , drop = FALSE]
expect_true(all(post_fail_age_rows$query_attempted %in% TRUE), "Post-selection invalidation should retain provenance that production age execution was attempted.")
expect_true(all(!(post_fail_age_rows$query_executed %in% TRUE) & !(post_fail_age_rows$query_success %in% TRUE)), "Invalidated age rows should be canonical non-executable failures after resolver invalidation.")
expect_true(all(post_fail_age_rows$validation_status == "post_selection_resolver_invalidated"), "Invalidated age rows should expose a dedicated validation status.")
expect_true(all(post_fail_age_rows$count_status == "count_not_available_requires_patient_demographics_mapping"), "Invalidated age rows should have the canonical patient-demographics mapping status.")
expect_false(any(grepl("public.patient", post_fail_age_rows$error_message_sanitized, fixed = TRUE)), "Age rows should point to the resolver audit instead of repeating stale-looking relation-not-found text.")
expect_true(any(grepl("public.patient", post_fail_resolver$post_selection_execution_error_sanitized, fixed = TRUE)), "The resolver audit should retain the production relation-not-found diagnostic.")
post_fail_tmp <- tempfile("mcl_count_post_selection_fresh_")
dir.create(post_fail_tmp, recursive = TRUE, showWarnings = FALSE)
mcl_count_write_outputs(post_fail_out, post_fail_tmp)
post_fail_status <- read_delimited_file(file.path(post_fail_tmp, "output_generation_status.csv"))
expect_true(any(post_fail_status$output_file == "mcl_triangle_patient_demographics_resolver.csv" & post_fail_status$stale == FALSE & post_fail_status$notes == "fresh after resolver change"), "Coherent post-selection resolver invalidation should be fresh output, not stale output.")
expect_true(any(post_fail_status$output_file == "mcl_triangle_data_point_counts.csv" & post_fail_status$stale == FALSE & post_fail_status$notes == "fresh after resolver change"), "Fail-closed age rows after resolver invalidation should be fresh output, not stale output.")
expect_false(any(post_fail_status$output_file == "mcl_triangle_count_query_templates.sql" & post_fail_status$stale == TRUE), "Regenerated query templates should not contain executable joins to invalidated demographics relations.")
expect_false(any(post_fail_out$treatment_strategy_strata_counts$count_status == "production_aggregate_count_available" & !nzchar(post_fail_out$treatment_strategy_strata_counts$distinct_person_count_display)), "Treatment-strategy strata without intersection counts must not be labelled count-available.")
expect_false(any(post_fail_out$exposure_strata_counts$count_status == "production_aggregate_count_available" & !nzchar(post_fail_out$exposure_strata_counts$distinct_person_count_display)), "Exposure strata without intersection counts must not be labelled count-available.")

prior_resolver_dir <- tempfile("mcl_count_prior_resolver_")
dir.create(prior_resolver_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(configured_resolver, file.path(prior_resolver_dir, "mcl_triangle_patient_demographics_resolver.csv"))
prior_plan <- mcl_count_build_query_plan(defs, project_root = root, outputs_dir = prior_resolver_dir)
prior_age_sql <- unlist(strsplit(prior_plan$sql, "-- query_id: ", fixed = TRUE), use.names = FALSE)
prior_age_sql <- prior_age_sql[grepl("^mcl_triangle_younger_mcl_proxy_age_le_65\\b", prior_age_sql)]
expect_true(length(prior_age_sql) == 1L && grepl('"public"."view_patient_table_os"', prior_age_sql[[1]], fixed = TRUE), "Plan mode may reuse exactly one prior resolver-selected demographics relation only when both probes succeeded.")

fake_query_adapter <- list(
  mcl_triangle_query = function(sql) {
    data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", gsub("\n", " ", sql), perl = TRUE)
    value <- if (identical(data_point, "cit_immunochemotherapy")) 0 else if (identical(data_point, "ki67_aeki")) 37 else 10
    data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
  }
)

fake_intersection_adapter <- function(fail_intersections = character()) {
  force(fail_intersections)
  list(
    mcl_triangle_query = function(sql) {
      compact_sql <- gsub("\n", " ", sql)
      if (grepl("current_database\\(\\)", sql)) {
        return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
      }
      if (grepl("information_schema[.]columns", sql)) {
        return(lyfo_age_cols)
      }
      if (grepl("where false", sql, fixed = TRUE)) {
        if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
        }
        return(data.frame(patientid = integer(), subtype = character(), age_at_diagnosis = numeric(), Reg_DiagnostiskBiopsi_dt = character(), Beh_KemoterapiStart_dt = character(), stringsAsFactors = FALSE))
      }
      if (grepl("numeric_age_count", sql, fixed = TRUE)) {
        return(data.frame(mcl_row_count = 30L, numeric_age_count = 24L, plausible_age_count = 24L, stringsAsFactors = FALSE))
      }
      if (grepl("as intersection_id", sql, fixed = TRUE)) {
        intersection_id <- sub(".*select '([^']+)' as intersection_id.*", "\\1", compact_sql, perl = TRUE)
        if (intersection_id %in% fail_intersections) {
          stop(paste("simulated aggregate intersection failure for", intersection_id, "token=secret"))
        }
        value <- if (identical(intersection_id, "all_lyfo_mcl__asct_hdt_first_line__ibrutinib_exposure")) {
          7L
        } else if (identical(intersection_id, "ibrutinib_exposure__asct_hdt_first_line")) {
          7L
        } else if (identical(intersection_id, "age_le_65_ibrutinib_yes_asct_yes")) {
          6L
        } else {
          9L
        }
        return(data.frame(intersection_id = intersection_id, distinct_person_count = value, stringsAsFactors = FALSE))
      }
      data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", compact_sql, perl = TRUE)
      value <- switch(
        data_point,
        all_lyfo_mcl = 30L,
        younger_mcl_proxy_age_le_65 = 24L,
        age_anchor_available = 24L,
        age_computable = 24L,
        age_gt_65 = 6L,
        age_missing_uncomputable = 0L,
        diagnosis_date = 30L,
        first_line_treatment_date = 22L,
        cit_immunochemotherapy = 20L,
        asct_hdt_first_line = 10L,
        ibrutinib_exposure = 12L,
        os_death = 20L,
        relapse_progression_ffs_proxy = 14L,
        ki67_aeki = 8L,
        mipi_mipic_components = 30L,
        10L
      )
      data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
    }
  )
}

prod_query_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_query_adapter,
  min_cell_count = 5L
)
expect_true(all(c("query_attempted", "query_executed", "query_success", "error_class", "error_message_sanitized") %in% names(prod_query_out$data_point_counts)), "Production query outputs should include query-attempt and sanitized-error columns.")
expect_true(any(prod_query_out$data_point_counts$query_success), "Successful aggregate query rows should be marked successful.")
cit_zero <- prod_query_out$data_point_counts[prod_query_out$data_point_counts$data_point_id == "cit_immunochemotherapy", , drop = FALSE]
expect_equal(cit_zero$count_status[[1]], "count_available_zero_requires_value_mapping_review", "Suspicious zero CIT counts should be flagged for value-mapping review.")
expect_equal(cit_zero$percent_of_denominator_display[[1]], "", "Zero counts requiring review should not get a reassuring percentage.")
ki67_summary <- prod_query_out$ki67_person_count_summary
expect_true(nrow(ki67_summary) > 0, "Successful Ki-67 AEKI person count should populate the Ki-67 person-count summary.")
expect_equal(ki67_summary$denominator[[1]], "all_lyfo_mcl", "Ki-67 person-count summary should include the all-MCL denominator row.")
expect_equal(ki67_summary$distinct_person_count_display[[1]], "37", "Ki-67 person-count summary should reuse the successful distinct-person AEKI count.")
expect_true(nrow(prod_query_out$overlap_matrix) > 0, "Overlap output should contain explanatory rows instead of an empty file when dedicated intersections are not run.")
expect_true(nrow(prod_query_out$exposure_strata_counts) > 0, "Exposure strata output should contain explanatory rows instead of an empty file when strata queries are not run.")
expect_true(nrow(prod_query_out$landmark_feasibility_counts) > 0, "Landmark output should contain availability/unavailable rows instead of an empty file.")
deep_ids <- c("toxicity_proxies", "alive_at_landmark", "event_free_pre_landmark", "asct_hdt_status_known_landmark", "ibrutinib_status_known_landmark", "high_risk_biology_pre_landmark")
tp53_row <- prod_query_out$data_point_counts[prod_query_out$data_point_counts$data_point_id == "tp53_p53_del17p", , drop = FALSE]
morph_row <- prod_query_out$data_point_counts[prod_query_out$data_point_counts$data_point_id == "blastoid_pleomorphic_morphology", , drop = FALSE]
expect_true(tp53_row$count_status[[1]] == "count_not_available_requires_value_mapping" && morph_row$count_status[[1]] == "count_not_available_requires_value_mapping", "TP53 and blastoid/pleomorphic positivity must remain fail-closed without exact value rules.")
expect_true(any(prod_query_out$query_review$data_point == "toxicity_proxies" & grepl("repo-derived provisional serious-infection", prod_query_out$query_review$value_rule_used, fixed = TRUE)), "Toxicity proxy query review should disclose the provisional CONFLUENCE serious-infection rule.")

intersection_profile_dir <- tempfile("mcl_count_intersection_profile_")
dir.create(intersection_profile_dir, recursive = TRUE, showWarnings = FALSE)
intersection_columns <- data.frame(
  table_name = c(rep("RKKP_LYFO", 22), rep("SDS_pato", 3)),
  column_name = c(
    "patientid", "subtype", "age_at_diagnosis", "Reg_DiagnostiskBiopsi_dt", "Reg_BehandlingBeslutning_dt",
    "Beh_KemoterapiStart_dt", "Beh_ErDerForetagetKemo", "Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2",
    "Beh_Kemoterapiregime3", "Beh_Immunoterapi", "Beh_Hoejdosisbehandling", "Beh_TypeAutologStamcellestoette",
    "Beh_Stamcelleinfusion_dt", "Rec_Hoejdosisbehandling", "Rec_Stamcelleinfusion_dt", "FU_Doedsdato",
    "CPR_Doedsdato", "FU_LeverPatienten", "Rec_RelapsProgressions_dt", "Reg_PerformanceStatusWHO", "Reg_LDHVaerdi",
    "patientid", "d_svardato", "c_snomedkode"
  ),
  column_type = c(rep("text", 25)),
  column_class = c(rep("text", 25)),
  n_missing = "",
  pct_missing = "",
  n_distinct_capped = "",
  is_sensitive = c(TRUE, rep(FALSE, 21), TRUE, FALSE, FALSE),
  is_date_like = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE),
  is_numeric_like = c(FALSE, FALSE, TRUE, rep(FALSE, 22)),
  stringsAsFactors = FALSE
)
write_csv(intersection_columns, file.path(intersection_profile_dir, "atlas_columns.csv"))
write_csv(data.frame(
  source = c(rep("RKKP_LYFO", 9), "SDS_pato"),
  raw_field = c("subtype", "Beh_ErDerForetagetKemo", "Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3", "Beh_Hoejdosisbehandling", "Beh_TypeAutologStamcellestoette", "FU_LeverPatienten", "Rec_RelapsProgressions_dt", "c_snomedkode"),
  code_or_value = c("MCL", "Y", "IBRUTINIB", "IBRUTINIB", "IBRUTINIB", "Y", "BEAM", "N", "non_missing_valid_date", "AEKI030"),
  concept_name = c("Mantle cell lymphoma cohort", "Chemotherapy performed", "Ibrutinib regimen", "Ibrutinib regimen", "Ibrutinib regimen", "First-line ASCT/HDT", "Autolog stem-cell support", "Death/status proxy", "Relapse/progression proxy", "Ki-67 AEKI"),
  stringsAsFactors = FALSE
), file.path(intersection_profile_dir, "mcl_triangle_variable_inventory.csv"))

prod_intersection_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = intersection_profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_intersection_adapter(),
  min_cell_count = 5L
)
deep_rows <- prod_intersection_out$data_point_counts[prod_intersection_out$data_point_counts$data_point_id %in% deep_ids, , drop = FALSE]
expect_true(nrow(deep_rows) == length(deep_ids) && all(deep_rows$count_status %in% mcl_count_available_statuses()), "Deterministic TRIANGLE deep-mapping data points should execute as production aggregate counts when the age denominator is validated.")
expect_true(any(prod_intersection_out$landmark_feasibility_counts$count_status %in% mcl_count_available_statuses()), "Dedicated landmark aggregate rows should be surfaced in the landmark feasibility output.")
expect_true(any(prod_intersection_out$high_risk_biology_counts$biology_component == "any_high_risk_biology_known" & prod_intersection_out$high_risk_biology_counts$count_status %in% mcl_count_available_statuses()), "High-risk biology output should surface deterministic pre-landmark component evidence.")
all_mcl_asct_ib <- prod_intersection_out$treatment_strategy_strata_counts[
  prod_intersection_out$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl" &
    prod_intersection_out$treatment_strategy_strata_counts$ibrutinib_status == "yes" &
    prod_intersection_out$treatment_strategy_strata_counts$asct_hdt_first_line_status == "yes",
  ,
  drop = FALSE
]
expect_true(all_mcl_asct_ib$count_status[[1]] %in% mcl_count_available_statuses() && nzchar(all_mcl_asct_ib$distinct_person_count_display[[1]]), "Normal DBI production path should populate ASCT/HDT x Ibrutinib strata without requiring mcl_triangle_count_sets.")
overlap_asct_ib <- prod_intersection_out$overlap_matrix[
  prod_intersection_out$overlap_matrix$row_data_point_id == "ibrutinib_exposure" &
    prod_intersection_out$overlap_matrix$column_data_point_id == "asct_hdt_first_line",
  ,
  drop = FALSE
]
expect_equal(overlap_asct_ib$distinct_person_count_display[[1]], "7", "Normal DBI production path should populate fixed v1 overlap rows from aggregate SQL.")
answerability_asct_ib <- prod_intersection_out$answerability_intersections[
  prod_intersection_out$answerability_intersections$intersection_id == "age_le_65_ibrutinib_yes_asct_yes",
  ,
  drop = FALSE
]
expect_equal(answerability_asct_ib$distinct_person_count_display[[1]], "6", "Executable answerability intersections should populate from aggregate SQL when all required predicates are count-available.")
expect_true(prod_intersection_out$execution_summary$populated_intersection_outputs[[1]] > 0L, "Execution summary should count populated intersection outputs.")

prod_intersection_fail_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = intersection_profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_intersection_adapter(fail_intersections = "ki67_aeki__os_death"),
  min_cell_count = 5L
)
failed_ki67_os <- prod_intersection_fail_out$overlap_matrix[
  prod_intersection_fail_out$overlap_matrix$row_data_point_id == "ki67_aeki" &
    prod_intersection_fail_out$overlap_matrix$column_data_point_id == "os_death",
  ,
  drop = FALSE
]
expect_equal(failed_ki67_os$count_status[[1]], "production_aggregate_failed_query_error", "A failed aggregate overlap query should fail closed without blocking independent overlaps.")
surviving_overlap <- prod_intersection_fail_out$overlap_matrix[
  prod_intersection_fail_out$overlap_matrix$row_data_point_id == "ibrutinib_exposure" &
    prod_intersection_fail_out$overlap_matrix$column_data_point_id == "asct_hdt_first_line",
  ,
  drop = FALSE
]
expect_equal(surviving_overlap$distinct_person_count_display[[1]], "7", "Independent aggregate intersections should still write when one overlap query fails.")
expect_true(prod_intersection_fail_out$execution_summary$failed_queries[[1]] >= 1L, "Execution summary should count failed intersection queries.")
intersection_fail_tmp <- tempfile("mcl_intersection_fail_")
dir.create(intersection_fail_tmp, recursive = TRUE, showWarnings = FALSE)
mcl_count_write_outputs(prod_intersection_fail_out, intersection_fail_tmp)
intersection_fail_text <- paste(vapply(list.files(intersection_fail_tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("secret", intersection_fail_text, fixed = TRUE), "Failed aggregate intersection output should not leak unsanitized adapter error details.")

atlas_treatment_dir <- tempfile("mcl_atlas_treatment_evidence_")
dir.create(atlas_treatment_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(data.frame(
  source_name = c("SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin"),
  object_name = c("SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "EKOKUR", "SP_OrdineretMedicin"),
  code_system = c("ATC", "SKS", "ATC", "ATC", "ATC"),
  code = c("L01XE27", "BWHA169", "L01XE27", "L01XE27", "L01XE27"),
  code_name = rep("Ibrutinib", 5),
  n_rows = c(7718, 3018, 20, 30, 40),
  n_patients = c(195, NA, NA, NA, NA),
  stringsAsFactors = FALSE
), file.path(atlas_treatment_dir, "atlas_semantic_code_map.csv"))
write_csv(data.frame(
  source_name = "RKKP_CLL",
  object_name = "RKKP_CLL",
  raw_field = "Beh_TargeteretBeh_Ibrutinib",
  raw_value = "Y",
  display_value = "Targeted therapy / Ibrutinib",
  n = 177,
  stringsAsFactors = FALSE
), file.path(atlas_treatment_dir, "atlas_panel_distributions.csv"))
atlas_treatment_inventory <- mcl_count_read_atlas_treatment_inventory(atlas_output_dir = atlas_treatment_dir)
for (source_id in c("SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin", "RKKP_CLL")) {
  expect_true(source_id %in% atlas_treatment_inventory$canonical_source_id, paste("Atlas treatment inventory should include", source_id))
}
expect_true(any(atlas_treatment_inventory$code == "BWHA169" & atlas_treatment_inventory$evidence_status == "atlas_confirmed_sks_ibrutinib_bridge_required"), "BWHA169 should be surfaced as atlas-confirmed SKS Ibrutinib evidence requiring bridge validation.")

ibrutinib_profile_dir <- tempfile("mcl_ibrutinib_profile_")
dir.create(ibrutinib_profile_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(intersection_columns, file.path(ibrutinib_profile_dir, "atlas_columns.csv"))
write_csv(data.frame(
  source = c("RKKP_LYFO", "RKKP_LYFO"),
  raw_field = c("subtype", "Beh_Kemoterapiregime1"),
  code_or_value = c("MCL", "IBRUTINIB"),
  concept_name = c("Mantle cell lymphoma cohort", "Ibrutinib regimen"),
  stringsAsFactors = FALSE
), file.path(ibrutinib_profile_dir, "mcl_triangle_variable_inventory.csv"))

fake_ibrutinib_adapter <- function(bridge_ok = TRUE) {
  force(bridge_ok)
  list(
    mcl_triangle_query = function(sql) {
      compact <- gsub("\n", " ", sql)
      if (grepl("current_database\\(\\)", sql)) {
        return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
      }
      if (grepl("information_schema[.]columns", sql)) {
        return(data.frame(
          db_name = "import",
          schema = "public",
          table = c(
            rep("RKKP_LYFO", 6), "SDS_indberetningmedpris", "SDS_indberetningmedpris", "SDS_indberetningmedpris", "SDS_indberetningmedpris",
            "SP_OrdineretMedicin", "SP_OrdineretMedicin", "SP_OrdineretMedicin", "SP_OrdineretMedicin",
            "SDS_epikur", "SDS_epikur", "SDS_epikur",
            "SDS_ekokur", "SDS_ekokur", "SDS_ekokur",
            "SDS_t_sksube", "SDS_t_sksube", "SDS_t_sksube",
            "SDS_t_adm", "SDS_t_adm",
            "RKKP_CLL", "RKKP_CLL", "RKKP_CLL"
          ),
          column_name = c(
            "patientid", "subtype", "Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3", "Beh_KemoterapiStart_dt",
            "patientid", "c_atc", "d_ord_start", "d_adm",
            "patientid", "atc", "atc5", "order_start_time",
            "patientid", "atc", "eksd",
            "patientid", "atc", "eksd",
            "c_opr", "v_recnum", "d_odto",
            "k_recnum", "patientid",
            "patientid", "Beh_TargeteretBeh_Ibrutinib", "Beh_Behandling_Start_dt"
          ),
          data_type = "text",
          stringsAsFactors = FALSE
        ))
      }
      if (grepl("where false", sql, fixed = TRUE)) {
        if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
          if (!bridge_ok && grepl('"SDS_t_sksube"', sql, fixed = TRUE) && grepl('"SDS_t_adm"', sql, fixed = TRUE)) {
            stop("relation bridge failed token=secret")
          }
          return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
        }
        if (!bridge_ok && grepl('"SDS_t_adm"', sql, fixed = TRUE)) {
          return(data.frame(k_recnum = character(), stringsAsFactors = FALSE))
        }
        return(data.frame(
          patientid = integer(), subtype = character(),
          Beh_Kemoterapiregime1 = character(), Beh_Kemoterapiregime2 = character(), Beh_Kemoterapiregime3 = character(),
          Beh_KemoterapiStart_dt = character(), c_atc = character(), d_ord_start = character(),
          atc = character(), atc5 = character(), order_start_time = character(), eksd = character(),
          d_adm = character(), c_opr = character(), v_recnum = character(), d_odto = character(), k_recnum = character(),
          Beh_TargeteretBeh_Ibrutinib = character(), Beh_Behandling_Start_dt = character(),
          stringsAsFactors = FALSE
        ))
      }
      if (grepl("source_code_rows", sql, fixed = TRUE)) {
        if (grepl('"SDS_t_sksube"', sql, fixed = TRUE) && !bridge_ok) {
          stop("bridge source query should not execute token=secret")
        }
        vals <- if (grepl('"SDS_t_sksube"', sql, fixed = TRUE)) {
          c(3018L, 190L, 14L, 12L)
        } else if (grepl('"SDS_indberetningmedpris"', sql, fixed = TRUE)) {
          c(7718L, 195L, 13L, 13L)
        } else if (grepl('"SP_OrdineretMedicin"', sql, fixed = TRUE)) {
          c(222L, 21L, 6L, 6L)
        } else if (grepl('"SDS_epikur"', sql, fixed = TRUE)) {
          c(40L, 10L, 5L, 5L)
        } else if (grepl('"SDS_ekokur"', sql, fixed = TRUE)) {
          c(41L, 11L, 5L, 5L)
        } else if (grepl('"RKKP_CLL"', sql, fixed = TRUE)) {
          c(177L, 177L, 8L, 8L)
        } else {
          c(109L, 73L, 12L, 12L)
        }
        return(data.frame(source_code_rows = vals[[1]], source_distinct_people = vals[[2]], mcl_exposed_people = vals[[3]], date_available_people = vals[[4]], stringsAsFactors = FALSE))
      }
      if (grepl("as intersection_id", sql, fixed = TRUE)) {
        intersection_id <- sub(".*select '([^']+)' as intersection_id.*", "\\1", compact, perl = TRUE)
        value <- if (grepl("SDS_indberetningmedpris_ATC_L01XE27__SDS_t_sksube_SKS_BWHA169", intersection_id, fixed = TRUE)) 9L else if (identical(intersection_id, "all_lyfo_mcl__asct_hdt_first_line__ibrutinib_exposure")) 11L else if (identical(intersection_id, "ibrutinib_exposure__asct_hdt_first_line")) 11L else 8L
        return(data.frame(intersection_id = intersection_id, distinct_person_count = value, stringsAsFactors = FALSE))
      }
      data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", compact, perl = TRUE)
      value <- switch(
        data_point,
        all_lyfo_mcl = 40L,
        ibrutinib_exposure = if (grepl('"SDS_indberetningmedpris"', sql, fixed = TRUE) && grepl('"SDS_t_sksube"', sql, fixed = TRUE)) 18L else 12L,
        asct_hdt_first_line = 16L,
        os_death = 24L,
        relapse_progression_ffs_proxy = 20L,
        ki67_aeki = 9L,
        diagnosis_date = 40L,
        first_line_treatment_date = 30L,
        cit_immunochemotherapy = 25L,
        mipi_mipic_components = 40L,
        10L
      )
      data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
    }
  )
}

ibrutinib_expanded_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = ibrutinib_profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_ibrutinib_adapter(bridge_ok = TRUE),
  atlas_output_dir = atlas_treatment_dir,
  min_cell_count = 5L
)
expect_true(any(ibrutinib_expanded_out$ibrutinib_source_validation$source_id == "SDS_indberetningmedpris_ATC_L01XE27" & ibrutinib_expanded_out$ibrutinib_source_validation$selected_for_union), "Validated ATC source should contribute to the primary Ibrutinib union.")
expect_true(any(ibrutinib_expanded_out$ibrutinib_source_validation$source_id == "SDS_t_sksube_SKS_BWHA169" & ibrutinib_expanded_out$ibrutinib_source_validation$selected_for_union), "Validated bridged SKS source should contribute to the primary Ibrutinib union.")
expect_false(any(ibrutinib_expanded_out$ibrutinib_source_validation$source_id == "RKKP_CLL_Beh_TargeteretBeh_Ibrutinib" & ibrutinib_expanded_out$ibrutinib_source_validation$selected_for_union), "RKKP_CLL Ibrutinib evidence should remain auxiliary and outside the primary MCL union.")
expanded_ib <- ibrutinib_expanded_out$data_point_counts[ibrutinib_expanded_out$data_point_counts$data_point_id == "ibrutinib_exposure", , drop = FALSE]
expect_equal(expanded_ib$distinct_person_count_display[[1]], "18", "Production Ibrutinib marginal should use the deduplicated multi-source union after ATC/SKS validation.")
expect_true(grepl("SDS_indberetningmedpris_ATC_L01XE27", expanded_ib$value_rule_used[[1]], fixed = TRUE), "Ibrutinib value rule should record validated source provenance.")
expect_true(any(ibrutinib_expanded_out$treatment_strategy_strata_counts$count_status %in% mcl_count_available_statuses()), "Expanded Ibrutinib union should feed existing ASCT/HDT x Ibrutinib strata.")
expect_true(nrow(ibrutinib_expanded_out$ibrutinib_overlap_by_source) > 0, "Source-overlap diagnostics should be written for deduplication review.")
expect_true(ibrutinib_expanded_out$execution_summary$atlas_treatment_inventory_rows[[1]] > 0L, "Execution summary should count atlas treatment inventory rows.")
expect_true(ibrutinib_expanded_out$execution_summary$ibrutinib_validation_queries[[1]] > 0L, "Execution summary should count Ibrutinib source-validation queries.")

ibrutinib_bridge_fail_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = ibrutinib_profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_ibrutinib_adapter(bridge_ok = FALSE),
  atlas_output_dir = atlas_treatment_dir,
  min_cell_count = 5L
)
bridge_fail <- ibrutinib_bridge_fail_out$ibrutinib_source_validation[ibrutinib_bridge_fail_out$ibrutinib_source_validation$source_id == "SDS_t_sksube_SKS_BWHA169", , drop = FALSE]
expect_false(bridge_fail$selected_for_union[[1]], "SDS_t_sksube BWHA169 should not be person-counted when the SDS_t_adm bridge is unavailable.")
expect_true(bridge_fail$validation_status[[1]] %in% c("bridge_probe_failed", "co_residency_probe_failed"), "Bridge failure should be explicit and fail closed.")
ibrutinib_tmp <- tempfile("mcl_ibrutinib_expanded_")
dir.create(ibrutinib_tmp, recursive = TRUE, showWarnings = FALSE)
mcl_count_write_outputs(ibrutinib_expanded_out, ibrutinib_tmp)
for (name in c("mcl_triangle_atlas_treatment_source_inventory.csv", "mcl_triangle_ibrutinib_source_validation.csv", "mcl_triangle_ibrutinib_source_counts.csv", "mcl_triangle_ibrutinib_union_counts.csv", "mcl_triangle_ibrutinib_overlap_by_source.csv")) {
  expect_file(file.path(ibrutinib_tmp, name))
}
ibrutinib_text <- paste(vapply(list.files(ibrutinib_tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("010101|\\bcpr\\b|personnummer|raw snippet|SELECT \\*|LIMIT 10|token=secret", ibrutinib_text, ignore.case = TRUE, perl = TRUE), "Expanded Ibrutinib outputs must stay aggregate-only and sanitized.")

atlas_ki67_dir <- tempfile("mcl_ki67_atlas_")
dir.create(atlas_ki67_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(data.frame(
  canonical_resource_id = c("pato", "t_mikro", "t_konk"),
  current_resolved_table_or_view = c("SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny"),
  display_table_name = c("PATOBANK coded pathology", "PATOBANK microscopy text", "PATOBANK conclusion text"),
  db_name = "import",
  schema = "public",
  current_profiled = TRUE,
  current_n_rows = c(5311994, 9807682, 2341363),
  current_n_columns = c(12, 7, 7),
  stringsAsFactors = FALSE
), file.path(atlas_ki67_dir, "canonical_resource_reconciliation_64.csv"))
write_csv(data.frame(
  source_name = c("RKKP_LYFO", "SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny"),
  table_name = c("RKKP_LYFO", "SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny"),
  db_name = "import",
  schema = "public",
  stringsAsFactors = FALSE
), file.path(atlas_ki67_dir, "atlas_sources.csv"))
write_csv(data.frame(
  table_name = c(
    rep("SDS_pato", 7),
    rep("SDS_t_mikro_ny", 5),
    rep("SDS_t_konk_ny", 5)
  ),
  column_name = c(
    "patientid", "c_snomedkode", "v_fritekst", "k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr",
    "v_fritekst", "k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr",
    "v_fritekst", "k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr"
  ),
  db_name = "import",
  schema = "public",
  data_type = "text",
  stringsAsFactors = FALSE
), file.path(atlas_ki67_dir, "atlas_columns.csv"))

ki67_inventory <- mcl_count_read_atlas_ki67_inventory(atlas_output_dir = atlas_ki67_dir)
expect_true(all(c("coded_pathology", "pathology_free_text_embedded_in_pato", "microscopy_text", "conclusion_text") %in% ki67_inventory$source_channel), "Ki-67 atlas inventory should discover coded and text PATOBANK source surfaces.")
expect_true(all(ki67_inventory$db_name == "import"), "Ki-67 atlas inventory should preserve import DB context.")
expect_true(all(ki67_inventory$same_db_as_lyfo), "Ki-67 source-space rows should be same-DB as LYFO in the supplied atlas evidence.")
expect_true(any(ki67_inventory$source_channel == "microscopy_text" & ki67_inventory$has_join_keys_to_pato), "t_mikro should be recorded as a bridge candidate, not direct patient evidence.")

fake_ki67_adapter <- list(
  mcl_triangle_query = function(sql) {
    compact <- gsub("\n", " ", sql)
    if (grepl("normalized_code", sql, fixed = TRUE) && grepl("pathology_code_rows", sql, fixed = TRUE)) {
      return(data.frame(
        normalized_code = c("AEKI030", "AEKI050"),
        parsed_percent = c(30L, 50L),
        pathology_code_rows = c(6L, 2L),
        mcl_distinct_people = c(5L, 2L),
        stringsAsFactors = FALSE
      ))
    }
    if (grepl("ki67_aeki_known_people", sql, fixed = TRUE)) {
      return(data.frame(
        mcl_people = 20L,
        ki67_aeki_known_people = 7L,
        ki67_aeki_ge_threshold_people = 5L,
        ki67_aeki_ge_50_people = 2L,
        ki67_aeki_missing_people = 13L,
        people_with_multiple_aeki_codes = 1L,
        stringsAsFactors = FALSE
      ))
    }
    if (grepl("group by parsed_percent", sql, fixed = TRUE)) {
      return(data.frame(parsed_percent = c(30L, 50L), distinct_person_count = c(5L, 2L), stringsAsFactors = FALSE))
    }
    if (grepl("current_database\\(\\)", sql)) {
      return(data.frame(database_name = "import", search_path = "public", stringsAsFactors = FALSE))
    }
    if (grepl("information_schema[.]columns", sql)) {
      return(data.frame(
        db_name = "import",
        schema = "public",
        table = c(rep("RKKP_LYFO", 5), rep("SDS_pato", 7)),
        column_name = c(
          "patientid", "subtype", "Beh_KemoterapiStart_dt", "Beh_Hoejdosisbehandling", "Rec_RelapsProgressions_dt",
          "patientid", "c_snomedkode", "v_fritekst", "k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr"
        ),
        data_type = "text",
        stringsAsFactors = FALSE
      ))
    }
    if (grepl("where false", sql, fixed = TRUE)) {
      if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
        return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
      }
      return(data.frame(patientid = integer(), subtype = character(), c_snomedkode = character(), v_fritekst = character(), stringsAsFactors = FALSE))
    }
    if (grepl("as intersection_id", sql, fixed = TRUE)) {
      intersection_id <- sub(".*select '([^']+)' as intersection_id.*", "\\1", compact, perl = TRUE)
      return(data.frame(intersection_id = intersection_id, distinct_person_count = 6L, stringsAsFactors = FALSE))
    }
    data_point <- sub(".*select '([^']+)' as data_point_id.*", "\\1", compact, perl = TRUE)
    value <- switch(
      data_point,
      all_lyfo_mcl = 20L,
      ki67_aeki = 7L,
      diagnosis_date = 20L,
      first_line_treatment_date = 18L,
      cit_immunochemotherapy = 12L,
      asct_hdt_first_line = 8L,
      ibrutinib_exposure = 6L,
      os_death = 9L,
      relapse_progression_ffs_proxy = 7L,
      mipi_mipic_components = 20L,
      4L
    )
    data.frame(data_point_id = data_point, distinct_person_count = value, stringsAsFactors = FALSE)
  }
)
ki67_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = atlas_ki67_dir,
  mode = "production_aggregate",
  db_adapter = fake_ki67_adapter,
  atlas_output_dir = atlas_ki67_dir,
  ki67_text_scan = FALSE,
  min_cell_count = 5L
)
expect_equal(ki67_out$ki67_threshold_counts[ki67_out$ki67_threshold_counts$metric == "ki67_aeki_ge_threshold", "distinct_person_count_display"][[1]], "5", "AEKI threshold counts should populate from aggregate coded pathology SQL.")
expect_equal(ki67_out$high_risk_biology_counts[ki67_out$high_risk_biology_counts$biology_component == "ki67_aeki_high_threshold", "distinct_person_count_display"][[1]], "5", "High-risk biology output should receive the validated AEKI threshold count without inferring standard risk.")
expect_true(any(ki67_out$ki67_text_bridge_validation$validation_status == "text_pattern_query_template_only"), "Text source bridge rows should remain template-only when Ki-67 text scan is disabled.")
expect_false(any(ki67_out$ki67_source_validation$source_channel %in% c("microscopy_text", "conclusion_text") & ki67_out$ki67_source_validation$selected_for_numeric_union), "Pathology text source-space must not enter the numeric Ki-67 union without validation.")
expect_true(ki67_out$execution_summary$atlas_ki67_inventory_rows[[1]] >= 4L, "Execution summary should count Ki-67 atlas inventory rows.")
expect_true(ki67_out$execution_summary$ki67_validation_queries[[1]] >= 3L, "Execution summary should count Ki-67 aggregate validation queries.")
ki67_tmp <- tempfile("mcl_ki67_outputs_")
dir.create(ki67_tmp, recursive = TRUE, showWarnings = FALSE)
mcl_count_write_outputs(ki67_out, ki67_tmp)
for (name in c("mcl_triangle_atlas_ki67_source_inventory.csv", "mcl_triangle_ki67_source_validation.csv", "mcl_triangle_ki67_aeki_code_counts.csv", "mcl_triangle_ki67_aeki_person_counts.csv", "mcl_triangle_ki67_percent_distribution.csv", "mcl_triangle_ki67_threshold_counts.csv", "mcl_triangle_ki67_text_bridge_validation.csv", "mcl_triangle_ki67_text_pattern_counts.csv", "mcl_triangle_ki67_text_person_counts.csv", "mcl_triangle_ki67_union_counts.csv", "mcl_triangle_ki67_overlap_by_source.csv")) {
  expect_file(file.path(ki67_tmp, name))
}
ki67_text <- paste(vapply(list.files(ki67_tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("010101|\\bcpr\\b|personnummer|raw pathology|raw snippet|SELECT \\*|LIMIT 10", ki67_text, ignore.case = TRUE, perl = TRUE), "Ki-67 atlas-aware outputs must stay aggregate-only and avoid raw pathology previews.")

fake_date_fail_adapter <- list(
  mcl_triangle_query = function(sql) {
    if (grepl("current_database\\(\\)", sql)) {
      return(data.frame(database_name = "dalycare_test", search_path = "public", stringsAsFactors = FALSE))
    }
    if (grepl("information_schema[.]columns", sql)) {
      return(configured_cols)
    }
    if (grepl("where false", sql, fixed = TRUE)) {
      if (grepl("count\\(\\*\\) as probe_count", sql, ignore.case = TRUE)) {
        return(data.frame(probe_count = 0L, stringsAsFactors = FALSE))
      }
      return(data.frame(patientid = integer(), date_birth = character(), stringsAsFactors = FALSE))
    }
    if (grepl("date_birth", sql, fixed = TRUE)) stop("invalid input syntax for type date: <redacted>")
    data.frame(distinct_person_count = 10, stringsAsFactors = FALSE)
  }
)
prod_fail_out <- mcl_count_build_outputs(
  project_root = root,
  outputs_dir = profile_dir,
  mode = "production_aggregate",
  db_adapter = fake_date_fail_adapter,
  min_cell_count = 5L
)
young_fail <- prod_fail_out$data_point_counts[prod_fail_out$data_point_counts$data_point_id == "younger_mcl_proxy_age_le_65", , drop = FALSE]
expect_equal(young_fail$count_mode[[1]], "production_aggregate", "Failed production queries must remain production-mode rows.")
expect_equal(young_fail$count_status[[1]], "production_aggregate_failed_query_error", "Age denominator query failures should be explicit production query errors.")
expect_true(young_fail$query_attempted[[1]] && !young_fail$query_success[[1]], "Failed age denominator should record attempted but unsuccessful query execution.")
asct_after_young_fail <- prod_fail_out$data_point_counts[prod_fail_out$data_point_counts$data_point_id == "asct_hdt_first_line", , drop = FALSE]
expect_equal(asct_after_young_fail$count_status[[1]], "production_aggregate_count_available", "All-MCL treatment marginal counts should remain countable when only the younger-age denominator query fails.")

prod_no_db <- mcl_count_build_outputs(project_root = root, outputs_dir = profile_dir, mode = "production_aggregate", min_cell_count = 5L)
expect_equal(prod_no_db$execution_summary$db_connection_attempted[[1]], TRUE, "Production mode should attempt DB adapter discovery.")
expect_true(any(prod_no_db$data_point_counts$count_status == "production_aggregate_failed_credentials_unavailable"), "Production mode without credentials should fail as production mode, not silently fall back to plan.")
expect_false(any(prod_no_db$data_point_counts$count_mode == "plan"), "Production mode should not write plan-mode count rows.")

runner <- file.path(root, "RUN_MCL_TRIANGLE_COUNTS.R")
sourceable <- file.path(root, "scripts", "source_mcl_triangle_counts.R")
combined <- paste(readLines(runner, warn = FALSE), readLines(sourceable, warn = FALSE), collapse = "\n")
expect_false(grepl("run_atlas\\s*\\(|RUN_DALYCARE_ATLAS|scripts/run_atlas[.]R|R/run_atlas[.]R", combined, ignore.case = TRUE, perl = TRUE), "One-click count runner must not call or source the full atlas runner.")

runner_dir <- tempfile("mcl_count_runner_")
dir.create(runner_dir, recursive = TRUE, showWarnings = FALSE)
env <- new.env(parent = globalenv())
env$MCL_COUNT_MODE <- "plan"
env$MCL_COUNT_PROJECT_ROOT <- root
env$MCL_COUNT_OUTPUTS_DIR <- runner_dir
runner_console <- capture.output(sys.source(runner, envir = env))
expect_file(file.path(runner_dir, "mcl_triangle_count_query_templates.sql"))
expect_file(file.path(runner_dir, "mcl_triangle_data_point_counts.csv"))
expect_file(file.path(runner_dir, "mcl_triangle_execution_summary.csv"))
runner_console_text <- paste(runner_console, collapse = "\n")
expect_true(grepl("Production aggregate console summary:", runner_console_text, fixed = TRUE), "Runner console should print the final production aggregate summary block.")
for (needle in c("count mode", "executed queries", "failed queries", "populated intersections", "all MCL count", "age <=65 count", "CIT count", "Ibrutinib count", "ASCT/HDT count", "Ki-67 AEKI count", "payload updated")) {
  expect_true(grepl(needle, runner_console_text, fixed = TRUE), paste("Runner console summary should include", needle))
}

runner_prod_dir <- tempfile("mcl_count_runner_prod_")
dir.create(runner_prod_dir, recursive = TRUE, showWarnings = FALSE)
env_prod <- new.env(parent = globalenv())
env_prod$MCL_COUNT_MODE <- "production_aggregate"
env_prod$MCL_COUNT_UPDATE_PAYLOAD <- FALSE
env_prod$MCL_COUNT_PROJECT_ROOT <- root
invisible(file.copy(file.path(profile_dir, "atlas_columns.csv"), file.path(runner_prod_dir, "atlas_columns.csv"), overwrite = TRUE))
invisible(file.copy(file.path(profile_dir, "mcl_triangle_variable_inventory.csv"), file.path(runner_prod_dir, "mcl_triangle_variable_inventory.csv"), overwrite = TRUE))
env_prod$MCL_COUNT_OUTPUTS_DIR <- runner_prod_dir
runner_prod_console <- capture.output(sys.source(runner, envir = env_prod))
runner_prod_counts <- read_delimited_file(file.path(runner_prod_dir, "mcl_triangle_data_point_counts.csv"))
expect_file(file.path(runner_prod_dir, "mcl_triangle_execution_summary.csv"))
expect_true(all(runner_prod_counts$count_mode == "production_aggregate"), "One-click runner should respect pre-set production_aggregate mode.")
expect_false(any(runner_prod_counts$count_mode == "plan"), "Production one-click runner must not silently fall back to plan mode.")
expect_true(any(runner_prod_counts$count_status %in% c("production_aggregate_failed_credentials_unavailable", "production_aggregate_failed_query_error", "production_aggregate_count_available", "suppressed_small_cell")), "Production one-click runner should report production execution/failed-production statuses.")
expect_true(grepl("count mode: production_aggregate", paste(runner_prod_console, collapse = "\n"), fixed = TRUE), "Production runner summary should report production_aggregate mode.")

count_source_text <- paste(readLines(file.path(root, "R", "mcl_triangle_counts.R"), warn = FALSE), collapse = "\n")
build_def_hits <- gregexpr("(?m)^mcl_count_build_outputs <- function", count_source_text, perl = TRUE)[[1]]
write_def_hits <- gregexpr("(?m)^mcl_count_write_outputs <- function", count_source_text, perl = TRUE)[[1]]
expect_equal(sum(build_def_hits > 0), 1L, "Only one authoritative mcl_count_build_outputs() definition should remain.")
expect_equal(sum(write_def_hits > 0), 1L, "Only one authoritative mcl_count_write_outputs() definition should remain.")

pdm_acceptance <- mcl_count_read_person_date_mapping(root)
lyfo_acceptance <- mcl_count_source_mapping(pdm_acceptance, "RKKP_LYFO", "RKKP_LYFO")
age_anchor_info <- mcl_count_age_anchor_sql_info(lyfo_acceptance)
expect_equal(age_anchor_info$columns, c("Reg_BehandlingBeslutning_dt", "Beh_KemoterapiStart_dt", "Reg_DiagnostiskBiopsi_dt"), "Age counts should use the same coalesced anchor order as age validation.")
expect_true(grepl("coalesce", age_anchor_info$expr, fixed = TRUE), "Age anchor SQL should coalesce the configured treatment-decision/start/biopsy dates.")

treatment_acceptance <- mcl_count_read_treatment_code_mappings(root)
direct_ib_sql <- mcl_count_ibrutinib_source_validation_sql(treatment_acceptance[treatment_acceptance$source_id == "SDS_indberetningmedpris_ATC_L01XE27", , drop = FALSE], lyfo_acceptance)
sks_ib_sql <- mcl_count_ibrutinib_source_validation_sql(treatment_acceptance[treatment_acceptance$source_id == "SDS_t_sksube_SKS_BWHA169", , drop = FALSE], lyfo_acceptance)
expect_true(grepl("left join mcl on", direct_ib_sql, fixed = TRUE), "Direct Ibrutinib source validation should join against the mcl CTE.")
expect_false(grepl("left join m on", direct_ib_sql, fixed = TRUE), "Direct Ibrutinib source validation should not reference m.")
expect_true(grepl("::text = source_rows.bridge_key::text", sks_ib_sql, fixed = TRUE), "Bridged SKS validation should cast bridge keys for type-compatible comparison.")
expect_true(grepl("left join mcl on", sks_ib_sql, fixed = TRUE), "Bridged SKS validation should join against the mcl CTE.")

ki67_norm_sql <- mcl_count_ki67_aeki_normalized_sql("p")
expect_true(grepl("'Æ'", ki67_norm_sql, fixed = TRUE), "Ki-67 AEKI normalization should handle actual Danish ÆKI codes.")
expect_true(grepl("'Ã†'", ki67_norm_sql, fixed = TRUE), "Ki-67 AEKI normalization should handle mojibake AEKI codes.")
ki67_person_sql <- mcl_count_ki67_aeki_person_sql(pdm_acceptance, threshold_percent = 30L)
expect_true(grepl("between 0 and 100", ki67_person_sql, fixed = TRUE), "AEKI000-AEKI100 should be the accepted numeric code range.")
ki67_bridge_sql <- mcl_count_ki67_bridge_validation_sql(pdm_acceptance, "SDS_t_mikro_ny")
expect_true(grepl("t.text_value", ki67_bridge_sql, fixed = TRUE), "Ki-67 text bridge SQL should reference the aliased text rows.")
expect_false(grepl("text_rows.text_value", ki67_bridge_sql, fixed = TRUE), "Ki-67 text bridge SQL should not reference the pre-alias name.")

vm_acceptance <- mcl_count_read_value_mappings(root)
cit_rows <- vm_acceptance[vm_acceptance$data_point_id == "cit_immunochemotherapy", , drop = FALSE]
expect_false(any(grepl("(^|;)ibrutinib(;|$)", cit_rows$mapped_values, ignore.case = TRUE, perl = TRUE)), "CIT/immunochemotherapy mapping must not include Ibrutinib.")

no_atlas_audit <- mcl_count_atlas_input_audit("", "")
expect_equal(no_atlas_audit$selection_reason[[1]], "atlas_input_not_supplied", "No-atlas mode should be explicit in atlas input audit.")
expect_false(no_atlas_audit$atlas_input_supplied[[1]], "No-atlas audit should not pretend that atlas input was searched.")

atlas_acceptance_dir <- tempfile("mcl_atlas_acceptance_")
dir.create(atlas_acceptance_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(data.frame(
  source_name = c("core.public.patient", "import.public.SDS_t_tumor", "SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin", "RKKP_CLL"),
  table_name = c("patient", "SDS_t_tumor", "SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin", "RKKP_CLL"),
  db_name = c("core", rep("import", 7)),
  schema = "public",
  stringsAsFactors = FALSE
), file.path(atlas_acceptance_dir, "atlas_sources.csv"))
write_csv(data.frame(
  table_name = c("patient", "SDS_t_tumor", "SDS_t_tumor", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "SDS_indberetningmedpris", "SDS_t_sksube", "SDS_epikur", "SDS_ekokur", "SP_OrdineretMedicin", "RKKP_CLL"),
  column_name = c("date_birth", "d_fdsdato", "v_diagnosealder", "Reg_BehandlingBeslutning_dt", "Beh_KemoterapiStart_dt", "Reg_DiagnostiskBiopsi_dt", "c_atc", "c_opr", "atc", "atc", "atc", "Beh_TargeteretBeh_Ibrutinib"),
  db_name = c("core", rep("import", 11)),
  schema = "public",
  data_type = "text",
  stringsAsFactors = FALSE
), file.path(atlas_acceptance_dir, "atlas_columns.csv"))
atlas_audit <- mcl_count_atlas_input_audit(atlas_output_dir = atlas_acceptance_dir)
expect_true(atlas_audit$atlas_input_supplied[[1]], "Atlas audit should record supplied atlas directories.")
expect_true(atlas_audit$atlas_sources_rows[[1]] > 0L && atlas_audit$atlas_columns_rows[[1]] > 0L, "Atlas audit should count searched atlas source/column rows.")
expect_true(nrow(mcl_count_read_atlas_age_inventory(atlas_output_dir = atlas_acceptance_dir)) > 0L, "Atlas age inventory should populate from supplied atlas source/column evidence.")
expect_true(nrow(mcl_count_read_atlas_treatment_inventory(atlas_output_dir = atlas_acceptance_dir)) > 0L, "Atlas treatment inventory should populate from supplied atlas source/column evidence.")

runner_files <- c("mcl_triangle_atlas_input_audit.csv", "mcl_triangle_failed_query_audit.csv")
for (name in runner_files) {
  expect_file(file.path(runner_dir, name))
}
runner_summary <- read_delimited_file(file.path(runner_dir, "mcl_triangle_execution_summary.csv"))
for (name in c("core_marginal_counts_succeeded", "age_validation_succeeded", "ibrutinib_validation_succeeded", "ki67_validation_succeeded", "atlas_ingestion_succeeded", "acceptance_status")) {
  expect_true(name %in% names(runner_summary), paste("Execution summary should include", name))
}
expect_true(grepl("acceptance status", runner_console_text, fixed = TRUE), "Runner console summary should include acceptance status.")
