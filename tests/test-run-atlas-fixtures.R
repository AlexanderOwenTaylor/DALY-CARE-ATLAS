root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
Sys.setenv(DALYCARE_MIN_CELL_COUNT = "1")
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

out_root <- tempfile("atlas_runs_")
result <- run_atlas(
  project_root = root,
  source_map_path = file.path(root, "config", "source-map.example.tsv"),
  output_root = out_root,
  mode = "report"
)

for (path in c(
  file.path(result$run_dir, "outputs", "atlas_resource_catalog.csv"),
  file.path(result$run_dir, "outputs", "atlas_source_resolution.csv"),
  file.path(result$run_dir, "outputs", "atlas_sources.csv"),
  file.path(result$run_dir, "outputs", "atlas_columns.csv"),
  file.path(result$run_dir, "outputs", "atlas_checks.csv"),
  file.path(result$run_dir, "outputs", "atlas_run_summary.csv"),
  file.path(result$run_dir, "outputs", "output_manifest.csv"),
  file.path(result$run_dir, "logs", "atlas_execution_log.tsv"),
  result$html,
  result$payload
)) {
  expect_file(path)
}

home <- paste(readLines(result$html,warn=FALSE),collapse="\n")
expect_true(grepl("DALYCARE_entry.js",home,fixed=TRUE),"Home should reference light bootstrap")
expect_false(grepl("DALYCARE_atlas_payload.js",home,fixed=TRUE),"Home must not load clinical core")
html <- paste(readLines(file.path(result$run_dir,"site/DALYCARE_clinical.html"), warn = FALSE), collapse = "\n")
for(asset in c('DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js')) {
  expect_true(grepl(asset,html,fixed=TRUE),'Offline shell must load its classic-script dependencies')
  expect_file(file.path(result$run_dir,'site',asset))
}
expect_false(grepl('DALYCARE_atlas_payload.js',html,fixed=TRUE),'Clinical shell must not load an eager payload')
expect_false(grepl(paste0('"run_id":"',result$run_id,'"'),html,fixed=TRUE),'HTML must not embed data')
route<-paste(readLines(file.path(result$run_dir,'site/atlas-route-feasibility.js'),encoding='UTF-8'),collapse='\n')
expect_true(grepl('MCL TRIANGLE',route,fixed=TRUE),'Feasibility route remains available')
index<-jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',paste(readLines(file.path(result$run_dir,'site/DALYCARE_search.js'),encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
profiles<-read_public_table(file.path(result$run_dir,'site'),'column_profiles')
expected<-unique(vapply(profiles,function(r)paste(r$table_name,r$column_name,sep='::'),character(1)))
actual<-vapply(index$fields,function(f)paste(index$sources[[f[[1]]+1L]],f[[2]],sep='::'),character(1))
expect_equal(sort(actual),sort(expected),'Every screened exact field remains searchable')

payload_js <- paste(readLines(result$payload, warn = FALSE), collapse = "\n")
expect_true(grepl("window.DALYCARE_ATLAS_PAYLOAD", payload_js, fixed = TRUE), "Payload JS should define the atlas payload.")
expect_true(grepl('dalycare-lazy-v1',payload_js,fixed=TRUE),'Payload is a labelled lazy bootstrap')
expect_false(grepl('column_profile_rows',payload_js,fixed=TRUE),'Bootstrap must not embed profile rows')

manifest <- read.csv(file.path(result$run_dir, "outputs", "output_manifest.csv"), stringsAsFactors = FALSE)
manifest_text <- paste(unlist(manifest), collapse = "\n")
expect_true(grepl("DALYCARE_atlas.html", manifest_text, fixed = TRUE), "Manifest should include the HTML artifact.")
expect_true(grepl("DALYCARE_atlas_payload.js", manifest_text, fixed = TRUE), "Manifest should include the payload artifact.")

assets <- list.files(file.path(result$run_dir,'site'),recursive=TRUE,full.names=TRUE)
asset_relative <- vapply(assets,function(p)relative_path(p,result$run_dir),character(1))
site_rows <- manifest[startsWith(manifest$relative_path,'site/'),]
expect_equal(sort(site_rows$relative_path),sort(unname(asset_relative)))
expect_equal(nrow(site_rows),length(assets))
expect_true(all(site_rows$file_size_bytes==file.info(site_rows$path)$size),'Manifest bytes must match assets')
context <- atlas_read_build_context(result$run_dir,atlas_output_registry(root))
expect_true(all(vapply(atlas_context_input_paths(result$run_dir,context,root),function(p)relative_path(p,result$run_dir),character(1)) %in% manifest$relative_path),'Saved and imported input bindings belong in internal manifest')
# A stricter saved threshold governs rebuilding even under a lower environment.
context$minimum_cell_count <- 10
jsonlite::write_json(context,file.path(result$run_dir,'outputs/atlas_build_context.json'),auto_unbox=TRUE,null='null')
path <- file.path(result$run_dir,'outputs/panels/registry_clinical_summary.csv')
rows <- utils::read.csv(path,stringsAsFactors=FALSE)
rows$n_rows <- rep(c(6,7,8,9),length.out=nrow(rows));write_csv(rows,path)
Sys.setenv(DALYCARE_MIN_CELL_COUNT='5')
rebuilt <- atlas_payload_from_run_outputs(result$run_dir,root)
expect_equal(rebuilt$payload$privacy_metadata$minimum_cell_count,10)
t <- Filter(function(t)t$id=='registry_clinical_summary',rebuilt$tables)[[1]]
expect_true(all(vapply(t$rows,function(r)is.null(r$n_rows),logical(1))),'Stricter saved policy must suppress original CSV counts')
# Execute the supported offline CLI against this synthetic run and recheck manifest.
rebuild_status <- system2(file.path(R.home('bin'),if(.Platform$OS.type=='windows') 'Rscript.exe' else 'Rscript'),shQuote(c(file.path(root,'scripts/rebuild_atlas_from_outputs.R'),result$run_dir,root)))
expect_equal(rebuild_status,0L)
manifest_after <- utils::read.csv(file.path(result$run_dir,'outputs/output_manifest.csv'),stringsAsFactors=FALSE)
expect_true(all(vapply(atlas_context_input_paths(result$run_dir,context,root),function(p)relative_path(p,result$run_dir),character(1)) %in% manifest_after$relative_path))
site_after <- manifest_after[startsWith(manifest_after$relative_path,'site/'),]
expect_true(all(file.info(site_after$path)$size==site_after$file_size_bytes))
core <- jsonlite::fromJSON(file.path(result$run_dir,'site/DALYCARE_atlas_payload.json'),simplifyVector=FALSE)
expect_equal(core$payload$privacy_metadata$minimum_cell_count,10L)
message("Atlas fixture smoke test passed")
