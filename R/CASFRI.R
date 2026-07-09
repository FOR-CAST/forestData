utils::globalVariables(c(
  "..cols2keep", "cas_id"
))

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
#' (see details), or a Postgresql database connection providing access to CASFRI database.
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
  if (
    is.list(x) && all(tolower(names(x)) %in% c("geo", "hdr", "cas", "eco", "dst", "lyr", "nfl"))
  ) {
    casfriSpeciesCover.list(x, studyArea)
  } else if (is(x, "PqConnection")) {
    casfriSpeciesCover.PqConnection(x, studyArea)
  } else {
    stop("x must be a named list of filenames or a postpgresql database connection")
  }
}

#' @rdname casfri-species
casfriSpeciesCover.list <- function(x, studyArea = NULL) {
  names(x) <- tolower(names(x))

  ## TODO: rework this once the mapserver/geoserver API is active and working;
  ##       REST API will serve (zipped) flat files of the denormalized data.
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
  cols2keep <- c("cas_id", .sppCols(lyr), .pctCols(lyr))
  lyr <- lyr[, ..cols2keep]

  for (i in seq_len(length(.sppCols(lyr)))) {
    set(lyr, which(lyr[[paste0("species_", i)]] %in% NA_chr), paste0("species_", i), NA_character_)
    set(
      lyr,
      which(lyr[[paste0("species_per_", i)]] %in% NA_num),
      paste0("species_per_", i),
      NA_integer_
    )
  }

  casfri <- merge(geo, lyr, by = "cas_id")

  return(casfri)
}

#' @rdname casfri-species
casfriSpeciesCover.PqConnection <- function(x, studyArea = NULL) {
  ## use parametrized queries, e.g.,
  # airport <- dbSendQuery(con, "SELECT * FROM airports WHERE faa = $1 or faa = $2")
  # dbBind(airport, list("GPT", "MSY"))
  # dbFetch(airport)
  # dbClearResult(airport)
}

#' @param x `sf` object produced via `casfriSpeciesCover()`
#' @param rasterToMatch template raster (`SpatRaster`)
#'
#' @return `RasterStack`
#'
#' @export
#' @rdname casfri-species
casfriSpeciesLayers <- function(x, rasterToMatch) {
  sppCols <- .sppCols(x)
  pctCols <- .pctCols(x)
  speciesPresent <- na.omit(unique(unlist(lapply(sppCols, function(sp) x[[sp]]))))

  template <- rasterToMatch * 0.0
  x <- st_transform(x, st_crs(template))
  sppRasters <- lapply(seq_along(sppCols), function(i) {
    x_ <- x[!is.na(x[[sppCols[i]]]), ]
    if (nrow(x_) > 0) {
      spp <- sort(unique(x_[[sppCols[i]]]))
      ## TODO: use terra instead of raster
      xRas <- stack(lapply(spp, function(sp) {
        ## percent cover, per species, using polygon with highest pixel-area covered
        ## TODO: get area-weighted mean using all polygons in a pixel; use terra
        xSp <- x_[x_[[sppCols[i]]] == sp, ]
        xRasSp <- xIdx <- exactextractr::rasterize_polygons(xSp, template, min_coverage = 0.00) ## poly index
        ids <- which(!is.na(xIdx[]))
        xRasSp[ids] <- xSp[xIdx[ids], pctCols[i]][[pctCols[i]]] ## replace indices with actual species codes

        return(xRasSp)
      }))
      names(xRas) <- spp
    } else {
      xRas <- NULL
    }

    return(xRas)
  })
  sppRasters <- sppRasters[!sapply(sppRasters, is.null)] ## remove NULLs

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
    z <- sum(zstck, na.rm = TRUE) ## TODO: improve this calc; weighted?
    names(z) <- spp
    z
  })
  names(sppLayers) <- speciesPresent

  ## rescale all layers to be between 0 and 100 percent cover
  for (sp in speciesPresent) {
    sppLayers[[sp]] <- getValues(sppLayers[[sp]]) |>
      .rescale(x = _, x.min = 0, new.min = 0, new.max = 100) |>
      setValues(sppLayers[[sp]], values = _)
  }

  stack(sppLayers)
}
