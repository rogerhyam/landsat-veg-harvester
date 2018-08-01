# calculate the correlation of overall simd rank to standardised mortality

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql = "SELECT

ndvi.*,
sp.sample_lon,
sp.sample_lat,
sp.distance,
i.calc_naturalness,
i.calc_artificialness,
i.evaluation_avg,
i.evaluation as evaluated,
i.path
FROM 
greenery.samples_natural_perception as ndvi
JOIN 
nat_image.sample_points as sp on sp.id = ndvi.sample_point_id 
JOIN
nat_image.image as i on sp.image_id = i.id
WHERE 
ndvi.stack_name = 'summers_14_16'
AND
ndvi.buffer_size = 500
AND ndvi.supress IS NULL
"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df) <- res_df$path

plot(y=res_df$calc_naturalness,x=res_df$ndvi_average)
identify(res_df$ndvi_average,res_df$evaluation_avg,  labels=row.names(res_df))

cor.test(y=res_df$calc_naturalness,x=res_df$ndvi_average)