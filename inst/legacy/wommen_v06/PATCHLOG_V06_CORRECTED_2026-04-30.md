# V06 corrected patch log — 2026-04-30

This bundle was produced from the original `WoMMen_code_V06.zip` after a static bug hunt and reconciliation against the attached `unified_consensus_dictionary.xlsx` seed-vector workbook.

## Seed-vector corrections

- Aligned `payload/01_config_and_helpers.R` M-spike, FLC, calcium, eGFR, leukocyte, and immunoglobulin vectors with `resources/unified_consensus_dictionary.xlsx`.
- Added missing urine M-spike `NPU291xx` / `NPU293xx` codes.
- Moved `NPU14523` into `MSPIKE_IFX_P` and made `MSPIKE_NEUROPATHY` an empty compatibility vector.
- Removed non-consensus `NPU19802` / `NPU19804` from `MSPIKE_IGE`.
- Set `EGFR_CODES <- c("DNK35302")`.
- Aligned `isotype_recovery_omnibus.R` with the same M-spike/FLC seed vectors.
- Replaced stale detective-archive `ANALYTE_SEEDS` with consensus-aligned seeds; LDH/B2M seeds were corrected from the bundled cartography development history because they are not present in the consensus workbook.

## Runtime and loader fixes

- Added `.WOMMEN_PAYLOAD_STAGE_FUNCTIONS_LOADED` to force-reload reset paths.
- Made `R/payload_stage_functions.R` load the helper-backed stage 13a implementation when sourced directly.
- Fixed Stage 05 idempotent skip restoration so `missingness_ever_summary` and `missingness_window_vs_ever` are restored from disk.
- Updated stale refactor parity tests so absence of the old monolith backup is treated as a V06 locked-bundle condition rather than a failure.

## Missingness patch hardening

- Removed the unused `missingness_by_cohort_summary.csv` gate.
- Guarded missing `denominator` columns.
- Avoided overwriting canonical `missingness_window_vs_ever.csv` when synthesising approximate fallback rows; approximate output now writes to `missingness_window_vs_ever_approx.csv`.

## Cartography and atlas fixes

- Replaced the cartography inline JS baseline parser with a string-aware parser.
- Added consensus workbook schema guards so malformed workbook columns fall back to detective candidate-code tables instead of hard-failing.
- Fixed `refresh_resource_catalog()` lookup when `loaded_name` is `NA`.
- Fixed `RUN_CARTOGRAPHY_ATLAS.R` commandArgs restoration so sourced runs do not leave a `.GlobalEnv$commandArgs` binding behind.
- Moved the assay-platform match into the Stage 27 FLC offset-expansion join keys to avoid unnecessary transient row blowup.

## Portability

- Replaced the hard-coded NGC DALY-CARE loader in `isotype_recovery_omnibus.R` with `DALYCARE_LOADER` / `DALYCARE_ROOT` discovery.
