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
cities <- rcrea::cities(source='mee', with_geometry = T,
name=c("Beijing", "Tianjin", "Shijiazhuang", "Tangshan", "Qinhuangdao", "Handan", "Xingtai", "Baoding", "Zhangjiakou",
       "Chengde", "Cangzhou", "Langfang", "Hengshui", "Xiong'an", "Dingzhou", "Xinji", "Taiyuan", "Yangquan", "Changzhi", "Jincheng",
       "Datong", "Shuozhou", "Jinzhong", "Yuncheng", "Xinzhou", "Linfen", "Luliang", "Jinan", "Zibo", "Zaozhuang", "Dongying", "Weifang",
       "Jining", "Taian", "Rizhao", "Linyi", "Dezhou", "Liaocheng", "Binzhou", "Heze", "Zhengzhou", "Kaifeng", "Luoyang", "Pingdingshan",
       "Anyang", "Hebi", "Xinxiang", "Jiaozuo", "Puyang", "Xuchang", "Luohe", "Sanmenxia", "Nanyang", "Shangqiu", "Xinyang", "Zhoukou",
       "Zhumadian", "Jiyuan", "Xi'an", "Tongchuan", "Baoji", "Xianyang", "Weinan", "Hancheng")
)

file_cities <- file.path(folder, "cities.geojson")
if(file.exists(file_cities)) file.remove(file_cities)
sf::st_as_sf(cities) %>% sf::write_sf(file_cities)


# Export measurements.csv
meas <- rcrea::measurements(source='mee', poll="pm25", date_from="2020-01-01", location_id=cities$id) %>%
  rcrea::utils.running_average(14)

file_meas <- file.path(folder, "measurements.csv")
readr::write_csv(meas, file_meas)  
