# Medication field discovery

2026-10-12. Base: accepted21 `6fccf10eb145ff3fa9233d19babd019f40e74346`.
Root selects this design under the user's continuing iterative-work request.
Implementation starts after a fresh independent design review. X1, Z3, W0 and
Y2 preparation reports are in local `.artifact-temp/iteration21-team/`.

## Problem and selected approach

Treatment currently orders evidence groups by source-record magnitude. Root's
fresh accepted20 desktop render puts medication administration at y1003 and orders
at y1889, behind four procedure-source count cards. The useful action/status, time
and ATC fields require another source-inventory search. Clinical HTML is unchanged
in accepted21, so that observation remains applicable.

Improve the existing administration/order sections with compact selected-field
links and explicit group order. Do not add a task card, another view or route state.
Links at the old position would retain the discovery problem; a new task card
would add an unnecessary detour. V33 informs concise field lists and nearby source
context, never copied values, dates, distributions or clinical interpretations.

## Scope and hierarchy

One owner changes `inst/templates/DALYCARE_atlas.html`, including narrowly scoped
CSS and Treatment helpers, plus focused tests. No outputs21, R/Python, transport,
schema, dictionaries, source-membership maps, guards or other domain changes.

At the primary Treatment group-rendering seam, put existing `sp_administered` then
`sp_ordered` groups first. Keep all other groups in their current relative order,
including unknown future groups. Do not change shared source sorting or context
classification. Do not manufacture a missing source or promote a candidate.

Place the two existing sections together, side by side where space permits and
stacked on phones. Use one readable heading, exact identity, a concise role
sentence, three direct field links, neutral source actions and optional additional
fields/source details. No large KPI strip or repeated preamble above the links.
Keep normal font sizes and 44px primary targets. The order section must be easy
to find without a long administration preamble; actual phone pixels decide this.

Administration-source records describe actions and do not alone establish a
delivered dose. Orders do not establish administration. Keep the distinction
visible. A wording-only correction to the existing administration description is
allowed; classification stays unchanged. Other source interpretations remain.

Only these exact source/field pairs are selected:

- `SP_AdministreretMedicin`: primary `mar_action_c`, `taken_time`, `atc`;
  additional `sig`, `zc_med_unit_name`, `zc_admin_route_name`.
- `SP_OrdineretMedicin`: primary `order_status_c`, `order_start_time`, `atc`;
  additional `is_pending_ord_yn`, `hv_discrete_dose`.

Use the reviewed label itself as the link with the raw key alongside it, not a
field card plus repeated action. Additional fields may use one native disclosure
per source. Clearly say selected fields; this is not an exposure definition.
Keep full-source browsing and source years/regions actions. Do not hard-code the
historical export's annual/regional availability or eagerly read coverage tables.
The existing source-specific destination supplies its own truthful current state.

## Exact identity and publication

An enhancement requires the exact displayed SP source identity in its existing
appropriate context. Case/whitespace variants, substring matches or conflicting
identity fields retain ordinary source presentation without borrowed fields.
Resolve labels from already-loaded `clinicalDictionaryRows` using exact
`kind === 'field'`, `system === source`, `code === field`. Do not use normalized
`clinicalDisplayEntry`. Nonexact, blank/malformed or conflicting definitions fall
back to the raw key. Identical repeated definitions with one label are acceptable.
No new translations or additional dictionary download are part of this change.

Use every exact matching `columnRows` profile for each pair. One discovery link
opens accepted21, which retains all profiles in order; do not select a canonical
row, sum counts, borrow units or preview numeric/category/date/dose values here.
Say when multiple profiles exist. A reviewed label without any profile remains a
definition: show no-published-profile text without a misleading evidence link.
Keep source actions available. A field link is not a claim that its values are
published or valid. Retain concise protected/publication-difference exceptions
where supplied; unknown markers may use a neutral publication-details cue. Never
apply one duplicate profile's reason to all, infer zero, or claim validation.

Keep the existing source record/count facts accessible in source details. The
compact primary presentation need not repeat numerical source counts. Reuse the
existing source-card renderer inside those details, with no new field list there,
so no newly exposed raw metadata or alternative count formatter is introduced.
For repeated exact source entries, show one finite field list, explicitly note
multiple supplied entries and retain every original source card/fact in details.
Do not choose the largest/first entry as authoritative or add their counts.

Only primary presentation of the two promoted groups gets selected-field lists.
Technical matrix/admin-order calls retain existing evidence without repeating
the new discovery list. Every other source, interpretation, code-reference action
and original technical section remains reachable. No source remapping or fresh
patient/record/category/date evidence is introduced.

## Navigation and verification

Use native escaped exact-pair Data tables links. The two `atc` fields have distinct
source URLs. Keep Treatment's existing fragment/global-query/Back/refresh behavior;
no new handlers for task state or registry themes. Keep deferred rendering and
beforeprint flushing. Optional fields and metadata use native accessible details.

Meaningful executable tests cover exact/normalized decoys, conflicting labels,
all eleven pairs and both ATC destinations; protected/unknown/no/multiple profiles;
duplicate or conflicting source identities; zero/null/guarded source facts kept in
details; missing enhanced sources; all other original sources and stable fallback
group order; no value previews or repeated enhancement in technical calls.

After independent source review and original-owner corrections, run the applicable
complete Node suite, portable UI-builder checks and relevant Treatment regression
test. Build from accepted21 plus matching run. Preserve every protected core value
and every table descriptor/row. Home/Library/transport stay byte-identical; check
the Clinical asset delta and requests, without claiming a speed improvement.

## Rendered-review correction

The initial iteration22 phone render exposed a task-level P2: two introductory
paragraphs and repeated generic publication notes put orders at y1177 at 390px.
Z3 and W0 independently requested a bounded compactness correction, accepted by
root under the continuing user instruction. Use plain "Treatment data" and one
brief orientation sentence; remove the redundant primary-dashboard preamble.
Keep all sources and their facts available rather than repeating the source-count
overview above the selected fields. Tighten local field/name-key spacing without
reducing readable text or 44px primary targets.

Consolidate the generic "Publication details" cue once per enhanced source when
any selected field would have that cue; use a short sentence explaining that
field links show recorded availability and publication limits. This is a neutral
instruction, not a common reason or eligibility claim. Keep no-profile, multiple
profile, differing-state and protected cues on their respective fields. Unknown
markers therefore retain a neutral cue; no status is relabelled as published,
validated or zero. Keep exact-pair destinations as the authoritative per-profile
explanation. Additional/source disclosures remain native and independently
usable. Actual final phone pixels and keyboard navigation must be reviewed again.

Render desktop and phone over HTTP and offline. X1 checks evidence meaning and
exact destinations; Z3 checks task discovery, keyboard/disclosures/focus/44px and
Back/refresh; W0 checks compactness and source/table context. Root inspects pixels
and data parity. Verify neutral source-coverage links, actual order/admin coverage
states at their destination, and all original evidence reachable. If print CSS
changes, render print output. No whole-atlas usability/privacy certification.
