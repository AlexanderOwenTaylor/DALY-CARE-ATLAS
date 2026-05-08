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

profile <- profile_source(df, "labs", "file", "labs.csv")
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
damyda_profile <- profile_source(damyda, "RKKP_DaMyDa", "file", "damyda.csv")
expect_true(nrow(damyda_profile$panels$damyda_feature_coverage) > 0, "DaMyDa coverage panel should be generated.")
expect_false(any(damyda_profile$panels$damyda_feature_coverage$feature == "patientid"), "DaMyDa panel should suppress patient identifiers.")

