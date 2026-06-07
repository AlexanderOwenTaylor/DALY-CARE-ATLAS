root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

safe_dir_arg <- paste0("safe.directory=", shQuote(root, type = "cmd"))
tracked <- system2("git", c("-c", safe_dir_arg, "ls-files"), stdout = TRUE, stderr = TRUE)
status <- attr(tracked, "status")
expect_true(is.null(status), "git ls-files should succeed for the current checkout.")

forbidden_patterns <- c(
  "^config/cartography-reference/",
  "^config/semantic-unmapped-entity-map[.]tsv$",
  "^config/dalycare_cycle4_curator_label_promotions[.]csv$",
  "^inst/extdata/.*/outputs/",
  "^inst/legacy/.*/site/",
  "^qa_pdsa_cycle",
  "(^|/)DALYCARE_atlas_payload[.]js$",
  "[.]zip$"
)

for (pattern in forbidden_patterns) {
  expect_false(any(grepl(pattern, tracked, perl = TRUE)), paste("Tracked generated artifact matched:", pattern))
}

ignore_text <- paste(readLines(file.path(root, ".gitignore"), warn = FALSE), collapse = "\n")
for (rule in c(
  "*.zip",
  "outputs/",
  "site/DALYCARE_atlas_payload.js",
  "site/DALYCARE_atlas*.html",
  "config/cartography-reference/",
  "config/semantic-unmapped-entity-map.tsv",
  "config/dalycare_cycle4_curator_label_promotions.csv",
  "inst/extdata/*/outputs/",
  "inst/legacy/**/site/",
  "qa_pdsa_cycle*/"
)) {
  expect_true(grepl(rule, ignore_text, fixed = TRUE), paste(".gitignore should include:", rule))
}

semantic <- build_semantic_outputs(project_root = root)
for (name in c("dictionary", "value_map", "code_map", "panel_links", "unmapped_entity_overlay")) {
  expect_true(is.data.frame(semantic[[name]]), paste("Semantic output should be a data frame:", name))
}

message("Clean source artifact tests passed")
