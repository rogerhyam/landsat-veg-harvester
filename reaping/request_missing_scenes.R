
# Takes a list of the available scenes. Compares them to the files we have downloaded. Puts in a request for the missing ones.
library(tools)

source('config.R')
source('reaping/functions.R')

# we work with stuff in the raw directory
raw_dir <- paste(DATA_DIR, "/raw", sep="") 

# load the available_scenes
load(paste(raw_dir, "/available_scenes.RData", sep=""))

# each downloaded (or ordered) scene is a file with either an ending of its current status or a .tgz
downloaded_scene_file_names <- list.files(list.dirs(raw_dir, recursive = FALSE), full.names = FALSE, include.dirs = FALSE)

# chop the ending off each one because we are not intereseted in the status
downloaded_scene_ids <- file_path_sans_ext(downloaded_scene_file_names)

# work out the missing ones - just the first 10 in this batch
missing_scenes <- head(setdiff(available_scenes[,'sceneID'], downloaded_scene_ids), 10)

# place orders for the scene
order_json <- usgs_place_order(missing_scenes)

# if we are successful with the call then write a file for each scene to say it has been ordered
if(!is.null(order_json)){
  
  # work through and order each of these scenes 
  for(scene_id in missing_scenes){
    
    # calculate location of file (by path_row) e.g. LC82040212016340LGN00
    row = as.integer(substr(scene_id, 7, 9))
    path = as.integer(substr(scene_id, 4, 6))
    
    # write the json to that 
    writeLines(order_json, paste(raw_dir, '/', path, '_', row, '/', scene_id, '.order', sep=""))

  }
  
}

