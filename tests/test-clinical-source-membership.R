root <- normalizePath('.', winslash = '/', mustWork = TRUE)
source('tests/helper.R'); source_test_runtime(root)
expect_true(exists('clinical_source_inventory', mode = 'function'),
            'Missing exact clinical-source selector: shared literal memberships must be supported.')
fixture <- jsonlite::fromJSON(file.path(root, 'tests/fixtures/clinical-source-membership.json'), simplifyVector = FALSE)
spec <- load_clinical_source_membership(root)
json <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = 'null', na = 'null', digits = NA))
expect_equal(vapply(spec$panels, function(p) p$panel_id, character(1)), unlist(fixture$covered_panel_ids, use.names = FALSE))
expect_equal(Filter(function(p) p$panel_id == 'clinical_imaging', spec$panels)[[1]]$review_key, 'imaging')
for (case in fixture$resource_cases) {
  result <- tryCatch(validate_clinical_source_membership(case$input), error = identity)
  if (isTRUE(case$expected_valid)) {
    expect_false(inherits(result, 'error'), paste('Valid resource rejected:', case$name))
  } else {
    expect_true(inherits(result, 'error'), paste('Invalid resource accepted:', case$name))
    expect_true(grepl(case$expected_error, conditionMessage(result), fixed = TRUE), paste('Wrong validation reason:', case$name))
  }
}
for (case in fixture$selector_cases) {
  before <- serialize(case$input, NULL)
  result <- clinical_source_inventory(case$input$catalog_rows, spec,
    evidence_origin = case$input$evidence_origin, inventory_limited = case$input$inventory_limited)
  expect_equal(json(result), json(case$expected), paste('Literal selector parity failed:', case$name))
  expect_equal(serialize(case$input, NULL), before, paste('Selector mutated original evidence:', case$name))
}
duplicates <- lapply(seq_len(130), function(i) list(table_name = paste0('unknown_', i), load_status = 'ok'))
bounded <- clinical_source_inventory(c(duplicates, duplicates), spec)
expect_equal(length(bounded$diagnostics), 101L)
expect_equal(bounded$diagnostics[[101]]$code, 'diagnostics_truncated')
expect_equal(length(bounded$rows), 0L)
missing_root <- tempfile('missing-membership-'); dir.create(file.path(missing_root, 'inst/config'), recursive = TRUE)
bad_path <- file.path(missing_root, 'inst/config/clinical-source-membership.json')
writeLines('{"schema_version":999}', bad_path)
result <- tryCatch(load_clinical_source_membership(missing_root), error = identity)
expect_true(inherits(result, 'error'), 'Malformed explicit config must fail rather than use installed fallback.')
expect_true(grepl('clinical-source-membership', conditionMessage(result), fixed = TRUE))
jsonlite::write_json(fixture$resource_cases[[1]]$input, bad_path, auto_unbox = TRUE)
partial <- tryCatch(load_clinical_source_membership(missing_root), error = identity)
expect_true(inherits(partial, 'error'), 'A publisher resource must cover all twelve panels; small fixture specs are validator-only.')
expect_true(grepl('incomplete_panel_coverage', conditionMessage(partial), fixed = TRUE))
cat('Exact clinical-source resource validation and shared literal selector parity passed\n')
