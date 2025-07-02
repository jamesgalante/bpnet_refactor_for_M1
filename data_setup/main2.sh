#!/bin/bash

# BPNet Training Pipeline - Orchestrates all setup and training scripts
echo "Starting BPNet training pipeline"

# Run setup scripts in order
echo "Step 5: Creating input data configuration..."
./scripts/05_create_input_data.sh

echo "Step 6: Creating BPNet parameters configuration..."
./scripts/06_create_bpnet_params.sh

echo "Step 7: Calculating optimal counts loss weight..."
./scripts/07_calculate_counts_loss_weight.sh

echo "Step 8: Creating chromosome splits..."
./scripts/08_create_splits.sh

echo "Step 9: Training BPNet model..."
#./scripts/09_train_model.sh

echo "BPNet training pipeline completed!"
