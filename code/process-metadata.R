
## version of rbind() that does not add row names

rbind0 <- function(...) {
    do.call(rbind, c(unname(list(...)), list(deparse.level = 0)))
}

all_metadata <- readRDS("metadata/all_metadata.rds")

all_var_metadata <- lapply(all_metadata, "[[", "metadata")
all_codebooks <- lapply(all_metadata, "[[", "codebook")

## Make a frequency table of what metadata column appears how many
## times

all_metadata_columns <- 
    lapply(all_var_metadata, 
           function(x) {
               lapply(x, names)
           })

unlist(all_metadata_columns) |> table() |> sort() |> as.data.frame()


## Generate two files: (1) All codebooks together, (2) All variable metadata together


## Codebooks: This is simple, just extract all codebooks and rbind()
## them. 


codebookDF <- do.call(rbind0, all_codebooks)
stopifnot(identical(names(codebookDF),
                    c("Variable", "Table", "Code or Value", "Value Description", 
                      "Count", "Cumulative", "Skip to Item")))
names(codebookDF) <- 
    c("Variable", "TableName", "CodeOrValue", "ValueDescription", 
      "Count", "Cumulative", "SkipToItem")

str(codebookDF)

saveRDS(codebookDF, file = "metadata/codebookDF.rds")

## Variable metadata.
##
## Should include (for each variable)
##            Hard Edits:  2539
##  English Instructions: 13738
##          English Text: 58216
##             SAS Label: 58216
##         Variable Name: 59570
##                Target: 63565
##
## Not all are present for all variables. 

## TODO: Add IsPhenotype columns (see nhanes-metadata repo)

## UseConstraints is dropped as it doesn't have any content (and
## should be table-specific anyway)

## Remove carriage return, new line, comma, backslash and quote characters
clean <- function(text)
{
    if (is.character(text)) gsub("[\r\n,\\\"\']", "", text)
}


metadata2df <- function(table_name, metadata = all_var_metadata)
{
    xdata <- metadata[[table_name]]
    f <- function(m) {
        data.frame(Variable = m[["Variable Name:"]] %||% NA_character_,
                   TableName = table_name,
                   SasLabel = m[["SAS Label:"]] %||% NA_character_,
                   Description = m[["English Text:"]] %||% NA_character_,
                   EnglishInstructions = m[["English Instructions:"]] %||% NA_character_,
                   HardEdits = m[["Hard Edits:"]] %||% NA_character_,
                   Target = m[["Target:"]] %||% NA_character_,
                   IsPhenotype = TRUE)
    }
    do.call(rbind0, lapply(xdata, f))
}

## this will be a little slow, but should be less than a minute

variablesDF <-
    do.call(rbind0, lapply(names(all_var_metadata),
                           metadata2df,
                           metadata = all_var_metadata))

for (i in seq_along(variablesDF))
    variablesDF[[i]] <- clean(variablesDF[[i]])


saveRDS(variablesDF, file = "metadata/variablesDF.rds")

## Table metadata.
##
## Should include (for each table)

## TableName
## Description
## BeginYear
## EndYear
## DataGroup
## UseConstraints
## DocFile
## DataFile
## DatePublished

## Somewhat confusingly, most of this information is available not in
## the manifest of tables, but in the manifest of variables, which is
## what we use below. The last three fields are collected from the
## tables manifest.


mf <- readRDS("metadata/manifest.rds")

tablesDF <- with(mf$variables,
                 data.frame(TableName = toupper(Table),
                            Description = TableDesc,
                            BeginYear = BeginYear,
                            EndYear = EndYear,
                            DataGroup = Component,
                            UseConstraints = UseConstraints)) |> unique()

tablesDF <- tablesDF[order(tablesDF$TableName), ]

if (anyDuplicated(tablesDF$TableName)) stop("Unexpected error: duplicate table names")

## Collect (DocFile, DataFile, DatePublished) from manifests of public
## and limited access tables

info_public <-
    with(mf$public,
         data.frame(DocFile = paste0("https://wwwn.cdc.gov", DocURL),
                    DataFile = paste0("https://wwwn.cdc.gov", DataURL),
                    DatePublished = Date.Published,
                    row.names = toupper(Table)))

info_limited <-
    with(mf$limitedaccess,
         data.frame(DocFile = paste0("https://wwwn.cdc.gov", DocURL),
                    DataFile = "",
                    DatePublished = Date.Published,
                    row.names = toupper(Table)))

if (length(intersect(rownames(info_public), rownames(info_limited))))
    stop("Unexpected error: some table names appear in both public and limited access manifests")

info <- rbind(info_public, info_limited, deparse.level = 0)

## Set of tables will not be identical: list differences
## TODO: investigate these more thoroughly

setdiff(tablesDF$TableName, rownames(info))
setdiff(rownames(info), tablesDF$TableName)

## Append info to tablesDF

tablesDF <- cbind(tablesDF, info[ tablesDF$TableName, ])

saveRDS(tablesDF, file = "metadata/tablesDF.rds")


