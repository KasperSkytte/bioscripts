#!/usr/bin/env bash
# This BASH script is based on the template from https://github.com/kasperskytte/bash_template

##### settings start ######
#exit when a command fails (use "|| :" after a command to allow it to fail)
set -o errexit

# exit when a pipe fails
set -o pipefail

#disallow clobbering (overwriting) of files
set -o noclobber

#print exactly what gets executed (useful for debugging)
#set -o xtrace

version="1.0"

#use all logical cores except 2 unless adjusted by user
max_threads=${max_threads:-$(($(nproc)-2))}

##### settings end #####

#function to show a standard error message
usageError() {
  echo "Invalid usage: $1" 1>&2
  echo ""
  eval "bash $0 -h"
}

#function to add timestamps to progress messages
scriptMessage() {
  #check user arguments
  if [ ! $# -eq 1 ]
  then
    echo "Error: function must be passed exactly 1 argument" >&2
    exit 1
  fi
  echo " *** [$(date '+%Y-%m-%d %H:%M:%S')] script message: $1"
}

#function to check if executable(s) are available in $PATH
checkCommand() {
  args="$*"
  exit="no"
  for arg in $args
  do
    if [ -z "$(command -v "$arg")" ]
    then
      echo "${arg}: command not found"
      exit="yes"
    fi
  done
  if [ $exit == "yes" ]
  then
    exit 1
  fi
}

#check for all required commands before doing anything else
checkCommand cutadapt xargs awk

#fetch and check options provided by user
while getopts ":hb:t:o:vi:" opt; do
case ${opt} in
  h )
    echo "Creates a subfolder for each barcode sequence in a fasta file and demultiplexes the input file using cutadapt based on the barcode file. Check the cutadapt command manually if it makes sense for your data."
    echo "version: $version"
    echo "Options:"
    echo "  -h    Display this help text and exit."
    echo "  -v    Print version and exit."
    echo "  -i    (required) Input fastq or fasta file, compressed or not."
    echo "  -o    (required) Output folder."
    echo "  -b    (required) Fasta file with barcode sequences."
    echo "  -t    Max number of max_threads to use. (Default: all available except 2)"
    exit 1
    ;;
  i )
    input_file=$OPTARG
    ;;
  o )
    output_folder=$OPTARG
    ;;
  b )
    barcode_file=$OPTARG
    ;;
  t )
    max_threads=$OPTARG
    ;;
  v )
    echo "version: $version"
    exit 0
    ;;
  \? )
    usageError "Invalid Option: -$OPTARG"
    exit 1
    ;;
  : )
    usageError "Option -$OPTARG requires an argument"
    exit 1
    ;;
esac
done
shift $((OPTIND -1)) #reset option pointer

#check required options
if [[ -z "$barcode_file" ]]
then
  usageError "option -b is required"
	exit 1
fi
if [[ -z "$output_folder" ]]
then
	usageError "option -o is required"
	exit 1
fi
if [[ -z "$input_file" ]]
then
	usageError "option -i is required"
	exit 1
fi

mkdir -p "$output_folder"

# create subfolders in output folder for each barcode
awk '/^>/ {gsub("^>", ""); print $0}' \
  "$barcode_file" |\
  xargs \
    -I% \
    mkdir -p \
      "${output_folder}/%" \
      "${output_folder}/unknown"

# filter barcodes and demultiplex
# extract file extension(s) from input file and use the same for output file
cutadapt \
  -e 0.05 \
  -j "${max_threads}" \
  --no-indels \
  --json="${output_folder}/demultiplex.cutadapt.json" \
  -b file:"${barcode_file}" \
  -o "${output_folder}/{name}/allreads.${input_file#*.}" \
  "${input_file}" \
  --quiet
