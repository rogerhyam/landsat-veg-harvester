# the 12% problem
# is there a distinct difference in mortality / depression between top and bottom quintiles of NDVI.

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)

sql = "select *, concat_ws('-', 'G', quintile_p) as greenness
from results_seasons_100 as ndvi
where quintile_p = 4 or quintile_p = 5
"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

dbDisconnect(mydb)

row.names(res_df) <- res_df$Data_Zone
res_df$greenness <- as.factor(res_df$greenness)

# centre  to make the units make sense - i think.
simd_rank.c <- scale(res_df$simd_rank, center=TRUE, scale=FALSE)
mortality.c <- scale(res_df$mortality, center=TRUE, scale=FALSE)
depression.c <- scale(res_df$depression, center=TRUE, scale=FALSE)
new.c.vars <- cbind(simd_rank.c, mortality.c, depression.c)
res_df <- cbind(res_df, new.c.vars)
names(res_df)[14:16] = c("simd_rank.c", "mortality.c", "depression.c" )

#model <- lm(simd_rank.c ~ greenness, data = res_df)
#summary(model)$coef

#model <- lm(mortality.c ~ greenness + simd_rank.c, data = res_df)
#summary(model)$coef

model <- lm(depression.c ~ greenness + simd_rank.c, data = res_df)
summary(model)$coef


#summary(res_df)


