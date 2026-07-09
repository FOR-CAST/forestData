# National eco-boundaries

Prepare boundaries based on Canadian national ecodistricts, -regions,
-provinces, or -zones.

## Usage

``` r
.ecoboundaries(
  type = NULL,
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
)

ecodistricts(
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
)

ecoregions(
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
)

ecoprovinces(
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
)

ecozones(
  destination_path = tempdir(),
  study_area = NULL,
  raster_to_match = NULL
)
```

## Arguments

- type:

  character. The polygon type to use: Must be one of "ECODISTRICT",
  "ECOREGION", "ECOPROVINCE", or "ECOZONE".

- destination_path:

  character. Path to directory where data will be downloaded.

- study_area:

  (optional) `SpatVector` (or `sf`) polygons defining the study area of
  interest. When supplied, the boundaries are cropped, masked, and
  reprojected to it (via
  [`spatialutils::prep_vector()`](https://rdrr.io/pkg/spatialutils/man/prep_vector.html)).

- raster_to_match:

  (optional) template `SpatRaster`; when supplied, the returned vector
  is reprojected to its CRS.

## Value

A `SpatVector` of the requested eco-boundary polygons.

## Examples

``` r
# \donttest{
## study area: a ~100 km buffer around a point in central Alberta
lcc <- paste(
  "+proj=lcc +lat_1=49 +lat_2=77 +lat_0=0 +lon_0=-95",
  "+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
)
study_area <- terra::vect(cbind(-115, 55), crs = "EPSG:4326") |>
  terra::project(lcc) |>
  terra::buffer(1e5)

ezs <- ecozones(study_area = study_area)
terra::plot(ezs, "ZONE_NAME", main = "ecozones in study area")

# }
```
