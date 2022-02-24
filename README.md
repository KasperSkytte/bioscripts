Table of Contents
=================

* [bioscripts](#bioscripts)
   * [cutadapt_demultiplex.sh](#cutadapt_demultiplexsh)
      * [Installation and usage](#installation-and-usage)
      * [Example](#example)
   * [QIIMEToSINTAXFASTA.R](#qiimetosintaxfastar)
   * [findCopyFastq.sh](#findcopyfastqsh)
      * [Installation and usage](#installation-and-usage-1)
      * [Example output](#example-output)
   * [install_singularity.sh](#install_singularitysh)
      * [Installation and usage](#installation-and-usage-2)
   * [docker-rstudio-renv.sh](#docker-rstudio-renvsh)
      * [Example output](#example-output-1)
   * [parallel_usearch_global](#parallel_usearch_global)
      * [Installation and usage](#installation-and-usage-3)
* [Table of Contents](#table-of-contents)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

# bioscripts
Miscellaneous bioinformatic helper scripts for various tasks. I recommend only using those documented below, otherwise inspect and use at your own risk, guessing what they do. I will find time at some point to go through the rest, but for now they are just here to have a home. 

**Always inspect scripts before running them!**

## cutadapt_demultiplex.sh
Demultiplex reads using `cutadapt` based on a fasta file with barcodes. Creates a subfolder for each barcode name in the fasta file and outputs all demultiplexed reads to a single file there with the same file extension as the input file. The input file must be a single file with all reads in either `fastq` or `fasta` format, `gz` compressed or not.

### Installation and usage
```
$ wget https://raw.githubusercontent.com/KasperSkytte/bioscripts/main/cutadapt_demultiplex.sh
$ bash cutadapt_demultiplex.sh -h
Creates a subfolder for each barcode sequence in a fasta file and demultiplexes the input file using cutadapt based on the barcode file. Check the cutadapt command manually if it makes sense for your data.
version: 1.0
Options:
  -h    Display this help text and exit.
  -v    Print version and exit.
  -i    (required) Input fastq or fasta file, compressed or not.
  -o    (required) Output folder.
  -b    (required) Fasta file with barcode sequences.
  -t    Max number of max_threads to use. (Default: all available except 2)
```

### Example
```
$ bash cutadapt_demultiplex.sh -i fastq_pass/unclassified/allreads.fastq.gz -o fastq_pass/ -b barcodes.fa 
```

## QIIMEToSINTAXFASTA.R
R script used to create a SINTAX formatted taxonomic database (FASTA file with formatted headers) for use with the [usearch](https://drive5.com/usearch/) pipeline. The input should be two files: a FASTA file where headers only contain a single sequence ID, and a tab-separated text file with the taxonomy, where the first column contains the sequence ID's matching those in the FASTA file, and the second column the taxonomy string for each sequence ID in QIIME format. The script then reformats the taxonomy strings to match the [SINTAX taxonomy annotation format](http://drive5.com/usearch/manual/tax_annot.html), adds them to the FASTA headers and writes out. To use the script, just source it directly from GitHub in R with `source("https://raw.githubusercontent.com/KasperSkytte/bioscripts/master/QIIMEToSINTAXFASTA.R")`. It will check for required packages, but will not install any. For installing Bioconductor packages use `BiocManager::install()`.

## findCopyFastq.sh
BASH script to search for fastq files and copy to a folder for further analysis. Initially made to find Illumina MiSeq/HiSeq samples, but can be applied to anything else. 

### Installation and usage
```
$ wget https://raw.githubusercontent.com/KasperSkytte/bioscripts/main/findCopyFastq.sh
$ bash findCopyFastq.sh -h
Find and copy fastq files. Reports for each sample how many files were found and copied.
Options:
  -h    Display this help text and exit.
  -i    (Required) Path to file containing sample ID's to find and copy. One sample ID per line. 
          (Default: samples)
  -f    (Required) Path to folder containing fastq files (will be searched recursively). 
          (Default: /space/sequences/Illumina/)
  -o    (Required) Output folder to copy fastq files into. 
          (Default: fastq)
  -d    (flag) Don't copy the files, instead only report whether they are found or not.
  -s    Separator to append after sample name. 
          (Default: _)
```

### Example output
```
$ bash findCopyFastq.sh
Searching for 5 sample(s) in /space/sequences/Illumina/...
Copying files into fastq
(1/5) MQ200204-1:  2 file(s) found and copied
(2/5) MQ200204-2:  2 file(s) found and copied
(3/5) MQ200204-3:  2 file(s) found and copied
(4/5) MQ200204-11:  2 file(s) found and copied
(5/5) test-123:  0 file(s) found and copied

1 sample(s) couldn't be found
```

## install_singularity.sh
Installs singularity (currently v3.9 using go v1.17.3) and required system dependencies (through APT) for it to run. Also updates your `$PATH` in `.bashrc` with the singularity binary. Only for Ubuntu and Debian based distros

### Installation and usage
```
$ wget https://raw.githubusercontent.com/KasperSkytte/bioscripts/main/install_singularity.sh
$ bash install_singularity.sh -h
This script installs singularity and required system dependencies. If an install folder path is provided with the -p option, singularity will be installed only for the current user within a /singularity subfolder there and the $PATH variable will be permanently updated in ~/.bashrc for the current user. Otherwise will be installed system-wide into /usr/local/singularity.
Please provide sudo password when asked.
Version: 1.2.1
Options:
  -h    Display this help text and exit.
  -p    Path to folder where singularity will be installed (/singularity subfolder will be created). If not provided, will be installed system-wide in /usr/local/singularity.
```

## docker-rstudio-renv.sh
Builds and launches an RStudio docker container based on a specific R version of your choice. The image is based on the [rocker/rstudio](https://hub.docker.com/r/rocker/rstudio) image with some extra nice-to-have system dependencies like `libxml2-dev`, `libcairo2-dev`, `libxt-dev`, and more, which are often needed by some R packages. It has built-in support for [`renv`](https://rstudio.github.io/renv/) set up with a global package cache on the host at `${HOME}/.local/share/renv/cache` (default) to avoid unnecessary repeated installation of the same packages across projects. Once the container is built, the script will search for an open port and start the container with the particular port exposed, and the current user's home directory will be mounted at /`home/rstudio/`. Running the script multiple times will launch multiple different RStudio instances each on its own port.

To build and start a container with for example R version 4.0.3, either download the script and run `bash docker-rstudio-renv.sh 4.0.3`, or source the script directly from this repo with this one-liner:

```
curl -fsSL https://raw.githubusercontent.com/KasperSkytte/bioscripts/main/docker-rstudio-renv.sh | bash -s 4.0.3
```

For the latest R version just ommit any arguments. A few additional environment variables can be set before running the script to adjust things: image_name, password, and port. Otherwise default values will be used.

### Example output
```
$ bash docker-rstudio-renv.sh 4.0.3
Sending build context to Docker daemon  3.072kB
Step 1/7 : FROM rocker/rstudio:4.0.3
4.0.3: Pulling from rocker/rstudio

... lines removed ...

Successfully built a7343a1294e2
Successfully tagged rstudio_r4.0.3:latest
5df65918a44d13b47e441c8c0f4be243beee18e822ab315bfd6b6095f561243e

Launch RStudio through a browser at one of these adresses:
http://127.0.0.1:8787 (this machine only)
http://192.168.0.4:8787

Username: rstudio
Password: supersafepassword
```

As noted above, just launch RStudio through a browser at the particular address and log in with the super safe password. Enjoy your 100% reproducible and portable R session.

## parallel_usearch_global
`usearch -usearch_global` does not scale linearly with the number of threads,
it's orders of magnitude faster to split into smaller jobs and run in parallel using
GNU parallel, then concatenate results afterwards.

### Installation and usage
The script can be either run as a standalone script or sourced as a function for use in another BASH script as part of a pipeline. Currently only outputs in `blast6out` format, but can easily be adapted to something else.

```
$ wget https://raw.githubusercontent.com/KasperSkytte/bioscripts/main/parallel_usearch_global.sh
$ bash parallel_usearch_global.sh -h
Runs usearch11 -usearch_global in parallel by splitting the input data and process in smaller chunks. Much faster than just using more threads with one command.
Options:
  -h    Display this help text and exit.
  -v    Print version and exit.
  -i    (required) Input file name.
  -o    (required) Output file name.
  -d    (required) Database file.
  -a    Additional arguments passed on to the usearch11 -usearch_global command as one quoted string, fx: -a "-maxrejects 8 -strand plus"
  -t    Max number of max_threads to use. (Default: all available except 2)
```

or when sourced from another script it will be available as a function call:

`script.sh`:
```
#!/usr/bin/env bash

#load function
. parallel_usearch_global.sh

#run usearch_global in parallel
parallel_usearch_global \
  -i inputseqs.fa \
  -o test.b6 \
  -d databasefile.fa \
  -t 10 \
  -a "-id 0.99 -maxaccepts 8 -maxrejects 32 -strand plus"

#some other steps based on the search...
```
