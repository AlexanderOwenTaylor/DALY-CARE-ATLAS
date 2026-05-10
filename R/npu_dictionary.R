npu_dictionary_required_columns <- function() {
  c(
    "Code", "Consensus vector", "System", "Status (LabTerm)", "Clinical role",
    "Used in V08 classification", "Vector consensus basis", "Resolution note"
  )
}

npu_dictionary_path <- function(project_root = ".") {
  path <- system.file("config", "npu-consensus-dictionary.tsv", package = "dalycareatlas")
  if (nzchar(path) && file.exists(path)) return(path)
  file.path(project_root, "config", "npu-consensus-dictionary.tsv")
}

load_npu_consensus_dictionary <- function(project_root = ".", path = npu_dictionary_path(project_root)) {
  if (!file.exists(path)) {
    stop("NPU consensus dictionary not found: ", path, call. = FALSE)
  }
  raw <- read_delimited_file(path)
  missing <- setdiff(npu_dictionary_required_columns(), names(raw))
  if (length(missing)) {
    stop("NPU consensus dictionary missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  dictionary_code <- normalize_npu_code(raw[["Code"]])
  fallback_code <- toupper(gsub("[^A-Z0-9]", "", as.character(raw[["Code"]])))
  missing_code <- is.na(dictionary_code) | !nzchar(dictionary_code)
  dictionary_code[missing_code] <- fallback_code[missing_code]
  out <- data.frame(
    npu_code = dictionary_code,
    consensus_vector = trimws(as.character(raw[["Consensus vector"]])),
    system = trimws(as.character(raw[["System"]])),
    status_labterm = trimws(as.character(raw[["Status (LabTerm)"]])),
    clinical_role = trimws(as.character(raw[["Clinical role"]])),
    used_in_v08_classification = trimws(as.character(raw[["Used in V08 classification"]])),
    vector_consensus_basis = trimws(as.character(raw[["Vector consensus basis"]])),
    resolution_note = trimws(as.character(raw[["Resolution note"]])),
    stringsAsFactors = FALSE
  )
  out[] <- lapply(out, function(x) {
    x[is.na(x)] <- ""
    x
  })
  validate_npu_dictionary(out)
  out
}

validate_npu_dictionary <- function(dictionary) {
  required <- c(
    "npu_code", "consensus_vector", "system", "status_labterm", "clinical_role",
    "used_in_v08_classification", "vector_consensus_basis", "resolution_note"
  )
  missing <- setdiff(required, names(dictionary))
  if (length(missing)) {
    stop("Normalized NPU dictionary missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  blank_codes <- is.na(dictionary$npu_code) | !nzchar(dictionary$npu_code)
  if (any(blank_codes)) {
    stop("NPU consensus dictionary contains blank or invalid NPU codes.", call. = FALSE)
  }
  duplicated_codes <- unique(dictionary$npu_code[duplicated(dictionary$npu_code)])
  if (length(duplicated_codes)) {
    stop("NPU consensus dictionary contains duplicate NPU codes: ", paste(duplicated_codes, collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

normalize_npu_code <- function(x) {
  x <- toupper(as.character(x))
  x[is.na(x)] <- ""
  hit <- regexpr("NPU[[:space:]_-]*[0-9]+", x, perl = TRUE)
  out <- rep(NA_character_, length(x))
  matched <- hit > 0
  out[matched] <- regmatches(x, hit)
  out <- gsub("[^A-Z0-9]", "", out)
  out[!nzchar(out)] <- NA_character_
  out
}

npu_code_column <- function(data) {
  if (!ncol(data)) return(NA_character_)
  patterns <- c(
    "^npu$", "npu.*code", "npu.*kode", "analysis.*code", "analyse.*kode",
    "analysekode", "analysiscode", "^component$", "component.*code",
    "^komponent$", "komponent.*kode", "komponentkode", "^code$", "^kode$",
    "lab.*code", "lab.*kode", "svar.*kode"
  )
  hits <- names(data)[Reduce(`|`, lapply(patterns, function(p) grepl(p, names(data), ignore.case = TRUE)))]
  if (!length(hits)) return(NA_character_)
  for (nm in hits) {
    if (any(!is.na(normalize_npu_code(data[[nm]])))) return(nm)
  }
  NA_character_
}

npu_code_column_from_names <- function(column_names) {
  if (!length(column_names)) return(NA_character_)
  fake <- stats::setNames(as.list(rep("NPU00000", length(column_names))), column_names)
  npu_code_column(as.data.frame(fake, stringsAsFactors = FALSE))
}

empty_npu_dictionary_summary <- function() {
  empty_df(metric = character(), label = character(), value = character())
}

empty_npu_dictionary_vectors <- function() {
  empty_df(
    consensus_vector = character(), n_dictionary_codes = integer(),
    systems = character(), n_systems = integer(), n_active = integer(),
    n_with_clinical_role = integer(), n_v08_sources = integer(),
    clinical_roles = character()
  )
}

empty_npu_lab_usage_by_vector <- function() {
  empty_df(
    table_name = character(), code_column = character(), consensus_vector = character(),
    clinical_role = character(), n_observed = integer(), pct_rows = numeric(),
    n_codes_observed = integer(), n_dictionary_codes = integer()
  )
}

empty_npu_lab_unmatched_codes <- function() {
  empty_df(
    table_name = character(), code_column = character(), npu_code = character(),
    n_observed = integer(), pct_rows = numeric()
  )
}

panel_npu_dictionary_summary <- function(dictionary) {
  if (is.null(dictionary) || !nrow(dictionary)) return(empty_npu_dictionary_summary())
  rows <- list(
    npu_summary_row("dictionary_codes", "Dictionary NPU codes", nrow(dictionary)),
    npu_summary_row("consensus_vectors", "Consensus vectors", length(unique_nonblank(dictionary$consensus_vector))),
    npu_summary_row("systems", "Systems represented", length(unique_nonblank(dictionary$system))),
    npu_summary_row("active_codes", "Active LabTerm codes", sum(tolower(dictionary$status_labterm) == "active", na.rm = TRUE)),
    npu_summary_row("blank_status_codes", "Codes with blank LabTerm status", sum(!nzchar(dictionary$status_labterm), na.rm = TRUE)),
    npu_summary_row("clinical_role_codes", "Codes with clinical role", sum(nzchar(dictionary$clinical_role), na.rm = TRUE)),
    npu_summary_row("v08_sources", "V08 classification source labels", length(unique_nonblank(dictionary$used_in_v08_classification)))
  )
  bind_rows_base(rows)
}

npu_summary_row <- function(metric, label, value) {
  data.frame(metric = metric, label = label, value = as.character(value), stringsAsFactors = FALSE)
}

panel_npu_dictionary_vectors <- function(dictionary) {
  if (is.null(dictionary) || !nrow(dictionary)) return(empty_npu_dictionary_vectors())
  vectors <- unique_nonblank(dictionary$consensus_vector)
  rows <- lapply(vectors, function(vector) {
    rows <- dictionary[dictionary$consensus_vector == vector, , drop = FALSE]
    data.frame(
      consensus_vector = vector,
      n_dictionary_codes = nrow(rows),
      systems = paste(unique_nonblank(rows$system), collapse = ", "),
      n_systems = length(unique_nonblank(rows$system)),
      n_active = sum(tolower(rows$status_labterm) == "active", na.rm = TRUE),
      n_with_clinical_role = sum(nzchar(rows$clinical_role), na.rm = TRUE),
      n_v08_sources = length(unique_nonblank(rows$used_in_v08_classification)),
      clinical_roles = paste(unique_nonblank(rows$clinical_role), collapse = "; "),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  out[order(-out$n_dictionary_codes, out$consensus_vector), , drop = FALSE]
}

npu_counts_from_values <- function(values, denom, min_cell_count = atlas_min_cell_count()) {
  codes <- normalize_npu_code(values)
  codes <- codes[!is.na(codes) & nzchar(codes)]
  if (!length(codes)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  tab <- sort(table(codes), decreasing = TRUE)
  tab <- tab[as.integer(tab) >= normalize_min_cell_count(min_cell_count)]
  if (!length(tab)) return(empty_df(npu_code = character(), n_observed = integer(), pct_rows = numeric()))
  data.frame(
    npu_code = names(tab),
    n_observed = as.integer(tab),
    pct_rows = vapply(as.integer(tab), safe_pct, numeric(1), denom = denom),
    stringsAsFactors = FALSE
  )
}

npu_lab_code_coverage_from_counts <- function(counts, table_name, code_column,
                                              min_cell_count = atlas_min_cell_count()) {
  if (!nrow(counts)) {
    return(empty_df(table_name = character(), code_column = character(), lab_code = character(), n = integer(), pct_rows = numeric()))
  }
  counts <- counts[counts$n_observed >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(counts)) {
    return(empty_df(table_name = character(), code_column = character(), lab_code = character(), n = integer(), pct_rows = numeric()))
  }
  data.frame(
    table_name = table_name,
    code_column = code_column,
    lab_code = counts$npu_code,
    n = counts$n_observed,
    pct_rows = counts$pct_rows,
    stringsAsFactors = FALSE
  )
}

panel_npu_lab_usage_by_vector <- function(data, table_name, dictionary,
                                          min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_npu_lab_usage_by_vector())
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = 1L)
  npu_lab_usage_from_counts(
    counts = counts,
    table_name = table_name,
    code_column = code_col,
    denom = nrow(data),
    dictionary = dictionary,
    min_cell_count = min_cell_count
  )
}

npu_lab_usage_from_counts <- function(counts, table_name, code_column, denom, dictionary,
                                      min_cell_count = atlas_min_cell_count()) {
  if (is.null(dictionary) || !nrow(dictionary) || !nrow(counts)) return(empty_npu_lab_usage_by_vector())
  match_idx <- match(counts$npu_code, dictionary$npu_code)
  matched <- counts[!is.na(match_idx), , drop = FALSE]
  matched_dict <- dictionary[match_idx[!is.na(match_idx)], , drop = FALSE]
  if (!nrow(matched)) return(empty_npu_lab_usage_by_vector())
  matched$consensus_vector <- matched_dict$consensus_vector
  min_cell_count <- normalize_min_cell_count(min_cell_count)
  vectors <- unique_nonblank(matched$consensus_vector)
  vector_panel <- panel_npu_dictionary_vectors(dictionary)
  rows <- lapply(vectors, function(vector) {
    ix <- matched$consensus_vector == vector
    dict_rows <- dictionary[dictionary$consensus_vector == vector, , drop = FALSE]
    observed <- sum(matched$n_observed[ix], na.rm = TRUE)
    if (is.na(observed) || observed < min_cell_count) return(empty_npu_lab_usage_by_vector())
    data.frame(
      table_name = table_name,
      code_column = code_column,
      consensus_vector = vector,
      clinical_role = paste(unique_nonblank(dict_rows$clinical_role), collapse = "; "),
      n_observed = as.integer(observed),
      pct_rows = safe_pct(observed, denom),
      n_codes_observed = length(unique(matched$npu_code[ix])),
      n_dictionary_codes = vector_panel$n_dictionary_codes[match(vector, vector_panel$consensus_vector)] %||% nrow(dict_rows),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_npu_lab_usage_by_vector())
  out[order(-out$n_observed, out$consensus_vector), , drop = FALSE]
}

panel_npu_lab_unmatched_codes <- function(data, table_name, dictionary,
                                          min_cell_count = atlas_min_cell_count()) {
  code_col <- npu_code_column(data)
  if (is.na(code_col)) return(empty_npu_lab_unmatched_codes())
  counts <- npu_counts_from_values(data[[code_col]], denom = nrow(data), min_cell_count = 1L)
  npu_lab_unmatched_from_counts(
    counts = counts,
    table_name = table_name,
    code_column = code_col,
    denom = nrow(data),
    dictionary = dictionary,
    min_cell_count = min_cell_count
  )
}

npu_lab_unmatched_from_counts <- function(counts, table_name, code_column, denom, dictionary,
                                          min_cell_count = atlas_min_cell_count()) {
  if (!nrow(counts)) return(empty_npu_lab_unmatched_codes())
  known <- if (is.null(dictionary) || !nrow(dictionary)) character() else dictionary$npu_code
  out <- counts[!counts$npu_code %in% known, , drop = FALSE]
  if (!nrow(out)) return(empty_npu_lab_unmatched_codes())
  out <- out[out$n_observed >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(out)) return(empty_npu_lab_unmatched_codes())
  data.frame(
    table_name = table_name,
    code_column = code_column,
    npu_code = out$npu_code,
    n_observed = out$n_observed,
    pct_rows = vapply(out$n_observed, safe_pct, numeric(1), denom = denom),
    stringsAsFactors = FALSE
  )
}
