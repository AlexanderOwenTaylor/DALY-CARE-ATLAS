# Clinician atlas interface and public exports

The atlas supports clinical-name and exact-code search, readable source names,
source-field discovery, and reference definitions for selected coded values.
Selected weight/height, BMI and haemoglobin shortcuts link exact source/field
identities to available summary statistics and source coverage. These are not
complete inventories of every laboratory measurement or harmonized results.

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

The main search matches table IDs, names, file paths, source terms and supplied
column meanings. It does not scan table rows. With a search term entered, the
explicit field-row and reference-definition actions carry that term into the
selected table without retyping. These actions do not promise a match. Exact
names and source languages may differ; English search is not exhaustive bilingual
mapping. Typing replaces the current search state, while task choices, paging,
table opening and whole-table searches remain meaningful browser history entries.

Frequently used field, dictionary, source and coverage tables have a reading
view that keeps exact source identity, supplied counts/denominators, units where
provided, and interpretation details together. On narrow screens each result
becomes a vertical row card. Show all exact columns restores the original schema;
whole-table search always covers every approved column, including columns not
shown in the reading view. Source lineage, full row meaning, original scope and
column definitions remain below the rows. No new statistics or units are inferred.
Reading views group counts and round percentage/statistic displays, while keeping
exact values in titles and the exact-column view. Coverage percentages retain
their source-specific denominator, and domain totals repeated across regions are
explicitly marked as nonregional totals that must not be summed across regions.

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

The local iteration9 build was reviewed in desktop and mobile browsers, including
measurement discovery, unit provenance, source coverage, keyboard controls and
route restoration. That visual acceptance does not certify all accessibility or
clinical interpretation requirements. No whole-project R-suite success is claimed.

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
shard data with one active table read. Browser heap overhead is additional. Home
and direct-library initial assets have a 512 KiB build ceiling; opening Clinical
explorer still loads its full, deduplicated clinical core.

The current package `DESCRIPTION` lacks a maintainer email, so untouched-source
`R CMD INSTALL` fails metadata validation. The installed-resource acceptance
test installs a temporary copy with a synthetic test contact; it verifies shipped
assets and project-resource preference, not production package-install readiness.
The source one-click, CLI and offline rebuild workflows do not require installation.
