source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)

results <- data.frame(c('stack', 'buffer', 'cor'))


get_correlations(100, 'summers_14_16')
get_correlations(250, 'summers_14_16')
get_correlations(500, 'summers_14_16')
get_correlations(100, 'winters_13_16')
get_correlations(250, 'winters_13_16')
get_correlations(500, 'winters_13_16')

get_correlations <- function(buffer_size, stack){
  
  sql <- sprintf("select pc.postcode, s.ndvi_average, cast(pc.CensusPopulationCount2011 as UNSIGNED) as pop_count,  cast(pc.CensusHouseholdCount2011 as UNSIGNED) as household_count
	from SmallUserPostcodes as pc
  join samples as s on pc.Postcode = s.postcode
  where pc.UrbanRural8Fold2013_2014Code < 3 
  and length(pc.DateOfDeletion) < 1 
  and length(pc.CensusPopulationCount2011)  > 0 
  and s.buffer_size = %i
  and s.stack_name = '%s'
  order by household_count desc", buffer_size, stack);
  
  res <- dbSendQuery(mydb, sql)
  pop_ndvi <- dbFetch(res, n = -1)
  dbClearResult(res)
  
  pop_cor <- cor(x = pop_ndvi[["ndvi_average"]], y = pop_ndvi[["pop_count"]]);
  household_cor <- cor(x = pop_ndvi[["ndvi_average"]], y = pop_ndvi[["household_count"]]);
  
  sprintf("%i,%s,%f,%f", buffer_size, stack, pop_cor, household_cor)
  
}





