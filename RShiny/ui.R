#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("IRIS ->Sepal Width Prediction Using RandomForest"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      selectInput("Prediction Variable", label = h3("predictionInput"),
                  choices = list("Sepal Width" = 'speal_width',
                                 "Sepal Length" = 'sepal_length',
                                 "Petal Length" = 'petal_length',    
                                 "Petal Width" = 'petal_width'), selected = 1),
      
      sliderInput("cores",
                  "No Of cores",
                  min = 1,
                  max = 10,
                  value = 1),
      
      sliderInput("trees",
                  "No Of Trees",
                  min = 1,
                  max = 60,
                  value = 5),
      
       sliderInput("depth",
                   "Max Depth of Tree:",
                   min = 1,
                   max = 30,
                   value = 5)
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
       
       tabsetPanel(type = "tabs",
                   tabPanel("Original/Predicted",       
                            plotOutput("lineChart")
                   ),
                   
                   
                   tabPanel("Model",       
                            verbatimTextOutput("model"),
                            textInput("text_model", label = "Interpretation", value = "Enter text...")
                            )         
                   
       )    
       
       
    )
  )
))

