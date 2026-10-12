root <- normalizePath('.', winslash='/')
source('tests/helper.R'); source_test_runtime(root)
Sys.unsetenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE')
for (table in c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL')) {
  expect_equal(registry_summary_person_key(table,c('patientid','cpr')),
               list(status='ok',key='patientid'), 'Exact registries must use the documented default patientid.')
  expect_equal(registry_summary_person_key(table,c('PatientID','cpr'))$status,'missing_person_key')
}
expect_equal(registry_summary_person_key('other_RKKP_LYFO','patientid')$status,'needs_person_key')
private <- tempfile(fileext='.csv')
for (mapping in list(
    data.frame(table_name='RKKP_LYFO',person_key='alternate',reviewed=TRUE),
    data.frame(table_name='RKKP_LYFO',person_key='patientid',reviewed=FALSE),
    data.frame(table_name='RKKP_CLL',person_key='patientid',reviewed=TRUE),
    data.frame(table_name='RKKP_LYFO',person_key='',reviewed=TRUE),
    data.frame(table_name='RKKP_LYFO',wrong='patientid',reviewed=TRUE),
    data.frame(table_name=c('RKKP_LYFO','RKKP_LYFO'),person_key='patientid',reviewed=TRUE))) {
  write.csv(mapping,private,row.names=FALSE)
  Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=private)
  result <- registry_summary_person_key('RKKP_LYFO',c('patientid','alternate'))
  if ('person_key' %in% names(mapping) && nrow(mapping)==1L && mapping$person_key[1]=='alternate') {
    expect_equal(result,list(status='ok',key='alternate'))
  } else expect_equal(result$status,'needs_person_key','Explicit malformed/disabled/absent source mapping must not fall back.')
}
Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=paste0(private,'.missing'))
expect_equal(registry_summary_person_key('RKKP_LYFO','patientid')$status,'needs_person_key')
Sys.unsetenv('DALYCARE_REGISTRY_PERSON_KEYS_FILE')
expect_equal(list.files(root,pattern='^RUN_.*[.]R$'),'RUN_DALYCARE_ATLAS_73_SOURCE.R')
expect_false(file.exists('inst/legacy/wommen_v06/RUN_CARTOGRAPHY_ATLAS.R'))
old <- read.delim('config/source-map.dalycare64.restored.tsv',check.names=FALSE,stringsAsFactors=FALSE)
map <- read.delim('config/source-map.dalycare73.tsv',check.names=FALSE,stringsAsFactors=FALSE)
expect_equal(nrow(map),73L)
expect_equal(map,old,'All source identities and reviewed modes must be retained; summary includes guarded detailed clinical producers.')
expect_true(all(map$profile_mode[map$table_name %in% c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL')]=='summary'))
sources <- data.frame(table_name=c('RKKP_LYFO','helper'),load_status=c('ok','failed'),profile_mode='summary')
requested <- data.frame(table_name=c('RKKP_LYFO','RKKP_CLL','helper'),profile_mode='summary')
specs <- Filter(function(f) f$table_name=='RKKP_LYFO',registry_summary_policy(root))
rows <- rbind(registry_summary_row(specs[[1]],'published',5),registry_summary_row(specs[[2]],'withheld_small_group',5),registry_summary_row(specs[[3]],'missing_person_key',5))
report <- atlas_completion_report(requested,sources,rows,root,'fixture-run','failed')
expect_equal(report$summary$value[report$summary$metric=='expected_sources'],'3')
expect_equal(report$summary$value[report$summary$metric=='profiled_sources'],'1')
expect_equal(report$summary$value[report$summary$metric=='coverage_status'],'partial')
expect_equal(report$registries$source_status[report$registries$table_name=='RKKP_CLL'],'source_unavailable')
lyfo <- report$registries[report$registries$table_name=='RKKP_LYFO',]
expect_equal(lyfo$published_fields,1L);expect_equal(lyfo$privacy_withheld_fields,1L);expect_equal(lyfo$key_issue_fields,1L)
expect_equal(report$summary$value[report$summary$metric=='build_status'],'failed')
expect_equal(report$summary$value[report$summary$metric=='registry_coverage_status'],'partial')
expect_equal(lyfo$missing_key_fields,1L)
expect_file('inst/config/source-map.dalycare73.tsv')
bad_root <- tempfile('bad-policy-');dir.create(file.path(bad_root,'inst/config'),recursive=TRUE)
writeLines('{"version":"invalid"}',file.path(bad_root,'inst/config/registry-summary-policy.json'))
bad <- atlas_completion_report(requested,sources,NULL,bad_root,'bad-policy','failed')
expect_equal(bad$summary$value[bad$summary$metric=='registry_coverage_status'],'unknown')
expect_true(all(bad$registries$policy_status=='unavailable'))
broken_root <- tempfile('broken-runtime-');dir.create(file.path(broken_root,'scripts'),recursive=TRUE)
file.copy('RUN_DALYCARE_ATLAS_73_SOURCE.R',broken_root)
writeLines('stop("synthetic runtime unavailable")',file.path(broken_root,'scripts/run_atlas.R'))
assign('dalycare_atlas_result',list(old=TRUE),envir=.GlobalEnv)
assign('dalycare_atlas_failed',FALSE,envir=.GlobalEnv)
loader_error <- tryCatch({source(file.path(broken_root,'RUN_DALYCARE_ATLAS_73_SOURCE.R'),local=new.env(parent=.GlobalEnv));NULL},error=function(e)e)
setwd(root)
expect_true(is.null(loader_error),'The one-click handler must also catch runtime loading failures.')
expect_true(dalycare_atlas_failed)
expect_false(exists('dalycare_atlas_result',envir=.GlobalEnv,inherits=FALSE))
cat('Runner73 mappings, override precedence, inventory, reviewed source map and completion contract passed\n')
