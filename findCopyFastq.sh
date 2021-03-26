#!/usr/bin/env bash
set -eu

#default options
fastq="/space/sequences/Illumina/"
input="samples"
output="fastq"
samplesep="_"

#default error message if bad usage
usageError() {
  echo "Error: $1" 1>&2
  echo ""
  eval "bash $0 -h"
}

while getopts ":hi:f:o:s:" opt
do
case ${opt} in
  h )
    echo "Find and copy fastq files. Reports for each sample how many files were found and copied."
    echo "Options:"
    echo "  -h    Display this help text and exit."
    echo -e "  -i    (Required) Path to file containing sample ID's to find and copy. One sample ID per line. \n          (Default: ${input})"
    echo -e "  -f    (Required) Path to folder containing fastq files (will be searched recursively). \n          (Default: ${fastq})"
    echo -e "  -o    (Required) Output folder to copy fastq files into. \n          (Default: ${output})"
    echo -e "  -s    Separator to append after sample name. \n          (Default: ${samplesep})"
    exit 1
    ;;
  i )
    input="$OPTARG"
    ;;
  f )
    fastq="$OPTARG"
    ;;
  o )
    output="$OPTARG"
    ;;
  s )
    samplesep="$OPTARG"
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

# check options
if [ ! -s "$input" ]
then
  usageError "File '${input}' does not exist or is empty"
  exit 1
fi
if [ ! -d "$fastq" ]
then
  usageError "Directory '${fastq}' does not exist"
  exit 1
fi

mkdir -p "$output"

#clean samples file
  tr "\r" "\n" < "$input" |\
  sed -e '$a\' |\
  sed -e '/^$/d' -e 's/ //g' > "${output}/samples.txt"

nsamples=$(wc -w < "${output}/samples.txt")
echo "Finding and copying ${nsamples} sample(s)..."
i=0
notFound=0
while ((i++)); read -r sample
do
  echo -n "($i/$nsamples) $sample:  "
  fileStatus=$(find "$fastq" -type f -name "*${sample}${samplesep}*.f*q*" -print -exec cp {} -t "$output" \; | wc -l)
  if [ "$fileStatus" -eq 0 ]
  then
    ((notFound=notFound+1))
  fi
  echo "$fileStatus file(s)"
done < "${output}/samples.txt"

echo
if [ "$notFound" != "0" ]
then
  echo "$notFound sample(s) couldn't be found"
else
  echo "All samples were found"
fi
