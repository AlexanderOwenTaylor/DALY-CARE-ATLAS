read_source_map <- function(source_map_path, project_root = ".") {
  if (!file.exists(source_map_path)) {
    stop("Source map not found: ", source_map_path, call. = FALSE)
  }
  source_map <- read_delimited_file(source_map_path)
  validate_source_map(source_map)
  source_map$table_name <- trimws(as.character(source_map$table_name))
  source_map$source_type <- tolower(trimws(as.character(source_map$source_type)))
  source_map$source <- trimws(as.character(source_map$source))
  source_map$priority <- suppressWarnings(as.integer(source_map$priority))
  source_map$profile_mode <- tolower(trimws(as.character(source_map$profile_mode)))
  for (nm in intersect(source_map_optional_metadata(), names(source_map))) {
    source_map[[nm]] <- trimws(as.character(source_map[[nm]]))
  }
  source_map$profile_mode[source_map$profile_mode == "" | is.na(source_map$profile_mode)] <- "full"
  warnings <- source_map_warnings(source_map, project_root = project_root)
  source_map$profile_mode[!source_map$profile_mode %in% valid_profile_modes()] <- "full"
  source_map$priority[is.na(source_map$priority)] <- seq_len(nrow(source_map))[is.na(source_map$priority)]
  source_map <- source_map[order(source_map$priority, source_map$table_name), , drop = FALSE]
  rownames(source_map) <- NULL
  attr(source_map, "warnings") <- warnings
  source_map
}

validate_source_map <- function(source_map) {
  required <- c("table_name", "source_type", "source", "priority", "profile_mode")
  missing <- setdiff(required, names(source_map))
  if (length(missing)) {
    stop("Source map is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (!nrow(source_map)) {
    stop("Source map contains no rows.", call. = FALSE)
  }
  bad_type <- !tolower(source_map$source_type) %in% c("dataset", "file")
  if (any(bad_type, na.rm = TRUE)) {
    stop("Unsupported source_type values: ", paste(unique(source_map$source_type[bad_type]), collapse = ", "), call. = FALSE)
  }
  empty_required <- vapply(required[1:3], function(nm) any(is.na(source_map[[nm]]) | trimws(as.character(source_map[[nm]])) == ""), logical(1))
  if (any(empty_required)) {
    stop("Source map has blank values in: ", paste(names(empty_required)[empty_required], collapse = ", "), call. = FALSE)
  }
  invisible(TRUE)
}

valid_profile_modes <- function() {
  c("schema", "summary", "full")
}

source_map_optional_metadata <- function() {
  c(
    "domain", "subdomain", "atlas_role",
    "load_strategy", "db_name", "schema", "table", "chunk_size", "allow_full_load",
    "expected_resource_id", "display_name", "current_source_key", "preferred_schema",
    "preferred_table", "known_aliases", "resolver_type", "resolution_priority",
    "expected_availability", "legacy_resolution_method", "requires_direct_sql",
    "requires_manual_file", "requires_special_handling", "known_unavailable",
    "legacy_known_unavailable", "current_known_unavailable", "current_resolver_configured",
    "requires_production_validation", "regression_candidate",
    "source_key", "source_label", "canonical_resource_id", "source_map_role",
    "source_map_role_primary", "source_map_role_secondary", "table_or_view",
    "expected_in_current_run", "attempted_in_current_run", "profiled_in_current_run",
    "activation_status", "activation_priority"
  )
}

source_map_warnings <- function(source_map, project_root = ".") {
  rows <- list()
  add_warning <- function(table_name, warning_id, message) {
    rows[[length(rows) + 1L]] <<- data.frame(
      table_name = table_name %||% "",
      warning_id = warning_id,
      message = message,
      stringsAsFactors = FALSE
    )
  }

  duplicate_names <- unique(source_map$table_name[duplicated(source_map$table_name)])
  for (table_name in duplicate_names) {
    add_warning(table_name, "duplicate_table_name", paste("Source map contains duplicate table_name:", table_name))
  }

  bad_modes <- !source_map$profile_mode %in% valid_profile_modes()
  if (any(bad_modes, na.rm = TRUE)) {
    bad_values <- unique(source_map$profile_mode[bad_modes])
    for (mode in bad_values) {
      add_warning("", "unsupported_profile_mode", paste("Unsupported profile_mode will default to full:", mode))
    }
  }

  file_rows <- which(source_map$source_type == "file")
  for (i in file_rows) {
    source <- source_map$source[[i]]
    path <- if (file.exists(source)) source else file.path(project_root, source)
    if (!file.exists(path)) {
      add_warning(
        source_map$table_name[[i]],
        "missing_file_source",
        paste("File-backed source does not exist yet:", source)
      )
    }
  }

  out <- bind_rows_base(rows)
  if (!nrow(out)) {
    return(empty_df(table_name = character(), warning_id = character(), message = character()))
  }
  out
}
