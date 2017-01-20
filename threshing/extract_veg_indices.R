
# Creates layer files for evi and ndvi without cloud cover for later use

# we keep track of what needs processing on the basis of directories and file names in raw. 
# there should be something in the threshed/<layer> for each tar.gz file in raw

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
  
}

