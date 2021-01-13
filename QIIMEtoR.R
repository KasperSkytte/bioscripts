QIIMEtoR <- function(filepath) {
  if(!require("data.table")) {
    install.packages("data.table")
    require("data.table")
  }
  if(!require("stringi")) {
    install.packages("stringi")
    require("stringi")
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