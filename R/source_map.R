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
  source_map$profile_mode[source_map$profile_mode == "" | is.na(source_map$profile_mode)] <- "full"
  source_map$priority[is.na(source_map$priority)] <- seq_len(nrow(source_map))[is.na(source_map$priority)]
  source_map <- source_map[order(source_map$priority, source_map$table_name), , drop = FALSE]
  rownames(source_map) <- NULL
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

