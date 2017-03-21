
# configuration variables in one place to make things simpler

library(tools)
library(utils)
library(jsonlite)
library(httr)
library(maptools)

# we include another config file with api keys and credentials in
# that is outside the code tree so we don't expose them through github
# it should contain
#  - USGS_USERPWD <- "username:password"

source('../secure_config.R')

# root directory of where the data is stored (no slash at end)
# DATA_DIR <- "/media/repo_disk/landsat-data"
#DATA_DIR <- "/media/landsat-data/data"
DATA_DIR <- "/Volumes/landsat-data"

# download location for bulk metadata at USGS
USGS_METADATA_URL <- "https://landsat.usgs.gov/landsat/metadata_service/bulk_metadata_files/LANDSAT_8.csv.gz"

USGS_API_URL <- "https://espa.cr.usgs.gov/api/v0/"





