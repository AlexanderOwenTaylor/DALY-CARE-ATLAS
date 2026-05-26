# PDSA Cycle 5 Plan

## Summary

Promote the curator-completed label CSV into the primary semantic display resolver for still-unmapped or insufficiently mapped DALY-CARE Atlas entities.

## Key Changes

- Track `config/dalycare_cycle4_curator_label_promotions.csv`.
- Validate required columns, row count, non-empty labels, privacy-safe content, and encoding hygiene.
- Build deterministic curator label lookup rows with exact-key priority and ambiguous-match skipping.
- Apply curator labels to display-derived semantic dictionary/code-map rows without adding duplicate semantic rows or changing counts.
- Expose compact payload/export lookup surfaces for browser-side display resolution.
- Keep config filenames and pseudo-source names out of reviewer-facing source labels.
- Preserve prior labels and raw code/source lineage.

## Measures

- Input curator rows: 5,047.
- Lookup rows available to display resolver: 5,047.
- Promoted labels retain `prior_display_label` and `curator_label_provenance`.
- No active `conflict_pending_review` state is introduced for approved curator rows.
- No aggregate counts or privacy protections are changed.
