# Registry field discovery implementation plan

> **For agentic workers:** Use superpowers:subagent-driven-development. Follow
> the approved spec task by task; record RED/GREEN and scoped review results.

**Goal:** Make DaMyDa, LYFO and CLL field discovery usable without empty charts,
repeated caveats or misleading clinical interpretations.

**Architecture:** One registry presentation layer in the existing HTML template,
using original-row privacy checks, exact profile joins and native theme anchors
within the existing hash router. One Y2 owner avoids simultaneous edits to the
shared template; X1/Z3/W0 and an independent Y2 reviewer challenge the result.

**Tech stack:** Existing vanilla HTML/CSS/JavaScript, Node tests, Python site
builder; no new dependencies or data transport.

**Spec:** docs/superpowers/specs/2026-10-12-registry-field-discovery-design.md

## Global constraints

- Preserve all iteration18 core payload values and 147 table descriptors with
  28,802 published row objects; source-only presentation changes.
- Preserve offline/HTTP, privacy, exact source identity, global routes and print.
- No prefix concept assertions, alias borrowing, count aggregation, unit
  inference or historical statistics. Follow AGENTS.md and the spec's finite
  mappings, interpretation and source-summary boundaries.

## Review focus

- Flagged rows with retained values: filter before mapping, including titles and
  print; mixed safe+withheld and supplied zero remain correct (Task1).
- Same field name in another source or an alias without profiles: no borrowed
  cards, counts or coverage; exact fallback remains available (Task2).
- Unreviewed Rec_ fields and FISH/IGHV/stage meanings: no automatic clinical
  interpretation or form-context loss (Task2).
- Direct/invalid/stale theme, global search and browser Back: restore only a
  valid active registry theme after deferred rendering (Task3).
- Long phone labels and no published chart: compact usable controls, accurate
  empty state, no scale copy and useful next action (Tasks1/3/4).

## Task1 — Original-row category eligibility

Owner Y2 registry implementation. Modify inst/templates/DALYCARE_atlas.html;
create tests/test-registry-discovery.js, following existing template test harness.

Consumes original DaMyDa/LYFO/CLL category rows and existing publication helpers.
Produces registry partition/renderer helpers retaining original metadata and a
supported/withheld/absent state. Internal signatures are local to this owner;
no external or data schema changes.

- [x] Write/run RED tests for safe positive/zero, null category/count, all withheld,
  mixed safe+withheld, flagged retained values and different exact scopes.
- [x] Implement partition before transformations at every registry chart path;
  remove unsafe aggregation and duplicate CLL summary rendering. No scale or
  coding footer without supported bars.
- [x] Run focused tests GREEN and self-review the complete affected call paths.

## Task2 — Finite task fields and compact source scope

Same owner/files; sequential dependency on Task1. Consumes current exact profiles,
clinicalDisplayEntry, sourceEvidenceLinks and iteration18 inventory helpers.
Produces registry theme descriptors and compact field/source renderers.

- [x] Write/run RED tests for X1's five required response fields, LYFO relapse
  regimen in Treatment, unknown Rec_ excluded, missing/wrong-source profiles,
  separate aliases, ambiguous/unavailable inventory and summary identity.
- [x] Implement finite corrected mappings, readable names plus exact identity,
  field actions and honest fallback. Preserve per-field units, validation and
  scientific caveats. Replace oversized unsupported KPI cards with source strip.
- [x] Run focused tests GREEN; confirm no old interpretation or source regex
  becomes authoritative in the new renderer.

## Task3 — Theme routes and compact hierarchy

Same owner/files; consumes Task2 descriptors. Produces registry-scoped theme
route parameter and native anchor restoration in the existing router.

- [x] Write/run RED tests for route serialization/parsing, invalid/stale theme,
  registry switching, search preservation and handler collision avoidance.
- [x] Add one delegated theme handler; restore/focus after deferred rendering,
  aria-current and visible focus; keep all sections printable and controls
  generous on phone. Consolidate repeated caveats and technical primary copy.
- [x] Focused tests GREEN. Save implementation report and hand source to root;
  no commit/push or additional children. Tasks1–3 form one shared-file review unit.

## Task4 — Integration, opposing reviews and checkpoint

Root owns docs/build/verification/artifacts. No R/Python production changes.

- [x] Build atlas-iteration-19 from accepted18 and matching historical inputs.
  Compare every core value and table descriptor/row; measure asset bytes.
- [x] Run complete applicable Node suite and existing builder validation.
- [x] Independent Y2 source review; original owner fixes consolidated findings,
  then scoped re-review. Do not repeat unrelated prior audits.
- [x] X1 exact semantics/field actions, Z3 offline phone/keyboard/tasks, W0
  organization/V33 comparison. Check HTTP direct/refresh/Back/invalid routes,
  global navigation, print and no new errors/external data requests.
- [x] Root inspects representative rendered images, records limitations and
  acceptance, packages local site, commits/pushes source-only PR3 checkpoint.
  Continue active goal with the next evidenced usability/loading issue.

Implementation, source review, final rendering and data equality are accepted.
The post-commit packaging/push operation completed at source checkpoint
eda8bfbb9fe604121b3b12522024fc5a92c4366d; both local ZIPs passed CRC verification.
