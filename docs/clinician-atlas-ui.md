# Clinician atlas interface and public exports

The atlas supports clinical-name and exact-code search, readable source names,
source-field discovery, and reference definitions for selected coded values.
Selected weight/height, BMI and haemoglobin shortcuts link exact source/field
identities to available summary statistics and source coverage. These are not
complete inventories of every laboratory measurement or harmonized results.

The HTML template remains `inst/templates/DALYCARE_atlas.html`. The native R
writer in `R/html.R` embeds the committed reference dictionaries, applies the
disclosure filter, and writes equivalent JavaScript and JSON payloads. The
offline Python builder applies the corresponding filter to an existing export:

```sh
python scripts/build_ui_iteration.py --input-dir /path/to/existing/site --output-dir /path/to/new/site
```

Both input and output directories must be supplied explicitly. Input requires
`DALYCARE_atlas_payload.js`. The generated HTML and payload script
must remain together for offline use. This build does not query a database.
Do not confuse intermediate run CSVs with guarded public release artifacts.

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
  separate from observed category distributions.

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
```

Native R checks for the writer, shared synthetic privacy fixtures and startup:

```sh
Rscript tests/test-html-payload.R
Rscript tests/test-public-privacy.R
Rscript tests/test-atlas-startup-runtime.R
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
