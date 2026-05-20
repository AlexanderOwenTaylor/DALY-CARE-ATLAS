# Ki-67 Discovery Notes

## Purpose

This pass adds and cleans up a Ki-67 discovery layer for the MCL / TRIANGLE feasibility panel. Ki-67 matters because high-risk mantle cell lymphoma biology and MIPI-c-type stratification often depend on proliferation-index evidence, but the static atlas remains aggregate-only and must not emit patient-level pathology text or values.

## Search Strategy

The discovery layer searches aggregate atlas artifacts for Ki-67, MIB-1, English/Danish proliferation-index terms, immunohistochemistry terms, structured codes, value labels, and source metadata. It separates:

- structured registry field candidates
- Danish pathology code evidence, especially `ÆKIxxx`
- pathology text-pattern extraction readiness
- source-only search space

The latest TRIANGLE ZIP was checked before implementation. It did not expose confirmed Ki-67 percentage evidence in the MCL feasibility outputs; the earlier biology-gap output treated broad pathology availability too much like a Ki-67 proxy.

## Noise Reduction

The cleanup pass reduces repetitive source-only hits before they reach the UI. Full audit rows remain in `outputs/ki67_search_inventory.csv`, but the visible panel now uses `display_in_ui`, `ui_group`, `ui_priority`, `suppression_reason`, and `evidence_channel` to show concise grouped rows.

Generic microscopy is no longer a standalone Ki-67 trigger. In particular, `microbiology_microscopy` is excluded from Ki-67 search-space evidence unless a row contains a direct Ki-67/MIB-1/`ÆKIxxx`/proliferationsindeks hit. Microbiology microscopy is not a plausible MCL Ki-67 recovery source by name alone.

Broad pathology or LYFO source availability remains useful for planning source activation, but it is search space, not Ki-67 evidence. Source-only evidence cannot raise Ki-67 readiness above `weak_candidate_only`.

## Danish Patobank Codes

Danish Patobank may encode numeric Ki-67 index using `ÆKIxxx`, where `xxx` is the percentage.

Examples:

- `ÆKI000` = Ki-67 0%
- `ÆKI005` = Ki-67 5%
- `ÆKI020` = Ki-67 20%
- `ÆKI100` = Ki-67 100%

The parser also accepts `AEKIxxx`, mixed-case variants, and common mojibake/transliteration forms. Values must be 0-100; malformed or out-of-range codes are rejected.

These local Danish codes are treated as structured pathology-code evidence for a numeric Ki-67 percent value, with manual Danish codebook validation still required. Current static artifacts do not expose confirmed aggregate `ÆKIxxx` counts, so the route is currently a production-validation plan, not a confirmed finding.

## p16 / Ki-67 Dual-Stain Guardrail

The following codes are tracked separately:

- `FY5015` = p16/Ki-67-positive cells not detected
- `FY5016` = p16/Ki-67-positive cells detected
- `M0901K` = inconclusive p16/Ki-67 test
- `M0901L` = too little material for p16/Ki-67

These are p16/Ki-67 dual-stain cervix-triage signals, not numeric MCL Ki-67 proliferation-index values. They must not upgrade MCL/TRIANGLE Ki-67 readiness to `strong_structured_numeric`.

## External SNOMED CT Anchors

The discovery layer includes these external SNOMED CT anchors as search references only:

- `1255078008`
- `1279926000`

They are not assumed to be present in Danish Patobank and are not treated as proof of local Danish pathology coding.

## Extraction Readiness

The text-pattern specification covers exact percentages, ranges, inequalities, qualitative mentions, and unknown/not-stated values. Synthetic examples are used in tests. No validated real patient-level pathology text extraction has been performed in the static atlas, and real pathology report text is not emitted.

Production validation should run aggregate-safe counts only:

- reports containing Ki-67/MIB-1/proliferationsindeks terms
- reports with extractable exact, range, or inequality percentages
- reports with qualitative-only or unknown/not-stated mentions

The output must not contain identifiers, dates, requisition IDs, raw snippets, or patient-level rows.

## Current Aggregate Finding

The current aggregate atlas artifacts do not expose confirmed structured Ki-67 percentage evidence. Ki-67 remains a candidate recovery route through `ÆKIxxx` pathology codes and pathology text patterns, but those routes require production validation and clinical/pathology review.

| Question | Current answer |
| --- | --- |
| Structured registry Ki-67 field confirmed? | Not found in current aggregate artifacts |
| Danish pathology/SNOMED-style Ki-67 code confirmed? | `ÆKIxxx` parser ready; aggregate production validation required |
| Pathology text-extractable? | Regex readiness specified on synthetic examples only |
| Exact numeric percentage extraction likely feasible? | Plausible after validating code/text sources |
| Manual validation required? | Yes |

## Limitations

- Source-only pathology, LYFO, `t_mikro`, or `t_konk` availability is search space, not direct Ki-67 evidence.
- Registry field meaning and Danish pathology code semantics still require source documentation or codebook validation.
- The atlas does not compute patient-level Ki-67 values.
- The static atlas does not validate extraction from raw pathology text.

## Recommended Validation

1. Validate `ÆKIxxx` semantics against Danish Patobank / Den Danske SNOMED for Patologi documentation.
2. Confirm whether LYFO contains structured Ki-67 fields or value codes.
3. Run aggregate-only `ÆKIxxx` code counts in candidate pathology code fields.
4. Run a privacy-preserving pathology text pattern count pilot without emitting raw report snippets.
5. Clinically validate value handling for exact, range, inequality, qualitative, and unknown Ki-67 representations before any cohort extraction.
