#!/bin/bash

# Create input_data.json file for BPNet training
echo "Creating input_data.json file"

BASE_DIR=ENCSR000EGM
DATA_DIR=$BASE_DIR/data

cat > $BASE_DIR/input_data.json << 'EOF'
{
    "0": {
        "signal": {
            "source": ["ENCSR000EGM/data/plus.bw", 
                       "ENCSR000EGM/data/minus.bw"]
        },
        "loci": {
            "source": ["ENCSR000EGM/data/peaks_inliers.bed"]
        },
        "background_loci": {
            "source": ["ENCSR000EGM/data/gc_negatives.bed"],
            "ratio": [0.25]
        },
        "bias": {
            "source": ["ENCSR000EGM/data/control_plus.bw",
                       "ENCSR000EGM/data/control_minus.bw"],
            "smoothing": [null, null]
        }
    }
}
EOF

echo "input_data.json created successfully"