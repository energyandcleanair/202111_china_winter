if(!require(remotes)){install.packages("remotes"); require(remotes)}
if(!require(tidyverse)){install.packages("tidyverse"); require(tidyverse)}
require(tidyverse)

remotes::install_github("energyandcleanair/rcrea", force=T, upgrade=T, dependencies=F)
library(rcrea)
Sys.setenv("TZ"="Etc/UTC"); #https://github.com/rocker-org/rocker-versioned/issues/89


# Parameters (filled in python engine)  -----------------------------------
folder <-  "output"
dir.create(folder, showWarnings = F)

# Export cities.geojson
cities <- rcrea::cities(source='mee', with_geometry = T)
file_cities <- file.path(folder, "cities.geojson")
if(file.exists(file_cities)) file.remove(file_cities)
sf::st_as_sf(cities) %>% sf::write_sf(file_cities)


# Export measurements.csv
meas <- rcrea::measurements(source='mee', poll="pm25", date_from="2020-01-01", process_id='city_day_mad') %>%
  rcrea::utils.running_average(14)
file_meas <- file.path(folder, "measurements.csv")
write_csv(meas, file_meas)  