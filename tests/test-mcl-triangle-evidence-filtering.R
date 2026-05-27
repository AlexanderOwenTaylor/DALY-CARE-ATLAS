root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

semantic_dictionary <- data.frame(
  semantic_id = c(
    "mcl", "death_date", "cll_smoking", "cll_alcohol", "lyfo_asct_1",
    "lyfo_asct_2", "lyfo_asct_3", "lyfo_rec_asct_1", "lyfo_rec_asct_2",
    "social_drinking", "social_smoking", "vitals_display", "lyfo_bsymptomer",
    "damyda_death_cause"
  ),
  clinical_concept_id = c(
    "mcl", "death", "ibrutinib_smoking", "ibrutinib_alcohol", "asct",
    "asct", "asct", "asct_rec", "asct_rec", "social", "social",
    "vitals", "bsymptoms", "death_cause"
  ),
  clinical_variable = c(
    "Mantle cell lymphoma cohort", "Date of death", "Ibrutinib table smoking",
    "Ibrutinib table alcohol", "LYFO ASCT HDT first-line indicator",
    "LYFO autologous stem-cell support type", "LYFO stem-cell infusion date",
    "LYFO relapse ASCT HDT indicator", "LYFO relapse stem-cell infusion date",
    "Drinking status", "Smoking status", "Vital display name",
    "B symptoms", "DaMyDa transplant death cause"
  ),
  semantic_meaning = c(
    "MCL subtype evidence", "Explicit death date", "Known false positive",
    "Known false positive", "Primary MCL ASCT/HDT phenotype",
    "Primary MCL ASCT/HDT phenotype", "Primary MCL ASCT/HDT timing field",
    "Relapse/recurrence ASCT proxy", "Relapse/recurrence ASCT timing proxy",
    "Not response evidence", "Not death evidence", "Not neutropenic fever evidence",
    "Not neutropenic fever evidence", "Not ASCT exposure evidence"
  ),
  source_name = c(
    "RKKP_LYFO", "patient", "CLL_TREAT_IBRUTINIB", "CLL_TREAT_IBRUTINIB",
    "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO",
    "SP_Social_Hx", "SP_Social_Hx", "SP_VitaleVaerdier", "RKKP_LYFO", "RKKP_DaMyDa"
  ),
  object_name = c(
    "RKKP_LYFO", "patient", "CLL_TREAT_IBRUTINIB", "CLL_TREAT_IBRUTINIB",
    "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO",
    "SP_Social_Hx", "SP_Social_Hx", "SP_VitaleVaerdier", "RKKP_LYFO", "RKKP_DaMyDa"
  ),
  raw_column = c(
    "Reg_Subtype", "date_of_death", "smoking", "alcohol",
    "Beh_Hoejdosisbehandling", "Beh_TypeAutologStamcellestoette",
    "Beh_Stamcelleinfusion_dt", "Rec_Hoejdosisbehandling",
    "Rec_Stamcelleinfusion_dt", "drikker", "ryger", "displayname",
    "Reg_BSymptomer", "FU_Doed_aarsag"
  ),
  raw_descriptor = "",
  raw_code = "",
  raw_value = c("", "", "", "", "", "", "", "", "", "", "", "", "", "transplant"),
  code_system = "",
  n_rows = c(100, 100, 9, 8, 60, 55, 50, 14, 12, 100, 100, 1000, 100, 7),
  n_patients = NA_real_,
  mapping_confidence = "high",
  mapping_status = "confirmed",
  clinical_caveat = "",
  search_terms = "",
  stringsAsFactors = FALSE
)

semantic_code_map <- data.frame(
  semantic_id = c("sks_bwha_asct", "sks_bwha_ibrutinib"),
  clinical_concept_id = c("asct_hdt", "ibrutinib"),
  clinical_variable = c("ASCT/HDT procedure validation", "Ibrutinib SKS validation"),
  source_name = c("SDS_t_sksube", "SDS_t_sksube"),
  object_name = c("SDS_t_sksube", "SDS_t_sksube"),
  code_system = c("SKS", "SKS"),
  code = c("BWHA169", "BWHA169"),
  code_name = c("Autologous stem-cell support validation proxy", "Ibrutinib"),
  panel = "treatment",
  n_rows = c(10, 10),
  n_patients = NA_real_,
  mapping_confidence = "candidate",
  notes = "",
  stringsAsFactors = FALSE
)

semantic_value_map <- data.frame(
  semantic_id = "damyda_transplant_death_cause",
  clinical_concept_id = "death_cause",
  clinical_variable = "DaMyDa transplant death cause",
  source_name = "RKKP_DaMyDa",
  object_name = "RKKP_DaMyDa",
  raw_column = "FU_Doed_aarsag",
  raw_value = "transplant",
  display_value = "transplant",
  value_class = "",
  clinical_interpretation = "Not ASCT/HDT exposure evidence",
  n = 4,
  pct = NA_real_,
  denominator_label = "registry/value-map rows",
  evidence_file = "fixture",
  mapping_confidence = "candidate",
  suppressed = FALSE,
  notes = "",
  stringsAsFactors = FALSE
)

sources <- data.frame(
  table_name = c("RKKP_LYFO", "patient", "CLL_TREAT_IBRUTINIB", "SP_Social_Hx", "SP_VitaleVaerdier", "RKKP_DaMyDa", "SDS_t_sksube"),
  source = c("RKKP_LYFO", "patient", "CLL_TREAT_IBRUTINIB", "SP_Social_Hx", "SP_VitaleVaerdier", "RKKP_DaMyDa", "SDS_t_sksube"),
  source_label = c("LYFO", "Patient", "CLL treatment", "Social history", "Vitals", "DaMyDa", "SKS sube"),
  domain = c("Registry", "Core", "Treatment", "EHR", "EHR", "Registry", "Procedure"),
  subdomain = "",
  atlas_role = "",
  load_status = "ok",
  n_rows = c(100, 100, 100, 100, 1000, 100, 50),
  n_cols = 5,
  stringsAsFactors = FALSE
)

canonical <- data.frame(
  canonical_resource_id = sources$source,
  display_name = sources$source_label,
  current_status = "current_profiled",
  current_profiled = TRUE,
  current_resolved_source_key = sources$source,
  current_resolved_table_or_view = sources$table_name,
  stringsAsFactors = FALSE
)

outputs <- build_mcl_triangle_feasibility_outputs(
  project_root = root,
  semantic_dictionary = semantic_dictionary,
  semantic_value_map = semantic_value_map,
  semantic_code_map = semantic_code_map,
  sources = sources,
  canonical_reconciliation = canonical,
  legacy_reference_vs_current = data.frame(stringsAsFactors = FALSE),
  ki67_discovery = ki67_empty_payload()
)

main_text <- paste(
  outputs$treatment_inventory$exposure_name,
  outputs$treatment_inventory$source,
  outputs$treatment_inventory$table_or_source,
  outputs$treatment_inventory$raw_field,
  outputs$treatment_inventory$raw_value,
  outputs$outcome_inventory$outcome_name,
  outputs$outcome_inventory$source,
  outputs$outcome_inventory$table_or_source,
  outputs$outcome_inventory$raw_field,
  collapse = "\n"
)

expect_false(grepl("CLL_TREAT_IBRUTINIB.*smoking", main_text, ignore.case = TRUE), "CLL_TREAT_IBRUTINIB.smoking must not be Ibrutinib evidence.")
expect_false(grepl("CLL_TREAT_IBRUTINIB.*alcohol", main_text, ignore.case = TRUE), "CLL_TREAT_IBRUTINIB.alcohol must not be Ibrutinib evidence.")
asct_main_rows <- outputs$treatment_inventory[grepl("ASCT|HDT|stem-cell|autologous|Stem-cell", outputs$treatment_inventory$exposure_name, ignore.case = TRUE), , drop = FALSE]
expect_false(any(grepl("RKKP_DaMyDa", paste(asct_main_rows$source, asct_main_rows$table_or_source, asct_main_rows$raw_field), ignore.case = TRUE)), "DaMyDa death-cause transplant must not be ASCT/HDT exposure evidence.")
expect_false(grepl("SP_Social_Hx.*drikker|SP_Social_Hx.*ryger", main_text, ignore.case = TRUE), "Social-history drinking/smoking must not be outcome or safety evidence.")
expect_false(grepl("SP_VitaleVaerdier.*displayname", main_text, ignore.case = TRUE), "Vitals display names must not be neutropenic-fever evidence.")
expect_false(grepl("RKKP_DaMyDa.*FU_Doed_aarsag.*Infection", main_text, ignore.case = TRUE), "DaMyDa death-cause infection must not be direct Infection evidence.")
expect_false(grepl("RKKP_LYFO.*Reg_BSymptomer.*neutropenic|RKKP_LYFO.*Reg_BSymptomer.*fever", main_text, ignore.case = TRUE), "LYFO B symptoms must not be neutropenic-fever evidence.")
ibrutinib_rows <- outputs$treatment_inventory[grepl("Ibrutinib|BTK", outputs$treatment_inventory$exposure_name, ignore.case = TRUE), , drop = FALSE]
expect_true(any(grepl("BWHA169", paste(ibrutinib_rows$code, ibrutinib_rows$raw_value, ibrutinib_rows$raw_field), ignore.case = TRUE)), "Atlas-confirmed SDS_t_sksube.BWHA169 should be retained as Ibrutinib code evidence, with bridge validation required before counting.")

asct_rows <- asct_main_rows
asct_text <- paste(asct_rows$raw_field, asct_rows$notes, asct_rows$evidence_category, collapse = "\n")
expect_true(grepl("Beh_Hoejdosisbehandling", asct_text, fixed = TRUE), "LYFO Beh_Hoejdosisbehandling should be primary ASCT/HDT evidence.")
expect_true(grepl("Beh_TypeAutologStamcellestoette", asct_text, fixed = TRUE), "LYFO Beh_TypeAutologStamcellestoette should be primary ASCT/HDT evidence.")
expect_true(grepl("Beh_Stamcelleinfusion_dt", asct_text, fixed = TRUE), "LYFO Beh_Stamcelleinfusion_dt should be primary ASCT/HDT timing evidence.")
expect_true(grepl("Rec_Hoejdosisbehandling", asct_text, fixed = TRUE), "LYFO Rec_Hoejdosisbehandling should be retained as relapse/recurrence proxy evidence.")
expect_true(grepl("relapse/recurrence", asct_text, ignore.case = TRUE), "Recurrence transplant fields should be labelled separately from first-line ASCT/HDT.")
expect_false(any(outputs$treatment_inventory$evidence_category %in% c("source_space_only", "false_positive_excluded")), "Main treatment inventory must suppress source-space and false-positive rows.")
expect_false(any(outputs$outcome_inventory$evidence_category %in% c("source_space_only", "false_positive_excluded")), "Main outcome inventory must suppress source-space and false-positive rows.")
expect_true(all(c("matched_term", "matched_field", "match_reason", "evidence_category") %in% names(outputs$variable_inventory)), "Variable inventory should include match lineage columns.")
expect_true(nrow(outputs$false_positive_exclusions) >= 9, "False-positive exclusion audit should be generated.")
expect_true(any(outputs$false_positive_exclusions$source == "CLL_TREAT_IBRUTINIB" & outputs$false_positive_exclusions$field == "smoking"), "False-positive audit should include CLL_TREAT_IBRUTINIB.smoking.")
expect_true(any(outputs$false_positive_exclusions$source == "SDS_t_sksube" & outputs$false_positive_exclusions$field == "BWHA169" & outputs$false_positive_exclusions$exclusion_type == "bridge_required_not_false_positive"), "Audit should retain SDS_t_sksube.BWHA169 as bridge-required Ibrutinib evidence rather than a blanket false positive.")
expect_true(any(outputs$false_positive_exclusions$source == "RKKP_DaMyDa" & outputs$false_positive_exclusions$field == "FU_Doed_aarsag" & outputs$false_positive_exclusions$value == "infection"), "False-positive audit should include DaMyDa cause-of-death infection as non-direct infection evidence.")

ready_rows <- outputs$study_readiness_matrix[outputs$study_readiness_matrix$readiness_status == "ready", , drop = FALSE]
expect_false(nrow(ready_rows) > 0, "Study-readiness matrix should not use ready for unvalidated aggregate evidence.")
