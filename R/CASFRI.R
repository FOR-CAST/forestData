utils::globalVariables(c(
  "..cols2keep", "cas_id"
))

.spp_cols <- function(x) {
  grep("^species_[0-9]", names(x), value = TRUE, ignore.case = TRUE)
}

.pct_cols <- function(x) {
  grep("^species_per_[0-9]", names(x), value = TRUE, ignore.case = TRUE)
}

#' CASFRI species cover data
#'
#' Extract spatial locations (polygons) and forest species layer attributes,
#' and create percent cover rasters for each species in an optionally provided study area.
#'
#' @param x Either a named list of file paths corresponding to exported CASFRI database files
#' (see details), or a Postgresql database connection providing access to CASFRI database.
#'
#' @param study_area (optional) `SpatVector` (or `sf`) polygons identifying the study area
#' boundaries, used to extract a subset of the species cover data (spatial intersection).
#'
#' @return A `SpatVector` of CASFRI polygons with the joined species/percent-cover attributes.
#'
#' @details If `x` is a list, it must be a named list with elements corresponding to
#' each of the CAS tables (e.g., `.csv` files) and a geodatabase file (`.gdb`):
#'
#' - `HDR`: header attributes;
#' - `CAS`: CAS base polygon attributes;
#' - `LYR`: forest-level attributes;
#' - `NFL`: non-forest land attributes;
#' - `DST`: disturbance history attributes;
#' - `ECO`: ecological specific attributes;
#' - `GEO`: geometry attributes.
#'
#' See <https://github.com/CASFRI/CASFRI/tree/master/documentation/specifications#common-attribute-schema>
#' for full details.
#'
#' @export
#' @rdname casfri-species
casfri_species_cover <- function(x, study_area = NULL) {
  # UseMethod("casfri_species_cover")
  if (
    is.list(x) && all(tolower(names(x)) %in% c("geo", "hdr", "cas", "eco", "dst", "lyr", "nfl"))
  ) {
    casfri_species_cover.list(x, study_area)
  } else if (is(x, "PqConnection")) {
    casfri_species_cover.PqConnection(x, study_area)
  } else {
    stop("x must be a named list of filenames or a postpgresql database connection")
  }
}

#' @rdname casfri-species
casfri_species_cover.list <- function(x, study_area = NULL) {
  names(x) <- tolower(names(x))

  ## TODO: rework this once the mapserver/geoserver API is active and working;
  ##       REST API will serve (zipped) flat files of the denormalized data.
  geo <- terra::vect(x$geo)
  lyr <- data.table::fread(x$lyr)

  if (!is.null(study_area)) {
    ## clip geo to the study area, keeping geo's own CRS
    geo <- spatialutils::prep_vector(geo, studyArea = study_area, crs = terra::crs(geo))
    lyr <- lyr[cas_id %in% geo$cas_id, ]
  }

  data.table::setkey(lyr, "cas_id")

  ## see CASFRI error codes:
  ## <https://github.com/CASFRI/CASFRI/tree/master/documentation/specifications#Error_codes>
  NA_chr <- c(
    "EMPTY_STRING",
    "NULL_VALUE",
    "NOT_APPLICABLE",
    "UNKNOWN_VALUE",
    "OUT_OF_RANGE",
    "NOT_IN_SET",
    "INVALID_VALUE",
    "WRONG_TYPE"
  )
  NA_num <- c(-8886, -8887, -8888, -9995, -9997, -9998, -9999)
  cols2keep <- c("cas_id", .spp_cols(lyr), .pct_cols(lyr))
  lyr <- lyr[, ..cols2keep]

  for (i in seq_len(length(.spp_cols(lyr)))) {
    data.table::set(
      lyr,
      which(lyr[[paste0("species_", i)]] %in% NA_chr),
      paste0("species_", i),
      NA_character_
    )
    data.table::set(
      lyr,
      which(lyr[[paste0("species_per_", i)]] %in% NA_num),
      paste0("species_per_", i),
      NA_integer_
    )
  }

  terra::merge(geo, lyr, by = "cas_id")
}

#' @rdname casfri-species
casfri_species_cover.PqConnection <- function(x, study_area = NULL) {
  ## use parametrized queries, e.g.,
  # airport <- dbSendQuery(con, "SELECT * FROM airports WHERE faa = $1 or faa = $2")
  # dbBind(airport, list("GPT", "MSY"))
  # dbFetch(airport)
  # dbClearResult(airport)
}

#' @param x `SpatVector` produced via `casfri_species_cover()` (an `sf` object or a
#'   source readable by [terra::vect()] is also accepted).
#' @param raster_to_match template `SpatRaster` defining the output grid and CRS.
#'
#' @return A `SpatRaster` with one percent-cover layer (0-100) per species.
#'
#' @export
#' @rdname casfri-species
casfri_species_layers <- function(x, raster_to_match) {
  if (!inherits(x, "SpatVector")) {
    x <- terra::vect(x)
  }
  if (!inherits(raster_to_match, "SpatRaster")) {
    raster_to_match <- terra::rast(raster_to_match)
  }
  .species_pct_layers(x, .spp_cols(x), .pct_cols(x), raster_to_match)
}
