# WoMMen / DALY-CARE single-source package — V06 (2026-04-28)

This package consolidates the WoMMen / DALY-CARE pipeline under a single
canonical source of truth and ships the cartography, WP1–WP6 frameworks,
and the supplementary support modules.

The cartography canonical source is:

`WoMMen_code/code/000_dalycare_cartography_consolidated.R`

Use the root runner:

```r
source("RUN_CARTOGRAPHY_ATLAS.R")
```

or from shell:

```bash
./RUN_CARTOGRAPHY_ATLAS.sh
```

## What V06 ships

1. **Single canonical cartography script.** Removed duplicated cartography
   history; there is now one versionless cartography source.
2. **Removed example/preview PNGs** and prior generated `WoMMen_outputs`
   from the bundled codebase.
3. **No nested ZIPs.** The package is zipped once only.
4. **Bounded cartography file discovery** to the package root by default.
   It no longer recursively scans parent directories unless
   `CARTO_SEARCH_PARENT_DIRS=1` is explicitly set.
5. **Atlas baseline files** retained in `site/`, so
   `DALYCARE_atlas_payload.js` and `DALYCARE_atlas_AOT_V35.html` are
   discoverable.
6. **`unified_consensus_dictionary.xlsx`** retained in `resources/`.
7. **Unpacked `resources/detective_archive_unpacked/`** instead of a
   nested detective ZIP.
8. **Fixed the WP1 CCI crash** in `payload_03_covariates.R`: the Charlson
   flag collapse no longer calls `across(-all_of("patientid"))` after
   grouping.
9. **CCI fail-loud behaviour** retained: all-zero CCI is not accepted when
   substantial dated pre-index diagnosis input exists.
10. **WP2 CCI inheritance guard** retained: WP2 refuses to silently use an
    all-zero inherited CCI.
11. **Detective-archive auto-build** wired into `RUN_CARTOGRAPHY_ATLAS.R`.
12. **`RUN_CARTOGRAPHY_ATLAS.R` path detection** hardened to work under
    both `source()` and `Rscript`.
13. **Removed the wrong `01_config_and_helpers.R` fallback** from the
    cartography's `BOOTSTRAP_PATH` chain (it was never a DALY-CARE
    bootstrap).
14. **Removed the stale `R/payload_stage_registry.R.v04b_backup`** file.
15. **Atlas-updater (Step 3) working-directory bug fixed.** Previously the
    runner sourced `001_dalycare_atlas_updater.R` with `chdir = TRUE`,
    which set `getwd()` to `WoMMen_code/code/`. The updater's
    `getwd()`-relative discovery then couldn't find the HTML in `site/`
    or the cartography output in `Other/`, so it threw "Could not find
    HTML atlas" / "Could not find DATA JSON payload", the runner's
    `tryCatch` caught the error, and the step silently no-op'd (even
    with `WOMMEN_RUN_ATLAS_UPDATER=1`). The fix:
    * The runner now resolves the bundled `site/DALYCARE_atlas_AOT_V*.html`
      itself, exports `ATLAS_HTML_PATH`, runs the updater from the
      package root, and pins `--out` to
      `CARTO_OUT_DIR/DALYCARE_atlas_AOT_V<n+1>.html` so successful runs
      no longer silently mutate the bundled `site/` HTML.
    * The updater now honours `CARTO_OUT_DIR` as the highest-priority
      JSON-payload directory, and also looks for the HTML under
      `<wd>/site/`, so it remains robust when invoked standalone from
      the package root.

## Detective archive auto-build (2026-04-28)

The previous bundle shipped `resources/detective_archive_unpacked/` with
only two near-empty files. The cartography reads seven CSVs from that
folder and silently fell through to baseline values for the five it
couldn't find.

This release adds **`WoMMen_code/code/000_build_detective_archive.R`**
which is sourced automatically by `RUN_CARTOGRAPHY_ATLAS.R` before the
cartography runs. The builder produces all seven CSVs the cartography
expects:

| Cartography reads                          | Builder source                            |
|--------------------------------------------|-------------------------------------------|
| `00_lab_source_summary.csv`                | WP1 `qc_lab_source_summary.csv` mirror, or live-derive |
| `10_coverage_heatmap_scenarios.csv`        | WP1 `qc_lab_site_coverage.csv` mirror, or live-derive |
| `20_candidates_npu.csv`                    | live-derive from `lab_all` × `Codes_NPU` |
| `41_class_v8_summary.csv`                  | WP1 `qc_isotype_ascertainment_summary.csv` mirror |
| `42_venn_plasma_vs_urine.csv`              | WP1 `qc_isotype_venn.csv` mirror |
| `44_mspike_generic_isotype_recovery.csv`   | live-call to `npu_detective_forensics.R::mspike_generic_isotype_recovery()`, or fallback |
| `60_provenance.csv`                        | synthesise from WP1 `qc_isotype_ascertainment.csv` per-source flags |

If WP1 has been run, four to six of the seven files are produced by
mirroring existing WP1 outputs — no DALY-CARE access required for the
build step. The remaining files require `load_dataset()` which is loaded
by the standard DALY-CARE bootstrap.

A build manifest is written to
`resources/detective_archive_unpacked/detective_archive_build_manifest.csv`
listing what was produced, what was skipped, and why.

See `PATCHLOG_DETECTIVE_ARCHIVE_2026-04-28.md` for the full diff
narrative.

## Memory and freeze fixes

V06 includes targeted fixes to prevent the WP3, WP4, and cartography
memory blow-ups that earlier internal pipeline runs hit on a full
DALY-CARE extract.

* **`payload/01_config_and_helpers.R`**: `EGFR_CODES` is defined as an
  empty character vector by default, with the same `if (!exists(...))`
  guard as the other NPU code vectors. Stages 27 and 30 reference this
  symbol in two descriptive consumer catalogs; without the default
  definition the run aborts with `object 'EGFR_CODES' not found`. The
  primary eGFR derivation in stage 27 uses CKD-EPI from creatinine, age,
  and sex, so leaving the vector empty is safe and matches the prior
  behaviour. Operators with extracts that include lab-reported eGFR
  (e.g. NPU28653) can populate the vector before sourcing the
  cartography.

* **`R/stages/payload_04_biomarkers_and_isotype.R`** (WP3 stage 04):
  - `mspike_by_date` is computed with a vectorised pre-mutate / pure
    summarise / post-mutate pipeline, replacing a previous embedded R
    block in `summarise(mprotein_value = { ... })`. dplyr executes the
    embedded block once per group through the per-group R interpreter
    loop; with the patient × sample-date cardinality of a national MM
    cohort that was the dominant transient allocation in WP3 stage 04
    and the source of an observed freeze at ~88 GiB. Output schema and
    row identity are preserved (`patientid`, `mprotein_date`,
    `any_detected`, `any_quant`, `any_typed_quant`, `mprotein_value`,
    `mprotein_detected`, `mp_nonquant_detected`, `mp_cat`).
  - `pair_flc_nearest_stage()` uses an offset-expansion equi-join. Each
    kappa row is fanned out to `(2 * tol_days + 1)` candidate target
    days; the equi-join with lambda on
    `(patientid, flc_platform, .target_l_int)` is bounded at
    `(2 * tol_days + 1) * |kappa|` intermediate rows globally rather
    than per-patient `M * N`, replacing a previous many-to-many
    `inner_join` that materialised the full per-(patient, platform)
    Cartesian product before the tol-day filter. The `slice(1)` at the
    end produces the same nearest-pair output. An empty-input guard
    returns the canonical empty tibble shape if either side has zero
    rows.

* **`payload/27_backward_prediagnostic_trajectory.R`** (WP4 stage 27):
  the same two patterns are applied to the backward endpoint universe.
  `mspike_by_date_scope` uses the vectorised summarise + post-mutate
  pattern (output schema preserved: `patientid`, `mprotein_date`,
  `any_detected`, `any_quant`, `mprotein_value`); `pair_flc_nearest()`
  uses the offset-expansion equi-join. Together these are the dominant
  memory reduction in WP4 stage 27.

* **`000_dalycare_cartography_consolidated.R`**: the cartography load
  loop is split into two stages.

  * **Stage A — lookup-resident loads.** A small fixed list of
    code/lookup tables (`Codes_NPU`, `CODES_NPU`, `CODES_NPU_core`,
    `Codes_ATC`, `Codes_ATC_core`, `Codes_hospital`, `Codes_SHAK_long`,
    `shakcomplete`, `Codes_kommunekoder`) is loaded into
    `load_profiles[[]]` exactly once. These tables are tiny and are
    reused by every name-decorating summariser via `npu_lookup`,
    `atc_lookup`, `lab_site_lookup`, and `shak_table_lookup`. They have
    to stay resident; everything else does not. The lookup-name maps
    are built immediately after Stage A, while only these small tables
    sit in memory.

  * **Stage B — streaming summarisers.** For every other dataset
    (`SP_VitaleVaerdier`, `SP_AlleProvesvar`, `SP_Bloddyrkning_del1..4`,
    `SP_Journalnotater_Del1/Del2`, `PERSIMUNE_biochemistry`,
    `SDS_laboratorieproevesvar`, `SDS_epikur`,
    `SDS_indberetningmedpris`, `SDS_pato`, `SDS_t_sksube`,
    `SP_OrdineretMedicin`, `SP_Administreret_Medicin`,
    `SP_BilleddiagnostiskeUndersoegelser_Del1`, `RKKP_*`, `LAB_*`,
    `SP_ITAOphold`, `SP_Flytningshistorik`, `SP_Behandlingsniveau`,
    `diagnoses_all`, `t_dalycare_diagnoses`, `SP_ADT_Haendelser`,
    `SP_Behandlingsplaner_del1`, `SP_Social_Hx`, microbiology parts) the
    loop loads the dataset into a local variable, dispatches it through
    its summariser (which writes its small CSVs and stores small
    results in module-scope variables), drops the loaded data.frame's
    `.GlobalEnv` binding, and `rm()`s + `gc()`s before moving to the
    next dataset. Two summarisers
    (`summarise_persimune_microbiology`, `summarise_sp_microbiology`)
    need >1 part, and the antineoplastic concordance (`atc_antineo`) is
    a union of four per-source contributions: for these the dispatcher
    captures small per-part summary tibbles into accumulators and the
    final shape is assembled once after the loop ends.

    Resident memory is bounded by `(lookup tables) + (one heavy
    dataset) + (small summaries)` instead of `sum of every loaded
    dataset`.

  * **`atlas_resource_catalog.csv`** row/col counts come from
    `loaded_status_tbl`, populated correctly during both stages, with
    canonical-name lookup via `canonical_target()` so catalog rows
    whose `dataset` field is a non-canonical alias (e.g.
    `microbiology_analysis`, canonical
    `PERSIMUNE_microbiology_analysis`) still resolve.

  * **`CARTO_DATASET_SKIP`** (comma-separated dataset names) and
    **`CARTO_MEMORY_LIMIT_GIB`** (numeric, GiB) are available as
    belt-and-suspenders guards but should rarely be needed: under
    streaming the only way the limit can fire is if a single dataset on
    its own exceeds the limit, in which case the limit should be
    raised.

The recommended invocation is just:

```bash
./RUN_CARTOGRAPHY_ATLAS.sh
```

with no env vars set.

## Expected use

For cartography, source only:

```r
source("RUN_CARTOGRAPHY_ATLAS.R")
```

For WP1, continue to use your normal WP1 runner. The patched files are:

* `WoMMen_code/code/R/stages/payload_03_covariates.R`
* `WoMMen_code/code/R/stages/payload_04_biomarkers_and_isotype.R`
* `WoMMen_code/code/payload/01_config_and_helpers.R`
* `WoMMen_code/code/payload/27_backward_prediagnostic_trajectory.R`
* `WoMMen_code/code/000_dalycare_cartography_consolidated.R`

For best results, run WP1 *before* the cartography so the
detective-archive builder can mirror the WP1 outputs. If WP1 hasn't been
run, the cartography still works; it just falls back to
baseline-preserving values for the panels that depend on the detective
archive.

The R pipeline was not executed against a real DALY-CARE extract from
the packaging environment (no DB credentials), but the canonical
cartography script parses cleanly under `Rscript -e 'parse(...)'`,
brace/paren/bracket balance was validated on every patched file, and
the detective archive builder's logic was dry-run against earlier WP1
outputs to confirm the schemas mirror correctly.
