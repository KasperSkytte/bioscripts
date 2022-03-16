#!/usr/bin/env R
#this script scans for all STATS files recursively
#in Illumina MiSeq run folders, extracts the sample table
#from the [Data] part of the file, then creates a data.table
#for each file found and merges them all into 1 big data.table
extractMiSeqStats <- function(path = ".") {
  req_pkgs <- c("data.table", "magrittr")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }

  csvdir <- "stats-files/"
  dir.create(csvdir)
  stats <- list.files(path,
             pattern = "STATS.*.txt$",
             full.names = TRUE,
             recursive = TRUE) %>%
    lapply(function(x) {
      file <- readLines(x)
      file <- file[-which(is.na(file) | file == "")]
    finddata <- grep("\\[Data\\]", file)
    if(length(finddata) == 0) {
      message("No \"[Data]\" line found in file ", basename(x), ", skipping...")
    } else {
      file <- file[-c(1:finddata)]
      file <- file[1:(grep("#", file)[1] - 1)]
      CSVpath <- paste0(csvdir, tools::file_path_sans_ext(basename(x)), ".csv")
      writeLines(file, CSVpath)
      data.table::fread(CSVpath)
    }
    }) %>%
    data.table::rbindlist(fill = TRUE)
  return(stats)
}