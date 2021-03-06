Table of Contents
=================

   * [bioscripts](#bioscripts)
      * [<a href="https://github.com/KasperSkytte/bioscripts/blob/main/QIIMEToSINTAXFASTA.R">QIIMEToSINTAXFASTA.R</a>](#qiimetosintaxfastar)
      * [<a href="https://github.com/KasperSkytte/bioscripts/blob/main/findCopyFastq.sh">findCopyFastq.sh</a>](#findcopyfastqsh)
         * [Options](#options)
         * [Example output](#example-output)
      * [<a href="https://github.com/KasperSkytte/bioscripts/blob/main/install_singularity.sh">install_singularity.sh</a>](#install_singularitysh)
         * [Options](#options-1)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# bioscripts
Miscellaneous bioinformatic helper scripts for various tasks. I recommend only using those documented below, otherwise inspect and use at your own risk, guessing what they do. I will find time at some point to go through the rest, but for now they are just here to have a home.

## [QIIMEToSINTAXFASTA.R](https://github.com/KasperSkytte/bioscripts/blob/main/QIIMEToSINTAXFASTA.R)
R script used to create a SINTAX formatted taxonomic database (FASTA file with formatted headers) for use with the [usearch](https://drive5.com/usearch/) pipeline. The input should be two files: a FASTA file where headers only contain a single sequence ID, and a tab-separated text file with the taxonomy, where the first column contains the sequence ID's matching those in the FASTA file, and the second column the taxonomy string for each sequence ID in QIIME format. The script then reformats the taxonomy strings to match the [SINTAX taxonomy annotation format](http://drive5.com/usearch/manual/tax_annot.html), adds them to the FASTA headers and writes out. To use the script, just source it directly from GitHub in R with `source("https://raw.githubusercontent.com/KasperSkytte/bioscripts/master/QIIMEToSINTAXFASTA.R")`. It will check for required packages, but will not install any. For installing Bioconductor packages use `BiocManager::install()`.

## [findCopyFastq.sh](https://github.com/KasperSkytte/bioscripts/blob/main/findCopyFastq.sh)
BASH script to search for fastq files and copy to a folder for further analysis. Initially made to find Illumina MiSeq/HiSeq samples, but can be applied to anything else. 

### Options
```
$ ./findCopyFastq.sh -h
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

### Example output
```
$ ./findCopyFastq.sh
Finding and copying 5 sample(s)...
(1/5) MQ200204-1:  2 file(s)
(2/5) MQ200204-2:  2 file(s)
(3/5) MQ200204-3:  2 file(s)
(4/5) MQ200204-11:  2 file(s)
(5/5) test-123:  0 file(s)

1 sample(s) couldn't be found
```

## [install_singularity.sh](https://github.com/KasperSkytte/bioscripts/blob/main/install_singularity.sh)
Installs singularity (currently v3.6.3 using go v1.14.1) and required system dependencies (through APT) for it to run. Also updates your `$PATH` in `.bashrc` with the singularity binary. Tested on Ubuntu18.04 and Ubuntu20.04. If running Ubuntu16.04 or earlier replacing `libgpgme-dev` with `libgpgme11-dev` on this line will likely be needed:
https://github.com/KasperSkytte/bioscripts/blob/4f65e861eeb7d7201a4b900dddfae21af0bc3b04/install_singularity.sh#L81

### Options
```
$ ./install_singularity.sh -h
This script installs singularity and required system dependencies. If an install folder path is provided with the -p option, singularity will be installed only for the current user within a /singularity subfolder there and the $PATH variable will be permanently updated in ~/.bashrc for the current user. Otherwise will be installed system-wide into /usr/local/singularity.
Please provide sudo password when asked.
Version: 1.1
Options:
  -h    Display this help text and exit.
  -p    Path to folder where singularity will be installed (/singularity subfolder will be created). If not provided, will be installed system-wide in /usr/local/singularity.
```