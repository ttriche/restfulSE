# some utilities to simplify exploration of ISB Cancer Genomic Cloud BigQuery
# August 2017

#' vector of dataset names in isb-cgc project
#' @export
isbCgcDatasets = function() {
 c("ccle_201602_alpha",
 "GDC_metadata",
 "genome_reference",
 "hg19_data_previews",
 "hg38_data_previews",
 "metadata",
 "platform_reference",
 "QotM",
 "TARGET_bioclin_v0",
 "TARGET_hg38_data_v0",
 "tcga_201607_beta",
 "TCGA_bioclin_v0",
 "tcga_cohorts",
 "TCGA_hg19_data_v0",
 "TCGA_hg38_data_v0",
 "tcga_seq_metadata",
 "Toil_recompute")
}

#' list the tables in a selected dataset
#' @param dataset character string identifying a table in ISB CGC
#' @param billing Google BigQuery billing code
isbCgcTables = function(dataset="TCGA_hg19_data_v0", billing=.cgcBilling) {
  stopifnot(dataset %in% isbCgcDatasets())
  con <- DBI::dbConnect(dbi_driver(), project = "isb-cgc", 
        dataset = dataset, billing = billing)
  on.exit(dbDisconnect(con))
  dbListTables(con)
}  

setClass("TableSet", representation(dataset="character", 
    tablenames="character", tables="list"))
setMethod("show", "TableSet", function(object) {
 cat("TableSet for dataset ", object@dataset, "\n")
 cat(" with", length(object@tables), "tables.\n")

}) 

TCGA_tablerefs = function(build="hg19", billing=.cgcBilling) {
 getConn = function(dataset) DBI::dbConnect(dbi_driver(), project = "isb-cgc", 
        dataset = dataset, billing = .cgcBilling)
 if (build == "hg19") {
   ds = "TCGA_hg19_data_v0"
   }
 else if (build == "hg38") {
   ds = "TCGA_hg38_data_v0"
   }
 tblnames = isbCgcTables(dataset=ds, billing=billing)
 new("TableSet", dataset=ds, tablenames=tblnames, tables=
      lapply(tblnames, function(x) getConn(ds) %>% tbl(x)))
}

  
