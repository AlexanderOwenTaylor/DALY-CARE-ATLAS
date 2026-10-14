root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
test_files <- list.files(file.path(root, "tests"), pattern = "^test-.*\\.R$", full.names = TRUE)
if (!length(test_files)) {
  stop("No tests found.", call. = FALSE)
}

failures <- list()
executable <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
for (test_file in test_files) {
  cat("Running", basename(test_file), "...\n")
  # Each file is a standalone regression program. A child process also isolates
  # global mock bindings, environment changes, options and registered S4 methods.
  tryCatch(
    {
      status <- system2(executable, c("--vanilla", shQuote(test_file)))
      if (!identical(status, 0L)) stop(paste("Rscript exit status", status), call. = FALSE)
      cat("  OK\n")
    },
    error = function(e) {
      failures[[basename(test_file)]] <<- conditionMessage(e)
      cat("  FAIL:", conditionMessage(e), "\n")
    }
  )
}

if (length(failures)) {
  cat("\nFailures:\n")
  for (nm in names(failures)) {
    cat("-", nm, ":", failures[[nm]], "\n")
  }
  quit(status = 1, save = "no", runLast = FALSE)
}

cat("\nAll tests passed.\n")
