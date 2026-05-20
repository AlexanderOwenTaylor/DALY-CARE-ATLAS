ki67_empty_search_inventory <- function() {
  empty_df(
    artifact_or_source = character(),
    file_or_table = character(),
    resource_id = character(),
    source_domain = character(),
    matched_term = character(),
    matched_field_or_column = character(),
    matched_value_example_redacted = character(),
    evidence_type = character(),
    evidence_strength = character(),
    concept_interpretation = character(),
    candidate_numeric_value_available = logical(),
    candidate_unit_available = logical(),
    value_class = character(),
    requires_text_mining = logical(),
    requires_codebook_lookup = logical(),
    requires_manual_validation = logical(),
    privacy_safe_to_display = logical(),
    display_in_ui = logical(),
    ui_group = character(),
    ui_priority = integer(),
    suppression_reason = character(),
    evidence_channel = character(),
    notes = character()
  )
}

ki67_empty_registry_field_candidates <- function() {
  empty_df(
    resource_id = character(),
    table_or_file = character(),
    field_name = character(),
    field_label = character(),
    field_description = character(),
    candidate_reason = character(),
    evidence_strength = character(),
    likely_value_type = character(),
    value_class = character(),
    notes = character()
  )
}

ki67_empty_pathology_code_candidates <- function() {
  empty_df(
    resource_id = character(),
    table_or_file = character(),
    code_system = character(),
    code = character(),
    code_label = character(),
    matched_term = character(),
    evidence_strength = character(),
    value_class = character(),
    is_observation_code = character(),
    is_value_code = logical(),
    requires_danish_snomed_lookup = logical(),
    mcl_triangle_high_risk_ki67_numeric = logical(),
    notes = character()
  )
}

ki67_empty_text_pattern_candidates <- function() {
  empty_df(
    resource_id = character(),
    table_or_file = character(),
    text_field = character(),
    pattern_name = character(),
    regex_pattern = character(),
    matched_count_if_available = character(),
    example_redacted_or_synthetic = character(),
    numeric_extraction_possible = logical(),
    unit_extraction_possible = logical(),
    value_class = character(),
    false_positive_risk = character(),
    notes = character()
  )
}

ki67_empty_channel_summary <- function() {
  empty_df(
    evidence_channel = character(),
    channel_label = character(),
    confirmed_hits = integer(),
    candidate_hits = integer(),
    status = character(),
    next_validation_action = character(),
    notes = character()
  )
}

ki67_empty_aeki_validation_plan <- function() {
  empty_df(
    validation_step = character(),
    resource_id = character(),
    candidate_table_or_source = character(),
    candidate_code_field = character(),
    candidate_value_field = character(),
    pattern = character(),
    safe_aggregate_output = character(),
    privacy_risk = character(),
    requires_db_access = logical(),
    expected_result = character(),
    notes = character()
  )
}

ki67_empty_aeki_code_counts <- function() {
  empty_df(
    resource_id = character(),
    source_table = character(),
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

ki67_empty_text_validation_plan <- function() {
  empty_df(
    validation_step = character(),
    resource_id = character(),
    candidate_text_field = character(),
    pattern_name = character(),
    regex_pattern = character(),
    safe_aggregate_output = character(),
    privacy_risk = character(),
    requires_db_access = logical(),
    expected_result = character(),
    notes = character()
  )
}

ki67_empty_payload <- function() {
  list(
    search_inventory = ki67_empty_search_inventory(),
    registry_field_candidates = ki67_empty_registry_field_candidates(),
    pathology_code_candidates = ki67_empty_pathology_code_candidates(),
    text_pattern_candidates = ki67_empty_text_pattern_candidates(),
    channel_summary = ki67_empty_channel_summary(),
    aeki_validation_plan = ki67_empty_aeki_validation_plan(),
    aeki_code_counts = ki67_empty_aeki_code_counts(),
    text_validation_plan = ki67_empty_text_validation_plan(),
    summary = empty_df(metric = character(), value = character(), notes = character())
  )
}

ki67_normalize <- function(x) {
  x <- tolower(as.character(x %||% ""))
  x <- gsub("\u00e6", "ae", x, fixed = TRUE)
  x <- gsub("\u00f8", "oe", x, fixed = TRUE)
  x <- gsub("\u00e5", "aa", x, fixed = TRUE)
  x <- gsub("\u00fc", "u", x, fixed = TRUE)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

ki67_term_catalog <- function() {
  c(
    "Ki-67", "Ki67", "KI67", "KI-67", "Ki 67",
    "MIB-1", "MIB1", "MIB 1",
    "proliferation index", "proliferative index", "proliferation marker",
    "percentage positive", "percent positive", "positive nuclei", "nuclei positive",
    "immunohistochemistry", "IHC",
    "proliferationsindeks", "proliferations index", "proliferations-index",
    "proliferationsmarkor", "proliferationsmarkør", "proliferationsmarker",
    "proliferationsaktivitet", "positivitet", "positive kerner", "cellekerner",
    "immunhistokemi", "immunhistokemisk", "farvning", "farvet",
    "1255078008", "1279926000"
  )
}

ki67_direct_terms <- function() {
  c(
    "Ki-67", "Ki67", "KI67", "KI-67", "Ki 67",
    "MIB-1", "MIB1", "MIB 1",
    "proliferation index", "proliferative index",
    "proliferationsindeks", "proliferations index", "proliferations-index",
    "1255078008", "1279926000"
  )
}

ki67_context_terms <- function() {
  c(
    "proliferation marker", "percentage positive", "percent positive",
    "positive nuclei", "nuclei positive", "immunohistochemistry", "IHC",
    "proliferationsmarkor", "proliferationsmarkør", "proliferationsmarker",
    "proliferationsaktivitet", "positivitet", "positive kerner", "cellekerner",
    "immunhistokemi", "immunhistokemisk", "farvning", "farvet"
  )
}

ki67_source_only_terms <- function() {
  c("pato", "patobank", "pathology", "patologi", "t_mikro", "t_konk", "lyfo", "rkkp_lyfo")
}

ki67_false_positive_source_only <- function(text) {
  norm <- ki67_normalize(text)
  microbiology <- grepl("\\b(microbiology|microbiologi|persimune|miba|culture|resistance|bacteria|virus|fungus)\\b", norm, perl = TRUE)
  microscopy <- grepl("\\b(microscopy|mikroskopi)\\b", norm, perl = TRUE)
  microbiology && microscopy
}

ki67_align_search_inventory <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(ki67_empty_search_inventory())
  template <- ki67_empty_search_inventory()
  missing <- setdiff(names(template), names(x))
  for (nm in missing) {
    x[[nm]] <- template[[nm]]
  }
  x[names(template)]
}

ki67_evidence_channel <- function(row) {
  text <- paste(row$artifact_or_source, row$file_or_table, row$resource_id, row$source_domain,
    row$matched_term, row$matched_field_or_column, row$evidence_type, row$evidence_strength,
    collapse = " "
  )
  norm <- ki67_normalize(text)
  if ((row$evidence_strength %||% "") == "source_only" || (row$evidence_type %||% "") == "source_only_not_evidence") {
    return("source_only_search_space")
  }
  if (grepl("aeki|fy5015|fy5016|m0901k|m0901l|snomed|patobank|pato|pathology|mikro|konk", norm, perl = TRUE) ||
      (row$evidence_type %||% "") %in% c("pathology_code", "external_code_reference", "code", "code_label")) {
    return("danish_pathology_code_evidence")
  }
  if (grepl("text|tekst|report|narrative|conclusion|konklusion|microscopy|mikroskopi", norm, perl = TRUE) ||
      (row$evidence_type %||% "") %in% c("free_text_pattern", "pathology_text_field")) {
    return("pathology_text_extraction_readiness")
  }
  if (grepl("lyfo|rkkp|registry|register", norm, perl = TRUE) ||
      (row$evidence_type %||% "") %in% c("column_name", "raw_column_profile", "registry_field", "dictionary_label", "value_label")) {
    return("structured_registry_fields")
  }
  "other_candidate"
}

ki67_apply_ui_metadata <- function(inventory, max_source_only_ui = 6L) {
  inventory <- ki67_align_search_inventory(inventory)
  if (!nrow(inventory)) return(inventory)

  inventory$evidence_channel <- vapply(seq_len(nrow(inventory)), function(i) {
    ki67_evidence_channel(inventory[i, , drop = FALSE])
  }, character(1))
  inventory$ui_group <- ifelse(nzchar(inventory$resource_id), inventory$resource_id,
    ifelse(nzchar(inventory$file_or_table), inventory$file_or_table, inventory$artifact_or_source)
  )
  inventory$ui_group <- ifelse(nzchar(inventory$ui_group), inventory$ui_group, "unknown")
  inventory$ui_priority <- ifelse(inventory$evidence_strength == "strong_direct", 10L,
    ifelse(inventory$evidence_strength == "moderate_direct", 20L,
      ifelse(inventory$evidence_strength == "weak_candidate", 40L,
        ifelse(inventory$evidence_strength == "source_only", 80L, 100L)
      )
    )
  )

  inventory$display_in_ui <- TRUE
  inventory$suppression_reason <- ""
  source_only <- inventory$evidence_channel == "source_only_search_space" |
    inventory$evidence_strength == "source_only" |
    inventory$evidence_type == "source_only_not_evidence"

  false_positive <- source_only & vapply(seq_len(nrow(inventory)), function(i) {
    ki67_false_positive_source_only(paste(inventory[i, c("resource_id", "file_or_table", "source_domain", "matched_term", "matched_field_or_column")], collapse = " "))
  }, logical(1))
  inventory$display_in_ui[false_positive] <- FALSE
  inventory$suppression_reason[false_positive] <- "false_positive_microbiology_microscopy"

  source_key <- paste(inventory$evidence_channel, inventory$ui_group, inventory$matched_term, inventory$matched_field_or_column, sep = "\r")
  dup <- source_only & duplicated(source_key)
  inventory$display_in_ui[dup] <- FALSE
  inventory$suppression_reason[dup] <- "duplicate_source_only_group"

  source_visible <- which(source_only & inventory$display_in_ui)
  if (length(source_visible) > max_source_only_ui) {
    ord <- source_visible[order(inventory$ui_priority[source_visible], inventory$ui_group[source_visible], inventory$matched_term[source_visible])]
    suppress <- setdiff(source_visible, head(ord, max_source_only_ui))
    inventory$display_in_ui[suppress] <- FALSE
    inventory$suppression_reason[suppress] <- "source_only_ui_limit"
  }

  ki67_align_search_inventory(inventory)
}

ki67_clean_code_text <- function(x) {
  x <- toupper(trimws(as.character(x %||% "")))
  x <- gsub("\u00c3\u2020", "AE", x, fixed = TRUE)
  x <- gsub("\u00c3\u2026", "AA", x, fixed = TRUE)
  x <- gsub("\u00c6", "AE", x, fixed = TRUE)
  x <- gsub("?KI", "AEKI", x, fixed = TRUE)
  x <- gsub("\u00d8", "OE", x, fixed = TRUE)
  x <- gsub("\u00c5", "AA", x, fixed = TRUE)
  x
}

ki67_patobank_numeric_code_match <- function(x) {
  clean <- ki67_clean_code_text(x)
  hit <- regexpr("AEKI([0-9]{3})", clean, perl = TRUE)
  if (hit[[1]] < 0) return(list(code = "", percent = NA_real_, valid = FALSE))
  code <- regmatches(clean, hit)[[1]]
  digits <- sub("^AEKI", "", code)
  pct <- suppressWarnings(as.numeric(digits))
  list(code = code, percent = pct, valid = !is.na(pct) && pct >= 0 && pct <= 100)
}

ki67_parse_patobank_numeric_percent <- function(code) {
  clean <- ki67_clean_code_text(code)
  if (!grepl("^AEKI[0-9]{3}$", clean, perl = TRUE)) return(NA_real_)
  hit <- ki67_patobank_numeric_code_match(clean)
  if (isTRUE(hit$valid)) hit$percent else NA_real_
}

ki67_dual_stain_code_map <- function() {
  data.frame(
    code = c("FY5015", "FY5016", "M0901K", "M0901L"),
    concept_interpretation = "p16_ki67_dual_stain_cervix_triage",
    value_class = c("qualitative_mention_only", "qualitative_mention_only", "unknown_or_not_stated", "test_failed_or_insufficient"),
    label = c(
      "p16/Ki-67-positive cells not detected",
      "p16/Ki-67-positive cells detected",
      "inconclusive p16/Ki-67 test",
      "too little material for p16/Ki-67"
    ),
    stringsAsFactors = FALSE
  )
}

ki67_dual_stain_code_info <- function(x) {
  clean <- ki67_clean_code_text(x)
  map <- ki67_dual_stain_code_map()
  idx <- which(vapply(map$code, function(code) grepl(paste0("\\b", code, "\\b"), clean, perl = TRUE), logical(1)))
  if (!length(idx)) return(NULL)
  map[idx[[1]], , drop = FALSE]
}

ki67_first_matching_term <- function(text, terms = ki67_term_catalog()) {
  norm <- ki67_normalize(text)
  term_norm <- ki67_normalize(terms)
  patterns <- paste0("\\b", gsub(" ", "\\\\s+", term_norm), "\\b")
  hit <- which(nzchar(term_norm) & vapply(patterns, function(pattern) grepl(pattern, norm, perl = TRUE), logical(1)))
  if (!length(hit)) return("")
  terms[[hit[[1]]]]
}

ki67_has_direct_term <- function(text) {
  nzchar(ki67_first_matching_term(text, ki67_direct_terms()))
}

ki67_has_context_term <- function(text) {
  nzchar(ki67_first_matching_term(text, ki67_context_terms()))
}

ki67_has_source_only_term <- function(text) {
  nzchar(ki67_first_matching_term(text, ki67_source_only_terms()))
}

ki67_term_regex <- function(terms) {
  term_norm <- ki67_normalize(terms)
  term_norm <- term_norm[nzchar(term_norm)]
  if (!length(term_norm)) return("$a")
  paste0("\\b(?:", paste(gsub(" ", "\\\\s+", term_norm), collapse = "|"), ")\\b")
}

ki67_percent_patterns <- function() {
  c(
    exact_numeric_percent = "(?i)\\b(?:ki[-\\s]?67|mib[-\\s]?1)\\b.{0,80}?(\\d{1,3}(?:[,.]\\d+)?)\\s*%",
    danish_numeric_percent = "(?i)\\bproliferations[-\\s]?indeks\\b.{0,80}?(\\d{1,3}(?:[,.]\\d+)?)\\s*%",
    range_percent = "(?i)\\b(?:ki[-\\s]?67|mib[-\\s]?1)\\b.{0,80}?(\\d{1,3})\\s*[-\u2013]\\s*(\\d{1,3})\\s*%",
    inequality_percent = "(?i)\\b(?:ki[-\\s]?67|mib[-\\s]?1)\\b.{0,80}?([<>≤≥])\\s*(\\d{1,3}(?:[,.]\\d+)?)\\s*%"
  )
}

ki67_extract_numbers <- function(x) {
  nums <- regmatches(x, gregexpr("\\d{1,4}(?:[,.]\\d+)?", x, perl = TRUE))[[1]]
  suppressWarnings(as.numeric(gsub(",", ".", nums, fixed = TRUE)))
}

ki67_values_in_percent_range <- function(x) {
  nums <- ki67_extract_numbers(x)
  length(nums) > 0 && all(!is.na(nums)) && all(nums >= 0 & nums <= 100)
}

ki67_classify_value <- function(text) {
  raw <- as.character(text %||% "")
  numeric_code <- ki67_patobank_numeric_code_match(raw)
  if (isTRUE(numeric_code$valid)) return("exact_numeric_percent")
  dual_code <- ki67_dual_stain_code_info(raw)
  if (is.data.frame(dual_code) && nrow(dual_code)) return(dual_code$value_class[[1]])
  norm <- ki67_normalize(raw)
  if (!ki67_has_direct_term(raw) && !grepl("\\bproliferations\\s*indeks\\b", norm)) {
    return("not_ki67")
  }
  if (grepl("\\b(ikke angivet|not stated|unknown|ukendt|not available|na)\\b", norm, perl = TRUE)) {
    return("unknown_or_not_stated")
  }
  pats <- ki67_percent_patterns()
  if (grepl(pats[["range_percent"]], raw, perl = TRUE)) {
    return(if (ki67_values_in_percent_range(raw)) "range_percent" else "uncertain")
  }
  if (grepl(pats[["inequality_percent"]], raw, perl = TRUE)) {
    return(if (ki67_values_in_percent_range(raw)) "inequality_percent" else "uncertain")
  }
  if (grepl(pats[["exact_numeric_percent"]], raw, perl = TRUE) || grepl(pats[["danish_numeric_percent"]], raw, perl = TRUE)) {
    return(if (ki67_values_in_percent_range(raw)) "exact_numeric_percent" else "uncertain")
  }
  if (grepl("\\b(positiv|positive|farvning|farvet|ihc|immunhistokemi|immunohistochemistry)\\b", norm, perl = TRUE)) {
    return("qualitative_mention_only")
  }
  "uncertain"
}

ki67_value_is_numeric_extractable <- function(value_class) {
  value_class %in% c("exact_numeric_percent", "range_percent", "inequality_percent")
}

ki67_evidence_type <- function(artifact, column_name, value_text = "") {
  numeric_code <- ki67_patobank_numeric_code_match(value_text)
  if (nzchar(numeric_code$code)) return("pathology_code")
  if (is.data.frame(ki67_dual_stain_code_info(value_text))) return("pathology_code")
  col <- ki67_normalize(column_name)
  artifact_norm <- ki67_normalize(artifact)
  value_norm <- ki67_normalize(value_text)
  if (grepl("code", artifact_norm) || grepl("\\b(code|raw code|code system|code name|snomed)\\b", col)) {
    if (grepl("\\b1255078008\\b|\\b1279926000\\b", value_norm)) return("external_code_reference")
    return(if (grepl("label|name|text|desc", col)) "code_label" else "code")
  }
  if (grepl("value", artifact_norm) || grepl("\\b(raw value|display value|value|label)\\b", col)) return("value_label")
  if (grepl("column|field|raw column|raw field", col) || grepl("column", artifact_norm)) return("raw_column_profile")
  if (grepl("semantic|dictionary|clinical", artifact_norm)) return("dictionary_label")
  if (grepl("panel", artifact_norm)) return("dictionary_label")
  if (grepl("source|catalog|profile", artifact_norm)) return("source_only_not_evidence")
  "dictionary_label"
}

ki67_evidence_strength <- function(evidence_type, haystack, value_class = "not_ki67") {
  numeric_code <- ki67_patobank_numeric_code_match(haystack)
  if (evidence_type == "pathology_code" && isTRUE(numeric_code$valid)) return("strong_direct")
  if (evidence_type == "pathology_code" && is.data.frame(ki67_dual_stain_code_info(haystack))) return("moderate_direct")
  if (evidence_type == "source_only_not_evidence") return("source_only")
  if (ki67_has_direct_term(haystack)) {
    if (evidence_type %in% c("code", "code_label", "external_code_reference")) return("strong_direct")
    if (evidence_type %in% c("column_name", "raw_column_profile", "dictionary_label", "registry_field", "value_label")) return("strong_direct")
    return("moderate_direct")
  }
  if (ki67_has_context_term(haystack)) return("weak_candidate")
  if (ki67_has_source_only_term(haystack)) return("source_only")
  if (value_class != "not_ki67") return("moderate_direct")
  "false_positive_likely"
}

ki67_resource_value <- function(row) {
  candidates <- c(
    "canonical_resource_id", "resource_id", "source_name", "source", "table_name",
    "object_name", "current_source_key", "evidence_source", "panel_id"
  )
  col <- intersect(candidates, names(row))
  if (!length(col)) return("")
  as.character(row[[col[[1]]]][[1]] %||% "")
}

ki67_domain_value <- function(row) {
  candidates <- c("domain", "source_domain", "clinical_group", "panel_section", "subdomain", "atlas_role")
  col <- intersect(candidates, names(row))
  if (!length(col)) return("")
  as.character(row[[col[[1]]]][[1]] %||% "")
}

ki67_file_table_value <- function(row, fallback = "") {
  candidates <- c("table_name", "object_name", "source_name", "source", "evidence_file", "current_source_key", "panel_id")
  col <- intersect(candidates, names(row))
  if (!length(col)) return(fallback)
  value <- as.character(row[[col[[1]]]][[1]] %||% "")
  if (nzchar(value)) value else fallback
}

ki67_scan_frame <- function(df, artifact_or_source, file_or_table = artifact_or_source, max_hits = 600L) {
  if (!is.data.frame(df) || !nrow(df)) return(ki67_empty_search_inventory())
  char_cols <- names(df)[vapply(df, function(x) is.character(x) || is.factor(x) || is.numeric(x) || is.logical(x), logical(1))]
  char_cols <- char_cols[!vapply(char_cols, is_sensitive_column, logical(1))]
  if (!length(char_cols)) return(ki67_empty_search_inventory())
  rows <- list()
  add_hit <- function(row, matched_text, column_name, evidence_type = NULL, source_only = FALSE) {
    value_class <- ki67_classify_value(matched_text)
    term <- ki67_first_matching_term(matched_text)
    numeric_code <- ki67_patobank_numeric_code_match(matched_text)
    dual_code <- ki67_dual_stain_code_info(matched_text)
    if (!nzchar(term) && nzchar(numeric_code$code)) term <- numeric_code$code
    if (!nzchar(term) && is.data.frame(dual_code) && nrow(dual_code)) term <- dual_code$code[[1]]
    if (!nzchar(term) && source_only) term <- ki67_first_matching_term(matched_text, ki67_source_only_terms())
    if (!nzchar(term)) return(NULL)
    etype <- evidence_type %||% ki67_evidence_type(artifact_or_source, column_name, matched_text)
    if (isTRUE(source_only)) etype <- "source_only_not_evidence"
    strength <- ki67_evidence_strength(etype, matched_text, value_class)
    if (strength == "false_positive_likely" && !source_only) return(NULL)
    data.frame(
      artifact_or_source = artifact_or_source,
      file_or_table = ki67_file_table_value(row, file_or_table),
      resource_id = ki67_resource_value(row),
      source_domain = ki67_domain_value(row),
      matched_term = term,
      matched_field_or_column = column_name,
      matched_value_example_redacted = if (value_class == "not_ki67") "" else paste("synthetic class:", value_class),
      evidence_type = etype,
      evidence_strength = strength,
      concept_interpretation = if (is.data.frame(dual_code) && nrow(dual_code)) dual_code$concept_interpretation[[1]] else if (nzchar(numeric_code$code)) "Danish Patobank local Ki-67 percent value code" else if (strength %in% c("strong_direct", "moderate_direct")) "candidate Ki-67 observation/test evidence" else if (strength == "source_only") "source search space only; not Ki-67 evidence" else "candidate requiring validation",
      candidate_numeric_value_available = ki67_value_is_numeric_extractable(value_class),
      candidate_unit_available = value_class %in% c("exact_numeric_percent", "range_percent", "inequality_percent"),
      value_class = value_class,
      requires_text_mining = etype %in% c("free_text_pattern", "pathology_text_field") || value_class %in% c("qualitative_mention_only", "unknown_or_not_stated"),
      requires_codebook_lookup = etype %in% c("code", "code_label", "external_code_reference"),
      requires_manual_validation = TRUE,
      privacy_safe_to_display = TRUE,
      display_in_ui = TRUE,
      ui_group = "",
      ui_priority = 100L,
      suppression_reason = "",
      evidence_channel = "",
      notes = if (is.data.frame(dual_code) && nrow(dual_code)) "p16/Ki-67 dual-stain cervix triage code; not numeric MCL Ki-67 proliferation index." else if (nzchar(numeric_code$code)) paste0("Danish Patobank Ki-67 code parsed as ", numeric_code$percent, "%. Validate local codebook before use.") else if (strength == "source_only") "Broad source availability is not direct Ki-67 evidence." else "Aggregate metadata hit; validate source-specific meaning before extraction.",
      stringsAsFactors = FALSE
    )
  }

  direct_re <- ki67_term_regex(ki67_direct_terms())
  context_re <- ki67_term_regex(ki67_context_terms())
  code_re <- "AEKI[0-9]{3}|FY5015|FY5016|M0901K|M0901L|1255078008|1279926000"
  likely_large_cols <- c("code", "raw_code", "code_name", "raw_value", "display_value", "value", "label", "name", "description", "column_name", "raw_column", "field_name", "clinical_variable", "source", "source_name", "table_name", "object_name")
  scan_cols <- char_cols
  if (nrow(df) > 100000L) {
    preferred <- char_cols[ki67_normalize(char_cols) %in% ki67_normalize(likely_large_cols) |
      grepl("code|value|label|name|desc|column|field|concept|source|table|object", char_cols, ignore.case = TRUE)]
    if (length(preferred)) scan_cols <- preferred
  }

  for (col in scan_cols) {
    values <- as.character(df[[col]] %||% "")
    values[is.na(values)] <- ""
    combined <- paste(col, values)
    norm <- ki67_normalize(combined)
    clean <- ki67_clean_code_text(combined)
    hit <- grepl(direct_re, norm, perl = TRUE) |
      grepl(context_re, norm, perl = TRUE) |
      grepl(code_re, clean, perl = TRUE)
    idx <- which(hit)
    if (length(idx)) {
      idx <- head(idx, max_hits - length(rows))
      for (i in idx) {
        rows[[length(rows) + 1L]] <- add_hit(df[i, , drop = FALSE], combined[[i]], col)
        if (length(rows) >= max_hits) break
      }
    }
    if (length(rows) >= max_hits) break
  }

  if (length(rows) < max_hits) {
    source_cols <- intersect(c("source_name", "source", "table_name", "object_name", "canonical_resource_id", "domain", "subdomain"), names(df))
    if (length(source_cols)) {
      source_frame <- unique(head(df[source_cols], 10000L))
      source_frame <- head(source_frame, max_hits)
      for (i in seq_len(nrow(source_frame))) {
        source_text <- paste(as.character(source_frame[i, , drop = TRUE]), collapse = " ")
        if (ki67_has_source_only_term(source_text) && !ki67_has_direct_term(source_text) && !ki67_false_positive_source_only(source_text)) {
          rows[[length(rows) + 1L]] <- add_hit(source_frame[i, , drop = FALSE], source_text, "source/resource name", source_only = TRUE)
        }
        if (length(rows) >= max_hits) break
      }
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(ki67_empty_search_inventory())
  out <- out[!duplicated(paste(out$artifact_or_source, out$file_or_table, out$resource_id, out$matched_term, out$matched_field_or_column, out$evidence_type, sep = "\r")), , drop = FALSE]
  ki67_apply_ui_metadata(out)
}

ki67_collect_reference_files <- function(project_root = ".", max_files = 80L, max_bytes = 2 * 1024 * 1024) {
  roots <- c(
    file.path(project_root, "config"),
    file.path(project_root, "inst", "legacy")
  )
  roots <- roots[dir.exists(roots)]
  if (!length(roots)) return(list())
  files <- unlist(lapply(roots, function(root) {
    list.files(
      root,
      pattern = "(columns|values|profile|dictionary|code|value|source|semantic|cartography|mcl|lyfo|pato|snomed).*[.](csv|tsv|txt|md|R|Rmd|qmd)$",
      recursive = TRUE,
      full.names = TRUE,
      ignore.case = TRUE
    )
  }), use.names = FALSE)
  files <- files[file.exists(files)]
  info <- file.info(files)
  files <- files[!is.na(info$size) & info$size <= max_bytes]
  files <- head(files, max_files)
  out <- list()
  for (path in files) {
    ext <- tolower(tools::file_ext(path))
    if (ext %in% c("csv", "tsv", "txt")) {
      df <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
    } else {
      lines <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"), error = function(e) character())
      df <- if (length(lines)) data.frame(line_no = seq_along(lines), text = lines, stringsAsFactors = FALSE) else data.frame(stringsAsFactors = FALSE)
    }
    if (nrow(df)) out[[relative_path(path, project_root)]] <- df
  }
  out
}

ki67_build_search_inventory <- function(frames = list(), project_root = ".", include_reference_files = TRUE) {
  frame_hits <- list()
  for (nm in names(frames)) {
    frame_hits[[length(frame_hits) + 1L]] <- ki67_scan_frame(frames[[nm]], artifact_or_source = nm, file_or_table = nm)
  }
  if (isTRUE(include_reference_files)) {
    refs <- ki67_collect_reference_files(project_root = project_root)
    for (nm in names(refs)) {
      frame_hits[[length(frame_hits) + 1L]] <- ki67_scan_frame(refs[[nm]], artifact_or_source = "legacy/reference file", file_or_table = nm, max_hits = 120L)
    }
  }
  out <- bind_rows_base(frame_hits)
  if (!nrow(out)) return(ki67_empty_search_inventory())
  ki67_apply_ui_metadata(out)
}

ki67_registry_candidates <- function(inventory) {
  if (!is.data.frame(inventory) || !nrow(inventory)) return(ki67_empty_registry_field_candidates())
  reg <- grepl("lyfo|rkkp|registry", paste(inventory$resource_id, inventory$file_or_table, inventory$source_domain), ignore.case = TRUE)
  keep <- reg & inventory$evidence_type %in% c("column_name", "dictionary_label", "raw_column_profile", "registry_field", "value_label", "source_only_not_evidence")
  x <- inventory[keep, , drop = FALSE]
  if (!nrow(x)) return(ki67_empty_registry_field_candidates())
  data.frame(
    resource_id = x$resource_id,
    table_or_file = x$file_or_table,
    field_name = x$matched_field_or_column,
    field_label = ifelse(x$evidence_strength == "source_only", "", x$matched_term),
    field_description = x$concept_interpretation,
    candidate_reason = x$notes,
    evidence_strength = x$evidence_strength,
    likely_value_type = ifelse(x$value_class == "exact_numeric_percent", "numeric_percent",
      ifelse(x$value_class == "range_percent", "categorical_range",
        ifelse(x$value_class == "inequality_percent", "inequality",
          ifelse(x$value_class == "unknown_or_not_stated", "unknown_code",
            ifelse(x$value_class == "qualitative_mention_only", "text_label", "not_clear")
          )
        )
      )
    ),
    value_class = x$value_class,
    notes = ifelse(x$evidence_strength == "source_only", "Registry/source only; not direct Ki-67 evidence.", "Validate registry codebook and value representation."),
    stringsAsFactors = FALSE
  )[names(ki67_empty_registry_field_candidates())]
}

ki67_pathology_code_candidates <- function(inventory) {
  rows <- list(
    data.frame(
      resource_id = "external_reference",
      table_or_file = "external SNOMED CT reference anchor",
      code_system = "SNOMED_CT",
      code = "1255078008",
      code_label = "Percent of cell nuclei positive for proliferation marker protein Ki-67 in primary malignant neoplasm by immunohistochemistry",
      matched_term = "1255078008",
      evidence_strength = "weak_candidate",
      value_class = "not_ki67",
      is_observation_code = "true",
      is_value_code = FALSE,
      requires_danish_snomed_lookup = TRUE,
      mcl_triangle_high_risk_ki67_numeric = FALSE,
      notes = "External reference anchor only; not proof of local Danish Patobank coding.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      resource_id = "external_reference",
      table_or_file = "external SNOMED CT site-specific example",
      code_system = "SNOMED_CT",
      code = "1279926000",
      code_label = "Site-specific Ki-67 percent positive example in thyroid malignant neoplasm by immunohistochemistry",
      matched_term = "1279926000",
      evidence_strength = "weak_candidate",
      value_class = "not_ki67",
      is_observation_code = "true",
      is_value_code = FALSE,
      requires_danish_snomed_lookup = TRUE,
      mcl_triangle_high_risk_ki67_numeric = FALSE,
      notes = "External reference anchor only; validate Danish pathology codes separately.",
      stringsAsFactors = FALSE
    )
  )
  if (is.data.frame(inventory) && nrow(inventory)) {
    path <- grepl("pato|patobank|pathology|t_mikro|t_konk|snomed|mikro|konk", paste(inventory$resource_id, inventory$file_or_table, inventory$source_domain), ignore.case = TRUE)
    code <- inventory$evidence_type %in% c("code", "code_label", "pathology_code", "external_code_reference", "value_label")
    x <- inventory[path & code, , drop = FALSE]
    if (nrow(x)) {
      numeric_codes <- lapply(paste(x$matched_term, x$file_or_table, x$matched_field_or_column), ki67_patobank_numeric_code_match)
      dual_codes <- lapply(paste(x$matched_term, x$file_or_table, x$matched_field_or_column), ki67_dual_stain_code_info)
      numeric_code_present <- vapply(numeric_codes, function(z) nzchar(z$code), logical(1))
      numeric_code_value <- vapply(numeric_codes, function(z) z$code, character(1))
      numeric_code_valid <- vapply(numeric_codes, function(z) isTRUE(z$valid), logical(1))
      dual_code_present <- vapply(dual_codes, is.data.frame, logical(1))
      dual_code_value <- vapply(dual_codes, function(z) if (is.data.frame(z) && nrow(z)) z$code[[1]] else "", character(1))
      dual_code_label <- vapply(dual_codes, function(z) if (is.data.frame(z) && nrow(z)) z$label[[1]] else "", character(1))
      rows[[length(rows) + 1L]] <- data.frame(
        resource_id = x$resource_id,
        table_or_file = x$file_or_table,
        code_system = ifelse(numeric_code_present, "Danish Patobank local pathology code",
          ifelse(grepl("snomed", paste(x$file_or_table, x$matched_field_or_column), ignore.case = TRUE), "Danish pathology/SNOMED candidate", "")
        ),
        code = ifelse(numeric_code_present, numeric_code_value,
          ifelse(dual_code_present, dual_code_value,
            ifelse(x$evidence_type %in% c("code", "external_code_reference", "pathology_code"), x$matched_term, "")
          )
        ),
        code_label = ifelse(dual_code_present, dual_code_label,
          ifelse(x$evidence_type %in% c("code_label", "value_label"), x$matched_term, "")
        ),
        matched_term = x$matched_term,
        evidence_strength = x$evidence_strength,
        value_class = x$value_class,
        is_observation_code = ifelse(numeric_code_present, "false_or_local_value_code", ifelse(x$evidence_strength %in% c("strong_direct", "moderate_direct"), "true", "false")),
        is_value_code = numeric_code_present,
        requires_danish_snomed_lookup = TRUE,
        mcl_triangle_high_risk_ki67_numeric = numeric_code_valid,
        notes = ifelse(dual_code_present, "p16/Ki-67 dual-stain cervix triage code; not numeric MCL Ki-67 proliferation index.",
          ifelse(numeric_code_present, "Danish Patobank Ki-67 percent value code; validate local codebook before study use.",
            ifelse(x$evidence_strength == "source_only", "Pathology/source only; not direct Ki-67 code evidence.", "Validate against Danish pathology/SNOMED codebook.")
          )
        ),
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  out[names(ki67_empty_pathology_code_candidates())]
}

ki67_text_pattern_candidates <- function(inventory) {
  patterns <- ki67_percent_patterns()
  base <- data.frame(
    resource_id = c("t_mikro", "t_konk", "pato", "pathology_text"),
    table_or_file = c("pathology text candidate", "pathology conclusion candidate", "pathology coded/text candidate", "pathology narrative candidate"),
    text_field = c("microscopy/conclusion text field", "conclusion text field", "report/narrative field", "pathology narrative field"),
    pattern_name = names(patterns),
    regex_pattern = unname(patterns),
    matched_count_if_available = "",
    example_redacted_or_synthetic = c("Ki-67 20%", "Ki-67 5-10%", "Ki-67 < 10%", "proliferationsindeks på 15%"),
    numeric_extraction_possible = TRUE,
    unit_extraction_possible = TRUE,
    value_class = names(patterns),
    false_positive_risk = c("medium", "medium", "medium", "medium"),
    notes = "Synthetic pattern only; do not emit real pathology report text in the atlas.",
    stringsAsFactors = FALSE
  )
  rows <- list(base)
  if (is.data.frame(inventory) && nrow(inventory)) {
    text_hit <- grepl("text|tekst|mikro|konklusion|conclusion|report|narrative|microscopy", paste(inventory$file_or_table, inventory$matched_field_or_column, inventory$resource_id), ignore.case = TRUE)
    path <- grepl("pato|pathology|t_mikro|t_konk|mikro|konk", paste(inventory$file_or_table, inventory$resource_id, inventory$source_domain), ignore.case = TRUE)
    x <- inventory[(text_hit | path) & inventory$evidence_strength %in% c("strong_direct", "moderate_direct", "weak_candidate", "source_only"), , drop = FALSE]
    if (nrow(x)) {
      rows[[length(rows) + 1L]] <- data.frame(
        resource_id = x$resource_id,
        table_or_file = x$file_or_table,
        text_field = x$matched_field_or_column,
        pattern_name = "candidate_field_for_ki67_text_mining",
        regex_pattern = patterns[["exact_numeric_percent"]],
        matched_count_if_available = "",
        example_redacted_or_synthetic = "Ki-67 20%",
        numeric_extraction_possible = x$evidence_strength != "source_only",
        unit_extraction_possible = x$evidence_strength != "source_only",
        value_class = ifelse(x$evidence_strength == "source_only", "uncertain", x$value_class),
        false_positive_risk = ifelse(x$evidence_strength == "source_only", "high", "medium"),
        notes = ifelse(x$evidence_strength == "source_only", "Text source search space only; requires source activation and validation.", "Candidate metadata hit; validate on redacted aggregate extraction output."),
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  out[!duplicated(paste(out$resource_id, out$table_or_file, out$text_field, out$pattern_name, sep = "\r")), names(ki67_empty_text_pattern_candidates()), drop = FALSE]
}

ki67_channel_summary <- function(inventory, registry, pathology, text_patterns) {
  inventory <- ki67_align_search_inventory(inventory)
  source_only <- inventory[inventory$evidence_channel == "source_only_search_space" | inventory$evidence_strength == "source_only", , drop = FALSE]
  direct_registry <- registry[registry$evidence_strength %in% c("strong_direct", "moderate_direct"), , drop = FALSE]
  numeric_pathology <- pathology[pathology$mcl_triangle_high_risk_ki67_numeric %in% TRUE, , drop = FALSE]
  direct_pathology <- pathology[pathology$evidence_strength %in% c("strong_direct", "moderate_direct"), , drop = FALSE]
  text_direct <- inventory[inventory$evidence_channel == "pathology_text_extraction_readiness" &
    inventory$evidence_strength %in% c("strong_direct", "moderate_direct", "weak_candidate"), , drop = FALSE]

  channel_row <- function(channel, label, confirmed, candidate, status, action, notes) {
    data.frame(
      evidence_channel = channel,
      channel_label = label,
      confirmed_hits = as.integer(confirmed),
      candidate_hits = as.integer(candidate),
      status = status,
      next_validation_action = action,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }

  bind_rows_base(list(
    channel_row(
      "structured_registry_fields",
      "Structured registry fields",
      nrow(direct_registry),
      nrow(registry),
      if (nrow(direct_registry)) "candidate_present" else "not_found_in_current_artifacts",
      "Validate RKKP/LYFO field definitions and value semantics before analytic use.",
      "Registry hits require codebook validation; source-only LYFO availability is not Ki-67 evidence."
    ),
    channel_row(
      "danish_pathology_code_evidence",
      "Danish pathology code evidence / AEKIxxx",
      nrow(numeric_pathology),
      max(0L, nrow(direct_pathology)),
      if (nrow(numeric_pathology)) "confirmed_present" else "requires_production_validation",
      "Run aggregate-only code counts for AEKIxxx / ÆKIxxx in pathology code fields.",
      "AEKIxxx parser is ready; current static artifacts do not expose validated aggregate code counts unless confirmed hits are present."
    ),
    channel_row(
      "pathology_text_extraction_readiness",
      "Pathology text extraction readiness",
      nrow(text_direct),
      nrow(text_patterns),
      "requires_production_validation",
      "Run aggregate-only text pattern counts; no raw snippets or identifiers.",
      "Regex patterns are readiness specifications tested on synthetic examples, not validated real-report extraction."
    ),
    channel_row(
      "source_only_search_space",
      "Source-only search space",
      0L,
      nrow(source_only),
      if (nrow(source_only)) "source_space_only" else "not_found_in_current_artifacts",
      "Use only as source activation guidance; do not treat as direct Ki-67 evidence.",
      "Broad pathology or LYFO source availability is search space, not Ki-67 evidence."
    )
  ))[names(ki67_empty_channel_summary())]
}

ki67_aeki_validation_plan <- function() {
  patterns <- c("^ÆKI([0-9]{3})$", "^AEKI([0-9]{3})$", "^Aeki([0-9]{3})$", "^aeki([0-9]{3})$", "^Ã†KI([0-9]{3})$")
  resources <- data.frame(
    resource_id = c("pato", "t_mikro", "t_konk"),
    table = c("SDS_pato / Patobank code table", "SDS_t_mikro_ny / pathology microscopy", "SDS_t_konk_ny / pathology conclusion"),
    fields = c("c_snomedkode; code; raw_code; snomedkode", "c_snomedkode; code; raw_code; snomedkode", "c_snomedkode; code; raw_code; snomedkode"),
    stringsAsFactors = FALSE
  )
  rows <- list()
  for (i in seq_len(nrow(resources))) {
    for (pattern in patterns) {
      rows[[length(rows) + 1L]] <- data.frame(
        validation_step = "aggregate_aeki_code_count",
        resource_id = resources$resource_id[[i]],
        candidate_table_or_source = resources$table[[i]],
        candidate_code_field = resources$fields[[i]],
        candidate_value_field = "parsed_percent_from_code",
        pattern = pattern,
        safe_aggregate_output = "resource_id; source_table; code; parsed_percent; aggregate_count; distinct_patient_count_if_allowed; year_min_if_allowed; year_max_if_allowed",
        privacy_risk = "low_if_aggregate_only",
        requires_db_access = TRUE,
        expected_result = "Aggregate counts by Ki-67 code only; no patient-level rows, identifiers, dates, or report snippets.",
        notes = "Valid parsed_percent range is 0-100. Values above 100 are rejected. Validate Danish Patobank codebook before analytic use.",
        stringsAsFactors = FALSE
      )
    }
  }
  bind_rows_base(rows)[names(ki67_empty_aeki_validation_plan())]
}

ki67_aeki_code_counts <- function(pathology) {
  if (is.data.frame(pathology) && nrow(pathology)) {
    x <- pathology[pathology$mcl_triangle_high_risk_ki67_numeric %in% TRUE, , drop = FALSE]
    if (nrow(x)) {
      pct <- vapply(x$code, function(code) {
        parsed <- ki67_parse_patobank_numeric_percent(code)
        if (is.na(parsed)) "" else as.character(parsed)
      }, character(1))
      return(data.frame(
        resource_id = x$resource_id,
        source_table = x$table_or_file,
        code = x$code,
        parsed_percent = pct,
        aggregate_count = "",
        distinct_patient_count_if_allowed = "",
        year_min_if_allowed = "",
        year_max_if_allowed = "",
        validation_status = "candidate_found_in_aggregate_metadata_requires_validation",
        notes = "Code observed in aggregate metadata, but production aggregate counts are still required before study use.",
        stringsAsFactors = FALSE
      )[names(ki67_empty_aeki_code_counts())])
    }
  }
  data.frame(
    resource_id = "",
    source_table = "",
    code = "",
    parsed_percent = "",
    aggregate_count = "",
    distinct_patient_count_if_allowed = "",
    year_min_if_allowed = "",
    year_max_if_allowed = "",
    validation_status = "requires_production_validation",
    notes = "No fake positive counts in fixture/static mode. Run aggregate-only AEKIxxx code counts in production pathology code fields.",
    stringsAsFactors = FALSE
  )[names(ki67_empty_aeki_code_counts())]
}

ki67_text_validation_plan <- function(text_patterns) {
  patterns <- ki67_percent_patterns()
  rows <- list()
  resources <- c("t_mikro", "t_konk", "pato")
  fields <- c("microscopy/conclusion/report text", "conclusion/report text", "report/narrative text")
  for (i in seq_along(resources)) {
    for (nm in names(patterns)) {
      rows[[length(rows) + 1L]] <- data.frame(
        validation_step = "aggregate_text_pattern_count",
        resource_id = resources[[i]],
        candidate_text_field = fields[[i]],
        pattern_name = nm,
        regex_pattern = unname(patterns[[nm]]),
        safe_aggregate_output = "resource_id; source_table; pattern_name; value_class; aggregate_report_count; distinct_patient_count_if_allowed; no snippets",
        privacy_risk = "low_if_aggregate_only_no_snippets",
        requires_db_access = TRUE,
        expected_result = "Counts reports containing Ki-67/MIB-1/proliferationsindeks terms and exact/range/inequality/qualitative/unknown classes.",
        notes = "Synthetic/readiness pattern only until aggregate production validation and clinical/pathology review.",
        stringsAsFactors = FALSE
      )
    }
  }
  bind_rows_base(rows)[names(ki67_empty_text_validation_plan())]
}

ki67_discovery_summary <- function(inventory, registry, pathology, text_patterns, channel_summary = ki67_empty_channel_summary()) {
  strong <- sum(inventory$evidence_strength == "strong_direct", na.rm = TRUE)
  moderate <- sum(inventory$evidence_strength == "moderate_direct", na.rm = TRUE)
  source_only <- sum(inventory$evidence_strength == "source_only", na.rm = TRUE)
  numeric <- sum(inventory$candidate_numeric_value_available, na.rm = TRUE)
  ui_display <- sum(inventory$display_in_ui %in% TRUE, na.rm = TRUE)
  ui_suppressed <- sum(!inventory$display_in_ui %in% TRUE, na.rm = TRUE)
  data.frame(
    metric = c("strong_direct_hits", "moderate_direct_hits", "source_only_hits", "numeric_percent_like_hits", "registry_candidates", "pathology_code_candidates", "text_pattern_candidates", "ui_display_hits", "ui_suppressed_hits", "evidence_channels"),
    value = as.character(c(strong, moderate, source_only, numeric, nrow(registry), nrow(pathology), nrow(text_patterns), ui_display, ui_suppressed, nrow(channel_summary))),
    notes = c(
      "Direct Ki-67/MIB/proliferation-index aggregate metadata hits.",
      "Moderate direct aggregate metadata hits.",
      "Search-space hits only; not direct Ki-67 evidence.",
      "Aggregate metadata lines with Ki-67-like numeric percent classes; no patient text emitted.",
      "Structured registry field candidates.",
      "Pathology/code candidates, including external anchors.",
      "Synthetic/metadata text-pattern extraction candidates.",
      "Rows intended for concise UI display after duplicate/source-only suppression.",
      "Rows suppressed from UI because they are duplicates, low-priority source-only rows, or false-positive source-space hits.",
      "Evidence channels summarized for the MCL/TRIANGLE Ki-67 panel."
    ),
    stringsAsFactors = FALSE
  )
}

build_ki67_discovery_outputs <- function(project_root = ".", include_reference_files = TRUE, ...) {
  frames <- list(...)
  frames <- frames[!vapply(frames, is.null, logical(1))]
  inventory <- ki67_build_search_inventory(frames = frames, project_root = project_root, include_reference_files = include_reference_files)
  registry <- ki67_registry_candidates(inventory)
  pathology <- ki67_pathology_code_candidates(inventory)
  text_patterns <- ki67_text_pattern_candidates(inventory)
  channel_summary <- ki67_channel_summary(inventory, registry, pathology, text_patterns)
  aeki_validation_plan <- ki67_aeki_validation_plan()
  aeki_code_counts <- ki67_aeki_code_counts(pathology)
  text_validation_plan <- ki67_text_validation_plan(text_patterns)
  list(
    search_inventory = inventory,
    registry_field_candidates = registry,
    pathology_code_candidates = pathology,
    text_pattern_candidates = text_patterns,
    channel_summary = channel_summary,
    aeki_validation_plan = aeki_validation_plan,
    aeki_code_counts = aeki_code_counts,
    text_validation_plan = text_validation_plan,
    summary = ki67_discovery_summary(inventory, registry, pathology, text_patterns, channel_summary)
  )
}

ki67_write_extraction_spec <- function(path) {
  lines <- c(
    "concept_id: ki67_percent_positive",
    "preferred_label: Ki-67 proliferation index",
    "synonyms:",
    "  - Ki-67",
    "  - Ki67",
    "  - KI-67",
    "  - Ki 67",
    "  - MIB-1",
    "  - MIB1",
    "  - proliferation index",
    "  - proliferationsindeks",
    "external_reference_codes:",
    "  SNOMED_CT: '1255078008'",
    "  SNOMED_CT_SITE_SPECIFIC_EXAMPLE: '1279926000'",
    "danish_pathology_codes:",
    "  numeric_percent_value_pattern: '\u00c6KIxxx'",
    "  regex: '^\u00c6KI([0-9]{3})$'",
    "  transliteration_regex: '^AEKI([0-9]{3})$'",
    "  interpretation: xxx is the Ki-67 percentage, valid from 000 to 100",
    "  p16_ki67_dual_stain_codes:",
    "    FY5015: p16/Ki-67-positive cells not detected; qualitative cervix triage evidence only",
    "    FY5016: p16/Ki-67-positive cells detected; qualitative cervix triage evidence only",
    "    M0901K: inconclusive p16/Ki-67 test",
    "    M0901L: too little material for p16/Ki-67",
    "preferred_sources:",
    "  - RKKP_LYFO structured registry fields if validated",
    "  - Danish pathology/SNOMED code resources if validated",
    "  - t_mikro and t_konk pathology text fields after source activation",
    "backup_sources:",
    "  - legacy/reference cartography metadata",
    "structured_field_strategy: Search field names, labels, and value metadata for Ki-67/MIB/proliferation-index terms; validate codebooks before cohort extraction.",
    "pathology_code_strategy: Use external SNOMED CT codes as anchors only; discover Danish pathology codes separately.",
    "danish_patobank_numeric_code_strategy: Parse \u00c6KIxxx / AEKIxxx as local Ki-67 percent value codes when xxx is between 000 and 100; keep p16/Ki-67 dual-stain codes separate from MCL Ki-67 proliferation-index evidence.",
    "pathology_text_strategy: Apply proximity-bounded patterns to redacted/extraction outputs; never emit raw report text in the static atlas.",
    "production_validation_strategy: Run aggregate-only \u00c6KIxxx code counts and aggregate-only text-pattern counts; do not return patient-level rows, identifiers, dates, requisition IDs, or raw pathology snippets.",
    "numeric_value_strategy: Capture exact percentages between 0 and 100 as observation values with unit percent.",
    "range_value_strategy: Capture ranges as lower and upper percent bounds; do not coerce to a single value without a study rule.",
    "inequality_value_strategy: Capture comparator and threshold separately.",
    "qualitative_value_strategy: Classify nonnumeric positive/staining mentions separately from extractable percentages.",
    "unknown_value_strategy: Classify unknown/not-stated mentions separately.",
    "unit_normalization: Percent values only; store unit as percent.",
    "validation_rules:",
    "  - percent values must be between 0 and 100",
    "  - reject years and dates",
    "  - reject unrelated percentages when Ki-67/MIB/proliferationsindeks is not nearby",
    "  - exact, range, inequality, qualitative, and unknown values stay separate",
    "false_positive_risks:",
    "  - unrelated percentages near report text",
    "  - source-only pathology availability mistaken for Ki-67 evidence",
    "  - external SNOMED CT anchors mistaken for Danish local codes",
    "  - p16/Ki-67 dual-stain codes mistaken for numeric MCL Ki-67 proliferation index",
    "false_negative_risks:",
    "  - Danish local abbreviations not in the initial synonym list",
    "  - Ki-67 values embedded in unprofiled pathology text",
    "clinical_validation_required: true"
  )
  dir_create(dirname(path))
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

ki67_write_outputs <- function(outputs, output_dir, project_root = ".") {
  spec_path <- file.path(project_root, "clinical_questions", "ki67_extraction_spec.yml")
  list(
    search_inventory = write_csv(outputs$search_inventory, file.path(output_dir, "ki67_search_inventory.csv")),
    registry_field_candidates = write_csv(outputs$registry_field_candidates, file.path(output_dir, "ki67_registry_field_candidates.csv")),
    pathology_code_candidates = write_csv(outputs$pathology_code_candidates, file.path(output_dir, "ki67_pathology_code_candidates.csv")),
    text_pattern_candidates = write_csv(outputs$text_pattern_candidates, file.path(output_dir, "ki67_text_pattern_candidates.csv")),
    channel_summary = write_csv(outputs$channel_summary, file.path(output_dir, "ki67_channel_summary.csv")),
    aeki_validation_plan = write_csv(outputs$aeki_validation_plan, file.path(output_dir, "ki67_aeki_validation_plan.csv")),
    aeki_code_counts = write_csv(outputs$aeki_code_counts, file.path(output_dir, "ki67_aeki_code_counts.csv")),
    text_validation_plan = write_csv(outputs$text_validation_plan, file.path(output_dir, "ki67_text_validation_plan.csv")),
    extraction_spec = ki67_write_extraction_spec(spec_path)
  )
}
