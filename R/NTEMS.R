.ntemsURLs <- list(
  CA_forest_age = "https://opendata.nfis.org/downloads/forest_change/CA_forest_age_2019.zip",
  CA_Forest_Fire = "https://opendata.nfis.org/downloads/forest_change/CA_Forest_Fire_1985-2020.zip",
  CA_Forest_Harvest = "https://opendata.nfis.org/downloads/forest_change/CA_Forest_Harvest_1985-2020.zip",
  CA_forest_lead_tree_species = "https://opendata.nfis.org/downloads/forest_change/CA_forest_lead_tree_species.zip",
  CA_Forest_Wildfire = "https://opendata.nfis.org/downloads/forest_change/CA_Forest_Wildfire_dNBR_1985_2020.zip"
)

#' @importFrom reproducible Cache prepInputs
.ntemsData <- function(destDir, studyArea = NULL, type = NULL) {
  if (is.null(type)) {
    stop("please specify NTEMS data type: see .ntemsURLs")
  } else {
    url <- .ntemsURLs[[type]]
  }

  opt <- options(reproducible.useTerra = TRUE)
  on.exit(options(opt), add = TRUE)

  x <- Cache({
    prepInputs(url = url, studyArea = studyArea, destinationPath = destDir)
  })

  return(x)
}

#' NTEMS data
#'
#' Get and prepare data from NTEMS (<https://opendata.nfis.org/mapserver/nfis-change_eng.html>):
#'
#' - `ntemsAge()`: forest age (\doi{10.1016/j.rse.2023.113529});
#' - `ntemsFires()`: forest fires (\doi{10.1080/17538947.2016.1187673});
#' - `ntemsHarvest()`: forest harvest disturbances (\doi{10.1080/17538947.2016.1187673});
#' - `ntemsLeadSpp()`: leading tree species (\doi{https://doi.org/10.1016/j.rse.2022.113276});
#' - `ntemsWildfire()`: wildfire differenced Normalized Burn Ratio
#'                      (\doi{10.1016/j.rse.2014.11.005}; \doi{10.1016/j.rse.2015.09.004}).
#'
#' @param destDir character, specifying the destination directory in which to download
#'                and extract the data.
#'
#' @param studyArea (optional) `sf` polygon to which the national raster will be cropped and masked.
#'
#' @return `SpatRaster`
#'
#' @export
#' @rdname ntems
ntemsAge <- function(destDir, studyArea = NULL) {
  .ntemsData(destDir = destDir, studyArea = studyArea, type = "CA_forest_age")
}

#' @export
#' @rdname ntems
ntemsFires <- function(destDir, studyArea = NULL) {
  .ntemsData(destDir = destDir, studyArea = studyArea, type = "CA_Forest_Fire")
}

#' @export
#' @rdname ntems
ntemsHarvest <- function(destDir, studyArea = NULL) {
  .ntemsData(destDir = destDir, studyArea = studyArea, type = "CA_Forest_Fire")
}

#' @export
#' @rdname ntems
ntemsLeadSpp <- function(destDir, studyArea = NULL) {
  .ntemsData(destDir = destDir, studyArea = studyArea, type = "CA_forest_lead_tree_species")
}

#' @export
#' @rdname ntems
ntemsWildfire <- function(destDir, studyArea = NULL) {
  .ntemsData(destDir = destDir, studyArea = studyArea, type = "CA_Forest_Fire")
}
