# Exercise the actual shared registry renderer. The historical string-position
# checks targeted superseded DaMyDa/LYFO/CLL markup and could not verify behavior.
root <- normalizePath(getwd(), winslash="/")
node <- Sys.which("node")
if (!nzchar(node)) stop("Node.js is required for registry renderer acceptance",call.=FALSE)
log <- tempfile("registry-renderer-",fileext=".log")
status <- system2(node,shQuote(c("--test",file.path(root,"tests/test-registry-discovery.js"))),stdout=log,stderr=log)
if (status != 0L) stop(paste(readLines(log,warn=FALSE,encoding="UTF-8"),collapse="\n"),call.=FALSE)
cat("Registry renderer staging, exact field navigation and disclosure tests passed\n")
