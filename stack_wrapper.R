source('config.R')
source('sampling_functions.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

#months <- c("2014/04","2014/05","2014/06","2014/07","2014/08","2014/09","2015/04","2015/05","2015/06","2015/07","2015/08","2015/09","2016/06","2016/05","2016/06","2016/07","2016/08","2016/09")
months <- c("2013/10","2013/11","2013/12","2014/01","2014/02","2014/03","2014/10","2014/11","2014/12","2015/01","2015/02","2015/03","2015/10","2015/11","2015/12","2016/01","2016/02","2016/03")
create_stack_cache(stack_name = 'winters_13_16', month_paths = months)
