# PDSA Cycle 3 Plan

## Summary

Cycle 3 is a reviewer-readability pass. It keeps DALY-CARE aggregate evidence intact while making bar charts, labels, aliases, and free-text/code boundaries easier to understand.

## Key Changes

- Make horizontal bars scale by count unless a shared denominator makes percent scaling safe.
- Show meaningful display labels first and keep raw labels in lineage.
- Wrap bar labels instead of hiding them behind single-line ellipses.
- Group obvious aliases only as display metadata unless scope is identical.
- Split pathology free-text availability from coded/code inventory.
- Add reviewer-readability visual QA for clipped labels, repeated prefixes, and empty-state contradictions.

## Measures

- No decreases in tracked tabs, panels, details, exports, payload keys, output files, MCL/TRIANGLE rows, CONFLUENCE rows, source catalog rows, data dictionary rows, or reconciliation rows.
- No tracked panel uses mixed-denominator percent scaling by default.
- No primary treatment/code labels hide the useful term behind repeated source prefixes.
- Free-text availability panels are status-first and do not primarily show code inventories.
