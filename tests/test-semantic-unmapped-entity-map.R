source('tests/helper.R')
source_test_runtime()
expect_stops <- function(expr,pattern) {
  e <- tryCatch({force(expr);NULL},error=function(e)conditionMessage(e))
  expect_true(!is.null(e) && grepl(pattern,e,ignore.case=TRUE),paste('Expected error:',pattern))
}
# Synthetic mappings exercise original resolution/conflict/privacy requirements.
systems <- c('ATC','SNOMED/pathology','SKS/procedure','ICD10/SKS_diagnosis','Danish_pathology_AEKI_Ki67_percent_code','NPU')
codes <- c('C03AB01','T06002','BWGC1','DD479B','AEKI030','NPU04998')
names <- c('Bendroflumethiazide','Bone marrow','Conventional external beam radiotherapy','Monoclonal B-cell lymphocytosis','Ki-67 coded percent value: 30%','Conflicting analyte')
rows <- as.data.frame(setNames(replicate(length(semantic_unmapped_entity_map_columns()),rep('',6),simplify=FALSE),semantic_unmapped_entity_map_columns()),stringsAsFactors=FALSE)
rows$code_system <- systems;rows$entity_code <- codes;rows$entity_scope_key <- paste(systems,codes,sep=':')
rows$fill_preferred_label <- names;rows$fill_denotation_definition <- paste('Synthetic reviewed meaning:',names)
rows$fill_clinical_domain <- c('Treatment','Pathology','Imaging','Diagnosis','Pathology','Laboratory')
rows$fill_specimen_or_context <- 'Synthetic context';rows$fill_unit_or_value_type <- 'Code definition only'
rows$source_tables <- 'SYNTHETIC';rows$source_files <- 'synthetic-inventory.tsv';rows$observed_count_max <- '99'
rows$observed_count_sum_across_surfaces_do_not_treat_as_unique <- '999'
validate_semantic_unmapped_entity_map(rows)
bad <- rows;bad$entity_scope_key <- NULL;expect_stops(validate_semantic_unmapped_entity_map(bad),'missing')
bad <- rows;bad$entity_scope_key[[2]] <- bad$entity_scope_key[[1]];expect_stops(validate_semantic_unmapped_entity_map(bad),'duplicate')
for(pair in list(c('010101-1234','CPR'),c('2020-01-01','date'),c('H\u00c3\u00b8jde','mojibake'))) {
  bad <- rows;bad$fill_preferred_label[[1]] <- pair[[1]];expect_stops(validate_semantic_unmapped_entity_map(bad),pair[[2]])
}
root <- tempfile();dir.create(root);dir.create(file.path(root,'config'))
write.table(rows,semantic_unmapped_entity_map_path(root),sep='\t',quote=TRUE,row.names=FALSE,fileEncoding='UTF-8')
existing <- semantic_code_row(semantic_id='current',clinical_concept_id='creatinine',clinical_variable='Creatinine',clinical_group='Laboratory',source_name='SYNTHETIC',code_system='NPU',code='NPU04998',code_name='Creatinine',mapping_confidence='high')
out <- semantic_build_unmapped_entity_overlay(root,empty_semantic_data_dictionary(),existing,5)
expect_equal(nrow(out$overlay),6L,'Every supplied mapping receives an outcome.')
expect_equal(nrow(out$conflicts),1L,'Conflicting analyte requires review.')
expect_equal(out$conflicts$entity_code[[1]],'NPU04998')
expect_equal(out$conflicts$mapping_status[[1]],'conflict_pending_review')
expect_true(all(out$overlay$overlay_action[1:5]=='wired_overlay'),'Nonconflicting exact code meanings resolve.')
expect_true(all(codes[1:5] %in% out$code_map$code),'Resolved mappings retain exact codes.')
expect_true(all(is.na(out$code_map$n_patients)) && all(is.na(out$dictionary$n_patients)),'Cross-surface counts cannot become patient counts.')
expect_false(any(out$code_map$code=='NPU04998'),'Conflicts cannot overwrite reviewed meanings.')
cat('Synthetic semantic overlay contract passed.\n')
