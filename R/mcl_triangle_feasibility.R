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
    count_or_rows_if_available = character(), count_type = character(), patient_count_if_available = character(),
    confidence = character(), notes = character()
  )
}

mcl_triangle_empty_treatment_inventory <- function() {
  empty_df(
    exposure_name = character(), exposure_group = character(), source = character(),
    code_system = character(), code = character(), raw_value = character(), table_or_source = character(),
    current_profiled_this_run = logical(), evidence_count_or_rows = character(), count_type = character(),
    notes = character()
  )
}

mcl_triangle_empty_outcome_inventory <- function() {
  empty_df(
    outcome_name = character(), source = character(), table_or_source = character(), raw_field = character(),
    current_profiled_this_run = logical(), legacy_reference_only = logical(), feasibility_role = character(),
    count_or_rows_if_available = character(), count_type = character(), notes = character()
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

mcl_triangle_empty_payload <- function() {
  list(
    summary = mcl_triangle_empty_summary(),
    variable_inventory = mcl_triangle_empty_variable_inventory(),
    treatment_inventory = mcl_triangle_empty_treatment_inventory(),
    outcome_inventory = mcl_triangle_empty_outcome_inventory(),
    biology_gap_analysis = mcl_triangle_empty_biology_gap_analysis(),
    study_readiness_matrix = mcl_triangle_empty_study_readiness_matrix(),
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
  parts <- unlist(strsplit(x, "\\|", fixed = FALSE), use.names = FALSE)
  parts <- trimws(parts)
  parts <- parts[nzchar(parts)]
  unique(parts)
}

mcl_triangle_terms_pattern <- function(terms) {
  terms <- unique(mcl_triangle_norm(terms))
  terms <- terms[nzchar(terms)]
  if (!length(terms)) return("")
  paste(gsub("([\\W])", "\\\\\\1", terms, perl = TRUE), collapse = "|")
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
  data.frame(
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
    count_or_rows_if_available = count,
    count_type = count_type,
    patient_count_if_available = patient_count,
    confidence = confidence,
    notes = notes,
    evidence_priority = evidence_priority,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

mcl_triangle_collect_evidence <- function(concept, prepared, max_rows_per_source = 40L) {
  terms <- c(
    mcl_triangle_terms(concept$atlas_search_terms),
    mcl_triangle_terms(concept$concept_name),
    mcl_triangle_terms(concept$expected_sources),
    mcl_triangle_terms(concept$preferred_sources)
  )
  frames <- list(
    list(data = prepared$semantic_dictionary, text = prepared$semantic_text, type = "semantic dictionary", priority = 1L),
    list(data = prepared$semantic_code_map, text = prepared$code_text, type = "code map", priority = 2L),
    list(data = prepared$semantic_value_map, text = prepared$value_text, type = "value map", priority = 3L),
    list(data = prepared$semantic_panel_links, text = prepared$panel_text, type = "panel links", priority = 4L),
    list(data = prepared$sources, text = prepared$source_text, type = "source/catalog profile", priority = 5L),
    list(data = prepared$legacy_reference_vs_current, text = prepared$legacy_text, type = "legacy/reference evidence", priority = 6L)
  )
  out <- list()
  for (frame in frames) {
    hits <- mcl_triangle_match_rows(frame$data, frame$text, terms, max_rows = max_rows_per_source)
    if (!nrow(hits)) next
    rows <- lapply(seq_len(nrow(hits)), function(i) {
      mcl_triangle_inventory_row(
        concept = concept,
        row = hits[i, , drop = FALSE],
        evidence_type = frame$type,
        evidence_priority = frame$priority,
        sources = prepared$sources,
        canonical_reconciliation = prepared$canonical_reconciliation,
        legacy_reference_vs_current = prepared$legacy_reference_vs_current
      )
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
                                         sources = NULL, canonical_reconciliation = NULL,
                                         legacy_reference_vs_current = NULL) {
  if (!is.data.frame(semantic_dictionary)) semantic_dictionary <- empty_semantic_data_dictionary()
  if (!is.data.frame(semantic_value_map)) semantic_value_map <- empty_semantic_value_map()
  if (!is.data.frame(semantic_code_map)) semantic_code_map <- empty_semantic_code_map()
  if (!is.data.frame(semantic_panel_links)) semantic_panel_links <- empty_semantic_panel_links()
  if (!is.data.frame(sources)) sources <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(canonical_reconciliation)) canonical_reconciliation <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(legacy_reference_vs_current)) legacy_reference_vs_current <- data.frame(stringsAsFactors = FALSE)
  list(
    semantic_dictionary = semantic_dictionary,
    semantic_value_map = semantic_value_map,
    semantic_code_map = semantic_code_map,
    semantic_panel_links = semantic_panel_links,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current,
    semantic_text = mcl_triangle_text_for_frame(semantic_dictionary, c("semantic_id", "clinical_concept_id", "clinical_variable", "clinical_group", "clinical_subgroup", "semantic_meaning", "source_name", "object_name", "table_name", "raw_column", "raw_descriptor", "raw_code", "raw_value", "code_system", "evidence_file", "clinical_caveat", "search_terms")),
    value_text = mcl_triangle_text_for_frame(semantic_value_map, c("semantic_id", "clinical_concept_id", "clinical_variable", "source_name", "object_name", "raw_column", "raw_value", "display_value", "value_class", "clinical_interpretation", "evidence_file", "notes")),
    code_text = mcl_triangle_text_for_frame(semantic_code_map, c("semantic_id", "clinical_concept_id", "clinical_variable", "clinical_group", "source_name", "object_name", "code_system", "code", "code_name", "panel", "evidence_file", "notes")),
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
    status <- "ready"
    limitation <- "Direct aggregate evidence is current-profiled."
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

mcl_triangle_build_readiness_matrix <- function(inventory) {
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
    list("Ki-67", mcl_triangle_filter_group(inventory, "High-risk biology", "Ki-67|proliferation"), mcl_triangle_filter_group(inventory, "High-risk biology", "pathology|microscopy|conclusion"), "pathology text, microscopy/conclusion text, LYFO fields"),
    list("MIPI", mcl_triangle_filter_group(inventory, "High-risk biology", "^MIPI$|MIPI score"), mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", "age|performance|LDH|leukocyte"), "LYFO/RKKP fields or reconstruction inputs"),
    list("MIPI-c", mcl_triangle_filter_group(inventory, "High-risk biology", "MIPI-c"), mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", "MIPI|Ki-67|age|performance|LDH|leukocyte"), "MIPI components plus Ki-67"),
    list("toxicity proxies", mcl_triangle_filter_group(inventory, "Safety", "admission|ICU|infection|neutropenic|antibiotic|hospitalisation|transfusion"), NULL, "ADT/admission, microbiology, medication, transfusion sources")
  )
  rows <- lapply(reqs, function(req) {
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

mcl_triangle_build_biology_gap_analysis <- function(inventory) {
  markers <- c("blastoid morphology", "pleomorphic morphology", "TP53", "p53", "del17p", "Ki-67", "MIPI", "MIPI-c", "LDH", "leukocytes", "performance status", "age")
  rows <- lapply(markers, function(marker) {
    direct <- mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", marker)
    if (!nrow(direct) && identical(marker, "p53")) direct <- mcl_triangle_filter_group(inventory, "High-risk biology", "TP53|p53")
    if (!nrow(direct) && identical(marker, "del17p")) direct <- mcl_triangle_filter_group(inventory, "High-risk biology", "del17p|17p")
    proxy <- mcl_triangle_filter_group(inventory, "High-risk biology|Eligibility", if (marker %in% c("MIPI", "MIPI-c")) "age|performance|LDH|leukocyte|Ki-67" else "pathology|morphology|FISH|molecular")
    direct_found <- mcl_triangle_has_any(direct)
    proxy_found <- !direct_found && mcl_triangle_has_any(proxy)
    current <- mcl_triangle_has_current(direct) || (!direct_found && mcl_triangle_has_current(proxy))
    legacy <- mcl_triangle_has_legacy_only(direct) || (!direct_found && mcl_triangle_has_legacy_only(proxy))
    status <- if (direct_found && current) {
      "ready"
    } else if (proxy_found && current) {
      "proxy_available"
    } else if (direct_found || proxy_found) {
      "legacy_reference_only"
    } else {
      "needs_source_activation"
    }
    action <- if (status %in% c("ready", "proxy_available")) {
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
      notes = if (status %in% c("ready", "proxy_available")) "Aggregate evidence exists; no patient-level inference is made." else "High-risk biology remains a feasibility gap until source activation/mapping is complete.",
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  out[names(mcl_triangle_empty_biology_gap_analysis())]
}

mcl_triangle_treatment_inventory <- function(inventory) {
  rows <- mcl_triangle_filter_group(inventory, "Treatment", "")
  if (!nrow(rows)) return(mcl_triangle_empty_treatment_inventory())
  data.frame(
    exposure_name = rows$concept_name,
    exposure_group = ifelse(grepl("ibrutinib|BTK", rows$concept_name, ignore.case = TRUE), "BTK inhibitor",
      ifelse(grepl("ASCT|HDT|stem-cell|autologous", rows$concept_name, ignore.case = TRUE), "ASCT/HDT",
        ifelse(grepl("R-CHOP|R-DHAP|cytarabine|rituximab|bendamustine|CIT|regimen|immunochemotherapy", rows$concept_name, ignore.case = TRUE), "CIT / immunochemotherapy", "Treatment exposure")
      )
    ),
    source = rows$source,
    code_system = ifelse(grepl("ATC|SKS|NPU", rows$code_or_value, ignore.case = TRUE), rows$code_or_value, ""),
    code = rows$code_or_value,
    raw_value = rows$code_or_value,
    table_or_source = rows$table_or_source,
    current_profiled_this_run = rows$current_profiled_this_run,
    evidence_count_or_rows = rows$count_or_rows_if_available,
    count_type = rows$count_type,
    notes = ifelse(nzchar(rows$count_or_rows_if_available), paste(rows$count_type, "from aggregate atlas output"), "Evidence found; count not available in atlas aggregate outputs."),
    stringsAsFactors = FALSE
  )
}

mcl_triangle_outcome_inventory <- function(inventory) {
  rows <- mcl_triangle_filter_group(inventory, "Outcomes|Safety", "")
  if (!nrow(rows)) return(mcl_triangle_empty_outcome_inventory())
  data.frame(
    outcome_name = rows$concept_name,
    source = rows$source,
    table_or_source = rows$table_or_source,
    raw_field = rows$raw_field,
    current_profiled_this_run = rows$current_profiled_this_run,
    legacy_reference_only = rows$legacy_reference_only,
    feasibility_role = ifelse(grepl("death|overall survival", rows$concept_name, ignore.case = TRUE), "OS/death",
      ifelse(grepl("relapse|progression|response|next treatment|follow-up", rows$concept_name, ignore.case = TRUE), "relapse/progression/FFS proxy", "toxicity proxy")
    ),
    count_or_rows_if_available = rows$count_or_rows_if_available,
    count_type = rows$count_type,
    notes = ifelse(nzchar(rows$count_or_rows_if_available), paste(rows$count_type, "from aggregate atlas output"), "Evidence found; count not available in atlas aggregate outputs."),
    stringsAsFactors = FALSE
  )
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
  readyish <- function(status) status %in% c("ready", "proxy_available", "feasible_with_mapping")
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
    metric_row("ki67_evidence_found", "Ki-67 evidence found", if (any(grepl("Ki-67", inventory$concept_name, ignore.case = TRUE))) "found" else "not_found", inventory[grepl("Ki-67", inventory$concept_name, ignore.case = TRUE), , drop = FALSE]),
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

build_mcl_triangle_feasibility_outputs <- function(project_root = ".",
                                                   semantic_dictionary = NULL,
                                                   semantic_value_map = NULL,
                                                   semantic_code_map = NULL,
                                                   semantic_panel_links = NULL,
                                                   panel_raw_fields = NULL,
                                                   panel_distributions = NULL,
                                                   panel_kpis = NULL,
                                                   sources = NULL,
                                                   canonical_reconciliation = NULL,
                                                   legacy_reference_vs_current = NULL) {
  concepts <- mcl_triangle_read_concepts(project_root)
  prepared <- mcl_triangle_prepare_sources(
    semantic_dictionary = semantic_dictionary,
    semantic_value_map = semantic_value_map,
    semantic_code_map = semantic_code_map,
    semantic_panel_links = semantic_panel_links,
    sources = sources,
    canonical_reconciliation = canonical_reconciliation,
    legacy_reference_vs_current = legacy_reference_vs_current
  )
  inventory_parts <- lapply(seq_len(nrow(concepts)), function(i) {
    mcl_triangle_collect_evidence(concepts[i, , drop = FALSE], prepared)
  })
  variable_inventory <- bind_rows_base(inventory_parts)
  if (!nrow(variable_inventory)) variable_inventory <- mcl_triangle_empty_variable_inventory()
  treatment_inventory <- mcl_triangle_treatment_inventory(variable_inventory)
  outcome_inventory <- mcl_triangle_outcome_inventory(variable_inventory)
  biology_gap_analysis <- mcl_triangle_build_biology_gap_analysis(variable_inventory)
  study_readiness_matrix <- mcl_triangle_build_readiness_matrix(variable_inventory)
  verdict <- mcl_triangle_verdict(study_readiness_matrix, biology_gap_analysis)
  feasibility_summary <- mcl_triangle_summary(
    inventory = variable_inventory,
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
    study_readiness_matrix = write_csv(outputs$study_readiness_matrix, file.path(output_dir, "mcl_triangle_study_readiness_matrix.csv"))
  )
}
