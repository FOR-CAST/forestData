#' Prepare species-layer rasters from SBFI data
#'
#' Build per-species percent-cover `SpatRaster` layers from the Satellite-Based
#' Forest Inventory (SBFI) 2020 geodatabase for a study area. Only the SBFI grid
#' tiles intersecting `study_area` are read, and only the species columns are
#' loaded, since the national geodatabase is large.
#'
#' @param gdb_file character, path to the SBFI `.gdb`.
#' @param study_area `SpatVector` (or `sf`) polygons defining the area of interest.
#' @param raster_to_match template `SpatRaster` defining the output grid and CRS.
#'
#' @return `SpatRaster` with one percent-cover layer per species.
#'
#' @export
prep_species_layers_sbfi <- function(gdb_file, study_area, raster_to_match) {
  if (!inherits(raster_to_match, "SpatRaster")) {
    raster_to_match <- terra::rast(raster_to_match)
  }
  if (!inherits(study_area, "SpatVector")) {
    study_area <- terra::vect(study_area)
  }

  ## SBFI grid of forested-ecosystem tiles; spatially prefilter to the study area
  ## so only the intersecting tiles are read (never the whole national gdb)
  grid <- terra::vect(gdb_file, layer = "_Grid_forested_ecosystem")
  aoi <- terra::project(study_area, terra::crs(grid))
  tile_ids <- grid[aoi, ]$Id

  if (length(tile_ids) == 0L) {
    stop("study_area does not intersect any SBFI tiles")
  }

  spp_cols <- sprintf("SPECIES_%d", 1:5)
  pct_cols <- sprintf("SPECIES_%d_PERC", 1:5)

  tile_rasters <- lapply(tile_ids, function(id) {
    lyr <- sprintf("CA_2020_tile_%s_metrics", id)
    ## read only the species columns for this tile
    v <- terra::vect(
      gdb_file,
      layer = lyr,
      query = sprintf("SELECT %s FROM \"%s\"", paste(c(spp_cols, pct_cols), collapse = ", "), lyr)
    )
    .species_pct_layers(v, spp_cols, pct_cols, raster_to_match)
  })

  if (length(tile_rasters) == 1L) {
    return(tile_rasters[[1]])
  }

  ## mosaic each species across the tiles that contain it (tiles may hold
  ## different species sets)
  all_species <- sort(unique(unlist(lapply(tile_rasters, names))))
  layers <- lapply(all_species, function(sp) {
    with_sp <- Filter(
      Negate(is.null),
      lapply(tile_rasters, function(r) if (sp %in% names(r)) r[[sp]] else NULL)
    )
    m <- if (length(with_sp) == 1L) {
      with_sp[[1]]
    } else {
      terra::mosaic(terra::sprc(with_sp), fun = "max")
    }
    names(m) <- sp
    m
  })

  terra::rast(layers)
}
