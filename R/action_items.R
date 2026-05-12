empty_run_action_items <- function() {
  empty_df(
    severity = character(),
    category = character(),
    action_id = character(),
    table_name = character(),
    domain = character(),
    subdomain = character(),
    atlas_role = character(),
    reason = character(),
    current_behavior = character(),
    recommended_action = character(),
    evidence = character()
  )
}

access_report_has_ok <- function(access_report, check_id) {
  is.data.frame(access_report) &&
    nrow(access_report) > 0 &&
    "check_id" %in% names(access_report) &&
    "status" %in% names(access_report) &&
    any(access_report$check_id == check_id & access_report$status == "ok", na.rm = TRUE)
}

adjust_access_report_for_actual_impact <- function(access_report,
                                                   db_adapter = NULL,
                                                   memory_plan = NULL) {
  if (!is.data.frame(access_report) || nrow(access_report) == 0) {
    return(access_report)
  }
  if (!"check_id" %in% names(access_report) || !"status" %in% names(access_report)) {
    return(access_report)
  }
  bootstrap_failed <- access_report$check_id == "bootstrap_source_failed"
  if (!any(bootstrap_failed, na.rm = TRUE)) {
    return(access_report)
  }

  db_available <- !is.null(db_adapter) || access_report_has_ok(access_report, "db_adapter_available")
  fallback_needed <- is.data.frame(memory_plan) &&
    nrow(memory_plan) > 0 &&
    "chosen_strategy" %in% names(memory_plan) &&
    any(memory_plan$chosen_strategy == "dataset_full_load_fallback", na.rm = TRUE)

  if (db_available && !fallback_needed) {
    access_report$status[bootstrap_failed] <- "warning"
    if ("message" %in% names(access_report)) {
      impact_message <- "DB aggregate profiling succeeded; load_dataset fallback unavailable."
      access_report$message[bootstrap_failed] <- paste(
        unique(c(access_report$message[bootstrap_failed], impact_message)),
        collapse = " "
      )
    }
  } else {
    access_report$status[bootstrap_failed] <- "error"
  }
  access_report
}

source_context_row <- function(sources, table_name) {
  defaults <- list(domain = "", subdomain = "", atlas_role = "")
  if (!is.data.frame(sources) || nrow(sources) == 0 || !nzchar(table_name)) {
    return(defaults)
  }
  if (!"table_name" %in% names(sources)) {
    return(defaults)
  }
  idx <- which(sources$table_name == table_name)
  if (!length(idx)) {
    return(defaults)
  }
  row <- sources[idx[1], , drop = FALSE]
  list(
    domain = if ("domain" %in% names(row)) as.character(row$domain[[1]]) else "",
    subdomain = if ("subdomain" %in% names(row)) as.character(row$subdomain[[1]]) else "",
    atlas_role = if ("atlas_role" %in% names(row)) as.character(row$atlas_role[[1]]) else ""
  )
}

action_item_row <- function(severity,
                            category,
                            action_id,
                            table_name = "",
                            sources = NULL,
                            reason = "",
                            current_behavior = "",
                            recommended_action = "",
                            evidence = "") {
  ctx <- source_context_row(sources, table_name)
  data.frame(
    severity = severity,
    category = category,
    action_id = action_id,
    table_name = table_name,
    domain = ctx$domain %||% "",
    subdomain = ctx$subdomain %||% "",
    atlas_role = ctx$atlas_role %||% "",
    reason = reason,
    current_behavior = current_behavior,
    recommended_action = recommended_action,
    evidence = evidence,
    stringsAsFactors = FALSE
  )
}

memory_row_for_table <- function(memory_plan, table_name) {
  if (!is.data.frame(memory_plan) || nrow(memory_plan) == 0 || !"table_name" %in% names(memory_plan)) {
    return(data.frame())
  }
  memory_plan[memory_plan$table_name == table_name, , drop = FALSE][1, , drop = FALSE]
}

atlas_run_action_items <- function(access_report = NULL,
                                   source_resolution = NULL,
                                   memory_plan = NULL,
                                   sources = NULL,
                                   panels = NULL,
                                   checks = NULL) {
  items <- list()

  add_item <- function(row) {
    items[[length(items) + 1L]] <<- row
  }

  if (is.data.frame(access_report) &&
    nrow(access_report) > 0 &&
    all(c("check_id", "status") %in% names(access_report))) {
    bootstrap_rows <- access_report[access_report$check_id == "bootstrap_source_failed", , drop = FALSE]
    if (nrow(bootstrap_rows) > 0) {
      msg <- if ("message" %in% names(bootstrap_rows)) bootstrap_rows$message[[1]] else ""
      db_available <- access_report_has_ok(access_report, "db_adapter_available")
      fallback_needed <- is.data.frame(memory_plan) &&
        nrow(memory_plan) > 0 &&
        "chosen_strategy" %in% names(memory_plan) &&
        any(memory_plan$chosen_strategy == "dataset_full_load_fallback", na.rm = TRUE)
      if (db_available && !fallback_needed) {
        add_item(action_item_row(
          severity = "warning",
          category = "Access",
          action_id = "bootstrap_fallback_unavailable",
          reason = msg,
          current_behavior = "DB aggregate profiling proceeded; load_dataset fallback is unavailable.",
          recommended_action = "No action is required for DB aggregate atlas runs. Repair the bootstrap path only if a source must use load_dataset fallback.",
          evidence = "bootstrap_source_failed;db_adapter_available"
        ))
      } else {
        add_item(action_item_row(
          severity = "error",
          category = "Access",
          action_id = "bootstrap_blocking",
          reason = msg,
          current_behavior = "The DALY bootstrap failed before a safe fallback path was available.",
          recommended_action = "Check DALYCARE_BOOTSTRAP_PATH and the NGC DALY loader installation, then rerun the atlas.",
          evidence = "bootstrap_source_failed"
        ))
      }
    }
  }

  if (is.data.frame(source_resolution) &&
    nrow(source_resolution) > 0 &&
    "resolution_status" %in% names(source_resolution)) {
    for (i in seq_len(nrow(source_resolution))) {
      row <- source_resolution[i, , drop = FALSE]
      status <- as.character(row$resolution_status[[1]])
      table_name <- if ("table_name" %in% names(row)) as.character(row$table_name[[1]]) else ""
      if (identical(status, "ambiguous")) {
        add_item(action_item_row(
          severity = "warning",
          category = "Source resolution",
          action_id = "ambiguous_source",
          table_name = table_name,
          sources = sources,
          reason = if ("message" %in% names(row)) as.character(row$message[[1]]) else "Multiple DB tables matched this source.",
          current_behavior = "The source was skipped until the atlas can choose a single DB table safely.",
          recommended_action = "Set db_name, schema, and table explicitly in config/source-map.dalycare.tsv for this source.",
          evidence = paste(
            c(
              if ("candidate_locations" %in% names(row)) paste0("candidates=", row$candidate_locations[[1]]) else "",
              if ("candidate_row_counts" %in% names(row)) paste0("row_counts=", row$candidate_row_counts[[1]]) else ""
            ),
            collapse = "; "
          )
        ))
      } else if (identical(status, "missing")) {
        recommendation <- if (grepl("^view_", table_name, ignore.case = TRUE)) {
          "Confirm that this DALY view exists in the live database, or update the source map to the current view/table name."
        } else {
          "Update the source map with the current DB table name, or remove this source if it is no longer part of the DALY contract."
        }
        add_item(action_item_row(
          severity = "warning",
          category = "Source resolution",
          action_id = "missing_source",
          table_name = table_name,
          sources = sources,
          reason = if ("message" %in% names(row)) as.character(row$message[[1]]) else "No DB catalog match was found.",
          current_behavior = "The source was not profiled because it was absent from the live DB catalog.",
          recommended_action = recommendation,
          evidence = paste(
            c(
              if ("suggestion" %in% names(row)) paste0("suggestion=", row$suggestion[[1]]) else "",
              if ("candidate_locations" %in% names(row)) paste0("nearest=", row$candidate_locations[[1]]) else ""
            ),
            collapse = "; "
          )
        ))
      }
    }
  }

  if (is.data.frame(memory_plan) &&
    nrow(memory_plan) > 0 &&
    "chosen_strategy" %in% names(memory_plan)) {
    risky <- memory_plan[memory_plan$chosen_strategy == "skipped_risky_full_load", , drop = FALSE]
    for (i in seq_len(nrow(risky))) {
      row <- risky[i, , drop = FALSE]
      table_name <- if ("table_name" %in% names(row)) as.character(row$table_name[[1]]) else ""
      resolution_status <- if ("resolution_status" %in% names(row)) as.character(row$resolution_status[[1]]) else ""
      recommended <- switch(
        resolution_status,
        ambiguous = "Resolve the ambiguous source map entry by setting db_name, schema, and table explicitly.",
        missing = "Fix the source map table/view name or confirm the source is absent from this live catalog.",
        db_unavailable = "Repair DB access before rerunning; avoid forcing a full-table load for large DALY sources.",
        "Only set allow_full_load=TRUE for this source after confirming it is small enough to load safely."
      )
      add_item(action_item_row(
        severity = "warning",
        category = "Memory guardrail",
        action_id = "skipped_risky_full_load",
        table_name = table_name,
        sources = sources,
        reason = if ("reason" %in% names(row)) as.character(row$reason[[1]]) else "Full-table loading was blocked by memory guardrails.",
        current_behavior = "The atlas skipped this source instead of risking a large load into R memory.",
        recommended_action = recommended,
        evidence = paste(
          c(
            if ("row_count" %in% names(row)) paste0("row_count=", row$row_count[[1]]) else "",
            if ("max_full_load_rows" %in% names(row)) paste0("max_full_load_rows=", row$max_full_load_rows[[1]]) else "",
            paste0("resolution_status=", resolution_status)
          ),
          collapse = "; "
        )
      ))
    }
  }

  temporal <- panels$atlas_temporal_coverage
  if (is.data.frame(temporal) && nrow(temporal) > 0 && "date_qc" %in% names(temporal)) {
    flagged <- temporal[temporal$date_qc %in% c("clamped_display_range", "missing_date_range"), , drop = FALSE]
    for (i in seq_len(nrow(flagged))) {
      row <- flagged[i, , drop = FALSE]
      table_name <- if ("table_name" %in% names(row)) as.character(row$table_name[[1]]) else ""
      qc <- as.character(row$date_qc[[1]])
      if (identical(qc, "clamped_display_range")) {
        add_item(action_item_row(
          severity = "warning",
          category = "Temporal coverage",
          action_id = "clamped_date_range",
          table_name = table_name,
          sources = sources,
          reason = "Raw date range extends outside the display-year guardrails.",
          current_behavior = "The atlas preserved raw min/max dates for audit and clamped the displayed years.",
          recommended_action = "Inspect the source date column for sentinel dates or invalid future/past values if this range looks unexpected.",
          evidence = paste(
            c(
              if ("date_column" %in% names(row)) paste0("date_column=", row$date_column[[1]]) else "",
              if ("raw_min_date" %in% names(row)) paste0("raw_min=", row$raw_min_date[[1]]) else "",
              if ("raw_max_date" %in% names(row)) paste0("raw_max=", row$raw_max_date[[1]]) else ""
            ),
            collapse = "; "
          )
        ))
      } else if (identical(qc, "missing_date_range")) {
        add_item(action_item_row(
          severity = "info",
          category = "Temporal coverage",
          action_id = "missing_date_range",
          table_name = table_name,
          sources = sources,
          reason = "No coverage-ready date column was available for this source.",
          current_behavior = "The atlas profiled the source but did not add source-year coverage rows.",
          recommended_action = "Add a date-column alias if this source has a meaningful event, diagnosis, treatment, or contact date.",
          evidence = if ("coverage_basis" %in% names(row)) paste0("coverage_basis=", row$coverage_basis[[1]]) else ""
        ))
      }
    }
  }

  if (!length(items)) {
    return(empty_run_action_items())
  }
  out <- bind_rows_base(items)
  severity_rank <- c(error = 1L, warning = 2L, info = 3L, ok = 4L)
  ranks <- severity_rank[out$severity]
  ranks[is.na(ranks)] <- 99L
  out[order(ranks, out$category, out$table_name, out$action_id), , drop = FALSE]
}

db_budget_actions_as_run_action_items <- function(db_budget_actions, sources = NULL) {
  if (!is.data.frame(db_budget_actions) || !nrow(db_budget_actions)) return(empty_run_action_items())
  rows <- lapply(seq_len(nrow(db_budget_actions)), function(i) {
    row <- db_budget_actions[i, , drop = FALSE]
    action_item_row(
      severity = row$severity[[1]] %||% "warning",
      category = row$category[[1]] %||% "DB budget",
      action_id = row$action_id[[1]] %||% "db_budget_action",
      table_name = row$table_name[[1]] %||% "",
      sources = sources,
      reason = row$reason[[1]] %||% "",
      current_behavior = row$current_behavior[[1]] %||% "",
      recommended_action = row$recommended_action[[1]] %||% "",
      evidence = paste(
        c(
          if ("column_name" %in% names(row)) paste0("column=", row$column_name[[1]]) else "",
          if ("query_category" %in% names(row)) paste0("query_category=", row$query_category[[1]]) else "",
          if ("estimated_rows" %in% names(row)) paste0("estimated_rows=", row$estimated_rows[[1]]) else ""
        ),
        collapse = "; "
      )
    )
  })
  out <- bind_rows_base(rows)
  if (!nrow(out)) return(empty_run_action_items())
  severity_rank <- c(error = 1L, warning = 2L, info = 3L, ok = 4L)
  ranks <- severity_rank[out$severity]
  ranks[is.na(ranks)] <- 99L
  out[order(ranks, out$category, out$table_name, out$action_id), , drop = FALSE]
}

action_item_summary <- function(action_items) {
  if (!is.data.frame(action_items) || nrow(action_items) == 0) {
    return(empty_df(severity = character(), category = character(), n_items = integer()))
  }
  rows <- split(action_items, paste(action_items$severity, action_items$category, sep = "\r"))
  out <- lapply(rows, function(x) {
    data.frame(
      severity = x$severity[[1]],
      category = x$category[[1]],
      n_items = nrow(x),
      stringsAsFactors = FALSE
    )
  })
  out <- bind_rows_base(out)
  severity_rank <- c(error = 1L, warning = 2L, info = 3L, ok = 4L)
  ranks <- severity_rank[out$severity]
  ranks[is.na(ranks)] <- 99L
  out[order(ranks, out$category), , drop = FALSE]
}
