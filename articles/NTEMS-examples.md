# NTEMS examples

## Download and pre-process NTEMS data for a study area

``` r

## ensure you are working with enough temp scratch storage space!
scratch_path <- ifelse(nzchar(Sys.getenv("SCRATCHDIR")), Sys.getenv("SCRATCHDIR"), tempdir())

## load packages
library(terra)
library(forestData)

## national rasters are large -- set terra to work on disk
terraOptions(
  memfrac = 0.2,
  tempdir = scratch_path
)

## study area: a ~100 km buffer around a point in central Alberta
lcc <- paste(
  "+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95",
  "+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
)
study_area <- terra::vect(cbind(-115, 55), crs = "EPSG:4326") |>
  terra::project(lcc) |>
  terra::buffer(1e5)

## CA_forest_harvest_recovery_rate.zip is smallest of the NTEMS archives (~49 MB).
## Only the study-area window is returned.
post_harvest_rr <- ntems("harvestrecovery", scratch_path, study_area = study_area)

terra::plot(post_harvest_rr)
```
