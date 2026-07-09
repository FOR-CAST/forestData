## annual landcover products (2019; v2)
.ntems_vlce2_years <- 1984L:2019L
.ntems_archives_vlce2 <- lapply(.ntems_vlce2_years, function(x) {
  paste0("CA_forest_VLCE2_", x, ".zip")
})
names(.ntems_archives_vlce2) <- tools::file_path_sans_ext(.ntems_archives_vlce2)

.ntems_types_vlce2 <- lapply(.ntems_vlce2_years, function(x) paste0("CA_forest_VLCE2_", x))
names(.ntems_types_vlce2) <- paste0("landcover", .ntems_vlce2_years)

## other forest data products (2019 or later)
.ntems_archives <- list(
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
  append(.ntems_archives_vlce2)

## user-facing types; used to convert to NTEMS archive names
.ntems_types <- list(
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
  append(.ntems_types_vlce2)

.ntems_data <- function(dest_dir, study_area = NULL, type = NULL) {
  if (is.null(type)) {
    stop("please specify valid NTEMS data type")
  }
  ## build the download URL at call time (base lives in R/urls.R)
  url <- paste0(.url_ntems, .ntems_archives[[type]])

  archive <- file.path(dest_dir, basename(url))
  workflowtools::download_once(url, archive, mode = "wb")
  files <- workflowtools::archive_extract_once(archive, dir = dest_dir)

  tif <- grep("[.]tif$", files, value = TRUE, ignore.case = TRUE)
  if (length(tif) == 0L) {
    stop("no raster (.tif) found in NTEMS archive '", basename(url), "'")
  }

  r <- terra::rast(tif[[1]])

  if (!is.null(study_area)) {
    r <- .crop_mask(r, study_area)
  }

  r
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
#' - `fao`: forest area based on FAO definitions for Canada (\doi{10.1093/forestry/cpaa006});
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
#' @param dest_dir character, specifying the destination directory in which to download
#'                and extract the data (defaults to current working directory).
#'
#' @param study_area (optional) `sf` polygon to which the national raster will be cropped and masked.
#'
#' @return `SpatRaster`
#'
#' @export
ntems <- function(type, dest_dir = NULL, study_area = NULL) {
  if (missing(type)) {
    stop("'type' must be specified")
  }

  type <- tolower(type)
  validtypes <- names(.ntems_types) |> sort()

  stopifnot(type %in% validtypes)

  if (is.null(dest_dir)) {
    dest_dir <- getwd()
  }

  .ntems_data(dest_dir = dest_dir, study_area = study_area, type = .ntems_types[[type]])
}
