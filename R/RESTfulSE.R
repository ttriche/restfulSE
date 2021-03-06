
# utilities for index processing
# sproc(isplit(vec)) will convert vec representing R integer vector
# into a list of HDF5server 'select' index candidates
#' isplit converts a numeric vector into a list of sequences for compact reexpression
#' @name isplit
#' @rdname sproc
#' @import methods
#' @param x a numeric vector (should be integers)
#' @export
isplit = function(x) {
 if (length(x)==1) return(list(`1`=x))
 dx = diff(x)
 rdx = rle(dx)
 if (all(rdx$lengths==1)) return(split(x,x)[as.character(x)])
 grps = c(1, rep(1:length(rdx$length), rdx$length))
 split(x, grps)
}

#' sproc massages output of isplit into HDF5 select candidates
#' @name sproc
#' @rdname sproc
#' @param spl output of isplit
#' @note Very preliminary implementation.
#' @examples
#' inds = c(1:10, seq(25,50,2), seq(200,150,-2))
#' sproc(isplit(inds))
#' @export
sproc = function(spl) {
# spl is output of isplit
ans = lapply(spl, function(x) {
   if (length(x)==1) return(paste(x-1,":",x,":1", sep=""))
   d = x[2]-x[1]
   return(paste(x[1]-1, ":", x[length(x)], ":", as.integer(d),
     sep=""))
   })
ans
}

#myvec = myvec = c(2:6, 12, 17, seq(30,7,-2))
#sproc(isplit(myvec))

#' hdf5server-based assay for SummarizedExperiment
#' @import SummarizedExperiment
#' @exportClass RESTfulSummarizedExperiment
setClass("RESTfulSummarizedExperiment",
   contains="RangedSummarizedExperiment", 
     representation(source="H5S_dataset",
                    globalDimnames="list"))

#' construct RESTfulSummarizedExperiment
#' @aliases RESTfulSummarizedExperiment,RangedSummarizedExperiment,H5S_dataset-method
#' @param se SummarizedExperiment instance, assay component can be empty SimpleList
#' @param source instance of H5S_dataset
#' @examples
#' bigec2 = H5S_source(serverURL="http://54.174.163.77:5000")
#' banoh5 = bigec2[["assays"]] # banovichSE
#' data(banoSEMeta)
#' rr = RESTfulSummarizedExperiment(banoSEMeta, banoh5)
#' rr
#' rr2 = rr[1:4, 1:5] # just modify metadata
#' rr2
#' assay(rr2) # extract data
#' @exportMethod RESTfulSummarizedExperiment
#' @export RESTfulSummarizedExperiment
setGeneric("RESTfulSummarizedExperiment",
  function(se, source) standardGeneric("RESTfulSummarizedExperiment"))
setMethod("RESTfulSummarizedExperiment", c("RangedSummarizedExperiment",
   "H5S_dataset"), function(se, source) {
 .RESTfulSummarizedExperiment(se, source)
})

.RESTfulSummarizedExperiment = function(se, source) {
   stopifnot(is(se, "RangedSummarizedExperiment")) # for now
   d = internalDim(source)
   if (!all(d == rev(dim(se)))) {
       cat("rev(internal dimensions of H5S_dataset) is", rev(d), "\n")
       cat("dim(se) is", dim(se), "\n")
       stop("these must agree.\n")
       }
   new("RESTfulSummarizedExperiment", se, source=source,
        globalDimnames=dimnames(se))
}

setMethod("assayNames", "RESTfulSummarizedExperiment", function(x, ...) {
 "(served by HDF5Server)"
})

#' @rdname RESTfulSummarizedExperiment-class
#' @importFrom DelayedArray rowRanges
#' @aliases [,RESTfulSummarizedExperiment,numeric,numeric,ANY-method
#' @param x instance of RESTfulSummarizedExperiment
#' @param i numeric selection vector
#' @param j numeric selection vector
#' @param \dots not used
#' @param drop not used
#' @exportMethod [
setMethod("[", c("RESTfulSummarizedExperiment",
     "numeric", "numeric", "ANY"), function(x,i,j,...,drop=FALSE) {
  if (is(x, "RangedSummarizedExperiment")) {
   x = BiocGenerics:::replaceSlots(x, rowRanges = rowRanges(x)[i],
                         colData = colData(x)[j,],
                         check=FALSE)
   }
  else if (is(x, "SummarizedExperiment")) {
   x = BiocGenerics:::replaceSlots(x, rowData = rowData(x)[i],
                         colData = colData(x)[j,],
                         check=FALSE)
   }
   x
   })

#' @name assay
#' @rdname RESTfulSummarizedExperiment
#' @note RESTfulSummarizedExperiment contains a global dimnames
#' list generated at creation.  It is possible that standard operations 
#' on a SummarizedExperiment will engender dimnames components that
#' differ from the initial global dimnames, principally through
#' uniqification (adding suffixes when dimname elements are
#' repeated).  When this is detected, assay() will fail with a complaint
#' about length(setdiff(*names(x), x@globalDimnames[[...]])).
#' @aliases assay,RESTfulSummarizedExperiment,missing-method
#' @param x instance of RESTfulSummarizedExperiment
#' @param i not used
#' @param \dots not used
#' @exportMethod assay
setMethod("assay", c("RESTfulSummarizedExperiment", "missing"), 
    function(x, i, ...) {
    stopifnot(length(rownames(x))>0)
    stopifnot(length(colnames(x))>0)
    stopifnot(length(setdiff(rownames(x), x@globalDimnames[[1]]))==0)
    stopifnot(length(setdiff(colnames(x), x@globalDimnames[[2]]))==0)
    rowsToGet = match(rownames(x), x@globalDimnames[[1]])
    colsToGet = match(colnames(x), x@globalDimnames[[2]])
    ind1 = sproc(isplit(colsToGet))  # may need to be double loop
    ind2 = sproc(isplit(rowsToGet))
#    if (length(ind1)>1 | length(ind2)>1) warning("as of 5/5/17 only processing contiguous block requests, will generalize soon; using first block only")
    if (length(ind1)==1 & length(ind2)==1) 
       ans = t(x@source[ ind1[[1]], ind2[[1]] ])
    else if (length(ind2)==1) {
       ansl = lapply(ind1, function(i1) t(x@source[i1, ind2[[1]] ]))
       ans = do.call(cbind,ansl)
       }
    else if (length(ind1)==1) {
       ansl = lapply(ind2, function(i2) t(x@source[ind1[[1]], i2 ]))
       ans = do.call(rbind,ansl)
       }
    else {
       ansl = lapply(ind1, function(i1) 
                do.call(rbind, lapply(ind2, 
                  function(i2) t(x@source[i1, i2]))))
       ans = do.call(cbind, ansl)
         }
    dimnames(ans) = list(x@globalDimnames[[1]][rowsToGet], 
                x@globalDimnames[[2]][colsToGet])
    ans
})

#' assays access for RESTfulSummarizedExperiment
#' @param x instance of RESTfulSummarizedExperiment
#' @param \dots not used
#' @param withDimnames logical defaults to TRUE
#' @exportMethod assays
setMethod("assays", c("RESTfulSummarizedExperiment"), function(x, ...,
   withDimnames=TRUE) {
#   warning("use assay(), only one allowed at present for RESTful SE")
#   assay(x, ...)  # document properly
   SimpleList("placeholder")
})
 

#' dimension access for RESTfulSummarizedExperiment
#' @param x instance of RESTfulSummarizedExperiment
#' @exportMethod dim
setMethod("dim", "RESTfulSummarizedExperiment", function(x)
   c(length(rownames(x)), length(colnames(x)))
)
