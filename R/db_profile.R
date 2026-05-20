atlas_db_profile_enabled <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_DB_PROFILE", unset = "TRUE"), default = TRUE)
}

atlas_default_chunk_size <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_CHUNK_SIZE", unset = "50000"), default = 50000L)
}

atlas_max_full_load_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS", unset = "100000"), default = 100000L)
}

atlas_max_text_distinct_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_TEXT_DISTINCT_ROWS", unset = "1000000"), default = 1000000L)
}

atlas_db_budget_mode <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_DB_BUDGET_MODE", unset = "TRUE"), default = TRUE)
}

atlas_db_stream_rows <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_DB_STREAM_ROWS", unset = "TRUE"), default = TRUE)
}

atlas_stream_chunk_size <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_STREAM_CHUNK_SIZE", unset = "50000"), default = 50000L)
}

atlas_progress_seconds <- function() {
  value <- suppressWarnings(as.numeric(Sys.getenv("DALYCARE_ATLAS_PROGRESS_SECONDS", unset = "30")))
  if (is.na(value) || value <= 0) 30 else value
}

atlas_progress_enabled <- function() {
  normalize_atlas_logical(Sys.getenv("DALYCARE_ATLAS_PROGRESS", unset = "TRUE"), default = TRUE)
}

atlas_format_count <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (is.na(x)) return("?")
  format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE)
}

atlas_elapsed_label <- function(seconds) {
  seconds <- suppressWarnings(as.numeric(seconds))
  if (is.na(seconds) || seconds < 0) return("00:00")
  seconds <- floor(seconds)
  h <- seconds %/% 3600
  m <- (seconds %% 3600) %/% 60
  s <- seconds %% 60
  if (h > 0) sprintf("%02d:%02d:%02d", h, m, s) else sprintf("%02d:%02d", m, s)
}

atlas_stream_threshold_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_STREAM_THRESHOLD_ROWS", unset = "1000000"), default = 1000000L)
}

atlas_max_tracked_categories <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_TRACKED_CATEGORIES", unset = "5000"), default = 5000L)
}

atlas_quantile_sample_size <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_QUANTILE_SAMPLE_SIZE", unset = "100000"), default = 100000L)
}

atlas_max_exact_agg_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_EXACT_AGG_ROWS", unset = "1000000"), default = 1000000L)
}

atlas_max_code_scan_rows <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_MAX_CODE_SCAN_ROWS", unset = "10000000"), default = 10000000L)
}

atlas_db_work_mem <- function() {
  Sys.getenv("DALYCARE_ATLAS_DB_WORK_MEM", unset = "64MB")
}

atlas_db_temp_file_limit <- function() {
  Sys.getenv("DALYCARE_ATLAS_DB_TEMP_FILE_LIMIT", unset = "20GB")
}

atlas_db_statement_timeout <- function() {
  Sys.getenv("DALYCARE_ATLAS_DB_STATEMENT_TIMEOUT", unset = "20min")
}

dalycare_standard_bootstrap_path <- function() {
  "/ngc/projects2/dalyca_r/clean_r/load_dalycare_package.R"
}

dalycare_resolve_bootstrap_path <- function(bootstrap_path = "") {
  explicit <- trimws(as.character(bootstrap_path[[1]] %||% ""))
  if (nzchar(explicit)) return(explicit)
  env_path <- trimws(Sys.getenv("DALYCARE_BOOTSTRAP_PATH", unset = ""))
  if (nzchar(env_path)) return(env_path)
  standard <- dalycare_standard_bootstrap_path()
  if (file.exists(standard)) return(standard)
  ""
}

dalycare_default_db_access_path <- function(user = Sys.info()[["user"]] %||% Sys.getenv("USER", unset = "")) {
  override <- Sys.getenv("DALYCARE_DB_ACCESS_PATH", unset = "")
  if (nzchar(override)) return(override)
  if (!nzchar(user %||% "")) return("")
  file.path("/ngc/people", user, "db_access.R")
}

dalycare_db_host <- function() {
  Sys.getenv("DALYCARE_ATLAS_DB_HOST", unset = "kb-dalyca-01.hpc.cld")
}

dalycare_db_port <- function() {
  normalize_positive_integer(Sys.getenv("DALYCARE_ATLAS_DB_PORT", unset = "5432"), default = 5432L)
}

dalycare_db_names <- function() {
  raw <- Sys.getenv("DALYCARE_ATLAS_DB_NAMES", unset = "core,import,dalycare")
  dbs <- trimws(strsplit(raw, ",", fixed = TRUE)[[1]])
  dbs[nzchar(dbs)]
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
  bootstrap_path <- dalycare_resolve_bootstrap_path(bootstrap_path)
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
  ngc_connections <- postgres_connections_from_ngc_db_access()
  for (nm in names(ngc_connections)) {
    if (!nm %in% names(connections)) {
      connections[[nm]] <- ngc_connections[[nm]]
    }
  }
  if (!length(connections)) {
    return(NULL)
  }
  budget_settings <- dbi_apply_budget_settings(connections)

  list(
    adapter_name = "DBI",
    connections = connections,
    budget_settings = budget_settings,
    access = dalycare_db_access_metadata(
      bootstrap_path = bootstrap_path,
      connection_names = names(connections)
    ),
    list_tables = function() dbi_list_tables(connections),
    table_schema = function(db_name, schema, table) dbi_table_schema(connections, db_name, schema, table),
    table_row_count = function(db_name, schema, table) dbi_table_row_count(connections, db_name, schema, table),
    profile_table = function(db_name, schema, table, table_name, source_type, source,
                             profile_mode = "full", top_n = 10L,
                             min_cell_count = atlas_min_cell_count(),
                             npu_dictionary = NULL,
                             npu_surfaces = NULL,
                             isotype_vectors = NULL,
                             treatment_families = NULL) {
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
        min_cell_count = min_cell_count,
        npu_dictionary = npu_dictionary,
        npu_surfaces = npu_surfaces,
        isotype_vectors = isotype_vectors,
        treatment_families = treatment_families
      )
    }
  )
}

dalycare_db_access_metadata <- function(bootstrap_path = dalycare_resolve_bootstrap_path(),
                                        db_access_path = dalycare_default_db_access_path(),
                                        connection_names = character()) {
  access <- read_dalycare_db_access(db_access_path)
  data.frame(
    bootstrap_path = bootstrap_path %||% "",
    bootstrap_exists = file.exists(bootstrap_path %||% ""),
    db_access_path = db_access_path %||% "",
    db_access_exists = isTRUE(access$exists),
    db_access_error = access$error %||% "",
    db_access_pw_present = isTRUE(access$password_present),
    db_access_symbols = paste(access$symbols$symbol_name, collapse = ","),
    db_connection_names = paste(connection_names, collapse = ","),
    stringsAsFactors = FALSE
  )
}

dalycare_access_report <- function(project_root = ".",
                                   source_map = NULL,
                                   bootstrap_path = "",
                                   db_adapter = NULL,
                                   source_resolution = NULL) {
  rows <- list()
  add <- function(status, check_id, message, table_name = "", db_name = "", schema = "", detail = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      status = status,
      check_id = check_id,
      table_name = table_name %||% "",
      db_name = db_name %||% "",
      schema = schema %||% "",
      message = message %||% "",
      detail = detail %||% "",
      stringsAsFactors = FALSE
    )
  }

  bootstrap_path <- dalycare_resolve_bootstrap_path(bootstrap_path)
  if (nzchar(bootstrap_path)) {
    if (file.exists(bootstrap_path)) {
      add("ok", "bootstrap_path_available", paste("Bootstrap path exists:", bootstrap_path))
      probe_env <- new.env(parent = .GlobalEnv)
      before_global <- ls(envir = .GlobalEnv, all.names = TRUE)
      sourced <- tryCatch(source(bootstrap_path, local = probe_env), error = function(e) e)
      global_loader_available <- exists("load_dataset", mode = "function", envir = .GlobalEnv, inherits = FALSE)
      created_global <- setdiff(ls(envir = .GlobalEnv, all.names = TRUE), before_global)
      if (length(created_global)) {
        rm(list = created_global, envir = .GlobalEnv)
      }
      if (inherits(sourced, "error")) {
        add("error", "bootstrap_source_failed", conditionMessage(sourced), detail = bootstrap_path)
      } else if (exists("load_dataset", mode = "function", envir = probe_env, inherits = FALSE) ||
                 isTRUE(global_loader_available)) {
        add("ok", "load_dataset_available", "Bootstrap defined load_dataset().")
      } else {
        add("warning", "load_dataset_missing", "Bootstrap sourced, but load_dataset() was not found.")
      }
    } else {
      add("warning", "bootstrap_path_missing", paste("Bootstrap path not found:", bootstrap_path))
    }
  } else {
    add("warning", "bootstrap_path_unset", "No bootstrap path was provided and the standard production path was not found.")
  }

  db_access_path <- dalycare_default_db_access_path()
  access <- read_dalycare_db_access(db_access_path)
  if (!nzchar(db_access_path)) {
    add("warning", "db_access_path_unset", "Could not determine the NGC db_access.R path.")
  } else if (!isTRUE(access$exists)) {
    add("warning", "db_access_missing", paste("DB credential file not found:", db_access_path))
  } else if (nzchar(access$error %||% "")) {
    add("warning", "db_access_source_failed", access$error, detail = db_access_path)
  } else {
    pw_detail <- paste0("pw_present=", isTRUE(access$password_present), "; symbols=", paste(access$symbols$symbol_name, collapse = ","))
    add(if (isTRUE(access$password_present)) "ok" else "warning", "db_access_read", "DB credential file was sourced in a private environment.", detail = pw_detail)
  }

  add(if (requireNamespace("DBI", quietly = TRUE)) "ok" else "warning", "dbi_package_available", "DBI package availability checked.")
  add(if (requireNamespace("RPostgres", quietly = TRUE)) "ok" else "warning", "rpostgres_package_available", "RPostgres package availability checked.")

  if (is.null(db_adapter)) {
    add("warning", "db_adapter_unavailable", "No DB adapter was available; DALY source catalog could not be queried.")
  } else {
    conn_names <- names(db_adapter$connections %||% list())
    add("ok", "db_adapter_available", paste("DB adapter available with", length(conn_names), "connection(s)."), detail = paste(conn_names, collapse = ","))
    budget_settings <- db_adapter$budget_settings %||% data.frame()
    if (is.data.frame(budget_settings) && nrow(budget_settings)) {
      for (i in seq_len(nrow(budget_settings))) {
        add(
          budget_settings$status[[i]],
          paste0("db_budget_setting_", budget_settings$setting[[i]]),
          paste("DB budget setting", budget_settings$setting[[i]], budget_settings$message[[i]]),
          db_name = budget_settings$db_name[[i]],
          detail = paste0("value=", budget_settings$value[[i]])
        )
      }
    }
    tables <- adapter_list_tables(db_adapter)
    if (!nrow(tables)) {
      add("warning", "db_catalog_empty", "DB adapter returned no tables or views in the DALY atlas schema universe.")
    } else {
      by_schema <- aggregate(table ~ db_name + schema, data = tables, FUN = length)
      names(by_schema)[names(by_schema) == "table"] <- "n_tables"
      for (i in seq_len(nrow(by_schema))) {
        add(
          "ok",
          "db_catalog_schema_count",
          paste("Catalog tables/views:", by_schema$n_tables[[i]]),
          db_name = by_schema$db_name[[i]],
          schema = by_schema$schema[[i]]
        )
      }
    }
  }

  if (!is.null(source_resolution) && is.data.frame(source_resolution) && nrow(source_resolution)) {
    status_counts <- aggregate(source_index ~ resolution_status, data = source_resolution, FUN = length)
    for (i in seq_len(nrow(status_counts))) {
      add(
        if (status_counts$resolution_status[[i]] %in% c("missing", "ambiguous", "db_unavailable")) "warning" else "ok",
        paste0("source_resolution_", status_counts$resolution_status[[i]]),
        paste("Mapped sources:", status_counts$source_index[[i]])
      )
    }
  } else if (!is.null(source_map) && is.data.frame(source_map) && any(source_map$source_type == "dataset")) {
    add("warning", "source_resolution_missing", "Source map has dataset rows, but no source-resolution report was available.")
  }

  out <- bind_rows_base(rows)
  if (!nrow(out)) {
    return(empty_df(status = character(), check_id = character(), table_name = character(), db_name = character(), schema = character(), message = character(), detail = character()))
  }
  out
}

read_dalycare_db_access <- function(db_access_path = dalycare_default_db_access_path(),
                                    user = Sys.info()[["user"]] %||% Sys.getenv("USER", unset = "")) {
  empty <- function(error = "") {
    list(
      path = db_access_path %||% "",
      exists = file.exists(db_access_path %||% ""),
      error = error,
      user = user %||% "",
      password = NULL,
      password_present = FALSE,
      symbols = empty_df(symbol_name = character(), object_class = character(), object_type = character(), object_length = integer())
    )
  }
  if (!nzchar(db_access_path %||% "") || !file.exists(db_access_path)) {
    return(empty())
  }
  access_env <- new.env(parent = .GlobalEnv)
  sourced <- tryCatch(source(db_access_path, local = access_env), error = function(e) e)
  if (inherits(sourced, "error")) {
    return(empty(conditionMessage(sourced)))
  }
  names <- ls(envir = access_env, all.names = TRUE)
  symbols <- lapply(names, function(nm) {
    value <- tryCatch(get(nm, envir = access_env, inherits = FALSE), error = function(e) NULL)
    data.frame(
      symbol_name = nm,
      object_class = paste(class(value), collapse = "/"),
      object_type = typeof(value),
      object_length = length(value),
      stringsAsFactors = FALSE
    )
  })
  pw <- if (exists("pw", envir = access_env, inherits = FALSE)) {
    tryCatch(get("pw", envir = access_env, inherits = FALSE), error = function(e) NULL)
  } else {
    NULL
  }
  list(
    path = db_access_path,
    exists = TRUE,
    error = "",
    user = user %||% "",
    password = if (is.null(pw)) NULL else as.character(pw[[1]]),
    password_present = !is.null(pw) && nzchar(as.character(pw[[1]] %||% "")),
    symbols = bind_rows_base(symbols)
  )
}

postgres_connections_from_ngc_db_access <- function(db_access = read_dalycare_db_access(),
                                                    db_names = dalycare_db_names()) {
  if (!requireNamespace("RPostgres", quietly = TRUE) || !requireNamespace("DBI", quietly = TRUE)) {
    return(list())
  }
  if (!isTRUE(db_access$password_present)) return(list())
  user <- Sys.getenv("DALYCARE_ATLAS_DB_USER", unset = db_access$user %||% "")
  if (!nzchar(user)) return(list())
  connections <- list()
  for (db_name in db_names) {
    args <- list(
      drv = RPostgres::Postgres(),
      dbname = db_name,
      host = dalycare_db_host(),
      port = dalycare_db_port(),
      user = user,
      password = db_access$password,
      options = "-c default_transaction_read_only=on"
    )
    conn <- tryCatch(do.call(DBI::dbConnect, args), error = function(e) NULL)
    if (!is.null(conn)) connections[[connection_db_name(conn, db_name)]] <- conn
  }
  connections
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

dbi_apply_budget_settings <- function(connections) {
  if (!length(connections) || !requireNamespace("DBI", quietly = TRUE)) {
    return(empty_df(db_name = character(), setting = character(), value = character(), status = character(), message = character()))
  }
  settings <- data.frame(
    setting = c("default_transaction_read_only", "work_mem", "temp_file_limit", "statement_timeout"),
    value = c("on", atlas_db_work_mem(), atlas_db_temp_file_limit(), atlas_db_statement_timeout()),
    stringsAsFactors = FALSE
  )
  rows <- list()
  for (db_name in names(connections)) {
    conn <- connections[[db_name]]
    for (i in seq_len(nrow(settings))) {
      setting <- settings$setting[[i]]
      value <- settings$value[[i]]
      sql <- paste0("set ", setting, " = ", DBI::dbQuoteString(conn, value))
      result <- tryCatch({
        DBI::dbExecute(conn, sql)
        list(status = "ok", message = "setting applied")
      }, error = function(e) {
        list(status = "warning", message = conditionMessage(e))
      })
      rows[[length(rows) + 1L]] <- data.frame(
        db_name = db_name,
        setting = setting,
        value = value,
        status = result$status,
        message = result$message,
        stringsAsFactors = FALSE
      )
    }
  }
  bind_rows_base(rows)
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

empty_db_query_log <- function() {
  empty_df(
    table_name = character(),
    column_name = character(),
    query_category = character(),
    strategy = character(),
    estimated_rows = numeric(),
    chunks_fetched = integer(),
    status = character(),
    budget_decision = character(),
    elapsed_ms = numeric(),
    message = character()
  )
}

empty_db_budget_actions <- function() {
  empty_df(
    severity = character(),
    category = character(),
    action_id = character(),
    table_name = character(),
    column_name = character(),
    query_category = character(),
    estimated_rows = numeric(),
    reason = character(),
    current_behavior = character(),
    recommended_action = character()
  )
}

new_db_budget_context <- function(table_name, row_count) {
  query_log <- list()
  budget_actions <- list()
  action_keys <- character()
  add_log <- function(column_name = "", query_category = "", status = "ok",
                      budget_decision = "executed", message = "", elapsed_ms = NA_real_,
                      strategy = "sql_aggregate", chunks_fetched = NA_integer_) {
    query_log[[length(query_log) + 1L]] <<- data.frame(
      table_name = table_name %||% "",
      column_name = column_name %||% "",
      query_category = query_category %||% "",
      strategy = strategy %||% "",
      estimated_rows = suppressWarnings(as.numeric(row_count %||% NA_real_)),
      chunks_fetched = suppressWarnings(as.integer(chunks_fetched %||% NA_integer_)),
      status = status %||% "",
      budget_decision = budget_decision %||% "",
      elapsed_ms = suppressWarnings(as.numeric(elapsed_ms %||% NA_real_)),
      message = message %||% "",
      stringsAsFactors = FALSE
    )
  }
  add_action <- function(column_name = "", query_category = "", reason = "",
                         current_behavior = "Exact aggregate skipped by DB budget.",
                         recommended_action = "Raise the DALYCARE_ATLAS_* budget environment variables only for a deliberately provisioned exact run.") {
    key <- paste(table_name, query_category, column_name, sep = "\r")
    if (key %in% action_keys) return(invisible(FALSE))
    action_keys <<- c(action_keys, key)
    budget_actions[[length(budget_actions) + 1L]] <<- data.frame(
      severity = "warning",
      category = "DB budget",
      action_id = "db_budget_skipped",
      table_name = table_name %||% "",
      column_name = column_name %||% "",
      query_category = query_category %||% "",
      estimated_rows = suppressWarnings(as.numeric(row_count %||% NA_real_)),
      reason = reason %||% "",
      current_behavior = current_behavior,
      recommended_action = recommended_action,
      stringsAsFactors = FALSE
    )
    invisible(TRUE)
  }
  should_skip <- function(query_category, row_limit, column_name = "", reason = "") {
    n <- suppressWarnings(as.numeric(row_count %||% NA_real_))
    if (!atlas_db_budget_mode() || is.na(n) || n <= row_limit) return(FALSE)
    msg <- if (nzchar(reason)) reason else paste0("estimated_rows=", n, " exceeds budget_rows=", row_limit)
    add_log(column_name, query_category, "budget_skipped", "skipped_by_row_budget", msg)
    add_action(column_name, query_category, msg)
    TRUE
  }
  list(
    table_name = table_name,
    row_count = row_count,
    add_log = add_log,
    add_action = add_action,
    should_skip = should_skip,
    query_log = function() bind_rows_base(query_log),
    budget_actions = function() bind_rows_base(budget_actions)
  )
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
  base <- function(status, n_matches = 0L, message = "", match = NULL, row_count = NA_real_,
                   candidate_locations = "", candidate_row_counts = "",
                   suggested_db_name = "", suggested_schema = "", suggested_table = "",
                   suggestion = "") {
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
      candidate_locations = candidate_locations %||% "",
      candidate_row_counts = candidate_row_counts %||% "",
      suggested_db_name = suggested_db_name %||% "",
      suggested_schema = suggested_schema %||% "",
      suggested_table = suggested_table %||% "",
      suggestion = suggestion %||% "",
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
    suggestions <- nearest_table_suggestions(record, tables)
    candidate_locations <- format_table_locations(suggestions)
    missing_message <- if (grepl("^view_", source_record_value(record, "table_name"), ignore.case = TRUE) ||
      grepl("^view_", source_record_value(record, "source"), ignore.case = TRUE)) {
      "Requested DALY view was absent from the live DB catalog."
    } else {
      "No matching table or view was found in the DB catalog."
    }
    suggestion <- if (nrow(suggestions)) {
      paste("No exact alias matched; nearest live catalog matches:", candidate_locations)
    } else {
      "No exact alias matched and no near catalog matches were found; source appears absent from the live catalog."
    }
    return(base(
      "missing",
      message = missing_message,
      candidate_locations = candidate_locations,
      suggested_db_name = if (nrow(suggestions)) suggestions$db_name[[1]] else "",
      suggested_schema = if (nrow(suggestions)) suggestions$schema[[1]] else "",
      suggested_table = if (nrow(suggestions)) suggestions$table[[1]] else "",
      suggestion = suggestion
    ))
  }
  if (nrow(matches) > 1L) {
    return(base(
      "ambiguous",
      n_matches = nrow(matches),
      message = "Multiple DB tables matched this source.",
      candidate_locations = format_table_locations(matches),
      candidate_row_counts = format_table_row_counts(db_adapter, matches),
      suggestion = "Set db_name, schema, and table explicitly in the source map to choose one candidate."
    ))
  }
  row_count <- adapter_table_row_count(db_adapter, matches$db_name[[1]], matches$schema[[1]], matches$table[[1]])
  message <- if (is.na(row_count)) "Resolved DB table; row count unavailable." else "Resolved DB table."
  base(
    "resolved",
    n_matches = 1L,
    message = message,
    match = matches,
    row_count = row_count,
    candidate_locations = format_table_locations(matches),
    candidate_row_counts = format_table_row_counts(db_adapter, matches),
    suggested_db_name = matches$db_name[[1]],
    suggested_schema = matches$schema[[1]],
    suggested_table = matches$table[[1]]
  )
}

format_table_locations <- function(locations, limit = 10L) {
  if (!is.data.frame(locations) || nrow(locations) == 0) return("")
  keep <- seq_len(min(nrow(locations), limit))
  out <- paste(locations$db_name[keep], locations$schema[keep], locations$table[keep], sep = ".")
  if (nrow(locations) > limit) out <- c(out, paste0("+", nrow(locations) - limit, " more"))
  paste(out, collapse = "; ")
}

format_table_row_counts <- function(db_adapter, locations, limit = 10L) {
  if (!is.data.frame(locations) || nrow(locations) == 0) return("")
  keep <- seq_len(min(nrow(locations), limit))
  out <- vapply(keep, function(i) {
    n <- adapter_table_row_count(db_adapter, locations$db_name[[i]], locations$schema[[i]], locations$table[[i]])
    count <- if (is.na(n)) "unavailable" else as.character(format(n, scientific = FALSE, trim = TRUE))
    paste0(locations$db_name[[i]], ".", locations$schema[[i]], ".", locations$table[[i]], "=", count)
  }, character(1))
  if (nrow(locations) > limit) out <- c(out, paste0("+", nrow(locations) - limit, " more"))
  paste(out, collapse = "; ")
}

nearest_table_suggestions <- function(record, tables, limit = 5L) {
  if (!is.data.frame(tables) || nrow(tables) == 0) return(empty_source_resolution_tables())
  candidates <- dalycare_table_candidates(record)
  candidate_keys <- normalized_table_key(candidates)
  candidate_keys <- candidate_keys[nzchar(candidate_keys)]
  if (!length(candidate_keys)) return(tables[0, , drop = FALSE])
  table_keys <- normalized_table_key(tables$table)
  scores <- vapply(seq_along(table_keys), function(i) {
    key <- table_keys[[i]]
    if (!nzchar(key)) return(Inf)
    overlaps <- vapply(candidate_keys, function(candidate_key) {
      grepl(key, candidate_key, fixed = TRUE) || grepl(candidate_key, key, fixed = TRUE)
    }, logical(1))
    if (any(overlaps)) {
      return(0)
    }
    min(as.numeric(adist(key, candidate_keys, partial = TRUE)))
  }, numeric(1))
  order_ix <- order(scores, tables$db_name, tables$schema, tables$table)
  order_ix <- order_ix[is.finite(scores[order_ix])]
  if (!length(order_ix)) return(tables[0, , drop = FALSE])
  tables[head(order_ix, limit), , drop = FALSE]
}

match_table_location <- function(record, tables) {
  if (!nrow(tables)) return(tables)
  requested_db <- source_record_value(record, "db_name")
  requested_schema <- source_record_value(record, "schema")
  requested_table <- source_record_value(record, "table")
  table_key <- normalized_table_key(tables$table)
  filtered_matches <- function(candidates) {
    candidates <- unique(candidates[nzchar(candidates)])
    if (!length(candidates)) return(tables[0, , drop = FALSE])
    ix <- which(table_key %in% normalized_table_key(candidates))
    if (nzchar(requested_db)) {
      ix <- ix[tolower(tables$db_name[ix]) == tolower(requested_db)]
    }
    if (nzchar(requested_schema)) {
      ix <- ix[tolower(tables$schema[ix]) == tolower(requested_schema)]
    }
    if (!length(ix)) return(tables[0, , drop = FALSE])
    tables[ix, , drop = FALSE]
  }

  exact_candidates <- unique(c(
    requested_table,
    source_record_value(record, "source"),
    source_record_value(record, "table_name"),
    make.names(source_record_value(record, "source")),
    make.names(source_record_value(record, "table_name"))
  ))
  exact_matches <- filtered_matches(exact_candidates)
  if (nrow(exact_matches)) return(exact_matches)

  alias_matches <- filtered_matches(dalycare_table_candidates(record))
  if (!nrow(alias_matches)) return(tables[0, , drop = FALSE])
  alias_matches
}

dalycare_table_candidates <- function(record) {
  base <- unique(c(
    source_record_value(record, "table"),
    source_record_value(record, "source"),
    source_record_value(record, "table_name"),
    source_record_value(record, "current_source_key"),
    source_record_value(record, "preferred_table"),
    make.names(source_record_value(record, "source")),
    make.names(source_record_value(record, "table_name")),
    unlist(strsplit(source_record_value(record, "known_aliases"), ";", fixed = TRUE), use.names = FALSE)
  ))
  base <- trimws(base)
  base <- base[nzchar(base)]
  aliases <- dalycare_table_aliases()
  out <- base
  base_keys <- normalized_table_key(base)
  for (family in aliases) {
    family_keys <- normalized_table_key(family)
    if (any(base_keys %in% family_keys)) out <- unique(c(out, family))
  }
  out[nzchar(out)]
}

dalycare_table_aliases <- function() {
  list(
    c("patient", "patients", "patient_table", "view_create_patient_table"),
    c("RKKP_CLL", "rkkp_cll", "clean_RKKP_CLL"),
    c("RKKP_LYFO", "rkkp_lyfo", "clean_RKKP_LYFO"),
    c("RKKP_DaMyDa", "RKKP_DAMYDA", "rkkp_damyda", "clean_RKKP_DAMYDA"),
    c("SP_AdministreretMedicin", "SP_Administreret_Medicin", "AdministreretMedicin"),
    c("SP_OrdineretMedicin", "SP_Ordineret_Medicin", "OrdineretMedicin"),
    c("SP_ADT_haendelser", "SP_ADT_Haendelser", "SP_ADT_Haendelser", "ADT_Haendelser"),
    c("SP_AktiveProblemlisteDiagnoser", "SP_Aktive_Problemliste_Diagnoser", "Aktive_Problemliste_Diagnoser", "SP_ActiveDx", "ActiveDx"),
    c("SP_AlleProvesvar", "SP_AlleProevesvar", "AlleProvesvar", "AlleProevesvar"),
    c("SP_BehandlingskontakterOgDiagnoser", "SP_Behandlingskontakter_diagnoser", "Behandlingskontakter_diagnoser"),
    c("SP_Behandlingsniveau", "Behandlingsniveau"),
    c("SP_BilleddiagnostiskeUndersoegelser_Del1", "BilleddiagnostiskeUndersoegelser_Del1"),
    c("SP_BilleddiagnostiskeUndersoegelser_Del2", "BilleddiagnostiskeUndersoegelser_Del2"),
    c("SP_BilleddiagnostikeUndersoegelser_Del1", "SP_BilleddiagnostiskeUndersoegelser_Del1", "SP_BilleddiagnostiskeUndersøgelser_Del1", "SP_BilleddiagnostiskeUndersÃ¸gelser_Del1", "BilleddiagnostikeUndersoegelser_Del1"),
    c("SP_BilleddiagnostikeUndersoegelser_Del2", "SP_BilleddiagnostiskeUndersoegelser_Del2", "SP_BilleddiagnostiskeUndersøgelser_Del2", "SP_BilleddiagnostiskeUndersÃ¸gelser_Del2", "BilleddiagnostikeUndersoegelser_Del2"),
    c("SP_Behandlingsplaner_Del1", "SP_Behandlingsplaner_del1", "Behandlingsplaner_Del1", "Behandlingsplaner_del1"),
    c("SP_Behandlingsplaner_Del2", "SP_Behandlingsplaner_del2", "Behandlingsplaner_Del2", "Behandlingsplaner_del2"),
    c("SP_Bloddyrkning_Del1", "SP_Bloddyrkning_del1", "Bloddyrkning_Del1"),
    c("SP_Bloddyrkning_Del2", "SP_Bloddyrkning_del2", "Bloddyrkning_Del2"),
    c("SP_Bloddyrkning_Del3", "SP_Bloddyrkning_del3", "Bloddyrkning_Del3"),
    c("SP_Bloddyrkning_Del4", "SP_Bloddyrkning_del4", "Bloddyrkning_Del4"),
    c("SP_ITAOphold", "ITA_Ophold", "ITAOphold"),
    c("SP_Journalnotater_Del1", "SP_Journalnotater_del1", "Journalnotater_Del1"),
    c("SP_Journalnotater_Del2", "SP_Journalnotater_del2", "Journalnotater_Del2"),
    c("SP_SocialHX", "SocialHX", "social_history"),
    c("SP_VitaleVaerdier", "SP_VitaleVærdier", "SP_VitaleVÃ¦rdier", "VitaleVaerdier"),
    c("SDS_lab_forsker", "SDS_laboratorieproevesvar", "SDS_laboratorieprøvesvar"),
    c("SDS_lab_labidcodes", "SDS_dimlaboratoriekoder", "labidcodes"),
    c("SDS_t_mikro_ny", "SDS_t_mikro_ny_distinct", "SDS_t_mikro", "t_mikro", "t_mikro_ny", "t_mikro_ny_distinct"),
    c("SDS_t_konk_ny", "SDS_t_konk", "t_konk", "t_konk_ny"),
    c("SDS_t_dodsaarsag_2", "SDS_t_doedsaarsag", "SDS_doedsaarsag_3", "SDS_dodsaarsag"),
    c("SDS_t_tumor", "SDS_tumor_aarlig", "SDS_tumor"),
    c("SDS_procedurer_kirurgi", "SDS_procedure_kirurgi", "procedurer_kirurgi", "procedure_kirurgi"),
    c("SDS_procedurer_andre", "SDS_procedure_andre", "procedurer_andre", "procedure_andre"),
    c("SDS_t_adm", "SDS_admissioner", "admissioner"),
    c("SDS_forloeb", "SDS_forløb", "forloeb"),
    c("SDS_kontakter", "kontakter"),
    c("SDS_t_sksopr", "SDS_sksopr"),
    c("SDS_t_sksube", "SDS_sksube"),
    c("SDS_t_diag", "SDS_diag"),
    c("SDS_t_udtilsgh", "SDS_udtilsgh"),
    c("SDS_diagnoser", "diagnoser"),
    c("SDS_resultater", "resultater"),
    c("SDS_koder", "koder"),
    c("SDS_organisationer", "organisationer"),
    c("SDS_epikur", "epikur"),
    c("SDS_indberetningmedpris", "indberetningmedpris"),
    c("SDS_pato", "pato"),
    c("PERSIMUNE_biochemistry", "biochemistry"),
    c("PERSIMUNE_microbiology_analysis", "microbiology_analysis"),
    c("PERSIMUNE_microbiology_culture", "microbiology_culture"),
    c("PERSIMUNE_microbiology_culture_resistance", "microbiology_culture_resistance"),
    c("PERSIMUNE_microbiology_microscopy", "microbiology_microscopy"),
    c("LAB_BIOBANK_SAMPLES", "BIOBANK_SAMPLES"),
    c("LAB_CLLPANEL_WIDE", "CLLPANEL_WIDE"),
    c("LAB_IGHVIMGT", "IGHVIMGT"),
    c("LAB_Flowcytometry", "Flowcytometry"),
    c("LAB_FISH", "FISH"),
    c("MM_TREAT_DARA", "REQUIRE_PERMISSION_MM_TREAT_DARA", "MM_TREATED_WITH_DARATUMUMAB", "mm_treat_dara", "mm_treated_with_daratumumab"),
    c("CLL_TREAT", "CLL_2ND_LINE_TREATMENT"),
    c("CLL_TREAT_IBRUTINIB", "CLL_TREATED_WTIH_IBRUTINIB", "CLL_TREATED_WITH_IBRUTINIB"),
    c("DANRICHT", "danricht", "Richter"),
    c("t_dalycare_diagnoses", "dalycare_diagnoses"),
    c("view_diagnosses_all", "view_diagnoses_all", "diagnoses_all", "diagnosses_all"),
    c("view_diagnoses_all_hosp_region", "diagnoses_all_hosp_region"),
    c("view_date_death", "date_death"),
    c("view_date_followup", "date_followup"),
    c("view_true_date_death", "true_date_death"),
    c("view_dalycare_diagnoses", "dalycare_diagnoses_view"),
    c("view_patient_table_os", "patient_table_os")
  )
}

normalized_table_key <- function(x) {
  x <- as.character(x)
  x <- gsub("Ã¸|ø|Ø", "oe", x)
  x <- gsub("Ã¦|æ|Æ", "ae", x)
  x <- gsub("Ã¥|å|Å", "aa", x)
  folded <- suppressWarnings(iconv(x, from = "", to = "ASCII//TRANSLIT", sub = ""))
  folded[is.na(folded)] <- x[is.na(folded)]
  gsub("[^a-z0-9]", "", tolower(folded))
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
    candidate_locations = "",
    candidate_row_counts = "",
    suggested_db_name = "",
    suggested_schema = "",
    suggested_table = "",
    suggestion = "",
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
    should_stream <- isTRUE(atlas_db_stream_rows()) &&
      !is.na(row_count) &&
      row_count > atlas_stream_threshold_rows()
    chosen_strategy <- if (identical(requested_strategy, "db_chunked") || isTRUE(should_stream)) "db_chunked" else "db_aggregate"
    status <- "ok"
    message <- if (identical(chosen_strategy, "db_chunked")) {
      "Resolved source will use DB cursor/chunk profiling for large-table memory safety."
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
                              top_n = 10L, min_cell_count = atlas_min_cell_count(),
                              npu_dictionary = NULL,
                              npu_surfaces = NULL,
                              isotype_vectors = NULL,
                              treatment_families = NULL) {
  if (is.null(db_adapter)) {
    stop("DB aggregate profiling requested but no DB adapter was available.", call. = FALSE)
  }
  if (!is.function(db_adapter$profile_table)) {
    stop("DB adapter does not provide profile_table().", call. = FALSE)
  }
  profile_mode <- normalize_profile_mode(profile_mode %||% source_record_value(source_record, "profile_mode", "full"))
  args <- list(
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
  formals_names <- names(formals(db_adapter$profile_table))
  if ("npu_dictionary" %in% formals_names || "..." %in% formals_names) {
    args$npu_dictionary <- npu_dictionary
  }
  if ("npu_surfaces" %in% formals_names || "..." %in% formals_names) {
    args$npu_surfaces <- npu_surfaces
  }
  if ("isotype_vectors" %in% formals_names || "..." %in% formals_names) {
    args$isotype_vectors <- isotype_vectors
  }
  if ("treatment_families" %in% formals_names || "..." %in% formals_names) {
    args$treatment_families <- treatment_families
  }
  out <- do.call(db_adapter$profile_table, args)
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
  out$db_query_log <- out$db_query_log %||% empty_db_query_log()
  out$db_budget_actions <- out$db_budget_actions %||% empty_db_budget_actions()
  out
}

dbi_list_tables <- function(connections) {
  known <- atlas_known_daly_db_schemas()
  rows <- lapply(names(connections), function(db_name) {
    conn <- connections[[db_name]]
    schemas <- unique(known$schema[known$db_name == db_name])
    if (!length(schemas)) schemas <- unique(known$schema)
    schema_sql <- paste(as.character(DBI::dbQuoteString(conn, schemas)), collapse = ", ")
    sql <- paste(
      "select current_database() as db_name, table_schema as schema, table_name as table",
      "from information_schema.tables",
      "where table_schema in (", schema_sql, ")",
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
                              min_cell_count = atlas_min_cell_count(),
                              npu_dictionary = NULL,
                              npu_surfaces = NULL,
                              isotype_vectors = NULL,
                              treatment_families = NULL) {
  conn <- dbi_connection_for(connections, db_name)
  profile_mode <- normalize_profile_mode(profile_mode)
  schema_info <- dbi_table_schema(connections, db_name, schema, table)
  row_count <- dbi_table_row_count(connections, db_name, schema, table)
  table_ref <- dbi_table_ref(conn, schema, table)
  budget_context <- new_db_budget_context(table_name, row_count)
  profile_strategy <- dbi_profile_strategy(row_count, profile_mode)
  budget_context$add_log(
    column_name = "",
    query_category = "table_profile",
    status = "ok",
    budget_decision = profile_strategy,
    message = paste("Selected DB profile strategy:", profile_strategy),
    strategy = profile_strategy
  )
  profile_bundle <- dbi_column_profile_bundle(
    conn = conn,
    table_ref = table_ref,
    schema_info = schema_info,
    table_name = table_name,
    row_count = row_count,
    profile_mode = profile_mode,
    profile_strategy = profile_strategy,
    top_n = top_n,
    min_cell_count = min_cell_count,
    budget_context = budget_context
  )
  column_profiles <- profile_bundle$column_profiles
  columns <- dbi_columns_from_profiles(column_profiles)
  top_values <- if (!is.null(profile_bundle$column_top_values)) {
    profile_bundle$column_top_values
  } else if (identical(profile_mode, "full")) {
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
    message = "",
    stringsAsFactors = FALSE
  )
  panels <- if (identical(profile_mode, "schema")) {
    list()
  } else {
    dbi_panels_from_profiles(
      column_profiles = column_profiles,
      source_row = source_row,
      conn = conn,
      table_ref = table_ref,
      profile_strategy = profile_strategy,
      stream_profile_bundle = profile_bundle,
      budget_context = budget_context,
      npu_dictionary = npu_dictionary,
      npu_surfaces = npu_surfaces,
      isotype_vectors = isotype_vectors,
      treatment_families = treatment_families,
      min_cell_count = min_cell_count
    )
  }
  list(
    source = source_row,
    columns = columns,
    column_profiles = column_profiles,
    column_top_values = top_values,
    checks = dbi_checks_from_columns(table_name, schema_info$column_name),
    value_frequencies = frequencies,
    panels = panels,
    db_query_log = budget_context$query_log(),
    db_budget_actions = budget_context$budget_actions()
  )
}

dbi_profile_strategy <- function(row_count, profile_mode = "full") {
  if (identical(normalize_profile_mode(profile_mode), "schema")) return("schema_metadata")
  n <- suppressWarnings(as.numeric(row_count %||% NA_real_))
  if (isTRUE(atlas_db_stream_rows()) && !is.na(n) && n > atlas_stream_threshold_rows()) {
    return("stream_column")
  }
  "sql_aggregate"
}

dbi_column_profile_bundle <- function(conn, table_ref, schema_info, table_name, row_count, profile_mode,
                                      profile_strategy = "sql_aggregate", top_n = 10L,
                                      min_cell_count = atlas_min_cell_count(),
                                      budget_context = new_db_budget_context(table_name, row_count)) {
  profile_strategy <- profile_strategy %||% "sql_aggregate"
  if (identical(profile_strategy, "schema_metadata")) {
    return(list(
      column_profiles = dbi_schema_column_profiles(schema_info, table_name, row_count),
      column_top_values = empty_column_top_values(),
      categorical_counts = list(),
      date_year_counts = list()
    ))
  }
  if (identical(profile_strategy, "stream_column")) {
    return(dbi_stream_column_profiles(
      conn = conn,
      table_ref = table_ref,
      schema_info = schema_info,
      table_name = table_name,
      row_count = row_count,
      profile_mode = profile_mode,
      top_n = top_n,
      min_cell_count = min_cell_count,
      budget_context = budget_context
    ))
  }
  list(
    column_profiles = dbi_column_profiles(conn, table_ref, schema_info, table_name, row_count, profile_mode),
    column_top_values = NULL,
    categorical_counts = list(),
    date_year_counts = list()
  )
}

dbi_schema_column_profiles <- function(schema_info, table_name, row_count) {
  if (!nrow(schema_info)) return(empty_column_profiles())
  rows <- lapply(seq_len(nrow(schema_info)), function(i) {
    info <- schema_info[i, , drop = FALSE]
    column_name <- as.character(info$column_name[[1]])
    column_type <- as.character(info$data_type[[1]] %||% "")
    column_class <- as.character(info$udt_name[[1]] %||% column_type)
    is_sensitive <- is_sensitive_column(column_name)
    is_sql_date <- sql_type_is_date(column_type, column_class)
    is_text_date <- likely_text_date_column(column_name, column_type, column_class)
    is_date_like <- (is_sql_date || is_text_date) && !is_sensitive
    is_numeric_like <- sql_type_is_numeric(column_type, column_class) && !is_sensitive && !is_date_like
    data.frame(
      table_name = table_name,
      column_name = column_name,
      column_type = column_type,
      column_class = column_class,
      profile_kind = if (is_sensitive) "sensitive" else if (is_date_like) "date" else if (is_numeric_like) "numeric" else "categorical",
      n_rows = row_count,
      n_available = NA_real_,
      pct_available = NA_real_,
      n_missing = NA_real_,
      pct_missing = NA_real_,
      n_distinct_capped = NA_real_,
      is_sensitive = is_sensitive,
      is_date_like = is_date_like,
      is_numeric_like = is_numeric_like,
      min = NA_real_,
      mean = NA_real_,
      median = NA_real_,
      p25 = NA_real_,
      p75 = NA_real_,
      max = NA_real_,
      min_date = NA_character_,
      max_date = NA_character_,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

dbi_stream_column_profiles <- function(conn, table_ref, schema_info, table_name, row_count, profile_mode,
                                       top_n = 10L, min_cell_count = atlas_min_cell_count(),
                                       budget_context = new_db_budget_context(table_name, row_count)) {
  if (!nrow(schema_info)) {
    return(list(
      column_profiles = empty_column_profiles(),
      column_top_values = empty_column_top_values(),
      categorical_counts = list(),
      date_year_counts = list()
    ))
  }
  rows <- list()
  top_values <- list()
  categorical_counts <- list()
  date_year_counts <- list()
  for (i in seq_len(nrow(schema_info))) {
    info <- schema_info[i, , drop = FALSE]
    prof <- dbi_stream_column_profile(
      conn = conn,
      table_ref = table_ref,
      info = info,
      table_name = table_name,
      row_count = row_count,
      profile_mode = profile_mode,
      top_n = top_n,
      min_cell_count = min_cell_count,
      budget_context = budget_context,
      column_index = i,
      column_total = nrow(schema_info)
    )
    rows[[length(rows) + 1L]] <- prof$profile
    if (nrow(prof$top_values)) top_values[[length(top_values) + 1L]] <- prof$top_values
    if (length(prof$categorical_counts)) categorical_counts[[prof$profile$column_name[[1]]]] <- prof$categorical_counts
    if (length(prof$date_year_counts)) date_year_counts[[prof$profile$column_name[[1]]]] <- prof$date_year_counts
    gc(verbose = FALSE)
  }
  list(
    column_profiles = bind_rows_base(rows),
    column_top_values = {
      out <- bind_rows_base(top_values)
      if (!nrow(out)) empty_column_top_values() else out
    },
    categorical_counts = categorical_counts,
    date_year_counts = date_year_counts
  )
}

dbi_stream_column_profile <- function(conn, table_ref, info, table_name, row_count, profile_mode,
                                      top_n = 10L, min_cell_count = atlas_min_cell_count(),
                                      budget_context = new_db_budget_context(table_name, row_count),
                                      column_index = NA_integer_, column_total = NA_integer_) {
  column_name <- as.character(info$column_name[[1]])
  column_type <- as.character(info$data_type[[1]] %||% "")
  column_class <- as.character(info$udt_name[[1]] %||% column_type)
  is_sensitive <- is_sensitive_column(column_name)
  is_sql_date <- sql_type_is_date(column_type, column_class)
  is_text_date <- likely_text_date_column(column_name, column_type, column_class)
  is_date_like <- (is_sql_date || is_text_date) && !is_sensitive
  is_numeric_like <- sql_type_is_numeric(column_type, column_class) && !is_sensitive && !is_date_like
  profile_kind <- if (is_sensitive) "sensitive" else if (is_date_like) "date" else if (is_numeric_like) "numeric" else "categorical"
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  select_expr <- if (is_sensitive) {
    paste0("(", qcol, " is null or btrim(", qcol, "::text) = '') as is_missing")
  } else {
    paste0(qcol, " as value")
  }
  sql <- paste0("select ", select_expr, " from ", table_ref)
  chunk_size <- atlas_stream_chunk_size()
  started <- proc.time()[["elapsed"]]
  result <- NULL
  chunks <- 0L
  total_rows <- 0
  estimated_chunks <- if (!is.na(suppressWarnings(as.numeric(row_count))) && row_count > 0) ceiling(as.numeric(row_count) / chunk_size) else NA_integer_
  progress_interval <- atlas_progress_seconds()
  last_progress <- started
  n_missing <- 0
  numeric_n <- 0
  numeric_sum <- 0
  numeric_min <- Inf
  numeric_max <- -Inf
  numeric_sample <- numeric()
  sample_limit <- atlas_quantile_sample_size()
  date_min <- as.Date(NA)
  date_max <- as.Date(NA)
  year_counts <- new.env(parent = emptyenv())
  category_counts <- new.env(parent = emptyenv())
  category_overflow <- FALSE
  max_categories <- atlas_max_tracked_categories()
  status <- "ok"
  message <- "streamed one column in bounded chunks"

  progress_line <- function(final = FALSE) {
    if (!atlas_progress_enabled()) return(invisible(NULL))
    elapsed <- proc.time()[["elapsed"]] - started
    if (!isTRUE(final) && chunks > 0L && elapsed - (last_progress - started) < progress_interval) {
      return(invisible(NULL))
    }
    chunk_label <- if (is.na(estimated_chunks)) as.character(chunks) else paste0(chunks, "/", estimated_chunks)
    row_label <- paste0(atlas_format_count(total_rows), "/", atlas_format_count(row_count))
    prefix <- if (isTRUE(final) && !identical(status, "ok")) "failed" else if (isTRUE(final)) "done" else "progress"
    cat(sprintf(
      "      %s: column %s/%s %s: chunk %s, rows %s, elapsed %s\n",
      prefix,
      atlas_format_count(column_index),
      atlas_format_count(column_total),
      column_name,
      chunk_label,
      row_label,
      atlas_elapsed_label(elapsed)
    ))
    flush.console()
    last_progress <<- proc.time()[["elapsed"]]
    invisible(NULL)
  }

  if (atlas_progress_enabled()) {
    cat(sprintf(
      "      streaming column %s/%s %s (%s rows, chunk %s)\n",
      atlas_format_count(column_index),
      atlas_format_count(column_total),
      column_name,
      atlas_format_count(row_count),
      atlas_format_count(chunk_size)
    ))
    flush.console()
  }

  update_categories <- function(values) {
    if (category_overflow || !length(values)) return(invisible(NULL))
    values <- truncate_value(values)
    tab <- table(values, useNA = "no")
    if (!length(tab)) return(invisible(NULL))
    for (nm in names(tab)) {
      old <- if (exists(nm, envir = category_counts, inherits = FALSE)) get(nm, envir = category_counts, inherits = FALSE) else 0
      assign(nm, old + as.integer(tab[[nm]]), envir = category_counts)
    }
    if (length(ls(envir = category_counts, all.names = TRUE)) > max_categories) {
      rm(list = ls(envir = category_counts, all.names = TRUE), envir = category_counts)
      category_overflow <<- TRUE
    }
    invisible(NULL)
  }
  update_years <- function(values) {
    dates <- safe_as_date(values)
    dates <- dates[!is.na(dates)]
    if (!length(dates)) return(invisible(NULL))
    date_min <<- if (is.na(date_min)) min(dates) else min(date_min, min(dates))
    date_max <<- if (is.na(date_max)) max(dates) else max(date_max, max(dates))
    years <- suppressWarnings(as.integer(format(dates, "%Y")))
    years <- years[!is.na(years)]
    if (!length(years)) return(invisible(NULL))
    tab <- table(years)
    for (nm in names(tab)) {
      old <- if (exists(nm, envir = year_counts, inherits = FALSE)) get(nm, envir = year_counts, inherits = FALSE) else 0
      assign(nm, old + as.integer(tab[[nm]]), envir = year_counts)
    }
    invisible(NULL)
  }
  update_numeric <- function(values) {
    nums <- suppressWarnings(as.numeric(as.character(values)))
    nums <- nums[!is.na(nums)]
    if (!length(nums)) return(invisible(NULL))
    numeric_n <<- numeric_n + length(nums)
    numeric_sum <<- numeric_sum + sum(nums)
    numeric_min <<- min(numeric_min, min(nums))
    numeric_max <<- max(numeric_max, max(nums))
    if (length(numeric_sample) < sample_limit) {
      room <- sample_limit - length(numeric_sample)
      numeric_sample <<- c(numeric_sample, head(nums, room))
    }
    invisible(NULL)
  }

  tryCatch({
    result <- DBI::dbSendQuery(conn, sql)
    repeat {
      chunk <- DBI::dbFetch(result, n = chunk_size)
      if (!nrow(chunk)) break
      chunks <- chunks + 1L
      total_rows <- total_rows + nrow(chunk)
      progress_line()
      if (is_sensitive) {
        missing <- as.logical(chunk[[1]])
        missing[is.na(missing)] <- TRUE
        n_missing <- n_missing + sum(missing)
        next
      }
      values <- chunk[[1]]
      missing <- is.na(values) | trimws(as.character(values)) == ""
      n_missing <- n_missing + sum(missing)
      available <- values[!missing]
      if (!length(available)) next
      if (is_numeric_like) {
        update_numeric(available)
      } else if (is_date_like) {
        update_years(available)
      } else if (!identical(normalize_profile_mode(profile_mode), "schema")) {
        update_categories(as.character(available))
      }
    }
  }, error = function(e) {
    status <<- "error"
    message <<- conditionMessage(e)
  }, finally = {
    if (!is.null(result)) {
      try(DBI::dbClearResult(result), silent = TRUE)
    }
  })
  progress_line(final = TRUE)
  elapsed_ms <- round(1000 * (proc.time()[["elapsed"]] - started), 1)
  budget_context$add_log(
    column_name = column_name,
    query_category = "column_stream",
    status = status,
    budget_decision = if (identical(status, "ok")) "streamed" else "stream_failed",
    message = message,
    elapsed_ms = elapsed_ms,
    strategy = "stream_column",
    chunks_fetched = chunks
  )
  if (is_numeric_like && numeric_n > sample_limit) {
    budget_context$add_action(
      column_name = column_name,
      query_category = "numeric_quantiles",
      reason = paste("median/p25/p75 estimated from first", sample_limit, "non-missing streamed numeric values."),
      current_behavior = "Exact min, max, mean, availability, and missingness were streamed; quantiles are bounded-sample approximations.",
      recommended_action = "Increase DALYCARE_ATLAS_QUANTILE_SAMPLE_SIZE for tighter approximate quantiles, or lower the streaming threshold for a provisioned exact SQL run."
    )
  }
  if (category_overflow) {
    budget_context$add_action(
      column_name = column_name,
      query_category = "categorical_top_values",
      reason = paste("distinct values exceeded DALYCARE_ATLAS_MAX_TRACKED_CATEGORIES =", max_categories),
      current_behavior = "The atlas kept coverage/missingness but suppressed value display for this high-cardinality column.",
      recommended_action = "Raise DALYCARE_ATLAS_MAX_TRACKED_CATEGORIES only for a targeted run if this column is safe and operationally important."
    )
  }

  n_rows <- suppressWarnings(as.numeric(row_count %||% total_rows))
  if (is.na(n_rows) || n_rows < total_rows) n_rows <- total_rows
  n_available <- if (is.na(n_rows)) NA_real_ else n_rows - n_missing
  numeric_stats <- if (is_numeric_like && numeric_n > 0) {
    list(
      min = numeric_min,
      mean = numeric_sum / numeric_n,
      median = stats::median(numeric_sample, na.rm = TRUE),
      p25 = as.numeric(stats::quantile(numeric_sample, 0.25, na.rm = TRUE, names = FALSE)),
      p75 = as.numeric(stats::quantile(numeric_sample, 0.75, na.rm = TRUE, names = FALSE)),
      max = numeric_max
    )
  } else {
    list(min = NA_real_, mean = NA_real_, median = NA_real_, p25 = NA_real_, p75 = NA_real_, max = NA_real_)
  }
  date_stats <- if (is_date_like && !is.na(date_min) && !is.na(date_max)) {
    list(min_date = as.character(date_min), max_date = as.character(date_max))
  } else {
    list(min_date = NA_character_, max_date = NA_character_)
  }
  counts <- if (!category_overflow) env_numeric_counts(category_counts) else numeric()
  n_distinct <- if (is_sensitive) {
    NA_real_
  } else if (category_overflow) {
    max_categories + 1L
  } else if (profile_kind == "categorical") {
    length(counts)
  } else {
    NA_real_
  }
  top_values <- empty_column_top_values()
  if (identical(normalize_profile_mode(profile_mode), "full") && profile_kind == "categorical" &&
      !category_overflow && length(counts) && length(counts) <= 100L) {
    keep <- counts[counts >= normalize_min_cell_count(min_cell_count)]
    if (length(keep)) {
      keep <- sort(keep, decreasing = TRUE)
      keep <- head(keep, top_n)
      labels <- names(keep)
      keep <- keep[!looks_cpr_like(labels)]
      labels <- names(keep)
      if (length(keep)) {
        top_values <- data.frame(
          table_name = table_name,
          column_name = column_name,
          value = labels,
          n = as.integer(keep),
          pct_rows = vapply(as.integer(keep), safe_pct, numeric(1), denom = n_rows),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  year_count_values <- env_numeric_counts(year_counts)
  list(
    profile = data.frame(
      table_name = table_name,
      column_name = column_name,
      column_type = column_type,
      column_class = column_class,
      profile_kind = profile_kind,
      n_rows = n_rows,
      n_available = n_available,
      pct_available = safe_pct(n_available, n_rows),
      n_missing = n_missing,
      pct_missing = safe_pct(n_missing, n_rows),
      n_distinct_capped = pmin(n_distinct, 100000),
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
    ),
    top_values = top_values,
    categorical_counts = counts,
    date_year_counts = year_count_values
  )
}

env_numeric_counts <- function(env) {
  names <- ls(envir = env, all.names = TRUE)
  if (!length(names)) return(numeric())
  stats::setNames(
    vapply(names, function(nm) suppressWarnings(as.numeric(get(nm, envir = env, inherits = FALSE))), numeric(1)),
    names
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
  skip_distinct <- dbi_skip_distinct_count(column_type, column_class, row_count)
  counts <- dbi_column_counts(conn, table_ref, qcol, include_distinct = !skip_distinct)
  is_sensitive <- is_sensitive_column(column_name)
  is_sql_date <- sql_type_is_date(column_type, column_class)
  is_text_date <- likely_text_date_column(column_name, column_type, column_class)
  is_date_like <- (is_sql_date || is_text_date) && !is_sensitive
  is_numeric_like <- sql_type_is_numeric(column_type, column_class) && !is_sensitive && !is_date_like
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
  date_stats <- if (is_text_date && !is_sensitive) {
    dbi_text_date_stats(conn, table_ref, qcol, enabled = is_date_like && !identical(profile_mode, "schema"))
  } else {
    dbi_date_stats(conn, table_ref, qcol, enabled = is_date_like && !identical(profile_mode, "schema"))
  }
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

dbi_skip_distinct_count <- function(column_type, column_class, row_count) {
  if (is.na(row_count)) return(FALSE)
  is_text <- sql_type_is_text(column_type, column_class)
  isTRUE(is_text) && suppressWarnings(as.numeric(row_count)) > atlas_max_text_distinct_rows()
}

sql_type_is_text <- function(column_type, column_class) {
  values <- tolower(c(column_type %||% "", column_class %||% ""))
  any(values %in% c("text", "varchar", "bpchar", "char", "character varying", "character"))
}

dbi_column_counts <- function(conn, table_ref, qcol, include_distinct = TRUE) {
  distinct_sql <- if (isTRUE(include_distinct)) {
    paste0("count(distinct ", qcol, ")")
  } else {
    "cast(null as double precision)"
  }
  sql <- paste0(
    "select ",
    "sum(case when ", qcol, " is null or btrim(", qcol, "::text) = '' then 1 else 0 end) as n_missing, ",
    distinct_sql, " as n_distinct ",
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

dbi_text_date_stats <- function(conn, table_ref, qcol, enabled = TRUE) {
  empty <- list(min_date = NA_character_, max_date = NA_character_)
  if (!isTRUE(enabled)) return(empty)
  expr <- dbi_text_date_string_expression(qcol)
  sql <- paste0(
    "select min(date_value) as min_date, max(date_value) as max_date ",
    "from (select ", expr, " as date_value from ", table_ref, ") atlas_text_dates ",
    "where date_value is not null"
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

likely_text_date_column <- function(column_name, column_type, column_class = "") {
  if (!sql_type_is_text(column_type, column_class)) return(FALSE)
  name <- tolower(as.character(column_name %||% ""))
  if (grepl("kode|code|type|navn|name|list|status|diagnosekode|diagnosetype|aktionsdiagnose|dx_", name)) {
    return(FALSE)
  }
  grepl(
    paste(
      c(
        "(^|_)dt$",
        "_dt$",
        "dato$",
        "(^|_)date$",
        "diagnosedato",
        "diagnos.*(_dt|dato|date)$",
        "kontakt.*(dato|date|time|dttm)$",
        "behandling.*(dato|date)$",
        "treatment.*date$",
        "response.*date$",
        "startdato",
        "slutdato",
        "time$",
        "dttm$"
      ),
      collapse = "|"
    ),
    name
  )
}

dbi_text_date_string_expression <- function(qcol) {
  value <- paste0("btrim(", qcol, "::text)")
  digits <- paste0("regexp_replace(", value, ", '[^0-9]', '', 'g')")
  paste0(
    "case when ", value, " ~ '^[0-9]{4}[-/]?[0-9]{2}[-/]?[0-9]{2}' ",
    "then substring(", digits, " from 1 for 4) || '-' || substring(", digits, " from 5 for 2) || '-' || substring(", digits, " from 7 for 2) ",
    "else null end"
  )
}

dbi_date_year_expression <- function(qcol, column_type = "", column_class = "") {
  if (sql_type_is_text(column_type, column_class)) {
    date_value <- dbi_text_date_string_expression(qcol)
    date_value <- paste0("(", date_value, ")")
    return(paste0(
      "case when ", date_value, " is not null ",
      "then substring(", date_value, " from 1 for 4)::integer else null end"
    ))
  }
  paste0("extract(year from ", qcol, "::date)::integer")
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

dbi_npu_code_counts <- function(conn, table_ref, column_name, table_name, row_count,
                                min_cell_count = atlas_min_cell_count()) {
  if (is.na(column_name) || !nzchar(column_name)) {
    return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  }
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  sql <- paste0(
    "select npu_code, count(*) as n_observed from (",
    "select upper(regexp_replace((regexp_match(upper(", qcol, "::text), 'NPU[[:space:]_-]*[0-9]+'))[1], '[^A-Z0-9]', '', 'g')) as npu_code ",
    "from ", table_ref, " where ", qcol, " is not null and ", qcol, "::text ~* 'NPU[[:space:]_-]*[0-9]+'",
    ") x where npu_code is not null group by npu_code having count(*) >= ",
    as.integer(normalize_min_cell_count(min_cell_count)),
    " order by n_observed desc, npu_code"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(npu_code = character(), n_observed = integer()))
  if (!nrow(out)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  data.frame(
    npu_code = as.character(out$npu_code),
    n_observed = suppressWarnings(as.integer(out$n_observed)),
    pct_rows = vapply(suppressWarnings(as.integer(out$n_observed)), safe_pct, numeric(1), denom = row_count),
    stringsAsFactors = FALSE
  )
}

dbi_npu_source_year_counts <- function(conn, table_ref, code_column, year_column, row_count,
                                       min_cell_count = atlas_min_cell_count()) {
  if (is.na(code_column) || !nzchar(code_column) || is.na(year_column) || !nzchar(year_column)) {
    return(empty_npu_detective_source_year())
  }
  qcode <- DBI::dbQuoteIdentifier(conn, code_column)
  qyear <- DBI::dbQuoteIdentifier(conn, year_column)
  sql <- paste0(
    "select year, npu_code, count(*) as n_observed from (",
    "select extract(year from ", qyear, "::date)::integer as year, ",
    "upper(regexp_replace((regexp_match(upper(", qcode, "::text), 'NPU[[:space:]_-]*[0-9]+'))[1], '[^A-Z0-9]', '', 'g')) as npu_code ",
    "from ", table_ref,
    " where ", qcode, " is not null and ", qyear, " is not null and ", qcode, "::text ~* 'NPU[[:space:]_-]*[0-9]+'",
    ") x where year is not null and npu_code is not null ",
    "group by year, npu_code having count(*) >= ", as.integer(normalize_min_cell_count(min_cell_count)),
    " order by year, n_observed desc, npu_code"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(year = integer(), npu_code = character(), n_observed = integer()))
  if (!nrow(out)) return(empty_df(year = integer(), npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  data.frame(
    year = suppressWarnings(as.integer(out$year)),
    npu_code = as.character(out$npu_code),
    n_observed = suppressWarnings(as.integer(out$n_observed)),
    pct_rows = vapply(suppressWarnings(as.integer(out$n_observed)), safe_pct, numeric(1), denom = row_count),
    stringsAsFactors = FALSE
  )
}

dbi_npu_source_year_panel <- function(conn, table_ref, code_column, year_column, table_name, row_count,
                                      dictionary, surfaces, min_cell_count = atlas_min_cell_count()) {
  counts <- dbi_npu_source_year_counts(conn, table_ref, code_column, year_column, row_count, min_cell_count = min_cell_count)
  if (!nrow(counts)) return(empty_npu_detective_source_year())
  inventory <- npu_detective_inventory_from_counts(
    counts = data.frame(npu_code = counts$npu_code, n_observed = counts$n_observed, stringsAsFactors = FALSE),
    table_name = table_name,
    code_column = code_column,
    denom = row_count,
    dictionary = dictionary,
    surfaces = surfaces,
    min_cell_count = min_cell_count
  )
  if (!nrow(inventory)) return(empty_npu_detective_source_year())
  data.frame(
    table_name = table_name,
    code_column = code_column,
    year_column = year_column,
    year = counts$year,
    npu_code = counts$npu_code,
    consensus_vector = inventory$consensus_vector[match(counts$npu_code, inventory$npu_code)],
    surface = inventory$surface[match(counts$npu_code, inventory$npu_code)],
    n_observed = counts$n_observed,
    pct_rows = counts$pct_rows,
    stringsAsFactors = FALSE
  )
}

dbi_treatment_code_columns <- function(column_profiles, table_name) {
  if (is.null(column_profiles) || !nrow(column_profiles) || !likely_treatment_source(table_name)) return(character())
  column_names <- as.character(column_profiles$column_name)
  fake <- as.data.frame(stats::setNames(rep(list(character()), length(column_names)), column_names), stringsAsFactors = FALSE)
  treatment_code_column_candidates(fake)
}

dbi_rule_condition <- function(conn, column_name, rule) {
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  normalized <- paste0("upper(regexp_replace(coalesce(", qcol, "::text, ''), '[^A-Za-z0-9]', '', 'g'))")
  code <- DBI::dbQuoteString(conn, normalize_generic_code(rule$code[[1]]))
  if (identical(rule$match_type[[1]], "prefix")) {
    paste0(normalized, " like ", DBI::dbQuoteString(conn, paste0(normalize_generic_code(rule$code[[1]]), "%")))
  } else {
    paste0(normalized, " = ", code)
  }
}

dbi_mm_treatment_code_counts <- function(conn, table_ref, column_profiles, source_row, treatment_families,
                                         min_cell_count = atlas_min_cell_count()) {
  if (is.null(treatment_families) || !nrow(treatment_families)) return(empty_mm_treatment_code_counts())
  table_name <- source_row$table_name[[1]]
  code_cols <- dbi_treatment_code_columns(column_profiles, table_name)
  if (!length(code_cols)) return(empty_mm_treatment_code_counts())
  id_col <- guess_id_column_from_names(column_profiles$column_name)
  has_id <- !is.na(id_col) && nzchar(id_col)
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  rows <- list()
  cat(sprintf("      panel query: MM treatment codes for %s\n", table_name))
  flush.console()
  for (code_col in code_cols) {
    for (i in seq_len(nrow(treatment_families))) {
      rule <- treatment_families[i, , drop = FALSE]
      condition <- dbi_rule_condition(conn, code_col, rule)
      select_patients <- if (has_id) {
        paste0(", count(distinct ", DBI::dbQuoteIdentifier(conn, id_col), ") as n_patients")
      } else {
        ", cast(null as integer) as n_patients"
      }
      sql <- paste0("select count(*) as n_rows", select_patients, " from ", table_ref, " where ", condition)
      out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(n_rows = 0L, n_patients = NA_integer_))
      n_rows <- suppressWarnings(as.integer(out$n_rows[[1]] %||% 0L))
      if (is.na(n_rows) || n_rows < min_cell_count) next
      n_patients <- suppressWarnings(as.integer(out$n_patients[[1]] %||% NA_integer_))
      if (!is.na(n_patients) && n_patients < min_cell_count) n_patients <- NA_integer_
      rows[[length(rows) + 1L]] <- data.frame(
        table_name = table_name,
        code_column = code_col,
        code_system = rule$code_system[[1]],
        family = rule$family[[1]],
        match_type = rule$match_type[[1]],
        code = rule$code[[1]],
        label = rule$label[[1]],
        n_rows = n_rows,
        pct_rows = safe_pct(n_rows, source_row$n_rows[[1]]),
        n_patients = n_patients,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_mm_treatment_code_counts())
  out[order(-out$n_rows, out$table_name, out$family, out$code), , drop = FALSE]
}

dbi_mm_treatment_source_summary <- function(conn, table_ref, column_profiles, source_row, treatment_families,
                                            min_cell_count = atlas_min_cell_count()) {
  if (is.null(treatment_families) || !nrow(treatment_families)) return(empty_mm_treatment_source_summary())
  table_name <- source_row$table_name[[1]]
  code_cols <- dbi_treatment_code_columns(column_profiles, table_name)
  if (!length(code_cols)) return(empty_mm_treatment_source_summary())
  conditions <- unlist(lapply(code_cols, function(code_col) {
    vapply(seq_len(nrow(treatment_families)), function(i) {
      dbi_rule_condition(conn, code_col, treatment_families[i, , drop = FALSE])
    }, character(1))
  }), use.names = FALSE)
  conditions <- unique(conditions[nzchar(conditions)])
  if (!length(conditions)) return(empty_mm_treatment_source_summary())
  where <- paste0("(", paste(conditions, collapse = ") or ("), ")")
  id_col <- guess_id_column_from_names(column_profiles$column_name)
  has_id <- !is.na(id_col) && nzchar(id_col)
  date_col <- guess_date_column_from_profiles(column_profiles)
  has_date <- !is.na(date_col) && nzchar(date_col)
  patient_sql <- if (has_id) {
    paste0(", count(distinct ", DBI::dbQuoteIdentifier(conn, id_col), ") as matched_patients")
  } else {
    ", cast(null as integer) as matched_patients"
  }
  date_sql <- if (has_date) {
    paste0(
      ", min(", DBI::dbQuoteIdentifier(conn, date_col), "::date) as min_date",
      ", max(", DBI::dbQuoteIdentifier(conn, date_col), "::date) as max_date"
    )
  } else {
    ", cast(null as date) as min_date, cast(null as date) as max_date"
  }
  sql <- paste0("select count(*) as matched_rows", patient_sql, date_sql, " from ", table_ref, " where ", where)
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(matched_rows = 0L, matched_patients = NA_integer_, min_date = NA_character_, max_date = NA_character_))
  matched_rows <- suppressWarnings(as.integer(out$matched_rows[[1]] %||% 0L))
  if (is.na(matched_rows) || matched_rows < normalize_min_cell_count(min_cell_count)) return(empty_mm_treatment_source_summary())
  matched_patients <- suppressWarnings(as.integer(out$matched_patients[[1]] %||% NA_integer_))
  if (!is.na(matched_patients) && matched_patients < normalize_min_cell_count(min_cell_count)) matched_patients <- NA_integer_
  data.frame(
    table_name = table_name,
    n_rows_scanned = source_row$n_rows[[1]],
    matched_rows = matched_rows,
    pct_rows_matched = safe_pct(matched_rows, source_row$n_rows[[1]]),
    matched_patients = matched_patients,
    min_date = as.character(out$min_date[[1]] %||% NA_character_),
    max_date = as.character(out$max_date[[1]] %||% NA_character_),
    stringsAsFactors = FALSE
  )
}

dbi_registry_column <- function(column_profiles, candidates) {
  columns <- as.character(column_profiles$column_name %||% character())
  if (!length(columns)) return(NA_character_)
  columns_lc <- tolower(columns)
  for (candidate in candidates) {
    exact <- which(columns_lc == tolower(candidate))
    exact <- exact[!vapply(columns[exact], is_sensitive_column, logical(1))]
    if (length(exact)) return(columns[[exact[[1]]]])
  }
  for (candidate in candidates) {
    partial <- which(grepl(tolower(candidate), columns_lc, fixed = TRUE))
    partial <- partial[!vapply(columns[partial], is_sensitive_column, logical(1))]
    if (length(partial)) return(columns[[partial[[1]]]])
  }
  NA_character_
}

dbi_registry_categorical_specs <- function(registry) {
  switch(
    registry,
    "DaMyDa" = list(
      registry_spec("stage", c("Reg_ISS_Stadie", "Stadie", "iss_stage", "ISS", "stage", "stadie"), 10L),
      registry_spec("bone_disease", c("Reg_Knogleforandringer", "bone_disease", "knogle_present"), 5L),
      registry_spec("amyloidosis", c("Reg_Amyloidose", "amyloidosis", "amyloidose"), 5L),
      registry_spec("treatment_flag", c("Reg_Behandlet", "treatment_required", "treated", "behandlet"), 5L),
      registry_spec("relapse_flag", c("Reg_Relaps", "relapse", "relaps"), 5L),
      registry_spec("primary_response", c("Reg_Respons1", "primary_response"), 12L),
      registry_spec("primary_treatment", c("Reg_PrimaerBehandling", "primary_tx", "primary_treatment", "regime"), 14L),
      registry_spec("cytogenetics_fish_done", c("Reg_FISH_Udfoert", "Cyto_FishUdfoert", "fish_done"), 5L),
      registry_spec("performance_status", c("Reg_PerformanceStatus", "performance_status", "ecog"), 6L),
      registry_spec("m_component_type", c("Reg_MKomponentType", "Reg_Mkomponent", "mcomp_type", "let_kaede"), 12L),
      registry_spec("imaging", c("Reg_Billeddiagnostik", "imaging"), 8L),
      registry_spec("prior_mgus", c("Reg_TidligereMGUS", "prior_mgus"), 4L),
      registry_spec("charlson", c("Reg_CharlsonGruppe", "Charlson", "CCI"), 7L),
      registry_spec("region", c("Reg_Region", "region", "Region"), 8L),
      registry_spec("organisation_shak", c("Reg_OrganisationKode_Shak", "organisation_shak", "shak"), 12L)
    ),
    "LYFO" = list(
      registry_spec("subtype", c("Reg_Subtype", "subtype", "WHO", "lymfomtype"), 18L),
      registry_spec("ann_arbor_stage", c("Reg_Stadium", "Reg_AnnArbor", "ann_arbor", "stage", "stadie"), 6L),
      registry_spec("ipi", c("Reg_IPI", "ipi", "aaipi"), 7L),
      registry_spec("b_symptoms", c("Reg_BSymptomer", "b_symptoms"), 4L),
      registry_spec("performance_status", c("Reg_PerformanceStatusWHO", "Reg_PS", "performance", "ecog"), 6L),
      registry_spec("treatment_flag", c("Reg_Behandlet", "treatment_flag", "treated"), 4L),
      registry_spec("bulk_disease", c("Reg_BulkSygdom", "Reg_Bulk", "bulk", "bulk_disease"), 4L)
    ),
    "CLL" = list(
      registry_spec("binet", c("Reg_BinetStadium", "Reg_Binet", "binet", "stage"), 4L),
      registry_spec("ighv", c("Reg_Umuteret", "Reg_IGHV", "ighv"), 5L),
      registry_spec("fish_overall", c("Reg_FISH", "fish"), 4L),
      registry_spec("del13q", c("Reg_Del13q14", "Reg_Del13q", "del13q"), 4L),
      registry_spec("del11q", c("Reg_Del11q", "del11q"), 4L),
      registry_spec("del17p", c("Reg_Del17p", "del17p", "17p"), 4L),
      registry_spec("trisomy12", c("Reg_Trisomi12", "Reg_Tri12", "trisomy12", "tri12"), 4L),
      registry_spec("tp53", c("Reg_TP53", "tp53"), 4L),
      registry_spec("treatment_flag", c("Reg_Behandlet", "treatment_flag", "treated"), 4L),
      registry_spec("performance_status", c("Reg_Performancestatus", "Reg_PS", "performance", "ecog"), 6L),
      registry_spec("zap70", c("Reg_ZAP70", "zap70"), 4L),
      registry_spec("cd38", c("Reg_CD38Positiv", "Reg_CD38", "cd38"), 4L),
      registry_spec("beta2m", c("Reg_Beta2Microglobulin", "Reg_Beta2M", "beta2m", "beta2"), 4L)
    ),
    list()
  )
}

dbi_damyda_numeric_specs <- function() {
  list(
    registry_numeric_spec("haemoglobin", c("HB", "Reg_Haemoglobin", "haemoglobin", "hemoglobin"), "mmol/L"),
    registry_numeric_spec("creatinine", c("CREA", "Reg_Creatinin_mikmoll", "Reg_Creatinin", "creatinine"), "umol/L"),
    registry_numeric_spec("ldh", c("LDH", "Reg_LDH", "ldh"), "U/L"),
    registry_numeric_spec("crp", c("Reg_CReaktivtProtein_gl", "Reg_CRP", "crp"), "mg/L"),
    registry_numeric_spec("igg", c("Reg_IgG_gl", "igg"), "g/L"),
    registry_numeric_spec("iga", c("Reg_IgA_gl", "iga"), "g/L"),
    registry_numeric_spec("igm", c("Reg_IgM_gl", "igm"), "g/L"),
    registry_numeric_spec("albumin", c("ALB", "Reg_Albumin_gl", "albumin"), "g/L"),
    registry_numeric_spec("m_component", c("mspike_p_diagnosis", "Reg_PlasmaMKomponent", "m_component", "mkomponent"), "g/L"),
    registry_numeric_spec("ionized_calcium", c("Reg_CalciumIoniseret", "ionized_calcium", "calcium"), "mmol/L"),
    registry_numeric_spec("free_kappa_chains", c("FLC_kappa", "Reg_FrieKappaKaeder", "kappa"), "mg/L"),
    registry_numeric_spec("free_lambda_chains", c("FLC_lambda", "Reg_FrieLambdaKaeder", "lambda"), "mg/L"),
    registry_numeric_spec("beta2_microglobulin", c("B2M", "Reg_Beta2Microglobulin_gl", "beta2", "beta_2"), "mg/L"),
    registry_numeric_spec("clonal_plasma_cells", c("plasmacell_percentage_BM", "Reg_ProcentKlonalePlasmaceller", "plasma_cells"), "%"),
    registry_numeric_spec("albumin_corrected_calcium", c("Reg_CalciumAlbuminkorrigeret", "corrected_calcium"), "mmol/L")
  )
}

dbi_registry_top_labels <- function(conn, table_ref, column_name, table_name, registry, facet, row_count,
                                    top_n = 12L, min_cell_count = atlas_min_cell_count()) {
  if (is.na(column_name) || !nzchar(column_name)) return(empty_registry_categorical())
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  sql <- paste0(
    "select left(", qcol, "::text, 120) as label, count(*) as n ",
    "from ", table_ref,
    " where ", qcol, " is not null and btrim(", qcol, "::text) <> '' ",
    "group by left(", qcol, "::text, 120) ",
    "having count(*) >= ", as.integer(normalize_min_cell_count(min_cell_count)),
    " order by n desc, label limit ", as.integer(top_n)
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(label = character(), n = integer()))
  if (!nrow(out)) return(empty_registry_categorical())
  labels <- truncate_value(as.character(out$label))
  keep <- !looks_cpr_like(labels)
  out <- out[keep, , drop = FALSE]
  labels <- labels[keep]
  if (!nrow(out)) return(empty_registry_categorical())
  data.frame(
    table_name = table_name,
    registry = registry,
    facet = facet,
    source_column = column_name,
    label = labels,
    n = suppressWarnings(as.integer(out$n)),
    pct_rows = vapply(suppressWarnings(as.integer(out$n)), safe_pct, numeric(1), denom = row_count),
    stringsAsFactors = FALSE
  )
}

dbi_registry_categorical_panel <- function(conn, table_ref, column_profiles, source_row, registry,
                                           min_cell_count = atlas_min_cell_count()) {
  specs <- dbi_registry_categorical_specs(registry)
  if (!length(specs)) return(empty_registry_categorical())
  rows <- lapply(specs, function(spec) {
    column_name <- dbi_registry_column(column_profiles, spec$candidates)
    dbi_registry_top_labels(
      conn = conn,
      table_ref = table_ref,
      column_name = column_name,
      table_name = source_row$table_name[[1]],
      registry = registry,
      facet = spec$facet,
      row_count = source_row$n_rows[[1]],
      top_n = spec$top_n %||% 12L,
      min_cell_count = min_cell_count
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_registry_categorical())
  out
}

dbi_registry_numeric_field <- function(conn, table_ref, column_profiles, source_row, registry, spec) {
  column_name <- dbi_registry_column(column_profiles, spec$candidates)
  if (is.na(column_name) || !nzchar(column_name)) return(empty_registry_numeric())
  profile <- column_profiles[column_profiles$column_name == column_name, , drop = FALSE]
  if (!nrow(profile) || !isTRUE(as.logical(profile$is_numeric_like[[1]]))) return(empty_registry_numeric())
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  sql <- paste0(
    "select count(", qcol, ") as n_available, avg(", qcol, "::double precision) as mean, ",
    "percentile_cont(0.5) within group (order by ", qcol, "::double precision) as median, ",
    "percentile_cont(0.25) within group (order by ", qcol, "::double precision) as p25, ",
    "percentile_cont(0.75) within group (order by ", qcol, "::double precision) as p75 ",
    "from ", table_ref, " where ", qcol, " is not null"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(n_available = 0L))
  n_available <- suppressWarnings(as.integer(out$n_available[[1]] %||% 0L))
  if (is.na(n_available) || n_available <= 0L) return(empty_registry_numeric())
  data.frame(
    table_name = source_row$table_name[[1]],
    registry = registry,
    field = spec$field,
    source_column = column_name,
    unit = spec$unit %||% NA_character_,
    n_available = n_available,
    pct_available = safe_pct(n_available, source_row$n_rows[[1]]),
    mean = suppressWarnings(as.numeric(out$mean[[1]] %||% NA_real_)),
    median = suppressWarnings(as.numeric(out$median[[1]] %||% NA_real_)),
    p25 = suppressWarnings(as.numeric(out$p25[[1]] %||% NA_real_)),
    p75 = suppressWarnings(as.numeric(out$p75[[1]] %||% NA_real_)),
    stringsAsFactors = FALSE
  )
}

dbi_damyda_numeric_panel <- function(conn, table_ref, column_profiles, source_row) {
  rows <- lapply(dbi_damyda_numeric_specs(), function(spec) {
    dbi_registry_numeric_field(conn, table_ref, column_profiles, source_row, "DaMyDa", spec)
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_registry_numeric())
  out
}

stream_counts_for_column <- function(stream_profile_bundle, column_name) {
  if (is.null(stream_profile_bundle) || is.na(column_name) || !nzchar(column_name)) return(integer())
  counts <- stream_profile_bundle$categorical_counts %||% list()
  if (!column_name %in% names(counts)) return(integer())
  counts[[column_name]]
}

stream_year_counts_for_column <- function(stream_profile_bundle, column_name) {
  if (is.null(stream_profile_bundle) || is.na(column_name) || !nzchar(column_name)) return(integer())
  counts <- stream_profile_bundle$date_year_counts %||% list()
  if (!column_name %in% names(counts)) return(integer())
  counts[[column_name]]
}

dbi_temporal_coverage_years_from_stream <- function(column_profiles, source_row, stream_profile_bundle,
                                                    min_cell_count = atlas_min_cell_count()) {
  date_column <- coverage_date_column_from_profiles(column_profiles)
  counts <- stream_year_counts_for_column(stream_profile_bundle, date_column)
  if (!length(counts)) return(empty_temporal_coverage_years())
  years <- suppressWarnings(as.integer(names(counts)))
  n_rows <- suppressWarnings(as.integer(counts))
  keep <- !is.na(years) &
    years >= coverage_display_year_min() &
    years <= coverage_display_year_max() &
    n_rows >= normalize_min_cell_count(min_cell_count)
  if (!any(keep)) return(empty_temporal_coverage_years())
  data.frame(
    table_name = source_row$table_name[[1]],
    domain = "",
    subdomain = "",
    atlas_role = "",
    date_column = date_column,
    year = years[keep],
    n_rows = n_rows[keep],
    pct_rows = vapply(n_rows[keep], safe_pct, numeric(1), denom = source_row$n_rows[[1]]),
    coverage_basis = "streamed_event_date_counts",
    stringsAsFactors = FALSE
  )
}

dbi_spatial_region_counts_from_stream <- function(column_profiles, source_row, stream_profile_bundle,
                                                  min_cell_count = atlas_min_cell_count()) {
  region_col <- region_column_from_profiles(column_profiles)
  counts <- stream_counts_for_column(stream_profile_bundle, region_col)
  if (!length(counts)) return(empty_spatial_region_counts())
  code <- normalize_dk_region(names(counts))
  out <- data.frame(
    table_name = source_row$table_name[[1]],
    domain = "",
    subdomain = "",
    atlas_role = "",
    region_column = region_col,
    region_code = code,
    n_rows = suppressWarnings(as.integer(counts)),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$region_code) & nzchar(out$region_code), , drop = FALSE]
  out <- out[out$n_rows >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(out)) return(empty_spatial_region_counts())
  out <- aggregate(n_rows ~ table_name + domain + subdomain + atlas_role + region_column + region_code, data = out, FUN = sum)
  ref <- dk_region_reference()
  out <- merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE)
  out$pct_rows <- vapply(out$n_rows, safe_pct, numeric(1), denom = source_row$n_rows[[1]])
  out$count_basis <- "streamed_region_column_counts"
  out[, c("table_name", "domain", "subdomain", "atlas_role", "region_column", "region_code", "region_name", "n_rows", "pct_rows", "count_basis"), drop = FALSE]
}

dbi_registry_categorical_panel_from_top_values <- function(column_profiles, source_row, registry, top_values) {
  specs <- dbi_registry_categorical_specs(registry)
  if (!length(specs) || !is.data.frame(top_values) || !nrow(top_values)) return(empty_registry_categorical())
  rows <- lapply(specs, function(spec) {
    column_name <- dbi_registry_column(column_profiles, spec$candidates)
    if (is.na(column_name) || !nzchar(column_name)) return(empty_registry_categorical())
    values <- top_values[top_values$column_name == column_name, , drop = FALSE]
    if (!nrow(values)) return(empty_registry_categorical())
    data.frame(
      table_name = source_row$table_name[[1]],
      registry = registry,
      facet = spec$facet,
      source_column = column_name,
      label = values$value,
      n = suppressWarnings(as.integer(values$n)),
      pct_rows = values$pct_rows,
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) empty_registry_categorical() else out
}

dbi_damyda_numeric_panel_from_profiles <- function(column_profiles, source_row) {
  rows <- lapply(dbi_damyda_numeric_specs(), function(spec) {
    column_name <- dbi_registry_column(column_profiles, spec$candidates)
    if (is.na(column_name) || !nzchar(column_name)) return(empty_registry_numeric())
    profile <- column_profiles[column_profiles$column_name == column_name, , drop = FALSE]
    if (!nrow(profile) || !isTRUE(as.logical(profile$is_numeric_like[[1]]))) return(empty_registry_numeric())
    data.frame(
      table_name = source_row$table_name[[1]],
      registry = "DaMyDa",
      field = spec$field,
      source_column = column_name,
      unit = spec$unit %||% NA_character_,
      n_available = suppressWarnings(as.integer(profile$n_available[[1]] %||% 0L)),
      pct_available = suppressWarnings(as.numeric(profile$pct_available[[1]] %||% NA_real_)),
      mean = suppressWarnings(as.numeric(profile$mean[[1]] %||% NA_real_)),
      median = suppressWarnings(as.numeric(profile$median[[1]] %||% NA_real_)),
      p25 = suppressWarnings(as.numeric(profile$p25[[1]] %||% NA_real_)),
      p75 = suppressWarnings(as.numeric(profile$p75[[1]] %||% NA_real_)),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) empty_registry_numeric() else out
}

stream_npu_counts_from_bundle <- function(stream_profile_bundle, code_column, row_count,
                                          min_cell_count = 1L) {
  counts <- stream_counts_for_column(stream_profile_bundle, code_column)
  if (!length(counts)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  codes <- normalize_npu_code(names(counts))
  ok <- !is.na(codes) & nzchar(codes)
  if (!any(ok)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  tmp <- data.frame(npu_code = codes[ok], n_observed = suppressWarnings(as.integer(counts[ok])), stringsAsFactors = FALSE)
  agg <- aggregate(n_observed ~ npu_code, data = tmp, FUN = sum)
  agg <- agg[agg$n_observed >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(agg)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  agg$pct_rows <- vapply(agg$n_observed, safe_pct, numeric(1), denom = row_count)
  agg[order(-agg$n_observed, agg$npu_code), , drop = FALSE]
}

dbi_mm_treatment_code_counts_from_stream <- function(column_profiles, source_row, treatment_families,
                                                     stream_profile_bundle,
                                                     min_cell_count = atlas_min_cell_count()) {
  if (is.null(treatment_families) || !nrow(treatment_families)) return(empty_mm_treatment_code_counts())
  table_name <- source_row$table_name[[1]]
  code_cols <- dbi_treatment_code_columns(column_profiles, table_name)
  if (!length(code_cols)) return(empty_mm_treatment_code_counts())
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  rows <- list()
  for (code_col in code_cols) {
    counts <- stream_counts_for_column(stream_profile_bundle, code_col)
    if (!length(counts)) next
    values <- normalize_generic_code(names(counts))
    n_values <- suppressWarnings(as.integer(counts))
    for (i in seq_len(nrow(treatment_families))) {
      rule <- treatment_families[i, , drop = FALSE]
      code <- normalize_generic_code(rule$code[[1]])
      matched <- if (identical(rule$match_type[[1]], "prefix")) startsWith(values, code) & nzchar(values) else values == code & nzchar(values)
      n_rows <- sum(n_values[matched], na.rm = TRUE)
      if (is.na(n_rows) || n_rows < min_cell_count) next
      rows[[length(rows) + 1L]] <- data.frame(
        table_name = table_name,
        code_column = code_col,
        code_system = rule$code_system[[1]],
        family = rule$family[[1]],
        match_type = rule$match_type[[1]],
        code = rule$code[[1]],
        label = rule$label[[1]],
        n_rows = as.integer(n_rows),
        pct_rows = safe_pct(n_rows, source_row$n_rows[[1]]),
        n_patients = NA_integer_,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_mm_treatment_code_counts())
  out[order(-out$n_rows, out$table_name, out$family, out$code), , drop = FALSE]
}

dbi_mm_treatment_source_summary_from_stream <- function(code_counts, source_row,
                                                        min_cell_count = atlas_min_cell_count()) {
  if (is.null(code_counts) || !nrow(code_counts)) return(empty_mm_treatment_source_summary())
  matched_rows <- sum(suppressWarnings(as.integer(code_counts$n_rows)), na.rm = TRUE)
  if (is.na(matched_rows) || matched_rows < normalize_min_cell_count(min_cell_count)) return(empty_mm_treatment_source_summary())
  data.frame(
    table_name = source_row$table_name[[1]],
    n_rows_scanned = source_row$n_rows[[1]],
    matched_rows = as.integer(matched_rows),
    pct_rows_matched = safe_pct(matched_rows, source_row$n_rows[[1]]),
    matched_patients = NA_integer_,
    min_date = source_row$min_date[[1]],
    max_date = source_row$max_date[[1]],
    stringsAsFactors = FALSE
  )
}

dbi_panels_from_profiles <- function(column_profiles, source_row, conn = NULL, table_ref = NULL,
                                     profile_strategy = "sql_aggregate",
                                     stream_profile_bundle = NULL,
                                     budget_context = new_db_budget_context(source_row$table_name[[1]], source_row$n_rows[[1]]),
                                     npu_dictionary = NULL,
                                     npu_surfaces = NULL,
                                     isotype_vectors = NULL,
                                     treatment_families = NULL,
                                     min_cell_count = atlas_min_cell_count()) {
  panels <- list()
  streamed <- identical(profile_strategy, "stream_column")
  if (!is.null(conn) && !is.null(table_ref)) {
    if (streamed) {
      panels$atlas_temporal_coverage_years <- dbi_temporal_coverage_years_from_stream(
        column_profiles = column_profiles,
        source_row = source_row,
        stream_profile_bundle = stream_profile_bundle,
        min_cell_count = min_cell_count
      )
      panels$atlas_spatial_region_counts <- dbi_spatial_region_counts_from_stream(
        column_profiles = column_profiles,
        source_row = source_row,
        stream_profile_bundle = stream_profile_bundle,
        min_cell_count = min_cell_count
      )
    } else {
      panels$atlas_temporal_coverage_years <- dbi_temporal_coverage_years(
        conn = conn,
        table_ref = table_ref,
        column_profiles = column_profiles,
        source_row = source_row,
        min_cell_count = min_cell_count
      )
      panels$atlas_spatial_region_counts <- dbi_spatial_region_counts(
        conn = conn,
        table_ref = table_ref,
        column_profiles = column_profiles,
        source_row = source_row,
        min_cell_count = min_cell_count
      )
    }
  }
  registry <- registry_name(source_row$table_name[[1]])
  if (!is.na(registry)) {
    panels$registry_clinical_summary <- data.frame(
      table_name = source_row$table_name[[1]],
      registry = registry,
      n_rows = source_row$n_rows[[1]],
      n_cols = source_row$n_cols[[1]],
      n_patients = NA_integer_,
      min_date = source_row$min_date[[1]],
      max_date = source_row$max_date[[1]],
      stringsAsFactors = FALSE
    )
    if (!is.null(conn) && !is.null(table_ref)) {
      if (identical(registry, "DaMyDa")) {
        panels$damyda_clinical_profile <- if (streamed) {
          dbi_registry_categorical_panel_from_top_values(column_profiles, source_row, registry, stream_profile_bundle$column_top_values)
        } else {
          dbi_registry_categorical_panel(conn, table_ref, column_profiles, source_row, registry, min_cell_count = min_cell_count)
        }
        panels$damyda_numeric_fields <- if (streamed) {
          dbi_damyda_numeric_panel_from_profiles(column_profiles, source_row)
        } else {
          dbi_damyda_numeric_panel(conn, table_ref, column_profiles, source_row)
        }
      } else if (identical(registry, "LYFO")) {
        panels$lyfo_clinical_profile <- if (streamed) {
          dbi_registry_categorical_panel_from_top_values(column_profiles, source_row, registry, stream_profile_bundle$column_top_values)
        } else {
          dbi_registry_categorical_panel(conn, table_ref, column_profiles, source_row, registry, min_cell_count = min_cell_count)
        }
      } else if (identical(registry, "CLL")) {
        panels$cll_clinical_profile <- if (streamed) {
          dbi_registry_categorical_panel_from_top_values(column_profiles, source_row, registry, stream_profile_bundle$column_top_values)
        } else {
          dbi_registry_categorical_panel(conn, table_ref, column_profiles, source_row, registry, min_cell_count = min_cell_count)
        }
      }
    }
  }
  if (!is.null(conn) && !is.null(table_ref) && !is.null(npu_dictionary) && nrow(npu_dictionary)) {
    code_column <- npu_code_column_from_names(column_profiles$column_name)
    counts <- if (streamed) {
      stream_npu_counts_from_bundle(stream_profile_bundle, code_column, source_row$n_rows[[1]], min_cell_count = 1L)
    } else {
      dbi_npu_code_counts(
        conn = conn,
        table_ref = table_ref,
        column_name = code_column,
        table_name = source_row$table_name[[1]],
        row_count = source_row$n_rows[[1]],
        min_cell_count = 1L
      )
    }
    panels$lab_npu_code_coverage <- npu_lab_code_coverage_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      min_cell_count = min_cell_count
    )
    panels$npu_lab_usage_by_vector <- npu_lab_usage_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      denom = source_row$n_rows[[1]],
      dictionary = npu_dictionary,
      min_cell_count = min_cell_count
    )
    panels$npu_lab_unmatched_codes <- npu_lab_unmatched_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      denom = source_row$n_rows[[1]],
      dictionary = npu_dictionary,
      min_cell_count = min_cell_count
    )
    panels$npu_detective_code_inventory <- npu_detective_inventory_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      denom = source_row$n_rows[[1]],
      dictionary = npu_dictionary,
      surfaces = npu_surfaces,
      min_cell_count = min_cell_count
    )
    panels$npu_detective_candidates <- npu_detective_candidates_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      denom = source_row$n_rows[[1]],
      dictionary = npu_dictionary,
      surfaces = npu_surfaces,
      min_cell_count = min_cell_count
    )
    panels$npu_detective_source_year <- if (streamed) {
      if (!is.na(code_column) && nzchar(code_column) && nrow(counts)) {
        budget_context$add_action(
          column_name = code_column,
          query_category = "npu_source_year",
          reason = "large-table streaming mode avoids two-column code/date scans by default",
          current_behavior = "NPU code inventory is exact from streamed code-column counts; source-year NPU cross-tab is omitted.",
          recommended_action = "Run a targeted NPU source-year query for the specific lab source if this cross-tab is needed."
        )
      }
      empty_npu_detective_source_year()
    } else {
      dbi_npu_source_year_panel(
        conn = conn,
        table_ref = table_ref,
        code_column = code_column,
        year_column = source_row$date_column_guess[[1]],
        table_name = source_row$table_name[[1]],
        row_count = source_row$n_rows[[1]],
        dictionary = npu_dictionary,
        surfaces = npu_surfaces,
        min_cell_count = min_cell_count
      )
    }
    panels$isotype_code_usage <- isotype_code_usage_from_counts(
      counts = counts,
      table_name = source_row$table_name[[1]],
      code_column = code_column,
      denom = source_row$n_rows[[1]],
      isotype_vectors = isotype_vectors,
      min_cell_count = min_cell_count
    )
    panels$isotype_bucket_summary <- isotype_bucket_summary_from_usage(
      usage = panels$isotype_code_usage,
      table_name = source_row$table_name[[1]],
      denom = source_row$n_rows[[1]],
      min_cell_count = min_cell_count
    )
  }
  if (!is.null(conn) && !is.null(table_ref) && !is.null(treatment_families) && nrow(treatment_families)) {
    panels$mm_treatment_code_counts <- if (streamed) {
      dbi_mm_treatment_code_counts_from_stream(
        column_profiles = column_profiles,
        source_row = source_row,
        treatment_families = treatment_families,
        stream_profile_bundle = stream_profile_bundle,
        min_cell_count = min_cell_count
      )
    } else {
      dbi_mm_treatment_code_counts(
        conn = conn,
        table_ref = table_ref,
        column_profiles = column_profiles,
        source_row = source_row,
        treatment_families = treatment_families,
        min_cell_count = min_cell_count
      )
    }
    panels$mm_treatment_source_summary <- if (streamed) {
      dbi_mm_treatment_source_summary_from_stream(
        code_counts = panels$mm_treatment_code_counts,
        source_row = source_row,
        min_cell_count = min_cell_count
      )
    } else {
      dbi_mm_treatment_source_summary(
        conn = conn,
        table_ref = table_ref,
        column_profiles = column_profiles,
        source_row = source_row,
        treatment_families = treatment_families,
        min_cell_count = min_cell_count
      )
    }
  }
  panels
}
