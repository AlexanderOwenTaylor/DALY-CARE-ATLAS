root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

top_values <- data.frame(
  table_name = c(rep("t_dalycare_diagnoses", 5), rep("SDS_pato", 4)),
  column_name = c(rep("diagnosis_code", 5), rep("c_snomedkode", 4)),
  value = c("DC911", "DD479B", "DD472", "DD472B", "DC900", "M95911", "M96121", "M98231", "M98233"),
  n = c(12831, 193, 4840, 22, 29472, 2, 6, 8, 66458),
  pct_rows = c(10, 1, 4, 0.1, 20, 0.01, 0.02, 0.03, 2),
  stringsAsFactors = FALSE
)

outputs <- build_confluence_feasibility_outputs(
  project_root = root,
  sources = data.frame(
    table_name = c("RKKP_CLL", "RKKP_DaMyDa", "PERSIMUNE_Microbiology", "SP_BloodCulture"),
    domain = c("RKKP", "RKKP", "Laboratory", "SP"),
    subdomain = c("CLL", "DaMyDa", "Microbiology", "Blood culture"),
    atlas_role = c("clinical_registry", "clinical_registry", "microbiology", "blood_culture"),
    load_status = "ok",
    source_type = "file",
    source = "",
    n_rows = c(7884, 100, 100, 100),
    n_cols = c(80, 20, 10, 10),
    stringsAsFactors = FALSE
  ),
  column_top_values = top_values,
  panels = list(
    microbiology = data.frame(panel = "microbiology blood culture resistance infection", stringsAsFactors = FALSE),
    treatment = data.frame(panel = "ibrutinib venetoclax rituximab bortezomib lenalidomide daratumumab ASCT", stringsAsFactors = FALSE)
  )
)

expect_true(all(c(
  "summary",
  "clone_route_manifest",
  "clone_source_resolution",
  "bcell_clone_evidence_counts",
  "pcd_clone_evidence_counts",
  "paraprotein_ambiguity_counts",
  "mgus_reclassification_waterfall",
  "dual_clone_overlap_counts",
  "dual_clone_overlap_timing",
  "primary_overlap_exclusion_reasons",
  "clone_availability_protocol_runway",
  "story_cards",
  "evidence_spine",
  "overlap_signal_summary",
  "ingredient_map",
  "protocol_runway",
  "disease_state_counts",
  "overlap_counts",
  "overlap_timing",
  "infection_outcome_readiness",
  "treatment_modifier_readiness",
  "estimands",
  "validation_checklist",
  "bias_warnings",
  "recommended_next_actions",
  "code_sets",
  "mbl_source_counts",
  "mgus_source_counts",
  "candidate_first_date_summary",
  "overlap_counts_accepted",
  "overlap_timing_accepted",
  "mbl_validation_waterfall",
  "mgus_validation_waterfall",
  "dual_clone_validation_waterfall",
  "small_cell_suppression_audit",
  "utf8_quality_audit",
  "infection_endpoint_definitions",
  "disease_state_person_counts",
  "first_date_availability",
  "infection_endpoint_code_sets",
  "infection_counts",
  "recurrent_infection_counts",
  "infection_person_time",
  "infection_rates",
  "microbiology_confirmation_counts",
  "microbiology_confirmation_source_audit",
  "production_query_review",
  "failed_query_audit",
  "source_resolution_audit",
  "production_execution_summary"
) %in% names(outputs)), "CONFLUENCE output should expose every requested table.")

for (table_name in c("story_cards", "evidence_spine", "overlap_signal_summary", "ingredient_map", "protocol_runway")) {
  expect_true(is.data.frame(outputs[[table_name]]), paste("CONFLUENCE should expose story table:", table_name))
}
expect_true(all(c(
  "overlap_identifiable",
  "denominator_separated",
  "mgus_candidate_gate",
  "ambiguity_hierarchy",
  "overlap_clock_defined",
  "infection_two_routes",
  "person_time_under_signal",
  "bias_controls_named",
  "completed_aggregate_checks",
  "next_protocol_moves"
) %in% outputs$story_cards$card_id), "Story cards should cover overlap, clone denominators, ambiguity gates, clock, infection routes, person-time, bias, completed checks, and protocol moves.")
overlap_story <- outputs$story_cards[outputs$story_cards$card_id == "overlap_identifiable", , drop = FALSE]
expect_equal(nrow(overlap_story), 1L, "Story cards should have one primary overlap status card.")
expect_false(identical(overlap_story$headline[[1]], "Accepted dual-clone cohort is identifiable"), "Scaffold story copy must not overclaim that the accepted primary cohort is identifiable.")
expect_true(overlap_story$evidence_status[[1]] %in% c("accepted route failed closed", "candidate/ambiguous mapping only", "source validation required"), "Scaffold story status should distinguish failed-closed, candidate/ambiguous-only, or validation-required states.")
expect_true(any(outputs$story_cards$headline == "Clone-evidence denominators are separated from diagnosis anchors"), "Story cards should use clinician-facing clone denominator copy.")
expect_true(any(grepl("MGUS diagnosis-code overlap is a candidate signal, not accepted evidence", paste(outputs$story_cards$submetric_display, outputs$story_cards$interpretation), fixed = TRUE)), "Story cards should keep the MGUS candidate-only gate visible.")
expect_true(any(grepl("Aggregate feasibility only; not causal", outputs$story_cards$caveat, fixed = TRUE)), "Story cards should keep feasibility-only/not-causal caveats visible.")
expect_true(any(grepl("provisional", paste(outputs$story_cards$caveat, outputs$story_cards$evidence_status), ignore.case = TRUE)), "Story cards should keep provisional endpoint language visible.")
expect_true(any(outputs$evidence_spine$spine_id == "overlap_entry_date"), "Evidence spine should include overlap entry timing.")
expect_true(any(outputs$evidence_spine$spine_id == "microbiology_confirmed_endpoint"), "Evidence spine should include microbiology confirmation.")
expect_true(all(c("cll_mbl_axis", "pcd_axis", "route_manifest_gate", "ambiguity_hierarchy", "hospital_serious_infection", "microbiology_confirmation", "treatment_modifiers", "death_followup_censoring", "source_resolution_fail_closed", "small_cell_suppression") %in% outputs$ingredient_map$ingredient_id), "Ingredient map should include clone axes, route validation, ambiguity hierarchy, infection, microbiology, treatment, censoring, source-resolution, and privacy rows.")
expect_true(all(c("mbl_validation", "mgus_validation", "smm_definition", "infection_endpoint_ownership", "microbiology_roles", "treatment_timing", "testing_intensity", "death_progression", "small_cell_precheck") %in% outputs$protocol_runway$runway_id), "Protocol runway should include the expected hardening workstreams.")
expect_true(all(c("route_manifest", "snomed_validation_gate", "ambiguity_hierarchy") %in% outputs$clone_availability_protocol_runway$runway_id), "Clone protocol runway should include route manifest, pathology validation, and ambiguity hardening workstreams.")
expect_true(nrow(outputs$overlap_signal_summary) == 0L, "Scaffold-only overlap signal summary should stay empty when accepted production rows are missing.")

disease <- outputs$disease_state_counts
mbl <- disease[disease$entity_id == "mbl_candidate", , drop = FALSE]
mgus <- disease[disease$entity_id == "mgus_candidate", , drop = FALSE]
cll <- disease[disease$entity_id == "cll_candidate", , drop = FALSE]
mm <- disease[disease$entity_id == "mm_candidate", , drop = FALSE]

expect_equal(nrow(mbl), 1L, "MBL anchor should exist.")
expect_true(identical(mbl$danish_sks_code[[1]], "DD479B"), "MBL should use DD479B.")
expect_true(identical(mbl$icd10_code[[1]], "D47.9B"), "MBL should use D47.9B.")
expect_true(grepl("coded candidate cohort", mbl$evidence_status[[1]], fixed = TRUE), "MBL should be coded-candidate evidence.")
expect_true(grepl("diagnosis-atlas records", mbl$count_kind[[1]], fixed = TRUE), "MBL should be diagnosis-atlas records.")
expect_true(grepl("not validated persons", mbl$notes[[1]], fixed = TRUE), "MBL should not be labelled validated persons.")
expect_true(identical(mbl$count_display[[1]], "193"), "MBL fixture count should render from exact code row.")

expect_true(identical(mgus$danish_sks_code[[1]], "DD472"), "MGUS should use DD472.")
expect_true(identical(mgus$icd10_code[[1]], "D47.2"), "MGUS should use D47.2.")
expect_true(grepl("coded candidate cohort", mgus$evidence_status[[1]], fixed = TRUE), "MGUS should be coded-candidate evidence.")
expect_true(identical(cll$danish_sks_code[[1]], "DC911"), "CLL should use DC911.")
expect_true(identical(cll$icd10_code[[1]], "C91.1"), "CLL should use C91.1.")
expect_true(identical(mm$danish_sks_code[[1]], "DC900"), "MM should use DC900.")
expect_true(identical(mm$icd10_code[[1]], "C90.0"), "MM should use C90.0.")

expect_true(all(outputs$overlap_counts$query_status == "query executable not run"), "Overlap rows should be not-run in scaffold-first mode.")
expect_true(all(outputs$overlap_counts$acceptance_status != "accepted"), "No overlap row should be accepted in scaffold-first mode.")
expect_true(all(outputs$overlap_counts$acceptance_status == "not accepted aggregate"), "Overlap rows should be explicitly not accepted aggregate.")
expect_true(all(outputs$overlap_timing$query_status == "query executable not run"), "Overlap timing should be not-run.")
expect_true(all(outputs$overlap_counts_accepted$acceptance_status != "accepted"), "No accepted overlap-count row should be accepted in v0.2 scaffold mode.")
expect_true(all(outputs$overlap_timing_accepted$acceptance_status != "accepted"), "No accepted overlap-timing row should be accepted in v0.2 scaffold mode.")

codes <- outputs$code_sets
for (code in c("M95911", "M96121", "M98231", "DD472", "DD472B")) {
  expect_true(any(codes$code == code), paste("CONFLUENCE code sets should include:", code))
}
m98233 <- codes[codes$code == "M98233", , drop = FALSE]
expect_equal(nrow(m98233), 1L, "M98233 should be present exactly once as an exclusion/contamination row.")
expect_true(identical(m98233$include_or_exclude[[1]], "exclude"), "M98233 should be excluded from MBL.")
expect_true(grepl("CLL morphology", m98233$concept_label[[1]], fixed = TRUE), "M98233 should be labelled CLL morphology.")
expect_false(any(codes$code == "M98233" & grepl("pathology-supported MBL", codes$validation_role, fixed = TRUE)), "M98233 must never be pathology-supported MBL.")

confluence_source <- paste(readLines(file.path(root, "R", "confluence_feasibility.R"), warn = FALSE), collapse = "\n")
expect_false(grepl("starts_with\\(\"M9823\"", confluence_source), "CONFLUENCE must not use broad starts_with(\"M9823\") SNOMED logic.")
expect_false(grepl("startsWith\\([^\\n]+M9823", confluence_source), "CONFLUENCE must not use broad M9823 prefix logic.")

mbl_sources <- outputs$mbl_source_counts
expect_true(any(mbl_sources$source_tier_id == "patobank_mbl_any" & grepl("M95911", mbl_sources$codes, fixed = TRUE)), "MBL source tiers should include exact PATOBANK MBL SNOMED codes.")
expect_true(any(mbl_sources$source_tier_id == "patobank_cll_morphology_pressure" & mbl_sources$acceptance_status == "not accepted MBL evidence"), "M98233 should render as CLL pressure, not accepted MBL evidence.")
expect_true(any(mbl_sources$source_tier_id == "patobank_mbl_non_cll_type" & mbl_sources$count_display == "<5"), "Small SNOMED rows should display as suppressed small cells.")
expect_true(any(outputs$small_cell_suppression_audit$count_display == "<5"), "Small-cell suppression audit should contain threshold display.")

mgus_sources <- outputs$mgus_source_counts
expect_true(any(grepl("DD472B", mgus_sources$codes, fixed = TRUE)), "MGUS source tiers should include DD472B.")
expect_true(any(mgus_sources$source_tier_id == "active_mm_pressure" & mgus_sources$acceptance_status == "not accepted MGUS evidence"), "Active MM pressure should not be accepted MGUS evidence.")

bad_gate <- confluence_acceptance_gate(data.frame(
  query_status = "executed",
  query_executed = "yes",
  count_kind = "distinct people",
  source_table = "",
  code_set_version = "",
  min_cell_suppression_applied = "yes",
  public_safe = "yes",
  first_date_logic = "overlap date is later of two first qualifying disease-state dates",
  immortal_time_handling_note = "immortal-time handled by overlap entry date",
  mbl_tier = "coded MBL",
  stringsAsFactors = FALSE
))
expect_false(bad_gate$accepted[[1]], "Acceptance gate should fail without source table and code-set version.")
good_gate <- confluence_acceptance_gate(data.frame(
  query_status = "executed",
  query_executed = "yes",
  count_kind = "distinct people",
  source_table = "secure_aggregate",
  code_set_version = "confluence-v0.2",
  min_cell_suppression_applied = "yes",
  public_safe = "yes",
  first_date_logic = "overlap date is later of two first qualifying disease-state dates",
  immortal_time_handling_note = "immortal-time handled by overlap entry date",
  mbl_tier = "coded MBL",
  stringsAsFactors = FALSE
))
expect_true(good_gate$accepted[[1]], "Acceptance gate should pass only when every required proof is present.")

expect_equal(nrow(outputs$estimands), 4L, "CONFLUENCE should include four estimand cards.")
expect_true(any(outputs$estimands$title == "First serious infection estimand"), "First serious infection estimand should render.")
expect_true(any(outputs$estimands$title == "Recurrent infection burden estimand"), "Recurrent infection burden estimand should render.")
expect_true(any(outputs$estimands$title == "Microbiology-confirmed infection phenotype estimand"), "Microbiology-confirmed infection phenotype estimand should render.")
expect_true(any(outputs$estimands$title == "Additive interaction / dual-clone vulnerability estimand"), "Additive interaction estimand should render.")

required_bias <- c(
  "immortal-time bias",
  "surveillance/testing bias",
  "MBL undercoding",
  "MGUS ascertainment bias",
  "treatment confounding",
  "progression/state-transition bias",
  "competing mortality",
  "small-cell suppression"
)
for (bias in required_bias) {
  expect_true(any(outputs$bias_warnings$bias_label == bias), paste("Missing bias warning:", bias))
}

tmp <- tempfile("confluence-test-")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- confluence_write_outputs(outputs, tmp)
expect_true(all(file.exists(unlist(paths))), "All CONFLUENCE output CSVs should be written.")
names(paths) <- paste0("confluence_", names(paths))
manifest <- output_manifest(paths, run_dir = tmp)
expect_true(any(grepl("confluence_disease_state_counts.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE disease-state counts.")
expect_true(any(grepl("confluence_story_cards.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE story cards.")
expect_true(any(grepl("confluence_evidence_spine.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE evidence spine.")
expect_true(any(grepl("confluence_overlap_signal_summary.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE overlap signal summary.")
expect_true(any(grepl("confluence_ingredient_map.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE ingredient map.")
expect_true(any(grepl("confluence_protocol_runway.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE protocol runway.")
expect_true(any(grepl("confluence_estimands.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE estimands.")
expect_true(any(grepl("confluence_code_sets.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE code sets.")
expect_true(any(grepl("confluence_mbl_source_counts.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE MBL source tiers.")
expect_true(any(grepl("confluence_small_cell_suppression_audit.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE suppression audit.")
expect_true(any(grepl("confluence_production_execution_summary.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE production execution summary.")
expect_true(any(grepl("confluence_source_resolution_audit.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE source-resolution audit.")
expect_true(any(grepl("confluence_microbiology_confirmation_source_audit.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE microbiology-confirmation source audit.")
expect_true(any(grepl("confluence_infection_rates.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE infection rates.")
for (clone_csv in c(
  "confluence_clone_route_manifest.csv",
  "confluence_clone_source_resolution.csv",
  "confluence_bcell_clone_evidence_counts.csv",
  "confluence_pcd_clone_evidence_counts.csv",
  "confluence_paraprotein_ambiguity_counts.csv",
  "confluence_mgus_reclassification_waterfall.csv",
  "confluence_dual_clone_overlap_counts.csv",
  "confluence_dual_clone_overlap_timing.csv",
  "confluence_primary_overlap_exclusion_reasons.csv",
  "confluence_clone_availability_protocol_runway.csv"
)) {
  expect_true(any(grepl(clone_csv, manifest$relative_path, fixed = TRUE)), paste("Manifest should include clone evidence output:", clone_csv))
}
expect_true(all(c("module", "artifact_role", "canonical_output", "production_output", "superseded_by") %in% names(manifest)), "Manifest should include artifact classification metadata.")
prod_summary <- manifest[manifest$artifact_id == "confluence_production_execution_summary", , drop = FALSE]
expect_true(nrow(prod_summary) == 1L && isTRUE(prod_summary$canonical_output[[1]]) && isTRUE(prod_summary$production_output[[1]]), "CONFLUENCE production execution summary should be marked canonical production output.")

sources <- data.frame(
  table_name = "t_dalycare_diagnoses",
  source_type = "file",
  source = "",
  domain = "SDS",
  subdomain = "Diagnoses",
  atlas_role = "diagnosis",
  profile_mode = "full",
  load_status = "ok",
  n_rows = 10,
  n_cols = 2,
  id_column_guess = "",
  min_date = "",
  max_date = "",
  stringsAsFactors = FALSE
)
columns <- data.frame(table_name = "t_dalycare_diagnoses", column_name = "diagnosis_code", column_type = "character", stringsAsFactors = FALSE)
checks <- data.frame(table_name = "", check_id = "ok", severity = "ok", message = "fixture", stringsAsFactors = FALSE)
payload <- atlas_payload(
  "confluence-test",
  "2026-05-24T00:00:00+0000",
  sources,
  columns,
  checks,
  list(),
  column_top_values = top_values,
  confluence_feasibility = outputs
)
expect_true("confluence_feasibility" %in% names(payload), "Payload should include confluence_feasibility.")
expect_true(length(payload$confluence_feasibility$estimands) == 4L, "Payload should preserve CONFLUENCE estimands.")
expect_true(length(payload$confluence_feasibility$story_cards) >= 8L, "Payload should preserve CONFLUENCE story cards.")
expect_true(length(payload$confluence_feasibility$evidence_spine) >= 10L, "Payload should preserve CONFLUENCE evidence spine.")
expect_true(length(payload$confluence_feasibility$ingredient_map) >= 10L, "Payload should preserve CONFLUENCE ingredient map.")
expect_true(length(payload$confluence_feasibility$protocol_runway) >= 9L, "Payload should preserve CONFLUENCE protocol runway.")
expect_true(length(payload$confluence_feasibility$code_sets) >= 16L, "Payload should include CONFLUENCE code sets.")
expect_true(length(payload$confluence_feasibility$mbl_source_counts) >= 6L, "Payload should include CONFLUENCE MBL source tiers.")

html <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
for (needle in c(
  "data-sub=\"mcl-triangle-feasibility\"",
  "data-sub=\"confluence-feasibility\"",
  "DALY-CARE CONFLUENCE",
  "CLL/MBL",
  "DD479B",
  "M95911",
  "M96121",
  "M98231",
  "M98233",
  "Exact-match rule",
  "MGUS",
  "query executable not run",
  "not accepted aggregate",
  "What the atlas has already assembled",
  "Question-to-evidence spine",
  "Overlap infection signal, read as feasibility only",
  "Accepted dual-clone cohort",
  "MGUS diagnosis-code overlap is a candidate signal",
  "Clone route manifest",
  "Clone evidence counts",
  "Ambiguity and exclusion cartography",
  "Data ingredients",
  "Protocol hardening path",
  "What is accepted aggregate vs still provisional",
  "function renderConfluenceFeasibilityPanel",
  "function renderConfluenceStoryHero",
  "confluence_feasibility"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("HTML/template should include:", needle))
}
for (term in c("DD479B", "M95911", "M96121", "M98231", "M98233", "MBL", "MGUS", "overlap", "Monoklonal B-celle lymfocytose", "blood culture", "CONFLUENCE")) {
  expect_true(grepl(term, html, fixed = TRUE), paste("Search/template should include CONFLUENCE term:", term))
}

all_text <- paste(unlist(outputs, recursive = TRUE, use.names = FALSE), collapse = " ")
story_text <- paste(unlist(outputs[c("story_cards", "evidence_spine", "overlap_signal_summary", "ingredient_map", "protocol_runway")], recursive = TRUE, use.names = FALSE), collapse = " ")
for (forbidden in c("p-value", "confidence interval", "hazard ratio", "adjusted risk", "causal effect", "survival curve", "model output", "raw microbiology text", "pathology narrative", "CPR")) {
  expect_false(grepl(forbidden, story_text, ignore.case = TRUE), paste("CONFLUENCE story layer must not contain forbidden analytic/raw wording:", forbidden))
}
expect_true(grepl("accepted provisional endpoint aggregate", html, fixed = TRUE), "Top CONFLUENCE story UI should distinguish provisional endpoint aggregates.")
expect_true(grepl(".join(\" \")", html, fixed = TRUE), "Badge rows should retain text fallback spacing between rendered pills.")
expect_false(grepl("Rate/100 PY: ${escapeHtml(row.rate_per_100_person_years || \"not available\")", html, fixed = TRUE), "Top overlap signal should not render unavailable rate lines as if they were metrics.")
for (stale_copy in c(
  "without new production overlap counts",
  "CONFLUENCE overlap rows are not accepted aggregates",
  "before any overlap query is accepted",
  "not-run overlap rows",
  "no production overlap queries accepted yet",
  "not accepted aggregate overlap counts"
)) {
  expect_false(grepl(stale_copy, html, fixed = TRUE), paste("CONFLUENCE static copy should not contradict accepted aggregate rows:", stale_copy))
}
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", all_text), "CONFLUENCE outputs must not contain CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", all_text), "CONFLUENCE scaffold outputs must not contain raw dates.")
expect_false(grepl("raw free text|snippet|row preview", all_text, ignore.case = TRUE), "CONFLUENCE scaffold outputs must not expose raw text/snippets/row previews.")

payload_text <- paste(capture.output(str(payload$confluence_feasibility, max.level = 4)), collapse = "\n")
for (bad in c(intToUtf8(0x00E2), intToUtf8(0xFFFD), intToUtf8(0x00C3))) {
  expect_false(grepl(bad, html, fixed = TRUE, useBytes = TRUE), "Atlas HTML must not contain mojibake markers.")
  expect_false(grepl(bad, payload_text, fixed = TRUE, useBytes = TRUE), "CONFLUENCE payload must not contain mojibake markers.")
}
expect_true(all(outputs$utf8_quality_audit$status == "pass"), "CONFLUENCE UTF-8 audit should pass.")

mockup_builder <- paste(readLines(file.path(root, "scripts", "build_atlas_mockup_from_run_zip.R"), warn = FALSE), collapse = "\n")
expect_true(grepl("$entryName = $rel -replace '\\\\\\\\','/'", mockup_builder, fixed = TRUE), "PowerShell ZIP fallback should normalize archive paths to forward slashes.")
expect_true(grepl("CreateEntryFromFile($zip, $_.FullName, $entryName", mockup_builder, fixed = TRUE), "PowerShell ZIP fallback should use the normalized archive entry name.")

cat("CONFLUENCE feasibility tests passed\n")
