# Synthetic unit-policy input only. Never authoritative production evidence.
registry_v2_test_setup <- function(root='.') {
  work<-file.path(root,'.artifact-temp/registry-v2');dir.create(work,recursive=TRUE,showWarnings=FALSE)
  p<-list(version='registry-numeric-policy-v1',policies=list(list(numeric_policy_id='synthetic-haemoglobin-v1',table_name='RKKP_DaMyDa',source_column='Reg_Haemoglobin',unit_code='synthetic-unit',edges=list(0,10,20,40,NULL),levels=list(list(0,1,2,3,4),list(0,2,3,4),list(0,3,4)),minimum_people=20,constant_policy='withhold')))
  b<-list(version='registry-unit-evidence-v2',bindings=list(list(table_name='RKKP_DaMyDa',source_column='Reg_Haemoglobin',unit_code='synthetic-unit',stored_to_display_multiplier=1,stored_to_display_offset=0,evidence_id='SYNTHETIC-TEST-ONLY',evidence_source='synthetic fixture',evidence_revision='1',evidence_checksum=paste(rep('a',64),collapse=''),review_status='verified',numeric_policy_id='synthetic-haemoglobin-v1',evidence_tier='authoritative_source_metadata')))
  jsonlite::write_json(p,file.path(work,'policy.json'),auto_unbox=TRUE,null='null',pretty=TRUE)
  b$bindings[[1]]$numeric_policy_version<-'registry-numeric-policy-v1'
  b$bindings[[1]]$numeric_policy_checksum<-digest::digest(readBin(file.path(work,'policy.json'),'raw',n=file.info(file.path(work,'policy.json'))$size),algo='sha256',serialize=FALSE)
  jsonlite::write_json(b,file.path(work,'unit.json'),auto_unbox=TRUE,null='null',pretty=TRUE)
  Sys.setenv(DALYCARE_REGISTRY_NUMERIC_POLICY_FILE=file.path(work,'policy.json'),DALYCARE_REGISTRY_UNIT_EVIDENCE_FILE=file.path(work,'unit.json'))
  work
}
