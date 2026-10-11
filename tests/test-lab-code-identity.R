root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

# Catch code/name swaps even when a stale upstream label contradicts the code.
cases <- list(
  c("NPU02593", "Creatinine", "leukocytes"),
  c("NPU04998", "CRP", "creatinine"),
  c("NPU19748", "Leukocytes", "crp"),
  c("NPU02636", "LDH", "lymphocytes"),
  c("NPU19658", "", "ldh"),
  c("NPU19673", "", "albumin"),
  c("NPU03568", "", "platelets")
)
for (case in cases) {
  actual <- lab_concept_definition(case[[1]], case[[2]])
  expect_equal(actual$concept_id, case[[3]], paste("Incorrect clinical identity for", case[[1]]))
}
expect_false(lab_concept_definition("NPU01349", "Albumin")$concept_id == "albumin",
             "A basophil code must not become albumin from a stale label")
expect_false(lab_concept_definition("NPU99999", "Creatinine")$concept_id == "creatinine",
             "Unknown NPU codes must not inherit an unverified name-based identity")
expect_equal(lab_concept_definition("Reg_Creatinin_mikmoll", "")$concept_id, "creatinine")
cat("Laboratory code identity tests passed\n")
