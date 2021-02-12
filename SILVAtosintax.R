require(data.table)
require(Biostrings)
require(tidyr)
folder <- ""
inFile <- "SILVA_138.1_SSURef_NR99_tax_silva.fasta"
outFile <- "SILVA_138.1_SSURef_NR99_tax_silva_sintax.fasta"
inFilePath <- paste0(folder, inFile)
outFilePath <- paste0(folder, outFile)

SILVA <- Biostrings::readBStringSet(inFilePath)
#SILVA <- SILVA[!grepl("eukaryota", tolower(names(SILVA)))]
names <- do.call(rbind, stringi::stri_split_fixed(names(SILVA), " ", n = 2))
namesDT <- data.table(ID = names[,1], tax = names[,2])
taxCols <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
sintax <- tidyr::separate(
  namesDT,
  col = "tax",
  into = taxCols,
  sep = ";")
sintax[
  ,
  (taxCols) := lapply(.SD, function(x) {
    x <- gsub(",|;", ".", x)
    x[grepl("uncultured|unknown|unidentified|incertae sedis|metagenome|\\bbacterium\\b|\\bpossible\\b", tolower(x))] <- NA
    return(x)
    }),
  .SDcols = taxCols]

sintax[, Kingdom := ifelse(is.na(Kingdom), NA, paste0("d:", Kingdom))]
sintax[, Phylum := ifelse(is.na(Phylum), NA, paste0("p:", Phylum))]
sintax[, Class := ifelse(is.na(Class), NA, paste0("c:", Class))]
sintax[, Order := ifelse(is.na(Order), NA, paste0("o:", Order))]
sintax[, Family := ifelse(is.na(Family), NA, paste0("f:", Family))]
sintax[, Genus := ifelse(is.na(Genus), NA, paste0("g:", Genus))]
sintax[, Species := ifelse(is.na(Species), NA, paste0("s:", Species))]

sintax_header <- paste0(sintax[,ID], ";tax=", tidyr::unite(sintax[,-1], col = "tax", sep = ",", na.rm = TRUE)[,tax], ";")
names(SILVA) <- sintax_header
Biostrings::writeXStringSet(SILVA, outFilePath)
