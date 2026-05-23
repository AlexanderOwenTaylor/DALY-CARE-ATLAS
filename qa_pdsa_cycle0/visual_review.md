# PDSA Cycle 0/1 Visual Review

## Scope

This pass used the patched static `mockup.zip` as the baseline artifact and rebuilt a static preview from aggregate-only outputs. It did not run the full 64-source production atlas and did not change data-discovery or standalone count SQL.

The review question was:

> Would I be comfortable giving a clinical PI a 5-minute guided walkthrough tomorrow?

## Guided Walkthrough Path

1. Overview: what DALY-CARE can do now.
2. Clinical Feasibility / TRIANGLE-lite.
3. Pathology/PATOBANK Ki-67 source discovery.
4. Data/source signposting.
5. Caveats and next steps.

## Visual QA Evidence

Visual QA completed against `qa_pdsa_cycle0/pdsa_cycle0_mockup_after/site/DALYCARE_atlas.html`.

- Screenshot folder: `qa_pdsa_cycle0/screenshots/`
- Overflow report: `qa_pdsa_cycle0/screenshots/overflow_report.json`
- Rendered views checked: 70
- Views with body or element overflow: 0
- Result: visual QA passed

## What Improved In This Cycle

The Overview now leads with a short clinical walkthrough path instead of dropping the viewer directly into panel cards and infrastructure-like run status. The first screen tells a clearer story: what the atlas can show, where to go for TRIANGLE-lite, where Ki-67 lives, and how caveats/next steps should be interpreted.

The TRIANGLE-lite panel now surfaces the key Output(5) counts immediately: all LYFO MCL, age <=65 younger proxy, expanded ibrutinib exposure, and the age <=65 + ASCT/HDT + ibrutinib overlap. This makes the proof-of-concept feasible to narrate before scrolling into the longer study-design language.

The Pathology/PATOBANK tab now opens with a "What this means" section that makes Ki-67 discoverability explicit through `SDS_pato.c_snomedkode` and `AEKI/ÆKI`, while keeping pathology text candidate-only and non-emitted.

## Current Readiness

Recommendation: showable with guided narrative.

The atlas is credible for a short guided clinical stakeholder walkthrough if the presenter follows the path above and frames the output as feasibility/pre-study evidence. It is not yet polished enough to hand over as a fully self-service clinical website because some source-catalog and dictionary sections remain dense.

## Residual Risks For Next Loop

- Data Dictionary and resource-catalog sections still read as analyst tooling rather than clinical review artifacts.
- Several restored domain panels remain useful but can still feel source-heavy without a presenter.
- Mobile views pass overflow QA, but the Overview hero/search area still consumes a lot of vertical space before the clinical walkthrough.
- The clinical narrative depends on careful caveat language: descriptive feasibility only, no causal treatment effect, no safe ASCT omission claim, no observed transplant eligibility, no validated MIPI-c, and no validated free-text Ki-67 extraction.
