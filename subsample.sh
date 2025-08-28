#!/usr/bin/bash -l
#SBATCH --job-name=subsample
#SBATCH --output=job_%j_%x.out
#SBATCH --cpus-per-task=32
#SBATCH --time=0-01:00:00
#SBATCH --mem=5G

# Script to subsample a nanopore run (or maybe others too).
# Will run in parallel for each barcode folder to speed it up, but it will likely be IO limited, so using more CPUs may not be faster.

set -euo pipefail

# adjust these 3 variables, then submit the script.
input_dir="data/2025-04-hyp"
output_dir="data_subsampled"
sample_sizes="1000 2000 5000 10000"

export output_dir sample_sizes

# function to concatenate and subsample fastq files
concat_subsample() {
  barcode="$1"
  barcodename=$(basename "$barcode")
  echo "Processing barcode: ${barcodename}"

  barcodefolder="${output_dir}/concat/${barcodename}"
  mkdir -p "$barcodefolder"

  fastqfiles=$(find -L "$barcode" -type f \( -iname '*.f*q' -o -iname '*.f*q.gz' \))

  if [ -z "$fastqfiles" ]; then
    echo "    (barcode: ${barcodename}): No fastq files found, skipping..."
    return
  fi

  barcode_allreads="${barcodefolder}/${barcodename}.fastq"

  if [ -r "$barcode_allreads" ]; then
    echo "    (barcode: ${barcodename}): barcode_allreads.fastq already exists, skipping..."
    return
  fi

  echo "    (barcode: ${barcodename}): Decompressing + concatenating..."
  #shellcheck disable=SC2086
  gunzip -cdfq $fastqfiles > "$barcode_allreads"

  nreads="$(grep -c '^+$' "$barcode_allreads")"
  echo "    (barcode: ${barcodename}): Total reads: ${nreads}..."
  for sample_size in $sample_sizes; do
    echo "    (barcode: ${barcodename}): Subsampling to ${sample_size} reads..."
    if [ "$nreads" -lt "${sample_size}" ]; then
      echo "    (barcode: ${barcodename}): Not enough reads to subsample to ${sample_size}, skipping..."
      continue
    fi
    subsample_file="${output_dir}/sample_size_${sample_size}/${barcodename}/allreads_subsampled_${sample_size}.fastq"
    mkdir -p "$(dirname "$subsample_file")"

    # adjust if needed, see https://drive5.com/usearch/manual/cmd_fastx_subsample.html
    usearch11 -fastx_subsample \
      "$barcode_allreads" \
      -sample_size "$sample_size" \
      -fastaout "$subsample_file" \
      -randseed 42 \
      -quiet
  done
}

export -f concat_subsample

demuxfolders=$(find -L "$input_dir" -maxdepth 1 -mindepth 1 -type d \
  ! -iregex ".*unclassified$" \
  ! -iregex ".*unknown$")

# Run the function in parallel for each barcode
parallel -j "$(nproc)" concat_subsample ::: $demuxfolders
