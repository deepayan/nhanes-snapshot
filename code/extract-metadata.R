## Extracts metadata (including codebook tables) from all
## documentation files in doc/ and saves as an RDS files for further
## processing. Expect errors and warnings to be issued; these can be
## useful to record unusual or unexpected doc files. To save these in
## an .Rout file, run the script in batch mode using

## R CMD BATCH --vanilla code/extract-metadata.R

library(nhanesA)

removeElement <- function(object, name)
{
    ## Like getElement, but remove 'name' and return rest. object must
    ## be list-like
    object[[name]] <- NULL
    object
}

getElementWith <- function(object, name, Variable, ...)
{
    e <- object[[name]]
    if (is.null(e)) NULL
    else cbind(Variable = Variable, ..., e, deparse.level = 0)
}

doc2codebook <- function(file, metadata = TRUE, codebook = TRUE)
{
    cb <- nhanesCodebookFromURL(file)
    Table <- gsub(".html", "", basename(file),
                  fixed = TRUE)
    ## May not be a list (e.g., SEQN), so convert first
    cb <- lapply(cb, as.list)
    ans <- list()
    varnames <- names(cb)
    ## extract codebooks (the element with corresponding varname)
    if (isTRUE(codebook))
    {
        codebookList <- 
            mapply(getElementWith, cb, varnames, Variable = varnames,
                   MoreArgs = list(Table = Table),
                   SIMPLIFY = FALSE)
        ans$codebook <-
            do.call(rbind, c(unname(codebookList), list(deparse.level = 0)))
    }
    if (isTRUE(metadata))
    {
        ans$metadata <- mapply(removeElement, cb, varnames,
                               SIMPLIFY = FALSE)
    }
    ans
}

tables <- list.files("docs", full.names = TRUE)

options(warn = 1)

system.time(
    all_metadata <- 
        lapply(tables,
               function(d) {
                   cat("*** ", d, fill = TRUE)
                   try(doc2codebook(d))
               })
)

names(all_metadata) <- gsub(".html", "", basename(tables), fixed = TRUE)
saveRDS(all_metadata, file = "metadata/all_metadata.rds")

