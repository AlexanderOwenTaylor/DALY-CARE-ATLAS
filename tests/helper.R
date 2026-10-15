source_test_runtime <- function(root = normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)) {
  files <- c(
    "R/utils.R",
    "R/source_map.R",
    "R/dalycare_preflight.R",
    "R/loader.R",
    "R/npu_dictionary.R",
    "R/code_panels.R",
    "R/coverage.R",
    "R/registry_summary_privacy.R",
    "R/registry_summaries.R",
    "R/profiler.R",
    "R/db_profile.R",
    "R/source_reconciliation.R",
    "R/clinical_source_membership.R",
    "R/situation_report.R",
    "R/action_items.R",
    "R/semantic_dictionary.R",
    "R/product_layer.R",
    "R/ki67_discovery.R",
    "R/patobank_ki67_cartography.R",
    "R/mcl_triangle_counts.R",
    "R/mcl_triangle_feasibility.R",
    "R/html.R",
    "R/output_evidence.R",
    "R/metadata_privacy.R",
    "R/public_privacy.R",
    "R/publication.R",
    "R/site_bundle.R",
    "R/run_atlas.R"
  )
  for (file in files) {
    source(file.path(root, file))
  }
  invisible(TRUE)
}

source_ki67_test_runtime <- function(root = normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)) {
  files <- c(
    "R/utils.R",
    "R/ki67_discovery.R",
    "R/mcl_triangle_counts.R",
    "R/mcl_triangle_feasibility.R",
    "R/source_map.R",
    "R/db_profile.R",
    "R/patobank_ki67_cartography.R",
    "R/ki67_production_finder.R"
  )
  for (file in files) {
    source(file.path(root, file))
  }
  invisible(TRUE)
}

expect_true <- function(x, message = "Expected TRUE") {
  if (!isTRUE(x)) stop(if(identical(message,"Expected TRUE"))paste(message,paste(deparse(substitute(x)),collapse=' '))else message, call. = FALSE)
}

expect_false <- function(x, message = "Expected FALSE") {
  if (isTRUE(x)) stop(message, call. = FALSE)
}

expect_equal <- function(x, y, message = NULL) {
  if (!identical(x, y)) {
    if (is.null(message)) {
      message <- paste0("Expected ", paste(capture.output(str(y)), collapse = " "), " but got ", paste(capture.output(str(x)), collapse = " "))
    }
    stop(message, call. = FALSE)
  }
}

expect_file <- function(path) {
  expect_true(file.exists(path), paste("Expected file to exist:", path))
}

source_advanced_entry <- function(path, envir) {
  key <- if (basename(path)=="source_ki67_finder.R") ".KI67_SOURCE_CONFIG" else ".MCL_COUNT_SOURCE_CONFIG"
  config <- as.list(envir, all.names=TRUE)
  old <- if (exists(key,envir=.GlobalEnv,inherits=FALSE)) get(key,envir=.GlobalEnv) else NULL
  on.exit({if (is.null(old)) rm(list=key,envir=.GlobalEnv) else assign(key,old,envir=.GlobalEnv)},add=TRUE)
  assign(key,config,envir=.GlobalEnv)
  sys.source(path,envir=envir)
}

# Copy the complete declared runtime for moved-root/CLI tests, never user runs.
copy_test_runtime_fixture <- function(destination,root=getwd()) {
  dir.create(destination,recursive=TRUE,showWarnings=FALSE)
  for(item in c('R','scripts','inst','config','DESCRIPTION','NAMESPACE','LICENSE'))
    if(!file.copy(file.path(root,item),destination,recursive=TRUE,overwrite=TRUE))stop('Runtime fixture copy failed',call.=FALSE)
  invisible(destination)
}
read_public_table <- function(site,id) {
  catalogue<-jsonlite::fromJSON(sub(';\\s*$','',sub('^[^=]+=','',paste(readLines(file.path(site,'DALYCARE_output_catalogue.js'),encoding='UTF-8'),collapse='\n'))),simplifyVector=FALSE)
  table<-Filter(function(t)t$id==id,catalogue$tables)[[1]]
  rows<-list()
  for(shard in table$shards){script<-paste(readLines(file.path(site,shard$src),encoding='UTF-8'),collapse='\n');wire<-jsonlite::fromJSON(sub('\\);$','',sub('^.*?register\\(','',script)),simplifyVector=FALSE);rows<-c(rows,jsonlite::fromJSON(wire$rows_json,simplifyVector=FALSE))}
  rows
}
