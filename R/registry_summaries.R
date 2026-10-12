# Distinct-person registry summaries. Values remain private until the full-field gates pass.
registry_summary_policy <- function(project_root = ".") {
  paths <- c(file.path(project_root, "inst", "config", "registry-summary-policy.json"),
             system.file("config", "registry-summary-policy.json", package = "dalycareatlas"))
  paths <- paths[nzchar(paths) & file.exists(paths)]
  if (!length(paths) || !requireNamespace("jsonlite", quietly = TRUE)) return(list())
  policy <- tryCatch(jsonlite::fromJSON(paths[[1]], simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(policy) || !identical(policy$version, "registry-summary-v1")) return(list())
  policy$fields
}

registry_summary_k <- function(k) {
  k <- suppressWarnings(as.numeric(c(k, Sys.getenv("DALYCARE_MIN_CELL_COUNT", "5"))))
  k <- k[is.finite(k) & k >= 5 & k == floor(k)]
  if (length(k)) max(k) else 5
}

empty_registry_field_summaries <- function() {
  data.frame(contract_version=character(), table_name=character(), source_column=character(),
    kind=character(), topic=character(), phase=character(), label=character(),
    unit_status=character(), count_basis=character(), summary_method=character(),
    summary_status=character(), minimum_cell_count=numeric(), denominator_n=numeric(),
    n_valid=numeric(), n_missing=numeric(), n_invalid=numeric(), n_conflicting=numeric(),
    n_distinct=numeric(), minimum_value_support=numeric(), category_counts_json=character(),
    mean=numeric(), median=numeric(), p25=numeric(), p75=numeric(), stringsAsFactors=FALSE)
}

registry_summary_row <- function(spec, status, k) {
  out <- empty_registry_field_summaries()
  out[1, ] <- NA
  for (nm in c("table_name", "source_column", "kind", "topic", "phase", "label")) out[[nm]] <- spec[[nm]]
  out$contract_version <- "registry-summary-v1"
  out$unit_status <- "unverified"
  out$count_basis <- "distinct_people_one_unambiguous_value_per_field"
  out$summary_method <- "exact_complete_field_3sf"
  out$summary_status <- status
  out$minimum_cell_count <- k
  out$category_counts_json <- "[]"
  out
}

# Exact defaults from legacy registry definitions and the archived
# 20260831_211803-p3532373 column metadata (patientid, int4, sensitive).
# A supplied private mapping is authoritative, including invalid/disabled rows.
# No source-column heuristics or row-count fallback.
registry_summary_person_key <- function(table_name, column_names) {
  path <- Sys.getenv("DALYCARE_REGISTRY_PERSON_KEYS_FILE", "")
  if (!nzchar(path)) {
    if (!table_name %in% c("RKKP_DaMyDa", "RKKP_LYFO", "RKKP_CLL")) return(list(status="needs_person_key", key=NULL))
    if (!"patientid" %in% column_names) return(list(status="missing_person_key", key=NULL))
    return(list(status="ok", key="patientid"))
  }
  if (!file.exists(path)) return(list(status="needs_person_key", key=NULL))
  mapping <- tryCatch(read.csv(path, colClasses="character", check.names=FALSE, stringsAsFactors=FALSE), error=function(e) NULL)
  if (is.null(mapping) || !all(c("table_name", "person_key", "reviewed") %in% names(mapping))) return(list(status="needs_person_key", key=NULL))
  mapping <- mapping[!is.na(mapping$table_name) & mapping$table_name == table_name, , drop=FALSE]
  if (nrow(mapping) != 1 || is.na(mapping$reviewed[1]) || tolower(mapping$reviewed[1]) != "true" ||
      is.na(mapping$person_key[1]) || !nzchar(trimws(mapping$person_key[1]))) return(list(status="needs_person_key", key=NULL))
  key <- mapping$person_key[1]
  if (!key %in% column_names) return(list(status="missing_person_key", key=NULL))
  list(status="ok", key=key)
}

registry_summary_number <- function(x) {
  # Canonical decimal/exponent syntax, identical across R/PostgreSQL/SQLite.
  # Negative/nonfinite and other encodings are invalid, never missing-code interpretations.
  lexical <- grepl("^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?$", x)
  out <- suppressWarnings(as.numeric(x))
  out[!lexical | !is.finite(out) | out < 0] <- NA_real_
  out
}

registry_summary_gate <- function(n, denominator, k) {
  positive <- n[n > 0]
  complement <- denominator - positive
  !any(positive < k | (complement > 0 & complement < k))
}

registry_summary_weighted_quantile <- function(values, counts, p) {
  ord <- order(values); values <- values[ord]; counts <- counts[ord]
  n <- sum(counts); position <- 1 + (n-1)*p
  lo <- floor(position); hi <- ceiling(position); cumulative <- cumsum(counts)
  low <- values[which(cumulative >= lo)[1]]; high <- values[which(cumulative >= hi)[1]]
  low + (high-low)*(position-lo)
}

# groups contain only per-person resolution status and grouped valid-value counts.
registry_summary_from_groups <- function(spec, groups, k) {
  out <- registry_summary_row(spec, "query_failed", k)
  if (!is.data.frame(groups) || !all(c("status", "value", "n") %in% names(groups))) return(out)
  counts <- suppressWarnings(as.numeric(groups$n))
  if (any(!is.finite(counts) | counts < 0 | counts != floor(counts)) ||
      any(!groups$status %in% c("valid", "missing", "invalid", "conflicting", "key_missing"))) return(out)
  if (any(groups$status == "key_missing" & counts > 0)) {out$summary_status <- "missing_person_key"; return(out)}
  counts_for <- function(status) sum(counts[groups$status == status])
  parts <- c(n_valid=counts_for("valid"), n_missing=counts_for("missing"),
             n_invalid=counts_for("invalid"), n_conflicting=counts_for("conflicting"))
  denominator <- sum(parts)
  if (!parts[["n_valid"]]) {out$summary_status <- "no_values"; return(out)}
  valid <- groups[groups$status == "valid" & counts > 0, , drop=FALSE]
  valid$n <- counts[groups$status == "valid" & counts > 0]
  if (!registry_summary_gate(parts, denominator, k) || !registry_summary_gate(valid$n, denominator, k)) {
    out$summary_status <- "withheld_small_group"; return(out)
  }
  if (identical(spec$kind, "categorical")) {
    if (any(!valid$value %in% unlist(spec$categories)) || anyDuplicated(valid$value)) return(out)
    valid <- valid[order(valid$value), , drop=FALSE]
    out$category_counts_json <- as.character(jsonlite::toJSON(lapply(seq_len(nrow(valid)), function(i) list(code=as.character(valid$value[i]), n=valid$n[i])), auto_unbox=TRUE))
  } else {
    values <- registry_summary_number(as.character(valid$value))
    if (anyNA(values) || anyDuplicated(values)) return(out)
    if (parts[["n_valid"]] < 20 || min(valid$n) < k) {out$summary_status <- "withheld_small_group"; return(out)}
    if (length(values) <= 1) {out$summary_status <- "withheld_constant"; return(out)}
    if (length(values) >= .9*parts[["n_valid"]]) {out$summary_status <- "withheld_near_unique"; return(out)}
    stats <- c(mean=sum(values*(valid$n/sum(valid$n))),
               median=registry_summary_weighted_quantile(values,valid$n,.5),
               p25=registry_summary_weighted_quantile(values,valid$n,.25),
               p75=registry_summary_weighted_quantile(values,valid$n,.75))
    stats <- signif(stats,3)
    if (any(!is.finite(stats) | stats < 0)) return(out)
    for (nm in names(stats)) out[[nm]] <- stats[[nm]]
    out$n_distinct <- length(values); out$minimum_value_support <- min(valid$n)
  }
  out$summary_status <- "published"; out$denominator_n <- denominator
  for (nm in names(parts)) out[[nm]] <- parts[[nm]]
  out
}

registry_summary_final_guard <- function(rows, project_root, k) {
  if (!nrow(rows) || !exists("atlas_registry_summary_guard", mode="function")) return(rows)
  guarded <- atlas_registry_summary_guard(rows, project_root, k)
  if (is.data.frame(guarded)) return(guarded)
  if (!length(guarded)) return(empty_registry_field_summaries())
  # The public guard returns a list of named flat records.
  do.call(rbind, lapply(guarded, function(row) as.data.frame(lapply(row, function(x) if (is.null(x)) NA else x), stringsAsFactors=FALSE)))
}

registry_summary_input_text <- function(x) {
  # Base as.character(double) rounds before grouping; retain all representable digits.
  # integer64 must use its own character conversion rather than a lossy as.double.
  if (is.double(x) && !inherits(x,c("integer64","Date","POSIXt","difftime"))) {
    out <- sprintf("%.17g",x)
    out[is.na(x) & !is.nan(x)] <- NA_character_
    return(out)
  }
  as.character(x)
}

registry_field_summaries <- function(data, table_name, project_root=".", min_cell_count=5) {
  specs <- Filter(function(s) identical(s$table_name,table_name), registry_summary_policy(project_root))
  if (!length(specs)) return(empty_registry_field_summaries())
  k <- registry_summary_k(min_cell_count); key <- registry_summary_person_key(table_name,names(data))
  rows <- lapply(specs, function(spec) {
    if (!spec$source_column %in% names(data)) return(registry_summary_row(spec,"field_unavailable",k))
    if (!identical(key$status,"ok")) return(registry_summary_row(spec,key$status,k))
    pid <- registry_summary_input_text(data[[key$key]])
    if (any(is.na(pid) | trimws(pid) == "")) return(registry_summary_row(spec,"missing_person_key",k))
    value <- trimws(if (spec$kind == "numeric") registry_summary_input_text(data[[spec$source_column]]) else as.character(data[[spec$source_column]])); value[is.na(value) | value == ""] <- NA_character_
    by_person <- split(value, pid)
    resolved <- lapply(by_person, function(v) {
      v <- unique(v[!is.na(v)])
      if (!length(v)) return(c(status="missing",value=""))
      if (length(v)>1) return(c(status="conflicting",value=""))
      if (identical(spec$kind,"categorical")) {
        if (!v %in% unlist(spec$categories)) return(c(status="invalid",value=""))
      } else {
        numeric_value <- registry_summary_number(v)
        if (is.na(numeric_value)) return(c(status="invalid",value=""))
        # Retain exact source encoding for support. Distinct encodings that parse to
        # an identical double fail closed in registry_summary_from_groups().
      }
      c(status="valid",value=v)
    })
    if (!length(resolved)) groups <- data.frame(status=character(),value=character(),n=numeric()) else {
      resolved <- as.data.frame(do.call(rbind,resolved),stringsAsFactors=FALSE)
      groups <- aggregate(list(n=rep(1,nrow(resolved))),by=list(status=resolved$status,value=resolved$value),FUN=sum)
    }
    registry_summary_from_groups(spec,groups,k)
  })
  registry_summary_final_guard(do.call(rbind,rows),project_root,k)
}

registry_summary_db_dialect <- function(conn) {
  cls <- class(conn)
  if (any(grepl("SQLite",cls,fixed=TRUE))) return("sqlite")
  if (any(grepl("PqConnection|PostgreSQLConnection",cls))) return("postgres")
  "unsupported"
}

registry_summary_sql <- function(conn, table_ref, key, spec, dialect, cap) {
  q <- function(x) as.character(DBI::dbQuoteIdentifier(conn,x))
  lit <- function(x) as.character(DBI::dbQuoteString(conn,x))
  # SQL resolves each person's entire field before returning only grouped values and counts.
  trim <- function(x) if (dialect == "postgres") paste0("btrim(CAST(",x," AS TEXT), ",lit(" \t\r\n"),")") else paste0("trim(CAST(",x," AS TEXT), char(9)||char(10)||char(13)||' ')")
  v <- paste0("NULLIF(",trim(q(spec$source_column)),", '')")
  if (spec$kind == "numeric" && dialect == "sqlite") v <- paste0("CASE WHEN typeof(",q(spec$source_column),") = 'real' THEN printf('%!.17g',",q(spec$source_column),") ELSE ",v," END")
  pid <- paste0("CASE WHEN NULLIF(",trim(q(key)),", '') IS NULL THEN NULL ELSE CAST(",q(key)," AS TEXT) END")
  if (dialect == "sqlite") pid <- paste0("CASE WHEN typeof(",q(key),") = 'real' THEN printf('%!.17g',",q(key),") ELSE ",pid," END")
  if (spec$kind == "categorical") {
    valid_test <- paste0("v IN (",paste(vapply(unlist(spec$categories),lit,character(1)),collapse=","),")")
    safe_value <- "v"
  } else if (dialect == "postgres") {
    parsed <- "CASE WHEN v ~ '^-?(0|[1-9][0-9]*)([.][0-9]+)?([eE][+-]?[0-9]+)?$' THEN CAST(v AS DOUBLE PRECISION) ELSE NULL END"
    valid_test <- paste0("(",parsed,") >= 0 AND (",parsed,") <= 1.7976931348623157e308")
    safe_value <- "v"
  } else {
    # SQLite JSON number grammar prevents its permissive CAST from turning text into zero.
    parsed <- "CAST(v AS REAL)"
    valid_test <- paste0("CASE WHEN json_valid(v) THEN json_type(v) IN ('integer','real') AND ",parsed," >= 0 AND ",parsed," <= 1.7976931348623157e308 ELSE 0 END")
    safe_value <- "v"
  }
  paste0("WITH raw AS (SELECT ",pid," AS pid, ",v," AS v FROM ",table_ref,
    "), per_person AS (SELECT pid, COUNT(DISTINCT v) AS d, MIN(v) AS v FROM raw WHERE pid IS NOT NULL GROUP BY pid), ",
    "resolved AS (SELECT CASE WHEN d=0 THEN 'missing' WHEN d>1 THEN 'conflicting' WHEN ",valid_test," THEN 'valid' ELSE 'invalid' END AS status, ",
    "CASE WHEN d=1 AND (",valid_test,") THEN ",safe_value," ELSE '' END AS value FROM per_person), ",
    "grouped AS (SELECT status,value,COUNT(*) AS n FROM resolved GROUP BY status,value UNION ALL ",
    "SELECT 'key_missing','',COUNT(*) FROM raw WHERE pid IS NULL HAVING COUNT(*) > 0) SELECT status,value,n FROM grouped LIMIT ",cap+1L)
}

# Respect any stricter PostgreSQL connection timeout and cap standalone queries too.
registry_summary_query <- function(conn, sql, dialect) {
  seconds <- suppressWarnings(as.numeric(Sys.getenv("DALYCARE_REGISTRY_QUERY_SECONDS", "600")))
  if (!is.finite(seconds) || seconds <= 0 || seconds > 1200) seconds <- 600
  if (dialect == "postgres") {
    settings <- tryCatch(DBI::dbGetQuery(conn,"SELECT current_setting('statement_timeout') AS timeout, current_setting('extra_float_digits') AS precision"), error=function(e) NULL)
    if (is.null(settings) || nrow(settings) != 1 || !all(c("timeout","precision") %in% names(settings))) return(list(status="query_failed",groups=NULL))
    old <- settings$timeout[1]
    old_precision <- settings$precision[1]
    precision_set <- tryCatch({DBI::dbExecute(conn,"SET extra_float_digits TO 3"); TRUE},error=function(e) FALSE)
    if (!precision_set) return(list(status="query_failed",groups=NULL))
    on.exit(try(DBI::dbExecute(conn,paste0("SET extra_float_digits TO ",as.character(DBI::dbQuoteString(conn,old_precision)))),silent=TRUE),add=TRUE)
    previous <- suppressWarnings(as.numeric(sub("[a-z]+$","",old)))
    scale <- if (grepl("ms$",old)) 1 else if (grepl("min$",old)) 60000 else if (grepl("h$",old)) 3600000 else if (grepl("s$",old)) 1000 else 1
    milliseconds <- seconds*1000
    if (is.finite(previous) && previous > 0) milliseconds <- min(milliseconds,previous*scale)
    setting <- tryCatch({DBI::dbExecute(conn,paste0("SET statement_timeout TO ",as.character(DBI::dbQuoteString(conn,paste0(milliseconds,"ms"))))); TRUE},error=function(e) FALSE)
    if (!setting) return(list(status="query_failed",groups=NULL))
    on.exit(try(DBI::dbExecute(conn,paste0("SET statement_timeout TO ",as.character(DBI::dbQuoteString(conn,old)))),silent=TRUE),add=TRUE)
  }
  setTimeLimit(elapsed=seconds,transient=TRUE)
  on.exit(setTimeLimit(cpu=Inf,elapsed=Inf,transient=FALSE),add=TRUE)
  tryCatch(list(status="ok",groups=DBI::dbGetQuery(conn,sql)),error=function(e) {
    timed_out <- grepl("time limit|statement timeout|canceling statement|interrupted",conditionMessage(e),ignore.case=TRUE)
    list(status=if(timed_out) "resource_limit" else "query_failed",groups=NULL)
  })
}

# PostgreSQL/SQLite only: never dbReadTable or fetch an individual record for this panel.
dbi_registry_field_summaries <- function(conn, table_ref, table_name, column_names, project_root=".",
                                         min_cell_count=5, budget_context=NULL) {
  specs <- Filter(function(s) identical(s$table_name,table_name),registry_summary_policy(project_root))
  if (!length(specs)) return(empty_registry_field_summaries())
  k <- registry_summary_k(min_cell_count); key <- registry_summary_person_key(table_name,column_names)
  dialect <- registry_summary_db_dialect(conn)
  cap <- suppressWarnings(as.integer(Sys.getenv("DALYCARE_REGISTRY_MAX_GROUPS","5000")))
  if (is.na(cap) || cap < 5 || cap > 50000) cap <- 5000L
  rows <- lapply(specs,function(spec) {
    if (!spec$source_column %in% column_names) return(registry_summary_row(spec,"field_unavailable",k))
    if (!identical(key$status,"ok")) return(registry_summary_row(spec,key$status,k))
    if (dialect == "unsupported") return(registry_summary_row(spec,"query_failed",k))
    if (!is.null(budget_context) && is.function(budget_context$should_skip) &&
        budget_context$should_skip("registry_exact_person_summary",atlas_max_text_distinct_rows(),spec$source_column)) return(registry_summary_row(spec,"resource_limit",k))
    start <- proc.time()[["elapsed"]]
    sql <- registry_summary_sql(conn,table_ref,key$key,spec,dialect,cap)
    query <- registry_summary_query(conn,sql,dialect)
    groups <- query$groups
    status <- if (query$status != "ok") query$status else if (nrow(groups)>cap) "resource_limit" else "ok"
    if (!is.null(budget_context) && is.function(budget_context$add_log))
      budget_context$add_log(spec$source_column,"registry_exact_person_summary",status,
        if (status == "ok") "executed" else "withheld", "Exact complete-field registry aggregate; private values excluded from logs.",
        elapsed_ms=1000*(proc.time()[["elapsed"]]-start),strategy="sql_person_aggregate")
    if (status != "ok") return(registry_summary_row(spec,status,k))
    registry_summary_from_groups(spec,groups,k)
  })
  registry_summary_final_guard(do.call(rbind,rows),project_root,k)
}
