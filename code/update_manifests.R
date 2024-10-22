
library(nhanesA)

nhanesOptions(log.access = TRUE)

## Delete spurious 'All Years' row --- see
## https://wwwn.cdc.gov/Nchs/Nhanes/DNAm/Default.aspx

mf <- list(public = nhanesManifest("public"),
           demographics = nhanesManifest("public", component = "demographics"),
           dietary = nhanesManifest("public", component = "dietary"),
           examination = nhanesManifest("public", component = "examination"),
           laboratory = nhanesManifest("public", component = "laboratory"),
           questionnaire = nhanesManifest("public", component = "questionnaire"),
           limitedaccess = subset(nhanesManifest("limitedaccess"), Table != "All Years"),
           variables = nhanesManifest("variables"))

saveRDS(mf, file = "metadata/manifest.rds")

cat(format(Sys.Date()), file = "COLLECTION_DATE", fill = TRUE)


