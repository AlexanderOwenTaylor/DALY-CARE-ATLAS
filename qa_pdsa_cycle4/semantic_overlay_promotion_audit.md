# Semantic Overlay Promotion Audit

## Cycle 4 Static Audit

- Overlay rows supplied: 3,902.
- Wired overlay rows: 3,805.
- Conflict-pending rows: 97.
- Display resolver payload rows: 3,902.
- Code-map rows with `semantic_unmapped_entity_map` as source after promotion: 0.
- Dictionary rows with `semantic_unmapped_entity_map` as source after promotion: 0.

## Promotion Policy

Only wired overlay rows are eligible for automatic first-line label promotion. Conflict-pending rows remain in the conflict audit and may appear as lineage/provenance, but do not replace existing non-generic labels.

## Remaining Unmapped Reasons

Remaining unmapped/code-only labels should be classified as one of:

- no dictionary entry;
- conflict pending review;
- ambiguous code system;
- insufficient source context;
- intentionally raw/source-lineage only.
