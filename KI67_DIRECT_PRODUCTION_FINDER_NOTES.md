# Ki-67 Direct Production Finder Notes

## Purpose

The cached atlas Ki-67 discovery pass showed that current aggregate atlas artifacts do not expose confirmed Ki-67 percentage evidence. That is not evidence that Ki-67 is absent from DALY-CARE production data.

The direct production finder is a targeted, aggregate-only search for where Ki-67 lives in raw production-facing tables. It is designed to find Ki-67 in production code, value, registry, and pathology text fields without rerunning the full atlas source-profiling pipeline.

## What The Finder Does

- Writes a concrete aggregate query plan and SQL/pseudo-SQL templates in plan mode.
- Uses existing DALY-CARE read-only DB conventions in production aggregate mode.
- Searches candidate Patobank, pathology text, and RKKP/LYFO registry locations.
- Preserves `db_name` in search-plan, metadata-hit, count, and found-location outputs so core/import source boundaries remain visible.
- Counts only grouped aggregate evidence.
- Applies small-cell suppression, default `n < 5`.
- Keeps p16/Ki-67 cervix/cytology triage codes separate from numeric MCL Ki-67 proliferation-index evidence.
- Updates MCL/TRIANGLE Ki-67 readiness only if direct aggregate evidence is found.

## What The Finder Does Not Do

- It does not run `run_atlas()` or the full source-map profiling loop.
- It does not emit patient-level rows.
- It does not emit CPR, patient identifiers, requisition IDs, dates, or raw pathology text snippets.
- It does not run raw preview queries such as `SELECT * ... LIMIT 10`.
- It does not conclude Ki-67 is absent unless direct production scans have searched the relevant fields.
- It does not treat pathology/LYFO source availability as Ki-67 evidence.

## Commands

Plan mode, no DB connection:

```sh
Rscript scripts/find_ki67_in_production.R --mode plan --project-root . --outputs-dir outputs
```

Production aggregate mode:

```sh
Rscript scripts/find_ki67_in_production.R --mode production_aggregate --project-root . --outputs-dir outputs
```

Restricted candidate-table mode:

```sh
Rscript scripts/find_ki67_in_production.R --mode production_aggregate --candidate-tables pato,t_mikro,t_konk,RKKP_LYFO --project-root . --outputs-dir outputs
```

Broad pathology text scans are disabled by default. Use `--full-scan true` only after reviewing `outputs/ki67_db_query_templates.sql`.

The MCL/TRIANGLE one-click runner also inventories Ki-67 source space directly:

```r
MCL_TRIANGLE_ATLAS_OUTPUT_DIR <- "path/to/main_atlas_outputs"
MCL_TRIANGLE_KI67_TEXT_SCAN <- FALSE
source("RUN_MCL_TRIANGLE_COUNTS.R")
```

By default it validates the coded `SDS_pato.c_snomedkode` AEKI route and writes text bridge plans without scanning raw pathology text.

## Outputs

- `ki67_db_query_templates.sql`: aggregate-only SQL/pseudo-SQL templates.
- `ki67_db_search_plan.csv`: planned resource, table, column, pattern, and privacy-risk rows.
- `ki67_db_column_name_hits.csv`: metadata-only column-name hits from production metadata when DB access is available.
- `ki67_db_aeki_code_counts.csv`: aggregate counts for Danish Patobank numeric Ki-67 codes.
- `ki67_db_p16_dual_stain_counts.csv`: separate p16/Ki-67 dual-stain counts.
- `ki67_db_text_pattern_counts.csv`: aggregate pathology text pattern counts by value class.
- `ki67_db_registry_field_counts.csv`: aggregate registry field summaries.
- `ki67_db_summary.csv`: channel-level evidence interpretation.

MCL/TRIANGLE-specific Ki-67 outputs include `mcl_triangle_atlas_ki67_source_inventory.csv`, `mcl_triangle_ki67_aeki_code_counts.csv`, `mcl_triangle_ki67_threshold_counts.csv`, and `mcl_triangle_ki67_text_bridge_validation.csv`.
- `ki67_found_locations.csv`: the single answer table for “where was Ki-67 found?”

## Danish Patobank Numeric Ki-67 Codes

The finder treats valid `ÆKIxxx` / `AEKIxxx` codes as the primary Danish numeric Ki-67 code route. The final three digits are parsed as a percent value:

- `ÆKI000` = 0%
- `ÆKI005` = 5%
- `ÆKI020` = 20%
- `ÆKI100` = 100%

Values above 100 and malformed variants are rejected. These local value codes are different from external SNOMED CT observation anchors such as `1255078008`.

## p16/Ki-67 Guardrail

The following codes are tracked separately:

- `FY5015`
- `FY5016`
- `M0901K`
- `M0901L`

They are p16/Ki-67 cervix/cytology triage or test-quality evidence, not numeric MCL Ki-67 proliferation-index values. They never upgrade MCL/TRIANGLE Ki-67 readiness.

## Text Pattern Handling

Text pattern queries count reports matching Ki-67, MIB-1, or `proliferationsindeks` patterns by value class:

- exact numeric percent
- approximate numeric percent
- range percent
- inequality percent
- qualitative mention only
- unknown or not stated

No report text is emitted. Manual clinical/pathology validation is required before extracted text values are used analytically.

## MCL/TRIANGLE Readiness Update

Readiness updates are conservative:

- valid `ÆKIxxx`/`AEKIxxx` aggregate counts can upgrade Ki-67 to `strong_structured_coded`;
- registry numeric Ki-67 fields can upgrade Ki-67 to `strong_structured_numeric`;
- text pattern counts can upgrade Ki-67 to `moderate_text_extractable`;
- p16/Ki-67 dual-stain and source-only evidence do not upgrade numeric MCL Ki-67 readiness.

For the TRIANGLE feasibility counts, text-pattern source space does not upgrade risk classifiability unless an explicit clinical validation flag/config is added later. Missing Ki-67 is never interpreted as standard-risk biology.

## Privacy Safeguards

- All queries are aggregate-only.
- Small counts below the configured minimum cell size are shown as `<5`.
- Raw pathology snippets and identifiers are prohibited.
- Query templates are emitted in plan mode so a human can review safety before production execution.

## Limitations

Production table and column names may vary by environment. Plan mode uses the restored source map and prior source-resolution outputs when available, then falls back to expected Patobank/RKKP candidates. Production mode refines candidates using database metadata when credentials are available.
