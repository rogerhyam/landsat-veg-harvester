

# getting the greenness of greenspace.
# load of this code is coppied from sampling_functions.R rather then generalise that

source('config.R')
source('sampling_functions.R')
stack_name <- "winters_13_16"

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

# load the shape file
shape_gs <- readOGR(dsn = "/Users/rogerhyam/Dropbox/RBGE/2018/Green_Deprivation/Green_Space_OS_2018", layer = "scotland_greenspace_2018")

# convert this into a list of centroids (note this OSG projection)
gs_centroids <- SpatialPointsDataFrame(gCentroid(shape_gs, byid=TRUE), shape_gs@data, match.ID = FALSE)

# get a raster file to work on 
stack_path <- paste(DATA_DIR, 'stacks/', stack_name, '.tif', sep='')
print(stack_path)
ndvi_stack <- stack(stack_path)
ndvi_raster <- ndvi_stack[[1]]

start_t <- Sys.time()

for(row in 1:nrow(gs_centroids)){

  cat("\014")
  end_t <- Sys.time()
  rate <- round((as.numeric(end_t) - as.numeric(start_t))/row, 3)
  remaining_sec <- (nrow(gs_centroids) - row)*rate
  estimate <- end_t + remaining_sec
  
  print(paste(gs_centroids@data[["id"]][row], row, nrow(gs_centroids),  rate, start_t, end_t, estimate, sep=" | "))
  
  # we are using the national grid as units are metres
  eastings <- gs_centroids@coords[row, 'x']
  northings <- gs_centroids@coords[row, 'y']
  coords <- cbind(eastings, northings)
  
  # turn it into a spatial object of points
  centroid <- SpatialPoints(coords)
  proj4string(centroid) <- OSG_CRS

  # 500m Buffer
  
  # create biggest crop
  buffer_500_ogs <- gBuffer( centroid, width=500, byid=TRUE)
  buffer_500_wgs84 <- spTransform(buffer_500_ogs, LATLON_CRS)
  # 
  # # if we get one out of the extent - should this happen? 
  if( is.null(intersect(extent(ndvi_raster), extent(buffer_500_wgs84) ) ) ){
     next
   }
  #
  # catch edge case of buffer overlapping raster edge?
  possibleError <- tryCatch(
     cropped <- crop(ndvi_raster, buffer_500_wgs84),
     # if we failed to crop it
     error = function(e)e
   )
  if(inherits(possibleError, "error")) next

  # actually do the sample
  s <- get_stats_for_sample(width_m = 500, postcode_point = centroid, ndvi_raster = cropped, buffer_wgs84 = buffer_500_wgs84)
  s[['polygon_id']] <- gs_centroids@data[["id"]][row]
  s[['gs_function']] <- gs_centroids@data[["function."]][row]
  save_greenness_of_greenspace(x = s)
  
  # 250m Buffer
  
  # next get the smaller crops by cropping the larger ones
  buffer_250_ogs <- gBuffer(centroid, width=250, byid=TRUE)
  buffer_250_wgs84 <- spTransform(buffer_250_ogs, LATLON_CRS)
  possibleError <- tryCatch(
    cropped <- crop(ndvi_raster, buffer_250_wgs84),
    # if we failed to crop it
    error = function(e)e
  )
  if(inherits(possibleError, "error")) next
  
  # actually do the sample
  s <- get_stats_for_sample(width_m = 250, postcode_point = centroid, ndvi_raster = cropped, buffer_wgs84 = buffer_250_wgs84)
  s[['polygon_id']] <- gs_centroids@data[["id"]][row]
  s[['gs_function']] <- gs_centroids@data[["function."]][row]
  save_greenness_of_greenspace(x = s)
  
  # 100m Buffer
  
  # next get the smaller crops by cropping the larger ones
  buffer_100_ogs <- gBuffer(centroid, width=100, byid=TRUE)
  buffer_100_wgs84 <- spTransform(buffer_100_ogs, LATLON_CRS)
  possibleError <- tryCatch(
    cropped <- crop(ndvi_raster, buffer_100_wgs84),
    # if we failed to crop it
    error = function(e)e
  )
  if(inherits(possibleError, "error")) next
  
  # actually do the sample
  s <- get_stats_for_sample(width_m = 100, postcode_point = centroid, ndvi_raster = cropped, buffer_wgs84 = buffer_100_wgs84)
  s[['polygon_id']] <- gs_centroids@data[["id"]][row]
  s[['gs_function']] <- gs_centroids@data[["function."]][row]
  save_greenness_of_greenspace(x = s)
  
}

