source('tests/helper.R');source_test_runtime()
local({
  root <- normalizePath('.',winslash='/')
  tmp <- tempfile('publication-recovery-');dir.create(tmp)
  on.exit(unlink(tmp,recursive=TRUE),add=TRUE)
  paths <- atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='previous'),list(),root)
  files <- c(unlist(paths$assets),paths$manifest)
  prior <- tools::md5sum(files)
  original_rename <- file.rename
  on.exit(if(exists('file.rename',envir=.GlobalEnv,inherits=FALSE))rm('file.rename',envir=.GlobalEnv),add=TRUE)
  for(fail_at in c('backup_site','backup_manifest','publish_site','publish_manifest')) {
    assign('file.rename',function(from,to) {
      fail <- switch(fail_at,
        backup_site=identical(from,file.path(normalizePath(tmp,winslash='/'),'site')),
        backup_manifest=identical(from,paths$manifest),
        publish_site=grepl('-stage-',from,fixed=TRUE) && !grepl('manifest-stage',from,fixed=TRUE),
        publish_manifest=grepl('manifest-stage',from,fixed=TRUE))
      if(fail) FALSE else original_rename(from,to)
    },envir=.GlobalEnv)
    failure <- try(atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='replacement'),list(),root),silent=TRUE)
    expect_true(inherits(failure,'try-error'),paste('Expected publication fault at',fail_at))
    expect_equal(tools::md5sum(files),prior,paste('Old site and manifest changed after',fail_at))
    expect_false(any(grepl('-stage-',list.files(tmp,all.files=TRUE),fixed=TRUE)))
  }
  rm('file.rename',envir=.GlobalEnv)
  atlas_write_site_bundle(file.path(tmp,'site'),list(run_id='replacement'),list(),root)
  expect_false(identical(tools::md5sum(files),prior))
})
cat('Site replacement preserves old bytes at every promotion failure boundary\n')
