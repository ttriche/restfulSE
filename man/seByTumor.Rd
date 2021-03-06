% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seByTumor.R
\name{seByTumor}
\alias{seByTumor}
\title{given a BigQueryConnection to the 2017 GDC-oriented ISB TCGA bigtables, obtain a SummarizedExperiment 'shell' rowData and colData}
\usage{
seByTumor(tumorCode = "LUAD", assayTblName = "RNAseq_Gene_Expression",
  rdColsToKeep = c("gene_name", "Ensembl_gene_id", "gene_type"),
  bqConnClinical, bqConnAssay, rowkey = "Ensembl_gene_id",
  colkey = "case_barcode", assayvbl = "HTSeq__Counts")
}
\arguments{
\item{tumorCode}{one of the concise TCGA codes in a character string -- not checked, defaults to "LUAD", lung adenocarcinoma}

\item{assayTblName}{the name of the assay whose annotation will be used as rowData}

\item{rdColsToKeep}{columns of assay table to use in rowData component}

\item{bqConnClinical}{instance of BigQueryConnection from bigrquery, for access to clinical metadata -- current expectation is that the BigQuery dataset is named "TCGA_bioclin_v0" and has a table called "Clinical"}

\item{bqConnAssay}{instance of BigQueryConnection from bigrquery -- current expectation is that the BigQuery dataset is named "TCGA_hg19_data_v0"}
}
\description{
given a BigQueryConnection to the 2017 GDC-oriented ISB TCGA bigtables, obtain a SummarizedExperiment 'shell' rowData and colData
}
\examples{
require(bigrquery)
# be sure that .cgcBilling is set in .GlobalEnv
if (exists(".cgcBilling")) {
 clinQ = cgcConn()
 assayQ = cgcConn( dataset = "TCGA_hg38_data_v0" )
 myexpShell = seByTumor( bqConnClinical=clinQ,
       bqConnAssay=assayQ)
 print(nrow(myexpShell) == 60483)
 print(ncol(myexpShell) == 522)
 assay(myexpShell[11:15,1:4]) # some case_barcodes repeat
 }
}
