test_that("rescale works correctly", {
  # rescale a single value
  expect_equal(.rescale(50, 0, 100, 0, 1), 0.5)
  expect_equal(.rescale(50, 0, 100, -1, 1), 0)

  # simple rescaling of numeric vectors
  x <- 0:100

  x1 <- .rescale(x)
  expect_equal(min(x1), 0)
  expect_equal(max(x1), 1)

  x2 <- .rescale(x, new.min = -1, new.max = 1)
  expect_equal(min(x2), -1)
  expect_equal(max(x2), 1)

  # a constant vector is returned unchanged
  expect_equal(.rescale(rep(0, 5)), rep(0, 5))
})

test_that("rescale works on SpatRaster values", {
  r <- terra::rast(nrows = 10, ncols = 10, vals = 0:99)

  r1 <- terra::setValues(r, .rescale(terra::values(r, mat = FALSE)))
  expect_equal(min(terra::values(r1)), 0)
  expect_equal(max(terra::values(r1)), 1)

  r2 <- terra::setValues(r, .rescale(terra::values(r, mat = FALSE), new.min = -1, new.max = 1))
  expect_equal(min(terra::values(r2)), -1)
  expect_equal(max(terra::values(r2)), 1)
})
