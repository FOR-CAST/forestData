#' National eco-boundaries
#'
#' Prepare boundaries based on Canadian national ecodistricts, -regions, -provinces, or -zones.
#'
#' @param type character. The polygon type to use:
#'             Must be one of "ECODISTRICT", "ECOREGION", "ECOPROVINCE", or "ECOZONE".
#'
#' @param destinationPath character. Path to directory where data will be downloaded.
#'
#' @param studyArea (optional) `sf` object corresponding to the study area of interest.
#'
#' @param rasterToMatch (optional) template raster to use.
#'
#' @importFrom raster crs
#' @importFrom reproducible prepInputs
#' @importFrom sf st_as_sf st_collection_extract st_make_valid st_transform
#'
#' @examples
#' library(sf)
#' library(sp)
#'
#' ## random study area in central Alberta
#' studyArea <- SpatialPoints(data.frame(lon = -115, lat = 55), proj4string = CRS("EPSG:4326")) |>
#'   st_as_sf() |>
#'   st_transform(paste("+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95",
#'                    "+x_0=0 +y_0=0 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")) |>
#'   as_Spatial() |>
#'   SpaDES.tools::randomStudyArea(center = _, seed = 60, size = 1e10) |>
#'   st_as_sf()
#'
#' \donttest{
#' ezs <- ecozones(studyArea = studyArea)
#' plot(ezs["ZONE_NAME"], main = "ecozones in study area")
#'
#' eps <- ecoprovinces(studyArea = studyArea)
#' plot(eps["ECOPROVINC"], main = "ecoprovinces in study area")
#'
#' ers <- ecoregions(studyArea = studyArea)
#' plot(ers["REGION_NAM"], main = "ecoregions in study area", key.pos = 1)
#'
#' eds <- ecodistricts(studyArea = studyArea)
#' plot(eds["ECODISTRIC"], main = "ecodistricts in study area")
#' }
#'
#' @rdname ecoboundaries
.ecoboundaries <- function(type = NULL, destinationPath = tempdir(),
                           studyArea = NULL, rasterToMatch = NULL) {
  type <- toupper(type)
  allowedTypes <- c("ECODISTRICT", "ECOREGION", "ECOPROVINCE", "ECOZONE")

  stopifnot(type %in% allowedTypes)

  urlList <- list(
      ecodistrict = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/district/ecodistrict_shp.zip",
      ecoregion = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/region/ecoregion_shp.zip",
      ecoprovince = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/province/ecoprovince_shp.zip",
      ecozone = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/zone/ecozone_shp.zip"
  )
  url <- urlList[[tolower(type)]]

  if (!is.null(studyArea) && is(studyArea, "SpatialPolygons")) {
    studyArea <- st_as_sf(studyArea)
  }

  tmp <- prepInputs(url = url,
                    destinationPath = destinationPath,
                    studyArea = studyArea,
                    rasterToMatch = rasterToMatch,
                    fun = "sf::st_read",
                    overwrite = TRUE) ## TODO: doesn't reproject -- fix upstream?
  tmp <- st_collection_extract(tmp, "POLYGON") |>
    st_make_valid()

  ## workaround issues with prepInputs() not reprojecting:
  if (!is.null(rasterToMatch)) {
    tmp <- st_transform(tmp, crs(rasterToMatch))
  } else if (is.null(rasterToMatch) && !is.null(studyArea)) {
    tmp <- st_transform(tmp, st_crs(studyArea))
  }

  return(tmp)
}

#' @export
#' @rdname ecoboundaries
ecodistricts <- function(destinationPath = tempdir(), studyArea = NULL, rasterToMatch = NULL) {
  .ecoboundaries(type = "ECODISTRICT", destinationPath = destinationPath,
                 studyArea = studyArea, rasterToMatch = rasterToMatch)
}

#' @export
#' @rdname ecoboundaries
ecoregions <- function(destinationPath = tempdir(), studyArea = NULL, rasterToMatch = NULL) {
  .ecoboundaries(type = "ECOREGION", destinationPath = destinationPath,
                 studyArea = studyArea, rasterToMatch = rasterToMatch)
}

#' @export
#' @rdname ecoboundaries
ecoprovinces <- function(destinationPath = tempdir(), studyArea = NULL, rasterToMatch = NULL) {
  .ecoboundaries(type = "ECOPROVINCE", destinationPath = destinationPath,
                 studyArea = studyArea, rasterToMatch = rasterToMatch)
}

#' @export
#' @rdname ecoboundaries
ecozones <- function(destinationPath = tempdir(), studyArea = NULL, rasterToMatch = NULL) {
  .ecoboundaries(type = "ECOZONE", destinationPath = destinationPath,
                 studyArea = studyArea, rasterToMatch = rasterToMatch)
}
