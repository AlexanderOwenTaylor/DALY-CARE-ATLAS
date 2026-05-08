profile_source <- function(data, table_name, source_type = NA_character_, source = NA_character_,
                           profile_mode = "full", top_n = 10L) {
  if (!is.data.frame(data)) {
    stop("profile_source() requires a data frame.", call. = FALSE)
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  n_rows <- nrow(data)
  n_cols <- ncol(data)
  id_guess <- guess_id_column(data)
  date_guess <- guess_date_column(data)
  date_range <- source_date_range(data)

  source_row <- data.frame(
    table_name = table_name,
    source_type = source_type,
    source = source,
    profile_mode = profile_mode,
    load_status = "ok",
    n_rows = n_rows,
    n_cols = n_cols,
    id_column_guess = id_guess,
    date_column_guess = date_guess,
    min_date = as.character(date_range$min_date),
    max_date = as.character(date_range$max_date),
    schema_signature = schema_signature(data),
    profiled_at = atlas_timestamp(),
    stringsAsFactors = FALSE
  )

  columns <- profile_columns(data, table_name)
  checks <- profile_checks(data, table_name)
  frequencies <- profile_value_frequencies(data, table_name, top_n = top_n)
  panels <- profile_panels(data, table_name)

  list(
    source = source_row,
    columns = columns,
    checks = checks,
    value_frequencies = frequencies,
    panels = panels
  )
}

source_date_range <- function(data) {
  date_cols <- names(data)[vapply(names(data), function(nm) is_date_like_column(nm, data[[nm]]), logical(1))]
  if (!length(date_cols)) {
    return(list(min_date = as.Date(NA), max_date = as.Date(NA)))
  }
  values <- do.call(c, lapply(date_cols, function(nm) safe_as_date(data[[nm]])))
  values <- values[!is.na(values)]
  if (!length(values)) {
    return(list(min_date = as.Date(NA), max_date = as.Date(NA)))
  }
  list(min_date = min(values), max_date = max(values))
}

profile_columns <- function(data, table_name) {
  if (!ncol(data)) {
    return(empty_df(
      table_name = character(), column_name = character(), column_type = character(),
      column_class = character(), n_missing = integer(), pct_missing = numeric(),
      n_distinct_capped = integer(), is_sensitive = logical(), is_date_like = logical(),
      is_numeric_like = logical()
    ))
  }
  rows <- lapply(names(data), function(nm) {
    x <- data[[nm]]
    missing <- is.na(x) | trimws(as.character(x)) == ""
    data.frame(
      table_name = table_name,
      column_name = nm,
      column_type = typeof(x),
      column_class = class_scalar(x),
      n_missing = sum(missing),
      pct_missing = safe_pct(sum(missing), length(x)),
      n_distinct_capped = count_distinct_capped(x),
      is_sensitive = is_sensitive_column(nm),
      is_date_like = is_date_like_column(nm, x),
      is_numeric_like = is.numeric(x) || mean(!is.na(suppressWarnings(as.numeric(as.character(x))))) >= 0.8,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

profile_checks <- function(data, table_name) {
  checks <- list()
  if (!nrow(data)) {
    checks[[length(checks) + 1L]] <- check_row(table_name, "empty_table", "warning", "Source loaded with zero rows.")
  }
  sensitive <- names(data)[vapply(names(data), is_sensitive_column, logical(1))]
  if (length(sensitive)) {
    checks[[length(checks) + 1L]] <- check_row(
      table_name,
      "sensitive_column_values_suppressed",
      "ok",
      paste("Value frequencies suppressed for:", paste(sensitive, collapse = ", "))
    )
  }
  cpr_like_columns <- names(data)[vapply(data, function(x) {
    sample_x <- head(x[!(is.na(x) | trimws(as.character(x)) == "")], 1000)
    length(sample_x) > 0 && mean(looks_cpr_like(sample_x)) > 0.8
  }, logical(1))]
  if (length(cpr_like_columns)) {
    checks[[length(checks) + 1L]] <- check_row(
      table_name,
      "cpr_like_values_detected_and_suppressed",
      "warning",
      paste("Possible CPR-like values detected in:", paste(cpr_like_columns, collapse = ", "))
    )
  }
  bind_rows_base(checks)
}

check_row <- function(table_name, check_id, severity, message) {
  data.frame(
    table_name = table_name,
    check_id = check_id,
    severity = severity,
    message = message,
    stringsAsFactors = FALSE
  )
}

profile_value_frequencies <- function(data, table_name, top_n = 10L) {
  if (!nrow(data) || !ncol(data)) {
    return(empty_df(table_name = character(), column_name = character(), value = character(), n = integer(), pct = numeric()))
  }
  eligible <- names(data)[vapply(names(data), function(nm) {
    x <- data[[nm]]
    !is_sensitive_column(nm) &&
      !is_date_like_column(nm, x) &&
      !is.numeric(x) &&
      count_distinct_capped(x, cap = 5000L) <= 100L
  }, logical(1))]
  rows <- lapply(eligible, function(nm) {
    out <- top_counts(data[[nm]], denom = nrow(data), top_n = top_n)
    if (!nrow(out)) return(out)
    cbind(table_name = table_name, column_name = nm, out, stringsAsFactors = FALSE)
  })
  bind_rows_base(rows)
}

profile_panels <- function(data, table_name) {
  list(
    lab_npu_code_coverage = panel_lab_codes(data, table_name),
    diagnosis_icd_groups = panel_diagnosis_groups(data, table_name),
    medication_atc_groups = panel_atc_groups(data, table_name),
    damyda_feature_coverage = panel_damyda_features(data, table_name),
    sp_operational_sources = panel_sp_sources(data, table_name)
  )
}

first_matching_column <- function(data, patterns) {
  hits <- names(data)[Reduce(`|`, lapply(patterns, function(p) grepl(p, names(data), ignore.case = TRUE)))]
  hits[1] %||% NA_character_
}

panel_lab_codes <- function(data, table_name) {
  code_col <- first_matching_column(data, c("npu", "analysis.*code", "analyse.*kode", "^code$", "lab.*code"))
  if (is.na(code_col)) {
    return(empty_df(table_name = character(), code_column = character(), lab_code = character(), n = integer(), pct_rows = numeric()))
  }
  counts <- top_counts(data[[code_col]], denom = nrow(data), top_n = 100L)
  if (!nrow(counts)) return(counts)
  data.frame(
    table_name = table_name,
    code_column = code_col,
    lab_code = counts$value,
    n = counts$n,
    pct_rows = counts$pct,
    stringsAsFactors = FALSE
  )
}

panel_diagnosis_groups <- function(data, table_name) {
  code_col <- first_matching_column(data, c("diag", "icd", "diagnos", "aktionsdiagnose"))
  if (is.na(code_col)) {
    return(empty_df(table_name = character(), diagnosis_column = character(), icd_group = character(), n = integer(), pct_rows = numeric()))
  }
  values <- toupper(gsub("[^A-Z0-9]", "", as.character(data[[code_col]])))
  groups <- ifelse(nchar(values) >= 3, substr(values, 1, 3), values)
  groups[is.na(groups) | groups == ""] <- NA_character_
  counts <- top_counts(groups, denom = nrow(data), top_n = 100L)
  if (!nrow(counts)) return(counts)
  data.frame(
    table_name = table_name,
    diagnosis_column = code_col,
    icd_group = counts$value,
    n = counts$n,
    pct_rows = counts$pct,
    stringsAsFactors = FALSE
  )
}

panel_atc_groups <- function(data, table_name) {
  atc_col <- first_matching_column(data, c("\\batc\\b", "laegemiddel", "drug", "medication"))
  if (is.na(atc_col)) {
    return(empty_df(table_name = character(), atc_column = character(), atc_group = character(), n = integer(), pct_rows = numeric()))
  }
  values <- toupper(gsub("[^A-Z0-9]", "", as.character(data[[atc_col]])))
  groups <- ifelse(nchar(values) >= 3, substr(values, 1, 3), values)
  groups[is.na(groups) | groups == ""] <- NA_character_
  counts <- top_counts(groups, denom = nrow(data), top_n = 100L)
  if (!nrow(counts)) return(counts)
  data.frame(
    table_name = table_name,
    atc_column = atc_col,
    atc_group = counts$value,
    n = counts$n,
    pct_rows = counts$pct,
    stringsAsFactors = FALSE
  )
}

panel_damyda_features <- function(data, table_name) {
  if (!grepl("damyda|rkkp", table_name, ignore.case = TRUE)) {
    return(empty_df(table_name = character(), feature = character(), n_available = integer(), pct_available = numeric()))
  }
  non_sensitive <- names(data)[!vapply(names(data), is_sensitive_column, logical(1))]
  rows <- lapply(non_sensitive, function(nm) {
    available <- !(is.na(data[[nm]]) | trimws(as.character(data[[nm]])) == "")
    data.frame(
      table_name = table_name,
      feature = nm,
      n_available = sum(available),
      pct_available = safe_pct(sum(available), nrow(data)),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(out)
  out[order(-out$n_available, out$feature), , drop = FALSE]
}

panel_sp_sources <- function(data, table_name) {
  if (!grepl("^sp_|sundhedsplatform|alleprovesvar|adt|contact", table_name, ignore.case = TRUE)) {
    return(empty_df(table_name = character(), n_rows = integer(), n_cols = integer(), min_date = character(), max_date = character()))
  }
  range <- source_date_range(data)
  data.frame(
    table_name = table_name,
    n_rows = nrow(data),
    n_cols = ncol(data),
    min_date = as.character(range$min_date),
    max_date = as.character(range$max_date),
    stringsAsFactors = FALSE
  )
}
