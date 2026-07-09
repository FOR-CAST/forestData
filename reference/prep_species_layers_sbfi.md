# Prepare species-layer rasters from SBFI data

Build per-species percent-cover `SpatRaster` layers from the
Satellite-Based Forest Inventory (SBFI) 2020 geodatabase for a study
area. Only the SBFI grid tiles intersecting `study_area` are read, and
only the species columns are loaded, since the national geodatabase is
large.

## Usage

``` r
prep_species_layers_sbfi(gdb_file, study_area, raster_to_match)
```

## Arguments

- gdb_file:

  character, path to the SBFI `.gdb`.

- study_area:

  `SpatVector` (or `sf`) polygons defining the area of interest.

- raster_to_match:

  template `SpatRaster` defining the output grid and CRS.

## Value

`SpatRaster` with one percent-cover layer per species.
