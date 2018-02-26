
# doing a greenspace extraction from a shape file.

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

# load the shape file
shape_gs <- readOGR(dsn = "/Users/rogerhyam/Dropbox/RBGE/2018/Green_Deprivation/Green_Space_OS", layer = "Scotland")

# get the list of postcodes to scan
e <- extent(shape_gs)
sql = sprintf("SELECT postcode, GridReferenceEasting, GridReferenceNorthing
                FROM SmallUserPostcodes
              WHERE length(DateOfDeletion) = 0
              AND UrbanRural8Fold2013_2014Code < 3
              AND GridReferenceEasting > %f
              AND GridReferenceEasting < %f
              AND GridReferenceNorthing > %f
              AND GridReferenceNorthing < %f
              ", e@xmin, e@xmax, e@ymin, e@ymax)

res <- dbSendQuery(mydb, sql)
postcodes <- dbFetch(res, n = -1)
dbClearResult(res)

# work through them
start_t <- Sys.time()

for(row in 1:nrow(postcodes)){
  
  cat("\014")
  end_t <- Sys.time()
  rate <- round((as.numeric(end_t) - as.numeric(start_t))/row, 3)
  remaining_sec <- (nrow(postcodes) - row)*rate
  estimate <- end_t + remaining_sec
  
  print(paste(postcodes[row, "postcode"], row, nrow(postcodes),  rate, start_t, end_t, estimate, sep=" | "))
  
  # we are using the national grid as units are metres
  eastings <- postcodes[row, "GridReferenceEasting"]
  northings <- postcodes[row, "GridReferenceNorthing"]
  
  coords <- cbind(eastings, northings)
  
  # turn it into a spatial object of points
  postcode_point <- SpatialPoints(coords)
  proj4string(postcode_point) <- crs(shape_gs)
  
  # dataframe to build results into
  #out <- data.frame("postcode", "buffer_size","greenspace_area","buffer_area")
  
  out <- data.frame()
  
  # create biggest crop
  buffer_500_ogs <- gBuffer(postcode_point, width=500, byid=TRUE)
  suppressWarnings(i <- intersect(shape_gs, buffer_500_ogs))
  data.frame("SN" = 1:2, "Age" = c(21,15), "Name" = c("John","Dora"))
  if(!is.null(i)){
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      500,
      sum(area(i)),
      area(buffer_500_ogs)
    ))
  }else{
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      500,
      0,
      area(buffer_500_ogs)
    ))
  }
  
  buffer_250_ogs <- gBuffer(postcode_point, width=250, byid=TRUE)
  suppressWarnings(i <- intersect(shape_gs, buffer_250_ogs))
  if(!is.null(i)){
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      250,
      sum(area(i)),
      area(buffer_250_ogs)
    ))
  }else{
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      250,
      0,
      area(buffer_250_ogs)
    ))
  }
  
  
  buffer_100_ogs <- gBuffer(postcode_point, width=100, byid=TRUE)
  suppressWarnings(i <- intersect(shape_gs, buffer_100_ogs))
  if(!is.null(i)){
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      100,
      sum(area(i)),
      area(buffer_100_ogs)
    ))
  }else{
    out <- rbind(out,list(
      postcodes[row, "postcode"],
      100,
      0,
      area(buffer_100_ogs)
    ))
  }
  
  # finally save it
  colnames(out) <- c("postcode", "buffer_size","greenspace_area","buffer_area")
  dbWriteTable(mydb, "samples_greenspace", data.frame(out), append = TRUE)
  
}

# get the area of the intersecting polygons
# sum(area(buffer_500_ogs))
# 
# sum(area(i))
# 
# 
# coords <- cbind(325514, 672062)
# postcode_point <- SpatialPoints(coords)
# proj4string(postcode_point) <- crs(shape)
# buffer_500_ogs <- gBuffer( postcode_point, width=500, byid=TRUE)
# i <- intersect(shape, buffer_500_ogs)
# writeOGR(obj=i, dsn=".", layer="greenspace", driver="ESRI Shapefile")


