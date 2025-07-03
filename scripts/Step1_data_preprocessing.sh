#!/bin/bash

set -e  # Exit on any error

echo "=========================================="
echo "BPNet Data Preparation Pipeline"
echo "=========================================="

echo ""
echo "Step 1: Downloading data..."
echo "=========================================="
./scripts/data_preprocessing/01_download_data.sh

echo ""
echo "Step 2: Preprocessing data..."
echo "=========================================="
./scripts/data_preprocessing/02_preprocessing.sh

echo ""
echo "Step 3: Removing outliers..."
echo "=========================================="
./scripts/data_preprocessing/03_outlier_removal.sh

echo ""
echo "Step 4: Generating background regions..."
echo "=========================================="
./scripts/data_preprocessing/04_background_generation.sh

echo ""
echo "=========================================="
echo "Data preparation completed successfully!"
echo "=========================================="
echo ""