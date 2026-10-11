root <- normalizePath('.', winslash = '/', mustWork = TRUE)
source('tests/helper.R'); source_test_runtime(root)
fixture <- jsonlite::fromJSON('tests/fixtures/clinical-source-membership.json', simplifyVector = FALSE)
spec <- load_clinical_source_membership(root)
failures <- character()
check <- function(name, code) {
  result <- tryCatch({ force(code); NULL }, error = identity)
  if (inherits(result, 'error')) {
    failures <<- c(failures, name)
    cat(name, ': ', conditionMessage(result), '\n', sep = '')
  }
}
check('catalog required table_name is exact', {
  out <- clinical_source_inventory(list(list(table_name_extra = 'SDS_t_diag', load_status = 'loaded')), spec)
  expect_equal(out$inventory_state, 'unavailable'); expect_equal(length(out$rows), 0L)
  expect_equal(out$diagnostics[[1]]$code, 'catalog_malformed')
})
check('catalog optional names are exact', {
  out <- clinical_source_inventory(list(list(table_name = 'SDS_t_diag', load_status_extra = 'loaded', canonical_resource_id_extra = 'BIOBANK_SAMPLES')), spec)
  expect_equal(out$rows[[1]]$load_status, NULL); expect_equal(out$rows[[1]]$load_state, 'unknown')
  expect_equal(out$rows[[1]]$canonical_resource_id, 't_diag')
  expect_equal(out$rows[[1]]$canonical_lineage_state, 'established')
})
check('duplicate catalog object fields are malformed', {
  row <- structure(list('SDS_t_diag', 'RKKP_CLL'), names = c('table_name', 'table_name'))
  out <- clinical_source_inventory(list(row), spec)
  expect_equal(out$inventory_state, 'unavailable'); expect_equal(length(out$rows), 0L)
})
check('duplicate dataframe columns are malformed', {
  frame <- data.frame(table_name = 'SDS_t_diag', other = 'RKKP_CLL', check.names = FALSE)
  names(frame) <- c('table_name', 'table_name')
  out <- clinical_source_inventory(frame, spec)
  expect_equal(out$inventory_state, 'unavailable'); expect_equal(length(out$rows), 0L)
})
minimal <- fixture$resource_cases[[1]]$input
check('catalog NBSP-only identity is malformed', {
  out <- clinical_source_inventory(list(list(table_name = intToUtf8(160L))), spec)
  expect_equal(out$inventory_state, 'unavailable'); expect_equal(length(out$rows), 0L)
})
check('resource surrounding NBSP is invalid whitespace', {
  input <- minimal; input[['inventory_version']] <- paste0(intToUtf8(160L), 'fixture-1')
  expect_true(inherits(tryCatch(validate_clinical_source_membership(input), error = identity), 'error'))
  input <- minimal; input[['panels']][[1]][['sources']][[1]][['source_keys']][[1]] <- paste0('BIOBANK_SAMPLES', intToUtf8(160L))
  expect_true(inherits(tryCatch(validate_clinical_source_membership(input), error = identity), 'error'))
})
check('nonblank catalog surrounding whitespace remains exact', {
  input <- list(list(table_name = paste0(intToUtf8(160L), 'SDS_t_diag'), load_status = 'loaded'))
  before <- serialize(input, NULL)
  out <- clinical_source_inventory(input, spec)
  expect_equal(out$inventory_state, 'present'); expect_equal(length(out$rows), 0L)
  expect_equal(serialize(input, NULL), before)
})
for (field in c('schema_version', 'inventory_version', 'panels')) {
  check(paste('resource exact required field', field), {
    input <- minimal; names(input)[names(input) == field] <- paste0(field, '_extra')
    expect_true(inherits(tryCatch(validate_clinical_source_membership(input), error = identity), 'error'))
  })
}
for (field in c('panel_id', 'sources')) {
  check(paste('panel exact required field', field), {
    input <- minimal; names(input$panels[[1]])[names(input$panels[[1]]) == field] <- paste0(field, '_extra')
    expect_true(inherits(tryCatch(validate_clinical_source_membership(input), error = identity), 'error'))
  })
}
for (field in c('membership_id', 'source_keys', 'membership_role', 'evidence_layer')) {
  check(paste('source exact required field', field), {
    input <- minimal
    names(input$panels[[1]]$sources[[1]])[names(input$panels[[1]]$sources[[1]]) == field] <- paste0(field, '_extra')
    expect_true(inherits(tryCatch(validate_clinical_source_membership(input), error = identity), 'error'))
  })
}
check('resource optional canonical field is exact', {
  input <- minimal
  names(input$panels[[1]]$sources[[1]])[names(input$panels[[1]]$sources[[1]]) == 'canonical_resource_id'] <- 'canonical_resource_id_extra'
  parsed <- validate_clinical_source_membership(input)
  out <- clinical_source_inventory(list(list(table_name = 'BIOBANK_SAMPLES', load_status = 'loaded')), parsed)
  expect_equal(out$rows[[1]]$canonical_resource_id, NULL)
  expect_equal(out$rows[[1]]$canonical_lineage_state, 'unestablished')
})
check('resource optional review field is exact', {
  input <- spec; input$panels[[7]]$review_key_extra <- 'unreviewed_extension'
  parsed <- validate_clinical_source_membership(input)
  frame <- data.frame(table_name = 'BIOBANK_SAMPLES', load_status = 'loaded')
  reviews <- review_clinical_sections(frame, parsed)
  expect_false('unreviewed_extension' %in% names(reviews))
})
for (scope in c('top', 'panel', 'source')) {
  check(paste('recursive duplicate resource object fields', scope), {
    input <- minimal
    if (scope == 'top') input <- c(input, list(schema_version = 999L))
    if (scope == 'panel') input$panels[[1]] <- c(input$panels[[1]], list(panel_id = 'clinical_pathology'))
    if (scope == 'source') input$panels[[1]]$sources[[1]] <- c(input$panels[[1]]$sources[[1]], list(membership_role = 'context'))
    rejected <- tryCatch(validate_clinical_source_membership(input), error = identity)
    expect_true(inherits(rejected, 'error'))
    expect_true(grepl('duplicate_object_key', conditionMessage(rejected), fixed = TRUE))
  })
}
check('duplicate JSON resource keys fail required loader', {
  project <- tempfile('duplicate-json-resource-'); dir.create(file.path(project, 'inst/config'), recursive = TRUE)
  text <- as.character(jsonlite::toJSON(spec, auto_unbox = TRUE, null = 'null'))
  text <- sub('"schema_version":1', '"schema_version":1,"schema_version":999', text, fixed = TRUE)
  writeLines(text, file.path(project, 'inst/config/clinical-source-membership.json'))
  rejected <- tryCatch(load_clinical_source_membership(project), error = identity)
  expect_true(inherits(rejected, 'error'))
  expect_true(grepl('duplicate_object_key', conditionMessage(rejected), fixed = TRUE))
})
check('valid typed frame remains supported', {
  frame <- data.frame(table_name = 'SDS_t_diag', load_status = 'loaded', stringsAsFactors = FALSE)
  out <- clinical_source_inventory(frame, spec)
  expect_equal(out$inventory_state, 'present'); expect_equal(out$rows[[1]]$source_key, 'SDS_t_diag')
})
if (length(failures)) stop('Strict boundary regressions: ', paste(failures, collapse = '; '), call. = FALSE)
cat('Strict exact resource/catalog field and duplicate-object boundary tests passed\n')
