
## Run this script to serve the files in current directory via HTTP,
## using the httpuv package. This allows a local checkout of
## <https://github.com/deepayan/nhanes-snapshot> to be used as the
## data source when building the docker container at
## <https://github.com/deepayan/nhanes-postgres>, potentially speeding
## up the build process.

## Must be run from the top-level folder (nhanes-snapshot) in an
## _interactive_ R session.

stopifnot(require(httpuv))

path <- 
    staticPath(".",
               indexhtml = FALSE,
               fallthrough = FALSE,
               html_charset = "")


s <-
    startServer(host = "127.0.0.1",
                port = 9849,
                app = list(staticPaths = list(snapshot = path)))

## To stop, run
## 
## stopServer(s)

