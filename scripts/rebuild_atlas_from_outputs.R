# Offline exact rebuild. No database connection or legacy payload fallback.
args <- commandArgs(trailingOnly=TRUE)
if(length(args)<1L || length(args)>2L) stop('Usage: Rscript scripts/rebuild_atlas_from_outputs.R <run_dir> [project_root]',call.=FALSE)
run_dir <- normalizePath(args[[1]],winslash='/',mustWork=TRUE)
project_root <- if(length(args)>1L) normalizePath(args[[2]],winslash='/',mustWork=TRUE) else normalizePath('.',winslash='/',mustWork=TRUE)
Sys.setenv(DALYCARE_ATLAS_SOURCE_ONLY='TRUE')
source(file.path(project_root,'scripts/run_atlas.R'),encoding='UTF-8')
load_atlas_runtime(project_root)
rebuilt <- atlas_payload_from_run_outputs(run_dir,project_root)
manifest_path <- file.path(run_dir,'outputs/output_manifest.csv')
existing <- if(file.exists(manifest_path)) utils::read.csv(manifest_path,stringsAsFactors=FALSE,check.names=FALSE,fileEncoding='UTF-8') else data.frame()
inputs <- atlas_context_input_paths(run_dir,rebuilt$context,project_root)
if(nrow(existing) && all(c('artifact_id','relative_path') %in% names(existing))) {
  previous <- setNames(lapply(existing$relative_path,function(p)atlas_confined_path(run_dir,p)),existing$artifact_id)
  previous <- previous[!startsWith(existing$relative_path,'site/')]
  inputs <- c(previous,inputs)
}
paths <- write_static_atlas(run_dir,rebuilt$payload,project_root=project_root,output_evidence=rebuilt$tables,manifest_paths=inputs)
cat('Rebuilt from strict CSV inputs:',paths$html,'\n')
