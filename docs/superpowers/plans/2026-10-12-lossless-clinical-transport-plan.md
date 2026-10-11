# Lossless Clinical transport implementation plan

2026-10-12. Accepted19 checkpoint is `eda8bfbb9fe604121b3b12522024fc5a92c4366d`. Follow `../specs/2026-10-12-lossless-clinical-transport-design.md`; older draft details yield to it. Stage0 is complete: root approved the final specification and froze contract version1 at SHA256 `716f8eb74b2421cf07aede1aa300b834140c13d1f20368e707d61adc764a0bc5`. Root owns release coordination, fixtures, pipeline/build/browser work and integration acceptance. No independent task may change clinical UI or snapshot values to make a codec test pass.

## Stage 0 — root freezes the interfaces

1. Finish registry19 review/fixes, verify its accepted source checkpoint and keep its build/evidence as the baseline. Record the exact source revision and guarded payload identity for the paired20 work. Do not rebuild or modify19 while its owner is active.
2. Root reviews/approves the final spec and writes/freezes one shared synthetic JSON fixture contract before implementation dispatch. Publish its path, revision/hash, case IDs, logical expectations, normalized budget numbers, work-limit overrides used by small tests, and configuration cases. No implementer independently changes this file. R loads it with `simplifyVector=FALSE`.
3. Freeze helper/signature conventions and ownership below, including the 32-unit numeric counter, Unicode scalar validation, absent/null treatment, version selection, path-array comparison, transaction guarantees and v1 read compatibility. Document fixture expected errors by category rather than identical cross-language wording.

Required shared fixture groups:

- **Valid round trip:** a one-key schema and a mixed-schema table; key order; distinct missing/null; nulls at row beginning/middle/end; leading-zero strings; zero, false and empty string; multibyte/supplementary Unicode; control/quote/backslash/slash/U+2028/U+2029 cases; empty/singleton/nested verbatim fallbacks; all reviewed alias identities needed by representative rows.
- **Numeric boundary:** protocol numeric 2 versus string/bool; indices 0 and 0.0 versus bool/fraction/negative/out-of-range; finite Number extremes; large Python integer whose JS equivalent is finite and one whose conversion is infinite; no value coercion. Charges are 32 per number regardless of lexical byte length; actual emitted file bytes remain a separate expectation.
- **Shape/path/graph:** exact-key violations, row width, duplicate schema keys/schemas, paths with delimiters, duplicate/prefix paths, missing destination versus null, array/inherited traversal, unsafe traversed/reconstructed keys, untouched unsafe-name own data properties, nested cells, dense arrays. Language-local constructed fixtures cover cycles, holes, accessors, symbols/non-JSON objects and nonfinite numbers, which JSON cannot encode.
- **Budget/fallback:** exact and one-over normalized charges; escaped Unicode; table/per-table-schema/key/path limits; aggregate packed rows/cells/tables with whole-table fallback and unconsumed counters; whole-envelope/expanded/actual-file failures including verbatim data and requested v1 output; no truncation or silent version change.
- **Transaction:** two valid tables then a late invalid descriptor/cell/budget/alias; original object and placeholders unchanged after rejection; successful decode also leaves input untouched; copies only affected branches and aliases refer to restored source arrays.
- **Compatibility/configuration:** real legacy and v1 reads; strict future3 rejection; output default2 independent of input; explicit v1; unset/empty/trimmed environment, whitespace-only invalid, explicit-argument precedence; JS and JSON assets agree.
- **Classic-script boundary:** both public writers reject own `__proto__` at any depth before promotion, including requested v1, while decoder JSON inputs preserve untouched own data properties and public outputs preserve untouched `constructor`/`prototype`. Verify prior site/manifest remain unchanged; do not alter the wrapper or drop the key.

## Stage 1 — independent production ownership after fixture freeze

### JS owner: browser decoder and Node tests

Own `inst/templates/atlas-transport.js`, `tests/test-payload-transport.js`, and narrowly related Node fixture/portable decoder tests. Implement strict v2 preflight, shared counters, copy-affected-branches reconstruction and staged alias validation. Preserve the legacy/v1 decode branches and existing API used by the template. No template/UI changes and no retained packed-data cache.

Verify against frozen valid/invalid fixtures, late failure transactions, alias identity, unchanged input, and untouched unsafe keys. Keep real v1 expectations; update future-version checks to3. Report exact files touched, focused test command/output, fixture contract hash, and unresolved risks. Do not run broad browser/performance work.

### Python owner: encoder, decoder, writer/import/CLI and tests

Own `scripts/site_bundle.py`, `scripts/build_ui_iteration.py`, `tests/test-site-bundle.py`, and narrowly related importer/export tests. Implement deterministic profitable packing, finite numeric interpretation, normalized counters, v2 transactional decoding, and writer whole-output budgets. Retain exact pre-read importer check; `max_bytes` controls new v2 read accounting only. Propagate appended version argument and CLI option with agreed environment precedence.

Keep Clinical guarded snapshot and Library projected evidence separate. Both output assets use one resolved version; stage failures preserve prior site/manifest. Verify real legacy/v1/v2 imports, default2/requested1 writes, actual bytes, JS/JSON equality and existing rollback behavior using bounded synthetic fixtures. Do not modify the shared fixture or R/JS owner files, run production builds, or replace clinical values.

### R owner: encoder/writers/call chain and tests

Own `R/site_bundle.R`, the trailing argument propagation in `R/html.R`, and focused R codec/site tests; touch other callers only if required for a real invocation. Resolve environment at public entry so existing R production/one-click/offline rebuild/mockup commands work unchanged. Implement eligibility/fallback with explicit unnamed protocol arrays, named records and list-preserved nulls; retain unsupported packing shapes' existing wire serialization. Implement shared accounting without whole-payload normalization to pack more.

Verify actual R v1 versus decoded R v2 using frozen fixtures and the browser decoder once available; include one-schema/one-key and mixed-type/null cases. Requested v1 must enforce the same writer budgets and be operational through a public call/environment. Deliberately update the default2 pipeline assertion while adding a true v1 assertion. Preserve publication/manifest rollback. Do not run the actual production pipeline or alter privacy/clinical source generation.

These owners can work independently only after Stage0. Coordinate common helper names and integration expectations through root; do not resolve disagreements by weakening shared expectations. The browser decoder is a cross-read dependency for final R/Python parity, not permission to edit its owner files.

## Stage 2 — root integrates and reviews

1. Review each focused diff/test result against the frozen contract, especially JS/Python finite-number semantics, R serialization shape, exact-vs-normalized bytes and legacy read preservation. Confirm files outside assigned scope are unchanged and no private data or candidate snapshot was committed.
2. Run the agreed shared cross-runtime round trips against actual serializers and the production decoder. Compare logical types/own properties and aliases; do not require cross-language packed-layout identity when existing serializers/order legitimately differ. Check actual JS/JSON envelopes match within each writer.
3. Run focused production-relevant integration: supported legacy/v1/v2 rebuild inputs, explicit public v1 invocations, default2, output budget/rollback, privacy audits and export parity. Update only targeted stale fixtures; do not loosen genuine v1 tests or broadly accept either version.
4. Obtain opposing code review of strict validation, transactional failures, counters, R shape/null, compatibility reachability and scope. Fix findings and rerun affected checks only. Root owns any shared fixture revision, with corresponding owner notification.

## Stage 3 — root actual build and frozen acceptance

1. Build candidate20 from the same guarded accepted19 input through the actual supported R pipeline and Python rebuild paths as required by the project, with no new database queries for this representation change. Verify publication manifests/rollback and actual assets. Preserve the accepted19 baseline throughout.
2. Establish exact decoded guarded-data equality and original provenance/coverage/privacy before browser work. Verify representative profile, dictionary, reconciliation, panel and source rows and actual Clinical/Library exports against their respective19 results. Record total file bytes and decoder size; raw/gzip/ZIP metrics are not interchangeable.
3. Apply the predeclared performance protocol from the approved design: HTTP and double-click offline; at least three fresh profiles for each variant/mode; paired/alternating order; identical readiness/settling rules; medians; report failures/exceptions; record decoder timing and sampled memory where available. Thresholds are >max(100ms,20%) completion regression or >max(2MiB,10%) retained heap growth. A noise-driven rerun uses five paired samples only for the affected comparison.
4. Treat observed sample maxima as observations, not true peak. If material regression occurs, investigate and fix or retain v1. If reliable heap measurement is unavailable, state memory remains unverified rather than claiming acceptance. Do not describe the change as faster until evidence supports that statement.
5. After all gates and review pass, create the user-authorized source checkpoint and deliver concise changes/validation/limitations. If keeping v1, report the measured reason and preserve the proven compatibility path. Do not publish/deploy unrelated assets or reopen clinical19 scope.

## Exit criteria

Finished means a bounded synchronous transport change with exact logical evidence parity, supported default2 and explicit1 output, true legacy/v1 read compatibility, strict transactional v2 validation, matched R/Python/browser contracts, complete supported build/export behavior, and an honest frozen performance decision. Smaller raw bytes alone do not satisfy completion.

## Accepted checkpoint — 2026-10-12

All stages above are complete. Independent Python review found no P1/P2; browser
inherited-array dispatch and R attributed-alias findings were reproduced, fixed by
their original owners and closed in narrow independent re-reviews. The R test's
initial historical-Git dependency was replaced with a verified synthetic literal;
the codec test passes without accessible Git metadata. Shared contract unchanged.

Root verification:272 JavaScript tests passed;78 Python tests ran with two optional
external-fixture skips. Final actual R one-click/default2/requested1 CLI/offline
rebuild/rollback/manifest/coverage/installed-resource pipeline passed after the
R correction. Actual historical input matches through accepted19 R v1, current
R v1/v2, Python and browser classic-script/JSON decoding, including all18 aliases.
Every guarded core value/type/own key/order and all147table descriptors/28802rows
remain unchanged. Actual v2 import followed by requested-v1 migration also matches.

HTTP and offline functional results match across55Clinical routes, three restored
registry themes,16printed sections, representative searches, actual dictionary
CSV exports and Library field/definition/coverage results. No browser exceptions
or page overflow. Root inspected the generated Clinical opening pixels.

The predeclared12fresh-profile performance runs pass both gates: medianHTTP
readiness211.9→248.5ms and retainedheap11171237→8612985B; offline202.1→283.7ms
and11139699→8608403B. Raw core4948341→2790493B. Retain default2 with explicit1
available. This is smaller/lower retained memory, not faster local startup; no
hosted/mobile or true-peak-memory claim. Sample variation does not change the
gate decision, so no additional repetitions were needed.

Evidence is local in `.artifact-temp/iteration20-team/`; generated research data,
public ZIPs and internal manifests are excluded from source control. The unrelated
baseline semantic-product assertion and DESCRIPTION maintainer-email limitation
remain recorded; this acceptance does not claim the whole R project suite passes.
