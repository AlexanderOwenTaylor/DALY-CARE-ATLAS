atlas_availability_unsafe <- function(row,k,total=NULL) {
  number<-function(v)if(is.null(v)||length(v)!=1L||is.logical(v)||is.na(suppressWarnings(as.numeric(v))))NA_real_ else suppressWarnings(as.numeric(v))
  if(identical(row$availability_privacy_status,'withheld_small_complementary_cells'))return(TRUE)
  n<-number(row$n_rows);if(!is.finite(n))n<-number(total)
  cells<-vapply(c('n_available','n_missing'),function(key)number(row[[key]]),numeric(1))
  if(is.finite(n)){cells<-c(cells,n-cells);for(key in c('pct_available','pct_missing')){pct<-number(row[[key]]);if(is.finite(pct))cells<-c(cells,n*pct/100,n*(100-pct)/100)}}
  any(is.finite(cells)&cells>0&cells<k)
}
# Final serialization guard. Public counts are source rows, not unique people.
atlas_public_privacy <- function(payload, project_root = ".", min_cell_count = 5, metadata_context = NULL) {
  if(!exists('atlas_metadata_only',mode='function'))source(file.path(project_root,'R/metadata_privacy.R'),local=TRUE)
  if(is.null(metadata_context))metadata_context<-atlas_metadata_context(payload,project_root)
  num <- function(x) {
    if (is.null(x) || length(x) != 1L || is.logical(x)) return(NA_real_)
    z <- suppressWarnings(as.numeric(x)); if (!is.finite(z)) NA_real_ else z
  }
  k <- num(min_cell_count); if (is.na(k)) k <- 5
  k <- max(5, ceiling(k))
  previous_registry_k <- num(payload$privacy_metadata$minimum_cell_count)
  environment_k <- num(Sys.getenv('DALYCARE_MIN_CELL_COUNT','5'))
  archived_rows <- payload$run_summary
  if(is.data.frame(archived_rows)) archived_rows <- lapply(seq_len(nrow(archived_rows)),function(i) as.list(archived_rows[i,,drop=FALSE]))
  archived_k <- vapply(archived_rows,function(row) if(is.list(row)&&identical(row$metric,'min_cell_count')) num(row$value) else NA_real_,numeric(1))
  k <- max(k,if(is.na(previous_registry_k)) 5 else ceiling(previous_registry_k),if(is.na(environment_k)) 5 else ceiling(environment_k),ceiling(archived_k[is.finite(archived_k)]))
  registry_k <- k
  policy_path <- file.path(project_root, "config", "public-measurement-policy.csv")
  if (!file.exists(policy_path)) policy_path <- system.file("config", "public-measurement-policy.csv", package = "dalycareatlas")
  policy <- if (nzchar(policy_path) && file.exists(policy_path)) utils::read.csv(policy_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8") else data.frame(table_name = character(), column_name = character())
  approved <- paste(policy$table_name, policy$column_name, sep = "\r")
  stats <- c("min", "max", "mean", "median", "p25", "p75", "sd", "q25", "q75", "iqr")
  dates <- c("min_date","max_date","raw_min_date","raw_max_date","display_min_date","display_max_date","date_min","date_max","date_range","display_min_year","display_max_year","as_of_date","lag_days")
  values <- c("value","label","top_value","mode","sample","samples","example","examples","snippet","raw_value","category","category_value","breakdown_value","display_value","raw_code","raw_descriptor","statistic_value")
  reference <- c("npu_display_dictionary","clinical_display_dictionary")
  protected_pattern <- "(^id$|(^|_)id($|_)|id$|^dw_ek_|identifier|uuid|guid|accession|requisition|record|recnum|contact|cpr|pnr|patient|person|name|address|email|phone|report|text|comment|postcode|municip|organisation|organization|location|drug|medication)"
  scalar <- function(r, key, default = "") { x <- r[[key]]; if (is.null(x) || !length(x) || is.na(x[1])) default else as.character(x[1]) }
  rows <- payload$column_profile_rows
  if (is.data.frame(rows)) rows <- lapply(seq_len(nrow(rows)), function(i) as.list(rows[i,,drop=FALSE]))
  profiles <- list()
  for (r in rows) profiles[[paste(scalar(r,"table_name"),scalar(r,"column_name"),sep="\r")]] <- r
  source_totals<-list();for(row in payload$sources)if(is.list(row)&&!is.null(row$table_name))source_totals[[row$table_name]]<-row$n_rows
  blank <- function(r, keys) { for (key in intersect(keys,names(r))) r[key] <- list(NULL); r }
  year_paths <- list(c('panels','atlas_temporal_coverage_years'),c('review_temporal_coverage','years'))
  range_rows <- c(payload$panels$atlas_temporal_coverage_years,payload$review_temporal_coverage$years)
  has_ranges <- any(vapply(range_rows,function(r) is.list(r) && scalar(r,'coverage_basis') == 'source_date_range',logical(1)))
  walk <- function(obj, path = character()) {
    if(length(path) && tail(path,1)%in%c("coverage_evidence","vital_descriptors","vital_descriptor_assessment"))return(list())
    summary_row<-function(r)is.list(r)&&!is.null(names(r))&&any(c('category_counts_json','numeric_groups_json') %in% names(r))
    summary_table<-is.list(obj)&&is.null(names(obj))&&any(vapply(obj,summary_row,logical(1)))
    if((length(path) && tail(path,1)=='registry_field_summaries')||summary_row(obj)||summary_table) {
      if(!exists('atlas_registry_summary_guard',mode='function')) {
        helper <- file.path(project_root,'R','registry_summary_privacy.R')
        if(file.exists(helper)) source(helper,local=environment(),encoding='UTF-8')
      }
      if(!exists('atlas_registry_summary_guard',mode='function')) return(list())
      result<-atlas_registry_summary_guard(if(summary_row(obj))list(obj) else obj,project_root,registry_k)
      return(if(summary_row(obj))if(length(result))result[[1]] else list() else result)
    }
    if (is.data.frame(obj)) obj <- lapply(seq_len(nrow(obj)), function(i) as.list(obj[i,,drop=FALSE]))
    if (!is.list(obj)) {
      if (is.character(obj) && length(path) && tail(path,1) %in% c("message","note","story","date_qc","description")) return(gsub("\\b[0-9]{4}-[0-9]{2}-[0-9]{2}\\b","[clinical date withheld]",obj,perl=TRUE))
      return(obj)
    }
    if (is.null(names(obj))) {
      if (any(vapply(year_paths,identical,logical(1),y=path))) {
        normalized <- list(); seen <- character()
        for(row in obj) {
          if(is.list(row) && scalar(row,'coverage_basis') == 'source_date_range') {
            identity <- jsonlite::toJSON(row[c('table_name','date_column','coverage_basis')],auto_unbox=TRUE,null='null')
            if(identity %in% seen) next
            seen <- c(seen,identity)
            row <- row[intersect(c('table_name','domain','subdomain','atlas_role','date_column','coverage_basis'),names(row))]
            row[c('year','n_rows','pct_rows')] <- list(NULL,NULL,NULL)
            row$date_privacy_status <- 'withheld_derived_source_range'
          }
          normalized[[length(normalized)+1L]] <- row
        }
        obj <- normalized
      }
      structural_path <- identical(path,"panel_groups") || identical(path,c("review_overview","panel_groups")) || (length(path) > 0 && tail(path,1) == "panels" && startsWith(path[1],"review_"))
      structural_rows <- all(vapply(obj,function(x) is.list(x) && setequal(names(x),c("group","panel_name","title","n_rows")),logical(1)))
      if (structural_path && structural_rows) {
        if(has_ranges) obj <- lapply(obj,function(r) {if(scalar(r,'panel_name') == 'atlas_temporal_coverage_years') r['n_rows'] <- list(NULL);r})
        return(obj)
      }
      out <- lapply(obj,walk,path=path)
      small <- any(vapply(obj,function(x) {
        if (!is.list(x)) return(FALSE)
        counts <- vapply(intersect(c("n","n_rows","n_observed","n_patients","count","frequency","choropleth_value","damyda_n","matched_rows","matched_patients"),names(x)),function(key) num(x[[key]]),numeric(1))
        any(!is.na(counts) & counts > 0 & counts < k)
      },logical(1)))
      if (small) out <- lapply(out,function(r) {
        if (!is.list(r)) return(r)
        r <- blank(r,c("n","n_rows","n_observed","n_patients","count","frequency","choropleth_value","damyda_n","matched_rows","matched_patients","pct",grep("^pct_",names(r),value=TRUE)))
        r$count_privacy_status <- "withheld_residual_small_distribution"; r
      })
      return(out)
    }
    if(atlas_metadata_identity_approved(obj,path,project_root,metadata_context))return(atlas_metadata_screen(obj,metadata_context))
    if(atlas_metadata_path(path))return(atlas_metadata_fallback(obj,metadata_context))
    if(has_ranges && identical(path,c('review_temporal_coverage','summary')) && 'n_year_rows' %in% names(obj)) obj['n_year_rows'] <- list(NULL)
    r <- obj
    r[c("sampling_method","sample_size","eligible_n","sampling_complete")] <- NULL
    coverage_year <- "year" %in% names(r) && "coverage_basis" %in% names(r)
    coverage_region <- "region_code" %in% names(r) && "count_basis" %in% names(r)
    if(coverage_year || coverage_region || "quality_state" %in% names(r)) {
      support_k<-num(r$support_k)
      supported <- is.finite(support_k) && support_k>=k &&
        all(vapply(c("person_support_safe","outside_person_support_safe","outside_record_support_safe"),function(key)identical(r[[key]],TRUE),logical(1)))
      valid <- identical(r$partition_complete,TRUE) && supported
      label_only <- supported && (coverage_year || coverage_region) &&
        (identical(r$coverage_basis,"person_supported_label_only") || identical(r$count_basis,"person_supported_label_only"))
      # Distinct people can overlap across years/regions. Publishing exact
      # support series and their union can expose a small intersection.
      r[c("person_count","outside_person_count","outside_record_count","total_person_count","total_record_count")]<-NULL
      if(!valid) {
        r <- blank(r,c("n_rows","pct_rows"))
        if(!label_only)r <- blank(r,c("year","region_code","region_name","quality_state"))
        r$count_privacy_status <- if(label_only)"withheld_partition_counts" else "unavailable_person_partition_evidence"
      }
    }
    if("coverage_status" %in% names(r) && "basis" %in% names(r) && scalar(r,"basis")!="person_supported_region_records") {
      r <- blank(r,c("n_rows","pct_rows"))
      if(scalar(r,"coverage_status")=="observed")r$coverage_status<-"not_assessed"
    }
    if("choropleth_basis" %in% names(r) && scalar(r,"choropleth_basis")!="person_supported_region_records")
      r<-blank(r,c("damyda_n","choropleth_value","pct_total"))
    for (key in names(r)) if (!key %in% reference) r[key] <- list(walk(r[[key]],c(path,key)))
    r <- blank(r,dates)
    if (any(dates %in% names(r))) r$date_privacy_status <- "withheld_exact_clinical_bounds"
    field <- scalar(r,"column_name",scalar(r,"source_column",scalar(r,"date_column",scalar(r,"raw_column"))))
    table <- scalar(r,"table_name",scalar(r,"registry"))
    profile <- "profile_kind" %in% names(r) || all(c("column_name","n_available") %in% names(r))
    available_cells <- vapply(c("n_available","n_missing"),function(key) num(obj[[key]]),numeric(1))
    if (atlas_availability_unsafe(obj,k,source_totals[[table]])) {
      r <- blank(r,c("n_available","n_missing","pct_available","pct_missing"))
      r$availability_privacy_status <- "withheld_small_complementary_cells"
    }
    provenance <- profiles[[paste(table,field,sep="\r")]]
    if (!is.null(provenance)) {
      cells <- vapply(c("n_available","n_missing"),function(key) num(provenance[[key]]),numeric(1))
      if (atlas_availability_unsafe(provenance,k,source_totals[[table]])) {
        r <- blank(r,c("n_available","n_missing","pct_available","pct_missing"))
        r$availability_privacy_status <- "withheld_small_complementary_cells"
      }
    }
    protected <- (nzchar(field) && grepl(protected_pattern,field,ignore.case=TRUE)) || tolower(scalar(r,"is_sensitive")) == "true" || scalar(r,"profile_kind") == "sensitive"
    if (profile || any(stats %in% names(r))) {
      original <- profiles[[paste(table,field,sep="\r")]]
      if (is.null(original)) original <- obj
      support <- num(original$n_available); missing <- num(original$n_missing)
      if ((!is.na(support) && support > 0 && support < k) || (!is.na(missing) && missing > 0 && missing < k)) {
        r <- blank(r,c("n_available","n_missing","pct_available","pct_missing"))
        r$availability_privacy_status <- "withheld_small_complementary_cells"
      }
      distinct <- num(original$n_distinct_capped); minimum <- num(original$min)
      reason <- if (protected) "protected_field" else if (!paste(table,field,sep="\r") %in% approved) "needs_validation_unreviewed_field" else if (is.na(support)) "withheld_unknown_support" else if (support < k) { if (support == 0) "unavailable_zero_support" else "withheld_insufficient_support" } else if (is.na(distinct)) "needs_validation_unknown_distinctness" else if (distinct <= 1) "withheld_constant_profile" else if (distinct >= support * 0.9) "withheld_near_unique_profile" else if (is.na(minimum) && scalar(original,"numeric_privacy_status") != "eligible_stored_summary") "needs_validation_missing_range_evidence" else if (!is.na(minimum) && minimum < 0) "needs_validation_negative_sentinel" else "eligible_stored_summary"
      previous <- scalar(r,"numeric_privacy_status")
      if (!reason %in% c("protected_field","needs_validation_unreviewed_field") && scalar(r,"availability_privacy_status") == "withheld_small_complementary_cells") reason <- "withheld_small_complementary_cells"
      if (nzchar(previous) && previous != "eligible_stored_summary") reason <- previous
      # Legacy source-row support and markers cannot prove person support, units or safe bands.
      if (reason == 'eligible_stored_summary') reason <- 'needs_verified_grouped_evidence'
      r <- blank(r,stats)
      r$numeric_privacy_status <- reason
      r$summary_scope <- "stored_source_row_profile"
      r$summary_method <- "supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample"
      if (protected) { r$is_sensitive <- TRUE; r$value_privacy_status <- "protected_field"; r <- blank(r,values) }
      if (protected || is.na(support) || support < k || scalar(r,"availability_privacy_status") == "withheld_small_complementary_cells") r <- blank(r,"n_distinct_capped")
    }
    if (protected) { r <- blank(r,values); r$value_privacy_status <- "protected_field" }
    observed <- any(values %in% names(r)) && (any(c("n","n_observed","n_patients","n_rows","frequency","count","pct_rows") %in% names(r)) || any(grepl("top_value|value_map",path)) || "panel_distribution_rows" %in% path)
    code_usage <- "code_column" %in% names(r) && any(c("n","n_rows","n_observed") %in% names(r))
    if (observed || code_usage) {
      schemas <- list(npu_dictionary_summary=c("metric","label","value"),npu_dictionary_vectors=c("consensus_vector","n_dictionary_codes","systems"),panel_kpi_rows=c("panel_id","kpi_id","unit","count_scope"),registry_clinical_summary=c("table_name","registry","n_cols"),situation_report_summary=c("metric_id","definition_basis","definition_status"),atlas_spatial_region_coverage=c("region_code","coverage_status","basis"),atlas_dk_choropleth_regions=c("region_code","svg_path","choropleth_basis"))
      safe <- !nzchar(field) && any(vapply(names(schemas),function(key) key %in% path && all(schemas[[key]] %in% names(r)),logical(1)))
      structural_section <- "panel_distribution_rows" %in% path && scalar(r,"distribution_type") == "clinical_section" && scalar(r,"value_class") == "section" && all(vapply(c("n","pct","statistic","statistic_value","raw_column","raw_descriptor","raw_code","raw_value"),function(key) scalar(r,key) == "",logical(1)))
      if (!structural_section && any(vapply(c("display_value","raw_code","raw_value","raw_descriptor","statistic_value"),function(key) scalar(r,key) != "",logical(1)))) safe <- FALSE
      if (!(safe || structural_section)) {
        r <- blank(r,c(values,"code","npu_code","lab_code","n","n_rows","n_observed","n_patients","frequency","count","pct_rows","pct_patients","pct"))
        r$value_privacy_status <- "withheld_unvalidated_distribution"
      }
    }
    count_keys <- intersect(c("n","n_rows","n_observed","n_patients","matched_rows","matched_patients","n_cohort","damyda_n","choropleth_value"),names(r))
    counts <- vapply(count_keys,function(key) num(r[[key]]),numeric(1))
    if (any(!is.na(counts) & counts > 0 & counts < k)) {
      r <- blank(r,c(count_keys,"pct",grep("^pct_",names(r),value=TRUE)))
      r$count_privacy_status <- "withheld_small_cells"
    }
    r
  }
  result <- walk(payload)
  result$privacy_metadata <- list(policy_version="2026-10-11-public-privacy-1", minimum_cell_count=k, count_basis="legacy summaries: source_rows; published registry_field_summaries: distinct people per exact field", categorical_policy="legacy distributions withheld; registry_field_summaries require complete-field distinct-person validation", summary_scope="stored_source_row_profile")
  result
}
