root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")

extract_regex <- function(pattern, message) {
  match <- regmatches(template, regexpr(pattern, template, perl = TRUE))
  expect_true(length(match) == 1L && nzchar(match), message)
  match
}
position_of <- function(needle, haystack, message) {
  pos <- regexpr(needle, haystack, fixed = TRUE)[[1]]
  expect_true(pos > 0L, message)
  pos
}

damyda_panel <- extract_regex("function renderDaMyDaPanel\\(\\)[\\s\\S]*?function lyfoSummaryRow", "DaMyDa registry panel renderer should be present.")
lyfo_panel <- extract_regex("function renderLYFOPanel\\(\\)[\\s\\S]*?function cllSummaryRow", "LYFO registry panel renderer should be present.")
cll_panel <- extract_regex("function renderCLLPanel\\(\\)[\\s\\S]*?document\\.getElementById\\(\"hero-copy\"\\)", "CLL registry panel renderer should be present.")
damyda_raw <- extract_regex("function renderDaMyDaRawLineage\\(\\)[\\s\\S]*?function renderDaMyDaPanel", "DaMyDa raw lineage renderer should be present.")
lyfo_raw <- extract_regex("function renderLYFORawLineage\\(\\)[\\s\\S]*?function renderLYFOPanel", "LYFO raw lineage renderer should be present.")
cll_raw <- extract_regex("function renderCLLRawLineage\\(\\)[\\s\\S]*?function renderCLLPanel", "CLL raw lineage renderer should be present.")

expect_true(position_of("registry entries", damyda_panel, "DaMyDa should lead with source/coverage KPIs.") < position_of("renderDaMyDaRawLineage()", damyda_panel, "DaMyDa raw lineage should be rendered after summaries."), "DaMyDa raw lineage must not be the first registry-facing block.")
expect_true(position_of("Cytogenetics/FISH availability", damyda_panel, "DaMyDa should include clinical summary sections before raw lineage.") < position_of("renderDaMyDaRawLineage()", damyda_panel, "DaMyDa raw lineage should be rendered after clinical summaries."), "DaMyDa should show clinical summaries before technical lineage.")

expect_true(position_of("Source / coverage", lyfo_panel, "LYFO should lead with source/coverage.") < position_of("renderLYFORawLineage()", lyfo_panel, "LYFO raw lineage should be rendered after summaries."), "LYFO raw lineage must not be the first registry-facing block.")
expect_true(position_of("Subtype mix", lyfo_panel, "LYFO should include clinical summary sections.") < position_of("renderLYFORawLineage()", lyfo_panel, "LYFO raw lineage should be rendered after clinical summaries."), "LYFO should show clinical summaries before technical lineage.")

expect_true(position_of("Source / coverage", cll_panel, "CLL should lead with source/coverage.") < position_of("renderCLLRawLineage()", cll_panel, "CLL raw lineage should be rendered after summaries."), "CLL raw lineage must not be the first registry-facing block.")
expect_true(position_of("Binet stage", cll_panel, "CLL should include clinical summary sections.") < position_of("renderCLLRawLineage()", cll_panel, "CLL raw lineage should be rendered after clinical summaries."), "CLL should show clinical summaries before technical lineage.")

expect_true(grepl("<details class=\"lineage-block\"", damyda_raw, fixed = TRUE), "DaMyDa raw lineage must be inside a technical disclosure.")
expect_true(grepl("Technical lineage / raw cartography rows", damyda_raw, fixed = TRUE), "DaMyDa raw lineage disclosure should be clearly technical.")
expect_true(grepl("<details class=\"lineage-block\"", lyfo_raw, fixed = TRUE), "LYFO raw lineage must be inside a technical disclosure.")
expect_true(grepl("Technical lineage / raw cartography rows", lyfo_raw, fixed = TRUE), "LYFO raw lineage disclosure should be clearly technical.")
expect_true(grepl("<details class=\"lineage-block\"", cll_raw, fixed = TRUE), "CLL raw lineage must be inside a collapsed lineage disclosure.")
expect_true(grepl("<summary>Raw names / data lineage</summary>", cll_raw, fixed = TRUE), "CLL raw lineage should be collapsed under raw names / data lineage.")

expect_true(grepl("patient denominator\", value: hasDisplayValue", template, fixed = TRUE), "Registry panels should distinguish computed patient denominators from uncomputed denominator states.")
expect_true(grepl("not computed for this aggregate block", template, fixed = TRUE), "Registry panels should use precise uncomputed denominator wording.")
expect_true(grepl("date span not reliable in current aggregate output", template, fixed = TRUE), "Registry panels should use precise date-span reliability wording.")
expect_false(grepl("not available patients", template, fixed = TRUE), "Registry panels must not render 'not available patients'.")
