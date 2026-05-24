root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

top_values <- data.frame(
  table_name = rep("t_dalycare_diagnoses", 4),
  column_name = rep("diagnosis_code", 4),
  value = c("DC911", "DD479B", "DD472", "DC900"),
  n = c(12831, 193, 4840, 29472),
  pct_rows = c(10, 1, 4, 20),
  stringsAsFactors = FALSE
)

outputs <- build_confluence_feasibility_outputs(
  project_root = root,
  sources = data.frame(
    table_name = c("RKKP_CLL", "RKKP_DaMyDa", "PERSIMUNE_Microbiology", "SP_BloodCulture"),
    domain = c("RKKP", "RKKP", "Laboratory", "SP"),
    subdomain = c("CLL", "DaMyDa", "Microbiology", "Blood culture"),
    atlas_role = c("clinical_registry", "clinical_registry", "microbiology", "blood_culture"),
    load_status = "ok",
    source_type = "file",
    source = "",
    n_rows = c(7884, 100, 100, 100),
    n_cols = c(80, 20, 10, 10),
    stringsAsFactors = FALSE
  ),
  column_top_values = top_values,
  panels = list(
    microbiology = data.frame(panel = "microbiology blood culture resistance infection", stringsAsFactors = FALSE),
    treatment = data.frame(panel = "ibrutinib venetoclax rituximab bortezomib lenalidomide daratumumab ASCT", stringsAsFactors = FALSE)
  )
)

expect_true(all(c(
  "summary",
  "disease_state_counts",
  "overlap_counts",
  "overlap_timing",
  "infection_outcome_readiness",
  "treatment_modifier_readiness",
  "estimands",
  "validation_checklist",
  "bias_warnings",
  "recommended_next_actions"
) %in% names(outputs)), "CONFLUENCE output should expose every requested table.")

disease <- outputs$disease_state_counts
mbl <- disease[disease$entity_id == "mbl_candidate", , drop = FALSE]
mgus <- disease[disease$entity_id == "mgus_candidate", , drop = FALSE]
cll <- disease[disease$entity_id == "cll_candidate", , drop = FALSE]
mm <- disease[disease$entity_id == "mm_candidate", , drop = FALSE]

expect_equal(nrow(mbl), 1L, "MBL anchor should exist.")
expect_true(identical(mbl$danish_sks_code[[1]], "DD479B"), "MBL should use DD479B.")
expect_true(identical(mbl$icd10_code[[1]], "D47.9B"), "MBL should use D47.9B.")
expect_true(grepl("coded candidate cohort", mbl$evidence_status[[1]], fixed = TRUE), "MBL should be coded-candidate evidence.")
expect_true(grepl("diagnosis-atlas records", mbl$count_kind[[1]], fixed = TRUE), "MBL should be diagnosis-atlas records.")
expect_true(grepl("not validated persons", mbl$notes[[1]], fixed = TRUE), "MBL should not be labelled validated persons.")
expect_true(identical(mbl$count_display[[1]], "193"), "MBL fixture count should render from exact code row.")

expect_true(identical(mgus$danish_sks_code[[1]], "DD472"), "MGUS should use DD472.")
expect_true(identical(mgus$icd10_code[[1]], "D47.2"), "MGUS should use D47.2.")
expect_true(grepl("coded candidate cohort", mgus$evidence_status[[1]], fixed = TRUE), "MGUS should be coded-candidate evidence.")
expect_true(identical(cll$danish_sks_code[[1]], "DC911"), "CLL should use DC911.")
expect_true(identical(cll$icd10_code[[1]], "C91.1"), "CLL should use C91.1.")
expect_true(identical(mm$danish_sks_code[[1]], "DC900"), "MM should use DC900.")
expect_true(identical(mm$icd10_code[[1]], "C90.0"), "MM should use C90.0.")

expect_true(all(outputs$overlap_counts$query_status == "query executable not run"), "Overlap rows should be not-run in scaffold-first mode.")
expect_true(all(outputs$overlap_counts$acceptance_status != "accepted"), "No overlap row should be accepted in scaffold-first mode.")
expect_true(all(outputs$overlap_counts$acceptance_status == "not accepted aggregate"), "Overlap rows should be explicitly not accepted aggregate.")
expect_true(all(outputs$overlap_timing$query_status == "query executable not run"), "Overlap timing should be not-run.")

expect_equal(nrow(outputs$estimands), 4L, "CONFLUENCE should include four estimand cards.")
expect_true(any(outputs$estimands$title == "First serious infection estimand"), "First serious infection estimand should render.")
expect_true(any(outputs$estimands$title == "Recurrent infection burden estimand"), "Recurrent infection burden estimand should render.")
expect_true(any(outputs$estimands$title == "Microbiology-confirmed infection phenotype estimand"), "Microbiology-confirmed infection phenotype estimand should render.")
expect_true(any(outputs$estimands$title == "Additive interaction / dual-clone vulnerability estimand"), "Additive interaction estimand should render.")

required_bias <- c(
  "immortal-time bias",
  "surveillance/testing bias",
  "MBL undercoding",
  "MGUS ascertainment bias",
  "treatment confounding",
  "progression/state-transition bias",
  "competing mortality",
  "small-cell suppression"
)
for (bias in required_bias) {
  expect_true(any(outputs$bias_warnings$bias_label == bias), paste("Missing bias warning:", bias))
}

tmp <- tempfile("confluence-test-")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- confluence_write_outputs(outputs, tmp)
expect_true(all(file.exists(unlist(paths))), "All CONFLUENCE output CSVs should be written.")
names(paths) <- paste0("confluence_", names(paths))
manifest <- output_manifest(paths, run_dir = tmp)
expect_true(any(grepl("confluence_disease_state_counts.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE disease-state counts.")
expect_true(any(grepl("confluence_estimands.csv", manifest$relative_path, fixed = TRUE)), "Manifest should include CONFLUENCE estimands.")

sources <- data.frame(
  table_name = "t_dalycare_diagnoses",
  source_type = "file",
  source = "",
  domain = "SDS",
  subdomain = "Diagnoses",
  atlas_role = "diagnosis",
  profile_mode = "full",
  load_status = "ok",
  n_rows = 10,
  n_cols = 2,
  id_column_guess = "",
  min_date = "",
  max_date = "",
  stringsAsFactors = FALSE
)
columns <- data.frame(table_name = "t_dalycare_diagnoses", column_name = "diagnosis_code", column_type = "character", stringsAsFactors = FALSE)
checks <- data.frame(table_name = "", check_id = "ok", severity = "ok", message = "fixture", stringsAsFactors = FALSE)
payload <- atlas_payload(
  "confluence-test",
  "2026-05-24T00:00:00+0000",
  sources,
  columns,
  checks,
  list(),
  column_top_values = top_values,
  confluence_feasibility = outputs
)
expect_true("confluence_feasibility" %in% names(payload), "Payload should include confluence_feasibility.")
expect_true(length(payload$confluence_feasibility$estimands) == 4L, "Payload should preserve CONFLUENCE estimands.")

html <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
for (needle in c(
  "data-sub=\"mcl-triangle-feasibility\"",
  "data-sub=\"confluence-feasibility\"",
  "DALY-CARE CONFLUENCE",
  "CLL/MBL",
  "DD479B",
  "MGUS",
  "query executable not run",
  "not accepted aggregate",
  "function renderConfluenceFeasibilityPanel",
  "confluence_feasibility"
)) {
  expect_true(grepl(needle, html, fixed = TRUE), paste("HTML/template should include:", needle))
}
for (term in c("DD479B", "MBL", "MGUS", "overlap", "Monoklonal B-celle lymfocytose", "blood culture", "CONFLUENCE")) {
  expect_true(grepl(term, html, fixed = TRUE), paste("Search/template should include CONFLUENCE term:", term))
}

all_text <- paste(unlist(outputs, recursive = TRUE, use.names = FALSE), collapse = " ")
expect_false(grepl("\\b[0-3][0-9]{5}-[0-9]{4}\\b", all_text), "CONFLUENCE outputs must not contain CPR-like values.")
expect_false(grepl("\\b\\d{4}-\\d{2}-\\d{2}\\b", all_text), "CONFLUENCE scaffold outputs must not contain raw dates.")
expect_false(grepl("raw free text|snippet|row preview", all_text, ignore.case = TRUE), "CONFLUENCE scaffold outputs must not expose raw text/snippets/row previews.")

cat("CONFLUENCE feasibility tests passed\n")
