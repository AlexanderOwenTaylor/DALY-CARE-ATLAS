root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

routes <- confluence_clone_read_sources(root)
expect_true(nrow(routes) >= 25L, "Clone route config should include source-specific route cartography.")

cartography_lint <- confluence_clone_lint_sources(routes, project_root = root, check_cartography = TRUE)
expect_true(nrow(cartography_lint) == 0L, "Clone route config should pass static cartography/source/NPU lint.")

allowed_modes <- confluence_clone_allowed_query_modes()
expect_true(all(routes$route_query_mode %in% allowed_modes), "Every clone route mode should be explicitly allowlisted.")
expect_false(any(routes$route_query_mode == "manifest_only" & (routes$usable_for_primary_overlap | routes$usable_for_sensitivity_overlap)), "Manifest-only routes cannot contribute to any cohort.")

placeholder_columns <- c(
  "SAMPLE_DATE", "RESULT_DATE", "NPU_CODE", "PATHOLOGICAL_PC_PCT",
  "KAPPA", "LAMBDA", "ABNORMAL_BCELL", "Reg_Mkomptype", "Reg_FLCratio",
  "Reg_1_linieBeh", "Reg_1_linieBeh_anden"
)
config_column_text <- paste(routes$required_columns, routes$optional_columns, routes$date_columns, routes$code_column, collapse = ";")
for (col in placeholder_columns) {
  expect_false(grepl(paste0("(^|;)", col, "($|;)"), config_column_text, fixed = FALSE), paste("Placeholder column should not remain in clone config:", col))
}

expect_true(any(routes$route_id == "pcd_damyda_clonal_pc_percent" & routes$route_query_mode == "numeric_positive_any" & routes$usable_for_primary_overlap), "DaMyDa clonal plasma-cell percentage should be executable direct evidence.")
expect_true(any(routes$route_id == "pcd_damyda_marrow_infiltration" & routes$route_query_mode == "categorical_yes_any" & routes$usable_for_primary_overlap), "DaMyDa marrow infiltration should be executable direct evidence.")
expect_true(any(routes$route_id == "pcd_damyda_typed_mcomponent_flc" & routes$route_query_mode == "damyda_nonigm_mcomponent_support" & !routes$usable_for_primary_overlap), "DaMyDa non-IgM typed M-component support should remain non-primary.")
expect_true(any(routes$route_id == "pcd_damyda_igm_mcomponent_ambiguity" & routes$axis == "ambiguity" & routes$route_query_mode == "damyda_igm_mcomponent_ambiguity"), "DaMyDa IgM support should be ambiguity-only.")
expect_true(any(routes$route_id == "bcell_flow_clonal_bcell_support" & routes$route_query_mode == "flow_bcell_support"), "Flow B-cell route should use source-specific flow predicate mode.")
expect_true(any(routes$route_id == "pcd_flow_pathological_pc_pct" & routes$route_query_mode == "flow_pcd_support"), "Flow PCD route should use source-specific flow predicate mode.")
expect_true(any(routes$route_id == "pcd_lab_sds_mspike_nonigm_probable" & routes$route_query_mode == "lab_npu_vector" & routes$code_column == "analysiscode"), "SDS lab route should use NPU dictionary vector mode.")
expect_true(any(routes$route_id == "pcd_lab_sp_mspike_nonigm_probable" & routes$route_query_mode == "lab_npu_vector" & routes$code_column == "component"), "SP lab route should use NPU dictionary vector mode.")
expect_true(any(routes$route_id == "pcd_lab_persimune_flc_probable" & routes$route_query_mode == "lab_npu_vector" & routes$code_column == "analysiscode"), "PERSIMUNE lab route should use NPU dictionary vector mode.")

bad_mode <- routes
bad_mode$route_query_mode[1] <- "silent_manifest_fallback"
bad_mode_lint <- confluence_clone_lint_sources(bad_mode, project_root = root, check_cartography = TRUE)
expect_true(any(bad_mode_lint$field == "route_query_mode"), "Unknown route_query_mode values should fail lint.")

bad_manifest <- routes
bad_manifest$route_query_mode[1] <- "manifest_only"
bad_manifest$usable_for_sensitivity_overlap[1] <- TRUE
bad_manifest_lint <- confluence_clone_lint_sources(bad_manifest, project_root = root, check_cartography = TRUE)
expect_true(any(bad_manifest_lint$lint_id == "manifest_only_contributes"), "Manifest-only routes should fail lint if they can contribute evidence.")

bad_placeholder <- routes
bad_placeholder$required_columns[bad_placeholder$route_id == "pcd_flow_pathological_pc_pct"] <- "patientid;DATE;PATHOLOGICAL_PC_PCT"
bad_placeholder_lint <- confluence_clone_lint_sources(bad_placeholder, project_root = root, check_cartography = TRUE)
expect_true(any(bad_placeholder_lint$lint_id == "placeholder_column"), "Placeholder clone columns should fail cartography lint.")

bad_primary <- routes
bad_primary$usable_for_primary_overlap[bad_primary$route_id == "pcd_lab_sds_mspike_igm_ambiguous"] <- TRUE
bad_primary_lint <- confluence_clone_lint_sources(bad_primary, project_root = root, check_cartography = TRUE)
expect_true(any(bad_primary_lint$route_id == "pcd_lab_sds_mspike_igm_ambiguous" & bad_primary_lint$field == "usable_for_primary_overlap"), "IgM ambiguity routes must not become primary-usable.")

cat("CONFLUENCE clone route cartography lint tests passed\n")
