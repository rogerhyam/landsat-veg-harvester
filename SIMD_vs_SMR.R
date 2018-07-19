
# calculate the correlation of overall simd rank to standardised mortality

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql = "SELECT 
	simd.Overall_SIMD16_rank as simd, i.SMR as smr
FROM 
greenery.simd16_indicator_data as i
JOIN 
greenery.SIMD16 as simd on simd.Data_Zone = i.Data_Zone
order by simd"

res <- dbSendQuery(mydb, sql)
simd_smr <- dbFetch(res, n = -1)
dbClearResult(res)


cor.test(x=simd_smr$simd, y=simd_smr$smr)