root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

tmp <- tempfile(fileext = ".tsv")
writeLines(c(
  "table_name\tsource_type\tsource\tpriority\tprofile_mode",
  "b\tfile\tb.csv\t2\tfull",
  "a\tdataset\ta_dataset\t1\t"
), tmp)

source_map <- read_source_map(tmp)
expect_equal(source_map$table_name, c("a", "b"), "Source map should sort by priority.")
expect_equal(source_map$profile_mode[[1]], "full", "Blank profile_mode should default to full.")

bad <- tempfile(fileext = ".tsv")
writeLines(c("table_name\tsource_type", "a\tfile"), bad)
failed <- FALSE
tryCatch(read_source_map(bad), error = function(e) failed <<- TRUE)
expect_true(failed, "Invalid source map should fail validation.")

