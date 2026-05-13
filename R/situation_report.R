empty_situation_report_summary <- function() {
  empty_df(
    metric_id = character(),
    label = character(),
    n_patients = numeric(),
    n_rows = numeric(),
    window_days = integer(),
    as_of_date = character(),
    source_table = character(),
    date_column = character(),
    definition_basis = character(),
    n_cohort = numeric(),
    pct_cohort = numeric(),
    definition_status = character(),
    freshness_status = character(),
    message = character()
  )
}

empty_situation_report_breakdowns <- function() {
  empty_df(
    metric_id = character(),
    label = character(),
    breakdown_type = character(),
    breakdown_value = character(),
    n_patients = numeric(),
    n_rows = numeric(),
    pct_patients = numeric(),
    source_table = character(),
    as_of_date = character()
  )
}

empty_situation_report_freshness <- function() {
  empty_df(
    metric_id = character(),
    source_table = character(),
    date_column = character(),
    max_date = character(),
    as_of_date = character(),
    lag_days = numeric(),
    freshness_status = character(),
    message = character()
  )
}

situation_report_metric_defs <- function() {
  list(
    list(
      metric_id = "currently_admitted",
      label = "Currently admitted",
      kind = "current_admission_interval",
      source_candidates = c("SP_ADT_haendelser", "SDS_t_adm", "SDS_kontakter"),
      date_candidates = c("effective_time", "event_time", "event_datetime", "event_date", "tidspunkt", "haendelsestidspunkt", "kontakt_dato", "admission_date", "d_inddto", "d_ind", "d_odto", "date_start"),
      event_candidates = c("event_type_name", "event_type", "event_name", "haendelsestype", "haendelsesnavn", "adt_event", "type", "status", "patient_class", "admission_type"),
      start_candidates = c("kontakt_start_local_dttm", "admission_date", "date_start", "start_date", "d_inddto", "d_ind", "indlaeggelsesdato", "kontakt_start"),
      end_candidates = c("kontakt_end_local_dttm", "discharge_date", "date_end", "end_date", "d_uddto", "d_ud", "udskrivningsdato", "kontakt_slut"),
      class_candidates = c("patient_class", "admission_type"),
      admission_pattern = "indl|admission|admit|flyt ind",
      discharge_pattern = "udskr|discharge|flyt ud",
      definition_basis = "active_inpatient_contact_interval",
      max_pct_cohort = 5
    ),
    list(
      metric_id = "currently_ita",
      label = "Currently in ITA/ICU",
      kind = "current_interval",
      source_candidates = c("SP_ITAOphold"),
      start_candidates = c("icu_stay_start", "icu_stay_start_1", "respiratorstart", "respiratorstart_1"),
      end_candidates = c("icu_stay_end", "icu_stay_end_1", "respiratorend", "respiratorend_1"),
      definition_basis = "active_icu_interval"
    ),
    list(
      metric_id = "admitted_30d",
      label = "Admitted in past 30 days",
      kind = "recent_interval_start",
      source_candidates = c("SP_ADT_haendelser", "SDS_t_adm", "SDS_kontakter"),
      date_candidates = c("kontakt_start_local_dttm", "admission_date", "date_start", "start_date", "d_inddto", "d_ind", "indlaeggelsesdato", "kontakt_start", "effective_time"),
      event_candidates = c("event_type_name", "event_type", "event_name", "haendelsestype", "haendelsesnavn", "adt_event", "type", "status", "patient_class", "admission_type"),
      class_candidates = c("patient_class", "admission_type"),
      event_pattern = "indl|admission|admit|flyt ind",
      window_days = 30L,
      definition_basis = "inpatient_contact_start_30d"
    ),
    list(
      metric_id = "discharged_30d",
      label = "Discharged in past 30 days",
      kind = "recent_interval_end",
      source_candidates = c("SP_ADT_haendelser", "SDS_t_adm", "SDS_kontakter"),
      date_candidates = c("kontakt_end_local_dttm", "discharge_date", "date_end", "end_date", "d_uddto", "d_ud", "udskrivningsdato", "kontakt_slut", "effective_time"),
      event_candidates = c("event_type_name", "event_type", "event_name", "haendelsestype", "haendelsesnavn", "adt_event", "type", "status"),
      class_candidates = c("patient_class", "admission_type"),
      event_pattern = "udskr|discharge|flyt ud",
      window_days = 30L,
      definition_basis = "inpatient_contact_end_30d"
    ),
    list(
      metric_id = "died_30d",
      label = "Died in past 30 days",
      kind = "recent_date",
      source_candidates = c("SDS_t_dodsaarsag_2", "view_date_death", "view_true_date_death", "patient"),
      date_candidates = c("d_dodsdato", "date_death", "date_death_fu", "death_date"),
      status_candidates = c("status", "dead", "death_status"),
      status_positive_pattern = "^1$|dead|died|dod|doed",
      window_days = 30L,
      definition_basis = "death_date_30d"
    ),
    list(
      metric_id = "diagnosed_30d",
      label = "Diagnosed in past 30 days",
      kind = "recent_date",
      source_candidates = c("t_dalycare_diagnoses", "view_dalycare_diagnoses", "view_diagnoses_all_hosp_region", "view_diagnosses_all", "RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL"),
      date_candidates = c("date_diagnosis", "Reg_Diagnose_dt", "diagnosis_date", "Reg_DiagnostiskBiopsi_dt", "Diagnosedato", "d_diagnosedato"),
      window_days = 30L,
      definition_basis = "diagnosis_date_30d"
    )
  )
}

build_situation_report_panels <- function(source_resolution = NULL,
                                          db_adapter = NULL,
                                          sources = NULL,
                                          column_profiles = NULL,
                                          min_cell_count = atlas_min_cell_count()) {
  if (!is.null(db_adapter) && is.function(db_adapter$situation_report)) {
    out <- tryCatch(
      db_adapter$situation_report(
        source_resolution = source_resolution,
        sources = sources,
        column_profiles = column_profiles,
        min_cell_count = min_cell_count
      ),
      error = function(e) NULL
    )
    if (is.list(out)) return(normalize_situation_report_panels(out, sources = sources))
  }
  if (!is.null(db_adapter) && !is.null(db_adapter$connections) && requireNamespace("DBI", quietly = TRUE)) {
    out <- tryCatch(
      dbi_situation_report_panels(source_resolution, db_adapter, sources = sources, min_cell_count = min_cell_count),
      error = function(e) fallback_situation_report_panels(sources, column_profiles, paste("Situation report DB query failed:", conditionMessage(e)))
    )
    return(normalize_situation_report_panels(out, sources = sources))
  }
  fallback_situation_report_panels(sources, column_profiles, "DB adapter unavailable; situation report counts were not computed.")
}

normalize_situation_report_panels <- function(out, sources = NULL) {
  summary <- out$situation_report_summary %||% empty_situation_report_summary()
  if (is.data.frame(summary) && nrow(summary)) {
    summary <- normalize_situation_summary_frame(summary, n_cohort = situation_cohort_n(sources))
  }
  list(
    situation_report_summary = summary,
    situation_report_breakdowns = out$situation_report_breakdowns %||% empty_situation_report_breakdowns(),
    situation_report_freshness = out$situation_report_freshness %||% empty_situation_report_freshness()
  )
}

fallback_situation_report_panels <- function(sources = NULL, column_profiles = NULL, message = "") {
  n_cohort <- situation_cohort_n(sources)
  rows <- lapply(situation_report_metric_defs(), function(def) {
    situation_unavailable_row(def, message = message %||% "Situation report requires live DB aggregate access.", n_cohort = n_cohort)
  })
  freshness <- situation_freshness_from_profiles(column_profiles)
  list(
    situation_report_summary = bind_rows_base(rows),
    situation_report_breakdowns = empty_situation_report_breakdowns(),
    situation_report_freshness = freshness
  )
}

situation_unavailable_row <- function(def, message = "Required source or columns were unavailable.", n_cohort = NA_real_) {
  data.frame(
    metric_id = def$metric_id,
    label = def$label,
    n_patients = NA_real_,
    n_rows = NA_real_,
    window_days = suppressWarnings(as.integer(def$window_days %||% NA_integer_)),
    as_of_date = NA_character_,
    source_table = NA_character_,
    date_column = NA_character_,
    definition_basis = def$definition_basis %||% "",
    n_cohort = suppressWarnings(as.numeric(n_cohort)),
    pct_cohort = NA_real_,
    definition_status = "unavailable",
    freshness_status = "unknown",
    message = message,
    stringsAsFactors = FALSE
  )
}

normalize_situation_summary_frame <- function(summary, n_cohort = NA_real_) {
  empty <- empty_situation_report_summary()
  for (nm in names(empty)) {
    if (!nm %in% names(summary)) summary[[nm]] <- empty[[nm]][NA_integer_]
  }
  if (!"definition_basis" %in% names(summary)) summary$definition_basis <- ""
  if (!"n_cohort" %in% names(summary)) summary$n_cohort <- n_cohort
  summary$n_cohort[is.na(suppressWarnings(as.numeric(summary$n_cohort)))] <- n_cohort
  if (!"pct_cohort" %in% names(summary)) summary$pct_cohort <- NA_real_
  missing_pct <- is.na(suppressWarnings(as.numeric(summary$pct_cohort)))
  if (any(missing_pct)) {
    summary$pct_cohort[missing_pct] <- mapply(
      safe_pct,
      suppressWarnings(as.numeric(summary$n_patients[missing_pct])),
      suppressWarnings(as.numeric(summary$n_cohort[missing_pct]))
    )
  }
  summary[, names(empty_situation_report_summary()), drop = FALSE]
}

situation_cohort_n <- function(sources) {
  if (!is.data.frame(sources) || !nrow(sources) || !"table_name" %in% names(sources) || !"n_rows" %in% names(sources)) {
    return(NA_real_)
  }
  status_ok <- if ("load_status" %in% names(sources)) sources$load_status == "ok" else rep(TRUE, nrow(sources))
  exact <- which(tolower(sources$table_name) == "patient" & status_ok)
  if (length(exact)) return(suppressWarnings(as.numeric(sources$n_rows[[exact[[1]]]])))
  candidates <- which(grepl("patient", sources$table_name, ignore.case = TRUE) & status_ok)
  if (length(candidates)) return(suppressWarnings(as.numeric(sources$n_rows[[candidates[[1]]]])))
  NA_real_
}

situation_freshness_from_profiles <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(empty_situation_report_freshness())
  date_rows <- column_profiles[column_profiles$profile_kind == "date" & !is.na(column_profiles$max_date) & nzchar(as.character(column_profiles$max_date)), , drop = FALSE]
  if (!nrow(date_rows)) return(empty_situation_report_freshness())
  rows <- split(date_rows, date_rows$table_name)
  out <- lapply(rows, function(x) {
    max_dates <- safe_as_date(x$max_date)
    if (all(is.na(max_dates))) return(empty_situation_report_freshness())
    i <- which.max(max_dates)
    data.frame(
      metric_id = "source_freshness",
      source_table = x$table_name[[1]],
      date_column = x$column_name[[i]],
      max_date = as.character(max_dates[[i]]),
      as_of_date = NA_character_,
      lag_days = NA_real_,
      freshness_status = "source_metadata",
      message = "Freshness derived from column profile date ranges.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(out)
}

dbi_situation_report_panels <- function(source_resolution, db_adapter, sources = NULL, min_cell_count = atlas_min_cell_count()) {
  schema_cache <- new.env(parent = emptyenv())
  get_context <- function(def) situation_dbi_context(def, source_resolution, db_adapter, schema_cache)
  n_cohort <- situation_cohort_n(sources)
  results <- lapply(situation_report_metric_defs(), function(def) {
    ctx <- get_context(def)
    if (is.null(ctx)) {
      return(list(
        summary = situation_unavailable_row(def, n_cohort = n_cohort),
        breakdowns = empty_situation_report_breakdowns(),
        freshness = empty_situation_report_freshness()
      ))
    }
    switch(
      def$kind,
      current_interval = situation_dbi_current_interval(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      current_admission_interval = situation_dbi_current_admission_interval(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      recent_interval_start = situation_dbi_recent_interval_date(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      recent_interval_end = situation_dbi_recent_interval_date(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      current_event = situation_dbi_current_event_or_interval(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      recent_event = situation_dbi_recent_event_or_date(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      recent_date = situation_dbi_recent_date(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count),
      list(summary = situation_unavailable_row(def, n_cohort = n_cohort), breakdowns = empty_situation_report_breakdowns(), freshness = empty_situation_report_freshness())
    )
  })
  summary <- bind_rows_base(lapply(results, `[[`, "summary"))
  breakdowns <- bind_rows_base(lapply(results, `[[`, "breakdowns"))
  freshness <- bind_rows_base(lapply(results, `[[`, "freshness"))
  apply_situation_freshness(summary, breakdowns, freshness)
}

situation_dbi_context <- function(def, source_resolution, db_adapter, schema_cache) {
  if (!is.data.frame(source_resolution) || !nrow(source_resolution)) return(NULL)
  candidates <- def$source_candidates %||% character()
  rows <- source_resolution[source_resolution$table_name %in% candidates & source_resolution$resolution_status == "resolved", , drop = FALSE]
  if (!nrow(rows)) return(NULL)
  rows$rank <- match(rows$table_name, candidates)
  rows <- rows[order(rows$rank), , drop = FALSE]
  for (i in seq_len(nrow(rows))) {
    row <- rows[i, , drop = FALSE]
    schema <- situation_schema_for_row(row, db_adapter, schema_cache)
    if (!is.data.frame(schema) || !nrow(schema)) next
    conn <- dbi_connection_for(db_adapter$connections, row$db_name[[1]])
    return(list(
      row = row,
      conn = conn,
      table_ref = dbi_table_ref(conn, row$schema[[1]], row$table[[1]]),
      schema = schema,
      columns = as.character(schema$column_name)
    ))
  }
  NULL
}

situation_schema_for_row <- function(row, db_adapter, schema_cache) {
  key <- paste(row$db_name[[1]], row$schema[[1]], row$table[[1]], sep = "\r")
  if (exists(key, envir = schema_cache, inherits = FALSE)) return(get(key, envir = schema_cache, inherits = FALSE))
  schema <- tryCatch(
    dbi_table_schema(db_adapter$connections, row$db_name[[1]], row$schema[[1]], row$table[[1]]),
    error = function(e) data.frame()
  )
  assign(key, schema, envir = schema_cache)
  schema
}

situation_find_column <- function(columns, candidates, allow_partial = TRUE) {
  columns <- as.character(columns %||% character())
  if (!length(columns)) return(NA_character_)
  lower <- tolower(columns)
  for (candidate in candidates %||% character()) {
    hit <- which(lower == tolower(candidate))
    hit <- hit[!vapply(columns[hit], is_sensitive_column, logical(1))]
    if (length(hit)) return(columns[[hit[[1]]]])
  }
  if (isTRUE(allow_partial)) {
    for (candidate in candidates %||% character()) {
      hit <- which(grepl(tolower(candidate), lower, fixed = TRUE))
      hit <- hit[!vapply(columns[hit], is_sensitive_column, logical(1))]
      if (length(hit)) return(columns[[hit[[1]]]])
    }
  }
  NA_character_
}

situation_patient_column <- function(columns) {
  hit <- columns[vapply(columns, is_sensitive_column, logical(1))]
  if (!length(hit)) return(NA_character_)
  hit[[1]]
}

situation_column_info <- function(schema, column_name) {
  row <- schema[tolower(schema$column_name) == tolower(column_name), , drop = FALSE]
  row[1, , drop = FALSE]
}

situation_date_expression <- function(conn, schema, column_name) {
  qcol <- DBI::dbQuoteIdentifier(conn, column_name)
  info <- situation_column_info(schema, column_name)
  column_type <- info$data_type[[1]] %||% ""
  column_class <- info$udt_name[[1]] %||% column_type
  if (sql_type_is_text(column_type, column_class)) {
    return(paste0("(", dbi_text_date_string_expression(qcol), ")::date"))
  }
  paste0(qcol, "::date")
}

situation_as_of_query <- function(conn, table_ref, date_expr) {
  lower <- DBI::dbQuoteString(conn, paste0(coverage_display_year_min(), "-01-01"))
  upper <- DBI::dbQuoteString(conn, as.character(Sys.Date() + 366L))
  sql <- paste0(
    "select max(date_value) as as_of_date from (select ", date_expr, " as date_value from ", table_ref, ") atlas_dates ",
    "where date_value is not null and date_value between ", lower, "::date and ", upper, "::date"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(as_of_date = NA_character_))
  as.Date(out$as_of_date[[1]] %||% NA_character_)
}

situation_count_result <- function(conn, sql) {
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) data.frame(n_rows = NA_real_, n_patients = NA_real_))
  list(
    n_rows = suppressWarnings(as.numeric(out$n_rows[[1]] %||% NA_real_)),
    n_patients = suppressWarnings(as.numeric(out$n_patients[[1]] %||% NA_real_))
  )
}

situation_metric_row <- function(def, counts, as_of_date, source_table, date_column,
                                 min_cell_count = atlas_min_cell_count(),
                                 definition_status = "ok", message = "",
                                 definition_basis = def$definition_basis %||% "",
                                 n_cohort = NA_real_) {
  suppressed <- !is.na(counts$n_patients) && counts$n_patients < normalize_min_cell_count(min_cell_count)
  public_patients <- if (isTRUE(suppressed)) NA_real_ else counts$n_patients
  public_rows <- if (isTRUE(suppressed)) NA_real_ else counts$n_rows
  pct_cohort <- safe_pct(public_patients, n_cohort)
  max_pct <- suppressWarnings(as.numeric(def$max_pct_cohort %||% NA_real_))
  needs_review <- !isTRUE(suppressed) && !is.na(max_pct) && !is.na(pct_cohort) && pct_cohort > max_pct
  status <- if (isTRUE(suppressed)) "suppressed" else if (isTRUE(needs_review)) "needs_review" else definition_status
  if (isTRUE(needs_review)) {
    msg <- paste0(
      "Needs review: ", def$label, " is ", round(pct_cohort, 1),
      "% of the available cohort, above the ", max_pct, "% plausibility guardrail."
    )
    message <- paste(c(message, msg)[nzchar(c(message, msg))], collapse = " ")
  }
  data.frame(
    metric_id = def$metric_id,
    label = def$label,
    n_patients = public_patients,
    n_rows = public_rows,
    window_days = suppressWarnings(as.integer(def$window_days %||% NA_integer_)),
    as_of_date = as.character(as_of_date),
    source_table = source_table,
    date_column = date_column,
    definition_basis = definition_basis,
    n_cohort = suppressWarnings(as.numeric(n_cohort)),
    pct_cohort = pct_cohort,
    definition_status = status,
    freshness_status = "pending",
    message = if (isTRUE(suppressed)) paste("Suppressed because n_patients is below", normalize_min_cell_count(min_cell_count)) else message,
    stringsAsFactors = FALSE
  )
}

situation_freshness_row <- function(def, source_table, date_column, as_of_date) {
  data.frame(
    metric_id = def$metric_id,
    source_table = source_table,
    date_column = date_column,
    max_date = as.character(as_of_date),
    as_of_date = NA_character_,
    lag_days = NA_real_,
    freshness_status = "pending",
    message = "Metric-specific data-as-of date.",
    stringsAsFactors = FALSE
  )
}

situation_dbi_recent_date <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  patient_col <- situation_patient_column(ctx$columns)
  date_col <- situation_find_column(ctx$columns, def$date_candidates)
  if (is.na(patient_col) || is.na(date_col)) return(situation_metric_unavailable_result(def, ctx, "Required patient/date columns were not found."))
  date_expr <- situation_date_expression(ctx$conn, ctx$schema, date_col)
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, date_expr)
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available."))
  start <- as_of - as.integer(def$window_days %||% 30L)
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  condition <- paste0(
    date_expr, " between ", DBI::dbQuoteString(ctx$conn, as.character(start)), "::date and ",
    DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date"
  )
  status_col <- situation_find_column(ctx$columns, def$status_candidates %||% character())
  if (!is.na(status_col) && nzchar(def$status_positive_pattern %||% "")) {
    qstatus <- DBI::dbQuoteIdentifier(ctx$conn, status_col)
    condition <- paste0(condition, " and coalesce(", qstatus, "::text, '') ~* ", DBI::dbQuoteString(ctx$conn, def$status_positive_pattern))
  }
  sql <- paste0("select count(*) as n_rows, count(distinct ", qpatient, ") as n_patients from ", ctx$table_ref, " where ", condition)
  counts <- situation_count_result(ctx$conn, sql)
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], date_col, min_cell_count = min_cell_count, n_cohort = n_cohort)
  breakdowns <- situation_breakdowns_for_condition(def, ctx, condition, summary, patient_col, min_cell_count = min_cell_count)
  list(summary = summary, breakdowns = breakdowns, freshness = situation_freshness_row(def, ctx$row$table_name[[1]], date_col, as_of))
}

situation_dbi_recent_event_or_date <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  event_col <- situation_find_column(ctx$columns, def$event_candidates %||% character())
  if (is.na(event_col)) {
    def$date_candidates <- def$fallback_date_candidates %||% def$date_candidates
    return(situation_dbi_recent_date(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count))
  }
  patient_col <- situation_patient_column(ctx$columns)
  date_col <- situation_find_column(ctx$columns, def$date_candidates)
  if (is.na(patient_col) || is.na(date_col)) return(situation_metric_unavailable_result(def, ctx, "Required patient/date columns were not found."))
  date_expr <- situation_date_expression(ctx$conn, ctx$schema, date_col)
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, date_expr)
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available."))
  start <- as_of - as.integer(def$window_days %||% 30L)
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  qevent <- DBI::dbQuoteIdentifier(ctx$conn, event_col)
  condition <- paste0(
    date_expr, " between ", DBI::dbQuoteString(ctx$conn, as.character(start)), "::date and ",
    DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date",
    " and coalesce(", qevent, "::text, '') ~* ", DBI::dbQuoteString(ctx$conn, def$event_pattern)
  )
  sql <- paste0("select count(*) as n_rows, count(distinct ", qpatient, ") as n_patients from ", ctx$table_ref, " where ", condition)
  counts <- situation_count_result(ctx$conn, sql)
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], date_col, min_cell_count = min_cell_count, n_cohort = n_cohort)
  breakdowns <- situation_breakdowns_for_condition(def, ctx, condition, summary, patient_col, min_cell_count = min_cell_count)
  list(summary = summary, breakdowns = breakdowns, freshness = situation_freshness_row(def, ctx$row$table_name[[1]], date_col, as_of))
}

situation_inpatient_condition <- function(conn, columns, class_candidates = character()) {
  class_col <- situation_find_column(columns, class_candidates %||% character())
  if (is.na(class_col)) {
    return(list(condition = "", column = NA_character_, basis = "no_patient_class_filter"))
  }
  qclass <- DBI::dbQuoteIdentifier(conn, class_col)
  inpatient <- DBI::dbQuoteString(conn, "indlagt|inpatient")
  outpatient <- DBI::dbQuoteString(conn, "ambulant|outpatient")
  list(
    condition = paste0(" and coalesce(", qclass, "::text, '') ~* ", inpatient, " and coalesce(", qclass, "::text, '') !~* ", outpatient),
    column = class_col,
    basis = paste0("inpatient_filter:", class_col)
  )
}

situation_dbi_current_admission_interval <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  patient_col <- situation_patient_column(ctx$columns)
  start_col <- situation_find_column(ctx$columns, def$start_candidates)
  end_col <- situation_find_column(ctx$columns, def$end_candidates)
  if (is.na(patient_col) || is.na(start_col) || is.na(end_col)) {
    return(situation_metric_unavailable_result(def, ctx, "Required paired patient/admission start/end columns were not found.", n_cohort = n_cohort))
  }
  start_expr <- situation_date_expression(ctx$conn, ctx$schema, start_col)
  end_expr <- situation_date_expression(ctx$conn, ctx$schema, end_col)
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, paste0("greatest(coalesce(", start_expr, ", '1900-01-01'::date), coalesce(", end_expr, ", '1900-01-01'::date))"))
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available.", n_cohort = n_cohort))
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  as_of_sql <- paste0(DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date")
  inpatient <- situation_inpatient_condition(ctx$conn, ctx$columns, def$class_candidates)
  condition <- paste0(
    start_expr, " <= ", as_of_sql,
    " and (", end_expr, " is null or ", end_expr, " > ", as_of_sql, ")",
    inpatient$condition
  )
  sql <- paste0("select count(*) as n_rows, count(distinct ", qpatient, ") as n_patients from ", ctx$table_ref, " where ", condition)
  counts <- situation_count_result(ctx$conn, sql)
  basis <- paste(c(def$definition_basis %||% "active_inpatient_contact_interval", paste0("start:", start_col), paste0("end:", end_col), inpatient$basis), collapse = "; ")
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], start_col, min_cell_count = min_cell_count, definition_basis = basis, n_cohort = n_cohort)
  breakdowns <- situation_breakdowns_for_condition(def, ctx, condition, summary, patient_col, min_cell_count = min_cell_count)
  list(summary = summary, breakdowns = breakdowns, freshness = situation_freshness_row(def, ctx$row$table_name[[1]], start_col, as_of))
}

situation_dbi_recent_interval_date <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  patient_col <- situation_patient_column(ctx$columns)
  date_col <- situation_find_column(ctx$columns, def$date_candidates)
  if (is.na(patient_col) || is.na(date_col)) {
    return(situation_metric_unavailable_result(def, ctx, "Required patient/date columns were not found.", n_cohort = n_cohort))
  }
  date_expr <- situation_date_expression(ctx$conn, ctx$schema, date_col)
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, date_expr)
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available.", n_cohort = n_cohort))
  start <- as_of - as.integer(def$window_days %||% 30L)
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  inpatient <- situation_inpatient_condition(ctx$conn, ctx$columns, def$class_candidates)
  condition <- paste0(
    date_expr, " between ", DBI::dbQuoteString(ctx$conn, as.character(start)), "::date and ",
    DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date",
    inpatient$condition
  )
  sql <- paste0("select count(*) as n_rows, count(distinct ", qpatient, ") as n_patients from ", ctx$table_ref, " where ", condition)
  counts <- situation_count_result(ctx$conn, sql)
  basis <- paste(c(def$definition_basis %||% "recent_inpatient_contact_date", paste0("date:", date_col), inpatient$basis), collapse = "; ")
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], date_col, min_cell_count = min_cell_count, definition_basis = basis, n_cohort = n_cohort)
  breakdowns <- situation_breakdowns_for_condition(def, ctx, condition, summary, patient_col, min_cell_count = min_cell_count)
  list(summary = summary, breakdowns = breakdowns, freshness = situation_freshness_row(def, ctx$row$table_name[[1]], date_col, as_of))
}

situation_dbi_current_interval <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  patient_col <- situation_patient_column(ctx$columns)
  start_col <- situation_find_column(ctx$columns, def$start_candidates)
  end_col <- situation_find_column(ctx$columns, def$end_candidates)
  if (is.na(patient_col) || is.na(start_col)) return(situation_metric_unavailable_result(def, ctx, "Required patient/start-date columns were not found."))
  start_expr <- situation_date_expression(ctx$conn, ctx$schema, start_col)
  end_expr <- if (!is.na(end_col)) situation_date_expression(ctx$conn, ctx$schema, end_col) else "null::date"
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, paste0("greatest(coalesce(", start_expr, ", '1900-01-01'::date), coalesce(", end_expr, ", '1900-01-01'::date))"))
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available."))
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  as_of_sql <- paste0(DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date")
  condition <- paste0(start_expr, " <= ", as_of_sql, " and (", end_expr, " is null or ", end_expr, " >= ", as_of_sql, ")")
  sql <- paste0("select count(*) as n_rows, count(distinct ", qpatient, ") as n_patients from ", ctx$table_ref, " where ", condition)
  counts <- situation_count_result(ctx$conn, sql)
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], start_col, min_cell_count = min_cell_count, n_cohort = n_cohort)
  breakdowns <- situation_breakdowns_for_condition(def, ctx, condition, summary, patient_col, min_cell_count = min_cell_count)
  list(summary = summary, breakdowns = breakdowns, freshness = situation_freshness_row(def, ctx$row$table_name[[1]], start_col, as_of))
}

situation_dbi_current_event_or_interval <- function(def, ctx, n_cohort = NA_real_, min_cell_count = atlas_min_cell_count()) {
  event_col <- situation_find_column(ctx$columns, def$event_candidates %||% character())
  date_col <- situation_find_column(ctx$columns, def$date_candidates %||% character())
  patient_col <- situation_patient_column(ctx$columns)
  if (is.na(event_col) || is.na(date_col) || is.na(patient_col)) {
    return(situation_dbi_current_interval(def, ctx, n_cohort = n_cohort, min_cell_count = min_cell_count))
  }
  date_expr <- situation_date_expression(ctx$conn, ctx$schema, date_col)
  as_of <- situation_as_of_query(ctx$conn, ctx$table_ref, date_expr)
  if (is.na(as_of)) return(situation_metric_unavailable_result(def, ctx, "No valid as-of date was available."))
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  qevent <- DBI::dbQuoteIdentifier(ctx$conn, event_col)
  as_of_sql <- paste0(DBI::dbQuoteString(ctx$conn, as.character(as_of)), "::date")
  admission <- DBI::dbQuoteString(ctx$conn, def$admission_pattern)
  discharge <- DBI::dbQuoteString(ctx$conn, def$discharge_pattern)
  sql <- paste0(
    "with events as (",
    "select ", qpatient, " as patient_key, ", date_expr, " as event_date, ",
    "case when coalesce(", qevent, "::text, '') ~* ", admission, " then 'admission' ",
    "when coalesce(", qevent, "::text, '') ~* ", discharge, " then 'discharge' else null end as event_kind ",
    "from ", ctx$table_ref, " where ", date_expr, " <= ", as_of_sql, "), ",
    "latest as (select patient_key, event_kind, row_number() over (partition by patient_key order by event_date desc) as rn from events where event_kind is not null) ",
    "select count(*) as n_rows, count(distinct patient_key) as n_patients from latest where rn = 1 and event_kind = 'admission'"
  )
  counts <- situation_count_result(ctx$conn, sql)
  summary <- situation_metric_row(def, counts, as_of, ctx$row$table_name[[1]], date_col, min_cell_count = min_cell_count, n_cohort = n_cohort)
  list(summary = summary, breakdowns = situation_source_breakdown(summary), freshness = situation_freshness_row(def, ctx$row$table_name[[1]], date_col, as_of))
}

situation_metric_unavailable_result <- function(def, ctx = NULL, message = "Required source or columns were unavailable.", n_cohort = NA_real_) {
  list(
    summary = situation_unavailable_row(def, message, n_cohort = n_cohort),
    breakdowns = empty_situation_report_breakdowns(),
    freshness = empty_situation_report_freshness()
  )
}

situation_breakdowns_for_condition <- function(def, ctx, condition, summary, patient_col, min_cell_count = atlas_min_cell_count()) {
  if (!is.data.frame(summary) || !nrow(summary) || summary$definition_status[[1]] %in% c("unavailable", "suppressed")) {
    return(empty_situation_report_breakdowns())
  }
  rows <- list(situation_source_breakdown(summary))
  breakdown_defs <- list(
    region = c("region_name", "region", "Reg_Region"),
    hospital = c("hospital_area_name", "hospital_name", "overafdeling_name", "afsnit_name", "organisation", "Reg_OrganisationKode_Shak"),
    source = c("datasource", "tablename", "source"),
    registry = c("registry", "register", "tablename", "datasource")
  )
  qpatient <- DBI::dbQuoteIdentifier(ctx$conn, patient_col)
  for (type in names(breakdown_defs)) {
    col <- situation_find_column(ctx$columns, breakdown_defs[[type]])
    if (is.na(col)) next
    qcol <- DBI::dbQuoteIdentifier(ctx$conn, col)
    sql <- paste0(
      "select left(", qcol, "::text, 120) as breakdown_value, count(*) as n_rows, count(distinct ", qpatient, ") as n_patients ",
      "from ", ctx$table_ref, " where ", condition, " and ", qcol, " is not null and btrim(", qcol, "::text) <> '' ",
      "group by 1 having count(distinct ", qpatient, ") >= ", as.integer(normalize_min_cell_count(min_cell_count)),
      " order by n_patients desc, breakdown_value limit 50"
    )
    out <- tryCatch(DBI::dbGetQuery(ctx$conn, sql), error = function(e) data.frame())
    if (!nrow(out)) next
    rows[[length(rows) + 1L]] <- data.frame(
      metric_id = summary$metric_id[[1]],
      label = summary$label[[1]],
      breakdown_type = type,
      breakdown_value = truncate_value(out$breakdown_value),
      n_patients = suppressWarnings(as.numeric(out$n_patients)),
      n_rows = suppressWarnings(as.numeric(out$n_rows)),
      pct_patients = vapply(suppressWarnings(as.numeric(out$n_patients)), safe_pct, numeric(1), denom = summary$n_patients[[1]]),
      source_table = summary$source_table[[1]],
      as_of_date = summary$as_of_date[[1]],
      stringsAsFactors = FALSE
    )
  }
  bind_rows_base(rows)
}

situation_source_breakdown <- function(summary) {
  if (!is.data.frame(summary) || !nrow(summary) || is.na(summary$n_patients[[1]])) return(empty_situation_report_breakdowns())
  data.frame(
    metric_id = summary$metric_id[[1]],
    label = summary$label[[1]],
    breakdown_type = "source",
    breakdown_value = summary$source_table[[1]],
    n_patients = summary$n_patients[[1]],
    n_rows = summary$n_rows[[1]],
    pct_patients = 100,
    source_table = summary$source_table[[1]],
    as_of_date = summary$as_of_date[[1]],
    stringsAsFactors = FALSE
  )
}

apply_situation_freshness <- function(summary, breakdowns, freshness) {
  if (!nrow(summary)) summary <- empty_situation_report_summary()
  if (!nrow(breakdowns)) breakdowns <- empty_situation_report_breakdowns()
  if (!nrow(freshness)) freshness <- empty_situation_report_freshness()
  as_of <- safe_as_date(summary$as_of_date)
  global_as_of <- if (any(!is.na(as_of))) max(as_of, na.rm = TRUE) else as.Date(NA)
  if (!is.na(global_as_of) && nrow(summary)) {
    lag_days <- as.numeric(global_as_of - as_of)
    status <- ifelse(is.na(lag_days), "unknown", ifelse(lag_days > 30, "stale", ifelse(lag_days > 0, "lagging", "current")))
    summary$freshness_status <- ifelse(summary$definition_status == "unavailable", "unknown", status)
    stale <- summary$freshness_status %in% c("lagging", "stale") & !is.na(as_of)
    if (any(stale)) {
      note <- paste0("Data as of ", as.character(as_of[stale]), "; source lags the freshest situation-report source.")
      existing <- as.character(summary$message[stale] %||% "")
      existing[is.na(existing)] <- ""
      summary$message[stale] <- trimws(paste(existing, note))
    }
  }
  if (!is.na(global_as_of) && nrow(freshness)) {
    max_dates <- safe_as_date(freshness$max_date)
    lag_days <- as.numeric(global_as_of - max_dates)
    freshness$as_of_date <- as.character(global_as_of)
    freshness$lag_days <- lag_days
    freshness$freshness_status <- ifelse(is.na(lag_days), "unknown", ifelse(lag_days > 30, "stale", ifelse(lag_days > 0, "lagging", "current")))
    freshness$message <- ifelse(
      freshness$freshness_status == "current",
      "Source date matches the freshest situation-report source.",
      "Source lags behind the freshest situation-report source."
    )
  }
  list(
    situation_report_summary = summary,
    situation_report_breakdowns = breakdowns,
    situation_report_freshness = freshness
  )
}

situation_recent_from_data <- function(data, metric_id, label, date_col, patient_col = "patientid",
                                       window_days = 30L, min_cell_count = atlas_min_cell_count(),
                                       n_cohort = NA_real_, definition_basis = "fixture_recent_date") {
  dates <- safe_as_date(data[[date_col]])
  as_of <- max(dates, na.rm = TRUE)
  ok <- !is.na(dates) & dates >= as_of - window_days & dates <= as_of
  patients <- unique(data[[patient_col]][ok])
  patients <- patients[!is.na(patients) & trimws(as.character(patients)) != ""]
  n_patients <- length(patients)
  n_rows <- sum(ok)
  suppressed <- n_patients < normalize_min_cell_count(min_cell_count)
  data.frame(
    metric_id = metric_id,
    label = label,
    n_patients = if (suppressed) NA_real_ else n_patients,
    n_rows = if (suppressed) NA_real_ else n_rows,
    window_days = window_days,
    as_of_date = as.character(as_of),
    source_table = "fixture",
    date_column = date_col,
    definition_basis = definition_basis,
    n_cohort = suppressWarnings(as.numeric(n_cohort)),
    pct_cohort = safe_pct(if (suppressed) NA_real_ else n_patients, n_cohort),
    definition_status = if (suppressed) "suppressed" else "ok",
    freshness_status = "current",
    message = if (suppressed) "Suppressed below minimum cell count." else "",
    stringsAsFactors = FALSE
  )
}

situation_current_interval_from_data <- function(data, metric_id, label, start_col, end_col = NULL,
                                                 patient_col = "patientid", min_cell_count = atlas_min_cell_count(),
                                                 n_cohort = NA_real_, definition_basis = "fixture_current_interval") {
  starts <- safe_as_date(data[[start_col]])
  ends <- if (!is.null(end_col) && end_col %in% names(data)) safe_as_date(data[[end_col]]) else rep(as.Date(NA), nrow(data))
  as_of <- max(c(starts, ends), na.rm = TRUE)
  ok <- !is.na(starts) & starts <= as_of & (is.na(ends) | ends >= as_of)
  patients <- unique(data[[patient_col]][ok])
  patients <- patients[!is.na(patients) & trimws(as.character(patients)) != ""]
  n_patients <- length(patients)
  n_rows <- sum(ok)
  suppressed <- n_patients < normalize_min_cell_count(min_cell_count)
  data.frame(
    metric_id = metric_id,
    label = label,
    n_patients = if (suppressed) NA_real_ else n_patients,
    n_rows = if (suppressed) NA_real_ else n_rows,
    window_days = NA_integer_,
    as_of_date = as.character(as_of),
    source_table = "fixture",
    date_column = start_col,
    definition_basis = definition_basis,
    n_cohort = suppressWarnings(as.numeric(n_cohort)),
    pct_cohort = safe_pct(if (suppressed) NA_real_ else n_patients, n_cohort),
    definition_status = if (suppressed) "suppressed" else "ok",
    freshness_status = "current",
    message = if (suppressed) "Suppressed below minimum cell count." else "",
    stringsAsFactors = FALSE
  )
}

situation_inpatient_rows <- function(data, class_col = NULL) {
  if (is.null(class_col) || !class_col %in% names(data)) return(rep(TRUE, nrow(data)))
  value <- tolower(as.character(data[[class_col]]))
  !grepl("ambulant|outpatient", value) & grepl("indlagt|inpatient", value)
}

situation_current_admission_from_data <- function(data, start_col = "kontakt_start_local_dttm",
                                                  end_col = "kontakt_end_local_dttm",
                                                  patient_col = "patientid",
                                                  class_col = "patient_class",
                                                  as_of = NULL,
                                                  min_cell_count = atlas_min_cell_count(),
                                                  n_cohort = NA_real_) {
  def <- situation_report_metric_defs()[[1]]
  if (!start_col %in% names(data) || is.null(end_col) || !end_col %in% names(data) || !patient_col %in% names(data)) {
    return(situation_unavailable_row(def, "Required paired patient/admission start/end columns were not found.", n_cohort = n_cohort))
  }
  starts <- safe_as_date(data[[start_col]])
  ends <- safe_as_date(data[[end_col]])
  if (is.null(as_of)) as_of <- max(c(starts, ends), na.rm = TRUE)
  as_of <- as.Date(as_of)
  inpatient <- situation_inpatient_rows(data, class_col)
  ok <- !is.na(starts) & starts <= as_of & (is.na(ends) | ends > as_of) & inpatient
  patients <- unique(data[[patient_col]][ok])
  patients <- patients[!is.na(patients) & trimws(as.character(patients)) != ""]
  counts <- list(n_rows = sum(ok), n_patients = length(patients))
  situation_metric_row(
    def, counts, as_of, "fixture", start_col,
    min_cell_count = min_cell_count,
    definition_basis = paste(c(def$definition_basis, paste0("start:", start_col), paste0("end:", end_col), paste0("inpatient_filter:", class_col)), collapse = "; "),
    n_cohort = n_cohort
  )
}

situation_recent_admission_date_from_data <- function(data, metric_id, label, date_col,
                                                      patient_col = "patientid",
                                                      class_col = "patient_class",
                                                      window_days = 30L,
                                                      as_of = NULL,
                                                      min_cell_count = atlas_min_cell_count(),
                                                      n_cohort = NA_real_) {
  if (!date_col %in% names(data) || !patient_col %in% names(data)) {
    def <- list(metric_id = metric_id, label = label, window_days = window_days, definition_basis = "fixture_recent_inpatient_contact_date")
    return(situation_unavailable_row(def, "Required patient/date columns were not found.", n_cohort = n_cohort))
  }
  dates <- safe_as_date(data[[date_col]])
  if (is.null(as_of)) as_of <- max(dates, na.rm = TRUE)
  as_of <- as.Date(as_of)
  inpatient <- situation_inpatient_rows(data, class_col)
  ok <- !is.na(dates) & dates >= as_of - window_days & dates <= as_of & inpatient
  patients <- unique(data[[patient_col]][ok])
  patients <- patients[!is.na(patients) & trimws(as.character(patients)) != ""]
  counts <- list(n_rows = sum(ok), n_patients = length(patients))
  situation_metric_row(
    list(metric_id = metric_id, label = label, window_days = window_days, definition_basis = "fixture_recent_inpatient_contact_date"),
    counts, as_of, "fixture", date_col,
    min_cell_count = min_cell_count,
    definition_basis = paste(c("fixture_recent_inpatient_contact_date", paste0("date:", date_col), paste0("inpatient_filter:", class_col)), collapse = "; "),
    n_cohort = n_cohort
  )
}
