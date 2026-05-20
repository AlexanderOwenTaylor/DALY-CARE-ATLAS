# Ki-67 Discovery Notes

## Purpose

This pass adds a Ki-67 discovery layer for the MCL / TRIANGLE feasibility panel. Ki-67 matters because high-risk mantle cell lymphoma biology and MIPI-c-type stratification often depend on proliferation-index evidence, but the static atlas must remain aggregate-only and must not emit patient-level pathology text or values.

## Search Strategy

The discovery layer searches aggregate atlas artifacts for Ki-67, MIB-1, English/Danish proliferation-index terms, immunohistochemistry terms, structured codes, value labels, and source metadata. It separates:

- structured registry field candidates
- pathology / SNOMED-style code candidates
- pathology text-pattern extraction readiness
- source-only search spaces

The latest TRIANGLE ZIP was checked before implementation. It did not expose confirmed Ki-67 percentage evidence in the MCL feasibility outputs; the previous biology-gap row overstated broad pathology availability as a Ki-67 proxy.

## Danish Patobank Codes

Danish Patobank may encode numeric Ki-67 index using `ÆKIxxx`, where `xxx` is the percentage.

Examples:

- `ÆKI000` = Ki-67 0%
- `ÆKI005` = Ki-67 5%
- `ÆKI020` = Ki-67 20%
- `ÆKI100` = Ki-67 100%

The parser also accepts `AEKIxxx`, mixed-case variants, and common mojibake/transliteration forms. Values must be 0-100; malformed or out-of-range codes are rejected.

These local Danish codes are treated as structured pathology-code evidence for a numeric Ki-67 percent value, with manual Danish codebook validation still required.

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

The text-pattern specification covers exact percentages, ranges, inequalities, qualitative mentions, and unknown/not-stated values. Synthetic examples are used in tests. Real pathology report text is not emitted in the static atlas.

## Limitations

- Source-only pathology, LYFO, `t_mikro`, or `t_konk` availability is search space, not direct Ki-67 evidence.
- Registry field meaning and Danish pathology code semantics still require source documentation or codebook validation.
- The atlas does not compute patient-level Ki-67 values.

## Recommended Validation

1. Validate `ÆKIxxx` semantics against Danish Patobank / Den Danske SNOMED for Patologi documentation.
2. Confirm whether LYFO contains structured Ki-67 fields or value codes.
3. Run a privacy-preserving extraction pilot on pathology text outputs without emitting raw report snippets.
4. Clinically validate value handling for exact, range, inequality, qualitative, and unknown Ki-67 representations before any cohort extraction.
