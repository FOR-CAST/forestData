test_that("sbfi volume field weights stand volume by species area share", {
  v <- terra::vect("POLYGON ((0 0, 1 0, 1 1, 0 1, 0 0))", crs = "EPSG:3857")
  v$SPECIES_1 <- "POPU.TRE"
  v$SPECIES_1_PERC <- 60
  v$SPECIES_2 <- "PICE.MAR"
  v$SPECIES_2_PERC <- 40
  v$SPECIES_3 <- NA_character_
  v$SPECIES_3_PERC <- NA_real_
  v$SPECIES_4 <- NA_character_
  v$SPECIES_4_PERC <- NA_real_
  v$SPECIES_5 <- NA_character_
  v$SPECIES_5_PERC <- NA_real_
  v$STRUCTURE_VOLUME_AVG <- 200

  ## Populus share = 60% -> 200 * 0.60 = 120
  expect_equal(.sbfi_species_vol_field(v, "POPU.TRE"), 120)

  ## a non-present species contributes nothing
  expect_equal(.sbfi_species_vol_field(v, "FRAX.AME"), 0)

  ## multiple species codes are summed
  v$SPECIES_2 <- "POPU.BAL"
  expect_equal(.sbfi_species_vol_field(v, c("POPU.TRE", "POPU.BAL")), 200)
})
