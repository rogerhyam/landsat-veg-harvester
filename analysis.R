
# Repeatable analysis
source('config.R')
source('analysis_functions.R')

# get a global scope db connection to use
mydb = dbConnect(MySQL(), user=DB_USER, password=DB_PASSWORD, dbname=DB_DATABASE, host=DB_HOST)
on.exit(dbDisconnect(mydb))

ndvi_decile <- get_ndvi_by_decile('summers_14_16', 500)
boxplot(ndvi~decile, data = ndvi_decile)
ndvi_anova <- aov(ndvi~decile, data = ndvi_decile)
summary(ndvi_anova)
boxplot(ndvi~decile, data = ndvi_anova)
plot(TukeyHSD(ndvi_anova, ordered = TRUE), las=1)
print(TukeyHSD(ndvi_anova, ordered = TRUE))