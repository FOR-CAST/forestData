test_that("casfri_species_layers builds one percent-cover layer per species", {
  template <- terra::rast(
    xmin = 0,
    xmax = 10,
    ymin = 0,
    ymax = 10,
    nrows = 10,
    ncols = 10,
    crs = "EPSG:3857",
    vals = 0
  )

  mk <- function(xmin, xmax, sp, pct) {
    p <- terra::vect(
      sprintf("POLYGON ((%g 0, %g 0, %g 10, %g 10, %g 0))", xmin, xmax, xmax, xmin, xmin),
      crs = "EPSG:3857"
    )
    p$species_1 <- sp
    p$species_per_1 <- pct
    p
  }
  v <- rbind(mk(0, 5, "PICE_MAR", 80), mk(5, 10, "POPU_TRE", 60))

  layers <- casfri_species_layers(v, template)

  expect_s4_class(layers, "SpatRaster")
  expect_setequal(names(layers), c("PICE_MAR", "POPU_TRE"))
  expect_lte(max(terra::values(layers), na.rm = TRUE), 100)
  expect_gte(min(terra::values(layers), na.rm = TRUE), 0)
})
