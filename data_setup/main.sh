#!/bin/bash

# BPNet Data Preparation Pipeline
# This script runs the data preparation steps for BPNet training

set -e  # Exit on any error

echo "=========================================="
echo "BPNet Data Preparation Pipeline"
echo "=========================================="

# Step 1: Download Data
echo ""
echo "Step 1: Downloading data..."
echo "=========================================="
./scripts/01_download_data.sh

# Step 2: Preprocessing
echo ""
echo "Step 2: Preprocessing data..."
echo "=========================================="
./scripts/02_preprocessing.sh

# Step 3: Outlier Removal
echo ""
echo "Step 3: Removing outliers..."
echo "=========================================="
./scripts/03_outlier_removal.sh

# Step 4: Background Generation
echo ""
echo "Step 4: Generating background regions..."
echo "=========================================="
./scripts/04_background_generation.sh

echo ""
echo "=========================================="
echo "Data preparation completed successfully!"
echo "=========================================="
echo ""
echo "Data is now ready for BPNet training."
echo "Prepared files are in ENCSR000EGM/data/"