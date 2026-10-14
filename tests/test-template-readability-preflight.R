source('tests/helper.R');source_test_runtime()
local({
  root <- normalizePath('.',winslash='/')
  tmp <- tempfile('template-readability-');dir.create(tmp)
  on.exit(unlink(tmp,recursive=TRUE),add=TRUE)
  project <- file.path(tmp,'project');dir.create(project)
  file.copy(file.path(root,'config'),project,recursive=TRUE)
  file.copy(file.path(root,'inst'),project,recursive=TRUE)
  template <- normalizePath(file.path(project,'inst/templates/atlas-vitals.js'),winslash='/')
  expect_true(file.info(template)$size>0)
  collection_calls <- 0L
  original_resolve <- resolve_dalycare_sources
  original_file <- file
  on.exit(assign('resolve_dalycare_sources',original_resolve,envir=.GlobalEnv),add=TRUE)
  on.exit(if(exists('file',envir=.GlobalEnv,inherits=FALSE))rm('file',envir=.GlobalEnv),add=TRUE)
  assign('resolve_dalycare_sources',function(...) {
    collection_calls <<- collection_calls+1L
    stop('Unexpected source collection after unreadable template')
  },envir=.GlobalEnv)
  assert_preflight <- function(failure) {
    expect_equal(collection_calls,0L,'Unreadable templates must prevent source collection.')
    expect_true(inherits(failure,'atlas_build_error'))
    expect_equal(failure$stage,'preflight')
    expect_equal(failure$code,'missing_or_invalid_template')
    expect_equal(failure$resource,'atlas-vitals.js')
    state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
    expect_equal(state$value[state$metric=='error_resource'],'atlas-vitals.js')
    expect_false(any(grepl('hunter2|SELECT|patientid|1234567890',c(conditionMessage(failure),state$value))))
  }
  # Inject only the filesystem open, keeping real preflight and collection control
  # flow. This portable branch catches the failure even on Windows/root sessions.
  assign('file',function(description='',open='',...) {
    if(is.character(description) && length(description)==1L &&
       identical(normalizePath(description,winslash='/',mustWork=FALSE),template) && grepl('r',open,fixed=TRUE))
      stop('password=hunter2 SELECT patientid FROM person WHERE id=1234567890')
    original_file(description,open,...)
  },envir=.GlobalEnv)
  failure <- tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'injected-runs')),error=identity)
  rm('file',envir=.GlobalEnv)
  assert_preflight(failure)
  # Actual Linux permission behavior is exercised by non-root acceptance runs.
  if(.Platform$OS.type!='windows' && Sys.info()[['user']]!='root') {
    Sys.chmod(template,'0000')
    on.exit(Sys.chmod(template,'0644'),add=TRUE)
    expect_true(file.exists(template) && file.info(template)$size>0)
    failure <- suppressWarnings(tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'permission-runs')),error=identity))
    Sys.chmod(template,'0644')
    assert_preflight(failure)
    cat('Actual non-root unreadable Linux template blocked before collection\n')
  } else cat('Actual non-root Linux permission branch pending on this platform\n')
})
cat('Unreadable templates stop preflight before collection with safe resource error\n')
