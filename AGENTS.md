# Repository Guidance

- Semantic mapping rule: prefer exact, source-aware field mappings for clinical concepts. Avoid broad substring matching when registry/source-specific rules exist; leave uncertain fields as candidates rather than forcing a misleading concept.
- Laboratory/NPU mapping rule: distinguish NPU/DNK code dictionary rows, SP AlleProvesvar rows, LABKA/SDS rows, PERSIMUNE biochemistry rows, and registry lab fields. Code coverage is not the same as harmonized result-value availability.
- Microbiology mapping rule: distinguish analysis, culture, resistance/susceptibility, microscopy, and SP blood-culture workflow layers. Broad organism/domain groups may be shown; detailed species-level or rare values require suppression/grouping safeguards.
- Imaging mapping rule: distinguish national procedure-code imaging, disease-registry modality/bone-disease fields, SP/EHR imaging metadata/report availability, and radiotherapy procedure signals. Do not treat report text as static atlas content and do not imply image-pixel availability.

## Visual QA Rule

- For atlas HTML/UI work, render the generated HTML before presenting the patch result. Prefer compact cards, KPI strips, badges, bars, collapsed raw lineage, and clear section hierarchy over overwhelming raw tables.
- If browser rendering is unavailable, state that visual rendering was not performed and do not claim visual acceptance.
- The V33 atlas is the visual reference for color, spacing, and scannability.
