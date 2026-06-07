root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

tracked <- system2(
  "git",
  c("-c", shQuote(paste0("safe.directory=", root)), "ls-files"),
  stdout = TRUE,
  stderr = TRUE
)
expect_true(is.null(attr(tracked, "status")), paste("git ls-files failed:", paste(tracked, collapse = "\n")))

forbidden_patterns <- c(
  "^atlas_runs/",
  "^logs/",
  "^outputs/",
  "^mockups/",
  "^config/cartography-reference/",
  "^config/semantic-unmapped-entity-map[.]tsv$",
  "^config/dalycare_cycle4_curator_label_promotions[.]csv$",
  "^inst/extdata/.*/outputs/",
  "^inst/legacy/.*/site/",
  "^qa_pdsa_cycle",
  "(^|/)DALYCARE_atlas_payload[.]js$",
  "(^|/)site/DALYCARE_atlas.*[.]html$",
  "[.]zip$"
)

forbidden_hits <- tracked[vapply(tracked, function(path) {
  any(vapply(forbidden_patterns, grepl, logical(1), x = path, perl = TRUE))
}, logical(1))]

expect_false(
  length(forbidden_hits) > 0L,
  paste(
    "Generated DALY-CARE aggregate/output artifacts must not be tracked:",
    paste(utils::head(forbidden_hits, 20L), collapse = ", ")
  )
)

ignore_text <- paste(readLines(file.path(root, ".gitignore"), warn = FALSE), collapse = "\n")
for (needle in c(
  "config/cartography-reference/",
  "config/semantic-unmapped-entity-map.tsv",
  "config/dalycare_cycle4_curator_label_promotions.csv",
  "inst/extdata/*/outputs/",
  "inst/legacy/**/site/",
  "qa_pdsa_cycle*/",
  "*.zip",
  "atlas_runs/",
  "outputs/",
  "site/DALYCARE_atlas_payload.js",
  "site/DALYCARE_atlas*.html",
  "mockups/"
)) {
  expect_true(grepl(needle, ignore_text, fixed = TRUE), paste("Expected .gitignore rule:", needle))
}

semantic <- build_semantic_outputs(project_root = root, min_cell_count = 5)
expect_true(all(semantic_dictionary_columns() %in% names(semantic$dictionary)), "Semantic dictionary schema should be available without local cartography artifacts.")
expect_true(all(semantic_value_map_columns() %in% names(semantic$value_map)), "Semantic value-map schema should be available without local cartography artifacts.")
expect_true(all(semantic_code_map_columns() %in% names(semantic$code_map)), "Semantic code-map schema should be available without local cartography artifacts.")
expect_true(all(semantic_panel_links_columns() %in% names(semantic$panel_links)), "Semantic panel-link schema should be available without local cartography artifacts.")

cat("Clean source artifact tests passed\n")
