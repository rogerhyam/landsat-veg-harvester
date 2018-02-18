
# functions used in sampling from landsat8 products

# Given product id it will get the image and associated postcodes and create a sample 
# for each of the postcodes that has data
sample_product <- function(product_id){
  
  ndvi_raster <- get_cloud_free_raster(product_id = product_id)
  
  # plot(ndvi_raster)
  
  postcodes <- get_postcodes_in_extent(ndvi_raster)
  
  for(row in 1:nrow(postcodes)){
  
    # we are using the national grid as units are metres
    eastings <- postcodes[row, "GridReferenceEasting"]
    northings <- postcodes[row, "GridReferenceNorthing"]
    
    coords <- cbind(eastings, northings)
    
    # turn it into a spatial object of points
    postcode_point <- SpatialPoints(coords)
    proj4string(postcode_point) <- OSG_CRS
    
    x <- get_stats_for_sample(width_m = 500, postcode_point = postcode_point, ndvi_raster = ndvi_raster)
    
    # expecting a large number to be no data
    # but when we hit one that is we save it
    if(x[['pixels_not_na']] != 0){
      
      message('Data for ',  postcodes[row, "postcode"])
      #plot(x[['cropped']])
      
      x[['postcode']] <- postcodes[row, "postcode"]
      x[['product_id']] <- product_id
      x[['year']] <- 1965 #product[[year]]
      x[['month']] <- 2 #product[[month]]
      x[['day']] <- 28 #product[[day]]
      
      insert_id <- save_sample(sample = x)
      
    }else{
      message('No data for ',  postcodes[row, "postcode"])
    }
    
  }
  
}


# removes clouds - used in overlay function
cloud2NA <- function(x, y){
  #veg[cl > 750] <- NA
  # 110100 - remove cloud, snow, water
  x[bitwAnd(y, 52) > 1] <- NA
  return(x)
}

# get a clound free version of the ndvi raster
get_cloud_free_raster <- function(product_id){
  
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
  
  ndvi_cloudless_raster <- overlay(x = ndvi_raster, y = qa_raster, fun = cloud2NA)
  
  return(ndvi_cloudless_raster)
  
}

# a function to process a buffer and return basic stats for it
get_stats_for_sample <- function(width_m, postcode_point, ndvi_raster){
  
  # nice object for the results of our work
  results <- list()
  results[['buffer_width']] <- width_m;
  
  buffer_osg <- gBuffer( postcode_point, width=width_m, byid=TRUE)
  buffer_wgs84 <- spTransform(buffer_osg, LATLON_CRS)
  
  # if we get one out of the extent - should this happen? 
  if( is.null(intersect(extent(ndvi_raster), extent(buffer_wgs84) ) ) ){
    results[['pixels_not_na']] <- 0;
    return(results);
  }
  cropped <- crop(ndvi_raster, buffer_wgs84) # FIXME - catch edge case of buffer overlapping raster edge?
  
  # we want to do our stats on the area just in the mask 
  # - not the whole square with outer pixels set to NA
  # - how would we deal within NA within the mask then?
  # - set outside to 10001 (bigger then highest ndvi value)
  masked <- mask(cropped, rasterize(buffer_wgs84, cropped), updatevalue = 10001, updateNA = TRUE)
  results[['masked']] <- masked
  
  # plot(masked)
  
  # convert the raster back to just a list of numbers
  vals <- masked@data@values
  
  # remove those outer pixels just leaving the ones in the buffer circle
  vals <- setdiff(vals, 10001)
  
  # get our stats together for these number
  results[['pixels_total']] <- length(vals)
  results[['pixels_not_na']] <- length(vals[!is.na(vals)])
  
  # no data give up now
  if(results[['pixels_not_na']] == 0){
    return(results)
  } 
  
  results[['pixel_coverage']] <- results[['pixels_not_na']] / results[['pixels_total']]
  results[['ndvi_max']] <- max(vals, na.rm = TRUE) / 10000
  results[['ndvi_min']] <- min(vals, na.rm = TRUE) / 10000
  results[['ndvi_average']] <- mean(vals, na.rm = TRUE) / 10000
  results[['ndvi_sd']] <- sd(vals, na.rm = TRUE) / 10000
  
  return(results)
  
}

# returns a list of product_id, year, month, day (of capture)
get_next_product <- function(){
  
}

# returns the postcodes for a product
get_postcodes_in_extent <- function(target_raster){
  
  # sql query of db for things within these bounds e@xmin, xmax
  # this gets much more than 
  e <- extent(projectExtent(target_raster, OSG_CRS))
  sql = sprintf("SELECT postcode, GridReferenceEasting, GridReferenceNorthing
                FROM SmallUserPostcodes
                WHERE GridReferenceEasting > %f
                AND GridReferenceEasting < %f
                AND GridReferenceNorthing > %f
                AND GridReferenceNorthing < %f
                ", e@xmin, e@xmax, e@ymin, e@ymax)
   
  res <- dbSendQuery(mydb, sql)
  all_points <- dbFetch(res, n = -1)
  dbClearResult(res)
  
  return(all_points)
  
}

save_sample <- function(sample){
  print(sample)

  # ndvid_sd may be NA which we want as null
  if(is.na(sample[['ndvi_sd']])){
    ndvi_sd <- 'NULL'
  }else{
    ndvi_sd <- toString(sample[['ndvi_sd']])
  }
  
  sql <- sprintf("INSERT INTO samples
                ( postcode, product_id, buffer_size, year, month, day, pixels_total, pixels_not_na, pixel_coverage, ndvi_max, ndvi_min, ndvi_average, ndvi_sd, created) VALUE ('%s', '%s', %i, %i, %i, %i, %i, %i, %f, %f, %f, %f, %s, now() )",
                 sample[['postcode']],
                 sample[['product_id']],
                 sample[['buffer_width']],
                 sample[['year']],
                 sample[['month']],
                 sample[['day']],
                 sample[['pixels_total']],
                 sample[['pixels_not_na']],
                 sample[['pixel_coverage']],
                 sample[['ndvi_max']],
                 sample[['ndvi_min']],
                 sample[['ndvi_average']],
                 ndvi_sd
                )
  
  print(sql)
  
  res <- dbSendQuery(mydb, sql)
  dbClearResult(res)
  
  # get the insert id
  r <- dbGetQuery(mydb, "SELECT LAST_INSERT_ID() as last_id;")
  
  # save a geotif of largest crop to file
  if(sample[['buffer_width']] == 500){
    
    dir_save_path <- paste(
      DATA_DIR,
      'sample_tifs/',
      strsplit(sample[['postcode']], ' ')[[1]][1],
      sep = ''
    )
    
    dir.create(dir_save_path, showWarnings = FALSE, recursive = TRUE)
    
    tif_save_path <- paste(
      dir_save_path,
      '/',
      strsplit(sample[['postcode']], ' ')[[1]][1],
      '_',
      strsplit(sample[['postcode']], ' ')[[1]][2],
      '_',
      r[['last_id']],
      '.tif',
      sep = ''
    )
    
    writeRaster(sample[['masked']], filename = tif_save_path, format = 'GTiff', datatype='INT2S', overwrite = TRUE)
    
  }
  
  
  return(r[['last_id']])

}
