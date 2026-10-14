source('tests/helper.R'); source_test_runtime()
# Reject prefix matches, calendar overflow, unmapped day-first and numeric epochs.
x <- c('2024-02-29','2023-02-29','2024-02-30','2024-13-01','2024-01-01junk',
       '01-02-03','01/02/2024','31-12-2024','20240101','2024-01-01T23:59:59Z',
       '2024-01-01 24:00:00','2024-01-01T12:30:00+02:00','0000-01-01')
expect_equal(as.character(safe_as_date(x)), c('2024-02-29',rep(NA_character_,8),
  '2024-01-01',NA_character_,'2024-01-01',NA_character_))
expect_true(all(is.na(safe_as_date(c(0,20000,20240101)))))
expect_equal(as.character(safe_as_date(c('31-12-2024','29-02-2023','01-02-2024'),format_rule='dmy_dash')),
 c('2024-12-31',NA_character_,'2024-02-01'))
expect_equal(as.character(safe_as_date('20240101',format_rule='ymd_compact')),'2024-01-01')
expect_equal(as.character(safe_as_date(20240101,format_rule='ymd_compact')),'2024-01-01')
expect_equal(as.character(coverage_parse_date('2024-02-29')),'2024-02-29')
# A bad rule for a field not yet visited must fail preflight before any DB call.
mapping<-tempfile(fileext='.csv')
write.csv(data.frame(table_name='unvisited_source',column_name='unvisited_field',format_rule='dmy_dash',reviewed=TRUE,sentinel_dates='2024-02-30'),mapping,row.names=FALSE)
Sys.setenv(DALYCARE_DATE_FORMATS_FILE=mapping)
called<-FALSE
err<-tryCatch(run_atlas(getwd(),'config/source-map.example.tsv',tempfile('bad-date-policy-'),'report',
 db_adapter=list(list_tables=function(){called<<-TRUE;stop('DB must not be reached')})),error=identity)
expect_true(inherits(err,'atlas_build_error')&&err$stage=='preflight'&&err$code=='invalid_policy')
expect_false(called)
Sys.unsetenv('DALYCARE_DATE_FORMATS_FILE');unlink(mapping)
cat('PASS strict date contract\n')
