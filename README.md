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

## Output Bundle

Each run writes `atlas_runs/<run_id>/` with:

- `outputs/atlas_resource_catalog.csv`
- `outputs/atlas_sources.csv`
- `outputs/atlas_columns.csv`
- `outputs/atlas_checks.csv`
- `outputs/atlas_value_frequencies.csv`
- `outputs/panels/*.csv`
- `outputs/output_manifest.csv`
- `logs/atlas_execution_log.tsv`
- `site/DALYCARE_atlas.html`
- `site/DALYCARE_atlas_payload.js`

## Legacy Provenance

Legacy WoMMen V06 cartography files are preserved under
`inst/legacy/wommen_v06/` as read-only reference evidence. They are not sourced
by the active package runtime.

