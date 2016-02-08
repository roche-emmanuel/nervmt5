# load the dependency packages:
library(data.table)
library(plyr)
library(fasttime)
library(pracma)

# Method used to load tick data from a raw file
# the pmode argument (price mode) will tell us if we want to get the
# bid price (="bid"), or the mean price (="mean")
loadTickData <- function(fname, pmode="mean")
{
  # The input data is located in RData/inputs/ folder:
  file <- paste0("RData/inputs/",fname,".csv")
  print(paste0("Loading dataset ",file,"..."))
  
  # In a tick file, the first colunm is for the date
  # The second column is for the bid price
  # The third column is for the ask price
  # Then we have 2 additional columns (not sure what they are)
  # For now we are only interested in the bid and ask prices:
  # We use both of those prices to build a "mean price" value:
  data <- fread(file,select=2:3)
  
  # By default use the bid price:
  # Note that the column name start as V2 since we ignore the date in V1:
  values <- data$V2
  
  if(pmode=="mean")
  {
    values <- (data$V2+data$V3)*0.5  
  }
  
  values
}

# Method used to downsample a given array with the provided period,
# This method will retrieve every "period" row from the source array
downsample <- function(arr,period)
{
  len <- length(arr)
  idx <- seq(from=period,to=len,by=period)
  
  arr[idx]
}

# Method used to generate all the patterns from a given price vector:
# patlen is the length of the patterns we want to consider.
generatePatterns <- function(arr,patlen = 30, predOffset = 20, predRange = 10)
{
  len <- length(arr)
  
  # Prepare the pattern matrix:
  # The maximum length that we should reach is: 
  maxlen <- len - 1 - predOffset - predRange
  
  # And we can only start generating patterns when we have patlen+1 elements, thus
  npat <- maxlen - patlen
  
  pmat <- matrix(data=NA,nrow=npat,ncol=patlen)
  preds <- matrix(data=NA,nrow=npat,ncol=predRange)
  
  for (i in 1:patlen)
  {
    pmat[,i] <- arr[i:(i+npat-1)]
  }
  
  poffset <- patlen+1+predOffset
  
  for (i in 1:predRange)
  {
    preds[,i] <- arr[(i+poffset):(i+poffset+npat-1)]
  }
  
  # Now we prepare the reference values:
  ref <- arr[(patlen+1):(patlen+npat)]
  
  # We substract this reference value from each element of a pattern row:
  pmat <- pmat - matrix(rep(ref,patlen),ncol=patlen)
  preds <- preds - matrix(rep(ref,predRange),ncol=predRange)
  
  # Then we need to normalize by the absolute value of this ref,
  # and multiply by 100.0 to convert into percent change values
  pmat <- 100.0 * pmat / matrix(rep(abs(ref),patlen),ncol=patlen)
  preds <- 100.0 * preds / matrix(rep(abs(ref),predRange),ncol=predRange)
  
  # Get the max/min/mean of each prediction row:
  print("Computing prediciton max...")
  maxi <- apply(preds, 1, max)
  print("Computing prediciton min...")
  mini <- apply(preds, 1, min)
  print("Computing prediciton mean...")
  mean <- apply(preds, 1, mean)
  
  list(patterns=pmat,predMaxi=maxi,predMini=mini,predMean=mean,ref=ref)
}

# will return the percentage of variations between all the patterns provided and the reference pattern:
computePatternVariations <- function(pattern, pool)
{
  # pool should be a matrix, so we can retrieve the number of rows:
  npat <- nrow(pool)

  # The number of cols in the pool should also match the number of elements in the pattern:
  plen <- length(pattern)
  if(plen != ncol(pool))
  {
    stop("Mismatch in pattern length and pool size.")
  }
  
  # replicate the pattern on as many rows as required:
  pmat <- matrix(rep(pattern, each=npat),nrow=npat)
  
  # Now substract the matrices:
  diff <- pool - pmat

  # Compute the norm of each row:
  norms <- apply(diff,1,Norm)
  
  # Get the norm of the input pattern:
  nval <- Norm(pattern)
  
  # Divide the diff norms by the pattern norm, and then multiply by 100.0 to get the percent change
  vars <- 100.0 * norms / nval
  
  # Now we return the variations:
  vars
}

# Method used to select the most similar patterns in the given pool,
# the varLevel is given in percent of variation acceptable
selectSimilarPatterns <- function(pattern, pool, predMean, varLevel=30.0)
{
  # First we have to compute the variations observed in the given pool:
  vars <- computePatternVariations(pattern, pool)
  
  # Now we should order those variation values:
  #idx <- sort.int(vars,decreasing = F, index.return = T)
  
  # Now we keep only the indices that are under the given threshold:
  goodvars <- vars < varLevel
  
  # keep only the selected vars:
  vars <- vars[goodvars]
  
  # we also keep only the selected predictions:
  mean <- predMean[goodvars]
  
  list(vars=vars, means=mean)
}

# Method used to compute the accuracy of the prediction given a pattern dataset
computeAccuracy <- function(data, startPat = 5001, endPat = 10000, poolSize = 5000, varLevel = 30.0, minSims = 0)
{
  accuracy <- numeric(0)
  macc <- numeric(0)
  
  for(i in startPat:endPat)
  {
    # select the similar patterns:
    sims <- selectSimilarPatterns(data$patterns[i,],data$patterns[(i-poolSize):(i-1),],data$predMean[(i-poolSize):(i-1)],varLevel)
    
    if(length(sims$means) > minSims)
    {
      # compute the mean of the predictions:
      pred <- mean(sims$means)
      
      # now compare that with the actual value for this pattern:
      realMean <- data$predMean[i]
      
      if(pred*realMean > 0.0)
      {
        accuracy <- c(accuracy,1.0)
      }
      else
      {
        accuracy <- c(accuracy,0.0)
      }
      
      m <- mean(accuracy)*100.0
      acc <- sprintf("%.2f%%",m)
      comp <- sprintf("%.0f%%",100.0*(i-startPat)/(endPat-startPat))
      
      macc <- c(macc,m)
      print(paste0("Accuracy = ",acc," with ",length(accuracy)," samples. Completed=",comp))
    }
  }
  
  accuracy
}
