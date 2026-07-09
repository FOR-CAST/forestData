#' Prepare species layer rasters from SBFI data
#'
#' @param gdbFile character specifying the path to the SBFI gdb file
#' @param studyArea `SpatVector` polygons object
#' @param rasterToMatch `SpatRaster` object
#'
#' @export
prepSpeciesLayers_SBFI <- function(gdbFile, studyArea, rasterToMatch) {
  if (!inherits(studyArea, "SpatVector")) {
    studyArea <- terra::vect(rasterToMatch)
  }
  if (!inherits(rasterToMatch, "SpatRaster")) {
    rasterToMatch <- terra::rast(rasterToMatch)
  }
  sbfi2020_grid <- terra::vect(gdbFile, layer = "_Grid_forested_ecosystem")
  sbfi2020_crs <- terra::crs(sbfi2020_grid)

  sbfi2020_grid_ids <- terra::intersect(studyArea, sbfi2020_grid) |>
    tidyterra::select(Id) |>
    tidyterra::pull(Id)

  sbfi2020_grid_studyArea <- sbfi2020_grid |> tidyterra::filter(Id %in% sbfi2020_grid_ids)

  sbfi2020_tile_names <- glue::glue("CA_2020_tile_{sbfi2020_grid_ids}_metrics")

  sbfi2020_tile_rasters <- lapply(sbfi2020_tile_names, function(lyr) {
    layer <- terra::vect(gdbFile, layer = lyr) |>
      tidyterra::select(dplyr::matches("^(SPECIES_[1-5]|SPECIES_[1-5]_PERC)$"))

    speciesPresent <- tidyterra::select(layer, dplyr::matches("^SPECIES_[1-5]$")) |>
      as.data.frame() |>
      apply(2, unique) |>
      unlist(use.names = FALSE) |>
      unique() |>
      trimws() |>
      stringr::str_subset(".+") |>
      sort()

    template <- terra::deepcopy(rasterToMatch) * 0.0

    sppCols <- tidyterra::select(layer, dplyr::matches("^SPECIES_[1-5]$")) |>
      as.data.frame() |>
      colnames()
    pctCols <- dplyr::select(layer, dplyr::matches("^SPECIES_[1-5]_PERC$")) |>
      as.data.frame() |>
      colnames()

    sppRastersList <- lapply(seq_along(sppCols), function(i) {
      vri <- tidyterra::filter(layer, !is.na(!!sppCols[i]))
      spp <- tidyterra::pull(vri, sppCols[i]) |>
        unique() |>
        sort() |>
        trimws() |>
        stringr::str_subset(".+")
      vriRas <- lapply(spp, function(sp) {
        ## percent cover, per species, using polygon with highest pixel-area covered
        ## TODO: get area-weighted mean using all polygons in a pixel
        vriSp <- tidyterra::filter(vri, .data[[sppCols[i]]] == sp)

        f_Idx <- tempfile("rast_", fileext = ".tif")
        vriIdx <- exactextractr::rasterize_polygons(
          sf::st_as_sf(vriSp),
          template,
          min_coverage = 0.05
        ) |>
          terra::writeRaster(filename = f_Idx)

        vriRasSp <- terra::deepcopy(vriIdx)

        gc(verbose = FALSE)

        ## replace indices with actual species codes
        idx_vals <- terra::values(vriIdx, mat = FALSE)
        ids <- which(!is.na(idx_vals))

        f_RasSp <- tempfile("rast_", fileext = ".tif")
        vriRasSp[ids] <- vriSp[idx_vals[ids], pctCols[i]][[pctCols[i]]]
        vriRasSp <- terra::writeRaster(vriRasSp, filename = f_RasSp)

        rm(ids, idx_vals)
        unlink(f_Idx)

        return(vriRasSp)
      }) |>
        terra::rast()
      names(vriRas) <- spp

      gc(verbose = FALSE)

      return(vriRas)
    })

    sppLayersList <- lapply(speciesPresent, function(spp) {
      z <- lapply(sppRastersList, function(x) {
        y <- if (spp %in% names(x)) {
          x[[spp]]
        } else {
          template
        }
        names(y) <- spp
        y
      }) |>
        terra::rast() |>
        sum(na.rm = TRUE)
      names(z) <- spp
      gc(verbose = FALSE)

      return(z)
    })
    names(sppLayersList) <- speciesPresent

    terra::rast(sppLayersList)
  })

  terra::mosaic(sbfi2020_tile_names) ## TODO
}
