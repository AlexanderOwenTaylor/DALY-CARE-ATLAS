# WoMMen V06 corrected patch bundle — 2026-05-01

This zip starts from `WoMMen_code_V06.zip` and applies the supplied `wommen_v06_patches.tar.gz` patch set.

## Applied patches

- P01 — bridge payload config/helpers into isolated payload runtimes, fixing WP5 `MSPIKE_PLASMA_WORKUP`/code-list visibility failures.
- P02 — fail closed in WP2 stage 13 when `SP_VitaleVaerdier` or `SP_Social_Hx` are unavailable, unless the reduced-covariate override is explicitly enabled.
- P03 — prevent cartography from publishing a degraded payload when zero streamed datasets loaded; preserves the existing `site/` payload unless `CARTO_FORCE_PUBLISH=TRUE`.
- P04 — add Cox separation/estimability guard for WP2 negative-control models and surface non-estimable separation as a blocking status.
- P05 — correct Danish kommune/region mapping to canonical Statistics Denmark region codes, including Hovedstaden = 1084 and Sjælland = 1085.
- P06 — fix absolute-path handling so `/ngc/...` paths are not nested under `WoMMen_outputs/`.
- P07 — add in-session cache for deterministic upstream stages 02–04 to avoid repeated rebuilds in multi-WP runs.
- P08 — surface stage 23 bootstrap/runtime failures in logs and end-of-run warnings instead of leaving silent partial outputs.
- P09 — make cartography object picking prefer exact names and block canonical alias collisions such as `Codes_NPU` resolving to `Codes_ATC`.
- P10 — add persistent ICD-10 resolution audit output (`qc_icd10_resolution.csv`) for DALY-CARE canonical code-list vs hardcoded fallback decisions.
- P11 — suppress expected many-to-many dplyr warnings in compatibility join helpers when callers explicitly requested `relationship="many-to-many"` on older dplyr versions.
- P12 — add `qc_unexpected_igm_summary.csv` and configurable handling for lab-IgM classifications after non-IgM cohort entry.
- P13 — correct CPR emigration code handling from status 20 to status 80, with optional status 70 sensitivity and `qc_emigration_status_distribution.csv`.
- P14 — expand DaMyDa/MM cross-validation to include date-discrepant and within-MGUS-cohort summaries.

## Validation performed in this environment

- Static file inspection and packaging checks only.
- Zip integrity checked with `unzip -t` after repackaging.

## Validation not performed here

- R execution tests were not run because `Rscript` was not available in this container.
- The corrected code should be smoke-tested in the DALY-CARE/R environment using the verification steps from `wommen_v06_patches/README_apply_order.md`.
