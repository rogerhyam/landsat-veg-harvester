# Sampling NDVI Buffers around postcode centroids

# nice tutorial on raster package here
# https://geoscripting-wur.github.io/IntroToRaster/
# https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf

# hardcode this for now

DATA_DIR <- '/Volumes/RepoBack2TB/landsat-data/'
TAR_DIR <- paste( DATA_DIR, 'raw/tars/', sep="")

product_id <- 'LC08_L1TP_206021_20140418_20170423_01_T1';


# let's get the files we are interested in into a tempdir
tar_file_path <- paste( TAR_DIR, product_id, '.tar.gz', sep="")
ndvi_file_name <- paste(product_id, '_sr_ndvi.tif', sep = "")
ndvi_file_path <- paste(tempdir(), ndvi_file_name, sep = "/")
qa_file_name <- paste(product_id, '_pixel_qa.tif', sep = "")
qa_file_path <- paste(tempdir(), qa_file_name, sep = "/")
untar(tar_file_path, files = c(ndvi_file_name, qa_file_name), exdir = tempdir(), compressed = "gzip")

# load them into raster layers
ndvi_raster = raster(ndvi_file_path)
qa_raster = raster(qa_file_path)

# quick look see what they are like
#plot(ndvi_raster)

cloud2NA <- function(x, y){
  #veg[cl > 750] <- NA
  # 110100 - remove cloud, snow, water
  x[bitwAnd(y, 52) > 1] <- NA
  return(x)
}

ndvi_cloudless_raster <- overlay(x = ndvi_raster, y = qa_raster, fun = cloud2NA)

plot(ndvi_cloudless_raster)

