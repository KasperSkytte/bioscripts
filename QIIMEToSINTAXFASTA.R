reqPkgs <- c("Biostrings", "data.table", "stringr")
if(!all(reqPkgs %in% installed.packages()[,"Package"]))
  stop("QIIMEToSINTAXFASTA() requires the following packages:\n", paste(reqPkgs, collapse = "\n"), call. = FALSE)

QIIMEToSINTAXFASTA <- function(fasta, tax, file = "file_w_sintax.fa", ...) {
  seqs <- Biostrings::readBStringSet(fasta)
  taxonomy <- data.table::fread(tax, 
                                fill = TRUE,
                                header = FALSE,
                                sep = "\t",
                                col.names = c("ID", "taxonomy"),
                                ...)
  names <- data.table::data.table(ID = names(seqs))
  
  #check if files match
  if(nrow(names) != nrow(taxonomy) & !all(names[,ID] %in% taxonomy[,ID]))
    stop("fasta file and QIIME taxonomy file don't match", call. = FALSE)
  
  #sort taxonomy according to FASTA file
  taxonomy <- taxonomy[names, on = "ID"]
  
  taxonomy[,taxonomy := stringr::str_replace_all(
    taxonomy,
    c("[kd]+_+" = "d:", 
      ";p__" = ",p:",
      ";c__" = ",c:",
      ";o__" = ",o:",
      ";f__" = ",f:",
      ";g__" = ",g:",
      ";s__" = ",s:"))]
  newnames <- paste0(apply(taxonomy, 1, paste0, collapse = ";tax="), ";")
  names(seqs) <- newnames
  
  Biostrings::writeXStringSet(seqs, file)
  invisible(seqs)
}
