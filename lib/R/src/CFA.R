## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
## Script:            Confirmatory Factor Analysis
## Author(s):         Carlos A. Toruño Paniagua   (ctoruno@worldjusticeproject.org)
## Dependencies:      World Justice Project
## Creation date:     January 5th, 2025
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

library(glue)
library(haven)
library(lavaan)
library(openxlsx)
library(tidyverse)

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 1.  Loading Data & Framework                                                                             ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Loading GPP data
path2SP <- glue("/Users/{Sys.info()['user']}/OneDrive - World Justice Project/EU Subnational/EU-S Data")
eugpp <- read_dta(
  file.path(path2SP, "eu-gpp/1. Data/3. Merge/EU_GPP_2024.dta")
)

# Loading outline
outline <- read.xlsx("../inputs/theoretical_outline.xlsx")
negative_vars <- outline %>% 
  filter(direction == "positive") %>% 
  pull(target_var)

# Loading framework
pillars <- outline %>% 
  distinct(chapter) %>% 
  pull(chapter) %>%
  setNames(
    paste("Pillar", seq(1,8),sep = "_")
  )

theoretical_model <- lapply(
  pillars,
  function(p) {
    outline %>%
      filter(chapter %in% p) %>%
      pull(target_var)
  }
)

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 2. Wrangling Data                                                                                        ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

subset4cfa <- eugpp %>%
  mutate(
    
    # Identifying survey groups
    CP = if_else(!is.na(CPA_media_freeop),"A", "B"),
    IP = if_else(!is.na(LEP_rightsresp),"A", "B"),
    group = paste0(CP,IP),
    
    # Transforming DKNAs as missing
    across(
      !c(country_year_id, CP, IP, group),
      \(x) case_when(
        x >= 98 ~ NA,
        TRUE ~ x
      )
    )
    
  ) %>%
  select(
    country_year_id, group,
    all_of(
      unlist(theoretical_model, use.names = FALSE)
    )
  ) %>%
  mutate(
    
    # Re-orienting data for better fit and interpretation
    across(
      !all_of(c("country_year_id", "group", negative_vars)),
      \(x) 5-x
    )
    
    # Transforming to ordered factors
    # across(
    #   !c(country_year_id, group),
    #   \(x) as.ordered(x)
    # ),
  )


## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 3. Modelling equations                                                                                   ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

modelled_groups <- lapply(
  c("AA"="AA",
    "AB"="AB",
    "BA"="BA",
    "BB"="BB"),
  function(group){
    
    individual_pillars <- imap(
      pillars,
      function(pillar_name, pillar_n){
        
        variables = outline %>% 
          rename(group = all_of(group)) %>% 
          filter(group == TRUE & chapter == pillar_name) %>%
          pull(target_var)
        
        rhs <- paste(variables, collapse = " + ")
        
        glue("{pillar_n} =~ {rhs}")
      }
    )
    
  } 
)


model_specification_1 <- glue('
  group: AA
  {modelled_groups[["AA"]][["Pillar_1"]]}
  {modelled_groups[["AA"]][["Pillar_2"]]}
  {modelled_groups[["AA"]][["Pillar_3"]]}
  {modelled_groups[["AA"]][["Pillar_4"]]}
  {modelled_groups[["AA"]][["Pillar_6"]]}
  {modelled_groups[["AA"]][["Pillar_7"]]}
  {modelled_groups[["AA"]][["Pillar_8"]]}
  
  group: AB
  {modelled_groups[["AB"]][["Pillar_1"]]}
  {modelled_groups[["AB"]][["Pillar_2"]]}
  {modelled_groups[["AB"]][["Pillar_3"]]}
  {modelled_groups[["AB"]][["Pillar_4"]]}
  {modelled_groups[["AB"]][["Pillar_6"]]}
  {modelled_groups[["AB"]][["Pillar_7"]]}
  {modelled_groups[["AB"]][["Pillar_8"]]}
  
  group: BA
  {modelled_groups[["BA"]][["Pillar_1"]]}
  {modelled_groups[["BA"]][["Pillar_2"]]}
  {modelled_groups[["BA"]][["Pillar_3"]]}
  {modelled_groups[["BA"]][["Pillar_4"]]}
  {modelled_groups[["BA"]][["Pillar_6"]]}
  {modelled_groups[["BA"]][["Pillar_7"]]}
  {modelled_groups[["BA"]][["Pillar_8"]]}
  
  group: BB
  {modelled_groups[["BB"]][["Pillar_1"]]}
  {modelled_groups[["BB"]][["Pillar_2"]]}
  {modelled_groups[["BB"]][["Pillar_3"]]}
  {modelled_groups[["BB"]][["Pillar_4"]]}
  {modelled_groups[["BB"]][["Pillar_6"]]}
  {modelled_groups[["BB"]][["Pillar_7"]]}
  {modelled_groups[["BB"]][["Pillar_8"]]}
')

model_specification_2 <- '
  Pillar_1 =~ {AA, BA} LEP_accountability + LEP_bribesreq + LEP_bribesacc 
              + LEP_accusation 
              + {AA, AB} CPA_cleanelec_local + CPA_freevote + CPA_media_freeop 
              + {BA, BB} CPB_freemedia + CPB_freexp_cso + CPB_freexp_pp 
              + CPB_freexp + CPB_freeassem
  Pillar_2 =~ {AA, BA} PAB_censorvoices + PAB_blamesoc + PAB_attackopp 
              + PAB_prosecuteopp + PAB_freecourts 
              + {AB, BB} PAB_distract  + PAB_misinfo + PAB_credibility 
              + PAB_attackmedia
  Pillar_3 =~ {AA, AB} CPA_freepolassoc + CPA_partdem_congress 
              + CPA_partdem_localgvt + CPA_cons_cso + CPA_cons_citizen 
              + {BA, BB} CPB_freeassoc + CPB_community
  Pillar_4 =~ CTZ_gendereq + CTZ_consrights + CTZ_laborcond + IPR_rights 
              + IPR_easy2read + IPR_easy2find + IPR_easy2find_online 
              + IRE_govtbudget + IRE_govtcontracts 
              + {AA, AB} CPA_freepolassoc + CPA_media_freeop + CPA_freevote 
              + CPA_partdem_congress + CPA_partdem_congress
              + {BA, BB} CPB_community + CPB_freeassem + CPB_freemedia 
              + CPB_freexp_cso + CPB_freexp_pp + CPB_freexp + CPB_unions
              + {AA, BA} LEP_rightsresp + LEP_exforce + LEP_pdaperformance 
              + CJP_fairtrial + CJP_proofburden
  Pillar_5 =~ {AB, BB} JSE_rightsaware + JSE_access2info + JSE_access2assis 
              + JSE_affordcosts + JSE_fairoutcomes + JSE_equality + JSE_enforce 
              + JSE_mediation
  Pillar_6 =~ TRT_police + COR_police + TRT_prosecutors + COR_prosecutors 
              + TRT_judges + COR_judges + TRT_pda + COR_pda 
              + {AA, BA} LEP_investigations + CJP_effective + CJP_efficient 
              + CJP_consistent + CJP_resprights + CJP_egalitarian 
              + CJP_victimsupport + LEP_rightsresp + LEP_exforce 
              + LEP_pdaperformance + CJP_fairtrial + CJP_proofburden 
              + CJP_saferights
              + {AB, BB} LEP_indpolinv
  Pillar_7 =~ COR_parliament + COR_govt_national + COR_govt_local + COR_judges 
              + COR_prosecutors + COR_pda + COR_police + COR_landreg 
              + COR_carreg + COR_pparties + COR_inst_eu + ORC_corimpact 
              + ORC_citizen_fight + ORC_govtefforts + ORC_impartial_measures 
              + ORC_pconnections + ATC_embezz_priv + ATC_recruitment_public
  Pillar_8 =~ IPR_rights + IPR_easy2read + IPR_easy2find + IPR_easy2find_online 
              + IRE_govtbudget + IRE_govtbudget
'

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##
## 4. Fitting the model                                                                                     ----
##
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

fit <- cfa(
  model_specification_1, 
  data      = subset4cfa, 
  estimator = "MLR", 
  # missing   = "FIML", 
  group     = "group"
)

