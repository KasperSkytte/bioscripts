#!/usr/bin/env R
addsintaxtofasta <- function(
  input_seqs,
  sintax_file,
  output_seqs = paste0(
    tools::file_path_sans_ext(input_seqs),
    "_w_sintax.",
    tools::file_ext(input_seqs)
  )
) {
  req_pkgs <- c("Biostrings", "dplyr", "plyr", "stringr")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }

  ##### export ASVs with SINTAX taxonomy in headers #####
  sintax <- readLines(sintax_file)
  taxdf <- plyr::ldply(str_split(sintax, "\t"), function(x) {
    x <- x[c(1,4)]
    if(is.null(x[2]) | x[2] == "")
      x[2] <- "d:unclassified"
    return(x)
  })
  colnames(taxdf) <- c("ASV", "tax")

  ASVs.fa <- readBStringSet(input_seqs)
  sintaxdf <- left_join(tibble(ASV = names(ASVs.fa)), taxdf, by = "ASV")
  sintax_header <- paste0(sintaxdf[["ASV"]], ";tax=", sintaxdf[["tax"]], ";")
  names(ASVs.fa) <- sintax_header
  writeXStringSet(ASVs.fa, output_seqs)
}
