root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

df <- data.frame(
  patientid = c("0101011234", "0202021234", "0303031234"),
  analysiscode = c("NPU03230", "NPU03230", "NPU19675"),
  samplingdate = c("2020-01-01", "2020-01-02", "2020-01-03"),
  group = c("A", "A", "B"),
  stringsAsFactors = FALSE
)

profile <- profile_source(df, "labs", "file", "labs.csv", min_cell_count = 1L)
expect_equal(profile$source$n_rows[[1]], 3L, "Profile should record row count.")
expect_true("patientid" %in% profile$columns$column_name, "Column inventory should include patientid column names.")
expect_false(any(profile$value_frequencies$column_name == "patientid"), "Value frequencies must suppress patient identifiers.")
expect_true(any(profile$checks$check_id == "sensitive_column_values_suppressed"), "Privacy suppression check should be emitted.")
expect_true(nrow(profile$panels$lab_npu_code_coverage) > 0, "Lab code panel should be generated.")
expect_true(all(names(df) %in% profile$column_profiles$column_name), "Every input column should have a safe aggregate column profile.")
expect_equal(nrow(profile$column_profiles), ncol(df), "Column profile output should have one row per input column.")
patient_profile <- profile$column_profiles[profile$column_profiles$column_name == "patientid", , drop = FALSE]
expect_equal(patient_profile$profile_kind[[1]], "sensitive", "Patient identifiers should be marked sensitive in column profiles.")
expect_true(is.na(patient_profile$min[[1]]) && is.na(patient_profile$max_date[[1]]), "Sensitive columns should not expose detailed stats.")
expect_false(any(profile$column_top_values$column_name == "patientid"), "Sensitive columns should not emit top values.")
expect_true(any(profile$column_top_values$column_name == "group"), "Eligible categorical columns should emit top values in full mode.")

column_detail_df <- data.frame(
  numeric_lab = c(1, 2, 3, 4, NA),
  event_date = c("2020-01-01", "2020-01-03", "", "2020-02-01", "2020-02-04"),
  category = c("A", "A", "B", "B", "rare"),
  stringsAsFactors = FALSE
)
column_detail_profile <- profile_source(column_detail_df, "column_detail", "file", "detail.csv", min_cell_count = 2L)
numeric_profile <- column_detail_profile$column_profiles[column_detail_profile$column_profiles$column_name == "numeric_lab", , drop = FALSE]
date_profile <- column_detail_profile$column_profiles[column_detail_profile$column_profiles$column_name == "event_date", , drop = FALSE]
category_top <- column_detail_profile$column_top_values[column_detail_profile$column_top_values$column_name == "category", , drop = FALSE]
expect_equal(numeric_profile$profile_kind[[1]], "numeric", "Numeric-like columns should be profiled as numeric.")
expect_equal(numeric_profile$median[[1]], 2.5, "Numeric column profiles should include aggregate numeric stats.")
expect_equal(date_profile$profile_kind[[1]], "date", "Date-like columns should be profiled as dates.")
expect_equal(date_profile$min_date[[1]], "2020-01-01", "Date column profiles should include minimum date.")
expect_equal(date_profile$max_date[[1]], "2020-02-04", "Date column profiles should include maximum date.")
expect_false(any(category_top$value == "rare"), "Column top values should obey minimum cell suppression.")

damyda <- data.frame(
  patientid = c(1, 2),
  iss_stage = c("I", "II"),
  bone_disease = c("no", "yes"),
  stringsAsFactors = FALSE
)
damyda_profile <- profile_source(damyda, "RKKP_DaMyDa", "file", "damyda.csv", min_cell_count = 1L)
expect_true(nrow(damyda_profile$panels$damyda_feature_coverage) > 0, "DaMyDa coverage panel should be generated.")
expect_false(any(damyda_profile$panels$damyda_feature_coverage$feature == "patientid"), "DaMyDa panel should suppress patient identifiers.")

registry_damyda <- data.frame(
  patientid = c("0101011234", "0202021234", "0303031234", "0404041234"),
  diagnosis_date = c("2021-01-01", "2021-02-01", "2021-03-01", "2021-04-01"),
  iss_stage = c("I", "II", "II", "III"),
  bone_disease = c("no", "yes", "yes", "no"),
  treatment_required = c("yes", "yes", "no", "yes"),
  primary_response = c("VGPR", "PR", "", "CR"),
  albumin = c(41, 38, NA, 32),
  Reg_Creatinin = c(72, 85, NA, 110),
  stringsAsFactors = FALSE
)
registry_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", min_cell_count = 1L)
summary_panel <- registry_profile$panels$registry_clinical_summary
expect_equal(summary_panel$registry[[1]], "DaMyDa", "Registry summary should identify DaMyDa.")
expect_equal(summary_panel$n_patients[[1]], 4L, "Registry summary should count distinct patients only as an aggregate.")

clinical_panel <- registry_profile$panels$damyda_clinical_profile
expect_true(nrow(clinical_panel) > 0, "DaMyDa clinical profile should be generated.")
expect_true(all(c("table_name", "registry", "facet", "source_column", "label", "n", "pct_rows") %in% names(clinical_panel)), "Clinical profile should use the flat categorical schema.")
expect_true(any(clinical_panel$facet == "stage"), "DaMyDa clinical profile should include stage.")
expect_false(any(clinical_panel$source_column == "patientid"), "Registry categorical panels must not expose patient identifier columns.")
expect_false(any(grepl("0101011234", clinical_panel$label, fixed = TRUE)), "Registry categorical labels must not expose patient IDs.")

numeric_panel <- registry_profile$panels$damyda_numeric_fields
expect_true(nrow(numeric_panel) > 0, "DaMyDa numeric field profile should be generated.")
expect_true(all(c("table_name", "registry", "field", "source_column", "unit", "n_available", "pct_available", "mean", "median", "p25", "p75") %in% names(numeric_panel)), "Numeric profile should use the aggregate schema.")
expect_true(any(numeric_panel$field == "albumin"), "DaMyDa numeric fields should include albumin when present.")
expect_false(any(c("value", "examples", "distinct_sample") %in% names(numeric_panel)), "Numeric registry panel should not include raw values or examples.")

dalycare_damyda <- data.frame(
  patientid = c(1, 2, 3, 4),
  Stadie = c("I", "II", "II", "III"),
  Cyto_FishUdfoert = c("yes", "yes", "no", "yes"),
  Reg_Diagnose_dt = c("2021-01-01", "2021-02-01", "2021-03-01", "2021-04-01"),
  Reg_OrganisationKode_Shak = c("1500", "1500", "1300", "1300"),
  HB = c(7.1, 6.8, 8.2, 7.7),
  CREA = c(72, 85, 91, 110),
  B2M = c(2.1, 3.4, 2.8, 5.2),
  ALB = c(41, 38, 36, 32),
  LDH = c(180, 210, 190, 260),
  stringsAsFactors = FALSE
)
dalycare_damyda_profile <- profile_source(dalycare_damyda, "RKKP_DaMyDa", "file", "damyda.csv", min_cell_count = 1L)
expect_true(any(dalycare_damyda_profile$panels$damyda_clinical_profile$source_column == "Stadie"), "DaMyDa aliases should match cleaner/raw Stadie.")
expect_true(any(dalycare_damyda_profile$panels$damyda_clinical_profile$source_column == "Cyto_FishUdfoert"), "DaMyDa aliases should match cleaner/raw FISH status.")
expect_true(any(dalycare_damyda_profile$panels$damyda_clinical_profile$source_column == "Reg_OrganisationKode_Shak"), "DaMyDa aliases should match organisation SHAK.")
expect_true(all(c("HB", "CREA", "B2M", "ALB", "LDH") %in% dalycare_damyda_profile$panels$damyda_numeric_fields$source_column), "DaMyDa numeric aliases should match cleaner-style lab fields.")

lyfo <- data.frame(
  patientid = c(1, 2, 3),
  Reg_Subtype = c("DLBCL", "FL", "DLBCL"),
  Reg_AnnArbor = c("III", "II", "IV"),
  Reg_IPI = c("2", "1", "3"),
  Reg_BSymptomer = c("yes", "no", "yes"),
  stringsAsFactors = FALSE
)
lyfo_profile <- profile_source(lyfo, "RKKP_LYFO", "file", "lyfo.csv", min_cell_count = 1L)
expect_true(nrow(lyfo_profile$panels$lyfo_clinical_profile) > 0, "LYFO clinical profile should be generated.")
expect_true(any(lyfo_profile$panels$lyfo_clinical_profile$facet == "subtype"), "LYFO profile should include subtype.")

dalycare_lyfo <- data.frame(
  patientid = c(1, 2, 3),
  Reg_DiagnostiskBiopsi_dt = c("2020-01-01", "2020-02-01", "2020-03-01"),
  Reg_Stadium = c("III", "II", "IV"),
  Reg_PerformanceStatusWHO = c("0", "1", "2"),
  Reg_BulkSygdom = c("no", "yes", "no"),
  Reg_BSymptomer = c("yes", "no", "yes"),
  stringsAsFactors = FALSE
)
dalycare_lyfo_profile <- profile_source(dalycare_lyfo, "RKKP_LYFO", "file", "lyfo.csv", min_cell_count = 1L)
expect_true(any(dalycare_lyfo_profile$panels$lyfo_clinical_profile$source_column == "Reg_Stadium"), "LYFO aliases should match Reg_Stadium.")
expect_true(any(dalycare_lyfo_profile$panels$lyfo_clinical_profile$source_column == "Reg_PerformanceStatusWHO"), "LYFO aliases should match Reg_PerformanceStatusWHO.")
expect_true(any(dalycare_lyfo_profile$panels$lyfo_clinical_profile$source_column == "Reg_BulkSygdom"), "LYFO aliases should match Reg_BulkSygdom.")

cll <- data.frame(
  patientid = c(1, 2, 3),
  Reg_Binet = c("A", "B", "C"),
  Reg_IGHV = c("mutated", "unmutated", "unmutated"),
  Reg_Del17p = c("negative", "negative", "positive"),
  Reg_TP53 = c("wildtype", "mutated", "mutated"),
  stringsAsFactors = FALSE
)
cll_profile <- profile_source(cll, "RKKP_CLL", "file", "cll.csv", min_cell_count = 1L)
expect_true(nrow(cll_profile$panels$cll_clinical_profile) > 0, "CLL clinical profile should be generated.")
expect_true(any(cll_profile$panels$cll_clinical_profile$facet == "tp53"), "CLL profile should include TP53.")

dalycare_cll <- data.frame(
  patientid = c(1, 2, 3, 4),
  Reg_BinetStadium = c("A", "B", "B", "C"),
  Reg_Umuteret = c("no", "yes", "yes", "no"),
  Reg_Del13q14 = c("positive", "negative", "positive", "negative"),
  Reg_Trisomi12 = c("negative", "positive", "negative", "negative"),
  Reg_CD38Positiv = c("no", "yes", "no", "yes"),
  Reg_Performancestatus = c("0", "1", "1", "2"),
  stringsAsFactors = FALSE
)
dalycare_cll_profile <- profile_source(dalycare_cll, "RKKP_CLL", "file", "cll.csv", min_cell_count = 1L)
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_BinetStadium"), "CLL aliases should match Reg_BinetStadium.")
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_Umuteret"), "CLL aliases should match Reg_Umuteret.")
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_Del13q14"), "CLL aliases should match Reg_Del13q14.")
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_Trisomi12"), "CLL aliases should match Reg_Trisomi12.")
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_CD38Positiv"), "CLL aliases should match Reg_CD38Positiv.")
expect_true(any(dalycare_cll_profile$panels$cll_clinical_profile$source_column == "Reg_Performancestatus"), "CLL aliases should match Reg_Performancestatus.")

sparse_lyfo <- profile_source(data.frame(patientid = 1:2, stringsAsFactors = FALSE), "RKKP_LYFO", "file", "lyfo.csv", min_cell_count = 1L)
expect_equal(nrow(sparse_lyfo$panels$lyfo_clinical_profile), 0L, "Missing registry columns should produce an empty valid panel.")
expect_true(all(c("table_name", "registry", "facet", "source_column", "label", "n", "pct_rows") %in% names(sparse_lyfo$panels$lyfo_clinical_profile)), "Empty registry panels should retain the expected schema.")

schema_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "schema", min_cell_count = 1L)
expect_equal(nrow(schema_profile$value_frequencies), 0L, "Schema profile mode should not emit value frequencies.")
expect_equal(length(schema_profile$panels), 0L, "Schema profile mode should not emit panels.")
expect_equal(nrow(schema_profile$column_top_values), 0L, "Schema profile mode should not emit column top values.")
expect_true(all(is.na(schema_profile$column_profiles$median)), "Schema profile mode should keep column profiles to metadata only.")

summary_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "summary", min_cell_count = 1L)
expect_equal(nrow(summary_profile$value_frequencies), 0L, "Summary profile mode should not emit value frequencies.")
expect_true("registry_clinical_summary" %in% names(summary_profile$panels), "Summary profile mode should emit high-level panels.")
expect_false("damyda_clinical_profile" %in% names(summary_profile$panels), "Summary profile mode should skip detailed registry panels.")

full_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "full", min_cell_count = 1L)
expect_true(nrow(full_profile$value_frequencies) > 0, "Full profile mode should emit eligible value frequencies.")
expect_true(nrow(full_profile$column_top_values) > 0, "Full profile mode should emit eligible column top values.")
expect_true("damyda_clinical_profile" %in% names(full_profile$panels), "Full profile mode should emit detailed registry panels.")

privacy_df <- data.frame(
  group = c("rare", "rare", "common", "common", "common", "common", "common"),
  stage = c("I", "I", "II", "II", "II", "II", "II"),
  stringsAsFactors = FALSE
)
privacy_profile <- profile_source(privacy_df, "RKKP_DaMyDa", "file", "privacy.csv", min_cell_count = 5L)
expect_false(any(privacy_profile$value_frequencies$value == "rare"), "Value frequencies below the minimum cell count should be suppressed.")
expect_false(any(privacy_profile$panels$damyda_clinical_profile$label == "I"), "Registry category counts below the minimum cell count should be suppressed.")
expect_true(any(privacy_profile$panels$damyda_clinical_profile$label == "II"), "Registry categories at or above the minimum cell count should remain visible.")
