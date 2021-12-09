plot <- function(meas, areas_to_plot, process_to_plot, targetpaths){
  
  m_plot <- meas_reg %>% mutate(label='historical data') %>% 
    filter(!is.na(value365), date>='2020-01-01',
           area %in% areas_to_plot,
           process_name==process_to_plot)
  
  split(m_plot, m_plot$area) %>%
    lapply(function(m){
      plot_ly(m, x = ~date, y = ~value365, color = ~label, linetype=~label, mode="lines", type = "scatter",
              legendgroup='group1',
              showlegend=area) %>%
        add_lines(data=targetpaths %>%
                    filter(area %in% unique(m$area),
                           process_name==process_to_plot),
                  x=~date,
                  y=~value365) %>%
        layout(
          yaxis=list(rangemode="tozero"),
          legend=list(orientation = 'h',
                      xanchor = "center",  # use center of legend as anchor
                      x = 0.5,
                      y=1.1)
        )
    }) %>%
    subplot(nrows = 1, shareX = TRUE, shareY = TRUE)
  
  
  
  
    (plt <- ggplot(m_plot, aes(date, value365, col=label, linetype=label)) + 
    geom_line(size=1) + 
    geom_line(data=targetpaths %>% filter(area %in% areas_to_plot,
                                          process_name==process_to_plot), 
              size=1) +
    geom_point(data=targetpaths %>% filter(year(date)==2022, area %in% areas_to_plot,
                                           process_name==process_to_plot)) +
    facet_wrap(~area) +
    theme_crea() +
    theme(text=element_text(family="Arial")) +
    expand_limits(y=0) + 
    scale_color_crea_d('dramatic', col.index=c(2,1)) +
    scale_x_datetime(date_breaks = '1 year', date_labels='%Y') +
    scale_y_continuous(limits=c(0,NA), expand=expansion(mult=c(0, 0.1))) +
    guides(col=guide_legend(nrow=1, title=''),
           linetype=guide_legend(nrow=1, title='')) +
    labs(title=paste('PM2.5 trends in', region_to_plot),
         subtitle=paste0('12-month moving average', 
                         ifelse(process_to_plot=='measured concentrations', '', ', weather-concentrolled')), 
         x='', y='µg/m3') +
    theme(legend.position = 'top',
          plot.title = element_text(margin=margin(0,0,300,0))))
    
    gp <- ggplotly(plt)  %>%
      layout(
        yaxis=list(rangemode="tozero"),
        legend=list(orientation = 'h',
                         xanchor = "center",  # use center of legend as anchor
                         x = 0.5,
                         y=1.12),
        
        title=list(
          y=0.5,
          pad=list(b=200,t=200)
        ))

    gp      
}