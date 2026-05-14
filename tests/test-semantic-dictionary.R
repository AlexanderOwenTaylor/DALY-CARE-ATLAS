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
expect_true(any(search_semantic("NPU02319")$clinical_variable == "Haemoglobin"), "Search for NPU02319 should return haemoglobin.")
expect_true(any(search_semantic("DNK35302")$clinical_variable == "eGFR"), "Search for DNK35302 should return eGFR.")
expect_true(any(search_semantic("NPU19748")$clinical_variable == "Leukocytes"), "Search for NPU19748 should return leukocytes.")
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
