
# common functions used in baking products from the threshed grains

# gets a bounding box extent of size in metres around a longlat coordinate.
roi_get_buffer <- function(coord, buffer){
  # coords <- cbind(-3.2011581,55.966792)
  
  # Latitude: 1 deg = 110.574 km
  lat_buffer_degrees = (buffer/1000)/110.574
  lon_buffer_degrees = (buffer/1000) / 111.320*cos( coord[[2]]*(pi/180) ) # cos is radians
  
  minX <- coord[1] - lat_buffer_degrees
  maxX <- coord[1] + lat_buffer_degrees
  minY <- coord[2] - lon_buffer_degrees
  maxY <- coord[2] + lon_buffer_degrees
  
  e <- extent(minX, maxX, minY, maxY)
  
  print(e)
  
  return(e)
  
}

# adds layers to the roi stack from the available threshed rasters
# - skips non intersecting rasters
# - skips rasters it has already done
roi_update <- function(roi_file, roi_extent){
  
  # directories we work with
  threshed_dir <- paste(DATA_DIR, "/threshed", sep="") 
  products_dir <- paste(DATA_DIR, "/products", sep="") 
  
  # roi file path
  roi_file_path <- paste(products_dir, "/", roi_file, sep = "")
    
    # if the file exists we load it into a stack and use the extent in the file
    # if it doesn't we create a fresh stack and use the extent we have been passed
    roi_stack <- NULL
    if(file.exists(roi_file_path)){
      roi_stack <- stack(roi_file_path)
      roi_extent <- roi_stack@extent
    }
     
    # scan the dirs of potential layers.
  
    # if the first file of a dir doesn't intersect then none of them will
    # so move to the next dir
    wrs_dirs <- list.dirs(threshed_dir, recursive = FALSE)
    for(wrs_dir in wrs_dirs){
      
      # multiple scenes for each wrs square
      scene_dirs <- list.dirs(wrs_dir, recursive = FALSE)
      for(scene_dir in scene_dirs){

        # if the stack already contains this scene as a layer then skip it
        # FIXME
        
        # each scene contains two tif files
        scene_tifs = list.files(scene_dir, full.names = TRUE, include.dirs = FALSE, pattern = "\\.tif$")
        first_raster <- raster(scene_tifs[[1]])
        second_raster <- raster(scene_tifs[[2]])
        
        # if this scene doesn't overlap with our extent of interest then
        # none of the scenes in this dir will intersect
       
        if(!tryCatch(!is.null(intersect(first_raster, roi_extent)), error=function(e) return(FALSE))){
           print("no overlap")
           break
        }

        # We know we are overlapping so get into cropping
        first_raster_cropped <- crop(first_raster, roi_extent, snap="near")
        second_raster_cropped <- crop(second_raster, roi_extent, snap="near")
        
        # extend to the same size as the crop - for cases where the crop goes over the edge of the raster
        # assuming these aren't too big as we are holding them in memory
        first_raster_cropped <- extend(first_raster_cropped, roi_extent, NA)
        second_raster_cropped <- extend(second_raster_cropped, roi_extent, NA)
        
        # convert the values to floating point so we can think about it in terms of -1 to +1 indices
        first_raster_cropped <- first_raster_cropped * 0.0001
        second_raster_cropped <- second_raster_cropped * 0.0001
        
        # we mask the non-veg values to make things clearer to handle
        
        first_raster_cropped[first_raster_cropped < 0.2] <- NA
        first_raster_cropped[first_raster_cropped > 0.8] <- NA
        second_raster_cropped[second_raster_cropped < 0.2] <- NA
        second_raster_cropped[second_raster_cropped > 0.8] <- NA

        print(first_raster_cropped)

        # add them to the stack
        if(is.null(roi_stack)){
          if(!is.na(maxValue(first_raster_cropped) ) && !is.na(maxValue(second_raster_cropped) )){
            roi_stack <- stack(first_raster_cropped, second_raster_cropped)
          }
            
        }else{
          
          # although they are the same crop and resolution their actual extents can be out
          # because of rounding to nearest row/col - so we force it
          first_raster_cropped <- resample(first_raster_cropped, roi_stack, method='bilinear')
          second_raster_cropped <- resample(second_raster_cropped, roi_stack, method='bilinear')
          
          # only if they are not totally NA
          if(!is.na(maxValue(first_raster_cropped) )) roi_stack <- addLayer(roi_stack, first_raster_cropped)
          if(!is.na(maxValue(second_raster_cropped) )) roi_stack <- addLayer(roi_stack, second_raster_cropped)
          
        }
        
        print(roi_stack)
        
      } # end work through scenes in wrs square
      
      
    } # end working through wrs directories

    # finally save the stack to the location
    writeRaster(x=roi_stack, filename=roi_file_path, datatype='FLT4S', overwrite=TRUE)
    
   # central ed area extent(-3.2410177,-3.1643177, 55.947176,55.975148)
    
}