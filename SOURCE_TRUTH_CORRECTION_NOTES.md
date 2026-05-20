# Source Truth Correction Notes

## Scope

This pass corrects the DALY-CARE Atlas 64-resource accounting. It does not add
new UI features, change clinical semantics, or reuse legacy row counts as
current-run counts.

## Legacy Evidence Inspected

The legacy package `DALY-CARE cartography(1).zip` was unpacked and inspected,
including:

- `000_dalycare_cartography.R`
- `000_dalycare_cartography_part2.R`
- `000_dalycare_cartography_part3.R`
- `000_dalycare_cartography_part4.R`
- `000_dalycare_cartography_part5.R`
- `000_dalycare_cartography_part6.R`
- `000_dalycare_cartography_part7.R`
- `DALYCARE_atlas_AOT_V33.html`
- generated cartography TSV/CSV outputs under `config/cartography-reference/files`

The most important generated/reference files were:

- `cartography_dataset_load_status_updated.tsv`
- `cartography_part4_resolution_log.tsv`
- `cartography_part6_resolution_log.tsv`
- `cartography_columns.tsv`
- `cartography_tumor_value_counts.tsv`
- `cartography_part4_*_value_counts.tsv`
- `cartography_part6_*_value_counts.tsv`

## Authority Order

When artifacts disagree, this pass uses the following source-truth order:

1. Final V33 rendered atlas evidence in `DALYCARE_atlas_AOT_V33.html`, especially
   the headline accounting and embedded `part4_resolved` data.
2. Generated legacy profile/value/count files with row-level evidence.
3. Legacy resolution logs (`part4`, `part6`).
4. Legacy R script source, which documents resolver intent but can include
   conditional branches that were not the final run outcome.
5. Current reconciliation outputs, which are treated as current-run evidence
   only, not historical truth.

## Corrected Historical Accounting

The final V33 atlas states:

- expected DALY-CARE resources: 64
- final legacy profiled/resolved resources: 63
- final legacy accounted resources: 64
- final legacy known unavailable resources: 1

This corrects the previous reconciliation package, which repeated an older
`62 resolved / 2 unavailable` interpretation.

## Production Recovery Follow-Up

The follow-up production recovery pass keeps this historical accounting intact
and adds a forward-looking resolver plan in:

- `config/source-map.dalycare64.production.tsv`
- `outputs/source_resolution_plan_dry_run.csv`
- `outputs/source_resolution_attempts.csv`
- `PRODUCTION_SOURCE_RECOVERY_PLAN.md`

The production map does not change historical classifications. It provides
attemptable resolver strategies, aliases, direct-SQL table patterns, and
manual/special declarations so a real DALY-CARE production run can test the
legacy-available resources while carrying
`BilleddiagnostikeUndersogelser_Del2` as legacy-known-unavailable but a current
resolver candidate that requires production validation.

## Corrected Resource Decisions

### `t_tumor`

Final classification: `legacy_profiled`

Evidence:

- `DALYCARE_atlas_AOT_V33.html` includes `SDS_tumor_aarlig` in
  `loadedDatasets` with 106,316 rows.
- `cartography_columns.tsv` and `cartography_tumor_value_counts.tsv` contain
  generated tumor-register evidence.
- The expected resource alias list maps `t_tumor`/`SDS_t_tumor` to
  `SDS_tumor_aarlig`.

Conclusion: `t_tumor` is not treated as known unavailable.

### `DANRICHT`

Final classification: `legacy_special_manual_or_embedded`

Evidence:

- Final V33 `part4_resolved` lists `DANRICHT`.
- The V33 description identifies on-disk project files:
  `danricht_clean.parquet` and `DANRICHT_20240412.csv`.
- The checked-in legacy TSVs do not show a normal PostgreSQL table profile.

Conclusion: `DANRICHT` is accounted/resolved by final V33 as special/manual
evidence, not known unavailable. It remains medium confidence because the
manual files are not reproduced as normal source-map tables in the current
repository.

### `FISH`

Final classification: `legacy_special_manual_or_embedded`

Evidence:

- Final V33 `part4_resolved` lists `LAB_FISH`.
- The V33 description says FISH evidence is embedded in RKKP_CLL and RKKP_DaMyDa
  columns.
- Checked-in TSVs include FISH-related registry/lab fields but no standalone
  normal `LAB_FISH` table.

Conclusion: `FISH` is accounted/resolved by final V33 as embedded/special
evidence, not known unavailable.

### `BilleddiagnostikeUndersøgelser_Del2`

Final classification: `legacy_known_unavailable`

Evidence:

- Final V33 Resource Catalog marks the SP imaging Del2 report-text table as the
  only remaining absent resource.
- Legacy part6/part7 searches found Del1 but not Del2.

Conclusion: this is the single evidence-backed legacy/V33 known-unavailable resource. A later production recovery cleanup separates that historical status from current resolver status and treats Del2 as a current resolver candidate until production validation proves it resolved or remains absent.

## Current Run Definitions

- `current_tested`: the refreshable pipeline actually had a matching source-map,
  source, or resolver row for the expected resource in this run.
- `current_resolved`: the current run successfully profiled/resolved the expected
  resource.
- `current_not_tested`: the expected resource exists in the V33 universe but was
  not attempted in the current source-map/fixture run.
- `current_missing_unexpectedly`: the current run attempted a matching expected
  resource but failed to resolve it.

Fixture-run limitations are not labeled as errors. Untested resources are shown
as `Not tested in current run`.

## Files Changed

- `config/expected_dalycare_resources_64.tsv`
- `R/source_reconciliation.R`
- `R/run_atlas.R`
- `R/html.R`
- `inst/templates/DALYCARE_atlas.html`
- `tests/test-run-atlas-fixtures.R`
- generated outputs:
  - `outputs/source_truth_evidence_matrix.csv`
  - `outputs/source_truth_summary.csv`
  - corrected `outputs/atlas_resource_reconciliation.csv`
  - corrected `outputs/source_resolution_delta_legacy_vs_current.csv`
  - corrected `outputs/atlas_run_summary.csv`

## Known Limitations

- The legacy HTML can be parsed when `jsonlite` is available. In lightweight
  test environments without `jsonlite`, the source-truth fallback uses the
  corrected expected-resource config plus generated legacy TSV evidence.
- `FISH` and `DANRICHT` remain medium-confidence special/manual resources until
  production source-map recovery adds explicit current resolver/source rows.
- Current fixture runs intentionally test only a small subset of resources; that
  is reported as `current_not_tested_resources`, not a production failure.

## Recommended Next Actions

1. Add production source-map rows or resolver aliases for every
   `legacy_resolved_current_not_tested` resource before production parity review.
2. Decide whether `FISH` and `DANRICHT` should be represented as curated files,
   embedded registry evidence, or explicit protected/manual resources.
3. Keep `BilleddiagnostikeUndersogelser_Del2` expected, legacy-known-unavailable,
   and current-candidate until a production attempt proves whether it now
   resolves or remains absent.
