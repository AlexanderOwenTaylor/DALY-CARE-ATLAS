# PDSA Cycle 1 Plan

## Aim

Improve audience fit and presentation trust in the static DALY-CARE Atlas without changing count logic, discovery logic, min-cell suppression, payload construction, CSV generation, or privacy boundaries.

## Prediction

If the Overview starts with task-based audience routes, MCL/TRIANGLE labels fallback values as fallback/reference counts, and trust/count-kind badges appear next to headline values, then internal reviewers can understand the atlas faster without losing access to technical detail.

## Changes

- Add six task-based Overview route cards.
- Add an internal briefing panel under Overview.
- Add count-kind and trust badge semantics for production, fallback/reference, plan/mockup, blocked, and feasibility-only states.
- Keep fallback values visible, but distinguish them from accepted production aggregates.
- Extend search synonyms for onboarding, source status, QA, disease areas, MCL/TRIANGLE, Ki-67, TP53/p53/del17p, and management-oriented terms.
- Keep all detailed tables, source rows, and exports available.

## Measures

- Static tests assert required route labels, badge helpers, MCL/Triangle caveats, and search terms.
- Presentation non-regression checks confirm payload row counts are not reduced during static atlas writing.
- Visual QA should capture Overview, Quick Start, Clinical Feasibility, Data Dictionary, Infrastructure, and mobile views.

## Acceptance Criteria

- No aggregate data, payload rows, CSV-backed rows, tabs, panels, source cards, audit tables, fallback values, or exports are removed.
- Fallback values are visibly labelled as fallback/reference and not accepted production truth.
- Accepted production aggregate values remain visually distinct from fallback values.
- MCL/TRIANGLE does not imply treatment-effect evidence, treatment recommendation, or safe ASCT/HDT omission.
- The atlas remains aggregate-only and privacy-safe.
