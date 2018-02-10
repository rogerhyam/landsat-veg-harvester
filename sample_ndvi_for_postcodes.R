# Sampling NDVI Buffers around postcode centroids

# nice tutorial on raster package here
# https://geoscripting-wur.github.io/IntroToRaster/
# https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf
# http://www.maths.lancs.ac.uk/~rowlings/Teaching/UseR2012/cheatsheet.html


# hardcode this for now

# DATA_DIR <- '/Volumes/RepoBack2TB/landsat-data/'
DATA_DIR <- '/Users/rogerhyam/landsat_data/'

TAR_DIR <- paste( DATA_DIR, 'raw/tars/', sep="")

# product_id <- 'LC08_L1TP_206021_20140418_20170423_01_T1';
product_id <- 'LC08_L1TP_204021_20140911_20170419_01_T1';

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

# Project the raster to OSG as we can then work in meters
# Do NOT do this it is very expensive.
# ndvi_raster_osg <- projectRaster(ndvi_cloudless_raster, crs = CRS("+init=epsg:27700"))

# projecting to and from osg
# bng = '+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs'
# crs_os <- CRS("+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs")
# latlong = "+init=epsg:4326"
# ukgrid = "+init=epsg:27700"

# EH9 1HB	EH9	EH9 1	19730800000000		325514	672062	55.9359	-3.192476030000000	N	S12000036	S14000024	S17000012	S16000108	S13002928	S08000024	S08000010	5	S37000012	S00104738	S00014577	6229BM13B	S01008616	S01002002	S02001613	S02000374	32	85	32	87	31	58	6921	S30000008	S31000277	UKM2	UKM25	S19000855	173001	212	S20000682	173	S35000287	S09000002	0	29	29		S12000036			S11000003	S22000059	1	1	Y
# EH4 5LR	EH4	EH4 5	19730800000000		320761	676132	55.9717	-3.269744670000000	N	S12000036	S14000026	S17000012	S16000109	S13002919	S08000024	S08000010	5	S37000012	S00103791	S00013726	6229AS10B	S01008939	S01002299	S02001672	S02000417	5	9	5	10	5	11	5856	S30000008	S31000235	UKM2	UKM25	S19000855	173001	212	S20000682	173	S35000287	S09000002	0	29	29		S12000036			S11000003	S22000059	1	1	Y
# EH33 2EQ	EH33	EH33 2	19730800000000		340639	672659	55.9433	-2.950507470000000	N	S12000010	S14000020	S17000015	S16000102	S13002910	S08000024	S08000010	5	S37000010	S00102508	S00012525	6228AJ10A	S01008226	S01001587	S02001544	S02000291	6	11	0	0	1	2	1473	S30000005	S31000165	UKM2	UKM23	S19001238	209001	574	S20000991	209	S35000826	S09000002	0	28	28		S12000010	S05000010	S06000052	S11000003	S22000059	2	2	Y

# DG16 5EA	DG16	DG16 5	19931200000000		332174	568369	55.0052	-3.060562620000000	N	S12000006	S14000014	S17000015	S16000097	S13002891	S08000017	S08000003	12	S37000006	S00097113	S00007455	5808AA07B	S01007681	S01000977	S02001444	S02000176	2	16	2	7	0	0	3484	S30000016	S31000511	UKM3	UKM32		0	276		0	S35000373	S09000004	0	8	8		S12000006				K01000010	5	6	Y

# take some coordinates (my home in OSG)
coords = cbind(340639, 672659)

# turn it into a spatial object of points
postcode.point <- SpatialPoints(coords)
proj4string(postcode.point) <- CRS("+init=epsg:27700");

# Create a buffer of different sizes for each one
postcode.buffer100 <- gBuffer( postcode.point, width=100, byid=TRUE)
postcode.buffer250 <- gBuffer( postcode.point, width=250, byid=TRUE)
postcode.buffer500 <- gBuffer( postcode.point, width=500, byid=TRUE)

# convert these to lon/lat as it is far cheaper than doing the whole raster the other way
latlon_crs <- CRS("+init=epsg:4326");
postcode.point <- spTransform(postcode.point, latlon_crs)
postcode.buffer100 <- spTransform(postcode.buffer100, latlon_crs)
postcode.buffer250 <- spTransform(postcode.buffer250, latlon_crs)
postcode.buffer500 <- spTransform(postcode.buffer500, latlon_crs)

x <- crop(ndvi_cloudless_raster, postcode.buffer500)
plot(x)

writeRaster(x, filename = 'ndvi_x_test.tif', format = 'GTiff')
writeRaster(y, filename = 'ndvi_mask_test.tif', format = 'GTiff', datatype='INT2S', overwrite = TRUE)

# we are working in lonlat WGS84
# postcode.point <- spTransform(postcode.point, CRS("+init=epsg:4326"))






# plot(ndvi_cloudless_raster)

