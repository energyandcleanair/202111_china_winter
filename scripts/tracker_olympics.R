if(!require(remotes)){install.packages("remotes"); library(remotes)}
if(!require(tidyverse)){install.packages("tidyverse"); library(tidyverse)}
remotes::install_github("energyandcleanair/creadeweather", force=F, upgrade=F, dependencies=F)
library(creadeweather)

Sys.setenv("TZ"="Etc/UTC");

# Creating result directories
folder <- {tmp_dir} # Used in rpy2, replaced by a temporary folder
setwd(folder)

dir.create("results", showWarnings=F)

plot_olympics_anomaly <- function(city, poll, folder, filename){
  
  cities <- rcrea::cities()
  
  # Olympics data
  m <- creadeweather::deweather(source='mee',
                                city=city,
                                poll=poll,
                                process_id='city_day_mad',
                                output=c("anomaly"),
                                training_end_anomaly = "2021-06-01",
                                upload_results = F)
  
  m.plot <- m %>%
    filter(output=="anomaly") %>%
    tidyr::unnest(normalised) %>%
    select(location_id, source, poll, output, date, value) %>%
    rcrea::utils.running_average(7) %>%
    left_join(cities %>% select(location_id=id, location_name=name))
  
  maxabs <- max(abs(m.plot$value), na.rm=T)
  chg_colors <- c("#35416C", "#8CC9D0", "darkgray", "#CC0000", "#990000")
  
  ggplot(m.plot) +
    geom_line(aes(date, value, col=value), size=0.6) +
    facet_grid(location_name ~ rcrea::poll_str(poll)) +
    rcrea::theme_crea() +
    geom_hline(yintercept=0) +
    labs(title=sprintf("%s concentration anomaly in %s", rcrea::poll_str(poll), city),
         subtitle="7-day running average",
         caption=sprintf("Source: CREA analysis based on MEE data. Last updated on %s.",
                         strftime(max(m.plot$date, na.rm=T),"%d %B %Y")),
         y="Anomaly [µg/m3]",
         x=NULL) +
    scale_x_datetime(date_breaks = "3 month", date_minor_breaks = "1 month",
                     date_labels = "%b %Y") +
    theme(panel.grid.major.x = element_line(color="#CACACA", size=0.3),
          panel.grid.minor.x = element_line(color="#DEDEDE", size=0.3)) +
    scale_color_gradientn(colors = chg_colors, guide = "none", limits=c(-maxabs,maxabs))
  
  ggsave(file.path(folder, filename), width=10, height=6)
}


plot_olympics_anomaly(city="Zhangjiakou", poll="no2", folder="results", filename="olympics_zhangjiakou_no2.jpg")
plot_olympics_anomaly(city="Beijing", poll="no2", folder="results", filename="olympics_zhangjiakou_no2.jpg")
plot_olympics_anomaly(city=c("Beijing","Zhangjiakou"), poll=c("no2","pm25"), folder="results", filename="olympics_beijing_zhangjiakou_no2_pm25.jpg")
plot_olympics_anomaly(city=c("Beijing","Zhangjiakou"), poll=c("no2"), folder="results", filename="olympics_beijing_zhangjiakou_no2.jpg")