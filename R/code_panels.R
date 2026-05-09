npu_detective_surfaces_path <- function(project_root = ".") {
  path <- system.file("config", "npu-detective-surfaces.tsv", package = "dalycareatlas")
  if (nzchar(path) && file.exists(path)) return(path)
  file.path(project_root, "config", "npu-detective-surfaces.tsv")
}

isotype_vectors_path <- function(project_root = ".") {
  path <- system.file("config", "isotype-vectors.tsv", package = "dalycareatlas")
  if (nzchar(path) && file.exists(path)) return(path)
  file.path(project_root, "config", "isotype-vectors.tsv")
}

mm_treatment_code_families_path <- function(project_root = ".") {
  path <- system.file("config", "mm-treatment-code-families.tsv", package = "dalycareatlas")
  if (nzchar(path) && file.exists(path)) return(path)
  file.path(project_root, "config", "mm-treatment-code-families.tsv")
}

load_npu_detective_surfaces <- function(project_root = ".", path = npu_detective_surfaces_path(project_root)) {
  if (!file.exists(path)) stop("NPU detective surfaces config not found: ", path, call. = FALSE)
  raw <- read_delimited_file(path)
  required <- c("surface", "candidate_label", "consensus_vectors", "system_include", "system_exclude", "clinical_role_pattern")
  missing <- setdiff(required, names(raw))
  if (length(missing)) stop("NPU detective surfaces config missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  out <- as.data.frame(lapply(raw[required], function(x) trimws(as.character(x))), stringsAsFactors = FALSE)
  blank <- !nzchar(out$surface) | !nzchar(out$candidate_label) | !nzchar(out$consensus_vectors)
  if (any(blank)) stop("NPU detective surfaces config contains blank surface, label, or consensus vector definitions.", call. = FALSE)
  duplicated_surfaces <- unique(out$surface[duplicated(out$surface)])
  if (length(duplicated_surfaces)) stop("NPU detective surfaces config contains duplicate surfaces: ", paste(duplicated_surfaces, collapse = ", "), call. = FALSE)
  out
}

load_isotype_vectors <- function(project_root = ".", dictionary = NULL, path = isotype_vectors_path(project_root)) {
  if (!file.exists(path)) stop("Isotype vectors config not found: ", path, call. = FALSE)
  raw <- read_delimited_file(path)
  required <- c("isotype_family", "specimen_class", "bucket", "consensus_vector", "npu_code")
  missing <- setdiff(required, names(raw))
  if (length(missing)) stop("Isotype vectors config missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  raw <- as.data.frame(lapply(raw[required], function(x) trimws(as.character(x))), stringsAsFactors = FALSE)
  blank_key <- !nzchar(raw$isotype_family) | !nzchar(raw$specimen_class) | !nzchar(raw$bucket) | !nzchar(raw$consensus_vector)
  if (any(blank_key)) stop("Isotype vectors config contains blank family, specimen, bucket, or consensus vector.", call. = FALSE)

  rows <- lapply(seq_len(nrow(raw)), function(i) {
    row <- raw[i, , drop = FALSE]
    code <- normalize_npu_code(row$npu_code)
    if (!is.na(code) && nzchar(code)) {
      row$npu_code <- code
      return(row)
    }
    if (is.null(dictionary) || !nrow(dictionary)) {
      return(empty_df(
        isotype_family = character(), specimen_class = character(), bucket = character(),
        consensus_vector = character(), npu_code = character()
      ))
    }
    dict_rows <- dictionary[dictionary$consensus_vector == row$consensus_vector[[1]], , drop = FALSE]
    if (!nrow(dict_rows)) {
      return(empty_df(
        isotype_family = character(), specimen_class = character(), bucket = character(),
        consensus_vector = character(), npu_code = character()
      ))
    }
    data.frame(
      isotype_family = row$isotype_family[[1]],
      specimen_class = row$specimen_class[[1]],
      bucket = row$bucket[[1]],
      consensus_vector = row$consensus_vector[[1]],
      npu_code = dict_rows$npu_code,
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) stop("Isotype vectors config did not resolve to any NPU codes.", call. = FALSE)
  out <- out[!duplicated(paste(out$isotype_family, out$specimen_class, out$bucket, out$consensus_vector, out$npu_code, sep = "\r")), , drop = FALSE]
  blank_codes <- is.na(out$npu_code) | !nzchar(out$npu_code)
  if (any(blank_codes)) stop("Isotype vectors config contains blank or invalid NPU codes after expansion.", call. = FALSE)
  out
}

load_mm_treatment_code_families <- function(project_root = ".", path = mm_treatment_code_families_path(project_root)) {
  if (!file.exists(path)) stop("MM treatment code family config not found: ", path, call. = FALSE)
  raw <- read_delimited_file(path)
  required <- c("family", "code_system", "match_type", "code", "label", "source_hint")
  missing <- setdiff(required, names(raw))
  if (length(missing)) stop("MM treatment code family config missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  out <- as.data.frame(lapply(raw[required], function(x) trimws(as.character(x))), stringsAsFactors = FALSE)
  out$match_type <- tolower(out$match_type)
  out$code <- normalize_generic_code(out$code)
  blank <- !nzchar(out$family) | !nzchar(out$code_system) | !nzchar(out$match_type) | !nzchar(out$code)
  if (any(blank)) stop("MM treatment code family config contains blank family, system, match type, or code.", call. = FALSE)
  invalid_match <- !out$match_type %in% c("exact", "prefix")
  if (any(invalid_match)) stop("MM treatment code family config has invalid match_type values.", call. = FALSE)
  duplicate_keys <- unique(paste(out$family, out$code_system, out$match_type, out$code, sep = "|")[duplicated(paste(out$family, out$code_system, out$match_type, out$code, sep = "|"))])
  if (length(duplicate_keys)) stop("MM treatment code family config contains duplicate keys: ", paste(duplicate_keys, collapse = ", "), call. = FALSE)
  out
}

normalize_generic_code <- function(x) {
  x <- toupper(as.character(x))
  x[is.na(x)] <- ""
  gsub("[^A-Z0-9]", "", x)
}

split_config_values <- function(x) {
  x <- trimws(as.character(x %||% ""))
  if (!nzchar(x)) return(character())
  out <- unlist(strsplit(x, "[,;]", perl = TRUE), use.names = FALSE)
  out <- trimws(out)
  out[nzchar(out)]
}

empty_npu_detective_code_inventory <- function() {
  empty_df(
    table_name = character(), code_column = character(), npu_code = character(),
    dictionary_match = logical(), consensus_vector = character(), clinical_role = character(),
    system = character(), status_labterm = character(), surface = character(),
    candidate_label = character(), n_observed = integer(), pct_rows = numeric()
  )
}

empty_npu_detective_candidates <- function() {
  empty_df(
    table_name = character(), code_column = character(), npu_code = character(),
    candidate_reason = character(), dictionary_match = logical(), surface = character(),
    candidate_label = character(), n_observed = integer(), pct_rows = numeric()
  )
}

empty_npu_detective_source_year <- function() {
  empty_df(
    table_name = character(), code_column = character(), year_column = character(),
    year = integer(), npu_code = character(), consensus_vector = character(),
    surface = character(), n_observed = integer(), pct_rows = numeric()
  )
}

empty_isotype_code_usage <- function() {
  empty_df(
    table_name = character(), code_column = character(), npu_code = character(),
    consensus_vector = character(), isotype_family = character(), specimen_class = character(),
    bucket = character(), n_observed = integer(), pct_rows = numeric()
  )
}

empty_isotype_bucket_summary <- function() {
  empty_df(
    table_name = character(), bucket = character(), isotype_family = character(),
    specimen_class = character(), n_rows = integer(), pct_rows = numeric(),
    n_patients = integer()
  )
}

empty_mm_treatment_code_counts <- function() {
  empty_df(
    table_name = character(), code_column = character(), code_system = character(),
    family = character(), match_type = character(), code = character(), label = character(),
    n_rows = integer(), pct_rows = numeric(), n_patients = integer()
  )
}

empty_mm_treatment_source_summary <- function() {
  empty_df(
    table_name = character(), n_rows_scanned = integer(), matched_rows = integer(),
    pct_rows_matched = numeric(), matched_patients = integer(), min_date = character(),
    max_date = character()
  )
}

surface_lookup_from_dictionary <- function(dictionary, surfaces) {
  if (is.null(dictionary) || !nrow(dictionary) || is.null(surfaces) || !nrow(surfaces)) {
    return(empty_df(npu_code = character(), surface = character(), candidate_label = character()))
  }
  rows <- lapply(seq_len(nrow(surfaces)), function(i) {
    surface <- surfaces[i, , drop = FALSE]
    vectors <- split_config_values(surface$consensus_vectors[[1]])
    dict_rows <- dictionary[dictionary$consensus_vector %in% vectors, , drop = FALSE]
    include <- split_config_values(surface$system_include[[1]])
    exclude <- split_config_values(surface$system_exclude[[1]])
    if (length(include)) dict_rows <- dict_rows[dict_rows$system %in% include, , drop = FALSE]
    if (length(exclude)) dict_rows <- dict_rows[!dict_rows$system %in% exclude, , drop = FALSE]
    if (!nrow(dict_rows)) return(empty_df(npu_code = character(), surface = character(), candidate_label = character()))
    data.frame(
      npu_code = dict_rows$npu_code,
      surface = surface$surface[[1]],
      candidate_label = surface$candidate_label[[1]],
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_df(npu_code = character(), surface = character(), candidate_label = character()))
  out[!duplicated(out$npu_code), , drop = FALSE]
}

npu_detective_inventory_from_counts <- function(counts, table_name, code_column, denom, dictionary,
                                                surfaces, min_cell_count = atlas_min_cell_count()) {
  if (is.null(counts) || !nrow(counts)) return(empty_npu_detective_code_inventory())
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  counts <- counts[counts$n_observed >= min_cell_count, , drop = FALSE]
  if (!nrow(counts)) return(empty_npu_detective_code_inventory())
  if (is.null(dictionary)) dictionary <- empty_df(
    npu_code = character(), consensus_vector = character(), system = character(),
    status_labterm = character(), clinical_role = character()
  )
  match_idx <- match(counts$npu_code, dictionary$npu_code)
  surface_lookup <- surface_lookup_from_dictionary(dictionary, surfaces)
  surface_idx <- match(counts$npu_code, surface_lookup$npu_code)
  data.frame(
    table_name = table_name,
    code_column = code_column %||% "",
    npu_code = counts$npu_code,
    dictionary_match = !is.na(match_idx),
    consensus_vector = ifelse(is.na(match_idx), "", dictionary$consensus_vector[match_idx]),
    clinical_role = ifelse(is.na(match_idx), "", dictionary$clinical_role[match_idx]),
    system = ifelse(is.na(match_idx), "", dictionary$system[match_idx]),
    status_labterm = ifelse(is.na(match_idx), "", dictionary$status_labterm[match_idx]),
    surface = ifelse(is.na(surface_idx), "", surface_lookup$surface[surface_idx]),
    candidate_label = ifelse(is.na(surface_idx), "", surface_lookup$candidate_label[surface_idx]),
    n_observed = counts$n_observed,
    pct_rows = vapply(counts$n_observed, safe_pct, numeric(1), denom = denom),
    stringsAsFactors = FALSE
  )
}

npu_detective_candidates_from_counts <- function(counts, table_name, code_column, denom, dictionary,
                                                surfaces, min_cell_count = atlas_min_cell_count()) {
  inventory <- npu_detective_inventory_from_counts(
    counts, table_name, code_column, denom, dictionary, surfaces, min_cell_count = min_cell_count
  )
  if (!nrow(inventory)) return(empty_npu_detective_candidates())
  candidate <- !as.logical(inventory$dictionary_match) | !nzchar(inventory$surface)
  out <- inventory[candidate, , drop = FALSE]
  if (!nrow(out)) return(empty_npu_detective_candidates())
  data.frame(
    table_name = out$table_name,
    code_column = out$code_column,
    npu_code = out$npu_code,
    candidate_reason = ifelse(out$dictionary_match, "dictionary_code_outside_detective_surface", "unmatched_npu_like_code"),
    dictionary_match = out$dictionary_match,
    surface = out$surface,
    candidate_label = out$candidate_label,
    n_observed = out$n_observed,
    pct_rows = out$pct_rows,
    stringsAsFactors = FALSE
  )
}

panel_npu_detective_code_inventory <- function(data, table_name, dictionary, surfaces,
                                               min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_npu_detective_code_inventory())
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = 1L)
  npu_detective_inventory_from_counts(counts, table_name, code_col, nrow(data), dictionary, surfaces, min_cell_count)
}

panel_npu_detective_candidates <- function(data, table_name, dictionary, surfaces,
                                           min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_npu_detective_candidates())
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = 1L)
  npu_detective_candidates_from_counts(counts, table_name, code_col, nrow(data), dictionary, surfaces, min_cell_count)
}

panel_npu_detective_source_year <- function(data, table_name, dictionary, surfaces,
                                            min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_npu_detective_source_year())
  date_col <- guess_date_column(data)
  if (is.na(date_col) || !date_col %in% names(data)) return(empty_npu_detective_source_year())
  codes <- normalize_npu_code(data[[code_col]])
  years <- suppressWarnings(as.integer(format(safe_as_date(data[[date_col]]), "%Y")))
  ok <- !is.na(codes) & nzchar(codes) & !is.na(years)
  if (!any(ok)) return(empty_npu_detective_source_year())
  keys <- paste(years[ok], codes[ok], sep = "\r")
  tab <- sort(table(keys), decreasing = TRUE)
  tab <- tab[as.integer(tab) >= normalize_min_cell_count(min_cell_count)]
  if (!length(tab)) return(empty_npu_detective_source_year())
  parts <- strsplit(names(tab), "\r", fixed = TRUE)
  counts <- data.frame(
    year = as.integer(vapply(parts, `[`, character(1), 1L)),
    npu_code = vapply(parts, `[`, character(1), 2L),
    n_observed = as.integer(tab),
    stringsAsFactors = FALSE
  )
  inv <- npu_detective_inventory_from_counts(
    counts = data.frame(npu_code = counts$npu_code, n_observed = counts$n_observed, stringsAsFactors = FALSE),
    table_name = table_name,
    code_column = code_col,
    denom = nrow(data),
    dictionary = dictionary,
    surfaces = surfaces,
    min_cell_count = min_cell_count
  )
  if (!nrow(inv)) return(empty_npu_detective_source_year())
  data.frame(
    table_name = table_name,
    code_column = code_col,
    year_column = date_col,
    year = counts$year,
    npu_code = counts$npu_code,
    consensus_vector = inv$consensus_vector[match(counts$npu_code, inv$npu_code)],
    surface = inv$surface[match(counts$npu_code, inv$npu_code)],
    n_observed = counts$n_observed,
    pct_rows = vapply(counts$n_observed, safe_pct, numeric(1), denom = nrow(data)),
    stringsAsFactors = FALSE
  )
}

isotype_code_usage_from_counts <- function(counts, table_name, code_column, denom, isotype_vectors,
                                           min_cell_count = atlas_min_cell_count()) {
  if (is.null(counts) || !nrow(counts) || is.null(isotype_vectors) || !nrow(isotype_vectors)) {
    return(empty_isotype_code_usage())
  }
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  counts <- counts[counts$n_observed >= min_cell_count, , drop = FALSE]
  if (!nrow(counts)) return(empty_isotype_code_usage())
  idx <- match(counts$npu_code, isotype_vectors$npu_code)
  matched <- counts[!is.na(idx), , drop = FALSE]
  matched_vectors <- isotype_vectors[idx[!is.na(idx)], , drop = FALSE]
  if (!nrow(matched)) return(empty_isotype_code_usage())
  data.frame(
    table_name = table_name,
    code_column = code_column %||% "",
    npu_code = matched$npu_code,
    consensus_vector = matched_vectors$consensus_vector,
    isotype_family = matched_vectors$isotype_family,
    specimen_class = matched_vectors$specimen_class,
    bucket = matched_vectors$bucket,
    n_observed = matched$n_observed,
    pct_rows = vapply(matched$n_observed, safe_pct, numeric(1), denom = denom),
    stringsAsFactors = FALSE
  )
}

isotype_bucket_summary_from_usage <- function(usage, table_name, denom, min_cell_count = atlas_min_cell_count(),
                                             patient_counts = NULL) {
  if (is.null(usage) || !nrow(usage)) return(empty_isotype_bucket_summary())
  key <- paste(usage$bucket, usage$isotype_family, usage$specimen_class, sep = "\r")
  rows <- lapply(unique(key), function(k) {
    ix <- key == k
    n_rows <- sum(suppressWarnings(as.integer(usage$n_observed[ix])), na.rm = TRUE)
    if (is.na(n_rows) || n_rows < normalize_min_cell_count(min_cell_count)) return(empty_isotype_bucket_summary())
    pieces <- strsplit(k, "\r", fixed = TRUE)[[1]]
    patient_count <- NA_integer_
    if (!is.null(patient_counts) && k %in% names(patient_counts)) {
      patient_count <- suppressWarnings(as.integer(patient_counts[[k]]))
      if (!is.na(patient_count) && patient_count < normalize_min_cell_count(min_cell_count)) patient_count <- NA_integer_
    }
    data.frame(
      table_name = table_name,
      bucket = pieces[[1]],
      isotype_family = pieces[[2]],
      specimen_class = pieces[[3]],
      n_rows = as.integer(n_rows),
      pct_rows = safe_pct(n_rows, denom),
      n_patients = patient_count,
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_isotype_bucket_summary())
  out[order(-out$n_rows, out$bucket, out$isotype_family), , drop = FALSE]
}

panel_isotype_code_usage <- function(data, table_name, isotype_vectors, min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_isotype_code_usage())
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = 1L)
  isotype_code_usage_from_counts(counts, table_name, code_col, nrow(data), isotype_vectors, min_cell_count)
}

panel_isotype_bucket_summary <- function(data, table_name, isotype_vectors, min_cell_count = atlas_min_cell_count()) {
  usage <- panel_isotype_code_usage(data, table_name, isotype_vectors, min_cell_count = min_cell_count)
  isotype_bucket_summary_from_usage(usage, table_name, nrow(data), min_cell_count = min_cell_count)
}

treatment_code_column_candidates <- function(data) {
  if (!ncol(data)) return(character())
  patterns <- paste(
    c(
      "procedurekode", "\\bc_opr\\b", "\\batc\\b", "atc5", "medicine", "medicin",
      "medication", "laegemiddel", "behandling", "treatment", "procedure", "kode$",
      "code$", "plan"
    ),
    collapse = "|"
  )
  hits <- names(data)[grepl(patterns, names(data), ignore.case = TRUE)]
  hits[!vapply(hits, is_sensitive_column, logical(1))]
}

likely_treatment_source <- function(table_name) {
  grepl(
    paste(c("procedur", "sks", "medicin", "medicine", "behandling", "treatment", "plan", "epikur", "indberetning"), collapse = "|"),
    table_name,
    ignore.case = TRUE
  )
}

rule_matches_values <- function(values, rule) {
  values <- normalize_generic_code(values)
  code <- normalize_generic_code(rule$code[[1]])
  values[is.na(values)] <- ""
  if (identical(rule$match_type[[1]], "prefix")) {
    startsWith(values, code) & nzchar(values)
  } else {
    values == code & nzchar(values)
  }
}

panel_mm_treatment_code_counts <- function(data, table_name, treatment_families,
                                           min_cell_count = atlas_min_cell_count()) {
  if (is.null(treatment_families) || !nrow(treatment_families) || !likely_treatment_source(table_name)) {
    return(empty_mm_treatment_code_counts())
  }
  code_cols <- treatment_code_column_candidates(data)
  if (!length(code_cols)) return(empty_mm_treatment_code_counts())
  id_col <- guess_id_column(data)
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  rows <- list()
  for (code_col in code_cols) {
    values <- data[[code_col]]
    for (i in seq_len(nrow(treatment_families))) {
      rule <- treatment_families[i, , drop = FALSE]
      matched <- rule_matches_values(values, rule)
      n_rows <- sum(matched, na.rm = TRUE)
      if (is.na(n_rows) || n_rows < min_cell_count) next
      n_patients <- NA_integer_
      if (!is.na(id_col) && id_col %in% names(data)) {
        n_patients <- length(unique(data[[id_col]][matched & !(is.na(data[[id_col]]) | trimws(as.character(data[[id_col]])) == "")]))
        if (!is.na(n_patients) && n_patients < min_cell_count) n_patients <- NA_integer_
      }
      rows[[length(rows) + 1L]] <- data.frame(
        table_name = table_name,
        code_column = code_col,
        code_system = rule$code_system[[1]],
        family = rule$family[[1]],
        match_type = rule$match_type[[1]],
        code = rule$code[[1]],
        label = rule$label[[1]],
        n_rows = as.integer(n_rows),
        pct_rows = safe_pct(n_rows, nrow(data)),
        n_patients = n_patients,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_mm_treatment_code_counts())
  out[order(-out$n_rows, out$table_name, out$family, out$code), , drop = FALSE]
}

panel_mm_treatment_source_summary <- function(data, table_name, treatment_families,
                                              min_cell_count = atlas_min_cell_count()) {
  if (is.null(treatment_families) || !nrow(treatment_families) || !likely_treatment_source(table_name)) {
    return(empty_mm_treatment_source_summary())
  }
  code_cols <- treatment_code_column_candidates(data)
  if (!length(code_cols)) return(empty_mm_treatment_source_summary())
  matched_any <- rep(FALSE, nrow(data))
  for (code_col in code_cols) {
    for (i in seq_len(nrow(treatment_families))) {
      matched_any <- matched_any | rule_matches_values(data[[code_col]], treatment_families[i, , drop = FALSE])
    }
  }
  matched_rows <- sum(matched_any, na.rm = TRUE)
  if (is.na(matched_rows) || matched_rows < normalize_min_cell_count(min_cell_count)) {
    return(empty_mm_treatment_source_summary())
  }
  id_col <- guess_id_column(data)
  matched_patients <- NA_integer_
  if (!is.na(id_col) && id_col %in% names(data)) {
    matched_patients <- length(unique(data[[id_col]][matched_any & !(is.na(data[[id_col]]) | trimws(as.character(data[[id_col]])) == "")]))
    if (!is.na(matched_patients) && matched_patients < normalize_min_cell_count(min_cell_count)) matched_patients <- NA_integer_
  }
  date_col <- guess_date_column(data)
  min_date <- max_date <- NA_character_
  if (!is.na(date_col) && date_col %in% names(data)) {
    dates <- safe_as_date(data[[date_col]][matched_any])
    dates <- dates[!is.na(dates)]
    if (length(dates)) {
      min_date <- as.character(min(dates))
      max_date <- as.character(max(dates))
    }
  }
  data.frame(
    table_name = table_name,
    n_rows_scanned = nrow(data),
    matched_rows = as.integer(matched_rows),
    pct_rows_matched = safe_pct(matched_rows, nrow(data)),
    matched_patients = matched_patients,
    min_date = min_date,
    max_date = max_date,
    stringsAsFactors = FALSE
  )
}
