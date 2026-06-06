# MCL TRIANGLE ASCT/HDT Conditioning Notes

## Primary LYFO ASCT/HDT definition

`asct_hdt_first_line` and `asct_hdt_primary_lyfo` are the same primary first-line ASCT/HDT phenotype. A person is primary ASCT/HDT positive only from LYFO first-line treatment evidence:

- `RKKP_LYFO.Beh_Stamcelleinfusion_dt` is a valid non-missing date.
- `RKKP_LYFO.Beh_Hoejdosisbehandling == "Y"`.
- `RKKP_LYFO.Beh_TypeAutologStamcellestoette` is one of `BEAM`, `OTHER`, `BCNU-THIOTEPA`, `BCNU`, or `BEAC`.

No medication, procedure, protocol, or relapse field is allowed to promote a person into the primary first-line ASCT/HDT phenotype.

## BEAM and melphalan evidence

Melphalan and BEAM-component evidence is validation/sensitivity support only. It can help describe whether a LYFO primary ASCT/HDT event has nearby conditioning support, and it can identify conditioning-only rescue candidates for review. Melphalan alone does not define ASCT/HDT.

`beam_multi_component_near_infusion` requires melphalan plus at least one other BEAM component near a LYFO stem-cell infusion. This prevents a single non-melphalan chemotherapy component from being treated as BEAM conditioning.

`asct_hdt_validated_by_conditioning` requires primary LYFO ASCT/HDT plus conditioning support. Conditioning support cannot create the primary phenotype by itself.

## Cytarabine-alone limitation

Cytarabine-containing induction signals such as DHAP/DHAX are induction or protocol-eligibility proxies. Cytarabine alone is not ASCT/HDT conditioning evidence and must not classify ASCT/HDT.

## BTKi no-ASCT arm rationale

The TRIANGLE-lite BTKi no-ASCT arm proxy is intentionally separate from missing ASCT. A person with induction plus BTKi exposure and no primary LYFO ASCT/HDT is counted as a no-ASCT BTKi arm proxy, not as an ASCT data-quality failure.

## Source-resolution behavior

ASCT/HDT medication and procedure sources fail closed. Each configured source reports an aggregate-only resolution state, including relation missing, columns missing, co-residency failed, bridge failed, available with zero qualifying events, available with qualifying aggregate events, and inventory-only/code-validation-required.

Qualifying-event counts are aggregate only and use suppression rules. Source-resolution output must not emit person identifiers, raw medication names, pathology text, or other row-level clinical text.

Procedure rows with `CONFIG_REQUIRED` or unvalidated ASCT/SCT SKS candidates are inventory/protocol-runway evidence only. They may appear in source-resolution or protocol-runway outputs, but they must not classify primary or sensitivity ASCT/HDT.

`Rec_*` relapse/recurrence ASCT/HDT fields remain separate from first-line ASCT/HDT.

## Remaining gaps

- Exact SKS ASCT/SCT procedure codes are not validated in this pass; procedure sources remain inventory-only.
- Medication capture may be incomplete across available sources and schemas.
- Absence of observed melphalan or BEAM-component support is not proof that conditioning was absent.
- Source-resolution proves source availability and aggregate exact-code event presence; it does not replace clinical validation.
- Long full-suite runtime/timeouts should be reported honestly. Targeted ASCT/HDT tests are the merge-safety signal for this pass, while any full-suite timeout remains an infrastructure/runtime issue until isolated by timestamped runner output.
- In the 2026-06-06 verification pass, `scripts/run_tests.R` timed out. `Rscript --verbose scripts/run_tests.R` showed the first long step as `test-db-profile.R` inside `run_atlas()` at `building semantic outputs`; direct `test-db-profile.R` timing also timed out after 180 seconds at that same step. `test-run-atlas-fixtures.R` separately timed out after 180 seconds at `building semantic outputs` after all fixture sources had loaded.
