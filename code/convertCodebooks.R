

## Run this from top-level directory (Data/ should be a sub-folder)

## Ensure local cache is running. Otherwise skip setting env variable
Sys.setenv(NHANES_TABLE_BASE = "http://127.0.0.1:8080/cdc")

library(nhanesA)
nhanesOptions(use.db = FALSE, log.access = TRUE)
mf <- nhanesManifest()

## Remove the tables we will not download (usually because they are
## large; some others have already been removed by nhanesManifest())

mf <- subset(mf, !startsWith(Table, "PAXMIN"))
mf <- mf[order(mf$Table), ]

FILEROOT <- "./Codebooks"

## Codebooks have two parts for every (table, column) combination: (1)
## Description, SasLabel, Target, etc., and (2) table of possible
## values.  These should go in different CSV files. And these are not
## very large, so we will just collect them all together and then process.

TEMPCB <- "codebooks.rds"


if (file.exists(TEMPCB)) {
    cb <- readRDS(TEMPCB)
} else {
    cb <- list()
    for (i in seq_len(nrow(mf))) {
        x <- mf$Table[i]
        cat("Processing code for ", x, fill = TRUE)
        cb[[x]] <- nhanesCodebookFromURL(mf$DocURL[i])
    }
    saveRDS(cb, file = TEMPCB)
}
