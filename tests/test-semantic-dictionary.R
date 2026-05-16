root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

validate_cartography_reference(root)
manifest <- utils::read.delim(file.path(root, "config", "cartography-reference", "manifest.tsv"), stringsAsFactors = FALSE, check.names = FALSE)
expect_true(nrow(manifest) >= 100, "Cartography reference manifest should list curated evidence files.")
expect_true(all(c("original_filename", "reference_filename", "curated_rows", "source_zip_sha256") %in% names(manifest)), "Cartography manifest should record provenance and row counts.")

semantic <- build_semantic_outputs(project_root = root, min_cell_count = 5)
dictionary <- semantic$dictionary
value_map <- semantic$value_map
code_map <- semantic$code_map
panel_links <- semantic$panel_links

expect_true(all(semantic_dictionary_columns() %in% names(dictionary)), "Semantic dictionary should have the required lineage columns.")
expect_true(all(semantic_value_map_columns() %in% names(value_map)), "Semantic value map should have the required columns.")
expect_true(all(semantic_code_map_columns() %in% names(code_map)), "Semantic code map should have the required columns.")
expect_true(all(semantic_panel_links_columns() %in% names(panel_links)), "Semantic panel links should have the required columns.")
expect_true(nrow(dictionary) > 500, "Semantic dictionary should be populated from the cartography reference.")
expect_true(nrow(value_map) > 10, "Semantic value map should include categorical value mappings.")
expect_true(nrow(code_map) > 100, "Semantic code map should include code-level mappings.")

search_semantic <- function(query) {
  hay <- apply(dictionary, 1, paste, collapse = " ")
  dictionary[grepl(query, hay, ignore.case = TRUE), , drop = FALSE]
}

expect_true(any(search_semantic("ryger")$clinical_variable == "Smoking status"), "Search for ryger should return Smoking status.")
expect_true(any(search_semantic("drikker")$clinical_variable == "Alcohol use"), "Search for drikker should return Alcohol use.")
expect_true(any(search_semantic("Vægt")$clinical_variable == "Weight"), "Search for Vægt should return Weight.")
expect_true(any(search_semantic("Højde")$clinical_variable == "Height"), "Search for Højde should return Height.")
expect_true(any(grepl("numericvalue", search_semantic("numericvalue")$raw_column, fixed = TRUE)), "Search for numericvalue should return the SP vital numeric value field.")
expect_true(any(search_semantic("Reg_LDH")$clinical_variable == "LDH"), "Search for Reg_LDH should return DaMyDa LDH.")
expect_true(any(search_semantic("Reg_Creatinin_mikmoll")$clinical_variable == "Creatinine"), "Search for Reg_Creatinin_mikmoll should return creatinine.")
crp_rows <- dictionary[dictionary$source_name == "RKKP_DaMyDa" & dictionary$raw_column %in% c("Reg_CReaktivtProtein_gl", "Reg_CReaktivtProtein_nMoll"), , drop = FALSE]
expect_true(nrow(crp_rows) >= 2, "DaMyDa CRP fields should be present in the semantic dictionary.")
expect_true(all(crp_rows$clinical_concept_id == "crp" & crp_rows$clinical_variable == "CRP"), "DaMyDa C-reactive protein fields should map to CRP.")
expect_false(any(crp_rows$clinical_concept_id == "creatinine" | crp_rows$clinical_variable == "Creatinine"), "DaMyDa C-reactive protein fields must not map to creatinine.")
corrected_calcium <- dictionary[dictionary$source_name == "RKKP_DaMyDa" & dictionary$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(corrected_calcium) > 0, "DaMyDa albumin-corrected calcium should be present in the semantic dictionary.")
expect_true(all(corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "DaMyDa albumin-corrected calcium should have a distinct concept id.")
expect_false(any(corrected_calcium$clinical_concept_id == "albumin" | corrected_calcium$clinical_variable == "Albumin"), "DaMyDa albumin-corrected calcium must not map to albumin.")
fish_availability <- dictionary[dictionary$source_name == "RKKP_DaMyDa" & dictionary$raw_column == "Cyto_FishUdfoert", , drop = FALSE]
fish_probe <- dictionary[dictionary$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishProber_", dictionary$raw_column), , drop = FALSE]
fish_result <- dictionary[dictionary$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishResultat_", dictionary$raw_column), , drop = FALSE]
expect_true(any(fish_availability$clinical_concept_id == "fish_availability"), "Cyto_FishUdfoert should retain FISH availability context.")
expect_true(nrow(fish_probe) > 0 && all(fish_probe$clinical_concept_id == "fish_probe"), "Cyto_FishProber fields should map to FISH probe context.")
expect_true(nrow(fish_result) > 0 && all(fish_result$clinical_concept_id == "fish_result"), "Cyto_FishResultat fields should map to FISH result context.")
expect_false(any(fish_probe$clinical_concept_id == "cytogenetic_risk"), "FISH probe fields must not collapse into generic cytogenetic risk.")

lyfo_rows <- dictionary[dictionary$source_name == "RKKP_LYFO", , drop = FALSE]
lyfo_histology <- lyfo_rows[lyfo_rows$raw_column %in% c("Reg_WHOHistologikode1", "Reg_WHOHistologikode2", "Rec_WHOHistologikode"), , drop = FALSE]
expect_true(nrow(lyfo_histology) > 0, "LYFO WHO histology fields should be present in the semantic dictionary when evidenced.")
expect_true(any(lyfo_histology$clinical_concept_id == "lymphoma_subtype_code" & lyfo_histology$clinical_variable == "WHO histology code"), "LYFO WHO histology fields should map to subtype/histology-code context.")
expect_false(any(lyfo_histology$clinical_concept_id == "performance_status" | lyfo_histology$clinical_variable == "Performance status"), "LYFO WHO histology fields must not map to performance status.")

lyfo_performance <- lyfo_rows[lyfo_rows$raw_column %in% c("Reg_PerformanceStatusWHO", "Beh_PerformanceStatus", "Rec_Performancestatus"), , drop = FALSE]
expect_true(nrow(lyfo_performance) > 0 && all(lyfo_performance$clinical_concept_id == "performance_status"), "LYFO performance-status fields should map to performance status.")
lyfo_corrected_calcium <- lyfo_rows[lyfo_rows$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(lyfo_corrected_calcium) > 0, "LYFO albumin-corrected calcium should be present in the semantic dictionary.")
expect_true(all(lyfo_corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "LYFO albumin-corrected calcium should have a distinct concept id.")
expect_false(any(lyfo_corrected_calcium$clinical_concept_id == "albumin" | lyfo_corrected_calcium$clinical_variable == "Albumin"), "LYFO albumin-corrected calcium must not map to albumin.")
lyfo_pancreas <- lyfo_rows[lyfo_rows$raw_column == "Reg_Lokal_Pancreas", , drop = FALSE]
expect_true(nrow(lyfo_pancreas) > 0 && all(lyfo_pancreas$clinical_concept_id == "disease_localization"), "LYFO pancreas localization should map to disease localization.")
expect_false(any(lyfo_pancreas$clinical_concept_id == "creatinine" | lyfo_pancreas$clinical_variable == "Creatinine"), "LYFO pancreas localization must not map to creatinine.")
lyfo_ldh <- lyfo_rows[lyfo_rows$raw_column %in% c("Reg_Lactatdehydrogenase", "Reg_LDHVaerdi"), , drop = FALSE]
if (nrow(lyfo_ldh)) {
  expect_true(all(lyfo_ldh$clinical_concept_id == "ldh" & lyfo_ldh$clinical_variable == "LDH"), "LYFO LDH fields should map to LDH.")
}
lyfo_b_symptoms <- lyfo_rows[lyfo_rows$raw_column == "Reg_BSymptomer", , drop = FALSE]
lyfo_bulk <- lyfo_rows[lyfo_rows$raw_column == "Reg_BulkSygdom", , drop = FALSE]
expect_true(nrow(lyfo_b_symptoms) > 0 && all(lyfo_b_symptoms$clinical_concept_id == "b_symptoms"), "LYFO B-symptom field should map to B symptoms.")
expect_true(nrow(lyfo_bulk) > 0 && all(lyfo_bulk$clinical_concept_id == "bulk_disease"), "LYFO bulk-disease field should map to bulk disease.")
index_expectations <- c(IPI = "ipi", aaIPI = "aaipi", FLIPI = "flipi", FLIPI2 = "flipi2", IPS = "ips")
for (raw_field in names(index_expectations)) {
  concept <- unname(index_expectations[[raw_field]])
  rows <- lyfo_rows[lyfo_rows$raw_column == raw_field, , drop = FALSE]
  if (nrow(rows)) {
    expect_true(all(rows$clinical_concept_id == concept), paste("LYFO prognostic index should preserve its raw name:", raw_field))
    expect_true(all(rows$clinical_variable == raw_field), paste("LYFO prognostic index should use the raw visible label:", raw_field))
  }
}

cll_rows <- dictionary[dictionary$source_name == "RKKP_CLL", , drop = FALSE]
expect_cll_mapping <- function(raw_column, concept_id, variable_pattern) {
  rows <- cll_rows[cll_rows$raw_column == raw_column, , drop = FALSE]
  if (nrow(rows)) {
    expect_true(
      any(rows$clinical_concept_id == concept_id & grepl(variable_pattern, rows$clinical_variable, ignore.case = TRUE)),
      paste("CLL field should map to", concept_id, "with expected label:", raw_column)
    )
  }
}
expect_cll_mapping("Reg_BinetStadium", "binet_stage", "Binet stage")
expect_cll_mapping("Reg_Umuteret", "ighv_mutation_status", "IGHV mutation status")
expect_cll_mapping("Reg_FISH", "fish_availability", "FISH")
expect_cll_mapping("Reg_Del17p", "del17p", "del\\(17p\\)")
expect_cll_mapping("Reg_Del11q", "del11q", "del\\(11q\\)")
expect_cll_mapping("Reg_Del13q14", "del13q14", "del\\(13q14\\)")
expect_cll_mapping("Reg_Trisomi12", "trisomy12", "Trisomy 12")
expect_cll_mapping("Reg_TP53", "tp53_status", "TP53 status")
expect_cll_mapping("Beh_TP53Mutation", "tp53_status", "TP53 mutation")
expect_cll_mapping("Reg_KnoglemarvsUndersoegelse", "bone_marrow_examination", "bone marrow")
expect_cll_mapping("Reg_CTSCANNING", "cll_diagnostic_ct_workup", "CT workup")
expect_cll_mapping("Reg_ULSCANNING", "cll_diagnostic_ultrasound_workup", "ultrasound workup")
expect_cll_mapping("Beh_Vaegttab", "weight_loss", "Weight loss")
expect_cll_mapping("Beh_Feber", "fever", "Fever")
expect_cll_mapping("Beh_Nattesved", "night_sweats", "Night sweats")
expect_cll_mapping("Beh_UdtaltTraethed", "marked_fatigue", "Marked fatigue")
expect_cll_mapping("Beh_Lymfadenopati", "lymphadenopathy", "Lymphadenopathy")
expect_cll_mapping("Beh_TargeteretBeh_Ibrutinib", "cll_targeted_therapy", "Ibrutinib")
expect_cll_mapping("Beh_TargeteretBeh_venetoclax", "cll_targeted_therapy", "Venetoclax")
expect_cll_mapping("Beh_TargeteretBeh_acalabrutinib", "cll_targeted_therapy", "Acalabrutinib")
expect_cll_mapping("Beh_MRD", "mrd", "MRD")
expect_cll_mapping("Beh_Responsevaluering", "response_evaluation", "Response evaluation")

cll_wrong_weight <- cll_rows[cll_rows$raw_column == "Beh_Vaegttab", , drop = FALSE]
expect_false(any(cll_wrong_weight$clinical_concept_id == "weight" | cll_wrong_weight$clinical_variable == "Weight"), "CLL weight-loss field must not map to weight measurement.")
cll_bone_marrow <- cll_rows[cll_rows$raw_column == "Reg_KnoglemarvsUndersoegelse", , drop = FALSE]
expect_false(any(cll_bone_marrow$clinical_concept_id == "bone_involvement" | grepl("bone involvement", cll_bone_marrow$clinical_variable, ignore.case = TRUE)), "CLL bone marrow examination must not map to bone involvement.")
cll_fish_like <- cll_rows[cll_rows$raw_column %in% c("Reg_FISH", "Reg_Del17p", "Beh_Del17p", "Reg_Del11q", "Reg_Del13q14", "Reg_Trisomi12", "Reg_TP53", "Beh_TP53Mutation", "Beh_FISH_TP53", "Rec_FISH_TP53"), , drop = FALSE]
expect_false(any(cll_fish_like$clinical_concept_id == "cytogenetic_risk"), "CLL FISH/del/TP53 fields must not collapse into generic cytogenetic risk.")
cll_symptoms <- cll_rows[cll_rows$raw_column %in% c("Beh_Vaegttab", "Beh_Feber", "Beh_Nattesved", "Beh_UdtaltTraethed", "Beh_Lymfadenopati", "Beh_StigendeLymfocytose"), , drop = FALSE]
expect_false(any(cll_symptoms$clinical_concept_id == "treatment" | cll_symptoms$clinical_variable == "Treatment signal"), "CLL symptom/treatment-indication fields must not map only to generic treatment.")
cll_workup <- cll_rows[cll_rows$raw_column %in% c("Reg_CTSCANNING", "Reg_ULSCANNING"), , drop = FALSE]
expect_false(any(cll_workup$clinical_concept_id == "imaging_availability"), "CLL registry workup fields must not be routed to general imaging availability.")
expect_true(any(search_semantic("NPU02319")$clinical_variable == "Haemoglobin"), "Search for NPU02319 should return haemoglobin.")
expect_true(any(grepl("eGFR", search_semantic("DNK35302")$clinical_variable, fixed = TRUE)), "Search for DNK35302 should return eGFR / CKD-EPI.")
expect_true(any(search_semantic("NPU19748")$clinical_variable == "Leukocytes"), "Search for NPU19748 should return leukocytes.")
expect_true(any(search_semantic("NPU02593")$clinical_concept_id == "creatinine"), "Search for NPU02593 should return creatinine.")
expect_true(any(search_semantic("NPU02636")$clinical_concept_id == "ldh"), "Search for NPU02636 should return LDH.")
expect_true(any(search_semantic("NPU01349")$clinical_concept_id == "albumin"), "Search for NPU01349 should return albumin.")
if (nrow(search_semantic("NPU04998"))) {
  expect_true(any(search_semantic("NPU04998")$clinical_concept_id == "crp"), "Search for NPU04998 should return CRP when evidenced.")
}
lab_rows <- dictionary[dictionary$clinical_group == "Laboratory", , drop = FALSE]
expect_false(any(grepl("CReaktivtProtein", lab_rows$raw_column, fixed = TRUE) & lab_rows$clinical_concept_id == "creatinine"), "Laboratory C-reactive protein rows must not map to creatinine.")
expect_false(any(lab_rows$raw_column == "Reg_CalciumAlbuminkorrigeret" & lab_rows$clinical_concept_id == "albumin"), "Laboratory albumin-corrected calcium must not map to albumin.")
expect_false(any(lab_rows$raw_column == "Reg_LYMFOCYTFORDOBLIN" & lab_rows$clinical_concept_id == "lymphocytes"), "Lymphocyte doubling must not map to lymphocyte count.")
expect_false(any(code_map$clinical_group == "Laboratory" & code_map$code_system %in% c("ATC", "SKS")), "ATC/SKS treatment rows must not appear as Laboratory code-map rows.")
npu_dnk_code_rows <- code_map[code_map$code_system %in% c("NPU", "DNK"), , drop = FALSE]
expect_false(any(npu_dnk_code_rows$clinical_group == "Treatment"), "NPU/DNK laboratory code rows must not be classified as Treatment.")
expect_false(any(grepl("^treatment_", npu_dnk_code_rows$clinical_concept_id)), "NPU/DNK laboratory code rows must not use treatment-prefixed concept IDs.")
expect_true(any(code_map$code == "NPU02319" & code_map$clinical_group == "Laboratory" & code_map$clinical_variable == "Haemoglobin"), "NPU02319 should remain Haemoglobin / Laboratory in the code map.")
expect_true(any(code_map$code == "NPU02593" & code_map$clinical_group == "Laboratory" & code_map$clinical_concept_id == "creatinine"), "NPU02593 should remain Creatinine / Laboratory in the code map.")
expect_true(any(code_map$code == "DNK35302" & code_map$clinical_group == "Laboratory" & code_map$clinical_concept_id == "egfr"), "DNK35302 should remain eGFR / Laboratory in the code map.")
if (any(code_map$code == "NPU04998")) {
  expect_true(any(code_map$code == "NPU04998" & code_map$clinical_group == "Laboratory" & code_map$clinical_concept_id == "crp"), "NPU04998 should remain CRP / Laboratory in the code map.")
}
treatment_matrix_lab_rows <- npu_dnk_code_rows[grepl("cartography_disease_treatment_matrix", npu_dnk_code_rows$evidence_file, fixed = TRUE), , drop = FALSE]
if (nrow(treatment_matrix_lab_rows)) {
  expect_true(all(grepl("supporting laboratory evidence; not treatment exposure", treatment_matrix_lab_rows$notes, fixed = TRUE)), "Treatment-matrix NPU/DNK rows should carry supporting-lab provenance caveat.")
}
expect_true(nrow(search_semantic("ATC")) > 0, "Search for ATC should return treatment/medication signals.")
expect_true(nrow(search_semantic("SKS")) > 0, "Search for SKS should return diagnosis/procedure/treatment/imaging signals.")
expect_true(nrow(search_semantic("SNOMED")) > 0, "Search for SNOMED should return pathology signals.")
expect_true(nrow(search_semantic("blood culture")) > 0, "Search for blood culture should return microbiology/SP blood-culture workflow signals.")

smoking_values <- value_map[value_map$semantic_id == "sp_social_hx_ryger_smoking_status", , drop = FALSE]
expect_true(any(smoking_values$raw_value == "Er holdt op" & smoking_values$display_value == "Former smoker"), "Smoking value map should classify former smokers.")
expect_true(any(smoking_values$raw_value == "Aldrig" & smoking_values$display_value == "Never smoker"), "Smoking value map should classify never smokers.")
expect_true(any(smoking_values$raw_value == "Ja" & smoking_values$display_value == "Current smoker"), "Smoking value map should classify current smokers.")
expect_true(any(smoking_values$raw_value == "Ikke spurgt" & smoking_values$display_value == "Not asked"), "Smoking value map should classify not-asked responses.")
expect_true(any(smoking_values$raw_value == "Passiv" & smoking_values$display_value == "Passive exposure"), "Smoking value map should classify passive exposure.")

alcohol_values <- value_map[value_map$semantic_id == "sp_social_hx_drikker_alcohol_use", , drop = FALSE]
expect_true(any(alcohol_values$raw_value == "Ja" & alcohol_values$value_class == "yes"), "Alcohol value map should classify yes.")
expect_true(any(alcohol_values$raw_value == "Nej" & alcohol_values$value_class == "no"), "Alcohol value map should classify no.")
expect_true(any(alcohol_values$raw_value == "Ikke aktuelt" & alcohol_values$value_class == "not_applicable"), "Alcohol value map should classify not applicable.")
expect_true(any(alcohol_values$raw_value == "Aldrig" & alcohol_values$value_class == "never"), "Alcohol value map should classify never drinks.")
expect_true(any(alcohol_values$raw_value == "Ikke spurgt" & alcohol_values$value_class == "not_asked"), "Alcohol value map should classify not asked.")
expect_true(any(alcohol_values$raw_value == "Udskyd" & alcohol_values$value_class == "deferred"), "Alcohol value map should classify deferred.")

expect_true(any(dictionary$raw_column == "Reg_ISS_Stadie" & dictionary$mapping_status == "not_present"), "Expected-but-missing DaMyDa fields should be emitted as not_present.")
expect_false(any(vapply(dictionary$raw_column, is_sensitive_column, logical(1))), "Identifier-like raw columns should not become semantic variables.")
expect_false(any(grepl("\\b[0-9]{6}[- ]?[0-9]{4}\\b", dictionary$raw_value)), "Semantic dictionary should not contain CPR-like raw values.")

suppressed <- build_semantic_outputs(project_root = root, min_cell_count = 1000000000)
expect_true(all(is.na(suppressed$value_map$n) | suppressed$value_map$suppressed == TRUE), "Small semantic value-map counts should be suppressed when below the configured threshold.")
