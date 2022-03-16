QIIMEtoR <- function(filepath) {
  req_pkgs <- c("data.table", "stringi")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
  tax <- data.table::fread(filepath,
                           sep = "\t",
                           fill = TRUE,
                           header = FALSE,
                           data.table = TRUE,
                           col.names = c("SeqID", "taxonomy")
  )
  
  # Separate each taxonomic level into individual columns.
  # This has to be done separately as taxonomic levels can be blank
  # in between two other levels.
  tax[, Kingdom := stringi::stri_extract_first_regex(taxonomy, "[dk]_*[^;]*")]
  tax[, Phylum := stringi::stri_extract_first_regex(taxonomy, "p[_]+[^;]*")]
  tax[, Class := stringi::stri_extract_first_regex(taxonomy, "c[_]+[^;]*")]
  tax[, Order := stringi::stri_extract_first_regex(taxonomy, "o[_]+[^;]*")]
  tax[, Family := stringi::stri_extract_first_regex(taxonomy, "f[_]+[^;]*")]
  tax[, Genus := stringi::stri_extract_first_regex(taxonomy, "g[_]+[^;]*")]
  tax[, Species := stringi::stri_extract_first_regex(taxonomy, "s[_]+[^;]*")]
  tax[, taxonomy := NULL]
  return(tax)
}