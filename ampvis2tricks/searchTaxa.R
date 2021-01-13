library(ampvis2)
searchStrings <- c("nocardioides", "trichococcus", "carnobacter")
d <- AalborgWWTPs

result <- unlist(lapply(d$tax, function(x) {
  unique(x[stringi::stri_detect_regex(str = tolower(x), pattern = paste0(tolower(searchStrings), collapse = "|"))])
}), use.names = FALSE)

ds <- amp_subset_taxa(d, result)
