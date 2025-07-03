#!/bin/bash

# Full pipeline for running BPNet and testing on M1 GPUs

set -e  # Exit on any error

echo ""
echo ""
echo "=========================================="
echo "Step 1: Data Preprocessing"
echo "=========================================="
./scripts/Step1_data_preprocessing.sh

echo ""
echo ""
echo "=========================================="
echo "Step 2: Model Setup"
echo "=========================================="
./scripts/Step2_model_setup.sh

# echo ""
# echo ""
# echo "=========================================="
# echo "Step 3: GPU M1 Testing"
# echo "=========================================="
# ./scripts/Step3_M1_gpu_testing.sh