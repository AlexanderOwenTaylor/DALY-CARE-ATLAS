# Repository Guidance

- Semantic mapping rule: prefer exact, source-aware field mappings for clinical concepts. Avoid broad substring matching when registry/source-specific rules exist; leave uncertain fields as candidates rather than forcing a misleading concept.

## Visual QA Rule

- For atlas HTML/UI work, render the generated HTML before presenting the patch result. Prefer compact cards, KPI strips, badges, bars, collapsed raw lineage, and clear section hierarchy over overwhelming raw tables.
- If browser rendering is unavailable, state that visual rendering was not performed and do not claim visual acceptance.
- The V33 atlas is the visual reference for color, spacing, and scannability.
