library(optparse)

# Define command line options
option_list <- list(
  
  # Path management flags
  make_option(
    c("--mice"),
    action  = "store_true",
    default = FALSE,
    help    = "Perform MICE routine"
  ),
  make_option(
    c("--nlpca"),
    action  = "store_true",
    default = FALSE,
    help    = "Perform Non-Linear PCA routine"
  ),
  make_option(
    c("--verbose"),
    action  = "store_true",
    default = TRUE,
    help    = "Print verbose output during execution"
  )
)


# Parse command line options
opt_parser <- OptionParser(
  option_list     = option_list,
  add_help_option = TRUE,
  description     = "R project for the EU GPP Clustering"
  # epilogue    = "Example: Rscript main.R --data --analyze --vis"
)
opt <- parse_args(opt_parser)


# Helper function to print verbose messages
verbose_message <- function(message) {
  if (opt$verbose) {
    cat(paste0("[INFO] ", message, "\n"))
  }
}


# main.R EntryPoint
main <- function(){
  
  renv::activate()
  
  source("src/config.R")
  source("src/data_loading.R")
  
  if (opt$mice){
    verbose_message("Performing multiple imputation using MICE...")
    source("src/MICE.R")
  }
  
  if (opt$nlpca){
    verbose_message("Performing dimensionality reduction using NLPCA...")
    source("src/NLPCA.R")
  }

}


if(!interactive()){
  main()
  quit(save = "no", status = 0)
}