root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
source_test_runtime(root)

csv_path <- tempfile(fileext = ".csv")
utils::write.csv(data.frame(a = 1:2, b = c("x", "y")), csv_path, row.names = FALSE)
record <- data.frame(table_name = "file_source", source_type = "file", source = csv_path, priority = 1L, profile_mode = "full")
loaded <- load_source_data(record, project_root = root)
expect_equal(nrow(loaded), 2L, "CSV file source should load.")

rds_path <- tempfile(fileext = ".rds")
saveRDS(data.frame(a = 1:3), rds_path)
record$source <- rds_path
loaded_rds <- load_source_data(record, project_root = root)
expect_equal(nrow(loaded_rds), 3L, "RDS file source should load.")

bootstrap <- tempfile(fileext = ".R")
writeLines(c(
  "load_dataset <- function(name) {",
  "  if (identical(name, 'returned_dataset')) return(data.frame(x = 1:2))",
  "  if (identical(name, 'side_effect_dataset')) { assign('side_effect_dataset', data.frame(y = 1:4), envir = .GlobalEnv); return(invisible(NULL)) }",
  "  if (identical(name, 'list_wrapped_dataset')) return(list(data = data.frame(q = 1:6)))",
  "  if (identical(name, 'env_wrapped_dataset')) { e <- new.env(parent = emptyenv()); e$data <- data.frame(r = 1:7); return(e) }",
  "  stop('unknown dataset')",
  "}"
), bootstrap)

dataset_record <- data.frame(table_name = "returned", source_type = "dataset", source = "returned_dataset", priority = 1L, profile_mode = "full")
returned <- load_source_data(dataset_record, bootstrap_path = bootstrap)
expect_equal(nrow(returned), 2L, "Return-value dataset loader should work.")

side_effect_record <- data.frame(table_name = "side_effect", source_type = "dataset", source = "side_effect_dataset", priority = 1L, profile_mode = "full")
side_effect <- load_source_data(side_effect_record, bootstrap_path = bootstrap)
expect_equal(nrow(side_effect), 4L, "Side-effect dataset loader should work.")
expect_false(exists("side_effect_dataset", envir = .GlobalEnv, inherits = FALSE), "Side-effect dataset object should be cleaned from global env.")

list_record <- data.frame(table_name = "list_wrapped", source_type = "dataset", source = "list_wrapped_dataset", priority = 1L, profile_mode = "full")
list_loaded <- load_source_data(list_record, bootstrap_path = bootstrap)
expect_equal(nrow(list_loaded), 6L, "List-wrapped DALY loader outputs should be unwrapped.")

env_record <- data.frame(table_name = "env_wrapped", source_type = "dataset", source = "env_wrapped_dataset", priority = 1L, profile_mode = "full")
env_loaded <- load_source_data(env_record, bootstrap_path = bootstrap)
expect_equal(nrow(env_loaded), 7L, "Environment-wrapped DALY loader outputs should be unwrapped.")

if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) {
  rm(load_dataset, envir = .GlobalEnv)
}
caller_bootstrap <- tempfile(fileext = ".R")
writeLines(c(
  "load_dataset <- function(dataset = NULL, value = NULL, column = 'patientid') {",
  "  if (is.null(dataset)) return(c('caller_dataset'))",
  "  assign(dataset, data.frame(z = 1:5), envir = parent.frame())",
  "  invisible(NULL)",
  "}"
), caller_bootstrap)
caller_record <- data.frame(table_name = "caller_table", source_type = "dataset", source = "caller_dataset", priority = 1L, profile_mode = "full")
caller_loaded <- load_source_data(caller_record, bootstrap_path = caller_bootstrap)
expect_equal(nrow(caller_loaded), 5L, "DALY-style caller-environment side-effect datasets should load.")
expect_false(exists("caller_dataset", envir = .GlobalEnv, inherits = FALSE), "Caller-environment dataset objects should not leak to global env.")
if (exists("load_dataset", envir = .GlobalEnv, inherits = FALSE)) {
  rm(load_dataset, envir = .GlobalEnv)
}
