# DALY-CARE-ATLAS

`dalycareatlas` is a standalone, aggregate-only R package for resurrecting the
useful DALY-CARE cartography machinery from the legacy WoMMen V06 work without
making WoMMen WP1 depend on it.

The MVP profiles mapped DALY-CARE sources, writes machine-readable evidence
tables, and renders a static HTML atlas from an external payload file. It does
not emit patient-level rows, CPR values, patient identifiers, or raw row samples.

## Quick Start

```sh
Rscript scripts/run_tests.R
Rscript scripts/run_atlas.R . config/source-map.example.tsv atlas_runs report
```

In DALY-CARE, set `DALYCARE_BOOTSTRAP_PATH` to a bootstrap script that defines
`load_dataset()`, then run:

```sh
Rscript scripts/run_atlas.R /path/to/project config/source-map.tsv atlas_runs report
```

For real DALY-CARE runs, start from the package preset and bootstrap template:

```sh
export DALYCARE_PACKAGE_ROOT=/path/to/dalycare_package
export DALYCARE_BOOTSTRAP_PATH=/path/to/DALY-CARE-ATLAS/inst/templates/dalycare_bootstrap.R
Rscript scripts/check_dalycare_bootstrap.R /path/to/DALY-CARE-ATLAS
Rscript scripts/run_atlas.R /path/to/DALY-CARE-ATLAS config/source-map.dalycare.tsv atlas_runs report
```

The preflight script checks the source map and bootstrap without loading live
patient-level data. Set `DALYCARE_PREFLIGHT_ATTEMPT_LOAD=TRUE` only when you
intentionally want to probe live DALY database access. Database credentials and
access still depend on the upstream DALY-CARE package and the user's NGC
`/ngc/people/<user>/db_access.R` setup.

By default, public aggregate counts below 5 are suppressed in value-frequency
and registry categorical outputs. Override this only for local fixture testing:

```sh
DALYCARE_MIN_CELL_COUNT=5 Rscript scripts/run_atlas.R /path/to/project config/source-map.tsv atlas_runs report
```

## Source Map

The source map is a TSV/CSV with these required columns:

- `table_name`
- `source_type`: `dataset` or `file`
- `source`: DALY dataset name or file path
- `priority`
- `profile_mode`

File-backed sources support `.csv`, `.tsv`, `.txt`, `.rds`, and `.rda/.RData`.
Dataset-backed sources call DALY `load_dataset()` and support both return-value
and side-effect loader contracts.

`config/source-map.dalycare.tsv` is the curated DALY-CARE preset. It covers the
canonical source universe from upstream `load_all_data()`: `patient`, RKKP
registries (`RKKP_CLL`, `RKKP_LYFO`, `RKKP_DaMyDa`), SP operational tables,
SDS/LPR/LPR3 tables, `t_dalycare_diagnoses`, and documented DALY diagnosis and
survival views where available.

Source maps may also include optional `domain`, `subdomain`, and `atlas_role`
columns. The atlas preserves these in `atlas_sources.csv`, the resource catalog,
and the static HTML payload so operators can filter and review sources by DALY
area.

`profile_mode` controls how much public aggregate evidence is written:

- `schema`: source, column, and check metadata only
- `summary`: schema metadata plus high-level panels, no value frequencies
- `full`: richest profiling, including eligible value frequencies and detailed
  registry panels

## Output Bundle

Each run writes `atlas_runs/<run_id>/` with:

- `outputs/atlas_resource_catalog.csv`
- `outputs/atlas_sources.csv`
- `outputs/atlas_columns.csv`
- `outputs/atlas_checks.csv`
- `outputs/atlas_value_frequencies.csv`
- `outputs/atlas_run_summary.csv`
- `outputs/panels/*.csv`
- `outputs/output_manifest.csv`
- `logs/atlas_execution_log.tsv`
- `site/DALYCARE_atlas.html`
- `site/DALYCARE_atlas_payload.js`

Registry-focused runs can include these clinical panels:

- `outputs/panels/registry_clinical_summary.csv`: row, column, patient-count,
  and date coverage summary for DaMyDa, LYFO, and CLL sources.
- `outputs/panels/damyda_clinical_profile.csv`: aggregate DaMyDa categorical
  facets such as stage, bone disease, treatment, response, cytogenetics, and
  region.
- `outputs/panels/damyda_numeric_fields.csv`: aggregate DaMyDa numeric field
  summaries such as albumin, creatinine, LDH, immunoglobulins, M-component,
  calcium, free light chains, beta-2 microglobulin, and plasma-cell percentage.
- `outputs/panels/lyfo_clinical_profile.csv`: aggregate LYFO subtype, stage,
  IPI, B-symptom, performance, treatment, and bulk-disease facets.
- `outputs/panels/cll_clinical_profile.csv`: aggregate CLL Binet, IGHV, FISH,
  cytogenetic, TP53, treatment, performance, ZAP70, CD38, and beta2m facets.

The static atlas shows warnings and errors first, provides source/check filters,
and adds navigation links for generated panels. The HTML remains data-light and
loads its run payload from `site/DALYCARE_atlas_payload.js`.

## Legacy Provenance

Legacy WoMMen V06 cartography files are preserved under
`inst/legacy/wommen_v06/` as read-only reference evidence. They are not sourced
by the active package runtime.
