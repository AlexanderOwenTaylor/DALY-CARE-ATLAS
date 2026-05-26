# PDSA Cycle 4 Audience UI Assessment

## Aim

Make the completed semantic dictionary act like a first-line display resolver, not just a side-table overlay.

## Assessment

The atlas had correctly ingested the completed semantic map, but many reviewer-facing views still showed code echoes, unmapped labels, or the pseudo-source `semantic_unmapped_entity_map`. The issue was promotion: curated non-conflicting labels needed to be used wherever the current label was generic or code-only.

## Preservation Position

- All aggregate rows, semantic rows, overlay rows, conflict rows, and exports remain available.
- Conflict-pending mappings stay audited and are not silently promoted.
- Raw code/source/provenance remains available in lineage and exports.
- No production queries, count logic, privacy safeguards, or min-cell rules are changed.
