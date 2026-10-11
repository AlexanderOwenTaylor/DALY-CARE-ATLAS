root <- normalizePath(getwd(), winslash='/')
source('tests/helper.R'); source_test_runtime(root)
expect_true(exists('atlas_payload_from_run_outputs', mode='function'), 'Strict CSV reconstruction entry point is missing')
expect_error <- function(expr) expect_true(inherits(tryCatch({force(expr);NULL},error=identity),'error'))
# Removing strict required reads or reverting to stale payloads must fail these assertions.
r <- run_atlas(root, 'config/source-map.example.tsv', tempfile('evidence-run-'), 'report')
a <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_equal(a$payload,atlas_payload_from_run_outputs(r$run_dir,root)$payload)
# Selected standalone counts must survive missing or conflicting local files.
selected_dir <- tempfile('selected-mcl-');dir.create(selected_dir)
registry <- atlas_output_registry(root)
count_spec <- Filter(function(s)s$id=='mcl_triangle_feasibility_cohort_counts_count_summary',registry$artifacts)[[1]]
selected <- mcl_count_empty_summary()[1,,drop=FALSE]
for(key in c('count_mode','source_tables','person_key_used','date_anchor_used','value_rule_used','generated_at','validation_status')) selected[[key]] <- NA_character_
selected$metric <- 'synthetic_count';selected$label <- 'Selected source';selected$value <- '23'
selected$status <- 'available'
selected_file <- file.path(selected_dir,basename(count_spec$source_file));write_csv(selected,selected_file)
expect_equal(atlas_read_selected_mcl_outputs(selected_dir,root)$count_summary$value,'23')
writeLines('UNREVIEWED_HEADER\nFORBIDDEN_BODY',selected_file)
expect_error(atlas_read_selected_mcl_outputs(selected_dir,root))
write_csv(selected,selected_file)
Sys.setenv(DALYCARE_ATLAS_INPUT_MAX_BYTES='10')
expect_error(atlas_read_selected_mcl_outputs(selected_dir,root))
Sys.unsetenv('DALYCARE_ATLAS_INPUT_MAX_BYTES')
# Reconstruct the existing production arguments as typed tables, then supply the
# selected-source module exactly as the runner does before its save handoff.
save_args <- list(run_id=a$context$run_id,generated_at=a$context$generated_at)
for(spec in registry$artifacts) if(spec$id %in% unlist(a$context$bindings)) {
 save_args <- atlas_evidence_set(save_args,unlist(spec$arg_path),atlas_read_registered_csv(file.path(r$run_dir,spec$source_file),spec))
}
save_args$patobank_ki67_percent$query_templates <- ''
save_args$mcl_triangle_feasibility$cohort_counts <- list(count_summary=selected)
selection <- mcl_count_empty_standalone_output_source()[1,,drop=FALSE]
selection$source_type <- 'explicit_dir';selection$source_path <- selected_dir
selection$selected_outputs_dir <- selected_dir;selection$selected <- TRUE
save_args$mcl_triangle_feasibility$standalone_output_source <- selection
local_file <- file.path(r$run_dir,count_spec$source_file)
conflict <- selected;conflict$value <- '91';conflict$label <- 'Current run conflict';write_csv(conflict,local_file)
atlas_save_build_context(r$run_dir,save_args,list(),list(),root)
chosen <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_equal(chosen$payload$mcl_triangle_feasibility$cohort_counts$count_summary[[1]]$value,'23','Selected source must beat the conflicting current-run CSV')
expect_equal(read.csv(local_file,colClasses='character')$value,'91','Import must preserve unrelated current-run outputs')
unlink(local_file)
save_args$mcl_triangle_feasibility$standalone_output_source$source_type <- 'bundled_output5_fixture'
atlas_save_build_context(r$run_dir,save_args,list(),list(),root)
# Removing only this synthetic source file makes the external input unavailable.
unlink(selected_file)
chosen <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_equal(chosen$payload$mcl_triangle_feasibility$cohort_counts$count_summary[[1]]$value,'23','Rebuild must use the confined imported CSV after the original disappears')
expect_equal(chosen$payload$mcl_triangle_feasibility$standalone_output_source[[1]]$source_type,'bundled_output5_fixture')
expect_equal(chosen$payload$mcl_triangle_feasibility$standalone_output_source[[1]]$selected_outputs_dir,selected_dir)
context_path <- file.path(r$run_dir,'outputs/atlas_build_context.json')
context_backup <- readBin(context_path,'raw',n=file.info(context_path)$size)
forged <- chosen$context;forged$binding_files[[count_spec$id]] <- '../escape.csv'
jsonlite::write_json(forged,context_path,auto_unbox=TRUE,null='null')
expect_error(atlas_payload_from_run_outputs(r$run_dir,root))
writeBin(context_backup,context_path)
p <- file.path(r$run_dir,'outputs/atlas_sources.csv')
x <- read.csv(p,colClasses='character',check.names=FALSE,na.strings='',fileEncoding='UTF-8')
x$domain[1] <- 'Reviewed synthetic domain'; write_csv(x,p)
b <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_true(any(vapply(b$payload$sources,function(x) identical(x$domain,'Reviewed synthetic domain'),logical(1))))
expect_false(identical(a$payload,b$payload))
backup <- readBin(p,'raw',n=file.info(p)$size)
unlink(p); expect_error(atlas_payload_from_run_outputs(r$run_dir,root)); writeBin(backup,p)
writeLines('FORBIDDEN_HEADER\nFORBIDDEN_BODY',p); expect_error(atlas_payload_from_run_outputs(r$run_dir,root)); writeBin(backup,p)
writeLines('table_name,domain\n"unterminated',p); expect_error(atlas_payload_from_run_outputs(r$run_dir,root)); writeBin(backup,p)
expect_error(atlas_confined_path(r$run_dir,'../escape.csv'))
f <- file.path(r$run_dir,'outputs/panels/registry_clinical_summary.csv')
rows <- read.csv('tests/fixtures/output-evidence-distribution.csv',stringsAsFactors=FALSE,na.strings='')
write_csv(rows,f)
writeLines('FORBIDDEN_HEADER\nFORBIDDEN_BODY',file.path(r$run_dir,'outputs/FORBIDDEN_FILENAME.csv'))
tables <- atlas_output_evidence(r$run_dir,root)
t <- Filter(function(x) x$id=='registry_clinical_summary',tables)[[1]]
expect_equal(length(t$rows),5201L);expect_true(t$complete);expect_true(is.null(t$rows[[5201]]$n_rows))
expect_false(grepl('FORBIDDEN',jsonlite::toJSON(tables,auto_unbox=TRUE),fixed=TRUE))
write_csv(rows[FALSE,],f)
t <- Filter(function(x) x$id=='registry_clinical_summary',atlas_output_evidence(r$run_dir,root))[[1]]
expect_equal(t$status,'empty_output')
p <- file.path(r$run_dir,'outputs/typed.csv')
write_csv(data.frame(code=c('0012','0013'),label=c('Æble,\n東京',NA),n=c(0,NA)),p)
typed <- atlas_read_registered_csv(p,list(schemas=list(list(code='string',label='string',n='number'))))
expect_equal(typed$code,c('0012','0013'));expect_equal(typed$label[1],'Æble,\n東京');expect_equal(typed$n[1],0)
# A profile beyond the former 3,000-row cap governs a panel copy.
profile_path <- file.path(r$run_dir,'outputs/atlas_column_profiles.csv')
profiles <- read.csv(profile_path,stringsAsFactors=FALSE,check.names=FALSE,na.strings='')
profiles <- profiles[rep(1,3001),,drop=FALSE]
profiles$table_name <- paste0('S',seq_len(3001));profiles$column_name <- 'test'
profiles$n_rows <- 1000;profiles$n_available <- 998;profiles$n_missing <- c(rep(0,3000),2)
profiles$pct_available <- 99.8;profiles$pct_missing <- 0.2
profiles$n_distinct_capped <- 10;profiles$is_sensitive <- FALSE;profiles$is_numeric_like <- TRUE;profiles$is_date_like <- FALSE
profiles$profile_kind <- 'numeric';profiles$min <- 1;profiles$max <- 20;profiles$mean <- 5
write_csv(profiles,profile_path)
write_csv(data.frame(table_name='S3001',registry='DaMyDa',field='Test',source_column='test',unit='',n_available=998,pct_available=99.8,mean=5,median=5,p25=3,p75=7),file.path(r$run_dir,'outputs/panels/damyda_numeric_fields.csv'))
context_tables <- atlas_output_evidence(r$run_dir,root)
context_panel <- Filter(function(x)x$id=='damyda_numeric_fields',context_tables)[[1]]
expect_true(is.null(context_panel$rows[[1]]$n_available));expect_true(is.null(context_panel$rows[[1]]$mean))
clinical <- atlas_payload_from_run_outputs(r$run_dir,root)$payload
expect_true(is.null(clinical$panels$damyda_numeric_fields[[1]]$n_available))
snapshot <- atlas_output_evidence(NULL,root,list(panels=list(registry_clinical_summary=list(list(table_name='S',registry='LYFO',n_rows=20,n_cols=7,n_patients=20)))))
st <- Filter(function(x)x$id=='registry_clinical_summary',snapshot)[[1]]
expect_equal(st$status,'snapshot_preview');expect_true(is.null(st$source_row_count));expect_false(st$complete)
Sys.setenv(DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES='1')
expect_error(atlas_output_evidence(r$run_dir,root))
Sys.unsetenv('DALYCARE_ATLAS_PUBLIC_TABLE_MAX_BYTES')
manifest <- file.path(r$run_dir,'outputs/output_manifest.csv')
write_csv(data.frame(relative_path='../escape.csv'),manifest)
expect_error(atlas_output_evidence(r$run_dir,root))
message('Strict CSV evidence tests passed')
