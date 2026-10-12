# DALY-CARE-ATLAS

`dalycareatlas` is a standalone, aggregate-only R package for building DALY-CARE cartography machinery.

The MVP profiles mapped DALY-CARE sources, writes machine-readable evidence
tables, and renders a static HTML atlas from an external payload file. It does
not emit patient-level rows, CPR values, patient identifiers, or raw row samples.

## Quick Start

Update or unpack the complete repository/package, then run this in RStudio Console:

```r
source("RUN_DALYCARE_ATLAS_73_SOURCE.R")
```

The runner builds the current run's CSV evidence and HTML/JSON/JavaScript site
automatically and prints its output directory. In DALY-CARE production it detects
`/ngc/projects2/dalyca_r/clean_r/load_dalycare_package.R` when available;
set `DALYCARE_BOOTSTRAP_PATH` only for a nonstandard loader.

Its default is `config/source-map.dalycare73.tsv`: **73 source-map entries**, including
canonical resources, derived/helper rows and special/manual entries. This is distinct
from the historical 64-resource reconciliation inventory and does not imply 73
independently accessible physical tables. The console names the selected map and
actual entry count; `DALYCARE_ATLAS_SOURCE_MAP` remains an authoritative override.
The former 48/64/default, standalone Ki-67/MCL root launchers and bundled legacy
cartography launcher are retired. The current runner already invokes the existing
Ki-67 discovery, pathology and MCL count machinery.

`summary` mode produces detailed guarded registry distributions and numeric summaries,
code/domain coverage and numeric profiles through existing source-aware producers.
It does not require generic `full` mode value-frequency exports. The new map preserves
all reviewed modes and source identities from the restored map: active clinical
sources use `summary`, while genuine manual/embedded/schema-only entries retain
those restrictions. `schema` omits clinical summaries; `full` is an advanced explicit
preset with legacy frequency producers. Memory, full-load and query budgets remain
in force in every mode. No free-text output is enabled by this consolidation.

Every actual attempt writes `outputs/atlas_completion_summary.csv` and
`outputs/atlas_registry_completion.csv`, including early runtime failures after a
run directory exists. These safe reports distinguish site-build status, source
coverage and reviewed registry-field coverage, and count published, privacy-withheld,
absent-field, missing-key/configuration, query and budget statuses. A wholly missing
registry is explicit. Successful HTML generation can coexist with partial coverage;
privacy withholding does not fabricate a result. These mutable attempt reports remain
outside the immutable build context/manifest so final state updates cannot invalidate
export checksums. A failed rerun clears the previous
`dalycare_atlas_result` and points to the actual attempt rather than an older output.

### Advanced and development entry points

```sh
Rscript scripts/run_tests.R
Rscript scripts/check_dalycare_bootstrap.R /path/to/DALY-CARE-ATLAS
Rscript RUN_DALYCARE_ATLAS_73_SOURCE.R
# Explicit fixture/custom-map invocation:
Rscript scripts/run_atlas.R . config/source-map.example.tsv atlas_runs report
```

For a custom-map interactive run, `source("scripts/run_atlas.R")` exposes
`run_atlas_from_source(source_map_path="config/source-map.example.tsv")`.
This is the underlying configurable API used by the single runner.

Advanced standalone invocations remain available through the internal sourceable APIs.
They preserve all prior configuration options, including optional text scanning and
atlas-output ingestion; defaults stay unchanged. Set configuration in `.GlobalEnv`
(or provide the complete `.KI67_SOURCE_CONFIG` / `.MCL_COUNT_SOURCE_CONFIG` list), then:

```r
KI67_PROJECT_ROOT <- "/path/to/DALY-CARE-ATLAS"
KI67_MODE <- "plan"                 # or production_aggregate
KI67_OUTPUTS_DIR <- "/secure/ki67-outputs"
source(file.path(KI67_PROJECT_ROOT, "scripts/source_ki67_finder.R"))

MCL_COUNT_PROJECT_ROOT <- "/path/to/DALY-CARE-ATLAS"
MCL_COUNT_MODE <- "plan"            # or production_aggregate
MCL_COUNT_OUTPUTS_DIR <- "/secure/mcl-outputs"
source(file.path(MCL_COUNT_PROJECT_ROOT, "scripts/source_mcl_triangle_counts.R"))
```

For advanced calls from another working directory, specify the project root explicitly.
The removed launcher convenience was automatic root detection/preset forwarding for
standalone calls; underlying functions, CLI/rebuild scripts, modes and options remain.

### Registry stage, treatment, response and measurements

The runner can now produce complete, person-counted summaries for reviewed
DaMyDa, LYFO and CLL fields. The existing archived top-value CSVs cannot establish
person-level support: **run the updated runner against the secure source data**
to generate these summaries. An offline rebuild cannot recover missing evidence.

Normal runs automatically use the exact `patientid` column for **RKKP_DaMyDa,
RKKP_LYFO and RKKP_CLL only**. This is an established mapping from legacy registry
functions (lines 1387, 1483 and 1505) and existing MCL mappings, corroborated by
column metadata in archived run `20260831_211803-p3532373` (`patientid`, int4,
sensitive in all three registries). No identifier values were inspected for that
confirmation. The exact live schema column must still exist. Missing or differently
cased fields withhold results; no CPR/name alternatives or record-count substitute
are tried. Database summaries resolve distinct people inside SQL and return grouped
counts, never identifier values.

An optional private operator mapping takes precedence over those defaults. Copy
`config/registry-summary-person-keys.example.csv` to a private configuration file,
set exact source/key names and `reviewed=TRUE` only for reviewed rows. Setting
`DALYCARE_REGISTRY_PERSON_KEYS_FILE` makes the entire file authoritative: disabled,
missing-source, duplicate, malformed or missing-file entries fail closed, with no
fallback to the default. Keep the file outside published output.

```r
# Optional authoritative override; ordinary runs need no manual mapping setup.
Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE = "/secure/config/registry-person-keys.csv")
source("RUN_DALYCARE_ATLAS_73_SOURCE.R")
```

The run writes `outputs/panels/registry_field_summaries.csv`, includes it in the
build context, and generates the HTML, JSON and offline JavaScript assets. In
Clinical explorer, open a registry, then **Stage**, **Treatment**, **Response** or
the baseline measurements topic. Each summary names its exact source column and
form phase. The data-table library also exposes the aggregate evidence. No person
key or individual record is exported by this summary producer.

Each field counts a person once when their nonblank recorded values agree.
Different values for the same person are classified as conflicting; blank-only
values are missing. Treatment fields remain separate and may overlap. Stage and
response codes retain their stored names until their meanings are verified.

Numeric summaries include finite, nonnegative stored values, with negatives and
unparseable values classified as invalid. This is a stated cleaning rule, not a
verified clinical range or missing-code interpretation. Units remain unverified;
fields are not converted or pooled. Mean, median and quartiles are rounded to
three significant digits; minimum and maximum are never published.

Publication requires all positive partition, category and complementary counts
to meet the run's threshold (at least five distinct people). Numeric summaries
also require at least 20 valid people, more than one distinct value, and at least
the threshold number of people for every distinct numeric value. A rare tail
withholds the entire field's counts and statistics. Missing keys, unsupported
queries, incomplete results and failed validation also withhold summaries.

The database path aggregates inside PostgreSQL or SQLite and retrieves grouped
counts only. Existing row budgets apply. `DALYCARE_REGISTRY_MAX_GROUPS` defaults
to 5,000 grouped values; exceeding it withholds the field. PostgreSQL queries
respect the stricter existing statement timeout or
`DALYCARE_REGISTRY_QUERY_SECONDS` (default 600 seconds, maximum 1,200). SQLite's
native execution cancellation has not been independently verified; its row and
result-cardinality limits still apply. The person-key review and database run
must happen in the secure DALY-CARE environment.

Rebuild a completed run without a database:

```sh
Rscript scripts/rebuild_atlas_from_outputs.R /path/to/completed/run /path/to/DALY-CARE-ATLAS
```

Both export implementations revalidate complete summaries before publishing
the core payload or table shards. Raising the disclosure threshold on rebuild
rechecks the saved evidence. Browser loading stays bounded: table shards load
on demand and registry results show at most 12 summaries per topic page.

The preflight script checks required project files, the 64-resource expected
list, the production source-map candidate, and the source-recovery dry-run
without requiring production DB credentials. Database credentials remain
controlled by `/ngc/people/<user>/db_access.R`; the atlas reports
symbol presence/classes only and never writes credential values. If a DALY
source map resolves zero live sources, the run now stops before writing the HTML
artifact unless
`DALYCARE_ATLAS_ALLOW_EMPTY_LIVE_RUN=TRUE` is set for a deliberate dry run.

By default, public aggregate counts below 5 are suppressed in value-frequency
and registry categorical outputs. Override this only for local fixture testing:

```sh
DALYCARE_MIN_CELL_COUNT=5 Rscript scripts/run_atlas.R /path/to/project config/source-map.tsv atlas_runs report
```

For DALY database-backed sources, the runner now prefers DB-side aggregate
profiling before it considers `load_dataset()`. These guardrails keep large
tables off the R heap unless a source is explicitly permitted to use the legacy
full-load path:

```sh
DALYCARE_ATLAS_DB_PROFILE=TRUE
DALYCARE_ATLAS_CHUNK_SIZE=50000
DALYCARE_ATLAS_MAX_FULL_LOAD_ROWS=100000
```

## Source Map

The source map is a TSV/CSV with these required columns:

- `table_name`
- `source_type`: `dataset` or `file`
- `source`: DALY dataset name or file path
- `priority`
- `profile_mode`

File-backed sources support `.csv`, `.tsv`, `.txt`, `.rds`, and `.rda/.RData`.
Dataset-backed sources first try DB aggregate profiling. `load_dataset()` remains
available for small fixtures and explicit fallback cases, including both
return-value and side-effect loader contracts.

`config/source-map.dalycare.tsv` is the curated compatibility DALY-CARE preset.
It covers the
canonical source universe from upstream `load_all_data()`: `patient`, RKKP
registries (`RKKP_CLL`, `RKKP_LYFO`, `RKKP_DaMyDa`), SP operational tables,
SDS/LPR/LPR3 tables, `t_dalycare_diagnoses`, and documented DALY diagnosis and
survival views where available.

`config/source-map.dalycare64.production.tsv` is the production recovery
candidate for the V033 64-resource universe. It preserves the one
legacy-known-unavailable resource separately from current resolver status,
carries manual/embedded resources explicitly, and adds late-cartography
aliases/direct-SQL table patterns so production runs can validate the full
expected resource universe. Validate it without database access with:

```sh
Rscript scripts/source_recovery_dry_run.R . config/source-map.dalycare64.production.tsv source_recovery_dry_run
```

Source maps may also include optional `domain`, `subdomain`, and `atlas_role`
columns. The atlas preserves these in `atlas_sources.csv`, the resource catalog,
and the static HTML payload so operators can filter and review sources by DALY
area. DALY DB runs may also include `load_strategy`, `db_name`, `schema`,
`table`, `chunk_size`, and `allow_full_load`. By default `load_strategy = auto`
means "use DB aggregates when the table resolves; otherwise skip risky full
loads unless the table is small enough or `allow_full_load = TRUE`."

`profile_mode` controls how much public aggregate evidence is written:

- `schema`: source, column, and check metadata only
- `summary`: schema metadata plus high-level panels, no value frequencies
- `full`: richest profiling, including eligible value frequencies and detailed
  registry panels

## Output Bundle

Each run writes `atlas_runs/<run_id>/` with:

- `outputs/atlas_resource_catalog.csv`
- `outputs/atlas_source_resolution.csv`
- `outputs/atlas_dalycare_access.csv`
- `outputs/atlas_memory_plan.csv`
- `outputs/atlas_sources.csv`
- `outputs/atlas_columns.csv`
- `outputs/atlas_column_profiles.csv`
- `outputs/atlas_column_top_values.csv`
- `outputs/atlas_checks.csv`
- `outputs/atlas_value_frequencies.csv`
- `outputs/atlas_semantic_data_dictionary.csv`
- `outputs/atlas_semantic_value_map.csv`
- `outputs/atlas_semantic_code_map.csv`
- `outputs/atlas_semantic_panel_links.csv`
- `outputs/atlas_run_summary.csv`
- `outputs/panels/*.csv`
- `outputs/legacy_cartography_source_resolution_audit.csv`
- `outputs/source_resolution_plan_dry_run.csv`
- `outputs/source_resolution_attempts.csv`
- `outputs/source_resolution_delta_legacy_vs_current.csv`
- `outputs/atlas_resource_reconciliation.csv`
- `outputs/output_manifest.csv`
- `logs/atlas_execution_log.tsv`
- `logs/atlas_memory_log.tsv`
- `site/DALYCARE_atlas.html`
- `site/DALYCARE_clinical.html` and `site/DALYCARE_outputs.html`
- `site/DALYCARE_atlas_payload.js` and matching `.json`
- light bootstrap/catalogue scripts, shared runtimes, styles, and `site/output-shards/`
- `outputs/atlas_build_context.json` (internal rebuild context)

Generated run outputs are local artifacts and should not be committed. The Git
repository carries the atlas tooling, source maps, static reference code sets,
templates, and synthetic fixtures; run-specific CSVs, payloads, cartography
extracts, QA screenshots, and ZIP bundles belong only in local run folders.

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

The static atlas is a tabbed, V33-style review artifact with run-level metrics,
domain cards, searchable source catalog, a safe per-column explorer, a semantic
Data Dictionary, registry cards, QA triage, generated panel tables, and
quick-start commands. Home and Data tables load only their small entry/catalogue assets.
Clinical explorer loads its core from `site/DALYCARE_atlas_payload.js` when opened.

Visual QA mock-ups generated from repository fixtures validate the atlas
template against fixture outputs. A separate full-output visual QA run is
required before final visual acceptance of production-scale data.

Generated atlas pages include the visible credit `Built by Alexander Owen
Taylor` in the header/footer and standard author metadata. Internal filenames,
payload keys, and generated CSV names stay neutral so the runtime remains
package-native and easy to audit. Repository citation metadata is recorded in
`CITATION.cff`.

`atlas_column_profiles.csv` contains one aggregate row per profiled column:
coverage, missingness, distinct count, sensitivity/date/numeric flags, and safe
numeric or date summaries where applicable. `atlas_column_top_values.csv`
contains top categorical values only for eligible non-sensitive columns after
minimum-cell suppression.

`atlas_semantic_data_dictionary.csv` is the generated variable-lineage table
used by the HTML Data Dictionary tab. It maps raw source/table/object names,
raw columns, descriptors, codes, and values to clinical concepts, domain
panels, confidence, caveats, and evidence files. The companion semantic value,
code, and panel-link CSVs support value interpretation, NPU/ATC/SKS/SNOMED/code
search, and the "Key raw fields" blocks shown throughout the atlas. These rows
are generated from the current run and optional local cartography reference
folder or ZIP supplied through `DALYCARE_CARTOGRAPHY_PATH`; no patient-level
rows, CPRs, raw free text, or unsuppressed small cells are emitted.

The atlas also ships a reference NPU consensus dictionary in
`config/npu-consensus-dictionary.tsv`, generated from the unified consensus
workbook. Lab sources with NPU-like code columns are joined to this dictionary
in aggregate-only panels:

- `outputs/panels/npu_dictionary_summary.csv`
- `outputs/panels/npu_dictionary_vectors.csv`
- `outputs/panels/npu_lab_usage_by_vector.csv`
- `outputs/panels/npu_lab_unmatched_codes.csv`

Observed NPU counts are normalized to uppercase `NPU[0-9]+` codes and remain
subject to `DALYCARE_MIN_CELL_COUNT` suppression.

## Legacy Provenance

Legacy WoMMen V06 cartography files are preserved under
`inst/legacy/wommen_v06/` as read-only reference evidence. They are not sourced
by the active package runtime.

## Clinician interface and guarded static exports

The static atlas includes clinical-name search, source-field comparisons,
reference code definitions, and source-specific time and regional coverage.
The R writer and offline Python builder apply a final disclosure filter to
both JSON and JavaScript payloads. Intermediate run CSVs are not equivalent
to these guarded release files and should not be published as public atlas
outputs. See [Clinician atlas interface and public exports](docs/clinician-atlas-ui.md)
for build instructions, interpretation limits, disclosure controls and tests.

## Offline and hosted bundles; exact rebuild versus migration

Open `site/DALYCARE_atlas.html` by double-clicking for offline use, or host the
entire `site/` directory over HTTP. Keep every page, script, style and
`output-shards/` together. Internal `outputs/` CSVs and the internal manifest
are not public downloads; do not host the enclosing run directory.

A new R run saves `outputs/atlas_build_context.json`, its supplemental CSVs and
any selected standalone MCL count bindings. The one-click runner and CLI use
these saved inputs to build the same guarded site. Rebuild without a database:

```sh
Rscript scripts/rebuild_atlas_from_outputs.R /path/to/run /path/to/project
```

Missing, malformed, oversized or incompatible required inputs stop publication;
the previous site and internal manifest remain available. Optional unknown or
changed schemas become metadata only. `outputs/output_manifest.csv` includes all
context inputs and every published asset exactly once. Explicit project templates
and registry take precedence over installed package resources.

Historical runs without the saved context cannot be claimed as exact CSV rebuilds.
Use an explicitly labelled snapshot migration, optionally selecting matching CSVs
for table evidence:

```sh
python scripts/build_ui_iteration.py --input-dir /path/to/old/site --output-dir /path/to/new/site --run-dir /path/to/matching/run
```

The clinical core remains an earlier snapshot in this mode; CSV tables and project
reference definitions have separate origins. Without `--run-dir`, snapshot tables
have unknown original counts and limited completeness. Only registered artifacts
in the selected run are considered; other archive contents are not published.

The input pre-read and total public-table limits default to 64 MiB each. Configure
`DALYCARE_ATLAS_INPUT_MAX_BYTES` and `DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES` in bytes;
the catalogue reports the limits. Shards have at most 250 rows and 256 KiB, pages
show 50 rows, and retained serialized shard data is bounded to 1 MiB. Browser heap
has additional overhead. Search completes only after scanning the selected
published table, not original withheld records. The clinical core still loads
as a whole when Clinical explorer opens. Production database access remains
unverified locally; synthetic entry-point checks do not establish it.

See [build and acceptance details](docs/clinician-atlas-ui.md) for interpretation,
privacy, and the integrated synthetic acceptance command.

The current package `DESCRIPTION` lacks a maintainer email, so untouched-source
`R CMD INSTALL` fails metadata validation. The installed-resource acceptance
test installs a temporary copy with a synthetic test contact; it verifies shipped
assets and project-resource preference, not production package-install readiness.
The source one-click, CLI and offline rebuild workflows do not require installation.
