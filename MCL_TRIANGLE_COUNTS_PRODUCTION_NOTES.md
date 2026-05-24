# MCL/TRIANGLE Counts Production Notes

## What Changed

This patch adds a standalone aggregate-count layer for the MCL/TRIANGLE feasibility panel. The count layer is intentionally separate from evidence matching: it only reports distinct-person cohort-size feasibility counts when person keys, date anchors, and value semantics are mapped well enough for aggregate production SQL.

The default runner remains plan-only:

```r
source("RUN_MCL_TRIANGLE_COUNTS.R")
```

Production aggregate execution is explicit:

```r
MCL_COUNT_MODE <- "production_aggregate"
MCL_COUNT_UPDATE_PAYLOAD <- TRUE
source("RUN_MCL_TRIANGLE_COUNTS.R")
```

The runner respects user-defined `MCL_COUNT_*` values that already exist in the R session. It does not call `run_atlas()`, does not profile the full source map, does not use raw-row previews, and does not update the payload by default.

Optional atlas-output evidence can be supplied without rerunning the atlas:

```r
MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- "path/to/atlas_outputs"
MCL_TRIANGLE_ATLAS_OUTPUT_ZIP <- "path/to/atlas_output.zip"
```

This evidence is discovery-only. The standalone probe still requires aggregate production validation before selecting an age source.

The same rule now applies to treatment/code evidence. Main-atlas outputs can surface ATC `L01XE27` and SKS `BWHA169` as Ibrutinib evidence in `SDS_indberetningmedpris`, `SDS_t_sksube`, `SDS_epikur`, `SDS_ekokur`, and `SP_OrdineretMedicin`, but those sources only contribute to `ibrutinib_exposure` after aggregate production validation. `SDS_t_sksube.BWHA169` additionally requires a validated `SDS_t_sksube.v_recnum -> SDS_t_adm.k_recnum/patientid` bridge before any person count is used.

The same atlas-aware pattern now covers Ki-67. Main-atlas outputs can identify current PATOBANK coded pathology and text source space in the import DB: `SDS_pato`, `SDS_t_mikro_ny`, and `SDS_t_konk_ny`. The standalone runner writes a Ki-67 source inventory and validates the coded `SDS_pato.c_snomedkode` AEKI route with aggregate SQL. Pathology text rows are source-space/bridge candidates only unless `MCL_TRIANGLE_KI67_TEXT_SCAN <- TRUE` is explicitly enabled; even then, text-derived numeric counts remain `text_pattern_numeric_candidate_requires_validation` and do not upgrade risk classifiability.

The console output reports the selected mode, project root, output directory, payload-update flag, DB connection attempt/availability, executable query count, executed query count, and populated count rows. If `MCL_COUNT_MODE <- "production_aggregate"` is selected and credentials are unavailable, the outputs remain in `count_mode = production_aggregate` and use `production_aggregate_failed_credentials_unavailable`; the runner does not silently fall back to plan mode.

Production query failures are now row-level output states rather than implicit plan-mode fallbacks. Count rows include `query_attempted`, `query_executed`, `query_success`, `error_class`, and `error_message_sanitized`. Sanitized errors are intended to show whether a date cast, credentials, mapping, or query problem occurred without exposing connection strings, identifiers, raw values, or snippets.

## Mapping Contract

Two mapping files control whether counts are executable:

- `config/mcl_triangle_person_date_mapping.tsv`
- `config/mcl_triangle_count_value_mappings.tsv`

The person/date mapping records the source table, selected person key, date anchors, linkage confidence, and whether the source is usable for distinct-person counts. If a source has no validated person key, it is audited but cannot contribute people.

The value mapping records the clinical interpretation of source fields and codes. A mapped person key is not enough: the MCL denominator, ASCT/HDT fields, Ki-67 AEKI codes, and other data points also require a validated or explicitly flagged value rule.

## Current Validation State

The plan-mode outputs deliberately do not report real cohort sizes unless production aggregate queries run successfully.

Current validated mapping highlights:

- `RKKP_LYFO.patientid` is the primary person key for the MCL registry denominator and LYFO treatment/follow-up fields.
- Patient birth/death joins are no longer trusted from a configured table name alone. The count runner now discovers candidates across all named DB connections and records `db_name`, `source_db_name`, `lyfo_db_name`, and cross-DB join availability.
- Main-atlas output evidence can show that `core.public.patient.date_birth` exists while `RKKP_LYFO` lives in the `import` DB. That evidence is retained, but it is labelled `cross_database_join_unavailable` and is not used for same-SQL LYFO age joins.
- `import.public.SDS_t_tumor.d_fdsdato` is treated as a same-import-DB birth-date candidate only after aggregate validation succeeds. It is not trusted from atlas metadata alone.
- `SDS_pato.patientid` is available for aggregate Ki-67 AEKI person-count queries.
- Atlas-profiled `SDS_pato.v_fritekst`, `SDS_t_mikro_ny.v_fritekst`, and `SDS_t_konk_ny.v_fritekst` are now inventoried as Ki-67 source space. `t_mikro` and `t_konk` require aggregate bridge validation through PATOBANK keys before they can produce MCL person counts.
- `SDS_dimpatologiskdiagnose` contains AEKI evidence locations but is not currently allowed to contribute person counts because person linkage is not validated.
- medication, procedure, and death-cause candidate sources remain non-countable until person linkage and value semantics are mapped.

Plan mode uses `query_executable_not_run` for mapped aggregate SQL templates that are safe to review but have not been executed. Production aggregate mode uses `production_aggregate_count_available` when a query returns a displayable distinct-person count, `suppressed_small_cell` when the returned count is below the configured threshold, `production_aggregate_failed_credentials_unavailable` when no read-only DB adapter can be opened, and `production_aggregate_failed_query_error` when an executable query cannot be completed.

## Patient Demographics Resolver

Age-dependent counts require a verified patient demographics table or view. The resolver writes `outputs/mcl_triangle_patient_demographics_resolver.csv` with the database name, search path, verification timestamp, verification mode, every candidate, and the selected row if one is usable.

Resolution order:

1. Verify the configured mapping in `config/mcl_triangle_person_date_mapping.tsv`.
2. If that relation is not present or lacks `patientid` and `date_birth`, discover candidates from `information_schema.columns`.
3. Run a zero-row relation probe (`select count(*) ... where false`) and a zero-row column-reference probe (`select "patientid", "date_birth" ... where false`) using the same DB connection that will run count SQL.
4. Run a LYFO co-residency check for same-DB candidates. Cross-DB candidates are preserved as evidence but are not selected unless an explicit bridge becomes available.
5. Score only candidates that pass the required probes, with boosts for the configured relation, `date_death_fu`, DALY patient-style naming, atlas/source-map evidence, and optional safe aggregate row-count compatibility.
6. Select the highest-scoring probe-passing candidate. Equal-score candidates are resolved by schema/table sort order and labelled `deterministic_tie_break_requires_review`, not clinically validated.
7. After production age queries run, perform a final consistency check. If any age query fails with `relation ... does not exist` for the selected demographics relation, the resolver selection is invalidated, `post_selection_execution_*` columns record the failure, age SQL is regenerated as non-executable, and age count rows are reset to `count_not_available_requires_patient_demographics_mapping`.

Disease-specific, treatment, event, diagnosis, pathology, medication, or registry tables are not accepted as fallback patient-demographics relations merely because they contain `patientid` and `date_birth`. Examples such as `RKKP_CLL_CLEAN`, `CLL_*`, `RKKP_DaMyDa*`, MM/myeloma-like, medication, procedure, and diagnosis tables are rejected as `rejected_non_mcl_demographics_source` unless an explicit general demographics mapping is configured and then verified by the probes above.

If no candidate is selected, age query templates begin with:

```sql
-- NOT EXECUTABLE: requires patient demographics mapping
```

and age rows use `count_not_available_requires_patient_demographics_mapping`. In that state, all-MCL marginal counts remain independently executable and should not be blocked by the age join.

## MCL Denominator

The intended MCL predicate is `RKKP_LYFO.subtype = 'MCL'`, but it is not used blindly. The count layer first checks aggregate metadata for a LYFO subtype field/value confirming MCL or mantle-cell meaning. If the exact field/value semantics cannot be confirmed, denominator counts are marked:

`count_not_available_requires_value_mapping`

This prevents row counts or broad LYFO source availability from being presented as a cohort size.

## Age Anchor

Age <=65 is labelled as a younger/transplant-eligible proxy, not transplant eligibility.

The deterministic age-anchor priority is:

1. LYFO treatment-decision date (`Reg_BehandlingBeslutning_dt`)
2. first-line treatment start date (`Beh_KemoterapiStart_dt`)
3. LYFO diagnostic-biopsy date (`Reg_DiagnostiskBiopsi_dt`)
4. unavailable

The selected anchor is written to `mcl_triangle_count_query_review.csv` and count output provenance when executable SQL can be planned.

The age query uses guarded date parsing for the resolver-selected birth-date field and the selected LYFO anchor. Blank, malformed, or unsupported date strings become unavailable date rows inside the aggregate SQL instead of crashing the entire count layer. The younger denominator is only executable when the selected age source passed metadata verification, relation/column probes, LYFO co-residency, and aggregate validation where required.

`outputs/mcl_triangle_age_source_validation.csv` records aggregate validation metrics for the selected same-DB birth-date candidate, including MCL people, birth-date availability, anchor availability, plausible age, multiple-birth-date conflicts, age <=65, age >65, and missing/uncomputable age. The default multiple-birth-date tolerance is zero, so any joined MCL person with multiple distinct birth dates fails the source closed.

## ASCT/HDT Semantics

First-line ASCT/HDT counts are based on LYFO `Beh_*` fields only:

- `Beh_Hoejdosisbehandling`
- `Beh_TypeAutologStamcellestoette`
- `Beh_Stamcelleinfusion_dt`

Relapse/recurrence transplant counts are kept separate:

- `Rec_Hoejdosisbehandling`
- `Rec_Stamcelleinfusion_dt`

Date fields may support non-missing valid-date evidence. Categorical fields still require value semantics such as yes/no/unknown mapping before final analytic use. CLL or DaMyDa transplant signals are not counted as first-line MCL ASCT/HDT.

## Ki-67 AEKI Person Counts

Ki-67 AEKI code evidence is counted only where person linkage is validated.

Current production-count route:

- `public.SDS_pato.c_snomedkode`
- valid code pattern `AEKI000` through `AEKI100` and supported encoded variants
- distinct linked people only

`SDS_dimpatologiskdiagnose` AEKI evidence is not summed into person counts until its person key is validated. If both pathology sources become linkable later, the count must be a database-side union of distinct people, not a sum of source-level code counts.

When `ki67_aeki` is successfully counted in production aggregate mode, `outputs/mcl_triangle_ki67_person_count_summary.csv` is populated from that same distinct-person count. For example, a production row such as `ki67_aeki = 37` should surface as an all-LYFO-MCL Ki-67 availability row, with validation status `aggregate_evidence_found_requires_validation`.

The runner now also writes:

- `outputs/mcl_triangle_atlas_ki67_source_inventory.csv`
- `outputs/mcl_triangle_ki67_source_validation.csv`
- `outputs/mcl_triangle_ki67_aeki_code_counts.csv`
- `outputs/mcl_triangle_ki67_aeki_person_counts.csv`
- `outputs/mcl_triangle_ki67_percent_distribution.csv`
- `outputs/mcl_triangle_ki67_threshold_counts.csv`
- `outputs/mcl_triangle_ki67_text_bridge_validation.csv`
- `outputs/mcl_triangle_ki67_text_pattern_counts.csv`
- `outputs/mcl_triangle_ki67_text_person_counts.csv`
- `outputs/mcl_triangle_ki67_union_counts.csv`
- `outputs/mcl_triangle_ki67_overlap_by_source.csv`

Knownness and high-threshold counts are separated. `ki67_aeki_known` means a validated aggregate AEKI percent code exists for an MCL person. `ki67_aeki_high_threshold` uses the threshold in `clinical_questions/mcl_triangle_high_risk_biology_definitions.yml` unless overridden by `MCL_TRIANGLE_KI67_THRESHOLD_PERCENT`. Missing Ki-67 is never treated as standard-risk biology.

## Outputs

The focused count outputs are:

- `outputs/mcl_triangle_person_key_audit.csv`
- `outputs/mcl_triangle_patient_demographics_resolver.csv`
- `outputs/mcl_triangle_age_source_locator.csv`
- `outputs/mcl_triangle_atlas_age_source_inventory.csv`
- `outputs/mcl_triangle_age_source_validation.csv`
- `outputs/mcl_triangle_atlas_treatment_source_inventory.csv`
- `outputs/mcl_triangle_atlas_ki67_source_inventory.csv`
- `outputs/mcl_triangle_ibrutinib_source_validation.csv`
- `outputs/mcl_triangle_ibrutinib_source_counts.csv`
- `outputs/mcl_triangle_ibrutinib_union_counts.csv`
- `outputs/mcl_triangle_ibrutinib_overlap_by_source.csv`
- `outputs/mcl_triangle_count_query_review.csv`
- `outputs/mcl_triangle_data_point_counts.csv`
- `outputs/mcl_triangle_inclusion_waterfall.csv`
- `outputs/mcl_triangle_overlap_matrix.csv`
- `outputs/mcl_triangle_exposure_strata_counts.csv`
- `outputs/mcl_triangle_landmark_feasibility_counts.csv`
- `outputs/mcl_triangle_ki67_person_count_summary.csv`
- `outputs/mcl_triangle_ki67_source_validation.csv`
- `outputs/mcl_triangle_ki67_aeki_code_counts.csv`
- `outputs/mcl_triangle_ki67_aeki_person_counts.csv`
- `outputs/mcl_triangle_ki67_percent_distribution.csv`
- `outputs/mcl_triangle_ki67_threshold_counts.csv`
- `outputs/mcl_triangle_ki67_text_bridge_validation.csv`
- `outputs/mcl_triangle_ki67_text_pattern_counts.csv`
- `outputs/mcl_triangle_ki67_text_person_counts.csv`
- `outputs/mcl_triangle_ki67_union_counts.csv`
- `outputs/mcl_triangle_ki67_overlap_by_source.csv`
- `outputs/mcl_triangle_count_summary.csv`
- `outputs/mcl_triangle_count_query_templates.sql`
- `outputs/output_generation_status.csv`

Every count row carries provenance columns: `count_mode`, `source_tables`, `person_key_used`, `date_anchor_used`, `value_rule_used`, `generated_at`, and `validation_status`.

Counts are scoped to the denominator declared in `clinical_questions/mcl_triangle_count_definitions.yml`. All-MCL marginal counts for diagnosis date, first-line treatment date, CIT, first-line ASCT/HDT, relapse ASCT/HDT, Ibrutinib, Ki-67 AEKI, OS/death, and relapse/progression remain independent of the age denominator. Age-specific versions are additional rows/intersections and are unavailable until the patient demographics resolver verifies a usable table/view.

`outputs/output_generation_status.csv` records whether packaged count outputs were generated after the latest resolver/mapping change. Outputs are marked fresh after the resolver change or explicitly stale with a reason.

A coherent post-selection invalidation is considered fresh output, not stale output. In that case, the resolver audit keeps the production relation-not-found diagnostic in `post_selection_execution_error_sanitized`, age rows point readers to that resolver audit, and query templates must show age SQL as non-executable.

The inclusion-waterfall output is only a true cumulative waterfall when dedicated intersection queries are available. If production mode has only marginal data-point counts, the output is labelled `data_point_availability_not_cumulative`. Overlap, exposure-strata, and landmark files are not left empty; they either contain real aggregate intersections or explicit unavailable/status rows explaining which mapping or intersection query is still required.

The CIT/immunochemotherapy count is guarded against a misleading zero. If the current LYFO predicate executes and returns zero, the row is labelled `count_available_zero_requires_value_mapping_review` until the exact LYFO treatment value coding is checked. This avoids presenting an overly narrow predicate as clinical truth.

## Privacy Safeguards

All query templates are aggregate-only. The count layer prohibits:

- `SELECT *`
- raw-row `LIMIT` previews
- CPR or person identifiers in output CSVs
- raw dates in output CSVs
- raw pathology text or snippets
- row-level values

Small-cell suppression defaults to `n < 5`. Percentages are blank when numerator counts are suppressed or denominators are unavailable, so suppressed cells cannot be reverse-engineered from percentages.

## Remaining Gaps

The current plan-mode outputs are conservative. Real counts require production aggregate execution and confirmed value mappings. In particular:

- MCL subtype value semantics must be confirmed before denominator counts are trusted.
- ASCT/HDT categorical values need source-specific yes/no/unknown confirmation.
- Ibrutinib, TP53/p53/del17p, blastoid/pleomorphic morphology, toxicity proxies, and some landmark requirements remain mapping-limited.
- `RKKP_DaMyDa.FU_Doed_aarsag` is not direct infection evidence; if ever used, it should only be labelled as a cause-of-death infection proxy and kept out of direct infection evidence cards.

## Interpretation

Counts are aggregate distinct-person feasibility counts. They show whether data elements and combinations are available for study design. They are not treatment-effect estimates and do not establish comparability between treatment groups.

ASCT/HDT x ibrutinib strata are descriptive feasibility strata only. They do not handle timing, eligibility, response, immortal time, or confounding unless a landmark or target-trial emulation design is implemented and validated.
