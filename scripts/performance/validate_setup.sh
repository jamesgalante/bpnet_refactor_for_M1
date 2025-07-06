#!/bin/bash

# Validation script to check prerequisites for grid search
# Usage: ./validate_setup.sh <environment_name>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment_name>"
    echo "Example: $0 bpnet-m1"
    exit 1
fi

ENV_NAME=$1
SAMPLE_NAME="ENCSR000EGM"
SAMPLE_DIR="../../samples/$SAMPLE_NAME"

echo "=========================================="
echo "BPNet Grid Search Setup Validation"
echo "=========================================="
echo "Environment: $ENV_NAME"
echo "Sample: $SAMPLE_NAME"
echo ""

# Check 1: Sample directory exists
echo "✓ Checking sample directory..."
if [ -d "$SAMPLE_DIR" ]; then
    echo "  ✅ Sample directory exists: $SAMPLE_DIR"
else
    echo "  ❌ Sample directory missing: $SAMPLE_DIR"
    echo "  → Run: ./scripts/main.sh setup $ENV_NAME"
    echo "  → Then: ./scripts/main.sh process $SAMPLE_NAME $ENV_NAME"
    exit 1
fi

# Check 2: Required files exist
echo "✓ Checking required files..."
REQUIRED_FILES=(
    "config.json"
    "results/input_data.json"
    "bpnet_params.json"
    "splits.json"
)

missing_files=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SAMPLE_DIR/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo "  → $missing_files files missing. Run complete processing:"
    echo "  → ./scripts/main.sh process $SAMPLE_NAME $ENV_NAME"
    exit 1
fi

# Check 3: Reference files exist
echo "✓ Checking reference files..."
REFERENCE_DIR="../../reference/hg38"
REFERENCE_FILES=(
    "hg38.genome.fa"
    "hg38.chrom.sizes"
    "chroms.txt"
)

missing_ref=0
for file in "${REFERENCE_FILES[@]}"; do
    if [ -f "$REFERENCE_DIR/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
        missing_ref=$((missing_ref + 1))
    fi
done

if [ $missing_ref -gt 0 ]; then
    echo "  → $missing_ref reference files missing. Run setup:"
    echo "  → ./scripts/main.sh setup $ENV_NAME"
    exit 1
fi

# Check 4: bpnet-refactor directory exists
echo "✓ Checking bpnet-refactor directory..."
if [ -d "../../bpnet-refactor" ]; then
    echo "  ✅ bpnet-refactor directory exists"
else
    echo "  ❌ bpnet-refactor directory missing"
    echo "  → Clone repository: git clone https://github.com/kundajelab/bpnet-refactor.git"
    echo "  → Checkout commit: cd bpnet-refactor && git checkout 33578afcdb0faf06457c9a35dea4791ab53c671b"
    exit 1
fi

# Check 5: Conda environment exists and can be activated
echo "✓ Checking conda environment..."
if conda env list | grep -q "^$ENV_NAME "; then
    echo "  ✅ Conda environment exists: $ENV_NAME"
else
    echo "  ❌ Conda environment not found: $ENV_NAME"
    echo "  → Create environment from YML file or manually"
    exit 1
fi

# Check 6: Can activate environment and import required packages
echo "✓ Testing environment activation..."
eval "$(conda shell.bash hook)"
if conda activate "$ENV_NAME" 2>/dev/null; then
    echo "  ✅ Environment activation successful"
else
    echo "  ❌ Environment activation failed"
    exit 1
fi

# Check 7: Test Python imports
echo "✓ Testing Python imports..."
python -c "
import sys
try:
    import tensorflow as tf
    print('  ✅ TensorFlow:', tf.__version__)
except ImportError as e:
    print('  ❌ TensorFlow import failed:', e)
    sys.exit(1)

try:
    import numpy as np
    print('  ✅ NumPy:', np.__version__)
except ImportError as e:
    print('  ❌ NumPy import failed:', e)
    sys.exit(1)

try:
    import pandas as pd
    print('  ✅ Pandas:', pd.__version__)
except ImportError as e:
    print('  ❌ Pandas import failed:', e)
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "  → Fix package installation issues"
    exit 1
fi

# Check 8: Test PYTHONPATH and bpnet module
echo "✓ Testing PYTHONPATH and bpnet module..."
export PYTHONPATH="$(pwd)/bpnet-refactor:$PYTHONPATH"
python -c "
import sys
try:
    import bpnet
    print('  ✅ bpnet module import successful')
except ImportError as e:
    print('  ❌ bpnet module import failed:', e)
    print('  → Check PYTHONPATH and bpnet-refactor directory')
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    exit 1
fi

# Check 9: Test timeout command
echo "✓ Testing timeout command..."
if command -v timeout >/dev/null 2>&1; then
    echo "  ✅ timeout command available"
elif command -v gtimeout >/dev/null 2>&1; then
    echo "  ⚠️  Using gtimeout (macOS coreutils)"
    echo "  → You may need to modify scripts to use 'gtimeout' instead of 'timeout'"
else
    echo "  ❌ timeout command not found"
    echo "  → Install coreutils: brew install coreutils"
    exit 1
fi

# Check 10: Quick training test (10 seconds)
echo "✓ Testing training command (10 second test)..."
BASE_DIR="$SAMPLE_DIR"
MODEL_DIR="$BASE_DIR/models/validation_test"
REFERENCE_DIR="../../reference/hg38"
CHROM_SIZES="$REFERENCE_DIR/hg38.chrom.sizes"
REFERENCE_GENOME="$REFERENCE_DIR/hg38.genome.fa"
CV_SPLITS="$BASE_DIR/splits.json"
INPUT_DATA="$BASE_DIR/results/input_data.json"
MODEL_PARAMS="$BASE_DIR/bpnet_params.json"

mkdir -p "$MODEL_DIR"

# Try 10-second training run
timeout 10 python ../../bpnet-refactor/bpnet/cli/bpnettrainer.py \
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
        --epochs 1 \
        --batch-size 64 \
        --reverse-complement-augmentation \
        --early-stopping-patience 10 \
        --reduce-lr-on-plateau-patience 5 \
        --learning-rate 0.001 \
        > validation_test.log 2>&1

# Check if training started (timeout expected)
if [ $? -eq 124 ]; then
    echo "  ✅ Training command works (timed out as expected)"
elif [ $? -eq 0 ]; then
    echo "  ✅ Training command works (completed quickly)"
else
    echo "  ❌ Training command failed"
    echo "  → Check validation_test.log for details"
    cat validation_test.log
    rm -rf "$MODEL_DIR"
    exit 1
fi

# Clean up
rm -rf "$MODEL_DIR"
rm -f validation_test.log

echo ""
echo "=========================================="
echo "✅ All validation checks passed!"
echo "=========================================="
echo "Your environment is ready for grid search testing."
echo ""
echo "Next steps:"
echo "1. Run progress parsing test: ./scripts/performance/test_training_parsing.sh $ENV_NAME"
echo "2. Run mini grid search: ./scripts/performance/grid_search.sh $ENV_NAME 90"
echo "3. Run full grid search: ./scripts/performance/grid_search.sh $ENV_NAME 300"
echo ""