# summer vs winter ndvi


source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql <- "select s.Data_Zone, s.ndvi_avg as summer_ndvi, w.ndvi_avg as winter_ndvi, s.depression, s.mortality, s.simd_rank,  s.sample_point_count, s.Total_population
from results_summers_250 as s join results_winters_250 as w on s.Data_Zone = w.Data_Zone"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

res_df$colour = 'black'
res_df$colour[res_df$simd_rank < 1395] = 'red'
res_df$colour[res_df$simd_rank > 5580] = 'blue'

plot(x = res_df$summer_ndvi, y = res_df$winter_ndvi, col = res_df$colour)

res_df$colour = 'black'
res_df$colour[res_df$mortality < 73] = 'blue'
res_df$colour[res_df$mortality > 127] = 'red'

res_df$symbol = 1
res_df$symbol[res_df$depression < 0.14] = 2
res_df$symbol[res_df$depression > 0.22] = 6

scatterplot3d(x = res_df$summer_ndvi, y = res_df$winter_ndvi, z=res_df$simd_rank, color=res_df$colour, pch = res_df$symbol)

