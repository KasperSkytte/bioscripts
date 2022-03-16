diffToR <- function(file1, file2, echo_cmd = TRUE) {
  req_pkgs <- c("processx", "data.table", "stringi")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
  if(.Platform$OS.type != "unix")
    stop("Function can only be used on unix systems that also has diff installed", call. = FALSE)
  
  res <- processx::run("diff",
                       args = c(file1, file2), 
                       echo_cmd = echo_cmd, 
                       error_on_status = FALSE)
  
  resChar <- unlist(stringi::stri_split(res$stdout, regex = "\n"), use.names = FALSE)
  diffLines <- data.table::data.table(
    file1 = gsub(pattern = "^< ", replacement = "", x = grep("^< ", resChar, value = TRUE)),
    file2 = gsub(pattern = "^> ", replacement = "", x = grep("^> ", resChar, value = TRUE))
  )
  return(diffLines)
}

