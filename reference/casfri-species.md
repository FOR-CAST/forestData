# CASFRI species cover data

Extract spatial locations (polygons) and forest species layer
attributes, and create percent cover rasters for each species in an
optionally provided study area.

## Usage

``` r
casfri_species_cover(x, study_area = NULL)

casfri_species_cover.list(x, study_area = NULL)

casfri_species_cover.PqConnection(x, study_area = NULL)

casfri_species_layers(x, raster_to_match)
```

## Arguments

- x:

  `SpatVector` produced via `casfri_species_cover()` (an `sf` object or
  a source readable by
  [`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html)
  is also accepted).

- study_area:

  (optional) `SpatVector` (or `sf`) polygons identifying the study area
  boundaries, used to extract a subset of the species cover data
  (spatial intersection).

- raster_to_match:

  template `SpatRaster` defining the output grid and CRS.

## Value

A `SpatVector` of CASFRI polygons with the joined species/percent-cover
attributes.

A `SpatRaster` with one percent-cover layer (0-100) per species.

## Details

If `x` is a list, it must be a named list with elements corresponding to
each of the CAS tables (e.g., `.csv` files) and a geodatabase file
(`.gdb`):

- `HDR`: header attributes;

- `CAS`: CAS base polygon attributes;

- `LYR`: forest-level attributes;

- `NFL`: non-forest land attributes;

- `DST`: disturbance history attributes;

- `ECO`: ecological specific attributes;

- `GEO`: geometry attributes.

See
<https://github.com/CASFRI/CASFRI/tree/master/documentation/specifications#common-attribute-schema>
for full details.
