.sppCols <- function(x) {
  grep("^species_[0-9]", colnames(x), value = TRUE, ignore.case = TRUE)
}

.pctCols <- function(x) {
  grep("^species_per_[0-9]", colnames(x), value = TRUE, ignore.case = TRUE)
}

#' CASFRI species cover data
#'
#' Extract spatial locations (polygons) and forest species layer attributes,
#' and create percent cover rasters for each species in an optionally provided study area.
#'
#' @param x Either a named list of file paths corresponding to exported CASFRI database files
#' (see details), or a Postgresl database connection providing access to CASFRI database.
#'
#' @param studyArea (optional) `sf` polygons object identifying the study area boundaries,
#' used to extract a subset of the species cover data (i.e., spatial  intersection).
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
#' @rdname casfri-species
casfriSpeciesCover <- function(x, studyArea = NULL) {
  # UseMethod("casfriSpeciesCover")
  if (is.list(x) && all(tolower(names(x)) %in% c("geo", "hdr", "cas", "eco", "dst", "lyr", "nfl"))) {
    casfriSpeciesCover.list(x, studyArea)
  } else if (is(x, "PqConnection")) {
    casfriSpeciesCover.PqConnection(x, studyArea)
  } else {
    stop("x must be a named list of filenames or a postpgresql database connection")
  }
}

#' @importFrom data.table fread set setkey
#' @importFrom sf st_crs st_intersection st_make_valid st_read st_transform
#' @rdname casfri-species
casfriSpeciesCover.list <- function(x, studyArea = NULL) {
  names(x) <- tolower(names(x))

  geo <- st_read(x$geo)
  lyr <- fread(x$lyr)

  if (!is.null(studyArea)) {
    geo <- studyArea |>
      st_transform(st_crs(geo)) |>
      st_intersection(geo) |>
      st_make_valid()

    lyr <- lyr[cas_id %in% geo$cas_id, ]
  }

  setkey(lyr, "cas_id")

  ## see CASFRI error codes:
  ## <https://github.com/CASFRI/CASFRI/tree/master/documentation/specifications#Error_codes>
  NAVals <- c(-8886, -8887, -8888, -9995, -9997, -9998, -9999)
  cols2keep <- c("cas_id", .sppCols(lyr), .pctCols(lyr))
  lyr <- lyr[, ..cols2keep]

  for (i in seq_len(length(.sppCols(lyr)))) {
    set(lyr, which(lyr[[paste0("species_", i)]] %in% NAVals), paste0("species_", i), NA_character_)
    set(lyr, which(lyr[[paste0("species_per_", i)]] %in% NAVals), paste0("species_", i), NA_integer_)
  }

  casfri <- merge(geo, lyr, by = "cas_id")

  return(casfri)
}

#' @rdname casfri-species
casfriSpeciesCover.PqConnection <- function(x, ...) {
  ## use parametrized queries, e.g.,
  # airport <- dbSendQuery(con, "SELECT * FROM airports WHERE faa = $1 or faa = $2")
  # dbBind(airport, list("GPT", "MSY"))
  # dbFetch(airport)
  # dbClearResult(airport)
}

#' @param x `sf` object produced via `casfriSpeciesCover()`
#' @param rtm template raster (`RasterLayer`)
#'
#' @return `RasterStack`
#'
#' @export
#' @importFrom exactextractr rasterize_polygons
#' @importFrom raster raster stack
#' @rdname casfri-species
casfriSpeciesLayers <- function(x, rtm) {
  sppCols <- .sppCols(x)
  pctCols <- .pctCols(x)
  speciesPresent <- na.omit(unique(unlist(lapply(sppCols, function(sp) x[[sp]]))))

  template <- raster(rtm * 0L)
  sppRasters <- lapply(seq_along(sppCols), function(i) {
    x_ <- x[!is.na(x[[sppCols[i]]]), ]
    spp <- sort(unique(x_[[sppCols[i]]]))
    xRas <- stack(lapply(spp, function(sp) {
      ## percent cover, per species, using polygon with highest pixel-area covered
      ## TODO: get area-weighted mean using all polygons in a pixel
      xSp <- x_[x_[[sppCols[i]]] == sp, ]
      xRasSp <- xIdx <- exactextractr::rasterize_polygons(xSp, template, min_coverage = 0.05) ## poly index
      ids <- which(!is.na(xIdx[]))
      xRasSp[ids] <- xSp[xIdx[ids], pctCols[i]][[pctCols[i]]] ## replace indices with actual species codes

      return(xRasSp)
    }))
    names(xRas) <- spp

    return(xRas)
  })

  sppLayers <- lapply(speciesPresent, function(spp) {
    zlist <- lapply(sppRasters, function(x) {
      y <- if (spp %in% names(x)) {
        x[[spp]]
      } else {
        template
      }
      names(y) <- spp
      y
    })
    zstck <- stack(zlist)
    z <- sum(zstck, na.rm = TRUE)
    names(z) <- spp
    z
  })
  names(sppLayers) <- speciesPresent

  stack(sppLayers)
}
