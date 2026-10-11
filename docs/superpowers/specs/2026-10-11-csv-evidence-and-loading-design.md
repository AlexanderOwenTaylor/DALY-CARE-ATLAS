# DALY-CARE Atlas: CSV contents, reliable builds and bounded loading

Status: approved and implemented for iteration 10. Integrated synthetic acceptance is recorded in Task 4; final real-bundle browser/benchmark acceptance, independent whole-branch review and release packaging remain delivery gates. Production database access remains unverified.

## Intended outcome

A clinician can find a generated data table by a familiar clinical term, exact source/field name or CSV filename; understand what its rows and columns mean; and browse every approved row without loading the whole atlas. The DALY-CARE R runner must produce the CSV evidence and the matching HTML, JavaScript and JSON assets in one verified build. Rebuilding from an existing run must not require querying the database.

The user explicitly requires both double-click offline use and web hosting. Existing clinical routes, translations and privacy rules remain supported. The clinician/audience team and the technical/data-management team have independently audited the current implementation and critically appraised each other's proposals.

## Verified starting point

- The current guarded JSON is 7,310,642 compact bytes. A read-only experiment removing exact repeated arrays produces an illustrative 4,577,805-byte envelope; this is a sizing experiment, not an implemented optimization or browser timing result.
- The technical team independently verified 18 repeated infrastructure arrays occupying 2,380,972 bytes. Narrow, explicit aliases can remove these copies with less risk than a general graph compressor.
- The selected run contains 133 direct output/panel CSV files, about 3.49 MB. Unrelated nested analyses in the supplied archive are outside scope.
- Two laboratory-code CSVs each contain 5,191 rows, while generic panel serialization caps at 250 and the generic UI table renderer displays at most 100. Displaying all rows remains subject to disclosure rules; a code occurrence does not automatically qualify for publication.
- The actual R runner's existing six-source synthetic fixture test passes. Production database access and production-scale performance have not been tested.
- The R runner writes and rereads most CSV outputs, but missing or unreadable files can silently fall back to in-memory data. The Python helper rebuilds from an existing payload, not from CSVs. The site writer creates JSON but does not include its path in the final output manifest.
- A source-checkout run can prefer an older installed package's HTML template. This must be corrected to avoid mismatched data and UI versions.

## Approaches and recommendation

1. **Recommended: a small entry page, an independent Data tables page, and a separate Clinical explorer.** Table browsing never loads the large clinical payload. Existing deep links still open the appropriate clinical view. The clinical payload also loses verified exact duplicates. This provides a substantial initial-load reduction without rewriting every clinical renderer.
2. Keep the current entry page and only deduplicate its payload, adding an independent table page. Lower navigation risk, but the default entry still eagerly loads roughly 5 MB. The technical team prefers this narrower change; it does less to meet the user's emphasis on loading.
3. Convert every clinical module to an asynchronous dependency graph. This offers more granular loading throughout the explorer, but touches eager constants, search indexes, diagrams and many route consumers. Defer this broad migration until the new loading contract and measurements are established.

The recommended option preserves clinical questions as prominent one-click destinations. It does not hide them behind administrator terminology or call the existing experience “legacy.” Its remaining trade-off is explicit: entering Clinical explorer still loads its compact core; a fast entry page does not prove every clinical route is fast.

## User experience

`DALYCARE_atlas.html` remains the opening filename. With no existing clinical fragment it displays lightweight clinical question cards, Browse data sources, Browse data tables, and Clinical explorer. It loads only a small approved run summary and navigation metadata. Existing clinical fragments delegate to `DALYCARE_clinical.html` with the fragment preserved; browser back/forward must not loop. All assets use relative URLs.

`DALYCARE_outputs.html` presents **Data tables**, with the subtitle “Published representations of CSV outputs.” Search covers approved titles, filenames, source identifiers, readable source names and column names. Group and availability filters narrow compact results. Opening a result displays one table, its purpose, what one row represents, and 50 rows at a time. Returning preserves filters and position. Contextual links return to the originating clinical/source view when supplied; direct links have a known default return destination.

Existing Panels navigation links to this library instead of maintaining a competing unpaginated inventory. A fixed route map sends old `#infrastructure/infra-panels` links to the library, translating the validated saved panel-group state and retaining supported search state. Known clinical/source/field routes preserve their exact identifiers and query parameters in the explorer. Unknown routes return to the light entry with a readable message rather than being interpreted as asset paths. Compatibility delegation replaces the current history entry so back/forward cannot loop. Clinical source-field discovery remains the primary interpretation layer; exact identifiers are retained alongside readable labels.

The table detail separates:

- Kind: Aggregate summary, Field metadata, or Reference definitions.
- Availability: Available, Empty output, Metadata only, Not produced, Could not load, Snapshot preview, or Status not supplied, according to evidence.
- Scope: original output row count when approved and known, represented row count, and the range currently displayed. These are file/table rows, not people.
- Completeness: “All approved output rows are available” or a precise limited/snapshot explanation. Never show an unqualified “Complete” badge.
- Values withheld: retain null plus a readable reason; distinguish it from a true zero or an empty file.

A collapsed **Column meanings** section lists readable heading, exact CSV key, type, and reviewed definitions, units, denominator and scope when supplied. Unknown meaning is explicitly not supplied; no inference from similar column names. Reference definitions never imply observed test availability or observed value frequencies.

## Authoritative CSV handoff

Introduce an explicit versioned registry of known artifacts, schemas, required/optional status, public projections, original guard paths and reviewed column meanings. A filename match alone is not publication approval. Inventory discovery uses the validated run manifest and CSV files directly in the selected run's `outputs/` and `outputs/panels/`, with normalized paths constrained to that run; it does not recurse into other directories. The registry controls publication, not discovery. Unknown entries are accounted for through safe generic metadata entries or a labelled unreviewed count, without exposing their names or headers.

Factor CSV rehydration into one R function used by both `run_atlas()` after writing outputs and an offline `scripts/rebuild_atlas_from_outputs.R` entry point. Save the small non-tabular build context required for deterministic reconstruction, such as run identity and controlled module configuration. It must contain no patient rows, credentials or raw narratives. Required artifacts must exist, parse and match schema; otherwise fail clearly without silently using memory or stale JavaScript. Missing optional artifacts remain explicitly unavailable.

Known CSV changes must reach the rebuilt public table and corresponding clinical payload when that artifact feeds it. Preserve identifiers and codes as strings, including leading zeros; honor explicit numeric types and missing values. Do not infer clinical measurements from generic numeric-looking text.

An older run that lacks the new build context must not be presented as an exact reproducible new-format run. Support an explicitly labelled migration mode: its existing guarded payload supplies the clinical snapshot, and approved original CSVs can supply the new table library with per-table provenance. No omitted rows are claimed restored when only the old payload exists.

The Python helper remains an explicit snapshot rebuild tool; it must support the new bundle contract without claiming to reconstruct R-derived clinical summaries from CSVs. It accepts an optional explicit run directory for table evidence; that input follows the same registry, path checks and guards as R. Without it, table provenance is snapshot-only and original CSV counts/completeness remain unknown. R is the authoritative full CSV reconstruction path. Python must not silently depend on an R installation.

Prefer a valid explicit source project's templates/resources over installed-package fallbacks. Package installations must include the required new templates, runtime and registry. Stamp and validate the schema, build and runtime versions.

## Publication boundary

Publish only reviewed metadata, reference definitions and aggregate representations. Never provide direct links to internal raw CSVs. Individual records, identifiers, narratives, exact clinical dates/extrema, rare observed categories and unsupported summaries remain protected by the existing disclosure policy.

Apply the disclosure filter to whole logical tables at their established payload paths, with all necessary profile context, **before** filtering, deduplication, pagination or sharding. Small-cell and complementary suppression must span future page boundaries. Then audit the resulting representation. Only that representation is eligible for browser assets or exports.

Unknown artifacts and optional/library-only changed schemas default to metadata only or unavailable. A missing, malformed, oversized or schema-incompatible required clinical/build input instead fails the staged build; it cannot be downgraded to metadata-only to publish a seemingly complete clinical site. Public catalogue metadata itself uses a safe projection: controlled identifiers, approved filenames/titles and only reviewed schema/counts. A synthetic identifier in an unknown filename, header or body must not escape into the site. Unreviewed metadata is represented by a generic controlled entry; internal diagnostics retain its mapping. Do not expose the internal manifest's absolute paths or arbitrary text.

Initial coverage includes reviewed source/field catalogues, field profiles, semantic/reference dictionaries and registered existing aggregate panels. Each schema must be assessed; the catalogue can account for more artifacts than it is allowed to display. It must state that difference plainly. A table may represent every approved row while still withholding some or all observed-value cells.

## Files and loading contract

The public site contains the light entry, Clinical explorer, Data tables, a small entry bootstrap, a versioned public catalogue, and content shards under a relative data folder. JSON versions support inspection/interoperability; classic JavaScript registrations support browsers opened through `file://`. No fetch-only loader, ES module requirement, service worker or external CDN is allowed for normal use.

Each table catalogue entry records a controlled id, title, source file, kind, availability/reason, row grain, approved counts, represented scope, reviewed columns, provenance and shard descriptors. Each shard registers its schema/build/table/shard identity and rows. Accept only paths in the catalogue, reject identity/size mismatches, coalesce identical requests, bound the cache, remove completed script elements, and ignore stale responses. A load failure offers Retry and instructions to keep the HTML and data folder together; it must not masquerade as an empty dataset.

Initial engineering limits, to be validated rather than advertised as measured performance:

- At most 250 rows and 256 KiB serialized UTF-8 data per shard; 50 visible rows.
- At most 1 MiB serialized-equivalent retained shard cache, with a single active table read. Browser heap overhead is separately measured.
- Whole-table search scans only the selected published table, one shard at a time, yielding progress and supporting cancellation. Keep a running match count and only the requested result page; re-scan for later pages when necessary. Never concatenate a whole large table merely to paginate it.
- “No matches” appears only after a successful full scan. Failure/cancellation says search incomplete. A match in the last shard must be findable.
- Export, if provided in this iteration, is **Export this published page**. It includes only displayed approved rows and neutralizes spreadsheet formula execution. No ambiguous all-results download.
- Light-entry and direct table-library initial assets target at most 512 KiB each on the supplied run; neither loads the clinical core or table rows before needed. If the catalogue exceeds the budget, page its metadata or fail clearly rather than hide entries.
- Build-time limits must be explicit. Start with a 64 MiB public table-data budget and a 64 MiB pre-read limit per input file, configured and reported by the builder. Oversized optional inputs/rows produce an explicit unavailable table; oversized required inputs fail the staged build. Neither causes unannounced truncation. This iteration does not claim arbitrary gigabyte-input streaming support.

Use fixed, reviewed aliases for exactly equal repeated clinical arrays. Sanitize/audit the full logical payload first, deduplicate second, and hydrate before existing captured constants/indexes. Validate alias destinations and targets; no arbitrary path traversal or cycles. JSON and JavaScript use the same transport version and decode to the same logical payload. Target at least 25% smaller serialized clinical core on the supplied run; measure the actual result and subsequent Clinical explorer load cost.

Generate a complete site in a staging directory, validate its assets, then publish it as a consistent build while retaining the previous usable site if publication fails. Build identities prevent mixed-run assets being accepted. Extend the internal output manifest to cover HTML, JSON, JavaScript, catalogue, runtime and every shard, with existence, byte counts, version/provenance and table completeness where appropriate. Do not publish that internal manifest verbatim.

## Acceptance and opposing-team review

1. Run the actual one-click R entry point with the committed synthetic source map, plus CLI and source-friendly entry points as applicable. Verify expected CSVs, complete site assets and manifest, not just mocked HTML creation.
2. Rebuild from those CSVs without database access. Alter a harmless allowed synthetic CSV value and prove the corresponding public output changes. Required missing/malformed/schema-invalid inputs fail; optional missing and header-only files stay distinct. Compare logical output content excluding intentional build timestamps.
3. Test approved tables beyond the old row caps, leading-zero codes, Unicode, quoted commas/newlines, null and zero. Account for every publishable row or explicitly report the limitation. Check the last page and a search match in the last shard.
4. Test full-context R/Python disclosure parity, including complementary cells separated by prospective shard boundaries. Search all generated assets/downloads for forbidden synthetic markers. Test unknown files, traversal paths and unrelated nested analyses.
5. Verify installed-template precedence, source/installed resource completeness and incompatible runtime/build rejection. Verify every manifest-listed asset exists with the recorded byte size.
6. Use an actual browser over both HTTP and `file://`. Check initial resource loading, keyboard/mobile behavior, back/forward/deep-link restoration (including old panel-group links and exact source/field search routes), canceled searches, missing/corrupt/wrong-build shards, retry and stale responses. DOM mocks alone do not establish offline compatibility.
7. Compare entry bytes, core bytes, table-open bytes, DOM rows, retained shard bytes and observed timings before/after. Measure the initial entry and subsequent Clinical explorer separately. Print must not trigger loading every table.
8. Team 1 tests Team 2's implementation against clinician tasks and plain-language interpretation. Team 2 critically reviews Team 1's navigation/copy recommendations for false completeness, disclosure, resource costs and maintainability. Consolidate their findings, fix blockers and perform a scoped re-review. Preserve existing clinician-route, semantic identity and privacy regressions.

## Limits and delivery

Production DALY-CARE database availability remains unverified locally. Synthetic runner success is reported as such. Existing aggregate privacy rules are conservative release controls, not a proof of person-level anonymity. Large input limits and the remaining eager Clinical explorer payload are reported honestly.

Deliver a locally reviewable iteration-10 bundle, updated R/Python source and tests, reproducible build instructions, measured results and the two teams' final cross-appraisals. Preserve earlier releases. After successful verification, update the existing draft source PR; do not merge it or publish dataset exports to GitHub.
