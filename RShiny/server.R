#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(sparklyr)
library(dplyr)
prediction <- function(cores,maxDepth,noofTrees) {
  conf <- spark_config()
  conf$spark.executor.memory <- "2GB"
  conf$spark.memory.fraction <- 0.9
  
  
  iris$Species<-NULL
  ir_data<-iris
  ir_data$petalratio <- ir_data$Petal.Length/ir_data$Petal.Width
  ir_data=transform(ir_data,sepalRatio=(ir_data$Sepal.Length/ir_data$Sepal.Width))
  ir_data$sepal_length<-ir_data$Sepal.Length
  ir_data$sepal_width<-ir_data$Sepal.Width
  ir_data$petal_length<-ir_data$Petal.Length
  ir_data$petal_width<-ir_data$Petal.Width
  ir_data$length_ratio<-ir_data$Petal.Length/ir_data$Sepal.Length
  ir_data$width_ratio<-ir_data$Petal.Width/ir_data$Sepal.Width
  ir_data$Sepal.Length<-NULL
  ir_data$Sepal.Width<-NULL
  ir_data$Petal.Length<-NULL
  ir_data$Petal.Width<-NULL
  sc <- spark_connect(master="spark://sparkr.c.silken-quasar-210317.internal:7077", 
                      version = "2.1.0",
                      config = conf,
                      spark_home = "/usr/lib/spark/")
  iris_tbl <- sdf_copy_to(sc, ir_data, name = "iris_tbl", overwrite = TRUE,repartition=cores)
  partitions <- iris_tbl %>%
    sdf_partition(training = 0.7, test = 0.3, seed = 1111)
  
  iris_training <- partitions$training
  iris_test <- partitions$test
  sdf_num_partitions(iris_training)
  rf_model <- iris_training %>%
    ml_random_forest_regressor( sepal_width ~ petal_width+petal_length+sepal_length+petalratio+length_ratio+width_ratio, num_trees = noofTrees,
                                subsampling_rate = 1, max_depth = maxDepth)
  
  predections <- sdf_predict(iris_test, rf_model)
  pred<-collect(predections)
  evaluation <-ml_regression_evaluator(predections, label_col = "sepal_width")
  Sys.setenv(EVALUATION = evaluation)
  result<-c(pred,evaluation)
  return(result)
}
model <- function(cores,maxDepth,noofTrees) {
  conf <- spark_config()
  conf$spark.executor.memory <- "2GB"
  conf$spark.memory.fraction <- 0.9
  
  iris$Species<-NULL
  ir_data<-iris
  ir_data$petalratio <- ir_data$Petal.Length/ir_data$Petal.Width
  ir_data=transform(ir_data,sepalRatio=(ir_data$Sepal.Length/ir_data$Sepal.Width))
  ir_data$sepal_length<-ir_data$Sepal.Length
  ir_data$sepal_width<-ir_data$Sepal.Width
  ir_data$petal_length<-ir_data$Petal.Length
  ir_data$petal_width<-ir_data$Petal.Width
  ir_data$length_ratio<-ir_data$Petal.Length/ir_data$Sepal.Length
  ir_data$width_ratio<-ir_data$Petal.Width/ir_data$Sepal.Width
  ir_data$Sepal.Length<-NULL
  ir_data$Sepal.Width<-NULL
  ir_data$Petal.Length<-NULL
  ir_data$Petal.Width<-NULL
  sc <- spark_connect(master="spark://sparkr.c.silken-quasar-210317.internal:7077", 
                      version = "2.1.0",
                      config = conf,
                      spark_home = "/usr/lib/spark/")
  iris_tbl <- sdf_copy_to(sc, ir_data, name = "iris_tbl", overwrite = TRUE,repartition=cores)
  partitions <- iris_tbl %>%
    sdf_partition(training = 0.7, test = 0.3, seed = 1111)
  
  iris_training <- partitions$training
  iris_test <- partitions$test
  sdf_num_partitions(iris_training)
  rf_model <- iris_training %>%
    ml_random_forest_regressor( sepal_width ~ petal_width+petal_length+sepal_length+petalratio+length_ratio+width_ratio, num_trees = noofTrees,
                                subsampling_rate = 1, max_depth = maxDepth)
  
  
  return(rf_model)
}





#calculating Errors




# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  output$accuracy<- renderPrint
  output$lineChart <- renderPlot({
    res<-prediction(input$cores,input$depth,input$trees)
    chartData <- list(res$sepal_width,res$prediction)
      
    
    chartTitle <- "Predicted Sapal Width Vs Actual Width"
    
    
    yrange <- c(0,7)
    xrange <- range(0,length(res$sepal_width))
    year<-1:length(res$sepal_width)
    plot(xrange,yrange,type="n",xlab="",ylab="Petal Width",cex.lab=1.5,
         main= chartTitle,sub=c("\n \n \n\n\n\n RMSE Error For Model is \n ",Sys.getenv("EVALUATION"))
         )
    
    lines(year,chartData[[1]],col="aquamarine4",lwd=3)
    lines(year,na.omit(chartData[[2]]),col="firebrick3",lwd=3)
    
    legend(25,7,c("Actual Sepal Width","Predicted Sepal Width"), 
           col=c('firebrick3','aquamarine4'),pch=15,ncol=1,bty ="n",cex=1.1)
    
   
  },height = 500, width = 700)
    
    
    
    
    
  output$model <- renderPrint({
    res<-model(input$cores,input$depth,input$trees)
    summary(res)
  })
    
  })
  


