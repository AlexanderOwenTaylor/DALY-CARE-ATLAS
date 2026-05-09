root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
test_files <- list.files(file.path(root, "tests"), pattern = "^test-.*\\.R$", full.names = TRUE)
if (!length(test_files)) {
  stop("No tests found.", call. = FALSE)
}

failures <- list()
for (test_file in test_files) {
  cat("Running", basename(test_file), "...\n")
  tryCatch(
    {
      sys.source(test_file, envir = new.env(parent = globalenv()))
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
