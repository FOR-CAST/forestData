#' NTEMS species-weighted gross stem volume
#'
#' Derive a species-group volume raster (m3/ha) from two NTEMS products: gross
#' stem volume (2022) multiplied by the summed per-species likelihood share of
#' the canopy (2019). No post-2014 product distributes species-specific volume
#' directly, so this reconstructs it as `volume * (sum of species likelihoods) /
#' 100`.
#'
#' @details
#' Only the requested species layers are extracted from the ~21 GB species
#' probabilities archive (via [workflowtools::archive_extract_once], which falls
#' back to the system `unzip` for `ZIP64`), and rasters are read lazily; when
#' `study_area` is supplied only that window is read. Rasters are never
#' reprojected -- the study-area vector is reprojected to the raster CRS.
#'
#' @param species character vector of NTEMS species codes whose likelihoods are
#'   summed, e.g. `c("POPU.TRE", "POPU.BAL", "POPU.GRA")` for *Populus*.
#'
#' @param study_area (optional) `SpatVector` (or `sf`) to crop and mask to.
#'
#' @param dest_dir character, destination directory for downloads
#'                (defaults to a subdirectory of [tempdir()]).
#'
#' @param spp_year integer, the species-probabilities epoch (default 2019).
#'
#' @return `SpatRaster` of species-weighted gross stem volume (m3/ha).
#'
#' @export
ntems_species_volume <- function(species, study_area = NULL, dest_dir = NULL, spp_year = 2019L) {
  if (is.null(dest_dir)) {
    dest_dir <- file.path(tempdir(), "ntems")
  }
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  old <- options(timeout = max(6 * 60 * 60, getOption("timeout")))
  on.exit(options(old), add = TRUE)

  ## download the volume + species-probability archives
  vol_zip_name <- .ntems_archives[[.ntems_types[["volume"]]]]
  spp_zip_name <- .ntems_archives[[.ntems_types[["speciesprobs"]]]]
  vol_zip <- file.path(dest_dir, vol_zip_name)
  spp_zip <- file.path(dest_dir, spp_zip_name)
  workflowtools::download_once(paste0(.url_ntems, vol_zip_name), vol_zip, mode = "wb")
  workflowtools::download_once(paste0(.url_ntems, spp_zip_name), spp_zip, mode = "wb")

  ## extract only the layers needed (workflowtools falls back to unzip for ZIP64)
  vol_tif <- sub("\\.zip$", ".tif", vol_zip_name)
  spp_tifs <- sprintf("CA_forest_%s_%d.tif", species, spp_year)
  workflowtools::archive_extract_once(vol_zip, dir = dest_dir, files = vol_tif)
  workflowtools::archive_extract_once(spp_zip, dir = dest_dir, files = spp_tifs)

  vol <- terra::rast(file.path(dest_dir, vol_tif))
  ## species share of canopy (0-100): sum of the per-species likelihood layers.
  ## na.rm = TRUE because a species is left NA where not regionally eligible;
  ## treat those as 0, not NA.
  share <- terra::rast(file.path(dest_dir, spp_tifs)) |> sum(na.rm = TRUE)
  if (!terra::compareGeom(vol, share, stopOnError = FALSE)) {
    share <- terra::resample(share, vol, method = "near")
  }

  if (!is.null(study_area)) {
    vol <- .crop_mask(vol, study_area)
    share <- .crop_mask(share, study_area)
  }

  out <- vol * (share / 100)
  names(out) <- "volume"
  out
}

#' SBFI species-weighted gross stem volume
#'
#' Build a species-group volume raster (m3/ha) from the Satellite-Based Forest
#' Inventory (SBFI) 2020 geodatabase, as stand volume (`STRUCTURE_VOLUME_AVG`)
#' multiplied by the summed area share of the requested species. This mirrors the
#' [ntems_species_volume()] construction, so SBFI and NTEMS volumes are directly
#' comparable (and share a lineage).
#'
#' @details
#' Only the SBFI tiles intersecting `study_area` are read, and only the species /
#' volume columns are loaded (the national geodatabase is large). Tiles are
#' rasterized in the SBFI native CRS (no raster reprojection; the study-area
#' vector is reprojected to the geodatabase CRS) and mosaicked. Zeros are kept
#' (mapped forest with no target species), so the raster's non-NA extent doubles
#' as the SBFI coverage mask.
#'
#' @param gdb_file character, path to the SBFI `.gdb`.
#' @param species character vector of SBFI species codes, e.g.
#'   `c("POPU.TRE", "POPU.BAL", "POPU.GRA")`.
#' @param study_area `SpatVector` (or `sf`) polygons defining the area of interest.
#' @param res numeric, output resolution (m) in the SBFI native CRS (default 100).
#' @param grid_layer character, the SBFI tile-grid layer name.
#' @param tile_fmt character, [sprintf()] format mapping a grid `Id` to its
#'   metrics layer name.
#' @param filename (optional) character, path to write the result to.
#'
#' @return `SpatRaster` of species-weighted stand volume (m3/ha).
#'
#' @export
sbfi_species_volume <- function(
  gdb_file,
  species,
  study_area,
  res = 100,
  grid_layer = "_Grid_forested_ecosystem",
  tile_fmt = "CA_2020_tile_%d_metrics",
  filename = NULL
) {
  if (!inherits(study_area, "SpatVector")) {
    study_area <- terra::vect(study_area)
  }

  grid <- terra::vect(gdb_file, layer = grid_layer)
  aoi <- terra::project(study_area, terra::crs(grid))
  ## a tile is kept if it intersects ANY AOI feature (so multi-part AOIs select
  ## all their tiles)
  ids <- sort(grid[rowSums(terra::relate(grid, aoi, "intersects")) > 0, ]$Id)
  if (length(ids) == 0L) {
    stop("study_area does not intersect any SBFI tiles")
  }

  cols <- c(sprintf("SPECIES_%d", 1:5), sprintf("SPECIES_%d_PERC", 1:5), "STRUCTURE_VOLUME_AVG")
  template <- terra::rast(terra::ext(aoi), resolution = res, crs = terra::crs(grid))

  parts <- lapply(ids, function(id) {
    lyr <- sprintf(tile_fmt, id)
    v <- terra::vect(
      gdb_file,
      layer = lyr,
      query = sprintf("SELECT %s FROM \"%s\"", paste(cols, collapse = ", "), lyr)
    )
    v$volume <- .sbfi_species_vol_field(v, species)
    terra::rasterize(v, terra::crop(template, terra::ext(v)), field = "volume")
  })

  out <- if (length(parts) == 1L) {
    parts[[1]]
  } else {
    terra::mosaic(terra::sprc(parts), fun = "mean")
  }
  out <- terra::mask(out, aoi)
  names(out) <- "volume"

  if (!is.null(filename)) {
    out <- terra::writeRaster(
      out,
      filename,
      overwrite = TRUE,
      gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES")
    )
  }
  out
}

## per-polygon species-weighted volume: STRUCTURE_VOLUME_AVG * (summed species
## area share / 100) over the SPECIES_1..5 / SPECIES_1..5_PERC columns
.sbfi_species_vol_field <- function(v, species) {
  d <- as.data.frame(v)
  fr <- numeric(nrow(d))
  for (i in 1:5) {
    sp <- d[[paste0("SPECIES_", i)]]
    pc <- suppressWarnings(as.numeric(d[[paste0("SPECIES_", i, "_PERC")]]))
    fr <- fr + ifelse(!is.na(sp) & sp %in% species & !is.na(pc), pc, 0)
  }
  d[["STRUCTURE_VOLUME_AVG"]] * fr / 100
}
