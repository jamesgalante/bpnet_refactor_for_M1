#!/bin/bash

set -e  # Exit on any error

echo "=========================================="
echo "BPNet Model Setup Pipeline"
echo "=========================================="

echo ""
echo "Step 1: Creating Input JSON..."
echo "=========================================="
./scripts/model_setup/05_create_input_data.sh

echo ""
echo "Step 2: Creating BPNet Params..."
echo "=========================================="
./scripts/model_setup/06_create_bpnet_params.sh

echo ""
echo "Step 3: Calculating Counts Loss Weight..."
echo "=========================================="
./scripts/model_setup/07_calculate_counts_loss_weight.sh

echo ""
echo "Step 4: Creating Splits..."
echo "=========================================="
./scripts/model_setup/08_create_splits.sh

echo ""
echo "=========================================="
echo "Model Setup Completed Successfully"
echo "=========================================="
echo ""