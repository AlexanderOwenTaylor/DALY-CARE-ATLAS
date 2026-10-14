source('tests/helper.R');source_test_runtime()
check <- function(name,expr) {
  failure <- tryCatch({force(expr);NULL},error=function(e)conditionMessage(e))
  if(!is.null(failure)) failures[[name]] <<- failure
}
failures <- list()
sources <- data.frame(table_name='S')
columns <- data.frame(table_name='S',column_name=c('name','result_a','result_b','new_field'))
old_columns <- columns[1:3,]
old <- build_semantic_outputs(getwd(),sources,old_columns)
old$dictionary$semantic_meaning[[1]] <- 'Preserved current interpretation'
old_product <- build_product_layer_outputs(old,sources=sources)
panels <- list(vital_descriptors=data.frame(source_name='S',name_col='name',value_col=c('result_a','result_b'),descriptor='Puls'))
args <- list(sources=sources,column_profiles=columns,panels=panels,semantic_dictionary=old$dictionary,
  semantic_panel_links=old$panel_links,panel_raw_fields=old_product$panel_raw_fields,clinical_concepts=old_product$clinical_concepts)
stale <- old$dictionary[1,,drop=FALSE];stale$semantic_id <- 'stale';stale$source_name <- 'OLD';stale$raw_column <- 'removed'
args$semantic_dictionary <- rbind(args$semantic_dictionary,stale)
link <- old$panel_links[1,,drop=FALSE];link$semantic_id <- 'stale'
args$semantic_panel_links <- rbind(args$semantic_panel_links,link)
raw <- old_product$panel_raw_fields[1,,drop=FALSE];raw$semantic_id <- 'stale';raw$source_name <- 'OLD'
args$panel_raw_fields <- rbind(args$panel_raw_fields,raw)
concept <- old_product$clinical_concepts[1,,drop=FALSE];concept$clinical_concept_id <- 'stale'
args$clinical_concepts <- rbind(args$clinical_concepts,concept)
rebuilt <- semantic_rehydrate_args(args,getwd())
dictionary <- rebuilt$semantic_dictionary
check('B1',{
  long <- dictionary[dictionary$data_shape=='long_descriptor_table',,drop=FALSE]
  expect_equal(nrow(long),2L,'Populated generic name metadata must not swallow new exact descriptors.')
  expect_equal(dictionary$semantic_meaning[dictionary$raw_column=='name' & dictionary$data_shape=='current_column_metadata'][[1]],'Preserved current interpretation')
})
check('B2',{
  expect_true(all(dictionary$semantic_id %in% rebuilt$semantic_panel_links$semantic_id),'Every reconciled identity needs a route.')
  expect_true(all(dictionary$semantic_id %in% rebuilt$panel_raw_fields$semantic_id),'Every recovered field needs a product route.')
  expect_false(any(rebuilt$semantic_panel_links$semantic_id=='stale' | rebuilt$panel_raw_fields$semantic_id=='stale'),'Stale dependencies must be removed.')
  expect_false(any(rebuilt$clinical_concepts$clinical_concept_id=='stale'),'Stale concept cards must be removed.')
  expect_true(semantic_exact_id('S','new_field') %in% rebuilt$clinical_concepts$clinical_concept_id,'Missing current concept must be appended.')
})
check('B3',{
  direct <- build_semantic_outputs(getwd(),sources,columns,panels)
  product <- build_product_layer_outputs(direct,sources=sources)
  long <- product$panel_raw_fields[product$panel_raw_fields$raw_descriptor=='Puls',,drop=FALSE]
  expect_equal(nrow(long),2L,'Same descriptor with different result fields needs distinct routes.')
  expect_true('value_column' %in% names(long),'Result field belongs to product schema.')
  expect_equal(sort(long$value_column),c('result_a','result_b'))
  registry <- atlas_output_registry(getwd());spec <- Filter(function(x)x$id=='panel_raw_fields',registry$artifacts)[[1]]
  expect_true('value_column' %in% unlist(spec$projection),'Result field must survive registered public table projection.')
  file <- tempfile(fileext='.csv');write_csv(product$panel_raw_fields,file)
  expect_equal(atlas_read_registered_csv(file,spec)$value_column,product$panel_raw_fields$value_column,'Current product CSV keeps exact result fields.')
  legacy <- product$panel_raw_fields;legacy$value_column <- NULL;write_csv(legacy,file)
  expect_equal(nrow(atlas_read_registered_csv(file,spec)),nrow(legacy),'Reviewed legacy product CSV schema remains supported.')
})
check('B4',{
  source <- data.frame(table_name='RKKP_DaMyDa')
  col <- data.frame(table_name='RKKP_DaMyDa',column_name='Stadie')
  semantic <- build_semantic_outputs(getwd(),source,col)
  semantic$value_map <- semantic_value_row(semantic_id=semantic$dictionary$semantic_id[[1]],clinical_concept_id=semantic$dictionary$clinical_concept_id[[1]],clinical_variable='Stage',source_name='RKKP_DaMyDa',object_name='RKKP_DaMyDa',raw_column='Stadie',raw_value='1',display_value='Recorded stage 1',n=25,pct=100,evidence_file='current-synthetic.csv',suppressed=FALSE)
  semantic$code_map <- semantic_code_row(semantic_id='current_stage_code',clinical_concept_id=semantic$dictionary$clinical_concept_id[[1]],clinical_variable='Stage',clinical_group='Disease Registries',source_name='RKKP_DaMyDa',code_system='LOCAL',code='STAGE1',code_name='Recorded stage 1',n_rows=25,evidence_file='current-synthetic.csv')
  direct <- build_product_layer_outputs(semantic,sources=source)
  after <- semantic_rehydrate_args(list(sources=source,column_profiles=col,panels=list(),semantic_dictionary=semantic$dictionary,semantic_value_map=semantic$value_map,semantic_code_map=semantic$code_map),getwd())
  expect_equal(after$panel_distributions,direct$panel_distributions,'Rebuilt products must carry all valid current semantic distributions.')
  expect_equal(after$clinical_concepts$value_map_count,direct$clinical_concepts$value_map_count)
  expect_equal(after$clinical_concepts$code_map_count,direct$clinical_concepts$code_map_count)
  partial <- after
  partial$clinical_concepts$value_map_count <- 0L
  partial$clinical_concepts$purpose <- 'Preserved current product interpretation'
  refreshed <- semantic_rehydrate_args(partial,getwd())
  expect_equal(refreshed$clinical_concepts$value_map_count,direct$clinical_concepts$value_map_count,'Partial products must refresh derived evidence counts.')
  expect_equal(refreshed$clinical_concepts$purpose[[1]],'Preserved current product interpretation','Valid current product interpretations remain intact.')
})
if(length(failures)) {
  for(name in names(failures)) cat(name,':',failures[[name]],'\n')
  quit(status=1)
}
cat('B1-B4 semantic rehydration reconciliation passed.\n')
