root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

concepts <- mcl_triangle_read_concepts(root)
required_groups <- c(
  "Cohort definition", "Eligibility / transplant-fit proxy", "Treatment exposures",
  "High-risk biology", "Outcomes", "Safety / toxicity proxies"
)
expect_true(all(required_groups %in% unique(concepts$concept_group)), "MCL/TRIANGLE config should contain all required concept groups.")
expect_true(any(concepts$required_for_feasibility), "MCL/TRIANGLE config should flag required feasibility concepts.")
expect_true(any(concepts$high_priority), "MCL/TRIANGLE config should flag high-priority concepts.")

required_requirements <- c(
  "MCL cohort", "younger/transplant-eligible proxy", "first-line treatment timing",
  "CIT / immunochemotherapy", "ASCT/HDT", "ibrutinib", "OS/death",
  "relapse/progression/FFS proxy", "blastoid morphology", "TP53 / p53 / del17p",
  "Ki-67", "MIPI", "MIPI-c", "toxicity proxies"
)

semantic_dictionary <- data.frame(
  semantic_id = c("lyfo_mcl", "lyfo_age", "lyfo_diag_date", "death_date", "ldh", "ecog"),
  clinical_concept_id = c("mcl_cohort", "age", "diagnosis_date", "overall_survival", "ldh", "performance_status"),
  clinical_variable = c("Mantle cell lymphoma cohort", "Age at diagnosis", "Diagnosis date", "Date of death", "LDH", "ECOG performance status"),
  clinical_group = c("Registry", "Registry", "Registry", "Outcomes", "Laboratory", "Registry"),
  clinical_subgroup = c("LYFO", "LYFO", "LYFO", "Death", "Laboratory", "LYFO"),
  semantic_meaning = c("LYFO MCL subtype evidence", "Age at diagnosis proxy", "Diagnosis date", "Overall survival endpoint", "LDH input", "Performance status input"),
  source_name = c("RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "patient", "RKKP_LYFO", "RKKP_LYFO"),
  object_name = c("RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "patient", "RKKP_LYFO", "RKKP_LYFO"),
  schema_name = "", table_name = "",
  raw_column = c("Reg_Subtype", "Reg_Alder", "Reg_Diagnosedato", "date_of_death", "Reg_LDH", "Reg_PS"),
  raw_descriptor = "", raw_code = "", raw_value = "", code_system = "", unit = "",
  value_type = "", data_shape = "", patient_id_column = "", date_column = "",
  value_column = "", source_level = "", geography = "",
  n_rows = c(100, 100, 100, 100, 100, 100),
  n_patients = NA_real_, pct_non_missing = NA_real_, min_date = "", max_date = "",
  evidence_file = "fixture", evidence_filter = "", mapping_confidence = "high",
  mapping_status = "confirmed", privacy_note = "", clinical_caveat = "",
  search_terms = "",
  stringsAsFactors = FALSE
)

semantic_code_map <- data.frame(
  semantic_id = c("ibrutinib", "asct", "rituximab"),
  clinical_concept_id = c("ibrutinib", "asct_hdt", "rituximab"),
  clinical_variable = c("Ibrutinib exposure", "ASCT/HDT exposure", "Rituximab exposure"),
  clinical_group = c("Treatment", "Treatment", "Treatment"),
  source_name = c("SP_AdministreretMedicin", "SDS_t_sksopr", "SP_AdministreretMedicin"),
  object_name = c("SP_AdministreretMedicin", "SDS_t_sksopr", "SP_AdministreretMedicin"),
  code_system = c("ATC", "SKS", "ATC"),
  code = c("L01XE27", "BWHA169", "L01XC02"),
  code_name = c("Ibrutinib / Imbruvica / BTK inhibitor", "Autologous stem-cell support / ASCT / HDT", "Rituximab"),
  panel = "treatment",
  n_rows = c(30, 12, 50),
  n_patients = NA_real_,
  evidence_file = "fixture",
  mapping_confidence = "high",
  notes = "",
  stringsAsFactors = FALSE
)

semantic_value_map <- data.frame(
  semantic_id = c("mcl_value", "rchop", "rdhap", "relapse"),
  clinical_concept_id = c("mcl_cohort", "cit", "cit", "relapse"),
  clinical_variable = c("MCL subtype", "R-CHOP regimen", "R-DHAP regimen", "Relapse/progression status"),
  source_name = c("RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO", "RKKP_LYFO"),
  object_name = "RKKP_LYFO",
  raw_column = c("Reg_Subtype", "Reg_Behandling", "Reg_Behandling", "Reg_Status"),
  raw_value = c("MCL", "R-CHOP", "R-DHAP", "progression"),
  display_value = c("Mantle cell lymphoma", "R-CHOP", "R-DHAP", "Progression"),
  value_class = "",
  clinical_interpretation = "",
  n = c(20, 8, 6, 5),
  pct = NA_real_,
  denominator_label = "registry/value-map rows",
  evidence_file = "fixture",
  mapping_confidence = "high",
  suppressed = FALSE,
  notes = "",
  stringsAsFactors = FALSE
)

semantic_panel_links <- data.frame(
  semantic_id = c("lyfo_mcl", "ibrutinib", "asct"),
  clinical_concept_id = c("mcl_cohort", "ibrutinib", "asct_hdt"),
  panel_id = c("reg_lyfo", "treatment", "treatment"),
  panel_section = c("Disease Registries", "Treatment", "Treatment"),
  relationship = "supports_feasibility",
  sort_order = 1:3,
  stringsAsFactors = FALSE
)

sources <- data.frame(
  table_name = c("RKKP_LYFO", "SP_AdministreretMedicin", "SDS_t_sksopr", "patient"),
  source = c("RKKP_LYFO", "SP_AdministreretMedicin", "SDS_t_sksopr", "patient"),
  source_label = c("LYFO", "Administered medicine", "Procedure", "Patient"),
  domain = c("Registry", "Treatment", "Treatment", "Core"),
  subdomain = "",
  atlas_role = "",
  load_status = "ok",
  n_rows = c(100, 300, 200, 100),
  n_cols = c(10, 8, 8, 4),
  stringsAsFactors = FALSE
)

canonical <- data.frame(
  canonical_resource_id = c("RKKP_LYFO", "SP_Administreret_Medicin", "t_sksopr", "patient", "t_mikro", "t_konk", "FISH"),
  display_name = c("RKKP_LYFO", "SP Administered Medicine", "SDS procedures", "patient", "t_mikro", "t_konk", "FISH"),
  current_status = c("current_profiled", "current_profiled", "current_profiled", "current_profiled", "current_not_attempted", "current_not_attempted", "special_manual"),
  current_profiled = c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE),
  current_resolved_source_key = c("RKKP_LYFO", "SP_AdministreretMedicin", "SDS_t_sksopr", "patient", "", "", ""),
  current_resolved_table_or_view = c("RKKP_LYFO", "SP_AdministreretMedicin", "SDS_t_sksopr", "patient", "", "", ""),
  stringsAsFactors = FALSE
)

legacy_reference <- data.frame(
  evidence_source = c("t_mikro", "t_konk", "FISH"),
  evidence_type = c("pathology_text", "pathology_conclusion", "molecular"),
  canonical_resource_id = c("t_mikro", "t_konk", "FISH"),
  current_profiled_this_run = c(FALSE, FALSE, FALSE),
  current_source_key = "",
  warning_needed = "TRUE",
  notes = c("blastoid morphology text candidate", "Ki-67 conclusion candidate", "TP53 del17p FISH candidate"),
  evidence_freshness_status = "legacy_reference_only",
  stringsAsFactors = FALSE
)

outputs <- build_mcl_triangle_feasibility_outputs(
  project_root = root,
  semantic_dictionary = semantic_dictionary,
  semantic_value_map = semantic_value_map,
  semantic_code_map = semantic_code_map,
  semantic_panel_links = semantic_panel_links,
  sources = sources,
  canonical_reconciliation = canonical,
  legacy_reference_vs_current = legacy_reference
)

expect_true(nrow(outputs$summary) > 0, "MCL/TRIANGLE summary should be generated.")
expect_true(nrow(outputs$variable_inventory) > 0, "MCL/TRIANGLE variable inventory should be generated.")
expect_true(nrow(outputs$treatment_inventory) > 0, "MCL/TRIANGLE treatment inventory should be generated.")
expect_true(nrow(outputs$outcome_inventory) > 0, "MCL/TRIANGLE outcome inventory should be generated.")
expect_true(nrow(outputs$biology_gap_analysis) >= 8, "MCL/TRIANGLE biology gap analysis should include high-risk markers.")
expect_true(all(required_requirements %in% outputs$study_readiness_matrix$study_requirement), "MCL/TRIANGLE readiness matrix should include all required study requirements.")
expect_true(any(grepl("ibrutinib|L01XE27|BTK", paste(outputs$treatment_inventory$exposure_name, outputs$treatment_inventory$code, outputs$treatment_inventory$raw_value), ignore.case = TRUE)), "Treatment inventory should include ibrutinib evidence/search terms.")
expect_true(any(grepl("ASCT|HDT|stem-cell|autologous|BWHA169", paste(outputs$treatment_inventory$exposure_name, outputs$treatment_inventory$code, outputs$treatment_inventory$raw_value), ignore.case = TRUE)), "Treatment inventory should include ASCT/HDT evidence/search terms.")
for (marker in c("blastoid morphology", "pleomorphic morphology", "TP53", "p53", "del17p", "Ki-67", "MIPI", "MIPI-c")) {
  expect_true(marker %in% outputs$biology_gap_analysis$marker, paste("Biology gap analysis should include:", marker))
}
verdict <- outputs$summary$status[outputs$summary$metric == "overall_feasibility_rating"][[1]]
expect_false(identical(verdict, "Strongly feasible"), "Panel must not become Strongly feasible while high-risk biology is missing or legacy/reference-only.")
expect_true(any(outputs$variable_inventory$current_profiled_this_run), "Inventory should label current-profiled evidence.")
expect_true(any(outputs$variable_inventory$legacy_reference_only), "Inventory should label legacy/reference-only evidence.")
expect_false(any(grepl("patientid|cpr|pnr", paste(outputs$variable_inventory$raw_field, outputs$variable_inventory$code_or_value), ignore.case = TRUE)), "MCL/TRIANGLE outputs must not emit patient identifiers.")
expect_false(any(nzchar(outputs$variable_inventory$count_or_rows_if_available) & !nzchar(outputs$variable_inventory$count_type)), "Counts should have explicit count-type labels.")
expect_false(any(grepl("patients should receive|ASCT improves|ibrutinib improves|benefit from ASCT|causal effect estimate", paste(outputs$caveats$text, outputs$recommended_next_actions$text), ignore.case = TRUE)), "MCL/TRIANGLE text must not imply treatment recommendation or causal treatment effect.")
