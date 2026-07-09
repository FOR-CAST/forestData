test_that("scanfi type resolver expands aliases and specific tokens", {
  expect_setequal(
    .scanfi_resolve_types("all"),
    unname(c(.scanfi_structure, .scanfi_species, .scanfi_mask))
  )
  expect_setequal(.scanfi_resolve_types("species"), unname(.scanfi_species))
  expect_setequal(.scanfi_resolve_types("structure"), unname(.scanfi_structure))
  expect_setequal(
    .scanfi_resolve_types(c("biomass", "blackSpruce")),
    c("att_biomass", "spsCC_blackSpruce")
  )
})

test_that("scanfi type resolver errors on unknown type", {
  expect_snapshot(.scanfi_resolve_types("nonsense"), error = TRUE)
})
