# calculate the correlation NDVI to various

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

res <- dbSendQuery(mydb, "SELECT * FROM results_winters_100 join pure_urban_1_data_zones on Data_Zone = DataZone2011Code")
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

cor.test(x=res_df$ndvi_avg, y=res_df$simd_rank)
cor.test(x=res_df$ndvi_avg, y=res_df$mortality)
cor.test(x=res_df$ndvi_avg, y=res_df$depression)

loess_fit <- loess(ndvi_avg ~ simd_rank, res_df)

fit <- lm(ndvi_avg~depression-simd_rank, data=res_df)


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

# create table pure_urban_1_data_zones
# 
# select  distinct(DataZone2011Code)
# 
# from SmallUserPostcodes
# 
# where DataZone2011Code  not in (
#   
#   SELECT DataZone2011Code
#   FROM greenery.SmallUserPostcodes as pc
#   where pc.UrbanRural8Fold2013_2014Code > 1
#   
# )

# create table results_seasons_500
# select 
# s1.Data_Zone, 
# s1.sample_point_count, 
# s1.ndvi_avg, 
# simd.Overall_SIMD16_rank as simd_rank, 
# i.SMR as mortality, 
# cast(replace(DEPRESS, "%", '') as signed)/100 as depression, 
# i.Total_population
# FROM 
# (
#   Select 
#   pc.DataZone2011Code as Data_Zone,
#   count(*) as sample_point_count,
#   avg(difference_ndvi) as ndvi_avg
#   FROM 
#   samples_season_difference as s
#   JOIN
#   SmallUserPostcodes as pc on s.postcode = pc.Postcode
#   JOIN
#   SIMD16 as simd on simd.Data_Zone = pc.DataZone2011Code
#   WHERE
#   s.buffer_size = 500
#   AND
#   s.pixel_coverage >= 0.95
#   GROUP BY
#   pc.DataZone2011Code
# ) as s1
# JOIN 
# SIMD16 simd ON simd.Data_Zone = s1.Data_Zone
# JOIN
# simd16_indicator_data AS i ON i.Data_Zone = s1.Data_Zone
# order by i.DEPRESS desc

# ALTER TABLE  `results_winters_500` 
# ADD COLUMN `rank` INT NULL AFTER `Total_population`,
# ADD COLUMN `quintile` INT NULL AFTER `rank`;
# 
# SET @rownr=-1;
# 
# SET @fifth = (select count(*)/5 from `results_winters_500`);
# 
# UPDATE  `results_winters_500` 
# set rank = @rownr:=@rownr+1, quintile =  floor(@rownr/@fifth) + 1
# order by ndvi_avg