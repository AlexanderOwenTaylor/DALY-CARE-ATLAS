root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

read_snapshot_numbers <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  keys <- c(
    "top_level_tabs", "sub_tabs", "panels", "details_sections",
    "source_catalog_rows", "data_dictionary_rows", "resource_reconciliation_rows",
    "payload_top_level_keys", "mcl_triangle_data_point_rows",
    "output_csv_files", "rendered_export_links"
  )
  out <- setNames(integer(length(keys)), keys)
  for (key in keys) {
    pattern <- paste0("\"", key, "\"\\s*:\\s*([0-9]+)")
    hit <- regexec(pattern, txt, perl = TRUE)
    value <- regmatches(txt, hit)[[1]]
    if (length(value) < 2) stop(paste("Snapshot key missing:", key), call. = FALSE)
    out[[key]] <- as.integer(value[[2]])
  }
  out
}

count_pattern <- function(text, pattern) {
  hit <- gregexpr(pattern, text, perl = TRUE)[[1]]
  if (identical(hit, -1L)) 0L else length(hit)
}

count_csv_rows <- function(path) {
  if (!file.exists(path)) return(0L)
  max(0L, length(readLines(path, warn = FALSE)) - 1L)
}

count_root_json_keys <- function(json) {
  chars <- strsplit(json, "", fixed = TRUE)[[1]]
  depth <- 0L
  count <- 0L
  i <- 1L
  while (i <= length(chars)) {
    ch <- chars[[i]]
    if (ch == "{") {
      depth <- depth + 1L
      i <- i + 1L
    } else if (ch == "}") {
      depth <- depth - 1L
      i <- i + 1L
    } else if (ch == "\"" && depth == 1L) {
      j <- i + 1L
      escaped <- FALSE
      while (j <= length(chars)) {
        if (escaped) {
          escaped <- FALSE
        } else if (chars[[j]] == "\\") {
          escaped <- TRUE
        } else if (chars[[j]] == "\"") {
          break
        }
        j <- j + 1L
      }
      k <- j + 1L
      while (k <= length(chars) && grepl("\\s", chars[[k]])) k <- k + 1L
      if (k <= length(chars) && chars[[k]] == ":") count <- count + 1L
      i <- k + 1L
    } else {
      i <- i + 1L
    }
  }
  count
}

before <- read_snapshot_numbers(file.path(root, "qa_pdsa_cycle2", "preservation_snapshot_before.json"))
after <- read_snapshot_numbers(file.path(root, "qa_pdsa_cycle2", "preservation_snapshot_after.json"))

for (key in names(before)) {
  expect_true(after[[key]] >= before[[key]], paste("Cycle 2 snapshot must not decrease:", key))
}

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
actual_static <- c(
  top_level_tabs = count_pattern(template, "class=\"tab-page"),
  sub_tabs = count_pattern(template, "class=\"sub-tab"),
  panels = count_pattern(template, "class=\"panel"),
  details_sections = count_pattern(template, "<details"),
  rendered_export_links = count_pattern(template, "data-export-view")
)
for (key in names(actual_static)) {
  expect_true(actual_static[[key]] >= after[[key]], paste("Rendered template count below Cycle 2 snapshot:", key))
}

out_root <- tempfile("pdsa_cycle2_preservation_")
result <- run_atlas(
  project_root = root,
  source_map_path = file.path(root, "config", "source-map.example.tsv"),
  output_root = out_root,
  mode = "report"
)

empty_sources <- data.frame(table_name = character(), load_status = character(), stringsAsFactors = FALSE)
empty_columns <- data.frame(table_name = character(), column_name = character(), stringsAsFactors = FALSE)
empty_checks <- data.frame(severity = character(), table_name = character(), check_id = character(), message = character(), stringsAsFactors = FALSE)
payload_shape <- atlas_payload("preservation-shape", "now", empty_sources, empty_columns, empty_checks, panels = list())

actual_generated <- c(
  source_catalog_rows = count_csv_rows(file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv")),
  data_dictionary_rows = count_csv_rows(file.path(result$run_dir, "outputs", "atlas_semantic_data_dictionary.csv")),
  resource_reconciliation_rows = count_csv_rows(file.path(result$run_dir, "outputs", "atlas_resource_reconciliation.csv")),
  payload_top_level_keys = length(names(payload_shape)),
  mcl_triangle_data_point_rows = count_csv_rows(file.path(result$run_dir, "outputs", "mcl_triangle_data_point_counts.csv")),
  output_csv_files = length(list.files(file.path(result$run_dir, "outputs"), pattern = "\\.(csv|tsv)$", recursive = TRUE))
)
for (key in names(actual_generated)) {
  expect_true(actual_generated[[key]] >= after[[key]], paste("Generated output count below Cycle 2 snapshot:", key))
}

closeAllConnections()
