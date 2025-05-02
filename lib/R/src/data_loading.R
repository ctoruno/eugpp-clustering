library(glue)
library(haven)
library(tidyverse)

load_data <- function(path2EU, source){
  
  if (!(source %in% c("gpp", "outline"))){
    stop("'source' argument should be one of: 'gpp', 'outline'")
  }
  
  if (source == "gpp"){
    path2data <- file.path(
      path2EU,
      "eu-gpp", "1. Data", "3. Merge", "EU_GPP_2024.dta"
    )
    
    if (file.exists(path2data)){
      df <- read_stata(path2data)
    } else {
      stop(glue("File '{path2data}' does not exist."))
    }
  }
  
  if (source == "outline"){
    path2data <- file.path(
      "..", "..", "metadata", "theoretical_outline.xlsx"
    )
    
    if (file.exists(path2data)){
      df <- read.xlsx(path2data)
    } else {
      stop(glue("File '{path2data}' does not exist."))
    }
  }
  
  return(df)
}