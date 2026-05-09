profile_source <- function(data, table_name, source_type = NA_character_, source = NA_character_,
                           profile_mode = "full", top_n = 10L,
                           min_cell_count = atlas_min_cell_count(),
                           npu_dictionary = NULL,
                           npu_surfaces = NULL,
                           isotype_vectors = NULL,
                           treatment_families = NULL) {
  if (!is.data.frame(data)) {
    stop("profile_source() requires a data frame.", call. = FALSE)
  }
  profile_mode <- normalize_profile_mode(profile_mode)
  min_cell_count <- normalize_min_cell_count(min_cell_count)
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
  column_profiles <- profile_column_profiles(data, table_name, profile_mode = profile_mode)
  checks <- profile_checks(data, table_name)
  frequencies <- if (identical(profile_mode, "full")) {
    profile_value_frequencies(data, table_name, top_n = top_n, min_cell_count = min_cell_count)
  } else {
    empty_value_frequencies()
  }
  column_top_values <- if (identical(profile_mode, "full")) {
    profile_column_top_values(data, table_name, top_n = top_n, min_cell_count = min_cell_count)
  } else {
    empty_column_top_values()
  }
  panels <- profile_panels(
    data = data,
    table_name = table_name,
    profile_mode = profile_mode,
    min_cell_count = min_cell_count,
    npu_dictionary = npu_dictionary,
    npu_surfaces = npu_surfaces,
    isotype_vectors = isotype_vectors,
    treatment_families = treatment_families
  )

  list(
    source = source_row,
    columns = columns,
    column_profiles = column_profiles,
    column_top_values = column_top_values,
    checks = checks,
    value_frequencies = frequencies,
    panels = panels
  )
}

normalize_profile_mode <- function(profile_mode) {
  profile_mode <- tolower(trimws(as.character(profile_mode %||% "full")))
  profile_mode[profile_mode == ""] <- "full"
  if (!profile_mode[[1]] %in% valid_profile_modes()) return("full")
  profile_mode[[1]]
}

atlas_min_cell_count <- function() {
  normalize_min_cell_count(Sys.getenv("DALYCARE_MIN_CELL_COUNT", unset = "5"))
}

normalize_min_cell_count <- function(x) {
  out <- suppressWarnings(as.integer(x[[1]] %||% 5L))
  if (is.na(out) || out < 1L) return(5L)
  out
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
    is_sensitive <- safe_sensitive_column(nm, x)
    is_numeric_like <- is_numeric_like_vector(x)
    data.frame(
      table_name = table_name,
      column_name = nm,
      column_type = typeof(x),
      column_class = class_scalar(x),
      n_missing = sum(missing),
      pct_missing = safe_pct(sum(missing), length(x)),
      n_distinct_capped = count_distinct_capped(x),
      is_sensitive = is_sensitive,
      is_date_like = is_date_like_column(nm, x),
      is_numeric_like = is_numeric_like,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

empty_column_profiles <- function() {
  empty_df(
    table_name = character(), column_name = character(), column_type = character(),
    column_class = character(), profile_kind = character(), n_rows = integer(),
    n_available = integer(), pct_available = numeric(), n_missing = integer(),
    pct_missing = numeric(), n_distinct_capped = integer(), is_sensitive = logical(),
    is_date_like = logical(), is_numeric_like = logical(), min = numeric(),
    mean = numeric(), median = numeric(), p25 = numeric(), p75 = numeric(),
    max = numeric(), min_date = character(), max_date = character()
  )
}

profile_column_profiles <- function(data, table_name, profile_mode = "full") {
  if (!ncol(data)) return(empty_column_profiles())
  profile_mode <- normalize_profile_mode(profile_mode)
  rows <- lapply(names(data), function(nm) {
    x <- data[[nm]]
    missing <- is.na(x) | trimws(as.character(x)) == ""
    n_available <- sum(!missing)
    is_sensitive <- safe_sensitive_column(nm, x)
    is_date_like <- is_date_like_column(nm, x)
    is_numeric_like <- is_numeric_like_vector(x)
    profile_kind <- if (is_sensitive) {
      "sensitive"
    } else if (is_date_like) {
      "date"
    } else if (is_numeric_like) {
      "numeric"
    } else {
      "categorical"
    }
    numeric_stats <- column_numeric_stats(x, enabled = !is_sensitive && is_numeric_like && !identical(profile_mode, "schema"))
    date_stats <- column_date_stats(x, enabled = !is_sensitive && is_date_like && !identical(profile_mode, "schema"))
    data.frame(
      table_name = table_name,
      column_name = nm,
      column_type = typeof(x),
      column_class = class_scalar(x),
      profile_kind = profile_kind,
      n_rows = length(x),
      n_available = n_available,
      pct_available = safe_pct(n_available, length(x)),
      n_missing = sum(missing),
      pct_missing = safe_pct(sum(missing), length(x)),
      n_distinct_capped = count_distinct_capped(x),
      is_sensitive = is_sensitive,
      is_date_like = is_date_like,
      is_numeric_like = is_numeric_like,
      min = numeric_stats$min,
      mean = numeric_stats$mean,
      median = numeric_stats$median,
      p25 = numeric_stats$p25,
      p75 = numeric_stats$p75,
      max = numeric_stats$max,
      min_date = as.character(date_stats$min_date),
      max_date = as.character(date_stats$max_date),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_column_profiles())
  out
}

column_numeric_stats <- function(x, enabled = TRUE) {
  empty <- list(min = NA_real_, mean = NA_real_, median = NA_real_, p25 = NA_real_, p75 = NA_real_, max = NA_real_)
  if (!isTRUE(enabled)) return(empty)
  values <- suppressWarnings(as.numeric(as.character(x)))
  values <- values[!is.na(values)]
  if (!length(values)) return(empty)
  list(
    min = min(values),
    mean = mean(values),
    median = stats::median(values),
    p25 = as.numeric(stats::quantile(values, 0.25, na.rm = TRUE, names = FALSE)),
    p75 = as.numeric(stats::quantile(values, 0.75, na.rm = TRUE, names = FALSE)),
    max = max(values)
  )
}

column_date_stats <- function(x, enabled = TRUE) {
  empty <- list(min_date = NA_character_, max_date = NA_character_)
  if (!isTRUE(enabled)) return(empty)
  values <- safe_as_date(x)
  values <- values[!is.na(values)]
  if (!length(values)) return(empty)
  list(min_date = as.character(min(values)), max_date = as.character(max(values)))
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

empty_value_frequencies <- function() {
  empty_df(table_name = character(), column_name = character(), value = character(), n = integer(), pct = numeric())
}

empty_column_top_values <- function() {
  empty_df(table_name = character(), column_name = character(), value = character(), n = integer(), pct_rows = numeric())
}

profile_value_frequencies <- function(data, table_name, top_n = 10L, min_cell_count = atlas_min_cell_count()) {
  top_values <- profile_column_top_values(data, table_name, top_n = top_n, min_cell_count = min_cell_count)
  if (!nrow(top_values)) return(empty_value_frequencies())
  data.frame(
    table_name = top_values$table_name,
    column_name = top_values$column_name,
    value = top_values$value,
    n = top_values$n,
    pct = top_values$pct_rows,
    stringsAsFactors = FALSE
  )
}

profile_column_top_values <- function(data, table_name, top_n = 10L, min_cell_count = atlas_min_cell_count()) {
  if (!nrow(data) || !ncol(data)) {
    return(empty_column_top_values())
  }
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  eligible <- names(data)[vapply(names(data), function(nm) {
    x <- data[[nm]]
    !safe_sensitive_column(nm, x) &&
      !is_date_like_column(nm, x) &&
      !is_numeric_like_vector(x) &&
      count_distinct_capped(x, cap = 5000L) <= 100L
  }, logical(1))]
  rows <- lapply(eligible, function(nm) {
    out <- top_counts(data[[nm]], denom = nrow(data), top_n = top_n, min_count = min_cell_count)
    if (!nrow(out)) return(out)
    data.frame(
      table_name = table_name,
      column_name = nm,
      value = out$value,
      n = out$n,
      pct_rows = out$pct,
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_column_top_values())
  out
}

safe_sensitive_column <- function(name, x) {
  is_sensitive_column(name) || column_looks_cpr_like(x)
}

column_looks_cpr_like <- function(x) {
  sample_x <- head(x[!(is.na(x) | trimws(as.character(x)) == "")], 1000)
  length(sample_x) > 0 && mean(looks_cpr_like(sample_x)) > 0.8
}

is_numeric_like_vector <- function(x) {
  if (is.numeric(x)) return(TRUE)
  nonmissing <- !(is.na(x) | trimws(as.character(x)) == "")
  if (!any(nonmissing)) return(FALSE)
  mean(!is.na(suppressWarnings(as.numeric(as.character(x[nonmissing]))))) >= 0.8
}

profile_panels <- function(data, table_name, profile_mode = "full", min_cell_count = atlas_min_cell_count(),
                           npu_dictionary = NULL,
                           npu_surfaces = NULL,
                           isotype_vectors = NULL,
                           treatment_families = NULL) {
  profile_mode <- normalize_profile_mode(profile_mode)
  if (identical(profile_mode, "schema")) {
    return(list())
  }
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  summary_panels <- list(
    lab_npu_code_coverage = panel_lab_codes(data, table_name, min_cell_count = min_cell_count),
    npu_lab_usage_by_vector = panel_npu_lab_usage_by_vector(data, table_name, npu_dictionary, min_cell_count = min_cell_count),
    npu_lab_unmatched_codes = panel_npu_lab_unmatched_codes(data, table_name, npu_dictionary, min_cell_count = min_cell_count),
    npu_detective_code_inventory = panel_npu_detective_code_inventory(data, table_name, npu_dictionary, npu_surfaces, min_cell_count = min_cell_count),
    npu_detective_candidates = panel_npu_detective_candidates(data, table_name, npu_dictionary, npu_surfaces, min_cell_count = min_cell_count),
    npu_detective_source_year = panel_npu_detective_source_year(data, table_name, npu_dictionary, npu_surfaces, min_cell_count = min_cell_count),
    isotype_code_usage = panel_isotype_code_usage(data, table_name, isotype_vectors, min_cell_count = min_cell_count),
    isotype_bucket_summary = panel_isotype_bucket_summary(data, table_name, isotype_vectors, min_cell_count = min_cell_count),
    mm_treatment_code_counts = panel_mm_treatment_code_counts(data, table_name, treatment_families, min_cell_count = min_cell_count),
    mm_treatment_source_summary = panel_mm_treatment_source_summary(data, table_name, treatment_families, min_cell_count = min_cell_count),
    diagnosis_icd_groups = panel_diagnosis_groups(data, table_name),
    medication_atc_groups = panel_atc_groups(data, table_name),
    damyda_feature_coverage = panel_damyda_features(data, table_name),
    registry_clinical_summary = panel_registry_summary(data, table_name),
    sp_operational_sources = panel_sp_sources(data, table_name)
  )
  if (identical(profile_mode, "summary")) {
    return(summary_panels)
  }
  c(
    summary_panels,
    list(
      damyda_clinical_profile = panel_damyda_clinical_profile(data, table_name, min_cell_count = min_cell_count),
      damyda_numeric_fields = panel_damyda_numeric_fields(data, table_name),
      lyfo_clinical_profile = panel_lyfo_clinical_profile(data, table_name, min_cell_count = min_cell_count),
      cll_clinical_profile = panel_cll_clinical_profile(data, table_name, min_cell_count = min_cell_count)
    )
  )
}

first_matching_column <- function(data, patterns) {
  hits <- names(data)[Reduce(`|`, lapply(patterns, function(p) grepl(p, names(data), ignore.case = TRUE)))]
  hits[1] %||% NA_character_
}

panel_lab_codes <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) {
    return(empty_df(table_name = character(), code_column = character(), lab_code = character(), n = integer(), pct_rows = numeric()))
  }
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = min_cell_count)
  npu_lab_code_coverage_from_counts(counts, table_name = table_name, code_column = code_col, min_cell_count = min_cell_count)
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

registry_name <- function(table_name) {
  if (grepl("damyda", table_name, ignore.case = TRUE)) return("DaMyDa")
  if (grepl("lyfo", table_name, ignore.case = TRUE)) return("LYFO")
  if (grepl("^cll$|rkkp.*cll", table_name, ignore.case = TRUE)) return("CLL")
  NA_character_
}

empty_registry_summary <- function() {
  empty_df(
    table_name = character(), registry = character(), n_rows = integer(),
    n_cols = integer(), n_patients = integer(), min_date = character(),
    max_date = character()
  )
}

empty_registry_categorical <- function() {
  empty_df(
    table_name = character(), registry = character(), facet = character(),
    source_column = character(), label = character(), n = integer(),
    pct_rows = numeric()
  )
}

empty_registry_numeric <- function() {
  empty_df(
    table_name = character(), registry = character(), field = character(),
    source_column = character(), unit = character(), n_available = integer(),
    pct_available = numeric(), mean = numeric(), median = numeric(),
    p25 = numeric(), p75 = numeric()
  )
}

registry_column <- function(data, candidates) {
  columns <- names(data)
  if (!length(columns)) return(NA_character_)
  columns_lc <- tolower(columns)
  for (candidate in candidates) {
    candidate_lc <- tolower(candidate)
    exact <- which(columns_lc == candidate_lc)
    exact <- exact[!vapply(columns[exact], is_sensitive_column, logical(1))]
    if (length(exact)) return(columns[[exact[[1]]]])
  }
  for (candidate in candidates) {
    candidate_lc <- tolower(candidate)
    partial <- which(grepl(candidate_lc, columns_lc, fixed = TRUE))
    partial <- partial[!vapply(columns[partial], is_sensitive_column, logical(1))]
    if (length(partial)) return(columns[[partial[[1]]]])
  }
  NA_character_
}

registry_patient_count <- function(data) {
  id_col <- guess_id_column(data)
  if (!is.na(id_col) && id_col %in% names(data)) {
    return(count_distinct_capped(data[[id_col]]))
  }
  nrow(data)
}

panel_registry_summary <- function(data, table_name) {
  registry <- registry_name(table_name)
  if (is.na(registry)) return(empty_registry_summary())
  range <- source_date_range(data)
  data.frame(
    table_name = table_name,
    registry = registry,
    n_rows = nrow(data),
    n_cols = ncol(data),
    n_patients = registry_patient_count(data),
    min_date = as.character(range$min_date),
    max_date = as.character(range$max_date),
    stringsAsFactors = FALSE
  )
}

registry_top_labels <- function(data, table_name, registry, facet, candidates, top_n = 12L,
                                min_cell_count = atlas_min_cell_count()) {
  source_column <- registry_column(data, candidates)
  if (is.na(source_column)) return(empty_registry_categorical())
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  values <- data[[source_column]]
  sample_values <- head(values[!(is.na(values) | trimws(as.character(values)) == "")], 1000)
  if (length(sample_values) && mean(looks_cpr_like(sample_values)) > 0.8) {
    return(empty_registry_categorical())
  }
  counts <- top_counts(values, denom = nrow(data), top_n = top_n, min_count = min_cell_count)
  if (!nrow(counts)) return(empty_registry_categorical())
  data.frame(
    table_name = table_name,
    registry = registry,
    facet = facet,
    source_column = source_column,
    label = counts$value,
    n = counts$n,
    pct_rows = counts$pct,
    stringsAsFactors = FALSE
  )
}

registry_categorical_panel <- function(data, table_name, registry, specs,
                                       min_cell_count = atlas_min_cell_count()) {
  if (!length(specs)) return(empty_registry_categorical())
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  rows <- lapply(specs, function(spec) {
    registry_top_labels(
      data = data,
      table_name = table_name,
      registry = registry,
      facet = spec$facet,
      candidates = spec$candidates,
      top_n = spec$top_n %||% 12L,
      min_cell_count = min_cell_count
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_registry_categorical())
  out
}

registry_numeric_field <- function(data, table_name, registry, field, candidates, unit = NA_character_) {
  source_column <- registry_column(data, candidates)
  if (is.na(source_column)) return(empty_registry_numeric())
  values <- suppressWarnings(as.numeric(as.character(data[[source_column]])))
  values <- values[!is.na(values)]
  if (!length(values)) return(empty_registry_numeric())
  data.frame(
    table_name = table_name,
    registry = registry,
    field = field,
    source_column = source_column,
    unit = unit,
    n_available = length(values),
    pct_available = safe_pct(length(values), nrow(data)),
    mean = mean(values),
    median = stats::median(values),
    p25 = as.numeric(stats::quantile(values, 0.25, na.rm = TRUE, names = FALSE)),
    p75 = as.numeric(stats::quantile(values, 0.75, na.rm = TRUE, names = FALSE)),
    stringsAsFactors = FALSE
  )
}

registry_numeric_panel <- function(data, table_name, registry, specs) {
  if (!length(specs)) return(empty_registry_numeric())
  rows <- lapply(specs, function(spec) {
    registry_numeric_field(
      data = data,
      table_name = table_name,
      registry = registry,
      field = spec$field,
      candidates = spec$candidates,
      unit = spec$unit %||% NA_character_
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_registry_numeric())
  out
}

registry_spec <- function(facet, candidates, top_n = 12L) {
  list(facet = facet, candidates = candidates, top_n = top_n)
}

registry_numeric_spec <- function(field, candidates, unit = NA_character_) {
  list(field = field, candidates = candidates, unit = unit)
}

panel_damyda_clinical_profile <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  if (!identical(registry_name(table_name), "DaMyDa")) return(empty_registry_categorical())
  specs <- list(
    registry_spec("stage", c("Reg_ISS_Stadie", "Stadie", "iss_stage", "ISS", "stage", "stadie"), 10L),
    registry_spec("bone_disease", c("Reg_Knogleforandringer", "bone_disease", "knogle_present"), 5L),
    registry_spec("bone_disease_type", c("Reg_Knogleforandringer_type", "bone_type", "knogle_type"), 8L),
    registry_spec("amyloidosis", c("Reg_Amyloidose", "amyloidosis", "amyloidose"), 5L),
    registry_spec("treatment_flag", c("Reg_Behandlet", "treatment_required", "treated", "behandlet"), 5L),
    registry_spec("relapse_flag", c("Reg_Relaps", "relapse", "relaps"), 5L),
    registry_spec("followup_flag", c("Reg_FollowUp", "followup"), 5L),
    registry_spec("primary_response", c("Reg_Respons1", "primary_response"), 12L),
    registry_spec("secondary_response", c("Reg_Respons2", "secondary_response"), 12L),
    registry_spec("primary_treatment", c("Reg_PrimaerBehandling", "primary_tx", "primary_treatment", "regime"), 14L),
    registry_spec("secondary_treatment", c("Reg_SekundaerBehandling", "secondary_tx", "secondary_treatment"), 14L),
    registry_spec("followup_treatment", c("Reg_OpfBehandling", "followup_tx", "followup_treatment"), 12L),
    registry_spec("primary_complications", c("Reg_Komplikationer1", "primary_comp"), 10L),
    registry_spec("secondary_complications", c("Reg_Komplikationer2", "secondary_comp"), 12L),
    registry_spec("followup_complications", c("Reg_Komplikationer3", "followup_comp"), 12L),
    registry_spec("cytogenetics_fish_done", c("Reg_FISH_Udfoert", "Cyto_FishUdfoert", "fish_done"), 5L),
    registry_spec("cytogenetics_iscn", c("Reg_ISCN_Resultat", "iscn"), 6L),
    registry_spec("cytogenetics_ploidy", c("Reg_Ploidi", "ploidy"), 6L),
    registry_spec("cytogenetics_abnormality", c("Reg_FISH_Abnormitet", "fish_abn", "fish_abnormality"), 14L),
    registry_spec("performance_status", c("Reg_PerformanceStatus", "performance_status", "ecog"), 6L),
    registry_spec("m_component_type", c("Reg_MKomponentType", "mcomp_type", "let_kaede"), 12L),
    registry_spec("imaging", c("Reg_Billeddiagnostik", "imaging"), 8L),
    registry_spec("prior_mgus", c("Reg_TidligereMGUS", "prior_mgus"), 4L),
    registry_spec("charlson", c("Reg_CharlsonGruppe", "Charlson", "CCI"), 7L),
    registry_spec("region", c("Reg_Region", "region", "Region"), 8L),
    registry_spec("organisation_shak", c("Reg_OrganisationKode_Shak", "organisation_shak", "shak"), 12L)
  )
  registry_categorical_panel(data, table_name, "DaMyDa", specs, min_cell_count = min_cell_count)
}

panel_damyda_numeric_fields <- function(data, table_name) {
  if (!identical(registry_name(table_name), "DaMyDa")) return(empty_registry_numeric())
  specs <- list(
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
  registry_numeric_panel(data, table_name, "DaMyDa", specs)
}

panel_lyfo_clinical_profile <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  if (!identical(registry_name(table_name), "LYFO")) return(empty_registry_categorical())
  specs <- list(
    registry_spec("subtype", c("Reg_Subtype", "subtype", "WHO", "lymfomtype"), 18L),
    registry_spec("ann_arbor_stage", c("Reg_Stadium", "Reg_AnnArbor", "ann_arbor", "stage", "stadie"), 6L),
    registry_spec("ipi", c("Reg_IPI", "ipi", "aaipi"), 7L),
    registry_spec("b_symptoms", c("Reg_BSymptomer", "b_symptoms"), 4L),
    registry_spec("performance_status", c("Reg_PerformanceStatusWHO", "Reg_PS", "performance", "ecog"), 6L),
    registry_spec("treatment_flag", c("Reg_Behandlet", "treatment_flag", "treated"), 4L),
    registry_spec("bulk_disease", c("Reg_BulkSygdom", "Reg_Bulk", "bulk", "bulk_disease"), 4L)
  )
  registry_categorical_panel(data, table_name, "LYFO", specs, min_cell_count = min_cell_count)
}

panel_cll_clinical_profile <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  if (!identical(registry_name(table_name), "CLL")) return(empty_registry_categorical())
  specs <- list(
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
  )
  registry_categorical_panel(data, table_name, "CLL", specs, min_cell_count = min_cell_count)
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
