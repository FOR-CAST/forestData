## ---------------------------------------------------------------------------
## Dataset source URLs -- the single place to find and update source locations.
## Referenced from the fetch functions and, via inline `r` in roxygen, from the
## help pages, so a moved source is changed in exactly one place.
## ---------------------------------------------------------------------------

## NTEMS / NFIS forest-change products (base; archive file names are appended)
.url_ntems <- "https://opendata.nfis.org/downloads/forest_change/"

## SCANFI v2 (NRCan public FTP-over-HTTPS)
.url_scanfi <- "https://ftp.maps.canada.ca/pub/nrcan_rncan/Forests_Foret/SCANFI/v2"

## National ecological framework boundaries (AAFC / CanSIS)
.url_ecoboundaries <- c(
  ecodistrict = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/district/ecodistrict_shp.zip",
  ecoregion = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/region/ecoregion_shp.zip",
  ecoprovince = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/province/ecoprovince_shp.zip",
  ecozone = "https://sis.agr.gc.ca/cansis/nsdb/ecostrat/zone/ecozone_shp.zip"
)
