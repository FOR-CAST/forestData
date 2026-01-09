## annual landcover products (2019; v2)
.ntemsVLCE2years <- 1984L:2019L
.ntemsArchivesVLCE2 <- lapply(.ntemsVLCE2years, function(x) paste0("CA_forest_VLCE2_", x, ".zip"))
names(.ntemsArchivesVLCE2) <- tools::file_path_sans_ext(.ntemsArchivesVLCE2)

.ntemsTypesVLCE2 <- lapply(.ntemsVLCE2years, function(x) paste0("CA_forest_VLCE2_", x))
names(.ntemsTypesVLCE2) <- paste0("landcover", .ntemsVLCE2years)

## other forest data products (2019 or later)
.ntemsArchives <- list(
  CA_FAO_forest_2019 = "CA_FAO_forest_2019.zip",
  CA_forest_age = "CA_forest_age_2019.zip",
  CA_forest_Distance2Second = "CA_forest_Distance2Second.zip",
  CA_Forest_Fire = "CA_Forest_Fire_1985-2020.zip",
  CA_forest_fire_recovery_rate = "CA_forest_fire_recovery_rate.zip",
  CA_forest_fire_years2recovery = "CA_forest_fire_years2recovery.zip",
  CA_Forest_Harvest = "CA_Forest_Harvest_1985-2020.zip",
  CA_forest_harvest_recovery_rate = "CA_forest_harvest_recovery_rate.zip",
  CA_forest_harvest_years2recovery = "CA_forest_harvest_years2recovery.zip",
  CA_forest_lead_tree_species = "CA_forest_lead_tree_species.zip",
  CA_forest_tree_species_probabilities = "CA_forest_tree_species_probabilities.zip",
  CA_Forest_Satellite_Based_Inventory = "CA_Forest_Satellite_Based_Inventory_2020.zip",
  CA_Forest_Wildfire = "CA_Forest_Wildfire_dNBR_1985_2020.zip"
) |>
  append(.ntemsArchivesVLCE2)

## user-facing types; used to convert to NTEMS archive names
.ntemsTypes <- list(
  age = "CA_forest_age",
  d2sc = "CA_forest_Distance2Second",
  fao = "CA_FAO_forest_2019",
  fires = "CA_Forest_Fire",
  firesrecovery = "CA_forest_fire_recovery_rate",
  firesy2r = "CA_forest_fire_years2recovery",
  harvest = "CA_Forest_Harvest",
  harvestrecovery = "CA_forest_harvest_recovery_rate",
  harvesty2r = "CA_forest_harvest_years2recovery",
  leadingspecies = "CA_forest_lead_tree_species",
  sbfi = "CA_Forest_Satellite_Based_Inventory",
  speciesprobs = "CA_forest_tree_species_probabilities",
  wildfirednbr = "CA_Forest_Wildfire"
) |>
  append(.ntemsTypesVLCE2)

## NTEMS urls
.ntemsBaseURL <- "https://opendata.nfis.org/downloads/forest_change/"
.ntemsURLs <- lapply(.ntemsArchives, function(x) paste0(.ntemsBaseURL, x)) ## preserve names

.ntemsData <- function(destDir, studyArea = NULL, type = NULL) {
  if (is.null(type)) {
    stop("please specify valid NTEMS data type")
  } else {
    url <- .ntemsURLs[[type]]
  }

  x <- Cache({
    prepInputs(url = url, studyArea = studyArea, destinationPath = destDir)
  })

  return(x)
}

#' NTEMS data
#'
#' Get and prepare data from NTEMS (<https://opendata.nfis.org/mapserver/nfis-change_eng.html>).
#'
#' @note Currently only supports the most recent data (made available 2019 or later).
#'       Previous NTEMS products (e.g., 2015 forest data) can be downloaded from the NTEMS site
#'       linked above.
#'
#' @details
#' `type` must be one of the following:
#' - `age`: forest age (\doi{10.1016/j.rse.2023.113529});
#' - `d2sc`: distance-to-second-class for tree species (\doi{10.1016/j.rse.2022.113276});
#' - `fao`: forest area based on FAO definitions for Canada (\doi{10.1093/forestry/cpaa0063});
#' - `fires`, `harvest`: wildfire or harvest disturbances (\doi{10.1080/17538947.2016.1187673});
#' - `firesrecovery`, `harvestrecovery`: post-disturbance forest recovery data
#'                               (\doi{10.1016/j.rse.2017.03.035}, \doi{10.1016/j.rse.2022.112904});
#' - `firesy2r`, `harvesty2r`: post-disturbance years-to-recovery
#'                               (\doi{10.1016/j.rse.2017.03.035}, \doi{10.1016/j.rse.2022.112904});
#' - `landcover<year>`: annual forest landcover 1984-2019
#'                      (\doi{10.1080/07038992.2018.1437719}, \doi{10.1016/j.rse.2021.112780})
#' - `leadingspecies`: leading tree species (\doi{10.1016/j.rse.2022.113276});
#' - `sbfi`: Satellite-Based Forest Inventory (\doi{10.1093/forestry/cpad065});
#' - `speciesprobs`: tree species probabilities (\doi{10.1016/j.rse.2022.113276});
#' - `wildfirednbr`: wildfire differenced Normalized Burn Ratio
#'                   (\doi{10.1016/j.rse.2014.11.005}; \doi{10.1016/j.rse.2015.09.004});
#'
#' @param type character, specifying which NTEMS product to download and prepare (see Details).
#'
#' @param destDir character, specifying the destination directory in which to download
#'                and extract the data (defaults to current working directory).
#'
#' @param studyArea (optional) `sf` polygon to which the national raster will be cropped and masked.
#'
#' @return `SpatRaster`
#'
#' @export
ntems <- function(type, destDir = NULL, studyArea = NULL) {
  if (missing(type)) {
    stop("'type' must be specified")
  }

  type <- tolower(type)
  validtypes <- names(.ntemsTypes) |> sort()

  stopifnot(type %in% validtypes)

  if (is.null(destDir)) {
    destDir <- getwd()
  }

  .ntemsData(destDir = destDir, studyArea = studyArea, type = .ntemsTypes[[type]])
}
