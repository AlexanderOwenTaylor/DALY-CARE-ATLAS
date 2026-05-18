semantic_dictionary_columns <- function() {
  c(
    "semantic_id", "clinical_concept_id", "clinical_variable", "clinical_group",
    "clinical_subgroup", "semantic_meaning", "source_name", "object_name",
    "schema_name", "table_name", "raw_column", "raw_descriptor", "raw_code",
    "raw_value", "code_system", "unit", "value_type", "data_shape",
    "patient_id_column", "date_column", "value_column", "source_level",
    "geography", "n_rows", "n_patients", "pct_non_missing", "min_date",
    "max_date", "evidence_file", "evidence_filter", "mapping_confidence",
    "mapping_status", "privacy_note", "clinical_caveat", "search_terms"
  )
}

semantic_value_map_columns <- function() {
  c(
    "semantic_id", "clinical_concept_id", "clinical_variable", "source_name",
    "object_name", "raw_column", "raw_value", "display_value", "value_class",
    "clinical_interpretation", "n", "pct", "denominator_label",
    "evidence_file", "mapping_confidence", "suppressed", "notes"
  )
}

semantic_code_map_columns <- function() {
  c(
    "semantic_id", "clinical_concept_id", "clinical_variable", "clinical_group",
    "source_name", "object_name", "code_system", "code", "code_name",
    "panel", "n_rows", "n_patients", "evidence_file", "mapping_confidence",
    "notes"
  )
}

semantic_panel_links_columns <- function() {
  c("semantic_id", "clinical_concept_id", "panel_id", "panel_section", "relationship", "sort_order")
}

empty_semantic_data_dictionary <- function() {
  empty_df(
    semantic_id = character(), clinical_concept_id = character(), clinical_variable = character(),
    clinical_group = character(), clinical_subgroup = character(), semantic_meaning = character(),
    source_name = character(), object_name = character(), schema_name = character(), table_name = character(),
    raw_column = character(), raw_descriptor = character(), raw_code = character(), raw_value = character(),
    code_system = character(), unit = character(), value_type = character(), data_shape = character(),
    patient_id_column = character(), date_column = character(), value_column = character(),
    source_level = character(), geography = character(), n_rows = numeric(), n_patients = numeric(),
    pct_non_missing = numeric(), min_date = character(), max_date = character(), evidence_file = character(),
    evidence_filter = character(), mapping_confidence = character(), mapping_status = character(),
    privacy_note = character(), clinical_caveat = character(), search_terms = character()
  )
}

empty_semantic_value_map <- function() {
  empty_df(
    semantic_id = character(), clinical_concept_id = character(), clinical_variable = character(),
    source_name = character(), object_name = character(), raw_column = character(), raw_value = character(),
    display_value = character(), value_class = character(), clinical_interpretation = character(),
    n = numeric(), pct = numeric(), denominator_label = character(), evidence_file = character(),
    mapping_confidence = character(), suppressed = logical(), notes = character()
  )
}

empty_semantic_code_map <- function() {
  empty_df(
    semantic_id = character(), clinical_concept_id = character(), clinical_variable = character(),
    clinical_group = character(), source_name = character(), object_name = character(),
    code_system = character(), code = character(), code_name = character(), panel = character(),
    n_rows = numeric(), n_patients = numeric(), evidence_file = character(), mapping_confidence = character(),
    notes = character()
  )
}

empty_semantic_panel_links <- function() {
  empty_df(
    semantic_id = character(), clinical_concept_id = character(), panel_id = character(),
    panel_section = character(), relationship = character(), sort_order = integer()
  )
}

empty_semantic_outputs <- function() {
  list(
    dictionary = empty_semantic_data_dictionary(),
    value_map = empty_semantic_value_map(),
    code_map = empty_semantic_code_map(),
    panel_links = empty_semantic_panel_links()
  )
}

cartography_reference_root <- function(project_root = ".") {
  override <- Sys.getenv("DALYCARE_CARTOGRAPHY_PATH", unset = "")
  if (nzchar(override)) {
    return(normalizePath(override, winslash = "/", mustWork = FALSE))
  }
  normalizePath(file.path(project_root, "config", "cartography-reference"), winslash = "/", mustWork = FALSE)
}

cartography_manifest <- function(project_root = ".") {
  root <- cartography_reference_root(project_root)
  if (file.exists(root) && tolower(tools::file_ext(root)) == "zip") {
    return(data.frame(stringsAsFactors = FALSE))
  }
  path <- file.path(root, "manifest.tsv")
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  suppressWarnings(read_delimited_file(path))
}

cartography_reference_file <- function(filename, project_root = ".") {
  root <- cartography_reference_root(project_root)
  if (file.exists(root) && tolower(tools::file_ext(root)) == "zip") {
    listing <- utils::unzip(root, list = TRUE)
    hit <- listing$Name[basename(listing$Name) == filename]
    if (!length(hit)) {
      hit <- listing$Name[basename(listing$Name) == sub("\\.tsv$", ".csv", filename)]
    }
    if (!length(hit)) return(NA_character_)
    exdir <- file.path(tempdir(), paste0("dalycare_cartography_", tools::file_path_sans_ext(basename(root))))
    dir_create(exdir)
    utils::unzip(root, files = hit[[1]], exdir = exdir, overwrite = TRUE)
    return(file.path(exdir, hit[[1]]))
  }
  candidates <- c(
    file.path(root, "files", filename),
    file.path(root, "files", sub("\\.tsv$", ".csv", filename)),
    file.path(root, filename),
    file.path(root, sub("\\.tsv$", ".csv", filename))
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit)) hit[[1]] else NA_character_
}

read_cartography_table <- function(filename, project_root = ".") {
  path <- cartography_reference_file(filename, project_root)
  if (is.na(path) || !file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  if (file.info(path)$size <= 3) return(data.frame(stringsAsFactors = FALSE))
  suppressWarnings(read_delimited_file(path))
}

validate_cartography_reference <- function(project_root = ".") {
  required <- c(
    "cartography_sp_social_hx_resolution.tsv",
    "cartography_sp_social_hx_value_frequencies.tsv",
    "cartography_sp_vitalevaerdier_resolution.tsv",
    "cartography_sp_vitalevaerdier_descriptors.tsv",
    "cartography_damyda_known_field_map.tsv",
    "cartography_npu_disease_panels.tsv"
  )
  missing <- required[!vapply(required, function(file) {
    path <- cartography_reference_file(file, project_root)
    !is.na(path) && file.exists(path)
  }, logical(1))]
  if (length(missing)) {
    stop("Cartography reference is missing required files: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  manifest <- cartography_manifest(project_root)
  if (nrow(manifest) && all(c("reference_filename", "curated_rows") %in% names(manifest))) {
    manifest_required <- manifest[manifest$reference_filename %in% required, , drop = FALSE]
    for (i in seq_len(nrow(manifest_required))) {
      path <- cartography_reference_file(manifest_required$reference_filename[[i]], project_root)
      if (is.na(path) || !file.exists(path)) next
      observed <- if (file.info(path)$size <= 3) 0L else nrow(suppressWarnings(read_delimited_file(path)))
      expected <- suppressWarnings(as.integer(manifest_required$curated_rows[[i]]))
      if (!is.na(expected) && observed != expected) {
        stop(
          "Cartography reference row-count mismatch for ",
          manifest_required$reference_filename[[i]],
          ": manifest=", expected, ", observed=", observed,
          call. = FALSE
        )
      }
    }
  }
  invisible(TRUE)
}

build_semantic_outputs <- function(project_root = ".", sources = NULL, column_profiles = NULL,
                                   panels = list(), min_cell_count = atlas_min_cell_count()) {
  validate_cartography_reference(project_root)
  pieces <- list(
    semantic_social_history(project_root, min_cell_count),
    semantic_vitals(project_root, min_cell_count),
    semantic_registry_sources(project_root, min_cell_count),
    semantic_laboratory_sources(project_root, min_cell_count),
    semantic_treatment_sources(project_root, min_cell_count),
    semantic_domain_sources(project_root, min_cell_count),
    semantic_candidate_discovery(project_root, min_cell_count)
  )
  dictionary <- bind_rows_base(lapply(pieces, `[[`, "dictionary"))
  value_map <- bind_rows_base(lapply(pieces, `[[`, "value_map"))
  code_map <- bind_rows_base(lapply(pieces, `[[`, "code_map"))
  panel_links <- bind_rows_base(lapply(pieces, `[[`, "panel_links"))

  dictionary <- semantic_apply_treatment_source_context_dictionary(dictionary)
  code_map <- semantic_apply_treatment_source_context_code_map(code_map)
  dictionary <- semantic_dedupe_dictionary(dictionary)
  value_map <- semantic_dedupe_value_map(value_map)
  code_map <- semantic_dedupe_code_map(code_map)
  if (!nrow(panel_links) && nrow(dictionary)) {
    panel_links <- semantic_panel_links_for_dictionary(dictionary)
  } else if (nrow(dictionary)) {
    panel_links <- semantic_dedupe_panel_links(bind_rows_base(list(panel_links, semantic_panel_links_for_dictionary(dictionary))))
  }
  out <- list(
    dictionary = align_semantic_frame(dictionary, semantic_dictionary_columns()),
    value_map = align_semantic_frame(value_map, semantic_value_map_columns()),
    code_map = align_semantic_frame(code_map, semantic_code_map_columns()),
    panel_links = align_semantic_frame(panel_links, semantic_panel_links_columns())
  )
  normalize_semantic_source_names(out)
}

semantic_social_history <- function(project_root, min_cell_count) {
  resolution <- read_cartography_table("cartography_sp_social_hx_resolution.tsv", project_root)
  frequencies <- read_cartography_table("cartography_sp_social_hx_value_frequencies.tsv", project_root)
  if (!nrow(resolution)) return(empty_semantic_outputs())
  source_name <- first_nonblank(resolution$source_name, "SP_Social_Hx")
  smoking_col <- first_nonblank(resolution$smoking_col, "ryger")
  alcohol_col <- first_nonblank(resolution$alcohol_col, "drikker")
  dict <- bind_rows_base(list(
    semantic_row(
      semantic_id = "sp_social_hx_ryger_smoking_status",
      clinical_concept_id = "smoking_status",
      clinical_variable = "Smoking status",
      clinical_group = "Lifestyle",
      clinical_subgroup = "Social history",
      semantic_meaning = "Smoking or tobacco-use status recorded in the SP social-history table.",
      source_name = source_name,
      object_name = source_name,
      raw_column = smoking_col,
      code_system = "local_SP_field",
      value_type = "categorical",
      data_shape = "wide_table",
      source_level = "SP/EHR",
      geography = "eastern Denmark/SP",
      n_rows = semantic_column_total(frequencies, smoking_col, min_cell_count),
      evidence_file = "cartography_sp_social_hx_resolution.tsv; cartography_sp_social_hx_value_frequencies.tsv",
      evidence_filter = paste0("column=", smoking_col),
      mapping_confidence = "high",
      mapping_status = "confirmed",
      privacy_note = "aggregate_only",
      clinical_caveat = "Social-history responses distinguish true no, not asked, passive exposure, and former use.",
      search_terms = semantic_terms(c("smoking", "tobacco", "ryger", "cigarette", "former smoker", "never smoker", smoking_col))
    ),
    semantic_row(
      semantic_id = "sp_social_hx_drikker_alcohol_use",
      clinical_concept_id = "alcohol_use",
      clinical_variable = "Alcohol use",
      clinical_group = "Lifestyle",
      clinical_subgroup = "Social history",
      semantic_meaning = "Alcohol-use status recorded in the SP social-history table.",
      source_name = source_name,
      object_name = source_name,
      raw_column = alcohol_col,
      code_system = "local_SP_field",
      value_type = "categorical",
      data_shape = "wide_table",
      source_level = "SP/EHR",
      geography = "eastern Denmark/SP",
      n_rows = semantic_column_total(frequencies, alcohol_col, min_cell_count),
      evidence_file = "cartography_sp_social_hx_resolution.tsv; cartography_sp_social_hx_value_frequencies.tsv",
      evidence_filter = paste0("column=", alcohol_col),
      mapping_confidence = "high",
      mapping_status = "confirmed",
      privacy_note = "aggregate_only",
      clinical_caveat = "Cartography denominator is the scanned social-history response denominator.",
      search_terms = semantic_terms(c("alcohol", "drikker", "drinks", "alcohol use", alcohol_col))
    )
  ))
  value_map <- semantic_social_value_map(frequencies, source_name, smoking_col, alcohol_col, min_cell_count)
  list(
    dictionary = dict,
    value_map = value_map,
    code_map = empty_semantic_code_map(),
    panel_links = semantic_panel_links_for_dictionary(dict)
  )
}

semantic_social_value_map <- function(frequencies, source_name, smoking_col, alcohol_col, min_cell_count) {
  if (!nrow(frequencies) || !"column" %in% names(frequencies) || !"value" %in% names(frequencies)) {
    return(empty_semantic_value_map())
  }
  smoking_values <- data.frame(
    raw_value = c("Er holdt op", "Aldrig", "Ja", "Ikke spurgt", "Passiv"),
    display_value = c("Former smoker", "Never smoker", "Current smoker", "Not asked", "Passive exposure"),
    value_class = c("former", "never", "current", "not_asked", "passive_exposure"),
    clinical_interpretation = c(
      "Former smoker or stopped tobacco use.",
      "Never smoker.",
      "Current smoker.",
      "Smoking status was not asked.",
      "Passive smoke exposure."
    ),
    stringsAsFactors = FALSE
  )
  alcohol_values <- data.frame(
    raw_value = c("Ja", "Nej", "Ikke aktuelt", "Aldrig", "Ikke spurgt", "Udskyd"),
    display_value = c("Alcohol use yes", "No alcohol use", "Not applicable", "Never drinks", "Not asked", "Deferred"),
    value_class = c("yes", "no", "not_applicable", "never", "not_asked", "deferred"),
    clinical_interpretation = c(
      "Alcohol use recorded as yes.",
      "Alcohol use recorded as no.",
      "Alcohol question marked not applicable.",
      "Never drinks alcohol.",
      "Alcohol status was not asked.",
      "Alcohol question deferred."
    ),
    stringsAsFactors = FALSE
  )
  bind_rows_base(list(
    semantic_value_rows_for_column(
      frequencies, source_name, smoking_col, "sp_social_hx_ryger_smoking_status",
      "smoking_status", "Smoking status", smoking_values,
      "cartography scanned rows for SP_Social_Hx.ryger", min_cell_count
    ),
    semantic_value_rows_for_column(
      frequencies, source_name, alcohol_col, "sp_social_hx_drikker_alcohol_use",
      "alcohol_use", "Alcohol use", alcohol_values,
      "cartography scanned rows for SP_Social_Hx.drikker", min_cell_count
    )
  ))
}

semantic_vitals <- function(project_root, min_cell_count) {
  resolution <- read_cartography_table("cartography_sp_vitalevaerdier_resolution.tsv", project_root)
  descriptors <- read_cartography_table("cartography_sp_vitalevaerdier_descriptors.tsv", project_root)
  domain_summary <- read_cartography_table("cartography_sp_vitalevaerdier_domain_summary.tsv", project_root)
  if (!nrow(descriptors)) return(empty_semantic_outputs())
  source_name <- first_nonblank(resolution$source_name, "SP_VitaleVaerdier")
  id_col <- first_nonblank(resolution$id_col, "")
  date_col <- first_nonblank(resolution$date_col, "")
  name_col <- first_nonblank(resolution$name_col, "displayname")
  value_col <- first_nonblank(resolution$value_col, "numericvalue")
  unit_col <- first_nonblank(resolution$unit_col, "")
  descriptor_rows <- lapply(seq_len(nrow(descriptors)), function(i) {
    descriptor <- descriptors$displayname[[i]]
    def <- vital_descriptor_definition(descriptor)
    summary_row <- semantic_vital_summary_row(domain_summary, descriptor)
    semantic_row(
      semantic_id = semantic_id_from(c("sp_vitalevaerdier", descriptor, def$concept_id)),
      clinical_concept_id = def$concept_id,
      clinical_variable = def$variable,
      clinical_group = "Vitals",
      clinical_subgroup = def$subgroup,
      semantic_meaning = def$meaning,
      source_name = source_name,
      object_name = source_name,
      raw_column = name_col,
      raw_descriptor = descriptor,
      code_system = "local_SP_descriptor",
      unit = first_nonblank(summary_row$top_units, ""),
      value_type = "numeric",
      data_shape = "long_descriptor_table",
      patient_id_column = id_col,
      date_column = date_col,
      value_column = value_col,
      source_level = "SP/EHR",
      geography = "eastern Denmark/SP",
      n_rows = semantic_suppress_count(descriptors$n_rows[[i]], min_cell_count),
      n_patients = semantic_suppress_count(descriptors$n_patients[[i]], min_cell_count),
      min_date = first_nonblank(descriptors$min_date[[i]], ""),
      max_date = first_nonblank(descriptors$max_date[[i]], ""),
      evidence_file = "cartography_sp_vitalevaerdier_resolution.tsv; cartography_sp_vitalevaerdier_descriptors.tsv; cartography_sp_vitalevaerdier_domain_summary.tsv",
      evidence_filter = paste0(name_col, "=", descriptor),
      mapping_confidence = def$confidence,
      mapping_status = def$status,
      privacy_note = "aggregate_only",
      clinical_caveat = semantic_vital_caveat(def, summary_row),
      search_terms = semantic_terms(c(def$terms, descriptor, source_name, name_col, value_col))
    )
  })
  value_row <- semantic_row(
    semantic_id = "sp_vitalevaerdier_numericvalue_measurement_value",
    clinical_concept_id = "vital_numeric_measurement_value",
    clinical_variable = "Vital numeric measurement value",
    clinical_group = "Vitals",
    clinical_subgroup = "Observation model",
    semantic_meaning = "Numeric measurement value paired with the displayname descriptor in the long-format SP vital-sign table.",
    source_name = source_name,
    object_name = source_name,
    raw_column = value_col,
    code_system = "local_SP_field",
    value_type = "numeric",
    data_shape = "long_descriptor_table",
    patient_id_column = id_col,
    date_column = date_col,
    value_column = value_col,
    source_level = "SP/EHR",
    geography = "eastern Denmark/SP",
    evidence_file = "cartography_sp_vitalevaerdier_resolution.tsv",
    evidence_filter = paste0("value_col=", value_col),
    mapping_confidence = "high",
    mapping_status = "confirmed",
    privacy_note = "aggregate_only",
    clinical_caveat = "Interpret numericvalue only together with displayname and unit context.",
    search_terms = semantic_terms(c("numericvalue", "measurement value", "vitals", "observations", value_col))
  )
  bmi_row <- semantic_row(
    semantic_id = "sp_vitalevaerdier_bmi_derived_height_weight",
    clinical_concept_id = "bmi",
    clinical_variable = "BMI",
    clinical_group = "Vitals",
    clinical_subgroup = "Anthropometrics",
    semantic_meaning = "Derived body mass index from height and weight observations when baseline-window logic is defined.",
    source_name = source_name,
    object_name = source_name,
    raw_column = name_col,
    raw_descriptor = "Derived from height and weight",
    value_column = value_col,
    value_type = "numeric",
    data_shape = "derived",
    patient_id_column = id_col,
    date_column = date_col,
    source_level = "SP/EHR",
    geography = "eastern Denmark/SP",
    evidence_file = "cartography_sp_vitalevaerdier_domain_summary.tsv",
    evidence_filter = "domain in weight,height",
    mapping_confidence = "medium",
    mapping_status = "inferred",
    privacy_note = "aggregate_only",
    clinical_caveat = "BMI is derived, not directly stored here unless another source proves a BMI field.",
    search_terms = semantic_terms(c("BMI", "body mass index", "height", "weight", "anthropometrics"))
  )
  dict <- bind_rows_base(c(descriptor_rows, list(value_row, bmi_row)))
  list(
    dictionary = dict,
    value_map = empty_semantic_value_map(),
    code_map = empty_semantic_code_map(),
    panel_links = semantic_panel_links_for_dictionary(dict)
  )
}

semantic_registry_sources <- function(project_root, min_cell_count) {
  registry_files <- list(
    RKKP_DaMyDa = list(
      numeric = "cartography_damyda_numeric_summary.tsv",
      values = "cartography_rkkp_damyda_value_counts.tsv",
      known = "cartography_damyda_known_field_map.tsv",
      group = "Registry",
      subgroup = "DaMyDa myeloma registry"
    ),
    RKKP_LYFO = list(
      numeric = "cartography_rkkp_lyfo_numeric_summary.tsv",
      values = "cartography_rkkp_lyfo_value_counts.tsv",
      known = "",
      group = "Registry",
      subgroup = "LYFO lymphoma registry"
    ),
    RKKP_CLL = list(
      numeric = "cartography_rkkp_cll_numeric_summary.tsv",
      values = "cartography_rkkp_cll_value_counts.tsv",
      known = "",
      group = "Registry",
      subgroup = "CLL registry"
    )
  )
  dict <- list()
  value_maps <- list()
  for (registry in names(registry_files)) {
    spec <- registry_files[[registry]]
    numeric <- read_cartography_table(spec$numeric, project_root)
    values <- read_cartography_table(spec$values, project_root)
    known <- if (nzchar(spec$known)) read_cartography_table(spec$known, project_root) else data.frame(stringsAsFactors = FALSE)
    dict[[length(dict) + 1L]] <- semantic_registry_known_fields(known, registry, spec, min_cell_count)
    dict[[length(dict) + 1L]] <- semantic_registry_column_rows(numeric, values, registry, spec, min_cell_count)
    value_maps[[length(value_maps) + 1L]] <- semantic_registry_value_rows(values, registry, min_cell_count)
  }
  dictionary <- bind_rows_base(dict)
  value_map <- bind_rows_base(value_maps)
  list(
    dictionary = dictionary,
    value_map = value_map,
    code_map = empty_semantic_code_map(),
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
}

semantic_laboratory_sources <- function(project_root, min_cell_count) {
  disease_panels <- read_cartography_table("cartography_npu_disease_panels.tsv", project_root)
  concordance <- read_cartography_table("cartography_biochemistry_concordance.tsv", project_root)
  labka <- read_cartography_table("cartography_labka_top_codes_named.tsv", project_root)
  sp <- read_cartography_table("cartography_sp_alleproevesvar_top_components.tsv", project_root)
  persimune <- read_cartography_table("cartography_persimune_biochem_top_named.tsv", project_root)
  rows <- list(
    semantic_npu_code_rows(disease_panels, "cartography_npu_disease_panels.tsv", min_cell_count),
    semantic_concordance_code_rows(concordance, "cartography_biochemistry_concordance.tsv", min_cell_count),
    semantic_named_code_rows(labka, "analysiscode", "name", "n", "LABKA", "cartography_labka_top_codes_named.tsv", min_cell_count),
    semantic_named_code_rows(sp, "component", "", "n", "SP_AlleProvesvar", "cartography_sp_alleproevesvar_top_components.tsv", min_cell_count),
    semantic_named_code_rows(persimune, "code", "name", "n", "PERSIMUNE_biochemistry", "cartography_persimune_biochem_top_named.tsv", min_cell_count)
  )
  code_map <- semantic_dedupe_code_map(bind_rows_base(rows))
  code_map <- semantic_apply_lab_source_context_code_map(code_map)
  dictionary <- semantic_dictionary_from_code_map(code_map, "Laboratory", "NPU biochemistry", "code_table")
  dictionary <- semantic_apply_lab_source_context_dictionary(dictionary)
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = code_map,
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
}

lab_code_key <- function(value) {
  toupper(gsub("[^A-Za-z0-9]", "", as.character(value %||% "")))
}

lab_name_key <- function(value) {
  tolower(gsub("[^a-z0-9]+", " ", as.character(value %||% "")))
}

lab_concept_definition <- function(code, name) {
  code_key <- lab_code_key(code)
  name_key <- lab_name_key(name)
  exact <- function(values) code_key %in% lab_code_key(values)
  has_word <- function(pattern) grepl(pattern, name_key, perl = TRUE)

  if (exact(c("NPU02319", "REGHAEMOGLOBIN", "REGHAEMOGLOBINMMOLL", "HAEMOGLOBIN", "HEMOGLOBIN", "HB")) ||
      has_word("\\b(haemoglobin|hemoglobin|hb)\\b")) {
    return(list(
      concept_id = "haemoglobin",
      variable = "Haemoglobin",
      subgroup = "Haematology",
      meaning = "Haemoglobin laboratory concept from code dictionary, lab source, or registry field evidence.",
      terms = c("haemoglobin", "hemoglobin", "NPU02319", "HB"),
      caveat = "Haemoglobin units and reference ranges require source-specific harmonization."
    ))
  }

  if (exact(c("NPU02593", "REGCREATININMIKMOLL", "REGCREATININMMOLL", "REGCREATININMILLIMOLL", "CREA")) ||
      has_word("\\bcreatinine\\b|\\bcreatinin\\b")) {
    return(list(
      concept_id = "creatinine",
      variable = "Creatinine",
      subgroup = "Renal function",
      meaning = "Creatinine laboratory concept from code dictionary, lab source, or registry field evidence.",
      terms = c("creatinine", "creatinin", "NPU02593", "CREA"),
      caveat = "Creatinine units and calibration require source-specific harmonization."
    ))
  }

  if (exact(c("DNK35302", "EGFR", "CKDEPI")) || has_word("\\begfr\\b|\\bckd epi\\b|\\bckdepi\\b")) {
    return(list(
      concept_id = "egfr",
      variable = "eGFR / CKD-EPI",
      subgroup = "Renal function",
      meaning = "Estimated glomerular filtration rate / CKD-EPI laboratory concept.",
      terms = c("eGFR", "CKD-EPI", "DNK35302", "renal function"),
      caveat = "eGFR equations and reporting thresholds must be validated by source and calendar period."
    ))
  }

  if (exact(c("NPU02636", "REGLDH", "REGLACTATDEHYDROGENASE", "REGLDHVAERDI", "LDH")) ||
      has_word("\\bldh\\b|lactate dehydrogenase|lactatdehydrogenase")) {
    return(list(
      concept_id = "ldh",
      variable = "LDH",
      subgroup = "Inflammation and biochemistry",
      meaning = "Lactate dehydrogenase laboratory concept.",
      terms = c("LDH", "lactate dehydrogenase", "NPU02636"),
      caveat = "LDH interpretation requires unit and source-specific harmonization."
    ))
  }

  if (exact(c("NPU01349", "REGALBUMINGL", "REGALBUMINGL", "ALB")) ||
      (has_word("\\balbumin\\b") && !has_word("corrected calcium|albumin korrigeret|albuminkorrigeret"))) {
    return(list(
      concept_id = "albumin",
      variable = "Albumin",
      subgroup = "Inflammation and biochemistry",
      meaning = "Albumin laboratory concept.",
      terms = c("albumin", "NPU01349", "ALB"),
      caveat = "Albumin units and serum/plasma context require source-specific harmonization."
    ))
  }

  if (exact(c("REGCALCIUMALBUMINKORRIGERET", "ALBUMINCORRECTEDCALCIUM")) ||
      has_word("albumin corrected calcium|albuminkorrigeret|corrected calcium")) {
    return(list(
      concept_id = "albumin_corrected_calcium",
      variable = "Albumin-corrected calcium",
      subgroup = "Inflammation and biochemistry",
      meaning = "Albumin-corrected calcium registry/laboratory field.",
      terms = c("albumin-corrected calcium", "corrected calcium", "Reg_CalciumAlbuminkorrigeret"),
      caveat = "Albumin-corrected calcium is a calcium marker, not an albumin measurement."
    ))
  }

  if (exact(c("REGCALCIUM", "REGCALCIUMIONISERET", "CALCIUM")) ||
      (has_word("\\bcalcium\\b") && !has_word("albumin corrected|albuminkorrigeret"))) {
    return(list(
      concept_id = if (has_word("ionised|ioniseret") || exact("REGCALCIUMIONISERET")) "ionised_calcium" else "calcium",
      variable = if (has_word("ionised|ioniseret") || exact("REGCALCIUMIONISERET")) "Ionised calcium" else "Calcium",
      subgroup = "Inflammation and biochemistry",
      meaning = "Calcium or ionised calcium laboratory concept.",
      terms = c("calcium", "ionised calcium", "ioniseret calcium"),
      caveat = "Calcium and ionised calcium require unit and specimen-context harmonization."
    ))
  }

  if (exact(c("NPU04998", "REGCREAKTIVTPROTEINGL", "REGCREAKTIVTPROTEINNMOLL", "CRP")) ||
      has_word("\\bcrp\\b|c reactive protein|c reaktivt protein|creaktivtprotein")) {
    return(list(
      concept_id = "crp",
      variable = "CRP",
      subgroup = "Inflammation and biochemistry",
      meaning = "C-reactive protein laboratory concept.",
      terms = c("CRP", "C-reactive protein", "NPU04998"),
      caveat = "CRP must not be conflated with creatinine despite similar raw-field prefixes."
    ))
  }

  if (exact(c("NPU19748", "REGLEUKOCYTTAL", "REGLEUKOCYTTER", "LEUKOCYTES", "LEU")) ||
      has_word("\\bleukocytes?\\b|\\bleucocytes?\\b|leukocytter|leukocyttal")) {
    return(list(
      concept_id = "leukocytes",
      variable = "Leukocytes",
      subgroup = "Haematology",
      meaning = "Leukocyte count laboratory concept.",
      terms = c("leukocytes", "leukocyttal", "NPU19748"),
      caveat = "Leukocyte counts should not be inferred from lymphocyte-doubling fields."
    ))
  }

  if (has_word("neutrophil|neutrofil")) {
    return(list(
      concept_id = "neutrophils",
      variable = "Neutrophils",
      subgroup = "Haematology",
      meaning = "Neutrophil count laboratory concept.",
      terms = c("neutrophils", "neutrofil"),
      caveat = "Neutrophil availability is only mapped when exact code/name evidence exists."
    ))
  }

  if (exact(c("REG_LYMFOCYTFORDOBLIN", "REGLYMFOCYTFORDOBLIN", "BEHLYMFOCYTFORDOBLINGSTID")) ||
      has_word("lymphocyte doubling|lymfocytfordobling")) {
    return(list(
      concept_id = "lymphocyte_doubling_time",
      variable = "Lymphocyte doubling time",
      subgroup = "Haematology",
      meaning = "Lymphocyte doubling/doubling-time field, distinct from lymphocyte count.",
      terms = c("lymphocyte doubling", "lymfocytfordobling"),
      caveat = "Lymphocyte doubling is a kinetics/treatment-indication field, not a lymphocyte count."
    ))
  }

  if (has_word("\\blymphocytes?\\b|lymfocytter")) {
    return(list(
      concept_id = "lymphocytes",
      variable = "Lymphocytes",
      subgroup = "Haematology",
      meaning = "Lymphocyte count laboratory concept.",
      terms = c("lymphocytes", "lymfocytter"),
      caveat = "Lymphocyte count and lymphocyte doubling time must remain distinct."
    ))
  }

  if (has_word("platelet|thrombocyte|thrombocyt|trombocyt")) {
    return(list(
      concept_id = "platelets",
      variable = "Platelets / thrombocytes",
      subgroup = "Haematology",
      meaning = "Platelet/thrombocyte count laboratory concept.",
      terms = c("platelets", "thrombocytes", "Reg_Thrombocytter"),
      caveat = "Platelet counts require source-specific unit harmonization."
    ))
  }

  if (exact(c("REGBETA2MICROGLOBULINGL", "REGBETA2MICROGLOBULINMGL", "REGBETA2MICROGLOBULINNML", "REGBETA2MICROGLOBULIN")) ||
      has_word("beta ?2 microglobulin|beta2microglobulin|b2m")) {
    return(list(
      concept_id = "beta2_microglobulin",
      variable = "Beta-2 microglobulin",
      subgroup = "Inflammation and biochemistry",
      meaning = "Beta-2 microglobulin laboratory/registry marker.",
      terms = c("beta-2 microglobulin", "B2M"),
      caveat = "Beta-2 microglobulin units differ across registry/lab sources."
    ))
  }

  if (has_word("\\bigg\\b|\\biga\\b|\\bigm\\b|immunoglobulin")) {
    return(list(
      concept_id = "immunoglobulin",
      variable = "Immunoglobulins",
      subgroup = "Immunoglobulins and M-protein",
      meaning = "Immunoglobulin quantitation or isotype-related laboratory concept.",
      terms = c("IgG", "IgA", "IgM", "immunoglobulin", "isotype"),
      caveat = "Immunoglobulin quantitation, isotype buckets, and M-protein evidence should remain distinct where source evidence supports it."
    ))
  }

  if (has_word("m protein|m component|m komponent|m spike|mspike|paraprotein|mkomponent|mcomponent")) {
    return(list(
      concept_id = "m_protein",
      variable = "M-protein / M-component",
      subgroup = "Immunoglobulins and M-protein",
      meaning = "M-protein, M-component, or paraprotein laboratory/registry marker.",
      terms = c("M-protein", "M-component", "paraprotein", "M-komponent"),
      caveat = "M-protein and immunoglobulin/isotype evidence require disease- and method-specific interpretation."
    ))
  }

  list(
    concept_id = semantic_id_from(c("lab", code, name)),
    variable = first_nonblank(name, code),
    subgroup = "Candidate laboratory concept",
    meaning = "Candidate laboratory/code row requiring source-specific validation.",
    terms = c(code, name),
    caveat = "Candidate lab concept; validate code label, source, unit, and result-value availability before analytic use."
  )
}

semantic_lab_source_context <- function(source_name = "", object_name = "", code_system = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", sep = " "))
  code_system <- toupper(as.character(code_system %||% ""))
  if (grepl("sp_alleprovesvar|sp_alleproevesvar|alleprovesvar|alleproevesvar", key)) {
    return(list(
      layer = "SP AlleProvesvar / EHR lab results",
      meaning = "EHR-native laboratory result layer.",
      caveat = "SP component names/codes may need harmonization to NPU concepts and units.",
      terms = c("SP AlleProvesvar", "EHR lab results", "component"),
      panel = "SP AlleProvesvar / EHR lab results"
    ))
  }
  if (grepl("persimune", key)) {
    return(list(
      layer = "PERSIMUNE biochemistry",
      meaning = "Research/clinical biochemistry source in PERSIMUNE.",
      caveat = "PERSIMUNE biochemistry coverage may be regional or research-specific rather than nationwide.",
      terms = c("PERSIMUNE", "biochemistry"),
      panel = "PERSIMUNE biochemistry"
    ))
  }
  if (grepl("labka|sdslab|sdslaboratorie|laboratorieproevesvar|sds_lab", key)) {
    return(list(
      layer = "National/LABKA/SDS lab source",
      meaning = "Nationwide or national-register laboratory result/code layer.",
      caveat = "NPU code coverage does not automatically mean harmonized result-value availability.",
      terms = c("LABKA", "SDS_lab_forsker", "SDS_laboratorieproevesvar"),
      panel = "National/LABKA/SDS lab source"
    ))
  }
  if (grepl("rkkp|damyda|lyfo|cll", key)) {
    return(list(
      layer = "Registry lab fields",
      meaning = "Disease-registry baseline or registry-specific laboratory field.",
      caveat = "Registry lab fields are not full longitudinal laboratory result streams.",
      terms = c("registry lab field", "RKKP"),
      panel = "Registry lab fields"
    ))
  }
  if (code_system %in% c("NPU", "DNK")) {
    return(list(
      layer = "NPU/DNK code dictionary",
      meaning = "NPU/DNK code dictionary or analyte mapping layer.",
      caveat = "Code labels and source-specific units must be validated before harmonized analyses.",
      terms = c("NPU", "DNK", "code dictionary"),
      panel = "NPU/DNK code dictionary"
    ))
  }
  list(
    layer = "Candidate laboratory evidence",
    meaning = "Candidate laboratory evidence row.",
    caveat = "Candidate lab rows require source-specific validation before use.",
    terms = c("candidate lab"),
    panel = "Candidate laboratory evidence"
  )
}

semantic_apply_lab_source_context_code_map <- function(code_map) {
  if (!is.data.frame(code_map) || !nrow(code_map)) return(code_map)
  for (i in seq_len(nrow(code_map))) {
    if (!identical(code_map$clinical_group[[i]] %||% "", "Laboratory")) next
    def <- lab_concept_definition(code_map$code[[i]], code_map$code_name[[i]])
    ctx <- semantic_lab_source_context(code_map$source_name[[i]], code_map$object_name[[i]], code_map$code_system[[i]])
    code_map$clinical_concept_id[[i]] <- def$concept_id
    code_map$clinical_variable[[i]] <- def$variable
    code_map$panel[[i]] <- paste(ctx$panel, def$subgroup, sep = " - ")
    code_map$notes[[i]] <- semantic_append_text(code_map$notes[[i]], paste(ctx$meaning, def$caveat, ctx$caveat))
  }
  code_map
}

semantic_apply_lab_source_context_dictionary <- function(dictionary) {
  if (!is.data.frame(dictionary) || !nrow(dictionary)) return(dictionary)
  for (i in seq_len(nrow(dictionary))) {
    if (!identical(dictionary$clinical_group[[i]] %||% "", "Laboratory")) next
    def <- lab_concept_definition(dictionary$raw_code[[i]], first_nonblank(dictionary$clinical_variable[[i]], dictionary$raw_descriptor[[i]]))
    ctx <- semantic_lab_source_context(dictionary$source_name[[i]], dictionary$object_name[[i]], dictionary$code_system[[i]])
    dictionary$clinical_concept_id[[i]] <- def$concept_id
    dictionary$clinical_variable[[i]] <- def$variable
    dictionary$clinical_subgroup[[i]] <- def$subgroup
    dictionary$semantic_meaning[[i]] <- semantic_append_text(ctx$meaning, def$meaning)
    dictionary$clinical_caveat[[i]] <- semantic_append_text(dictionary$clinical_caveat[[i]], paste(ctx$caveat, def$caveat))
    dictionary$search_terms[[i]] <- semantic_terms(c(dictionary$search_terms[[i]], ctx$terms, def$terms, ctx$layer, def$subgroup))
  }
  dictionary
}

semantic_treatment_sources <- function(project_root, min_cell_count) {
  rows <- list(
    semantic_treatment_matrix_rows(read_cartography_table("cartography_disease_treatment_matrix.tsv", project_root), min_cell_count),
    semantic_sks_rows(read_cartography_table("cartography_sks_treatment_codes.tsv", project_root), min_cell_count),
    semantic_sks_top_rows(read_cartography_table("cartography_sks_antineoplastic_top50.tsv", project_root), min_cell_count),
    semantic_atc_rows(read_cartography_table("cartography_atc_antineoplastic_codes.tsv", project_root), min_cell_count),
    semantic_named_code_rows(read_cartography_table("cartography_sp_rx_med_atc_top_named.tsv", project_root), "code", "name", "n", "SP_OrdineretMedicin", "cartography_sp_rx_med_atc_top_named.tsv", min_cell_count, clinical_group = "Treatment"),
    semantic_named_code_rows(read_cartography_table("cartography_smr_atc_top_named.tsv", project_root), "atc", "name", "n", "SMR_medicine", "cartography_smr_atc_top_named.tsv", min_cell_count, clinical_group = "Treatment")
  )
  code_map <- semantic_dedupe_code_map(bind_rows_base(rows))
  code_map <- semantic_reclassify_supporting_lab_codes(code_map)
  code_map <- semantic_apply_lab_source_context_code_map(code_map)
  code_map <- semantic_apply_treatment_source_context_code_map(code_map)
  dictionary <- semantic_dictionary_from_code_map(code_map, "Treatment", "Medication and procedure codes", "code_table")
  dictionary <- semantic_apply_lab_source_context_dictionary(dictionary)
  dictionary <- semantic_apply_treatment_source_context_dictionary(dictionary)
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = code_map,
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
}

semantic_npu_dnk_code_system <- function(code_system = "", code = "") {
  code_system <- toupper(trimws(as.character(code_system %||% "")))
  code <- toupper(trimws(as.character(code %||% "")))
  if (code_system %in% c("NPU", "DNK")) return(code_system)
  if (grepl("^NPU[0-9]", code)) return("NPU")
  if (grepl("^DNK[0-9]", code)) return("DNK")
  ""
}

semantic_lab_like_code_context <- function(source_name = "", object_name = "", evidence_file = "", panel = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", evidence_file %||% "", panel %||% "", sep = " "))
  grepl(
    "sds_lab|sdslab|laboratorie|laboratory|labka|sp_alleprovesvar|sp_alleproevesvar|alleprovesvar|alleproevesvar|persimune_biochemistry|biochemistry|haematology|hematology|immunoglobulin|npu_dictionary|npu_disease|npu_lab",
    key
  )
}

semantic_known_lab_concept <- function(code = "", name = "") {
  def <- lab_concept_definition(code, name)
  !grepl("^lab_", def$concept_id)
}

semantic_reclassify_supporting_lab_codes <- function(code_map) {
  if (!is.data.frame(code_map) || !nrow(code_map)) return(code_map)
  supporting_note <- "Surfaced by treatment-matrix scan as supporting laboratory evidence; not treatment exposure."
  for (i in seq_len(nrow(code_map))) {
    lab_system <- semantic_npu_dnk_code_system(code_map$code_system[[i]], code_map$code[[i]])
    if (!nzchar(lab_system)) next
    if (!(
      semantic_lab_like_code_context(code_map$source_name[[i]], code_map$object_name[[i]], code_map$evidence_file[[i]], code_map$panel[[i]]) ||
        semantic_known_lab_concept(code_map$code[[i]], code_map$code_name[[i]])
    )) next

    def <- lab_concept_definition(code_map$code[[i]], code_map$code_name[[i]])
    ctx <- semantic_lab_source_context(code_map$source_name[[i]], code_map$object_name[[i]], lab_system)
    code_map$semantic_id[[i]] <- semantic_id_from(c("supporting_lab", code_map$source_name[[i]], code_map$code[[i]], code_map$code_name[[i]]))
    code_map$clinical_concept_id[[i]] <- def$concept_id
    code_map$clinical_variable[[i]] <- def$variable
    code_map$clinical_group[[i]] <- "Laboratory"
    code_map$code_system[[i]] <- lab_system
    code_map$panel[[i]] <- paste(ctx$panel, def$subgroup, sep = " - ")
    code_map$notes[[i]] <- semantic_append_text(code_map$notes[[i]], paste(ctx$meaning, def$caveat, ctx$caveat))
    if (grepl("cartography_disease_treatment_matrix", code_map$evidence_file[[i]] %||% "", fixed = TRUE)) {
      code_map$notes[[i]] <- semantic_append_text(code_map$notes[[i]], supporting_note)
    }
  }
  code_map
}

semantic_treatment_source_context <- function(source_name = "", object_name = "", code_system = "",
                                              code = "", raw_column = "", clinical_variable = "",
                                              evidence_file = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", evidence_file %||% "", sep = " "))
  code_key <- toupper(as.character(code %||% ""))
  code_system <- toupper(as.character(code_system %||% ""))
  atc_note <- if (identical(code_system, "ATC")) {
    "ATC medication-code context is preserved; this row is not an SKS procedure."
  } else ""
  sks_note <- if (identical(code_system, "SKS")) {
    "SKS procedure-code context is preserved; this row is not an administered medication or prescription."
  } else ""
  mk <- function(id, label, subgroup, variable, meaning, caveat, terms, panel = label) {
    suffix <- paste(c(atc_note, sks_note), collapse = " ")
    caveat <- semantic_append_text(caveat, suffix)
    list(id = id, label = label, subgroup = subgroup, variable = variable, meaning = meaning, caveat = caveat, terms = terms, panel = panel)
  }
  if (grepl("rkkp_damyda", key)) {
    return(mk(
      "registry_treatment",
      "Registry treatment fields",
      "Myeloma registry treatment fields",
      "Myeloma registry treatment field",
      "DaMyDa registry treatment, response, relapse, or follow-up field; registry context must be preserved.",
      "DaMyDa treatment fields are registry-coded signals, not a complete medication administration record.",
      c("registry treatment", "DaMyDa", "myeloma registry treatment")
    ))
  }
  if (grepl("rkkp_lyfo", key)) {
    return(mk(
      "registry_treatment",
      "Registry treatment fields",
      "Lymphoma registry treatment fields",
      "Lymphoma registry treatment/regimen field",
      "LYFO registry treatment, regimen, response, relapse, or follow-up field; registry context must be preserved.",
      "LYFO treatment fields are registry-coded signals, not a complete medication administration record.",
      c("registry treatment", "LYFO", "lymphoma registry treatment", "regimen")
    ))
  }
  if (grepl("rkkp_cll", key)) {
    return(mk(
      "registry_treatment",
      "Registry treatment fields",
      "CLL registry treatment fields",
      "CLL registry treatment/targeted therapy field",
      "CLL registry treatment, targeted therapy, response, MRD, or follow-up field; registry context must be preserved.",
      "CLL treatment fields are registry-coded signals, not a complete medication administration record.",
      c("registry treatment", "CLL", "targeted therapy", "DCLLR")
    ))
  }
  if (grepl("sp_behandlingsplaner", key)) {
    return(mk(
      "sp_treatment_plan",
      "SP treatment plans",
      "SP treatment plans and protocols",
      "SP treatment plan/protocol field",
      "Sundhedsplatformen treatment-plan or protocol field; planning context must be preserved.",
      "SP treatment-plan rows describe planned treatment/protocol metadata and do not by themselves prove medication administration.",
      c("SP treatment plan", "protocol", "cycle", "planned treatment")
    ))
  }
  if (grepl("sp_administreretmedicin", key)) {
    return(mk(
      "sp_administered_medication",
      "SP administered medication",
      "SP administered medication",
      "SP administered medication field",
      "Sundhedsplatformen medication-administration field; administration context must be preserved.",
      "SP administered-medication rows are EHR administration evidence and should not be labeled as prescription-only records.",
      c("SP administered medication", "EHR medication administration", "administration time", "administration route")
    ))
  }
  if (grepl("sp_ordineretmedicin", key)) {
    return(mk(
      "sp_ordered_medication",
      "SP ordered medication",
      "SP ordered medication",
      "SP ordered medication field",
      "Sundhedsplatformen ordered-medication field; order context must be preserved.",
      "SP ordered-medication rows are EHR medication orders and do not by themselves prove administration.",
      c("SP ordered medication", "EHR medication order", "prescription-like EHR medication")
    ))
  }
  if (grepl("sds_epikur|sds_ekokur", key)) {
    return(mk(
      "national_prescription",
      "National prescription data",
      "National prescription metadata",
      "National prescription / outpatient prescription signal",
      "SDS Epikur/Ekokur prescription or outpatient prescription metadata; prescription context must be preserved.",
      "Epikur/Ekokur rows are prescription or outpatient prescription signals and should not be labeled as inpatient administration.",
      c("national prescription", "outpatient prescription", "ATC prescription signal", "Epikur", "Ekokur")
    ))
  }
  if (grepl("sds_indberetningmedpris|smr_medicine|smr", key)) {
    return(mk(
      "smr_in_hospital_medication",
      "SMR / in-hospital medication",
      "National in-hospital medication register",
      "SMR / national in-hospital medication signal",
      "National in-hospital medication-register field; SMR context must be preserved.",
      "SMR / SDS_indberetningmedpris rows are national in-hospital medication-register signals, not SP administered-medication rows.",
      c("SMR", "in-hospital medication", "SDS_indberetningmedpris", "medicine register")
    ))
  }
  if (grepl("sds_t_sks|sksopr|sksube|sds_procedurer|sds_sks", key) || identical(code_system, "SKS")) {
    return(mk(
      "sks_procedure",
      "SKS procedure/treatment signals",
      "SKS treatment/procedure signals",
      "SKS treatment/procedure signal",
      "SKS procedure or treatment-code signal; procedure-code context must be preserved.",
      "SKS rows are procedure/treatment code signals and should not be labeled as ATC drug exposure, prescriptions, or administered medication.",
      c("SKS", "procedure", "treatment procedure", "radiotherapy", "transplant")
    ))
  }
  if (identical(code_system, "ATC") || grepl("^[A-Z][0-9]{2}", code_key)) {
    atc_subgroup <- if (grepl("^L01", code_key)) {
      "ATC antineoplastic medication signals"
    } else if (grepl("^L04", code_key)) {
      "ATC immunomodulating/immunosuppressive medication signals"
    } else {
      "ATC medication signals"
    }
    return(mk(
      "atc_medication",
      "ATC medication signals",
      atc_subgroup,
      first_nonblank(clinical_variable, "ATC medication signal"),
      "ATC medication-code signal; ATC code context must be preserved.",
      "ATC rows are medication-code signals and should not be labeled as SKS procedures, confirmed delivered therapy, or registry treatment without source-specific evidence.",
      c("ATC", "medication code", "drug signal", "L01", "L04")
    ))
  }
  mk(
    "candidate_treatment",
    "Candidate / needs-validation treatment rows",
    "Candidate treatment rows",
    first_nonblank(clinical_variable, "Candidate treatment row"),
    "Treatment-related row that needs source-specific validation before primary exposure use.",
    "Candidate treatment rows should be validated against source documentation before use as treatment exposure evidence.",
    c("candidate treatment", "needs validation")
  )
}

semantic_treatment_registry_related <- function(row) {
  if (!is.data.frame(row) || !nrow(row)) return(FALSE)
  source <- row$source_name[[1]] %||% ""
  if (!grepl("RKKP_", source, ignore.case = TRUE)) return(FALSE)
  hay <- paste(
    row$clinical_concept_id[[1]] %||% "",
    row$clinical_variable[[1]] %||% "",
    row$raw_column[[1]] %||% "",
    row$semantic_meaning[[1]] %||% "",
    row$search_terms[[1]] %||% ""
  )
  grepl("treatment|therapy|regimen|behandling|behandl|kemo|immun|target|targeteret|transplant|response|mrd|relaps|progress", hay, ignore.case = TRUE)
}

semantic_treatment_context_relevant <- function(row) {
  if (!is.data.frame(row) || !nrow(row)) return(FALSE)
  group <- row$clinical_group[[1]] %||% ""
  if (identical(group, "Treatment")) return(TRUE)
  semantic_treatment_registry_related(row)
}

semantic_append_text <- function(base, addition) {
  base <- as.character(base %||% "")
  addition <- trimws(as.character(addition %||% ""))
  if (!nzchar(addition)) return(base)
  if (!nzchar(base)) return(addition)
  if (grepl(addition, base, fixed = TRUE)) return(base)
  paste(base, addition)
}

semantic_apply_treatment_source_context_dictionary <- function(dictionary) {
  if (!is.data.frame(dictionary) || !nrow(dictionary)) return(dictionary)
  for (i in seq_len(nrow(dictionary))) {
    row <- dictionary[i, , drop = FALSE]
    if (!semantic_treatment_context_relevant(row)) next
    ctx <- semantic_treatment_source_context(
      source_name = row$source_name[[1]],
      object_name = row$object_name[[1]],
      code_system = row$code_system[[1]],
      code = row$raw_code[[1]],
      raw_column = row$raw_column[[1]],
      clinical_variable = row$clinical_variable[[1]],
      evidence_file = row$evidence_file[[1]]
    )
    if (identical(dictionary$clinical_variable[[i]], "Treatment signal")) {
      dictionary$clinical_variable[[i]] <- ctx$variable
    }
    dictionary$clinical_subgroup[[i]] <- ctx$subgroup
    dictionary$semantic_meaning[[i]] <- semantic_append_text(dictionary$semantic_meaning[[i]], ctx$meaning)
    dictionary$clinical_caveat[[i]] <- semantic_append_text(dictionary$clinical_caveat[[i]], ctx$caveat)
    dictionary$search_terms[[i]] <- semantic_terms(c(dictionary$search_terms[[i]], ctx$terms, ctx$label, ctx$subgroup))
  }
  dictionary
}

semantic_apply_treatment_source_context_code_map <- function(code_map) {
  if (!is.data.frame(code_map) || !nrow(code_map)) return(code_map)
  for (i in seq_len(nrow(code_map))) {
    if (!identical(code_map$clinical_group[[i]] %||% "", "Treatment")) next
    ctx <- semantic_treatment_source_context(
      source_name = code_map$source_name[[i]],
      object_name = code_map$object_name[[i]],
      code_system = code_map$code_system[[i]],
      code = code_map$code[[i]],
      clinical_variable = code_map$clinical_variable[[i]],
      evidence_file = code_map$evidence_file[[i]]
    )
    code_map$panel[[i]] <- ctx$panel
    code_map$notes[[i]] <- semantic_append_text(code_map$notes[[i]], ctx$caveat)
  }
  code_map
}

semantic_domain_sources <- function(project_root, min_cell_count) {
  imaging <- semantic_value_count_code_rows(
    project_root,
    c(
      "cartography_part6_sp_billeddiagnostik_del1_value_counts.tsv",
      "cartography_sds_t_sksube_value_counts.tsv",
      "cartography_part4_sds_procedure_andre_value_counts.tsv",
      "cartography_part4_sds_procedure_kirurgi_value_counts.tsv"
    ),
    "Imaging",
    "Imaging and radiotherapy signals",
    c("PET", "PET-CT", "FDG", "CT", "MR", "MRI", "UX", "BWGC", "radiotherapy", "X-ray"),
    min_cell_count
  )
  microbiology <- semantic_value_count_code_rows(
    project_root,
    c(
      "cartography_persimune_microbiology_analysis_value_counts.tsv",
      "cartography_persimune_microbiology_culture_value_counts.tsv",
      "cartography_persimune_microbiology_culture_resistance_value_counts.tsv",
      "cartography_persimune_microbiology_microscopy_value_counts.tsv",
      "cartography_sp_bloddyrkning_del1_value_counts.tsv",
      "cartography_sp_bloddyrkning_del2_value_counts.tsv",
      "cartography_sp_bloddyrkning_del3_value_counts.tsv",
      "cartography_sp_bloddyrkning_del4_value_counts.tsv"
    ),
    "Microbiology",
    "Culture, microscopy, resistance, and blood-culture workflow",
    c("blood culture", "bloddyrkning", "culture", "resistance", "susceptibility", "organism", "sample material", "antibiotic"),
    min_cell_count
  )
  pathology <- semantic_value_count_code_rows(
    project_root,
    c(
      "cartography_pato_top_snomed.tsv",
      "cartography_sds_pato_value_counts.tsv",
      "cartography_part4_sds_t_mikro_value_counts.tsv",
      "cartography_part4_sds_t_konk_value_counts.tsv",
      "cartography_sds_t_tumor_value_counts.tsv",
      "cartography_tumor_value_counts.tsv"
    ),
    "Pathology",
    "SNOMED pathology and specimen signals",
    c("SNOMED", "pathology", "PATOBANK", "pato", "specimen", "biopsy", "morphology", "microscopy", "conclusion", "tumor"),
    min_cell_count
  )
  biobank <- semantic_value_count_code_rows(
    project_root,
    c("cartography_lab_biobank_samples_value_counts.tsv"),
    "Biobank",
    "Biobank sample availability",
    c("biobank", "sample", "plasma", "DNA", "tissue", "bone marrow"),
    min_cell_count
  )
  outcomes <- semantic_value_count_code_rows(
    project_root,
    c("cartography_sds_t_dodsaarsag_2_value_counts.tsv", "cartography_part6_sds_t_dodsaarsag_2_value_counts.tsv"),
    "Outcomes",
    "Death and cause-of-death coding",
    c("death", "cause of death", "dod", "mortality", "outcomes"),
    min_cell_count
  )
  dictionary <- bind_rows_base(list(imaging$dictionary, microbiology$dictionary, pathology$dictionary, biobank$dictionary, outcomes$dictionary))
  code_map <- bind_rows_base(list(imaging$code_map, microbiology$code_map, pathology$code_map, biobank$code_map, outcomes$code_map))
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = code_map,
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
}

semantic_candidate_discovery <- function(project_root, min_cell_count) {
  hits <- read_cartography_table("cartography_column_name_hits.tsv", project_root)
  if (!nrow(hits) || !all(c("source_name", "concept", "matched_column") %in% names(hits))) {
    return(empty_semantic_outputs())
  }
  rows <- lapply(seq_len(nrow(hits)), function(i) {
    column <- hits$matched_column[[i]]
    if (is_sensitive_column(column)) return(NULL)
    source_name <- hits$source_name[[i]]
    if (pathology_sds_pato_snomed_field(source_name, column)) {
      def <- list(
        concept_id = "pathology_snomed_code",
        variable = "SNOMED pathology code",
        group = "Pathology",
        subgroup = "SNOMED-coded pathology",
        value_type = "code",
        code_system = "SNOMED",
        terms = c("SDS_pato", "PATOBANK", "SNOMED", "c_snomedkode", "pathology"),
        confidence = "high",
        status = "confirmed",
        caveat = "SDS_pato.c_snomedkode is a SNOMED pathology code field; do not interpret it as SKS treatment/procedure evidence.",
        meaning = "Exact SDS/PATOBANK SNOMED pathology code field."
      )
    } else if (grepl("CLL", source_name, ignore.case = TRUE) && !grepl("LAB", source_name, ignore.case = TRUE)) {
      cll_def <- registry_column_definition(column, "RKKP_CLL")
      def <- list(
        concept_id = cll_def$concept_id,
        variable = cll_def$variable,
        group = "Registry",
        subgroup = cll_def$subgroup,
        value_type = cll_def$value_type,
        code_system = "RKKP_field",
        terms = cll_def$terms,
        confidence = cll_def$confidence,
        status = cll_def$status,
        caveat = cll_def$caveat,
        meaning = cll_def$meaning
      )
    } else {
      def <- semantic_concept_definition(hits$concept[[i]], column, source_name)
      def$confidence <- "medium"
      def$status <- "inferred"
      def$caveat <- hits$notes[[i]] %||% "Column-name hit needs clinical validation before analytic use."
      def$meaning <- paste("Column-name cartography hit for", def$variable, "in", source_name)
    }
    semantic_row(
      semantic_id = semantic_id_from(c(source_name, column, hits$concept[[i]])),
      clinical_concept_id = def$concept_id,
      clinical_variable = def$variable,
      clinical_group = def$group,
      clinical_subgroup = def$subgroup,
      semantic_meaning = def$meaning,
      source_name = source_name,
      object_name = hits$object_name[[i]] %||% source_name,
      raw_column = column,
      code_system = def$code_system,
      value_type = def$value_type,
      data_shape = "wide_table",
      source_level = source_level_for_source(source_name),
      geography = geography_for_source(source_name),
      evidence_file = "cartography_column_name_hits.tsv",
      evidence_filter = paste0("concept=", hits$concept[[i]], "; matched_column=", column),
      mapping_confidence = def$confidence,
      mapping_status = def$status,
      privacy_note = "aggregate_only",
      clinical_caveat = def$caveat,
      search_terms = semantic_terms(c(hits$concept[[i]], column, source_name, def$terms))
    )
  })
  dictionary <- bind_rows_base(rows)
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = empty_semantic_code_map(),
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
}

semantic_row <- function(...) {
  values <- list(...)
  cols <- semantic_dictionary_columns()
  out <- as.list(stats::setNames(rep(NA_character_, length(cols)), cols))
  for (nm in names(values)) out[[nm]] <- values[[nm]]
  data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

semantic_value_row <- function(...) {
  values <- list(...)
  cols <- semantic_value_map_columns()
  out <- as.list(stats::setNames(rep(NA_character_, length(cols)), cols))
  for (nm in names(values)) out[[nm]] <- values[[nm]]
  data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

semantic_code_row <- function(...) {
  values <- list(...)
  cols <- semantic_code_map_columns()
  out <- as.list(stats::setNames(rep(NA_character_, length(cols)), cols))
  for (nm in names(values)) out[[nm]] <- values[[nm]]
  data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

semantic_panel_link_row <- function(...) {
  values <- list(...)
  cols <- semantic_panel_links_columns()
  out <- as.list(stats::setNames(rep(NA_character_, length(cols)), cols))
  for (nm in names(values)) out[[nm]] <- values[[nm]]
  data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

align_semantic_frame <- function(x, cols) {
  if (!is.data.frame(x) || !nrow(x)) {
    return(data.frame(matrix(ncol = length(cols), nrow = 0, dimnames = list(NULL, cols)), stringsAsFactors = FALSE))
  }
  missing <- setdiff(cols, names(x))
  for (nm in missing) x[[nm]] <- NA
  x <- x[cols]
  rownames(x) <- NULL
  x
}

semantic_id_from <- function(parts) {
  x <- paste(parts[!is.na(parts) & nzchar(as.character(parts))], collapse = "_")
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  if (!nzchar(x)) "semantic_row" else x
}

semantic_terms <- function(x) {
  x <- trimws(as.character(unlist(x, use.names = FALSE)))
  x <- unique(x[!is.na(x) & nzchar(x)])
  paste(x, collapse = "; ")
}

first_nonblank <- function(x, default = "") {
  if (is.null(x) || !length(x)) return(default)
  x <- trimws(as.character(x))
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x)) x[[1]] else default
}

semantic_vector_value <- function(x, i, default = "") {
  if (is.null(x) || !length(x) || i > length(x)) return(default)
  value <- x[[i]]
  if (length(value) == 0 || is.na(value) || !nzchar(as.character(value))) default else as.character(value)
}

semantic_suppress_count <- function(n, min_cell_count = atlas_min_cell_count()) {
  n <- suppressWarnings(as.numeric(n))
  if (!length(n) || is.na(n[[1]]) || n[[1]] < min_cell_count) return(NA_real_)
  n[[1]]
}

semantic_column_total <- function(frequencies, column, min_cell_count) {
  if (!is.data.frame(frequencies) || !nrow(frequencies) || !"column" %in% names(frequencies) || !"n" %in% names(frequencies)) {
    return(NA_real_)
  }
  rows <- frequencies[frequencies$column == column, , drop = FALSE]
  semantic_suppress_count(sum(suppressWarnings(as.numeric(rows$n)), na.rm = TRUE), min_cell_count)
}

semantic_value_rows_for_column <- function(frequencies, source_name, column, semantic_id,
                                           concept_id, variable, value_defs,
                                           denominator_label, min_cell_count) {
  rows <- frequencies[frequencies$column == column, , drop = FALSE]
  if (!nrow(rows)) return(empty_semantic_value_map())
  total <- sum(suppressWarnings(as.numeric(rows$n)), na.rm = TRUE)
  out <- lapply(seq_len(nrow(rows)), function(i) {
    raw <- rows$value[[i]]
    def <- value_defs[value_defs$raw_value == raw, , drop = FALSE]
    n <- suppressWarnings(as.numeric(rows$n[[i]]))
    suppressed <- is.na(n) || n < min_cell_count
    semantic_value_row(
      semantic_id = semantic_id,
      clinical_concept_id = concept_id,
      clinical_variable = variable,
      source_name = source_name,
      object_name = rows$object_name[[i]] %||% source_name,
      raw_column = column,
      raw_value = raw,
      display_value = if (nrow(def)) def$display_value[[1]] else raw,
      value_class = if (nrow(def)) def$value_class[[1]] else "observed_response",
      clinical_interpretation = if (nrow(def)) def$clinical_interpretation[[1]] else "Observed response; clinical interpretation not curated yet.",
      n = if (suppressed) NA_real_ else n,
      pct = if (!suppressed && total > 0) round(n / total * 100, 3) else NA_real_,
      denominator_label = denominator_label,
      evidence_file = "cartography_sp_social_hx_value_frequencies.tsv",
      mapping_confidence = if (nrow(def)) "high" else "medium",
      suppressed = suppressed,
      notes = if (suppressed) paste("Suppressed below minimum cell count", min_cell_count) else "Aggregate value count from cartography."
    )
  })
  bind_rows_base(out)
}

vital_descriptor_definition <- function(descriptor) {
  key <- semantic_id_from(descriptor)
  known <- list(
    vaegt = list("weight", "Weight", "Anthropometrics", "Body weight observation.", "high", "confirmed", c("weight", "body weight", "kg", "vaegt")),
    vagt = list("weight", "Weight", "Anthropometrics", "Body weight observation.", "high", "confirmed", c("weight", "body weight", "kg", "vaegt")),
    hojde = list("height", "Height", "Anthropometrics", "Body height observation.", "high", "confirmed", c("height", "cm", "hojde")),
    puls = list("pulse", "Pulse", "Physiology", "Pulse or heart-rate observation.", "high", "confirmed", c("pulse", "heart rate", "puls")),
    spo2 = list("oxygen_saturation", "Oxygen saturation", "Physiology", "Peripheral oxygen saturation observation.", "high", "confirmed", c("SpO2", "oxygen saturation", "saturation")),
    saturation = list("oxygen_saturation", "Oxygen saturation", "Physiology", "Peripheral oxygen saturation observation.", "high", "confirmed", c("SpO2", "oxygen saturation", "saturation")),
    resp = list("respiratory_rate", "Respiratory rate", "Physiology", "Respiratory-rate observation.", "high", "confirmed", c("respiratory rate", "respiration", "resp")),
    resp_frekvens = list("respiratory_rate", "Respiratory rate", "Physiology", "Respiratory-rate observation.", "high", "confirmed", c("respiratory rate", "respiration", "resp")),
    bt_diastolisk = list("blood_pressure_diastolic", "Diastolic blood pressure", "Physiology", "Diastolic blood-pressure observation.", "high", "confirmed", c("blood pressure", "diastolic", "BT")),
    bt_systolisk = list("blood_pressure_systolic", "Systolic blood pressure", "Physiology", "Systolic blood-pressure observation.", "high", "confirmed", c("blood pressure", "systolic", "BT")),
    temp = list("temperature", "Temperature", "Physiology", "Body-temperature observation.", "high", "confirmed", c("temperature", "temp", "fever")),
    ilt_l_min = list("oxygen_flow", "Oxygen flow", "Respiratory support", "Oxygen flow rate observation.", "medium", "inferred", c("oxygen", "oxygen flow", "ilt")),
    ews_total = list("early_warning_score", "EWS total", "Deterioration", "Early Warning Score total.", "medium", "inferred", c("EWS", "early warning score", "deterioration"))
  )
  hit <- known[[key]]
  if (is.null(hit)) {
    return(list(
      concept_id = semantic_id_from(c("vital", descriptor)),
      variable = descriptor,
      subgroup = "Observation descriptor",
      meaning = paste("SP vital-sign descriptor:", descriptor),
      confidence = "medium",
      status = "candidate",
      terms = c(descriptor, "vitals", "observation")
    ))
  }
  list(
    concept_id = hit[[1]],
    variable = hit[[2]],
    subgroup = hit[[3]],
    meaning = hit[[4]],
    confidence = hit[[5]],
    status = hit[[6]],
    terms = hit[[7]]
  )
}

semantic_vital_summary_row <- function(domain_summary, descriptor) {
  if (!is.data.frame(domain_summary) || !nrow(domain_summary) || !"domain" %in% names(domain_summary)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  key <- semantic_id_from(descriptor)
  target <- if (key == "vaegt") "weight" else if (key == "hojde") "height" else key
  rows <- domain_summary[semantic_id_from(domain_summary$domain) == target, , drop = FALSE]
  if (nrow(rows)) rows[1, , drop = FALSE] else data.frame(stringsAsFactors = FALSE)
}

semantic_vital_caveat <- function(def, summary_row) {
  base <- "Repeated measures; define baseline windows relative to diagnosis and apply outlier filters before analysis."
  if (is.data.frame(summary_row) && nrow(summary_row)) {
    stats <- paste(
      paste0("median=", first_nonblank(summary_row$median_numeric, "")),
      paste0("p05=", first_nonblank(summary_row$p05_numeric, "")),
      paste0("p95=", first_nonblank(summary_row$p95_numeric, "")),
      sep = "; "
    )
    return(paste(base, stats))
  }
  base
}

semantic_registry_known_fields <- function(known, registry, spec, min_cell_count) {
  if (!is.data.frame(known) || !nrow(known) || !"expected_field" %in% names(known)) {
    return(empty_semantic_data_dictionary())
  }
  rows <- lapply(seq_len(nrow(known)), function(i) {
    field <- known$actual_column[[i]] %||% known$expected_field[[i]]
    if (!nzchar(field)) field <- known$expected_field[[i]]
    def <- registry_column_definition(field, registry)
    present <- tolower(as.character(known$present[[i]] %||% "")) %in% c("true", "1", "yes", "present")
    semantic_row(
      semantic_id = semantic_id_from(c(registry, field, def$concept_id)),
      clinical_concept_id = def$concept_id,
      clinical_variable = def$variable,
      clinical_group = "Registry",
      clinical_subgroup = spec$subgroup,
      semantic_meaning = first_nonblank(known$description[[i]], def$meaning),
      source_name = registry,
      object_name = registry,
      raw_column = field,
      code_system = "RKKP_field",
      value_type = def$value_type,
      data_shape = "wide_table",
      source_level = "RKKP registry",
      geography = "nationwide",
      evidence_file = "cartography_damyda_known_field_map.tsv",
      evidence_filter = paste0("expected_field=", known$expected_field[[i]]),
      mapping_confidence = if (present) "high" else "low",
      mapping_status = if (present) "confirmed" else "not_present",
      privacy_note = "aggregate_only",
      clinical_caveat = if (present) def$caveat else "Expected registry field was not found in cartography evidence.",
      search_terms = semantic_terms(c(field, known$expected_field[[i]], def$terms, registry))
    )
  })
  bind_rows_base(rows)
}

semantic_registry_column_rows <- function(numeric, values, registry, spec, min_cell_count) {
  cols <- unique(c(numeric$column %||% character(), values$column_name %||% values$column %||% character()))
  cols <- cols[!is.na(cols) & nzchar(cols) & !vapply(cols, is_sensitive_column, logical(1))]
  if (!length(cols)) return(empty_semantic_data_dictionary())
  rows <- lapply(cols, function(column) {
    def <- registry_column_definition(column, registry)
    num <- numeric[numeric$column == column, , drop = FALSE]
    val <- values[(values$column_name %||% values$column) == column, , drop = FALSE]
    n_rows <- if (nrow(num) && "n_numeric" %in% names(num)) num$n_numeric[[1]] else if (nrow(val) && "n_rows" %in% names(val)) sum(suppressWarnings(as.numeric(val$n_rows)), na.rm = TRUE) else if (nrow(val) && "n" %in% names(val)) sum(suppressWarnings(as.numeric(val$n)), na.rm = TRUE) else NA_real_
    semantic_row(
      semantic_id = semantic_id_from(c(registry, column, def$concept_id)),
      clinical_concept_id = def$concept_id,
      clinical_variable = def$variable,
      clinical_group = "Registry",
      clinical_subgroup = spec$subgroup,
      semantic_meaning = def$meaning,
      source_name = registry,
      object_name = registry,
      raw_column = column,
      code_system = "RKKP_field",
      value_type = def$value_type,
      data_shape = "wide_table",
      source_level = "RKKP registry",
      geography = "nationwide",
      n_rows = semantic_suppress_count(n_rows, min_cell_count),
      evidence_file = paste(c(spec$numeric, spec$values), collapse = "; "),
      evidence_filter = paste0("column=", column),
      mapping_confidence = def$confidence,
      mapping_status = def$status,
      privacy_note = "aggregate_only",
      clinical_caveat = def$caveat,
      search_terms = semantic_terms(c(column, def$terms, registry))
    )
  })
  bind_rows_base(rows)
}

semantic_registry_value_rows <- function(values, registry, min_cell_count) {
  if (!is.data.frame(values) || !nrow(values)) return(empty_semantic_value_map())
  col_name <- if ("column_name" %in% names(values)) "column_name" else "column"
  count_name <- if ("n_rows" %in% names(values)) "n_rows" else "n"
  if (!all(c(col_name, "value", count_name) %in% names(values))) return(empty_semantic_value_map())
  values <- values[!vapply(values[[col_name]], is_sensitive_column, logical(1)), , drop = FALSE]
  values <- head(values, 500)
  by_col <- split(values, values[[col_name]])
  rows <- lapply(names(by_col), function(column) {
    group <- by_col[[column]]
    def <- registry_column_definition(column, registry)
    total <- sum(suppressWarnings(as.numeric(group[[count_name]])), na.rm = TRUE)
    lapply(seq_len(nrow(group)), function(i) {
      n <- suppressWarnings(as.numeric(group[[count_name]][[i]]))
      suppressed <- is.na(n) || n < min_cell_count
      semantic_value_row(
        semantic_id = semantic_id_from(c(registry, column, def$concept_id)),
        clinical_concept_id = def$concept_id,
        clinical_variable = def$variable,
        source_name = registry,
        object_name = group$object_name[[i]] %||% registry,
        raw_column = column,
        raw_value = group$value[[i]],
        display_value = group$value[[i]],
        value_class = "registry_category",
        clinical_interpretation = "Registry categorical value; interpretation requires registry data dictionary validation.",
        n = if (suppressed) NA_real_ else n,
        pct = if (!suppressed && total > 0) round(n / total * 100, 3) else NA_real_,
        denominator_label = paste("cartography value-count denominator for", registry, column),
        evidence_file = paste0("cartography_rkkp_", tolower(sub("^RKKP_", "", registry)), "_value_counts.tsv"),
        mapping_confidence = def$confidence,
        suppressed = suppressed,
        notes = if (suppressed) paste("Suppressed below minimum cell count", min_cell_count) else "Aggregate registry value count."
      )
    })
  })
  bind_rows_base(unlist(rows, recursive = FALSE))
}

damyda_registry_column_definition <- function(column, key, mk) {
  exact <- function(values) {
    key %in% vapply(values, semantic_id_from, character(1))
  }
  starts_with <- function(prefixes) {
    any(startsWith(key, vapply(prefixes, semantic_id_from, character(1))))
  }

  if (exact(c("Reg_Knogleundersoegelser_CT", "Reg_Knogleundersoegelser_ct"))) {
    return(mk(
      "myeloma_ct_modality",
      "Myeloma CT modality field",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating CT use in myeloma bone/imaging assessment.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "CT", "bone imaging", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact(c("Reg_Knogleundersoegelser_MR", "Reg_Knogleundersoegelser_mri"))) {
    return(mk(
      "myeloma_mri_modality",
      "Myeloma MRI modality field",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating MRI use in myeloma bone/imaging assessment.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "MRI", "MR", "bone imaging", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact(c("Reg_Knogleundersoegelser_PETCT", "Reg_Knogleundersoegelser_pet"))) {
    return(mk(
      "myeloma_pet_ct_modality",
      "Myeloma PET/CT modality field",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating PET/CT use in myeloma bone/imaging assessment.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "PET/CT", "FDG", "bone imaging", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact(c("Reg_Knogleundersoegelser_DEXA", "Reg_Knogleundersoegelser_dexa"))) {
    return(mk(
      "myeloma_dexa_modality",
      "Myeloma DEXA modality field",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating DEXA use in myeloma bone/imaging assessment.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "DEXA", "bone imaging", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact(c("Reg_Knogleundersoegelser_SCINTI", "Reg_Knogleundersoegelser_scinti"))) {
    return(mk(
      "myeloma_scintigraphy_modality",
      "Myeloma scintigraphy modality field",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating scintigraphy use in myeloma bone/imaging assessment.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "scintigraphy", "bone imaging", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact("Reg_AndreKnogleundersoegelse")) {
    return(mk(
      "myeloma_other_imaging",
      "Other myeloma bone/imaging investigation",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field for other bone/imaging investigations.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "other imaging", "bone investigation", column),
      "Registry modality fields are disease-specific summaries, not full imaging-event streams."
    ))
  }

  if (exact("Reg_Knogleforandringer")) {
    return(mk(
      "myeloma_bone_disease",
      "Myeloma bone disease / bone lesions",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field indicating bone disease or bone lesions.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "bone disease", "bone lesions", column),
      "Bone-disease fields preserve registry context and are not generic imaging-event streams."
    ))
  }

  if (exact("Reg_Knogleforandringer_type")) {
    return(mk(
      "myeloma_bone_lesion_type",
      "Myeloma bone lesion type",
      "Myeloma registry imaging / bone disease",
      "DaMyDa registry field describing the type of bone lesion or bone disease.",
      "categorical",
      "high",
      "confirmed",
      c("DaMyDa", "myeloma", "bone lesion type", column),
      "Bone-disease fields preserve registry context and are not generic imaging-event streams."
    ))
  }

  if (exact(c("Reg_CReaktivtProtein_gl", "Reg_CReaktivtProtein_nMoll"))) {
    return(mk(
      "crp",
      "CRP",
      "Laboratory at registration",
      "C-reactive protein measured in the DaMyDa registry.",
      "numeric",
      "high",
      "confirmed",
      c("CRP", "C-reactive protein", "inflammation", column),
      "Registry CRP fields require unit-aware interpretation."
    ))
  }

  if (exact(c(
    "Reg_Creatinin_mikmoll",
    "Reg_Creatinin_mmoll",
    "PB_Creatinin_MikMoll",
    "PB_Creatinin_mMoll",
    "PB_CreatininSeneste",
    "CREA"
  ))) {
    return(mk(
      "creatinine",
      "Creatinine",
      "Laboratory at registration",
      "Creatinine field in the registry.",
      "numeric",
      "high",
      "confirmed",
      c("creatinine", "renal function", column),
      "Creatinine units may vary by source field."
    ))
  }

  if (exact(c("Reg_Albumin_gl", "ALB"))) {
    return(mk(
      "albumin",
      "Albumin",
      "Laboratory at registration",
      "Albumin field in the registry.",
      "numeric",
      "high",
      "confirmed",
      c("albumin", column),
      "Albumin is a baseline biochemical marker."
    ))
  }

  if (exact("Reg_CalciumAlbuminkorrigeret")) {
    return(mk(
      "albumin_corrected_calcium",
      "Albumin-corrected calcium",
      "Laboratory at registration",
      "Albumin-corrected calcium field in the registry.",
      "numeric",
      "high",
      "confirmed",
      c("calcium", "albumin corrected calcium", "bone disease", column),
      "Corrected calcium is a calcium/bone-related biochemical marker, not an albumin measurement."
    ))
  }

  if (exact(c("Reg_CalciumIoniseret", "Reg_Calcium"))) {
    return(mk(
      "calcium",
      "Calcium",
      "Laboratory at registration",
      "Calcium field in the registry.",
      "numeric",
      "high",
      "confirmed",
      c("calcium", "bone disease", column),
      "Calcium fields require source-specific unit interpretation."
    ))
  }

  if (exact(c("Cyto_FishUdfoert", "Reg_FISH_Udfoert"))) {
    return(mk(
      "fish_availability",
      "FISH/cytogenetics availability",
      "Cytogenetics and molecular markers",
      "Field indicating whether FISH/cytogenetics testing was performed.",
      "categorical",
      "high",
      "confirmed",
      c("FISH", "cytogenetics", "availability", column),
      "Operational availability field; it should not be interpreted as a cytogenetic risk marker."
    ))
  }

  if (starts_with("Cyto_FishProber_")) {
    return(mk(
      "fish_probe",
      "FISH probe field",
      "Cytogenetics and molecular markers",
      "Field describing a FISH probe tested in the DaMyDa cytogenetics module.",
      "categorical",
      "high",
      "confirmed",
      c("FISH probe", "cytogenetics probe", column),
      "Probe fields describe assay coverage and probe-specific evidence, not an interpreted risk category by themselves."
    ))
  }

  if (starts_with("Cyto_FishResultat_")) {
    return(mk(
      "fish_result",
      "FISH result field",
      "Cytogenetics and molecular markers",
      "Field describing a probe-specific FISH result in the DaMyDa cytogenetics module.",
      "categorical",
      "high",
      "confirmed",
      c("FISH result", "cytogenetics result", column),
      "Probe-specific result fields require clinical grouping before interpretation as cytogenetic risk."
    ))
  }

  if (exact(c("Reg_FISH_Abnormitet", "Reg_CYTOGENRES", "Reg_ISCN_Resultat", "Reg_Ploidi"))) {
    return(mk(
      "cytogenetic_risk",
      "Cytogenetic/FISH interpretation",
      "Cytogenetics and molecular markers",
      "Interpreted cytogenetic or FISH result-summary field.",
      "categorical",
      "medium",
      "confirmed",
      c("cytogenetic risk", "FISH abnormality", column),
      "Only interpreted abnormality or summary fields should be treated as cytogenetic risk signals."
    ))
  }

  NULL
}

lyfo_registry_column_definition <- function(column, key, mk) {
  exact <- function(values) {
    key %in% vapply(values, semantic_id_from, character(1))
  }
  starts_with <- function(prefixes) {
    any(startsWith(key, vapply(prefixes, semantic_id_from, character(1))))
  }

  if (exact("subtype")) {
    return(mk(
      "lymphoma_subtype",
      "Lymphoma subtype",
      "Subtype",
      "Lymphoma subtype aggregate derived from LYFO registry profile evidence.",
      "categorical",
      "high",
      "confirmed",
      c("subtype", "DLBCL", "FL", "WM", "RKKP_LYFO"),
      "Subtype labels are registry/profile categories and should be checked against LYFO definitions."
    ))
  }

  if (exact(c("Reg_WHOHistologikode1", "Reg_WHOHistologikode2", "Rec_WHOHistologikode"))) {
    return(mk(
      "lymphoma_subtype_code",
      "WHO histology code",
      "Subtype",
      "WHO histology code field used for lymphoma subtype classification.",
      "code",
      "high",
      "confirmed",
      c("WHO histology", "histology code", "lymphoma subtype", column),
      "Histology-code fields are subtype/code fields, not performance-status fields."
    ))
  }

  if (exact("Reg_Stadium")) {
    return(mk(
      "ann_arbor_stage",
      "Ann Arbor / lymphoma stage",
      "Staging and risk",
      "Ann Arbor lymphoma staging field in LYFO.",
      "categorical",
      "high",
      "confirmed",
      c("Ann Arbor", "stage", "Reg_Stadium"),
      "Stage categories require registry data-dictionary validation before study use."
    ))
  }

  index_defs <- list(
    IPI = c("ipi", "IPI", "International Prognostic Index"),
    aaIPI = c("aaipi", "aaIPI", "age-adjusted International Prognostic Index"),
    FLIPI = c("flipi", "FLIPI", "Follicular Lymphoma International Prognostic Index"),
    FLIPI2 = c("flipi2", "FLIPI2", "Follicular Lymphoma International Prognostic Index 2"),
    IPS = c("ips", "IPS", "International Prognostic Score")
  )
  for (field in names(index_defs)) {
    if (exact(field)) {
      def <- index_defs[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Staging and risk",
        paste(def[[3]], "field in LYFO."),
        "categorical",
        "high",
        "confirmed",
        c(def[[2]], def[[3]], column),
        "Prognostic-index values preserve the raw index name and require LYFO definition checks."
      ))
    }
  }

  if (exact(c("Reg_BSymptomer"))) {
    return(mk(
      "b_symptoms",
      "B symptoms",
      "Presentation",
      "B-symptom field in the LYFO registry.",
      "categorical",
      "high",
      "confirmed",
      c("B symptoms", "fever", "night sweats", "weight loss", column),
      "Unknown categories should remain distinct from no symptoms."
    ))
  }

  if (exact(c("Reg_BulkSygdom"))) {
    return(mk(
      "bulk_disease",
      "Bulky disease",
      "Presentation",
      "Bulky disease field in the LYFO registry.",
      "categorical",
      "high",
      "confirmed",
      c("bulk disease", "bulky disease", column),
      "Unknown categories should remain distinct from no bulky disease."
    ))
  }

  if (exact(c("Reg_PerformanceStatusWHO", "Beh_PerformanceStatus", "Rec_Performancestatus"))) {
    return(mk(
      "performance_status",
      "WHO performance status",
      "Functional status",
      "WHO or treatment/follow-up performance-status field in LYFO.",
      "categorical",
      "high",
      "confirmed",
      c("performance status", "WHO performance", column),
      "Only explicit performance-status fields should be mapped here."
    ))
  }

  baseline_markers <- list(
    Reg_Haemoglobin = c("haemoglobin", "Haemoglobin", "Haemoglobin laboratory field in LYFO."),
    Reg_Albumin_gL = c("albumin", "Albumin", "Albumin laboratory field in LYFO."),
    Reg_Albumin_mikmoll = c("albumin", "Albumin", "Albumin laboratory field in LYFO."),
    Reg_CalciumAlbuminkorrigeret = c("albumin_corrected_calcium", "Albumin-corrected calcium", "Albumin-corrected calcium field in LYFO."),
    Reg_CalciumIoniseret = c("ionised_calcium", "Ionised calcium", "Ionised calcium field in LYFO."),
    Reg_Creatinin_mikmoll = c("creatinine", "Creatinine", "Creatinine laboratory field in LYFO."),
    Reg_Creatinin_millimoll = c("creatinine", "Creatinine", "Creatinine laboratory field in LYFO."),
    Reg_Lactatdehydrogenase = c("ldh", "LDH", "Lactate dehydrogenase field in LYFO."),
    Reg_LDHVaerdi = c("ldh", "LDH", "LDH value field in LYFO."),
    Reg_Beta2Microglobulin_mgL = c("beta_2_microglobulin", "Beta-2 microglobulin", "Beta-2 microglobulin field in LYFO."),
    Reg_Beta2Microglobulin_nmL = c("beta_2_microglobulin", "Beta-2 microglobulin", "Beta-2 microglobulin field in LYFO."),
    Reg_Leukocytter = c("leukocytes", "Leukocytes", "Leukocyte laboratory field in LYFO."),
    Reg_Lymfocytter_mL = c("lymphocytes", "Lymphocytes", "Lymphocyte laboratory field in LYFO."),
    Reg_Thrombocytter = c("platelets", "Platelets", "Platelet laboratory field in LYFO."),
    Reg_Saenkning = c("esr", "ESR / sedimentation rate", "Sedimentation-rate field in LYFO."),
    Reg_MProtein = c("m_protein", "M-protein", "M-protein field in LYFO.")
  )
  for (field in names(baseline_markers)) {
    if (exact(field)) {
      def <- baseline_markers[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Baseline disease markers",
        def[[3]],
        "numeric",
        "high",
        "confirmed",
        c(def[[2]], column),
        "Baseline marker availability is registry evidence; use source-specific units and definitions."
      ))
    }
  }

  treatment_fields <- c(
    "Beh_ErDerForetagetKemo",
    "Beh_Kemoterapiregime1",
    "Beh_Kemoterapiregime2",
    "Beh_Kemoterapiregime3",
    "Beh_KemoterapiStart_dt",
    "Beh_KemoterapiSlut_dt",
    "Beh_Immunoterapi",
    "Beh_ImmunoterapiCyclusantal",
    "Beh_CycluslaengdeReg1",
    "Beh_CyclusAntalReg1",
    "Beh_CycluslaengdeReg2",
    "Beh_CyclusAntalReg2",
    "Beh_CycluslaengdeReg3",
    "Beh_CyclusAntalReg3",
    "Beh_DosisIGray",
    "Beh_AntalFraktioner"
  )
  if (exact(treatment_fields) || starts_with(c("Beh_Kemoterapi", "Beh_Cyclus", "Beh_Dosis", "Beh_AntalFraktioner"))) {
    return(mk(
      "lyfo_treatment_field",
      "LYFO treatment/regimen field",
      "Treatment and regimen",
      "Registry treatment, regimen, date, cycle, immunotherapy, or radiotherapy field in LYFO.",
      if (grepl("_dt$", column, ignore.case = TRUE)) "date" else "categorical",
      "medium",
      "confirmed",
      c("treatment", "regimen", "chemotherapy", "immunotherapy", "radiotherapy", column),
      "Registry treatment fields are treatment signals, not a complete medication administration record."
    ))
  }

  if (exact(c("ind_relaps", "ind_fu")) || starts_with("Rec_")) {
    return(mk(
      "lyfo_followup_relapse",
      "LYFO follow-up / relapse field",
      "Response / follow-up / relapse",
      "Relapse, follow-up, recurrence, response, toxicity, or recurrence-treatment field in LYFO.",
      "categorical",
      "medium",
      "confirmed",
      c("relapse", "follow-up", "recurrence", column),
      "Follow-up fields can represent recurrence-specific registry forms or later treatment evidence."
    ))
  }

  if (starts_with(c("Reg_Lokal_", "Reg_Sygdomslokal"))) {
    return(mk(
      "disease_localization",
      if (exact("Reg_Lokal_Pancreas")) "Pancreas localization / extranodal disease site" else "Disease localization / involved site",
      "Disease localization",
      "Disease localization, nodal/extranodal involvement, or involved-site field in LYFO.",
      "categorical",
      "medium",
      "confirmed",
      c("disease localization", "involved site", "extranodal", column),
      "Localization fields describe disease sites; they should not be interpreted as laboratory markers."
    ))
  }

  NULL
}

cll_registry_column_definition <- function(column, key, mk) {
  exact <- function(values) {
    key %in% vapply(values, semantic_id_from, character(1))
  }

  if (exact(c("Reg_BinetStadium", "Binet"))) {
    return(mk(
      "binet_stage",
      "Binet stage",
      "CLL staging",
      "Binet stage field in the CLL registry.",
      "categorical",
      "high",
      "confirmed",
      c("Binet", "CLL stage", column),
      "Binet stage categories require CLL registry data-dictionary validation before analytic use."
    ))
  }

  if (exact(c("Reg_Umuteret", "IGHV"))) {
    return(mk(
      "ighv_mutation_status",
      "IGHV mutation status / unmutated IGHV",
      "IGHV and baseline risk markers",
      "IGHV mutation-status or unmutated-IGHV field in the CLL registry.",
      "categorical",
      "high",
      "confirmed",
      c("IGHV", "unmutated IGHV", "mutation status", column),
      "Coding direction must be checked against the CLL registry data dictionary before analytic use."
    ))
  }

  fish_fields <- list(
    Reg_FISH = c("fish_availability", "FISH performed / FISH availability", "FISH availability field in the CLL registry."),
    Reg_Del17p = c("del17p", "del(17p)", "CLL del(17p) field at registration."),
    Beh_Del17p = c("del17p", "del(17p)", "CLL del(17p) field at treatment assessment."),
    Reg_Del11q = c("del11q", "del(11q)", "CLL del(11q) field at registration."),
    Reg_Del13q14 = c("del13q14", "del(13q14)", "CLL del(13q14) field at registration."),
    Reg_Del13q = c("del13q14", "del(13q14)", "CLL del(13q) field at registration."),
    Reg_Trisomi12 = c("trisomy12", "Trisomy 12", "CLL trisomy 12 field at registration."),
    Reg_Tri12 = c("trisomy12", "Trisomy 12", "CLL trisomy 12 field at registration."),
    Reg_TP53 = c("tp53_status", "TP53 status", "CLL TP53 status field at registration."),
    Beh_TP53Mutation = c("tp53_status", "TP53 mutation", "CLL TP53 mutation field at treatment assessment."),
    Beh_FISH_TP53 = c("fish_tp53", "FISH TP53 result/availability", "CLL treatment-assessment FISH TP53 field."),
    Rec_FISH_TP53 = c("fish_tp53", "FISH TP53 result/availability", "CLL recurrence/follow-up FISH TP53 field.")
  )
  for (field in names(fish_fields)) {
    if (exact(field)) {
      def <- fish_fields[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "FISH / cytogenetics / TP53",
        def[[3]],
        "categorical",
        "high",
        "confirmed",
        c("FISH", "cytogenetics", "TP53", "CLL", column),
        "FISH, TP53, and deletion fields preserve their raw CLL registry meaning and should not be collapsed into a generic cytogenetic-risk marker."
      ))
    }
  }

  baseline_markers <- list(
    Reg_Leukocyttal = c("leukocytes", "Leukocyte count", "Baseline leukocyte-count field in the CLL registry.", "numeric"),
    Beh_Leukocyttal = c("leukocytes", "Leukocyte count", "Treatment-assessment leukocyte-count field in the CLL registry.", "numeric"),
    Reg_Beta2Microglobulin = c("beta2_microglobulin", "Beta-2 microglobulin", "Baseline beta-2 microglobulin field in the CLL registry.", "numeric"),
    Reg_Hypogammaglobulinami = c("hypogammaglobulinaemia", "Hypogammaglobulinaemia", "Baseline hypogammaglobulinaemia field in the CLL registry.", "categorical"),
    Reg_LYMFOCYTFORDOBLIN = c("lymphocyte_doubling_time", "Lymphocyte doubling / lymphocyte doubling time", "Registration lymphocyte-doubling field in the CLL registry.", "categorical"),
    Reg_ZAP70 = c("zap70_status", "ZAP70 status", "ZAP70 field in the CLL registry.", "categorical"),
    Reg_CD38Positiv = c("cd38_status", "CD38 positivity", "CD38 positivity field in the CLL registry.", "categorical"),
    Reg_Performancestatus = c("performance_status", "Performance status", "CLL registration performance-status field.", "categorical"),
    Reg_PerformanceStatusWHO = c("performance_status", "WHO performance status", "CLL WHO performance-status field.", "categorical")
  )
  for (field in names(baseline_markers)) {
    if (exact(field)) {
      def <- baseline_markers[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Baseline blood and immune markers",
        def[[3]],
        def[[4]],
        "high",
        "confirmed",
        c(def[[2]], "CLL", column),
        "Baseline and treatment-time marker context should be preserved from the raw CLL field name."
      ))
    }
  }

  workup_fields <- list(
    Reg_KnoglemarvsUndersoegelse = c("bone_marrow_examination", "Bone marrow examination / CLL diagnostic workup", "Bone marrow examination or diagnostic-workup field in the CLL registry."),
    Reg_CTSCANNING = c("cll_diagnostic_ct_workup", "CLL diagnostic CT workup", "CLL registry CT workup field."),
    Reg_ULSCANNING = c("cll_diagnostic_ultrasound_workup", "CLL diagnostic ultrasound workup", "CLL registry ultrasound workup field.")
  )
  for (field in names(workup_fields)) {
    if (exact(field)) {
      def <- workup_fields[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Diagnostic workup",
        def[[3]],
        "categorical",
        "high",
        "confirmed",
        c("diagnostic workup", "CLL registry workup", column),
        "CLL registry workup fields describe registry-coded examination availability, not general imaging coverage."
      ))
    }
  }

  symptom_fields <- list(
    Beh_Anaemi = c("cll_treatment_indication_anaemia", "Anaemia treatment indication", "Anaemia treatment-indication field."),
    Beh_Thrombocytopeni = c("cll_treatment_indication_thrombocytopenia", "Thrombocytopenia treatment indication", "Thrombocytopenia treatment-indication field."),
    Beh_Lymfadenopati = c("lymphadenopathy", "Lymphadenopathy", "Lymphadenopathy symptom/treatment-indication field."),
    Beh_Splenomegali = c("splenomegaly", "Splenomegaly", "Splenomegaly symptom/treatment-indication field."),
    Beh_StigendeLymfocytose = c("increasing_lymphocytosis", "Increasing lymphocytosis", "Increasing lymphocytosis treatment-indication field."),
    Beh_LymfocytFordoblingstid = c("lymphocyte_doubling_time", "Lymphocyte doubling time", "Lymphocyte doubling-time treatment-indication field."),
    Beh_Vaegttab = c("weight_loss", "Weight loss", "Weight-loss symptom/treatment-indication field."),
    Beh_Feber = c("fever", "Fever", "Fever symptom/treatment-indication field."),
    Beh_UdtaltTraethed = c("marked_fatigue", "Marked fatigue", "Marked fatigue symptom/treatment-indication field."),
    Beh_Nattesved = c("night_sweats", "Night sweats", "Night-sweats symptom/treatment-indication field."),
    Beh_AndreFundSymptomer = c("other_symptoms_findings", "Other symptoms/findings", "Other symptoms or findings field."),
    Beh_IndikationKemoterapi = c("cll_treatment_indication", "Treatment indication / chemotherapy indication", "Treatment or chemotherapy indication field.")
  )
  for (field in names(symptom_fields)) {
    if (exact(field)) {
      def <- symptom_fields[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Symptoms and treatment indication",
        def[[3]],
        "categorical",
        "high",
        "confirmed",
        c("CLL symptoms", "treatment indication", def[[2]], column),
        "Symptoms and treatment-indication fields should not be treated as treatment exposure."
      ))
    }
  }

  chemotherapy_fields <- c(
    "Beh_Kemo_Fludarabin", "Beh_Kemo_Chlorambucil", "Beh_Kemo_Bendamustin",
    "Beh_Kemo_other", "Beh_Kemo_none", "Rec_Kemo_Fludarabin",
    "Rec_Kemo_Chlorambucil", "Rec_Kemo_Bendamustin", "Rec_Kemo_other",
    "Rec_Kemo_none"
  )
  if (exact(chemotherapy_fields)) {
    label <- gsub("^.*Kemo_", "", column)
    label <- if (identical(tolower(label), "none")) "No chemotherapy" else paste("CLL chemotherapy:", label)
    return(mk(
      "cll_chemotherapy",
      label,
      "Treatment and targeted therapy",
      "CLL registry chemotherapy exposure or regimen field.",
      "categorical",
      "high",
      "confirmed",
      c("CLL chemotherapy", "registry treatment", column),
      "Chemotherapy fields are registry-coded treatment signals, not a complete medication administration record."
    ))
  }

  if (exact(c("Beh_Immunterapi", "Rec_Immunterapi"))) {
    return(mk(
      "cll_immunotherapy",
      "Immunotherapy",
      "Treatment and targeted therapy",
      "CLL registry immunotherapy field.",
      "categorical",
      "high",
      "confirmed",
      c("immunotherapy", "CLL treatment", column),
      "Immunotherapy fields are registry-coded treatment signals."
    ))
  }

  targeted_fields <- list(
    Beh_TargeteretBeh_Ibrutinib = "Ibrutinib",
    Beh_TargeteretBeh_idelalisib = "Idelalisib",
    Beh_TargeteretBeh_venetoclax = "Venetoclax",
    Beh_TargeteretBeh_acalabrutinib = "Acalabrutinib",
    Beh_TargeteretBeh_Other = "Other targeted therapy",
    Beh_TargeteretBeh_None = "No targeted therapy"
  )
  for (field in names(targeted_fields)) {
    if (exact(field)) {
      return(mk(
        "cll_targeted_therapy",
        paste("Targeted therapy /", targeted_fields[[field]]),
        "Treatment and targeted therapy",
        paste("CLL registry targeted therapy field for", targeted_fields[[field]], "."),
        "categorical",
        "high",
        "confirmed",
        c("targeted therapy", targeted_fields[[field]], column),
        "Targeted therapy fields indicate registry-coded treatment availability/exposure fields and should not be overinterpreted as administered medication records."
      ))
    }
  }

  if (exact("Beh_TRANSPLANT")) {
    return(mk(
      "transplant",
      "Transplant",
      "Treatment and targeted therapy",
      "CLL registry transplant field.",
      "categorical",
      "high",
      "confirmed",
      c("transplant", "CLL treatment", column),
      "Registry transplant fields require source-specific interpretation."
    ))
  }
  if (exact("Beh_TRANSPDATO")) {
    return(mk(
      "transplant",
      "Transplant date",
      "Treatment and targeted therapy",
      "CLL registry transplant date field.",
      "date",
      "high",
      "confirmed",
      c("transplant date", "CLL treatment", column),
      "Date fields are shown as raw-field availability unless a safe aggregate date summary is generated."
    ))
  }

  response_fields <- list(
    Beh_Responsevaluering = c("response_evaluation", "Response evaluation", "CLL registry response-evaluation field.", "categorical"),
    Beh_Responsevaluering_dt = c("response_evaluation", "Response evaluation date", "CLL registry response-evaluation date field.", "date"),
    Beh_MRD = c("mrd", "MRD", "CLL registry minimal residual disease field.", "categorical"),
    Rec_NyBehandling_dt = c("new_treatment_date", "New treatment / recurrence treatment date", "CLL recurrence or new-treatment date field.", "date"),
    FU_Doedsdato = c("death_date", "Death date", "CLL follow-up death-date field.", "date"),
    Beh_Doedsdato = c("death_date", "Death date", "CLL treatment-form death-date field.", "date"),
    FU_Doedsaarsag = c("cause_of_death", "Cause of death", "CLL follow-up cause-of-death field.", "categorical")
  )
  for (field in names(response_fields)) {
    if (exact(field)) {
      def <- response_fields[[field]]
      return(mk(
        def[[1]],
        def[[2]],
        "Response / MRD / follow-up",
        def[[3]],
        def[[4]],
        "high",
        "confirmed",
        c("response", "MRD", "follow-up", "outcomes", column),
        "Date and outcome fields are represented as aggregate-safe field availability unless validated summaries are generated."
      ))
    }
  }

  NULL
}

registry_column_definition <- function(column, registry) {
  key <- semantic_id_from(column)
  mk <- function(concept_id, variable, subgroup, meaning, value_type = "categorical", confidence = "medium", status = "inferred", terms = character(), caveat = "Registry field mapping is based on cartography evidence and should be checked against the registry data dictionary.") {
    list(concept_id = concept_id, variable = variable, subgroup = subgroup, meaning = meaning, value_type = value_type, confidence = confidence, status = status, terms = terms, caveat = caveat)
  }
  if (grepl("damyda", registry, ignore.case = TRUE)) {
    damyda_definition <- damyda_registry_column_definition(column, key, mk)
    if (!is.null(damyda_definition)) {
      return(damyda_definition)
    }
  }
  if (grepl("lyfo", registry, ignore.case = TRUE)) {
    lyfo_definition <- lyfo_registry_column_definition(column, key, mk)
    if (!is.null(lyfo_definition)) {
      return(lyfo_definition)
    }
    return(mk(
      semantic_id_from(c(registry, column)),
      column,
      "LYFO registry field",
      paste("Registry field", column),
      "categorical",
      "low",
      "candidate",
      c(column, registry)
    ))
  }
  if (grepl("cll", registry, ignore.case = TRUE)) {
    cll_definition <- cll_registry_column_definition(column, key, mk)
    if (!is.null(cll_definition)) {
      return(cll_definition)
    }
    return(mk(
      semantic_id_from(c(registry, column)),
      column,
      "CLL registry field",
      paste("Registry field", column),
      "categorical",
      "low",
      "candidate",
      c(column, registry)
    ))
  }
  patterns <- list(
    list("ldh", mk("ldh", "LDH", "Laboratory at registration", "Lactate dehydrogenase field in the registry.", "numeric", "high", "confirmed", c("LDH", "Reg_LDH"))),
    list("creatinin|crea", mk("creatinine", "Creatinine", "Laboratory at registration", "Creatinine field in the registry.", "numeric", "high", "confirmed", c("creatinine", "Reg_Creatinin_mikmoll", "CREA"))),
    list("haemoglobin|hemoglobin|hb", mk("haemoglobin", "Haemoglobin", "Laboratory at registration", "Haemoglobin field in the registry.", "numeric", "high", "confirmed", c("haemoglobin", "hemoglobin", "Reg_Haemoglobin", "HB"))),
    list("albumin|alb", mk("albumin", "Albumin", "Laboratory at registration", "Albumin field in the registry.", "numeric", "high", "confirmed", c("albumin", "ALB"))),
    list("beta2|b2m", mk("beta_2_microglobulin", "Beta-2 microglobulin", "Laboratory at registration", "Beta-2 microglobulin field in the registry.", "numeric", "high", "confirmed", c("B2M", "beta-2 microglobulin"))),
    list("calcium", mk("calcium", "Calcium", "Laboratory at registration", "Calcium field in the registry.", "numeric", "high", "confirmed", c("calcium"))),
    list("reaktivtprotein|crp", mk("crp", "CRP", "Laboratory at registration", "C-reactive protein field in the registry.", "numeric", "high", "confirmed", c("CRP", "C-reactive protein"))),
    list("vaegt|weight", mk("weight", "Weight", "Anthropometrics", "Weight at registration or registry assessment.", "numeric", "high", "confirmed", c("weight", "Reg_Vaegt"))),
    list("hoejde|height", mk("height", "Height", "Anthropometrics", "Height at registration or registry assessment.", "numeric", "high", "confirmed", c("height", "Reg_Hoejde"))),
    list("knogle|osteo", mk("bone_involvement", "Bone involvement type", "Myeloma CRAB and imaging", "Bone involvement or skeletal disease field.", "categorical", "high", "confirmed", c("bone disease", "skeletal", "Reg_Knogleforandringer_type"))),
    list("stadie|stadium|iss|r_iss|riss|r2", mk("stage", "Disease stage", "Staging", "Disease staging field.", "categorical", "high", "confirmed", c("stage", "ISS", "R-ISS", "Binet", "Ann Arbor"))),
    list("mkomponent|mkomp|paraprotein|plasmam", mk("m_component", "M-component / paraprotein", "Myeloma markers", "M-component or paraprotein field.", "numeric", "medium", "inferred", c("M-component", "paraprotein"))),
    list("frikaede|kappa|lambda", mk("light_chain", "Light-chain disease marker", "Myeloma markers", "Free light chain or kappa/lambda field.", "numeric", "medium", "inferred", c("free light chain", "kappa", "lambda"))),
    list("fish|cyto|karyotype|del17|del11|del13|trisomi|tp53", mk("cytogenetic_risk", "Cytogenetic risk marker", "Genetics and cytogenetics", "FISH, cytogenetic, or molecular risk marker.", "categorical", "high", "confirmed", c("FISH", "cytogenetics", "TP53", "del17p", "del11q", "del13q", "trisomy 12"))),
    list("performancestatus|ecog|who", mk("performance_status", "Performance status", "Functional status", "Performance status field.", "categorical", "high", "confirmed", c("performance", "WHO", "ECOG"))),
    list("bsy|bsymptom", mk("b_symptoms", "B symptoms", "Lymphoma presentation", "B symptoms field.", "categorical", "high", "confirmed", c("B symptoms", "fever", "night sweats", "weight loss"))),
    list("ipi|flipi", mk("prognostic_index", "Prognostic index", "Lymphoma risk", "IPI, aaIPI, FLIPI, or related prognostic index.", "categorical", "high", "confirmed", c("IPI", "aaIPI", "FLIPI"))),
    list("ighv", mk("ighv_status", "IGHV mutation status", "CLL genetics", "IGHV mutation-status field.", "categorical", "high", "confirmed", c("IGHV", "mutation status"))),
    list("binet", mk("binet_stage", "Binet stage", "CLL staging", "Binet stage field.", "categorical", "high", "confirmed", c("Binet", "CLL stage"))),
    list("behandl|beh_|regimen|kur|treat", mk("treatment", "Treatment signal", "Treatment", "Treatment, treatment line, regimen, or registry treatment indicator.", "categorical", "medium", "inferred", c("treatment", "regimen", "behandling"))),
    list("respons|response", mk("response", "Response / best response", "Response", "Response or best-response field.", "categorical", "medium", "inferred", c("response", "best response"))),
    list("relaps|progression|prog", mk("relapse_progression", "Relapse / progression", "Disease course", "Relapse or progression field.", "categorical", "medium", "inferred", c("relapse", "progression"))),
    list("diagnose|dato|_dt$", mk("diagnosis_date", "Diagnosis date", "Timing", "Diagnosis or registry date field.", "date", "medium", "inferred", c("diagnosis date", "Reg_Diagnose_dt")))
  )
  for (pat in patterns) {
    if (grepl(pat[[1]], key, ignore.case = TRUE)) return(pat[[2]])
  }
  mk(
    semantic_id_from(c(registry, column)),
    column,
    if (grepl("DaMyDa", registry, ignore.case = TRUE)) "DaMyDa registry field" else if (grepl("LYFO", registry, ignore.case = TRUE)) "LYFO registry field" else "CLL registry field",
    paste("Registry field", column),
    "categorical",
    "low",
    "candidate",
    c(column, registry)
  )
}

semantic_npu_code_rows <- function(x, evidence_file, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"npu_code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    code <- x$npu_code[[i]]
    name <- x$name[[i]] %||% code
    semantic_code_row(
      semantic_id = semantic_id_from(c("npu", code, name)),
      clinical_concept_id = lab_concept_id(code, name),
      clinical_variable = lab_variable_name(code, name),
      clinical_group = "Laboratory",
      source_name = x$source[[i]] %||% "Laboratory",
      object_name = x$source[[i]] %||% "Laboratory",
      code_system = if (grepl("^DNK", code, ignore.case = TRUE)) "DNK" else "NPU",
      code = code,
      code_name = name,
      panel = x$panel[[i]] %||% "NPU disease panel",
      n_rows = semantic_suppress_count(x$n_rows[[i]], min_cell_count),
      n_patients = semantic_suppress_count(x$n_patients[[i]], min_cell_count),
      evidence_file = evidence_file,
      mapping_confidence = "high",
      notes = "Consensus NPU disease-panel evidence from cartography."
    )
  })
  bind_rows_base(rows)
}

semantic_concordance_code_rows <- function(x, evidence_file, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    code <- x$code[[i]]
    name <- x$name[[i]] %||% code
    semantic_code_row(
      semantic_id = semantic_id_from(c("lab", code, name, x$source[[i]])),
      clinical_concept_id = lab_concept_id(code, name),
      clinical_variable = lab_variable_name(code, name),
      clinical_group = "Laboratory",
      source_name = x$source[[i]] %||% "Laboratory",
      object_name = x$source[[i]] %||% "Laboratory",
      code_system = if (grepl("^DNK", code, ignore.case = TRUE)) "DNK" else if (grepl("^NPU", code, ignore.case = TRUE)) "NPU" else "local_lab_code",
      code = code,
      code_name = name,
      panel = "Biochemistry concordance",
      n_rows = semantic_suppress_count(x$n[[i]], min_cell_count),
      evidence_file = evidence_file,
      mapping_confidence = "high",
      notes = "Cross-source biochemistry concordance evidence."
    )
  })
  bind_rows_base(rows)
}

semantic_named_code_rows <- function(x, code_col, name_col, count_col, source_name, evidence_file,
                                     min_cell_count, clinical_group = "Laboratory") {
  if (!is.data.frame(x) || !nrow(x) || !code_col %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    code <- x[[code_col]][[i]]
    if (!nzchar(code) || is_sensitive_column(code)) return(NULL)
    name <- if (nzchar(name_col) && name_col %in% names(x)) x[[name_col]][[i]] else lab_variable_name(code, code)
    code_system <- if (grepl("^NPU", code, ignore.case = TRUE)) "NPU" else if (grepl("^DNK", code, ignore.case = TRUE)) "DNK" else if (grepl("^[A-Z][0-9]{2}", code)) "ATC" else "local_code"
    semantic_code_row(
      semantic_id = semantic_id_from(c(source_name, code, name)),
      clinical_concept_id = if (clinical_group == "Laboratory") lab_concept_id(code, name) else semantic_id_from(c(code_system, name)),
      clinical_variable = if (clinical_group == "Laboratory") lab_variable_name(code, name) else first_nonblank(name, code),
      clinical_group = clinical_group,
      source_name = source_name,
      object_name = source_name,
      code_system = code_system,
      code = code,
      code_name = first_nonblank(name, code),
      panel = if (clinical_group == "Laboratory") "Laboratory code map" else "Treatment code map",
      n_rows = if (count_col %in% names(x)) semantic_suppress_count(x[[count_col]][[i]], min_cell_count) else NA_real_,
      evidence_file = evidence_file,
      mapping_confidence = "medium",
      notes = "Top named code evidence from cartography."
    )
  })
  bind_rows_base(rows)
}

semantic_treatment_matrix_rows <- function(x, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    semantic_code_row(
      semantic_id = semantic_id_from(c("treatment", x$code[[i]], x$disease[[i]])),
      clinical_concept_id = semantic_id_from(c("treatment", x$description[[i]] %||% x$code[[i]])),
      clinical_variable = first_nonblank(x$description[[i]], paste("Treatment code", x$code[[i]])),
      clinical_group = "Treatment",
      source_name = x$source[[i]] %||% "Treatment",
      object_name = x$source[[i]] %||% "Treatment",
      code_system = x$code_system[[i]] %||% "treatment_code",
      code = x$code[[i]],
      code_name = x$description[[i]] %||% x$code[[i]],
      panel = x$disease[[i]] %||% "Treatment signal matrix",
      n_rows = semantic_suppress_count(x$n_rows[[i]], min_cell_count),
      n_patients = semantic_suppress_count(x$n_patients[[i]], min_cell_count),
      evidence_file = "cartography_disease_treatment_matrix.tsv",
      mapping_confidence = "high",
      notes = "Disease-treatment matrix evidence; code-level treatment signal unless regimen label is explicit."
    )
  })
  bind_rows_base(rows)
}

semantic_sks_rows <- function(x, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    semantic_code_row(
      semantic_id = semantic_id_from(c("sks", x$code[[i]], x$disease[[i]])),
      clinical_concept_id = semantic_id_from(c("sks", x$description[[i]] %||% x$code[[i]])),
      clinical_variable = first_nonblank(x$description[[i]], paste("SKS treatment code", x$code[[i]])),
      clinical_group = "Treatment",
      source_name = x$source[[i]] %||% "SDS/SKS",
      object_name = x$source[[i]] %||% "SDS/SKS",
      code_system = "SKS",
      code = x$code[[i]],
      code_name = x$description[[i]] %||% x$code[[i]],
      panel = x$disease[[i]] %||% "SKS treatment codes",
      n_rows = semantic_suppress_count(x$prefix_rows[[i]] %||% x$exact_rows[[i]], min_cell_count),
      n_patients = semantic_suppress_count(x$prefix_patients[[i]] %||% x$exact_patients[[i]], min_cell_count),
      evidence_file = "cartography_sks_treatment_codes.tsv",
      mapping_confidence = "high",
      notes = "SKS exact/prefix treatment-code evidence."
    )
  })
  bind_rows_base(rows)
}

semantic_sks_top_rows <- function(x, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    semantic_code_row(
      semantic_id = semantic_id_from(c("sks_antineoplastic", x$code[[i]])),
      clinical_concept_id = semantic_id_from(c("sks_antineoplastic", x$code[[i]])),
      clinical_variable = paste("SKS antineoplastic procedure", x$code[[i]]),
      clinical_group = "Treatment",
      source_name = "SDS/SKS",
      object_name = "SDS/SKS",
      code_system = "SKS",
      code = x$code[[i]],
      code_name = paste("SKS antineoplastic procedure", x$code[[i]]),
      panel = "SKS antineoplastic top codes",
      n_rows = semantic_suppress_count(x$n[[i]], min_cell_count),
      evidence_file = "cartography_sks_antineoplastic_top50.tsv",
      mapping_confidence = "medium",
      notes = "Top SKS antineoplastic code evidence."
    )
  })
  bind_rows_base(rows)
}

semantic_atc_rows <- function(x, min_cell_count) {
  if (!is.data.frame(x) || !nrow(x) || !"atc_code" %in% names(x)) return(empty_semantic_code_map())
  rows <- lapply(seq_len(nrow(x)), function(i) {
    semantic_code_row(
      semantic_id = semantic_id_from(c("atc", x$atc_code[[i]], x$drug_name[[i]])),
      clinical_concept_id = semantic_id_from(c("atc", x$drug_name[[i]] %||% x$atc_code[[i]])),
      clinical_variable = first_nonblank(x$drug_name[[i]], paste("ATC", x$atc_code[[i]])),
      clinical_group = "Treatment",
      source_name = x$source[[i]] %||% "Medication",
      object_name = x$source[[i]] %||% "Medication",
      code_system = "ATC",
      code = x$atc_code[[i]],
      code_name = x$drug_name[[i]] %||% x$atc_code[[i]],
      panel = x$disease[[i]] %||% "ATC antineoplastic codes",
      n_rows = semantic_suppress_count(x$prefix_rows[[i]] %||% x$exact_rows[[i]], min_cell_count),
      n_patients = semantic_suppress_count(x$n_patients[[i]], min_cell_count),
      evidence_file = "cartography_atc_antineoplastic_codes.tsv",
      mapping_confidence = "high",
      notes = "ATC antineoplastic/immunomodulating therapy evidence."
    )
  })
  bind_rows_base(rows)
}

semantic_value_count_code_rows <- function(project_root, files, clinical_group, subgroup, terms, min_cell_count) {
  code_rows <- list()
  dict_rows <- list()
  for (file in files) {
    x <- read_cartography_table(file, project_root)
    if (!is.data.frame(x) || !nrow(x)) next
    col_col <- intersect(c("column_name", "column"), names(x))[1]
    val_col <- intersect(c("value", "val", "snomed", "code"), names(x))[1]
    count_col <- intersect(c("n_rows", "n"), names(x))[1]
    if (is.na(val_col) || is.na(count_col)) next
    if (!is.na(col_col)) {
      x <- x[!vapply(x[[col_col]], semantic_identifier_like_column, logical(1)), , drop = FALSE]
    }
    source_name <- if ("source_name" %in% names(x)) x$source_name else rep(sub("^cartography_|_value_counts\\.tsv$|_top_snomed\\.tsv$", "", file), nrow(x))
    object_name <- if ("object_name" %in% names(x)) x$object_name else source_name
    keep <- semantic_domain_keep_rows(x[[val_col]], clinical_group)
    if (clinical_group %in% c("Microbiology", "Biobank", "Pathology", "Outcomes")) keep <- rep(TRUE, nrow(x))
    x <- head(x[keep, , drop = FALSE], 150)
    if (!nrow(x)) next
    for (i in seq_len(nrow(x))) {
      code <- x[[val_col]][[i]]
      column <- if (!is.na(col_col)) x[[col_col]][[i]] else ""
      is_microbiology <- identical(clinical_group, "Microbiology")
      is_imaging <- identical(clinical_group, "Imaging")
      is_pathology <- identical(clinical_group, "Pathology")
      if (is_pathology && !nzchar(column) && identical(file, "cartography_pato_top_snomed.tsv")) {
        column <- "c_snomedkode"
      }
      if (semantic_identifier_like_column(column)) next
      if (is_microbiology && (microbiology_date_like_column(column) || microbiology_free_text_column(column))) next
      if (is_imaging && (imaging_date_like_column(column) || imaging_free_text_column(column))) next
      n <- semantic_suppress_count(x[[count_col]][[i]], min_cell_count)
      row_source <- semantic_vector_value(source_name, i)
      row_object <- semantic_vector_value(object_name, i, row_source)
      micro_def <- if (is_microbiology) microbiology_column_definition(row_source, column) else NULL
      micro_ctx <- if (is_microbiology) microbiology_source_context(row_source, row_object, file) else NULL
      imaging_def <- if (is_imaging) imaging_column_definition(row_source, row_object, column, code) else NULL
      imaging_ctx <- if (is_imaging) imaging_source_context(row_source, row_object, file, code, column) else NULL
      pathology_def <- if (is_pathology) pathology_column_definition(row_source, row_object, column, code) else NULL
      pathology_ctx <- if (is_pathology) pathology_source_context(row_source, row_object, file, column) else NULL
      variable <- if (is_microbiology) {
        micro_def$variable
      } else if (is_imaging) {
        imaging_def$variable
      } else if (is_pathology) {
        pathology_def$variable
      } else {
        semantic_domain_variable(clinical_group, code, column)
      }
      concept_id <- if (is_microbiology) {
        micro_def$concept_id
      } else if (is_imaging) {
        imaging_def$concept_id
      } else if (is_pathology) {
        pathology_def$concept_id
      } else {
        semantic_id_from(c(clinical_group, variable))
      }
      subgroup_value <- if (is_microbiology) {
        paste(micro_ctx$layer, micro_def$subgroup, sep = " - ")
      } else if (is_imaging) {
        paste(imaging_ctx$layer, imaging_def$subgroup, sep = " - ")
      } else if (is_pathology) {
        paste(pathology_ctx$layer, pathology_def$subgroup, sep = " - ")
      } else {
        subgroup
      }
      safe_value <- if (is_microbiology) {
        microbiology_safe_display_value(column, code, concept_id, x[[count_col]][[i]], min_cell_count)
      } else if (is_imaging) {
        imaging_safe_display_value(column, code, concept_id, x[[count_col]][[i]], min_cell_count)
      } else if (is_pathology) {
        pathology_safe_display_value(column, code, concept_id, x[[count_col]][[i]], min_cell_count)
      } else {
        code
      }
      if (!nzchar(safe_value)) next
      semantic_id <- semantic_id_from(c(clinical_group, row_source, column, safe_value))
      semantic_meaning <- if (is_microbiology) {
        paste(micro_ctx$meaning, micro_def$meaning)
      } else if (is_imaging) {
        paste(imaging_ctx$meaning, imaging_def$meaning)
      } else if (is_pathology) {
        paste(pathology_ctx$meaning, pathology_def$meaning)
      } else {
        semantic_domain_meaning(clinical_group, code, column)
      }
      clinical_caveat <- if (is_microbiology) {
        paste(micro_ctx$caveat, "Detailed organism/species values and free text are suppressed or grouped.", micro_def$meaning)
      } else if (is_imaging) {
        paste(imaging_ctx$caveat, imaging_def$caveat, "No report text, patient rows, image pixels, or raw dates are emitted.")
      } else if (is_pathology) {
        paste(pathology_ctx$caveat, pathology_def$caveat, "No raw pathology report text, patient rows, or raw date values are emitted.")
      } else {
        semantic_domain_caveat(clinical_group)
      }
      search_terms <- if (is_microbiology) {
        c(terms, micro_ctx$terms, micro_def$terms, safe_value, column, row_source, micro_ctx$layer)
      } else if (is_imaging) {
        c(terms, imaging_ctx$terms, imaging_def$terms, safe_value, column, row_source, imaging_ctx$layer)
      } else if (is_pathology) {
        c(terms, pathology_ctx$terms, pathology_def$terms, safe_value, column, row_source, pathology_ctx$layer)
      } else {
        c(terms, code, column, row_source)
      }
      code_system <- if (is_imaging) {
        imaging_def$code_system
      } else if (is_pathology) {
        pathology_def$code_system
      } else {
        semantic_domain_code_system(clinical_group, code, column)
      }
      dict_rows[[length(dict_rows) + 1L]] <- semantic_row(
        semantic_id = semantic_id,
        clinical_concept_id = concept_id,
        clinical_variable = variable,
        clinical_group = clinical_group,
        clinical_subgroup = subgroup_value,
        semantic_meaning = semantic_meaning,
        source_name = row_source,
        object_name = row_object,
        raw_column = column,
        raw_descriptor = if (is_microbiology || is_imaging || is_pathology) safe_value else if (clinical_group %in% c("Biobank")) code else "",
        raw_code = if (is_microbiology || (is_pathology && identical(pathology_def$value_type, "free_text"))) "" else if (clinical_group %in% c("Treatment", "Pathology", "Imaging") || grepl("^[A-Z0-9]{3,}", code)) safe_value else "",
        raw_value = if (is_microbiology) safe_value else if (clinical_group %in% c("Biobank", "Outcomes")) code else "",
        code_system = code_system,
        value_type = if (is_imaging) imaging_def$value_type else if (is_pathology) pathology_def$value_type else if (grepl("text|note|beskrivelse", column, ignore.case = TRUE)) "free_text" else "code",
        data_shape = "code_table",
        source_level = source_level_for_source(row_source),
        geography = geography_for_source(row_source),
        n_rows = n,
        evidence_file = file,
        evidence_filter = paste0(column, "=", safe_value),
        mapping_confidence = if (is_microbiology) micro_def$confidence else if (is_imaging) imaging_def$confidence else if (is_pathology) pathology_def$confidence else if (clinical_group == "Biobank") "medium" else "high",
        mapping_status = if (is_microbiology) micro_def$status else if (is_imaging) imaging_def$status else if (is_pathology) pathology_def$status else if (clinical_group == "Biobank") "candidate" else "inferred",
        privacy_note = if (is_microbiology && identical(safe_value, "suppressed / not shown")) "aggregate_only_suppressed_value" else if (is_pathology && pathology_free_text_column(column)) "free_text_not_exposed" else if (is_pathology && pathology_date_like_column(column)) "date_values_not_exposed" else if (is_imaging && imaging_free_text_column(column)) "free_text_not_exposed" else if (is_imaging && imaging_date_like_column(column)) "date_values_not_exposed" else if (grepl("text|note|beskrivelse", column, ignore.case = TRUE)) "free_text_not_exposed" else "aggregate_only",
        clinical_caveat = clinical_caveat,
        search_terms = semantic_terms(search_terms)
      )
      if (nzchar(safe_value)) {
        code_rows[[length(code_rows) + 1L]] <- semantic_code_row(
          semantic_id = semantic_id,
          clinical_concept_id = concept_id,
          clinical_variable = variable,
          clinical_group = clinical_group,
          source_name = row_source,
          object_name = row_object,
          code_system = code_system,
          code = safe_value,
          code_name = if (is_pathology) safe_value else variable,
          panel = subgroup_value,
          n_rows = n,
          evidence_file = file,
          mapping_confidence = if (is_microbiology) micro_def$confidence else if (is_imaging) imaging_def$confidence else if (is_pathology) pathology_def$confidence else "medium",
          notes = if (is_microbiology) paste(micro_ctx$caveat, "Detailed organism/species values and free text are suppressed or grouped.") else if (is_imaging) clinical_caveat else if (is_pathology) clinical_caveat else semantic_domain_caveat(clinical_group)
        )
      }
    }
  }
  dictionary <- bind_rows_base(dict_rows)
  list(
    dictionary = dictionary,
    code_map = semantic_dedupe_code_map(bind_rows_base(code_rows))
  )
}

semantic_identifier_like_column <- function(name) {
  name <- as.character(name %||% "")
  is_sensitive_column(name) ||
    grepl("(^id$|_id$|(^|_)id_|identifier|patient|person|cpr|pnr|recnum|record|rekv)", name, ignore.case = TRUE)
}

semantic_dictionary_from_code_map <- function(code_map, clinical_group, subgroup, data_shape) {
  if (!is.data.frame(code_map) || !nrow(code_map)) return(empty_semantic_data_dictionary())
  rows <- lapply(seq_len(nrow(code_map)), function(i) {
    semantic_row(
      semantic_id = code_map$semantic_id[[i]],
      clinical_concept_id = code_map$clinical_concept_id[[i]],
      clinical_variable = code_map$clinical_variable[[i]],
      clinical_group = code_map$clinical_group[[i]] %||% clinical_group,
      clinical_subgroup = subgroup,
      semantic_meaning = paste(code_map$clinical_variable[[i]], "identified by", code_map$code_system[[i]], "code", code_map$code[[i]]),
      source_name = code_map$source_name[[i]],
      object_name = code_map$object_name[[i]],
      raw_code = code_map$code[[i]],
      code_system = code_map$code_system[[i]],
      value_type = "code",
      data_shape = data_shape,
      source_level = source_level_for_source(code_map$source_name[[i]]),
      geography = geography_for_source(code_map$source_name[[i]]),
      n_rows = code_map$n_rows[[i]],
      n_patients = code_map$n_patients[[i]],
      evidence_file = code_map$evidence_file[[i]],
      evidence_filter = paste0("code=", code_map$code[[i]]),
      mapping_confidence = code_map$mapping_confidence[[i]],
      mapping_status = "confirmed",
      privacy_note = "aggregate_only",
      clinical_caveat = code_map$notes[[i]],
      search_terms = semantic_terms(c(code_map$code[[i]], code_map$code_name[[i]], code_map$clinical_variable[[i]], code_map$code_system[[i]], code_map$panel[[i]]))
    )
  })
  bind_rows_base(rows)
}

lab_concept_id <- function(code, name) {
  lab_concept_definition(code, name)$concept_id
}

lab_variable_name <- function(code, name) {
  lab_concept_definition(code, name)$variable
}

semantic_concept_definition <- function(concept, column, source_name) {
  concept_key <- semantic_id_from(concept)
  defs <- list(
    smoking_tobacco = list("smoking_status", "Smoking status", "Lifestyle", "Social history", "categorical", "local_field", c("smoking", "tobacco", "ryger")),
    alcohol = list("alcohol_use", "Alcohol use", "Lifestyle", "Social history", "categorical", "local_field", c("alcohol", "drikker")),
    weight = list("weight", "Weight", "Vitals", "Anthropometrics", "numeric", "local_field", c("weight", "body weight")),
    height = list("height", "Height", "Vitals", "Anthropometrics", "numeric", "local_field", c("height")),
    bmi = list("bmi", "BMI", "Vitals", "Anthropometrics", "numeric", "local_field", c("BMI", "body mass index")),
    atc = list("atc_medication_code", "ATC medication code", "Treatment", "Medication codes", "code", "ATC", c("ATC", "medicine", "drug")),
    sks = list("sks_code", "SKS code", "Treatment", "Procedure and diagnosis codes", "code", "SKS", c("SKS", "procedure", "diagnosis")),
    r_iss_or_stage = list("stage", "Disease stage", "Registry", "Staging", "categorical", "RKKP_field", c("stage", "ISS", "R-ISS")),
    bone_involvement = list("bone_involvement", "Bone involvement", "Registry", "Skeletal disease", "categorical", "RKKP_field", c("bone disease", "skeletal")),
    multiple_myeloma = list("diagnosis_or_disease_label", "Diagnosis / disease label", "Diagnosis", "Disease labels", "code", "ICD10/SKS/local", c("diagnosis", "myeloma", "lymphoma", "CLL"))
  )
  d <- defs[[concept_key]]
  if (is.null(d)) d <- list(concept_key, column, "Clinical Data", "Candidate variables", "categorical", "local_field", c(concept, column))
  list(
    concept_id = d[[1]], variable = d[[2]], group = d[[3]], subgroup = d[[4]],
    value_type = d[[5]], code_system = d[[6]], terms = d[[7]]
  )
}

source_level_for_source <- function(source_name) {
  source_name <- as.character(source_name %||% "")
  if (grepl("^RKKP", source_name, ignore.case = TRUE)) return("RKKP registry")
  if (grepl("^SP_", source_name, ignore.case = TRUE)) return("SP/EHR")
  if (grepl("^SDS|^LPR|^LPR3|diagnos|patient", source_name, ignore.case = TRUE)) return("nationwide")
  if (grepl("PERSIMUNE", source_name, ignore.case = TRUE)) return("PERSIMUNE")
  if (grepl("biobank", source_name, ignore.case = TRUE)) return("biobank")
  "unknown"
}

geography_for_source <- function(source_name) {
  source_name <- as.character(source_name %||% "")
  if (grepl("^SP_", source_name, ignore.case = TRUE)) return("eastern Denmark/SP")
  if (grepl("PERSIMUNE", source_name, ignore.case = TRUE)) return("Capital Region/PERSIMUNE")
  if (grepl("^RKKP|^SDS|^LPR|^LPR3|patient|diagnos", source_name, ignore.case = TRUE)) return("nationwide")
  "unknown"
}

imaging_date_like_column <- function(column) {
  grepl("(^|_)(date|dato|datetime|time|tidspunkt)($|_)|_dt$|dato|tidspunkt|bestillingstidspunkt", column, ignore.case = TRUE)
}

imaging_free_text_column <- function(column) {
  grepl("rapporttekst|report_text|reporttext|beskrivelse|tekst|text|note|free_text", column, ignore.case = TRUE)
}

imaging_source_context <- function(source_name = "", object_name = "", evidence_file = "", code = "", column = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", evidence_file %||% "", column %||% "", sep = " "))
  code_text <- paste(code %||% "", column %||% "")
  mk <- function(layer, subgroup, meaning, caveat, terms) {
    list(layer = layer, subgroup = subgroup, meaning = meaning, caveat = caveat, terms = terms)
  }
  if (grepl("^BWGC|radioter|straale|straalebehandling|strale|stråle", code_text, ignore.case = TRUE)) {
    return(mk(
      "Radiotherapy procedure signals",
      "Radiotherapy procedure signals",
      "Radiotherapy procedure-code signal.",
      "Radiotherapy procedure codes are treatment/procedure signals, not medication exposure or image pixels.",
      c("radiotherapy", "BWGC", "procedure")
    ))
  }
  if (grepl("rkkp_damyda|damyda", key)) {
    return(mk(
      "DaMyDa registry imaging / bone disease",
      "DaMyDa registry imaging / bone disease",
      "Disease-specific DaMyDa registry imaging, modality, or bone-disease field.",
      "Registry modality fields are disease-specific summaries, not full imaging-event streams.",
      c("DaMyDa", "registry imaging", "bone disease")
    ))
  }
  if (grepl("billeddiagnostik|billeddiagnostiske|sp_billed", key)) {
    return(mk(
      "SP imaging metadata/report layer",
      "SP imaging metadata/report layer",
      "EHR-native imaging order, code, metadata, or report-text availability layer.",
      "Report text/free text must not be emitted into the static atlas. Show availability and metadata only.",
      c("SP imaging", "billeddiagnostik", "metadata", "report availability")
    ))
  }
  if (grepl("sksube|procedurer|procedure|sds", key)) {
    return(mk(
      "Nationwide procedure-code imaging",
      "Procedure-code imaging",
      "National SKS/UX/BWGC procedure-coded imaging or radiotherapy signal.",
      "Procedure-code signals are event/procedure evidence, not image pixels and not necessarily report text.",
      c("SDS", "SKS", "procedure", "UX", "BWGC")
    ))
  }
  mk(
    "Candidate imaging evidence",
    "Candidate imaging evidence",
    "Candidate imaging aggregate evidence layer.",
    "Candidate imaging rows require source-specific validation and do not imply image-pixel availability.",
    c("imaging", "candidate")
  )
}

imaging_column_definition <- function(source_name = "", object_name = "", column = "", value = "") {
  col_key <- semantic_id_from(column)
  value_text <- as.character(value %||% "")
  value_key <- toupper(value_text)
  combined <- paste(value_text, column)
  mk <- function(id, variable, subgroup, meaning, terms, confidence = "high", status = "confirmed",
                 value_type = "code", code_system = "local_imaging_code", caveat = "") {
    list(
      concept_id = id,
      variable = variable,
      subgroup = subgroup,
      meaning = meaning,
      terms = terms,
      confidence = confidence,
      status = status,
      value_type = value_type,
      code_system = code_system,
      caveat = caveat
    )
  }
  if (imaging_free_text_column(column)) {
    return(mk(
      "sp_imaging_report_text_availability",
      "SP imaging report text availability",
      "SP imaging metadata/report layer",
      "SP imaging report/free-text availability field.",
      c("SP imaging", "report text", "rapporttekst", column),
      "high",
      "confirmed",
      "free_text",
      "SP_imaging_metadata",
      "Report text values are not emitted into the static atlas."
    ))
  }
  if (imaging_date_like_column(column)) {
    return(mk(
      "sp_imaging_order_date",
      "SP imaging order time / date field",
      "SP imaging metadata/report layer",
      "SP imaging order or examination time metadata field.",
      c("SP imaging", "order date", "bestillingstidspunkt", column),
      "high",
      "confirmed",
      "date",
      "SP_imaging_metadata",
      "Date values are retained as structural metadata only and are not rendered as categorical bars."
    ))
  }
  if (col_key == "hospital_area_name") {
    return(mk(
      "sp_imaging_hospital_area",
      "SP imaging hospital area",
      "SP imaging metadata/report layer",
      "SP imaging hospital-area metadata field.",
      c("SP imaging", "hospital area", column),
      "high",
      "confirmed",
      "categorical",
      "SP_imaging_metadata",
      "Hospital-area metadata is source coverage context, not a clinical imaging phenotype."
    ))
  }
  if (grepl("^BWGC", value_key) || grepl("\\bBWGC|radioter|straale|strale|strålebehandling|electron beam", combined, ignore.case = TRUE)) {
    return(mk(
      "radiotherapy",
      "Radiotherapy procedure signal",
      "Radiotherapy procedure signals",
      "Radiotherapy procedure-coded signal.",
      c("radiotherapy", "BWGC", "procedure", value_text),
      "high",
      "confirmed",
      "code",
      "SKS",
      "Radiotherapy is a procedure/treatment signal, not medication exposure or image pixels."
    ))
  }
  if (grepl("PET|PET[-/ ]?CT|FDG|F-18", combined, ignore.case = TRUE)) {
    return(mk(
      "imaging_pet_ct",
      "PET / PET-CT imaging signal",
      "Procedure-code imaging",
      "PET or PET/CT imaging procedure or SP imaging metadata signal.",
      c("PET", "PET/CT", "FDG", value_text),
      "high",
      "confirmed",
      "code",
      if (grepl("^UX|^BW|^AP", value_key)) "SKS" else "local_imaging_code",
      "PET/PET-CT rows are procedure or metadata evidence, not image pixels."
    ))
  }
  if (value_key %in% c("UXZ11") || grepl("(^|[^A-Z])MRI([^A-Z]|$)|(^|[^A-Z])MR([^A-Z]|$)|magnetic resonance", combined, ignore.case = TRUE)) {
    return(mk(
      "imaging_mri",
      "MRI imaging signal",
      "Procedure-code imaging",
      "MRI imaging procedure or SP imaging metadata signal.",
      c("MRI", "MR", "UXZ11", value_text),
      "high",
      "confirmed",
      "code",
      if (grepl("^UX|^BW|^AP", value_key)) "SKS" else "local_imaging_code",
      "MRI rows are procedure or metadata evidence, not image pixels."
    ))
  }
  if (value_key %in% c("UXRC00") || grepl("RU THORAX|R[OØ]NTGEN|RONTGEN|X[- ]?RAY|CHEST X[- ]?RAY", combined, ignore.case = TRUE)) {
    return(mk(
      "imaging_xray",
      "X-ray imaging signal",
      "Procedure-code imaging",
      "X-ray imaging procedure or SP imaging metadata signal.",
      c("X-ray", "Rontgen", "RU THORAX", "UXRC00", value_text),
      "high",
      "confirmed",
      "code",
      if (grepl("^UX|^BW|^AP", value_key)) "SKS" else "local_imaging_code",
      "X-ray rows are procedure or metadata evidence, not image pixels."
    ))
  }
  if (value_key %in% c("APAA4", "UXZ10", "UXCC00", "UXCD00", "UXCD10", "UXCD15", "UXCA00") || grepl("(^|[^A-Z])CT([^A-Z]|$)|CT THORAX|CT ABDOMEN|CT CEREBRUM|CT HELKROP|CT HALS", combined, ignore.case = TRUE)) {
    return(mk(
      "imaging_ct",
      "CT imaging signal",
      "Procedure-code imaging",
      "CT imaging procedure or SP imaging metadata signal.",
      c("CT", "UXZ10", "UXCC00", "UXCD00", "APAA4", value_text),
      "high",
      "confirmed",
      "code",
      if (grepl("^UX|^BW|^AP", value_key)) "SKS" else "local_imaging_code",
      "CT rows are procedure or metadata evidence, not image pixels."
    ))
  }
  if (col_key == "bestillingsnavn") {
    return(mk(
      "sp_imaging_exam_name",
      "SP imaging order/examination name",
      "SP imaging metadata/report layer",
      "SP imaging order or examination-name metadata field.",
      c("SP imaging", "bestillingsnavn", value_text),
      "medium",
      "confirmed",
      "categorical",
      "SP_imaging_metadata",
      "SP imaging names are EHR metadata and do not imply image-pixel or report-text availability."
    ))
  }
  if (col_key == "bld_kode") {
    return(mk(
      "sp_imaging_code",
      "SP imaging code",
      "SP imaging metadata/report layer",
      "SP imaging local code metadata field.",
      c("SP imaging", "bld_kode", value_text),
      "medium",
      "confirmed",
      "code",
      "SP_imaging_metadata",
      "SP imaging local codes are metadata signals, not image pixels."
    ))
  }
  mk(
    "imaging_candidate_signal",
    "Imaging metadata / procedure signal",
    "Candidate imaging evidence",
    "Candidate imaging procedure or metadata signal.",
    c("imaging", column, value_text),
    "medium",
    "candidate",
    "code",
    if (grepl("^UX|^BW|^AP", value_key)) "SKS" else "local_imaging_code",
    "Candidate imaging rows require source-specific validation and do not imply image-pixel availability."
  )
}

imaging_value_is_relevant <- function(values) {
  values <- as.character(values)
  grepl(
    "PET|FDG|F-18|(^|[^A-Z])CT([^A-Z]|$)|MRI|(^|[^A-Z])MR([^A-Z]|$)|R[OØ]NT|RONT|RU THORAX|X[- ]?RAY|UX|BWGC|radioter|straale|strale|stråle|APAA4",
    values,
    ignore.case = TRUE
  )
}

imaging_safe_display_value <- function(column, value, concept_id, n, min_cell_count) {
  value <- as.character(value %||% "")
  if (!nzchar(value)) return("")
  if (imaging_date_like_column(column) || imaging_free_text_column(column)) return("")
  if (is.na(suppressWarnings(as.numeric(n))) || suppressWarnings(as.numeric(n)) < min_cell_count) return("suppressed / not shown")
  value
}

semantic_domain_keep_rows <- function(values, clinical_group) {
  values <- as.character(values)
  if (clinical_group == "Imaging") {
    return(imaging_value_is_relevant(values))
  }
  rep(TRUE, length(values))
}

microbiology_source_context <- function(source_name = "", object_name = "", evidence_file = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", evidence_file %||% "", sep = " "))
  mk <- function(layer, subgroup, meaning, caveat, terms) {
    list(layer = layer, subgroup = subgroup, meaning = meaning, caveat = caveat, terms = terms)
  }
  if (grepl("culture_resistance|resistance", key)) {
    return(mk("PERSIMUNE resistance/susceptibility", "Resistance/susceptibility", "Antibiotic susceptibility/resistance result layer from PERSIMUNE microbiology culture evidence.", "Resistance/susceptibility rows do not by themselves define resistant infection episodes.", c("PERSIMUNE microbiology resistance", "susceptibility", "antibiotic")))
  }
  if (grepl("microbiology_culture|micro_culture", key)) {
    return(mk("PERSIMUNE culture", "Culture", "PERSIMUNE culture investigation layer with culture group, organism/domain, sample material, and interpretation where available.", "Culture rows are aggregate evidence layers and require study-specific infection definitions.", c("PERSIMUNE microbiology culture", "culture", "organism", "sample material")))
  }
  if (grepl("microbiology_microscopy|microscopy", key)) {
    return(mk("PERSIMUNE microscopy", "Microscopy", "PERSIMUNE microscopy/visual microbiology examination layer.", "Microscopy rows are aggregate evidence only and free-text result examples are not emitted.", c("PERSIMUNE microbiology microscopy", "microscopy")))
  }
  if (grepl("microbiology_analysis|micro_analysis", key)) {
    return(mk("PERSIMUNE analysis", "PERSIMUNE analysis", "PERSIMUNE microbiology analysis/test layer with sample material, domain, analysis group, and result interpretation where available.", "PERSIMUNE coverage may be regional or research-specific and not nationwide.", c("PERSIMUNE microbiology analysis", "analysis", "sample material", "domain")))
  }
  if (grepl("bloddyrkning_del1|bloddyrkning_del_1", key)) return(mk("SP blood culture del1", "SP blood-culture workflow", "SP blood-culture workflow part del1.", "SP blood-culture workflow parts must be interpreted together before defining events.", c("SP blood culture del1", "blood culture")))
  if (grepl("bloddyrkning_del2|bloddyrkning_del_2", key)) return(mk("SP blood culture del2", "SP blood-culture workflow", "SP blood-culture workflow part del2.", "SP blood-culture workflow parts must be interpreted together before defining events.", c("SP blood culture del2", "blood culture")))
  if (grepl("bloddyrkning_del3|bloddyrkning_del_3", key)) return(mk("SP blood culture del3", "SP blood-culture workflow", "SP blood-culture workflow part del3 with organism, antibiotic, and sensitivity fields where aggregate-safe.", "SP blood-culture workflow parts must be interpreted together before defining events.", c("SP blood culture del3", "organism", "antibiotic", "sensitivity")))
  if (grepl("bloddyrkning_del4|bloddyrkning_del_4", key)) return(mk("SP blood culture del4", "SP blood-culture workflow", "SP blood-culture workflow part del4.", "SP blood-culture workflow parts must be interpreted together before defining events.", c("SP blood culture del4", "blood culture")))
  mk("Candidate microbiology evidence", "Candidate microbiology evidence", "Candidate microbiology aggregate evidence layer.", "Candidate microbiology rows require source-specific validation before analytic use.", c("microbiology", "infection"))
}

microbiology_column_definition <- function(source_name = "", column = "") {
  source_key <- semantic_id_from(source_name)
  col_key <- semantic_id_from(column)
  mk <- function(id, variable, subgroup, meaning, terms, confidence = "high", status = "confirmed") {
    list(concept_id = id, variable = variable, subgroup = subgroup, meaning = meaning, terms = terms, confidence = confidence, status = status)
  }
  if (col_key %in% c("samplematerial", "c_samplematerial", "c_pm_samplematerial", "material", "provemateriale", "proevemateriale", "c_samplematerialold")) {
    return(mk("microbiology_sample_material", "Microbiology sample material", "Sample material", "Microbiology sample-material field.", c("sample material", "prøvemateriale", "proevemateriale")))
  }
  if (col_key %in% c("c_domain", "domain", "organisme", "organism", "refmicroorganism", "microorganism", "microorganismidentificationtext")) {
    return(mk("microbiology_organism_domain", "Organism/domain group", "Organism/domain", "Microbiology organism/domain group field.", c("organism", "domain", "microorganism")))
  }
  if (col_key %in% c("investigationinterpretation", "c_categoricalresult_old", "c_categoricalresult", "result_class", "result", "proveresultat", "proeveresultat", "pr_veresultat", "sensitivitet_resultat")) {
    if (col_key == "sensitivitet_resultat") {
      return(mk("microbiology_susceptibility_result", "Susceptibility result", "Resistance/susceptibility", "Blood-culture susceptibility result field.", c("susceptibility result", "sensitivity result", "resistant", "susceptible")))
    }
    return(mk("microbiology_result_class", "Microbiology result class / interpretation", "Result interpretation", "Microbiology result class or interpretation field.", c("result class", "interpretation", "positive", "negative")))
  }
  if (col_key %in% c("investigationexamination", "investigationexaminationtype", "c_analysisgroup", "c_new_analysisgroup", "analysisgroup", "analysisgroup_mads", "culture_group", "analysisname", "analysisshortname", "komponentnavn", "type")) {
    return(mk("microbiology_culture_group", if (grepl("bloddyrkning", source_key)) "Blood-culture component / workflow type" else "Culture / analysis group", "Culture group", "Microbiology culture, analysis-group, component, or workflow-type field.", c("culture group", "analysis group", "BLOODCULTURE", "URINECULTURE")))
  }
  if (col_key %in% c("antibiotika", "antibiotic", "antibioticnamecoderesponsible", "antibioticnametext", "antibioticnamecodetype")) {
    return(mk("microbiology_antibiotic", "Microbiology antibiotic", "Resistance/susceptibility", "Antibiotic field in microbiology resistance/susceptibility evidence.", c("antibiotic", "antibiotika")))
  }
  if (grepl("susceptibility", col_key)) return(mk("microbiology_susceptibility_result", "Susceptibility result", "Resistance/susceptibility", "Antibiotic susceptibility/resistance result or method field.", c("susceptibility", "resistance", "sensitive")))
  if (col_key %in% c("hospital", "c_hospital", "hospital_area_name", "lab", "laboratory", "institution", "c_hospitalcode", "referringhospital", "hospital_name", "region_name")) {
    return(mk("microbiology_lab_source", "Microbiology laboratory / hospital source", "Source/lab", "Microbiology laboratory, hospital, region, or source field.", c("hospital", "lab", "source")))
  }
  if (grepl("bloddyrkning", source_key)) {
    return(mk(paste0("microbiology_", semantic_id_from(gsub("^sp_", "", source_key))), paste("Blood-culture workflow", gsub("^.*bloddyrkning_", "", source_key), "field"), "SP blood-culture workflow", "SP blood-culture workflow field with part context preserved.", c("SP blood culture", source_name, column), "medium", "candidate"))
  }
  mk("microbiology_workflow_signal", "Microbiology workflow signal", "Microbiology workflow", "Microbiology aggregate workflow field.", c("microbiology", column), "medium", "candidate")
}

microbiology_date_like_column <- function(column) {
  grepl("(^|_)(date|dato|datetime|time|tidspunkt)($|_)|_dt$|dato|tidspunkt", column, ignore.case = TRUE)
}

microbiology_free_text_column <- function(column) {
  grepl("clinicalinformation|requisitioninformationtext|commentsgrouping|resultsummary|investigationexaminationsummary|resultat_tekst|kliniske_oplysninger|microscopicresult|tekst|text|comment|summary|oplysninger", column, ignore.case = TRUE)
}

microbiology_broad_domain_value <- function(value) {
  key <- tolower(trimws(as.character(value %||% "")))
  key %in% c("virus", "bacteria", "bacterium", "fungus", "fungi", "parasites", "protozoa", "helminths", "parasites/protozoa/helminths", "other", "unclassified", "unknown", "null", "negative", "positive", "not interpreted", "not analyzed", "not analysed", "inconclusive", "sent to external lab")
}

microbiology_safe_display_value <- function(column, value, concept_id, n, min_cell_count) {
  value <- as.character(value %||% "")
  if (!nzchar(value)) return("")
  if (is.na(suppressWarnings(as.numeric(n))) || suppressWarnings(as.numeric(n)) < min_cell_count) return("suppressed / not shown")
  if (identical(concept_id, "microbiology_organism_domain") && !microbiology_broad_domain_value(value)) return("suppressed / not shown")
  value
}

pathology_source_context <- function(source_name = "", object_name = "", evidence_file = "", column = "") {
  key <- semantic_id_from(paste(source_name %||% "", object_name %||% "", evidence_file %||% "", column %||% "", sep = " "))
  mk <- function(layer, subgroup, meaning, caveat, terms) {
    list(layer = layer, subgroup = subgroup, meaning = meaning, caveat = caveat, terms = terms)
  }
  if (grepl("t_mikro|mikro", key)) {
    return(mk(
      "Microscopy / free-text availability",
      "Microscopy/free-text availability",
      "Pathology microscopy/report text availability layer.",
      "Microscopy text values are not emitted into the static atlas; show availability only.",
      c("SDS_t_mikro", "microscopy", "free text")
    ))
  }
  if (grepl("t_konk|konk|konklusion|conclusion", key)) {
    return(mk(
      "Conclusion / report-text availability",
      "Conclusion/report-text availability",
      "Pathology conclusion/report text availability layer.",
      "Conclusion text values are not emitted into the static atlas; show availability only.",
      c("SDS_t_konk", "conclusion", "report text")
    ))
  }
  if (grepl("t_tumor|tumor|tumour", key)) {
    return(mk(
      "Tumor-coded evidence",
      "Tumor-coded evidence",
      "Tumor-registry or tumor-coded pathology-related evidence.",
      "Tumor-coded evidence must remain source-scoped and not be merged silently with PATOBANK SNOMED records.",
      c("SDS_t_tumor", "tumor", "TNM", "morphology", "topography")
    ))
  }
  mk(
    "SDS/PATOBANK coded pathology",
    "Coded PATOBANK/SDS pathology",
    "Coded pathology evidence from PATOBANK/SDS pathology records.",
    "Coded pathology records are not the same as raw pathology report text.",
    c("SDS_pato", "PATOBANK", "SNOMED", "pathology")
  )
}

pathology_sds_pato_snomed_field <- function(source_name = "", column = "") {
  identical(semantic_id_from(source_name), "sds_pato") &&
    identical(semantic_id_from(column), "c_snomedkode")
}

pathology_column_definition <- function(source_name = "", object_name = "", column = "", value = "") {
  col_key <- semantic_id_from(column)
  value_text <- as.character(value %||% "")
  mk <- function(id, variable, subgroup, meaning, terms, confidence = "high", status = "confirmed",
                 value_type = "code", code_system = "local_pathology_code", caveat = "") {
    list(
      concept_id = id,
      variable = variable,
      subgroup = subgroup,
      meaning = meaning,
      terms = terms,
      confidence = confidence,
      status = status,
      value_type = value_type,
      code_system = code_system,
      caveat = caveat
    )
  }
  if (pathology_free_text_column(column)) {
    return(mk(
      "pathology_text_availability",
      "Pathology report/free-text availability",
      "Text availability",
      "Pathology microscopy, conclusion, description, or free-text availability field.",
      c("pathology text", "microscopy", "conclusion", "free text", column),
      "high",
      "confirmed",
      "free_text",
      "pathology_text",
      "Raw pathology report text is not emitted; availability only."
    ))
  }
  if (pathology_date_like_column(column)) {
    return(mk(
      "pathology_structural_date",
      "Pathology answer/report date field",
      "Structural date field",
      "Pathology report or answer date structural field.",
      c("pathology date", "d_svardato", column),
      "medium",
      "candidate",
      "date",
      "pathology_metadata",
      "Date fields are structural metadata and are not rendered as categorical bars."
    ))
  }
  if (col_key %in% c("c_snomedkode", "snomed", "snomed_code", "snomedkode") ||
      grepl("^[A-Z][0-9]{4,}", value_text, ignore.case = TRUE)) {
    return(mk(
      "pathology_snomed_code",
      "SNOMED pathology code",
      "SNOMED-coded pathology",
      "SNOMED-coded pathology evidence.",
      c("SNOMED", "pathology code", value_text, column),
      "high",
      "confirmed",
      "code",
      "SNOMED",
      "SNOMED labels may require a separate code dictionary for clinical interpretation."
    ))
  }
  if (col_key %in% c("c_mattype", "materiale", "material", "specimen", "specimen_type", "provemateriale", "proevemateriale", "k_matnr")) {
    return(mk(
      "pathology_specimen_material",
      "Pathology specimen / material type",
      "Specimen/material",
      "Pathology specimen, material, or sample-type field.",
      c("pathology specimen", "material", "c_mattype", column),
      "high",
      "confirmed",
      "categorical",
      "pathology_material_code",
      "Specimen/material codes require source-specific interpretation."
    ))
  }
  if (col_key %in% c("k_inst", "institution", "lab", "laboratory", "department", "hospital")) {
    return(mk(
      "pathology_institution",
      "Pathology institution / lab source",
      "Source/lab",
      "Pathology institution, department, laboratory, or source field.",
      c("pathology institution", "lab", "k_inst", column),
      "high",
      "confirmed",
      "categorical",
      "pathology_source_code",
      "Institution/lab source is coverage context and not a clinical phenotype."
    ))
  }
  if (grepl("tnm|tumor|tumour|grade|morphology|topography|laterality|extent|c_aa|c_diag|c_morf|c_topo", col_key, ignore.case = TRUE) ||
      grepl("t_tumor|tumor|tumour", semantic_id_from(paste(source_name, object_name)), ignore.case = TRUE)) {
    return(mk(
      "pathology_tumor_coded_evidence",
      "Tumor-coded pathology evidence",
      "Tumor-coded evidence",
      "Tumor-registry or tumor-coded pathology-related field.",
      c("tumor", "TNM", "morphology", "topography", "grade", column),
      "medium",
      "confirmed",
      "code",
      "tumor_code",
      "Tumor-coded evidence is source-scoped and not automatically equivalent to PATOBANK SNOMED records."
    ))
  }
  mk(
    "pathology_candidate_signal",
    "Pathology coded evidence",
    "Candidate pathology evidence",
    "Candidate pathology coded evidence.",
    c("pathology", "PATOBANK", column, value_text),
    "medium",
    "candidate",
    "code",
    "local_pathology_code",
    "Candidate pathology rows require source-specific validation before analytic use."
  )
}

pathology_date_like_column <- function(column) {
  grepl("date|dato|datetime|tidspunkt|svardato|d_svar|_dt$|time", column, ignore.case = TRUE)
}

pathology_free_text_column <- function(column) {
  grepl("v_fritekst|fritekst|free_text|mikro_text|konklusion|conclusion|description|beskrivelse|tekst|text", column, ignore.case = TRUE)
}

pathology_safe_display_value <- function(column, value, concept_id, n, min_cell_count) {
  value <- as.character(value %||% "")
  if (!nzchar(value)) return("")
  if (pathology_date_like_column(column)) return("")
  if (pathology_free_text_column(column)) return("free-text field present; values not emitted")
  if (is.na(suppressWarnings(as.numeric(n))) || suppressWarnings(as.numeric(n)) < min_cell_count) return("suppressed / not shown")
  value
}

semantic_domain_variable <- function(clinical_group, code, column) {
  text <- paste(code, column)
  if (clinical_group == "Imaging") {
    if (grepl("PET|FDG", text, ignore.case = TRUE)) return("PET/CT imaging signal")
    if (grepl("\\bCT\\b|UXC", text, ignore.case = TRUE)) return("CT imaging signal")
    if (grepl("MR|MRI", text, ignore.case = TRUE)) return("MRI imaging signal")
    if (grepl("BWGC|radioter", text, ignore.case = TRUE)) return("Radiotherapy signal")
    return("Imaging event / metadata signal")
  }
  if (clinical_group == "Microbiology") {
    if (grepl("resist|suscept|antibiot|foelsom|resistent", text, ignore.case = TRUE)) return("Antibiotic susceptibility / resistance")
    if (grepl("culture|dyrkning", text, ignore.case = TRUE)) return("Culture result")
    if (grepl("material|sample", text, ignore.case = TRUE)) return("Sample material")
    return("Microbiology workflow signal")
  }
  if (clinical_group == "Pathology") {
    if (grepl("snomed|^[MTS][0-9]", text, ignore.case = TRUE)) return("SNOMED pathology code")
    return("Pathology specimen or diagnosis signal")
  }
  if (clinical_group == "Biobank") return("Biobank sample availability")
  if (clinical_group == "Outcomes") return("Cause of death / mortality signal")
  paste(clinical_group, "signal")
}

semantic_domain_meaning <- function(clinical_group, code, column) {
  paste(semantic_domain_variable(clinical_group, code, column), "observed in aggregate cartography output.")
}

semantic_domain_code_system <- function(clinical_group, code, column) {
  if (clinical_group == "Pathology") return("SNOMED")
  if (clinical_group == "Imaging" && grepl("^UX|^BW", code, ignore.case = TRUE)) return("SKS")
  if (clinical_group == "Treatment" && grepl("^[A-Z][0-9]{2}", code)) return("ATC")
  if (clinical_group == "Microbiology") return("local_microbiology")
  if (clinical_group == "Biobank") return("local_biobank")
  if (clinical_group == "Outcomes") return("ICD10/cause_of_death")
  "local_code"
}

semantic_domain_caveat <- function(clinical_group) {
  switch(
    clinical_group,
    Imaging = "Imaging codes indicate procedure or metadata/report-layer events, not image pixels.",
    Microbiology = "Microbiology mappings are aggregate workflow/code signals; no raw result text is exposed.",
    Pathology = "Pathology free text is not emitted; only aggregate code/specimen signals are shown.",
    Biobank = "Biobank rows indicate aggregate sample availability, not specimen-level raw records.",
    Outcomes = "Cause-of-death coding requires careful competing-risk and lag interpretation.",
    "Code-level evidence; clinical interpretation may require source-specific validation."
  )
}

semantic_panel_links_for_dictionary <- function(dictionary) {
  if (!is.data.frame(dictionary) || !nrow(dictionary)) return(empty_semantic_panel_links())
  rows <- lapply(seq_len(nrow(dictionary)), function(i) {
    panel <- panel_for_semantic_row(dictionary[i, , drop = FALSE])
    semantic_panel_link_row(
      semantic_id = dictionary$semantic_id[[i]],
      clinical_concept_id = dictionary$clinical_concept_id[[i]],
      panel_id = panel$id,
      panel_section = panel$section,
      relationship = "raw_lineage",
      sort_order = i
    )
  })
  bind_rows_base(rows)
}

panel_for_semantic_row <- function(row) {
  group <- row$clinical_group[[1]] %||% ""
  source <- row$source_name[[1]] %||% ""
  if (grepl("DaMyDa", source, ignore.case = TRUE)) return(list(id = "reg_damyda", section = "Disease Registries"))
  if (grepl("LYFO", source, ignore.case = TRUE)) return(list(id = "reg_lyfo", section = "Disease Registries"))
  if (grepl("CLL", source, ignore.case = TRUE)) return(list(id = "reg_cll", section = "Disease Registries"))
  if (group == "Lifestyle") return(list(id = "clinical_social_history", section = "Clinical Data"))
  if (group == "Vitals") return(list(id = "clinical_vitals", section = "Clinical Data"))
  if (group == "Laboratory") return(list(id = "laboratory_npu", section = "Laboratory"))
  if (group == "Treatment") return(list(id = "treatment_codes", section = "Treatment"))
  if (group == "Imaging") return(list(id = "clinical_imaging", section = "Clinical Data"))
  if (group == "Microbiology") return(list(id = "clinical_microbiology", section = "Clinical Data"))
  if (group == "Pathology") return(list(id = "clinical_pathology", section = "Clinical Data"))
  if (group == "Biobank") return(list(id = "laboratory_biobank", section = "Laboratory"))
  if (group == "Outcomes") return(list(id = "clinical_outcomes", section = "Clinical Data"))
  list(id = "data_dictionary", section = "Data Dictionary")
}

semantic_dedupe_dictionary <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(empty_semantic_data_dictionary())
  x <- x[!vapply(x$raw_column %||% rep("", nrow(x)), is_sensitive_column, logical(1)), , drop = FALSE]
  key <- paste(x$semantic_id, x$source_name, x$raw_column, x$raw_descriptor, x$raw_code, x$raw_value, x$mapping_status, sep = "\r")
  x[!duplicated(key), , drop = FALSE]
}

semantic_dedupe_value_map <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(empty_semantic_value_map())
  x <- x[!vapply(x$raw_column %||% rep("", nrow(x)), is_sensitive_column, logical(1)), , drop = FALSE]
  key <- paste(x$semantic_id, x$raw_column, x$raw_value, sep = "\r")
  x[!duplicated(key), , drop = FALSE]
}

semantic_dedupe_code_map <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(empty_semantic_code_map())
  key <- paste(x$source_name, x$code_system, x$code, x$clinical_variable, sep = "\r")
  x[!duplicated(key), , drop = FALSE]
}

semantic_dedupe_panel_links <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(empty_semantic_panel_links())
  key <- paste(x$semantic_id, x$panel_id, sep = "\r")
  x[!duplicated(key), , drop = FALSE]
}

semantic_summary <- function(dictionary, value_map, code_map, panel_links) {
  if (!is.data.frame(dictionary)) dictionary <- empty_semantic_data_dictionary()
  data.frame(
    metric = c("semantic_variables", "value_mappings", "code_mappings", "panel_links", "confirmed_rows", "candidate_rows"),
    label = c("Semantic rows", "Value mappings", "Code mappings", "Panel links", "Confirmed rows", "Candidate rows"),
    value = c(
      nrow(dictionary),
      if (is.data.frame(value_map)) nrow(value_map) else 0L,
      if (is.data.frame(code_map)) nrow(code_map) else 0L,
      if (is.data.frame(panel_links)) nrow(panel_links) else 0L,
      sum(dictionary$mapping_status == "confirmed", na.rm = TRUE),
      sum(dictionary$mapping_status %in% c("candidate", "inferred"), na.rm = TRUE)
    ),
    stringsAsFactors = FALSE
  )
}

normalize_semantic_source_names <- function(outputs) {
  outputs$dictionary <- normalize_semantic_source_frame(outputs$dictionary)
  outputs$value_map <- normalize_semantic_source_frame(outputs$value_map)
  outputs$code_map <- normalize_semantic_source_frame(outputs$code_map)
  outputs
}

normalize_semantic_source_frame <- function(x) {
  if (!is.data.frame(x) || !nrow(x) || !"source_name" %in% names(x)) return(x)
  evidence <- if ("evidence_file" %in% names(x)) x$evidence_file else rep("", nrow(x))
  object <- if ("object_name" %in% names(x)) x$object_name else rep("", nrow(x))
  for (i in seq_len(nrow(x))) {
    source <- as.character(x$source_name[[i]] %||% "")
    recovered <- semantic_recover_source_name(source, evidence[[i]] %||% "", object[[i]] %||% "")
    if (nzchar(recovered)) {
      x$source_name[[i]] <- recovered
      if ("object_name" %in% names(x) && semantic_source_looks_like_evidence_file(x$object_name[[i]] %||% "")) {
        x$object_name[[i]] <- recovered
      }
    }
  }
  x
}

semantic_source_looks_like_evidence_file <- function(x) {
  x <- as.character(x %||% "")
  grepl("[.](tsv|csv)$", x, ignore.case = TRUE) ||
    grepl("^cartography_|_value_counts$|_value_counts[.]|_top_|_summary[.]", x, ignore.case = TRUE)
}

semantic_recover_source_name <- function(source_name, evidence_file = "", object_name = "") {
  source_name <- as.character(source_name %||% "")
  evidence_file <- as.character(evidence_file %||% "")
  object_name <- as.character(object_name %||% "")
  if (nzchar(source_name) && !semantic_source_looks_like_evidence_file(source_name)) {
    return(source_name)
  }
  key <- tolower(paste(source_name, object_name, evidence_file, sep = " "))
  patterns <- list(
    "SP_Social_Hx" = c("social_hx", "socialhx"),
    "SP_VitaleVaerdier" = c("vitalevaerdier", "vital"),
    "RKKP_DaMyDa" = c("damyda"),
    "RKKP_LYFO" = c("lyfo"),
    "RKKP_CLL" = c("rkkp_cll", "cll_treat", "ibrutinib"),
    "SP_AlleProvesvar" = c("alleproevesvar", "alleprovesvar"),
    "SDS_lab_forsker" = c("sds_lab_forsker"),
    "LABKA" = c("labka"),
    "PERSIMUNE_biochemistry" = c("persimune_biochem", "persimune_biochemistry"),
    "SP_BilleddiagnostikeUndersoegelser_Del1" = c("billeddiagnostik_del1", "billeddiagnostikeundersoegelser_del1"),
    "SP_BilleddiagnostikeUndersoegelser_Del2" = c("billeddiagnostik_del2", "billeddiagnostikeundersoegelser_del2"),
    "SDS_t_sksube" = c("sds_t_sksube"),
    "SDS_procedurer_andre" = c("sds_procedure_andre", "procedurer_andre"),
    "SDS_procedurer_kirurgi" = c("sds_procedure_kirurgi", "procedurer_kirurgi"),
    "SP_Bloddyrkning_Del1" = c("bloddyrkning_del1"),
    "SP_Bloddyrkning_Del2" = c("bloddyrkning_del2"),
    "SP_Bloddyrkning_Del3" = c("bloddyrkning_del3"),
    "SP_Bloddyrkning_Del4" = c("bloddyrkning_del4"),
    "PERSIMUNE_microbiology_analysis" = c("microbiology_analysis", "micro_analysis"),
    "PERSIMUNE_microbiology_culture_resistance" = c("culture_resistance"),
    "PERSIMUNE_microbiology_culture" = c("microbiology_culture", "micro_culture"),
    "PERSIMUNE_microbiology_microscopy" = c("microbiology_microscopy"),
    "SP_AdministreretMedicin" = c("administreret_medicin"),
    "SP_OrdineretMedicin" = c("ordineretmedicin", "rx_med"),
    "SP_Behandlingsplaner_Del1" = c("behandlingsplaner_del1"),
    "SP_Behandlingsplaner_Del2" = c("behandlingsplaner_del2"),
    "SP_ADT_haendelser" = c("adt_haendelser"),
    "SP_Journalnotater_Del1" = c("journalnotater_del1"),
    "SP_Journalnotater_Del2" = c("journalnotater_del2"),
    "SDS_epikur" = c("epikur"),
    "SDS_ekokur" = c("ekokur"),
    "SMR_medicine" = c("smr_atc"),
    "SDS_pato" = c("sds_pato", "pato_top_snomed", "pato_value"),
    "SDS_t_mikro" = c("sds_t_mikro"),
    "SDS_t_konk" = c("sds_t_konk"),
    "SDS_t_tumor" = c("sds_t_tumor", "tumor_value"),
    "SDS_t_dodsaarsag_2" = c("dodsaarsag_2"),
    "LAB_biobank_samples" = c("biobank_samples")
  )
  for (nm in names(patterns)) {
    if (any(vapply(patterns[[nm]], function(pattern) grepl(pattern, key, fixed = TRUE), logical(1)))) {
      return(nm)
    }
  }
  if (nzchar(object_name) && !semantic_source_looks_like_evidence_file(object_name)) return(object_name)
  source_name
}
