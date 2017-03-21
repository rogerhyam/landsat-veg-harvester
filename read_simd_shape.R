# read the shape file in
simd.shp <- rgdal::readOGR(dsn = paste(DATA_DIR, "simd", "SG_SIMD_2016", sep = "/"), layer = "SG_SIMD_2016")

# need to reproject the shape file to lon/lat as that is what the rasters are in
# "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
simd.shp.wgs <- spTransform(simd.shp, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

# add the polygon for each datazone to the end of a dataframe to make iteration easier
my.df <- simd.shp.wgs@data
my.df$smid_polygon <- simd.shp.wgs@polygons

# save this to a file..


t <- simd.shp@polygons[[1]]@Polygons
plot(t[[1]]@coords)


# explanation of creating crop of area https://stat.ethz.ch/pipermail/r-sig-geo/2012-June/015274.html


# looking for overlapping rasters
# creating and extent for your box in lon/lat goes 
# extent(minLon, maxLon, minLat, maxLat)
# e.g.extent(-4.045384, -0.1114924, 54.79117, 56.99756)

# check if overlap with intersect - result is NULL or the area of overlap
intersect(my.extent, ndvi_raster)

if(!is.null(intersect(my.extent, ndvi_raster))){
  # We found an overlapping raster...
  
}

extent(0, 20, 0, 20)




