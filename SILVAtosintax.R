#!/usr/bin/env R
silvatosintax <- function(
    tax_silva_file = "SILVA_138.1_SSURef_NR99_tax_silva.fasta",
    tax_sintax_file = paste0(
      tools::file_path_sans_ext(tax_silva_file),
      "_sintax.",
      tools::file_ext(tax_silva_file)
    ),
    filter_eukaryota = TRUE
) {
  req_pkgs <- c("Biostrings", "tidyr", "data.table", "stringi")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
  
  silva <- Biostrings::readBStringSet(tax_silva_file)
  
  if(isTRUE(filter_eukaryota)) {
    silva <- silva[!grepl("eukaryota", tolower(names(silva)))]
  }
  names <- do.call(rbind, stringi::stri_split_fixed(names(silva), " ", n = 2))
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
  names(silva) <- sintax_header
  Biostrings::writeXStringSet(silva, tax_sintax_file)
}
