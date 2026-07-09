#' SCANFI data
#'
#' Get and prepare SCANFI 2020 data
#' (<https://open.canada.ca/data/en/dataset/18e6a919-53fd-41ce-b4e2-44a9707c52dc>).
#'
#' @param type character, specifying which SCANFI product to download and prepare
#'             (currently, only "all" is supported).
#'
#' @param destDir character, specifying the destination directory in which to download
#'                and extract the data (defaults to current working directory).
#'
#' @param studyArea (optional) `sf` polygon to which the national raster will be cropped and masked.
#'
#' @return `SpatRaster`
#'
#' @export
scanfi <- function(type = "all", destDir = NULL, studyArea = NULL) {
  stopifnot(type == "all")

  if (is.null(destDir)) {
    destDir <- getwd()
  }

  withr::local_options(timeout = 3000)

  scanfi_url <- "https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/SCANFI/v1"

  download_files <- function(url, dest) {
    httr2::request(url) |>
      ## disable ssl due to certificate problems with server
      httr2::req_options(
        ssl_verifypeer = 0L,
        ssl_verifyhost = 0L
      ) |>
      httr2::req_perform(path = dest)
  }

  scanfi_files <- RCurl::getURL(
    scanfi_url,
    dirlistonly = TRUE,
    .opts = list(followlocation = TRUE),
    ssl.verifypeer = FALSE,
    ssl.verifyhost = FALSE
  ) |>
    XML::getHTMLLinks() |>
    ## get all species layers
    grep("^SCANFI_sps_.*[.]tif$", x = _, value = TRUE)

  urls <- c(
    file.path(scanfi_url, scanfi_files),
    file.path(scanfi_url, "_readme.txt")
  )
  dests <- file.path(dataPath, basename(urls)) |>
    sub("_readme.txt", "_README.txt", x = _)

  purrr::walk2(.x = urls, .y = dests, .f = download_files)

  return(invisible(TRUE))
}
