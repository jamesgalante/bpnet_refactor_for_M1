#!/bin/bash

# Generate background regions for sample
# Usage: ./04_background_generation.sh <sample_directory>

set -e  # Exit on any error

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sample_directory>"
    echo "Example: $0 samples/ENCSR000EGM"
    exit 1
fi

SAMPLE_DIR=$1


echo "Using global GC reference (created during setup_global.sh)"

echo "Creating gc background"
python ../../bpnet-refactor/bpnet/cli/gc/get_gc_background.py \
        --ref_fasta ../../reference/hg38/hg38.genome.fa \
        --peaks_bed "$SAMPLE_DIR/processed/peaks_inliers.bed" \
        --out_dir "$SAMPLE_DIR/processed/" \
        --ref_gc_bed ../../reference/hg38/genomewide_gc_stride_1000_flank_size_1057.gc.bed \
        --output_prefix gc_negatives \
        --flank_size 1057 \
        --neg_to_pos_ratio_train 4
