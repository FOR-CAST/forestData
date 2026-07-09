test_that("NTEMS type and url lookups work", {
  types <- unname(unlist(.ntems_types))
  zips <- names(.ntems_archives)

  expect_identical(length(types), length(zips))
  expect_in(types, zips)
  expect_in(zips, types)
})

test_that("NTEMS download function works", {
  ## datasets are large; don't hammer download servers from concurrent CI workers or on CRAN
  skip_on_ci()
  skip_on_cran()
  skip_if_offline()
  ## CA_forest_harvest_recovery_rate.zip is smallest of the set (~49 MB)
  postharvestrr <- ntems("harvestrecovery", tempdir())

  expect_s4_class(postharvestrr, "SpatRaster")
  unlink(terra::sources(postharvestrr))
})
