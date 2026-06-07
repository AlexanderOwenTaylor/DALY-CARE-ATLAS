# SMM Immunity Tracker Notes

The SMM Immunity Tracker is an aggregate-only feasibility panel. It compares
infection-burden signals in two SMM cohort surfaces:

- AOT/WP5 original SMM-compatible day-90 cohort.
- CVM/JAMA clinically filtered SMM cohort, harmonized to day 90 for the primary
  tracker comparison.

The CVM diagnosis-origin view is retained only as a secondary reproduction or
readiness view. It must not be used as the primary cross-cohort comparison
against AOT/WP5 because both cohorts condition eligibility on being untreated
and alive through day 90.

The panel uses time-to-progression language: progression is treatment-defined
active MM or AL amyloidosis according to the cohort output contract, and death
before progression is a competing event. It does not use survival-before-
progression language, and it does not claim infections cause progression.

## Privacy Boundary

Static SMM outputs are aggregate-only. They must not contain identifiers, raw
dates, organism names, microbiology result text, pathology text, free text, or
row-level records. Primary and complementary small-cell suppression are required.
Rates are hidden when the numerator count is hidden.

The completed CONFLUENCE run zip supplied during development is reference-only.
It can guide schemas and visual QA locally, but true DALY-CARE run outputs,
payloads, logs, extracted folders, rendered pages, and derived real-data mockups
must remain untracked.
