## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Script:            Nonlinear PCA
## Author(s):         Carlos A. Toruño Paniagua   (ctoruno@worldjusticeproject.org)
## Dependencies:      World Justice Project
## Creation date:     January 5th, 2025
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library(glue)
library(haven)
library(Gifi)
library(cowplot)
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
negative_vars <- outline %>% 
  filter(direction == "positive") %>% 
  pull(target_var)

# Loading master GPP data
eugpp <- load_data(path2SP, "gpp") %>%
  filter(
    gend < 3
  ) %>%
  mutate(
    # Identifying survey groups
    CP = if_else(!is.na(CPA_media_freeop),"A", "B"),
    IP = if_else(!is.na(LEP_rightsresp),"A", "B"),
    group = paste0(CP,IP)
  ) %>%
  select(country_year_id, group) 


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 2.  Creating data subsets ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

groups <- list(
  "AA" = "AA",
  "AB" = "AB",
  "BA" = "BA",
  "BB" = "BB"
)
pillars <- list(
  "p1" = "p1", 
  "p2" = "p2", 
  "p3" = "p3", 
  "p4" = "p4", 
  "p5" = "p5"
)

imputed_data <- lapply(
  groups,
  function(g){
    
    print(glue("Group: {g}"))
    
    lapply(
      pillars,
      function(p){
        
        print(glue("Pillar: {p} - {p}"))
        
        # Looping through multiple imputations and saving data frames as CSV
        lapply(
          c(1:5),
          function(n_imp){
            
            # Loading and preparing data
            df <- read_csv(
              glue("../../data/mice_imputations/subdata_{g}_{p}_imp{n_imp}.csv"),
              col_types = list(col_double())
            ) %>% mutate(

              # Re-orienting data for better fit and interpretation
              across(
                !any_of(negative_vars),
                \(x) 5-x
              ),  # ROL_*_imp are 3-points Likert scales, same with CTZ_accountability... but they do NOT require re-orientation

              # Transforming to ordered factors
              across(
                everything(),
                \(x) as.ordered(x)
              )
            )
            
            return(as.data.frame(df))
            
          })
      })
  })


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 3.  Optimal number of dimensions ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

set.seed(281299)

# Getting the optimal number of dimensions
elbow_plots <- unlist(
  lapply(
    groups,
    function(g){
      
      print(glue("Group: {g}"))
      
      lapply(
        pillars,
        function(p){
          
          print(glue("Pillar: {p} - {p}"))
          
          # Random draw from multiple imputations
          rd <- sample(1:5, 1)
          
          data4nlpca <- imputed_data[[g]][[p]][[rd]]
          nlpca_fit <- princals(
            data4nlpca,
            ndim    = 10,
            missing = "s" 
          )
          
          # Elbow Method Plot
          eigenvalues <- nlpca_fit$evals
          data.frame(
            Component = 1:length(eigenvalues), 
            Eigenvalue = eigenvalues
          ) %>%
            ggplot(
              aes(
                x = Component, 
                y = Eigenvalue
              )
            ) +
            geom_line() +
            geom_point() +
            geom_hline(
              yintercept = 2, 
              color      = "grey25",
              linetype   = "dashed"
            ) +
            labs(
              title = glue("Pillar: {p}"), 
              x = "Component", 
              y = "Eigenvalue"
            ) +
            scale_x_continuous(
              breaks = seq(1, length(eigenvalues), by = 1)
            ) +
            theme_minimal()
        })
    }),
  recursive = FALSE
)

# Creating a subdir for media outputs
dir.create(
  "../../viz", 
  recursive = TRUE, 
  showWarnings = FALSE
)

# Reviewing elbows and saving plot
grid <- plot_grid(
  plot_grid(
    plotlist =  elbow_plots[1:5],
    ncol = 5
  ),
  plot_grid(
    plotlist =  elbow_plots[6:10],
    ncol = 5
  ),
  plot_grid(
    plotlist =  elbow_plots[11:15],
    ncol = 5
  ),
  plot_grid(
    plotlist =  elbow_plots[16:20],
    ncol = 5
  ),
  labels = groups,
  ncol  = 1
)

ggsave2(
  plot     = grid,
  filename = "../../viz/NLPCA-elbow.png",
  width    = 20,
  height   = 8,
  units    = "in"
)

# We select the number of dimensions to preserve based on the elbow plot
n_dims <- list(
  "p1" = 2,
  "p2" = 2,
  "p3" = 2,
  "p4" = 3,
  "p5" = 1
)


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 4.  Fitting a NLPCA model                                                                                ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Fitting a NLPCA on every individual imputation
nlpca_results <- lapply(
  groups,
  function(g){
    
    print(glue("Group: {g}"))
    
    lapply(
      pillars,
      function(p){
        
        print(glue("Pillar: {p} - {p}"))
        
        lapply(
          c(1:5),
          function(n_imp){
            
            data4nlpca <- imputed_data[[g]][[p]][[n_imp]]
            nlpca_fit  <- princals(
              data4nlpca,
              ndim    = n_dims[[p]],
              missing = "a" 
            )
            
            return(nlpca_fit)
            
          })
      })
  })

acrons <- list(
  "p1" = "checks",
  "p2" = "frights",
  "p3" = "justice",
  "p4" = "corrup",
  "p5" = "trust"
)

nlpca_results_pooled <- lapply(
  groups,
  function(g){
    
    print(glue("Group: {g}"))
    
    lapply(
      pillars,
      function(p){
        
        print(glue("Pillar: {p} - {p}"))
        
        scores_list <- lapply(
          nlpca_results[[g]][[p]],
          function(n_imp){
            return(n_imp[["objectscores"]])
          })
        
        loadings_list <- lapply(
          nlpca_results[[g]][[p]],
          function(n_imp){
            return(n_imp[["loadings"]])
          })
        
        pillar_name <- acrons[[p]]
        
        scores_df <- as_tibble(
          Reduce("+", scores_list) / length(nlpca_results[[g]][[p]])
        ) %>% 
          rename_with(~paste(pillar_name, .x, sep = "_"))
        
        loadings_df <- as_tibble(
          Reduce("+", loadings_list) / length(nlpca_results[[g]][[p]]), 
          rownames = "variable"
        )
        
        return(
          list(
            "scores"   = scores_df,
            "loadings" = loadings_df
          )
        )
        
      })
  })

# Extracting scores
final_scores <- map_dfr(
  groups,
  function(g){
    
    x <- eugpp %>%
      filter(
        group %in% g
      ) %>%
      select(country_year_id) # We need the unique ID for every row in every group
    
    y <- bind_cols(
      lapply(
        nlpca_results_pooled[[g]], 
        \(x) x[["scores"]]
      )
    ) %>%
      mutate(
        group = g
      )
    
    df <- bind_cols(x,y) %>%
      relocate(all_of(c("country_year_id", "group"))) %>%
      mutate(
        
        # Centering values per group to be mean-0 and var-1
        across(
          where(is.numeric),
          \(x) scale(x)[,1]
        )
      )
    
    print(names(df))
    
    df_subset <- df[,sapply(df, is.numeric)] # Are the resulting scores centered?
    
    print("======================================================================")
    print(glue("Group: {g}"))
    print("Mean")
    print(
      sapply(df_subset, \(x) round(mean(x), 4))
    )
    print("Variance")
    print(
      sapply(df_subset, \(x) round(var(x), 2))
    )

    return(df)
    
  })

write_csv(final_scores, "../../data/nlpca_results.csv")

