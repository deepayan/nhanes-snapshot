# Copy of NHANES public data and codebook

This repository maintains snapshots of publicly available NHANES data
and documentation. The primary goal is to use these to eventually
populate a database containing the same information in a more
structured manner.

## Requirements

A recent version of R along with the `nhanesA` package, which can be
installed from CRAN or GitHub. To avoid multiple downloads in case the
process is interrupted and needs to be restarted, local caching can be
enabled using some Bioconductor tools. The following code should set
up the system appropriately.

```r
install.packages(c("httpuv", "BiocManager"), repos = "https://cloud.r-project.org")
BiocManager::install("BiocFileCache")
BiocManager::install_github("cjendres1/nhanes")
BiocManager::install_github("ccb-hms/cachehttp")
```

## Run local caching server (optional)

The first step is to start up the caching server. The following code
must be run in a separate R session, which must not terminate before
all downloads are complete.

```r
require(cachehttp)
add_cache("cdc", "https://wwwn.cdc.gov",
          fun = function(x) {
              x <- tolower(x)
              ok <- endsWith(x, ".htm") || endsWith(x, ".xpt")
              cat(x, if (ok) " [ TRUE ]" else " [ FALSE ]", fill = TRUE)
              ok
          })
s <- start_cache(host = "0.0.0.0", port = 8080,
                 static_path = BiocFileCache::bfccache(BiocFileCache::BiocFileCache()))
## httpuv::stopServer(s) # to stop the httpuv server
```

It is best to keep an eye on the session to see if anything unexpected
is happening. In that case, closing the session and restarting usually
works. One thing to look out for is that the temporary directory does
not run out of space.

The advantage of doing it this way is that files will not be
downloaded from the CDC website more than once _unless_ it has been
updated, even if the process is repeated after six months (provided
the cache has not been removed).

## Download manifests from CDC website and record collection date

Run (from the top-level directory)

```sh
R --vanilla < code/update_manifests.R
```

This downloads and saves current manifests of public and limited
access data tables from the CDC NHANES website, along with a manifest
of available variables. Subsequent downloads are based on the
information in these manifests.

The current date is recorded in a file named `COLLECTION_DATE`.


## Download raw data and convert to CSV

The script `code/convert2csv.R` downloads the XPT files and converts
them to CSV files, keeping track of updates. It should be run from the
top-level directory. If the local cache is enabled as described above,
this can be done from the command line using

```sh
export NHANES_TABLE_BASE="http://127.0.0.1:8080/cdc"
R --vanilla < code/convert2csv.R
```

To download directly from the CDC website, skip setting the
environment variable.

## Download documentation files

To download the HTML documentation files (for publicly accessible
datasets), similarly run

```sh
export NHANES_TABLE_BASE="http://127.0.0.1:8080/cdc"
R --vanilla < code/htmldoc.R
```

To download the HTML documentation files for limited access datasets, run

```sh
export NHANES_TABLE_BASE="http://127.0.0.1:8080/cdc"
R --vanilla < code/htmldoc-limited-access.R
```

## Generate codebooks and other metadata

To extract metadata and codebook information from the documentation
files, we follow a two-step process. The first step is to run

```sh
R --vanilla < code/extract-metadata.R
```

to process all available documentation files and extract variable
metadata and codebooks. This step is a little slow (~15 minutes) as it
needs to process all documentation files one by one. The combined
results are stored in `metadata/all_metadata.rds`.

The second step is to run 

```sh
R --vanilla < code/process-metadata.R
```

This uses the manifests and the results of the first step to produce
three data frames:

- `codebookDF` containing codebooks for all variables

- `variablesDF` containing descriptions of variables

- `tablesDF` containing descriptions of tables

These are saved as corresponding RDS files in the `metadata` directory.

