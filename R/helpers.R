#' @keywords internal
.rescale <- function(
  x,
  x.min = min(x, na.rm = TRUE),
  x.max = max(x, na.rm = TRUE),
  new.min = 0,
  new.max = 1
) {
  if (isTRUE(all.equal(x.min, x.max))) {
    return(x)
  } else {
    return(new.min + (x - x.min) * ((new.max - new.min) / (x.max - x.min)))
  }
}

## Crop and mask a raster to a study area. The (small) study-area vector is
## reprojected into the raster's CRS -- the raster is never reprojected.
.crop_mask <- function(x, study_area) {
  if (!inherits(study_area, "SpatVector")) {
    study_area <- terra::vect(study_area)
  }
  study_area <- terra::project(study_area, terra::crs(x))
  terra::mask(terra::crop(x, study_area), study_area)
}

## Build per-species percent-cover raster layers from a polygon `SpatVector` that
## has paired species-name / species-percent columns (e.g. CASFRI LYR or SBFI
## tiles). For each pixel the percent cover is taken from the polygon with the
## highest pixel-area coverage. The `template`'s CRS is authoritative -- the
## vector is reprojected to it, never the raster. Returns a `SpatRaster` with one
## layer per unique species, rescaled to 0-100.
.species_pct_layers <- function(v, spp_cols, pct_cols, template) {
  v <- terra::project(v, terra::crs(template))
  template <- terra::deepcopy(template) * 0.0
  att <- terra::values(v)

  species_present <- unlist(att[spp_cols], use.names = FALSE) |> trimws()
  species_present <- sort(unique(species_present[
    !is.na(species_present) & nzchar(species_present)
  ]))

  per_col <- lapply(seq_along(spp_cols), function(i) {
    sp_i <- trimws(att[[spp_cols[i]]])
    keep <- !is.na(sp_i) & nzchar(sp_i)
    if (!any(keep)) {
      return(NULL)
    }
    vi <- v[keep, ]
    sp_vec <- sp_i[keep]
    pct_vec <- att[[pct_cols[i]]][keep]
    spp <- sort(unique(sp_vec))

    ras <- lapply(spp, function(sp) {
      sel <- sp_vec == sp
      ## polygon index per pixel (highest pixel-area coverage)
      idx_ras <- exactextractr::rasterize_polygons(
        sf::st_as_sf(vi[sel, ]),
        template,
        min_coverage = 0
      )
      out <- terra::deepcopy(idx_ras)
      idx <- terra::values(idx_ras, mat = FALSE)
      ids <- which(!is.na(idx))
      ## replace polygon indices with that polygon's percent cover
      out[ids] <- pct_vec[sel][idx[ids]]
      out
    }) |>
      terra::rast()
    names(ras) <- spp
    ras
  })
  per_col <- per_col[!vapply(per_col, is.null, logical(1))]

  layers <- lapply(species_present, function(sp) {
    z <- lapply(per_col, function(r) {
      y <- if (sp %in% names(r)) r[[sp]] else template
      names(y) <- sp
      y
    }) |>
      terra::rast() |>
      sum(na.rm = TRUE)
    ## rescale to 0-100 percent cover
    terra::values(z) <- .rescale(
      terra::values(z, mat = FALSE),
      x.min = 0,
      new.min = 0,
      new.max = 100
    )
    names(z) <- sp
    z
  })

  terra::rast(layers)
}
