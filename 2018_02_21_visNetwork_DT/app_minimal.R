
source("global.R")

# read files 
nodes.df <- read_rds("data/nodes.Rds")
edges.df <- read_rds("data/edges.Rds") 
map.df <- read_rds("data/map.Rds")

# user interface
ui <- dashboardPage(
  dashboardHeader(title = "Known Associate AnalyzeR - R-meetup: Minimal", titleWidth = 800),
  
  dashboardSidebar(
    selectizeInput('character', choices = nodes.df$id, label="Search by Name",
                   multiple = TRUE),
    br(),
    div(actionButton("updateButton", "Update the chart"), style = "text-align:center")
  ),
  
  dashboardBody(
    fluidRow(
      box(title = "Known Associate Network", 
          visNetworkOutput("network", width = "100%", height = "500px"),
          collapsible = TRUE, collapsed = FALSE,
          status = "danger", solidHeader = TRUE, width= 12
      ),
      box(title = "Raw Data", 
          div(style = 'overflow-x: scroll; overflow-y: scroll; height:400px', 
              DT::dataTableOutput("table", width = "auto", height = "100%") 
          ),
          collapsible = TRUE, collapsed = TRUE,
          status = "primary", solidHeader = TRUE, width= 12
      ),
      box(title = "Known associate map", 
          leafletOutput("map", height = 600), 
          collapsible = TRUE, collapsed = TRUE,
          status = "warning", solidHeader = TRUE, width= 12
      )
    )
  )
)

# server side functions
server <- function(input, output, session){
  
  # selecting edges
  edges <- eventReactive(input$updateButton, {

    dplyr::filter(edges.df, from %in% input$character | to %in% input$character)
    
    }
  )
  
  # selecting nodes
  nodes <- eventReactive(input$updateButton, {
    
    dplyr::filter(nodes.df, id %in% edges()$from | id %in% edges()$to)
    
    }
  )
  
  # displaying the initial network
  output$network <- renderVisNetwork({
  
    visNetwork(nodes(), edges(), width = "100%") 
  })
  
  # table
  output$table <- DT::renderDataTable({
  
    table.df <- edges() %>% 
                mutate(from = paste0("<a href=\"https://www.google.com/search?q=pulp+fiction+", from, "\" target=\"_blank\">", from, "</a>"),
                       to = paste0("<a href=\"https://www.google.com/search?q=pulp+fiction+", to, "\" target=\"_blank\">", to, "</a>")
                ) 
    
    DT::datatable(table.df, 
                  escape = FALSE, 
                  rownames = FALSE
    )
  })
  
  # display the initial map
  output$map <- renderLeaflet({
    
    map_data <- filter(map.df, id %in% nodes()$id)
    
    leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>% 
      fitBounds(min(map.df$lon),  min(map.df$lat), 
                max(map.df$lon),  max(map.df$lat)) %>% 
      addCircleMarkers(data = map_data,
                       lng=~lon, lat=~lat,
                       fillOpacity=0.5, stroke=FALSE,
                       popup=~Name)
  })
}

shinyApp(ui, server)
