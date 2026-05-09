atlas_db_profile_enabled <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = "TRUE"), default = TRUE)
}

atlas_default_chunk_size <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_CHUNK_SIZE", unset = "50000"), default = 50000L)
}

atlas_max_full_load_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS", unset = "100000"), default = 100000L)
}

normalize_atlas_logical <- function(x, default = FALSE) {
  x <- tolower(trimws(as.character(x[[1]] %||% "")))
  if (x %in% c("true", "t", "yes", "y", "1")) return(TRUE)
  if (x %in% c("false", "f", "no", "n", "0")) return(FALSE)
  default
}

normalize_positive_integer <- function(x, default) {
  out <- suppressWarnings(as.integer(x[[1]] %||% default))
  if (is.na(out) || out <= 0L) return(default)
  out
}

normalize_source_load_strategy <- function(x) {
  x <- tolower(trimws(as.character(x[[1]] %||% "auto")))
  if (!nzchar(x)) return("auto")
  aliases <- c(
    load_dataset = "dataset_full_load_fallback",
    full_load = "dataset_full_load_fallback",
    dataset_full_load = "dataset_full_load_fallback",
    skip = "skipped_risky_full_load",
    skipped = "skipped_risky_full_load"
  )
  if (x %in% names(aliases)) return(unname(aliases[[x]]))
  valid <- c(
    "auto", "db_aggregate", "db_chunked", "file_full_load",
    "dataset_full_load_fallback", "skipped_risky_full_load"
  )
  if (x %in% valid) x else "auto"
}

source_record_value <- function(record, name, default = "") {
  if (!name %in% names(record)) return(default)
  value <- record[[name]][[1]] %||% default
  value <- trimws(as.character(value))
  if (!nzchar(value) || is.na(value)) return(default)
  value
}

source_record_logical <- function(record, name, default = FALSE) {
  if (!name %in% names(record)) return(default)
  normalize_atlas_logical(record[[name]][[1]], default = default)
}

source_record_integer <- function(record, name, default) {
  if (!name %in% names(record)) return(default)
  normalize_positive_integer(record[[name]][[1]], default = default)
}

atlas_known_daly_db_schemas <- function() {
  data.frame(
    db_name = c(
      "core", "core", "core",
      "import", "import", "import",
      "dalycare", "dalycare"
    ),
    schema = c(
      "public", "curated", "_lookup_tables",
      "public", "laboratory", "_lookup_tables",
      "public", "views"
    ),
    stringsAsFactors = FALSE
  )
}

dalycare_db_adapter <- function(bootstrap_path = "", env = .GlobalEnv) {
  if (nzchar(bootstrap_path %||% "") && file.exists(bootstrap_path)) {
    tryCatch(source(bootstrap_path, local = env), error = function(e) invisible(NULL))
  }
  if (!requireNamespace("DBI", quietly = TRUE)) {
    return(NULL)
  }

  connections <- find_dbi_connections(env)
  env_conn <- postgres_connection_from_env()
  if (!is.null(env_conn)) {
    connections[[connection_db_name(env_conn, "env_postgres")]] <- env_conn
  }
  if (!length(connections)) {
    return(NULL)
  }

  list(
    adapter_name = "DBI",
    connections = connections,
    list_tables = function() dbi_list_tables(connections),
    table_schema = function(db_name, schema, table) dbi_table_schema(connections, db_name, schema, table),
    table_row_count = function(db_name, schema, table) dbi_table_row_count(connections, db_name, schema, table),
    profile_table = function(db_name, schema, table, table_name, source_type, source,
                             profile_mode = "full", top_n = 10L,
                             min_cell_count = atlas_min_cell_count()) {
      dbi_profile_table(
        connections = connections,
        db_name = db_name,
        schema = schema,
        table = table,
        table_name = table_name,
        source_type = source_type,
        source = source,
        profile_mode = profile_mode,
        top_n = top_n,
        min_cell_count = min_cell_count
      )
    }
  )
}

find_dbi_connections <- function(env = .GlobalEnv) {
  names <- ls(envir = env, all.names = TRUE)
  connections <- list()
  for (nm in names) {
    value <- tryCatch(get(nm, envir = env, inherits = FALSE), error = function(e) NULL)
    if (inherits(value, "DBIConnection")) {
      connections[[connection_db_name(value, nm)]] <- value
    }
  }
  connections
}

postgres_connection_from_env <- function() {
  if (!requireNamespace("RPostgres", quietly = TRUE) || !requireNamespace("DBI", quietly = TRUE)) {
    return(NULL)
  }
  dbname <- Sys.getenv("DALYCARE_ATLAS_DBNAME", unset = Sys.getenv("PGDATABASE", unset = ""))
  if (!nzchar(dbname)) return(NULL)
  args <- list(
    drv = RPostgres::Postgres(),
    dbname = dbname,
    options = "-c default_transaction_read_only=on"
  )
  for (nm in c("host", "user", "password", "port")) {
    env_name <- paste0("PG", toupper(nm))
    value <- Sys.getenv(env_name, unset = "")
    if (nzchar(value)) args[[nm]] <- if (identical(nm, "port")) as.integer(value) else value
  }
  tryCatch(do.call(DBI::dbConnect, args), error = function(e) NULL)
}

connection_db_name <- function(conn, fallback) {
  info <- tryCatch(DBI::dbGetInfo(conn), error = function(e) list())
  value <- info$dbname %||% info$dbname[[1]] %||% fallback
  value <- as.character(value[[1]] %||% fallback)
  if (!nzchar(value)) fallback else value
}

adapter_list_tables <- function(db_adapter) {
  if (is.null(db_adapter) || !is.function(db_adapter$list_tables)) {
    return(empty_source_resolution_tables())
  }
  tables <- tryCatch(db_adapter$list_tables(), error = function(e) empty_source_resolution_tables())
  normalize_table_locations(tables)
}

empty_source_resolution_tables <- function() {
  empty_df(db_name = character(), schema = character(), table = character())
}

normalize_table_locations <- function(tables) {
  if (!is.data.frame(tables) || !nrow(tables)) return(empty_source_resolution_tables())
  aliases <- list(
    db_name = c("db_name", "database", "database_name", "dbname"),
    schema = c("schema", "table_schema", "schema_name"),
    table = c("table", "table_name", "relation", "name")
  )
  out <- data.frame(.row = seq_len(nrow(tables)), stringsAsFactors = FALSE)
  for (nm in names(aliases)) {
    hit <- intersect(aliases[[nm]], names(tables))[1] %||% NA_character_
    out[[nm]] <- if (is.na(hit)) rep("", nrow(tables)) else trimws(as.character(tables[[hit]]))
  }
  out$.row <- NULL
  out <- out[nzchar(out$table), , drop = FALSE]
  rownames(out) <- NULL
  out
}

resolve_dalycare_sources <- function(source_map, db_adapter = NULL) {
  tables <- if (atlas_db_profile_enabled()) adapter_list_tables(db_adapter) else empty_source_resolution_tables()
  rows <- lapply(seq_len(nrow(source_map)), function(i) {
    resolve_dalycare_source(source_map[i, , drop = FALSE], i, db_adapter = db_adapter, tables = tables)
  })
  bind_rows_base(rows)
}

resolve_dalycare_source <- function(record, source_index, db_adapter = NULL, tables = empty_source_resolution_tables()) {
  base <- function(status, n_matches = 0L, message = "", match = NULL, row_count = NA_real_) {
    data.frame(
      source_index = source_index,
      table_name = source_record_value(record, "table_name"),
      source = source_record_value(record, "source"),
      source_type = source_record_value(record, "source_type"),
      load_strategy = normalize_source_load_strategy(source_record_value(record, "load_strategy", "auto")),
      db_name = if (is.null(match)) source_record_value(record, "db_name") else match$db_name[[1]],
      schema = if (is.null(match)) source_record_value(record, "schema") else match$schema[[1]],
      table = if (is.null(match)) source_record_value(record, "table") else match$table[[1]],
      resolution_status = status,
      n_matches = as.integer(n_matches),
      row_count = suppressWarnings(as.numeric(row_count)),
      message = message,
      stringsAsFactors = FALSE
    )
  }

  source_type <- tolower(source_record_value(record, "source_type"))
  if (!identical(source_type, "dataset")) {
    return(base("not_applicable", message = "File-backed source does not need DALY DB resolution."))
  }
  if (!atlas_db_profile_enabled()) {
    return(base("db_profile_disabled", message = "DALYCARE_ATLAS_DB_PROFILE is FALSE."))
  }
  if (is.null(db_adapter) || !nrow(tables)) {
    return(base("db_unavailable", message = "No DB adapter or table catalog was available."))
  }

  matches <- match_table_location(record, tables)
  if (!nrow(matches)) {
    return(base("missing", message = "No matching table or view was found in the DB catalog."))
  }
  if (nrow(matches) > 1L) {
    return(base("ambiguous", n_matches = nrow(matches), message = "Multiple DB tables matched this source."))
  }
  row_count <- adapter_table_row_count(db_adapter, matches$db_name[[1]], matches$schema[[1]], matches$table[[1]])
  message <- if (is.na(row_count)) "Resolved DB table; row count unavailable." else "Resolved DB table."
  base("resolved", n_matches = 1L, message = message, match = matches, row_count = row_count)
}

match_table_location <- function(record, tables) {
  if (!nrow(tables)) return(tables)
  requested_db <- source_record_value(record, "db_name")
  requested_schema <- source_record_value(record, "schema")
  requested_table <- source_record_value(record, "table")
  candidates <- if (nzchar(requested_table)) {
    requested_table
  } else {
    unique(c(
      source_record_value(record, "source"),
      source_record_value(record, "table_name"),
      make.names(source_record_value(record, "source")),
      make.names(source_record_value(record, "table_name"))
    ))
  }
  candidates <- candidates[nzchar(candidates)]
  table_key <- normalized_table_key(tables$table)
  candidate_keys <- normalized_table_key(candidates)
  ix <- which(table_key %in% candidate_keys)
  if (nzchar(requested_db)) {
    ix <- ix[tolower(tables$db_name[ix]) == tolower(requested_db)]
  }
  if (nzchar(requested_schema)) {
    ix <- ix[tolower(tables$schema[ix]) == tolower(requested_schema)]
  }
  if (!length(ix)) return(tables[0, , drop = FALSE])
  tables[ix, , drop = FALSE]
}

normalized_table_key <- function(x) {
  gsub("[^a-z0-9]", "", tolower(as.character(x)))
}

adapter_table_row_count <- function(db_adapter, db_name, schema, table) {
  if (is.null(db_adapter) || !is.function(db_adapter$table_row_count)) return(NA_real_)
  value <- tryCatch(db_adapter$table_row_count(db_name, schema, table), error = function(e) NA_real_)
  suppressWarnings(as.numeric(value[[1]] %||% NA_real_))
}

memory_plan_for_sources <- function(source_map, source_resolution) {
  rows <- lapply(seq_len(nrow(source_map)), function(i) {
    record <- source_map[i, , drop = FALSE]
    resolution <- source_resolution[source_resolution$source_index == i, , drop = FALSE]
    if (!nrow(resolution)) resolution <- empty_source_resolution_row(record, i)
    memory_plan_for_source(record, i, resolution[1, , drop = FALSE])
  })
  bind_rows_base(rows)
}

empty_source_resolution_row <- function(record, source_index) {
  data.frame(
    source_index = source_index,
    table_name = source_record_value(record, "table_name"),
    source = source_record_value(record, "source"),
    source_type = source_record_value(record, "source_type"),
    load_strategy = normalize_source_load_strategy(source_record_value(record, "load_strategy", "auto")),
    db_name = source_record_value(record, "db_name"),
    schema = source_record_value(record, "schema"),
    table = source_record_value(record, "table"),
    resolution_status = "unknown",
    n_matches = 0L,
    row_count = NA_real_,
    message = "No resolution row was available.",
    stringsAsFactors = FALSE
  )
}

memory_plan_for_source <- function(record, source_index, resolution) {
  source_type <- tolower(source_record_value(record, "source_type"))
  requested_strategy <- normalize_source_load_strategy(source_record_value(record, "load_strategy", "auto"))
  row_count <- suppressWarnings(as.numeric(resolution$row_count[[1]] %||% NA_real_))
  chunk_size <- source_record_integer(record, "chunk_size", atlas_default_chunk_size())
  max_full_load_rows <- atlas_max_full_load_rows()
  allow_full_load <- source_record_logical(record, "allow_full_load", default = FALSE)
  db_enabled <- atlas_db_profile_enabled()

  chosen_strategy <- "skipped_risky_full_load"
  status <- "skipped"
  message <- "Full-table load refused by strict memory guardrail."

  if (identical(source_type, "file")) {
    chosen_strategy <- "file_full_load"
    status <- "ok"
    message <- "File-backed source will be loaded through the existing file path."
  } else if (identical(requested_strategy, "skipped_risky_full_load")) {
    chosen_strategy <- "skipped_risky_full_load"
    status <- "skipped"
    message <- "Source map requested skip."
  } else if (isTRUE(db_enabled) && identical(resolution$resolution_status[[1]], "resolved") &&
             !identical(requested_strategy, "dataset_full_load_fallback")) {
    chosen_strategy <- if (identical(requested_strategy, "db_chunked")) "db_chunked" else "db_aggregate"
    status <- "ok"
    message <- if (identical(chosen_strategy, "db_chunked")) {
      "Resolved source will use DB chunked profiling."
    } else {
      "Resolved source will use DB aggregate profiling."
    }
  } else {
    can_full_load <- isTRUE(allow_full_load) || (!is.na(row_count) && row_count <= max_full_load_rows)
    if (isTRUE(can_full_load)) {
      chosen_strategy <- "dataset_full_load_fallback"
      status <- "warning"
      message <- if (isTRUE(allow_full_load)) {
        "Full-table load fallback allowed by source map."
      } else {
        paste("Full-table load fallback allowed because row count is <=", max_full_load_rows)
      }
    } else {
      chosen_strategy <- "skipped_risky_full_load"
      status <- "skipped"
      message <- if (is.na(row_count)) {
        "DB resolution/row count unavailable and allow_full_load is not TRUE."
      } else {
        paste("Row count", row_count, "exceeds full-load threshold", max_full_load_rows)
      }
    }
  }

  data.frame(
    source_index = source_index,
    table_name = source_record_value(record, "table_name"),
    source = source_record_value(record, "source"),
    source_type = source_type,
    requested_load_strategy = requested_strategy,
    chosen_strategy = chosen_strategy,
    db_name = resolution$db_name[[1]] %||% "",
    schema = resolution$schema[[1]] %||% "",
    table = resolution$table[[1]] %||% "",
    resolution_status = resolution$resolution_status[[1]] %||% "",
    row_count = row_count,
    chunk_size = chunk_size,
    max_full_load_rows = max_full_load_rows,
    allow_full_load = allow_full_load,
    db_profile_enabled = db_enabled,
    memory_status = status,
    message = message,
    stringsAsFactors = FALSE
  )
}

profile_db_source <- function(source_record, resolution_row, db_adapter, profile_mode = NULL,
                              top_n = 10L, min_cell_count = atlas_min_cell_count()) {
  if (is.null(db_adapter)) {
    stop("DB aggregate profiling requested but no DB adapter was available.", call. = FALSE)
  }
  if (!is.function(db_adapter$profile_table)) {
    stop("DB adapter does not provide profile_table().", call. = FALSE)
  }
  profile_mode <- normalize_profile_mode(profile_mode %||% source_record_value(source_record, "profile_mode", "full"))
  out <- db_adapter$profile_table(
    db_name = resolution_row$db_name[[1]],
    schema = resolution_row$schema[[1]],
    table = resolution_row$table[[1]],
    table_name = source_record_value(source_record, "table_name"),
    source_type = "dataset",
    source = source_record_value(source_record, "source"),
    profile_mode = profile_mode,
    top_n = top_n,
    min_cell_count = min_cell_count
  )
  normalize_profile_result(out)
}

normalize_profile_result <- function(out) {
  if (!is.list(out) || is.null(out$source) || !is.data.frame(out$source)) {
    stop("DB profile result did not match atlas profile shape.", call. = FALSE)
  }
  out$columns <- out$columns %||% empty_df()
  out$column_profiles <- out$column_profiles %||% empty_column_profiles()
  out$column_top_values <- out$column_top_values %||% empty_column_top_values()
  out$checks <- out$checks %||% empty_df()
  out$value_frequencies <- out$value_frequencies %||% empty_value_frequencies()
  out$panels <- out$panels %||% list()
  out
}

dbi_list_tables <- function(connections) {
  rows <- lapply(names(connections), function(db_name) {
    conn <- connections[[db_name]]
    sql <- paste(
      "select current_database() as db_name, table_schema as schema, table_name as table",
      "from information_schema.tables",
      "where table_schema not in ('pg_catalog', 'information_schema')",
      "and table_type in ('BASE TABLE', 'VIEW')"
    )
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_source_resolution_tables())
    if (!"db_name" %in% names(out)) out$db_name <- db_name
    out
  })
  normalize_table_locations(bind_rows_base(rows))
}

dbi_connection_for <- function(connections, db_name) {
  if (db_name %in% names(connections)) return(connections[[db_name]])
  if (length(connections) == 1L) return(connections[[1]])
  stop("No DB connection found for database: ", db_name, call. = FALSE)
}

dbi_table_schema <- function(connections, db_name, schema, table) {
  conn <- dbi_connection_for(connections, db_name)
  sql <- paste0(
    "select column_name, data_type, udt_name, ordinal_position ",
    "from information_schema.columns where table_schema = ",
    DBI::dbQuoteString(conn, schema),
    " and table_name = ",
    DBI::dbQuoteString(conn, table),
    " order by ordinal_position"
  )
  DBI::dbGetQuery(conn, sql)
}

dbi_table_ref <- function(conn, schema, table) {
  if (!nzchar(schema %||% "")) return(as.character(DBI::dbQuoteIdentifier(conn, table)))
  paste(DBI::dbQuoteIdentifier(conn, schema), DBI::dbQuoteIdentifier(conn, table), sep = ".")
}

dbi_table_row_count <- function(connections, db_name, schema, table) {
  conn <- dbi_connection_for(connections, db_name)
  out <- DBI::dbGetQuery(conn, paste0("select count(*) as n_rows from ", dbi_table_ref(conn, schema, table)))
  suppressWarnings(as.numeric(out$n_rows[[1]]))
}

dbi_profile_table <- function(connections, db_name, schema, table, table_name, source_type, source,
                              profile_mode = "full", top_n = 10L,
                              min_cell_count = atlas_min_cell_count()) {
  conn <- dbi_connection_for(connections, db_name)
  profile_mode <- normalize_profile_mode(profile_mode)
  schema_info <- dbi_table_schema(connections, db_name, schema, table)
  row_count <- dbi_table_row_count(connections, db_name, schema, table)
  table_ref <- dbi_table_ref(conn, schema, table)
  column_profiles <- dbi_column_profiles(
    conn = conn,
    table_ref = table_ref,
    schema_info = schema_info,
    table_name = table_name,
    row_count = row_count,
    profile_mode = profile_mode
  )
  columns <- dbi_columns_from_profiles(column_profiles)
  top_values <- if (identical(profile_mode, "full")) {
    dbi_column_top_values(
      conn = conn,
      table_ref = table_ref,
      column_profiles = column_profiles,
      row_count = row_count,
      top_n = top_n,
      min_cell_count = min_cell_count
    )
  } else {
    empty_column_top_values()
  }
  frequencies <- if (nrow(top_values)) {
    data.frame(
      table_name = top_values$table_name,
      column_name = top_values$column_name,
      value = top_values$value,
      n = top_values$n,
      pct = top_values$pct_rows,
      stringsAsFactors = FALSE
    )
  } else {
    empty_value_frequencies()
  }
  date_range <- dbi_source_date_range(column_profiles)
  source_row <- data.frame(
    table_name = table_name,
    source_type = source_type,
    source = source,
    profile_mode = profile_mode,
    load_status = "ok",
    n_rows = row_count,
    n_cols = nrow(schema_info),
    id_column_guess = guess_id_column_from_names(schema_info$column_name),
    date_column_guess = guess_date_column_from_profiles(column_profiles),
    min_date = date_range$min_date,
    max_date = date_range$max_date,
    schema_signature = dbi_schema_signature(schema_info),
    profiled_at = atlas_timestamp(),
    stringsAsFactors = FALSE
  )
  panels <- dbi_panels_from_profiles(column_profiles, source_row)
  list(
    source = source_row,
    columns = columns,
    column_profiles = column_profiles,
    column_top_values = top_values,
    checks = dbi_checks_from_columns(table_name, schema_info$column_name),
    value_frequencies = frequencies,
    panels = panels
  )
}

dbi_column_profiles <- function(conn, table_ref, schema_info, table_name, row_count, profile_mode) {
  if (!nrow(schema_info)) return(empty_column_profiles())
  rows <- lapply(seq_len(nrow(schema_info)), function(i) {
    info <- schema_info[i, , drop = FALSE]
    dbi_column_profile(conn, table_ref, info, table_name, row_count, profile_mode)
  })
  bind_rows_base(rows)
}

dbi_column_profile <- function(conn, table_ref, info, table_name, row_count, profile_mode) {
  column_name <- as.character(info$column_name[[1]])
  column_type <- as.character(info$data_type[[1]] %||% "")
  column_class <- as.character(info$udt_name[[1]] %||% column_type)
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  counts <- dbi_column_counts(conn, table_ref, qcol)
  is_sensitive <- is_sensitive_column(column_name)
  is_date_like <- sql_type_is_date(column_type, column_class) && !is_sensitive
  is_numeric_like <- sql_type_is_numeric(column_type, column_class) && !is_sensitive
  profile_kind <- if (is_sensitive) {
    "sensitive"
  } else if (is_date_like) {
    "date"
  } else if (is_numeric_like) {
    "numeric"
  } else {
    "categorical"
  }
  numeric_stats <- dbi_numeric_stats(conn, table_ref, qcol, enabled = is_numeric_like && !identical(profile_mode, "schema"))
  date_stats <- dbi_date_stats(conn, table_ref, qcol, enabled = is_date_like && !identical(profile_mode, "schema"))
  n_missing <- suppressWarnings(as.numeric(counts$n_missing[[1]] %||% NA_real_))
  n_available <- if (is.na(n_missing) || is.na(row_count)) NA_real_ else row_count - n_missing
  data.frame(
    table_name = table_name,
    column_name = column_name,
    column_type = column_type,
    column_class = column_class,
    profile_kind = profile_kind,
    n_rows = row_count,
    n_available = n_available,
    pct_available = safe_pct(n_available, row_count),
    n_missing = n_missing,
    pct_missing = safe_pct(n_missing, row_count),
    n_distinct_capped = pmin(suppressWarnings(as.numeric(counts$n_distinct[[1]] %||% NA_real_)), 100000),
    is_sensitive = is_sensitive,
    is_date_like = is_date_like,
    is_numeric_like = is_numeric_like,
    min = numeric_stats$min,
    mean = numeric_stats$mean,
    median = numeric_stats$median,
    p25 = numeric_stats$p25,
    p75 = numeric_stats$p75,
    max = numeric_stats$max,
    min_date = date_stats$min_date,
    max_date = date_stats$max_date,
    stringsAsFactors = FALSE
  )
}

dbi_column_counts <- function(conn, table_ref, qcol) {
  sql <- paste0(
    "select ",
    "sum(case when ", qcol, " is null or btrim(", qcol, "::text) = '' then 1 else 0 end) as n_missing, ",
    "count(distinct ", qcol, ") as n_distinct ",
    "from ", table_ref
  )
  tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(n_missing = NA_real_, n_distinct = NA_real_))
}

dbi_numeric_stats <- function(conn, table_ref, qcol, enabled = TRUE) {
  empty <- list(min = NA_real_, mean = NA_real_, median = NA_real_, p25 = NA_real_, p75 = NA_real_, max = NA_real_)
  if (!isTRUE(enabled)) return(empty)
  sql <- paste0(
    "select min(", qcol, "::double precision) as min, ",
    "avg(", qcol, "::double precision) as mean, ",
    "percentile_cont(0.5) within group (order by ", qcol, "::double precision) as median, ",
    "percentile_cont(0.25) within group (order by ", qcol, "::double precision) as p25, ",
    "percentile_cont(0.75) within group (order by ", qcol, "::double precision) as p75, ",
    "max(", qcol, "::double precision) as max ",
    "from ", table_ref, " where ", qcol, " is not null"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) NULL)
  if (is.null(out) || !nrow(out)) return(empty)
  list(
    min = suppressWarnings(as.numeric(out$min[[1]])),
    mean = suppressWarnings(as.numeric(out$mean[[1]])),
    median = suppressWarnings(as.numeric(out$median[[1]])),
    p25 = suppressWarnings(as.numeric(out$p25[[1]])),
    p75 = suppressWarnings(as.numeric(out$p75[[1]])),
    max = suppressWarnings(as.numeric(out$max[[1]]))
  )
}

dbi_date_stats <- function(conn, table_ref, qcol, enabled = TRUE) {
  empty <- list(min_date = NA_character_, max_date = NA_character_)
  if (!isTRUE(enabled)) return(empty)
  sql <- paste0(
    "select min(", qcol, "::date) as min_date, max(", qcol, "::date) as max_date ",
    "from ", table_ref, " where ", qcol, " is not null"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) NULL)
  if (is.null(out) || !nrow(out)) return(empty)
  list(min_date = as.character(out$min_date[[1]] %||% NA_character_), max_date = as.character(out$max_date[[1]] %||% NA_character_))
}

dbi_column_top_values <- function(conn, table_ref, column_profiles, row_count, top_n = 10L,
                                  min_cell_count = atlas_min_cell_count()) {
  if (!nrow(column_profiles)) return(empty_column_top_values())
  sensitive <- identical_or_false(column_profiles$is_sensitive)
  date_like <- identical_or_false(column_profiles$is_date_like)
  numeric_like <- identical_or_false(column_profiles$is_numeric_like)
  distinct <- suppressWarnings(as.numeric(column_profiles$n_distinct_capped))
  eligible <- column_profiles[!sensitive & !date_like & !numeric_like & !is.na(distinct) & distinct <= 100, , drop = FALSE]
  if (!nrow(eligible)) return(empty_column_top_values())
  rows <- lapply(eligible$column_name, function(column_name) {
    qcol <- DBI::dbQuoteIdentifier(conn, column_name)
    sql <- paste0(
      "select left(", qcol, "::text, 120) as value, count(*) as n ",
      "from ", table_ref,
      " where ", qcol, " is not null and btrim(", qcol, "::text) <> '' ",
      "group by 1 having count(*) >= ", as.integer(min_cell_count),
      " order by n desc, value limit ", as.integer(top_n)
    )
    out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(value = character(), n = integer()))
    if (!nrow(out)) return(empty_column_top_values())
    data.frame(
      table_name = eligible$table_name[[1]],
      column_name = column_name,
      value = truncate_value(out$value),
      n = suppressWarnings(as.integer(out$n)),
      pct_rows = vapply(suppressWarnings(as.integer(out$n)), safe_pct, numeric(1), denom = row_count),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) empty_column_top_values() else out
}

identical_or_false <- function(x) {
  out <- as.logical(x)
  out[is.na(out)] <- FALSE
  out
}

sql_type_is_numeric <- function(column_type, column_class = "") {
  grepl("smallint|integer|bigint|decimal|numeric|real|double|float|int[248]|float[48]", paste(column_type, column_class), ignore.case = TRUE)
}

sql_type_is_date <- function(column_type, column_class = "") {
  grepl("date|timestamp|time without time zone|time with time zone", paste(column_type, column_class), ignore.case = TRUE)
}

dbi_columns_from_profiles <- function(column_profiles) {
  if (!nrow(column_profiles)) return(profile_columns(data.frame(), ""))
  data.frame(
    table_name = column_profiles$table_name,
    column_name = column_profiles$column_name,
    column_type = column_profiles$column_type,
    column_class = column_profiles$column_class,
    n_missing = column_profiles$n_missing,
    pct_missing = column_profiles$pct_missing,
    n_distinct_capped = column_profiles$n_distinct_capped,
    is_sensitive = column_profiles$is_sensitive,
    is_date_like = column_profiles$is_date_like,
    is_numeric_like = column_profiles$is_numeric_like,
    stringsAsFactors = FALSE
  )
}

dbi_source_date_range <- function(column_profiles) {
  date_rows <- column_profiles[column_profiles$profile_kind == "date", , drop = FALSE]
  min_dates <- date_rows$min_date[nzchar(as.character(date_rows$min_date)) & !is.na(date_rows$min_date)]
  max_dates <- date_rows$max_date[nzchar(as.character(date_rows$max_date)) & !is.na(date_rows$max_date)]
  list(
    min_date = if (length(min_dates)) min(min_dates) else NA_character_,
    max_date = if (length(max_dates)) max(max_dates) else NA_character_
  )
}

guess_id_column_from_names <- function(column_names) {
  hits <- column_names[vapply(column_names, is_sensitive_column, logical(1))]
  hits[1] %||% NA_character_
}

guess_date_column_from_profiles <- function(column_profiles) {
  hits <- column_profiles$column_name[as.logical(column_profiles$is_date_like)]
  hits[1] %||% NA_character_
}

dbi_schema_signature <- function(schema_info) {
  if (!nrow(schema_info)) return(NA_character_)
  paste(paste(schema_info$column_name, schema_info$data_type, schema_info$udt_name, sep = ":"), collapse = "|")
}

dbi_checks_from_columns <- function(table_name, column_names) {
  sensitive <- column_names[vapply(column_names, is_sensitive_column, logical(1))]
  if (!length(sensitive)) return(empty_df())
  check_row(
    table_name,
    "sensitive_column_values_suppressed",
    "ok",
    paste("Value frequencies suppressed for:", paste(sensitive, collapse = ", "))
  )
}

dbi_panels_from_profiles <- function(column_profiles, source_row) {
  registry <- registry_name(source_row$table_name[[1]])
  if (is.na(registry)) return(list())
  summary <- data.frame(
    table_name = source_row$table_name[[1]],
    registry = registry,
    n_rows = source_row$n_rows[[1]],
    n_cols = source_row$n_cols[[1]],
    n_patients = NA_integer_,
    min_date = source_row$min_date[[1]],
    max_date = source_row$max_date[[1]],
    stringsAsFactors = FALSE
  )
  list(registry_clinical_summary = summary)
}
