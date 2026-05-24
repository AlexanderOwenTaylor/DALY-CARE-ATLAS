# Ki-67 One-Click RStudio Finder Notes

## How to run

From the repository root in RStudio:

```r
source("RUN_KI67_FINDER.R")
```

Default configuration:

```r
KI67_MODE <- "production_aggregate"
KI67_CANDIDATE_TABLES <- c("pato", "t_mikro", "t_konk", "RKKP_LYFO")
KI67_FULL_SCAN <- FALSE
KI67_UPDATE_MCL <- TRUE
KI67_PROJECT_ROOT <- "."
KI67_OUTPUTS_DIR <- "outputs"
KI67_MIN_CELL_COUNT <- 5L
```

Set any of these before sourcing to override them:

```r
KI67_MODE <- "plan"
source("RUN_KI67_FINDER.R")
```

```r
KI67_MODE <- "production_aggregate"
KI67_FULL_SCAN <- TRUE
source("RUN_KI67_FINDER.R")
```

## What it writes

The one-click finder writes aggregate-only Ki-67 direct-finder outputs:

- `outputs/ki67_db_search_plan.csv`
- `outputs/ki67_db_query_templates.sql`
- `outputs/ki67_found_locations.csv`
- `outputs/ki67_db_aeki_code_counts.csv`
- `outputs/ki67_db_text_pattern_counts.csv`
- `outputs/ki67_db_registry_field_counts.csv`
- `outputs/ki67_db_summary.csv`

MCL/TRIANGLE readiness files are updated only when direct aggregate Ki-67 evidence is found and `KI67_UPDATE_MCL` is true.

## What it does not do

The one-click finder does not run the full DALY-CARE atlas, does not profile the 48/64-source maps, does not rebuild all site outputs, and does not emit patient-level rows, CPR/IDs, dates, requisition IDs, or raw pathology snippets.

## Privacy safeguards

Production scans are aggregate-only. Small-cell suppression defaults to `n < 5`. Plan mode writes query templates without opening a database connection.

## Difference from cached-output discovery

Cached-output Ki-67 discovery scans existing atlas metadata. The direct finder is intended to answer where Ki-67 lives in production by checking production-relevant raw code/text/registry fields directly, especially Danish Patobank `AEKIxxx` / `AEKI000`-`AEKI100` code paths and Ki-67/MIB-1/proliferationsindeks text patterns.
