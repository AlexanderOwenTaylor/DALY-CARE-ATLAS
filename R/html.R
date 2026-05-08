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

atlas_payload <- function(run_id, generated_at, sources, columns, checks, panels, run_summary = NULL) {
  public_checks <- sanitize_public_frame(checks)
  public_panels <- lapply(panels, sanitize_public_frame)
  list(
    run_id = run_id,
    generated_at = generated_at,
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
    registry_cards = registry_cards(panels),
    panel_groups = public_rows(panel_groups(panels), max_rows = 100),
    run_summary = public_rows(run_summary, max_rows = 100),
    source_domains = public_rows(source_domain_summary(sources), max_rows = 100),
    sources = public_rows(public_sources(sources), max_rows = 500),
    checks = public_rows(public_checks, max_rows = 500),
    panels = lapply(public_panels, public_rows, max_rows = 250)
  )
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
      profile_mode = character(), load_status = character(), n_rows = numeric(),
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
    diagnosis_icd_groups = "Diagnosis ICD Groups",
    medication_atc_groups = "Medication ATC Groups",
    damyda_feature_coverage = "DaMyDa Feature Coverage",
    registry_clinical_summary = "Registry Clinical Summary",
    damyda_clinical_profile = "DaMyDa Clinical Profile",
    damyda_numeric_fields = "DaMyDa Numeric Fields",
    lyfo_clinical_profile = "LYFO Clinical Profile",
    cll_clinical_profile = "CLL Clinical Profile",
    sp_operational_sources = "SP Operational Sources",
    source_availability_drift = "Source Availability Drift"
  )
  named_value(titles, name, title_from_name(name))
}

panel_group <- function(name) {
  groups <- c(
    lab_npu_code_coverage = "Source Content",
    diagnosis_icd_groups = "Source Content",
    medication_atc_groups = "Source Content",
    damyda_feature_coverage = "Clinical Registries",
    registry_clinical_summary = "Clinical Registries",
    damyda_clinical_profile = "Clinical Registries",
    damyda_numeric_fields = "Clinical Registries",
    lyfo_clinical_profile = "Clinical Registries",
    cll_clinical_profile = "Clinical Registries",
    sp_operational_sources = "SP Operations",
    source_availability_drift = "Run QA"
  )
  named_value(groups, name, "Atlas Panels")
}

public_sources <- function(sources) {
  if (!nrow(sources)) return(sources)
  sources[, intersect(
    c(
      "table_name", "source_type", "source", "domain", "subdomain", "atlas_role",
      "profile_mode", "load_status", "n_rows", "n_cols", "min_date", "max_date", "message"
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
  grepl("id_column_guess|schema_signature", name, ignore.case = TRUE)
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
  out[severity == "warning"] <- 2L
  out[severity == "ok"] <- 3L
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
