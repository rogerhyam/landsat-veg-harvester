
# Creates layer files for evi and ndvi without cloud cover for later use

# we keep track of what needs processing on the basis of directories and file names in raw. 
# there should be something in the threshed/<layer> for each tar.gz file in raw
library(raster)

source('config.R')
source('reaping/functions.R')

# we work with stuff in the raw directory
raw_dir <- paste(DATA_DIR, "/raw", sep="") 

# we put things in the threshed directory so need the path for it
threshed_dir <- paste(DATA_DIR, "/threshed", sep="") 

# get a list of all the tar.gz files we have 
tar_files = list.files(raw_dir, recursive = TRUE, pattern = "\\.tar.gz$", include.dirs = FALSE)

# turn these into expected dir paths
expected_dirs = file_path_sans_ext(file_path_sans_ext(tar_files))
expected_dirs = paste(threshed_dir, '/', expected_dirs, sep="")

# do we have a companion dir in threshed
existing_dirs = Filter(dir.exists, expected_dirs)
missing_dirs = setdiff(expected_dirs,existing_dirs)

# create a function to set cloud pixels to NA
# remember veg and cl could be big vectors
cloud2NA <- function(veg, cl){
  
  # bit masking for sr cloud from https://landsat.usgs.gov/sites/default/files/documents/provisional_lasrc_product_guide.pdf
  # 0 Cirrus cloud
  # 1 Cloud
  # 2 Adjacent to cloud
  # 3 Cloud shadow
  # 4 Aerosol
  # 5 Aerosol
  # 6 Unused
  # 7 Internal test
  # 
  # bits 4&5 interpreted as
  # 00 Climatology level aerosol content
  # 01 Low aerosol content
  # 10 Average aerosol conten
  # 11 High aerosol content
  # 
  
  # remove cirrus cloud, cloud, adjacent cloud and cloud shadow 00001111 (15) AND
  veg[bitwAnd(cl, 15) > 1] <- NA
  
  # remove high aerosol content (average and low can stay) 00110000
  veg[bitwAnd(cl, 48) == 48] <- NA
  
  return(veg)
  
}

# work through these and process the files to fill them
for(missing_dir in missing_dirs){
  
  # get the base file name (item name)
  name <- sub("^.*/threshed/[0-9]{1,3}_[0-9]{1,3}/", "", missing_dir)
  
  # get the tar.gz path again
  tar_path <- sub("/threshed/", "/raw/", missing_dir)
  tar_path <- paste(tar_path, '.tar.gz', sep="")

  # which files do we extract?
  cloud_file = paste(name, '_sr_cloud.tif', sep = "")
  evi_file =  paste(name, '_sr_evi.tif', sep = "")
  ndvi_file =  paste(name, '_sr_ndvi.tif', sep = "")
  meta_file = paste(name, '.xml', sep = "")
  file_vector = c(cloud_file, evi_file, ndvi_file, meta_file)
  
  untar(tar_path, files = file_vector, exdir = missing_dir, compressed = "gzip")
  
  # path to the clouds
  cloud_file_path <- paste(missing_dir, '/', cloud_file, sep="")
  cloud_raster <- raster(cloud_file_path)
  
  # create a cloud free version of the evi file
  evi_file_path <- paste(missing_dir, '/', evi_file, sep="")
  evi_file_sans_clouds_path <-  paste(missing_dir, '/', name, '_sr_evi_sans_cloud.tif', sep = "")
  evi_raster <- raster(evi_file_path)
  evi_sans_clouds_raster <- overlay(evi_raster, cloud_raster, fun = cloud2NA, filename = evi_file_sans_clouds_path)
  
  # create a cloud free version of the ndvi file
  ndvi_file_path <- paste(missing_dir, '/', ndvi_file, sep="")
  ndvi_file_sans_clouds_path <-  paste(missing_dir, '/', name, '_sr_ndvi_sans_cloud.tif', sep = "")
  ndvi_raster <- raster(ndvi_file_path)
  ndvi_sans_clouds_raster <- overlay(ndvi_raster, cloud_raster, fun = cloud2NA, filename = ndvi_file_sans_clouds_path)
  
  # remove cloudy files - we can always get them again from the raw tar
  file.remove(evi_file_path)
  file.remove(ndvi_file_path)
  file.remove(cloud_file_path)

}


