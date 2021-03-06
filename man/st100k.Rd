% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{st100k}
\alias{st100k}
\title{st100k: metadata RangedSummarizedExperiment shell for 100k cells from 10x genomics 1.3 million neuron dataset}
\format{RangedSummarizedExperiment instance}
\source{
\url{https://community.10xgenomics.com/t5/10x-Blog/Our-1-3-million-single-cell-dataset-is-ready-to-download/ba-p/276}
}
\usage{
st100k
}
\description{
st100k: metadata RangedSummarizedExperiment shell for 100k cells from 10x genomics 1.3 million neuron dataset
}
\note{
used github.com/mtmorgan/TENxGenomics package to obtain 
SummarizedExperiment, then added range information, sorted within
chromosome, and saved shell for use with HDF5 server
}
\keyword{datasets}
