#!/bin/bash

# BPNet Grid Search Log Analysis Wrapper
# Usage: ./analyze_logs.sh [environment_name]

set -e

if [ $# -gt 1 ]; then
    echo "Usage: $0 [environment_name]"
    echo "Example: $0 testing-bpnet-m1_version2"
    echo "If no environment provided, will use python3 directly"
    exit 1
fi

ENV_NAME=${1:-""}

echo "=========================================="
echo "BPNet Grid Search Log Analysis"
echo "=========================================="
echo "Analyzing log files in current directory..."
echo ""

# Check if log files exist
LOG_COUNT=$(ls training_*t_*b.log 2>/dev/null | wc -l)
if [ $LOG_COUNT -eq 0 ]; then
    echo "Error: No grid search log files found (training_*t_*b.log)"
    echo "Please run grid search first: ./scripts/performance/grid_search.sh ENV_NAME"
    exit 1
fi

echo "Found $LOG_COUNT log files to analyze"
echo ""

# Activate environment if provided
if [ -n "$ENV_NAME" ]; then
    echo "Activating conda environment: $ENV_NAME"
    eval "$(conda shell.bash hook)"
    conda activate "$ENV_NAME"
    echo ""
fi

# Check if required packages are available
echo "Checking Python dependencies..."
python3 -c "
import sys
missing_packages = []

try:
    import pandas
    print('✅ pandas')
except ImportError:
    missing_packages.append('pandas')
    print('❌ pandas (missing)')

try:
    import matplotlib
    print('✅ matplotlib')
except ImportError:
    missing_packages.append('matplotlib')
    print('❌ matplotlib (missing)')

try:
    import seaborn
    print('✅ seaborn')
except ImportError:
    missing_packages.append('seaborn')
    print('❌ seaborn (missing)')

try:
    import numpy
    print('✅ numpy')
except ImportError:
    missing_packages.append('numpy')
    print('❌ numpy (missing)')

if missing_packages:
    print(f'\\nMissing packages: {missing_packages}')
    print('Install with: pip install pandas matplotlib seaborn numpy')
    sys.exit(1)
else:
    print('\\n✅ All required packages available')
"

if [ $? -ne 0 ]; then
    echo ""
    echo "Please install missing packages and try again"
    exit 1
fi

echo ""
echo "Running analysis..."
echo ""

# Run the analysis script
python3 scripts/performance/analyze_grid_search.py .

echo ""
echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo "Generated files:"
echo "  - plots/: Performance visualization plots"
echo "  - grid_search_analysis.json: Detailed results data"
echo ""
echo "Open the plots directory to view performance charts!"