# Field-label continuity implementation plan

Use Superpowers subagent-driven development and verification before completion.
Spec: `docs/superpowers/specs/2026-10-11-field-label-continuity-design.md`.
Baseline: iteration16 source commit 8060cca1e8020d94a327e7c21b9fdcee1b4c84b4.
Work in the existing dedicated branch; two disjoint implementation owners.

## Task 1 — Matched dictionary-derived catalogue metadata

Owner Y2 builders. Files: `scripts/site_bundle.py`, `R/site_bundle.R`, their bundle
tests and one shared synthetic fixture as needed. Do not change client assets.

- [x] Demonstrate failing tests for exact nonregistry labels, nonfield exclusion,
  identical/conflicting pairs, invalid rows, absent dictionary and publication
  rollback. Use the same fixture for both languages; test emitted catalogue.
- [x] Extract the optional map from the guarded dictionary being published and
  emit consistently in both writers. Respect installed-resource behavior and
  existing asset ceilings. No new independent dictionary loader.
- [x] Run targeted R/Python checks and report changed paths/limitations.

## Task 2 — Exact readable display and search

Owner Y2 client. Files: `inst/templates/atlas-outputs.js` and relevant Node tests.
No builder, Clinical, Home or CSS edits.

- [x] Demonstrate failure for nonregistry label arrival/search, exact-pair isolation
  and unknown fields, old catalogue fallback, malformed/prototype/HTML-like inputs.
- [x] Prefer valid exact optional map entries; retain raw names and exact filters.
  No new fetches or broad lookup/clinical inference. Test actual rendering/search.
- [x] Run relevant Node checks and report implementation with risks.

## Task 3 — Integration and bounded acceptance

- [x] Rebuild iteration17 from the same iteration16 historical inputs; compare all
  descriptors/published rows/core and inspect initial byte budgets/manifests.
- [x] X1/Z3 render the three journeys/searches including offline phone; root
  inspects images. W0 checks source-to-field continuity and retained exact names.
- [x] Independent Y2 review; original implementers fix important findings in one
  consolidated wave, followed by scoped re-review.
- [x] Run appropriate full Node/Python and R bundle/pipeline tests because both
  publishers changed; document exact limits and evidence.
- [x] Package local release, commit/push source-only checkpoint, update draft PR
  and continue the active goal with the next ranked critic finding.
