## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Script:            Configuration script
## Author(s):         Carlos Toruno   (ctoruno@worldjusticeproject.org)
## Creation date:     April 25th, 2025
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 1. SharePoint Paths ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

if (!(Sys.info()["user"] %in% c("carlostoruno"))){
  stop("'USER' is not recorded in 'config.R'. Please add this user and its paths to the config.R file")
}

if (Sys.info()["user"] == "carlostoruno") {
  path2SP <- "/Users/carlostoruno/OneDrive - World Justice Project/EU Subnational/EU-S Data"
} 
