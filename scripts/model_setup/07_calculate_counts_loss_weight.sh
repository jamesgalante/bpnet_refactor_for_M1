#!/bin/bash

# Initialize conda for this shell session
echo "Initializing conda"
eval "$(conda shell.bash hook)"
# Now activate the environment
conda activate bpnet-m1

# Calculate optimal counts loss weight for BPNet training
echo "Calculating optimal counts loss weight"

BASE_DIR=ENCSR000EGM
INPUT_DATA=$BASE_DIR/input_data.json

# Run bpnet-counts-loss-weight command
echo "Running bpnet-counts-loss-weight command..."
bpnet-counts-loss-weight --input-data $INPUT_DATA

echo "Counts loss weight calculation completed"
echo "Note: Update the 'loss_weights' field in bpnet_params.json with the calculated value"
