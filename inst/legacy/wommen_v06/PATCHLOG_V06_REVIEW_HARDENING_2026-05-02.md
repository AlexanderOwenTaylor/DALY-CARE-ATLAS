# PATCHLOG V06 — bug/design review hardening patch (2026-05-02)

Base: `WoMMen_code_V06_corrected_cartography_hardened.zip`.
Source review: `WoMMen_V06_bug_and_design_review.md`.

Applied static code fixes:

1. Stage cache key now includes a seed-code-list digest and a stage-source-file digest; runtime reset clears `.WOMMEN_STAGE_CACHE`.
2. Polypharmacy derivation now emits `polypharm_observed` and `Polypharmacy_missing`, with downstream propagation into WP2/WP3/WP4/WP6 candidate/select surfaces.
3. WP2 exposure flags now remain `NA_integer_` for patients not ascertained in `SDS_epikur`, rather than silently treating them as unexposed.
4. Emigration extraction now fails closed in locked/publication mode unless `WOMMEN_ALLOW_NO_EMIGRATION_CENSORING=TRUE`; emits `qc_emigration_status_audit.csv`.
5. `mp_nonquant_imputed_flc` contract violations now stop in locked/publication mode and default to `NA_integer_` otherwise, not `0L`.
6. Hypogonadism stage no longer blanket-replaces all numeric testosterone lab values with zero; only flag/count columns are zero-filled.
7. WP6 model fitting now hard-fails on missing structural columns instead of fabricating `patientid`.
8. WP2 publication hierarchy now fail-closes `count_gate_pass` using `coalesce(..., FALSE)`.
9. Exportable root default is now user-relative (`/ngc/people/<user>/Exportable_data`) instead of hardcoded to `aletay_r`.
10. CCW clone construction now errors on missing `outcome_day` instead of silently treating it as day 0.

Not fully refactored here:

- Cartography remains outside the formal DAG; the earlier bootstrap/zero-stream publish guards are retained, but the large registry-stage refactor is not attempted in this patch.
- Stage 07 side-effect sensitivity outputs and duplicated idempotency guards are not centrally refactored; doing so safely requires an R/DALY-CARE run to validate output restoration semantics.
- Global-environment fallback audit is only partially addressed by previous isolated-runtime patches; a full executor-level namespace isolation refactor is deferred.

Validation performed in this packaging environment:

- Static grep checks for patched sentinel lines.
- Archive creation and `unzip -t` integrity check.
- R execution/smoke tests were not run because `Rscript` is unavailable in this container.
