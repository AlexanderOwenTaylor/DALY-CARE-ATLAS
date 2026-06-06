mcl_asct_required_evidence_source_columns <- function() {
  c(
    "source_id",
    "canonical_source_id",
    "evidence_family",
    "db_name",
    "schema",
    "table",
    "person_key_column",
    "code_column",
    "code_system",
    "code_value",
    "date_columns",
    "dose_columns",
    "route_columns",
    "drug_name_columns",
    "bridge_table",
    "bridge_source_key_column",
    "bridge_key_column",
    "bridge_person_key_column",
    "timing_anchor",
    "timing_window_start_days",
    "timing_window_end_days",
    "evidence_tier",
    "include_in_primary_asct",
    "include_in_sensitivity_asct",
    "requires_co_residency_with_lyfo",
    "requires_bridge_validation",
    "notes"
  )
}

mcl_asct_empty_evidence_sources <- function() {
  empty_df(
    source_id = character(),
    canonical_source_id = character(),
    evidence_family = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    person_key_column = character(),
    code_column = character(),
    code_system = character(),
    code_value = character(),
    date_columns = character(),
    dose_columns = character(),
    route_columns = character(),
    drug_name_columns = character(),
    bridge_table = character(),
    bridge_source_key_column = character(),
    bridge_key_column = character(),
    bridge_person_key_column = character(),
    timing_anchor = character(),
    timing_window_start_days = character(),
    timing_window_end_days = character(),
    evidence_tier = character(),
    include_in_primary_asct = character(),
    include_in_sensitivity_asct = character(),
    requires_co_residency_with_lyfo = character(),
    requires_bridge_validation = character(),
    notes = character()
  )
}

mcl_asct_empty_source_resolution <- function() {
  empty_df(
    source_id = character(),
    canonical_source_id = character(),
    evidence_family = character(),
    db_name = character(),
    schema = character(),
    table = character(),
    resolution_status = character(),
    relation_probe_success = logical(),
    column_probe_success = logical(),
    co_residency_probe_success = logical(),
    bridge_probe_success = logical(),
    qualifying_event_probe_success = logical(),
    qualifying_event_count_status = character(),
    qualifying_person_count_display = character(),
    qualifying_person_count_suppressed = logical(),
    usable_for_primary_asct = logical(),
    usable_for_sensitivity_asct = logical(),
    missing_reason = character(),
    caveat = character()
  )
}

mcl_asct_empty_primary_vs_conditioning_counts <- function() {
  empty_df(
    state_id = character(),
    state_label = character(),
    evidence_tier = character(),
    persons_n = character(),
    suppressed_flag = logical(),
    denominator = character(),
    timing_window = character(),
    usable_for_primary_asct = logical(),
    usable_for_sensitivity_asct = logical(),
    caveat = character()
  )
}

mcl_asct_empty_validation_matrix <- function() {
  empty_df(
    validation_cell = character(),
    lyfo_asct_flag = character(),
    melphalan_flag = character(),
    beam_multi_component_flag = character(),
    relapse_asct_flag = character(),
    persons_n = character(),
    suppressed_flag = logical(),
    caveat = character()
  )
}

mcl_asct_empty_triangle_arm_proxy_counts <- function() {
  empty_df(
    arm_proxy_id = character(),
    arm_proxy_label = character(),
    induction_proxy_flag = character(),
    btk_flag = character(),
    asct_primary_lyfo_flag = character(),
    conditioning_support_flag = character(),
    persons_n = character(),
    suppressed_flag = logical(),
    caveat = character()
  )
}

mcl_asct_empty_evidence_timing <- function() {
  empty_df(
    timing_id = character(),
    anchor = character(),
    window_start_days = integer(),
    window_end_days = integer(),
    persons_n = character(),
    suppressed_flag = logical(),
    caveat = character()
  )
}

mcl_asct_empty_protocol_runway <- function() {
  empty_df(
    runway_item = character(),
    status = character(),
    owner_hint = character(),
    notes = character()
  )
}

mcl_asct_read_evidence_sources <- function(project_root = ".") {
  path <- file.path(project_root, "config", "mcl_triangle_asct_hdt_evidence_sources.tsv")
  if (!file.exists(path)) return(mcl_asct_empty_evidence_sources())
  x <- read_delimited_file(path)
  needed <- mcl_asct_required_evidence_source_columns()
  missing <- setdiff(needed, names(x))
  if (length(missing)) {
    stop(
      "MCL/TRIANGLE ASCT/HDT evidence-source configuration is missing columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  x <- x[needed]
  for (nm in names(x)) x[[nm]] <- as.character(x[[nm]] %||% "")
  x
}

mcl_asct_sql_count_string <- function(x) {
  if (exists("mcl_count_sql_string", mode = "function")) {
    return(mcl_count_sql_string(x))
  }
  paste0("'", gsub("'", "''", as.character(x %||% ""), fixed = TRUE), "'")
}

mcl_asct_bool <- function(x) {
  if (exists("mcl_count_bool", mode = "function")) return(mcl_count_bool(x))
  tolower(trimws(as.character(x %||% ""))) %in% c("true", "t", "1", "yes", "y")
}

mcl_asct_split_config <- function(x) {
  if (exists("mcl_count_split_config", mode = "function")) return(mcl_count_split_config(x))
  out <- unlist(strsplit(as.character(x %||% ""), ";", fixed = TRUE), use.names = FALSE)
  out <- trimws(out)
  out[nzchar(out)]
}

mcl_asct_relation_sql <- function(source) {
  paste0(
    "select count(*) as probe_count\n",
    "from ", mcl_count_sql_table(source$schema[[1]], source$table[[1]]), "\n",
    "where false;"
  )
}

mcl_asct_probe_columns <- function(source, include_bridge_source = FALSE) {
  cols <- unique(c(
    mcl_asct_split_config(source$person_key_column[[1]]),
    mcl_asct_split_config(source$code_column[[1]]),
    mcl_asct_split_config(source$date_columns[[1]]),
    mcl_asct_split_config(source$dose_columns[[1]]),
    mcl_asct_split_config(source$route_columns[[1]]),
    mcl_asct_split_config(source$drug_name_columns[[1]]),
    if (isTRUE(include_bridge_source)) mcl_asct_split_config(source$bridge_source_key_column[[1]]) else character()
  ))
  cols[nzchar(cols)]
}

mcl_asct_column_sql <- function(source, columns) {
  if (!length(columns)) return(mcl_asct_relation_sql(source))
  paste0(
    "select ", paste(vapply(columns, mcl_count_sql_ident, character(1)), collapse = ", "),
    "\nfrom ", mcl_count_sql_table(source$schema[[1]], source$table[[1]]), "\n",
    "where false;"
  )
}

mcl_asct_code_validation_required <- function(source) {
  code_values <- toupper(mcl_asct_split_config(source$code_value[[1]]))
  any(code_values %in% c("CONFIG_REQUIRED", "TBD", "TO_BE_VALIDATED")) ||
    grepl("requires_code_validation", source$evidence_tier[[1]] %||% "", ignore.case = TRUE) ||
    grepl("transplant_procedure_candidate", source$evidence_family[[1]] %||% "", ignore.case = TRUE)
}

mcl_asct_exact_code_predicate_sql <- function(source, alias = "x") {
  code_values <- toupper(mcl_asct_split_config(source$code_value[[1]]))
  code_values <- code_values[!code_values %in% c("CONFIG_REQUIRED", "TBD", "TO_BE_VALIDATED")]
  code_columns <- mcl_asct_split_config(source$code_column[[1]])
  if (!length(code_values) || !length(code_columns)) return("")
  values_sql <- paste(vapply(code_values, mcl_asct_sql_count_string, character(1)), collapse = ", ")
  paste(
    vapply(code_columns, function(col) {
      paste0("upper(trim(", alias, ".", mcl_count_sql_ident(col), "::text)) in (", values_sql, ")")
    }, character(1)),
    collapse = " or "
  )
}

mcl_asct_qualifying_event_sql <- function(source) {
  person_col <- source$person_key_column[[1]] %||% ""
  if (!nzchar(person_col) || isTRUE(mcl_asct_code_validation_required(source))) return("")
  ref <- mcl_count_sql_table(source$schema[[1]], source$table[[1]])
  date_cols <- mcl_asct_split_config(source$date_columns[[1]])
  date_expr <- if (length(date_cols)) mcl_count_date_coalesce_sql("x", source$date_columns[[1]]) else ""
  code_system <- toupper(trimws(source$code_system[[1]] %||% ""))
  pred <- if (identical(code_system, "DATE_FIELD")) {
    if (!nzchar(date_expr)) return("")
    paste0(date_expr, " is not null")
  } else {
    code_pred <- mcl_asct_exact_code_predicate_sql(source, "x")
    if (!nzchar(code_pred)) return("")
    if (nzchar(date_expr)) {
      paste0("(", code_pred, ") and ", date_expr, " is not null")
    } else {
      paste0("(", code_pred, ")")
    }
  }
  paste0(
    "select count(distinct x.", mcl_count_sql_ident(person_col), ") as qualifying_people\n",
    "from ", ref, " x\n",
    "where x.", mcl_count_sql_ident(person_col), " is not null\n",
    "  and ", pred, ";"
  )
}

mcl_asct_source_probe <- function(db_adapter, source, lyfo_mapping) {
  requires_bridge <- mcl_asct_bool(source$requires_bridge_validation[[1]]) ||
    nzchar(source$bridge_table[[1]] %||% "")
  relation <- mcl_count_db_query_result(db_adapter, mcl_asct_relation_sql(source))
  relation_success <- is.data.frame(relation$data) && nrow(relation$data) == 1L &&
    "probe_count" %in% names(relation$data)
  relation_error <- relation$error_message_sanitized %||% ""
  if (!relation_success && !nzchar(relation_error) && is.data.frame(relation$data)) {
    relation_error <- "Relation probe returned an unexpected aggregate shape."
  }

  columns <- mcl_asct_probe_columns(source, include_bridge_source = requires_bridge)
  column <- if (relation_success) {
    mcl_count_db_query_result(db_adapter, mcl_asct_column_sql(source, columns))
  } else {
    list(data = NULL, error_message_sanitized = "")
  }
  column_success <- is.data.frame(column$data) &&
    (!length(columns) || all(tolower(columns) %in% tolower(names(column$data))))
  column_error <- column$error_message_sanitized %||% ""
  if (relation_success && !column_success && !nzchar(column_error) && is.data.frame(column$data)) {
    missing <- setdiff(tolower(columns), tolower(names(column$data)))
    column_error <- paste("Missing source column(s):", paste(missing, collapse = ", "))
  }

  bridge_attempted <- FALSE
  bridge_success <- !requires_bridge
  bridge_error <- ""
  co_attempted <- FALSE
  co_success <- FALSE
  co_error <- ""
  qualifying_attempted <- FALSE
  qualifying_success <- FALSE
  qualifying_raw <- NA_integer_
  qualifying_error <- ""
  qualifying_count_status <- "not_attempted"

  source_db <- source$db_name[[1]] %||% ""
  lyfo_db <- lyfo_mapping$db_name[[1]] %||% ""
  same_db <- !nzchar(source_db) || !nzchar(lyfo_db) || identical(tolower(source_db), tolower(lyfo_db))

  if (relation_success && column_success && !same_db) {
    co_error <- paste0("Cross-database join unavailable: source db_name=", source_db, " and RKKP_LYFO db_name=", lyfo_db, ".")
  } else if (relation_success && column_success && requires_bridge) {
    bridge_attempted <- TRUE
    bridge_cols <- unique(c(
      mcl_asct_split_config(source$bridge_key_column[[1]]),
      mcl_asct_split_config(source$bridge_person_key_column[[1]])
    ))
    bridge_cols <- bridge_cols[nzchar(bridge_cols)]
    bridge_sql <- paste0(
      "select ", paste(vapply(bridge_cols, mcl_count_sql_ident, character(1)), collapse = ", "),
      "\nfrom ", mcl_count_sql_table(source$schema[[1]], source$bridge_table[[1]]), "\n",
      "where false;"
    )
    bridge <- mcl_count_db_query_result(db_adapter, bridge_sql)
    bridge_success <- is.data.frame(bridge$data) && all(tolower(bridge_cols) %in% tolower(names(bridge$data)))
    bridge_error <- bridge$error_message_sanitized %||% ""
    if (!bridge_success && !nzchar(bridge_error) && is.data.frame(bridge$data)) {
      missing <- setdiff(tolower(bridge_cols), tolower(names(bridge$data)))
      bridge_error <- paste("Missing bridge column(s):", paste(missing, collapse = ", "))
    }
    if (bridge_success) {
      co_sql <- paste0(
        "select count(*) as probe_count\n",
        "from ", mcl_count_sql_table(lyfo_mapping$schema[[1]], lyfo_mapping$table[[1]]), " r\n",
        "join ", mcl_count_sql_table(source$schema[[1]], source$bridge_table[[1]]), " b on b.",
        mcl_count_sql_ident(source$bridge_person_key_column[[1]]), "::text = r.",
        mcl_count_sql_ident(lyfo_mapping$person_key_column[[1]]), "::text\n",
        "join ", mcl_count_sql_table(source$schema[[1]], source$table[[1]]), " s on s.",
        mcl_count_sql_ident(source$bridge_source_key_column[[1]]), "::text = b.",
        mcl_count_sql_ident(source$bridge_key_column[[1]]), "::text\n",
        "where false;"
      )
      co <- mcl_count_db_query_result(db_adapter, co_sql)
      co_attempted <- TRUE
      co_success <- is.data.frame(co$data) && nrow(co$data) == 1L && "probe_count" %in% names(co$data)
      co_error <- co$error_message_sanitized %||% ""
      if (!co_success && !nzchar(co_error) && is.data.frame(co$data)) {
        co_error <- "Bridge co-residency probe returned an unexpected aggregate shape."
      }
    }
  } else if (relation_success && column_success && nzchar(source$person_key_column[[1]] %||% "")) {
    if (identical(tolower(source$table[[1]]), tolower(lyfo_mapping$table[[1]]))) {
      co_attempted <- TRUE
      co_success <- TRUE
    } else {
      co <- mcl_count_co_residency_probe(
        db_adapter,
        lyfo_mapping,
        source$schema[[1]],
        source$table[[1]],
        source$person_key_column[[1]],
        source_db_name = source_db,
        lyfo_db_name = lyfo_db
      )
      co_attempted <- isTRUE(co$co_residency_probe_attempted)
      co_success <- isTRUE(co$co_residency_probe_success)
      co_error <- co$co_residency_probe_error_sanitized %||% ""
    }
  }
  if (relation_success && column_success && bridge_success && co_success) {
    if (mcl_asct_code_validation_required(source)) {
      qualifying_count_status <- "inventory_only_code_validation_required"
    } else {
      qualifying_sql <- mcl_asct_qualifying_event_sql(source)
      if (nzchar(qualifying_sql)) {
        qualifying_attempted <- TRUE
        qualifying <- mcl_count_db_query_result(db_adapter, qualifying_sql)
        qualifying_success <- is.data.frame(qualifying$data) &&
          nrow(qualifying$data) == 1L &&
          "qualifying_people" %in% names(qualifying$data)
        qualifying_error <- qualifying$error_message_sanitized %||% ""
        if (qualifying_success) {
          qualifying_raw <- suppressWarnings(as.integer(qualifying$data$qualifying_people[[1]]))
          if (is.na(qualifying_raw)) {
            qualifying_success <- FALSE
            qualifying_error <- "Qualifying event probe returned a non-integer aggregate."
            qualifying_count_status <- "qualifying_event_probe_failed"
          } else if (qualifying_raw == 0L) {
            qualifying_count_status <- "available_zero_qualifying_events"
          } else {
            qualifying_count_status <- "available_with_qualifying_events"
          }
        } else {
          if (!nzchar(qualifying_error) && is.data.frame(qualifying$data)) {
            qualifying_error <- "Qualifying event probe returned an unexpected aggregate shape."
          }
          qualifying_count_status <- "qualifying_event_probe_failed"
        }
      } else {
        qualifying_error <- "No exact qualifying event predicate was configured."
        qualifying_count_status <- "not_applicable_no_exact_person_predicate"
      }
    }
  }

  list(
    relation_probe_success = relation_success,
    relation_probe_error_sanitized = relation_error,
    column_probe_success = column_success,
    column_probe_error_sanitized = column_error,
    bridge_probe_success = bridge_success,
    bridge_probe_attempted = bridge_attempted,
    bridge_probe_error_sanitized = bridge_error,
    co_residency_probe_success = co_success,
    co_residency_probe_attempted = co_attempted,
    co_residency_probe_error_sanitized = co_error,
    qualifying_event_probe_attempted = qualifying_attempted,
    qualifying_event_probe_success = qualifying_success,
    qualifying_event_count_raw = qualifying_raw,
    qualifying_event_count_status = qualifying_count_status,
    qualifying_event_probe_error_sanitized = qualifying_error
  )
}

mcl_asct_source_resolution <- function(sources, person_date_mapping, db_adapter = NULL, min_cell_count = 5L) {
  sources <- mcl_count_match_empty(sources, mcl_asct_empty_evidence_sources())
  if (!nrow(sources)) return(mcl_asct_empty_source_resolution())
  lyfo <- mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  db_available <- mcl_count_db_adapter_available(db_adapter) && !is.function(db_adapter$mcl_triangle_count_sets)
  rows <- lapply(seq_len(nrow(sources)), function(i) {
    source <- sources[i, , drop = FALSE]
    requires_bridge <- mcl_asct_bool(source$requires_bridge_validation[[1]]) ||
      nzchar(source$bridge_table[[1]] %||% "")
    include_primary <- mcl_asct_bool(source$include_in_primary_asct[[1]])
    include_sensitivity <- mcl_asct_bool(source$include_in_sensitivity_asct[[1]])
    inventory_only <- isTRUE(mcl_asct_code_validation_required(source))
    if (!nrow(lyfo) || !mcl_count_mapping_usable(lyfo)) {
      probe <- list(
        relation_probe_success = FALSE,
        column_probe_success = FALSE,
        co_residency_probe_success = FALSE,
        bridge_probe_success = !requires_bridge,
        qualifying_event_probe_success = FALSE,
        qualifying_event_count_raw = NA_integer_,
        qualifying_event_count_status = "not_attempted"
      )
      reason <- "RKKP_LYFO mapping is unavailable; ASCT/HDT source validation failed closed."
      resolution_status <- "lyfo_mapping_unavailable"
    } else if (!db_available) {
      probe <- list(
        relation_probe_success = FALSE,
        column_probe_success = FALSE,
        co_residency_probe_success = FALSE,
        bridge_probe_success = !requires_bridge,
        qualifying_event_probe_success = FALSE,
        qualifying_event_count_raw = NA_integer_,
        qualifying_event_count_status = "not_attempted"
      )
      reason <- "Production DB adapter unavailable; source not used for ASCT/HDT evidence."
      resolution_status <- "db_adapter_unavailable"
    } else {
      probe <- mcl_asct_source_probe(db_adapter, source, lyfo)
      reason <- ""
      resolution_status <- ""
    }
    relation_ok <- isTRUE(probe$relation_probe_success)
    column_ok <- isTRUE(probe$column_probe_success)
    bridge_ok <- isTRUE(probe$bridge_probe_success)
    co_ok <- isTRUE(probe$co_residency_probe_success)
    if (!nzchar(reason)) {
      if (!relation_ok) {
        reason <- probe$relation_probe_error_sanitized %||% "Relation probe failed."
        resolution_status <- "relation_missing_or_unreadable"
      } else if (!column_ok) {
        reason <- probe$column_probe_error_sanitized %||% "Column probe failed."
        resolution_status <- "columns_missing_or_unreadable"
      } else if (!bridge_ok) {
        reason <- probe$bridge_probe_error_sanitized %||% "Bridge probe failed."
        resolution_status <- "bridge_failed"
      } else if (!co_ok) {
        reason <- probe$co_residency_probe_error_sanitized %||% "Co-residency probe failed."
        resolution_status <- "co_residency_failed"
      } else if (inventory_only) {
        reason <- "Exact ASCT/SCT procedure codes are not validated; source remains inventory-only."
        resolution_status <- "inventory_only_code_validation_required"
      } else if (identical(probe$qualifying_event_count_status %||% "", "qualifying_event_probe_failed")) {
        reason <- probe$qualifying_event_probe_error_sanitized %||% "Qualifying event probe failed."
        resolution_status <- "qualifying_event_probe_failed"
      } else if (!include_primary && !include_sensitivity) {
        reason <- "Configured as validation/inventory-only; not included in primary or sensitivity ASCT counts."
        resolution_status <- "available_not_selected_for_asct_counts"
      } else if (identical(probe$qualifying_event_count_status %||% "", "available_zero_qualifying_events")) {
        resolution_status <- "available_zero_qualifying_events"
      } else if (identical(probe$qualifying_event_count_status %||% "", "available_with_qualifying_events")) {
        resolution_status <- "available_with_qualifying_events"
      } else {
        resolution_status <- "available_source_probe_only"
      }
    }
    qualifying_failed <- identical(probe$qualifying_event_count_status %||% "", "qualifying_event_probe_failed") ||
      identical(probe$qualifying_event_count_status %||% "", "not_applicable_no_exact_person_predicate")
    usable_base <- relation_ok && column_ok && bridge_ok && co_ok && !inventory_only && !qualifying_failed
    qualifying_display <- ""
    qualifying_suppressed <- FALSE
    qualifying_raw <- suppressWarnings(as.integer(probe$qualifying_event_count_raw %||% NA_integer_))
    if (!is.na(qualifying_raw)) {
      suppressed <- mcl_count_suppress(qualifying_raw, min_cell_count = min_cell_count)
      qualifying_display <- suppressed$display
      qualifying_suppressed <- isTRUE(suppressed$suppressed)
    }
    data.frame(
      source_id = source$source_id[[1]],
      canonical_source_id = source$canonical_source_id[[1]],
      evidence_family = source$evidence_family[[1]],
      db_name = source$db_name[[1]],
      schema = source$schema[[1]],
      table = source$table[[1]],
      resolution_status = resolution_status,
      relation_probe_success = relation_ok,
      column_probe_success = column_ok,
      co_residency_probe_success = co_ok,
      bridge_probe_success = bridge_ok,
      qualifying_event_probe_success = isTRUE(probe$qualifying_event_probe_success),
      qualifying_event_count_status = probe$qualifying_event_count_status %||% "not_attempted",
      qualifying_person_count_display = qualifying_display,
      qualifying_person_count_suppressed = qualifying_suppressed,
      usable_for_primary_asct = usable_base && include_primary,
      usable_for_sensitivity_asct = usable_base && include_sensitivity,
      missing_reason = reason,
      caveat = if (usable_base) source$notes[[1]] else paste("Failed closed:", reason),
      stringsAsFactors = FALSE
    )
  })
  mcl_count_match_empty(bind_rows_base(rows), mcl_asct_empty_source_resolution())
}

mcl_asct_count_specs_primary <- function() {
  data.frame(
    state_id = c(
      "asct_hdt_primary_lyfo",
      "asct_hdt_validated_by_conditioning",
      "asct_hdt_lyfo_only_no_conditioning_seen",
      "melphalan_near_stem_cell_infusion",
      "melphalan_in_first_line_transplant_window",
      "beam_multi_component_near_infusion",
      "asct_hdt_conditioning_rescue_candidate",
      "asct_hdt_relapse_recurrence_lyfo"
    ),
    state_label = c(
      "Primary first-line LYFO ASCT/HDT",
      "LYFO ASCT/HDT validated by conditioning evidence",
      "LYFO ASCT/HDT with no conditioning medication seen",
      "Melphalan near stem-cell infusion",
      "Melphalan in first-line transplant window",
      "BEAM multi-component support near infusion",
      "Conditioning-only rescue candidate",
      "Relapse/recurrence LYFO ASCT/HDT"
    ),
    evidence_tier = c(
      "primary_registry",
      "registry_validated_subset",
      "primary_registry_no_medication_seen",
      "medication_support",
      "medication_support",
      "multi_component_medication_support",
      "sensitivity_rescue",
      "relapse_registry"
    ),
    denominator = "all_lyfo_mcl",
    timing_window = c(
      "first_line_lyfo_beh_fields",
      "near_stem_cell_infusion",
      "near_stem_cell_infusion",
      "near_stem_cell_infusion_-45_to_+7_days",
      "first_line_transplant_window_+60_to_+240_days",
      "near_stem_cell_infusion_-45_to_+7_days",
      "sensitivity_near_or_first_line_transplant_window",
      "relapse_recurrence"
    ),
    usable_for_primary_asct = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
    usable_for_sensitivity_asct = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
    caveat = c(
      "Primary ASCT/HDT phenotype remains the LYFO Beh_* first-line rule.",
      "Validated subset of primary LYFO ASCT/HDT; conditioning evidence supports but does not replace LYFO.",
      "Absence of medication evidence is not evidence of no conditioning; medication capture may be incomplete.",
      "Melphalan support is validation/sensitivity evidence only, not primary ASCT.",
      "First-line transplant-window melphalan is sensitivity evidence only.",
      "Requires melphalan plus another BEAM component; cytarabine alone is not conditioning evidence.",
      "Candidate rescue signal only; requires transplant procedure validation or clinical review.",
      "Relapse/recurrence transplant evidence is kept separate from first-line ASCT/HDT."
    ),
    condition_sql = c(
      "asct_hdt_primary_lyfo",
      "asct_hdt_primary_lyfo and (melphalan_near_stem_cell_infusion or beam_multi_component_near_infusion)",
      "asct_hdt_primary_lyfo and not (melphalan_near_stem_cell_infusion or beam_multi_component_near_infusion)",
      "melphalan_near_stem_cell_infusion",
      "melphalan_in_first_line_transplant_window",
      "beam_multi_component_near_infusion",
      "not asct_hdt_primary_lyfo and (melphalan_near_stem_cell_infusion or beam_multi_component_near_infusion or melphalan_in_first_line_transplant_window)",
      "asct_hdt_relapse_recurrence_lyfo"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_asct_count_specs_validation <- function() {
  data.frame(
    validation_cell = c(
      "LYFO_ASCT_yes__melphalan_near_infusion_yes",
      "LYFO_ASCT_yes__melphalan_not_seen",
      "LYFO_ASCT_no__melphalan_near_infusion_yes",
      "LYFO_ASCT_no__melphalan_first_line_window_only",
      "LYFO_ASCT_no__BEAM_multi_component_yes",
      "relapse_ASCT_only",
      "no_ASCT_or_conditioning_evidence"
    ),
    lyfo_asct_flag = c("yes", "yes", "no", "no", "no", "no", "no"),
    melphalan_flag = c("near_infusion", "not_seen", "near_infusion", "first_line_window_only", "any", "not_primary", "not_seen"),
    beam_multi_component_flag = c("not_required", "not_seen", "not_required", "not_required", "yes", "not_required", "not_seen"),
    relapse_asct_flag = c("any", "any", "any", "any", "any", "yes", "no"),
    caveat = c(
      "Registry ASCT with melphalan near infusion.",
      "Registry ASCT without observed melphalan support; absence may reflect missing medication capture.",
      "Melphalan near infusion without LYFO primary ASCT is sensitivity/rescue evidence only.",
      "Melphalan only in the first-line transplant window is sensitivity evidence only.",
      "BEAM multi-component support without LYFO primary ASCT is sensitivity/rescue evidence only.",
      "Relapse/recurrence ASCT only; not merged into first-line.",
      "No primary, relapse, or validated conditioning signal seen in configured sources."
    ),
    condition_sql = c(
      "asct_hdt_primary_lyfo and melphalan_near_stem_cell_infusion",
      "asct_hdt_primary_lyfo and not (melphalan_near_stem_cell_infusion or melphalan_in_first_line_transplant_window)",
      "not asct_hdt_primary_lyfo and melphalan_near_stem_cell_infusion",
      "not asct_hdt_primary_lyfo and not melphalan_near_stem_cell_infusion and melphalan_in_first_line_transplant_window",
      "not asct_hdt_primary_lyfo and beam_multi_component_near_infusion",
      "asct_hdt_relapse_recurrence_lyfo and not asct_hdt_primary_lyfo",
      "not asct_hdt_primary_lyfo and not asct_hdt_relapse_recurrence_lyfo and not melphalan_near_stem_cell_infusion and not melphalan_in_first_line_transplant_window and not beam_multi_component_near_infusion"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_asct_count_specs_arm_proxy <- function() {
  data.frame(
    arm_proxy_id = c(
      "triangle_btk_no_asct_arm_proxy",
      "triangle_btk_plus_asct_arm_proxy",
      "legacy_asct_standard_proxy",
      "legacy_induction_no_asct_no_btk",
      "induction_unknown",
      "btk_exposure_without_induction_proxy",
      "asct_without_induction_proxy"
    ),
    arm_proxy_label = c(
      "TRIANGLE BTKi no-ASCT arm proxy",
      "TRIANGLE BTKi plus ASCT arm proxy",
      "Legacy ASCT standard proxy",
      "Legacy induction without ASCT/BTKi",
      "Induction unknown",
      "BTKi exposure without induction proxy",
      "ASCT without induction proxy"
    ),
    induction_proxy_flag = c("yes", "yes", "yes", "yes", "no", "no", "no"),
    btk_flag = c("yes", "yes", "no", "no", "no", "yes", "any"),
    asct_primary_lyfo_flag = c("no", "yes", "yes", "no", "no", "any", "yes"),
    conditioning_support_flag = c("any", "any", "any", "any", "any", "any", "any"),
    caveat = c(
      "BTKi plus induction and no LYFO primary ASCT can represent a post-TRIANGLE no-ASCT treatment path, not just missing ASCT capture.",
      "BTKi plus induction with LYFO primary ASCT/HDT.",
      "Induction plus LYFO primary ASCT/HDT without BTKi evidence in the first-line proxy window.",
      "Could represent missing ASCT capture, clinical non-transplant decision, incomplete treatment, progression, toxicity, or incomplete source mapping.",
      "No exact LYFO induction proxy value seen; not classified into TRIANGLE/legacy arm proxies.",
      "BTKi evidence without exact LYFO induction proxy; requires timing/source review.",
      "LYFO primary ASCT without exact LYFO induction proxy; requires regimen-value review."
    ),
    condition_sql = c(
      "triangle_induction_cytarabine_platinum_proxy and triangle_btk_exposure_any and not asct_hdt_primary_lyfo",
      "triangle_induction_cytarabine_platinum_proxy and triangle_btk_exposure_any and asct_hdt_primary_lyfo",
      "triangle_induction_cytarabine_platinum_proxy and asct_hdt_primary_lyfo and not triangle_btk_exposure_any",
      "triangle_induction_cytarabine_platinum_proxy and not asct_hdt_primary_lyfo and not triangle_btk_exposure_any",
      "not triangle_induction_cytarabine_platinum_proxy and not asct_hdt_primary_lyfo and not triangle_btk_exposure_any",
      "not triangle_induction_cytarabine_platinum_proxy and triangle_btk_exposure_any",
      "not triangle_induction_cytarabine_platinum_proxy and asct_hdt_primary_lyfo"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_asct_count_specs_timing <- function() {
  data.frame(
    timing_id = c(
      "near_stem_cell_infusion",
      "first_line_transplant_window",
      "broad_first_line_window"
    ),
    anchor = c(
      "RKKP_LYFO.Beh_Stamcelleinfusion_dt",
      "RKKP_LYFO.Beh_KemoterapiStart_dt",
      "RKKP_LYFO.Beh_KemoterapiStart_dt or RKKP_LYFO.Reg_BehandlingBeslutning_dt"
    ),
    window_start_days = c(-45L, 60L, -30L),
    window_end_days = c(7L, 240L, 240L),
    caveat = c(
      "Best validation window for BEAM/melphalan conditioning.",
      "Rescue window when stem-cell infusion date is missing but first-line start is known.",
      "Source validation only; broad-window medication alone is not primary ASCT."
    ),
    condition_sql = c(
      "melphalan_near_stem_cell_infusion or beam_multi_component_near_infusion",
      "melphalan_in_first_line_transplant_window",
      "broad_first_line_conditioning_support"
    ),
    stringsAsFactors = FALSE
  )
}

mcl_asct_format_counts <- function(data, spec, empty, id_col, min_cell_count = 5L, failure_caveat = "") {
  spec_public <- spec[setdiff(names(spec), c("condition_sql", "condition_r"))]
  if (!is.data.frame(data) || !nrow(data) || !"persons_raw" %in% names(data)) {
    out <- spec_public
    out$persons_n <- rep("", nrow(out))
    out$suppressed_flag <- rep(FALSE, nrow(out))
    if (nzchar(failure_caveat)) {
      out$caveat <- trimws(paste(out$caveat %||% "", failure_caveat))
    }
    return(mcl_count_match_empty(out, empty))
  }
  counts <- data[, c(id_col, "persons_raw"), drop = FALSE]
  names(counts)[names(counts) == "persons_raw"] <- ".persons_raw"
  out <- merge(spec_public, counts, by = id_col, all.x = TRUE, sort = FALSE)
  out <- out[match(spec_public[[id_col]], out[[id_col]]), , drop = FALSE]
  suppressed <- lapply(out$.persons_raw, mcl_count_suppress, min_cell_count = min_cell_count)
  out$persons_n <- vapply(suppressed, function(x) x$display, character(1))
  out$suppressed_flag <- vapply(suppressed, function(x) isTRUE(x$suppressed), logical(1))
  out$.persons_raw <- NULL
  if (nzchar(failure_caveat)) out$caveat <- trimws(paste(out$caveat %||% "", failure_caveat))
  mcl_count_match_empty(out, empty)
}

mcl_asct_selected_sources <- function(sources, source_resolution, sensitivity = TRUE) {
  sources <- mcl_count_match_empty(sources, mcl_asct_empty_evidence_sources())
  resolution <- mcl_count_match_empty(source_resolution, mcl_asct_empty_source_resolution())
  if (!nrow(sources) || !nrow(resolution)) return(sources[FALSE, , drop = FALSE])
  flag <- if (isTRUE(sensitivity)) "usable_for_sensitivity_asct" else "usable_for_primary_asct"
  selected_ids <- resolution$source_id[resolution[[flag]] %in% TRUE]
  sources[sources$source_id %in% selected_ids, , drop = FALSE]
}

mcl_asct_conditioning_evidence_families <- function() {
  c(
    "melphalan_conditioning_support",
    "beam_component_support",
    "melphalan_order_support",
    "beam_component_order_support",
    "melphalan_administered_support",
    "beam_component_administered_support",
    "melphalan_prescription_candidate"
  )
}

mcl_asct_medication_event_sql <- function(source) {
  code_values <- toupper(mcl_asct_split_config(source$code_value[[1]]))
  code_columns <- mcl_asct_split_config(source$code_column[[1]])
  if (!length(code_values) || !length(code_columns) || !nzchar(source$person_key_column[[1]] %||% "")) return(character())
  ref <- mcl_count_sql_table(source$schema[[1]], source$table[[1]])
  date_expr <- mcl_count_date_coalesce_sql("x", source$date_columns[[1]])
  rows <- list()
  for (code_value in code_values) {
    pred <- paste(
      vapply(code_columns, function(col) {
        paste0("upper(trim(x.", mcl_count_sql_ident(col), "::text)) = ", mcl_asct_sql_count_string(code_value))
      }, character(1)),
      collapse = " or "
    )
    rows[[length(rows) + 1L]] <- paste0(
      "select distinct x.", mcl_count_sql_ident(source$person_key_column[[1]]), " as person_key,\n",
      "       ", mcl_asct_sql_count_string(source$source_id[[1]]), " as source_id,\n",
      "       ", mcl_asct_sql_count_string(source$evidence_family[[1]]), " as evidence_family,\n",
      "       ", mcl_asct_sql_count_string(code_value), " as code_value,\n",
      "       ", date_expr, " as event_date\n",
      "from ", ref, " x\n",
      "where x.", mcl_count_sql_ident(source$person_key_column[[1]]), " is not null\n",
      "  and ", date_expr, " is not null\n",
      "  and (", pred, ")"
    )
  }
  unlist(rows, use.names = FALSE)
}

mcl_asct_conditioning_union_sql <- function(sources, source_resolution) {
  selected <- mcl_asct_selected_sources(sources, source_resolution, sensitivity = TRUE)
  if (!nrow(selected)) return("")
  keep <- toupper(selected$code_system %||% "") == "ATC" &
    selected$evidence_family %in% mcl_asct_conditioning_evidence_families() &
    !vapply(seq_len(nrow(selected)), function(i) mcl_asct_code_validation_required(selected[i, , drop = FALSE]), logical(1))
  selected <- selected[keep, , drop = FALSE]
  if (!nrow(selected)) return("")
  pieces <- unlist(lapply(seq_len(nrow(selected)), function(i) {
    mcl_asct_medication_event_sql(selected[i, , drop = FALSE])
  }), use.names = FALSE)
  pieces <- pieces[nzchar(pieces)]
  if (!length(pieces)) return("")
  paste(pieces, collapse = "\nunion\n")
}

mcl_asct_induction_regimen_values <- function() {
  c(
    "R-CHOP/R-DHAP",
    "R-DHAP",
    "R-DHAX",
    "DHAP",
    "DHAX",
    "R-ARAC",
    "HDARAC",
    "MAXICHOP",
    "MANTLE2",
    "MANTLE3"
  )
}

mcl_asct_regimen_predicate_sql <- function(alias, values) {
  values_sql <- paste(vapply(toupper(values), mcl_asct_sql_count_string, character(1)), collapse = ", ")
  fields <- c("Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3")
  paste(
    paste0("upper(trim(", alias, ".", mcl_count_sql_ident(fields), "::text)) in (", values_sql, ")"),
    collapse = " or "
  )
}

mcl_asct_shared_flags_sql <- function(person_date_mapping, sources, source_resolution,
                                      ibrutinib_source_validation = NULL,
                                      treatment_code_mappings = NULL) {
  lyfo <- mcl_count_source_mapping(person_date_mapping, "RKKP_LYFO", "RKKP_LYFO")
  if (!nrow(lyfo) || !mcl_count_mapping_usable(lyfo)) return("")
  lyfo_ref <- mcl_count_sql_table(lyfo$schema[[1]], lyfo$table[[1]])
  lyfo_key <- mcl_count_sql_ident(lyfo$person_key_column[[1]])
  med_union <- mcl_asct_conditioning_union_sql(sources, source_resolution)
  if (!nzchar(med_union)) {
    med_union <- "select null::text as person_key, null::text as source_id, null::text as evidence_family, null::text as code_value, null::date as event_date where false"
  }
  btk_union <- ""
  if (is.data.frame(ibrutinib_source_validation) && nrow(ibrutinib_source_validation)) {
    btk_union <- mcl_count_ibrutinib_union_data_sql(
      ibrutinib_source_validation,
      treatment_code_mappings %||% data.frame(stringsAsFactors = FALSE)
    )
  }
  if (!nzchar(btk_union)) {
    btk_union <- paste0(
      "select distinct x.", lyfo_key, " as person_key\n",
      "from ", lyfo_ref, " x\n",
      "where ", mcl_count_lyfo_ibrutinib_predicate_sql("x")
    )
  }
  induction_pred <- mcl_asct_regimen_predicate_sql("r", mcl_asct_induction_regimen_values())
  stem_date <- mcl_count_date_sql("r.\"Beh_Stamcelleinfusion_dt\"")
  first_line_date <- mcl_count_date_sql("r.\"Beh_KemoterapiStart_dt\"")
  decision_date <- mcl_count_date_sql("r.\"Reg_BehandlingBeslutning_dt\"")
  primary_asct <- paste0(
    "(", stem_date, " is not null",
    " or upper(trim(r.\"Beh_Hoejdosisbehandling\"::text)) = 'Y'",
    " or upper(trim(r.\"Beh_TypeAutologStamcellestoette\"::text)) in ('BEAM','OTHER','BCNU-THIOTEPA','BCNU','BEAC'))"
  )
  relapse_asct <- paste0(
    "(", mcl_count_date_sql("r.\"Rec_Stamcelleinfusion_dt\""), " is not null",
    " or upper(trim(r.\"Rec_Hoejdosisbehandling\"::text)) = 'Y')"
  )
  paste0(
    "mcl_base as (\n",
    "  select distinct r.", lyfo_key, " as person_key,\n",
    "         ", stem_date, " as stem_cell_date,\n",
    "         ", first_line_date, " as first_line_date,\n",
    "         ", decision_date, " as treatment_decision_date,\n",
    "         ", primary_asct, " as asct_hdt_primary_lyfo,\n",
    "         ", relapse_asct, " as asct_hdt_relapse_recurrence_lyfo,\n",
    "         (", induction_pred, ") as triangle_induction_cytarabine_platinum_proxy\n",
    "  from ", lyfo_ref, " r\n",
    "  where upper(trim(r.", mcl_count_sql_ident("subtype"), "::text)) = 'MCL'\n",
    "), medication_events as (\n",
    "  ", gsub("\n", "\n  ", med_union, fixed = TRUE), "\n",
    "), btk_any as (\n",
    "  ", gsub("\n", "\n  ", btk_union, fixed = TRUE), "\n",
    "), melphalan_near as (\n",
    "  select distinct b.person_key\n",
    "  from mcl_base b\n",
    "  join medication_events e on e.person_key::text = b.person_key::text\n",
    "  where e.code_value = 'L01AA03'\n",
    "    and b.stem_cell_date is not null\n",
    "    and e.event_date >= b.stem_cell_date - 45\n",
    "    and e.event_date <= b.stem_cell_date + 7\n",
    "), melphalan_first_line as (\n",
    "  select distinct b.person_key\n",
    "  from mcl_base b\n",
    "  join medication_events e on e.person_key::text = b.person_key::text\n",
    "  where e.code_value = 'L01AA03'\n",
    "    and b.first_line_date is not null\n",
    "    and e.event_date >= b.first_line_date + 60\n",
    "    and e.event_date <= b.first_line_date + 240\n",
    "), beam_component_near as (\n",
    "  select distinct b.person_key\n",
    "  from mcl_base b\n",
    "  join medication_events e on e.person_key::text = b.person_key::text\n",
    "  where e.code_value in ('L01AD01','L01CB01','L01BC01')\n",
    "    and b.stem_cell_date is not null\n",
    "    and e.event_date >= b.stem_cell_date - 45\n",
    "    and e.event_date <= b.stem_cell_date + 7\n",
    "), beam_multi as (\n",
    "  select distinct m.person_key\n",
    "  from melphalan_near m\n",
    "  join beam_component_near c on c.person_key::text = m.person_key::text\n",
    "), broad_first_line_support as (\n",
    "  select distinct b.person_key\n",
    "  from mcl_base b\n",
    "  join medication_events e on e.person_key::text = b.person_key::text\n",
    "  where e.code_value in ('L01AA03','L01AD01','L01CB01','L01BC01')\n",
    "    and coalesce(b.first_line_date, b.treatment_decision_date) is not null\n",
    "    and e.event_date >= coalesce(b.first_line_date, b.treatment_decision_date) - 30\n",
    "    and e.event_date <= coalesce(b.first_line_date, b.treatment_decision_date) + 240\n",
    "), flags as (\n",
    "  select b.person_key,\n",
    "         b.asct_hdt_primary_lyfo,\n",
    "         b.asct_hdt_relapse_recurrence_lyfo,\n",
    "         (mn.person_key is not null) as melphalan_near_stem_cell_infusion,\n",
    "         (mf.person_key is not null) as melphalan_in_first_line_transplant_window,\n",
    "         (bm.person_key is not null) as beam_multi_component_near_infusion,\n",
    "         (br.person_key is not null) as broad_first_line_conditioning_support,\n",
    "         b.triangle_induction_cytarabine_platinum_proxy,\n",
    "         (bk.person_key is not null) as triangle_btk_exposure_any\n",
    "  from mcl_base b\n",
    "  left join melphalan_near mn on mn.person_key::text = b.person_key::text\n",
    "  left join melphalan_first_line mf on mf.person_key::text = b.person_key::text\n",
    "  left join beam_multi bm on bm.person_key::text = b.person_key::text\n",
    "  left join broad_first_line_support br on br.person_key::text = b.person_key::text\n",
    "  left join btk_any bk on bk.person_key::text = b.person_key::text\n",
    ")"
  )
}

mcl_asct_count_sql <- function(flags_sql, spec, id_col) {
  pieces <- lapply(seq_len(nrow(spec)), function(i) {
    paste0(
      "select ", mcl_asct_sql_count_string(spec[[id_col]][[i]]), " as ", id_col, ",\n",
      "       count(distinct person_key) as persons_raw\n",
      "from flags\n",
      "where ", spec$condition_sql[[i]]
    )
  })
  paste0("with ", flags_sql, "\n", paste(unlist(pieces, use.names = FALSE), collapse = "\nunion all\n"), ";")
}

mcl_asct_execute_count_sql <- function(db_adapter, flags_sql, spec, empty, id_col, min_cell_count = 5L) {
  if (!nzchar(flags_sql %||% "") || !mcl_count_db_adapter_available(db_adapter) || is.function(db_adapter$mcl_triangle_count_sets)) {
    return(mcl_asct_format_counts(NULL, spec, empty, id_col, min_cell_count, "Production aggregate SQL was not run."))
  }
  result <- mcl_count_db_query_result(db_adapter, mcl_asct_count_sql(flags_sql, spec, id_col))
  success <- is.data.frame(result$data) && all(c(id_col, "persons_raw") %in% names(result$data))
  if (!success) {
    err <- result$error_message_sanitized %||% "Aggregate ASCT/HDT evidence query failed."
    return(mcl_asct_format_counts(NULL, spec, empty, id_col, min_cell_count, paste("Aggregate query failed closed:", err)))
  }
  mcl_asct_format_counts(result$data, spec, empty, id_col, min_cell_count)
}

mcl_asct_protocol_runway <- function() {
  data.frame(
    runway_item = c(
      "validate LYFO ASCT semantics",
      "validate BEAM/melphalan medication capture",
      "validate SP administered medication columns",
      "validate SMR/in-hospital medication columns",
      "validate SKS transplant procedure codes",
      "validate modern BTKi ATC codes",
      "validate R-DHAX/R-DHAP regimen values",
      "decide primary vs sensitivity ASCT definition",
      "update feasibility panel narrative"
    ),
    status = c(
      "primary_definition_preserved",
      "validation_layer_added",
      "source_probe_required",
      "source_probe_required",
      "inventory_only_until_code_validation",
      "candidate_probe_required",
      "exact_value_review_required",
      "primary_lyfo_sensitivity_conditioning_split",
      "updated"
    ),
    owner_hint = c(
      "clinical registry lead",
      "medication source reviewer",
      "SP source reviewer",
      "SDS/SMR source reviewer",
      "procedure-code reviewer",
      "medication source reviewer",
      "LYFO value-mapping reviewer",
      "PI/statistical analysis plan",
      "atlas maintainer"
    ),
    notes = c(
      "Primary first-line ASCT/HDT remains LYFO Beh_* only.",
      "BEAM/melphalan evidence validates or rescues sensitivity counts; it is not primary ASCT.",
      "Fail closed if administered-medication table or columns are absent.",
      "Fail closed if in-hospital medication table or columns are absent.",
      "Do not guess SKS ASCT/SCT procedure codes; produce inventory for human review.",
      "Modern BTKi codes L01EL01/L01EL02/L01EL03 require source probing before use.",
      "TRIANGLE induction proxy uses exact LYFO values, not broad raw-text matching.",
      "Melphalan alone cannot define primary ASCT/HDT.",
      "Panel copy separates primary LYFO ASCT, conditioning support, rescue candidates, and BTKi no-ASCT arm proxy."
    ),
    stringsAsFactors = FALSE
  )
}

mcl_asct_outputs_from_db <- function(person_date_mapping, sources, source_resolution, db_adapter,
                                     ibrutinib_source_validation = NULL,
                                     treatment_code_mappings = NULL,
                                     min_cell_count = 5L) {
  flags_sql <- mcl_asct_shared_flags_sql(
    person_date_mapping,
    sources,
    source_resolution,
    ibrutinib_source_validation = ibrutinib_source_validation,
    treatment_code_mappings = treatment_code_mappings
  )
  list(
    asct_hdt_source_resolution = source_resolution,
    asct_hdt_primary_vs_conditioning_counts = mcl_asct_execute_count_sql(
      db_adapter, flags_sql, mcl_asct_count_specs_primary(),
      mcl_asct_empty_primary_vs_conditioning_counts(), "state_id", min_cell_count
    ),
    asct_hdt_validation_matrix = mcl_asct_execute_count_sql(
      db_adapter, flags_sql, mcl_asct_count_specs_validation(),
      mcl_asct_empty_validation_matrix(), "validation_cell", min_cell_count
    ),
    triangle_arm_proxy_counts = mcl_asct_execute_count_sql(
      db_adapter, flags_sql, mcl_asct_count_specs_arm_proxy(),
      mcl_asct_empty_triangle_arm_proxy_counts(), "arm_proxy_id", min_cell_count
    ),
    asct_hdt_evidence_timing = mcl_asct_execute_count_sql(
      db_adapter, flags_sql, mcl_asct_count_specs_timing(),
      mcl_asct_empty_evidence_timing(), "timing_id", min_cell_count
    ),
    asct_hdt_protocol_runway = mcl_asct_protocol_runway()
  )
}

mcl_asct_count_from_flags <- function(flags, condition) {
  if (!is.data.frame(flags) || !nrow(flags)) return(NA_integer_)
  idx <- tryCatch(eval(parse(text = condition), envir = flags, enclos = parent.frame()), error = function(e) rep(FALSE, nrow(flags)))
  sum(idx %in% TRUE, na.rm = TRUE)
}

mcl_asct_format_flag_counts <- function(flags, spec, empty, id_col, min_cell_count = 5L) {
  data <- data.frame(
    id = spec[[id_col]],
    persons_raw = vapply(spec$condition_r, function(condition) mcl_asct_count_from_flags(flags, condition), integer(1)),
    stringsAsFactors = FALSE
  )
  names(data)[[1]] <- id_col
  mcl_asct_format_counts(data, spec, empty, id_col, min_cell_count)
}

mcl_asct_r_specs_primary <- function() {
  spec <- mcl_asct_count_specs_primary()
  spec$condition_r <- c(
    "asct_hdt_primary_lyfo",
    "asct_hdt_primary_lyfo & (melphalan_near_stem_cell_infusion | beam_multi_component_near_infusion)",
    "asct_hdt_primary_lyfo & !(melphalan_near_stem_cell_infusion | beam_multi_component_near_infusion)",
    "melphalan_near_stem_cell_infusion",
    "melphalan_in_first_line_transplant_window",
    "beam_multi_component_near_infusion",
    "!asct_hdt_primary_lyfo & (melphalan_near_stem_cell_infusion | beam_multi_component_near_infusion | melphalan_in_first_line_transplant_window)",
    "asct_hdt_relapse_recurrence_lyfo"
  )
  spec
}

mcl_asct_r_specs_validation <- function() {
  spec <- mcl_asct_count_specs_validation()
  spec$condition_r <- c(
    "asct_hdt_primary_lyfo & melphalan_near_stem_cell_infusion",
    "asct_hdt_primary_lyfo & !(melphalan_near_stem_cell_infusion | melphalan_in_first_line_transplant_window)",
    "!asct_hdt_primary_lyfo & melphalan_near_stem_cell_infusion",
    "!asct_hdt_primary_lyfo & !melphalan_near_stem_cell_infusion & melphalan_in_first_line_transplant_window",
    "!asct_hdt_primary_lyfo & beam_multi_component_near_infusion",
    "asct_hdt_relapse_recurrence_lyfo & !asct_hdt_primary_lyfo",
    "!asct_hdt_primary_lyfo & !asct_hdt_relapse_recurrence_lyfo & !melphalan_near_stem_cell_infusion & !melphalan_in_first_line_transplant_window & !beam_multi_component_near_infusion"
  )
  spec
}

mcl_asct_r_specs_arm_proxy <- function() {
  spec <- mcl_asct_count_specs_arm_proxy()
  spec$condition_r <- c(
    "triangle_induction_cytarabine_platinum_proxy & triangle_btk_exposure_any & !asct_hdt_primary_lyfo",
    "triangle_induction_cytarabine_platinum_proxy & triangle_btk_exposure_any & asct_hdt_primary_lyfo",
    "triangle_induction_cytarabine_platinum_proxy & asct_hdt_primary_lyfo & !triangle_btk_exposure_any",
    "triangle_induction_cytarabine_platinum_proxy & !asct_hdt_primary_lyfo & !triangle_btk_exposure_any",
    "!triangle_induction_cytarabine_platinum_proxy & !asct_hdt_primary_lyfo & !triangle_btk_exposure_any",
    "!triangle_induction_cytarabine_platinum_proxy & triangle_btk_exposure_any",
    "!triangle_induction_cytarabine_platinum_proxy & asct_hdt_primary_lyfo"
  )
  spec
}

mcl_asct_r_specs_timing <- function() {
  spec <- mcl_asct_count_specs_timing()
  spec$condition_r <- c(
    "melphalan_near_stem_cell_infusion | beam_multi_component_near_infusion",
    "melphalan_in_first_line_transplant_window",
    "broad_first_line_conditioning_support"
  )
  spec
}

mcl_asct_outputs_from_flags <- function(flags, source_resolution = mcl_asct_empty_source_resolution(), min_cell_count = 5L) {
  list(
    asct_hdt_source_resolution = mcl_count_match_empty(source_resolution, mcl_asct_empty_source_resolution()),
    asct_hdt_primary_vs_conditioning_counts = mcl_asct_format_flag_counts(
      flags, mcl_asct_r_specs_primary(), mcl_asct_empty_primary_vs_conditioning_counts(), "state_id", min_cell_count
    ),
    asct_hdt_validation_matrix = mcl_asct_format_flag_counts(
      flags, mcl_asct_r_specs_validation(), mcl_asct_empty_validation_matrix(), "validation_cell", min_cell_count
    ),
    triangle_arm_proxy_counts = mcl_asct_format_flag_counts(
      flags, mcl_asct_r_specs_arm_proxy(), mcl_asct_empty_triangle_arm_proxy_counts(), "arm_proxy_id", min_cell_count
    ),
    asct_hdt_evidence_timing = mcl_asct_format_flag_counts(
      flags, mcl_asct_r_specs_timing(), mcl_asct_empty_evidence_timing(), "timing_id", min_cell_count
    ),
    asct_hdt_protocol_runway = mcl_asct_protocol_runway()
  )
}

mcl_asct_outputs_from_sets <- function(count_sets = NULL, source_resolution = mcl_asct_empty_source_resolution(),
                                       min_cell_count = 5L) {
  if (!is.list(count_sets) || !length(count_sets)) {
    return(mcl_asct_outputs_from_flags(data.frame(stringsAsFactors = FALSE), source_resolution, min_cell_count))
  }
  all_people <- unique(unlist(count_sets, use.names = FALSE))
  if (!length(all_people)) return(mcl_asct_outputs_from_flags(data.frame(stringsAsFactors = FALSE), source_resolution, min_cell_count))
  has <- function(id) all_people %in% (count_sets[[id]] %||% character())
  flags <- data.frame(
    person_key = all_people,
    asct_hdt_primary_lyfo = has("asct_hdt_primary_lyfo") | has("asct_hdt_first_line"),
    asct_hdt_relapse_recurrence_lyfo = has("asct_hdt_relapse_recurrence"),
    melphalan_near_stem_cell_infusion = has("melphalan_near_stem_cell_infusion"),
    melphalan_in_first_line_transplant_window = has("melphalan_in_first_line_transplant_window"),
    beam_multi_component_near_infusion = has("beam_multi_component_near_infusion"),
    broad_first_line_conditioning_support = has("broad_first_line_conditioning_support"),
    triangle_induction_cytarabine_platinum_proxy = has("triangle_induction_cytarabine_platinum_proxy") | has("cit_immunochemotherapy"),
    triangle_btk_exposure_any = has("triangle_btk_exposure_any") | has("ibrutinib_exposure"),
    stringsAsFactors = FALSE
  )
  mcl_asct_outputs_from_flags(flags, source_resolution, min_cell_count)
}

mcl_asct_first_column <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit)) hit[[1]] else ""
}

mcl_asct_derive_fixture_flags <- function(lyfo, medication_events = data.frame(stringsAsFactors = FALSE)) {
  if (!is.data.frame(lyfo) || !nrow(lyfo)) return(data.frame(stringsAsFactors = FALSE))
  person_col <- mcl_asct_first_column(lyfo, c("person_key", "patientid", "id"))
  if (!nzchar(person_col)) stop("Synthetic LYFO fixture needs person_key or patientid.", call. = FALSE)
  person <- as.character(lyfo[[person_col]])
  stem <- safe_as_date(lyfo$Beh_Stamcelleinfusion_dt %||% NA)
  first_line <- safe_as_date(lyfo$Beh_KemoterapiStart_dt %||% NA)
  decision <- safe_as_date(lyfo$Reg_BehandlingBeslutning_dt %||% NA)
  primary <- !is.na(stem) |
    toupper(trimws(as.character(lyfo$Beh_Hoejdosisbehandling %||% ""))) == "Y" |
    toupper(trimws(as.character(lyfo$Beh_TypeAutologStamcellestoette %||% ""))) %in% c("BEAM", "OTHER", "BCNU-THIOTEPA", "BCNU", "BEAC")
  relapse <- !is.na(safe_as_date(lyfo$Rec_Stamcelleinfusion_dt %||% NA)) |
    toupper(trimws(as.character(lyfo$Rec_Hoejdosisbehandling %||% ""))) == "Y"
  reg_cols <- intersect(c("Beh_Kemoterapiregime1", "Beh_Kemoterapiregime2", "Beh_Kemoterapiregime3"), names(lyfo))
  reg_text <- if (length(reg_cols)) {
    apply(lyfo[reg_cols], 1, function(x) paste(toupper(trimws(as.character(x))), collapse = "\r"))
  } else {
    rep("", nrow(lyfo))
  }
  induction_values <- mcl_asct_induction_regimen_values()
  induction <- vapply(reg_text, function(value) {
    any(strsplit(value, "\r", fixed = TRUE)[[1]] %in% induction_values)
  }, logical(1))
  if ("induction_proxy" %in% names(lyfo)) induction <- induction | (lyfo$induction_proxy %in% TRUE)
  btk <- grepl("IBRUTINIB|ACALABRUTINIB|ZANUBRUTINIB", reg_text)
  if ("btk_exposure" %in% names(lyfo)) btk <- btk | (lyfo$btk_exposure %in% TRUE)

  med_person_col <- mcl_asct_first_column(medication_events, c("person_key", "patientid", "id"))
  med_code_col <- mcl_asct_first_column(medication_events, c("code_value", "atc", "c_atc", "atc5"))
  med_date_col <- mcl_asct_first_column(medication_events, c("event_date", "date", "d_adm", "d_ord_start", "taken_time", "order_start_time", "eksd"))
  med <- if (is.data.frame(medication_events) && nrow(medication_events) && nzchar(med_person_col) && nzchar(med_code_col) && nzchar(med_date_col)) {
    data.frame(
      person_key = as.character(medication_events[[med_person_col]]),
      code_value = toupper(trimws(as.character(medication_events[[med_code_col]]))),
      event_date = safe_as_date(medication_events[[med_date_col]]),
      stringsAsFactors = FALSE
    )
  } else {
    data.frame(person_key = character(), code_value = character(), event_date = as.Date(character()), stringsAsFactors = FALSE)
  }

  in_window <- function(p, codes, anchor, start, end) {
    if (is.na(anchor)) return(FALSE)
    rows <- med[med$person_key == p & med$code_value %in% codes & !is.na(med$event_date), , drop = FALSE]
    if (!nrow(rows)) return(FALSE)
    any(rows$event_date >= anchor + start & rows$event_date <= anchor + end)
  }
  mel_near <- vapply(seq_along(person), function(i) in_window(person[[i]], "L01AA03", stem[[i]], -45L, 7L), logical(1))
  mel_fl <- vapply(seq_along(person), function(i) in_window(person[[i]], "L01AA03", first_line[[i]], 60L, 240L), logical(1))
  component_near <- vapply(seq_along(person), function(i) in_window(person[[i]], c("L01AD01", "L01CB01", "L01BC01"), stem[[i]], -45L, 7L), logical(1))
  broad_anchor <- ifelse(!is.na(first_line), first_line, decision)
  broad_anchor <- as.Date(broad_anchor, origin = "1970-01-01")
  broad <- vapply(seq_along(person), function(i) in_window(person[[i]], c("L01AA03", "L01AD01", "L01CB01", "L01BC01"), broad_anchor[[i]], -30L, 240L), logical(1))
  data.frame(
    person_key = person,
    asct_hdt_primary_lyfo = primary,
    asct_hdt_relapse_recurrence_lyfo = relapse,
    melphalan_near_stem_cell_infusion = mel_near,
    melphalan_in_first_line_transplant_window = mel_fl,
    beam_multi_component_near_infusion = mel_near & component_near,
    broad_first_line_conditioning_support = broad,
    triangle_induction_cytarabine_platinum_proxy = induction,
    triangle_btk_exposure_any = btk,
    stringsAsFactors = FALSE
  )
}

mcl_asct_build_outputs <- function(project_root = ".",
                                   person_date_mapping = NULL,
                                   db_adapter = NULL,
                                   count_sets = NULL,
                                   source_resolution = NULL,
                                   ibrutinib_source_validation = NULL,
                                   treatment_code_mappings = NULL,
                                   min_cell_count = 5L) {
  sources <- mcl_asct_read_evidence_sources(project_root)
  if (is.null(person_date_mapping)) person_date_mapping <- mcl_count_read_person_date_mapping(project_root)
  if (is.null(source_resolution)) {
    source_resolution <- mcl_asct_source_resolution(sources, person_date_mapping, db_adapter = db_adapter, min_cell_count = min_cell_count)
  }
  if (is.list(count_sets) && length(count_sets)) {
    return(mcl_asct_outputs_from_sets(count_sets, source_resolution, min_cell_count))
  }
  if (mcl_count_db_adapter_available(db_adapter) && !is.function(db_adapter$mcl_triangle_count_sets)) {
    return(mcl_asct_outputs_from_db(
      person_date_mapping,
      sources,
      source_resolution,
      db_adapter,
      ibrutinib_source_validation = ibrutinib_source_validation,
      treatment_code_mappings = treatment_code_mappings,
      min_cell_count = min_cell_count
    ))
  }
  mcl_asct_outputs_from_flags(data.frame(stringsAsFactors = FALSE), source_resolution, min_cell_count)
}

mcl_asct_write_outputs <- function(outputs, output_dir) {
  list(
    asct_hdt_source_resolution = write_csv(outputs$asct_hdt_source_resolution %||% mcl_asct_empty_source_resolution(), file.path(output_dir, "mcl_triangle_asct_hdt_source_resolution.csv")),
    asct_hdt_primary_vs_conditioning_counts = write_csv(outputs$asct_hdt_primary_vs_conditioning_counts %||% mcl_asct_empty_primary_vs_conditioning_counts(), file.path(output_dir, "mcl_triangle_asct_hdt_primary_vs_conditioning_counts.csv")),
    asct_hdt_validation_matrix = write_csv(outputs$asct_hdt_validation_matrix %||% mcl_asct_empty_validation_matrix(), file.path(output_dir, "mcl_triangle_asct_hdt_validation_matrix.csv")),
    triangle_arm_proxy_counts = write_csv(outputs$triangle_arm_proxy_counts %||% mcl_asct_empty_triangle_arm_proxy_counts(), file.path(output_dir, "mcl_triangle_triangle_arm_proxy_counts.csv")),
    asct_hdt_evidence_timing = write_csv(outputs$asct_hdt_evidence_timing %||% mcl_asct_empty_evidence_timing(), file.path(output_dir, "mcl_triangle_asct_hdt_evidence_timing.csv")),
    asct_hdt_protocol_runway = write_csv(outputs$asct_hdt_protocol_runway %||% mcl_asct_empty_protocol_runway(), file.path(output_dir, "mcl_triangle_asct_hdt_protocol_runway.csv"))
  )
}
