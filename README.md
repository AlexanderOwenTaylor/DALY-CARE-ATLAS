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
