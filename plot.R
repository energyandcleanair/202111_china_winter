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
  

}