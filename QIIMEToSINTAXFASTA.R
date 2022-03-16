QIIMEToSINTAXFASTA <- function(fasta, tax, file = "file_w_sintax.fa", ...) {
  req_pkgs <- c("Biostrings", "data.table", "stringr")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
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
