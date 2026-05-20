# UX Source Reconciliation Notes

## What Changed

- Added a V033 64-resource expected-resource config.
- Added legacy-script audit output documenting how the old cartography scripts resolved or accounted for expected resources.
- Added a legacy-vs-current delta output.
- Added a Resource Catalog reconciliation output used by the atlas UI.
- Updated the Resource Catalog so expected resources remain visible even when a current fixture or production-like run did not explore them.
- Added source resolver aliases for late-cartography resources recovered by legacy direct PostgreSQL/table-pattern logic.

## Files Modified

- `config/expected_dalycare_resources_64.tsv`
- `R/source_reconciliation.R`
- `R/db_profile.R`
- `R/html.R`
- `R/run_atlas.R`
- `scripts/run_atlas.R`
- `scripts/visual_qa_atlas.js`
- `inst/templates/DALYCARE_atlas.html`
- `tests/helper.R`
- `tests/test-db-profile.R`
- `tests/test-run-atlas-fixtures.R`
- `SOURCE_RECONCILIATION_FROM_LEGACY_R_SCRIPTS.md`
- `SOURCE_TRUTH_CORRECTION_NOTES.md`
- `UX_SOURCE_RECONCILIATION_NOTES.md`

## Assumptions

- The V033 expected universe is 64 resources.
- The corrected final V33 source truth is 63 resolved/profiled resources and 1 known-unavailable resource.
- `BilleddiagnostikeUndersøgelser_Del2` is the evidence-backed known-unavailable resource.
- `FISH` and `DANRICHT` are special/manual/embedded rather than normal standalone current tables.
- Legacy counts are historical reference values and must not be shown as current counts.

## Known Limitations

- Fixture runs may show many expected resources as not tested because the fixture source map is intentionally small.
- Current production resolution still depends on the actual database catalog and configured source map.
- The reconciliation layer documents safe table/schema/alias patterns, not credentials or environment-specific DB connection details.

## How To Test Locally

```sh
Rscript scripts/run_tests.R
git diff --check
node scripts/visual_qa_atlas.js <generated-run>/site/DALYCARE_atlas.html qa_screenshots
```

Expected Resource Catalog screenshots:

- `qa_screenshots/resource_catalog_normal_desktop.png`
- `qa_screenshots/run_status_normal_desktop.png`

## Screenshots Generated

The visual QA script captures the normal Resource Catalog and Run Status views in addition to the existing Overview, Data Dictionary, Code Maps, Clinical Variables, and Treatment normal/mobile screenshots.
