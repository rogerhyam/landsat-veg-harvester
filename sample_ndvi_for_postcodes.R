# Sampling NDVI Buffers around postcode centroids

# nice tutorial on raster package here
# https://geoscripting-wur.github.io/IntroToRaster/
# https://landsat.usgs.gov/sites/default/files/documents/lasrc_product_guide.pdf
# http://www.maths.lancs.ac.uk/~rowlings/Teaching/UseR2012/cheatsheet.html

# load the config variables and functions
source('config.R')
source('sampling_functions.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

# product_id <- 'LC08_L1TP_206021_20140418_20170423_01_T1';
product_id <- 'LC08_L1TP_204021_20140911_20170419_01_T1';

ndvi_raster <- get_cloud_free_raster(product_id = product_id)

plot(ndvi_raster)

postcodes <- get_postcodes_in_extent(ndvi_raster)


for(row in 1:nrow(postcodes)){
  eastings <- postcodes[row, "GridReferenceEasting"]
  northings <- postcodes[row, "GridReferenceNorthing"]
  
  coords <- cbind(eastings, northings)
  # turn it into a spatial object of points
  postcode_point <- SpatialPoints(coords)
  proj4string(postcode_point) <- OSG_CRS
  
  x <- get_stats_for_sample(width_m = 250, postcode_point = postcode_point, ndvi_raster = ndvi_raster)

  # expecting a large number to be no data
  # but when we hit one that is we save it
  if(x[['pixels_not_na']] != 0){
    plot(x[['cropped']])
    x[['postcode']] <- postcodes[row, "postcode"]
    x[['product_id']] <- product_id
    x[['year']] <- 1965 #product[[year]]
    x[['month']] <- 2 #product[[month]]
    x[['day']] <- 28 #product[[day]]
    save_sample(sample = x)
  }  
  
}


# EH9 1HB	EH9	EH9 1	19730800000000		325514	672062	55.9359	-3.192476030000000	N	S12000036	S14000024	S17000012	S16000108	S13002928	S08000024	S08000010	5	S37000012	S00104738	S00014577	6229BM13B	S01008616	S01002002	S02001613	S02000374	32	85	32	87	31	58	6921	S30000008	S31000277	UKM2	UKM25	S19000855	173001	212	S20000682	173	S35000287	S09000002	0	29	29		S12000036			S11000003	S22000059	1	1	Y
# EH4 5LR	EH4	EH4 5	19730800000000		320761	676132	55.9717	-3.269744670000000	N	S12000036	S14000026	S17000012	S16000109	S13002919	S08000024	S08000010	5	S37000012	S00103791	S00013726	6229AS10B	S01008939	S01002299	S02001672	S02000417	5	9	5	10	5	11	5856	S30000008	S31000235	UKM2	UKM25	S19000855	173001	212	S20000682	173	S35000287	S09000002	0	29	29		S12000036			S11000003	S22000059	1	1	Y
# EH33 2EQ	EH33	EH33 2	19730800000000		340639	672659	55.9433	-2.950507470000000	N	S12000010	S14000020	S17000015	S16000102	S13002910	S08000024	S08000010	5	S37000010	S00102508	S00012525	6228AJ10A	S01008226	S01001587	S02001544	S02000291	6	11	0	0	1	2	1473	S30000005	S31000165	UKM2	UKM23	S19001238	209001	574	S20000991	209	S35000826	S09000002	0	28	28		S12000010	S05000010	S06000052	S11000003	S22000059	2	2	Y
# DG16 5EA	DG16	DG16 5	19931200000000		332174	568369	55.0052	-3.060562620000000	N	S12000006	S14000014	S17000015	S16000097	S13002891	S08000017	S08000003	12	S37000006	S00097113	S00007455	5808AA07B	S01007681	S01000977	S02001444	S02000176	2	16	2	7	0	0	3484	S30000016	S31000511	UKM3	UKM32		0	276		0	S35000373	S09000004	0	8	8		S12000006				K01000010	5	6	Y

# take some coordinates 
coords <- cbind(340639, 672659)
postcode_string <- 'EH33 2EQ'

# turn it into a spatial object of points
postcode_point <- SpatialPoints(coords)
proj4string(postcode_point) <- OSG_CRS

sample_stats <- get_stats_for_sample(width_m = 100, postcode_point = postcode_point, ndvi_raster = ndvi_raster)


# add the other bits into the sample_stats then save them to the db
sample_stats[['product_id']] <- product_id
sample_stats[['postcode']] <- postcode_string
# sample_stats[['year']] <- product[[year]]
# sample_stats[['month']] <- product[[month]]
# sample_stats[['day']] <- product[[day]]

# writeRaster(x, filename = 'ndvi_x_test.tif', format = 'GTiff')
# writeRaster(y, filename = 'ndvi_mask_test.tif', format = 'GTiff', datatype='INT2S', overwrite = TRUE)


