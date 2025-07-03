#!/bin/bash

# Sample preprocessing pipeline - combines data preprocessing and model setup
# Usage: ./preprocess_sample.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

echo "=========================================="
echo "BPNet Sample Preprocessing Pipeline"
echo "Sample Directory: $SAMPLE_DIR"
echo "=========================================="

echo ""
echo "Step 1: Downloading data..."
echo "=========================================="
./scripts/preprocess_sample/01_download_data.sh "$SAMPLE_DIR"

echo ""
echo "Step 2: Preprocessing data..."
echo "=========================================="
./scripts/preprocess_sample/02_preprocessing.sh "$SAMPLE_DIR"

echo ""
echo "Step 3: Removing outliers..."
echo "=========================================="
./scripts/preprocess_sample/03_outlier_removal.sh "$SAMPLE_DIR"

echo ""
echo "Step 4: Generating background regions..."
echo "=========================================="
./scripts/preprocess_sample/04_background_generation.sh "$SAMPLE_DIR"

echo ""
echo "Step 5: Creating input data configuration..."
echo "=========================================="
./scripts/preprocess_sample/05_create_input_data.sh "$SAMPLE_DIR"

echo ""
echo "Step 6: Calculating counts loss weight..."
echo "=========================================="
./scripts/preprocess_sample/06_calculate_counts_loss_weight.sh "$SAMPLE_DIR"

echo ""
echo "=========================================="
echo "Sample preprocessing completed successfully!"
echo "=========================================="
echo ""