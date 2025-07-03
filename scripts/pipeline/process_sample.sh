#!/bin/bash

# Process individual sample through BPNet pipeline
# Usage: ./process_sample.sh <sample_name> <environment_name>

set -e  # Exit on any error

if [ $# -ne 2 ]; then
    echo "Usage: $0 <sample_name> <environment_name>"
    echo "Example: $0 ENCSR000EGM bpnet-m1"
    exit 1
fi

SAMPLE_NAME=$1
ENV_NAME=$2
SAMPLE_DIR="samples/$SAMPLE_NAME"

# Check if sample directory and config exist
if [ ! -d "$SAMPLE_DIR" ]; then
    echo "Error: Sample directory $SAMPLE_DIR does not exist"
    echo "Please create the sample directory and config.json first"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/config.json" ]; then
    echo "Error: Sample config file $SAMPLE_DIR/config.json does not exist"
    echo "Please create the config.json file first"
    exit 1
fi

# Initialize conda for this shell session and activate environment
echo "Initializing conda and activating environment: $ENV_NAME"
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

echo ""
echo "=========================================="
echo "Processing Sample: $SAMPLE_NAME"
echo "=========================================="

# Call the sample preprocessing script
./preprocess_sample.sh "$SAMPLE_DIR"

echo ""
echo "=========================================="
echo "Sample $SAMPLE_NAME processed successfully!"
echo "Results available in: $SAMPLE_DIR/results/"
echo "=========================================="
echo ""