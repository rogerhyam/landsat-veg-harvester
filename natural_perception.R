# Looking at greenness vs natural perception from Street View Study.

source('config.R')
source('sampling_functions.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql <- "SELECT sp.*,  i.evaluation as evaluated, i.evaluation_avg, i.calc_artificialness, i.calc_naturalness  
FROM nat_image.sample_points as sp
join nat_image.image as i on sp.image_id = i.id"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

stack_name <- 'summers_14_16'

stack_path <- paste(DATA_DIR, 'stacks/', stack_name, '.tif', sep='')
print(stack_path)
ndvi_stack <- stack(stack_path)
ndvi_raster <- ndvi_stack[[1]]

# work through them
start_t <- Sys.time()

for(row in 1:nrow(res_df)){
  
  cat("\014")
  end_t <- Sys.time()
  rate <- round((as.numeric(end_t) - as.numeric(start_t))/row, 3)
  remaining_sec <- (nrow(res_df) - row)*rate
  estimate <- end_t + remaining_sec 

  print(paste(res_df[row, "image_id"], row, nrow(res_df),  rate, start_t, end_t, estimate, sep=" | "))
  
  # create a point
  eastings <- res_df[row, "sample_lon"]
  northings <- res_df[row, "sample_lat"]
  coords <- cbind(eastings, northings)
  
  # turn it into a spatial object of points
  sample_point_wgs84 <- SpatialPoints(coords)
  proj4string(sample_point_wgs84) <- LATLON_CRS # we are on latlon at the moment
  
  # reproject it to something with metres as the unit so we can build buffers
  sample_point_ogs <- spTransform(sample_point_wgs84, OSG_CRS)
  
  # 500 buffer
  
  buffer_500_ogs <- gBuffer( sample_point_ogs, width=500, byid=TRUE)
  buffer_500_wgs84 <- spTransform(buffer_500_ogs, LATLON_CRS)
  
  cropped <- crop(ndvi_raster, buffer_500_wgs84)
  
  x <- get_stats_for_sample(width_m = 500, postcode_point = sample_point_wgs84, ndvi_raster = cropped, buffer_wgs84 = buffer_500_wgs84)
  x[['sample_point_id']] <- res_df[row, "id"]
  x[['stack_name']] <- stack_name

  save_natural_perception_sample(sample = x)
  
  # 250 buffer
  
  buffer_250_ogs <- gBuffer( sample_point_ogs, width=250, byid=TRUE)
  buffer_250_wgs84 <- spTransform(buffer_250_ogs, LATLON_CRS)
  
  cropped <- crop(ndvi_raster, buffer_250_wgs84)
  
  x <- get_stats_for_sample(width_m = 250, postcode_point = sample_point_wgs84, ndvi_raster = cropped, buffer_wgs84 = buffer_250_wgs84)
  x[['sample_point_id']] <- res_df[row, "id"]
  x[['stack_name']] <- stack_name
  
  save_natural_perception_sample(sample = x)
  
  # 100 buffer
  
  buffer_100_ogs <- gBuffer( sample_point_ogs, width=250, byid=TRUE)
  buffer_100_wgs84 <- spTransform(buffer_100_ogs, LATLON_CRS)
  
  cropped <- crop(ndvi_raster, buffer_100_wgs84)
  
  x <- get_stats_for_sample(width_m = 100, postcode_point = sample_point_wgs84, ndvi_raster = cropped, buffer_wgs84 = buffer_100_wgs84)
  x[['sample_point_id']] <- res_df[row, "id"]
  x[['stack_name']] <- stack_name
  
  save_natural_perception_sample(sample = x)
  
}


  

