root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

config_path <- file.path(root, "config", "dalycare_cycle4_curator_label_promotions.csv")
expect_file(config_path)

promotions <- read_curator_label_promotions(root, validate = TRUE)
expect_equal(nrow(promotions), 5047L, "Curator label promotion config should contain 5,047 rows.")
expect_false(any(!nzchar(trimws(promotions$fill_preferred_label))), "Every curator row should have fill_preferred_label.")
expect_false(any(promotions$mapping_status_or_reason == "conflict_pending_review"), "Approved curator rows must not be reopened as conflicts.")

lookup <- curator_label_build_lookup(promotions)
expect_equal(nrow(lookup), 5047L, "Curator lookup should retain every config row.")
expect_equal(sum(lookup$promotion_eligible == "yes", na.rm = TRUE), 5047L, "Every curator row should be promotion-eligible.")

hit_label <- function(row) {
  hit <- curator_label_lookup_hit(curator_label_lookup_index(lookup), row)
  expect_true(!is.null(hit$hit), paste("Expected curator hit for", paste(row, collapse = " / ")))
  hit$hit$display_label[[1]]
}

expect_equal(
  hit_label(data.frame(code_system = "NPU", raw_code = "NPU01459", source_name = "LABKA", raw_column = "analysiscode", stringsAsFactors = FALSE)),
  "P—Carbamide; subst.c. = ? mmol/L",
  "NPU curator label should resolve deterministically."
)
expect_equal(
  hit_label(data.frame(code_system = "SKS", code = "UXCD00", source_name = "part4_sds_procedure_andre", raw_column = "procedurekode_parent", stringsAsFactors = FALSE)),
  "CT imaging signal",
  "CT/imaging procedure curator label should resolve deterministically."
)
expect_equal(
  hit_label(data.frame(code_system = "SKS", code = "BWHA100", source_name = "SDS_t_sksube", stringsAsFactors = FALSE)),
  "Etoposide",
  "SKS treatment procedure curator label should resolve deterministically."
)
expect_equal(
  hit_label(data.frame(code_system = "SNOMED", raw_code = "T06002", source_name = "SDS_pato", raw_column = "c_snomedkode", stringsAsFactors = FALSE)),
  "Cristamarv",
  "Pathology/SNOMED curator label should resolve deterministically."
)
expect_equal(
  hit_label(data.frame(code_type = "pathology_institution_code", code = "4202220", source_name = "SDS_t_mikro", stringsAsFactors = FALSE)),
  "Pathology institution / lab source code 4202220",
  "Pathology institution curator label should resolve deterministically with source context."
)
expect_equal(
  hit_label(data.frame(code_system = "SNOMED", raw_code = "M98233", source_name = "SDS_pato", raw_column = "c_snomedkode", stringsAsFactors = FALSE)),
  "Kronisk lymfocytær leukæmi",
  "Tumor/pathology morphology curator label should resolve deterministically."
)

ambiguous_lookup <- curator_label_build_lookup(data.frame(
  code_type = c("NPU", "NPU"),
  code = c("NPU99999", "NPU99999"),
  fill_preferred_label = c("First label", "Second label"),
  mapping_status_or_reason = c("curator_filled_label_ready_for_promotion", "curator_filled_label_ready_for_promotion"),
  source_table_or_panel = c("", ""),
  source_column = c("", ""),
  evidence_file = c("", ""),
  observed_count = c("", ""),
  observed_pct = c("", ""),
  entity_scope_key = c("", ""),
  from_file = c("", ""),
  notes = c("", ""),
  stringsAsFactors = FALSE
))
ambiguous_hit <- curator_label_lookup_hit(
  curator_label_lookup_index(ambiguous_lookup),
  data.frame(code_system = "NPU", raw_code = "NPU99999", stringsAsFactors = FALSE)
)
expect_true(is.null(ambiguous_hit$hit), "Ambiguous code-only curator matches should not be promoted.")
expect_equal(ambiguous_hit$reason, "ambiguous_match", "Ambiguous curator match should be audited as ambiguous_match.")

code_map <- semantic_code_row(
  semantic_id = "test_npu01459",
  clinical_concept_id = "test_npu01459",
  clinical_variable = "NPU01459",
  clinical_group = "Laboratory",
  source_name = "LABKA",
  object_name = "LABKA",
  code_system = "NPU",
  code = "NPU01459",
  code_name = "Unmapped NPU code: NPU01459",
  panel = "NPU",
  n_rows = 10,
  evidence_file = "outputs/panels/lab_npu_code_coverage.csv",
  mapping_confidence = "candidate",
  notes = ""
)
dictionary <- semantic_row(
  semantic_id = "test_t06002",
  clinical_concept_id = "pathology_snomed_code",
  clinical_variable = "Unmapped SNOMED/pathology code: T06002",
  clinical_group = "Pathology",
  source_name = "SDS_pato",
  object_name = "SDS_pato",
  raw_column = "c_snomedkode",
  raw_code = "T06002",
  code_system = "SNOMED",
  data_shape = "code_map",
  n_rows = 10,
  evidence_file = "config/cartography-reference/files/cartography_pato_top_snomed.tsv",
  mapping_confidence = "candidate",
  mapping_status = "candidate",
  clinical_caveat = ""
)
promoted <- semantic_apply_curator_label_promotions(dictionary, code_map, lookup)
expect_equal(promoted$code_map$code_name[[1]], "P—Carbamide; subst.c. = ? mmol/L", "Code-map primary label should be curator promoted.")
expect_equal(promoted$code_map$prior_display_label[[1]], "Unmapped NPU code: NPU01459", "Prior code-map label should remain in lineage.")
expect_equal(promoted$dictionary$clinical_variable[[1]], "Cristamarv", "Dictionary primary label should be curator promoted.")
expect_equal(promoted$dictionary$prior_display_label[[1]], "Unmapped SNOMED/pathology code: T06002", "Prior dictionary label should remain in lineage.")

empty_sources_frame <- data.frame(table_name = character(), load_status = character(), stringsAsFactors = FALSE)
empty_columns_frame <- data.frame(
  table_name = character(),
  column_name = character(),
  column_type = character(),
  column_class = character(),
  stringsAsFactors = FALSE
)
empty_checks_frame <- data.frame(
  severity = character(),
  table_name = character(),
  check_id = character(),
  message = character(),
  stringsAsFactors = FALSE
)

payload <- atlas_payload(
  run_id = "curator-label-test",
  generated_at = "2026-05-25T00:00:00+0000",
  sources = empty_sources_frame,
  columns = empty_columns_frame,
  checks = empty_checks_frame,
  panels = list(),
  semantic_dictionary = promoted$dictionary,
  semantic_code_map = promoted$code_map,
  curator_label_promotions = promotions,
  curator_label_lookup = lookup
)
expect_true("curator_label_promotion_lookup_rows" %in% names(payload), "Payload should expose the curator label lookup.")
expect_equal(length(payload$curator_label_promotion_lookup_rows), 5047L, "Payload should include all curator lookup rows.")
payload_text <- atlas_to_json(payload)
reviewer_source_pollution <- grepl("\"source_name\"\\s*:\\s*\"(?:semantic_unmapped_entity_map|dalycare_cycle4_column_C_filled_corrected_ready_for_codex|dalycare_cycle4_curator_label_promotions)\"", payload_text)
expect_false(reviewer_source_pollution, "Pseudo-source/config filenames should not appear as reviewer-facing source_name values.")
expect_false(grepl("conflict_pending_review", payload_text, fixed = TRUE), "Cycle 5 approved labels should not introduce active conflict_pending_review states.")

cat("PDSA Cycle 5 curator label promotion tests passed\n")
