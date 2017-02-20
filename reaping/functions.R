# Common Functions used by the reaping scripts
# place an order
# returns json text if successful

usgs_place_order <- function(scene_ids){
  
 # build the object
  usgs_order_ob <- list(
    `olitirs8` = list(
      `inputs` = list(scene_ids),
      `products` = c("sr", "sr_ndvi", "sr_evi", "cloud")
    ),
    `format` = "gtiff", 
    `plot_statistics` = FALSE, 
    `projection` = list(`lonlat` = NULL),
    `note` = "From R Script usgs_place_order"
  )

  payload = toJSON(usgs_order_ob, pretty = TRUE, auto_unbox = TRUE, null = 'null')
  
  response <- POST(paste(USGS_API_URL, 'order', sep = ""),
                   body = payload,
                   authenticate(USGS_USER, USGS_PASSWORD) )
  warn_for_status(response)
  return(response);
  
}

# takes an order_id and fetches the status of that 
# order as a dataframe
usgs_get_status <- function(order_id){

  # call the service (we will get results for a bunch of scenes)
  response <- GET(paste(USGS_API_URL, 'item-status/', order_id, sep = ""), authenticate(USGS_USER, USGS_PASSWORD) )
  warn_for_status(response)
  if(response$status_code == 200){
    
    response_ob <- content(response, "parsed", "application/json")
    output <- NULL
    for(item in response_ob$orderid[[order_id]]){
      if(is.null(output)){
        output <- item
      }else{
        output <- rbind(output, item)
      }
    }
    return(output)
    
  }else{
    return(NULL)
  }

}

