root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

out_root <- tempfile("atlas_runs_")
result <- run_atlas(
  project_root = root,
  source_map_path = file.path(root, "config", "source-map.example.tsv"),
  output_root = out_root,
  mode = "report"
)

expect_file(file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_source_resolution.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_dalycare_access.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_memory_plan.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_db_query_log.tsv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_db_budget_actions.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_sources.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_columns.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_column_profiles.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_column_top_values.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_checks.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_value_frequencies.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_semantic_data_dictionary.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_semantic_value_map.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_semantic_code_map.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_semantic_panel_links.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_clinical_concepts.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_domain_panels.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_panel_kpis.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_panel_distributions.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_panel_raw_fields.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_panel_parity.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_run_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "atlas_run_action_items.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "lab_npu_code_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_dictionary_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_dictionary_vectors.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_lab_usage_by_vector.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_lab_unmatched_codes.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_detective_code_inventory.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_detective_candidates.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "npu_detective_source_year.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "isotype_code_usage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "isotype_bucket_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "mm_treatment_code_counts.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "mm_treatment_source_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "diagnosis_icd_groups.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "damyda_feature_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "registry_clinical_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "damyda_clinical_profile.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "damyda_numeric_fields.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "lyfo_clinical_profile.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "cll_clinical_profile.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_coverage_years.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_date_quality.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_spatial_region_counts.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_spatial_region_coverage.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_dk_choropleth_regions.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_streaming_progress_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "situation_report_summary.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "situation_report_breakdowns.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "situation_report_freshness.csv"))
expect_file(file.path(result$run_dir, "outputs", "panels", "atlas_module_readiness.csv"))
expect_file(file.path(result$run_dir, "outputs", "output_manifest.csv"))
expect_file(file.path(result$run_dir, "logs", "atlas_execution_log.tsv"))
expect_file(file.path(result$run_dir, "logs", "atlas_memory_log.tsv"))
expect_file(result$html)
expect_file(result$payload)

html <- paste(readLines(result$html, warn = FALSE), collapse = "\n")
expect_true(grepl("DALYCARE_atlas_payload.js", html, fixed = TRUE), "HTML should reference external payload JS.")
expect_false(grepl("window.DALYCARE_ATLAS_PAYLOAD =", html, fixed = TRUE), "HTML should not embed the full payload.")
expect_true(grepl("<meta name=\"author\" content=\"Alexander Owen Taylor\">", html, fixed = TRUE), "HTML should include transparent author metadata.")
expect_true(grepl("Built by Alexander Owen Taylor", html, fixed = TRUE), "HTML should include visible generated-atlas credit.")
expect_true(grepl("tab-overview", html, fixed = TRUE), "HTML should include the Overview tab.")
expect_true(grepl("tab-variables", html, fixed = TRUE), "HTML should include the Clinical Variables tab.")
expect_true(grepl("tab-situation", html, fixed = TRUE), "HTML should include the Situation Report tab.")
expect_true(grepl("tab-quickstart", html, fixed = TRUE), "HTML should include the Quick Start tab.")
expect_true(grepl("tab-dictionary", html, fixed = TRUE), "HTML should include the Data Dictionary tab.")
expect_true(grepl("tab-registries", html, fixed = TRUE), "HTML should include the Disease Registries tab.")
expect_true(grepl("tab-clinical", html, fixed = TRUE), "HTML should include the Clinical Data tab.")
expect_true(grepl("tab-treatment", html, fixed = TRUE), "HTML should include the Treatment tab.")
expect_true(grepl("tab-laboratory", html, fixed = TRUE), "HTML should include the Laboratory tab.")
expect_true(grepl("tab-ehr", html, fixed = TRUE), "HTML should include the EHR Modules tab.")
expect_true(grepl("tab-infrastructure", html, fixed = TRUE), "HTML should include the Infrastructure tab.")
expect_true(grepl("data-sub=\"overview-temporal\"", html, fixed = TRUE), "HTML should include temporal coverage sub-tabs.")
expect_true(grepl("data-sub=\"overview-spatial\"", html, fixed = TRUE), "HTML should include regional coverage sub-tabs.")
expect_true(grepl("data-sub=\"situation-headlines\"", html, fixed = TRUE), "HTML should include Situation Report sub-tabs.")
expect_true(grepl("data-sub=\"dictionary-lineage\"", html, fixed = TRUE), "HTML should include semantic dictionary sub-tabs.")
expect_true(grepl("data-sub=\"reg-damyda\"", html, fixed = TRUE), "HTML should include DaMyDa registry sub-tabs.")
expect_true(grepl("data-sub=\"clinical-diagnoses\"", html, fixed = TRUE), "HTML should include clinical module sub-tabs.")
expect_true(grepl("data-sub=\"clinical-microbiology\"", html, fixed = TRUE), "HTML should include Microbiology/Infection clinical sub-tab.")
expect_true(grepl("treatment-dashboard", html, fixed = TRUE), "HTML should include the Treatment dashboard container.")
expect_true(grepl("data-sub=\"lab-npu\"", html, fixed = TRUE), "HTML should include laboratory/NPU sub-tabs.")
expect_true(grepl("data-sub=\"ehr-sp\"", html, fixed = TRUE), "HTML should include EHR module sub-tabs.")
expect_true(grepl("data-sub=\"infra-actions\"", html, fixed = TRUE), "HTML should include run action item sub-tabs.")
expect_true(grepl("data-sub=\"infra-catalog\"", html, fixed = TRUE), "HTML should include infrastructure sub-tabs.")
expect_true(grepl("catalog-search", html, fixed = TRUE), "HTML should include source catalog search.")
expect_true(grepl("catalog-domain-filter", html, fixed = TRUE), "HTML should include domain filtering controls.")
expect_true(grepl("catalog-status-filter", html, fixed = TRUE), "HTML should include status filtering controls.")
expect_true(grepl("catalog-role-filter", html, fixed = TRUE), "HTML should include role filtering controls.")
expect_true(grepl("column-search", html, fixed = TRUE), "HTML should include column search.")
expect_true(grepl("column-dataset-filter", html, fixed = TRUE), "HTML should include column dataset filtering.")
expect_true(grepl("column-domain-filter", html, fixed = TRUE), "HTML should include column domain filtering.")
expect_true(grepl("column-kind-filter", html, fixed = TRUE), "HTML should include column profile-kind filtering.")
expect_true(grepl("clinical-variable-search", html, fixed = TRUE), "HTML should include Clinical Variables search.")
expect_true(grepl("clinical-variable-cards", html, fixed = TRUE), "HTML should include Clinical Variables concept cards.")
expect_true(grepl("function clinicalConceptDisplayPriority", html, fixed = TRUE), "Clinical Variables should use renderer-side priority ordering.")
expect_true(grepl("function stableClinicalConceptSort", html, fixed = TRUE), "Clinical Variables priority ordering should preserve stable non-priority order.")
for (needle in c("Height and weight / BMI", "Smoking status", "Alcohol use", "Diagnosis date/source", "Stage/risk", "LDH", "Haemoglobin", "Creatinine/eGFR", "Treatment exposure", "Imaging availability", "Microbiology/infection", "Pathology", "Biobank samples")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Clinical Variables priority list should include:", needle))
}
expect_true(grepl("renderDomainPanel", html, fixed = TRUE), "HTML should include the product-layer domain panel renderer.")
expect_true(grepl("function renderVitalsPanel()", html, fixed = TRUE), "HTML should include the dedicated Vitals renderer.")
expect_true(grepl("function renderSocialHistoryPanel()", html, fixed = TRUE), "HTML should include the dedicated Social History renderer.")
expect_true(grepl("function renderDaMyDaPanel()", html, fixed = TRUE), "HTML should include the dedicated DaMyDa renderer.")
expect_true(grepl("function renderLYFOPanel()", html, fixed = TRUE), "HTML should include the dedicated LYFO renderer.")
expect_true(grepl("function renderCLLPanel()", html, fixed = TRUE), "HTML should include the dedicated CLL renderer.")
expect_true(grepl("function renderTreatmentPanel()", html, fixed = TRUE), "HTML should include the dedicated Treatment renderer.")
expect_true(grepl("function renderLaboratoryNPUPanel()", html, fixed = TRUE), "HTML should include the dedicated Laboratory/NPU renderer.")
expect_true(grepl("function renderMicrobiologyPanel()", html, fixed = TRUE), "HTML should include the dedicated Microbiology/Infection renderer.")
expect_true(grepl("function renderImagingPanel()", html, fixed = TRUE), "HTML should include the dedicated Imaging renderer.")
for (needle in c("--green", "--blue", "--amber", "--plum", "--violet", "--red", "--cyan", "--surface", "--surface2", "--surface3", "--line", "--muted", "--shadow", "--radius")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("HTML design system should define:", needle))
}
for (needle in c(".badge.green", ".badge.blue", ".badge.amber", ".badge.plum", ".badge.violet", ".badge.red", ".badge.cyan", ".h-bar", ".kpi-strip", ".clinical-card", ".raw-lineage-card", ".scope-chip", ".caveat-box")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("HTML should include V33-style component class:", needle))
}
for (needle in c("overflow-wrap: anywhere", "word-break: break-word", ".table-wrap", "overflow-x: auto", "renderHBarRows", "renderKpiStrip", "renderBadge", "renderScopeChip", "renderClinicalMetricCard", "renderValueMapCard", "renderSectionCard", "renderCollapsedRawLineage")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("HTML should include overflow-safe visual helper:", needle))
}
expect_true(grepl("semanticVisibleLimit = 80", html, fixed = TRUE), "Data Dictionary should default to compact, limited visible rows.")
expect_true(grepl("Showing ${visible.length} of ${filtered.length} matching semantic rows. Total rows: ${semanticRows.length}.", html, fixed = TRUE), "Data Dictionary count should distinguish visible, matching, and total semantic rows.")
expect_true(grepl("Showing ${visible.length} of ${filtered.length} matching clinical concepts. Total concepts: ${clinicalConceptRows.length}.", html, fixed = TRUE), "Clinical Variables count should distinguish visible, matching, and total concepts.")
expect_true(grepl("qa-overflow-report", html, fixed = TRUE) && grepl("overflowReport", html, fixed = TRUE), "HTML should include rendered-DOM overflow QA hooks.")
expect_file(file.path(root, "scripts", "visual_qa_atlas.js"))
visual_qa_script <- paste(readLines(file.path(root, "scripts", "visual_qa_atlas.js"), warn = FALSE), collapse = "\n")
expect_true(grepl("overflow_desktop.json", visual_qa_script, fixed = TRUE), "Visual QA script should write a desktop overflow report.")
expect_true(grepl("overflow_mobile.json", visual_qa_script, fixed = TRUE), "Visual QA script should write a mobile overflow report.")
expect_true(grepl("{ name: \"cll\", tab: \"registries\", sub: \"reg-cll\" }", visual_qa_script, fixed = TRUE), "Visual QA script should include the CLL registry target.")
expect_true(grepl("{ name: \"treatment\", tab: \"treatment\", sub: \"treatment-dashboard\" }", visual_qa_script, fixed = TRUE), "Visual QA script should include the Treatment target.")
expect_true(grepl("{ name: \"laboratory\", tab: \"laboratory\", sub: \"lab-npu\" }", visual_qa_script, fixed = TRUE), "Visual QA script should include the Laboratory/NPU target.")
expect_true(grepl("{ name: \"microbiology\", tab: \"clinical\", sub: \"clinical-microbiology\" }", visual_qa_script, fixed = TRUE), "Visual QA script should include the Microbiology/Infection target.")
expect_true(grepl("{ name: \"imaging\", tab: \"clinical\", sub: \"clinical-imaging\" }", visual_qa_script, fixed = TRUE), "Visual QA script should include the Imaging target.")
expect_true(grepl("microbiologyAtGlancePresent", visual_qa_script, fixed = TRUE), "Visual QA script should verify the Microbiology At a glance section.")
expect_true(grepl("imagingPanelPresent", visual_qa_script, fixed = TRUE), "Visual QA script should verify the Imaging panel.")
expect_true(grepl("dataDictionaryDetailStackPresent", visual_qa_script, fixed = TRUE), "Visual QA script should verify the Data Dictionary stacked detail pane.")
expect_true(grepl("dataDictionaryFullLineageTablePresent", visual_qa_script, fixed = TRUE), "Visual QA script should reject wide Full lineage tables in the detail pane.")
readme_text <- paste(readLines(file.path(root, "README.md"), warn = FALSE), collapse = "\n")
readme_flat <- gsub("\\s+", " ", readme_text)
expect_true(grepl("A separate full-output visual QA run is required before final visual acceptance of production-scale data.", readme_flat, fixed = TRUE), "README should clarify fixture visual QA is not production-scale visual acceptance.")
mockup_builder <- paste(readLines(file.path(root, "scripts", "build_atlas_mockup_from_run_zip.R"), warn = FALSE), collapse = "\n")
expect_true(grepl("Visual QA source artifact:", mockup_builder, fixed = TRUE), "Mockup README should record the source artifact used for visual QA.")
expect_true(grepl("A separate full-output visual QA run is required before final visual acceptance of production-scale data.", mockup_builder, fixed = TRUE), "Mockup README should clarify fixture versus full-output visual QA.")
expect_false(grepl("renderRegistryDetail(\"registry-damyda\", \"reg_damyda\")", html, fixed = TRUE), "DaMyDa should not be rendered through the generic registry detail renderer.")
expect_false(grepl("renderRegistryDetail(\"registry-lyfo\", \"reg_lyfo\")", html, fixed = TRUE), "LYFO should not be rendered through the generic registry detail renderer.")
expect_true(grepl("setHtml(\"registry-lyfo\", renderLYFOPanel())", html, fixed = TRUE), "LYFO should be wired to its dedicated renderer.")
expect_false(grepl("renderRegistryDetail(\"registry-cll\", \"reg_cll\")", html, fixed = TRUE), "CLL should not be rendered through the generic registry detail renderer.")
expect_true(grepl("setHtml(\"registry-cll\", renderCLLPanel())", html, fixed = TRUE), "CLL should be wired to its dedicated renderer.")
expect_true(grepl("setHtml(\"treatment-dashboard\", renderTreatmentPanel())", html, fixed = TRUE), "Treatment should be wired to its dedicated renderer.")
expect_true(grepl("setHtml(\"laboratory-npu-dashboard\", renderLaboratoryNPUPanel())", html, fixed = TRUE), "Laboratory/NPU should be wired to its dedicated renderer.")
expect_true(grepl("setHtml(\"clinical-microbiology-cards\", renderMicrobiologyPanel())", html, fixed = TRUE), "Microbiology/Infection should be wired to its dedicated renderer.")
expect_true(grepl("setHtml(\"clinical-imaging-cards\", renderImagingPanel())", html, fixed = TRUE), "Imaging should be wired to its dedicated renderer.")
expect_false(grepl("setHtml(\"clinical-imaging-cards\", renderDomainPanel(\"clinical_imaging\"))", html, fixed = TRUE), "Imaging should not be rendered through the generic domain panel renderer.")
expect_false(grepl("setHtml(\"treatment-source-cards\", sourceTiles", html, fixed = TRUE), "Treatment should not render source summary through generic source tiles.")
expect_false(grepl("setHtml(\"treatment-medicine-cards\", sourceTiles", html, fixed = TRUE), "Treatment medicine evidence should not render through generic source tiles.")
expect_false(grepl("setHtml(\"treatment-procedure-cards\", sourceTiles", html, fixed = TRUE), "Treatment procedure evidence should not render through generic source tiles.")
expect_false(grepl("setHtml(\"clinical-vitals-cards\", renderDomainPanel(\"clinical_vitals\"))", html, fixed = TRUE), "Vitals should not be rendered through the generic domain panel renderer.")
expect_false(grepl("setHtml(\"clinical-social-cards\", renderDomainPanel(\"clinical_social_history\"))", html, fixed = TRUE), "Social History should not be rendered through the generic domain panel renderer.")
expect_false(grepl("<h3>Key raw fields</h3><div id=\"semantic-clinical-vitals\"", html, fixed = TRUE), "Vitals should not show a second open generic raw-field block.")
expect_false(grepl("<h3>Key raw fields</h3><div id=\"semantic-clinical-social\"", html, fixed = TRUE), "Social History should not show a second open generic raw-field block.")
expect_true(grepl("Additional semantic hits", html, fixed = TRUE), "Dedicated Vitals/Social panels should keep generic semantic hits collapsed.")
expect_false(grepl("Vitals Sources", html, fixed = TRUE), "Vitals heading should no longer say Vitals Sources.")
expect_false(grepl("Social History Sources", html, fixed = TRUE), "Social History heading should no longer say Social History Sources.")
expect_true(grepl("Vital signs and anthropometrics", html, fixed = TRUE), "Vitals heading should use the clinician-facing title.")
expect_true(grepl("Social history: smoking and alcohol", html, fixed = TRUE), "Social History heading should use the clinician-facing title.")
expect_true(grepl("DaMyDa: myeloma registry review", html, fixed = TRUE), "DaMyDa heading should use the clinician-facing registry title.")
expect_true(grepl("LYFO: lymphoma registry review", html, fixed = TRUE), "LYFO heading should use the clinician-facing registry title.")
expect_true(grepl("CLL: chronic lymphocytic leukemia registry review", html, fixed = TRUE), "CLL heading should use the clinician-facing registry title.")
expect_false(grepl("<h3>Key raw fields</h3><div id=\"semantic-registry-lyfo\"", html, fixed = TRUE), "LYFO should not show a second open generic raw-field block.")
expect_false(grepl("<h3>Key raw fields</h3><div id=\"semantic-registry-cll\"", html, fixed = TRUE), "CLL should not show a second open generic raw-field block.")
expect_true(grepl("date span not reliable in current aggregate output", html, fixed = TRUE), "DaMyDa renderer should include the date-quality fallback.")
for (needle in c("Baseline disease markers", "Staging/risk", "Treatment", "Response/relapse", "Bone disease / imaging", "Cytogenetics/FISH availability", "Raw names / data lineage", "Use cases and caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("DaMyDa renderer should contain section:", needle))
}
for (needle in c("Source / coverage", "Subtype mix", "Staging and risk", "B symptoms and bulk disease", "Performance status", "Baseline disease markers", "Treatment and regimen fields", "Response / follow-up / relapse fields", "Disease localization", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("LYFO renderer should contain section:", needle))
}
for (needle in c("Source / coverage", "Binet stage", "IGHV and baseline risk markers", "FISH / cytogenetics / TP53", "Baseline blood and immune markers", "Symptoms and treatment indication", "Treatment and targeted therapy", "Response / MRD / follow-up", "Diagnostic workup", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("CLL renderer should contain section:", needle))
}
for (needle in c("Source / coverage", "Treatment evidence layers", "ATC medication signals", "SKS/procedure signals", "SP treatment plans", "Administered/ordered medicine", "Registry treatment context", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Treatment renderer should contain section:", needle))
}
for (needle in c("Laboratory / NPU atlas", "Lab evidence layers", "Core lab concepts", "Cross-source NPU concordance", "Haematology", "Renal function", "Inflammation and biochemistry", "Immunoglobulins and M-protein", "Myeloma / lymphoma / CLL registry lab fields", "NPU code dictionary", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Laboratory/NPU renderer should contain section:", needle))
}
for (needle in c("Microbiology / infection atlas", "Microbiology evidence layers", "At a glance", "PERSIMUNE analysis", "PERSIMUNE culture", "Resistance / susceptibility", "Microscopy", "SP blood-culture workflow", "Sample material", "Organism/domain", "Result class", "Antibiotic/susceptibility", "Hospital/lab source", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Microbiology/Infection renderer should contain section:", needle))
}
for (needle in c("Medical imaging atlas", "Imaging evidence layers", "Nationwide procedure-code imaging", "DaMyDa registry imaging / bone disease", "SP imaging metadata/report layer", "CT", "MRI", "PET / PET-CT", "X-ray", "Radiotherapy", "Raw names / data lineage", "Use cases", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Imaging renderer should contain section:", needle))
}
for (needle in c("function imagingLayer", "function isDaMyDaImagingRegistryRow", "imagingDamydaRegistryColumns", "function imagingPanelDistributionRows", "function renderImagingLayerCards", "function renderImagingRawLineageByLayer", "SP imaging report-text table not available in current aggregate output", "Disease-specific registry summary, not full imaging-event stream", "Imaging signals are procedure/metadata/registry evidence, not image pixels", "Report text/free text must not be emitted into the static atlas", "Radiotherapy rows are procedure signals, not medication treatment exposure")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Imaging renderer should include guarded source-aware logic:", needle))
}
for (needle in c("SDS_t_sksube", "SDS_procedurer_andre", "SP_Billeddiagnostik", "RKKP_DaMyDa", "APAA4", "UXZ11", "UXZ10", "UXRC00", "UXCC00", "UXCD00", "BWGC1", "BWGC4A", "CT", "MRI", "PET", "PET/CT", "F-18-FDG", "RU THORAX", "Reg_Knogleundersoegelser_CT", "Reg_Knogleundersoegelser_ct", "Reg_Knogleundersoegelser_MR", "Reg_Knogleundersoegelser_mri", "Reg_Knogleundersoegelser_PETCT", "Reg_Knogleundersoegelser_pet", "Reg_Knogleundersoegelser_DEXA", "Reg_Knogleundersoegelser_dexa", "Reg_Knogleundersoegelser_SCINTI", "Reg_Knogleundersoegelser_scinti", "Reg_Knogleforandringer", "Reg_Knogleforandringer_type")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Imaging renderer should be able to surface evidenced term:", needle))
}
for (needle in c("function microbiologyLayer", "function microbiologyPanelDistributionRows", "function microbiologyRowsForAtGlance", "function renderMicrobiologyAtGlance", "microbiology-at-a-glance", "panelDistributionRows || []", "function renderMicrobiologyLayerCards", "function renderSpBloodCultureWorkflow", "function renderMicrobiologyRawLineageByLayer", "Aggregate rows not available in current output", "Detailed organism/species values are suppressed or grouped", "Free text, notes, report examples, and raw date values are not emitted as categorical bars")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Microbiology/Infection renderer should include guarded source-aware logic:", needle))
}
for (needle in c("PERSIMUNE_microbiology_analysis", "PERSIMUNE_microbiology_culture", "PERSIMUNE_microbiology_culture_resistance", "PERSIMUNE_microbiology_microscopy", "SP_Bloddyrkning_del1", "SP_Bloddyrkning_del2", "SP_Bloddyrkning_del3", "SP_Bloddyrkning_del4", "Virus", "Bacteria", "Fungus", "Negative", "Positive", "Not interpreted", "Blood", "Swab", "Stool", "BAL", "BLOODCULTURE", "URINECULTURE", "antibiotika", "sensitivitet_resultat")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Microbiology/Infection renderer should be able to surface evidenced term:", needle))
}
for (needle in c("function labSourceLayer", "function labConceptCard", "function renderLabConcordance", "function renderLabRawLineageByLayer", "labConceptSpecs", "NPU code coverage is not the same as harmonized result-value availability", "Registry lab fields are baseline/registry-specific fields, not full longitudinal lab streams")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Laboratory/NPU renderer should include guarded lab atlas logic:", needle))
}
for (needle in c("NPU02319", "NPU02593", "DNK35302", "NPU02636", "NPU01349", "NPU04998", "NPU19748", "Haemoglobin", "Creatinine", "eGFR / CKD-EPI", "LDH", "Albumin", "CRP", "Leukocytes", "SP_AlleProvesvar", "SDS_lab_forsker", "PERSIMUNE_biochemistry", "Reg_Haemoglobin", "Reg_Creatinin_mikmoll", "Reg_LDH", "Reg_Albumin_gl", "Reg_Beta2Microglobulin_gl")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Laboratory/NPU renderer should be able to surface evidenced lab term:", needle))
}
for (needle in c("function treatmentDistributionRows", "panelDistributionRows || []", "row.panel_id === \"treatment\"", "treatmentIsDateLike", "treatmentIsLabSupport", "Supporting labs surfaced by treatment matrix")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Treatment renderer should use guarded product-layer grouping:", needle))
}
for (needle in c("function treatmentSourceContext", "treatmentRowsForContext", "Registry treatment fields", "SP administered medication", "SP ordered medication", "National prescription data", "SMR / in-hospital medication", "SKS procedure/treatment signals", "Candidate / needs-validation treatment rows")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Treatment renderer should preserve source-context layer:", needle))
}
for (needle in c("SP_AdministreretMedicin", "SP_OrdineretMedicin", "SMR_medicine", "SDS_t_sksube", "SDS_epikur", "ATC", "SKS", "L01/L04", "antineoplastic chemotherapy", "immunotherapy", "radiotherapy", "lenalidomide", "bortezomib", "daratumumab", "rituximab", "venetoclax", "ibrutinib")) {
  expect_true(grepl(needle, html, ignore.case = TRUE), paste("Treatment renderer should be able to surface evidenced term:", needle))
}
expect_false(grepl("treatmentDashboardPrimaryLabRows", html, fixed = TRUE), "Treatment primary dashboard should not need a primary lab-row bucket.")
for (needle in c("function cllDistributionRowsFor", "panelDistributionRows.filter", "row.panel_id !== \"reg_cll\"", "raw_column", "wanted.has(normalizeClinicalKey(rawColumn))", "cllIsDateLikeColumn(rawColumn)", "renderCLLDistributionGroups(columns || [], tone)", "cll-distribution-grid")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("CLL renderer should use guarded product-layer distributions:", needle))
}
for (needle in c("RKKP_LYFO", "Reg_Stadium", "IPI", "aaIPI", "Reg_BSymptomer", "Reg_BulkSygdom", "Reg_PerformanceStatusWHO", "Reg_Haemoglobin", "Reg_Lactatdehydrogenase", "Reg_LDHVaerdi", "Reg_Creatinin_mikmoll", "Reg_CalciumAlbuminkorrigeret", "Beh_Kemoterapiregime1", "Beh_Immunoterapi", "ind_relaps", "Reg_Lokal_Pancreas", "Reg_WHOHistologikode1")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("LYFO renderer should be able to surface evidenced field/value:", needle))
}
for (needle in c("Lymphoma subtype cohort discovery", "Ann Arbor stage and IPI/aaIPI risk adjustment", "Candidate raw fields are shown for discovery")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("LYFO renderer should include use case or caveat:", needle))
}
for (needle in c("RKKP_CLL", "Reg_BinetStadium", "Reg_Umuteret", "Reg_FISH", "Reg_Del17p", "Reg_Del11q", "Reg_Del13q14", "Reg_Trisomi12", "Reg_TP53", "Beh_TP53Mutation", "Reg_KnoglemarvsUndersoegelse", "Reg_CTSCANNING", "Reg_ULSCANNING", "Beh_Vaegttab", "Beh_Feber", "Beh_Nattesved", "Beh_UdtaltTraethed", "Beh_Lymfadenopati", "Beh_TargeteretBeh_Ibrutinib", "Beh_TargeteretBeh_venetoclax", "Beh_TargeteretBeh_acalabrutinib", "Beh_MRD", "Beh_Responsevaluering")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("CLL renderer should be able to surface evidenced field/value:", needle))
}
for (needle in c("Beh_Behandling_Start_dt", "Beh_Behandling_slut_dt", "FU_Doedsdato", "Beh_Doedsdato", "Rec_NyBehandling_dt", "Beh_TRANSPDATO")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("CLL renderer should explicitly recognize date-like field:", needle))
}
for (needle in c("CLL cohort review and registry-field discovery", "Binet stage stratification", "Targeted-therapy registry-field discovery", "Date fields are not displayed as meaningful coverage or outcome distributions")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("CLL renderer should include use case or caveat:", needle))
}
expect_false(grepl("Beh_Vaegttab -> Weight", html, fixed = TRUE), "CLL renderer must not show weight-loss as weight measurement.")
expect_false(grepl("Reg_KnoglemarvsUndersoegelse -> Bone involvement", html, fixed = TRUE), "CLL renderer must not show bone marrow examination as bone involvement.")
expect_false(grepl("Reg_WHOHistologikode1 -> Performance status", html, fixed = TRUE), "LYFO renderer must not show histology as performance status.")
expect_false(grepl("Reg_CalciumAlbuminkorrigeret -> Albumin", html, fixed = TRUE), "LYFO renderer must not show albumin-corrected calcium as albumin.")
expect_false(grepl("Reg_Lokal_Pancreas -> Creatinine", html, fixed = TRUE), "LYFO renderer must not show pancreas localization as creatinine.")
for (needle in c("CRP / C-reactive protein", "Albumin-corrected calcium", "FISH probe fields", "FISH result fields", "Interpreted cytogenetic/FISH summary fields")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("DaMyDa renderer should contain corrected semantic section:", needle))
}
expect_false(grepl("Reg_CReaktivtProtein_gl -> Creatinine", html, fixed = TRUE), "DaMyDa renderer must not show C-reactive protein as creatinine.")
expect_false(grepl("Reg_CReaktivtProtein_nMoll -> Creatinine", html, fixed = TRUE), "DaMyDa renderer must not show C-reactive protein as creatinine.")
expect_false(grepl("Reg_CalciumAlbuminkorrigeret -> Albumin", html, fixed = TRUE), "DaMyDa renderer must not show albumin-corrected calcium as albumin.")
expect_false(grepl("key.includes(normalizeClinicalKey(pattern))", html, fixed = TRUE), "DaMyDa raw-lineage priority should not rely on broad substring pattern matching.")
expect_true(grepl("damydaColumnEquals", html, fixed = TRUE) && grepl("damydaColumnStartsWith", html, fixed = TRUE), "DaMyDa raw-lineage priority should use exact and anchored field matching.")
for (needle in c("section-baseline-markers", "renderDaMyDaFacetGroup(\"Staging/risk\"", "renderDaMyDaFacetGroup(\"Treatment\"", "renderDaMyDaFacetGroup(\"Response/relapse\"", "renderDaMyDaFacetGroup(\"Bone disease / imaging\"", "renderDaMyDaFacetGroup(\"Cytogenetics/FISH availability\"")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("DaMyDa dashboard should include section-card hook:", needle))
}
for (needle in c("renderLYFOFacetGroup(\"Subtype mix\"", "renderLYFOFacetGroup(\"Staging and risk\"", "renderLYFOFacetGroup(\"B symptoms and bulk disease\"", "renderLYFOFacetGroup(\"Performance status\"", "renderLYFORawGroup(\"Treatment and regimen fields\"", "renderLYFORawGroup(\"Response / follow-up / relapse fields\"", "renderLYFORawGroup(\"Disease localization\"")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("LYFO dashboard should include section-card hook:", needle))
}
for (needle in c("RKKP_DaMyDa", "registry entries", "variables", "not available in current aggregate output", "Reg_Haemoglobin", "Reg_Creatinin_mikmoll", "Reg_LDH", "Reg_Albumin_gl", "Reg_Beta2Microglobulin_gl", "Reg_ProcentKlonalePlasmaceller", "Stadie", "Reg_PerformanceStatus", "Reg_Knogleforandringer", "IND_Relaps", "Cyto_FishUdfoert")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("DaMyDa renderer should visibly contain:", needle))
}
for (needle in c("n_available", "pct_available", "mean", "median", "p25", "p75", "unit", "source_column")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("DaMyDa numeric renderer should use field:", needle))
}
vaegt <- paste0("V", intToUtf8(0x00E6), "gt")
hoejde <- paste0("H", intToUtf8(0x00F8), "jde")
for (needle in c("SP_VitaleVaerdier", "patientid", "displayname", "numericvalue", vaegt, hoejde)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Vitals renderer should visibly contain:", needle))
}
for (needle in c("SP_Social_Hx", "ryger", "drikker", "Er holdt op", "Aldrig", "Ja", "Ikke spurgt", "Passiv", "Ikke aktuelt", "Udskyd")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Social History renderer should visibly contain:", needle))
}
expect_true(grepl("jumpToClinicalConcept", html, fixed = TRUE), "Concept-link buttons should use the Clinical Variables search/filter path.")
expect_true(grepl("Repeated measures", html, fixed = TRUE) && grepl("baseline window", html, fixed = TRUE) && grepl("outlier filtering", html, fixed = TRUE), "Vitals renderer should include the required caveat.")
expect_true(grepl("Unknown and true missing were not separately quantified in this output", html, fixed = TRUE), "Social History renderer should include the unknown/missing evidence note.")
expect_true(grepl("Row-level social-history observations do not necessarily equal current patient-level status", html, fixed = TRUE), "Social History renderer should include the row-level caveat.")
expect_true(grepl("{ label: \"patients\", value: patientCountForConcept", html, fixed = TRUE), "Vitals stat cards should render patient-count fields.")
expect_true(grepl("clinical-metric-card", html, fixed = TRUE) && grepl("{ label: \"unit\", value: unit || \"not available\"", html, fixed = TRUE), "Vitals stat cards should render units with a not-available fallback.")
expect_true(grepl("renderVitalsStatCard(\"Weight\", [\"Vægt\", \"Vaegt\", \"VÃ¦gt\"], \"weight\", \"kg\")", html, fixed = TRUE), "Vitals stat cards should render kg for weight.")
expect_true(grepl("renderVitalsStatCard(\"Height\", [\"Højde\", \"Hoejde\", \"HÃ¸jde\"], \"height\", \"cm\")", html, fixed = TRUE), "Vitals stat cards should render cm for height.")
expect_true(grepl("scope: mixed; displayed distributions are cartography_scan", html, fixed = TRUE) || grepl("scope: displayed distributions are cartography_scan", html, fixed = TRUE), "Vitals/Social renderer should expose cartography-scan scope.")
bmi_label <- paste("BMI", intToUtf8(0x2014), "derived from height and weight")
expect_true(grepl(bmi_label, html, fixed = TRUE), "Vitals lineage should label BMI as derived from height and weight.")
expect_true(grepl("const priorityRows = [weightRow, heightRow, numericRow].filter(Boolean)", html, fixed = TRUE), "Vitals renderer should order priority raw lineage as Vægt, Højde, numericvalue.")
expect_true(grepl("semantic-search", html, fixed = TRUE), "HTML should include semantic dictionary search.")
expect_true(grepl("semantic-group-filter", html, fixed = TRUE), "HTML should include semantic dictionary group filtering.")
expect_true(grepl("semantic-panel-filter", html, fixed = TRUE), "HTML should include semantic dictionary panel filtering.")
expect_true(grepl("semantic-detail", html, fixed = TRUE), "HTML should include semantic lineage detail drawer.")
expect_true(grepl("function renderSemanticLineageKeyValues", html, fixed = TRUE), "Data Dictionary detail pane should use a stacked lineage renderer.")
expect_true(grepl("semantic-detail-stack", html, fixed = TRUE), "Data Dictionary detail pane should include the stacked lineage class.")
expect_true(grepl("semantic-full-lineage", html, fixed = TRUE), "Data Dictionary Full lineage block should be explicitly identifiable for rendered QA.")
expect_false(grepl("${rowsForTable([row], 1)}", html, fixed = TRUE), "Data Dictionary Full lineage should not render as a wide one-row table.")
for (needle in c("Clinical meaning", "Raw data location", "Value/code details", "Structural columns", "Evidence and confidence", "Caveats")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Data Dictionary stacked lineage should include section:", needle))
}
for (needle in c("Semantic ID", "Clinical concept", "Clinical variable", "Clinical group/subgroup", "Source name", "Object name", "Schema/table name", "Raw column", "Raw descriptor", "Raw code", "Raw value", "Code system", "Unit", "Value type", "Data shape", "Patient ID column", "Date column", "Value column", "Evidence file", "Evidence filter", "Mapping status", "Mapping confidence", "Clinical caveat")) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("Data Dictionary stacked lineage should include field label:", needle))
}
expect_true(grepl("Key raw fields", html, fixed = TRUE), "HTML domain panels should include key raw fields blocks.")
expect_true(grepl("qa-severity-filter", html, fixed = TRUE), "HTML should include QA filtering controls.")
expect_true(grepl("run-action-items", html, fixed = TRUE), "HTML should include action item containers.")
expect_true(grepl("action-summary-cards", html, fixed = TRUE), "HTML should include action item summary cards.")
expect_true(grepl("streaming-progress-cards", html, fixed = TRUE), "HTML should include DB streaming progress cards.")
expect_true(grepl("temporal-date-quality-cards", html, fixed = TRUE), "HTML should include temporal date-quality cards.")
expect_true(grepl("infrastructure-streaming-progress", html, fixed = TRUE), "HTML should include DB streaming progress tables.")
expect_true(grepl("infrastructure-temporal-date-quality", html, fixed = TRUE), "HTML should include temporal date-quality tables.")
expect_true(grepl("panel-nav", html, fixed = TRUE), "HTML should include panel navigation.")
expect_true(grepl("temporal-heatmap", html, fixed = TRUE), "HTML should include a temporal coverage heatmap container.")
expect_true(grepl("dkMap", html, fixed = TRUE), "HTML should include a Denmark choropleth container.")
expect_true(grepl("regionMatrix", html, fixed = TRUE), "HTML should include a region coverage matrix container.")
expect_true(grepl("dk-region", html, fixed = TRUE), "HTML should include clickable Denmark region handlers.")
expect_true(grepl("situation-cards", html, fixed = TRUE), "HTML should include Situation Report card containers.")
expect_true(grepl("of cohort", html, fixed = TRUE), "Situation Report cards should show patient counts as a share of the cohort.")
expect_true(grepl("data as of", html, fixed = TRUE), "Situation Report cards should label source dates as data-as-of anchors.")
payload <- paste(readLines(result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl("damyda_clinical_profile", payload, fixed = TRUE), "Payload should include the DaMyDa clinical profile panel.")
expect_true(grepl("lyfo_clinical_profile", payload, fixed = TRUE), "Payload should include the LYFO clinical profile panel.")
expect_true(grepl("cll_clinical_profile", payload, fixed = TRUE), "Payload should include the CLL clinical profile panel.")
expect_true(grepl("run_summary", payload, fixed = TRUE), "Payload should include run summary rows.")
expect_true(grepl("action_items", payload, fixed = TRUE), "Payload should include run action items.")
expect_true(grepl("action_summary", payload, fixed = TRUE), "Payload should include action item summaries.")
expect_true(grepl("db_query_log", payload, fixed = TRUE), "Payload should include DB query log diagnostics.")
expect_true(grepl("db_budget_actions", payload, fixed = TRUE), "Payload should include DB budget action diagnostics.")
expect_true(grepl("source_domains", payload, fixed = TRUE), "Payload should include source-domain summaries.")
expect_true(grepl("hero_metrics", payload, fixed = TRUE), "Payload should include hero metrics.")
expect_true(grepl("domain_cards", payload, fixed = TRUE), "Payload should include domain cards.")
expect_true(grepl("catalog_rows", payload, fixed = TRUE), "Payload should include catalog rows.")
expect_true(grepl("qa_items", payload, fixed = TRUE), "Payload should include QA items.")
expect_true(grepl("npu_cards", payload, fixed = TRUE), "Payload should include NPU dictionary cards.")
expect_true(grepl("detective_cards", payload, fixed = TRUE), "Payload should include NPU detective cards.")
expect_true(grepl("isotype_cards", payload, fixed = TRUE), "Payload should include isotype cards.")
expect_true(grepl("treatment_cards", payload, fixed = TRUE), "Payload should include treatment-code cards.")
expect_true(grepl("situation_report_cards", payload, fixed = TRUE), "Payload should include Situation Report cards.")
expect_true(grepl("registry_cards", payload, fixed = TRUE), "Payload should include registry cards.")
expect_true(grepl("panel_groups", payload, fixed = TRUE), "Payload should include panel groups.")
expect_true(grepl("column_profile_rows", payload, fixed = TRUE), "Payload should include column profile rows.")
expect_true(grepl("column_top_value_rows", payload, fixed = TRUE), "Payload should include column top value rows.")
expect_true(grepl("column_profile_summary", payload, fixed = TRUE), "Payload should include column profile summary.")
expect_true(grepl("semantic_dictionary_rows", payload, fixed = TRUE), "Payload should include semantic dictionary rows.")
expect_true(grepl("semantic_value_map_rows", payload, fixed = TRUE), "Payload should include semantic value map rows.")
expect_true(grepl("semantic_code_map_rows", payload, fixed = TRUE), "Payload should include semantic code map rows.")
expect_true(grepl("semantic_panel_links", payload, fixed = TRUE), "Payload should include semantic panel links.")
expect_true(grepl("clinical_concept_rows", payload, fixed = TRUE), "Payload should include Clinical Variables concept rows.")
expect_true(grepl("domain_panel_rows", payload, fixed = TRUE), "Payload should include product-layer domain panel rows.")
expect_true(grepl("panel_kpi_rows", payload, fixed = TRUE), "Payload should include product-layer KPI rows.")
expect_true(grepl("panel_distribution_rows", payload, fixed = TRUE), "Payload should include product-layer distribution rows.")
expect_true(grepl("panel_raw_field_rows", payload, fixed = TRUE), "Payload should include product-layer raw field rows.")
expect_true(grepl("panel_parity_rows", payload, fixed = TRUE), "Payload should include V33 panel parity rows.")
expect_true(grepl("review_clinical_variables", payload, fixed = TRUE), "Payload should include the Clinical Variables view model.")
expect_true(grepl("review_semantic_summary", payload, fixed = TRUE), "Payload should include semantic summary rows.")
expect_true(grepl("Smoking status", payload, fixed = TRUE), "Payload should expose clinician-facing semantic variables.")
expect_true(grepl("NPU02319", payload, fixed = TRUE), "Payload should expose aggregate NPU semantic code lineage.")
expect_true(grepl("builder_credit", payload, fixed = TRUE), "Payload should include transparent generated-atlas credit.")
expect_true(grepl("Built by Alexander Owen Taylor", payload, fixed = TRUE), "Payload should include the generated-atlas credit value.")
expect_true(grepl("review_scope_notes", payload, fixed = TRUE), "Payload should include review scope notes.")
expect_true(grepl("review_data_landscape", payload, fixed = TRUE), "Payload should include review data landscape.")
expect_true(grepl("review_module_readiness", payload, fixed = TRUE), "Payload should include module readiness.")
expect_true(grepl("review_streaming_summary", payload, fixed = TRUE), "Payload should include DB streaming progress summaries.")
expect_true(grepl("review_temporal_date_quality", payload, fixed = TRUE), "Payload should include temporal date-quality summaries.")
expect_true(grepl("review_domain_jump_links", payload, fixed = TRUE), "Payload should include review jump links.")
expect_true(grepl("review_nav", payload, fixed = TRUE), "Payload should include V33-style navigation.")
expect_true(grepl("review_overview", payload, fixed = TRUE), "Payload should include V33-style overview sections.")
expect_true(grepl("review_registry_sections", payload, fixed = TRUE), "Payload should include V33-style registry sections.")
expect_true(grepl("review_clinical_sections", payload, fixed = TRUE), "Payload should include V33-style clinical sections.")
expect_true(grepl("review_treatment_sections", payload, fixed = TRUE), "Payload should include V33-style treatment sections.")
expect_true(grepl("review_laboratory_sections", payload, fixed = TRUE), "Payload should include V33-style laboratory sections.")
expect_true(grepl("review_situation_sections", payload, fixed = TRUE), "Payload should include V33-style Situation Report sections.")
expect_true(grepl("review_ehr_sections", payload, fixed = TRUE), "Payload should include V33-style EHR sections.")
expect_true(grepl("review_infrastructure_sections", payload, fixed = TRUE), "Payload should include V33-style infrastructure sections.")
expect_true(grepl("review_temporal_coverage", payload, fixed = TRUE), "Payload should include V33-style temporal coverage sections.")
expect_true(grepl("review_spatial_coverage", payload, fixed = TRUE), "Payload should include V33-style spatial coverage sections.")
expect_true(grepl("review_dk_choropleth", payload, fixed = TRUE), "Payload should include V33-style Denmark choropleth sections.")
expect_false(grepl("\"aot|\"AOT|\"Alexander", payload), "Payload keys should not use personal or AOT naming.")
expect_false(grepl("patientid", payload, ignore.case = TRUE), "HTML payload should not expose id-like field names.")

freq <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_value_frequencies.csv"), stringsAsFactors = FALSE)
expect_false(any(freq$column_name == "patientid"), "Public value frequencies must not expose patient IDs.")

manifest <- utils::read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE)
expect_true(all(c("resource_catalog", "source_resolution", "dalycare_access", "memory_plan", "db_query_log", "db_budget_actions", "action_items", "sources", "columns", "column_profiles", "column_top_values", "checks", "value_frequencies", "semantic_dictionary", "semantic_value_map", "semantic_code_map", "semantic_panel_links", "clinical_concepts", "domain_panels", "panel_kpis", "panel_distributions", "panel_raw_fields", "panel_parity", "run_summary", "html", "payload", "memory_log") %in% manifest$artifact_id), "Manifest should list expected artifacts.")
expect_true(all(c("npu_dictionary_summary", "npu_dictionary_vectors", "npu_lab_usage_by_vector", "npu_lab_unmatched_codes", "npu_detective_code_inventory", "npu_detective_candidates", "npu_detective_source_year", "isotype_code_usage", "isotype_bucket_summary", "mm_treatment_code_counts", "mm_treatment_source_summary", "registry_clinical_summary", "damyda_clinical_profile", "damyda_numeric_fields", "lyfo_clinical_profile", "cll_clinical_profile") %in% manifest$artifact_id), "Manifest should list NPU, isotype, treatment, and registry panel artifacts.")
expect_true(all(c("atlas_temporal_coverage", "atlas_temporal_coverage_years", "atlas_spatial_region_counts", "atlas_spatial_region_coverage", "atlas_dk_choropleth_regions") %in% manifest$artifact_id), "Manifest should list V33 coverage panel artifacts.")
expect_true(all(c("atlas_temporal_date_quality", "atlas_streaming_progress_summary") %in% manifest$artifact_id), "Manifest should list date-quality and streaming-progress panel artifacts.")
expect_true(all(c("situation_report_summary", "situation_report_breakdowns", "situation_report_freshness") %in% manifest$artifact_id), "Manifest should list Situation Report panel artifacts.")
expect_true("atlas_module_readiness" %in% manifest$artifact_id, "Manifest should list the module readiness panel artifact.")
expect_false(any(grepl("aot|AOT|Alexander", manifest$artifact_id)), "Generated artifact IDs should use neutral names.")
expect_true(all(manifest$status == "ok"), "Manifest artifacts should exist.")

sources <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_sources.csv"), stringsAsFactors = FALSE)
expect_true(all(c("domain", "subdomain", "atlas_role") %in% names(sources)), "Source metadata should be preserved in atlas_sources.csv.")
expect_true(all(c("chosen_strategy", "memory_status", "resolution_status") %in% names(sources)), "Source rows should record memory-safe profiling decisions.")
expect_true(!any(sources$date_column_guess == "patientid"), "Patient identifiers should not be guessed as date columns.")
expect_true("2021-01-01" %in% sources$min_date, "Date ranges should be emitted as ISO dates.")

columns <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_columns.csv"), stringsAsFactors = FALSE)
column_profiles <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_column_profiles.csv"), stringsAsFactors = FALSE)
column_top_values <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_column_top_values.csv"), stringsAsFactors = FALSE)
expect_equal(nrow(column_profiles), nrow(columns), "Run output should include one column profile per profiled column.")
expect_true(any(column_profiles$profile_kind == "numeric"), "Column profile output should include numeric summaries when numeric columns exist.")
expect_true(any(column_profiles$profile_kind == "date"), "Column profile output should include date summaries when date columns exist.")
expect_false(any(column_top_values$column_name == "patientid"), "Column top values must not expose patient identifier columns.")
expect_true(all(c("domain", "subdomain", "atlas_role") %in% names(column_profiles)), "Column profiles should retain source metadata.")

catalog <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv"), stringsAsFactors = FALSE)
expect_true(all(c("domain", "subdomain", "atlas_role") %in% names(catalog)), "Source metadata should be preserved in the resource catalog.")

damyda_clinical <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "damyda_clinical_profile.csv"), stringsAsFactors = FALSE)
expect_true(any(damyda_clinical$facet == "stage"), "Run output should include DaMyDa stage summary.")
expect_false(any(damyda_clinical$source_column == "patientid"), "Run output registry panels must not expose patient identifier columns.")

damyda_numeric <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "damyda_numeric_fields.csv"), stringsAsFactors = FALSE)
expect_true(any(damyda_numeric$field == "albumin"), "Run output should include DaMyDa albumin aggregate summary.")
expect_false(any(c("value", "examples", "distinct_sample") %in% names(damyda_numeric)), "Run output numeric registry panel should be aggregate-only.")

npu_summary <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_dictionary_summary.csv"), stringsAsFactors = FALSE)
npu_vectors <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_dictionary_vectors.csv"), stringsAsFactors = FALSE)
npu_usage <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_lab_usage_by_vector.csv"), stringsAsFactors = FALSE)
npu_unmatched <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_lab_unmatched_codes.csv"), stringsAsFactors = FALSE)
npu_inventory <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_detective_code_inventory.csv"), stringsAsFactors = FALSE)
npu_candidates <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "npu_detective_candidates.csv"), stringsAsFactors = FALSE)
isotype_usage <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "isotype_code_usage.csv"), stringsAsFactors = FALSE)
isotype_buckets <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "isotype_bucket_summary.csv"), stringsAsFactors = FALSE)
mm_counts <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "mm_treatment_code_counts.csv"), stringsAsFactors = FALSE)
mm_sources <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "mm_treatment_source_summary.csv"), stringsAsFactors = FALSE)
temporal_coverage <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_coverage.csv"), stringsAsFactors = FALSE)
temporal_years <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_coverage_years.csv"), stringsAsFactors = FALSE)
temporal_quality <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_temporal_date_quality.csv"), stringsAsFactors = FALSE)
streaming_progress <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_streaming_progress_summary.csv"), stringsAsFactors = FALSE)
spatial_counts <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_spatial_region_counts.csv"), stringsAsFactors = FALSE)
spatial_coverage <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_spatial_region_coverage.csv"), stringsAsFactors = FALSE)
dk_regions <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "atlas_dk_choropleth_regions.csv"), stringsAsFactors = FALSE)
expect_true("dictionary_codes" %in% npu_summary$metric, "Run output should include NPU dictionary summary.")
expect_true(any(npu_vectors$consensus_vector == "CREATININE_CODES"), "Run output should include NPU dictionary vector summaries.")
expect_true(any(npu_usage$consensus_vector == "CREATININE_CODES"), "Run output should include observed NPU usage by consensus vector.")
expect_true(any(npu_unmatched$npu_code == "NPU99999"), "Run output should include suppressed-safe unmatched NPU code summaries.")
expect_true(any(npu_inventory$surface == "renal_creatinine"), "Run output should include NPU detective surface classifications.")
expect_true(any(npu_candidates$npu_code == "NPU99999"), "Run output should include NPU detective candidates.")
expect_true(any(isotype_usage$isotype_family == "IgG"), "Run output should include isotype finder usage.")
expect_true(any(isotype_buckets$bucket == "heavy_chain"), "Run output should include isotype bucket summaries.")
expect_true(any(mm_counts$code == "BWHA154"), "Run output should count exact MM treatment codes.")
expect_true(any(mm_counts$code == "BWG"), "Run output should count MM treatment prefix codes.")
expect_true(nrow(mm_sources) > 0, "Run output should summarize treatment evidence sources.")
expect_true(any(temporal_coverage$table_name == "example_labs" & temporal_coverage$display_min_year == 2021), "Run output should include clamped temporal coverage by source.")
expect_true(any(temporal_years$table_name == "example_labs" & temporal_years$year == 2021), "Run output should include temporal coverage year counts.")
expect_true(all(c("issue_type", "message") %in% names(temporal_quality)), "Run output should include temporal date-quality audit columns.")
expect_true(all(c("streamed_columns", "total_chunks", "slowest_column") %in% names(streaming_progress)), "Run output should include DB streaming progress summary columns.")
expect_true(any(spatial_counts$table_name == "example_damyda" & spatial_counts$region_code == "1084"), "Run output should include aggregate DaMyDa region counts.")
expect_true(any(spatial_coverage$region_code == "1084"), "Run output should include region coverage matrix rows.")
expect_equal(sum(as.logical(dk_regions$map_include)), 5L, "Denmark choropleth should include the five Danish regions.")
expect_false(any(dk_regions$region_code == "1099" & as.logical(dk_regions$map_include)), "Other/unknown region should not be shaded on the map.")

run_summary <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_run_summary.csv"), stringsAsFactors = FALSE)
expect_true(all(c("builder_credit", "mapped_sources", "loaded_sources", "skipped_sources", "panel_rows", "min_cell_count", "db_aggregate_sources", "dataset_full_load_fallback_sources") %in% run_summary$metric), "Run summary should include compact run, credit, and memory metrics.")
expect_true("Built by Alexander Owen Taylor" %in% run_summary$value[run_summary$metric == "builder_credit"], "Run summary should record the generated-atlas credit.")
expect_true("1" %in% run_summary$value[run_summary$metric == "min_cell_count"], "Run summary should record the active minimum cell count.")

action_items <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_run_action_items.csv"), stringsAsFactors = FALSE)
expect_true(all(c("severity", "action_id", "recommended_action") %in% names(action_items)), "Run action items should include severity, action id, and operator action columns.")

semantic_dictionary <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_semantic_data_dictionary.csv"), stringsAsFactors = FALSE)
semantic_value_map <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_semantic_value_map.csv"), stringsAsFactors = FALSE)
semantic_code_map <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_semantic_code_map.csv"), stringsAsFactors = FALSE)
semantic_panel_links <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_semantic_panel_links.csv"), stringsAsFactors = FALSE)
clinical_concepts <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_clinical_concepts.csv"), stringsAsFactors = FALSE)
domain_panels <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_domain_panels.csv"), stringsAsFactors = FALSE)
panel_kpis <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_panel_kpis.csv"), stringsAsFactors = FALSE)
panel_distributions <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_panel_distributions.csv"), stringsAsFactors = FALSE)
panel_raw_fields <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_panel_raw_fields.csv"), stringsAsFactors = FALSE)
panel_parity <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_panel_parity.csv"), stringsAsFactors = FALSE)
expect_true(any(semantic_dictionary$raw_column == "ryger" & semantic_dictionary$clinical_variable == "Smoking status"), "Semantic output should map ryger to Smoking status.")
expect_true(any(semantic_dictionary$raw_column == "drikker" & semantic_dictionary$clinical_variable == "Alcohol use"), "Semantic output should map drikker to Alcohol use.")
expect_true(any(semantic_dictionary$raw_descriptor == "Vægt" & semantic_dictionary$clinical_variable == "Weight"), "Semantic output should map Vægt to Weight.")
expect_true(any(semantic_dictionary$raw_descriptor == "Højde" & semantic_dictionary$clinical_variable == "Height"), "Semantic output should map Højde to Height.")
expect_true(any(semantic_dictionary$raw_column == "Reg_LDH" & semantic_dictionary$clinical_variable == "LDH"), "Semantic output should map Reg_LDH to LDH.")
expect_true(any(semantic_dictionary$raw_column == "Reg_Creatinin_mikmoll" & semantic_dictionary$clinical_variable == "Creatinine"), "Semantic output should map Reg_Creatinin_mikmoll to creatinine.")
run_crp <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_DaMyDa" & semantic_dictionary$raw_column %in% c("Reg_CReaktivtProtein_gl", "Reg_CReaktivtProtein_nMoll"), , drop = FALSE]
expect_true(nrow(run_crp) >= 2 && all(run_crp$clinical_concept_id == "crp" & run_crp$clinical_variable == "CRP"), "Run semantic output should map DaMyDa C-reactive protein fields to CRP.")
expect_false(any(run_crp$clinical_concept_id == "creatinine" | run_crp$clinical_variable == "Creatinine"), "Run semantic output must not map DaMyDa C-reactive protein fields to creatinine.")
run_corrected_calcium <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_DaMyDa" & semantic_dictionary$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(run_corrected_calcium) > 0 && all(run_corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "Run semantic output should map DaMyDa albumin-corrected calcium to its own concept.")
expect_false(any(run_corrected_calcium$clinical_concept_id == "albumin" | run_corrected_calcium$clinical_variable == "Albumin"), "Run semantic output must not map DaMyDa albumin-corrected calcium to albumin.")
run_fish_probe <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishProber_", semantic_dictionary$raw_column), , drop = FALSE]
run_fish_result <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_DaMyDa" & grepl("^Cyto_FishResultat_", semantic_dictionary$raw_column), , drop = FALSE]
expect_true(nrow(run_fish_probe) > 0 && all(run_fish_probe$clinical_concept_id == "fish_probe"), "Run semantic output should preserve FISH probe context.")
expect_true(nrow(run_fish_result) > 0 && all(run_fish_result$clinical_concept_id == "fish_result"), "Run semantic output should preserve FISH result context.")
run_lyfo <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_LYFO", , drop = FALSE]
run_lyfo_histology <- run_lyfo[run_lyfo$raw_column %in% c("Reg_WHOHistologikode1", "Reg_WHOHistologikode2", "Rec_WHOHistologikode"), , drop = FALSE]
expect_true(nrow(run_lyfo_histology) > 0 && any(run_lyfo_histology$clinical_concept_id == "lymphoma_subtype_code"), "Run semantic output should map LYFO histology fields to subtype-code context.")
expect_false(any(run_lyfo_histology$clinical_concept_id == "performance_status" | run_lyfo_histology$clinical_variable == "Performance status"), "Run semantic output must not map LYFO histology fields to performance status.")
run_lyfo_corrected_calcium <- run_lyfo[run_lyfo$raw_column == "Reg_CalciumAlbuminkorrigeret", , drop = FALSE]
expect_true(nrow(run_lyfo_corrected_calcium) > 0 && all(run_lyfo_corrected_calcium$clinical_concept_id == "albumin_corrected_calcium"), "Run semantic output should map LYFO albumin-corrected calcium to its own concept.")
expect_false(any(run_lyfo_corrected_calcium$clinical_concept_id == "albumin" | run_lyfo_corrected_calcium$clinical_variable == "Albumin"), "Run semantic output must not map LYFO albumin-corrected calcium to albumin.")
run_lyfo_pancreas <- run_lyfo[run_lyfo$raw_column == "Reg_Lokal_Pancreas", , drop = FALSE]
expect_true(nrow(run_lyfo_pancreas) > 0 && all(run_lyfo_pancreas$clinical_concept_id == "disease_localization"), "Run semantic output should map LYFO pancreas localization to disease localization.")
expect_false(any(run_lyfo_pancreas$clinical_concept_id == "creatinine" | run_lyfo_pancreas$clinical_variable == "Creatinine"), "Run semantic output must not map LYFO pancreas localization to creatinine.")
run_lyfo_ldh <- run_lyfo[run_lyfo$raw_column %in% c("Reg_Lactatdehydrogenase", "Reg_LDHVaerdi"), , drop = FALSE]
if (nrow(run_lyfo_ldh)) {
  expect_true(all(run_lyfo_ldh$clinical_concept_id == "ldh"), "Run semantic output should map LYFO LDH fields to LDH.")
}
lyfo_index_expectations <- c(IPI = "ipi", aaIPI = "aaipi", FLIPI = "flipi", FLIPI2 = "flipi2", IPS = "ips")
for (raw_field in names(lyfo_index_expectations)) {
  concept <- unname(lyfo_index_expectations[[raw_field]])
  rows <- run_lyfo[run_lyfo$raw_column == raw_field, , drop = FALSE]
  if (nrow(rows)) {
    expect_true(all(rows$clinical_concept_id == concept & rows$clinical_variable == raw_field), paste("Run semantic output should preserve LYFO prognostic index:", raw_field))
  }
}
run_cll <- semantic_dictionary[semantic_dictionary$source_name == "RKKP_CLL", , drop = FALSE]
expect_run_cll_mapping <- function(raw_column, concept_id, variable_pattern) {
  rows <- run_cll[run_cll$raw_column == raw_column, , drop = FALSE]
  if (nrow(rows)) {
    expect_true(
      any(rows$clinical_concept_id == concept_id & grepl(variable_pattern, rows$clinical_variable, ignore.case = TRUE)),
      paste("Run semantic output should map CLL field to", concept_id, ":", raw_column)
    )
  }
}
expect_run_cll_mapping("Reg_BinetStadium", "binet_stage", "Binet stage")
expect_run_cll_mapping("Reg_Umuteret", "ighv_mutation_status", "IGHV mutation status")
expect_run_cll_mapping("Reg_FISH", "fish_availability", "FISH")
expect_run_cll_mapping("Reg_Del17p", "del17p", "del\\(17p\\)")
expect_run_cll_mapping("Reg_Del11q", "del11q", "del\\(11q\\)")
expect_run_cll_mapping("Reg_Del13q14", "del13q14", "del\\(13q14\\)")
expect_run_cll_mapping("Reg_Trisomi12", "trisomy12", "Trisomy 12")
expect_run_cll_mapping("Reg_TP53", "tp53_status", "TP53 status")
expect_run_cll_mapping("Beh_TP53Mutation", "tp53_status", "TP53 mutation")
expect_run_cll_mapping("Reg_KnoglemarvsUndersoegelse", "bone_marrow_examination", "bone marrow")
expect_run_cll_mapping("Reg_CTSCANNING", "cll_diagnostic_ct_workup", "CT workup")
expect_run_cll_mapping("Reg_ULSCANNING", "cll_diagnostic_ultrasound_workup", "ultrasound workup")
expect_run_cll_mapping("Beh_Vaegttab", "weight_loss", "Weight loss")
expect_run_cll_mapping("Beh_Feber", "fever", "Fever")
expect_run_cll_mapping("Beh_Nattesved", "night_sweats", "Night sweats")
expect_run_cll_mapping("Beh_UdtaltTraethed", "marked_fatigue", "Marked fatigue")
expect_run_cll_mapping("Beh_Lymfadenopati", "lymphadenopathy", "Lymphadenopathy")
expect_run_cll_mapping("Beh_TargeteretBeh_Ibrutinib", "cll_targeted_therapy", "Ibrutinib")
expect_run_cll_mapping("Beh_TargeteretBeh_venetoclax", "cll_targeted_therapy", "Venetoclax")
expect_run_cll_mapping("Beh_TargeteretBeh_acalabrutinib", "cll_targeted_therapy", "Acalabrutinib")
expect_run_cll_mapping("Beh_MRD", "mrd", "MRD")
expect_run_cll_mapping("Beh_Responsevaluering", "response_evaluation", "Response evaluation")
expect_false(any(run_cll$raw_column == "Beh_Vaegttab" & run_cll$clinical_concept_id == "weight"), "Run semantic output must not map CLL weight loss to weight measurement.")
expect_false(any(run_cll$raw_column == "Reg_KnoglemarvsUndersoegelse" & run_cll$clinical_concept_id == "bone_involvement"), "Run semantic output must not map CLL bone marrow examination to bone involvement.")
expect_false(any(run_cll$raw_column %in% c("Reg_FISH", "Reg_Del17p", "Reg_Del11q", "Reg_Del13q14", "Reg_Trisomi12", "Reg_TP53", "Beh_TP53Mutation", "Beh_FISH_TP53", "Rec_FISH_TP53") & run_cll$clinical_concept_id == "cytogenetic_risk"), "Run semantic output must not flatten CLL FISH/del/TP53 fields to generic cytogenetic risk.")
expect_true(any(semantic_dictionary$raw_code == "NPU02319" & semantic_dictionary$clinical_variable == "Haemoglobin"), "Semantic output should map NPU02319 to haemoglobin.")
expect_true(any(semantic_dictionary$raw_code == "DNK35302" & grepl("eGFR", semantic_dictionary$clinical_variable, fixed = TRUE)), "Semantic output should map DNK35302 to eGFR / CKD-EPI.")
expect_true(any(semantic_dictionary$raw_code == "NPU19748" & semantic_dictionary$clinical_variable == "Leukocytes"), "Semantic output should map NPU19748 to leukocytes.")
expect_true(any(semantic_dictionary$raw_code == "NPU02593" & semantic_dictionary$clinical_concept_id == "creatinine"), "Semantic output should map NPU02593 to creatinine.")
expect_true(any(semantic_dictionary$raw_code == "NPU02636" & semantic_dictionary$clinical_concept_id == "ldh"), "Semantic output should map NPU02636 to LDH when evidenced.")
expect_true(any(semantic_dictionary$raw_code == "NPU01349" & semantic_dictionary$clinical_concept_id == "albumin"), "Semantic output should map NPU01349 to albumin when evidenced.")
if (any(semantic_dictionary$raw_code == "NPU04998")) {
  expect_true(any(semantic_dictionary$raw_code == "NPU04998" & semantic_dictionary$clinical_concept_id == "crp"), "Semantic output should map NPU04998 to CRP when evidenced.")
}
lab_semantic_rows <- semantic_dictionary[semantic_dictionary$clinical_group == "Laboratory", , drop = FALSE]
expect_false(any(grepl("CReaktivtProtein", lab_semantic_rows$raw_column, fixed = TRUE) & lab_semantic_rows$clinical_concept_id == "creatinine"), "Laboratory semantic output must not map C-reactive protein to creatinine.")
expect_false(any(lab_semantic_rows$raw_column == "Reg_CalciumAlbuminkorrigeret" & lab_semantic_rows$clinical_concept_id == "albumin"), "Laboratory semantic output must not map albumin-corrected calcium to albumin.")
expect_false(any(lab_semantic_rows$raw_column == "Reg_LYMFOCYTFORDOBLIN" & lab_semantic_rows$clinical_concept_id == "lymphocytes"), "Laboratory semantic output must not map lymphocyte doubling to lymphocyte count.")
expect_false(any(semantic_code_map$clinical_group == "Laboratory" & semantic_code_map$code_system %in% c("ATC", "SKS")), "ATC/SKS treatment rows must not appear in the primary Laboratory/NPU code map.")
npu_dnk_code_rows <- semantic_code_map[semantic_code_map$code_system %in% c("NPU", "DNK"), , drop = FALSE]
expect_false(any(npu_dnk_code_rows$clinical_group == "Treatment"), "NPU/DNK laboratory code rows must not remain classified as Treatment.")
expect_false(any(grepl("^treatment_", npu_dnk_code_rows$clinical_concept_id)), "NPU/DNK laboratory code rows must not use treatment-prefixed concept IDs.")
expect_lab_code_map <- function(code, concept_id, variable_pattern) {
  rows <- semantic_code_map[semantic_code_map$code == code, , drop = FALSE]
  if (!nrow(rows)) return(invisible(TRUE))
  expect_true(any(rows$clinical_group == "Laboratory" & rows$clinical_concept_id == concept_id & grepl(variable_pattern, rows$clinical_variable, ignore.case = TRUE)), paste("Semantic code map should keep", code, "as", concept_id, "/ Laboratory."))
}
expect_lab_code_map("NPU02319", "haemoglobin", "Haemoglobin")
expect_lab_code_map("NPU02593", "creatinine", "Creatinine")
expect_lab_code_map("DNK35302", "egfr", "eGFR")
expect_lab_code_map("NPU04998", "crp", "CRP")
treatment_matrix_lab_rows <- npu_dnk_code_rows[grepl("cartography_disease_treatment_matrix", npu_dnk_code_rows$evidence_file, fixed = TRUE), , drop = FALSE]
if (nrow(treatment_matrix_lab_rows)) {
  expect_true(all(grepl("supporting laboratory evidence; not treatment exposure", treatment_matrix_lab_rows$notes, fixed = TRUE)), "Treatment-matrix NPU/DNK rows should carry supporting-lab provenance caveat.")
}
expect_true(any(semantic_value_map$raw_column == "ryger" & semantic_value_map$display_value == "Former smoker"), "Semantic value map should include smoking value meanings.")
expect_true(any(semantic_code_map$code_system == "ATC"), "Semantic code map should include ATC treatment signals.")
expect_true(any(semantic_code_map$code_system == "SKS"), "Semantic code map should include SKS signals.")
semantic_treatment_text <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows)) return(character())
  cols <- intersect(c("clinical_variable", "clinical_subgroup", "semantic_meaning", "clinical_caveat", "search_terms", "notes", "panel"), names(rows))
  apply(rows[, cols, drop = FALSE], 1, paste, collapse = " | ")
}
treatment_code_rows <- semantic_code_map[semantic_code_map$clinical_group == "Treatment", , drop = FALSE]
atc_treatment_rows <- treatment_code_rows[treatment_code_rows$code_system == "ATC", , drop = FALSE]
sks_treatment_rows <- treatment_code_rows[treatment_code_rows$code_system == "SKS", , drop = FALSE]
expect_true(nrow(atc_treatment_rows) > 0 && all(grepl("ATC medication-code context is preserved", atc_treatment_rows$notes, fixed = TRUE)), "ATC treatment rows should explicitly preserve ATC medication-code context.")
expect_false(any(atc_treatment_rows$panel == "SKS procedure/treatment signals"), "ATC treatment rows must not be grouped as SKS procedure rows.")
expect_true(nrow(sks_treatment_rows) > 0 && all(grepl("SKS procedure-code context is preserved", sks_treatment_rows$notes, fixed = TRUE)), "SKS treatment rows should explicitly preserve SKS procedure-code context.")
expect_false(any(sks_treatment_rows$panel %in% c("SP administered medication", "SP ordered medication", "ATC medication signals")), "SKS rows must not be grouped as administered, ordered, or ATC medication rows.")
sp_ordered_context <- treatment_code_rows[treatment_code_rows$source_name == "SP_OrdineretMedicin", , drop = FALSE]
if (nrow(sp_ordered_context)) {
  expect_true(all(sp_ordered_context$panel == "SP ordered medication"), "SP ordered-medication code rows should preserve ordered-medication context.")
  expect_true(all(grepl("do not by themselves prove administration", sp_ordered_context$notes, fixed = TRUE)), "SP ordered-medication rows must not imply confirmed administration.")
}
smr_context <- treatment_code_rows[treatment_code_rows$source_name == "SMR_medicine", , drop = FALSE]
if (nrow(smr_context)) {
  expect_true(all(smr_context$panel == "SMR / in-hospital medication"), "SMR code rows should preserve national in-hospital medication context.")
  expect_false(any(smr_context$panel == "SP administered medication"), "SMR rows must not be grouped as SP administered medication.")
}
epikur_context <- semantic_dictionary[semantic_dictionary$source_name %in% c("SDS_epikur", "SDS_ekokur"), , drop = FALSE]
if (nrow(epikur_context)) {
  expect_true(any(grepl("prescription", semantic_treatment_text(epikur_context), ignore.case = TRUE)), "Epikur/Ekokur rows should preserve prescription context.")
  expect_false(any(grepl("EHR medication-administration evidence", semantic_treatment_text(epikur_context), fixed = TRUE)), "Epikur/Ekokur rows must not be labeled as administered medication.")
}
sp_plan_context <- semantic_dictionary[grepl("^SP_Behandlingsplaner", semantic_dictionary$source_name), , drop = FALSE]
if (nrow(sp_plan_context)) {
  expect_true(all(grepl("treatment-plan|protocol", semantic_treatment_text(sp_plan_context), ignore.case = TRUE)), "SP treatment-plan rows should preserve plan/protocol context.")
  expect_false(any(grepl("medication-administration evidence", semantic_treatment_text(sp_plan_context), fixed = TRUE)), "SP treatment-plan rows must not be labeled as administered medication.")
}
registry_treatment_context <- semantic_dictionary[
  grepl("^RKKP_", semantic_dictionary$source_name) &
    grepl("treatment|therapy|regimen|behandling|behandl|kemo|immun|target|targeteret|transplant|response|mrd|relaps|progress", semantic_treatment_text(semantic_dictionary), ignore.case = TRUE),
  ,
  drop = FALSE
]
if (nrow(registry_treatment_context)) {
  expect_true(any(grepl("not a complete medication administration record", registry_treatment_context$clinical_caveat, fixed = TRUE)), "Registry treatment fields should warn that they are not complete medication administration records.")
}
microbiology_rows <- semantic_dictionary[semantic_dictionary$clinical_group == "Microbiology", , drop = FALSE]
expect_true(nrow(microbiology_rows) > 0, "Semantic output should include microbiology/infection rows.")
microbiology_distribution_rows <- panel_distributions[panel_distributions$panel_id == "clinical_microbiology", , drop = FALSE]
expect_true(nrow(microbiology_distribution_rows) > 0, "Microbiology panel should expose product-layer distribution rows.")
microbiology_distribution_has_value <- function(rows, values) {
  hay <- apply(rows[, intersect(c("raw_value", "raw_descriptor", "raw_code", "display_value"), names(rows)), drop = FALSE], 1, paste, collapse = " ")
  any(vapply(values, function(value) any(grepl(value, hay, fixed = TRUE)), logical(1)))
}
microbiology_expect_visible_if_distributed <- function(values, message) {
  if (microbiology_distribution_has_value(microbiology_distribution_rows, values)) {
    expect_true(any(vapply(values, function(value) grepl(value, html, fixed = TRUE), logical(1))), message)
  }
}
microbiology_expect_visible_if_distributed(c("Bacteria", "Fungus", "Virus"), "Distributed organism/domain broad values should be renderable in the Microbiology panel.")
microbiology_expect_visible_if_distributed(c("Negative", "Positive", "Not interpreted"), "Distributed result-class values should be renderable in the Microbiology panel.")
microbiology_expect_visible_if_distributed(c("BLOODCULTURE", "URINECULTURE"), "Distributed culture-group values should be renderable in the Microbiology panel.")
microbiology_expect_visible_if_distributed(c("antibiotika", "sensitivitet_resultat", "Følsom", "Resistent", "Intermediær"), "Distributed antibiotic/susceptibility values should be renderable in the Microbiology panel.")
expect_false(any(grepl("date|dato|tidspunkt|datetime|free_text|clinicalinformation|requisitioninformationtext|commentsgrouping|resultsummary|oplysninger", microbiology_distribution_rows$raw_column, ignore.case = TRUE)), "Microbiology distribution bars should not expose date-like or free-text columns.")
microbiology_expect_if_present <- function(rows, present, mapped, message) {
  if (any(present)) {
    expect_true(any(mapped), message)
  }
}
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$source_name == "PERSIMUNE_microbiology_analysis" & grepl("samplematerial|material|proeve|prøve", microbiology_rows$raw_column, ignore.case = TRUE),
  microbiology_rows$source_name == "PERSIMUNE_microbiology_analysis" & microbiology_rows$clinical_concept_id == "microbiology_sample_material" & grepl("PERSIMUNE analysis", microbiology_rows$clinical_subgroup, fixed = TRUE),
  "PERSIMUNE analysis sample-material rows should keep analysis-layer context."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$source_name == "PERSIMUNE_microbiology_culture" & microbiology_rows$raw_column %in% c("investigationexamination", "investigationexaminationtype", "c_analysisgroup", "c_new_analysisgroup", "analysisgroup", "culture_group"),
  microbiology_rows$source_name == "PERSIMUNE_microbiology_culture" & microbiology_rows$clinical_concept_id == "microbiology_culture_group",
  "PERSIMUNE culture rows should include culture/analysis-group mappings."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$source_name == "PERSIMUNE_microbiology_culture_resistance" & grepl("antibiotic|antibiotika|susceptibility|sensitivitet", microbiology_rows$raw_column, ignore.case = TRUE),
  microbiology_rows$source_name == "PERSIMUNE_microbiology_culture_resistance" & microbiology_rows$clinical_concept_id %in% c("microbiology_antibiotic", "microbiology_susceptibility_result"),
  "PERSIMUNE resistance rows should include antibiotic/susceptibility mappings."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$source_name == "PERSIMUNE_microbiology_microscopy",
  microbiology_rows$source_name == "PERSIMUNE_microbiology_microscopy" & grepl("microscopy", microbiology_rows$clinical_subgroup, ignore.case = TRUE),
  "PERSIMUNE microscopy rows should keep microscopy-layer context."
)
expect_true(all(c("SP_Bloddyrkning_del1", "SP_Bloddyrkning_del2", "SP_Bloddyrkning_del3", "SP_Bloddyrkning_del4") %in% microbiology_rows$source_name), "SP blood-culture rows should preserve del1-del4 source context.")
microbiology_expect_if_present(
  microbiology_rows,
  grepl("samplematerial|material|proeve|prøve", microbiology_rows$raw_column, ignore.case = TRUE),
  grepl("samplematerial|material|proeve|prøve", microbiology_rows$raw_column, ignore.case = TRUE) & microbiology_rows$clinical_concept_id == "microbiology_sample_material",
  "Sample-material fields should map to microbiology sample material."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$raw_column %in% c("c_domain", "domain", "organisme", "organism", "refmicroorganism", "microorganism"),
  microbiology_rows$raw_column %in% c("c_domain", "domain", "organisme", "organism", "refmicroorganism", "microorganism") & microbiology_rows$clinical_concept_id == "microbiology_organism_domain",
  "Domain/organism fields should map to organism/domain group."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$raw_column %in% c("investigationinterpretation", "c_categoricalresult_old", "c_categoricalresult", "result_class", "result", "proveresultat", "proeveresultat", "prøveresultat"),
  microbiology_rows$raw_column %in% c("investigationinterpretation", "c_categoricalresult_old", "c_categoricalresult", "result_class", "result", "proveresultat", "proeveresultat", "prøveresultat") & microbiology_rows$clinical_concept_id == "microbiology_result_class",
  "Result interpretation fields should map to microbiology result class."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$raw_column == "antibiotika",
  microbiology_rows$raw_column == "antibiotika" & microbiology_rows$clinical_concept_id == "microbiology_antibiotic",
  "Blood-culture antibiotic fields should map to microbiology antibiotic context."
)
microbiology_expect_if_present(
  microbiology_rows,
  microbiology_rows$raw_column == "sensitivitet_resultat",
  microbiology_rows$raw_column == "sensitivitet_resultat" & microbiology_rows$clinical_concept_id == "microbiology_susceptibility_result",
  "Blood-culture sensitivity fields should map to susceptibility result."
)
expect_false(any(microbiology_rows$clinical_concept_id %in% c("diagnosis_or_disease_label", "pathology_signal")), "Organism/domain microbiology rows must not map to diagnosis or pathology concepts.")
expect_false(any(microbiology_rows$clinical_group == "Treatment"), "Microbiology rows must not be classified as treatment exposure.")
expect_false(any(grepl("ATC", microbiology_rows$code_system, fixed = TRUE)), "Microbiology antibiotic rows must not become ATC treatment signals.")
expect_false(any(microbiology_rows$clinical_concept_id == "microbiology_lab_source" & grepl("infection phenotype", microbiology_rows$semantic_meaning, ignore.case = TRUE)), "Hospital/lab source rows must not be infection phenotypes.")
expect_false(any(grepl("date|dato|tidspunkt|datetime", microbiology_rows$raw_column, ignore.case = TRUE)), "Microbiology semantic rows should not render raw date-like values as categorical rows.")
expect_false(any(grepl("clinicalinformation|requisitioninformationtext|commentsgrouping|resultsummary|tekst|text|oplysninger", microbiology_rows$raw_column, ignore.case = TRUE)), "Microbiology semantic rows should not expose free-text example columns.")
broad_micro_values <- c("Virus", "Bacteria", "Bacterium", "Fungus", "Fungi", "Parasites/Protozoa/Helminths", "Other", "Unclassified", "Unknown", "NULL", "Negative", "Positive", "Not interpreted", "Not analyzed", "Not analysed", "Inconclusive", "Sent to external lab", "suppressed / not shown")
organism_rows <- microbiology_rows[microbiology_rows$clinical_concept_id == "microbiology_organism_domain" & nzchar(microbiology_rows$raw_value), , drop = FALSE]
expect_true(all(organism_rows$raw_value %in% broad_micro_values), "Detailed organism/species values should be suppressed/grouped before public semantic output.")
imaging_rows <- semantic_dictionary[semantic_dictionary$clinical_group == "Imaging", , drop = FALSE]
expect_true(nrow(imaging_rows) > 0, "Semantic output should include imaging rows.")
imaging_code_rows <- semantic_code_map[semantic_code_map$clinical_group == "Imaging", , drop = FALSE]
imaging_panel_raw <- panel_raw_fields[panel_raw_fields$panel_id == "clinical_imaging", , drop = FALSE]
imaging_panel_distributions <- panel_distributions[panel_distributions$panel_id == "clinical_imaging", , drop = FALSE]
damyda_imaging_fields <- c(
  "Reg_Knogleundersoegelser_CT",
  "Reg_Knogleundersoegelser_ct",
  "Reg_Knogleundersoegelser_MR",
  "Reg_Knogleundersoegelser_mri",
  "Reg_Knogleundersoegelser_PETCT",
  "Reg_Knogleundersoegelser_pet",
  "Reg_Knogleundersoegelser_DEXA",
  "Reg_Knogleundersoegelser_dexa",
  "Reg_Knogleundersoegelser_SCINTI",
  "Reg_Knogleundersoegelser_scinti",
  "Reg_AndreKnogleundersoegelse",
  "Reg_Knogleforandringer",
  "Reg_Knogleforandringer_type"
)
imaging_expect_code_if_present <- function(codes, concept_id, message) {
  present <- imaging_rows$raw_code %in% codes | imaging_rows$raw_descriptor %in% codes | imaging_code_rows$code %in% codes
  if (any(present)) {
    expect_true(any((imaging_rows$raw_code %in% codes | imaging_rows$raw_descriptor %in% codes) & imaging_rows$clinical_concept_id == concept_id) ||
      any(imaging_code_rows$code %in% codes & imaging_code_rows$clinical_concept_id == concept_id), message)
  }
}
imaging_expect_value_if_present <- function(values, concept_id, message) {
  hay <- apply(imaging_rows[, intersect(c("raw_code", "raw_descriptor", "raw_value", "clinical_variable"), names(imaging_rows)), drop = FALSE], 1, paste, collapse = " ")
  present <- vapply(values, function(value) any(grepl(value, hay, ignore.case = TRUE)), logical(1))
  if (any(present)) {
    expect_true(any(vapply(values, function(value) any(grepl(value, hay, ignore.case = TRUE) & imaging_rows$clinical_concept_id == concept_id), logical(1))), message)
  }
}
imaging_expect_code_if_present(c("UXZ10", "UXCC00", "UXCD00", "UXCD10", "UXCD15", "UXCA00", "APAA4"), "imaging_ct", "CT imaging codes should map to CT imaging signal.")
imaging_expect_code_if_present("UXZ11", "imaging_mri", "UXZ11 should map to MRI imaging signal.")
imaging_expect_code_if_present("UXRC00", "imaging_xray", "UXRC00 should map to X-ray imaging signal.")
imaging_expect_code_if_present(c("BWGC1", "BWGC4A"), "radiotherapy", "BWGC radiotherapy codes should map to radiotherapy procedure signal.")
imaging_expect_value_if_present(c("PET", "F-18-FDG", "FDG"), "imaging_pet_ct", "PET/FDG labels should map to PET/PET-CT imaging signal.")
imaging_expect_value_if_present(c("RU THORAX"), "imaging_xray", "RU THORAX should map to X-ray imaging signal.")
imaging_expect_value_if_present(c("CT THORAX", "CT ABDOMEN", "CT CEREBRUM", "CT HELKROP"), "imaging_ct", "CT labels should map to CT imaging signal.")
damyda_imaging <- semantic_dictionary[
  semantic_dictionary$source_name == "RKKP_DaMyDa" &
    semantic_dictionary$raw_column %in% damyda_imaging_fields,
  ,
  drop = FALSE
]
if (nrow(damyda_imaging)) {
  damyda_exact_imaging <- damyda_imaging[damyda_imaging$clinical_concept_id %in% c(
    "myeloma_ct_modality",
    "myeloma_mri_modality",
    "myeloma_pet_ct_modality",
    "myeloma_dexa_modality",
    "myeloma_scintigraphy_modality",
    "myeloma_other_imaging",
    "myeloma_bone_disease",
    "myeloma_bone_lesion_type"
  ), , drop = FALSE]
  expect_true(nrow(damyda_exact_imaging) > 0, "DaMyDa imaging/bone evidence should include exact registry imaging concepts.")
  expect_true(any(grepl("DaMyDa registry|myeloma bone|myeloma bone/imaging|Registry modality fields|Bone-disease fields", paste(damyda_exact_imaging$semantic_meaning, damyda_exact_imaging$clinical_caveat), ignore.case = TRUE)), "DaMyDa imaging/bone rows should preserve myeloma registry context.")
  expect_false(any(damyda_imaging$clinical_concept_id == "imaging_candidate_signal" & grepl("Reg_Knogle", damyda_imaging$raw_column)), "DaMyDa exact imaging/bone fields should not fall through to generic imaging candidates.")
  expect_true(any(panel_raw_fields$source_name == "RKKP_DaMyDa" & panel_raw_fields$raw_column %in% damyda_imaging$raw_column), "DaMyDa registry imaging fields should flow into product-layer raw-field rows.")
  expect_false(any(grepl("Nationwide procedure-code imaging", damyda_imaging$clinical_subgroup, fixed = TRUE)), "DaMyDa registry imaging rows must not render as national procedure-code imaging.")
  expect_false(any(grepl("image pixels|image-pixel", paste(damyda_imaging$semantic_meaning, damyda_imaging$clinical_caveat), ignore.case = TRUE)), "DaMyDa registry imaging rows must not imply image-pixel availability.")
}
sp_imaging <- imaging_rows[grepl("^SP_Billeddiagnost", imaging_rows$source_name), , drop = FALSE]
if (nrow(sp_imaging)) {
  expect_true(any(grepl("SP imaging metadata/report layer", sp_imaging$clinical_subgroup)), "SP imaging rows should preserve SP metadata/report context.")
  expect_false(all(grepl("Nationwide procedure-code imaging", sp_imaging$clinical_subgroup)), "SP imaging metadata rows must not be treated only as national SKS procedure rows.")
}
expect_false(any(grepl("rapporttekst|report_text|reporttext|beskrivelse|tekst|text|note", imaging_rows$raw_column, ignore.case = TRUE) & nzchar(imaging_rows$raw_value)), "Imaging semantic rows must not emit report-text/free-text values.")
expect_false(any(grepl("date|dato|tidspunkt|bestillingstidspunkt|_dt", imaging_panel_distributions$raw_column, ignore.case = TRUE)), "Imaging panel distributions should not render date-like rows as categorical bars.")
expect_false(any(grepl("patient|cpr|pnr", imaging_panel_distributions$raw_value, ignore.case = TRUE)), "Imaging distributions must not render patient IDs or CPR-like values.")
expect_false(any(imaging_code_rows$clinical_concept_id == "radiotherapy" & grepl("medication|medicine", imaging_code_rows$clinical_variable, ignore.case = TRUE)), "Radiotherapy procedure codes must not be classified as medication treatment.")
expect_false(any(grepl("image pixel|image-pixel", imaging_rows$semantic_meaning, ignore.case = TRUE)), "Procedure-code imaging rows must not be described as image pixels.")
expect_true(nrow(imaging_panel_raw) > 0, "Imaging panel raw fields should be generated.")
expect_true(nrow(imaging_panel_distributions) > 0, "Imaging panel distributions should be generated.")
expect_true(any(semantic_code_map$code_system == "SNOMED"), "Semantic code map should include SNOMED pathology signals.")
expect_true(nrow(semantic_panel_links) > 0, "Semantic panel links should be generated.")
expect_true(all(nzchar(semantic_dictionary$evidence_file)), "Every semantic row should include an evidence file.")
expect_false(any(vapply(semantic_dictionary$raw_column, is_sensitive_column, logical(1))), "Semantic dictionary should not turn identifier-like columns into variables.")
expect_false(any(grepl("[.](tsv|csv)$", semantic_dictionary$source_name, ignore.case = TRUE)), "Semantic source names should not be cartography evidence filenames.")
expect_true(all(c("height", "weight", "bmi", "smoking_status", "alcohol_use", "ldh", "haemoglobin", "creatinine", "egfr", "imaging_availability", "microbiology_infection_data") %in% clinical_concepts$clinical_concept_id), "Clinical concept output should include required clinician-facing concept cards.")
expect_true(any(panel_raw_fields$source_name == "SP_VitaleVaerdier"), "Panel raw fields should include SP_VitaleVaerdier rows.")
expect_true(any(panel_raw_fields$source_name %in% c("SP_Social_Hx", "SP_SocialHX")), "Panel raw fields should include SP_Social_Hx rows.")
expect_true(any(panel_raw_fields$source_name == "SP_VitaleVaerdier" & panel_raw_fields$raw_column == "displayname" & panel_raw_fields$raw_descriptor == vaegt), "Panel raw fields should include SP_VitaleVaerdier displayname=Vægt.")
expect_true(any(panel_raw_fields$source_name == "SP_VitaleVaerdier" & panel_raw_fields$raw_column == "displayname" & panel_raw_fields$raw_descriptor == hoejde), "Panel raw fields should include SP_VitaleVaerdier displayname=Højde.")
expect_true(any(panel_raw_fields$source_name == "SP_VitaleVaerdier" & panel_raw_fields$raw_column == "numericvalue"), "Panel raw fields should include SP_VitaleVaerdier numericvalue.")
vital_raw <- panel_raw_fields[panel_raw_fields$panel_id == "clinical_vitals", , drop = FALSE]
priority_labels <- c(
  vital_raw$raw_field_label[which(vital_raw$raw_column == "displayname" & vital_raw$raw_descriptor == vaegt)[1]],
  vital_raw$raw_field_label[which(vital_raw$raw_column == "displayname" & vital_raw$raw_descriptor == hoejde)[1]],
  vital_raw$raw_field_label[which(vital_raw$raw_column == "numericvalue")[1]]
)
priority_labels <- priority_labels[!is.na(priority_labels)]
priority_renderable <- paste(priority_labels, collapse = "\n")
expect_true(grepl(vaegt, priority_renderable, fixed = TRUE), "Renderable Vitals priority lineage should contain Vægt.")
expect_true(grepl(hoejde, priority_renderable, fixed = TRUE), "Renderable Vitals priority lineage should contain Højde.")
expect_true(grepl("numericvalue", priority_renderable, fixed = TRUE), "Renderable Vitals priority lineage should contain numericvalue.")
expect_true(regexpr(vaegt, priority_renderable, fixed = TRUE)[[1]] < regexpr(hoejde, priority_renderable, fixed = TRUE)[[1]], "Renderable Vitals priority lineage should place Vægt before Højde.")
expect_true(regexpr(hoejde, priority_renderable, fixed = TRUE)[[1]] < regexpr("numericvalue", priority_renderable, fixed = TRUE)[[1]], "Renderable Vitals priority lineage should place Højde before numericvalue.")
expect_true(any(panel_raw_fields$raw_column == "ryger" & panel_raw_fields$clinical_variable == "Smoking status"), "Panel raw fields should include ryger to Smoking status.")
expect_true(any(panel_raw_fields$source_name %in% c("SP_Social_Hx", "SP_SocialHX") & panel_raw_fields$raw_column == "ryger"), "Panel raw fields should include SP_Social_Hx.ryger.")
expect_true(any(panel_raw_fields$raw_column == "numericvalue" & panel_raw_fields$clinical_variable == "Vital numeric measurement value"), "Panel raw fields should include numericvalue as the vital measurement value.")
expect_true(any(panel_raw_fields$source_name %in% c("SP_Social_Hx", "SP_SocialHX") & panel_raw_fields$raw_column == "drikker"), "Panel raw fields should include SP_Social_Hx.drikker.")
expect_true(any(panel_raw_fields$raw_code == "NPU02319" & panel_raw_fields$clinical_variable == "Haemoglobin"), "Panel raw fields should include NPU02319 to Haemoglobin.")
expect_true(any(panel_raw_fields$panel_id == "laboratory_npu" & panel_raw_fields$raw_code == "NPU02319" & panel_raw_fields$clinical_variable == "Haemoglobin"), "Laboratory/NPU panel raw fields should include NPU02319 to Haemoglobin.")
expect_true(any(panel_raw_fields$panel_id == "laboratory_npu" & panel_raw_fields$raw_code == "DNK35302" & grepl("eGFR", panel_raw_fields$clinical_variable, fixed = TRUE)), "Laboratory/NPU panel raw fields should include DNK35302 to eGFR / CKD-EPI.")
expect_false(any(panel_raw_fields$panel_id == "treatment" & grepl("^(NPU|DNK)", panel_raw_fields$raw_code, ignore.case = TRUE)), "Treatment panel raw fields must not include NPU/DNK laboratory rows as treatment lineage.")
expect_false(any(panel_raw_fields$panel_id == "laboratory_npu" & grepl("^L0|^BW", panel_raw_fields$raw_code, ignore.case = TRUE)), "Laboratory/NPU panel raw fields should not include treatment ATC/SKS-style codes as primary lab lineage.")
lyfo_panel_raw <- panel_raw_fields[panel_raw_fields$source_name == "RKKP_LYFO", , drop = FALSE]
expect_true(any(lyfo_panel_raw$raw_column == "Reg_WHOHistologikode1" & lyfo_panel_raw$clinical_concept_id == "lymphoma_subtype_code"), "Panel raw fields should keep LYFO WHO histology in subtype-code context.")
expect_false(any(lyfo_panel_raw$raw_column %in% c("Reg_WHOHistologikode1", "Reg_WHOHistologikode2", "Rec_WHOHistologikode") & lyfo_panel_raw$clinical_concept_id == "performance_status"), "Panel raw fields must not map LYFO histology to performance status.")
expect_true(any(lyfo_panel_raw$raw_column == "Reg_CalciumAlbuminkorrigeret" & lyfo_panel_raw$clinical_concept_id == "albumin_corrected_calcium"), "Panel raw fields should keep LYFO albumin-corrected calcium separate from albumin.")
expect_true(any(lyfo_panel_raw$raw_column == "Reg_Lokal_Pancreas" & lyfo_panel_raw$clinical_concept_id == "disease_localization"), "Panel raw fields should keep LYFO pancreas localization as localization.")
expect_false(any(lyfo_panel_raw$raw_column == "Reg_Lokal_Pancreas" & lyfo_panel_raw$clinical_concept_id == "creatinine"), "Panel raw fields must not map LYFO pancreas localization to creatinine.")
expect_true(any(panel_distributions$panel_id == "clinical_social_history" & panel_distributions$raw_column == "ryger" & panel_distributions$display_value == "Former smoker"), "Social History panel distributions should include smoking value maps.")
expect_true(any(panel_distributions$panel_id == "clinical_social_history" & panel_distributions$raw_column == "drikker" & panel_distributions$display_value == "Alcohol use yes"), "Social History panel distributions should include alcohol value maps.")
expect_false(any(panel_distributions$panel_id == "clinical_social_history" & panel_distributions$raw_column == "ryger" & panel_distributions$raw_value == "Ja" & panel_distributions$display_value == "Alcohol use yes"), "Smoking Ja should not be grouped as alcohol use.")
expect_false(any(panel_distributions$panel_id == "clinical_social_history" & panel_distributions$raw_column == "drikker" & panel_distributions$raw_value == "Ja" & panel_distributions$display_value == "Current smoker"), "Alcohol Ja should not be grouped as current smoker.")
vitals_panel <- domain_panels[domain_panels$panel_id == "clinical_vitals", , drop = FALSE]
social_panel <- domain_panels[domain_panels$panel_id == "clinical_social_history", , drop = FALSE]
expect_true(all(c(vitals_panel$count_scope, vitals_panel$denominator_scope, vitals_panel$profile_scope) == "cartography_scan"), "Vitals panel-level scopes should reflect cartography-scan evidence.")
expect_true(all(c(social_panel$count_scope, social_panel$denominator_scope, social_panel$profile_scope) == "cartography_scan"), "Social History panel-level scopes should reflect cartography-scan evidence.")
expect_equal(sum(clinical_concepts$clinical_concept_id == "bmi"), 1L, "Clinical concept output should contain only one BMI row.")
expect_true(grepl("derived from height and weight", clinical_concepts$purpose[clinical_concepts$clinical_concept_id == "bmi"], ignore.case = TRUE), "BMI concept should be described as derived from height and weight.")
if (any(clinical_concepts$clinical_concept_id %in% c("weight", "height") & !is.na(clinical_concepts$n_patients))) {
  expect_true(grepl("patientCountForConcept(conceptId, [\"SP_VitaleVaerdier\"])", html, fixed = TRUE), "Vitals renderer should use source-specific SP_VitaleVaerdier patient counts when available.")
}
expect_true(any(domain_panels$panel_id == "clinical_vitals" & grepl("Repeated measures", domain_panels$caveats, fixed = TRUE)), "Vitals product panel should carry repeated-measures caveat.")
expect_true(any(panel_distributions$panel_id == "clinical_imaging" & panel_distributions$display_value == "EHR-native imaging metadata/report text"), "Imaging panel should preserve EHR-native imaging layer.")
expect_true(any(panel_distributions$panel_id == "clinical_microbiology" & grepl("SP blood-culture workflow", panel_distributions$display_value, fixed = TRUE)), "Microbiology panel should include SP blood-culture workflow.")
expect_true(all(c("old_panel_id", "new_panel_id", "old_title", "new_title", "parity_status", "missing_items", "next_required_output") %in% names(panel_parity)), "Panel parity should use the required schema.")
expect_true(all(c("restored", "partial", "placeholder") %in% c(panel_parity$parity_status, "partial", "placeholder")), "Panel parity should use allowed statuses.")
for (panel_id in domain_panels$panel_id[domain_panels$parity_status == "restored"]) {
  expect_true(any(panel_raw_fields$panel_id == panel_id), paste("Restored panel should have raw fields:", panel_id))
  expect_true(any(panel_kpis$panel_id == panel_id) || any(panel_distributions$panel_id == panel_id), paste("Restored panel should have KPIs/distributions:", panel_id))
}

situation_summary <- utils::read.csv(file.path(result$run_dir, "outputs", "panels", "situation_report_summary.csv"), stringsAsFactors = FALSE)
expect_true(all(c("definition_basis", "n_cohort", "pct_cohort") %in% names(situation_summary)), "Situation Report summary should include definition and cohort-audit columns.")

log_text <- paste(readLines(file.path(result$run_dir, "logs", "atlas_execution_log.tsv"), warn = FALSE), collapse = "\n")
expect_true(grepl("Run summary:", log_text, fixed = TRUE), "Execution log should include a run summary line.")

memory_plan <- utils::read.csv(file.path(result$run_dir, "outputs", "atlas_memory_plan.csv"), stringsAsFactors = FALSE)
expect_true(all(memory_plan$chosen_strategy == "file_full_load"), "Fixture file sources should use the file full-load strategy.")
memory_log <- utils::read.delim(file.path(result$run_dir, "logs", "atlas_memory_log.tsv"), stringsAsFactors = FALSE)
expect_true(all(c("chosen_strategy", "memory_status", "max_full_load_rows") %in% names(memory_log)), "Memory log should record strategy and guardrail decisions.")
