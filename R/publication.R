# Public files only; private outputs and recovery logs never enter this allowlist.
atlas_loading_budget <- function(stage,directory) {
  common<-c('DALYCARE_clinical.html','atlas-shell.css','DALYCARE_directory.js','DALYCARE_search.js','atlas-reader.js','atlas-shell.js','atlas-topic.js','atlas-topic.css')
  route_bytes<-max(c(0,file.info(list.files(stage,pattern='^atlas-route-.*[.]js$',full.names=TRUE))$size))
  size<-function(names)sum(file.info(file.path(stage,unique(c(names,'favicon.svg'))))$size)+if('atlas-topic.js'%in%names)route_bytes else 0
  routes<-list(list(route='home',bytes=size(c('DALYCARE_atlas.html','atlas-pages.css','DALYCARE_entry.js','atlas-entry.js'))),list(route='clinical topic',bytes=size(common)),list(route='clinical source membership',bytes=size(c(common,'DALYCARE_membership.js'))))
  descriptors<-list()
  for(entry in directory$tables){text<-paste(readLines(file.path(stage,entry$descriptor),encoding='UTF-8',warn=FALSE),collapse='\n');table<-jsonlite::fromJSON(sub('\\);$','',sub('^.*?registerDescriptor\\(','',text)),simplifyVector=FALSE)$table;descriptors[[table$id]]<-list(entry=entry,table=table)
    deps<-c(common,entry$descriptor);shards<-table$shards
    if(table$id=='registry_field_summaries')deps<-c(deps,'registry-v2.js')
    if(table$id=='semantic_dictionary')deps<-c(deps,'DALYCARE_membership.js')
    count<-0L;page_bytes<-0;page_limit<-if(table$id%in%c('column_profiles','registry_field_summaries','semantic_dictionary'))131072 else 262144;for(s in shards){charge<-file.info(file.path(stage,s$src))$size;if(count>=50||(page_bytes>0&&(table$id%in%c('column_profiles','registry_field_summaries','semantic_dictionary')||page_bytes+charge>page_limit)))break;deps<-c(deps,s$src);count<-count+s$rows;page_bytes<-page_bytes+charge}
    routes[[length(routes)+1L]]<-list(route=paste0('table=',table$id),bytes=size(deps))
    if(!identical(table$provenance,'project_reference')&&!table$id%in%c('column_profiles','registry_field_summaries','npu_reference_search')){
      filtered<-c(common,entry$descriptor,if(table$id=='semantic_dictionary')'DALYCARE_membership.js');charged<-0
      for(shard in shards){amount<-file.info(file.path(stage,shard$src))$size;if(charged>0&&(table$id=='semantic_dictionary'||charged+amount>page_limit))break;filtered<-c(filtered,shard$src);charged<-charged+amount}
      routes[[length(routes)+1L]]<-list(route=paste0('source-filtered bounded scan=',table$id),bytes=size(filtered))
    }

    if(table$id%in%c('column_profiles','registry_field_summaries','semantic_dictionary')&&length(shards)){
      scoped<-c(common,entry$descriptor,if(table$id=='registry_field_summaries')'registry-v2.js' else if(table$id=='semantic_dictionary')'DALYCARE_membership.js')
      routes[[length(routes)+1L]]<-list(route=paste(table$id,'exact field detail (largest shard)'),bytes=size(scoped)+max(file.info(file.path(stage,vapply(shards,function(s)s$src,character(1))))$size))
      sources<-unique(unlist(lapply(shards,function(s)vapply(s$fields,function(pair)pair[[1]],character(1)))))
      for(source in sources){deps<-scoped;count<-0L;page_bytes<-0;for(s in shards){n<-sum(vapply(s$fields,function(pair)pair[[1]]==source,logical(1)));if(n&&count<50){charge<-file.info(file.path(stage,s$src))$size;if(page_bytes>0&&(table$id%in%c('column_profiles','registry_field_summaries','semantic_dictionary')||page_bytes+charge>page_limit))break;deps<-c(deps,s$src);count<-count+n;page_bytes<-page_bytes+charge}};routes[[length(routes)+1L]]<-list(route='source field first page',table=table$id,source=source,bytes=size(deps),dependencies=lapply(sort(unique(c(deps,'favicon.svg',basename(list.files(stage,pattern='^atlas-route-.*[.]js$',full.names=TRUE)[which.max(file.info(list.files(stage,pattern='^atlas-route-.*[.]js$',full.names=TRUE))$size)]))),method='radix'),function(n)list(path=n,bytes=file.info(file.path(stage,n))$size)))}
    }
  }
  if(all(c('column_profiles','registry_field_summaries')%in%names(descriptors))){profile<-descriptors$column_profiles;registry<-descriptors$registry_field_summaries;deps<-c(common,profile$entry$descriptor,registry$entry$descriptor);routes[[length(routes)+1L]]<-list(route='unconfigured registry field profile fallback',bytes=size(deps)+max(c(0,file.info(file.path(stage,vapply(profile$table$shards,function(s)s$src,character(1))))$size)))}
  if(all(c('npu_reference_search','npu_display_dictionary')%in%names(descriptors))){search<-descriptors$npu_reference_search;reference<-descriptors$npu_display_dictionary;deps<-c(common,search$entry$descriptor,reference$entry$descriptor);pairs<-size(deps);definitions<-setNames(vapply(reference$table$shards,function(s)s$src,character(1)),vapply(reference$table$shards,function(s)s$id,character(1)));for(s in search$table$shards)for(key in unlist(s$definitions))pairs<-c(pairs,size(c(deps,s$src,definitions[[key]])));routes[[length(routes)+1L]]<-list(route='selected NPU item (largest actual dependency pair)',bytes=max(pairs))}
  exceeded<-Filter(function(r)!is.finite(r$bytes)||r$bytes>524288,routes)
  if(length(exceeded)){item<-exceeded[[1]];dir.create(file.path(dirname(stage),'logs'),showWarnings=FALSE);writeLines(atlas_bundle_json(item),file.path(dirname(stage),'logs','loading-budget-failure.json'));stop(structure(list(message=paste('Cold route dependency byte budget exceeded:',item$route,item$bytes),call=NULL,budget_route=item$route,budget_bytes=item$bytes,budget_limit=524288),class=c('atlas_budget_error','error','condition')))}
  result<-list(schema_version=1L,build_id=directory$build_id,limit=524288L,accounting='Emitted bytes without gzip or cache credit; explicit later search/detail transfers excluded',routes=routes)
  con<-file(file.path(stage,'loading-budget.json'),'wb');writeBin(charToRaw(enc2utf8(paste0(atlas_bundle_json(result),'\n'))),con);close(con);invisible(result)
}
atlas_publication_boundary <- function(expr,phase='website') {
  tryCatch(force(expr),error=function(e){
    if(inherits(e,'atlas_publication_error'))stop(e)
    message<-conditionMessage(e)
    budget_diagnostic<-if(inherits(e,'atlas_budget_error')&&is.character(e$budget_route)&&length(e$budget_route)==1L&&grepl('^[A-Za-z0-9_ =()/-]+$',e$budget_route)&&is.numeric(e$budget_bytes)&&length(e$budget_bytes)==1L&&is.finite(e$budget_bytes))paste0('Cold route ',e$budget_route,': ',e$budget_bytes,' bytes exceeds ',e$budget_limit,'; reduce automatic dependency transfers.')else ''
    if(nzchar(budget_diagnostic))message(budget_diagnostic)
    patterns<-c(`clinical-source-membership`='publication_membership_invalid',checksum='publication_checksum_mismatch',schema='publication_schema_invalid',budget='publication_byte_budget',privacy='publication_privacy_failed',path='publication_path_invalid',ZIP='package_validation_failed',rename='publication_promotion_failed')
    hits<-names(patterns)[vapply(names(patterns),function(p)grepl(p,message,ignore.case=TRUE),logical(1))]
    code<-if(length(hits))unname(patterns[[hits[[1]]]])else if(phase=='packaging')'package_failed' else 'site_writer_failed'
    allowed<-c('atlas_publication_boundary','atlas_write_site_bundle','atlas_public_manifest','atlas_validate_public_site','atlas_package_site','write_static_atlas')
    calls<-vapply(sys.calls(),function(call)if(is.symbol(call[[1]]))as.character(call[[1]])else '',character(1))
    breadcrumbs<-paste(c(budget_diagnostic,intersect(calls,allowed),intersect(class(e),c('simpleError','error','atlas_publication_error'))),collapse=';')
    resource<-if(code=='publication_membership_invalid')'clinical-source-membership.json' else if(phase=='packaging')'public archive' else 'public site'
    stop(structure(list(message=paste(code,resource,'Rebuild from retained aggregate outputs; verify the named public resource.'),call=NULL,code=code,resource=resource,breadcrumbs=substr(breadcrumbs,1,512)),class=c('atlas_publication_error','error','condition')))
  })
}
atlas_public_hash <- function(path) {
  # Test actual readability: Windows sandbox ACL probes can report denial while
  # the authorized file handle is readable. Public assets have a hard byte cap.
  size<-file.info(path)$size
  if(length(size)!=1L||is.na(size)||size>67108864)stop('Public hash input missing or oversized',call.=FALSE)
  digest::digest(readBin(path,'raw',n=size),algo='sha256',serialize=FALSE)
}
atlas_package_preflight <- function() {
  if(!requireNamespace('zip',quietly=TRUE))stop(structure(list(message='Portable ZIP dependency unavailable',call=NULL,code='missing_dependency',resource='zip'),class=c('atlas_publication_error','error','condition')))
  invisible(TRUE)
}
atlas_publication_outcomes <- function(summary) {
  outcomes<-list(collection='unknown',interpretation='unknown',website='complete')
  for(phase in c('collection','interpretation')){values<-lapply(Filter(function(row)identical(row$metric,paste0(phase,'_status')),summary),function(row)row$value);if(length(values)==1L&&values[[1]]%in%c('complete','partial','failed','not_started','running'))outcomes[[phase]]<-values[[1]]}
  outcomes
}
atlas_public_manifest <- function(stage,build_id,run_id,policy,project_root,summary=list()) {
  files<-sort(list.files(stage,recursive=TRUE,full.names=FALSE))
  records<-lapply(files,function(relative){path<-atlas_confined_path(stage,relative);list(path=relative,bytes=unname(file.info(path)$size),sha256=atlas_public_hash(path))})
  terminology_path<-file.path(project_root,'config/terminology/manifest.json')
  terminology<-if(file.exists(terminology_path))jsonlite::fromJSON(terminology_path,simplifyVector=FALSE) else list(state='not_included',reason='Pinned terminology manifest is not available in this runtime')
  outcomes<-atlas_publication_outcomes(summary)
  manifest<-list(schema_version=1L,build_id=build_id,run_id=run_id,state=if(all(unlist(outcomes)=='complete'))'complete' else 'partial',outcomes=outcomes,privacy_policy_version=policy,terminology=terminology,files=records)
  con<-file(file.path(stage,'public-manifest.json'),'wb');writeBin(charToRaw(enc2utf8(paste0(atlas_bundle_json(manifest),'\n'))),con);close(con)
  atlas_validate_public_site(stage);manifest
}
atlas_validate_public_site <- function(site) {
  manifest<-jsonlite::fromJSON(file.path(site,'public-manifest.json'),simplifyVector=FALSE)
  names<-vapply(manifest$files,function(x)x$path,character(1))
  if(anyDuplicated(names)||any(!grepl('^[A-Za-z0-9_./-]+$',names))||any(grepl('^/|(^|/)[.][.](/|$)',names))||'public-manifest.json'%in%names)stop('Unsafe public asset name',call.=FALSE)
  for(item in manifest$files){path<-atlas_confined_path(site,item$path);link<-Sys.readlink(path);if(!is.na(link)&&nzchar(link))stop('Unsafe public linked asset',call.=FALSE)
    if(!file.exists(path)||file.info(path)$size!=item$bytes||atlas_public_hash(path)!=item$sha256)stop('Public asset checksum mismatch; rebuild from retained outputs',call.=FALSE)}
  if(!setequal(list.files(site,recursive=TRUE),c(names,'public-manifest.json')))stop('Unexpected public assets; rebuild from retained outputs',call.=FALSE)
  manifest
}
atlas_package_site <- function(site,destination=paste0(site,'.zip')) {
  atlas_package_preflight();manifest<-atlas_validate_public_site(site)
  destination<-file.path(normalizePath(dirname(destination),winslash='/',mustWork=TRUE),basename(destination))
  link<-Sys.readlink(destination);if(!is.na(link)&&nzchar(link))stop('Unsafe ZIP destination',call.=FALSE)
  stage<-tempfile('.atlas-zip-',tmpdir=dirname(destination),fileext='.zip');backup<-paste0(destination,'-previous-',manifest$build_id)
  check<-tempfile('.atlas-zip-check-',tmpdir=dirname(destination));dir.create(check)
  on.exit({if(file.exists(stage))unlink(stage);if(dir.exists(check))unlink(check,recursive=TRUE)},add=TRUE)
  names<-c(vapply(manifest$files,function(x)x$path,character(1)),'public-manifest.json')
  zip::zipr(stage,files=names,root=site,include_directories=FALSE,mode='mirror')
  entries<-zip::zip_list(stage)$filename
  if(anyDuplicated(entries)||!setequal(entries,names))stop('ZIP allowlist mismatch',call.=FALSE)
  zip::unzip(stage,exdir=check)
  for(name in names)if(atlas_public_hash(file.path(check,name))!=atlas_public_hash(file.path(site,name)))stop('ZIP checksum mismatch',call.=FALSE)
  moved<-FALSE
  if(file.exists(destination)){if(!file.rename(destination,backup))stop('Cannot preserve previous ZIP',call.=FALSE);moved<-TRUE}
  if(!file.rename(stage,destination)){if(moved)file.rename(backup,destination);stop('ZIP publication failed; previous ZIP retained',call.=FALSE)}
  if(moved)unlink(backup)
  destination
}
atlas_public_csv <- function(path,columns,rows) {
  quote_cell<-function(value){if(is.null(value)||!length(value)||is.na(value))return('""');if(is.logical(value))return(if(value)'true' else 'false');if(is.numeric(value))return(atlas_bundle_json(value));paste0('"',gsub('"','""',value,fixed=TRUE),'"')}
  lines<-c(paste(vapply(columns,quote_cell,character(1)),collapse=','),vapply(rows,function(row)paste(vapply(columns,function(k)quote_cell(row[[k]]),character(1)),collapse=','),character(1)))
  con<-file(path,'wb');on.exit(close(con));writeBin(charToRaw(enc2utf8(paste0(paste(lines,collapse='\n'),'\n'))),con)
}
atlas_reference_search <- function(write,build_id,canonical,tables) {
  source<-Filter(function(t)t$id=='npu_display_dictionary',tables);if(!length(source))return(NULL)
  source<-source[[1]];data<-canonical$npu_display_dictionary;offset<-0L;rows<-list()
  for(shard in source$shards){for(row in data[offset+seq_len(shard$rows)]){
    text<-paste(unlist(row,use.names=FALSE),collapse=' ');words<-unique(unlist(strsplit(tolower(text),'[^[:alnum:]_]+',perl=TRUE)));words<-words[nzchar(words)]
    rows[[length(rows)+1L]]<-list(code=row$code %||% '',label=row$label %||% '',terms=paste(words,collapse=' '),shard=shard$id)
  };offset<-offset+shard$rows}
  if(length(rows))rows<-rows[order(vapply(rows,function(r)r$code,character(1)))]
  table<-list(id='npu_reference_search',title='NPU reference search',status=if(length(rows))'available' else 'empty_output',represented_row_count=length(rows),complete=TRUE,columns=lapply(c('code','label','terms','shard'),function(k)list(key=k,label=k,type='string')),shards=list())
  parts<-list();pending<-list();bytes<-0
  for(row in rows){encoded<-atlas_bundle_json(row);charge<-nchar(enc2utf8(atlas_bundle_json(encoded)),type='bytes')+1
    if(length(pending)&&(length(pending)>=100||bytes+charge>262144-512)){parts[[length(parts)+1L]]<-pending;pending<-list();bytes<-0}
    if(charge>262144-512)stop('Reference search row exceeds byte budget',call.=FALSE)
    pending[[length(pending)+1L]]<-encoded;bytes<-bytes+charge}
  if(length(pending))parts[[length(parts)+1L]]<-pending
  offset<-0L
  for(i in seq_along(parts)){part<-parts[[i]];id<-sprintf('s%04d',i);raw<-paste0('[',paste(unlist(part),collapse=','),']');script<-paste0('window.DALYCARE_OUTPUTS.register(',atlas_bundle_json(list(schema_version=1L,build_id=build_id,table_id=table$id,shard_id=id,rows_json=raw)),');\n');relative<-paste0('output-shards/',table$id,'-',id,'.js')
    if(nchar(enc2utf8(script),type='bytes')>262144)stop('Reference search shard budget',call.=FALSE)
    write(relative,script);table$shards[[i]]<-list(id=id,src=relative,rows=length(part),bytes=nchar(enc2utf8(raw),type='bytes'),first=rows[[offset+1L]]$code,last=rows[[offset+length(part)]]$code,definitions=as.list(unique(vapply(rows[offset+seq_along(part)],function(r)r$shard,character(1)))));offset<-offset+length(part)}
  relative<-paste0('table-descriptors/',table$id,'.js');write(relative,paste0('window.DALYCARE_OUTPUTS.registerDescriptor(',atlas_bundle_json(list(schema_version=1L,build_id=build_id,table=table)),');\n'))
  list(table=table,rows=rows,directory=c(table[c('id','title','status','represented_row_count','complete')],list(descriptor=relative)))
}
