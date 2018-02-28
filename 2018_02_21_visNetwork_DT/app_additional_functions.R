

source("global.R")

# read files 
nodes.df <- read_rds("data/nodes.Rds")
edges.df <- read_rds("data/edges.Rds") %>% 
            mutate(id = 1:length(from))# for edge selection
map.df <- read_rds("data/map.Rds")


# user interface
ui <- dashboardPage(
  dashboardHeader(title = "Known Associate AnalyzeR - R-meetup", titleWidth = 600),
  
  dashboardSidebar(
    selectizeInput('character', choices = NULL, label="Search by Name",
                   multiple = TRUE),
    br(),
    div(actionButton("updateButton", "Update the chart"), style = "text-align:center"),
    br(),
    checkboxInput("expand", "Expand network", value=FALSE)
  ),
  
  dashboardBody(
    fluidRow(
      box(title = "Edit Known Associate Network", collapsible = TRUE, collapsed = FALSE,
          status = "danger", solidHeader = TRUE, width= 12,
          visNetworkOutput("network", width = "100%", height = "350px")
      ),
      box(title = "Raw Data", 
          div(style = 'overflow-x: scroll; overflow-y: scroll; height:350px', 
              DT::dataTableOutput("table", width = "auto", height = "100%") 
          )
          ,
          collapsible = TRUE, collapsed = TRUE,
          status = "primary", solidHeader = TRUE, width= 12
      ),
      box(title = "Known associate map", leafletOutput("map", height = 600), 
          collapsible = TRUE, collapsed = TRUE,
          status = "warning", solidHeader = TRUE, width= 12
      )
    )
  )
)

# server side functions
server <- function(input, output, session){
  
  updateSelectizeInput(session, 'character', choices = nodes.df, server = TRUE,
                       options = list(labelField='label', searchField='label', 
                                      valueField='label',render = I( 
                                        "{ 
                                        option: function(item, escape) { 
                                        return '<div><strong>' + escape(item.label) + '</div>'; 
                                        } }"
                                      )
                                      )
                                      )
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
  
    visNetwork(nodes(), edges(), width = "100%") %>% 
      visOptions(highlightNearest = FALSE, 
                 nodesIdSelection = TRUE, 
                 manipulation = TRUE) %>%  
      visInteraction(multiselect = FALSE, selectConnectedEdges = FALSE) %>% 
      visNodes(shapeProperties = list(useBorderWithImage = TRUE)) %>%
      visEvents(doubleClick = "function(properties) {
                window.open('https://www.google.com/search?q=pulp+fiction+' + this.body.data.nodes.get(properties.nodes[0]).id);}",
                selectEdge = "function(edges) {
                  Shiny.onInputChange('current_edge_id', edges);
                  ;}", 
                selectNode = "function(nodes) {
                  Shiny.onInputChange('current_node_id', nodes);
                  ;}"
                )
    }
  )
  
  # table
  
  table.df <- reactive({

    # just get images to join for both from and to
    nodes.sub <- values[["nodes"]] %>%
      mutate(image = paste0('<img src=\"', image, '" height="100"></img>')) %>% 
      mutate(from_image = image,
             to_image = image) %>% 
      select(id, from_image, to_image)
    
    # join
   table.df <- left_join(values[["edges"]], nodes.sub[, c("id", "from_image")], by=c("from" = "id")) %>% 
      left_join(nodes.sub[, c("id", "to_image")], by=c("to" = "id")) %>% 
      mutate(from = paste0("<a href=\"https://www.google.com/search?q=pulp+fiction+", from, "\" target=\"_blank\">", from, "</a>"),
             to = paste0("<a href=\"https://www.google.com/search?q=pulp+fiction+", to, "\" target=\"_blank\">", to, "</a>")
      ) 
    
  })
  
  output$table <- DT::renderDataTable({
    
    table.df <- table.df()
    
    if(!is.null(input$network_selectedEdges)){
       
      if(input$network_selectedEdges != ""){
        table.df <- subset(table.df, id %in% input$network_selectedEdges)
      } else {
        table.df <- table.df()
      }
    } else {
      table.df <- table.df()
    }
      
    table.df <- select(table.df, from, from_image, to, to_image)

    DT::datatable(table.df,
                  escape = FALSE, 
                  rownames = FALSE
    )
  })
  
  # display the initial map
  output$map <- renderLeaflet({
    
    map_data <- filter(map.df, id %in% nodes()$id)
    
    info <- paste0(map_data$Name, 
                   "<br>", map_data$Note,
                   "<br>", '<img src=\"', map_data$image_url, '" height="150"></img>')
    
    m <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>% 
      fitBounds(min(map.df$lon),  min(map.df$lat), 
                max(map.df$lon),  max(map.df$lat))
    
      m %>% addCircleMarkers(data = map_data,
                       lng=~lon, lat=~lat,
                       fillOpacity=0.5, stroke=FALSE,
                       popup=info)
  })
  
  # selecting network elements
  observe({
    input$current_edge_id
    visNetworkProxy("network") %>% visGetSelectedEdges()
  })
  
  observe({
    input$current_node_id
    visNetworkProxy("network") %>% visGetSelectedNodes()
  })
  
  # adding a network of clicked individual
  
  observeEvent(input$network_selected, {
    
    if(input$expand==TRUE){
    
      if(input$network_selected!=""){  

      # additional edges
      edges2 <- dplyr::filter(edges.df, from %in% input$network_selected | 
                                        to %in% input$network_selected) %>% 
                dplyr::filter(!(id %in% edges()$id))
      
      # additional nodes
      nodes2 <- dplyr::filter(nodes.df, id %in% edges2$from | id %in% edges2$to)
                
      visNetworkProxy("network") %>% 
        visUpdateNodes(nodes = nodes2) %>%
        visUpdateEdges(edges = edges2)   

      }
    }
  }
  ) 
  
  # keeping expanded network in reactive values
  
  values <- reactiveValues()
  
  observe({
    
    if(!is.null(input$network_selected)){ 
    
      if(input$network_selected!=""){  
     
        #browser()
      
        values[["nodes_previous"]] <- isolate(values[["nodes"]])
        values[["edges_previous"]] <- isolate(values[["edges"]])
      
        values[["edges"]]  <- dplyr::filter(edges.df, from %in% input$network_selected | 
                                to %in% input$network_selected) %>% 
                dplyr::filter(!(id %in% edges()$id)) %>% 
                rbind(values[["edges_previous"]]) %>% 
                distinct()
      
        values[["nodes"]]  <- dplyr::filter(nodes.df, id %in% values[["edges"]] $from | 
                                                      id %in% values[["edges"]] $to) %>% 
          rbind(values[["nodes_previous"]]) %>% 
          distinct()
      
      } 

    }  else {
       initialize
      values[["nodes"]] <- nodes()
      values[["edges"]] <- edges()
    }
  })
  
}

shinyApp(ui, server)


