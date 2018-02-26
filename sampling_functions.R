
# functions used in sampling from landsat8 products

# Given stack_name sample the NDVI for all the postcodes covered.
sample_stack <- function(stack_name){
  
  rasterOptions(maxmemory=10e+09)
  
  stack_path <- paste(DATA_DIR, 'stacks/', stack_name, '.tif', sep='')
  ndvi_stack <- stack(stack_path);
  ndvi_raster <- ndvi_stack[[1]]
  
  postcodes <- get_postcodes_in_extent(ndvi_raster)
  
  start_t <- Sys.time()
  
  for(row in 1:nrow(postcodes)){
    
    cat("\014")
    end_t <- Sys.time()
    rate <- round((as.numeric(end_t) - as.numeric(start_t))/row, 3)
    remaining_sec <- (nrow(postcodes) - row)*rate
    estimate <- end_t + remaining_sec

    print(paste(stack_name, postcodes[row, "postcode"], row, nrow(postcodes),  rate, start_t, end_t, estimate, sep=" | "))
  
    # we are using the national grid as units are metres
    eastings <- postcodes[row, "GridReferenceEasting"]
    northings <- postcodes[row, "GridReferenceNorthing"]
    
    coords <- cbind(eastings, northings)
    
    # turn it into a spatial object of points
    postcode_point <- SpatialPoints(coords)
    proj4string(postcode_point) <- OSG_CRS
    
    # 500m Buffer
    
    # create biggest crop
    buffer_500_ogs <- gBuffer( postcode_point, width=500, byid=TRUE)
    buffer_500_wgs84 <- spTransform(buffer_500_ogs, LATLON_CRS)
    
    # if we get one out of the extent - should this happen? 
    if( is.null(intersect(extent(ndvi_raster), extent(buffer_500_wgs84) ) ) ){
      next
    }
    
    # catch edge case of buffer overlapping raster edge?
    tryCatch(
      cropped <- crop(ndvi_raster, buffer_500_wgs84),
      # if we failed to crop it
      error = function(e){
        next
      }  
    )
    
    # actually do the sample
    x <- get_stats_for_sample(width_m = 500, postcode_point = postcode_point, ndvi_raster = cropped, buffer_wgs84 = buffer_500_wgs84)
    x[['postcode']] <- postcodes[row, "postcode"]
    x[['stack_name']] <- stack_name
    save_sample(sample = x)
    
    # 250m Buffer

    # next get the smaller crops by cropping the larger ones
    buffer_250_ogs <- gBuffer(postcode_point, width=250, byid=TRUE)
    buffer_250_wgs84 <- spTransform(buffer_250_ogs, LATLON_CRS)
    cropped <- crop(cropped, buffer_250_wgs84)

    x <- get_stats_for_sample(width_m = 250, postcode_point = postcode_point, ndvi_raster = cropped, buffer_wgs84 = buffer_500_wgs84)
    x[['postcode']] <- postcodes[row, "postcode"]
    x[['stack_name']] <- stack_name
    save_sample(sample = x)

    # 100m Buffer
    
    # next get the smaller crops by cropping the larger ones
    buffer_100_ogs <- gBuffer(postcode_point, width=100, byid=TRUE)
    buffer_100_wgs84 <- spTransform(buffer_100_ogs, LATLON_CRS)
    cropped <- crop(cropped, buffer_100_wgs84)
    
    x <- get_stats_for_sample(width_m = 100, postcode_point = postcode_point, ndvi_raster = cropped, buffer_wgs84 = buffer_500_wgs84)
    x[['postcode']] <- postcodes[row, "postcode"]
    x[['stack_name']] <- stack_name
    save_sample(sample = x)

  }
  
  # if we get to here then we have finished sampling the product
  dbGetQuery(mydb, sprintf("UPDATE downloads set `status` = 'sampled' WHERE product_id = '%s'", product_id))
  
  
}

# a function to process a buffer and return basic stats for it
get_stats_for_sample <- function(width_m, postcode_point, ndvi_raster, buffer_wgs84){
  
  # nice object for the results of our work
  results <- list()
  results[['buffer_width']] <- width_m;
  
  vals <- extract(ndvi_raster, buffer_wgs84)
  vals <- unlist(vals[1])
  
  # get our stats together for these number
  results[['pixels_total']] <- length(vals)
  results[['pixels_not_na']] <- length(vals[!is.na(vals)])

  # no data give up now
  if(results[['pixels_not_na']] == 0){
    results[['pixel_coverage']] <- 0
    results[['ndvi_max']] <- 0
    results[['ndvi_min']] <- 0
    results[['ndvi_average']] <-0
    results[['ndvi_sd']] <- 0
  }else{
    results[['pixel_coverage']] <- results[['pixels_not_na']] / results[['pixels_total']]
    results[['ndvi_max']] <- max(vals, na.rm = TRUE) / 10000
    results[['ndvi_min']] <- min(vals, na.rm = TRUE) / 10000
    results[['ndvi_average']] <- mean(vals, na.rm = TRUE) / 10000
    results[['ndvi_sd']] <- sd(vals, na.rm = TRUE) / 10000
  }
  
  return(results)
  
}



# this will delete the samples for any incomplete sampling runs and reset their status to 'downloaded'
roll_back_product_sampling <- function(){
  
  stalled <- dbGetQuery(mydb, "SELECT product_id FROM downloads WHERE `status` LIKE 'sampling'")
  
  for(i in 1:nrow(stalled)) {
    row <- stalled[i,]
    dbGetQuery(mydb, sprintf("DELETE FROM samples WHERE product_id LIKE '%s'", row[1] ))
    dbGetQuery(mydb, sprintf("UPDATE downloads set `status` = 'downloaded' WHERE product_id = '%s'", row[1]))
  }
  
}


# removes clouds - used in overlay function
cloud2NA <- function(x, y){
  #veg[cl > 750] <- NA
  # 110100 - remove cloud, snow, water
  x[bitwAnd(y, 52) > 1] <- NA
  return(x)
}

# make sure month_paths are of the form "2016/04" "2016/05"
create_stack_cache <- function(stack_name, month_paths){
  
  stack_cache_dir <- paste(DATA_DIR, 'cloud_free_cache', sep='')
  dir_paths <- paste(stack_cache_dir, month_paths, sep='/')
  file_paths <- list.files(dir_paths,full.names=TRUE )
  
  print(file_paths)
  
  # get a list of rasters
  source_rasters <- lapply(file_paths, raster)
  
  # create a seed raster with just NA in it
  seed <- source_rasters[[1]]
  values(seed)[TRUE] = NA
  
  # extend the seed to get 
  for(r in source_rasters){
    print(seed);
    seed <- extend(seed[[1]], extent(r), value=NA)
  }
  
  # resample them all to the seed size and add to stack
  myStack <- stack()
  for(r in source_rasters){
    print(r)
    re <- resample(r, seed)
    myStack <- addLayer(myStack, re)
  }
  
  # create some summary data
  mean_raster <- calc(myStack, fun = mean, na.rm = TRUE)
  n_raster <- calc(myStack, fun = function(x){ return(length(x[!is.na(x)])) })
  result_stack = stack(mean_raster, n_raster)
  
  # save the stack
  stack_path <- paste(DATA_DIR, 'stacks/', stack_name, '.tif', sep='')
  writeRaster(result_stack, filename=stack_path, dataType='FLT4S')

}

# build a cache of cloud_free tifs by date
update_cloud_free_cache <- function(){
  
  # get a list of them from db
  downloads <- dbGetQuery(mydb, "select 
                          d.id,
                          d.product_id, 
                          SUBSTRING_INDEX(p.acquisitionDate,'-',1) as year,
                          SUBSTRING_INDEX(SUBSTRING_INDEX(p.acquisitionDate,'-',2),'-',-1) as month
                          from LANDSAT_8_C1 as p
                          join downloads as d on p.LANDSAT_PRODUCT_ID = d.product_id
                          where d.`status` like 'downloaded'")
  for(i in 1:nrow(downloads)) {
    
    print(paste(i, '-' ,p[['product_id']]))
    
    p <- downloads[i,]
    ndvi_cloudless_raster <- get_cloud_free_raster(p[['product_id']])
    
    file_dir <- paste(DATA_DIR, 'cloud_free_cache/', p[['year']], '/', p[['month']], sep='')
    dir.create(file_dir, showWarnings = FALSE, recursive = TRUE)
    
    file_path <- paste(file_dir, '/', p[['product_id']], '.tif', sep='')
    writeRaster(ndvi_cloudless_raster, filename = file_path, format = 'GTiff', datatype='INT2S', overwrite = TRUE)

    dbGetQuery(mydb, sprintf("UPDATE downloads set `status` = 'cached' WHERE product_id = '%s'", p[['product_id']]))
    
  }
  
}

# get a clound free version of the ndvi raster
get_cloud_free_raster <- function(product_id){
  
  # set the raster options to increase memory size - we know approx size of images
  # 127450485
  # 140000000
  rasterOptions(maxmemory=10e+09)
  
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

# returns a list of product_id, year, month, day (of capture)
get_next_products <- function(){
  next_products <- dbGetQuery(mydb, "select 
             d.id,
             d.product_id, 
             SUBSTRING_INDEX(p.acquisitionDate,'-',1) as year,
             SUBSTRING_INDEX(SUBSTRING_INDEX(p.acquisitionDate,'-',2),'-',-1) as month,
             SUBSTRING_INDEX(p.acquisitionDate,'-',-1) as day
             from LANDSAT_8_C1 as p
             join downloads as d on p.LANDSAT_PRODUCT_ID = d.product_id
             where d.`status` like 'downloaded'
             and year(p.acquisitionDate) in (2016, 2015, 2014)
             order by year(p.acquisitionDate), d.id")
}

# returns the postcodes for a product
get_postcodes_in_extent <- function(target_raster){
  
  # sql query of db for things within these bounds e@xmin, xmax
  # this gets much more than 
  e <- extent(projectExtent(target_raster, OSG_CRS))
  sql = sprintf("SELECT postcode, GridReferenceEasting, GridReferenceNorthing
                FROM SmallUserPostcodes
                WHERE length(DateOfDeletion) = 0
                AND UrbanRural8Fold2013_2014Code < 3
                AND GridReferenceEasting > %f
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
  # print(sample)

  # ndvid_sd may be NA which we want as null
  if(is.na(sample[['ndvi_sd']])){
    ndvi_sd <- 'NULL'
  }else{
    ndvi_sd <- toString(sample[['ndvi_sd']])
  }
  
  sql <- sprintf("INSERT INTO samples
                ( postcode, stack_name, buffer_size, pixels_total, pixels_not_na, pixel_coverage, ndvi_max, ndvi_min, ndvi_average, ndvi_sd, created) 
                 VALUE ('%s', '%s', '%s', '%s', '%s', %f, %f, %f, %f, %s, now() )",
                 sample[['postcode']],
                 sample[['stack_name']],
                 sample[['buffer_width']],
                 sample[['pixels_total']],
                 sample[['pixels_not_na']],
                 sample[['pixel_coverage']],
                 sample[['ndvi_max']],
                 sample[['ndvi_min']],
                 sample[['ndvi_average']],
                 ndvi_sd
                )
  
  # print(sql)
  
  res <- dbSendQuery(mydb, sql)
  dbClearResult(res)
  
  # get the insert id
  # r <- dbGetQuery(mydb, "SELECT LAST_INSERT_ID() as last_id;")
  
  # save a geotif of largest crop to file
  # if(sample[['buffer_width']] == 500){
  #   
  #   dir_save_path <- paste(
  #     DATA_DIR,
  #     'sample_tifs/',
  #     strsplit(sample[['postcode']], ' ')[[1]][1],
  #     sep = ''
  #   )
  #   
  #   dir.create(dir_save_path, showWarnings = FALSE, recursive = TRUE)
  #   
  #   tif_save_path <- paste(
  #     dir_save_path,
  #     '/',
  #     strsplit(sample[['postcode']], ' ')[[1]][1],
  #     '_',
  #     strsplit(sample[['postcode']], ' ')[[1]][2],
  #     '_',
  #     r[['last_id']],
  #     '.tif',
  #     sep = ''
  #   )
  #   
  #   # writeRaster(sample[['masked']], filename = tif_save_path, format = 'GTiff', datatype='INT2S', overwrite = TRUE)
  #   
  # }
  
  # return(r[['last_id']])

}

sample_greenspace <- function(shape_gs, buffer, buffer_size, postcode_string){
  
  
  
}
