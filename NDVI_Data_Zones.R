# calculate the correlation NDVI to various

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

res <- dbSendQuery(mydb, "SELECT * FROM results_summers_500")
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

cor.test(x=res_df$ndvi_avg, y=res_df$simd_rank)
cor.test(x=res_df$ndvi_avg, y=res_df$mortality)
cor.test(x=res_df$ndvi_avg, y=res_df$depression)

loess_fit <- loess(ndvi_avg ~ simd_rank, res_df)


# create table results_winters_500
# select 
# s1.Data_Zone, 
# s1.sample_point_count, 
# s1.ndvi_avg, 
# s1.ndvi_std,  
# simd.Overall_SIMD16_rank as simd_rank, 
# i.SMR as mortality, 
# cast(replace(DEPRESS, "%", '') as signed)/100 as depression, 
# i.Total_population
# FROM 
# (
#   Select 
#   pc.DataZone2011Code as Data_Zone,
#   count(*) as sample_point_count,
#   avg(ndvi_average) as ndvi_avg,
#   std(ndvi_average) as ndvi_std
#   FROM 
#   samples as s
#   JOIN
#   SmallUserPostcodes as pc on s.postcode = pc.Postcode
#   JOIN
#   SIMD16 as simd on simd.Data_Zone = pc.DataZone2011Code
#   WHERE
#   s.buffer_size = 500
#   AND
#   s.stack_name = 'winters_13_16'
#   AND
#   s.pixels_not_na >= 0.95
#   GROUP BY
#   pc.DataZone2011Code
# ) as s1
# JOIN 
# SIMD16 simd ON simd.Data_Zone = s1.Data_Zone
# JOIN
# simd16_indicator_data AS i ON i.Data_Zone = s1.Data_Zone
# order by i.DEPRESS desc