source('tests/helper.R');source_test_runtime()
failures <- list()
check <- function(name,expr) {
  error <- tryCatch({force(expr);NULL},error=function(e)conditionMessage(e))
  if(!is.null(error)) failures[[name]] <<- error
}
source <- data.frame(table_name='S')
columns <- data.frame(table_name='S',column_name=c('name','result_a','result_b','analysis_a','analysis_b'))
saved_panel <- list(vital_descriptors=data.frame(source_name='S',name_col='name',value_col='result_a',descriptor='Puls'))
saved <- build_semantic_outputs(getwd(),source,columns,saved_panel)$dictionary
saved$n_rows[saved$data_shape=='long_descriptor_table'] <- 25
saved$semantic_meaning[saved$data_shape=='long_descriptor_table'] <- 'Explicit saved pulse definition'
check('B1-unassessed',{
  for(panel in list(list(),list(vital_descriptors=data.frame()),list(vital_descriptors=data.frame(source_name='S',name_col='name',value_col='result_a',descriptor='Temp.')))) {
    result <- semantic_rehydrate_args(list(sources=source,column_profiles=columns,panels=panel,semantic_dictionary=saved),getwd())
    pulse <- result$semantic_dictionary[result$semantic_dictionary$raw_descriptor=='Puls' & !is.na(result$semantic_dictionary$raw_descriptor),,drop=FALSE]
    expect_equal(nrow(pulse),1L,'Absent, empty or partial descriptor inventory cannot delete a saved valid context.')
    expect_equal(pulse$semantic_meaning[[1]],'Explicit saved pulse definition')
    expect_equal(pulse$mapping_status[[1]],'saved_definition_inventory_unassessed','Retained definition must not imply current inventory assessment.')
    expect_true(is.na(pulse$n_rows[[1]]) && is.na(pulse$n_patients[[1]]),'Saved definitions must not manufacture current observation counts.')
  }
})
check('B1-assessed',{
  assessment <- data.frame(source_name='S',name_col='name',value_col='result_a',inventory_status='assessed_complete')
  args <- list(sources=source,column_profiles=columns,panels=list(vital_descriptor_assessment=assessment),semantic_dictionary=saved)
  result <- semantic_rehydrate_args(args,getwd())
  expect_false(any(result$semantic_dictionary$raw_descriptor=='Puls',na.rm=TRUE),'Only explicit complete scope may establish descriptor absence.')
  args$panels$vital_descriptor_assessment$value_col <- 'result_b'
  expect_true(any(semantic_rehydrate_args(args,getwd())$semantic_dictionary$raw_descriptor=='Puls',na.rm=TRUE),'Complete scope for another result field cannot delete this saved context.')
  args$column_profiles <- columns[columns$column_name!='result_a',]
  expect_false(any(semantic_rehydrate_args(args,getwd())$semantic_dictionary$raw_descriptor=='Puls',na.rm=TRUE),'A missing current result field invalidates the saved context.')
})
check('B4-partial-code-map',{
  inventory <- data.frame(table_name='S',code_column=c('analysis_a','analysis_a','analysis_b'),lab_code=c('NPU04998','NPU99999','NPU04998'))
  panels <- list(lab_npu_code_coverage=inventory)
  direct <- build_semantic_outputs(getwd(),source,columns,panels)
  partial <- direct$code_map[1,,drop=FALSE]
  partial$n_rows <- 25;partial$code_name <- 'Explicit current creatinine label'
  args <- list(sources=source,column_profiles=columns,panels=panels,semantic_dictionary=direct$dictionary,semantic_code_map=partial)
  result <- semantic_rehydrate_args(args,getwd())$semantic_code_map
  expect_equal(nrow(result),3L,'Partial saved maps must append known/unknown current inventory and separate fields.')
  expect_true('raw_column' %in% names(result),'Current code-map lineage needs an explicit exact field.')
  expect_true(any(result$code=='NPU99999' & result$code_name=='Description unavailable'))
  expect_true(any(result$code=='NPU04998' & result$raw_column=='analysis_a' & result$n_rows==25,na.rm=TRUE),'Explicit current evidence remains intact.')
  expect_true(any(result$code=='NPU04998' & result$raw_column=='analysis_b' & is.na(result$n_rows)),'Other field context remains separate and receives no invented count.')
  rebuilt <- semantic_rehydrate_args(args,getwd())
  expect_true(any(rebuilt$panel_distributions$raw_code=='NPU04998' & rebuilt$panel_distributions$raw_column=='analysis_b',na.rm=TRUE),'Distinct exact code fields must survive into downstream distributions.')
  recovered <- partial;recovered$raw_column <- NULL;args$semantic_code_map <- recovered
  expect_equal(nrow(semantic_rehydrate_args(args,getwd())$semantic_code_map),3L,'Exact stable-ID lineage recovery must not duplicate an existing context.')
  legacy <- partial;legacy$semantic_id <- 'legacy_without_field';legacy$raw_column <- NULL
  args$semantic_code_map <- legacy
  result <- semantic_rehydrate_args(args,getwd())$semantic_code_map
  expect_equal(nrow(result),4L,'Unscoped legacy evidence cannot swallow any exact current field context.')
  expect_true(any(grepl('field lineage unavailable',result$notes,fixed=TRUE)),'Legacy missing lineage remains explicit.')
  spec <- Filter(function(x)x$id=='semantic_code_map',atlas_output_registry(getwd())$artifacts)[[1]]
  file <- tempfile(fileext='.csv');write_csv(result,file)
  expect_equal(nrow(atlas_read_registered_csv(file,spec)),4L,'Exact current code-map schema must round-trip.')
  legacy_frame <- result;legacy_frame$raw_column <- NULL;write_csv(legacy_frame,file)
  expect_equal(nrow(atlas_read_registered_csv(file,spec)),4L,'Legacy code-map schema remains readable without invented lineage.')
})
if(length(failures)) {
  for(name in names(failures)) cat(name,':',failures[[name]],'\n')
  quit(status=1)
}
cat('Saved descriptor scopes and partial current code-map reconciliation passed.\n')
