# Checking 12% difference between max and min NDVI as per James et al.

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql <- "SELECT
	*
FROM 
results_summers_250
join pure_urban_1_data_zones on Data_Zone = DataZone2011Code
order by ndvi_avg desc
limit 450"

res <- dbSendQuery(mydb, sql)
res_df_Q5 <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df_Q5) <- res_df_Q5$Data_Zone

summary(res_df_Q5)

sql <- "SELECT
	*
FROM 
results_summers_250
join pure_urban_1_data_zones on Data_Zone = DataZone2011Code
order by ndvi_avg asc
limit 450"

res <- dbSendQuery(mydb, sql)
res_df_Q1 <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df_Q1) <- res_df_Q1$Data_Zone

summary(res_df_Q1)

# t.test(res_df_Q1$mortality,res_df_Q5$mortality, alternative = c("two.sided"))

t.test(res_df_Q1$mortality,res_df_Q5$mortality)
t.test(res_df_Q1$depression,res_df_Q5$depression)
t.test(res_df_Q1$simd_rank,res_df_Q5$simd_rank)