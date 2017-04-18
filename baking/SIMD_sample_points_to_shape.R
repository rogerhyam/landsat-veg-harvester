
# Create a shape file of the buffers around the sample points

# read in the 

source('config.R')
source('baking/functions.R')

crs_longlat <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
crs_os <- CRS("+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs")

# where is it
sample_point_csv <- paste(DATA_DIR, "/simd/SIMD_2016_sample_points.csv", sep="")
dir.create(paste(DATA_DIR, "/simd/SIMD_2016_sample_points", sep=""), showWarnings = FALSE)
sample_point_shp <- paste(DATA_DIR, "/simd/SIMD_2016_sample_points/SIMD_2016_sample_points.shp", sep="") 
sample_points <- read.csv(sample_point_csv)

polys <- NULL

for(i in 1:nrow(sample_points)) {
  
  row <- sample_points[i,]
  
  # coords <- cbind(row$Longitude,row$Latitude)

  # there seems to be an issue with gov supplied long lats so use Eastings, Northings and reproject
  coords <- cbind(row$Eastings,row$Northings)
  sp <- SpatialPoints(coords, proj4string = crs_os)
  sp2 <- spTransform(sp, crs_longlat)
  
  # get it as an extent
  e <- roi_get_buffer(sp2@coords, 500)
  
  # convert it to a polygon
  poly <- as(e, "SpatialPolygons")
  crs(poly) <- crs_longlat
  
  # give it a name so it doesn't clash
  poly@polygons[[1]]@ID <- paste(row$DataZone, "-", row$PostCode, sep = "")
  
  if(is.null(polys)){
    print("Poly is null")
    polys <- poly
  }else{
    print("Poly is not null")
    polys <- rbind(polys, poly);
  }
  
  if(i > 3) break
  
}

shapefile(polys, sample_point_shp, overwrite=TRUE)
