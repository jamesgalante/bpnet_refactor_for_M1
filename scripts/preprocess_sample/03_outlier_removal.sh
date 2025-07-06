#!/bin/bash

# Remove outliers from sample peaks
# Usage: ./03_outlier_removal.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

echo "Creating input_outliers.json"
cat > "$SAMPLE_DIR/input_outliers.json" << EOF
{
    "0": {
        "signal": {
            "source": ["$SAMPLE_DIR/processed/plus.bw",
                       "$SAMPLE_DIR/processed/minus.bw"]
        },
        "loci": {
            "source": ["$SAMPLE_DIR/processed/peaks.bed"]
        },
        "bias": {
            "source": ["$SAMPLE_DIR/processed/control_plus.bw",
                       "$SAMPLE_DIR/processed/control_minus.bw"],
            "smoothing": [null, null]
        }
    }
}
EOF

echo "Running bpnet-outliers"
python ../../bpnet-refactor/bpnet/cli/outliers.py \
    --input-data "$SAMPLE_DIR/input_outliers.json"  \
    --quantile 0.99 \
    --quantile-value-scale-factor 1.2 \
    --task 0 \
    --chrom-sizes ../../reference/hg38/hg38.chrom.sizes \
    --chroms $(paste -s -d ' ' ../../reference/hg38/chroms.txt) \
    --sequence-len 1000 \
    --blacklist ../../reference/hg38/blacklist.bed \
    --global-sample-weight 1.0 \
    --output-bed "$SAMPLE_DIR/processed/peaks_inliers.bed"

# Move log file to sample directory
if [ -f "outliers.log" ]; then
    mv outliers.log "$SAMPLE_DIR/"
fi
