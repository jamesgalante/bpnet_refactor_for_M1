#!/bin/bash

# Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# Now activate the environment
conda activate bpnet-refactored

echo "Creating input_outliers.json"
cat > input_outliers.json << 'EOF'
{
    "0": {
        "signal": {
            "source": ["ENCSR000EGM/data/plus.bw",
                       "ENCSR000EGM/data/minus.bw"]
        },
        "loci": {
            "source": ["ENCSR000EGM/data/peaks.bed"]
        },
        "bias": {
            "source": ["ENCSR000EGM/data/control_plus.bw",
                       "ENCSR000EGM/data/control_minus.bw"],
            "smoothing": [null, null]
        }
    }
}
EOF

echo "Running bpnet-outliers"
bpnet-outliers \
    --input-data input_outliers.json  \
    --quantile 0.99 \
    --quantile-value-scale-factor 1.2 \
    --task 0 \
    --chrom-sizes ENCSR000EGM/reference/hg38.chrom.sizes \
    --chroms $(paste -s -d ' ' ENCSR000EGM/reference/chroms.txt) \
    --sequence-len 1000 \
    --blacklist ENCSR000EGM/reference/blacklist.bed \
    --global-sample-weight 1.0 \
    --output-bed ENCSR000EGM/data/peaks_inliers.bed
