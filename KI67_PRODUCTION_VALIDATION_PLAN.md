# Ki-67 Production Validation Plan

## Scope

This plan describes aggregate-only validation for Ki-67 discovery. It does not rerun the full atlas pipeline, does not export patient-level rows, and does not emit raw pathology report snippets.

## Outputs

The Ki-67 cleanup adds three validation-planning outputs:

- `outputs/ki67_aeki_validation_plan.csv`
- `outputs/ki67_aeki_code_counts.csv`
- `outputs/ki67_text_validation_plan.csv`

In fixture/static mode, `ki67_aeki_code_counts.csv` contains a placeholder row with `requires_production_validation`; it must not fabricate positive counts.

## Danish Patobank `ÆKIxxx` Strategy

Candidate code patterns:

- `^ÆKI([0-9]{3})$`
- `^AEKI([0-9]{3})$`
- mixed-case/lowercase variants
- observed mojibake/transliteration variants

Validation rules:

- Parse the three digits as a percent.
- Accept only 0 through 100.
- Reject values above 100 and malformed codes.
- Return aggregate counts by code and source table only.
- Include distinct patient counts only if local disclosure rules permit them.
- Include year ranges only if local disclosure rules permit them.

Safe output shape:

```text
resource_id
source_table
code
parsed_percent
aggregate_count
distinct_patient_count_if_allowed
year_min_if_allowed
year_max_if_allowed
validation_status
notes
```

The query should search configured pathology code fields in `pato`, `t_mikro`, and `t_konk` candidates. It must not return identifiers, dates, requisition IDs, raw report text, or row-level records.

## p16 / Ki-67 Dual-Stain Guardrail

The following codes should be counted separately if encountered, but must not be treated as numeric MCL Ki-67 proliferation-index values:

- `FY5015`
- `FY5016`
- `M0901K`
- `M0901L`

They are useful for false-positive avoidance and codebook documentation, not for upgrading MCL/TRIANGLE Ki-67 readiness to `strong_structured_numeric`.

## Pathology Text Strategy

Aggregate-only text validation should count:

- reports containing Ki-67, Ki67, MIB-1, MIB1, or proliferationsindeks terms
- reports with exact numeric percent patterns
- reports with range percent patterns
- reports with inequality percent patterns
- reports with qualitative-only mentions
- reports with unknown/not-stated mentions

The production validation should return counts by resource, source table, pattern, and value class. It must not return raw snippets or identifiers.

## Privacy Safeguards

- No CPR, patient IDs, requisition IDs, specimen IDs, dates, or free-text snippets.
- Suppress or group rare categories according to local DALY-CARE disclosure rules.
- Use aggregate counts only.
- Treat all outputs as feasibility evidence, not analytic cohort data.

## Updating MCL/TRIANGLE Readiness

After production validation:

- Confirmed valid `ÆKIxxx` aggregate counts can upgrade Ki-67 to `strong_structured_numeric` after Danish codebook validation.
- Validated pathology text pattern counts can support `moderate_text_extractable`, but analytic use still requires manual clinical/pathology validation.
- Source-only pathology/LYFO availability should remain `weak_candidate_only`.
- The panel must not become `Strongly feasible` unless Ki-67 and other key high-risk biology markers have direct/current validated evidence.

## Command

Cached-output mode can be run without DB access:

```bash
Rscript scripts/build_ki67_discovery.R --mode cached_outputs --project-root . --outputs-dir outputs
```

Validation-only mode checks the finder without writing outputs:

```bash
Rscript scripts/build_ki67_discovery.R --mode cached_outputs --project-root . --outputs-dir outputs --validate-only true
```

Targeted production validation should be implemented as an aggregate-only DB routine using the output specifications above, not by rerunning the full source-profiling loop.
