# V06 seed-bucket and empty-vector fix — 2026-04-30

This patch applies two final release-candidate hardening fixes:

1. `isotype_recovery_omnibus.R`
   - Added `vec_tbl()` and routed `codes_queried` construction through it.
   - This prevents empty consensus vectors, currently `MSPIKE_NEUROPATHY <- character()`, from creating a zero-length/length-one tibble recycling error.

2. `000_build_detective_archive.R`
   - Completed fallback detective bucketing for consensus M-spike codes not previously covered by `ANALYTE_SEEDS`.
   - Added urine IFX, urine generic/screen/type/group/24h-screen, and Bence Jones buckets while keeping plasma generic seeds plasma-only for the isotype-recovery fallback.

No generated result files are changed by this patch.
