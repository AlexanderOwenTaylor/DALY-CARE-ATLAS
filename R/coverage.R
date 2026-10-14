coverage_display_year_min <- function() 2000L

coverage_display_year_max <- function(current_date = Sys.Date()) {
  as.integer(format(as.Date(current_date), "%Y")) + 1L
}

dk_region_reference <- function() {
  data.frame(
    region_code = c("1081", "1082", "1083", "1084", "1085", "1099"),
    region_name = c(
      "North Denmark Region",
      "Central Denmark Region",
      "Region of Southern Denmark",
      "Capital Region",
      "Region Zealand",
      "Other/unknown"
    ),
    display_label = c("North Denmark", "Central Denmark", "Southern Denmark", "Capital", "Zealand", "Other/unknown"),
    map_order = c(5L, 4L, 3L, 1L, 2L, 99L),
    map_include = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    ehr_default = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE),
    lab_default = c("no", "no", "no", "capital", "partial", "unknown"),
    svg_path = c(
      "M108 15 L130 10 L158 12 L178 22 L192 42 L198 72 L196 105 L188 130 L172 148 L148 155 L128 150 L112 135 L102 110 L96 80 L98 48 Z",
      "M72 155 L112 148 L148 155 L172 165 L188 188 L196 218 L194 255 L184 282 L168 298 L148 305 L124 302 L98 288 L80 262 L68 228 L64 192 Z",
      "M64 305 L98 298 L124 302 L148 305 L158 325 L156 352 L148 378 L134 398 L116 410 L96 412 L78 400 L64 378 L56 348 L58 322 Z M185 288 L208 278 L235 285 L252 305 L250 332 L238 350 L218 355 L200 345 L190 322 Z M242 358 L258 352 L272 362 L276 378 L268 390 L252 392 L244 380 Z",
      "M368 165 L392 158 L418 168 L435 188 L440 215 L435 242 L422 262 L405 272 L388 265 L378 245 L374 218 L370 192 Z M508 212 L518 206 L530 212 L534 226 L528 238 L516 240 L510 230 Z",
      "M295 200 L322 188 L355 195 L378 215 L388 245 L385 278 L372 305 L352 320 L328 325 L308 315 L295 292 L288 258 L290 228 Z M312 338 L338 332 L362 345 L372 365 L366 385 L348 395 L328 392 L315 375 L310 355 Z",
      ""
    ),
    story = c(
      "Nationwide register coverage, no default SP/EHR bedside modules.",
      "Nationwide register coverage, no default SP/EHR bedside modules.",
      "Nationwide register coverage, no default SP/EHR bedside modules.",
      "Default SP/EHR coverage plus nationwide register coverage.",
      "Default SP/EHR coverage plus nationwide register coverage.",
      "Administrative residual category excluded from map shading."
    ),
    stringsAsFactors = FALSE
  )
}

normalize_dk_region <- function(x) {
  raw <- trimws(as.character(x))
  out <- rep(NA_character_, length(raw))
  key <- tolower(raw)
  key <- gsub("æ", "ae", key)
  key <- gsub("ø", "oe", key)
  key <- gsub("å", "aa", key)
  key <- gsub("[^a-z0-9]+", " ", key)
  key <- trimws(key)
  out[key %in% c("1081", "north denmark region", "region nordjylland", "nordjylland", "north denmark")] <- "1081"
  out[key %in% c("1082", "central denmark region", "region midtjylland", "midtjylland", "central denmark")] <- "1082"
  out[key %in% c("1083", "region of southern denmark", "region syddanmark", "syddanmark", "southern denmark")] <- "1083"
  out[key %in% c("1084", "capital region", "capital", "region hovedstaden", "hovedstaden", "capital region of denmark")] <- "1084"
  out[key %in% c("1085", "region zealand", "zealand", "region sjaelland", "sjaelland", "sjaeland")] <- "1085"
  out[key %in% c("1099", "other", "unknown", "other unknown", "missing")] <- "1099"
  out
}

coverage_date_score <- function(column_name) {
  nm <- tolower(as.character(column_name))
  score <- rep(0, length(nm))
  score <- score + ifelse(grepl("diagnos|diagnose|diagnosis|diagnosedato|reg_diagnose", nm), 100, 0)
  score <- score + ifelse(grepl("recorded|taken|pr[oø]vetagning|specim|sample|resultat|rekv|eksd", nm), 85, 0)
  score <- score + ifelse(grepl("admission|adm|kontakt|contact|inddto|dato_start|d_ind|d_ud|d_odto", nm), 80, 0)
  score <- score + ifelse(grepl("procedure|procedur|treatment|behandling|plan_start|order_start|aktiv", nm), 75, 0)
  score <- score + ifelse(grepl("date|dato|_dt$|time|tidspunkt", nm), 25, 0)
  score <- score - ifelse(grepl("birth|foed|f[oø]d", nm), 130, 0)
  score <- score - ifelse(grepl("death|doed|d[oø]d", nm), 110, 0)
  score <- score - ifelse(grepl("follow|followup|fu_|opdat|update|created|received|gyldig|valid|slut|end|lukket", nm), 45, 0)
  score
}

coverage_date_column_from_profiles <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(NA_character_)
  rows <- column_profiles[(column_profiles$profile_kind == "date" | grepl("date|dato|_dt$|time|tidspunkt",column_profiles$column_name,ignore.case=TRUE)) & !as.logical(column_profiles$is_sensitive %||% FALSE), , drop = FALSE]
  if (!nrow(rows)) return(NA_character_)
  score <- coverage_date_score(rows$column_name)
  available <- suppressWarnings(as.numeric(rows$n_available %||% 0))
  score[is.na(score)] <- 0
  available[is.na(available)] <- 0
  keep <- score > 0
  if (!any(keep)) return(NA_character_)
  rows <- rows[keep, , drop = FALSE]
  score <- score[keep]
  available <- available[keep]
  rows$score <- score
  rows$available_sort <- available
  rows <- rows[order(-rows$score, -rows$available_sort, rows$column_name), , drop = FALSE]
  rows$column_name[[1]]
}

coverage_date_profile <- function(column_profiles, column_name) {
  if (is.na(column_name) || !nzchar(column_name) || !is.data.frame(column_profiles)) return(data.frame())
  column_profiles[column_profiles$column_name == column_name, , drop = FALSE][1, , drop = FALSE]
}

coverage_parse_date <- function(x) {
  safe_as_date(x)
}

coverage_clamped_year <- function(date_value, lower = coverage_display_year_min(),
                                  upper = coverage_display_year_max()) {
  date <- coverage_parse_date(date_value)
  if (is.na(date)) return(NA_integer_)
  year <- as.integer(format(date, "%Y"))
  if (is.na(year)) return(NA_integer_)
  max(lower, min(upper, year))
}

coverage_temporal_qc_flag <- function(raw_min, raw_max, lower = coverage_display_year_min(),
                                      upper = coverage_display_year_max()) {
  years <- as.integer(format(coverage_parse_date(c(raw_min, raw_max)), "%Y"))
  if (all(is.na(years))) return("missing_date_range")
  if (any(!is.na(years) & (years < lower | years > upper))) return("clamped_display_range")
  "ok"
}

empty_temporal_coverage <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    n_rows = numeric(), date_column = character(), raw_min_date = character(), raw_max_date = character(),
    display_min_year = integer(), display_max_year = integer(), display_min_date = character(),
    display_max_date = character(), pct_available = numeric(), date_qc = character(),selection_basis=character(),event_meaning=character()
  )
}

empty_temporal_coverage_years <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    date_column = character(), year = integer(), n_rows = integer(), pct_rows = numeric(),
    coverage_basis = character(),person_support_safe=logical(),outside_person_support_safe=logical(),outside_record_support_safe=logical(),partition_complete=logical(),support_k=numeric()
  )
}

empty_temporal_date_quality <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    date_column = character(), raw_min_date = character(), raw_max_date = character(),
    display_min_year = integer(), display_max_year = integer(), issue_type = character(),
    severity = character(), message = character()
  )
}

empty_spatial_region_counts <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    region_column = character(), region_code = character(), region_name = character(),
    n_rows = integer(), pct_rows = numeric(), count_basis = character(),person_support_safe=logical(),outside_person_support_safe=logical(),outside_record_support_safe=logical(),partition_complete=logical(),support_k=numeric()
  )
}

empty_spatial_region_coverage <- function() {
  empty_df(
    region_code = character(), region_name = character(), display_label = character(),
    domain = character(), coverage_status = character(), loaded_sources = integer(),
    mapped_sources = integer(), n_rows = numeric(), basis = character(),expected_remit=character()
  )
}

empty_dk_choropleth_regions <- function() {
  empty_df(
    region_code = character(), region_name = character(), display_label = character(),
    map_order = integer(), map_include = logical(), svg_path = character(),
    choropleth_value = numeric(), pct_total = numeric(), choropleth_basis = character(),
    damyda_n = integer(), ehr_status = character(), lab_status = character(), story = character()
  )
}

panel_atlas_temporal_coverage <- function(sources, column_profiles) {
  if (!is.data.frame(sources) || !nrow(sources)) return(empty_temporal_coverage())
  source_value <- function(src, name, default = "") {
    if (!name %in% names(src)) return(default)
    src[[name]][[1]] %||% default
  }
  rows <- lapply(seq_len(nrow(sources)), function(i) {
    src <- sources[i, , drop = FALSE]
    profiles <- if (is.data.frame(column_profiles) && nrow(column_profiles)) {
      column_profiles[column_profiles$table_name == src$table_name[[1]], , drop = FALSE]
    } else {
      data.frame()
    }
    date_column <- coverage_date_column_from_profiles(profiles)
    prof <- coverage_date_profile(profiles, date_column)
    raw_min <- as.character(if(nrow(prof)) prof$min_date[[1]] %||% NA_character_ else NA_character_)
    raw_max <- as.character(if(nrow(prof)) prof$max_date[[1]] %||% NA_character_ else NA_character_)
    display_min_year <- coverage_clamped_year(raw_min)
    display_max_year <- coverage_clamped_year(raw_max)
    if (!is.na(display_min_year) && !is.na(display_max_year) && display_min_year > display_max_year) {
      tmp <- display_min_year
      display_min_year <- display_max_year
      display_max_year <- tmp
    }
    data.frame(
      table_name = src$table_name[[1]],
      domain = source_value(src, "domain"),
      subdomain = source_value(src, "subdomain"),
      atlas_role = source_value(src, "atlas_role"),
      n_rows = suppressWarnings(as.numeric(source_value(src, "n_rows", NA_real_))),
      date_column = date_column %||% NA_character_,
      raw_min_date = raw_min,
      raw_max_date = raw_max,
      display_min_year = display_min_year,
      display_max_year = display_max_year,
      display_min_date = if (is.na(display_min_year)) NA_character_ else paste0(display_min_year, "-01-01"),
      display_max_date = if (is.na(display_max_year)) NA_character_ else paste0(display_max_year, "-12-31"),
      pct_available = suppressWarnings(as.numeric(prof$pct_available[[1]] %||% NA_real_)),
      date_qc = coverage_temporal_qc_flag(raw_min, raw_max),
      selection_basis="name_prioritised_date_candidate",
      event_meaning="Selected source field; clinical event meaning not verified",
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_temporal_coverage())
  out
}

temporal_date_quality_rows_for_source <- function(row, lower = coverage_display_year_min(),
                                                  upper = coverage_display_year_max()) {
  table_name <- row$table_name[[1]] %||% ""
  date_column <- as.character(row$date_column[[1]] %||% "")
  raw_min <- as.character(row$raw_min_date[[1]] %||% "")
  raw_max <- as.character(row$raw_max_date[[1]] %||% "")
  min_date <- coverage_parse_date(raw_min)
  max_date <- coverage_parse_date(raw_max)
  min_year <- suppressWarnings(as.integer(format(min_date, "%Y")))
  max_year <- suppressWarnings(as.integer(format(max_date, "%Y")))
  base <- function(issue_type, severity, message) {
    data.frame(
      table_name = table_name,
      domain = row$domain[[1]] %||% "",
      subdomain = row$subdomain[[1]] %||% "",
      atlas_role = row$atlas_role[[1]] %||% "",
      date_column = date_column,
      raw_min_date = raw_min,
      raw_max_date = raw_max,
      display_min_year = suppressWarnings(as.integer(row$display_min_year[[1]] %||% NA_integer_)),
      display_max_year = suppressWarnings(as.integer(row$display_max_year[[1]] %||% NA_integer_)),
      issue_type = issue_type,
      severity = severity,
      message = message,
      stringsAsFactors = FALSE
    )
  }
  rows <- list()
  if (!nzchar(date_column) || is.na(date_column)) {
    rows[[length(rows) + 1L]] <- base(
      "missing_date_column",
      "info",
      "No coverage-ready date column was selected for this source."
    )
  } else if (all(is.na(c(min_date, max_date)))) {
    rows[[length(rows) + 1L]] <- base(
      "text_date_unparsed",
      "warning",
      "A date-like column was selected, but no valid aggregate date range was parsed."
    )
  }
  if (!is.na(min_year) && min_year < lower) {
    rows[[length(rows) + 1L]] <- base(
      "before_display_range",
      "warning",
      paste("Raw minimum date is before the display lower bound", lower, "and was clamped in figures.")
    )
  }
  if (!is.na(max_year) && max_year > upper) {
    rows[[length(rows) + 1L]] <- base(
      "after_display_range",
      "warning",
      paste("Raw maximum date is after the display upper bound", upper, "and was clamped in figures.")
    )
  }
  if (!length(rows)) return(empty_temporal_date_quality())
  bind_rows_base(rows)
}

panel_atlas_temporal_date_quality <- function(temporal_coverage) {
  if (!is.data.frame(temporal_coverage) || !nrow(temporal_coverage)) {
    return(empty_temporal_date_quality())
  }
  out <- bind_rows_base(lapply(seq_len(nrow(temporal_coverage)), function(i) {
    temporal_date_quality_rows_for_source(temporal_coverage[i, , drop = FALSE])
  }))
  if (!nrow(out)) return(empty_temporal_date_quality())
  out
}

panel_temporal_coverage_years <- function(data,table_name,min_cell_count=atlas_min_cell_count()) {
  p<-coverage_evidence_panels_from_data(data,table_name,min_cell_count)
  coverage_release_panels(p,data.frame(table_name=table_name),min_cell_count)$atlas_temporal_coverage_years
}

coverage_year_rows_from_ranges <- function(temporal_coverage) {
  # Extrema cannot establish event-bearing years or distinct-person support.
  empty_temporal_coverage_years()
}

region_column_from_profiles <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(NA_character_)
  cols <- as.character(column_profiles$column_name)
  nonsensitive <- !as.logical(column_profiles$is_sensitive %||% FALSE)
  candidates <- c(
    "^Region$", "^region$", "region_name", "region_tekst", "region_pro", "region_ans", "region_ind",
    "^k_region_id$", "^Reg_Region$"
  )
  for (pattern in candidates) {
    hit <- which(grepl(pattern, cols, ignore.case = TRUE) & nonsensitive)
    if (length(hit)) return(cols[[hit[[1]]]])
  }
  NA_character_
}

panel_spatial_region_counts <- function(data,table_name,min_cell_count=atlas_min_cell_count()) {
  p<-coverage_evidence_panels_from_data(data,table_name,min_cell_count)
  coverage_release_panels(p,data.frame(table_name=table_name),min_cell_count)$atlas_spatial_region_counts
}

dbi_temporal_coverage_years <- function(conn,table_ref,column_profiles,source_row,min_cell_count=atlas_min_cell_count()) {
  evidence<-dbi_coverage_evidence(conn,table_ref,column_profiles,source_row,min_cell_count)
  coverage_release_panels(list(coverage_evidence=evidence),source_row,min_cell_count)$atlas_temporal_coverage_years
}
dbi_spatial_region_counts <- function(conn,table_ref,column_profiles,source_row,min_cell_count=atlas_min_cell_count()) {
  evidence<-dbi_coverage_evidence(conn,table_ref,column_profiles,source_row,min_cell_count)
  coverage_release_panels(list(coverage_evidence=evidence),source_row,min_cell_count)$atlas_spatial_region_counts
}

add_source_context_to_coverage_panels <- function(rows, sources) {
  if (!is.data.frame(rows) || !nrow(rows) || !is.data.frame(sources) || !nrow(sources)) return(rows)
  idx <- match(rows$table_name, sources$table_name)
  for (nm in c("domain", "subdomain", "atlas_role")) {
    if (nm %in% names(rows) && nm %in% names(sources)) {
      rows[[nm]] <- ifelse(is.na(idx), rows[[nm]], as.character(sources[[nm]][idx]))
    }
  }
  rows
}

panel_atlas_spatial_region_coverage <- function(sources, region_counts = empty_spatial_region_counts()) {
  ref <- dk_region_reference()
  ref <- ref[ref$map_include, , drop = FALSE]
  if (!is.data.frame(sources) || !nrow(sources)) return(empty_spatial_region_coverage())
  if (!"domain" %in% names(sources)) sources$domain <- ""
  if (!"load_status" %in% names(sources)) sources$load_status <- ""
  if (!"n_rows" %in% names(sources)) sources$n_rows <- NA_real_
  domains <- unique(as.character((sources$domain %||% character())[nzchar(as.character(sources$domain %||% character()))]))
  domains <- unique(c("RKKP", "SDS", "DALY Views", "SP", domains))
  rows <- list()
  for (domain in domains) {
    domain_sources <- sources[sources$domain == domain, , drop = FALSE]
    loaded_sources <- sum(domain_sources$load_status == "ok", na.rm = TRUE)
    mapped_sources <- nrow(domain_sources)

    for (i in seq_len(nrow(ref))) {
      region <- ref[i, , drop = FALSE]
      observed_rows <- NA_real_
      status <- "unknown"
      basis <- "expected_source_remit"
      if (loaded_sources > 0 && domain %in% c("RKKP", "SDS", "DALY Views", "Core")) {
        status <- "nationwide"
      } else if (loaded_sources > 0 && identical(domain, "SP")) {
        status <- if (isTRUE(region$ehr_default[[1]])) "ehr" else "none"
      } else if (loaded_sources > 0) {
        status <- "available"
      } else if (mapped_sources > 0) {
        status <- "mapped_not_loaded"
      }
      remit <- status
      if (is.data.frame(region_counts) && nrow(region_counts)) {
        observed <- region_counts[region_counts$domain == domain & region_counts$region_code == region$region_code[[1]], , drop = FALSE]
        if (nrow(observed) && sum(observed$n_rows, na.rm = TRUE) > 0) {
          observed_rows <- sum(observed$n_rows)
          status <- "observed"
          basis <- "person_supported_region_records"
        }
      }
      rows[[length(rows) + 1L]] <- data.frame(
        region_code = region$region_code,
        region_name = region$region_name,
        display_label = region$display_label,
        domain = domain,
        coverage_status = if(status=="observed") "observed" else "not_assessed",
        loaded_sources = loaded_sources,
        mapped_sources = mapped_sources,
        n_rows = observed_rows,
        basis = basis,
        expected_remit = remit,
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_spatial_region_coverage())
  out
}

damyda_region_counts_from_panels <- function(panels, region_counts = empty_spatial_region_counts()) {
  ref <- dk_region_reference()
  if (is.data.frame(region_counts) && nrow(region_counts)) {
    out <- region_counts[region_counts$table_name == "RKKP_DaMyDa", c("region_code", "n_rows"), drop = FALSE]
    out <- out[is.finite(out$n_rows),,drop=FALSE]
    if (nrow(out)) {
      names(out)[names(out) == "n_rows"] <- "damyda_n"
      out <- aggregate(damyda_n ~ region_code, data = out, FUN = sum)
      return(merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE))
    }
  }
  data.frame(region_code = character(), damyda_n = integer(), region_name = character(), stringsAsFactors = FALSE)
}

spatial_region_counts_from_registry_panels <- function(panels, min_cell_count = atlas_min_cell_count()) {
  if (!is.list(panels) || !"damyda_clinical_profile" %in% names(panels)) {
    return(empty_spatial_region_counts())
  }
  damyda <- panels$damyda_clinical_profile
  if (!is.data.frame(damyda) || !nrow(damyda) || !"facet" %in% names(damyda)) {
    return(empty_spatial_region_counts())
  }
  damyda <- damyda[damyda$facet == "region", , drop = FALSE]
  if (!nrow(damyda)) return(empty_spatial_region_counts())
  code <- normalize_dk_region(damyda$label)
  out <- data.frame(
    table_name = damyda$table_name %||% "RKKP_DaMyDa",
    domain = "RKKP",
    subdomain = damyda$registry %||% "DaMyDa",
    atlas_role = "clinical_registry",
    region_column = damyda$source_column %||% "",
    region_code = code,
    n_rows = suppressWarnings(as.integer(damyda$n %||% 0L)),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$region_code), , drop = FALSE]
  out <- out[out$n_rows >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(out)) return(empty_spatial_region_counts())
  out <- aggregate(n_rows ~ table_name + domain + subdomain + atlas_role + region_column + region_code,
                   data = out, FUN = sum)
  ref <- dk_region_reference()
  out <- merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE)
  total_by_table <- stats::setNames(
    tapply(out$n_rows, out$table_name, sum, na.rm = TRUE),
    names(tapply(out$n_rows, out$table_name, sum, na.rm = TRUE))
  )
  denom <- suppressWarnings(as.numeric(total_by_table[out$table_name]))
  out$pct_rows <- mapply(safe_pct, out$n_rows, denom)
  out$count_basis <- "registry_region_panel"
  out[, c(
    "table_name", "domain", "subdomain", "atlas_role", "region_column",
    "region_code", "region_name", "n_rows", "pct_rows", "count_basis"
  ), drop = FALSE]
}

panel_atlas_dk_choropleth_regions <- function(sources, panels, region_counts = empty_spatial_region_counts(),
                                              region_coverage = empty_spatial_region_coverage()) {
  ref <- dk_region_reference()
  damyda_counts <- damyda_region_counts_from_panels(panels, region_counts)
  out <- ref
  out$damyda_n <- NA_integer_
  if (nrow(damyda_counts)) {
    idx <- match(out$region_code, damyda_counts$region_code)
    out$damyda_n <- ifelse(is.na(idx), NA_integer_, as.integer(damyda_counts$damyda_n[idx]))
  }
  map_total <- sum(out$damyda_n[out$map_include], na.rm = TRUE)
  out$choropleth_value <- out$damyda_n
  out$pct_total <- NA_real_
  out$choropleth_basis <- if (map_total > 0) "person_supported_region_records" else "observed counts unavailable; expected remit only"
  sp_status <- region_coverage[region_coverage$domain == "SP", c("region_code", "coverage_status"), drop = FALSE]
  out$ehr_status <- ifelse(out$ehr_default, "ehr", "none")
  if (nrow(sp_status)) {
    idx <- match(out$region_code, sp_status$region_code)
    out$ehr_status <- ifelse(is.na(idx), out$ehr_status, as.character(sp_status$coverage_status[idx]))
  }
  out$lab_status <- out$lab_default
  out[, c(
    "region_code", "region_name", "display_label", "map_order", "map_include", "svg_path",
    "choropleth_value", "pct_total", "choropleth_basis", "damyda_n", "ehr_status", "lab_status", "story"
  ), drop = FALSE]
}

build_coverage_panels <- function(sources, column_profiles, panels, min_cell_count = atlas_min_cell_count()) {
  panels <- panels %||% list()
  panels$atlas_temporal_coverage <- panel_atlas_temporal_coverage(sources, column_profiles)
  panels$atlas_temporal_date_quality <- panel_atlas_temporal_date_quality(panels$atlas_temporal_coverage)
  panels <- coverage_release_panels(panels,sources,min_cell_count)
  # Display bounds derive only from privacy-approved annual groups, never extrema.
  temporal <- panels$atlas_temporal_coverage
  temporal$display_min_year <- temporal$display_max_year <- NA_integer_
  temporal$display_min_date <- temporal$display_max_date <- NA_character_
  for(i in seq_len(nrow(temporal))) {
    years <- panels$atlas_temporal_coverage_years$year[panels$atlas_temporal_coverage_years$table_name==temporal$table_name[i]]
    if(length(years)) {temporal$display_min_year[i]<-min(years);temporal$display_max_year[i]<-max(years)}
  }
  panels$atlas_temporal_coverage <- temporal
  panels$atlas_spatial_region_coverage <- panel_atlas_spatial_region_coverage(
    sources = sources,
    region_counts = panels$atlas_spatial_region_counts
  )
  panels$atlas_dk_choropleth_regions <- panel_atlas_dk_choropleth_regions(
    sources = sources,
    panels = panels,
    region_counts = panels$atlas_spatial_region_counts,
    region_coverage = panels$atlas_spatial_region_coverage
  )
  panels
}

# Internal bounded aggregate contract. Never export keys or raw unknown tokens.
empty_coverage_evidence <- function() empty_df(table_name=character(),column_name=character(),dimension=character(),group_value=character(),
 record_count=numeric(),person_count=numeric(),outside_record_count=numeric(),outside_person_count=numeric(),
 total_record_count=numeric(),total_person_count=numeric(),missing_person_rows=numeric(),collection_status=character(),release_status=character(),format_rule=character(),format_rule_status=character())

coverage_unavailable <- function(table_name,column_name,dimension,status) {
  data.frame(table_name=table_name,column_name=column_name,dimension=dimension,group_value=NA_character_,
   record_count=NA_real_,person_count=NA_real_,outside_record_count=NA_real_,outside_person_count=NA_real_,
   total_record_count=NA_real_,total_person_count=NA_real_,missing_person_rows=NA_real_,collection_status=status,release_status=status,
   format_rule=if(dimension%in%c("year","date_quality","date_format") && !is.na(column_name))atlas_date_rule(table_name,column_name)$format_rule else "not_applicable",
   format_rule_status=if(dimension%in%c("year","date_quality","date_format") && !is.na(column_name))atlas_date_rule(table_name,column_name)$evidence_status else "not_applicable")
}

coverage_group_values <- function(values,dimension,rule=list(format_rule="iso",sentinel_dates=character())) {
  missing <- is.na(values)|trimws(as.character(values))==""
  if(dimension=="region") {
    result<-normalize_dk_region(values);result[is.na(result)]<-"unrecognised";result[missing]<-"missing";return(result)
  }
  if(dimension=="date_format")return(coverage_date_format_values(values,rule))
  dates <- safe_as_date(values,rule$format_rule)
  years <- suppressWarnings(as.integer(format(dates,"%Y")))
  result<-rep("valid",length(values));result[is.na(dates)]<-"unrecognised"
  outside<-!is.na(years)&(years<coverage_display_year_min()|years>coverage_display_year_max())
  result[outside]<-"outside_display_range"
  result[!is.na(dates)&as.character(dates)%in%rule$sentinel_dates]<-"sentinel"
  result[missing]<-"missing"
  if(dimension=="year") result[result=="valid"]<-as.character(years[result=="valid"])
  result
}

# Label-only membership uses complete exact evidence, but does not release any
# counts from an unsafe partition. Validate the full structure before each label.
coverage_label_eligible <- function(evidence,min_cell_count=atlas_min_cell_count()) {
  eligible<-rep(FALSE,nrow(evidence));k<-normalize_min_cell_count(min_cell_count)
  for(scope in unique(paste(evidence$table_name,evidence$column_name,evidence$dimension,sep="\r"))) {
    ix<-which(paste(evidence$table_name,evidence$column_name,evidence$dimension,sep="\r")==scope);e<-evidence[ix,,drop=FALSE]
    if(!isTRUE(all(e$collection_status=="complete"))||!isTRUE(all(e$missing_person_rows==0)))next
    measures<-unlist(e[c("record_count","person_count","outside_record_count","outside_person_count","total_record_count","total_person_count")],use.names=FALSE)
    valid<-all(is.finite(measures)) && all(measures>=0 & measures==floor(measures)) &&
      !anyNA(e$group_value) && !anyDuplicated(e$group_value) && all(e$record_count>0) &&
      length(unique(e$total_record_count))==1L && length(unique(e$total_person_count))==1L &&
      sum(e$record_count)==e$total_record_count[1] && all(e$total_record_count>=e$total_person_count) &&
      all(e$record_count>=e$person_count) && all(e$outside_record_count>=e$outside_person_count) &&
      all(e$outside_record_count==e$total_record_count-e$record_count) &&
      all(e$person_count<=e$total_person_count & e$outside_person_count<=e$total_person_count) &&
      all(e$person_count+e$outside_person_count>=e$total_person_count)
    if(isTRUE(valid))eligible[ix]<-e$person_count>=k &
      (e$outside_person_count>=k | (e$outside_person_count==0 & e$outside_record_count==0)) &
      (e$outside_record_count==0 | e$outside_record_count>=k)
  }
  eligible
}

coverage_gate <- function(evidence,min_cell_count=atlas_min_cell_count()) {
  if(!nrow(evidence))return(evidence)
  k<-normalize_min_cell_count(min_cell_count)
  for(scope in unique(paste(evidence$table_name,evidence$column_name,evidence$dimension,sep="\r"))) {
    ix<-which(paste(evidence$table_name,evidence$column_name,evidence$dimension,sep="\r")==scope)
    e<-evidence[ix,,drop=FALSE]
    if(!isTRUE(all(e$collection_status=="complete"))) {
      evidence$release_status[ix]<-if(length(unique(e$collection_status))==1L && !is.na(e$collection_status[1])) e$collection_status[1] else "not_assessed"
      next
    }
    missing_key<-any(is.na(e$missing_person_rows)|e$missing_person_rows>0)
    positive_small<-function(x)any(!is.finite(x)|x<0|(x>0&x<k))
    measures<-unlist(e[c("record_count","person_count","outside_record_count","outside_person_count","total_record_count","total_person_count")],use.names=FALSE)
    safe<-!missing_key && all(is.finite(measures)) && all(measures>=0 & measures==floor(measures)) &&
      !anyNA(e$group_value) && !anyDuplicated(e$group_value) && all(e$record_count>0 & e$person_count>=k) &&
      length(unique(e$total_person_count))==1L && all(e$total_record_count>=e$total_person_count) &&
      all(e$person_count+e$outside_person_count>=e$total_person_count) &&
      length(unique(e$total_record_count))==1L && sum(e$record_count)==e$total_record_count[1] &&
      all(e$record_count>=e$person_count) && all(e$outside_record_count==e$total_record_count-e$record_count) &&
      all(e$person_count<=e$total_person_count) && all(e$outside_person_count<=e$total_person_count) &&
      !positive_small(e$record_count) && !positive_small(e$person_count) &&
      !positive_small(e$outside_record_count) && !positive_small(e$outside_person_count)
    evidence$release_status[ix]<-if(missing_key)"missing_person_key" else if(isTRUE(safe))"published" else "withheld_privacy"
  }
  evidence
}

coverage_partition_from_data <- function(groups,keys,table_name,column_name,dimension,min_cell_count=atlas_min_cell_count()) {
  keys<-trimws(as.character(keys));missing<-is.na(keys)|keys==""
  levels<-sort(unique(groups))
  if(length(levels)>10010L)return(coverage_unavailable(table_name,column_name,dimension,"category_overflow"))
  total<-length(groups);people<-length(unique(keys[!missing]))
  if(!total)return(coverage_unavailable(table_name,column_name,dimension,"empty_source"))
  out<-bind_rows_base(lapply(levels,function(g) {
    inside<-groups==g
    data.frame(table_name=table_name,column_name=column_name,dimension=dimension,group_value=g,
      record_count=as.numeric(sum(inside)),person_count=as.numeric(length(unique(keys[inside&!missing]))),
      outside_record_count=as.numeric(sum(!inside)),outside_person_count=as.numeric(length(unique(keys[!inside&!missing]))),
      total_record_count=as.numeric(total),total_person_count=as.numeric(people),missing_person_rows=as.numeric(sum(missing)),
      collection_status="complete",release_status="unassessed",format_rule="not_applicable",format_rule_status="not_applicable")
  }))
  coverage_gate(out,min_cell_count)
}

coverage_evidence_from_data <- function(data,table_name,column_name,dimension,min_cell_count=atlas_min_cell_count()) {
  if(is.na(column_name)||!column_name%in%names(data))return(coverage_unavailable(table_name,column_name,dimension,"missing_column"))
  key<-registry_summary_person_key(table_name,names(data))
  if(key$status!="ok")return(coverage_unavailable(table_name,column_name,dimension,key$status))
  groups<-coverage_group_values(data[[column_name]],dimension,atlas_date_rule(table_name,column_name))
  out<-coverage_partition_from_data(groups,data[[key$key]],table_name,column_name,dimension,min_cell_count)
  if(dimension%in%c("year","date_quality","date_format")) {
    rule<-atlas_date_rule(table_name,column_name);out$format_rule<-rule$format_rule;out$format_rule_status<-rule$evidence_status
  }
  out
}

coverage_evidence_panels_from_data <- function(data,table_name,min_cell_count=atlas_min_cell_count()) {
  profiles<-profile_column_profiles(data,table_name,profile_mode="summary")
  date<-coverage_date_column_from_profiles(profiles);region<-region_column_from_profiles(profiles)
  e<-bind_rows_base(list(coverage_evidence_from_data(data,table_name,date,"year",min_cell_count),
    coverage_evidence_from_data(data,table_name,date,"date_quality",min_cell_count),
    coverage_evidence_from_data(data,table_name,date,"date_format",min_cell_count),
    coverage_evidence_from_data(data,table_name,region,"region",min_cell_count)))
  list(coverage_evidence=e)
}

coverage_release_panels <- function(panels,sources,min_cell_count=atlas_min_cell_count()) {
  evidence<-panels$coverage_evidence %||% empty_coverage_evidence()
  evidence<-coverage_gate(evidence,min_cell_count)
  # Keep archived row-only inputs in their saved CSVs. They cannot establish even
  # a safe observed bin label; no bounds-to-years reconstruction is permitted.
  safe<-evidence[evidence$release_status=="published",,drop=FALSE]
  labels<-evidence[coverage_label_eligible(evidence,min_cell_count),,drop=FALSE]
  years<-labels[labels$dimension=="year" & grepl("^[0-9]{4}$",labels$group_value),,drop=FALSE]
  panels$atlas_temporal_coverage_years<-if(nrow(years)) data.frame(table_name=years$table_name,domain="",subdomain="",atlas_role="",
    date_column=years$column_name,year=as.integer(years$group_value),n_rows=ifelse(years$release_status=="published",years$record_count,NA_real_),
    pct_rows=ifelse(years$release_status=="published",100*years$record_count/years$total_record_count,NA_real_),coverage_basis=ifelse(years$release_status=="published","person_supported_complete_partition","person_supported_label_only"),
    person_support_safe=TRUE,outside_person_support_safe=TRUE,outside_record_support_safe=TRUE,partition_complete=years$release_status=="published",support_k=normalize_min_cell_count(min_cell_count),
    count_privacy_status=ifelse(years$release_status=="published","published","withheld_partition_counts")) else empty_temporal_coverage_years()
  region<-labels[labels$dimension=="region" & labels$group_value %in% dk_region_reference()$region_code,,drop=FALSE]
  panels$atlas_spatial_region_counts<-if(nrow(region)) data.frame(table_name=region$table_name,domain="",subdomain="",atlas_role="",
    region_column=region$column_name,region_code=region$group_value,region_name=dk_region_reference()$region_name[match(region$group_value,dk_region_reference()$region_code)],
    n_rows=ifelse(region$release_status=="published",region$record_count,NA_real_),pct_rows=ifelse(region$release_status=="published",100*region$record_count/region$total_record_count,NA_real_),count_basis=ifelse(region$release_status=="published","person_supported_complete_partition","person_supported_label_only"),
    person_support_safe=TRUE,outside_person_support_safe=TRUE,outside_record_support_safe=TRUE,partition_complete=region$release_status=="published",support_k=normalize_min_cell_count(min_cell_count),
    count_privacy_status=ifelse(region$release_status=="published","published","withheld_partition_counts")) else empty_spatial_region_counts()
  for(name in c("atlas_temporal_coverage_years","atlas_spatial_region_counts"))panels[[name]]<-add_source_context_to_coverage_panels(panels[[name]],sources)
  statuses <- if(nrow(evidence)) unique(evidence[c("table_name","column_name","dimension","collection_status","release_status")]) else empty_coverage_status()
  for(i in seq_len(nrow(statuses)))if(statuses$dimension[i]%in%c("year","region") && statuses$release_status[i]=="withheld_privacy" &&
    any(labels$table_name==statuses$table_name[i] & labels$column_name==statuses$column_name[i] & labels$dimension==statuses$dimension[i]))statuses$release_status[i]<-"partial_labels_counts_withheld"
  if(!nrow(evidence) && is.data.frame(sources) && nrow(sources)) statuses <- data.frame(table_name=sources$table_name,column_name=NA_character_,dimension="source",collection_status="not_assessed",release_status="unavailable_person_partition_evidence")
  panels$atlas_coverage_status <- statuses
  quality <- safe[safe$dimension=="date_quality",,drop=FALSE]
  panels$atlas_date_quality_counts <- if(nrow(quality)) data.frame(table_name=quality$table_name,date_column=quality$column_name,
    quality_state=quality$group_value,n_rows=quality$record_count,person_support_safe=TRUE,outside_person_support_safe=TRUE,
    outside_record_support_safe=TRUE,partition_complete=TRUE,support_k=normalize_min_cell_count(min_cell_count)) else empty_date_quality_counts()
  panels
}

empty_coverage_status <- function() empty_df(table_name=character(),column_name=character(),dimension=character(),collection_status=character(),release_status=character())
empty_date_quality_counts <- function() empty_df(table_name=character(),date_column=character(),quality_state=character(),n_rows=numeric(),person_support_safe=logical(),outside_person_support_safe=logical(),outside_record_support_safe=logical(),partition_complete=logical(),support_k=numeric())

# The database keeps person membership local. Exclusive-to-one-group support is
# subtracted from total people to count people with ANY record outside that group.
coverage_partition_sql <- function(conn,table_ref,key_column,group_expression) {
  key<-DBI::dbQuoteIdentifier(conn,key_column)
  paste0("with base as materialized (select nullif(",dbi_trim_date_text_expression(key),",'') pid, ",group_expression," g from ",table_ref,"),",
    " memberships as (select pid,count(distinct g) ng,min(g) only_group from base where pid is not null group by pid),",
    " totals as (select count(*)::double precision nr,count(distinct pid)::double precision np,count(*) filter(where pid is null)::double precision missing from base),",
    " groups as (select g,count(*)::double precision nr,count(distinct pid)::double precision np from base group by g),",
    " exclusive as (select only_group g,count(*)::double precision n from memberships where ng=1 group by only_group)",
    " select groups.g group_value,groups.nr record_count,groups.np person_count,totals.nr-groups.nr outside_record_count,",
    "totals.np-coalesce(exclusive.n,0) outside_person_count,totals.nr total_record_count,totals.np total_person_count,totals.missing missing_person_rows",
    " from groups cross join totals left join exclusive using(g) order by groups.g limit 10011")
}

coverage_group_sql <- function(conn,qcol,dimension,rule=list(format_rule="iso",sentinel_dates=character()),column_type="") {
  value<-dbi_trim_date_text_expression(qcol)
  if(dimension=="date_format")return(coverage_date_format_sql(conn,qcol,rule,column_type))
  if(dimension=="region") {
    aliases<-c("1081","north denmark region","region nordjylland","nordjylland","north denmark",
      "1082","central denmark region","region midtjylland","midtjylland","central denmark",
      "1083","region of southern denmark","region syddanmark","syddanmark","southern denmark",
      "1084","capital region","capital","region hovedstaden","hovedstaden","capital region of denmark",
      "1085","region zealand","zealand","region sjaelland","sjaelland","sjaeland",
      "1099","other","unknown","other unknown","missing")
    canonical<-paste0("btrim(regexp_replace(replace(replace(replace(lower(",value,"),'æ','ae'),'ø','oe'),'å','aa'),'[^a-z0-9]+',' ','g'))")
    cases<-vapply(split(aliases,normalize_dk_region(aliases)),function(tokens) paste0(" when ",canonical," in (",paste(DBI::dbQuoteString(conn,tokens),collapse=","),") then '",normalize_dk_region(tokens[1]),"'"),character(1))
    return(paste0("case when ",qcol," is null or ",value,"='' then 'missing'",paste(cases,collapse="")," else 'unrecognised' end"))
  }
  date<-if(sql_type_is_date(column_type,column_type)) paste0(dbi_typed_date_expression(qcol,column_type,column_type),"::text") else dbi_text_date_string_expression(qcol,rule$format_rule)
  sentinel<-if(length(rule$sentinel_dates))paste0(" when d in (",paste(DBI::dbQuoteString(conn,rule$sentinel_dates),collapse=","),") then 'sentinel'") else ""
  paste0("(select case when ",qcol," is null or ",value,"='' then 'missing' when d is null then 'unrecognised'",sentinel,
   " when substring(d from 1 for 4)::integer < ",coverage_display_year_min()," or substring(d from 1 for 4)::integer > ",coverage_display_year_max()," then 'outside_display_range' else ",
   if(dimension=="year")"substring(d from 1 for 4)" else "'valid'"," end from (select ",date," d) parsed)")
}

dbi_coverage_evidence <- function(conn,table_ref,profiles,source_row,min_cell_count=atlas_min_cell_count(),budget_context=NULL) {
  table<-source_row$table_name[1];columns<-profiles$column_name
  key<-registry_summary_person_key(table,columns)
  date<-coverage_date_column_from_profiles(profiles);region<-region_column_from_profiles(profiles)
  rows<-lapply(c("year","date_quality","date_format","region"),function(dimension) {
    column<-if(dimension=="region")region else date
    unavailable<-function(status)coverage_unavailable(table,column,dimension,status)
    if(is.na(column))return(unavailable("missing_column"))
    if(key$status!="ok")return(unavailable(key$status))
    if(!is.null(budget_context)&&budget_context$should_skip("coverage_person_partition",atlas_max_exact_agg_rows(),column))return(unavailable("budget_skipped"))
    sql<-coverage_partition_sql(conn,table_ref,key$key,coverage_group_sql(conn,DBI::dbQuoteIdentifier(conn,column),dimension,atlas_date_rule(table,column),profiles$column_type[match(column,profiles$column_name)] %||% ""))
    started<-proc.time()[["elapsed"]]
    out<-tryCatch(DBI::dbGetQuery(conn,sql),error=function(e)NULL)
    if(!is.null(budget_context))budget_context$add_log(column,"coverage_person_partition",if(is.null(out))"query_failed" else "ok",elapsed_ms=1000*(proc.time()[["elapsed"]]-started))
    if(is.null(out))return(unavailable("query_failed"))
    if(!nrow(out))return(unavailable("empty_source"))
    if(nrow(out)>10010L)return(unavailable("category_overflow"))
    out$table_name<-table;out$column_name<-column;out$dimension<-dimension;out$collection_status<-"complete";out$release_status<-"unassessed"
    rule<-atlas_date_rule(table,column)
    out$format_rule<-if(dimension=="region")"not_applicable" else rule$format_rule
    out$format_rule_status<-if(dimension=="region")"not_applicable" else rule$evidence_status
    for(n in c("record_count","person_count","outside_record_count","outside_person_count","total_record_count","total_person_count","missing_person_rows"))out[[n]]<-as.numeric(out[[n]])
    coverage_gate(out[,names(empty_coverage_evidence()),drop=FALSE],min_cell_count)
  })
  bind_rows_base(rows)
}

empty_vital_descriptors <- function() empty_df(source_name=character(),name_col=character(),value_col=character(),descriptor=character())
empty_vital_descriptor_assessment <- function() empty_df(source_name=character(),name_col=character(),value_col=character(),inventory_status=character())

vital_inventory_scopes <- function(table_name,columns) {
  if(!identical(table_name,"SP_VitaleVaerdier")||!"displayname"%in%columns)return(character())
  intersect(c("meas_value","meas_value_clean","numericvalue"),columns)
}
vital_inventory_vocabulary <- function(project_root=getOption("dalycare.registry.project_root",".")) {
  path<-file.path(project_root,"config/metadata-descriptor-definitions.json")
  resource<-jsonlite::fromJSON(path)
  stopifnot(identical(resource$version,"metadata-descriptor-definitions-v1"))
  resource$descriptors
}
vital_inventory_finish <- function(evidence,table_name,scopes,min_cell_count=atlas_min_cell_count()) {
  status<-if(!nrow(evidence))"not_assessed" else if(all(evidence$release_status=="published"))"assessed_complete" else evidence$release_status[1]
  descriptors<-setdiff(evidence$group_value[coverage_label_eligible(evidence,min_cell_count)],c("missing","unrecognised"))
  if(length(descriptors) && status!="assessed_complete")status<-"partial_withheld"
  # Unknown tokens are accounted as a state and never exported as examples.
  if(status=="assessed_complete" && "unrecognised"%in%evidence$group_value)status<-"partial_unrecognised"
  list(vital_descriptors=if(length(descriptors))bind_rows_base(lapply(scopes,function(value) data.frame(source_name=table_name,name_col="displayname",value_col=value,descriptor=descriptors))) else empty_vital_descriptors(),
   vital_descriptor_assessment=if(length(scopes))data.frame(source_name=table_name,name_col="displayname",value_col=scopes,inventory_status=status) else empty_vital_descriptor_assessment())
}
vital_inventory_from_data <- function(data,table_name,min_cell_count=atlas_min_cell_count()) {
  scopes<-vital_inventory_scopes(table_name,names(data))
  if(!length(scopes))return(vital_inventory_finish(empty_coverage_evidence(),table_name,scopes))
  key<-registry_summary_person_key(table_name,names(data))
  if(key$status!="ok")return(vital_inventory_finish(coverage_unavailable(table_name,"displayname","descriptor",key$status),table_name,scopes))
  raw<-as.character(data$displayname);allowed<-vital_inventory_vocabulary()
  groups<-ifelse(!is.na(raw)&nchar(raw)<=64L&raw==trimws(raw)&tolower(raw)%in%allowed,raw,"unrecognised")
  groups[is.na(raw)|trimws(raw)==""]<-"missing"
  e<-coverage_partition_from_data(groups,data[[key$key]],table_name,"displayname","descriptor",min_cell_count)
  vital_inventory_finish(e,table_name,scopes,min_cell_count)
}
dbi_vital_inventory <- function(conn,table_ref,columns,table_name,min_cell_count=atlas_min_cell_count(),budget_context=NULL) {
  scopes<-vital_inventory_scopes(table_name,columns)
  unavailable<-function(status)vital_inventory_finish(coverage_unavailable(table_name,"displayname","descriptor",status),table_name,scopes)
  if(!length(scopes))return(unavailable("missing_column"))
  key<-registry_summary_person_key(table_name,columns)
  if(key$status!="ok")return(unavailable(key$status))
  if(!is.null(budget_context)&&budget_context$should_skip("controlled_vital_inventory",atlas_max_exact_agg_rows(),"displayname"))return(unavailable("budget_skipped"))
  col<-DBI::dbQuoteIdentifier(conn,"displayname");tokens<-paste(DBI::dbQuoteString(conn,vital_inventory_vocabulary()),collapse=",")
  group<-paste0("case when ",col," is null or ",dbi_trim_date_text_expression(col),"='' then 'missing' when length(",col,"::text)<=64 and ",col,"::text=",dbi_trim_date_text_expression(col)," and lower(",col,"::text) in (",tokens,") then ",col,"::text else 'unrecognised' end")
  sql<-coverage_partition_sql(conn,table_ref,key$key,group)
  started<-proc.time()[["elapsed"]]
  out<-tryCatch(DBI::dbGetQuery(conn,sql),error=function(e)NULL)
  if(!is.null(budget_context))budget_context$add_log("displayname","controlled_vital_inventory",if(is.null(out))"query_failed" else "ok",elapsed_ms=1000*(proc.time()[["elapsed"]]-started))
  if(is.null(out))return(unavailable("query_failed"))
  if(!nrow(out))return(unavailable("empty_source"))
  if(nrow(out)>5000L)return(unavailable("category_overflow"))
  out$table_name<-table_name;out$column_name<-"displayname";out$dimension<-"descriptor";out$collection_status<-"complete";out$release_status<-"unassessed"
  vital_inventory_finish(coverage_gate(out,min_cell_count),table_name,scopes,min_cell_count)
}

# Finite diagnostics only: candidate syntax never authorizes parsing/coverage.
coverage_date_format_values <- function(values,rule) {
  raw<-trimws(as.character(values));missing<-is.na(raw)|raw==""
  parsed<-safe_as_date(values,rule$format_rule)
  result<-rep("other_unrecognised",length(raw))
  matches<-function(pattern)!missing & grepl(pattern,raw)
  result[matches("^[0-9]{1,2}[-/.][0-9]{1,2}[-/.][0-9]{2}$")]<-"ambiguous_short_date"
  result[matches(atlas_date_format_pattern("dmy_slash"))]<-"ambiguous_slash_date"
  result[matches(atlas_date_format_pattern("dmy_dot"))]<-"candidate_dmy_dot"
  result[matches(atlas_date_format_pattern("dmy_dash"))]<-"candidate_dmy_dash"
  result[matches(atlas_date_format_pattern("ymd_compact"))]<-"candidate_compact_ymd"
  lexical<-matches(atlas_date_format_pattern(rule$format_rule))
  result[lexical&is.na(parsed)]<-"impossible_calendar"
  if(rule$format_rule=="iso") {
    date_only<-safe_as_date(substr(raw,1,10))
    result[lexical&is.na(parsed)&!is.na(date_only)]<-"invalid_timestamp"
    result[!is.na(parsed)]<-ifelse(nchar(raw[!is.na(parsed)])==10L,"valid_iso_date","valid_iso_timestamp")
  } else result[!is.na(parsed)]<-"valid_mapped_date"
  if(inherits(values,"Date"))result[!is.na(parsed)]<-"typed_date"
  if(inherits(values,"POSIXt"))result[!is.na(parsed)]<-"typed_timestamp"
  result[!is.na(parsed)&as.character(parsed)%in%rule$sentinel_dates]<-"documented_sentinel"
  result[missing]<-"missing"
  result
}

coverage_date_format_sql <- function(conn,qcol,rule,column_type="") {
  value<-dbi_trim_date_text_expression(qcol)
  typed<-grepl("^date$|timestamp|timestamptz",column_type,ignore.case=TRUE)
  parsed<-if(typed)paste0(dbi_typed_date_expression(qcol,column_type,column_type),"::text") else dbi_text_date_string_expression(qcol,rule$format_rule)
  sentinel<-if(length(rule$sentinel_dates))paste0(" when parsed in (",paste(DBI::dbQuoteString(conn,rule$sentinel_dates),collapse=","),") then 'documented_sentinel'") else ""
  valid<-if(typed)if(column_type=="date")"'typed_date'" else "'typed_timestamp'" else if(rule$format_rule=="iso")"case when length(v)=10 then 'valid_iso_date' else 'valid_iso_timestamp' end" else "'valid_mapped_date'"
  invalid<-if(rule$format_rule=="iso")paste0("case when ",dbi_text_date_string_expression("substring(v from 1 for 10)")," is not null then 'invalid_timestamp' else 'impossible_calendar' end") else "'impossible_calendar'"
  paste0("(select case when v is null or v='' then 'missing'",sentinel," when parsed is not null then ",valid,
    " when v ~ '",atlas_date_format_pattern(rule$format_rule),"' then ",invalid,
    " when v ~ '",atlas_date_format_pattern("dmy_dash"),"' then 'candidate_dmy_dash'",
    " when v ~ '",atlas_date_format_pattern("dmy_slash"),"' then 'ambiguous_slash_date'",
    " when v ~ '",atlas_date_format_pattern("dmy_dot"),"' then 'candidate_dmy_dot'",
    " when v ~ '",atlas_date_format_pattern("ymd_compact"),"' then 'candidate_compact_ymd'",
    " when v ~ '^[0-9]{1,2}[-/.][0-9]{1,2}[-/.][0-9]{2}$' then 'ambiguous_short_date' else 'other_unrecognised' end",
    " from (select ",value," v,",parsed," parsed) formats)")
}
