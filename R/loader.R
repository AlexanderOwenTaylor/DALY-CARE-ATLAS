load_source_data <- function(source_record, project_root = ".", bootstrap_path = "") {
  source_type <- tolower(source_record$source_type[[1]])
  if (identical(source_type, "file")) {
    return(load_file_source(source_record, project_root = project_root))
  }
  if (identical(source_type, "dataset")) {
    return(load_dataset_source(source_record, bootstrap_path = bootstrap_path))
  }
  stop("Unsupported source_type: ", source_type, call. = FALSE)
}

load_file_source <- function(source_record, project_root = ".") {
  source <- source_record$source[[1]]
  path <- if (file.exists(source)) source else file.path(project_root, source)
  if (!file.exists(path)) {
    stop("File source not found: ", source, call. = FALSE)
  }
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("csv", "tsv", "txt")) {
    return(read_delimited_file(path))
  }
  if (identical(ext, "rds")) {
    x <- readRDS(path)
    if (!is.data.frame(x)) stop("RDS source did not contain a data frame: ", source, call. = FALSE)
    return(x)
  }
  if (ext %in% c("rda", "rdata")) {
    env <- new.env(parent = emptyenv())
    loaded <- load(path, envir = env)
    dfs <- loaded[vapply(loaded, function(nm) is.data.frame(get(nm, envir = env)), logical(1))]
    if (!length(dfs)) stop("RData source did not contain a data frame: ", source, call. = FALSE)
    return(get(dfs[[1]], envir = env))
  }
  stop("Unsupported file source extension: ", ext, call. = FALSE)
}

load_dataset_source <- function(source_record, bootstrap_path = "") {
  if (!exists("load_dataset", mode = "function", envir = .GlobalEnv)) {
    if (!nzchar(bootstrap_path %||% "")) {
      stop("Dataset source requires load_dataset() or DALYCARE_BOOTSTRAP_PATH.", call. = FALSE)
    }
    if (!file.exists(bootstrap_path)) {
      stop("Bootstrap path not found: ", bootstrap_path, call. = FALSE)
    }
    source(bootstrap_path, local = .GlobalEnv)
  }
  if (!exists("load_dataset", mode = "function", envir = .GlobalEnv)) {
    stop("Bootstrap did not define load_dataset().", call. = FALSE)
  }

  dataset_name <- source_record$source[[1]]
  before_global <- ls(envir = .GlobalEnv, all.names = TRUE)
  call_env <- new.env(parent = .GlobalEnv)
  call_env$load_dataset <- get("load_dataset", envir = .GlobalEnv)
  call_env$dataset_name <- dataset_name
  on.exit(clean_loader_side_effects(before_global), add = TRUE)
  result <- evalq(load_dataset(dataset_name), envir = call_env)

  extracted <- extract_loader_data_frame(result, dataset_name = dataset_name)
  if (!is.null(extracted)) {
    return(extracted)
  }

  created_global <- setdiff(ls(envir = .GlobalEnv, all.names = TRUE), before_global)
  created_call <- setdiff(ls(envir = call_env, all.names = TRUE), c("load_dataset", "dataset_name"))
  candidates <- unique(c(
    dataset_name,
    make.names(dataset_name),
    source_record$table_name[[1]],
    make.names(source_record$table_name[[1]]),
    created_call,
    created_global
  ))
  candidates <- candidates[nzchar(candidates)]
  for (env in list(call_env, .GlobalEnv)) {
    for (nm in candidates) {
      if (exists(nm, envir = env, inherits = FALSE)) {
        value <- get(nm, envir = env, inherits = FALSE)
        extracted <- extract_loader_data_frame(value, dataset_name = dataset_name)
        if (!is.null(extracted)) return(extracted)
      }
    }
  }
  stop("DalyDataLoader dataset source did not produce a data frame: ", dataset_name, call. = FALSE)
}

extract_loader_data_frame <- function(value, dataset_name = "", depth = 0L) {
  if (is.data.frame(value)) return(value)
  if (depth > 4L) return(NULL)
  preferred <- unique(c(
    dataset_name,
    make.names(dataset_name),
    paste0(dataset_name, "_subset"),
    paste0(make.names(dataset_name), "_subset"),
    "data", "result", "value", "dataset", "x"
  ))
  preferred <- preferred[nzchar(preferred)]

  if (is.environment(value)) {
    env_names <- ls(envir = value, all.names = TRUE)
    for (nm in unique(c(preferred, env_names))) {
      if (exists(nm, envir = value, inherits = FALSE)) {
        out <- extract_loader_data_frame(get(nm, envir = value, inherits = FALSE), dataset_name, depth + 1L)
        if (!is.null(out)) return(out)
      }
    }
    return(NULL)
  }

  if (is.list(value)) {
    for (nm in unique(c(preferred, names(value)))) {
      if (nzchar(nm) && nm %in% names(value)) {
        item <- value[[nm]]
      } else {
        next
      }
      out <- extract_loader_data_frame(item, dataset_name, depth + 1L)
      if (!is.null(out)) return(out)
    }
    for (j in seq_along(value)) {
      out <- extract_loader_data_frame(value[[j]], dataset_name, depth + 1L)
      if (!is.null(out)) return(out)
    }
    if (length(value) && all(vapply(value, function(x) is.atomic(x) || is.factor(x) || inherits(x, "Date"), logical(1)))) {
      lengths <- vapply(value, length, integer(1))
      if (length(unique(lengths)) == 1L && lengths[[1]] > 0L) {
        out <- tryCatch(as.data.frame(value, stringsAsFactors = FALSE), error = function(e) NULL)
        if (is.data.frame(out)) return(out)
      }
    }
  }
  NULL
}

clean_loader_side_effects <- function(before) {
  after <- ls(envir = .GlobalEnv, all.names = TRUE)
  created <- setdiff(after, before)
  if (!length(created)) return(invisible(TRUE))
  for (nm in created) {
    if (identical(nm, "load_dataset")) next
    rm(list = nm, envir = .GlobalEnv)
  }
  gc(verbose = FALSE)
  invisible(TRUE)
}
