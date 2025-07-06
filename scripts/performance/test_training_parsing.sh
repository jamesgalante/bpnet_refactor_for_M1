#!/bin/bash

# Test script to verify training progress parsing works
# Usage: ./test_training_parsing.sh <environment_name>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment_name>"
    echo "Example: $0 bpnet-m1"
    exit 1
fi

ENV_NAME=$1
SAMPLE_NAME="ENCSR000EGM"
SAMPLE_DIR="../../samples/$SAMPLE_NAME"
TIMEOUT_SECONDS=90

echo "Testing training with timeout and progress parsing..."
echo "Sample: $SAMPLE_NAME"
echo "Timeout: $TIMEOUT_SECONDS seconds"
echo ""

# Check if sample directory exists and has required files
if [ ! -d "$SAMPLE_DIR" ]; then
    echo "Error: Sample directory $SAMPLE_DIR does not exist"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/results/input_data.json" ]; then
    echo "Error: input_data.json not found in $SAMPLE_DIR/results/"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/bpnet_params.json" ]; then
    echo "Error: bpnet_params.json not found in $SAMPLE_DIR"
    exit 1
fi

if [ ! -f "$SAMPLE_DIR/splits.json" ]; then
    echo "Error: splits.json not found in $SAMPLE_DIR"
    exit 1
fi

# Initialize conda and activate environment
echo "Activating conda environment: $ENV_NAME"
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Set PYTHONPATH for bpnet-refactor
export PYTHONPATH="$(pwd)/bpnet-refactor:$PYTHONPATH"

# Set up paths
BASE_DIR="$SAMPLE_DIR"
MODEL_DIR="$BASE_DIR/models/test_run"
REFERENCE_DIR="../../reference/hg38"
CHROM_SIZES="$REFERENCE_DIR/hg38.chrom.sizes"
REFERENCE_GENOME="$REFERENCE_DIR/hg38.genome.fa"
CV_SPLITS="$BASE_DIR/splits.json"
INPUT_DATA="$BASE_DIR/results/input_data.json"
MODEL_PARAMS="$BASE_DIR/bpnet_params.json"

# Create test model output directory
mkdir -p "$MODEL_DIR"

echo "Starting test training run..."
echo "Output will be saved to: training_output.log"
echo ""

# Run training with timeout and capture output
timeout $TIMEOUT_SECONDS python ../../bpnet-refactor/bpnet/cli/bpnettrainer.py \
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
        --threads 5 \
        --epochs 100 \
        --batch-size 128 \
        --reverse-complement-augmentation \
        --early-stopping-patience 10 \
        --reduce-lr-on-plateau-patience 5 \
        --learning-rate 0.001 \
        2>&1 | tee training_output.log

# Check if timeout occurred
if [ $? -eq 124 ]; then
    echo "Training timed out after $TIMEOUT_SECONDS seconds (as expected)"
else
    echo "Training completed before timeout"
fi

echo ""
echo "Analyzing training output for progress parsing..."
echo ""

# Extract progress information from the log
# Look for lines like: "199/400 [=============>................] - ETA: 12:02"
grep -E "[0-9]+/[0-9]+ \[.*\] - ETA:" training_output.log | tail -5 | while IFS= read -r line; do
    echo "Found progress line: $line"
    
    # Extract steps completed and total steps
    if [[ $line =~ ([0-9]+)/([0-9]+) ]]; then
        steps_completed=${BASH_REMATCH[1]}
        total_steps=${BASH_REMATCH[2]}
        echo "  → Steps completed: $steps_completed"
        echo "  → Total steps: $total_steps"
        
        # Calculate percentage
        if [ $total_steps -gt 0 ]; then
            percentage=$((steps_completed * 100 / total_steps))
            echo "  → Progress: $percentage%"
        fi
    fi
    echo ""
done

echo "Progress parsing test completed!"
echo "Log file saved as: training_output.log"

# Clean up test model directory
rm -rf "$MODEL_DIR"
echo "Test model directory cleaned up"