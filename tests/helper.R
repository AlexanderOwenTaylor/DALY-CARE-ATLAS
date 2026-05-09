source_test_runtime <- function(root = normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)) {
  files <- c(
    "R/utils.R",
    "R/source_map.R",
    "R/dalycare_preflight.R",
    "R/loader.R",
    "R/profiler.R",
    "R/db_profile.R",
    "R/html.R",
    "R/run_atlas.R"
  )
  for (file in files) {
    source(file.path(root, file))
  }
  invisible(TRUE)
}

expect_true <- function(x, message = "Expected TRUE") {
  if (!isTRUE(x)) stop(message, call. = FALSE)
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
