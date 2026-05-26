# PDSA Cycle 4 Plan

## Summary

Promote the completed semantic overlay into the reviewer-facing label path while preserving raw lineage and conflict audits.

## Key Changes

- Derive source display from source tables/files instead of hard-coding `semantic_unmapped_entity_map`.
- Add an uncapped `semantic_overlay_lookup_rows` payload for display-label resolution.
- Promote wired overlay labels into generic/code-echo native semantic rows.
- Keep conflict-pending rows in audit/lineage only.
- Add visual QA for visible pseudo-source leakage and unresolved mapped-code labels.

## Measures

- Overlay rows: 3,902.
- Wired overlay rows: 3,805.
- Conflict-pending rows: 97.
- Reviewer-facing code/dictionary source rows using `semantic_unmapped_entity_map`: 0.
- Payload lookup rows available to the resolver: 3,902.
