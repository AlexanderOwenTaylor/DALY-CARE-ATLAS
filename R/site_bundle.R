# Matched bounded transport and staged publication for R-only installations.
atlas_bundle_json <- function(x) as.character(jsonlite::toJSON(x,auto_unbox=TRUE,null='null',na='null',digits=NA))
atlas_bundle_aliases <- function() c(action_items='action_items',action_summary='action_summary',streaming_summary='review_streaming_summary',temporal_date_quality='review_temporal_date_quality',db_budget_actions='db_budget_actions',db_query_log='db_query_log',catalog='catalog_rows',resource_reconciliation='resource_reconciliation_rows',canonical_resource_reconciliation='canonical_resource_reconciliation_rows',current_run_source_map_audit='current_run_source_map_audit_rows',source_map_crosswalk='source_map_crosswalk_rows',source_resolution_delta='source_resolution_delta_rows',legacy_resource_audit='legacy_cartography_audit_rows',columns='column_profile_rows',column_summary='column_profile_summary',panels='panel_groups',qa='qa_items',run_summary='run_summary')
atlas_payload_transport <- function(payload) {
  aliases <- list(); pairs <- atlas_bundle_aliases()
  for(target in names(pairs)) {
    source <- pairs[[target]]; a <- payload$review_infrastructure_sections[[target]]; b <- payload[[source]]
    if(is.list(a) && is.null(names(a)) && is.list(b) && is.null(names(b)) && identical(atlas_bundle_json(a),atlas_bundle_json(b))) {
      payload$review_infrastructure_sections[target] <- NULL
      aliases[[length(aliases)+1L]] <- list(target=list('review_infrastructure_sections',target),source=list(source))
    }
  }
  list(transport_version=1L,payload=payload,aliases=aliases)
}
atlas_bundle_resource <- function(name,project_root) {
  path <- file.path(project_root,'inst/templates',name)
  if(!file.exists(path)) path <- system.file('templates',name,package='dalycareatlas')
  if(!nzchar(path) || !file.exists(path)) stop('Site resource unavailable: ',name,call.=FALSE)
  path
}
atlas_write_site_bundle <- function(site_dir,payload,tables,project_root='.',provenance='legacy_payload',manifest_paths=list()) {
  registry <- atlas_output_registry(project_root); minimum <- atlas_effective_threshold(payload)
  if(!exists('atlas_public_privacy',mode='function')) source(file.path(project_root,'R/public_privacy.R'),encoding='UTF-8')
  if(!provenance %in% c('csv_outputs','legacy_payload')) stop('Invalid entry provenance',call.=FALSE)
  logical <- payload; ids <- vapply(registry$artifacts,function(s)s$id,character(1))
  for(table in tables) {
    index <- match(table$id,ids); if(is.na(index)) next
    spec <- registry$artifacts[[index]]
    if(length(spec$payload_path) && length(spec$projection)) logical <- atlas_evidence_set(logical,unlist(spec$payload_path),table$rows)
  }
  safe <- atlas_public_privacy(logical,project_root,minimum)
  payload <- atlas_public_privacy(payload,project_root,minimum)
  atlas_evidence_audit(safe);atlas_evidence_audit(payload)
  transport <- atlas_bundle_json(atlas_payload_transport(atlas_sanitize_payload_text(payload)))
  parent <- dirname(site_dir);dir.create(parent,recursive=TRUE,showWarnings=FALSE)
  parent <- normalizePath(parent,winslash='/',mustWork=TRUE)
  output <- file.path(parent,basename(site_dir))
  if(dir.exists(output) && !identical(tolower(normalizePath(output,winslash='/')),tolower(output))) stop('Unsafe linked site destination',call.=FALSE)
  if(basename(site_dir) %in% c('','..','.') || nzchar(Sys.readlink(output)) || (file.exists(output) && !dir.exists(output))) stop('Unsafe site destination',call.=FALSE)
  stage <- tempfile(paste0('.',basename(output),'-stage-'),tmpdir=parent);dir.create(stage)
  stage <- normalizePath(stage,winslash='/',mustWork=TRUE)
  # Build IDs are controlled hexadecimal, independent of display run IDs.
  build_id <- paste(sample(c(0:9,letters[1:6]),32,replace=TRUE),collapse='')
  backup <- paste0(output,'-previous-',build_id)
  manifest <- atlas_confined_path(parent,'outputs/output_manifest.csv')
  dir.create(dirname(manifest),recursive=TRUE,showWarnings=FALSE)
  manifest <- atlas_confined_path(parent,'outputs/output_manifest.csv')
  manifest_stage <- file.path(parent,paste0('.',basename(output),'-manifest-stage-',build_id,'.csv'))
  manifest_backup <- paste0(manifest,'-previous-',build_id)
  on.exit({if(dir.exists(stage)) unlink(stage,recursive=TRUE);if(file.exists(manifest_stage)) unlink(manifest_stage)},add=TRUE)
  write <- function(name,text) {
    path <- atlas_confined_path(stage,name)
    con <- file(path,'wb');on.exit(close(con));writeBin(charToRaw(enc2utf8(text)),con)
  }
  resources <- c(DALYCARE_atlas.html='DALYCARE_entry.html',DALYCARE_clinical.html='DALYCARE_atlas.html',DALYCARE_outputs.html='DALYCARE_outputs.html',`atlas-entry.js`='atlas-entry.js',`atlas-outputs.js`='atlas-outputs.js',`atlas-transport.js`='atlas-transport.js',`atlas-pages.css`='atlas-pages.css')
  for(name in names(resources)) if(!file.copy(atlas_bundle_resource(resources[[name]],project_root),file.path(stage,name))) stop('Resource copy failed',call.=FALSE)
  write('DALYCARE_atlas_payload.js',paste0('window.DALYCARE_ATLAS_PAYLOAD = ',transport,';\n'))
  write('DALYCARE_atlas_payload.json',paste0(transport,'\n'))
  write('DALYCARE_entry.js',paste0('window.DALYCARE_ENTRY = ',atlas_bundle_json(list(schema_version=1L,build_id=build_id,run_id=payload$run_id %||% '',provenance=provenance)),';\n'))
  dir.create(file.path(stage,'output-shards'))
  registration <- function(table_id,shard_id,rows) {
    data <- paste0('[',paste(unlist(rows,use.names=FALSE),collapse=','),']')
    script <- paste0('window.DALYCARE_OUTPUTS.register(',atlas_bundle_json(list(schema_version=1L,build_id=build_id,table_id=table_id,shard_id=shard_id,rows_json=data)),');\n')
    list(data=data,script=script,bytes=nchar(enc2utf8(data),type='bytes'))
  }
  fits <- function(x) x$bytes<=262144 && nchar(enc2utf8(x$script),type='bytes')<=262144
  catalog_tables <- list();total <- 0;seen <- character()
  privacy <- c('value_privacy_status','count_privacy_status','date_privacy_status','availability_privacy_status','numeric_privacy_status','summary_scope','summary_method','is_sensitive')
  for(table in tables) {
    id <- table$id
    if(!grepl('^[A-Za-z0-9_-]+$',id) || id %in% seen) stop('Invalid table identity',call.=FALSE)
    seen <- c(seen,id); index <- match(id,ids); spec <- if(!is.na(index)) registry$artifacts[[index]] else NULL
    rows <- if(length(spec$projection) && length(spec$payload_path)) atlas_evidence_get(safe,unlist(spec$payload_path)) else list()
    keys <- vapply(table$columns,function(c)c$key,character(1))
    if(any(!keys %in% c(unlist(spec$projection),if(!is.null(spec)) privacy)) || (is.null(spec) && (length(keys) || nzchar(table$source_file)))) stop('Unreviewed public schema',call.=FALSE)
    rows <- lapply(rows,function(r)setNames(lapply(keys,function(k)r[[k]]),keys))
    table$rows <- NULL;table$shards <- list()
    if(identical(table$status,'snapshot_preview')) table$status <- 'limited'
    parts <- list();pending <- list()
    for(row in rows) {
      for(column in table$columns) {
        v <- row[[column$key]]
        valid <- is.null(v) || (length(v)==1 && switch(column$type,string=is.character(v),boolean=is.logical(v),number=is.numeric(v) && is.finite(v),FALSE))
        if(!valid) stop('Typed evidence mismatch: ',id,call.=FALSE)
      }
      serialized <- atlas_bundle_json(row)
      trial <- c(pending,list(serialized)); shard_id <- sprintf('s%04d',length(parts)+1L)
      item <- registration(id,shard_id,trial)
      if(length(trial)>250 || !fits(item)) {
        if(length(pending)) parts[[length(parts)+1L]] <- pending
        pending <- list()
        if(!fits(registration(id,sprintf('s%04d',length(parts)+1L),list(serialized)))) {
          if(isTRUE(spec$required)) stop('Required table row exceeds shard limit',call.=FALSE)
          parts <- list();rows <- list();table$status <- 'unavailable';table$reason <- 'Row exceeds public shard byte limit';table$complete <- FALSE;break
        }
      }
      pending[[length(pending)+1L]] <- serialized
    }
    if(length(pending)) parts[[length(parts)+1L]] <- pending
    table$represented_row_count <- length(rows)
    for(i in seq_along(parts)) {
      shard_id <- sprintf('s%04d',i);item <- registration(id,shard_id,parts[[i]])
      relative <- paste0('output-shards/',id,'-',shard_id,'.js');write(relative,item$script)
      total <- total+item$bytes
      table$shards[[i]] <- list(id=shard_id,src=relative,rows=length(parts[[i]]),bytes=item$bytes)
    }
    catalog_tables[[length(catalog_tables)+1L]] <- table
  }
  if(total>registry$public_table_max_bytes) stop('Public table-data budget exceeded',call.=FALSE)
  limits <- list(input_max_bytes=registry$input_max_bytes,public_table_max_bytes=registry$public_table_max_bytes,shard_max_rows=250L,shard_max_bytes=262144L,cache_max_bytes=1048576L,page_rows=50L,minimum_cell_count=minimum,public_table_bytes=total)
  catalogue <- list(schema_version=1L,build_id=build_id,run_id=payload$run_id %||% '',provenance=provenance,privacy_policy_version=payload$privacy_metadata$policy_version,limits=limits,tables=catalog_tables)
  write('DALYCARE_output_catalogue.js',paste0('window.DALYCARE_OUTPUT_CATALOGUE = ',atlas_bundle_json(catalogue),';\n'))
  for(names in list(c('DALYCARE_atlas.html','DALYCARE_entry.js','atlas-entry.js','atlas-pages.css'),c('DALYCARE_outputs.html','DALYCARE_output_catalogue.js','atlas-outputs.js','atlas-pages.css'))) if(sum(file.info(file.path(stage,names))$size)>524288) stop('Initial asset byte budget exceeded',call.=FALSE)
  files <- list.files(stage,recursive=TRUE,full.names=FALSE)
  if(any(file.info(file.path(stage,files))$size==0)) stop('Empty site asset',call.=FALSE)
  stage_assets <- as.list(setNames(file.path(stage,files),paste0('site_',seq_along(files))))
  internal <- output_manifest(c(manifest_paths,stage_assets),parent)
  site_rows <- match(unlist(stage_assets,use.names=FALSE),internal$path)
  if(anyNA(site_rows)) stop('Incomplete staged manifest',call.=FALSE)
  internal$relative_path[site_rows] <- paste0(basename(output),'/',files)
  internal$path[site_rows] <- file.path(output,files)
  if(anyDuplicated(internal$relative_path) || any(internal$file_size_bytes[site_rows]!=file.info(file.path(stage,files))$size)) stop('Invalid staged manifest',call.=FALSE)
  write_csv(internal,manifest_stage)
  # Promote the public directory and internal manifest as one recoverable pair.
  moved_site <- moved_manifest <- published_site <- FALSE
  tryCatch({
    if(dir.exists(output)) {
      if(!file.rename(output,backup)) stop('Cannot preserve previous site',call.=FALSE)
      moved_site <- TRUE
    }
    if(file.exists(manifest)) {
      if(!file.rename(manifest,manifest_backup)) stop('Cannot preserve previous manifest',call.=FALSE)
      moved_manifest <- TRUE
    }
    if(!file.rename(stage,output)) stop('Site publication failed',call.=FALSE)
    published_site <- TRUE
    if(!file.rename(manifest_stage,manifest)) stop('Manifest publication failed',call.=FALSE)
  },error=function(e) {
    if(published_site) unlink(output,recursive=TRUE)
    if(moved_site && !file.rename(backup,output)) stop('Previous site retained at ',backup,call.=FALSE)
    if(moved_manifest && !file.rename(manifest_backup,manifest)) stop('Previous manifest retained at ',manifest_backup,call.=FALSE)
    stop(e)
  })
  if(moved_site) unlink(backup,recursive=TRUE)
  if(moved_manifest) unlink(manifest_backup)
  list(html=file.path(output,'DALYCARE_atlas.html'),clinical_html=file.path(output,'DALYCARE_clinical.html'),payload=file.path(output,'DALYCARE_atlas_payload.js'),payload_json=file.path(output,'DALYCARE_atlas_payload.json'),catalogue=file.path(output,'DALYCARE_output_catalogue.js'),manifest=manifest,assets=as.list(setNames(file.path(output,files),paste0('site_',seq_along(files)))))
}
