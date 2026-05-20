# Fix 64-Resource Mockup Issues Notes

Generated: 2026-05-20

## What Changed

This pass cleans up the 64-resource restoration mockup after reviewing the latest production-derived atlas package.

- Source-map roles are no longer modeled as mutually exclusive buckets.
- `t_dalycare_diagnoses` is consistently represented as a canonical profiled resource, even when source-map rows also behave like derived/view layers.
- `BilleddiagnostikeUndersøgelser_Del2` now has direct current-run evidence in the Del2 regression audit.
- Generic unrelated `Del2` resources are filtered out of the Billeddiagnostik Del2 audit unless they also carry imaging/Billeddiagnostik context.
- Added `outputs/remaining_canonical_resources_activation_plan.csv` for the 22 canonical resources not attempted in the 48-row production source map.
- Updated summary metrics and UI wording to say that 64-resource reconciliation is restored, while 64-resource production profiling is not yet complete.

## Files Modified

- `R/source_map.R`
- `R/source_reconciliation.R`
- `R/run_atlas.R`
- `R/html.R`
- `inst/templates/DALYCARE_atlas.html`
- `scripts/build_atlas_mockup_from_run_zip.R`
- `tests/test-run-atlas-fixtures.R`
- `tests/test-restore-64-resource-resolution.R`
- `config/source-map.dalycare64.restored.tsv`

## Non-Mutually-Exclusive Source-Map Roles

`outputs/source_map_row_to_canonical_resource_crosswalk.csv` now includes:

- `source_map_role_primary`
- `source_map_role_secondary`
- `is_canonical_resource`
- `is_derived_view`
- `is_helper_table`
- `is_current_profiled`

These booleans are independent. A row can be both canonical and derived, or canonical and helper, when the source-map row explicitly maps to a canonical resource.

## t_dalycare_diagnoses Fix

The prior mockup could show `t_dalycare_diagnoses` as profiled in canonical reconciliation while its source-map row looked non-canonical in the crosswalk. It now appears as:

- `canonical_resource_id = t_dalycare_diagnoses`
- `is_canonical_resource = TRUE`
- `is_derived_view = TRUE` where the row is also a DALY view/source-map view layer
- `is_current_profiled = TRUE`

The canonical profiled count remains 40 for the current production-derived mockup.

## Del2 Current-Run Evidence

`outputs/billeddiagnostik_del2_regression_audit.csv` now includes current-run evidence rows from:

- `outputs/atlas_sources.csv`
- `outputs/atlas_source_resolution.csv`
- `outputs/canonical_resource_reconciliation_64.csv`
- `outputs/source_map_row_to_canonical_resource_crosswalk.csv`

These rows show:

- canonical resource: `BilleddiagnostikeUndersøgelser_Del2`
- current source key: `SP_BilleddiagnostikeUndersoegelser_Del2`
- resolved table: `import.public.SP_BilleddiagnostiskeUndersøgelser_Del2`
- final classification: `legacy_unavailable_current_resolved`
- current rows/columns from the generated current-run outputs

## Del2 Audit Noise Reduction

The audit no longer treats generic `Del2` matches as relevant unless the same line also contains imaging/Billeddiagnostik context. This prevents unrelated resources such as treatment-plan, blood-culture, and journal-note Del2 tables from polluting the Del2-specific audit.

## Remaining 22 Activation Candidates

`outputs/remaining_canonical_resources_activation_plan.csv` lists the 22 canonical resources not attempted in the current 48-row source map:

- `Aktive_Problemliste_Diagnoser`
- `Behandlingskontakter_diagnoser`
- `Behandlingsplaner_del2`
- `BIOBANK_SAMPLES`
- `biochemistry`
- `CLL_TREAT`
- `CLL_TREAT_IBRUTINIB`
- `CLLPANEL_WIDE`
- `EKOKUR`
- `Flowcytometry`
- `Flytningshistorik`
- `forloebsmarkoerer`
- `IGHVIMGT`
- `Journalnotater_del2`
- `microbiology_analysis`
- `microbiology_culture`
- `microbiology_culture_resistance`
- `microbiology_microscopy`
- `MM_TREAT_DARA`
- `SP_PatientInfo`
- `t_konk`
- `t_mikro`

`FISH` and `DANRICHT` remain separate as special/manual/embedded resources.

## Current-Profiled vs Not-Attempted vs Special/Manual

The current production-derived mockup reports:

- Canonical resources: 64
- Canonical profiled current run: 40
- Canonical not attempted current run: 22
- Special/manual/embedded: 2
- Source-map rows profiled current run: 48
- Derived-view source-map rows: 9
- Helper source-map rows: 1

Not attempted means the resource was not in the 48-row source map used for this production run. It is not automatically a failure.

## Canonical Resources vs Source-Map Rows

Canonical resources are the 64-resource DALY-CARE universe. Source-map rows are the operational rows the current run actually attempted. Some source-map rows are derived views or helper tables and must be counted separately.

## Known Limitations

- The restored source map is ready for targeted production activation, but the 22 activation candidates still require a production run with the restored 64-resource source map.
- Current counts are always read from generated outputs. V033/legacy row counts remain historical reference only.
- Manual/special resources may require file permissions, embedded-field interpretation, or project-specific access before they can be profiled as normal source-map rows.

## Recommended Next Production Validation

1. Run `config/source-map.dalycare64.restored.tsv` in the production environment.
2. Review `outputs/remaining_canonical_resources_activation_plan.csv`.
3. Confirm each activation candidate either resolves, needs permission, or receives a reviewed action item.
4. Keep Del2 under regression protection as `legacy_unavailable_current_resolved`.
5. Review `legacy_reference_vs_current_profiled_evidence.csv` for evidence sources that remain reference-only.
