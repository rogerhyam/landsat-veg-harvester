
# Download completed orders for scenes

source('config.R')
source('reaping/functions.R')

# we work with stuff in the raw directory
raw_dir <- paste(DATA_DIR, "/raw", sep="") 

# get a list of all the xxxx.order files (open orders)
order_files <- list.files(list.dirs(raw_dir, recursive = FALSE), full.names = TRUE, include.dirs = FALSE, pattern = "\\.order$")

# find the order ids that are in the json in these files
order_ids <- list()
for(of in order_files){
  ord <- read_json(of)
  
  order_ids <- c(order_ids, ord$orderid)
}
order_ids <- unique(unlist(order_ids))

# call to get the status for the scenes in these orders.
for(id in order_ids){
  
  # only item per order
  item <- usgs_get_status(id)
     
  # we ignore plot - don't ask for that any more
  if(item$name == "plot") return()
  
  # calculate location of file (by path_row) e.g. LC82040212016340LGN00
  row = as.integer(substr(item$name, 7, 9))
  path = as.integer(substr(item$name, 4, 6))
  file_without_ending = paste(raw_dir, '/', path, '_', row, '/', item$name, sep="")
  
  # if the order is unavailable replace the .order file with a .unavailable file
  if(item$status == "unavailable"){
    
    # write the note to an unavailable file 
    writeLines(item$note[[1]], paste(file_without_ending, '.unavailable', sep=""))
    
    # remove the order file so we don't keep checking it
    file.remove(paste(file_without_ending, '.order', sep=""))
    
  }
  
  # if the status is complete download the files and delete the associated .order file
  if(item$status == "complete"){
    print(item$cksum_download_url[[1]])
    
    # get the md5 checksum
    md5_file <- paste(file_without_ending, '.md5', sep='')
    
    # Don't bother with full error handling on the md5 download as we aren't checking it just now
    try(download.file(item$cksum_download_url[[1]], md5_file))
    
    # get the actual thing
    tar_file <- paste(file_without_ending, '.tar.gz', sep='')
    
    success_code <- tryCatch(
      download.file(item$product_dload_url[[1]], tar_file),
      error = function(e){
        writeLines(conditionMessage(e), paste(file_without_ending, '.error', sep=""))
        return(99)
      },
      warning = function(e){
        writeLines(conditionMessage(e), paste(file_without_ending, '.warning', sep=""))
        return(99)
      }
    )

    # improve me - not going to check md5 at the moment as we are getting working files but bad md5s
    
    # remove the .order and other files so we don't download it next time
    if(success_code == 0){
      file.remove(paste(file_without_ending, '.order', sep=""))
      file.remove(paste(file_without_ending, '.error', sep=""), showWarnings = FALSE)
      file.remove(paste(file_without_ending, '.warning', sep=""), showWarnings = FALSE)
    }
    
  }
  
} # end working through orders


