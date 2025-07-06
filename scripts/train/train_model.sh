#!/bin/bash

# Train BPNet model for a specific sample
# Usage: ./train_model.sh <sample_name> <environment_name>

set -e  # Exit on any error

if [ $# -ne 2 ]; then
    echo "Usage: $0 <sample_name> <environment_name>"
    echo "Example: $0 ENCSR000EGM bpnet-m1"
    exit 1
fi

SAMPLE_NAME=$1
ENV_NAME=$2
SAMPLE_DIR="../../samples/$SAMPLE_NAME"

# Check if sample directory exists
if [ ! -d "$SAMPLE_DIR" ]; then
    echo "Error: Sample directory $SAMPLE_DIR does not exist"
    echo "Please run preprocessing first"
    exit 1
fi

# Check if required files exist
if [ ! -f "$SAMPLE_DIR/results/input_data.json" ]; then
    echo "Error: input_data.json not found in $SAMPLE_DIR/results/"
    echo "Please run preprocessing first"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/bpnet_params.json" ]; then
    echo "Error: bpnet_params.json not found in $SAMPLE_DIR"
    echo "Please run preprocessing first"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/splits.json" ]; then
    echo "Error: splits.json not found in $SAMPLE_DIR"
    echo "Please run preprocessing first"
    exit 1
fi

# Initialize conda for this shell session and activate environment
echo "Initializing conda and activating environment: $ENV_NAME"
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

echo ""
echo "=========================================="
echo "Training BPNet Model for Sample: $SAMPLE_NAME"
echo "=========================================="

# Set up paths
BASE_DIR="$SAMPLE_DIR"
MODEL_DIR="$BASE_DIR/models"
REFERENCE_DIR="../../reference/hg38"
CHROM_SIZES="$REFERENCE_DIR/hg38.chrom.sizes"
REFERENCE_GENOME="$REFERENCE_DIR/hg38.genome.fa"
CV_SPLITS="$BASE_DIR/splits.json"
INPUT_DATA="$BASE_DIR/results/input_data.json"
MODEL_PARAMS="$BASE_DIR/bpnet_params.json"

# Create model output directory
mkdir -p "$MODEL_DIR"

echo "Training configuration:"
echo "  Sample: $SAMPLE_NAME"
echo "  Input data: $INPUT_DATA"
echo "  Model parameters: $MODEL_PARAMS"
echo "  CV splits: $CV_SPLITS"
echo "  Model output: $MODEL_DIR"
echo "  Reference genome: $REFERENCE_GENOME"
echo "  Chromosome sizes: $CHROM_SIZES"
echo ""

# Run BPNet training
echo "Starting BPNet training..."
python ../../bpnet-refactor/bpnet/cli/bpnettrainer.py \
        --input-data "$INPUT_DATA" \
        --output-dir "$MODEL_DIR" \
        --reference-genome "$REFERENCE_GENOME" \
        --chroms $(paste -s -d ' ' "$REFERENCE_DIR/chroms.txt") \
        --chrom-sizes "$CHROM_SIZES" \
        --splits "$CV_SPLITS" \
        --model-arch-name BPNet \
        --model-arch-params-json "$MODEL_PARAMS" \
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

echo ""
echo "=========================================="
echo "Model training completed successfully!"
echo "Trained model saved in: $MODEL_DIR"
echo "=========================================="
echo ""