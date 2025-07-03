#!/bin/bash

# Full pipeline for running BPNet and testing on M1 GPUs

set -e  # Exit on any error

echo ""
echo ""
echo "=========================================="
echo "Step 1: Data Preprocessing"
echo "=========================================="
./scripts/data_preprocessing.sh

echo ""
echo ""
echo "=========================================="
echo "Step 2: Model Setup"
echo "=========================================="
./scripts/model_setup.sh