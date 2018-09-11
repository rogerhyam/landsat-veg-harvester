# How different are winter green are winter green 

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)

sql = "
SELECT 
    w.ndvi_avg as winters_ndvi,
    s.ndvi_avg as summers_ndvi,
    abs(sea.ndvi_avg) as seasons_ndvi,
    w.*
FROM
  results_seasons_100 as sea
JOIN
  results_summers_100 as s on s.Data_Zone = sea.Data_Zone
JOIN
  results_winters_100 as w on s.Data_Zone = w.Data_Zone
#JOIN  pure_urban_1_data_zones as urban on s.Data_Zone = urban.DataZone2011Code
;"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df) <- res_df$Data_Zone
#res_df$greenness <- as.factor(res_df$greenness)

#model <- lm(simd_rank.c ~ greenness, data = res_df)
#summary(model)$coef

model <- lm(seasons_ndvi ~ winters_ndvi + summers_ndvi + simd_rank, data = res_df)
summary(model)$coef

plot(res_df$winters_ndvi, res_df$seasons_ndvi)

plot(res_df$summers_ndvi, res_df$seasons_ndvi)

plot(res_df$summers_ndvi, res_df$winters_ndvi)

cor.test(res_df$seasons_ndvi, res_df$winters_ndvi)
cor.test(res_df$seasons_ndvi, res_df$summers_ndvi)

#model <- lm(winters_ndvi ~ summers_ndvi + seasons_ndvi, data = res_df)
#summary(model)$coef


dbDisconnect(mydb)

summary(res_df)