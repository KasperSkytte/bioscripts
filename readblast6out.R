readblast6out <- function(file, ...) {
  if(!require("data.table"))
  install.packages("data.table")

  x <- data.table::fread(
    file, 
    header = FALSE,
    fill = TRUE,
    sep = "\t",
    col.names = c("query", 
                  "target",
                  "id", 
                  "aln_length", 
                  "n_missmatch",
                  "n_gapopen",
                  "query_start",
                  "query_end",
                  "target_start",
                  "target_end",
                  "evalue",
                  "bitscore")
    ...)
  return(x)
}
