# summer vs winter ndvi


source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql <- "select s.Data_Zone, s.ndvi_avg as summer_ndvi, w.ndvi_avg as winter_ndvi, s.depression, s.mortality, s.simd_rank,  s.sample_point_count, s.Total_population
from results_summers_250 as s join results_winters_250 as w on s.Data_Zone = w.Data_Zone"

sql <- "select s.Data_Zone, s.ndvi_avg as summer_ndvi, w.ndvi_avg as winter_ndvi, s.depression, s.mortality, s.simd_rank,  s.sample_point_count, s.Total_population
from 
	results_summers_100 as s 
join 
	results_winters_100 as w on s.Data_Zone = w.Data_Zone
join 
	pure_urban_1_data_zones as pure on pure.DataZone2011Code = s.Data_Zone

where s.simd_rank > 6000

"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

row.names(res_df) <- res_df$Data_Zone

res_df$colour = 'black'
res_df$colour[res_df$simd_rank < 500] = 'red'
res_df$colour[res_df$simd_rank > 6000] = 'blue'

plot(x = res_df$summer_ndvi, y = res_df$winter_ndvi, col = res_df$colour)

res_df$colour = 'black'
res_df$colour[res_df$mortality < 73] = 'blue'
res_df$colour[res_df$mortality > 127] = 'red'

res_df$symbol = 1
res_df$symbol[res_df$depression < 0.14] = 2
res_df$symbol[res_df$depression > 0.22] = 6

scatterplot3d(x = res_df$summer_ndvi, y = res_df$winter_ndvi, z=res_df$simd_rank, color=res_df$colour, pch = res_df$symbol)

scatterplot3d(y = res_df$depression, x = res_df$winter_ndvi, z=res_df$simd_rank, color=res_df$colour, pch = res_df$symbol)


scatterplot3d(x = res_df$summer_ndvi, y = res_df$winter_ndvi, z=res_df$depression)

plot(y = res_df$depression, x = res_df$winter_ndvi, main="Winter Greenness and Depression Weakly Correlate", 
     xlab="Winter Greenness", ylab="Depression Prescriptions", pch=1, col=res_df$colour)
abline(lm(res_df$depression~res_df$winter_ndvi), col="black") # regression line (y~x) 
#lines(lowess(res_df$winter_ndvi,res_df$depression), col="blue") # lowess line (x,y)

identify(res_df$winter_ndvi, res_df$depression,  labels=row.names(res_df))

cor.test(x=(res_df$summer_ndvi - res_df$winter_ndvi), y=res_df$depression)

cor.test(x=res_df$winter_ndvi, y=res_df$depression)

pcor.test(x=res_df$winter_ndvi, y=res_df$depression, z=res_df$simd_rank)

t.test(res_df$summer_ndvi,res_df$winter_ndvi, paired = TRUE, alternative = c("two.sided"))

