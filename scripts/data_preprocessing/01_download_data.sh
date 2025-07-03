#!/bin/bash

# Download sample-specific data based on config.json
# Usage: ./01_download_data.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

# Check if config.json exists
if [ ! -f "$SAMPLE_DIR/config.json" ]; then
    echo "Error: Config file $SAMPLE_DIR/config.json not found"
    exit 1
fi

# Extract URLs from config.json
REPLICATE_URLS=$(python3 -c "
import json, sys
with open('$SAMPLE_DIR/config.json', 'r') as f:
    config = json.load(f)
for i, url in enumerate(config['data_urls']['replicates']):
    print(f'rep{i+1}:{url}')
")

CONTROL_URL=$(python3 -c "
import json
with open('$SAMPLE_DIR/config.json', 'r') as f:
    config = json.load(f)
print(config['data_urls']['control'])
")

PEAKS_URL=$(python3 -c "
import json
with open('$SAMPLE_DIR/config.json', 'r') as f:
    config = json.load(f)
print(config['data_urls']['peaks'])
")

# Make directories if they don't exist
echo "Making directories"
mkdir -p "$SAMPLE_DIR/resources/"
mkdir -p "$SAMPLE_DIR/processed/"
mkdir -p "$SAMPLE_DIR/results/"

# Download the ChIP-Seq data
echo "Downloading replicates..."
echo "$REPLICATE_URLS" | while IFS=':' read -r rep_name url; do
    echo "Downloading $rep_name"
    wget "$url" -O "$SAMPLE_DIR/resources/$rep_name.bam"
done

echo "Downloading control"
wget "$CONTROL_URL" -O "$SAMPLE_DIR/resources/control.bam"

echo "Downloading peaks"
wget "$PEAKS_URL" -O "$SAMPLE_DIR/resources/peaks.bed.gz"
gunzip "$SAMPLE_DIR/resources/peaks.bed.gz"
