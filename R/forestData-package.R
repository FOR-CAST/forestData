#' Tools for Importing Canadian Forestry Data
#'
#' @import methods
#' @name forestData-package
#'
"_PACKAGE"

## usethis namespace: start
#' @importFrom archive archive_extract
#' @importFrom data.table fread
#' @importFrom data.table set
#' @importFrom data.table setkey
#' @importFrom dplyr matches
#' @importFrom exactextractr rasterize_polygons
#' @importFrom glue glue
#' @importFrom RCurl getURL
#' @importFrom sf st_as_sf
#' @importFrom sf st_collection_extract
#' @importFrom sf st_crs
#' @importFrom sf st_intersection
#' @importFrom sf st_make_valid
#' @importFrom sf st_read
#' @importFrom sf st_transform
#' @importFrom stats na.omit
#' @importFrom stringr str_subset
#' @importFrom terra crs
#' @importFrom terra deepcopy
#' @importFrom terra mosaic
#' @importFrom terra rast
#' @importFrom terra setValues
#' @importFrom terra values
#' @importFrom terra vect
#' @importFrom terra writeRaster
#' @importFrom tidyterra filter
#' @importFrom tidyterra pull
#' @importFrom tidyterra select
## usethis namespace: end
NULL
