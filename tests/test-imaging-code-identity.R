root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)
for (code in c("UXZ10", "UXZ11")) {
  result <- imaging_column_definition("SDS_t_sksube", "SDS_t_sksube", "c_opr", code)
  expect_equal(result$concept_id, "imaging_contrast", "Contrast codes must not establish CT or MRI modality.")
  expect_false(any(result$terms %in% c("CT", "MRI", "MR")), "Contrast-only evidence must not acquire modality aliases.")
}
expect_equal(imaging_column_definition("SDS_t_sksube", "SDS_t_sksube", "c_opr", "UXCC00")$concept_id, "imaging_ct")
expect_equal(imaging_column_definition("SDS_t_sksube", "SDS_t_sksube", "c_opr", "APAA4")$concept_id, "administrative_staff_role", "Hospital physician is a personnel code, not a CT procedure.")
expect_equal(semantic_domain_keep_rows(c("APAA4", "apaa4", "UXCC00", "UXZ10", "UXZ11"), "Imaging"), c(FALSE, FALSE, TRUE, TRUE, TRUE), "Staff codes must not enter imaging coverage; contrast context remains relevant.")
cat("Imaging code identity tests passed\n")
