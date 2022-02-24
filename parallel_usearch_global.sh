#!/usr/bin/env bash
set -e

parallel_usearch_global() {
  #use all threads available except 2
  maxthreads=${maxthreads:-$(($(nproc)-2))}
  
  #number of threads to use for each parallel process of usearch_global
  usearch_global_jobsize=${usearch_global_jobsize:-5}

  local OPTIND
  while getopts ":hi:o:d:t:a:" opt; do
    case ${opt} in
      h )
      echo "Runs usearch11 -usearch_global in parallel by splitting the input data and process in smaller chunks. Much faster than just using more threads with one command."
      echo "Options:"
      echo "  -h    Display this help text and exit."
      echo "  -v    Print version and exit."
      echo "  -i    (required) Input file name."
      echo "  -o    (required) Output file name."
      echo "  -d    (required) Database file."
      echo "  -a    Additional arguments passed on to the usearch11 -usearch_global command as one quoted string, fx: -a \"-maxrejects 8 -strand plus\""
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
  
  jobs=$(( maxthreads / usearch_global_jobsize ))
  if [ ${jobs} -gt 1 ]
  then
    #create and/or clear a temporary folder for split input files
    tmpsplitdir="${output}_tmpsplit"
    rm -rf "${tmpsplitdir}"
    mkdir -p "${tmpsplitdir}"

    echo "  - Splitting input file in ${jobs} to run in parallel"
    #minus 1 job because of leftover seqs from equal split
    usearch11 -fastx_split "${input}" \
      -splits $((jobs - 1)) \
      -outname "${tmpsplitdir}/seqs_@.fa" \
      -quiet

    echo "  - Running ${jobs} jobs using max ${usearch_global_jobsize} threads each ($(((jobs * usearch_global_jobsize))) total)"
    find "${tmpsplitdir}" -type f -name 'seqs_*.fa' |\
      parallel --progress usearch11 -usearch_global {} \
        -db "${database}" \
        $usearch_args \
        -blast6out "{.}.b6" \
        -threads "${usearch_global_jobsize}" \
        -quiet

    echo "  - Combining output search tables into a single table"
    find "${tmpsplitdir}" \
      -type f \
      -name '*.b6' \
      -exec cat > "${tmpsplitdir}/combined.txt" {} +
    
    sort -V "${tmpsplitdir}/combined.txt" > "$output"

    rm -rf "${tmpsplitdir}"
  else
    echo "  - Number of jobs is ${jobs}, exiting..."
    exit 1
  fi
}

#if sourced from another script, just load the function
#if not then run the function passing on arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  parallel_usearch_global "$*"
fi
