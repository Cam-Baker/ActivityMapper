library(shiny)
library(stringr)
library(XML)
library(reticulate)
library(R.utils)
library(leaflet)
library(dplyr)
library(pbapply)

### Python libraries to install before usage
#py_install("fitparse", pip = TRUE)
#py_install("pytz", pip = TRUE)
source_python("Python/fit_convert.py")

### Set maximum upload size to 50 MB
options(shiny.maxRequestSize = 50*1024^2)

### Finds the coordinate locations within GPX files
### inspired by http://rcrastinate.blogspot.com/2014/09/stay-on-track-plotting-gps-tracks-with-r.html
parseGPX <- function(file_path){
  pfile <- htmlTreeParse(file_path, error = function (...) {}, useInternalNodes = T)
  coords <- xpathSApply(pfile, path = "//trkpt", xmlAttrs)
  if(length(coords) == 0){
    print("No coords")
    return_df <- data.frame(matrix(nrow = 0,ncol = 2))
    colnames(return_df) <- c("lat","lng")
    return(return_df)
  }
  lats <- as.numeric(coords["lat",])
  lons <- as.numeric(coords["lon",])
  return(data.frame(lat = lats, lng = lons))
}

### Finds the coordinate locations within TCX files using similar methods as above
parseTCX <- function(file_path){
  gunzip(file_path, remove=F)
  file_path <- gsub('.{3}$','',file_path)
  pfile <- htmlTreeParse(file_path, useInternalNodes = T)
  lats <- as.numeric(xpathApply(pfile, path = "//latitudedegrees", xmlValue))
  lons <- as.numeric(xpathApply(pfile, path = "//longitudedegrees", xmlValue))
  file.remove(file_path)
  return(data.frame(lat = lats, lng = lons))
}

### Uses Python package fitparse to csv and then import
### inspired by https://github.com/mrhheffernan/PythonHeatmap
parseFIT <- function(file_path){
  gunzip(file_path, remove=F)
  file_path <- gsub('.{3}$','',file_path)
  write_fitfile_to_csv(file_path, output_file = paste0(gsub('.{4}$','',file_path),".csv"))
  fit_file <- read.csv(paste0(gsub('.{4}$','',file_path),".csv"))
  fit_file <- fit_file[which(fit_file$position_lat != "None" & fit_file$position_long != "None"),c("position_lat","position_long")]
  file.remove(file_path)
  file.remove(paste0(gsub('.{4}$','',file_path),".csv"))
  return(data.frame(lat = as.numeric(as.character(fit_file$position_lat)), lng = as.numeric(as.character(fit_file$position_long))))
}

### Chooses a function to run based on the file extension
parseFile <- function(file_path){
  if(grepl("fit",file_path)){
    return(parseFIT(file_path))
  }else if(grepl("tcx",file_path)){
    return(parseTCX(file_path))
  }else if(grepl("gps",file_path)){
    return(parseGPX(file_path))
  }
}

### Define UI for run mapper
ui <- fluidPage(
  
  ### App header
  headerPanel("Map Your Activities"),
  
  ### Side bar for uploading data
  sidebarLayout(
    sidebarPanel(
      tags$head(
        tags$style(type="text/css", "select { max-width: 300px; }"),
        tags$style(type="text/css", ".span4 { max-width: 300px; }"),
        tags$style(type="text/css", ".well { max-width: 300px; }")
      ),
      radioButtons("timespan","Selet activities from", c("Last Month" = 1, "Last 6 months" = 2, "Last Year" = 3, "All Time" = 0)),
      tags$hr(),
      fileInput("Import", "Choose your Strava Export", multiple = FALSE, accept = ".zip"),
      tags$hr(),
      sliderInput("Height",
                  "Height in Pixels:",
                  min = 100,
                  max = 2000,
                  value = 500),
      sliderInput("Width",
                  "Width in Pixels:",
                  min = 100,
                  max = 2000,
                  value = 500),
      tags$hr()
      
    ),
    
    ### Displaying contents of file
    mainPanel(
      uiOutput("leaf")
    )
  )
)

server <- function(input, output){
  
  output$leaf <- renderUI({
    leafletOutput("map", width = input$Width, height = input$Height)
  })
  
  output$map <- renderLeaflet({
    
    ### Do not start until there is an upload
    req(input$timespan)
    req(input$Import)
    
    ### Unzip the directory
    tryCatch(
      {
        ### Create a temporary directory and unzip the payload to that directory
        tmp_dir <- str_replace(paste0("./",Sys.time())," ","_")
        dir.create(tmp_dir)
        setwd(tmp_dir)
        unzip(input$Import$datapath)
        
      },
      error = function(e) {
        # return a safeError if a parsing error occurs
        stop(safeError(e))
      }
    )
    
    ### Read in and format the activity data table
    activity_df <- read.csv("activities.csv", stringsAsFactors = F)
    activity_df <- activity_df[which(grepl("activities",activity_df$Filename)),]
    activity_df <- activity_df %>% mutate(Activity.Date = as.Date(Activity.Date, format = '%B %d, %Y, %H:%M:%S'))
    
    ### Filter activities based on user selected time frame
    if(input$timespan == "1"){
      activity_df <- activity_df[which(difftime(Sys.Date(),activity_df$Activity.Date) <= 31),]
    }else if(input$timespan == "2"){
      activity_df <- activity_df[which(difftime(Sys.Date(),activity_df$Activity.Date) <= (30*6+3)),]
    }else if(input$timespan == "3"){
      activity_df <- activity_df[which(difftime(Sys.Date(),activity_df$Activity.Date) <= 365),]
    }
    
    ### Parse each of the gps files, returning as a table of coordinates
    withProgress(message = "Processing activity files...", value=0, {
      percentage <- 0
      out <- lapply(activity_df$Filename, function(x){
        percentage <<- percentage + 1/length(activity_df$Filename)*100
        incProgress(1/length(activity_df$Filename), detail = paste0("Progress: ",round(percentage,1)))
        parseFile(x)
      })
    })
    
    ### Create the map from the lists of coordinates
    map <- leaflet() %>% addTiles() 
    for(i in out){
      if(!is.null(i)){
        if(isTruthy(i) && nrow(i) > 0){
          map <- map %>% addPolylines(lat = i$lat, lng = i$lng)
        }
      }
    }
    
    ### Delete the temporary directory
    setwd("..")
    unlink(tmp_dir, recursive = T)
    
    return(map)
  })

}

shinyApp(ui, server)