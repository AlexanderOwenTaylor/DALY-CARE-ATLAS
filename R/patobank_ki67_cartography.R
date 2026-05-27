patobank_ki67_empty_validation <- function() {
  empty_df(
    validation_id = character(),
    label = character(),
    status = character(),
    count_display = character(),
    denominator_display = character(),
    percent_display = character(),
    rejection_reason = character(),
    source_table = character(),
    source_column = character(),
    key_columns_used = character(),
    notes = character()
  )
}

patobank_ki67_empty_summary <- function() {
  empty_df(
    metric_id = character(),
    label = character(),
    value_display = character(),
    denominator_display = character(),
    percent_display = character(),
    count_kind = character(),
    status = character(),
    source_scope = character(),
    notes = character()
  )
}

patobank_ki67_empty_code_counts <- function() {
  empty_df(
    canonical_code = character(),
    parsed_percent = integer(),
    aggregate_count_display = character(),
    count_status = character(),
    validation_status = character(),
    notes = character()
  )
}

patobank_ki67_empty_denominator_counts <- function() {
  empty_df(
    denominator_id = character(),
    label = character(),
    numerator_display = character(),
    denominator_display = character(),
    percent_display = character(),
    key_status = character(),
    key_columns_used = character(),
    count_status = character(),
    notes = character()
  )
}

patobank_ki67_empty_outputs <- function() {
  list(
    validation = patobank_ki67_empty_validation(),
    summary = patobank_ki67_empty_summary(),
    code_counts = patobank_ki67_empty_code_counts(),
    denominator_counts = patobank_ki67_empty_denominator_counts(),
    query_templates = character()
  )
}

patobank_ki67_fail_closed_outputs <- function(reason_id,
                                              label,
                                              notes,
                                              source_table = "SDS_pato",
                                              source_column = "c_snomedkode",
                                              query_templates = character()) {
  reason_id <- as.character(reason_id %||% "patobank_ki67_not_computed")
  label <- as.character(label %||% "PATOBANK Ki-67 cartography")
  notes <- as.character(notes %||% "PATOBANK Ki-67 cartography was not computed in this build.")
  denominator_counts <- data.frame(
    denominator_id = c("patient", "investigation", "specimen"),
    label = c(
      "PATOBANK patient coverage",
      "PATOBANK investigation/requisition coverage",
      "PATOBANK specimen/material coverage"
    ),
    numerator_display = "",
    denominator_display = "",
    percent_display = "",
    key_status = reason_id,
    key_columns_used = "",
    count_status = "failed_closed",
    notes = notes,
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_denominator_counts())]
  list(
    validation = data.frame(
      validation_id = reason_id,
      label = label,
      status = "failed_closed",
      count_display = "",
      denominator_display = "",
      percent_display = "",
      rejection_reason = "",
      source_table = source_table,
      source_column = source_column,
      key_columns_used = "",
      notes = notes,
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_validation())],
    summary = data.frame(
      metric_id = "patobank_ki67_status",
      label = "PATOBANK coded Ki-67 percent evidence coverage",
      value_display = "not computed in this build",
      denominator_display = "",
      percent_display = "",
      count_kind = "not production count",
      status = "failed_closed",
      source_scope = "PATOBANK/SDS_pato coded pathology",
      notes = notes,
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_summary())],
    code_counts = data.frame(
      canonical_code = reason_id,
      parsed_percent = NA_integer_,
      aggregate_count_display = "",
      count_status = "failed_closed",
      validation_status = reason_id,
      notes = notes,
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_code_counts())],
    denominator_counts = denominator_counts,
    query_templates = query_templates %||% character()
  )
}

patobank_ki67_no_valid_code_counts_row <- function(notes = "PATOBANK source was scanned but no valid AEKI/AEKI-normalized numeric Ki-67 percent codes were found.") {
  data.frame(
    canonical_code = "no_valid_aeki_codes_found",
    parsed_percent = NA_integer_,
    aggregate_count_display = "0",
    count_status = "failed_closed",
    validation_status = "no_valid_aeki_codes_found",
    notes = notes,
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_code_counts())]
}

patobank_ki67_required_components <- function() {
  c("validation", "summary", "code_counts", "denominator_counts")
}

patobank_ki67_validate_outputs <- function(outputs) {
  components <- patobank_ki67_required_components()
  rows <- lapply(components, function(component) {
    value <- outputs[[component]]
    n <- if (is.data.frame(value)) nrow(value) else 0L
    data.frame(
      component = component,
      n_rows = n,
      status = if (n > 0L) "ok" else "empty_output_error",
      notes = if (n > 0L) "" else "PATOBANK Ki-67 cartography failed: output file exists but contains no data rows and no fail-closed validation row.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

patobank_ki67_assert_outputs_valid <- function(outputs) {
  audit <- patobank_ki67_validate_outputs(outputs)
  bad <- audit[audit$status == "empty_output_error", , drop = FALSE]
  if (nrow(bad)) {
    stop(
      "PATOBANK Ki-67 cartography failed: output file exists but contains no data rows and no fail-closed validation row.",
      call. = FALSE
    )
  }
  invisible(audit)
}

patobank_ki67_validate_output_files <- function(output_dir) {
  required <- c(
    validation = "patobank_ki67_percent_validation.csv",
    summary = "patobank_ki67_percent_summary.csv",
    code_counts = "patobank_ki67_percent_code_counts.csv",
    denominator_counts = "patobank_ki67_percent_denominator_counts.csv"
  )
  rows <- lapply(names(required), function(component) {
    path <- file.path(output_dir, required[[component]])
    n <- if (file.exists(path)) {
      max(length(readLines(path, warn = FALSE, encoding = "UTF-8")) - 1L, 0L)
    } else {
      0L
    }
    data.frame(
      component = component,
      path = path,
      n_rows = n,
      status = if (n > 0L) "ok" else "empty_output_error",
      notes = if (n > 0L) "" else "PATOBANK Ki-67 cartography failed: output file exists but contains no data rows and no fail-closed validation row.",
      stringsAsFactors = FALSE
    )
  })
  bind_rows_base(rows)
}

patobank_ki67_mojibake_ae_variants <- function() {
  c(
    intToUtf8(c(0x00C3, 0x2020)),
    intToUtf8(c(0x00C3, 0x0192, 0x00E2, 0x20AC, 0x00A0)),
    intToUtf8(c(0x00C3, 0x0192, 0x00E2, 0x20AC, 0x00A0))
  )
}

patobank_ki67_normalize_code <- function(x) {
  out <- toupper(trimws(as.character(x %||% "")))
  out[is.na(out)] <- ""
  out <- gsub("\u00C6", "AE", out, fixed = TRUE)
  out <- gsub("\u00E6", "AE", out, fixed = TRUE)
  for (variant in patobank_ki67_mojibake_ae_variants()) {
    out <- gsub(variant, "AE", out, fixed = TRUE)
  }
  gsub("[^A-Z0-9]", "", out)
}

patobank_ki67_p16_codes <- function() {
  c("FY5015", "FY5016", "M0901K", "M0901L")
}

patobank_ki67_rejection_reason_levels <- function() {
  c(
    "percent_out_of_range",
    "qualitative_code",
    "p16_ki67_dual_stain_or_non_numeric",
    "malformed_encoding",
    "unmapped_candidate",
    "missing_code_value"
  )
}

patobank_ki67_parse_code <- function(x) {
  raw <- as.character(x %||% "")
  normalized <- patobank_ki67_normalize_code(raw)
  parsed <- rep(NA_integer_, length(normalized))
  reason <- rep("unmapped_candidate", length(normalized))
  is_blank <- !nzchar(trimws(raw)) | is.na(raw)
  reason[is_blank] <- "missing_code_value"
  p16 <- normalized %in% patobank_ki67_p16_codes()
  reason[p16] <- "p16_ki67_dual_stain_or_non_numeric"
  aeki_numeric <- grepl("^AEKI[0-9]{3}$", normalized)
  parsed[aeki_numeric] <- suppressWarnings(as.integer(sub("^AEKI", "", normalized[aeki_numeric])))
  reason[aeki_numeric & (is.na(parsed) | parsed < 0L | parsed > 100L)] <- "percent_out_of_range"
  reason[aeki_numeric & !is.na(parsed) & parsed >= 0L & parsed <= 100L] <- "valid_numeric_percent"
  malformed <- !aeki_numeric & grepl("^AEKI", normalized)
  reason[malformed] <- "malformed_encoding"
  qualitative <- !aeki_numeric & !p16 & grepl("KI67|MIB1|PROLIF", normalized)
  reason[qualitative] <- "qualitative_code"
  data.frame(
    raw_code = raw,
    canonical_code = ifelse(aeki_numeric, paste0("AEKI", sprintf("%03d", parsed)), normalized),
    parsed_percent = parsed,
    valid_numeric_percent = reason == "valid_numeric_percent",
    rejection_reason = ifelse(reason == "valid_numeric_percent", "", reason),
    stringsAsFactors = FALSE
  )
}

patobank_ki67_suppress_display <- function(n, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  if (is.na(n_num)) return("")
  if (n_num > 0 && n_num < min_cell_count) return(paste0("<", min_cell_count))
  format(n_num, scientific = FALSE, trim = TRUE)
}

patobank_ki67_percent_display <- function(n, denom, min_cell_count = 5L) {
  n_num <- suppressWarnings(as.numeric(n))
  d_num <- suppressWarnings(as.numeric(denom))
  if (is.na(n_num) || is.na(d_num) || d_num <= 0) return("")
  if (n_num > 0 && n_num < min_cell_count) {
    return(paste0("<", round(100 * min_cell_count / d_num, 1), "%"))
  }
  paste0(round(100 * n_num / d_num, 1), "%")
}

patobank_ki67_safe_key <- function(df, cols) {
  if (!length(cols) || !all(cols %in% names(df))) return(rep(NA_character_, nrow(df)))
  parts <- lapply(cols, function(col) {
    value <- trimws(as.character(df[[col]] %||% ""))
    value[is.na(value) | !nzchar(value)] <- NA_character_
    value
  })
  complete <- Reduce(`&`, lapply(parts, function(x) !is.na(x)))
  key <- rep(NA_character_, nrow(df))
  key[complete] <- do.call(paste, c(lapply(parts, `[`, complete), sep = "\r"))
  key
}

patobank_ki67_key_columns <- function(df) {
  patient <- intersect(c("patientid", "personid", "person_id", "patient_id"), names(df))
  investigation <- if ("k_rekvnr" %in% names(df)) {
    intersect(c("k_inst", "k_rekvnr"), names(df))
  } else {
    intersect(c("requisition_id", "rekvnr", "investigation_id"), names(df))
  }
  specimen_base <- intersect(c("k_matnr", "k_sekvensnr", "specimen_id", "material_id"), names(df))
  specimen <- if (length(specimen_base)) {
    unique(c(intersect(c("k_inst", "k_rekvnr"), names(df)), specimen_base))
  } else {
    character()
  }
  list(
    patient = if (length(patient)) patient[[1]] else character(),
    investigation = investigation,
    specimen = specimen
  )
}

patobank_ki67_denominator_row <- function(df, valid, denominator_id, label, key_cols, min_cell_count = 5L) {
  if (!length(key_cols)) {
    return(data.frame(
      denominator_id = denominator_id,
      label = label,
      numerator_display = "",
      denominator_display = "",
      percent_display = "",
      key_status = paste0(denominator_id, "_key_missing"),
      key_columns_used = "",
      count_status = paste0(denominator_id, "_denominator_unavailable_key_missing"),
      notes = "Stable denominator key unavailable; denominator was not guessed.",
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_denominator_counts())])
  }
  key <- patobank_ki67_safe_key(df, key_cols)
  available <- !is.na(key)
  denom <- length(unique(key[available]))
  numerator <- length(unique(key[available & valid]))
  data.frame(
    denominator_id = denominator_id,
    label = label,
    numerator_display = patobank_ki67_suppress_display(numerator, min_cell_count),
    denominator_display = patobank_ki67_suppress_display(denom, min_cell_count),
    percent_display = patobank_ki67_percent_display(numerator, denom, min_cell_count),
    key_status = "validated_aggregate_key_available",
    key_columns_used = paste(key_cols, collapse = "; "),
    count_status = if (denom > 0) "aggregate_count_available" else "denominator_empty",
    notes = "Aggregate deduplication used internal key values only; no key values are emitted.",
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_denominator_counts())]
}

patobank_ki67_outputs_from_frame <- function(df, source_table = "SDS_pato",
                                             source_column = "c_snomedkode",
                                             min_cell_count = 5L) {
  if (!is.data.frame(df) || !nrow(df)) {
    return(patobank_ki67_fail_closed_outputs(
      reason_id = "source_rows_not_available",
      label = "PATOBANK rows",
      notes = "No PATOBANK/SDS_pato rows were available to the cartography helper.",
      source_table = source_table,
      source_column = source_column
    ))
  }
  if (!source_column %in% names(df)) {
    return(patobank_ki67_fail_closed_outputs(
      reason_id = "required_code_column_missing",
      label = "Ki-67 code column",
      notes = "Required PATOBANK/SDS_pato code column is absent.",
      source_table = source_table,
      source_column = source_column
    ))
  }
  parsed <- patobank_ki67_parse_code(df[[source_column]])
  valid <- parsed$valid_numeric_percent %in% TRUE
  keys <- patobank_ki67_key_columns(df)
  denominator_counts <- bind_rows_base(list(
    patobank_ki67_denominator_row(df, valid, "patient", "PATOBANK patients with coded Ki-67 percent evidence", keys$patient, min_cell_count),
    patobank_ki67_denominator_row(df, valid, "investigation", "PATOBANK investigations/requisitions with coded Ki-67 percent evidence", keys$investigation, min_cell_count),
    patobank_ki67_denominator_row(df, valid, "specimen", "PATOBANK specimens/materials with coded Ki-67 percent evidence", keys$specimen, min_cell_count)
  ))
  if (any(valid)) {
    valid_df <- data.frame(
      canonical_code = parsed$canonical_code[valid],
      parsed_percent = parsed$parsed_percent[valid],
      stringsAsFactors = FALSE
    )
    grouped <- stats::aggregate(
      rep(1L, nrow(valid_df)),
      by = list(canonical_code = valid_df$canonical_code, parsed_percent = valid_df$parsed_percent),
      FUN = sum
    )
    names(grouped)[names(grouped) == "x"] <- "n"
    code_counts <- data.frame(
      canonical_code = grouped$canonical_code,
      parsed_percent = as.integer(grouped$parsed_percent),
      aggregate_count_display = vapply(grouped$n, patobank_ki67_suppress_display, character(1), min_cell_count = min_cell_count),
      count_status = "aggregate_count_available",
      validation_status = "valid_numeric_percent_code",
      notes = "Row-level aggregate valid AEKI percent-code count; no identifiers emitted.",
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_code_counts())]
    code_counts <- code_counts[order(code_counts$parsed_percent, code_counts$canonical_code), , drop = FALSE]
  } else {
    code_counts <- patobank_ki67_no_valid_code_counts_row()
  }
  reason_levels <- patobank_ki67_rejection_reason_levels()
  reason_count <- vapply(reason_levels, function(reason) sum(parsed$rejection_reason == reason, na.rm = TRUE), integer(1))
  validation_reasons <- data.frame(
    validation_id = paste0("rejected_", reason_levels),
    label = paste("Rejected candidate:", reason_levels),
    status = ifelse(reason_count > 0L, "rejected_candidate_observed", "no_rejected_candidate_observed"),
    count_display = vapply(reason_count, patobank_ki67_suppress_display, character(1), min_cell_count = min_cell_count),
    denominator_display = "",
    percent_display = "",
    rejection_reason = reason_levels,
    source_table = source_table,
    source_column = source_column,
    key_columns_used = "",
    notes = "Aggregate validation metadata only; not valid numeric Ki-67 percent evidence.",
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_validation())]
  key_validation <- lapply(seq_len(nrow(denominator_counts)), function(i) {
    row <- denominator_counts[i, , drop = FALSE]
    data.frame(
      validation_id = paste0(row$denominator_id[[1]], "_key"),
      label = paste(row$denominator_id[[1]], "deduplication key"),
      status = row$key_status[[1]],
      count_display = row$numerator_display[[1]],
      denominator_display = row$denominator_display[[1]],
      percent_display = row$percent_display[[1]],
      rejection_reason = "",
      source_table = source_table,
      source_column = source_column,
      key_columns_used = row$key_columns_used[[1]],
      notes = row$notes[[1]],
      stringsAsFactors = FALSE
    )
  })
  validation <- bind_rows_base(c(list(
    data.frame(
      validation_id = "source_relation",
      label = "PATOBANK/SDS_pato source rows",
      status = "source_rows_available",
      count_display = patobank_ki67_suppress_display(nrow(df), min_cell_count),
      denominator_display = "",
      percent_display = "",
      rejection_reason = "",
      source_table = source_table,
      source_column = source_column,
      key_columns_used = "",
      notes = "Input rows were aggregated in memory for test/fixture cartography; production uses aggregate SQL.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      validation_id = "valid_numeric_percent_rows",
      label = "Valid AEKI/AEKI-normalized Ki-67 percent code rows",
      status = if (sum(valid) > 0L) "valid_numeric_percent_evidence_found" else "valid_numeric_percent_evidence_not_found",
      count_display = patobank_ki67_suppress_display(sum(valid), min_cell_count),
      denominator_display = patobank_ki67_suppress_display(nrow(df), min_cell_count),
      percent_display = patobank_ki67_percent_display(sum(valid), nrow(df), min_cell_count),
      rejection_reason = "",
      source_table = source_table,
      source_column = source_column,
      key_columns_used = "",
      notes = "Valid Ki-67 percent codes are source-coverage evidence, not disease-specific biomarker completeness.",
      stringsAsFactors = FALSE
    )
  ), key_validation, list(validation_reasons)))
  patient <- denominator_counts[denominator_counts$denominator_id == "patient", , drop = FALSE]
  investigation <- denominator_counts[denominator_counts$denominator_id == "investigation", , drop = FALSE]
  specimen <- denominator_counts[denominator_counts$denominator_id == "specimen", , drop = FALSE]
  summary <- data.frame(
    metric_id = c("source_scope", "valid_code_rows", "patient_coverage", "investigation_coverage", "specimen_coverage"),
    label = c(
      "PATOBANK/SDS_pato source denominator",
      "Valid coded Ki-67 percent rows",
      "Patients with any coded Ki-67 percent evidence",
      "Investigations/requisitions with coded Ki-67 percent evidence",
      "Specimens/materials with coded Ki-67 percent evidence"
    ),
    value_display = c(
      "PATOBANK source coverage, not disease-specific completeness",
      patobank_ki67_suppress_display(sum(valid), min_cell_count),
      patient$numerator_display[[1]] %||% "",
      investigation$numerator_display[[1]] %||% "",
      specimen$numerator_display[[1]] %||% ""
    ),
    denominator_display = c(
      "",
      patobank_ki67_suppress_display(nrow(df), min_cell_count),
      patient$denominator_display[[1]] %||% "",
      investigation$denominator_display[[1]] %||% "",
      specimen$denominator_display[[1]] %||% ""
    ),
    percent_display = c(
      "",
      patobank_ki67_percent_display(sum(valid), nrow(df), min_cell_count),
      patient$percent_display[[1]] %||% "",
      investigation$percent_display[[1]] %||% "",
      specimen$percent_display[[1]] %||% ""
    ),
    count_kind = c("source scope", "aggregate evidence rows", "persons", "investigations", "specimens"),
    status = c(
      "source_coverage_cartography",
      if (sum(valid) > 0L) "valid_numeric_percent_evidence_found" else "valid_numeric_percent_evidence_not_found",
      patient$count_status[[1]] %||% "",
      investigation$count_status[[1]] %||% "",
      specimen$count_status[[1]] %||% ""
    ),
    source_scope = "PATOBANK/SDS_pato coded pathology",
    notes = c(
      "Denominator is PATOBANK/SDS_pato source coverage, not MCL, lymphoma, plasma cell disorder, CLL, treatment, or TRIANGLE eligibility completeness.",
      "Valid AEKI/AEKI-normalized code rows only; raw pathology text is not emitted.",
      patient$notes[[1]] %||% "",
      investigation$notes[[1]] %||% "",
      specimen$notes[[1]] %||% ""
    ),
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_summary())]
  list(
    validation = validation[names(patobank_ki67_empty_validation())],
    summary = summary,
    code_counts = code_counts,
    denominator_counts = denominator_counts,
    query_templates = patobank_ki67_query_templates_for_columns(
      schema = "public",
      table = source_table,
      source_column = source_column,
      key_columns = keys
    )
  )
}

patobank_ki67_sql_ident <- function(x) {
  paste0('"', gsub('"', '""', as.character(x %||% "")), '"')
}

patobank_ki67_sql_table <- function(schema, table) {
  paste(patobank_ki67_sql_ident(schema %||% "public"), patobank_ki67_sql_ident(table), sep = ".")
}

patobank_ki67_normalized_sql <- function(alias = "p", column = "c_snomedkode") {
  col <- paste0(alias, ".", patobank_ki67_sql_ident(column))
  paste0(
    "upper(regexp_replace(replace(replace(replace(", col, "::text, ",
    "'\u00C6', 'AE'), '", intToUtf8(c(0x00C3, 0x2020)), "', 'AE'), '",
    intToUtf8(c(0x00C3, 0x0192, 0x00E2, 0x20AC, 0x00A0)), "', 'AE'), ",
    "'[^A-Za-z0-9]', '', 'g'))"
  )
}

patobank_ki67_valid_predicate_sql <- function(norm_expr) {
  paste0("(", norm_expr, " ~ '^AEKI[0-9]{3}$' and substring(", norm_expr, " from 5 for 3)::integer between 0 and 100)")
}

patobank_ki67_code_counts_sql <- function(schema = "public", table = "SDS_pato", source_column = "c_snomedkode") {
  ref <- patobank_ki67_sql_table(schema, table)
  norm <- patobank_ki67_normalized_sql("p", source_column)
  paste0(
    "with coded as (\n",
    "  select ", norm, " as canonical_code\n",
    "  from ", ref, " p\n",
    "), valid_codes as (\n",
    "  select canonical_code, substring(canonical_code from 5 for 3)::integer as parsed_percent\n",
    "  from coded\n",
    "  where canonical_code ~ '^AEKI[0-9]{3}$'\n",
    "    and substring(canonical_code from 5 for 3)::integer between 0 and 100\n",
    ")\n",
    "select canonical_code, parsed_percent, count(*) as aggregate_count\n",
    "from valid_codes\n",
    "group by canonical_code, parsed_percent\n",
    "order by parsed_percent, canonical_code;"
  )
}

patobank_ki67_rejection_counts_sql <- function(schema = "public", table = "SDS_pato", source_column = "c_snomedkode") {
  ref <- patobank_ki67_sql_table(schema, table)
  norm <- patobank_ki67_normalized_sql("p", source_column)
  raw_col <- paste0("p.", patobank_ki67_sql_ident(source_column))
  p16_sql <- paste0("'", paste(patobank_ki67_p16_codes(), collapse = "', '"), "'")
  paste0(
    "with coded as (\n",
    "  select ", raw_col, "::text as raw_code, ", norm, " as canonical_code\n",
    "  from ", ref, " p\n",
    "), classified as (\n",
    "  select case\n",
    "    when raw_code is null or btrim(raw_code) = '' then 'missing_code_value'\n",
    "    when canonical_code in (", p16_sql, ") then 'p16_ki67_dual_stain_or_non_numeric'\n",
    "    when canonical_code ~ '^AEKI[0-9]{3}$' and substring(canonical_code from 5 for 3)::integer between 0 and 100 then 'valid_numeric_percent'\n",
    "    when canonical_code ~ '^AEKI[0-9]{3}$' then 'percent_out_of_range'\n",
    "    when canonical_code ~ '^AEKI' then 'malformed_encoding'\n",
    "    when canonical_code ~ '(KI67|MIB1|PROLIF)' then 'qualitative_code'\n",
    "    else 'unmapped_candidate'\n",
    "  end as rejection_reason\n",
    "  from coded\n",
    ")\n",
    "select rejection_reason, count(*) as aggregate_count\n",
    "from classified\n",
    "where rejection_reason <> 'valid_numeric_percent'\n",
    "group by rejection_reason\n",
    "order by rejection_reason;"
  )
}

patobank_ki67_denominator_sql <- function(schema = "public", table = "SDS_pato", source_column = "c_snomedkode",
                                          key_columns = character(), denominator_id = "patient") {
  if (!length(key_columns)) return("")
  ref <- patobank_ki67_sql_table(schema, table)
  norm <- patobank_ki67_normalized_sql("p", source_column)
  key_expr <- if (length(key_columns) == 1L) {
    paste0("nullif(trim(p.", patobank_ki67_sql_ident(key_columns[[1]]), "::text), '')")
  } else {
    paste0("concat_ws('|', ", paste(paste0("nullif(trim(p.", patobank_ki67_sql_ident(key_columns), "::text), '')"), collapse = ", "), ")")
  }
  key_not_null <- paste(paste0("p.", patobank_ki67_sql_ident(key_columns), " is not null"), collapse = " and ")
  valid <- patobank_ki67_valid_predicate_sql(norm)
  paste0(
    "select '", denominator_id, "' as denominator_id,\n",
    "       count(distinct ", key_expr, ") filter (where ", key_not_null, ") as denominator_count,\n",
    "       count(distinct ", key_expr, ") filter (where ", key_not_null, " and ", valid, ") as numerator_count\n",
    "from ", ref, " p;"
  )
}

patobank_ki67_query_templates_for_columns <- function(schema = "public", table = "SDS_pato",
                                                      source_column = "c_snomedkode",
                                                      key_columns = list(patient = character(), investigation = character(), specimen = character())) {
  parts <- c(
    "-- query_id: patobank_ki67_percent_code_counts\n-- Aggregate valid AEKI000-AEKI100 code counts; no identifiers, dates, text, snippets, or raw rows emitted.",
    patobank_ki67_code_counts_sql(schema, table, source_column),
    "-- query_id: patobank_ki67_rejected_candidate_counts\n-- Aggregate rejected Ki-67-like/pathology code validation metadata by reason; no identifiers, dates, text, snippets, or raw rows emitted.",
    patobank_ki67_rejection_counts_sql(schema, table, source_column)
  )
  for (denom in c("patient", "investigation", "specimen")) {
    cols <- key_columns[[denom]] %||% character()
    sql <- patobank_ki67_denominator_sql(schema, table, source_column, cols, denom)
    parts <- c(
      parts,
      paste0("-- query_id: patobank_ki67_", denom, "_coverage\n-- Aggregate ", denom, " denominator; key values are used only inside count(distinct ...) and are not emitted."),
      if (nzchar(sql)) sql else paste0("-- NOT EXECUTABLE: ", denom, " key unavailable")
    )
  }
  paste(parts, collapse = "\n\n")
}

patobank_ki67_source_location <- function(source_resolution = NULL, sources = NULL) {
  if (is.data.frame(source_resolution) && nrow(source_resolution)) {
    text_cols <- intersect(c("table_name", "source", "schema", "table", "resolved_table", "candidate_locations"), names(source_resolution))
    hay <- do.call(paste, c(lapply(text_cols, function(nm) as.character(source_resolution[[nm]])), sep = " "))
    hit <- grepl("SDS_pato|PATOBANK", hay, ignore.case = TRUE)
    if (any(hit)) {
      row <- source_resolution[which(hit)[[1]], , drop = FALSE]
      return(list(
        db_name = as.character((row$db_name %||% "")[[1]] %||% ""),
        schema = as.character((row$schema %||% "public")[[1]] %||% "public"),
        table = as.character((row$table %||% row$resolved_table %||% "SDS_pato")[[1]] %||% "SDS_pato")
      ))
    }
  }
  list(db_name = "", schema = "public", table = "SDS_pato")
}

patobank_ki67_columns_from_adapter <- function(db_adapter, db_name, schema, table) {
  if (!is.null(db_adapter) && is.function(db_adapter$table_schema)) {
    out <- tryCatch(db_adapter$table_schema(db_name, schema, table), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (is.data.frame(out) && nrow(out) && "column_name" %in% names(out)) return(as.character(out$column_name))
  }
  character()
}

patobank_ki67_query <- function(db_adapter, sql, db_name = "") {
  if (!is.null(db_adapter) && is.function(db_adapter$patobank_ki67_query)) {
    return(db_adapter$patobank_ki67_query(sql = sql, db_name = db_name))
  }
  if (!is.null(db_adapter) && is.list(db_adapter$connections) && length(db_adapter$connections) && requireNamespace("DBI", quietly = TRUE)) {
    conn <- if (nzchar(db_name) && db_name %in% names(db_adapter$connections)) db_adapter$connections[[db_name]] else db_adapter$connections[[1]]
    return(DBI::dbGetQuery(conn, sql))
  }
  stop("No PATOBANK Ki-67 aggregate query adapter is available.", call. = FALSE)
}

patobank_ki67_build_outputs <- function(project_root = ".", db_adapter = NULL, source_resolution = NULL,
                                        sources = NULL, min_cell_count = atlas_min_cell_count()) {
  if (!is.null(db_adapter) && is.data.frame(db_adapter$patobank_ki67_source_frame)) {
    return(patobank_ki67_outputs_from_frame(db_adapter$patobank_ki67_source_frame, min_cell_count = min_cell_count))
  }
  loc <- patobank_ki67_source_location(source_resolution = source_resolution, sources = sources)
  columns <- patobank_ki67_columns_from_adapter(db_adapter, loc$db_name, loc$schema, loc$table)
  if (!length(columns)) {
    return(patobank_ki67_fail_closed_outputs(
      reason_id = "source_relation_not_found",
      label = "PATOBANK/SDS_pato source relation",
      notes = "No queryable PATOBANK/SDS_pato relation was validated; output fails closed.",
      source_table = paste(loc$db_name, loc$schema, loc$table, sep = "."),
      source_column = "c_snomedkode",
      query_templates = patobank_ki67_query_templates_for_columns(loc$schema, loc$table, "c_snomedkode")
    ))
  }
  if (!"c_snomedkode" %in% columns) {
    return(patobank_ki67_fail_closed_outputs(
      reason_id = "required_code_column_missing",
      label = "PATOBANK Ki-67 code column",
      notes = "Required c_snomedkode column is absent; valid Ki-67 percent code coverage was not counted.",
      source_table = paste(loc$db_name, loc$schema, loc$table, sep = "."),
      source_column = "c_snomedkode"
    ))
  }
  key_columns <- patobank_ki67_key_columns(as.data.frame(stats::setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE))
  templates <- patobank_ki67_query_templates_for_columns(loc$schema, loc$table, "c_snomedkode", key_columns)
  code_counts_raw <- tryCatch(
    patobank_ki67_query(db_adapter, patobank_ki67_code_counts_sql(loc$schema, loc$table, "c_snomedkode"), loc$db_name),
    error = function(e) structure(data.frame(stringsAsFactors = FALSE), error_message = conditionMessage(e))
  )
  rejection_counts_raw <- tryCatch(
    patobank_ki67_query(db_adapter, patobank_ki67_rejection_counts_sql(loc$schema, loc$table, "c_snomedkode"), loc$db_name),
    error = function(e) structure(data.frame(stringsAsFactors = FALSE), error_message = conditionMessage(e))
  )
  if (is.data.frame(code_counts_raw) && nrow(code_counts_raw)) {
    code_counts <- data.frame(
      canonical_code = as.character(code_counts_raw$canonical_code %||% ""),
      parsed_percent = suppressWarnings(as.integer(code_counts_raw$parsed_percent %||% NA_integer_)),
      aggregate_count_display = vapply(code_counts_raw$aggregate_count %||% 0, patobank_ki67_suppress_display, character(1), min_cell_count = min_cell_count),
      count_status = "aggregate_count_available",
      validation_status = "valid_numeric_percent_code",
      notes = "Production aggregate valid AEKI percent-code count; no identifiers emitted.",
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_code_counts())]
  } else {
    code_status <- attr(code_counts_raw, "error_message", exact = TRUE)
    code_counts <- if (nzchar(code_status %||% "")) {
      data.frame(
        canonical_code = "aggregate_query_failed",
        parsed_percent = NA_integer_,
        aggregate_count_display = "",
        count_status = "failed_closed",
        validation_status = "aggregate_query_failed",
        notes = paste("Aggregate valid-code query failed; no identifiers emitted.", code_status),
        stringsAsFactors = FALSE
      )[names(patobank_ki67_empty_code_counts())]
    } else {
      patobank_ki67_no_valid_code_counts_row()
    }
  }
  denom_rows <- lapply(c("patient", "investigation", "specimen"), function(denom) {
    cols <- key_columns[[denom]] %||% character()
    if (!length(cols)) {
      return(patobank_ki67_denominator_row(data.frame(stringsAsFactors = FALSE), logical(), denom, paste("PATOBANK", denom, "coverage"), character(), min_cell_count))
    }
    sql <- patobank_ki67_denominator_sql(loc$schema, loc$table, "c_snomedkode", cols, denom)
    raw <- tryCatch(patobank_ki67_query(db_adapter, sql, loc$db_name), error = function(e) data.frame(stringsAsFactors = FALSE))
    if (!is.data.frame(raw) || !nrow(raw)) {
      return(data.frame(
        denominator_id = denom,
        label = paste("PATOBANK", denom, "coverage"),
        numerator_display = "",
        denominator_display = "",
        percent_display = "",
        key_status = "aggregate_query_failed",
        key_columns_used = paste(cols, collapse = "; "),
        count_status = "aggregate_query_failed",
        notes = "Aggregate denominator query failed; no key values emitted.",
        stringsAsFactors = FALSE
      )[names(patobank_ki67_empty_denominator_counts())])
    }
    n <- suppressWarnings(as.numeric(raw$numerator_count[[1]] %||% NA_real_))
    d <- suppressWarnings(as.numeric(raw$denominator_count[[1]] %||% NA_real_))
    data.frame(
      denominator_id = denom,
      label = paste("PATOBANK", denom, "coverage"),
      numerator_display = patobank_ki67_suppress_display(n, min_cell_count),
      denominator_display = patobank_ki67_suppress_display(d, min_cell_count),
      percent_display = patobank_ki67_percent_display(n, d, min_cell_count),
      key_status = "validated_aggregate_key_available",
      key_columns_used = paste(cols, collapse = "; "),
      count_status = "aggregate_count_available",
      notes = "Production aggregate count(distinct ...) output; no key values emitted.",
      stringsAsFactors = FALSE
    )[names(patobank_ki67_empty_denominator_counts())]
  })
  denominator_counts <- bind_rows_base(denom_rows)
  valid_total <- sum(suppressWarnings(as.numeric(gsub("^<", "", code_counts$aggregate_count_display %||% "0"))), na.rm = TRUE)
  reason_levels <- patobank_ki67_rejection_reason_levels()
  if (is.data.frame(rejection_counts_raw) && nrow(rejection_counts_raw) &&
      all(c("rejection_reason", "aggregate_count") %in% names(rejection_counts_raw))) {
    reason_counts <- stats::setNames(rep(0, length(reason_levels)), reason_levels)
    observed_reason <- as.character(rejection_counts_raw$rejection_reason)
    matched <- observed_reason %in% reason_levels
    reason_counts[observed_reason[matched]] <- suppressWarnings(as.numeric(rejection_counts_raw$aggregate_count[matched]))
  } else {
    reason_counts <- stats::setNames(rep(NA_real_, length(reason_levels)), reason_levels)
  }
  validation_reasons <- data.frame(
    validation_id = paste0("rejected_", reason_levels),
    label = paste("Rejected candidate:", reason_levels),
    status = ifelse(!is.na(reason_counts) & reason_counts > 0, "rejected_candidate_observed",
      ifelse(is.na(reason_counts), "rejected_candidate_query_unavailable", "no_rejected_candidate_observed")
    ),
    count_display = ifelse(
      is.na(reason_counts),
      "",
      vapply(reason_counts, patobank_ki67_suppress_display, character(1), min_cell_count = min_cell_count)
    ),
    denominator_display = "",
    percent_display = "",
    rejection_reason = reason_levels,
    source_table = paste(loc$db_name, loc$schema, loc$table, sep = "."),
    source_column = "c_snomedkode",
    key_columns_used = "",
    notes = "Aggregate validation metadata only; not valid numeric Ki-67 percent evidence.",
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_validation())]
  validation <- bind_rows_base(list(
    data.frame(
      validation_id = "source_relation",
      label = "PATOBANK/SDS_pato source relation",
      status = "source_relation_queryable",
      count_display = "",
      denominator_display = "",
      percent_display = "",
      rejection_reason = "",
      source_table = paste(loc$db_name, loc$schema, loc$table, sep = "."),
      source_column = "c_snomedkode",
      key_columns_used = "",
      notes = "Relation and c_snomedkode column were validated before aggregate counting.",
      stringsAsFactors = FALSE
    ),
    data.frame(
      validation_id = "valid_numeric_percent_rows",
      label = "Valid AEKI/AEKI-normalized Ki-67 percent code rows",
      status = if (nrow(code_counts)) "valid_numeric_percent_evidence_found" else "valid_numeric_percent_evidence_not_found",
      count_display = if (nrow(code_counts)) paste(unique(code_counts$aggregate_count_display), collapse = "; ") else "0",
      denominator_display = "",
      percent_display = "",
      rejection_reason = "",
      source_table = paste(loc$db_name, loc$schema, loc$table, sep = "."),
      source_column = "c_snomedkode",
      key_columns_used = "",
      notes = "Valid code rows are source-coverage evidence only.",
      stringsAsFactors = FALSE
    ),
    validation_reasons
  ))
  summary <- data.frame(
    metric_id = c("source_scope", "valid_code_rows", paste0(denominator_counts$denominator_id, "_coverage")),
    label = c(
      "PATOBANK/SDS_pato source denominator",
      "Valid coded Ki-67 percent rows",
      denominator_counts$label
    ),
    value_display = c(
      "PATOBANK source coverage, not disease-specific completeness",
      patobank_ki67_suppress_display(valid_total, min_cell_count),
      denominator_counts$numerator_display
    ),
    denominator_display = c("", "", denominator_counts$denominator_display),
    percent_display = c("", "", denominator_counts$percent_display),
    count_kind = c("source scope", "aggregate evidence rows", denominator_counts$denominator_id),
    status = c("source_coverage_cartography", if (nrow(code_counts)) "valid_numeric_percent_evidence_found" else "valid_numeric_percent_evidence_not_found", denominator_counts$count_status),
    source_scope = "PATOBANK/SDS_pato coded pathology",
    notes = c(
      "Denominator is PATOBANK/SDS_pato source coverage, not disease-specific clinical completeness.",
      "Valid AEKI/AEKI-normalized code rows only; raw pathology text is not emitted.",
      denominator_counts$notes
    ),
    stringsAsFactors = FALSE
  )[names(patobank_ki67_empty_summary())]
  list(
    validation = validation[names(patobank_ki67_empty_validation())],
    summary = summary,
    code_counts = code_counts,
    denominator_counts = denominator_counts,
    query_templates = templates
  )
}

patobank_ki67_write_outputs <- function(outputs, output_dir) {
  dir_create(output_dir)
  patobank_ki67_assert_outputs_valid(outputs)
  paths <- list(
    validation = write_csv(outputs$validation %||% patobank_ki67_empty_validation(), file.path(output_dir, "patobank_ki67_percent_validation.csv")),
    summary = write_csv(outputs$summary %||% patobank_ki67_empty_summary(), file.path(output_dir, "patobank_ki67_percent_summary.csv")),
    code_counts = write_csv(outputs$code_counts %||% patobank_ki67_empty_code_counts(), file.path(output_dir, "patobank_ki67_percent_code_counts.csv")),
    denominator_counts = write_csv(outputs$denominator_counts %||% patobank_ki67_empty_denominator_counts(), file.path(output_dir, "patobank_ki67_percent_denominator_counts.csv"))
  )
  query_path <- file.path(output_dir, "patobank_ki67_percent_query_templates.sql")
  writeLines(outputs$query_templates %||% character(), query_path, useBytes = TRUE)
  paths$query_templates <- query_path
  file_audit <- patobank_ki67_validate_output_files(output_dir)
  if (any(file_audit$status == "empty_output_error")) {
    stop(
      "PATOBANK Ki-67 cartography failed: output file exists but contains no data rows and no fail-closed validation row.",
      call. = FALSE
    )
  }
  paths
}

patobank_ki67_read_outputs <- function(output_dir) {
  read_or_empty <- function(name, empty) {
    path <- file.path(output_dir, name)
    if (file.exists(path)) read_delimited_file(path) else empty
  }
  list(
    validation = read_or_empty("patobank_ki67_percent_validation.csv", patobank_ki67_empty_validation()),
    summary = read_or_empty("patobank_ki67_percent_summary.csv", patobank_ki67_empty_summary()),
    code_counts = read_or_empty("patobank_ki67_percent_code_counts.csv", patobank_ki67_empty_code_counts()),
    denominator_counts = read_or_empty("patobank_ki67_percent_denominator_counts.csv", patobank_ki67_empty_denominator_counts()),
    query_templates = if (file.exists(file.path(output_dir, "patobank_ki67_percent_query_templates.sql"))) {
      paste(readLines(file.path(output_dir, "patobank_ki67_percent_query_templates.sql"), warn = FALSE), collapse = "\n")
    } else {
      ""
    }
  )
}
