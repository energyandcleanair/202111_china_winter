library(remotes)
remotes::install_github("energyandcleanair/creadeweather", force=F, upgrade=F, dependencies=F)
library(creadeweather)

Sys.setenv("TZ"="Etc/UTC")

creadeweather::deweather(source='mee', city=c("Beijing","Shanghai"), poll='pm25', process_id='city_day_mad', output=c("trend","anomaly"))
