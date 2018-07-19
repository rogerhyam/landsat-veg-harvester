# calculate the correlation of SMR against NDVI

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql = "SELECT 
	i.SMR as smr, s.ndvi_average
FROM 
greenery.simd16_indicator_data as i
JOIN 
greenery.SmallUserPostcodes as pc on pc.DataZone2011Code = i.Data_Zone
JOIN
greenery.samples as s on s.postcode = pc.Postcode
WHERE
s.buffer_size = 100
AND
s.stack_name = 'winters_13_16'"

res <- dbSendQuery(mydb, sql)
smr_ndvi <- dbFetch(res, n = -1)
dbClearResult(res)


cor.test(x=smr_ndvi$ndvi, y=smr_ndvi$smr)