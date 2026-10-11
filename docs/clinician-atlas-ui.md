# Clinician atlas interface and public exports

The atlas supports clinical-name and exact-code search, readable source names,
source-field discovery, and reference definitions for selected coded values.
Home leads with eight clinical topic groups, including diagnoses, treatment,
hospital contacts, laboratory data, microbiology, imaging, pathology, samples,
molecular sources, vital signs, social history and notes. Measurement examples
remain available below this broader inventory. They are not complete inventories
of every laboratory measurement or harmonized results.

The clinical template remains `inst/templates/DALYCARE_atlas.html` and is emitted
as `DALYCARE_clinical.html`. Home (`DALYCARE_atlas.html`) and Data tables
(`DALYCARE_outputs.html`) have light independent assets. The R one-click and CLI
runners write CSVs plus saved context, strictly reconstruct the clinical payload,
and publish the pages, typed table catalogue/shards, and matching JSON/JS core.

For an exact offline rebuild of a new run, without the original source connection:

```sh
Rscript scripts/rebuild_atlas_from_outputs.R /path/to/run /path/to/project
```

Keep the saved context and all bound CSVs, including supplemental and imported
selected-count files. Required errors fail the staged build and preserve the prior
site/manifest pair. Optional missing, header-only, incompatible and unreviewed
artifacts have distinct catalogue states. Explicit project resources beat installed
package fallbacks. The internal manifest enumerates inputs and published assets.

An older export without saved context uses snapshot migration:

```sh
python scripts/build_ui_iteration.py --input-dir /path/to/existing/site --output-dir /path/to/new/site --run-dir /path/to/matching/run
```

The clinical core remains a labelled legacy snapshot; matching registered CSVs
supply individual table evidence. Omit `--run-dir` for limited snapshot-only table
previews with unknown original counts. Neither mode queries a database.

Double-click Home or serve the entire `site/` directory over HTTP. Keep all pages,
scripts, styles and `output-shards/` together. Internal run CSVs are not public
release artifacts and must not be linked or hosted with the site.

## Clinical explorer

Start offers twelve clinical topics, registry and molecular-field routes, and
collapsed measurement examples. Six primary sections keep
registries, clinical data, treatment, laboratory data and source fields close to
hand. More sections retains the other destinations; existing deep links and the
mobile section selector remain supported. Export metadata and technical guidance
are secondary details.

Domain pages show exact current source inventories even when curated panel
mappings are absent. Source cards distinguish diagnoses from contact-linked
diagnoses, microbiology workflow layers, full procedure sources from imaging
events, coded pathology from text availability, and samples from assays. Counts
describe individual source records and are not added across overlapping views or
presented as people. Declared aliases do not duplicate an unprofiled source;
separately profiled identities remain visible. Existing published summaries remain
available beside the source overview, including registry imaging and Ki-67 coverage.

Clinical fields opens compact, full-width source details with readable names,
availability or a withholding reason, and exact field-evidence links. Browse all
source fields preserves access to the complete inventory. Exact field journeys
hide unrelated measurement shortcuts; selected date-field availability links
retain both the date field and source. The explicit domain inventory is curated:
the complete catalogue remains the route to sources not mapped to a topic.

Field cards show the exact source and field beside the readable name, records
with a value, usable numeric summaries or the reason they are unavailable. A
recorded/total statement uses an explicitly supplied compatible total; it does
not reconstruct suppressed counts or estimate people. Small positive percentages
and incomplete recording remain distinguishable from zero and 100%. Full source
coverage is linked once from each field rather than repeated as tables inside
its summary. The destination retains the exact source.

Vitals links to the available weight/height and BMI field profiles with their
source names. These are separate from SP vital-event aggregates. Laboratory
reference results show supplied specimen/system and terminology units before
selection. Those definitions do not establish which tests were observed or
validate the units in a source. Where observed summaries are withheld, the page
explains that limit and offers source fields, source coverage and reference
definitions as separate actions.

Registry numeric cards retain configured panel units as explicitly configured
metadata. An absent field-profile unit stays absent; no unit is copied between
the two outputs. Withheld statistics receive a readable reason and an exact
field-evidence link. Treatment source groups distinguish administrations,
prescriptions, plans, national medicine, registry indicators and procedures.
Known identities and declared aliases determine these groups; uncertain or
conflicting identities remain candidates.

Global search retains its query after opening a result, with a control to show
the results again. Exact source/field selection, search terms and supported
laboratory, reference and measurement filters remain in the route for refresh and
browser history. Catalogue domain/status/role and field domain/kind filters are
not encoded in the route. Hidden technical panels render on demand;
direct links and printing retain their content. Clinical explorer still downloads
the complete clinical core. Reduced initial rendering does not reduce its payload
transfer size or establish a deployment latency guarantee.

## Coverage and Data tables

Coverage over time shows readable counts grouped by exact source, selected date
field and evidence basis. The local table scrolls horizontally; select a source
for its year tables. Missing years, zero, withheld counts and duplicate evidence
remain distinct. Source totals are under a collapsed section. Date availability
uses nonmissing records in the selected field, not date validity or complete
follow-up. The evidence links open the existing Data tables library.

Coverage by place includes a native Region selector for keyboard use and compact
source-count details. Direct and streamed region shares use all source records;
registry-region shares use retained mapped-region counts. Map share has its own
supplied mapped Myeloma registry denominator. Unknown percentage bases are not
shown. Source status describes loaded-source metadata or recorded-region evidence.
The recorded-region evidence table also includes supplied unmapped categories.

Data tables starts with four tasks: Fields and summaries, Sources, Years and
regions, and Code meanings. These use reviewed exact table identities. All
outputs retains the complete inventory, including technical context and outputs
without published rows, in pages of twelve entries. Run and publication details
offers the remaining technical inventory. A published file is not a promise of
clinical usefulness: source-only or domain-only projections are labelled Context
only before opening.

In Fields and summaries, submitting the primary search opens matching published
field profiles directly. This search matches field names and reviewed field
labels, excluding incidental matches in source labels or numeric values. The
visible search mode survives URL restoration; users can switch to searching all
published row values. Other inventory views search table IDs, names, file
paths, source terms and supplied column meanings; their explicit field-row and
reference-definition actions carry the term into a table without retyping.
These actions do not promise a match. Exact
names and source languages may differ; English search is not exhaustive bilingual
mapping. Typing replaces the current search state, while task choices, paging,
table opening and whole-table searches remain meaningful browser history entries.

Years and regions opens a source overview with a searchable source selector.
The initially selected Myeloma registry is labelled as an example. Reviewed names
and exact identifiers find sources; all current source-inventory entries remain
selectable. Exact source links override conflicting discovery terms; an absent
source retains its requested identity and is reported as absent from the export.
Source totals, availability of the selected date field, annual counts
and regional counts appear together. Years and regions remain independent
summaries, grouped by exact source, field and count basis. Shared explanations
appear once per group. Duplicate entries retain their separate supplied values;
inferred date ranges do not become recorded years. Sources without annual or
regional summaries receive an explicit explanation, not spelling advice or zero
counts. Read failures do not become absence claims.

Field profiles and source details link to the same source's coverage. Evidence
links carry exact source and date/region field filters. Original tables and
geographic reference context remain accessible below the overview. A secondary
hospital-field search explicitly searches across sources; it does not promise
hospital names, counts or hospital-specific coverage. This view reuses 25 reviewed
date/region field labels and existing source labels without loading a dictionary.

Frequently used field, dictionary, source and coverage tables have a reading
view that keeps exact source identity, supplied counts/denominators, units where
provided, and interpretation details together. On narrow screens each result
becomes a vertical row card. Show all exact columns restores the original schema;
search in all-row-values mode covers every approved column, including columns
not shown in the reading view. Source lineage, full row meaning, original scope and
column definitions remain below the rows. No new statistics or units are inferred.
Reading views group counts and round percentage/statistic displays, while keeping
exact values in titles and the exact-column view. A value below 100% that would
round to 100.0% is shown as less than 100%, rather than implying complete recording.
Coverage percentages retain
their source-specific denominator, and domain totals repeated across regions are
explicitly marked as nonregional totals that must not be summed across regions.

Myeloma, lymphoma and CLL category outputs open as field lists. Identical rows
whose category, count and share are all withheld pending validation appear once
in the reading view, with a shared explanation. Additional restrictions remain
beside the affected field. Different evidence and any supplied values, including
zero, stay separate. The exact view retains every published row. Grouping is
limited to the loaded page; it does not estimate category counts or recover
withheld distributions.

The registry views reuse 42 reviewed source/field labels from the clinical dictionary
(27 category fields and 15 myeloma numeric fields). The same exact-pair labels
and reviewed source aliases support searches in field profiles and field
metadata. Unknown fields keep their exact names. The compact map needs no extra
dictionary download and is not a complete translation of the atlas.

Inspect field availability opens field profiles with exact `source` and `field`
URL filters. Both identities must match; another source's similarly named field
cannot supply the answer. The visible scope can be cleared and survives browser
history. A missing match is reported explicitly. Myeloma numeric coverage groups
common known reasons for absent summaries, while keeping availability and units
beside each field. Unknown reasons or supplied summaries use the full reading
view, and the original columns remain available.

Category summaries retain bounded/top-N qualifications, registry ID counts may
be bounded or fall back to records, and dictionary counts describe reference
entries rather than observed tests. A no-match reference search means no matching
definition was supplied in this export; it does not establish code validity.

## Interpretation

- A readable field name or reference code definition does not establish observed
  values, a complete codebook, a positive finding, or measurement availability.
- Means and quartiles describe supplied source records. Quartiles may use samples;
  units and source cleaning are not independently validated.
- A unit in an exact field name is labelled as such. Missing unit metadata is not
  inferred from another source's field or from a related code definition.
- Source year counts use the named date field, which can be a contact or diagnosis
  date. They do not establish measurement dates or measurement completeness.
- Regional summaries describe the recorded source field, not necessarily residence.
  They do not establish completeness by measurement, region and year.
- Missing, withheld and zero counts are distinct. Reference definitions remain
  separate from observed category distributions. Table cells show their applicable
  suppression or validation reason; unrelated missing cells remain missing.
- Table kind, row meaning and evidence origin distinguish aggregate summaries,
  field metadata and reference definitions. Common observed values and laboratory
  code frequencies remain withheld under the current policy; source-field context
  and reviewed definitions do not establish observed result availability.
- Inferred source date ranges are collapsed to one neutral row per source/date
  field/basis. Their years, counts and original cardinality are withheld, including
  copied temporal summaries and inventories. Recorded and streamed year aggregates
  keep their existing count guards. Regional domain totals must not be summed
  across reference regions or treated as region-specific patient counts.
- Search covers the selected published rows. Limited snapshots do not recover
  omitted original rows, and failed/cancelled scans report incomplete search.

## Disclosure controls

`R/public_privacy.R` and `scripts/public_privacy.py` filter the serialized payload,
including copied branches. The minimum cell threshold cannot be less than five;
higher configured thresholds remain supported. The filter removes exact numeric
extremes, exact clinical date bounds, identifying/text values, unvalidated observed
categories and code frequencies, small and complementary counts, and unsupported
numeric summaries. `config/public-measurement-policy.csv` is an exact source/field
allowlist; eligibility also requires the accompanying support and quality checks.
Negative sentinel evidence causes withholding rather than silent recalculation.

Protection of underlying values and suppression of counts have separate metadata.
Source-count displays respect count-specific suppression while retaining aggregate
year counts already released by the filter. Generic protected category displays
remain withheld. No individual records or row previews are emitted by this UI.

The controls are conservative release filtering, not certification of population
anonymity. Source-record counts do not prove distinct-person support or rule out
uniqueness through external linkage.

## Validation

Default JavaScript and Python checks use synthetic data and committed public
reference definitions. They must run without local atlas releases or database access:

```sh
node --test tests/*.js
python tests/test-ui-export.py
python tests/test-public-privacy.py
python tests/test-output-evidence.py
python tests/test-site-bundle.py
```

Native R checks for the writer, shared synthetic privacy fixtures and startup:

```sh
Rscript tests/test-html-payload.R
Rscript tests/test-public-privacy.R
Rscript tests/test-atlas-startup-runtime.R
Rscript tests/test-iteration10-pipeline.R
Rscript tests/test-site-bundle.R
Rscript tests/test-output-evidence.R
```

Other relevant regressions include laboratory/imaging identity, semantic-code
translation, semantic presentation, and treatment-panel separation. Windows R
may need a UTF-8 locale and the local package-library path. `jsonlite` is needed
for the shared privacy-fixture test. Optional export-to-export tests and search
benchmarks require explicitly supplied local exports; these data are not committed.

The iteration16 review used researcher (X1), clinician (Z3), older-static-atlas
comparison (W0) and developer (Y2) roles. The comparison recovers navigation and
supported source structure, never historical statistics. Browser checks cover
desktop and offline phone use, exact source/field and coverage links, keyboard
controls, all existing section routes and print rendering. Independent code review
identified availability-withholding and partial-panel fallback defects; regression
tests cover sanitized and retained suppressed counts, registry-only imaging and
incomplete optional panel metadata. These bounded checks do not certify every
atlas section, accessibility requirement or clinical interpretation. No whole-project
R-suite success is claimed. The synthetic one-click, CLI and offline rebuild pipeline
was exercised, including rollback and installed-resource precedence.

### Optional local export checks and benchmarks

Historical export-to-export checks are optional. Set
`DALYCARE_TEST_ORIGINAL_EXPORT` and `DALYCARE_TEST_UPDATED_EXPORT` to directories
containing `DALYCARE_atlas_payload.js`; the updated directory must also contain
matching `DALYCARE_atlas_payload.json`. To run every historical comparison, also
set `DALYCARE_TEST_ITERATION5_EXPORT` and `DALYCARE_TEST_ITERATION7_EXPORT` to their
corresponding export directories. Any existing JSON file must match its JS payload.
Missing optional inputs produce informative skips; explicitly supplied malformed,
missing, unsafe updated, or mismatched files fail. Run `python tests/test-ui-export.py`.

Run search benchmarks with:

```sh
node tests/benchmark-search.cjs /path/to/DALYCARE_atlas_payload.json
```

Alternatively, set `DALYCARE_BENCHMARK_PAYLOAD` to an explicit JSON/offline-JS
payload path. A second CLI argument can select an HTML template. No export is
loaded by default, and data exports must remain local.

The integrated iteration10 test executes real one-click, standalone CLI and offline
R rebuilds against committed synthetic sources; checks a CSV sentinel in the core
and public table, required-input publication rollback, optional/header-only states,
complete manifests/build versions, range-cardinality suppression, and installed
resource inventory/preference. It does not connect to the production database.
Final real-bundle browser/heap benchmarks and independent release review are
separate local acceptance steps; generated data, screenshots and ZIPs stay out of Git.

Default pre-read/public table-data budgets are 64 MiB each, configured through
`DALYCARE_ATLAS_INPUT_MAX_BYTES` and `DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES`.
Catalogue limits expose the effective budget and disclosure threshold. Each table
part is limited to 250 rows and 256 KiB of both serialized rows and finished script;
50 rows are visible per page. The runtime retains at most 1 MiB of serialized-equivalent
shard data with one active table read. The source coverage overview sequentially
reads only the source inventory, date availability, annual counts and regional
counts. Its retained snapshot has separate limits of 512 KiB of serialized rows
and 2,048 rows; oversize exports show an explicit limitation with links to the
original tables. It does not preload field profiles, dictionaries or the clinical
core. Source changes reuse the completed bounded snapshot. Browser heap overhead
is additional. Home
and direct-library initial assets have a 512 KiB build ceiling; opening Clinical
explorer still loads its full, deduplicated clinical core.

The current package `DESCRIPTION` lacks a maintainer email, so untouched-source
`R CMD INSTALL` fails metadata validation. The installed-resource acceptance
test installs a temporary copy with a synthetic test contact; it verifies shipped
assets and project-resource preference, not production package-install readiness.
The source one-click, CLI and offline rebuild workflows do not require installation.
