ki67_db_empty_search_plan <- function() {
  empty_df(
    search_step = character(),
    resource_id = character(),
    schema = character(),
    table = character(),
    column = character(),
    column_type = character(),
    search_channel = character(),
    pattern = character(),
    reason = character(),
    privacy_risk = character(),
    query_planned = logical(),
    notes = character()
  )
}

ki67_db_empty_column_name_hits <- function() {
  empty_df(
    schema = character(),
    table = character(),
    column = character(),
    column_type = character(),
    matched_term = character(),
    likely_channel = character(),
    notes = character()
  )
}

ki67_db_empty_aeki_code_counts <- function() {
  empty_df(
    resource_id = character(),
    schema = character(),
    table = character(),
    column = character(),
    code = character(),
    parsed_percent = character(),
    aggregate_count = character(),
    distinct_patient_count_if_allowed = character(),
    year_min_if_allowed = character(),
    year_max_if_allowed = character(),
    validation_status = character(),
    notes = character()
  )
}

ki67_db_empty_p16_dual_stain_counts <- function() {
  empty_df(
    resource_id = character(),
    schema = character(),
    table = character(),
    column = character(),
    code = character(),
    interpretation = character(),
    aggregate_count = character(),
    notes = character()
  )
}

ki67_db_empty_text_pattern_counts <- function() {
  empty_df(
    resource_id = character(),
    schema = character(),
    table = character(),
    text_column = character(),
    pattern_name = character(),
    value_class = character(),
    aggregate_count = character(),
    numeric_value_min_if_aggregate_safe = character(),
    numeric_value_max_if_aggregate_safe = character(),
    notes = character()
  )
}

ki67_db_empty_registry_field_counts <- function() {
  empty_df(
    schema = character(),
    table = character(),
    field = character(),
    matched_term = character(),
    likely_value_type = character(),
    non_missing_count_if_allowed = character(),
    distinct_value_count_if_allowed = character(),
    aggregate_value_summary_if_allowed = character(),
    notes = character()
  )
}

ki67_db_empty_summary <- function() {
  empty_df(
    channel = character(),
    direct_evidence_found = logical(),
    numeric_percent_found = logical(),
    aggregate_count_total = character(),
    best_source = character(),
    evidence_strength = character(),
    mcl_triangle_relevance = character(),
    requires_manual_validation = logical(),
    next_action = character(),
    notes = character()
  )
}

ki67_empty_found_locations <- function() {
  empty_df(
    evidence_channel = character(),
    schema = character(),
    table = character(),
    column = character(),
    evidence_type = character(),
    direct_evidence_found = logical(),
    numeric_percent_found = logical(),
    aggregate_count_display = character(),
    small_cell_suppressed = logical(),
    readiness_impact = character(),
    next_validation_step = character(),
    notes = character()
  )
}

ki67_db_empty_outputs <- function() {
  list(
    query_templates = character(),
    search_plan = ki67_db_empty_search_plan(),
    column_name_hits = ki67_db_empty_column_name_hits(),
    aeki_code_counts = ki67_db_empty_aeki_code_counts(),
    p16_dual_stain_counts = ki67_db_empty_p16_dual_stain_counts(),
    text_pattern_counts = ki67_db_empty_text_pattern_counts(),
    registry_field_counts = ki67_db_empty_registry_field_counts(),
    summary = ki67_db_empty_summary(),
    found_locations = ki67_empty_found_locations()
  )
}

ki67_db_default_candidate_tables <- function() {
  c("pato", "SDS_pato", "t_mikro", "SDS_t_mikro_ny", "t_konk", "SDS_t_konk_ny", "RKKP_LYFO")
}

ki67_db_column_terms <- function() {
  c(
    "ki67", "ki_67", "ki-67", "mib1", "mib_1", "mib-1",
    "proliferation", "proliferationsindeks", "proliferations_index",
    "proliferationsaktivitet", "ihc", "immunhistokemi", "immunohistochemistry"
  )
}

ki67_db_code_column_terms <- function() {
  c("kode", "code", "snomed", "snomedkode", "raw_code", "c_snomedkode", "value", "vaerdi")
}

ki67_db_text_column_terms <- function() {
  c("tekst", "text", "mikro", "konk", "konklusion", "conclusion", "report", "narrative", "beskrivelse", "note")
}

ki67_db_registry_column_terms <- function() {
  c("ki67", "ki_67", "ki-67", "mib1", "mib_1", "proliferation", "proliferationsindeks", "ihc")
}

ki67_db_normalized_hit <- function(x, patterns) {
  x_norm <- ki67_normalize(x)
  patterns_norm <- unique(ki67_normalize(patterns))
  patterns_norm <- patterns_norm[nzchar(patterns_norm)]
  if (!length(patterns_norm)) return(FALSE)
  any(vapply(patterns_norm, function(pattern) grepl(pattern, x_norm, fixed = TRUE), logical(1)))
}

ki67_db_first_term <- function(x, patterns) {
  x_norm <- ki67_normalize(x)
  for (term in patterns) {
    term_norm <- ki67_normalize(term)
    if (nzchar(term_norm) && grepl(term_norm, x_norm, fixed = TRUE)) return(term)
  }
  ""
}

ki67_db_is_text_type <- function(column_type) {
  grepl("char|text|varchar|character|citext", tolower(as.character(column_type %||% "")))
}

ki67_db_suppress_count <- function(n, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  if (is.na(n_num)) return(list(display = "", suppressed = FALSE, numeric = NA_real_))
  if (n_num > 0 && n_num < min_cell_count) {
    return(list(display = paste0("<", min_cell_count), suppressed = TRUE, numeric = n_num))
  }
  list(display = format(n_num, scientific = FALSE, trim = TRUE), suppressed = FALSE, numeric = n_num)
}

ki67_db_source_map_candidates <- function(project_root = ".", outputs_dir = NULL, candidate_tables = ki67_db_default_candidate_tables()) {
  rows <- list()
  row_value <- function(df, i, candidates, default = "") {
    for (nm in candidates) {
      if (!nm %in% names(df)) next
      value <- trimws(as.character(df[[nm]][[i]] %||% ""))
      if (nzchar(value) && !is.na(value)) return(value)
    }
    default
  }
  add_candidate <- function(resource_id, schema, table, db_name = "", notes = "") {
    if (!nzchar(table %||% "")) return(NULL)
    rows[[length(rows) + 1L]] <<- data.frame(
      resource_id = resource_id %||% table,
      db_name = db_name %||% "",
      schema = ifelse(nzchar(schema %||% ""), schema, "public"),
      table = table,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }

  if (!is.null(outputs_dir) && dir.exists(outputs_dir)) {
    for (name in c("atlas_source_resolution.csv", "atlas_sources.csv")) {
      path <- file.path(outputs_dir, name)
      if (!file.exists(path)) next
      x <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
      if (!is.data.frame(x) || !nrow(x)) next
      table_col <- intersect(c("table", "suggested_table", "source", "table_name"), names(x))
      if (!length(table_col)) next
      text <- do.call(paste, c(lapply(intersect(c("table_name", "source", "canonical_resource_id", "source_key", "table", "suggested_table"), names(x)), function(nm) as.character(x[[nm]])), sep = " "))
      hit <- vapply(text, ki67_db_normalized_hit, logical(1), patterns = candidate_tables)
      if (!any(hit)) next
      for (i in which(hit)) {
        table <- row_value(x, i, c("table", "suggested_table", "source", "table_name"))
        schema <- row_value(x, i, c("schema", "suggested_schema"))
        db_name <- row_value(x, i, c("db_name", "suggested_db_name"))
        resource_id <- row_value(x, i, c("canonical_resource_id", "table_name", "source"), table)
        add_candidate(resource_id, schema, table, db_name, paste("Derived from", name))
      }
    }
  }

  for (path in c(
    file.path(project_root, "config", "source-map.dalycare64.restored.tsv"),
    file.path(project_root, "config", "source-map.dalycare.tsv")
  )) {
    if (!file.exists(path)) next
    x <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(x) || !nrow(x)) next
    text_cols <- intersect(c("table_name", "source", "source_key", "canonical_resource_id", "known_aliases", "table", "table_or_view"), names(x))
    text <- do.call(paste, c(lapply(text_cols, function(nm) as.character(x[[nm]])), sep = " "))
    hit <- vapply(text, ki67_db_normalized_hit, logical(1), patterns = candidate_tables)
    if (!any(hit)) next
    for (i in which(hit)) {
      table <- row_value(x, i, c("table", "table_or_view", "source", "table_name"))
      table <- strsplit(table, ";", fixed = TRUE)[[1]][[1]]
      schema <- row_value(x, i, c("schema"))
      db_name <- row_value(x, i, c("db_name"))
      resource_id <- row_value(x, i, c("canonical_resource_id", "table_name", "source"), table)
      add_candidate(resource_id, schema, table, db_name, paste("Derived from", basename(path)))
    }
  }

  if (!length(rows)) {
    fallback <- data.frame(
      resource_id = c("pato", "t_mikro", "t_konk", "RKKP_LYFO"),
      db_name = c("import", "import", "import", "import"),
      schema = "public",
      table = c("SDS_pato", "SDS_t_mikro_ny", "SDS_t_konk_ny", "RKKP_LYFO"),
      notes = "Fallback candidate; validate schema/table in production metadata.",
      stringsAsFactors = FALSE
    )
    return(fallback)
  }

  out <- unique(bind_rows_base(rows))
  out <- out[nzchar(out$table), , drop = FALSE]
  rownames(out) <- NULL
  out
}

ki67_db_candidate_columns <- function(resource_id, table) {
  key <- ki67_normalize(paste(resource_id, table))
  if (grepl("lyfo|rkkp", key)) {
    return(data.frame(
      column = ki67_db_registry_column_terms(),
      column_type = "candidate",
      search_channel = "structured_registry_fields",
      reason = "RKKP/LYFO registry field name candidate.",
      stringsAsFactors = FALSE
    ))
  }
  bind_rows_base(list(
    data.frame(
      column = c("c_snomedkode", "snomedkode", "code", "raw_code", "patobank_code", "kode", "value"),
      column_type = "candidate",
      search_channel = "danish_patobank_aeki_codes",
      reason = "Potential Patobank/SNOMED pathology code or value field.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      column = c("tekst", "mikrotekst", "konklusion", "report_text", "patologi_tekst", "narrative_text", "beskrivelse"),
      column_type = "candidate",
      search_channel = "pathology_text_patterns",
      reason = "Potential pathology report, microscopy, or conclusion text field.",
      stringsAsFactors = FALSE
    )
  ))
}

ki67_db_plan_from_candidates <- function(candidates) {
  rows <- list()
  for (i in seq_len(nrow(candidates))) {
    cols <- ki67_db_candidate_columns(candidates$resource_id[[i]], candidates$table[[i]])
    for (j in seq_len(nrow(cols))) {
      channel <- cols$search_channel[[j]]
      pattern <- switch(
        channel,
        danish_patobank_aeki_codes = "^(ÆKI|AEKI|Ã†KI)([0-9]{3})$",
        pathology_text_patterns = "Ki-67/MIB-1/proliferationsindeks aggregate text patterns",
        structured_registry_fields = paste(ki67_db_column_terms(), collapse = "|"),
        paste(ki67_db_column_terms(), collapse = "|")
      )
      rows[[length(rows) + 1L]] <- data.frame(
        search_step = channel,
        resource_id = candidates$resource_id[[i]],
        schema = candidates$schema[[i]],
        table = candidates$table[[i]],
        column = cols$column[[j]],
        column_type = cols$column_type[[j]],
        search_channel = channel,
        pattern = pattern,
        reason = cols$reason[[j]],
        privacy_risk = "low_if_aggregate_only",
        query_planned = TRUE,
        notes = candidates$notes[[i]] %||% "",
        stringsAsFactors = FALSE
      )
    }
  }
  unique(bind_rows_base(rows))[names(ki67_db_empty_search_plan())]
}

ki67_db_column_channel <- function(table, column, column_type = "") {
  text <- paste(table, column, column_type)
  if (ki67_db_normalized_hit(column, ki67_db_registry_column_terms())) return("structured_registry_fields")
  if (ki67_db_normalized_hit(column, ki67_db_code_column_terms())) return("danish_patobank_aeki_codes")
  if (ki67_db_normalized_hit(column, ki67_db_text_column_terms())) return("pathology_text_patterns")
  "column_name_metadata"
}

ki67_db_plan_from_metadata <- function(metadata, candidate_tables = ki67_db_default_candidate_tables()) {
  if (!is.data.frame(metadata) || !nrow(metadata)) return(ki67_db_empty_search_plan())
  rows <- lapply(seq_len(nrow(metadata)), function(i) {
    channel <- ki67_db_column_channel(metadata$table[[i]], metadata$column[[i]], metadata$column_type[[i]])
    data.frame(
      search_step = channel,
      resource_id = metadata$table[[i]],
      schema = metadata$schema[[i]],
      table = metadata$table[[i]],
      column = metadata$column[[i]],
      column_type = metadata$column_type[[i]],
      search_channel = channel,
      pattern = switch(
        channel,
        danish_patobank_aeki_codes = "^(ÆKI|AEKI|Ã†KI)([0-9]{3})$",
        pathology_text_patterns = "Ki-67/MIB-1/proliferationsindeks aggregate text patterns",
        structured_registry_fields = paste(ki67_db_column_terms(), collapse = "|"),
        paste(ki67_db_column_terms(), collapse = "|")
      ),
      reason = "Column confirmed in production metadata.",
      privacy_risk = "low_if_aggregate_only",
      query_planned = TRUE,
      notes = "Metadata-confirmed candidate column; aggregate-only query allowed.",
      stringsAsFactors = FALSE
    )
  })
  unique(bind_rows_base(rows))[names(ki67_db_empty_search_plan())]
}

ki67_db_quote_table <- function(conn, schema, table) {
  dbi_table_ref(conn, schema, table)
}

ki67_db_regex_literal <- function(conn, pattern) {
  as.character(DBI::dbQuoteString(conn, pattern))
}

ki67_db_query_for_plan_row <- function(row, conn = NULL, min_cell_count = 5L) {
  schema <- row$schema[[1]]
  table <- row$table[[1]]
  column <- row$column[[1]]
  channel <- row$search_channel[[1]]
  table_ref <- if (is.null(conn)) {
    paste0('"', schema, '"."', table, '"')
  } else {
    ki67_db_quote_table(conn, schema, table)
  }
  qcol <- if (is.null(conn)) paste0('"', column, '"') else as.character(DBI::dbQuoteIdentifier(conn, column))
  if (identical(channel, "danish_patobank_aeki_codes")) {
    return(paste0(
      "select ", qcol, "::text as code, count(*) as aggregate_count\n",
      "from ", table_ref, "\n",
      "where ", qcol, "::text ~* '^(ÆKI|AEKI|Ã†KI)[0-9]{3}$'\n",
      "group by ", qcol, "::text;"
    ))
  }
  if (identical(channel, "pathology_text_patterns")) {
    return(paste0(
      "select 'exact_numeric_percent' as value_class, count(*) as aggregate_count from ", table_ref,
      " where ", qcol, "::text ~* '(ki[-[:space:]]?67|mib[-[:space:]]?1|proliferationsindeks).{0,80}[0-9]{1,3}([,.][0-9]+)?[[:space:]]*%'\n",
      "union all\n",
      "select 'range_percent' as value_class, count(*) as aggregate_count from ", table_ref,
      " where ", qcol, "::text ~* '(ki[-[:space:]]?67|mib[-[:space:]]?1).{0,80}[0-9]{1,3}[[:space:]]*[-–][[:space:]]*[0-9]{1,3}[[:space:]]*%'\n",
      "union all\n",
      "select 'inequality_percent' as value_class, count(*) as aggregate_count from ", table_ref,
      " where ", qcol, "::text ~* '(ki[-[:space:]]?67|mib[-[:space:]]?1).{0,80}[<>≤≥][[:space:]]*[0-9]{1,3}([,.][0-9]+)?[[:space:]]*%'\n",
      "union all\n",
      "select 'qualitative_mention_only' as value_class, count(*) as aggregate_count from ", table_ref,
      " where ", qcol, "::text ~* '(ki[-[:space:]]?67|mib[-[:space:]]?1|proliferationsindeks).{0,80}(positiv|positive|farvning|immunhistokemi|ihc)'\n",
      "union all\n",
      "select 'unknown_or_not_stated' as value_class, count(*) as aggregate_count from ", table_ref,
      " where ", qcol, "::text ~* '(ki[-[:space:]]?67|mib[-[:space:]]?1|proliferationsindeks).{0,80}(ikke angivet|ukendt|unknown|not stated)';"
    ))
  }
  if (identical(channel, "structured_registry_fields")) {
    return(paste0(
      "select count(", qcol, ") as non_missing_count, count(distinct ", qcol, "::text) as distinct_value_count\n",
      "from ", table_ref, "\n",
      "where ", qcol, " is not null;"
    ))
  }
  paste0(
    "-- metadata-only column-name hit for ", schema, ".", table, ".", column, "\n",
    "select count(*) as aggregate_count from ", table_ref, " where ", qcol, " is not null;"
  )
}

ki67_db_query_templates <- function(search_plan) {
  if (!is.data.frame(search_plan) || !nrow(search_plan)) return(character())
  blocks <- lapply(seq_len(nrow(search_plan)), function(i) {
    row <- search_plan[i, , drop = FALSE]
    paste(
      paste0("-- search_step: ", row$search_step[[1]]),
      paste0("-- location: ", row$schema[[1]], ".", row$table[[1]], ".", row$column[[1]]),
      paste0("-- privacy: aggregate-only; suppress exact counts below configured threshold"),
      ki67_db_query_for_plan_row(row),
      sep = "\n"
    )
  })
  unlist(blocks, use.names = FALSE)
}

ki67_db_find_column_name_hits <- function(connections, candidate_tables = ki67_db_default_candidate_tables(), full_scan = FALSE) {
  if (!requireNamespace("DBI", quietly = TRUE) || !length(connections)) return(ki67_db_empty_column_name_hits())
  terms <- unique(c(ki67_db_column_terms(), ki67_db_code_column_terms(), ki67_db_text_column_terms()))
  rows <- list()
  for (db_name in names(connections)) {
    conn <- connections[[db_name]]
    known <- atlas_known_daly_db_schemas()
    schemas <- unique(known$schema[known$db_name == db_name])
    if (!length(schemas)) schemas <- unique(known$schema)
    schema_sql <- paste(as.character(DBI::dbQuoteString(conn, schemas)), collapse = ", ")
    term_clauses <- paste(vapply(terms, function(term) {
      paste0("lower(column_name) like ", DBI::dbQuoteString(conn, paste0("%", tolower(term), "%")))
    }, character(1)), collapse = " or ")
    table_clause <- ""
    if (!isTRUE(full_scan)) {
      table_clauses <- paste(vapply(candidate_tables, function(term) {
        paste0("lower(table_name) like ", DBI::dbQuoteString(conn, paste0("%", tolower(term), "%")))
      }, character(1)), collapse = " or ")
      table_clause <- paste0(" and (", table_clauses, ")")
    }
    sql <- paste0(
      "select table_schema as schema, table_name as table, column_name as column, data_type as column_type ",
      "from information_schema.columns where table_schema in (", schema_sql, ") and (", term_clauses, ")",
      table_clause,
      " order by table_schema, table_name, ordinal_position"
    )
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (is.data.frame(out) && nrow(out)) rows[[length(rows) + 1L]] <- out
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_db_empty_column_name_hits())
  out$matched_term <- vapply(out$column, ki67_db_first_term, character(1), patterns = terms)
  out$likely_channel <- vapply(seq_len(nrow(out)), function(i) {
    ki67_db_column_channel(out$table[[i]], out$column[[i]], out$column_type[[i]])
  }, character(1))
  out$notes <- "Metadata-only hit; not patient-level data."
  out[names(ki67_db_empty_column_name_hits())]
}

ki67_db_resolve_connection <- function(connections, db_name = "") {
  if (!length(connections)) return(NULL)
  if (nzchar(db_name %||% "") && db_name %in% names(connections)) return(connections[[db_name]])
  connections[[1]]
}

ki67_db_connection_for_location <- function(connections, schema, table) {
  if (!requireNamespace("DBI", quietly = TRUE) || !length(connections)) return(NULL)
  for (nm in names(connections)) {
    conn <- connections[[nm]]
    sql <- paste0(
      "select 1 as found from information_schema.tables where table_schema = ",
      DBI::dbQuoteString(conn, schema),
      " and table_name = ",
      DBI::dbQuoteString(conn, table),
      " limit 1"
    )
    hit <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (is.data.frame(hit) && nrow(hit)) return(conn)
  }
  connections[[1]]
}

ki67_db_execute_aeki_counts <- function(connections, search_plan, min_cell_count = 5L) {
  rows <- list()
  x <- search_plan[search_plan$search_channel == "danish_patobank_aeki_codes", , drop = FALSE]
  if (!nrow(x) || !length(connections)) return(ki67_db_empty_aeki_code_counts())
  for (i in seq_len(nrow(x))) {
    conn <- ki67_db_connection_for_location(connections, x$schema[[i]], x$table[[i]])
    sql <- ki67_db_query_for_plan_row(x[i, , drop = FALSE], conn = conn, min_cell_count = min_cell_count)
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out) || !nrow(out)) next
    for (j in seq_len(nrow(out))) {
      parsed <- ki67_parse_patobank_numeric_percent(out$code[[j]])
      if (is.na(parsed)) next
      count <- ki67_db_suppress_count(out$aggregate_count[[j]], min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(
        resource_id = x$resource_id[[i]],
        schema = x$schema[[i]],
        table = x$table[[i]],
        column = x$column[[i]],
        code = ki67_clean_code_text(out$code[[j]]),
        parsed_percent = as.character(parsed),
        aggregate_count = count$display,
        distinct_patient_count_if_allowed = "",
        year_min_if_allowed = "",
        year_max_if_allowed = "",
        validation_status = if (count$suppressed) "suppressed_small_cell" else "aggregate_count_available",
        notes = if (count$suppressed) "Exact small count suppressed." else "Aggregate count only; validate Danish Patobank codebook before analytic use.",
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_db_empty_aeki_code_counts())
  out[names(ki67_db_empty_aeki_code_counts())]
}

ki67_db_execute_p16_counts <- function(connections, search_plan, min_cell_count = 5L) {
  rows <- list()
  x <- search_plan[search_plan$search_channel == "danish_patobank_aeki_codes", , drop = FALSE]
  codes <- ki67_dual_stain_code_map()
  if (!nrow(x) || !length(connections)) return(ki67_db_empty_p16_dual_stain_counts())
  for (i in seq_len(nrow(x))) {
    conn <- ki67_db_connection_for_location(connections, x$schema[[i]], x$table[[i]])
    table_ref <- ki67_db_quote_table(conn, x$schema[[i]], x$table[[i]])
    qcol <- as.character(DBI::dbQuoteIdentifier(conn, x$column[[i]]))
    code_sql <- paste(as.character(DBI::dbQuoteString(conn, codes$code)), collapse = ", ")
    sql <- paste0(
      "select upper(trim(", qcol, "::text)) as code, count(*) as aggregate_count from ", table_ref,
      " where upper(trim(", qcol, "::text)) in (", code_sql, ") group by upper(trim(", qcol, "::text))"
    )
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out) || !nrow(out)) next
    for (j in seq_len(nrow(out))) {
      info <- codes[codes$code == out$code[[j]], , drop = FALSE]
      if (!nrow(info)) next
      count <- ki67_db_suppress_count(out$aggregate_count[[j]], min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(
        resource_id = x$resource_id[[i]],
        schema = x$schema[[i]],
        table = x$table[[i]],
        column = x$column[[i]],
        code = out$code[[j]],
        interpretation = info$concept_interpretation[[1]],
        aggregate_count = count$display,
        notes = paste(info$label[[1]], "- not numeric MCL Ki-67 proliferation-index evidence."),
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_db_empty_p16_dual_stain_counts())
  out[names(ki67_db_empty_p16_dual_stain_counts())]
}

ki67_db_execute_text_counts <- function(connections, search_plan, min_cell_count = 5L) {
  rows <- list()
  x <- search_plan[search_plan$search_channel == "pathology_text_patterns", , drop = FALSE]
  if (!nrow(x) || !length(connections)) return(ki67_db_empty_text_pattern_counts())
  for (i in seq_len(nrow(x))) {
    conn <- ki67_db_connection_for_location(connections, x$schema[[i]], x$table[[i]])
    sql <- ki67_db_query_for_plan_row(x[i, , drop = FALSE], conn = conn, min_cell_count = min_cell_count)
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out) || !nrow(out)) next
    for (j in seq_len(nrow(out))) {
      count <- ki67_db_suppress_count(out$aggregate_count[[j]], min_cell_count)
      rows[[length(rows) + 1L]] <- data.frame(
        resource_id = x$resource_id[[i]],
        schema = x$schema[[i]],
        table = x$table[[i]],
        text_column = x$column[[i]],
        pattern_name = out$value_class[[j]],
        value_class = out$value_class[[j]],
        aggregate_count = count$display,
        numeric_value_min_if_aggregate_safe = "",
        numeric_value_max_if_aggregate_safe = "",
        notes = if (count$suppressed) "Exact small count suppressed; no snippets emitted." else "Aggregate pattern count only; no snippets emitted.",
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_db_empty_text_pattern_counts())
  out[names(ki67_db_empty_text_pattern_counts())]
}

ki67_db_execute_registry_counts <- function(connections, search_plan, min_cell_count = 5L) {
  rows <- list()
  x <- search_plan[search_plan$search_channel == "structured_registry_fields", , drop = FALSE]
  if (!nrow(x) || !length(connections)) return(ki67_db_empty_registry_field_counts())
  for (i in seq_len(nrow(x))) {
    conn <- ki67_db_connection_for_location(connections, x$schema[[i]], x$table[[i]])
    sql <- ki67_db_query_for_plan_row(x[i, , drop = FALSE], conn = conn, min_cell_count = min_cell_count)
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(out) || !nrow(out)) next
    non_missing <- ki67_db_suppress_count(out$non_missing_count[[1]], min_cell_count)
    distinct <- ki67_db_suppress_count(out$distinct_value_count[[1]], min_cell_count)
    rows[[length(rows) + 1L]] <- data.frame(
      schema = x$schema[[i]],
      table = x$table[[i]],
      field = x$column[[i]],
      matched_term = ki67_db_first_term(x$column[[i]], ki67_db_column_terms()),
      likely_value_type = if (grepl("pct|percent|procent|index|indeks", x$column[[i]], ignore.case = TRUE)) "numeric_percent_or_range" else "not_clear",
      non_missing_count_if_allowed = non_missing$display,
      distinct_value_count_if_allowed = distinct$display,
      aggregate_value_summary_if_allowed = "",
      notes = "Aggregate non-missing/distinct summary only; validate registry field definition before analytic use.",
      stringsAsFactors = FALSE
    )
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_db_empty_registry_field_counts())
  out[names(ki67_db_empty_registry_field_counts())]
}

ki67_db_placeholder_counts <- function(status = "not_run_plan_mode", note = "Plan generated; aggregate production query not executed.") {
  list(
    aeki_code_counts = data.frame(
      resource_id = "", schema = "", table = "", column = "", code = "", parsed_percent = "",
      aggregate_count = "", distinct_patient_count_if_allowed = "", year_min_if_allowed = "", year_max_if_allowed = "",
      validation_status = status, notes = note, stringsAsFactors = FALSE
    )[names(ki67_db_empty_aeki_code_counts())],
    p16_dual_stain_counts = data.frame(
      resource_id = "", schema = "", table = "", column = "", code = "", interpretation = "",
      aggregate_count = "", notes = note, stringsAsFactors = FALSE
    )[names(ki67_db_empty_p16_dual_stain_counts())],
    text_pattern_counts = data.frame(
      resource_id = "", schema = "", table = "", text_column = "", pattern_name = "", value_class = "",
      aggregate_count = "", numeric_value_min_if_aggregate_safe = "", numeric_value_max_if_aggregate_safe = "",
      notes = note, stringsAsFactors = FALSE
    )[names(ki67_db_empty_text_pattern_counts())],
    registry_field_counts = data.frame(
      schema = "", table = "", field = "", matched_term = "", likely_value_type = "",
      non_missing_count_if_allowed = "", distinct_value_count_if_allowed = "", aggregate_value_summary_if_allowed = "",
      notes = note, stringsAsFactors = FALSE
    )[names(ki67_db_empty_registry_field_counts())]
  )
}

ki67_db_count_has_evidence <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(FALSE)
  count_cols <- intersect(c("aggregate_count", "non_missing_count_if_allowed"), names(x))
  if (!length(count_cols)) return(FALSE)
  any(vapply(count_cols, function(col) {
    vals <- as.character(x[[col]] %||% "")
    nzchar(vals) & vals != "0"
  }, logical(nrow(x))) %in% TRUE, na.rm = TRUE)
}

ki67_db_summary <- function(aeki, p16, text_counts, registry_counts) {
  aeki_found <- ki67_db_count_has_evidence(aeki) && any(nzchar(aeki$code %||% ""), na.rm = TRUE)
  registry_found <- ki67_db_count_has_evidence(registry_counts) && any(nzchar(registry_counts$field %||% ""), na.rm = TRUE)
  text_found <- ki67_db_count_has_evidence(text_counts) && any(nzchar(text_counts$value_class %||% ""), na.rm = TRUE)
  p16_found <- ki67_db_count_has_evidence(p16) && any(nzchar(p16$code %||% ""), na.rm = TRUE)
  total_display <- function(x, col = "aggregate_count") {
    if (!is.data.frame(x) || !nrow(x) || !col %in% names(x)) return("0")
    vals <- as.character(x[[col]] %||% "")
    vals <- vals[nzchar(vals)]
    if (!length(vals)) "0" else paste(unique(vals), collapse = "; ")
  }
  best_source <- function(x, col = "column") {
    if (!is.data.frame(x) || !nrow(x)) return("")
    parts <- paste(x$schema %||% "", x$table %||% "", x[[col]] %||% "", sep = ".")
    parts <- parts[nzchar(gsub("[.]", "", parts))]
    paste(unique(head(parts, 3)), collapse = "; ")
  }
  data.frame(
    channel = c("structured_registry_fields", "danish_patobank_aeki_codes", "pathology_text_patterns", "p16_ki67_dual_stain_codes", "source_only_search_space"),
    direct_evidence_found = c(registry_found, aeki_found, text_found, p16_found, FALSE),
    numeric_percent_found = c(registry_found, aeki_found, text_found, FALSE, FALSE),
    aggregate_count_total = c(
      total_display(registry_counts, "non_missing_count_if_allowed"),
      total_display(aeki),
      total_display(text_counts),
      total_display(p16),
      "0"
    ),
    best_source = c(best_source(registry_counts, "field"), best_source(aeki, "column"), best_source(text_counts, "text_column"), best_source(p16, "column"), ""),
    evidence_strength = c(
      if (registry_found) "strong_structured_numeric" else "not_found",
      if (aeki_found) "strong_structured_coded" else "not_found",
      if (text_found) "moderate_text_extractable" else "not_found",
      if (p16_found) "moderate_direct_non_mcl_numeric" else "not_found",
      "source_only"
    ),
    mcl_triangle_relevance = c(
      if (registry_found) "numeric Ki-67 candidate; validate registry semantics" else "no direct registry Ki-67 evidence found",
      if (aeki_found) "numeric Danish Patobank Ki-67 code candidate" else "no aggregate AEKI evidence found",
      if (text_found) "text-extractable candidate; requires manual validation" else "no aggregate text-pattern evidence found",
      "not numeric MCL Ki-67 proliferation-index evidence",
      "search space only"
    ),
    requires_manual_validation = c(TRUE, TRUE, TRUE, TRUE, TRUE),
    next_action = c(
      "Validate field definition, unit, and missing/range coding.",
      "Validate Danish Patobank local codebook and MCL applicability.",
      "Clinically validate extraction rules on an approved aggregate/text-mining workflow.",
      "Keep separate from MCL Ki-67 numeric readiness.",
      "Use source-space rows to guide production validation only."
    ),
    notes = c(
      "Counts are aggregate-only and may be small-cell suppressed.",
      "AEKI/ÆKI codes encode numeric percent in the local code value.",
      "No raw snippets are emitted.",
      "Dual-stain cervix triage codes are tracked for false-positive avoidance.",
      "Source-only availability is not evidence of Ki-67."
    ),
    stringsAsFactors = FALSE
  )[names(ki67_db_empty_summary())]
}

ki67_db_found_locations <- function(summary, aeki, text_counts, registry_counts, p16) {
  rows <- list()
  add_rows <- function(channel, x, column_name, evidence_type, readiness_impact, next_step, numeric = TRUE) {
    if (!is.data.frame(x) || !nrow(x)) return(NULL)
    for (i in seq_len(nrow(x))) {
      count <- as.character((x$aggregate_count %||% x$non_missing_count_if_allowed %||% "")[[i]] %||% "")
      if (!nzchar(count) || count == "0") next
      rows[[length(rows) + 1L]] <<- data.frame(
        evidence_channel = channel,
        schema = as.character((x$schema %||% "")[[i]] %||% ""),
        table = as.character((x$table %||% "")[[i]] %||% ""),
        column = as.character((x[[column_name]] %||% "")[[i]] %||% ""),
        evidence_type = evidence_type,
        direct_evidence_found = TRUE,
        numeric_percent_found = numeric,
        aggregate_count_display = count,
        small_cell_suppressed = grepl("^<|suppressed", count),
        readiness_impact = readiness_impact,
        next_validation_step = next_step,
        notes = as.character((x$notes %||% "")[[i]] %||% ""),
        stringsAsFactors = FALSE
      )
    }
  }
  add_rows("structured_registry_fields", registry_counts, "field", "registry_field", "strong_structured_numeric_if_validated", "Validate field definition and unit.")
  add_rows("danish_patobank_aeki_codes", aeki, "column", "pathology_code", "strong_structured_coded_if_validated", "Validate Danish Patobank codebook and source scope.")
  add_rows("pathology_text_patterns", text_counts, "text_column", "aggregate_text_pattern", "moderate_text_extractable_if_validated", "Run approved validation of text extraction.", numeric = TRUE)
  add_rows("p16_ki67_dual_stain_codes", p16, "column", "p16_ki67_dual_stain_code", "no_numeric_mcl_upgrade", "Keep separate from MCL Ki-67 numeric readiness.", numeric = FALSE)
  out <- bind_rows_base(rows)
  if (!nrow(out)) {
    return(data.frame(
      evidence_channel = "none",
      schema = "", table = "", column = "", evidence_type = "no_direct_aggregate_evidence",
      direct_evidence_found = FALSE, numeric_percent_found = FALSE, aggregate_count_display = "0",
      small_cell_suppressed = FALSE, readiness_impact = "no_readiness_upgrade",
      next_validation_step = "Run production aggregate scan with validated candidate tables/columns.",
      notes = "No direct aggregate Ki-67 evidence was found or production queries were not executed.",
      stringsAsFactors = FALSE
    )[names(ki67_empty_found_locations())])
  }
  out[names(ki67_empty_found_locations())]
}

ki67_db_apply_to_mcl_outputs <- function(output_dir, db_outputs) {
  summary <- db_outputs$summary
  if (!is.data.frame(summary) || !nrow(summary)) return(character())
  direct <- summary[summary$direct_evidence_found %in% TRUE & summary$channel %in% c("structured_registry_fields", "danish_patobank_aeki_codes", "pathology_text_patterns"), , drop = FALSE]
  if (!nrow(direct)) return(character())
  strongest <- if (any(direct$channel == "structured_registry_fields")) {
    "strong_structured_numeric"
  } else if (any(direct$channel == "danish_patobank_aeki_codes")) {
    "strong_structured_coded"
  } else {
    "moderate_text_extractable"
  }
  paths <- character()
  update_csv <- function(name, updater) {
    path <- file.path(output_dir, name)
    if (!file.exists(path)) return(NULL)
    x <- read_delimited_file(path)
    x <- updater(x)
    write_csv(x, path)
    paths <<- c(paths, path)
  }
  update_csv("mcl_triangle_study_readiness_matrix.csv", function(x) {
    if (!"study_requirement" %in% names(x)) return(x)
    idx <- x$study_requirement == "Ki-67"
    if (!any(idx)) return(x)
    x$readiness_status[idx] <- strongest
    x$direct_variable_available[idx] <- strongest %in% c("strong_structured_numeric", "strong_structured_coded")
    x$proxy_available[idx] <- identical(strongest, "moderate_text_extractable")
    x$current_profiled_evidence[idx] <- TRUE
    x$candidate_fields_or_codes[idx] <- paste(direct$best_source, collapse = "; ")
    x$key_limitation[idx] <- "Direct aggregate Ki-67 evidence found by production finder; source-specific clinical validation is still required."
    x$recommended_next_action[idx] <- "Validate Ki-67 coding/value semantics before analytic cohort extraction."
    x
  })
  update_csv("mcl_triangle_biology_gap_analysis.csv", function(x) {
    if (!"marker" %in% names(x)) return(x)
    idx <- x$marker == "Ki-67"
    if (!any(idx)) return(x)
    x$direct_variable_found[idx] <- strongest %in% c("strong_structured_numeric", "strong_structured_coded")
    x$indirect_proxy_found[idx] <- identical(strongest, "moderate_text_extractable")
    x$current_profiled_source_available[idx] <- TRUE
    x$feasibility_status[idx] <- if (strongest %in% c("strong_structured_numeric", "strong_structured_coded")) "ready" else "feasible_with_mapping"
    x$action_required[idx] <- "Validate source-specific definition and coding before cohort extraction."
    x$notes[idx] <- paste("Production Ki-67 finder status:", strongest, "- aggregate-only evidence found; no raw text emitted.")
    x
  })
  update_csv("mcl_triangle_feasibility_summary.csv", function(x) {
    if (!"metric" %in% names(x)) return(x)
    idx <- x$metric == "ki67_evidence_found"
    if (!any(idx)) return(x)
    x$status[idx] <- strongest
    x$value[idx] <- strongest
    x$evidence_count[idx] <- nrow(direct)
    x$notes[idx] <- "Ki-67 evidence updated from direct aggregate production finder; manual validation required."
    x
  })
  update_csv("ki67_channel_summary.csv", function(x) {
    if (!"evidence_channel" %in% names(x)) return(x)
    for (i in seq_len(nrow(direct))) {
      channel <- switch(
        direct$channel[[i]],
        structured_registry_fields = "structured_registry_fields",
        danish_patobank_aeki_codes = "danish_pathology_code_evidence",
        pathology_text_patterns = "pathology_text_extraction_readiness",
        direct$channel[[i]]
      )
      idx <- x$evidence_channel == channel
      if (any(idx)) {
        x$confirmed_hits[idx] <- as.integer(suppressWarnings(as.integer(x$confirmed_hits[idx])) %||% 0L) + 1L
        x$status[idx] <- "confirmed_present"
        x$notes[idx] <- paste("Updated from direct aggregate production finder:", direct$best_source[[i]])
      }
    }
    x
  })
  paths
}

build_ki67_db_outputs <- function(project_root = ".",
                                  outputs_dir = file.path(project_root, "outputs"),
                                  mode = "plan",
                                  candidate_tables = ki67_db_default_candidate_tables(),
                                  full_scan = FALSE,
                                  min_cell_count = 5L,
                                  update_mcl = TRUE,
                                  db_adapter = NULL) {
  candidates <- ki67_db_source_map_candidates(project_root, outputs_dir = outputs_dir, candidate_tables = candidate_tables)
  plan <- ki67_db_plan_from_candidates(candidates)
  column_hits <- ki67_db_empty_column_name_hits()
  note_status <- "not_run_plan_mode"
  note <- "Plan generated; aggregate production query not executed."
  if (identical(mode, "production_aggregate")) {
    if (is.null(db_adapter)) db_adapter <- tryCatch(dalycare_db_adapter(), error = function(e) NULL)
    if (!is.null(db_adapter) && length(db_adapter$connections %||% list())) {
      column_hits <- ki67_db_find_column_name_hits(db_adapter$connections, candidate_tables = candidate_tables, full_scan = full_scan)
      metadata_plan <- ki67_db_plan_from_metadata(column_hits, candidate_tables = candidate_tables)
      if (nrow(metadata_plan)) plan <- unique(bind_rows_base(list(plan, metadata_plan)))[names(ki67_db_empty_search_plan())]
      aeki <- ki67_db_execute_aeki_counts(db_adapter$connections, plan, min_cell_count = min_cell_count)
      p16 <- ki67_db_execute_p16_counts(db_adapter$connections, plan, min_cell_count = min_cell_count)
      text_counts <- if (isTRUE(full_scan)) ki67_db_execute_text_counts(db_adapter$connections, plan, min_cell_count = min_cell_count) else ki67_db_empty_text_pattern_counts()
      registry_counts <- ki67_db_execute_registry_counts(db_adapter$connections, plan, min_cell_count = min_cell_count)
      summary <- ki67_db_summary(aeki, p16, text_counts, registry_counts)
      found <- ki67_db_found_locations(summary, aeki, text_counts, registry_counts, p16)
      out <- list(
        query_templates = ki67_db_query_templates(plan),
        search_plan = plan,
        column_name_hits = column_hits,
        aeki_code_counts = aeki,
        p16_dual_stain_counts = p16,
        text_pattern_counts = text_counts,
        registry_field_counts = registry_counts,
        summary = summary,
        found_locations = found
      )
      if (isTRUE(update_mcl)) {
        out$updated_mcl_paths <- ki67_db_apply_to_mcl_outputs(outputs_dir, out)
      }
      return(out)
    }
    note_status <- "no_db_connection"
    note <- "Production aggregate mode requested, but no DALY-CARE DB connection was available; wrote query plan only."
  }
  placeholders <- ki67_db_placeholder_counts(note_status, note)
  summary <- ki67_db_summary(
    placeholders$aeki_code_counts,
    placeholders$p16_dual_stain_counts,
    placeholders$text_pattern_counts,
    placeholders$registry_field_counts
  )
  found <- ki67_db_found_locations(summary, placeholders$aeki_code_counts, placeholders$text_pattern_counts, placeholders$registry_field_counts, placeholders$p16_dual_stain_counts)
  list(
    query_templates = ki67_db_query_templates(plan),
    search_plan = plan,
    column_name_hits = column_hits,
    aeki_code_counts = placeholders$aeki_code_counts,
    p16_dual_stain_counts = placeholders$p16_dual_stain_counts,
    text_pattern_counts = placeholders$text_pattern_counts,
    registry_field_counts = placeholders$registry_field_counts,
    summary = summary,
    found_locations = found,
    updated_mcl_paths = character()
  )
}

ki67_db_write_outputs <- function(outputs, output_dir) {
  dir_create(output_dir)
  query_path <- file.path(output_dir, "ki67_db_query_templates.sql")
  writeLines(outputs$query_templates %||% character(), query_path, useBytes = TRUE)
  c(
    query_templates = query_path,
    search_plan = write_csv(outputs$search_plan, file.path(output_dir, "ki67_db_search_plan.csv")),
    column_name_hits = write_csv(outputs$column_name_hits, file.path(output_dir, "ki67_db_column_name_hits.csv")),
    aeki_code_counts = write_csv(outputs$aeki_code_counts, file.path(output_dir, "ki67_db_aeki_code_counts.csv")),
    p16_dual_stain_counts = write_csv(outputs$p16_dual_stain_counts, file.path(output_dir, "ki67_db_p16_dual_stain_counts.csv")),
    text_pattern_counts = write_csv(outputs$text_pattern_counts, file.path(output_dir, "ki67_db_text_pattern_counts.csv")),
    registry_field_counts = write_csv(outputs$registry_field_counts, file.path(output_dir, "ki67_db_registry_field_counts.csv")),
    summary = write_csv(outputs$summary, file.path(output_dir, "ki67_db_summary.csv")),
    found_locations = write_csv(outputs$found_locations, file.path(output_dir, "ki67_found_locations.csv"))
  )
}
