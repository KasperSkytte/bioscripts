#!/bin/bash
# Set error check
set -e
set -o pipefail

SEQPATH=${1:-/space/sequences/}
SAMPLESEP="_"

if [ ! -s samples ]
  then
    echo "Could not find a \"samples\" file!"
    exit 2
fi
cat samples | tr "\r" "\n" | sed -e '$a\' | sed -e '/^$/d' -e 's/ //g' > samples_tmp.txt

NSAMPLES=$(wc -w < samples_tmp.txt)
while ((i++)); read SAMPLE
  do
    echo -ne "Processing sample: $SAMPLE ($i / $NSAMPLES)\r"
    find "$SEQPATH" -name $SAMPLE$SAMPLESEP*R1* 2>/dev/null -exec gzip -cd {} \; >> allsamples.R1.fq
done < samples_tmp.txt

duration=$(printf '%02dh:%02dm:%02ds\n' $(($SECONDS/3600)) $(($SECONDS%3600/60)) $(($SECONDS%60)))
echo "Done in: $duration"
