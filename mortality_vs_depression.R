# how are depression and mortality related in urban areas?

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)

# all the results tables have the same info in them
sql = "SELECT * FROM greenery.results_seasons_250  where mortality <250;"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)
dbDisconnect(mydb)

cor.test(x=res_df$mortality, y=res_df$depression)

plot(x=res_df$mortality, y=res_df$depression)