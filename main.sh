#!/bin/bash

# Full pipeline for running BPNet with generalized sample processing

set -e  # Exit on any error

ENVIRONMENT_NAME="bpnet-m1"

echo ""
echo "=========================================="
echo "BPNet M1 Pipeline - Full Workflow"
echo "=========================================="

echo ""
echo "Step 1: Global Setup (run once)"
echo "=========================================="
echo "Setting up reference data and global configurations..."
./setup_global.sh "$ENVIRONMENT_NAME"

echo ""
echo "Step 2: Sample Processing"
echo "=========================================="
echo "Processing sample: ENCSR000EGM"

# Check if sample config exists
if [ ! -f "samples/ENCSR000EGM/config.json" ]; then
    echo "Error: Sample config samples/ENCSR000EGM/config.json not found"
    echo "Please create the sample configuration first"
    echo "See README.md for sample configuration instructions"
    exit 1
fi

./process_sample.sh ENCSR000EGM "$ENVIRONMENT_NAME"

echo ""
echo "=========================================="
echo "Pipeline completed successfully!"
echo "=========================================="
echo ""
echo "To process additional samples:"
echo "1. Create samples/YOUR_SAMPLE/config.json with download URLs"
echo "2. Run: ./process_sample.sh YOUR_SAMPLE $ENVIRONMENT_NAME"
echo ""

# echo ""
# echo ""
# echo "=========================================="
# echo "Step 3: GPU M1 Testing (Future Enhancement)"
# echo "=========================================="
# echo "GPU testing functionality will be added in future updates"