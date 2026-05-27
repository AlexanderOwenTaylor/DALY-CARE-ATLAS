# MCL/TRIANGLE Evidence Matching Fix Notes

## What changed

The MCL/TRIANGLE feasibility builder now treats source names as context, not proof. Evidence rows must match a concept-specific field, code, value, label, or note before expected/preferred sources can prioritize them.

## Files modified

- `R/mcl_triangle_feasibility.R`
- `inst/templates/DALYCARE_atlas.html`
- `R/run_atlas.R`
- `tests/test-mcl-triangle-evidence-filtering.R`
- `tests/test-mcl-triangle-feasibility.R`

## Matching logic

`expected_sources` and `preferred_sources` are now used only after a row has a real concept-term match. The variable inventory records the match lineage:

- `matched_term`
- `matched_field`
- `match_reason`
- `evidence_category`

Main UI cards use only direct or proxy evidence. `source_space_only` and `false_positive_excluded` rows are kept out of the main treatment/outcome cards.

## ASCT/HDT phenotype correction

Primary MCL first-line ASCT/HDT evidence is driven by LYFO fields:

- `RKKP_LYFO.Beh_Hoejdosisbehandling`
- `RKKP_LYFO.Beh_TypeAutologStamcellestoette`
- `RKKP_LYFO.Beh_Stamcelleinfusion_dt`

Relapse/recurrence fields are retained as proxy/timing evidence, not first-line ASCT/HDT by default:

- `RKKP_LYFO.Rec_Hoejdosisbehandling`
- `RKKP_LYFO.Rec_Stamcelleinfusion_dt`

SKS/LPR transplant codes remain validation/proxy evidence unless confirmed as source-specific ASCT/HDT phenotype codes.

## False positives suppressed

The builder writes `outputs/mcl_triangle_false_positive_exclusions.csv`. It documents why rows such as CLL social-history columns, DaMyDa death-cause transplant values, social-history smoking/drinking, vitals display names, LYFO B symptoms, and `SDS_t_sksube.BWHA169` are not shown as treatment/outcome evidence.

## Readiness language

`ready` is reserved for evidence that is direct enough for cohort-construction logic or explicitly validated. Current aggregate evidence is generally labelled `aggregate_evidence_found_requires_validation`. Ki-67 remains conservative until direct aggregate production evidence is found.

## Rebuild without full atlas profiling

Use the existing aggregate output ZIP as the seed:

```powershell
Rscript scripts/build_atlas_mockup_from_run_zip.R DALYCARE_atlas_ki67_direct_finder_20260521_104011.zip DALYCARE_atlas_triangle_mcl_evidence_ki67_oneclick_YYYYMMDD_HHMMSS.zip
```

This refreshes the MCL/TRIANGLE CSVs and payload from existing aggregate outputs. It does not query production data or rerun the full source profiler.

## Limitations

This remains an aggregate feasibility panel. It does not define patient-level cohorts, treatment windows, causal estimands, or treatment recommendations.
