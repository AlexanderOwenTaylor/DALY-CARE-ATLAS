.dalycare_entry_path <- local({
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    if (exists("ofile", envir = frames[[i]], inherits = FALSE)) {
      return(normalizePath(get("ofile", envir = frames[[i]]), winslash = "/", mustWork = FALSE))
    }
  }
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(sub("^--file=", "", file_arg[[1]]), winslash = "/", mustWork = FALSE))
  }
  candidate <- file.path(getwd(), "RUN_DALYCARE_ATLAS_73_SOURCE.R")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/", mustWork = FALSE))
  NA_character_
})

.dalycare_project_root <- if (!is.na(.dalycare_entry_path)) {
  dirname(.dalycare_entry_path)
} else {
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}
if (!identical(basename(if (is.na(.dalycare_entry_path)) "" else .dalycare_entry_path), "RUN_DALYCARE_ATLAS_73_SOURCE.R") &&
    file.exists(file.path(getwd(), "RUN_DALYCARE_ATLAS_73_SOURCE.R"))) {
  .dalycare_entry_path <- normalizePath(file.path(getwd(), "RUN_DALYCARE_ATLAS_73_SOURCE.R"), winslash = "/", mustWork = FALSE)
  .dalycare_project_root <- dirname(.dalycare_entry_path)
}

.dalycare_run_dir_from_error <- function(error_message, output_root) {
  hit <- regmatches(error_message, regexpr("Diagnostics written to:[^\r\n]+", error_message))
  if (length(hit) && nzchar(hit[[1]])) {
    return(trimws(sub("^Diagnostics written to:", "", hit[[1]])))
  }
  getOption("dalycare.atlas.active_run_dir", NA_character_)
}

.dalycare_print_diagnostic_path <- function(label, path) {
  suffix <- if (file.exists(path)) "" else " (not found)"
  cat("  - ", label, ": ", normalizePath(path, winslash = "/", mustWork = FALSE), suffix, "\n", sep = "")
}

# Keep startup recovery self-contained: a broken runtime cannot supply helpers.
.dalycare_startup_failure <- function() {
  stage <- 'startup'
  message <- 'Atlas startup failed. Raw error details withheld; restore runtime files and dependencies, then rerun the source entrypoint.'
  recovery <- 'Restore the complete source runner and its R, scripts, config and inst directories. Keep existing run outputs for offline rebuilding.'
  attempt <- paste0(format(Sys.time(),'%Y%m%d_%H%M%S'),'-p',Sys.getpid(),'-',paste(sample(c(0:9,letters[1:6]),8,TRUE),collapse=''))
  for(base in unique(c(file.path(.dalycare_project_root,'atlas_runs','.recovery'),
    file.path(getwd(),'atlas_runs','.recovery'),file.path(path.expand('~'),'.dalycare-atlas','recovery')))) {
    path <- file.path(base,attempt)
    diagnostics <- file.path(path,'atlas_build_status.tsv')
    ok <- tryCatch({
      suppressWarnings(dir.create(path,recursive=TRUE,showWarnings=FALSE))
      rows <- data.frame(metric=c('run_status','failing_stage','current_stage','sanitised_error','recovery_instructions',
        'collection_status','interpretation_status','website_status','packaging_status'),
        value=c('failed',stage,stage,message,recovery,rep('not_started',3),'not_implemented'))
      utils::write.table(rows,diagnostics,sep='\t',quote=TRUE,row.names=FALSE,fileEncoding='UTF-8')
      utils::write.table(data.frame(timestamp=format(Sys.time(),'%Y-%m-%dT%H:%M:%S%z'),level='error',table_name='',stage=stage,message=message),
        file.path(path,'atlas_execution_log.tsv'),sep='\t',quote=TRUE,row.names=FALSE,fileEncoding='UTF-8')
      writeLines(c(message,recovery),file.path(path,'atlas_recovery.txt'))
      TRUE
    },error=function(e) FALSE)
    if(ok) {
      diagnostics <- normalizePath(diagnostics,winslash='/',mustWork=TRUE)
      options(dalycare.atlas.failure_diagnostics=diagnostics)
      return(structure(list(message=paste0(message,' Diagnostics written to: ',diagnostics),call=NULL,
        stage=stage,diagnostics=diagnostics,run_dir=NA_character_),class=c('atlas_build_error','error','condition')))
    }
  }
  simpleError('Atlas startup failed and recovery diagnostics could not be written; choose a writable project or working directory.')
}

cat("\nDALY-CARE Atlas one-click RStudio runner (73 source-map entries)\n")
cat("Project root: ", .dalycare_project_root, "\n", sep = "")
cat("The 73 entries include canonical resources, derived/helper rows and special/manual entries; live access is assessed separately.\n")

.dalycare_source_map <- Sys.getenv("DALYCARE_ATLAS_SOURCE_MAP", unset = "config/source-map.dalycare73.tsv")
.dalycare_output_root <- Sys.getenv("DALYCARE_ATLAS_OUTPUT_ROOT", unset = "atlas_runs")
.dalycare_mode <- Sys.getenv("DALYCARE_ATLAS_MODE", unset = "report")
.dalycare_output_root_abs <- if (grepl("^[A-Za-z]:|^/", .dalycare_output_root)) {
  normalizePath(.dalycare_output_root, winslash = "/", mustWork = FALSE)
} else {
  normalizePath(file.path(.dalycare_project_root, .dalycare_output_root), winslash = "/", mustWork = FALSE)
}

if (exists("dalycare_atlas_result", envir=.GlobalEnv, inherits=FALSE)) rm("dalycare_atlas_result", envir=.GlobalEnv)
assign("dalycare_atlas_failed", FALSE, envir = .GlobalEnv)
assign("dalycare_atlas_last_error", NULL, envir = .GlobalEnv)

options(dalycare.atlas.active_run_dir = NULL)
options(dalycare.atlas.failure_diagnostics = NULL)
.dalycare_result <- tryCatch(
  {
    setwd(.dalycare_project_root)
    .dalycare_restore_source_only <- Sys.getenv("DALYCARE_ATLAS_SOURCE_ONLY", unset = NA)
    Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = "TRUE")
    tryCatch(source(file.path(.dalycare_project_root, "scripts", "run_atlas.R"), local=.GlobalEnv),
      finally={
        if (is.na(.dalycare_restore_source_only)) Sys.unsetenv("DALYCARE_ATLAS_SOURCE_ONLY")
        else Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY=.dalycare_restore_source_only)
      })
    
    project_root <- load_atlas_runtime(.dalycare_project_root)
    cat("Selected source map: ", .dalycare_source_map, "\n", sep="")
    run_atlas(
      project_root = project_root,
      source_map_path = .dalycare_source_map,
      output_root = .dalycare_output_root,
      mode = .dalycare_mode
    )
  },
  error = function(e) if(inherits(e,'atlas_build_error')) e else .dalycare_startup_failure()
)

if (inherits(.dalycare_result, "error")) {
  assign("dalycare_atlas_failed", TRUE, envir = .GlobalEnv)
  assign("dalycare_atlas_last_error", .dalycare_result, envir = .GlobalEnv)
  .dalycare_error_message <- conditionMessage(.dalycare_result)
  .dalycare_run_dir <- if(inherits(.dalycare_result,'atlas_build_error')) .dalycare_result$run_dir else
    .dalycare_run_dir_from_error(.dalycare_error_message, .dalycare_output_root_abs)
  cat("\nDALY-CARE atlas failed, but RStudio is still open.\n")
  cat("Error: ", .dalycare_error_message, "\n", sep = "")
  .dalycare_failure_path <- getOption('dalycare.atlas.failure_diagnostics',NA_character_)
  if(!is.na(.dalycare_failure_path)) {
    cat('Failure stage: ',.dalycare_result$stage,'\n',sep='')
    .dalycare_print_diagnostic_path('Build and recovery status',.dalycare_failure_path)
    .dalycare_print_diagnostic_path('Recovery instructions',file.path(dirname(.dalycare_failure_path),'atlas_recovery.txt'))
  }
  if (!is.na(.dalycare_run_dir) && nzchar(.dalycare_run_dir)) {
    cat("\nRun directory: ", .dalycare_run_dir, "\n", sep = "")
    cat("Diagnostic files:\n")
    .dalycare_print_diagnostic_path("Completion report", file.path(.dalycare_run_dir,"outputs","atlas_completion_summary.csv"))
    .dalycare_print_diagnostic_path("Registry report", file.path(.dalycare_run_dir,"outputs","atlas_registry_completion.csv"))
    .dalycare_print_diagnostic_path("DALY access", file.path(.dalycare_run_dir, "outputs", "atlas_dalycare_access.csv"))
    .dalycare_print_diagnostic_path("Source resolution", file.path(.dalycare_run_dir, "outputs", "atlas_source_resolution.csv"))
    .dalycare_print_diagnostic_path("Memory plan", file.path(.dalycare_run_dir, "outputs", "atlas_memory_plan.csv"))
    .dalycare_print_diagnostic_path("Execution log", file.path(.dalycare_run_dir, "logs", "atlas_execution_log.tsv"))
  } else {
    cat("\nNo run directory was created before the failure.\n")
  }
  cat("\nFailure object saved as: dalycare_atlas_last_error\n")
} else {
  assign("dalycare_atlas_result", .dalycare_result, envir = .GlobalEnv)
  assign("dalycare_atlas_failed", FALSE, envir = .GlobalEnv)
  assign("dalycare_atlas_last_error", NULL, envir = .GlobalEnv)
  cat("\nDALY-CARE atlas run complete.\n")
  cat("Run directory: ", .dalycare_result$run_dir, "\n", sep = "")
  cat("HTML: ", .dalycare_result$html, "\n", sep = "")
  atlas_print_completion_report(.dalycare_result$completion)
  cat("Completion report: ", .dalycare_result$completion_summary, "\n", sep="")
  cat("Registry report: ", .dalycare_result$registry_completion, "\n", sep="")
  cat("Result object saved as: dalycare_atlas_result\n")
}

invisible(.dalycare_result)
