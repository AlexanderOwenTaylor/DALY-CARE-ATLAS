# V06 cartography bootstrap/loader hardening patch — 2026-05-01

This patch addresses the failure mode where the consolidated cartography script
found a pre-existing `load_dataset()` function and therefore skipped DALY-CARE
bootstrap refresh, but the underlying backend/session was stale. The failed run
then loaded only a few lookup tables and zero streamed clinical datasets.

Changes:

1. Refresh DALY-CARE bootstrap by default when `BOOTSTRAP_PATH` is available.
   Set `CARTO_REFRESH_BOOTSTRAP=FALSE` only for a deliberately pre-bootstrapped
   session.
2. Add a loader canary (`CARTO_LOADER_CANARY`, default `patient`) and fail before
   payload generation if it cannot resolve a positive-row data.frame.
3. Refuse to create a near-empty atlas payload when Stage B loads zero streamed
   datasets, unless `CARTO_ALLOW_ZERO_STREAM=TRUE` is explicitly set.
4. Reject wrong-object identity matches in both Stage A and Stage B, preventing
   cases such as `Codes_NPU` being satisfied by a `Codes_ATC` object.
5. The existing `RUN_CARTOGRAPHY_ATLAS.R` publish guard remains: even if an
   operator overrides the script-level guard, the site payload is not overwritten
   unless at least one streamed dataset loaded, unless `CARTO_FORCE_PUBLISH=TRUE`.
