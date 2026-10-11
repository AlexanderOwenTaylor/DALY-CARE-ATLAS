# Atlas breadth and source discovery — iteration 16

The X1 researcher, Z3 clinician and W0 V33 comparison reviews independently found that the atlas hides broad existing evidence behind a measurement-led opening and empty domain panels. This iteration restores useful routes through the existing three-page site. The historical V33 is a visual reference, not a source of current statistics or instructions.

## Intended experience

Home and Clinical Start should immediately name diagnoses and registries, treatment, admissions, laboratory tests, microbiology, imaging, pathology, samples, molecular sources, vital signs, social history and notes. Compact groups can combine related topics. The clinician chooses a topic and reaches exact sources, available field profiles and source-specific years/regions. Weight, height and haemoglobin remain useful examples within this broader map.

Domain pages must distinguish three different states: a documented source exists, its field profiles are supplied, and its observed summaries are published or withheld. An absent panel-curation layer must not hide source evidence. Show one concise explanation of missing summaries, rather than multiple empty charts and zero mapping counters. Preserve any actual supplied distributions and their privacy rules.

Use current declared review-section membership and exact catalog names. Where a domain has explicit maintained source specifications, intersect these with the current catalog; do not invent source membership with broad substring matching. Deduplicate only exact identities or explicitly declared aliases, never similarly named sources. Source rows are not people, events of interest, or pooled domain totals.

The independent source audit found that some existing review inventories themselves contain substring false positives (imaging in diagnoses, medication in admissions, contacts in imaging). They are candidate inventories, not authoritative classifications: filter them through explicit exact domain specifications. Repair their upstream producer in a separately tested follow-on cycle rather than silently changing this snapshot's aggregates.

## First repair cycle

- Compact broad Home topic map, followed by field/definition/coverage tasks. Home remains static and light; no core-payload dependency or new entry schema is needed.
- Clinical Start mirrors the breadth. Diagnoses, admissions and notes use their existing declared source inventories. Microbiology, imaging, pathology and biobank expose exact current source cards and field/coverage actions. Vital-sign events and social-history sources become visible without false distribution claims.
- Correct social-history source identity and smoking/alcohol actions; remove dummy category bars when counts are unavailable. Collapse technical details and empty panel subsections rather than deleting useful source interpretation.
- Keep larger registry navigation, contextual field ordering, treatment navigation and a temporal overview chart in the next reviewed cycle. These are recorded work, not silently dropped findings.

## Constraints

- Preserve offline double-click and HTTP operation, existing routes, lazy rendering and keyboard access.
- Home and Data tables initial assets each remain below 512 KiB. Do not load the Clinical core on Home.
- Preserve all current published data, withholding and source-aware semantics; no raw rows, identifiers, note/report text, old counts or borrowed units.
- Preserve separate microbiology workflow layers, imaging metadata/procedures versus pixels, coded pathology versus text, and sample presence versus assay results.
- Source/field links retain exact source and field context; annual and regional summaries remain separate with their supplied date basis.
- Keep R and Python publishers compatible. Generated exports remain local; GitHub changes are source only on the existing draft branch.

## Acceptance

At desktop and phone widths, the first page conveys the breadth before a large single-measurement card. Starting from the topic map, a user can find a diagnosis field, an admission source, susceptibility interpretation/value/unit fields, sample source/material fields, imaging metadata and coded pathology source evidence without memorizing technical table names. Smoking/alcohol routes do not open zero-match searches. Missing metadata has an honest useful fallback. No current aggregates change.
