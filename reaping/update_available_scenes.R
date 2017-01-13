# update metadata on available scenes.
# run perhaps once a month

library(sqldf)

raw_dir <- "../data/raw"
meta_file.gz <- paste(raw_dir, "/landsat8_metadata.csv.gz", sep="")
meta_file.csv <- paste(raw_dir, "/landsat8_metadata.csv" , sep="")
available_scenes.RData <- paste(raw_dir, "/available_scenes.RData", sep="")

# get the bulk data
download.file("https://landsat.usgs.gov/landsat/metadata_service/bulk_metadata_files/LANDSAT_8.csv.gz", meta_file.gz, mode = "w")

# unzip it
system(paste("gunzip -k ", meta_file.gz))

# load only the rows for the scenes we are interested in
# we use an sql filter on the csv file loader based on the directory names
path_row <- paste(list.dirs(raw_dir, full.name = FALSE), collapse = '","')
sql <- paste("SELECT  * FROM file WHERE `path` || '_' ||`row`  in", '("' , path_row, '")' )
l8_meta <- read.csv.sql(meta_file.csv, sql = sql, header = TRUE)

# save a copy of this as the list of all the available scenes for the row/path specified.
save(l8_meta, file = available_scenes.RData)

# remove the big csv file (it is 300M)
file.remove(meta_file.csv)


