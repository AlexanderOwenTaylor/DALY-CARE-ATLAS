root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))

old_source_only <- Sys.getenv("DALYCARE_ATLAS_SOURCE_ONLY", unset = NA_character_)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = "TRUE")
restore_source_only <- function() {
  if (is.na(old_source_only)) {
    Sys.unsetenv("DALYCARE_ATLAS_SOURCE_ONLY")
  } else {
    Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY = old_source_only)
  }
}

cli_env <- new.env(parent = globalenv())
sys.source(file.path(root, "scripts", "run_atlas.R"), envir = cli_env)

help_text <- capture.output(cli_env$run_atlas_cli(c("--help")))
expect_true(any(grepl("Usage:", help_text, fixed = TRUE)), "CLI help should print usage.")
expect_true(any(grepl("<source_map_path>", help_text, fixed = TRUE)), "CLI help should include the short source-map form.")

no_arg_error <- tryCatch(
  {
    cli_env$run_atlas_cli(character())
    NA_character_
  },
  error = function(e) conditionMessage(e)
)
expect_true(grepl("Usage:", no_arg_error, fixed = TRUE), "CLI with no args should raise usage without quitting R.")

restore_source_only()
