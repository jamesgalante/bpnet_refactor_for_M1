#!/bin/bash

# Simple BPNet parameter test
# Usage: ./simple_test.sh <batch_size> <threads>

# Set base directory
BASE_DIR=/Users/jamesgalante/Documents/Projects/BPNet_Recreate/trying_bpnet_refactor/ENCSR000EGM/

# Activate environment
source /opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh
conda activate bpnet-test-py38
export PYTHONPATH="/Users/jamesgalante/Documents/Projects/BPNet_Recreate/bpnet_refactor_for_M1/bpnet_refactor:$PYTHONPATH"

# Test parameters
BATCH_SIZE=$1
THREADS=$2
TEST_NAME="batch_${BATCH_SIZE}_threads_${THREADS}"

# Change to parent directory where ENCSR000EGM is located
cd ..

# Run BPNet training for 120 seconds max with timeout
# Install timeout if needed: brew install coreutils
if command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_CMD="gtimeout 120s"
elif command -v timeout >/dev/null 2>&1; then
    TIMEOUT_CMD="timeout 120s"
else
    echo "Installing coreutils for timeout command..."
    brew install coreutils
    TIMEOUT_CMD="gtimeout 120s"
fi

# $TIMEOUT_CMD python -m bpnet.cli.bpnettrainer \
#     --input-data $INPUT_DATA \
#     --output-dir "bpnet_refactor_for_M1/results/$TEST_NAME" \
#     --reference-genome ENCSR000EGM/reference/hg38.genome.fa \
#     --chroms $(paste -s -d ' ' $REFERENCE_DIR/chroms.txt) \
#     --chrom-sizes ENCSR000EGM/reference/hg38.chrom.sizes \
#     --splits ENCSR000EGM/splits.json \
#     --model-arch-name BPNet \
#     --model-arch-params-json ENCSR000EGM/bpnet_params.json \
#     --sequence-generator-name BPNet \
#     --model-output-filename model_test \
#     --input-seq-len 2114 \
#     --output-len 1000 \
#     --shuffle \
#     --threads $THREADS \
#     --epochs 10 \
#     --batch-size $BATCH_SIZE \
#     --learning-rate 0.001 \
#     2>&1 | tee "new_attempt_optimization/results/$TEST_NAME/training.log"

# EXIT_CODE=$?


# Run BPNet training
$TIMEOUT_CMD python -m bpnet.cli.bpnettrainer \
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
        2>&1 | tee "new_attempt_optimization/results/$TEST_NAME/training.log"
EXIT_CODE=$?


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



echo "End: $(date)"
echo "Exit Code: $EXIT_CODE (124 = timeout, 0 = normal completion)"

# Quick analysis
LOG_FILE="new_attempt_optimization/results/$TEST_NAME/training.log"
if [ -f "$LOG_FILE" ]; then
    STEPS=$(grep -c "step\|Step\|ETA" "$LOG_FILE" 2>/dev/null || echo "0")
    ERRORS=$(grep -c "Error\|ERROR\|Exception" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "Steps detected: $STEPS"
    echo "Errors detected: $ERRORS"
    
    # Check for GPU usage
    if grep -q "MPS\|GPU" "$LOG_FILE"; then
        echo "GPU usage: YES"
    else
        echo "GPU usage: NO"
    fi
    
    echo "Full log: $LOG_FILE"
else
    echo "No log file created"
fi