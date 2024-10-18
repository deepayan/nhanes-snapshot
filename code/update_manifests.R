
library(nhanesA)

## Delete spurious 'All Years' row --- see
## https://wwwn.cdc.gov/Nchs/Nhanes/DNAm/Default.aspx

mf <- list(public = nhanesManifest("public"),
           limitedaccess = subset(nhanesManifest("limitedaccess"), Table != "All Years"),
           variables = nhanesManifest("variables"))

saveRDS(mf, file = "metadata/manifest.rds")

cat(format(Sys.Date()), file = "COLLECTION_DATE", fill = TRUE)


