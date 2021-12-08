if(!require(remotes)){install.packages("remotes"); library(remotes)}
if(!require(tidyverse)){install.packages("tidyverse"); library(tidyverse)}

library(magrittr)
library(lubridate)
library(zoo)
library(readxl)

remotes::install_github("energyandcleanair/rcrea", force=F, upgrade=F)
library(rcrea)

Sys.setenv("TZ"="Etc/UTC");

# Creating result directories
folder <- {tmp_dir} # Used in rpy2, replaced by a temporary folder
setwd(folder)

dir.create("results", showWarnings=F)


# Export cities.geojson
cities <- rcrea::cities(country='CN', source='mee', with_geometry = T)
stationkey <- read.csv("https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/data/stationkey_joined.csv", encoding='UTF-8')

stationkey %>% 
  group_by(name=CityEN, nameZH=City, keyregion=keyregion2018, Province, ProvinceZH) %>% 
  tally %>% 
  left_join(cities, .) -> cities

dest_file <- file.path(folder, "2022_winter_air_pollution_action_plan.xlsx")

download.file(url='https://raw.githubusercontent.com/energyandcleanair/202111_china_winter/master/data/1101_1Analysis_2021-2022_winter_air_pollution_action_plan.xlsx', destfile=dest_file)

read_xlsx(dest_file, skip=1) %>% mutate(poll='pm25') -> targets

names(targets)[1:13] <- c('city_no', 'nameZH', 'name', 'Province', 'keyregionZH', 'new_in_2022',
                          'target_ug', 'target_hpd', 'baseline_ug',
                          'baseline_hpd', 'baseline_dw_ug', 'target_perc', 'target_hpdchange')

# Export measurements.RDS
m <- rcrea::measurements(poll='pm25', source='mee', location_id=cities$id, deweathered=F, process="city_day_mad")

dw <- rcrea::measurements(poll='pm25', source='mee', location_id=cities$id, deweathered=T)

bind_rows(m, dw) %>% 
  filter(grepl('trend|city_day', process_id)) %>% 
  mutate(value_type='measured') ->
  meas

# saveRDS(meas, 'measurements.RDS')
# meas <- readRDS('measurements.RDS')
meas %<>% rename(name=location_name) %>% left_join(cities)

#calculate targets
cities %<>% left_join(targets %>% select(-nameZH))

winter_20.21_dates = seq.Date(ymd("2020-10-01"), ymd("2021-03-31"), by='d')
summer_2021_dates = seq.Date(ymd("2021-04-01"), ymd("2021-09-30"), by='d')
meas %>% 
  mutate(across(date,lubridate::date),
         period = case_when(date %in% winter_20.21_dates~"winter 2020-21",
                            date %in% summer_2021_dates~"summer 2021")) %>% 
  group_by(name, Province, period, process_id) %>% 
  summarise(across(value, mean, na.rm=T)) %>% 
  left_join(cities) %>% 
  filter(!is.na(period), !is.na(target_perc)) %>% 
  group_by(name, Province, keyregion, n, process_id) %>% 
  summarise(value = value[period=="winter 2020-21"] * length(winter_20.21_dates)/365 * (1+target_perc) + 
              value[period=="summer 2021"] * length(summer_2021_dates)/365) %>% filter(!is.na(value)) %>% distinct %>% 
  mutate(value_type = 'winter target', date = ymd('2022-03-31'), poll='pm25') ->
  targetvalues

#keyregion averages
meas %>% bind_rows(targetvalues) %>% 
  filter(!is.na(keyregion), keyregion != 'none') %>% 
  group_by(area = keyregion, poll, date, process_id, value_type) %>% 
  summarise(value=weighted.mean(value,  w=n)) ->
  meas_reg

#city averages
meas %>% bind_rows(targetvalues) %>% 
  inner_join(targets %>% select(Province, name)) %>% 
  group_by(area=name, poll, date, process_id, value_type) %>% 
  summarise(across(value, mean)) %>% 
  bind_rows(meas_reg) ->
  meas_reg

meas %>% 
  group_by(poll, date, process_id) %>% 
  summarise(across(value, mean)) %>% 
  mutate(area='National', value_type=) %>% 
  bind_rows(meas_reg) ->
  meas_reg

mean.maxna <- function (x, maxna){
  if (sum(is.na(x)) > maxna){
    return(NA)
  }else{
    return(mean(x, na.rm = T))
  }
}

na.cover <- function(x, x.new){
  ifelse(is.na(x), x.new, x)
}

meas_reg %<>% 
  group_by(area, process_id, value_type, poll) %>% 
  arrange(date) %>% 
  mutate(value365=rollapplyr(value, 365, mean.maxna, maxna=30, fill=NA)) %>% 
  mutate(process_name = case_when(grepl('trend', process_id)~'weather-controlled trend',
                                  grepl('city_day', process_id)~'measured concentrations',
                                  T~process_id))

meas_reg %>% filter(value_type=='measured' & date(date)=='2021-09-30' | value_type=='winter target') %>% 
  mutate(value_type='winter target', value365 = na.cover(value365, value),
         label='path to target') -> targetpaths

regions_with_targets <- targetpaths %>% filter(area %in% unique(meas$keyregion), year(date)==2022) %>% 
  use_series(area) %>% unique

for(process_to_plot in unique(meas_reg$process_name)) {
  for(region_to_plot in c('China', 'Fenwei', '2+26')) {
    areas_to_plot = na.omit(cities$name[cities$keyregion==region_to_plot])
    if(region_to_plot=='China') areas_to_plot = regions_with_targets
    
    if(length(areas_to_plot)>0){
      
      meas_reg %>% mutate(label='historical data') %>% 
        filter(!is.na(value365), date>='2020-01-01',
               area %in% areas_to_plot,
               process_name==process_to_plot) %>% 
        ggplot(aes(date, value365, col=label, linetype=label)) + 
        geom_line(size=1) + 
        geom_line(data=targetpaths %>% filter(area %in% areas_to_plot,
                                              process_name==process_to_plot), 
                  size=1) +
        geom_point(data=targetpaths %>% filter(year(date)==2022, area %in% areas_to_plot,
                                               process_name==process_to_plot)) +
        facet_wrap(~area) +
        theme_crea() +
        expand_limits(y=0) + 
        scale_color_crea_d('dramatic', col.index=c(2,1)) +
        scale_x_datetime(date_breaks = '1 year', date_labels='%Y') +
        guides(col=guide_legend(nrow=1, title=''),
               linetype=guide_legend(nrow=1, title='')) +
        labs(title=paste('PM2.5 trends in', region_to_plot),
             subtitle=paste0('12-month moving average', 
                             ifelse(process_to_plot=='measured concentrations', '', ', weather-concentrolled')), 
             x='', y='µg/m3') +
        theme(legend.position = 'top')
      
      ggsave(file.path('results/', paste0('PM25 trends, ', region_to_plot, ', ', process_to_plot, '.png')))
      
    }
  }
}









