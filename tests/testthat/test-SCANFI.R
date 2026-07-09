test_that("SCANFI url lookups work", {
  types <- unname(unlist(.ntemsTypes))
  zips <- names(.ntemsArchives)

  expect_identical(length(types), length(zips))
  expect_in(types, zips)
  expect_in(zips, types)
})

test_that("SCANFI download function works", {
  ## CA_forest_harvest_recovery_rate.zip is smallest of the set (~49 MB)
  postharvestrr <- ntems("harvestrecovery", tempdir())

  unlink(terra::sources(postharvestrr))
})
