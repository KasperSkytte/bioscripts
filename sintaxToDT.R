reqPkgs <- c("Biostrings", "data.table", "stringi")
if(!all(reqPkgs %in% installed.packages()[,"Package"]))
  stop("sintaxToDT() requires the following packages:\n", paste(reqPkgs, collapse = "\n"), call. = FALSE)
       
sintaxToDT <- function(file) {
  fasta_stats <- Biostrings::fasta.index(file)
  tax <- data.table::data.table(header = stringi::stri_replace_all_regex(fasta_stats[["desc"]], pattern = ";$", ""))
  tax[, ID := as.character(stringi::stri_extract_all_regex(header, "^[^;]*"))]
  tax[, Kingdom := as.character(stringi::stri_extract_all_regex(header, "[kd]:[^,]*"))]
  tax[, Phylum := as.character(stringi::stri_extract_all_regex(header, "[p]:[^,]*"))]
  tax[, Class := as.character(stringi::stri_extract_all_regex(header, "[c]:[^,]*"))]
  tax[, Order := as.character(stringi::stri_extract_all_regex(header, "[o]:[^,]*"))]
  tax[, Family := as.character(stringi::stri_extract_all_regex(header, "[f]:[^,]*"))]
  tax[, Genus := as.character(stringi::stri_extract_all_regex(header, "[g]:[^,]*"))]
  tax[, Species := as.character(stringi::stri_extract_all_regex(header, "[s]:[^,]*"))]
  tax[, header := NULL]
  data.table::dcast(data.table::melt(tax, id.vars = "ID")[,value := substring(value, 3), by = ID], ID~variable)
}
