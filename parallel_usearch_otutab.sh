#!/usr/bin/env bash
set -euo pipefail

parallel_usearch_otutab() {
  #use all threads available except 2
  maxthreads=${maxthreads:-$(($(nproc)-2))}
  
  #number of threads to use for each parallel process of usearch_global
  chunksize=${chunksize:-5}

  usearch_args=""

  local OPTIND
  while getopts ":hi:o:d:t:a:" opt; do
    case ${opt} in
      h )
      echo "Runs usearch -usearch_global in parallel by splitting the input data and process in smaller chunks. Much faster than just using more threads with one command."
      echo "Options:"
      echo "  -h    Display this help text and exit."
      echo "  -v    Print version and exit."
      echo "  -i    (required) Input file name."
      echo "  -o    (required) Output file name."
      echo "  -d    (required) Database file."
      echo "  -a    Additional arguments passed on to the usearch -usearch_global command as one quoted string, fx: -a \"-maxrejects 8 -strand plus\""
      echo "  -t    Max number of max_threads to use. (Default: all available except 2)"
      exit 1
      ;;
      i )
        local input=$OPTARG
        ;;
      o )
        local output=$OPTARG
        ;;
      d )
        local database=$OPTARG
        ;;
      t )
        local maxthreads=$OPTARG
        ;;
      a )
        local usearch_args=$OPTARG
        ;;
      \? )
        echo "Invalid Option: -$OPTARG"
        exit 1
        ;;
      : )
        echo "Option -$OPTARG requires an argument"
        exit 1
        ;;
    esac
  done

  #check required options
  if [[ -z "$input" ]]
  then
    echo "option -i is required"
    exit 1
  fi
  if [[ -z "$output" ]]
  then
    echo "option -o is required"
    exit 1
  fi
  if [[ -z "$database" ]]
  then
    echo "option -d is required"
    exit 1
  fi
  
  #usearch -otutab does not scale linearly with the number of threads
  #much faster to split into smaller chunks and run in parallel using
  # GNU parallel and then merge tables afterwards
  jobs=$((( maxthreads / chunksize )))
  if [ $jobs -lt 1]
  then
    jobs=1
  fi
  if [ $jobs -gt 1 ]
  then
    tmpsplitdir="${output}_tmpsplit"
    rm -rf "${tmpsplitdir}"
    mkdir -p "${tmpsplitdir}"

    #minus 1 job because of leftover seqs from equal split
    usearch -fastx_split "${input}" \
      -splits $((jobs - 1)) \
      -outname "${tmpsplitdir}/seqs_@.fa" \
      -quiet

    echo "  - Running ${jobs} jobs using max ${chunksize} threads each ($(((jobs * chunksize))) total)"
    #run a usearch -otutab command for each file
    find "${tmpsplitdir}" -type f -name 'seqs_*.fa' |\
      parallel --progress usearch -otutab {} \
        -zotus "${database}" \
        -otutabout "{.}_asvtab.tsv" \
        -threads "$chunksize" \
        $usearch_args \
        -quiet

    #generate a comma-separated list of filenames to merge
    asvtabslist=""
    while IFS= read -r -d '' asvtab
    do
      #exclude table if empty, ie only contains one line with "#OTU ID"
      if [ "$(head -n 2 "$asvtab" | wc -l)" -lt 2 ]
      then
        continue
      fi
      if [ -z "$asvtabslist" ]
      then
        asvtabslist="$asvtab"
      else
        asvtabslist="$asvtabslist,$asvtab"
      fi
    done < <(find "$tmpsplitdir" -type f -iname '*_asvtab.tsv' -print0)

    #merge asvtables
    usearch -otutab_merge "$asvtabslist" -output "${output}" -quiet
  else
    #dont run in parallel if maxthreads <= 2*chunksize
    usearch -otutab \
      "${input}" \
      -zotus "${database}" \
      -otutabout "${output}" \
      -threads "$maxthreads" $usearch_args
  fi
  rm -rf "${tmpsplitdir}"
}

#if sourced from another script, just load the function
#if not then run the function passing on arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  parallel_usearch_otutab "$*"
fi
