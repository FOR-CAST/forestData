# forestData 0.1.0

## Breaking changes

* Exported functions and their arguments now use snake_case: `casfriSpeciesLayers()` is now
  `casfri_species_layers()`, and `prepSpeciesLayers_SBFI()` is now `prep_species_layers_sbfi()`;
  arguments `studyArea`, `rasterToMatch`, `destDir`, and `destinationPath` are now `study_area`,
  `raster_to_match`, `dest_dir`, and `destination_path`.
* `casfri_species_layers()` now returns a `SpatRaster` (previously a `RasterStack`).
* `ecodistricts()`, `ecoprovinces()`, `ecoregions()`, and `ecozones()` now return a `SpatVector`
  (previously `sf`).

## Improvements

* `scanfi()` returns a `SpatRaster` from SCANFI v2, with a `type` argument to select layers and a
  `flavour` argument for the public (NRCan) or private (Google Drive) source.
* Data are downloaded and prepared with `workflowtools` and `spatialutils` instead of `reproducible`;
  national data are read lazily / prefiltered to the study area rather than loaded whole.
* Dataset source URLs are centralized in `R/urls.R`.
* Minimum R version is now 4.4.

## Dependencies

* remove `raster`, `reproducible`, `SpaDES.tools`, `sp`, `archive`, `httr2`, `RCurl`, `XML`, `dplyr`,
  `glue`, `stringr`, `tidyterra`, and `stats`;
* add `curl`, `spatialutils`, and `workflowtools`.

# forestData 0.0.2

* drop support for R 4.1;
* improved NTEMS data workflows and added more datasets (#3);

# forestData 0.0.1

* initial version
