source('tests/helper.R');source_test_runtime();source('R/public_privacy.R')
Sys.unsetenv(c('DALYCARE_REGISTRY_PERSON_KEYS_FILE','DALYCARE_DATE_FORMATS_FILE'))
data<-data.frame(patientid=c(1:10,1),event_date=c(rep('2024-01-01',5),rep('2025-01-01',5),'2025-02-01'),
 Region=c(rep('Capital',3),rep('Region Hovedstaden',2),rep('Zealand',6)))
rare<-data[c(1:5,11),]
evidence<-coverage_evidence_panels_from_data(rare,'RKKP_CLL')$coverage_evidence
expected<-c(year='withheld_privacy',region='withheld_privacy',date_quality='published',date_format='published')
for(dimension in names(expected)) {
 rows<-evidence[evidence$dimension==dimension,]
 expect_true(nrow(rows)>0&&all(rows$release_status==expected[[dimension]]))
 if(dimension%in%c('date_quality','date_format')) {
   expect_equal(rows$record_count,6);expect_equal(rows$person_count,5)
   expect_equal(rows$outside_record_count,0);expect_equal(rows$outside_person_count,0)
 } else {
   expect_equal(sort(rows$record_count),c(1,5));expect_equal(sort(rows$person_count),c(1,5))
 }
}
panels<-coverage_release_panels(list(coverage_evidence=evidence),data.frame(table_name='RKKP_CLL'))
public<-atlas_public_privacy(list(panels=lapply(panels,atlas_evidence_rows)),'.')$panels
expect_equal(length(public$atlas_temporal_coverage_years),0L)
expect_equal(length(public$atlas_spatial_region_counts),0L)
expect_equal(length(public$atlas_date_quality_counts),1L)
expect_equal(public$atlas_date_quality_counts[[1]]$quality_state,'valid')
expect_equal(as.numeric(public$atlas_date_quality_counts[[1]]$n_rows),6)
expect_true(is.null(public$atlas_date_quality_counts[[1]]$person_count))
expect_true(is.null(public$coverage_evidence)||length(public$coverage_evidence)==0L)
# These later integration assertions really do apply across all dimensions.
one<-data;one$patientid<-1
expect_true(all(coverage_evidence_panels_from_data(one,'RKKP_CLL')$coverage_evidence$release_status=='withheld_privacy'))
missing<-data;missing$patientid[1]<-NA
expect_true(all(coverage_evidence_panels_from_data(missing,'RKKP_CLL')$coverage_evidence$release_status=='missing_person_key'))
cat('PASS rare year/region withheld; homogeneous date quality/format supported; public has only valid-quality records6, no year/region/person evidence\n')
