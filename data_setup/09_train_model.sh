#!/bin/bash

# Initialize conda for this shell session
echo "Initializing conda"
eval "$(conda shell.bash hook)"
# Now activate the environment
# conda activate bpnet-refactored
conda activate bpnet-test-py38

export PYTHONPATH="/Users/jamesgalante/Documents/Projects/BPNet_Recreate/trying_bpnet_refactor/bpnet-refactor:$PYTHONPATH"

# BPNet Model Training Script
echo "Training BPNet model..."

# Set up environment variables
BASE_DIR=ENCSR000EGM
DATA_DIR=$BASE_DIR/data
MODEL_DIR=$BASE_DIR/models
REFERENCE_DIR=$BASE_DIR/reference
CHROM_SIZES=$REFERENCE_DIR/hg38.chrom.sizes
REFERENCE_GENOME=$REFERENCE_DIR/hg38.genome.fa
CV_SPLITS=$BASE_DIR/splits.json
INPUT_DATA=$BASE_DIR/input_data.json
MODEL_PARAMS=$BASE_DIR/bpnet_params.json

# Create model directory
echo "Creating model directory"
mkdir -p $MODEL_DIR

# Run BPNet training
python -m bpnet.cli.bpnettrainer \
        --input-data $INPUT_DATA \
        --output-dir $MODEL_DIR \
        --reference-genome $REFERENCE_GENOME \
        --chroms $(paste -s -d ' ' $REFERENCE_DIR/chroms.txt) \
        --chrom-sizes $CHROM_SIZES \
        --splits $CV_SPLITS \
        --model-arch-name BPNet \
        --model-arch-params-json $MODEL_PARAMS \
        --sequence-generator-name BPNet \
        --model-output-filename model \
        --input-seq-len 2114 \
        --output-len 1000 \
        --shuffle \
        --threads 10 \
        --epochs 100 \
        --batch-size 128 \
        --reverse-complement-augmentation \
        --early-stopping-patience 10 \
        --reduce-lr-on-plateau-patience 5 \
        --learning-rate 0.001

echo "Training completed!"
