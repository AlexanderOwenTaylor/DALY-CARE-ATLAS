# MCL / TRIANGLE Feasibility Panel Notes

## Clinical Motivation

This panel supports aggregate feasibility review for a possible mantle cell lymphoma study of first-line ibrutinib-containing immunochemotherapy with or without ASCT/HDT in younger or transplant-eligible patients, especially when stratified by high-risk biology. It is neutral study-planning infrastructure and does not estimate treatment effects.

## What The Panel Does

- Searches existing aggregate atlas outputs for MCL cohort, eligibility proxy, treatment, outcome, timing, toxicity, and high-risk biology evidence.
- Distinguishes current-profiled evidence from legacy/reference-only evidence.
- Produces a study-readiness matrix and a high-risk biology gap analysis.
- Labels counts by source type such as aggregate value-map count, code-map rows, source rows, or aggregate evidence rows.
- Recommends source activation and mapping steps when biology/timing evidence is weak.

## What The Panel Does Not Do

- It does not expose patient-level rows, patient identifiers, CPR values, or raw free text.
- It does not calculate patient-level cohort counts unless an aggregate output explicitly provides patient counts.
- It does not recommend ASCT/HDT, ibrutinib, or any treatment strategy.
- It does not make causal claims or compare treatment effects.

## Files Added Or Modified

- `config/mcl_triangle_feasibility_concepts.tsv`
- `R/mcl_triangle_feasibility.R`
- `scripts/build_mcl_triangle_feasibility_panel.R`
- `R/run_atlas.R`
- `R/html.R`
- `scripts/run_atlas.R`
- `scripts/build_atlas_mockup_from_run_zip.R`
- `inst/templates/DALYCARE_atlas.html`
- `scripts/visual_qa_atlas.js`
- `tests/test-mcl-triangle-feasibility.R`
- `tests/test-run-atlas-fixtures.R`
- `tests/test-html-payload.R`

## Generated Outputs

The atlas run writes:

- `outputs/mcl_triangle_feasibility_summary.csv`
- `outputs/mcl_triangle_variable_inventory.csv`
- `outputs/mcl_triangle_treatment_inventory.csv`
- `outputs/mcl_triangle_outcome_inventory.csv`
- `outputs/mcl_triangle_biology_gap_analysis.csv`
- `outputs/mcl_triangle_study_readiness_matrix.csv`

The static payload includes `mcl_triangle_feasibility` with those tables plus recommended next actions, caveats, and verdict metadata.

## Evidence Logic

Evidence is searched in this priority order:

1. Semantic dictionary / clinical concept mapping
2. Code maps
3. Value maps
4. Panel links
5. Source/catalog/profile evidence
6. Legacy/reference evidence

Treatment matching includes medication names, ATC/SKS codes, registry treatment/regimen values, and Danish/English variants. Ibrutinib terms include `ibrutinib`, `Imbruvica`, `L01XE27`, `BTK inhibitor`, and `BWHA169` where present. ASCT/HDT terms include `ASCT`, `HDT`, high-dose therapy, autologous stem-cell support, stem-cell infusion, LYFO HDT/stem-cell fields, and transplant/procedure signals.

## Verdict Logic

- `Strongly feasible` requires MCL cohort, ASCT/HDT, ibrutinib, CIT/regimen, at least one outcome, and core high-risk biology markers such as blastoid morphology, TP53, and Ki-67 to have current-profiled direct evidence.
- `Feasible with biology gaps` means cohort plus key treatment and outcome evidence exist, but high-risk biology is incomplete, proxy-only, or legacy/reference-only.
- `Partially feasible` means cohort evidence exists, but treatment or outcome evidence is incomplete.
- `Not currently feasible` means MCL cohort evidence is absent or unusable.

The generator blocks `Strongly feasible` when blastoid morphology, TP53/p53/del17p, or Ki-67 are missing, proxy-only, or only legacy/reference evidence.

## High-Risk Biology Limitations

Missing or weak high-risk biology markers are tied to likely recovery sources:

- Blastoid/pleomorphic morphology: LYFO WHO/histology fields, PATOBANK codes, `t_mikro`, `t_konk`.
- TP53/p53/del17p: pathology text, molecular/FISH resources, RKKP fields where present.
- Ki-67: pathology text, microscopy/conclusion text, possible LYFO fields.
- MIPI/MIPI-c: reconstructability from age, ECOG/performance status, LDH, leukocytes, and Ki-67 when available.

## Regeneration

Standalone generation from an existing run output directory:

```sh
Rscript scripts/build_mcl_triangle_feasibility_panel.R . atlas_runs/<run_id>/outputs
```

Full atlas regeneration:

```sh
Rscript scripts/run_atlas.R . config/source-map.example.tsv atlas_runs report
```

## Local Tests

Recommended checks:

```sh
Rscript scripts/run_tests.R
git diff --check
node scripts/visual_qa_atlas.js <generated site/DALYCARE_atlas.html> qa_screenshots
```

## Future Study-Design Considerations

Any later patient-level study should use a bias-aware design. Candidate designs include induction-completion landmark analysis and clone-censor-weight target-trial emulation. Treatment eligibility, response-dependent ASCT selection, immortal time, and confounding by indication need explicit handling before treatment-effect estimation.

## Known Limitations

- The panel depends on existing aggregate atlas outputs; it does not query patient-level data.
- Counts are only shown when already present in aggregate outputs and must be read with their count-type labels.
- Legacy/reference-only evidence is useful for planning but must be refreshed or source-activated before being treated as current production evidence.
