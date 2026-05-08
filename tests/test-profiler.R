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

sparse_lyfo <- profile_source(data.frame(patientid = 1:2, stringsAsFactors = FALSE), "RKKP_LYFO", "file", "lyfo.csv", min_cell_count = 1L)
expect_equal(nrow(sparse_lyfo$panels$lyfo_clinical_profile), 0L, "Missing registry columns should produce an empty valid panel.")
expect_true(all(c("table_name", "registry", "facet", "source_column", "label", "n", "pct_rows") %in% names(sparse_lyfo$panels$lyfo_clinical_profile)), "Empty registry panels should retain the expected schema.")

schema_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "schema", min_cell_count = 1L)
expect_equal(nrow(schema_profile$value_frequencies), 0L, "Schema profile mode should not emit value frequencies.")
expect_equal(length(schema_profile$panels), 0L, "Schema profile mode should not emit panels.")

summary_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "summary", min_cell_count = 1L)
expect_equal(nrow(summary_profile$value_frequencies), 0L, "Summary profile mode should not emit value frequencies.")
expect_true("registry_clinical_summary" %in% names(summary_profile$panels), "Summary profile mode should emit high-level panels.")
expect_false("damyda_clinical_profile" %in% names(summary_profile$panels), "Summary profile mode should skip detailed registry panels.")

full_profile <- profile_source(registry_damyda, "RKKP_DaMyDa", "file", "damyda.csv", profile_mode = "full", min_cell_count = 1L)
expect_true(nrow(full_profile$value_frequencies) > 0, "Full profile mode should emit eligible value frequencies.")
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
