# SCANFI data

Get and prepare SCANFI v2 (Spatialized Canadian National Forest
Inventory) data as a `SpatRaster`. SCANFI provides wall-to-wall 30 m
maps of forest structure, composition, biomass, and age for Canada
(Guindon et al. 2026;
[doi:10.23687/07653869-f303-46c2-a04e-9ab479b73cbf](https://doi.org/10.23687/07653869-f303-46c2-a04e-9ab479b73cbf)
).

## Usage

``` r
scanfi(
  type = "all",
  years = 2020L,
  flavour = c("public", "private"),
  dest_dir = NULL,
  study_area = NULL,
  drive_folder = "1i7w4tO52Sh45tRwlUiUEnwidOeE5Zq68"
)
```

## Arguments

- type:

  character vector of layer types to fetch (see Details).

- years:

  integer year(s) to fetch (v2 spans 1985-2025 in 5-year steps).

- flavour:

  one of `"public"` (default) or `"private"` (see Details).

- dest_dir:

  character, destination directory for downloads (defaults to a
  subdirectory of [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- study_area:

  (optional) `SpatVector` (or `sf`) to which the rasters are cropped and
  masked.

- drive_folder:

  Google Drive folder id for the `"private"` flavour.

## Value

`SpatRaster` (one layer per downloaded SCANFI file).

## Details

`type` selects which layers to fetch; it accepts the group aliases
`"all"` (default), `"structure"`, and `"species"`, and/or any of the
specific tokens below. National data are large, so only the requested
layers are downloaded (public flavour) and rasters are read lazily –
when `study_area` is supplied, only that window is read from disk.

Structural attributes and age (one layer per requested `years`):

- `biomass`: aboveground biomass (t/ha);

- `closure`: total crown closure (%);

- `height`: forest height (m);

- `landcover`: NFI-compatible land cover classification;

- `age`: forest stand age (years).

Tree-species crown closure (%; `"species"` selects all):

- `balsamFir`, `blackSpruce`, `broadleaf`, `douglasFir`, `jackPine`,
  `lodgepolePine`, `otherConiferous`, `ponderosaPine`, `tamarack`,
  `whiteRedPine`.

Other:

- `mask`: northern-extrapolation mask (year-agnostic integer mask).

Two flavours are available:

- `"public"`: the NRCan public v2 product
  (https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/SCANFI/v2),
  holding the full 1985-2025 time series (5-year steps);

- `"private"`: a periodically-updated Google Drive dataset (2000, 2010,
  2020), which requires the googledrive package and Drive
  authentication.
