# CSV Evidence and Bounded Loading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Ship a fast offline-capable atlas with discoverable, accurately scoped CSV-derived table contents and a verified R CSV-to-site pipeline.

**Architecture:** The existing opening filename becomes a light clinical-question entry. An independent Data tables page uses a safe catalogue and bounded classic-script chunks; Clinical explorer retains existing clinical routes with exact-array transport deduplication. The R production and offline rebuild paths share strict CSV rehydration; Python upgrades snapshots and optionally reads selected run evidence through the same publication registry.

**Tech Stack:** R with existing jsonlite/readr dependencies; standard-library Python; dependency-free classic JavaScript/HTML/CSS; R, Python and Node tests; actual HTTP and file browser QA.

**Spec:** `docs/superpowers/specs/2026-10-11-csv-evidence-and-loading-design.md` (approved by user on 2026-10-11).

## Global Constraints

- The user explicitly requires both double-click offline use and web hosting.
- Existing clinical routes, translations and privacy rules remain supported.
- Apply the disclosure filter to whole logical tables at their established payload paths, with all necessary profile context, **before** filtering, deduplication, pagination or sharding.
- Never provide direct links to internal raw CSVs.
- Unknown artifacts and optional/library-only changed schemas default to metadata only or unavailable. A missing, malformed, oversized or schema-incompatible required clinical/build input instead fails the staged build.
- At most 250 rows and 256 KiB serialized UTF-8 data per shard; 50 visible rows.
- At most 1 MiB serialized-equivalent retained shard cache, with a single active table read. Browser heap overhead is separately measured.
- “No matches” appears only after a successful full scan. Failure/cancellation says search incomplete. A match in the last shard must be findable.
- Light-entry and direct table-library initial assets target at most 512 KiB each on the supplied run; neither loads the clinical core or table rows before needed.
- Start with a 64 MiB public table-data budget and a 64 MiB pre-read limit per input file, configured and reported by the builder.
- Target at least 25% smaller serialized clinical core on the supplied run; measure the actual result and subsequent Clinical explorer load cost.
- Production DALY-CARE database availability remains unverified locally. Synthetic runner success is reported as such.
- Preserve earlier releases. After successful verification, update the existing draft source PR; do not merge it or publish dataset exports to GitHub.

## Review Focus

1. Mixed builds and stale loads: wrong build/shard responses must never display under a different table title (Task 2).
2. Silent CSV fallback and type loss: missing/malformed required files fail; zero, null, leading-zero codes and Unicode survive correctly (Task 1).
3. Disclosure across page boundaries: whole-table complementary suppression occurs before chunks, and unreviewed headers/filenames never escape (Tasks 1 and 3).
4. Published site replacement failure: the previous working site survives a failed new build, including budget failures (Task 3).
5. Existing saved routes and installed resources: old panel-group/source-field routes work offline/HTTP and explicit project resources beat stale installed resources (Tasks 2–4).

## Shared interfaces and file ownership

- `inst/config/public-output-registry.json`: versioned R/Python registry of exact artifacts, CSV paths, payload paths, expected/allowed schemas, projections, required status, row grain and reviewed column meanings. Package location is deliberate; do not maintain independent copies.
- `R/output_evidence.R`: strict local-run inventory, build context, CSV rehydration and public evidence projection. `scripts/output_evidence.py`: equivalent table reading/projection for Python snapshot upgrades; no duplicate implementation of R clinical-derived summaries.
- `R/site_bundle.R` / `scripts/site_bundle.py`: matched transport/dedup, table chunks/catalogue, byte budgets, consistent staged publication and complete asset list.
- `inst/templates/DALYCARE_atlas.html`: existing clinical template stays at this source path for regression tests and is emitted as `DALYCARE_clinical.html`. New `DALYCARE_entry.html`, `DALYCARE_outputs.html`, `atlas-entry.js`, `atlas-outputs.js`, `atlas-transport.js`, and `atlas-pages.css` are focused entry/library/runtime assets.
- Internal full-run context: `outputs/atlas_build_context.json`, versioned, controlled run/build arguments and table schema metadata, no individual rows or credentials. It enables the same R assembly path after the source connection is gone.
- Public site schema version is 1. Catalogue global is `window.DALYCARE_OUTPUT_CATALOGUE`; bootstrap global is `window.DALYCARE_ENTRY`. Payload transport global remains `window.DALYCARE_ATLAS_PAYLOAD` with `{transport_version:1,payload:<logical object minus equal copies>,aliases:[{target:[keys],source:[keys]}]}`. The decoder restores the logical object before clinical initialization and accepts legacy non-envelope payloads.
- Catalogue fields: `schema_version`, `build_id`, `run_id`, `provenance`, `privacy_policy_version`, `limits`, `tables`. A table has controlled `id`, `title`, `source_file`, `group`, `kind`, `status`, `reason`, `row_grain`, `count_basis`, `source_row_count`, `represented_row_count`, `complete`, `provenance`, `source_terms`, `columns`, `shards`. Columns use `key`, `label`, `type`, and optional reviewed `definition`, `unit`, `denominator`, `scope`, `missing_rule`. Unknown fields are not fabricated.
- A shard descriptor has `id`, `src`, `rows`, `bytes`; its file calls `window.DALYCARE_OUTPUTS.register({schema_version:1,build_id,table_id,shard_id,rows})`. Size means UTF-8 serialized row-array bytes; runtime verifies the same measure.
- `DALYCARE_OUTPUTS.loadShard(tableId, shardId)` resolves rows after identity/size validation; `scanTable(tableId, query, page, onProgress, signal)` resolves `{rows,total_matches,scanned_rows,complete}` with at most 50 result rows and no unbounded match list. Empty query uses direct page/shard navigation.

### Task 1: Strict CSV evidence and reproducible R handoff

**Files:** Create `inst/config/public-output-registry.json`, `R/output_evidence.R`, `scripts/output_evidence.py`, `scripts/rebuild_atlas_from_outputs.R`, `tests/test-output-evidence.R`, `tests/test-output-evidence.py`; modify `R/run_atlas.R`, `scripts/run_atlas.R`, `tests/helper.R` for runtime loading and shared assembly. Keep existing site presentation unchanged in this task.

**Interfaces:**
- `atlas_save_build_context(run_dir, payload_args, output_paths, panel_paths, project_root)` records reconstructible controlled context and exact CSV bindings, not a cached full payload. Persist any required non-tabular aggregate context through explicit reviewed fields; prefer existing CSVs and reject unsupported context rather than retaining arbitrary objects.
- `atlas_payload_from_run_outputs(run_dir, project_root)` returns `list(payload, tables, context)` after strict required reads and `atlas_payload` assembly. No DB calls or old-payload fallback in this entry point.
- `atlas_output_evidence(run_dir, project_root, payload_snapshot=NULL)` returns full sanitized library table descriptors with a `rows` array but no chunks; snapshot-only mode is allowed with unknown original counts. `collect_output_evidence(run_dir, project_root, payload_snapshot=None)` provides equivalent Python descriptors.
- Production saves context from its assembled inputs, then rehydrates actual CSVs through the same function before calling the existing writer. The rebuild script invokes the same function and writer; Task 3 will extend its site output.

- [ ] Write focused synthetic failing tests for strict required read, harmless CSV edit affecting rebuilt logical payload, header-only optional file, leading-zero code/Unicode/quoted newline preservation, unknown filename/header/body sentinel non-disclosure, path escape rejection, and complete rows beyond 250/3000/5000 limits.
- [ ] Add a shared synthetic full-distribution fixture whose small cell and complement lie across prospective chunk boundaries; assert equivalent R/Python safe evidence and no forbidden strings. Unknown schemas close publication; required incompatible schemas fail.
- [ ] Implement the registry using audited existing output schemas and conservative per-column projections. Cover source/field/profile/reference/semantic outputs and registered existing panels; inventory other current-run outputs safely as metadata-only. File names alone never approve arbitrary columns. Read committed reference dictionaries from project resources, not untrusted reference CSV replacements in a run.
- [ ] Factor the current R CSV-reading/argument-assembly block, preserving controlled non-tabular module context and exact run provenance. Resolve non-tabular aggregate context explicitly in the implementation report so the reviewer can audit it. Reuse the production argument construction; do not build an unrelated approximation of `atlas_payload`.
- [ ] Run `Rscript tests/test-output-evidence.R`, `python tests/test-output-evidence.py -v`, existing R runner fixture and both shared privacy suites. Expected: passing assertions, no DB access, old site still works. Record actual commands/red-green results and any public coverage limitation.
- [ ] Commit only task files and write the task report with concrete interfaces/schema coverage and tests. Independent task review must pass before Task 2.

### Task 2: Lightweight entry and bounded Data tables browser

**Files:** Create the six new template/runtime/style files listed above, `tests/test-output-browser.js`, `tests/test-entry-routing.js`, `tests/test-payload-transport.js`; modify only clinical-template navigation/transport initialization in `inst/templates/DALYCARE_atlas.html`. No R/Python producer edits.

**Interfaces:** Consumes the shared globals/schema and Task 1 reviewed column semantics. Exposes the shard registration/load/search methods above. `atlas-transport.js` defines `window.DALYCARE_TRANSPORT.decode(transport)` and restores `window.DALYCARE_ATLAS_PAYLOAD` before the existing inline clinical app captures it; fixed aliases only, legacy payload support.

- [ ] Write failing runtime tests for shard coalescing, version/build/table/id mismatch, invalid paths, oversized row arrays, 1 MiB cache eviction, timeout/retry, late canceled responses, last-shard search, correct complete match count, bounded result memory and zero/null formatting. Use a script-loading harness, not arbitrary sleeps.
- [ ] Implement the catalogue/detail UI: search approved metadata, group/availability filters, one selected table, 50-row pages, whole-selected-table search with progress/cancel, clear empty/missing/withheld/limited states, column meanings, exact file/source labels and back state. Do not implement a download unless its page-only scope and spreadsheet-formula neutralization are tested.
- [ ] Implement light clinical question cards and readable loading/error states. `DALYCARE_atlas.html` legacy fragments delegate by a fixed known-route map using history replacement. Old Panels links map validated group/query state to library; known clinical/source/field fragments stay exact. Unknown routes get a friendly safe entry message. No arbitrary return URL or asset path from query parameters.
- [ ] Add Home/Data tables navigation from clinical template; use the library instead of a competing generic unpaginated panel inventory. Preserve existing clinical search/routes. Keep one-click clinical question destinations prominent on the new entry.
- [ ] Run new Node tests plus existing Node UI suites and R startup mock where touched. Use synthetic catalogue/shards for actual HTTP/file smoke if available; production export QA follows Task 3. No eager core/table scripts on entry/library. Commit and report actual tests for independent review.

### Task 3: Matched R/Python bundle generation and complete manifest

**Files:** Create `R/site_bundle.R`, `scripts/site_bundle.py`, `tests/test-site-bundle.R`, `tests/test-site-bundle.py`; modify `R/html.R`, `R/run_atlas.R`, `scripts/run_atlas.R`, `scripts/build_ui_iteration.py`, `scripts/rebuild_atlas_from_outputs.R`, `tests/helper.R`, `tests/test-ui-export.py`, affected R payload/runner tests, and package resource lookup if necessary.

**Interfaces:** `atlas_write_site_bundle(site_dir, payload, tables, project_root, provenance)` returns named `html`, `clinical_html`, `payload`, `payload_json`, `catalogue`, and `assets` paths. Python `write_site_bundle(output_dir,payload,tables,project_root,provenance)` returns equivalent paths. Existing `write_static_atlas` keeps its first three arguments and adds optional `output_evidence=NULL`; old callers produce honestly labelled snapshot table evidence. Existing `build(input_dir,output_dir,project_root,run_dir=None)` preserves positional compatibility and CLI adds optional explicit `--run-dir`.

- [ ] Write failing chunk/manifest/transport tests: 251 rows creates multiple parts; wide Unicode rows respect 256 KiB; >64 MiB pre-read refusal uses metadata/no allocation for optional inputs and fails required inputs; full-distribution suppression survives boundary; all assets exactly enumerated with valid bytes; corrupt build cannot replace previous valid output.
- [ ] Implement whole-logical-payload guard/audit before transport optimization. Deduplicate only reviewed equal infrastructure/top-level array pairs; fixed alias paths, matching JSON/JS transport, valid decoder order. Prove reconstructed logical equality and shared reference identity where appropriate; target >=25% core byte reduction on supplied local baseline without including that data in tests/repo.
- [ ] Compile table descriptors into bounded JSON/classic-JS parts and catalogue; include complete safe schema/provenance/counts, with no raw CSV links. Enforce declared input/table/shard/catalogue/entry limits. Over-limit optional tables are explicitly unavailable, not partially complete; required failures preserve prior site.
- [ ] Copy approved templates/runtime/styles into fresh staging, emit light bootstrap and new opening filename, validate every file, then publish one consistent build. Prefer explicit source-project resources over installed fallback. Keep previous site on failure and prevent accidental path escape on Windows. Manifest includes every HTML/JSON/JS/runtime/catalogue/shard asset exactly once and remains internal.
- [ ] Wire full production/rebuild R calls to Task 1 evidence. Python snapshot imports accept old and new transports, refresh committed dictionaries, audit, and optionally read the selected matching run through Task 1 with per-table provenance; reject mismatched run identity. Update portable export tests to assert both transport and logical equivalence rather than weakening old privacy assertions.
- [ ] Run R/Python producer tests, evidence/parity tests, actual fixture pipeline and affected Node tests. Commit/report, then independent review of publication boundary and full handoff.

### Task 4: End-to-end acceptance, opposing-team critique and delivery

**Files:** Create `tests/test-iteration10-pipeline.R` and any minimal regression fixture cases required by findings; update `docs/clinician-atlas-ui.md`, `README.md` and build usage documentation. Generated releases, benchmark reports, browser screenshots and review packages remain outside Git.

**Interfaces:** Real entry points and final site format from Tasks 1–3; previous iteration9 baseline outside the repository. User-facing deliverable is sibling `atlas-iteration-10` with a release ZIP and source-change ZIP.

- [ ] Execute real one-click, CLI and offline R rebuild against synthetic committed source inputs. Prove CSV sentinel edit reaches corresponding public output, missing required/schema errors stop publication, optional/header-only states persist, and complete manifests/versions agree. Test source-resource preference and shipped installed-resource inventory.
- [ ] Run all relevant Node tests, targeted R runner/semantic/privacy/writer tests and Python evidence/bundle/export/privacy suites once on the integrated tree. Classify any pre-existing unrelated failures; never claim unrun whole-project success. Re-run only covering checks after fixes.
- [ ] Build local migration release using the exact selected original run CSVs plus guarded iteration9 snapshot; validate path selection and report per-table origin. Never recursively publish other archive contents. Compare bytes/core/entry/table loading, asset counts and limits with baseline. Do not commit any generated dataset representation.
- [ ] Team 1 browses real final site over HTTP and file://, desktop/mobile and keyboard: clinical question to field to table, last-page/search match, return/deep links and simulated missing/wrong-build/canceled loads. Team 2 critically appraises UI wording/completeness and runtime/resource safety from Task 2 and Team 1 findings, and Team 1 critically appraises Team 2's actual generator behavior and availability messages. Record both cross-appraisals and resolve blockers.
- [ ] Package whole-iteration code diff for one final independent reviewer. Dispatch one consolidated fix wave if needed, then one scoped re-review; preserve exact tests/evidence. Stage allowlisted source only, commit/push feature branch and update/attach existing draft PR3. Keep main unmerged.
- [ ] Deliver local bundle links, updated PR, measured improvements and candid limits (production DB untested, core still eager when explorer opened, input limits, any undisplayed table types).

## Self-review and execution

All spec sections map to Tasks 1–4. Interfaces above are the common producer/consumer contract. All five Review Focus risks have explicit owning tests. Implementation is sequential to avoid overlapping-file writes; independent browser/code critiques can run in parallel after producer completion. Use the already requested two-team method and retain the existing feature checkout. Stop for new destructive/external actions beyond approved scope, not for routine implementation choices; record significant rulings in the plan ledger.
