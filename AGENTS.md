# Repository Guidance

- Semantic mapping rule: prefer exact, source-aware field mappings for clinical concepts. Avoid broad substring matching when registry/source-specific rules exist; leave uncertain fields as candidates rather than forcing a misleading concept.
- Laboratory/NPU mapping rule: distinguish NPU/DNK code dictionary rows, SP AlleProvesvar rows, LABKA/SDS rows, PERSIMUNE biochemistry rows, and registry lab fields. Code coverage is not the same as harmonized result-value availability.

## Visual QA Rule

- For atlas HTML/UI work, render the generated HTML before presenting the patch result. Prefer compact cards, KPI strips, badges, bars, collapsed raw lineage, and clear section hierarchy over overwhelming raw tables.
- If browser rendering is unavailable, state that visual rendering was not performed and do not claim visual acceptance.
- The V33 atlas is the visual reference for color, spacing, and scannability.
