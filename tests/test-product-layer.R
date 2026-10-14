source('tests/helper.R')
source_test_runtime()
# Current discovery replaces dependency on absent ignored historical references.
labels <- read.csv('config/clinical-display-dictionary.csv',stringsAsFactors=FALSE,fileEncoding='UTF-8')
fields <- labels[labels$kind=='field' & labels$system %in% c('RKKP_DaMyDa','RKKP_LYFO','RKKP_CLL'),,drop=FALSE]
columns <- unique(data.frame(table_name=fields$system,column_name=fields$code,profile_kind='metadata_only'))
columns <- rbind(columns,data.frame(table_name='Other.Ø',column_name=c('patientid','Unknown.Field'),profile_kind=c('sensitive','metadata_only')))
sources <- data.frame(table_name=unique(columns$table_name),load_status='ok',n_rows=NA_real_,n_cols=NA_integer_)
semantic <- build_semantic_outputs(getwd(),sources,columns)
semantic$value_map <- semantic_value_row(semantic_id='fixture_stage',clinical_concept_id='stage',clinical_variable='Recorded stage',source_name='RKKP_DaMyDa',raw_column='Stadie',raw_value='1',display_value='Recorded category 1',n=25,pct=100,evidence_file='current-run-synthetic.csv',suppressed=FALSE)
product <- build_product_layer_outputs(semantic,sources=sources,project_root=getwd())
raw <- product$panel_raw_fields
expect_true(nrow(product$clinical_concepts)>0,'Current metadata generates concept cards.')
expect_true(nrow(product$domain_panels)>0 && nrow(product$panel_kpis)>0 && nrow(product$panel_parity)>0,'Current metadata generates panel navigation, KPIs and parity states.')
expect_equal(nrow(raw),nrow(columns),'All exact current pairs, including identifiers, reach field navigation.')
expect_true(nrow(product$panel_distributions)>0,'Explicit current-run categorical evidence reaches distributions.')
expect_true(all(raw$profile_scope=='source_identity_metadata'),'Discovery has metadata scope.')
expect_true(all(na.omit(product$clinical_concepts$count_scope) %in% product_scope_values()),'Scopes use approved vocabulary.')
expect_true(all(is.na(product$clinical_concepts$n_patients)),'Names cannot manufacture patient counts.')
unknown_concept <- product$clinical_concepts[product$clinical_concepts$clinical_concept_id==semantic_exact_id('Other.Ø','Unknown.Field'),,drop=FALSE]
expect_equal(unknown_concept$concept_status[[1]],'metadata_only','A discovered field without observations cannot claim clinical availability.')
for(i in seq_len(nrow(fields))) {
  row <- raw[raw$source_name==fields$system[[i]] & raw$raw_column==fields$code[[i]],,drop=FALSE]
  expect_equal(nrow(row),1L,paste('Exact field route:',fields$system[[i]],fields$code[[i]]))
  expect_equal(row$clinical_variable[[1]],fields$label[[i]],'Labels agree with reviewed exact source-field dictionary.')
}
crp <- semantic$dictionary[semantic$dictionary$source_name=='RKKP_DaMyDa' & semantic$dictionary$raw_column %in% c('Reg_CReaktivtProtein_gl','Reg_CReaktivtProtein_nMoll'),,drop=FALSE]
expect_true(nrow(crp)==2L && all(crp$clinical_concept_id=='crp'),'CRP cannot resolve as creatinine.')
calcium <- semantic$dictionary[semantic$dictionary$raw_column=='Reg_CalciumAlbuminkorrigeret',,drop=FALSE]
expect_true(nrow(calcium)>0 && all(calcium$clinical_concept_id=='albumin_corrected_calcium'),'Corrected calcium cannot resolve as albumin.')
histology <- semantic$dictionary[semantic$dictionary$source_name=='RKKP_LYFO' & semantic$dictionary$raw_column=='Reg_WHOHistologikode1',,drop=FALSE]
expect_true(nrow(histology)==1L && histology$clinical_concept_id=='lymphoma_subtype_code','WHO histology cannot resolve as performance status.')
expect_equal(raw$mapping_status[raw$raw_column=='Unknown.Field'][[1]],'description_unavailable','Unknown fields stay reachable.')
expect_true(all(is.na(semantic$dictionary$unit) | semantic$dictionary$unit==''),'Readable names cannot verify units.')
cat('Current product-layer contract passed.\n')
