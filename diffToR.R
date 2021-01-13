require("processx")
require("tibble")
require("readr")
require("stringi")

diffToR <- function(file1, file2, echo_cmd = TRUE) {
  if(.Platform$OS.type != "unix")
    stop("Function can only be used on unix systems that also has diff installed", call. = FALSE)
  
  res <- processx::run("diff",
                       args = c(file1, file2), 
                       echo_cmd = echo_cmd, 
                       error_on_status = FALSE)
  
  resChar <- unlist(stringi::stri_split(res$stdout, regex = "\n"), use.names = FALSE)
  diffLines <- tibble::tibble(file1 = gsub(pattern = "^< ", replacement = "", x = grep("^< ", resChar, value = TRUE)),
                              file2 = gsub(pattern = "^> ", replacement = "", x = grep("^> ", resChar, value = TRUE)))
  return(diffLines)
}

