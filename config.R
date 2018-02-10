
# configuration variables in one place to make things simpler

library(tools)
library(utils)
library(jsonlite)
library(httr)
library(maptools)
library(raster)
library(rgeos)

source('../secure_config.R')

# root directory of where the data is stored (no slash at end)
DATA_DIR <- "/Volumes/RepoBack2TB/landsat-data"

# download location for bulk metadata at USGS
USGS_METADATA_URL <- "https://landsat.usgs.gov/landsat/metadata_service/bulk_metadata_files/LANDSAT_8_C1.csv.gz"

USGS_API_URL <- "https://espa.cr.usgs.gov/api/v0/"





