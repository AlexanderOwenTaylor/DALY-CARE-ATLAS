root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
for (needle in c(
  "Choose your route",
  "Planning a study",
  "Validating data/source readiness",
  "New to DALY-CARE",
  "Disease researcher",
  "Clinical/management overview",
  "Data dictionary and QA",
  "Internal briefing",
  "What this means",
  "Retrospective cohort construction feasible; risk-adapted TRIANGLE emulation not yet ready",
  "Feasibility template, not causal answer",
  "fallback reference count",
  "fallback/reference count",
  "renderCountKindBadge",
  "What to do here",
  "RKKP registry loading and cleaning",
  "Diagnosis cohort construction",
  "Drug-exposed cohorts",
  "Text mining / pathology discovery",
  "Bias and completeness checks",
  "candidate / needs validation",
  "no raw text emitted",
  "Special/manual resources",
  "Represented through embedded cytogenetic/FISH fields in RKKP_CLL and RKKP_DaMyDa; no standalone LAB_FISH table is expected in this run.",
  "Manual/on-disk curated Richter transformation resource. Legacy atlas evidence identified danricht_clean.parquet and DANRICHT_20240412.csv.",
  "private source-owner register",
  "BilleddiagnostikeUndersøgelser_Del2 is handled separately"
)) {
  expect_true(grepl(needle, template, fixed = TRUE), paste("Presentation template should include:", needle))
}
expect_false(grepl("/ngc/dalyca_r/people/", template, fixed = TRUE), "Presentation template must not emit guessed person-specific NGC paths.")

sources <- data.frame(
  table_name = c("SDS_pato", "RKKP_LYFO"),
  domain = c("Pathology", "RKKP"),
  subdomain = c("PATOBANK", "LYFO"),
  atlas_role = c("pathology", "clinical_registry"),
  source_type = c("db", "db"),
  source = c("SDS_pato", "RKKP_LYFO"),
  profile_mode = c("aggregate", "aggregate"),
  load_status = c("ok", "ok"),
  chosen_strategy = c("fixture", "fixture"),
  memory_status = c("ok", "ok"),
  resolution_status = c("resolved", "resolved"),
  n_rows = c(10, 20),
  n_cols = c(2, 3),
  date_range = c("", ""),
  message = c("", ""),
  stringsAsFactors = FALSE
)
columns <- data.frame(
  table_name = c("SDS_pato", "RKKP_LYFO"),
  column_name = c("c_snomedkode", "Reg_Diagnose_dt"),
  type = c("character", "date"),
  stringsAsFactors = FALSE
)
checks <- data.frame(
  severity = "ok",
  table_name = "SDS_pato",
  check_id = "aggregate_only",
  message = "No raw text emitted",
  stringsAsFactors = FALSE
)
semantic_dictionary <- data.frame(
  semantic_id = c("path_ki67", "lyfo_dx"),
  clinical_concept_id = c("ki67", "diagnosis_date"),
  clinical_variable = c("Ki-67 proliferation index", "Diagnosis date"),
  clinical_group = c("Pathology", "Registry"),
  clinical_subgroup = c("PATOBANK", "LYFO"),
  semantic_meaning = c("Coded Ki-67 signpost", "Registry diagnosis date"),
  source_name = c("SDS_pato", "RKKP_LYFO"),
  object_name = c("SDS_pato", "RKKP_LYFO"),
  table_name = c("SDS_pato", "RKKP_LYFO"),
  raw_column = c("c_snomedkode", "Reg_Diagnose_dt"),
  raw_descriptor = c("SNOMED code", "diagnosis date"),
  raw_code = c("AEKI030", ""),
  raw_value = c("", ""),
  code_system = c("SNOMED", ""),
  value_type = c("code", "date"),
  data_shape = c("coded", "date"),
  evidence_file = c("fixture", "fixture"),
  evidence_filter = c("aggregate", "aggregate"),
  mapping_status = c("candidate", "confirmed"),
  mapping_confidence = c("medium", "high"),
  clinical_caveat = c("Needs validation", ""),
  privacy_note = c("aggregate_only", "aggregate_only"),
  stringsAsFactors = FALSE
)
semantic_value_map <- data.frame(
  semantic_id = "path_ki67",
  raw_value = "suppressed",
  display_value = "suppressed",
  clinical_interpretation = "small cells suppressed",
  stringsAsFactors = FALSE
)
semantic_code_map <- data.frame(
  semantic_id = "path_ki67",
  code_system = "SNOMED",
  code = "AEKI030",
  code_name = "Ki-67 30",
  clinical_group = "Pathology",
  stringsAsFactors = FALSE
)

mcl_payload <- mcl_triangle_empty_payload()
mcl_payload$cohort_counts <- list(
  data_point_counts = data.frame(
    data_point_id = c("all_lyfo_mcl", "ki67_aeki"),
    clinical_label = c("All LYFO MCL", "Ki-67 AEKI"),
    count_status = c("count_available", "count_available"),
    distinct_person_count_display = c("1,417", "37"),
    stringsAsFactors = FALSE
  ),
  treatment_strategy_strata_counts = data.frame(
    denominator = "all_lyfo_mcl",
    ibrutinib_status = "yes",
    asct_hdt_first_line_status = "yes",
    count_status = "count_available",
    distinct_person_count_display = "14",
    stringsAsFactors = FALSE
  ),
  answerability_summary = data.frame(
    row_id = "descriptive_feasibility",
    status = "descriptive_feasibility_only",
    distinct_person_count_display = "14",
    interpretation = "Aggregate feasibility only",
    recommended_next_step = "Validate protocol definitions",
    stringsAsFactors = FALSE
  )
)

payload <- atlas_payload(
  "presentation-test",
  "2026-05-23T00:00:00+0200",
  sources,
  columns,
  checks,
  panels = list(),
  semantic_dictionary = semantic_dictionary,
  semantic_value_map = semantic_value_map,
  semantic_code_map = semantic_code_map,
  mcl_triangle_feasibility = mcl_payload
)

count_rows <- function(x) {
  if (is.null(x)) return(0L)
  if (is.data.frame(x)) return(nrow(x))
  length(x)
}
mcl_counts <- function(mcl) {
  out <- integer()
  for (name in names(mcl)) {
    item <- mcl[[name]]
    if (is.list(item) && !is.null(names(item))) {
      for (child in names(item)) {
        out[[paste(name, child, sep = ".")]] <- count_rows(item[[child]])
      }
    } else {
      out[[name]] <- count_rows(item)
    }
  }
  out
}
json_array_for_key <- function(json, key) {
  marker <- paste0("\"", key, "\"\\s*:\\s*\\[")
  matches <- gregexpr(marker, json, perl = TRUE)[[1]]
  hits <- matches[matches > 0]
  lengths <- attr(matches, "match.length")
  lengths <- lengths[matches > 0]
  hits <- hits[hits > 0]
  if (!length(hits)) return("")
  hit <- hits[[length(hits)]]
  start <- hit + lengths[[length(lengths)]] - 1L
  chars <- strsplit(substr(json, start, nchar(json)), "", fixed = TRUE)[[1]]
  bracket_depth <- 0L
  in_string <- FALSE
  escaped <- FALSE
  for (i in seq_along(chars)) {
    ch <- chars[[i]]
    if (in_string) {
      if (escaped) {
        escaped <- FALSE
      } else if (identical(ch, "\\")) {
        escaped <- TRUE
      } else if (identical(ch, "\"")) {
        in_string <- FALSE
      }
    } else if (identical(ch, "\"")) {
      in_string <- TRUE
    } else if (identical(ch, "[")) {
      bracket_depth <- bracket_depth + 1L
    } else if (identical(ch, "]")) {
      bracket_depth <- bracket_depth - 1L
      if (bracket_depth == 0L) {
        return(paste(chars[seq_len(i)], collapse = ""))
      }
    }
  }
  ""
}
json_array_row_count <- function(json, key) {
  array_text <- json_array_for_key(json, key)
  if (!nzchar(array_text)) return(0L)
  chars <- strsplit(array_text, "", fixed = TRUE)[[1]]
  bracket_depth <- 0L
  in_string <- FALSE
  escaped <- FALSE
  rows <- 0L
  for (ch in chars) {
    if (in_string) {
      if (escaped) {
        escaped <- FALSE
      } else if (identical(ch, "\\")) {
        escaped <- TRUE
      } else if (identical(ch, "\"")) {
        in_string <- FALSE
      }
    } else if (identical(ch, "\"")) {
      in_string <- TRUE
    } else if (identical(ch, "[")) {
      bracket_depth <- bracket_depth + 1L
    } else if (identical(ch, "]")) {
      bracket_depth <- bracket_depth - 1L
    } else if (identical(ch, "{") && bracket_depth == 1L) {
      rows <- rows + 1L
    }
  }
  rows
}
before <- c(
  semantic_dictionary_rows = count_rows(payload$semantic_dictionary_rows),
  semantic_value_map_rows = count_rows(payload$semantic_value_map_rows),
  semantic_code_map_rows = count_rows(payload$semantic_code_map_rows),
  sources = count_rows(payload$sources),
  catalog_rows = count_rows(payload$catalog_rows),
  "cohort_counts.data_point_counts" = count_rows(payload$mcl_triangle_feasibility$cohort_counts$data_point_counts),
  "cohort_counts.treatment_strategy_strata_counts" = count_rows(payload$mcl_triangle_feasibility$cohort_counts$treatment_strategy_strata_counts),
  "cohort_counts.answerability_summary" = count_rows(payload$mcl_triangle_feasibility$cohort_counts$answerability_summary)
)

run_dir <- tempfile("atlas_presentation_nonregression_")
invisible(write_static_atlas(run_dir, payload, project_root = root))
payload_js <- paste(readLines(file.path(run_dir, "site", "DALYCARE_atlas_payload.js"), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
payload_json <- sub("^window\\.DALYCARE_ATLAS_PAYLOAD\\s*=\\s*", "", payload_js)
payload_json <- sub(";\\s*$", "", payload_json)
after <- c(
  semantic_dictionary_rows = json_array_row_count(payload_json, "semantic_dictionary_rows"),
  semantic_value_map_rows = json_array_row_count(payload_json, "semantic_value_map_rows"),
  semantic_code_map_rows = json_array_row_count(payload_json, "semantic_code_map_rows"),
  sources = json_array_row_count(payload_json, "sources"),
  catalog_rows = json_array_row_count(payload_json, "catalog_rows"),
  "cohort_counts.data_point_counts" = json_array_row_count(payload_json, "data_point_counts"),
  "cohort_counts.treatment_strategy_strata_counts" = json_array_row_count(payload_json, "treatment_strategy_strata_counts"),
  "cohort_counts.answerability_summary" = json_array_row_count(payload_json, "answerability_summary")
)

for (name in names(before)) {
  expect_equal(
    as.integer(after[[name]]),
    as.integer(before[[name]]),
    paste("Presentation rendering should preserve payload row count:", name, "before", before[[name]], "after", after[[name]])
  )
}
closeAllConnections()
