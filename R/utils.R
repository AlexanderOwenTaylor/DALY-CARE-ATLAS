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

safe_as_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    as_text <- as.character(x)
    ymd_like <- !is.na(x) & x >= 19000101 & x <= 21001231 & grepl("^[0-9]{8}$", as_text)
    out <- rep(as.Date(NA), length(x))
    out[ymd_like] <- suppressWarnings(as.Date(as_text[ymd_like], format = "%Y%m%d"))
    remaining <- !ymd_like
    out[remaining] <- suppressWarnings(as.Date(x[remaining], origin = "1970-01-01"))
    plausible <- !is.na(out) & out >= as.Date("1900-01-01") & out <= as.Date("2100-12-31")
    out[!plausible] <- NA
    return(out)
  }
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  formats <- c("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d", "%Y%m%d", "%d.%m.%Y")
  parsed <- rep(as.Date(NA), length(x))
  for (fmt in formats) {
    missing <- is.na(parsed) & !is.na(x)
    if (!any(missing)) break
    parsed[missing] <- suppressWarnings(as.Date(x[missing], format = fmt))
  }
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
    return(jsonlite::toJSON(x, auto_unbox = TRUE, dataframe = "rows", null = "null", pretty = TRUE))
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
