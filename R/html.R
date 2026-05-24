write_static_atlas <- function(run_dir, payload, project_root = ".") {
  site_dir <- file.path(run_dir, "site")
  dir_create(site_dir)

  template_path <- system.file("templates", "DALYCARE_atlas.html", package = "dalycareatlas")
  if (!nzchar(template_path) || !file.exists(template_path)) {
    template_path <- file.path(project_root, "inst", "templates", "DALYCARE_atlas.html")
  }
  if (!file.exists(template_path)) {
    stop("HTML template not found.", call. = FALSE)
  }

  html_path <- file.path(site_dir, "DALYCARE_atlas.html")
  payload_path <- file.path(site_dir, "DALYCARE_atlas_payload.js")
  file.copy(template_path, html_path, overwrite = TRUE)

  json <- atlas_to_json(payload)
  writeLines(c("window.DALYCARE_ATLAS_PAYLOAD = ", json, ";"), con = payload_path, useBytes = TRUE)
  list(html = html_path, payload = payload_path)
}

empty_streaming_progress_summary <- function() {
  empty_df(
    table_name = character(),
    domain = character(),
    subdomain = character(),
    atlas_role = character(),
    streamed_columns = integer(),
    total_chunks = integer(),
    total_elapsed_ms = numeric(),
    total_elapsed_minutes = numeric(),
    estimated_rows = numeric(),
    slowest_column = character(),
    slowest_column_elapsed_ms = numeric(),
    status = character(),
    message = character()
  )
}

atlas_streaming_progress_summary <- function(db_query_log, sources = NULL) {
  if (!is.data.frame(db_query_log) || !nrow(db_query_log)) return(empty_streaming_progress_summary())
  required <- c("table_name", "column_name", "query_category", "strategy")
  if (!all(required %in% names(db_query_log))) return(empty_streaming_progress_summary())
  rows <- db_query_log[
    db_query_log$strategy == "stream_column" |
      db_query_log$query_category == "column_stream",
    ,
    drop = FALSE
  ]
  if (!nrow(rows)) return(empty_streaming_progress_summary())
  rows$elapsed_ms_num <- suppressWarnings(as.numeric(rows$elapsed_ms %||% NA_real_))
  rows$chunks_num <- suppressWarnings(as.integer(rows$chunks_fetched %||% NA_integer_))
  rows$estimated_rows_num <- suppressWarnings(as.numeric(rows$estimated_rows %||% NA_real_))
  by_table <- split(rows, rows$table_name)
  out <- lapply(by_table, function(group) {
    table_name <- group$table_name[[1]] %||% ""
    ctx <- source_context_row(sources, table_name)
    elapsed <- group$elapsed_ms_num
    slow_i <- if (any(!is.na(elapsed))) which.max(replace(elapsed, is.na(elapsed), -Inf)) else 1L
    statuses <- unique_nonblank(group$status %||% character())
    status <- if (length(statuses) && all(statuses == "ok")) "ok" else if (length(statuses)) "warning" else "unknown"
    streamed_columns <- length(unique_nonblank(group$column_name))
    total_chunks <- sum(group$chunks_num, na.rm = TRUE)
    total_elapsed_ms <- sum(group$elapsed_ms_num, na.rm = TRUE)
    estimated <- if (any(!is.na(group$estimated_rows_num))) {
      max(group$estimated_rows_num, na.rm = TRUE)
    } else {
      NA_real_
    }
    data.frame(
      table_name = table_name,
      domain = ctx$domain %||% "",
      subdomain = ctx$subdomain %||% "",
      atlas_role = ctx$atlas_role %||% "",
      streamed_columns = streamed_columns,
      total_chunks = total_chunks,
      total_elapsed_ms = total_elapsed_ms,
      total_elapsed_minutes = round(total_elapsed_ms / 60000, 2),
      estimated_rows = estimated,
      slowest_column = group$column_name[[slow_i]] %||% "",
      slowest_column_elapsed_ms = group$elapsed_ms_num[[slow_i]] %||% NA_real_,
      status = status,
      message = paste(
        streamed_columns,
        "column(s) streamed in",
        total_chunks,
        "chunk(s); slowest column:",
        group$column_name[[slow_i]] %||% ""
      ),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(out)
  if (!nrow(out)) return(empty_streaming_progress_summary())
  out[order(-suppressWarnings(as.numeric(out$total_elapsed_ms)), out$table_name), , drop = FALSE]
}

atlas_payload <- function(run_id, generated_at, sources, columns, checks, panels,
                          column_profiles = NULL, column_top_values = NULL,
                          run_summary = NULL, action_items = NULL, source_resolution = NULL,
                          memory_plan = NULL, db_query_log = NULL,
                          db_budget_actions = NULL,
                          semantic_dictionary = NULL, semantic_value_map = NULL,
                          semantic_code_map = NULL, semantic_panel_links = NULL,
                          clinical_concepts = NULL, domain_panels = NULL,
                          panel_kpis_product = NULL, panel_distributions = NULL,
                          panel_raw_fields = NULL, panel_parity = NULL,
                          legacy_resource_audit = NULL, billeddiagnostik_del2_regression_audit = NULL,
                          source_resolution_plan_dry_run = NULL,
                          source_resolution_attempts = NULL, source_resolution_delta = NULL,
                          resource_reconciliation = NULL, source_truth_evidence = NULL,
                          source_truth_summary = NULL, current_run_source_map_audit = NULL,
                          canonical_resource_reconciliation = NULL,
                          source_map_crosswalk = NULL,
                          legacy_reference_vs_current = NULL,
                          remaining_activation_plan = NULL,
                          ki67_discovery = NULL,
                          patobank_ki67_percent = NULL,
                          mcl_triangle_feasibility = NULL,
                          confluence_feasibility = NULL) {
  if (is.null(column_profiles)) column_profiles <- basic_column_profiles(columns)
  if (is.null(column_top_values)) column_top_values <- empty_column_top_values()
  if (is.null(action_items)) action_items <- empty_run_action_items()
  if (is.null(semantic_dictionary)) semantic_dictionary <- empty_semantic_data_dictionary()
  if (is.null(semantic_value_map)) semantic_value_map <- empty_semantic_value_map()
  if (is.null(semantic_code_map)) semantic_code_map <- empty_semantic_code_map()
  if (is.null(semantic_panel_links)) semantic_panel_links <- empty_semantic_panel_links()
  if (is.null(clinical_concepts)) clinical_concepts <- empty_clinical_concepts()
  if (is.null(domain_panels)) domain_panels <- empty_domain_panels()
  if (is.null(panel_kpis_product)) panel_kpis_product <- empty_panel_kpis()
  if (is.null(panel_distributions)) panel_distributions <- empty_panel_distributions()
  if (is.null(panel_raw_fields)) panel_raw_fields <- empty_panel_raw_fields()
  if (is.null(panel_parity)) panel_parity <- empty_panel_parity()
  if (is.null(legacy_resource_audit)) legacy_resource_audit <- data.frame(stringsAsFactors = FALSE)
  if (is.null(billeddiagnostik_del2_regression_audit)) billeddiagnostik_del2_regression_audit <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_resolution_plan_dry_run)) source_resolution_plan_dry_run <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_resolution_attempts)) source_resolution_attempts <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_resolution_delta)) source_resolution_delta <- data.frame(stringsAsFactors = FALSE)
  if (is.null(resource_reconciliation)) resource_reconciliation <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_truth_evidence)) source_truth_evidence <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_truth_summary)) source_truth_summary <- data.frame(stringsAsFactors = FALSE)
  if (is.null(current_run_source_map_audit)) current_run_source_map_audit <- data.frame(stringsAsFactors = FALSE)
  if (is.null(canonical_resource_reconciliation)) canonical_resource_reconciliation <- data.frame(stringsAsFactors = FALSE)
  if (is.null(source_map_crosswalk)) source_map_crosswalk <- data.frame(stringsAsFactors = FALSE)
  if (is.null(legacy_reference_vs_current)) legacy_reference_vs_current <- data.frame(stringsAsFactors = FALSE)
  if (is.null(remaining_activation_plan)) remaining_activation_plan <- data.frame(stringsAsFactors = FALSE)
  if (is.null(ki67_discovery)) ki67_discovery <- ki67_empty_payload()
  if (is.null(patobank_ki67_percent)) patobank_ki67_percent <- patobank_ki67_empty_outputs()
  if (is.null(mcl_triangle_feasibility)) mcl_triangle_feasibility <- mcl_triangle_empty_payload()
  if (is.null(confluence_feasibility)) confluence_feasibility <- confluence_empty_payload()
  public_checks <- sanitize_public_frame(checks)
  public_panels <- lapply(panels, sanitize_public_frame)
  public_column_profiles <- public_column_profile_rows(column_profiles)
  public_column_top_values <- sanitize_public_frame(column_top_values)
  public_action_items <- sanitize_public_frame(action_items)
  public_db_query_log <- public_db_diagnostics(db_query_log)
  public_db_budget_actions <- public_db_diagnostics(db_budget_actions)
  public_semantic_dictionary <- sanitize_public_frame(semantic_dictionary)
  public_semantic_value_map <- sanitize_public_frame(semantic_value_map)
  public_semantic_code_map <- sanitize_public_frame(semantic_code_map)
  public_semantic_panel_links <- sanitize_public_frame(semantic_panel_links)
  public_clinical_concepts <- sanitize_public_frame(clinical_concepts)
  public_domain_panels <- sanitize_public_frame(domain_panels)
  public_panel_kpis <- sanitize_public_frame(panel_kpis_product)
  public_panel_distributions <- sanitize_public_frame(panel_distributions)
  public_panel_raw_fields <- sanitize_public_frame(panel_raw_fields)
  public_panel_parity <- sanitize_public_frame(panel_parity)
  public_legacy_resource_audit <- sanitize_public_frame(legacy_resource_audit)
  public_billeddiagnostik_del2_regression_audit <- sanitize_public_frame(billeddiagnostik_del2_regression_audit)
  public_source_resolution_plan_dry_run <- sanitize_public_frame(source_resolution_plan_dry_run)
  public_source_resolution_attempts <- sanitize_public_frame(source_resolution_attempts)
  public_source_resolution_delta <- sanitize_public_frame(source_resolution_delta)
  public_resource_reconciliation <- sanitize_public_frame(resource_reconciliation)
  public_source_truth_evidence <- sanitize_public_frame(source_truth_evidence)
  public_source_truth_summary <- sanitize_public_frame(source_truth_summary)
  public_current_run_source_map_audit <- sanitize_public_frame(current_run_source_map_audit)
  public_canonical_resource_reconciliation <- sanitize_public_frame(canonical_resource_reconciliation)
  public_source_map_crosswalk <- sanitize_public_frame(source_map_crosswalk)
  public_legacy_reference_vs_current <- sanitize_public_frame(legacy_reference_vs_current)
  public_remaining_activation_plan <- sanitize_public_frame(remaining_activation_plan)
  public_ki67_discovery <- lapply(ki67_discovery, function(x) {
    if (is.data.frame(x)) public_rows(sanitize_public_frame(x), max_rows = 2000) else x
  })
  public_patobank_ki67_percent <- lapply(patobank_ki67_percent, function(x) {
    if (is.data.frame(x)) public_rows(sanitize_public_frame(x), max_rows = 2000) else x
  })
  public_mcl_triangle_feasibility <- lapply(mcl_triangle_feasibility, function(x) {
    if (is.data.frame(x)) return(public_rows(sanitize_public_frame(x), max_rows = 2000))
    if (is.list(x)) {
      return(lapply(x, function(y) {
        if (is.data.frame(y)) public_rows(sanitize_public_frame(y), max_rows = 2000) else y
      }))
    }
    x
  })
  public_confluence_feasibility <- lapply(confluence_feasibility, function(x) {
    if (is.data.frame(x)) return(public_rows(sanitize_public_frame(x), max_rows = 2000))
    if (is.list(x)) {
      return(lapply(x, function(y) {
        if (is.data.frame(y)) public_rows(sanitize_public_frame(y), max_rows = 2000) else y
      }))
    }
    x
  })
  module_readiness <- panel_or_empty(panels, "atlas_module_readiness")
  list(
    run_id = run_id,
    generated_at = generated_at,
    builder_credit = atlas_builder_credit(),
    source_count = nrow(sources),
    loaded_source_count = sum(sources$load_status == "ok", na.rm = TRUE),
    column_count = nrow(columns),
    check_count = nrow(checks),
    warning_count = sum(checks$severity == "warning", na.rm = TRUE),
    error_count = sum(checks$severity == "error", na.rm = TRUE),
    hero_metrics = public_rows(hero_metrics(sources, columns, checks, run_summary), max_rows = 20),
    domain_cards = public_rows(domain_cards(sources), max_rows = 100),
    catalog_rows = public_rows(catalog_rows(sources), max_rows = 1000),
    qa_items = public_rows(qa_items(checks), max_rows = 500),
    npu_cards = npu_cards(panels),
    detective_cards = detective_cards(panels),
    isotype_cards = isotype_cards(panels),
    treatment_cards = treatment_cards(panels),
    situation_report_cards = situation_report_cards(panels),
    review_scope_notes = public_rows(review_scope_notes(sources, columns, checks, run_summary), max_rows = 20),
    review_data_landscape = review_data_landscape(sources, panels),
    review_module_readiness = public_rows(module_readiness, max_rows = 100),
    review_streaming_summary = public_rows(panel_or_empty(panels, "atlas_streaming_progress_summary"), max_rows = 500),
    review_temporal_date_quality = public_rows(panel_or_empty(panels, "atlas_temporal_date_quality"), max_rows = 500),
    review_semantic_summary = public_rows(semantic_summary(semantic_dictionary, semantic_value_map, semantic_code_map, semantic_panel_links), max_rows = 100),
    review_domain_jump_links = review_domain_jump_links(),
    review_clinical_variables = review_clinical_variables(clinical_concepts, panel_raw_fields, panel_distributions, panel_kpis_product),
    review_nav = review_nav(),
    review_overview = review_overview(
      sources = sources,
      columns = columns,
      checks = checks,
      panels = panels,
      run_summary = run_summary,
      action_items = action_items
    ),
    review_registry_sections = review_registry_sections(panels),
    review_clinical_sections = review_clinical_sections(sources),
    review_treatment_sections = review_treatment_sections(sources, panels),
    review_laboratory_sections = review_laboratory_sections(sources, panels),
    review_situation_sections = review_situation_sections(panels),
    review_ehr_sections = review_ehr_sections(sources),
    review_temporal_coverage = review_temporal_coverage(panels),
    review_spatial_coverage = review_spatial_coverage(panels),
    review_dk_choropleth = review_dk_choropleth(panels),
    review_infrastructure_sections = review_infrastructure_sections(
      sources = sources,
      checks = checks,
      panels = panels,
      column_profiles = column_profiles,
      run_summary = run_summary,
      action_items = action_items,
      source_resolution = source_resolution,
      memory_plan = memory_plan,
      db_query_log = db_query_log,
      db_budget_actions = db_budget_actions,
      legacy_resource_audit = legacy_resource_audit,
      source_resolution_delta = source_resolution_delta,
      resource_reconciliation = resource_reconciliation,
      canonical_resource_reconciliation = canonical_resource_reconciliation,
      current_run_source_map_audit = current_run_source_map_audit,
      source_map_crosswalk = source_map_crosswalk,
      legacy_reference_vs_current = legacy_reference_vs_current
    ),
    registry_cards = registry_cards(panels),
    panel_groups = public_rows(panel_groups(panels), max_rows = 100),
    column_profile_rows = public_rows(public_column_profiles, max_rows = 3000),
    column_top_value_rows = public_rows(public_column_top_values, max_rows = 3000),
    column_profile_summary = public_rows(column_profile_summary(column_profiles), max_rows = 200),
    semantic_dictionary_rows = public_rows(public_semantic_dictionary, max_rows = 5000),
    semantic_value_map_rows = public_rows(public_semantic_value_map, max_rows = 5000),
    semantic_code_map_rows = public_rows(public_semantic_code_map, max_rows = 5000),
    semantic_panel_links = public_rows(public_semantic_panel_links, max_rows = 5000),
    clinical_concept_rows = public_rows(public_clinical_concepts, max_rows = 5000),
    domain_panel_rows = public_rows(public_domain_panels, max_rows = 500),
    panel_kpi_rows = public_rows(public_panel_kpis, max_rows = 2000),
    panel_distribution_rows = public_rows(public_panel_distributions, max_rows = 5000),
    panel_raw_field_rows = public_rows(public_panel_raw_fields, max_rows = 5000),
    panel_parity_rows = public_rows(public_panel_parity, max_rows = 500),
    legacy_cartography_audit_rows = public_rows(public_legacy_resource_audit, max_rows = 1000),
    billeddiagnostik_del2_regression_audit_rows = public_rows(public_billeddiagnostik_del2_regression_audit, max_rows = 1000),
    source_resolution_plan_dry_run_rows = public_rows(public_source_resolution_plan_dry_run, max_rows = 1000),
    source_resolution_attempt_rows = public_rows(public_source_resolution_attempts, max_rows = 1000),
    source_resolution_delta_rows = public_rows(public_source_resolution_delta, max_rows = 1000),
    resource_reconciliation_rows = public_rows(public_resource_reconciliation, max_rows = 1000),
    source_truth_evidence_rows = public_rows(public_source_truth_evidence, max_rows = 1000),
    source_truth_summary_rows = public_rows(public_source_truth_summary, max_rows = 100),
    current_run_source_map_audit_rows = public_rows(public_current_run_source_map_audit, max_rows = 1000),
    canonical_resource_reconciliation_rows = public_rows(public_canonical_resource_reconciliation, max_rows = 1000),
    source_map_crosswalk_rows = public_rows(public_source_map_crosswalk, max_rows = 1000),
    legacy_reference_vs_current_rows = public_rows(public_legacy_reference_vs_current, max_rows = 1000),
    remaining_activation_plan_rows = public_rows(public_remaining_activation_plan, max_rows = 1000),
    ki67_discovery = public_ki67_discovery,
    patobank_ki67_percent = public_patobank_ki67_percent,
    mcl_triangle_feasibility = public_mcl_triangle_feasibility,
    confluence_feasibility = public_confluence_feasibility,
    run_summary = public_rows(run_summary, max_rows = 100),
    action_items = public_rows(public_action_items, max_rows = 1000),
    action_summary = public_rows(action_item_summary(action_items), max_rows = 100),
    db_query_log = public_rows(public_db_query_log, max_rows = 3000),
    db_budget_actions = public_rows(public_db_budget_actions, max_rows = 1000),
    source_domains = public_rows(source_domain_summary(sources), max_rows = 100),
    sources = public_rows(public_sources(sources), max_rows = 500),
    checks = public_rows(public_checks, max_rows = 500),
    panels = lapply(public_panels, public_rows, max_rows = 250)
  )
}

atlas_builder_credit <- function() {
  "Built by Alexander Owen Taylor"
}

review_nav <- function() {
  list(
    list(
      id = "overview",
      label = "Overview",
      sub_tabs = c("Run metrics", "Coverage", "Temporal coverage", "Regional coverage", "Priority QA")
    ),
    list(
      id = "variables",
      label = "Clinical Variables",
      sub_tabs = c("Concept cards", "Raw names", "Distributions", "Related panels")
    ),
    list(
      id = "situation",
      label = "Situation Report",
      sub_tabs = c("Headlines", "Breakdowns", "Freshness", "Definitions")
    ),
    list(
      id = "quickstart",
      label = "Quick Start",
      sub_tabs = c("RStudio", "Terminal", "Preflight")
    ),
    list(
      id = "clinical-feasibility",
      label = "Clinical Feasibility",
      sub_tabs = c("MCL / TRIANGLE", "CONFLUENCE")
    ),
    list(
      id = "dictionary",
      label = "Data Dictionary",
      sub_tabs = c("Semantic lineage", "Value maps", "Code maps", "Panel links")
    ),
    list(
      id = "registries",
      label = "Disease Registries",
      sub_tabs = c("DaMyDa", "LYFO", "CLL", "Registry inventory")
    ),
    list(
      id = "clinical",
      label = "Clinical Data",
      sub_tabs = c("Diagnoses", "Admissions", "Imaging", "Vitals", "Notes", "Social history")
    ),
    list(
      id = "treatment",
      label = "Treatment",
      sub_tabs = c("Code families", "Source summary", "Medicine", "Procedures")
    ),
    list(
      id = "laboratory",
      label = "Laboratory & Diagnostics",
      sub_tabs = c("NPU vectors", "NPU detective", "Imaging", "Microbiology", "Pathology", "Isotypes", "Biobank", "Lab sources")
    ),
    list(
      id = "ehr",
      label = "EHR Modules",
      sub_tabs = c("SP", "SDS/LPR", "DALY views")
    ),
    list(
      id = "infrastructure",
      label = "Infrastructure",
      sub_tabs = c("Catalog", "Columns", "Resolution", "Memory plan", "DB budget", "Panels", "QA")
    )
  )
}

review_overview <- function(sources, columns, checks, panels, run_summary = NULL, action_items = NULL) {
  safe_sources <- public_sources(sources)
  module_readiness <- panel_or_empty(panels, "atlas_module_readiness")
  list(
    scope_notes = public_rows(review_scope_notes(sources, columns, checks, run_summary), max_rows = 20),
    metrics = public_rows(hero_metrics(sources, columns, checks, run_summary), max_rows = 20),
    source_availability = public_rows(review_source_availability(safe_sources), max_rows = 100),
    largest_sources = public_rows(review_largest_sources(safe_sources), max_rows = 20),
    module_readiness = public_rows(module_readiness, max_rows = 100),
    domain_jump_links = review_domain_jump_links(),
    action_items = public_rows(sanitize_public_frame(action_items), max_rows = 20),
    action_summary = public_rows(action_item_summary(action_items), max_rows = 100),
    priority_qa = public_rows(qa_items(checks), max_rows = 20),
    panel_groups = public_rows(panel_groups(panels), max_rows = 100),
    run_summary = public_rows(run_summary, max_rows = 100)
  )
}

review_scope_notes <- function(sources, columns, checks, run_summary = NULL) {
  run_values <- if (is.data.frame(run_summary) && nrow(run_summary) && all(c("metric", "value") %in% names(run_summary))) {
    stats::setNames(run_summary$value, run_summary$metric)
  } else {
    character()
  }
  n_rows <- named_value(run_values, "total_rows", as.character(sum(suppressWarnings(as.numeric(sources$n_rows)), na.rm = TRUE)))
  data.frame(
    note = c("Run scope", "Loaded evidence", "Privacy boundary", "Review interpretation"),
    detail = c(
      paste0(nrow(sources), " mapped sources, ", sum(sources$load_status == "ok", na.rm = TRUE), " loaded or resolved, and ", nrow(columns), " profiled columns."),
      paste0("The current run reports ", n_rows, " aggregate source rows and ", sum(checks$severity == "warning", na.rm = TRUE), " warnings."),
      paste0("Public panels use aggregate-only outputs with minimum cell count ", atlas_min_cell_count(), "; CPRs, patient IDs, and raw rows are excluded."),
      "Empty module cards mean no matching protected evidence was available in this run, not that the clinical domain does not exist."
    ),
    stringsAsFactors = FALSE
  )
}

review_data_landscape <- function(sources, panels) {
  list(
    domains = public_rows(domain_cards(sources), max_rows = 100),
    availability = public_rows(review_source_availability(public_sources(sources)), max_rows = 100),
    modules = public_rows(panel_or_empty(panels, "atlas_module_readiness"), max_rows = 100)
  )
}

review_domain_jump_links <- function() {
  list(
    list(domain = "Clinical Variables", target_tab = "variables", label = "Find concepts, raw names, value maps, and related panels"),
    list(domain = "Situation Report", target_tab = "situation", label = "Current and recent activity"),
    list(domain = "Registries", target_tab = "registries", label = "DaMyDa, LYFO, and CLL registry review"),
    list(domain = "Clinical Data", target_tab = "clinical", label = "Diagnoses, admissions, imaging, notes, vitals, and social history"),
    list(domain = "Treatment", target_tab = "treatment", label = "MM code families, medicine, and procedures"),
    list(domain = "Laboratory & Diagnostics", target_tab = "laboratory", label = "NPU dictionary, diagnostics, pathology, microbiology, imaging, biobank, and lab source evidence"),
    list(domain = "EHR Modules", target_tab = "ehr", label = "SP, SDS/LPR, and DALY view source readiness"),
    list(domain = "Infrastructure", target_tab = "infrastructure", label = "Resolution, streaming, DB budget, QA, and generated panels")
  )
}

review_clinical_variables <- function(clinical_concepts, panel_raw_fields, panel_distributions, panel_kpis) {
  list(
    concepts = public_rows(clinical_concepts, max_rows = 5000),
    raw_fields = public_rows(panel_raw_fields, max_rows = 5000),
    distributions = public_rows(panel_distributions, max_rows = 5000),
    kpis = public_rows(panel_kpis, max_rows = 2000)
  )
}

review_registry_sections <- function(panels) {
  cards <- registry_cards(panels)
  list(
    overview = cards,
    damyda = review_registry_panel_bundle(panels, "damyda"),
    lyfo = review_registry_panel_bundle(panels, "lyfo"),
    cll = review_registry_panel_bundle(panels, "cll"),
    summary = public_rows(panel_or_empty(panels, "registry_clinical_summary"), max_rows = 100)
  )
}

review_clinical_sections <- function(sources) {
  safe_sources <- public_sources(sources)
  list(
    diagnoses = public_rows(review_sources_like(safe_sources, c("diagnos", "diagnos", "diag", "cancer", "tumor")), max_rows = 100),
    admissions = public_rows(review_sources_like(safe_sources, c("adt", "adm", "kontakt", "contact", "skadestue", "icu")), max_rows = 100),
    imaging = public_rows(review_sources_like(safe_sources, c("billed", "imaging", "image", "radiolog", "scan", "ct", "mr")), max_rows = 100),
    vitals = public_rows(review_sources_like(safe_sources, c("vital", "vaegt", "weight", "height", "bloodpressure")), max_rows = 100),
    notes = public_rows(review_sources_like(safe_sources, c("note", "journal", "epikur", "text")), max_rows = 100),
    social_history = public_rows(review_sources_like(safe_sources, c("social", "smoking", "alcohol")), max_rows = 100)
  )
}

review_treatment_sections <- function(sources, panels) {
  cards <- treatment_cards(panels)
  safe_sources <- public_sources(sources)
  list(
    code_families = cards$code_families,
    source_summary = cards$source_summary,
    treatment_sources = public_rows(review_sources_like(
      safe_sources,
      c("behandling", "treatment", "medicin", "medicine", "atc", "procedure", "sks", "plan", "ordered", "administered")
    ), max_rows = 150),
    panels = public_rows(review_panel_index(panels, c("mm_treatment", "treatment")), max_rows = 50)
  )
}

review_situation_sections <- function(panels) {
  summary <- panel_or_empty(panels, "situation_report_summary")
  breakdowns <- panel_or_empty(panels, "situation_report_breakdowns")
  freshness <- panel_or_empty(panels, "situation_report_freshness")
  definition_cols <- intersect(c(
    "metric_id", "label", "n_rows", "window_days", "as_of_date", "source_table", "date_column",
    "definition_basis", "n_cohort", "pct_cohort",
    "definition_status", "freshness_status", "message"
  ), names(summary))
  definitions <- if (length(definition_cols)) summary[, definition_cols, drop = FALSE] else data.frame()
  list(
    cards = public_rows(summary, max_rows = 100),
    breakdowns = public_rows(breakdowns, max_rows = 1000),
    freshness = public_rows(freshness, max_rows = 500),
    definitions = public_rows(definitions, max_rows = 100)
  )
}

review_laboratory_sections <- function(sources, panels) {
  safe_sources <- public_sources(sources)
  list(
    npu = npu_cards(panels),
    detective = detective_cards(panels),
    isotype = isotype_cards(panels),
    lab_sources = public_rows(review_sources_like(
      safe_sources,
      c("lab", "laborator", "npu", "prove", "analysis", "result", "biochemistry")
    ), max_rows = 150),
    panels = public_rows(review_panel_index(panels, c("npu", "isotype", "lab")), max_rows = 80)
  )
}

review_ehr_sections <- function(sources) {
  safe_sources <- public_sources(sources)
  list(
    sp = public_rows(review_sources_like(safe_sources, c("^sp_", "sp ")), max_rows = 150),
    sds_lpr = public_rows(review_sources_like(safe_sources, c("^sds", "^lpr", "lpr3", "sksube", "procedure")), max_rows = 150),
    daly_views = public_rows(review_sources_like(safe_sources, c("dalycare", "view_", "views", "survival")), max_rows = 150)
  )
}

review_temporal_coverage <- function(panels) {
  coverage <- panel_or_empty(panels, "atlas_temporal_coverage")
  years <- panel_or_empty(panels, "atlas_temporal_coverage_years")
  date_quality <- panel_or_empty(panels, "atlas_temporal_date_quality")
  list(
    sources = public_rows(coverage, max_rows = 500),
    years = public_rows(years, max_rows = 5000),
    summary = public_rows(review_temporal_summary(coverage, years), max_rows = 100),
    date_quality = public_rows(date_quality, max_rows = 500)
  )
}

review_spatial_coverage <- function(panels) {
  list(
    region_counts = public_rows(panel_or_empty(panels, "atlas_spatial_region_counts"), max_rows = 1000),
    region_coverage = public_rows(panel_or_empty(panels, "atlas_spatial_region_coverage"), max_rows = 500)
  )
}

review_dk_choropleth <- function(panels) {
  regions <- panel_or_empty(panels, "atlas_dk_choropleth_regions")
  map_regions <- if (is.data.frame(regions) && nrow(regions) && "map_include" %in% names(regions)) {
    regions[as.logical(regions$map_include), , drop = FALSE]
  } else {
    data.frame()
  }
  list(
    regions = public_rows(regions, max_rows = 20),
    map_regions = public_rows(map_regions, max_rows = 10)
  )
}

review_infrastructure_sections <- function(sources, checks, panels, column_profiles, run_summary = NULL,
                                        action_items = NULL,
                                        source_resolution = NULL, memory_plan = NULL,
                                        db_query_log = NULL, db_budget_actions = NULL,
                                        legacy_resource_audit = NULL,
                                        source_resolution_delta = NULL,
                                        resource_reconciliation = NULL,
                                        canonical_resource_reconciliation = NULL,
                                        current_run_source_map_audit = NULL,
                                        source_map_crosswalk = NULL,
                                        legacy_reference_vs_current = NULL) {
  safe_sources <- public_sources(sources)
  list(
    action_items = public_rows(sanitize_public_frame(action_items), max_rows = 1000),
    action_summary = public_rows(action_item_summary(action_items), max_rows = 100),
    streaming_summary = public_rows(panel_or_empty(panels, "atlas_streaming_progress_summary"), max_rows = 500),
    temporal_date_quality = public_rows(panel_or_empty(panels, "atlas_temporal_date_quality"), max_rows = 500),
    db_budget_actions = public_rows(public_db_diagnostics(db_budget_actions), max_rows = 1000),
    db_query_log = public_rows(public_db_diagnostics(db_query_log), max_rows = 3000),
    catalog = public_rows(catalog_rows(sources), max_rows = 1000),
    resource_reconciliation = public_rows(sanitize_public_frame(resource_reconciliation), max_rows = 1000),
    canonical_resource_reconciliation = public_rows(sanitize_public_frame(canonical_resource_reconciliation), max_rows = 1000),
    current_run_source_map_audit = public_rows(sanitize_public_frame(current_run_source_map_audit), max_rows = 1000),
    source_map_crosswalk = public_rows(sanitize_public_frame(source_map_crosswalk), max_rows = 1000),
    legacy_reference_vs_current = public_rows(sanitize_public_frame(legacy_reference_vs_current), max_rows = 1000),
    source_resolution_delta = public_rows(sanitize_public_frame(source_resolution_delta), max_rows = 1000),
    legacy_resource_audit = public_rows(sanitize_public_frame(legacy_resource_audit), max_rows = 1000),
    columns = public_rows(public_column_profile_rows(column_profiles), max_rows = 3000),
    column_summary = public_rows(column_profile_summary(column_profiles), max_rows = 200),
    resolution = public_rows(sanitize_public_frame(source_resolution), max_rows = 500),
    memory_plan = public_rows(sanitize_public_frame(memory_plan), max_rows = 500),
    skipped_sources = public_rows(review_sources_by_status(safe_sources, c("skipped", "missing", "failed", "error", "unresolved")), max_rows = 500),
    panels = public_rows(panel_groups(panels), max_rows = 100),
    qa = public_rows(qa_items(checks), max_rows = 500),
    run_summary = public_rows(run_summary, max_rows = 100)
  )
}

review_temporal_summary <- function(coverage, years) {
  if (!is.data.frame(coverage) || !nrow(coverage)) return(data.frame())
  has_years <- is.data.frame(years) && nrow(years)
  out <- aggregate(
    list(n_sources = coverage$table_name),
    by = list(domain = coverage$domain),
    FUN = length
  )
  available <- coverage[!is.na(coverage$display_min_year) & !is.na(coverage$display_max_year), , drop = FALSE]
  min_year <- if (nrow(available)) {
    aggregate(display_min_year ~ domain, data = available, FUN = min)
  } else {
    data.frame(domain = character(), display_min_year = integer())
  }
  max_year <- if (nrow(available)) {
    aggregate(display_max_year ~ domain, data = available, FUN = max)
  } else {
    data.frame(domain = character(), display_max_year = integer())
  }
  out <- merge(out, min_year, by = "domain", all.x = TRUE)
  out <- merge(out, max_year, by = "domain", all.x = TRUE)
  out$n_year_rows <- if (has_years) {
    counts <- aggregate(year ~ domain, data = years, FUN = length)
    counts$year[match(out$domain, counts$domain)]
  } else {
    0L
  }
  out
}

review_registry_panel_bundle <- function(panels, registry) {
  registry <- tolower(registry)
  matched <- panels[grepl(registry, tolower(names(panels)), fixed = TRUE)]
  if (!length(matched)) return(list())
  out <- lapply(matched, function(panel) public_rows(panel, max_rows = 100))
  names(out) <- names(matched)
  out
}

review_panel_index <- function(panels, patterns) {
  if (!length(panels)) return(data.frame())
  panel_names <- names(panels)
  matched <- Reduce(`|`, lapply(patterns, function(pattern) {
    grepl(pattern, panel_names, ignore.case = TRUE)
  }))
  if (!any(matched)) return(data.frame())
  data.frame(
    panel = panel_names[matched],
    title = vapply(panel_names[matched], panel_title, character(1), USE.NAMES = FALSE),
    rows = vapply(panels[matched], nrow, integer(1)),
    group = vapply(panel_names[matched], panel_group, character(1), USE.NAMES = FALSE),
    stringsAsFactors = FALSE
  )
}

review_source_availability <- function(sources) {
  if (!is.data.frame(sources) || !nrow(sources)) return(data.frame())
  domain <- if ("domain" %in% names(sources)) sources$domain else rep("", nrow(sources))
  subdomain <- if ("subdomain" %in% names(sources)) sources$subdomain else rep("", nrow(sources))
  status <- if ("status" %in% names(sources)) sources$status else if ("load_status" %in% names(sources)) sources$load_status else rep("", nrow(sources))
  key <- data.frame(
    domain = replace_empty(domain, "Unassigned"),
    subdomain = replace_empty(subdomain, "Unassigned"),
    status = replace_empty(status, "unknown"),
    stringsAsFactors = FALSE
  )
  out <- aggregate(rep(1L, nrow(key)), key, sum)
  names(out) <- c("domain", "subdomain", "status", "n_sources")
  out
}

review_largest_sources <- function(sources) {
  if (!is.data.frame(sources) || !nrow(sources)) return(data.frame())
  rows <- numeric_or_zero(if ("n_rows" %in% names(sources)) sources$n_rows else rep(NA, nrow(sources)))
  out <- sources
  out$n_rows_sort <- rows
  out <- out[order(out$n_rows_sort, decreasing = TRUE, na.last = TRUE), , drop = FALSE]
  keep <- intersect(c("table_name", "status", "load_status", "domain", "subdomain", "atlas_role", "n_rows", "n_cols", "min_date", "max_date"), names(out))
  out <- out[seq_len(min(20, nrow(out))), keep, drop = FALSE]
  out
}

review_sources_like <- function(sources, patterns) {
  if (!is.data.frame(sources) || !nrow(sources)) return(data.frame())
  search_cols <- intersect(c("table_name", "domain", "subdomain", "atlas_role"), names(sources))
  haystack <- if (length(search_cols)) {
    apply(sources[, search_cols, drop = FALSE], 1, paste, collapse = " ")
  } else {
    rep("", nrow(sources))
  }
  matched <- Reduce(`|`, lapply(patterns, function(pattern) {
    grepl(pattern, haystack, ignore.case = TRUE, perl = TRUE)
  }))
  out <- sources[matched, , drop = FALSE]
  if (!nrow(out)) return(data.frame())
  keep <- intersect(c("table_name", "status", "load_status", "domain", "subdomain", "atlas_role", "n_rows", "n_cols", "min_date", "max_date"), names(out))
  out[, keep, drop = FALSE]
}

review_sources_by_status <- function(sources, patterns) {
  if (!is.data.frame(sources) || !nrow(sources)) return(data.frame())
  status <- paste(
    if ("status" %in% names(sources)) sources$status else "",
    if ("load_status" %in% names(sources)) sources$load_status else ""
  )
  matched <- Reduce(`|`, lapply(patterns, function(pattern) {
    grepl(pattern, status, ignore.case = TRUE)
  }))
  out <- sources[matched, , drop = FALSE]
  if (!nrow(out)) return(data.frame())
  keep <- intersect(c("table_name", "status", "load_status", "domain", "subdomain", "atlas_role", "n_rows", "n_cols"), names(out))
  out[, keep, drop = FALSE]
}

atlas_module_readiness <- function(sources, panels = list()) {
  specs <- list(
    list("Overview", "Temporal coverage", c("date", "dt", "dato", "time"), c("atlas_temporal")),
    list("Overview", "Regional coverage", c("region", "shak", "organisation", "hospital"), c("atlas_spatial", "choropleth")),
    list("Disease Registries", "DaMyDa registry", c("damyda", "myeloma"), c("damyda", "registry_clinical")),
    list("Disease Registries", "LYFO registry", c("lyfo", "lymphoma"), c("lyfo", "registry_clinical")),
    list("Disease Registries", "CLL registry", c("cll", "dcllr"), c("cll", "registry_clinical")),
    list("Clinical Data", "Diagnoses and tumors", c("diagnos", "diag", "cancer", "tumor"), c("diagnos")),
    list("Clinical Data", "Admissions and ADT", c("adt", "adm", "kontakt", "contact", "skadestue", "icu"), c("situation_report")),
    list("Laboratory & Diagnostics", "Imaging and radiotherapy diagnostics", c("billed", "imaging", "image", "radiolog", "scan", "ct", "mr", "bwgc"), character()),
    list("Clinical Data", "Vitals", c("vital", "vaegt", "weight", "height", "bloodpressure"), character()),
    list("Clinical Data", "Notes", c("note", "journal", "epikur", "text"), character()),
    list("Clinical Data", "Social history", c("social", "smoking", "alcohol"), character()),
    list("Treatment", "MM treatment codes", c("behandling", "treatment", "procedure", "sks", "plan"), c("mm_treatment")),
    list("Treatment", "Medicine and ATC", c("medicin", "medicine", "atc", "ordered", "administered"), c("treatment")),
    list("Laboratory & Diagnostics", "NPU dictionary", c("lab", "laborator", "npu", "prove", "analysis", "result"), c("npu_dictionary", "npu_lab")),
    list("Laboratory & Diagnostics", "NPU detective", c("lab", "npu", "analysis"), c("npu_detective")),
    list("Laboratory & Diagnostics", "Isotype finder", c("isotype", "mspike", "m_component", "lab", "npu"), c("isotype")),
    list("Laboratory & Diagnostics", "Microbiology / MiBa diagnostics", c("microbiology", "miba", "culture", "resistance", "susceptibility"), character()),
    list("Laboratory & Diagnostics", "Pathology / PATOBANK diagnostics", c("molecular", "patholog", "pato", "snomed", "biopsy"), character()),
    list("Laboratory & Diagnostics", "Molecular, pathology, and biobank readiness", c("molecular", "patholog", "pato", "biobank", "snomed"), character()),
    list("EHR Modules", "SP modules", c("^sp_", "sp "), character()),
    list("EHR Modules", "SDS/LPR modules", c("^sds", "^lpr", "lpr3", "sksube", "procedure"), character()),
    list("EHR Modules", "DALY views", c("dalycare", "view_", "views", "survival"), character()),
    list("Infrastructure", "Resolution and DB streaming", c(""), c("source_availability_drift", "atlas_streaming_progress_summary", "atlas_module_readiness"))
  )
  rows <- lapply(specs, function(spec) {
    atlas_module_readiness_row(
      sources = sources,
      panels = panels,
      domain = spec[[1]],
      module = spec[[2]],
      source_patterns = spec[[3]],
      panel_patterns = spec[[4]]
    )
  })
  bind_rows_base(rows)
}

atlas_module_readiness_row <- function(sources, panels, domain, module, source_patterns, panel_patterns) {
  matched_sources <- if (identical(source_patterns, c(""))) {
    sources
  } else {
    review_sources_like(public_sources(sources), source_patterns)
  }
  source_count <- if (is.data.frame(matched_sources)) nrow(matched_sources) else 0L
  load_status <- if (source_count && "load_status" %in% names(matched_sources)) matched_sources$load_status else character()
  loaded_count <- sum(load_status == "ok", na.rm = TRUE)
  n_rows <- if (source_count && "n_rows" %in% names(matched_sources)) sum(suppressWarnings(as.numeric(matched_sources$n_rows)), na.rm = TRUE) else 0
  n_columns <- if (source_count && "n_cols" %in% names(matched_sources)) sum(suppressWarnings(as.numeric(matched_sources$n_cols)), na.rm = TRUE) else 0
  min_dates <- if (source_count && "min_date" %in% names(matched_sources)) unique_nonblank(matched_sources$min_date) else character()
  max_dates <- if (source_count && "max_date" %in% names(matched_sources)) unique_nonblank(matched_sources$max_date) else character()
  evidence_panels <- atlas_matching_panel_names(panels, panel_patterns)
  status <- if (loaded_count > 0 && length(evidence_panels)) {
    "panel_ready"
  } else if (loaded_count > 0) {
    "source_ready"
  } else if (source_count > 0) {
    "mapped_not_loaded"
  } else if (length(evidence_panels)) {
    "panel_only"
  } else {
    "not_mapped"
  }
  message <- switch(
    status,
    panel_ready = "Source metadata and dedicated aggregate panels are available.",
    source_ready = "Source metadata is available; a dedicated clinical panel is not yet generated.",
    mapped_not_loaded = "Sources were mapped but not loaded in this run.",
    panel_only = "A derived panel exists but no matching source-card source was identified.",
    not_mapped = "No matching protected source evidence was available in this run.",
    "Review status unavailable."
  )
  data.frame(
    domain = domain,
    module = module,
    status = status,
    source_count = source_count,
    loaded_count = loaded_count,
    n_rows = n_rows,
    n_columns = n_columns,
    date_min = if (length(min_dates)) min(min_dates, na.rm = TRUE) else "",
    date_max = if (length(max_dates)) max(max_dates, na.rm = TRUE) else "",
    evidence_panels = paste(evidence_panels, collapse = ", "),
    message = message,
    stringsAsFactors = FALSE
  )
}

atlas_matching_panel_names <- function(panels, patterns) {
  if (!length(patterns) || !length(panels)) return(character())
  panel_names <- names(panels)
  matched <- Reduce(`|`, lapply(patterns, function(pattern) {
    grepl(pattern, panel_names, ignore.case = TRUE)
  }))
  panel_names[matched]
}

panel_or_empty <- function(panels, name) {
  if (is.list(panels) && name %in% names(panels)) return(sanitize_public_frame(panels[[name]]))
  data.frame()
}

replace_empty <- function(x, replacement) {
  x <- as.character(x)
  x[is.na(x) | !nzchar(x)] <- replacement
  x
}

numeric_or_zero <- function(x) {
  out <- suppressWarnings(as.numeric(x))
  out[is.na(out)] <- 0
  out
}

basic_column_profiles <- function(columns) {
  if (!is.data.frame(columns) || !nrow(columns)) return(empty_column_profiles())
  get_col <- function(name, default) {
    if (name %in% names(columns)) columns[[name]] else rep(default, nrow(columns))
  }
  is_sensitive <- as.logical(get_col("is_sensitive", FALSE))
  is_date_like <- as.logical(get_col("is_date_like", FALSE))
  is_numeric_like <- as.logical(get_col("is_numeric_like", FALSE))
  out <- data.frame(
    table_name = get_col("table_name", ""),
    column_name = get_col("column_name", ""),
    column_type = get_col("column_type", ""),
    column_class = get_col("column_class", ""),
    profile_kind = ifelse(is_sensitive, "sensitive", ifelse(is_date_like, "date", ifelse(is_numeric_like, "numeric", "categorical"))),
    n_rows = NA_integer_,
    n_available = NA_integer_,
    pct_available = NA_real_,
    n_missing = get_col("n_missing", NA_integer_),
    pct_missing = get_col("pct_missing", NA_real_),
    n_distinct_capped = get_col("n_distinct_capped", NA_integer_),
    is_sensitive = is_sensitive,
    is_date_like = is_date_like,
    is_numeric_like = is_numeric_like,
    min = NA_real_,
    mean = NA_real_,
    median = NA_real_,
    p25 = NA_real_,
    p75 = NA_real_,
    max = NA_real_,
    min_date = NA_character_,
    max_date = NA_character_,
    stringsAsFactors = FALSE
  )
  out
}

hero_metrics <- function(sources, columns, checks, run_summary = NULL) {
  run_values <- if (is.data.frame(run_summary) && nrow(run_summary) && all(c("metric", "value") %in% names(run_summary))) {
    stats::setNames(run_summary$value, run_summary$metric)
  } else {
    character()
  }
  n_rows_total <- sum(suppressWarnings(as.numeric(sources$n_rows)), na.rm = TRUE)
  n_rows_value <- named_value(run_values, "total_rows", as.character(n_rows_total))
  min_cell_count <- named_value(run_values, "min_cell_count", as.character(atlas_min_cell_count()))
  if ("canonical_resources_total" %in% names(run_values) || "canonical_expected_resources" %in% names(run_values)) {
    total <- named_value(run_values, "canonical_resources_total", named_value(run_values, "canonical_expected_resources", "64"))
    accounted <- named_value(run_values, "canonical_resources_accounted_for", total)
    db_total <- named_value(run_values, "db_attemptable_canonical_resources", "")
    db_profiled <- named_value(run_values, "db_attemptable_profiled_resources", "")
    db_value <- if (nzchar(db_total) && nzchar(db_profiled)) paste0(db_profiled, " / ", db_total) else db_profiled
    source_total <- named_value(run_values, "source_map_rows_total", as.character(nrow(sources)))
    source_profiled <- named_value(run_values, "source_map_rows_profiled", as.character(sum(sources$load_status == "ok", na.rm = TRUE)))
    source_value <- if (nzchar(source_total) && nzchar(source_profiled)) paste0(source_profiled, " / ", source_total) else source_profiled
    return(data.frame(
      metric = c(
        "canonical_resources_accounted_for", "db_attemptable_profiled_resources",
        "special_manual_or_embedded_resources", "unexpected_missing_canonical_resources",
        "source_map_rows_profiled", "columns", "non_blocking_warnings", "min_cell_count"
      ),
      label = c(
        "Canonical resources accounted for", "DB-attemptable canonical resources profiled",
        "Special/manual/embedded resources", "Unexpected missing resources",
        "Source-map rows profiled", "Columns profiled", "Non-blocking notes", "Minimum cell count"
      ),
      value = c(
        paste0(accounted, " / ", total),
        db_value,
        named_value(run_values, "special_manual_or_embedded_resources", "0"),
        named_value(run_values, "unexpected_missing_canonical_resources", named_value(run_values, "canonical_current_missing_after_attempt_resources", "0")),
        source_value,
        nrow(columns),
        named_value(run_values, "non_blocking_warnings", as.character(sum(checks$severity %in% c("warning", "manual_note", "info"), na.rm = TRUE))),
        min_cell_count
      ),
      tone = c("good", "good", "neutral", "good", "neutral", "neutral", "warn", "neutral"),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    metric = c(
      "mapped_sources", "loaded_sources", "failed_sources", "rows",
      "columns", "warnings", "errors", "min_cell_count"
    ),
    label = c(
      "Mapped sources", "Loaded sources", "Failed sources", "Rows profiled",
      "Columns profiled", "Warnings", "Errors", "Minimum cell count"
    ),
    value = c(
      nrow(sources),
      sum(sources$load_status == "ok", na.rm = TRUE),
      sum(sources$load_status == "failed", na.rm = TRUE),
      n_rows_value,
      nrow(columns),
      sum(checks$severity == "warning", na.rm = TRUE),
      sum(checks$severity == "error", na.rm = TRUE),
      min_cell_count
    ),
    tone = c("neutral", "good", "bad", "neutral", "neutral", "warn", "bad", "neutral"),
    stringsAsFactors = FALSE
  )
}

domain_cards <- function(sources) {
  if (!nrow(sources)) {
    return(empty_df(
      domain = character(), subdomains = character(), atlas_roles = character(),
      n_sources = integer(), loaded_sources = integer(), failed_sources = integer(),
      n_rows = numeric(), n_cols = numeric()
    ))
  }
  domain <- if ("domain" %in% names(sources)) sources$domain else rep("Unassigned", nrow(sources))
  domain[is.na(domain) | domain == ""] <- "Unassigned"
  rows <- lapply(sort(unique(domain)), function(group) {
    ix <- which(domain == group)
    subdomains <- if ("subdomain" %in% names(sources)) unique_nonblank(sources$subdomain[ix]) else character()
    roles <- if ("atlas_role" %in% names(sources)) unique_nonblank(sources$atlas_role[ix]) else character()
    data.frame(
      domain = group,
      subdomains = paste(subdomains, collapse = ", "),
      atlas_roles = paste(roles, collapse = ", "),
      n_sources = length(ix),
      loaded_sources = sum(sources$load_status[ix] == "ok", na.rm = TRUE),
      failed_sources = sum(sources$load_status[ix] == "failed", na.rm = TRUE),
      n_rows = sum(suppressWarnings(as.numeric(sources$n_rows[ix])), na.rm = TRUE),
      n_cols = sum(suppressWarnings(as.numeric(sources$n_cols[ix])), na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(out)
  out[order(-out$loaded_sources, out$domain), , drop = FALSE]
}

catalog_rows <- function(sources) {
  if (!nrow(sources)) {
    return(empty_df(
      table_name = character(), domain = character(), subdomain = character(),
      atlas_role = character(), source_type = character(), source = character(),
      profile_mode = character(), load_status = character(), chosen_strategy = character(),
      memory_status = character(), resolution_status = character(), n_rows = numeric(),
      n_cols = numeric(), date_range = character(), message = character()
    ))
  }
  get_col <- function(name, default = "") {
    if (name %in% names(sources)) sources[[name]] else rep(default, nrow(sources))
  }
  min_date <- get_col("min_date")
  max_date <- get_col("max_date")
  date_range <- ifelse(nzchar(min_date) & nzchar(max_date), paste(min_date, max_date, sep = " to "), "")
  data.frame(
    table_name = get_col("table_name"),
    domain = get_col("domain", "Unassigned"),
    subdomain = get_col("subdomain"),
    atlas_role = get_col("atlas_role"),
    source_type = get_col("source_type"),
    source = get_col("source"),
    profile_mode = get_col("profile_mode"),
    load_status = get_col("load_status"),
    chosen_strategy = get_col("chosen_strategy"),
    memory_status = get_col("memory_status"),
    resolution_status = get_col("resolution_status"),
    n_rows = suppressWarnings(as.numeric(get_col("n_rows", NA))),
    n_cols = suppressWarnings(as.numeric(get_col("n_cols", NA))),
    date_range = date_range,
    message = redact_sensitive_text(get_col("message")),
    stringsAsFactors = FALSE
  )
}

qa_items <- function(checks) {
  if (!nrow(checks)) {
    return(empty_df(severity = character(), table_name = character(), check_id = character(), message = character()))
  }
  out <- sanitize_public_frame(checks[, intersect(c("severity", "table_name", "check_id", "message"), names(checks)), drop = FALSE])
  rank <- severity_rank(out$severity)
  out[order(rank, out$table_name, out$check_id), , drop = FALSE]
}

registry_cards <- function(panels) {
  summary <- panels$registry_clinical_summary %||% empty_registry_summary()
  if (!is.data.frame(summary) || !nrow(summary)) return(list())
  registries <- unique(summary$registry)
  registries <- registries[nzchar(registries)]
  cards <- lapply(registries, function(registry) {
    summary_row <- summary[summary$registry == registry, , drop = FALSE][1, , drop = FALSE]
    categorical <- registry_panel_for(panels, registry)
    numeric <- if (identical(registry, "DaMyDa")) panels$damyda_numeric_fields %||% empty_registry_numeric() else empty_registry_numeric()
    numeric <- numeric[numeric$registry == registry, , drop = FALSE]
    list(
      registry = registry,
      table_name = as.character(summary_row$table_name[[1]] %||% ""),
      n_rows = as.character(summary_row$n_rows[[1]] %||% ""),
      n_cols = as.character(summary_row$n_cols[[1]] %||% ""),
      n_patients = as.character(summary_row$n_patients[[1]] %||% ""),
      date_range = compact_date_range(summary_row$min_date[[1]] %||% "", summary_row$max_date[[1]] %||% ""),
      facets = public_rows(top_registry_facets(categorical), max_rows = 40),
      numeric_fields = public_rows(top_registry_numeric(numeric), max_rows = 20)
    )
  })
  names(cards) <- registries
  cards
}

npu_cards <- function(panels) {
  summary <- panels$npu_dictionary_summary %||% empty_npu_dictionary_summary()
  vectors <- panels$npu_dictionary_vectors %||% empty_npu_dictionary_vectors()
  usage <- panels$npu_lab_usage_by_vector %||% empty_npu_lab_usage_by_vector()
  unmatched <- panels$npu_lab_unmatched_codes %||% empty_npu_lab_unmatched_codes()
  if (!is.data.frame(summary)) summary <- empty_npu_dictionary_summary()
  if (!is.data.frame(vectors)) vectors <- empty_npu_dictionary_vectors()
  if (!is.data.frame(usage)) usage <- empty_npu_lab_usage_by_vector()
  if (!is.data.frame(unmatched)) unmatched <- empty_npu_lab_unmatched_codes()
  vectors <- vectors[order(-suppressWarnings(as.numeric(vectors$n_dictionary_codes)), vectors$consensus_vector), , drop = FALSE]
  usage <- usage[order(-suppressWarnings(as.numeric(usage$n_observed)), usage$consensus_vector), , drop = FALSE]
  unmatched <- unmatched[order(-suppressWarnings(as.numeric(unmatched$n_observed)), unmatched$npu_code), , drop = FALSE]
  list(
    summary = public_rows(summary, max_rows = 20),
    top_vectors = public_rows(head(vectors, 15L), max_rows = 15),
    observed_vectors = public_rows(head(usage, 15L), max_rows = 15),
    unmatched_codes = public_rows(head(unmatched, 15L), max_rows = 15)
  )
}

detective_cards <- function(panels) {
  inventory <- panels$npu_detective_code_inventory %||% empty_npu_detective_code_inventory()
  candidates <- panels$npu_detective_candidates %||% empty_npu_detective_candidates()
  source_year <- panels$npu_detective_source_year %||% empty_npu_detective_source_year()
  if (!is.data.frame(inventory)) inventory <- empty_npu_detective_code_inventory()
  if (!is.data.frame(candidates)) candidates <- empty_npu_detective_candidates()
  if (!is.data.frame(source_year)) source_year <- empty_npu_detective_source_year()
  inventory <- inventory[order(-suppressWarnings(as.numeric(inventory$n_observed)), inventory$npu_code), , drop = FALSE]
  candidates <- candidates[order(-suppressWarnings(as.numeric(candidates$n_observed)), candidates$npu_code), , drop = FALSE]
  list(
    observed_codes = public_rows(head(inventory, 15L), max_rows = 15),
    candidate_codes = public_rows(head(candidates, 15L), max_rows = 15),
    source_year = public_rows(head(source_year[order(source_year$year, -suppressWarnings(as.numeric(source_year$n_observed))), , drop = FALSE], 20L), max_rows = 20)
  )
}

isotype_cards <- function(panels) {
  usage <- panels$isotype_code_usage %||% empty_isotype_code_usage()
  buckets <- panels$isotype_bucket_summary %||% empty_isotype_bucket_summary()
  if (!is.data.frame(usage)) usage <- empty_isotype_code_usage()
  if (!is.data.frame(buckets)) buckets <- empty_isotype_bucket_summary()
  usage <- usage[order(-suppressWarnings(as.numeric(usage$n_observed)), usage$isotype_family), , drop = FALSE]
  buckets <- buckets[order(-suppressWarnings(as.numeric(buckets$n_rows)), buckets$bucket, buckets$isotype_family), , drop = FALSE]
  list(
    code_usage = public_rows(head(usage, 15L), max_rows = 15),
    bucket_summary = public_rows(head(buckets, 15L), max_rows = 15)
  )
}

treatment_cards <- function(panels) {
  counts <- panels$mm_treatment_code_counts %||% empty_mm_treatment_code_counts()
  summary <- panels$mm_treatment_source_summary %||% empty_mm_treatment_source_summary()
  if (!is.data.frame(counts)) counts <- empty_mm_treatment_code_counts()
  if (!is.data.frame(summary)) summary <- empty_mm_treatment_source_summary()
  counts <- counts[order(-suppressWarnings(as.numeric(counts$n_rows)), counts$family, counts$code), , drop = FALSE]
  summary <- summary[order(-suppressWarnings(as.numeric(summary$matched_rows)), summary$table_name), , drop = FALSE]
  list(
    code_families = public_rows(head(counts, 15L), max_rows = 15),
    source_summary = public_rows(head(summary, 15L), max_rows = 15)
  )
}

situation_report_cards <- function(panels) {
  public_rows(panel_or_empty(panels, "situation_report_summary"), max_rows = 100)
}

registry_panel_for <- function(panels, registry) {
  panel_name <- switch(
    registry,
    "DaMyDa" = "damyda_clinical_profile",
    "LYFO" = "lyfo_clinical_profile",
    "CLL" = "cll_clinical_profile",
    NA_character_
  )
  if (is.na(panel_name) || is.null(panels[[panel_name]]) || !is.data.frame(panels[[panel_name]])) {
    return(empty_registry_categorical())
  }
  panels[[panel_name]][panels[[panel_name]]$registry == registry, , drop = FALSE]
}

top_registry_facets <- function(panel) {
  if (!is.data.frame(panel) || !nrow(panel)) {
    return(empty_df(facet = character(), source_column = character(), label = character(), n = integer(), pct_rows = numeric()))
  }
  panel <- sanitize_public_frame(panel)
  rows <- list()
  for (facet in unique(panel$facet)) {
    facet_rows <- panel[panel$facet == facet, , drop = FALSE]
    facet_rows <- facet_rows[order(-suppressWarnings(as.numeric(facet_rows$n)), facet_rows$label), , drop = FALSE]
    rows[[length(rows) + 1L]] <- head(facet_rows, 5L)
  }
  out <- bind_rows_base(rows)
  out[, intersect(c("facet", "source_column", "label", "n", "pct_rows"), names(out)), drop = FALSE]
}

top_registry_numeric <- function(panel) {
  if (!is.data.frame(panel) || !nrow(panel)) {
    return(empty_df(field = character(), source_column = character(), unit = character(), n_available = integer(), median = numeric(), p25 = numeric(), p75 = numeric()))
  }
  out <- sanitize_public_frame(panel)
  out <- out[order(-suppressWarnings(as.numeric(out$n_available)), out$field), , drop = FALSE]
  out <- head(out, 12L)
  out[, intersect(c("field", "source_column", "unit", "n_available", "median", "p25", "p75"), names(out)), drop = FALSE]
}

panel_groups <- function(panels) {
  if (!length(panels)) {
    return(empty_df(group = character(), panel_name = character(), title = character(), n_rows = integer()))
  }
  data.frame(
    group = vapply(names(panels), panel_group, character(1)),
    panel_name = names(panels),
    title = vapply(names(panels), panel_title, character(1)),
    n_rows = vapply(panels, function(x) if (is.data.frame(x)) nrow(x) else 0L, integer(1)),
    stringsAsFactors = FALSE
  )
}

panel_title <- function(name) {
  titles <- c(
    lab_npu_code_coverage = "Lab NPU Code Coverage",
    npu_dictionary_summary = "NPU Dictionary Summary",
    npu_dictionary_vectors = "NPU Dictionary Vectors",
    npu_lab_usage_by_vector = "NPU Lab Usage By Vector",
    npu_lab_unmatched_codes = "NPU Lab Unmatched Codes",
    npu_detective_code_inventory = "NPU Detective Code Inventory",
    npu_detective_candidates = "NPU Detective Candidates",
    npu_detective_source_year = "NPU Detective Source-Year Usage",
    isotype_code_usage = "Isotype Code Usage",
    isotype_bucket_summary = "Isotype Bucket Summary",
    mm_treatment_code_counts = "MM Treatment Code Counts",
    mm_treatment_source_summary = "MM Treatment Source Summary",
    diagnosis_icd_groups = "Diagnosis ICD Groups",
    medication_atc_groups = "Medication ATC Groups",
    damyda_feature_coverage = "DaMyDa Feature Coverage",
    registry_clinical_summary = "Registry Clinical Summary",
    damyda_clinical_profile = "DaMyDa Clinical Profile",
    damyda_numeric_fields = "DaMyDa Numeric Fields",
    lyfo_clinical_profile = "LYFO Clinical Profile",
    cll_clinical_profile = "CLL Clinical Profile",
    sp_operational_sources = "SP Operational Sources",
    atlas_temporal_coverage = "Temporal Coverage",
    atlas_temporal_coverage_years = "Temporal Coverage By Year",
    atlas_temporal_date_quality = "Temporal Date Quality",
    atlas_spatial_region_counts = "Spatial Region Counts",
    atlas_spatial_region_coverage = "Spatial Region Coverage",
    atlas_dk_choropleth_regions = "Denmark Choropleth Regions",
    atlas_streaming_progress_summary = "DB Streaming Progress Summary",
    situation_report_summary = "Situation Report Summary",
    situation_report_breakdowns = "Situation Report Breakdowns",
    situation_report_freshness = "Situation Report Freshness",
    source_availability_drift = "Source Availability Drift"
  )
  named_value(titles, name, title_from_name(name))
}

panel_group <- function(name) {
  groups <- c(
    lab_npu_code_coverage = "Source Content",
    npu_dictionary_summary = "Source Content",
    npu_dictionary_vectors = "Source Content",
    npu_lab_usage_by_vector = "Source Content",
    npu_lab_unmatched_codes = "Source Content",
    npu_detective_code_inventory = "NPU Detective",
    npu_detective_candidates = "NPU Detective",
    npu_detective_source_year = "NPU Detective",
    isotype_code_usage = "Isotype Finder",
    isotype_bucket_summary = "Isotype Finder",
    mm_treatment_code_counts = "MM Treatment Codes",
    mm_treatment_source_summary = "MM Treatment Codes",
    diagnosis_icd_groups = "Source Content",
    medication_atc_groups = "Source Content",
    damyda_feature_coverage = "Clinical Registries",
    registry_clinical_summary = "Clinical Registries",
    damyda_clinical_profile = "Clinical Registries",
    damyda_numeric_fields = "Clinical Registries",
    lyfo_clinical_profile = "Clinical Registries",
    cll_clinical_profile = "Clinical Registries",
    sp_operational_sources = "SP Operations",
    atlas_temporal_coverage = "Coverage Figures",
    atlas_temporal_coverage_years = "Coverage Figures",
    atlas_temporal_date_quality = "Coverage Figures",
    atlas_spatial_region_counts = "Coverage Figures",
    atlas_spatial_region_coverage = "Coverage Figures",
    atlas_dk_choropleth_regions = "Coverage Figures",
    atlas_streaming_progress_summary = "Run QA",
    situation_report_summary = "Situation Report",
    situation_report_breakdowns = "Situation Report",
    situation_report_freshness = "Situation Report",
    source_availability_drift = "Run QA"
  )
  named_value(groups, name, "Atlas Panels")
}

public_column_profile_rows <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(empty_column_profiles())
  out <- sanitize_public_frame(column_profiles)
  if ("is_sensitive" %in% names(out) && "column_name" %in% names(out)) {
    sensitive <- as.logical(out$is_sensitive)
    sensitive[is.na(sensitive)] <- FALSE
    sensitive <- sensitive | vapply(out$column_name, is_public_identifier_column, logical(1))
    out$is_sensitive <- sensitive
    if ("profile_kind" %in% names(out)) out$profile_kind[sensitive] <- "sensitive"
    if ("is_numeric_like" %in% names(out)) out$is_numeric_like[sensitive] <- FALSE
    if ("is_date_like" %in% names(out)) out$is_date_like[sensitive] <- FALSE
    for (nm in intersect(c("min", "mean", "median", "p25", "p75", "max", "min_date", "max_date"), names(out))) {
      out[[nm]][sensitive] <- NA
    }
    out$column_name[sensitive] <- "[sensitive]"
  }
  out
}

public_db_diagnostics <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows)) return(rows)
  out <- sanitize_public_frame(rows)
  if ("column_name" %in% names(out)) {
    sensitive <- vapply(out$column_name, is_public_identifier_column, logical(1))
    out$column_name[sensitive] <- "[sensitive]"
  }
  out
}

is_public_identifier_column <- function(name) {
  name <- tolower(as.character(name %||% ""))
  grepl(
    paste(
      c(
        "^id$", "(^|_)id($|_)", "_id$", "identifier", "uuid", "guid",
        "(^|_)key($|_)", "record_id", "order_med_id", "contact_serial",
        "recnum", "recordnum", "record_number", "pat_id", "person", "patient",
        "borger", "cpr", "pnr", "civil"
      ),
      collapse = "|"
    ),
    name,
    ignore.case = TRUE
  )
}

column_profile_summary <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) {
    return(empty_df(domain = character(), profile_kind = character(), n_columns = integer()))
  }
  domain <- if ("domain" %in% names(column_profiles)) column_profiles$domain else rep("Unassigned", nrow(column_profiles))
  domain[is.na(domain) | domain == ""] <- "Unassigned"
  profile_kind <- if ("profile_kind" %in% names(column_profiles)) column_profiles$profile_kind else rep("unknown", nrow(column_profiles))
  aggregate(
    list(n_columns = column_profiles$table_name),
    by = list(domain = domain, profile_kind = profile_kind),
    FUN = length
  )
}

public_sources <- function(sources) {
  if (!nrow(sources)) return(sources)
  sources[, intersect(
    c(
      "table_name", "source_type", "source", "domain", "subdomain", "atlas_role",
      "profile_mode", "load_status", "chosen_strategy", "memory_status",
      "resolution_status", "n_rows", "n_cols", "min_date", "max_date", "message"
    ),
    names(sources)
  ), drop = FALSE]
}

source_domain_summary <- function(sources) {
  if (!nrow(sources) || !"domain" %in% names(sources)) {
    return(empty_df(domain = character(), subdomain = character(), atlas_role = character(), load_status = character(), n_sources = integer()))
  }
  domain <- sources$domain %||% rep("", nrow(sources))
  subdomain <- if ("subdomain" %in% names(sources)) sources$subdomain else rep("", nrow(sources))
  atlas_role <- if ("atlas_role" %in% names(sources)) sources$atlas_role else rep("", nrow(sources))
  aggregate(
    list(n_sources = sources$table_name),
    by = list(
      domain = domain,
      subdomain = subdomain,
      atlas_role = atlas_role,
      load_status = sources$load_status
    ),
    FUN = length
  )
}

public_rows <- function(x, max_rows = 200) {
  if (is.null(x) || !is.data.frame(x) || !nrow(x)) return(list())
  x <- head(x, max_rows)
  lapply(seq_len(nrow(x)), function(i) {
    row <- as.list(x[i, , drop = FALSE])
    lapply(row, function(value) {
      if (length(value) == 0 || is.na(value)) NULL else as.character(value)
    })
  })
}

sanitize_public_frame <- function(x) {
  if (!is.data.frame(x) || !nrow(x)) return(x)
  x <- x[, !vapply(names(x), is_sensitive_payload_column, logical(1)), drop = FALSE]
  for (nm in names(x)) {
    if (is.character(x[[nm]])) x[[nm]] <- redact_sensitive_text(x[[nm]])
  }
  x
}

is_sensitive_payload_column <- function(name) {
  grepl(
    "id_column_guess|schema_signature|patientid|patient_id|person_key|cpr|pnr|raw_date|raw_text|snippet|requisition",
    name,
    ignore.case = TRUE
  )
}

redact_sensitive_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- NA_character_
  pattern <- paste(
    c(
      "\\bpatientid\\b", "patient[_ -]?id", "\\bcpr\\b", "personnummer",
      "person[_ -]?id", "borger", "dw_ek_borger", "\\bpnr\\b",
      "civil", "socialsecurity", "\\bssn\\b"
    ),
    collapse = "|"
  )
  gsub(pattern, "[sensitive]", x, ignore.case = TRUE)
}

severity_rank <- function(severity) {
  severity <- tolower(as.character(severity))
  out <- rep(9L, length(severity))
  out[severity == "error"] <- 1L
  out[severity == "unexpected_failure"] <- 1L
  out[severity == "warning"] <- 2L
  out[severity == "manual_note"] <- 3L
  out[severity == "info"] <- 4L
  out[severity == "ok"] <- 5L
  out
}

unique_nonblank <- function(x) {
  x <- trimws(as.character(x))
  sort(unique(x[!(is.na(x) | x == "")]))
}

compact_date_range <- function(min_date, max_date) {
  min_date <- as.character(min_date %||% "")
  max_date <- as.character(max_date %||% "")
  if (nzchar(min_date) && nzchar(max_date)) return(paste(min_date, max_date, sep = " to "))
  if (nzchar(min_date)) return(min_date)
  if (nzchar(max_date)) return(max_date)
  ""
}

title_from_name <- function(name) {
  words <- strsplit(gsub("_", " ", name), " ", fixed = TRUE)[[1]]
  paste(vapply(words, function(word) {
    if (!nzchar(word)) return(word)
    paste0(toupper(substr(word, 1L, 1L)), substr(word, 2L, nchar(word)))
  }, character(1)), collapse = " ")
}

named_value <- function(x, name, default = "") {
  if (is.null(x) || !length(x) || is.null(names(x)) || !name %in% names(x)) return(default)
  value <- x[[name]]
  if (is.null(value) || length(value) == 0 || is.na(value)) return(default)
  value
}
