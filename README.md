# landsat-veg-harvester
A project written in R for processing NDVI and EVI data from Landsat thanks to USGS

This is an unsupported research and presented for you general interest only.

There are three main parts.

* [reaping](reaping/README.md) handles download of raw scene files from USGS.
* _threshing_ extracts the NDVI and EVI layers from the raw scenes, removes the clouded areas, reprojects and saves the digested layers.
* _baking_ combines the digested layers into different products for analysis

