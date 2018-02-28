

options(list(scipen=999)) #, shiny.port = 5170, shiny.host = "0.0.0.0"))

list.of.packages <- c("shiny", "devtools", "readr", "htmltools", "lubridate", "readxl", "leaflet",
                      "rgeos", "sp", "rgdal", "shinydashboard", "dplyr", "plyr",
                      "tidyr", "visNetwork", "stringr", "igraph", "linkcomm", 
                      "rgexf", "httr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org")

library(shiny)
library(shinydashboard)

library(leaflet)
library(readr)
library(DT) 
library(htmltools)
library(lubridate)
library(rgeos)
library(sp)
library(rgdal)
library(tidyr)
library(dplyr)
library(plyr)
library(readxl)
library(visNetwork)
library(stringr)
library(igraph)
library(linkcomm)

library(rgexf)
library(httr)