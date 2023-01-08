#-----------------------------------------------------------------------------------------------------------------------------------------------------------
# PARAMETERS
AIRPORTS_DATA = "./airports.csv"
MAPBOX_TOKEN = "your_token"
AIRPORTS_COLOR = "white"
INCOMING_FLIGHTS = "mediumblue"
OUTCOMING_FLIGHTS = "deepskyblue"
CORSICAN_FLIGHTS = "red"
#-----------------------------------------------------------------------------------------------------------------------------------------------------------


library(rvest)
library(dplyr)
library(plyr)
library(magrittr)
library(stringr)
library(plotly)
library(shiny)
library(ggmap)




# SHINY FRONT-END
ui = fillPage(
  tags$style(HTML(".control-label {color: white};")),
  tags$style(HTML("body {background-color: #191a1a};")),
  title = "R Flight Data app",
  titlePanel(
    h1(" Real-Time Flight Data Visualisation app ", align="center", style="color: white")
    ),
  h3("Displays all the current flights of Air France airline, all around the world", align = "center", style = "color: white"),
  plotlyOutput("plot", width = "100%", height = "85%"),
  h5("Airports size is weighted according to AF traffic. Just fly over flights and airports to see informations", align = "center", style = "color: white"),
  h5("Flights data is from flightaware.com", align = "center", style = "color: white")
)

# SHINY BACK-END
server = function(input, output) {
  
  # load the airports locations
  airports = read.csv(AIRPORTS_DATA)
  french_airports = dplyr::filter(airports, type == "large_airport" | type == "medium_airport" | type == "small_aiport") %>%
    dplyr::filter(iso_country == "FR") %>%
    dplyr::select(ident)
  corsican_airports = dplyr::filter(airports, type == "large_airport" | type == "medium_airport" | type == "small_aiport") %>%
    dplyr::filter(iso_region == "FR-H") %>%
    dplyr::select(ident)
  airports = dplyr::filter(airports, type == "large_airport" | type == "medium_airport" | type == "small_aiport") %>%
    dplyr::select(ident, latitude_deg, longitude_deg)
  colnames(airports)[2] <- "latitude"
  colnames(airports)[3] <- "longitude"
  
  # get live flights for AFR 
  flights_page = read_html("https://fr.flightaware.com/live/fleet/AFR")
  last_page = FALSE
  loop_count = 0
  
  while( last_page==FALSE ){
    live_flights_html = flights_page %>% html_nodes(".prettyTable")
    live_flights_table = html_table(live_flights_html, fill = TRUE, header = TRUE)
    live_flights_df = data.frame(live_flights_table)
    if(nrow(live_flights_df) < 20 | loop_count == 2) {
      last_page = TRUE
    }
    if(loop_count == 0) {
      live_flights = live_flights_df
    } else {
      live_flights = rbind(live_flights, live_flights_df) 
    }
    next_page_url = flights_page %>% html_nodes(".fullWidth+ span a:nth-child(1)") %>% html_attr("href")
    flights_page = read_html(paste(flights_page,next_page_url))
    loop_count = loop_count + 1
  }
  
  colnames(live_flights) = as.character(unlist(live_flights[1,]))
  live_flights = live_flights[-1,1:6]
  
  # clean data to obtain only IACO airports codes
  live_flights = live_flights %>% mutate(Provenance = str_extract(Provenance, "[A-Z]{4}"))
  live_flights = live_flights %>% mutate(Destination = str_extract(Destination, "[A-Z]{4}"))
  live_flights =  live_flights %>% dplyr::filter(!(is.na(Provenance)))
  
  # from IACO, add Provenance and Destination coordinates
  live_airports = c(live_flights$Provenance, live_flights$Destination) %>% unique()
  live_airports = airports %>% dplyr::filter(ident %in% live_airports)
  live_airports = live_airports %>% mutate(ident = as.character(ident))
  long = live_airports$longitude
  lat = live_airports$latitude
  names(long) = live_airports$ident
  names(lat) = live_airports$ident
  
  # add the count of flights from/to the airports to size the markers according to frequentation
  destination_count = live_flights %>% dplyr::count(Destination) %>% arrange(desc(n))
  destination_cnt = destination_count$n
  names(destination_cnt) = destination_count$Destination
  provenance_count = live_flights %>% dplyr::count(Provenance) %>% arrange(desc(n))
  provenance_cnt = provenance_count$n
  names(provenance_cnt) = provenance_count$Provenance
  i = 1
  live_airports$count = rep.int(1, nrow(live_airports))
  while(i <= nrow(live_airports)){
    live_airports$count[i] = live_airports$count[i] + ifelse(is.na(provenance_cnt[live_airports$ident[i]]), 0, provenance_cnt[live_airports$ident[i]]) + ifelse(is.na(destination_cnt[live_airports$ident[i]]), 0, destination_cnt[live_airports$ident[i]])
    i = i + 1
  }
  
  
  live_flights$Provenance_long = live_flights$Provenance
  live_flights$Provenance_lat = live_flights$Provenance
  live_flights$Destination_long = live_flights$Destination
  live_flights$Destination_lat = live_flights$Destination
  live_flights = live_flights %>% mutate(Provenance_long = long[Provenance_long])
  live_flights = live_flights %>% mutate(Provenance_lat = lat[Provenance_lat])
  live_flights = live_flights %>% mutate(Destination_long = long[Destination_long])
  live_flights = live_flights %>% mutate(Destination_lat = lat[Destination_lat])
  
  # Add from_france dummy to color incoming and outcoming flights accordingly
  live_flights$from_france = live_flights$Provenance
  live_flights = live_flights %>% mutate(from_france = from_france %in% french_airports$ident)
  
  # Separate Corsican flights for color purposes as well
  live_flights$from_corsica = live_flights$Provenance
  live_flights = live_flights %>% mutate(from_corsica = from_corsica %in% corsican_airports$ident)
  live_flights$to_corsica = live_flights$Destination
  live_flights = live_flights %>% mutate(to_corsica = to_corsica %in% corsican_airports$ident)
  live_flights_corsican = live_flights %>% dplyr::filter(from_corsica == TRUE | to_corsica == TRUE)
  live_flights = live_flights %>% dplyr::filter(from_corsica == FALSE & to_corsica == FALSE)
  
  live_flights_outcoming = live_flights %>% dplyr::filter(from_france == TRUE)
  live_flights_incoming = live_flights %>% dplyr::filter(from_france == FALSE)
  
  # plot
  Sys.setenv(MAPBOX_TOKEN = 'pk.eyJ1IjoiYXoyMDkiLCJhIjoiY2w1cXQyMDhwMHg2OTNkbzMzMmM5NzJsYiJ9.saP33HFLalx4j-EvN4svNw')
  
  if(nrow(live_flights_corsican) > 0){
    output$plot <- renderPlotly({
      plot_mapbox(mode = 'scattermapbox') %>%
        layout(font = list(color='white'),
               plot_bgcolor = '#191A1A', paper_bgcolor = '#191A1A',
               mapbox = list(style = 'dark',
                             center = list(lat = 36.7538,lon = 3.0588),
                             zoom = 3),
               legend = list(orientation = 'h',
                             font = list(size = 14),
                             xanchor = "center",
                             yanchor = "top",
                             x = 0.5,
                             y = 0.1),
               margin = list(l = 25, r = 25,
                             t = 80, b = 80)) %>%
        add_trace(
          name = "Airports",
          hoverinfo = 'text',
          data = live_airports,
          text = ~ident,
          lon = ~longitude,
          lat = ~latitude,
          mode = "markers",
          marker = list(color = AIRPORTS_COLOR),
          opacity = 0.7,
          size = ~count
        ) %>%
        add_segments( 
          name = "Flights to France",
          data = live_flights_incoming,
          x = ~Provenance_long, xend = ~Destination_long,
          y = ~Provenance_lat, yend = ~Destination_lat,
          size = I(1), 
          hoverinfo = "text",
          text = ~`N° de vol`,
          line = list(color = INCOMING_FLIGHTS),
          opacity = 0.5
        ) %>%
        add_segments( 
          name = "Flights from France",
          data = live_flights_outcoming,
          x = ~Provenance_long, xend = ~Destination_long,
          y = ~Provenance_lat, yend = ~Destination_lat,
          size = I(1), 
          hoverinfo = "text",
          text = ~`N° de vol`,
          line = list(color = OUTCOMING_FLIGHTS),
          opacity = 0.5
        ) %>%
        add_segments( 
          name = "Corsican Flights",
          data = live_flights_corsican,
          x = ~Provenance_long, xend = ~Destination_long,
          y = ~Provenance_lat, yend = ~Destination_lat,
          size = I(1), 
          hoverinfo = "text",
          text = ~`N° de vol`,
          line = list(color = CORSICAN_FLIGHTS),
          opacity = 0.5
        )
    })
  } else {
    output$plot <- renderPlotly({
      plot_mapbox(mode = 'scattermapbox') %>%
        layout(font = list(color='white'),
               plot_bgcolor = '#191A1A', paper_bgcolor = '#191A1A',
               mapbox = list(style = 'dark',
                             center = list(lat = 36.7538,lon = 3.0588),
                             zoom = 3),
               legend = list(orientation = 'h',
                             font = list(size = 14),
                             xanchor = "center",
                             yanchor = "top",
                             x = 0.5,
                             y = 0.1),
               margin = list(l = 25, r = 25,
                             t = 80, b = 80)) %>%
        
        add_trace(
          name = "Airports",
          hoverinfo = 'text',
          data = live_airports,
          text = ~ident,
          lon = ~longitude,
          lat = ~latitude,
          mode = "markers",
          marker = list(color = AIRPORTS_COLOR),
          opacity = 0.7,
          size = ~count
        ) %>%
        add_segments( 
          name = "Flights to France",
          data = live_flights_incoming,
          x = ~Provenance_long, xend = ~Destination_long,
          y = ~Provenance_lat, yend = ~Destination_lat,
          size = I(1), 
          hoverinfo = "text",
          text = ~`N° de vol`,
          line = list(color = INCOMING_FLIGHTS),
          opacity = 0.5
        ) %>%
        add_segments( 
          name = "Flights from France",
          data = live_flights_outcoming,
          x = ~Provenance_long, xend = ~Destination_long,
          y = ~Provenance_lat, yend = ~Destination_lat,
          size = I(1), 
          hoverinfo = "text",
          text = ~`N° de vol`,
          line = list(color = OUTCOMING_FLIGHTS),
          opacity = 0.5
        )})
  }
}

shinyApp(ui, server)