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
  key <- gsub("Ã¦|æ", "ae", key)
  key <- gsub("Ã¸|ø", "oe", key)
  key <- gsub("Ã¥|å", "aa", key)
  key <- gsub("[^a-z0-9]+", " ", key)
  key <- trimws(key)
  out[key %in% c("1081", "north denmark region", "region nordjylland", "nordjylland", "north denmark")] <- "1081"
  out[key %in% c("1082", "central denmark region", "region midtjylland", "midtjylland", "central denmark")] <- "1082"
  out[key %in% c("1083", "region of southern denmark", "region syddanmark", "syddanmark", "southern denmark")] <- "1083"
  out[key %in% c("1084", "capital region", "capital", "region hovedstaden", "hovedstaden", "capital region of denmark")] <- "1084"
  out[key %in% c("1085", "region zealand", "zealand", "region sjaelland", "sjaelland", "sjaeland")] <- "1085"
  out[key %in% c("1099", "other", "unknown", "other unknown", "missing")] <- "1099"
  out[is.na(out) & grepl("hoved", key)] <- "1084"
  out[is.na(out) & grepl("sjaelland|sjaeland|zealand", key)] <- "1085"
  out[is.na(out) & grepl("syddanmark|southern|south", key)] <- "1083"
  out[is.na(out) & grepl("midtjylland|central", key)] <- "1082"
  out[is.na(out) & grepl("nordjylland|north", key)] <- "1081"
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
  rows <- column_profiles[column_profiles$profile_kind == "date" & !as.logical(column_profiles$is_sensitive %||% FALSE), , drop = FALSE]
  if (!nrow(rows)) return(NA_character_)
  score <- coverage_date_score(rows$column_name)
  available <- suppressWarnings(as.numeric(rows$n_available %||% 0))
  score[is.na(score)] <- 0
  available[is.na(available)] <- 0
  keep <- score > 0 & available >= normalize_min_cell_count(atlas_min_cell_count())
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
  suppressWarnings(as.Date(as.character(x)))
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
    display_max_date = character(), pct_available = numeric(), date_qc = character()
  )
}

empty_temporal_coverage_years <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    date_column = character(), year = integer(), n_rows = integer(), pct_rows = numeric(),
    coverage_basis = character()
  )
}

empty_spatial_region_counts <- function() {
  empty_df(
    table_name = character(), domain = character(), subdomain = character(), atlas_role = character(),
    region_column = character(), region_code = character(), region_name = character(),
    n_rows = integer(), pct_rows = numeric(), count_basis = character()
  )
}

empty_spatial_region_coverage <- function() {
  empty_df(
    region_code = character(), region_name = character(), display_label = character(),
    domain = character(), coverage_status = character(), loaded_sources = integer(),
    mapped_sources = integer(), n_rows = numeric(), basis = character()
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
    raw_min <- as.character(prof$min_date[[1]] %||% src$min_date[[1]] %||% NA_character_)
    raw_max <- as.character(prof$max_date[[1]] %||% src$max_date[[1]] %||% NA_character_)
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
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_temporal_coverage())
  out
}

panel_temporal_coverage_years <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  if (!is.data.frame(data) || !nrow(data)) return(empty_temporal_coverage_years())
  profiles <- profile_column_profiles(data, table_name, profile_mode = "full")
  date_column <- coverage_date_column_from_profiles(profiles)
  if (is.na(date_column) || !nzchar(date_column) || !date_column %in% names(data)) return(empty_temporal_coverage_years())
  years <- as.integer(format(safe_as_date(data[[date_column]]), "%Y"))
  years <- years[!is.na(years) & years >= coverage_display_year_min() & years <= coverage_display_year_max()]
  if (!length(years)) return(empty_temporal_coverage_years())
  counts <- sort(table(years), decreasing = FALSE)
  out <- data.frame(
    table_name = table_name,
    domain = "",
    subdomain = "",
    atlas_role = "",
    date_column = date_column,
    year = as.integer(names(counts)),
    n_rows = as.integer(counts),
    pct_rows = vapply(as.integer(counts), safe_pct, numeric(1), denom = nrow(data)),
    coverage_basis = "event_date_counts",
    stringsAsFactors = FALSE
  )
  out[out$n_rows >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
}

coverage_year_rows_from_ranges <- function(temporal_coverage) {
  if (!is.data.frame(temporal_coverage) || !nrow(temporal_coverage)) return(empty_temporal_coverage_years())
  rows <- lapply(seq_len(nrow(temporal_coverage)), function(i) {
    row <- temporal_coverage[i, , drop = FALSE]
    y1 <- suppressWarnings(as.integer(row$display_min_year[[1]]))
    y2 <- suppressWarnings(as.integer(row$display_max_year[[1]]))
    if (is.na(y1) || is.na(y2) || y1 > y2) return(empty_temporal_coverage_years())
    data.frame(
      table_name = row$table_name[[1]],
      domain = row$domain[[1]] %||% "",
      subdomain = row$subdomain[[1]] %||% "",
      atlas_role = row$atlas_role[[1]] %||% "",
      date_column = row$date_column[[1]] %||% "",
      year = seq.int(y1, y2),
      n_rows = NA_integer_,
      pct_rows = NA_real_,
      coverage_basis = "source_date_range",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

region_column_from_profiles <- function(column_profiles) {
  if (!is.data.frame(column_profiles) || !nrow(column_profiles)) return(NA_character_)
  cols <- as.character(column_profiles$column_name)
  nonsensitive <- !as.logical(column_profiles$is_sensitive %||% FALSE)
  candidates <- c(
    "^Region$", "^region$", "region_name", "region_tekst", "region_pro", "region_ans", "region_ind",
    "k_region_id", "Reg_Region", "Kommunenr"
  )
  for (pattern in candidates) {
    hit <- which(grepl(pattern, cols, ignore.case = TRUE) & nonsensitive)
    if (length(hit)) return(cols[[hit[[1]]]])
  }
  NA_character_
}

panel_spatial_region_counts <- function(data, table_name, min_cell_count = atlas_min_cell_count()) {
  if (!is.data.frame(data) || !nrow(data)) return(empty_spatial_region_counts())
  profiles <- profile_column_profiles(data, table_name, profile_mode = "summary")
  region_col <- region_column_from_profiles(profiles)
  if (is.na(region_col) || !nzchar(region_col) || !region_col %in% names(data)) return(empty_spatial_region_counts())
  codes <- normalize_dk_region(data[[region_col]])
  codes <- codes[!is.na(codes)]
  if (!length(codes)) return(empty_spatial_region_counts())
  counts <- sort(table(codes), decreasing = TRUE)
  ref <- dk_region_reference()
  out <- data.frame(
    table_name = table_name,
    domain = "",
    subdomain = "",
    atlas_role = "",
    region_column = region_col,
    region_code = names(counts),
    n_rows = as.integer(counts),
    stringsAsFactors = FALSE
  )
  out <- merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE)
  out$pct_rows <- vapply(out$n_rows, safe_pct, numeric(1), denom = nrow(data))
  out$count_basis <- "region_column_counts"
  out <- out[out$n_rows >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  out[, c("table_name", "domain", "subdomain", "atlas_role", "region_column", "region_code", "region_name", "n_rows", "pct_rows", "count_basis"), drop = FALSE]
}

dbi_temporal_coverage_years <- function(conn, table_ref, column_profiles, source_row,
                                        min_cell_count = atlas_min_cell_count()) {
  if (is.null(conn) || is.null(table_ref)) return(empty_temporal_coverage_years())
  date_column <- coverage_date_column_from_profiles(column_profiles)
  if (is.na(date_column) || !nzchar(date_column)) return(empty_temporal_coverage_years())
  date_profile <- coverage_date_profile(column_profiles, date_column)
  qcol <- DBI::dbQuoteIdentifier(conn, date_column)
  year_expr <- dbi_date_year_expression(
    qcol,
    column_type = date_profile$column_type[[1]] %||% "",
    column_class = date_profile$column_class[[1]] %||% ""
  )
  lower <- coverage_display_year_min()
  upper <- coverage_display_year_max()
  sql <- paste0(
    "select year, count(*) as n_rows ",
    "from (select ", year_expr, " as year from ", table_ref, " where ", qcol, " is not null) atlas_years ",
    "where year between ", as.integer(lower), " and ", as.integer(upper), " ",
    "group by year ",
    "having count(*) >= ", as.integer(normalize_min_cell_count(min_cell_count)),
    " order by year"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(year = integer(), n_rows = integer()))
  if (!nrow(out)) return(empty_temporal_coverage_years())
  data.frame(
    table_name = source_row$table_name[[1]],
    domain = "",
    subdomain = "",
    atlas_role = "",
    date_column = date_column,
    year = suppressWarnings(as.integer(out$year)),
    n_rows = suppressWarnings(as.integer(out$n_rows)),
    pct_rows = vapply(suppressWarnings(as.integer(out$n_rows)), safe_pct, numeric(1), denom = source_row$n_rows[[1]]),
    coverage_basis = "event_date_counts",
    stringsAsFactors = FALSE
  )
}

dbi_spatial_region_counts <- function(conn, table_ref, column_profiles, source_row,
                                      min_cell_count = atlas_min_cell_count()) {
  if (is.null(conn) || is.null(table_ref)) return(empty_spatial_region_counts())
  region_col <- region_column_from_profiles(column_profiles)
  if (is.na(region_col) || !nzchar(region_col)) return(empty_spatial_region_counts())
  qcol <- DBI::dbQuoteIdentifier(conn, region_col)
  sql <- paste0(
    "select left(", qcol, "::text, 120) as raw_region, count(*) as n_rows ",
    "from ", table_ref,
    " where ", qcol, " is not null and btrim(", qcol, "::text) <> '' ",
    "group by left(", qcol, "::text, 120) ",
    "having count(*) >= ", as.integer(normalize_min_cell_count(min_cell_count)),
    " order by n_rows desc, raw_region"
  )
  out <- tryCatch(DBI::dbGetQuery(conn, sql), error = function(e) empty_df(raw_region = character(), n_rows = integer()))
  if (!nrow(out)) return(empty_spatial_region_counts())
  code <- normalize_dk_region(out$raw_region)
  out <- data.frame(
    region_code = code,
    n_rows = suppressWarnings(as.integer(out$n_rows)),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$region_code), , drop = FALSE]
  if (!nrow(out)) return(empty_spatial_region_counts())
  out <- aggregate(n_rows ~ region_code, data = out, FUN = sum)
  out <- out[out$n_rows >= normalize_min_cell_count(min_cell_count), , drop = FALSE]
  if (!nrow(out)) return(empty_spatial_region_counts())
  ref <- dk_region_reference()
  out <- merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE)
  data.frame(
    table_name = source_row$table_name[[1]],
    domain = "",
    subdomain = "",
    atlas_role = "",
    region_column = region_col,
    region_code = out$region_code,
    region_name = out$region_name,
    n_rows = out$n_rows,
    pct_rows = vapply(out$n_rows, safe_pct, numeric(1), denom = source_row$n_rows[[1]]),
    count_basis = "region_column_counts",
    stringsAsFactors = FALSE
  )
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
    row_total <- suppressWarnings(sum(as.numeric(domain_sources$n_rows), na.rm = TRUE))
    for (i in seq_len(nrow(ref))) {
      region <- ref[i, , drop = FALSE]
      status <- "unknown"
      basis <- "source_metadata"
      if (loaded_sources > 0 && domain %in% c("RKKP", "SDS", "DALY Views", "Core")) {
        status <- "nationwide"
      } else if (loaded_sources > 0 && identical(domain, "SP")) {
        status <- if (isTRUE(region$ehr_default[[1]])) "ehr" else "none"
      } else if (loaded_sources > 0) {
        status <- "available"
      } else if (mapped_sources > 0) {
        status <- "mapped_not_loaded"
      }
      if (is.data.frame(region_counts) && nrow(region_counts)) {
        observed <- region_counts[region_counts$domain == domain & region_counts$region_code == region$region_code[[1]], , drop = FALSE]
        if (nrow(observed) && sum(observed$n_rows, na.rm = TRUE) > 0) {
          status <- "observed"
          basis <- "observed_region_counts"
        }
      }
      rows[[length(rows) + 1L]] <- data.frame(
        region_code = region$region_code,
        region_name = region$region_name,
        display_label = region$display_label,
        domain = domain,
        coverage_status = status,
        loaded_sources = loaded_sources,
        mapped_sources = mapped_sources,
        n_rows = row_total,
        basis = basis,
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
  if (is.list(panels) && "damyda_clinical_profile" %in% names(panels)) {
    damyda <- panels$damyda_clinical_profile
    if (is.data.frame(damyda) && nrow(damyda)) {
      damyda <- damyda[damyda$facet == "region", , drop = FALSE]
      if (nrow(damyda)) {
        code <- normalize_dk_region(damyda$label)
        out <- data.frame(region_code = code, damyda_n = suppressWarnings(as.integer(damyda$n)), stringsAsFactors = FALSE)
        out <- out[!is.na(out$region_code), , drop = FALSE]
        if (nrow(out)) {
          out <- aggregate(damyda_n ~ region_code, data = out, FUN = sum)
          return(merge(out, ref[, c("region_code", "region_name")], by = "region_code", all.x = TRUE, sort = FALSE))
        }
      }
    }
  }
  if (is.data.frame(region_counts) && nrow(region_counts)) {
    out <- region_counts[region_counts$table_name == "RKKP_DaMyDa", c("region_code", "n_rows"), drop = FALSE]
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
  out$damyda_n <- 0L
  if (nrow(damyda_counts)) {
    idx <- match(out$region_code, damyda_counts$region_code)
    out$damyda_n <- ifelse(is.na(idx), 0L, as.integer(damyda_counts$damyda_n[idx]))
  }
  map_total <- sum(out$damyda_n[out$map_include], na.rm = TRUE)
  out$choropleth_value <- if (map_total > 0) out$damyda_n else ifelse(out$ehr_default, 1, 0)
  out$pct_total <- if (map_total > 0) vapply(out$damyda_n, safe_pct, numeric(1), denom = map_total) else NA_real_
  out$choropleth_basis <- if (map_total > 0) "DaMyDa region count" else "source coverage status"
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
  if (!"atlas_temporal_coverage_years" %in% names(panels) ||
      !is.data.frame(panels$atlas_temporal_coverage_years) ||
      !nrow(panels$atlas_temporal_coverage_years)) {
    panels$atlas_temporal_coverage_years <- coverage_year_rows_from_ranges(panels$atlas_temporal_coverage)
  }
  panels$atlas_temporal_coverage_years <- add_source_context_to_coverage_panels(
    panels$atlas_temporal_coverage_years, sources
  )
  panels$atlas_spatial_region_counts <- add_source_context_to_coverage_panels(
    panels$atlas_spatial_region_counts %||% empty_spatial_region_counts(), sources
  )
  if (!nrow(panels$atlas_spatial_region_counts)) {
    panels$atlas_spatial_region_counts <- spatial_region_counts_from_registry_panels(
      panels = panels,
      min_cell_count = min_cell_count
    )
  }
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
