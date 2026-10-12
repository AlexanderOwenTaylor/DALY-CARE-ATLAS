root <- normalizePath(getwd(), winslash="/", mustWork=TRUE)
source(file.path(root,"tests/helper.R"))
source(file.path(root,"R/registry_summaries.R"))
if (file.exists(file.path(root,"R/registry_summary_privacy.R"))) source(file.path(root,"R/registry_summary_privacy.R"))
policy <- registry_summary_policy(root)
expect_equal(length(policy),217L,"Policy has a fixed reviewed field inventory.")
expect_false(anyDuplicated(vapply(policy,function(s) paste(s$table_name,s$source_column),character(1)))>0)
measurements <- read.csv("config/public-measurement-policy.csv",stringsAsFactors=FALSE)
measurements <- measurements[measurements$table_name %in% c("RKKP_DaMyDa","RKKP_LYFO","RKKP_CLL"),]
expect_true(all(paste(measurements$table_name,measurements$column_name) %in% vapply(Filter(function(s) s$kind=="numeric",policy),function(s) paste(s$table_name,s$source_column),character(1))))
old_key <- Sys.getenv("DALYCARE_REGISTRY_PERSON_KEYS_FILE",unset=NA_character_)
old_k <- Sys.getenv("DALYCARE_MIN_CELL_COUNT",unset=NA_character_)
cleanup <- function() {
  if (is.na(old_key)) Sys.unsetenv("DALYCARE_REGISTRY_PERSON_KEYS_FILE") else Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=old_key)
  if (is.na(old_k)) Sys.unsetenv("DALYCARE_MIN_CELL_COUNT") else Sys.setenv(DALYCARE_MIN_CELL_COUNT=old_k)
}
Sys.unsetenv("DALYCARE_REGISTRY_PERSON_KEYS_FILE"); Sys.setenv(DALYCARE_MIN_CELL_COUNT="5")
field <- function(rows,col) rows[rows$source_column==col,,drop=FALSE]
status <- function(rows,col) field(rows,col)$summary_status[1]
base <- data.frame(secret_person=sprintf("private-%03d",1:40),Stadie=rep(c("I","II"),each=20),Reg_Haemoglobin=rep(c(1,2,3,4),each=10),stringsAsFactors=FALSE)
missing <- registry_field_summaries(base,"RKKP_DaMyDa",root)
expect_equal(status(missing,"Stadie"),"needs_person_key")
expect_true(all(is.na(field(missing,"Stadie")$denominator_n)))
map <- tempfile(fileext=".csv")
write.csv(data.frame(table_name=c("RKKP_DaMyDa","RKKP_LYFO","RKKP_CLL"),person_key="secret_person",reviewed="TRUE"),map,row.names=FALSE)
Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=map)
rows <- registry_field_summaries(base,"RKKP_DaMyDa",root)
expect_equal(status(rows,"Stadie"),"published")
expect_equal(as.numeric(field(rows,"Stadie")$denominator_n),40)
expect_equal(status(rows,"Reg_Haemoglobin"),"published")
expect_equal(as.numeric(field(rows,"Reg_Haemoglobin")$mean),2.5)
expect_equal(as.numeric(field(rows,"Reg_Haemoglobin")$p25),1.75)
expect_equal(as.numeric(field(rows,"Reg_Haemoglobin")$p75),3.25)
expect_false(any(grepl("private-",as.character(unlist(rows)),fixed=TRUE)))
repeated <- registry_field_summaries(rbind(base,base),"RKKP_DaMyDa",root)
expect_equal(field(repeated,"Reg_Haemoglobin"),field(rows,"Reg_Haemoglobin"),"Repeated identical measurements collapse per person.")
conflict <- rbind(base,transform(base[1:5,],Stadie="III",Reg_Haemoglobin=8))
conflicted <- registry_field_summaries(conflict,"RKKP_DaMyDa",root)
expect_equal(status(conflicted,"Stadie"),"published")
expect_equal(as.numeric(field(conflicted,"Stadie")$n_conflicting),5)
expect_equal(as.numeric(field(conflicted,"Stadie")$denominator_n),40)
rare_conflict <- registry_field_summaries(rbind(base,transform(base[1,],Stadie="III")),"RKKP_DaMyDa",root)
expect_equal(status(rare_conflict,"Stadie"),"withheld_small_group")
unknown <- base; unknown$Stadie[1] <- "unapproved raw text"
unknown_rows <- registry_field_summaries(unknown,"RKKP_DaMyDa",root)
expect_equal(status(unknown_rows,"Stadie"),"withheld_small_group")
expect_false(any(grepl("unapproved",as.character(unlist(unknown_rows)),fixed=TRUE)))
neg <- base; neg$Reg_Haemoglobin[1:5] <- -1; neg$Reg_Haemoglobin[6:10] <- Inf
negative <- registry_field_summaries(neg,"RKKP_DaMyDa",root)
expect_equal(status(negative,"Reg_Haemoglobin"),"published")
expect_equal(as.numeric(field(negative,"Reg_Haemoglobin")$n_invalid),10)
expect_true(field(negative,"Reg_Haemoglobin")$p25 >= 0)
adjacent <- base; adjacent$Reg_Haemoglobin <- c(1.0000000000000002,rep(1,19),rep(2,20))
expect_equal(status(registry_field_summaries(adjacent,"RKKP_DaMyDa",root),"Reg_Haemoglobin"),"withheld_small_group","Typed adjacent double rare tails must not collapse.")
merged <- registry_summary_final_guard(rbind(rows,rows),root,5)
expect_true(all(merged$summary_status=="invalid_contract"),"Duplicate published sources fail closed after concatenation.")
expect_true(all(is.na(merged$denominator_n)) && all(merged$category_counts_json=="[]"))
rare <- base; rare$Reg_Haemoglobin[1] <- 1.23456
rare_rows <- registry_field_summaries(rare,"RKKP_DaMyDa",root)
expect_equal(status(rare_rows,"Reg_Haemoglobin"),"withheld_small_group")
expect_true(all(is.na(field(rare_rows,"Reg_Haemoglobin")[c("denominator_n","n_valid","n_distinct","mean","p25","p75")])) )
const <- base; const$Reg_Haemoglobin <- 1
expect_equal(status(registry_field_summaries(const,"RKKP_DaMyDa",root),"Reg_Haemoglobin"),"withheld_constant")
blank_key <- base; blank_key$secret_person[1] <- ""
expect_equal(status(registry_field_summaries(blank_key,"RKKP_DaMyDa",root),"Stadie"),"missing_person_key")
expect_equal(status(registry_field_summaries(base[-1],"RKKP_DaMyDa",root),"Stadie"),"missing_person_key")
for (tbl in c("RKKP_LYFO","RKKP_CLL")) {
  df <- data.frame(secret_person=base$secret_person,stringsAsFactors=FALSE)
  stagecol <- if (tbl=="RKKP_LYFO") "Reg_Stadium" else "Reg_BinetStadium"
  df[[stagecol]] <- rep(c("1","2"),each=20)
  df$Beh_Responsevaluering <- rep(c("CR","PR"),each=20)
  tx <- if(tbl=="RKKP_LYFO") "Beh_ErDerForetagetKemo" else "Beh_TargeteretBeh_Ibrutinib"
  df[[tx]] <- rep(c("0","1"),each=20)
  rows <- registry_field_summaries(df,tbl,root)
  expect_true(all(vapply(c(stagecol,"Beh_Responsevaluering",tx),function(col) status(rows,col)=="published",logical(1))))
}
Sys.setenv(DALYCARE_MIN_CELL_COUNT="21")
expect_equal(status(registry_field_summaries(base,"RKKP_DaMyDa",root,min_cell_count=1),"Stadie"),"withheld_small_group")
Sys.setenv(DALYCARE_MIN_CELL_COUNT="5")
expect_equal(nrow(registry_field_summaries(base,"fake_RKKP_DaMyDa",root)),0L)
# SQL is executed independently by Python's standard SQLite engine when RSQLite is unavailable.
sql_dir <- file.path(root,".artifact-temp/registry-sql-fixtures")
dir.create(sql_dir,recursive=TRUE,showWarnings=FALSE)
for(col in c("Stadie","Reg_Haemoglobin")) {
  spec <- Filter(function(s) s$table_name=="RKKP_DaMyDa" && s$source_column==col,policy)[[1]]
  writeLines(registry_summary_sql(DBI::ANSI(),'"cohort"',"secret_person",spec,"sqlite",5000L),file.path(sql_dir,paste0(col,".sql")))
}
write.csv(base,file.path(sql_dir,"cohort.csv"),row.names=FALSE)
cleanup()
cat("Registry producer synthetic privacy, person resolution, all-three-registry and policy coverage tests passed.\n")
# Exercise the public DB producer and budget behavior without returning individual records.
library(DBI)
setClass("RegistryTestSQLiteConnection", contains="DBIConnection")
fixture_conn <- new("RegistryTestSQLiteConnection")
fixture_query_count <- 0L
fixture_mode <- "normal"
setMethod("dbQuoteIdentifier",signature(conn="RegistryTestSQLiteConnection",x="character"),function(conn,x,...) DBI::SQL(paste0('"',gsub('"','""',x,fixed=TRUE),'"')))
setMethod("dbQuoteString",signature(conn="RegistryTestSQLiteConnection",x="character"),function(conn,x,...) DBI::SQL(paste0("'",gsub("'","''",x,fixed=TRUE),"'")))
setMethod("dbGetQuery",signature(conn="RegistryTestSQLiteConnection",statement="character"),function(conn,statement,...) {
  fixture_query_count <<- fixture_query_count+1L
  expect_true(grepl("GROUP BY pid",statement,fixed=TRUE),"Person resolution stays inside SQL.")
  expect_true(grepl("SELECT status,value,n FROM grouped LIMIT",statement,fixed=TRUE),"DB returns grouped counts only.")
  if(fixture_mode=="error") stop("Synthetic query failure with no source data")
  if(fixture_mode=="timeout") stop("Synthetic statement timeout")
  if(fixture_mode=="missing_key") return(data.frame(status="key_missing",value="",n=1))
  if(fixture_mode=="cap") return(data.frame(status=rep("valid",5001),value=as.character(1:5001),n=rep(5,5001)))
  data.frame(status=c("valid","valid"),value=c("I","II"),n=c(20,20))
})
# Reset reviewed config because the standalone memory tests restore the environment.
Sys.setenv(DALYCARE_REGISTRY_PERSON_KEYS_FILE=map,DALYCARE_MIN_CELL_COUNT="5")
db <- dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root)
expect_equal(status(db,"Stadie"),"published")
expect_equal(fixture_query_count,1L)
fixture_mode <- "missing_key"
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root),"Stadie"),"missing_person_key")
fixture_mode <- "cap"
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root),"Stadie"),"resource_limit")
fixture_mode <- "timeout"
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root),"Stadie"),"resource_limit")
fixture_mode <- "error"
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root),"Stadie"),"query_failed")
fixture_mode <- "normal"
skipping <- list(should_skip=function(...) TRUE)
before <- fixture_query_count
source(file.path(root,"R/db_profile.R"))
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root,budget_context=skipping),"Stadie"),"resource_limit")
expect_equal(fixture_query_count,before,"Budget-skipped fields must execute no value query.")
# Operator review, exact key names and canonical table identity are mandatory.
write.csv(data.frame(table_name="RKKP_DaMyDa",person_key="secret_person",reviewed="FALSE"),map,row.names=FALSE)
expect_equal(status(dbi_registry_field_summaries(fixture_conn,'"cohort"',"RKKP_DaMyDa",c("secret_person","Stadie"),root),"Stadie"),"needs_person_key")
expect_equal(fixture_query_count,before)
cleanup()
cat("Registry DB producer budget, cardinality cap, missing keys, errors, timeouts and review tests passed.\n")
