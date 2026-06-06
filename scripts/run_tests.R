root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
test_files <- list.files(file.path(root, "tests"), pattern = "^test-.*\\.R$", full.names = TRUE)
if (!length(test_files)) {
  stop("No tests found.", call. = FALSE)
}

failures <- list()
for (test_file in test_files) {
  setwd(root)
  test_start <- Sys.time()
  cat("[", format(test_start, "%Y-%m-%d %H:%M:%S"), "] Running ", basename(test_file), "...\n", sep = "")
  flush.console()
  tryCatch(
    {
      sys.source(test_file, envir = new.env(parent = globalenv()))
      elapsed <- round(as.numeric(difftime(Sys.time(), test_start, units = "secs")), 1)
      cat("  OK (", elapsed, "s)\n", sep = "")
      flush.console()
    },
    error = function(e) {
      failures[[basename(test_file)]] <<- conditionMessage(e)
      cat("  FAIL:", conditionMessage(e), "\n")
      flush.console()
    },
    finally = {
      closeAllConnections()
      setwd(root)
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
