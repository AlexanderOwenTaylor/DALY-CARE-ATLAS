source("tests/helper.R")
source_test_runtime()

semantic <- build_semantic_outputs(project_root = getwd(), min_cell_count = 5)
product <- build_product_layer_outputs(semantic_outputs = semantic, project_root = getwd(), min_cell_count = 5)

concepts <- product$clinical_concepts
domain_panels <- product$domain_panels
kpis <- product$panel_kpis
distributions <- product$panel_distributions
raw_fields <- product$panel_raw_fields
parity <- product$panel_parity

expect_true(nrow(concepts) > 0, "Clinical concepts should be generated from semantic evidence.")
expect_true(nrow(domain_panels) > 0, "Domain panels should be generated from semantic evidence.")
expect_true(nrow(kpis) > 0, "Panel KPIs should be generated.")
expect_true(nrow(distributions) > 0, "Panel distributions should be generated.")
expect_true(nrow(raw_fields) > 0, "Panel raw fields should be generated.")
expect_true(nrow(parity) > 0, "Panel parity rows should be generated.")

scope_values <- product_scope_values()
expect_true(all(na.omit(concepts$count_scope) %in% scope_values), "Clinical concept count scopes should use approved labels.")
expect_true(all(na.omit(raw_fields$profile_scope) %in% scope_values), "Panel raw-field profile scopes should use approved labels.")
expect_true(all(na.omit(distributions$denominator_scope) %in% scope_values), "Panel distribution denominator scopes should use approved labels.")

has_raw <- function(source, column = "", descriptor = "", code = "", variable = "") {
  rows <- raw_fields
  rows <- rows[rows$source_name == source, , drop = FALSE]
  if (nzchar(column)) rows <- rows[rows$raw_column == column, , drop = FALSE]
  if (nzchar(descriptor)) rows <- rows[rows$raw_descriptor == descriptor, , drop = FALSE]
  if (nzchar(code)) rows <- rows[rows$raw_code == code | grepl(code, rows$raw_field_label, fixed = TRUE), , drop = FALSE]
  if (nzchar(variable)) rows <- rows[rows$clinical_variable == variable, , drop = FALSE]
  nrow(rows) > 0
}

vaegt <- paste0("V", intToUtf8(0x00E6), "gt")
hoejde <- paste0("H", intToUtf8(0x00F8), "jde")
expect_true(has_raw("SP_Social_Hx", "ryger", variable = "Smoking status"), "Raw fields should map SP_Social_Hx.ryger to Smoking status.")
expect_true(has_raw("SP_Social_Hx", "drikker", variable = "Alcohol use"), "Raw fields should map SP_Social_Hx.drikker to Alcohol use.")
expect_true(has_raw("SP_VitaleVaerdier", "displayname", descriptor = vaegt, variable = "Weight"), "Raw fields should map SP_VitaleVaerdier displayname=Vægt to Weight.")
expect_true(has_raw("SP_VitaleVaerdier", "displayname", descriptor = hoejde, variable = "Height"), "Raw fields should map SP_VitaleVaerdier displayname=Højde to Height.")
expect_true(has_raw("SP_VitaleVaerdier", "numericvalue", variable = "Vital numeric measurement value"), "Raw fields should map SP_VitaleVaerdier.numericvalue to the numeric vital-sign value.")
expect_true(has_raw("RKKP_DaMyDa", "Reg_LDH", variable = "LDH"), "Raw fields should map DaMyDa Reg_LDH to LDH.")
if (any(semantic$dictionary$source_name == "RKKP_DaMyDa" & semantic$dictionary$raw_column == "Reg_Creatinin_mikmoll")) {
  expect_true(has_raw("RKKP_DaMyDa", "Reg_Creatinin_mikmoll", variable = "Creatinine"), "Raw fields should map DaMyDa Reg_Creatinin_mikmoll to Creatinine when present.")
}
damyda_crp <- raw_fields[raw_fields$source_name == "RKKP_DaMyDa" & raw_fields$raw_column %in% c("Reg_CReaktivtProtein_gl", "Reg_CReaktivtProtein_nMoll"), , drop = FALSE]
expect_true(nrow(damyda_crp) >= 2, "DaMyDa CRP raw fields should flow into panel raw fields.")
expect_true(all(damyda_crp$clinical_concept_id == "crp" & damyda_crp$clinical_variable == "CRP"), "DaMyDa CRP raw fields should remain CRP in product-layer rows.")
expect_false(any(damyda_crp$clinical_concept_id == "creatinine" | damyda_crp$clinical_variable == "Creatinine"), "DaMyDa CRP raw fields must not appear under creatinine in product-layer rows.")
damyda_corrected_calcium <- raw_fields[raw_fields$source_name == "RKKP_DaMyDa" & raw_fields$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(damyda_corrected_calcium) > 0, "DaMyDa albumin-corrected calcium should flow into panel raw fields.")
expect_true(all(damyda_corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "DaMyDa albumin-corrected calcium should keep its corrected-calcium concept.")
expect_false(any(damyda_corrected_calcium$clinical_concept_id == "albumin" | damyda_corrected_calcium$clinical_variable == "Albumin"), "DaMyDa albumin-corrected calcium must not appear under albumin in product-layer rows.")
damyda_fish_probe <- raw_fields[raw_fields$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishProber_", raw_fields$raw_column), , drop = FALSE]
damyda_fish_result <- raw_fields[raw_fields$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishResultat_", raw_fields$raw_column), , drop = FALSE]
expect_true(nrow(damyda_fish_probe) > 0 && all(damyda_fish_probe$clinical_concept_id == "fish_probe"), "FISH probe rows should keep FISH/probe context in product-layer rows.")
expect_true(nrow(damyda_fish_result) > 0 && all(damyda_fish_result$clinical_concept_id == "fish_result"), "FISH result rows should keep FISH/result context in product-layer rows.")
expect_false(any(damyda_fish_probe$clinical_concept_id == "cytogenetic_risk"), "FISH probe rows must not be described only as generic cytogenetic risk.")

lyfo_raw <- raw_fields[raw_fields$source_name == "RKKP_LYFO", , drop = FALSE]
lyfo_histology <- lyfo_raw[lyfo_raw$raw_column %in% c("Reg_WHOHistologikode1", "Reg_WHOHistologikode2", "Rec_WHOHistologikode"), , drop = FALSE]
expect_true(nrow(lyfo_histology) > 0, "LYFO histology rows should flow into product-layer raw fields.")
expect_true(any(lyfo_histology$clinical_concept_id == "lymphoma_subtype_code" & lyfo_histology$clinical_variable == "WHO histology code"), "LYFO histology rows should keep subtype-code context in product-layer rows.")
expect_false(any(lyfo_histology$clinical_concept_id == "performance_status" | lyfo_histology$clinical_variable == "Performance status"), "LYFO histology rows must not appear under performance status.")
lyfo_performance <- lyfo_raw[lyfo_raw$raw_column %in% c("Reg_PerformanceStatusWHO", "Beh_PerformanceStatus", "Rec_Performancestatus"), , drop = FALSE]
expect_true(nrow(lyfo_performance) > 0 && all(lyfo_performance$clinical_concept_id == "performance_status"), "LYFO performance rows should map to performance status in product-layer rows.")
lyfo_corrected_calcium <- lyfo_raw[lyfo_raw$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(lyfo_corrected_calcium) > 0 && all(lyfo_corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "LYFO albumin-corrected calcium should keep its corrected-calcium concept.")
expect_false(any(lyfo_corrected_calcium$clinical_concept_id == "albumin" | lyfo_corrected_calcium$clinical_variable == "Albumin"), "LYFO albumin-corrected calcium must not appear under albumin.")
lyfo_pancreas <- lyfo_raw[lyfo_raw$raw_column == "Reg_Lokal_Pancreas", , drop = FALSE]
expect_true(nrow(lyfo_pancreas) > 0 && all(lyfo_pancreas$clinical_concept_id == "disease_localization"), "LYFO pancreas localization should stay in disease-localization context.")
expect_false(any(lyfo_pancreas$clinical_concept_id == "creatinine" | lyfo_pancreas$clinical_variable == "Creatinine"), "LYFO pancreas localization must not appear under creatinine.")
lyfo_ldh <- lyfo_raw[lyfo_raw$raw_column %in% c("Reg_Lactatdehydrogenase", "Reg_LDHVaerdi"), , drop = FALSE]
if (nrow(lyfo_ldh)) {
  expect_true(all(lyfo_ldh$clinical_concept_id == "ldh" & lyfo_ldh$clinical_variable == "LDH"), "LYFO LDH rows should keep LDH context.")
}
lyfo_index_expectations <- c(IPI = "ipi", aaIPI = "aaipi", FLIPI = "flipi", FLIPI2 = "flipi2", IPS = "ips")
for (raw_field in names(lyfo_index_expectations)) {
  concept <- unname(lyfo_index_expectations[[raw_field]])
  rows <- lyfo_raw[lyfo_raw$raw_column == raw_field, , drop = FALSE]
  if (nrow(rows)) {
    expect_true(all(rows$clinical_concept_id == concept), paste("LYFO raw index should preserve concept id:", raw_field))
    expect_true(all(rows$clinical_variable == raw_field), paste("LYFO raw index should preserve visible label:", raw_field))
  }
}
expect_true(has_raw("LABKA", code = "NPU02319", variable = "Haemoglobin") || has_raw("SDS_lab_forsker", code = "NPU02319", variable = "Haemoglobin"), "Raw fields should map NPU02319 to Haemoglobin.")
expect_true(has_raw("LABKA", code = "DNK35302", variable = "eGFR") || has_raw("PERSIMUNE", code = "DNK35302", variable = "eGFR"), "Raw fields should map DNK35302 to eGFR.")
expect_true(has_raw("LABKA", code = "NPU19748", variable = "Leukocytes") || has_raw("SDS_lab_forsker", code = "NPU19748", variable = "Leukocytes"), "Raw fields should map NPU19748 to Leukocytes.")

social_distributions <- distributions[distributions$panel_id == "clinical_social_history", , drop = FALSE]
expect_true(any(social_distributions$raw_column == "ryger" & social_distributions$raw_value == "Er holdt op" & social_distributions$display_value == "Former smoker"), "Smoking value map should classify Er holdt op as Former smoker.")
expect_true(any(social_distributions$raw_column == "ryger" & social_distributions$raw_value == "Aldrig" & social_distributions$display_value == "Never smoker"), "Smoking value map should classify Aldrig as Never smoker.")
expect_true(any(social_distributions$raw_column == "ryger" & social_distributions$raw_value == "Ja" & social_distributions$display_value == "Current smoker"), "Smoking value map should classify Ja as Current smoker.")
expect_true(any(social_distributions$raw_column == "ryger" & social_distributions$raw_value == "Ikke spurgt" & social_distributions$display_value == "Not asked"), "Smoking value map should classify Ikke spurgt as Not asked.")
expect_true(any(social_distributions$raw_column == "ryger" & social_distributions$raw_value == "Passiv" & social_distributions$display_value == "Passive exposure"), "Smoking value map should classify Passiv as Passive exposure.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Ja" & social_distributions$display_value == "Alcohol use yes"), "Alcohol value map should classify Ja as Alcohol use yes.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Nej" & social_distributions$display_value == "No alcohol use"), "Alcohol value map should classify Nej as No alcohol use.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Ikke aktuelt" & social_distributions$display_value == "Not applicable"), "Alcohol value map should classify Ikke aktuelt as Not applicable.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Aldrig" & social_distributions$display_value == "Never drinks"), "Alcohol value map should classify Aldrig as Never drinks.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Ikke spurgt" & social_distributions$display_value == "Not asked"), "Alcohol value map should classify Ikke spurgt as Not asked.")
expect_true(any(social_distributions$raw_column == "drikker" & social_distributions$raw_value == "Udskyd" & social_distributions$display_value == "Deferred"), "Alcohol value map should classify Udskyd as Deferred.")

required_panels <- c(
  "reg_damyda", "reg_lyfo", "reg_cll", "diagnosis_atlas", "clinical_vitals",
  "clinical_social_history", "clinical_adt", "clinical_notes", "clinical_imaging",
  "clinical_microbiology", "treatment", "laboratory_npu", "clinical_pathology", "clinical_biobank"
)
expect_true(all(required_panels %in% domain_panels$panel_id), "All required domain panels should be present.")
vitals_panel <- domain_panels[domain_panels$panel_id == "clinical_vitals", , drop = FALSE]
social_panel <- domain_panels[domain_panels$panel_id == "clinical_social_history", , drop = FALSE]
expect_true(all(c(vitals_panel$count_scope, vitals_panel$denominator_scope, vitals_panel$profile_scope) == "cartography_scan"), "Vitals product panel should carry cartography-scan panel-level scope.")
expect_true(all(c(social_panel$count_scope, social_panel$denominator_scope, social_panel$profile_scope) == "cartography_scan"), "Social History product panel should carry cartography-scan panel-level scope.")
for (panel_id in required_panels) {
  panel <- domain_panels[domain_panels$panel_id == panel_id, , drop = FALSE]
  expect_true(nzchar(panel$clinical_purpose[[1]]), paste("Panel should have clinical purpose:", panel_id))
  has_kpi_or_dist <- any(kpis$panel_id == panel_id) || any(distributions$panel_id == panel_id)
  expect_true(has_kpi_or_dist || nzchar(panel$missing_upstream_file[[1]]), paste("Panel should have KPI/distribution evidence or a named missing upstream file:", panel_id))
  expect_true(any(raw_fields$panel_id == panel_id), paste("Panel should have raw-field lineage rows:", panel_id))
}

expect_true(any(raw_fields$panel_id == "clinical_vitals" & raw_fields$source_name == "SP_VitaleVaerdier"), "Vitals panel should include SP_VitaleVaerdier.")
expect_true(any(raw_fields$panel_id == "clinical_vitals" & raw_fields$raw_descriptor == vaegt), "Vitals panel should include Vægt.")
expect_true(any(raw_fields$panel_id == "clinical_vitals" & raw_fields$raw_descriptor == hoejde), "Vitals panel should include Højde.")
expect_true(any(raw_fields$panel_id == "clinical_vitals" & raw_fields$raw_column == "numericvalue"), "Vitals panel should include numericvalue.")
expect_true(grepl("Repeated measures", domain_panels$caveats[domain_panels$panel_id == "clinical_vitals"], fixed = TRUE), "Vitals panel should carry the repeated-measures caveat.")

expect_true(any(raw_fields$panel_id == "clinical_social_history" & raw_fields$raw_column == "ryger"), "Social History panel should include ryger.")
expect_true(any(raw_fields$panel_id == "clinical_social_history" & raw_fields$raw_column == "drikker"), "Social History panel should include drikker.")
expect_true(grepl("Not asked", domain_panels$caveats[domain_panels$panel_id == "clinical_social_history"], fixed = TRUE), "Social History panel should carry not-asked/unknown/missing caveat.")

damyda_sections <- distributions$display_value[distributions$panel_id == "reg_damyda" & distributions$distribution_type == "clinical_section"]
expect_true(all(c("Baseline disease markers", "Staging/risk", "Treatment", "Response/relapse", "Bone disease / imaging", "Raw fields") %in% damyda_sections), "DaMyDa should expose required structured blocks.")
damyda_raw <- raw_fields[raw_fields$panel_id == "reg_damyda", , drop = FALSE]
for (column in c("Reg_Haemoglobin", "Reg_Creatinin_mikmoll", "Reg_LDH", "Reg_Albumin_gl", "Reg_Beta2Microglobulin_gl", "Reg_ProcentKlonalePlasmaceller", "Stadie", "Reg_PerformanceStatus", "Reg_Knogleforandringer", "IND_Relaps", "Cyto_FishUdfoert")) {
  if (any(semantic$dictionary$source_name == "RKKP_DaMyDa" & semantic$dictionary$raw_column == column)) {
    expect_true(any(damyda_raw$raw_column == column), paste("DaMyDa raw fields should include evidenced column:", column))
  }
}

lyfo_sections <- distributions$display_value[distributions$panel_id == "reg_lyfo" & distributions$distribution_type == "clinical_section"]
expect_true(all(c(
  "Source / coverage", "Subtype mix", "Staging and risk", "B symptoms and bulk disease",
  "Performance status", "Baseline disease markers", "Treatment and regimen fields",
  "Response / follow-up / relapse fields", "Disease localization", "Raw names / data lineage",
  "Use cases", "Caveats"
) %in% lyfo_sections), "LYFO should expose required structured clinical sections.")
lyfo_panel <- domain_panels[domain_panels$panel_id == "reg_lyfo", , drop = FALSE]
expect_true(grepl("lymphoma registry review", lyfo_panel$panel_title[[1]], ignore.case = TRUE), "LYFO panel should use the clinician-facing registry title.")
expect_true(grepl("subtype", lyfo_panel$clinical_purpose[[1]], ignore.case = TRUE) && grepl("Ann Arbor", lyfo_panel$clinical_purpose[[1]], fixed = TRUE), "LYFO panel purpose should describe lymphoma-specific registry use.")
for (column in c("Reg_Stadium", "IPI", "aaIPI", "Reg_BSymptomer", "Reg_BulkSygdom", "Reg_PerformanceStatusWHO", "Reg_Haemoglobin", "Reg_Lactatdehydrogenase", "Reg_Creatinin_mikmoll", "Reg_CalciumAlbuminkorrigeret", "Beh_Kemoterapiregime1", "Beh_Immunoterapi", "ind_relaps", "Reg_Lokal_Pancreas", "Reg_WHOHistologikode1")) {
  if (any(semantic$dictionary$source_name == "RKKP_LYFO" & semantic$dictionary$raw_column == column)) {
    expect_true(any(lyfo_raw$raw_column == column), paste("LYFO raw fields should include evidenced column:", column))
  }
}

imaging_sections <- distributions$display_value[distributions$panel_id == "clinical_imaging" & distributions$distribution_type == "clinical_section"]
expect_true(all(c("Nationwide procedure-code imaging", "Registry modality fields", "EHR-native imaging metadata/report text") %in% imaging_sections), "Imaging panel should preserve the three-layer framing.")

micro_sections <- distributions$display_value[distributions$panel_id == "clinical_microbiology" & distributions$distribution_type == "clinical_section"]
expect_true(any(grepl("PERSIMUNE analysis/culture/resistance/microscopy", micro_sections, fixed = TRUE)), "Microbiology panel should include PERSIMUNE analysis/culture/resistance/microscopy.")
expect_true(any(grepl("SP blood-culture workflow", micro_sections, fixed = TRUE)), "Microbiology panel should include SP blood-culture workflow.")
expect_true(any(grepl("Sample material/result class/organism-domain", micro_sections, fixed = TRUE)), "Microbiology panel should include sample material/result class/organism-domain framing.")

lab_codes <- raw_fields[raw_fields$panel_id == "laboratory_npu", , drop = FALSE]
for (concept_id in intersect(c("haemoglobin", "creatinine", "egfr", "leukocytes"), semantic$dictionary$clinical_concept_id)) {
  expect_true(any(lab_codes$clinical_concept_id == concept_id), paste("Laboratory/NPU panel should include evidenced concept:", concept_id))
}

required_concepts <- c("height", "weight", "bmi", "smoking_status", "alcohol_use", "ldh", "haemoglobin", "creatinine", "egfr", "imaging_availability", "microbiology_infection_data")
expect_true(all(required_concepts %in% concepts$clinical_concept_id), "Clinical Variables should include required concept cards.")
expect_equal(sum(concepts$clinical_concept_id == "bmi"), 1L, "Clinical Variables should contain exactly one BMI concept row.")
bmi_row <- concepts[concepts$clinical_concept_id == "bmi", , drop = FALSE]
expect_true(grepl("derived from height and weight", bmi_row$purpose[[1]], ignore.case = TRUE), "BMI concept should be labelled as derived from height and weight.")
expect_true(grepl("derived", bmi_row$caveats[[1]], ignore.case = TRUE), "BMI concept should preserve the derived-concept caveat.")

search_product <- function(query) {
  hay <- paste(
    concepts$clinical_concept_id, concepts$clinical_variable, concepts$purpose, concepts$best_source,
    concepts$primary_sources, concepts$use_cases, concepts$caveats, concepts$search_terms,
    sep = " "
  )
  raw_hay <- paste(raw_fields$clinical_concept_id, raw_fields$clinical_variable, raw_fields$raw_field_label, raw_fields$source_name, raw_fields$evidence_file, sep = " ")
  dist_hay <- paste(distributions$clinical_concept_id, distributions$clinical_variable, distributions$raw_value, distributions$display_value, distributions$raw_code, sep = " ")
  grepl(query, hay, ignore.case = TRUE) | concepts$clinical_concept_id %in% raw_fields$clinical_concept_id[grepl(query, raw_hay, ignore.case = TRUE)] | concepts$clinical_concept_id %in% distributions$clinical_concept_id[grepl(query, dist_hay, ignore.case = TRUE)]
}
for (query in c("ryger", vaegt, "NPU02319", "Reg_LDH", "PET", "blood culture", "IGHV")) {
  expect_true(any(search_product(query)), paste("Clinical Variables search should return product-layer concept/panel results for:", query))
}

expect_false(any(grepl("[.](tsv|csv)$", semantic$dictionary$source_name, ignore.case = TRUE)), "Semantic source names should not be cartography evidence filenames when source/table can be recovered.")
expect_false(any(grepl("[.](tsv|csv)$", raw_fields$source_name, ignore.case = TRUE)), "Panel raw-field source names should not be cartography evidence filenames.")
for (i in seq_len(nrow(parity))) {
  if (identical(parity$parity_status[[i]], "restored")) {
    panel_id <- parity$new_panel_id[[i]]
    panel <- domain_panels[domain_panels$panel_id == panel_id, , drop = FALSE]
    if (!nrow(panel)) next
    expect_true(nzchar(panel$clinical_purpose[[1]]), paste("Restored panel should have purpose:", panel_id))
    expect_true(any(raw_fields$panel_id == panel_id), paste("Restored panel should have raw fields:", panel_id))
    expect_true(any(kpis$panel_id == panel_id) || any(distributions$panel_id == panel_id), paste("Restored panel should have KPIs/distributions:", panel_id))
  }
}

public_cells <- unlist(lapply(product, function(x) {
  if (!is.data.frame(x)) return(character())
  as.character(unlist(x, use.names = FALSE))
}), use.names = FALSE)
public_cells <- public_cells[nzchar(public_cells)]
expect_false(any(grepl("^[0-9]{6}[- ]?[0-9]{4}$", public_cells)), "Product-layer outputs should not contain CPR-like values.")
expect_false(any(grepl("free text example|raw note|report text:", public_cells, ignore.case = TRUE)), "Product-layer outputs should not emit free-text examples.")
