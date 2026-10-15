# Real entry-point acceptance using only committed synthetic inputs.
root <- normalizePath('.',winslash='/')
source('tests/helper.R'); source_test_runtime(root)
Sys.unsetenv('DALYCARE_ATLAS_TRANSPORT_VERSION')
work <- tempfile('iteration10-pipeline-');dir.create(work)
rscript <- file.path(R.home('bin'),if(.Platform$OS.type=='windows') 'Rscript.exe' else 'Rscript')
child <- function(args,success=TRUE) {
 log <- tempfile('child-',tmpdir=work,fileext='.log')
 status <- system2(rscript,shQuote(args),stdout=log,stderr=log)
 if(success && status!=0L) stop(paste(readLines(log,warn=FALSE),collapse='\n'))
 expect_true(if(success)status==0L else status!=0L)
 invisible(log)
}
read_assignment <- function(path) jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',paste(readLines(path,encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
accept_site <- function(run,project_root=root,transport_version=2L) {
 site <- file.path(run,'site');manifest <- read.csv(file.path(run,'outputs/output_manifest.csv'),stringsAsFactors=FALSE)
 files <- list.files(site,recursive=TRUE)
 entries <- manifest[startsWith(manifest$relative_path,'site/'),]
 expect_equal(sort(entries$relative_path),sort(paste0('site/',files)))
 expect_false(anyDuplicated(manifest$relative_path)>0)
 expect_true(all(file.info(entries$path)$size==entries$file_size_bytes))
 context <- atlas_read_build_context(run,atlas_output_registry(project_root))
 inputs <- vapply(atlas_context_input_paths(run,context,project_root),function(p)relative_path(p,run),character(1))
 expect_true(all(inputs %in% manifest$relative_path),'All supplemental and imported binding files must be manifested')
 supplemental <- c('outputs/atlas_context_ki67_discovery_summary.csv','outputs/atlas_context_mcl_triangle_feasibility_standalone_output_source.csv','outputs/atlas_context_mcl_triangle_feasibility_pathology_ki67_signpost.csv','outputs/atlas_context_mcl_triangle_feasibility_recommended_next_actions.csv','outputs/atlas_context_mcl_triangle_feasibility_caveats.csv','outputs/atlas_context_mcl_triangle_feasibility_verdict_metadata.csv')
 expect_true(all(c('outputs/atlas_build_context.json',supplemental,unlist(context$binding_files)) %in% manifest$relative_path))

 required <- c('DALYCARE_atlas.html','DALYCARE_clinical.html','DALYCARE_outputs.html','DALYCARE_entry.js','DALYCARE_output_catalogue.js','DALYCARE_atlas_payload.js','DALYCARE_atlas_payload.json','atlas-entry.js','atlas-outputs.js','atlas-transport.js','atlas-pages.css')
 expect_true(all(required %in% files))
 bootstrap <- read_assignment(file.path(site,'DALYCARE_entry.js'));catalogue <- read_assignment(file.path(site,'DALYCARE_output_catalogue.js'))
 core <- jsonlite::fromJSON(file.path(site,'DALYCARE_atlas_payload.json'),simplifyVector=FALSE)
 expect_equal(bootstrap$schema_version,1L);expect_equal(catalogue$schema_version,1L);expect_equal(core$transport_version,transport_version)
 # Semantic assertions below consume the actual browser-decoded logical payload.
 decoded <- tempfile('decoded-',tmpdir=work,fileext='.json');probe <- tempfile('decode-',tmpdir=work,fileext='.cjs')
 writeLines(c("const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict');",
   "const [asset,json,decoder,out]=process.argv.slice(2),context={window:{}};vm.createContext(context);",
   "vm.runInContext(fs.readFileSync(asset,'utf8'),context);vm.runInContext(fs.readFileSync(decoder,'utf8'),context);",
   "assert.deepEqual(JSON.parse(JSON.stringify(context.window.DALYCARE_ATLAS_PAYLOAD)),JSON.parse(fs.readFileSync(json,'utf8')));",
   "fs.writeFileSync(out,JSON.stringify(context.window.DALYCARE_TRANSPORT.decode(context.window.DALYCARE_ATLAS_PAYLOAD)));"),probe)
 expect_equal(system2(Sys.which('node'),shQuote(c(probe,file.path(site,'DALYCARE_atlas_payload.js'),file.path(site,'DALYCARE_atlas_payload.json'),file.path(site,'atlas-transport.js'),decoded))),0L)
 core$payload <- jsonlite::fromJSON(decoded,simplifyVector=FALSE)
 expect_equal(bootstrap$build_id,catalogue$build_id);expect_equal(bootstrap$run_id,context$run_id);expect_equal(core$payload$run_id,context$run_id)
 for(t in catalogue$tables) for(shard in t$shards) {
  text <- paste(readLines(file.path(site,shard$src),encoding='UTF-8'),collapse='\n')
  data <- jsonlite::fromJSON(sub('\\);\\s*$','',sub('^window.DALYCARE_OUTPUTS.register\\(','',text)),simplifyVector=FALSE)
  expect_equal(data$build_id,catalogue$build_id);expect_equal(data$table_id,t$id);expect_equal(data$shard_id,shard$id)
  expect_equal(nchar(enc2utf8(data$rows_json),type='bytes'),shard$bytes)
 }
 invisible(list(core=core,catalogue=catalogue,context=context))
}
# Execute the real RStudio one-click entry, retaining its public global result.
Sys.unsetenv('DALYCARE_ATLAS_SOURCE_ONLY')
Sys.setenv(DALYCARE_ATLAS_SOURCE_MAP='config/source-map.example.tsv',DALYCARE_ATLAS_OUTPUT_ROOT=file.path(work,'one-click'),DALYCARE_ATLAS_MODE='report')
sys.source(file.path(root,'RUN_DALYCARE_ATLAS_73_SOURCE.R'),envir=new.env(parent=.GlobalEnv))
expect_false(isTRUE(get('dalycare_atlas_failed',envir=.GlobalEnv)))
one <- get('dalycare_atlas_result',envir=.GlobalEnv);accepted <- accept_site(one$run_dir)
# Actual standalone CLI, not a mocked helper call.
Sys.unsetenv('DALYCARE_ATLAS_SOURCE_ONLY')
cli_out <- file.path(work,'cli')
child(c(file.path(root,'scripts/run_atlas.R'),root,'config/source-map.example.tsv',cli_out,'report'))
cli_runs <- list.dirs(cli_out,recursive=FALSE,full.names=TRUE);expect_equal(length(cli_runs),1L);accept_site(cli_runs[[1]])
# The unchanged real standalone CLI can still produce genuine v1 via environment.
Sys.setenv(DALYCARE_ATLAS_TRANSPORT_VERSION='1')
v1_out <- file.path(work,'cli-requested-v1')
child(c(file.path(root,'scripts/run_atlas.R'),root,'config/source-map.example.tsv',v1_out,'report'))
v1_runs <- list.dirs(v1_out,recursive=FALSE,full.names=TRUE);expect_equal(length(v1_runs),1L)
accept_site(v1_runs[[1]],transport_version=1L)
Sys.unsetenv('DALYCARE_ATLAS_TRANSPORT_VERSION')
# A harmless source metadata change must travel through the standalone offline rebuild.
source_path <- file.path(one$run_dir,'outputs/atlas_sources.csv')
rows <- read.csv(source_path,stringsAsFactors=FALSE,check.names=FALSE,na.strings='');rows$domain[[1]] <- 'Synthetic CSV acceptance sentinel';write_csv(rows,source_path)
rebuild_args <- c(file.path(root,'scripts/rebuild_atlas_from_outputs.R'),one$run_dir,root)
# A selected standalone binding must remain represented in each replacement manifest.
registry <- atlas_output_registry(root)
selected_spec <- Filter(function(s)s$id=='mcl_triangle_feasibility_cohort_counts_count_summary',registry$artifacts)[[1]]
selected_relative <- atlas_imported_mcl_path(selected_spec)
dir.create(dirname(file.path(one$run_dir,selected_relative)),recursive=TRUE,showWarnings=FALSE)
expect_true(file.copy(file.path(one$run_dir,selected_spec$source_file),file.path(one$run_dir,selected_relative)))
saved <- accepted$context;saved$bindings <- as.list(unique(c(unlist(saved$bindings),selected_spec$id)));saved$binding_files <- setNames(list(selected_relative),selected_spec$id)
jsonlite::write_json(saved,file.path(one$run_dir,'outputs/atlas_build_context.json'),auto_unbox=TRUE,null='null')

child(rebuild_args);after <- accept_site(one$run_dir)
expect_true(any(vapply(read_public_table(file.path(one$run_dir,'site'),'sources'),function(r)identical(r$domain,'Synthetic CSV acceptance sentinel'),logical(1))))
t <- Filter(function(t)t$id=='sources',after$catalogue$tables)[[1]]
shard_text <- paste(readLines(file.path(one$run_dir,'site',t$shards[[1]]$src),encoding='UTF-8'),collapse='\n')
expect_true(grepl('Synthetic CSV acceptance sentinel',shard_text,fixed=TRUE),'CSV change must reach the public table shard')
# Required errors must preserve every prior site asset and the manifest.
assets <- c(list.files(file.path(one$run_dir,'site'),recursive=TRUE,full.names=TRUE),file.path(one$run_dir,'outputs/output_manifest.csv'))
prior <- tools::md5sum(assets);backup <- readBin(source_path,'raw',n=file.info(source_path)$size)
file.rename(source_path,paste0(source_path,'.test-backup'));child(rebuild_args,FALSE);expect_equal(prior,tools::md5sum(assets));file.rename(paste0(source_path,'.test-backup'),source_path)
writeLines('unexpected_header\nsynthetic',source_path);child(rebuild_args,FALSE);expect_equal(prior,tools::md5sum(assets));writeBin(backup,source_path)
writeLines('table_name,domain\n"unterminated',source_path);child(rebuild_args,FALSE);expect_equal(prior,tools::md5sum(assets));writeBin(backup,source_path)
# Optional missing and header-only states remain distinct in an actual offline export.
registry <- atlas_output_registry(root)
reference_root <- file.path(work,'reference-project');dir.create(reference_root)
for(folder in c('R','scripts','inst','config')) expect_true(file.copy(file.path(root,folder),reference_root,recursive=TRUE))
optional <- Filter(function(s)s$id=='npu_display_dictionary',registry$artifacts)[[1]]
optional_path <- file.path(reference_root,optional$source_file)
file.rename(optional_path,paste0(optional_path,'.test-backup'))
reference_args <- c(file.path(reference_root,'scripts/rebuild_atlas_from_outputs.R'),one$run_dir,reference_root)
child(reference_args,FALSE);expect_equal(prior,tools::md5sum(assets))
schema <- optional$schemas[[which.max(lengths(optional$schemas))]]
write_csv(as.data.frame(lapply(schema,function(x)character()),stringsAsFactors=FALSE),optional_path)
child(reference_args,FALSE);expect_equal(prior,tools::md5sum(assets))
expect_true(file.copy(paste0(optional_path,'.test-backup'),optional_path,overwrite=TRUE))
child(reference_args);a <- accept_site(one$run_dir,reference_root);expect_equal(Filter(function(t)t$id==optional$id,a$catalogue$tables)[[1]]$status,'available')
summary_only_range <- review_temporal_summary(data.frame(table_name='S',domain='D',display_min_year=NA_real_,display_max_year=NA_real_),data.frame(domain='D',year=NA_real_))
expect_true(is.na(summary_only_range$n_year_rows[[1]]))
# Synthetic coverage regression: inferred range lengths disappear from descriptor scope.
coverage_run <- file.path(work,'coverage');dir.create(file.path(coverage_run,'outputs/panels'),recursive=TRUE)
spec <- Filter(function(s)s$id=='atlas_temporal_coverage_years',registry$artifacts)[[1]]
years <- function(end) {
 rows <- data.frame(table_name='S',domain='D',subdomain='D',atlas_role='events',date_column='ClinicalDate',year=1980:end,n_rows=NA_real_,pct_rows=NA_real_,coverage_basis='source_date_range')
 rows <- rbind(rows,transform(rows[1,],date_column='EventDate',year=2020,n_rows=1,pct_rows=1,coverage_basis='event_date_counts'))
 write_csv(rows,file.path(coverage_run,spec$source_file))
 Filter(function(t)t$id==spec$id,atlas_output_evidence(coverage_run,root))[[1]]
}
# A required clinical CSV with collapsing rows must rebuild through typed R assembly.
invisible(years(1982))
file.copy(file.path(coverage_run,spec$source_file),file.path(one$run_dir,spec$source_file),overwrite=TRUE)
child(rebuild_args)
range_core <- accept_site(one$run_dir)$core$payload
expect_equal(length(read_public_table(file.path(one$run_dir,'site'),'atlas_temporal_coverage_years')),2L)
# Only inferred rows also rebuild without aggregate() dropping every null year.
only_ranges <- read.csv(file.path(coverage_run,spec$source_file),stringsAsFactors=FALSE)
only_ranges <- only_ranges[only_ranges$coverage_basis=='source_date_range',]
write_csv(only_ranges,file.path(one$run_dir,spec$source_file))
child(rebuild_args);only_core <- accept_site(one$run_dir)$core$payload
expect_equal(length(read_public_table(file.path(one$run_dir,'site'),'atlas_temporal_coverage_years')),1L)

x <- years(1982);y <- years(2025);expect_equal(x,y);expect_true(is.null(x$source_row_count));expect_equal(x$represented_row_count,2L)
expect_true(is.null(x$rows[[1]]$year));expect_equal(x$rows[[2]]$date_column,'EventDate');expect_true(is.null(x$rows[[2]]$year));expect_true(is.null(x$rows[[2]]$n_rows))
# A supported label can remain while its numeric partition is withheld.
supported<-list(table_name='S',date_column='EventDate',coverage_basis='person_supported_label_only',year=2020,n_rows=10,pct_rows=50,support_k=5,person_support_safe=TRUE,outside_person_support_safe=TRUE,outside_record_support_safe=TRUE,partition_complete=FALSE)
supported_table<-Filter(function(t)t$id=='atlas_temporal_coverage_years',atlas_output_evidence(NULL,root,list(panels=list(atlas_temporal_coverage_years=list(supported)))))[[1]]
expect_equal(supported_table$rows[[1]]$year,2020);expect_true(is.null(supported_table$rows[[1]]$n_rows));expect_equal(supported_table$rows[[1]]$count_privacy_status,'withheld_partition_counts')
sp <- Filter(function(s)s$id=='atlas_spatial_region_counts',registry$artifacts)[[1]]
region <- data.frame(table_name='S',domain='D',subdomain='D',atlas_role='events',region_column='RegionCode',region_code='01',region_name='Synthetic',n_rows=1,pct_rows=1,count_basis='source_rows')
write_csv(region,file.path(coverage_run,sp$source_file));tab <- Filter(function(t)t$id==sp$id,atlas_output_evidence(coverage_run,root))[[1]]
expect_equal(tab$rows[[1]]$region_column,'RegionCode');expect_true(is.null(tab$rows[[1]]$n_rows))
# Shipped-resource fixture installation; the untouched DESCRIPTION has no
# maintainer email, so install only a copy with an explicitly synthetic contact.
package_copy <- file.path(work,'package-fixture');dir.create(package_copy)
for(item in c('R','inst','DESCRIPTION','NAMESPACE','LICENSE')) expect_true(file.copy(file.path(root,item),package_copy,recursive=TRUE))
description <- readLines(file.path(package_copy,'DESCRIPTION'),warn=FALSE)
description <- sub('role = c("aut", "cre")','email = "synthetic-maintainer@example.invalid", role = c("aut", "cre")',description,fixed=TRUE)
writeLines(description,file.path(package_copy,'DESCRIPTION'))
lib <- file.path(work,'library');dir.create(lib)
install_log <- file.path(work,'install.log')
status <- system2(file.path(R.home('bin'),if(.Platform$OS.type=='windows')'R.exe' else 'R'),shQuote(c('CMD','INSTALL',paste0('--library=',lib),package_copy)),stdout=install_log,stderr=install_log)
if(status!=0L) stop(paste(readLines(install_log,warn=FALSE),collapse='\n'))
.libPaths(c(lib,.libPaths()))
resources <- c('DALYCARE_atlas.html','DALYCARE_entry.html','DALYCARE_outputs.html','atlas-entry.js','atlas-outputs.js','atlas-transport.js','atlas-pages.css')
for(name in resources) expect_true(file.exists(system.file('templates',name,package='dalycareatlas')))
expect_true(file.exists(system.file('config','public-output-registry.json',package='dalycareatlas')))
expect_true(file.exists(system.file('config','clinical-source-membership.json',package='dalycareatlas')))
for(name in c('registry-summary-policy.json','public-measurement-policy.csv','source-map.dalycare73.tsv')) {
  expect_true(file.exists(system.file('config',name,package='dalycareatlas')))
}
installed <- system.file('templates','DALYCARE_entry.html',package='dalycareatlas')
installed_entry_text <- readLines(installed,encoding='UTF-8',warn=FALSE)
writeLines('STALE INSTALLED TEMPLATE',installed)
expect_equal(normalizePath(atlas_bundle_resource('DALYCARE_entry.html',root),winslash='/'),paste0(root,'/inst/templates/DALYCARE_entry.html'))
empty_root <- file.path(work,'empty');dir.create(empty_root)
expect_equal(normalizePath(atlas_bundle_resource('DALYCARE_entry.html',empty_root),winslash='/'),normalizePath(installed,winslash='/'))
writeLines(installed_entry_text,installed,useBytes=TRUE)
# Exercise R-only publication from the installed namespace and an empty project
# root; no checkout/Python resolver may supply the required membership resource.
installed_member <- system.file('config','clinical-source-membership.json',package='dalycareatlas')
installed_member_text <- readLines(installed_member,encoding='UTF-8',warn=FALSE)
installed_spec <- getFromNamespace('load_clinical_source_membership','dalycareatlas')(empty_root)
expect_equal(installed_spec$inventory_version,'2026-10-11-clinical-source-1')
namespace_publish <- getFromNamespace('write_static_atlas','dalycareatlas')
installed_run <- file.path(work,'installed-only');dir.create(installed_run)
installed_payload <- list(run_id='installed-only',catalog_rows=list(),review_infrastructure_sections=list(),
  clinical_source_inventory=getFromNamespace('clinical_source_inventory','dalycareatlas')(list(),installed_spec))
installed_paths <- namespace_publish(installed_run,installed_payload,empty_root,output_evidence=list())
installed_manifest <- read.csv(installed_paths$manifest,stringsAsFactors=FALSE,check.names=FALSE)
member_row <- installed_manifest[installed_manifest$artifact_id=='clinical_source_membership',,drop=FALSE]
expect_equal(nrow(member_row),1L)
expect_equal(member_row$clinical_source_inventory_version,installed_spec$inventory_version)
installed_assets <- list.files(file.path(installed_run,'site'),recursive=TRUE,full.names=TRUE)
installed_before <- tools::md5sum(c(installed_assets,installed_paths$manifest))
for(invalid in c('malformed','missing')) {
  if(invalid=='malformed') writeLines('{"schema_version":999}',installed_member) else unlink(installed_member)
  rejected <- tryCatch(namespace_publish(installed_run,installed_payload,empty_root,output_evidence=list()),error=identity)
  expect_true(inherits(rejected,'error'),'Required installed membership failure must reject publication.')
  expect_true(grepl('clinical-source-membership',conditionMessage(rejected),fixed=TRUE))
  expect_equal(tools::md5sum(c(installed_assets,installed_paths$manifest)),installed_before)
  writeLines(installed_member_text,installed_member,useBytes=TRUE)
}
installed_registry <- system.file('config','public-output-registry.json',package='dalycareatlas');writeLines('{"schema_version":999}',installed_registry)
expect_equal(atlas_output_registry(root)$schema_version,1L)
expect_equal(system2('git',c('check-ignore','--quiet','site/acceptance.js')),0L)
cat('Iteration 10 actual one-click, CLI, offline rebuild, rollback, manifest, coverage and installed-resource fixture acceptance passed\n')
