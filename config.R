
# configuration variables in one place to make things simpler

library(tools)
library(utils)
library(maptools)
library(raster)
library(rgeos)
library(RMySQL)
require(rgdal)

source('../secure_config.R')

# root directory of where the data is stored (slash at end)
DATA_DIR <- "/Volumes/RepoBack2TB/landsat-data/"
#DATA_DIR <- '/Users/rogerhyam/landsat_data/'
TAR_DIR <- paste( DATA_DIR, 'raw/tars/', sep="")

# download location for bulk metadata at USGS
USGS_METADATA_URL <- "https://landsat.usgs.gov/landsat/metadata_service/bulk_metadata_files/LANDSAT_8_C1.csv.gz"

USGS_API_URL <- "https://espa.cr.usgs.gov/api/v0/"

LATLON_CRS <- CRS("+init=epsg:4326")
#OSG_CRS <- CRS("+init=epsg:27700")
OSG_CRS <- CRS("+init=epsg:27700 +proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +datum=OSGB36 +units=m +no_defs +ellps=airy +towgs84=446.448,-125.157,542.060,0.1502,0.2470,0.8421,-20.4894")








