# Exact clinical source membership in builds and presentation

X1 identified substring-based false positives in the R review/readiness/product
metadata: imaging can enter diagnoses, administered medicine can enter admissions,
and contact names can enter imaging. Source-row sums also combine overlapping
views and full procedure inventories. Iteration16 protects its restored pages with
exact local specifications; this cycle makes a reviewed inventory shared across
fresh R production and historical snapshot presentation.

## Scope agreed after X1 and Y2 critique

Cover twelve panel IDs: diagnosis_atlas, clinical_adt, clinical_notes,
clinical_microbiology, clinical_imaging, clinical_pathology, clinical_biobank,
clinical_vitals, clinical_social_history, reg_damyda, reg_lyfo and reg_cll.
Do not expand into treatment/exposure, generic laboratory/NPU/isotype, molecular,
EHR landscape, temporal/regional grouping, clinical concepts or database resolution.
Remaining discovery heuristics must not be described as repaired by this cycle.

Use the finite already audited source families in the iteration16 Clinical
specifications and explicit reviewed alias declarations in expected/canonical
resources. Exclude uncertain `EKOKUR?` and unreviewed archive/lookalike variants.
SDS_epikur and EKOKUR stay out of Notes regardless of old ClinicalText metadata.
The two are not merged. Molecular/pathology/biobank composite readiness must not
claim molecular coverage from only pathology/biobank sources.

## Shared resource and pure selectors

One required installed resource: `inst/config/clinical-source-membership.json`.
No duplicate editable root copy. Schema version 1, inventory_version string, panels
array. Each panel has panel_id, optional review_key, sources array. Each source
entry has membership_id, nonempty exact source_keys array, optional established
canonical_resource_id, membership_role and evidence_layer. Array order supplies
display order. Roles: primary, context, derived_view, text_availability.

The resource owner freezes its JSON shape and shared literal fixture before other
workers implement consumers. Validate versions, strings, accepted roles, duplicate
panel/family memberships, prototype-related keys, and conflicting aliases. A
source key cannot silently map to unrelated families. Cross-panel membership is
allowed explicitly with different roles. Repeated family declarations must agree
on accepted aliases/canonical lineage. Missing/malformed config fails publication.
Pure validation permits nonempty panel subsets for small explicit fixtures;
required publication loaders require all twelve covered panel IDs. Otherwise a
partial installed file could incorrectly make omitted panels look empty.

R uses explicit project inst/config first, installed package config second. Python
uses explicit project_root. Pure selectors accept parsed metadata and supplied
current source rows; no independent regex or canonical resolver. Exact table_name
is the identity. Preserve every current alias identity, even if only one has field
profiles. No profile-based deduplication, case folding, Unicode normalization,
substring or first-match alias resolution. Canonical IDs describe lineage only.

Duplicate catalog identities or conflicting supplied canonical lineage produce
bounded diagnostics; never choose or sum their counts. Preserve the input rows.
Unknown keys stay available in the full catalogue rather than becoming guessed
clinical sources. Source presence, load status and field-profile presence remain
different facts. Known load spellings ok/loaded may be recognized explicitly.

## Derived presentation contract

Add optional `clinical_source_inventory` to the existing Clinical payload:
schema_version, inventory_version, basis=`reviewed_exact_source_inventory`,
evidence_origin=`fresh_run` or `imported_snapshot`, inventory_state=`present`,
`limited` or `unavailable`, rows and diagnostics. The source basis is the guarded
Clinical catalog, not a mixture of CSV counts and snapshot profile evidence.
Absent/malformed catalog is unavailable, explicit empty array is present-empty;
known truncation or legacy 1000-row ceiling saturation is limited. Saturation
means omitted rows cannot be ruled out, not that omission is established.
Present describes the supplied inventory, not proof
of complete DALY-CARE coverage. Do not infer missing sources are absent upstream.

Membership rows contain panel_id, membership_id, actual source_key, optional
unambiguous canonical ID, role/layer and necessary ambiguity/state flags. Do not
duplicate source counts, dates, field values or text. Consumers join exact existing
catalog/profile/coverage rows. Ambiguous duplicate identity counts must not be
chosen arbitrarily; show a clear limitation with original evidence access.

Clinical prefers supported supplied membership metadata for covered domains and
source-readiness presentation, retaining labels/selected-field lists as separate
presentation data. Both declared aliases retain exact routes. Old payloads without
the object retain the iteration16 fallback. Malformed/unsupported present metadata
shows a clear source-inventory limitation rather than silently asserting fallback
authority or crashing the atlas. Existing eligible distributions, including
registry-only imaging, remain governed by their reviewed selectors/disclosure.

Home and Data tables do not load the object. No new browser request is required.

## Fresh versus historical evidence

Fresh R review_clinical_sections, covered readiness rows and product source KPIs
use the shared selector. Exact source identity counts are metadata, not people,
independent datasets or clinical events. Covered readiness retains numeric schema
but emits NA for pooled n_rows/n_columns, blank pooled dates and a plain reason.
Covered product mapped_sources is labelled Current source identities; compatible
source_rows value is `Not summed`, label `Source records (not additive)`, empty unit.
Never replace unsupported sums with zero. Readiness describes source state only;
header-only/withheld panel names cannot establish eligible clinical summaries.

Fresh derived metadata CSVs necessarily change. Raw source inventories, profiles,
dedicated clinical distributions and their counts remain unchanged. Do not claim
all fresh CSVs are unchanged while correcting the faulty metadata CSVs.

Historical Python migration adds only the derived object. Preserve all original
payload arrays and registered CSV shards, including old review/readiness/KPI
evidence; label accessible original readiness as historical supplied metadata.
The new object is authoritative for covered grouping. It is not a database rerun.

Load resource once at explicit run/rebuild boundaries and pass parsed metadata.
Wire any new R helper into source-mode run/rebuild/mockup/test loaders and installed
resources. Record its version/input identity in publication manifests. R-only
installed publication must work without a checkout or Python; required resource
absence must fail rather than silently use heuristic grouping.

## Verification and authorized delivery

Shared literal fixtures cover real stem collisions, exact registries versus CLL
companions, declared aliases/lookalikes/both-present identities with unequal
profiles, duplicate/conflicting lineage diagnostics, overlapping views/procedure
context, Epikur/notes/pathology/microbiology distinctions, missing/limited/empty
inventory, and zero/null evidence. Assert preserved original inputs and snapshot
arrays/CSV rows, not equality with faulty historical sums.

Run R fresh/CLI/offline/installed-resource acceptance, Python historical migration,
Node source/readiness/legacy route tests and shared selector parity. X1 verifies
source identities and count interpretation; Z3 checks clear current-source actions;
W0 checks recovered breadth without resurrecting old statistics. Independent Y2
reviews important correctness/compatibility defects. Root compares all original
historical evidence, tests byte ceilings, inspects browser renders and saves a
source-only checkpoint to existing draft PR under the ongoing user authorization.
