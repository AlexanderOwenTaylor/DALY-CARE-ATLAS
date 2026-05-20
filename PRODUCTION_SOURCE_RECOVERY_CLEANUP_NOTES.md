# Production Source Recovery Cleanup Notes

## What Changed

This cleanup pass makes the production source recovery package internally consistent before production testing. It separates historical/V33 absence from current resolver status and adds a focused audit for `BilleddiagnostikeUndersogelser_Del2`.

## Missing Bootstrap Script Fix

The previous package documentation referenced `scripts/check_dalycare_bootstrap.R`, but the script was not included in the ZIP. The cleanup package includes it.

The script now performs an offline package preflight:

- required directories exist;
- expected config files exist;
- `expected_dalycare_resources_64.tsv` has 64 rows;
- `source-map.dalycare64.production.tsv` has 64 rows;
- every expected resource has a resolver strategy;
- the production source-recovery dry run validates.

It does not require production DB credentials.

## Source-Map Filename Cleanup

The package now includes both:

- `config/source-map.dalycare.tsv`: current curated compatibility preset used by existing runner defaults and compatibility tests;
- `config/source-map.dalycare64.production.tsv`: 64-resource production recovery candidate.

Production recovery documentation recommends `source-map.dalycare64.production.tsv`.

## Metric Naming Cleanup

Ambiguous “attemptable” language was split into clearer metrics:

- `legacy_available_or_resolved_resources`
- `db_attemptable_resources`
- `special_manual_or_embedded_resources`
- `known_unavailable_legacy_resources`
- `current_known_unavailable_resources`
- `current_resolver_configured_resources`
- `current_tested_resources`
- `current_resolved_resources`
- `current_not_tested_resources`
- `current_missing_unexpectedly_resources`
- `regression_candidate_resources`

This avoids conflating DB-attemptable resources with manual/embedded resources.

## Dry-Run Wording Cleanup

Dry-run statuses now describe resolver configuration rather than production outcomes:

- `would_attempt_in_production`
- `legacy_unavailable_current_candidate`
- `requires_manual_file`
- `requires_embedded_field_mapping`
- `current_known_unavailable_declared`
- `needs_manual_review`

The dry-run summary marks production attempt status as `not_applicable_dry_run`.

## Del2 Regression Audit

The cleanup creates:

- `outputs/billeddiagnostik_del2_regression_audit.csv`

Evidence found locally:

- Legacy cartography Part 6/7 marked Del2 absent and noted that only Del1 existed.
- `config/source-map.dalycare.tsv` includes `SP_BilleddiagnostikeUndersoegelser_Del2`.
- `R/dalycare_preflight.R` includes Del2 candidates.
- `R/db_profile.R` includes Del2 alias families.
- `R/semantic_dictionary.R` and the atlas template include Del2 aliases/display references.
- Earlier packaged current atlas payload/template evidence includes Del2 as a source-map/candidate name, but no local evidence proves a current production run resolved it.

Final cleanup classification:

- `legacy_known_unavailable = TRUE`
- `current_known_unavailable = FALSE`
- `resolver_type = direct_sql`
- `expected_availability = legacy_unavailable_current_candidate`
- `requires_production_validation = TRUE`
- `regression_candidate = possible_current_candidate`

## Tests Added Or Updated

Tests now verify:

- the production source-map has 64 resources;
- Del2 is still in the 64-resource universe;
- Del2 is legacy-known-unavailable but not current-known-unavailable;
- Del2 has candidate aliases and a direct-SQL resolver strategy;
- dry-run output uses non-production statuses;
- summary counts distinguish DB-attemptable, special/manual, legacy unavailable, and current unavailable;
- Del2 regression audit output exists and contains current candidate evidence.

## Known Limitations

- No production database attempt was made in this cleanup pass.
- Del2 cannot be called resolved until production evidence shows it resolves.
- Del2 cannot be called current-known-unavailable until a current production attempt or source-owner confirmation proves absence.
- Manual-file and embedded-field resources still require source-specific production handling for current counts.

## How To Validate In Production

```sh
Rscript scripts/check_dalycare_bootstrap.R /path/to/DALY-CARE-ATLAS
Rscript scripts/source_recovery_dry_run.R /path/to/DALY-CARE-ATLAS config/source-map.dalycare64.production.tsv source_recovery_dry_run
Rscript scripts/run_atlas.R /path/to/DALY-CARE-ATLAS config/source-map.dalycare64.production.tsv atlas_runs report
```

Then review:

- `outputs/source_resolution_attempts.csv`
- `outputs/billeddiagnostik_del2_regression_audit.csv`
- `outputs/atlas_resource_reconciliation.csv`
- Resource Catalog in the generated atlas
