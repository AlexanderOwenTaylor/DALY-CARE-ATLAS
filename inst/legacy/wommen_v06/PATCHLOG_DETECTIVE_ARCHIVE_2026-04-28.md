# PATCHLOG_DETECTIVE_ARCHIVE_2026-04-28

## What this patch fixes

The previous bundle (`WoMMen_DALYCARE_single_source_hotfix_2026-04-28.zip`)
shipped a `resources/detective_archive_unpacked/` folder that contained only
two files (one near-empty, one zero-byte). Because the cartography reads from
that folder via `nrow(...)` guards, it didn't crash — it just produced an
atlas with skeletal lab-detective and isotype-recovery panels. The README
described the folder as an unpacked detective archive but provided no script
that actually populates it.

Two scripts in the bundle (`isotype_recovery_omnibus.R` and
`npu_detective_forensics.R`) are *capable* of producing the seven CSVs the
cartography expects, but:

- They aren't wired into `RUN_CARTOGRAPHY_ATLAS.R`.
- `npu_detective_forensics.R` is a partial library — its parent
  `npu_detective.R` (which defines `score_candidates`, `ANALYTE_SEEDS`,
  `ANALYTE_ALLOWLIST`) is **not in the bundle** at all, so the forensics
  module's negative-control panel and code-candidate sweep cannot run.
- Both scripts assume a live DALY-CARE bootstrap; they cannot mirror the
  WP1 outputs that already contain most of the same information.

This patch adds a detective archive builder that knows how to produce the
seven cartography-expected files from three priority-ordered sources, and
wires it into `RUN_CARTOGRAPHY_ATLAS.R` so the archive is built before
cartography reads it.

## Files changed

### 1. `WoMMen_code/code/000_build_detective_archive.R` (NEW, 653 lines)

Standalone R script that produces the seven CSVs the cartography reads:

| Cartography expects                     | Source priority                                         |
|-----------------------------------------|---------------------------------------------------------|
| `00_lab_source_summary.csv`             | (1) `qc_lab_source_summary.csv` from WP1; (2) live derive from `lab_all` |
| `10_coverage_heatmap_scenarios.csv`     | (1) `qc_lab_site_coverage.csv` from WP1 V06 patch; (2) live derive |
| `20_candidates_npu.csv`                 | (1) WP1 candidate audit (if it has the right schema); (2) live derive from `lab_all` × `Codes_NPU` |
| `41_class_v8_summary.csv`               | Mirror of WP1 `qc_isotype_ascertainment_summary.csv`    |
| `42_venn_plasma_vs_urine.csv`           | Mirror of WP1 `qc_isotype_venn.csv`                     |
| `44_mspike_generic_isotype_recovery.csv`| (1) Existing 44_…csv if present; (2) call `npu_detective_forensics.R::mspike_generic_isotype_recovery()`; (3) minimal counts fallback |
| `60_provenance.csv`                     | (1) Existing provenance file; (2) synthesise from `qc_isotype_ascertainment.csv` per-source flags |

For each source path, the script logs a one-line provenance note. A build
manifest is written to `detective_archive_build_manifest.csv` listing what
was produced, what was skipped, and why. The script is safe to run when
`load_dataset()` is unavailable — it simply uses the WP1 mirror paths and
warns about the live-derivation paths it skipped.

Honoured environment variables:

- `DETECTIVE_OUT_DIR` — output directory (default: `<pkg>/resources/detective_archive_unpacked`)
- `WP1_RESULTS_DIR` — WP1 results directory to mirror from (default: searches several candidates including `<pkg>/WoMMen_code/code/WoMMen_outputs/WP1/results`)
- `WOMMEN_PROJECT_DIR` — alternate WP1 output root
- `DALYCARE_BOOTSTRAP_PATH` — explicit DALY-CARE bootstrap to source
- `DETECTIVE_BUILD_LIVE` — `"0"` to skip live derivation entirely

Dry-run verification against the previous V06 WP1 outputs (without the V06
patches applied):

```
File                              Status                                       Rows
00_lab_source_summary.csv         WP1 mirror                                      4
10_coverage_heatmap_scenarios.csv WP1 mirror (V06)                               (lives in V06 stage 04)
20_candidates_npu.csv             WP1 schema mismatch -> live-derive needed       -
41_class_v8_summary.csv           WP1 mirror                                      7
42_venn_plasma_vs_urine.csv       WP1 mirror                                      4
44_mspike_generic_isotype_recovery.csv  forensics call or fallback              (live)
60_provenance.csv                 synthesised from qc_isotype_ascertainment       6
```

So with WP1 already run, four to six of the seven files are produced from
the existing WP1 outputs — no DALY-CARE access required for the build step.

### 2. `RUN_CARTOGRAPHY_ATLAS.R` (REWRITTEN, 111 lines)

Three substantive changes:

- **Robust path detection.** The previous version used `sys.frame(1)$ofile`
  which is `NULL` under `Rscript`; the `tryCatch(...)` fallback only worked
  because the `.sh` wrapper does `cd $(dirname $0)` first. The new version
  handles both `source()` and `Rscript` invocation explicitly via
  `commandArgs("--file=")`.
- **Detective archive build is now invoked first.** Before sourcing the
  cartography script, `RUN_CARTOGRAPHY_ATLAS.R` now sources
  `000_build_detective_archive.R` so the seven CSVs are populated. The
  build is wrapped in `tryCatch` so a build failure logs a `[WARN]` and
  cartography still runs in baseline-preserving mode.
- **Optional atlas updater.** If `WOMMEN_RUN_ATLAS_UPDATER=1` is set,
  `001_dalycare_atlas_updater.R` is invoked after cartography to hot-swap
  the JSON payload into the V35 HTML atlas. Off by default because it
  touches `site/`.

Environment variables now exported:

- `DETECTIVE_ARCHIVE_PATH` (defaults to `<pkg>/resources/detective_archive_unpacked`)
- `DETECTIVE_OUT_DIR` (mirrors `DETECTIVE_ARCHIVE_PATH` for the builder)

### 3. `WoMMen_code/code/000_dalycare_cartography_consolidated.R` (1-line removed, comment added)

Removed the fourth `BOOTSTRAP_PATH` fallback that pointed at
`01_config_and_helpers.R`. That file is the WoMMen pipeline's helpers, not a
DALY-CARE bootstrap. Sourcing it as a "bootstrap" loaded ~14 R packages and
defined hundreds of WoMMen-internal functions but never defined
`load_dataset()`; the downstream check then warned "load_dataset is NOT
available" *after* a lot of unnecessary side effects. The comment block now
records why the fallback was removed.

The remaining three fallbacks (env var → `/ngc/projects2/...` → recursive
glob for `load_dalycare_package.R`) cover all legitimate cases.

### 4. `WoMMen_code/code/R/payload_stage_registry.R.v04b_backup` (DELETED)

Stale backup file from the V04b refactor. Harmless (no `list.files` glob
picks it up) but inconsistent with the README's "single source of truth"
framing.

## What this patch does NOT change

- The WP1 CCI fix in `payload_03_covariates.R` (already correct).
- The WP2 CCI inheritance guard (already correct).
- The cartography's lab-site / SHAK decoding (already correct and well-implemented).
- The `safe_load_dataset()` three-path implementation (already correct).
- The atlas baseline payload-first reading (already correct).
- The two parallel lab-site lookup dictionaries (cartography-side and WoMMen-side
  V06 patch). Both work; one could be factored out into a shared resource
  but that's a refactor, not a bug.

## Operating expectations

After this patch, on the NGC server:

1. The user runs WP1 (which produces the WoMMen results tree under
   `WoMMen_code/code/WoMMen_outputs/WP1/results/`).
2. The user runs `./RUN_CARTOGRAPHY_ATLAS.sh` from the package root.
3. The detective archive builder runs first, mirroring 4–6 of the 7 CSVs
   from the WP1 results, plus optionally live-deriving the rest if
   `load_dataset()` is available.
4. The cartography script then reads the populated detective archive and
   produces a full atlas — not a skeletal one.

If WP1 hasn't been run, the detective archive builder will warn that most
of its inputs are absent and the cartography will fall back to baseline
payload values, exactly as before. The build step is non-blocking.

## Verification commands

```sh
# Should now contain seven CSVs + a manifest, not just two files
ls resources/detective_archive_unpacked/

# Build manifest tells you exactly which path was used for each file
cat resources/detective_archive_unpacked/detective_archive_build_manifest.csv

# Build log retains every [WARN] line
cat resources/detective_archive_unpacked/detective_archive_build_log.txt
```

In the cartography log (`Other/DALYCARE_atlas_refresh_*/cartography_consolidated_log.txt`),
the seven `read_archive_csv(...)` calls should now produce non-zero rows for
the files the builder populated, and the seven downstream
`if (nrow(...) > 0L) write_csv_safe(...)` writes will produce the
`atlas_npu_detective_*.csv` and `atlas_isotype_recovery_*.csv` files in the
refresh output directory.
