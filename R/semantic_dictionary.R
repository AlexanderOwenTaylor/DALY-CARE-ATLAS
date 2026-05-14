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
  dictionary <- semantic_dictionary_from_code_map(code_map, "Laboratory", "NPU biochemistry", "code_table")
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = code_map,
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
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
  dictionary <- semantic_dictionary_from_code_map(code_map, "Treatment", "Medication and procedure codes", "code_table")
  list(
    dictionary = dictionary,
    value_map = empty_semantic_value_map(),
    code_map = code_map,
    panel_links = semantic_panel_links_for_dictionary(dictionary)
  )
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
    c("cartography_pato_top_snomed.tsv", "cartography_sds_pato_value_counts.tsv", "cartography_part4_sds_t_mikro_value_counts.tsv"),
    "Pathology",
    "SNOMED pathology and specimen signals",
    c("SNOMED", "pathology", "pato", "specimen", "biopsy", "morphology", "microscopy"),
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
    def <- semantic_concept_definition(hits$concept[[i]], column, hits$source_name[[i]])
    semantic_row(
      semantic_id = semantic_id_from(c(hits$source_name[[i]], column, hits$concept[[i]])),
      clinical_concept_id = def$concept_id,
      clinical_variable = def$variable,
      clinical_group = def$group,
      clinical_subgroup = def$subgroup,
      semantic_meaning = paste("Column-name cartography hit for", def$variable, "in", hits$source_name[[i]]),
      source_name = hits$source_name[[i]],
      object_name = hits$object_name[[i]] %||% hits$source_name[[i]],
      raw_column = column,
      code_system = def$code_system,
      value_type = def$value_type,
      data_shape = "wide_table",
      source_level = source_level_for_source(hits$source_name[[i]]),
      geography = geography_for_source(hits$source_name[[i]]),
      evidence_file = "cartography_column_name_hits.tsv",
      evidence_filter = paste0("concept=", hits$concept[[i]], "; matched_column=", column),
      mapping_confidence = "medium",
      mapping_status = "inferred",
      privacy_note = "aggregate_only",
      clinical_caveat = hits$notes[[i]] %||% "Column-name hit needs clinical validation before analytic use.",
      search_terms = semantic_terms(c(hits$concept[[i]], column, hits$source_name[[i]], def$terms))
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

registry_column_definition <- function(column, registry) {
  key <- semantic_id_from(column)
  mk <- function(concept_id, variable, subgroup, meaning, value_type = "categorical", confidence = "medium", status = "inferred", terms = character(), caveat = "Registry field mapping is based on cartography evidence and should be checked against the registry data dictionary.") {
    list(concept_id = concept_id, variable = variable, subgroup = subgroup, meaning = meaning, value_type = value_type, confidence = confidence, status = status, terms = terms, caveat = caveat)
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
      if (semantic_identifier_like_column(column)) next
      n <- semantic_suppress_count(x[[count_col]][[i]], min_cell_count)
      variable <- semantic_domain_variable(clinical_group, code, column)
      row_source <- semantic_vector_value(source_name, i)
      row_object <- semantic_vector_value(object_name, i, row_source)
      semantic_id <- semantic_id_from(c(clinical_group, row_source, column, code))
      dict_rows[[length(dict_rows) + 1L]] <- semantic_row(
        semantic_id = semantic_id,
        clinical_concept_id = semantic_id_from(c(clinical_group, variable)),
        clinical_variable = variable,
        clinical_group = clinical_group,
        clinical_subgroup = subgroup,
        semantic_meaning = semantic_domain_meaning(clinical_group, code, column),
        source_name = row_source,
        object_name = row_object,
        raw_column = column,
        raw_descriptor = if (clinical_group %in% c("Imaging", "Microbiology", "Biobank")) code else "",
        raw_code = if (clinical_group %in% c("Treatment", "Pathology", "Imaging") || grepl("^[A-Z0-9]{3,}", code)) code else "",
        raw_value = if (clinical_group %in% c("Microbiology", "Biobank", "Outcomes")) code else "",
        code_system = semantic_domain_code_system(clinical_group, code, column),
        value_type = if (grepl("text|note|beskrivelse", column, ignore.case = TRUE)) "free_text" else "code",
        data_shape = "code_table",
        source_level = source_level_for_source(row_source),
        geography = geography_for_source(row_source),
        n_rows = n,
        evidence_file = file,
        evidence_filter = paste0(column, "=", code),
        mapping_confidence = if (clinical_group %in% c("Microbiology", "Biobank")) "medium" else "high",
        mapping_status = if (clinical_group %in% c("Microbiology", "Biobank")) "candidate" else "inferred",
        privacy_note = if (grepl("text|note|beskrivelse", column, ignore.case = TRUE)) "free_text_not_exposed" else "aggregate_only",
        clinical_caveat = semantic_domain_caveat(clinical_group),
        search_terms = semantic_terms(c(terms, code, column, row_source))
      )
      if (nzchar(code)) {
        code_rows[[length(code_rows) + 1L]] <- semantic_code_row(
          semantic_id = semantic_id,
          clinical_concept_id = semantic_id_from(c(clinical_group, variable)),
          clinical_variable = variable,
          clinical_group = clinical_group,
          source_name = row_source,
          object_name = row_object,
          code_system = semantic_domain_code_system(clinical_group, code, column),
          code = code,
          code_name = variable,
          panel = subgroup,
          n_rows = n,
          evidence_file = file,
          mapping_confidence = "medium",
          notes = semantic_domain_caveat(clinical_group)
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
  key <- semantic_id_from(c(code, name))
  name_l <- tolower(name %||% "")
  if (grepl("haemoglobin|hemoglobin", name_l) || code == "NPU02319") return("haemoglobin")
  if (grepl("creatinine", name_l) || code == "NPU02593") return("creatinine")
  if (grepl("egfr|ckd", name_l) || code == "DNK35302") return("egfr")
  if (grepl("leukocyte|leucocyte", name_l) || code == "NPU19748") return("leukocytes")
  if (grepl("\\bldh\\b|lactate dehydrogenase", name_l)) return("ldh")
  if (grepl("albumin", name_l)) return("albumin")
  if (grepl("c-reactive|crp", name_l)) return("crp")
  if (grepl("immunoglobulin|\\bigg\\b|\\biga\\b|\\bigm\\b", name_l)) return("immunoglobulin")
  if (grepl("m-component|m spike|paraprotein", name_l)) return("m_component")
  semantic_id_from(c("lab", key))
}

lab_variable_name <- function(code, name) {
  concept <- lab_concept_id(code, name)
  labels <- c(
    haemoglobin = "Haemoglobin",
    creatinine = "Creatinine",
    egfr = "eGFR",
    leukocytes = "Leukocytes",
    ldh = "LDH",
    albumin = "Albumin",
    crp = "CRP",
    immunoglobulin = "Immunoglobulin",
    m_component = "M-component / paraprotein"
  )
  if (concept %in% names(labels)) labels[[concept]] else first_nonblank(name, code)
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

semantic_domain_keep_rows <- function(values, clinical_group) {
  values <- as.character(values)
  if (clinical_group == "Imaging") {
    return(grepl("PET|FDG|\\bCT\\b|MR|MRI|R[Oo]nt|RU |UX|BWGC|radioter", values, ignore.case = TRUE))
  }
  rep(TRUE, length(values))
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
