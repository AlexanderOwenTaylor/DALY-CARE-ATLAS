source('tests/helper.R');source_test_runtime();source('R/public_privacy.R')
p<-list(column_profile_rows=list(list(table_name='x',column_name='value',profile_kind='numeric',n_available=1,n_missing=9,sampling_method='algorithm_r_reservoir',sample_size=1,eligible_n=1,sampling_complete=TRUE)),
 panels=list(atlas_temporal_coverage_years=list(list(table_name='x',date_column='event_date',year=2024,n_rows=100,pct_rows=100,coverage_basis='event_date_counts')),
 atlas_spatial_region_counts=list(list(table_name='x',region_column='Region',region_code='1084',region_name='Capital',n_rows=100,count_basis='region_column_counts'))))
safe<-atlas_public_privacy(p,'.')
expect_true(is.null(safe$column_profile_rows[[1]]$sample_size))
expect_true(is.null(safe$column_profile_rows[[1]]$eligible_n))
expect_true(is.null(safe$panels$atlas_temporal_coverage_years[[1]]$year))
expect_true(is.null(safe$panels$atlas_spatial_region_counts[[1]]$region_code))
# Exact A=5, B=9 and total people=10 would reveal the protected intersection=4.
d<-data.frame(patientid=c(1:5,2:10),event_date=c(rep('2024-01-01',5),rep('2025-01-01',9)))
e<-coverage_evidence_panels_from_data(d,'RKKP_CLL')$coverage_evidence
expect_equal(e$person_count[e$dimension=='year'],c(5,9))
rows<-coverage_release_panels(list(coverage_evidence=e),data.frame(table_name='RKKP_CLL'))$atlas_temporal_coverage_years
published<-atlas_public_privacy(list(panels=list(atlas_temporal_coverage_years=atlas_evidence_rows(rows))),'.')$panels$atlas_temporal_coverage_years
expect_equal(vapply(published,function(x)as.numeric(x$n_rows),numeric(1)),c(5,9))
expect_true(all(vapply(published,function(x)all(vapply(x[intersect(names(x),c('person_count','outside_person_count','outside_record_count','total_person_count'))],is.null,logical(1))),logical(1))),
 'Private overlapping person support must not become a public series or reveal an intersection.')
# Rare unknown partitions withhold counts but do not erase independently safe labels.
d<-data.frame(patientid=1:21,event_date=c(rep('2024-01-01',10),rep('2025-01-01',10),'bad'),
 Region=c(rep('Capital',10),rep('Zealand',10),'PRIVATE UNKNOWN'))
e<-coverage_evidence_panels_from_data(d,'RKKP_CLL')$coverage_evidence
rows<-coverage_release_panels(list(coverage_evidence=e),data.frame(table_name='RKKP_CLL'))
expect_equal(rows$atlas_temporal_coverage_years$year,c(2024L,2025L))
expect_true(all(is.na(rows$atlas_temporal_coverage_years$n_rows)))
expect_equal(rows$atlas_spatial_region_counts$region_code,c('1084','1085'))
expect_true(all(is.na(rows$atlas_spatial_region_counts$n_rows)))
published<-atlas_public_privacy(list(panels=lapply(rows[c('atlas_temporal_coverage_years','atlas_spatial_region_counts')],atlas_evidence_rows)),'.')$panels
expect_equal(vapply(published$atlas_temporal_coverage_years,function(x)as.integer(x$year),integer(1)),c(2024L,2025L))
expect_true(all(vapply(published$atlas_temporal_coverage_years,function(x)is.null(x$n_rows)&&identical(x$count_privacy_status,'withheld_partition_counts'),logical(1))))
expect_false(any(grepl('PRIVATE UNKNOWN',unlist(published))))
cat('PASS sampling metadata, legacy unsupported bins, overlap protection and supported label-only membership\n')
