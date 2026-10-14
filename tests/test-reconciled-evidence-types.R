# Reconciliation must not replace typed CSV cells with legacy display strings.
source('tests/helper.R');source('R/utils.R');source('R/output_evidence.R')
modern <- list(semantic_id='string',code='string',sort_order='number',reviewed='boolean',value_column='string')
legacy <- modern[setdiff(names(modern),'value_column')]
spec <- list(schemas=list(modern,legacy))
rows <- list(list(semantic_id='source::001',code='0012',sort_order='2',reviewed='TRUE',value_column=NULL),list(semantic_id='source::002',code='0000',sort_order=NULL,reviewed=NULL))
out <- atlas_reconcile_evidence_rows(rows,names(modern),spec)
expect_equal(out[[1]]$semantic_id,'source::001');expect_equal(out[[1]]$code,'0012')
expect_equal(out[[1]]$sort_order,2);expect_true(is.numeric(out[[1]]$sort_order))
expect_true(isTRUE(out[[1]]$reviewed));expect_true(is.null(out[[1]]$value_column))
expect_true(is.null(out[[2]]$value_column));expect_true(is.null(out[[2]]$reviewed));expect_true(is.null(out[[2]]$sort_order))
expect_equal(out[[2]]$code,'0000')
old <- atlas_reconcile_evidence_rows(rows,names(legacy),spec)
expect_equal(names(old[[1]]),names(legacy));expect_true(is.numeric(old[[1]]$sort_order))
expect_equal(out,atlas_reconcile_evidence_rows(out,names(modern),spec))
for(bad in list('NaN','Infinity','not-number',TRUE)) {
  forged <- rows;forged[[1]]$sort_order<-bad
  expect_true(inherits(tryCatch(atlas_reconcile_evidence_rows(forged,names(modern),spec),error=identity),'error'))
}
cat('Reconciled numeric/boolean types, exact string identities, nullable legacy columns and malformed rejection passed.\n')
