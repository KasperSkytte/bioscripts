readblast6out <- function(file, ...) {
  req_pkgs <- c("data.table")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
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
                  "bitscore"),
    ...)
  return(x)
}
