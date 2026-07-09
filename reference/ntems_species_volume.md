# NTEMS species-weighted gross stem volume

Derive a species-group volume raster (m3/ha) from two NTEMS products:
gross stem volume (2022) multiplied by the summed per-species likelihood
share of the canopy (2019). No post-2014 product distributes
species-specific volume directly, so this reconstructs it as
`volume * (sum of species likelihoods) / 100`.

## Usage

``` r
ntems_species_volume(
  species,
  study_area = NULL,
  dest_dir = NULL,
  spp_year = 2019L
)
```

## Arguments

- species:

  character vector of NTEMS species codes whose likelihoods are summed,
  e.g. `c("POPU.TRE", "POPU.BAL", "POPU.GRA")` for *Populus*.

- study_area:

  (optional) `SpatVector` (or `sf`) to crop and mask to.

- dest_dir:

  character, destination directory for downloads (defaults to a
  subdirectory of [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- spp_year:

  integer, the species-probabilities epoch (default 2019).

## Value

`SpatRaster` of species-weighted gross stem volume (m3/ha).

## Details

Only the requested species layers are extracted from the ~21 GB species
probabilities archive (via
[workflowtools::archive_extract_once](https://rdrr.io/pkg/workflowtools/man/archive_extract_once.html),
which falls back to the system `unzip` for `ZIP64`), and rasters are
read lazily; when `study_area` is supplied only that window is read.
Rasters are never reprojected – the study-area vector is reprojected to
the raster CRS.
