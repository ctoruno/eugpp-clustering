## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Script:            FCA Multiple Imputation
## Author(s):         Carlos A. Toruño Paniagua   (ctoruno@worldjusticeproject.org)
## Dependencies:      World Justice Project
## Creation date:     January 5th, 2025
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library(glue)
library(haven)
library(mice)
library(MASS)
library(furrr)
library(future)
library(openxlsx)
library(tidyverse)

if (interactive()){
  source("src/config.R")
  source("src/data_loading.R")
}

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 1.  Loading Data ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Loading outline
outline <- load_data(path2SP, "outline")

# Loading GPP data
eugpp <- load_data(path2SP, "gpp") %>%
  filter(
    gend < 3
  ) %>%
  mutate(
    age_group = case_when(
      age >= 1  & age <= 6  ~ age, # Luxembourg
      age >= 18 & age <= 24 ~ 1,
      age >= 25 & age <= 34 ~ 2,
      age >= 35 & age <= 44 ~ 3,
      age >= 45 & age <= 54 ~ 4,
      age >= 55 & age <= 64 ~ 5,
      age >= 65 & age <= 100 ~ 6
    ),
    polid = case_when(
      polid >= 0 & polid <= 3  ~ "Left",
      polid >= 4 & polid <= 6  ~ "Center",
      polid >= 7 & polid <= 10 ~ "Right",
    ),
    
    # Identifying survey groups
    CP = if_else(!is.na(CPA_media_freeop),"A", "B"),
    IP = if_else(!is.na(LEP_rightsresp),"A", "B"),
    group = paste0(CP,IP)
  )

# Predictors
demographic_predictors <- c(
  "nuts_id", "group", "age_group", "urban", "gend", "edu", 
  "fin", "emp", "marital", "politics", "polid"
)


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 2.  Splitting data into groups ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

groups <- list(
  "AA" = "AA",
  "AB" = "AB",
  "BA" = "BA",
  "BB" = "BB"
)
pillars <- list(
  "Checks on Government Powers",
  "Fundamental Rights & Civic Participation",
  "Justice & Law Enforcement",
  "Transparency & Control of Corruption",
  "Trust in Institutions"
)
names(pillars) <- pillars

data_subsets <- lapply(
  groups,
  function(g){
    
    lapply(
      pillars,
      function(p){
        
        target_features <- outline %>%
          select(pillar, target_var, group = all_of(g)) %>%
          filter(group == TRUE & pillar == p) %>%
          pull(target_var)
        
        data4imputation <- eugpp %>%
          filter(group %in% g) %>%
          select(
            all_of(demographic_predictors),
            all_of(target_features)
          ) %>%
          mutate(
            
            # Transforming DKNAs as missing
            across(
              all_of(target_features),
              \(x) case_when(
                x >= 98 ~ NA,
                TRUE ~ x
              )
            ),
            across(
              all_of(c(
                "edu", "fin", "emp", "marital", "politics"
              )),
              \(x) case_when(
                x >= 98 ~ NA,
                TRUE ~ x
              )
            ),
            # age = if_else(age == 999, NA, age),
            # A1  = if_else(A1 == -9999, NA, A1),
            
            # Defining variable types
            across(
              all_of(target_features),
              \(x) ordered(x, levels = 1:4)
            ),
            across(
              all_of(ends_with("_imp")),
              \(x) ordered(x, levels = 1:3)
            ),
            across(
              all_of(c(
                "nuts_id", "urban", "gend", "edu", "fin", 
                "emp", "marital", "politics", "polid", "group"
              )),
              \(x) as.factor(x)
            ),
            across(
              all_of(c("age_group")),
              \(x) ordered(x, levels = 1:6)
            )
          )
        
        # MICE does not work well with columns that have a high incidence of NAs
        na_sum = (colSums(is.na(data4imputation))/nrow(data4imputation))*100
        
        print("======================================")
        print(glue("Group  : {g}"))
        print(glue("Pillar : {p}"))
        print(na_sum[na_sum>15])
        print("======================================")
        
        return(data4imputation %>% select(-names(na_sum[na_sum>15])))  
        
      }
    )
  }
)


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 3.  Performing MICE on grouped data ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Looping through groups and pillars to perform MICE
imputed_data <- lapply(
  groups,
  function(g){
    
    lapply(
      pillars,
      function(p){
        
        print("===========================================")
        print(glue("Group  : {g}"))
        print(glue("Pillar : {p}"))
        print(glue("Start time : {Sys.time()}"))
        print("... Performing Imputation ...")
        
        
        data4imputation <- data_subsets[[g]][[p]]
        
        methods <- c(
          
          "", # NUTS does not need to be imputed
          "", # group does not need to be imputed
          
          # Imputation of ordered factor data requires a 'polr' model (AGE)
          "polr",
        
          # Imputation of factor data can be done using a 'polyreg' model
          rep("polyreg", length(demographic_predictors)-3),
          
          # Imputation of ordered factor data requires a 'polr' model
          rep("polr", ncol(data4imputation)-length(demographic_predictors))
        )
        
        imputed <- futuremice(
          data4imputation,
          m = 5, 
          maxit = 10,
          method = methods,
          # When using future we don't need to specify a seed because this will replicate the randomness
          # across multiple R sessions. We then use parallelseed instead.
          # seed   = 1910,
          n.core = 5,
          parallelseed = 1910,
          nnet.MaxNWts = 2000
        )
        plan(sequential)
        
        print(glue("End time : {Sys.time()}"))
        print("===========================================")
        
        return(imputed)
        
      }
    )
  }
)

# Saving full mids object
saveRDS(imputed_data, file = "../../data/imputed-mids.rds")

# Creating a subdir for individual imputations
dir.create(
  "../../data/mice_imputations", 
  recursive = TRUE, 
  showWarnings = FALSE
)

# Extracting individual datasets and saving imputations
pillars4sav <- list(
  "Checks on Government Powers",
  "Fundamental Rights & Civic Participation",
  "Justice & Law Enforcement",
  "Transparency & Control of Corruption",
  "Trust in Institutions"
)
names(pillars4sav) <- c("p1", "p2", "p3", "p4", "p5")

lapply(
  groups,
  function(g){
    
    print(glue("Group: {g}"))
    
    imap(
      pillars4sav,
      function(p, pcounter){
        
        print(glue("Pillar: {pcounter} - {p}"))
        
        # Extracting mids object
        mids <- imputed_data[[g]][[p]]
        
        # Looping through multiple imputations and saving data frames as CSV
        lapply(
          c(1:5),
          function(n_imp){
            
            df <- mice::complete(mids, action = n_imp) %>%
              dplyr::select(-all_of(demographic_predictors))
            write_csv(
              df,
              file = glue("../../data/mice_imputations/subdata_{g}_{pcounter}_imp{n_imp}.csv")
            )
            
          }
        )
      }
    )
  }
)


