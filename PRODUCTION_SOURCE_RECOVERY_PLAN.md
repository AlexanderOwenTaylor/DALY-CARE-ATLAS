# Production Source Recovery Plan

## What Changed

This package adds a production recovery layer for the DALY-CARE 64-resource universe. It preserves fixture/mock mode and does not copy V33 row counts into current-run counts.

Current accounting:

- `expected_resources = 64`
- `legacy_available_or_resolved_resources = 63`
- `legacy_known_unavailable_resources = 1`
- `db_attemptable_resources = 62`
- `special_manual_or_embedded_resources = 2`
- `current_known_unavailable_resources = 0` until a production attempt proves otherwise

`BilleddiagnostikeUndersogelser_Del2` is legacy-known-unavailable, but it is no longer treated as permanently/current unavailable. The current source-map and resolver code contain Del2 candidates, so it is classified as `legacy_unavailable_current_candidate` and requires production validation.

## Files Added Or Modified

- `config/source-map.dalycare64.production.tsv`
- `config/source-map.dalycare.tsv`
- `R/source_reconciliation.R`
- `R/db_profile.R`
- `R/html.R`
- `R/run_atlas.R`
- `R/source_map.R`
- `scripts/source_recovery_dry_run.R`
- `scripts/check_dalycare_bootstrap.R`
- `tests/test-production-source-recovery.R`
- `tests/test-run-atlas-fixtures.R`
- `inst/templates/DALYCARE_atlas.html`
- `PRODUCTION_SOURCE_RECOVERY_PLAN.md`

## How The Production Source Map Was Built

The production source-map candidate is seeded from:

- `config/expected_dalycare_resources_64.tsv`
- `outputs/source_truth_evidence_matrix.csv`
- `outputs/legacy_cartography_source_resolution_audit.csv`
- legacy cartography alias/direct-query evidence captured during source-truth correction
- current atlas source-map/preflight/resolver aliases

Legacy row counts are historical reference evidence only. They are not current counts.

## Resolver Types

- `standard_table`: standard source-map/table-name resolution.
- `alias_table`: alias table-name resolution.
- `schema_qualified_table`: configured database/schema/table resolution.
- `direct_sql`: named production DB resolver candidate using safe schema/table patterns.
- `manual_file`: curated/manual file evidence.
- `embedded_fields`: evidence embedded as fields in another source.
- `known_unavailable`: current production evidence proves the resource unavailable.
- `legacy_unavailable_current_candidate`: legacy/V33 could not resolve the resource, but current code carries a resolver candidate.
- `needs_manual_review`: insufficient resolver evidence.

## Dry-Run Mode

Dry-run mode validates resolver configuration without opening a production database connection:

```sh
Rscript scripts/source_recovery_dry_run.R . config/source-map.dalycare64.production.tsv source_recovery_dry_run
```

It writes:

- `outputs/source_resolution_plan_dry_run.csv`
- `outputs/source_recovery_dry_run_summary.csv`

Dry-run statuses use non-production wording:

- `would_attempt_in_production`
- `legacy_unavailable_current_candidate`
- `requires_manual_file`
- `requires_embedded_field_mapping`
- `current_known_unavailable_declared`
- `needs_manual_review`

The dry-run summary deliberately marks production attempt status as `not_applicable_dry_run`.

## Production-Run Reporting

Normal atlas runs write:

- `outputs/source_resolution_plan_dry_run.csv`
- `outputs/source_resolution_attempts.csv`
- `outputs/billeddiagnostik_del2_regression_audit.csv`

`source_resolution_attempts.csv` records, per expected resource, whether the current run attempted resolution, how it attempted it, whether it resolved, the resolved table/file/schema where available, current row/patient counts where available, warnings, action required, and legacy/current known-unavailable flags.

The Resource Catalog UI combines expected resources, source-truth evidence, the production resolver plan, and current attempt rows. Fixture-run untested resources are labelled `Not tested in current run`, not as errors.

## Del2 Regression-Audit Outcome

`BilleddiagnostikeUndersogelser_Del2` has mixed historical/current evidence:

- Legacy Part 6/7 evidence says Del2 was not found and only Del1 was resolved.
- Current `config/source-map.dalycare.tsv` includes a Del2 source-map row.
- Current `R/dalycare_preflight.R`, `R/db_profile.R`, and template/payload code include Del2 aliases/candidates.
- No local package evidence proves a current production run resolved Del2.

Therefore the cleanup classification is:

- `legacy_known_unavailable = TRUE`
- `current_known_unavailable = FALSE`
- `resolver_type = direct_sql`
- `expected_availability = legacy_unavailable_current_candidate`
- `requires_production_validation = TRUE`
- `regression_candidate = possible_current_candidate`

This keeps the V33 limitation visible without treating it as a permanent current absence.

## Adding A New Alias

Add aliases to `known_aliases` in `config/source-map.dalycare64.production.tsv`, separated by semicolons. The resolver normalizes case, punctuation, underscores, spaces, and common Danish character variants.

If an alias should apply outside the production 64-resource map, add it to `dalycare_table_aliases()` in `R/db_profile.R`.

## Marking Current Known Unavailable

Only mark a resource current-known-unavailable when a current production attempt or source-owner confirmation supports that status. Set:

- `resolver_type = known_unavailable`
- `current_known_unavailable = TRUE`
- `expected_availability = current_known_unavailable`
- a clear `notes` value explaining the current evidence

Historical/V33 absence should use `legacy_known_unavailable = TRUE`. If a current resolver candidate exists, keep `current_known_unavailable = FALSE` and set `requires_production_validation = TRUE`.

## Fixture/Mock Versus Production Mode

Fixture/mock runs intentionally profile only a small subset of resources. In that mode:

- most expected resources may be `Not tested in current run`;
- `FISH` and `DANRICHT` remain `Special/manual`;
- `BilleddiagnostikeUndersogelser_Del2` remains `legacy_unavailable_current_candidate`;
- untested fixture rows are not production errors.

## Known Limitations

- Direct SQL resolvers record safe table/schema patterns and aliases; they do not embed credentials.
- Manual-file resources require production file paths or source-specific loaders before they can produce current counts.
- Embedded-field resources require downstream panel logic to count field coverage if current-run counts are needed.
- Del2 needs a real production validation attempt before it can be called resolved or currently unavailable.

## Recommended Production Command Sequence

```sh
Rscript scripts/check_dalycare_bootstrap.R /path/to/DALY-CARE-ATLAS
Rscript scripts/source_recovery_dry_run.R /path/to/DALY-CARE-ATLAS config/source-map.dalycare64.production.tsv source_recovery_dry_run
Rscript scripts/run_atlas.R /path/to/DALY-CARE-ATLAS config/source-map.dalycare64.production.tsv atlas_runs report
```

After the run, review:

- `outputs/source_resolution_attempts.csv`
- `outputs/billeddiagnostik_del2_regression_audit.csv`
- `outputs/atlas_resource_reconciliation.csv`
- `outputs/atlas_run_summary.csv`
- Resource Catalog and Run Status in `site/DALYCARE_atlas.html`
