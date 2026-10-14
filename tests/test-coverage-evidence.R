source('tests/helper.R'); source_test_runtime()
Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_DATE_FORMATS_FILE'))
# One person occurs in both years: outside people are not total minus cell people.
d <- data.frame(patientid=c(1:10,1),event_date=c(rep('2024-01-01',5),rep('2025-01-01',5),'2025-02-01'),Region=c(rep('Capital',3),rep('Region Hovedstaden',2),rep('Zealand',6)))
e <- coverage_evidence_from_data(d,'RKKP_CLL','event_date','year')
expect_equal(e$outside_person_count[e$group_value=='2024'],6)
expect_equal(e$outside_person_count[e$group_value=='2025'],5)
expect_true(all(e$release_status=='published'))
tampered<-e;tampered$collection_status<-'budget_skipped'
expect_true(all(coverage_gate(tampered)$release_status=='budget_skipped'))
tampered<-e;tampered$person_count<-0
expect_true(all(coverage_gate(tampered)$release_status=='withheld_privacy'))
tampered<-e;tampered$outside_person_count[1]<-NA
expect_true(all(coverage_gate(tampered)$release_status=='withheld_privacy'))
r <- coverage_evidence_from_data(d,'RKKP_CLL','Region','region')
expect_equal(r$record_count[r$group_value=='1084'],5)
expect_equal(r$person_count[r$group_value=='1084'],5)
# A single outside record must withhold the partition, despite overlapping people.
rare <- d[c(1:5,11),]; rare$event_date[6] <- '2025-01-01'
expect_true(all(coverage_evidence_from_data(rare,'RKKP_CLL','event_date','year')$release_status=='withheld_privacy'))
one <- d;one$patientid<-1
expect_true(all(coverage_evidence_from_data(one,'RKKP_CLL','event_date','year')$release_status=='withheld_privacy'))
expect_true(all(coverage_evidence_from_data(d,'SP_VitaleVaerdier','event_date','year')$release_status=='needs_person_key'))
d$patientid[1]<-NA
expect_true(all(coverage_evidence_from_data(d,'RKKP_CLL','event_date','year')$release_status=='missing_person_key'))
q <- data.frame(patientid=1:20,event_date=rep(c('2024-01-01',NA,'01/02/03','9999-12-31'),each=5))
quality <- coverage_evidence_from_data(q,'RKKP_CLL','event_date','date_quality')
expect_true(setequal(quality$group_value,c('valid','missing','unrecognised','outside_display_range')))
expect_true(!any(grepl('sentinel',quality$group_value)))
expect_true(all(is.na(normalize_dk_region(c('north confidential text','central person name')))))
sources <- data.frame(table_name='RKKP_CLL',domain='RKKP',load_status='ok',n_rows=100)
legacy <- list(atlas_temporal_coverage_years=data.frame(table_name='RKKP_CLL',date_column='event_date',year=2024,n_rows=100),
 atlas_spatial_region_counts=data.frame(table_name='RKKP_CLL',domain='RKKP',region_code='1084',n_rows=100))
safe <- coverage_release_panels(legacy,sources)
expect_equal(nrow(safe$atlas_temporal_coverage_years),0L)
expect_equal(nrow(safe$atlas_spatial_region_counts),0L)
safe <- coverage_release_panels(list(coverage_evidence=r),sources)
spatial <- panel_atlas_spatial_region_coverage(sources,safe$atlas_spatial_region_counts)
expect_equal(spatial$n_rows[spatial$domain=='RKKP' & spatial$region_code=='1084'],5)
expect_true(all(is.na(spatial$n_rows[spatial$domain=='RKKP' & spatial$region_code=='1081'])))
expect_true(all(is.na(panel_atlas_temporal_coverage(sources,data.frame())$raw_min_date)))
sources$min_date<-'2010-01-01';sources$max_date<-'2025-01-01'
profiles<-data.frame(table_name='RKKP_CLL',column_name='event_date',profile_kind='date',is_sensitive=FALSE,n_available=0,min_date=NA_character_,max_date=NA_character_,pct_available=0)
selected<-panel_atlas_temporal_coverage(sources,profiles)
expect_equal(selected$date_column,'event_date')
expect_true(is.na(selected$raw_min_date)&&is.na(selected$raw_max_date),'Selected field must never borrow another field/source bounds.')
# Unavailable DB paths carry bounded statuses and never fall back to row counts.
profiles<-profile_column_profiles(q,'RKKP_CLL')
budget<-list(should_skip=function(...)TRUE,add_log=function(...)stop('Skipped query must not execute'))
skipped<-dbi_coverage_evidence(NULL,'unused',profiles,sources,budget_context=budget)
expect_true(all(skipped$collection_status[skipped$dimension!='region']=='budget_skipped'))
expect_true(all(is.na(skipped$record_count)))
failed<-dbi_coverage_evidence(DBI::ANSI(),'unused',profiles,sources)
expect_true(all(failed$collection_status[failed$dimension!='region']=='query_failed'))
expect_true(all(is.na(failed$person_count)))
cat('PASS exact person/complement coverage evidence and honest legacy limitations\n')
