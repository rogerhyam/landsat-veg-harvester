# Sampling NDVI Buffers around postcode centroids

# nice tutorial on raster package here
# https://geoscripting-wur.github.io/IntroToRaster/
# https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf
# http://www.maths.lancs.ac.uk/~rowlings/Teaching/UseR2012/cheatsheet.html


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

# projecting to and from osg
# bng = '+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs'
# crs_os <- CRS("+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs")
# latlong = "+init=epsg:4326"
# ukgrid = "+init=epsg:27700"

# EH9 1HB	EH9	EH9 1	19730800000000		325514	672062	55.9359	-3.192476030000000	N	S12000036	S14000024	S17000012	S16000108	S13002928	S08000024	S08000010	5	S37000012	S00104738	S00014577	6229BM13B	S01008616	S01002002	S02001613	S02000374	32	85	32	87	31	58	6921	S30000008	S31000277	UKM2	UKM25	S19000855	173001	212	S20000682	173	S35000287	S09000002	0	29	29		S12000036			S11000003	S22000059	1	1	Y

# take some coordinates (my home in OSG)
coords = cbind(325514, 672062)

# turn it into a spatial object of points
postcode.point <- SpatialPoints(coords)
proj4string(my.points, CRS("+init=epsg:27700"))

# Create a buffer of different sizes for each one
postcode.buffer100 <- gBuffer( postcode.point, width=100, byid=TRUE)
postcode.buffer250 <- gBuffer( postcode.point, width=250, byid=TRUE)
postcode.buffer500 <- gBuffer( postcode.point, width=500, byid=TRUE)

# Project the raster to OSG as well
ndvi_raster_osg <- spTransform(ndvi_cloudless_raster, CRS("+init=epsg:27700"))



# we are working in lonlat WGS84
# postcode.point <- spTransform(postcode.point, CRS("+init=epsg:4326"))






# plot(ndvi_cloudless_raster)

