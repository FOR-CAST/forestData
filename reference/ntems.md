# NTEMS data

Get and prepare data from NTEMS
(<https://opendata.nfis.org/mapserver/nfis-change_eng.html>).

## Usage

``` r
ntems(type, dest_dir = NULL, study_area = NULL)
```

## Arguments

- type:

  character, specifying which NTEMS product to download and prepare (see
  Details).

- dest_dir:

  character, specifying the destination directory in which to download
  and extract the data (defaults to current working directory).

- study_area:

  (optional) `sf` polygon to which the national raster will be cropped
  and masked.

## Value

`SpatRaster`

## Details

`type` must be one of the following:

- `age`: forest age
  ([doi:10.1016/j.rse.2023.113529](https://doi.org/10.1016/j.rse.2023.113529)
  );

- `d2sc`: distance-to-second-class for tree species
  ([doi:10.1016/j.rse.2022.113276](https://doi.org/10.1016/j.rse.2022.113276)
  );

- `fao`: forest area based on FAO definitions for Canada
  ([doi:10.1093/forestry/cpaa006](https://doi.org/10.1093/forestry/cpaa006)
  );

- `fires`, `harvest`: wildfire or harvest disturbances
  ([doi:10.1080/17538947.2016.1187673](https://doi.org/10.1080/17538947.2016.1187673)
  );

- `firesrecovery`, `harvestrecovery`: post-disturbance forest recovery
  data
  ([doi:10.1016/j.rse.2017.03.035](https://doi.org/10.1016/j.rse.2017.03.035)
  ,
  [doi:10.1016/j.rse.2022.112904](https://doi.org/10.1016/j.rse.2022.112904)
  );

- `firesy2r`, `harvesty2r`: post-disturbance years-to-recovery
  ([doi:10.1016/j.rse.2017.03.035](https://doi.org/10.1016/j.rse.2017.03.035)
  ,
  [doi:10.1016/j.rse.2022.112904](https://doi.org/10.1016/j.rse.2022.112904)
  );

- `landcover<year>`: annual forest landcover 1984-2019
  ([doi:10.1080/07038992.2018.1437719](https://doi.org/10.1080/07038992.2018.1437719)
  ,
  [doi:10.1016/j.rse.2021.112780](https://doi.org/10.1016/j.rse.2021.112780)
  )

- `leadingspecies`: leading tree species
  ([doi:10.1016/j.rse.2022.113276](https://doi.org/10.1016/j.rse.2022.113276)
  );

- `sbfi`: Satellite-Based Forest Inventory
  ([doi:10.1093/forestry/cpad065](https://doi.org/10.1093/forestry/cpad065)
  );

- `speciesprobs`: tree species probabilities
  ([doi:10.1016/j.rse.2022.113276](https://doi.org/10.1016/j.rse.2022.113276)
  );

- `wildfirednbr`: wildfire differenced Normalized Burn Ratio
  ([doi:10.1016/j.rse.2014.11.005](https://doi.org/10.1016/j.rse.2014.11.005)
  ;
  [doi:10.1016/j.rse.2015.09.004](https://doi.org/10.1016/j.rse.2015.09.004)
  );

## Note

Currently only supports the most recent data (made available 2019 or
later). Previous NTEMS products (e.g., 2015 forest data) can be
downloaded from the NTEMS site linked above.
