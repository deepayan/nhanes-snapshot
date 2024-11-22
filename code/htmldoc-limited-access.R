
## Run this from top-level directory (data/ and timestamp/ should be a sub-folders)

## If a local cache is running, set this envvar suitably, otherwise skip
## Sys.setenv(NHANES_TABLE_BASE = "http://127.0.0.1:8080/cdc")

options(warn = 1)

library(nhanesA)
nhanesOptions(use.db = FALSE, log.access = TRUE)
mf_pub <- readRDS("metadata/manifest.rds")$public # only for checking

mf <- readRDS("metadata/manifest.rds")$limitedaccess
mf <- mf[order(mf$Table), ]
mf$DestFile <- gsub("/Nchs/Nhanes/", "", mf$DocURL, ignore.case = TRUE)

## Make sure there are no overlaps:

commonTable <- intersect(mf_pub$Table, mf$Table)
commonURL <- intersect(mf_pub$DocURL, mf$DocURL)
if (length(commonTable) || length(commonURL)) {
    stop("Common tables or doc URLs in public and limited access manifests... Aborting.")
}

## Remove the tables we will not download (usually because they are
## large; some others have already been removed by nhanesManifest())

DOCROOT <- "./docs"
TSROOT <- "./timestamp"

## For each <DATAROOT>/foo.html, keep a corresponding
## <TSROOT>/foo.txt which contains the corresponding
## mf$Date.Published[i] field. If this file exists and is identical to
## the current value, we do not attempt to update.

update_needed <- function(mf, i)
{
    ## TRUE if (data file does not exist) OR (timestamp has changed)
    x <- mf$Table[i]
    dest <- mf$DestFile[i]
    timestamp <- sprintf("%s/%s.txt", TSROOT, x)
    docfile <- sprintf("%s/%s", DOCROOT, dest)
    if (!file.exists(docfile) || !file.exists(timestamp)) return(TRUE)
    if (identical(mf$Date.Published[i], readLines(timestamp))) return(FALSE)
    else return(TRUE)
}

DOC_PREFIX <- Sys.getenv("NHANES_TABLE_BASE", unset = "https://wwwn.cdc.gov")

for (i in seq_len(nrow(mf))) {
    x <- mf$Table[i]
    dest <- mf$DestFile[i]
    if (update_needed(mf, i)) {
        timestamp <- sprintf("%s/%s.txt", TSROOT, x)
        docfile <- sprintf("%s/%s", DOCROOT, dest)
        message(x, " -> ", docfile)
        url <- paste0(DOC_PREFIX, mf$DocURL[i])
        download.file(url, destfile = docfile)
        ## add timestamp
        cat(mf$Date.Published[i], file = timestamp, fill = TRUE)
    }
    else message("skipping: ", x)
}

## Update MANIFEST.txt to list all html files currently present

FIXME

htmlfiles <- list.files(DOCROOT, pattern = "html$")
cat(htmlfiles, file = file.path(DOCROOT, "MANIFEST.txt"), sep = "\n")



