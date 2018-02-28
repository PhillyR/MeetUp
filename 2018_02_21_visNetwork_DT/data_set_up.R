

# prepping data

require(rgexf)
require(httr)
library(igraph)
library(visNetwork)
library(dplyr)
library(readxl)
library(ggmap)
library(readr)

options(stringsAsFactors = F)

# Get the gexf file from the site and place it into a file
#gex <- as.character(GET('http://media.moviegalaxies.com/gexf/660.gexf'))
gex <- readLines('data\\660.gexf') # offline 

cat(gex, file = 'movie.gexf')

# Read it in with the gexf reader
pulp <- read.gexf('movie.gexf')

# read image file

image <- read_excel("data\\map_and_image.xlsx", sheet = "image")

# read map file and geocode

map <- read_excel("data\\map_and_image.xlsx", sheet = "leaflet")

coords <- geocode(map$Location)
map <- cbind(map, coords)


# Transform to igraph class
ipulp <- as.undirected(gexf.to.igraph(pulp))

edges <- as.data.frame(as_edgelist(ipulp, names = TRUE)) %>% 
         rename(from = V1, to=V2)

nodes <- data.frame(id = names(V(ipulp))) %>% 
         mutate(label = id, 
                shape = "circularImage") %>% 
         left_join(image, by="id")

saveRDS(nodes, "data/nodes.Rds")
saveRDS(edges, "data/edges.Rds")
saveRDS(map, "data/map.Rds")
