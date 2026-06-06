root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

routes <- confluence_clone_read_sources(root)
route <- function(route_id) routes[routes$route_id == route_id, , drop = FALSE][1, , drop = FALSE]
sql_for <- function(route_id) confluence_clone_route_sql(route(route_id), project_root = root)

numeric_sql <- sql_for("pcd_damyda_clonal_pc_percent")
expect_true(grepl("Reg_ProcentKlonalePlasmaceller", numeric_sql, fixed = TRUE), "Numeric route should reference exact DaMyDa clonal plasma-cell column.")
expect_true(grepl("regexp_replace", numeric_sql, fixed = TRUE) && grepl("::numeric", numeric_sql, fixed = TRUE), "Numeric route should use guarded SQL numeric parsing.")
expect_true(grepl("> 0", numeric_sql, fixed = TRUE), "Numeric route should require a positive value.")

categorical_sql <- sql_for("pcd_damyda_marrow_infiltration")
expect_true(grepl("Reg_PCINFMARV", categorical_sql, fixed = TRUE), "Categorical route should reference exact DaMyDa marrow column.")
expect_true(grepl("'Y', 'YES', 'JA', '1', 'TRUE', 'T'", categorical_sql, fixed = TRUE), "Categorical route should use the positivity allowlist.")

flow_bcell_sql <- sql_for("bcell_flow_clonal_bcell_support")
expect_true(grepl("BCLPD", flow_bcell_sql, fixed = TRUE) && grepl("BLIM", flow_bcell_sql, fixed = TRUE), "Flow B-cell route should constrain expected panels.")
expect_true(grepl("B_CELLER_ABNORMALE", flow_bcell_sql, fixed = TRUE), "Flow B-cell route should use abnormal B-cell columns.")
expect_true(grepl("K_L_ratio", flow_bcell_sql, fixed = TRUE) && grepl("Kappa_positive_PCT", flow_bcell_sql, fixed = TRUE) && grepl("Lambda_positive_PCT", flow_bcell_sql, fixed = TRUE), "Flow B-cell route should include light-chain restriction columns.")

flow_pcd_sql <- sql_for("pcd_flow_pathological_pc_pct")
expect_true(grepl("PCD", flow_pcd_sql, fixed = TRUE) && grepl("MYELOM", flow_pcd_sql, fixed = TRUE), "Flow PCD route should constrain expected panels.")
expect_true(grepl("MATERIAL", flow_pcd_sql, fixed = TRUE), "Flow PCD route should include marrow material preference.")
expect_true(grepl("PC_PATOLOGISKE", flow_pcd_sql, fixed = TRUE) && grepl("PC_MULIGE_PATOLOGISKE_PCT", flow_pcd_sql, fixed = TRUE), "Flow PCD route should use pathological plasma-cell columns.")
expect_false(grepl("OBS_DIAGNOSIS|PHENOTYPE|CONCLUSION|POPULATION", flow_pcd_sql), "Flow routes must not use raw flow text fields.")

nonigm_sql <- sql_for("pcd_damyda_typed_mcomponent_flc")
expect_true(grepl("Reg_PlasmaMKomp_IgA_Kappa", nonigm_sql, fixed = TRUE) && grepl("Reg_PlasmaMKomp_IgG_Lambda", nonigm_sql, fixed = TRUE), "DaMyDa non-IgM route should use typed non-IgM M-component fields.")
expect_false(grepl("Reg_PlasmaMKomp_IgM_", nonigm_sql, fixed = TRUE), "DaMyDa non-IgM route should not use IgM ambiguity columns.")

igm_sql <- sql_for("pcd_damyda_igm_mcomponent_ambiguity")
expect_true(grepl("Reg_PlasmaMKomp_IgM_Kappa", igm_sql, fixed = TRUE) && grepl("Reg_PlasmaMKomp_IgM_Lambda", igm_sql, fixed = TRUE), "DaMyDa IgM route should use IgM ambiguity columns.")

lab_sql <- sql_for("pcd_lab_sds_mspike_nonigm_probable")
expect_true(grepl("join (values", lab_sql, fixed = TRUE), "Lab NPU vector route should compile dictionary vectors into an inline aggregate SQL join.")
expect_true(grepl("analysiscode", lab_sql, fixed = TRUE), "SDS lab route should join through analysiscode.")
expect_true(grepl("MSPIKE_IGG", lab_sql, fixed = TRUE) && grepl("FLC_RATIO_CODES", lab_sql, fixed = TRUE), "Lab NPU vector route should filter configured consensus vectors.")
expect_false(grepl("MSPIKE_SCREEN|MSPIKE_TYPE_LABEL", lab_sql), "Generic/untyped NPU vectors should not be included in non-IgM probable route SQL.")

sp_lab_sql <- sql_for("pcd_lab_sp_mspike_nonigm_probable")
expect_true(grepl("component", sp_lab_sql, fixed = TRUE), "SP lab route should join through component.")

persimune_lab_sql <- sql_for("pcd_lab_persimune_flc_probable")
expect_true(grepl("analysiscode", persimune_lab_sql, fixed = TRUE), "PERSIMUNE lab route should join through analysiscode.")

manifest_route <- route("pcd_damyda_clonal_pc_percent")
manifest_route$route_query_mode <- "manifest_only"
expect_equal(confluence_clone_route_sql(manifest_route, project_root = root), "", "Manifest-only routes should not generate SQL.")
evidence <- data.frame(person_key = "p01", route_id = manifest_route$route_id, evidence_date = as.Date("2020-01-01"), stringsAsFactors = FALSE)
manifest <- confluence_clone_hook_manifest(manifest_route, evidence)
out <- confluence_clone_outputs_from_evidence(evidence, manifest_route, manifest, min_cell_count = 1L)
expect_true(nrow(out$internal_clone_evidence) == 0L, "Manifest-only routes cannot contribute evidence through secure hooks.")
expect_false(any(out$dual_clone_overlap_counts$count_display != "0" & out$dual_clone_overlap_counts$count_display != "<1"), "Manifest-only evidence should not create cohort counts.")

cat("CONFLUENCE clone route SQL tests passed\n")
