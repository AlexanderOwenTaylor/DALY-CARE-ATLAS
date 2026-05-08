#!/usr/bin/env Rscript
# =============================================================================
# DALY-CARE cartography — consolidated atlas builder
# =============================================================================
# PURPOSE
# -------
# This script builds the DALY-CARE atlas payload from a baseline plus a fresh
# pass over the live DALY-CARE datasets. Concretely:
#
#   1. Reads its baseline payload from `DALYCARE_atlas_payload.js` first, and
#      only falls back to a glob over `DALYCARE_atlas_AOT_V*.html` if no
#      payload is on disk. The atlas's externalised payload is the
#      authoritative baseline; the HTML glob is a recovery path when no
#      payload has been written yet.
#
#   2. Captures `load_dataset()`'s return value inside `safe_load_dataset()`
#      and assigns it into `.GlobalEnv` if it is a data.frame. This handles
#      both the legacy side-effect contract and the current return-only
#      contract of the DALY-CARE loader.
#
#   3. Logs prominent warnings when any of `ATLAS_PAYLOAD_PATH`,
#      `ATLAS_HTML_PATH`, `CONSENSUS_XLSX_PATH`, `DETECTIVE_ARCHIVE_PATH` come
#      back NA, instead of a single quiet "Path: NA" line.
#
#   4. Stamps `DATA_payload$__refreshed_at` so the HTML atlas banner can show
#      when the figures were refreshed.
#
#   5. Adds lab-site / SHAK / SOR decoding so LABKA "RHB" renders as
#      "Rigshospitalet" and a SHAK code like "3800A20" renders as
#      "Sjællands Universitetshospital — Hæmatologisk afdeling". The lookups
#      try the canonical `Codes_hospital`, `Codes_SHAK_long`, and
#      `shakcomplete` reference tables when they're loaded; otherwise they
#      fall back to a small, hand-maintained dictionary of common 3-letter
#      lab codes and SHAK hospital prefixes.
#
#   6. Provides live summarisers for every panel: diagGroups (curated ICD-10
#      groupings), atcTop, the registry deep panels (DaMyDa stage / treatment
#      / response / cytogenetics / labs, LYFO subtypes / IPI / B-symptoms,
#      CLL Binet / IGHV / FISH / TP53), tx_protocols + tx_lines from
#      SP_Behandlingsplaner_del1, ADT events / hospitals / admission_type /
#      patient_class, administered medicine ATC + routes, note types,
#      microbiology atlases (PERSIMUNE + SP_Bloddyrkning), IGHV mutational
#      status, flow cytometry footprint, CLL panel driver counts, biobank
#      sources + types, ICU stays, transfer hospitals, DNR
#      (Behandlingsniveau), and BWGC radiotherapy procedure codes.
#
#   7. Treats every section as `result <- baseline_value %||% live_value`, so
#      runs where some section silently returns nothing still preserve the
#      previous payload's value rather than collapsing to []. No single run
#      will resolve every dataset, and the operator should not be punished
#      for that with a half-empty atlas.
#
#   8. Splits the live load loop into Stage A (lookup-resident) and Stage B
#      (streaming). Stage A loads small reference tables and keeps them
#      resident so the lookup-name maps populate. Stage B then iterates over
#      the heavy datasets one at a time: load → dispatch to summariser →
#      drop the loaded data.frame and gc() before the next iteration. Two
#      summarisers (`summarise_persimune_microbiology`,
#      `summarise_sp_microbiology`) need >1 part; for those the dispatcher
#      captures small per-part summary tibbles into accumulators and the
#      final shapes are assembled after the loop ends. Resident memory is
#      bounded by `(lookup tables) + (one heavy dataset) + (small
#      summaries)` instead of `sum of every loaded dataset`.
#
# Operator workflow:
#   Rscript 000_dalycare_cartography_consolidated.R [OUT_DIR]
# Or with explicit baseline:
#   ATLAS_PAYLOAD_PATH=/path/to/DALYCARE_atlas_payload.js \
#     Rscript 000_dalycare_cartography_consolidated.R
# =============================================================================

options(stringsAsFactors = FALSE, warn = 1)

quiet_library <- function(pkg, required = TRUE) {
  ok <- suppressPackageStartupMessages(
    require(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
  )
  if (!ok && required) stop("Missing required package: ", pkg, call. = FALSE)
  ok
}

required_pkgs <- c("dplyr", "readr", "tibble", "tidyr", "stringr", "purrr", "jsonlite")
invisible(vapply(required_pkgs, quiet_library, logical(1), required = TRUE))
optional_pkgs <- c("readxl", "openxlsx", "writexl", "DBI", "RPostgres")
invisible(vapply(optional_pkgs, quiet_library, logical(1), required = FALSE))

`%||%` <- function(x, y) if (is.null(x)) y else x

# =============================================================================
# Config
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
refreshed_at_iso <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z", tz = "UTC")

OUT_DIR <- if (length(args) >= 1L && nzchar(args[[1]])) {
  args[[1]]
} else {
  Sys.getenv("CARTO_OUT_DIR", unset = file.path(getwd(), "Other", paste0("DALYCARE_atlas_refresh_", stamp)))
}
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

LOG_FILE <- file.path(OUT_DIR, "cartography_consolidated_log.txt")
log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = LOG_FILE, append = TRUE)
}
warn_loud <- function(...) {
  msg <- paste(..., collapse = "")
  banner <- paste(rep("!", min(80L, nchar(msg) + 4L)), collapse = "")
  log_msg(banner)
  log_msg("!! ", msg)
  log_msg(banner)
}
cat("", file = LOG_FILE)

# ---- Robust path discovery -------------------------------------------------
# This script searches the operator's rearranged package/tree instead of only CWD and
# the script directory. This prevents a run launched from /ngc/people/<user>
# from missing files placed in e.g. "Column names/", "resources/", "site/",
# "atlas_publication/", or "WoMMen_code_V06/code/".
as_logical_env <- function(name, default = FALSE) {
  val <- tolower(Sys.getenv(name, unset = if (isTRUE(default)) "true" else "false"))
  val %in% c("1", "true", "yes", "y", "on")
}

find_first_existing <- function(paths) {
  paths <- unique(stats::na.omit(as.character(paths)))
  paths <- paths[nzchar(paths)]
  hits <- paths[file.exists(paths)]
  if (length(hits)) normalizePath(hits[[1]], winslash = "/", mustWork = FALSE) else NA_character_
}

script_dir_guess <- tryCatch({
  a <- commandArgs(trailingOnly = FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f) >= 1L && nzchar(f[[1]])) dirname(normalizePath(f[[1]], winslash = "/", mustWork = FALSE)) else getwd()
}, error = function(e) getwd())

path_ancestors <- function(x, max_up = 5L) {
  x <- normalizePath(x, winslash = "/", mustWork = FALSE)
  out <- character()
  cur <- x
  for (i in seq_len(max_up)) {
    out <- c(out, cur)
    nxt <- dirname(cur)
    if (identical(nxt, cur)) break
    cur <- nxt
  }
  unique(out)
}

split_env_paths <- function(x) {
  if (!nzchar(x)) return(character())
  unique(trimws(unlist(strsplit(x, .Platform$path.sep, fixed = TRUE))))
}

carto_input_roots <- function() {
  env_roots <- split_env_paths(Sys.getenv("CARTO_INPUT_ROOTS", unset = ""))
  roots <- unique(c(env_roots, getwd(), script_dir_guess))

  # Important: do not recursively scan parent directories by default. On NGC,
  # sourcing this file from a home/project directory can otherwise walk very
  # large trees and look like an infinite hang. Parent search is available only
  # when explicitly requested.
  if (as_logical_env("CARTO_SEARCH_PARENT_DIRS", default = FALSE)) {
    roots <- unique(c(roots, path_ancestors(getwd(), 4L), path_ancestors(script_dir_guess, 4L)))
  }

  roots <- roots[nzchar(roots)]
  roots <- roots[dir.exists(roots)]
  unique(normalizePath(roots, winslash = "/", mustWork = FALSE))
}

carto_search_dirs <- function(roots = carto_input_roots()) {
  roots <- unique(roots[dir.exists(roots)])
  one_level <- unlist(lapply(roots, function(root) {
    kids <- list.files(root, full.names = TRUE, recursive = FALSE, all.files = FALSE, no.. = TRUE)
    kids <- kids[dir.exists(kids)]
    keep <- grepl("(Column names|WoMMen|atlas|DALYCARE|Dalycare|dalycare|resources|site|cartography|code|Other|review_sources|atlas_publication)",
                  basename(kids), ignore.case = TRUE)
    kids[keep]
  }), use.names = FALSE)
  unique(normalizePath(c(roots, one_level), winslash = "/", mustWork = FALSE))
}

is_bad_baseline_candidate <- function(path) {
  grepl("DALYCARE_atlas_refresh_|/Other/DALYCARE_atlas_refresh_", path, ignore.case = TRUE)
}

version_number_from_path <- function(path) {
  m <- regmatches(basename(path), regexpr("V[0-9]+", basename(path), ignore.case = TRUE))
  if (!length(m) || is.na(m)) return(0L)
  as.integer(gsub("[^0-9]", "", m))
}

find_latest_glob <- function(dirs, pattern, recursive = FALSE, exclude_refresh_outputs = FALSE) {
  dirs <- unique(stats::na.omit(as.character(dirs)))
  dirs <- dirs[nzchar(dirs) & dir.exists(dirs)]
  if (!length(dirs)) return(NA_character_)
  hits <- character()
  for (d in dirs) {
    found <- list.files(d, pattern = pattern, full.names = TRUE, ignore.case = TRUE,
                        recursive = isTRUE(recursive), all.files = FALSE, no.. = TRUE)
    hits <- c(hits, found)
  }
  hits <- unique(hits[file.exists(hits)])
  if (isTRUE(exclude_refresh_outputs)) hits <- hits[!vapply(hits, is_bad_baseline_candidate, logical(1))]
  if (!length(hits)) return(NA_character_)
  info <- file.info(hits)
  ver <- vapply(hits, version_number_from_path, integer(1))
  ord <- order(ver, info$size, info$mtime, decreasing = TRUE, na.last = TRUE)
  normalizePath(hits[ord][[1]], winslash = "/", mustWork = FALSE)
}

find_best_file <- function(pattern, recursive = TRUE, exclude_refresh_outputs = FALSE) {
  direct_dirs <- carto_search_dirs()
  # First try direct/curated subdirectories recursively; then optionally full roots.
  hit <- find_latest_glob(direct_dirs, pattern, recursive = isTRUE(recursive),
                          exclude_refresh_outputs = exclude_refresh_outputs)
  if (!is.na(hit)) return(hit)
  if (as_logical_env("CARTO_FULL_RECURSIVE", default = FALSE)) {
    hit <- find_latest_glob(carto_input_roots(), pattern, recursive = TRUE,
                            exclude_refresh_outputs = exclude_refresh_outputs)
    if (!is.na(hit)) return(hit)
  }
  NA_character_
}

find_best_dir <- function(pattern) {
  dirs <- carto_search_dirs()
  hits <- character()
  for (d in dirs) {
    kids <- list.files(d, full.names = TRUE, recursive = FALSE, all.files = FALSE, no.. = TRUE)
    hits <- c(hits, kids[dir.exists(kids) & grepl(pattern, basename(kids), ignore.case = TRUE)])
  }
  hits <- unique(hits)
  if (!length(hits)) return(NA_character_)
  info <- file.info(hits)
  normalizePath(hits[order(info$mtime, decreasing = TRUE)][[1]], winslash = "/", mustWork = FALSE)
}

# ---- Path resolution (payload-first, bounded package-aware) ---------
ATLAS_PAYLOAD_PATH <- find_first_existing(c(
  Sys.getenv("ATLAS_PAYLOAD_PATH", unset = ""),
  file.path(getwd(), "DALYCARE_atlas_payload.js"),
  file.path(script_dir_guess, "DALYCARE_atlas_payload.js")
))
if (is.na(ATLAS_PAYLOAD_PATH)) {
  ATLAS_PAYLOAD_PATH <- find_best_file("^DALYCARE_atlas_payload( \\([0-9]+\\))?\\.js$",
                                       recursive = TRUE, exclude_refresh_outputs = TRUE)
}

ATLAS_HTML_PATH <- find_first_existing(c(
  Sys.getenv("ATLAS_HTML_PATH", unset = ""),
  file.path(getwd(), "DALYCARE_atlas_AOT_V35.html"),
  file.path(script_dir_guess, "DALYCARE_atlas_AOT_V35.html")
))
if (is.na(ATLAS_HTML_PATH)) {
  ATLAS_HTML_PATH <- find_best_file("^DALYCARE_atlas_AOT_V[0-9]+\\.html$",
                                    recursive = TRUE, exclude_refresh_outputs = TRUE)
}

CONSENSUS_XLSX_PATH <- find_first_existing(c(
  Sys.getenv("CONSENSUS_XLSX_PATH", unset = ""),
  file.path(getwd(), "unified_consensus_dictionary.xlsx"),
  file.path(script_dir_guess, "unified_consensus_dictionary.xlsx")
))
if (is.na(CONSENSUS_XLSX_PATH)) {
  CONSENSUS_XLSX_PATH <- find_best_file("^unified_consensus_dictionary\\.xlsx$",
                                        recursive = TRUE, exclude_refresh_outputs = FALSE)
}

DETECTIVE_ARCHIVE_PATH <- find_first_existing(c(
  Sys.getenv("DETECTIVE_SOURCE_PATH", unset = ""),
  Sys.getenv("DETECTIVE_ARCHIVE_PATH", unset = ""),
  file.path(getwd(), "Column names"),
  file.path(script_dir_guess, "Column names"),
  file.path(getwd(), "resources", "detective_archive_unpacked"),
  file.path(script_dir_guess, "resources", "detective_archive_unpacked")
))
if (is.na(DETECTIVE_ARCHIVE_PATH)) {
  # Supports both legacy ZIP archives and unpacked directories. The final
  # production package intentionally contains no nested ZIPs.
  z <- find_best_file("^(Column names\\(.*\\)|[0-9]{8} [0-9]+|.*detective.*|.*forensic.*)\\.zip$",
                      recursive = TRUE, exclude_refresh_outputs = FALSE)
  if (!is.na(z)) {
    DETECTIVE_ARCHIVE_PATH <- z
  } else {
    # If a rearranged output tree is present, use it as the detective source.
    d <- find_best_dir("^(Column names|detective_archive_unpacked|npu_detective|forensics)$")
    if (!is.na(d)) DETECTIVE_ARCHIVE_PATH <- d
  }
}

BOOTSTRAP_PATH <- find_first_existing(c(
  Sys.getenv("DALYCARE_BOOTSTRAP_PATH", unset = ""),
  "/ngc/projects2/dalyca_r/clean_r/load_dalycare_package.R",
  find_best_file("^load_dalycare_package\\.R$", recursive = TRUE, exclude_refresh_outputs = TRUE)
  # Note: a fourth fallback to 01_config_and_helpers.R is intentionally NOT
  # included. That file is the WoMMen pipeline's helpers, not a DALY-CARE
  # bootstrap. Sourcing it loads ~14 R packages and defines hundreds of
  # WoMMen-internal functions but never defines load_dataset(); the
  # downstream check then warns "load_dataset is NOT available" after a lot
  # of unnecessary side effects. If the real DALY-CARE bootstrap can't be
  # found, the script falls into baseline-preserving mode without polluting
  # .GlobalEnv.
))

ATLAS_REQUIRE_BASELINE <- !as_logical_env("ATLAS_ALLOW_EMPTY_BASELINE", default = FALSE)

log_msg("=== Cartography starting ===")
log_msg("Refreshed-at stamp: ", refreshed_at_iso)
log_msg("Output dir:         ", normalizePath(OUT_DIR, winslash = "/", mustWork = FALSE))
log_msg("Atlas payload path: ", ATLAS_PAYLOAD_PATH %||% "NA")
log_msg("Atlas HTML path:    ", ATLAS_HTML_PATH %||% "NA")
log_msg("Consensus XLSX:     ", CONSENSUS_XLSX_PATH %||% "NA")
log_msg("Detective archive:  ", DETECTIVE_ARCHIVE_PATH %||% "NA")
log_msg("Bootstrap path:     ", BOOTSTRAP_PATH %||% "NA")

if (is.na(ATLAS_PAYLOAD_PATH) && is.na(ATLAS_HTML_PATH)) {
  warn_loud(
    "Neither DALYCARE_atlas_payload.js nor a DALYCARE_atlas_AOT_V*.html ",
    "atlas was found after recursive package-aware discovery. In production ",
    "this is a hard stop unless ATLAS_ALLOW_EMPTY_BASELINE=1 is set."
  )
}
if (is.na(CONSENSUS_XLSX_PATH)) {
  log_msg("Optional consensus XLSX not found. Will preserve baseline NPU panels and/or use detective-derived fallback tables if available.")
}
if (is.na(DETECTIVE_ARCHIVE_PATH)) {
  log_msg("Optional detective source not found as ZIP or unpacked directory. Will preserve baseline detective/isotype panels if present.")
}
if (is.na(BOOTSTRAP_PATH)) {
  warn_loud(
    "No DALY-CARE bootstrap found. load_dataset() will not be available; ",
    "the script will produce a baseline-preserving payload only."
  )
}

# =============================================================================
# Atlas baseline extraction
# =============================================================================
# This section reads the externalised payload first (preferred path; recent
# atlases carry no inline DATA / ATLAS so the baseline must come from disk).
# If that is absent, fall back to parsing the const declarations out of an
# HTML atlas of any version.

find_js_value_bounds <- function(chars, start_pos, open_char = "{", close_char = "}") {
  n <- length(chars)
  if (start_pos > n || chars[start_pos] != open_char) return(NULL)

  depth <- 0L
  in_string <- FALSE
  escape_next <- FALSE

  for (i in seq.int(start_pos, n)) {
    ch <- chars[[i]]

    if (escape_next) {
      escape_next <- FALSE
      next
    }
    if (identical(ch, "\\") && in_string) {
      escape_next <- TRUE
      next
    }
    if (identical(ch, "\"")) {
      in_string <- !in_string
      next
    }
    if (in_string) next

    if (identical(ch, open_char)) depth <- depth + 1L
    if (identical(ch, close_char)) {
      depth <- depth - 1L
      if (depth == 0L) return(list(start = start_pos, end = i))
    }
  }
  NULL
}

extract_js_value <- function(txt, anchor, open_char, close_char) {
  idx <- regexpr(anchor, txt, fixed = TRUE)[1]
  if (is.na(idx) || idx < 1L) return(NULL)
  chars <- strsplit(txt, "", fixed = TRUE)[[1]]
  start <- idx + nchar(anchor)
  while (start <= length(chars) && chars[start] %in% c(" ", "\n", "\r", "\t")) {
    start <- start + 1L
  }
  if (start > length(chars) || !identical(chars[start], open_char)) return(NULL)
  bounds <- find_js_value_bounds(chars, start, open_char, close_char)
  if (is.null(bounds)) return(NULL)
  paste(chars[bounds$start:bounds$end], collapse = "")
}

extract_js_braced_object <- function(txt, anchor) {
  extract_js_value(txt, anchor, "{", "}")
}

extract_js_bracketed_array <- function(txt, anchor) {
  extract_js_value(txt, anchor, "[", "]")
}

read_atlas_baseline_from_payload <- function(payload_path) {
  if (is.na(payload_path) || !file.exists(payload_path)) {
    return(list(DATA = list(), ATLAS = list(), REGION_COVERAGE_ROWS = NULL))
  }
  txt <- paste(readLines(payload_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  out <- list(DATA = list(), ATLAS = list(), REGION_COVERAGE_ROWS = NULL)
  data_txt <- extract_js_braced_object(txt, "const DATA = ")
  atlas_txt <- extract_js_braced_object(txt, "const ATLAS = ")
  rcr_txt <- extract_js_bracketed_array(txt, "const REGION_COVERAGE_ROWS = ")
  if (!is.null(data_txt))  out$DATA  <- tryCatch(jsonlite::fromJSON(data_txt,  simplifyVector = TRUE), error = function(e) list())
  if (!is.null(atlas_txt)) out$ATLAS <- tryCatch(jsonlite::fromJSON(atlas_txt, simplifyVector = TRUE), error = function(e) list())
  if (!is.null(rcr_txt))   out$REGION_COVERAGE_ROWS <- tryCatch(jsonlite::fromJSON(rcr_txt, simplifyVector = TRUE), error = function(e) NULL)
  out
}

read_atlas_baseline_from_html <- function(html_path) {
  if (is.na(html_path) || !file.exists(html_path)) {
    return(list(DATA = list(), ATLAS = list(), REGION_COVERAGE_ROWS = NULL))
  }
  txt <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  out <- list(DATA = list(), ATLAS = list(), REGION_COVERAGE_ROWS = NULL)
  data_txt <- extract_js_braced_object(txt, "const DATA = ")
  atlas_txt <- extract_js_braced_object(txt, "const ATLAS = ")
  rcr_txt <- extract_js_bracketed_array(txt, "const REGION_COVERAGE_ROWS = ")
  if (!is.null(data_txt))  out$DATA  <- tryCatch(jsonlite::fromJSON(data_txt,  simplifyVector = TRUE), error = function(e) list())
  if (!is.null(atlas_txt)) out$ATLAS <- tryCatch(jsonlite::fromJSON(atlas_txt, simplifyVector = TRUE), error = function(e) list())
  if (!is.null(rcr_txt))   out$REGION_COVERAGE_ROWS <- tryCatch(jsonlite::fromJSON(rcr_txt, simplifyVector = TRUE), error = function(e) NULL)
  out
}

atlas_baseline <- if (!is.na(ATLAS_PAYLOAD_PATH)) {
  log_msg("Reading baseline from payload: ", basename(ATLAS_PAYLOAD_PATH))
  read_atlas_baseline_from_payload(ATLAS_PAYLOAD_PATH)
} else if (!is.na(ATLAS_HTML_PATH)) {
  log_msg("Reading baseline from HTML: ", basename(ATLAS_HTML_PATH))
  read_atlas_baseline_from_html(ATLAS_HTML_PATH)
} else {
  list(DATA = list(), ATLAS = list(), REGION_COVERAGE_ROWS = NULL)
}
baseline_DATA  <- atlas_baseline$DATA  %||% list()
baseline_ATLAS <- atlas_baseline$ATLAS %||% list()
baseline_RCR   <- atlas_baseline$REGION_COVERAGE_ROWS

log_msg("Baseline parsed. DATA keys: ", length(names(baseline_DATA)),
        " | ATLAS keys: ", length(names(baseline_ATLAS)),
        " | RCR rows: ",   if (is.null(baseline_RCR)) 0 else NROW(baseline_RCR))

baseline_empty <- length(names(baseline_DATA)) == 0L && length(names(baseline_ATLAS)) == 0L
if (baseline_empty) {
  warn_loud(
    "Baseline DATA and ATLAS are both empty. Either no baseline file was ",
    "found, or the file did not contain `const DATA = {…};` / `const ATLAS ",
    "= {…};` blocks at the expected anchors."
  )
  if (isTRUE(ATLAS_REQUIRE_BASELINE)) {
    stop(
      "Required atlas baseline is empty. Refusing to write a near-empty atlas. ",
      "Place DALYCARE_atlas_payload.js or DALYCARE_atlas_AOT_V*.html in the package tree, ",
      "set ATLAS_PAYLOAD_PATH / ATLAS_HTML_PATH explicitly, or set ATLAS_ALLOW_EMPTY_BASELINE=1 ",
      "for a deliberate first-build run.",
      call. = FALSE
    )
  }
}

# =============================================================================
# Bootstrap DALY-CARE
# =============================================================================
bootstrap_status <- "not_attempted"
# V06 cartography hardening: a pre-existing `load_dataset()` is not enough.
# In the failed 2026-05-01 run the function object survived from an earlier
# session, but the DALY-CARE backend connection underneath it was stale: lookup
# tables could still appear while every streamed clinical dataset returned
# `not_loaded`. Refresh the bootstrap by default whenever a bootstrap path is
# available; operators can opt out only for a deliberately pre-bootstrapped
# session.
.bootstrap_refresh <- as_logical_env("CARTO_REFRESH_BOOTSTRAP", default = TRUE) ||
  as_logical_env("CARTO_FORCE_BOOTSTRAP", default = FALSE)
if (isTRUE(.bootstrap_refresh) && !is.na(BOOTSTRAP_PATH) && file.exists(BOOTSTRAP_PATH)) {
  log_msg("Refreshing DALY-CARE bootstrap: ", BOOTSTRAP_PATH)
  tryCatch({
    source(BOOTSTRAP_PATH, local = .GlobalEnv)
    bootstrap_status <- paste0("refreshed:", BOOTSTRAP_PATH)
  }, error = function(e) {
    bootstrap_status <<- paste0("error:", conditionMessage(e))
    warn_loud("Bootstrap refresh error: ", conditionMessage(e))
  })
} else if (!exists("load_dataset", mode = "function", inherits = TRUE)) {
  if (!is.na(BOOTSTRAP_PATH) && file.exists(BOOTSTRAP_PATH)) {
    log_msg("Sourcing DALY-CARE bootstrap: ", BOOTSTRAP_PATH)
    tryCatch({
      source(BOOTSTRAP_PATH, local = .GlobalEnv)
      bootstrap_status <- paste0("sourced:", BOOTSTRAP_PATH)
    }, error = function(e) {
      bootstrap_status <<- paste0("error:", conditionMessage(e))
      warn_loud("Bootstrap source error: ", conditionMessage(e))
    })
  } else {
    bootstrap_status <- "not_found"
  }
} else {
  bootstrap_status <- "pre_existing_not_refreshed"
}
log_msg("Bootstrap status: ", bootstrap_status)
if (!exists("load_dataset", mode = "function", inherits = TRUE)) {
  warn_loud(
    "load_dataset() is NOT available after bootstrap. The script will run ",
    "in baseline-preserving mode only — no live DALY-CARE refresh will ",
    "occur this run."
  )
}

# =============================================================================
# Source aliases (SDS-2026-04-23 refresh names included)
# =============================================================================
ascii_fold <- function(x) {
  x_chr <- as.character(x %||% "")
  x_ascii <- suppressWarnings(iconv(x_chr, from = "", to = "ASCII//TRANSLIT"))
  x_use <- ifelse(is.na(x_ascii), x_chr, x_ascii)
  tolower(gsub("[^a-z0-9]+", "", x_use))
}

source_alias_map <- function() {
  list(
    SDS_lab_forsker = c("SDS_laboratorieproevesvar", "SDS_lab_forsker"),
    SDS_lab_labidcodes = c("SDS_dimlaboratoriekoder", "SDS_lab_labidcodes"),
    SDS_t_tumor = c("SDS_tumor_aarlig", "SDS_t_tumor"),
    SDS_t_vaevsanvend_markoer = c("SDS_vaevregistrering", "SDS_t_vaevsanvend_markoer"),
    SDS_t_doedsaarsag = c("SDS_t_dodsaarsag_2", "SDS_t_doedsaarsag", "SDS_doedsaarsag_3"),
    SP_Administreret_Medicin = c("SP_Administreret_Medicin", "SP_AdministreretMedicin", "Administreret_Medicin"),
    SP_ADT_Haendelser = c("SP_ADT_Haendelser", "SP_ADT_haendelser", "ADT_Haendelser"),
    SP_Aktive_Problemliste_Diagnoser = c("SP_Aktive_Problemliste_Diagnoser", "SP_AktiveProblemlisteDiagnoser"),
    SP_Behandlingskontakter_diagnoser = c("SP_Behandlingskontakter_diagnoser", "SP_BehandlingskontakterOgDiagnoser"),
    SP_Behandlingsplaner_del1 = c("SP_Behandlingsplaner_del1", "SP_Behandlingsplaner_Del1"),
    SP_Behandlingsplaner_del2 = c("SP_Behandlingsplaner_del2", "SP_Behandlingsplaner_Del2"),
    SP_Journalnotater_Del1 = c("SP_Journalnotater_Del1", "SP_Journalnotater_del1"),
    SP_Journalnotater_Del2 = c("SP_Journalnotater_Del2", "SP_Journalnotater_del2"),
    SP_BilleddiagnostikeUndersoegelser_Del1 = c(
      "SP_BilleddiagnostikeUndersoegelser_Del1", "SP_BilleddiagnostiskeUndersøgelser_Del1",
      "SP_BilleddiagnostiskeUndersoegelser_Del1", "BilleddiagnostikeUndersoegelser_Del1"),
    SP_BilleddiagnostikeUndersoegelser_Del2 = c(
      "SP_BilleddiagnostikeUndersoegelser_Del2", "SP_BilleddiagnostiskeUndersøgelser_Del2",
      "SP_BilleddiagnostiskeUndersoegelser_Del2", "BilleddiagnostikeUndersoegelser_Del2"),
    SDS_procedure_kirurgi = c("SDS_procedurer_kirurgi", "SDS_procedure_kirurgi"),
    SDS_procedure_andre = c("SDS_procedurer_andre", "SDS_procedure_andre"),
    laboratorymeasurements = c("laboratorymeasurements"),
    t_dalycare_diagnoses = c("t_dalycare_diagnoses"),
    diagnoses_all = c("diagnoses_all"),
    patient = c("patient"),
    PERSIMUNE_microbiology_analysis = c("PERSIMUNE_microbiology_analysis", "microbiology_analysis"),
    PERSIMUNE_microbiology_culture = c("PERSIMUNE_microbiology_culture", "microbiology_culture"),
    PERSIMUNE_microbiology_culture_resistance = c("PERSIMUNE_microbiology_culture_resistance", "microbiology_culture_resistance"),
    PERSIMUNE_microbiology_microscopy = c("PERSIMUNE_microbiology_microscopy", "microbiology_microscopy"),
    PERSIMUNE_biochemistry = c("PERSIMUNE_biochemistry", "biochemistry"),
    LAB_IGHVIMGT = c("LAB_IGHVIMGT", "IGHVIMGT"),
    LAB_Flowcytometry = c("LAB_Flowcytometry", "Flowcytometry"),
    LAB_FISH = c("LAB_FISH", "FISH"),
    LAB_CLLPANEL_WIDE = c("LAB_CLLPANEL_WIDE", "CLLPANEL_WIDE"),
    LAB_BIOBANK_SAMPLES = c("LAB_BIOBANK_SAMPLES", "BIOBANK_SAMPLES"),
    SP_Bloddyrkning_del1 = c("SP_Bloddyrkning_del1"),
    SP_Bloddyrkning_del2 = c("SP_Bloddyrkning_del2"),
    SP_Bloddyrkning_del3 = c("SP_Bloddyrkning_del3"),
    SP_Bloddyrkning_del4 = c("SP_Bloddyrkning_del4"),
    SP_ITAOphold = c("SP_ITAOphold"),
    SP_Flytningshistorik = c("SP_Flytningshistorik"),
    SP_Behandlingsniveau = c("SP_Behandlingsniveau"),
    CLL_TREAT = c("CLL_TREAT"),
    CLL_TREAT_IBRUTINIB = c("CLL_TREAT_IBRUTINIB"),
    Codes_hospital = c("Codes_hospital"),
    Codes_SHAK_long = c("Codes_SHAK_long"),
    shakcomplete = c("shakcomplete")
  )
}

expand_candidates <- function(candidates) {
  alias_map <- source_alias_map()
  candidates <- unique(stats::na.omit(as.character(candidates)))
  out <- character()
  for (cand in candidates) {
    matched <- FALSE
    cand_fold <- ascii_fold(cand)
    for (canonical in names(alias_map)) {
      fam <- unique(c(canonical, alias_map[[canonical]]))
      if (cand_fold %in% ascii_fold(fam)) {
        out <- c(out, fam); matched <- TRUE
      }
    }
    if (!matched) out <- c(out, cand)
  }
  unique(out[nzchar(out)])
}

canonical_target <- function(candidate) {
  alias_map <- source_alias_map()
  cand_fold <- ascii_fold(candidate)
  for (canonical in names(alias_map)) {
    fam <- unique(c(canonical, alias_map[[canonical]]))
    if (cand_fold %in% ascii_fold(fam)) return(canonical)
  }
  candidate
}

pick_existing_object <- function(candidates) {
  candidates <- expand_candidates(candidates)
  objs <- ls(.GlobalEnv, all.names = TRUE)
  if (!length(objs)) return(list(name = NA_character_, data = NULL))
  exact_hit <- which(objs %in% candidates)
  if (length(exact_hit)) {
    nm <- objs[exact_hit[[1]]]
    obj <- get0(nm, envir = .GlobalEnv, inherits = FALSE, ifnotfound = NULL)
    return(list(name = nm, data = obj))
  }
  obj_fold <- ascii_fold(objs)
  cand_fold <- ascii_fold(candidates)
  hit <- which(obj_fold %in% cand_fold)
  if (!length(hit)) return(list(name = NA_character_, data = NULL))
  nm <- objs[hit[[1]]]
  obj <- get0(nm, envir = .GlobalEnv, inherits = FALSE, ifnotfound = NULL)
  list(name = nm, data = obj)
}

# ---- safe_load_dataset(): capture load_dataset() return value -------------
# load_dataset() can either return the data.frame, side-effect into
# .GlobalEnv, or both, depending on the DALY-CARE loader version in scope.
# safe_load_dataset() handles all three paths so the cartography never
# silently produces zero loads when the loader API drifts.
safe_load_dataset <- function(candidates, prefer_live = TRUE) {
  existing <- pick_existing_object(candidates)
  if (inherits(existing$data, "data.frame")) {
    return(c(existing, list(requested = paste(candidates, collapse = ";"), status = "already_loaded")))
  }
  if (!exists("load_dataset", mode = "function", inherits = TRUE) || !isTRUE(prefer_live)) {
    return(list(name = NA_character_, data = NULL,
                requested = paste(candidates, collapse = ";"), status = "load_dataset_unavailable"))
  }
  tried <- expand_candidates(candidates)
  for (cand in tried) {
    before <- ls(.GlobalEnv, all.names = TRUE)
    res <- NULL
    ok <- tryCatch({
      res <- load_dataset(cand)
      TRUE
    }, error = function(e) {
      log_msg("load_dataset failed for '", cand, "': ", conditionMessage(e))
      FALSE
    })
    if (!ok) next
    # PATH A — return value carries the data
    if (inherits(res, "data.frame")) {
      target_name <- canonical_target(cand)
      if (!nzchar(target_name)) target_name <- cand
      assign(target_name, res, envir = .GlobalEnv)
      return(list(name = target_name, data = res,
                  requested = paste(candidates, collapse = ";"),
                  status = paste0("loaded_via_return:", cand)))
    }
    # PATH B — load_dataset side-effected into .GlobalEnv
    after <- ls(.GlobalEnv, all.names = TRUE)
    fresh <- setdiff(after, before)
    hits <- unique(c(fresh, expand_candidates(candidates)))
    picked <- pick_existing_object(hits)
    if (inherits(picked$data, "data.frame")) {
      return(c(picked, list(requested = paste(candidates, collapse = ";"),
                            status = paste0("loaded_via_global:", cand))))
    }
    # PATH C — return value is something else (a list, NULL, etc.). Try
    # extracting the first data.frame element if `res` is a list.
    if (is.list(res) && !is.data.frame(res)) {
      df_idx <- which(vapply(res, is.data.frame, logical(1)))
      if (length(df_idx)) {
        target_name <- canonical_target(cand)
        df <- res[[df_idx[[1]]]]
        assign(target_name, df, envir = .GlobalEnv)
        return(list(name = target_name, data = df,
                    requested = paste(candidates, collapse = ";"),
                    status = paste0("loaded_via_list:", cand)))
      }
    }
  }
  list(name = NA_character_, data = NULL,
       requested = paste(candidates, collapse = ";"), status = "not_loaded")
}

# ---- loader canary --------------------------------------------------------
# Fail early if the DALY-CARE loader exists as an R function but no longer
# returns or side-effects a real data.frame from the live backend. This catches
# the stale-loader / network-outage mode before the script writes a baseline-
# preserving atlas that looks like a successful refresh.
.cartography_loader_canary <- function(ds = Sys.getenv("CARTO_LOADER_CANARY", unset = "patient")) {
  if (!exists("load_dataset", mode = "function", inherits = TRUE)) {
    return(list(ok = FALSE, reason = "load_dataset() unavailable"))
  }
  before <- ls(.GlobalEnv, all.names = TRUE)
  res <- tryCatch(load_dataset(ds), error = function(e) e)
  if (inherits(res, "error")) {
    return(list(ok = FALSE, reason = paste0("load_dataset(", ds, ") error: ", conditionMessage(res))))
  }
  if (inherits(res, "data.frame") && nrow(res) > 0L) {
    assign(canonical_target(ds), res, envir = .GlobalEnv)
    return(list(ok = TRUE, reason = paste0("return data.frame rows=", nrow(res))))
  }
  after <- ls(.GlobalEnv, all.names = TRUE)
  candidates <- unique(c(setdiff(after, before), expand_candidates(ds), canonical_target(ds)))
  hit <- pick_existing_object(candidates)
  if (inherits(hit$data, "data.frame") && nrow(hit$data) > 0L) {
    return(list(ok = TRUE, reason = paste0("global data.frame ", hit$name, " rows=", nrow(hit$data))))
  }
  list(ok = FALSE, reason = paste0("load_dataset(", ds, ") returned class ",
                                   paste(class(res), collapse = "/"),
                                   " and no positive-row data.frame was resolvable"))
}

if (as_logical_env("CARTO_REQUIRE_LOADER_CANARY", default = TRUE)) {
  .canary <- .cartography_loader_canary()
  log_msg("Loader canary: ", if (isTRUE(.canary$ok)) "PASS" else "FAIL", " — ", .canary$reason)
  if (!isTRUE(.canary$ok) && !as_logical_env("CARTO_ALLOW_FAILED_CANARY", default = FALSE)) {
    stop("DALY-CARE loader canary failed: ", .canary$reason,
         ". Refusing to build a baseline-only cartography payload. ",
         "Set CARTO_ALLOW_FAILED_CANARY=TRUE only for deliberate offline testing.",
         call. = FALSE)
  }
}

# =============================================================================
# Generic summarise helpers — stable contract
# =============================================================================
resolve_column <- function(df, candidates, partial = FALSE) {
  if (!inherits(df, "data.frame") || !length(names(df))) return(NA_character_)
  nms <- names(df); low <- tolower(trimws(nms))
  cand_low <- tolower(trimws(candidates))
  idx <- match(cand_low, low); idx <- idx[!is.na(idx)]
  if (length(idx)) return(nms[idx[[1]]])
  if (isTRUE(partial)) {
    for (cand in cand_low) {
      hit <- which(grepl(cand, low, fixed = TRUE))
      if (length(hit)) return(nms[hit[[1]]])
    }
  }
  NA_character_
}

coerce_date_safe <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  x_chr <- as.character(x)
  out <- suppressWarnings(as.Date(x_chr)); if (sum(!is.na(out)) > 0L) return(out)
  out <- suppressWarnings(as.Date(substr(x_chr, 1L, 10L))); if (sum(!is.na(out)) > 0L) return(out)
  suppressWarnings(as.Date(as.numeric(x), origin = "1970-01-01"))
}

normalise_code <- function(x) {
  x <- toupper(gsub("[^A-Z0-9]", "", as.character(x))); x[x == ""] <- NA_character_; x
}

collapse_unique <- function(x, n = 3) {
  vals <- unique(stats::na.omit(as.character(x)))
  if (!length(vals)) return(NA_character_)
  paste(utils::head(vals, n), collapse = ";")
}

summarise_top_codes <- function(df, col, top_n = 25L, clean_fun = identity) {
  empty <- tibble::tibble(code = character(), n = integer())
  if (!inherits(df, "data.frame") || is.na(col) || !col %in% names(df)) return(empty)
  vals <- clean_fun(df[[col]]); vals <- vals[!is.na(vals) & vals != ""]
  if (!length(vals)) return(empty)
  tab <- sort(table(vals), decreasing = TRUE); keep <- utils::head(tab, top_n)
  tibble::tibble(code = names(keep), n = as.integer(keep))
}

summarise_top_labels <- function(df, col, top_n = 10L, label_name = "label") {
  empty <- stats::setNames(tibble::tibble(character(), integer()), c(label_name, "n"))
  if (!inherits(df, "data.frame") || is.na(col) || !col %in% names(df)) return(empty)
  vals <- as.character(df[[col]]); vals <- trimws(vals); vals[vals == ""] <- NA_character_
  vals <- vals[!is.na(vals)]
  if (!length(vals)) return(empty)
  tab <- sort(table(vals), decreasing = TRUE); keep <- utils::head(tab, top_n)
  out <- tibble::tibble(label = names(keep), n = as.integer(keep))
  if (label_name != "label") names(out)[1] <- label_name
  out
}

safe_n_distinct <- function(x) {
  x <- x[!is.na(x)]; if (!length(x)) return(NA_integer_); dplyr::n_distinct(x)
}

infer_layout <- function(df, id_col = NA_character_, date_col = NA_character_) {
  if (!inherits(df, "data.frame")) return("unknown")
  if (!is.na(id_col) && !is.na(date_col)) return("event_table")
  if (nrow(df) < 1e6 && ncol(df) >= 50 && nrow(df) <= ncol(df) * 500) return("wide_table")
  if (nrow(df) < 2e5 && ncol(df) <= 10) return("lookup_table")
  "unknown"
}

profile_dataset <- function(df, dataset_name, loaded_name = dataset_name, note = NA_character_) {
  if (!inherits(df, "data.frame")) {
    return(tibble::tibble(
      name = dataset_name, loaded_name = loaded_name, load_status = "not_loaded",
      rows = NA_integer_, cols = NA_integer_, patients = NA_integer_,
      id_col = NA_character_, date_col = NA_character_, layout = "unknown",
      date_min = NA_character_, date_max = NA_character_, note = note
    ))
  }
  id_col <- resolve_column(df, c("patientid", "patient_id", "dw_ek_borger", "pid", "personid", "cpr"), partial = TRUE)
  date_col <- resolve_column(df, c("date", "dato", "samplingdate", "measurementdate", "contact_date", "event_date", "date_diagnosis", "date_samplecollection"), partial = TRUE)
  dates <- if (!is.na(date_col)) coerce_date_safe(df[[date_col]]) else as.Date(character())
  tibble::tibble(
    name = dataset_name, loaded_name = loaded_name, load_status = "loaded",
    rows = nrow(df), cols = ncol(df),
    patients = if (!is.na(id_col)) safe_n_distinct(df[[id_col]]) else NA_integer_,
    id_col = id_col, date_col = date_col,
    layout = infer_layout(df, id_col = id_col, date_col = date_col),
    date_min = if (length(dates) && any(!is.na(dates))) as.character(min(dates, na.rm = TRUE)) else NA_character_,
    date_max = if (length(dates) && any(!is.na(dates))) as.character(max(dates, na.rm = TRUE)) else NA_character_,
    note = note
  )
}

write_csv_safe <- function(df, filename) {
  if (is.null(df)) return(invisible(NULL))
  path <- file.path(OUT_DIR, filename)
  readr::write_csv(df, path, na = "")
  invisible(path)
}

# =============================================================================
# Refresh notices
# =============================================================================
refresh_notices <- tibble::tribble(
  ~topic, ~status, ~detail,
  "SDS_lab_forsker", "renamed", "Use SDS_laboratorieproevesvar as the primary refreshed lab table; keep SDS_lab_forsker only as a legacy fallback.",
  "SDS_lab_labidcodes", "renamed", "Use SDS_dimlaboratoriekoder as the refreshed laboratory code lookup; keep SDS_lab_labidcodes only as a legacy fallback.",
  "SDS_t_tumor", "renamed", "Use SDS_tumor_aarlig as the refreshed tumour table alias.",
  "SDS_t_vaevsanvend_markoer", "renamed", "Use SDS_vaevregistrering as the refreshed tissue-registration alias.",
  "t_dalycare_diagnoses", "stale_core", "Do not treat core.t_dalycare_diagnoses as authoritative during the transition; derive diagnosis atlas summaries from diagnoses_all / patient instead.",
  "laboratorymeasurements", "stale_core", "Do not treat core.laboratorymeasurements as authoritative during the transition; prefer refreshed source tables (SDS_laboratorieproevesvar, SP_AlleProvesvar, biochemistry) and only fall back to core when necessary."
)
write_csv_safe(refresh_notices, "atlas_refresh_notices.csv")

# =============================================================================
# Resource catalog (baseline-overlaid)
# =============================================================================
resource_catalog <- NULL
if (!is.null(baseline_DATA$resourceCatalog) && length(baseline_DATA$resourceCatalog) > 0L) {
  resource_catalog <- tibble::as_tibble(baseline_DATA$resourceCatalog)
}
if (is.null(resource_catalog) || !nrow(resource_catalog)) {
  resource_catalog <- tibble::tibble(
    domain = c("Core", "Core", "RKKP", "RKKP", "RKKP", "SDS", "SP", "Laboratory"),
    dataset = c("patient", "diagnoses_all", "RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL",
                "SDS_epikur", "SP_VitaleVaerdier", "microbiology_analysis"),
    title = dataset, status = "unknown",
    geography = NA_character_, key_variable = NA_character_,
    modality = NA_character_, opportunity = NA_character_,
    loaded_name = dataset
  )
}

# =============================================================================
# Live dataset profiling
# =============================================================================
load_profiles <- list()
loaded_status_tbl <- tibble::tibble()

live_dataset_targets <- unique(c(
  resource_catalog$dataset, resource_catalog$loaded_name,
  c("patient", "diagnoses_all", "RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL",
    "SDS_epikur", "SDS_ekokur", "SP_VitaleVaerdier", "SP_PatientInfo",
    "SP_Social_Hx", "SP_AlleProvesvar", "SP_OrdineretMedicin",
    "SP_Administreret_Medicin", "SP_ADT_Haendelser",
    "SDS_indberetningmedpris", "SDS_diagnoser", "SDS_kontakter",
    "SDS_t_sksube", "SDS_t_sksopr", "SDS_t_adm", "SDS_tumor_aarlig",
    "SDS_pato", "microbiology_analysis", "microbiology_culture",
    "microbiology_culture_resistance", "microbiology_microscopy",
    "SDS_laboratorieproevesvar", "SDS_dimlaboratoriekoder",
    "PERSIMUNE_biochemistry", "biochemistry",
    "LAB_Flowcytometry", "LAB_IGHVIMGT", "LAB_FISH",
    "LAB_CLLPANEL_WIDE", "LAB_BIOBANK_SAMPLES",
    "CLL_TREAT", "CLL_TREAT_IBRUTINIB",
    "SP_BilleddiagnostikeUndersoegelser_Del1",
    "SP_Behandlingsplaner_del1", "SP_Behandlingsplaner_del2",
    "SP_Journalnotater_Del1", "SP_Journalnotater_Del2",
    "SP_Bloddyrkning_del1", "SP_Bloddyrkning_del2",
    "SP_Bloddyrkning_del3", "SP_Bloddyrkning_del4",
    "SP_ITAOphold", "SP_Flytningshistorik", "SP_Behandlingsniveau",
    "Codes_NPU", "CODES_NPU", "Codes_ATC", "Codes_hospital",
    "Codes_SHAK_long", "shakcomplete", "Codes_kommunekoder")
))

# Two-stage load architecture. Earlier iterations of the cartography hoarded
# every loaded data.frame in `load_profiles[[ds]]` for the entire run, which
# caused R to freeze on a full DALY-CARE extract once the heap exhausted
# physical memory. The two-stage split below replaces hoarding with
# streaming:
#
#   Stage A (lookup-resident):
#     Load the small reference / lookup tables and KEEP them in
#     `load_profiles`. They are tiny (a few thousand rows of code-name
#     pairs at most) and are needed by `npu_lookup`, `atc_lookup`,
#     `lab_site_lookup`, and `shak_table_lookup`, which in turn decorate
#     every downstream summary with human-readable names.
#
#   Stage B (streaming):
#     For every heavy dataset (clinical notes, blood-culture parts,
#     biochemistry, lab measurements, prescription registers, imaging,
#     pathology, ADT, etc.) the loop now LOADS one dataset, RUNS its
#     summariser (which produces a small tibble or list of tibbles),
#     WRITES the resulting CSVs to disk, and then `rm()`s the data and
#     calls `gc()` BEFORE moving on to the next dataset. The data.frame
#     never enters `load_profiles`; only the small summary outputs do.
#     This bounds resident memory at (lookup tables) + (one heavy
#     dataset) + (accumulated small summaries), instead of the previous
#     (all loaded datasets simultaneously).
#
# CARTO_DATASET_SKIP and CARTO_MEMORY_LIMIT_GIB are preserved as
# belt-and-suspenders guards but should rarely be needed under streaming.
.lookup_dataset_targets <- c(
  "Codes_NPU", "CODES_NPU", "CODES_NPU_core", "Codes_ATC", "Codes_ATC_core",
  "Codes_hospital", "Codes_SHAK_long", "shakcomplete", "Codes_kommunekoder"
)
# Streaming targets = everything in live_dataset_targets that is not a lookup.
# Order is preserved (definition order from live_dataset_targets) so that the
# operator's mental model of "what loads when" is unchanged for the heavy
# part of the pipeline. The lookup list above runs first, in its own loop.
.streaming_dataset_targets <- setdiff(live_dataset_targets, .lookup_dataset_targets)
live_dataset_targets <- unique(c(
  intersect(.lookup_dataset_targets, live_dataset_targets),
  .streaming_dataset_targets
))

.skip_raw <- Sys.getenv("CARTO_DATASET_SKIP", unset = "")
.skip_set <- if (nzchar(.skip_raw)) {
  trimws(strsplit(.skip_raw, "[,\\s]+", perl = TRUE)[[1]])
} else {
  character()
}
.mem_limit_gib <- suppressWarnings(as.numeric(
  Sys.getenv("CARTO_MEMORY_LIMIT_GIB", unset = "")
))
if (length(.mem_limit_gib) == 0L || !is.finite(.mem_limit_gib)) .mem_limit_gib <- NA_real_
.session_gib <- function() {
  # gc() returns a matrix; column "(Mb)" / "max used" totals the session's
  # current Vcells + Ncells in MB. Sum across rows to get total MB.
  g <- tryCatch(gc(verbose = FALSE, reset = FALSE), error = function(e) NULL)
  if (is.null(g)) return(NA_real_)
  used_col <- grep("^used \\(Mb\\)$|^\\(Mb\\)$|used \\(MB\\)", colnames(g), value = TRUE)
  if (!length(used_col)) used_col <- colnames(g)[which(colnames(g) %in% c("(Mb)", "used (Mb)"))[1]]
  if (!length(used_col) || is.na(used_col[1])) {
    # Fall back to column 2, which is "(Mb)" in standard R gc() output.
    if (ncol(g) >= 2L) sum(g[, 2L], na.rm = TRUE) / 1024 else NA_real_
  } else {
    sum(g[, used_col[1]], na.rm = TRUE) / 1024
  }
}
if (length(.skip_set)) {
  log_msg("CARTO_DATASET_SKIP active. Will skip: ", paste(.skip_set, collapse = ", "))
}
if (!is.na(.mem_limit_gib)) {
  log_msg("CARTO_MEMORY_LIMIT_GIB=", .mem_limit_gib,
          " GiB. Loop will stop loading further datasets when session memory exceeds this.")
}

n_loaded <- 0L
n_attempted <- 0L
n_streaming_loaded <- 0L
n_streaming_attempted <- 0L
.memory_ceiling_hit <- FALSE
# Track .GlobalEnv objects already claimed by a canonical to catch alias collisions.
.canonical_claims <- new.env(parent = emptyenv())
.record_claim <- function(canonical, loaded_name, addr) {
  prior <- ls(.canonical_claims, all.names = TRUE)
  for (k in prior) {
    rec <- get(k, envir = .canonical_claims)
    if (identical(rec$addr, addr)) return(list(collision = TRUE, prior_canonical = rec$canonical, prior_loaded_name = rec$loaded_name))
  }
  assign(canonical, list(canonical = canonical, loaded_name = loaded_name, addr = addr), envir = .canonical_claims)
  list(collision = FALSE)
}
seen_canonical_targets <- character()
# Stage A: lookup-resident loads. These small reference tables stay in
# load_profiles[[]] so that the lookup-name maps below can build off them.
# The heavy datasets are NOT loaded here - they are streamed in Stage B
# (further down, after the lookup-name maps are constructed).
.lookup_targets_to_load <- intersect(.lookup_dataset_targets, live_dataset_targets)
if (exists("load_dataset", mode = "function", inherits = TRUE)) {
  for (ds in .lookup_targets_to_load) {
    ds_canonical <- canonical_target(ds)
    if (ds_canonical %in% seen_canonical_targets) next
    seen_canonical_targets <- c(seen_canonical_targets, ds_canonical)
    n_attempted <- n_attempted + 1L

    if (ds %in% .skip_set || ds_canonical %in% .skip_set) {
      prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = ds)
      prof$load_status <- "skipped_by_operator"
      loaded_status_tbl <- dplyr::bind_rows(loaded_status_tbl, prof)
      log_msg("Skipped (CARTO_DATASET_SKIP): ", ds_canonical)
      next
    }

    hit <- safe_load_dataset(ds)
    prof <- profile_dataset(hit$data, dataset_name = ds_canonical, loaded_name = hit$name %||% ds)
    if (identical(ds, "t_dalycare_diagnoses")) prof$note <- refresh_notices$detail[refresh_notices$topic == "t_dalycare_diagnoses"]

    # V06 cartography hardening: do not let one lookup masquerade as another
    # (e.g. Codes_NPU resolved to a Codes_ATC object in the failed run).
    if (inherits(hit$data, "data.frame") && !is.na(hit$name %||% NA_character_) &&
        !identical(canonical_target(hit$name), ds_canonical)) {
      warn_loud("Stage A identity mismatch: requested canonical '", ds_canonical,
                "' but resolved object '", hit$name, "' belongs to canonical '",
                canonical_target(hit$name), "'. Refusing this load.")
      prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = hit$name %||% ds)
      prof$note <- paste0("wrong_dataset_identity:", hit$name %||% NA_character_)
      hit$data <- NULL
    }

    # V06 collision check: refuse a second canonical claim on the same object.
    if (inherits(hit$data, "data.frame")) {
      addr <- tryCatch(utils::capture.output(.Internal(inspect(hit$data)))[1L], error = function(e) paste(nrow(hit$data), paste(names(hit$data), collapse = "|")))
      claim <- .record_claim(ds_canonical, hit$name %||% ds, addr)
      if (isTRUE(claim$collision)) {
        warn_loud("Stage A canonical-claim collision: '", ds_canonical, "' would resolve to the same .GlobalEnv object already claimed by '", claim$prior_canonical, "' (loaded as '", claim$prior_loaded_name, "'). Refusing the duplicate claim.")
        prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = ds)
        prof$note <- paste0("collision_with_", claim$prior_canonical)
        hit$data <- NULL
      }
    }

    loaded_status_tbl <- dplyr::bind_rows(loaded_status_tbl, prof)
    if (inherits(hit$data, "data.frame")) {
      load_profiles[[ds_canonical]] <- hit$data
      load_profiles[[ds]] <- hit$data
      n_loaded <- n_loaded + 1L
      log_msg("Stage A (lookup) loaded: ", ds_canonical, " -> rows=", nrow(hit$data),
              " cols=", ncol(hit$data), " status=", hit$status)
    } else {
      log_msg("Stage A (lookup) not loaded: ", ds_canonical, " (status=", hit$status %||% "unknown", ")")
    }
    gc(verbose = FALSE)
    if (!is.na(.mem_limit_gib)) {
      .now_gib <- .session_gib()
      if (is.finite(.now_gib)) {
        log_msg(sprintf("  session memory after gc(): %.1f GiB / limit %.1f GiB",
                        .now_gib, .mem_limit_gib))
      }
    }
  }
  log_msg("Stage A complete: ", n_loaded, " of ", n_attempted, " lookup datasets loaded.")
} else {
  log_msg("load_dataset() unavailable. Stage A skipped; proceeding with baseline-only payload assembly.")
}

if (n_attempted > 0L && n_loaded == 0L && !.memory_ceiling_hit && !length(.skip_set)) {
  warn_loud(
    "Stage A: load_dataset() was available but produced ZERO data.frames across ",
    n_attempted, " lookup-table attempts. The lookup-name maps below will be ",
    "empty, so downstream panels will not have decoded code names. Verify ",
    "load_dataset()'s return type and that DALY-CARE credentials are present ",
    "(e.g. db_access.R)."
  )
}
# NOTE: loaded_status_tbl, atlas_loaded_datasets.csv, and atlas_schema_overview.csv
# are finalised AFTER the Stage B streaming loop below, so that they include
# the heavy datasets too.

get_profile <- function(candidates) {
  for (cand in unique(c(candidates, expand_candidates(candidates)))) {
    obj <- load_profiles[[cand]]
    if (inherits(obj, "data.frame")) return(obj)
  }
  NULL
}

# =============================================================================
# Lookups: NPU + ATC names plus lab-site / SHAK / kommune lookups
# =============================================================================
lookup_name_map <- function(df, code_candidates, name_candidates) {
  if (!inherits(df, "data.frame") || !nrow(df)) return(setNames(character(), character()))
  code_col <- resolve_column(df, code_candidates, partial = TRUE)
  name_col <- resolve_column(df, name_candidates, partial = TRUE)
  if (is.na(code_col) || is.na(name_col)) return(setNames(character(), character()))
  out <- df %>%
    dplyr::transmute(code = normalise_code(.data[[code_col]]),
                     name = as.character(.data[[name_col]])) %>%
    dplyr::filter(!is.na(code), !is.na(name), nzchar(name)) %>%
    dplyr::distinct(code, .keep_all = TRUE)
  stats::setNames(out$name, out$code)
}

npu_lookup <- c(
  lookup_name_map(load_profiles[["Codes_NPU"]], c("code", "npu", "npucode"),
                  c("trivial name", "trivial_name", "name", "component", "short definition", "short")),
  lookup_name_map(load_profiles[["CODES_NPU"]], c("code", "npu", "npucode"),
                  c("trivial name", "trivial_name", "name", "component", "short definition", "short")),
  lookup_name_map(load_profiles[["CODES_NPU_core"]], c("code", "npu", "npucode"),
                  c("trivial name", "trivial_name", "name", "component", "short definition", "short"))
)
atc_lookup <- c(
  lookup_name_map(load_profiles[["Codes_ATC"]], c("atc", "code", "atc_code"),
                  c("name", "drug", "description", "tekst")),
  lookup_name_map(load_profiles[["Codes_ATC_core"]], c("atc", "code", "atc_code"),
                  c("name", "drug", "description", "tekst"))
)
atc_disease_lookup <- stats::setNames(
  ifelse(grepl("^L01", names(atc_lookup)), "Antineoplastic agents",
         ifelse(grepl("^L04", names(atc_lookup)), "Immunosuppressants", NA_character_)),
  names(atc_lookup)
)

# ---- Lab-site decoding for LABKA / PERSIMUNE 3-letter site codes ---------
# These are stable Danish biochemistry-laboratory short codes. A
# hand-maintained map plus a `Codes_hospital` lookup decode them to
# clinician-readable site names.
hardcoded_lab_site_lookup <- c(
  RHB = "Rigshospitalet (Klinisk Biokemi)",
  RH  = "Rigshospitalet",
  HEH = "Herlev Hospital",
  HGH = "Herlev og Gentofte Hospital",
  HI  = "Hvidovre Hospital",
  AHH = "Amager og Hvidovre Hospital",
  BBH = "Bispebjerg Hospital",
  BFH = "Bispebjerg og Frederiksberg Hospitaler",
  NOH = "Nordsjællands Hospital",
  SKS = "Aarhus Universitetshospital, Skejby (Klinisk Biokemi)",
  AUH = "Aarhus Universitetshospital",
  AAS = "Aarhus Sygehus",
  AA  = "Aalborg Universitetshospital",
  ASS = "Aalborg Sygehus Syd",
  OUK = "Odense Universitetshospital (Klinisk Biokemi)",
  OUH = "Odense Universitetshospital",
  ESB = "Sydvestjysk Sygehus, Esbjerg",
  KOL = "Sygehus Lillebælt, Kolding",
  VEJ = "Sygehus Lillebælt, Vejle",
  SVS = "Sydvestjysk Sygehus",
  KPL = "Klinisk Patologi (regional)",
  RSJ = "Region Sjælland (regional reference)",
  RSD = "Region Syddanmark (regional reference)",
  SST = "Statens Serum Institut",
  HOL = "Holbæk Sygehus",
  ROS = "Sjællands Universitetshospital, Roskilde",
  KOG = "Sjællands Universitetshospital, Køge",
  SLA = "Slagelse Sygehus",
  NAE = "Næstved Sygehus",
  NYK = "Nykøbing F Sygehus",
  HIL = "Hillerød (Nordsjællands Hospital)",
  BOH = "Bornholms Hospital",
  UKN = "Unknown / unmapped",
  UKW = "Unknown / unmapped"
)

site_table_lookup <- character()
codes_hospital_df <- get_profile(c("Codes_hospital"))
if (inherits(codes_hospital_df, "data.frame") && nrow(codes_hospital_df) > 0L) {
  site_table_lookup <- lookup_name_map(
    codes_hospital_df,
    c("kortnavn", "shortcode", "code", "kode", "shak", "shakkode", "lab_id", "labid"),
    c("hospital", "navn", "fullname", "name", "sygehus", "klinik", "long_name")
  )
}
lab_site_lookup <- {
  combined <- c(site_table_lookup, hardcoded_lab_site_lookup[setdiff(names(hardcoded_lab_site_lookup), names(site_table_lookup))])
  combined
}

# ---- SHAK code decoding --------------------------------------------------
# SHAK codes are 4–7 character department-level identifiers (e.g. 3800A20).
# First 4 digits are the hospital. We try the canonical lookup table, then a
# small hand-maintained prefix dictionary.
hardcoded_shak_prefix_lookup <- c(
  "1301" = "Rigshospitalet",
  "1311" = "Bispebjerg og Frederiksberg Hospitaler",
  "1316" = "Amager og Hvidovre Hospital",
  "1318" = "Herlev og Gentofte Hospital",
  "1320" = "Nordsjællands Hospital",
  "1330" = "Bornholms Hospital",
  "3800" = "Sjællands Universitetshospital",
  "3801" = "Holbæk Sygehus",
  "3802" = "Næstved, Slagelse og Ringsted Sygehuse",
  "3803" = "Nykøbing F Sygehus",
  "4202" = "Odense Universitetshospital",
  "4203" = "Sygehus Lillebælt",
  "4204" = "Sydvestjysk Sygehus",
  "4205" = "Sygehus Sønderjylland",
  "5500" = "Aarhus Universitetshospital",
  "5501" = "Hospitalsenhed Midt",
  "5502" = "Regionshospital Vest",
  "5503" = "Regionshospital Horsens",
  "5504" = "Regionshospital Randers",
  "6008" = "Aalborg Universitetshospital",
  "6006" = "Vendsyssel/Hjørring",
  "6007" = "Sygehus Thy-Mors"
)
shak_table_lookup <- character()
shak_full_table <- get_profile(c("shakcomplete", "Codes_SHAK_long"))
if (inherits(shak_full_table, "data.frame") && nrow(shak_full_table) > 0L) {
  shak_table_lookup <- lookup_name_map(
    shak_full_table,
    c("shak", "shakkode", "code", "kode"),
    c("hospital", "afdeling", "navn", "name", "sygehus", "long_name", "department")
  )
}
shak_lookup_lookup_fn <- function(shak_code) {
  if (is.na(shak_code) || !nzchar(shak_code)) return(NA_character_)
  norm <- gsub("[^0-9A-Z]", "", toupper(as.character(shak_code)))
  # Full match in the full table first
  if (length(shak_table_lookup) && norm %in% names(shak_table_lookup)) return(unname(shak_table_lookup[norm]))
  # 4-digit hospital prefix
  prefix <- substr(norm, 1L, 4L)
  if (prefix %in% names(hardcoded_shak_prefix_lookup)) return(unname(hardcoded_shak_prefix_lookup[prefix]))
  norm
}

decode_lab_site_name <- function(code) {
  if (is.na(code) || !nzchar(code)) return(NA_character_)
  key <- toupper(as.character(code))
  if (key %in% names(lab_site_lookup)) return(unname(lab_site_lookup[key]))
  key
}

add_names_from_lookup <- function(df, code_col = "code", lookup = character()) {
  if (!inherits(df, "data.frame")) df <- tibble::tibble(code = character(), n = integer())
  df <- tibble::as_tibble(df)
  if (!code_col %in% names(df)) df[[code_col]] <- rep(NA_character_, nrow(df))
  if (!"n" %in% names(df)) df$n <- rep(NA_integer_, nrow(df))
  code_norm <- normalise_code(df[[code_col]])
  if (!length(lookup)) {
    df$name <- code_norm
  } else {
    df$name <- ifelse(code_norm %in% names(lookup), unname(lookup[code_norm]), code_norm)
  }
  df
}

normalise_atlas_table <- function(df, defaults) {
  if (!inherits(df, "data.frame")) df <- tibble::tibble()
  df <- tibble::as_tibble(df); n <- nrow(df)
  for (nm in names(defaults)) if (!nm %in% names(df)) df[[nm]] <- rep(defaults[[nm]], length.out = n)
  df
}

as_top_code_table <- function(df, include_name = TRUE) {
  df <- normalise_atlas_table(df, list(code = NA_character_, name = NA_character_, n = NA_integer_))
  df <- df %>% dplyr::mutate(code = as.character(code),
                             name = dplyr::coalesce(as.character(name), as.character(code)),
                             n = suppressWarnings(as.integer(n)))
  if (isTRUE(include_name)) df %>% dplyr::select(code, name, n) else df %>% dplyr::select(code, n)
}

as_antineo_table <- function(df) {
  df <- normalise_atlas_table(df, list(
    code = NA_character_, drug = NA_character_, disease = NA_character_,
    rows = NA_real_, patients = NA_real_, source = NA_character_))
  df %>% dplyr::mutate(code = as.character(code), drug = as.character(drug),
                       disease = as.character(disease),
                       rows = suppressWarnings(as.numeric(rows)),
                       patients = suppressWarnings(as.numeric(patients)),
                       source = as.character(source)) %>%
    dplyr::select(code, drug, disease, rows, patients, source)
}

# =============================================================================
# Live summarisers
# =============================================================================
# Each function returns either a tibble or a list-of-tibbles in the exact
# shape the atlas HTML expects. Functions that get an empty / unloaded
# input return empty objects — never NULL — so the payload-overlay pattern
# `live %||% baseline` cleanly falls through to the baseline value.

# ---- Diagnosis groups (curated ICD-10 → group label) -----------------------
# Nine curated groups. The mapping is hard-coded here because it is a
# clinical curation (which ICD-10 codes belong together as one "DLBCL
# family"), not a data-derived value.
icd10_curated_groups <- function() {
  list(
    list(id = "plasma-cell-monoclonal-gammopathy-disorders",
         label = "Plasma cell / monoclonal gammopathy disorders",
         members = tibble::tribble(
           ~icd10,    ~danish_sks_code, ~diagnosis,
           "C90.0",   "DC900",          "Multiple myeloma",
           "C90.1",   "DC901",          "Plasma cell leukemia",
           "C90.2",   "DC902",          "Solitary extramedullary plasmacytoma",
           "C90.3",   "DC903",          "Solitary osseous plasmacytoma",
           "D47.2",   "DD472",          "MGUS",
           "E85.8A",  "DE858A",         "AL amyloidosis")),
    list(id = "dlbcl-family", label = "DLBCL family",
         members = tibble::tribble(
           ~icd10,    ~danish_sks_code, ~diagnosis,
           "C83.3",   "DC833",  "Diffuse large B-cell lymphoma",
           "C83.3E",  "DC833E", "Plasmablastic DLBCL")),
    list(id = "cll-mbl-richter", label = "CLL / MBL / Richter",
         members = tibble::tribble(
           ~icd10,   ~danish_sks_code, ~diagnosis,
           "C91.1",  "DC911",  "CLL (B-CLL)",
           "C91.1B", "DC911B", "Richter syndrome",
           "D47.9B", "DD479B", "MBL")),
    list(id = "follicular-lymphoma", label = "Follicular lymphoma",
         members = tibble::tribble(
           ~icd10,  ~danish_sks_code, ~diagnosis,
           "C82.0", "DC820",  "FL grade I",
           "C82.1", "DC821",  "FL grade II",
           "C82.2", "DC822",  "FL grade III",
           "C82.7", "DC827",  "Other FL",
           "C82.9", "DC829",  "FL unspecified")),
    list(id = "t-nk-cell", label = "T/NK-cell lymphoid neoplasms",
         members = tibble::tribble(
           ~icd10,   ~danish_sks_code, ~diagnosis,
           "C84.0",  "DC840",  "Mycosis fungoides",
           "C84.4",  "DC844",  "PTCL-NOS",
           "C84.7",  "DC847",  "ALCL ALK-",
           "C86.5",  "DC865",  "AITL",
           "C91.6",  "DC916",  "T-PLL",
           "C91.7B", "DC917B", "LGL leukemia")),
    list(id = "hodgkin-lymphoma", label = "Hodgkin lymphoma",
         members = tibble::tribble(
           ~icd10,  ~danish_sks_code, ~diagnosis,
           "C81.0", "DC810", "NLPHL",
           "C81.1", "DC811", "NS cHL",
           "C81.2", "DC812", "MC cHL",
           "C81.9", "DC819", "HL unspecified")),
    list(id = "waldenstrom", label = "Waldenström / LPL",
         members = tibble::tribble(
           ~icd10,   ~danish_sks_code, ~diagnosis,
           "C88.0",  "DC880",  "Waldenström macroglobulinemia",
           "C83.0B", "DC830B", "LPL")),
    list(id = "mantle-cell", label = "Mantle cell lymphoma",
         members = tibble::tribble(
           ~icd10,  ~danish_sks_code, ~diagnosis,
           "C83.1", "DC831", "Mantle cell lymphoma")),
    list(id = "marginal-zone", label = "Marginal zone lymphoma",
         members = tibble::tribble(
           ~icd10,   ~danish_sks_code, ~diagnosis,
           "C83.0C", "DC830C", "NMZL",
           "C83.0D", "DC830D", "SMZL",
           "C88.4",  "DC884",  "EMZL",
           "C88.4A", "DC884A", "MALT lymphoma"))
  )
}

summarise_diag_groups <- function(df) {
  groups <- icd10_curated_groups()
  if (!inherits(df, "data.frame") || !nrow(df)) return(groups)  # baseline-shape fallback
  dx_col <- resolve_column(df, c("icd10", "diagnosis", "diagnosekode", "code"), partial = TRUE)
  if (is.na(dx_col)) return(groups)
  vals <- toupper(gsub("\\.", "", as.character(df[[dx_col]])))
  vals <- vals[!is.na(vals) & nzchar(vals)]
  if (!length(vals)) return(groups)
  vals_tab <- table(vals)
  enriched <- lapply(groups, function(g) {
    members <- g$members
    members$icd10_norm <- toupper(gsub("\\.", "", members$icd10))
    members$n <- as.integer(vapply(members$icd10_norm, function(c) {
      n_exact <- if (c %in% names(vals_tab)) as.integer(vals_tab[[c]]) else 0L
      n_prefix <- sum(vapply(names(vals_tab),
                             function(v) startsWith(v, c) && v != c, logical(1L)) *
                      as.integer(vals_tab))
      n_exact + n_prefix
    }, integer(1L)))
    members <- members[order(-members$n), ]
    g$members <- members[, c("danish_sks_code", "icd10", "diagnosis", "n")]
    g$count <- sum(members$n, na.rm = TRUE)
    g$n_codes <- nrow(members)
    g$type <- "group"
    g$icd10_codes <- members$icd10
    g$sks_codes <- members$danish_sks_code
    g
  })
  enriched[order(-vapply(enriched, function(g) g$count %||% 0L, integer(1L)))]
}

# ---- Top ATC codes (overview) ----------------------------------------------
summarise_atc_top <- function(df, top_n = 20L) {
  if (!inherits(df, "data.frame") || !nrow(df)) return(tibble::tibble(code = character(), name = character(), n = integer()))
  atc_col <- resolve_column(df, c("atc", "ATC", "atc_code"), partial = TRUE)
  if (is.na(atc_col)) return(tibble::tibble(code = character(), name = character(), n = integer()))
  summarise_top_codes(df, atc_col, top_n = top_n, clean_fun = normalise_code) %>%
    add_names_from_lookup(lookup = atc_lookup) %>%
    dplyr::select(code, name, n)
}

# ---- DaMyDa deep panel (everything currently in baseline_DATA$damyda) -----
summarise_damyda_panel <- function(df) {
  empty <- list(n_patients = NA_integer_, columns = NA_integer_)
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid", "patient_id"), partial = TRUE)
  pull_top <- function(candidates, n = 10L) {
    col <- resolve_column(df, candidates, partial = TRUE)
    if (is.na(col)) return(tibble::tibble(label = character(), n = integer()))
    summarise_top_labels(df, col, top_n = n)
  }
  reg_field_summary <- function(field_candidates, label, unit = NA_character_) {
    col <- resolve_column(df, field_candidates, partial = TRUE)
    if (is.na(col)) return(NULL)
    vals <- suppressWarnings(as.numeric(df[[col]]))
    non_missing_n <- sum(!is.na(vals))
    pct <- round(100 * non_missing_n / max(nrow(df), 1L), 2)
    examples <- paste(utils::head(stats::na.omit(unique(as.character(df[[col]]))), 2), collapse = " | ")
    stats_block <- if (non_missing_n >= 30) {
      list(n_freq = non_missing_n,
           mean = round(mean(vals, na.rm = TRUE), 2),
           median = round(stats::median(vals, na.rm = TRUE), 2),
           p25 = as.numeric(stats::quantile(vals, 0.25, na.rm = TRUE)),
           p75 = as.numeric(stats::quantile(vals, 0.75, na.rm = TRUE)),
           p05 = as.numeric(stats::quantile(vals, 0.05, na.rm = TRUE)),
           p95 = as.numeric(stats::quantile(vals, 0.95, na.rm = TRUE)))
    } else NULL
    list(field = col, label = label, unit = unit, non_missing_pct = pct,
         non_missing_n = as.integer(non_missing_n),
         missing_n = as.integer(nrow(df) - non_missing_n),
         distinct_sample = as.integer(safe_n_distinct(df[[col]])),
         examples = examples, stats = stats_block)
  }
  region_summary <- {
    col <- resolve_column(df, c("Region", "region", "Reg_Region"), partial = TRUE)
    if (is.na(col)) tibble::tibble(code = character(), name = character(), n = integer()) else {
      labels <- c("1081" = "North Denmark Region", "1082" = "Central Denmark Region",
                  "1083" = "Region of Southern Denmark", "1084" = "Capital Region",
                  "1085" = "Region Zealand", "1099" = "Other/unknown")
      tab <- sort(table(as.character(df[[col]])), decreasing = TRUE)
      tibble::tibble(
        code = names(tab),
        name = ifelse(names(tab) %in% names(labels), unname(labels[names(tab)]), names(tab)),
        n = as.integer(tab))
    }
  }
  out <- list(
    n_patients = if (!is.na(pid_col)) as.integer(safe_n_distinct(df[[pid_col]])) else as.integer(nrow(df)),
    columns = ncol(df),
    stage = pull_top(c("Reg_ISS_Stadie", "ISS", "stage", "stadie"), 10),
    bone_present = pull_top(c("Reg_Knogleforandringer", "knogle_present"), 5),
    bone_type = pull_top(c("Reg_Knogleforandringer_type", "knogle_type"), 6),
    amyloidosis = pull_top(c("Reg_Amyloidose", "amyloidose"), 5),
    treated_flag = pull_top(c("Reg_Behandlet", "treated", "behandlet"), 5),
    relapse_flag = pull_top(c("Reg_Relaps", "relaps", "relapse"), 5),
    followup_flag = pull_top(c("Reg_FollowUp", "followup"), 5),
    primary_response = pull_top(c("Reg_Respons1", "primary_response"), 12),
    secondary_response = pull_top(c("Reg_Respons2", "secondary_response"), 12),
    primary_tx = pull_top(c("Reg_PrimaerBehandling", "primary_tx", "regime"), 14),
    secondary_tx = pull_top(c("Reg_SekundaerBehandling", "secondary_tx"), 14),
    followup_tx = pull_top(c("Reg_OpfBehandling", "followup_tx"), 12),
    primary_comp = pull_top(c("Reg_Komplikationer1", "primary_comp"), 10),
    secondary_comp = pull_top(c("Reg_Komplikationer2", "secondary_comp"), 12),
    followup_comp = pull_top(c("Reg_Komplikationer3", "followup_comp"), 12),
    cyto_fish_done = pull_top(c("Reg_FISH_Udfoert"), 5),
    cyto_iscn = pull_top(c("Reg_ISCN_Resultat", "iscn"), 6),
    cyto_ploidy = pull_top(c("Reg_Ploidi", "ploidy"), 6),
    cyto_abn_top = pull_top(c("Reg_FISH_Abnormitet", "fish_abn"), 14),
    performance_status = pull_top(c("Reg_PerformanceStatus", "performance_status", "ecog"), 6),
    mcomp_type = pull_top(c("Reg_MKomponentType", "mcomp_type", "let_kaede"), 12),
    vertebral_collapse = pull_top(c("Reg_VertebraleKollaps", "vertebral"), 5),
    urine_mcomp = pull_top(c("Reg_UrinMKomponent", "urine_mcomp"), 5),
    imaging_modalities = pull_top(c("Reg_Billeddiagnostik", "imaging"), 8),
    prior_mgus = pull_top(c("Reg_TidligereMGUS", "prior_mgus"), 4),
    charlson = pull_top(c("Charlson", "CCI", "Reg_CharlsonGruppe"), 7),
    regions = region_summary,
    labs = stats::na.omit(list(
      reg_field_summary(c("Reg_Haemoglobin"), "Haemoglobin", "mmol/L"),
      reg_field_summary(c("Reg_Creatinin_mikmoll", "Reg_Creatinin"), "Creatinine", "µmol/L"),
      reg_field_summary(c("Reg_LDH"), "LDH", "U/L"),
      reg_field_summary(c("Reg_CReaktivtProtein_gl", "Reg_CRP"), "CRP", "mg/L"),
      reg_field_summary(c("Reg_IgG_gl"), "IgG", "g/L"),
      reg_field_summary(c("Reg_IgA_gl"), "IgA", "g/L"),
      reg_field_summary(c("Reg_IgM_gl"), "IgM", "g/L"),
      reg_field_summary(c("Reg_Albumin_gl"), "Albumin", "g/L"),
      reg_field_summary(c("Reg_PlasmaMKomponent"), "M-component", "g/L"),
      reg_field_summary(c("Reg_CalciumIoniseret"), "Ionized Ca²⁺", "mmol/L"),
      reg_field_summary(c("Reg_FrieKappaKaeder"), "Free κ chains", "mg/L"),
      reg_field_summary(c("Reg_FrieLambdaKaeder"), "Free λ chains", "mg/L"),
      reg_field_summary(c("Reg_Beta2Microglobulin_gl"), "β2-microglobulin", "mg/L"),
      reg_field_summary(c("Reg_ProcentKlonalePlasmaceller"), "Clonal plasma cells", "%"),
      reg_field_summary(c("Reg_CalciumAlbuminkorrigeret"), "Alb-corrected Ca²⁺", "mmol/L")
    ))
  )
  out$labs <- Filter(Negate(is.null), out$labs)
  out
}

summarise_lyfo_panel <- function(df) {
  empty <- list(n_patients = NA_integer_, columns = NA_integer_)
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid"), partial = TRUE)
  pull_top <- function(candidates, n = 10L) {
    col <- resolve_column(df, candidates, partial = TRUE)
    if (is.na(col)) return(tibble::tibble(label = character(), n = integer()))
    summarise_top_labels(df, col, top_n = n)
  }
  list(
    n_patients = if (!is.na(pid_col)) as.integer(safe_n_distinct(df[[pid_col]])) else as.integer(nrow(df)),
    columns = ncol(df),
    subtypes = pull_top(c("Reg_Subtype", "subtype", "WHO", "lymfomtype"), 18),
    stage = pull_top(c("Reg_AnnArbor", "stage", "stadie", "ann_arbor"), 6),
    ipi = pull_top(c("Reg_IPI", "ipi", "aaipi"), 7),
    b_symptoms = pull_top(c("Reg_BSymptomer", "b_symptoms"), 4),
    performance_status = pull_top(c("Reg_PS", "performance", "ecog"), 6),
    treatment_flag = pull_top(c("Reg_Behandlet", "treatment_flag", "treated"), 4),
    bulk_disease = pull_top(c("Reg_Bulk", "bulk", "bulk_disease"), 4)
  )
}

summarise_cll_registry <- function(df) {
  empty <- list(n_patients = NA_integer_, columns = NA_integer_)
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid"), partial = TRUE)
  pull_top <- function(candidates, n = 10L) {
    col <- resolve_column(df, candidates, partial = TRUE)
    if (is.na(col)) return(tibble::tibble(label = character(), n = integer()))
    summarise_top_labels(df, col, top_n = n)
  }
  list(
    n_patients = if (!is.na(pid_col)) as.integer(safe_n_distinct(df[[pid_col]])) else as.integer(nrow(df)),
    columns = ncol(df),
    binet = pull_top(c("Reg_Binet", "binet", "stage"), 4),
    ighv = pull_top(c("Reg_IGHV", "ighv"), 5),
    fish_overall = pull_top(c("Reg_FISH", "fish"), 4),
    del13q = pull_top(c("Reg_Del13q", "del13q"), 4),
    del11q = pull_top(c("Reg_Del11q", "del11q"), 4),
    del17p = pull_top(c("Reg_Del17p", "del17p", "17p"), 4),
    trisomy12 = pull_top(c("Reg_Tri12", "trisomy12"), 4),
    tp53 = pull_top(c("Reg_TP53", "tp53"), 4),
    treatment_flag = pull_top(c("Reg_Behandlet", "treatment_flag"), 4),
    performance_status = pull_top(c("Reg_PS", "performance"), 6),
    zap70 = pull_top(c("Reg_ZAP70", "zap70"), 4),
    cd38 = pull_top(c("Reg_CD38", "cd38"), 4),
    beta2m = pull_top(c("Reg_Beta2M", "beta2m"), 4)
  )
}

# ---- Treatment plans (SP_Behandlingsplaner_del1) → tx_protocols, tx_lines --
summarise_tx_plans <- function(df) {
  empty <- list(tx_protocols = tibble::tibble(name = character(), n = integer()),
                tx_lines = tibble::tibble(name = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  proto_col <- resolve_column(df, c("protokol_navn", "protocol_name", "protocol", "plan_navn"), partial = TRUE)
  line_col  <- resolve_column(df, c("behandlingslinje", "linje", "treatment_line", "tx_line"), partial = TRUE)
  list(
    tx_protocols = if (!is.na(proto_col)) {
      summarise_top_labels(df, proto_col, top_n = 24L, label_name = "name")
    } else empty$tx_protocols,
    tx_lines = if (!is.na(line_col)) {
      summarise_top_labels(df, line_col, top_n = 14L, label_name = "name")
    } else empty$tx_lines
  )
}

# ---- ADT (SP_ADT_Haendelser) → events, hospitals, types -------------------
summarise_adt <- function(df) {
  empty <- list(adt_events = tibble::tibble(name = character(), n = integer()),
                adt_hospitals = tibble::tibble(name = character(), n = integer()),
                admission_type = tibble::tibble(label = character(), n = integer()),
                patient_class = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  ev_col <- resolve_column(df, c("haendelse", "event_type", "event"), partial = TRUE)
  hosp_col <- resolve_column(df, c("hospital", "hospital_name", "afdeling_navn"), partial = TRUE)
  admt_col <- resolve_column(df, c("admission_type", "admissionstype", "indlaeggelsestype"), partial = TRUE)
  pclass_col <- resolve_column(df, c("patient_class", "patientklasse"), partial = TRUE)
  list(
    adt_events = if (!is.na(ev_col)) summarise_top_labels(df, ev_col, top_n = 10L, label_name = "name") else empty$adt_events,
    adt_hospitals = if (!is.na(hosp_col)) summarise_top_labels(df, hosp_col, top_n = 12L, label_name = "name") else empty$adt_hospitals,
    admission_type = if (!is.na(admt_col)) summarise_top_labels(df, admt_col, top_n = 4L, label_name = "label") else empty$admission_type,
    patient_class = if (!is.na(pclass_col)) summarise_top_labels(df, pclass_col, top_n = 4L, label_name = "label") else empty$patient_class
  )
}

# ---- Administered medicine (SP_Administreret_Medicin) → atc + routes ------
summarise_adm_med <- function(df) {
  empty <- list(adm_med_atc = tibble::tibble(code = character(), name = character(), n = integer()),
                adm_routes = tibble::tibble(name = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  atc_col <- resolve_column(df, c("atc", "atc_code", "laegemiddelatc"), partial = TRUE)
  route_col <- resolve_column(df, c("administrationsvej", "route", "anvendelse"), partial = TRUE)
  atc_top <- if (!is.na(atc_col)) {
    summarise_top_codes(df, atc_col, top_n = 25L, clean_fun = normalise_code) %>%
      add_names_from_lookup(lookup = atc_lookup) %>%
      dplyr::select(code, name, n)
  } else empty$adm_med_atc
  routes <- if (!is.na(route_col)) summarise_top_labels(df, route_col, top_n = 14L, label_name = "name") else empty$adm_routes
  list(adm_med_atc = atc_top, adm_routes = routes)
}

# ---- Note types (SP_Journalnotater_Del1) ----------------------------------
summarise_note_types <- function(df) {
  empty <- tibble::tibble(name = character(), n = integer())
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  nt_col <- resolve_column(df, c("notattype", "note_type", "type", "kategori"), partial = TRUE)
  if (is.na(nt_col)) return(empty)
  summarise_top_labels(df, nt_col, top_n = 20L, label_name = "name")
}

# ---- PERSIMUNE microbiology atlas (analysis / culture / resistance) -------
summarise_persimune_microbiology <- function(profiles) {
  empty <- list(
    analysis = list(sample_material = tibble::tibble(),
                    domain = tibble::tibble(),
                    result_class = tibble::tibble(),
                    institutional = tibble::tibble()),
    culture = list(group = tibble::tibble(), domain = tibble::tibble(), result = tibble::tibble()),
    resistance = list(sir = tibble::tibble())
  )
  out <- empty
  ana <- profiles[["PERSIMUNE_microbiology_analysis"]] %||% profiles[["microbiology_analysis"]]
  if (inherits(ana, "data.frame") && nrow(ana) > 0L) {
    out$analysis$sample_material <- summarise_top_labels(ana,
      resolve_column(ana, c("sample_material", "materiale", "specimen", "sample"), partial = TRUE),
      top_n = 10L, label_name = "label")
    out$analysis$domain <- summarise_top_labels(ana,
      resolve_column(ana, c("domain", "kategori", "category", "type"), partial = TRUE),
      top_n = 8L, label_name = "label")
    out$analysis$result_class <- summarise_top_labels(ana,
      resolve_column(ana, c("result_class", "resultat", "outcome"), partial = TRUE),
      top_n = 8L, label_name = "label")
    out$analysis$institutional <- summarise_top_labels(ana,
      resolve_column(ana, c("hospital", "responsible_lab", "institution"), partial = TRUE),
      top_n = 10L, label_name = "label")
  }
  cul <- profiles[["PERSIMUNE_microbiology_culture"]] %||% profiles[["microbiology_culture"]]
  if (inherits(cul, "data.frame") && nrow(cul) > 0L) {
    out$culture$group <- summarise_top_labels(cul,
      resolve_column(cul, c("culture_group", "group", "kategori"), partial = TRUE),
      top_n = 8L, label_name = "label")
    out$culture$domain <- summarise_top_labels(cul,
      resolve_column(cul, c("domain", "kategori", "category"), partial = TRUE),
      top_n = 6L, label_name = "label")
    out$culture$result <- summarise_top_labels(cul,
      resolve_column(cul, c("culture_result", "result", "resultat"), partial = TRUE),
      top_n = 6L, label_name = "label")
  }
  res <- profiles[["PERSIMUNE_microbiology_culture_resistance"]] %||% profiles[["microbiology_culture_resistance"]]
  if (inherits(res, "data.frame") && nrow(res) > 0L) {
    out$resistance$sir <- summarise_top_labels(res,
      resolve_column(res, c("sir", "susceptibility", "resistance_pattern"), partial = TRUE),
      top_n = 10L, label_name = "label")
  }
  out
}

# ---- SP microbiology (SP_Bloddyrkning_del1..4) ----------------------------
summarise_sp_microbiology <- function(profiles) {
  out <- list(
    specimen_mix = tibble::tibble(label = character(), n = integer()),
    sensitivity_panel = tibble::tibble(label = character(), n = integer()),
    hospital_distribution = tibble::tibble(label = character(), n = integer())
  )
  d1 <- profiles[["SP_Bloddyrkning_del1"]]
  if (inherits(d1, "data.frame") && nrow(d1) > 0L) {
    out$specimen_mix <- summarise_top_labels(d1,
      resolve_column(d1, c("specimen", "materialetype", "sample_type"), partial = TRUE),
      top_n = 10L, label_name = "label")
    out$hospital_distribution <- summarise_top_labels(d1,
      resolve_column(d1, c("hospital", "afsender", "site"), partial = TRUE),
      top_n = 12L, label_name = "label")
  }
  d3 <- profiles[["SP_Bloddyrkning_del3"]]
  if (inherits(d3, "data.frame") && nrow(d3) > 0L) {
    out$sensitivity_panel <- summarise_top_labels(d3,
      resolve_column(d3, c("antibiotic", "antibiotikum", "sens_navn"), partial = TRUE),
      top_n = 14L, label_name = "label")
  }
  out
}

# ---- IGHV / Flow / CLL panel / Biobank ------------------------------------
summarise_ighv <- function(df) {
  empty <- list(n_patients = 0L, mutated = 0L, unmutated = 0L,
                top_alleles = tibble::tibble(label = character(), n = integer()),
                stereotypic_subsets = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid"), partial = TRUE)
  mut_col <- resolve_column(df, c("mutational_status", "mutation_status", "mutated", "ighv_status"), partial = TRUE)
  allele_col <- resolve_column(df, c("ighv_allele", "allele", "v_gene"), partial = TRUE)
  subset_col <- resolve_column(df, c("subset", "stereotypic_subset", "subset_id"), partial = TRUE)
  mutated <- 0L; unmutated <- 0L
  if (!is.na(mut_col)) {
    v <- toupper(trimws(as.character(df[[mut_col]])))
    mutated <- sum(v %in% c("M", "MUTATED", "MUT", "Y"), na.rm = TRUE)
    unmutated <- sum(v %in% c("U", "UNMUTATED", "UNMUT", "N"), na.rm = TRUE)
  }
  list(
    n_patients = if (!is.na(pid_col)) as.integer(safe_n_distinct(df[[pid_col]])) else as.integer(nrow(df)),
    mutated = as.integer(mutated), unmutated = as.integer(unmutated),
    top_alleles = if (!is.na(allele_col)) summarise_top_labels(df, allele_col, 8L, label_name = "label") else empty$top_alleles,
    stereotypic_subsets = if (!is.na(subset_col)) summarise_top_labels(df, subset_col, 8L, label_name = "label") else empty$stereotypic_subsets
  )
}

summarise_flow <- function(df) {
  empty <- list(n_records = 0L,
                material = tibble::tibble(label = character(), n = integer()),
                panel = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  mat_col <- resolve_column(df, c("material", "specimen", "materialetype"), partial = TRUE)
  panel_col <- resolve_column(df, c("panel", "panel_navn", "test_panel"), partial = TRUE)
  list(
    n_records = as.integer(nrow(df)),
    material = if (!is.na(mat_col)) summarise_top_labels(df, mat_col, 8L, label_name = "label") else empty$material,
    panel = if (!is.na(panel_col)) summarise_top_labels(df, panel_col, 10L, label_name = "label") else empty$panel
  )
}

summarise_cll_panel <- function(df) {
  empty <- list(n_patients = 0L,
                driver_counts = tibble::tibble(label = character(), n = integer()),
                binet = tibble::tibble(label = character(), n = integer()),
                fish_status = tibble::tibble(label = character(), n = integer()),
                cll_ipi = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid", "PATIENTID"), partial = TRUE)
  drv_col <- resolve_column(df, c("N.drivers", "n_drivers", "driver_count"), partial = TRUE)
  bin_col <- resolve_column(df, c("Binet", "binet"), partial = TRUE)
  fish_col <- resolve_column(df, c("FISH_status", "FISH", "fish_overall"), partial = TRUE)
  ipi_col <- resolve_column(df, c("CLL_IPI", "ipi"), partial = TRUE)
  list(
    n_patients = if (!is.na(pid_col)) as.integer(safe_n_distinct(df[[pid_col]])) else as.integer(nrow(df)),
    driver_counts = if (!is.na(drv_col)) {
      v <- as.character(df[[drv_col]])
      tab <- sort(table(v), decreasing = FALSE)
      tibble::tibble(label = paste0(names(tab), " driver", ifelse(names(tab) == "1", "", "s")),
                     n = as.integer(tab))
    } else empty$driver_counts,
    binet = if (!is.na(bin_col)) summarise_top_labels(df, bin_col, 4L, label_name = "label") else empty$binet,
    fish_status = if (!is.na(fish_col)) summarise_top_labels(df, fish_col, 8L, label_name = "label") else empty$fish_status,
    cll_ipi = if (!is.na(ipi_col)) summarise_top_labels(df, ipi_col, 5L, label_name = "label") else empty$cll_ipi
  )
}

summarise_biobank <- function(df) {
  empty <- list(total_samples = 0L,
                sources = tibble::tibble(label = character(), n = integer()),
                types = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  src_col <- resolve_column(df, c("source", "biobank_source", "kilde"), partial = TRUE)
  type_col <- resolve_column(df, c("material", "type", "materialetype", "sample_type"), partial = TRUE)
  list(
    total_samples = as.integer(nrow(df)),
    sources = if (!is.na(src_col)) summarise_top_labels(df, src_col, 10L, label_name = "label") else empty$sources,
    types = if (!is.na(type_col)) summarise_top_labels(df, type_col, 12L, label_name = "label") else empty$types
  )
}

# ---- ICU / transfers / DNR (SP_ITAOphold, SP_Flytningshistorik, SP_Behandlingsniveau)
summarise_icu <- function(df) {
  empty <- list(total = 0L, units = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  unit_col <- resolve_column(df, c("ita_unit", "afdeling", "unit"), partial = TRUE)
  list(
    total = as.integer(nrow(df)),
    units = if (!is.na(unit_col)) summarise_top_labels(df, unit_col, 10L, label_name = "label") else empty$units
  )
}

summarise_transfers <- function(df) {
  empty <- list(total = 0L,
                events = tibble::tibble(label = character(), n = integer()),
                hospitals = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  ev_col <- resolve_column(df, c("haendelse", "event"), partial = TRUE)
  hosp_col <- resolve_column(df, c("hospital", "afdeling_navn", "site"), partial = TRUE)
  list(
    total = as.integer(nrow(df)),
    events = if (!is.na(ev_col)) summarise_top_labels(df, ev_col, 10L, label_name = "label") else empty$events,
    hospitals = if (!is.na(hosp_col)) summarise_top_labels(df, hosp_col, 12L, label_name = "label") else empty$hospitals
  )
}

summarise_dnr <- function(df) {
  empty <- list(total = 0L,
                hospitals = tibble::tibble(label = character(), n = integer()),
                regions = tibble::tibble(label = character(), n = integer()))
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  hosp_col <- resolve_column(df, c("hospital", "afdeling"), partial = TRUE)
  reg_col <- resolve_column(df, c("region", "region_navn"), partial = TRUE)
  list(
    total = as.integer(nrow(df)),
    hospitals = if (!is.na(hosp_col)) summarise_top_labels(df, hosp_col, 10L, label_name = "label") else empty$hospitals,
    regions = if (!is.na(reg_col)) summarise_top_labels(df, reg_col, 6L, label_name = "label") else empty$regions
  )
}

# =============================================================================
# Existing summarisers
# =============================================================================
summarise_vitals <- function(df) {
  empty <- list(descriptors = tibble::tibble(), domains = tibble::tibble())
  if (!inherits(df, "data.frame") || !nrow(df)) return(empty)
  pid_col <- resolve_column(df, c("patientid", "patient_id", "dw_ek_borger"), partial = TRUE)
  dt_col <- resolve_column(df, c("dato", "date", "measurementdate", "samplingdate", "tidspunkt"), partial = TRUE)
  desc_col <- resolve_column(df, c("displayname", "parameter", "measure", "name", "komponent", "component", "type"), partial = TRUE)
  val_col <- resolve_column(df, c("value", "vaerdi", "numeric", "numeric_value", "result", "num"), partial = TRUE)
  if (is.na(desc_col)) return(empty)
  dates <- if (!is.na(dt_col)) coerce_date_safe(df[[dt_col]]) else rep(as.Date(NA), nrow(df))
  desc_tbl <- df %>%
    dplyr::transmute(
      name = as.character(.data[[desc_col]]),
      patientid = if (!is.na(pid_col)) as.character(.data[[pid_col]]) else NA_character_,
      date = dates) %>%
    dplyr::filter(!is.na(name), nzchar(name)) %>%
    dplyr::group_by(name) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      patients = if (all(is.na(patientid))) NA_integer_ else dplyr::n_distinct(patientid, na.rm = TRUE),
      from = if (all(is.na(date))) NA_character_ else as.character(min(date, na.rm = TRUE)),
      to = if (all(is.na(date))) NA_character_ else as.character(max(date, na.rm = TRUE)),
      .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(rows)) %>% utils::head(25L)
  domain_from_desc <- function(x) {
    x_low <- tolower(x)
    dplyr::case_when(
      grepl("blodtryk|blood pressure|systol|diastol", x_low) ~ "Blood pressure",
      grepl("puls|pulse|heart", x_low) ~ "Pulse",
      grepl("temp", x_low) ~ "Temperature",
      grepl("saturation|spo2|oxygen", x_low) ~ "Oxygenation",
      grepl("resp", x_low) ~ "Respiration",
      grepl("vægt|vaegt|weight|height|hojde|højde|bmi", x_low) ~ "Anthropometrics",
      TRUE ~ "Other")
  }
  domains_df <- df %>%
    dplyr::transmute(
      domain = domain_from_desc(.data[[desc_col]]),
      patientid = if (!is.na(pid_col)) as.character(.data[[pid_col]]) else NA_character_,
      date = dates,
      value = if (!is.na(val_col)) suppressWarnings(as.numeric(.data[[val_col]])) else NA_real_) %>%
    dplyr::group_by(domain) %>%
    dplyr::summarise(
      rows = dplyr::n(),
      patients = if (all(is.na(patientid))) NA_integer_ else dplyr::n_distinct(patientid, na.rm = TRUE),
      from = if (all(is.na(date))) NA_character_ else as.character(min(date, na.rm = TRUE)),
      to = if (all(is.na(date))) NA_character_ else as.character(max(date, na.rm = TRUE)),
      min = if (all(is.na(value))) NA_real_ else min(value, na.rm = TRUE),
      p05 = if (sum(!is.na(value)) < 5L) NA_real_ else as.numeric(stats::quantile(value, 0.05, na.rm = TRUE)),
      median = if (all(is.na(value))) NA_real_ else stats::median(value, na.rm = TRUE),
      p95 = if (sum(!is.na(value)) < 5L) NA_real_ else as.numeric(stats::quantile(value, 0.95, na.rm = TRUE)),
      max = if (all(is.na(value))) NA_real_ else max(value, na.rm = TRUE),
      .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(rows))
  list(descriptors = desc_tbl, domains = domains_df)
}

summarise_social <- function(df) {
  if (!inherits(df, "data.frame") || !nrow(df)) return(list())
  smoke_col <- resolve_column(df, c("ryger", "rygning", "smoking", "smoker"), partial = TRUE)
  alcohol_col <- resolve_column(df, c("drikker", "alkohol", "alcohol", "genstand"), partial = TRUE)
  pack_col <- resolve_column(df, c("pack", "pakke", "packyears", "pakkeaar"), partial = TRUE)
  count_clean <- function(col) {
    if (is.na(col)) return(tibble::tibble(label = character(), n = integer()))
    vals <- as.character(df[[col]]); vals <- trimws(vals); vals[vals == ""] <- NA_character_
    tab <- sort(table(vals, useNA = "no"), decreasing = TRUE)
    tibble::tibble(label = names(utils::head(tab, 10L)), n = as.integer(utils::head(tab, 10L)))
  }
  list(
    sample_base = nrow(df), smoking = count_clean(smoke_col), drinking = count_clean(alcohol_col),
    pack_years_non_missing = if (!is.na(pack_col)) sum(!is.na(df[[pack_col]])) else NA_integer_,
    pack_years_pct = if (!is.na(pack_col)) round(mean(!is.na(df[[pack_col]])) * 100, 1) else NA_real_)
}

# =============================================================================
# Stage B: streaming summarisers
# =============================================================================
# Each heavy dataset is loaded via safe_load_dataset(), passed through its
# summariser(s), the resulting (small) CSVs are written, and then the
# data.frame is dropped before the next dataset is loaded. The summary
# objects below are pre-initialised to empty defaults so that any dataset
# that fails to load leaves a benign empty value in place; the
# overlay_if_nonempty() pattern further down then keeps the previous
# baseline payload's value in that slot.
log_msg("Running streaming summarisers...")

# ---- Empty defaults for every result the rest of the pipeline reads ----
.empty_top_codes_named <- tibble::tibble(code = character(), name = character(), n = integer())
.empty_top_codes       <- tibble::tibble(code = character(), n = integer())

vitals_focus       <- list(descriptors = tibble::tibble(), domains = tibble::tibble())
social_focus       <- list()
damyda_panel       <- list()
lyfo_panel         <- list()
cll_panel_reg      <- list()
diag_groups        <- tibble::tibble()
atc_top            <- tibble::tibble()
tx_plans           <- list(tx_protocols = tibble::tibble(), tx_lines = tibble::tibble())
adt_summary        <- list(adt_events = tibble::tibble(), adt_hospitals = tibble::tibble(),
                           admission_type = tibble::tibble(), patient_class = tibble::tibble())
adm_med_summary    <- list(adm_med_atc = tibble::tibble(), adm_routes = tibble::tibble())
note_types_summary <- tibble::tibble()
ighv_summary       <- list(n_patients = 0L, mutated = 0L, unmutated = 0L,
                           top_alleles = tibble::tibble(), stereotypic_subsets = tibble::tibble())
flow_summary       <- list(material = tibble::tibble(), panel = tibble::tibble())
cll_panel_lab      <- list(binet = tibble::tibble(), fish_status = tibble::tibble(),
                           cll_ipi = tibble::tibble())
biobank_summary    <- list(sources = tibble::tibble(), types = tibble::tibble())
icu_summary        <- list(units = tibble::tibble())
transfers_summary  <- list(events = tibble::tibble(), hospitals = tibble::tibble())
dnr_summary        <- list(hospitals = tibble::tibble(), regions = tibble::tibble())

labka_top              <- .empty_top_codes_named
labka_by_site          <- tibble::tibble(code = character(), name = character(), n = integer())
sp_lab_top             <- .empty_top_codes_named
persimune_biochem_top  <- .empty_top_codes_named
smr_top                <- .empty_top_codes_named
sp_rx_top              <- .empty_top_codes_named
adm_med_atc_codes      <- .empty_top_codes
pato_top_snomed        <- tibble::tibble(code = character(), name = character(), n = integer())
epikur_atc_top         <- .empty_top_codes_named

imaging_summary <- list(
  ux_top = tibble::tibble(), bwgc_top = tibble::tibble(),
  sksube_total = NA_integer_, sksube_distinct_codes = NA_integer_,
  top_procedure_examples = tibble::tibble(),
  sp_imaging_status = "missing_or_unresolved",
  sp_imaging_note = "No imaging profiling available.",
  paper_total = baseline_DATA$imaging$paper_total %||% 3300000,
  nationwide_source = "SDS_t_sksube",
  ehr_source = "SP_BilleddiagnostiskeUndersogelser_Del1")

# Multi-source accumulators: the per-part data.frames are kept ONLY for as
# long as the streaming loop runs, then summarised once and dropped.
.persimune_micro_acc <- list(analysis = NULL, culture = NULL, resistance = NULL)
.sp_micro_acc        <- list(d1 = NULL, d3 = NULL)
.atc_antineo_parts   <- list()

# ---- count_antineo helper (atc_lookup / atc_disease_lookup are in scope) ----
count_antineo <- function(df, code_col, source_label) {
  empty_tbl <- tibble::tibble(source = character(), code = character(), drug = character(),
                              disease = character(), rows = integer(), patients = integer())
  if (!inherits(df, "data.frame") || is.na(code_col) || !code_col %in% names(df)) return(empty_tbl)
  pid_col <- resolve_column(df, c("patientid", "patient_id", "dw_ek_borger"), partial = TRUE)
  x <- df %>%
    dplyr::transmute(code = normalise_code(.data[[code_col]]),
                     patientid = if (!is.na(pid_col)) as.character(.data[[pid_col]]) else NA_character_) %>%
    dplyr::filter(!is.na(code), grepl("^(L01|L04)", code))
  if (!nrow(x)) return(empty_tbl)
  x %>% dplyr::group_by(code) %>%
    dplyr::summarise(rows = dplyr::n(),
                     patients = if (all(is.na(patientid))) NA_integer_ else dplyr::n_distinct(patientid, na.rm = TRUE),
                     .groups = "drop") %>%
    dplyr::mutate(source = source_label,
                  drug = ifelse(code %in% names(atc_lookup), unname(atc_lookup[code]), NA_character_),
                  disease = ifelse(code %in% names(atc_disease_lookup), unname(atc_disease_lookup[code]), NA_character_)) %>%
    dplyr::select(source, code, drug, disease, rows, patients)
}

# ---- Streaming dispatcher: one loaded data.frame in, small results out ----
.dispatch_streaming <- function(df, ds_canonical) {
  if (!inherits(df, "data.frame") || nrow(df) == 0L) return(invisible(NULL))
  if (ds_canonical == "SP_VitaleVaerdier") {
    vitals_focus <<- summarise_vitals(df)
  } else if (ds_canonical == "SP_Social_Hx") {
    social_focus <<- summarise_social(df)
  } else if (ds_canonical == "RKKP_DaMyDa") {
    damyda_panel <<- summarise_damyda_panel(df)
  } else if (ds_canonical == "RKKP_LYFO") {
    lyfo_panel <<- summarise_lyfo_panel(df)
  } else if (ds_canonical == "RKKP_CLL") {
    cll_panel_reg <<- summarise_cll_registry(df)
  } else if (ds_canonical == "diagnoses_all") {
    diag_groups <<- summarise_diag_groups(df)
  } else if (ds_canonical == "t_dalycare_diagnoses") {
    if (!nrow(diag_groups)) diag_groups <<- summarise_diag_groups(df)
  } else if (ds_canonical == "SP_Behandlingsplaner_del1") {
    tx_plans <<- summarise_tx_plans(df)
  } else if (ds_canonical == "SP_ADT_Haendelser") {
    adt_summary <<- summarise_adt(df)
  } else if (ds_canonical == "SP_Journalnotater_Del1") {
    note_types_summary <<- summarise_note_types(df)
  } else if (ds_canonical == "LAB_IGHVIMGT") {
    ighv_summary <<- summarise_ighv(df)
  } else if (ds_canonical == "LAB_Flowcytometry") {
    flow_summary <<- summarise_flow(df)
  } else if (ds_canonical == "LAB_CLLPANEL_WIDE") {
    cll_panel_lab <<- summarise_cll_panel(df)
  } else if (ds_canonical == "LAB_BIOBANK_SAMPLES") {
    biobank_summary <<- summarise_biobank(df)
  } else if (ds_canonical == "SP_ITAOphold") {
    icu_summary <<- summarise_icu(df)
  } else if (ds_canonical == "SP_Flytningshistorik") {
    transfers_summary <<- summarise_transfers(df)
  } else if (ds_canonical == "SP_Behandlingsniveau") {
    dnr_summary <<- summarise_dnr(df)
  } else if (ds_canonical %in% c("SDS_laboratorieproevesvar", "SDS_lab_forsker", "laboratorymeasurements")) {
    lab_code_col <- resolve_column(df, c("analysiscode", "npu", "labtestcode", "c_analysiscode"), partial = TRUE)
    labka_top <<- summarise_top_codes(df, lab_code_col, top_n = 25L, clean_fun = normalise_code) %>%
      add_names_from_lookup(lookup = npu_lookup)
    site_col <- resolve_column(df, c("labid", "lab_id", "labkode", "lab", "responsible_lab"), partial = TRUE)
    if (!is.na(site_col)) {
      tab <- summarise_top_codes(df, site_col, top_n = 15L,
                                 clean_fun = function(x) toupper(trimws(as.character(x))))
      tab$name <- vapply(tab$code, decode_lab_site_name, character(1))
      labka_by_site <<- tab[, c("code", "name", "n")]
    }
  } else if (ds_canonical == "SP_AlleProvesvar") {
    sp_lab_top <<- summarise_top_codes(df,
      resolve_column(df, c("component", "analysiscode", "npu", "displayname"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code) %>% add_names_from_lookup(lookup = npu_lookup)
  } else if (ds_canonical %in% c("PERSIMUNE_biochemistry", "biochemistry")) {
    persimune_biochem_top <<- summarise_top_codes(df,
      resolve_column(df, c("c_analysiscode", "analysiscode", "component"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code) %>% add_names_from_lookup(lookup = npu_lookup)
  } else if (ds_canonical == "SDS_indberetningmedpris") {
    smr_top <<- summarise_top_codes(df,
      resolve_column(df, c("atc", "atc_code", "laegemiddelatc"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code) %>% add_names_from_lookup(lookup = atc_lookup)
    .atc_antineo_parts[[length(.atc_antineo_parts) + 1L]] <<- count_antineo(
      df, resolve_column(df, c("atc", "atc_code"), partial = TRUE), "SDS_indberetningmedpris")
  } else if (ds_canonical == "SP_OrdineretMedicin") {
    sp_rx_top <<- summarise_top_codes(df,
      resolve_column(df, c("atc", "atc_code", "medicineatc"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code) %>% add_names_from_lookup(lookup = atc_lookup)
    .atc_antineo_parts[[length(.atc_antineo_parts) + 1L]] <<- count_antineo(
      df, resolve_column(df, c("atc", "atc_code"), partial = TRUE), "SP_OrdineretMedicin")
  } else if (ds_canonical == "SP_Administreret_Medicin") {
    adm_med_summary   <<- summarise_adm_med(df)
    adm_med_atc_codes <<- summarise_top_codes(df,
      resolve_column(df, c("atc", "atc_code", "laegemiddelatc"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code)
    .atc_antineo_parts[[length(.atc_antineo_parts) + 1L]] <<- count_antineo(
      df, resolve_column(df, c("atc", "atc_code"), partial = TRUE), "SP_Administreret_Medicin")
  } else if (ds_canonical == "SDS_pato") {
    tab <- summarise_top_codes(df,
      resolve_column(df, c("snomed", "kode", "morfologi", "topografi"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code)
    if (nrow(tab)) tab$name <- tab$code
    pato_top_snomed <<- tab
  } else if (ds_canonical == "SDS_epikur") {
    atc_top        <<- summarise_atc_top(df)
    epikur_atc_top <<- summarise_top_codes(df,
      resolve_column(df, c("atc", "ATC", "atc_code"), partial = TRUE),
      top_n = 25L, clean_fun = normalise_code) %>% add_names_from_lookup(lookup = atc_lookup)
    .atc_antineo_parts[[length(.atc_antineo_parts) + 1L]] <<- count_antineo(
      df, resolve_column(df, c("atc", "ATC", "atc_code"), partial = TRUE), "SDS_epikur")
  } else if (ds_canonical == "SDS_t_sksube") {
    proc_col <- resolve_column(df, c("procedurecode", "sks", "opr", "kode"), partial = TRUE)
    if (!is.na(proc_col)) {
      codes_normalised <- normalise_code(df[[proc_col]])
      top_ux <- tibble::tibble(code = codes_normalised) %>%
        dplyr::filter(!is.na(code), grepl("^UX", code)) %>%
        dplyr::count(code, sort = TRUE, name = "n") %>% utils::head(20L)
      top_bwgc <- tibble::tibble(code = codes_normalised) %>%
        dplyr::filter(!is.na(code), grepl("^BWGC", code)) %>%
        dplyr::count(code, sort = TRUE, name = "n") %>% utils::head(10L)
      .new_imaging <- imaging_summary
      .new_imaging$ux_top <- top_ux
      .new_imaging$bwgc_top <- top_bwgc
      .new_imaging$sksube_total <- nrow(df)
      .new_imaging$sksube_distinct_codes <- dplyr::n_distinct(codes_normalised, na.rm = TRUE)
      .new_imaging$top_procedure_examples <- top_ux %>% utils::head(10L)
      imaging_summary <<- .new_imaging
    }
  } else if (ds_canonical %in% c("SP_BilleddiagnostikeUndersoegelser_Del1",
                                  "SP_BilleddiagnostiskeUndersoegelser_Del1")) {
    .new_imaging <- imaging_summary
    .new_imaging$sp_imaging_status <- "loaded"
    desc_like <- names(df)[grepl("beskrivelse|description|tekst|text|fritekst|pdf|report|rapport",
                                  names(df), ignore.case = TRUE)]
    .new_imaging$sp_imaging_note <- if (length(desc_like)) {
      paste0("Del1 loaded. Description/report-like columns: ", paste(desc_like, collapse = ", "))
    } else "Del1 loaded, but no obvious description/report column was detected."
    imaging_summary <<- .new_imaging
  } else if (ds_canonical %in% c("PERSIMUNE_microbiology_analysis", "microbiology_analysis")) {
    # Compute the small per-part tibbles HERE while the loaded data.frame is
    # still in scope, then store only the small results in the accumulator.
    # Storing `df` itself would keep the full data.frame resident across
    # iterations and defeat streaming.
    .persimune_micro_acc$analysis <<- list(
      sample_material = summarise_top_labels(df,
        resolve_column(df, c("sample_material", "materiale", "specimen", "sample"), partial = TRUE),
        top_n = 10L, label_name = "label"),
      domain          = summarise_top_labels(df,
        resolve_column(df, c("domain", "kategori", "category", "type"), partial = TRUE),
        top_n = 8L, label_name = "label"),
      result_class    = summarise_top_labels(df,
        resolve_column(df, c("result_class", "resultat", "outcome"), partial = TRUE),
        top_n = 8L, label_name = "label"),
      institutional   = summarise_top_labels(df,
        resolve_column(df, c("hospital", "responsible_lab", "institution"), partial = TRUE),
        top_n = 10L, label_name = "label")
    )
  } else if (ds_canonical %in% c("PERSIMUNE_microbiology_culture", "microbiology_culture")) {
    .persimune_micro_acc$culture <<- list(
      group  = summarise_top_labels(df,
        resolve_column(df, c("culture_group", "group", "kategori"), partial = TRUE),
        top_n = 8L, label_name = "label"),
      domain = summarise_top_labels(df,
        resolve_column(df, c("domain", "kategori", "category"), partial = TRUE),
        top_n = 6L, label_name = "label"),
      result = summarise_top_labels(df,
        resolve_column(df, c("culture_result", "result", "resultat"), partial = TRUE),
        top_n = 6L, label_name = "label")
    )
  } else if (ds_canonical %in% c("PERSIMUNE_microbiology_culture_resistance", "microbiology_culture_resistance")) {
    .persimune_micro_acc$resistance <<- list(
      sir = summarise_top_labels(df,
        resolve_column(df, c("sir", "susceptibility", "resistance_pattern"), partial = TRUE),
        top_n = 10L, label_name = "label")
    )
  } else if (ds_canonical == "SP_Bloddyrkning_del1") {
    .sp_micro_acc$d1 <<- list(
      specimen_mix          = summarise_top_labels(df,
        resolve_column(df, c("specimen", "materialetype", "sample_type"), partial = TRUE),
        top_n = 10L, label_name = "label"),
      hospital_distribution = summarise_top_labels(df,
        resolve_column(df, c("hospital", "afsender", "site"), partial = TRUE),
        top_n = 12L, label_name = "label")
    )
  } else if (ds_canonical == "SP_Bloddyrkning_del3") {
    .sp_micro_acc$d3 <<- list(
      sensitivity_panel = summarise_top_labels(df,
        resolve_column(df, c("antibiotic", "antibiotikum", "sens_navn"), partial = TRUE),
        top_n = 14L, label_name = "label")
    )
  }
  invisible(NULL)
}

# ---- Stage B streaming load loop ---------------------------------------
.streaming_targets_to_load <- setdiff(.streaming_dataset_targets, .lookup_dataset_targets)
if (exists("load_dataset", mode = "function", inherits = TRUE)) {
  for (ds in .streaming_targets_to_load) {
    ds_canonical <- canonical_target(ds)
    if (ds_canonical %in% seen_canonical_targets) next
    seen_canonical_targets <- c(seen_canonical_targets, ds_canonical)
    n_streaming_attempted <- n_streaming_attempted + 1L

    if (ds %in% .skip_set || ds_canonical %in% .skip_set) {
      prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = ds)
      prof$load_status <- "skipped_by_operator"
      loaded_status_tbl <- dplyr::bind_rows(loaded_status_tbl, prof)
      log_msg("Skipped (CARTO_DATASET_SKIP): ", ds_canonical)
      next
    }

    if (.memory_ceiling_hit) {
      prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = ds)
      prof$load_status <- "skipped_memory_pressure"
      loaded_status_tbl <- dplyr::bind_rows(loaded_status_tbl, prof)
      log_msg("Skipped (memory pressure ceiling reached earlier): ", ds_canonical)
      next
    }

    # 1. LOAD into a local variable (NOT into load_profiles).
    hit <- safe_load_dataset(ds)
    prof <- profile_dataset(hit$data, dataset_name = ds_canonical, loaded_name = hit$name %||% ds)
    if (inherits(hit$data, "data.frame") && !is.na(hit$name %||% NA_character_) &&
        !identical(canonical_target(hit$name), ds_canonical)) {
      warn_loud("Stage B identity mismatch: requested canonical '", ds_canonical,
                "' but resolved object '", hit$name, "' belongs to canonical '",
                canonical_target(hit$name), "'. Refusing this stream load.")
      prof <- profile_dataset(NULL, dataset_name = ds_canonical, loaded_name = hit$name %||% ds)
      prof$note <- paste0("wrong_dataset_identity:", hit$name %||% NA_character_)
      hit$data <- NULL
    }
    if (identical(ds, "laboratorymeasurements")) prof$note <- refresh_notices$detail[refresh_notices$topic == "laboratorymeasurements"]

    if (identical(ds, "t_dalycare_diagnoses")) prof$note <- refresh_notices$detail[refresh_notices$topic == "t_dalycare_diagnoses"]
    loaded_status_tbl <- dplyr::bind_rows(loaded_status_tbl, prof)

    if (inherits(hit$data, "data.frame")) {
      n_streaming_loaded <- n_streaming_loaded + 1L
      log_msg("Stage B (stream) loaded: ", ds_canonical, " -> rows=", nrow(hit$data),
              " cols=", ncol(hit$data), " status=", hit$status)
      # 2. SUMMARISE: dispatcher writes small results to module-scope vars.
      tryCatch(.dispatch_streaming(hit$data, ds_canonical),
               error = function(e) {
                 log_msg("Stage B summariser FAILED for ", ds_canonical, ": ", conditionMessage(e))
               })
    } else {
      log_msg("Stage B (stream) not loaded: ", ds_canonical, " (status=", hit$status %||% "unknown", ")")
    }

    # 3. DISCARD: drop the heavy data.frame before the next iteration.
    # safe_load_dataset() assign()s the loaded data.frame into .GlobalEnv
    # (Path A: see ~line 611, Path C: ~line 632) or picks it up from
    # .GlobalEnv after load_dataset() side-effected (Path B: ~lines
    # 616-624). In every path the data.frame ends up bound in .GlobalEnv.
    # Without removing that binding here, `rm(hit); gc()` only frees the
    # local alias and the heap grows monotonically across the streaming
    # loop. Drop the binding explicitly. Stage A intentionally leaves its
    # lookup tables resident, so this cleanup is Stage-B only.
    .global_binding <- if (is.list(hit) && !is.null(hit$name)) hit$name else NA_character_
    if (!is.na(.global_binding) && nzchar(.global_binding) &&
        exists(.global_binding, envir = .GlobalEnv, inherits = FALSE)) {
      # Don't accidentally remove a Stage A lookup table if the canonical
      # name happens to collide.
      if (!(.global_binding %in% .lookup_dataset_targets)) {
        rm(list = .global_binding, envir = .GlobalEnv)
      }
    }
    rm(hit, .global_binding)
    gc(verbose = FALSE)

    if (!is.na(.mem_limit_gib)) {
      .now_gib <- .session_gib()
      if (is.finite(.now_gib)) {
        log_msg(sprintf("  session memory after gc(): %.1f GiB / limit %.1f GiB",
                        .now_gib, .mem_limit_gib))
        if (.now_gib > .mem_limit_gib) {
          .memory_ceiling_hit <- TRUE
          warn_loud(sprintf(
            "Session memory %.1f GiB exceeded CARTO_MEMORY_LIMIT_GIB=%.1f GiB after %s. ",
            .now_gib, .mem_limit_gib, ds_canonical),
            "Subsequent datasets in .streaming_dataset_targets will be marked ",
            "skipped_memory_pressure. Under streaming this should rarely fire because ",
            "each dataset is freed before the next one loads; if it does, the ",
            "single largest table on its own already exceeds the limit and the ",
            "limit should be raised.")
        }
      }
    }
  }
  log_msg("Stage B complete: ", n_streaming_loaded, " of ",
          n_streaming_attempted, " streamed datasets loaded and summarised.")
} else {
  log_msg("Stage B skipped because load_dataset() is unavailable.")
}

# ---- Post-Stage-B: aggregations that need >1 part -----------------------
# The per-part accumulators hold the small summary tibbles produced in the
# dispatcher (not the full data.frames), so the final `persimune_micro` /
# `sp_micro` shapes are assembled directly from them.
.empty_persimune_micro <- list(
  analysis = list(sample_material = tibble::tibble(),
                  domain = tibble::tibble(),
                  result_class = tibble::tibble(),
                  institutional = tibble::tibble()),
  culture = list(group = tibble::tibble(), domain = tibble::tibble(), result = tibble::tibble()),
  resistance = list(sir = tibble::tibble())
)
persimune_micro <- .empty_persimune_micro
if (!is.null(.persimune_micro_acc$analysis))   persimune_micro$analysis   <- .persimune_micro_acc$analysis
if (!is.null(.persimune_micro_acc$culture))    persimune_micro$culture    <- .persimune_micro_acc$culture
if (!is.null(.persimune_micro_acc$resistance)) persimune_micro$resistance <- .persimune_micro_acc$resistance

.empty_sp_micro <- list(
  specimen_mix = tibble::tibble(label = character(), n = integer()),
  sensitivity_panel = tibble::tibble(label = character(), n = integer()),
  hospital_distribution = tibble::tibble(label = character(), n = integer())
)
sp_micro <- .empty_sp_micro
if (!is.null(.sp_micro_acc$d1)) {
  if (!is.null(.sp_micro_acc$d1$specimen_mix))          sp_micro$specimen_mix          <- .sp_micro_acc$d1$specimen_mix
  if (!is.null(.sp_micro_acc$d1$hospital_distribution)) sp_micro$hospital_distribution <- .sp_micro_acc$d1$hospital_distribution
}
if (!is.null(.sp_micro_acc$d3)) {
  if (!is.null(.sp_micro_acc$d3$sensitivity_panel))     sp_micro$sensitivity_panel     <- .sp_micro_acc$d3$sensitivity_panel
}
# Drop the accumulated summaries now that we have the final shapes.
.persimune_micro_acc <- list(analysis = NULL, culture = NULL, resistance = NULL)
.sp_micro_acc <- list(d1 = NULL, d3 = NULL)
gc(verbose = FALSE)

# Antineoplastic concordance: union of the per-source contributions.
atc_antineo <- as_antineo_table(tibble::tibble())
if (length(.atc_antineo_parts)) {
  atc_antineo <- dplyr::bind_rows(.atc_antineo_parts) %>%
    dplyr::distinct(source, code, .keep_all = TRUE)
}

# ---- Per-section CSVs ----------------------------------------------------
write_csv_safe(vitals_focus$descriptors, "atlas_vitals_descriptors.csv")
write_csv_safe(vitals_focus$domains, "atlas_vitals_domains.csv")
if (length(social_focus$smoking)) write_csv_safe(social_focus$smoking, "atlas_social_smoking.csv")
if (length(social_focus$drinking)) write_csv_safe(social_focus$drinking, "atlas_social_drinking.csv")
write_csv_safe(tibble::tibble(
  sample_base = social_focus$sample_base %||% NA_integer_,
  pack_years_non_missing = social_focus$pack_years_non_missing %||% NA_integer_,
  pack_years_pct = social_focus$pack_years_pct %||% NA_real_), "atlas_social_summary.csv")
write_csv_safe(tx_plans$tx_protocols, "atlas_tx_protocols.csv")
write_csv_safe(tx_plans$tx_lines, "atlas_tx_lines.csv")
write_csv_safe(adt_summary$adt_events, "atlas_adt_events.csv")
write_csv_safe(adt_summary$adt_hospitals, "atlas_adt_hospitals.csv")
write_csv_safe(adm_med_summary$adm_med_atc, "atlas_adm_med_atc.csv")
write_csv_safe(adm_med_summary$adm_routes, "atlas_adm_routes.csv")
write_csv_safe(note_types_summary, "atlas_note_types.csv")
write_csv_safe(atc_top, "atlas_atc_top.csv")
write_csv_safe(persimune_micro$analysis$institutional, "atlas_persimune_institutional.csv")

write_csv_safe(labka_top, "atlas_labka_top.csv")
write_csv_safe(labka_by_site, "atlas_labka_by_site.csv")
write_csv_safe(sp_lab_top, "atlas_sp_lab_top.csv")
write_csv_safe(persimune_biochem_top, "atlas_persimune_biochem_top.csv")
write_csv_safe(smr_top, "atlas_smr_top.csv")
write_csv_safe(sp_rx_top, "atlas_sp_rx_top.csv")
write_csv_safe(adm_med_atc_codes, "atlas_sp_admin_med_top_atc.csv")
write_csv_safe(pato_top_snomed, "atlas_pato_top_snomed.csv")
write_csv_safe(epikur_atc_top, "atlas_epikur_top_atc.csv")

write_csv_safe(imaging_summary$ux_top, "atlas_imaging_ux_top.csv")
write_csv_safe(imaging_summary$bwgc_top, "atlas_imaging_bwgc_top.csv")
write_csv_safe(tibble::tibble(
  sksube_total = imaging_summary$sksube_total,
  sksube_distinct_codes = imaging_summary$sksube_distinct_codes,
  sp_imaging_status = imaging_summary$sp_imaging_status,
  sp_imaging_note = imaging_summary$sp_imaging_note,
  paper_total = imaging_summary$paper_total,
  nationwide_source = imaging_summary$nationwide_source,
  ehr_source = imaging_summary$ehr_source), "atlas_imaging_summary.csv")
write_csv_safe(atc_antineo, "atlas_atc_antineoplastic_concordance.csv")

# ---- Finalise loaded_status_tbl now that BOTH stages have appended -----
loaded_status_tbl <- loaded_status_tbl %>%
  dplyr::distinct(name, .keep_all = TRUE) %>% dplyr::arrange(name)
write_csv_safe(loaded_status_tbl, "atlas_loaded_datasets.csv")
write_csv_safe(loaded_status_tbl %>% dplyr::select(name, rows, cols, id_col, date_col, layout),
               "atlas_schema_overview.csv")

# Total-pipeline silent-failure check (now correctly counts both stages).
.n_total_attempted <- n_attempted + n_streaming_attempted
.n_total_loaded    <- n_loaded + n_streaming_loaded
if (.n_total_attempted > 0L && .n_total_loaded == 0L && !.memory_ceiling_hit && !length(.skip_set)) {
  warn_loud(
    "load_dataset() was available but produced ZERO data.frames across ",
    .n_total_attempted, " dataset attempts. This is a silent-failure mode: ",
    "verify load_dataset()'s return type and that DALY-CARE credentials ",
    "are present (e.g. db_access.R)."
  )
}
log_msg("Pipeline summary: Stage A loaded ", n_loaded, "/", n_attempted,
        " lookup tables; Stage B loaded ", n_streaming_loaded, "/",
        n_streaming_attempted, " streamed datasets.")

if (n_streaming_attempted > 0L && n_streaming_loaded == 0L &&
    !as_logical_env("CARTO_ALLOW_ZERO_STREAM", default = FALSE)) {
  stop("Cartography loaded ZERO streamed datasets out of ", n_streaming_attempted,
       ". This indicates a dead/stale DALY-CARE loader, network/backend outage, ",
       "or missing credentials. Refusing to create a near-empty atlas payload. ",
       "Set CARTO_ALLOW_ZERO_STREAM=TRUE only for deliberate offline/baseline testing.",
       call. = FALSE)
}


# =============================================================================
# Optional DB enumeration / detective archive / consensus dictionary
# =============================================================================
full_schema_tbl <- tibble::tibble()
part4_summary <- tibble::tibble()
hidden_tables <- tibble::tibble()

try_db_enumeration <- function() {
  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("RPostgres", quietly = TRUE)) return(NULL)
  un <- Sys.info()[["user"]]; pw <- NULL
  db_access_path <- paste0("/ngc/people/", un, "/db_access.R")
  if (file.exists(db_access_path)) {
    local_env <- new.env(parent = emptyenv())
    tryCatch(source(db_access_path, local = local_env), error = function(e) NULL)
    if (exists("pw", envir = local_env, inherits = FALSE)) pw <- get("pw", envir = local_env)
  }
  if (is.null(pw) || !nzchar(pw)) return(NULL)
  schemas <- list(
    list(db = "import", schema = "public"), list(db = "import", schema = "laboratory"),
    list(db = "import", schema = "_lookup_tables"), list(db = "core", schema = "public"),
    list(db = "core", schema = "curated"), list(db = "core", schema = "_lookup_tables"))
  connect_one <- function(dbname, schema) {
    option_path <- paste0("-c search_path=", schema)
    tryCatch(DBI::dbConnect(RPostgres::Postgres(), dbname = dbname, host = "kb-dalyca-01.hpc.cld",
                            port = 5432, user = un, password = pw, options = option_path),
             error = function(e) NULL)
  }
  rows <- list()
  for (s in schemas) {
    con <- connect_one(s$db, s$schema)
    if (is.null(con)) next
    tabs <- tryCatch(DBI::dbListTables(con), error = function(e) character())
    if (length(tabs)) {
      rows[[length(rows) + 1L]] <- tibble::tibble(db = s$db, schema = s$schema, table = tabs,
                                                  ref = paste0(s$db, ".", s$schema, ".", tabs))
    }
    tryCatch(DBI::dbDisconnect(con), error = function(e) NULL)
  }
  if (!length(rows)) return(NULL)
  dplyr::bind_rows(rows)
}

full_schema_tbl <- tryCatch(try_db_enumeration(), error = function(e) NULL) %||% tibble::tibble()
if (nrow(full_schema_tbl)) {
  write_csv_safe(full_schema_tbl, "atlas_full_schema.csv")
  known_tbls <- unique(unlist(lapply(unique(c(resource_catalog$dataset, resource_catalog$loaded_name)),
                                     expand_candidates), use.names = FALSE))
  known_tbls_fold <- unique(ascii_fold(known_tbls))
  hidden_tables <- full_schema_tbl %>%
    dplyr::filter(!(ascii_fold(table) %in% known_tbls_fold)) %>%
    dplyr::transmute(table = table, db = paste(db, schema, sep = "."))
  write_csv_safe(hidden_tables, "atlas_hidden_tables.csv")
  targeted <- tibble::tribble(
    ~name, ~patterns, ~domain, ~desc, ~priority,
    "SDS_t_doedsaarsag", "SDS_t_dodsaarsag_2|SDS_doedsaarsag_3|SDS_t_doedsaarsag", "SDS", "Cause-of-death alias family", "high",
    "SP_Aktive_Problemliste_Diagnoser", "SP_AktiveProblemlisteDiagnoser|SP_Aktive_Problemliste_Diagnoser", "SP", "Active problem list diagnoses", "high",
    "SP_Behandlingskontakter_diagnoser", "SP_BehandlingskontakterOgDiagnoser|SP_Behandlingskontakter_diagnoser", "SP", "Treatment contacts and diagnoses", "high",
    "SP_BilleddiagnostikeUndersoegelser_Del1", "BilleddiagnostiskeUnders.+Del1|BilleddiagnostikeUnders.+Del1", "SP", "Imaging metadata", "high",
    "SP_BilleddiagnostikeUndersoegelser_Del2", "BilleddiagnostiskeUnders.+Del2|BilleddiagnostikeUnders.+Del2", "SP", "Imaging free-text", "high",
    "LAB_FISH", "FISH|fish|cytogen", "Laboratory", "FISH cytogenetics", "medium",
    "DANRICHT", "DANRICHT|richter", "Curated", "Richter cohort", "medium")
  part4_summary <- targeted %>% dplyr::rowwise() %>%
    dplyr::mutate(status = if (sum(grepl(patterns, full_schema_tbl$table, ignore.case = TRUE)) > 0L)
                            "resolved_or_found" else "absent_or_unresolved") %>%
    dplyr::ungroup() %>% dplyr::select(name, domain, desc, status, priority)
  write_csv_safe(part4_summary, "atlas_part4_summary.csv")
}

# Detective source enrichment (ZIP or unpacked directory)
source_rank_key <- function(member_name) {
  x <- basename(member_name)
  m1 <- stringr::str_match(x, "(20[0-9]{6})[_ ]?([0-9]{4,6})")
  if (!all(is.na(m1[1, 2:3]))) return(paste0(m1[1,2], stringr::str_pad(m1[1,3], 6, pad = "0")))
  m2 <- stringr::str_match(x, "(20[0-9]{6})")
  if (!is.na(m2[1,2])) return(paste0(m2[1,2], "000000"))
  x
}

list_source_members <- function(source, pattern) {
  if (is.na(source) || !file.exists(source)) return(character())
  if (dir.exists(source)) {
    hits <- list.files(source, pattern = pattern, recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
    hits <- hits[!grepl("cecilie|Cecilie", hits)]
    return(unique(hits[file.exists(hits)]))
  }
  if (grepl("\\.zip$", source, ignore.case = TRUE)) {
    members <- tryCatch(utils::unzip(source, list = TRUE)$Name, error = function(e) character())
    hits <- members[grepl(pattern, members, ignore.case = TRUE)]
    hits <- hits[!grepl("cecilie|Cecilie", hits)]
    return(unique(hits))
  }
  character()
}

latest_source_member <- function(source, pattern) {
  hits <- list_source_members(source, pattern)
  if (!length(hits)) return(NA_character_)
  if (dir.exists(source)) {
    info <- file.info(hits)
    return(hits[order(vapply(hits, source_rank_key, character(1)), info$mtime, decreasing = TRUE, na.last = TRUE)][[1]])
  }
  hits[[order(vapply(hits, source_rank_key, character(1)), decreasing = TRUE)[1]]]
}

read_archive_csv <- function(archive, pattern) {
  if (is.na(archive) || !file.exists(archive)) return(tibble::tibble())
  hit <- latest_source_member(archive, pattern)
  if (is.na(hit)) return(tibble::tibble())
  if (dir.exists(archive)) {
    return(tryCatch(readr::read_csv(hit, show_col_types = FALSE), error = function(e) tibble::tibble()))
  }
  tmp <- tempfile(fileext = ".csv"); on.exit(unlink(tmp), add = TRUE)
  utils::unzip(archive, files = hit, exdir = dirname(tmp))
  extracted <- file.path(dirname(tmp), hit)
  if (!file.exists(extracted)) return(tibble::tibble())
  tryCatch(readr::read_csv(extracted, show_col_types = FALSE), error = function(e) tibble::tibble())
}

coverage_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "10_coverage_heatmap_scenarios\\.csv$")
lab_source_summary_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "00_lab_source_summary\\.csv$")
generic_recoverability_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "44_mspike_generic_isotype_recovery\\.csv$")
isotype_class_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "41_class_v8_summary\\.csv$")
isotype_venn_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "42_venn_plasma_vs_urine\\.csv$|qc_isotype_venn\\.csv$")
provenance_tbl <- read_archive_csv(DETECTIVE_ARCHIVE_PATH, "60_provenance\\.csv$")

if (nrow(coverage_tbl)) write_csv_safe(coverage_tbl, "atlas_npu_detective_coverage.csv")
if (nrow(lab_source_summary_tbl)) write_csv_safe(lab_source_summary_tbl, "atlas_npu_detective_lab_sources.csv")
if (nrow(generic_recoverability_tbl)) write_csv_safe(generic_recoverability_tbl, "atlas_mspike_generic_recoverability.csv")
if (nrow(isotype_class_tbl)) write_csv_safe(isotype_class_tbl, "atlas_isotype_recovery_summary.csv")
if (nrow(isotype_venn_tbl)) write_csv_safe(isotype_venn_tbl, "atlas_isotype_recovery_venn.csv")
if (nrow(provenance_tbl)) write_csv_safe(provenance_tbl, "atlas_isotype_recovery_provenance.csv")

read_archive_candidate_tables <- function(archive) {
  out <- tibble::tibble()
  if (is.na(archive) || !file.exists(archive)) return(out)
  hits <- list_source_members(archive, "20_candidates_.*\\.csv$|candidate.*code.*\\.csv$|atlas_detective_candidate_code_summary\\.csv$")
  if (!length(hits)) return(out)
  rows <- list()
  tmp_dir <- file.path(tempdir(), paste0("atlas_candidates_", stamp))
  dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
  for (hit in hits) {
    p <- hit
    if (!dir.exists(archive) && grepl("\\.zip$", archive, ignore.case = TRUE)) {
      utils::unzip(archive, files = hit, exdir = tmp_dir)
      p <- file.path(tmp_dir, hit)
    }
    if (!file.exists(p)) next
    tbl <- tryCatch(readr::read_csv(p, show_col_types = FALSE), error = function(e) tibble::tibble())
    if (!nrow(tbl)) next
    keep <- intersect(c("analyte_key", "analyte_label", "code", "n_rows", "n_patients",
                        "dict_component", "dict_system", "dict_unit", "rows", "patients",
                        "name", "vector", "clinical_role", "used_v08", "notes"), names(tbl))
    if (!length(keep)) next
    rows[[length(rows) + 1L]] <- tbl[, keep, drop = FALSE]
  }
  if (!length(rows)) return(out)
  dplyr::bind_rows(rows) %>% dplyr::distinct()
}
candidate_code_tbl <- read_archive_candidate_tables(DETECTIVE_ARCHIVE_PATH)
write_csv_safe(candidate_code_tbl, "atlas_detective_candidate_code_summary.csv")

panel_group_from_vector <- function(vector_name) {
  v <- toupper(vector_name %||% "")
  dplyr::case_when(
    grepl("HAEMOGLOBIN|LEUKOCYTE|THROMBO|ERYTHRO", v) ~ "Haematology",
    grepl("IGG_TOTAL|IGA_TOTAL|IGM_TOTAL|IGD_TOTAL|IGE_TOTAL|IGG_SUBCLASS", v) ~ "Immunoglobulins",
    grepl("FREELITE|FLC|KAPPA|LAMBDA", v) ~ "MM/Light chains",
    grepl("MSPIKE|BJP|FREE_HEAVY|NEUROPATHY", v) ~ "MM/M-component",
    grepl("CREATININE|EGFR|ALBUMIN|LDH|B2M", v) ~ "Biochemistry",
    grepl("CALCIUM", v) ~ "MM/Calcium",
    TRUE ~ "Other")
}

npu_panels_grouped_df <- tibble::tibble()
if (!is.na(CONSENSUS_XLSX_PATH) && requireNamespace("readxl", quietly = TRUE)) {
  consensus_df <- tryCatch(readxl::read_xlsx(CONSENSUS_XLSX_PATH, sheet = "Consensus_Dictionary"),
                           error = function(e) tibble::tibble())
  if (nrow(consensus_df)) {
    consensus_df <- consensus_df %>% dplyr::rename_with(~gsub("[^A-Za-z0-9]+", "_", .x))
    code_col <- resolve_column(consensus_df, c("Code"), partial = TRUE)
    vector_col <- resolve_column(consensus_df, c("Consensus_vector"), partial = TRUE)
    name_col <- resolve_column(consensus_df, c("Trivial_name_LabTerm", "Trivial_name"), partial = TRUE)
    role_col <- resolve_column(consensus_df, c("Clinical_role"), partial = TRUE)
    used_col <- resolve_column(consensus_df, c("Used_in_V08_classification"), partial = TRUE)
    notes_col <- resolve_column(consensus_df, c("WoMMen_notes", "Resolution_note"), partial = TRUE)
    if (is.na(code_col) || is.na(vector_col)) {
      warn_loud("Consensus dictionary found but required Code / Consensus vector columns were not resolved; falling back to detective candidate-code tables.")
      npu_panels_grouped_df <- tibble::tibble()
    } else {
      npu_panels_grouped_df <- consensus_df %>%
        dplyr::transmute(
          code = normalise_code(.data[[code_col]]),
          vector = as.character(.data[[vector_col]]),
          name = if (!is.na(name_col)) as.character(.data[[name_col]]) else NA_character_,
          clinical_role = if (!is.na(role_col)) as.character(.data[[role_col]]) else NA_character_,
          used_v08 = if (!is.na(used_col)) as.character(.data[[used_col]]) else NA_character_,
          notes = if (!is.na(notes_col)) as.character(.data[[notes_col]]) else NA_character_) %>%
        dplyr::filter(!is.na(code), !is.na(vector), nzchar(vector)) %>%
        dplyr::mutate(group = panel_group_from_vector(vector))
    }
    if (nrow(npu_panels_grouped_df) && nrow(candidate_code_tbl)) {
      candidate_rollup <- candidate_code_tbl %>%
        dplyr::mutate(code = normalise_code(code)) %>%
        dplyr::group_by(code) %>%
        dplyr::summarise(
          rows = if (all(is.na(n_rows))) NA_real_ else max(n_rows, na.rm = TRUE),
          patients = if (all(is.na(n_patients))) NA_real_ else max(n_patients, na.rm = TRUE),
          .groups = "drop")
      npu_panels_grouped_df <- npu_panels_grouped_df %>% dplyr::left_join(candidate_rollup, by = "code")
    } else if (nrow(npu_panels_grouped_df)) {
      npu_panels_grouped_df$rows <- NA_real_; npu_panels_grouped_df$patients <- NA_real_
    }
    if (nrow(npu_panels_grouped_df)) {
      npu_panels_grouped_df <- npu_panels_grouped_df %>% dplyr::arrange(group, vector, code)
    }
  }
}
if (!nrow(npu_panels_grouped_df) && nrow(candidate_code_tbl)) {
  # Fallback: the consensus workbook is preferred, but a rearranged handoff
  # may only include detective candidate CSVs. Preserve a useful NPU panel sheet
  # instead of writing a zero-byte/empty file.
  cc <- candidate_code_tbl
  if (!"code" %in% names(cc)) cc$code <- NA_character_
  if (!"analyte_label" %in% names(cc)) cc$analyte_label <- if ("name" %in% names(cc)) cc$name else NA_character_
  if (!"n_rows" %in% names(cc)) cc$n_rows <- if ("rows" %in% names(cc)) cc$rows else NA_real_
  if (!"n_patients" %in% names(cc)) cc$n_patients <- if ("patients" %in% names(cc)) cc$patients else NA_real_
  npu_panels_grouped_df <- cc %>%
    dplyr::mutate(
      .fallback_vector = if ("vector" %in% names(cc)) as.character(.data[["vector"]]) else as.character(.data[["analyte_label"]]),
      .fallback_role = if ("clinical_role" %in% names(cc)) as.character(.data[["clinical_role"]]) else NA_character_,
      .fallback_used = if ("used_v08" %in% names(cc)) as.character(.data[["used_v08"]]) else NA_character_,
      .fallback_notes = if ("notes" %in% names(cc)) as.character(.data[["notes"]]) else "Fallback from detective candidate-code CSV; unified consensus workbook not found."
    ) %>%
    dplyr::transmute(
      code = normalise_code(.data[["code"]]),
      vector = .data[[".fallback_vector"]],
      name = as.character(.data[["analyte_label"]]),
      clinical_role = .data[[".fallback_role"]],
      used_v08 = .data[[".fallback_used"]],
      notes = .data[[".fallback_notes"]],
      rows = suppressWarnings(as.numeric(.data[["n_rows"]])),
      patients = suppressWarnings(as.numeric(.data[["n_patients"]])),
      group = panel_group_from_vector(ifelse(is.na(vector), "", vector))
    ) %>%
    dplyr::filter(!is.na(code), nzchar(code)) %>%
    dplyr::distinct()
}
write_csv_safe(npu_panels_grouped_df, "atlas_npu_panels_grouped.csv")

# Antineoplastic concordance: produced by the streaming dispatcher above
# (see Stage B). The data sources (SDS_epikur, SDS_indberetningmedpris,
# SP_OrdineretMedicin, SP_Administreret_Medicin) are no longer in
# load_profiles[[]] at this point, so this block can no longer be a
# fresh computation; `atc_antineo` is already populated from the
# .atc_antineo_parts accumulator. The CSV write also already happened.

# =============================================================================
# Region coverage rows + recommendations panel + resource catalog refresh
# =============================================================================
# Declarative region_coverage_rows table. Note that the codes embedded in
# the labels are the official Danmarks Statistik codes (Capital=1084,
# Zealand=1085, South=1083, Central=1082, North=1081).
region_coverage_rows <- baseline_RCR
if (is.null(region_coverage_rows) || NROW(region_coverage_rows) == 0L) {
  region_coverage_rows <- list(
    list(domain = "Population & demography (CPR)",
         "Capital Region" = "nationwide", "Region Zealand" = "nationwide",
         "Region of Southern Denmark" = "nationwide", "Central Denmark Region" = "nationwide",
         "North Denmark Region" = "nationwide"),
    list(domain = "Hospital admissions / contacts (LPR / LPR3 via SDS)",
         "Capital Region" = "nationwide", "Region Zealand" = "nationwide",
         "Region of Southern Denmark" = "nationwide", "Central Denmark Region" = "nationwide",
         "North Denmark Region" = "nationwide"),
    list(domain = "Vital signs and observations (SP)",
         "Capital Region" = "high", "Region Zealand" = "high",
         "Region of Southern Denmark" = "none", "Central Denmark Region" = "none",
         "North Denmark Region" = "none"),
    list(domain = "Clinical biochemistry (SDS / PERSIMUNE / SP)",
         "Capital Region" = "high", "Region Zealand" = "high",
         "Region of Southern Denmark" = "regional", "Central Denmark Region" = "regional",
         "North Denmark Region" = "regional"),
    list(domain = "Microbiology (PERSIMUNE / SP)",
         "Capital Region" = "high", "Region Zealand" = "high",
         "Region of Southern Denmark" = "moderate", "Central Denmark Region" = "moderate",
         "North Denmark Region" = "moderate"),
    list(domain = "Imaging metadata (SDS_t_sksube + SP imaging)",
         "Capital Region" = "nationwide_codes_plus_SP_text",
         "Region Zealand" = "nationwide_codes_plus_SP_text",
         "Region of Southern Denmark" = "nationwide_codes_only",
         "Central Denmark Region" = "nationwide_codes_only",
         "North Denmark Region" = "nationwide_codes_only"),
    list(domain = "Clinical-quality registries (RKKP)",
         "Capital Region" = "linked", "Region Zealand" = "linked",
         "Region of Southern Denmark" = "linked", "Central Denmark Region" = "linked",
         "North Denmark Region" = "linked")
  )
}

# Refresh the resource catalog from live profiling. Under streaming,
# load_profiles only contains lookup tables (not heavy datasets), so the
# row/col counts must come from loaded_status_tbl, which profile_dataset()
# populated correctly during BOTH Stage A and Stage B.
refresh_resource_catalog <- function(catalog, profiles_tbl) {
  if (!nrow(catalog)) return(catalog)
  rows_for <- function(target_name) {
    if (!nrow(profiles_tbl)) return(list(rows = NA_integer_, cols = NA_integer_, status = "unknown"))
    hit <- profiles_tbl[profiles_tbl$name == target_name, , drop = FALSE]
    if (nrow(hit) == 0L) return(list(rows = NA_integer_, cols = NA_integer_, status = "unknown"))
    status_str <- if ("load_status" %in% names(hit) && !is.na(hit$load_status[[1]])) {
      if (hit$load_status[[1]] == "loaded") "loaded" else hit$load_status[[1]]
    } else "unknown"
    list(rows = hit$rows[[1]], cols = hit$cols[[1]], status = status_str)
  }
  lookup_name <- function(loaded_name, dataset) {
    x <- tryCatch(as.character(loaded_name[[1]]), error = function(e) NA_character_)
    y <- tryCatch(as.character(dataset[[1]]), error = function(e) NA_character_)
    if (is.na(x) || !nzchar(x)) y else x
  }
  catalog %>% dplyr::rowwise() %>%
    dplyr::mutate(.r = list(rows_for(canonical_target(lookup_name(loaded_name, dataset)))),
                  rows = .r$rows, cols = .r$cols, status = .r$status) %>%
    dplyr::ungroup() %>% dplyr::select(-.r)
}
resource_catalog <- refresh_resource_catalog(resource_catalog, loaded_status_tbl)
write_csv_safe(resource_catalog, "atlas_resource_catalog.csv")

# Recommendations — clinical/operational notes
recommendations_tbl <- baseline_DATA$recommendations
if (is.null(recommendations_tbl) || !length(recommendations_tbl)) {
  recommendations_tbl <- list(
    list(id = "use-canonical-table-names",
         title = "Use SDS-2026-04-23 refreshed table names",
         body = "Switch primary code paths to SDS_laboratorieproevesvar / SDS_dimlaboratoriekoder / SDS_tumor_aarlig / SDS_vaevregistrering. Keep the legacy aliases only as fallbacks."),
    list(id = "add-isotype-recovery",
         title = "Wire WoMMen NPU detective outputs into the cartography",
         body = "Pipe 41_class_v8_summary, 42_venn_plasma_vs_urine, 44_mspike_generic_isotype_recovery, 60_provenance, and 10_coverage_heatmap_scenarios into the lab-detail panels so the atlas reflects current isotype recovery and coverage."),
    list(id = "consume-consensus-dictionary",
         title = "Source NPU groupings from unified_consensus_dictionary.xlsx",
         body = "Replace any inline NPU groupings with the consensus-dictionary projection so the atlas matches WoMMen WP1/WP2/WP3 panels by definition."),
    list(id = "use-payload-not-html",
         title = "Use DALYCARE_atlas_payload.js as the canonical baseline",
         body = "Recent versions of the atlas externalise DATA / ATLAS / REGION_COVERAGE_ROWS to a sibling payload file. Use the payload-first lookup; do not edit inline JSON inside the HTML.")
  )
}

# =============================================================================
# Compose DATA_payload and ATLAS_payload
# =============================================================================
log_msg("Composing payloads…")

DATA_payload <- baseline_DATA

# ---- Always-overwrite: bookkeeping fields the cartography owns -----------
DATA_payload$`__refreshed_at` <- refreshed_at_iso
DATA_payload$`__cartography_version` <- "v06"
DATA_payload$`__cartography_run_dir` <- normalizePath(OUT_DIR, winslash = "/", mustWork = FALSE)

# ---- Loaded-datasets / resource catalog / refresh notices -----------------
loaded_for_payload <- loaded_status_tbl %>%
  dplyr::transmute(name = name, status = load_status, rows = rows, cols = cols,
                   patients = patients, layout = layout,
                   from = date_min, to = date_max, note = note %||% NA_character_)
DATA_payload$loadedDatasets <- if (nrow(loaded_for_payload)) loaded_for_payload else baseline_DATA$loadedDatasets
DATA_payload$resourceCatalog <- if (nrow(resource_catalog)) resource_catalog else baseline_DATA$resourceCatalog
DATA_payload$refresh_notices <- refresh_notices
DATA_payload$recommendations <- recommendations_tbl
DATA_payload$schema_overview <- if (nrow(loaded_status_tbl)) {
  loaded_status_tbl %>% dplyr::select(name, rows, cols, id_col, date_col, layout)
} else baseline_DATA$schema_overview

# ---- New live structures (overlaid only when non-empty) ------------------
overlay_if_nonempty <- function(live, baseline_path) {
  is_empty <- is.null(live) || (is.list(live) && !length(live)) ||
              (inherits(live, "data.frame") && !nrow(live))
  if (is_empty) baseline_path else live
}

DATA_payload$diagGroups <- overlay_if_nonempty(diag_groups, baseline_DATA$diagGroups)
DATA_payload$atcTop     <- overlay_if_nonempty(atc_top,     baseline_DATA$atcTop)
DATA_payload$damyda     <- overlay_if_nonempty(damyda_panel, baseline_DATA$damyda)
DATA_payload$lyfo       <- overlay_if_nonempty(lyfo_panel,   baseline_DATA$lyfo)
DATA_payload$cll_registry <- overlay_if_nonempty(cll_panel_reg, baseline_DATA$cll_registry)
DATA_payload$tx <- overlay_if_nonempty(tx_plans, baseline_DATA$tx)
DATA_payload$adt <- overlay_if_nonempty(adt_summary, baseline_DATA$adt)
DATA_payload$adm_med <- overlay_if_nonempty(adm_med_summary, baseline_DATA$adm_med)
DATA_payload$note_types <- overlay_if_nonempty(note_types_summary, baseline_DATA$note_types)
DATA_payload$persimune_microbiology <- overlay_if_nonempty(persimune_micro, baseline_DATA$persimune_microbiology)
DATA_payload$sp_microbiology <- overlay_if_nonempty(sp_micro, baseline_DATA$sp_microbiology)

# Lab detail panels (lab_detail.{ighv, flowcytometry, cll_panel, biobank, wommen_npu_detective, …})
lab_detail <- baseline_DATA$lab_detail %||% list()
lab_detail$ighv <- overlay_if_nonempty(ighv_summary, lab_detail$ighv)
lab_detail$flowcytometry <- overlay_if_nonempty(flow_summary, lab_detail$flowcytometry)
lab_detail$cll_panel <- overlay_if_nonempty(cll_panel_lab, lab_detail$cll_panel)
lab_detail$biobank <- overlay_if_nonempty(biobank_summary, lab_detail$biobank)
DATA_payload$lab_detail <- lab_detail

# Operations / SP detail (sp_detail.{icu, transfers, dnr, …})
sp_detail <- baseline_DATA$sp_detail %||% list()
sp_detail$icu <- overlay_if_nonempty(icu_summary, sp_detail$icu)
sp_detail$transfers <- overlay_if_nonempty(transfers_summary, sp_detail$transfers)
sp_detail$dnr <- overlay_if_nonempty(dnr_summary, sp_detail$dnr)
DATA_payload$sp_detail <- sp_detail

# ---- Lab top-codes panels --------------------------------------------------
DATA_payload$labka_top <- as_top_code_table(labka_top)
DATA_payload$labka_by_site <- labka_by_site
DATA_payload$sp_lab_top <- as_top_code_table(sp_lab_top)
DATA_payload$persimune_biochem_top <- as_top_code_table(persimune_biochem_top)
DATA_payload$smr_top <- as_top_code_table(smr_top)
DATA_payload$sp_rx_top <- as_top_code_table(sp_rx_top)
DATA_payload$pato_top_snomed <- as_top_code_table(pato_top_snomed)
DATA_payload$epikur_atc_top <- as_top_code_table(epikur_atc_top)

# ---- Vitals + social -------------------------------------------------------
if (nrow(vitals_focus$descriptors)) {
  DATA_payload$vitalDescriptors <- vitals_focus$descriptors
  DATA_payload$vitalDomains <- vitals_focus$domains
}
if (length(social_focus)) DATA_payload$social <- social_focus

# ---- Imaging ---------------------------------------------------------------
DATA_payload$imaging <- list(
  ux_top = imaging_summary$ux_top,
  bwgc_top = imaging_summary$bwgc_top,
  sksube_total = imaging_summary$sksube_total %||% baseline_DATA$imaging$sksube_total,
  sksube_distinct_codes = imaging_summary$sksube_distinct_codes %||% baseline_DATA$imaging$sksube_distinct_codes,
  top_procedure_examples = imaging_summary$top_procedure_examples,
  sp_imaging_status = imaging_summary$sp_imaging_status,
  sp_imaging_note = imaging_summary$sp_imaging_note,
  paper_total = imaging_summary$paper_total,
  nationwide_source = imaging_summary$nationwide_source,
  ehr_source = imaging_summary$ehr_source
)

# ---- Antineoplastic concordance + full schema ----------------------------
DATA_payload$antineoplastic_concordance <- list(atc_cross_source = as_antineo_table(atc_antineo))
if (nrow(full_schema_tbl)) DATA_payload$full_schema <- full_schema_tbl
if (nrow(hidden_tables)) DATA_payload$hidden_tables <- hidden_tables
if (nrow(part4_summary)) DATA_payload$part4_resolved <- part4_summary

# ---- Detective archive + consensus enrichment ---------------------------
if (nrow(coverage_tbl) || nrow(lab_source_summary_tbl)) {
  DATA_payload$lab_detail$wommen_npu_detective <- list(
    coverage = coverage_tbl, lab_sources = lab_source_summary_tbl,
    candidate_summary = candidate_code_tbl)
}
if (nrow(generic_recoverability_tbl) || nrow(isotype_class_tbl) ||
    nrow(isotype_venn_tbl) || nrow(provenance_tbl)) {
  DATA_payload$lab_detail$isotype_recovery <- list(
    generic = generic_recoverability_tbl, class_summary = isotype_class_tbl,
    venn_plasma_urine = isotype_venn_tbl, provenance = provenance_tbl)
}
if (nrow(npu_panels_grouped_df)) DATA_payload$npu_panels_grouped <- npu_panels_grouped_df

# ---- ATLAS_payload (the parallel structure consumed by the second JS const)
ATLAS_payload <- baseline_ATLAS
ATLAS_payload$tx_protocols <- overlay_if_nonempty(tx_plans$tx_protocols, baseline_ATLAS$tx_protocols)
ATLAS_payload$tx_lines <- overlay_if_nonempty(tx_plans$tx_lines, baseline_ATLAS$tx_lines)
ATLAS_payload$adt_events <- overlay_if_nonempty(adt_summary$adt_events, baseline_ATLAS$adt_events)
ATLAS_payload$adt_hospitals <- overlay_if_nonempty(adt_summary$adt_hospitals, baseline_ATLAS$adt_hospitals)
ATLAS_payload$adm_med_atc <- overlay_if_nonempty(adm_med_summary$adm_med_atc, baseline_ATLAS$adm_med_atc)
ATLAS_payload$adm_routes <- overlay_if_nonempty(adm_med_summary$adm_routes, baseline_ATLAS$adm_routes)
ATLAS_payload$note_types <- overlay_if_nonempty(note_types_summary, baseline_ATLAS$note_types)
ATLAS_payload$labka_top <- as_top_code_table(labka_top)
ATLAS_payload$atc_smr <- as_top_code_table(smr_top)
ATLAS_payload$atc_antineo <- as_antineo_table(atc_antineo)
if (nrow(npu_panels_grouped_df)) ATLAS_payload$npu_panels_grouped <- npu_panels_grouped_df
ATLAS_payload$hidden_tables <- if (nrow(hidden_tables)) hidden_tables else baseline_ATLAS$hidden_tables
ATLAS_payload$part4_summary <- if (nrow(part4_summary)) part4_summary else baseline_ATLAS$part4_summary

# =============================================================================
# Region coverage rows
# =============================================================================
region_coverage_rows <- baseline_RCR %||% list(
  list(domain = "RKKP / clinical-quality registries", subdomain = "DaMyDa, LYFO, CLL, AML, MPDS, …",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "yes",
                       `Region of Southern Denmark` = "yes", `Central Denmark Region` = "yes",
                       `North Denmark Region` = "yes")),
  list(domain = "SDS national registries", subdomain = "LPR / LMS / Epikur / SMR / pato / SKS",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "yes",
                       `Region of Southern Denmark` = "yes", `Central Denmark Region` = "yes",
                       `North Denmark Region` = "yes")),
  list(domain = "Sundhedsplatformen (SP / EHR)", subdomain = "Vital signs, prescriptions, notes, imaging",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "yes",
                       `Region of Southern Denmark` = "no", `Central Denmark Region` = "no",
                       `North Denmark Region` = "no")),
  list(domain = "PERSIMUNE laboratory feeds", subdomain = "Microbiology, biochemistry",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "limited",
                       `Region of Southern Denmark` = "no", `Central Denmark Region` = "no",
                       `North Denmark Region` = "no")),
  list(domain = "Curated lab panels (LAB_*)", subdomain = "IGHV, FISH, Flow, CLL panel, biobank",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "limited",
                       `Region of Southern Denmark` = "no", `Central Denmark Region` = "no",
                       `North Denmark Region` = "no")),
  list(domain = "DST geographic linkage", subdomain = "Kommune, region, deprivation",
       coverage = list(`Capital Region` = "yes", `Region Zealand` = "yes",
                       `Region of Southern Denmark` = "yes", `Central Denmark Region` = "yes",
                       `North Denmark Region` = "yes"))
)

# =============================================================================
# Recommendations + final resource catalog refresh
# =============================================================================
recommendations_tbl <- tibble::tribble(
  ~id, ~title, ~detail,
  1, "Run the cartography after each DALY-CARE refresh",
     "Schedule Rscript 000_dalycare_cartography_consolidated.R after the SDS/DALY-CARE refresh; drop the resulting DALYCARE_atlas_payload.js next to the public atlas HTML.",
  2, "Externalise atlas state via DALYCARE_atlas_payload.js",
     "Recent versions of the atlas read DATA, ATLAS, and REGION_COVERAGE_ROWS from this file. Stop hand-editing inline JSON inside the HTML.",
  3, "Decode lab-site / SHAK codes for clinician readability",
     "The cartography ships a hand-maintained dictionary of common LABKA short codes plus a Codes_hospital / shakcomplete join. Validate the decoded names against your local site list and extend the dictionary as needed.",
  4, "Suppress small cells before publishing publicly",
     "Run a suppression pass that masks any aggregate where n < 5 (or your steward's threshold) before the payload leaves DALY-CARE; the cartography produces the raw values intentionally.",
  5, "Fix the kommune→region transposition in wp2_damyda_clinical_enrichment.R",
     "The .wp2_kommune_to_region helper assigns Hovedstaden kommunes to '1081' (should be '1084') and Sjælland to '1082' (should be '1085'). The accompanying patch swaps these to align with Danmarks Statistik."
)
write_csv_safe(recommendations_tbl, "atlas_recommendations.csv")

# `resource_catalog` was already produced above by the canonical-name-aware
# refresh_resource_catalog() call. Reuse it here as `resource_catalog_full`;
# the catalog CSV has already been written. Do NOT redefine
# refresh_resource_catalog() with a non-canonicalising left_join here —
# catalog rows whose `dataset` is a non-canonical alias (e.g.
# "microbiology_analysis", canonical "PERSIMUNE_microbiology_analysis")
# would then fail to join, fall back to NA row counts, and end up with
# status "unknown".
resource_catalog_full <- resource_catalog

# =============================================================================
# Compose DATA + ATLAS payloads (baseline-overlay pattern)
# =============================================================================
# Pattern: each key in DATA / ATLAS is `live_value %||% baseline_value`. If
# this run produced a non-empty live computation, it wins; otherwise we keep
# whatever the previous payload had so the atlas doesn't suddenly lose a
# section because a single dataset failed to load.

is_empty_value <- function(x) {
  if (is.null(x)) return(TRUE)
  if (inherits(x, "data.frame")) return(nrow(x) == 0L)
  if (is.list(x) && length(x) == 0L) return(TRUE)
  FALSE
}
prefer <- function(live, baseline) if (is_empty_value(live)) baseline else live

DATA_payload <- baseline_DATA
DATA_payload$loadedDatasets <- loaded_status_tbl
DATA_payload$resourceCatalog <- resource_catalog_full
DATA_payload$schema_overview <- loaded_status_tbl %>%
  dplyr::select(name, rows, cols, id_col, date_col, layout)
DATA_payload$recommendations <- recommendations_tbl
DATA_payload$refresh_notices <- refresh_notices

DATA_payload$vitalDescriptors <- prefer(vitals_focus$descriptors, baseline_DATA$vitalDescriptors)
DATA_payload$vitalDomains     <- prefer(vitals_focus$domains, baseline_DATA$vitalDomains)
DATA_payload$social <- prefer(list(
  sample_base = social_focus$sample_base,
  smoking = social_focus$smoking, drinking = social_focus$drinking,
  pack_years_non_missing = social_focus$pack_years_non_missing,
  pack_years_pct = social_focus$pack_years_pct
), baseline_DATA$social)

DATA_payload$diagGroups <- prefer(diag_groups, baseline_DATA$diagGroups)
DATA_payload$atcTop <- prefer(atc_top, baseline_DATA$atcTop)

DATA_payload$damyda       <- prefer(damyda_panel, baseline_DATA$damyda)
DATA_payload$lyfo         <- prefer(lyfo_panel, baseline_DATA$lyfo)
DATA_payload$cll_registry <- prefer(cll_panel_reg, baseline_DATA$cll_registry)

DATA_payload$tx <- prefer(tx_plans, baseline_DATA$tx %||% baseline_ATLAS[c("tx_protocols", "tx_lines")])
DATA_payload$adt <- prefer(adt_summary, baseline_DATA$adt)
DATA_payload$adm_med <- prefer(adm_med_summary, baseline_DATA$adm_med)
DATA_payload$note_types <- prefer(note_types_summary, baseline_DATA$note_types)

DATA_payload$persimune_microbiology <- prefer(persimune_micro, baseline_DATA$persimune_microbiology)
DATA_payload$sp_microbiology <- prefer(sp_micro, baseline_DATA$sp_microbiology)

# Lab-detail substructure (IGHV, flow, CLL panel, biobank) — atlas reads from DATA.lab_detail
DATA_payload$lab_detail <- baseline_DATA$lab_detail %||% list()
DATA_payload$lab_detail$ighv <- prefer(ighv_summary, DATA_payload$lab_detail$ighv)
DATA_payload$lab_detail$flowcytometry <- prefer(flow_summary, DATA_payload$lab_detail$flowcytometry)
DATA_payload$lab_detail$cll_panel <- prefer(cll_panel_lab, DATA_payload$lab_detail$cll_panel)
DATA_payload$lab_detail$biobank <- prefer(biobank_summary, DATA_payload$lab_detail$biobank)

# Operations frontier (ICU, transfers, DNR) — atlas reads from DATA.sp_detail
DATA_payload$sp_detail <- baseline_DATA$sp_detail %||% list()
DATA_payload$sp_detail$icu <- prefer(icu_summary, DATA_payload$sp_detail$icu)
DATA_payload$sp_detail$transfers <- prefer(transfers_summary, DATA_payload$sp_detail$transfers)
DATA_payload$sp_detail$dnr <- prefer(dnr_summary, DATA_payload$sp_detail$dnr)

# Imaging
DATA_payload$imaging <- prefer(imaging_summary, baseline_DATA$imaging)

# Lab top-codes
DATA_payload$labka_top <- prefer(as_top_code_table(labka_top), baseline_DATA$labka_top)
DATA_payload$labka_by_site <- prefer(labka_by_site, baseline_DATA$labka_by_site)
DATA_payload$sp_lab_top <- prefer(as_top_code_table(sp_lab_top), baseline_DATA$sp_lab_top)
DATA_payload$persimune_biochem_top <- prefer(as_top_code_table(persimune_biochem_top), baseline_DATA$persimune_biochem_top)
DATA_payload$smr_top <- prefer(as_top_code_table(smr_top), baseline_DATA$smr_top)
DATA_payload$sp_rx_top <- prefer(as_top_code_table(sp_rx_top), baseline_DATA$sp_rx_top)
DATA_payload$pato_top_snomed <- prefer(as_top_code_table(pato_top_snomed), baseline_DATA$pato_top_snomed)

# Schema / hidden tables / part 4
DATA_payload$full_schema <- prefer(full_schema_tbl, baseline_DATA$full_schema)
DATA_payload$hidden_tables <- prefer(hidden_tables, baseline_DATA$hidden_tables)
DATA_payload$part4_resolved <- prefer(part4_summary, baseline_DATA$part4_resolved)

# Antineoplastic concordance (DATA + ATLAS surface both view it)
DATA_payload$antineoplastic_concordance <- list(
  atc_cross_source = prefer(atc_antineo, baseline_DATA$antineoplastic_concordance$atc_cross_source))

# Detective archive enrichments
if (nrow(coverage_tbl)) {
  DATA_payload$wommen_npu_detective <- list(
    coverage = coverage_tbl, lab_sources = lab_source_summary_tbl,
    isotype_class = isotype_class_tbl, isotype_venn = isotype_venn_tbl,
    generic_recoverability = generic_recoverability_tbl, provenance = provenance_tbl)
}
if (nrow(npu_panels_grouped_df)) DATA_payload$npu_panels_grouped <- npu_panels_grouped_df

# Refresh stamp for the atlas freshness banner
DATA_payload$`__refreshed_at` <- refreshed_at_iso
DATA_payload$`__refreshed_by` <- paste0("cartography_v06 / ", Sys.info()[["user"]])
DATA_payload$`__cartography_version` <- "v06"

# ATLAS payload arrays (tx / adt / adm_med plus existing labka / atc_smr / atc_antineo / npu_panels_grouped)
ATLAS_payload <- baseline_ATLAS
ATLAS_payload$tx_protocols <- prefer(tx_plans$tx_protocols, baseline_ATLAS$tx_protocols)
ATLAS_payload$tx_lines     <- prefer(tx_plans$tx_lines, baseline_ATLAS$tx_lines)
ATLAS_payload$adt_events   <- prefer(adt_summary$adt_events, baseline_ATLAS$adt_events)
ATLAS_payload$adt_hospitals <- prefer(adt_summary$adt_hospitals, baseline_ATLAS$adt_hospitals)
ATLAS_payload$adm_med_atc  <- prefer(adm_med_summary$adm_med_atc, baseline_ATLAS$adm_med_atc)
ATLAS_payload$adm_routes   <- prefer(adm_med_summary$adm_routes, baseline_ATLAS$adm_routes)
ATLAS_payload$note_types   <- prefer(note_types_summary, baseline_ATLAS$note_types)
ATLAS_payload$labka_top    <- prefer(as_top_code_table(labka_top), baseline_ATLAS$labka_top)
ATLAS_payload$atc_smr      <- prefer(as_top_code_table(smr_top), baseline_ATLAS$atc_smr)
ATLAS_payload$atc_antineo  <- prefer(as_antineo_table(atc_antineo), baseline_ATLAS$atc_antineo)
ATLAS_payload$npu_panels_grouped <- prefer(npu_panels_grouped_df, baseline_ATLAS$npu_panels_grouped)
ATLAS_payload$`__refreshed_at` <- refreshed_at_iso

# After baseline-overlay composition, rewrite the public CSVs from the
# final payload, not only from live tables. This prevents "empty CSV" handoffs
# when DALY-CARE live loading is partial but the baseline payload carries the
# complete prior atlas state.
as_payload_tibble <- function(x) {
  if (is.null(x)) return(tibble::tibble())
  if (inherits(x, "data.frame")) return(tibble::as_tibble(x))
  if (is.list(x) && length(x)) {
    return(tryCatch(tibble::as_tibble(x), error = function(e) tibble::tibble()))
  }
  tibble::tibble()
}
write_overlay_csv <- function(x, filename) {
  tbl <- as_payload_tibble(x)
  if (nrow(tbl) || length(names(tbl))) write_csv_safe(tbl, filename)
  invisible(tbl)
}
write_overlay_csv(DATA_payload$vitalDescriptors, "atlas_vitals_descriptors.csv")
write_overlay_csv(DATA_payload$vitalDomains, "atlas_vitals_domains.csv")
write_overlay_csv(DATA_payload$labka_top, "atlas_labka_top.csv")
write_overlay_csv(DATA_payload$labka_by_site, "atlas_labka_by_site.csv")
write_overlay_csv(DATA_payload$sp_lab_top, "atlas_sp_lab_top.csv")
write_overlay_csv(DATA_payload$persimune_biochem_top, "atlas_persimune_biochem_top.csv")
write_overlay_csv(DATA_payload$smr_top, "atlas_smr_top.csv")
write_overlay_csv(DATA_payload$sp_rx_top, "atlas_sp_rx_top.csv")
write_overlay_csv(DATA_payload$pato_top_snomed, "atlas_pato_top_snomed.csv")
write_overlay_csv(DATA_payload$epikur_atc_top, "atlas_epikur_top_atc.csv")
write_overlay_csv(DATA_payload$atcTop, "atlas_atc_top.csv")
write_overlay_csv(ATLAS_payload$tx_protocols %||% DATA_payload$tx$tx_protocols, "atlas_tx_protocols.csv")
write_overlay_csv(ATLAS_payload$tx_lines %||% DATA_payload$tx$tx_lines, "atlas_tx_lines.csv")
write_overlay_csv(ATLAS_payload$adt_events %||% DATA_payload$adt$adt_events, "atlas_adt_events.csv")
write_overlay_csv(ATLAS_payload$adt_hospitals %||% DATA_payload$adt$adt_hospitals, "atlas_adt_hospitals.csv")
write_overlay_csv(ATLAS_payload$adm_med_atc %||% DATA_payload$adm_med$adm_med_atc, "atlas_adm_med_atc.csv")
write_overlay_csv(ATLAS_payload$adm_routes %||% DATA_payload$adm_med$adm_routes, "atlas_adm_routes.csv")
write_overlay_csv(ATLAS_payload$note_types %||% DATA_payload$note_types, "atlas_note_types.csv")
write_overlay_csv(DATA_payload$npu_panels_grouped %||% ATLAS_payload$npu_panels_grouped, "atlas_npu_panels_grouped.csv")
write_overlay_csv(DATA_payload$antineoplastic_concordance$atc_cross_source %||% ATLAS_payload$atc_antineo, "atlas_atc_antineoplastic_concordance.csv")

# =============================================================================
# Write payloads
# =============================================================================
log_msg("Writing payloads …")

js_payload <- paste0(
  "// DALYCARE_atlas_payload.js — generated ", refreshed_at_iso, " by cartography.\n",
  "// This file is consumed by DALYCARE_atlas_AOT_V35.html (and onward).\n",
  "// Do not hand-edit; rerun the cartography script to refresh.\n\n",
  "const DATA = ", jsonlite::toJSON(DATA_payload, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null"), ";\n\n",
  "const ATLAS = ", jsonlite::toJSON(ATLAS_payload, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null"), ";\n\n",
  "const REGION_COVERAGE_ROWS = ", jsonlite::toJSON(region_coverage_rows, auto_unbox = TRUE, dataframe = "rows", null = "null", na = "null"), ";\n"
)
writeLines(js_payload, con = file.path(OUT_DIR, "DALYCARE_atlas_payload.js"), useBytes = TRUE)

writeLines(jsonlite::toJSON(DATA_payload, auto_unbox = TRUE, dataframe = "rows",
                            null = "null", na = "null", pretty = TRUE),
           con = file.path(OUT_DIR, "DALYCARE_atlas_payload_data.json"), useBytes = TRUE)
writeLines(jsonlite::toJSON(ATLAS_payload, auto_unbox = TRUE, dataframe = "rows",
                            null = "null", na = "null", pretty = TRUE),
           con = file.path(OUT_DIR, "DALYCARE_atlas_payload_atlas.json"), useBytes = TRUE)

# Workbook bundle
if (requireNamespace("openxlsx", quietly = TRUE)) {
  wb <- openxlsx::createWorkbook()
  add_sheet <- function(name, df) {
    if (!inherits(df, "data.frame") || !nrow(df)) return(invisible(NULL))
    nm <- substr(gsub("[^A-Za-z0-9_]", "_", name), 1L, 31L)
    openxlsx::addWorksheet(wb, nm); openxlsx::writeData(wb, nm, df)
  }
  add_sheet("loaded_datasets", loaded_status_tbl)
  add_sheet("resource_catalog", resource_catalog_full)
  add_sheet("recommendations", recommendations_tbl)
  add_sheet("refresh_notices", refresh_notices)
  add_sheet("labka_top", labka_top)
  add_sheet("labka_by_site", labka_by_site)
  add_sheet("sp_lab_top", sp_lab_top)
  add_sheet("persimune_biochem_top", persimune_biochem_top)
  add_sheet("smr_top", smr_top)
  add_sheet("sp_rx_top", sp_rx_top)
  add_sheet("adm_med_atc", adm_med_summary$adm_med_atc)
  add_sheet("atc_top", atc_top)
  add_sheet("tx_protocols", tx_plans$tx_protocols)
  add_sheet("tx_lines", tx_plans$tx_lines)
  add_sheet("adt_events", adt_summary$adt_events)
  add_sheet("adt_hospitals", adt_summary$adt_hospitals)
  add_sheet("note_types", note_types_summary)
  add_sheet("imaging_ux_top", imaging_summary$ux_top)
  add_sheet("imaging_bwgc_top", imaging_summary$bwgc_top)
  add_sheet("npu_panels_grouped", npu_panels_grouped_df)
  add_sheet("antineoplastic_concord", atc_antineo)
  if (nrow(full_schema_tbl)) add_sheet("full_schema", full_schema_tbl)
  if (nrow(hidden_tables)) add_sheet("hidden_tables", hidden_tables)
  openxlsx::saveWorkbook(wb, file.path(OUT_DIR, "DALYCARE_atlas_data_sheets.xlsx"), overwrite = TRUE)
}

# Manifest
manifest_files <- list.files(OUT_DIR, pattern = "^(atlas_|DALYCARE_atlas_).+", full.names = TRUE)
manifest_tbl <- tibble::tibble(
  file = basename(manifest_files),
  bytes = file.info(manifest_files)$size,
  mtime = format(file.info(manifest_files)$mtime, "%Y-%m-%d %H:%M:%S"))
write_csv_safe(manifest_tbl, "atlas_manifest.csv")

log_msg("Cartography refresh complete. ",
        "Loaded ", (n_loaded + n_streaming_loaded), "/",
        (n_attempted + n_streaming_attempted), " datasets ",
        "(Stage A lookup: ", n_loaded, "/", n_attempted,
        "; Stage B stream: ", n_streaming_loaded, "/", n_streaming_attempted, "). ",
        "Output: ", normalizePath(OUT_DIR, winslash = "/", mustWork = FALSE))
log_msg("=== Cartography finished ===")
