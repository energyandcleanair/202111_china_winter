library(creadeweather)


stations <- rcrea::locations(source="mee", level="station")

m.dew <- creadeweather::deweather(source='mee', city="Beijing",
                                  poll=c('pm25','no2'),
                                  process_id='city_day_mad',
                                  output=c("anomaly"),
                                  training_end_anomaly = "2021-12-31")
