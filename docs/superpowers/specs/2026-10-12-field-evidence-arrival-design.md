# Exact field evidence arrival — iteration21 design

2026-10-12. Approved by root under the user's continuing iterative-work authorization.
Base is accepted transport20 checkpoint `b850a14bb515be70bfcc141473898928c7ad5208`.
X1 researcher,
Z3 clinician and W0 V33 comparison critiques agree on the problem; Y2 feasibility
review supplies the state/DOM constraints. Their local reports are under workspace
`.artifact-temp/iteration21-team/`. No user permission is pending. Implementation
follows the accompanying plan after its bounded independent design review; this
approval does not establish render acceptance.

## Outcome and boundary

After choosing an exact field in Clinical explorer, immediately see the readable
field name, exact source and key, recorded availability and stored-summary status.
The saved390x844 response arrival currently starts its field row aroundy705 after
generic copy and table controls. Recover V33's compact factual hierarchy without
old statistics, distributions, privacy decisions or monolithic loading.

Choose conditional presentation inside the existing Data tables reader. Activate
only for `column_profiles` with nonempty exact `rowScope.source` and `rowScope.field`,
including loading, no-match/error and copied URLs. A source-only/field-only/unscoped
arrival keeps the ordinary table workflow. A CSS squeeze cannot fix title/state
ambiguity; a separate page/aggregator adds routing and evidence reconciliation
outside this need. No source mapping, code translation, registry19, R/Python,
catalogue/shard schema, cache/scanner, publication or transport change belongs here.

Production ownership: `inst/templates/atlas-outputs.js`, `DALYCARE_outputs.html`
and locally scoped `atlas-pages.css`; focused browser/navigation tests as needed.
Use the already accepted exact label catalogue and source-name lookup. Unknown
identities remain raw. Do not trim/normalize equality keys or infer a clinical
meaning from a substring. A dictionary label identifies the request, never creates
an observed profile. No additional Clinical core/dictionary download.

## Reading order and interaction

Use one real heading with the reviewed field name or exact key, then readable
source where known and exact source/field identifiers. Hide the generic heading
purpose and redundant field-summary badge in this mode; do not add a second hero.
The DOM and visual order are: heading/identity; concise publication qualifier and
live read status; all returned profile rows and pagination; source onward links;
optional table tools; provenance and column definitions. Reading facts precede
empty search/exact-column controls. Keep normal font sizes and44px primary controls.

Each profile has clearly labeled Recorded availability and Stored summary areas,
side by side on desktop and sequential on a phone. One concise count qualification
states source records, not people or clinical reference ranges. Keep row-specific
withholding/method/scope reasons with the row. Consolidate rounding copy beside
exact-column tools. Avoid charts, computed KPIs and repeated identity in every
single-row cell. Every profile still retains its exact field/source relationship.

Move actual nodes, never duplicate IDs/forms or use CSS-only order. Do not put the
entire existing `row-controls`/`search-table` in a closed details element: status
and Cancel currently live there. Status, Cancel, Retry and paging must remain
visible independently of the tools disclosure. Restore controls to their normal
slots when leaving field mode. Preserve one live status region and escaped output.
Native disclosure/links/buttons need visible focus including summary:focus-visible.
Opening focuses the field heading; progress/completion must not steal focus.

Tools initially open for an applied nonempty query, `searchmode=fields`, or
`columns=all`. A compact applied-query/mode/exact-view indicator remains visible
even if the user closes tools. Direct columns=all renders exact columns immediately,
with raw column keys beside reviewed headings; fixtures must include distinct
labels and keys. Exact view remains the same scoped published rows, without a
rescan for a presentation toggle. Long IDs wrap; grid overflow is contained.

Keep draft input separate from the applied query. At open/restore/submit or a mode
change, set the applied query used for scan, result copy and URL serialization.
Capture query/mode/page/scope at read start. Merely editing an unsubmitted input or
toggling presentation must not relabel current results or save a query never run.
This bounded state correction applies consistently where the shared handlers need
it; ordinary submitted-search behavior stays intact. No scanner API change.

## Evidence contract

Render page rows in existing order, with no grouping, deduplication, summation,
first-row preference or cross-table fill. For multiple profiles show the total
matching published profile rows, page range, and result-row ordinals. An ordinal
identifies its position in this ordered result, not a persistent cohort/profile ID.
Keep supplied domain/subdomain/atlas_role/profile_kind and summary metadata with
each row. Say Summary scope not supplied where absent; do not invent cohort/time
scope from these fields. Identical duplicate rows also stay distinct.

Availability consists of independent supplied n_available, pct_available,
n_missing, pct_missing and n_rows. Show permitted supplied missingness directly.
Never compute complements, shares, people, support or totals across rows. Zero is
supplied; null/absent is not zero. Use existing publication-reason mappings for
guarded null metrics; unknown nonempty reasons remain visible as supplied status.
One shared reason may replace repeated nulls only when it cannot hide any supplied
availability/missingness metric. A source total is independent of recorded count.

Stored summaries retain supplied mean/median/quartile values including zero and
partial summaries, or the actual withholding/missing reason. Name the object:
Stored summary not shown, rather than an unqualified Not shown. Keep supplied
summary scope/method/caveats even when numeric values are absent or the profile is
categorical, labeled as supplied metadata; it must not imply an observed category
distribution. Do not borrow units from another output. No new statistics, modes,
extrema, dates, value categories, raw free text or clinical inference.

Three independent facts must never substitute for each other: completed scan
(`result.complete`), complete/limited approved export (`selected.complete`), and
each stored summary's `summary_scope`. A complete scan of limited evidence remains
limited. Earlier snapshot origin retains its visible qualifier. Keep full source
file/run/origin/row-grain/count-basis/schema details in existing disclosures.

## Required states and routes

- Loading/progress: requested identity, visible status/Cancel, no stale profiles,
  count or absence conclusion. Error/cancel: incomplete-read message and Retry;
  late old requests cannot paint new evidence. Retain existing epoch/abort rules.
- Completed unqueried zero-match scan: no published profile rows found for this
  exact pair in this export. This is not upstream absence or zero availability.
  Preserve requested identity/source links; never create a dictionary-only card.
- Applied-query zero match: no published profiles match the displayed query within
  this exact field. Clear search retains pair/mode/columns/coverage return context,
  resets page and executes the read. Do not claim unfiltered profiles exist/count
  unless actually known; no second hidden scan to obtain that count.
- Page beyond results: no profile rows on this page plus matching total and First
  page action. Preserve URL until explicit action; First page retains all scope,
  applied query/mode/columns and rescans. Do not silently clamp or call pair absent.
- Unreadable/unpublished/empty table: retain its actual publication state/reason
  and origin, without implying a successful scan or manufactured observations.
- Multiple/paged profiles: every retained row remains reachable, including duplicate
  rows; no sum or guessed scope. Partial metric/summary values remain partial.

Use ordinary exact-source anchors after evidence: Browse fields in this source
opens `?view=fields&table=column_profiles&source=<source>`, deliberately dropping
field-specific query/mode/page/columns and unrelated list filters. Native Back
restores the prior field URL. Years and regions opens `?view=timeplace&source=<source>`
as source-wide context, never field-specific or joint year-region coverage. Keep
incoming view=timeplace/returnsource and existing Back-to-tables behavior. Do not
guess a registry return link; browser Back preserves the accepted registry theme.

Refresh/copied URLs/history preserve source, field, applied search, searchmode,
page, columns and supported coverage-return context. Broader scope clearing remains
an explicitly labeled optional action. Source-only ordinary browsing must work
after leaving specialized mode without stale heading or hidden controls.

## Verification and acceptance

Focused behavior tests execute the shipped runtime with synthetic publication
fixtures. Cover exact-pair decoys/unknown and label-only identities; deliberately
noncomplementary supplied missingness to expose invented arithmetic; zero/null/
guarded/unknown reasons/partial stats;52matching rows with duplicate rows and
different/absent metadata; applied versus draft query, zero-match Clear search,
page999 First page, exact grid raw keys, history/refresh/scope transitions; partial
read failure/cancel/retry/stale registration and limited/snapshot/unreadable states.
Observe values, membership/counts, URL, reads, status/focus, not copied helper text.
Retain reader cache/row/byte/privacy checks; do not recreate unchanged transport
tests. Extend fake DOM minimally where node movement needs it; it cannot prove
layout, real keyboard/disclosure behavior or accessibility.

Build candidate21 only from accepted20/matching run after source review. Compare
every guarded core value and all147table descriptors/28802published rows; no data
change is intended. Check catalogue, Home/Clinical HTML and Clinical core/runtime
remain unchanged; shared CSS may change within existing initial-asset budgets.
Use actual localHTTP and double-click offline at390x844 and1280x900. Representative
response, treatment and newly mobile stage arrivals must show readable identity,
availability and summary/status before optional controls in the first screen.
Do not hide material qualifiers or shrink text to meet that target; very long
labels/multiple profiles/active searches need correct order, wrapping and reachable
evidence rather than an unconditional all-above-fold promise.

X1 inspects researcher evidence/states, Z3 native phone interaction and wording,
W0 compact hierarchy/retained table context against reference strengths. Y2 fresh
independent code review challenges implementation/guards/state transitions. Root
checks complete data parity, tests and actual pixels. Exact-grid contained scrolling,
44px controls, keyboard details/links, query visibility, source onward links and
native Back/refresh require rendered evidence. If print styles change, verify the
scoped page in print; do not claim global print improvements from CSS inspection.
No database query, new codebook or whole-atlas usability/anonymity certification.
