# SBFI species-weighted gross stem volume

Build a species-group volume raster (m3/ha) from the Satellite-Based
Forest Inventory (SBFI) 2020 geodatabase, as stand volume
(`STRUCTURE_VOLUME_AVG`) multiplied by the summed area share of the
requested species. This mirrors the
[`ntems_species_volume()`](https://for-cast.github.io/forestData/reference/ntems_species_volume.md)
construction, so SBFI and NTEMS volumes are directly comparable (and
share a lineage).

## Usage

``` r
sbfi_species_volume(
  gdb_file,
  species,
  study_area,
  res = 100,
  grid_layer = "_Grid_forested_ecosystem",
  tile_fmt = "CA_2020_tile_%d_metrics",
  filename = NULL
)
```

## Arguments

- gdb_file:

  character, path to the SBFI `.gdb`.

- species:

  character vector of SBFI species codes, e.g.
  `c("POPU.TRE", "POPU.BAL", "POPU.GRA")`.

- study_area:

  `SpatVector` (or `sf`) polygons defining the area of interest.

- res:

  numeric, output resolution (m) in the SBFI native CRS (default 100).

- grid_layer:

  character, the SBFI tile-grid layer name.

- tile_fmt:

  character, [`sprintf()`](https://rdrr.io/r/base/sprintf.html) format
  mapping a grid `Id` to its metrics layer name.

- filename:

  (optional) character, path to write the result to.

## Value

`SpatRaster` of species-weighted stand volume (m3/ha).

## Details

Only the SBFI tiles intersecting `study_area` are read, and only the
species / volume columns are loaded (the national geodatabase is large).
Tiles are rasterized in the SBFI native CRS (no raster reprojection; the
study-area vector is reprojected to the geodatabase CRS) and mosaicked.
Zeros are kept (mapped forest with no target species), so the raster's
non-NA extent doubles as the SBFI coverage mask.
