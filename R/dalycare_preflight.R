dalycare_canonical_sources <- function() {
  unique(c(
    "patient",
    "RKKP_CLL", "RKKP_LYFO", "RKKP_DaMyDa",
    "SP_AdministreretMedicin", "SP_ADT_haendelser", "SP_AlleProvesvar",
    "SP_BilleddiagnostikeUndersoegelser_Del1",
    "SP_BilleddiagnostikeUndersoegelser_Del2",
    "SP_Behandlingsniveau", "SP_BilleddiagnostiskeUndersøgelser_Del1",
    "SP_BilleddiagnostiskeUndersøgelser_Del2", "SP_Behandlingsplaner_Del1",
    "SP_Bloddyrkning_Del1", "SP_Bloddyrkning_Del2", "SP_Bloddyrkning_Del3",
    "SP_Bloddyrkning_Del4", "SP_ITAOphold", "SP_Journalnotater_Del1",
    "SP_OrdineretMedicin", "SP_SocialHX", "SP_VitaleVaerdier",
    "SDS_t_adm", "SDS_forloeb", "SDS_kontakter", "SDS_t_sksopr",
    "SDS_t_sksube", "SDS_t_diag", "SDS_t_udtilsgh",
    "SDS_procedurer_kirurgi", "SDS_procedurer_andre", "SDS_diagnoser",
    "SDS_resultater", "SDS_koder", "SDS_organisationer", "SDS_epikur",
    "SDS_indberetningmedpris", "SDS_pato", "SDS_t_tumor",
    "SDS_lab_forsker", "SDS_t_dodsaarsag_2",
    "t_dalycare_diagnoses",
    "view_diagnosses_all", "view_diagnoses_all_hosp_region",
    "view_date_death", "view_date_followup", "view_true_date_death",
    "view_dalycare_diagnoses", "view_patient_table_os",
    "view_create_patient_table"
  ))
}

dalycare_default_source_map_path <- function(project_root = ".") {
  file.path(project_root, "config", "source-map.dalycare.tsv")
}

dalycare_default_bootstrap_path <- function(project_root = ".") {
  standard <- if (exists("dalycare_standard_bootstrap_path", mode = "function")) {
    dalycare_standard_bootstrap_path()
  } else {
    "/ngc/projects2/dalyca_r/clean_r/load_dalycare_package.R"
  }
  if (file.exists(standard)) return(standard)
  file.path(project_root, "inst", "templates", "dalycare_bootstrap.R")
}

check_dalycare_bootstrap <- function(project_root = ".",
                                     source_map_path = dalycare_default_source_map_path(project_root),
                                     bootstrap_path = Sys.getenv(
                                       "DALYCARE_BOOTSTRAP_PATH",
                                       dalycare_default_bootstrap_path(project_root)
                                     ),
                                     attempt_load = FALSE) {
  project_root <- normalizePath(project_root, winslash = "/", mustWork = FALSE)
  rows <- list()
  add <- function(status, check_id, message, table_name = "", detail = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      status = status,
      check_id = check_id,
      table_name = table_name %||% "",
      message = message,
      detail = detail %||% "",
      stringsAsFactors = FALSE
    )
  }

  source_map <- NULL
  source_map_path <- if (file.exists(source_map_path)) source_map_path else file.path(project_root, source_map_path)
  if (!file.exists(source_map_path)) {
    add("error", "source_map_missing", paste("Source map not found:", source_map_path))
  } else {
    source_map <- tryCatch(
      read_source_map(source_map_path, project_root = project_root),
      error = function(e) e
    )
    if (inherits(source_map, "error")) {
      add("error", "source_map_invalid", conditionMessage(source_map))
      source_map <- NULL
    } else {
      add("ok", "source_map_readable", paste("Source map rows:", nrow(source_map)))
      source_warnings <- attr(source_map, "warnings") %||% data.frame()
      if (nrow(source_warnings)) {
        for (i in seq_len(nrow(source_warnings))) {
          add(
            "warning",
            source_warnings$warning_id[[i]],
            source_warnings$message[[i]],
            table_name = source_warnings$table_name[[i]]
          )
        }
      }
      dataset_rows <- source_map$source_type == "dataset"
      unsupported <- setdiff(unique(source_map$source[dataset_rows]), dalycare_canonical_sources())
      unsupported <- unsupported[nzchar(unsupported)]
      if (length(unsupported)) {
        add(
          "warning",
          "unsupported_source_names",
          paste("Dataset source names are not in the DALY-CARE preset:", paste(unsupported, collapse = ", "))
        )
      } else {
        add("ok", "canonical_source_names", "All dataset source names match the DALY-CARE preset.")
      }
    }
  }

  package_root <- Sys.getenv("DALYCARE_PACKAGE_ROOT", unset = "")
  default_bootstrap <- normalizePath(dalycare_default_bootstrap_path(project_root), winslash = "/", mustWork = FALSE)
  selected_bootstrap <- normalizePath(bootstrap_path, winslash = "/", mustWork = FALSE)
  using_default_bootstrap <- identical(selected_bootstrap, default_bootstrap)
  if (!nzchar(package_root)) {
    status <- if (using_default_bootstrap) "error" else "warning"
    add(status, "missing_package_root", "DALYCARE_PACKAGE_ROOT is not set.")
  } else if (!dir.exists(package_root)) {
    add("error", "missing_package_root", paste("DALYCARE_PACKAGE_ROOT does not exist:", package_root))
  } else {
    add("ok", "package_root_available", paste("DALYCARE_PACKAGE_ROOT:", normalizePath(package_root, winslash = "/", mustWork = FALSE)))
  }

  bootstrap_path <- if (file.exists(bootstrap_path)) bootstrap_path else file.path(project_root, bootstrap_path)
  load_fun <- NULL
  before_global <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (!file.exists(bootstrap_path)) {
    add("error", "bootstrap_missing", paste("Bootstrap path not found:", bootstrap_path))
  } else {
    bootstrap_env <- new.env(parent = .GlobalEnv)
    sourced <- tryCatch(source(bootstrap_path, local = bootstrap_env), error = function(e) e)
    if (inherits(sourced, "error")) {
      add("error", "bootstrap_source_failed", conditionMessage(sourced))
    } else if (exists("load_dataset", mode = "function", envir = bootstrap_env, inherits = FALSE)) {
      load_fun <- get("load_dataset", envir = bootstrap_env, inherits = FALSE)
      add("ok", "load_dataset_available", "Bootstrap defined load_dataset().")
    } else if (exists("load_dataset", mode = "function", envir = .GlobalEnv, inherits = FALSE)) {
      load_fun <- get("load_dataset", envir = .GlobalEnv, inherits = FALSE)
      add("ok", "load_dataset_available", "Bootstrap defined load_dataset().")
    } else {
      add("error", "load_dataset_missing", "Bootstrap completed but did not define load_dataset().")
    }
  }

  if (isTRUE(attempt_load)) {
    if (is.null(load_fun)) {
      add("error", "db_access_not_attempted", "DB access was requested but load_dataset() is unavailable.")
    } else {
      probe <- tryCatch(load_fun(NULL), error = function(e) e)
      if (inherits(probe, "error")) {
        add("error", "db_access_attempt_failed", conditionMessage(probe))
      } else {
        add("ok", "db_access_attempted", "load_dataset(NULL) completed.")
      }
    }
  } else {
    add("ok", "db_access_skipped", "Real DB access was skipped; set DALYCARE_PREFLIGHT_ATTEMPT_LOAD=TRUE to probe it.")
  }

  created_global <- setdiff(ls(envir = .GlobalEnv, all.names = TRUE), before_global)
  if (length(created_global)) {
    rm(list = created_global, envir = .GlobalEnv)
  }

  out <- bind_rows_base(rows)
  db_adapter <- NULL
  if (exists("dalycare_access_report", mode = "function")) {
    db_adapter <- if (exists("dalycare_db_adapter", mode = "function")) {
      tryCatch(dalycare_db_adapter(bootstrap_path = bootstrap_path), error = function(e) NULL)
    } else {
      NULL
    }
    source_resolution <- if (!is.null(source_map) && exists("resolve_dalycare_sources", mode = "function")) {
      tryCatch(resolve_dalycare_sources(source_map, db_adapter = db_adapter), error = function(e) NULL)
    } else {
      NULL
    }
    access_rows <- tryCatch(
      dalycare_access_report(
        project_root = project_root,
        source_map = source_map,
        bootstrap_path = bootstrap_path,
        db_adapter = db_adapter,
        source_resolution = source_resolution
      ),
      error = function(e) data.frame(
        status = "error",
        check_id = "dalycare_access_report_failed",
        table_name = "",
        db_name = "",
        schema = "",
        message = conditionMessage(e),
        detail = "",
        stringsAsFactors = FALSE
      )
    )
    out <- bind_rows_base(list(out, access_rows))
  }
  if (exists("adjust_access_report_for_actual_impact", mode = "function")) {
    out <- adjust_access_report_for_actual_impact(out, db_adapter = db_adapter %||% NULL)
  }
  if (!nrow(out)) {
    return(empty_df(status = character(), check_id = character(), table_name = character(), message = character(), detail = character()))
  }
  out
}

dalycare_preflight_has_errors <- function(report) {
  any(report$status == "error", na.rm = TRUE)
}

write_dalycare_preflight_report <- function(report) {
  if (!nrow(report)) {
    cat("No preflight checks were produced.\n")
    return(invisible(report))
  }
  for (i in seq_len(nrow(report))) {
    table_prefix <- if (nzchar(report$table_name[[i]])) paste0(" [", report$table_name[[i]], "]") else ""
    cat(sprintf("[%s] %s%s: %s\n", report$status[[i]], report$check_id[[i]], table_prefix, report$message[[i]]))
  }
  invisible(report)
}
