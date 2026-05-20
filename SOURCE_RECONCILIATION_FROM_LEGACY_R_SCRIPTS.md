# Source Reconciliation From Legacy R Scripts

## What Changed

The atlas now carries a legacy-aware resource reconciliation layer. It does not only list the 64 V033/DALY-CARE expected resources; it also documents how the legacy cartography R scripts resolved or accounted for them and compares that evidence with the current refreshable atlas run.

Generated outputs:

- `outputs/legacy_cartography_source_resolution_audit.csv`
- `outputs/source_resolution_delta_legacy_vs_current.csv`
- `outputs/atlas_resource_reconciliation.csv`
- `outputs/source_truth_evidence_matrix.csv`
- `outputs/source_truth_summary.csv`

The Resource Catalog UI now shows expected resources even when they were not explored in the current run.

The later production recovery pass adds `config/source-map.dalycare64.production.tsv`
as a concrete resolver candidate built from this evidence. That file is the
place to add production aliases, direct-SQL table patterns, manual-file
declarations, and known-unavailable declarations without changing the historical
legacy audit.

## Legacy Package Inspected

The legacy package inspected was:

- `DALY-CARE cartography(1).zip`

The ZIP was unpacked locally for inspection. The current pipeline uses the checked-in reference extracts under:

- `config/cartography-reference/files/`

## Legacy R Scripts Inspected

The relevant scripts were:

- `000_dalycare_cartography.R`
- `000_dalycare_cartography_part2.R`
- `000_dalycare_cartography_part3.R`
- `000_dalycare_cartography_part4.R`
- `000_dalycare_cartography_part5.R`
- `000_dalycare_cartography_part6.R`
- `000_dalycare_cartography_part7.R`

The main script defines the expected DALY-CARE resource universe in `default_datasets` and writes the original load-status/catalog outputs. Parts 4, 6, and 7 contain the late recovery logic for resources not resolved by ordinary `load_dataset()` paths.

## Generated Legacy Files Inspected

The reconciliation builder reads these generated legacy extracts when present:

- `cartography_dataset_load_status_updated.tsv`
- `cartography_part4_resolution_log.tsv`
- `cartography_part6_resolution_log.tsv`

Other cartography output files were reviewed to confirm source families and domain context, including PATOBANK, SP imaging, laboratory/NPU, microbiology, treatment, biobank, and registry panel outputs.

## Expected 64 Resources

The canonical expected-resource file is:

- `config/expected_dalycare_resources_64.tsv`

It contains the 64 V033 resources with aliases, legacy status, historical row/patient placeholders where available, known absence status, and notes. Legacy row counts are historical reference evidence only. They are not used as current run counts.

## Legacy Resolution Summary

The corrected source-truth audit preserves:

- 64 expected resources.
- 63 resources resolved/profiled or accounted for as available evidence by the final V33 atlas.
- 1 resource known unavailable in the final V33 evidence.

The known unavailable resource is:

- `BilleddiagnostikeUndersøgelser_Del2`
`FISH` and `DANRICHT` are treated as special/manual/embedded rather than known unavailable because the final V33 HTML `part4_resolved` evidence marks both as resolved through embedded registry/project-file evidence, even though neither appears as a normal standalone PostgreSQL table in the checked-in legacy TSV extracts.

## Ported Resolver Logic

The current source resolver now knows the late-cartography aliases and spelling variants documented by the legacy scripts, including:

- `t_mikro` -> `SDS_t_mikro_ny`
- `t_konk` -> `SDS_t_konk_ny`
- `t_doedsaarsag` -> `SDS_t_dodsaarsag_2`
- `procedure_kirurgi` -> `SDS_procedurer_kirurgi`
- `procedure_andre` -> `SDS_procedurer_andre`
- `SP_Administreret_Medicin` -> `SP_AdministreretMedicin`
- `SP_ADT_Haendelser` -> `SP_ADT_haendelser`
- `Aktive_Problemliste_Diagnoser` -> `SP_AktiveProblemlisteDiagnoser`
- `Behandlingskontakter_diagnoser` -> `SP_BehandlingskontakterOgDiagnoser`
- `Behandlingsplaner_del1` -> `SP_Behandlingsplaner_Del1`
- `Behandlingsplaner_del2` -> `SP_Behandlingsplaner_Del2`
- `Journalnotater_del1` -> `SP_Journalnotater_Del1`
- `Journalnotater_del2` -> `SP_Journalnotater_Del2`
- `BilleddiagnostikeUndersøgelser_Del1` -> `SP_BilleddiagnostiskeUndersøgelser_Del1`
- `lab_forsker` -> `SDS_laboratorieproevesvar`
- `biochemistry` -> `PERSIMUNE_biochemistry`
- `microbiology_*` -> `PERSIMUNE_microbiology_*`
- `BIOBANK_SAMPLES` -> `LAB_BIOBANK_SAMPLES`
- `CLLPANEL_WIDE` -> `LAB_CLLPANEL_WIDE`
- `MM_TREAT_DARA` -> `REQUIRE_PERMISSION_MM_TREAT_DARA`

The resolver records these as alias/direct-resolution paths when the current DB catalog exposes a matching table. It does not hard-code legacy counts as current counts.

## Current Delta Categories

`outputs/source_resolution_delta_legacy_vs_current.csv` uses these categories:

- `present_in_both`
- `legacy_profiled_current_missing`
- `legacy_resolved_current_not_tested`
- `legacy_known_unavailable`
- `legacy_special_manual_or_embedded`
- `current_fixture_only`
- `current_missing_unexpectedly`
- `uncertain_manual_review`

Every expected resource must have an explicit status. No expected resource should silently disappear.

## UI Changes

The Resource Catalog now reports:

- Expected resource count.
- Legacy resolved/accounted count.
- Current explored count.
- Known unavailable count.
- Missing/review-needed count.

Each expected resource row shows:

- Legacy status.
- Current status.
- Resolution method.
- Current table/schema when available.
- Historical legacy rows when available.
- Action required.

## Known Limitations

- Legacy row counts are historical and may not match a current database.
- Direct SQL patterns are represented as safe table/schema/alias patterns; credentials and environment-specific connection details are not emitted.
- Some current runs are fixture/mock runs. In those runs, many expected production resources may be `not_tested_current` rather than truly absent.
- `FISH` and `DANRICHT` remain special/manual/embedded resources until current standalone or curated source rows are available.

## How To Test Locally

```sh
Rscript scripts/run_tests.R
git diff --check
node scripts/visual_qa_atlas.js <generated-run>/site/DALYCARE_atlas.html qa_screenshots
```

When `Rscript` is not on PATH on Windows, use:

```sh
"C:\Program Files\R\R-4.3.1\bin\Rscript.exe" scripts/run_tests.R
```
