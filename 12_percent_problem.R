# the 12% problem
# is there a distinct difference in mortality / depression between top and bottom quintiles of NDVI.

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql = "select *, concat_ws('-', 'G', quintile) as greenness
from results_winters_500 as ndvi 
join pure_urban_1_data_zones as urban on ndvi.Data_Zone = urban.DataZone2011Code
where quintile = 1 or quintile = 5
"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df) <- res_df$Data_Zone
res_df$greenness <- as.factor(res_df$greenness)

model <- lm(simd_rank ~ greenness, data = res_df)
summary(model)$coef

model <- lm(mortality ~ greenness - simd_rank, data = res_df)
summary(model)$coef

model <- lm(depression ~ greenness - simd_rank, data = res_df)
summary(model)$coef

#summary(res_df)