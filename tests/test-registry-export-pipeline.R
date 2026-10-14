# Full runner -> CSV -> guarded rebuild -> both site builders, synthetic data only.
root <- normalizePath('.',winslash='/')
source('tests/helper.R'); source_test_runtime(root)
work <- Sys.getenv('DALYCARE_REGISTRY_TEST_RUN_ROOT',unset=tempfile('registry-export-'))
dir.create(work,recursive=TRUE,showWarnings=FALSE)
work <- normalizePath(work,winslash='/')
policy <- jsonlite::fromJSON('inst/config/registry-summary-policy.json',simplifyVector=FALSE)
sources <- c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL')
Sys.unsetenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE')
source_map <- data.frame(table_name=sources,source_type='file',source='',priority=1:3,profile_mode='summary',domain='RKKP',subdomain=c('DaMyDa','LYFO','CLL'),atlas_role='clinical_registry')
expected <- list()
preferred <- list(
  c('Stadie','PB_Behandling_Bortezomib','PB_MaksimaleRespons','Reg_Haemoglobin'),
  c('Reg_Stadium','Beh_Kemoterapiregime1','Beh_Responsevaluering','Reg_Haemoglobin'),
  c('Reg_BinetStadium','Beh_TargeteretBeh_Ibrutinib','Beh_Responsevaluering','Reg_Leukocyttal')
)
for(i in seq_along(sources)) {
  fields <- Filter(function(f)f$table_name==sources[i],policy$fields)
  selected <- lapply(preferred[[i]],function(column) Filter(function(f) f$source_column==column,fields)[[1]])
  withheld <- Filter(function(f) f$kind=='categorical' && !f$source_column %in% preferred[[i]] && length(f$categories)>=2L, fields)[[1]]
  x <- data.frame(patientid=sprintf('SYNTHETIC_PRIVATE_PERSON_%03d',1:90))
  x[[withheld$source_column]] <- c(unlist(withheld$categories)[1],rep(unlist(withheld$categories)[2],89))
  for(f in selected) {
    values <- if(f$kind=='numeric') as.character(rep(6:11,each=10)) else rep(unlist(f$categories)[1:2],each=30)
    x[[f$source_column]] <- c(values,rep(NA_character_,10),rep(if(f$kind=='numeric') '-999' else 'SYNTHETIC_FORBIDDEN_CATEGORY',10),rep(values[1],10))
    if(f$kind=='categorical') expected[[length(expected)+1L]] <- paste(sources[i],f$source_column,sep='::')
  }
  repeated <- x[1:10,,drop=FALSE]
  conflict <- x[81:90,,drop=FALSE]
  for(f in selected) conflict[[f$source_column]] <- if(f$kind=='numeric') '19' else unlist(f$categories)[2]
  x <- rbind(x,repeated,conflict)
  source_map$source[i] <- file.path(work,paste0(sources[i],'.csv'))
  write.csv(x,source_map$source[i],row.names=FALSE,na='')
}
map_path <- file.path(work,'source-map.tsv');write.table(source_map,map_path,sep='\t',row.names=FALSE,quote=FALSE)
Sys.setenv(DALYCARE_ATLAS_SOURCE_MAP=map_path,DALYCARE_ATLAS_OUTPUT_ROOT=file.path(work,'runs'),DALYCARE_ATLAS_MODE='strict')
outside <- file.path(work,'outside');dir.create(outside,showWarnings=FALSE)
setwd(outside)
source(file.path(root,'RUN_DALYCARE_ATLAS_73_SOURCE.R'),local=new.env(parent=.GlobalEnv))
setwd(root)
expect_false(dalycare_atlas_failed)
run <- dalycare_atlas_result
Sys.unsetenv(c('DALYCARE_ATLAS_SOURCE_MAP','DALYCARE_ATLAS_OUTPUT_ROOT','DALYCARE_ATLAS_MODE'))
expect_file(file.path(run$run_dir,'outputs/atlas_completion_summary.csv'))
expect_file(file.path(run$run_dir,'outputs/atlas_registry_completion.csv'))
completion <- read.csv(file.path(run$run_dir,'outputs/atlas_registry_completion.csv'))
expect_true(all(completion$published_fields==3L))
expect_true(all(completion$field_unavailable_fields>0))
expect_true(all(completion$privacy_withheld_fields==1L))
expect_true(all(grepl('Privacy gates',completion$action,fixed=TRUE)))
manifest <- read.csv(file.path(run$run_dir,'outputs/output_manifest.csv'),stringsAsFactors=FALSE)
# Mutable completion state is intentionally outside the immutable build context.
expect_false(any(grepl('atlas_(completion_summary|registry_completion)[.]csv',as.character(unlist(manifest)))))
writeLines(run$run_dir,file.path(work,'latest-run.txt'))
csv <- file.path(run$run_dir,'outputs/panels/registry_field_summaries.csv')
expect_file(csv)
frame <- read.csv(csv,stringsAsFactors=FALSE,check.names=FALSE)
published <- frame[frame$summary_status=='published',,drop=FALSE]
expect_equal(sort(paste(published$table_name,published$source_column,sep='::')),sort(unlist(expected)))
expect_true(all(published$denominator_n==90 & published$n_valid==60 & published$n_missing==10 & published$n_unrecognised==10 & published$n_conflicting==10))
expect_true(all(published$unit_status=='unverified'))
rebuilt <- atlas_payload_from_run_outputs(run$run_dir,root)
rows <- rebuilt$payload$panels$registry_field_summaries
expect_equal(sum(vapply(rows,function(r)r$summary_status=='published',logical(1))),9L)
expect_true(all(vapply(Filter(function(r)r$summary_status=='published',rows),function(r)is.numeric(r$denominator_n),logical(1))))
atlas_evidence_audit(rebuilt$payload,root,5)
evidence <- Filter(function(t)t$id=='registry_field_summaries',rebuilt$tables)[[1]]
expect_equal(length(evidence$rows),length(rows))
expect_equal(evidence$rows,rows)
# Complete fields must survive repeat guarding and the production CSV rebuild entry point.
script <- file.path(root,'scripts/rebuild_atlas_from_outputs.R')
status <- system2(file.path(R.home('bin'),if(.Platform$OS.type=='windows') 'Rscript.exe' else 'Rscript'),shQuote(c(script,run$run_dir,root)),stdout=file.path(work,'rebuild.log'),stderr=file.path(work,'rebuild.log'))
expect_equal(status,0L,paste(readLines(file.path(work,'rebuild.log'),warn=FALSE),collapse='\n'))
after <- atlas_payload_from_run_outputs(run$run_dir,root)
expect_equal(after$payload$panels$registry_field_summaries,rows)
# Python rebuild validates the same exported contract and keeps both JS/JSON transports.
status <- system2(Sys.which('python'),shQuote(c('scripts/build_ui_iteration.py','--input-dir',file.path(run$run_dir,'site'),'--output-dir',file.path(work,'python-site'),'--run-dir',run$run_dir)),stdout=file.path(work,'python.log'),stderr=file.path(work,'python.log'))
expect_equal(status,0L,paste(readLines(file.path(work,'python.log'),warn=FALSE),collapse='\n'))
for(site in c(file.path(run$run_dir,'site'),file.path(work,'python-site'))) {
  paths <- list.files(site,recursive=TRUE,full.names=TRUE)
  texts <- vapply(paths,function(path)paste(readLines(path,warn=FALSE,encoding='UTF-8'),collapse='\n'),character(1))
  expect_false(any(grepl('SYNTHETIC_PRIVATE_PERSON_|SYNTHETIC_FORBIDDEN_CATEGORY',texts)))
  expect_file(file.path(site,'DALYCARE_clinical.html'))
  expect_file(file.path(site,'DALYCARE_atlas_payload.js'))
  expect_file(file.path(site,'DALYCARE_atlas_payload.json'))
}
# A changed threshold is reapplied to the complete exported evidence, not just the UI.
Sys.setenv(DALYCARE_MIN_CELL_COUNT='15')
raised <- atlas_payload_from_run_outputs(run$run_dir,root)$payload$panels$registry_field_summaries
expect_false(any(vapply(raised,function(r)r$summary_status=='published',logical(1))))
expect_true(all(vapply(raised,function(r)is.null(r$denominator_n) && is.null(r$approximate_mean) && r$category_counts_json=='[]',logical(1))))
Sys.unsetenv(c('DALYCARE_MIN_CELL_COUNT','DALYCARE_REGISTRY_PERSON_KEYS_FILE'))
cat('Automatic one-click three-registry runner, typed CSV round trip, R/Python bundles, repeated guards, byte absence and raised-threshold acceptance passed\n')
