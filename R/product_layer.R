product_scope_values <- function() {
  c("full_table", "full_source", "cartography_scan", "top_n_scan", "max_scan_100000", "unknown", "not_available")
}

empty_clinical_concepts <- function() {
  empty_df(
    clinical_concept_id = character(),
    clinical_variable = character(),
    clinical_group = character(),
    clinical_subgroup = character(),
    concept_status = character(),
    purpose = character(),
    best_source = character(),
    primary_sources = character(),
    raw_field_count = integer(),
    value_map_count = integer(),
    code_map_count = integer(),
    evidence_files = character(),
    mapping_status_summary = character(),
    n_rows = numeric(),
    n_patients = numeric(),
    count_scope = character(),
    denominator_scope = character(),
    profile_scope = character(),
    use_cases = character(),
    caveats = character(),
    related_panel_ids = character(),
    search_terms = character()
  )
}

empty_domain_panels <- function() {
  empty_df(
    panel_id = character(),
    panel_section = character(),
    panel_title = character(),
    clinical_purpose = character(),
    panel_status = character(),
    source_names = character(),
    related_clinical_concepts = character(),
    use_cases = character(),
    caveats = character(),
    missing_upstream_file = character(),
    parity_status = character(),
    count_scope = character(),
    denominator_scope = character(),
    profile_scope = character(),
    sort_order = integer()
  )
}

empty_panel_kpis <- function() {
  empty_df(
    panel_id = character(),
    kpi_id = character(),
    label = character(),
    value = character(),
    unit = character(),
    source_name = character(),
    evidence_file = character(),
    count_scope = character(),
    denominator_scope = character(),
    profile_scope = character(),
    sort_order = integer()
  )
}

empty_panel_distributions <- function() {
  empty_df(
    panel_id = character(),
    clinical_concept_id = character(),
    clinical_variable = character(),
    distribution_type = character(),
    source_name = character(),
    raw_column = character(),
    raw_descriptor = character(),
    raw_code = character(),
    raw_value = character(),
    display_value = character(),
    value_class = character(),
    n = numeric(),
    pct = numeric(),
    statistic = character(),
    statistic_value = character(),
    evidence_file = character(),
    count_scope = character(),
    denominator_scope = character(),
    profile_scope = character(),
    sort_order = integer()
  )
}

empty_panel_raw_fields <- function() {
  empty_df(
    panel_id = character(),
    panel_section = character(),
    semantic_id = character(),
    clinical_concept_id = character(),
    clinical_variable = character(),
    source_name = character(),
    object_name = character(),
    raw_column = character(),
    raw_descriptor = character(),
    raw_code = character(),
    raw_value = character(),
    raw_field_label = character(),
    mapping_status = character(),
    mapping_confidence = character(),
    evidence_file = character(),
    evidence_filter = character(),
    count_scope = character(),
    denominator_scope = character(),
    profile_scope = character(),
    privacy_note = character(),
    clinical_caveat = character(),
    sort_order = integer()
  )
}

empty_panel_parity <- function() {
  empty_df(
    old_panel_id = character(),
    new_panel_id = character(),
    old_title = character(),
    new_title = character(),
    parity_status = character(),
    missing_items = character(),
    next_required_output = character()
  )
}

empty_product_layer_outputs <- function() {
  list(
    clinical_concepts = empty_clinical_concepts(),
    domain_panels = empty_domain_panels(),
    panel_kpis = empty_panel_kpis(),
    panel_distributions = empty_panel_distributions(),
    panel_raw_fields = empty_panel_raw_fields(),
    panel_parity = empty_panel_parity()
  )
}

build_product_layer_outputs <- function(semantic_outputs, sources = NULL, panels = list(),
                                        column_profiles = NULL, min_cell_count = atlas_min_cell_count(),
                                        project_root = ".") {
  dictionary <- semantic_outputs$dictionary %||% empty_semantic_data_dictionary()
  value_map <- semantic_outputs$value_map %||% empty_semantic_value_map()
  code_map <- semantic_outputs$code_map %||% empty_semantic_code_map()
  panel_links <- semantic_outputs$panel_links %||% empty_semantic_panel_links()

  raw_fields <- product_panel_raw_fields(dictionary, panel_links, project_root = project_root)
  concepts <- product_clinical_concepts(dictionary, value_map, code_map, panel_links, raw_fields)
  distributions <- product_panel_distributions(dictionary, value_map, code_map, panels, project_root = project_root)
  kpis <- product_panel_kpis(sources, panels, raw_fields, distributions, project_root = project_root)
  domain_panels <- product_domain_panels(raw_fields, kpis, distributions, concepts)
  parity <- product_panel_parity(domain_panels, kpis, distributions, raw_fields)

  list(
    clinical_concepts = align_product_frame(concepts, names(empty_clinical_concepts())),
    domain_panels = align_product_frame(domain_panels, names(empty_domain_panels())),
    panel_kpis = align_product_frame(kpis, names(empty_panel_kpis())),
    panel_distributions = align_product_frame(distributions, names(empty_panel_distributions())),
    panel_raw_fields = align_product_frame(raw_fields, names(empty_panel_raw_fields())),
    panel_parity = align_product_frame(parity, names(empty_panel_parity()))
  )
}

product_panel_specs <- function() {
  data.frame(
    panel_id = c(
      "reg_damyda", "reg_lyfo", "reg_cll", "diagnosis_atlas", "clinical_vitals",
      "clinical_social_history", "clinical_adt", "clinical_notes", "clinical_imaging",
      "clinical_microbiology", "treatment", "laboratory_npu", "clinical_pathology",
      "clinical_biobank"
    ),
    panel_section = c(
      "Disease Registries", "Disease Registries", "Disease Registries", "Disease Registries",
      "Clinical Data", "Clinical Data", "Clinical Data", "Clinical Data", "Clinical Data",
      "Clinical Data", "Treatment", "Laboratory", "Clinical Data", "Laboratory"
    ),
    panel_title = c(
      "DaMyDa", "LYFO: lymphoma registry review", "CLL", "Diagnosis Atlas", "Vitals", "Social History",
      "ADT", "Notes", "Imaging", "Microbiology", "Treatment", "Laboratory/NPU",
      "Pathology / PATOBANK", "Biobank"
    ),
    clinical_purpose = c(
      "Myeloma registry review for baseline markers, staging, treatment, response, relapse, bone disease, imaging, and cytogenetic availability.",
      "Lymphoma registry review for subtype, Ann Arbor stage, prognostic scores, B symptoms, bulk disease, performance status, treatment/regimen fields, follow-up, and disease localization.",
      "CLL registry review for Binet stage, IGHV, FISH/cytogenetics, TP53, treatment, targeted therapy, response, and MRD availability.",
      "ICD10 diagnosis availability across DALY-CARE diagnosis tables and views.",
      "Physiological measurement availability from SP vital signs, including anthropometrics and repeated clinical observations.",
      "Lifestyle and social-history availability, especially smoking and alcohol status with raw Danish value meanings.",
      "Admission, discharge, transfer, ICU, and hospital-contact signals for patient trajectory analysis.",
      "Clinical note metadata and free-text availability without exposing note text.",
      "Imaging availability across nationwide procedure-code events, registry modality fields, and EHR-native imaging metadata/report text.",
      "Infection and microbiology availability across PERSIMUNE microbiology and SP blood-culture workflows.",
      "Treatment evidence across SKS procedure codes, ATC medication codes, administered medicine, prescriptions, and treatment plans.",
      "Laboratory/NPU evidence across LABKA, SP AlleProvesvar, PERSIMUNE, consensus NPU dictionary, and disease panels.",
      "Pathology evidence through SNOMED/code summaries and pathology table availability; free text is not exposed.",
      "Biobank sample availability by source, sample type, material, and linked aggregate evidence."
    ),
    use_cases = c(
      "Myeloma cohort phenotyping; staging/risk stratification; renal/bone disease studies; treatment-response analyses.",
      "Lymphoma subtype cohort discovery; Ann Arbor stage and IPI/aaIPI risk adjustment; B-symptom and bulky-disease stratification; treatment/regimen field discovery; relapse/follow-up variable discovery; disease-localization review.",
      "CLL risk stratification; targeted therapy cohorts; molecular/cytogenetic subgroup analyses.",
      "Cohort definition; diagnosis validation; comorbidity and longitudinal disease history.",
      "Frailty, acute illness, deterioration, baseline anthropometrics, and longitudinal physiology studies.",
      "Lifestyle covariate extraction; smoking/alcohol adjustment; missingness and not-asked audits.",
      "Current/recent care state, hospitalization trajectories, ICU linkage, and operational situation reports.",
      "NLP eligibility, clinical-event text mining, note-type availability, and text-access planning.",
      "Imaging-event ascertainment, PET/CT/CT/MRI availability, radiotherapy procedure signals, and report-metadata planning.",
      "Infection phenotype development, culture/resistance evidence, organism/material/result class availability.",
      "Treatment exposure algorithms, regimen proxies, code-family validation, and cross-source therapy triangulation.",
      "Biochemistry and disease-marker availability; cross-source code concordance; NPU-driven laboratory phenotyping.",
      "Pathology-code phenotyping, specimen/body-site audits, biopsy verification signals, and NLP planning without raw text.",
      "Translational study feasibility and linked sample availability planning."
    ),
    caveats = c(
      "Registry fields are wide-format and disease-specific; expected fields may be absent or renamed in cartography evidence.",
      "LYFO is a registry layer, not the complete medication administration record. Registry-coded fields require LYFO data-dictionary validation; counts/distributions may be cartography/profile outputs unless explicitly full-source.",
      "Molecular/treatment fields can be sparse; targeted therapy variables may live in curated companion tables.",
      "Diagnosis rows are not unique patients and may reflect repeated or refined coding over time.",
      "Repeated measures require baseline windows, outlier handling, and unit checks before patient-level analysis.",
      "Not asked, unknown, deferred, and true missing values must be separated analytically.",
      "ADT events are operational contacts, not diagnoses; current-state metrics require conservative interval definitions.",
      "Free text is counted/described only; actual note content is never emitted in the static atlas.",
      "This is not image pixel storage; it is event, procedure, modality, metadata, and report-text availability.",
      "Microbiology panels expose aggregate descriptors/results only; isolate-level interpretation needs source-specific validation.",
      "Code-level treatment signals are proxies unless a registry or treatment-plan source confirms regimen semantics.",
      "NPU/DNK code coverage differs by source and may represent top-N or cartography scan evidence rather than full denominators.",
      "Free-text pathology content is not emitted; code summaries require coding-system expertise.",
      "Sample availability does not imply assay availability or consent/use permissions."
    ),
    missing_upstream_file = c(rep("", 14)),
    sort_order = seq_len(14),
    stringsAsFactors = FALSE
  )
}

product_panel_raw_fields <- function(dictionary, panel_links, project_root = ".") {
  if (!is.data.frame(dictionary)) dictionary <- empty_semantic_data_dictionary()
  if (!is.data.frame(panel_links)) panel_links <- empty_semantic_panel_links()
  rows <- list()
  if (nrow(dictionary)) {
    if (!nrow(panel_links)) panel_links <- semantic_panel_links_for_dictionary(dictionary)
    links <- panel_links[panel_links$semantic_id %in% dictionary$semantic_id, , drop = FALSE]
    if (nrow(links)) {
      for (i in seq_len(nrow(links))) {
        idx <- match(links$semantic_id[[i]], dictionary$semantic_id)
        if (is.na(idx)) next
        row <- dictionary[idx, , drop = FALSE]
        if (product_identifier_like_column(row$raw_column[[1]] %||% "")) next
        panel_id <- product_normalize_panel_id(links$panel_id[[i]], row)
        rows[[length(rows) + 1L]] <- product_raw_field_row(
          panel_id = panel_id,
          panel_section = links$panel_section[[i]] %||% product_panel_section(panel_id),
          semantic_id = row$semantic_id[[1]],
          clinical_concept_id = row$clinical_concept_id[[1]],
          clinical_variable = row$clinical_variable[[1]],
          source_name = row$source_name[[1]],
          object_name = row$object_name[[1]],
          raw_column = row$raw_column[[1]],
          raw_descriptor = row$raw_descriptor[[1]],
          raw_code = row$raw_code[[1]],
          raw_value = row$raw_value[[1]],
          raw_field_label = product_raw_field_label(row),
          mapping_status = row$mapping_status[[1]],
          mapping_confidence = row$mapping_confidence[[1]],
          evidence_file = row$evidence_file[[1]],
          evidence_filter = row$evidence_filter[[1]],
          count_scope = product_scope_for_evidence(row$evidence_file[[1]]),
          denominator_scope = product_scope_for_evidence(row$evidence_file[[1]]),
          profile_scope = product_scope_for_evidence(row$evidence_file[[1]]),
          privacy_note = row$privacy_note[[1]],
          clinical_caveat = row$clinical_caveat[[1]],
          sort_order = i
        )
      }
    }
  }
  rows <- c(rows, product_structural_raw_fields(project_root, length(rows) + 1L))
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_panel_raw_fields())
  out <- product_dedupe_raw_fields(out)
  align_product_frame(out, names(empty_panel_raw_fields()))
}

product_raw_field_row <- function(...) {
  align_product_frame(data.frame(..., stringsAsFactors = FALSE), names(empty_panel_raw_fields()))
}

product_structural_raw_fields <- function(project_root, start_sort = 1L) {
  rows <- list()
  specs <- list(
    list(
      panel_id = "clinical_notes",
      panel_section = "Clinical Data",
      source_name = "SP_Journalnotater_Del1",
      evidence_file = "cartography_part4_sp_journalnotater_del1_columns.tsv",
      fields = c("notat_type", "notat_status", "service", "ydelsesdato_dato_tid", "notat_text"),
      variables = c("Note type", "Note status", "Clinical service", "Note timestamp", "Clinical note text availability"),
      caveat = "Free-text note content is described as available but not emitted into public outputs.",
      privacy = "free_text_not_exposed"
    ),
    list(
      panel_id = "clinical_adt",
      panel_section = "Clinical Data",
      source_name = "SP_ADT_haendelser",
      evidence_file = "cartography_part4_sp_adt_haendelser_columns.tsv",
      fields = c("kontakt_start_local_dttm", "kontakt_end_local_dttm", "effective_time", "event_type_name", "patient_class"),
      variables = c("Contact start", "Contact end", "ADT event time", "ADT event type", "Patient class"),
      caveat = "Admission/current-state metrics require paired interval or event-stream definitions.",
      privacy = "aggregate_only"
    ),
    list(
      panel_id = "clinical_pathology",
      panel_section = "Clinical Data",
      source_name = "SDS_t_mikro",
      evidence_file = "cartography_part4_sds_t_mikro_columns.tsv",
      fields = c("k_inst", "v_fritekst", "date_received", "datetime_created"),
      variables = c("Pathology institution / lab source", "Pathology microscopy/free-text availability", "Pathology received date field", "Pathology created datetime field"),
      caveat = "Pathology microscopy/free-text values are described as available but never emitted into public outputs.",
      privacy = "free_text_not_exposed"
    ),
    list(
      panel_id = "clinical_pathology",
      panel_section = "Clinical Data",
      source_name = "SDS_t_konk",
      evidence_file = "cartography_part4_sds_t_konk_columns.tsv",
      fields = c("k_inst", "v_fritekst", "date_received", "datetime_created"),
      variables = c("Pathology institution / lab source", "Pathology conclusion/free-text availability", "Pathology received date field", "Pathology created datetime field"),
      caveat = "Pathology conclusion/free-text values are described as available but never emitted into public outputs.",
      privacy = "free_text_not_exposed"
    )
  )
  sort_order <- start_sort
  for (spec in specs) {
    table <- read_cartography_table(spec$evidence_file, project_root)
    if (!nrow(table) || !"column" %in% names(table)) next
    for (j in seq_along(spec$fields)) {
      field <- spec$fields[[j]]
      if (!field %in% table$column) next
      rows[[length(rows) + 1L]] <- product_raw_field_row(
        panel_id = spec$panel_id,
        panel_section = spec$panel_section,
        semantic_id = semantic_id_from(c(spec$panel_id, field)),
        clinical_concept_id = semantic_id_from(c(spec$panel_id, spec$variables[[j]])),
        clinical_variable = spec$variables[[j]],
        source_name = spec$source_name,
        object_name = spec$source_name,
        raw_column = field,
        raw_descriptor = "",
        raw_code = "",
        raw_value = "",
        raw_field_label = paste0(spec$source_name, ".", field, " -> ", spec$variables[[j]]),
        mapping_status = "confirmed",
        mapping_confidence = "medium",
        evidence_file = spec$evidence_file,
        evidence_filter = paste0("column=", field),
        count_scope = "cartography_scan",
        denominator_scope = "cartography_scan",
        profile_scope = "cartography_scan",
        privacy_note = spec$privacy,
        clinical_caveat = spec$caveat,
        sort_order = sort_order
      )
      sort_order <- sort_order + 1L
    }
  }
  rows
}

product_clinical_concepts <- function(dictionary, value_map, code_map, panel_links, raw_fields) {
  if (!is.data.frame(dictionary) || !nrow(dictionary)) return(empty_clinical_concepts())
  concepts <- split(dictionary, dictionary$clinical_concept_id)
  rows <- lapply(names(concepts), function(id) {
    group <- concepts[[id]]
    value_count <- if (is.data.frame(value_map) && nrow(value_map)) sum(value_map$clinical_concept_id == id, na.rm = TRUE) else 0L
    code_count <- if (is.data.frame(code_map) && nrow(code_map)) sum(code_map$clinical_concept_id == id, na.rm = TRUE) else 0L
    link_rows <- if (is.data.frame(panel_links) && nrow(panel_links)) panel_links[panel_links$clinical_concept_id == id, , drop = FALSE] else empty_semantic_panel_links()
    raw_count <- if (is.data.frame(raw_fields) && nrow(raw_fields)) sum(raw_fields$clinical_concept_id == id, na.rm = TRUE) else nrow(group)
    variable <- product_best_label(group$clinical_variable)
    source <- product_best_source(group)
    evidence <- unique_nonblank(group$evidence_file)
    scopes <- vapply(evidence, product_scope_for_evidence, character(1))
    data.frame(
      clinical_concept_id = id,
      clinical_variable = variable,
      clinical_group = product_best_label(group$clinical_group),
      clinical_subgroup = product_best_label(group$clinical_subgroup),
      concept_status = product_concept_status(group),
      purpose = product_concept_purpose(id, variable, group),
      best_source = source,
      primary_sources = paste(unique_nonblank(group$source_name), collapse = "; "),
      raw_field_count = raw_count,
      value_map_count = value_count,
      code_map_count = code_count,
      evidence_files = paste(evidence, collapse = "; "),
      mapping_status_summary = paste(names(sort(table(group$mapping_status), decreasing = TRUE)), collapse = "; "),
      n_rows = product_sum_numeric(group$n_rows),
      n_patients = product_sum_numeric(group$n_patients),
      count_scope = product_merge_scopes(scopes),
      denominator_scope = product_merge_scopes(scopes),
      profile_scope = product_merge_scopes(scopes),
      use_cases = product_concept_use_cases(id, variable, group),
      caveats = product_concept_caveat(id, group),
      related_panel_ids = paste(unique_nonblank(vapply(link_rows$panel_id, product_normalize_panel_id, character(1), row = group[1, , drop = FALSE])), collapse = "; "),
      search_terms = semantic_terms(c(variable, id, group$search_terms, group$source_name, group$raw_column, group$raw_descriptor, group$raw_code)),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  out <- bind_rows_base(list(out, product_derived_concepts(dictionary, raw_fields)))
  out <- product_dedupe_clinical_concepts(out)
  out <- out[order(out$clinical_group, out$clinical_variable), , drop = FALSE]
  align_product_frame(out, names(empty_clinical_concepts()))
}

product_dedupe_clinical_concepts <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(empty_clinical_concepts())
  rows <- lapply(split(x, x$clinical_concept_id), function(group) {
    if (nrow(group) == 1L) return(group)
    id <- group$clinical_concept_id[[1]]
    derived <- grepl("derived", paste(group$mapping_status_summary, group$caveats, group$purpose), ignore.case = TRUE)
    base_index <- if (identical(id, "bmi") && any(derived)) which(derived)[1] else 1L
    base <- group[base_index, , drop = FALSE]
    scopes <- unique_nonblank(c(group$count_scope, group$denominator_scope, group$profile_scope))
    base$primary_sources <- paste(unique_nonblank(group$primary_sources), collapse = "; ")
    base$raw_field_count <- sum(suppressWarnings(as.numeric(group$raw_field_count)), na.rm = TRUE)
    base$value_map_count <- sum(suppressWarnings(as.numeric(group$value_map_count)), na.rm = TRUE)
    base$code_map_count <- sum(suppressWarnings(as.numeric(group$code_map_count)), na.rm = TRUE)
    base$evidence_files <- paste(unique_nonblank(group$evidence_files), collapse = "; ")
    base$mapping_status_summary <- paste(unique_nonblank(group$mapping_status_summary), collapse = "; ")
    base$n_rows <- product_sum_numeric(group$n_rows)
    base$n_patients <- product_sum_numeric(group$n_patients)
    base$count_scope <- product_merge_scopes(scopes)
    base$denominator_scope <- product_merge_scopes(scopes)
    base$profile_scope <- product_merge_scopes(scopes)
    base$related_panel_ids <- paste(unique_nonblank(group$related_panel_ids), collapse = "; ")
    base$search_terms <- semantic_terms(c(group$search_terms, group$clinical_variable, group$clinical_concept_id))
    if (identical(id, "bmi")) {
      base$clinical_variable <- "BMI"
      base$purpose <- "BMI derived from height and weight evidence when both are available."
      base$caveats <- "BMI is derived from height and weight and is not treated as directly stored unless a source proves otherwise."
      base$concept_status <- if (any(group$concept_status == "available", na.rm = TRUE)) "available" else "partial"
    }
    base
  })
  bind_rows_base(rows)
}

product_derived_concepts <- function(dictionary, raw_fields) {
  rows <- list()
  has_weight <- any(dictionary$clinical_concept_id == "weight", na.rm = TRUE)
  has_height <- any(dictionary$clinical_concept_id == "height", na.rm = TRUE)
  if (has_weight && has_height) {
    rows[[length(rows) + 1L]] <- data.frame(
      clinical_concept_id = "bmi",
      clinical_variable = "BMI",
      clinical_group = "Vitals",
      clinical_subgroup = "Anthropometrics",
      concept_status = "partial",
      purpose = "Derived body-mass index concept from height and weight evidence when both are available.",
      best_source = "SP_VitaleVaerdier",
      primary_sources = paste(unique_nonblank(dictionary$source_name[dictionary$clinical_concept_id %in% c("weight", "height")]), collapse = "; "),
      raw_field_count = sum(raw_fields$clinical_concept_id %in% c("weight", "height"), na.rm = TRUE),
      value_map_count = 0L,
      code_map_count = 0L,
      evidence_files = paste(unique_nonblank(dictionary$evidence_file[dictionary$clinical_concept_id %in% c("weight", "height")]), collapse = "; "),
      mapping_status_summary = "derived",
      n_rows = NA_real_,
      n_patients = NA_real_,
      count_scope = "not_available",
      denominator_scope = "not_available",
      profile_scope = "not_available",
      use_cases = "Anthropometrics, frailty adjustment, and baseline covariate derivation.",
      caveats = "BMI is derived from height and weight and is not treated as directly stored unless a source proves otherwise.",
      related_panel_ids = "clinical_vitals",
      search_terms = "BMI; body mass index; height; weight; Vægt; Højde; anthropometrics",
      stringsAsFactors = FALSE
    )
  }
  if (any(dictionary$clinical_group == "Imaging", na.rm = TRUE)) {
    rows[[length(rows) + 1L]] <- product_domain_concept_row(
      "imaging_availability", "Imaging availability", "Imaging", "Imaging",
      "Availability of imaging events, modality fields, and EHR imaging metadata/report layers.",
      dictionary[dictionary$clinical_group == "Imaging", , drop = FALSE],
      "clinical_imaging",
      "PET; CT; MRI; X-ray; radiotherapy; imaging; billeddiagnostik"
    )
  }
  if (any(dictionary$clinical_group == "Microbiology", na.rm = TRUE)) {
    rows[[length(rows) + 1L]] <- product_domain_concept_row(
      "microbiology_infection_data", "Microbiology/infection data", "Microbiology", "Infection",
      "Availability of microbiology analysis, culture, resistance, microscopy, and blood-culture workflow evidence.",
      dictionary[dictionary$clinical_group == "Microbiology", , drop = FALSE],
      "clinical_microbiology",
      "blood culture; bloddyrkning; infection; culture; resistance; organism; sample material"
    )
  }
  bind_rows_base(rows)
}

product_domain_concept_row <- function(id, variable, group_name, subgroup, purpose, rows, panel_id, terms) {
  evidence <- unique_nonblank(rows$evidence_file)
  scopes <- vapply(evidence, product_scope_for_evidence, character(1))
  data.frame(
    clinical_concept_id = id,
    clinical_variable = variable,
    clinical_group = group_name,
    clinical_subgroup = subgroup,
    concept_status = if (nrow(rows)) "available" else "not_yet_profiled",
    purpose = purpose,
    best_source = product_best_source(rows),
    primary_sources = paste(unique_nonblank(rows$source_name), collapse = "; "),
    raw_field_count = nrow(rows),
    value_map_count = 0L,
    code_map_count = 0L,
    evidence_files = paste(evidence, collapse = "; "),
    mapping_status_summary = paste(unique_nonblank(rows$mapping_status), collapse = "; "),
    n_rows = product_sum_numeric(rows$n_rows),
    n_patients = product_sum_numeric(rows$n_patients),
    count_scope = product_merge_scopes(scopes),
    denominator_scope = product_merge_scopes(scopes),
    profile_scope = product_merge_scopes(scopes),
    use_cases = "Clinical availability review, feasibility assessment, and source-selection planning.",
    caveats = product_best_label(rows$clinical_caveat),
    related_panel_ids = panel_id,
    search_terms = terms,
    stringsAsFactors = FALSE
  )
}

product_panel_distributions <- function(dictionary, value_map, code_map, panels, project_root = ".") {
  rows <- list()
  if (is.data.frame(value_map) && nrow(value_map)) {
    for (i in seq_len(nrow(value_map))) {
      panel_id <- product_panel_for_concept(value_map$clinical_concept_id[[i]], value_map$clinical_variable[[i]], value_map$source_name[[i]])
      rows[[length(rows) + 1L]] <- product_distribution_row(
        panel_id = panel_id,
        clinical_concept_id = value_map$clinical_concept_id[[i]],
        clinical_variable = value_map$clinical_variable[[i]],
        distribution_type = "value_map",
        source_name = value_map$source_name[[i]],
        raw_column = value_map$raw_column[[i]],
        raw_value = value_map$raw_value[[i]],
        display_value = value_map$display_value[[i]],
        value_class = value_map$value_class[[i]],
        n = value_map$n[[i]],
        pct = value_map$pct[[i]],
        evidence_file = value_map$evidence_file[[i]],
        count_scope = product_scope_for_evidence(value_map$evidence_file[[i]]),
        denominator_scope = product_scope_for_evidence(value_map$evidence_file[[i]]),
        profile_scope = product_scope_for_evidence(value_map$evidence_file[[i]]),
        sort_order = i
      )
    }
  }
  if (is.data.frame(code_map) && nrow(code_map)) {
    for (i in seq_len(nrow(code_map))) {
      panel_id <- product_panel_for_concept(code_map$clinical_concept_id[[i]], code_map$clinical_variable[[i]], code_map$source_name[[i]], code_map$clinical_group[[i]])
      rows[[length(rows) + 1L]] <- product_distribution_row(
        panel_id = panel_id,
        clinical_concept_id = code_map$clinical_concept_id[[i]],
        clinical_variable = code_map$clinical_variable[[i]],
        distribution_type = "code_map",
        source_name = code_map$source_name[[i]],
        raw_code = code_map$code[[i]],
        display_value = code_map$code_name[[i]],
        value_class = code_map$code_system[[i]],
        n = code_map$n_rows[[i]],
        evidence_file = code_map$evidence_file[[i]],
        count_scope = product_scope_for_evidence(code_map$evidence_file[[i]]),
        denominator_scope = product_scope_for_evidence(code_map$evidence_file[[i]]),
        profile_scope = product_scope_for_evidence(code_map$evidence_file[[i]]),
        sort_order = 10000L + i
      )
    }
  }
  rows <- c(rows, product_vital_numeric_distributions(project_root, length(rows) + 1L))
  rows <- c(rows, product_registry_section_distributions(length(rows) + 1L))
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_panel_distributions())
  align_product_frame(out, names(empty_panel_distributions()))
}

product_distribution_row <- function(...) {
  align_product_frame(data.frame(..., stringsAsFactors = FALSE), names(empty_panel_distributions()))
}

product_vital_numeric_distributions <- function(project_root, start_sort = 1L) {
  domain_summary <- read_cartography_table("cartography_sp_vitalevaerdier_domain_summary.tsv", project_root)
  if (!nrow(domain_summary) || !"domain" %in% names(domain_summary)) return(list())
  rows <- list()
  sort_order <- start_sort
  labels <- c(weight = "Weight", height = "Height")
  descriptors <- c(weight = "Vægt", height = "Højde")
  domain_keys <- vapply(domain_summary$domain, semantic_id_from, character(1))
  for (domain in intersect(names(labels), domain_keys)) {
    hit <- domain_summary[domain_keys == domain, , drop = FALSE]
    if (!nrow(hit)) next
    for (stat in intersect(c("p05_numeric", "median_numeric", "p95_numeric"), names(hit))) {
      rows[[length(rows) + 1L]] <- product_distribution_row(
        panel_id = "clinical_vitals",
        clinical_concept_id = domain,
        clinical_variable = labels[[domain]],
        distribution_type = "numeric_summary",
        source_name = "SP_VitaleVaerdier",
        raw_column = "numericvalue",
        raw_descriptor = descriptors[[domain]],
        display_value = paste(labels[[domain]], stat),
        n = suppressWarnings(as.numeric(hit$n_rows[[1]] %||% NA_real_)),
        statistic = stat,
        statistic_value = as.character(hit[[stat]][[1]] %||% ""),
        evidence_file = "cartography_sp_vitalevaerdier_domain_summary.tsv",
        count_scope = "cartography_scan",
        denominator_scope = "cartography_scan",
        profile_scope = "cartography_scan",
        sort_order = sort_order
      )
      sort_order <- sort_order + 1L
    }
  }
  rows
}

product_registry_section_distributions <- function(start_sort = 1L) {
  specs <- list(
    reg_damyda = c("Baseline disease markers", "Staging/risk", "Treatment", "Response/relapse", "Bone disease / imaging", "Cytogenetics/molecular", "Raw fields"),
    reg_lyfo = c("Source / coverage", "Subtype mix", "Staging and risk", "B symptoms and bulk disease", "Performance status", "Baseline disease markers", "Treatment and regimen fields", "Response / follow-up / relapse fields", "Disease localization", "Raw names / data lineage", "Use cases", "Caveats"),
    reg_cll = c("Binet stage", "IGHV", "FISH/cytogenetics", "TP53 if available", "Treatment/targeted therapies", "Response/MRD if available", "Raw fields"),
    clinical_imaging = c("Nationwide procedure-code imaging", "Registry modality fields", "EHR-native imaging metadata/report text"),
    clinical_microbiology = c("PERSIMUNE analysis/culture/resistance/microscopy", "SP blood-culture workflow", "Sample material/result class/organism-domain framing")
  )
  rows <- list()
  sort_order <- start_sort
  for (panel_id in names(specs)) {
    for (label in specs[[panel_id]]) {
      rows[[length(rows) + 1L]] <- product_distribution_row(
        panel_id = panel_id,
        clinical_concept_id = semantic_id_from(c(panel_id, label)),
        clinical_variable = label,
        distribution_type = "clinical_section",
        display_value = label,
        value_class = "section",
        count_scope = "not_available",
        denominator_scope = "not_available",
        profile_scope = "not_available",
        sort_order = sort_order
      )
      sort_order <- sort_order + 1L
    }
  }
  rows
}

product_panel_kpis <- function(sources, panels, raw_fields, distributions, project_root = ".") {
  specs <- product_panel_specs()
  rows <- list()
  sort_order <- 1L
  for (i in seq_len(nrow(specs))) {
    panel_id <- specs$panel_id[[i]]
    panel_raw <- raw_fields[raw_fields$panel_id == panel_id, , drop = FALSE]
    panel_dist <- distributions[distributions$panel_id == panel_id, , drop = FALSE]
    rows[[length(rows) + 1L]] <- product_kpi_row(panel_id, "raw_fields", "Key raw fields", nrow(panel_raw), "", "", "", "cartography_scan", sort_order)
    sort_order <- sort_order + 1L
    rows[[length(rows) + 1L]] <- product_kpi_row(panel_id, "related_concepts", "Related clinical variables", length(unique_nonblank(panel_raw$clinical_concept_id)), "", "", "", "cartography_scan", sort_order)
    sort_order <- sort_order + 1L
    rows[[length(rows) + 1L]] <- product_kpi_row(panel_id, "distributions", "Distribution rows", nrow(panel_dist), "", "", "", "cartography_scan", sort_order)
    sort_order <- sort_order + 1L
  }
  rows <- c(rows, product_source_kpis(sources, specs, sort_order))
  rows <- c(rows, product_vital_kpis(project_root, length(rows) + 1L))
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_panel_kpis())
  align_product_frame(out, names(empty_panel_kpis()))
}

product_kpi_row <- function(panel_id, kpi_id, label, value, unit = "", source_name = "", evidence_file = "",
                            scope = "unknown", sort_order = 1L) {
  data.frame(
    panel_id = panel_id,
    kpi_id = kpi_id,
    label = label,
    value = as.character(value %||% ""),
    unit = unit %||% "",
    source_name = source_name %||% "",
    evidence_file = evidence_file %||% "",
    count_scope = scope,
    denominator_scope = scope,
    profile_scope = scope,
    sort_order = sort_order,
    stringsAsFactors = FALSE
  )
}

product_source_kpis <- function(sources, specs, start_sort = 1L) {
  if (!is.data.frame(sources) || !nrow(sources)) return(list())
  rows <- list()
  sort_order <- start_sort
  for (i in seq_len(nrow(specs))) {
    patterns <- product_source_patterns_for_panel(specs$panel_id[[i]])
    if (!length(patterns)) next
    src <- review_sources_like(public_sources(sources), patterns)
    if (!nrow(src)) next
    total_rows <- sum(suppressWarnings(as.numeric(src$n_rows)), na.rm = TRUE)
    rows[[length(rows) + 1L]] <- product_kpi_row(specs$panel_id[[i]], "mapped_sources", "Mapped sources", nrow(src), "", paste(unique_nonblank(src$table_name), collapse = "; "), "atlas_sources.csv", "full_source", sort_order)
    sort_order <- sort_order + 1L
    rows[[length(rows) + 1L]] <- product_kpi_row(specs$panel_id[[i]], "source_rows", "Source rows", total_rows, "rows", paste(unique_nonblank(src$table_name), collapse = "; "), "atlas_sources.csv", "full_source", sort_order)
    sort_order <- sort_order + 1L
  }
  rows
}

product_vital_kpis <- function(project_root, start_sort = 1L) {
  domain_summary <- read_cartography_table("cartography_sp_vitalevaerdier_domain_summary.tsv", project_root)
  if (!nrow(domain_summary)) return(list())
  rows <- list()
  sort_order <- start_sort
  for (domain in c("weight", "height")) {
    hit <- domain_summary[semantic_id_from(domain_summary$domain) == domain, , drop = FALSE]
    if (!nrow(hit)) next
    label <- if (domain == "weight") "Weight rows" else "Height rows"
    rows[[length(rows) + 1L]] <- product_kpi_row("clinical_vitals", paste0(domain, "_rows"), label, hit$n_rows[[1]], "rows", "SP_VitaleVaerdier", "cartography_sp_vitalevaerdier_domain_summary.tsv", "cartography_scan", sort_order)
    sort_order <- sort_order + 1L
    rows[[length(rows) + 1L]] <- product_kpi_row("clinical_vitals", paste0(domain, "_patients"), paste(if (domain == "weight") "Weight" else "Height", "patients"), hit$n_patients[[1]], "patients", "SP_VitaleVaerdier", "cartography_sp_vitalevaerdier_domain_summary.tsv", "cartography_scan", sort_order)
    sort_order <- sort_order + 1L
  }
  rows
}

product_domain_panels <- function(raw_fields, kpis, distributions, concepts) {
  specs <- product_panel_specs()
  rows <- lapply(seq_len(nrow(specs)), function(i) {
    panel_id <- specs$panel_id[[i]]
    panel_raw <- raw_fields[raw_fields$panel_id == panel_id, , drop = FALSE]
    panel_kpi <- kpis[kpis$panel_id == panel_id, , drop = FALSE]
    panel_dist <- distributions[distributions$panel_id == panel_id, , drop = FALSE]
    related <- unique_nonblank(panel_raw$clinical_variable)
    status <- product_panel_status(panel_raw, panel_kpi, panel_dist)
    missing <- if (identical(status, "placeholder")) product_missing_output_for_panel(panel_id) else specs$missing_upstream_file[[i]]
    data.frame(
      panel_id = panel_id,
      panel_section = specs$panel_section[[i]],
      panel_title = specs$panel_title[[i]],
      clinical_purpose = specs$clinical_purpose[[i]],
      panel_status = status,
      source_names = paste(unique_nonblank(panel_raw$source_name), collapse = "; "),
      related_clinical_concepts = paste(head(related, 30), collapse = "; "),
      use_cases = specs$use_cases[[i]],
      caveats = specs$caveats[[i]],
      missing_upstream_file = missing,
      parity_status = status,
      count_scope = product_panel_scope(panel_id, c(panel_kpi$count_scope, panel_dist$count_scope, panel_raw$count_scope)),
      denominator_scope = product_panel_scope(panel_id, c(panel_kpi$denominator_scope, panel_dist$denominator_scope, panel_raw$denominator_scope)),
      profile_scope = product_panel_scope(panel_id, c(panel_kpi$profile_scope, panel_dist$profile_scope, panel_raw$profile_scope)),
      sort_order = specs$sort_order[[i]],
      stringsAsFactors = FALSE
    )
  })
  align_product_frame(bind_rows_base(rows), names(empty_domain_panels()))
}

product_panel_scope <- function(panel_id, scopes) {
  scopes <- unique_nonblank(scopes)
  if (panel_id %in% c("clinical_vitals", "clinical_social_history") && "cartography_scan" %in% scopes) {
    return("cartography_scan")
  }
  product_merge_scopes(scopes)
}

product_panel_parity <- function(domain_panels, kpis, distributions, raw_fields) {
  old <- data.frame(
    old_panel_id = c(
      "reg-damyda", "reg-lyfo", "reg-cll", "reg-diagnoses", "clin-vitals", "clin-social",
      "clin-admissions", "clin-notes", "clin-imaging", "clin-micro", "tx-protocols", "tx-meds",
      "tx-rx", "tx-smr", "tx-antineo", "tx-curated", "lab-biochem", "lab-npu", "lab-concordance",
      "lab-molecular", "lab-biobank", "lab-pathology", "ehr-sp", "ehr-sds", "ehr-operations",
      "infra-schema", "infra-resolved", "infra-unresolved", "infra-hidden"
    ),
    new_panel_id = c(
      "reg_damyda", "reg_lyfo", "reg_cll", "diagnosis_atlas", "clinical_vitals", "clinical_social_history",
      "clinical_adt", "clinical_notes", "clinical_imaging", "clinical_microbiology", "treatment", "treatment",
      "treatment", "treatment", "treatment", "treatment", "laboratory_npu", "laboratory_npu", "laboratory_npu",
      "laboratory_npu", "clinical_biobank", "clinical_pathology", "clinical_adt", "diagnosis_atlas", "clinical_adt",
      "infrastructure_schema", "infrastructure_resolution", "infrastructure_unresolved", "infrastructure_hidden"
    ),
    old_title = c(
      "DaMyDa", "LYFO", "DCLLR", "Diagnosis atlas", "Vital signs", "Social history",
      "Admissions, discharges & transfers", "Medical notes", "Medical imaging", "Microbiology & infection atlas",
      "Treatment protocols", "Administered medicine", "Prescriptions", "In-hospital medications", "SKS & ATC treatment codes",
      "Curated treatment cohorts", "Biochemistry atlas", "NPU disease panels", "Cross-source concordance", "Molecular diagnostics",
      "Biobank linkage", "Pathology atlas", "Sundhedsplatformen modules", "SDS nationwide registers", "Hospital operations",
      "PostgreSQL database schema", "Recovered modules", "Datasets not in database", "Untapped database resources"
    ),
    stringsAsFactors = FALSE
  )
  rows <- lapply(seq_len(nrow(old)), function(i) {
    new_id <- old$new_panel_id[[i]]
    panel <- domain_panels[domain_panels$panel_id == new_id, , drop = FALSE]
    if (nrow(panel)) {
      raw_n <- sum(raw_fields$panel_id == new_id, na.rm = TRUE)
      kpi_n <- sum(kpis$panel_id == new_id, na.rm = TRUE)
      dist_n <- sum(distributions$panel_id == new_id, na.rm = TRUE)
      status <- if (nzchar(panel$clinical_purpose[[1]]) && raw_n > 0 && (kpi_n > 0 || dist_n > 0) && nzchar(panel$use_cases[[1]]) && nzchar(panel$caveats[[1]])) {
        panel$panel_status[[1]]
      } else if (raw_n > 0 || kpi_n > 0 || dist_n > 0) {
        "partial"
      } else {
        "placeholder"
      }
      missing <- product_missing_items(panel, raw_n, kpi_n, dist_n)
      title <- panel$panel_title[[1]]
      next_output <- if (identical(status, "placeholder")) product_missing_output_for_panel(new_id) else ""
    } else {
      status <- "placeholder"
      missing <- "No generated domain panel row"
      title <- old$old_title[[i]]
      next_output <- product_missing_output_for_panel(new_id)
    }
    data.frame(
      old_panel_id = old$old_panel_id[[i]],
      new_panel_id = new_id,
      old_title = old$old_title[[i]],
      new_title = title,
      parity_status = status,
      missing_items = missing,
      next_required_output = next_output,
      stringsAsFactors = FALSE
    )
  })
  align_product_frame(bind_rows_base(rows), names(empty_panel_parity()))
}

product_panel_status <- function(panel_raw, panel_kpi, panel_dist) {
  has_raw <- is.data.frame(panel_raw) && nrow(panel_raw) > 0
  has_kpi_or_dist <- (is.data.frame(panel_kpi) && nrow(panel_kpi) > 0) || (is.data.frame(panel_dist) && nrow(panel_dist) > 0)
  if (has_raw && has_kpi_or_dist) "restored" else if (has_raw || has_kpi_or_dist) "partial" else "placeholder"
}

product_missing_items <- function(panel, raw_n, kpi_n, dist_n) {
  missing <- character()
  if (!nrow(panel) || !nzchar(panel$clinical_purpose[[1]] %||% "")) missing <- c(missing, "clinical purpose")
  if (raw_n <= 0) missing <- c(missing, "raw fields")
  if (kpi_n <= 0 && dist_n <= 0) missing <- c(missing, "KPIs/distributions")
  if (!nrow(panel) || !nzchar(panel$use_cases[[1]] %||% "")) missing <- c(missing, "use cases")
  if (!nrow(panel) || !nzchar(panel$caveats[[1]] %||% "")) missing <- c(missing, "caveats")
  paste(missing, collapse = "; ")
}

product_missing_output_for_panel <- function(panel_id) {
  mapping <- c(
    infrastructure_schema = "atlas_source_resolution.csv",
    infrastructure_resolution = "atlas_source_resolution.csv",
    infrastructure_unresolved = "atlas_source_resolution.csv",
    infrastructure_hidden = "atlas_run_action_items.csv",
    clinical_notes = "cartography_part4_sp_journalnotater_del1_columns.tsv",
    clinical_adt = "cartography_part4_sp_adt_haendelser_columns.tsv"
  )
  mapping[[panel_id]] %||% "atlas_semantic_data_dictionary.csv"
}

product_source_patterns_for_panel <- function(panel_id) {
  switch(panel_id,
    reg_damyda = c("damyda"),
    reg_lyfo = c("lyfo"),
    reg_cll = c("cll"),
    diagnosis_atlas = c("diagnos", "diag", "dalycare"),
    clinical_vitals = c("vitale", "vital", "height", "weight"),
    clinical_social_history = c("social", "socialhx"),
    clinical_adt = c("adt", "adm", "kontakt", "icu", "ita"),
    clinical_notes = c("journal", "note", "epikur"),
    clinical_imaging = c("billed", "imaging", "radiolog", "scan"),
    clinical_microbiology = c("micro", "bloddyrkning", "culture"),
    treatment = c("medicin", "treatment", "behandling", "atc", "sks", "plan"),
    laboratory_npu = c("lab", "prove", "npu", "biochem"),
    clinical_pathology = c("pato", "snomed", "mikro"),
    clinical_biobank = c("biobank", "sample"),
    character()
  )
}

product_panel_for_concept <- function(concept_id, variable, source_name = "", group = "") {
  group <- group %||% ""
  source_name <- source_name %||% ""
  if (grepl("DaMyDa", source_name, ignore.case = TRUE)) return("reg_damyda")
  if (grepl("LYFO", source_name, ignore.case = TRUE)) return("reg_lyfo")
  if (grepl("CLL", source_name, ignore.case = TRUE) && !grepl("LAB", source_name, ignore.case = TRUE)) return("reg_cll")
  if (group == "Treatment") return("treatment")
  if (group == "Laboratory" || concept_id %in% c("haemoglobin", "creatinine", "egfr", "leukocytes", "ldh", "albumin", "crp", "immunoglobulin")) return("laboratory_npu")
  if (group == "Imaging") return("clinical_imaging")
  if (group == "Microbiology") return("clinical_microbiology")
  if (group == "Pathology") return("clinical_pathology")
  if (group == "Biobank") return("clinical_biobank")
  if (concept_id %in% c("smoking_status", "alcohol_use")) return("clinical_social_history")
  if (concept_id %in% c("height", "weight", "bmi", "vital_numeric_measurement_value")) return("clinical_vitals")
  "data_dictionary"
}

product_normalize_panel_id <- function(panel_id, row = NULL) {
  panel_id <- as.character(panel_id %||% "")
  aliases <- c(
    clinical_social_history = "clinical_social_history",
    clinical_vitals = "clinical_vitals",
    clinical_imaging = "clinical_imaging",
    clinical_microbiology = "clinical_microbiology",
    clinical_pathology = "clinical_pathology",
    clinical_biobank = "clinical_biobank",
    clinical_outcomes = "diagnosis_atlas",
    reg_damyda = "reg_damyda",
    reg_lyfo = "reg_lyfo",
    reg_cll = "reg_cll",
    laboratory_npu = "laboratory_npu",
    treatment = "treatment"
  )
  if (panel_id %in% names(aliases)) return(aliases[[panel_id]])
  if (!is.null(row) && is.data.frame(row) && nrow(row)) {
    return(product_panel_for_concept(row$clinical_concept_id[[1]], row$clinical_variable[[1]], row$source_name[[1]], row$clinical_group[[1]]))
  }
  panel_id
}

product_panel_section <- function(panel_id) {
  specs <- product_panel_specs()
  hit <- specs$panel_section[match(panel_id, specs$panel_id)]
  hit[[1]] %||% "Data Dictionary"
}

product_raw_field_label <- function(row) {
  source <- row$source_name[[1]] %||% ""
  column <- row$raw_column[[1]] %||% ""
  descriptor <- row$raw_descriptor[[1]] %||% ""
  code <- row$raw_code[[1]] %||% ""
  value <- row$raw_value[[1]] %||% ""
  variable <- row$clinical_variable[[1]] %||% ""
  lhs <- if (nzchar(code)) {
    code
  } else if (nzchar(column) && nzchar(descriptor)) {
    paste0(source, ".", column, " = ", descriptor)
  } else if (nzchar(column) && nzchar(value)) {
    paste0(source, ".", column, " = ", value)
  } else if (nzchar(column)) {
    paste0(source, ".", column)
  } else if (nzchar(descriptor)) {
    paste0(source, " descriptor ", descriptor)
  } else {
    source
  }
  paste(lhs, "->", variable)
}

product_best_label <- function(x) {
  values <- unique_nonblank(x)
  if (!length(values)) return("")
  tab <- sort(table(x[x %in% values]), decreasing = TRUE)
  names(tab)[[1]]
}

product_best_source <- function(rows) {
  sources <- unique_nonblank(rows$source_name)
  if (!length(sources)) return("")
  preferred <- c("SP_VitaleVaerdier", "SP_Social_Hx", "RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL", "LABKA", "SDS_lab_forsker", "SP_AlleProvesvar", "PERSIMUNE")
  hit <- intersect(preferred, sources)
  if (length(hit)) hit[[1]] else sources[[1]]
}

product_sum_numeric <- function(x) {
  y <- suppressWarnings(as.numeric(x))
  if (!length(y) || all(is.na(y))) return(NA_real_)
  sum(y, na.rm = TRUE)
}

product_concept_status <- function(rows) {
  statuses <- unique_nonblank(rows$mapping_status)
  if ("confirmed" %in% statuses) return("available")
  if ("inferred" %in% statuses) return("inferred")
  if ("candidate" %in% statuses) return("candidate")
  if ("not_present" %in% statuses || "unresolved" %in% statuses) return("not_yet_profiled")
  "available"
}

product_concept_purpose <- function(id, variable, rows) {
  known <- list(
    smoking_status = "Lifestyle covariate describing tobacco exposure status from SP social history.",
    alcohol_use = "Lifestyle covariate describing alcohol-use status from SP social history.",
    weight = "Anthropometric measurement for baseline/frailty and longitudinal physiology analyses.",
    height = "Anthropometric measurement required for BMI and body-size adjustment.",
    vital_numeric_measurement_value = "Numeric value column storing SP vital-sign measurements in long descriptor-value format.",
    ldh = "Disease marker and prognostic laboratory/registry variable.",
    haemoglobin = "Core haematology marker used for anaemia, disease burden, and treatment-readiness analyses.",
    creatinine = "Renal function marker used for comorbidity, treatment eligibility, and myeloma renal involvement.",
    egfr = "Derived kidney-function marker for renal stratification and treatment eligibility.",
    leukocytes = "Blood-count marker for immune status, disease burden, and infection-risk studies."
  )
  known[[id]] %||% product_best_label(rows$semantic_meaning) %||% paste(variable, "availability across DALY-CARE sources.")
}

product_concept_use_cases <- function(id, variable, rows) {
  known <- list(
    smoking_status = "Smoking adjustment; lifestyle subgrouping; missingness/not-asked audits.",
    alcohol_use = "Alcohol-use adjustment; lifestyle subgrouping; missingness/not-asked audits.",
    weight = "Baseline covariate extraction; frailty adjustment; dosing/body-size context.",
    height = "BMI derivation; body-size adjustment.",
    bmi = "Derived anthropometric covariate for baseline/frailty analyses.",
    ldh = "Risk/staging models, disease activity, and laboratory availability review.",
    haemoglobin = "Anaemia phenotyping, treatment readiness, disease burden.",
    creatinine = "Renal function, treatment eligibility, comorbidity adjustment.",
    egfr = "Renal function stratification and treatment eligibility.",
    leukocytes = "Blood-count phenotyping and infection-risk context."
  )
  known[[id]] %||% "Clinical feasibility review, cohort phenotyping, and source-selection planning."
}

product_concept_caveat <- function(id, rows) {
  known <- list(
    smoking_status = "Not asked, passive exposure, unknown, and true missing values require separate handling.",
    alcohol_use = "Not asked, deferred, not applicable, and true missing values require separate handling.",
    weight = "Repeated measures require a baseline window and outlier filtering.",
    height = "Repeated measures and implausible values require outlier filtering.",
    bmi = "Derived from height and weight; not necessarily stored directly.",
    vital_numeric_measurement_value = "Interpret values only with the corresponding descriptor and unit context.",
    ldh = "Units and source-specific code systems must be harmonized.",
    haemoglobin = "Units/source coding may differ; use NPU/source-specific definitions.",
    creatinine = "Creatinine and CRP-like fields must not be confused; inspect raw column/code meaning.",
    egfr = "Formula/version may vary by source code.",
    leukocytes = "Use source-specific code definitions and units."
  )
  known[[id]] %||% product_best_label(rows$clinical_caveat)
}

product_scope_for_evidence <- function(evidence_file) {
  evidence_file <- tolower(as.character(evidence_file %||% ""))
  if (!nzchar(evidence_file)) return("unknown")
  if (grepl("schema_overview|columns", evidence_file)) return("cartography_scan")
  if (grepl("top|top50", evidence_file)) return("top_n_scan")
  if (grepl("max_scan_100000", evidence_file)) return("max_scan_100000")
  if (grepl("value_counts|value_frequencies|domain_summary|numeric_summary|disease_panels|concordance|known_field|resolution|candidate|descriptor|cartography", evidence_file)) return("cartography_scan")
  "unknown"
}

product_merge_scopes <- function(scopes) {
  scopes <- unique_nonblank(scopes)
  if (!length(scopes)) return("not_available")
  priority <- c("full_table", "full_source", "cartography_scan", "top_n_scan", "max_scan_100000", "unknown", "not_available")
  hit <- intersect(priority, scopes)
  hit[[1]] %||% "unknown"
}

product_dedupe_raw_fields <- function(x) {
  key <- paste(x$panel_id, x$source_name, x$raw_column, x$raw_descriptor, x$raw_code, x$raw_value, x$clinical_variable, sep = "\r")
  x[!duplicated(key), , drop = FALSE]
}

product_identifier_like_column <- function(name) {
  name <- as.character(name %||% "")
  is_sensitive_column(name) ||
    grepl("(^id$|_id$|(^|_)id_|identifier|patient|person|cpr|pnr|recnum|record|rekv)", name, ignore.case = TRUE)
}

align_product_frame <- function(x, cols) {
  if (!is.data.frame(x)) x <- data.frame(stringsAsFactors = FALSE)
  for (col in setdiff(cols, names(x))) x[[col]] <- NA
  x <- x[cols]
  x
}
