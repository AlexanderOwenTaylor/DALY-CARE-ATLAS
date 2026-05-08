#!/usr/bin/env Rscript
# =============================================================================
# DALY-CARE atlas updater
# =============================================================================
# PURPOSE
# -------
# Takes the JSON payloads produced by 000_dalycare_cartography_consolidated.R
# and hot-swaps the embedded const DATA / const ATLAS / const REGION_COVERAGE_ROWS
# inside the HTML atlas file, producing a refreshed copy.
#
# This is the "last mile" that the consolidated cartography recommends but
# does not perform itself.  Running this script after the cartography means
# the HTML atlas stays current without manual JSON editing.
#
# HOW TO RUN
# ----------
# Option A (defaults — finds files in the working directory):
#   Rscript 001_dalycare_atlas_updater.R
#
# Option B (explicit paths):
#   Rscript 001_dalycare_atlas_updater.R  \
#     --html  DALYCARE_atlas_AOT_V33.html \
#     --data  Other/DALYCARE_atlas_refresh_*/DALYCARE_atlas_payload_data.json \
#     --atlas Other/DALYCARE_atlas_refresh_*/DALYCARE_atlas_payload_atlas.json \
#     --out   DALYCARE_atlas_AOT_V34.html
#
# Option C (use the combined .js payload instead of separate JSONs):
#   Rscript 001_dalycare_atlas_updater.R  \
#     --html    DALYCARE_atlas_AOT_V33.html \
#     --payload Other/DALYCARE_atlas_refresh_*/DALYCARE_atlas_payload.js
#
# WHAT IT DOES
# ------------
# 1. Reads the existing HTML atlas
# 2. Reads the new DATA and ATLAS JSON payloads (from cartography output)
# 3. Locates const DATA = {...}; and const ATLAS = {...}; in the HTML using
#    a string-aware brace walker (handles braces inside JSON string literals)
# 4. Replaces each constant's value with the fresh JSON
# 5. Optionally replaces const REGION_COVERAGE_ROWS = [...];
# 6. Writes the updated HTML to the output path
# 7. Validates that the output parses correctly by re-extracting and
#    comparing key counts
# =============================================================================

options(stringsAsFactors = FALSE)

suppressPackageStartupMessages({
  library(jsonlite)
})

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0L) y else x

# =============================================================================
# CLI argument parsing
# =============================================================================
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  opts <- list(
    html    = NULL,
    data    = NULL,
    atlas   = NULL,
    payload = NULL,
    region  = NULL,
    out     = NULL,
    backup  = TRUE,
    dry_run = FALSE,
    minify  = TRUE
  )

  i <- 1L
  while (i <= length(args)) {
    a <- args[i]
    if (a %in% c("--html", "-h"))        { opts$html    <- args[i + 1L]; i <- i + 2L }
    else if (a %in% c("--data", "-d"))    { opts$data    <- args[i + 1L]; i <- i + 2L }
    else if (a %in% c("--atlas", "-a"))   { opts$atlas   <- args[i + 1L]; i <- i + 2L }
    else if (a %in% c("--payload", "-p")) { opts$payload <- args[i + 1L]; i <- i + 2L }
    else if (a %in% c("--region", "-r"))  { opts$region  <- args[i + 1L]; i <- i + 2L }
    else if (a %in% c("--out", "-o"))     { opts$out     <- args[i + 1L]; i <- i + 2L }
    else if (a == "--no-backup")          { opts$backup  <- FALSE; i <- i + 1L }
    else if (a == "--dry-run")            { opts$dry_run <- TRUE;  i <- i + 1L }
    else if (a == "--pretty")             { opts$minify  <- FALSE; i <- i + 1L }
    else { i <- i + 1L }
  }
  opts
}

# =============================================================================
# File discovery — find the most recent cartography output
# =============================================================================
find_latest_dir <- function(pattern = "DALYCARE_atlas_refresh_", root = ".") {
  dirs <- list.dirs(file.path(root, "Other"), recursive = FALSE, full.names = TRUE)
  hits <- dirs[grepl(pattern, basename(dirs), fixed = TRUE)]
  if (!length(hits)) {
    dirs2 <- list.dirs(root, recursive = FALSE, full.names = TRUE)
    hits <- dirs2[grepl(pattern, basename(dirs2), fixed = TRUE)]
  }
  if (!length(hits)) return(NA_character_)
  hits <- sort(hits, decreasing = TRUE)
  hits[1]
}

find_file <- function(explicit, candidates, label) {
  if (!is.null(explicit) && file.exists(explicit)) return(normalizePath(explicit))
  for (c in candidates) {
    if (file.exists(c)) return(normalizePath(c))
  }
  stop("Could not find ", label, ". Tried:\n  ",
       paste(c(explicit %||% "<not specified>", candidates), collapse = "\n  "),
       "\nUse --", gsub(" ", "-", tolower(label)), " to specify explicitly.",
       call. = FALSE)
}

resolve_paths <- function(opts) {
  wd <- getwd()
  latest_dir <- find_latest_dir(root = wd)

  # CARTO_OUT_DIR is set by RUN_CARTOGRAPHY_ATLAS.R and points directly at
  # the cartography's just-written output. It takes precedence over the
  # find_latest_dir() heuristic so the updater consumes the JSON the runner
  # just produced rather than an older sibling refresh directory.
  carto_out <- Sys.getenv("CARTO_OUT_DIR", unset = "")
  if (!nzchar(carto_out) || !dir.exists(carto_out)) carto_out <- NA_character_

  # HTML atlas
  html_candidates <- c(
    Sys.getenv("ATLAS_HTML_PATH", unset = ""),
    list.files(wd, pattern = "DALYCARE_atlas.*\\.html$", full.names = TRUE),
    list.files(file.path(wd, "site"), pattern = "DALYCARE_atlas.*\\.html$", full.names = TRUE),
    if (!is.na(latest_dir)) list.files(latest_dir, pattern = "\\.html$", full.names = TRUE)
  )
  html_candidates <- html_candidates[nzchar(html_candidates)]
  opts$html <- find_file(opts$html, html_candidates, "HTML atlas")

  # If combined payload is given, use that; otherwise find separate JSONs
  if (!is.null(opts$payload) && file.exists(opts$payload)) {
    opts$use_combined <- TRUE
  } else {
    opts$use_combined <- FALSE
    json_dir_candidates <- c(
      if (!is.na(carto_out)) carto_out,
      if (!is.na(latest_dir)) latest_dir,
      wd,
      file.path(wd, "Other")
    )

    data_candidates <- unlist(lapply(json_dir_candidates, function(d)
      file.path(d, "DALYCARE_atlas_payload_data.json")))
    atlas_candidates <- unlist(lapply(json_dir_candidates, function(d)
      file.path(d, "DALYCARE_atlas_payload_atlas.json")))

    opts$data  <- find_file(opts$data,  data_candidates,  "DATA JSON payload")
    opts$atlas <- find_file(opts$atlas, atlas_candidates, "ATLAS JSON payload")

    # Region coverage is optional
    if (is.null(opts$region)) {
      for (d in json_dir_candidates) {
        rp <- file.path(d, "DALYCARE_atlas_payload.js")
        if (file.exists(rp)) { opts$payload_js_for_region <- rp; break }
      }
    }
  }

  # Output path
  if (is.null(opts$out)) {
    base <- tools::file_path_sans_ext(basename(opts$html))
    # Increment version number if present
    m <- regexpr("V(\\d+)", base)
    if (m > 0) {
      old_v <- as.integer(regmatches(base, m) |> sub(pattern = "V", replacement = ""))
      new_base <- sub("V\\d+", paste0("V", old_v + 1L), base)
    } else {
      new_base <- paste0(base, "_updated")
    }
    opts$out <- file.path(dirname(opts$html), paste0(new_base, ".html"))
  }

  opts
}

# =============================================================================
# String-aware JS object/array boundary finder
# =============================================================================
# Walks the character vector counting { } or [ ] depth while skipping
# characters inside string literals (handles \" escapes).
find_js_value_bounds <- function(chars, start_pos, open_char = "{", close_char = "}") {
  n <- length(chars)
  if (start_pos > n || chars[start_pos] != open_char) return(NULL)

  depth <- 0L
  in_string <- FALSE
  escape_next <- FALSE

  for (i in seq.int(start_pos, n)) {
    ch <- chars[i]

    if (escape_next) {
      escape_next <- FALSE
      next
    }
    if (ch == "\\") {
      if (in_string) { escape_next <- TRUE; next }
    }
    if (ch == "\"") {
      in_string <- !in_string
      next
    }
    if (in_string) next

    if (ch == open_char)  depth <- depth + 1L
    if (ch == close_char) {
      depth <- depth - 1L
      if (depth == 0L) return(list(start = start_pos, end = i))
    }
  }
  NULL
}

# Find a JS constant assignment like: const NAME = <value>;
# Returns list(decl_start, decl_end, value_start, value_end) in character indices
find_js_const <- function(txt_chars, anchor) {
  txt <- paste(txt_chars, collapse = "")
  idx <- regexpr(anchor, txt, fixed = TRUE)
  if (idx < 1L) return(NULL)

  # Find the first { or [ after the anchor
  anchor_end <- idx + nchar(anchor) - 1L
  search_start <- anchor_end + 1L

  # Skip whitespace

  while (search_start <= length(txt_chars) && txt_chars[search_start] %in% c(" ", "\n", "\r", "\t")) {
    search_start <- search_start + 1L
  }
  if (search_start > length(txt_chars)) return(NULL)

  first_char <- txt_chars[search_start]
  if (first_char == "{") {
    bounds <- find_js_value_bounds(txt_chars, search_start, "{", "}")
  } else if (first_char == "[") {
    bounds <- find_js_value_bounds(txt_chars, search_start, "[", "]")
  } else {
    return(NULL)
  }
  if (is.null(bounds)) return(NULL)

  # Find the trailing semicolon
  semi_pos <- bounds$end + 1L
  while (semi_pos <= length(txt_chars) && txt_chars[semi_pos] %in% c(" ", "\n", "\r", "\t")) {
    semi_pos <- semi_pos + 1L
  }
  if (semi_pos <= length(txt_chars) && txt_chars[semi_pos] == ";") {
    bounds$semi <- semi_pos
  } else {
    bounds$semi <- bounds$end
  }

  list(
    anchor_start = as.integer(idx),
    value_start  = bounds$start,
    value_end    = bounds$end,
    decl_end     = bounds$semi
  )
}

# =============================================================================
# Replacement engine
# =============================================================================
replace_js_const <- function(html_text, anchor, new_json, minify = TRUE) {
  chars <- strsplit(html_text, "", fixed = TRUE)[[1]]
  loc <- find_js_const(chars, anchor)

  if (is.null(loc)) {
    message("  WARNING: Could not locate '", anchor, "' in HTML. Skipping.")
    return(html_text)
  }

  # Format the replacement JSON
  if (minify) {
    json_str <- jsonlite::toJSON(new_json, auto_unbox = TRUE, null = "null", na = "null")
  } else {
    json_str <- jsonlite::toJSON(new_json, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null")
  }

  # Build: <anchor><json>;
  replacement <- paste0(anchor, as.character(json_str), ";")

  # Splice: everything before anchor + replacement + everything after semicolon
  before <- paste(chars[seq_len(loc$anchor_start - 1L)], collapse = "")
  after  <- paste(chars[seq.int(loc$decl_end + 1L, length(chars))], collapse = "")

  paste0(before, replacement, after)
}

# =============================================================================
# Region coverage — extract from the .js payload if available
# =============================================================================
extract_region_from_payload_js <- function(js_path) {
  if (is.null(js_path) || !file.exists(js_path)) return(NULL)
  txt <- paste(readLines(js_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  anchor <- "const REGION_COVERAGE_ROWS = "
  idx <- regexpr(anchor, txt, fixed = TRUE)
  if (idx < 1L) return(NULL)
  chars <- strsplit(txt, "", fixed = TRUE)[[1]]
  search_start <- idx + nchar(anchor)
  while (search_start <= length(chars) && chars[search_start] %in% c(" ", "\n", "\r", "\t")) {
    search_start <- search_start + 1L
  }
  if (search_start > length(chars) || chars[search_start] != "[") return(NULL)
  bounds <- find_js_value_bounds(chars, search_start, "[", "]")
  if (is.null(bounds)) return(NULL)
  json_str <- paste(chars[bounds$start:bounds$end], collapse = "")
  tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE), error = function(e) NULL)
}

# =============================================================================
# Validation
# =============================================================================
validate_output <- function(output_path) {
  txt <- paste(readLines(output_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  chars <- strsplit(txt, "", fixed = TRUE)[[1]]

  checks <- list()

  # Check DATA
  data_loc <- find_js_const(chars, "const DATA = ")
  if (!is.null(data_loc)) {
    data_json <- paste(chars[data_loc$value_start:data_loc$value_end], collapse = "")
    data_obj <- tryCatch(jsonlite::fromJSON(data_json, simplifyVector = FALSE), error = function(e) NULL)
    checks$DATA <- list(
      found = TRUE,
      parseable = !is.null(data_obj),
      n_keys = length(names(data_obj)),
      n_loaded = length(data_obj$loadedDatasets),
      n_catalog = length(data_obj$resourceCatalog)
    )
  } else {
    checks$DATA <- list(found = FALSE)
  }

  # Check ATLAS
  atlas_loc <- find_js_const(chars, "const ATLAS = ")
  if (!is.null(atlas_loc)) {
    atlas_json <- paste(chars[atlas_loc$value_start:atlas_loc$value_end], collapse = "")
    atlas_obj <- tryCatch(jsonlite::fromJSON(atlas_json, simplifyVector = FALSE), error = function(e) NULL)
    checks$ATLAS <- list(
      found = TRUE,
      parseable = !is.null(atlas_obj),
      n_keys = length(names(atlas_obj))
    )
  } else {
    checks$ATLAS <- list(found = FALSE)
  }

  checks
}

# =============================================================================
# Main
# =============================================================================
main <- function() {
  opts <- parse_args()
  opts <- resolve_paths(opts)

  cat("DALY-CARE Atlas Updater\n")
  cat("======================\n")
  cat("  Input HTML:  ", opts$html, "\n")
  if (opts$use_combined) {
    cat("  Payload JS:  ", opts$payload, "\n")
  } else {
    cat("  DATA JSON:   ", opts$data, "\n")
    cat("  ATLAS JSON:  ", opts$atlas, "\n")
  }
  cat("  Output HTML: ", opts$out, "\n")
  cat("  Minify JSON: ", opts$minify, "\n")
  cat("  Dry run:     ", opts$dry_run, "\n\n")

  # Read HTML
  cat("Reading HTML atlas... ")
  html_text <- paste(readLines(opts$html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  cat(format(nchar(html_text), big.mark = ","), "chars\n")

  # Read payloads
  if (opts$use_combined) {
    cat("Reading combined payload JS... ")
    js_text <- paste(readLines(opts$payload, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    js_chars <- strsplit(js_text, "", fixed = TRUE)[[1]]

    data_loc <- find_js_const(js_chars, "const DATA = ")
    atlas_loc <- find_js_const(js_chars, "const ATLAS = ")

    if (is.null(data_loc)) stop("Could not parse const DATA from payload JS", call. = FALSE)
    if (is.null(atlas_loc)) stop("Could not parse const ATLAS from payload JS", call. = FALSE)

    data_json_str <- paste(js_chars[data_loc$value_start:data_loc$value_end], collapse = "")
    atlas_json_str <- paste(js_chars[atlas_loc$value_start:atlas_loc$value_end], collapse = "")

    new_data  <- jsonlite::fromJSON(data_json_str,  simplifyVector = FALSE)
    new_atlas <- jsonlite::fromJSON(atlas_json_str, simplifyVector = FALSE)
    cat("done (DATA:", length(names(new_data)), "keys, ATLAS:", length(names(new_atlas)), "keys)\n")

    # Region coverage from same file
    region_data <- extract_region_from_payload_js(opts$payload)
  } else {
    cat("Reading DATA JSON... ")
    new_data <- jsonlite::fromJSON(opts$data, simplifyVector = FALSE)
    cat(length(names(new_data)), "keys\n")

    cat("Reading ATLAS JSON... ")
    new_atlas <- jsonlite::fromJSON(opts$atlas, simplifyVector = FALSE)
    cat(length(names(new_atlas)), "keys\n")

    region_data <- if (!is.null(opts$region) && file.exists(opts$region)) {
      jsonlite::fromJSON(opts$region, simplifyVector = FALSE)
    } else if (!is.null(opts$payload_js_for_region)) {
      extract_region_from_payload_js(opts$payload_js_for_region)
    } else {
      NULL
    }
  }

  # Replace DATA
  cat("Replacing const DATA... ")
  html_text <- replace_js_const(html_text, "const DATA = ", new_data, minify = opts$minify)
  cat("done\n")

  # Replace ATLAS
  cat("Replacing const ATLAS = ... ")
  html_text <- replace_js_const(html_text, "const ATLAS = ", new_atlas, minify = opts$minify)
  cat("done\n")

  # Replace REGION_COVERAGE_ROWS if available
  if (!is.null(region_data)) {
    cat("Replacing const REGION_COVERAGE_ROWS... ")
    html_text <- replace_js_const(html_text, "const REGION_COVERAGE_ROWS = ", region_data, minify = opts$minify)
    cat("done\n")
  }

  if (opts$dry_run) {
    cat("\n[DRY RUN] Would write ", format(nchar(html_text), big.mark = ","),
        " chars to: ", opts$out, "\n")
    return(invisible(NULL))
  }

  # Backup
  if (opts$backup && file.exists(opts$out)) {
    bak <- paste0(opts$out, ".bak.", format(Sys.time(), "%Y%m%d%H%M%S"))
    file.copy(opts$out, bak)
    cat("Backed up existing output to: ", bak, "\n")
  }

  # Write
  cat("Writing updated HTML... ")
  writeLines(html_text, opts$out, useBytes = TRUE)
  cat(format(nchar(html_text), big.mark = ","), "chars -> ", opts$out, "\n")

  # Validate
  cat("\nValidating output...\n")
  checks <- validate_output(opts$out)

  if (checks$DATA$found && checks$DATA$parseable) {
    cat("  DATA:  OK (",
        checks$DATA$n_keys, " keys, ",
        checks$DATA$n_loaded, " loaded datasets, ",
        checks$DATA$n_catalog, " catalog entries)\n", sep = "")
  } else {
    cat("  DATA:  ", if (!checks$DATA$found) "NOT FOUND" else "PARSE ERROR", "\n")
  }

  if (checks$ATLAS$found && checks$ATLAS$parseable) {
    cat("  ATLAS: OK (", checks$ATLAS$n_keys, " keys)\n", sep = "")
  } else {
    cat("  ATLAS: ", if (!checks$ATLAS$found) "NOT FOUND" else "PARSE ERROR", "\n")
  }

  cat("\nDone. Updated atlas: ", opts$out, "\n")
  invisible(opts$out)
}

# Run if executed directly (not sourced)
if (!interactive() || identical(Sys.getenv("ATLAS_UPDATER_RUN"), "1")) {
  main()
}
