readPAF <- function(file, ...) {
  if(!require("data.table"))
  install.packages("data.table")

  col.names <- c("query", 
                "query_length",
                "query_start", 
                "query_end", 
                "strand",
                "target",
                "target_length",
                "target_start",
                "target_end",
                "nmatches",
                "aln_length",
                "map_quality")
  
  x <- data.table::fread(
    file, 
    header = FALSE,
    fill = TRUE,
    ...)
  
  colnames(x)[1:length(col.names)] <- col.names
  return(x)
}