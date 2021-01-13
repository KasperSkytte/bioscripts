  suppressPackageStartupMessages({
    #Biostrings (and BiocManager which is used to install Biostrings)
    if(!require("Biostrings")) {
      if(!require("BiocManager")) {
        install.packages("BiocManager")
      }
      BiocManager::install("Biostrings", update = FALSE, ask = FALSE)
    }
    if(!require("Biostrings"))
      stop("   The Biostrings R package is not available, skipping step", call. = FALSE)
    
    #dplyr
    if(!require("dplyr")) {
      install.packages("dplyr")
      require("dplyr")
    }
    
    #plyr
    if(!require("plyr")) {
      install.packages("plyr")
      require("plyr")
    }
    
    #stringr
    if(!require("stringr")) {
      install.packages("stringr")
      require("stringr")
    }
  })
  ##### export ASVs with SINTAX taxonomy in headers #####
  sintax <- readLines("ASVsV13_v1.0_20190205/ASVs.R1.sintax")
  taxdf <- plyr::ldply(str_split(sintax, "\t"), function(x) {
    x <- x[c(1,4)]
    if(is.null(x[2]) | x[2] == "")
      x[2] <- "d:unclassified"
    return(x)
  })
  colnames(taxdf) <- c("ASV", "tax")
  
  ASVs.fa <- readBStringSet("ASVsV13_v1.0_20190205/ASVs.R1.fa")
  sintaxdf <- left_join(tibble(ASV = names(ASVs.fa)), taxdf, by = "ASV")
  sintax_header <- paste0(sintaxdf[["ASV"]], ";tax=", sintaxdf[["tax"]], ";")
  names(ASVs.fa) <- sintax_header
  writeXStringSet(ASVs.fa, "ASVs.R1.w_sintax.fa")
