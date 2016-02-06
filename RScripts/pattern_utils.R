# load the dependency packages:
library(data.table)
library(plyr)
library(fasttime)

# Method used to load tick data from a raw file
loadTickData <- function(fname)
{
  # The input data is located in RData/inputs/ folder:
  file <- paste0("RData/inputs/",fname,".csv")
  print(paste0("Loading dataset ",file,"..."))
  
  data <- fread(file,select=1:6)
}