write_static_atlas <- function(run_dir, payload, project_root = ".") {
  site_dir <- file.path(run_dir, "site")
  dir_create(site_dir)

  template_path <- system.file("templates", "DALYCARE_atlas.html", package = "dalycareatlas")
  if (!nzchar(template_path) || !file.exists(template_path)) {
    template_path <- file.path(project_root, "inst", "templates", "DALYCARE_atlas.html")
  }
  if (!file.exists(template_path)) {
    stop("HTML template not found.", call. = FALSE)
  }

  html_path <- file.path(site_dir, "DALYCARE_atlas.html")
  payload_path <- file.path(site_dir, "DALYCARE_atlas_payload.js")
  file.copy(template_path, html_path, overwrite = TRUE)

  json <- atlas_to_json(payload)
  writeLines(c("window.DALYCARE_ATLAS_PAYLOAD = ", json, ";"), con = payload_path, useBytes = TRUE)
  list(html = html_path, payload = payload_path)
}

atlas_payload <- function(run_id, generated_at, sources, columns, checks, panels) {
  list(
    run_id = run_id,
    generated_at = generated_at,
    source_count = nrow(sources),
    loaded_source_count = sum(sources$load_status == "ok", na.rm = TRUE),
    column_count = nrow(columns),
    check_count = nrow(checks),
    sources = public_rows(sources, max_rows = 500),
    checks = public_rows(checks, max_rows = 500),
    panels = lapply(panels, public_rows, max_rows = 250)
  )
}

public_rows <- function(x, max_rows = 200) {
  if (is.null(x) || !is.data.frame(x) || !nrow(x)) return(list())
  x <- head(x, max_rows)
  lapply(seq_len(nrow(x)), function(i) {
    row <- as.list(x[i, , drop = FALSE])
    lapply(row, function(value) {
      if (length(value) == 0 || is.na(value)) NULL else as.character(value)
    })
  })
}
