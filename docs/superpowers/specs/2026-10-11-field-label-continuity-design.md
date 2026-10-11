# Reviewed field names throughout Data tables

The X1 review found that Clinical explorer's Sample type, Diagnosis code and
Susceptibility interpretation links arrive at raw field names in Data tables.
The published local display dictionary already contains 785 exact field pairs
across 30 sources; 784 match this historical export's profiles. The library's
manually copied map covers only three registries. Preserve existing reviewed
translations throughout the journey without fetching the Clinical core.

## Contract

- Both R and Python bundle writers emit an optional `field_labels` object in the
  existing output catalogue, keyed by exact source, then exact field, with string
  display labels. Derive it from the same guarded clinical display dictionary
  being published, not a new lookup file or independent stale copy.
- Only `kind=field` rows qualify. `system`, `code` and `label` must be nonempty
  strings. Preserve their exact identity; do not trim/case-fold/alias-match source
  or field keys into another identity. Identical duplicate pairs may coalesce;
  conflicting labels fail publication. Reject malformed qualifying rows and
  prototype-related keys with an explicit build error. Omit the optional map when
  there are no labels. Failed publication preserves the previous site/manifest.
- The browser uses own-property exact lookups. With a valid new map, missing pairs
  remain raw. Old catalogues without the optional property keep the existing
  registry fallback. Malformed optional metadata must not crash the table reader
  or render object text/markup: ignore invalid entries and retain exact names.
- Readable field names apply to existing field cards/tables and field-name search
  through the existing `fieldLabel` helper. Search matches raw name OR reviewed
  label under exact source/field filters. Labels must not alter typed raw rows,
  identifiers, categorical/numeric interpretation, unit provenance or disclosure.
- Raw identifiers and source remain visible in the existing evidence reader;
  HTML-like text stays escaped. Reference code, term, gene and value rows are not
  field labels. An unmatched `RKKP_LYFO/Reg_IPI` must never be guessed onto `IPI`.
  Unknown `SDS_t_udtilsgh/c_udtilsgh` remains exact.

## Boundaries and acceptance

This cycle adds display metadata, not new meanings, values, units, measurements
or availability. Preserve dictionary provenance and the raw published table.
Home/Clinical assets and core stay unchanged. Table descriptors/row objects stay
unchanged. Both writers enforce the existing 512 KiB initial library ceiling and
atomic publication. No clinical-core/dictionary-shard prefetch is introduced.

X1 and Z3 test Biobank Sample type, microbiology interpretation/value/unit and
Diagnosis code journeys, exact source scopes, human-label searches and unknown
fields, using HTTP and offline browser renders. W0 checks improved source-to-field
continuity against its existing recovery ledger. Independent Y2 review checks
builder parity, collision/malformed metadata, search scope and escaped rendering.
Use shared synthetic builder fixtures plus meaningful Node behavior tests.

Authorization: this is the next bounded repair within the user's explicit
ongoing multi-team iteration request. Root integrates and saves source-only
checkpoints to the existing draft PR; generated research artifacts remain local.
