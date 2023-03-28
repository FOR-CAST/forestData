test_that("rescale works correctly", {
  # rescale a single value
  expect_equal(.rescale(50, 0, 100, 0, 1), 0.5)
  expect_equal(.rescale(50, 0, 100, -1, 1), 0)

  # simple rescaling of numeric vectors
  x <- 0:100

  x1 <- .rescale(x)
  expect_lt(min(x1), max(x1))
  expect_equal(min(x1), 0)
  expect_equal(max(x1), 1)

  x2 <- .rescale(x, new.min = -1, new.max = 1)
  expect_lt(min(x2), max(x2))
  expect_equal(min(x2), -1)
  expect_equal(max(x2), 1)

  ## rescaling values of a raster
  f <- system.file("external/test.grd", package = "raster")
  r <- raster::raster(f)

  r1 <- raster::getValues(r) |>
    .rescale() |>
    raster::setValues(r, values = _)
  expect_lt(raster::minValue(r1), raster::maxValue(r1))
  expect_equal(raster::minValue(r1), 0)
  expect_equal(raster::maxValue(r1), 1)

  r2 <- raster::getValues(r) |>
    .rescale(new.min = -1, new.max = 1) |>
    raster::setValues(r, values = _)
  expect_lt(raster::minValue(r2), raster::maxValue(r2))
  expect_equal(raster::minValue(r2), -1)
  expect_equal(raster::maxValue(r2), 1)

  r[] <- 0
  r3 <- raster::getValues(r) |>
    .rescale() |>
    raster::setValues(r, values = _)
  expect_equal(r, r3)
})
