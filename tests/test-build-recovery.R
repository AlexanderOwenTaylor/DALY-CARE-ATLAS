source('tests/helper.R'); source_test_runtime()
local({
  root <- normalizePath('.',winslash='/')
  tmp <- tempfile('build-recovery-'); dir.create(tmp)
  tmp <- normalizePath(tmp,winslash='/')
  link <- file.path(tmp,'linked')
  link_created <- FALSE
  remove_fixture_link <- function() {
    if (!link_created) return(invisible(NULL))
    # Delete only this fixture entry, before recursively cleaning its scratch root.
    expect_equal(normalizePath(dirname(link),winslash='/'),tmp)
    expect_equal(dirname(tmp),normalizePath(tempdir(),winslash='/'))
    if (.Platform$OS.type == 'windows') {
      # R unlink can misidentify directory symlinks as junction reparse points.
      command <- paste0("[System.IO.Directory]::Delete('",gsub("'","''",link,fixed=TRUE),"')")
      expect_equal(system2('powershell.exe',c('-NoProfile','-NonInteractive','-Command',shQuote(command))),0L)
    } else {
      expect_equal(unlink(link),0L)
    }
    expect_false(dir.exists(link) || file.exists(link),'Fixture link must be removed without traversing its target.')
    link_created <<- FALSE
  }
  on.exit({remove_fixture_link();unlink(tmp,recursive=TRUE)},add=TRUE)
  # A missing Linux path returns NA, which must never be interpreted as a link.
  assign('Sys.readlink',function(paths) rep(NA_character_,length(paths)),envir=.GlobalEnv)
  on.exit(if(exists('Sys.readlink',envir=.GlobalEnv,inherits=FALSE))rm('Sys.readlink',envir=.GlobalEnv),add=TRUE)
  destination <- file.path(tmp,'absent','site')
  expect_equal(atlas_site_destination(destination),normalizePath(destination,winslash='/',mustWork=FALSE))
  dir.create(destination)
  expect_equal(atlas_site_destination(destination),normalizePath(destination,winslash='/'))
  rm('Sys.readlink',envir=.GlobalEnv)
  blocked <- file.path(tmp,'file'); writeLines('keep',blocked)
  expect_true(inherits(try(atlas_site_destination(blocked),silent=TRUE),'try-error'))
  expect_true(inherits(try(atlas_site_destination(file.path(tmp,'..','site')),silent=TRUE),'try-error'))
  target <- file.path(tmp,'real'); dir.create(target)
  sentinel <- file.path(target,'keep.txt');writeLines('keep',sentinel)
  link_created <- isTRUE(suppressWarnings(file.symlink(target,link)))
  if (link_created) {
    expect_true(inherits(try(atlas_site_destination(link),silent=TRUE),'try-error'))
    expect_true(inherits(try(atlas_site_destination(file.path(link,'nested','site')),silent=TRUE),'try-error'))
    remove_fixture_link()
    expect_file(sentinel)
  }
  if (.Platform$OS.type != 'windows' && Sys.info()[['user']] != 'root') {
    locked <- file.path(tmp,'locked');dir.create(locked);Sys.chmod(locked,'0555')
    expect_true(inherits(try(atlas_site_destination(file.path(locked,'site')),silent=TRUE),'try-error'))
    Sys.chmod(locked,'0755')
  }
  # Preflight failures before directory creation still leave a durable safe record.
  failure <- tryCatch(run_atlas(root,'missing-secret-map-1234567890',output_root=file.path(blocked,'runs')),error=identity)
  expect_true(inherits(failure,'atlas_build_error'))
  expect_file(failure$diagnostics)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'preflight')
  expect_true(nzchar(state$value[state$metric=='recovery_instructions']))
  expect_false(any(grepl('secret|1234567890',c(conditionMessage(failure),state$value))))
  original_require <- requireNamespace
  dependency_resolve <- resolve_dalycare_sources
  assign('resolve_dalycare_sources',function(...)stop('Unexpected collection after missing dependency'),envir=.GlobalEnv)
  assign('requireNamespace',function(package,...) if(package=='readr') FALSE else original_require(package,...),envir=.GlobalEnv)
  failure <- tryCatch(run_atlas(root,'config/source-map.example.tsv',file.path(tmp,'missing-dependency')),error=identity)
  rm('requireNamespace',envir=.GlobalEnv)
  assign('resolve_dalycare_sources',dependency_resolve,envir=.GlobalEnv)
  expect_equal(failure$code,'missing_dependency')
  expect_equal(failure$resource,'readr')

  # Actual DB boundary is replaced because a live database is an external dependency.
  # Its invocation must follow preflight and an already flushed collection log.
  original_resolve <- resolve_dalycare_sources
  on.exit(assign('resolve_dalycare_sources',original_resolve,envir=.GlobalEnv),add=TRUE)
  assign('resolve_dalycare_sources',function(...) {
    active <- getOption('dalycare.atlas.active_run_dir')
    lines <- readLines(file.path(active,'logs','atlas_execution_log.tsv'))
    expect_true(any(grepl('collection',lines,fixed=TRUE)),'Collection stage must be flushed before DB work.')
    stop('password=hunter2 SELECT patientid FROM person WHERE id=1234567890')
  },envir=.GlobalEnv)
  failure <- tryCatch(run_atlas(root,'config/source-map.example.tsv',file.path(tmp,'runs')),error=identity)
  expect_true(inherits(failure,'atlas_build_error'))
  expect_file(failure$diagnostics)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'collection')
  text <- c(conditionMessage(failure),state$value,readLines(file.path(dirname(failure$diagnostics),'atlas_execution_log.tsv')))
  expect_false(any(grepl('hunter2|SELECT|patientid|1234567890',text)))
  expect_file(file.path(dirname(failure$diagnostics),'atlas_recovery.txt'))

  # Missing templates, malformed dictionaries/policies and unwritable output fail
  # before that DB boundary, even when their errors contain private text.
  project <- file.path(tmp,'project');dir.create(project)
  file.copy(file.path(root,'config'),project,recursive=TRUE)
  file.copy(file.path(root,'inst'),project,recursive=TRUE)
  required <- file.path(project,'inst/templates/atlas-vitals.js')
  unlink(required)
  failure <- tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'bad-template')),error=identity)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'preflight')
  expect_equal(state$value[state$metric=='error_code'],'missing_or_invalid_template')
  expect_equal(state$value[state$metric=='error_resource'],'atlas-vitals.js')
  file.copy(file.path(root,'inst/templates/atlas-vitals.js'),required)
  dictionary <- file.path(project,'config/npu-consensus-dictionary.tsv')
  writeLines('private malformed dictionary',dictionary)
  failure <- tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'bad-dictionary')),error=identity)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'preflight')
  file.copy(file.path(root,'config/npu-consensus-dictionary.tsv'),dictionary,overwrite=TRUE)
  writeLines('{"password":"hunter2"}',file.path(project,'inst/config/registry-summary-policy.json'))
  failure <- tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'bad-policy')),error=identity)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'preflight')
  expect_false(any(grepl('hunter2',state$value)))
  file.copy(file.path(root,'inst/config/registry-summary-policy.json'),file.path(project,'inst/config/registry-summary-policy.json'),overwrite=TRUE)
  display <- file.path(project,'config/clinical-display-dictionary.csv')
  rows <- read.csv(display,stringsAsFactors=FALSE,check.names=FALSE)
  field <- rows[which(rows$kind=='field')[1],,drop=FALSE]
  field$label <- paste0(field$label,' conflicting')
  write.csv(rbind(rows,field),display,row.names=FALSE)
  failure <- tryCatch(run_atlas(project,file.path(root,'config/source-map.example.tsv'),file.path(tmp,'bad-display')),error=identity)
  state <- read.delim(failure$diagnostics,stringsAsFactors=FALSE)
  expect_equal(state$value[state$metric=='failing_stage'],'preflight','Conflicting field labels must be caught before collection.')
})
cat('Build recovery destination, preflight and durable diagnostics passed\n')
