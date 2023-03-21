utils::globalVariables(c(
  "geometry", "USETHIS"
))

#' `prepInputsEcoBoundaries`
#'
#' Prepare boundaries based on Canadian national ecodistricts, -regions, -provinces, or -zones.
#'
#' @param url character. URL from which to download and prepare fire regime polygons.
#'            Defaults are provided for Canadian ecodistrict, ecoregion, ecoprovince, and ecozone.
#'
#' @param destinationPath character. Path to directory where data will be downloaded.
#'
#' @param studyArea `sf` object corresponding to the study area of interest.
#'
#' @param rasterToMatch TODO
#'
#' @param type character. The polygon type to use:
#'             Must be one of "ECODISTRICT", "ECOREGION" (default), "ECOPROVINCE", "ECOZONE",
#'             "FRT", or "FRU".
#'             If `url` to BEC shapefile is provided, can also be one of:
#'             "BECNDT", "BECSUBZONE", or "BECZONE".
#'
#' @export
#' @importFrom dplyr %>% group_by summarise ungroup
#' @importFrom raster crs
#' @importFrom reproducible prepInputs
#' @importFrom sf st_as_sf st_collection_extract st_union
#'
#' @examples
#' library(sf)
#' library(sp)
#'
#' ## random study area in central Alberta
#' studyArea <- SpatialPoints(data.frame(lon = -115, lat = 55), proj4string = CRS("EPSG:4326")) %>%
#' st_as_sf() %>%
#'   st_transform(paste("+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95",
#'                    "+x_0=0 +y_0=0 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")) %>%
#'   as_Spatial() %>%
#'   SpaDES.tools::randomStudyArea(center = ., seed = 60, size = 1e10) %>%
#'   st_as_sf()
#'
#' \donttest{
#' ecoregions <- prepInputsFireRegimePolys(studyArea = studyArea, type = "ECOREGION")
#' plot(frpEcoregion)
#' }
prepInputsFireRegimePolys <- function(url = NULL, destinationPath = tempdir(),
                                      studyArea = NULL, rasterToMatch = NULL, type = "ECOZONE") {
  type <- toupper(type)
  allowedTypes <- c("ECODISTRICT", "ECOREGION", "ECOPROVINCE", "ECOZONE")

  stopifnot(type %in% allowedTypes)

  if (is.null(url)) {
    urlList <- list(
      ecodistrict = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/district/ecodistrict_shp.zip",
      ecoregion = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/region/ecoregion_shp.zip",
      ecoprovince = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/province/ecoprovince_shp.zip",
      ecozone = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/zone/ecozone_shp.zip",
      frt = "https://zenodo.org/record/4458156/files/FRT.zip",
      fru = "https://zenodo.org/record/4458156/files/FRU.zip"
    )
    url <- urlList[[tolower(type)]]
  }

  if (!is.null(studyArea) && is(studyArea, "SpatialPolygons")) {
    studyArea <- sf::st_as_sf(studyArea)
  }

  tmp <- prepInputs(url = url,
                    destinationPath = destinationPath,
                    studyArea = studyArea,
                    rasterToMatch = rasterToMatch,
                    fun = "sf::st_read",
                    overwrite = TRUE) ## TODO: doesn't reproject -- fix upstream?

  ## workaround issues with prepInputs() not reprojecting:
  if (!is.null(rasterToMatch)) {
    tmp <- sf::st_transform(tmp, raster::crs(rasterToMatch))
  } else if (is.null(rasterToMatch) && !is.null(studyArea)) {
    tmp <- sf::st_transform(tmp, sf::st_crs(studyArea))
  }

  cols2keep <- substr(type, 1, 10) ## colname abbrev to 10 chars
  tmp <- tmp[, cols2keep]
  tmp$USETHIS <- tmp[[cols2keep[1]]]
  tmp$USETHIS <- as.factor(tmp$USETHIS)

  tmp2 <- group_by(tmp, USETHIS) %>% summarise(geometry = sf::st_union(geometry)) %>% ungroup()
  polys <- sf::st_collection_extract(tmp2)
  polys[["PolyID"]] <- as.integer(1:nrow(polys))
  polys[["USETHIS"]] <- NULL

  return(polys)
}
