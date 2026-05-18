# Repository Guidance

- Semantic mapping rule: prefer exact, source-aware field mappings for clinical concepts. Avoid broad substring matching when registry/source-specific rules exist; leave uncertain fields as candidates rather than forcing a misleading concept.
- Laboratory/NPU mapping rule: distinguish NPU/DNK code dictionary rows, SP AlleProvesvar rows, LABKA/SDS rows, PERSIMUNE biochemistry rows, and registry lab fields. Code coverage is not the same as harmonized result-value availability.
- Microbiology mapping rule: distinguish analysis, culture, resistance/susceptibility, microscopy, and SP blood-culture workflow layers. Broad organism/domain groups may be shown; detailed species-level or rare values require suppression/grouping safeguards.
- Imaging mapping rule: distinguish national procedure-code imaging, disease-registry modality/bone-disease fields, SP/EHR imaging metadata/report availability, and radiotherapy procedure signals. Do not treat report text as static atlas content and do not imply image-pixel availability.
- Pathology mapping rule: distinguish coded pathology records, SNOMED code rows, specimen/material fields, institution/source fields, tumor-coded evidence, and report/free-text availability. Never emit raw pathology report text or examples in the static atlas.
- Biobank mapping rule: distinguish sample source, sample type/material, sample availability, and translational/cohort source labels. Do not infer assay availability, molecular data, sequencing, immune profiling, or biomarker results from sample presence alone.
- Atlas product rule: the clinician journey starts with questions and restored panels, not raw source tables. Use source tables and semantic rows as evidence underneath Overview entry cards, concept cards, and domain panels.

## Visual QA Rule

- For atlas HTML/UI work, render the generated HTML before presenting the patch result. Prefer compact cards, KPI strips, badges, bars, collapsed raw lineage, and clear section hierarchy over overwhelming raw tables.
- If browser rendering is unavailable, state that visual rendering was not performed and do not claim visual acceptance.
- The V33 atlas is the visual reference for color, spacing, and scannability.
