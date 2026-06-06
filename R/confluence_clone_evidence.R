confluence_clone_empty_sources <- function() {
  empty_df(
    route_id = character(),
    route_family = character(),
    axis = character(),
    state_id = character(),
    evidence_tier = character(),
    source_id = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    person_key_column = character(),
    date_columns = character(),
    code_column = character(),
    code_values = character(),
    required_columns = character(),
    optional_columns = character(),
    local_validation_status = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    aggregate_only = logical(),
    text_suppression_required = logical(),
    fail_closed_behavior = character(),
    route_query_mode = character(),
    route_label = character(),
    caveat = character()
  )
}

confluence_clone_empty_lint <- function() {
  empty_df(
    lint_id = character(),
    route_id = character(),
    severity = character(),
    field = character(),
    status = character(),
    message = character()
  )
}

confluence_clone_empty_route_manifest <- function() {
  empty_df(
    route_id = character(),
    axis = character(),
    state_id = character(),
    source_id = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    table_resolved = logical(),
    required_columns = character(),
    resolved_columns = character(),
    missing_required_columns = character(),
    optional_columns_present = character(),
    optional_columns_missing = character(),
    date_column_used = character(),
    person_key_column_used = character(),
    route_status = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    fail_closed_reason = character()
  )
}

confluence_clone_empty_source_resolution <- function() {
  empty_df(
    route_id = character(),
    route_family = character(),
    axis = character(),
    state_id = character(),
    evidence_tier = character(),
    source_id = character(),
    table = character(),
    route_status = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    local_validation_status = character(),
    route_query_mode = character(),
    fail_closed_reason = character(),
    caveat = character()
  )
}

confluence_clone_empty_evidence_counts <- function() {
  empty_df(
    axis = character(),
    state_id = character(),
    state_label = character(),
    route_family = character(),
    route_id = character(),
    evidence_tier = character(),
    overlap_basis = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    route_status = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    ambiguity_flag = character(),
    suppression_status = character(),
    caveat = character()
  )
}

confluence_clone_empty_ambiguity_counts <- function() {
  empty_df(
    ambiguity_id = character(),
    route_family = character(),
    route_id = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_tier = character(),
    overlap_basis = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    ambiguity_flag = character(),
    suppression_status = character(),
    caveat = character()
  )
}

confluence_clone_empty_mgus_waterfall <- function() {
  empty_df(
    waterfall_id = character(),
    step_order = integer(),
    step_label = character(),
    evidence_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    overlap_basis = character(),
    usable_for_primary_overlap = logical(),
    ambiguity_flag = character(),
    suppression_status = character(),
    caveat = character()
  )
}

confluence_clone_empty_overlap_counts <- function() {
  empty_df(
    overlap_id = character(),
    overlap_label = character(),
    mbl_tier = character(),
    pcd_tier = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    evidence_tier = character(),
    overlap_basis = character(),
    usable_for_primary_overlap = logical(),
    usable_for_sensitivity_overlap = logical(),
    ambiguity_flag = character(),
    bcell_entry_route_id = character(),
    pcd_entry_route_id = character(),
    date_anchor_used = character(),
    endpoint_definition_status = character(),
    notes = character()
  )
}

confluence_clone_empty_overlap_timing <- function() {
  empty_df(
    timing_id = character(),
    timing_label = character(),
    classification_id = character(),
    bcell_entry_route_id = character(),
    pcd_entry_route_id = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    acceptance_status = character(),
    query_status = character(),
    acceptance_gate_status = character(),
    suppression_status = character(),
    candidate_date = character(),
    supporting_date = character(),
    accepted_clone_date = character(),
    overlap_entry_date = character(),
    notes = character()
  )
}

confluence_clone_empty_exclusion_reasons <- function() {
  empty_df(
    exclusion_reason = character(),
    reason_label = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_tier = character(),
    overlap_basis = character(),
    usable_for_primary_overlap = logical(),
    ambiguity_flag = character(),
    suppression_status = character(),
    caveat = character()
  )
}

confluence_clone_empty_protocol_runway <- function() {
  empty_df(
    runway_id = character(),
    workstream = character(),
    route_family = character(),
    current_gate = character(),
    next_protocol_move = character(),
    priority = character(),
    caveat = character()
  )
}

confluence_clone_empty_outputs <- function() {
  list(
    clone_route_manifest = confluence_clone_empty_route_manifest(),
    clone_source_resolution = confluence_clone_empty_source_resolution(),
    bcell_clone_evidence_counts = confluence_clone_empty_evidence_counts(),
    pcd_clone_evidence_counts = confluence_clone_empty_evidence_counts(),
    paraprotein_ambiguity_counts = confluence_clone_empty_ambiguity_counts(),
    mgus_reclassification_waterfall = confluence_clone_empty_mgus_waterfall(),
    dual_clone_overlap_counts = confluence_clone_empty_overlap_counts(),
    dual_clone_overlap_timing = confluence_clone_empty_overlap_timing(),
    primary_overlap_exclusion_reasons = confluence_clone_empty_exclusion_reasons(),
    clone_availability_protocol_runway = confluence_clone_empty_protocol_runway()
  )
}

confluence_clone_split <- function(x) {
  x <- paste(as.character(x %||% ""), collapse = ";")
  out <- trimws(unlist(strsplit(x, ";", fixed = TRUE), use.names = FALSE))
  out[nzchar(out)]
}

confluence_clone_bool <- function(x) {
  if (exists("confluence_count_bool", mode = "function")) return(confluence_count_bool(x))
  tolower(trimws(as.character(x %||% ""))) %in% c("true", "t", "1", "yes", "y")
}

confluence_clone_read_sources <- function(project_root = ".") {
  path <- file.path(project_root, "config", "confluence_clone_evidence_sources.tsv")
  if (!file.exists(path)) return(confluence_clone_empty_sources())
  rows <- tryCatch(read_delimited_file(path), error = function(e) confluence_clone_empty_sources())
  if (!is.data.frame(rows) || !nrow(rows)) return(confluence_clone_empty_sources())
  empty <- confluence_clone_empty_sources()
  for (nm in setdiff(names(empty), names(rows))) {
    rows[[nm]] <- if (is.logical(empty[[nm]])) FALSE else ""
  }
  rows <- rows[names(empty)]
  chr <- names(rows)[!vapply(rows, is.logical, logical(1))]
  for (nm in chr) rows[[nm]] <- trimws(as.character(rows[[nm]] %||% ""))
  for (nm in c("usable_for_primary_overlap", "usable_for_sensitivity_overlap", "aggregate_only", "text_suppression_required")) {
    rows[[nm]] <- confluence_clone_bool(rows[[nm]])
  }
  rows
}

confluence_clone_allowed_axes <- function() c("bcell", "pcd", "ambiguity", "compatibility")

confluence_clone_allowed_tiers <- function() {
  c(
    "accepted", "registry_supported", "direct_clone_supported", "supporting",
    "probable", "candidate", "ambiguous", "unvalidated", "unavailable",
    "exclusion_pressure"
  )
}

confluence_clone_allowed_validation <- function() {
  c("validated_primary", "validated_supporting", "candidate_review", "excluded", "not_applicable")
}

confluence_clone_lint_sources <- function(routes, fail = FALSE) {
  rows <- list()
  add <- function(route_id, field, message, lint_id = field) {
    rows[[length(rows) + 1L]] <<- data.frame(
      lint_id = lint_id,
      route_id = route_id %||% "",
      severity = "error",
      field = field,
      status = "fail",
      message = message,
      stringsAsFactors = FALSE
    )
  }
  if (!is.data.frame(routes) || !nrow(routes)) {
    add("", "config", "config/confluence_clone_evidence_sources.tsv is missing or empty.")
  } else {
    required <- names(confluence_clone_empty_sources())
    missing <- setdiff(required, names(routes))
    for (nm in missing) add("", nm, paste("Config is missing required column:", nm), "missing_column")
    if (!length(missing)) {
      duplicated_routes <- unique(routes$route_id[duplicated(routes$route_id) | !nzchar(routes$route_id)])
      for (route_id in duplicated_routes) add(route_id, "route_id", "route_id must be present and unique.")
      for (i in seq_len(nrow(routes))) {
        row <- routes[i, , drop = FALSE]
        route_id <- row$route_id[[1]] %||% ""
        if (!row$axis[[1]] %in% confluence_clone_allowed_axes()) add(route_id, "axis", "axis is not allowed.")
        if (!row$evidence_tier[[1]] %in% confluence_clone_allowed_tiers()) add(route_id, "evidence_tier", "evidence_tier is not allowed.")
        if (!row$local_validation_status[[1]] %in% confluence_clone_allowed_validation()) add(route_id, "local_validation_status", "local_validation_status is not allowed.")
        for (nm in c("source_id", "table", "person_key_column", "date_columns", "required_columns", "fail_closed_behavior")) {
          if (!nzchar(row[[nm]][[1]] %||% "")) add(route_id, nm, paste(nm, "must not be empty."))
        }
        state <- tolower(paste(route_id, row$state_id[[1]], row$route_label[[1]], collapse = " "))
        if (isTRUE(row$usable_for_primary_overlap[[1]]) &&
            (grepl("mgus", state) || grepl("igm", state) || row$evidence_tier[[1]] %in% c("candidate", "ambiguous", "unvalidated", "unavailable", "exclusion_pressure"))) {
          add(route_id, "usable_for_primary_overlap", "Candidate, ambiguous, unvalidated, unavailable, exclusion, MGUS-code-only, and IgM-only routes cannot be primary-usable.")
        }
        raw_text_cols <- c("OBS_DIAGNOSIS", "PHENOTYPE", "CONCLUSION", "POPULATION", "v_fritekst", "resulttextvalue")
        used_text <- any(tolower(confluence_clone_split(paste(row$required_columns, row$optional_columns, collapse = ";"))) %in% tolower(raw_text_cols))
        if (used_text && (!isTRUE(row$aggregate_only[[1]]) || !isTRUE(row$text_suppression_required[[1]]))) {
          add(route_id, "text_suppression_required", "Routes touching raw/text-like fields must be aggregate-only and text-suppressed.")
        }
      }
    }
  }
  out <- confluence_match_empty(bind_rows_base(rows), confluence_clone_empty_lint())
  if (isTRUE(fail) && nrow(out)) {
    stop(paste(out$message, collapse = " | "), call. = FALSE)
  }
  out
}

confluence_clone_numeric_clean <- function(x) {
  original <- as.character(x)
  original[is.na(x)] <- NA_character_
  txt <- trimws(tolower(original))
  txt[is.na(txt)] <- NA_character_
  txt_ascii <- suppressWarnings(iconv(txt, from = "", to = "ASCII//TRANSLIT"))
  txt_ascii[is.na(txt_ascii)] <- txt[is.na(txt_ascii)]
  negative <- !is.na(txt) & (
    txt %in% c("neg", "negative", "ikke pavist", "ikke paavist", "not detected", "no", "nej") |
      txt_ascii %in% c("neg", "negative", "ikke pavist", "ikke paavist", "not detected", "no", "nej") |
      grepl("^ikke\\s+p.*vist$", txt_ascii)
  )
  blank <- is.na(txt) | !nzchar(txt)
  comparator <- ifelse(grepl("^<", txt %||% ""), "<", ifelse(grepl("^>", txt %||% ""), ">", ""))
  clean <- gsub(",", ".", txt, fixed = TRUE)
  clean <- gsub("[^0-9.+-]", "", clean)
  value <- suppressWarnings(as.numeric(clean))
  value[negative] <- NA_real_
  status <- rep("parsed", length(txt))
  status[blank] <- "missing"
  status[negative] <- "coded_negative"
  status[!blank & !negative & is.na(value)] <- "malformed"
  caveat <- rep("", length(txt))
  caveat[comparator == "<" & !is.na(value)] <- "lower-than comparator retained as numeric boundary; do not recode as zero."
  caveat[comparator == ">" & !is.na(value)] <- "greater-than comparator retained as numeric boundary."
  caveat[status == "malformed"] <- "Malformed numeric value; treated as NA."
  caveat[status == "coded_negative"] <- "Validated negative categorical value; not converted to zero."
  data.frame(
    original = original,
    numeric_value = value,
    numeric_status = status,
    comparator = comparator,
    caveat = caveat,
    stringsAsFactors = FALSE
  )
}

numeric_clean <- confluence_clone_numeric_clean

confluence_clone_source_record <- function(route, relaxed = FALSE) {
  data.frame(
    table_name = route$source_id[[1]] %||% route$table[[1]] %||% "",
    source = route$source_id[[1]] %||% route$table[[1]] %||% "",
    source_type = "dataset",
    db_name = if (isTRUE(relaxed)) "" else (route$db_name[[1]] %||% ""),
    schema = if (isTRUE(relaxed)) "" else (route$schema[[1]] %||% ""),
    table = route$table[[1]] %||% "",
    known_aliases = paste(unique(c(route$source_id[[1]], route$table[[1]])), collapse = ";"),
    stringsAsFactors = FALSE
  )
}

confluence_clone_match_source_location <- function(route, tables) {
  if (!is.data.frame(tables) || !nrow(tables)) return(tables)
  if (exists("match_table_location", mode = "function")) {
    strict <- match_table_location(confluence_clone_source_record(route, relaxed = FALSE), tables)
    if (nrow(strict)) return(strict)
    return(match_table_location(confluence_clone_source_record(route, relaxed = TRUE), tables))
  }
  key <- tolower(as.character(tables$table %||% ""))
  candidates <- unique(tolower(c(route$table[[1]], route$source_id[[1]])))
  tables[key %in% candidates, , drop = FALSE]
}

confluence_clone_table_columns <- function(db_adapter, db_name, schema, table) {
  if (is.null(db_adapter) || !is.function(db_adapter$table_schema)) return(character())
  cols <- tryCatch(db_adapter$table_schema(db_name, schema, table), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(cols) || !nrow(cols)) return(character())
  hit <- intersect(c("column_name", "name", "column"), names(cols))[1] %||% NA_character_
  if (is.na(hit)) return(character())
  trimws(as.character(cols[[hit]]))
}

confluence_clone_resolve_routes <- function(db_adapter = NULL, project_root = ".") {
  routes <- confluence_clone_read_sources(project_root)
  lint <- confluence_clone_lint_sources(routes)
  if (!is.data.frame(routes) || !nrow(routes)) {
    return(list(routes = routes, manifest = confluence_clone_empty_route_manifest(), lint = lint))
  }
  tables <- if (exists("adapter_list_tables", mode = "function")) adapter_list_tables(db_adapter) else data.frame(db_name = character(), schema = character(), table = character(), stringsAsFactors = FALSE)
  manifest <- lapply(seq_len(nrow(routes)), function(i) {
    route <- routes[i, , drop = FALSE]
    db <- route$db_name[[1]] %||% ""
    schema <- route$schema[[1]] %||% ""
    table <- route$table[[1]] %||% ""
    table_resolved <- FALSE
    status <- "unavailable"
    reason <- "No DB catalog was available; route failed closed before contribution."
    if (is.data.frame(tables) && nrow(tables)) {
      matches <- confluence_clone_match_source_location(route, tables)
      if (nrow(matches) == 1L) {
        db <- matches$db_name[[1]]
        schema <- matches$schema[[1]]
        table <- matches$table[[1]]
        table_resolved <- TRUE
        status <- "missing_required_columns"
        reason <- "Column schema was unavailable or missing required columns."
      } else if (nrow(matches) > 1L) {
        status <- "ambiguous_table"
        reason <- paste("Multiple tables matched:", paste(matches$db_name, matches$schema, matches$table, sep = ".", collapse = "; "))
      } else {
        status <- "missing_table"
        reason <- "No live DB catalog table matched this route."
      }
    }
    cols <- if (table_resolved) confluence_clone_table_columns(db_adapter, db, schema, table) else character()
    required <- unique(c(route$person_key_column[[1]], confluence_clone_split(route$date_columns[[1]]), confluence_clone_split(route$required_columns[[1]]), route$code_column[[1]]))
    required <- required[nzchar(required)]
    optional <- confluence_clone_split(route$optional_columns[[1]])
    cols_key <- tolower(cols)
    resolved_required <- required[tolower(required) %in% cols_key]
    missing_required <- setdiff(required, resolved_required)
    optional_present <- optional[tolower(optional) %in% cols_key]
    optional_missing <- setdiff(optional, optional_present)
    date_used <- confluence_clone_split(route$date_columns[[1]])
    date_used <- date_used[tolower(date_used) %in% cols_key][1] %||% ""
    person_used <- if (tolower(route$person_key_column[[1]]) %in% cols_key) route$person_key_column[[1]] else ""
    if (table_resolved && length(cols) && !length(missing_required)) {
      status <- "usable"
      reason <- ""
    } else if (table_resolved && !length(cols)) {
      status <- "schema_unavailable"
      reason <- "Table resolved, but column schema was unavailable; route failed closed."
    }
    data.frame(
      route_id = route$route_id,
      axis = route$axis,
      state_id = route$state_id,
      source_id = route$source_id,
      db_name = db,
      schema = schema,
      table = table,
      table_resolved = table_resolved,
      required_columns = paste(required, collapse = ";"),
      resolved_columns = paste(resolved_required, collapse = ";"),
      missing_required_columns = paste(missing_required, collapse = ";"),
      optional_columns_present = paste(optional_present, collapse = ";"),
      optional_columns_missing = paste(optional_missing, collapse = ";"),
      date_column_used = date_used,
      person_key_column_used = person_used,
      route_status = status,
      usable_for_primary_overlap = isTRUE(route$usable_for_primary_overlap[[1]]) && identical(status, "usable"),
      usable_for_sensitivity_overlap = isTRUE(route$usable_for_sensitivity_overlap[[1]]) && identical(status, "usable"),
      fail_closed_reason = reason,
      stringsAsFactors = FALSE
    )
  })
  list(
    routes = routes,
    manifest = confluence_match_empty(bind_rows_base(manifest), confluence_clone_empty_route_manifest()),
    lint = lint
  )
}

confluence_clone_hook_manifest <- function(routes, evidence = data.frame(stringsAsFactors = FALSE)) {
  if (!is.data.frame(routes) || !nrow(routes)) return(confluence_clone_empty_route_manifest())
  observed <- unique(as.character(evidence$route_id %||% character()))
  rows <- lapply(seq_len(nrow(routes)), function(i) {
    route <- routes[i, , drop = FALSE]
    usable <- route$route_id[[1]] %in% observed
    data.frame(
      route_id = route$route_id,
      axis = route$axis,
      state_id = route$state_id,
      source_id = route$source_id,
      db_name = route$db_name,
      schema = route$schema,
      table = route$table,
      table_resolved = usable,
      required_columns = route$required_columns,
      resolved_columns = if (usable) route$required_columns else "",
      missing_required_columns = if (usable) "" else route$required_columns,
      optional_columns_present = if (usable) route$optional_columns else "",
      optional_columns_missing = if (usable) "" else route$optional_columns,
      date_column_used = if (usable) confluence_clone_split(route$date_columns[[1]])[1] %||% "" else "",
      person_key_column_used = if (usable) route$person_key_column else "",
      route_status = if (usable) "usable" else "unavailable",
      usable_for_primary_overlap = isTRUE(route$usable_for_primary_overlap[[1]]) && usable,
      usable_for_sensitivity_overlap = isTRUE(route$usable_for_sensitivity_overlap[[1]]) && usable,
      fail_closed_reason = if (usable) "Secure aggregate hook supplied route-level evidence." else "No secure hook evidence was supplied for this route.",
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(rows), confluence_clone_empty_route_manifest())
}

confluence_clone_source_resolution <- function(routes, manifest) {
  if (!is.data.frame(routes) || !nrow(routes)) return(confluence_clone_empty_source_resolution())
  merged <- merge(
    routes,
    manifest[c("route_id", "route_status", "usable_for_primary_overlap", "usable_for_sensitivity_overlap", "fail_closed_reason")],
    by = "route_id",
    all.x = TRUE,
    suffixes = c("", ".manifest")
  )
  out <- data.frame(
    route_id = merged$route_id,
    route_family = merged$route_family,
    axis = merged$axis,
    state_id = merged$state_id,
    evidence_tier = merged$evidence_tier,
    source_id = merged$source_id,
    table = merged$table,
    route_status = merged$route_status %||% "unavailable",
    usable_for_primary_overlap = confluence_clone_bool(merged$usable_for_primary_overlap.manifest %||% FALSE),
    usable_for_sensitivity_overlap = confluence_clone_bool(merged$usable_for_sensitivity_overlap.manifest %||% FALSE),
    local_validation_status = merged$local_validation_status,
    route_query_mode = merged$route_query_mode,
    fail_closed_reason = merged$fail_closed_reason %||% "",
    caveat = merged$caveat,
    stringsAsFactors = FALSE
  )
  confluence_match_empty(out, confluence_clone_empty_source_resolution())
}

confluence_clone_normalize_evidence <- function(evidence, routes, manifest) {
  if (!is.data.frame(evidence) || !nrow(evidence)) {
    return(empty_df(
      person_key = character(), route_id = character(), evidence_date = as.Date(character()),
      axis = character(), state_id = character(), route_family = character(), evidence_tier = character()
    ))
  }
  names(evidence) <- tolower(names(evidence))
  if (!"person_key" %in% names(evidence) && "patientid" %in% names(evidence)) evidence$person_key <- evidence$patientid
  if (!"evidence_date" %in% names(evidence) && "first_date" %in% names(evidence)) evidence$evidence_date <- evidence$first_date
  if (!"evidence_date" %in% names(evidence) && "date" %in% names(evidence)) evidence$evidence_date <- evidence$date
  if (!all(c("person_key", "route_id", "evidence_date") %in% names(evidence))) {
    return(empty_df(
      person_key = character(), route_id = character(), evidence_date = as.Date(character()),
      axis = character(), state_id = character(), route_family = character(), evidence_tier = character()
    ))
  }
  usable_routes <- manifest$route_id[manifest$route_status == "usable"]
  rows <- evidence[nzchar(as.character(evidence$person_key)) & evidence$route_id %in% usable_routes, , drop = FALSE]
  if (!nrow(rows)) {
    return(empty_df(
      person_key = character(), route_id = character(), evidence_date = as.Date(character()),
      axis = character(), state_id = character(), route_family = character(), evidence_tier = character()
    ))
  }
  rows$person_key <- as.character(rows$person_key)
  rows$route_id <- as.character(rows$route_id)
  rows$evidence_date <- safe_as_date(rows$evidence_date)
  rows <- rows[!is.na(rows$evidence_date), , drop = FALSE]
  if (!nrow(rows)) {
    return(empty_df(
      person_key = character(), route_id = character(), evidence_date = as.Date(character()),
      axis = character(), state_id = character(), route_family = character(), evidence_tier = character()
    ))
  }
  route_meta <- merge(
    routes,
    manifest[c("route_id", "route_status", "usable_for_primary_overlap", "usable_for_sensitivity_overlap")],
    by = "route_id",
    all.x = TRUE,
    suffixes = c(".config", "")
  )
  out <- merge(rows[c("person_key", "route_id", "evidence_date")], route_meta, by = "route_id", all.x = TRUE)
  out[order(out$person_key, out$evidence_date, out$route_id), , drop = FALSE]
}

confluence_clone_legacy_evidence_from_first_dates <- function(first_dates) {
  rows <- confluence_count_normalize_first_dates(first_dates)
  if (!is.data.frame(rows) || !nrow(rows)) return(data.frame(stringsAsFactors = FALSE))
  route_for_state <- c(
    cll = "bcell_diag_cll_icd_c911",
    coded_mbl = "bcell_diag_mbl_icd_d479b",
    pathology_mbl = "bcell_pato_mbl_snomed_m98231",
    cll_morphology_pressure = "bcell_pato_cll_pressure_m98233",
    mgus = "pcd_diag_mgus_candidate",
    mm = "pcd_diag_mm_candidate"
  )
  rows$route_id <- unname(route_for_state[rows$state_id])
  rows <- rows[nzchar(rows$route_id %||% ""), , drop = FALSE]
  data.frame(
    person_key = rows$person_key,
    route_id = rows$route_id,
    evidence_date = rows$first_date,
    stringsAsFactors = FALSE
  )
}

confluence_clone_first <- function(rows, ix, date_col = "evidence_date") {
  hit <- rows[ix & !is.na(rows[[date_col]]), , drop = FALSE]
  if (!nrow(hit)) return(list(date = as.Date(NA), route_id = ""))
  hit <- hit[order(hit[[date_col]], hit$route_id), , drop = FALSE][1, , drop = FALSE]
  list(date = hit[[date_col]][[1]], route_id = hit$route_id[[1]])
}

confluence_clone_person_summary <- function(evidence) {
  if (!is.data.frame(evidence) || !nrow(evidence)) {
    return(empty_df(
      person_key = character(), classification_id = character(), group_id = character(),
      group_label = character(), entry_date = as.Date(character())
    ))
  }
  people <- unique(evidence$person_key)
  rows <- lapply(people, function(person) {
    ev <- evidence[evidence$person_key == person, , drop = FALSE]
    primary <- confluence_clone_bool(ev$usable_for_primary_overlap)
    sensitivity <- confluence_clone_bool(ev$usable_for_sensitivity_overlap)
    tier <- as.character(ev$evidence_tier)
    state <- as.character(ev$state_id)
    axis <- as.character(ev$axis)
    bcell_accepted_ix <- axis == "bcell" & primary & tier %in% c("accepted", "direct_clone_supported")
    bcell_sens_ix <- axis == "bcell" & (primary | sensitivity) & tier %in% c("accepted", "direct_clone_supported", "supporting", "probable", "registry_supported")
    bcell_candidate_ix <- axis == "bcell" & tier == "candidate"
    pcd_strict_ix <- axis == "pcd" & primary & (tier %in% c("accepted", "direct_clone_supported") | state %in% c("pcd_flow_pathological_plasma_cells", "pcd_validated_plasma_cell_pathology", "pcd_plasmacytoma_support", "pcd_marrow_plasma_cell_infiltration"))
    pcd_registry_ix <- axis == "pcd" & state == "pcd_registry_supported" & sensitivity
    pcd_support_ix <- axis == "pcd" & sensitivity & tier %in% c("supporting", "probable", "direct_clone_supported", "accepted") & !pcd_registry_ix
    pcd_candidate_ix <- axis == "pcd" & tier %in% c("candidate", "unvalidated")
    igm_ambiguous_ix <- axis == "ambiguity" | tier == "ambiguous" | grepl("igm", state, ignore.case = TRUE)

    bcell_accepted <- confluence_clone_first(ev, bcell_accepted_ix)
    bcell_sens <- confluence_clone_first(ev, bcell_accepted_ix | bcell_sens_ix | bcell_candidate_ix)
    pcd_strict <- confluence_clone_first(ev, pcd_strict_ix)
    pcd_probable <- confluence_clone_first(ev, pcd_support_ix)
    pcd_candidate <- confluence_clone_first(ev, pcd_candidate_ix)
    igm_ambiguous <- confluence_clone_first(ev, igm_ambiguous_ix)
    registry <- confluence_clone_first(ev, pcd_registry_ix)
    support <- confluence_clone_first(ev, pcd_support_ix)

    registry_supported <- !is.na(registry$date) && !is.na(support$date)
    registry_supported_date <- if (registry_supported) max(registry$date, support$date) else as.Date(NA)
    accepted_pcd_date <- pcd_strict$date
    accepted_pcd_route <- pcd_strict$route_id
    accepted_pcd_basis <- "strict direct clone support"
    if (is.na(accepted_pcd_date) && registry_supported) {
      accepted_pcd_date <- registry_supported_date
      accepted_pcd_route <- paste(registry$route_id, support$route_id, sep = "+")
      accepted_pcd_basis <- "registry-supported plus independent support"
    }
    pcd_any <- !is.na(accepted_pcd_date) || !is.na(pcd_probable$date) || !is.na(pcd_candidate$date) || !is.na(igm_ambiguous$date) || !is.na(registry$date)
    bcell_any <- !is.na(bcell_sens$date)
    classification <- "neither_or_unclassified"
    entry <- as.Date(NA)
    bcell_route <- bcell_sens$route_id
    pcd_route <- ""
    overlap_basis <- "no overlap"
    if (!is.na(bcell_accepted$date) && !is.na(accepted_pcd_date)) {
      classification <- "accepted_dual_clone_overlap"
      entry <- max(bcell_accepted$date, accepted_pcd_date)
      bcell_route <- bcell_accepted$route_id
      pcd_route <- accepted_pcd_route
      overlap_basis <- accepted_pcd_basis
    } else if (!is.na(bcell_sens$date) && !is.na(pcd_probable$date)) {
      classification <- "probable_dual_clone_sensitivity"
      entry <- max(bcell_sens$date, pcd_probable$date)
      pcd_route <- pcd_probable$route_id
      overlap_basis <- "probable non-primary plasma-cell support"
    } else if (!is.na(bcell_sens$date) && !is.na(igm_ambiguous$date) && is.na(accepted_pcd_date) && is.na(pcd_probable$date)) {
      classification <- "ambiguous_bcell_paraprotein"
      entry <- max(bcell_sens$date, igm_ambiguous$date)
      pcd_route <- igm_ambiguous$route_id
      overlap_basis <- "IgM paraprotein without independent plasma-cell clone evidence"
    } else if (bcell_any && (!is.na(pcd_candidate$date) || !is.na(registry$date))) {
      classification <- "candidate_diagnosis_overlap"
      right_date <- min(c(pcd_candidate$date, registry$date), na.rm = TRUE)
      entry <- max(bcell_sens$date, right_date)
      pcd_route <- if (!is.na(pcd_candidate$date)) pcd_candidate$route_id else registry$route_id
      overlap_basis <- "candidate diagnosis or registry-support-only overlap"
    } else if (bcell_any) {
      classification <- "bcell_only"
      entry <- bcell_sens$date
      overlap_basis <- "B-cell clone evidence only"
    } else if (pcd_any) {
      classification <- "pcd_only"
      dates <- c(accepted_pcd_date, pcd_probable$date, pcd_candidate$date, registry$date, igm_ambiguous$date)
      entry <- min(dates, na.rm = TRUE)
      pcd_route <- c(accepted_pcd_route, pcd_probable$route_id, pcd_candidate$route_id, registry$route_id, igm_ambiguous$route_id)[which.min(dates)]
      overlap_basis <- "plasma-cell evidence only"
    }
    if (is.infinite(entry)) entry <- as.Date(NA)
    data.frame(
      person_key = person,
      classification_id = classification,
      group_id = classification,
      group_label = confluence_clone_classification_label(classification),
      entry_date = entry,
      bcell_accepted_date = bcell_accepted$date,
      pcd_accepted_date = accepted_pcd_date,
      pcd_probable_date = pcd_probable$date,
      pcd_candidate_date = pcd_candidate$date,
      pcd_supporting_date = support$date,
      bcell_entry_route_id = bcell_route,
      pcd_entry_route_id = pcd_route,
      overlap_basis = overlap_basis,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

confluence_clone_classification_label <- function(id) {
  labels <- c(
    accepted_dual_clone_overlap = "Accepted dual-clone cohort: accepted B-cell clone + accepted plasma-cell clone",
    probable_dual_clone_sensitivity = "Probable dual-clone sensitivity cohort",
    ambiguous_bcell_paraprotein = "Ambiguous B-cell paraprotein",
    candidate_diagnosis_overlap = "Candidate diagnosis overlap",
    bcell_only = "B-cell clone only",
    pcd_only = "Plasma-cell clone/evidence only",
    neither_or_unclassified = "Neither or unclassified"
  )
  unname(labels[[id]] %||% id)
}

confluence_clone_group_entries <- function(person_summary) {
  if (!is.data.frame(person_summary) || !nrow(person_summary)) {
    return(empty_df(person_key = character(), group_id = character(), group_label = character(), entry_date = as.Date(character())))
  }
  rows <- person_summary[!is.na(person_summary$entry_date), c("person_key", "group_id", "group_label", "entry_date"), drop = FALSE]
  rows[nzchar(rows$group_id), , drop = FALSE]
}

confluence_clone_count <- function(n, min_cell_count) {
  if (exists("confluence_count_suppress", mode = "function")) return(confluence_count_suppress(n, min_cell_count))
  confluence_suppress_count(n, min_cell_count)
}

confluence_clone_status <- function(count) {
  if (exists("confluence_count_status_from_suppression", mode = "function")) return(confluence_count_status_from_suppression(count))
  count$status %||% ""
}

confluence_clone_acceptance <- function(classification_id, evidence_tier = "") {
  if (identical(classification_id, "accepted_dual_clone_overlap")) return("accepted")
  if (identical(classification_id, "probable_dual_clone_sensitivity")) return("accepted sensitivity aggregate")
  "not accepted primary overlap"
}

confluence_clone_evidence_count_rows <- function(evidence, axis, min_cell_count = atlas_min_cell_count()) {
  empty <- confluence_clone_empty_evidence_counts()
  if (!is.data.frame(evidence) || !nrow(evidence)) return(empty)
  rows <- evidence[evidence$axis == axis, , drop = FALSE]
  if (!nrow(rows)) return(empty)
  keys <- unique(rows[c("axis", "state_id", "route_family", "route_id", "evidence_tier", "route_status", "usable_for_primary_overlap", "usable_for_sensitivity_overlap", "caveat")])
  out <- lapply(seq_len(nrow(keys)), function(i) {
    key <- keys[i, , drop = FALSE]
    people <- unique(rows$person_key[rows$route_id == key$route_id[[1]]])
    count <- confluence_clone_count(length(people), min_cell_count)
    data.frame(
      axis = key$axis,
      state_id = key$state_id,
      state_label = gsub("_", " ", key$state_id),
      route_family = key$route_family,
      route_id = key$route_id,
      evidence_tier = key$evidence_tier,
      overlap_basis = if (isTRUE(key$usable_for_primary_overlap[[1]])) "primary-eligible evidence route" else if (isTRUE(key$usable_for_sensitivity_overlap[[1]])) "sensitivity/candidate evidence route" else "not overlap-usable",
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people by route; no IDs emitted",
      acceptance_status = if (isTRUE(key$usable_for_primary_overlap[[1]])) "accepted route evidence" else "not accepted primary overlap",
      route_status = key$route_status,
      usable_for_primary_overlap = confluence_clone_bool(key$usable_for_primary_overlap),
      usable_for_sensitivity_overlap = confluence_clone_bool(key$usable_for_sensitivity_overlap),
      ambiguity_flag = if (key$evidence_tier[[1]] == "ambiguous") "ambiguous_bcell_paraprotein" else "",
      suppression_status = confluence_clone_status(count),
      caveat = key$caveat,
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(out), empty)
}

confluence_clone_overlap_count_rows <- function(person_summary, min_cell_count = atlas_min_cell_count()) {
  levels <- c("accepted_dual_clone_overlap", "probable_dual_clone_sensitivity", "ambiguous_bcell_paraprotein", "candidate_diagnosis_overlap", "bcell_only", "pcd_only", "neither_or_unclassified")
  rows <- lapply(levels, function(level) {
    people <- person_summary$person_key[person_summary$classification_id == level]
    count <- confluence_clone_count(length(unique(people)), min_cell_count)
    data.frame(
      overlap_id = level,
      overlap_label = confluence_clone_classification_label(level),
      mbl_tier = if (grepl("bcell|dual|candidate|ambiguous", level)) "accepted or candidate B-cell clone evidence" else "not applicable",
      pcd_tier = if (grepl("pcd|dual|candidate|ambiguous", level)) "accepted, probable, candidate, or ambiguous plasma-cell evidence" else "not applicable",
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = confluence_clone_acceptance(level),
      query_status = "executed",
      acceptance_gate_status = if (identical(level, "accepted_dual_clone_overlap")) "passed" else "not primary cohort",
      suppression_status = confluence_clone_status(count),
      evidence_tier = switch(level,
        accepted_dual_clone_overlap = "accepted",
        probable_dual_clone_sensitivity = "probable",
        ambiguous_bcell_paraprotein = "ambiguous",
        candidate_diagnosis_overlap = "candidate",
        bcell_only = "single-axis",
        pcd_only = "single-axis",
        "unclassified"
      ),
      overlap_basis = switch(level,
        accepted_dual_clone_overlap = "accepted B-cell clone plus accepted plasma-cell clone",
        probable_dual_clone_sensitivity = "accepted/supported B-cell evidence plus probable plasma-cell support",
        ambiguous_bcell_paraprotein = "IgM paraprotein with B-cell clone and no independent PCD evidence",
        candidate_diagnosis_overlap = "candidate diagnosis or registry-only overlap",
        bcell_only = "B-cell evidence without plasma-cell evidence",
        pcd_only = "plasma-cell evidence without B-cell evidence",
        "no qualifying evidence"
      ),
      usable_for_primary_overlap = identical(level, "accepted_dual_clone_overlap"),
      usable_for_sensitivity_overlap = level %in% c("accepted_dual_clone_overlap", "probable_dual_clone_sensitivity"),
      ambiguity_flag = if (identical(level, "ambiguous_bcell_paraprotein")) "ambiguous_bcell_paraprotein" else "",
      bcell_entry_route_id = "",
      pcd_entry_route_id = "",
      date_anchor_used = if (identical(level, "accepted_dual_clone_overlap")) "overlap entry date is later accepted clone date, not emitted" else "classification date not emitted",
      endpoint_definition_status = "not an infection endpoint",
      notes = if (identical(level, "accepted_dual_clone_overlap")) {
        "A person cannot enter accepted_dual_clone_overlap through candidate, ambiguous, unavailable, or unvalidated evidence."
      } else {
        "Classification row retained for feasibility cartography; not the primary cohort."
      },
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(rows), confluence_clone_empty_overlap_counts())
}

confluence_clone_timing_rows <- function(person_summary, min_cell_count = atlas_min_cell_count()) {
  rows <- person_summary[person_summary$classification_id %in% c("accepted_dual_clone_overlap", "probable_dual_clone_sensitivity"), , drop = FALSE]
  if (!nrow(rows)) return(confluence_clone_empty_overlap_timing())
  rows$timing_id <- "unknown_unavailable"
  diff_days <- as.numeric(rows$pcd_accepted_date - rows$bcell_accepted_date)
  rows$timing_id[!is.na(diff_days) & abs(diff_days) <= 90] <- "same_90_day_window"
  rows$timing_id[!is.na(diff_days) & abs(diff_days) > 90 & format(rows$bcell_accepted_date, "%Y") == format(rows$pcd_accepted_date, "%Y")] <- "same_calendar_year"
  rows$timing_id[!is.na(diff_days) & diff_days > 90] <- "bcell_first"
  rows$timing_id[!is.na(diff_days) & diff_days < -90] <- "pcd_first"
  keys <- unique(rows[c("timing_id", "classification_id", "bcell_entry_route_id", "pcd_entry_route_id")])
  out <- lapply(seq_len(nrow(keys)), function(i) {
    key <- keys[i, , drop = FALSE]
    n <- sum(rows$timing_id == key$timing_id[[1]] &
               rows$classification_id == key$classification_id[[1]] &
               rows$bcell_entry_route_id == key$bcell_entry_route_id[[1]] &
               rows$pcd_entry_route_id == key$pcd_entry_route_id[[1]], na.rm = TRUE)
    count <- confluence_clone_count(n, min_cell_count)
    accepted <- identical(key$classification_id[[1]], "accepted_dual_clone_overlap")
    data.frame(
      timing_id = key$timing_id,
      timing_label = gsub("_", " ", key$timing_id),
      classification_id = key$classification_id,
      bcell_entry_route_id = key$bcell_entry_route_id,
      pcd_entry_route_id = key$pcd_entry_route_id,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      acceptance_status = if (accepted) "accepted" else "accepted sensitivity aggregate",
      query_status = "executed",
      acceptance_gate_status = if (accepted) "passed" else "not primary cohort",
      suppression_status = confluence_clone_status(count),
      candidate_date = "not emitted",
      supporting_date = "not emitted",
      accepted_clone_date = "not emitted",
      overlap_entry_date = "not emitted",
      notes = "Timing is aggregated by entry route IDs; raw dates are not emitted.",
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(out), confluence_clone_empty_overlap_timing())
}

confluence_clone_ambiguity_rows <- function(evidence, person_summary, min_cell_count = atlas_min_cell_count()) {
  amb <- evidence[evidence$axis == "ambiguity" | evidence$evidence_tier == "ambiguous", , drop = FALSE]
  if (!nrow(amb)) return(confluence_clone_empty_ambiguity_counts())
  keys <- unique(amb[c("route_family", "route_id")])
  out <- lapply(seq_len(nrow(keys)), function(i) {
    key <- keys[i, , drop = FALSE]
    people <- unique(amb$person_key[amb$route_id == key$route_id[[1]]])
    count <- confluence_clone_count(length(people), min_cell_count)
    data.frame(
      ambiguity_id = "ambiguous_bcell_paraprotein",
      route_family = key$route_family,
      route_id = key$route_id,
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people with ambiguous paraprotein route",
      evidence_tier = "ambiguous",
      overlap_basis = "IgM paraprotein support is ambiguous in CLL/MBL unless independent plasma-cell evidence exists.",
      usable_for_primary_overlap = FALSE,
      usable_for_sensitivity_overlap = FALSE,
      ambiguity_flag = "ambiguous_bcell_paraprotein",
      suppression_status = confluence_clone_status(count),
      caveat = "Ambiguous rows are removed from headline accepted dual-clone counts unless independent PCD evidence exists.",
      stringsAsFactors = FALSE
    )
  })
  class_people <- unique(person_summary$person_key[person_summary$classification_id == "ambiguous_bcell_paraprotein"])
  count <- confluence_clone_count(length(class_people), min_cell_count)
  total <- data.frame(
    ambiguity_id = "ambiguous_bcell_paraprotein_classified",
    route_family = "classification",
    route_id = "",
    count_display = count$display,
    n_people = count$n_public,
    count_kind = "distinct people after hierarchy",
    evidence_tier = "ambiguous",
    overlap_basis = "B-cell clone plus IgM paraprotein without independent plasma-cell clone evidence.",
    usable_for_primary_overlap = FALSE,
    usable_for_sensitivity_overlap = FALSE,
    ambiguity_flag = "ambiguous_bcell_paraprotein",
    suppression_status = confluence_clone_status(count),
    caveat = "Hierarchy prevents double counting with accepted/probable dual-clone groups.",
    stringsAsFactors = FALSE
  )
  confluence_match_empty(bind_rows_base(c(out, list(total))), confluence_clone_empty_ambiguity_counts())
}

confluence_clone_mgus_waterfall <- function(evidence, person_summary, min_cell_count = atlas_min_cell_count()) {
  people_for <- function(ix) unique(evidence$person_key[ix])
  mgus <- people_for(evidence$state_id == "pcd_mgus_diagnosis_candidate")
  with_bcell <- intersect(mgus, person_summary$person_key[person_summary$classification_id %in% c("accepted_dual_clone_overlap", "probable_dual_clone_sensitivity", "ambiguous_bcell_paraprotein", "candidate_diagnosis_overlap", "bcell_only")])
  accepted <- person_summary$person_key[person_summary$classification_id == "accepted_dual_clone_overlap"]
  candidate_only <- setdiff(with_bcell, accepted)
  specs <- list(
    list("mgus_code_candidates", 1L, "MGUS diagnosis-code candidates", "candidate", mgus, "MGUS code only is candidate evidence."),
    list("mgus_with_bcell_clone", 2L, "MGUS code with B-cell evidence", "candidate", with_bcell, "Still not primary without independent plasma-cell clone evidence."),
    list("remove_accepted_direct_pcd", 3L, "Accepted dual clone after direct/registry-supported PCD evidence", "accepted", accepted, "Only accepted plasma-cell clone evidence can enter the primary cohort."),
    list("remaining_candidate_overlap", 4L, "Remaining MGUS-code overlap after primary gate", "candidate", candidate_only, "MGUS diagnosis-code overlap is a candidate signal, not accepted evidence of an independent plasma-cell clone.")
  )
  rows <- lapply(specs, function(spec) {
    count <- confluence_clone_count(length(unique(spec[[5]])), min_cell_count)
    data.frame(
      waterfall_id = spec[[1]],
      step_order = spec[[2]],
      step_label = spec[[3]],
      evidence_tier = spec[[4]],
      count_display = count$display,
      n_people = count$n_public,
      count_kind = "distinct people",
      overlap_basis = spec[[6]],
      usable_for_primary_overlap = identical(spec[[4]], "accepted"),
      ambiguity_flag = "",
      suppression_status = confluence_clone_status(count),
      caveat = spec[[6]],
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(rows), confluence_clone_empty_mgus_waterfall())
}

confluence_clone_exclusion_reason_rows <- function(evidence, manifest, person_summary, min_cell_count = atlas_min_cell_count()) {
  reason_people <- list()
  add_people <- function(reason, people) {
    people <- unique(people[nzchar(people)])
    if (!length(people)) return(invisible(NULL))
    reason_people[[reason]] <<- unique(c(reason_people[[reason]] %||% character(), people))
  }
  not_primary <- person_summary[person_summary$classification_id != "accepted_dual_clone_overlap", , drop = FALSE]
  if (nrow(not_primary)) {
    add_people("mgus_code_only", evidence$person_key[evidence$state_id == "pcd_mgus_diagnosis_candidate"])
    add_people("igm_mspike_only_with_bcell_clone", person_summary$person_key[person_summary$classification_id == "ambiguous_bcell_paraprotein"])
    add_people("mbl_code_only", evidence$person_key[evidence$state_id == "bcell_mbl_diagnosis_candidate"])
    add_people("pcd_registry_without_direct_clone_field", evidence$person_key[evidence$state_id == "pcd_registry_supported" & !evidence$person_key %in% person_summary$person_key[person_summary$classification_id == "accepted_dual_clone_overlap"]])
    add_people("pathology_code_unvalidated", evidence$person_key[evidence$local_validation_status %in% c("candidate_review", "validated_supporting") & evidence$route_family %in% c("pcd_pathology", "bcell_pathology")])
    add_people("flc_abnormality_only", evidence$person_key[evidence$state_id == "pcd_lab_flc_abnormal_probable"])
    add_people("mcomponent_untyped", evidence$person_key[evidence$state_id == "pcd_lab_mcomponent_untyped"])
  }
  add_manifest_reason <- function(reason, pattern) {
    bad <- manifest$route_id[manifest$route_status != "usable" & grepl(pattern, paste(manifest$route_id, manifest$source_id), ignore.case = TRUE)]
    if (length(bad)) reason_people[[reason]] <<- character()
  }
  add_manifest_reason("missing_lab_isotype_mapping", "lab|AlleProvesvar|biochemistry")
  add_manifest_reason("missing_flow_source", "flow")
  add_manifest_reason("missing_damyda_source", "damyda")
  add_manifest_reason("missing_patobank_source", "pato|SDS_pato")
  labels <- c(
    mgus_code_only = "MGUS diagnosis code only",
    igm_mspike_only_with_bcell_clone = "IgM paraprotein only with B-cell clone",
    mcomponent_untyped = "M-component untyped",
    flc_abnormality_only = "FLC abnormality only",
    mbl_code_only = "MBL diagnosis code only",
    pcd_registry_without_direct_clone_field = "PCD registry without direct clone field",
    pathology_code_unvalidated = "Pathology code unvalidated for primary use",
    missing_lab_isotype_mapping = "Missing lab/isotype mapping",
    missing_flow_source = "Missing flow source",
    missing_damyda_source = "Missing DaMyDa source",
    missing_patobank_source = "Missing PATOBANK source"
  )
  rows <- lapply(names(labels), function(reason) {
    people <- reason_people[[reason]] %||% character()
    n <- if (length(people)) length(unique(people)) else if (reason %in% names(reason_people)) NA_real_ else 0
    count <- confluence_clone_count(n, min_cell_count)
    data.frame(
      exclusion_reason = reason,
      reason_label = labels[[reason]],
      count_display = if (is.na(n)) "route failed closed" else count$display,
      n_people = if (is.na(n)) NA_real_ else count$n_public,
      count_kind = if (is.na(n)) "route-level blocker" else "distinct people",
      evidence_tier = "candidate_or_unavailable",
      overlap_basis = "primary overlap exclusion reason",
      usable_for_primary_overlap = FALSE,
      ambiguity_flag = if (identical(reason, "igm_mspike_only_with_bcell_clone")) "ambiguous_bcell_paraprotein" else "",
      suppression_status = if (is.na(n)) "not run" else confluence_clone_status(count),
      caveat = "Feasibility cartography; reasons are aggregate and may overlap.",
      stringsAsFactors = FALSE
    )
  })
  confluence_match_empty(bind_rows_base(rows), confluence_clone_empty_exclusion_reasons())
}

confluence_clone_protocol_runway <- function() {
  data.frame(
    runway_id = c("route_manifest", "snomed_validation_gate", "pcd_direct_support", "ambiguity_hierarchy", "leakage_scan", "numeric_parsing"),
    workstream = c("Route manifest", "SNOMED validation gate", "Direct PCD support", "Ambiguity hierarchy", "Leakage scan", "Numeric parsing"),
    route_family = c("all", "bcell_pathology;pcd_pathology", "pcd_damyda_direct;pcd_flow", "pcd_lab_ambiguity", "all public outputs", "damyda;flow;lab"),
    current_gate = c("All configured routes must resolve or fail closed.", "Primary use requires validated_primary.", "DaMyDa row alone is registry-supported only.", "Accepted/probable PCD overrides ambiguity; IgM-only remains ambiguous.", "No IDs/raw values/free text in public outputs.", "Malformed values become NA with caveat, not zero."),
    next_protocol_move = c("Review failed route manifest rows after production runs.", "Clinician/pathologist validation of Danish Patobank code context.", "Lock exact direct clone predicates in secure aggregate hook.", "Review ambiguous IgM paraprotein strata.", "Keep automated leakage tests in regression suite.", "Extend validated categorical negative dictionaries only with clinical sign-off."),
    priority = c("P0", "P0", "P0", "P0", "P0", "P1"),
    caveat = "Feasibility hardening output only; not a clinical analysis.",
    stringsAsFactors = FALSE
  )
}

confluence_clone_outputs_from_evidence <- function(evidence,
                                                   routes,
                                                   manifest,
                                                   min_cell_count = atlas_min_cell_count()) {
  if (!is.data.frame(routes) || !nrow(routes)) routes <- confluence_clone_empty_sources()
  if (!is.data.frame(manifest) || !nrow(manifest)) manifest <- confluence_clone_hook_manifest(routes, evidence)
  norm <- confluence_clone_normalize_evidence(evidence, routes, manifest)
  person_summary <- confluence_clone_person_summary(norm)
  list(
    clone_route_manifest = confluence_match_empty(manifest, confluence_clone_empty_route_manifest()),
    clone_source_resolution = confluence_clone_source_resolution(routes, manifest),
    bcell_clone_evidence_counts = confluence_clone_evidence_count_rows(norm, "bcell", min_cell_count = min_cell_count),
    pcd_clone_evidence_counts = confluence_clone_evidence_count_rows(norm, "pcd", min_cell_count = min_cell_count),
    paraprotein_ambiguity_counts = confluence_clone_ambiguity_rows(norm, person_summary, min_cell_count = min_cell_count),
    mgus_reclassification_waterfall = confluence_clone_mgus_waterfall(norm, person_summary, min_cell_count = min_cell_count),
    dual_clone_overlap_counts = confluence_clone_overlap_count_rows(person_summary, min_cell_count = min_cell_count),
    dual_clone_overlap_timing = confluence_clone_timing_rows(person_summary, min_cell_count = min_cell_count),
    primary_overlap_exclusion_reasons = confluence_clone_exclusion_reason_rows(norm, manifest, person_summary, min_cell_count = min_cell_count),
    clone_availability_protocol_runway = confluence_clone_protocol_runway(),
    internal_person_summary = person_summary,
    internal_clone_evidence = norm
  )
}

confluence_clone_placeholder_outputs <- function(project_root = ".", min_cell_count = atlas_min_cell_count()) {
  routes <- confluence_clone_read_sources(project_root)
  manifest <- confluence_clone_hook_manifest(routes, data.frame(stringsAsFactors = FALSE))
  out <- confluence_clone_outputs_from_evidence(data.frame(stringsAsFactors = FALSE), routes, manifest, min_cell_count = min_cell_count)
  out$internal_person_summary <- NULL
  out$internal_clone_evidence <- NULL
  out
}

confluence_clone_route_sql <- function(route) {
  mode <- route$route_query_mode[[1]] %||% "manifest_only"
  if (identical(mode, "manifest_only")) return("")
  person <- route$person_key_column[[1]] %||% ""
  date_expr <- confluence_count_date_expr_sql("x", route$date_columns[[1]] %||% "")
  if (!nzchar(person) || !nzchar(date_expr)) return("")
  source_ref <- confluence_count_source_ref(route)
  where <- c(paste0("x.", confluence_count_sql_ident(person), " is not null"), paste0(date_expr, " is not null"))
  if (mode %in% c("diagnosis_exact", "pathology_exact")) {
    code_col <- route$code_column[[1]] %||% ""
    values <- confluence_norm_code(confluence_clone_split(route$code_values[[1]]))
    if (!nzchar(code_col) || !length(values)) return("")
    code_expr <- confluence_count_norm_expr_sql("x", code_col)
    where <- c(where, paste0(code_expr, " in (", confluence_count_sql_quote_values(values), ")"))
  }
  paste0(
    "select x.", confluence_count_sql_ident(person), "::text as person_key,\n",
    "       '", gsub("'", "''", route$route_id[[1]], fixed = TRUE), "'::text as route_id,\n",
    "       min(", date_expr, ") as evidence_date\n",
    "from ", source_ref, " x\n",
    "where ", paste(where, collapse = "\n  and "), "\n",
    "group by x.", confluence_count_sql_ident(person), "::text;"
  )
}

confluence_clone_execute_routes <- function(db_adapter, routes, manifest) {
  usable <- routes[routes$route_id %in% manifest$route_id[manifest$route_status == "usable"], , drop = FALSE]
  if (!nrow(usable)) return(data.frame(stringsAsFactors = FALSE))
  rows <- list()
  for (i in seq_len(nrow(usable))) {
    route <- usable[i, , drop = FALSE]
    if (route$route_query_mode[[1]] %in% "manifest_only") next
    match <- manifest[manifest$route_id == route$route_id[[1]], , drop = FALSE][1, , drop = FALSE]
    route$resolved_db_name <- match$db_name[[1]]
    route$resolved_schema <- match$schema[[1]]
    route$resolved_table <- match$table[[1]]
    sql <- confluence_clone_route_sql(route)
    if (!nzchar(sql)) next
    result <- confluence_count_query_result(db_adapter, sql)
    if (!nzchar(result$error_class %||% "") && is.data.frame(result$data) && nrow(result$data)) {
      rows[[length(rows) + 1L]] <- result$data
    }
  }
  bind_rows_base(rows)
}
