`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x
}

atlas_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
}

atlas_run_id <- function() {
  paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "-p", Sys.getpid())
}

dir_create <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  invisible(path)
}

normalize_slashes <- function(path) {
  gsub("\\\\", "/", path)
}

relative_path <- function(path, root) {
  path <- normalize_slashes(normalizePath(path, winslash = "/", mustWork = FALSE))
  root <- normalize_slashes(normalizePath(root, winslash = "/", mustWork = FALSE))
  prefix <- paste0(sub("/$", "", root), "/")
  if (startsWith(path, prefix)) {
    return(substring(path, nchar(prefix) + 1L))
  }
  path
}

empty_df <- function(...) {
  out <- data.frame(..., stringsAsFactors = FALSE)
  out[0, , drop = FALSE]
}

bind_rows_base <- function(items) {
  items <- Filter(function(x) is.data.frame(x) && nrow(x) > 0, items)
  if (!length(items)) {
    return(data.frame(stringsAsFactors = FALSE))
  }
  names_all <- unique(unlist(lapply(items, names), use.names = FALSE))
  aligned <- lapply(items, function(x) {
    missing <- setdiff(names_all, names(x))
    for (nm in missing) x[[nm]] <- NA
    x[names_all]
  })
  do.call(rbind, aligned)
}

write_csv <- function(x, path) {
  dir_create(dirname(path))
  if (is.null(x)) x <- data.frame(stringsAsFactors = FALSE)
  utils::write.csv(x, file = path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(path)
}

append_csv_rows <- function(x, path) {
  if (is.null(x) || !is.data.frame(x) || !nrow(x)) return(invisible(path))
  dir_create(dirname(path))
  if (!file.exists(path)) {
    utils::write.csv(x, file = path, row.names = FALSE, na = "")
  } else {
    header <- names(utils::read.csv(path, nrows = 0, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8"))
    if (length(header)) {
      missing <- setdiff(header, names(x))
      for (nm in missing) x[[nm]] <- NA
      x <- x[header]
    }
    utils::write.table(
      x,
      file = path,
      sep = ",",
      row.names = FALSE,
      col.names = FALSE,
      append = TRUE,
      quote = TRUE,
      qmethod = "double",
      na = "",
      fileEncoding = "UTF-8"
    )
  }
  invisible(path)
}

write_tsv <- function(x, path) {
  dir_create(dirname(path))
  if (is.null(x)) x <- data.frame(stringsAsFactors = FALSE)
  utils::write.table(x, file = path, sep = "\t", row.names = FALSE, quote = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(path)
}

read_delimited_file <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("tsv", "txt")) {
    utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  } else {
    utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  }
}

# Text dates accept complete ISO calendar dates/timestamps by default. Day-first
# and compact forms require an exact reviewed source/column mapping.
atlas_date_format_pattern <- function(format_rule = "iso") {
  switch(format_rule,
    iso = "^[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})?)?$",
    dmy_dash = "^[0-9]{2}-[0-9]{2}-[0-9]{4}$",
    dmy_slash = "^[0-9]{2}/[0-9]{2}/[0-9]{4}$",
    dmy_dot = "^[0-9]{2}[.][0-9]{2}[.][0-9]{4}$",
    ymd_compact = "^[0-9]{8}$", stop("Unsupported date format rule",call.=FALSE))
}

atlas_date_rule <- function(table_name, column_name) {
  path <- Sys.getenv("DALYCARE_DATE_FORMATS_FILE", "")
  default <- list(format_rule="iso", sentinel_dates=character(), evidence_status="iso_default")
  if(!nzchar(path)) return(default)
  mapping <- read.csv(path,colClasses="character",check.names=FALSE,stringsAsFactors=FALSE)
  if(!all(c("table_name","column_name","format_rule","reviewed") %in% names(mapping))) stop("Invalid date mapping",call.=FALSE)
  if(any(is.na(mapping$table_name)|!nzchar(trimws(mapping$table_name))|is.na(mapping$column_name)|!nzchar(trimws(mapping$column_name))))stop("Invalid exact date field mapping",call.=FALSE)
  if(anyDuplicated(paste(mapping$table_name,mapping$column_name,sep="\r"))) stop("Duplicate date mapping",call.=FALSE)
  for(rule in mapping$format_rule) atlas_date_format_pattern(rule)
  if("sentinel_dates"%in%names(mapping))for(cell in mapping$sentinel_dates) {
    if(is.na(cell)||!nzchar(cell))next
    sentinels<-strsplit(cell,";",fixed=TRUE)[[1]]
    if(any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",sentinels)|is.na(safe_as_date(sentinels)))||anyDuplicated(sentinels))stop("Invalid sentinel mapping",call.=FALSE)
  }
  if(any(is.na(mapping$reviewed)|tolower(mapping$reviewed)!="true")) stop("Unreviewed date mapping",call.=FALSE)
  row <- mapping[mapping$table_name==table_name & mapping$column_name==column_name,,drop=FALSE]
  if(!nrow(row))return(default)
  sentinels <- if("sentinel_dates" %in% names(row) && !is.na(row$sentinel_dates[1])) strsplit(row$sentinel_dates[1],";",fixed=TRUE)[[1]] else character()
  if(length(sentinels) && any(is.na(safe_as_date(sentinels))))stop("Invalid sentinel mapping",call.=FALSE)
  list(format_rule=row$format_rule[1],sentinel_dates=sentinels,evidence_status="reviewed_mapping")
}

safe_as_date <- function(x, format_rule = "iso") {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x, tz="UTC"))
  parsed <- rep(as.Date(NA), length(x))
  # Numeric values never get an epoch origin; only an explicit compact mapping
  # can match their string representation.
  x <- trimws(as.character(x))
  ok <- !is.na(x) & grepl(atlas_date_format_pattern(format_rule),x)
  value <- x
  if(format_rule %in% c("dmy_dash","dmy_slash","dmy_dot")) value <- paste0(substr(x,7,10),"-",substr(x,4,5),"-",substr(x,1,2))
  if(format_rule=="ymd_compact") value <- paste0(substr(x,1,4),"-",substr(x,5,6),"-",substr(x,7,8))
  year <- suppressWarnings(as.integer(substr(value,1,4)))
  month <- suppressWarnings(as.integer(substr(value,6,7)))
  day <- suppressWarnings(as.integer(substr(value,9,10)))
  leap <- year %% 4 == 0 & (year %% 100 != 0 | year %% 400 == 0)
  days <- c(31L,28L,31L,30L,31L,30L,31L,31L,30L,31L,30L,31L)[pmax(1L,pmin(12L,month))]
  days[!is.na(month) & month==2L & !is.na(leap) & leap] <- 29L
  ok <- ok & !is.na(year) & year>=1L & month>=1L & month<=12L & day>=1L & day<=days
  if(format_rule=="iso") {
    timed <- nchar(x)>10L & !is.na(x)
    clock_ok <- suppressWarnings(as.integer(substr(x,12,13)))<=23L & suppressWarnings(as.integer(substr(x,15,16)))<=59L & suppressWarnings(as.integer(substr(x,18,19)))<=59L
    offset <- grepl("[+-][0-9]{2}:[0-9]{2}$",x)
    tail <- substring(x,pmax(1,nchar(x)-5))
    offset_ok <- suppressWarnings(as.integer(substr(tail,2,3)))<=23L & suppressWarnings(as.integer(substr(tail,5,6)))<=59L
    ok[timed] <- ok[timed] & clock_ok[timed]
    ok[offset] <- ok[offset] & offset_ok[offset]
  }
  ok[is.na(ok)] <- FALSE
  parsed[ok] <- as.Date(substr(value[ok],1,10),format="%Y-%m-%d")
  parsed
}

is_date_like_column <- function(name, x) {
  if (is_sensitive_column(name)) return(FALSE)
  name_hit <- grepl("date|dato|tidspunkt|time|(^|_)tid($|_)|dt$|_dt", name, ignore.case = TRUE)
  if (inherits(x, c("Date", "POSIXt"))) return(TRUE)
  if (!name_hit) return(FALSE)
  parsed <- safe_as_date(x)
  mean(!is.na(parsed)) >= 0.25
}

is_sensitive_column <- function(name) {
  grepl(
    paste(
      c(
        "^patientid$", "patient[_]?id", "\\bcpr\\b", "personnummer", "person[_]?id",
        "borger", "dw_ek_borger", "pnr", "civil", "socialsecurity", "ssn"
      ),
      collapse = "|"
    ),
    name,
    ignore.case = TRUE
  )
}

looks_cpr_like <- function(x) {
  x <- gsub("[^0-9]", "", as.character(x))
  nchar(x) %in% c(10, 12) & grepl("^[0-9]+$", x)
}

safe_pct <- function(n, denom) {
  if (is.na(denom) || denom <= 0) return(NA_real_)
  pmin(100, pmax(0, 100 * n / denom))
}

truncate_value <- function(x, width = 120) {
  x <- as.character(x)
  x[is.na(x)] <- NA_character_
  too_long <- !is.na(x) & nchar(x) > width
  x[too_long] <- paste0(substr(x[too_long], 1, width - 3), "...")
  x
}

schema_signature <- function(df) {
  if (!is.data.frame(df)) return(NA_character_)
  paste(paste(names(df), vapply(df, function(x) paste(class(x), collapse = "/"), character(1)), sep = ":"), collapse = "|")
}

guess_id_column <- function(df) {
  hits <- names(df)[vapply(names(df), is_sensitive_column, logical(1))]
  hits[1] %||% NA_character_
}

guess_date_column <- function(df) {
  hits <- names(df)[vapply(names(df), function(nm) is_date_like_column(nm, df[[nm]]), logical(1))]
  hits[1] %||% NA_character_
}

column_missingness <- function(x) {
  if (!length(x)) return(NA_real_)
  mean(is.na(x) | trimws(as.character(x)) == "")
}

count_distinct_capped <- function(x, cap = 100000L) {
  x <- x[!(is.na(x) | trimws(as.character(x)) == "")]
  if (!length(x)) return(0L)
  sample_x <- head(x, cap)
  length(unique(sample_x))
}

top_counts <- function(x, denom, top_n = 10L, cap = 200000L, min_count = 1L) {
  x <- as.character(x)
  x <- x[!(is.na(x) | trimws(x) == "")]
  if (!length(x)) {
    return(empty_df(value = character(), n = integer(), pct = numeric()))
  }
  x <- head(x, cap)
  tab <- sort(table(x), decreasing = TRUE)
  tab <- tab[as.integer(tab) >= min_count]
  if (!length(tab)) {
    return(empty_df(value = character(), n = integer(), pct = numeric()))
  }
  tab <- head(tab, top_n)
  data.frame(
    value = truncate_value(names(tab)),
    n = as.integer(tab),
    pct = vapply(as.integer(tab), safe_pct, numeric(1), denom = denom),
    stringsAsFactors = FALSE
  )
}

class_scalar <- function(x) {
  paste(class(x), collapse = "/")
}

atlas_to_json <- function(x) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    return(jsonlite::toJSON(x, auto_unbox = TRUE, dataframe = "rows", null = "null", pretty = FALSE))
  }
  atlas_json_value(x)
}

atlas_repair_mojibake_text <- function(x) {
  if (!length(x)) return(x)
  out <- enc2utf8(as.character(x))
  replacements <- c(
    "ÃƒÆ’Ã¢â‚¬Â " = "Æ",
    "Ãƒâ€ " = "Æ",
    "Ã†" = "Æ",
    "Ã˜" = "Ø",
    "Ã…" = "Å",
    "Ã¦" = "æ",
    "Ã¸" = "ø",
    "Ã¥" = "å",
    "Ã„" = "Ä",
    "Ã–" = "Ö",
    "Ãœ" = "Ü",
    "Ã¤" = "ä",
    "Ã¶" = "ö",
    "Ã¼" = "ü",
    "Ã©" = "é",
    "Ã¨" = "è",
    "Ã¡" = "á",
    "Ã­" = "í",
    "Ã³" = "ó",
    "Ãº" = "ú",
    "â€”" = "—",
    "â€“" = "-",
    "â€˜" = "'",
    "â€™" = "'",
    "â€œ" = "\"",
    "â€�" = "\"",
    "â€¦" = "...",
    "Â·" = "·",
    "Â±" = "±",
    "Âµ" = "µ",
    "Â°" = "°",
    "Â" = ""
  )
  for (pattern in names(replacements)) {
    out <- gsub(pattern, replacements[[pattern]], out, fixed = TRUE, useBytes = FALSE)
  }
  out
}

atlas_sanitize_payload_text <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) {
    out <- x
    for (nm in names(out)) {
      if (is.character(out[[nm]])) {
        out[[nm]] <- atlas_repair_mojibake_text(out[[nm]])
      } else if (is.factor(out[[nm]])) {
        out[[nm]] <- atlas_repair_mojibake_text(as.character(out[[nm]]))
      } else if (is.list(out[[nm]])) {
        out[[nm]] <- lapply(out[[nm]], atlas_sanitize_payload_text)
      }
    }
    return(out)
  }
  if (is.list(x)) {
    return(lapply(x, atlas_sanitize_payload_text))
  }
  if (is.character(x) || is.factor(x)) {
    return(atlas_repair_mojibake_text(as.character(x)))
  }
  x
}

atlas_json_value <- function(x) {
  if (is.null(x)) return("null")
  if (is.data.frame(x)) {
    rows <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
    return(atlas_json_value(rows))
  }
  if (is.list(x)) {
    nm <- names(x)
    if (!is.null(nm) && all(nzchar(nm))) {
      fields <- vapply(seq_along(x), function(i) {
        paste0(atlas_json_string(nm[[i]]), ":", atlas_json_value(x[[i]]))
      }, character(1))
      return(paste0("{", paste(fields, collapse = ","), "}"))
    }
    values <- vapply(x, atlas_json_value, character(1))
    return(paste0("[", paste(values, collapse = ","), "]"))
  }
  if (length(x) == 0) return("null")
  if (length(x) > 1) {
    return(paste0("[", paste(vapply(x, atlas_json_value, character(1)), collapse = ","), "]"))
  }
  if (is.na(x)) return("null")
  if (is.logical(x)) return(if (isTRUE(x)) "true" else "false")
  if (is.numeric(x) || is.integer(x)) return(as.character(x))
  atlas_json_string(as.character(x))
}

atlas_json_string <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub("\"", "\\\\\"", x)
  x <- gsub("\n", "\\\\n", x)
  x <- gsub("\r", "\\\\r", x)
  x <- gsub("\t", "\\\\t", x)
  paste0("\"", x, "\"")
}
