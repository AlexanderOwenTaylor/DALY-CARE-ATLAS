# Finite reviewed source membership; canonical lineage never resolves identity.
clinical_source_panel_ids <- function() c(
  'diagnosis_atlas', 'clinical_adt', 'clinical_notes', 'clinical_microbiology',
  'clinical_imaging', 'clinical_pathology', 'clinical_biobank', 'clinical_vitals',
  'clinical_social_history', 'reg_damyda', 'reg_lyfo', 'reg_cll')

validate_clinical_source_membership <- function(spec) {
  fail <- function(code) stop('Invalid clinical-source-membership resource: ', code, call. = FALSE)
  unsafe <- c('__proto__', 'prototype', 'constructor')
  check_keys <- function(x) {
    if (is.list(x)) {
      if (any(names(x) %in% unsafe)) fail('unsafe_resource_key')
      if (anyDuplicated(names(x))) fail('duplicate_object_key')
      for (value in x) check_keys(value)
    }
  }
  check_keys(spec)
  object <- function(x) is.list(x) && !is.null(names(x))
  array <- function(x) is.list(x) && is.null(names(x))
  token <- function(x, limit = 256L) {
    if (is.character(x) && length(x) == 1L && !is.na(x) && x %in% unsafe) fail('unsafe_resource_key')
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x) &&
      identical(trimws(x, whitespace = '[\\h\\v]'), x) && nchar(x, type = 'chars') <= limit
  }
  if (!object(spec) || !identical(spec[["schema_version"]], 1L)) fail('unsupported_schema_version')
  if (!token(spec[["inventory_version"]], 128L)) fail('invalid_inventory_version')
  if (!array(spec[["panels"]]) || !length(spec[["panels"]]) || length(spec[["panels"]]) > 12L) fail('invalid_panels')
  panel_ids <- character(); families <- list(); key_families <- list()
  for (panel in spec[["panels"]]) {
    if (!object(panel) || !token(panel[["panel_id"]]) || !panel[["panel_id"]] %in% clinical_source_panel_ids()) fail('invalid_panel_id')
    if (panel[["panel_id"]] %in% panel_ids) fail('duplicate_panel_id')
    panel_ids <- c(panel_ids, panel[["panel_id"]])
    if ('review_key' %in% names(panel) && !token(panel[["review_key"]])) fail('invalid_review_key')
    if (!array(panel[["sources"]]) || !length(panel[["sources"]]) || length(panel[["sources"]]) > 64L) fail('invalid_sources')
    memberships <- character()
    for (entry in panel[["sources"]]) {
      if (!object(entry) || !token(entry[["membership_id"]])) fail('invalid_membership_id')
      id <- entry[["membership_id"]]
      if (id %in% memberships) fail('duplicate_membership_id')
      memberships <- c(memberships, id)
      if (!array(entry[["source_keys"]]) || !length(entry[["source_keys"]]) || length(entry[["source_keys"]]) > 32L ||
          !all(vapply(entry[["source_keys"]], token, logical(1)))) fail('invalid_source_keys')
      keys <- unlist(entry[["source_keys"]], use.names = FALSE)
      if (anyDuplicated(keys)) fail('duplicate_source_key')
      if (!token(entry[["membership_role"]]) || !entry[["membership_role"]] %in% c('primary', 'context', 'derived_view', 'text_availability')) fail('invalid_membership_role')
      if (!token(entry[["evidence_layer"]])) fail('invalid_evidence_layer')
      if ('canonical_resource_id' %in% names(entry) && !token(entry[["canonical_resource_id"]])) fail('invalid_canonical_resource_id')
      shape <- list(source_keys = keys, canonical_resource_id = entry[["canonical_resource_id"]])
      if (!is.null(families[[id]]) && !identical(families[[id]], shape)) fail('conflicting_membership_family')
      families[[id]] <- shape
      for (key in keys) {
        if (!is.null(key_families[[key]]) && !identical(key_families[[key]], id)) fail('conflicting_source_key')
        key_families[[key]] <- id
      }
    }
  }
  spec
}

clinical_source_membership_path <- function(project_root = NULL) {
  path <- if (!is.null(project_root)) file.path(project_root, 'inst/config/clinical-source-membership.json') else ''
  if (!nzchar(path) || !file.exists(path)) path <- system.file('config', 'clinical-source-membership.json', package = 'dalycareatlas')
  if (!nzchar(path) || !file.exists(path)) stop('Required clinical-source-membership resource unavailable; install the reviewed config or supply project_root.', call. = FALSE)
  normalizePath(path, winslash = '/', mustWork = TRUE)
}

load_clinical_source_membership <- function(project_root = NULL) {
  path <- clinical_source_membership_path(project_root)
  if (file.info(path)[["size"]] > 131072L) stop('Required clinical-source-membership resource exceeds size limit.', call. = FALSE)
  tryCatch({
    spec <- validate_clinical_source_membership(jsonlite::fromJSON(path, simplifyVector = FALSE))
    if (!setequal(vapply(spec[["panels"]], function(panel) panel[["panel_id"]], character(1)), clinical_source_panel_ids()))
      stop('incomplete_panel_coverage', call. = FALSE)
    spec
  }, error = function(e) stop('Required clinical-source-membership resource invalid: ', conditionMessage(e), call. = FALSE))
}

clinical_source_inventory <- function(catalog_rows, membership_spec,
                                      evidence_origin = 'fresh_run', inventory_limited = FALSE) {
  if (!evidence_origin %in% c('fresh_run', 'imported_snapshot') || length(evidence_origin) != 1L) stop('Invalid clinical-source inventory origin.', call. = FALSE)
  if (!is.logical(inventory_limited) || length(inventory_limited) != 1L || is.na(inventory_limited)) stop('Invalid clinical-source inventory limited flag.', call. = FALSE)
  diagnostics <- list(); rows <- list()
  add <- function(code, source_key = NULL, membership_id = NULL) {
    diagnostics[[length(diagnostics) + 1L]] <<- list(code = code, source_key = source_key, membership_id = membership_id)
  }
  string <- function(x) is.character(x) && length(x) == 1L && !is.na(x)
  nonblank <- function(x) string(x) && nzchar(trimws(x, whitespace = '[\\h\\v]'))
  catalog <- catalog_rows
  if (is.data.frame(catalog)) {
    catalog <- lapply(seq_len(nrow(catalog)), function(i) lapply(catalog, function(column) {
      value <- column[[i]]
      if (length(value) == 1L && is.na(value)) NULL else value
    }))
  }
  state <- if (isTRUE(inventory_limited)) 'limited' else 'present'
  if (is.null(catalog)) {
    state <- 'unavailable'; add('catalog_unavailable')
  } else if (!is.list(catalog) || !is.null(names(catalog)) || !all(vapply(catalog, function(row)
    is.list(row) && !is.null(names(row)) && !anyDuplicated(names(row)) &&
      'table_name' %in% names(row) && nonblank(row[["table_name"]]), logical(1)))) {
    state <- 'unavailable'; add('catalog_malformed')
  } else if (isTRUE(inventory_limited)) add('catalog_limited')
  if (state != 'unavailable') {
    keys <- vapply(catalog, function(row) row[["table_name"]], character(1))
    present <- unique(keys)
    family_entries <- list(); key_families <- list()
    for (panel in membership_spec[["panels"]]) for (entry in panel[["sources"]]) {
      id <- entry[["membership_id"]]
      if (is.null(family_entries[[id]])) family_entries[[id]] <- entry
      for (key in unlist(entry[["source_keys"]], use.names = FALSE)) key_families[[key]] <- id
    }
    identity <- list(); lineage <- list()
    for (key in present) {
      originals <- catalog[keys == key]
      duplicate <- length(originals) > 1L
      if (duplicate) add('duplicate_source_identity', key)
      identity[[key]] <- if (duplicate) 'duplicate' else 'unique'
      id <- key_families[[key]]
      if (is.null(id)) next
      entry <- family_entries[[id]]
      supplied <- lapply(originals, function(row) row[["canonical_resource_id"]])
      invalid <- any(vapply(supplied, function(value) !is.null(value) && !(string(value) || (length(value) == 1L && is.na(value))), logical(1)))
      claims <- unique(unlist(Filter(nonblank, supplied), use.names = FALSE))
      declared <- entry[["canonical_resource_id"]]
      conflict <- invalid || length(claims) > 1L || (!is.null(declared) && length(claims) && any(claims != declared))
      lineage[[key]] <- if (conflict) 'conflicting' else if (is.null(declared)) 'unestablished' else 'established'
      if (conflict) add('canonical_lineage_conflict', key, id)
    }
    family_states <- list()
    for (id in names(family_entries)) {
      found <- intersect(unlist(family_entries[[id]][["source_keys"]], use.names = FALSE), present)
      family_states[[id]] <- if (length(found) > 1L) 'multiple' else 'single'
      if (length(found) > 1L) add('multiple_family_identities', membership_id = id)
    }
    for (panel in membership_spec[["panels"]]) for (entry in panel[["sources"]]) {
      for (key in unlist(entry[["source_keys"]], use.names = FALSE)) {
        if (!key %in% present) next
        originals <- catalog[keys == key]
        status <- if (identity[[key]] == 'unique' && string(originals[[1]][["load_status"]])) originals[[1]][["load_status"]] else NULL
        load_state <- if (!is.null(status) && status %in% c('ok', 'loaded')) 'loaded' else if (!is.null(status) && status %in% c('failed', 'mapped', 'not_loaded', 'not_tested', 'not_attempted', 'unavailable')) 'not_loaded' else 'unknown'
        canonical <- if (lineage[[key]] == 'established') entry[["canonical_resource_id"]] else NULL
        rows[[length(rows) + 1L]] <- list(
          panel_id = panel[["panel_id"]], membership_id = entry[["membership_id"]], source_key = key,
          canonical_resource_id = canonical, membership_role = entry[["membership_role"]],
          evidence_layer = entry[["evidence_layer"]], catalog_identity_state = identity[[key]],
          canonical_lineage_state = lineage[[key]], family_identity_state = family_states[[entry[["membership_id"]]]],
          load_status = status, load_state = load_state)
      }
    }
  }
  if (length(diagnostics) > 100L) diagnostics <- c(diagnostics[seq_len(100L)], list(list(code = 'diagnostics_truncated', source_key = NULL, membership_id = NULL)))
  list(schema_version = 1L, inventory_version = membership_spec[["inventory_version"]],
       basis = 'reviewed_exact_source_inventory', evidence_origin = evidence_origin,
       inventory_state = state, rows = rows, diagnostics = diagnostics)
}

clinical_source_rows_for_panel <- function(inventory, panel_id) {
  Filter(function(row) identical(row[["panel_id"]], panel_id), inventory[["rows"]])
}

clinical_source_frame_for_panel <- function(sources, inventory, panel_id) {
  keys <- vapply(clinical_source_rows_for_panel(inventory, panel_id), function(row) row[["source_key"]], character(1))
  if (!is.data.frame(sources) || !'table_name' %in% names(sources)) return(data.frame())
  # Keep all original duplicate rows inspectable; never choose a count-bearing row.
  sources[!is.na(sources[["table_name"]]) & sources[["table_name"]] %in% keys, , drop = FALSE]
}
