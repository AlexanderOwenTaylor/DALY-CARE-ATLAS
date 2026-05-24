root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

write_header_only_patobank_ki67_csvs <- function(output_dir) {
  dir_create(output_dir)
  write.csv(patobank_ki67_empty_validation(), file.path(output_dir, "patobank_ki67_percent_validation.csv"), row.names = FALSE)
  write.csv(patobank_ki67_empty_summary(), file.path(output_dir, "patobank_ki67_percent_summary.csv"), row.names = FALSE)
  write.csv(patobank_ki67_empty_code_counts(), file.path(output_dir, "patobank_ki67_percent_code_counts.csv"), row.names = FALSE)
  write.csv(patobank_ki67_empty_denominator_counts(), file.path(output_dir, "patobank_ki67_percent_denominator_counts.csv"), row.names = FALSE)
  output_dir
}

header_only_dir <- write_header_only_patobank_ki67_csvs(tempfile("patobank_ki67_header_only_"))
header_only_audit <- patobank_ki67_validate_output_files(header_only_dir)
expect_true(
  all(header_only_audit$status == "empty_output_error"),
  "Header-only PATOBANK Ki-67 CSV files must fail output-file validation."
)
expect_true(
  all(header_only_audit$n_rows == 0L),
  "Header-only PATOBANK Ki-67 CSV validation should report zero data rows for each required component."
)

empty_write_error <- tryCatch({
  patobank_ki67_write_outputs(patobank_ki67_empty_outputs(), tempfile("patobank_ki67_empty_write_"))
  ""
}, error = function(e) conditionMessage(e))
expect_true(
  grepl("contains no data rows and no fail-closed validation row", empty_write_error, fixed = TRUE),
  "Header-only PATOBANK Ki-67 outputs must not be written as valid atlas outputs."
)

failed_closed <- patobank_ki67_fail_closed_outputs(
  reason_id = "test_failed_closed",
  label = "Test failed-closed PATOBANK Ki-67 fixture",
  notes = "Test fixture failed closed without production aggregate coverage."
)
failed_closed_dir <- tempfile("patobank_ki67_failed_closed_")
invisible(patobank_ki67_write_outputs(failed_closed, failed_closed_dir))
failed_closed_file_audit <- patobank_ki67_validate_output_files(failed_closed_dir)
expect_true(
  all(failed_closed_file_audit$status == "ok"),
  "Failed-closed PATOBANK Ki-67 CSVs must pass file validation because they contain explicit semantic state rows."
)
failed_closed_output_audit <- patobank_ki67_validate_outputs(patobank_ki67_read_outputs(failed_closed_dir))
expect_true(
  all(failed_closed_output_audit$status == "ok"),
  "Failed-closed PATOBANK Ki-67 outputs must pass in-memory component validation."
)
expect_true(
  any(failed_closed$summary$status == "failed_closed") &&
    any(failed_closed$code_counts$count_status == "failed_closed") &&
    any(failed_closed$denominator_counts$count_status == "failed_closed"),
  "Failed-closed PATOBANK Ki-67 fixtures must carry fail-closed state across summary, code counts, and denominators."
)

successful_frame <- data.frame(
  patientid = c("P1", "P2", "P2", "P3"),
  k_inst = c("A", "A", "A", "B"),
  k_rekvnr = c("R1", "R2", "R2", "R3"),
  k_matnr = c("M1", "M2", "M2", "M3"),
  k_sekvensnr = c("S1", "S2", "S2", "S3"),
  c_snomedkode = c("AEKI030", "AEKI050", "AEKI050", "AEKI100"),
  stringsAsFactors = FALSE
)
successful <- patobank_ki67_outputs_from_frame(successful_frame, min_cell_count = 1L)
successful_audit <- patobank_ki67_validate_outputs(successful)
expect_true(all(successful_audit$status == "ok"), "Successful PATOBANK Ki-67 aggregate fixtures must pass component validation.")
expect_true(
  any(successful$summary$status == "valid_numeric_percent_evidence_found") &&
    any(successful$code_counts$count_status == "aggregate_count_available") &&
    any(successful$denominator_counts$count_status == "aggregate_count_available"),
  "Successful PATOBANK Ki-67 aggregate fixtures must expose production aggregate status rows."
)
