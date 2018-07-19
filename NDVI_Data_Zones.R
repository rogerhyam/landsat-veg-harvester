# calculate the correlation NDVI to various

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

res <- dbSendQuery(mydb, "SELECT * FROM results_summers_500")
res_df <- dbFetch(res, n = -1)
dbClearResult(res)


cor.test(x=res_df$ndvi_avg, y=res_df$simd_rank)