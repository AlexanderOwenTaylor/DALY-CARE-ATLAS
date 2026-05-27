# Audience UI Assessment

## Aim

Make the DALY-CARE Atlas easier for internal clinical, research, data-management, onboarding, and operational audiences to understand within the first minute, while preserving all aggregate data, payload fields, CSV-backed rows, panels, exports, and privacy safeguards.

## Audience Assumptions

- Senior investigators need a fast answer to what DALY-CARE can support now and what remains validation-bound.
- Data managers need source status, run status, caveats, and lineage without losing detail.
- Disease researchers need routes into registry, treatment, pathology, laboratory, and feasibility evidence.
- New employees need task recipes before opening dense source catalogs.
- Clinical and management users need scale, governance, care-optimization context, and non-causal caveats.

## Current Assessment

The atlas is credible for guided review, but the first path mixed clinical meaning, infrastructure detail, and source tables too early. The MCL/TRIANGLE panel carried useful fallback values, but those values needed stronger visual labelling so they could not be mistaken for accepted production evidence when the current payload is plan-only, mockup, failed, or not run.

## Measures

- Required audience route cards are visible on the Overview first fold.
- MCL/TRIANGLE distinguishes accepted production aggregate values from fallback/reference values.
- Count-kind and trust badges are visible in first-read KPI areas.
- Search supports audience, disease, source-status, and QA language.
- Dense details remain available through existing tables and disclosure patterns.

## Open Risks

- Fallback values are useful for orientation but require disciplined labelling wherever they appear.
- Candidate evidence can still be misread without guided explanation; the UI must continue to state validation status near each claim.
- Visual QA remains necessary after rendering a fresh static atlas because screenshots can reveal mobile layout issues that static tests cannot.
