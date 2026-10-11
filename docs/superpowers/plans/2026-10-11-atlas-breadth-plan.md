# Atlas breadth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reveal the atlas's clinical scope and connect supported domains to useful source evidence.

**Architecture:** Retain the existing lightweight Home, Clinical explorer and sharded Data tables. Use static topic navigation on Home and exact current source inventories inside Clinical; reuse existing field and coverage routes. No new payload data or schema.

**Tech Stack:** Static HTML/CSS, inline JavaScript, Node tests, Python/R build pipeline.

**Spec:** `docs/superpowers/specs/2026-10-11-atlas-breadth-design.md`

## Global Constraints

All spec constraints apply. Work in the existing clean dedicated `codex/clinician-atlas-ui` checkout, continuing the established user-authorized iteration workflow. Root owns integration, builds, artifacts, commit and push; workers own disjoint product files and must not revert another worker's changes.

## Review Focus

1. Empty curated-panel arrays with nonempty catalog/profiles must still reveal exact source evidence (Task 2).
2. Missing exact sources/profiles must not create asserted availability, duplicate aliases or broken actions (Task 2).
3. Null/withheld categories must not generate dummy bars or counts (Task 2).
4. Source names with punctuation and source/field queries must survive encoded links (Task 2).
5. Phone, keyboard and offline navigation must expose the same broad topic choices (Task 1 and integration QA).

### Task 1: A broad lightweight Home

**Files:** `inst/templates/DALYCARE_entry.html`, Home-scoped rules in `inst/templates/atlas-pages.css`; focused route tests if behavior changes require them.

**Interfaces:** Existing verified Clinical hashes and Data tables `?view=timeplace` / `?view=fields` routes only. Do not edit Clinical template, builders or generated metadata.

- [x] Replace measurement-led question cards with a compact readable map of clinical domains; retain field, code and coverage discovery as secondary useful tasks.
- [x] Keep Home-specific CSS isolated from Data tables; retain focus styles, wrapping, static link operation and route compatibility.
- [x] Check relevant entry route tests and render desktop/mobile in integration QA. Pure styling/text does not need implementation-mirroring tests.

### Task 2: Source-backed Clinical domain pages

**Files:** `inst/templates/DALYCARE_atlas.html`, a focused `tests/test-clinical-domain-sources.js` or existing related behavior test.

**Interfaces:** Current exact catalog/profile rows and `review_clinical_sections`; source specifications for diagnostic layers; existing `browseFieldsLink` and `sourceEvidenceLinks` helpers. Introduce small reusable domain source helpers within the current template rather than a second routing system.

- [x] Add meaningful behavior tests for nonempty source evidence with empty curation, absent exact sources, alias identity, withheld values, and exact source links; run and observe the failures.
- [x] Expose broad Clinical Start choices and usable diagnosis/admissions/notes sources. Add current exact source cards and relevant profile links to microbiology, imaging, pathology, biobank, vital signs and social history.
- [x] Replace repeated empty/null presentation with one honest status and useful next steps, preserving actual available distributions and evidence-layer interpretation.
- [x] Repair social-history exact source and smoking/alcohol routes; do not label smoking intensity as validated pack-years.
- [x] Run focused behavior checks and report implementation with precise files and remaining findings. Root handles commit after review.

### Task 3: Critique the candidate and checkpoint

- [x] Rebuild from iteration-15 matching inputs into a new iteration-16 directory; preserve earlier releases.
- [x] X1, Z3 and W0 reattempt their concrete tasks in fresh browser renders, including phone/offline/exact source coverage. Root personally inspects images.
- [x] Independently review changed source behavior; fix Important findings through the same implementer and scoped re-review.
- [x] Run applicable Node/Python/R checks and legacy-route smoke; compare all published rows/core and asset budgets against iteration 15.
- [x] Record evidence, package local release, commit source, update existing draft PR, then proceed to the next ranked repair cycle while the user-authorized goal is active.
