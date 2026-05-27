root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_ki67_test_runtime(root)
source(file.path(root, "R", "mcl_triangle_counts.R"))

expect_file(file.path(root, "clinical_questions", "mcl_triangle_high_risk_biology_definitions.yml"))

fake_sets <- list(
  all_lyfo_mcl = paste0("p", 1:30),
  younger_mcl_proxy_age_le_65 = paste0("p", 1:24),
  birth_date_available = paste0("p", 1:28),
  diagnosis_date = paste0("p", 1:30),
  age_computable = paste0("p", 1:25),
  age_missing_uncomputable = paste0("p", 26:30),
  first_line_treatment_date = paste0("p", 1:22),
  asct_hdt_first_line = paste0("p", 1:10),
  asct_hdt_relapse_recurrence = paste0("p", 27:30),
  ibrutinib_exposure = paste0("p", 1:12),
  os_death = paste0("p", 1:20),
  relapse_progression_ffs_proxy = paste0("p", 1:14),
  ki67_aeki = paste0("p", 1:8),
  ki67_aeki_high_threshold = paste0("p", c(1, 3, 5, 7)),
  mipi_mipic_components = paste0("p", 1:26),
  tp53_p53_del17p = paste0("p", c(2, 4, 6, 8, 10)),
  blastoid_pleomorphic_morphology = paste0("p", c(11, 12, 13)),
  alive_at_landmark = paste0("p", 1:18),
  event_free_pre_landmark = paste0("p", 1:15),
  asct_hdt_status_known_landmark = paste0("p", 1:21),
  ibrutinib_status_known_landmark = paste0("p", 1:16),
  high_risk_biology_pre_landmark = paste0("p", 1:11)
)

out <- mcl_count_build_outputs(
  project_root = root,
  mode = "production_aggregate",
  db_adapter = list(mcl_triangle_count_sets = function(min_cell_count = 1L) list(sets = fake_sets)),
  min_cell_count = 1L
)

expect_true(all(c(
  "age_proxy_counts",
  "ibrutinib_exposure_counts",
  "treatment_strategy_strata_counts",
  "high_risk_biology_counts",
  "answerability_intersections",
  "answerability_summary"
) %in% names(out)), "Answerability outputs should be part of the cohort-count object.")

age_le_65 <- out$age_proxy_counts[out$age_proxy_counts$metric == "total_mcl_age_le_65", , drop = FALSE]
expect_equal(age_le_65$distinct_person_count_display[[1]], "24", "Age <=65 proxy should populate when the age set is available.")
expect_true(grepl("not transplant eligibility", age_le_65$notes[[1]], fixed = TRUE), "Age <=65 must remain labelled as a younger proxy, not transplant eligibility.")

ib_counts <- out$ibrutinib_exposure_counts[out$ibrutinib_exposure_counts$denominator == "younger_mcl_proxy_age_le_65" & out$ibrutinib_exposure_counts$timing_window == "ever_observed", , drop = FALSE]
expect_equal(ib_counts$distinct_person_count_display[[1]], "12", "Ibrutinib counts should come from validated distinct-person exposure sets.")

strata <- out$treatment_strategy_strata_counts[out$treatment_strategy_strata_counts$denominator == "all_lyfo_mcl", , drop = FALSE]
strata_counts <- suppressWarnings(as.numeric(gsub(",", "", strata$distinct_person_count_display)))
expect_equal(sum(strata_counts, na.rm = TRUE), 30, "Ibrutinib x ASCT/HDT strata should be exhaustive for the denominator when generated from distinct-person sets.")
expect_true(all(grepl("Descriptive feasibility stratum only", strata$notes, fixed = TRUE)), "Treatment strategy strata must not imply causal comparability.")

high_risk <- out$high_risk_biology_counts
expect_true(any(high_risk$biology_component == "ki67_aeki_high_threshold" & high_risk$distinct_person_count_display == "4"), "Ki-67 high-threshold row should count only when an aggregate threshold set is supplied.")
standard <- high_risk[high_risk$biology_component == "standard_risk_biology_classifiable", , drop = FALSE]
expect_equal(standard$count_status[[1]], "count_not_available_requires_value_mapping", "Missing high-risk components must not be silently treated as standard risk.")

intersections <- out$answerability_intersections
ki67_overlap <- intersections[intersections$intersection_id == "age_le_65_ibrutinib_yes_asct_known_ki67_known", , drop = FALSE]
expect_equal(ki67_overlap$distinct_person_count_display[[1]], "8", "Ki-67 overlap should be computed from distinct-person intersections when sets are available.")
overall <- out$answerability_summary[out$answerability_summary$row_id == "overall_answerability", , drop = FALSE]
expect_equal(overall$status[[1]], "not_ready_for_risk_adapted_deescalation_answer", "The original de-escalation question must not be marked answerable while standard/high-risk classifiability remains incomplete.")
landmark_summary <- out$answerability_summary[out$answerability_summary$row_id == "landmark_design_available", , drop = FALSE]
expect_equal(landmark_summary$status[[1]], "not_ready_for_risk_adapted_deescalation_answer", "Standalone date/exposure counts must not be treated as a landmark-compatible design.")

plan_out <- mcl_count_build_outputs(project_root = root, mode = "plan", min_cell_count = 5L)
plan_strategy <- plan_out$treatment_strategy_strata_counts
expect_true(nrow(plan_strategy) == 0 || all(!nzchar(plan_strategy$distinct_person_count_display)), "Plan mode must not fabricate treatment-strategy strata counts.")
plan_summary <- plan_out$answerability_summary
expect_true(nrow(plan_summary) == 0 || any(plan_summary$status == "not_ready_for_risk_adapted_deescalation_answer"), "Plan mode answerability should stay conservative.")

tmp <- tempfile("mcl_answerability_")
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
paths <- mcl_count_write_outputs(out, tmp)
expect_file(file.path(tmp, "mcl_triangle_answerability_intersections.csv"))
expect_file(file.path(tmp, "mcl_triangle_answerability_summary.csv"))
expect_file(file.path(tmp, "mcl_triangle_treatment_strategy_strata_counts.csv"))
all_output_text <- paste(vapply(list.files(tmp, recursive = TRUE, full.names = TRUE), function(path) paste(readLines(path, warn = FALSE), collapse = "\n"), character(1)), collapse = "\n")
expect_false(grepl("010101|\\bcpr\\b|raw snippet|SELECT \\*|LIMIT 10", all_output_text, ignore.case = TRUE, perl = TRUE), "Answerability outputs must not emit patient identifiers, raw snippets, or raw preview SQL.")
