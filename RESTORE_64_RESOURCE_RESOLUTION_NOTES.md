# Restore 64-Resource Resolution Notes

Generated: 2026-05-19

## What Changed

This pass adds a canonical 64-resource layer to the refreshable DALY-CARE Atlas while preserving the successful 48-row production source map.

- Added `config/canonical-dalycare-resources-64.tsv` with exactly 64 canonical DALY-CARE resource-universe entries.
- Added `config/source-map.dalycare64.restored.tsv`, which keeps the current 48 production source-map rows and appends/restores missing canonical resource candidates.
- Added source-map metadata support for `source_key`, `source_label`, `canonical_resource_id`, `source_map_role`, `table_or_view`, and `expected_in_current_run`.
- Added reconciliation outputs that distinguish canonical resources, source-map rows, derived views, helper tables, current-profiled evidence, and legacy/reference-only evidence.
- Reclassified `BilleddiagnostikeUndersøgelser_Del2` as `legacy_unavailable_current_resolved` when current production output resolves it.
- Updated the Resource Catalog and Run Status payload/UI so fixture limitations, current production profiling, derived views, and reference-only evidence are not conflated.

## Files Modified

- `R/source_map.R`
- `R/source_reconciliation.R`
- `R/run_atlas.R`
- `R/html.R`
- `inst/templates/DALYCARE_atlas.html`
- `scripts/build_atlas_mockup_from_run_zip.R`
- `tests/test-run-atlas-fixtures.R`
- `tests/test-restore-64-resource-resolution.R`
- `config/canonical-dalycare-resources-64.tsv`
- `config/source-map.dalycare64.restored.tsv`

## New Outputs

Generated runs now include:

- `outputs/current_run_source_map_audit.csv`
- `outputs/canonical_resource_reconciliation_64.csv`
- `outputs/source_map_row_to_canonical_resource_crosswalk.csv`
- `outputs/legacy_reference_vs_current_profiled_evidence.csv`
- `outputs/remaining_canonical_resources_activation_plan.csv`

These complement the prior reconciliation outputs rather than replacing them.

The source-map crosswalk now models source-map roles as overlapping booleans. A row can be canonical and derived/view at the same time when it explicitly maps to a canonical resource.

## 48-Source Production Run vs 64-Resource Universe

The latest real DALY-CARE run used a 48-row source map and resolved all 48 rows. That does not mean the DALY-CARE resource universe is 48 resources. The atlas now reports both:

- Canonical DALY-CARE resources: 64
- Source-map rows profiled in the current run: 48

The source-map rows include canonical resources, derived/helper views, and helper/reference tables. Derived views are retained because they are useful atlas inputs, but they are not counted as canonical resources.

## Del2 Reclassification

Legacy V033 did not resolve `BilleddiagnostikeUndersøgelser_Del2`. The current production run did resolve:

`SP_BilleddiagnostikeUndersoegelser_Del2 -> import.public.SP_BilleddiagnostiskeUndersøgelser_Del2`

with 1,909,409 rows and 12 columns in the supplied production outputs. The atlas therefore classifies this resource as:

`legacy_unavailable_current_resolved`

It must not be treated as current-unavailable unless a future reviewed production attempt proves otherwise.

## Restored / Added Canonical Candidates

The restored source map includes candidates for canonical resources omitted from the 48-row production map, including late-cartography and curated resources such as:

- `EKOKUR`
- `t_mikro`
- `t_konk`
- `forloebsmarkoerer`
- `Aktive_Problemliste_Diagnoser`
- `Behandlingskontakter_diagnoser`
- `Behandlingsplaner_del2`
- `Flytningshistorik`
- `Journalnotater_del2`
- `SP_PatientInfo`
- `microbiology_analysis`
- `microbiology_culture`
- `microbiology_culture_resistance`
- `microbiology_microscopy`
- `biochemistry`
- `IGHVIMGT`
- `Flowcytometry`
- `FISH`
- `CLLPANEL_WIDE`
- `BIOBANK_SAMPLES`
- `CLL_TREAT`
- `MM_TREAT_DARA`
- `CLL_TREAT_IBRUTINIB`
- `DANRICHT`

Some are normal DB-attemptable resources, while `FISH` and `DANRICHT` remain special/manual/embedded resources based on the legacy evidence.

## How to Interpret New Metrics

- `canonical_expected_resources`: the 64-resource DALY-CARE universe.
- `canonical_current_profiled_resources`: canonical resources profiled in the current run.
- `canonical_current_not_attempted_resources`: canonical resources not attempted by the current source map.
- `source_map_rows_profiled`: source-map rows resolved/profiled in the current run.
- `derived_view_rows_profiled`: profiled source-map rows that are useful derived/helper views rather than canonical resources.
- `legacy_reference_only_resources`: semantic/reference evidence sources that were not refreshed in the current run.
- `legacy_unavailable_current_resolved_resources`: resources unavailable to V033/legacy but resolved by current production output.

## How to Run the Restored 64-Resource Source Map

For production validation, run the atlas with:

```sh
Rscript scripts/run_atlas.R . config/source-map.dalycare64.restored.tsv atlas_runs report
```

This should be done only in an environment with the required DALY-CARE database/file access. Local fixture tests do not require production credentials.

## Tests

Focused checks run in this pass:

```sh
Rscript tests/test-production-source-recovery.R
Rscript tests/test-restore-64-resource-resolution.R
Rscript tests/test-run-atlas-fixtures.R
node scripts/visual_qa_atlas.js <generated site/DALYCARE_atlas.html> qa_screenshots_restore_64_resource_resolution
```

The generated visual QA passed for the rebuilt production-run site.

## Known Limitations

- The restored source map is a production candidate. The newly restored canonical resources still require a real DALY-CARE production run to confirm row counts and accessibility.
- Legacy/reference semantic evidence is preserved and labelled; it is not removed simply because a resource was not profiled in the supplied 48-source run.
- Current row counts are taken from current run outputs only. V033 row counts remain historical/reference evidence and are not used as current counts.

## Recommended Next Production Validation

1. Run `config/source-map.dalycare64.restored.tsv` in the production environment.
2. Review `outputs/canonical_resource_reconciliation_64.csv`.
3. Review `outputs/source_map_row_to_canonical_resource_crosswalk.csv` for derived/helper rows.
4. Confirm missing canonical resources are either resolved, intentionally not attempted, special/manual, or have a clear action item.
5. Keep `BilleddiagnostikeUndersøgelser_Del2` under regression protection so it is not downgraded based on legacy absence alone.
