#!/bin/bash

# Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# Now activate the environment
conda activate bpnet-refactored


echo "Creating gc reference"
bpnet-gc-reference \
        --ref_fasta ENCSR000EGM/reference/hg38.genome.fa \
        --chrom_sizes ENCSR000EGM/reference/hg38.chrom.sizes \
        --output_prefix ENCSR000EGM/reference/genomewide_gc_stride_1000_flank_size_1057.gc \
        --inputlen 2114 \
        --stride 1000

echo "Creating gc background"
bpnet-gc-background \
        --ref_fasta ENCSR000EGM/reference/hg38.genome.fa \
        --peaks_bed ENCSR000EGM/data/peaks_inliers.bed \
        --out_dir ENCSR000EGM/data/ \
        --ref_gc_bed ENCSR000EGM/reference/genomewide_gc_stride_1000_flank_size_1057.gc.bed \
        --output_prefix gc_negatives \
        --flank_size 1057 \
        --neg_to_pos_ratio_train 4
