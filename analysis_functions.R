# functions used in running the analysis


get_ndvi_by_decile <- function(stack_name, buffer_size){
  
  sql <- sprintf("select s.ndvi_average as ndvi, d.decile
  from SmallUserPostcodes as pc
  join samples as s on pc.Postcode = s.postcode
  join SIMD16 as simd on pc.DataZone2011Code = simd.Data_Zone
  join simd_decile as d on d.rank = simd.Overall_SIMD16_rank
  where stack_name like '%s'
  and length(pc.DateOfDeletion) < 1
  and buffer_size = %i", stack_name, buffer_size)
  
  res <- dbSendQuery(mydb, sql)
  ndvi_data <- dbFetch(res, n = -1)
  
  # convert deciles to factors
  ndvi_data$decile <- as.factor(ndvi_data$decile)

  return(ndvi_data)
  
}
