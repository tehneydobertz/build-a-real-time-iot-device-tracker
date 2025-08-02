# Load necessary libraries
library(shiny)
library(leaflet)
library(dplyr)
library(tidyr)
library(readr)

# Set up connection to IoT device tracking database
con <- dbConnect(RPostgres::Postgres(),
                  dbname = "iot_tracker",
                  host = "localhost",
                  port = 5432,
                  user = "iot_user",
                  password = "iot_password")

# Create a reactive Shiny Server function
shinyServer(function(input, output, session) {
  
  # Fetch new data from database every 5 seconds
  data <- reactive({
    invalidateLater(5000)
    query <- "SELECT * FROM iot_devices WHERE timestamp > NOW() - INTERVAL '1 minute'"
    dbGetQuery(con, query)
  })
  
  # Create a leaflet map output
  output$map <- renderLeaflet({
    leaflet() %>% 
      setView(lng = 0, lat = 0, zoom_start = 4) %>% 
      addTiles() %>% 
      addMarkers(lng = data()$longitude, lat = data()$latitude)
  })
  
  # Create a table output
  output$table <- renderTable({
    data() %>% 
      arrange(desc(timestamp)) %>% 
      select(device_id, longitude, latitude, timestamp)
  })
  
})

# Create a Shiny UI
ui <- fluidPage(
  titlePanel("Real-time IoT Device Tracker"),
  sidebarLayout(
    sidebarPanel(
      h3("Devices"),
      textOutput("device_count")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", leafletOutput("map")),
        tabPanel("Table", tableOutput("table"))
      )
    )
  )
)

# Run the Shiny app
shinyApp(ui = ui, server = shinyServer)