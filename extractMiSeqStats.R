extractMiSeqStats <- function(path = ".") {
	if(!require("data.table"))
	  install.packages("data.table")
	if(!require("magrittr"))
	  install.packages("magrittr");require("magrittr")
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
		  file <- file[1:(grep("#", file)[1]-1)]
		  CSVpath <- paste0(csvdir, tools::file_path_sans_ext(basename(x)), ".csv")
		  writeLines(file, CSVpath)
		  data.table::fread(CSVpath)
		}
	  }) %>% 
	  data.table::rbindlist(fill = TRUE)
	return(stats)
}