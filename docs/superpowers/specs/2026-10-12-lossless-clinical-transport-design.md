# Lossless Clinical transport v2 design

2026-10-12. Approved under the continuing iterative-work request after accepted registry19 source checkpoint `eda8bfbb9fe604121b3b12522024fc5a92c4366d`. Earlier alternatives yield to this specification. X1 scientific and Y2 design challenges are incorporated, including the classic-script property boundary. No user permission is pending.

## Outcome and scope

Reduce raw Clinical payload representation while preserving the exact logical JSON produced by the existing v1 serializer, including array/key order, types, absent versus null, reviewed alias identity, privacy annotations and provenance. Retain eager synchronous initialization, filenames, routes, search, print, exports, offline double-click and HTTP operation. No new loader, asset family, workers, dependencies, clinical mappings or Library-to-Clinical substitution.

The scratch candidate saved 2,157,848 raw bytes (43.608%) on iteration18; fixed-level gzip saved 38,221 bytes (13.773%). These are feasibility evidence, not implementation acceptance or latency promises. Final bytes and behavior must be measured on the accepted19 guarded input.

## Protocol

V2 has exactly four own keys: `transport_version`, `payload`, `aliases`, `row_tables`. The protocol selector is numeric 2, never boolean or string. Parsed finite integral `2.0` equals 2 and is accepted. Unknown numeric versions reject. `payload` is a JSON record; `aliases` and `row_tables` are dense arrays.

Each table has exactly `path`, `schemas`, `rows`. A path is an array of object-property strings from `payload` to a null placeholder. Schemas are arrays of ordered key arrays. A row is `[schema_index, cell0, ...]`; indices are zero-based finite mathematically integral JSON numbers, excluding booleans. Each cell matches the corresponding schema key. Different ordered key sets preserve missing properties without adding nulls. Empty arrays, empty records and ordinary nulls not targeted by a descriptor remain ordinary data.

Each table has at least one schema and at least two rows. Empty `row_tables` is valid. Unique, well-formed unused schemas are accepted within the metadata limits; decoding does not require the encoder's canonical first-encounter schema order.

Packing visits record properties in existing order and does not recurse through array elements. Eligible arrays contain at least two nonempty records, each with scalar JSON cells. Schema identity is the exact ordered component array, in first-occurrence order; comparisons must not join components using a delimiter. Preserve row and property order. Retain a table verbatim if it is ineligible, would not save actual serializer UTF-8 bytes including its descriptor/placeholder/separator overhead, or exceeds a packing-work limit. Never partly pack, truncate, coerce, project or fill missing cells.

Encoding performs the existing equality-checked alias removal first, then packs the resulting guarded snapshot. Decoding unpacks first, validates/restores aliases second, and returns only the complete logical payload.

## Scalar, graph and key contract

JSON scalar cells are null, boolean, finite number and valid-Unicode string. All strings, including keys, must contain Unicode scalar values; v2 rejects lone surrogates. Preserve code points without normalization. Python integers are allowed only when their JavaScript Number equivalent is finite; perform this check without converting/storing a replacement value. In particular an arbitrary integer whose float conversion overflows is invalid. Existing JavaScript rounding of integers outside its exact range is not newly corrected or hidden; compare each runtime against its existing parsed-v1 baseline. Test the finite/infinite boundary explicitly.

V2 graph preflight rejects cycles, non-JSON values, holes/undefined, symbol keys, accessors, functions, nonfinite numbers and non-record objects. JavaScript records have Object.prototype or null prototype and enumerable own string data properties; arrays are dense with only indexed cells and length. Python uses JSON-compatible built-in containers/scalars, with booleans distinguished from numbers. Acyclic shared subtrees are allowed but charged once per serialized occurrence, not once per identity. Use bounded traversal with active-ancestor cycle detection; maximum JSON nesting depth is 128.

Depth starts at zero and increases once per container-to-value edge; any value at depth greater than128 rejects. Envelope accounting starts at its root, while expanded pre-alias accounting starts at the payload root. A restored scalar is at `path.length + 2`. Keys are not additional graph nodes. Reviewed aliases are not recursively expanded for byte/depth accounting.

Unsafe names `__proto__`, `constructor`, and `prototype` reject in a traversed path component or reconstructed schema key, including an alias write path. Do not add a blanket ban to untouched JSON property names: those can remain own data properties and must never be merged through unsafe assignment. Use own-property lookup throughout. Do not invoke inherited accessors while inspecting a graph.

The unchanged classic-script object-literal wrapper cannot faithfully represent an own `__proto__` JSON key. Both public writers therefore reject such a key at any depth of the final guarded transport, for requested v1 and v2, before publication; preserve the previous site and manifest. Do not silently delete the key or change the wrapper/import grammar. Decoder-only JSON/object inputs still support untouched own `__proto__`; untouched `constructor` and `prototype` remain publishable. Test the actual JS/JSON boundary, not only JSON.parse-based decoder fixtures.

Paths must be nonempty arrays of nonempty strings; traverse only existing own properties of records, never array indices. Resolve every destination against the original placeholder tree. Each destination must exist and be exactly null. Reject duplicate paths and prefix overlaps using component-array comparison. Each schema is nonempty, has unique nonempty keys and is unique within its table. Each row has exactly one index plus the selected schema's cell count. Reject missing/out-of-range indices, wrong widths, nested cells and extra table/envelope keys. Each v2 alias has exactly `target` and `source`, and must match the current reviewed allowlist; reject duplicates, overwritten targets, missing/non-array sources and cycles. Raw duplicate JSON members cannot be detected after ordinary parsing and are outside this change; reject parsed collisions that remain observable.

## Limits: fallback versus error

Frozen packing-work limits: 4,096 tables; path depth 16; 64 schemas per table; 64 keys per schema; 128 UTF-8 bytes per path/schema-key component; 100,000 packed rows and 1,000,000 packed scalar cells in total. The index is metadata, not a scalar cell. Limits count only successfully packed tables. If the next whole table would exceed a limit, leave it verbatim without consuming counters, then continue deterministic traversal. Decoder metadata exceeding these limits rejects.

The project byte limit is `min(67,108,864, registry.input_max_bytes)`; require a positive finite integral limit, not boolean. Browser v2 defense limit is fixed at 67,108,864 and knows no environment settings. Library `public_table_max_bytes` and shard budgets remain independent.

Writers of either v1 or v2 must enforce (a) actual emitted JS bytes including wrapper/terminator/newline and actual JSON bytes including newline, (b) normalized encoded-envelope accounting, and (c) normalized expanded **pre-alias payload** accounting. Exceeding any whole-output limit is a publication error, including when v1 was explicitly requested; it is not a reason to truncate or downgrade. Validate before promotion and preserve the previous site plus manifest on failure.

V2 readers enforce normalized encoded-envelope and expanded pre-alias payload limits. Python's importer additionally retains the existing exact pre-read file-size check and passes the project limit to v2 decoding. Browser checking occurs after classic-script parsing/evaluation and is not a pre-read network or parser limit. Legacy/v1 read branches retain existing semantics and do not acquire these new normalized/expanded counters, even if `max_bytes` is supplied; their importer still has the exact pre-read file-size check. All writers retain the whole-output budgets above.

### Shared normalized accounting algorithm

This is a defense accounting unit, not a claim of exact serialized bytes. Use the same function/rules in all three runtimes:

- Null costs 4; true 4; false 5; every finite numeric token costs **32**. This numeric charge applies to metadata indices too. It is deliberately independent of numeric spelling and is not an upper bound for arbitrary Python integer lexical length; exact emitted-file checks are separate.
- A string costs two quotation marks plus escaped-content bytes. Quote and backslash cost 2 each. Backspace, tab, LF, form feed and CR use the standard two-byte escapes. Other U+0000–U+001F characters cost 6 (`\\u00xx`). Other Unicode scalar values cost their ordinary UTF-8 length, including supplementary characters as 4 bytes. Slash is not escaped in this normalized accounting; U+2028/U+2029 cost their UTF-8 bytes. Actual serializers may spell these differently, covered by exact file checks.
- An array costs brackets (2), commas (`max(0,n-1)`) and each element's charge. A record costs braces (2), commas, and each quoted key + colon (1) + value charge. No whitespace is charged. Include all verbatim data, metadata and cells; schema indexes are part of encoded accounting but not restored rows.
- Expanded pre-alias accounting starts from payload accounting with null placeholders. For each table replace its 4-byte placeholder charge with the restored array charge: brackets/commas and, for each row, braces/commas and repeated schema key + colon + scalar-cell charges. Do not alias-expand shared arrays and charge them twice.
- Abort immediately when a limit is exceeded. Count by walking and accumulating; do not allocate an expanded JSON string, full reconstructed graph or whole-payload clone just to count. Apply depth/cycle/shape validation during the walk.

The shared fixture file must include exact string charges, numeric charges, exact-equal and one-unit-over normalized boundaries, and actual-file boundaries separately. Actual descriptor profitability uses the language's existing serializer and actual UTF-8 bytes; cross-language packing choices may differ while decoded values must not.

## Transactional reconstruction and retained memory

For browser v2 graph validation, arrays must have either the current realm's `Array.prototype` or a null prototype. Reject other array prototypes without invoking inherited accessors. Traverse input arrays by own indexed data cells and compare path/schema components without calling input iterators or inherited array methods. Dense null-prototype arrays remain supported throughout metadata, rows and alias paths. This clarification does not change the legacy/v1 branch.

Validate the complete graph, descriptor metadata, original paths, cells, work limits and byte accounting before constructing restored row objects. Build arrays off to the side. Stage a new root and copies only of record branches affected by destinations and the alias parent; share untouched subtrees. Validate all aliases against staged reconstructed sources before applying any staged alias writes. Return only after every check passes. Input envelope/payload/descriptors remain unchanged on success and failure; a late alias failure must not reveal an earlier restored table through the input.

Do not deep-clone the whole envelope/payload or retain descriptors/envelope in caches or closures. The template already replaces `window.DALYCARE_ATLAS_PAYLOAD` with the decoded payload before its consumers capture arrays. Returning the staged logical object lets packed arrays become collectible after decode. Temporary packed/restored coexistence and garbage-collection timing still require observation; smaller files do not imply lower peak or retained heap.

## R wire fidelity

The target is the existing serializer's parsed JSON, not R classes or numeric spelling. Pack only eligible unnamed arrays of nonempty named record lists with unique names and supported scalar cells. Unsupported packing shapes remain verbatim with their current serialization; do not reparse/normalize/rewrite the entire payload to increase eligibility. Budget traversal must reflect those existing JSON serialization shapes, not assume every R list/vector is the same wire shape.

For unsupported R subtrees, locally walking tokens from their existing serialization is permitted for accounting without changing the value graph. Prefer small fragments where practical; do not serialize/clone the whole payload merely to count. This can transiently allocate the serialized unsupported subtree, so the publication budget is not a hard allocation cap. Preserve existing NA/class wire behavior.

Construct `row_tables`, `path`, `schemas`, each schema, `rows` and each row as explicit unnamed lists, including one-element cases. Use `as.list(keys)` for a schema and a list containing the numeric index plus original cells for a row; never atomic concatenation that coerces mixed types. Preserve null placeholders/cells with list-preserving replacement (`parent[key] <- list(NULL)`, `row[i] <- list(NULL)`); `[[key]] <- NULL` deletes a property. Distinct schemas preserve absence. R fixtures are read using `simplifyVector=FALSE` and then compared via the actual serializer and browser decoder.

## Reachable compatibility and configuration

Append optional `transport_version` parameters to existing public writer/caller signatures to preserve positional calls. Python: `build(..., transport_version=None)` -> `write_site_bundle(..., transport_version=None)` -> `encode_transport(..., transport_version=2, max_bytes=...)`; decoder adds optional `max_bytes=None`, governing v2 only. R: `write_static_atlas(..., transport_version=NULL)` -> `atlas_write_site_bundle(..., transport_version=NULL)` -> `atlas_payload_transport(..., transport_version=2L, max_bytes=...)`. Resolve at a public entry and pass the resolved choice downward; direct public-writer calls also resolve once. Internal codecs do not reread the environment.

Precedence: explicit argument > `DALYCARE_ATLAS_TRANSPORT_VERSION` > default 2. An explicit argument may deliberately normalize numeric 1/2 (finite integral, not bool) or exact string `"1"`/`"2"`; reject every other explicit value. Environment unset or exactly empty means default 2. Otherwise trim surrounding whitespace, then accept only `"1"` or `"2"`; whitespace-only is invalid, as are `"01"`, `"1.0"`, or other text. Configuration normalization never permits string protocol versions. Imported format never selects output format.

Python CLI adds `--transport-version {1,2}` and passes it through `build`. Existing R production/one-click/offline rebuild/mockup invocations can select v1 through the environment with no mandatory argument changes. Demonstrate a real v1 build in both languages, plus legacy/v1/v2 import into updated rebuild tools. Old tools cannot read v2 and must reject it clearly; no duplicate full v1 assets are shipped by default. Keep genuine v1 tests and move “future version” fixtures to unsupported version 3.

## Frozen acceptance gate

Semantic acceptance is mandatory before performance interpretation: type-aware decoded equality against the same guarded v1 input, own-key/null distinction, alias identity, privacy audit parity, unchanged source/run/provenance/completeness, actual JS/JSON/import/rebuild parity, and Clinical/Library exports each compared to their own baseline. No row-count-only acceptance.

Compare accepted19 and candidate20 with the same guarded input/environment, separately under local HTTP and double-click offline. Use at least three fresh browser profiles per variant per mode (12 minimum successful runs), alternating or paired order. Measure completion from navigation start to the first observation of `document.documentElement.dataset.atlasReady === "true"`, with the same observation mechanism/cadence for both variants. Verify search/print/export readiness and exceptions independently; readiness-probe failure invalidates acceptance rather than silently redefining completion. Failures are reported, not discarded. Report median completion time and median retained JS heap measured two seconds after readiness, before probes that change the displayed view; use the same supported heap mechanism and no forced GC in either variant.

Investigate/fix or retain v1 if candidate median completion regresses by **more than max(100 ms, 20% of baseline median)**, or retained heap grows by **more than max(2 MiB, 10% of baseline median)**. If results are noisy enough to change the decision, rerun five paired fresh-profile samples per variant/mode only for affected measurements. Otherwise do not broaden/repeat. The tolerances are pragmatic local noise gates, not universal user-experience thresholds or proof of speed. With a roughly 200–250 ms baseline the 100 ms floor is permissive; report absolute results even when within it.

Capture decoder timing and heap samples when supported without new production instrumentation. Report the largest sampled value as an **observed maximum**, never a guaranteed true peak. No reliable heap measure means memory acceptance remains explicitly unverified. Actual emitted bytes, decoder growth and exact data equality remain mandatory. No faster-opening claim from file arithmetic alone.

## Frozen synthetic contract

`tests/fixtures/transport-v2-contract.json`, contract version1, SHA256 `716f8eb74b2421cf07aede1aa300b834140c13d1f20368e707d61adc764a0bc5`, is root-owned. It has five valid decoding cases, 37 invalid cases, exact normalized charges, a mixed-schema encoder fixture, configuration cases and language-local requirements. It contains no dataset evidence. Implementers must report discrepancies to root instead of editing expectations. R reads it with `simplifyVector=FALSE`; browser VM tests parse within the tested realm. Private test seams may use smaller byte limits, but the public browser decoder keeps its fixed64MiB ceiling and unchanged API. No production API is added solely for fixture access.

R cannot represent embedded NUL in strings, and the installed jsonlite truncates those synthetic fixture strings on import. Keep the fixture unchanged: test R-representable charge cases directly and the original serialized NUL tokens through the accounting token walker. Compare R v2 to its actual parsed-v1 serialization; do not claim that R imported the original NUL fixture losslessly. JavaScript/Python retain full original NUL values and decode expectations. This is an explicit existing R input limitation, not permission for a new codec to truncate strings.
