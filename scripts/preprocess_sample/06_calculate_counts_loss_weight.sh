#!/bin/bash

# Calculate optimal counts loss weight for BPNet training
# Usage: ./06_calculate_counts_loss_weight.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

echo "Calculating optimal counts loss weight"

INPUT_DATA="$SAMPLE_DIR/results/input_data.json"

# Run bpnet-counts-loss-weight command
echo "Running bpnet-counts-loss-weight command..."
export PYTHONPATH="../../bpnet-refactor:$PYTHONPATH"
python -m bpnet.cli.bpnet_counts_loss_weight --input-data "$INPUT_DATA"

echo "Counts loss weight calculation completed"
echo "Note: Update the 'loss_weights' field in bpnet_params.json with the calculated value"
