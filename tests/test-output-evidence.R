root <- normalizePath(getwd(), winslash='/')
source('tests/helper.R'); source_test_runtime(root)
expect_true(exists('atlas_payload_from_run_outputs', mode='function'), 'Strict CSV reconstruction entry point is missing')
# Removing strict required reads or reverting to stale payloads must fail these assertions.
r <- run_atlas(root, 'config/source-map.example.tsv', tempfile('evidence-run-'), 'report')
a <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_equal(a$payload,atlas_payload_from_run_outputs(r$run_dir,root)$payload)
p <- file.path(r$run_dir,'outputs/atlas_sources.csv')
x <- read.csv(p,colClasses='character',check.names=FALSE,na.strings='',fileEncoding='UTF-8')
x$domain[1] <- 'Reviewed synthetic domain'; write_csv(x,p)
b <- atlas_payload_from_run_outputs(r$run_dir,root)
expect_true(any(vapply(b$payload$sources,function(x) identical(x$domain,'Reviewed synthetic domain'),logical(1))))
expect_false(identical(a$payload,b$payload))
expect_error <- function(expr) expect_true(inherits(tryCatch({force(expr);NULL},error=identity),'error'))
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
