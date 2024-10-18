
## Run this from top-level directory (data/ and timestamp/ should be a sub-folders)

## If a local cache is running (see README), set this envvar suitably, otherwise skip
## Sys.setenv(NHANES_TABLE_BASE = "http://127.0.0.1:8080/cdc")

options(warn = 1) # show warnings immediately

library(nhanesA)
nhanesOptions(use.db = FALSE, log.access = TRUE)

mf <- readRDS("metadata/manifest.rds")$public

## Remove the tables we will not download (usually because they are
## large; some others have already been removed by nhanesManifest())

mf <- subset(mf, !startsWith(Table, "PAXMIN"))
mf <- mf[order(mf$Table), ]

DATAROOT <- "./data"
TSROOT <- "./timestamp"

## For each <DATAROOT>/foo.csv.xz, keep a corresponding
## <TSROOT>/foo.txt which contains the corresponding
## mf$Date.Published[i] field. If this file exists and is identical to
## the current value, we do not attempt to update.

update_needed <- function(mf, i)
{
    ## TRUE if (data file does not exist) OR (timestamp has changed)
    x <- mf$Table[i]
    timestamp <- sprintf("%s/%s.txt", TSROOT, x)
    rawcsv <- sprintf("%s/%s.csv.xz", DATAROOT, x)
    if (!file.exists(rawcsv) || !file.exists(timestamp)) return(TRUE)
    if (identical(mf$Date.Published[i], readLines(timestamp))) return(FALSE)
    else return(TRUE)
}


for (i in seq_len(nrow(mf))) {
    x <- mf$Table[i]
    if (update_needed(mf, i)) {
        timestamp <- sprintf("%s/%s.txt", TSROOT, x)
        rawcsv <- sprintf("%s/%s.csv.xz", DATAROOT, x)
        message(x, " -> ", rawcsv)
        d <- nhanesFromURL(mf$DataURL[i], translated = FALSE)
        if (is.data.frame(d)) {
            xzcon <- xzfile(rawcsv, "w", compression = 8)
            write.csv(d, file = xzcon, row.names = FALSE)
            close(xzcon)
            cat(mf$Date.Published[i], file = timestamp, fill = TRUE)
        }
        else message("failed: ", x)
    }
    else message("skipping: ", x)
}

