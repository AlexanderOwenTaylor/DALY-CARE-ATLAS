# Synthetic producer contract: changing packing, charges, or selection must fail here.
source('tests/helper.R'); source_test_runtime()
contract <- jsonlite::fromJSON('tests/fixtures/transport-v2-contract.json',simplifyVector=FALSE)
parsed <- function(x) jsonlite::fromJSON(atlas_bundle_json(x),simplifyVector=FALSE)
reject <- function(expr) stopifnot(inherits(try(force(expr),silent=TRUE),'try-error'))
payload <- contract$encoder_payload
wire <- atlas_payload_transport(payload)
stopifnot(identical(wire$transport_version,2L),identical(names(wire),c('transport_version','payload','aliases','row_tables')))
stopifnot(length(wire$row_tables)>0L,is.null(names(wire$row_tables)))
stopifnot(identical(atlas_payload_transport(payload,1L)$transport_version,1L))

# R cannot represent embedded NUL: jsonlite truncates those fixture strings.
# Test the original serialized string charge separately without decoding its value.
for(i in seq_along(contract$normalized_charges)) {
  if(i %in% c(15L,17L)) next
  item <- contract$normalized_charges[[i]]
  stopifnot(atlas_transport_usage(item$value)==item$charge)
}
stopifnot(atlas_transport_json_usage('"\\u0000\\u001f"')==14,
  atlas_transport_json_usage('"quote\\\" backslash\\\\ slash/ \\b\\t\\n\\f\\r\\u0000\\u001f \\u00e6\\u4e2d\\ud83d\\ude00\\u2028\\u2029"')==67)
reject(atlas_transport_json_usage('"\\ud800"'))
reject(atlas_transport_json_usage('"\\udc00"'))

# Configuration comes from a public entry, never from the internal encoder.
old_version <- Sys.getenv('DALYCARE_ATLAS_TRANSPORT_VERSION',unset=NA_character_)
for(case in contract$configuration_cases) {
  if(is.null(case$environment)) Sys.unsetenv('DALYCARE_ATLAS_TRANSPORT_VERSION') else
    Sys.setenv(DALYCARE_ATLAS_TRANSPORT_VERSION=case$environment)
  if(isTRUE(case$error)) reject(atlas_transport_version(case$explicit)) else
    stopifnot(atlas_transport_version(case$explicit)==case$expect)
}
Sys.setenv(DALYCARE_ATLAS_TRANSPORT_VERSION='1')
stopifnot(atlas_payload_transport(list(x=1))$transport_version==2L)
if(is.na(old_version)) Sys.unsetenv('DALYCARE_ATLAS_TRANSPORT_VERSION') else Sys.setenv(DALYCARE_ATLAS_TRANSPORT_VERSION=old_version)

# This test reconstruction deliberately preserves NULL list members and ordered keys.
unpack <- function(envelope) {
  out <- envelope$payload
  put <- function(node,path,value) {
    if(length(path)==1L) node[path] <- list(value) else
      node[path[[1L]]] <- list(put(node[[path[[1L]]]],path[-1L],value))
    node
  }
  for(table in envelope$row_tables) {
    rows <- lapply(table$rows,function(row) {
      keys <- unlist(table$schemas[[row[[1L]]+1L]],use.names=FALSE)
      setNames(row[-1L],keys)
    })
    out <- put(out,unlist(table$path,use.names=FALSE),rows)
  }
  for(alias in envelope$aliases) out <- put(out,unlist(alias$target,use.names=FALSE),out[[alias$source[[1L]]]])
  out
}
stopifnot(identical(parsed(unpack(wire)),parsed(payload)),identical(parsed(payload),parsed(contract$encoder_payload)))
paths <- lapply(wire$row_tables,function(t) t$path)
for(path in contract$must_pack_paths) stopifnot(any(vapply(paths,identical,logical(1),path)))
for(table in wire$row_tables) {
  stopifnot(is.null(names(table$path)),is.null(names(table$schemas)),is.null(names(table$rows)))
  for(schema in table$schemas) stopifnot(is.list(schema),is.null(names(schema)))
  for(row in table$rows) stopifnot(is.list(row),is.null(names(row)))
}

one_key <- list(single=rep(list(list(synthetic_repeated_long_key=NULL)),12L))
single_wire <- atlas_payload_transport(one_key)
stopifnot(length(single_wire$row_tables)==1L,length(single_wire$row_tables[[1L]]$schemas)==1L,
  length(single_wire$row_tables[[1L]]$schemas[[1L]])==1L,
  identical(parsed(unpack(single_wire)),parsed(one_key)))
mixed <- list(rows=rep(list(list(first=NULL,middle=FALSE,last=NULL),list(last='',first=0)),20L))
stopifnot(identical(parsed(unpack(atlas_payload_transport(mixed))),parsed(mixed)))
delimiters <- list(rows=rep(list(setNames(list('a','b'),c('a|b','c')),setNames(list('c','d'),c('a','b|c'))),10L))
stopifnot(length(atlas_payload_transport(delimiters)$row_tables[[1L]]$schemas)==2L)

# Unsupported R shapes retain exactly their previous serializer output, including NA.
fallback <- list(frame=data.frame(a=c(1,NA),b=c('001','002')),named_vector=c(a=1,b=2),
  factor=factor(c('x','y')),date=as.Date('2020-01-01'),matrix=matrix(1:4,2),
  partial=setNames(list(1,NULL),c('a','')),duplicates=setNames(list(1,2),c('x','x')),
  missing=NA_real_,nested=list(list(rows=one_key$single)),unsafe=list(constructor=one_key$single,prototype='data'))
fallback_wire <- atlas_payload_transport(fallback)
stopifnot(length(fallback_wire$row_tables)==0L,identical(parsed(fallback_wire$payload),parsed(fallback)),
  atlas_transport_usage(fallback)==atlas_transport_json_usage(atlas_bundle_json(fallback)))
for(odd_record in list(setNames(list(1,NULL),c('a','')),setNames(list(1,2),c('x','x')))) {
  odd_wire <- atlas_payload_transport(odd_record)
  stopifnot(length(odd_wire$row_tables)==0L,identical(parsed(odd_wire$payload),parsed(odd_record)))
}
classed_root <- I(list(vector=I(1),raw=as.raw(c(1,2))))
stopifnot(identical(parsed(atlas_payload_transport(classed_root)$payload),parsed(classed_root)))
duplicate_review <- list(catalog_rows=one_key$single,
  review_infrastructure_sections=setNames(list(one_key$single,one_key$single),c('catalog','catalog')))
stopifnot(length(atlas_payload_transport(duplicate_review)$aliases)==0L,
  identical(parsed(unpack(atlas_payload_transport(duplicate_review))),parsed(duplicate_review)))
stopifnot(atlas_transport_usage(list(a=list(x=1),b=list(x=1)))==87)
reject(atlas_payload_transport(list(x=Inf)));reject(atlas_payload_transport(list(x=NaN)))
reject(atlas_payload_transport(list(x=new.env(parent=emptyenv()))))
bad_utf8 <- rawToChar(as.raw(c(0xED,0xA0,0x80)));Encoding(bad_utf8) <- 'UTF-8'
reject(atlas_payload_transport(list(x=bad_utf8)))

# Limits apply to the whole next table; rejected candidates consume no counters.
small_limits <- list(tables=2L,path_depth=16L,schemas_per_table=64L,keys_per_schema=64L,
  key_utf8_bytes=128L,rows=12L,cells=12L)
larger <- rep(one_key$single,2L)
packed <- atlas_transport_pack(list(too_large=larger,then_small=one_key$single),small_limits)
stopifnot(length(packed$row_tables)==1L,identical(packed$row_tables[[1L]]$path,list('then_small')),
  identical(packed$payload$too_large,larger))
unsafe <- list(constructor=one_key$single,prototype=one_key$single)
stopifnot(length(atlas_payload_transport(unsafe)$row_tables)==0L)
long_key <- paste(rep('k',129L),collapse='')
stopifnot(length(atlas_payload_transport(list(rows=rep(list(setNames(list('x'),long_key)),12L)))$row_tables)==0L)
wide <- setNames(as.list(rep('x',65L)),paste0('k',seq_len(65L)))
stopifnot(length(atlas_payload_transport(list(rows=rep(list(wide),12L)))$row_tables)==0L)
schemas <- lapply(seq_len(65L),function(i)setNames(list('x'),paste0('schema_long_key_',i)))
stopifnot(length(atlas_payload_transport(list(rows=rep(schemas,2L)))$row_tables)==0L)
deep <- one_key$single
for(i in seq_len(17L)) deep <- list(nested=deep)
stopifnot(length(atlas_payload_transport(deep)$row_tables)==0L)
boundary <- NULL
for(i in seq_len(127L)) boundary <- list(x=boundary)
stopifnot(atlas_payload_transport(boundary)$transport_version==2L)
reject(atlas_payload_transport(list(x=boundary)))

# Whole encoded and expanded budgets cover all data, even requested-v1 verbatim values.
for(version in c(1L,2L)) {
  simple <- list(x=0)
  envelope <- atlas_payload_transport(simple,version)
  required <- max(atlas_transport_usage(envelope),atlas_transport_usage(simple))
  stopifnot(atlas_payload_transport(simple,version,max_bytes=required)$transport_version==version)
  reject(atlas_payload_transport(simple,version,max_bytes=required-1L))
  reject(atlas_payload_transport(simple,version,max_bytes=TRUE))
}
large <- list(rows=rep(list(list(repeated_very_long_field_name_for_expanded_normalized_budget=0)),30L))
expanded <- atlas_transport_usage(large)
stopifnot(atlas_transport_usage(atlas_payload_transport(large))<expanded)
stopifnot(atlas_payload_transport(large,max_bytes=expanded)$transport_version==2L)
reject(atlas_payload_transport(large,max_bytes=expanded-1L))
alias_budget <- list(catalog_rows=one_key$single,review_infrastructure_sections=list(catalog=one_key$single))
stopifnot(atlas_transport_usage(alias_budget)==953,
  atlas_transport_usage(atlas_payload_transport(alias_budget,1L))==657,
  atlas_transport_usage(atlas_payload_transport(alias_budget,2L))==790,
  atlas_payload_transport(alias_budget,1L,max_bytes=800)$transport_version==1L,
  atlas_payload_transport(alias_budget,2L,max_bytes=800)$transport_version==2L)
# Alias eligibility follows the accepted v1 wire contract even when inert R
# attributes prevent row packing. Losing it changes decoded identity and key order.
# Fixed synthetic accepted19 wire, verified independently against eda8bfb during
# local review. The committed test must also run from ZIPs and shallow checkouts.
accepted_alias_json <- '{"transport_version":1,"payload":{"catalog_rows":[{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"},{"repeated_long_synthetic_field_name":"x"}],"review_infrastructure_sections":{"other":"kept"}},"aliases":[{"target":["review_infrastructure_sections","catalog"],"source":["catalog_rows"]}]}'
alias_rows <- rep(list(list(repeated_long_synthetic_field_name='x')),10L)
alias_base <- list(catalog_rows=alias_rows,review_infrastructure_sections=list(catalog=alias_rows,other='kept'))
alias_cases <- list()
for(kind in c('AsIs','comment','explicit_list')) {
  attribute <- function(x) switch(kind,AsIs=I(x),comment=structure(x,comment='synthetic'),explicit_list=structure(x,class='list'))
  value <- alias_base;value$catalog_rows <- attribute(alias_rows);value$review_infrastructure_sections$catalog <- attribute(alias_rows)
  alias_cases[[paste0('array-',kind)]] <- value
  value <- alias_base;value$review_infrastructure_sections <- attribute(value$review_infrastructure_sections)
  alias_cases[[paste0('review-',kind)]] <- value
  alias_cases[[paste0('root-',kind)]] <- attribute(alias_base)
}
for(case_name in names(alias_cases)) {
  value <- alias_cases[[case_name]]
  current_v1 <- atlas_payload_transport(value,1L,max_bytes=1000)
  current_v2 <- atlas_payload_transport(value,2L,max_bytes=1000)
  stopifnot(length(current_v1$aliases)==1L,length(current_v2$aliases)==1L,
    identical(atlas_bundle_json(current_v1),accepted_alias_json),
    atlas_transport_usage(current_v1)==657,
    identical(names(parsed(unpack(current_v2))$review_infrastructure_sections),c('other','catalog')))
  if(startsWith(case_name,'array-') || startsWith(case_name,'root-')) stopifnot(length(current_v2$row_tables)==0L)
}
renamed_review <- alias_base
renamed_review$review_infrastructure_sections <- structure(setNames(list(alias_rows,'kept'),c('catalog','')),comment='synthetic')
stopifnot(length(atlas_payload_transport(renamed_review)$aliases)==0L)
duplicate_review$review_infrastructure_sections <- I(duplicate_review$review_infrastructure_sections)
stopifnot(length(atlas_payload_transport(duplicate_review)$aliases)==0L)
# These literals exercise actual JS wrapper/newline bytes independently of charges.
actual_wire <- list(transport_version=2L,payload=list(x='a'),aliases=list(),row_tables=list())
actual_json <- '{"transport_version":2,"payload":{"x":"a"},"aliases":[],"row_tables":[]}\n'
actual_js <- paste0('window.DALYCARE_ATLAS_PAYLOAD = ',sub('\n$','',actual_json),';\n')
actual_limit <- nchar(actual_js,type='bytes')
assets <- atlas_transport_assets(actual_wire,actual_limit)
stopifnot(identical(assets$json,actual_json),identical(assets$script,actual_js))
reject(atlas_transport_assets(actual_wire,actual_limit-1L))
frame_proto <- list(frame=setNames(data.frame(value='data'), '__proto__'))
for(version in c(1L,2L)) reject(atlas_transport_assets(atlas_payload_transport(frame_proto,version),67108864))
# Cross-read the actual R serializer in the production browser decoder's realm.
parity <- file.path('.artifact-temp','iteration20-team','r-codec-parity')
dir.create(parity,recursive=TRUE,showWarnings=FALSE)
write_utf8 <- function(text,path) {con <- file(path,'wb');on.exit(close(con));writeBin(charToRaw(enc2utf8(text)),con)}
write_utf8(atlas_bundle_json(atlas_payload_transport(payload,1L)),file.path(parity,'r-v1.json'))
write_utf8(atlas_bundle_json(wire),file.path(parity,'r-v2.json'))
for(case_name in names(alias_cases)) {
  value <- alias_cases[[case_name]]
  write_utf8(accepted_alias_json,file.path(parity,paste0('r-alias-',case_name,'-accepted-v1.json')))
  for(version in c(1L,2L)) write_utf8(atlas_bundle_json(atlas_payload_transport(value,version,max_bytes=1000)),
    file.path(parity,paste0('r-alias-',case_name,'-current-v',version,'.json')))
}
public_payload <- payload;public_payload$unsafe_untouched['__proto__'] <- NULL
for(version in c(1L,2L)) {
  public_assets <- atlas_transport_assets(atlas_payload_transport(public_payload,version),67108864)
  write_utf8(public_assets$script,file.path(parity,paste0('r-public-v',version,'.js')))
  write_utf8(public_assets$json,file.path(parity,paste0('r-public-v',version,'.json')))
}
numeric_payload <- list(rows=rep(list(list(synthetic_large_finite_number=.Machine$double.xmax,
  synthetic_tiny_finite_number=.Machine$double.xmin,synthetic_large_integer=9007199254740992)),12L))
write_utf8(atlas_bundle_json(atlas_payload_transport(numeric_payload,1L)),file.path(parity,'r-numeric-v1.json'))
write_utf8(atlas_bundle_json(atlas_payload_transport(numeric_payload,2L)),file.path(parity,'r-numeric-v2.json'))
probe <- file.path(parity,'assert-r-parity.cjs')
writeLines(c("const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict'),path=require('path');",
  "const [dir,decoder]=process.argv.slice(2);const context={window:{}};vm.createContext(context);vm.runInContext(fs.readFileSync(decoder,'utf8'),context);",
  "const read=name=>vm.runInContext('JSON.parse('+JSON.stringify(fs.readFileSync(path.join(dir,name),'utf8'))+')',context);",
  "const decode=wire=>context.window.DALYCARE_TRANSPORT.decode(wire);",
  "for(const base of ['r-','r-numeric-']) {const a=decode(read(base+'v1.json')),b=decode(read(base+'v2.json'));assert.equal(JSON.stringify(b),JSON.stringify(a));}",
  "for(const kind of ['array','review','root']) for(const attr of ['AsIs','comment','explicit_list']) {const base='r-alias-'+kind+'-'+attr+'-',a=decode(read(base+'accepted-v1.json'));for(const v of [1,2]) {const b=decode(read(base+'current-v'+v+'.json'));assert.equal(JSON.stringify(b),JSON.stringify(a));assert.equal(b.catalog_rows,b.review_infrastructure_sections.catalog);assert.equal(Object.keys(b.review_infrastructure_sections).join(','),'other,catalog');}}",
  "for(const v of [1,2]) {vm.runInContext(fs.readFileSync(path.join(dir,'r-public-v'+v+'.js'),'utf8'),context);assert.equal(JSON.stringify(context.window.DALYCARE_ATLAS_PAYLOAD),JSON.stringify(read('r-public-v'+v+'.json')));const p=decode(context.window.DALYCARE_ATLAS_PAYLOAD);assert.equal(p.catalog_rows,p.review_infrastructure_sections.catalog);assert.equal(p.unsafe_untouched.constructor,'own-data');assert.equal(p.unsafe_untouched.prototype,'own-data');}",
  "console.log('Actual R v1/v2 serializer and browser decoder parity passed');"),probe)
stopifnot(system2(Sys.which('node'),shQuote(c(probe,parity,'inst/templates/atlas-transport.js')))==0L)
cat('R transport producer focused contract tests passed\n')
