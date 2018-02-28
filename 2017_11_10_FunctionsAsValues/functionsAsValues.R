print("Hello World")

#---- Hello World

HelloWorld <- function(){
  print("Hello World")
}

HelloWorld()


#---- Say thing 

SayThing <- function(thing){
  print(thing)
}

SayThing("I love R")


#---- Thing

Thing <- function(thing){
  return(thing)
}

Thing("What does Thing do?")

fromThing <- Thing("What does Thing do?")
class(fromThing)

Thing(1234)

fromThing1234 <- Thing(1234)
class(fromThing1234)

#---- WeirdThing

WeirdThing <- function(thing){
  thing
}

WeirdThing("What does WeirdThing do?")

fromWeirdThing <- WeirdThing("What does WeirdThing do?")
class(fromWeirdThing)

WeirdThing(1234)

fromWeirdThing1234 <- WeirdThing(1234)
class(fromThing1234)


#---- Stranger Things

# Nested
Thing(HelloWorld())
WeirdThing(HelloWorld())

# Nested ?
Thing(HelloWorld)
WeirdThing(HelloWorld)

# Quiz
StrangerThings <- WeirdThing(Thing)

StrangerThings("What's going on")

# "Bad" practice (depending on who you ask) but still allowed
WeirdThing(Thing)("So weird")
