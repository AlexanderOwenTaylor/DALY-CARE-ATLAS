# Single entry point for the DALY-CARE cartography atlas refresh.
# Run from the package root with:
#   source("RUN_CARTOGRAPHY_ATLAS.R")
# or:
#   Rscript RUN_CARTOGRAPHY_ATLAS.R

# ---- Robust path detection (works under both source() and Rscript) ---------
# The previous version relied on `sys.frame(1)$ofile` which is NULL under
# Rscript; the tryCatch fallback to getwd() only works because the .sh wrapper
# does `cd $(dirname $0)` first. This version handles both cases explicitly.
.this_file <- {
  ofile <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
  if (!is.null(ofile) && nzchar(ofile)) {
    normalizePath(ofile, winslash = "/", mustWork = FALSE)
  } else {
    args <- commandArgs(trailingOnly = FALSE)
    fa <- grep("^--file=", args, value = TRUE)
    if (length(fa) > 0L) {
      normalizePath(sub("^--file=", "", fa[1]), winslash = "/", mustWork = FALSE)
    } else {
      NA_character_
    }
  }
}
.package_root <- if (!is.na(.this_file)) {
  dirname(.this_file)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

.cartography_script  <- file.path(.package_root, "WoMMen_code", "code", "000_dalycare_cartography_consolidated.R")
.detective_builder   <- file.path(.package_root, "WoMMen_code", "code", "000_build_detective_archive.R")

if (!file.exists(.cartography_script)) {
  stop("Cannot find canonical cartography script: ", .cartography_script, call. = FALSE)
}

# Bound input discovery to this package unless the operator explicitly overrides.
if (!nzchar(Sys.getenv("CARTO_INPUT_ROOTS", unset = ""))) {
  Sys.setenv(CARTO_INPUT_ROOTS = .package_root)
}
if (!nzchar(Sys.getenv("CARTO_OUT_DIR", unset = ""))) {
  stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  Sys.setenv(CARTO_OUT_DIR = file.path(.package_root, "Other",
                                        paste0("DALYCARE_atlas_refresh_", stamp)))
}

# Default detective archive path: <package>/resources/detective_archive_unpacked.
# The cartography script will pick this up via DETECTIVE_ARCHIVE_PATH.
.detective_dir <- file.path(.package_root, "resources", "detective_archive_unpacked")
dir.create(.detective_dir, recursive = TRUE, showWarnings = FALSE)
if (!nzchar(Sys.getenv("DETECTIVE_ARCHIVE_PATH", unset = ""))) {
  Sys.setenv(DETECTIVE_ARCHIVE_PATH = .detective_dir)
}
if (!nzchar(Sys.getenv("DETECTIVE_OUT_DIR", unset = ""))) {
  Sys.setenv(DETECTIVE_OUT_DIR = .detective_dir)
}

# ============================================================================
# Step 1: build (or refresh) the detective archive
# ============================================================================
# Without this, the cartography reads near-empty CSVs and produces an atlas
# with skeletal lab-detective and isotype-recovery panels. The builder pulls
# from existing WP1 outputs first (cheap), then falls back to live derivation
# from lab_all if load_dataset() is available, then writes the seven CSVs the
# cartography expects.
if (file.exists(.detective_builder)) {
  message("Building detective archive at: ", .detective_dir)
  tryCatch(
    source(.detective_builder, chdir = TRUE),
    error = function(e) {
      message("[WARN] Detective archive build failed: ", conditionMessage(e))
      message("[WARN] Cartography will fall back to baseline payload values for ",
              "the detective and isotype-recovery panels.")
    }
  )
} else {
  message("[WARN] Detective archive builder not found at ", .detective_builder,
          " — cartography panels driven by detective archive will fall through ",
          "to baseline values.")
}

# ============================================================================
# Step 2: cartography
# ============================================================================
message("Running canonical cartography script: ", .cartography_script)
message("CARTO_INPUT_ROOTS=", Sys.getenv("CARTO_INPUT_ROOTS"))
message("CARTO_OUT_DIR=",     Sys.getenv("CARTO_OUT_DIR"))
message("DETECTIVE_ARCHIVE_PATH=", Sys.getenv("DETECTIVE_ARCHIVE_PATH"))
source(.cartography_script, chdir = TRUE)

# ============================================================================
# Step 3: publish the fresh payload into site/
# ============================================================================
# The cartography writes its outputs into CARTO_OUT_DIR — a fresh, timestamped
# folder under Other/. The HTML in site/ loads its data via:
#
#   <script src="DALYCARE_atlas_payload.js"></script>
#
# (see site/DALYCARE_atlas_AOT_V35.html line ~1036), so to refresh the atlas
# we just need to drop the new payload next to the HTML. The timestamped
# folder under Other/ is preserved untouched, so older payloads are archived
# automatically — no need to manage versions by hand.
#
# This step replaces the previous atlas-updater pass
# (001_dalycare_atlas_updater.R, opt-in via WOMMEN_RUN_ATLAS_UPDATER=1), which
# was needed when the HTML still embedded `const DATA = {...}` inline and had
# to be patched in place. Since V35 the HTML loads its data externally, so a
# straight file copy is sufficient and the updater is no longer invoked. The
# updater script is left in WoMMen_code/code/ for archeology but is unused.
.refresh_dir   <- Sys.getenv("CARTO_OUT_DIR", unset = "")
.fresh_payload <- file.path(.refresh_dir, "DALYCARE_atlas_payload.js")
.site_dir      <- file.path(.package_root, "site")
.site_payload  <- file.path(.site_dir, "DALYCARE_atlas_payload.js")
.loaded_csv    <- file.path(.refresh_dir, "atlas_loaded_datasets.csv")

.cartography_load_summary <- function(loaded_csv) {
  if (!file.exists(loaded_csv)) {
    return(list(ok_to_publish = FALSE, loaded = NA_integer_, streamed_loaded = NA_integer_, total = NA_integer_,
                reason = paste0("atlas_loaded_datasets.csv not found at ", loaded_csv)))
  }
  tbl <- tryCatch(utils::read.csv(loaded_csv, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(tbl) || !nrow(tbl)) {
    return(list(ok_to_publish = FALSE, loaded = 0L, streamed_loaded = 0L, total = 0L,
                reason = "atlas_loaded_datasets.csv is empty or unreadable"))
  }
  rows_num <- suppressWarnings(as.numeric(tbl$rows))
  loaded_mask <- !is.na(rows_num) & rows_num > 0
  loaded <- sum(loaded_mask, na.rm = TRUE)
  lookup_names <- c("Codes_NPU", "Codes_ATC", "Codes_SHAK_long", "Codes_hospital",
                    "Codes_kommunekoder", "LAB_IGHVIMGT", "shakcomplete")
  name_chr <- if ("name" %in% names(tbl)) as.character(tbl$name) else rep("", nrow(tbl))
  streamed_loaded <- sum(loaded_mask & !(name_chr %in% lookup_names), na.rm = TRUE)
  ok <- streamed_loaded > 0L
  list(
    ok_to_publish = ok,
    loaded = loaded,
    streamed_loaded = streamed_loaded,
    total = nrow(tbl),
    reason = if (ok) {
      "cartography loaded at least one streamed dataset successfully"
    } else {
      paste0("cartography loaded ZERO streamed datasets (", loaded,
             " lookup/baseline rows loaded) — publish blocked to preserve the previous site/ payload")
    }
  )
}
.cartography_force_publish <- identical(toupper(Sys.getenv("CARTO_FORCE_PUBLISH", unset = "FALSE")), "TRUE")

if (!nzchar(.refresh_dir)) {
  message("[WARN] CARTO_OUT_DIR is unset; cannot publish payload to site/.")
} else if (!file.exists(.fresh_payload)) {
  message("[WARN] No fresh payload at ", .fresh_payload, ".")
  message("[WARN] Cartography may have failed before writing the payload; site/ not updated. The previous payload in site/ is unchanged.")
} else if (!dir.exists(.site_dir)) {
  message("[WARN] site/ directory not found at ", .site_dir, " — payload not published. Fresh payload remains in ", .refresh_dir, ".")
} else {
  load_summary <- .cartography_load_summary(.loaded_csv)
  if (!isTRUE(load_summary$ok_to_publish) && !.cartography_force_publish) {
    message("\n[WARN] Refusing to publish payload to site/ because:")
    message("[WARN]   ", load_summary$reason)
    if (!is.null(load_summary$loaded) && !is.null(load_summary$total)) message("[WARN]   Loaded ", load_summary$loaded, " / ", load_summary$total, " datasets in this run.")
    message("[WARN] The previous payload in site/ is preserved unchanged.")
    message("[WARN] The fresh (degraded) payload remains archived at: ", .fresh_payload)
    message("[WARN] To override, set CARTO_FORCE_PUBLISH=TRUE and re-run RUN_CARTOGRAPHY_ATLAS.R.")
  } else {
    if (!isTRUE(load_summary$ok_to_publish) && .cartography_force_publish) message("[WARN] CARTO_FORCE_PUBLISH=TRUE — publishing despite ", load_summary$reason)
    ok <- file.copy(.fresh_payload, .site_payload, overwrite = TRUE)
    if (isTRUE(ok)) {
      message("Published fresh payload to: ", .site_payload)
      message("Archived copy retained at:   ", .fresh_payload)
      message("To view the refreshed atlas, open site/DALYCARE_atlas_AOT_V35.html in a browser.")
    } else {
      message("[WARN] Failed to copy fresh payload from ", .fresh_payload, " to ", .site_payload, ". Check filesystem permissions.")
    }
  }
}

message("Cartography refresh complete.")
