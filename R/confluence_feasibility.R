confluence_empty_summary <- function() {
  empty_df(
    metric = character(),
    label = character(),
    value = character(),
    status = character(),
    count_kind = character(),
    evidence_confidence = character(),
    notes = character()
  )
}

confluence_empty_disease_state_counts <- function() {
  empty_df(
    entity_id = character(),
    entity_label = character(),
    disease_family = character(),
    danish_sks_code = character(),
    icd10_code = character(),
    diagnosis_label = character(),
    count_display = character(),
    n_records = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    evidence_confidence = character(),
    source_table = character(),
    source_column = character(),
    evidence_source = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_overlap_counts <- function() {
  empty_df(
    overlap_id = character(),
    overlap_label = character(),
    left_state = character(),
    right_state = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    feasibility_status = character(),
    query_status = character(),
    notes = character()
  )
}

confluence_empty_overlap_timing <- function() {
  empty_df(
    timing_id = character(),
    timing_label = character(),
    count_display = character(),
    n_people = numeric(),
    count_kind = character(),
    evidence_status = character(),
    acceptance_status = character(),
    query_status = character(),
    notes = character()
  )
}

confluence_empty_infection_outcome_readiness <- function() {
  empty_df(
    outcome_id = character(),
    outcome_label = character(),
    source_layer = character(),
    source_signal = character(),
    readiness_status = character(),
    evidence_status = character(),
    count_kind = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_treatment_modifier_readiness <- function() {
  empty_df(
    modifier_id = character(),
    modifier_label = character(),
    source_layer = character(),
    source_signal = character(),
    readiness_status = character(),
    evidence_status = character(),
    count_kind = character(),
    validation_needed = character(),
    notes = character()
  )
}

confluence_empty_estimands <- function() {
  empty_df(
    estimand_id = character(),
    title = character(),
    population = character(),
    exposure_condition = character(),
    outcome_variable = character(),
    intercurrent_events = character(),
    summary_measure = character(),
    plain_language = character(),
    feasibility_status = character()
  )
}

confluence_empty_validation_checklist <- function() {
  empty_df(
    entity_id = character(),
    entity_label = character(),
    validation_step = character(),
    source_hint = character(),
    status = character(),
    notes = character()
  )
}

confluence_empty_bias_warnings <- function() {
  empty_df(
    bias_id = character(),
    bias_label = character(),
    why_it_matters = character(),
    mitigation = character(),
    severity = character()
  )
}

confluence_empty_recommended_next_actions <- function() {
  empty_df(
    action_id = character(),
    action_label = character(),
    owner_role = character(),
    priority = character(),
    status = character(),
    notes = character()
  )
}

confluence_empty_payload <- function() {
  list(
    summary = confluence_empty_summary(),
    disease_state_counts = confluence_empty_disease_state_counts(),
    overlap_counts = confluence_empty_overlap_counts(),
    overlap_timing = confluence_empty_overlap_timing(),
    infection_outcome_readiness = confluence_empty_infection_outcome_readiness(),
    treatment_modifier_readiness = confluence_empty_treatment_modifier_readiness(),
    estimands = confluence_empty_estimands(),
    validation_checklist = confluence_empty_validation_checklist(),
    bias_warnings = confluence_empty_bias_warnings(),
    recommended_next_actions = confluence_empty_recommended_next_actions()
  )
}

confluence_norm_code <- function(x) {
  toupper(gsub("[^A-Z0-9]", "", as.character(x %||% "")))
}

confluence_norm_text <- function(x) {
  x <- tolower(as.character(x %||% ""))
  x <- gsub("\u00e6", "ae", x, fixed = TRUE)
  x <- gsub("\u00f8", "oe", x, fixed = TRUE)
  x <- gsub("\u00e5", "aa", x, fixed = TRUE)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT", sub = "")
  x <- gsub("[^a-z0-9]+", " ", x)
  trimws(gsub("\\s+", " ", x))
}

confluence_disease_state_specs <- function() {
  data.frame(
    entity_id = c("cll_candidate", "mbl_candidate", "richter_candidate", "mgus_candidate", "smm_candidate", "mm_candidate", "any_pcd_candidate"),
    entity_label = c("CLL candidate", "MBL coded candidate", "Richter candidate", "MGUS coded candidate", "SMM candidate", "MM candidate", "Any plasma-cell disorder candidate"),
    disease_family = c("CLL/MBL/Richter", "CLL/MBL/Richter", "CLL/MBL/Richter", "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder", "Plasma-cell disorder"),
    danish_sks_code = c("DC911", "DD479B", "DC911B", "DD472", "", "DC900", ""),
    icd10_code = c("C91.1", "D47.9B", "C91.1B", "D47.2", "", "C90.0", ""),
    diagnosis_label = c(
      "Chronic lymphocytic leukemia",
      "Monoklonal B-celle lymfocytose / MBL",
      "Richter transformation",
      "Monoclonal gammopathy of undetermined significance / MGUS",
      "Smouldering multiple myeloma / SMM",
      "Multiple myeloma",
      "MGUS/SMM/MM or related plasma-cell disorder"
    ),
    validation_needed = c(
      "Confirm CLL registry or repeated diagnosis support; derive first qualifying state date.",
      "Treat DD479B / D47.9B as coded MBL only; deduplicate persons, exclude prior/concurrent CLL where appropriate, and seek flow-cytometry/lab support.",
      "Validate relation to CLL course and timing before overlap classification.",
      "Treat DD472 / D47.2 as coded MGUS only; seek M-protein/FLC/immunoglobulin support and exclude active MM at or before MGUS index for strict definitions.",
      "Locate and validate SMM-specific registry, diagnosis, or laboratory criteria before use.",
      "Confirm DaMyDa and/or DC900 / C90.0 support plus staging/treatment evidence where available.",
      "Define source hierarchy across MGUS, SMM, MM, plasmacytoma, plasma-cell leukemia, and AL amyloidosis before grouping."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_reference_diagnosis_counts <- function(project_root = ".") {
  path <- file.path(project_root, "config", "cartography-reference", "files", "cartography_t_dalycare_diagnoses_value_counts.tsv")
  if (!file.exists(path)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  ref <- tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
  if (!is.data.frame(ref) || !nrow(ref) || !"value" %in% names(ref)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(ref$value),
    n_records = suppressWarnings(as.numeric(ref$n_rows %||% ref$n %||% NA_real_)),
    source_table = as.character(ref$object_name %||% ref$source_name %||% "t_dalycare_diagnoses"),
    source_column = as.character(ref$column_name %||% "diagnosis_code"),
    evidence_source = "checked-in cartography-reference rows",
    stringsAsFactors = FALSE
  )
}

confluence_current_diagnosis_counts <- function(column_top_values = NULL) {
  if (!is.data.frame(column_top_values) || !nrow(column_top_values) || !"value" %in% names(column_top_values)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  code <- confluence_norm_code(column_top_values$value)
  table_name <- as.character(column_top_values$table_name %||% "")
  column_name <- as.character(column_top_values$column_name %||% "")
  likely_diagnosis <- grepl("diag|diagnos|icd|sks|tumor|tumour", paste(table_name, column_name), ignore.case = TRUE)
  rows <- column_top_values[likely_diagnosis & nzchar(code), , drop = FALSE]
  if (!nrow(rows)) {
    return(empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character()))
  }
  data.frame(
    code = confluence_norm_code(rows$value),
    n_records = suppressWarnings(as.numeric(rows$n %||% rows$n_rows %||% NA_real_)),
    source_table = as.character(rows$table_name %||% ""),
    source_column = as.character(rows$column_name %||% ""),
    evidence_source = "current-run profiled aggregate rows",
    stringsAsFactors = FALSE
  )
}

confluence_best_count_for_code <- function(code, current_counts, reference_counts) {
  norm <- confluence_norm_code(code)
  current <- current_counts[current_counts$code == norm & !is.na(current_counts$n_records), , drop = FALSE]
  if (nrow(current)) {
    current <- current[order(-current$n_records), , drop = FALSE][1, , drop = FALSE]
    return(current)
  }
  reference <- reference_counts[reference_counts$code == norm & !is.na(reference_counts$n_records), , drop = FALSE]
  if (nrow(reference)) {
    reference <- reference[order(-reference$n_records), , drop = FALSE][1, , drop = FALSE]
    return(reference)
  }
  empty_df(code = character(), n_records = numeric(), source_table = character(), source_column = character(), evidence_source = character())
}

confluence_disease_state_counts <- function(project_root = ".", column_top_values = NULL) {
  specs <- confluence_disease_state_specs()
  current_counts <- confluence_current_diagnosis_counts(column_top_values)
  reference_counts <- confluence_reference_diagnosis_counts(project_root)
  rows <- lapply(seq_len(nrow(specs)), function(i) {
    spec <- specs[i, , drop = FALSE]
    if (!nzchar(spec$danish_sks_code[[1]])) {
      return(data.frame(
        entity_id = spec$entity_id,
        entity_label = spec$entity_label,
        disease_family = spec$disease_family,
        danish_sks_code = spec$danish_sks_code,
        icd10_code = spec$icd10_code,
        diagnosis_label = spec$diagnosis_label,
        count_display = "query executable not run",
        n_records = NA_real_,
        count_kind = "not run",
        evidence_status = "source validation required",
        acceptance_status = "not accepted aggregate",
        evidence_confidence = "candidate mapping",
        source_table = "",
        source_column = "",
        evidence_source = "scaffold-only row",
        validation_needed = spec$validation_needed,
        notes = "No accepted aggregate person count exists in this scaffold-first CONFLUENCE implementation.",
        stringsAsFactors = FALSE
      ))
    }
    hit <- confluence_best_count_for_code(spec$danish_sks_code[[1]], current_counts, reference_counts)
    has_count <- nrow(hit) && !is.na(hit$n_records[[1]])
    data.frame(
      entity_id = spec$entity_id,
      entity_label = spec$entity_label,
      disease_family = spec$disease_family,
      danish_sks_code = spec$danish_sks_code,
      icd10_code = spec$icd10_code,
      diagnosis_label = spec$diagnosis_label,
      count_display = if (has_count) format(hit$n_records[[1]], big.mark = ",", scientific = FALSE, trim = TRUE) else "not available in current aggregate output",
      n_records = if (has_count) hit$n_records[[1]] else NA_real_,
      count_kind = "diagnosis-atlas records",
      evidence_status = "coded candidate cohort",
      acceptance_status = "not accepted person denominator",
      evidence_confidence = if (has_count && grepl("current-run", hit$evidence_source[[1]])) "profiled aggregate" else "fallback/reference",
      source_table = if (has_count) hit$source_table[[1]] else "",
      source_column = if (has_count) hit$source_column[[1]] else "",
      evidence_source = if (has_count) hit$evidence_source[[1]] else "no exact diagnosis-code top-value row found",
      validation_needed = spec$validation_needed,
      notes = "Evidence anchor only: diagnosis-atlas records are not validated persons and not a disease-state denominator.",
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_disease_state_counts() else out
}

confluence_overlap_counts <- function() {
  rows <- data.frame(
    overlap_id = c("cll_mgus", "cll_smm_mm", "cll_any_pcd", "mbl_mgus", "mbl_smm_mm", "mbl_any_pcd", "cll_mbl_pcd"),
    overlap_label = c(
      "CLL \u2229 MGUS",
      "CLL \u2229 SMM/MM",
      "CLL \u2229 any PCD",
      "MBL \u2229 MGUS",
      "MBL \u2229 SMM/MM",
      "MBL \u2229 any PCD",
      "CLL/MBL \u2229 MGUS/SMM/MM"
    ),
    left_state = c("CLL", "CLL", "CLL", "MBL", "MBL", "MBL", "CLL/MBL"),
    right_state = c("MGUS", "SMM/MM", "any plasma-cell disorder", "MGUS", "SMM/MM", "any plasma-cell disorder", "MGUS/SMM/MM"),
    stringsAsFactors = FALSE
  )
  rows$count_display <- "query executable not run"
  rows$n_people <- NA_real_
  rows$count_kind <- "not run"
  rows$evidence_status <- "query executable not run"
  rows$acceptance_status <- "not accepted aggregate"
  rows$feasibility_status <- "source validation required"
  rows$query_status <- "query executable not run"
  rows$notes <- "Scaffold-first row only. Do not label as accepted unless a future aggregate query returns acceptance_status == accepted."
  rows
}

confluence_overlap_timing <- function() {
  rows <- data.frame(
    timing_id = c("cll_mbl_first", "pcd_first", "same_day_or_same_year", "unknown_timing"),
    timing_label = c("CLL/MBL first", "Plasma-cell disorder first", "same-day/same-year", "unknown timing"),
    stringsAsFactors = FALSE
  )
  rows$count_display <- "query executable not run"
  rows$n_people <- NA_real_
  rows$count_kind <- "not run"
  rows$evidence_status <- "query executable not run"
  rows$acceptance_status <- "not accepted aggregate"
  rows$query_status <- "query executable not run"
  rows$notes <- "Overlap timing must be defined from first qualifying disease-state dates; no accepted aggregate timing output exists yet."
  rows
}

confluence_signal_present <- function(pattern, ...) {
  frames <- list(...)
  text_blob <- paste(unlist(lapply(frames, function(x) {
    if (!is.data.frame(x) || !nrow(x)) return(character())
    as.character(unlist(x, use.names = FALSE))
  }), use.names = FALSE), collapse = " ")
  grepl(pattern, confluence_norm_text(text_blob), perl = TRUE)
}

confluence_readiness_row <- function(id, label, source_layer, source_signal, present, validation_needed, notes = "") {
  data.frame(
    outcome_id = id,
    outcome_label = label,
    source_layer = source_layer,
    source_signal = source_signal,
    readiness_status = if (isTRUE(present)) "source evidence present; validation required" else "source validation required",
    evidence_status = if (isTRUE(present)) "profiled aggregate" else "query executable not run",
    count_kind = "source-readiness signal, not outcome count",
    validation_needed = validation_needed,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

confluence_infection_outcome_readiness <- function(sources = NULL, panel_raw_fields = NULL, panel_distributions = NULL, panels = NULL) {
  panel_text <- bind_rows_base(Filter(is.data.frame, panels %||% list()))
  rows <- list(
    confluence_readiness_row("infection_hospitalization", "Infection-related hospitalization", "SDS/LPR admissions and diagnosis layers", "infection diagnosis/contact/admission evidence", confluence_signal_present("infection|infektion|admission|kontakt|lpr|diagnos", sources, panel_raw_fields, panel_distributions, panel_text), "Define infection diagnosis code families, admission windows, and recurrent-episode gap rules."),
    confluence_readiness_row("recurrent_infection", "Recurrent serious infection", "Admissions/outcomes", "episode counting from hospital contacts", confluence_signal_present("infection|infektion|admission|kontakt|episode|recurrent", sources, panel_raw_fields, panel_distributions, panel_text), "Validate episode-splitting rules and person-time denominators."),
    confluence_readiness_row("microbiology_confirmed", "Microbiology-confirmed infection", "Laboratory & Diagnostics / MiBa / PERSIMUNE", "microbiology culture/PCR/analysis evidence", confluence_signal_present("micro|miba|persimune|culture|dyrkning|pcr", sources, panel_raw_fields, panel_distributions, panel_text), "Classify microbiology fields by organism, specimen, source, agent, and result role before analysis."),
    confluence_readiness_row("bloodstream_infection", "Bloodstream infection", "SP blood culture / microbiology", "blood culture evidence", confluence_signal_present("blood culture|bloodculture|bloddyrkning|bloed|sepsis", sources, panel_raw_fields, panel_distributions, panel_text), "Separate blood-culture testing opportunity from confirmed bloodstream infection."),
    confluence_readiness_row("resistant_organism", "Resistant organism signal", "Microbiology resistance/susceptibility", "resistance and susceptibility evidence", confluence_signal_present("resistance|resistent|susceptib|foelsom|folsom|sensitivitet|antibiot", sources, panel_raw_fields, panel_distributions, panel_text), "Do not treat hospital/source aliases as antibiotic or susceptibility values."),
    confluence_readiness_row("infection_mortality", "Infection-related mortality", "Death / cause-of-death route", "cause-of-death or infection mortality evidence", confluence_signal_present("death|dod|doed|mortality|cause of death|dodsarsag|doedsaarsag", sources, panel_raw_fields, panel_distributions, panel_text), "Validate cause-of-death source access and coding before endpoint use.")
  )
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_infection_outcome_readiness() else out
}

confluence_treatment_modifier_row <- function(id, label, source_layer, source_signal, present, validation_needed, notes = "") {
  data.frame(
    modifier_id = id,
    modifier_label = label,
    source_layer = source_layer,
    source_signal = source_signal,
    readiness_status = if (isTRUE(present)) "source evidence present; validation required" else "source validation required",
    evidence_status = if (isTRUE(present)) "profiled aggregate" else "query executable not run",
    count_kind = "source-readiness signal, not treatment count",
    validation_needed = validation_needed,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

confluence_treatment_modifier_readiness <- function(sources = NULL, panel_raw_fields = NULL, panel_distributions = NULL, panels = NULL) {
  panel_text <- bind_rows_base(Filter(is.data.frame, panels %||% list()))
  rows <- list(
    confluence_treatment_modifier_row("cll_treatment", "CLL treatment", "RKKP_CLL / treatment panels", "CLL registry treatment fields", confluence_signal_present("rkkp cll|cll|behandling|treatment", sources, panel_raw_fields, panel_distributions, panel_text), "Classify registry indicators separately from medication administrations."),
    confluence_treatment_modifier_row("btki", "BTKi / ibrutinib", "ATC/SKS/treatment", "ibrutinib/BTK inhibitor evidence", confluence_signal_present("ibrutinib|imbruvica|btki|btk inhibitor|l01xe27|bwha169", sources, panel_raw_fields, panel_distributions, panel_text), "Define timing as pre-treatment/post-treatment or time-updated modifier."),
    confluence_treatment_modifier_row("venetoclax", "Venetoclax", "ATC/SKS/treatment", "venetoclax evidence", confluence_signal_present("venetoclax|venclyxto", sources, panel_raw_fields, panel_distributions, panel_text), "Validate source and route before using as modifier."),
    confluence_treatment_modifier_row("anti_cd20", "Anti-CD20", "ATC/SKS/treatment", "rituximab/obinutuzumab evidence", confluence_signal_present("rituximab|mabthera|obinutuzumab|gazyvaro|anti cd20", sources, panel_raw_fields, panel_distributions, panel_text), "Separate regimen component, supportive context, and registry indicator evidence."),
    confluence_treatment_modifier_row("steroids", "Steroids", "Medication / treatment", "steroid evidence", confluence_signal_present("steroid|prednis|dexameth|methylpred", sources, panel_raw_fields, panel_distributions, panel_text), "Distinguish antineoplastic regimen components from supportive or unrelated steroid use."),
    confluence_treatment_modifier_row("mm_therapy", "MM therapy", "DaMyDa / ATC / SKS", "myeloma treatment evidence", confluence_signal_present("damyda|myeloma|bortezomib|lenalidomide|pomalidomide|carfilzomib|daratumumab", sources, panel_raw_fields, panel_distributions, panel_text), "Define MM therapy line and timing before modifier use."),
    confluence_treatment_modifier_row("anti_cd38", "Anti-CD38", "ATC/treatment", "daratumumab/isatuximab evidence", confluence_signal_present("daratumumab|darzalex|isatuximab|sarclisa|anti cd38", sources, panel_raw_fields, panel_distributions, panel_text), "Validate source and line of therapy."),
    confluence_treatment_modifier_row("imid", "IMiD", "ATC/treatment", "lenalidomide/pomalidomide/thalidomide evidence", confluence_signal_present("lenalidomide|pomalidomide|thalidomide|imid", sources, panel_raw_fields, panel_distributions, panel_text), "Validate drug concept grouping and source separation."),
    confluence_treatment_modifier_row("proteasome_inhibitor", "Proteasome inhibitor", "ATC/treatment", "bortezomib/carfilzomib/ixazomib evidence", confluence_signal_present("bortezomib|carfilzomib|ixazomib|proteasome", sources, panel_raw_fields, panel_distributions, panel_text), "Validate drug concept grouping and source separation."),
    confluence_treatment_modifier_row("asct_hdt", "ASCT/HDT", "SKS/procedure therapy", "stem-cell transplant/high-dose therapy evidence", confluence_signal_present("asct|hdt|stem cell|stamcelle|transplant|bwgc|bwha", sources, panel_raw_fields, panel_distributions, panel_text), "Treat as procedure/treatment timing evidence, not medication.")
  )
  out <- bind_rows_base(rows)
  if (!nrow(out)) confluence_empty_treatment_modifier_readiness() else out
}

confluence_estimands <- function() {
  data.frame(
    estimand_id = c("first_serious_infection", "recurrent_infection_burden", "microbiology_confirmed_phenotype", "additive_interaction_dual_clone"),
    title = c("First serious infection estimand", "Recurrent infection burden estimand", "Microbiology-confirmed infection phenotype estimand", "Additive interaction / dual-clone vulnerability estimand"),
    population = c(
      "Adults in DALY-CARE with validated CLL/MBL and/or validated MGUS/SMM/MM disease states, alive and under observation at disease-state entry.",
      "Same disease-state population as the primary estimand.",
      "Subcohort with microbiology/blood-culture ascertainment opportunity.",
      "Adults with sufficient follow-up and validated disease-state timing."
    ),
    exposure_condition = c(
      "Time-varying clonal disease state: CLL/MBL only, PCD only, or CLL/MBL + PCD overlap.",
      "Time-varying clonal disease state groups.",
      "CLL/MBL only, PCD only, overlap.",
      "Joint exposure: CLL/MBL yes/no x PCD yes/no."
    ),
    outcome_variable = c(
      "First serious infection within 2 years after disease-state entry, optionally enriched by microbiology confirmation.",
      "Number of serious infection episodes per person-year.",
      "Positive culture/PCR/analysis, bloodstream infection, organism class, and resistance signal.",
      "2-year serious infection risk."
    ),
    intercurrent_events = c(
      "Death before infection is a competing event; progression and treatment initiation are time-updated modifiers or stratifiers.",
      "Death terminates follow-up; treatment can be handled as time-updated.",
      "Testing intensity and admission intensity are key ascertainment processes.",
      "Death as competing event; treatment as time-updated modifier/sensitivity."
    ),
    summary_measure = c(
      "Cumulative incidence at 1 and 2 years plus adjusted cause-specific or subdistribution hazard ratio.",
      "Incidence rate ratio or recurrent-event model estimate.",
      "Proportion or rate of microbiology-confirmed infections by organism class and disease state.",
      "Excess risk due to interaction, such as RERI or risk-difference interaction."
    ),
    plain_language = c(
      "Among people who newly enter a CLL/MBL, plasma-cell-disorder, or overlap state, what is the 1-2 year risk of serious infection, accounting for death and progression?",
      "Is the overlap group experiencing more repeated infection episodes, not just earlier first infection?",
      "Do overlap patients have a different infection phenotype, not just a higher infection count?",
      "Is infection risk in people with both clonal states greater than the sum of the risks from each state alone?"
    ),
    feasibility_status = "feasibility only; query executable not run; not causal",
    stringsAsFactors = FALSE
  )
}

confluence_validation_checklist <- function() {
  data.frame(
    entity_id = c("cll", "mbl", "mgus", "smm", "mm", "overlap", "infection", "treatment", "privacy"),
    entity_label = c("CLL", "MBL", "MGUS", "SMM", "MM", "Overlap person-time", "Infection outcomes", "Treatment modifiers", "Privacy/suppression"),
    validation_step = c(
      "Use RKKP_CLL preferred when available; support with repeated diagnosis, treatment, molecular, or flow/FISH/IGHV evidence.",
      "Use DD479B / D47.9B as coded candidate; exclude prior/concurrent CLL where appropriate and seek flow-cytometry/lab support.",
      "Use DD472 / D47.2 as coded candidate; seek M-protein/FLC/immunoglobulin support and exclude active MM at or before MGUS index.",
      "Locate SMM-specific registry/lab/diagnosis logic if present.",
      "Use DaMyDa and/or DC900 / C90.0 with treatment/staging support where available.",
      "Define overlap date as the later of two qualifying disease-state entry dates; do not classify pre-overlap time as overlap time.",
      "Separate serious infection, recurrent infection, microbiology-confirmed infection, bloodstream infection, resistance, and infection mortality.",
      "Handle CLL/MM treatments as time-updated modifiers, not ignored confounders.",
      "Keep outputs aggregate-only with small-cell suppression and no individual-record examples."
    ),
    source_hint = c("RKKP_CLL; diagnoses_all; t_dalycare_diagnoses", "DD479B / D47.9B; flow cytometry if available", "DD472 / D47.2; LABKA/NPU M-protein/FLC/Ig evidence", "DaMyDa/lab/diagnosis sources if mapped", "RKKP_DaMyDa; DC900 / C90.0", "future accepted aggregate query", "SDS/LPR; microbiology; blood culture; mortality routes", "Treatment panels; ATC/SKS; RKKP registries; SP/SMR/prescriptions", "atlas min-cell and public-frame sanitization"),
    status = c("source validation required", "coded candidate cohort", "coded candidate cohort", "query executable not run", "coded candidate cohort", "query executable not run", "source validation required", "source validation required", "required"),
    notes = c(
      "CLL diagnosis-atlas records are not validated persons.",
      "MBL is a biologic/flow-cytometry entity; the atlas anchor is a diagnosis-code candidate.",
      "MGUS ascertainment may be incidental and testing-opportunity dependent.",
      "SMM is not accepted unless a source-specific aggregate run proves it.",
      "MM diagnosis records are not equivalent to validated DaMyDa person denominators.",
      "This prevents immortal-time bias from naive ever-overlap classification.",
      "Testing/admission opportunity must be modelled or stratified.",
      "BTKi, venetoclax, anti-CD20, steroids, IMiD, PI, anti-CD38, and ASCT/HDT can modify infection risk.",
      "No identifiers, CPR values, individual event dates, pathology narratives, or unsafe small cells."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_bias_warnings <- function() {
  data.frame(
    bias_id = c("immortal_time", "surveillance_testing", "mbl_undercoding", "mgus_ascertainment", "treatment_confounding", "progression_state_transition", "competing_mortality", "small_cell_suppression"),
    bias_label = c("immortal-time bias", "surveillance/testing bias", "MBL undercoding", "MGUS ascertainment bias", "treatment confounding", "progression/state-transition bias", "competing mortality", "small-cell suppression"),
    why_it_matters = c(
      "Overlap patients must survive long enough to receive the second qualifying disease-state diagnosis.",
      "CLL/MM patients may receive more labs, admissions, and cultures, inflating observed infection ascertainment.",
      "Many MBL cases are flow-detected or biologic and may not be diagnosis-coded.",
      "MGUS is often incidental and depends on testing opportunity.",
      "BTKi, venetoclax, anti-CD20, steroids, IMiD, PI, anti-CD38, ASCT/HDT, and other treatments may cause or prevent infections.",
      "MGUS/SMM can progress to MM and MBL can progress to CLL, changing risk state over time.",
      "Death before infection competes with the infection endpoint.",
      "MBL overlap strata may be small and must remain suppressed or grouped when below threshold."
    ),
    mitigation = c(
      "Define overlap entry at the second qualifying disease-state date or use time-varying exposure.",
      "Separate hospital-coded and microbiology-confirmed outcomes; consider testing/admission intensity.",
      "Label DD479B / D47.9B as coded MBL candidate, not all biologic MBL.",
      "Use M-protein/FLC/immunoglobulin testing opportunity and sensitivity analyses.",
      "Model treatment as pre/post strata or time-updated modifier.",
      "Use time-updated disease states and first-date validation.",
      "Use competing-risk cumulative incidence or cause-specific handling.",
      "Report aggregate-only with suppression and count-kind labels."
    ),
    severity = c("critical", "high", "high", "high", "critical", "high", "high", "critical"),
    stringsAsFactors = FALSE
  )
}

confluence_recommended_next_actions <- function() {
  data.frame(
    action_id = c("deduplicate_first_dates", "run_overlap_counts", "validate_mbl", "validate_mgus", "map_infection_outcomes", "classify_microbiology_roles", "add_treatment_modifiers", "review_small_cells"),
    action_label = c(
      "Build person-deduplicated disease-state first-date aggregate",
      "Run overlap-count aggregates with accepted/not-accepted status",
      "Validate coded MBL against CLL conflicts and flow/lab support",
      "Validate coded MGUS against MM conflicts and monoclonal-protein support",
      "Define serious and recurrent infection outcomes",
      "Classify microbiology field roles before organism/resistance panels",
      "Map treatment modifiers as time-updated source-specific layers",
      "Pre-check small-cell suppression for MBL/PCD overlaps"
    ),
    owner_role = c("data manager / analyst", "data manager / analyst", "CLL researcher + data manager", "PCD researcher + data manager", "clinician investigator + analyst", "microbiology/source owner + analyst", "treatment/source owner + analyst", "data manager / QA"),
    priority = c("P0", "P0", "P0", "P0", "P1", "P1", "P1", "P0"),
    status = c("not started", "query executable not run", "source validation required", "source validation required", "source validation required", "source validation required", "source validation required", "required"),
    notes = c(
      "Needed before any overlap timing or target-trial state assignment.",
      "Do not label overlap rows accepted until the aggregate run returns acceptance_status == accepted.",
      "Classify as coded MBL until validated biologic MBL logic exists.",
      "Separate MGUS, SMM, active MM, and paraprotein associated with CLL.",
      "Outcome definitions should be protocol-owned before extraction.",
      "Avoid repeating the hospital/source alias error in antibiotic/susceptibility panels.",
      "Treat medications/procedures/registry indicators as different evidence types.",
      "Likely limiting step for MBL overlap reporting."
    ),
    stringsAsFactors = FALSE
  )
}

confluence_summary <- function(disease_counts, infection_readiness, treatment_readiness) {
  candidate_rows <- sum(disease_counts$evidence_status == "coded candidate cohort", na.rm = TRUE)
  diagnosis_records <- sum(suppressWarnings(as.numeric(disease_counts$n_records)), na.rm = TRUE)
  readiness_present <- sum(grepl("present", infection_readiness$readiness_status %||% "", ignore.case = TRUE), na.rm = TRUE)
  treatment_present <- sum(grepl("present", treatment_readiness$readiness_status %||% "", ignore.case = TRUE), na.rm = TRUE)
  data.frame(
    metric = c("panel_status", "candidate_disease_anchors", "diagnosis_atlas_record_anchors", "overlap_acceptance_status", "infection_readiness_signals", "treatment_modifier_signals", "raw_patient_rows_emitted"),
    label = c("Panel status", "Candidate disease anchors", "Diagnosis-atlas record anchors", "Overlap acceptance status", "Infection readiness signals", "Treatment modifier readiness signals", "Raw patient rows emitted"),
    value = c("scaffold first", as.character(candidate_rows), format(diagnosis_records, big.mark = ",", scientific = FALSE, trim = TRUE), "query executable not run", as.character(readiness_present), as.character(treatment_present), "0"),
    status = c("feasibility only", "coded candidate cohort", "diagnosis-atlas records", "not accepted aggregate", "source validation required", "source validation required", "privacy-safe aggregate only"),
    count_kind = c("not patient count", "source/code rows", "diagnosis-atlas records", "not run", "source-readiness signal", "source-readiness signal", "not patient count"),
    evidence_confidence = c("candidate mapping", "fallback/reference", "fallback/reference", "query executable not run", "profiled aggregate", "profiled aggregate", "production safeguard"),
    notes = c(
      "CONFLUENCE renders feasibility infrastructure only; it does not execute new production overlap queries.",
      "CLL, MBL, MGUS, and MM anchors are candidate diagnosis-code evidence until validated.",
      "Diagnosis-atlas records are evidence anchors, not validated person denominators.",
      "Overlap counts and timing remain not-run/not-accepted in this scaffold implementation.",
      "Presence indicates route/readiness evidence only, not outcome counts.",
      "Presence indicates route/readiness evidence only, not medication exposure counts.",
      "The panel emits aggregate rows only."
    ),
    stringsAsFactors = FALSE
  )
}

build_confluence_feasibility_outputs <- function(project_root = ".",
                                                 sources = NULL,
                                                 columns = NULL,
                                                 column_profiles = NULL,
                                                 column_top_values = NULL,
                                                 panels = NULL,
                                                 panel_raw_fields = NULL,
                                                 panel_distributions = NULL,
                                                 panel_kpis = NULL,
                                                 canonical_reconciliation = NULL,
                                                 legacy_reference_vs_current = NULL) {
  disease_counts <- confluence_disease_state_counts(project_root = project_root, column_top_values = column_top_values)
  overlap_counts <- confluence_overlap_counts()
  overlap_timing <- confluence_overlap_timing()
  infection_readiness <- confluence_infection_outcome_readiness(
    sources = sources,
    panel_raw_fields = panel_raw_fields,
    panel_distributions = panel_distributions,
    panels = panels
  )
  treatment_readiness <- confluence_treatment_modifier_readiness(
    sources = sources,
    panel_raw_fields = panel_raw_fields,
    panel_distributions = panel_distributions,
    panels = panels
  )
  list(
    summary = confluence_summary(disease_counts, infection_readiness, treatment_readiness),
    disease_state_counts = disease_counts,
    overlap_counts = overlap_counts,
    overlap_timing = overlap_timing,
    infection_outcome_readiness = infection_readiness,
    treatment_modifier_readiness = treatment_readiness,
    estimands = confluence_estimands(),
    validation_checklist = confluence_validation_checklist(),
    bias_warnings = confluence_bias_warnings(),
    recommended_next_actions = confluence_recommended_next_actions()
  )
}

confluence_write_outputs <- function(outputs, output_dir) {
  if (is.null(outputs)) outputs <- confluence_empty_payload()
  list(
    summary = write_csv(outputs$summary %||% confluence_empty_summary(), file.path(output_dir, "confluence_feasibility_summary.csv")),
    disease_state_counts = write_csv(outputs$disease_state_counts %||% confluence_empty_disease_state_counts(), file.path(output_dir, "confluence_disease_state_counts.csv")),
    overlap_counts = write_csv(outputs$overlap_counts %||% confluence_empty_overlap_counts(), file.path(output_dir, "confluence_overlap_counts.csv")),
    overlap_timing = write_csv(outputs$overlap_timing %||% confluence_empty_overlap_timing(), file.path(output_dir, "confluence_overlap_timing.csv")),
    infection_outcome_readiness = write_csv(outputs$infection_outcome_readiness %||% confluence_empty_infection_outcome_readiness(), file.path(output_dir, "confluence_infection_outcome_readiness.csv")),
    treatment_modifier_readiness = write_csv(outputs$treatment_modifier_readiness %||% confluence_empty_treatment_modifier_readiness(), file.path(output_dir, "confluence_treatment_modifier_readiness.csv")),
    estimands = write_csv(outputs$estimands %||% confluence_empty_estimands(), file.path(output_dir, "confluence_estimands.csv")),
    validation_checklist = write_csv(outputs$validation_checklist %||% confluence_empty_validation_checklist(), file.path(output_dir, "confluence_validation_checklist.csv")),
    bias_warnings = write_csv(outputs$bias_warnings %||% confluence_empty_bias_warnings(), file.path(output_dir, "confluence_bias_warnings.csv")),
    recommended_next_actions = write_csv(outputs$recommended_next_actions %||% confluence_empty_recommended_next_actions(), file.path(output_dir, "confluence_recommended_next_actions.csv"))
  )
}
