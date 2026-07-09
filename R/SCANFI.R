## SCANFI v2 layer types: user token -> file-name token
.scanfi_structure <- c(
  biomass = "att_biomass",
  closure = "att_closure",
  height = "att_height",
  landcover = "att_nfiLandcover",
  age = "age_median"
)

.scanfi_species <- c(
  balsamFir = "spsCC_balsamFir",
  blackSpruce = "spsCC_blackSpruce",
  broadleaf = "spsCC_broadleaf",
  douglasFir = "spsCC_douglasFir",
  jackPine = "spsCC_jackPine",
  lodgepolePine = "spsCC_lodgepolePine",
  otherConiferous = "spsCC_otherConiferous",
  ponderosaPine = "spsCC_ponderosaPine",
  tamarack = "spsCC_tamarack",
  whiteRedPine = "spsCC_whiteRedPine"
)

## the northern-extrapolation mask is year-agnostic
.scanfi_mask <- c(mask = "north_extrapol_area")

.scanfi_types <- c(.scanfi_structure, .scanfi_species, .scanfi_mask)

## resolve user `type` tokens (incl. group aliases "all"/"structure"/"species")
## to file-name tokens
.scanfi_resolve_types <- function(type) {
  type <- unique(type)
  if ("all" %in% type) {
    return(unname(.scanfi_types))
  }
  toks <- character(0)
  if ("structure" %in% type) {
    toks <- c(toks, .scanfi_structure)
  }
  if ("species" %in% type) {
    toks <- c(toks, .scanfi_species)
  }
  specific <- setdiff(type, c("structure", "species"))
  bad <- setdiff(specific, names(.scanfi_types))
  if (length(bad) > 0L) {
    stop("unknown SCANFI type(s): ", paste(bad, collapse = ", "))
  }
  unique(unname(c(toks, .scanfi_types[specific])))
}

## list + download the requested SCANFI v2 public layers; returns local file paths.
## Only the requested layers are downloaded (national data is large).
.scanfi_public <- function(tokens, years, dest_dir) {
  base <- .url_scanfi

  ## directory listing -> available GeoTIFFs (the trailing "$" excludes
  ## .tif.aux.xml / .tif.ovr sidecars)
  html <- rawToChar(curl::curl_fetch_memory(paste0(base, "/"))$content)
  avail <- regmatches(html, gregexpr('(?<=href=")[^"]+\\.tif(?=")', html, perl = TRUE))[[1]] |>
    basename() |>
    unique()

  year_tokens <- setdiff(tokens, .scanfi_mask)
  patt <- character(0)
  if (length(year_tokens) > 0L) {
    patt <- c(
      patt,
      sprintf(
        "^SCANFI_(%s)_(%s)_v2",
        paste(year_tokens, collapse = "|"),
        paste(years, collapse = "|")
      )
    )
  }
  if (.scanfi_mask %in% tokens) {
    patt <- c(patt, "^SCANFI_north_extrapol_area\\.tif$")
  }
  keep <- Reduce(`|`, lapply(patt, function(p) grepl(p, avail)))
  files <- avail[keep]
  if (length(files) == 0L) {
    stop("no SCANFI v2 layers matched the requested type(s)/year(s)")
  }

  uf <- file.path(base, files)
  df <- file.path(dest_dir, files)

  ## robust, resumable, parallel download (skips already-complete files on re-run)
  dl <- curl::multi_download(uf, df, resume = TRUE)
  failed <- !dl$success | is.na(dl$status_code) | dl$status_code >= 400L
  if (any(failed)) {
    dl[failed, ] <- curl::multi_download(uf[failed], df[failed], resume = TRUE)
  }

  df
}

## download the private (Google Drive) SCANFI folder, then keep the requested
## layers; returns local file paths
.scanfi_private <- function(tokens, drive_folder, dest_dir) {
  if (!requireNamespace("googledrive", quietly = TRUE)) {
    stop("the 'private' flavour requires the 'googledrive' package (and Drive authentication)")
  }
  workflowtools::drive_download_folder(
    drive_folder = googledrive::as_id(drive_folder),
    path = dest_dir,
    overwrite = TRUE
  )
  files <- list.files(dest_dir, pattern = "[.]tif$", full.names = TRUE, recursive = TRUE)
  keep <- Reduce(`|`, lapply(tokens, function(t) grepl(t, basename(files), fixed = TRUE)))
  files[keep]
}

#' SCANFI data
#'
#' Get and prepare SCANFI v2 (Spatialized Canadian National Forest Inventory)
#' data as a `SpatRaster`. SCANFI provides wall-to-wall 30 m maps of forest
#' structure, composition, biomass, and age for Canada (Guindon et al. 2026;
#' \doi{10.23687/07653869-f303-46c2-a04e-9ab479b73cbf}).
#'
#' @details
#' `type` selects which layers to fetch; it accepts the group aliases `"all"`
#' (default), `"structure"`, and `"species"`, and/or any of the specific tokens
#' below. National data are large, so only the requested layers are downloaded
#' (public flavour) and rasters are read lazily -- when `study_area` is supplied,
#' only that window is read from disk.
#'
#' Structural attributes and age (one layer per requested `years`):
#' - `biomass`: aboveground biomass (t/ha);
#' - `closure`: total crown closure (%);
#' - `height`: forest height (m);
#' - `landcover`: NFI-compatible land cover classification;
#' - `age`: forest stand age (years).
#'
#' Tree-species crown closure (%; `"species"` selects all):
#' - `balsamFir`, `blackSpruce`, `broadleaf`, `douglasFir`, `jackPine`,
#'   `lodgepolePine`, `otherConiferous`, `ponderosaPine`, `tamarack`,
#'   `whiteRedPine`.
#'
#' Other:
#' - `mask`: northern-extrapolation mask (year-agnostic integer mask).
#'
#' Two flavours are available:
#' - `"public"`: the NRCan public v2 product (`r forestData:::.url_scanfi`),
#'   holding the full 1985-2025 time series (5-year steps);
#' - `"private"`: a periodically-updated Google Drive dataset (2000, 2010,
#'   2020), which requires the \pkg{googledrive} package and Drive authentication.
#'
#' @param type character vector of layer types to fetch (see Details).
#'
#' @param years integer year(s) to fetch (v2 spans 1985-2025 in 5-year steps).
#'
#' @param flavour one of `"public"` (default) or `"private"` (see Details).
#'
#' @param dest_dir character, destination directory for downloads
#'                (defaults to a subdirectory of [tempdir()]).
#'
#' @param study_area (optional) `SpatVector` (or `sf`) to which the rasters are
#'                  cropped and masked.
#'
#' @param drive_folder Google Drive folder id for the `"private"` flavour.
#'
#' @return `SpatRaster` (one layer per downloaded SCANFI file).
#'
#' @export
scanfi <- function(
  type = "all",
  years = 2020L,
  flavour = c("public", "private"),
  dest_dir = NULL,
  study_area = NULL,
  drive_folder = "1i7w4tO52Sh45tRwlUiUEnwidOeE5Zq68"
) {
  flavour <- match.arg(flavour)
  tokens <- .scanfi_resolve_types(type)

  if (is.null(dest_dir)) {
    dest_dir <- file.path(tempdir(), "scanfi")
  }
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)

  old <- options(timeout = 3000)
  on.exit(options(old), add = TRUE)

  tifs <- if (flavour == "public") {
    .scanfi_public(tokens, years, dest_dir)
  } else {
    .scanfi_private(tokens, drive_folder, dest_dir)
  }

  r <- terra::rast(tifs)

  if (!is.null(study_area)) {
    r <- .crop_mask(r, study_area)
  }

  r
}
