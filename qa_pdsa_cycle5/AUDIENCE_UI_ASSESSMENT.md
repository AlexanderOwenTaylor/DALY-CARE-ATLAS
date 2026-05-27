# PDSA Cycle 5 Audience UI Assessment

## Summary

Cycle 5 promotes curator-completed semantic labels into the reviewer-facing display path. The issue was not data absence; it was that curated labels were still too often treated as side-table evidence while first-line panels showed code echoes, unmapped labels, or source-debug text.

## Assessment

- The 5,047-row curator file is display-label metadata, not a clinical data source.
- Matching rows should show `fill_preferred_label` first, with raw code, prior label, source table/panel, source column, evidence file, and provenance retained in lineage.
- Ambiguous matches are skipped rather than guessed.
- Counts, payload rows, exports, panels, privacy safeguards, and source-discovery logic remain unchanged.

## Review Focus

- NPU, DNK, SKS/procedure, imaging, pathology, ATC, and source-like code rows should be less code-echo heavy.
- Pseudo-source labels such as `semantic_unmapped_entity_map` and `dalycare_cycle4_curator_label_promotions` should not appear as reviewer-facing source names.
- Remaining unmapped labels should be explainable as no curator label, ambiguity, source-context mismatch, or intentionally raw lineage.
