# Test suites must not inherit another test's global mocks, options or environment.
local({
  root <- normalizePath('.', winslash='/')
  harness <- file.path(root, 'scripts', 'run_tests.R')
  executable <- file.path(R.home('bin'), if (.Platform$OS.type == 'windows') 'Rscript.exe' else 'Rscript')
  scratch <- tempfile('atlas-suite-isolation-')
  dir.create(scratch)
  scratch <- normalizePath(scratch, winslash='/')
  on.exit({
    setwd(root)
    stopifnot(identical(dirname(scratch), normalizePath(tempdir(), winslash='/')))
    unlink(scratch, recursive=TRUE)
  }, add=TRUE)
  dir.create(file.path(scratch, 'tests'))
  writeLines(c("assign('.synthetic_atlas_test_poison', TRUE, envir=.GlobalEnv)",
               "Sys.setenv(DALYCARE_SYNTHETIC_TEST_POISON='poison')",
               "options(dalycare.synthetic.test.poison=TRUE)"),
             file.path(scratch, 'tests', 'test-01-poison.R'))
  writeLines(c("stopifnot(!exists('.synthetic_atlas_test_poison', inherits=TRUE))",
               "stopifnot(Sys.getenv('DALYCARE_SYNTHETIC_TEST_POISON') == '')",
               "stopifnot(is.null(getOption('dalycare.synthetic.test.poison')))",
               "cat('ISOLATED_CHILD_PASSED\\n')"),
             file.path(scratch, 'tests', 'test-02-clean.R'))
  setwd(scratch)
  success_log <- file.path(scratch, 'success.log')
  status <- system2(executable, shQuote(harness), stdout=success_log, stderr=success_log)
  if (!identical(status, 0L)) stop('R test harness leaks state between test files; see child log.', call.=FALSE)
  stopifnot(any(grepl('ISOLATED_CHILD_PASSED', readLines(success_log), fixed=TRUE)))
  writeLines("stop('SYNTHETIC_EXPECTED_FAILURE', call.=FALSE)", file.path(scratch, 'tests', 'test-02-clean.R'))
  writeLines("cat('AFTER_FAILURE_EXECUTED\\n')", file.path(scratch, 'tests', 'test-03-after.R'))
  failure_log <- file.path(scratch, 'failure.log')
  status <- system2(executable, shQuote(harness), stdout=failure_log, stderr=failure_log)
  stopifnot(status != 0L)
  log <- readLines(failure_log)
  stopifnot(any(grepl('SYNTHETIC_EXPECTED_FAILURE', log, fixed=TRUE)),
            any(grepl('AFTER_FAILURE_EXECUTED', log, fixed=TRUE)),
            any(grepl('test-02-clean.R', log, fixed=TRUE)))
  cat('R test process isolation and failure propagation passed\n')
})
