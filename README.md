# landsat-veg-harvester
A project written in R for processing NDVI and EVI data from Landsat thanks to USGS

This is an unsupported research and presented for you general interest only.

There are three main parts.

* [reaping](reaping/README.md) handles download of raw scene files from USGS.
* _threshing_ extracts the NDVI and EVI layers from the raw scenes, removes the clouded areas, reprojects and saves the digested layers.
* _baking_ combines the digested layers into different products for analysis

## con jobs

May nee virtual frame buffer for graphic things
http://www.itgo.me/a/193895636550551095/how-to-run-r-on-a-server-without-x11-and-avoid-broken-dependencies


# should be run once a week to update the list of available scenes.
# uses the dir names in the landsat-data/raw dir to know which scenes we are interested in
# so if you change those best to run this again or wait a week till it goes.
* * * * * cd /var/landsat/landsat-veg-harvester && R CMD BATCH reaping/update_available_scenes.R 2>&1

# takes the next 1 scene needed and puts in a request for them 
# run every hour?
* * * * * cd /var/landsat/landsat-veg-harvester && R CMD BATCH reaping/request_missing_scenes.R 2>&1

# requests the results of orders run once a day about 12 hours after orders placed
* * * * * cd /var/landsat/landsat-veg-harvester && R CMD BATCH reaping/download_ordered_scenes.R 2>&1

# extract the veg layers
* * * * * cd /var/landsat/landsat-veg-harvester && R CMD BATCH threshing/extract_veg_indices.R 2>&1
