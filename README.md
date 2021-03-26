# bioscripts
Miscellaneous bioinformatic helper scripts for various tasks. I recommend only using those documented below, otherwise inspect and use at your own risk, guessing what they do. I will find time at some point to go through the rest, but for now they are just here to have a home.

## [QIIMEToSINTAXFASTA.R](https://github.com/KasperSkytte/bioscripts/blob/main/QIIMEToSINTAXFASTA.R)
R script used to create a SINTAX formatted taxonomic database (FASTA file with formatted headers) for use with the [usearch](https://drive5.com/usearch/) pipeline. The input should be two files: a FASTA file where headers only contain a single sequence ID, and a tab-separated text file with the taxonomy, where the first column contains the sequence ID's matching those in the FASTA file, and the second column the taxonomy string for each sequence ID in QIIME format. The script then reformats the taxonomy strings to match the [SINTAX taxonomy annotation format](http://drive5.com/usearch/manual/tax_annot.html), adds them to the FASTA headers and writes out. To use the script, just source it directly from GitHub in R with `source("https://raw.githubusercontent.com/KasperSkytte/bioscripts/master/QIIMEToSINTAXFASTA.R")`. It will check for required packages, but will not install any. For installing Bioconductor packages use `BiocManager::install()`.

## [findCopyFastq.sh](https://github.com/KasperSkytte/bioscripts/blob/main/findCopyFastq.sh)
BASH script to search for fastq files and copy to a folder for further analysis. Initially made to find Illumina MiSeq/HiSeq samples, but can be applied to anything else. 

```
$ findCopyFastq.sh -h
Find and copy fastq files. Reports for each sample how many files were found and copied.
Options:
  -h    Display this help text and exit.
  -i    (Required) Path to file containing sample ID's to find and copy. One sample ID per line. 
          (Default: samples)
  -f    (Required) Path to folder containing fastq files (will be searched recursively). 
          (Default: /space/sequences/Illumina/)
  -o    (Required) Output folder to copy fastq files into. 
          (Default: fastq)
  -s    Separator to append after sample name. 
          (Default: _)
```
