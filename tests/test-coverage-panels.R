root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

regions <- dk_region_reference()
expect_equal(sum(regions$map_include), 5L, "Denmark map should include exactly five displayed regions.")
expect_true("1099" %in% regions$region_code[!regions$map_include], "Other/unknown should be retained but excluded from map geometry.")
expect_equal(normalize_dk_region(c("1084", "Capital Region", "Region Hovedstaden", "Region Sjælland", "North Denmark Region")), c("1084", "1084", "1084", "1085", "1081"), "Region normalization should handle codes and English/Danish labels.")

profiles <- data.frame(
  table_name = "example",
  column_name = c("date_birth", "created_at", "Reg_Diagnose_dt", "gyldig_til"),
  profile_kind = "date",
  n_available = c(10, 10, 9, 10),
  pct_available = c(100, 100, 90, 100),
  is_sensitive = FALSE,
  min_date = c("1900-01-01", "2024-01-01", "2005-01-01", "1970-01-01"),
  max_date = c("2000-01-01", "2025-01-01", "2024-12-31", "9999-12-31"),
  stringsAsFactors = FALSE
)
expect_equal(coverage_date_column_from_profiles(profiles), "Reg_Diagnose_dt", "Temporal coverage should prefer event/diagnosis dates over birth/admin/sentinel date columns.")
expect_equal(coverage_clamped_year("9999-12-31", upper = 2027L), 2027L, "Display coverage years should clamp impossible future sentinels.")
expect_equal(coverage_temporal_qc_flag("2005-01-01", "9999-12-31", upper = 2027L), "clamped_display_range", "Coverage rows should flag clamped display ranges.")

example <- data.frame(
  patientid = sprintf("010101%04d", seq_len(8)),
  Reg_Diagnose_dt = as.Date("2020-01-01") + 0:7,
  Region = c("1084", "1084", "1084", "1084", "1085", "1085", "1099", "1099"),
  stringsAsFactors = FALSE
)
years <- panel_temporal_coverage_years(example, "RKKP_DaMyDa", min_cell_count = 2L)
expect_true(any(years$year == 2020 & years$n_rows == 8), "In-memory temporal coverage should emit aggregate source-year counts.")
region_counts <- panel_spatial_region_counts(example, "RKKP_DaMyDa", min_cell_count = 2L)
expect_true(any(region_counts$region_code == "1084" & region_counts$n_rows == 4), "Region count panel should normalize and count region codes.")
expect_false(any(region_counts$region_column == "patientid"), "Region count panel must not use patient identifiers.")

sources <- data.frame(
  table_name = c("RKKP_DaMyDa", "SP_VitaleVaerdier"),
  domain = c("RKKP", "SP"),
  subdomain = c("DaMyDa", "Vitals"),
  atlas_role = c("clinical_registry", "vitals"),
  load_status = c("ok", "ok"),
  n_rows = c(8, 100),
  stringsAsFactors = FALSE
)
region_counts <- add_source_context_to_coverage_panels(region_counts, sources)
coverage <- panel_atlas_spatial_region_coverage(sources, region_counts)
expect_true(any(coverage$domain == "SP" & coverage$region_code == "1084" & coverage$coverage_status == "ehr"), "SP coverage should default to Capital/Zealand EHR regions.")
choropleth <- panel_atlas_dk_choropleth_regions(
  sources,
  panels = list(damyda_clinical_profile = data.frame(
    table_name = "RKKP_DaMyDa",
    registry = "DaMyDa",
    facet = "region",
    source_column = "Region",
    label = c("1084", "1085", "1099"),
    n = c(4, 2, 2),
    pct_rows = c(50, 25, 25),
    stringsAsFactors = FALSE
  )),
  region_counts = region_counts,
  region_coverage = coverage
)
expect_true(any(choropleth$region_code == "1084" & choropleth$damyda_n == 4), "Choropleth should use DaMyDa regional counts when available.")
expect_false(any(choropleth$region_code == "1099" & choropleth$map_include), "Other/unknown should not be included in Denmark map shading.")
