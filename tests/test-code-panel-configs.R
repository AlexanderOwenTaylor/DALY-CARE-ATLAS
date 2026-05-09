root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

dictionary <- load_npu_consensus_dictionary(project_root = root)
surfaces <- load_npu_detective_surfaces(project_root = root)
isotypes <- load_isotype_vectors(project_root = root, dictionary = dictionary)
treatments <- load_mm_treatment_code_families(project_root = root)

expect_true(all(c("surface", "candidate_label", "consensus_vectors", "system_include", "system_exclude", "clinical_role_pattern") %in% names(surfaces)), "NPU detective config should expose the required columns.")
expect_true(nrow(surfaces) >= 8L, "NPU detective config should include the core myeloma lab surfaces.")
expect_true(any(surfaces$surface == "mspike_plasma"), "NPU detective config should include plasma M-spike surfaces.")

expect_true(all(c("isotype_family", "specimen_class", "bucket", "consensus_vector", "npu_code") %in% names(isotypes)), "Isotype config should expose the required columns.")
expect_true(any(isotypes$npu_code == "NPU28638" & isotypes$isotype_family == "IgG"), "Isotype config should expand consensus vectors to dictionary NPU codes.")
expect_true(any(isotypes$specimen_class == "urine"), "Isotype config should include urine isotype vectors.")

expect_true(all(c("family", "code_system", "match_type", "code", "label", "source_hint") %in% names(treatments)), "MM treatment config should expose the required columns.")
expect_true(any(treatments$code == "BWHA154" & treatments$match_type == "exact"), "MM treatment config should include Cecilie's exact BWHA codes.")
expect_true(any(treatments$code == "BWG" & treatments$match_type == "prefix"), "MM treatment config should include prefix family rules.")
expect_false(any(duplicated(paste(treatments$family, treatments$code_system, treatments$match_type, treatments$code, sep = "|"))), "MM treatment code family keys should be unique.")

bad_treatments <- tempfile(fileext = ".tsv")
writeLines(c(
  "family\tcode_system\tmatch_type\tcode\tlabel\tsource_hint",
  "broken\tSKS\tcontains\tBWHA\tBroken\tprocedure"
), bad_treatments)
err <- tryCatch(load_mm_treatment_code_families(path = bad_treatments), error = function(e) conditionMessage(e))
expect_true(grepl("invalid match_type", err, fixed = TRUE), "Invalid treatment match types should fail clearly.")
