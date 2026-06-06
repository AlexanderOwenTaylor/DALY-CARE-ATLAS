root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

expect_file(file.path(root, "R", "confluence_clone_evidence.R"))
expect_file(file.path(root, "config", "confluence_clone_evidence_sources.tsv"))

routes <- confluence_clone_read_sources(root)
expect_true(nrow(routes) >= 20L, "Clone evidence route config should expose route-level source rules.")
expect_true(all(c(
  "route_id", "route_family", "axis", "state_id", "evidence_tier",
  "required_columns", "local_validation_status", "usable_for_primary_overlap"
) %in% names(routes)), "Clone route config should include audit and validation columns.")
expect_true(all(!duplicated(routes$route_id)), "Clone route IDs should be stable and unique.")
expect_true(nrow(confluence_clone_lint_sources(routes)) == 0L, "Committed clone route config should pass lint.")
expect_true(any(routes$route_id == "pcd_diag_mgus_candidate" & !routes$usable_for_primary_overlap), "MGUS-code-only route must not be primary-usable.")
expect_true(any(routes$route_id == "pcd_lab_sds_mspike_igm_ambiguous" & !routes$usable_for_primary_overlap), "IgM-only ambiguity route must not be primary-usable.")
expect_true(any(routes$route_id == "pcd_pato_plasma_m97323" & routes$local_validation_status == "candidate_review" & !routes$usable_for_primary_overlap), "Plasma-cell SNOMED candidates should default away from primary use.")

bad_routes <- routes
bad_routes$usable_for_primary_overlap[bad_routes$route_id == "pcd_diag_mgus_candidate"] <- TRUE
bad_lint <- confluence_clone_lint_sources(bad_routes)
expect_true(any(bad_lint$route_id == "pcd_diag_mgus_candidate" & bad_lint$field == "usable_for_primary_overlap"), "Lint should fail primary-usable MGUS-code-only routes.")

num <- numeric_clean(c("12.5", "12,5", "<1", ">100", "neg", "Negative", "Ikke påvist", NA, ""))
expect_equal(num$numeric_value[1], 12.5, "numeric_clean should parse dot decimals.")
expect_equal(num$numeric_value[2], 12.5, "numeric_clean should parse comma decimals.")
expect_equal(num$numeric_value[3], 1, "numeric_clean should keep comparator numeric boundary.")
expect_equal(num$comparator[3], "<", "numeric_clean should retain lower-than comparator.")
expect_equal(num$numeric_value[4], 100, "numeric_clean should parse greater-than comparator boundary.")
expect_true(all(num$numeric_status[5:7] == "coded_negative"), "Known negative labels should not become zero.")
expect_true(all(is.na(num$numeric_value[5:9])), "Negative, missing, and blank numerics should become NA.")

clone_fixture_adapter <- list(
  confluence_count_sets = function(min_cell_count = 5L) {
    list(
      patient_frame = data.frame(
        person_key = sprintf("p%02d", 1:8),
        date_death_fu = rep(as.Date(NA), 8),
        stringsAsFactors = FALSE
      ),
      disease_first_dates = data.frame(
        person_key = c("p01", "p02", "p03", "p04", "p05", "p06", "p06"),
        state_id = c("cll", "cll", "cll", "coded_mbl", "mm", "cll", "mgus"),
        first_date = as.Date(c("2020-01-01", "2020-01-01", "2020-01-01", "2020-01-01", "2020-02-01", "2020-01-01", "2019-01-01")),
        stringsAsFactors = FALSE
      ),
      clone_evidence = data.frame(
        person_key = c(
          "p01", "p01",
          "p02", "p02",
          "p03", "p03",
          "p04", "p04",
          "p05",
          "p06", "p06", "p06"
        ),
        route_id = c(
          "bcell_rkkp_cll_registry_diagnosis_date", "pcd_damyda_clonal_pc_percent",
          "bcell_diag_cll_icd_c911", "pcd_lab_sds_mspike_nonigm_probable",
          "bcell_diag_cll_icd_c911", "pcd_lab_sds_mspike_igm_ambiguous",
          "bcell_diag_mbl_icd_d479b", "pcd_diag_mgus_candidate",
          "pcd_damyda_clonal_pc_percent",
          "bcell_diag_cll_icd_c911", "pcd_diag_mgus_candidate", "pcd_damyda_clonal_pc_percent"
        ),
        evidence_date = as.Date(c(
          "2020-01-01", "2020-06-01",
          "2020-01-01", "2020-05-01",
          "2020-01-01", "2020-04-01",
          "2020-01-01", "2020-03-01",
          "2020-02-01",
          "2020-01-01", "2019-01-01", "2021-01-01"
        )),
        stringsAsFactors = FALSE
      ),
      infection_events = data.frame(
        person_key = c("p01", "p02", "p03", "p04", "p05", "p06"),
        event_date = as.Date(rep("2021-08-01", 6)),
        endpoint_id = "serious_infection_hospitalization",
        stringsAsFactors = FALSE
      )
    )
  }
)

prod <- confluence_count_build_outputs(root, clone_fixture_adapter, mode = "production_aggregate", min_cell_count = 1L)
expect_true(any(prod$clone_route_manifest$route_id == "pcd_diag_mgus_candidate" & prod$clone_route_manifest$route_status == "usable"), "Hook evidence should create a route-level manifest for observed routes.")
expect_true(any(prod$dual_clone_overlap_counts$overlap_id == "accepted_dual_clone_overlap" & prod$dual_clone_overlap_counts$count_display == "2" & prod$dual_clone_overlap_counts$acceptance_status == "accepted"), "Only direct/accepted plasma-cell evidence should enter accepted dual clone.")
expect_true(any(prod$dual_clone_overlap_counts$overlap_id == "probable_dual_clone_sensitivity" & prod$dual_clone_overlap_counts$count_display == "1"), "Non-IgM M-component/FLC support should enter probable sensitivity.")
expect_true(any(prod$dual_clone_overlap_counts$overlap_id == "ambiguous_bcell_paraprotein" & prod$dual_clone_overlap_counts$count_display == "1"), "CLL plus IgM-only paraprotein should remain ambiguous.")
expect_true(any(prod$dual_clone_overlap_counts$overlap_id == "candidate_diagnosis_overlap" & prod$dual_clone_overlap_counts$count_display == "1"), "MBL code plus MGUS code should remain candidate overlap.")
expect_true(any(prod$dual_clone_overlap_counts$overlap_id == "pcd_only" & prod$dual_clone_overlap_counts$count_display == "1"), "PCD-only evidence should not become dual clone.")
expect_false(any(prod$dual_clone_overlap_counts$overlap_id == "accepted_dual_clone_overlap" & grepl("candidate|ambiguous|unvalidated|unavailable", prod$dual_clone_overlap_counts$evidence_tier, ignore.case = TRUE)), "Accepted dual clone must not be labelled candidate, ambiguous, unavailable, or unvalidated.")
expect_true(any(prod$dual_clone_overlap_timing$classification_id == "accepted_dual_clone_overlap" & prod$dual_clone_overlap_timing$bcell_entry_route_id == "bcell_diag_cll_icd_c911" & prod$dual_clone_overlap_timing$pcd_entry_route_id == "pcd_damyda_clonal_pc_percent"), "Timing should expose route IDs for accepted entry routes.")
expect_true(any(prod$dual_clone_overlap_timing$timing_id == "bcell_first"), "CLL plus MGUS code first plus later accepted PCD should time from later accepted PCD, not MGUS code date.")
expect_true(any(prod$primary_overlap_exclusion_reasons$exclusion_reason == "mgus_code_only"), "Exclusion reasons should include MGUS-code-only blockers.")
expect_true(any(prod$mgus_reclassification_waterfall$step_label == "Remaining MGUS-code overlap after primary gate"), "MGUS reclassification waterfall should show candidate remnants.")
expect_true(any(prod$paraprotein_ambiguity_counts$ambiguity_id == "ambiguous_bcell_paraprotein_classified"), "Ambiguity output should include deterministic post-hierarchy count.")
expect_true(any(prod$infection_person_time$group_id == "accepted_dual_clone_overlap"), "Person-time should use new accepted dual-clone group IDs.")
expect_true(any(prod$infection_counts$group_id == "accepted_dual_clone_overlap"), "Infection counts should use new accepted dual-clone group IDs.")

small_prod <- confluence_count_build_outputs(root, clone_fixture_adapter, mode = "production_aggregate", min_cell_count = 5L)
accepted_small <- small_prod$dual_clone_overlap_counts[small_prod$dual_clone_overlap_counts$overlap_id == "accepted_dual_clone_overlap", , drop = FALSE]
expect_true(accepted_small$count_display[[1]] == "<5" && accepted_small$suppression_status == "suppressed small cell", "Small accepted dual-clone counts should be suppressed.")

new_public_outputs <- prod[c(
  "clone_route_manifest", "clone_source_resolution", "bcell_clone_evidence_counts",
  "pcd_clone_evidence_counts", "paraprotein_ambiguity_counts",
  "mgus_reclassification_waterfall", "dual_clone_overlap_counts",
  "dual_clone_overlap_timing", "primary_overlap_exclusion_reasons",
  "clone_availability_protocol_runway"
)]
forbidden_columns <- tolower(c(
  "patientid", "pnr", "cpr", "OBS_DIAGNOSIS", "PHENOTYPE", "CONCLUSION",
  "POPULATION", "v_fritekst", "resulttextvalue", "resultvalue",
  "ord_value", "value", "c_resultvaluenumeric", "person_key"
))
for (name in names(new_public_outputs)) {
  expect_false(any(tolower(names(new_public_outputs[[name]])) %in% forbidden_columns), paste("New public clone output has forbidden column name:", name))
}
public_text <- paste(unlist(new_public_outputs, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("\\bp[0-9]{2}\\b", public_text), "New public clone outputs must not emit fake person IDs.")
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", public_text), "New public clone outputs must not emit CPR-like values.")
expect_false(grepl("raw pathology text|snippet|row preview", public_text, ignore.case = TRUE), "New public clone outputs must not emit raw text/snippets/row previews.")

cat("CONFLUENCE clone evidence tests passed\n")
