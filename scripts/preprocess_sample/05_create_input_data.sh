#!/bin/bash

# Create input_data.json file for BPNet training
# Usage: ./05_create_input_data.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1

echo "Creating input_data.json file"

cat > "$SAMPLE_DIR/results/input_data.json" << EOF
{
    "0": {
        "signal": {
            "source": ["$SAMPLE_DIR/processed/plus.bw", 
                       "$SAMPLE_DIR/processed/minus.bw"]
        },
        "loci": {
            "source": ["$SAMPLE_DIR/processed/peaks_inliers.bed"]
        },
        "background_loci": {
            "source": ["$SAMPLE_DIR/processed/gc_negatives.bed"],
            "ratio": [0.25]
        },
        "bias": {
            "source": ["$SAMPLE_DIR/processed/control_plus.bw",
                       "$SAMPLE_DIR/processed/control_minus.bw"],
            "smoothing": [null, null]
        }
    }
}
EOF

echo "input_data.json created successfully in $SAMPLE_DIR/results/"