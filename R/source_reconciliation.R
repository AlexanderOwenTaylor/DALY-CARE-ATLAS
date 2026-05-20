expected_dalycare_resource_columns <- function() {
  c(
    "expected_resource_id", "display_name", "domain", "modality", "description",
    "expected_role", "legacy_rows", "legacy_patients", "legacy_status",
    "known_aliases", "legacy_resolution_strategy", "known_absence_status", "notes"
  )
}

empty_expected_dalycare_resources <- function() {
  empty_df(
    expected_resource_id = character(),
    display_name = character(),
    domain = character(),
    modality = character(),
    description = character(),
    expected_role = character(),
    legacy_rows = character(),
    legacy_patients = character(),
    legacy_status = character(),
    known_aliases = character(),
    legacy_resolution_strategy = character(),
    known_absence_status = character(),
    notes = character()
  )
}

read_expected_dalycare_resources <- function(project_root = ".") {
  path <- file.path(project_root, "config", "expected_dalycare_resources_64.tsv")
  if (!file.exists(path)) return(empty_expected_dalycare_resources())
  out <- read_delimited_file(path)
  missing <- setdiff(expected_dalycare_resource_columns(), names(out))
  for (nm in missing) out[[nm]] <- ""
  out <- out[expected_dalycare_resource_columns()]
  out[] <- lapply(out, as.character)
  out
}

legacy_cartography_reference_dir <- function(project_root = ".") {
  file.path(project_root, "config", "cartography-reference", "files")
}

safe_read_reference_file <- function(project_root, file_name) {
  path <- file.path(legacy_cartography_reference_dir(project_root), file_name)
  if (!file.exists(path)) return(data.frame(stringsAsFactors = FALSE))
  tryCatch(read_delimited_file(path), error = function(e) data.frame(stringsAsFactors = FALSE))
}

legacy_v33_html_candidates <- function(project_root = ".") {
  c(
    file.path(project_root, "_legacy_cartography_inspect", "DALYCARE_atlas_AOT_V33.html"),
    file.path(project_root, "DALYCARE_atlas_AOT_V33.html"),
    file.path(project_root, "config", "cartography-reference", "DALYCARE_atlas_AOT_V33.html")
  )
}

extract_js_object_after_marker <- function(text, marker) {
  start <- regexpr(marker, text, fixed = TRUE)[[1]]
  if (is.na(start) || start < 0) return("")
  after <- substr(text, start + nchar(marker), nchar(text))
  brace_start <- regexpr("{", after, fixed = TRUE)[[1]]
  if (is.na(brace_start) || brace_start < 0) return("")
  chars <- strsplit(substr(after, brace_start, nchar(after)), "", fixed = TRUE)[[1]]
  depth <- 0L
  in_string <- FALSE
  escaped <- FALSE
  for (i in seq_along(chars)) {
    ch <- chars[[i]]
    if (in_string) {
      if (escaped) {
        escaped <- FALSE
      } else if (identical(ch, "\\")) {
        escaped <- TRUE
      } else if (identical(ch, "\"")) {
        in_string <- FALSE
      }
    } else if (identical(ch, "\"")) {
      in_string <- TRUE
    } else if (identical(ch, "{")) {
      depth <- depth + 1L
    } else if (identical(ch, "}")) {
      depth <- depth - 1L
      if (identical(depth, 0L)) {
        return(paste(chars[seq_len(i)], collapse = ""))
      }
    }
  }
  ""
}

read_legacy_v33_data <- function(project_root = ".") {
  html_path <- legacy_v33_html_candidates(project_root)
  html_path <- html_path[file.exists(html_path)]
  if (!length(html_path) || !requireNamespace("jsonlite", quietly = TRUE)) {
    return(list(data = NULL, source_file = ""))
  }
  html <- paste(readLines(html_path[[1]], warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  object <- extract_js_object_after_marker(html, "const DATA =")
  if (!nzchar(object)) return(list(data = NULL, source_file = html_path[[1]]))
  data <- tryCatch(jsonlite::fromJSON(object, simplifyVector = FALSE), error = function(e) NULL)
  list(data = data, source_file = html_path[[1]])
}

legacy_v33_list_rows <- function(x) {
  if (!length(x)) return(data.frame(stringsAsFactors = FALSE))
  rows <- lapply(x, function(row) {
    if (!is.list(row)) return(data.frame(value = as.character(row), stringsAsFactors = FALSE))
    values <- lapply(row, function(value) {
      if (length(value) == 0) return("")
      if (is.atomic(value) && length(value) == 1) return(as.character(value))
      ""
    })
    as.data.frame(values, stringsAsFactors = FALSE, check.names = FALSE)
  })
  bind_rows_base(rows)
}

legacy_v33_resource_evidence <- function(project_root = ".") {
  expected <- read_expected_dalycare_resources(project_root)
  parsed <- read_legacy_v33_data(project_root)
  data <- parsed$data
  if (is.null(data) || !nrow(expected)) {
    if (!nrow(expected)) {
      return(empty_df(
        expected_resource_id = character(),
        v033_catalog_status = character(),
        v033_catalog_rows = character(),
        v033_catalog_notes = character(),
        v033_evidence_source = character()
      ))
    }
    load_status <- safe_read_reference_file(project_root, "cartography_dataset_load_status_updated.tsv")
    html_path <- legacy_v33_html_candidates(project_root)
    html_path <- html_path[file.exists(html_path)]
    rows <- lapply(seq_len(nrow(expected)), function(i) {
      row <- expected[i, , drop = FALSE]
      aliases <- resource_alias_vector(row)
      load_hit <- match_by_resource_alias(aliases, load_status, c("requested_source", "resolved_object"))
      legacy_status <- row$legacy_status[[1]] %||% ""
      status <- if (legacy_status %in% c("loaded")) {
        "profiled"
      } else if (legacy_status %in% c("db_resolved")) {
        "resolved"
      } else if (legacy_status %in% c("special_manual_embedded")) {
        "resolved"
      } else if (legacy_status %in% c("known_unavailable")) {
        "not_in_database"
      } else {
        ""
      }
      data.frame(
        expected_resource_id = row$expected_resource_id[[1]],
        v033_catalog_status = status,
        v033_catalog_rows = resource_first_nonblank(
          if (nrow(load_hit)) load_hit$n_rows[[1]] else "",
          row$legacy_rows[[1]] %||% ""
        ),
        v033_catalog_notes = resource_first_nonblank(
          row$notes[[1]] %||% "",
          if (nrow(load_hit)) paste("Generated legacy load/profile evidence for", load_hit$resolved_object[[1]] %||% load_hit$requested_source[[1]] %||% row$expected_resource_id[[1]]) else ""
        ),
        v033_evidence_source = if (length(html_path)) html_path[[1]] else "config/expected_dalycare_resources_64.tsv",
        stringsAsFactors = FALSE
      )
    })
    return(bind_rows_base(rows))
  }
  loaded <- legacy_v33_list_rows(data$loadedDatasets)
  resolved <- legacy_v33_list_rows(data$part4_resolved)
  catalog <- legacy_v33_list_rows(data$resourceCatalog)
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- expected[i, , drop = FALSE]
    aliases <- resource_alias_vector(row)
    loaded_hit <- match_by_resource_alias(aliases, loaded, c("name"))
    resolved_hit <- match_by_resource_alias(aliases, resolved, c("name", "desc"))
    catalog_hit <- match_by_resource_alias(aliases, catalog, c("dataset", "loaded_name", "title"))
    status <- ""
    n_rows <- ""
    notes <- ""
    source <- parsed$source_file %||% ""
    if (nrow(resolved_hit)) {
      hit <- resolved_hit[1, , drop = FALSE]
      status <- "resolved"
      n_rows <- resource_first_nonblank(hit$rows[[1]] %||% "")
      notes <- resource_first_nonblank(hit$desc[[1]] %||% "", "Final V33 part4_resolved entry.")
    } else if (nrow(loaded_hit)) {
      hit <- loaded_hit[1, , drop = FALSE]
      status <- "profiled"
      n_rows <- resource_first_nonblank(hit$rows[[1]] %||% "")
      notes <- paste("Final V33 loadedDatasets entry:", hit$name[[1]] %||% "")
    } else if (nrow(catalog_hit)) {
      hit <- catalog_hit[1, , drop = FALSE]
      raw_status <- hit$status[[1]] %||% ""
      status <- if (identical(raw_status, "loaded")) "profiled" else "catalogued_unloaded"
      notes <- paste(
        "Final V33 resourceCatalog entry:",
        resource_first_nonblank(hit$title[[1]] %||% "", hit$dataset[[1]] %||% "")
      )
    }
    if (nzchar(row$known_absence_status[[1]] %||% "") &&
        grepl("known_unavailable", row$known_absence_status[[1]], fixed = TRUE) &&
        !nzchar(n_rows) && !nrow(resolved_hit) && !nrow(loaded_hit)) {
      status <- "not_in_database"
      notes <- resource_first_nonblank(notes, row$notes[[1]], "Expected by V33 but known unavailable.")
    }
    data.frame(
      expected_resource_id = row$expected_resource_id[[1]],
      v033_catalog_status = status,
      v033_catalog_rows = n_rows,
      v033_catalog_notes = notes,
      v033_evidence_source = source,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

resource_alias_vector <- function(row) {
  values <- c(
    row$expected_resource_id[[1]] %||% "",
    row$canonical_resource_id[[1]] %||% "",
    row$display_name[[1]] %||% "",
    row$preferred_current_source_key[[1]] %||% "",
    row$preferred_table_or_view[[1]] %||% "",
    row$current_source_key[[1]] %||% "",
    row$preferred_table[[1]] %||% "",
    row$source_key[[1]] %||% "",
    row$table_name[[1]] %||% "",
    row$source[[1]] %||% "",
    row$table[[1]] %||% "",
    row$table_or_view[[1]] %||% "",
    unlist(strsplit(row$known_aliases[[1]] %||% "", ";", fixed = TRUE), use.names = FALSE)
  )
  unique(trimws(values[nzchar(trimws(values))]))
}

resource_key <- function(x) {
  if (exists("normalized_table_key", mode = "function")) {
    return(normalized_table_key(x))
  }
  x <- as.character(x)
  x <- gsub("æ|Æ", "ae", x)
  x <- gsub("ø|Ø", "oe", x)
  x <- gsub("å|Å", "aa", x)
  folded <- suppressWarnings(iconv(x, from = "", to = "ASCII//TRANSLIT", sub = ""))
  folded[is.na(folded)] <- x[is.na(folded)]
  gsub("[^a-z0-9]", "", tolower(folded))
}

match_by_resource_alias <- function(aliases, df, columns) {
  if (!is.data.frame(df) || !nrow(df)) return(data.frame(stringsAsFactors = FALSE))
  columns <- intersect(columns, names(df))
  if (!length(columns)) return(df[0, , drop = FALSE])
  alias_keys <- resource_key(aliases)
  alias_keys <- alias_keys[nzchar(alias_keys)]
  if (!length(alias_keys)) return(df[0, , drop = FALSE])
  hit <- rep(FALSE, nrow(df))
  for (nm in columns) {
    hit <- hit | resource_key(df[[nm]]) %in% alias_keys
  }
  df[hit, , drop = FALSE]
}

resource_first_nonblank <- function(...) {
  values <- unlist(list(...), use.names = FALSE)
  values <- as.character(values)
  values <- values[!is.na(values) & nzchar(trimws(values))]
  if (!length(values)) return("")
  values[[1]]
}

legacy_method_label <- function(status, strategy, source_file) {
  status <- status %||% ""
  strategy <- strategy %||% ""
  source_file <- source_file %||% ""
  if (status %in% c("known_unavailable", "confirmed_absent", "absent")) return("last_resort_absence_search")
  if (identical(status, "special_manual_embedded")) return("special_manual_embedded")
  if (grepl("part6", source_file, ignore.case = TRUE)) return("direct_sql_name_variant")
  if (grepl("part4", source_file, ignore.case = TRUE)) return("direct_sql_alias_or_table_pattern")
  if (grepl("load_dataset|direct_get_after_safe_load", strategy, ignore.case = TRUE)) return("standard_load_dataset")
  if (nzchar(strategy)) return(strategy)
  "not_documented"
}

build_legacy_cartography_source_resolution_audit <- function(project_root = ".") {
  expected <- read_expected_dalycare_resources(project_root)
  if (!nrow(expected)) {
    return(empty_df(
      expected_resource_id = character(), legacy_display_name = character(), domain = character(),
      legacy_status = character(), legacy_rows = character(), legacy_patients_if_available = character(),
      resolved_by_legacy_script = logical(), legacy_script_file = character(),
      legacy_script_function_or_section = character(), legacy_resolution_method = character(),
      legacy_query_or_table_pattern = character(), known_aliases = character(),
      failure_or_absence_reason = character(), notes = character()
    ))
  }

  load_status <- safe_read_reference_file(project_root, "cartography_dataset_load_status_updated.tsv")
  part4 <- safe_read_reference_file(project_root, "cartography_part4_resolution_log.tsv")
  part6 <- safe_read_reference_file(project_root, "cartography_part6_resolution_log.tsv")
  v33 <- legacy_v33_resource_evidence(project_root)

  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- expected[i, , drop = FALSE]
    aliases <- resource_alias_vector(row)
    load_hit <- match_by_resource_alias(aliases, load_status, c("requested_source", "resolved_object"))
    p4_hit <- match_by_resource_alias(aliases, part4, c("dataset", "db_location"))
    p6_hit <- match_by_resource_alias(aliases, part6, c("dataset", "db_table", "db_ref"))
    v33_hit <- v33[v33$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]

    legacy_status <- row$legacy_status[[1]] %||% ""
    legacy_rows <- row$legacy_rows[[1]] %||% ""
    legacy_patients <- row$legacy_patients[[1]] %||% ""
    script_file <- ""
    section <- ""
    method <- row$legacy_resolution_strategy[[1]] %||% ""
    pattern <- ""
    absence <- row$known_absence_status[[1]] %||% ""
    notes <- row$notes[[1]] %||% ""
    display <- row$display_name[[1]] %||% row$expected_resource_id[[1]]

    if (nrow(load_hit)) {
      hit <- load_hit[1, , drop = FALSE]
      if (nzchar(hit$load_status[[1]] %||% "")) legacy_status <- hit$load_status[[1]]
      legacy_rows <- resource_first_nonblank(hit$n_rows[[1]] %||% "", legacy_rows)
      legacy_patients <- resource_first_nonblank(hit$n_patients[[1]] %||% "", legacy_patients)
      display <- resource_first_nonblank(hit$requested_source[[1]] %||% "", display)
      script_file <- "000_dalycare_cartography.R"
      section <- "default_datasets + safe_load_dataset/load_dataset inventory loop"
      method <- resource_first_nonblank(hit$resolution_method[[1]] %||% "", method)
      pattern <- resource_first_nonblank(hit$resolved_object[[1]] %||% "", pattern)
      notes <- resource_first_nonblank(hit$note[[1]] %||% "", notes)
    }
    if (nrow(p4_hit) && any(p4_hit$status == "resolved", na.rm = TRUE)) {
      hit <- p4_hit[p4_hit$status == "resolved", , drop = FALSE][1, , drop = FALSE]
      legacy_status <- "db_resolved_part4"
      legacy_rows <- resource_first_nonblank(hit$n_rows[[1]] %||% "", legacy_rows)
      legacy_patients <- resource_first_nonblank(hit$n_patients[[1]] %||% "", legacy_patients)
      display <- resource_first_nonblank(hit$dataset[[1]] %||% "", display)
      script_file <- "000_dalycare_cartography_part4.R"
      section <- "unresolved table patterns + profile_via_db()"
      method <- "direct PostgreSQL table-pattern resolver"
      pattern <- resource_first_nonblank(hit$db_location[[1]] %||% "", pattern)
      notes <- resource_first_nonblank(hit$description[[1]] %||% "", notes)
    }
    if (nrow(p6_hit)) {
      hit <- p6_hit[1, , drop = FALSE]
      display <- resource_first_nonblank(hit$dataset[[1]] %||% "", display)
      script_file <- "000_dalycare_cartography_part6.R"
      section <- "final frontier exact name-variant resolver"
      legacy_status <- if (identical(hit$status[[1]], "resolved")) "db_resolved_part6" else "known_unavailable"
      legacy_rows <- resource_first_nonblank(hit$n_rows[[1]] %||% "", legacy_rows)
      legacy_patients <- resource_first_nonblank(hit$n_patients[[1]] %||% "", legacy_patients)
      method <- if (identical(hit$status[[1]], "resolved")) {
        "direct PostgreSQL exact name-variant query"
      } else {
        "last-resort database/schema search"
      }
      pattern <- resource_first_nonblank(hit$db_ref[[1]] %||% "", hit$db_table[[1]] %||% "", pattern)
      absence <- if (!identical(hit$status[[1]], "resolved")) resource_first_nonblank(absence, "known_unavailable_not_in_database") else absence
      notes <- resource_first_nonblank(hit$note[[1]] %||% "", notes)
    }
    if (identical(row$legacy_status[[1]], "special_manual_embedded")) {
      legacy_status <- "special_manual_embedded"
      script_file <- resource_first_nonblank(script_file, "000_dalycare_cartography_part7.R; DALYCARE_atlas_AOT_V33.html")
      section <- "last-resort embedded registry/file search + final V33 part4_resolved"
      method <- "special/manual/embedded resource search"
      if (identical(row$expected_resource_id[[1]], "DANRICHT")) {
        pattern <- resource_first_nonblank(pattern, "danricht_clean.parquet; DANRICHT_20240412.csv")
      } else if (identical(row$expected_resource_id[[1]], "FISH")) {
        pattern <- resource_first_nonblank(pattern, "RKKP_CLL and RKKP_DaMyDa embedded FISH columns")
      }
      if (nrow(v33_hit)) {
        legacy_rows <- resource_first_nonblank(legacy_rows, v33_hit$v033_catalog_rows[[1]] %||% "")
        notes <- resource_first_nonblank(v33_hit$v033_catalog_notes[[1]] %||% "", row$notes[[1]], notes)
      } else {
        notes <- resource_first_nonblank(row$notes[[1]], notes)
      }
    }
    if (identical(row$legacy_status[[1]], "known_unavailable")) {
      legacy_status <- "known_unavailable"
      script_file <- resource_first_nonblank(script_file, "000_dalycare_cartography_part6.R; 000_dalycare_cartography_part7.R")
      section <- resource_first_nonblank(section, "last-resort absence search")
      method <- resource_first_nonblank(method, "last-resort database/schema/file search")
      absence <- resource_first_nonblank(absence, "known_unavailable_not_in_database")
      notes <- resource_first_nonblank(row$notes[[1]], notes)
    }

    resolved <- legacy_status %in% c("loaded", "db_resolved", "db_resolved_part4", "db_resolved_part6", "special_manual_embedded")
    data.frame(
      expected_resource_id = row$expected_resource_id[[1]],
      legacy_display_name = display,
      domain = row$domain[[1]],
      legacy_status = legacy_status,
      legacy_rows = legacy_rows,
      legacy_patients_if_available = legacy_patients,
      resolved_by_legacy_script = resolved,
      legacy_script_file = script_file,
      legacy_script_function_or_section = section,
      legacy_resolution_method = legacy_method_label(legacy_status, method, script_file),
      legacy_query_or_table_pattern = pattern,
      known_aliases = row$known_aliases[[1]],
      failure_or_absence_reason = absence,
      notes = notes,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

current_resource_match <- function(row, sources = NULL, source_resolution = NULL, source_map = NULL) {
  aliases <- resource_alias_vector(row)
  source_hit <- match_by_resource_alias(
    aliases,
    sources,
    c("table_name", "source", "table", "db_name", "schema")
  )
  resolution_hit <- match_by_resource_alias(
    aliases,
    source_resolution,
    c("table_name", "source", "table", "suggested_table", "candidate_locations")
  )
  map_hit <- match_by_resource_alias(aliases, source_map, c("table_name", "source", "table"))
  list(source_hit = source_hit, resolution_hit = resolution_hit, map_hit = map_hit)
}

current_resolution_strategy <- function(source_hit, resolution_hit) {
  if (nrow(source_hit)) {
    strategy <- source_hit$chosen_strategy[[1]] %||% ""
    if (nzchar(strategy)) return(strategy)
    if (tolower(source_hit$source_type[[1]] %||% "") == "file") return("special_or_manual_file")
  }
  if (nrow(resolution_hit)) {
    status <- resolution_hit$resolution_status[[1]] %||% ""
    if (identical(status, "resolved")) {
      requested <- resource_key(c(resolution_hit$table_name[[1]], resolution_hit$source[[1]]))
      resolved <- resource_key(resolution_hit$table[[1]])
      if (nzchar(resolved[[1]] %||% "") && !resolved[[1]] %in% requested) return("alias_or_direct_sql_resolved")
      return("standard_source_map_resolved")
    }
    if (nzchar(status)) return(status)
  }
  "not_tested_current"
}

canonical_dalycare_resource_columns <- function() {
  c(
    "canonical_resource_id", "display_name", "domain", "legacy_status",
    "legacy_resolution_method", "current_expected_strategy",
    "preferred_current_source_key", "preferred_schema", "preferred_table_or_view",
    "known_aliases", "source_map_role", "requires_direct_sql",
    "requires_manual_file", "requires_embedded_field_mapping",
    "current_validation_status", "notes"
  )
}

empty_canonical_dalycare_resources <- function() {
  as.data.frame(
    stats::setNames(rep(list(character()), length(canonical_dalycare_resource_columns())), canonical_dalycare_resource_columns()),
    stringsAsFactors = FALSE
  )
}

read_canonical_dalycare_resources <- function(project_root = ".") {
  path <- file.path(project_root, "config", "canonical-dalycare-resources-64.tsv")
  if (file.exists(path)) {
    out <- read_delimited_file(path)
  } else {
    expected <- read_expected_dalycare_resources(project_root)
    plan <- read_production_source_recovery_map(project_root)
    if (!nrow(expected)) return(empty_canonical_dalycare_resources())
    out <- lapply(seq_len(nrow(expected)), function(i) {
      row <- expected[i, , drop = FALSE]
      plan_row <- plan[plan$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
      if (!nrow(plan_row)) plan_row <- data.frame(stringsAsFactors = FALSE)
      resolver <- plan_row$resolver_type[[1]] %||% ""
      data.frame(
        canonical_resource_id = row$expected_resource_id[[1]],
        display_name = row$display_name[[1]],
        domain = row$domain[[1]],
        legacy_status = row$legacy_status[[1]],
        legacy_resolution_method = row$legacy_resolution_strategy[[1]],
        current_expected_strategy = resource_first_nonblank(resolver, "needs_manual_review"),
        preferred_current_source_key = resource_first_nonblank(plan_row$current_source_key[[1]] %||% "", plan_row$source[[1]] %||% "", row$expected_resource_id[[1]]),
        preferred_schema = plan_row$preferred_schema[[1]] %||% "",
        preferred_table_or_view = resource_first_nonblank(plan_row$preferred_table[[1]] %||% "", plan_row$table[[1]] %||% ""),
        known_aliases = resource_first_nonblank(plan_row$known_aliases[[1]] %||% "", row$known_aliases[[1]]),
        source_map_role = if (resolver %in% c("manual_file", "embedded_fields")) "special_manual_or_embedded" else "canonical_resource",
        requires_direct_sql = plan_row$requires_direct_sql[[1]] %||% "FALSE",
        requires_manual_file = plan_row$requires_manual_file[[1]] %||% "FALSE",
        requires_embedded_field_mapping = if (identical(resolver, "embedded_fields")) "TRUE" else "FALSE",
        current_validation_status = if (identical(row$expected_resource_id[[1]], "BilleddiagnostikeUndersøgelser_Del2")) {
          "legacy_unavailable_current_candidate"
        } else if (resolver %in% c("manual_file", "embedded_fields")) {
          "special_manual_or_embedded"
        } else {
          "resolver_configured"
        },
        notes = resource_first_nonblank(plan_row$notes[[1]] %||% "", row$notes[[1]]),
        stringsAsFactors = FALSE
      )
    })
    out <- bind_rows_base(out)
  }
  missing <- setdiff(canonical_dalycare_resource_columns(), names(out))
  for (nm in missing) out[[nm]] <- ""
  out <- out[canonical_dalycare_resource_columns()]
  out[] <- lapply(out, as.character)
  out
}

source_row_profiled <- function(row) {
  if (!is.data.frame(row) || !nrow(row)) return(FALSE)
  if ("load_status" %in% names(row)) {
    return(any(tolower(row$load_status %||% "") == "ok", na.rm = TRUE))
  }
  TRUE
}

canonical_special_status <- function(row, sources = NULL, columns = NULL) {
  id <- resource_key(resource_first_nonblank(
    if ("canonical_resource_id" %in% names(row)) row$canonical_resource_id[[1]] else "",
    if ("expected_resource_id" %in% names(row)) row$expected_resource_id[[1]] else ""
  ))
  strategy <- resource_first_nonblank(
    if ("current_expected_strategy" %in% names(row)) row$current_expected_strategy[[1]] else "",
    if ("resolver_type" %in% names(row)) row$resolver_type[[1]] else ""
  )
  if (identical(id, resource_key("FISH")) || identical(strategy, "embedded_fields")) {
    fish_source <- if (is.data.frame(sources) && nrow(sources)) {
      sources[resource_key(sources$canonical_resource_id %||% sources$table_name %||% "") == resource_key("FISH"), , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    if (nrow(fish_source) && any(fish_source$load_status == "embedded_fields_represented", na.rm = TRUE)) {
      return("embedded_fields_represented")
    }
    return("special_manual_or_embedded")
  }
  if (identical(id, resource_key("DANRICHT")) || identical(strategy, "manual_file")) {
    danricht_source <- if (is.data.frame(sources) && nrow(sources)) {
      sources[resource_key(sources$canonical_resource_id %||% sources$table_name %||% "") == resource_key("DANRICHT"), , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    if (nrow(danricht_source) && any(danricht_source$load_status == "manual_file_not_available", na.rm = TRUE)) {
      return("manual_file_not_available")
    }
    return("special_manual_or_embedded")
  }
  ""
}

source_map_row_role_flags <- function(row) {
  hay <- tolower(paste(row$table_name[[1]] %||% "", row$source[[1]] %||% "", row$domain[[1]] %||% "", row$atlas_role[[1]] %||% ""))
  explicit_role <- row$source_map_role[[1]] %||% ""
  is_derived <- grepl("(^|[^a-z0-9])view|daly views|documented|survival|followup|follow-up", hay) ||
    identical(explicit_role, "derived_view")
  is_helper <- grepl("koder|lookup|helper|reference", hay) ||
    identical(explicit_role, "helper_table")
  list(is_derived_view = is_derived, is_helper_table = is_helper, explicit_role = explicit_role)
}

source_map_row_roles <- function(row, canonical_hit = NULL) {
  flags <- source_map_row_role_flags(row)
  is_canonical <- is.data.frame(canonical_hit) && nrow(canonical_hit) > 0
  primary <- if (is_canonical) {
    "canonical_resource"
  } else if (flags$is_helper_table) {
    "helper_table"
  } else if (flags$is_derived_view) {
    "derived_view"
  } else if (nzchar(flags$explicit_role)) {
    flags$explicit_role
  } else {
    "ambiguous_manual_review"
  }
  secondary <- c()
  if (is_canonical && flags$is_derived_view) secondary <- c(secondary, "derived_view")
  if (is_canonical && flags$is_helper_table) secondary <- c(secondary, "helper_table")
  list(
    primary = primary,
    secondary = paste(unique(secondary), collapse = ";"),
    is_canonical_resource = is_canonical,
    is_derived_view = flags$is_derived_view,
    is_helper_table = flags$is_helper_table
  )
}

source_map_row_role <- function(row, canonical_hit = NULL) {
  source_map_row_roles(row, canonical_hit)$primary
}

source_map_row_role_note <- function(roles) {
  if (isTRUE(roles$is_canonical_resource) && isTRUE(roles$is_derived_view)) {
    return("Source-map row maps to a canonical resource and is also implemented as a derived/view layer.")
  }
  if (isTRUE(roles$is_canonical_resource) && isTRUE(roles$is_helper_table)) {
    return("Source-map row maps to a canonical resource and also behaves as a helper/reference table.")
  }
  if (isTRUE(roles$is_canonical_resource)) return("Matched canonical resource by exact alias/source-map key.")
  if (isTRUE(roles$is_derived_view)) return("Derived/view row retained for atlas support; not counted as a canonical resource unless explicitly mapped.")
  if (isTRUE(roles$is_helper_table)) return("Helper/reference table retained for atlas support; not counted as a canonical resource unless explicitly mapped.")
  "No canonical resource match; classified for manual review."
}

source_map_row_role_legacy <- function(row, canonical_hit = NULL) {
  if (is.data.frame(canonical_hit) && nrow(canonical_hit)) {
    role <- canonical_hit$source_map_role[[1]] %||% ""
    if (nzchar(role)) return(role)
    return("canonical_resource")
  }
  source_map_row_role(row, canonical_hit)
}

match_source_map_row_to_canonical <- function(row, canonical) {
  if (!is.data.frame(canonical) || !nrow(canonical)) return(canonical[0, , drop = FALSE])
  candidates <- unique(resource_key(c(
    row$canonical_resource_id[[1]] %||% "",
    row$expected_resource_id[[1]] %||% "",
    row$table_name[[1]] %||% "",
    row$source[[1]] %||% "",
    row$table[[1]] %||% "",
    row$source_key[[1]] %||% "",
    row$current_source_key[[1]] %||% ""
  )))
  candidates <- candidates[nzchar(candidates)]
  if (!length(candidates)) return(canonical[0, , drop = FALSE])
  hit <- vapply(seq_len(nrow(canonical)), function(i) {
    aliases <- resource_key(resource_alias_vector(canonical[i, , drop = FALSE]))
    any(candidates %in% aliases)
  }, logical(1))
  out <- canonical[hit, , drop = FALSE]
  if (!nrow(out)) return(out)
  out[1, , drop = FALSE]
}

source_hit_for_source_map_row <- function(row, sources = NULL, source_resolution = NULL) {
  aliases <- c(row$table_name[[1]] %||% "", row$source[[1]] %||% "", row$table[[1]] %||% "")
  list(
    source_hit = match_by_resource_alias(aliases, sources, c("table_name", "source", "table")),
    resolution_hit = match_by_resource_alias(aliases, source_resolution, c("table_name", "source", "table", "suggested_table", "candidate_locations"))
  )
}

build_source_map_row_to_canonical_resource_crosswalk <- function(project_root = ".", source_map = NULL,
                                                                sources = NULL, source_resolution = NULL,
                                                                canonical = NULL) {
  if (is.null(source_map) || !is.data.frame(source_map)) source_map <- data.frame(stringsAsFactors = FALSE)
  if (is.null(canonical)) canonical <- read_canonical_dalycare_resources(project_root)
  if (!nrow(source_map)) {
    return(empty_df(
      source_map_key = character(), source_map_label = character(),
      source_map_role_primary = character(), source_map_role_secondary = character(),
      source_map_role = character(), canonical_resource_id = character(),
      canonical_resource_display_name = character(), is_canonical_resource = logical(),
      is_derived_view = logical(), is_helper_table = logical(), is_current_profiled = logical(),
      current_profiled = logical(), current_n_rows = character(), current_n_columns = character(),
      role_notes = character(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(source_map)), function(i) {
    row <- source_map[i, , drop = FALSE]
    canonical_hit <- match_source_map_row_to_canonical(row, canonical)
    roles <- source_map_row_roles(row, canonical_hit)
    hit <- source_hit_for_source_map_row(row, sources, source_resolution)
    source_hit <- hit$source_hit
    resolution_hit <- hit$resolution_hit
    current_profiled <- source_row_profiled(source_hit)
    current_rows <- resource_first_nonblank(
      if (nrow(source_hit)) source_hit$n_rows[[1]] else "",
      if (nrow(resolution_hit)) resolution_hit$row_count[[1]] else ""
    )
    current_cols <- resource_first_nonblank(
      if (nrow(source_hit)) source_hit$n_cols[[1]] else "",
      if (nrow(source_hit)) source_hit$n_columns[[1]] else ""
    )
    data.frame(
      source_map_key = row$table_name[[1]] %||% row$source[[1]] %||% "",
      source_map_label = row$source_label[[1]] %||% row$source[[1]] %||% row$table_name[[1]] %||% "",
      source_map_role_primary = roles$primary,
      source_map_role_secondary = roles$secondary,
      source_map_role = roles$primary,
      canonical_resource_id = if (nrow(canonical_hit)) canonical_hit$canonical_resource_id[[1]] else "",
      canonical_resource_display_name = if (nrow(canonical_hit)) canonical_hit$display_name[[1]] else "",
      is_canonical_resource = roles$is_canonical_resource,
      is_derived_view = roles$is_derived_view,
      is_helper_table = roles$is_helper_table,
      is_current_profiled = current_profiled,
      current_profiled = current_profiled,
      current_n_rows = current_rows,
      current_n_columns = current_cols,
      role_notes = source_map_row_role_note(roles),
      notes = source_map_row_role_note(roles),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

build_current_run_source_map_audit <- function(project_root = ".", source_map = NULL, sources = NULL,
                                               source_resolution = NULL, canonical = NULL) {
  crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    canonical = canonical
  )
  if (!is.data.frame(source_map) || !nrow(source_map)) {
    return(empty_df(
      source_map_key = character(), source_map_name = character(), resolved_table_or_view = character(),
      schema = character(), n_rows_current = character(), n_columns_current = character(),
      canonical_resource_match = logical(), canonical_resource_id = character(),
      source_map_role = character(), is_canonical_resource = logical(),
      is_derived_view = logical(), is_helper_table = logical(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(source_map)), function(i) {
    row <- source_map[i, , drop = FALSE]
    cross <- crosswalk[i, , drop = FALSE]
    hit <- source_hit_for_source_map_row(row, sources, source_resolution)
    source_hit <- hit$source_hit
    resolution_hit <- hit$resolution_hit
    data.frame(
      source_map_key = row$table_name[[1]] %||% row$source[[1]] %||% "",
      source_map_name = row$source[[1]] %||% row$table_name[[1]] %||% "",
      resolved_table_or_view = resource_first_nonblank(
        if (nrow(resolution_hit)) resolution_hit$table[[1]] else "",
        if (nrow(source_hit)) source_hit$table[[1]] else "",
        if (nrow(source_hit)) source_hit$table_name[[1]] else ""
      ),
      schema = resource_first_nonblank(
        if (nrow(resolution_hit)) paste(resolution_hit$db_name[[1]], resolution_hit$schema[[1]], sep = ".") else "",
        if (nrow(source_hit)) paste(source_hit$db_name[[1]], source_hit$schema[[1]], sep = ".") else ""
      ),
      n_rows_current = cross$current_n_rows[[1]] %||% "",
      n_columns_current = if (nrow(source_hit)) source_hit$n_cols[[1]] %||% "" else "",
      canonical_resource_match = nzchar(cross$canonical_resource_id[[1]] %||% ""),
      canonical_resource_id = cross$canonical_resource_id[[1]] %||% "",
      source_map_role = cross$source_map_role[[1]] %||% "",
      is_canonical_resource = as.logical(cross$is_canonical_resource[[1]] %||% FALSE),
      is_derived_view = as.logical(cross$is_derived_view[[1]] %||% FALSE),
      is_helper_table = as.logical(cross$is_helper_table[[1]] %||% FALSE),
      notes = cross$notes[[1]] %||% "",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

build_canonical_resource_reconciliation_64 <- function(project_root = ".", source_map = NULL, sources = NULL,
                                                       source_resolution = NULL, canonical = NULL,
                                                       resource_reconciliation = NULL) {
  if (is.null(canonical)) canonical <- read_canonical_dalycare_resources(project_root)
  if (is.null(resource_reconciliation)) {
    resource_reconciliation <- build_atlas_resource_reconciliation(
      project_root = project_root,
      source_map = source_map,
      sources = sources,
      source_resolution = source_resolution
    )
  }
  crosswalk <- build_source_map_row_to_canonical_resource_crosswalk(
    project_root = project_root,
    source_map = source_map,
    sources = sources,
    source_resolution = source_resolution,
    canonical = canonical
  )
  if (!nrow(canonical)) {
    return(empty_df(
      canonical_resource_id = character(), display_name = character(), domain = character(),
      legacy_status = character(), current_expected_strategy = character(),
      current_attempted = logical(), current_profiled = logical(),
      current_resolved_source_key = character(), current_resolved_table_or_view = character(),
      current_n_rows = character(), current_n_columns = character(),
      source_map_role = character(), current_status = character(),
      discrepancy_flag = logical(), action_required = character(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(canonical)), function(i) {
    row <- canonical[i, , drop = FALSE]
    id <- row$canonical_resource_id[[1]]
    rec <- resource_reconciliation[resource_reconciliation$expected_resource_id == id, , drop = FALSE]
    cross <- crosswalk[crosswalk$canonical_resource_id == id, , drop = FALSE]
    profiled <- any(as.logical(cross$current_profiled %||% FALSE), na.rm = TRUE)
    profiled_index <- if (nrow(cross)) {
      hit <- which(as.logical(cross$current_profiled %||% FALSE))
      if (length(hit)) hit[[1]] else 1L
    } else {
      1L
    }
    attempted <- nrow(cross) > 0 || (nrow(rec) && rec$current_run_status[[1]] %in% c("Resolved current run", "Resolved by alias", "Resolved by direct SQL", "Missing unexpectedly"))
    if (nrow(rec) && rec$current_run_status[[1]] %in% c("Resolved current run", "Resolved by alias", "Resolved by direct SQL")) {
      profiled <- TRUE
    }
    del2_keys <- c(
      resource_key("BilleddiagnostikeUndersoegelser_Del2"),
      resource_key("BilleddiagnostikeUndersogelser_Del2")
    )
    special_status <- canonical_special_status(row, sources = sources)
    current_status <- if (resource_key(id) %in% del2_keys && isTRUE(profiled)) {
      "legacy_unavailable_current_resolved"
    } else if (isTRUE(profiled)) {
      "current_profiled"
    } else if (nrow(rec) && identical(rec$current_run_status[[1]], "Missing unexpectedly")) {
      "current_missing_after_attempt"
    } else if (nzchar(special_status)) {
      special_status
    } else if (identical(row$source_map_role[[1]] %||% "", "special_manual_or_embedded")) {
      "special_manual_or_embedded"
    } else {
      "current_not_attempted"
    }
    current_key <- resource_first_nonblank(
      if (nrow(cross)) cross$source_map_key[profiled_index] else "",
      if (nrow(rec)) rec$current_table_name[[1]] else ""
    )
    current_table <- if (nrow(rec)) rec$current_table_name[[1]] %||% "" else ""
    if (!nzchar(current_table) && nrow(cross) && isTRUE(profiled)) current_table <- current_key
    current_rows <- resource_first_nonblank(
      if (nrow(cross)) cross$current_n_rows[profiled_index] else "",
      if (nrow(rec)) rec$current_n_rows[[1]] else ""
    )
    source_hit <- if (isTRUE(profiled)) {
      match_by_resource_alias(resource_alias_vector(row), sources, c("table_name", "source", "table"))
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    current_cols <- if (nrow(source_hit)) source_hit$n_cols[[1]] %||% "" else ""
    action <- if (identical(current_status, "legacy_unavailable_current_resolved")) {
      "Preserve the current resolver; V033 legacy absence has been superseded by production evidence."
    } else if (identical(current_status, "current_profiled")) {
      "No action."
    } else if (identical(current_status, "embedded_fields_represented")) {
      "Represented through embedded fields in profiled registry resources; no standalone DB table required."
    } else if (identical(current_status, "manual_file_not_available")) {
      "Manual/on-disk source not loaded; provide the manual file if this special source should be profiled."
    } else if (identical(current_status, "special_manual_or_embedded")) {
      "Represented as special/manual or embedded evidence; add a normal source only if access allows."
    } else if (identical(current_status, "current_missing_after_attempt")) {
      "Review resolver aliases, schema/table spelling, or production access."
    } else {
      "Enable the restored 64-resource source map or add a resolver/source-map row before parity validation."
    }
    data.frame(
      canonical_resource_id = id,
      display_name = row$display_name[[1]],
      domain = row$domain[[1]],
      legacy_status = row$legacy_status[[1]],
      current_expected_strategy = row$current_expected_strategy[[1]],
      current_attempted = attempted,
      current_profiled = profiled,
      current_resolved_source_key = current_key,
      current_resolved_table_or_view = current_table,
      current_n_rows = current_rows,
      current_n_columns = current_cols,
      source_map_role = row$source_map_role[[1]],
      current_status = current_status,
      discrepancy_flag = current_status %in% c("current_missing_after_attempt"),
      action_required = action,
      notes = resource_first_nonblank(
        if (identical(current_status, "legacy_unavailable_current_resolved")) "Legacy V033 did not resolve this resource; resolved in the current production run." else "",
        if (nrow(rec)) rec$notes[[1]] else "",
        row$notes[[1]]
      ),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

semantic_source_rows <- function(df, evidence_type) {
  if (!is.data.frame(df) || !nrow(df) || !"source_name" %in% names(df)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  source_names <- unique_nonblank(df$source_name)
  if (!length(source_names)) return(data.frame(stringsAsFactors = FALSE))
  rows <- lapply(source_names, function(source_name) {
    hit <- df[df$source_name == source_name, , drop = FALSE]
    data.frame(
      evidence_source = source_name,
      evidence_type = evidence_type,
      evidence_file = resource_first_nonblank(hit$evidence_file[[1]] %||% ""),
      n_evidence_rows = nrow(hit),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

build_legacy_reference_vs_current_profiled_evidence <- function(project_root = ".", semantic_dictionary = NULL,
                                                               semantic_code_map = NULL, semantic_value_map = NULL,
                                                               canonical_reconciliation = NULL,
                                                               sources = NULL, canonical = NULL) {
  if (is.null(canonical)) canonical <- read_canonical_dalycare_resources(project_root)
  evidence <- bind_rows_base(list(
    semantic_source_rows(semantic_dictionary, "semantic_dictionary"),
    semantic_source_rows(semantic_code_map, "code_map"),
    semantic_source_rows(semantic_value_map, "value_map")
  ))
  if (!nrow(evidence)) {
    return(empty_df(
      evidence_source = character(), evidence_type = character(), canonical_resource_id = character(),
      appears_in_legacy_reference = logical(), current_profiled_this_run = logical(),
      current_source_key = character(), evidence_freshness_status = character(),
      warning_needed = logical(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(evidence)), function(i) {
    row <- evidence[i, , drop = FALSE]
    pseudo <- data.frame(
      table_name = row$evidence_source[[1]],
      source = row$evidence_source[[1]],
      known_aliases = "",
      stringsAsFactors = FALSE
    )
    canonical_hit <- match_source_map_row_to_canonical(pseudo, canonical)
    id <- if (nrow(canonical_hit)) canonical_hit$canonical_resource_id[[1]] else ""
    rec <- if (nzchar(id) && is.data.frame(canonical_reconciliation) && nrow(canonical_reconciliation)) {
      canonical_reconciliation[canonical_reconciliation$canonical_resource_id == id, , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    current_hit <- match_by_resource_alias(c(row$evidence_source[[1]]), sources, c("table_name", "source", "table"))
    current_profiled <- (nrow(rec) && isTRUE(as.logical(rec$current_profiled[[1]]))) || source_row_profiled(current_hit)
    legacy_reference <- grepl("cartography|reference|legacy", row$evidence_file[[1]] %||% "", ignore.case = TRUE) || !isTRUE(current_profiled)
    warning_needed <- isTRUE(legacy_reference) && !isTRUE(current_profiled)
    freshness <- if (nrow(rec) && rec$current_status[[1]] %in% c("special_manual_or_embedded", "embedded_fields_represented", "manual_file_not_available")) {
      "special_manual"
    } else if (isTRUE(current_profiled) && isTRUE(legacy_reference)) {
      "current_profiled_and_legacy_reference"
    } else if (isTRUE(current_profiled)) {
      "current_profiled"
    } else if (isTRUE(legacy_reference)) {
      "legacy_reference_only"
    } else {
      "unknown_manual_review"
    }
    data.frame(
      evidence_source = row$evidence_source[[1]],
      evidence_type = row$evidence_type[[1]],
      canonical_resource_id = id,
      appears_in_legacy_reference = legacy_reference,
      current_profiled_this_run = current_profiled,
      current_source_key = if (nrow(rec)) rec$current_resolved_source_key[[1]] %||% "" else "",
      evidence_freshness_status = freshness,
      warning_needed = warning_needed,
      notes = if (warning_needed) {
        "Evidence appears in semantic/reference outputs but was not profiled in this run."
      } else if (isTRUE(current_profiled)) {
        "Evidence source was profiled in the current run or matched a profiled canonical resource."
      } else {
        "Evidence source could not be matched to a canonical current-profiled source."
      },
      stringsAsFactors = FALSE
    )
  })
  unique(bind_rows_base(rows))
}

build_remaining_canonical_resources_activation_plan <- function(project_root = ".", canonical_reconciliation = NULL,
                                                               production_map = NULL, canonical = NULL) {
  if (is.null(canonical)) canonical <- read_canonical_dalycare_resources(project_root)
  if (is.null(production_map)) production_map <- read_production_source_recovery_map(project_root)
  if (!is.data.frame(canonical_reconciliation) || !nrow(canonical_reconciliation)) {
    canonical_reconciliation <- build_canonical_resource_reconciliation_64(project_root = project_root, canonical = canonical)
  }
  targets <- canonical_reconciliation[canonical_reconciliation$current_status == "current_not_attempted", , drop = FALSE]
  if (!nrow(targets)) {
    return(empty_df(
      canonical_resource_id = character(), display_name = character(), domain = character(),
      current_status = character(), preferred_resolver_type = character(),
      preferred_source_key = character(), preferred_schema = character(),
      preferred_table_or_view = character(), known_aliases = character(),
      requires_direct_sql = logical(), requires_manual_file = logical(),
      requires_permission = logical(), likely_reason_not_attempted = character(),
      activation_step = character(), priority = character(), manual_review_needed = logical(),
      notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(targets)), function(i) {
    row <- targets[i, , drop = FALSE]
    plan <- production_map[production_map$expected_resource_id == row$canonical_resource_id[[1]], , drop = FALSE]
    if (!nrow(plan)) plan <- data.frame(stringsAsFactors = FALSE)
    resolver <- plan$resolver_type[[1]] %||% row$current_expected_strategy[[1]] %||% ""
    requires_permission <- grepl("permission|REQUIRE_PERMISSION", paste(row$canonical_resource_id[[1]], plan$known_aliases[[1]] %||% "", plan$preferred_table[[1]] %||% "", plan$notes[[1]] %||% ""), ignore.case = TRUE)
    direct_sql <- source_recovery_truthy(plan$requires_direct_sql[[1]] %||% "") || resolver %in% c("direct_sql", "schema_qualified_table")
    manual_file <- source_recovery_truthy(plan$requires_manual_file[[1]] %||% "") || identical(resolver, "manual_file")
    priority <- if (requires_permission || resolver %in% c("manual_file", "embedded_fields")) {
      "manual_review"
    } else if (direct_sql) {
      "high"
    } else {
      "medium"
    }
    activation_step <- if (requires_permission) {
      "Confirm access/permission and enable the configured resolver in the restored production source map."
    } else if (manual_file) {
      "Provide the configured manual file in the production environment and rerun the restored source map."
    } else if (direct_sql) {
      "Enable the restored source-map row and validate the schema/table alias with production DB access."
    } else {
      "Enable the restored source-map row and rerun production profiling."
    }
    data.frame(
      canonical_resource_id = row$canonical_resource_id[[1]],
      display_name = row$display_name[[1]],
      domain = row$domain[[1]],
      current_status = row$current_status[[1]],
      preferred_resolver_type = resolver,
      preferred_source_key = resource_first_nonblank(plan$current_source_key[[1]] %||% "", plan$source[[1]] %||% "", row$canonical_resource_id[[1]]),
      preferred_schema = plan$preferred_schema[[1]] %||% "",
      preferred_table_or_view = resource_first_nonblank(plan$preferred_table[[1]] %||% "", plan$table[[1]] %||% ""),
      known_aliases = plan$known_aliases[[1]] %||% "",
      requires_direct_sql = direct_sql,
      requires_manual_file = manual_file,
      requires_permission = requires_permission,
      likely_reason_not_attempted = "Canonical resource was not included in the 48-row source map used for this production run.",
      activation_step = activation_step,
      priority = priority,
      manual_review_needed = requires_permission || resolver %in% c("manual_file", "embedded_fields", "needs_manual_review"),
      notes = resource_first_nonblank(plan$notes[[1]] %||% "", row$notes[[1]] %||% ""),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

canonical_resource_summary_metrics <- function(canonical_reconciliation = NULL, crosswalk = NULL,
                                               legacy_reference = NULL) {
  if (!is.data.frame(canonical_reconciliation)) canonical_reconciliation <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(crosswalk)) crosswalk <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(legacy_reference)) legacy_reference <- data.frame(stringsAsFactors = FALSE)
  current_status <- canonical_reconciliation$current_status %||% character()
  special_status <- current_status %in% c("special_manual_or_embedded", "embedded_fields_represented", "manual_file_not_available")
  db_attemptable <- if (nrow(canonical_reconciliation)) !special_status else logical()
  db_profiled <- current_status %in% c("current_profiled", "legacy_unavailable_current_resolved")
  source_map_canonical_rows <- if (nrow(crosswalk)) sum(as.logical(crosswalk$is_canonical_resource %||% FALSE), na.rm = TRUE) else 0L
  data.frame(
    metric = c(
      "canonical_expected_resources",
      "canonical_current_attempted_resources",
      "canonical_current_profiled_resources",
      "canonical_current_not_attempted_resources",
      "canonical_current_missing_after_attempt_resources",
      "derived_view_rows_profiled",
      "helper_table_rows_profiled",
      "source_map_rows_total",
      "source_map_rows_profiled",
      "legacy_reference_only_resources",
      "legacy_unavailable_current_resolved_resources",
      "special_manual_or_embedded_resources",
      "canonical_profiled_current_run",
      "canonical_not_attempted_current_run",
      "canonical_special_manual_or_embedded",
      "canonical_missing_after_attempt",
      "source_map_rows_profiled_current_run",
      "source_map_rows_canonical",
      "source_map_rows_derived_views",
      "source_map_rows_helpers",
      "remaining_activation_candidates",
      "canonical_resources_total",
      "canonical_resources_accounted_for",
      "db_attemptable_canonical_resources",
      "db_attemptable_profiled_resources",
      "manual_special_not_loaded_resources",
      "embedded_field_resources",
      "unexpected_missing_canonical_resources",
      "db_attemptable_failures",
      "canonical_mapped_source_map_rows"
    ),
    value = as.character(c(
      nrow(canonical_reconciliation),
      if (nrow(canonical_reconciliation)) sum(as.logical(canonical_reconciliation$current_attempted %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(canonical_reconciliation)) sum(as.logical(canonical_reconciliation$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_not_attempted", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_missing_after_attempt", na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_derived_view %||% FALSE) & as.logical(crosswalk$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_helper_table %||% FALSE) & as.logical(crosswalk$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      nrow(crosswalk),
      if (nrow(crosswalk)) sum(as.logical(crosswalk$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(legacy_reference)) length(unique(legacy_reference$canonical_resource_id[as.logical(legacy_reference$warning_needed %||% FALSE) & nzchar(legacy_reference$canonical_resource_id %||% "")])) else 0L,
      if (length(current_status)) sum(current_status == "legacy_unavailable_current_resolved", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(special_status, na.rm = TRUE) else 0L,
      if (nrow(canonical_reconciliation)) sum(as.logical(canonical_reconciliation$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_not_attempted", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(special_status, na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_missing_after_attempt", na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_current_profiled %||% crosswalk$current_profiled %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_canonical_resource %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_derived_view %||% FALSE), na.rm = TRUE) else 0L,
      if (nrow(crosswalk)) sum(as.logical(crosswalk$is_helper_table %||% FALSE), na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_not_attempted", na.rm = TRUE) else 0L,
      nrow(canonical_reconciliation),
      if (length(current_status)) sum(current_status %in% c("current_profiled", "legacy_unavailable_current_resolved", "special_manual_or_embedded", "embedded_fields_represented", "manual_file_not_available"), na.rm = TRUE) else 0L,
      if (length(current_status)) sum(db_attemptable, na.rm = TRUE) else 0L,
      if (length(current_status)) sum(db_attemptable & db_profiled, na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "manual_file_not_available", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "embedded_fields_represented", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(current_status == "current_missing_after_attempt", na.rm = TRUE) else 0L,
      if (length(current_status)) sum(db_attemptable & current_status == "current_missing_after_attempt", na.rm = TRUE) else 0L,
      source_map_canonical_rows
    )),
    stringsAsFactors = FALSE
  )
}

build_source_resolution_delta_legacy_vs_current <- function(project_root = ".", source_map = NULL,
                                                           sources = NULL, source_resolution = NULL,
                                                           legacy_audit = NULL, source_attempts = NULL) {
  expected <- read_expected_dalycare_resources(project_root)
  if (is.null(legacy_audit)) legacy_audit <- build_legacy_cartography_source_resolution_audit(project_root)
  if (!nrow(expected)) {
    return(empty_df(
      expected_resource_id = character(), legacy_resolved = logical(), current_resolved = logical(),
      legacy_resolution_method = character(), current_resolution_method = character(),
      legacy_rows = character(), current_rows = character(), delta_status = character(),
      likely_reason = character(), action_required = character()
    ))
  }
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- expected[i, , drop = FALSE]
    audit <- legacy_audit[legacy_audit$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    if (!nrow(audit)) audit <- data.frame(resolved_by_legacy_script = FALSE, legacy_resolution_method = "", legacy_rows = "", failure_or_absence_reason = "", notes = "", stringsAsFactors = FALSE)
    match <- current_resource_match(row, sources = sources, source_resolution = source_resolution, source_map = source_map)
    attempt <- if (is.data.frame(source_attempts) && nrow(source_attempts)) {
      source_attempts[source_attempts$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    current_source <- match$source_hit
    current_resolution <- match$resolution_hit
    has_map <- nrow(match$map_hit) > 0
    current_tested <- has_map || nrow(current_source) > 0 || nrow(current_resolution) > 0
    if (nrow(attempt)) current_tested <- isTRUE(source_recovery_truthy(attempt$attempted[[1]]))
    current_resolved <- FALSE
    if (nrow(current_source)) {
      current_resolved <- any(tolower(current_source$load_status %||% "") == "ok", na.rm = TRUE)
    }
    if (!current_resolved && nrow(current_resolution)) {
      current_resolved <- any(current_resolution$resolution_status %in% c("resolved", "not_applicable"), na.rm = TRUE)
    }
    if (nrow(attempt)) current_resolved <- isTRUE(source_recovery_truthy(attempt$resolved[[1]]))
    known_unavailable <- nzchar(row$known_absence_status[[1]] %||% "") && grepl("known_unavailable", row$known_absence_status[[1]], fixed = TRUE)
    current_known_unavailable <- nrow(attempt) && isTRUE(source_recovery_truthy(attempt$current_known_unavailable[[1]]))
    requires_validation <- nrow(attempt) && isTRUE(source_recovery_truthy(attempt$requires_production_validation[[1]]))
    legacy_resolved <- isTRUE(audit$resolved_by_legacy_script[[1]])
    legacy_special <- identical(audit$legacy_status[[1]] %||% "", "special_manual_embedded")
    current_method <- resource_first_nonblank(
      if (nrow(attempt)) attempt$resolver_type_attempted[[1]] else "",
      current_resolution_strategy(current_source, current_resolution)
    )
    current_rows <- resource_first_nonblank(
      if (nrow(attempt)) attempt$n_rows_current[[1]] else "",
      if (nrow(current_source)) current_source$n_rows[[1]] else "",
      if (nrow(current_resolution)) current_resolution$row_count[[1]] else ""
    )
    delta_status <- "uncertain_needs_review"
    likely_reason <- ""
    action_required <- ""
    if (known_unavailable && current_resolved) {
      delta_status <- "fixed_current_resolves_legacy_unavailable"
      likely_reason <- "Legacy/final V33 marked this unavailable, but the current run resolved it."
      action_required <- "Review and retain the current resolver evidence."
    } else if (known_unavailable && current_known_unavailable) {
      delta_status <- "legacy_known_unavailable"
      likely_reason <- resource_first_nonblank(row$known_absence_status[[1]], audit$failure_or_absence_reason[[1]])
      action_required <- "Keep as expected but unavailable unless the source is imported later."
    } else if (known_unavailable && requires_validation) {
      delta_status <- "legacy_known_unavailable_current_candidate"
      likely_reason <- "Legacy/final V33 marked this unavailable, but the current atlas carries a resolver candidate that has not been production-validated."
      action_required <- "Validate the current resolver candidate in a production run before calling this unavailable."
    } else if (legacy_resolved && current_resolved) {
      delta_status <- "present_in_both"
      likely_reason <- "Legacy and current run both account for the resource."
      action_required <- "No action."
    } else if (legacy_special && !current_resolved) {
      delta_status <- "legacy_special_manual_or_embedded"
      likely_reason <- "Final V33 accounted for this through special/manual/embedded evidence rather than a normal source-map table."
      action_required <- "Document source-specific access or add a curated source when available."
    } else if (legacy_resolved && !current_resolved && !current_tested) {
      delta_status <- "legacy_resolved_current_not_tested"
      likely_reason <- "Legacy resolved/profiled this resource, but the current run did not attempt it."
      action_required <- "Add or enable a current source-map row before production parity validation."
    } else if (legacy_resolved && !current_resolved && current_tested) {
      delta_status <- "legacy_profiled_current_missing"
      likely_reason <- "The current run had a matching source-map/resolution row, but it did not resolve."
      action_required <- "Check DB catalog spelling/alias and source-map db/schema/table fields."
    } else if (!legacy_resolved && current_resolved) {
      delta_status <- "current_fixture_only"
      likely_reason <- "Current run resolved a resource that legacy did not profile as a normal table."
      action_required <- "Review whether this is a legitimate newer source or alias."
    } else if (!current_tested) {
      delta_status <- "legacy_resolved_current_not_tested"
      likely_reason <- "Expected resource was not represented in the current source map."
      action_required <- "Add a source-map row or mark explicitly unavailable."
    } else if (current_tested && !current_resolved) {
      delta_status <- "current_missing_unexpectedly"
      likely_reason <- "The current run attempted this expected resource but did not resolve it."
      action_required <- "Investigate the source-map row or database availability."
    }
    data.frame(
      expected_resource_id = row$expected_resource_id[[1]],
      legacy_resolved = legacy_resolved,
      current_resolved = current_resolved,
      legacy_resolution_method = audit$legacy_resolution_method[[1]] %||% "",
      current_resolution_method = current_method,
      legacy_rows = audit$legacy_rows[[1]] %||% "",
      current_rows = current_rows,
      delta_status = delta_status,
      likely_reason = likely_reason,
      action_required = action_required,
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

build_atlas_resource_reconciliation <- function(project_root = ".", source_map = NULL,
                                                sources = NULL, source_resolution = NULL,
                                                legacy_audit = NULL, delta = NULL,
                                                source_attempts = NULL) {
  expected <- read_expected_dalycare_resources(project_root)
  if (is.null(legacy_audit)) legacy_audit <- build_legacy_cartography_source_resolution_audit(project_root)
  if (is.null(delta)) {
    delta <- build_source_resolution_delta_legacy_vs_current(
      project_root = project_root,
      source_map = source_map,
      sources = sources,
      source_resolution = source_resolution,
      legacy_audit = legacy_audit
    )
  }
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- expected[i, , drop = FALSE]
    audit <- legacy_audit[legacy_audit$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    d <- delta[delta$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    attempt <- if (is.data.frame(source_attempts) && nrow(source_attempts)) {
      source_attempts[source_attempts$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    } else {
      data.frame(stringsAsFactors = FALSE)
    }
    match <- current_resource_match(row, sources = sources, source_resolution = source_resolution, source_map = source_map)
    current_source <- match$source_hit
    current_resolution <- match$resolution_hit
    strategy <- resource_first_nonblank(
      if (nrow(attempt)) attempt$resolver_type_attempted[[1]] else "",
      if (nrow(d)) d$current_resolution_method[[1]] else "",
      current_resolution_strategy(current_source, current_resolution)
    )
    current_status <- "Not tested in current run"
    if (nrow(attempt)) {
      if (isTRUE(source_recovery_truthy(attempt$resolved[[1]]))) {
        current_status <- if (isTRUE(source_recovery_truthy(attempt$resolved_by_direct_sql[[1]]))) {
          "Resolved by direct SQL"
        } else if (isTRUE(source_recovery_truthy(attempt$resolved_by_alias[[1]]))) {
          "Resolved by alias"
        } else if (isTRUE(source_recovery_truthy(attempt$resolved_by_manual_file[[1]])) || isTRUE(source_recovery_truthy(attempt$resolved_by_embedded_fields[[1]]))) {
          "Special/manual"
        } else {
          "Resolved current run"
        }
      } else if (identical(attempt$error_or_warning[[1]] %||% "", "Current known unavailable")) {
        current_status <- "Current known unavailable"
      } else if (identical(attempt$error_or_warning[[1]] %||% "", "Special/manual configured")) {
        current_status <- "Special/manual"
      } else if (identical(attempt$error_or_warning[[1]] %||% "", "Legacy unavailable current candidate")) {
        current_status <- "Not tested in current run"
      } else if (isTRUE(source_recovery_truthy(attempt$attempted[[1]]))) {
        current_status <- "Missing unexpectedly"
      }
    } else if (nrow(current_source) && any(tolower(current_source$load_status %||% "") == "ok", na.rm = TRUE)) {
      current_status <- "Resolved current run"
    } else if (nrow(current_resolution) && any(current_resolution$resolution_status %in% c("resolved", "not_applicable"), na.rm = TRUE)) {
      current_status <- "Resolved current run"
    } else if (nrow(match$map_hit)) {
      current_status <- "Missing unexpectedly"
    }
    status_category <- if (nrow(d)) d$delta_status[[1]] else "uncertain_needs_review"
    current_table <- resource_first_nonblank(
      if (nrow(attempt)) attempt$resolved_table_or_file[[1]] else "",
      if (nrow(current_resolution)) current_resolution$table[[1]] else "",
      if (nrow(current_source)) current_source$table[[1]] else "",
      if (nrow(current_source)) current_source$table_name[[1]] else ""
    )
    current_schema <- resource_first_nonblank(
      if (nrow(attempt)) attempt$resolved_schema[[1]] else "",
      if (nrow(current_resolution)) paste(current_resolution$db_name[[1]], current_resolution$schema[[1]], sep = ".") else "",
      if (nrow(current_source)) paste(current_source$db_name[[1]], current_source$schema[[1]], sep = ".") else ""
    )
    current_rows <- resource_first_nonblank(
      if (nrow(attempt)) attempt$n_rows_current[[1]] else "",
      if (nrow(current_source)) current_source$n_rows[[1]] else "",
      if (nrow(current_resolution)) current_resolution$row_count[[1]] else ""
    )
    current_patients <- resource_first_nonblank(
      if (nrow(attempt)) attempt$n_patients_current_if_available[[1]] else "",
      if (nrow(current_source) && "n_patients" %in% names(current_source)) current_source$n_patients[[1]] else ""
    )
    action <- resource_first_nonblank(if (nrow(attempt)) attempt$action_required[[1]] else "", if (nrow(d)) d$action_required[[1]] else "")
    discrepancy <- status_category %in% c("legacy_profiled_current_missing", "current_missing_unexpectedly", "uncertain_manual_review")
    data.frame(
      expected_resource_id = row$expected_resource_id[[1]],
      display_name = row$display_name[[1]],
      domain = row$domain[[1]],
      expected_role = row$expected_role[[1]],
      expected_in_v033 = TRUE,
      legacy_status = if (nrow(audit)) audit$legacy_status[[1]] else row$legacy_status[[1]],
      current_run_status = current_status,
      current_resolution_strategy = strategy,
      current_table_name = current_table,
      current_db_schema = current_schema,
      current_n_rows = current_rows,
      current_n_patients = current_patients,
      legacy_n_rows = if (nrow(audit)) audit$legacy_rows[[1]] else row$legacy_rows[[1]],
      status_category = status_category,
      discrepancy_flag = discrepancy,
      action_required = action,
      notes = resource_first_nonblank(if (nrow(audit)) audit$notes[[1]] else "", row$notes[[1]]),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

legacy_final_classification <- function(audit_status) {
  audit_status <- audit_status %||% ""
  if (audit_status %in% c("known_unavailable", "confirmed_absent", "absent")) return("legacy_known_unavailable")
  if (identical(audit_status, "special_manual_embedded")) return("legacy_special_manual_or_embedded")
  if (identical(audit_status, "loaded")) return("legacy_profiled")
  if (audit_status %in% c("db_resolved", "db_resolved_part4", "db_resolved_part6")) return("legacy_resolved")
  "uncertain_manual_review"
}

source_truth_confidence <- function(resource_id, final_classification, v33_status) {
  if (resource_id %in% c("FISH", "DANRICHT")) return("medium")
  if (final_classification %in% c("legacy_profiled", "legacy_resolved", "legacy_known_unavailable") ||
      v33_status %in% c("profiled", "resolved", "not_in_database")) return("high")
  "medium"
}

build_source_truth_evidence_matrix <- function(project_root = ".", legacy_audit = NULL,
                                               delta = NULL, reconciliation = NULL) {
  expected <- read_expected_dalycare_resources(project_root)
  if (is.null(legacy_audit)) legacy_audit <- build_legacy_cartography_source_resolution_audit(project_root)
  if (is.null(delta)) delta <- build_source_resolution_delta_legacy_vs_current(project_root, legacy_audit = legacy_audit)
  if (is.null(reconciliation)) reconciliation <- build_atlas_resource_reconciliation(project_root, legacy_audit = legacy_audit, delta = delta)
  v33 <- legacy_v33_resource_evidence(project_root)
  if (!nrow(expected)) {
    return(empty_df(
      expected_resource_id = character(), display_name = character(), domain = character(),
      v033_catalog_status = character(), v033_catalog_rows = character(), v033_catalog_notes = character(),
      legacy_csv_status = character(), legacy_csv_rows = character(), legacy_script_status = character(),
      legacy_script_files = character(), legacy_resolution_method = character(),
      legacy_query_or_alias_evidence = character(), final_legacy_classification = character(),
      final_legacy_classification_reason = character(), current_reconciliation_status = character(),
      current_run_status = character(), discrepancy_flag = logical(), action_required = character(),
      confidence = character(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(expected)), function(i) {
    row <- expected[i, , drop = FALSE]
    id <- row$expected_resource_id[[1]]
    audit <- legacy_audit[legacy_audit$expected_resource_id == id, , drop = FALSE]
    d <- delta[delta$expected_resource_id == id, , drop = FALSE]
    rec <- reconciliation[reconciliation$expected_resource_id == id, , drop = FALSE]
    v <- v33[v33$expected_resource_id == id, , drop = FALSE]
    if (!nrow(audit)) audit <- data.frame(legacy_status = "", legacy_rows = "", legacy_script_file = "", legacy_resolution_method = "", legacy_query_or_table_pattern = "", notes = "", stringsAsFactors = FALSE)
    if (!nrow(d)) d <- data.frame(delta_status = "", action_required = "", stringsAsFactors = FALSE)
    if (!nrow(rec)) rec <- data.frame(current_run_status = "", discrepancy_flag = FALSE, action_required = "", notes = "", stringsAsFactors = FALSE)
    if (!nrow(v)) v <- data.frame(v033_catalog_status = "", v033_catalog_rows = "", v033_catalog_notes = "", stringsAsFactors = FALSE)
    final_class <- legacy_final_classification(audit$legacy_status[[1]] %||% "")
    reason <- switch(
      final_class,
      legacy_profiled = "Legacy generated profile/catalog output for this resource.",
      legacy_resolved = "Legacy script found the resource through alias/direct SQL resolution.",
      legacy_special_manual_or_embedded = "Final V33 accounted for this resource through special/manual/embedded evidence rather than a normal table.",
      legacy_known_unavailable = "Legacy/final V33 evidence explicitly marks this expected resource unavailable or not in database.",
      "Manual review is required because legacy evidence is incomplete or conflicting."
    )
    if (nzchar(v$v033_catalog_notes[[1]] %||% "")) {
      reason <- paste(reason, "V33 evidence:", v$v033_catalog_notes[[1]])
    }
    data.frame(
      expected_resource_id = id,
      display_name = row$display_name[[1]],
      domain = row$domain[[1]],
      v033_catalog_status = v$v033_catalog_status[[1]] %||% "",
      v033_catalog_rows = v$v033_catalog_rows[[1]] %||% "",
      v033_catalog_notes = v$v033_catalog_notes[[1]] %||% "",
      legacy_csv_status = audit$legacy_status[[1]] %||% "",
      legacy_csv_rows = audit$legacy_rows[[1]] %||% "",
      legacy_script_status = audit$legacy_status[[1]] %||% "",
      legacy_script_files = audit$legacy_script_file[[1]] %||% "",
      legacy_resolution_method = audit$legacy_resolution_method[[1]] %||% "",
      legacy_query_or_alias_evidence = audit$legacy_query_or_table_pattern[[1]] %||% "",
      final_legacy_classification = final_class,
      final_legacy_classification_reason = reason,
      current_reconciliation_status = d$delta_status[[1]] %||% "",
      current_run_status = rec$current_run_status[[1]] %||% "",
      discrepancy_flag = as.logical(rec$discrepancy_flag[[1]] %||% FALSE),
      action_required = resource_first_nonblank(rec$action_required[[1]] %||% "", d$action_required[[1]] %||% ""),
      confidence = source_truth_confidence(id, final_class, v$v033_catalog_status[[1]] %||% ""),
      notes = resource_first_nonblank(rec$notes[[1]] %||% "", audit$notes[[1]] %||% "", row$notes[[1]] %||% ""),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

source_truth_summary <- function(matrix) {
  if (!is.data.frame(matrix) || !nrow(matrix)) {
    return(data.frame(metric = character(), value = character(), stringsAsFactors = FALSE))
  }
  cls <- matrix$final_legacy_classification %||% rep("", nrow(matrix))
  current <- matrix$current_run_status %||% rep("", nrow(matrix))
  resolved_statuses <- c("Resolved current run", "Resolved by alias", "Resolved by direct SQL")
  legacy_resolved <- cls %in% c("legacy_profiled", "legacy_resolved", "legacy_special_manual_or_embedded")
  data.frame(
    metric = c(
      "expected_resources",
      "legacy_profiled_resources",
      "legacy_resolved_resources",
      "legacy_accounted_resources",
      "legacy_known_unavailable_resources",
      "legacy_special_manual_or_embedded_resources",
      "current_tested_resources",
      "current_resolved_resources",
      "current_not_tested_resources",
      "current_known_unavailable_resources",
      "current_special_manual_resources",
      "current_missing_unexpectedly_resources",
      "uncertain_resources_requiring_manual_review"
    ),
    value = as.character(c(
      nrow(matrix),
      sum(legacy_resolved, na.rm = TRUE),
      sum(legacy_resolved, na.rm = TRUE),
      sum(nzchar(cls), na.rm = TRUE),
      sum(cls == "legacy_known_unavailable", na.rm = TRUE),
      sum(cls == "legacy_special_manual_or_embedded", na.rm = TRUE),
      sum(current %in% c(resolved_statuses, "Missing unexpectedly"), na.rm = TRUE),
      sum(current %in% resolved_statuses, na.rm = TRUE),
      sum(current == "Not tested in current run", na.rm = TRUE),
      sum(current == "Current known unavailable", na.rm = TRUE),
      sum(current == "Special/manual", na.rm = TRUE),
      sum(current == "Missing unexpectedly", na.rm = TRUE),
      sum(cls == "uncertain_manual_review" | matrix$current_reconciliation_status == "uncertain_manual_review", na.rm = TRUE)
    )),
    stringsAsFactors = FALSE
  )
}

production_source_recovery_columns <- function() {
  c(
    "table_name", "source_type", "source", "priority", "profile_mode",
    "domain", "subdomain", "atlas_role", "load_strategy", "db_name", "schema", "table",
    "expected_resource_id", "display_name", "current_source_key", "preferred_schema",
    "preferred_table", "known_aliases", "resolver_type", "resolution_priority",
    "expected_availability", "legacy_resolution_method", "requires_direct_sql",
    "requires_manual_file", "requires_special_handling", "known_unavailable",
    "legacy_known_unavailable", "current_known_unavailable", "current_resolver_configured",
    "requires_production_validation", "regression_candidate", "notes"
  )
}

empty_production_source_recovery_map <- function() {
  out <- as.data.frame(stats::setNames(rep(list(character()), length(production_source_recovery_columns())), production_source_recovery_columns()), stringsAsFactors = FALSE)
  out
}

read_production_source_recovery_map <- function(project_root = ".", path = NULL) {
  if (is.null(path)) path <- file.path(project_root, "config", "source-map.dalycare64.production.tsv")
  if (!file.exists(path)) return(empty_production_source_recovery_map())
  out <- read_delimited_file(path)
  missing <- setdiff(production_source_recovery_columns(), names(out))
  for (nm in missing) out[[nm]] <- ""
  out <- out[production_source_recovery_columns()]
  out[] <- lapply(out, as.character)
  out$priority <- suppressWarnings(as.integer(out$priority))
  out$resolution_priority <- suppressWarnings(as.integer(out$resolution_priority))
  out$priority[is.na(out$priority)] <- seq_len(nrow(out))[is.na(out$priority)]
  out$resolution_priority[is.na(out$resolution_priority)] <- out$priority[is.na(out$resolution_priority)]
  out
}

source_recovery_truthy <- function(x) {
  x <- tolower(trimws(as.character(x %||% "")))
  x %in% c("true", "t", "yes", "y", "1")
}

validate_production_source_recovery_map <- function(plan, expected = NULL) {
  rows <- list()
  add <- function(expected_resource_id, check_id, status, message) {
    rows[[length(rows) + 1L]] <<- data.frame(
      expected_resource_id = expected_resource_id %||% "",
      check_id = check_id,
      status = status,
      message = message,
      stringsAsFactors = FALSE
    )
  }
  if (!is.data.frame(plan) || !nrow(plan)) {
    add("", "production_source_map_missing", "error", "Production 64-resource source map is missing.")
    return(bind_rows_base(rows))
  }
  if (!is.null(expected) && is.data.frame(expected) && nrow(expected)) {
    missing <- setdiff(expected$expected_resource_id, plan$expected_resource_id)
    extra <- setdiff(plan$expected_resource_id, expected$expected_resource_id)
    for (id in missing) add(id, "expected_resource_missing_from_production_map", "error", "Expected resource is missing from production source-map candidate.")
    for (id in extra) add(id, "unexpected_resource_in_production_map", "warning", "Production source-map candidate contains a resource outside the expected V33 universe.")
  }
  duplicated_ids <- unique(plan$expected_resource_id[duplicated(plan$expected_resource_id)])
  for (id in duplicated_ids) add(id, "duplicate_expected_resource_id", "error", "Duplicate expected resource in production source-map candidate.")
  for (i in seq_len(nrow(plan))) {
    row <- plan[i, , drop = FALSE]
    id <- row$expected_resource_id[[1]]
    resolver <- row$resolver_type[[1]]
    current_known_unavailable <- source_recovery_truthy(row$current_known_unavailable[[1]]) ||
      (source_recovery_truthy(row$known_unavailable[[1]]) && !source_recovery_truthy(row$legacy_known_unavailable[[1]])) ||
      identical(resolver, "known_unavailable")
    legacy_known_unavailable <- source_recovery_truthy(row$legacy_known_unavailable[[1]]) ||
      source_recovery_truthy(row$known_unavailable[[1]])
    manual <- source_recovery_truthy(row$requires_manual_file[[1]]) || source_recovery_truthy(row$requires_special_handling[[1]]) ||
      resolver %in% c("manual_file", "embedded_fields")
    if (!nzchar(resolver)) add(id, "missing_resolver_type", "error", "Resource lacks a resolver strategy.")
    if (current_known_unavailable && !identical(resolver, "known_unavailable")) {
      add(id, "current_known_unavailable_resolver_mismatch", "error", "Current-known-unavailable resource must use resolver_type known_unavailable.")
    }
    if (legacy_known_unavailable && !current_known_unavailable &&
        !source_recovery_truthy(row$requires_production_validation[[1]])) {
      add(id, "legacy_unavailable_candidate_needs_validation_flag", "warning", "Legacy-unavailable current candidates should be marked requires_production_validation.")
    }
    if (manual && !nzchar(row$notes[[1]] %||% "")) {
      add(id, "manual_resource_missing_notes", "warning", "Manual/special resource should explain how it is represented.")
    }
  }
  out <- bind_rows_base(rows)
  if (!nrow(out)) {
    return(empty_df(expected_resource_id = character(), check_id = character(), status = character(), message = character()))
  }
  out
}

build_source_resolution_plan_dry_run <- function(project_root = ".", production_map = NULL) {
  if (is.null(production_map)) production_map <- read_production_source_recovery_map(project_root)
  expected <- read_expected_dalycare_resources(project_root)
  checks <- validate_production_source_recovery_map(production_map, expected = expected)
  rows <- lapply(seq_len(nrow(production_map)), function(i) {
    row <- production_map[i, , drop = FALSE]
    row_checks <- checks[checks$expected_resource_id == row$expected_resource_id[[1]], , drop = FALSE]
    legacy_known_unavailable <- source_recovery_truthy(row$legacy_known_unavailable[[1]]) ||
      source_recovery_truthy(row$known_unavailable[[1]])
    current_known_unavailable <- source_recovery_truthy(row$current_known_unavailable[[1]]) ||
      (source_recovery_truthy(row$known_unavailable[[1]]) && !legacy_known_unavailable) ||
      identical(row$resolver_type[[1]], "known_unavailable")
    requires_validation <- source_recovery_truthy(row$requires_production_validation[[1]])
    has_error <- nrow(row_checks) && any(row_checks$status == "error")
    dry_status <- if (has_error) {
      "needs_manual_review"
    } else if (current_known_unavailable) {
      "current_known_unavailable_declared"
    } else if (identical(row$resolver_type[[1]], "manual_file")) {
      "requires_manual_file"
    } else if (identical(row$resolver_type[[1]], "embedded_fields")) {
      "requires_embedded_field_mapping"
    } else if (legacy_known_unavailable && requires_validation) {
      "legacy_unavailable_current_candidate"
    } else {
      "would_attempt_in_production"
    }
    data.frame(
      expected_resource_id = row$expected_resource_id[[1]],
      resolver_type = row$resolver_type[[1]],
      expected_availability = row$expected_availability[[1]],
      known_aliases = row$known_aliases[[1]],
      requires_direct_sql = row$requires_direct_sql[[1]],
      requires_manual_file = row$requires_manual_file[[1]],
      requires_special_handling = row$requires_special_handling[[1]],
      requires_production_validation = row$requires_production_validation[[1]],
      regression_candidate = row$regression_candidate[[1]],
      dry_run_status = dry_status,
      notes = resource_first_nonblank(
        paste(row_checks$message, collapse = "; "),
        row$notes[[1]]
      ),
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

build_source_resolution_attempts <- function(project_root = ".", production_map = NULL,
                                             source_map = NULL, sources = NULL,
                                             source_resolution = NULL) {
  if (is.null(production_map)) production_map <- read_production_source_recovery_map(project_root)
  if (!is.data.frame(production_map) || !nrow(production_map)) {
    return(empty_df(
      expected_resource_id = character(), attempted = logical(), resolver_type_attempted = character(),
      resolved = logical(), resolved_table_or_file = character(), resolved_schema = character(),
      resolved_by_alias = logical(), resolved_by_direct_sql = logical(), resolved_by_manual_file = logical(),
      resolved_by_embedded_fields = logical(), n_rows_current = character(),
      n_patients_current_if_available = character(), error_or_warning = character(),
      action_required = character(), legacy_known_unavailable = logical(),
      current_known_unavailable = logical(), requires_production_validation = logical(),
      regression_candidate = character(), notes = character()
    ))
  }
  rows <- lapply(seq_len(nrow(production_map)), function(i) {
    row <- production_map[i, , drop = FALSE]
    id <- row$expected_resource_id[[1]]
    match <- current_resource_match(row, sources = sources, source_resolution = source_resolution, source_map = source_map)
    current_source <- match$source_hit
    current_resolution <- match$resolution_hit
    current_map <- match$map_hit
    legacy_known_unavailable <- source_recovery_truthy(row$legacy_known_unavailable[[1]]) ||
      source_recovery_truthy(row$known_unavailable[[1]])
    current_known_unavailable <- source_recovery_truthy(row$current_known_unavailable[[1]]) ||
      (source_recovery_truthy(row$known_unavailable[[1]]) && !legacy_known_unavailable) ||
      identical(row$resolver_type[[1]], "known_unavailable")
    special_manual <- row$resolver_type[[1]] %in% c("manual_file", "embedded_fields")
    attempted <- !current_known_unavailable && !special_manual && (nrow(current_source) > 0 || nrow(current_resolution) > 0 || nrow(current_map) > 0)
    resolved <- FALSE
    if (special_manual && identical(row$resolver_type[[1]], "embedded_fields")) {
      resolved <- nrow(current_source) && any(current_source$load_status %in% c("ok", "embedded_fields_represented"), na.rm = TRUE)
    } else if (special_manual && identical(row$resolver_type[[1]], "manual_file")) {
      resolved <- nrow(current_source) && any(tolower(current_source$load_status %||% "") == "ok", na.rm = TRUE)
    } else if (nrow(current_source)) {
      resolved <- any(tolower(current_source$load_status %||% "") == "ok", na.rm = TRUE)
    }
    if (!resolved && !special_manual && nrow(current_resolution)) {
      resolved <- any(current_resolution$resolution_status %in% c("resolved", "not_applicable"), na.rm = TRUE)
    }
    resolver <- row$resolver_type[[1]]
    strategy <- current_resolution_strategy(current_source, current_resolution)
    table_or_file <- resource_first_nonblank(
      if (nrow(current_resolution)) current_resolution$table[[1]] else "",
      if (nrow(current_source)) current_source$table[[1]] else "",
      if (nrow(current_source)) current_source$table_name[[1]] else "",
      if (nrow(current_map)) current_map$source[[1]] else "",
      row$preferred_table[[1]]
    )
    schema <- resource_first_nonblank(
      if (nrow(current_resolution)) paste(current_resolution$db_name[[1]], current_resolution$schema[[1]], sep = ".") else "",
      if (nrow(current_source)) paste(current_source$db_name[[1]], current_source$schema[[1]], sep = ".") else "",
      row$preferred_schema[[1]]
    )
    current_rows <- resource_first_nonblank(
      if (nrow(current_source)) current_source$n_rows[[1]] else "",
      if (nrow(current_resolution)) current_resolution$row_count[[1]] else ""
    )
    current_patients <- if (nrow(current_source) && "n_patients" %in% names(current_source)) current_source$n_patients[[1]] else ""
    resolved_by_direct <- isTRUE(resolved) && (resolver %in% c("direct_sql", "schema_qualified_table") || grepl("alias|direct|db_chunked|db_aggregate", strategy, ignore.case = TRUE))
    resolved_by_manual <- identical(resolver, "manual_file") && (isTRUE(resolved) || special_manual)
    resolved_by_embedded <- identical(resolver, "embedded_fields") && (isTRUE(resolved) || special_manual)
    resolved_by_alias <- isTRUE(resolved) && !resolved_by_direct && resolver %in% c("alias_table", "schema_qualified_table")
    warning <- if (current_known_unavailable) {
      "Current known unavailable"
    } else if (identical(row$resolver_type[[1]], "embedded_fields") && resolved) {
      ""
    } else if (identical(row$resolver_type[[1]], "manual_file") && !resolved) {
      "Manual/special source not loaded"
    } else if (special_manual && !resolved) {
      "Special/manual configured"
    } else if (legacy_known_unavailable && !attempted && source_recovery_truthy(row$requires_production_validation[[1]])) {
      "Legacy unavailable current candidate"
    } else if (!attempted) {
      "Not tested in current run"
    } else if (!resolved) {
      "Attempted but not resolved"
    } else {
      ""
    }
    action <- if (current_known_unavailable) {
      "No current attempt expected unless the resource is imported later."
    } else if (identical(row$resolver_type[[1]], "embedded_fields") && resolved) {
      "Represented through embedded registry fields; no standalone DB table is required."
    } else if (identical(row$resolver_type[[1]], "manual_file") && !resolved) {
      "Manual/on-disk files were not available; provide them only if this special source should be profiled."
    } else if (special_manual && !resolved) {
      "Represented by manual/special evidence; add a source-specific loader if this should be profiled as a normal table."
    } else if (legacy_known_unavailable && !attempted && source_recovery_truthy(row$requires_production_validation[[1]])) {
      "Legacy V33 did not resolve this resource; current resolver candidate requires production validation."
    } else if (!attempted) {
      "Run with the production source-map and database access to test this resource."
    } else if (!resolved) {
      "Review resolver aliases, schema/table spelling, or production access."
    } else {
      "No action."
    }
    data.frame(
      expected_resource_id = id,
      attempted = attempted,
      resolver_type_attempted = resolver,
      resolved = resolved,
      resolved_table_or_file = table_or_file,
      resolved_schema = schema,
      resolved_by_alias = resolved_by_alias,
      resolved_by_direct_sql = resolved_by_direct,
      resolved_by_manual_file = resolved_by_manual,
      resolved_by_embedded_fields = resolved_by_embedded,
      n_rows_current = current_rows,
      n_patients_current_if_available = current_patients,
      error_or_warning = warning,
      action_required = action,
      legacy_known_unavailable = legacy_known_unavailable,
      current_known_unavailable = current_known_unavailable,
      requires_production_validation = source_recovery_truthy(row$requires_production_validation[[1]]),
      regression_candidate = row$regression_candidate[[1]],
      notes = row$notes[[1]],
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

source_recovery_run_summary_metrics <- function(plan = NULL, dry_run = NULL, attempts = NULL) {
  if (!is.data.frame(plan)) plan <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(dry_run)) dry_run <- data.frame(stringsAsFactors = FALSE)
  if (!is.data.frame(attempts)) attempts <- data.frame(stringsAsFactors = FALSE)
  legacy_known_unavailable <- if (nrow(plan)) source_recovery_truthy(plan$legacy_known_unavailable) | source_recovery_truthy(plan$known_unavailable) else logical()
  current_known_unavailable <- if (nrow(plan)) source_recovery_truthy(plan$current_known_unavailable) |
    (source_recovery_truthy(plan$known_unavailable) & !legacy_known_unavailable) |
    plan$resolver_type == "known_unavailable" else logical()
  db_attemptable <- if (nrow(plan)) plan$resolver_type %in% c("standard_table", "alias_table", "schema_qualified_table", "direct_sql") &
    !current_known_unavailable else logical()
  special_manual <- if (nrow(plan)) plan$resolver_type %in% c("manual_file", "embedded_fields") else logical()
  configured <- if (nrow(dry_run)) dry_run$dry_run_status %in% c(
    "would_attempt_in_production", "requires_manual_file", "requires_embedded_field_mapping",
    "legacy_unavailable_current_candidate", "current_known_unavailable_declared"
  ) else logical()
  resolved_ids <- if (nrow(attempts) && all(c("expected_resource_id", "resolved") %in% names(attempts))) {
    attempts$expected_resource_id[as.logical(attempts$resolved)]
  } else {
    character()
  }
  unresolved_validation <- if (nrow(plan)) {
    source_recovery_truthy(plan$requires_production_validation) & !plan$expected_resource_id %in% resolved_ids
  } else {
    logical()
  }
  unresolved_regression <- if (nrow(plan)) {
    nzchar(plan$regression_candidate %||% "") & plan$regression_candidate != "FALSE" & !plan$expected_resource_id %in% resolved_ids
  } else {
    logical()
  }
  data.frame(
    metric = c(
      "production_source_map_resources",
      "current_resolver_configured_resources",
      "legacy_available_or_resolved_resources",
      "db_attemptable_resources",
      "special_manual_or_embedded_resources",
      "known_unavailable_legacy_resources",
      "current_known_unavailable_resources",
      "requires_production_validation_resources",
      "regression_candidate_resources",
      "source_recovery_special_manual_resources",
      "source_resolution_attempted_resources",
      "source_resolution_resolved_current_resources",
      "source_resolution_not_tested_current_resources"
    ),
    value = as.character(c(
      nrow(plan),
      sum(configured, na.rm = TRUE),
      if (nrow(plan)) sum(!legacy_known_unavailable | special_manual, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(db_attemptable, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(special_manual, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(legacy_known_unavailable, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(current_known_unavailable, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(unresolved_validation, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(unresolved_regression, na.rm = TRUE) else 0L,
      if (nrow(plan)) sum(special_manual, na.rm = TRUE) else 0L,
      if (nrow(attempts)) sum(as.logical(attempts$attempted), na.rm = TRUE) else 0L,
      if (nrow(attempts)) sum(as.logical(attempts$resolved), na.rm = TRUE) else 0L,
      if (nrow(attempts)) sum(!as.logical(attempts$attempted) & attempts$error_or_warning == "Not tested in current run", na.rm = TRUE) else 0L
    )),
    stringsAsFactors = FALSE
  )
}

billeddiagnostik_del2_patterns <- function() {
  c(
    "BilleddiagnostikeUndersøgelser_Del2",
    "BilleddiagnostiskeUndersøgelser_Del2",
    "BilleddiagnostikeUndersogelser_Del2",
    "BilleddiagnostiskeUndersogelser_Del2",
    "BilleddiagnostikeUndersoegelser_Del2",
    "BilleddiagnostiskeUndersoegelser_Del2",
    "SP_BilleddiagnostiskeUndersøgelser_Del2",
    "SP_BilleddiagnostikeUndersøgelser_Del2",
    "SP_BilleddiagnostiskeUndersogelser_Del2",
    "SP_BilleddiagnostikeUndersogelser_Del2",
    "SP_BilleddiagnostiskeUndersoegelser_Del2",
    "SP_BilleddiagnostikeUndersoegelser_Del2",
    "Billeddiagnostik", "Billeddiagnostiske", "Billeddiagnostike",
    "Undersøgelser", "Undersogelser", "Del2", "Del_2",
    "imaging text", "imaging narrative", "radiology text"
  )
}

billeddiagnostik_del2_relevant_line <- function(line) {
  line_key <- resource_key(line)
  exact_keys <- resource_key(c(
    "BilleddiagnostikeUndersøgelser_Del2",
    "BilleddiagnostiskeUndersøgelser_Del2",
    "BilleddiagnostikeUndersogelser_Del2",
    "BilleddiagnostiskeUndersogelser_Del2",
    "BilleddiagnostikeUndersoegelser_Del2",
    "BilleddiagnostiskeUndersoegelser_Del2",
    "SP_BilleddiagnostiskeUndersøgelser_Del2",
    "SP_BilleddiagnostikeUndersøgelser_Del2",
    "SP_BilleddiagnostiskeUndersogelser_Del2",
    "SP_BilleddiagnostikeUndersogelser_Del2",
    "SP_BilleddiagnostiskeUndersoegelser_Del2",
    "SP_BilleddiagnostikeUndersoegelser_Del2"
  ))
  if (any(vapply(exact_keys, function(key) grepl(key, line_key, fixed = TRUE), logical(1)))) {
    return(TRUE)
  }
  has_del2 <- grepl("del2|del_2", line, ignore.case = TRUE)
  has_imaging_context <- grepl("Billeddiagnostik|Billeddiagnostiske|Billeddiagnostike|Undersøgelser|Undersogelser|Undersoegelser|radiology|imaging", line, ignore.case = TRUE)
  isTRUE(has_del2 && has_imaging_context)
}

billeddiagnostik_del2_inferred_status <- function(path, line) {
  lower <- tolower(paste(path, line))
  if (grepl("source-map\\.dalycare\\.tsv|dalycare_preflight|db_profile|semantic_dictionary", lower)) {
    return("current_resolver_candidate")
  }
  if (grepl("source-map\\.dalycare64\\.production", lower) &&
      grepl("legacy_unavailable_current_candidate|requires_production_validation|direct_sql", lower)) {
    return("legacy_unavailable_current_candidate")
  }
  if (grepl("absent|not found|not in database|known_unavailable|only del1 exists", lower)) {
    return("legacy_known_unavailable")
  }
  if (grepl("payload|loaded_name|source map|alias|resolver|candidate", lower)) {
    return("current_or_packaged_candidate")
  }
  "mention_needs_review"
}

billeddiagnostik_del2_evidence_type <- function(path) {
  lower <- tolower(path)
  if (grepl("source-map", lower)) return("source_map")
  if (grepl("resolution_log|load_status|summary", lower)) return("legacy_resolution_output")
  if (grepl("\\.r$|\\.rmd$|\\.qmd$", lower)) return("script_or_resolver_code")
  if (grepl("payload|html|js", lower)) return("rendered_site_or_payload")
  if (grepl("notes|readme|\\.md$", lower)) return("documentation")
  "text_evidence"
}

current_run_billeddiagnostik_del2_evidence <- function(sources = NULL, source_resolution = NULL,
                                                        resource_catalog = NULL,
                                                        canonical_reconciliation = NULL,
                                                        crosswalk = NULL) {
  frames <- list()
  if (is.data.frame(sources) && nrow(sources)) {
    hit <- sources[grepl("Billeddiagnostik|Billeddiagnostiske|Billeddiagnostike", paste(sources$table_name %||% "", sources$source %||% "", sources$table %||% ""), ignore.case = TRUE) &
      grepl("Del2|Del_2", paste(sources$table_name %||% "", sources$source %||% "", sources$table %||% ""), ignore.case = TRUE), , drop = FALSE]
    if (nrow(hit)) {
      frames[[length(frames) + 1L]] <- data.frame(
        artifact_or_package = "current_run",
        file = "outputs/atlas_sources.csv",
        matched_string = hit$table_name,
        evidence_type = "current_run_resolution",
        inferred_status = "current_profiled",
        resolver_or_alias = hit$source %||% hit$table_name,
        row_count_if_available = hit$n_rows %||% "",
        canonical_resource_id = "BilleddiagnostikeUndersøgelser_Del2",
        current_source_key = hit$table_name %||% hit$source,
        resolved_table = paste(hit$db_name %||% "", hit$schema %||% "", hit$table %||% "", sep = "."),
        current_status = "current_profiled",
        final_classification = "legacy_unavailable_current_resolved",
        current_rows = hit$n_rows %||% "",
        current_columns = hit$n_cols %||% "",
        is_relevant_to_billeddiagnostik_del2 = TRUE,
        notes = "Current production source profile resolved the SP imaging Del2 resource.",
        stringsAsFactors = FALSE
      )
    }
  }
  if (is.data.frame(source_resolution) && nrow(source_resolution)) {
    hay <- paste(source_resolution$table_name %||% "", source_resolution$source %||% "", source_resolution$table %||% "", source_resolution$candidate_locations %||% "")
    hit <- source_resolution[grepl("Billeddiagnostik|Billeddiagnostiske|Billeddiagnostike", hay, ignore.case = TRUE) &
      grepl("Del2|Del_2", hay, ignore.case = TRUE), , drop = FALSE]
    if (nrow(hit)) {
      frames[[length(frames) + 1L]] <- data.frame(
        artifact_or_package = "current_run",
        file = "outputs/atlas_source_resolution.csv",
        matched_string = hit$table_name %||% hit$source,
        evidence_type = "current_run_resolution",
        inferred_status = "current_profiled",
        resolver_or_alias = hit$suggested_table %||% hit$table %||% hit$table_name,
        row_count_if_available = hit$row_count %||% "",
        canonical_resource_id = "BilleddiagnostikeUndersøgelser_Del2",
        current_source_key = hit$table_name %||% hit$source,
        resolved_table = paste(hit$db_name %||% "", hit$schema %||% "", hit$table %||% hit$suggested_table %||% "", sep = "."),
        current_status = "current_profiled",
        final_classification = "legacy_unavailable_current_resolved",
        current_rows = hit$row_count %||% "",
        current_columns = "",
        is_relevant_to_billeddiagnostik_del2 = TRUE,
        notes = "Current production source-resolution output resolved the SP imaging Del2 table.",
        stringsAsFactors = FALSE
      )
    }
  }
  if (is.data.frame(canonical_reconciliation) && nrow(canonical_reconciliation)) {
    hit <- canonical_reconciliation[resource_key(canonical_reconciliation$canonical_resource_id) == resource_key("BilleddiagnostikeUndersøgelser_Del2"), , drop = FALSE]
    if (nrow(hit)) {
      frames[[length(frames) + 1L]] <- data.frame(
        artifact_or_package = "current_run",
        file = "outputs/canonical_resource_reconciliation_64.csv",
        matched_string = hit$canonical_resource_id,
        evidence_type = "current_run_resolution",
        inferred_status = hit$current_status,
        resolver_or_alias = hit$current_resolved_source_key,
        row_count_if_available = hit$current_n_rows,
        canonical_resource_id = hit$canonical_resource_id,
        current_source_key = hit$current_resolved_source_key,
        resolved_table = hit$current_resolved_table_or_view,
        current_status = ifelse(isTRUE(as.logical(hit$current_profiled)), "current_profiled", hit$current_status),
        final_classification = hit$current_status,
        current_rows = hit$current_n_rows,
        current_columns = hit$current_n_columns,
        is_relevant_to_billeddiagnostik_del2 = TRUE,
        notes = "Canonical reconciliation classifies Del2 as legacy-unavailable/current-resolved.",
        stringsAsFactors = FALSE
      )
    }
  }
  if (is.data.frame(crosswalk) && nrow(crosswalk)) {
    hit <- crosswalk[resource_key(crosswalk$canonical_resource_id) == resource_key("BilleddiagnostikeUndersøgelser_Del2") |
      grepl("Billeddiagnostik|Billeddiagnostiske|Billeddiagnostike", crosswalk$source_map_key %||% "", ignore.case = TRUE) &
        grepl("Del2|Del_2", crosswalk$source_map_key %||% "", ignore.case = TRUE), , drop = FALSE]
    if (nrow(hit)) {
      frames[[length(frames) + 1L]] <- data.frame(
        artifact_or_package = "current_run",
        file = "outputs/source_map_row_to_canonical_resource_crosswalk.csv",
        matched_string = hit$source_map_key,
        evidence_type = "current_run_resolution",
        inferred_status = ifelse(as.logical(hit$is_current_profiled %||% hit$current_profiled), "current_profiled", "not_profiled"),
        resolver_or_alias = hit$source_map_label %||% hit$source_map_key,
        row_count_if_available = hit$current_n_rows,
        canonical_resource_id = hit$canonical_resource_id,
        current_source_key = hit$source_map_key,
        resolved_table = hit$source_map_label %||% "",
        current_status = ifelse(as.logical(hit$is_current_profiled %||% hit$current_profiled), "current_profiled", "not_profiled"),
        final_classification = ifelse(as.logical(hit$is_current_profiled %||% hit$current_profiled), "legacy_unavailable_current_resolved", "needs_review"),
        current_rows = hit$current_n_rows,
        current_columns = hit$current_n_columns %||% "",
        is_relevant_to_billeddiagnostik_del2 = TRUE,
        notes = "Source-map crosswalk maps the current source-map row to Del2.",
        stringsAsFactors = FALSE
      )
    }
  }
  bind_rows_base(frames)
}

build_billeddiagnostik_del2_regression_audit <- function(project_root = ".", sources = NULL,
                                                         source_resolution = NULL,
                                                         resource_catalog = NULL,
                                                         canonical_reconciliation = NULL,
                                                         crosswalk = NULL) {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  candidates <- c(
    file.path(project_root, "config", "source-map.dalycare.tsv"),
    file.path(project_root, "config", "source-map.dalycare64.production.tsv"),
    file.path(project_root, "config", "expected_dalycare_resources_64.tsv"),
    Sys.glob(file.path(project_root, "config", "cartography-reference", "files", "*billeddiagnostik*")),
    Sys.glob(file.path(project_root, "config", "cartography-reference", "files", "*part4*")),
    Sys.glob(file.path(project_root, "config", "cartography-reference", "files", "*part6*")),
    file.path(project_root, "R", "db_profile.R"),
    file.path(project_root, "R", "dalycare_preflight.R"),
    file.path(project_root, "R", "semantic_dictionary.R"),
    file.path(project_root, "R", "source_reconciliation.R"),
    file.path(project_root, "inst", "templates", "DALYCARE_atlas.html"),
    file.path(project_root, "inst", "legacy", "wommen_v06", "site", "DALYCARE_atlas_payload.js"),
    file.path(project_root, "inst", "legacy", "wommen_v06", "site", "DALYCARE_atlas_AOT_V35.html"),
    file.path(project_root, "PRODUCTION_SOURCE_RECOVERY_PLAN.md"),
    file.path(project_root, "SOURCE_TRUTH_CORRECTION_NOTES.md"),
    file.path(project_root, "SOURCE_RECONCILIATION_FROM_LEGACY_R_SCRIPTS.md")
  )
  candidates <- unique(normalizePath(candidates[file.exists(candidates)], winslash = "/", mustWork = FALSE))
  patterns <- billeddiagnostik_del2_patterns()
  rows <- list()
  for (path in candidates) {
    lines <- tryCatch(readLines(path, warn = FALSE, encoding = "UTF-8"), error = function(e) character())
    if (!length(lines)) next
    hit_ix <- which(vapply(lines, function(line) {
      any(grepl(paste(patterns, collapse = "|"), line, ignore.case = TRUE)) &&
        billeddiagnostik_del2_relevant_line(line)
    }, logical(1)))
    hit_ix <- head(hit_ix, 80L)
    for (ix in hit_ix) {
      line <- lines[[ix]]
      matched <- patterns[vapply(patterns, function(pattern) grepl(pattern, line, ignore.case = TRUE), logical(1))]
      rows[[length(rows) + 1L]] <- data.frame(
        artifact_or_package = basename(project_root),
        file = sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", project_root), "/?"), "", path),
        matched_string = paste(unique(matched), collapse = ";"),
        evidence_type = billeddiagnostik_del2_evidence_type(path),
        inferred_status = billeddiagnostik_del2_inferred_status(path, line),
        resolver_or_alias = if (grepl("SP_Billed|Billeddiagnost", line)) trimws(substr(line, 1L, 500L)) else "",
        row_count_if_available = paste(regmatches(line, gregexpr("[0-9][0-9,\\.]{2,}", line))[[1]], collapse = ";"),
        canonical_resource_id = "",
        current_source_key = "",
        resolved_table = "",
        current_status = "",
        final_classification = billeddiagnostik_del2_inferred_status(path, line),
        current_rows = "",
        current_columns = "",
        is_relevant_to_billeddiagnostik_del2 = TRUE,
        notes = paste0("Line ", ix, ": ", trimws(substr(line, 1L, 500L))),
        stringsAsFactors = FALSE
      )
    }
  }
  out <- bind_rows_base(list(
    bind_rows_base(rows),
    current_run_billeddiagnostik_del2_evidence(
      sources = sources,
      source_resolution = source_resolution,
      resource_catalog = resource_catalog,
      canonical_reconciliation = canonical_reconciliation,
      crosswalk = crosswalk
    )
  ))
  if (!nrow(out)) {
    return(empty_df(
      artifact_or_package = character(), file = character(), matched_string = character(),
      evidence_type = character(), inferred_status = character(), resolver_or_alias = character(),
      row_count_if_available = character(), canonical_resource_id = character(),
      current_source_key = character(), resolved_table = character(),
      current_status = character(), final_classification = character(),
      current_rows = character(), current_columns = character(),
      is_relevant_to_billeddiagnostik_del2 = logical(), notes = character()
    ))
  }
  out
}

resource_reconciliation_summary_metrics <- function(reconciliation, legacy_audit = NULL) {
  if (!is.data.frame(reconciliation) || !nrow(reconciliation)) {
    return(data.frame(metric = character(), value = character(), stringsAsFactors = FALSE))
  }
  status <- reconciliation$status_category %||% rep("", nrow(reconciliation))
  resolved_statuses <- c("Resolved current run", "Resolved by alias", "Resolved by direct SQL")
  current_resolved <- reconciliation$current_run_status %in% resolved_statuses
  current_tested <- reconciliation$current_run_status %in% c(resolved_statuses, "Missing unexpectedly")
  direct_sql <- grepl("alias|direct|db_chunked|db_aggregate", reconciliation$current_resolution_strategy %||% "", ignore.case = TRUE)
  special <- grepl("special|manual|embedded|file", reconciliation$current_resolution_strategy %||% "", ignore.case = TRUE)
  legacy_resolved <- 0L
  legacy_unavailable <- 0L
  legacy_special <- 0L
  if (is.data.frame(legacy_audit) && nrow(legacy_audit)) {
    legacy_resolved <- sum(as.logical(legacy_audit$resolved_by_legacy_script %||% FALSE), na.rm = TRUE)
    legacy_unavailable <- sum(legacy_audit$legacy_status %in% c("known_unavailable", "confirmed_absent", "absent"), na.rm = TRUE)
    legacy_special <- sum(legacy_audit$legacy_status %in% c("special_manual_embedded"), na.rm = TRUE)
  }
  current_not_tested <- sum(reconciliation$current_run_status == "Not tested in current run", na.rm = TRUE)
  current_known_unavailable <- sum(reconciliation$current_run_status == "Current known unavailable", na.rm = TRUE)
  current_special_manual <- sum(reconciliation$current_run_status == "Special/manual", na.rm = TRUE)
  current_missing_unexpectedly <- sum(reconciliation$current_run_status == "Missing unexpectedly", na.rm = TRUE)
  uncertain <- sum(status %in% c("uncertain_manual_review"), na.rm = TRUE)
  data.frame(
    metric = c(
      "expected_resources",
      "legacy_profiled_resources",
      "legacy_resolved_resources",
      "legacy_accounted_resources",
      "legacy_known_unavailable_resources",
      "legacy_special_manual_or_embedded_resources",
      "current_tested_resources",
      "current_resolved_resources",
      "current_not_tested_resources",
      "current_known_unavailable_resources",
      "current_special_manual_resources",
      "current_missing_unexpectedly_resources",
      "uncertain_resources_requiring_manual_review",
      "explored_resources_this_run",
      "standard_resolved_resources",
      "direct_sql_resolved_resources",
      "special_or_manual_resources",
      "known_unavailable_resources",
      "unexpectedly_missing_resources",
      "current_missing_but_legacy_resolved_resources",
      "current_untested_resources"
    ),
    value = as.character(c(
      nrow(reconciliation),
      legacy_resolved,
      legacy_resolved,
      legacy_resolved + legacy_unavailable,
      legacy_unavailable,
      legacy_special,
      sum(current_tested, na.rm = TRUE),
      sum(current_resolved, na.rm = TRUE),
      current_not_tested,
      current_known_unavailable,
      current_special_manual,
      current_missing_unexpectedly,
      uncertain,
      sum(current_resolved, na.rm = TRUE),
      sum(current_resolved & !direct_sql & !special, na.rm = TRUE),
      sum(current_resolved & direct_sql, na.rm = TRUE),
      current_special_manual,
      current_known_unavailable,
      current_missing_unexpectedly,
      sum(status %in% c("legacy_profiled_current_missing", "current_missing_unexpectedly"), na.rm = TRUE),
      current_not_tested
    )),
    stringsAsFactors = FALSE
  )
}

append_resource_reconciliation_run_summary <- function(run_summary, reconciliation, legacy_audit = NULL) {
  bind_rows_base(list(run_summary, resource_reconciliation_summary_metrics(reconciliation, legacy_audit)))
}

resource_reconciliation_checks <- function(reconciliation) {
  if (!is.data.frame(reconciliation) || !nrow(reconciliation)) {
    return(check_row("", "resource_reconciliation_missing", "warning", "Expected-resource reconciliation was not generated."))
  }
  problem <- reconciliation[
    reconciliation$status_category %in% c(
      "legacy_resolved_current_not_tested",
      "legacy_profiled_current_missing",
      "legacy_special_manual_or_embedded",
      "current_missing_unexpectedly",
      "uncertain_manual_review"
    ),
    ,
    drop = FALSE
  ]
  if (!nrow(problem)) return(data.frame(stringsAsFactors = FALSE))
  msg <- paste(
    nrow(problem),
    "expected DALY-CARE resource(s) were resolved/accounted for by legacy cartography scripts but are missing or untested in the current run."
  )
  check_row("", "legacy_resource_reconciliation_gap", "warning", msg)
}
