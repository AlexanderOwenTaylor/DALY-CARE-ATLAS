source('tests/test-registry-private-diagnostics.R')
root<-normalizePath('.',winslash='/')
work<-Sys.getenv('DALYCARE_PRIVATE_DIAGNOSTIC_TEST_ROOT',unset=tempfile('private-diagnostic-publication-'))
dir.create(work,recursive=TRUE,showWarnings=FALSE);work<-normalizePath(work,winslash='/')
input<-file.path(work,'cll.csv');write.csv(data,input,row.names=FALSE)
map<-data.frame(table_name='RKKP_CLL',source_type='file',source=input,priority=1,profile_mode='summary',domain='RKKP',subdomain='CLL',atlas_role='clinical_registry')
map_path<-file.path(work,'map.tsv');write.table(map,map_path,sep='\t',quote=FALSE,row.names=FALSE)
run<-run_atlas(root,map_path,file.path(work,'runs'),mode='strict')
private_path<-file.path(run$run_dir,'outputs/panels/registry_interpretation_diagnostics.csv')
expect_file(private_path)
d<-read.csv(private_path);d<-d[d$source_column=='Beh_Immunterapi',]
expect_equal(d$n_valid,19L);expect_equal(d$n_unrecognised,1L)
expect_false(any(grepl('PRIVATE_PERSON_|UNMAPPED_SYNTHETIC',as.character(unlist(d)))))
internal_manifest<-read.csv(file.path(run$run_dir,'outputs/output_manifest.csv'))
expect_true('outputs/panels/registry_interpretation_diagnostics.csv' %in% internal_manifest$relative_path)
# Retain actual SQLite producer outputs and safe executed-query logs separately.
sql_dir<-file.path(work,'sql-internal');dir.create(sql_dir)
write.csv(attr(sql,'registry_interpretation_diagnostics'),file.path(sql_dir,'registry_interpretation_diagnostics.csv'),row.names=FALSE,na='')
write.csv(sql,file.path(sql_dir,'registry_field_summaries.csv'),row.names=FALSE,na='')
write.csv(budget$query_log(),file.path(sql_dir,'db_query_log.csv'),row.names=FALSE,na='')
for(name in c('failed','timeout','skipped'))write.csv(attr(get(name),'registry_interpretation_diagnostics'),file.path(sql_dir,paste0(name,'_registry_interpretation_diagnostics.csv')),row.names=FALSE,na='')
rebuilt<-atlas_payload_from_run_outputs(run$run_dir,root)
expect_false('registry_interpretation_diagnostics' %in% names(rebuilt$payload$panels))
rows<-rebuilt$payload$panels$registry_field_summaries
public<-Filter(function(r)r$table_name=='RKKP_CLL'&&r$source_column=='Beh_Immunterapi',rows)[[1]]
expect_equal(public$publication_status,'withheld_privacy');expect_true(is.null(public$n_valid)&&is.null(public$n_unrecognised))
# Direct stale/imported payload copies must lose the panel identity as well.
injected<-rebuilt$payload
injected$panels$registry_interpretation_diagnostics<-atlas_evidence_rows(attr(sql,'registry_interpretation_diagnostics'))
injected$nested<-list(registry_interpretation_diagnostics=injected$panels$registry_interpretation_diagnostics)
guarded<-atlas_public_privacy(injected,root)
expect_false(grepl('registry_interpretation_diagnostics',jsonlite::toJSON(guarded,auto_unbox=TRUE,null='null')))
full<-file.path(work,'full-import');dir.create(full)
# Feed the Python publication entry a stale copy to exercise its own exclusion.
wire<-atlas_transport_assets(atlas_payload_transport(injected),atlas_output_registry(root)$input_max_bytes)
writeLines(wire$script,file.path(full,'DALYCARE_atlas_payload.js'),useBytes=TRUE)
status<-system2(Sys.which('python'),shQuote(c('scripts/build_ui_iteration.py','--input-dir',full,'--output-dir',file.path(work,'python-site'),'--run-dir',run$run_dir)),stdout=file.path(work,'python-publication.log'),stderr=file.path(work,'python-publication.log'))
expect_equal(status,0L,paste(readLines(file.path(work,'python-publication.log'),warn=FALSE),collapse='\n'))
for(site in c(file.path(run$run_dir,'site'),file.path(work,'python-site'))) {
  manifest<-atlas_validate_public_site(site)
  archive<-atlas_package_site(site)
  paths<-list.files(site,recursive=TRUE,full.names=TRUE)
  expect_false(any(grepl('registry_interpretation_diagnostics',paths)))
  for(path in paths) {
    text<-rawToChar(readBin(path,'raw',n=file.info(path)$size))
    expect_false(grepl('registry_interpretation_diagnostics|PRIVATE_PERSON_|UNMAPPED_SYNTHETIC',text),paste('Private data in public asset',path))
  }
  members<-unzip(archive,list=TRUE)$Name
  expect_false(any(grepl('registry_interpretation_diagnostics',members)))
  unpack<-tempfile('public-zip-');dir.create(unpack);unzip(archive,exdir=unpack)
  for(path in list.files(unpack,recursive=TRUE,full.names=TRUE)) {
    text<-rawToChar(readBin(path,'raw',n=file.info(path)$size))
    expect_false(grepl('registry_interpretation_diagnostics|PRIVATE_PERSON_|UNMAPPED_SYNTHETIC',text))
  }
  unlink(unpack,recursive=TRUE)
  released<-read_public_table(site,'registry_field_summaries')
  r<-Filter(function(r)r$table_name=='RKKP_CLL'&&r$source_column=='Beh_Immunterapi',released)[[1]]
  expect_equal(r$publication_status,'withheld_privacy');expect_true(is.null(r$n_valid)&&is.null(r$n_unrecognised))
}
writeLines(run$run_dir,file.path(work,'retained-run.txt'))
cat('PASS retained memory/SQL internal CSV evidence and R/Python public CSV/JSON/JS/HTML/manifest/ZIP exclusion: ',work,'\n',sep='')
