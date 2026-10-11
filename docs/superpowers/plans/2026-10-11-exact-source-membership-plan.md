# Exact source membership implementation plan

Use Superpowers subagent-driven development, TDD and verification before completion.
Spec: `docs/superpowers/specs/2026-10-11-exact-source-membership-design.md`.
Baseline96eb2deaa63aed848b78f5a2d8cdfb96f1fc50cb; same dedicated integration branch.

## Task 0 — Freeze the finite shared interface

Y2 R/resource owner creates installed JSON and shared literal fixture, using audited
current specifications and explicit alias evidence. No broad alias import.

- [x] Publish validated schema, finite memberships and fixture to root; record
  exactly accepted aliases and exclusions. Freeze interface before dependent work.

## Task 1 — R producers and required-resource wiring

Same Y2 R/resource owner. Own new R/clinical_source_membership.R, R/html.R,
R/product_layer.R, R/run_atlas.R, R/output_evidence.R, required R loader/manifest
wiring, R tests and shared fixture. Do not edit Clinical template or Python.

- [x] Observe failing selector and fresh review/readiness/KPI tests.
- [x] Implement exact selection, diagnostic handling, non-additive metadata and
  optional fresh inventory at explicit run/rebuild boundaries.
- [x] Wire installed/source loaders and resource manifest identity. Preserve raw
  evidence and keep unknown/missing state distinct from zero.
- [x] Run focused R tests and report precise coverage/uncovered families.

## Task 2 — Historical Python overlay

Y2 Python owner starts after Task0 interface. Own scripts/clinical_source_membership.py,
scripts/build_ui_iteration.py, Python tests. Shared schema is read-only.

- [x] Observe failing literal-fixture parity, exact identity, ambiguity and
  imported-array preservation tests.
- [x] Load once via explicit project_root; append guarded derived metadata only,
  with imported origin and resource identity in manifest inputs.
- [x] Verify missing/malformed config and original site/manifest preservation;
  retain every original evidence array and CSV-derived table row.

## Task 3 — Clinical consumer

Y2 client owner starts after Task0 interface. Own Clinical template and focused
Node domain/readiness tests. No R/Python/resource edits.

- [x] Observe failing exact metadata selection, retained alias identities with
  unequal profiles, ambiguous counts, malformed metadata and old fallback tests.
- [x] Consume normalized covered memberships/readiness with exact links and honest
  state. Preserve existing published distributions and selected-field evidence.
- [x] Keep old supplied readiness inspectable with accurate provenance. No extra
  fetches, Home/library change, or unknown source/field inference.

## Task 4 — Integrate, challenge and checkpoint

- [x] Build iteration18 from the matching iteration17 historical inputs; compare
  original core arrays and all table descriptors/published row objects, permitting
  only the documented new derived metadata.
- [x] X1/Z3/W0 bounded rendered review, independent Y2 code review, consolidated
  important fixes by original owners, scoped re-review; root inspects images.
- [x] Full applicable Node/Python plus focused R and real one-click/CLI/offline/
  installed-resource pipeline acceptance. Verify manifests and byte budgets.
- [x] Package local release, update docs, commit/push source-only checkpoint to
  existing draft PR, continue active goal with registry usability findings.

Acceptance record: final Node225/225; full Python57 run with two optional local
export skips, followed by the scoped loader correction tests; all four focused
R membership files and the real one-click/CLI/offline/relocation/rollback/
manifest/installed-resource pipeline passed. X1/Z3/W0 rendered acceptance and
independent Y2 task/fix/integration gates are complete. The existing semantic
product-layer assertion fails identically on the pristine baseline and remains
outside this checkpoint's passing claims. Packaging/checkpoint completion is
recorded in the local iteration18 release validation file.
