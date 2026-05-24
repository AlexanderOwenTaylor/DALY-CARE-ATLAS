root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

actual_ae <- intToUtf8(0x00C6)
mojibake_ae <- intToUtf8(c(0x00C3, 0x2020))
parsed <- patobank_ki67_parse_code(c(
  "AEKI030",
  paste0(actual_ae, "KI030"),
  paste0(mojibake_ae, "KI030"),
  "AEKI000",
  "AEKI100",
  "AEKI101",
  "AEKI999",
  "FY5015",
  "KI67 qualitative"
))
expect_equal(parsed$parsed_percent[[1]], 30L, "AEKI030 should parse to 30.")
expect_equal(parsed$parsed_percent[[2]], 30L, "Actual ÆKI030 should parse to 30.")
expect_equal(parsed$parsed_percent[[3]], 30L, "Mojibake AEKI030 should parse to 30.")
expect_true(parsed$valid_numeric_percent[[4]], "AEKI000 should be accepted.")
expect_true(parsed$valid_numeric_percent[[5]], "AEKI100 should be accepted.")
expect_equal(parsed$rejection_reason[[6]], "percent_out_of_range", "AEKI101 should be rejected as out of range.")
expect_equal(parsed$rejection_reason[[7]], "percent_out_of_range", "AEKI999 should be rejected as out of range.")
expect_equal(parsed$rejection_reason[[8]], "p16_ki67_dual_stain_or_non_numeric", "p16/Ki-67 dual-stain codes must not be numeric Ki-67 percent evidence.")
expect_equal(parsed$rejection_reason[[9]], "qualitative_code", "Qualitative Ki-67-like values must not be numeric percent evidence.")

pato <- data.frame(
  patientid = c("PATIENT_A", "PATIENT_A", "PATIENT_B", "PATIENT_C", "PATIENT_D", "PATIENT_E", "PATIENT_F", "PATIENT_G", "PATIENT_H"),
  k_inst = c("INST_A", "INST_A", "INST_B", "INST_C", "INST_D", "INST_E", "INST_F", "INST_G", "INST_H"),
  k_rekvnr = c("REQ_A", "REQ_A", "REQ_B", "REQ_C", "REQ_D", "REQ_E", "REQ_F", "REQ_G", "REQ_H"),
  k_matnr = c("MAT_A", "MAT_A", "MAT_B", "MAT_C", "MAT_D", "MAT_E", "MAT_F", "MAT_G", "MAT_H"),
  k_sekvensnr = c("SEQ_A", "SEQ_A", "SEQ_B", "SEQ_C", "SEQ_D", "SEQ_E", "SEQ_F", "SEQ_G", "SEQ_H"),
  c_snomedkode = c(
    "AEKI030",
    "AEKI050",
    paste0(actual_ae, "KI030"),
    paste0(mojibake_ae, "KI100"),
    "AEKI101",
    "FY5015",
    "KI67 qualitative",
    "AEKI000",
    "AEKI999"
  ),
  stringsAsFactors = FALSE
)
outputs <- patobank_ki67_outputs_from_frame(pato, min_cell_count = 1L)
patient <- outputs$denominator_counts[outputs$denominator_counts$denominator_id == "patient", , drop = FALSE]
investigation <- outputs$denominator_counts[outputs$denominator_counts$denominator_id == "investigation", , drop = FALSE]
specimen <- outputs$denominator_counts[outputs$denominator_counts$denominator_id == "specimen", , drop = FALSE]
expect_equal(patient$numerator_display[[1]], "4", "Multiple valid Ki-67 rows for one patient should deduplicate to one patient numerator.")
expect_equal(patient$denominator_display[[1]], "8", "Patient denominator should count distinct patient keys, not pathology rows.")
expect_equal(investigation$numerator_display[[1]], "4", "Investigation numerator should deduplicate repeated rows within one investigation.")
expect_equal(specimen$numerator_display[[1]], "4", "Specimen numerator should deduplicate repeated rows within one specimen.")
expect_true(any(outputs$code_counts$canonical_code == "AEKI030" & outputs$code_counts$aggregate_count_display == "2"), "AEKI/ÆKI/mojibake aliases should normalize into the same code-count row.")
expect_true(any(outputs$validation$rejection_reason == "percent_out_of_range" & outputs$validation$count_display == "2"), "Rejected out-of-range candidates should be retained as validation metadata.")
expect_true(any(outputs$validation$rejection_reason == "p16_ki67_dual_stain_or_non_numeric" & outputs$validation$count_display == "1"), "p16/Ki-67 non-numeric candidates should be validation metadata only.")

no_patient <- pato[, setdiff(names(pato), "patientid"), drop = FALSE]
no_patient_outputs <- patobank_ki67_outputs_from_frame(no_patient, min_cell_count = 1L)
no_patient_den <- no_patient_outputs$denominator_counts[no_patient_outputs$denominator_counts$denominator_id == "patient", , drop = FALSE]
no_patient_inv <- no_patient_outputs$denominator_counts[no_patient_outputs$denominator_counts$denominator_id == "investigation", , drop = FALSE]
expect_equal(no_patient_den$count_status[[1]], "patient_denominator_unavailable_key_missing", "Missing patient key should fail closed instead of guessing patient deduplication.")
expect_equal(no_patient_inv$count_status[[1]], "aggregate_count_available", "Investigation coverage may still populate when a stable investigation key exists.")

empty_source_outputs <- patobank_ki67_outputs_from_frame(data.frame(stringsAsFactors = FALSE), min_cell_count = 1L)
expect_true(all(vapply(empty_source_outputs[patobank_ki67_required_components()], nrow, integer(1)) > 0L), "Fail-closed PATOBANK Ki-67 outputs must populate every required CSV, not just validation.")
expect_true(any(empty_source_outputs$validation$status == "failed_closed"), "Unavailable PATOBANK Ki-67 inputs should emit explicit failed_closed validation rows.")
expect_true(any(empty_source_outputs$summary$status == "failed_closed"), "Unavailable PATOBANK Ki-67 inputs should emit explicit failed_closed summary rows.")
expect_true(any(empty_source_outputs$code_counts$count_status == "failed_closed"), "Unavailable PATOBANK Ki-67 inputs should emit explicit failed_closed code-count rows.")
expect_true(any(empty_source_outputs$denominator_counts$count_status == "failed_closed"), "Unavailable PATOBANK Ki-67 inputs should emit explicit failed_closed denominator rows.")

no_valid <- pato
no_valid$c_snomedkode <- c("AEKI101", "AEKI999", "FY5015", "KI67 qualitative", "", "MIB1", "PROLIF", "AEKIABC", "other")
no_valid_outputs <- patobank_ki67_outputs_from_frame(no_valid, min_cell_count = 1L)
expect_true(nrow(no_valid_outputs$code_counts) > 0L, "No-valid-code scans must still emit a code-count fail-closed row.")
expect_true(any(no_valid_outputs$code_counts$validation_status == "no_valid_aeki_codes_found"), "No-valid-code scans should state no_valid_aeki_codes_found.")

expect_error_message <- function(expr, pattern, message) {
  err <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) conditionMessage(e))
  expect_true(!is.null(err) && grepl(pattern, err, fixed = TRUE), message)
}
expect_error_message(
  patobank_ki67_write_outputs(patobank_ki67_empty_outputs(), tempfile("patobank_empty_write_")),
  "PATOBANK Ki-67 cartography failed: output file exists but contains no data rows and no fail-closed validation row.",
  "Header-only PATOBANK Ki-67 outputs must fail before being written."
)

issued_queries <- character()
fake_db <- list(
  table_schema = function(db_name, schema, table) {
    expect_equal(db_name, "import", "PATOBANK Ki-67 DB path should use the resolved source database.")
    data.frame(
      column_name = c("patientid", "k_inst", "k_rekvnr", "k_matnr", "k_sekvensnr", "c_snomedkode"),
      stringsAsFactors = FALSE
    )
  },
  patobank_ki67_query = function(sql, db_name = "") {
    issued_queries <<- c(issued_queries, sql)
    if (grepl("valid_codes", sql, fixed = TRUE)) {
      return(data.frame(canonical_code = c("AEKI030", "AEKI050"), parsed_percent = c(30L, 50L), aggregate_count = c(2L, 1L), stringsAsFactors = FALSE))
    }
    if (grepl("classified", sql, fixed = TRUE)) {
      return(data.frame(rejection_reason = c("percent_out_of_range", "p16_ki67_dual_stain_or_non_numeric"), aggregate_count = c(2L, 1L), stringsAsFactors = FALSE))
    }
    if (grepl("'patient' as denominator_id", sql, fixed = TRUE)) {
      return(data.frame(denominator_count = 8L, numerator_count = 4L, stringsAsFactors = FALSE))
    }
    if (grepl("'investigation' as denominator_id", sql, fixed = TRUE)) {
      return(data.frame(denominator_count = 8L, numerator_count = 4L, stringsAsFactors = FALSE))
    }
    if (grepl("'specimen' as denominator_id", sql, fixed = TRUE)) {
      return(data.frame(denominator_count = 8L, numerator_count = 4L, stringsAsFactors = FALSE))
    }
    stop("Unexpected PATOBANK Ki-67 aggregate SQL in fake adapter.")
  }
)
db_outputs <- patobank_ki67_build_outputs(
  db_adapter = fake_db,
  source_resolution = data.frame(table_name = "SDS_pato", source = "SDS_pato", db_name = "import", schema = "public", table = "SDS_pato", stringsAsFactors = FALSE),
  min_cell_count = 1L
)
expect_true(any(db_outputs$code_counts$canonical_code == "AEKI030"), "DB aggregate path should populate valid AEKI code counts.")
expect_true(any(db_outputs$validation$rejection_reason == "percent_out_of_range" & db_outputs$validation$count_display == "2"), "DB aggregate path should populate rejected-code validation metadata.")
expect_equal(db_outputs$denominator_counts$count_status[db_outputs$denominator_counts$denominator_id == "patient"], "aggregate_count_available", "DB aggregate path should populate validated patient coverage when a patient key exists.")
expect_false(grepl("SELECT \\*|LIMIT 10", paste(issued_queries, collapse = "\n"), ignore.case = TRUE, perl = TRUE), "DB aggregate PATOBANK Ki-67 queries must not use raw-row previews.")

tmp <- tempfile("patobank_ki67_outputs_")
dir_create(tmp)
paths <- patobank_ki67_write_outputs(outputs, tmp)
file_audit <- patobank_ki67_validate_output_files(tmp)
expect_true(all(file_audit$status == "ok"), "Written PATOBANK Ki-67 output CSVs must each contain at least one data row.")
all_output_text <- paste(vapply(unlist(paths), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("PATIENT_A|REQ_A|MAT_A|SEQ_A", all_output_text), "PATOBANK Ki-67 outputs must not emit patient, requisition, specimen, or sequence key values.")
expect_false(grepl("SELECT \\*|LIMIT 10", all_output_text, ignore.case = TRUE, perl = TRUE), "PATOBANK Ki-67 query templates must not use raw-row previews.")

payload <- atlas_payload(
  run_id = "patobank_ki67_fixture",
  generated_at = "2026-05-23T00:00:00Z",
  sources = data.frame(table_name = "SDS_pato", source_type = "dataset", source = "SDS_pato", load_status = "ok", n_rows = 9, n_cols = 6, stringsAsFactors = FALSE),
  columns = data.frame(table_name = "SDS_pato", column_name = "c_snomedkode", column_type = "character", stringsAsFactors = FALSE),
  checks = data.frame(table_name = "SDS_pato", check_id = "ok", severity = "ok", message = "ok", stringsAsFactors = FALSE),
  panels = list(),
  patobank_ki67_percent = outputs
)
expect_true("patobank_ki67_percent" %in% names(payload), "Atlas payload should expose PATOBANK Ki-67 percent coverage separately from TRIANGLE feasibility.")
expect_true(length(payload$patobank_ki67_percent$summary) > 0, "PATOBANK Ki-67 payload summary should be populated from PATOBANK outputs.")

template <- paste(readLines(file.path(root, "inst", "templates", "DALYCARE_atlas.html"), warn = FALSE), collapse = "\n")
expect_true(grepl("PATOBANK coded Ki-67 percent evidence coverage", template, fixed = TRUE), "Pathology/PATOBANK panel should contain the dedicated PATOBANK Ki-67 coverage title.")
expect_true(grepl("renderPatobankKi67PercentCoverage()", template, fixed = TRUE), "Pathology/PATOBANK panel should render the PATOBANK Ki-67 output, not the TRIANGLE signpost.")
expect_true(grepl("TRIANGLE feasibility-only", template, fixed = TRUE), "TRIANGLE Ki-67 section should remain visibly scoped to TRIANGLE feasibility.")
expect_true(grepl("empty-output-error", template, fixed = TRUE), "PATOBANK Ki-67 UI should expose an empty-output QA error state.")
expect_true(grepl("not computed in this build", template, fixed = TRUE), "PATOBANK Ki-67 UI should expose a failed-closed not-computed state.")
expect_true(grepl("General PATOBANK Ki-67 cartography was attempted but not computed in this build", template, fixed = TRUE), "TRIANGLE Ki-67 wording should not generalize when PATOBANK Ki-67 coverage is unavailable.")
expect_true(grepl("Semantic output QA", template, fixed = TRUE), "Atlas should include a visible semantic-output QA summary.")
expect_true(grepl("Technical lineage / raw cartography rows", template, fixed = TRUE), "DaMyDa/LYFO raw cartography rows should be behind technical disclosure.")
expect_true(grepl("Primary taxonomy: Laboratory & Diagnostics", template, fixed = TRUE), "Microbiology and Pathology should be labelled as Laboratory & Diagnostics resources even when cross-linked from Clinical Data.")
