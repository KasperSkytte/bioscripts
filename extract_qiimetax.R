#!/usr/bin/env R
#' @title Extract taxonomy from FASTA file and output QIIME formatted taxonomy.
#' @description extracts taxonomy from fasta sequence headers and outputs a QIIME formatted taxonomy table as well as the sequences without the taxonomy string. Eukaryotes are filtered for now. To keep Eukaryotes everything in between domain+phylum should be removed and only 7 levels kingdom/domain -> species should remain.
#'
#' @param input_seqs (Required) Path to input fasta file
#' @param output_seqs Path to output fasta file
#' @param output_tax Path to output taxonomy TSV table
#'
#' @return A list
#' @import Biostrings data.table stringi
#' @author Kasper Skytte Andersen \email{ksa@@bio.aau.dk}
extract_qiimetax <- function(
  input_seqs,
  output_seqs = paste0(
    tools::file_path_sans_ext(input_seqs),
    "_noeuk.",
    tools::file_ext(input_seqs)
  ),
  output_tax = paste0(
    tools::file_path_sans_ext(input_seqs),
    "_noeuk_qiimetax.tsv"
  )
) {
  req_pkgs <- c("Biostrings", "data.table", "stringi")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }

  #read fasta file
  seqs <- readBStringSet(input_seqs)

  #extract taxonomy
  tax <- trimws(
    stri_extract_all_regex(
      names(seqs),
      "[\t ]+.*$"
    )
  )

  #filter Eukaryotes
  non_euk_ids <- stri_detect_regex(
    tolower(tax),
    "^eukar",
    negate = TRUE
  )
  seqs <- seqs[non_euk_ids]
  tax <- tax[non_euk_ids]

  #extract sequence IDs' from headers and rename input seqs
  seq_ids <- stri_replace_all_regex(
    names(seqs),
    "[\t ].*$",
    ""
  )
  names(seqs) <- seq_ids

  #generate taxonomy table
  taxonomy <- data.table(
    seq_ids,
    tax
  )

  tax_levels <- c(
    "Kingdom",
    "Phylum",
    "Class",
    "Order",
    "Family",
    "Genus",
    "Species"
  )

  #split up taxonomy column into separate columns with tax levels
  taxonomy[, c(tax_levels) := tstrsplit(tax, ";", fixed = FALSE)] # nolint

  #trim white spaces and add tax level prefix
  taxonomy[, Kingdom := trimws(paste0("k__", Kingdom))] # nolint
  taxonomy[, Phylum := trimws(paste0("p__", Phylum))] # nolint
  taxonomy[, Class := trimws(paste0("c__", Class))] # nolint
  taxonomy[, Order := trimws(paste0("o__", Order))] # nolint
  taxonomy[, Family := trimws(paste0("f__", Family))] # nolint
  taxonomy[, Genus := trimws(paste0("g__", Genus))] # nolint
  taxonomy[, Species := trimws(paste0("s__", Species))] # nolint

  #combine columns again with "; " separator
  qiime_tax <- taxonomy[
    ,
    .(seq_ids, tax = do.call(paste, c(.SD, sep = "; "))),
    .SDcols = tax_levels
  ]

  #write out files
  Biostrings::writeXStringSet(
    seqs,
    output_seqs
  )
  fwrite(
    qiime_tax,
    output_tax,
    col.names = FALSE,
    row.names = FALSE,
    sep = "\t"
  )
  invisible(
    list(
      seqs = seqs,
      qiime_tax = qiime_tax
    )
  )
}