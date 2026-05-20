# Polish Run Summary And Special Handling Notes

## What changed

This patch adds a resource-status normalization layer so the atlas reports the latest 64-resource production-style run as a successful source-recovery run:

- 64 canonical DALY-CARE resources accounted for.
- 62 DB-attemptable canonical resources profiled.
- 2 special/manual/embedded resources: `FISH` and `DANRICHT`.
- 0 unexpected missing canonical DB resources.

Resolved/profiled source rows now have consistent `attempted_in_current_run`, `profiled_in_current_run`, and `activation_status` fields before reconciliation, run-summary, and payload generation.

## Files modified

- `R/run_atlas.R`
- `R/source_reconciliation.R`
- `R/action_items.R`
- `R/html.R`
- `inst/templates/DALYCARE_atlas.html`
- `tests/test-restore-64-resource-resolution.R`
- `tests/test-run-atlas-fixtures.R`

## FISH

`FISH` is a canonical resource, but in the current atlas it is represented through embedded cytogenetic/FISH fields in profiled RKKP registry resources such as `RKKP_CLL` and `RKKP_DaMyDa`. It should not be reported as a failed standalone DB table when those embedded fields are present.

The normalized status is:

- `load_status = embedded_fields_represented`
- `current_status = embedded_fields_represented`
- severity `info`

## DANRICHT

`DANRICHT` is a manual/on-disk special resource. Missing local files such as `danricht_clean.parquet` or `DANRICHT_20240412.csv` are now reported as a manual note rather than an ordinary DB profiling failure.

The normalized status is:

- `load_status = manual_file_not_available`
- `current_status = manual_file_not_available`
- severity `manual_note`

## Canonical resources versus source-map rows

Canonical resources are the 64 DALY-CARE resource-universe entries. Source-map rows are runner inputs and can include canonical resources, aliases, derived views, and helper rows. Some canonical resources can map to more than one source-map row, so source-map-row counts must not be described as canonical-resource counts.

The UI now prefers clearer metrics:

- `canonical_resources_accounted_for`
- `db_attemptable_canonical_resources`
- `db_attemptable_profiled_resources`
- `special_manual_or_embedded_resources`
- `embedded_field_resources`
- `manual_special_not_loaded_resources`
- `unexpected_missing_canonical_resources`
- `db_attemptable_failures`
- `canonical_mapped_source_map_rows`

Older metric keys remain available for compatibility.

## Del2

`BilleddiagnostikeUndersøgelser_Del2` remains classified as `legacy_unavailable_current_resolved`. V033/legacy could not resolve it, but the current production source key resolves to the SP imaging Del2 table and should never be downgraded to current-unavailable without a reviewed future production failure.

## Warning severity

The atlas now separates:

- `success`
- `info`
- `manual_note`
- `warning`
- `unexpected_failure`

Only unexpected DB-attemptable source failures should appear as top-level failures. Sentinel/date parsing, DB-budget notes, and manual/special source notes remain visible but non-blocking.

## Known limitations

This patch does not change the 64-resource universe or redo source recovery. It normalizes status interpretation and presentation after profiling. A future standalone FISH table or required DANRICHT manual file can be added without changing the canonical resource model.

## How to test locally

```r
source("scripts/run_atlas.R")
result <- run_atlas_from_source(
  source_map_path = "config/source-map.example.tsv",
  output_root = "atlas_runs",
  mode = "report"
)
```

Recommended checks:

```sh
Rscript tests/test-restore-64-resource-resolution.R
Rscript scripts/run_tests.R
git diff --check
```

