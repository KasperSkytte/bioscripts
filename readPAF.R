readPAF <- function(file, ...) {
  req_pkgs <- c("data.table")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
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

  colnames(x)[seq_len(col.names)] <- col.names
  return(x)
}