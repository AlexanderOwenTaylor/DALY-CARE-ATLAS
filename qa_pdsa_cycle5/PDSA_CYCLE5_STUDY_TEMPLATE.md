# PDSA Cycle 5 Study Template

## Plan

Promote approved curator labels into first-line reviewer-facing labels while preserving raw lineage and exports.

## Do

- Load and validate the 5,047-row curator CSV.
- Build deterministic lookup keys.
- Promote labels only when matching is unambiguous.
- Generate remaining-unmapped and promotion-summary QA outputs.

## Study

- Compare visible code echoes/unmapped labels before and after promotion.
- Inspect NPU, imaging/SKS, treatment, pathology material/institution, tumor-coded pathology, and microbiology/source-like panels.
- Confirm pseudo-source/config filenames do not appear as clinical source labels.

## Act

- Keep ambiguous rows in the QA audit for curator review.
- Use remaining unmapped rows to prioritize the next dictionary curation pass.
