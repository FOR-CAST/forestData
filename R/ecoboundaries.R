#' National eco-boundaries
#'
#' Prepare boundaries based on Canadian national ecodistricts, -regions, -provinces, or -zones.
#'
#' @param type character. The polygon type to use:
#'             Must be one of "ECODISTRICT", "ECOREGION", "ECOPROVINCE", or "ECOZONE".
#'
#' @param destination_path character. Path to directory where data will be downloaded.
#'
#' @param study_area (optional) `SpatVector` (or `sf`) polygons defining the study
#'   area of interest. When supplied, the boundaries are cropped, masked, and
#'   reprojected to it (via [spatialutils::prep_vector()]).
#'
#' @param raster_to_match (optional) template `SpatRaster`; when supplied, the
#'   returned vector is reprojected to its CRS.
#'
#' @return A `SpatVector` of the requested eco-boundary polygons.
#'
#' @examples
#' \donttest{
#' ## study area: a ~100 km buffer around a point in central Alberta
#' lcc <- paste(
#'   "+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95",
#'   "+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
#' )
#' study_area <- terra::vect(cbind(-115, 55), crs = "EPSG:4326") |>
#'   terra::project(lcc) |>
#'   terra::buffer(1e5)
#'
#' ezs <- ecozones(study_area = study_area)
#' terra::plot(ezs, "ZONE_NAME", main = "ecozones in study area")
#' }
#'
#' @rdname ecoboundaries
.ecoboundaries <- function(
  type = NULL,
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
) {
  type <- toupper(type)
  allowed_types <- c("ECODISTRICT", "ECOREGION", "ECOPROVINCE", "ECOZONE")

  stopifnot(type %in% allowed_types)

  url <- .url_ecoboundaries[[tolower(type)]]

  zip <- file.path(destination_path, basename(url))
  workflowtools::download_once(url, zip, mode = "wb")
  files <- workflowtools::archive_extract_once(zip, dir = destination_path)

  shp <- grep("[.]shp$", files, value = TRUE, ignore.case = TRUE)
  if (length(shp) == 0L) {
    stop("no shapefile (.shp) found in '", basename(url), "'")
  }

  tmp <- terra::vect(shp[[1]])

  if (!is.null(study_area) && !inherits(study_area, "SpatVector")) {
    study_area <- terra::vect(study_area)
  }

  if (!is.null(study_area)) {
    ## crop + mask + reproject (terra-native; replaces the postprocessing that
    ## prepInputs() used to perform internally). Target CRS is raster_to_match's
    ## when supplied, otherwise the study area's.
    crs <- if (!is.null(raster_to_match)) terra::crs(raster_to_match) else terra::crs(study_area)
    tmp <- spatialutils::prep_vector(tmp, studyArea = study_area, crs = crs)
  } else if (!is.null(raster_to_match)) {
    tmp <- terra::project(tmp, terra::crs(raster_to_match))
  }

  tmp
}

#' @export
#' @rdname ecoboundaries
ecodistricts <- function(destination_path = tempdir(), study_area = NULL, raster_to_match = NULL) {
  .ecoboundaries(
    type = "ECODISTRICT",
    destination_path = destination_path,
    study_area = study_area,
    raster_to_match = raster_to_match
  )
}

#' @export
#' @rdname ecoboundaries
ecoregions <- function(destination_path = tempdir(), study_area = NULL, raster_to_match = NULL) {
  .ecoboundaries(
    type = "ECOREGION",
    destination_path = destination_path,
    study_area = study_area,
    raster_to_match = raster_to_match
  )
}

#' @export
#' @rdname ecoboundaries
ecoprovinces <- function(destination_path = tempdir(), study_area = NULL, raster_to_match = NULL) {
  .ecoboundaries(
    type = "ECOPROVINCE",
    destination_path = destination_path,
    study_area = study_area,
    raster_to_match = raster_to_match
  )
}

#' @export
#' @rdname ecoboundaries
ecozones <- function(destination_path = tempdir(), study_area = NULL, raster_to_match = NULL) {
  .ecoboundaries(
    type = "ECOZONE",
    destination_path = destination_path,
    study_area = study_area,
    raster_to_match = raster_to_match
  )
}
