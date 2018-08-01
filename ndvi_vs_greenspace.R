
# checking if grass changes NDVI during the winter

source('config.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

sql <- "SELECT  s.polygon_id, s.ndvi_average as summer, w.ndvi_average as winter
FROM samples_greenness_greenspace as s
join samples_greenness_greenspace as w on w.polygon_id = s.polygon_id
where s.stack_name = 'summers_14_16'
and w.stack_name = 'winters_13_16'
and s.buffer_size = 100
and w.buffer_size = 100
and s.gs_function = 'Religious Grounds'
and s.polygon_id not in (SELECT 
s2.polygon_id as pid
FROM samples_greenness_greenspace as s2
join samples_greenness_greenspace as w2 on w2.polygon_id = s2.polygon_id
where s2.stack_name = 'summers_14_16'
and w2.stack_name = 'winters_13_16'
and s2.buffer_size = 100
and w2.buffer_size = 100
and s2.gs_function = 'Religious Grounds'
group by s2.polygon_id
having count(*)  > 1)"

res <- dbSendQuery(mydb, sql)
res_df <- dbFetch(res, n = -1)
dbClearResult(res)

summary(res_df)

row.names(res_df) <- res_df$polygon_id

t.test(res_df$summer,res_df$winter, paired = TRUE, alternative = c("two.sided"))
