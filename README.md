# forestData

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/FOR-CAST/forestData/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/FOR-CAST/forestData/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of `forestData` is to simplify importing of Canadian forestry data, including:

- National Ecosystem Framework for Canada (<https://sis.agr.gc.ca/cansis/nsdb/ecostrat/gis_data.html>);
- Common Attribute Schema for Forest Resource Inventories (CASFRI; <https://casfri.github.io/CASFRI/>);
- National Terrestrial Ecosystem Monitoring System (NTEMS, <https://opendata.nfis.org/mapserver/nfis-change_eng.html>);
- Satellite-Based Forest Inventory (SBFI) and the Spatialized Canadian National Forest Inventory (SCANFI).

## Installation

You can install the development version of `forestData` from
[GitHub](https://github.com/FOR-CAST/forestData) with:

``` r
# install.packages("pak")
pak::pak("FOR-CAST/forestData")
```

`pak` reads the `Remotes:` field, so the GitHub-only dependencies (`spatialutils`,
`workflowtools`) are installed automatically.

## Examples

See the `CASFRI-examples` and `NTEMS-examples` vignettes.
