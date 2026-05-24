# MCL/TRIANGLE Answerability Counts Notes

## Purpose

This layer answers a narrower question than the evidence panel: not only whether TRIANGLE-relevant data elements exist, but whether aggregate distinct-person counts and intersections are populated enough to support a risk-adapted ASCT de-escalation feasibility assessment.

Counts remain feasibility evidence only. They are not treatment-effect estimates and do not establish comparability between ASCT/HDT and non-ASCT/HDT groups.

## Full Atlas Predicate Evidence Used

This patch uses the full atlas predicate/value evidence from the May 20 atlas output as a mapping seed. It does not treat cached value counts as final person-level overlaps.

- LYFO `subtype = MCL` is confirmed by atlas value evidence with aggregate value count 1,417, so the denominator predicate is `upper(trim(subtype::text)) = 'MCL'`.
- LYFO chemotherapy and ASCT/HDT yes/no fields use observed `Y/N` values, not `Ja/Yes`.
- CIT/immunochemotherapy is mapped from `Beh_ErDerForetagetKemo = 'Y'`, LYFO chemotherapy regimen fields, and mapped immunotherapy values.
- Ibrutinib exposure is mapped only from LYFO regimen fields containing `ibrutinib` unless a medication/code source is separately validated.
- First-line ASCT/HDT remains LYFO `Beh_*`; relapse/recurrence ASCT/HDT remains LYFO `Rec_*`.
- Ki-67 person counts use valid `AEKI000`-`AEKI100` codes through validated `SDS_pato.patientid` linkage. `SDS_dimpatologiskdiagnose` is not added to person counts unless person linkage is validated.

The helper `mcl_count_import_full_atlas_predicates()` can read the relevant atlas ZIP entries directly. It does not run source profiling or the full atlas.

## Added Outputs

- `outputs/mcl_triangle_age_proxy_counts.csv`
- `outputs/mcl_triangle_ibrutinib_exposure_counts.csv`
- `outputs/mcl_triangle_treatment_strategy_strata_counts.csv`
- `outputs/mcl_triangle_high_risk_biology_counts.csv`
- `outputs/mcl_triangle_answerability_intersections.csv`
- `outputs/mcl_triangle_answerability_summary.csv`

The outputs are written by `RUN_MCL_TRIANGLE_COUNTS.R` / `scripts/source_mcl_triangle_counts.R`. They do not run the full atlas, do not call `run_atlas()`, and do not run source profiling.

## Age <=65 Proxy

Age <=65 is labelled `younger_mcl_proxy_age_le_65`. It is not labelled transplant eligibility.

Patient birth/death mapping is now resolved rather than guessed. The configured demographics relation is verified through `information_schema`; if it is absent or lacks `patientid` and `date_birth`, the resolver discovers and scores candidates and writes `outputs/mcl_triangle_patient_demographics_resolver.csv`. Without a selected resolver row, age SQL is non-executable and no hard-coded patient table/view is used.

The DB-aware resolver distinguishes discovery evidence from executable linkage. For the current atlas evidence, `core.public.patient.date_birth` can be found but is cross-DB relative to `import.public.RKKP_LYFO`, so it is recorded as `cross_database_join_unavailable` instead of being joined in production SQL. The same-import-DB candidate `import.public.SDS_t_tumor.d_fdsdato` can be selected only after `outputs/mcl_triangle_age_source_validation.csv` shows a passing aggregate validation with no multiple-birth-date conflicts.

The date-anchor priority is:

1. `RKKP_LYFO.Reg_BehandlingBeslutning_dt`
2. `RKKP_LYFO.Beh_KemoterapiStart_dt`
3. `RKKP_LYFO.Reg_DiagnostiskBiopsi_dt`
4. unavailable

Date parsing is guarded for ISO and Danish day-month-year forms; blanks and malformed values become `NULL` inside aggregate SQL. Percentages depending on the younger denominator remain blank when the age denominator fails or is unavailable.

## CIT And Ibrutinib

CIT no longer uses the old `Ja/Yes` predicate. The all-MCL marginal treatment counts are deliberately anchored to `all_lyfo_mcl`, so they remain executable even while the younger-proxy age join is being validated. CIT is executable from the full-atlas LYFO evidence:

- `Beh_ErDerForetagetKemo = 'Y'`
- mapped regimen values such as `chop`, `bendamustin`, `maxichop`, `mantle2`, `mantle3`, `hdarac`, `dhap`, `beam`, `bcnu`, `beac`, and `ibrutinib`
- immunotherapy values such as `rituximab` and `obinutuzumab`

If a production query still returns zero for CIT, the output status becomes `count_available_zero_requires_value_mapping_review`.

Ibrutinib now starts with LYFO regimen fields and can expand to validated atlas-confirmed ATC/SKS sources:

- `Beh_Kemoterapiregime1 = 'ibrutinib'`
- `Beh_Kemoterapiregime2 = 'ibrutinib'`
- `Beh_Kemoterapiregime3 = 'ibrutinib'`
- ATC `L01XE27` in `SDS_indberetningmedpris`, `SP_OrdineretMedicin`, `SDS_epikur`, and `SDS_ekokur`
- SKS `BWHA169` in `SDS_t_sksube`, only after the `SDS_t_adm` bridge validates

The count is a deduplicated aggregate union of validated primary sources, not a sum of source counts. `RKKP_CLL.Beh_TargeteretBeh_Ibrutinib` and curated `CLL_TREAT_IBRUTINIB` evidence remain auxiliary and are not included in the primary MCL union by default. Ever-observed exposure can populate the main feasibility count; first-line or landmark Ibrutinib remains unavailable until exposure-date windows are validated.

## ASCT/HDT Semantics

First-line ASCT/HDT uses LYFO `Beh_*` fields:

- `RKKP_LYFO.Beh_Hoejdosisbehandling`
- `RKKP_LYFO.Beh_TypeAutologStamcellestoette`
- `RKKP_LYFO.Beh_Stamcelleinfusion_dt`

Relapse/recurrence transplant evidence remains separate:

- `RKKP_LYFO.Rec_Hoejdosisbehandling`
- `RKKP_LYFO.Rec_Stamcelleinfusion_dt`

Relapse `Rec_*` evidence is not merged into first-line ASCT/HDT counts.

## High-Risk Biology

The configuration file `clinical_questions/mcl_triangle_high_risk_biology_definitions.yml` defines component-level biology:

- blastoid/pleomorphic morphology
- Ki-67 AEKI high threshold, default `>=30%`
- TP53/p53/del17p
- high MIPI
- high MIPI-c
- LDH, stage, and performance-status components

Ki-67 AEKI known counts can be reported from valid aggregate AEKI person counts, but high Ki-67 threshold and MIPI-c/high-risk classes require dedicated aggregate threshold/person queries. Standard-risk classification is unavailable until high-risk components are known enough to rule them out.

## Landmark Feasibility

Standalone counts such as first-line treatment date availability are useful feasibility signals, but they do not make a landmark design available.

The runner marks landmark alive/event-free/exposure/biology rows as date/timing gaps unless a real landmark date-window query is executable. It does not reuse ever-observed exposure as landmark-compatible evidence.

## Answerability Policy

The conservative threshold is `20` non-suppressed people in key comparison/intersection cells before descriptive feasibility labels become positive. Counts alone never make the original causal de-escalation question ready.

Overall answerability remains `not_ready_for_risk_adapted_deescalation_answer` until Ibrutinib x ASCT/HDT strata, high-risk biology strata, outcomes, and landmark-compatible intersections are all populated with adequate non-suppressed cells.

## Console Summary

After each run, the RStudio console prints:

- count mode
- executed queries
- failed queries
- all MCL count
- age <=65 count
- CIT count
- Ibrutinib count
- ASCT/HDT count
- Ki-67 AEKI count
- whether the payload was updated

Use this summary to verify that a requested production run did not silently fall back to plan mode.

## Privacy Safeguards

All outputs are aggregate. They must not contain CPR, patient IDs, requisition IDs, raw dates, raw pathology text, snippets, row-level values, `SELECT *`, or raw-row `LIMIT` previews. Small cells are suppressed by the count runner threshold.

## How To Run

Plan mode:

```r
source("RUN_MCL_TRIANGLE_COUNTS.R")
```

Production aggregate mode:

```r
MCL_COUNT_MODE <- "production_aggregate"
MCL_COUNT_UPDATE_PAYLOAD <- TRUE
source("RUN_MCL_TRIANGLE_COUNTS.R")
```

Production mode should not silently fall back to plan mode. If database credentials, person-key mappings, date anchors, or value rules are unavailable, the outputs state the specific unavailable status.
