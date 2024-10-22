
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

mf <- readRDS("metadata/manifest.rds")

public_tables <-
    cbind(with(mf, rbind0(cbind(demographics,  Component = "Demographics"),
                          cbind(dietary,       Component = "Dietary"),
                          cbind(examination,   Component = "Examination"),
                          cbind(laboratory,    Component = "Laboratory"),
                          cbind(questionnaire, Component = "Questionnaire"))),
          UseConstraints = "None")

limitedaccess_tables <-
    cbind(mf$limitedaccess,
          DataURL = "",
          Component = "LimitedAccess",
          UseConstraints = "RDC Only")

## Somewhat confusingly, even though the limited access tables are
## given by
## <https://wwwn.cdc.gov/nchs/nhanes/search/variablelist.aspx?Component=LimitedAccess>,
## they also have a 'component' or data group in the regular sense
## (demographics, laboratory, etc.), which is recorded in the manifest
## of variables (source: nhanesA:::varURLs). However, the variables
## manifest also has a lot of spurious records (e.g., from tables that
## predate 1999), so we will only use it to find the data group for
## limited access tables.

rdc_vars <- unique(mf$variables[c("Table", "TableDesc",
                                  "BeginYear", "EndYear",
                                  "Component", "UseConstraints")])

## make sure no Table is repeated, which might happen if some
## variables are public and some RDC Only within the same table.

if (anyDuplicated(rdc_vars$Table)) stop("Unexpected error: duplicate table names")

## restrict to non-public tables 

rdc_vars <- subset(rdc_vars, UseConstraints != "None", select = -UseConstraints)

## check if all limited access tables are available

## These are the ones we care about. 

(tables_without_info <- 
    setdiff(toupper(limitedaccess_tables$Table),
            toupper(rdc_vars$Table)))

subset(limitedaccess_tables, Table %in% tables_without_info)

## Their doc files do not list variables. We will classify them as
## Component/DataGroup = Documentation


## these are in the variable list, but not in the main list of
## tables. We will ignore these.

setdiff(toupper(rdc_vars$Table),
        toupper(limitedaccess_tables$Table))

## Set the Component column of limitedaccess_tables to corresponding column in rdc_vars

rownames(rdc_vars) <- toupper(rdc_vars$Table)
rdc_vars <- rdc_vars[limitedaccess_tables$Table, ] # sync rows

limitedaccess_tables$Component <- rdc_vars$Component
limitedaccess_tables <-
    within(limitedaccess_tables,
           Component[is.na(Component)] <- "Documentation")

## Sanity check: make sure BeginYear - EndYear are consistent

ok <- with(rdc_vars, paste0(BeginYear, "-", EndYear)) == limitedaccess_tables$Years
if (!identical(limitedaccess_tables$Table[!ok], tables_without_info))
    stop("Mismatch in Years for limited access tables")

## OK, now we can merge and proceed

tablesDF <-
    with(rbind0(public_tables, limitedaccess_tables),
         data.frame(TableName = toupper(Table),
                    Description = Description,
                    BeginYear = as.integer(substring(Years, 1, 4)),
                    EndYear = as.integer(substring(Years, 6, 9)),
                    DataGroup = Component,
                    UseConstraints = UseConstraints,
                    DocFile = paste0("https://wwwn.cdc.gov", DocURL),
                    DataFile = ifelse(nzchar(DataURL), paste0("https://wwwn.cdc.gov", DataURL), ""),
                    DatePublished = Date.Published))

tablesDF <- tablesDF[order(tablesDF$TableName), ]

if (anyDuplicated(tablesDF$TableName)) stop("Unexpected error: duplicate table names")
## Also check if there are any doc files that have been downloaded
## (from the data manifests) but have somehow been excluded

saveRDS(tablesDF, file = "metadata/tablesDF.rds")

## for comparison with earlier version
write.csv(tablesDF, file = "/tmp/tablesDF.csv", row.names = FALSE)

docs <- list.files("docs/") |> gsub(".html", "", x =_)
setdiff(docs, tablesDF$TableName)


