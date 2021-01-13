#!/usr/bin/Rscript
#load R packages
suppressPackageStartupMessages({
  require("Biostrings")
  require("doParallel")
  require("plyr")
  require("data.table")
  require("dplyr")
})

cores <- 36L

#read sequences
ASVs <- Biostrings::readBStringSet("/home/kapper/Dropbox/AAU/PhD/Projects/MiDAS_global/amplicon_data/data/ASVs.R1.fa")[1:100]
ESVs <- Biostrings::readBStringSet("/home/kapper/Dropbox/AAU/PhD/Projects/ESV pipeline/runs/MiDAS4.1_20190602/output/ESVs_w_sintax.fa")

#Match ASVs to ESVs (ESVs must be longer)
doParallel::registerDoParallel(cores = cores)
res <- foreach::foreach(
  query = as.character(ASVs),
  name = names(ASVs),
  .inorder = TRUE,
  .combine = "rbind",
  .final = data.table) %dopar% {
    hitIDs <- stringi::stri_detect_fixed(pattern = query, str = ESVs)
    nHits <- sum(hitIDs)
    if(nHits == 0) {
      return(NULL)
    } else {
      targetHits <- ESVs[hitIDs]
      data.table(
        ASV = rep(name, times = nHits),
        ESV = names(targetHits),
        ESVlength = Biostrings::width(targetHits)
      )[order(ESVlength, decreasing = TRUE)]
    }
  }
res <- res[, .SD[1], by = ASV]

ASVtable <- data.table::fread("/home/kapper/Dropbox/AAU/PhD/Projects/MiDAS_global/amplicon_data/data/ASVtable.tsv", 
                              sep = "\t",
                              nThread = cores)
colnames(ASVtable)[1] <- "ASV"
#row wise calculations in data.table is SLOOOOW, use plyr
ASVcounts <- ddply(ASVtable, 
                   "ASV", 
                   function(x) 
                     sum(x[-1]),
                   .parallel = TRUE)
doParallel::stopImplicitCluster()
colnames(ASVcounts)[2] <- "count"
out <- left_join(res, ASVcounts, by = "ASV") %>% 
  arrange(desc(count)) %>% 
  select(1,3,2)

data.table::fwrite(out, "mapASVtoESV.txt", sep = "\t", col.names = TRUE)
data.table::fwrite(out[1:100,], "mapASVtoESV_top100.txt", sep = "\t", col.names = TRUE)