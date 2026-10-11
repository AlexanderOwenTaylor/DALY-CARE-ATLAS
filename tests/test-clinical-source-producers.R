root <- normalizePath('.', winslash = '/', mustWork = TRUE)
source('tests/helper.R'); source_test_runtime(root)
spec <- load_clinical_source_membership(root)
fixture <- jsonlite::fromJSON('tests/fixtures/clinical-source-membership.json', simplifyVector = FALSE)
source_frame <- function(rows) data.frame(
  table_name = vapply(rows, function(row) row$table_name, character(1)),
  load_status = vapply(rows, function(row) row$load_status %||% '', character(1)),
  n_rows = vapply(rows, function(row) row$n_rows %||% NA_real_, numeric(1)),
  n_cols = 20, min_date = '2001-01-01', max_date = '2025-12-31',
  domain = 'SP', subdomain = 'Synthetic', atlas_role = 'source',
  source_type = 'file', source = 'synthetic.csv', profile_mode = 'full',
  stringsAsFactors = FALSE)
sources <- source_frame(fixture$selector_cases[[1]]$input$catalog_rows)
before <- serialize(sources, NULL)
review <- review_clinical_sections(sources, membership_spec = spec)
keys <- function(rows) vapply(rows, function(row) row$table_name, character(1))
expect_equal(keys(review$diagnoses), c('SDS_diagnoser', 'Behandlingskontakter_diagnoser'))
expect_equal(keys(review$admissions), c('SP_ADT_haendelser', 'SDS_kontakter', 'Behandlingskontakter_diagnoser'))
expect_equal(keys(review$imaging), 'SP_BilleddiagnostikeUndersoegelser_Del1')
expect_equal(length(review$notes), 0L)
panels <- list(diagnosis_atlas = data.frame(n = numeric()),
               clinical_imaging = data.frame(n = NA_real_),
               registry_clinical_summary = data.frame(n = 1))
ready <- atlas_module_readiness(sources, panels, membership_spec = spec)
expect_equal(ready$source_count[ready$module == 'CLL registry'], 1L)
expect_equal(ready$source_count[ready$module == 'Diagnoses and tumors'], 2L)
expect_equal(ready$source_count[ready$module == 'Admissions and ADT'], 3L)
covered_modules <- c('DaMyDa registry', 'LYFO registry', 'CLL registry',
  'Diagnoses and tumors', 'Admissions and ADT', 'Imaging and radiotherapy diagnostics',
  'Vitals', 'Notes', 'Social history', 'Microbiology / MiBa diagnostics',
  'Pathology / PATOBANK diagnostics', 'Biobank sample inventory')
covered <- ready[ready$module %in% covered_modules, , drop = FALSE]
expect_equal(nrow(covered), 12L)
expect_true(all(is.na(covered$n_rows)) && all(is.na(covered$n_columns)), 'Covered readiness must never pool source rows or fields.')
expect_true(all(covered$date_min == '') && all(covered$date_max == ''), 'Covered dates must not be pooled.')
expect_false(any(covered$status == 'panel_ready'), 'Panel names/header-only/withheld rows do not establish clinical eligibility.')
expect_true(all(grepl('not additive', covered$message, fixed = TRUE)))
expect_false(any(grepl('Molecular, pathology', ready$module, fixed = TRUE)))
duplicate_sources <- source_frame(fixture$selector_cases[[4]]$input$catalog_rows)
duplicate_ready <- atlas_module_readiness(duplicate_sources, list(), membership_spec = spec)
duplicate_biobank <- duplicate_ready[duplicate_ready$module == 'Biobank sample inventory', , drop = FALSE]
expect_equal(duplicate_biobank$source_count, 1L)
expect_equal(duplicate_biobank$loaded_count, 0L)
expect_equal(duplicate_biobank$status, 'source_state_unknown')
expect_true(grepl('Duplicate identity counts', duplicate_biobank$message, fixed = TRUE))
aliases <- source_frame(fixture$selector_cases[[3]]$input$catalog_rows)
alias_ready <- atlas_module_readiness(aliases, list(), membership_spec = spec)
expect_equal(alias_ready$source_count[alias_ready$module == 'Biobank sample inventory'], 2L)
kpis <- bind_rows_base(product_source_kpis(sources, product_panel_specs(), membership_spec = spec))
cll <- kpis[kpis$panel_id == 'reg_cll', , drop = FALSE]
expect_equal(cll$value[cll$kpi_id == 'mapped_sources'], '1')
expect_equal(cll$label[cll$kpi_id == 'mapped_sources'], 'Current source identities')
expect_equal(cll$source_name[cll$kpi_id == 'mapped_sources'], 'RKKP_CLL')
for (id in clinical_source_panel_ids()) {
  summed <- kpis[kpis$panel_id == id & kpis$kpi_id == 'source_rows', , drop = FALSE]
  expect_equal(nrow(summed), 1L)
  expect_equal(summed$value, 'Not summed')
  expect_equal(summed$label, 'Source records (not additive)')
  expect_equal(summed$unit, '')
  expect_equal(summed$count_scope, 'source_identity_metadata')
}
expect_equal(serialize(sources, NULL), before, 'Fresh metadata helpers must leave source evidence unchanged.')
expect_equal(product_merge_scopes('source_identity_metadata'), 'source_identity_metadata')
checks <- data.frame(table_name = character(), check_id = character(), severity = character(), message = character())
columns <- data.frame(table_name = character(), column_name = character(), column_type = character())
payload <- atlas_payload('membership-test', '2026-10-11', sources, columns, checks, panels, membership_spec = spec)
expect_equal(payload$clinical_source_inventory$basis, 'reviewed_exact_source_inventory')
expect_equal(payload$clinical_source_inventory$evidence_origin, 'fresh_run')
expect_equal(payload$catalog_rows, public_rows(catalog_rows(sources), max_rows = 1000))
expect_equal(payload$clinical_source_inventory$rows,
             clinical_source_inventory(payload$catalog_rows, spec)$rows)
legacy <- atlas_payload('membership-test', '2026-10-11', sources, columns, checks, panels)
expect_false('clinical_source_inventory' %in% names(legacy), 'Absent optional metadata preserves legacy payload compatibility.')
many <- sources[rep(1L, 1001L), ]; many$table_name <- paste0('unknown_', seq_len(nrow(many)))
limited <- atlas_payload('limited', '2026-10-11', many, columns, checks, list(), membership_spec = spec)
expect_equal(limited$clinical_source_inventory$inventory_state, 'limited')
expect_equal(length(limited$catalog_rows), 1000L)
expect_equal(limited$clinical_source_inventory$diagnostics[[1]]$code, 'catalog_limited')
cat('Exact covered review/readiness/source-KPI and guarded payload producer tests passed\n')
