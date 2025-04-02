#!/usr/bin/env bash
set -euo pipefail

## functions
#default error message if bad usage
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
  echo " *** [$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $1"
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

#ensure all required commands are available before doing anything
checkCommand rename dorado 

## user options and variables, with defaults
#set max number of threads to all except 2. This is relative to container, better to limit the container itself? also memory
max_threads=$(($(nproc)-2))
version="1.0"
kitname="SQK-RBK114-96"
model="sup"
timeout=${timeout:-30}

#fetch and check options provided by user
#flags for required options, checked after getopts loop
i_flag=0
o_flag=0
while getopts ":hi:o:m:k:t:v" opt; do
case ${opt} in
  h )
    echo "Live basecalling and demultiplexing using dorado. The input folder will be checked for new pod5 files every minute until timeout reached."
    echo "Version: $version"
    echo "Options:"
    echo "  -h    Display this help text and exit."
    echo "  -i    (required) Input folder containing pod5 files."
    echo "  -o    (required) Output folder to contain the demultiplexed FASTQ files. Contents will be overridden if any."
    echo "  -m    Dorado model, fast/hac/sup. (Default: $model)"
    echo "  -k    Kit name for demultiplexing. (Default: $kitname)"
    echo "  -t    Max number of threads to use when demultiplexing. (Default: $max_threads)"
    echo "  -v    Print version and exit."
    exit 1
    ;;
  i )
    pod5=$(realpath $OPTARG)
    i_flag=1
    ;;
  o )
    output=$OPTARG
    o_flag=1
    ;;
  m )
    model=$OPTARG
    ;;
  k )
    kitname=$OPTARG
    ;;
  t )
    max_threads=$OPTARG
    ;;
  v )
    echo "Version: $version"
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

#check all required options
if [ $i_flag -eq 0 ]
then
	usageError "option -i is required"
	exit 1
fi
if [ $o_flag -eq 0 ]
then
	usageError "option -o is required"
	exit 1
fi

## check and create folders
#temporary folder within output folder
temp="${output}/temp"

#pod5 temporary folder and backup folder
pod5_tmp="${temp}/pod5_tmp"
pod5_backup="${output}/pod5_backup"

#fastq temporary folder
basecalls="${temp}/basecalls"

#demultiplexed
demux="${output}/demultiplexed"

#create folders
mkdir -p "$demux"
mkdir -p "$output"
mkdir -p "$temp"
mkdir -p "$pod5_tmp"
mkdir -p "$basecalls"
mkdir -p "$pod5_backup"

scriptMessage "Starting live basecalling..."

#check for new pod5 files in pod5 folder and do basecalling+demux
#continue with assembly if timeout reached
timer=0
batchNo=0
while true; do
  #check pod5 folder recursively, make sure no exit when none found
  pod5files=$(find -L "$pod5"/ -type f -iname '*.pod5')
	if [ -n "$pod5files" ]
	then
		timer=0
		batchNo=$((batchNo+1))
		batch="batch_${batchNo}"

		#backup raw data to ensure that no data is lost if pipeline fails
    #add batch number to avoid overriding files and logs
		mkdir -p "$pod5_backup"/"$batch"/
		mv $pod5files -t "${pod5_backup}/$batch"/ --backup=numbered
		scriptMessage "Basecalling pod5 batch number ${batchNo} ($(echo $pod5files | wc -w) pod5 file(s))"
		
    #copy pod5 files to dorado input folder
		cp -r "$pod5_backup"/"$batch"/*.pod5* "$pod5_tmp"/ --backup=numbered
		rename 's/\.pod5\.//' "$pod5_tmp"/*
		rename 's/~$/~.pod5/' "$pod5_tmp"/*
		
    #go basecall
    dorado basecaller \
      "$model" \
      "$pod5_tmp" \
      --device cuda:all \
      -o "$basecalls"/"$batch"/

		#remove all pod5 files from current batch afterwards, ready for next
		rm -rf ${pod5_tmp:?}/*	#make sure this doesn't expand to rm -rf /* which could be dangerous
        
    #check again every minute until timeout reached
	elif [ -z "$(find "$pod5"/ -type f -iname '*.pod5')" ]
  then
    echo -e "\r\033[1A\033[0KNo new pod5 files found for $timer minute(s). Continuing with demultiplexing in $((timeout-timer)) minute(s)..."
		if [ $timer -eq "$timeout" ]
		then
			break;
		fi
		sleep 60
		timer=$((timer+1))
	fi
done

# Demultiplex
scriptMessage "Starting demultiplexing..."
dorado demux \
  -r \
  --kit-name "$kitname" \
  --emit-fastq \
  -o "$demux" \
  -t "$max_threads" \
  "$basecalls"

scriptMessage "Cleaning up temporary files..."
rm -rf "$temp"

scriptMessage "Done, enjoy!"
