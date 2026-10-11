root <- normalizePath('.', winslash = '/', mustWork = TRUE)
source('tests/helper.R'); source_test_runtime(root)
spec <- load_clinical_source_membership(root)
work <- tempfile('membership-wiring-'); dir.create(file.path(work, 'outputs'), recursive = TRUE)
writeLines('{}', file.path(work, 'outputs/atlas_build_context.json'))
paths <- atlas_context_input_paths(work, list(bindings = list()), root)
expect_true('clinical_source_membership' %in% names(paths), 'Publication inputs must record the required membership resource.')
expect_equal(normalizePath(paths$clinical_source_membership, winslash = '/'), clinical_source_membership_path(root))
runtime <- new.env(parent = .GlobalEnv)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = 'TRUE')
sys.source('scripts/run_atlas.R', envir = runtime)
rm('clinical_source_inventory', envir = .GlobalEnv)
runtime$load_atlas_runtime(root)
expect_true(exists('clinical_source_inventory', envir = .GlobalEnv, inherits = FALSE), 'Source bootstrap must load the pure membership helper.')
payload <- list(run_id = 'wiring-test', catalog_rows = list(), review_infrastructure_sections = list(),
                clinical_source_inventory = clinical_source_inventory(list(), spec))
published <- write_static_atlas(work, payload, root, output_evidence = list(), membership_spec = spec)
manifest <- read.csv(published$manifest, stringsAsFactors = FALSE, check.names = FALSE)
resource_row <- manifest[manifest$artifact_id == 'clinical_source_membership', , drop = FALSE]
expect_equal(nrow(resource_row), 1L)
expect_equal(resource_row$clinical_source_inventory_version, spec$inventory_version)
expect_equal(resource_row$input_md5, unname(tools::md5sum(clinical_source_membership_path(root))))
atlas_validate_output_manifest(work, atlas_output_registry(root)$input_max_bytes, project_root = root)
manifest_bytes <- readBin(published$manifest, 'raw', n = file.info(published$manifest)$size)
bad_manifest <- manifest
bad_manifest$relative_path[bad_manifest$artifact_id == 'clinical_source_membership'] <- 'C:/outside/unreviewed.json'
write_csv(bad_manifest, published$manifest)
rejected_manifest <- tryCatch(atlas_validate_output_manifest(work, atlas_output_registry(root)$input_max_bytes, project_root = root), error = identity)
expect_true(inherits(rejected_manifest, 'error'), 'The resource input exception must not permit another external path.')
writeBin(manifest_bytes, published$manifest)
moved_root <- tempfile('moved-membership-project-'); dir.create(file.path(moved_root, 'inst/config'), recursive = TRUE)
for (name in c('clinical-source-membership.json', 'public-output-registry.json')) {
  expect_true(file.copy(file.path(root, 'inst/config', name), file.path(moved_root, 'inst/config', name)))
}
expect_equal(unname(tools::md5sum(clinical_source_membership_path(moved_root))),
             unname(tools::md5sum(clinical_source_membership_path(root))))
# The saved resource row is historical input identity, not a CSV to rehydrate.
# Remove only this test's deliberately empty build context to exercise evidence
# reconstruction's saved-manifest boundary without creating a live database run.
context_path <- file.path(work, 'outputs/atlas_build_context.json')
context_backup <- file.path(work, 'outputs/unused-build-context.json')
expect_true(file.rename(context_path, context_backup))
moved_tables <- tryCatch(atlas_output_evidence(work, moved_root, discard_membership_input = TRUE), error = identity)
expect_true(file.rename(context_backup, context_path))
expect_false(inherits(moved_tables, 'error'), 'Rehydration must discard old resource input before moved-project manifest validation.')
bad_manifest <- manifest
bad_manifest <- rbind(bad_manifest, bad_manifest[1, , drop = FALSE])
bad_manifest$artifact_id[nrow(bad_manifest)] <- 'actual_csv_output'
bad_manifest$relative_path[nrow(bad_manifest)] <- 'C:/outside/unreviewed.csv'
write_csv(bad_manifest, published$manifest)
bad_output <- tryCatch(atlas_validate_output_manifest(work, atlas_output_registry(moved_root)$input_max_bytes,
  project_root = moved_root, discard_membership_input = TRUE), error = identity)
writeBin(manifest_bytes, published$manifest)
expect_true(inherits(bad_output, 'error'), 'Discarding an old resource input must retain confinement of every actual output.')
assets <- list.files(file.path(work, 'site'), full.names = TRUE, recursive = TRUE)
before <- tools::md5sum(c(assets, published$manifest))
bad_root <- tempfile('bad-membership-root-'); dir.create(file.path(bad_root, 'inst/config'), recursive = TRUE)
expect_true(file.copy('inst/config/public-output-registry.json', file.path(bad_root, 'inst/config/public-output-registry.json')))
writeLines('{"schema_version":999}', file.path(bad_root, 'inst/config/clinical-source-membership.json'))
failure <- tryCatch(write_static_atlas(work, payload, bad_root, output_evidence = list()), error = identity)
expect_true(inherits(failure, 'error'))
expect_true(grepl('clinical-source-membership', conditionMessage(failure), fixed = TRUE))
expect_equal(tools::md5sum(c(assets, published$manifest)), before, 'Invalid resource must preserve previous published files and manifest.')
cat('Required membership source bootstrap and publication manifest wiring passed\n')
