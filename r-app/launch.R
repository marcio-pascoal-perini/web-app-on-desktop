args <- commandArgs(TRUE)

packages <- c('ggplot2', 'jsonlite', 'plumber', 'stringr')

if (is.na(args[1])) {
  stop('Working directory path is missing.')
  q()
}

if (is.na(args[2])) {
  stop('Library path is missing.')
  q()
}

if (is.na(args[3])) {
  stop('Host is missing.')
  q()
}

if (is.na(args[4])) {
  stop('Port is missing.')
  q()
}

tryCatch({
  setwd(args[1])
  .libPaths(args[2])
},
error = function(err) {
  stop(err)
  q()
})

tryCatch({
  if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
    install.packages(setdiff(packages, rownames(installed.packages())), repo = 'https://lib.ugent.be/CRAN/')
  }
},
error = function(err) {
  stop(err)
  q()
})

tryCatch({
  library(plumber)
  suppressMessages(pr(file = 'alphavantage.R') %>% pr_run(host = args[3], port = as.integer(args[4]), docs = FALSE, swaggerCallback = FALSE, quiet = FALSE))
},
error = function(err) {
  stop(err)
  q()
})
