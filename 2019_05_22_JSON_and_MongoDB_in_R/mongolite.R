library(mongolite)
library(tidyverse)

# Free book! https://jeroen.github.io/mongolite/

# look for sample collection "listingsAndReviews" on "sample_airbnb"
m <- mongo(
  db = "sample_airbnb",
  collection = "listingsAndReviews",
  url = "mongodb+srv://phillyr:risawesome@phillyr-djozr.azure.mongodb.net/test?retryWrites=true",
  verbose = T
)

# How many documents? i.e. SELECT COUNT(*) FROM listingsAndReviews
m$count('{}')

# Query only one, i.e. SELECT * FROM listingsAndReviews LIMIT 1
oneTrueListing <- m$find(fields = '{}', limit = 1)

# Is automatically a data.frame
class(oneTrueListing)
colnames(oneTrueListing)

# tibblify to view data easily
(oneTrueListing <- tibble::as_tibble(oneTrueListing))

# Using iterate to get 1 value as JSON (by passing automatic conversion to dataframe)
findOne_asJSON <- m$iterate()
oneTrueListing_json <- findOne_asJSON$json(1)
# Print as pretty
jsonlite::prettify(oneTrueListing_json)

# let's remove summary, space, description, neighborhood_overview, and notes because they really long texts
jsonlite::prettify(
  m$iterate(
    query = sprintf('{ "_id": "%s" }', oneTrueListing$`_id`),
    fields = '{"summary" : false, "space" : false, "description" : false, "neighborhood_overview" : false, "notes" : false }',
    limit = 1)$json(1)
)


# Some of the fields are "complex". Let's explore
simpleListing <- m$find(
  query = sprintf('{ "_id": "%s" }', oneTrueListing$`_id`),
  fields = '{"summary" : false, "space" : false, "description" : false, "neighborhood_overview" : false, "notes" : false }'
)

# What is the class of each column in data.frame?
sapply(simpleListing, function(x) {paste(class(x), collapse = "/")})

# Which column is not a vector?
colnames(simpleListing)[!sapply(simpleListing, is.vector)]


# Example of nested document
jsonlite::prettify(
  m$iterate(
    query = sprintf('{ "_id": "%s" }', oneTrueListing$`_id`),
    fields = '{"_id" : true, "beds" : true, "price": true, "images" : true }',
    limit = 1)$json(1)
)

# Watch what happens to "price" and "images"
(nestedObjects <- m$find(
  query = sprintf('{ "_id": "%s" }', oneTrueListing$`_id`),
  fields = '{"_id" : true, "beds" : true, "price": true, "images" : true }'
))

class(nestedObjects$images)
nestedObjects$images

# flattens non-recursively, leading to 4-col tibble with "images" column being a data.frame
as_tibble(nestedObjects) 
sapply(as_tibble(nestedObjects), function(x) {paste(class(x), collapse = "/")})

#.............................................................................................#
# What if the value was an array? (e.g. "amenities")
class(simpleListing$amenities)
(nestedArray <- m$find(
  query = sprintf('{ "_id": "%s" }', oneTrueListing$`_id`),
  fields = '{"_id" : true, "beds" : true, "price": true, "images" : true, "amenities" : true }'
))

class(nestedArray$amenities)
nestedArray$amenities

# flattens non-recursively, leading to 5-col tibble with "images" column being a data.frame,
# and "amenties" as a list
as_tibble(nestedArray)
sapply(as_tibble(nestedArray), function(x) {paste(class(x), collapse = "/")})
