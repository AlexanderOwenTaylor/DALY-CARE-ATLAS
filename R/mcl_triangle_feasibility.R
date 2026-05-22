mcl_triangle_required_concept_columns <- function() {
  c(
    "concept_group", "concept_name", "atlas_search_terms", "expected_sources",
    "preferred_sources", "notes", "required_for_feasibility", "high_priority"
  )
}

mcl_triangle_read_concepts <- function(project_root = ".") {
  path <- file.path(project_root, "config", "mcl_triangle_feasibility_concepts.tsv")
  if (!file.exists(path)) {
    stop("Missing MCL/TRIANGLE concept configuration: ", path, call. = FALSE)
  }
  concepts <- read_delimited_file(path)
  missing <- setdiff(mcl_triangle_required_concept_columns(), names(concepts))
  if (length(missing)) {
    stop("MCL/TRIANGLE concept configuration is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  concepts <- concepts[mcl_triangle_required_concept_columns()]
  concepts$required_for_feasibility <- tolower(trimws(as.character(concepts$required_for_feasibility))) %in% c("true", "t", "1", "yes", "y")
  concepts$high_priority <- tolower(trimws(as.character(concepts$high_priority))) %in% c("true", "t", "1", "yes", "y")
  concepts
}

mcl_triangle_empty_summary <- function() {
  empty_df(
    metric = character(), label = character(), value = character(), status = character(),
    count_type = character(), evidence_count = integer(), notes = character()
  )
}

mcl_triangle_empty_variable_inventory <- function() {
  empty_df(
    concept_group = character(), concept_name = character(), source = character(),
    canonical_resource_id = character(), current_profiled_this_run = logical(),
    legacy_reference_only = logical(), table_or_source = character(), raw_field = character(),
    semantic_id = character(), code_or_value = character(), evidence_type = character(),
    matched_term = character(), matched_field = character(), match_reason = character(),
    evidence_category = character(),
    count_or_rows_if_available = character(), count_type = character(), patient_count_if_available = character(),
    confidence = character(), notes = character()
  )
}

mcl_triangle_empty_treatment_inventory <- function() {
  empty_df(
    exposure_name = character(), exposure_group = character(), source = character(),
    code_system = character(), code = character(), raw_value = character(), table_or_source = character(),
    raw_field = character(), matched_term = character(), matched_field = character(),
    match_reason = character(), evidence_category = character(),
    current_profiled_this_run = logical(), evidence_count_or_rows = character(), count_type = character(),
    notes = character()
  )
}

mcl_triangle_empty_outcome_inventory <- function() {
  empty_df(
    outcome_name = character(), source = character(), table_or_source = character(), raw_field = character(),
    matched_term = character(), matched_field = character(), match_reason = character(),
    evidence_category = character(),
    current_profiled_this_run = logical(), legacy_reference_only = logical(), feasibility_role = character(),
    count_or_rows_if_available = character(), count_type = character(), notes = character()
  )
}

mcl_triangle_empty_false_positive_exclusions <- function() {
  empty_df(
    concept_name = character(), source = character(), field = character(), value = character(),
    reason = character(), exclusion_type = character(), notes = character()
  )
}

mcl_triangle_empty_biology_gap_analysis <- function() {
  empty_df(
    marker = character(), direct_variable_found = logical(), indirect_proxy_found = logical(),
    current_profiled_source_available = logical(), legacy_reference_only = logical(),
    preferred_recovery_source = character(), action_required = character(),
    feasibility_status = character(), notes = character()
  )
}

mcl_triangle_empty_study_readiness_matrix <- function() {
  empty_df(
    study_requirement = character(), readiness_status = character(),
    direct_variable_available = logical(), proxy_available = logical(),
    current_profiled_evidence = logical(), legacy_reference_only_evidence = logical(),
    preferred_source = character(), candidate_fields_or_codes = character(),
    key_limitation = character(), recommended_next_action = character()
  )
}

mcl_triangle_empty_text_table <- function(kind = character(), text = character()) {
  empty_df(kind = kind, text = text)
}

mcl_triangle_empty_standalone_output_source <- function() {
  empty_df(
    source_type = character(),
    source_path = character(),
    selected_outputs_dir = character(),
    selected = logical(),
    mode = character(),
    acceptance_status = character(),
    failed_queries = integer(),
    production_aggregate_succeeded = logical(),
    notes = character()
  )
}

mcl_triangle_empty_pathology_ki67_signpost <- function() {
  empty_df(
    title = character(),
    source_resource = character(),
    table_name = character(),
    column_name = character(),
    code_family = character(),
    interpretation = character(),
    evidence_type = character(),
    current_use_status = character(),
    mcl_aeki_known = character(),
    mcl_aeki_ge30 = character(),
    mcl_aeki_ge50 = character(),
    text_recovery_route = character(),
    caveat = character(),
    search_terms = character()
  )
}

mcl_triangle_empty_payload <- function() {
  list(
    summary = mcl_triangle_empty_summary(),
    variable_inventory = mcl_triangle_empty_variable_inventory(),
    treatment_inventory = mcl_triangle_empty_treatment_inventory(),
    outcome_inventory = mcl_triangle_empty_outcome_inventory(),
    biology_gap_analysis = mcl_triangle_empty_biology_gap_analysis(),
    study_readiness_matrix = mcl_triangle_empty_study_readiness_matrix(),
    false_positive_exclusions = mcl_triangle_empty_false_positive_exclusions(),
    ki67_discovery = ki67_empty_payload(),
    standalone_output_source = mcl_triangle_empty_standalone_output_source(),
    pathology_ki67_signpost = mcl_triangle_empty_pathology_ki67_signpost(),
    recommended_next_actions = mcl_triangle_empty_text_table(),
    caveats = mcl_triangle_empty_text_table(),
    verdict_metadata = mcl_triangle_empty_text_table()
  )
}

mcl_triangle_norm <- function(x) {
  x <- tolower(as.character(x %||% ""))
  x <- gsub("\u00e6", "ae", x, fixed = TRUE)
  x <- gsub("\u00f8", "oe", x, fixed = TRUE)
  x <- gsub("\u00e5", "aa", x, fixed = TRUE)
  x <- gsub("\u00fc", "u", x, fixed = TRUE)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

mcl_triangle_terms <- function(x) {
  x <- paste(as.character(x %||% ""), collapse = "|")
  parts <- unlist(strsplit(x, "[|;]", fixed = FALSE), use.names = FALSE)
  parts <- trimws(parts)
  parts <- parts[nzchar(parts)]
  unique(parts)
}

mcl_triangle_terms_pattern <- function(terms) {
  terms <- unique(mcl_triangle_norm(terms))
  terms <- terms[nzchar(terms)]
  if (!length(terms)) return("")
  escaped <- gsub("([\\W])", "\\\\\\1", terms, perl = TRUE)
  paste0("(^| )(", paste(escaped, collapse = "|"), ")( |$)")
}

mcl_triangle_pick_col <- function(df, candidates) {
  hits <- intersect(candidates, names(df))
  if (length(hits)) hits[[1]] else NA_character_
}

mcl_triangle_text_for_frame <- function(df, columns) {
  if (!is.data.frame(df) || !nrow(df)) return(character())
  columns <- intersect(columns, names(df))
  if (!length(columns)) return(rep("", nrow(df)))
  vals <- lapply(columns, function(nm) {
    x <- as.character(df[[nm]] %||% "")
    x[is.na(x)] <- ""
    x
  })
  mcl_triangle_norm(do.call(paste, c(vals, sep = " ")))
}

mcl_triangle_match_rows <- function(df, search_text, terms, max_rows = 60L) {
  if (!is.data.frame(df) || !nrow(df) || !length(search_text)) return(df[0, , drop = FALSE])
  pattern <- mcl_triangle_terms_pattern(terms)
  if (!nzchar(pattern)) return(df[0, , drop = FALSE])
  idx <- grepl(pattern, search_text, perl = TRUE)
  if (!any(idx, na.rm = TRUE)) return(df[0, , drop = FALSE])
  head(df[idx, , drop = FALSE], max_rows)
}

mcl_triangle_match_info <- function(df, columns, terms, max_rows = 60L) {
  if (!is.data.frame(df) || !nrow(df)) return(df[0, , drop = FALSE])
  columns <- intersect(columns, names(df))
  terms <- unique(mcl_triangle_terms(terms))
  terms <- terms[nzchar(terms)]
  if (!length(columns) || !length(terms)) return(df[0, , drop = FALSE])
  pattern <- mcl_triangle_terms_pattern(terms)
  if (!nzchar(pattern)) return(df[0, , drop = FALSE])
  search_text <- mcl_triangle_text_for_frame(df, columns)
  idx <- which(grepl(pattern, search_text, perl = TRUE))
  if (!length(idx)) return(df[0, , drop = FALSE])
  idx <- head(idx, max_rows)
  out <- list()
  for (i in idx) {
    matched <- NULL
    for (column in columns) {
      value <- as.character(df[[column]][[i]] %||% "")
      if (!nzchar(value)) next
      for (term in terms) {
        if (mcl_triangle_has_terms(value, term)) {
          matched <- list(term = term, field = column)
          break
        }
      }
      if (!is.null(matched)) break
    }
    if (is.null(matched)) next
    row <- df[i, , drop = FALSE]
    row$.matched_term <- matched$term
    row$.matched_field <- matched$field
    out[[length(out) + 1L]] <- row
  }
  bind_rows_base(out)
}

mcl_triangle_concept_search_terms <- function(concept) {
  name <- as.character(concept$concept_name[[1]] %||% "")
  terms <- c(
    mcl_triangle_terms(concept$atlas_search_terms),
    mcl_triangle_terms(name)
  )
  if (grepl("ibrutinib|BTK", name, ignore.case = TRUE)) {
    terms <- c(terms, "ibrutinib", "Imbruvica", "L01XE27", "BWHA169", "BTK inhibitor", "BTK haemmer")
  }
  if (grepl("ASCT|HDT|stem|autolog", name, ignore.case = TRUE)) {
    terms <- c(
      terms,
      "Beh_Hoejdosisbehandling", "Beh_TypeAutologStamcellestoette",
      "Beh_Stamcelleinfusion_dt", "Rec_Hoejdosisbehandling",
      "Rec_Stamcelleinfusion_dt", "hoejdosis", "autolog",
      "stamcelle", "stamcelleinfusion", "stem cell", "stem-cell"
    )
  }
  if (grepl("CIT|immunochemotherapy|regimen|R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine", name, ignore.case = TRUE)) {
    terms <- c(
      terms, "treatment", "therapy", "behandling", "regimen", "regime",
      "protocol", "cytarabine", "Ara C", "rituximab", "bendamustine",
      "cyclophosphamide", "doxorubicin", "chemotherapy", "kemoterapi"
    )
  }
  unique(terms[nzchar(terms)])
}

mcl_triangle_frame_columns <- function(frame_type) {
  switch(
    frame_type,
    "semantic dictionary" = c(
      "semantic_id", "clinical_concept_id", "clinical_variable", "semantic_meaning",
      "raw_column", "raw_descriptor", "raw_code", "raw_value", "code_system",
      "clinical_caveat", "search_terms"
    ),
    "code map" = c(
      "semantic_id", "clinical_concept_id", "clinical_variable", "code_system",
      "code", "code_name", "panel", "notes"
    ),
    "value map" = c(
      "semantic_id", "clinical_concept_id", "clinical_variable", "raw_column",
      "raw_value", "display_value", "value_class", "clinical_interpretation", "notes"
    ),
    "column profile" = c(
      "column_name", "column", "semantic_type", "logical_type", "data_type",
      "r_type", "value_type", "notes"
    ),
    "panel links" = c("semantic_id", "clinical_concept_id", "panel_id", "panel_section", "relationship"),
    "source/catalog profile" = c("table_name", "source_label", "domain", "subdomain", "atlas_role", "load_status"),
    "legacy/reference evidence" = c(
      "evidence_source", "evidence_type", "canonical_resource_id", "current_source_key",
      "warning_needed", "notes", "evidence_freshness_status"
    ),
    character()
  )
}

mcl_triangle_has_terms <- function(text, terms) {
  pattern <- mcl_triangle_terms_pattern(terms)
  if (!nzchar(pattern)) return(FALSE)
  grepl(pattern, mcl_triangle_norm(text), perl = TRUE)
}

mcl_triangle_row_source_text <- function(row) {
  paste(
    mcl_triangle_value(row, c("source_name", "source", "evidence_source", "table_name", "panel_id")),
    mcl_triangle_value(row, c("object_name", "table_name", "source_name", "current_source_key", "panel_id")),
    sep = " "
  )
}

mcl_triangle_source_filter_match <- function(row, source_filters) {
  source_filters <- mcl_triangle_terms(source_filters)
  source_filters <- source_filters[nzchar(source_filters)]
  if (!length(source_filters)) return(TRUE)
  mcl_triangle_has_terms(mcl_triangle_row_source_text(row), source_filters)
}

mcl_triangle_value <- function(row, candidates) {
  col <- mcl_triangle_pick_col(row, candidates)
  if (is.na(col)) return("")
  as.character(row[[col]][[1]] %||% "")
}

mcl_triangle_count_value <- function(row, count_cols) {
  col <- mcl_triangle_pick_col(row, count_cols)
  if (is.na(col)) return("")
  value <- suppressWarnings(as.numeric(row[[col]][[1]] %||% NA_real_))
  if (is.na(value)) return("")
  format(value, big.mark = ",", scientific = FALSE, trim = TRUE)
}

mcl_triangle_known_false_positive_exclusions <- function() {
  data.frame(
    concept_name = c(
      "Ibrutinib", "Ibrutinib", "ASCT / HDT", "Response evaluation",
      "Death / overall survival", "Neutropenic fever proxy",
      "Neutropenic fever proxy", "Neutropenic fever proxy", "Ibrutinib", "ASCT / HDT",
      "Infection"
    ),
    source = c(
      "CLL_TREAT_IBRUTINIB", "CLL_TREAT_IBRUTINIB", "RKKP_DaMyDa",
      "SP_Social_Hx", "SP_Social_Hx", "SP_VitaleVaerdier",
      "RKKP_DaMyDa", "RKKP_LYFO", "SDS_t_sksube", "RKKP_CLL", "RKKP_DaMyDa"
    ),
    field = c(
      "smoking", "alcohol", "FU_Doed_aarsag", "drikker",
      "ryger", "displayname", "FU_Doed_aarsag", "Reg_BSymptomer", "BWHA169", "Beh_TRANSPLANT",
      "FU_Doed_aarsag"
    ),
    value = c("", "", "transplant", "", "", "", "", "", "BWHA169", "", "infection"),
    reason = c(
      "Smoking inside the CLL_TREAT_IBRUTINIB table is not ibrutinib exposure evidence.",
      "Alcohol inside the CLL_TREAT_IBRUTINIB table is not ibrutinib exposure evidence.",
      "DaMyDa death-cause value transplant is not MCL ASCT/HDT exposure evidence.",
      "Social-history drinking is not response-evaluation evidence.",
      "Social-history smoking is not death, response, or safety evidence.",
      "A generic vital-sign display-name field is not neutropenic-fever evidence.",
      "DaMyDa cause-of-death field is not neutropenic-fever evidence.",
      "LYFO B symptoms are not neutropenic-fever evidence.",
      "BWHA169 in SDS_t_sksube is atlas-confirmed SKS Ibrutinib code evidence, but aggregate person counting requires SDS_t_adm bridge validation.",
      "CLL transplant fields are not primary MCL ASCT/HDT phenotype evidence.",
      "DaMyDa cause-of-death infection values are not direct infection phenotype evidence."
    ),
    exclusion_type = c(
      "source_name_false_positive", "source_name_false_positive", "cross_disease_or_wrong_context",
      "wrong_domain", "wrong_domain", "generic_field_false_positive",
      "wrong_endpoint", "wrong_endpoint", "bridge_required_not_false_positive", "cross_disease_reference",
      "cause_of_death_proxy_not_direct_infection"
    ),
    notes = c(
      "Source names are used only as filters/boosts after a concept-specific match.",
      "Source names are used only as filters/boosts after a concept-specific match.",
      "Use LYFO first-line HDT/stem-cell fields for the primary MCL ASCT/HDT phenotype.",
      "Kept out of main MCL/TRIANGLE evidence cards.",
      "Kept out of main MCL/TRIANGLE evidence cards.",
      "Kept out of main MCL/TRIANGLE evidence cards.",
      "Kept out of main MCL/TRIANGLE evidence cards.",
      "Kept out of main MCL/TRIANGLE evidence cards.",
      "Retain as Ibrutinib source evidence only with atlas semantics; do not emit person counts without source bridge validation.",
      "Use LYFO Beh_Hoejdosisbehandling, Beh_TypeAutologStamcellestoette, and Beh_Stamcelleinfusion_dt for MCL.",
      "May be considered only as a cause-of-death infection proxy in detailed audit outputs, not a main direct evidence card."
    ),
    stringsAsFactors = FALSE
  )
}

mcl_triangle_false_positive_reason <- function(row) {
  concept <- mcl_triangle_norm(row$concept_name[[1]] %||% "")
  source_text <- mcl_triangle_norm(paste(row$source[[1]] %||% "", row$table_or_source[[1]] %||% ""))
  field_text <- mcl_triangle_norm(row$raw_field[[1]] %||% "")
  value_text <- mcl_triangle_norm(row$code_or_value[[1]] %||% "")
  if (grepl("ibrutinib|btk", concept) && grepl("cll treat ibrutinib", source_text) &&
      field_text %in% c("smoking", "alcohol", "ryger", "drikker")) {
    return("Unrelated social-history field inside CLL_TREAT_IBRUTINIB; not ibrutinib exposure evidence.")
  }
  if (grepl("ibrutinib|btk", concept) && grepl("bwha169", paste(field_text, value_text))) {
    return("")
  }
  if (grepl("asct|hdt|stem|autolog", concept) && grepl("rkkp damyda", source_text) &&
      grepl("fu doed aarsag|fu doedsaarsag|fu dod arsag", field_text) &&
      grepl("transplant", value_text)) {
    return("DaMyDa death-cause transplant value is not MCL ASCT/HDT exposure evidence.")
  }
  if (grepl("asct|hdt|stem|autolog", concept) && grepl("rkkp cll|cll treat|reg cll|mm treat|rkkp damyda", source_text)) {
    return("Cross-disease transplant fields are reference rows and are not primary MCL ASCT/HDT evidence.")
  }
  if (grepl("death|overall survival|response|follow|relapse|progression|neutropenic|fever|safety", concept) &&
      grepl("sp social hx", source_text) && field_text %in% c("drikker", "ryger", "smoking", "alcohol")) {
    return("Social-history drinking/smoking field is not outcome or safety evidence.")
  }
  if (grepl("neutropenic|fever", concept) && grepl("sp vitalevaerdier", source_text) && field_text == "displayname") {
    return("Generic vital-sign display name is not neutropenic-fever evidence.")
  }
  if (grepl("neutropenic|fever", concept) && grepl("rkkp damyda", source_text) && grepl("fu doed aarsag", field_text)) {
    return("DaMyDa cause-of-death field is not neutropenic-fever evidence.")
  }
  if (grepl("infection|infektion|safety|toxicity", concept) && grepl("rkkp damyda", source_text) &&
      grepl("fu doed aarsag", field_text)) {
    return("DaMyDa cause-of-death infection values are not direct infection phenotype evidence; retain only as cause-of-death infection proxy if explicitly labelled.")
  }
  if (grepl("neutropenic|fever", concept) && grepl("rkkp lyfo", source_text) && field_text == "reg bsymptomer") {
    return("LYFO B symptoms are not neutropenic-fever evidence.")
  }
  ""
}

mcl_triangle_evidence_category <- function(row, evidence_type) {
  false_reason <- mcl_triangle_false_positive_reason(row)
  if (nzchar(false_reason)) return("false_positive_excluded")
  if (identical(evidence_type, "source/catalog profile")) return("source_space_only")
  concept <- mcl_triangle_norm(row$concept_name[[1]] %||% "")
  field_text <- mcl_triangle_norm(row$raw_field[[1]] %||% "")
  source_text <- mcl_triangle_norm(paste(row$source[[1]] %||% "", row$table_or_source[[1]] %||% ""))
  if (grepl("asct|hdt|stem|autolog", concept) &&
      field_text %in% c("rec hoejdosisbehandling", "rec stamcelleinfusion dt")) {
    return("proxy_evidence")
  }
  if (grepl("asct|hdt|stem|autolog", concept) && grepl("sds t sks|procedure", source_text)) {
    return("proxy_evidence")
  }
  if (identical(evidence_type, "code map")) return("direct_code_evidence")
  if (identical(evidence_type, "value map")) return("direct_value_evidence")
  "direct_variable_evidence"
}

mcl_triangle_match_reason <- function(row, evidence_type) {
  false_reason <- mcl_triangle_false_positive_reason(row)
  if (nzchar(false_reason)) return(false_reason)
  category <- mcl_triangle_evidence_category(row, evidence_type)
  field_text <- mcl_triangle_norm(row$raw_field[[1]] %||% "")
  concept <- mcl_triangle_norm(row$concept_name[[1]] %||% "")
  if (identical(category, "source_space_only")) return("Relevant source/search-space row only; not direct clinical evidence.")
  if (identical(category, "proxy_evidence") &&
      field_text %in% c("rec hoejdosisbehandling", "rec stamcelleinfusion dt")) {
    return("Relapse/recurrence transplant timing proxy; not first-line ASCT/HDT unless explicitly handled.")
  }
  if (grepl("asct|hdt|stem|autolog", concept) &&
      field_text %in% c("beh hoejdosisbehandling", "beh typeautologstamcellestoette", "beh stamcelleinfusion dt")) {
    return("Primary LYFO MCL first-line ASCT/HDT phenotype field.")
  }
  paste0("Matched concept-specific ", evidence_type, " term.")
}

mcl_triangle_source_profiled <- function(source_name = "", table_name = "", sources = NULL,
                                         canonical_reconciliation = NULL,
                                         legacy_reference_vs_current = NULL) {
  candidates <- unique(mcl_triangle_norm(c(source_name, table_name)))
  candidates <- candidates[nzchar(candidates)]
  if (!length(candidates)) return(FALSE)
  if (is.data.frame(sources) && nrow(sources)) {
    cols <- intersect(c("table_name", "source", "source_label", "domain", "subdomain"), names(sources))
    if (length(cols)) {
      text <- mcl_triangle_text_for_frame(sources, cols)
      ok <- (sources$load_status %||% rep("", nrow(sources))) == "ok"
      if (any(ok & text %in% candidates, na.rm = TRUE)) return(TRUE)
      row_hit <- Reduce(`|`, lapply(candidates, function(candidate) grepl(candidate, text, fixed = TRUE)))
      if (any(ok & row_hit, na.rm = TRUE)) return(TRUE)
    }
  }
  if (is.data.frame(canonical_reconciliation) && nrow(canonical_reconciliation)) {
    cols <- intersect(c("canonical_resource_id", "display_name", "current_resolved_source_key", "current_resolved_table_or_view"), names(canonical_reconciliation))
    if (length(cols)) {
      text <- mcl_triangle_text_for_frame(canonical_reconciliation, cols)
      profiled_col <- mcl_triangle_pick_col(canonical_reconciliation, c("current_profiled", "current_profiled_this_run"))
      status_col <- mcl_triangle_pick_col(canonical_reconciliation, c("current_status", "current_classification"))
      profiled <- rep(FALSE, nrow(canonical_reconciliation))
      if (!is.na(profiled_col)) profiled <- profiled | tolower(as.character(canonical_reconciliation[[profiled_col]])) %in% c("true", "1", "yes")
      if (!is.na(status_col)) profiled <- profiled | grepl("profiled|resolved", tolower(as.character(canonical_reconciliation[[status_col]] %||% "")))
      row_hit <- Reduce(`|`, lapply(candidates, function(candidate) grepl(candidate, text, fixed = TRUE)))
      if (any(profiled & row_hit, na.rm = TRUE)) return(TRUE)
    }
  }
  if (is.data.frame(legacy_reference_vs_current) && nrow(legacy_reference_vs_current)) {
    cols <- intersect(c("evidence_source", "canonical_resource_id", "current_source_key", "evidence_freshness_status"), names(legacy_reference_vs_current))
    text <- mcl_triangle_text_for_frame(legacy_reference_vs_current, cols)
    status <- tolower(as.character(legacy_reference_vs_current$evidence_freshness_status %||% ""))
    row_hit <- Reduce(`|`, lapply(candidates, function(candidate) grepl(candidate, text, fixed = TRUE)))
    if (any(grepl("current_profiled", status) & row_hit, na.rm = TRUE)) return(TRUE)
  }
  FALSE
}

mcl_triangle_canonical_id <- function(source_name = "", canonical_reconciliation = NULL) {
  if (!is.data.frame(canonical_reconciliation) || !nrow(canonical_reconciliation)) return("")
  cols <- intersect(c("canonical_resource_id", "display_name", "current_resolved_source_key", "current_resolved_table_or_view"), names(canonical_reconciliation))
  if (!length(cols)) return("")
  text <- mcl_triangle_text_for_frame(canonical_reconciliation, cols)
  key <- mcl_triangle_norm(source_name)
  if (!nzchar(key)) return("")
  idx <- which(grepl(key, text, fixed = TRUE))
  if (!length(idx)) return("")
  as.character(canonical_reconciliation$canonical_resource_id[[idx[[1]]]] %||% "")
}

mcl_triangle_inventory_row <- function(concept, row, evidence_type, evidence_priority,
                                       matched_term = "", matched_field = "",
                                       sources = NULL, canonical_reconciliation = NULL,
                                       legacy_reference_vs_current = NULL) {
  source_name <- mcl_triangle_value(row, c("source_name", "source", "evidence_source", "table_name", "panel_id"))
  object_name <- mcl_triangle_value(row, c("object_name", "table_name", "source_name", "current_source_key", "panel_id"))
  raw_field <- mcl_triangle_value(row, c("raw_column", "column", "column_name", "raw_field", "clinical_variable"))
  if (nzchar(raw_field) && is_sensitive_column(raw_field)) return(NULL)
  code_or_value <- mcl_triangle_value(row, c("code", "raw_code", "code_name", "raw_value", "display_value", "value", "clinical_variable"))
  if (nzchar(code_or_value) && looks_cpr_like(code_or_value)) return(NULL)
  count <- mcl_triangle_count_value(row, c("n", "n_rows", "current_n_rows", "legacy_rows", "value"))
  patient_count <- mcl_triangle_count_value(row, c("n_patients", "current_n_patients", "legacy_patients"))
  count_type <- switch(
    evidence_type,
    "semantic dictionary" = if (nzchar(count)) "source rows" else "",
    "code map" = if (nzchar(count)) "code-map rows" else "",
    "value map" = if (nzchar(count)) "aggregate value-map count" else "",
    "panel links" = "panel-link rows",
    "column profile" = if (nzchar(count)) "source rows" else "",
    "source/catalog profile" = if (nzchar(count)) "source rows" else "",
    "legacy/reference evidence" = "legacy/reference evidence rows",
    ""
  )
  current <- mcl_triangle_source_profiled(
    source_name = source_name,
    table_name = object_name,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current
  )
  canonical_id <- mcl_triangle_canonical_id(source_name %||% object_name, canonical_reconciliation)
  confidence <- mcl_triangle_value(row, c("mapping_confidence", "mapping_status", "confidence"))
  if (!nzchar(confidence)) confidence <- if (evidence_priority <= 3L) "candidate/high-priority aggregate evidence" else "candidate"
  notes <- mcl_triangle_value(row, c("clinical_caveat", "notes", "privacy_note", "relationship"))
  out <- data.frame(
    concept_group = concept$concept_group[[1]],
    concept_name = concept$concept_name[[1]],
    source = source_name,
    canonical_resource_id = canonical_id,
    current_profiled_this_run = current,
    legacy_reference_only = evidence_type == "legacy/reference evidence" || !current,
    table_or_source = object_name,
    raw_field = raw_field,
    semantic_id = mcl_triangle_value(row, c("semantic_id", "clinical_concept_id", "panel_id")),
    code_or_value = code_or_value,
    evidence_type = evidence_type,
    matched_term = matched_term %||% "",
    matched_field = matched_field %||% "",
    match_reason = "",
    evidence_category = "",
    count_or_rows_if_available = count,
    count_type = count_type,
    patient_count_if_available = patient_count,
    confidence = confidence,
    notes = notes,
    evidence_priority = evidence_priority,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out$evidence_category <- mcl_triangle_evidence_category(out, evidence_type)
  out$match_reason <- mcl_triangle_match_reason(out, evidence_type)
  out
}

mcl_triangle_inventory_guard_text <- function(row, include_source = FALSE) {
  bits <- c(
    row$raw_field[[1]] %||% "",
    row$semantic_id[[1]] %||% "",
    row$code_or_value[[1]] %||% "",
    row$notes[[1]] %||% ""
  )
  if (include_source) {
    bits <- c(bits, row$source[[1]] %||% "", row$table_or_source[[1]] %||% "")
  }
  paste(bits, collapse = " ")
}

mcl_triangle_inventory_has_terms <- function(row, terms, include_source = FALSE) {
  mcl_triangle_has_terms(mcl_triangle_inventory_guard_text(row, include_source = include_source), terms)
}

mcl_triangle_treatment_guard_terms <- function(concept_name) {
  name <- mcl_triangle_norm(concept_name)
  if (grepl("ibrutinib|btk", name)) {
    return(c("ibrutinib", "imbruvica", "L01XE27", "BTK", "BTK inhibitor", "BTK haemmer"))
  }
  if (grepl("asct|hdt|stem|autolog", name)) {
    return(c(
      "ASCT", "HDT", "high dose therapy", "autologous", "stem cell",
      "stem-cell", "stamcelle", "transplant", "BWHA169",
      "Beh_Hoejdosisbehandling", "Beh_TypeAutologStamcellestoette",
      "Beh_Stamcelleinfusion_dt", "Rec_Hoejdosisbehandling",
      "Rec_Stamcelleinfusion_dt"
    ))
  }
  if (grepl("rituximab", name)) return(c("rituximab", "MabThera", "L01FA01", "L01XC02"))
  if (grepl("cytarabine|ara", name)) return(c("cytarabine", "Ara C", "L01BC01", "cytosar"))
  if (grepl("bendamustine", name)) return(c("bendamustine", "bendamustin", "L01AA09", "BR"))
  if (grepl("r chop", name)) return(c("R CHOP", "RCHOP", "CHOP", "rituximab CHOP"))
  if (grepl("r dhap", name)) return(c("R DHAP", "RDHAP", "DHAP", "cytarabine", "cisplatin"))
  c(
    "first line", "1st line", "immunochemotherapy", "chemoimmunotherapy", "CIT",
    "induction", "regimen", "regime", "protocol", "kemo", "kemoterapi",
    "treatment", "therapy", "behandling", "Beh Kemoterapi", "Beh Behandling",
    "PB Behandling", "FU Behandling", "rituximab", "cytarabine", "R CHOP",
    "R DHAP", "bendamustine", "cyclophosphamide", "doxorubicin"
  )
}

mcl_triangle_outcome_guard_terms <- function(concept_name) {
  name <- mcl_triangle_norm(concept_name)
  if (grepl("death|overall survival", name)) {
    return(c(
      "death", "date of death", "dead", "deceased", "overall survival",
      "survival endpoint", "doed", "doedsdato", "dod", "dodsdato",
      "død", "dødsdato", "patient doed", "patient dead", "vital status",
      "cause of death", "doedsaarsag", "dødsaarsag", "t doedsaarsag",
      "KMregisdoed", "doedsregister", "death register"
    ))
  }
  if (grepl("relapse|progression|failure", name)) {
    return(c("relapse", "relaps", "recurrence", "progression", "progressive disease", "PD", "FFS", "failure free", "Rec", "ind relaps"))
  }
  if (grepl("next treatment", name)) {
    return(c("next treatment", "new treatment", "ny behandling", "Rec NyBehandling", "second line", "line of therapy"))
  }
  if (grepl("response", name)) {
    return(c("response", "response evaluation", "remission", "Beh Response", "Rec Response"))
  }
  if (grepl("follow", name)) {
    return(c("follow up", "followup", "disease status", "ind fu", "Rec", "FU status"))
  }
  character()
}

mcl_triangle_inventory_allowed <- function(row) {
  group <- as.character(row$concept_group[[1]] %||% "")
  concept <- as.character(row$concept_name[[1]] %||% "")
  if (identical(group, "Treatment exposures")) {
    return(mcl_triangle_inventory_has_terms(row, mcl_triangle_treatment_guard_terms(concept), include_source = FALSE))
  }
  if (identical(group, "Outcomes")) {
    terms <- mcl_triangle_outcome_guard_terms(concept)
    if (!length(terms)) return(TRUE)
    include_source <- grepl("death|overall survival", concept, ignore.case = TRUE)
    return(mcl_triangle_inventory_has_terms(row, terms, include_source = include_source))
  }
  TRUE
}

mcl_triangle_collect_evidence <- function(concept, prepared, max_rows_per_source = 40L) {
  terms <- mcl_triangle_concept_search_terms(concept)
  source_filters <- c(
    mcl_triangle_terms(concept$expected_sources),
    mcl_triangle_terms(concept$preferred_sources)
  )
  frames <- list(
    list(data = prepared$semantic_dictionary, type = "semantic dictionary", priority = 1L),
    list(data = prepared$semantic_code_map, type = "code map", priority = 2L),
    list(data = prepared$semantic_value_map, type = "value map", priority = 3L),
    list(data = prepared$column_evidence, type = "column profile", priority = 4L),
    list(data = prepared$semantic_panel_links, type = "panel links", priority = 5L),
    list(data = prepared$sources, type = "source/catalog profile", priority = 6L),
    list(data = prepared$legacy_reference_vs_current, type = "legacy/reference evidence", priority = 7L)
  )
  out <- list()
  for (frame in frames) {
    hits <- mcl_triangle_match_info(
      frame$data,
      columns = mcl_triangle_frame_columns(frame$type),
      terms = terms,
      max_rows = max_rows_per_source
    )
    if (!nrow(hits)) next
    if (frame$type %in% c("source/catalog profile", "legacy/reference evidence") && length(source_filters)) {
      keep <- vapply(seq_len(nrow(hits)), function(i) mcl_triangle_source_filter_match(hits[i, , drop = FALSE], source_filters), logical(1))
      hits <- hits[keep, , drop = FALSE]
      if (!nrow(hits)) next
    }
    rows <- lapply(seq_len(nrow(hits)), function(i) {
      out <- mcl_triangle_inventory_row(
        concept = concept,
        row = hits[i, , drop = FALSE],
        evidence_type = frame$type,
        evidence_priority = frame$priority,
        matched_term = hits$.matched_term[[i]] %||% "",
        matched_field = hits$.matched_field[[i]] %||% "",
        sources = prepared$sources,
        canonical_reconciliation = prepared$canonical_reconciliation,
        legacy_reference_vs_current = prepared$legacy_reference_vs_current
      )
      if (is.null(out) || !mcl_triangle_inventory_allowed(out)) return(NULL)
      out
    })
    out[[length(out) + 1L]] <- bind_rows_base(rows)
  }
  out <- bind_rows_base(out)
  if (!nrow(out)) return(mcl_triangle_empty_variable_inventory())
  key <- paste(out$concept_group, out$concept_name, out$source, out$table_or_source, out$raw_field, out$code_or_value, out$evidence_type, sep = "\r")
  out <- out[!duplicated(key), , drop = FALSE]
  order_cols <- order(out$evidence_priority, !out$current_profiled_this_run, out$concept_group, out$concept_name)
  align_mcl <- names(mcl_triangle_empty_variable_inventory())
  out <- out[order_cols, , drop = FALSE]
  missing <- setdiff(align_mcl, names(out))
  for (nm in missing) out[[nm]] <- NA
  out[align_mcl]
}

mcl_triangle_prepare_sources <- function(semantic_dictionary = NULL, semantic_value_map = NULL,
                                         semantic_code_map = NULL, semantic_panel_links = NULL,
                                         columns = NULL, column_profiles = NULL,
                                         sources = NULL, canonical_reconciliation = NULL,
                                         legacy_reference_vs_current = NULL) {
  if (!is.data.frame(semantic_dictionary)) semantic_dictionary <- empty_semantic_data_dictionary()
  if (!is.data.frame(semantic_value_map)) semantic_value_map <- empty_semantic_value_map()
  if (!is.data.frame(semantic_code_map)) semantic_code_map <- empty_semantic_code_map()
  if (!is.data.frame(semantic_panel_links)) semantic_panel_links <- empty_semantic_panel_links()
  if (!is.data.frame(columns)) columns <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(column_profiles)) column_profiles <- data.frame(stringsAsFactors = FALSE)
  column_evidence <- bind_rows_base(list(column_profiles, columns))
  if (!is.data.frame(sources)) sources <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(canonical_reconciliation)) canonical_reconciliation <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(legacy_reference_vs_current)) legacy_reference_vs_current <- data.frame(stringsAsFactors = FALSE)
  list(
    semantic_dictionary = semantic_dictionary,
    semantic_value_map = semantic_value_map,
    semantic_code_map = semantic_code_map,
    semantic_panel_links = semantic_panel_links,
    column_evidence = column_evidence,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current,
    semantic_text = mcl_triangle_text_for_frame(semantic_dictionary, c("semantic_id", "clinical_concept_id", "clinical_variable", "semantic_meaning", "raw_column", "raw_descriptor", "raw_code", "raw_value", "code_system", "clinical_caveat", "search_terms")),
    value_text = mcl_triangle_text_for_frame(semantic_value_map, c("semantic_id", "clinical_concept_id", "clinical_variable", "raw_column", "raw_value", "display_value", "value_class", "clinical_interpretation", "notes")),
    code_text = mcl_triangle_text_for_frame(semantic_code_map, c("semantic_id", "clinical_concept_id", "clinical_variable", "code_system", "code", "code_name", "panel", "notes")),
    panel_text = mcl_triangle_text_for_frame(semantic_panel_links, c("semantic_id", "clinical_concept_id", "panel_id", "panel_section", "relationship")),
    source_text = mcl_triangle_text_for_frame(sources, c("table_name", "source", "source_label", "domain", "subdomain", "atlas_role", "load_status")),
    legacy_text = mcl_triangle_text_for_frame(legacy_reference_vs_current, c("evidence_source", "evidence_type", "canonical_resource_id", "current_source_key", "warning_needed", "notes", "evidence_freshness_status"))
  )
}

mcl_triangle_filter_group <- function(inventory, group_pattern = "", name_pattern = "") {
  if (!is.data.frame(inventory) || !nrow(inventory)) return(mcl_triangle_empty_variable_inventory())
  group_hit <- if (nzchar(group_pattern)) grepl(group_pattern, inventory$concept_group, ignore.case = TRUE) else TRUE
  name_hit <- if (nzchar(name_pattern)) grepl(name_pattern, inventory$concept_name, ignore.case = TRUE) else TRUE
  inventory[group_hit & name_hit, , drop = FALSE]
}

mcl_triangle_has_current <- function(rows) {
  is.data.frame(rows) && nrow(rows) && any(rows$current_profiled_this_run, na.rm = TRUE)
}

mcl_triangle_has_any <- function(rows) {
  is.data.frame(rows) && nrow(rows)
}

mcl_triangle_has_legacy_only <- function(rows) {
  is.data.frame(rows) && nrow(rows) && any(rows$legacy_reference_only, na.rm = TRUE) && !any(rows$current_profiled_this_run, na.rm = TRUE)
}

mcl_triangle_display_inventory <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows)) return(mcl_triangle_empty_variable_inventory())
  if (!"evidence_category" %in% names(rows)) rows$evidence_category <- "direct_variable_evidence"
  keep <- !rows$evidence_category %in% c("source_space_only", "false_positive_excluded")
  rows <- rows[keep, , drop = FALSE]
  if (!nrow(rows)) return(mcl_triangle_empty_variable_inventory())
  rows
}

mcl_triangle_candidate_list <- function(rows, max_items = 8L) {
  if (!is.data.frame(rows) || !nrow(rows)) return("")
  vals <- unique(trimws(c(rows$raw_field, rows$code_or_value, rows$table_or_source, rows$source)))
  vals <- vals[nzchar(vals)]
  paste(head(vals, max_items), collapse = "; ")
}

mcl_triangle_requirement_status <- function(rows, proxy_rows = NULL, preferred_source = "",
                                            not_found_action = "Map source-specific fields or activate likely source.",
                                            legacy_action = "Refresh this evidence in the current run or validate the legacy/reference row.") {
  proxy_rows <- proxy_rows %||% mcl_triangle_empty_variable_inventory()
  direct_any <- mcl_triangle_has_any(rows)
  proxy_any <- mcl_triangle_has_any(proxy_rows)
  direct_current <- mcl_triangle_has_current(rows)
  proxy_current <- mcl_triangle_has_current(proxy_rows)
  legacy_only <- mcl_triangle_has_legacy_only(rows) || (direct_any && !direct_current)
  if (direct_current) {
    status <- "aggregate_evidence_found_requires_validation"
    limitation <- "Direct aggregate evidence is current-profiled but still requires source-specific validation."
    action <- "Define operational study windows and source-specific variable logic."
  } else if (proxy_current) {
    status <- "proxy_available"
    limitation <- "A current-profiled proxy exists, but direct study variable mapping is incomplete."
    action <- "Validate proxy definition against source documentation."
  } else if (direct_any && legacy_only) {
    status <- "legacy_reference_only"
    limitation <- "Evidence is present only in legacy/reference cartography or an unrefreshed source."
    action <- legacy_action
  } else if (proxy_any) {
    status <- "feasible_with_mapping"
    limitation <- "Candidate proxy/reference rows exist but need source-specific mapping."
    action <- "Map candidate rows and refresh the relevant source."
  } else {
    status <- "not_found"
    limitation <- "No aggregate atlas evidence found for this requirement."
    action <- not_found_action
  }
  data.frame(
    readiness_status = status,
    direct_variable_available = direct_any,
    proxy_available = proxy_any,
    current_profiled_evidence = direct_current || proxy_current,
    legacy_reference_only_evidence = legacy_only,
    preferred_source = preferred_source,
    candidate_fields_or_codes = mcl_triangle_candidate_list(bind_rows_base(list(rows, proxy_rows))),
    key_limitation = limitation,
    recommended_next_action = action,
    stringsAsFactors = FALSE
  )
}

mcl_triangle_ki67_direct_rows <- function(ki67_discovery) {
  inventory <- ki67_discovery$search_inventory %||% ki67_empty_search_inventory()
  if (!is.data.frame(inventory) || !nrow(inventory)) return(ki67_empty_search_inventory())
  inventory <- ki67_align_search_inventory(inventory)
  inventory[inventory$evidence_strength %in% c("strong_direct", "moderate_direct") &
    inventory$evidence_type != "source_only_not_evidence", , drop = FALSE]
}

mcl_triangle_ki67_source_only_rows <- function(ki67_discovery) {
  inventory <- ki67_discovery$search_inventory %||% ki67_empty_search_inventory()
  if (!is.data.frame(inventory) || !nrow(inventory)) return(ki67_empty_search_inventory())
  inventory <- ki67_align_search_inventory(inventory)
  inventory[inventory$evidence_strength == "source_only" | inventory$evidence_type == "source_only_not_evidence", , drop = FALSE]
}

mcl_triangle_ki67_status <- function(ki67_discovery = NULL) {
  if (is.null(ki67_discovery)) ki67_discovery <- ki67_empty_payload()
  db_summary <- ki67_discovery$db_summary %||% ki67_discovery$ki67_db_summary %||% data.frame(stringsAsFactors = FALSE)
  if (is.data.frame(db_summary) && nrow(db_summary) && all(c("channel", "direct_evidence_found", "numeric_percent_found") %in% names(db_summary))) {
    direct_flag <- tolower(trimws(as.character(db_summary$direct_evidence_found %||% ""))) %in% c("true", "t", "1", "yes")
    numeric_flag <- tolower(trimws(as.character(db_summary$numeric_percent_found %||% ""))) %in% c("true", "t", "1", "yes")
    aeki <- db_summary[db_summary$channel == "danish_patobank_aeki_codes" & direct_flag & numeric_flag, , drop = FALSE]
    registry <- db_summary[db_summary$channel == "structured_registry_fields" & direct_flag & numeric_flag, , drop = FALSE]
    text <- db_summary[db_summary$channel == "pathology_text_patterns" & direct_flag & numeric_flag, , drop = FALSE]
    if (nrow(registry) || nrow(aeki) || nrow(text)) {
      selected <- if (nrow(registry)) registry[1, , drop = FALSE] else if (nrow(aeki)) aeki[1, , drop = FALSE] else text[1, , drop = FALSE]
      status <- if (nrow(registry)) "strong_structured_numeric" else if (nrow(aeki)) "strong_structured_coded" else "moderate_text_extractable"
      return(list(
        status = status,
        direct_rows = nrow(selected),
        source_only_rows = 0L,
        direct_current = TRUE,
        numeric_direct = TRUE,
        coded_direct = nrow(aeki) > 0L,
        text_extractable = nrow(text) > 0L,
        best_source = as.character((selected$best_source %||% "")[[1]] %||% ""),
        aggregate_count_display = as.character((selected$aggregate_count_display %||% selected$aggregate_count_total %||% "")[[1]] %||% "")
      ))
    }
  }
  pathology <- ki67_discovery$pathology_code_candidates %||% ki67_empty_pathology_code_candidates()
  text_patterns <- ki67_discovery$text_pattern_candidates %||% ki67_empty_text_pattern_candidates()
  direct <- mcl_triangle_ki67_direct_rows(ki67_discovery)
  source_only <- mcl_triangle_ki67_source_only_rows(ki67_discovery)
  direct_current <- nrow(direct) && !all(grepl("legacy/reference", direct$artifact_or_source, ignore.case = TRUE))
  numeric_direct <- nrow(direct) && any(direct$value_class %in% c("exact_numeric_percent", "range_percent", "inequality_percent") | direct$candidate_numeric_value_available, na.rm = TRUE)
  coded_direct <- nrow(pathology) && any(pathology$evidence_strength == "strong_direct" & pathology$is_observation_code %in% c("true", "TRUE", TRUE), na.rm = TRUE)
  text_direct <- nrow(direct) && any(grepl("text|mikro|konk|pathology|pato|conclusion|microscopy", paste(direct$file_or_table, direct$matched_field_or_column, direct$resource_id), ignore.case = TRUE), na.rm = TRUE)
  text_extractable <- nrow(text_patterns) && any(text_patterns$numeric_extraction_possible & text_patterns$false_positive_risk != "high", na.rm = TRUE) && text_direct
  status <- if (numeric_direct) {
    "strong_structured_numeric"
  } else if (coded_direct) {
    "strong_structured_coded"
  } else if (text_extractable) {
    "moderate_text_extractable"
  } else if (nrow(direct)) {
    "requires_manual_validation"
  } else if (nrow(source_only)) {
    "weak_candidate_only"
  } else {
    "not_found"
  }
  best <- if (nrow(direct)) {
    paste(unique(head(direct$file_or_table[nzchar(direct$file_or_table)], 4)), collapse = "; ")
  } else if (nrow(source_only)) {
    visible <- source_only[source_only$display_in_ui %in% TRUE, , drop = FALSE]
    if (!nrow(visible)) visible <- head(source_only, 4)
    paste(unique(head(visible$ui_group[nzchar(visible$ui_group)], 4)), collapse = "; ")
  } else {
    ""
  }
  list(
    status = status,
    direct_rows = direct,
    source_only_rows = source_only,
    direct_current = isTRUE(direct_current),
    numeric_direct = isTRUE(numeric_direct),
    coded_direct = isTRUE(coded_direct),
    text_extractable = isTRUE(text_extractable),
    best_source = best,
    evidence_count = nrow(direct),
    source_only_count = nrow(source_only)
  )
}

mcl_triangle_build_readiness_matrix <- function(inventory, ki67_discovery = NULL) {
  ki67 <- mcl_triangle_ki67_status(ki67_discovery)
  reqs <- list(
    list("MCL cohort", mcl_triangle_filter_group(inventory, "Cohort", "mantle|MCL|LYFO"), NULL, "RKKP_LYFO"),
    list("younger/transplant-eligible proxy", mcl_triangle_filter_group(inventory, "Eligibility", "age|performance|stage|transplant"), NULL, "RKKP_LYFO; diagnosis and treatment date sources"),
    list("first-line treatment timing", mcl_triangle_filter_group(inventory, "Eligibility|Treatment|Outcomes", "diagnosis date|treatment start|stem-cell infusion|death|relapse|progression"), NULL, "LYFO, treatment, procedure, death/follow-up sources"),
    list("CIT / immunochemotherapy", mcl_triangle_filter_group(inventory, "Treatment", "CIT|immunochemotherapy|R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine|regimen"), NULL, "LYFO treatment/regimen, medication, SKS procedure sources"),
    list("ASCT/HDT", mcl_triangle_filter_group(inventory, "Treatment", "ASCT|HDT|stem-cell|autologous"), NULL, "LYFO HDT/stem-cell fields; SKS transplant procedure signals"),
    list("ibrutinib", mcl_triangle_filter_group(inventory, "Treatment", "ibrutinib|BTK"), NULL, "ATC/SKS/medication sources"),
    list("OS/death", mcl_triangle_filter_group(inventory, "Outcomes", "death|overall survival"), NULL, "patient/death/follow-up sources"),
    list("relapse/progression/FFS proxy", mcl_triangle_filter_group(inventory, "Outcomes", "relapse|progression|failure|next treatment|response|follow-up"), NULL, "LYFO response/status and treatment-line sources"),
    list("blastoid morphology", mcl_triangle_filter_group(inventory, "High-risk biology", "blastoid"), mcl_triangle_filter_group(inventory, "High-risk biology", "morphology|pathology"), "LYFO WHO/histology, PATOBANK, t_mikro, t_konk"),
    list("TP53 / p53 / del17p", mcl_triangle_filter_group(inventory, "High-risk biology", "TP53|p53|del17p"), mcl_triangle_filter_group(inventory, "High-risk biology", "FISH|molecular|pathology"), "pathology text, molecular/FISH resources, RKKP fields"),
    list("Ki-67", mcl_triangle_filter_group(inventory, "High-risk biology", "Ki-67|proliferation"), NULL, "structured LYFO fields; Danish pathology/SNOMED codes; t_mikro/t_konk text extraction"),
    list("MIPI", mcl_triangle_filter_group(inventory, "High-risk biology", "^MIPI$|MIPI score"), mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", "age|performance|LDH|leukocyte"), "LYFO/RKKP fields or reconstruction inputs"),
    list("MIPI-c", mcl_triangle_filter_group(inventory, "High-risk biology", "MIPI-c"), mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", "MIPI|Ki-67|age|performance|LDH|leukocyte"), "MIPI components plus Ki-67"),
    list("toxicity proxies", mcl_triangle_filter_group(inventory, "Safety", "admission|ICU|infection|neutropenic|antibiotic|hospitalisation|transfusion"), NULL, "ADT/admission, microbiology, medication, transfusion sources")
  )
  rows <- lapply(reqs, function(req) {
    if (identical(req[[1]], "Ki-67")) {
      direct_available <- ki67$status %in% c("strong_structured_numeric", "strong_structured_coded")
      proxy_available <- identical(ki67$status, "moderate_text_extractable")
      key_limitation <- switch(
        ki67$status,
        strong_structured_numeric = "Direct structured Ki-67 percent evidence candidate found; validate source definition and units.",
        strong_structured_coded = "Direct aggregate Danish pathology code evidence exists, but source-specific clinical validation is required before analytic cohort extraction.",
        moderate_text_extractable = "Ki-67 text extraction appears possible but requires validation and no raw report text is emitted.",
        requires_manual_validation = "Ki-67 candidate evidence requires manual validation before study use.",
        weak_candidate_only = "Only source/search-space evidence is present; source availability is not direct Ki-67 evidence.",
        not_tested_fixture = "Ki-67 discovery was not tested in this fixture run.",
        "No Ki-67-specific aggregate atlas evidence found."
      )
      return(data.frame(
        study_requirement = "Ki-67",
        readiness_status = ki67$status,
        direct_variable_available = direct_available,
        proxy_available = proxy_available,
        current_profiled_evidence = isTRUE(ki67$direct_current) && (direct_available || proxy_available),
        legacy_reference_only_evidence = FALSE,
        preferred_source = "LYFO structured fields; Danish pathology/SNOMED; t_mikro/t_konk text",
        candidate_fields_or_codes = ki67$best_source,
        key_limitation = key_limitation,
        recommended_next_action = if (direct_available) "Validate Danish Patobank Ki-67 coding/value semantics, source scope, and MCL applicability before analytic cohort extraction." else "Run source-specific Ki-67 codebook lookup and validated text-extraction pilot.",
        stringsAsFactors = FALSE
      ))
    }
    status <- mcl_triangle_requirement_status(
      rows = req[[2]],
      proxy_rows = req[[3]] %||% NULL,
      preferred_source = req[[4]],
      not_found_action = "Needs source activation or mapping.",
      legacy_action = "Needs source activation or mapping before feasibility can be treated as refreshed evidence."
    )
    data.frame(study_requirement = req[[1]], status, stringsAsFactors = FALSE)
  })
  out <- bind_rows_base(rows)
  align <- names(mcl_triangle_empty_study_readiness_matrix())
  missing <- setdiff(align, names(out))
  for (nm in missing) out[[nm]] <- NA
  out[align]
}

mcl_triangle_biology_recovery_source <- function(marker) {
  key <- tolower(marker)
  if (grepl("blastoid|pleomorphic", key)) return("LYFO WHO/histology fields; PATOBANK codes; t_mikro; t_konk")
  if (grepl("tp53|p53|del17p", key)) return("pathology text; molecular/FISH resources; RKKP fields if present")
  if (grepl("ki", key)) return("pathology text; microscopy/conclusion text; possible LYFO fields")
  if (grepl("mipi-c", key)) return("MIPI reconstruction inputs plus Ki-67")
  if (grepl("mipi", key)) return("age, ECOG/performance status, LDH, leukocytes")
  if (grepl("ldh", key)) return("Laboratory/NPU and LYFO registry fields")
  if (grepl("leukocyte", key)) return("Laboratory/NPU and LYFO registry fields")
  if (grepl("performance|ecog", key)) return("LYFO performance status/ECOG fields")
  "source-specific mapping"
}

mcl_triangle_build_biology_gap_analysis <- function(inventory, ki67_discovery = NULL) {
  markers <- c("blastoid morphology", "pleomorphic morphology", "TP53", "p53", "del17p", "Ki-67", "MIPI", "MIPI-c", "LDH", "leukocytes", "performance status", "age")
  ki67 <- mcl_triangle_ki67_status(ki67_discovery)
  rows <- lapply(markers, function(marker) {
    if (identical(marker, "Ki-67")) {
      ready_status <- switch(
        ki67$status,
        strong_structured_numeric = "aggregate_evidence_found_requires_validation",
        strong_structured_coded = "aggregate_evidence_found_requires_validation",
        moderate_text_extractable = "feasible_with_mapping",
        requires_manual_validation = "requires_manual_validation",
        weak_candidate_only = "weak_candidate_only",
        not_tested_fixture = "not_tested_fixture",
        not_found = "not_found",
        ki67$status
      )
      return(data.frame(
        marker = marker,
        direct_variable_found = ki67$status %in% c("strong_structured_numeric", "strong_structured_coded"),
        indirect_proxy_found = identical(ki67$status, "moderate_text_extractable"),
        current_profiled_source_available = isTRUE(ki67$direct_current),
        legacy_reference_only = FALSE,
        preferred_recovery_source = mcl_triangle_biology_recovery_source(marker),
        action_required = if (ki67$status %in% c("strong_structured_numeric", "strong_structured_coded")) "Validate source-specific definition and coding before cohort extraction." else "Needs source activation, codebook lookup, or validated Ki-67 text extraction.",
        feasibility_status = ready_status,
        notes = paste(
          "Ki-67 discovery status:", ki67$status,
          if (ki67$status %in% c("strong_structured_numeric", "strong_structured_coded")) "- direct aggregate evidence found, but source-specific clinical validation is required before analytic cohort extraction." else "- source-only pathology/LYFO availability is not treated as Ki-67 evidence.",
          if (nzchar(ki67$best_source)) paste("Best aggregate source:", ki67$best_source) else ""
        ),
        stringsAsFactors = FALSE
      ))
    }
    direct <- mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", marker)
    if (!nrow(direct) && identical(marker, "p53")) direct <- mcl_triangle_filter_group(inventory, "High-risk biology", "TP53|p53")
    if (!nrow(direct) && identical(marker, "del17p")) direct <- mcl_triangle_filter_group(inventory, "High-risk biology", "del17p|17p")
    proxy <- mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", if (marker %in% c("MIPI", "MIPI-c")) "age|performance|LDH|leukocyte|Ki-67" else "pathology|morphology|FISH|molecular")
    direct_found <- mcl_triangle_has_any(direct)
    proxy_found <- !direct_found && mcl_triangle_has_any(proxy)
    current <- mcl_triangle_has_current(direct) || (!direct_found && mcl_triangle_has_current(proxy))
    legacy <- mcl_triangle_has_legacy_only(direct) || (!direct_found && mcl_triangle_has_legacy_only(proxy))
    status <- if (direct_found && current) {
      "aggregate_evidence_found_requires_validation"
    } else if (proxy_found && current) {
      "proxy_available"
    } else if (direct_found || proxy_found) {
      "legacy_reference_only"
    } else {
      "needs_source_activation"
    }
    action <- if (status %in% c("aggregate_evidence_found_requires_validation", "proxy_available")) {
      "Validate source-specific definition and coding before cohort extraction."
    } else {
      "Needs source activation or mapping."
    }
    data.frame(
      marker = marker,
      direct_variable_found = direct_found,
      indirect_proxy_found = proxy_found,
      current_profiled_source_available = current,
      legacy_reference_only = legacy,
      preferred_recovery_source = mcl_triangle_biology_recovery_source(marker),
      action_required = action,
      feasibility_status = status,
      notes = if (status %in% c("aggregate_evidence_found_requires_validation", "proxy_available")) "Aggregate evidence exists and requires source-specific validation; no patient-level inference is made." else "High-risk biology remains a feasibility gap until source activation/mapping is complete.",
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  out[names(mcl_triangle_empty_biology_gap_analysis())]
}

mcl_triangle_exposure_group <- function(concept_name) {
  ifelse(grepl("ibrutinib|BTK", concept_name, ignore.case = TRUE), "BTK inhibitor",
    ifelse(grepl("ASCT|HDT|stem-cell|autologous", concept_name, ignore.case = TRUE), "ASCT/HDT",
      ifelse(grepl("R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine|CIT|regimen|immunochemotherapy", concept_name, ignore.case = TRUE), "CIT / immunochemotherapy", "Treatment exposure")
    )
  )
}

mcl_triangle_outcome_role <- function(concept_name) {
  ifelse(grepl("death|overall survival", concept_name, ignore.case = TRUE), "OS/death",
    ifelse(grepl("relapse|progression|response|next treatment|follow-up", concept_name, ignore.case = TRUE), "relapse/progression/FFS proxy", "toxicity proxy")
  )
}

mcl_triangle_join_values <- function(x, max_items = 5L) {
  x <- unique(trimws(as.character(x %||% "")))
  x <- x[nzchar(x)]
  if (!length(x)) return("")
  suffix <- if (length(x) > max_items) paste0(" +", length(x) - max_items, " more") else ""
  paste0(paste(head(x, max_items), collapse = "; "), suffix)
}

mcl_triangle_summarize_keys <- function(rows, key_cols) {
  if (!is.data.frame(rows) || !nrow(rows)) return(integer())
  key_cols <- intersect(key_cols, names(rows))
  if (!length(key_cols)) return(rep(1L, nrow(rows)))
  key_values <- rows[key_cols]
  key_values[] <- lapply(key_values, mcl_triangle_norm)
  key <- do.call(paste, c(key_values, sep = "\r"))
  as.integer(factor(key, levels = unique(key)))
}

mcl_triangle_false_positive_exclusions <- function(inventory = NULL) {
  static <- mcl_triangle_known_false_positive_exclusions()
  if (!is.data.frame(inventory) || !nrow(inventory) || !"evidence_category" %in% names(inventory)) {
    return(static[names(mcl_triangle_empty_false_positive_exclusions())])
  }
  excluded <- inventory[inventory$evidence_category == "false_positive_excluded", , drop = FALSE]
  if (!nrow(excluded)) return(static[names(mcl_triangle_empty_false_positive_exclusions())])
  dynamic <- data.frame(
    concept_name = excluded$concept_name,
    source = excluded$source,
    field = excluded$raw_field,
    value = excluded$code_or_value,
    reason = excluded$match_reason,
    exclusion_type = "matched_false_positive_excluded",
    notes = "Matched during evidence collection but suppressed from main MCL/TRIANGLE UI evidence cards.",
    stringsAsFactors = FALSE
  )
  out <- bind_rows_base(list(static, dynamic))
  key <- paste(out$concept_name, out$source, out$field, out$value, out$reason, sep = "\r")
  out <- out[!duplicated(key), , drop = FALSE]
  out[names(mcl_triangle_empty_false_positive_exclusions())]
}

mcl_triangle_treatment_inventory <- function(inventory) {
  rows <- mcl_triangle_display_inventory(mcl_triangle_filter_group(inventory, "Treatment", ""))
  if (!nrow(rows)) return(mcl_triangle_empty_treatment_inventory())
  rows$exposure_group <- mcl_triangle_exposure_group(rows$concept_name)
  groups <- split(rows, mcl_triangle_summarize_keys(rows, c("concept_name", "exposure_group", "source", "table_or_source", "evidence_category")), drop = TRUE)
  out <- lapply(groups, function(group) {
    fields <- mcl_triangle_join_values(c(group$raw_field, group$code_or_value))
    evidence_types <- mcl_triangle_join_values(group$evidence_type, 4L)
    categories <- mcl_triangle_join_values(group$evidence_category, 4L)
    match_reasons <- mcl_triangle_join_values(group$match_reason, 3L)
    data.frame(
      exposure_name = group$concept_name[[1]],
      exposure_group = group$exposure_group[[1]],
      source = group$source[[1]],
      code_system = mcl_triangle_join_values(group$code_or_value[grepl("ATC|SKS|NPU|L[0-9]|BWHA", group$code_or_value, ignore.case = TRUE)], 3L),
      code = mcl_triangle_join_values(group$code_or_value, 4L),
      raw_value = mcl_triangle_join_values(group$code_or_value, 4L),
      table_or_source = group$table_or_source[[1]],
      raw_field = mcl_triangle_join_values(group$raw_field, 5L),
      matched_term = mcl_triangle_join_values(group$matched_term, 4L),
      matched_field = mcl_triangle_join_values(group$matched_field, 4L),
      match_reason = match_reasons,
      evidence_category = categories,
      current_profiled_this_run = any(group$current_profiled_this_run, na.rm = TRUE),
      evidence_count_or_rows = as.character(nrow(group)),
      count_type = "evidence rows",
      notes = paste0(
        if (nzchar(fields)) paste0("Representative fields/codes: ", fields, ". ") else "",
        if (nzchar(evidence_types)) paste0("Evidence channels: ", evidence_types, ". ") else "",
        if (nzchar(categories)) paste0("Evidence category: ", categories, ". ") else "",
        if (nzchar(match_reasons)) paste0("Match reason: ", match_reasons, ". ") else "",
        nrow(group), " detail evidence row", if (nrow(group) == 1L) "" else "s",
        " summarized from mcl_triangle_variable_inventory.csv."
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(out)
  out[names(mcl_triangle_empty_treatment_inventory())]
}

mcl_triangle_outcome_inventory <- function(inventory) {
  rows <- mcl_triangle_display_inventory(mcl_triangle_filter_group(inventory, "Outcomes|Safety", ""))
  if (!nrow(rows)) return(mcl_triangle_empty_outcome_inventory())
  rows$feasibility_role <- mcl_triangle_outcome_role(rows$concept_name)
  groups <- split(rows, mcl_triangle_summarize_keys(rows, c("concept_name", "feasibility_role", "source", "table_or_source", "evidence_category")), drop = TRUE)
  out <- lapply(groups, function(group) {
    fields <- mcl_triangle_join_values(group$raw_field)
    evidence_types <- mcl_triangle_join_values(group$evidence_type, 4L)
    categories <- mcl_triangle_join_values(group$evidence_category, 4L)
    match_reasons <- mcl_triangle_join_values(group$match_reason, 3L)
    data.frame(
      outcome_name = group$concept_name[[1]],
      source = group$source[[1]],
      table_or_source = group$table_or_source[[1]],
      raw_field = fields,
      matched_term = mcl_triangle_join_values(group$matched_term, 4L),
      matched_field = mcl_triangle_join_values(group$matched_field, 4L),
      match_reason = match_reasons,
      evidence_category = categories,
      current_profiled_this_run = any(group$current_profiled_this_run, na.rm = TRUE),
      legacy_reference_only = any(group$legacy_reference_only, na.rm = TRUE),
      feasibility_role = group$feasibility_role[[1]],
      count_or_rows_if_available = as.character(nrow(group)),
      count_type = "evidence rows",
      notes = paste0(
        if (nzchar(fields)) paste0("Representative fields/codes: ", fields, ". ") else "",
        if (nzchar(evidence_types)) paste0("Evidence channels: ", evidence_types, ". ") else "",
        if (nzchar(categories)) paste0("Evidence category: ", categories, ". ") else "",
        if (nzchar(match_reasons)) paste0("Match reason: ", match_reasons, ". ") else "",
        nrow(group), " detail evidence row", if (nrow(group) == 1L) "" else "s",
        " summarized from mcl_triangle_variable_inventory.csv."
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(out)
  out[names(mcl_triangle_empty_outcome_inventory())]
}

mcl_triangle_verdict <- function(matrix, biology) {
  status_for <- function(req) {
    hit <- matrix[matrix$study_requirement == req, , drop = FALSE]
    if (nrow(hit)) hit$readiness_status[[1]] else "not_found"
  }
  biology_direct_current <- function(marker) {
    hit <- biology[biology$marker == marker, , drop = FALSE]
    if (!nrow(hit)) return(FALSE)
    isTRUE(as.logical(hit$direct_variable_found[[1]])) &&
      isTRUE(as.logical(hit$current_profiled_source_available[[1]])) &&
      !isTRUE(as.logical(hit$legacy_reference_only[[1]]))
  }
  readyish <- function(status) status %in% c("ready", "aggregate_evidence_found_requires_validation", "proxy_available", "feasible_with_mapping")
  core <- c(
    status_for("MCL cohort"),
    status_for("CIT / immunochemotherapy"),
    status_for("ASCT/HDT"),
    status_for("ibrutinib"),
    status_for("OS/death")
  )
  biology_core <- biology[biology$marker %in% c("blastoid morphology", "TP53", "p53", "del17p", "Ki-67", "MIPI-c"), , drop = FALSE]
  biology_ready_count <- sum(biology_core$feasibility_status %in% c("ready", "proxy_available"), na.rm = TRUE)
  essential_biology_ready <- all(c("blastoid morphology", "TP53", "Ki-67") %in% biology$marker[biology$feasibility_status == "ready"]) &&
    all(vapply(c("blastoid morphology", "TP53", "Ki-67"), biology_direct_current, logical(1))) &&
    status_for("Ki-67") == "ready"
  if (!readyish(status_for("MCL cohort"))) {
    return(c(verdict = "Not currently feasible", rationale = "MCL cohort evidence is absent or unusable in the aggregate atlas outputs."))
  }
  if (all(readyish(core)) && essential_biology_ready && biology_ready_count >= 4L) {
    return(c(verdict = "Strongly feasible", rationale = "Cohort, key treatments, outcomes, and core high-risk biology markers have current-profiled direct evidence."))
  }
  if (all(readyish(core))) {
    return(c(verdict = "Feasible with biology gaps", rationale = "Cohort, key treatment, and outcome evidence exist, but high-risk biology is incomplete, proxy-only, or legacy/reference-only."))
  }
  c(verdict = "Partially feasible", rationale = "MCL cohort evidence exists, but treatment or outcome evidence is incomplete in current aggregate outputs.")
}

mcl_triangle_summary <- function(inventory, treatment, outcome, biology, matrix, verdict) {
  metric_row <- function(metric, label, status, rows, notes = "") {
    data.frame(
      metric = metric,
      label = label,
      value = as.character(if (is.data.frame(rows)) nrow(rows) else rows),
      status = status,
      count_type = if (is.data.frame(rows)) "aggregate evidence rows" else "derived verdict",
      evidence_count = if (is.data.frame(rows)) nrow(rows) else NA_integer_,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  ki67_row <- biology[biology$marker == "Ki-67", , drop = FALSE]
  ki67_status <- if (nrow(ki67_row)) ki67_row$feasibility_status[[1]] else "not_found"
  ki67_evidence_count <- if (nrow(ki67_row) && isTRUE(as.logical(ki67_row$direct_variable_found[[1]]))) 1L else 0L
  rows <- list(
    metric_row("overall_feasibility_rating", "Overall feasibility rating", verdict[["verdict"]], verdict[["verdict"]], verdict[["rationale"]]),
    metric_row("mcl_cohort_evidence_found", "MCL cohort evidence found", if (nrow(mcl_triangle_filter_group(inventory, "Cohort", "mantle|MCL"))) "found" else "not_found", mcl_triangle_filter_group(inventory, "Cohort", "mantle|MCL")),
    metric_row("lyfo_mcl_subtype_evidence_found", "LYFO MCL subtype evidence found", if (nrow(mcl_triangle_filter_group(inventory, "Cohort", "LYFO|subtype|MCL"))) "found" else "not_found", mcl_triangle_filter_group(inventory, "Cohort", "LYFO|subtype|MCL")),
    metric_row("current_profiled_mcl_source_available", "Current-profiled MCL source available", if (any(mcl_triangle_filter_group(inventory, "Cohort", "mantle|MCL")$current_profiled_this_run, na.rm = TRUE)) "yes" else "no", sum(mcl_triangle_filter_group(inventory, "Cohort", "mantle|MCL")$current_profiled_this_run, na.rm = TRUE)),
    metric_row("asct_hdt_evidence_found", "ASCT/HDT evidence found", if (any(grepl("ASCT|HDT|stem-cell|autologous", treatment$exposure_name, ignore.case = TRUE))) "found" else "not_found", treatment[grepl("ASCT|HDT|stem-cell|autologous", treatment$exposure_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("ibrutinib_evidence_found", "Ibrutinib evidence found", if (any(grepl("ibrutinib|BTK", treatment$exposure_name, ignore.case = TRUE))) "found" else "not_found", treatment[grepl("ibrutinib|BTK", treatment$exposure_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("cit_regimen_evidence_found", "CIT/regimen evidence found", if (any(grepl("CIT|immunochemotherapy|R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine|regimen", treatment$exposure_name, ignore.case = TRUE))) "found" else "not_found", treatment[grepl("CIT|immunochemotherapy|R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine|regimen", treatment$exposure_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("relapse_progression_evidence_found", "Relapse/progression evidence found", if (any(grepl("relapse|progression|FFS", outcome$outcome_name, ignore.case = TRUE))) "found" else "not_found", outcome[grepl("relapse|progression|FFS", outcome$outcome_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("death_os_evidence_found", "Death/OS evidence found", if (any(grepl("death|overall survival", outcome$outcome_name, ignore.case = TRUE))) "found" else "not_found", outcome[grepl("death|overall survival", outcome$outcome_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("ldh_evidence_found", "LDH evidence found", if (any(grepl("LDH", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("LDH", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("leukocyte_evidence_found", "Leukocyte evidence found", if (any(grepl("leukocyte", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("leukocyte", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("performance_status_evidence_found", "Performance-status evidence found", if (any(grepl("performance|ECOG", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("performance|ECOG", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("ki67_evidence_found", "Ki-67 evidence found", ki67_status, ki67_evidence_count, "Ki-67 status is driven by dedicated discovery outputs; source-only pathology/LYFO availability is not direct evidence."),
    metric_row("tp53_evidence_found", "TP53/p53/del17p evidence found", if (any(grepl("TP53|p53|del17p", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("TP53|p53|del17p", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("blastoid_morphology_evidence_found", "Blastoid morphology evidence found", if (any(grepl("blastoid", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("blastoid", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("mipi_direct_evidence_found", "MIPI/MIPI-c direct evidence found", if (any(grepl("MIPI", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("MIPI", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
    metric_row("mipi_reconstructability_status", "MIPI/MIPI-c reconstructability status", matrix$readiness_status[matrix$study_requirement == "MIPI-c"] %||% "not_found", matrix[matrix$study_requirement %in% c("MIPI", "MIPI-c"), , drop = FALSE]),
    metric_row("pathology_text_availability", "Pathology text availability", if (any(grepl("pathology|microscopy|conclusion|t_mikro|t_konk", inventory$source, ignore.case = TRUE))) "candidate_evidence_found" else "not_found", inventory[grepl("pathology|microscopy|conclusion|t_mikro|t_konk", inventory$source, ignore.case = TRUE), , drop = FALSE]),
    metric_row("current_profiled_evidence_rows", "Current-profiled evidence rows", "aggregate_count", sum(inventory$current_profiled_this_run, na.rm = TRUE)),
    metric_row("legacy_reference_only_evidence_rows", "Legacy/reference-only evidence rows", "aggregate_count", sum(inventory$legacy_reference_only, na.rm = TRUE))
  )
  out <- bind_rows_base(rows)
  out[names(mcl_triangle_empty_summary())]
}

mcl_triangle_recommended_actions <- function(matrix, biology) {
  actions <- unique(c(
    matrix$recommended_next_action[matrix$readiness_status %in% c("legacy_reference_only", "needs_source_activation", "not_found", "manual_review_needed", "feasible_with_mapping")],
    biology$action_required[biology$feasibility_status %in% c("legacy_reference_only", "needs_source_activation", "not_found", "manual_review_needed")]
  ))
  actions <- actions[nzchar(actions)]
  defaults <- c(
    "Activate pathology text sources t_mikro and t_konk for morphology/Ki-67/TP53 term mapping.",
    "Map blastoid and pleomorphic morphology terms in LYFO/PATOBANK/pathology aggregate evidence.",
    "Search TP53, p53, del17p, FISH, and molecular resources after source activation.",
    "Run Ki-67 source-specific codebook lookup and validated text-extraction pilot; do not treat pathology-source availability as Ki-67 evidence.",
    "Verify MIPI/MIPI-c reconstructability from age, ECOG/performance status, LDH, leukocytes, and Ki-67.",
    "Define ASCT/HDT exposure windows and ibrutinib exposure timing before any target-trial emulation.",
    "Define relapse/progression/FFS proxy using response, next-treatment, and follow-up disease-status sources."
  )
  actions <- unique(c(actions, defaults))
  data.frame(kind = "recommended_next_action", text = actions, stringsAsFactors = FALSE)
}

mcl_triangle_caveats <- function() {
  data.frame(
    kind = "caveat",
    text = c(
      "This panel supports feasibility assessment only; it does not estimate treatment effects and does not recommend ASCT/HDT or ibrutinib use.",
      "All evidence is aggregate atlas evidence. Counts are row/code/value/source counts unless explicitly labelled as patient counts.",
      "Current-profiled evidence and legacy/reference-only evidence are labelled separately; legacy/reference rows were not necessarily refreshed in this run.",
      "Avoid naive ever/never ASCT comparisons because of immortal-time bias, confounding by indication, treatment eligibility, and response-dependent selection.",
      "Future causal work would require a bias-aware design such as induction-completion landmark analysis or clone-censor-weight target-trial emulation."
    ),
    stringsAsFactors = FALSE
  )
}

mcl_triangle_count_row_display <- function(rows, metric_key, metric_value, display_col = "distinct_person_count_display") {
  if (!is.data.frame(rows) || !nrow(rows) || !metric_key %in% names(rows)) return("")
  hit <- rows[as.character(rows[[metric_key]]) == metric_value, , drop = FALSE]
  if (!nrow(hit) || !display_col %in% names(hit)) return("")
  as.character(hit[[display_col]][[1]] %||% "")
}

mcl_triangle_pathology_ki67_signpost <- function(cohort_counts = NULL) {
  if (!is.list(cohort_counts)) return(mcl_triangle_empty_pathology_ki67_signpost())
  aeki_people <- cohort_counts$ki67_aeki_person_counts %||% data.frame(stringsAsFactors = FALSE)
  known <- mcl_triangle_count_row_display(aeki_people, "metric", "ki67_aeki_known")
  ge30 <- mcl_triangle_count_row_display(aeki_people, "metric", "ki67_aeki_ge_threshold")
  ge50 <- mcl_triangle_count_row_display(aeki_people, "metric", "ki67_aeki_ge_50")
  summary <- cohort_counts$ki67_person_count_summary %||% data.frame(stringsAsFactors = FALSE)
  if (!nzchar(known) && is.data.frame(summary) && nrow(summary) && "distinct_person_count_display" %in% names(summary)) {
    known <- as.character(summary$distinct_person_count_display[[1]] %||% "")
  }
  if (!nzchar(known) && !nzchar(ge30) && !nzchar(ge50)) return(mcl_triangle_empty_pathology_ki67_signpost())
  data.frame(
    title = "Ki-67 proliferation index",
    source_resource = "PATOBANK/SDS pathology",
    table_name = "import.public.SDS_pato",
    column_name = "c_snomedkode",
    code_family = "AEKIxxx / ÆKIxxx",
    interpretation = "xxx encodes a percentage-like Ki-67 proliferation index in structured coded pathology evidence.",
    evidence_type = "coded pathology/PATOBANK evidence",
    current_use_status = "structured coded signal; MCL feasibility count validated",
    mcl_aeki_known = known,
    mcl_aeki_ge30 = ge30,
    mcl_aeki_ge50 = ge50,
    text_recovery_route = "SDS_pato.v_fritekst; SDS_t_mikro_ny.v_fritekst; SDS_t_konk_ny.v_fritekst",
    caveat = "Not yet a complete Ki-67 capture strategy; pathology free text is candidate-only and requires separate extraction and clinical validation.",
    search_terms = "Ki-67;KI67;proliferation index;proliferationsindeks;AEKI;ÆKI;SDS_pato;PATOBANK;c_snomedkode",
    stringsAsFactors = FALSE
  )
}

build_mcl_triangle_feasibility_outputs <- function(project_root = ".",
                                                   semantic_dictionary = NULL,
                                                   semantic_value_map = NULL,
                                                   semantic_code_map = NULL,
                                                   semantic_panel_links = NULL,
                                                   columns = NULL,
                                                   column_profiles = NULL,
                                                   panel_raw_fields = NULL,
                                                   panel_distributions = NULL,
                                                   panel_kpis = NULL,
                                                   sources = NULL,
                                                   canonical_reconciliation = NULL,
                                                   legacy_reference_vs_current = NULL,
                                                   ki67_discovery = NULL) {
  concepts <- mcl_triangle_read_concepts(project_root)
  prepared <- mcl_triangle_prepare_sources(
    semantic_dictionary = semantic_dictionary,
    semantic_value_map = semantic_value_map,
    semantic_code_map = semantic_code_map,
    semantic_panel_links = semantic_panel_links,
    columns = columns,
    column_profiles = column_profiles,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current
  )
  inventory_parts <- lapply(seq_len(nrow(concepts)), function(i) {
    mcl_triangle_collect_evidence(concepts[i, , drop = FALSE], prepared)
  })
  variable_inventory <- bind_rows_base(inventory_parts)
  if (!nrow(variable_inventory)) variable_inventory <- mcl_triangle_empty_variable_inventory()
  if (is.null(ki67_discovery)) {
    ki67_discovery <- build_ki67_discovery_outputs(
      project_root = project_root,
      include_reference_files = FALSE,
      semantic_dictionary = semantic_dictionary,
      semantic_value_map = semantic_value_map,
      semantic_code_map = semantic_code_map,
      semantic_panel_links = semantic_panel_links,
      panel_raw_fields = panel_raw_fields,
      panel_distributions = panel_distributions,
      panel_kpis = panel_kpis,
      sources = sources,
      columns = columns,
      column_profiles = column_profiles,
      canonical_reconciliation = canonical_reconciliation,
      legacy_reference_vs_current = legacy_reference_vs_current
    )
  }
  display_inventory <- mcl_triangle_display_inventory(variable_inventory)
  false_positive_exclusions <- mcl_triangle_false_positive_exclusions(variable_inventory)
  treatment_inventory <- mcl_triangle_treatment_inventory(display_inventory)
  outcome_inventory <- mcl_triangle_outcome_inventory(display_inventory)
  biology_gap_analysis <- mcl_triangle_build_biology_gap_analysis(display_inventory, ki67_discovery = ki67_discovery)
  study_readiness_matrix <- mcl_triangle_build_readiness_matrix(display_inventory, ki67_discovery = ki67_discovery)
  verdict <- mcl_triangle_verdict(study_readiness_matrix, biology_gap_analysis)
  feasibility_summary <- mcl_triangle_summary(
    inventory = display_inventory,
    treatment = treatment_inventory,
    outcome = outcome_inventory,
    biology = biology_gap_analysis,
    matrix = study_readiness_matrix,
    verdict = verdict
  )
  list(
    summary = feasibility_summary,
    variable_inventory = variable_inventory,
    treatment_inventory = treatment_inventory,
    outcome_inventory = outcome_inventory,
    biology_gap_analysis = biology_gap_analysis,
    study_readiness_matrix = study_readiness_matrix,
    false_positive_exclusions = false_positive_exclusions,
    ki67_discovery = ki67_discovery,
    recommended_next_actions = mcl_triangle_recommended_actions(study_readiness_matrix, biology_gap_analysis),
    caveats = mcl_triangle_caveats(),
    verdict_metadata = data.frame(kind = c("verdict", "rationale"), text = unname(verdict), stringsAsFactors = FALSE)
  )
}

mcl_triangle_write_outputs <- function(outputs, output_dir) {
  list(
    summary = write_csv(outputs$summary, file.path(output_dir, "mcl_triangle_feasibility_summary.csv")),
    variable_inventory = write_csv(outputs$variable_inventory, file.path(output_dir, "mcl_triangle_variable_inventory.csv")),
    treatment_inventory = write_csv(outputs$treatment_inventory, file.path(output_dir, "mcl_triangle_treatment_inventory.csv")),
    outcome_inventory = write_csv(outputs$outcome_inventory, file.path(output_dir, "mcl_triangle_outcome_inventory.csv")),
    biology_gap_analysis = write_csv(outputs$biology_gap_analysis, file.path(output_dir, "mcl_triangle_biology_gap_analysis.csv")),
    study_readiness_matrix = write_csv(outputs$study_readiness_matrix, file.path(output_dir, "mcl_triangle_study_readiness_matrix.csv")),
    false_positive_exclusions = write_csv(outputs$false_positive_exclusions %||% mcl_triangle_empty_false_positive_exclusions(), file.path(output_dir, "mcl_triangle_false_positive_exclusions.csv"))
  )
}
